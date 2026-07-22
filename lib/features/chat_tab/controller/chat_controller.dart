import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/local/local_data.dart';
import '../../../routes/app_routes.dart';
import '../controller/chat_conversation_controller.dart';
import '../model/chat_model.dart';
import '../repository/chat_firestore_repository.dart';

const _kConversationsKey = 'chat_conversations';

class MessagesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Tab controller
  late TabController tabController;

  // Observable state
  final RxList<MessageModel> personalMessages = <MessageModel>[].obs;
  final RxList<MessageModel> communityMessages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentTabIndex = 0.obs;

  // Firebase-backed state
  final _repo = ChatFirestoreRepository();
  final _local = LocalService();
  StreamSubscription? _conversationsSub;
  String? _myId;

  bool get _useFirebase => FirebaseService.instance.isReady;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabSelection);
    _bootstrap();
  }

  @override
  void onClose() {
    _conversationsSub?.cancel();
    tabController.dispose();
    super.onClose();
  }

  void _handleTabSelection() {
    currentTabIndex.value = tabController.index;
  }

  /// Resolves the current user's app id, fetching it lazily if bootstrap
  /// hasn't finished yet. Prevents a race where callers (e.g. tapping a user
  /// to start a chat) invoke [startConversation] before [_bootstrap] has
  /// populated [_myId], which would wrongly fall back to the local path and
  /// open a non-shared conversation.
  Future<String?> _ensureMyId() async {
    if (_myId == null || _myId!.isEmpty) {
      _myId = await _local.getUserId();
    }
    return _myId;
  }

  Future<void> _bootstrap() async {
    _myId = await _local.getUserId();
    if (_useFirebase && _myId != null && _myId!.isNotEmpty) {
      await _publishSelfToDirectory();
      _listenToFirestore();
    } else {
      _loadConversations();
    }
  }

  Future<void> _publishSelfToDirectory() async {
    try {
      await _repo.registerUser(
        userId: _myId!,
        name: await _local.getName() ?? '',
        email: await _local.getEmail() ?? '',
        image: await _local.getImagePath() ?? '',
      );
    } catch (e) {
      log('Failed to publish user directory entry: $e');
    }
  }

  void _listenToFirestore() {
    isLoading.value = true;
    _conversationsSub = _repo.watchConversations(_myId!).listen(
      (all) {
        personalMessages.assignAll(
          all.where((m) => m.messageType == MessageType.personal).toList(),
        );
        communityMessages.assignAll(
          all.where((m) => m.messageType == MessageType.community).toList(),
        );
        isLoading.value = false;
      },
      onError: (e) {
        log('Firestore conversations stream error: $e');
        isLoading.value = false;
      },
    );
  }

  // ── Local persistence (fallback) ────────────────────────────────────────────

  Future<void> _loadConversations() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kConversationsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        final all = list
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        personalMessages.assignAll(
          all.where((m) => m.messageType == MessageType.personal).toList(),
        );
        communityMessages.assignAll(
          all.where((m) => m.messageType == MessageType.community).toList(),
        );
      }
    } catch (e) {
      log('Failed to load conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveConversations() async {
    if (_useFirebase) return; // Firestore is the source of truth.
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = [...personalMessages, ...communityMessages];
      await prefs.setString(
        _kConversationsKey,
        jsonEncode(all.map((m) => m.toJson()).toList()),
      );
    } catch (e) {
      log('Failed to save conversations: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Open (or create) a 1:1 chat with a user by their app id. Shared entry point
  /// for the Friends list and the Messages "new chat" picker.
  void startChatWith({
    required String userId,
    required String name,
    String email = '',
    String image = '',
  }) {
    startConversation(MessageModel(
      id: userId,
      senderId: userId,
      senderName: name,
      senderEmail: email,
      senderProfileImage: image,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      messageType: MessageType.personal,
    ));
  }

  /// Called from the community/follow flow to start a new conversation.
  Future<void> startConversation(MessageModel conversation) async {
    // Resolve identity first so we don't race bootstrap and wrongly fall back
    // to the local path (which would open a non-shared conversation).
    await _ensureMyId();
    if (_useFirebase && _myId != null && _myId!.isNotEmpty) {
      await _startFirebaseConversation(conversation);
      return;
    }

    final list = conversation.messageType == MessageType.personal
        ? personalMessages
        : communityMessages;

    final exists = list.any((m) => m.id == conversation.id);
    if (!exists) {
      list.insert(0, conversation);
      await _saveConversations();
    }
    _openConversation(conversation);
  }

  Future<void> _startFirebaseConversation(MessageModel other) async {
    final otherId = other.senderId;
    final convId = ChatFirestoreRepository.personalConversationId(
      _myId!,
      otherId,
    );

    try {
      await _repo.ensureConversation(
        conversationId: convId,
        myId: _myId!,
        myInfo: {
          'name': await _local.getName() ?? '',
          'email': await _local.getEmail() ?? '',
          'image': await _local.getImagePath() ?? '',
        },
        otherId: otherId,
        otherInfo: {
          'name': other.senderName,
          'email': other.senderEmail,
          'image': other.senderProfileImage,
        },
      );
    } catch (e) {
      log('Failed to ensure conversation: $e');
    }

    // Open using a model whose id is the shared Firestore conversation id.
    _openConversation(other.copyWith(id: convId));
  }

  void onMessageTap(MessageModel message) {
    _openConversation(message);
  }

  void _openConversation(MessageModel message) {
    // Register a fresh conversation controller scoped to this chat
    Get.delete<ChatConversationController>(force: true);
    Get.put(ChatConversationController(conversation: message));
    Get.toNamed(AppRoutes.chatConversationScreen);
  }

  void onMessageLongPress(MessageModel message) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete conversation'),
                onTap: () {
                  Get.back();
                  deleteMessage(message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_off_outlined),
                title: const Text('Mute notifications'),
                onTap: () {
                  Get.back();
                  muteMessage(message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mark_chat_read_outlined),
                title: const Text('Mark as read'),
                onTap: () {
                  Get.back();
                  markMessageAsRead(message.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Update the conversation preview after a new message is sent.
  /// (Firestore path updates the preview server-side; this is the local path.)
  Future<void> updateLastMessage(String conversationId, String text) async {
    if (_useFirebase) return;

    void update(RxList<MessageModel> list) {
      final idx = list.indexWhere((m) => m.id == conversationId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          lastMessage: text,
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
        );
      }
    }

    update(personalMessages);
    update(communityMessages);
    await _saveConversations();
  }

  void markMessageAsRead(String messageId) {
    if (_useFirebase && _myId != null) {
      _repo.markRead(messageId, _myId!);
      return;
    }

    void update(RxList<MessageModel> list) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(unreadCount: 0);
      }
    }

    update(personalMessages);
    update(communityMessages);
    _saveConversations();
  }

  Future<void> deleteMessage(String messageId) async {
    if (_useFirebase && _myId != null) {
      try {
        // Soft-delete: hide for me only, never erase the other user's history.
        await _repo.hideConversation(messageId, _myId!);
      } catch (e) {
        log('Failed to hide conversation: $e');
      }
      return;
    }

    personalMessages.removeWhere((m) => m.id == messageId);
    communityMessages.removeWhere((m) => m.id == messageId);
    await _saveConversations();
    // Also clear the message history for this conversation
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages_$messageId');
  }

  void muteMessage(String messageId) {
    // Mute logic — persist muted IDs when backend is available
    Get.snackbar(
      'Muted',
      'Notifications muted for this conversation',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void refreshData() {
    if (!_useFirebase) _loadConversations();
  }

  // ── Computed ───────────────────────────────────────────────────────────────

  List<MessageModel> get currentList =>
      currentTabIndex.value == 0 ? personalMessages : communityMessages;

  int get totalUnreadCount {
    int count = 0;
    for (final m in [...personalMessages, ...communityMessages]) {
      count += m.unreadCount;
    }
    return count;
  }

  int get currentTabUnreadCount =>
      currentList.fold(0, (sum, m) => sum + m.unreadCount);
}
