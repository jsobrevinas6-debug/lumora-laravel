import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'google_account_picker_sheet.dart';
import 'google_icon.dart';

class AuthModal {
  static Future<void> show(
    BuildContext context, {
    String actionName = 'continue',
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AuthModalContent(actionName: actionName),
    );
  }
}

class _AuthModalContent extends StatefulWidget {
  final String actionName;

  const _AuthModalContent({required this.actionName});

  @override
  State<_AuthModalContent> createState() => _AuthModalContentState();
}

class _AuthModalContentState extends State<_AuthModalContent> {
  bool _isGoogleLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final success = await GoogleAccountPickerSheet.signInWithGoogle(context);
      if (mounted && success) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header with Drag Handle & Back/Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 32),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticService.lightImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Center(
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.plum, AppColors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign In Required',
            style: AppTextStyles.heading(
              size: 22,
              weight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are currently browsing as a Guest. Please log in or sign up to ${widget.actionName}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              size: 13.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Log In',
                    style: AppTextStyles.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.plum, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.body(
                      size: 13.5,
                      weight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with', style: AppTextStyles.body(size: 12, color: AppColors.muted)),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 14),
          // Continue with Google Button at Bottom
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.line, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.plum, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GoogleIcon(size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Continue Browsing as Guest',
              style: AppTextStyles.body(
                size: 12.5,
                color: AppColors.muted,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
