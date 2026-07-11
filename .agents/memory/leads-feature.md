---
name: Leads / Clients feature storage
description: Why the Leads list is stored on-device (Hive) and not on the backend
---

# Leads / Clients feature

The Leads (client list) feature stores data **on-device with Hive**, not on the Railway backend.

**Why:** The backend is a separate Railway service we cannot modify, and it has **no leads/clients endpoint** (the existing `/goals/clients` is goal-scoped, not a standalone lead list). The user wanted a lead list "available at all times" and offline. On-device Hive persistence satisfies that reliably without depending on the flaky backend (which has a history of save failures for this app).

**How it works:** `LeadsController` opens `Box<String>('leads_v1')` and stores each `Lead` as a JSON string keyed by id. It uses the same Hive readiness pattern as the Bible feature (box-open wrapped in try/catch, `_boxReady` flag, degrades to in-memory-only on failure). `Lead.fromMap` is tolerant of missing/malformed fields.

**How to apply:** If the user later asks for leads to sync across devices, that requires a NEW backend endpoint (needs Railway access) — the on-device store would then become a cache/offline layer, not the source of truth. Don't silently switch storage; it's a data-migration decision the user must approve.

## Lead photos: store the FILE NAME only, never the absolute path
Lead photos are copied into the app documents dir (`path_provider`) and the model stores just the **file name**; the absolute path is rebuilt at read time from the cached docs-dir path. **Why:** on iOS the app-container path contains a UUID that changes on every install/update, so a persisted absolute path goes stale and the image "disappears." Always reconstruct paths and guard rendering with `File(path).existsSync()` before `FileImage`.

## Per-lead follow-up reminders: persisted deterministic notification ids
One-off local notifications (via NotificationService) let the user be reminded to reach out to a lead. Notification ids are allocated from a **persisted monotonic counter** (base 200000) in SharedPreferences (`lead_reminder_id_map`/`_seq`), NOT `leadId.hashCode`. **Why:** hashCode collides across leads (one reminder cancels another) and isn't a stable-id contract across launches. `cancelAll()` (daily reminders) deliberately does NOT touch lead reminders. Setting a reminder requests notification permission on the spot (a legit explicit opt-in moment) even if the master reminders toggle is off.
