---
name: Chat Architecture
description: How the chat feature is structured — no real-time backend, SharedPreferences persistence, controller lifecycle.
---

# Chat Architecture

## The rule
Chat has no dedicated backend endpoint. All messages are stored locally via SharedPreferences. The architecture is structured so connecting a real backend (REST or WebSocket) is a one-file change in the repository layer.

**Why:** The existing backend (goalshare-backend-production.up.railway.app) has no /messages or /conversations endpoints as of the initial import. Shipping fake mock data was worse than shipping local-first persistence.

## How to apply
- `MessagesController` (chat_controller.dart) — manages the conversation list, persisted at `chat_conversations` key in SharedPreferences. Registered in AppBindings with fenix: true. Found via Get.find in MessagesPage.
- `ChatConversationController` (chat_conversation_controller.dart) — scoped per conversation, instantiated via Get.put immediately before Get.toNamed(chatConversationScreen). Deleted and re-created each open (force: true). NOT in AppBindings.
- `ChatConversationScreen` guards against direct route access: checks Get.isRegistered<ChatConversationController>() in build and pops back if missing.
- Messages are stored per conversation at key `chat_messages_{conversationId}` in SharedPreferences.
- `onBackPressed` was removed from MessagesController — the UI calls Get.back() directly.
