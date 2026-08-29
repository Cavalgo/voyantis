# Arquitectura Técnica

## Stack
- **Frontend:** Flutter Web, Riverpod (sin code generation — ver `rules.md`), Clean Architecture ligera
- **Backend/orquestación del agente:** Cloud Function (Node.js/Express) — proxy entre Flutter y Claude API, NUNCA exponer la API key de Claude ni de Google Places en el cliente
- **Agente:** Claude API con tool use
- **Datos reales de lugares/fotos:** Google Places API (Text Search + Photo API)
- **Persistencia:** Firestore
- **Deploy:** Firebase Hosting (`flutter build web` → `firebase deploy --only hosting`)

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

## Schema de Firestore — colección `trips`

```json
{
  "tripId": "auto-generado",
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
La Photo API de Google Places devuelve una `photo_reference`, no una URL directa. Hay que construir la URL así:
```
https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference={photo_reference}&key={API_KEY}
```
Esto se hace en el backend (Cloud Function), y la URL resultante es la que se guarda en `location.photoUrl`.

## Checklist de setup (hacer en los primeros 20 min)
- [ ] API key de Claude (Anthropic Console)
- [ ] API key de Google Places (Google Cloud Console — habilitar Places API)
- [ ] Proyecto de Firebase creado + Firestore en modo test + Hosting habilitado
- [ ] `flutterfire configure` corrido para generar `firebase_options.dart`
- [ ] Cloud Function desplegada con ambas API keys como variables de entorno (nunca en código)
