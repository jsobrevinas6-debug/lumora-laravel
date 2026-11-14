import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/google_account_picker_sheet.dart';
import '../widgets/google_icon.dart';
import '../widgets/luxury_otp_field.dart';
import '../widgets/luxury_snackbar.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _rememberMePrefKey = 'lumora_remember_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_rememberMePrefKey);
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_rememberMePrefKey, email.trim());
      } else {
        await prefs.remove(_rememberMePrefKey);
      }
    } catch (_) {}
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      return;
    }

    HapticService.selection();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.login(email, password);

      if (!mounted) return;

      if (success) {
        await _saveRememberedEmail(email);
        if (!mounted) return;
        HapticService.success();
        LuxurySnackBar.show(
          context,
          message: 'Signed in successfully as ${auth.currentUser?.fullName ?? 'Buyer'}.',
          icon: Icons.check_circle_outline_rounded,
        );
        Navigator.of(context).pop(true);
      } else {
        HapticService.error();
        LuxurySnackBar.show(
          context,
          message: auth.lastAuthError ?? 'Please check your email address and password.',
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        LuxurySnackBar.show(
          context,
          message: 'An unexpected issue occurred. Please try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final success = await GoogleAccountPickerSheet.signInWithGoogle(context);
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showForgotPasswordModal() {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PasswordResetModal(
        initialEmail: _emailController.text.trim(),
        onSuccess: (email, newPassword) {
          _emailController.text = email;
          _passwordController.text = newPassword;
        },
      ),
    );
  }

  void _handleBackNavigation() {
    HapticService.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF4F0),
        body: Stack(
          children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF4F0),
                  Color(0xFFF7EFEB),
                  Color(0xFFF5E4E8),
                ],
              ),
            ),
          ),
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFECD5CD).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFECCDC1).withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 780;

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 980 : 440,
                        ),
                        child: RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDFB),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFFE8D8D0), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF351128).withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: isWideScreen
                                  ? IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            flex: 45,
                                            child: _buildArtBanner(isWideScreen: true),
                                          ),
                                          Expanded(
                                            flex: 55,
                                            child: RepaintBoundary(child: _buildFormPanel()),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildArtBanner(isWideScreen: false),
                                      RepaintBoundary(child: _buildFormPanel()),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
          ),
          // Luxury Floating Top-Left Back Button
          Positioned(
            top: 14,
            left: 16,
            child: SafeArea(
              child: Semantics(
                label: 'Back',
                button: true,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _handleBackNavigation,
                    customBorder: const CircleBorder(),
                    splashColor: AppColors.plum.withValues(alpha: 0.15),
                    highlightColor: AppColors.plum.withValues(alpha: 0.08),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.98),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8D8D0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF351128).withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildArtBanner({required bool isWideScreen}) {
    return RepaintBoundary(
      child: SizedBox(
        height: isWideScreen ? double.infinity : 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 700,
              filterQuality: FilterQuality.low,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF351128).withValues(alpha: 0.20),
                  const Color(0xFF351128).withValues(alpha: 0.15),
                  const Color(0xFF351128).withValues(alpha: 0.55),
                  const Color(0xFF351128).withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.40, 0.75, 1.0],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isWideScreen ? 36 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'L U M O R A',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isWideScreen ? 24 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Timeless\nElegance',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isWideScreen ? 40 : 27,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 38,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Designed to shine. Made to be yours.',
                  style: GoogleFonts.inter(
                    fontSize: isWideScreen ? 13.5 : 12,
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Welcome back',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.plum,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFFDEC8BC)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.gold,
                            shadows: [
                              Shadow(
                                color: AppColors.gold.withValues(alpha: 0.40),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDEC8BC), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue shopping with Lumora',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Email address',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 6),
            RepaintBoundary(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5F2),
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 19,
                    color: Color(0xFF9C8A8F),
                  ),
                  hintText: 'Enter your email',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFB2A4A1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Password',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 6),
            RepaintBoundary(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _submitLogin(),
                style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFAF5F2),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 19,
                    color: Color(0xFF9C8A8F),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 19,
                      color: const Color(0xFF9C8A8F),
                    ),
                    onPressed: () {
                      HapticService.selection();
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  hintText: 'Enter your password',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFB2A4A1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                  ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }
                if (value.length < 4) {
                  return 'Password must be at least 4 characters.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    HapticService.selection();
                    setState(() => _rememberMe = !_rememberMe);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            HapticService.selection();
                            setState(() => _rememberMe = val ?? false);
                          },
                          activeColor: AppColors.plum,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Color(0xFFB2A4A1), width: 1.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _showForgotPasswordModal,
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.plum,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.plum,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.plum, Color(0xFF4A1A45)],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.plum.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: _isLoading ? null : _submitLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Sign in',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Divider(color: Color(0xFFE8D8D0), thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: Color(0xFFE8D8D0), thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE8D8D0), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: _isGoogleLoading ? null : _submitGoogleLogin,
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.plum,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleIcon(size: 19),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticService.selection();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Create account',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.plum,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.plum,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-Step Interactive 6-Digit OTP Password Recovery Modal
class _PasswordResetModal extends StatefulWidget {
  final String initialEmail;
  final void Function(String email, String newPassword) onSuccess;

  const _PasswordResetModal({
    required this.initialEmail,
    required this.onSuccess,
  });

  @override
  State<_PasswordResetModal> createState() => _PasswordResetModalState();
}

class _PasswordResetModalState extends State<_PasswordResetModal> {
  int _step = 1; // 1 = Email, 2 = 6-digit OTP, 3 = New Password
  late final TextEditingController _emailCtrl;
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;
  bool _otpHasError = false;
  String? _otpErrorMessage;
  String _generatedOtp = '';

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // STEP 1: Send OTP
  Future<void> _handleSendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Please enter a valid registered email address.',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.selection();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.sendPasswordResetOtp(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _generatedOtp = (result['code'] ?? '').toString();
      HapticService.success();
      setState(() {
        _step = 2;
        _otpHasError = false;
        _otpErrorMessage = null;
        _otpCtrl.clear();
      });
      LuxurySnackBar.show(
        context,
        message: result['isLive'] == true
            ? 'Password reset OTP sent to $email! Please check your Gmail inbox.'
            : 'Password reset OTP sent to $email! (OTP: $_generatedOtp • valid for 10 mins)',
        icon: Icons.mark_email_read_outlined,
        iconColor: AppColors.flowGold,
      );
    } else {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: (result['message'] ?? 'Could not send reset OTP.').toString(),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  // STEP 2: Verify OTP
  Future<void> _handleVerifyOtp() async {
    final email = _emailCtrl.text.trim();
    final code = _otpCtrl.text.trim();

    if (code.length != 6) {
      HapticService.error();
      setState(() {
        _otpHasError = true;
        _otpErrorMessage = 'Please enter all 6 digits of the OTP.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyPasswordResetOtp(email, code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      HapticService.success();
      setState(() {
        _step = 3;
        _otpHasError = false;
        _otpErrorMessage = null;
      });
      LuxurySnackBar.show(
        context,
        message: 'OTP verified. Please set your new password.',
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF5C7355),
      );
    } else {
      HapticService.error();
      setState(() {
        _otpHasError = true;
        _otpErrorMessage = (result['message'] ?? 'Incorrect OTP code.').toString();
      });
      LuxurySnackBar.show(
        context,
        message: (result['message'] ?? 'Incorrect OTP code.').toString(),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  // STEP 3: Reset Password
  Future<void> _handleResetPassword() async {
    final email = _emailCtrl.text.trim();
    final code = _otpCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.length < 8) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Password must be at least 8 characters long.',
        icon: Icons.lock_outline,
      );
      return;
    }

    if (newPass != confirmPass) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Passwords do not match. Please re-check.',
        icon: Icons.lock_reset,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.resetPasswordWithOtp(
      rawEmail: email,
      code: code,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      HapticService.success();
      Navigator.of(context).pop();
      widget.onSuccess(email, newPass);
      LuxurySnackBar.show(
        context,
        message: 'Password updated successfully! You can now log in.',
        icon: Icons.verified_user_outlined,
        iconColor: AppColors.flowGold,
      );
    } else {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: (result['message'] ?? 'Could not reset password.').toString(),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header Row with Step Indicator & Back Button
          Row(
            children: [
              if (_step > 1) ...[
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    setState(() => _step--);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.arrow_back, size: 16, color: AppColors.plum),
                  ),
                ),
              ] else ...[
                const Icon(Icons.lock_reset, color: AppColors.plum, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  _step == 1
                      ? 'Password Recovery'
                      : (_step == 2 ? 'Verify 6-Digit OTP' : 'Set New Password'),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.plum.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Step $_step of 3',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Step Description
          Text(
            _step == 1
                ? 'Enter your registered email address to receive a secure 6-digit verification code.'
                : (_step == 2
                    ? 'Enter the 6-digit OTP code sent to ${_emailCtrl.text.trim()}.'
                    : 'Create a new, strong password for your Lumora marketplace account.'),
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),

          // STEP 1 CONTENT: Email Input
          if (_step == 1) ...[
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 19, color: AppColors.muted),
                hintText: 'Enter your registered email address',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB2A4A1)),
                filled: true,
                fillColor: const Color(0xFFFAF5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleSendOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Send 6-Digit OTP',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],

          // STEP 2 CONTENT: 6-Digit OTP Field
          if (_step == 2) ...[
            if (_generatedOtp.isNotEmpty) ...[
              Center(
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    _otpCtrl.text = _generatedOtp;
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.plum.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.plum.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key_rounded, size: 14, color: AppColors.plum),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'OTP Code: $_generatedOtp (Tap to auto-fill)',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            LuxuryOtpInputField(
              controller: _otpCtrl,
              hasError: _otpHasError,
              errorMessage: _otpErrorMessage,
              onChanged: (code) {
                if (_otpHasError) {
                  setState(() {
                    _otpHasError = false;
                    _otpErrorMessage = null;
                  });
                }
              },
              onCompleted: (code) => _handleVerifyOtp(),
              onResend: _handleSendOtp,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleVerifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Verify OTP',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],

          // STEP 3 CONTENT: Set New Password
          if (_step == 3) ...[
            TextField(
              controller: _newPassCtrl,
              obscureText: _obscureNewPass,
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, size: 19, color: AppColors.muted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.muted,
                  ),
                  onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                ),
                hintText: 'New password (min. 8 characters)',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB2A4A1)),
                filled: true,
                fillColor: const Color(0xFFFAF5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirmPass,
              style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_reset, size: 19, color: AppColors.muted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.muted,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
                hintText: 'Confirm new password',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB2A4A1)),
                filled: true,
                fillColor: const Color(0xFFFAF5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plum,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleResetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Update Password & Log In',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
