import 'package:flutter/material.dart';

/// Reputation tier derived from a provider's Service Quality Score (SQS).
/// SQS drives visibility (ranking, badges, job priority), never pricing.
class ProviderBadgeChip extends StatelessWidget {
  final String? badge;
  final double fontSize;

  const ProviderBadgeChip({
    super.key,
    required this.badge,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(badge);
    if (tier == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tier.color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tier.icon, size: 12, color: tier.color),
          const SizedBox(width: 3),
          Text(
            badge!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: tier.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeTier? _tierFor(String? badge) {
    if (badge == null || badge.isEmpty) return null;
    switch (badge.toUpperCase()) {
      case 'PLATINUM':
        return const _BadgeTier(Icons.diamond, Color(0xFF7B1FA2));
      case 'GOLD':
        return const _BadgeTier(Icons.workspace_premium, Color(0xFFB8860B));
      case 'SILVER':
        return const _BadgeTier(Icons.military_tech, Color(0xFF607D8B));
      case 'BRONZE':
        return const _BadgeTier(Icons.emoji_events, Color(0xFF8D6E63));
      default:
        return null;
    }
  }
}

class _BadgeTier {
  final IconData icon;
  final Color color;

  const _BadgeTier(this.icon, this.color);
}
