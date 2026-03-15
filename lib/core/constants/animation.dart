import 'package:flutter/animation.dart';

/// Animation Durations
/// Following UI/UX best practices: 150-300ms for micro-interactions
class AnimationDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 250);
  static const Duration modalTransition = Duration(milliseconds: 300);

  // Stagger animations
  static const Duration stagger = Duration(milliseconds: 50);
}

/// Animation Curves
class AnimationCurves {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve sharpCurve = Curves.easeOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
