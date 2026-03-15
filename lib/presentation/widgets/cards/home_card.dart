import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/touch_targets.dart';

/// Home Action Card
/// Swiss Modernism style - clean borders, no shadows, focus on content
class HomeCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final Color? backgroundColor;

  const HomeCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$title${subtitle != null ? ': $subtitle' : ''}',
      child: Material(
        color: backgroundColor ??
            (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(
              isPrimary
                  ? TouchTargets.paddingLarge
                  : TouchTargets.paddingMedium,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isPrimary ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: isPrimary ? 56 : 48,
                  height: isPrimary ? 56 : 48,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface)
                            .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: isPrimary ? 28 : 24,
                    color: isPrimary
                        ? AppColors.primary
                        : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)
                            .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: isPrimary
                      ? AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPrimary
                              ? AppColors.primary
                              : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary)
                                  .withValues(alpha: 0.9),
                        )
                      : AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                ),

                // Subtitle
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home Grid Layout
/// Responsive grid: 1 column (mobile) / 2 columns (tablet) / 4 columns (desktop)
/// Desktop uses a wider layout with max content width for better visual balance
class HomeGridLayout extends StatelessWidget {
  final List<Widget> children;

  const HomeGridLayout({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine columns based on screen width
        int columns;
        double maxWidth;
        if (constraints.maxWidth < Breakpoints.tablet) {
          columns = 1; // Mobile
          maxWidth = constraints.maxWidth;
        } else if (constraints.maxWidth < Breakpoints.desktop) {
          columns = 2; // Tablet
          maxWidth = constraints.maxWidth;
        } else {
          columns = 4; // Desktop - more columns for wider layout
          maxWidth = Breakpoints.maxContentWidth;
        }

        // Calculate aspect ratio based on columns
        double aspectRatio;
        switch (columns) {
          case 1:
            aspectRatio = 16 / 9; // Mobile: wider cards
            break;
          case 2:
            aspectRatio = 2.0; // Tablet: wider for better horizontal space use
            break;
          case 4:
          default:
            aspectRatio = 1.6; // Desktop: balanced aspect ratio
            break;
        }

        // Calculate spacing based on screen size
        final spacing = constraints.maxWidth < Breakpoints.tablet
            ? 16.0
            : constraints.maxWidth < Breakpoints.desktop
                ? 20.0
                : 24.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
