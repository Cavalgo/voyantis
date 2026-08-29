import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import 'activity_card.dart';

/// Una sección del timeline por día: encabezado (número, fecha, tema) + la
/// columna de actividades unidas por una línea vertical.
class TimelineDay extends StatelessWidget {
  const TimelineDay({super.key, required this.day, this.isLast = false});

  final Day day;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DayBadge(dayNumber: day.dayNumber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.theme.isNotEmpty)
                    Text(
                      day.theme,
                      style: displayFont(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.15,
                      ),
                    ),
                  if (day.date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        formatDayLabel(day.date),
                        style: t.labelMedium?.copyWith(
                          color: AppColors.muted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Riel vertical alineado al centro del badge.
              SizedBox(
                width: 32,
                child: Center(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.line,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                  child: Column(
                    children: [
                      for (var i = 0; i < day.activities.length; i++) ...[
                        ActivityCard(activity: day.activities[i]),
                        if (i != day.activities.length - 1)
                          const SizedBox(height: 14),
                      ],
                      if (day.activities.isEmpty)
                        Text(
                          'Día libre',
                          style: t.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.dayNumber});

  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.sienna,
        shape: BoxShape.circle,
      ),
      child: Text(
        dayNumber > 0 ? '$dayNumber' : '·',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
