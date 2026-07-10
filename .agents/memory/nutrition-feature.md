---
name: My Nutrition feature
description: Data sources, storage, and the USDA API-key caveat for the calorie-logging feature.
---

# My Nutrition (calorie/food logging)

Local-only feature under `lib/features/nutrition/`. Storage is **Hive only**
(boxes `nutritionEntriesBox` = Box<LoggedEntry> keyed by entry id,
`nutritionGoalsBox` = Box<NutritionGoal> single key "goal",
`foodCacheBox` = Box<String> JSON cache). Exercise is modelled as a LoggedEntry
with `meal == "exercise"` (calories burned), so it reuses FoodItem/LoggedEntry.

## Data sources (free, NO api key)
- **Text search → Open Food Facts** `/cgi/search.pl`. Nutrients parsed **per 100 g**.
- **Barcode → Open Food Facts** `/api/v2/product`, via `mobile_scanner`. Per 100 g.
- Both paths share the `_fromOpenFoodFacts` parser. **Why keyless:** USDA
  FoodData Central needs a per-build API key (DEMO_KEY is rate-limited and the app
  runs on-device, so a Replit secret can't reach it) — dropped it to keep setup
  zero-config for the user. `FoodItem.source` still allows "manual" entries.
- No paid AI / photo recognition (spec constraint).

## v2 retention features (all free, Hive-only)
- **Boxes:** added `weightEntriesBox` (Box<WeightEntry>, keyed by day string
  `YYYY-MM-DD` so one reading/day, re-log overwrites), `foodCombosBox`
  (Box<FoodCombo>, keyed by combo id), `streakDataBox` (Box<StreakData>, single
  key "streak"). typeIds: 17=WeightEntry, 18=FoodCombo, 19=StreakData.
- **Streak** (`streak` Rx) is **recomputed from the entry-day set on every
  `_refresh()`** — both current and longest are pure functions of current data
  (NOT sticky; a delete can lower them). Current counts consecutive days ending
  at the most-recent logged day only if that day is today or yesterday (1-day
  grace). **Why data-driven:** avoids stale/duplicate streak state across
  deletes/backfills; don't reintroduce a `max(computed, stored)` on longest.
- **Repeat Yesterday / Repeat [meal]:** `repeatDay()`/`repeatMeal()` copy the
  prior day (relative to `selectedDate`) via `addFood`. Always go through the
  review sheet `NutritionSheets.confirmRepeat(c, mealLabel?)` — spec requires a
  reviewable, no-silent-duplicate confirm before committing.
- **Quick Add** is the FIRST tab in FoodEntryScreen (TabController length 5),
  built inline in the screen (`source:'quickadd'`), NOT a sheet. Name+calories
  required, macros optional.
- **Combos** surface in the My Foods tab: "Save as combo" (multi-select ≥2 of
  myFoods) + one-tap `logCombo` to the current meal.
- **Weight tracking** (`WeightTrackingScreen`) uses **syncfusion_flutter_charts**
  (already a dep — `SfCartesianChart`/`DateTimeAxis`) for the line + dashed
  goal-pacing projection line; status text is computed from a least-squares
  weekly trend vs goal (ahead / on-track / behind / holding-steady). Pure math.
- **Goal Setup** (`GoalSetupScreen`) → `NutritionGoal.computeBudget` (Mifflin-St
  Jeor BMR × activity + weeklyRate×3500/7, clamped 1200–6000). Personalization
  fields live IN `NutritionGoal` (fields 4–11), so **the manual `editGoal` sheet
  must use `copyWith` on the current goal** — building a fresh `NutritionGoal`
  there wipes goal/current weight + pacing metadata (regression fixed once).
- `NutritionGoal.isPersonalized` = current & goal weight both set; drives the
  dashboard first-run "Personalize" banner.
