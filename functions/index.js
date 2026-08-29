/**
 * Cloud Function proxy — Voyantis
 * Flutter (/api/chat)  ->  esta función  ->  Claude API (tool use) + Firestore
 *
 * El loop del agente vive en ./agent.js. Ver: ../phases.md (TRACK A) ·
 * ../mymds/ai-agent-design.md · ../mymds/skills.md (recetas 4-6).
 *
 * Secrets: NO están en este archivo. Emulador -> functions/.secret.local (gitignored) ;
 * deploy -> Secret Manager (`firebase functions:secrets:set`). Ver ../mymds/rules.md § Secrets.
 */
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");
const Anthropic = require("@anthropic-ai/sdk");

// Schemas de las tools — fuente de verdad compartida, congelada en FASE 1.
const { TOOLS } = require("./tools");
const { runAgent } = require("./agent");

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");
const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");

admin.initializeApp();

const app = express();
// En prod Flutter llama a /api/** (mismo origen vía rewrite de Hosting) y CORS
// no aplica. Pero en dev (`flutter run -d chrome`) la llamada es cross-origin;
// refleja el origin para no bloquearla. La API no tiene auth, mismo modelo que
// las reglas abiertas de Firestore (ver auditoria.md B12).
app.use(cors({ origin: true }));
app.use(express.json());

// El rewrite de Hosting `"/api/**"` reenvía el path COMPLETO (`/api/chat`);
// la URL cruda de la función lo entrega como `/chat`. Normalizamos quitando el
// prefijo `/api` para que las rutas de abajo sirvan en ambos casos.
app.use((req, _res, next) => {
  if (req.url === "/api" || req.url.startsWith("/api/") || req.url.startsWith("/api?")) {
    req.url = req.url.slice(4) || "/";
  }
  next();
});

// Inspección del contrato de tools congelado en FASE 1 (útil para Track A/B/C).
app.get("/tools", (_req, res) => {
  res.json({ tools: TOOLS.map((t) => t.name), schemas: TOOLS });
});

// Flutter llama a /api/chat (rewrite en firebase.json -> sin CORS).
app.post("/chat", async (req, res) => {
  const { profileId, tripId, messages } = req.body || {};
  if (!profileId || !Array.isArray(messages) || messages.length === 0) {
    return res
      .status(400)
      .json({ error: "profileId y messages[] (no vacío) son requeridos" });
  }

  // Reanudar tras recarga: si viene un tripId, cargar el conversationContext del doc
  // para que el agente pueda retomar la edición sin el historial completo (auditoria B14).
  let priorContext = null;
  if (tripId) {
    try {
      const snap = await admin.firestore().collection("trips").doc(tripId).get();
      if (snap.exists) priorContext = snap.data().conversationContext || null;
    } catch (e) {
      logger.warn("no se pudo cargar conversationContext", e);
    }
  }

  try {
    const r = await runAgent({
      apiKey: ANTHROPIC_API_KEY.value(),
      placesApiKey: GOOGLE_PLACES_API_KEY.value(),
      profileId,
      tripId: tripId || null,
      messages,
      priorContext,
    });
    return res.status(200).json({
      reply: r.reply,
      tripId: r.currentTripId,
      itinerarySaved: r.itinerarySaved,
      error: r.capped ? "max_iterations" : null,
    });
  } catch (e) {
    logger.error("agent error", e);
    const rateLimited = e instanceof Anthropic.RateLimitError;
    return res.status(200).json({
      reply:
        "Uy, tuve un problema procesando eso. ¿Puedes intentarlo de nuevo en un momento?",
      tripId: tripId || null,
      itinerarySaved: false,
      error: rateLimited ? "rate_limited" : "upstream_error",
    });
  }
});

exports.api = onRequest(
  {
    region: "us-central1",
    secrets: [ANTHROPIC_API_KEY, GOOGLE_PLACES_API_KEY],
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  app,
);
