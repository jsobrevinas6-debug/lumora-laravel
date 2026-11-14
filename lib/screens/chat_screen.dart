import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/haptic_service.dart';
import '../services/native_photo_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
import '../widgets/cards.dart';
import '../widgets/luxury_snackbar.dart';

class ChatScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? sellerName;
  final String? sellerRole;
  final Object? productContext; // Product or Map<String, String>

  const ChatScreen({
    super.key,
    this.title = 'Lumora Assistant & Support',
    this.subtitle = 'AI Assistant & Concierge • Typically replies instantly',
    this.sellerName,
    this.sellerRole,
    this.productContext,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;
  String? _activeThreadId;
  String? _attachedFileName;
  String? _attachedFileUrl;

  Map<String, String>? get _normalizedProductContext {
    final ctx = widget.productContext;
    if (ctx is Product) {
      return {
        'id': ctx.id,
        'name': ctx.name,
        'price': ctx.formattedPrice,
        'image': ctx.imagePath ?? '',
      };
    } else if (ctx is Map<String, String>) {
      return ctx;
    }
    return null;
  }

  final List<Map<String, String>> _supportBotTopics = [
    {
      'label': 'What is Lumora?',
      'answer':
          'Lumora is an online luxury beauty marketplace where independent sellers offer skincare, makeup and fragrance, and buyers can shop, chat with sellers and follow their favorite shops.',
    },
    {
      'label': 'Who is the developers of Lumora',
      'answer':
          'Lumora was created by the Lumora development team (Justin Sobreviñas, Arron Ivan Balonzo, and Ratbu Team Workspace).',
    },
    {
      'label': 'I will report a product',
      'answer':
          'Sorry about that! Please describe what is wrong, and attach a photo or file if you have one. An admin will review your report.',
      'action': 'report',
    },
    {
      'label': 'Do you support COD & GCash?',
      'answer':
          'Yes! Lumora supports Cash on Delivery (COD), GCash, Maya, and direct bank transfers at checkout.',
    },
  ];

  @override
  void initState() {
    super.initState();
    final isSellerChat = widget.sellerName != null;

    if (!isSellerChat) {
      _messages = [
        ChatMessage(
          id: 'msg-1',
          senderName: 'Lumora Assistant',
          senderRole: 'Bot',
          message:
              'Hi! I am Lumora Assistant. ✨ Tap a topic below or type your question anytime.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isFromUser: false,
          isBot: true,
        ),
      ];
    } else {
      _messages = [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final thread = chatProvider.getOrCreateThread(
          sellerName: widget.sellerName!,
          sellerRole: widget.sellerRole,
          productContext: _normalizedProductContext,
        );
        chatProvider.markThreadRead(thread.id);
        setState(() {
          _activeThreadId = thread.id;
          _messages = List<ChatMessage>.from(thread.messages);
        });
      });
    }
  }

  void _sendAttachmentPicker() {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Attach File or Photo',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select proof, receipt, or product defect photo to send to support or seller.',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF8EEE9),
                child: Icon(Icons.photo_library_outlined, color: AppColors.rose),
              ),
              title: Text('Choose Photo from Gallery / Device Storage', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
              subtitle: Text('Browse JPG or PNG from your phone storage', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final dataUri = await pickNativeImage(fromCamera: false);
                if (dataUri != null && dataUri.isNotEmpty && mounted) {
                  setState(() {
                    _attachedFileName = 'photo_attachment.jpg';
                    _attachedFileUrl = dataUri;
                  });
                  LuxurySnackBar.show(context, message: 'Photo attached from device storage');
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF8EEE9),
                child: Icon(Icons.camera_alt_outlined, color: AppColors.rose),
              ),
              title: Text('Take Photo from Camera', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5)),
              subtitle: Text('Capture photo using your device camera', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final dataUri = await pickNativeImage(fromCamera: true);
                if (dataUri != null && dataUri.isNotEmpty && mounted) {
                  setState(() {
                    _attachedFileName = 'camera_photo.jpg';
                    _attachedFileUrl = dataUri;
                  });
                  LuxurySnackBar.show(context, message: 'Camera photo attached');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text, {String? attachmentName, String? attachmentUrl}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty && attachmentName == null) return;
    if (cleanText.length > 1000) {
      LuxurySnackBar.show(
        context,
        message: 'Message cannot exceed 1,000 characters.',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      AuthModal.show(context, actionName: 'send messages');
      return;
    }

    HapticService.selection();

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderName: auth.currentUser?.fullName ?? 'You',
      senderRole: 'Buyer',
      message: cleanText.isNotEmpty ? cleanText : 'Attached file: $attachmentName',
      timestamp: DateTime.now(),
      isFromUser: true,
      attachmentName: attachmentName,
      attachmentUrl: attachmentUrl,
    );

    if (_activeThreadId != null) {
      Provider.of<ChatProvider>(context, listen: false)
          .addMessageToThread(_activeThreadId!, userMsg);
    }

    setState(() {
      _messages.add(userMsg);
      _attachedFileName = null;
      _attachedFileUrl = null;
    });
    _textController.clear();
    _scrollToBottom();

    // AI Bot / Seller automatic reply
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      HapticService.lightImpact();

      String replyText;
      final lower = cleanText.toLowerCase();

      if (widget.sellerName != null) {
        if (lower.contains('available') || lower.contains('stock')) {
          replyText = 'Yes, this item is in stock and ready to ship within 24 hours!';
        } else if (lower.contains('discount') || lower.contains('price')) {
          replyText = 'Our prices are best guaranteed authentic with member loyalty points earned upon checkout!';
        } else {
          replyText = 'Thank you for your message! Our merchant representative will attend to your request shortly.';
        }
      } else {
        // Lumora Support Assistant Logic
        final matched = _supportBotTopics.firstWhere(
          (t) => lower.contains(t['label']!.toLowerCase()) || t['label']!.toLowerCase().contains(lower),
          orElse: () => {},
        );

        if (matched.isNotEmpty) {
          replyText = matched['answer']!;
        } else if (lower.contains('human') || lower.contains('agent') || lower.contains('talk to')) {
          replyText = 'A Lumora human support agent has been notified and will reply to this thread shortly. Thank you for your patience!';
        } else if (lower.contains('report')) {
          replyText = 'We have logged your product report. Please attach any photos or screenshots so our quality assurance team can inspect the seller.';
        } else {
          replyText = 'Thank you for contacting Lumora! Tap any of the topics below or ask about our genuine beauty curation.';
        }
      }

      final botMsg = ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderName: widget.sellerName ?? 'Lumora Assistant',
        senderRole: widget.sellerRole ?? 'Bot',
        message: replyText,
        timestamp: DateTime.now(),
        isFromUser: false,
        isBot: widget.sellerName == null,
      );

      if (_activeThreadId != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .addMessageToThread(_activeThreadId!, botMsg);
      }

      setState(() {
        _messages.add(botMsg);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.sellerName ?? widget.title;
    final subtitleText = widget.sellerName != null ? 'Official Lumora Merchant' : widget.subtitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.plum),
          onPressed: () {
            HapticService.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    titleText,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.plum,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.sellerName != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 15, color: Color(0xFF6F8F78)),
                ],
              ],
            ),
            Text(
              subtitleText,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Product Context Banner (if inquiring about a product)
          if (_normalizedProductContext != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDFB),
                border: Border(bottom: BorderSide(color: Color(0xFFE8D8D0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8EEE9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (_normalizedProductContext!['image'] ?? '').isNotEmpty
                        ? buildLumoraImage(
                            _normalizedProductContext!['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.spa_outlined, color: AppColors.plum, size: 22),
                          )
                        : const Icon(Icons.spa_outlined, color: AppColors.plum, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INQUIRING ABOUT THIS ITEM',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.rose,
                          ),
                        ),
                        Text(
                          _normalizedProductContext!['name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.plum,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _normalizedProductContext!['price'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.plum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Quick Action Bot Buttons (from config/support_bot.php)
          if (widget.sellerName == null)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _supportBotTopics.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = _supportBotTopics[index];
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8D8D0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    label: Text(
                      topic['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.plum,
                      ),
                    ),
                    onPressed: () => _sendMessage(topic['label']!),
                  );
                },
              ),
            ),

          // Attached File Indicator
          if (_attachedFileName != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5C8A54).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: Color(0xFF5C8A54)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedFileName!,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF385333)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _attachedFileName = null;
                      _attachedFileUrl = null;
                    }),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF5C8A54)),
                  ),
                ],
              ),
            ),

          // Message Input Field with Attachment Button
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.viewInsetsOf(context).bottom > 0
                  ? 10
                  : (MediaQuery.paddingOf(context).bottom + 10),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8D8D0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.muted, size: 22),
                  onPressed: _sendAttachmentPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLength: 1000,
                    style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.ink),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: widget.sellerName != null ? 'Message ${widget.sellerName}...' : 'Ask Lumora Assistant...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB2A4A1)),
                      filled: true,
                      fillColor: const Color(0xFFFAF5F2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: Color(0xFFE8D8D0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: AppColors.plum, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(val, attachmentName: _attachedFileName, attachmentUrl: _attachedFileUrl),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.plum,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_textController.text, attachmentName: _attachedFileName, attachmentUrl: _attachedFileUrl),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isFromUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: msg.isBot ? const Color(0xFF351128) : const Color(0xFFB85E68),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  msg.isBot ? Icons.auto_awesome : Icons.storefront,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.plum : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: const Color(0xFFE8D8D0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.attachmentUrl != null && msg.attachmentUrl!.startsWith('data:image/')) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(msg.attachmentUrl!.split(',').last),
                        width: 180,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else if (msg.attachmentName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFFAF5F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 14,
                            color: isMe ? Colors.white : AppColors.rose,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            msg.attachmentName!,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isMe ? Colors.white : AppColors.plum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    msg.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isMe ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF9C8A8F),
                    ),
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
