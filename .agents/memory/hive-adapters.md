---
name: Hive adapters & typeId registry
description: How to add Hive-backed features when Flutter/build_runner is unavailable locally, and the current typeId allocation.
---

# Hive adapters when Flutter isn't installed locally

Flutter/Dart/build_runner are NOT installed in this repl, so `.g.dart` TypeAdapter
files cannot be generated. **Hand-write the `.g.dart` adapter** mirroring the
existing generator output (see any existing `*.g.dart` under
`lib/features/home/subflow/todo/data/` for the exact shape: `read` maps fields
by index, `write` does `writeByte(fieldCount)` then paired `writeByte(i)/write`).
Getting the field count or index mapping wrong corrupts stored data silently.

**Why:** the app is only compiled by Codemagic CI; there's no local analyze/compile,
so a wrong adapter isn't caught until a cloud build (or worse, runtime).

**How to apply:** for a new `@HiveType`, hand-author the matching adapter, register
it guarded (`if (!Hive.isAdapterRegistered(id)) Hive.registerAdapter(...)`), and
open the box lazily in the controller's `onInit` (mirrors leads/todo/journal).

## typeId registry (avoid collisions — this app has hit a build error from a dup)
- 11 = TodoItem
- 12 = DailyTodos
- 13 = JournalEntry (Gratitude Journal — one entry per day, id = "YYYY-MM-DD")
- 14 = FoodItem (My Nutrition; nested inside LoggedEntry)
- 15 = LoggedEntry (My Nutrition; one logged food/exercise, keyed by own id)
- 16 = NutritionGoal (My Nutrition; single record, key "goal"; fields 0–11 incl. personalization)
- 17 = WeightEntry (My Nutrition v2; keyed by day string "YYYY-MM-DD")
- 18 = FoodCombo (My Nutrition v2; nested List<FoodItem>, keyed by combo id)
- 19 = StreakData (My Nutrition v2; single record, key "streak")
- **Next free: 20+**

## Controller readiness matters
Box open is async. Gate reads/writes on an `isReady` RxBool: don't prefill from
`entryFor()` before ready (use an `ever(isReady)` worker), and have `save`/`delete`
return `Future<bool>` (false when box null) so the UI never shows false success.
