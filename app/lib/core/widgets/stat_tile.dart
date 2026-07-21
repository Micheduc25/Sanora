import 'package:flutter/material.dart';

import 'bodi_card.dart';

/// Compact metric tile: icon, value, label, optional goal progress.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.progress,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final double? progress;
  final VoidCallback? onTap;

  /// Height the content needs at a text scale of 1.
  ///
  /// Grids lay these out with a `mainAxisExtent` built from this rather than a
  /// `childAspectRatio`: the content does not scale with width, so deriving
  /// height from it clipped the tile on narrow phones and fitted it on wide
  /// ones. Multiply by the ambient text scale — the type inside grows too.
  static const double preferredExtent = 148;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BodiCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          // A long value ("12,500 kcal") or a translated label that wraps must
          // shrink inside the tile rather than push the progress bar out.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
