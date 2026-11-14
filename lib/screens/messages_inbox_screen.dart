import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final allThreads = chatProvider.threads;
        final filtered = _searchQuery.trim().isEmpty
            ? allThreads
            : allThreads.where((t) {
                final q = _searchQuery.trim().toLowerCase();
                return t.sellerName.toLowerCase().contains(q) ||
                    t.lastMessagePreview.toLowerCase().contains(q);
              }).toList();

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.plum),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.plum,
                  ),
                ),
                Text(
                  chatProvider.totalUnreadCount > 0
                      ? '${chatProvider.totalUnreadCount} unread message${chatProvider.totalUnreadCount == 1 ? '' : 's'}'
                      : 'Direct conversations with verified sellers',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFEAE3DD)),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Search seller or message...',
                      hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.muted),
                      prefixIcon: const Icon(Icons.search, size: 19, color: AppColors.muted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 17, color: AppColors.muted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(99),
                        borderSide: const BorderSide(color: AppColors.plum, width: 1.4),
                      ),
                    ),
                  ),
                ),

                // Pinned Lumora AI Concierge Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticService.selection();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.plum, Color(0xFF522147)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.plum.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Lumora Assistant (AI)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        '24/7 BOT',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.plum,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Ask about Lumora, developers, COD/GCash, or report a product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Seller Conversations List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 42, color: AppColors.muted),
                              const SizedBox(height: 10),
                              Text(
                                'No seller conversations found',
                                style: AppTextStyles.heading(size: 16, color: AppColors.plum),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Visit any boutique or product page to chat with a seller.',
                                style: AppTextStyles.body(size: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final thread = filtered[index];
                            return _buildThreadCard(context, chatProvider, thread);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThreadCard(
    BuildContext context,
    ChatProvider chatProvider,
    ConversationThread thread,
  ) {
    final hasUnread = thread.unreadCount > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticService.selection();
        chatProvider.markThreadRead(thread.id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              sellerName: thread.sellerName,
              sellerRole: thread.sellerRole,
              productContext: thread.productContext,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread ? AppColors.rose.withValues(alpha: 0.6) : AppColors.line,
            width: hasUnread ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.plum.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.plum,
                  child: Text(
                    thread.sellerName.isNotEmpty ? thread.sellerName[0].toUpperCase() : 'S',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                thread.sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  color: AppColors.plum,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: Color(0xFFC9972B)),
                          ],
                        ),
                      ),
                      Text(
                        _formatRelativeTime(thread.lastMessageAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                          color: hasUnread ? AppColors.rose : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (thread.productContext != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5ECE6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Inquiring: ${thread.productContext!['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessagePreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: hasUnread ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
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
