enum MessageType { personal, community }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String senderProfileImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final MessageType messageType;
  final bool isOnline;
  final bool? isVerified;
  final String? groupName; // For community messages
  final String? groupDescription; // For community messages
  final List<String>? participants; // For community messages

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.senderProfileImage,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.messageType = MessageType.personal,
    this.isOnline = false,
    this.isVerified = false,
    this.groupName,
    this.groupDescription,
    this.participants,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? senderProfileImage,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    MessageType? messageType,
    bool? isOnline,
    bool? isVerified,
    String? groupName,
    String? groupDescription,
    List<String>? participants,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messageType: messageType ?? this.messageType,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      participants: participants ?? this.participants,
    );
  }

  // Helper method to get display name based on message type
  String get displayName {
    return messageType == MessageType.community
        ? (groupName ?? 'Community Group')
        : senderName;
  }

  // Helper method to get display description
  String get displayDescription {
    return messageType == MessageType.community
        ? (groupDescription ?? 'Community chat')
        : senderEmail;
  }

  // Helper method to format time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'senderProfileImage': senderProfileImage,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'messageType': messageType.name,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'participants': participants,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      senderProfileImage: json['senderProfileImage'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.personal,
      ),
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
      groupName: json['groupName'],
      groupDescription: json['groupDescription'],
      participants: json['participants'] != null
          ? List<String>.from(json['participants'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
