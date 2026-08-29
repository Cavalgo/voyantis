import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../formatters.dart';

/// Una parada del itinerario. Un solo widget parametrizado para toda actividad
/// (ver `mymds/skills.md` receta 7). Tolera foto vacía, tip vacío y costo 0.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.currency,
  });

  final Activity activity;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loc = activity.location;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Photo(url: loc.photoUrl, category: loc.category),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MetaLine(
                      time: activity.time,
                      category: loc.category,
                      instagrammable: loc.instagrammable,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.title,
                      style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (loc.name.isNotEmpty && loc.name != activity.title) ...[
                      const SizedBox(height: 2),
                      Text(
                        loc.name,
                        style: t.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        activity.description,
                        style: t.bodyMedium?.copyWith(height: 1.35),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _Footer(cost: activityCost(activity.estimatedCost, currency)),
                    if (activity.tip.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _Tip(text: activity.tip),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.category});

  final String url;
  final String category;

  @override
  Widget build(BuildContext context) {
    const side = 128.0;
    final fallback = Container(
      width: side,
      alignment: Alignment.center,
      color: AppColors.sage.withValues(alpha: 0.18),
      child: Icon(_iconFor(category), color: AppColors.sage, size: 30),
    );
    if (url.isEmpty) return fallback;
    return SizedBox(
      width: side,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.cream),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.time,
    required this.category,
    required this.instagrammable,
  });

  final String time;
  final String category;
  final bool instagrammable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bits = <Widget>[];

    if (time.isNotEmpty) {
      bits.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.sienna.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          time,
          style: t.labelMedium?.copyWith(
            color: AppColors.sienna,
            fontWeight: FontWeight.w700,
          ),
        ),
      ));
    }
    if (category.isNotEmpty) {
      bits.add(Text(
        category.toUpperCase(),
        style: t.labelSmall?.copyWith(
          color: AppColors.muted,
          letterSpacing: 0.6,
        ),
      ));
    }
    if (instagrammable) {
      bits.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera_outlined, size: 13, color: AppColors.muted),
          const SizedBox(width: 3),
          Text('foto', style: t.labelSmall?.copyWith(color: AppColors.muted)),
        ],
      ));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: bits,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.cost});

  final String cost;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(Icons.payments_outlined, size: 15, color: AppColors.muted),
        const SizedBox(width: 5),
        Text(
          cost,
          style: t.labelLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 15, color: AppColors.sienna),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: t.bodySmall?.copyWith(color: AppColors.ink, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('restaur') || c.contains('food') || c.contains('comida')) {
    return Icons.restaurant;
  }
  if (c.contains('bar') || c.contains('mezcal') || c.contains('cantina')) {
    return Icons.local_bar;
  }
  if (c.contains('museo') || c.contains('museum') || c.contains('galer')) {
    return Icons.museum;
  }
  if (c.contains('mercado') || c.contains('market') || c.contains('compra')) {
    return Icons.storefront;
  }
  if (c.contains('natur') || c.contains('parque') || c.contains('park') ||
      c.contains('mirador')) {
    return Icons.park;
  }
  if (c.contains('arqueo') || c.contains('ruina') || c.contains('monument') ||
      c.contains('templo') || c.contains('iglesia')) {
    return Icons.account_balance;
  }
  return Icons.place;
}
