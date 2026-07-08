import 'dart:async';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spanx/core/firebase/firebase_service.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/features/chat_tab/model/chat_bubble_model.dart';
import 'package:spanx/features/chat_tab/model/chat_model.dart';
import 'package:spanx/features/chat_tab/controller/chat_controller.dart';
import 'package:spanx/features/chat_tab/repository/chat_firestore_repository.dart';

class ChatConversationController extends GetxController {
  final MessageModel conversation;
  ChatConversationController({required this.conversation});

  final RxList<ChatBubble> messages = <ChatBubble>[].obs;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isSending = false.obs;

  final _repo = ChatFirestoreRepository();
  final _local = LocalService();
  StreamSubscription? _messagesSub;
  String? _myId;

  bool get _useFirebase => FirebaseService.instance.isReady;
  String get _prefsKey => 'chat_messages_${conversation.id}';

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    _myId = await _local.getUserId();
    if (_useFirebase && _myId != null && _myId!.isNotEmpty) {
      _listenToFirestore();
    } else {
      await _loadMessages();
    }
    _markRead();
  }

  void _listenToFirestore() {
    _messagesSub =
        _repo.watchMessages(conversation.id, _myId!).listen((list) {
      messages.assignAll(list);
      _scrollToBottom();
    }, onError: (e) => log('Firestore messages stream error: $e'));
  }

  // ── Local (fallback) ─────────────────────────────────────────────────────────

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

    if (_useFirebase && _myId != null && _myId!.isNotEmpty) {
      try {
        await _repo.sendMessage(
          conversationId: conversation.id,
          senderId: _myId!,
          text: text,
        );
      } catch (e) {
        log('Failed to send message: $e');
        Get.snackbar(
          'Message not sent',
          'Please check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      isSending.value = false;
      return;
    }

    // Local fallback
    final bubble = ChatBubble(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    messages.add(bubble);
    await _saveMessages();
    _scrollToBottom();

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
