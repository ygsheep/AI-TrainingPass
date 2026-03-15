import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/touch_targets.dart';
import '../../../../core/utils/app_logger.dart';
import '../../widgets/appbars/app_top_bar.dart';
import '../../providers/question_update_provider.dart';
import '../../../../data/services/question_update_service.dart';
import 'package:file_picker/file_picker.dart';

/// Question Update Page
/// Allows users to update question bank from network or local file
class QuestionUpdatePage extends ConsumerStatefulWidget {
  const QuestionUpdatePage({super.key});

  @override
  ConsumerState<QuestionUpdatePage> createState() => _QuestionUpdatePageState();
}

class _QuestionUpdatePageState extends ConsumerState<QuestionUpdatePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isUrlValid = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    setState(() {
      _isUrlValid = Uri.tryParse(_urlController.text)?.hasAbsolutePath ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final updateState = ref.watch(questionUpdateProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: '题库更新',
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TouchTargets.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current version info card
            _VersionInfoCard(
              isDark: isDark,
              currentVersion: updateState.currentVersion,
              questionCount: updateState.currentQuestionCount,
            ),

            const SizedBox(height: 24),

            // Network update section
            _SectionHeader(title: '网络更新', isDark: isDark),
            _NetworkUpdateSection(
              controller: _urlController,
              isUrlValid: _isUrlValid,
              isChecking: updateState.isChecking,
              isUpdating: updateState.isUpdating,
              hasUpdate: updateState.hasUpdateAvailable,
              availableUpdate: updateState.availableUpdate,
              onCheck: () => _checkForUpdates(),
              onUpdate: () => _updateFromUrl(),
            ),

            const SizedBox(height: 24),

            // Local file import section
            _SectionHeader(title: '本地文件', isDark: isDark),
            _LocalFileSection(
              isUpdating: updateState.isUpdating,
              onImport: () => _importLocalFile(),
            ),

            const SizedBox(height: 24),

            // Error display
            if (updateState.error != null)
              _ErrorCard(
                error: updateState.error!,
                onDismiss: () => ref.read(questionUpdateProvider.notifier).clearError(),
              ),

            // Bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Check for updates
  Future<void> _checkForUpdates() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('请输入更新URL');
      return;
    }

    await ref.read(questionUpdateProvider.notifier).checkForUpdates(url);

    if (mounted) {
      final state = ref.read(questionUpdateProvider);
      if (state.error == null && !state.hasUpdateAvailable) {
        _showSuccess('题库已是最新版本');
      } else if (state.error != null) {
        _showError(state.error!);
      }
    }
  }

  /// Update from URL
  Future<void> _updateFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('请输入更新URL');
      return;
    }

    final confirmed = await _showUpdateConfirmDialog();
    if (!confirmed) return;

    await ref.read(questionUpdateProvider.notifier).updateFromUrl(url);

    if (mounted) {
      final state = ref.read(questionUpdateProvider);
      if (state.isSuccess) {
        _showSuccessDialog(
          questionCount: state.updatedQuestionCount ?? 0,
          newVersion: state.newVersion ?? '未知',
        );
      } else if (state.error != null) {
        _showError(state.error!);
      }
    }
  }

  /// Import local file
  Future<void> _importLocalFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Use kIsWeb for reliable platform detection
      if (kIsWeb) {
        // Web platform - use bytes
        if (result.files.single.bytes != null) {
          final bytes = result.files.single.bytes!;
          // Use utf8.decode to properly handle UTF-8 encoded content (Chinese characters)
          final jsonString = utf8.decode(bytes);
          final confirmed = await _showImportConfirmDialog(result.files.single.name);
          if (!confirmed) return;

          await ref.read(questionUpdateProvider.notifier).importFromJsonString(jsonString);

          if (mounted) {
            final state = ref.read(questionUpdateProvider);
            if (state.isSuccess) {
              _showSuccessDialog(
                questionCount: state.updatedQuestionCount ?? 0,
                newVersion: state.newVersion ?? '未知',
              );
            } else if (state.error != null) {
              _showError(state.error!);
            }
          }
        }
      } else {
        // IO platform - use path
        if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final confirmed = await _showImportConfirmDialog(file.path);
          if (!confirmed) return;

          await ref.read(questionUpdateProvider.notifier).importFromFile(file);

          if (mounted) {
            final state = ref.read(questionUpdateProvider);
            if (state.isSuccess) {
              _showSuccessDialog(
                questionCount: state.updatedQuestionCount ?? 0,
                newVersion: state.newVersion ?? '未知',
              );
            } else if (state.error != null) {
              _showError(state.error!);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.debug('❌ Error importing file: $e');
      if (mounted) {
        _showError('导入失败: ${e.toString()}');
      }
    }
  }

  /// Show update confirmation dialog
  Future<bool> _showUpdateConfirmDialog() async {
    final state = ref.read(questionUpdateProvider);
    final update = state.availableUpdate;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本: ${state.currentVersion ?? "未知"}'),
            Text('新版本: ${update?.formatVersion ?? "未知"}'),
            const SizedBox(height: 8),
            if (update?.totalQuestions != null)
              Text('题目数量: ${update!.totalQuestions}'),
            const SizedBox(height: 16),
            const Text('更新将覆盖现有题库，是否继续？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认更新'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show import confirmation dialog
  Future<bool> _showImportConfirmDialog(String fileName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件: $fileName'),
            const SizedBox(height: 16),
            const Text('导入将覆盖现有题库，是否继续？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认导入'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show success dialog
  void _showSuccessDialog({
    required int questionCount,
    required String newVersion,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 48,
        ),
        title: const Text('更新成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: $newVersion'),
            Text('题目数量: $questionCount'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear success state
              ref.read(questionUpdateProvider.notifier).reset();
            },
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

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Version Info Card
class _VersionInfoCard extends StatelessWidget {
  final bool isDark;
  final String? currentVersion;
  final int? questionCount;

  const _VersionInfoCard({
    required this.isDark,
    this.currentVersion,
    this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TouchTargets.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前题库',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本 ${currentVersion ?? "未知"}',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (questionCount != null)
                  Text(
                    '$questionCount 道题目',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(
        left: TouchTargets.paddingSmall,
        bottom: TouchTargets.paddingSmall,
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

/// Network Update Section
class _NetworkUpdateSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isUrlValid;
  final bool isChecking;
  final bool isUpdating;
  final bool hasUpdate;
  final QuestionBankMetadata? availableUpdate;
  final VoidCallback onCheck;
  final VoidCallback onUpdate;

  const _NetworkUpdateSection({
    required this.controller,
    required this.isUrlValid,
    required this.isChecking,
    required this.isUpdating,
    required this.hasUpdate,
    this.availableUpdate,
    required this.onCheck,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TouchTargets.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL input
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '更新URL',
                hintText: 'https://example.com/questions.json',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
              enabled: !isChecking && !isUpdating,
            ),
            const SizedBox(height: 16),

            // Check button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isChecking || isUpdating) ? null : onCheck,
                icon: isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(isChecking ? '检查中...' : '检查更新'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Update available notice
            if (hasUpdate && availableUpdate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.new_releases_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '发现新版本',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '版本: ${availableUpdate?.formatVersion ?? "未知"}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (availableUpdate?.updatedAt != null)
                      Text(
                        '更新日期: ${availableUpdate!.updatedAt}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    if (availableUpdate?.totalQuestions != null)
                      Text(
                        '题目数量: ${availableUpdate!.totalQuestions}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUpdating ? null : onUpdate,
                        icon: isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(isUpdating ? '更新中...' : '立即更新'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Local File Section
class _LocalFileSection extends StatelessWidget {
  final bool isUpdating;
  final VoidCallback onImport;

  const _LocalFileSection({
    required this.isUpdating,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TouchTargets.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '从本地文件导入',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '支持导入符合规范格式的JSON题库文件',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : onImport,
                icon: isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(isUpdating ? '导入中...' : '选择文件'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error Card
class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorCard({
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
