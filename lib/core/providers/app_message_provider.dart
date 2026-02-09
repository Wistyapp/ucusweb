import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class AppMessageProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  ConversationModel? _currentConversation;
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  ConversationModel? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) {
      return sum + conv.unreadCount.values.fold(0, (s, c) => s + c);
    });
  }

  void loadConversations(String userId) {
    _conversationsSubscription?.cancel();

    _conversationsSubscription = _firestoreService
        .getConversationsStream(userId)
        .listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  void loadMessages(String conversationId) {
    _messagesSubscription?.cancel();

    _messagesSubscription = _firestoreService
        .getMessagesStream(conversationId)
        .listen((messages) {
      _currentMessages = messages;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  Future<void> openConversation(String conversationId, String currentUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentConversation = _conversations.firstWhere(
            (c) => c.id == conversationId,
        orElse: () => _conversations.first,
      );

      loadMessages(conversationId);

      await _firestoreService.markMessagesAsRead(conversationId, currentUserId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> startConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserType,
    String? currentUserImage,
    required String otherUserId,
    required String otherUserName,
    required String otherUserType,
    String? otherUserImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final participantsInfo = {
        currentUserId: ParticipantInfo(
          displayName: currentUserName,
          profileImage: currentUserImage,
          userType: currentUserType,
        ),
        otherUserId: ParticipantInfo(
          displayName: otherUserName,
          profileImage: otherUserImage,
          userType: otherUserType,
        ),
      };

      final conversationId = await _firestoreService.getOrCreateConversation(
        currentUserId,
        otherUserId,
        participantsInfo,
      );

      _isLoading = false;
      notifyListeners();
      return conversationId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderProfileImage,
    required String text,
    List<AttachmentModel>? attachments,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderProfileImage: senderProfileImage,
        text: text,
        attachments: attachments ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.sendMessage(conversationId, message);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _firestoreService.markMessagesAsRead(conversationId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void closeConversation() {
    _messagesSubscription?.cancel();
    _currentConversation = null;
    _currentMessages = [];
    notifyListeners();
  }

  int getUnreadCountForUser(String conversationId, String userId) {
    final conversation = _conversations.firstWhere(
          (c) => c.id == conversationId,
      orElse: () => _conversations.first,
    );
    return conversation.getUnreadCountFor(userId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
