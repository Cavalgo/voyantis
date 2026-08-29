import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../formatters.dart';

/// Desglose del presupuesto como barra apilada + lista. Se muestra al final del
/// timeline. Si todos los rubros son 0, el llamador no debería renderizarlo.
class BudgetBreakdownCard extends StatelessWidget {
  const BudgetBreakdownCard({
    super.key,
    required this.budget,
    required this.currency,
  });

  final BudgetBreakdown budget;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final rows = <_Row>[
      _Row('Vuelos', budget.flights, AppColors.sienna),
      _Row('Hospedaje', budget.accommodation, AppColors.sage),
      _Row('Actividades', budget.activities, const Color(0xFFC98A5B)),
      _Row('Comida', budget.food, const Color(0xFF9AA87F)),
      _Row('Reserva', budget.buffer, AppColors.muted),
    ].where((r) => r.value > 0).toList();

    final sum = rows.fold<num>(0, (a, r) => a + r.value);
    final total = budget.total > 0 ? budget.total : sum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Presupuesto',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(money(total, currency),
                  style: t.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.sienna,
                  )),
            ],
          ),
          if (rows.isNotEmpty && sum > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final r in rows)
                      Expanded(
                        flex: (r.value / sum * 1000).round().clamp(1, 1000).toInt(),
                        child: Container(color: r.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final r in rows) ...[
              _LegendRow(row: r, currency: currency),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value, this.color);
  final String label;
  final num value;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.row, required this.currency});

  final _Row row;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: row.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(row.label, style: t.bodyMedium)),
        Text(money(row.value, currency),
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
