import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/touch_targets.dart';

/// App Top Bar Widget
/// Material 3 styled top app bar with logo and actions
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onSettingsTap;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final double? elevation;
  final Color? backgroundColor;

  const AppTopBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.actions,
    this.onSettingsTap,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.darkSurface : Colors.white),
      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: showLogo
          ? _buildLogo(context, isDark)
          : (title != null ? _buildTitle(context, title!, isDark) : null),
      actions: _buildActions(context, isDark),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
        // App name
        Text(
          'TrainingPass',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleLarge.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  List<Widget>? _buildActions(BuildContext context, bool isDark) {
    if (actions != null) return actions;

    return [
      if (onSettingsTap != null)
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: onSettingsTap,
          tooltip: '设置',
          style: IconButton.styleFrom(
            minimumSize: const Size(TouchTargets.minimumSize, TouchTargets.minimumSize),
          ),
        ),
    ];
  }
}

/// Sliver App Top Bar
/// For use with CustomScrollView
class SliverAppTopBar extends StatelessWidget {
  final String? title;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onSettingsTap;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final double? elevation;

  const SliverAppTopBar({
    super.key,
    this.title,
    this.showLogo = true,
    this.actions,
    this.onSettingsTap,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      centerTitle: true,
      pinned: pinned,
      floating: floating,
      leading: leading,
      expandedHeight: showLogo ? 80 : kToolbarHeight,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: showLogo
            ? _buildLogo(context, isDark)
            : (title != null ? Text(title!) : null),
      ),
      actions: _buildActions(context, isDark),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'TrainingPass',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget>? _buildActions(BuildContext context, bool isDark) {
    if (actions != null) return actions;

    return [
      if (onSettingsTap != null)
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: onSettingsTap,
          tooltip: '设置',
        ),
    ];
  }
}

/// Back Button with custom styling
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      style: IconButton.styleFrom(
        minimumSize: const Size(TouchTargets.minimumSize, TouchTargets.minimumSize),
        foregroundColor: color ??
            (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      tooltip: '返回',
    );
  }
}

/// Close Button
class AppCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppCloseButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      icon: const Icon(Icons.close_rounded),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      style: IconButton.styleFrom(
        minimumSize: const Size(TouchTargets.minimumSize, TouchTargets.minimumSize),
        foregroundColor: color ??
            (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      tooltip: '关闭',
    );
  }
}
