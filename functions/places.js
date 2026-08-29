/**
 * places.js — Google Places (Text Search legacy) + Photo API.
 *
 * Lo usa agent.js para la tool `search_places` (paso A3 de phases.md).
 * Se elige el endpoint LEGACY a propósito (ver auditoria.md B11): Text Search
 * clásico + Photo con `photoreference`, que es lo que asume el resto del proyecto.
 */
const logger = require("firebase-functions/logger");

const TEXT_SEARCH_URL =
  "https://maps.googleapis.com/maps/api/place/textsearch/json";
const PHOTO_URL = "https://maps.googleapis.com/maps/api/place/photo";
const MAX_RESULTS = 5;
const PHOTO_MAX_WIDTH = 1000;

/**
 * URL pública de una foto de Places.
 * NOTA (auditoria.md B10): la key viaja en la URL y se guarda en Firestore, así
 * que queda visible en el cliente. Aceptado para el hackathon (key restringida a
 * Places API + budget alert). Alternativa limpia: endpoint proxy `/api/photo`.
 */
function photoUrl(photoReference, apiKey) {
  const p = new URLSearchParams({
    maxwidth: String(PHOTO_MAX_WIDTH),
    photoreference: photoReference,
    key: apiKey,
  });
  return `${PHOTO_URL}?${p.toString()}`;
}

/**
 * Busca lugares reales para anclar actividades del itinerario.
 * NUNCA lanza: ante cualquier problema (sin key, red, status no-OK) devuelve
 * `{ ok: true, results: [], warning }` para que el agente siga sin fotos.
 *
 * @param {{destination?:string, category?:string, keywords?:string}} input
 * @param {string|undefined} apiKey  GOOGLE_PLACES_API_KEY
 * @returns {Promise<{ok:boolean, query?:string, count?:number, results:Array<object>, warning?:string}>}
 */
async function searchPlaces(input, apiKey) {
  const { destination, category, keywords } = input || {};
  const query = [keywords, category, "en", destination]
    .filter(Boolean)
    .join(" ")
    .trim();

  if (!apiKey) {
    return {
      ok: true,
      results: [],
      warning:
        "GOOGLE_PLACES_API_KEY no configurada: continúa sin fotos y deja location.photoUrl vacío.",
    };
  }
  if (!query) {
    return { ok: true, results: [], warning: "search_places sin destination/category." };
  }

  let data;
  try {
    const url = `${TEXT_SEARCH_URL}?${new URLSearchParams({ query, key: apiKey })}`;
    const res = await fetch(url);
    data = await res.json();
  } catch (e) {
    logger.warn("search_places: fallo de red a Google Places", e);
    return {
      ok: true,
      results: [],
      warning: `Places no disponible: ${String((e && e.message) || e)}`,
    };
  }

  if (data.status && data.status !== "OK" && data.status !== "ZERO_RESULTS") {
    logger.warn("search_places: status no-OK", {
      status: data.status,
      error: data.error_message,
    });
    return {
      ok: true,
      results: [],
      warning: `Places status ${data.status}${
        data.error_message ? `: ${data.error_message}` : ""
      }`,
    };
  }

  const results = (data.results || []).slice(0, MAX_RESULTS).map((r) => {
    const loc = (r.geometry && r.geometry.location) || {};
    const ref = r.photos && r.photos[0] && r.photos[0].photo_reference;
    return {
      name: r.name || "",
      address: r.formatted_address || r.vicinity || "",
      lat: typeof loc.lat === "number" ? loc.lat : null,
      lng: typeof loc.lng === "number" ? loc.lng : null,
      rating: typeof r.rating === "number" ? r.rating : null,
      userRatingsTotal:
        typeof r.user_ratings_total === "number" ? r.user_ratings_total : null,
      category: category || (Array.isArray(r.types) ? r.types[0] : "") || "",
      photoUrl: ref ? photoUrl(ref, apiKey) : "",
    };
  });

  return { ok: true, query, count: results.length, results };
}

module.exports = { searchPlaces, photoUrl };
