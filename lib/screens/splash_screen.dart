import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _rippleController;

  // Staggered letter animations
  late final List<Animation<double>> _letterFades;
  late final List<Animation<Offset>> _letterSlides;

  late final Animation<double> _monogramScale;
  late final Animation<double> _monogramFade;
  late final Animation<double> _letterSpacing;
  late final Animation<double> _taglineFade;
  late final Animation<double> _hairlineWidth;
  late final Animation<double> _progress;

  Timer? _navTimer;
  bool _precached = false;

  final List<String> _letters = ['L', 'U', 'M', 'O', 'R', 'A'];

  @override
  void initState() {
    super.initState();

    // Main entrance & timeline controller (1800ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Continuous concentric silk water ripple controller
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Monogram entrance (smooth scale pop + soft fade)
    _monogramScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.38, curve: Curves.easeOutBack),
      ),
    );

    _monogramFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
      ),
    );

    // Staggered Letter-by-Letter Reveal Animations
    _letterFades = [];
    _letterSlides = [];
    for (int i = 0; i < _letters.length; i++) {
      final start = 0.12 + (i * 0.05);
      final end = (start + 0.22).clamp(0.0, 1.0);

      _letterFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _letterSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    // Dynamic tracking expansion (Zalora runway title card effect)
    _letterSpacing = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutQuart),
      ),
    );

    // Tagline fade
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.42, 0.78, curve: Curves.easeOut),
      ),
    );

    // Expanding luxury hairline dividers
    _hairlineWidth = Tween<double>(begin: 0.0, end: 36.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    // Progress bar fill (0% -> 100%)
    _progress = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _mainController.forward();

    // Direct transition to Main Marketplace
    _navTimer = Timer(const Duration(milliseconds: 1950), _navigateToHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Pre-cache all marketplace catalog & banner assets during the splash animation
      final assetList = [
        'assets/images/hero/hero-1.jpg',
        'assets/images/hero/hero-2.jpg',
        'assets/images/hero/hero-3.jpg',
        'assets/images/hero/hero-4.jpg',
        'assets/images/flow-menu-womans-apparel.jpg',
        'assets/images/flow-menu-mens-apparel.jpg',
        'assets/images/skincare.jpg',
        'assets/images/makeup.jpg',
        'assets/images/lumora-laptop.jpg',
      ];
      for (final asset in assetList) {
        precacheImage(AssetImage(asset), context).catchError((_) {});
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: const MainScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _rippleController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  String _getCurationPhase(double progress) {
    if (progress < 0.38) {
      return 'Curating seasonal collections...';
    } else if (progress < 0.78) {
      return 'Authenticating luxury ateliers...';
    } else {
      return 'Welcome to Lumora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blush1,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _rippleController]),
            builder: (context, child) {
              final progressVal = _progress.value.clamp(0.05, 1.0);
              final rippleVal = _rippleController.value;
              final percentInt = (progressVal * 100).toInt();
              final curationPhase = _getCurationPhase(progressVal);

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 48),

                  // Center Monogram & Staggered Runway Typography
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Water Drop Monogram with Concentric Silk Ripples
                      FadeTransition(
                        opacity: _monogramFade,
                        child: ScaleTransition(
                          scale: _monogramScale,
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Concentric Ripple 1 (Expanding Outer Wave)
                                Container(
                                  width: 58 + (rippleVal * 46),
                                  height: 58 + (rippleVal * 46),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.rose.withValues(
                                        alpha: (1.0 - rippleVal) * 0.35,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                // Concentric Ripple 2 (Delayed Secondary Wave)
                                Container(
                                  width: 58 + (((rippleVal + 0.5) % 1.0) * 46),
                                  height: 58 + (((rippleVal + 0.5) % 1.0) * 46),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.rose.withValues(
                                        alpha: (1.0 - ((rippleVal + 0.5) % 1.0)) * 0.25,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                // Core Monogram Badge
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.rose.withValues(alpha: 0.3),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.rose.withValues(alpha: 0.22),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.water_drop_rounded,
                                      size: 28,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Staggered Letter-by-Letter Reveal (L · U · M · O · R · A)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_letters.length, (index) {
                          final char = _letters[index];
                          final isO = char == 'O';

                          return FadeTransition(
                            opacity: _letterFades[index],
                            child: SlideTransition(
                              position: _letterSlides[index],
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _letterSpacing.value / 2,
                                ),
                                child: Text(
                                  char,
                                  style: AppTextStyles.heading(
                                    size: 30,
                                    weight: FontWeight.w700,
                                    color: isO ? AppColors.rose : AppColors.plum,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      // Expanding Luxury Hairlines & Tagline
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: _hairlineWidth.value,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.rose.withValues(alpha: 0.0),
                                    AppColors.rose.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'CURATED LUXURY & LIFESTYLE',
                                style: AppTextStyles.body(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: AppColors.rose,
                                  letterSpacing: 3.5,
                                ),
                              ),
                            ),
                            Container(
                              width: _hairlineWidth.value,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.rose.withValues(alpha: 0.55),
                                    AppColors.rose.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Dynamic Curation Phase & Comet Shimmer Progress Capsule
                  Padding(
                    padding: const EdgeInsets.only(bottom: 46),
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Luxury Progress Capsule with Shimmer Head
                          Container(
                            width: 195,
                            height: 5.5,
                            decoration: BoxDecoration(
                              color: AppColors.line,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.plum.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: progressVal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.rose, AppColors.orange],
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.rose.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Glowing Comet Head at Leading Edge
                                Positioned(
                                  left: (195 * progressVal) - 4,
                                  top: -1.2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.rose.withValues(alpha: 0.8),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Dynamic Curation Phase & Live Percentage Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  curationPhase,
                                  key: ValueKey<String>(curationPhase),
                                  style: AppTextStyles.body(
                                    size: 11.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.plum.withValues(alpha: 0.85),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.rose.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '$percentInt%',
                                  style: AppTextStyles.body(
                                    size: 10,
                                    weight: FontWeight.w800,
                                    color: AppColors.rose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
