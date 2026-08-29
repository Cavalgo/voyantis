import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Bloques secundarios del itinerario: vuelos, hospedaje y desglose de
/// presupuesto. Todos toleran datos nulos/vacíos (no se renderizan si faltan).

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.sienna),
              const SizedBox(width: 8),
              Text(
                title,
                style: displayFont(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class FlightsSection extends StatelessWidget {
  const FlightsSection({super.key, required this.flights});

  final List<Flight> flights;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      icon: Icons.flight_takeoff_rounded,
      title: 'Vuelos',
      child: Column(
        children: [
          for (var i = 0; i < flights.length; i++) ...[
            Row(
              children: [
                Icon(
                  flights[i].type == 'return'
                      ? Icons.flight_land_rounded
                      : Icons.flight_takeoff_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${flights[i].from}  →  ${flights[i].to}',
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        [
                          if (flights[i].airline.isNotEmpty) flights[i].airline,
                          if (flights[i].date.isNotEmpty)
                            formatShortDate(flights[i].date.split('T').first),
                        ].join(' · '),
                        style: t.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (flights[i].estimatedPrice > 0)
                  Text(
                    formatCost(flights[i].estimatedPrice),
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.siennaDark,
                    ),
                  ),
              ],
            ),
            if (i != flights.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class AccommodationSection extends StatelessWidget {
  const AccommodationSection({super.key, required this.stays});

  final List<Accommodation> stays;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      icon: Icons.hotel_rounded,
      title: stays.length > 1 ? 'Hospedaje' : 'Dónde te quedas',
      child: Column(
        children: [
          for (var i = 0; i < stays.length; i++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stays[i].name.isNotEmpty ? stays[i].name : 'Hospedaje',
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (stays[i].estimatedPricePerNight > 0)
                      Text(
                        '${formatCost(stays[i].estimatedPricePerNight)} / noche',
                        style: t.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.siennaDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (stays[i].style.isNotEmpty) stays[i].style,
                    if (stays[i].area.isNotEmpty) stays[i].area,
                    if (stays[i].checkIn.isNotEmpty && stays[i].checkOut.isNotEmpty)
                      '${formatShortDate(stays[i].checkIn)} – ${formatShortDate(stays[i].checkOut)}',
                  ].join(' · '),
                  style: t.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            if (i != stays.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class BudgetSection extends StatelessWidget {
  const BudgetSection({super.key, required this.budget, required this.currency});

  final BudgetBreakdown budget;
  final String currency;

  static const List<Color> _palette = [
    AppColors.sienna,
    AppColors.sage,
    AppColors.gold,
    AppColors.siennaDark,
    AppColors.muted,
  ];

  @override
  Widget build(BuildContext context) {
    final all = <(String, num)>[
      ('Vuelos', budget.flights),
      ('Hospedaje', budget.accommodation),
      ('Actividades', budget.activities),
      ('Comida', budget.food),
      ('Colchón', budget.buffer),
    ];
    final rows = <(String, num, Color)>[
      for (var i = 0; i < all.length; i++)
        if (all[i].$2 > 0) (all[i].$1, all[i].$2, _palette[i]),
    ];

    final sum = rows.fold<num>(0, (s, r) => s + r.$2);
    final total = budget.total > 0 ? budget.total : sum;

    final t = Theme.of(context).textTheme;

    return SectionCard(
      icon: Icons.savings_rounded,
      title: 'Presupuesto',
      child: Column(
        children: [
          if (rows.isNotEmpty && sum > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (final r in rows)
                      Expanded(
                        flex: (r.$2 / sum * 1000).round().clamp(1, 1000).toInt(),
                        child: Container(color: r.$3),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: r.$3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(child: Text(r.$1, style: t.bodySmall)),
                  Text(
                    formatCost(r.$2),
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (total > 0) ...[
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  formatMoney(total, currency),
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.siennaDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
