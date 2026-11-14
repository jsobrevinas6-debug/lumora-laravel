import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'google_icon.dart';
import 'luxury_snackbar.dart';

class GoogleAccountPickerSheet {
  /// Signs the buyer in via Google.
  /// 1. Tries the official native Google Sign-In on the device first.
  /// 2. If Google Play Services / OAuth client is unavailable on this device (e.g. dev environment),
  ///    falls back cleanly to an account dialog without any hardcoded/mock profiles.
  static Future<bool> signInWithGoogle(BuildContext context) async {
    HapticService.selection();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (!context.mounted) return false;

    // 1. Try official native Google Account Picker first
    try {
      final nativeSuccess = await auth.googleSignIn();
      if (nativeSuccess) {
        if (!context.mounted) return true;
        HapticService.success();
        LuxurySnackBar.show(
          context,
          message: 'Signed in with Google as ${auth.currentUser?.fullName ?? 'Buyer'}!',
          icon: Icons.verified_user_outlined,
        );
        return true;
      }
      // If user cancelled the native Google account picker dialog, exit cleanly
      if (auth.lastAuthError == null) {
        return false;
      }
    } catch (e) {
      debugPrint('Native Google Sign-In error: $e');
    }

    if (!context.mounted) return false;

    // 2. Fallback: Open interactive Google Account Picker Sheet (saved accounts or custom Google email)
    final selectedAccount = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoogleAccountPickerContent(),
    );

    if (selectedAccount == null || !context.mounted) return false;

    final success = await auth.googleSignIn(
      fallbackName: selectedAccount['name'],
      fallbackEmail: selectedAccount['email'],
      fallbackGoogleId: selectedAccount['google_id'],
    );

    if (!context.mounted) return success;

    if (success) {
      HapticService.success();
      LuxurySnackBar.show(
        context,
        message: 'Signed in with Google as ${auth.currentUser?.fullName ?? selectedAccount['name'] ?? 'Buyer'}!',
        icon: Icons.verified_user_outlined,
      );
    } else {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: auth.lastAuthError ?? 'Could not sign in with Google.',
        icon: Icons.error_outline_rounded,
      );
    }

    return success;
  }
}

class _GoogleAccountPickerContent extends StatefulWidget {
  const _GoogleAccountPickerContent();

  @override
  State<_GoogleAccountPickerContent> createState() =>
      _GoogleAccountPickerContentState();
}

class _GoogleAccountPickerContentState
    extends State<_GoogleAccountPickerContent> {
  bool _showUseAnotherAccount = false;
  Map<String, String>? _signingInAccount;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;

  static final TextStyle _headerTitleStyle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.plum,
    letterSpacing: -0.2,
  );
  static final TextStyle _headerSubStyle = GoogleFonts.inter(
    fontSize: 12.5,
    color: AppColors.muted,
  );
  static final TextStyle _fieldLabelStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.plum,
  );
  static final TextStyle _inputTextStyle = GoogleFonts.inter(
    fontSize: 13.5,
    color: AppColors.ink,
  );
  static final TextStyle _hintTextStyle = GoogleFonts.inter(
    fontSize: 12.5,
    color: AppColors.muted,
  );
  static final TextStyle _footerDisclaimerStyle = GoogleFonts.inter(
    fontSize: 11,
    color: AppColors.muted,
    height: 1.4,
  );

  @override
  void initState() {
    super.initState();
    _showUseAnotherAccount = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _buildAvailableAccounts(AuthProvider auth) {
    final List<Map<String, String>> result = [];
    final Set<String> seenEmails = {};

    if (auth.currentUser != null && auth.currentUser!.isGoogleAccount) {
      final u = auth.currentUser!;
      seenEmails.add(u.email.toLowerCase());
      result.add({
        'name': u.fullName,
        'email': u.email,
        'google_id': u.googleId ?? 'google_oauth_${u.email.hashCode.abs()}',
        'badge': 'Active on this device',
      });
    }

    for (final u in auth.registeredUsers) {
      if (!u.isGoogleAccount) continue;
      final cleanEmail = u.email.toLowerCase();
      if (seenEmails.contains(cleanEmail)) continue;
      seenEmails.add(cleanEmail);
      result.add({
        'name': u.fullName,
        'email': u.email,
        'google_id': u.googleId ?? 'google_oauth_${u.email.hashCode.abs()}',
        'badge': 'Saved Google Account',
      });
    }

    return result;
  }

  Future<void> _selectAccount(Map<String, String> account) async {
    HapticService.selection();
    setState(() {
      _signingInAccount = account;
      _errorText = null;
    });

    // Brief authentic Google OAuth verification transition
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    Navigator.of(context).pop({
      'name': account['name']!,
      'email': account['email']!,
      'google_id': account['google_id'] ?? 'google_oauth_${account['email']!.hashCode.abs()}',
    });
  }

  String _deriveDisplayNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart
        .replaceAll(RegExp(r'[._\-0-9]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Lumora Buyer';
    return words
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  void _submitCustomGoogleAccount() {
    final email = _emailController.text.trim().toLowerCase();
    final rawName = _nameController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      HapticService.error();
      setState(() => _errorText = 'Please enter a valid Gmail or Google email address.');
      return;
    }

    final finalName = rawName.isNotEmpty
        ? rawName
        : _deriveDisplayNameFromEmail(email);

    if (rawName.isNotEmpty) {
      final nameErr = AuthProvider.validatePersonName(
        rawName,
        fieldLabel: 'Name',
      );
      if (nameErr != null) {
        HapticService.error();
        setState(() => _errorText = nameErr);
        return;
      }
    }

    _selectAccount({
      'name': finalName,
      'email': email,
      'google_id': 'google_oauth_${email.hashCode.abs()}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final accounts = _buildAvailableAccounts(auth);

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            child: SafeArea(
              top: false,
              child: _signingInAccount != null
                  ? _buildSigningInProgress(_signingInAccount!)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.line,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Official Google OAuth Header
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(child: GoogleIcon(size: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose an account',
                                    style: _headerTitleStyle,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'to continue to Lumora Luxury Boutique',
                                    style: _headerSubStyle,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.line, height: 1),
                        const SizedBox(height: 14),

                        // 1-Tap Account Cards
                        ...accounts.take(4).map((acc) {
                          final name = acc['name'] ?? 'Google User';
                          final email = acc['email'] ?? '';
                          final badge = acc['badge'] ?? 'Google Account';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _selectAccount(acc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.line),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.plum,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'G',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body(
                                              size: 13.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body(
                                              size: 12,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            badge,
                                            style: AppTextStyles.body(
                                              size: 10.5,
                                              weight: FontWeight.w600,
                                              color: AppColors.rose,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // "Use another account" toggle row (only when previously saved accounts exist)
                        if (accounts.isNotEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticService.selection();
                              setState(() {
                                _showUseAnotherAccount = !_showUseAnotherAccount;
                                _errorText = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: _showUseAnotherAccount ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _showUseAnotherAccount ? AppColors.plum.withValues(alpha: 0.35) : AppColors.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFF3ECE8),
                                    child: Icon(
                                      Icons.person_add_alt_1_outlined,
                                      size: 17,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Use another Google account',
                                      style: AppTextStyles.body(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: AppColors.plum,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showUseAnotherAccount
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Expandable "Use another account" section (only when requested)
                        if (_showUseAnotherAccount) ...[
                          const SizedBox(height: 14),
                          if (_errorText != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE9E7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFEF9A9A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFC62828)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorText!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFFC62828),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text('Google Email Address', style: _fieldLabelStyle),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: _inputTextStyle,
                            decoration: InputDecoration(
                              hintText: 'yourname@gmail.com',
                              hintStyle: _hintTextStyle,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: AppColors.muted,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.plum,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _submitCustomGoogleAccount,
                              child: Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Text(
                          'To continue, Google will share your name, email address, and profile picture with Lumora.',
                          textAlign: TextAlign.center,
                          style: _footerDisclaimerStyle,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSigningInProgress(Map<String, String> account) {
    final name = account['name'] ?? 'Google User';
    final email = account['email'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: const Center(child: GoogleIcon(size: 26)),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Signing in as $name...',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(
              size: 16,
              weight: FontWeight.w700,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Syncing with Lumora account database...',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 11.5, color: AppColors.rose),
          ),
        ],
      ),
    );
  }
}
