# scripts/

Utilidades sueltas. No forman parte del build de la app ni de las functions.

## `seed_firestore.mjs`

Crea/actualiza el doc `trips/demo-seed` en Firestore (FASE 1 §1.4). Es lo que
Track B usa para construir el timeline sin esperar al backend, y el **escenario
de respaldo** del pitch.

```bash
node scripts/seed_firestore.mjs
```

- No necesita gcloud ni service account: las reglas de Firestore están abiertas
  (modo demo) y la REST API acepta la Web API key pública.
- `updatedAt` se escribe como server timestamp real (transform `REQUEST_TIME`),
  así el `orderBy('updatedAt', desc)` de `watchCurrentTrip()` lo toma como el
  viaje más reciente.
- Es idempotente: cada corrida sobrescribe el doc completo.
- Para cambiar el contenido del itinerario, edita el objeto `trip` en el script.

Ver el resultado:
https://console.firebase.google.com/project/mi-viaje-11d84/firestore/data/~2Ftrips~2Fdemo-seed
