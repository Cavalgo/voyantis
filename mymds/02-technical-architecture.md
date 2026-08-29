# Arquitectura Técnica

> Decisiones fijas y contrato del backend: `rules.md`. Fases: `phases.md` (raíz).

## Stack
- **Frontend:** Flutter Web, Riverpod (sin code generation — ver `rules.md`), Clean Architecture ligera
- **Backend/orquestación del agente:** Cloud Function (Node 20, Functions **v2**, Express) — proxy entre
  Flutter y Claude API (`claude-opus-5`). NUNCA exponer la API key de Claude ni de Google Places en el cliente.
- **Agente:** Claude API con tool use
- **Datos reales de lugares/fotos:** Google Places API **legacy** (Text Search + Photo API)
- **Persistencia:** Firestore (proyecto `mi-viaje-11d84`)
- **Deploy:** Firebase Hosting (`flutter build web` → `firebase deploy --only hosting`) + Functions
- **Plan Firebase:** **Blaze** obligatorio — en Spark la Cloud Function no puede hacer llamadas de red
  salientes (ni a `api.anthropic.com` ni a Google Places).

## Flujo de datos

```
Usuario
  ↓ (mensaje de chat)
Flutter Web (chat_agent feature)
  ↓ (HTTP request)
Cloud Function (proxy)
  ↓ (llamada con tools)
Claude API
  ↓ (cuando el modelo llama la tool)
  ├── search_places()  → Google Places API → devuelve lugar real + foto + rating
  └── save_itinerary() → escribe/actualiza documento en Firestore
  ↓
Cloud Function devuelve la respuesta del agente a Flutter
  ↓
Flutter (itinerary_view feature) escucha Firestore en tiempo real (stream)
  → renderiza el timeline visual
```

**Por qué un backend intermedio y no llamar Claude API directo desde Flutter Web:** las API keys no deben viajar al cliente. La Cloud Function también es donde se ejecutan las tools (llamadas a Google Places, escritura en Firestore) de forma segura y centralizada.

## Contrato Cloud Function ↔ Flutter

```jsonc
// POST /api/chat   (Flutter llama a /api/** vía rewrite de Hosting → sin CORS)
// request
{
  "profileId": "voyantis-demo",         // perfil fijo (ver rules.md). El backend lo escribe en el doc.
  "tripId": "abc | null",               // null hasta el primer save_itinerary
  "messages": [                          // historial COMPLETO — Claude API es stateless
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
// response
{
  "reply": "texto del agente",
  "tripId": "abc",                       // SIEMPRE (nuevo o existente) — Flutter lo usa para watchTrip
  "itinerarySaved": true,                // true si el agente llamó save_itinerary este turno
  "error": null
}
```
- El modelo **no ve** `profileId`; lo inyecta el backend al escribir el doc.
- **Reanudar tras recarga:** si llega `tripId` con `messages` corto (sin historial), el backend carga
  `conversationContext` del doc y lo antepone.

## Cloud Function — config

- **Deployada:** `api` en `us-central1`, Node 22, 2nd gen. URL cruda:
  `https://us-central1-mi-viaje-11d84.cloudfunctions.net/api` (pero Flutter usa `/api/**`).
  Hoy devuelve `501 not_implemented` — Track A implementa el loop del agente.
- **`timeoutSeconds: 300`, `memory: "512MiB"`** — el loop de tools (Claude + 2-3 round trips + Places)
  pasa fácil los 60s por defecto.
- **Secrets:** `defineSecret('ANTHROPIC_API_KEY')` / `defineSecret('GOOGLE_PLACES_API_KEY')` — ya en
  Secret Manager. **Emulador local** → `functions/.secret.local` (gitignored). ⚠️ **NO usar `functions/.env`**
  para estas keys: Firebase lo despliega como env var y choca con `defineSecret`
  (`Secret environment variable overlaps non secret environment variable`). Ver `rules.md` § Secrets.
- **CORS:** no se maneja en la función — el rewrite `"/api/**" → api` en `firebase.json` hace que
  Flutter y la función compartan origen.

## Schema de Firestore — colección `trips`

> **Fechas:** siempre ISO 8601 string (`"2026-09-10"` / `"2026-09-10T14:00:00Z"`). `createdAt` /
> `updatedAt` van como `Timestamp` de Firestore (server timestamp). La query "viaje actual" usa
> `where(profileId ==) + orderBy(updatedAt desc) + limit(1)` → necesita el índice compuesto de
> `firestore.indexes.json` (ya desplegado).

```json
{
  "tripId": "auto-generado",
  "profileId": "voyantis-demo",
  "status": "draft | confirmed",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",

  "travelerProfile": {
    "originCity": "string",
    "groupType": "solo | pareja | familia | amigos",
    "groupSize": "number",
    "socialStyle": "introvertido | extrovertido | mixto",
    "paceStyle": "relajado | balanceado | intenso",
    "interests": ["naturaleza", "gastronomía", "historia", "vida nocturna", "arte", "compras", "playas", "aventura"],
    "goals": {
      "instagrammable": "boolean",
      "salirZonaConfort": "boolean",
      "conocerGente": "boolean",
      "desconectar": "boolean"
    },
    "constraints": ["restricciones alimenticias, movilidad, etc — string libre"]
  },

  "summary": {
    "destination": "string",
    "startDate": "date",
    "endDate": "date",
    "totalDays": "number",
    "vibeTags": ["ej: aventura", "romántico", "cultural"],
    "estimatedBudgetTotal": "number",
    "currency": "string"
  },

  "flights": [
    {
      "type": "outbound | return",
      "airline": "string (simulado)",
      "from": "string",
      "to": "string",
      "date": "date",
      "estimatedPrice": "number"
    }
  ],

  "accommodation": [
    {
      "name": "string (simulado o real)",
      "area": "string",
      "checkIn": "date",
      "checkOut": "date",
      "estimatedPricePerNight": "number",
      "style": "string (boutique, hostal, resort, etc)"
    }
  ],

  "days": [
    {
      "dayNumber": "number",
      "date": "date",
      "theme": "string (ej: 'Centro histórico')",
      "activities": [
        {
          "time": "string",
          "title": "string",
          "description": "string",
          "location": {
            "name": "string",
            "address": "string",
            "lat": "number",
            "lng": "number",
            "photoUrl": "string (de Google Places)",
            "category": "string",
            "instagrammable": "boolean"
          },
          "estimatedCost": "number",
          "tip": "string"
        }
      ]
    }
  ],

  "budgetBreakdown": {
    "flights": "number",
    "accommodation": "number",
    "activities": "number",
    "food": "number",
    "buffer": "number",
    "total": "number"
  },

  "conversationContext": "string — resumen libre que el agente mantiene para entender ediciones futuras sin releer todo el historial"
}
```

## Google Places — nota técnica
Se usa la **Places API legacy** (hay que habilitar "Places API", no solo "Places API (New)").
La Photo API devuelve una `photo_reference`, no una URL directa. Se construye así:
```
https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference={photo_reference}&key={API_KEY}
```
Esto se hace en el backend, y la URL resultante se guarda en `location.photoUrl`.

⚠️ **Esa URL lleva la API key** → cuando el cliente renderiza la foto, la key de Places queda visible
en la red. Para el demo es tolerable. Hardening opcional: restringir la key a la Places API, o endpoint
proxy `/api/photo?ref=...` en la función (la key nunca llega al cliente).

## Checklist de setup — estado actual (2026-08-29)
- [x] API key de Claude → `functions/.secret.local` + Secret Manager
- [x] API key de Google Places → `functions/.secret.local` + Secret Manager
- [x] Proyecto Firebase `mi-viaje-11d84` en **plan Blaze** + Firestore + reglas (hasta 2026-09-28) + índice `trips`
- [x] Places API habilitada en GCP
- [x] `flutterfire configure` → `lib/firebase_options.dart` (commiteado; su Web API key es pública)
- [x] Dependencias Flutter (`flutter_riverpod`, `firebase_core`, `cloud_firestore`, `http`, `google_fonts`, `cached_network_image`, `intl`)
- [x] `functions/` scaffold + `npm install` + **`firebase deploy --only functions`** (función `api` viva, devuelve 501)
- [x] Árbol de carpetas `lib/` + scaffold del contador eliminado
- [ ] Hosting: `firebase deploy --only hosting` (tras `flutter build web`) — FASE 4
- [ ] Track A: implementar el loop del agente en `functions/index.js`
- [ ] Track A: implementar el loop del agente en `functions/index.js`
