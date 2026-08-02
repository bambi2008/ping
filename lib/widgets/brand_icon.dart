import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app/theme.dart';
import '../models/subscription.dart';

/// Shows the real brand logo from simpleicons CDN when available,
/// falls back to a themed Material Icon with brand color background.
class BrandIcon extends StatelessWidget {
  final String name;
  final Color? fallbackColor;
  final double size;
  final double borderRadius;

  const BrandIcon({
    super.key,
    required this.name,
    this.fallbackColor,
    this.size = 42,
    this.borderRadius = PingTheme.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = SubscriptionTheme.match(name);
    final color = fallbackColor ??
        theme?.color ??
        SubscriptionTheme.categoryColors['Other']!;

    if (theme != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: color.withValues(alpha: 0.12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: 'https://cdn.simpleicons.org/${theme.iconName}/${_colorHex(color)}/24',
            width: size * 0.55,
            height: size * 0.55,
            placeholder: (ctx, _) => _fallbackIcon(color),
            errorWidget: (ctx, _, __) => _fallbackIcon(color),
            fadeOutDuration: const Duration(milliseconds: 200),
            fadeInDuration: const Duration(milliseconds: 300),
          ),
        ),
      );
    }

    return _fallbackIcon(color);
  }

  Widget _fallbackIcon(Color color) {
    final icon = _getMaterialIcon(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }

  String _colorHex(Color c) {
    return c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  IconData _getMaterialIcon(String name) {
    const icons = {
      'netflix': Icons.movie, 'spotify': Icons.music_note,
      'disney+': Icons.movie_creation, 'icloud+': Icons.cloud,
      'apple': Icons.apple, 'youtube': Icons.play_circle,
      'youtube premium': Icons.play_circle, 'amazon prime': Icons.shopping_cart,
      'adobe cc': Icons.brush, 'google one': Icons.cloud_queue,
      'microsoft 365': Icons.computer, 'dropbox': Icons.inventory_2,
      'hbo max': Icons.live_tv, 'gym': Icons.fitness_center,
      'dazn': Icons.sports_soccer, 'sky': Icons.tv,
      'deezer': Icons.headphones, 'strava': Icons.directions_run,
      'deliveroo': Icons.delivery_dining, 'canal+': Icons.movie_filter,
      'rtl+': Icons.live_tv, 'zalando': Icons.checkroom,
      'bolt': Icons.electric_bolt, 'notion': Icons.article,
      'figma': Icons.design_services, 'github': Icons.code, 'gitlab': Icons.code,
    };
    return icons[name.toLowerCase()] ?? Icons.subscriptions_rounded;
  }
}
