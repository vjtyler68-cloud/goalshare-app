import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spanx/features/chat_tab/model/chat_bubble_model.dart';
import 'package:spanx/features/chat_tab/model/chat_model.dart';
import 'package:spanx/features/chat_tab/controller/chat_controller.dart';

class ChatConversationController extends GetxController {
  final MessageModel conversation;
  ChatConversationController({required this.conversation});

  final RxList<ChatBubble> messages = <ChatBubble>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isSending = false.obs;

  String get _prefsKey => 'chat_messages_${conversation.id}';

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
    // Mark conversation as read when opened
    _markRead();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      messages.assignAll(ChatBubble.decodeList(raw));
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, ChatBubble.encodeList(messages));
  }

  void _markRead() {
    if (Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().markMessageAsRead(conversation.id);
    }
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    textController.clear();
    isSending.value = true;

    final bubble = ChatBubble(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    messages.add(bubble);
    await _saveMessages();
    _scrollToBottom();

    // Update the conversation preview in the list
    if (Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().updateLastMessage(conversation.id, text);
    }

    isSending.value = false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get otherUserName => conversation.displayName;
  String get otherUserAvatar => conversation.senderProfileImage;
  bool get isOtherOnline => conversation.isOnline;
}
