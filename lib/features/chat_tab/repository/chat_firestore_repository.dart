import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_service.dart';
import '../model/chat_bubble_model.dart';
import '../model/chat_model.dart';

/// All Firestore reads/writes for chat live here. Controllers depend on this
/// so swapping/extending the backend is a single-file concern.
///
/// Data model:
///   conversations/{conversationId}
///     participants: [appUserIdA, appUserIdB]
///     participantInfo: { appUserId: {name, email, image} }
///     lastMessage, lastMessageTime, lastSenderId
///     unread: { appUserId: <int> }
///     type: 'personal' | 'community'
///     groupName?, groupDescription?
///   conversations/{conversationId}/messages/{messageId}
///     text, senderId, timestamp
class ChatFirestoreRepository {
  final FirebaseFirestore _db = FirebaseService.instance.db;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  /// Deterministic id for a 1:1 chat so both users share the same document.
  static String personalConversationId(String a, String b) {
    final ids = [a, b]..sort();
    return 'p_${ids[0]}_${ids[1]}';
  }

  /// Publish/refresh this user's directory entry so others can resolve their
  /// display name and avatar when starting a conversation.
  Future<void> registerUser({
    required String userId,
    required String name,
    required String email,
    required String image,
  }) async {
    await _db.collection('users').doc(userId).set({
      'id': userId,
      'name': name,
      'email': email,
      'image': image,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Conversation list ──────────────────────────────────────────────────────

  Stream<List<MessageModel>> watchConversations(String myId) {
    return _conversations
        .where('participants', arrayContains: myId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            // Hide conversations this user has "deleted" without erasing them
            // for the other participant.
            .where((d) {
              final hidden =
                  (d.data()['hiddenFor'] as List?)?.cast<String>() ?? const [];
              return !hidden.contains(myId);
            })
            .map((d) => _conversationToModel(d.id, d.data(), myId))
            .toList());
  }

  MessageModel _conversationToModel(
    String convId,
    Map<String, dynamic> data,
    String myId,
  ) {
    final type = (data['type'] == 'community')
        ? MessageType.community
        : MessageType.personal;

    final participants =
        (data['participants'] as List?)?.cast<String>() ?? const [];
    final info = (data['participantInfo'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final unread = (data['unread'] as Map?)?.cast<String, dynamic>() ?? const {};

    // Identify the "other" participant for 1:1 chats.
    final otherId = participants.firstWhere(
      (p) => p != myId,
      orElse: () => '',
    );
    final other = (info[otherId] as Map?)?.cast<String, dynamic>() ?? const {};

    final ts = data['lastMessageTime'];
    final lastTime = ts is Timestamp ? ts.toDate() : DateTime.now();

    return MessageModel(
      id: convId,
      senderId: otherId,
      senderName: (other['name'] ?? '') as String,
      senderEmail: (other['email'] ?? '') as String,
      senderProfileImage: (other['image'] ?? '') as String,
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: lastTime,
      unreadCount: (unread[myId] as num?)?.toInt() ?? 0,
      messageType: type,
      groupName: data['groupName'] as String?,
      groupDescription: data['groupDescription'] as String?,
      participants: participants,
    );
  }

  // ── Messages within a conversation ───────────────────────────────────────────

  Stream<List<ChatBubble>> watchMessages(String conversationId, String myId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final ts = data['timestamp'];
              return ChatBubble(
                id: d.id,
                text: (data['text'] ?? '') as String,
                timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
                isMe: (data['senderId'] ?? '') == myId,
              );
            }).toList());
  }

  /// Ensure a 1:1 conversation document exists before it is opened.
  Future<void> ensureConversation({
    required String conversationId,
    required String myId,
    required Map<String, String> myInfo,
    required String otherId,
    required Map<String, String> otherInfo,
  }) async {
    final ref = _conversations.doc(conversationId);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'participants': [myId, otherId],
      'participantInfo': {myId: myInfo, otherId: otherInfo},
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unread': {myId: 0, otherId: 0},
      'type': 'personal',
    });
  }

  /// Append a message and update the conversation preview + unread counters
  /// atomically.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final convRef = _conversations.doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    await _db.runTransaction((tx) async {
      final convSnap = await tx.get(convRef);
      final data = convSnap.data() ?? {};
      final participants =
          (data['participants'] as List?)?.cast<String>() ?? [senderId];
      final unread =
          (data['unread'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      // Everyone except the sender gains one unread; the sender is reset to 0.
      final newUnread = <String, dynamic>{};
      for (final p in participants) {
        if (p == senderId) {
          newUnread[p] = 0;
        } else {
          newUnread[p] = ((unread[p] as num?)?.toInt() ?? 0) + 1;
        }
      }

      tx.set(msgRef, {
        'text': text,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      tx.set(
        convRef,
        {
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': senderId,
          'unread': newUnread,
          // New activity re-surfaces the chat for anyone who had hidden it.
          'hiddenFor': <String>[],
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> markRead(String conversationId, String myId) async {
    await _conversations.doc(conversationId).set({
      'unread': {myId: 0},
    }, SetOptions(merge: true));
  }

  /// Soft-delete: hides the conversation for [myId] only. The other
  /// participant keeps their history. Sending a new message re-surfaces it (see
  /// [sendMessage], which clears `hiddenFor`).
  Future<void> hideConversation(String conversationId, String myId) async {
    await _conversations.doc(conversationId).set({
      'hiddenFor': FieldValue.arrayUnion([myId]),
    }, SetOptions(merge: true));
  }
}
