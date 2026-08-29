// FASE 1 — verificación de contratos. No es una suite exhaustiva (ver
// mymds/rules.md): solo confirma que los modelos hacen round-trip contra el
// schema de `trips` y toleran campos ausentes.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:voyanties/core/models/models.dart';

/// Doc `trips` completo y realista — mismo contenido que `trips/demo-seed`.
Map<String, dynamic> fullTripJson() => {
      'tripId': 'demo-seed',
      'profileId': 'voyantis-demo',
      'status': 'draft',
      'createdAt': '2026-08-29T20:00:00.000Z',
      'updatedAt': '2026-08-29T20:30:00.000Z',
      'travelerProfile': {
        'originCity': 'Ciudad de México',
        'groupType': 'pareja',
        'groupSize': 2,
        'socialStyle': 'mixto',
        'paceStyle': 'balanceado',
        'interests': ['gastronomía', 'historia', 'arte', 'naturaleza'],
        'goals': {
          'instagrammable': true,
          'salirZonaConfort': false,
          'conocerGente': false,
          'desconectar': true,
        },
        'constraints': ['Sin restricciones alimenticias', 'Prefieren caminar'],
      },
      'summary': {
        'destination': 'Oaxaca de Juárez, México',
        'startDate': '2026-09-18',
        'endDate': '2026-09-20',
        'totalDays': 3,
        'vibeTags': ['cultural', 'gastronómico', 'relajado'],
        'estimatedBudgetTotal': 18000,
        'currency': 'MXN',
      },
      'flights': [
        {
          'type': 'outbound',
          'airline': 'Aeroméxico',
          'from': 'Ciudad de México (MEX)',
          'to': 'Oaxaca (OAX)',
          'date': '2026-09-18T08:30:00-06:00',
          'estimatedPrice': 2400,
        },
        {
          'type': 'return',
          'airline': 'Aeroméxico',
          'from': 'Oaxaca (OAX)',
          'to': 'Ciudad de México (MEX)',
          'date': '2026-09-20T20:15:00-06:00',
          'estimatedPrice': 2600,
        },
      ],
      'accommodation': [
        {
          'name': 'Hotel Casa Antonieta',
          'area': 'Centro Histórico',
          'checkIn': '2026-09-18',
          'checkOut': '2026-09-20',
          'estimatedPricePerNight': 2200,
          'style': 'boutique',
        },
      ],
      'days': [
        {
          'dayNumber': 1,
          'date': '2026-09-18',
          'theme': 'Centro histórico y sabores',
          'activities': [
            {
              'time': '13:00',
              'title': 'Comida en Los Danzantes',
              'description': 'Cocina oaxaqueña contemporánea en un patio abierto.',
              'location': {
                'name': 'Los Danzantes Oaxaca',
                'address': 'Macedonio Alcalá 403, Centro',
                'lat': 17.0611,
                'lng': -96.7236,
                'photoUrl':
                    'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',
                'category': 'restaurante',
                'instagrammable': true,
              },
              'estimatedCost': 650,
              'tip': 'Pide el mezcal de la casa antes de comer.',
            },
          ],
        },
      ],
      'budgetBreakdown': {
        'flights': 5000,
        'accommodation': 4400,
        'activities': 2890,
        'food': 3500,
        'buffer': 2210,
        'total': 18000,
      },
      'conversationContext':
          'Pareja de CDMX, 3 días en Oaxaca, presupuesto ~18k MXN.',
    };

void main() {
  test('Trip: fromJson(toJson(trip)) es idempotente (round-trip completo)', () {
    final source = fullTripJson();
    final trip = Trip.fromJson(source);
    final once = trip.toJson();
    final twice = Trip.fromJson(once).toJson();

    expect(jsonEncode(once), jsonEncode(twice));
  });

  test('Trip: los valores clave sobreviven el round-trip', () {
    final trip = Trip.fromJson(fullTripJson());

    expect(trip.tripId, 'demo-seed');
    expect(trip.profileId, 'voyantis-demo');
    expect(trip.updatedAt, isNotNull);
    expect(trip.summary!.destination, 'Oaxaca de Juárez, México');
    expect(trip.summary!.startDate, '2026-09-18'); // fecha de contenido = string
    expect(trip.travelerProfile!.goals['desconectar'], true);
    expect(trip.flights, hasLength(2));
    expect(trip.days.first.activities.first.location.lat, 17.0611);
    expect(trip.budgetBreakdown!.total, 18000);
  });

  test('Trip: tolera un doc vacío y campos ausentes', () {
    final trip = Trip.fromJson(const {});

    expect(trip.summary, isNull);
    expect(trip.travelerProfile, isNull);
    expect(trip.budgetBreakdown, isNull);
    expect(trip.flights, isEmpty);
    expect(trip.accommodation, isEmpty);
    expect(trip.days, isEmpty);
    expect(() => trip.toJson(), returnsNormally);
  });

  test('Trip: tolera que falten flights / accommodation / budgetBreakdown', () {
    final partial = fullTripJson()
      ..remove('flights')
      ..remove('accommodation')
      ..remove('budgetBreakdown');

    final trip = Trip.fromJson(partial);
    expect(trip.flights, isEmpty);
    expect(trip.accommodation, isEmpty);
    expect(trip.budgetBreakdown, isNull);
    expect(jsonEncode(trip.toJson()),
        jsonEncode(Trip.fromJson(trip.toJson()).toJson()));
  });

  test('Trip: normaliza un Timestamp-like en updatedAt (duck-typing)', () {
    final json = fullTripJson()..['updatedAt'] = _FakeTimestamp(_epochUtc());
    final trip = Trip.fromJson(json);

    expect(trip.updatedAt, isNotNull);
    expect(trip.updatedAt!.toUtc().toIso8601String(),
        _epochUtc().toIso8601String());
  });

  test('ChatRequest: round-trip y forma del body de /api/chat', () {
    const req = ChatRequest(
      profileId: 'voyantis-demo',
      tripId: null,
      messages: [
        ChatMessage.user('quiero un viaje a Oaxaca'),
        ChatMessage.assistant('¡genial! ¿cuántos días?'),
      ],
    );
    final json = req.toJson();

    expect(json['profileId'], 'voyantis-demo');
    expect(json['tripId'], isNull);
    expect((json['messages'] as List).first, {
      'role': 'user',
      'content': 'quiero un viaje a Oaxaca',
    });

    final back = ChatRequest.fromJson(json);
    expect(back.messages, hasLength(2));
    expect(back.messages.last.role, 'assistant');
  });

  test('ChatResponse: mapea la respuesta 501 del esqueleto sin crashear', () {
    final r = ChatResponse.fromJson(const {
      'reply': null,
      'tripId': null,
      'itinerarySaved': false,
      'error': 'not_implemented',
    });

    expect(r.reply, isNull);
    expect(r.hasError, isTrue);
    expect(r.isOk, isFalse);
    expect(r.itinerarySaved, isFalse);
  });

  test('ChatResponse: mapea una respuesta OK con itinerario guardado', () {
    final r = ChatResponse.fromJson(const {
      'reply': 'listo, guardé tu itinerario',
      'tripId': 'abc123',
      'itinerarySaved': true,
      'error': null,
    });

    expect(r.isOk, isTrue);
    expect(r.tripId, 'abc123');
    expect(r.itinerarySaved, isTrue);
  });
}

DateTime _epochUtc() => DateTime.utc(2026, 8, 29, 20, 30, 0);

/// Imita `cloud_firestore` `Timestamp` sin importar el paquete: `jDate` solo
/// necesita que exista `.toDate()`.
class _FakeTimestamp {
  _FakeTimestamp(this._dt);
  final DateTime _dt;
  DateTime toDate() => _dt;
}
