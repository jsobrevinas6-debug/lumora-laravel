import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

/// Top-floating Dynamic Island capsule toast delivering an ultra-premium editorial notification.
/// Floats gracefully beneath the status bar so it never occludes bottom navigation or checkout bars.
class LuxurySnackBar {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_outline_rounded,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    HapticService.lightImpact();

    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

    late OverlayEntry entry;
    final GlobalKey<_LuxuryCapsuleToastState> toastKey = GlobalKey<_LuxuryCapsuleToastState>();

    entry = OverlayEntry(
      builder: (ctx) => _LuxuryCapsuleToast(
        key: toastKey,
        message: message,
        icon: icon,
        iconColor: iconColor,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          _removeEntry();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      toastKey.currentState?.dismiss();
    });
  }

  static void _removeEntry() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _LuxuryCapsuleToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _LuxuryCapsuleToast({
    super.key,
    required this.message,
    required this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_LuxuryCapsuleToast> createState() => _LuxuryCapsuleToastState();
}

class _LuxuryCapsuleToastState extends State<_LuxuryCapsuleToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _animCtrl.forward();
  }

  void dismiss() {
    if (_isDismissing || !mounted) return;
    _isDismissing = true;
    _animCtrl.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -3) {
                    HapticService.selection();
                    dismiss();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.plum.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.flowGold.withValues(alpha: 0.38),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.plum.withValues(alpha: 0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing Icon Capsule
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (widget.iconColor ?? AppColors.flowGold).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                widget.icon,
                                size: 17,
                                color: widget.iconColor ?? AppColors.flowGold,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Toast Message Text
                            Flexible(
                              child: Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ),

                            // Optional Action Button
                            if (widget.actionLabel != null && widget.onAction != null) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  dismiss();
                                  widget.onAction!();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.rose,
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.rose.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
