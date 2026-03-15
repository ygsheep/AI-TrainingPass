import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import 'bottom_nav_bar.dart';
import 'top_nav_bar.dart';

/// Adaptive Navigation Widget
/// Shows BottomNavBar on mobile, TopNavBar on tablet/desktop
class AdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Widget child;

  const AdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      // Mobile: Bottom navigation bar
      return Scaffold(
        body: child,
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
        ),
      );
    } else {
      // Tablet/Desktop: Top navigation bar
      return Scaffold(
        body: Column(
          children: [
            TopNavBar(
              currentIndex: currentIndex,
              onTap: onTap,
              items: items,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }
  }
}

/// Helper class for responsive utilities
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet &&
      MediaQuery.of(context).size.width < Breakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;
}
