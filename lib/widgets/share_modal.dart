import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'luxury_snackbar.dart';

class LuxuryShareModal {
  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ShareModalContent(product: product),
    );
  }
}

class _ShareModalContent extends StatefulWidget {
  final Product product;
  const _ShareModalContent({required this.product});

  @override
  State<_ShareModalContent> createState() => _ShareModalContentState();
}

class _ShareModalContentState extends State<_ShareModalContent> {
  bool _copied = false;

  String get _productUrl => 'https://lumora.luxury/p/${widget.product.id}';
  String get _shareText => 'Check out this product I found: $_productUrl';

  void _copyToClipboard() async {
    HapticService.selection();
    await Clipboard.setData(ClipboardData(text: _shareText));
    setState(() => _copied = true);

    if (mounted) {
      LuxurySnackBar.show(
        context,
        message: 'Product link copied to clipboard!',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.gold,
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _handleShareApp(String appName) {
    HapticService.lightImpact();
    Clipboard.setData(ClipboardData(text: _shareText));
    Navigator.of(context).pop();
    LuxurySnackBar.show(
      context,
      message: 'Opening $appName with "${widget.product.name}"...',
      icon: Icons.share_outlined,
      iconColor: AppColors.rose,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Quick Contacts List
    final quickContacts = [
      {'name': 'My Drive', 'icon': Icons.folder_outlined, 'badge': Icons.add_to_drive, 'color': const Color(0xFF4285F4)},
      {'name': 'Cali', 'initials': 'C', 'badge': Icons.chat_bubble, 'color': const Color(0xFF673AB7)},
      {'name': 'Elena R.', 'initials': 'ER', 'badge': Icons.chat_bubble, 'color': const Color(0xFFE91E63)},
      {'name': 'Howard A.', 'initials': 'HA', 'badge': Icons.chat_bubble, 'color': const Color(0xFF009688)},
      {'name': 'Katrina V.', 'initials': 'KV', 'badge': Icons.chat_bubble, 'color': const Color(0xFFFF9800)},
      {'name': 'Marcus T.', 'initials': 'MT', 'badge': Icons.chat_bubble, 'color': const Color(0xFF3F51B5)},
    ];

    // Social Apps Grid (4 columns)
    final shareApps = [
      {'name': 'Quick Share', 'icon': Icons.sync_alt_rounded, 'color': const Color(0xFF1976D2)},
      {'name': 'Chats', 'icon': Icons.chat_bubble_rounded, 'color': const Color(0xFF0084FF)},
      {'name': 'Instagram', 'icon': Icons.camera_alt_outlined, 'color': const Color(0xFFE1306C)},
      {'name': 'WhatsApp', 'icon': Icons.call_outlined, 'color': const Color(0xFF25D366)},
      {'name': 'Drive', 'icon': Icons.add_to_drive_rounded, 'color': const Color(0xFF0F9D58)},
      {'name': 'Bluetooth', 'icon': Icons.bluetooth, 'color': const Color(0xFF4285F4)},
      {'name': 'Messaging', 'icon': Icons.message_rounded, 'color': const Color(0xFF4CAF50)},
      {'name': 'Gemini', 'icon': Icons.auto_awesome, 'color': const Color(0xFF8E24AA)},
      {'name': 'Gmail', 'icon': Icons.mail_outline_rounded, 'color': const Color(0xFFEA4335)},
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)},
      {'name': 'Telegram', 'icon': Icons.send_rounded, 'color': const Color(0xFF0088CC)},
      {'name': 'Discord', 'icon': Icons.headset_mic_rounded, 'color': const Color(0xFF5865F2)},
      {'name': 'X (Twitter)', 'icon': Icons.close_rounded, 'color': Colors.white},
      {'name': 'Copy Link', 'icon': Icons.link_rounded, 'color': AppColors.gold},
      {'name': 'Save Image', 'icon': Icons.download_rounded, 'color': const Color(0xFF78909C)},
      {'name': 'QR Code', 'icon': Icons.qr_code_2_rounded, 'color': AppColors.orange},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF1F1D20), // Dark luxury background matching Zalora reference
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header with Close Button and Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Share',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      size: 17,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 44), // Balance the close button
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Copyable Link Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2A2D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3F3C40)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _shareText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB0ADB2),
                              fontSize: 12.5,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _copyToClipboard,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _copied ? AppColors.plum : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _copied ? Icons.check : Icons.copy_rounded,
                              color: _copied ? Colors.white : const Color(0xFFD0CDD2),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Quick Direct Contacts Row
                  SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: quickContacts.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 14),
                      itemBuilder: (context, idx) {
                        final c = quickContacts[idx];
                        return GestureDetector(
                          onTap: () => _handleShareApp(c['name'] as String),
                          child: SizedBox(
                            width: 64,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: c.containsKey('icon')
                                            ? Colors.white
                                            : (c['color'] as Color).withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: c.containsKey('icon')
                                            ? Icon(c['icon'] as IconData, color: const Color(0xFF5F6368), size: 24)
                                            : Text(
                                                c['initials'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1F1D20),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          c['badge'] as IconData,
                                          size: 12,
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFDCD8DD),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFF333035), height: 1),
                  ),

                  // 3. Social Apps 4-Column Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: shareApps.length,
                    itemBuilder: (context, idx) {
                      final app = shareApps[idx];
                      return GestureDetector(
                        onTap: () => _handleShareApp(app['name'] as String),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E2C30),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF3C393E)),
                              ),
                              child: Center(
                                child: Icon(
                                  app['icon'] as IconData,
                                  color: app['color'] as Color,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE0DCE2),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
