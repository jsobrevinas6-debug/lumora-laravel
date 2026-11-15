import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  static const String _baseStorageKey = 'lumora_buyer_conversations_v2';
  String? _currentUserKey;
  String? _authToken;
  final List<ConversationThread> _threads = [];
  ConversationThread? _supportThread;
  bool _isLoading = false;
  String? _lastError;
  Future<void>? _inFlightRefresh;

  String get _storageKey => (_currentUserKey != null && _currentUserKey!.isNotEmpty)
      ? '${_baseStorageKey}_$_currentUserKey'
      : '${_baseStorageKey}_guest';

  List<ConversationThread> get threads {
    final sorted = List<ConversationThread>.from(_threads);
    sorted.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return List.unmodifiable(sorted);
  }

  ConversationThread? get supportThread => _supportThread;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  int get totalUnreadCount =>
      _threads.fold(0, (sum, thread) => sum + thread.unreadCount) +
      (_supportThread?.unreadCount ?? 0);

  int get unreadCount => totalUnreadCount;

  ChatProvider() {
    _loadThreads();
  }

  Future<void> syncWithAuth(String? userEmail, {String? token}) async {
    final normalized = userEmail?.trim().toLowerCase();
    final userChanged = _currentUserKey != normalized;
    final tokenChanged = _authToken != token;
    if (!userChanged && !tokenChanged) return;

    _currentUserKey = normalized;
    _authToken = token;

    if (userChanged) {
      _supportThread = null;
      _lastError = null;
      await _loadThreads();
    }

    if (ApiConfig.useLiveApi && _authToken != null && _authToken!.isNotEmpty) {
      await refreshFromServer(token: _authToken);
    }
  }

  Future<void> refreshFromServer({String? token}) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      await _loadThreads();
      return;
    }

    if (_inFlightRefresh != null) {
      return _inFlightRefresh;
    }

    _inFlightRefresh = _performRefreshFromServer(tok);
    try {
      await _inFlightRefresh;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _performRefreshFromServer(String tok) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService().fetchConversations(token: tok);
    _isLoading = false;

    if (res.success) {
      final existingById = {for (final t in _threads) t.id: t};
      final merged = res.conversations.map((serverThread) {
        final existing = existingById[serverThread.id];
        if (existing != null &&
            existing.messages.length > 1 &&
            serverThread.messages.length <= 1) {
          final latestServerId =
              serverThread.messages.isNotEmpty ? serverThread.messages.last.id : null;
          final alreadyContainsLatest = latestServerId == null ||
              existing.messages.any((m) => m.id == latestServerId);
          if (alreadyContainsLatest) {
            return ConversationThread(
              id: serverThread.id,
              sellerId: serverThread.sellerId,
              sellerName: serverThread.sellerName,
              sellerRole: serverThread.sellerRole,
              sellerAvatar: serverThread.sellerAvatar,
              productContext: serverThread.productContext ?? existing.productContext,
              messages: List<ChatMessage>.from(existing.messages),
              lastMessageAt: serverThread.lastMessageAt,
              unreadCount: serverThread.unreadCount,
            );
          }
        }
        return serverThread;
      }).toList();

      _threads
        ..clear()
        ..addAll(merged);
      if (res.supportConversation != null) {
        _supportThread = res.supportConversation;
      }
      _lastError = null;
      await _saveThreads();
    } else {
      _lastError = res.message;
    }

    notifyListeners();
  }

  Future<void> _loadThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _threads.clear();
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _threads.addAll(
          list.map((e) => ConversationThread.fromJson(Map<String, dynamic>.from(e as Map))),
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

  void _upsertThread(ConversationThread thread) {
    final idx = _threads.indexWhere((t) => t.id == thread.id);
    if (idx >= 0) {
      _threads[idx] = thread;
    } else {
      _threads.insert(0, thread);
    }
    _saveThreads();
    notifyListeners();
  }

  Future<ConversationThread?> openSellerConversation({
    String? sellerId,
    required String sellerName,
    String? sellerRole,
    Map<String, String>? productContext,
    String? token,
  }) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      return getOrCreateThread(
        sellerName: sellerName,
        sellerRole: sellerRole,
        productContext: productContext,
      );
    }

    final productId = int.tryParse(productContext?['id'] ?? '');
    final res = await ApiService().startSellerConversation(
      sellerId: sellerId,
      sellerName: sellerName,
      productId: productId,
      token: tok,
    );

    if (res.success && res.conversation != null) {
      final thread = res.conversation!;
      thread.unreadCount = 0;
      _lastError = null;
      _upsertThread(thread);
      return thread;
    }

    _lastError = res.message ?? 'Could not connect to merchant conversation.';
    notifyListeners();
    return null;
  }

  Future<ConversationThread?> fetchConversationById(
    String conversationId, {
    String? token,
  }) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      final idx = _threads.indexWhere((t) => t.id == conversationId);
      return idx >= 0 ? _threads[idx] : null;
    }

    final res = await ApiService().fetchConversationMessages(
      conversationId: conversationId,
      token: tok,
    );

    if (res.success && res.conversation != null) {
      final thread = res.conversation!;
      thread.unreadCount = 0;
      _lastError = null;
      _upsertThread(thread);
      return thread;
    }

    _lastError = res.message;
    return null;
  }

  Future<({
    bool success,
    ChatMessage? userMessage,
    String? error,
  })> sendMessageToSeller({
    required String conversationId,
    required String body,
    String? attachmentData,
    String? attachmentName,
    String? token,
  }) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      return (success: false, userMessage: null, error: 'Offline or unauthenticated.');
    }

    final res = await ApiService().sendSellerMessage(
      conversationId: conversationId,
      body: body,
      attachmentData: attachmentData,
      attachmentName: attachmentName,
      token: tok,
    );

    if (res.success && res.messageItem != null) {
      final item = res.messageItem!;
      final idx = _threads.indexWhere((t) => t.id == conversationId);
      if (idx >= 0) {
        if (!_threads[idx].messages.any((m) => m.id == item.id)) {
          _threads[idx].messages.add(item);
        }
        _threads[idx].lastMessageAt = item.timestamp;
        _threads[idx].unreadCount = 0;
        await _saveThreads();
      } else if (res.conversation != null) {
        _threads.insert(0, res.conversation!..messages.add(item));
        await _saveThreads();
      }
      _lastError = null;
      notifyListeners();
      return (success: true, userMessage: item, error: null);
    }

    _lastError = res.message ?? 'Failed to send message.';
    notifyListeners();
    return (success: false, userMessage: null, error: _lastError);
  }

  Future<ConversationThread?> openSupportConversation({String? token}) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      return _supportThread;
    }

    final res = await ApiService().fetchSupportConversation(token: tok);
    if (res.success && res.conversation != null) {
      _supportThread = res.conversation!..unreadCount = 0;
      _lastError = null;
      notifyListeners();
      return _supportThread;
    }

    _lastError = res.message;
    notifyListeners();
    return null;
  }

  Future<({
    bool success,
    ChatMessage? userMessage,
    ChatMessage? botMessage,
    String? error,
  })> sendMessageToSupport({
    required String body,
    String? attachmentData,
    String? attachmentName,
    String? token,
  }) async {
    final tok = token ?? _authToken;
    if (!ApiConfig.useLiveApi || tok == null || tok.isEmpty) {
      return (
        success: false,
        userMessage: null,
        botMessage: null,
        error: 'Offline or unauthenticated.',
      );
    }

    final res = await ApiService().sendSupportMessage(
      body: body,
      attachmentData: attachmentData,
      attachmentName: attachmentName,
      token: tok,
    );

    if (res.success && res.userMessage != null) {
      final base = res.conversation ?? _supportThread;
      if (base != null) {
        final mergedMessages = List<ChatMessage>.from(_supportThread?.messages ?? const []);
        if (!mergedMessages.any((m) => m.id == res.userMessage!.id)) {
          mergedMessages.add(res.userMessage!);
        }
        if (res.botMessage != null && !mergedMessages.any((m) => m.id == res.botMessage!.id)) {
          mergedMessages.add(res.botMessage!);
        }
        _supportThread = ConversationThread(
          id: base.id,
          sellerId: 'support',
          sellerName: base.sellerName,
          sellerRole: base.sellerRole,
          messages: mergedMessages,
          lastMessageAt: res.botMessage?.timestamp ?? res.userMessage!.timestamp,
          unreadCount: 0,
        );
      }
      _lastError = null;
      notifyListeners();
      return (
        success: true,
        userMessage: res.userMessage,
        botMessage: res.botMessage,
        error: null,
      );
    }

    _lastError = res.message ?? 'Failed to contact Lumora Support.';
    notifyListeners();
    return (
      success: false,
      userMessage: null,
      botMessage: null,
      error: _lastError,
    );
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
    if (ApiConfig.useLiveApi &&
        int.tryParse(threadId) != null &&
        _authToken != null &&
        _authToken!.isNotEmpty) {
      ApiService().markConversationRead(conversationId: threadId, token: _authToken);
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
