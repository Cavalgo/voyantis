import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../formatters.dart';
import 'activity_card.dart';

/// Una sección del timeline = un día: encabezado (número, tema, fecha) + la
/// lista de actividades enlazadas por un riel vertical.
class TimelineDay extends StatelessWidget {
  const TimelineDay({
    super.key,
    required this.day,
    required this.currency,
    this.isLast = false,
  });

  final Day day;
  final String currency;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DayHeader(day: day),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Rail(faded: isLast),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < day.activities.length; i++) ...[
                        ActivityCard(
                          activity: day.activities[i],
                          currency: currency,
                        ),
                        if (i != day.activities.length - 1)
                          const SizedBox(height: 14),
                      ],
                      if (day.activities.isEmpty)
                        Text('Día libre',
                            style: t.bodyMedium
                                ?.copyWith(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final Day day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.sienna,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${day.dayNumber}',
            style: t.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.theme.isEmpty ? 'Día ${day.dayNumber}' : day.theme,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (day.date.isNotEmpty)
                Text(
                  prettyDate(day.date, withYear: true),
                  style: t.bodySmall?.copyWith(color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.faded});

  final bool faded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Center(
        child: SizedBox(
          width: 2,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.sienna.withValues(alpha: faded ? 0.15 : 0.30),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}
