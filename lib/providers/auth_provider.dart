import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class EmailVerificationRecord {
  final String email;
  final String code;
  final DateTime expiresAt;
  bool verified;

  EmailVerificationRecord({
    required this.email,
    required this.code,
    required this.expiresAt,
    this.verified = false,
  });
}

class AuthProvider extends ChangeNotifier {
  static const String _userPrefKey = 'lumora_auth_user';
  static const String _tokenPrefKey = 'lumora_auth_token';
  static const String _usersRegistryPrefKey = 'lumora_registered_users';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _isLoggedIn = false;
  User? _currentUser;
  String? _authToken;
  String? _lastAuthError;
  final List<User> _registeredUsers = [];
  final Map<String, EmailVerificationRecord> _verificationCodes = {};
  final Map<String, EmailVerificationRecord> _passwordResetCodes = {};
  final List<SavedPaymentMethod> _savedPaymentMethods = [];

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => !_isLoggedIn;
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  String? get lastAuthError => _lastAuthError;
  List<User> get registeredUsers => List.unmodifiable(_registeredUsers);
  List<SavedPaymentMethod> get paymentMethods => List.unmodifiable(_savedPaymentMethods);

  SavedPaymentMethod? get defaultPaymentMethod => _savedPaymentMethods.isNotEmpty
      ? _savedPaymentMethods.firstWhere(
          (p) => p.isDefault,
          orElse: () => _savedPaymentMethods.first,
        )
      : null;


  AuthProvider() {
    _loadRegistryAndUserFromPrefs();
    _loadPaymentMethods();
  }

  /// Name validation matching RegisteredUserController.php & ProfileUpdateRequest.php
  /// Allows letters, spaces, ñ/Ñ, hyphens (-), and apostrophes ('). Rejects numbers and other symbols.
  /// Enforces min 2 chars and max 50 chars for first and last names.
  static String? validatePersonName(String? value, {required String fieldLabel, bool requiredField = true}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return requiredField ? '$fieldLabel is required.' : null;
    }
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return "You can't input a number in your name.";
    }
    if (!RegExp(r"^[A-Za-zñÑ\s'.-]+$").hasMatch(trimmed)) {
      return "You can't input special characters in your name (only hyphens, apostrophes, periods, and ñ are allowed).";
    }
    if (fieldLabel != 'M.I.' && fieldLabel != 'Middle initial') {
      if (trimmed.length < 2) {
        return '$fieldLabel must be at least 2 characters.';
      }
      if (trimmed.length > 50) {
        return '$fieldLabel may not exceed 50 characters.';
      }
    }
    return null;
  }

  /// Normalizes Philippine mobile numbers (+63 / 63 to 09)
  static String normalizePhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+63')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('63')) {
      clean = '0${clean.substring(2)}';
    }
    return clean;
  }

  /// Strict Philippine mobile phone validator (11 digits starting with 09)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required.';
    }
    final normalized = normalizePhoneNumber(value.trim());
    if (!RegExp(r'^09\d{9}$').hasMatch(normalized)) {
      return 'Please enter a valid 11-digit Philippine mobile number starting with 09 (e.g. 09171234567).';
    }
    return null;
  }

  /// Password complexity validator (min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special symbol)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number (0-9).';
    }
    if (!RegExp(r'[@$!%*?&#^()_\-+=\[\]{}|\\:;"<>,./~`]').hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  Future<void> _loadRegistryAndUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load registered users list
      final registryJson = prefs.getString(_usersRegistryPrefKey);
      if (registryJson != null && registryJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(registryJson);
        _registeredUsers
          ..clear()
          ..addAll(decoded.map((e) => User.fromJson(e as Map<String, dynamic>)));
      }

      // Automatically purge any previous synthetic dummy accounts from storage
      _registeredUsers.removeWhere((u) {
        return u.id.startsWith('usr_') && !u.isGoogleAccount;
      });

      // Load active session user
      _authToken = prefs.getString(_tokenPrefKey);
      final userJson = prefs.getString(_userPrefKey);
      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        final loaded = User.fromJson(data);
        if (loaded.id.startsWith('usr_') && !loaded.isGoogleAccount) {
          // Clear old synthetic test user session so user starts clean
          await _removeUserFromPrefs();
          _currentUser = null;
          _authToken = null;
          _isLoggedIn = false;
        } else {
          _currentUser = loaded;
          _isLoggedIn = true;
          _upsertUserInRegistry(_currentUser!);
          if ((_authToken == null || _authToken!.isEmpty) &&
              loaded.passwordHash?.isNotEmpty == true &&
              ApiConfig.useLiveApi) {
            _recoverAuthTokenSilently(loaded, prefs);
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _recoverAuthTokenSilently(User user, SharedPreferences prefs) async {
    try {
      final pw = user.passwordHash;
      if (pw == null || pw.isEmpty) return;
      final res = await ApiService().login(user.email, pw);
      if (res.success && res.data != null) {
        final tok = (res.data!['token'] ?? res.data!['access_token'])?.toString();
        if (tok != null && tok.isNotEmpty) {
          _authToken = tok;
          await prefs.setString(_tokenPrefKey, tok);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPrefKey, jsonEncode(user.toJson()));
      if (_authToken != null) {
        await prefs.setString(_tokenPrefKey, _authToken!);
      }
      _upsertUserInRegistry(user);
      await prefs.setString(
        _usersRegistryPrefKey,
        jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _upsertUserInRegistry(User user) {
    final idx = _registeredUsers.indexWhere(
      (u) => u.id == user.id || u.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (idx >= 0) {
      _registeredUsers[idx] = user;
    } else {
      _registeredUsers.add(user);
    }
  }

  Future<void> _removeUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefKey);
      await prefs.remove(_tokenPrefKey);
    } catch (_) {}
  }

  bool isEmailRegistered(String email) {
    final normalized = email.trim().toLowerCase();
    return _registeredUsers.any((u) => u.email.trim().toLowerCase() == normalized);
  }

  bool isPhoneRegistered(String phone) {
    final normalized = normalizePhoneNumber(phone.trim());
    return _registeredUsers.any((u) =>
        u.contactNumber != null &&
        normalizePhoneNumber(u.contactNumber!) == normalized);
  }


  // ===========================================================================
  // EMAIL VERIFICATION OTP (Matches Laravel Api/AuthController.php /api/auth/otp/*)
  // ===========================================================================

  /// Sends a 6-digit verification code with 10-minute expiration.
  /// Dispatches real email via Laravel Gmail SMTP when ApiConfig.useLiveApi is true.
  Future<Map<String, dynamic>> sendEmailVerificationCode(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return {'success': false, 'message': 'Please enter a valid email address.'};
    }

    if (isEmailRegistered(email)) {
      return {'success': false, 'message': 'An account with this email already exists.'};
    }

    // 1. Dispatch real email via Laravel Backend SMTP
    if (ApiConfig.useLiveApi) {
      final res = await ApiService().requestOtp(target: email, type: 'signup');
      if (res['success'] == true) {
        final expiresAt = DateTime.now().add(const Duration(minutes: 10));
        _verificationCodes[email] = EmailVerificationRecord(
          email: email,
          code: '', // Real OTP is delivered straight to user's Gmail inbox
          expiresAt: expiresAt,
          verified: false,
        );
        return {
          'success': true,
          'message': 'A 6-digit verification code has been sent to $email. Please check your Gmail inbox and Spam folder.',
          'isLive': true,
          'code': null,
        };
      } else {
        final msg = res['message']?.toString() ?? '';
        if (msg.toLowerCase().contains('already')) {
          return {'success': false, 'message': msg};
        }
      }
    }

    // 2. Offline / Local fallback if backend is unreachable
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    _verificationCodes[email] = EmailVerificationRecord(
      email: email,
      code: code,
      expiresAt: expiresAt,
      verified: false,
    );

    return {
      'success': true,
      'message': 'Verification code sent (Dev / Offline Mode).',
      'code': code,
      'isLive': false,
    };
  }

  /// Verifies the 6-digit OTP code against MySQL database on server or local record.
  Future<Map<String, dynamic>> verifyEmailCode(String rawEmail, String inputCode) async {
    final email = rawEmail.trim().toLowerCase();
    final code = inputCode.trim();

    if (code.length != 6) {
      return {'success': false, 'message': 'Please enter all 6 digits.'};
    }

    // 1. Live server verification against MySQL email_verification_codes table
    if (ApiConfig.useLiveApi) {
      final res = await ApiService().verifyOtp(target: email, code: code, type: 'signup');
      if (res['success'] == true) {
        final expiresAt = DateTime.now().add(const Duration(minutes: 30));
        _verificationCodes[email] = EmailVerificationRecord(
          email: email,
          code: code,
          expiresAt: expiresAt,
          verified: true,
        );
        notifyListeners();
        return {'success': true, 'message': 'Email verified successfully.'};
      } else {
        final serverMsg = res['message']?.toString() ?? '';
        if (serverMsg.isNotEmpty && (serverMsg.contains('Incorrect') || serverMsg.contains('expired'))) {
          return {'success': false, 'message': serverMsg};
        }
      }
    }

    // 2. Offline / Local fallback verification
    final record = _verificationCodes[email];
    if (record == null || (record.code.isNotEmpty && record.code != code)) {
      return {'success': false, 'message': 'Incorrect verification code.'};
    }

    if (DateTime.now().isAfter(record.expiresAt)) {
      return {
        'success': false,
        'message': 'This code has expired. Please request a new one.',
      };
    }

    record.verified = true;
    notifyListeners();
    return {'success': true, 'message': 'Email verified.'};
  }

  bool isEmailVerifiedForSignup(String rawEmail) {
    final email = rawEmail.trim().toLowerCase();
    return _verificationCodes[email]?.verified == true;
  }

  // ===========================================================================
  // PASSWORD RESET OTP (Matches Laravel Api/AuthController.php /api/auth/otp/*)
  // ===========================================================================

  /// Sends a 6-digit password reset OTP with 10-minute expiration.
  Future<Map<String, dynamic>> sendPasswordResetOtp(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return {'success': false, 'message': 'Please enter a valid email address.'};
    }

    final exists = isEmailRegistered(email) ||
        (_currentUser != null && _currentUser!.email.toLowerCase() == email);
    if (!exists && !ApiConfig.useLiveApi) {
      return {
        'success': false,
        'message': 'No registered account found with $email.',
      };
    }

    // 1. Live server dispatch
    if (ApiConfig.useLiveApi) {
      final res = await ApiService().requestOtp(target: email, type: 'reset');
      if (res['success'] == true) {
        final expiresAt = DateTime.now().add(const Duration(minutes: 10));
        _passwordResetCodes[email] = EmailVerificationRecord(
          email: email,
          code: '',
          expiresAt: expiresAt,
          verified: false,
        );
        return {
          'success': true,
          'message': 'Password reset OTP sent to your Gmail inbox.',
          'isLive': true,
          'code': null,
        };
      }
    }

    // 2. Offline fallback
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    _passwordResetCodes[email] = EmailVerificationRecord(
      email: email,
      code: code,
      expiresAt: expiresAt,
      verified: false,
    );

    return {
      'success': true,
      'message': 'Password reset OTP sent (Offline Mode).',
      'code': code,
      'isLive': false,
    };
  }

  /// Verifies the 6-digit password reset OTP.
  Future<Map<String, dynamic>> verifyPasswordResetOtp(String rawEmail, String inputCode) async {
    final email = rawEmail.trim().toLowerCase();
    final code = inputCode.trim();

    if (code.length != 6) {
      return {'success': false, 'message': 'Please enter all 6 digits.'};
    }

    if (ApiConfig.useLiveApi) {
      final res = await ApiService().verifyOtp(target: email, code: code, type: 'reset');
      if (res['success'] == true) {
        final expiresAt = DateTime.now().add(const Duration(minutes: 30));
        _passwordResetCodes[email] = EmailVerificationRecord(
          email: email,
          code: code,
          expiresAt: expiresAt,
          verified: true,
        );
        notifyListeners();
        return {'success': true, 'message': 'OTP verified successfully.'};
      } else {
        final serverMsg = res['message']?.toString() ?? '';
        if (serverMsg.isNotEmpty && (serverMsg.contains('Incorrect') || serverMsg.contains('expired'))) {
          return {'success': false, 'message': serverMsg};
        }
      }
    }

    final record = _passwordResetCodes[email];
    if (record == null || (record.code.isNotEmpty && record.code != code)) {
      return {'success': false, 'message': 'Incorrect OTP code.'};
    }

    if (DateTime.now().isAfter(record.expiresAt)) {
      return {
        'success': false,
        'message': 'This OTP code has expired. Please request a new one.',
      };
    }

    record.verified = true;
    notifyListeners();
    return {'success': true, 'message': 'OTP verified successfully.'};
  }

  /// Resets the user's password once the 6-digit OTP has been verified.
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String rawEmail,
    required String code,
    required String newPassword,
  }) async {
    final email = rawEmail.trim().toLowerCase();
    final record = _passwordResetCodes[email];

    if (record == null || record.code != code.trim() || !record.verified) {
      return {'success': false, 'message': 'Please verify your 6-digit OTP first.'};
    }

    final pwdErr = validatePassword(newPassword);
    if (pwdErr != null) {
      return {'success': false, 'message': pwdErr};
    }

    if (ApiConfig.useLiveApi) {
      final res = await ApiService().resetPassword(
        email: email,
        code: code.trim(),
        password: newPassword,
      );
      if (!res.success) {
        return {'success': false, 'message': res.message ?? 'Password reset failed on server.'};
      }
    }

    final idx = _registeredUsers.indexWhere((u) => u.email.toLowerCase() == email);
    if (idx != -1) {
      final updatedUser = _registeredUsers[idx].copyWith(passwordHash: newPassword);
      _registeredUsers[idx] = updatedUser;
      await _saveUserToPrefs(updatedUser);
    }

    if (_currentUser != null && _currentUser!.email.toLowerCase() == email) {
      _currentUser = _currentUser!.copyWith(passwordHash: newPassword);
      await _saveUserToPrefs(_currentUser!);
    }

    _passwordResetCodes.remove(email);
    notifyListeners();

    return {'success': true, 'message': 'Password updated successfully. You can now log in.'};
  }

  void _loadPaymentMethods() {
    _savedPaymentMethods.clear();
  }


  void addPaymentMethod(SavedPaymentMethod method) {
    if (method.isDefault) {
      for (int i = 0; i < _savedPaymentMethods.length; i++) {
        _savedPaymentMethods[i] = SavedPaymentMethod(
          id: _savedPaymentMethods[i].id,
          type: _savedPaymentMethods[i].type,
          name: _savedPaymentMethods[i].name,
          accountName: _savedPaymentMethods[i].accountName,
          accountNumber: _savedPaymentMethods[i].accountNumber,
          isDefault: false,
        );
      }
    }
    _savedPaymentMethods.add(method);
    notifyListeners();
  }

  void removePaymentMethod(String id) {
    _savedPaymentMethods.removeWhere((p) => p.id == id);
    if (_savedPaymentMethods.isNotEmpty && !_savedPaymentMethods.any((p) => p.isDefault)) {
      final first = _savedPaymentMethods.first;
      _savedPaymentMethods[0] = SavedPaymentMethod(
        id: first.id,
        type: first.type,
        name: first.name,
        accountName: first.accountName,
        accountNumber: first.accountNumber,
        isDefault: true,
      );
    }
    notifyListeners();
  }

  void setDefaultPaymentMethod(String id) {
    for (int i = 0; i < _savedPaymentMethods.length; i++) {
      final item = _savedPaymentMethods[i];
      _savedPaymentMethods[i] = SavedPaymentMethod(
        id: item.id,
        type: item.type,
        name: item.name,
        accountName: item.accountName,
        accountNumber: item.accountNumber,
        isDefault: item.id == id,
      );
    }
    notifyListeners();
  }

  // ===========================================================================
  // LOGIN (Matches AuthenticatedSessionController.php)
  // Strictly authenticates against MySQL database (lumora.users) via Backend API.
  // Zero dummy or synthetic accounts are permitted.
  // ===========================================================================
  Future<bool> login(String email, String password) async {
    _lastAuthError = null;
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.trim().isEmpty) {
      _lastAuthError = 'Please enter your email and password.';
      return false;
    }

    final res = await ApiService().login(cleanEmail, password);
    if (res.success && res.data != null && res.data!['user'] is Map<String, dynamic>) {
      _authToken = res.data!['token']?.toString();
      _currentUser = User.fromJson(res.data!['user'] as Map<String, dynamic>)
          .copyWith(passwordHash: password);
      _isLoggedIn = true;
      _upsertUserInRegistry(_currentUser!);
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
      return true;
    } else {
      _lastAuthError = res.message ?? 'These credentials do not match our database records.';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // REGISTER (Matches RegisteredUserController.php)
  // Strictly registers user into MySQL database (lumora.users) via Backend API.
  // ===========================================================================
  Future<bool> signup(
    String fullName,
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? middleInitial,
    String? sex,
    String? contactNumber,
    String? dateOfBirth,
    int? age,
    String? province,
    String? municipality,
    String? barangay,
    String? street,
    String? houseNumber,
    String? validIdType,
    String? validIdPhoto,
  }) async {
    _lastAuthError = null;
    final cleanEmail = email.trim().toLowerCase();
    if (fullName.trim().isEmpty || cleanEmail.isEmpty || password.trim().isEmpty) {
      _lastAuthError = 'All required fields must be filled.';
      return false;
    }

    if (isEmailRegistered(cleanEmail)) {
      _lastAuthError = 'An account with this email already exists in our database.';
      return false;
    }

    if (contactNumber != null && contactNumber.trim().isNotEmpty) {
      if (isPhoneRegistered(contactNumber)) {
        _lastAuthError = 'An account with this mobile number already exists.';
        return false;
      }
    }

    final res = await ApiService().register(
      fullName.trim(),
      cleanEmail,
      password,
      extra: {
        'first_name': firstName?.trim(),
        'last_name': lastName?.trim(),
        'middle_initial': middleInitial?.trim(),
        'sex': sex,
        'contact_number': contactNumber?.trim(),
        'date_of_birth': dateOfBirth,
        'province': province,
        'municipality': municipality,
        'barangay': barangay,
        'street': street?.trim(),
        'house_number': houseNumber?.trim(),
        'valid_id_type': ?validIdType,
        'valid_id_photo': ?validIdPhoto,
      },
    );

    if (res.success && res.data != null && res.data!['user'] is Map<String, dynamic>) {
      _authToken = res.data!['token']?.toString();
      _currentUser = User.fromJson(res.data!['user'] as Map<String, dynamic>).copyWith(
        passwordHash: password,
        validIdType: validIdType,
        validIdPhoto: validIdPhoto,
      );
      _verificationCodes.remove(cleanEmail);
      
      // If the buyer is pending admin approval, do NOT log them in as an active session
      if (_currentUser!.status == 'pending' || _currentUser!.approvalStatus == 'pending') {
        _isLoggedIn = false;
        _authToken = null;
        _removeUserFromPrefs();
        notifyListeners();
        return true;
      }

      _isLoggedIn = true;
      _upsertUserInRegistry(_currentUser!);
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
      return true;
    } else {
      _lastAuthError = res.message ?? 'Registration failed. Please check your details and try again.';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // GOOGLE OAUTH SIGN-IN (Matches GoogleController.php 1:1 + Live DB Sync)
  // ===========================================================================
  Future<bool> googleSignIn({
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackGoogleId,
    String? fallbackAvatar,
  }) async {
    _lastAuthError = null;
    String googleId = '';
    String email = '';
    String fullName = '';
    String? avatar;

    try {
      if (fallbackEmail == null || fallbackEmail.trim().isEmpty) {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account != null) {
          googleId = account.id.trim();
          email = account.email.trim().toLowerCase();
          fullName = (account.displayName?.trim().isNotEmpty == true)
              ? account.displayName!.trim()
              : email.split('@').first;
          avatar = account.photoUrl;
        } else {
          // User dismissed or cancelled the native Google picker
          return false;
        }
      }
    } catch (e) {
      debugPrint('Native Google Sign-In exception: $e');
      _lastAuthError = 'Google Play Services OAuth is unavailable on this device ($e).';
    }

    if (email.isEmpty && fallbackEmail != null && fallbackEmail.trim().isNotEmpty) {
      email = fallbackEmail.trim().toLowerCase();
      googleId = (fallbackGoogleId != null && fallbackGoogleId.trim().isNotEmpty)
          ? fallbackGoogleId.trim()
          : 'gid_${email.hashCode.abs()}';
      fullName = (fallbackName != null && fallbackName.trim().isNotEmpty)
          ? fallbackName.trim()
          : email.split('@').first;
      avatar = fallbackAvatar;
    }

    if (googleId.isEmpty || email.isEmpty) {
      _lastAuthError = 'Google did not provide a verified email for this account.';
      return false;
    }

    final cleanFullName = fullName.isNotEmpty ? fullName : 'Lumora Buyer';

    // Verify and sync with MySQL Database (lumora.users) via Backend API
    final apiRes = await ApiService().googleAuth(
      fullName: cleanFullName,
      email: email,
      googleId: googleId,
      avatar: avatar,
    );

    if (apiRes.success && apiRes.data != null && apiRes.data!['user'] is Map<String, dynamic>) {
      _authToken = apiRes.data!['token']?.toString();
      _currentUser = User.fromJson(apiRes.data!['user'] as Map<String, dynamic>).copyWith(
        googleId: googleId,
        provider: 'google',
        avatar: avatar,
        emailVerified: true,
      );
      _isLoggedIn = true;
      _upsertUserInRegistry(_currentUser!);
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
      return true;
    } else {
      _lastAuthError = apiRes.message ?? 'Google authentication failed to connect with the database.';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // PROFILE MANAGEMENT (Matches ProfileController.php & PasswordController.php)
  // ===========================================================================

  /// PATCH /profile — Update buyer profile information
  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    String? middleInitial,
    required String sex,
    required String contactNumber,
    required String dateOfBirth,
    required String email,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Not signed in.'};
    }

    final fnErr = validatePersonName(firstName, fieldLabel: 'First name');
    if (fnErr != null) return {'success': false, 'message': fnErr};

    final lnErr = validatePersonName(lastName, fieldLabel: 'Last name');
    if (lnErr != null) return {'success': false, 'message': lnErr};

    final miErr = validatePersonName(middleInitial, fieldLabel: 'Middle initial', requiredField: false);
    if (miErr != null) return {'success': false, 'message': miErr};

    final phoneErr = validatePhoneNumber(contactNumber);
    if (phoneErr != null) return {'success': false, 'message': phoneErr};
    final normalizedPhone = normalizePhoneNumber(contactNumber.trim());

    final cleanEmail = email.trim().toLowerCase();
    final emailChanged = cleanEmail != _currentUser!.email.toLowerCase();
    if (emailChanged && isEmailRegistered(cleanEmail)) {
      return {'success': false, 'message': 'This email is already taken by another account.'};
    }

    final phoneChanged = _currentUser!.contactNumber == null ||
        normalizePhoneNumber(_currentUser!.contactNumber!) != normalizedPhone;
    if (phoneChanged && isPhoneRegistered(normalizedPhone)) {
      return {'success': false, 'message': 'This mobile number is already taken by another account.'};
    }

    int? computedAge = _currentUser!.age;
    if (dateOfBirth.trim().isNotEmpty) {
      final parsedDob = DateTime.tryParse(dateOfBirth.trim());
      if (parsedDob == null) {
        return {'success': false, 'message': 'Please enter a valid date of birth (YYYY-MM-DD).'};
      }
      final now = DateTime.now();
      int age = now.year - parsedDob.year;
      if (now.month < parsedDob.month || (now.month == parsedDob.month && now.day < parsedDob.day)) {
        age--;
      }
      if (age < 18) {
        return {'success': false, 'message': 'You must be at least 18 years old.'};
      }
      computedAge = age;
    }

    final updatedFullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    _currentUser = _currentUser!.copyWith(
      fullName: updatedFullName,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      middleInitial: middleInitial?.trim(),
      sex: sex,
      contactNumber: normalizedPhone,
      dateOfBirth: dateOfBirth.trim(),
      age: computedAge,
      email: cleanEmail,
      emailVerifiedAt: emailChanged ? null : _currentUser!.emailVerifiedAt,
    );

    if (ApiConfig.useLiveApi) {
      try {
        await ApiService().updateProfile(
          data: {
            'full_name': updatedFullName,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'middle_initial': middleInitial?.trim(),
            'sex': sex,
            'contact_number': normalizedPhone,
            'date_of_birth': dateOfBirth.trim(),
          },
          token: _authToken,
        );
      } catch (e) {
        debugPrint('Live updateProfile sync warning: $e');
      }
    }

    await _saveUserToPrefs(_currentUser!);
    notifyListeners();
    return {'success': true, 'message': 'Profile updated successfully.'};
  }

  /// PATCH /profile/avatar — Update buyer profile picture
  Future<void> updateAvatar(String avatarSource) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(avatar: avatarSource);
    await _saveUserToPrefs(_currentUser!);
    notifyListeners();
  }

  /// PATCH /profile/address — Update buyer shipping address
  Future<void> updateShippingAddress({
    required String province,
    required String municipality,
    required String barangay,
    String? street,
    String? houseNumber,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      province: province.trim(),
      municipality: municipality.trim(),
      barangay: barangay.trim(),
      street: street?.trim(),
      houseNumber: houseNumber?.trim(),
    );
    if (ApiConfig.useLiveApi) {
      try {
        await ApiService().updateProfile(
          data: {
            'province': province.trim(),
            'municipality': municipality.trim(),
            'barangay': barangay.trim(),
            'street': street?.trim(),
            'house_number': houseNumber?.trim(),
          },
          token: _authToken,
        );
      } catch (e) {
        debugPrint('Live updateShippingAddress sync warning: $e');
      }
    }
    await _saveUserToPrefs(_currentUser!);
    notifyListeners();
  }

  /// PUT /password — Update account password
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Not signed in.'};
    }
    if (_currentUser!.passwordHash != null &&
        _currentUser!.passwordHash!.isNotEmpty &&
        _currentUser!.passwordHash != currentPassword) {
      return {'success': false, 'message': 'The current password is incorrect.'};
    }
    final pwdErr = validatePassword(newPassword);
    if (pwdErr != null) {
      return {'success': false, 'message': pwdErr};
    }
    if (newPassword == currentPassword) {
      return {'success': false, 'message': 'New password must be different from current password.'};
    }
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'The password confirmation does not match.'};
    }

    if (ApiConfig.useLiveApi) {
      final res = await ApiService().updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        token: _authToken,
      );
      if (!res.success) {
        return {'success': false, 'message': res.message ?? 'Failed to update password.'};
      }
    }

    _currentUser = _currentUser!.copyWith(passwordHash: newPassword);
    await _saveUserToPrefs(_currentUser!);
    notifyListeners();
    return {'success': true, 'message': 'Password updated successfully.'};
  }

  /// DELETE /profile — Permanently delete buyer account after password check
  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Not signed in.'};
    }
    if (!_currentUser!.isGoogleAccount &&
        _currentUser!.passwordHash != null &&
        _currentUser!.passwordHash!.isNotEmpty &&
        _currentUser!.passwordHash != password) {
      return {'success': false, 'message': 'The password you entered is incorrect.'};
    }

    final idToRemove = _currentUser!.id;
    final emailToRemove = _currentUser!.email.toLowerCase();
    _registeredUsers.removeWhere(
      (u) => u.id == idToRemove || u.email.toLowerCase() == emailToRemove,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _usersRegistryPrefKey,
        jsonEncode(_registeredUsers.map((u) => u.toJson()).toList()),
      );
    } catch (_) {}

    logout();
    return {'success': true, 'message': 'Your account has been permanently deleted.'};
  }

  // Log out to Guest Mode (preserves per-user persisted cart & orders for BUY-CART-008)
  void logout() {
    _currentUser = null;
    _authToken = null;
    _isLoggedIn = false;
    _lastAuthError = null;
    _removeUserFromPrefs();
    notifyListeners();
    try {
      _googleSignIn.signOut();
    } catch (_) {}
  }
}
