import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Hero del itinerario: destino, fechas, presupuesto total y vibe tags.
class ItineraryHeader extends StatelessWidget {
  const ItineraryHeader({
    super.key,
    required this.summary,
    required this.profile,
    required this.status,
  });

  final Summary summary;
  final TravelerProfile? profile;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final destination =
        summary.destination.isNotEmpty ? summary.destination : 'Tu viaje';
    final dateRange = (summary.startDate.isNotEmpty && summary.endDate.isNotEmpty)
        ? formatDateRange(summary.startDate, summary.endDate)
        : null;
    final days = summary.totalDays > 0 ? summary.totalDays : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.siennaDark, AppColors.sienna],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null && status!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Tag(
                label: status == 'confirmed' ? 'Confirmado' : 'Borrador',
                icon: status == 'confirmed'
                    ? Icons.verified_rounded
                    : Icons.edit_note_rounded,
              ),
            ),
          Text(
            destination,
            style: displayFont(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (dateRange != null)
                _MetaLine(icon: Icons.calendar_today_rounded, text: dateRange),
              if (days != null)
                _MetaLine(
                  icon: Icons.wb_sunny_rounded,
                  text: days == 1 ? '1 día' : '$days días',
                ),
              if (profile != null && profile!.groupType.isNotEmpty)
                _MetaLine(
                  icon: Icons.group_rounded,
                  text: _groupLabel(profile!),
                ),
            ],
          ),
          if (summary.estimatedBudgetTotal > 0) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatMoney(summary.estimatedBudgetTotal, summary.currency),
                  style: displayFont(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'presupuesto estimado',
                  style: t.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
          if (summary.vibeTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in summary.vibeTags) _Tag(label: tag),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _groupLabel(TravelerProfile p) {
    final size = p.groupSize > 0 ? ' · ${p.groupSize}' : '';
    return '${p.groupType[0].toUpperCase()}${p.groupType.substring(1)}$size';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 9, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
