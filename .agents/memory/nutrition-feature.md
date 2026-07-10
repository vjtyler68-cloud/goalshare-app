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
