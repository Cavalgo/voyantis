/// Fotos genéricas por categoría de actividad.
///
/// Los itinerarios que crea el agente hoy vienen sin `location.photoUrl`
/// (search_places / Google Places todavía no está en `main`). En vez de mostrar
/// solo el placeholder con degradado, usamos una foto real acorde a la categoría
/// para que el timeline se vea "fotografiado" en el demo.
///
/// Son fotos de lugares de Oaxaca (Unsplash, verificadas) — cohesionan con el
/// escenario de demo y con `trips/demo-seed`. Cuando entre A3 (fotos reales por
/// lugar), `location.photoUrl` gana y esto deja de usarse.
library;

const String _base = 'https://images.unsplash.com/photo-';
const String _query = '?w=1000&q=80&auto=format&fit=crop';

/// URL de foto por defecto para [category]. `''` si no hay categoría reconocible
/// — la UI usa entonces su placeholder (degradado + icono).
String defaultPhotoFor(String category) {
  final c = category.toLowerCase();
  String pick(String id) => '$_base$id$_query';

  if (c.contains('restau') ||
      c.contains('comida') ||
      c.contains('food') ||
      c.contains('gastro') ||
      c.contains('desayun') ||
      c.contains('cena')) {
    return pick('1414235077428-338989a2e8c0');
  }
  if (c.contains('bar') ||
      c.contains('mezcal') ||
      c.contains('café') ||
      c.contains('cafe') ||
      c.contains('cantina') ||
      c.contains('noche') ||
      c.contains('cocktail') ||
      c.contains('coctel')) {
    return pick('1516455207990-7a41ce80f7ee');
  }
  if (c.contains('mercado') || c.contains('market')) {
    return pick('1509440159596-0249088772ff');
  }
  if (c.contains('artesan') ||
      c.contains('taller') ||
      c.contains('compras') ||
      c.contains('tienda') ||
      c.contains('textil')) {
    return pick('1528825871115-3581a5387919');
  }
  if (c.contains('museo') || c.contains('museum') || c.contains('galer')) {
    return pick('1533105079780-92b9be482077');
  }
  if (c.contains('arqueolog') ||
      c.contains('ruina') ||
      c.contains('piramide') ||
      c.contains('pirámide') ||
      c.contains('zona arque')) {
    return pick('1518638150340-f706e86654de');
  }
  if (c.contains('templo') ||
      c.contains('iglesia') ||
      c.contains('catedral') ||
      c.contains('monument') ||
      c.contains('convento') ||
      c.contains('centro históric') ||
      c.contains('centro historic')) {
    return pick('1568402102990-bc541580b59f');
  }
  if (c.contains('cascada') ||
      c.contains('agua') ||
      c.contains('rio') ||
      c.contains('río') ||
      c.contains('lago') ||
      c.contains('playa') ||
      c.contains('mar ') ||
      c.contains('cenote')) {
    return pick('1583212292454-1fe6229603b7');
  }
  if (c.contains('natura') ||
      c.contains('parque') ||
      c.contains('jardin') ||
      c.contains('jardín') ||
      c.contains('mirador') ||
      c.contains('montaña') ||
      c.contains('bosque') ||
      c.contains('sierra') ||
      c.contains('cerro') ||
      c.contains('senderis') ||
      c.contains('hiking') ||
      c.contains('aventura')) {
    return pick('1425913397330-cf8af2ff40a1');
  }
  return '';
}
