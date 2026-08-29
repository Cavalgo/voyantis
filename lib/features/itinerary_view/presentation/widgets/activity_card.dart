import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import 'place_photo.dart';

/// Una parada del itinerario: foto, hora, título, descripción, costo y tip.
/// Un solo widget parametrizado para toda actividad (ver skills.md §7).
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loc = activity.location;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PlacePhoto(
                photoUrl: loc.photoUrl,
                category: loc.category,
                name: loc.name.isNotEmpty ? loc.name : activity.title,
                height: 172,
                borderRadius: 0,
              ),
              if (activity.time.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _Pill(
                    icon: Icons.schedule_rounded,
                    label: activity.time,
                  ),
                ),
              if (loc.instagrammable)
                const Positioned(
                  right: 12,
                  top: 12,
                  child: _Pill(
                    icon: Icons.camera_alt_rounded,
                    label: 'Instagrameable',
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        formatCost(activity.estimatedCost),
                        style: t.labelLarge?.copyWith(
                          color: AppColors.siennaDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (loc.name.isNotEmpty || loc.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          loc.address.isNotEmpty ? loc.address : loc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    activity.description,
                    style: t.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
                if (activity.tip.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 16, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.tip,
                            style: t.bodySmall?.copyWith(
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
