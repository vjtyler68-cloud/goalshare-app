import 'dart:convert';

/// A single message bubble within a conversation.
class ChatBubble {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  const ChatBubble({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isMe': isMe,
      };

  factory ChatBubble.fromJson(Map<String, dynamic> json) => ChatBubble(
        id: json['id'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isMe: json['isMe'] as bool,
      );

  static List<ChatBubble> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ChatBubble.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<ChatBubble> bubbles) =>
      jsonEncode(bubbles.map((b) => b.toJson()).toList());

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
