---
name: Cloud backup of local Hive data
description: How device-local Hive data is backed up/restored via Firestore, and the Firestore rules constraints that gate chat edits and backups.
---

# Cloud backup (reinstall-proof local data)

`lib/core/backup/cloud_backup_service.dart` mirrors every user-content Hive box to Firestore `user_backups/{railwayUserId}/boxes/{boxName}` (`{data: jsonString, count, updatedAt}`), keyed by the STABLE Railway user id (NOT the anonymous Firebase uid, which changes per install).

Rules that must hold when touching it:
- **Open typing must match the owning controller exactly** (`Box<Goal>` vs `Box<dynamic>` mismatch throws). Box names come from the real `kXxxBox` constants — several differ from intuition (`budget_v1` not budget_store, `priming_streak`, camelCase nutrition boxes).
- **Restore only into an EMPTY box; local always wins.** Restore is time-boxed (~15s) with an `_restoreAbandoned` flag checked before every `putAll` — a timed-out pass must never write stale cloud data into boxes the user started using. Re-check `box.isNotEmpty` right before `putAll`.
- Backup skips any box whose JSON exceeds ~900KB (Firestore 1MB doc cap) — logged, not chunked.
- New Hive boxes holding user content MUST be added to the service registry (with toJson/fromJson on their models, ISO-8601 dates) or they silently won't survive reinstall. Mission stats live in SharedPreferences, not Hive — currently NOT backed up.
- Wire-up points: `main.dart` (restore+start when a userId already exists) and `login_controller._routeAfterLogin` (fresh-reinstall login).

## Firestore rules gotchas
- Chat message edits are allowed ONLY as key-constrained updates: `affectedKeys().hasOnly(['text','isEdited','editedAt'])`. Adding any new editable message field requires a rules change or edits silently fail.
- Whole DB is "any authed user" posture because auth is anonymous (Firebase uid ≠ app user id). Per-user isolation (incl. `user_backups` cross-account reads) needs custom-token auth minted by the Railway backend — known accepted tradeoff, flagged to user.
- `FieldValue.serverTimestamp()` is illegal inside `arrayUnion` elements (story comments use `Timestamp.now()`); per-key map writes use dot-path `update({'reactions.$uid': emoji})`.
