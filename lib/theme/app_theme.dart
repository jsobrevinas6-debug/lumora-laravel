import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color plum = Color(0xFF381535);
  static const Color plumLight = Color(0xFF53244F);
  static const Color terracotta = Color(0xFFC46A4A);
  static const Color orange = Color(0xFFC46A4A); // Harmonized soft terracotta
  static const Color rose = Color(0xFFB85E68); // Cashmere Rose
  static const Color roseGold = Color(0xFFC48B82);
  static const Color gold = Color(0xFFD4AF37); // Champagne Gold
  static const Color green = Color(0xFF5C8A54);
  static const Color cream = Color(0xFFFFFDFB);
  static const Color blush1 = Color(0xFFFAF4F0);
  static const Color blush2 = Color(0xFFF5E4E8);
  static const Color ink = Color(0xFF2C2426);
  static const Color muted = Color(0xFF8A7B7E);
  static const Color line = Color(0xFFEBDDD8);
  static const Color flowBg = Color(0xFFB9827C);
  static const Color flowGold = Color(0xFFF2C98E);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [blush1, blush2, blush1],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [plum, Color(0xFF5A2748)],
  );

  static const LinearGradient luxuryDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF220D22), Color(0xFF140714)],
  );
}

class AppTextStyles {
  static final Map<String, TextStyle> _headingCache = {};
  static final Map<String, TextStyle> _bodyCache = {};

  static TextStyle heading({
    double size = 24,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.plum,
    bool italic = false,
    double? height,
    double? letterSpacing,
  }) {
    final key = '$size-${weight.value}-$color-$italic-$height-$letterSpacing';
    return _headingCache.putIfAbsent(
      key,
      () => GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    final key = '$size-${weight.value}-$color-$height-$letterSpacing';
    return _bodyCache.putIfAbsent(
      key,
      () => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      ),
    );
  }

  static TextStyle price({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.plum,
  }) {
    return body(size: size, weight: weight, color: color);
  }

  static TextStyle caption({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.muted,
    double? letterSpacing,
  }) {
    return body(
      size: size,
      weight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

/// Crisp X (Twitter) style tactile press feedback (110ms fastOutSlowIn, subtle 0.98 scale)
class LuxuryTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const LuxuryTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
  });

  @override
  State<LuxuryTapScale> createState() => _LuxuryTapScaleState();
}

class _LuxuryTapScaleState extends State<LuxuryTapScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.fastOutSlowIn,
        child: widget.child,
      ),
    );
  }
}

/// Unified Theme Provider for Lumora Luxury Marketplace
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.blush1,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.plum,
        primary: AppColors.plum,
        secondary: AppColors.orange,
      ),
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
