import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/download_util.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../providers/config_provider.dart';
import '../../providers/question_provider.dart';
import '../../providers/question_update_provider.dart';
import '../../providers/data_export_provider.dart';
import '../question_update/question_update_page.dart';

/// Settings Page
/// User settings and app configuration
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settingsState = ref.watch(userSettingsProvider);

    // Show loading state
    if (settingsState.isLoading) {
      return Scaffold(
        appBar: AppTopBar(
          title: '设置',
          automaticallyImplyLeading: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (settingsState.error != null) {
      return Scaffold(
        appBar: AppTopBar(
          title: '设置',
          automaticallyImplyLeading: true,
        ),
        body: Center(child: Text('加载失败：${settingsState.error}')),
      );
    }

    final settings = settingsState.settings;
    if (settings == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: '设置',
          automaticallyImplyLeading: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: '设置',
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        children: [
          // User info section
          _SectionHeader(title: '账号', isDark: isDark),
          _UserStatsCard(isDark: isDark),
          const SizedBox(height: 24),

          // Display settings
          _SectionHeader(title: '显示', isDark: isDark),
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            title: '深色模式',
            subtitle: _getThemeModeLabel(settings.themeMode),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'system',
                  label: Text('跟随', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'light',
                  label: Text('浅色', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: Text('深色', style: TextStyle(fontSize: 12)),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) {
                ref.read(userSettingsProvider.notifier).updateThemeMode(
                      value.first,
                    );
              },
              style: SegmentedButton.styleFrom(
                minimumSize: const Size(180, 36),
              ),
            ),
          ),
          _SettingTile(
            icon: Icons.text_fields_rounded,
            title: '字体大小',
            subtitle: _getTextSizeLabel(settings.textSize),
            trailing: DropdownButton<int>(
              value: settings.textSize,
              items: const [
                DropdownMenuItem(value: 0, child: Text('小')),
                DropdownMenuItem(value: 1, child: Text('中')),
                DropdownMenuItem(value: 2, child: Text('大')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(userSettingsProvider.notifier).updateTextSize(value);
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Practice settings
          _SectionHeader(title: '练习设置', isDark: isDark),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_rounded),
            title: Text(
              '显示解析',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '答题后显示答案解析',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            value: settings.showExplanations,
            onChanged: (value) {
              ref.read(userSettingsProvider.notifier).toggleShowExplanations();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timer_rounded),
            title: Text(
              '显示计时器',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '答题时显示用时',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            value: settings.showTimer,
            onChanged: (value) {
              ref.read(userSettingsProvider.notifier).toggleShowTimer();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_mode_rounded),
            title: Text(
              '自动提交',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '选择答案后自动提交',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            value: settings.autoSubmit,
            onChanged: (value) {
              ref.read(userSettingsProvider.notifier).toggleAutoSubmit();
            },
          ),
          const SizedBox(height: 24),

          // Data section
          _SectionHeader(title: '数据', isDark: isDark),
          _SettingTile(
            icon: Icons.cloud_download_rounded,
            title: '导入题库',
            subtitle: '从文件导入题目',
            onTap: () => _showImportDialog(context),
          ),
          _SettingTile(
            icon: Icons.cloud_upload_rounded,
            title: '导出数据',
            subtitle: '导出答题记录',
            onTap: () => _showExportDialog(context),
          ),
          _SettingTile(
            icon: Icons.delete_outline_rounded,
            title: '清除数据',
            subtitle: '删除所有本地数据',
            titleColor: AppColors.error,
            onTap: () => _showClearDataDialog(context),
          ),
          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: '关于', isDark: isDark),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            title: '关于 TrainingPass',
            subtitle: 'v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),

          // Bottom padding
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getThemeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      case 'system':
      default:
        return '跟随系统';
    }
  }

  String _getTextSizeLabel(int size) {
    switch (size) {
      case 0:
        return '小';
      case 2:
        return '大';
      case 1:
      default:
        return '中';
    }
  }

  void _showImportDialog(BuildContext context) {
    // Navigate to question update page
    context.push('/question-update');
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final exportState = ref.watch(dataExportProvider);
          final hasData = (exportState.statistics?['total'] ?? 0) > 0;

          return AlertDialog(
            title: const Text('导出数据'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('确定要导出所有答题记录吗？'),
                const SizedBox(height: 16),
                if (exportState.statistics != null) ...[
                  Text(
                    '包含数据：',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: '答题记录',
                    count: exportState.statistics!['user_answers'] ?? 0,
                  ),
                  _StatRow(
                    label: '考试记录',
                    count: exportState.statistics!['exam_records'] ?? 0,
                  ),
                  _StatRow(
                    label: '错题记录',
                    count: exportState.statistics!['wrong_questions'] ?? 0,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: hasData && !exportState.isExporting
                    ? () async {
                        Navigator.of(context).pop();
                        await _exportData(context);
                      }
                    : null,
                child: exportState.isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('导出'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在导出数据...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      if (kIsWeb) {
        // Web: Download as file using platform-specific download utility
        final jsonString = await ref.read(dataExportProvider.notifier).getExportJsonString();
        final filename = 'trainingpass_export_${DateTime.now().toIso8601String().split('T')[0]}.json';

        await downloadString(jsonString, filename);

        if (context.mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog(context, 0);
        }
      } else {
        // IO: Use provider to export
        await ref.read(dataExportProvider.notifier).exportToFile();

        if (context.mounted) {
          Navigator.of(context).pop();
          final state = ref.read(dataExportProvider);
          if (state.isSuccess) {
            _showSuccessDialog(context, state.totalRecords ?? 0);
          } else if (state.error != null) {
            _showError(context, state.error!);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, '导出失败: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog(BuildContext context, int recordCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 48,
        ),
        title: const Text('导出成功'),
        content: Text('已导出 $recordCount 条记录'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('确定要删除所有本地数据吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData(BuildContext context) async {
    try {
      AppLogger.debug('🗑️ Clearing user data...');

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在清除数据...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Clear user data (preserves question bank)
      await ref.read(questionRepositoryProvider).clearUserData();

      AppLogger.debug('✅ User data cleared successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据已清除'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.debug('❌ Failed to clear data: $e');

      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败：$e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TrainingPass',
      applicationVersion: 'v1.0.0',
      applicationIcon: const Icon(
        Icons.school_rounded,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text('一个简洁高效的答题考试应用'),
        const SizedBox(height: 16),
        const Text('使用 Flutter 构建'),
      ],
    );
  }
}

/// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TouchTargets.paddingMedium,
        TouchTargets.paddingMedium,
        TouchTargets.paddingMedium,
        TouchTargets.paddingSmall,
      ),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// User Stats Card
class _UserStatsCard extends ConsumerStatefulWidget {
  final bool isDark;

  const _UserStatsCard({required this.isDark});

  @override
  ConsumerState<_UserStatsCard> createState() => _UserStatsCardState();
}

class _UserStatsCardState extends ConsumerState<_UserStatsCard> {
  @override
  void initState() {
    super.initState();
    // Load progress when widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyProgressProvider.notifier).loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(studyProgressProvider);

    // Handle loading and error states
    if (progressState.isLoading || progressState.progress == null) {
      return const SizedBox();
    }

    final progress = progressState.progress!;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: TouchTargets.paddingMedium,
      ),
      padding: const EdgeInsets.all(TouchTargets.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '学习统计',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatItem(
                      label: '天数',
                      value: '${progress.studyDays}',
                    ),
                    const SizedBox(width: 16),
                    _StatItem(
                      label: '答题',
                      value: '${progress.totalAnswered}',
                    ),
                    const SizedBox(width: 16),
                    _StatItem(
                      label: '正确率',
                      value: progress.totalAnswered > 0
                          ? '${(progress.correctCount * 100 ~/ progress.totalAnswered)}%'
                          : '0%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat Item
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Setting Tile
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: titleColor ??
            (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                .withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: titleColor ??
              (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TouchTargets.paddingMedium,
        vertical: TouchTargets.paddingSmall,
      ),
    );
  }
}

/// Stat Row Widget for Export Dialog
class _StatRow extends StatelessWidget {
  final String label;
  final int count;

  const _StatRow({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          Text(
            '$count 条',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
