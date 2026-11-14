import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ChatProvider extends ChangeNotifier {
  static const String _baseStorageKey = 'lumora_buyer_conversations_v2';
  String? _currentUserKey;
  final List<ConversationThread> _threads = [];

  String get _storageKey => (_currentUserKey != null && _currentUserKey!.isNotEmpty)
      ? '${_baseStorageKey}_$_currentUserKey'
      : '${_baseStorageKey}_guest';

  List<ConversationThread> get threads {
    final sorted = List<ConversationThread>.from(_threads);
    sorted.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return List.unmodifiable(sorted);
  }

  int get totalUnreadCount =>
      _threads.fold(0, (sum, thread) => sum + thread.unreadCount);

  int get unreadCount => totalUnreadCount;

  ChatProvider() {
    _loadThreads();
  }

  Future<void> syncWithAuth(String? userEmail) async {
    final normalized = userEmail?.trim().toLowerCase();
    if (_currentUserKey == normalized) return;
    _currentUserKey = normalized;
    await _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _threads.clear();
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _threads.addAll(
          list.map((e) => ConversationThread.fromJson(e as Map<String, dynamic>)),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider._loadThreads error: $e');
      _threads.clear();
      notifyListeners();
    }
  }

  Future<void> _saveThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_threads.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ChatProvider._saveThreads error: $e');
    }
  }

  ConversationThread getOrCreateThread({
    required String sellerName,
    String? sellerRole,
    Map<String, String>? productContext,
  }) {
    final normalizedName = sellerName.trim().toLowerCase();
    final idx = _threads.indexWhere(
      (t) => t.sellerName.trim().toLowerCase() == normalizedName,
    );

    if (idx >= 0) {
      final existing = _threads[idx];
      if (productContext != null) {
        final updated = ConversationThread(
          id: existing.id,
          sellerId: existing.sellerId,
          sellerName: existing.sellerName,
          sellerRole: sellerRole ?? existing.sellerRole,
          sellerAvatar: existing.sellerAvatar,
          productContext: productContext,
          messages: List<ChatMessage>.from(existing.messages),
          lastMessageAt: existing.lastMessageAt,
          unreadCount: existing.unreadCount,
        );
        _threads[idx] = updated;
        return updated;
      }
      return existing;
    }

    final now = DateTime.now();
    final newThread = ConversationThread(
      id: 'conv_${now.millisecondsSinceEpoch}',
      sellerId: 'seller_${normalizedName.hashCode.abs()}',
      sellerName: sellerName.trim(),
      sellerRole: sellerRole ?? 'Verified Luxury Merchant',
      productContext: productContext,
      lastMessageAt: now,
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'welcome_${now.millisecondsSinceEpoch}',
          senderName: sellerName.trim(),
          senderRole: 'Seller',
          message: productContext != null
              ? 'Hello! Thank you for inquiring about "${productContext['name']}". This item is authentic and in stock. How may we help you?'
              : 'Welcome to ${sellerName.trim()}! How can we assist you with our collection today?',
          timestamp: now,
          isFromUser: false,
          productContext: productContext,
        ),
      ],
    );

    _threads.insert(0, newThread);
    _saveThreads();
    notifyListeners();
    return newThread;
  }

  void markThreadRead(String threadId) {
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0 && _threads[idx].unreadCount > 0) {
      _threads[idx].unreadCount = 0;
      _saveThreads();
      notifyListeners();
    }
  }

  void addMessageToThread(String threadId, ChatMessage message, {bool incrementUnread = false}) {
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      _threads[idx].messages.add(message);
      _threads[idx].lastMessageAt = message.timestamp;
      if (incrementUnread) {
        _threads[idx].unreadCount += 1;
      }
      _saveThreads();
      notifyListeners();
    }
  }
}
