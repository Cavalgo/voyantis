import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/place_images.dart';
import '../../../../core/theme/app_theme.dart';

/// Foto de un lugar. Si no viene `photoUrl` (lo normal en itinerarios que crea
/// el agente hoy) usa una foto genérica por categoría; si tampoco hay categoría
/// reconocible, cae a un placeholder degradado + icono.
class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.photoUrl,
    required this.category,
    required this.name,
    this.height = 180,
    this.borderRadius = 16,
  });

  final String photoUrl;
  final String category;
  final String name;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    // photoUrl real > foto genérica por categoría > placeholder degradado.
    final url = photoUrl.isNotEmpty ? photoUrl : defaultPhotoFor(category);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: url.isEmpty
            ? _Placeholder(category: category, name: name)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (_, _) => Container(
                  color: AppColors.sand,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) =>
                    _Placeholder(category: category, name: name),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.category, required this.name});

  final String category;
  final String name;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = _iconFor(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.white, 0.55)!,
            Color.lerp(tint, AppColors.ink, 0.08)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(icon, size: 128, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 26, color: Colors.white.withValues(alpha: 0.95)),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: displayFont(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('restau') || c.contains('comida') || c.contains('food')) {
      return (Icons.restaurant_rounded, AppColors.sienna);
    }
    if (c.contains('bar') || c.contains('mezcal') || c.contains('café') || c.contains('cafe')) {
      return (Icons.local_bar_rounded, AppColors.siennaDark);
    }
    if (c.contains('mercado') || c.contains('market') || c.contains('compras')) {
      return (Icons.storefront_rounded, AppColors.gold);
    }
    if (c.contains('museo') || c.contains('museum') || c.contains('galer')) {
      return (Icons.museum_rounded, AppColors.ink);
    }
    if (c.contains('monument') || c.contains('templo') || c.contains('iglesia') ||
        c.contains('arqueolog') || c.contains('ruina')) {
      return (Icons.account_balance_rounded, AppColors.siennaDark);
    }
    if (c.contains('natura') || c.contains('parque') || c.contains('playa') ||
        c.contains('cascada') || c.contains('montaña') || c.contains('mirador') ||
        c.contains('lago') || c.contains('bosque')) {
      return (Icons.landscape_rounded, AppColors.sage);
    }
    if (c.contains('hotel') || c.contains('hospedaje') || c.contains('hostal')) {
      return (Icons.hotel_rounded, AppColors.sienna);
    }
    if (c.contains('aventura') || c.contains('tour') || c.contains('activ')) {
      return (Icons.hiking_rounded, AppColors.sage);
    }
    return (Icons.place_rounded, AppColors.sienna);
  }
}
