import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../formatters.dart';

/// Cabecera del itinerario: destino, fechas, vibe tags y presupuesto total,
/// más una línea compacta con vuelos y hospedaje. Tolera bloques ausentes.
class ItineraryHeader extends StatelessWidget {
  const ItineraryHeader({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = trip.summary;
    final destination =
        (s?.destination.isNotEmpty ?? false) ? s!.destination : 'Tu viaje';
    final dateLabel = _dateLabel(s);
    final currency = s?.currency ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.sienna.withValues(alpha: 0.10),
            AppColors.sage.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.status == 'confirmed')
            const _Pill(icon: Icons.verified_outlined, label: 'Confirmado')
          else
            const _Pill(icon: Icons.edit_note, label: 'Borrador'),
          const SizedBox(height: 12),
          Text(
            destination,
            style: t.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          if (dateLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(dateLabel,
                    style: t.titleMedium?.copyWith(color: AppColors.muted)),
                if ((s?.totalDays ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  Text('· ${s!.totalDays} días',
                      style: t.titleMedium?.copyWith(color: AppColors.muted)),
                ],
              ],
            ),
          ],
          if ((s?.vibeTags ?? const []).isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in s!.vibeTags) _Tag(tag),
              ],
            ),
          ],
          if ((s?.estimatedBudgetTotal ?? 0) > 0) ...[
            const SizedBox(height: 18),
            Text('PRESUPUESTO ESTIMADO',
                style: t.labelSmall?.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                )),
            const SizedBox(height: 2),
            Text(
              money(s!.estimatedBudgetTotal, currency),
              style: t.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.sienna,
              ),
            ),
          ],
          if (trip.flights.isNotEmpty || trip.accommodation.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _LogisticsRow(trip: trip, currency: currency),
          ],
        ],
      ),
    );
  }

  String _dateLabel(Summary? s) {
    if (s == null) return '';
    if (s.startDate.isNotEmpty && s.endDate.isNotEmpty) {
      return prettyRange(s.startDate, s.endDate);
    }
    if (s.startDate.isNotEmpty) return prettyDate(s.startDate, withYear: true);
    return '';
  }
}

class _LogisticsRow extends StatelessWidget {
  const _LogisticsRow({required this.trip, required this.currency});

  final Trip trip;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (trip.flights.isNotEmpty) {
      final total = trip.flights.fold<num>(0, (a, f) => a + f.estimatedPrice);
      final airline = trip.flights.first.airline;
      items.add(_LogisticItem(
        icon: Icons.flight_takeoff,
        title: '${trip.flights.length} ${trip.flights.length == 1 ? 'vuelo' : 'vuelos'}'
            '${airline.isNotEmpty ? ' · $airline' : ''}',
        subtitle: total > 0 ? money(total, currency) : '',
      ));
    }

    for (final a in trip.accommodation) {
      final nights = _nights(a.checkIn, a.checkOut);
      items.add(_LogisticItem(
        icon: Icons.hotel,
        title: a.name.isEmpty ? 'Hospedaje' : a.name,
        subtitle: [
          if (a.area.isNotEmpty) a.area,
          if (nights != null) '$nights ${nights == 1 ? 'noche' : 'noches'}',
          if (a.estimatedPricePerNight > 0)
            '${money(a.estimatedPricePerNight, currency)}/noche',
        ].join(' · '),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  int? _nights(String checkIn, String checkOut) {
    final a = DateTime.tryParse(checkIn);
    final b = DateTime.tryParse(checkOut);
    if (a == null || b == null) return null;
    final n = b.difference(a).inDays;
    return n > 0 ? n : null;
  }
}

class _LogisticItem extends StatelessWidget {
  const _LogisticItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.sage),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: t.bodySmall?.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sienna.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: t.labelMedium?.copyWith(
          color: AppColors.sienna,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(label,
              style: t.labelSmall?.copyWith(
                color: AppColors.muted,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}
