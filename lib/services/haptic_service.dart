import 'package:flutter/services.dart';

/// Centralized service for luxury tactile feedback throughout the Lumora app.
class HapticService {
  /// Subtle tick for tab switches, filter selections, and small interactions.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Gentle tap for button presses, card clicks, and navigation.
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Affirmative feedback for adding to cart or toggling favorites.
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Rich feedback for checkout completion, successful login, or major actions.
  static void success() {
    HapticFeedback.heavyImpact();
  }

  /// Noticeable vibration for input validation errors or alert states.
  static void error() {
    HapticFeedback.vibrate();
  }
}
