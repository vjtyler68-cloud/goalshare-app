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

## Data sources (free tier only)
- **Text search → USDA FoodData Central.** Nutrients parsed **per 100 g**.
- **Barcode → Open Food Facts** (no key), via `mobile_scanner`. Also per 100 g.
- No paid AI / photo recognition (spec constraint), but `FoodItem.source` is kept
  open ("usda"|"openfoodfacts"|"manual") for future sources.

## USDA API key caveat (needs user action)
`FoodApiService.usdaApiKey` defaults to `'DEMO_KEY'` — heavily rate-limited
(a few req/hour). **Why:** the app runs on-device so a Replit secret can't reach
it; the key must be baked into the build. **How to apply:** get a free key at
fdc.nal.usda.gov/api-key-signup.html and replace the constant (or wire a
`--dart-define`). Barcode scanning works with no key regardless.
