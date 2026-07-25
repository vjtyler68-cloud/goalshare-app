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

  /// Whether this message has been edited after it was originally sent.
  final bool isEdited;

  /// Emoji reactions on this message, keyed by the reactor's app user id
  /// (userId -> emoji). One reaction per person, like Instagram/Facebook.
  final Map<String, String> reactions;

  /// The current user's own reaction emoji ('' if they haven't reacted).
  final String myReaction;

  const ChatBubble({
    required this.id,
    required this.text,
    this.imageData = '',
    this.gifUrl = '',
    required this.timestamp,
    required this.isMe,
    this.isEdited = false,
    this.reactions = const {},
    this.myReaction = '',
  });

  bool get hasImage => imageData.isNotEmpty;
  bool get hasGif => gifUrl.isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;

  /// Aggregated reaction counts (emoji -> number of people), for the little
  /// chip shown on the bubble.
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      if (emoji.isEmpty) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  ChatBubble copyWith({
    String? text,
    bool? isEdited,
    Map<String, String>? reactions,
    String? myReaction,
  }) =>
      ChatBubble(
        id: id,
        text: text ?? this.text,
        imageData: imageData,
        gifUrl: gifUrl,
        timestamp: timestamp,
        isMe: isMe,
        isEdited: isEdited ?? this.isEdited,
        reactions: reactions ?? this.reactions,
        myReaction: myReaction ?? this.myReaction,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'image': imageData,
        'gif': gifUrl,
        'timestamp': timestamp.toIso8601String(),
        'isMe': isMe,
        'isEdited': isEdited,
        if (reactions.isNotEmpty) 'reactions': reactions,
      };

  factory ChatBubble.fromJson(Map<String, dynamic> json) => ChatBubble(
        id: json['id'] as String,
        text: (json['text'] as String?) ?? '',
        imageData: (json['image'] as String?) ?? '',
        gifUrl: (json['gif'] as String?) ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
        isMe: json['isMe'] as bool,
        isEdited: (json['isEdited'] as bool?) ?? false,
        reactions: (json['reactions'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
            ) ??
            const {},
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
