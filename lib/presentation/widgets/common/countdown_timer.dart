import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_config.dart';

/// Countdown Timer Widget
/// Displays countdown for exam time limit
class CountdownTimer extends ConsumerStatefulWidget {
  final Duration duration;
  final Duration? initialRemaining;
  final VoidCallback? onTimeUp;
  final bool showLabel;
  final bool isWarningThreshold;
  final Color? color;
  final bool showIcon;

  const CountdownTimer({
    super.key,
    required this.duration,
    this.initialRemaining,
    this.onTimeUp,
    this.showLabel = true,
    this.isWarningThreshold = true,
    this.color,
    this.showIcon = true,
  });

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialRemaining ?? widget.duration;
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      setState(() {
        _remaining = widget.duration;
        _restartTimer();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          _timer?.cancel();
          widget.onTimeUp?.call();
        }
      });
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  double get _progress {
    return _remaining.inSeconds / widget.duration.inSeconds;
  }

  bool get _isWarning {
    if (!widget.isWarningThreshold) return false;
    return _progress <= AppConfig.timerWarningThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final timerColor = _isWarning
        ? AppColors.error
        : (widget.color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isWarning
            ? AppColors.error.withValues(alpha: isDark ? 0.15 : 0.1)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              _isWarning ? Icons.warning_amber_rounded : Icons.access_time_rounded,
              color: timerColor,
              size: 18,
            ),
            const SizedBox(width: 6),
          ],
          if (widget.showLabel) ...[
            Text(
              '剩余',
              style: AppTypography.labelSmall.copyWith(
                color: timerColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formattedTime,
            style: AppTypography.labelMedium.copyWith(
              color: timerColor,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer Control Widget
/// Provides pause/resume/reset controls for countdown
class TimerControl extends StatelessWidget {
  final bool isPaused;
  final VoidCallback? onPauseResume;
  final VoidCallback? onReset;
  final VoidCallback? onAddTime;

  const TimerControl({
    super.key,
    this.isPaused = false,
    this.onPauseResume,
    this.onReset,
    this.onAddTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause/Resume button
        IconButton.filled(
          onPressed: onPauseResume,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        // Reset button
        IconButton.outlined(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        // Add time button (optional)
        if (onAddTime != null) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: onAddTime,
            icon: const Icon(Icons.add_circle_outline),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Elapsed Time Widget
/// Shows time elapsed since a start point
class ElapsedTime extends StatefulWidget {
  final DateTime startTime;
  final bool showLabel;
  final bool showIcon;

  const ElapsedTime({
    super.key,
    required this.startTime,
    this.showLabel = false,
    this.showIcon = false,
  });

  @override
  State<ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<ElapsedTime> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon)
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        if (widget.showIcon && widget.showLabel) const SizedBox(width: 4),
        if (widget.showLabel)
          Text(
            '用时：',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        Text(
          _formattedTime,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
