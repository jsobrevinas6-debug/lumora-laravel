import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          // Top Brand Mark
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.water_drop_outlined,
                                size: 18,
                                color: AppColors.rose,
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'L U M ',
                                      style: AppTextStyles.heading(
                                        size: 18,
                                        weight: FontWeight.w700,
                                        color: AppColors.plum,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'O ',
                                      style: AppTextStyles.heading(
                                        size: 18,
                                        weight: FontWeight.w700,
                                        color: AppColors.rose,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'R A',
                                      style: AppTextStyles.heading(
                                        size: 18,
                                        weight: FontWeight.w700,
                                        color: AppColors.plum,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Center Editorial Hero Showcase (Floating Framed Arch)
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 220),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer Ambient Glow Ring
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: AppColors.line,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.plum.withValues(alpha: 0.08),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Hero Lifestyle Image
                                        Image.asset(
                                          'assets/images/hero/hero-1.jpg',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            decoration: const BoxDecoration(
                                              gradient: AppColors.heroGradient,
                                            ),
                                          ),
                                        ),
                                        // Soft Silk Vignette Gradient
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withValues(alpha: 0.1),
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.45),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Floating Top-Right Privilege Badge
                                  Positioned(
                                    top: 24,
                                    right: 24,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.cream.withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(color: AppColors.line),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.plum.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.verified, size: 13, color: AppColors.gold),
                                          const SizedBox(width: 5),
                                          Text(
                                            '100% AUTHENTIC',
                                            style: AppTextStyles.body(
                                              size: 9.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.plum,
                                            ).copyWith(letterSpacing: 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Floating Bottom-Left Category Badge
                                  Positioned(
                                    bottom: 24,
                                    left: 24,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.plum.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(99),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 12, color: AppColors.flowGold),
                                          const SizedBox(width: 6),
                                          Text(
                                            'BOUTIQUE CURATION',
                                            style: AppTextStyles.body(
                                              size: 9.5,
                                              weight: FontWeight.w700,
                                              color: Colors.white,
                                            ).copyWith(letterSpacing: 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Editorial Copy & Actions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Micro Sub-heading
                              Text(
                                'THE ART OF REFINED LIVING',
                                style: AppTextStyles.body(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: AppColors.rose,
                                ).copyWith(letterSpacing: 2.2),
                              ),
                              const SizedBox(height: 8),

                              // Headline
                              Text(
                                'Elevate Your\nEveryday Style',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading(
                                  size: 28,
                                  weight: FontWeight.w700,
                                  color: AppColors.plum,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Description
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Discover refined apparel, premier beauty, and modern electronics curated with guaranteed authenticity.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body(
                                    size: 13,
                                    color: AppColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Primary Get Started Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.plum,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.plum.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const MainScreen()),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: AppTextStyles.body(
                                          size: 14.5,
                                          weight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: AppColors.flowGold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Returning User Sign In
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: AppTextStyles.body(
                                      size: 13,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: AppTextStyles.body(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: AppColors.rose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
