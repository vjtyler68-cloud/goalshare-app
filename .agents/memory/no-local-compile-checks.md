---
name: No local compile — grep before delete
description: How to avoid shipping build breaks when Flutter can't be run locally
---
Rule: before deleting or renaming any file/folder/class, `grep -rn` the whole `lib/` for every identifier and import path it exposes; there is no local compiler to catch dangling references.

**Why:** Deleting the Following/Followers feature broke Codemagic build (QR Connect screen still imported its controller) — cost the user a wasted iOS build.

**How to apply:** After removals, grep for the old import path AND every public class name. Also check for user-facing wording tied to the removed concept (e.g. "follow" → "friend").
