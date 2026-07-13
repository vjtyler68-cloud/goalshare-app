---
name: My Goals feature
description: The Goals tab is a local-first Hive feature, fully decoupled from the Mission backend. Includes the GetX nested-Obx reactivity gotcha that bit it.
---

# My Goals tab

The Goals bottom tab (`lib/features/goals/`) is **local-first Hive**, NOT backed by the Mission `/goals` API. It was rebuilt this way because the shared Mission backend was unreliable (goals silently failed to save) and the mission-centric "Create New Mission" dialog was the wrong UX for goals.

- Hive model `Goal` typeId **20** (11–19 already used; see hive-adapters.md), box `goals_box`, hand-written `goal.g.dart` (no local build_runner). Fields: id,title,timeframe(Daily/Weekly/Monthly/Yearly),target,progress,createdAt,completedAt?,emoji. `copyWith` uses a private `_undefined` sentinel so `completedAt` can be explicitly set to null.
- `GoalsController` (registered fenix in AppBindings) opens the box in onInit; writes `await _ensureReady()` (an `_initFuture ??= _init()`) so a save fired before init finishes waits instead of silently no-op'ing.
- The tab is decoupled from `MissionController` entirely. The **Mission tab still uses `CreateNewMission`** — do not delete that dialog; the nav-bar FAB routes to `GoalCreateSheet` only when `selectedIndex == 2` (Goals), else `CreateNewMission`.
- "Addicting" mechanics: tap card = +1 progress (haptic), animated progress bar, confetti (`assets/jsons/confetti.json` via Lottie in an Overlay+IgnorePointer) on completion; long-press card = edit/undo/complete/delete sheet.

## GetX reactivity gotcha (cost a review cycle)
An `Obx` only tracks `.obs` reads that happen **synchronously inside its own builder closure**. Reading a reactive value inside a *child widget's* build method (even one constructed within the Obx builder) is NOT tracked by the parent Obx — the child's build runs later, outside the tracking zone.

**Why:** the first Goals build wrapped the whole screen in one `Obx(() => ...)` that only read `isReady.value`; the header/section child widgets read `goals`-derived getters in their own builds, so mutations to `goals` never rebuilt anything.

**How to apply:** put an `Obx` in each widget that actually reads the reactive state (header has its own Obx, each section has its own Obx), or ensure the tracking Obx reads the Rx directly. Also key list items (`ValueKey(id)`) when the list re-sorts, so stateful children/animations follow the right item.
