import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';
import '../controller/chat_conversation_controller.dart';
import '../model/chat_model.dart';

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

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabSelection);
    _loadConversations();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _handleTabSelection() {
    currentTabIndex.value = tabController.index;
  }

  // ── Persistence ────────────────────────────────────────────────────────────

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

  /// Called from the community/follow flow to start a new conversation.
  Future<void> startConversation(MessageModel conversation) async {
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
  Future<void> updateLastMessage(String conversationId, String text) async {
    void _update(RxList<MessageModel> list) {
      final idx = list.indexWhere((m) => m.id == conversationId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          lastMessage: text,
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
        );
      }
    }

    _update(personalMessages);
    _update(communityMessages);
    await _saveConversations();
  }

  void markMessageAsRead(String messageId) {
    void _update(RxList<MessageModel> list) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(unreadCount: 0);
      }
    }

    _update(personalMessages);
    _update(communityMessages);
    _saveConversations();
  }

  Future<void> deleteMessage(String messageId) async {
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

  void refreshData() => _loadConversations();

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
