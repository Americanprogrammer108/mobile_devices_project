import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/expiry_utils.dart';

/**
 * Text colour for expiry messages like "Expires tomorrow". Red for
 * today, tomorrow, or orange otherwise.
 */
///
Color expiresColor(int days) =>
    days <= 1 ? AppColors.iconRed : AppColors.fontOrange;

// The coloured pill showing how long until the item expires
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    // Red for 1 day or less, oranges for soon, green otherwise
    final (background, foreground) = switch (days) {
      <= 1 => (AppColors.badgeRed, AppColors.iconRed),
      <= expiringSoonDays => (AppColors.badgeYellow, AppColors.fontOrange),
      _ => (AppColors.badgeGreen, AppColors.fontGreen),
    };

    final label = switch (days) {
      < 0 => 'Expired',
      0 => 'Today',
      1 => '1 day',
      _ => '$days days',
    };

    return Container(
      constraints: const BoxConstraints(minWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
