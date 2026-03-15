import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/touch_targets.dart';

/// Bottom Navigation Bar Item Model
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// Bottom Navigation Bar Widget
/// Material 3 styled bottom navigation with 5 tabs
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Color? backgroundColor;
  final double? elevation;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.elevation,
  });

  /// Default navigation items for the app
  static const List<NavItem> defaultItems = [
    NavItem(
      label: '首页',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/',
    ),
    NavItem(
      label: '练习',
      icon: Icons.edit_note_outlined,
      activeIcon: Icons.edit_note,
      route: '/practice',
    ),
    NavItem(
      label: '考试',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz,
      route: '/exam',
    ),
    NavItem(
      label: '错题',
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      route: '/wrong-book',
    ),
    NavItem(
      label: '我的',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurface : Colors.white),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: TouchTargets.navigationBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == currentIndex;

              return Expanded(
                child: _NavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isActive ? 5 : 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? activeColor : inactiveColor,
                size: isActive ? 23 : 21,
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation Rail for Tablet/Desktop
/// Side navigation for larger screens
class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Color? backgroundColor;
  final bool extended;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Container(
      width: extended ? 200 : 80,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkSurface : Colors.white),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo (only for extended rail)
          if (extended) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TrainingPass',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Navigation items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == currentIndex;

            return _RailNavItem(
              item: item,
              isActive: isActive,
              extended: extended,
              onTap: () => onTap(index),
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              isDark: isDark,
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final bool extended;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;

  const _RailNavItem({
    required this.item,
    required this.isActive,
    required this.extended,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: TouchTargets.minimumSize,
        width: extended ? 200 : 80,
        padding: EdgeInsets.symmetric(
          horizontal: extended ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: extended
            ? Row(
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? activeColor : inactiveColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              )
            : Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? activeColor : inactiveColor,
                size: 26,
              ),
      ),
    );
  }
}
