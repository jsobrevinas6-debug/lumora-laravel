import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/address_service.dart';
import '../services/haptic_service.dart';
import '../services/native_photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/google_account_picker_sheet.dart';
import '../widgets/google_icon.dart';
import '../widgets/luxury_otp_field.dart';
import '../widgets/luxury_snackbar.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  // Address
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();

  // Account Security
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State values
  String _selectedSex = 'female';

  // Dynamic PSGC Address state
  List<AddressItem> _provinces = [];
  List<AddressItem> _municipalities = [];
  List<AddressItem> _barangays = [];

  AddressItem? _selectedProvinceItem;
  AddressItem? _selectedMunicipalityItem;
  AddressItem? _selectedBarangayItem;

  bool _isLoadingProvinces = true;
  bool _isLoadingMunicipalities = false;
  bool _isLoadingBarangays = false;

  DateTime? _selectedDob;
  int? _computedAge;

  bool _isEmailVerified = false;
  String _verifiedEmail = '';
  bool _showCodeInput = false;
  String _generatedCode = '';
  bool _otpHasError = false;
  String? _otpErrorMessage;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  // Identity Verification (Valid ID)
  static const int _maxValidIdBytes = 5 * 1024 * 1024; // 5 MB max upload size (matches backend max:5120)
  static const List<String> _validIdTypes = [
    'PhilSys National ID',
    'Passport',
    'Driver\'s License',
    'UMID / SSS ID',
    'Postal ID',
    'Voter\'s ID',
    'PRC ID',
    'School / Student ID',
  ];
  String _selectedValidIdType = 'PhilSys National ID';
  String? _validIdPhotoDataUri;
  String? _validIdFileSizeLabel;
  String? _validIdErrorText;
  bool _isUploadingValidId = false;
  bool _validIdHasError = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
    _loadProvinces();
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  void _onEmailChanged() {
    if (_isEmailVerified &&
        _emailController.text.trim().toLowerCase() != _verifiedEmail.toLowerCase()) {
      setState(() {
        _isEmailVerified = false;
      });
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    final list = await AddressService().getProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = list;
      _isLoadingProvinces = false;
      _selectedProvinceItem = null;
      _municipalities = [];
      _selectedMunicipalityItem = null;
      _barangays = [];
      _selectedBarangayItem = null;
      _barangayController.clear();
    });
  }

  Future<void> _loadMunicipalities(String provinceCode) async {
    setState(() {
      _isLoadingMunicipalities = true;
      _municipalities = [];
      _barangays = [];
      _selectedMunicipalityItem = null;
      _selectedBarangayItem = null;
      _barangayController.clear();
    });

    final list = await AddressService().getMunicipalities(provinceCode);
    if (!mounted) return;
    setState(() {
      _municipalities = list;
      _isLoadingMunicipalities = false;
      _selectedMunicipalityItem = null;
    });
  }

  Future<void> _loadBarangays(String municipalityCode) async {
    setState(() {
      _isLoadingBarangays = true;
      _barangays = [];
      _selectedBarangayItem = null;
      _barangayController.clear();
    });

    final list = await AddressService().getBarangays(municipalityCode);
    if (!mounted) return;
    setState(() {
      _barangays = list;
      _isLoadingBarangays = false;
      _selectedBarangayItem = null;
      _barangayController.clear();
    });
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
    _barangayController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Please enter a valid email address first.',
        icon: Icons.mail_outline_rounded,
      );
      return;
    }

    HapticService.selection();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.sendEmailVerificationCode(email);
    if (!mounted) return;

    if (result['success'] == true) {
      _generatedCode = (result['code'] ?? '').toString();
      setState(() {
        _isEmailVerified = false;
        _showCodeInput = true;
        _otpHasError = false;
        _otpErrorMessage = null;
        _verificationCodeController.clear();
      });
      LuxurySnackBar.show(
        context,
        message: result['isLive'] == true
            ? 'Verification code sent to $email! Please check your Gmail inbox (and Spam folder).'
            : 'Verification code sent to $email! (OTP: $_generatedCode • valid for 10 mins)',
        icon: Icons.mark_email_read_outlined,
        iconColor: AppColors.flowGold,
      );
    } else {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: (result['message'] ?? 'Could not send verification code.').toString(),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _confirmVerificationCode() async {
    final email = _emailController.text.trim();
    final inputCode = _verificationCodeController.text.trim();

    if (inputCode.length != 6) {
      HapticService.error();
      setState(() {
        _otpHasError = true;
        _otpErrorMessage = 'Please enter all 6 digits of the OTP.';
      });
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyEmailCode(email, inputCode);
    if (!mounted) return;

    if (result['success'] == true) {
      HapticService.success();
      setState(() {
        _isEmailVerified = true;
        _verifiedEmail = email;
        _showCodeInput = false;
        _otpHasError = false;
        _otpErrorMessage = null;
      });
      LuxurySnackBar.show(
        context,
        message: 'Email verified successfully.',
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF5C7355),
      );
    } else {
      HapticService.error();
      setState(() {
        _otpHasError = true;
        _otpErrorMessage = (result['message'] ?? 'Incorrect code.').toString();
      });
      LuxurySnackBar.show(
        context,
        message: (result['message'] ?? 'Incorrect code.').toString(),
        icon: Icons.error_outline_rounded,
      );
    }
  }

  void _pickDateOfBirth() async {
    HapticService.selection();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now.subtract(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.plum,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        int age = now.year - picked.year;
        if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _computedAge = age;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      final firstError = AuthProvider.validatePersonName(_lastNameController.text, fieldLabel: 'Last name') ??
          AuthProvider.validatePersonName(_firstNameController.text, fieldLabel: 'First name') ??
          AuthProvider.validatePersonName(_middleInitialController.text, fieldLabel: 'M.I.', requiredField: false) ??
          AuthProvider.validatePhoneNumber(_phoneController.text) ??
          (_emailController.text.trim().isEmpty
              ? 'Email is required.'
              : (!_emailController.text.contains('@') || !_emailController.text.contains('.')
                  ? 'Please enter a valid email address.'
                  : null)) ??
          (_selectedProvinceItem == null ? 'Please select your province.' : null) ??
          (_selectedMunicipalityItem == null ? 'Please select your municipality.' : null) ??
          ((_selectedBarangayItem == null && _barangayController.text.trim().isEmpty) ? 'Please select your barangay.' : null) ??
          AuthProvider.validatePassword(_passwordController.text) ??
          (_confirmPasswordController.text.isEmpty
              ? 'Please confirm your password.'
              : (_confirmPasswordController.text != _passwordController.text
                  ? 'Passwords do not match.'
                  : null));

      LuxurySnackBar.show(
        context,
        message: firstError ?? 'Please check the highlighted fields above and fix any errors.',
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (_selectedProvinceItem == null ||
        _selectedMunicipalityItem == null ||
        (_selectedBarangayItem == null && _barangayController.text.trim().isEmpty)) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Please select your province, municipality, and barangay.',
        icon: Icons.location_on_outlined,
      );
      return;
    }

    if (_selectedDob == null) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Please tap and select your birthdate.',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (_computedAge == null || _computedAge! < 18) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'You must be at least 18 years old to create a buyer account.',
        icon: Icons.block_rounded,
      );
      return;
    }

    if (_validIdPhotoDataUri == null || _validIdPhotoDataUri!.isEmpty) {
      HapticService.error();
      setState(() => _validIdHasError = true);
      LuxurySnackBar.show(
        context,
        message: 'Please insert/upload a photo of your Valid ID for identity verification.',
        icon: Icons.badge_outlined,
      );
      return;
    }

    if (!_agreeToTerms) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'You must accept the Terms of Service and Privacy Policy to register.',
        icon: Icons.gavel_rounded,
      );
      return;
    }

    final email = _emailController.text.trim();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!_isEmailVerified || !auth.isEmailVerifiedForSignup(email)) {
      HapticService.error();
      LuxurySnackBar.show(
        context,
        message: 'Please verify your email before signing up.',
        icon: Icons.mark_email_unread_outlined,
      );
      return;
    }

    HapticService.selection();
    setState(() => _isLoading = true);

    final mi = _middleInitialController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = mi.isNotEmpty ? '$firstName $mi. $lastName' : '$firstName $lastName';
    final password = _passwordController.text;

    try {
      final success = await auth.signup(
        fullName,
        email,
        password,
        firstName: firstName,
        lastName: lastName,
        middleInitial: mi,
        sex: _selectedSex,
        contactNumber: AuthProvider.normalizePhoneNumber(_phoneController.text.trim()),
        dateOfBirth: _selectedDob?.toIso8601String().split('T').first,
        age: _computedAge,
        province: _selectedProvinceItem!.name,
        municipality: _selectedMunicipalityItem!.name,
        barangay: _selectedBarangayItem?.name ?? _barangayController.text.trim(),
        street: _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
        houseNumber: _houseNumberController.text.trim().isNotEmpty ? _houseNumberController.text.trim() : null,
        validIdType: _selectedValidIdType,
        validIdPhoto: _validIdPhotoDataUri,
      );

      if (!mounted) return;

      if (success) {
        HapticService.success();
        final isPending = auth.currentUser?.status == 'pending' || !auth.isLoggedIn;
        if (isPending) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: AppColors.rose, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Approval Pending',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.plum,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Your account has been registered into the database and submitted for review.\n\nAn administrator will review and verify your valid ID and details. Once approved, you will be able to log in to both the mobile app and website.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.ink,
                  height: 1.45,
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        } else {
          LuxurySnackBar.show(
            context,
            message: 'Account created! Welcome to Lumora, $fullName.',
            icon: Icons.check_circle_outline_rounded,
          );
          Navigator.of(context).pop(true);
        }
      } else {
        HapticService.error();
        LuxurySnackBar.show(
          context,
          message: auth.lastAuthError ?? 'Could not create account. Please check your details.',
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (_) {
      if (mounted) {
        HapticService.error();
        LuxurySnackBar.show(
          context,
          message: 'An unexpected error occurred. Please try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _hasUnsavedChanges {
    return _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _middleInitialController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _selectedDob != null ||
        _validIdPhotoDataUri != null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 100 ? 1 : 0)} KB';
    final mb = kb / 1024.0;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _pickValidIdPhoto({required bool fromCamera}) async {
    if (_isUploadingValidId) return;
    HapticService.selection();
    setState(() => _isUploadingValidId = true);
    try {
      final dataUri = await pickNativeImage(fromCamera: fromCamera);
      if (!mounted) return;
      if (dataUri != null && dataUri.isNotEmpty) {
        int byteCount = 0;
        try {
          final b64 = dataUri.contains(',') ? dataUri.split(',').last : dataUri;
          byteCount = base64Decode(b64.replaceAll(RegExp(r'\s+'), '')).length;
        } catch (_) {
          byteCount = (dataUri.length * 3) ~/ 4;
        }

        if (byteCount > _maxValidIdBytes) {
          final sizeStr = _formatFileSize(byteCount);
          HapticService.error();
          setState(() {
            _validIdHasError = true;
            _validIdErrorText =
                'Selected photo ($sizeStr) exceeds the 5 MB maximum file size requirement.';
          });
          LuxurySnackBar.show(
            context,
            message: 'Photo is too large ($sizeStr). Maximum allowed file size is 5 MB.',
            icon: Icons.error_outline_rounded,
          );
          return;
        }

        final sizeLabel = _formatFileSize(byteCount);
        HapticService.success();
        setState(() {
          _validIdPhotoDataUri = dataUri;
          _validIdFileSizeLabel = sizeLabel;
          _validIdHasError = false;
          _validIdErrorText = null;
        });
        LuxurySnackBar.show(
          context,
          message: '$_selectedValidIdType photo attached ($sizeLabel).',
          icon: Icons.verified_user_outlined,
          iconColor: const Color(0xFF5C7355),
        );
      }
    } catch (_) {
      if (mounted) {
        HapticService.error();
        LuxurySnackBar.show(
          context,
          message: 'Could not load Valid ID photo. Please try again.',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingValidId = false);
    }
  }

  void _previewValidIdFullDialog() {
    if (_validIdPhotoDataUri == null || !_validIdPhotoDataUri!.startsWith('data:image')) return;
    try {
      final base64Str = _validIdPhotoDataUri!.split(',').last;
      final bytes = base64Decode(base64Str);
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.plum, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedValidIdType,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 380),
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Discard registration?',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.plum,
          ),
        ),
        content: Text(
          'Are you sure you want to leave? Any details you have entered will be lost.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _handleBackNavigation() async {
    HapticService.lightImpact();
    final canLeave = await _confirmDiscardChanges();
    if (!canLeave || !mounted) return;
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
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmDiscardChanges();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFAF4F0),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Gradient matching Web
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideScreen ? 980 : 480,
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
        height: isWideScreen ? double.infinity : 150,
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
                    const Color(0xFF351128).withValues(alpha: 0.25),
                    const Color(0xFF351128).withValues(alpha: 0.65),
                    const Color(0xFF351128).withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isWideScreen ? 36 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isWideScreen ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  Text(
                    'L U M O R A',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isWideScreen ? 24 : 16,
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
                  if (isWideScreen) const Spacer(),
                  const SizedBox(height: 6),
                  Text(
                    'Create your account',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isWideScreen ? 36 : 22,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
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
                  const SizedBox(height: 4),
                  Text(
                    'Start shopping or selling with Lumora.',
                    style: GoogleFonts.inter(
                      fontSize: isWideScreen ? 13.5 : 11.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Title & Subtitle
            Text(
              'Create your account',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.plum,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All fields marked required must be filled in.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),

            // 1. Personal Details: Last Name, First Name, M.I.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Last Name *'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _lastNameController,
                        hint: 'Last name',
                        maxLength: 50,
                        validator: (v) => AuthProvider.validatePersonName(v, fieldLabel: 'Last name'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('First Name *'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _firstNameController,
                        hint: 'First name',
                        maxLength: 50,
                        validator: (v) => AuthProvider.validatePersonName(v, fieldLabel: 'First name'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('M.I.'),
                      const SizedBox(height: 5),
                      RepaintBoundary(
                        child: TextFormField(
                          controller: _middleInitialController,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: AppTextStyles.body(size: 13, color: AppColors.ink),
                          validator: (v) => AuthProvider.validatePersonName(
                            v,
                            fieldLabel: 'M.I.',
                            requiredField: false,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFFAF5F2),
                            hintText: 'M.I.',
                            hintStyle: AppTextStyles.body(size: 12, color: const Color(0xFFB2A4A1)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Sex Selection Cards
            _buildFieldLabel('Sex *'),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _buildSexCard(
                    value: 'female',
                    label: 'Female',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSexCard(
                    value: 'male',
                    label: 'Male',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Contact Number (Strict 11-Digit PH Mobile Number Limit)
            Row(
              children: [
                _buildFieldLabel('Contact Number *'),
                const Spacer(),
                Builder(
                  builder: (context) {
                    final digitsLen = _phoneController.text.trim().length;
                    final isValid11 = RegExp(r'^09\d{9}$').hasMatch(_phoneController.text.trim());
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isValid11
                            ? const Color(0xFF5C7355).withValues(alpha: 0.12)
                            : const Color(0xFFF3E9E6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$digitsLen/11 digits',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isValid11 ? const Color(0xFF5C7355) : AppColors.muted,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            _buildInputField(
              controller: _phoneController,
              hint: '09XX XXX XXXX (11 digits)',
              keyboardType: TextInputType.phone,
              icon: Icons.phone_outlined,
              maxLength: 11,
              inputFormatters: const [
                _PhContactNumberInputFormatter(),
              ],
              validator: (v) => AuthProvider.validatePhoneNumber(v),
            ),
            const SizedBox(height: 14),

            // 4. Date of Birth & Auto Age Row (Mobile 62% / 38%)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Date of Birth *'),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDob == null ? const Color(0xFFE8D8D0) : AppColors.plum,
                              width: _selectedDob == null ? 1 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF9C8A8F)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDob == null
                                      ? 'Tap to select'
                                      : '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: _selectedDob == null ? const Color(0xFFB2A4A1) : AppColors.ink,
                                    fontWeight: _selectedDob == null ? FontWeight.w400 : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 38,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Age'),
                      const SizedBox(height: 5),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E9E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8D8D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF9C8A8F)),
                            const SizedBox(width: 6),
                            Text(
                              _computedAge != null ? '$_computedAge yrs' : '—',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _computedAge != null ? AppColors.plum : const Color(0xFF857579),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5. Email Address with Integrated Verify Button
            _buildFieldLabel('Email address *'),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _emailController,
                    hint: 'Enter your email address',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEmailVerified ? const Color(0xFF5C7355) : Colors.white,
                      foregroundColor: _isEmailVerified ? Colors.white : AppColors.plum,
                      side: BorderSide(
                        color: _isEmailVerified ? const Color(0xFF5C7355) : const Color(0xFFE8D8D0),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      elevation: 0,
                    ),
                    onPressed: _isEmailVerified ? null : _sendVerificationCode,
                    child: Text(
                      _isEmailVerified ? '✓ Verified' : 'Verify',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            // 6-Digit Email Code Confirmation Box
            if (_showCodeInput && !_isEmailVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 18, color: AppColors.plum),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '6-Digit Email Verification OTP',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.plum,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the 6-digit code sent to ${_emailController.text.trim()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    if (_generatedCode.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          HapticService.selection();
                          _verificationCodeController.text = _generatedCode;
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                                  'OTP Code: $_generatedCode (Tap to auto-fill)',
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
                    ],
                    const SizedBox(height: 14),
                    LuxuryOtpInputField(
                      controller: _verificationCodeController,
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
                      onCompleted: (code) => _confirmVerificationCode(),
                      onResend: _sendVerificationCode,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _confirmVerificationCode,
                        child: Text(
                          'Confirm OTP',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Section Divider: Address
            _buildSectionDivider('Address'),

            // Province & Municipality (Mobile 50% / 50%)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Province *'),
                      const SizedBox(height: 5),
                      _buildAddressDropdown(
                        value: _selectedProvinceItem,
                        items: _provinces,
                        hint: 'Select province',
                        isLoading: _isLoadingProvinces,
                        validator: (val) => val == null ? 'Required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedProvinceItem = val);
                            _loadMunicipalities(val.code);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Municipality *'),
                      const SizedBox(height: 5),
                      _buildAddressDropdown(
                        value: _selectedMunicipalityItem,
                        items: _municipalities,
                        hint: _selectedProvinceItem == null ? 'Select province first' : 'Select municipality',
                        isLoading: _isLoadingMunicipalities,
                        validator: (val) => val == null ? 'Required' : null,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMunicipalityItem = val);
                            _loadBarangays(val.code);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barangay (Dynamic PSGC Dropdown matching Image 2)
            _buildFieldLabel('Barangay *'),
            const SizedBox(height: 5),
            (_selectedMunicipalityItem == null || _barangays.isNotEmpty || _isLoadingBarangays)
                ? _buildAddressDropdown(
                    value: _selectedBarangayItem,
                    items: _barangays,
                    hint: _selectedMunicipalityItem == null ? 'Select municipality first' : 'Select barangay',
                    isLoading: _isLoadingBarangays,
                    validator: (val) => val == null ? 'Barangay is required' : null,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBarangayItem = val;
                          _barangayController.text = val.name;
                        });
                      }
                    },
                  )
                : _buildInputField(
                    controller: _barangayController,
                    hint: 'Barangay (e.g. Ilaya, Poblacion)',
                    icon: Icons.location_city_outlined,
                    validator: (v) => v?.trim().isEmpty == true ? 'Barangay is required' : null,
                  ),
            const SizedBox(height: 12),

            // Street & House / Unit No. (Mobile 60% / 40%)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Street'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _streetController,
                        hint: 'Street name',
                        icon: Icons.signpost_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('House / Unit No.'),
                      const SizedBox(height: 5),
                      _buildInputField(
                        controller: _houseNumberController,
                        hint: 'Unit / No.',
                        icon: Icons.home_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Section Divider: Identity Verification (Valid ID)
            _buildSectionDivider('Valid ID Verification'),
            _buildValidIdVerificationSection(),

            // Section Divider: Account
            _buildSectionDivider('Account Security'),

            // Password
            _buildFieldLabel('Password *'),
            const SizedBox(height: 5),
            _buildInputField(
              controller: _passwordController,
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 19,
                  color: const Color(0xFF9C8A8F),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => AuthProvider.validatePassword(v),
            ),
            const SizedBox(height: 12),

            // Confirm Password
            _buildFieldLabel('Confirm Password *'),
            const SizedBox(height: 5),
            _buildInputField(
              controller: _confirmPasswordController,
              hint: 'Repeat your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 19,
                  color: const Color(0xFF9C8A8F),
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Terms of Service and Privacy Policy Checkbox
            InkWell(
              onTap: () {
                HapticService.selection();
                setState(() => _agreeToTerms = !_agreeToTerms);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: AppColors.plum,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: _agreeToTerms ? AppColors.plum : const Color(0xFFC4B4AE),
                          width: 1.5,
                        ),
                        onChanged: (val) {
                          HapticService.selection();
                          setState(() => _agreeToTerms = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.ink,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.plum,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.plum,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' *'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Primary Sign Up Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.plum, Color(0xFF4A1A45)],
                ),
                borderRadius: BorderRadius.circular(12),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitRegistration,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Sign Up',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Or Continue With Google
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE8D8D0), height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE8D8D0), height: 1)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE8D8D0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final success = await GoogleAccountPickerSheet.signInWithGoogle(context);
                  if (success && mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoogleIcon(size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Footer
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticService.selection();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Log in',
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.body(
        size: 12,
        weight: FontWeight.w600,
        color: AppColors.plum,
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: AppColors.plum,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE8D8D0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSexCard({required String value, required String label}) {
    final isSelected = _selectedSex == value;
    return InkWell(
      onTap: () {
        HapticService.selection();
        setState(() => _selectedSex = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F1ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.rose : const Color(0xFFE8D8D0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 16, color: AppColors.rose),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.plum : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isCredential = obscureText ||
        keyboardType == TextInputType.emailAddress ||
        keyboardType == TextInputType.phone ||
        keyboardType == TextInputType.visiblePassword;

    return RepaintBoundary(
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        autocorrect: !isCredential,
        enableSuggestions: !isCredential,
        style: AppTextStyles.body(size: 13, color: AppColors.ink),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFFAF5F2),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF9C8A8F)) : null,
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: AppTextStyles.body(size: 12.5, color: const Color(0xFFB2A4A1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB8451F), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB8451F), width: 1.5),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAddressDropdown({
    required AddressItem? value,
    required List<AddressItem> items,
    required String hint,
    required bool isLoading,
    required void Function(AddressItem?) onChanged,
    String? Function(AddressItem?)? validator,
  }) {
    final currentVal = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<AddressItem>(
      key: ValueKey('${hint}_${currentVal?.code ?? 'none'}_${items.length}'),
      initialValue: currentVal,
      isExpanded: true,
      validator: validator,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.plum),
            )
          : const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9C8A8F)),
      style: AppTextStyles.body(size: 12.5, color: AppColors.ink),
      hint: Text(
        isLoading ? 'Loading...' : hint,
        style: AppTextStyles.body(size: 12.5, color: const Color(0xFFB2A4A1)),
        overflow: TextOverflow.ellipsis,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFFAF5F2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8451F), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8451F), width: 1.5),
        ),
      ),
      items: items.map((it) {
        return DropdownMenuItem<AddressItem>(
          value: it,
          child: Text(it.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (isLoading || items.isEmpty) ? null : onChanged,
    );
  }

  Widget _buildValidIdVerificationSection() {
    final hasPhoto = _validIdPhotoDataUri != null && _validIdPhotoDataUri!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Valid ID Type *'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: _selectedValidIdType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9C8A8F)),
          style: AppTextStyles.body(size: 12.5, color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAF5F2),
            prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF9C8A8F)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
            ),
          ),
          items: _validIdTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedValidIdType = val);
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFieldLabel('Insert Valid ID Photo *'),
            const Spacer(),
            if (hasPhoto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C7355).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFF5C7355).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF5C7355)),
                    const SizedBox(width: 4),
                    Text(
                      'ID Photo Attached',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5C7355),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasPhoto ? const Color(0xFFFDFBF9) : const Color(0xFFFAF5F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _validIdHasError
                  ? const Color(0xFFB8451F)
                  : (hasPhoto ? const Color(0xFF5C7355) : const Color(0xFFE8D8D0)),
              width: (_validIdHasError || hasPhoto) ? 1.4 : 1,
            ),
          ),
          child: hasPhoto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _previewValidIdFullDialog,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 86,
                              height: 62,
                              color: AppColors.cream,
                              child: Builder(
                                builder: (context) {
                                  try {
                                    final base64Str = _validIdPhotoDataUri!.split(',').last;
                                    return Image.memory(
                                      base64Decode(base64Str),
                                      fit: BoxFit.cover,
                                    );
                                  } catch (_) {
                                    return const Icon(Icons.badge_outlined, color: AppColors.plum);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedValidIdType,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.plum,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap thumbnail to preview • ${_validIdFileSizeLabel ?? 'Verified'} (Max 5 MB)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ID photo',
                          onPressed: () {
                            HapticService.selection();
                            setState(() {
                              _validIdPhotoDataUri = null;
                              _validIdFileSizeLabel = null;
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB8451F),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.plum,
                              side: const BorderSide(color: Color(0xFFE8D8D0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: _isUploadingValidId ? null : () => _pickValidIdPhoto(fromCamera: false),
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: Text(
                              'Change Photo',
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.plum,
                              side: const BorderSide(color: Color(0xFFE8D8D0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: _isUploadingValidId ? null : () => _pickValidIdPhoto(fromCamera: true),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: Text(
                              'Retake Camera',
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.plum.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingValidId
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.plum),
                            )
                          : const Icon(Icons.add_a_photo_outlined, color: AppColors.plum, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a clear photo of your $_selectedValidIdType',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Accepted formats: JPG, PNG • Max file size: 5 MB (auto-optimized)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.plum,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Make sure your full name and birthdate match your registration details.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.plum,
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE8D8D0), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: _isUploadingValidId ? null : () => _pickValidIdPhoto(fromCamera: false),
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: Text(
                              'Upload Photo',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.plum,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: _isUploadingValidId ? null : () => _pickValidIdPhoto(fromCamera: true),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: Text(
                              'Take Photo',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        if (_validIdHasError) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _validIdErrorText ?? 'Valid ID photo is required for buyer verification (Max 5 MB).',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFFB8451F),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhContactNumberInputFormatter extends TextInputFormatter {
  const _PhContactNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text.trim();
    // Normalize +639... or 639... when pasted
    if (raw.startsWith('+639')) {
      raw = '09${raw.substring(4)}';
    } else if (raw.startsWith('639') && raw.length >= 12) {
      raw = '09${raw.substring(3)}';
    }
    // Keep only digits and limit strictly to 11 digits
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    final truncated = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}

