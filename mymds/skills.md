# Skills — Recetas rápidas para hoy

Guías cortas para las tareas que se van a repetir hoy. Úsenlas como prompt base para Claude Code.

## 1. Crear una nueva feature
1. Crear carpeta `lib/features/<nombre_feature>/` con subcarpetas `data/`, `domain/`, `presentation/`
2. `domain/`: definir el modelo/entidad si no existe ya en `core/`
3. `data/`: repository que hable con Firestore o con la Cloud Function
4. `presentation/`: pantalla + provider/notifier que consuma el repository
5. Seguir el patrón de `flutter-architecture-features.md`

## 2. Conectar una pantalla a un stream de Firestore
1. Definir un `StreamProvider` (o `StreamProvider.family` si depende de un id) en el repository
2. En la pantalla, usar `ref.watch(miProvider)` y manejar los 3 casos con `.when(data:, loading:, error:)`
3. No hacer la query de Firestore directo en el widget — siempre a través del repository

## 3. Agregar un nuevo tool call al agente (backend)
1. Definir el tool en el formato de tool use de Claude API: `name`, `description`, `input_schema` (JSON Schema)
2. Implementar la función que ejecuta la lógica real (ej. llamar Google Places, escribir en Firestore)
3. En el loop de la Cloud Function: cuando la respuesta de Claude incluya un `tool_use` block, ejecutar la función, devolver el resultado como `tool_result`, y continuar la conversación
4. Documentar el tool nuevo en `ai-agent-design.md`

## 4. Renderizar una nueva sección en el timeline visual
1. Cada "día" del itinerario es una tarjeta/sección expandible con sus actividades
2. Cada actividad: foto (de `location.photoUrl`), título, hora, descripción corta, tip opcional
3. Reutilizar un solo widget `ActivityCard` parametrizado — no crear un widget nuevo por tipo de actividad
4. Priorizar que se vea bien con 3-4 actividades de ejemplo antes de optimizar para casos raros (0 actividades, 20 actividades, etc.)
