/**
 * agent.js — el agente de Voyantis: system prompt + loop manual de tool use.
 *
 * Lo llama `index.js` desde `POST /chat`. Modelo: claude-opus-5 (rules.md).
 * Tools: `search_places` (Google Places, ver ./places.js) + `save_itinerary` (upsert a `trips`).
 * Ver ../mymds/ai-agent-design.md y ../phases.md (TRACK A).
 */
const Anthropic = require("@anthropic-ai/sdk");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

const { SEARCH_PLACES_TOOL, SAVE_ITINERARY_TOOL } = require("./tools");
const { searchPlaces } = require("./places");

const MODEL = "claude-opus-5";
// El turno de guardado emite el itinerario completo como JSON (2-4k tokens) +
// thinking adaptativo. 32k deja holgura para itinerarios de 5-7 días sin truncar.
// Con este max_tokens hay que usar streaming (el SDK rechaza no-streaming por el
// límite de 10 min); igual no hacemos SSE al cliente, solo `.finalMessage()`.
const MAX_TOKENS = 32000;
// Con search_places el agente encadena varias búsquedas antes de proponer/guardar,
// así que damos más vueltas que con save_itinerary solo. Es un techo de seguridad:
// el flujo normal (unas búsquedas + 1 save + 1 confirmación) usa ~4-6.
const MAX_ITERATIONS = 12;
// "high" da itinerarios un poco mejores pero cada turno tarda 45-120s — demasiado
// para el pitch en vivo. "medium" baja a ~20-40s con calidad muy pareja.
const EFFORT = "medium";

const ACTIVE_TOOLS = [SEARCH_PLACES_TOOL, SAVE_ITINERARY_TOOL];

const SYSTEM_PROMPT = `Eres Voyantis, un planeador de viajes experto y cálido. Hablas español, con tono cercano y entusiasta — como un amigo que sabe muchísimo de viajes, nunca como un formulario.

Hoy es ${new Date().toISOString().slice(0, 10)}. Cualquier viaje que planees es a futuro a partir de esa fecha.

Tu trabajo tiene tres fases:

FASE DE DIAGNÓSTICO (flexible):
Conversa para entender: destino (o "sorpréndeme"), ciudad de origen, fechas o duración,
presupuesto (total o por persona), perfil del grupo (solo/pareja/familia/amigos y tamaño),
personalidad de viaje (introvertido/extrovertido/mixto, ritmo relajado/balanceado/intenso),
intereses (naturaleza, gastronomía, historia, vida nocturna, arte, compras, playas, aventura…),
objetivos especiales (fotos instagrameables, salir de la zona de confort, conocer gente,
desconectar) y restricciones (alimenticias, movilidad, lo que mencionen).
- Máximo 2-3 preguntas por turno. Nunca un interrogatorio.
- Infiere lo que puedas del contexto; no repreguntes lo que ya te dijeron.
- Cuando tengas suficiente para un primer borrador (no necesitas el 100%), ofrece pasar a la
  propuesta en vez de seguir preguntando.

FASE DE PROPUESTA:
Antes de armar la propuesta, usa la tool search_places para los lugares principales del viaje
(restaurantes, atracciones, miradores, museos y el hotel): búscala por destino + categoría, con
keywords útiles ("comida local", "vista panorámica", "hotel boutique céntrico"…). Puedes lanzar
varias búsquedas en paralelo. Así anclas cada actividad a un lugar que existe y consigues fotos
reales. Si una búsqueda vuelve vacía, propón un lugar real que conozcas y sigue.
Luego presenta un resumen claro y legible del itinerario propuesto (destino, fechas, días con
sus actividades, hospedaje, vuelos estimados, presupuesto). Pide confirmación explícita antes de
guardar. Si piden cambios, ajusta y vuelve a mostrar el resumen. NO guardes hasta tener un "sí"
claro del usuario.

FASE DE GUARDADO:
Solo con el "sí" explícito, llama a la tool save_itinerary con el itinerario completo. Reglas:
- Fechas SIEMPRE como string ISO 8601: "2026-09-18", o con hora "2026-09-18T14:00:00-06:00".
- Incluye SIEMPRE flights, accommodation y budgetBreakdown, aunque sean estimaciones — el
  itinerario visual siempre los muestra. Los vuelos y el hotel pueden ser simulados y realistas.
- En cada location copia lo que devolvió search_places para ese lugar: name, address, lat, lng,
  category y photoUrl TAL CUAL. Nunca inventes URLs ni coordenadas. Si no hubo resultado para un
  lugar, deja photoUrl como "" y omite lat/lng. Marca instagrammable según el perfil del viajero.
- Mantén conversationContext actualizado y útil en cada save: resumen del perfil del viajero,
  decisiones tomadas y qué quedó pendiente. Es lo que te permite retomar una edición si el
  usuario recarga la página y vuelve más tarde.
- Para editar un itinerario ya guardado, vuelve a llamar save_itinerary con el MISMO tripId y el
  documento completo actualizado.
Después de guardar, confírmalo en una frase corta y amable.

Si save_itinerary devuelve un error, explícale al usuario que hubo un problema al guardar y
ofrécele reintentar; no inventes que se guardó.`;

/** Concatena los bloques de texto de una respuesta del modelo. */
function textOf(message) {
  return (message.content || [])
    .filter((b) => b.type === "text")
    .map((b) => b.text)
    .join("\n")
    .trim();
}

/** Implementación de las tools. Devuelve siempre un objeto con `ok: boolean`. */
async function executeTool(name, input, ctx) {
  if (name === "search_places") {
    try {
      return await searchPlaces(input || {}, ctx.placesApiKey);
    } catch (e) {
      logger.error("search_places failed", e);
      // No es error duro: el agente sigue sin fotos.
      return {
        ok: true,
        results: [],
        warning: `search_places falló: ${String((e && e.message) || e)}`,
      };
    }
  }

  if (name === "save_itinerary") {
    try {
      const db = admin.firestore();
      const tripId =
        ctx.currentTripId ||
        (typeof input.tripId === "string" && input.tripId) ||
        db.collection("trips").doc().id;

      const ref = db.collection("trips").doc(tripId);
      const existing = await ref.get();

      const data = {
        profileId: ctx.profileId,
        status: input.status || "draft",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      // Campos del modelo que maneja el agente (todo lo demás lo pone el backend).
      for (const k of [
        "travelerProfile",
        "summary",
        "flights",
        "accommodation",
        "days",
        "budgetBreakdown",
        "conversationContext",
      ]) {
        if (input[k] !== undefined) data[k] = input[k];
      }
      if (!existing.exists) {
        data.createdAt = admin.firestore.FieldValue.serverTimestamp();
      }

      await ref.set(data, { merge: true });
      logger.info("save_itinerary ok", { tripId, created: !existing.exists });
      return { ok: true, tripId, created: !existing.exists };
    } catch (e) {
      logger.error("save_itinerary failed", e);
      return { ok: false, error: String((e && e.message) || e) };
    }
  }

  return { ok: false, error: `tool desconocida: ${name}` };
}

/**
 * Loop manual de tool use.
 * @returns {Promise<{reply:string, currentTripId:(string|null), itinerarySaved:boolean, capped?:boolean, refused?:boolean}>}
 */
async function runAgent({
  apiKey,
  placesApiKey,
  profileId,
  tripId,
  messages,
  priorContext,
}) {
  const client = new Anthropic({ apiKey });

  const system = priorContext
    ? `${SYSTEM_PROMPT}\n\nCONTEXTO DE UNA SESIÓN ANTERIOR (el usuario vuelve a un itinerario ya guardado; retómalo y edítalo, no empieces de cero):\n${priorContext}`
    : SYSTEM_PROMPT;

  const convo = messages.map((m) => ({ role: m.role, content: m.content }));
  let currentTripId = tripId || null;
  let itinerarySaved = false;
  let last = null;

  for (let i = 0; i < MAX_ITERATIONS; i++) {
    const resp = await client.messages
      .stream({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system,
        tools: ACTIVE_TOOLS,
        messages: convo,
        output_config: { effort: EFFORT },
      })
      .finalMessage();
    last = resp;
    convo.push({ role: "assistant", content: resp.content });

    if (resp.stop_reason === "refusal") {
      return {
        reply:
          "Perdón, no puedo ayudarte con eso. ¿Probamos con otra cosa para tu viaje?",
        currentTripId,
        itinerarySaved,
        refused: true,
      };
    }

    if (resp.stop_reason === "max_tokens") {
      logger.warn("runAgent: respuesta truncada por max_tokens");
      return {
        reply:
          textOf(resp) ||
          "Se me hizo muy largo el itinerario. ¿Lo hacemos de menos días o más simple?",
        currentTripId,
        itinerarySaved,
        capped: true,
      };
    }

    if (resp.stop_reason !== "tool_use") {
      return { reply: textOf(resp), currentTripId, itinerarySaved };
    }

    const toolResults = [];
    for (const block of resp.content.filter((b) => b.type === "tool_use")) {
      const out = await executeTool(block.name, block.input, {
        profileId,
        currentTripId,
        placesApiKey,
      });
      if (block.name === "save_itinerary" && out.ok) {
        currentTripId = out.tripId;
        itinerarySaved = true;
      }
      toolResults.push({
        type: "tool_result",
        tool_use_id: block.id,
        content: JSON.stringify(out),
        is_error: !out.ok,
      });
    }
    convo.push({ role: "user", content: toolResults });
  }

  logger.warn("runAgent alcanzó MAX_ITERATIONS", { tripId: currentTripId });
  return {
    reply:
      textOf(last) ||
      "Estoy dándole muchas vueltas a esto. ¿Puedes decirme qué ajustar?",
    currentTripId,
    itinerarySaved,
    capped: true,
  };
}

module.exports = { runAgent, SYSTEM_PROMPT };
