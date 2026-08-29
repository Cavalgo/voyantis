/**
 * seed_firestore.mjs — crea/actualiza el doc `trips/demo-seed` en Firestore.
 *
 * FASE 1 §1.4: un doc `trips` completo y realista que desbloquea a Track B
 * (construyen el timeline contra este doc) y es el escenario de respaldo del pitch.
 *
 * Cómo funciona: las reglas de Firestore están abiertas (modo demo), así que la
 * REST API acepta la Web API key sin OAuth. Escribe con `:commit` + un transform
 * para que `updatedAt` sea server timestamp real.
 *
 * Uso:
 *   node scripts/seed_firestore.mjs
 *
 * No necesita gcloud ni service account. Requiere Node 18+ (fetch global).
 */

const PROJECT_ID = "mi-viaje-11d84";
// Web API key — pública por diseño (misma que lib/firebase_options.dart).
const API_KEY = "AIzaSyBEg0E0HZVT3uY8L8g4ft1y_TGa9LTCFo4";
const DOC_ID = "demo-seed";

const DOC_PATH = `projects/${PROJECT_ID}/databases/(default)/documents/trips/${DOC_ID}`;
const COMMIT_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit?key=${API_KEY}`;

// ── Contenido del seed ───────────────────────────────────────────────────────
// Oaxaca, 3 días, pareja de CDMX. Fotos: Unsplash (Track A/pitch las cambia por
// fotos reales de Google Places). Fechas de contenido = string ISO 8601.
const photo = (id) => `https://images.unsplash.com/photo-${id}?w=1000&q=80&auto=format&fit=crop`;

const trip = {
  profileId: "voyantis-demo",
  status: "draft",
  createdAt: new Date(),

  travelerProfile: {
    originCity: "Ciudad de México",
    groupType: "pareja",
    groupSize: 2,
    socialStyle: "mixto",
    paceStyle: "balanceado",
    interests: ["gastronomía", "historia", "arte", "naturaleza"],
    goals: {
      instagrammable: true,
      salirZonaConfort: false,
      conocerGente: false,
      desconectar: true,
    },
    constraints: [
      "Sin restricciones alimenticias",
      "Prefieren caminar; evitar trayectos largos en auto",
    ],
  },

  summary: {
    destination: "Oaxaca de Juárez, México",
    startDate: "2026-09-18",
    endDate: "2026-09-20",
    totalDays: 3,
    vibeTags: ["cultural", "gastronómico", "relajado"],
    estimatedBudgetTotal: 18000,
    currency: "MXN",
  },

  flights: [
    {
      type: "outbound",
      airline: "Aeroméxico",
      from: "Ciudad de México (MEX)",
      to: "Oaxaca (OAX)",
      date: "2026-09-18T08:30:00-06:00",
      estimatedPrice: 2400,
    },
    {
      type: "return",
      airline: "Aeroméxico",
      from: "Oaxaca (OAX)",
      to: "Ciudad de México (MEX)",
      date: "2026-09-20T20:15:00-06:00",
      estimatedPrice: 2600,
    },
  ],

  accommodation: [
    {
      name: "Hotel Casa Antonieta",
      area: "Centro Histórico",
      checkIn: "2026-09-18",
      checkOut: "2026-09-20",
      estimatedPricePerNight: 2200,
      style: "boutique",
    },
  ],

  days: [
    {
      dayNumber: 1,
      date: "2026-09-18",
      theme: "Centro histórico y sabores",
      activities: [
        {
          time: "13:00",
          title: "Comida en Los Danzantes",
          description:
            "Cocina oaxaqueña contemporánea alrededor de un patio abierto, a un paso de Santo Domingo.",
          location: {
            name: "Los Danzantes Oaxaca",
            address: "Macedonio Alcalá 403, Centro, Oaxaca de Juárez",
            lat: 17.0614,
            lng: -96.7236,
            photoUrl: photo("1414235077428-338989a2e8c0"),
            category: "restaurante",
            instagrammable: true,
          },
          estimatedCost: 650,
          tip: "Reserva con un día de anticipación y pide mesa en el patio.",
        },
        {
          time: "16:00",
          title: "Templo de Santo Domingo de Guzmán",
          description:
            "Retablos dorados y el jardín etnobotánico anexo. El interior es de los más impresionantes de México.",
          location: {
            name: "Templo de Santo Domingo de Guzmán",
            address: "Macedonio Alcalá s/n, Centro, Oaxaca de Juárez",
            lat: 17.0654,
            lng: -96.7231,
            photoUrl: photo("1568402102990-bc541580b59f"),
            category: "monumento",
            instagrammable: true,
          },
          estimatedCost: 0,
          tip: "La luz de la tarde entra por el poniente: mejores fotos ~17:30.",
        },
        {
          time: "19:00",
          title: "Mezcalería In Situ",
          description:
            "Más de 100 mezcales de productores pequeños. El dueño, Ulises Torrentera, es una enciclopedia viva.",
          location: {
            name: "In Situ Mezcalería",
            address: "José María Morelos 511, Centro, Oaxaca de Juárez",
            lat: 17.0606,
            lng: -96.7256,
            photoUrl: photo("1516455207990-7a41ce80f7ee"),
            category: "bar",
            instagrammable: false,
          },
          estimatedCost: 500,
          tip: "Pide una cata comparada de espadín vs. tobalá.",
        },
      ],
    },
    {
      dayNumber: 2,
      date: "2026-09-19",
      theme: "Naturaleza y artesanía en los Valles Centrales",
      activities: [
        {
          time: "08:00",
          title: "Hierve el Agua",
          description:
            "Cascadas petrificadas y pozas de borde infinito sobre el valle. Salir temprano evita el gentío.",
          location: {
            name: "Hierve el Agua",
            address: "San Isidro Roaguía, San Lorenzo Albarradas, Oaxaca",
            lat: 16.8664,
            lng: -96.2761,
            photoUrl: photo("1583212292454-1fe6229603b7"),
            category: "naturaleza",
            instagrammable: true,
          },
          estimatedCost: 400,
          tip: "~2 h en auto. Lleva efectivo para las cuotas comunitarias.",
        },
        {
          time: "13:30",
          title: "Comida en Teotitlán del Valle",
          description:
            "Pueblo de tejedores de tapetes de lana teñida con grana cochinilla y añil. Comida de olla en fonda local.",
          location: {
            name: "Teotitlán del Valle",
            address: "Teotitlán del Valle, Oaxaca",
            lat: 17.0306,
            lng: -96.5225,
            photoUrl: photo("1528825871115-3581a5387919"),
            category: "restaurante",
            instagrammable: false,
          },
          estimatedCost: 350,
          tip: "Muchos talleres ofrecen demostración de teñido gratis si compras algo.",
        },
        {
          time: "17:30",
          title: "Árbol del Tule",
          description:
            "El árbol de tronco más ancho del mundo (~42 m de perímetro). Parada corta de camino de regreso.",
          location: {
            name: "Árbol del Tule",
            address: "Santa María del Tule, Oaxaca",
            lat: 17.0468,
            lng: -96.6361,
            photoUrl: photo("1425913397330-cf8af2ff40a1"),
            category: "naturaleza",
            instagrammable: true,
          },
          estimatedCost: 40,
          tip: "Niños del pueblo te muestran figuras en el tronco por una propina.",
        },
      ],
    },
    {
      dayNumber: 3,
      date: "2026-09-20",
      theme: "Monte Albán y despedida en el mercado",
      activities: [
        {
          time: "09:00",
          title: "Zona Arqueológica de Monte Albán",
          description:
            "Capital zapoteca sobre una montaña aplanada a mano, con vista de 360° a los tres brazos del valle.",
          location: {
            name: "Monte Albán",
            address: "Ex Hacienda de Xoxocotlán, Oaxaca",
            lat: 17.0439,
            lng: -96.7677,
            photoUrl: photo("1518638150340-f706e86654de"),
            category: "arqueología",
            instagrammable: true,
          },
          estimatedCost: 95,
          tip: "Abre 8:00. Llega temprano: sin sombra y a mediodía pega fuerte.",
        },
        {
          time: "13:00",
          title: "Pasillo de Humo — Mercado 20 de Noviembre",
          description:
            "Eliges tu tasajo o cecina en un puesto y te lo asan al carbón ahí mismo. Con memelas y agua de chilacayota.",
          location: {
            name: "Mercado 20 de Noviembre",
            address: "20 de Noviembre s/n, Centro, Oaxaca de Juárez",
            lat: 17.0585,
            lng: -96.7256,
            photoUrl: photo("1509440159596-0249088772ff"),
            category: "mercado",
            instagrammable: true,
          },
          estimatedCost: 220,
          tip: "Compra la carne por peso primero; las guarniciones se piden aparte.",
        },
        {
          time: "16:00",
          title: "Museo de las Culturas de Oaxaca",
          description:
            "En el ex convento de Santo Domingo. Guarda el Tesoro de la Tumba 7 de Monte Albán.",
          location: {
            name: "Museo de las Culturas de Oaxaca",
            address: "Macedonio Alcalá s/n, Centro, Oaxaca de Juárez",
            lat: 17.0656,
            lng: -96.7225,
            photoUrl: photo("1533105079780-92b9be482077"),
            category: "museo",
            instagrammable: false,
          },
          estimatedCost: 90,
          tip: "Última entrada 16:15. La sala de la Tumba 7 está casi al final.",
        },
      ],
    },
  ],

  budgetBreakdown: {
    flights: 5000,
    accommodation: 4400,
    activities: 2890,
    food: 3500,
    buffer: 2210,
    total: 18000,
  },

  conversationContext:
    "Pareja de CDMX (2 personas), ritmo balanceado, estilo social mixto. Quieren desconectar y fotos instagrameables. Intereses: gastronomía, historia, arte, naturaleza. Sin restricciones alimenticias; prefieren caminar. Viaje CONFIRMADO a Oaxaca de Juárez, 18–20 sep 2026 (3 días), presupuesto ~18,000 MXN. Hotel boutique en el Centro (Casa Antonieta). Estructura decidida: D1 centro histórico + mezcal, D2 Hierve el Agua + Teotitlán del Valle, D3 Monte Albán + Mercado 20 de Noviembre. Pendiente: valorar añadir una clase de cocina la tarde del D2.",
};

// ── Conversión a Firestore REST typed values ─────────────────────────────────
function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") {
    return Number.isInteger(v)
      ? { integerValue: String(v) }
      : { doubleValue: v };
  }
  if (typeof v === "string") return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === "object") return { mapValue: { fields: toFields(v) } };
  throw new Error(`Tipo no soportado: ${typeof v}`);
}

function toFields(obj) {
  const fields = {};
  for (const [k, val] of Object.entries(obj)) fields[k] = toValue(val);
  return fields;
}

// ── Escritura ────────────────────────────────────────────────────────────────
async function main() {
  const body = {
    writes: [
      {
        update: { name: DOC_PATH, fields: toFields(trip) },
        // updatedAt = server timestamp real (para el orderBy de watchCurrentTrip).
        updateTransforms: [
          { fieldPath: "updatedAt", setToServerValue: "REQUEST_TIME" },
        ],
      },
    ],
  };

  const res = await fetch(COMMIT_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const text = await res.text();
  if (!res.ok) {
    console.error(`❌ HTTP ${res.status}\n${text}`);
    process.exit(1);
  }

  const json = JSON.parse(text);
  const writeTime = json.writeResults?.[0]?.updateTime ?? json.commitTime;
  console.log(`✅ trips/${DOC_ID} escrito. updateTime: ${writeTime}`);
  console.log(
    `   Consola: https://console.firebase.google.com/project/${PROJECT_ID}/firestore/data/~2Ftrips~2F${DOC_ID}`,
  );
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
