/**
 * chat_smoke.mjs — prueba end-to-end de POST /api/chat (TRACK A pasada 1).
 *
 * Corre un guion de chat contra la función deployada, imprime cada respuesta del
 * agente y, si se guardó un itinerario, lee el doc `trips/{tripId}` de Firestore
 * (REST + Web API key, como scripts/seed_firestore.mjs) y valida su forma.
 *
 * Uso:
 *   node scripts/chat_smoke.mjs                 # guion nuevo: diagnóstico -> propuesta -> guardar
 *   node scripts/chat_smoke.mjs --edit <tripId> # un turno de edición sobre un trip existente
 *   node scripts/chat_smoke.mjs --url http://localhost:5001/mi-viaje-11d84/us-central1/api
 *
 * Requiere Node 18+ (fetch global).
 */

const PROJECT_ID = "mi-viaje-11d84";
const API_KEY = "AIzaSyBEg0E0HZVT3uY8L8g4ft1y_TGa9LTCFo4"; // Web API key, pública
const DEFAULT_URL = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/api`;
const PROFILE_ID = "voyantis-demo";

const args = process.argv.slice(2);
function argValue(flag) {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : null;
}
const BASE_URL = argValue("--url") || DEFAULT_URL;
const EDIT_TRIP_ID = argValue("--edit");

const NEW_TRIP_SCRIPT = [
  "Quiero planear un viaje a Oaxaca de Juárez con mi pareja. Salimos de CDMX, 3 días a mediados de septiembre de 2026, presupuesto de unos 18 mil pesos en total. Nos gusta la comida, la historia y algo de naturaleza; ritmo relajado. Queremos desconectar y tomar buenas fotos. Sin restricciones alimenticias. Si tienes suficiente, propón el itinerario directamente.",
  "Me encanta la propuesta. Guárdala tal cual, por favor.",
  "Sí, confírmalo y guárdalo.",
];

const EDIT_SCRIPT = [
  "Cámbiame el hospedaje por uno más económico (un hostal boutique) y vuelve a guardar el itinerario.",
];

async function postChat(messages, tripId) {
  const res = await fetch(`${BASE_URL}/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ profileId: PROFILE_ID, tripId: tripId ?? null, messages }),
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`HTTP ${res.status} — respuesta no-JSON:\n${text.slice(0, 500)}`);
  }
  return { status: res.status, json };
}

async function readTripDoc(tripId) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/trips/${tripId}?key=${API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) return null;
  return res.json();
}

function fv(field) {
  // Firestore REST typed value -> valor plano (solo lo que necesita la validación)
  if (!field) return undefined;
  if ("stringValue" in field) return field.stringValue;
  if ("integerValue" in field) return Number(field.integerValue);
  if ("doubleValue" in field) return field.doubleValue;
  if ("booleanValue" in field) return field.booleanValue;
  if ("timestampValue" in field) return field.timestampValue;
  if ("arrayValue" in field) return field.arrayValue.values || [];
  if ("mapValue" in field) return field.mapValue.fields || {};
  return undefined;
}

async function run() {
  const script = EDIT_TRIP_ID ? EDIT_SCRIPT : NEW_TRIP_SCRIPT;
  const messages = [];
  let tripId = EDIT_TRIP_ID || null;
  let itinerarySaved = false;

  console.log(`▶ ${BASE_URL}/chat   perfil=${PROFILE_ID}${tripId ? `  tripId=${tripId}` : ""}\n`);

  for (const userMsg of script) {
    messages.push({ role: "user", content: userMsg });
    console.log(`\x1b[36m[user]\x1b[0m ${userMsg}\n`);

    const t0 = Date.now();
    const { status, json } = await postChat(messages, tripId);
    const secs = ((Date.now() - t0) / 1000).toFixed(1);

    if (status !== 200) {
      console.error(`✗ HTTP ${status}: ${JSON.stringify(json)}`);
      process.exit(1);
    }
    console.log(
      `\x1b[32m[agente ${secs}s]\x1b[0m ${json.reply}\n` +
        `   tripId=${json.tripId}  itinerarySaved=${json.itinerarySaved}  error=${json.error}\n`,
    );

    messages.push({ role: "assistant", content: json.reply });
    if (json.tripId) tripId = json.tripId;
    if (json.itinerarySaved) itinerarySaved = true;
    if (json.error && json.error !== "max_iterations") {
      console.error(`✗ el agente devolvió error="${json.error}"`);
      process.exit(1);
    }
    if (itinerarySaved && !EDIT_TRIP_ID) break; // ya guardó, no hace falta seguir el guion
  }

  if (!itinerarySaved) {
    console.error("✗ el guion terminó sin itinerarySaved=true");
    process.exit(1);
  }

  console.log(`\n🔎 Verificando trips/${tripId} en Firestore…`);
  const doc = await readTripDoc(tripId);
  if (!doc || !doc.fields) {
    console.error(`✗ el doc trips/${tripId} no existe / no es legible`);
    process.exit(1);
  }
  const f = doc.fields;
  const summary = fv(f.summary) || {};
  const days = fv(f.days) || [];
  const checks = {
    "profileId == voyantis-demo": fv(f.profileId) === PROFILE_ID,
    "summary.destination presente": !!fv(summary.destination),
    "summary.startDate ISO": /^\d{4}-\d{2}-\d{2}/.test(fv(summary.startDate) || ""),
    "days.length >= 1": days.length >= 1,
    "updatedAt presente": !!doc.updateTime,
    "flights presente": Array.isArray(fv(f.flights)),
    "budgetBreakdown presente": !!fv(f.budgetBreakdown),
    "conversationContext presente": !!fv(f.conversationContext),
  };
  let allOk = true;
  for (const [label, ok] of Object.entries(checks)) {
    console.log(`   ${ok ? "✓" : "✗"} ${label}`);
    if (!ok) allOk = false;
  }
  console.log(
    `\n   destino: ${fv(summary.destination)}  |  ${fv(summary.startDate)} → ${fv(summary.endDate)}  |  ${days.length} días  |  updateTime ${doc.updateTime}`,
  );

  console.log(
    allOk
      ? `\n✅ OK — itinerario guardado y verificado. tripId=${tripId}`
      : `\n✗ hay checks en rojo`,
  );
  process.exit(allOk ? 0 : 1);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
