import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/chat_model.dart';

class MessagesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Tab Controller
  late TabController tabController;

  // Observable variables
  final RxList<MessageModel> personalMessages = <MessageModel>[].obs;
  final RxList<MessageModel> communityMessages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabSelection);
    loadMessagesData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _handleTabSelection() {
    currentTabIndex.value = tabController.index;
  }

  void loadMessagesData() {
    isLoading.value = true;

    // Mock personal messages data
    final List<MessageModel> personal = [
      MessageModel(
        id: '1',
        senderId: '101',
        senderName: 'Andre Sophia',
        senderEmail: 'andre.sophia@example.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&q=60&w=500',
        lastMessage: 'Hey, how are you doing today?',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
        unreadCount: 2,
        messageType: MessageType.personal,
        isOnline: true,
        isVerified: true,
      ),
      MessageModel(
        id: '2',
        senderId: '102',
        senderName: 'Michael Tony',
        senderEmail: 'michael.tony@example.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fm=jpg&q=60&w=500',
        lastMessage: 'Thanks for the help earlier!',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
        unreadCount: 0,
        messageType: MessageType.personal,
        isOnline: false,
        isVerified: false,
      ),
      MessageModel(
        id: '3',
        senderId: '103',
        senderName: 'Joseph Ray',
        senderEmail: 'joseph.ray@example.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?fm=jpg&q=60&w=500',
        lastMessage: 'Can we meet tomorrow?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 1,
        messageType: MessageType.personal,
        isOnline: true,
        isVerified: true,
      ),
      MessageModel(
        id: '4',
        senderId: '104',
        senderName: 'Thomas Adison',
        senderEmail: 'thomas.adison@example.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?fm=jpg&q=60&w=500',
        lastMessage: 'Great work on the project!',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        messageType: MessageType.personal,
        isOnline: false,
        isVerified: false,
      ),
    ];

    // Mock community messages data
    final List<MessageModel> community = [
      MessageModel(
        id: '5',
        senderId: '201',
        senderName: 'Flutter Developers',
        senderEmail: 'admin@flutterdev.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?fm=jpg&q=60&w=500',
        lastMessage: 'New Flutter 3.0 features discussion',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 5,
        messageType: MessageType.community,
        isOnline: true,
        isVerified: true,
        groupName: 'Flutter Developers',
        groupDescription: 'Community for Flutter developers',
        participants: ['user1', 'user2', 'user3', 'user4'],
      ),
      MessageModel(
        id: '6',
        senderId: '202',
        senderName: 'Design System',
        senderEmail: 'design@company.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?fm=jpg&q=60&w=500',
        lastMessage: 'Updated design guidelines available',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 45)),
        unreadCount: 3,
        messageType: MessageType.community,
        isOnline: false,
        isVerified: true,
        groupName: 'Design System',
        groupDescription: 'Design team collaboration',
        participants: ['designer1', 'designer2', 'developer1'],
      ),
      MessageModel(
        id: '7',
        senderId: '203',
        senderName: 'Project Alpha',
        senderEmail: 'project@alpha.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1556761175-4b46a572b786?fm=jpg&q=60&w=500',
        lastMessage: 'Sprint planning meeting at 3 PM',
        lastMessageTime: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 30),
        ),
        unreadCount: 0,
        messageType: MessageType.community,
        isOnline: true,
        isVerified: false,
        groupName: 'Project Alpha',
        groupDescription: 'Alpha project team',
        participants: ['pm1', 'dev1', 'dev2', 'tester1'],
      ),
      MessageModel(
        id: '8',
        senderId: '204',
        senderName: 'Tech News',
        senderEmail: 'news@tech.com',
        senderProfileImage:
            'https://images.unsplash.com/photo-1504639725590-34d0984388bd?fm=jpg&q=60&w=500',
        lastMessage: 'Latest tech trends and updates',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 7,
        messageType: MessageType.community,
        isOnline: false,
        isVerified: true,
        groupName: 'Tech News',
        groupDescription: 'Technology news and updates',
        participants: ['admin', 'moderator1', 'moderator2'],
      ),
    ];

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      personalMessages.assignAll(personal);
      communityMessages.assignAll(community);
      isLoading.value = false;
    });
  }

  void onMessageTap(MessageModel message) {
    // Mark message as read
    markMessageAsRead(message.id);

    // Navigate to chat screen
    Get.snackbar('Opening Chat', 'Opening chat with ${message.displayName}');
    // Add navigation logic here
    // Get.toNamed('/chat', arguments: message);
  }

  void onMessageLongPress(MessageModel message) {
    // Show options menu (delete, mute, etc.)
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Chat'),
              onTap: () {
                deleteMessage(message.id);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: const Text('Mute Chat'),
              onTap: () {
                muteMessage(message.id);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_chat_read_outlined),
              title: const Text('Mark as Read'),
              onTap: () {
                markMessageAsRead(message.id);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void markMessageAsRead(String messageId) {
    // Update personal messages
    final personalIndex = personalMessages.indexWhere((m) => m.id == messageId);
    if (personalIndex != -1) {
      personalMessages[personalIndex] = personalMessages[personalIndex]
          .copyWith(unreadCount: 0);
    }

    // Update community messages
    final communityIndex = communityMessages.indexWhere(
      (m) => m.id == messageId,
    );
    if (communityIndex != -1) {
      communityMessages[communityIndex] = communityMessages[communityIndex]
          .copyWith(unreadCount: 0);
    }
  }

  void deleteMessage(String messageId) {
    personalMessages.removeWhere((message) => message.id == messageId);
    communityMessages.removeWhere((message) => message.id == messageId);
    Get.snackbar('Deleted', 'Chat has been deleted');
  }

  void muteMessage(String messageId) {
    Get.snackbar('Muted', 'Chat has been muted');
    // Implement mute logic here
  }

  void onBackPressed() {
    Get.back();
  }

  void refreshData() {
    loadMessagesData();
  }

  // Get current list based on selected tab
  List<MessageModel> get currentList {
    return currentTabIndex.value == 0 ? personalMessages : communityMessages;
  }

  // Get counts
  int get personalMessagesCount => personalMessages.length;
  int get communityMessagesCount => communityMessages.length;

  // Get total unread count
  int get totalUnreadCount {
    final personalUnread = personalMessages.fold<int>(
      0,
      (sum, msg) => sum + msg.unreadCount,
    );
    final communityUnread = communityMessages.fold<int>(
      0,
      (sum, msg) => sum + msg.unreadCount,
    );
    return personalUnread + communityUnread;
  }

  // Get unread count for current tab
  int get currentTabUnreadCount {
    return currentList.fold<int>(0, (sum, msg) => sum + msg.unreadCount);
  }
}
