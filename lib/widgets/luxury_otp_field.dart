import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// Editorial 6-digit luxury OTP PIN input widget.
/// Features smooth focus cells, auto-advance, clipboard paste support,
/// and a built-in 60-second resend countdown timer.
class LuxuryOtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final VoidCallback? onResend;
  final bool hasError;
  final String? errorMessage;
  final int resendCountdownSeconds;

  const LuxuryOtpInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.onResend,
    this.hasError = false,
    this.errorMessage,
    this.resendCountdownSeconds = 60,
  });

  @override
  State<LuxuryOtpInputField> createState() => _LuxuryOtpInputFieldState();
}

class _LuxuryOtpInputFieldState extends State<LuxuryOtpInputField>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  Timer? _resendTimer;
  late int _remainingSeconds;
  DateTime? _timerEndTime;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _timerEndTime != null && !_canResend) {
      _syncRemainingTime();
    }
  }

  void _syncRemainingTime() {
    if (_timerEndTime == null) return;
    final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _resendTimer?.cancel();
      if (mounted) {
        setState(() {
          _remainingSeconds = 0;
          _canResend = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _remainingSeconds = remaining;
          _canResend = false;
        });
      }
    }
  }

  void _startTimer() {
    _canResend = false;
    _remainingSeconds = widget.resendCountdownSeconds;
    _timerEndTime = DateTime.now().add(Duration(seconds: widget.resendCountdownSeconds));
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _syncRemainingTime();
    });
  }

  void _handleTextChange() {
    final text = widget.controller.text;
    widget.onChanged?.call(text);
    if (text.length == 6) {
      HapticService.selection();
      widget.onCompleted?.call(text);
    }
    if (mounted) setState(() {});
  }

  void _triggerResend() {
    if (!_canResend) return;
    HapticService.lightImpact();
    widget.controller.clear();
    _startTimer();
    widget.onResend?.call();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _focusNode.dispose();
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hidden input with 6 visual cells
        GestureDetector(
          onTap: () {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Off-screen or transparent actual TextField
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                ),
              ),

              // 6 PIN boxes row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < currentText.length;
                  final isFocused = _focusNode.hasFocus &&
                      (index == currentText.length ||
                          (index == 5 && currentText.length == 6));
                  final char = isFilled ? currentText[index] : '';

                  Color borderColor;
                  if (widget.hasError) {
                    borderColor = AppColors.rose;
                  } else if (isFocused) {
                    borderColor = AppColors.plum;
                  } else if (isFilled) {
                    borderColor = AppColors.line.withValues(alpha: 0.9);
                  } else {
                    borderColor = AppColors.line;
                  }

                  return Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 44),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? Colors.white
                              : (isFocused ? Colors.white : const Color(0xFFFAF5F2)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: isFocused ? 1.8 : 1.2,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: AppColors.plum.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          char,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        // Optional Error message
        if (widget.hasError && widget.errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.rose),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.rose,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 14),

        // Countdown Timer & Resend Button Strip
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            if (!_canResend) ...[
              const Icon(Icons.schedule, size: 14, color: AppColors.muted),
              Text(
                'Resend code in 00:${_remainingSeconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                "Didn't receive the OTP?",
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
              GestureDetector(
                onTap: _triggerResend,
                child: Text(
                  'Resend OTP',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rose,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
