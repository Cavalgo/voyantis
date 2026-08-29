/**
 * tools.js — Schemas de las tools del agente. FUENTE DE VERDAD compartida
 * (congelada en FASE 1, ver ../phases.md §1.3).
 *
 * - `index.js` importa `TOOLS` y se lo pasa a `anthropic.messages.create({ tools })`.
 * - El detalle de los sub-objetos de `save_itinerary` refleja el schema de la
 *   colección `trips` de ../mymds/02-technical-architecture.md.
 * - `profileId`, `createdAt` y `updatedAt` NO están en el schema: los inyecta el
 *   backend al escribir el doc (`req.body.profileId` + `serverTimestamp()`).
 *
 * Fechas: siempre string ISO 8601 (`"2026-09-18"` o `"2026-09-18T14:00:00-06:00"`).
 */

/**
 * search_places — Google Places (Text Search legacy) + Photo API.
 * Devuelve un array de lugares con esta forma (el backend arma `photoUrl`):
 *   { name, address, lat, lng, rating, photoUrl, category }
 */
const SEARCH_PLACES_TOOL = {
  name: "search_places",
  description:
    "Busca lugares reales (restaurantes, atracciones, hoteles, miradores) en un destino usando Google Places. Devuelve nombre, dirección, coordenadas, rating, categoría y una URL de foto real. Úsalo para anclar actividades a lugares que existen y para conseguir fotos del itinerario.",
  input_schema: {
    type: "object",
    properties: {
      destination: {
        type: "string",
        description: "Ciudad o zona donde buscar. Ej: 'Oaxaca de Juárez, México'",
      },
      category: {
        type: "string",
        description: "Tipo de lugar. Ej: restaurante, museo, mirador, hotel, bar, mercado",
      },
      keywords: {
        type: "string",
        description:
          "Matices opcionales de la búsqueda. Ej: 'vista panorámica', 'comida local', 'rooftop'",
      },
    },
    required: ["destination", "category"],
  },
};

/**
 * save_itinerary — upsert del doc completo a la colección `trips` de Firestore.
 * Si falta `tripId` el backend genera uno nuevo y lo devuelve.
 */
const SAVE_ITINERARY_TOOL = {
  name: "save_itinerary",
  description:
    "Crea o actualiza (upsert) el itinerario de viaje en la base de datos, con el perfil del viajero y el plan día por día. Incluye SIEMPRE flights, accommodation y budgetBreakdown, aunque sean estimaciones (el itinerario visual siempre los muestra). Para editar un itinerario ya guardado, reusa el mismo tripId y manda el doc completo actualizado.",
  input_schema: {
    type: "object",
    properties: {
      tripId: {
        type: "string",
        description:
          "Omitir la primera vez (se genera uno nuevo). Incluir para actualizar un itinerario existente.",
      },
      status: {
        type: "string",
        enum: ["draft", "confirmed"],
        description: "'draft' mientras se ajusta; 'confirmed' tras el sí explícito del usuario.",
      },
      travelerProfile: {
        type: "object",
        description: "Perfil que armaste en la fase de diagnóstico.",
        properties: {
          originCity: { type: "string" },
          groupType: {
            type: "string",
            enum: ["solo", "pareja", "familia", "amigos"],
          },
          groupSize: { type: "number" },
          socialStyle: {
            type: "string",
            enum: ["introvertido", "extrovertido", "mixto"],
          },
          paceStyle: {
            type: "string",
            enum: ["relajado", "balanceado", "intenso"],
          },
          interests: {
            type: "array",
            items: { type: "string" },
            description: "Lista abierta: naturaleza, gastronomía, historia, vida nocturna, arte, compras, playas, aventura…",
          },
          goals: {
            type: "object",
            properties: {
              instagrammable: { type: "boolean" },
              salirZonaConfort: { type: "boolean" },
              conocerGente: { type: "boolean" },
              desconectar: { type: "boolean" },
            },
          },
          constraints: {
            type: "array",
            items: { type: "string" },
            description: "Restricciones alimenticias, de movilidad, etc. Texto libre.",
          },
        },
      },
      summary: {
        type: "object",
        description: "Resumen de cabecera del itinerario.",
        properties: {
          destination: { type: "string" },
          startDate: { type: "string", description: "ISO 8601, ej '2026-09-18'" },
          endDate: { type: "string", description: "ISO 8601, ej '2026-09-20'" },
          totalDays: { type: "number" },
          vibeTags: {
            type: "array",
            items: { type: "string" },
            description: "Ej: 'aventura', 'romántico', 'cultural'",
          },
          estimatedBudgetTotal: { type: "number" },
          currency: { type: "string", description: "Ej: 'MXN', 'USD'" },
        },
        required: ["destination", "startDate", "endDate", "totalDays"],
      },
      flights: {
        type: "array",
        description: "Vuelos simulados (ida y vuelta). Estimaciones realistas.",
        items: {
          type: "object",
          properties: {
            type: { type: "string", enum: ["outbound", "return"] },
            airline: { type: "string", description: "Aerolínea (simulada)" },
            from: { type: "string" },
            to: { type: "string" },
            date: { type: "string", description: "ISO 8601" },
            estimatedPrice: { type: "number" },
          },
          required: ["type", "from", "to", "date"],
        },
      },
      accommodation: {
        type: "array",
        description: "Hospedaje simulado. Normalmente 1 entrada.",
        items: {
          type: "object",
          properties: {
            name: { type: "string" },
            area: { type: "string", description: "Zona o barrio" },
            checkIn: { type: "string", description: "ISO 8601" },
            checkOut: { type: "string", description: "ISO 8601" },
            estimatedPricePerNight: { type: "number" },
            style: { type: "string", description: "boutique, hostal, resort, etc" },
          },
          required: ["name", "checkIn", "checkOut"],
        },
      },
      days: {
        type: "array",
        description: "Plan día por día, en orden.",
        items: {
          type: "object",
          properties: {
            dayNumber: { type: "number" },
            date: { type: "string", description: "ISO 8601, ej '2026-09-18'" },
            theme: { type: "string", description: "Ej: 'Centro histórico'" },
            activities: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  time: {
                    type: "string",
                    description: "Ej: '09:00' o 'Mañana' — string libre, no fecha",
                  },
                  title: { type: "string" },
                  description: { type: "string" },
                  location: {
                    type: "object",
                    description:
                      "Idealmente de search_places. photoUrl la arma el backend.",
                    properties: {
                      name: { type: "string" },
                      address: { type: "string" },
                      lat: { type: "number" },
                      lng: { type: "number" },
                      photoUrl: {
                        type: "string",
                        description: "URL de foto de Google Places",
                      },
                      category: { type: "string" },
                      instagrammable: { type: "boolean" },
                    },
                  },
                  estimatedCost: { type: "number" },
                  tip: { type: "string", description: "Consejo práctico corto" },
                },
                required: ["time", "title", "description"],
              },
            },
          },
          required: ["dayNumber", "date", "activities"],
        },
      },
      budgetBreakdown: {
        type: "object",
        description: "Desglose del presupuesto estimado. Inclúyelo siempre.",
        properties: {
          flights: { type: "number" },
          accommodation: { type: "number" },
          activities: { type: "number" },
          food: { type: "number" },
          buffer: { type: "number" },
          total: { type: "number" },
        },
      },
      conversationContext: {
        type: "string",
        description:
          "Resumen libre que mantienes para reanudar ediciones tras una recarga: perfil del viajero + decisiones tomadas + qué quedó pendiente. Actualízalo en cada save.",
      },
    },
    required: ["summary", "days"],
  },
};

/** Array listo para `anthropic.messages.create({ tools: TOOLS })`. */
const TOOLS = [SEARCH_PLACES_TOOL, SAVE_ITINERARY_TOOL];

module.exports = { TOOLS, SEARCH_PLACES_TOOL, SAVE_ITINERARY_TOOL };
