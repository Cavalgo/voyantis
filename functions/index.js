/**
 * Cloud Function proxy — Voyantis
 * Flutter (/api/chat)  ->  esta función  ->  Claude API (tool use) + Google Places + Firestore
 *
 * ESQUELETO. Track A (rama feature/agent) implementa el loop del agente aquí.
 * Ver: ../phases.md (TRACK A) · ../mymds/ai-agent-design.md · ../mymds/skills.md (recetas 4-6)
 *
 * Secrets: NO están en este archivo. Local -> functions/.env ; deploy -> Secret Manager.
 */
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const express = require("express");

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");
const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(express.json());

// Flutter llama a /api/chat (rewrite en firebase.json -> sin CORS).
app.post("/chat", async (req, res) => {
  const { profileId, tripId, messages } = req.body || {};
  if (!profileId || !Array.isArray(messages)) {
    return res.status(400).json({ error: "profileId y messages[] son requeridos" });
  }

  // TODO Track A: loop manual de tool use con Claude (claude-opus-5).
  //   - system prompt de mymds/ai-agent-design.md
  //   - tools: search_places (Google Places), save_itinerary (upsert a `trips`)
  //   - save_itinerary escribe profileId + updatedAt (serverTimestamp) en el doc
  //   - devolver { reply, tripId, itinerarySaved, error }
  return res.status(501).json({
    reply: null,
    tripId: tripId || null,
    itinerarySaved: false,
    error: "not_implemented",
  });
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
