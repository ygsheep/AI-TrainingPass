import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/constants/touch_targets.dart';
import 'bottom_nav_bar.dart';

/// Top Navigation Bar for Tablet/Desktop
/// Material 3 styled top navigation with logo and navigation tabs
class TopNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Color? backgroundColor;

  const TopNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900; // Compact mode for smaller tablets

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurface : Colors.white),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey)
                .withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : Breakpoints.paddingXLarge,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Logo - smaller on compact screens
              _Logo(isDark: isDark, isCompact: isCompact),
              SizedBox(width: isCompact ? 24 : 48),

              // Navigation items - scrollable on compact screens
              Expanded(
                child: isCompact
                    ? _CompactNavigationItems(
                        items: items,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      )
                    : _FullNavigationItems(
                        items: items,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),
              ),

              // Settings button
              _SettingsButton(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full width navigation items for desktop
class _FullNavigationItems extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FullNavigationItems({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isActive = index == currentIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TopNavItem(
            item: item,
            isActive: isActive,
            onTap: () => onTap(index),
          ),
        );
      }).toList(),
    );
  }
}

/// Compact scrollable navigation for smaller tablets
class _CompactNavigationItems extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CompactNavigationItems({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _CompactNavItem(
              item: item,
              isActive: isActive,
              onTap: () => onTap(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Logo for Top Navigation Bar
class _Logo extends StatelessWidget {
  final bool isDark;
  final bool isCompact;

  const _Logo({required this.isDark, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 32.0 : 40.0;
    final fontSize = isCompact ? 16.0 : 20.0;
    final spacing = isCompact ? 8.0 : 12.0;

    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
          ),
          child: Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: isCompact ? 18 : 24,
          ),
        ),
        SizedBox(width: spacing),
        if (!isCompact)
          Text(
            'TrainingPass',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
      ],
    );
  }
}

/// Top Navigation Bar Item
class _TopNavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _TopNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Navigation Bar Item for smaller tablets
class _CompactNavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _CompactNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? activeColor : inactiveColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings Button for Top Navigation Bar
class _SettingsButton extends StatelessWidget {
  final bool isDark;

  const _SettingsButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '设置',
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        iconSize: 22,
        onPressed: () => context.go('/settings'),
        tooltip: '设置',
        style: IconButton.styleFrom(
          minimumSize: const Size(
            TouchTargets.iconButtonMedium,
            TouchTargets.iconButtonMedium,
          ),
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface.withValues(alpha: 0.5),
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
