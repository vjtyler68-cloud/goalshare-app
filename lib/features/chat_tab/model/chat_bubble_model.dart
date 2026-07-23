import 'dart:convert';

/// A single message bubble within a conversation.
class ChatBubble {
  final String id;
  final String text;

  /// Optional attached photo (base64 JPEG). Empty for a plain text message.
  final String imageData;

  /// Optional GIPHY GIF URL. Empty unless this is a GIF message. GIFs are
  /// stored as a URL (not base64) because they are animated and too big for
  /// the in-Firestore photo path.
  final String gifUrl;

  final DateTime timestamp;
  final bool isMe;

  const ChatBubble({
    required this.id,
    required this.text,
    this.imageData = '',
    this.gifUrl = '',
    required this.timestamp,
    required this.isMe,
  });

  bool get hasImage => imageData.isNotEmpty;
  bool get hasGif => gifUrl.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'image': imageData,
        'gif': gifUrl,
        'timestamp': timestamp.toIso8601String(),
        'isMe': isMe,
      };

  factory ChatBubble.fromJson(Map<String, dynamic> json) => ChatBubble(
        id: json['id'] as String,
        text: (json['text'] as String?) ?? '',
        imageData: (json['image'] as String?) ?? '',
        gifUrl: (json['gif'] as String?) ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
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
