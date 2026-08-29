/// Constantes globales de Voyantis.
library;

/// Perfil fijo único — no hay auth (ver mymds/rules.md).
/// Todo `trip` en Firestore lleva este `profileId`; la app muestra siempre
/// el último trip de la DB con este id.
const String kProfileId = 'voyantis-demo';

/// El chat llama a `/api/chat` (rewrite de Hosting → Cloud Function `api`).
/// Nunca a la URL cruda de la función (CORS).
const String kApiBasePath = '/api';

/// Modelo del agente (referencia; el modelo real se fija en functions/).
const String kAgentModel = 'claude-opus-5';
