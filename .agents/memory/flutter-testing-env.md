---
name: Running flutter test in this environment
description: Flutter is not preinstalled anywhere usable; match the SDK to pubspec.lock's floor and keep the lockfile pristine.
---

# Running `flutter test` in this environment

**Rule:** `flutter` is not on PATH and the preinstalled (nix-store) Flutter SDKs
are older than the floor recorded in `pubspec.lock` (`sdks:` section), so they
fail dependency resolution. To run tests, download the official stable Flutter
SDK release that satisfies that floor (check `pubspec.lock` for the current
minimum) into a temp dir and put its `bin/` on PATH.

**Why:** the project tracks a newer stable channel than the container images;
using an older SDK either fails `pub get` outright or silently downgrades pins.

**How to apply:**
- After `flutter pub get` with any SDK, run `git checkout -- pubspec.lock` —
  pub rewrites the lockfile to match the local SDK and that churn must not be
  committed.
- `flutter test` progress output uses carriage returns; redirect to a file (or
  `tr '\r' '\n'`) or the shell tool shows only "...".
- Temp-dir SDKs don't survive the session; re-fetch when needed.

**Controller unit-test pattern:** `MyBudgetController` accepts an injected
`BudgetStore`; tests subclass it with an in-memory fake and use
`Get.testMode = true; Get.put(controller)` to fire `onInit` — no Hive box, so
plain `flutter test` is CI-safe.
