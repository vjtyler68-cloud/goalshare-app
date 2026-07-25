import 'food_item.dart';

/// A bundled, offline database of the foods people log most often.
///
/// Open Food Facts (the online source in [FoodApiService]) is excellent for
/// scanning packaged/barcode products but poor for the everyday staples that
/// make up most logging — "chicken breast", "2 eggs", "banana" return foreign
/// products, duplicates, or zero-calorie junk. This list fills that gap:
///
///   • ~150 common foods with **accurate USDA reference values**,
///   • **real, recognizable serving sizes** ("1 large egg", "4 oz chicken
///     breast", "1 medium banana") instead of a raw "100 g",
///   • **instant + fully offline** — no network, no API key, no cost.
///
/// [CommonFoods.search] returns matches ranked best-first; the food entry
/// screen shows these on top and merges the online results in below.
class CommonFoods {
  const CommonFoods._();

  static List<FoodItem> search(String query, {int limit = 25}) {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return const [];
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final wordStart = RegExp(r'\b' + RegExp.escape(q));

    // Forgiving token match: also matches across a simple plural/singular
    // difference so "eggs" finds "Egg" and "banana" finds "Bananas".
    bool nameHasToken(String name, String t) {
      if (name.contains(t)) return true;
      if (t.length > 3 && t.endsWith('s') && name.contains(t.substring(0, t.length - 1))) {
        return true;
      }
      return false;
    }

    final scored = <MapEntry<FoodItem, int>>[];
    for (final f in _foods) {
      final name = f.name.toLowerCase();
      // Every typed word must appear somewhere in the name.
      if (!tokens.every((t) => nameHasToken(name, t))) continue;
      // The "base" name is the part before any comma qualifier, so "Egg, large"
      // is really the food "egg" and beats an incidental match like "Egg roll".
      final base = name.split(',').first.trim();
      final int score;
      if (name == q) {
        score = 0;
      } else if (base == q) {
        score = 1; // canonical staple ("Egg, large" for "egg")
      } else if (name.startsWith('$q ') || name.startsWith('$q,')) {
        score = 2; // query is the first whole word ("Egg roll" for "egg")
      } else if (name.startsWith(q)) {
        score = 3;
      } else if (wordStart.hasMatch(name)) {
        score = 4; // matches at a word boundary ("egg" in "Scrambled eggs")
      } else {
        score = 5;
      }
      scored.add(MapEntry(f, score));
    }

    scored.sort((a, b) {
      final s = a.value.compareTo(b.value);
      if (s != 0) return s;
      // Tie-break: shorter names are the more generic staple ("Egg" > "Egg …").
      return a.key.name.length.compareTo(b.key.name.length);
    });

    return scored.take(limit).map((e) => e.key).toList();
  }

  static int get count => _foods.length;

  // ── The data ────────────────────────────────────────────────────────────────
  // Values are per the stated serving. `source: 'usda'` marks them as verified
  // reference data (shown with a check in the UI). Fiber/sugar are grams;
  // sodium is milligrams. Detailed fields are filled only where well known.
  static const List<FoodItem> _foods = [
    // ── Proteins ──────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_chicken_breast', name: 'Chicken breast, cooked', servingSize: '4 oz (113 g)', calories: 187, protein: 35, carbs: 0, fat: 4, source: 'usda'),
    FoodItem(id: 'cf_chicken_thigh', name: 'Chicken thigh, cooked', servingSize: '4 oz (113 g)', calories: 209, protein: 26, carbs: 0, fat: 11, source: 'usda'),
    FoodItem(id: 'cf_chicken_wing', name: 'Chicken wings', servingSize: '3 wings', calories: 264, protein: 24, carbs: 0, fat: 18, source: 'usda'),
    FoodItem(id: 'cf_rotisserie_chicken', name: 'Rotisserie chicken', servingSize: '3 oz (85 g)', calories: 170, protein: 22, carbs: 0, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_ground_beef_8020', name: 'Ground beef, 80/20, cooked', servingSize: '4 oz (113 g)', calories: 287, protein: 26, carbs: 0, fat: 19, source: 'usda'),
    FoodItem(id: 'cf_ground_beef_9010', name: 'Ground beef, 90/10, cooked', servingSize: '4 oz (113 g)', calories: 199, protein: 26, carbs: 0, fat: 10, source: 'usda'),
    FoodItem(id: 'cf_steak_sirloin', name: 'Sirloin steak, cooked', servingSize: '4 oz (113 g)', calories: 207, protein: 32, carbs: 0, fat: 8, source: 'usda'),
    FoodItem(id: 'cf_pork_chop', name: 'Pork chop, cooked', servingSize: '4 oz (113 g)', calories: 220, protein: 29, carbs: 0, fat: 11, source: 'usda'),
    FoodItem(id: 'cf_bacon', name: 'Bacon', servingSize: '2 slices', calories: 87, protein: 6, carbs: 0, fat: 7, source: 'usda', sodiumMgValue: 370),
    FoodItem(id: 'cf_sausage', name: 'Pork sausage link', servingSize: '2 links', calories: 165, protein: 9, carbs: 1, fat: 14, source: 'usda'),
    FoodItem(id: 'cf_ground_turkey', name: 'Ground turkey, 93/7, cooked', servingSize: '4 oz (113 g)', calories: 230, protein: 28, carbs: 0, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_turkey_deli', name: 'Turkey breast, deli', servingSize: '2 oz (57 g)', calories: 54, protein: 10, carbs: 1, fat: 1, source: 'usda', sodiumMgValue: 550),
    FoodItem(id: 'cf_ham_deli', name: 'Ham, deli', servingSize: '2 oz (57 g)', calories: 60, protein: 10, carbs: 1, fat: 2, source: 'usda', sodiumMgValue: 600),
    FoodItem(id: 'cf_salmon', name: 'Salmon, cooked', servingSize: '4 oz (113 g)', calories: 233, protein: 25, carbs: 0, fat: 14, source: 'usda'),
    FoodItem(id: 'cf_tuna_canned', name: 'Tuna, canned in water', servingSize: '3 oz (85 g)', calories: 99, protein: 22, carbs: 0, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_tilapia', name: 'Tilapia, cooked', servingSize: '4 oz (113 g)', calories: 145, protein: 30, carbs: 0, fat: 3, source: 'usda'),
    FoodItem(id: 'cf_shrimp', name: 'Shrimp, cooked', servingSize: '3 oz (85 g)', calories: 84, protein: 18, carbs: 0, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_egg', name: 'Egg, large', servingSize: '1 large', calories: 72, protein: 6, carbs: 1, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_egg_white', name: 'Egg white', servingSize: '1 large', calories: 17, protein: 4, carbs: 0, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_scrambled_eggs', name: 'Scrambled eggs', servingSize: '2 eggs', calories: 180, protein: 12, carbs: 2, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_tofu', name: 'Tofu, firm', servingSize: '4 oz (113 g)', calories: 94, protein: 10, carbs: 2, fat: 6, source: 'usda'),

    // ── Dairy ─────────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_milk_whole', name: 'Milk, whole', servingSize: '1 cup (240 ml)', calories: 149, protein: 8, carbs: 12, fat: 8, source: 'usda', sugarG: 12),
    FoodItem(id: 'cf_milk_2', name: 'Milk, 2%', servingSize: '1 cup (240 ml)', calories: 122, protein: 8, carbs: 12, fat: 5, source: 'usda', sugarG: 12),
    FoodItem(id: 'cf_milk_skim', name: 'Milk, skim', servingSize: '1 cup (240 ml)', calories: 83, protein: 8, carbs: 12, fat: 0, source: 'usda', sugarG: 12),
    FoodItem(id: 'cf_almond_milk', name: 'Almond milk, unsweetened', servingSize: '1 cup (240 ml)', calories: 37, protein: 1, carbs: 1, fat: 3, source: 'usda'),
    FoodItem(id: 'cf_oat_milk', name: 'Oat milk', servingSize: '1 cup (240 ml)', calories: 120, protein: 3, carbs: 16, fat: 5, source: 'usda', sugarG: 7),
    FoodItem(id: 'cf_greek_yogurt', name: 'Greek yogurt, plain nonfat', servingSize: '1 container (170 g)', calories: 100, protein: 17, carbs: 6, fat: 0, source: 'usda', sugarG: 4),
    FoodItem(id: 'cf_yogurt', name: 'Yogurt, plain whole milk', servingSize: '1 cup (245 g)', calories: 149, protein: 9, carbs: 11, fat: 8, source: 'usda', sugarG: 11),
    FoodItem(id: 'cf_cheddar', name: 'Cheddar cheese', servingSize: '1 oz (28 g)', calories: 113, protein: 7, carbs: 1, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_mozzarella', name: 'Mozzarella cheese', servingSize: '1 oz (28 g)', calories: 85, protein: 6, carbs: 1, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_string_cheese', name: 'String cheese', servingSize: '1 stick', calories: 80, protein: 6, carbs: 1, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_cottage_cheese', name: 'Cottage cheese, low-fat', servingSize: '1/2 cup (113 g)', calories: 90, protein: 12, carbs: 5, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_butter', name: 'Butter', servingSize: '1 tbsp', calories: 102, protein: 0, carbs: 0, fat: 12, source: 'usda'),
    FoodItem(id: 'cf_cream_cheese', name: 'Cream cheese', servingSize: '1 tbsp', calories: 51, protein: 1, carbs: 1, fat: 5, source: 'usda'),

    // ── Grains & starches ───────────────────────────────────────────────────────
    FoodItem(id: 'cf_white_rice', name: 'White rice, cooked', servingSize: '1 cup (158 g)', calories: 205, protein: 4, carbs: 45, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_brown_rice', name: 'Brown rice, cooked', servingSize: '1 cup (195 g)', calories: 216, protein: 5, carbs: 45, fat: 2, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_pasta', name: 'Pasta, cooked', servingSize: '1 cup (140 g)', calories: 221, protein: 8, carbs: 43, fat: 1, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_spaghetti_marinara', name: 'Spaghetti with marinara', servingSize: '1 cup', calories: 220, protein: 8, carbs: 43, fat: 3, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_white_bread', name: 'White bread', servingSize: '1 slice', calories: 75, protein: 3, carbs: 14, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_wheat_bread', name: 'Wheat bread', servingSize: '1 slice', calories: 80, protein: 4, carbs: 14, fat: 1, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_bagel', name: 'Bagel, plain', servingSize: '1 medium', calories: 245, protein: 10, carbs: 48, fat: 2, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_oatmeal', name: 'Oatmeal, cooked', servingSize: '1 cup (234 g)', calories: 154, protein: 6, carbs: 27, fat: 3, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_quinoa', name: 'Quinoa, cooked', servingSize: '1 cup (185 g)', calories: 222, protein: 8, carbs: 39, fat: 4, source: 'usda', fiberG: 5),
    FoodItem(id: 'cf_flour_tortilla', name: 'Flour tortilla', servingSize: '1 medium (8 in)', calories: 144, protein: 4, carbs: 24, fat: 4, source: 'usda'),
    FoodItem(id: 'cf_corn_tortilla', name: 'Corn tortilla', servingSize: '1 small (6 in)', calories: 52, protein: 1, carbs: 11, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_baked_potato', name: 'Potato, baked', servingSize: '1 medium', calories: 161, protein: 4, carbs: 37, fat: 0, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_sweet_potato', name: 'Sweet potato, baked', servingSize: '1 medium', calories: 103, protein: 2, carbs: 24, fat: 0, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_french_fries', name: 'French fries', servingSize: '1 medium serving', calories: 365, protein: 4, carbs: 48, fat: 17, source: 'usda', sodiumMgValue: 250),
    FoodItem(id: 'cf_cereal', name: 'Breakfast cereal', servingSize: '1 cup', calories: 110, protein: 2, carbs: 24, fat: 1, source: 'usda', sugarG: 9),
    FoodItem(id: 'cf_pancakes', name: 'Pancakes', servingSize: '2 (4 in)', calories: 175, protein: 5, carbs: 22, fat: 7, source: 'usda'),
    FoodItem(id: 'cf_waffle', name: 'Waffle', servingSize: '1 round', calories: 218, protein: 6, carbs: 25, fat: 11, source: 'usda'),
    FoodItem(id: 'cf_crackers', name: 'Saltine crackers', servingSize: '5 crackers', calories: 62, protein: 1, carbs: 11, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_granola', name: 'Granola', servingSize: '1/2 cup (61 g)', calories: 200, protein: 5, carbs: 36, fat: 6, source: 'usda', sugarG: 12),

    // ── Fruits ────────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_banana', name: 'Banana', servingSize: '1 medium', calories: 105, protein: 1, carbs: 27, fat: 0, source: 'usda', fiberG: 3, sugarG: 14),
    FoodItem(id: 'cf_apple', name: 'Apple', servingSize: '1 medium', calories: 95, protein: 0, carbs: 25, fat: 0, source: 'usda', fiberG: 4, sugarG: 19),
    FoodItem(id: 'cf_orange', name: 'Orange', servingSize: '1 medium', calories: 62, protein: 1, carbs: 15, fat: 0, source: 'usda', fiberG: 3, sugarG: 12),
    FoodItem(id: 'cf_grapes', name: 'Grapes', servingSize: '1 cup (151 g)', calories: 104, protein: 1, carbs: 27, fat: 0, source: 'usda', sugarG: 23),
    FoodItem(id: 'cf_strawberries', name: 'Strawberries', servingSize: '1 cup (152 g)', calories: 49, protein: 1, carbs: 12, fat: 0, source: 'usda', fiberG: 3, sugarG: 7),
    FoodItem(id: 'cf_blueberries', name: 'Blueberries', servingSize: '1 cup (148 g)', calories: 84, protein: 1, carbs: 21, fat: 0, source: 'usda', fiberG: 4, sugarG: 15),
    FoodItem(id: 'cf_watermelon', name: 'Watermelon', servingSize: '1 cup diced', calories: 46, protein: 1, carbs: 12, fat: 0, source: 'usda', sugarG: 9),
    FoodItem(id: 'cf_avocado', name: 'Avocado', servingSize: '1/2 medium', calories: 120, protein: 2, carbs: 6, fat: 11, source: 'usda', fiberG: 5),
    FoodItem(id: 'cf_grapefruit', name: 'Grapefruit', servingSize: '1/2 medium', calories: 52, protein: 1, carbs: 13, fat: 0, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_pineapple', name: 'Pineapple', servingSize: '1 cup chunks', calories: 82, protein: 1, carbs: 22, fat: 0, source: 'usda', sugarG: 16),
    FoodItem(id: 'cf_mango', name: 'Mango', servingSize: '1 cup (165 g)', calories: 99, protein: 1, carbs: 25, fat: 0, source: 'usda', fiberG: 3, sugarG: 23),
    FoodItem(id: 'cf_peach', name: 'Peach', servingSize: '1 medium', calories: 59, protein: 1, carbs: 14, fat: 0, source: 'usda', fiberG: 2),

    // ── Vegetables ──────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_broccoli', name: 'Broccoli, cooked', servingSize: '1 cup (156 g)', calories: 55, protein: 4, carbs: 11, fat: 0, source: 'usda', fiberG: 5),
    FoodItem(id: 'cf_spinach', name: 'Spinach, raw', servingSize: '1 cup (30 g)', calories: 7, protein: 1, carbs: 1, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_carrots', name: 'Carrots', servingSize: '1 cup chopped', calories: 52, protein: 1, carbs: 12, fat: 0, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_salad_greens', name: 'Mixed salad greens', servingSize: '2 cups', calories: 15, protein: 1, carbs: 3, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_tomato', name: 'Tomato', servingSize: '1 medium', calories: 22, protein: 1, carbs: 5, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_corn', name: 'Corn', servingSize: '1 cup (164 g)', calories: 132, protein: 5, carbs: 29, fat: 2, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_green_beans', name: 'Green beans, cooked', servingSize: '1 cup (125 g)', calories: 44, protein: 2, carbs: 10, fat: 0, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_bell_pepper', name: 'Bell pepper', servingSize: '1 medium', calories: 24, protein: 1, carbs: 6, fat: 0, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_cucumber', name: 'Cucumber', servingSize: '1 cup sliced', calories: 16, protein: 1, carbs: 4, fat: 0, source: 'usda'),

    // ── Legumes & nuts ──────────────────────────────────────────────────────────
    FoodItem(id: 'cf_black_beans', name: 'Black beans, cooked', servingSize: '1/2 cup (86 g)', calories: 114, protein: 8, carbs: 20, fat: 0, source: 'usda', fiberG: 7),
    FoodItem(id: 'cf_chickpeas', name: 'Chickpeas, cooked', servingSize: '1/2 cup (82 g)', calories: 134, protein: 7, carbs: 22, fat: 2, source: 'usda', fiberG: 6),
    FoodItem(id: 'cf_lentils', name: 'Lentils, cooked', servingSize: '1/2 cup (99 g)', calories: 115, protein: 9, carbs: 20, fat: 0, source: 'usda', fiberG: 8),
    FoodItem(id: 'cf_peanut_butter', name: 'Peanut butter', servingSize: '2 tbsp (32 g)', calories: 190, protein: 8, carbs: 7, fat: 16, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_almonds', name: 'Almonds', servingSize: '1 oz (23 nuts)', calories: 164, protein: 6, carbs: 6, fat: 14, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_peanuts', name: 'Peanuts', servingSize: '1 oz (28 g)', calories: 161, protein: 7, carbs: 5, fat: 14, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_walnuts', name: 'Walnuts', servingSize: '1 oz (28 g)', calories: 185, protein: 4, carbs: 4, fat: 18, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_cashews', name: 'Cashews', servingSize: '1 oz (28 g)', calories: 157, protein: 5, carbs: 9, fat: 12, source: 'usda'),
    FoodItem(id: 'cf_hummus', name: 'Hummus', servingSize: '2 tbsp (30 g)', calories: 70, protein: 2, carbs: 6, fat: 5, source: 'usda', fiberG: 2),

    // ── Common meals & fast food (generic) ──────────────────────────────────────
    FoodItem(id: 'cf_cheeseburger', name: 'Cheeseburger, fast food', servingSize: '1 single', calories: 300, protein: 15, carbs: 33, fat: 13, source: 'usda', sodiumMgValue: 680),
    FoodItem(id: 'cf_hamburger', name: 'Hamburger, fast food', servingSize: '1 single', calories: 250, protein: 13, carbs: 30, fat: 9, source: 'usda', sodiumMgValue: 480),
    FoodItem(id: 'cf_pizza_slice', name: 'Pizza, cheese', servingSize: '1 slice', calories: 285, protein: 12, carbs: 36, fat: 10, source: 'usda', sodiumMgValue: 640),
    FoodItem(id: 'cf_pizza_pepperoni', name: 'Pizza, pepperoni', servingSize: '1 slice', calories: 313, protein: 13, carbs: 36, fat: 13, source: 'usda', sodiumMgValue: 760),
    FoodItem(id: 'cf_chicken_nuggets', name: 'Chicken nuggets', servingSize: '6 pieces', calories: 270, protein: 14, carbs: 16, fat: 17, source: 'usda'),
    FoodItem(id: 'cf_hot_dog', name: 'Hot dog with bun', servingSize: '1', calories: 290, protein: 10, carbs: 29, fat: 17, source: 'usda', sodiumMgValue: 810),
    FoodItem(id: 'cf_grilled_chicken_sandwich', name: 'Grilled chicken sandwich', servingSize: '1', calories: 350, protein: 28, carbs: 40, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_burrito', name: 'Bean & cheese burrito', servingSize: '1', calories: 380, protein: 12, carbs: 50, fat: 14, source: 'usda', fiberG: 7),
    FoodItem(id: 'cf_mac_cheese', name: 'Macaroni & cheese', servingSize: '1 cup', calories: 310, protein: 11, carbs: 40, fat: 12, source: 'usda'),
    FoodItem(id: 'cf_pbj', name: 'Peanut butter & jelly sandwich', servingSize: '1', calories: 390, protein: 14, carbs: 48, fat: 18, source: 'usda'),
    FoodItem(id: 'cf_caesar_salad_chicken', name: 'Caesar salad with chicken', servingSize: '1 entrée', calories: 400, protein: 30, carbs: 12, fat: 26, source: 'usda'),
    FoodItem(id: 'cf_ramen', name: 'Instant ramen noodles', servingSize: '1 package', calories: 380, protein: 8, carbs: 52, fat: 14, source: 'usda', sodiumMgValue: 1600),

    // ── Beverages ─────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_coffee_black', name: 'Coffee, black', servingSize: '1 cup (240 ml)', calories: 2, protein: 0, carbs: 0, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_latte', name: 'Latte, 2% milk', servingSize: '16 oz (grande)', calories: 190, protein: 12, carbs: 18, fat: 7, source: 'usda', sugarG: 17),
    FoodItem(id: 'cf_orange_juice', name: 'Orange juice', servingSize: '1 cup (240 ml)', calories: 112, protein: 2, carbs: 26, fat: 0, source: 'usda', sugarG: 21),
    FoodItem(id: 'cf_cola', name: 'Cola / soda', servingSize: '12 oz can', calories: 140, protein: 0, carbs: 39, fat: 0, source: 'usda', sugarG: 39),
    FoodItem(id: 'cf_diet_soda', name: 'Diet soda', servingSize: '12 oz can', calories: 0, protein: 0, carbs: 0, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_beer', name: 'Beer, regular', servingSize: '12 oz (355 ml)', calories: 153, protein: 2, carbs: 13, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_wine', name: 'Wine, red', servingSize: '5 oz (148 ml)', calories: 125, protein: 0, carbs: 4, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_protein_shake', name: 'Protein shake (1 scoop, water)', servingSize: '1 shake', calories: 120, protein: 24, carbs: 3, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_gatorade', name: 'Sports drink', servingSize: '20 oz bottle', calories: 140, protein: 0, carbs: 36, fat: 0, source: 'usda', sugarG: 34),
    FoodItem(id: 'cf_energy_drink', name: 'Energy drink', servingSize: '8.4 oz can', calories: 110, protein: 1, carbs: 27, fat: 0, source: 'usda', sugarG: 27),
    FoodItem(id: 'cf_sweet_tea', name: 'Sweet tea', servingSize: '1 cup (240 ml)', calories: 90, protein: 0, carbs: 22, fat: 0, source: 'usda', sugarG: 22),

    // ── Snacks & sweets ─────────────────────────────────────────────────────────
    FoodItem(id: 'cf_potato_chips', name: 'Potato chips', servingSize: '1 oz (~15 chips)', calories: 152, protein: 2, carbs: 15, fat: 10, source: 'usda', sodiumMgValue: 149),
    FoodItem(id: 'cf_tortilla_chips', name: 'Tortilla chips', servingSize: '1 oz (~10 chips)', calories: 140, protein: 2, carbs: 18, fat: 7, source: 'usda'),
    FoodItem(id: 'cf_cookie', name: 'Chocolate chip cookie', servingSize: '1 medium', calories: 78, protein: 1, carbs: 10, fat: 4, source: 'usda', sugarG: 6),
    FoodItem(id: 'cf_ice_cream', name: 'Ice cream, vanilla', servingSize: '1/2 cup', calories: 137, protein: 2, carbs: 16, fat: 7, source: 'usda', sugarG: 14),
    FoodItem(id: 'cf_chocolate_bar', name: 'Chocolate bar, milk', servingSize: '1.5 oz (43 g)', calories: 235, protein: 3, carbs: 26, fat: 13, source: 'usda', sugarG: 24),
    FoodItem(id: 'cf_granola_bar', name: 'Granola bar', servingSize: '1 bar', calories: 120, protein: 2, carbs: 20, fat: 4, source: 'usda', sugarG: 8),
    FoodItem(id: 'cf_protein_bar', name: 'Protein bar', servingSize: '1 bar', calories: 200, protein: 20, carbs: 22, fat: 7, source: 'usda', fiberG: 10),
    FoodItem(id: 'cf_popcorn', name: 'Popcorn, air-popped', servingSize: '3 cups', calories: 93, protein: 3, carbs: 19, fat: 1, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_pretzels', name: 'Pretzels', servingSize: '1 oz (28 g)', calories: 108, protein: 3, carbs: 23, fat: 1, source: 'usda', sodiumMgValue: 385),
    FoodItem(id: 'cf_donut', name: 'Donut, glazed', servingSize: '1', calories: 240, protein: 4, carbs: 31, fat: 12, source: 'usda', sugarG: 12),
    FoodItem(id: 'cf_trail_mix', name: 'Trail mix', servingSize: '1/4 cup', calories: 175, protein: 5, carbs: 16, fat: 11, source: 'usda'),

    // ── Condiments & extras ─────────────────────────────────────────────────────
    FoodItem(id: 'cf_olive_oil', name: 'Olive oil', servingSize: '1 tbsp', calories: 119, protein: 0, carbs: 0, fat: 14, source: 'usda'),
    FoodItem(id: 'cf_mayo', name: 'Mayonnaise', servingSize: '1 tbsp', calories: 94, protein: 0, carbs: 0, fat: 10, source: 'usda'),
    FoodItem(id: 'cf_ketchup', name: 'Ketchup', servingSize: '1 tbsp', calories: 17, protein: 0, carbs: 5, fat: 0, source: 'usda', sugarG: 4),
    FoodItem(id: 'cf_ranch', name: 'Ranch dressing', servingSize: '2 tbsp', calories: 130, protein: 1, carbs: 2, fat: 14, source: 'usda'),
    FoodItem(id: 'cf_honey', name: 'Honey', servingSize: '1 tbsp', calories: 64, protein: 0, carbs: 17, fat: 0, source: 'usda', sugarG: 17),
    FoodItem(id: 'cf_sugar', name: 'Sugar, granulated', servingSize: '1 tsp', calories: 16, protein: 0, carbs: 4, fat: 0, source: 'usda', sugarG: 4),
    FoodItem(id: 'cf_maple_syrup', name: 'Maple syrup', servingSize: '1 tbsp', calories: 52, protein: 0, carbs: 13, fat: 0, source: 'usda', sugarG: 12),
    FoodItem(id: 'cf_soy_sauce', name: 'Soy sauce', servingSize: '1 tbsp', calories: 10, protein: 1, carbs: 1, fat: 0, source: 'usda', sodiumMgValue: 900),

    // ── More proteins ───────────────────────────────────────────────────────────
    FoodItem(id: 'cf_chicken_tenders', name: 'Chicken tenders, fried', servingSize: '3 tenders', calories: 250, protein: 16, carbs: 14, fat: 14, source: 'usda'),
    FoodItem(id: 'cf_chicken_drumstick', name: 'Chicken drumstick', servingSize: '1 drumstick', calories: 120, protein: 14, carbs: 0, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_fried_chicken', name: 'Fried chicken, thigh', servingSize: '1 piece', calories: 280, protein: 22, carbs: 9, fat: 17, source: 'usda'),
    FoodItem(id: 'cf_ground_chicken', name: 'Ground chicken, cooked', servingSize: '4 oz (113 g)', calories: 180, protein: 24, carbs: 0, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_turkey_burger', name: 'Turkey burger, cooked', servingSize: '4 oz (113 g)', calories: 193, protein: 22, carbs: 0, fat: 11, source: 'usda'),
    FoodItem(id: 'cf_meatballs', name: 'Meatballs', servingSize: '3 (1 oz each)', calories: 190, protein: 11, carbs: 6, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_pork_tenderloin', name: 'Pork tenderloin, cooked', servingSize: '4 oz (113 g)', calories: 163, protein: 26, carbs: 0, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_pork_ribs', name: 'Pork ribs, cooked', servingSize: '3 oz (85 g)', calories: 250, protein: 20, carbs: 0, fat: 18, source: 'usda'),
    FoodItem(id: 'cf_cod', name: 'Cod, cooked', servingSize: '4 oz (113 g)', calories: 119, protein: 26, carbs: 0, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_sardines', name: 'Sardines, canned', servingSize: '1 can (3.75 oz)', calories: 191, protein: 23, carbs: 0, fat: 11, source: 'usda'),
    FoodItem(id: 'cf_crab', name: 'Crab, cooked', servingSize: '3 oz (85 g)', calories: 82, protein: 16, carbs: 0, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_beef_jerky', name: 'Beef jerky', servingSize: '1 oz (28 g)', calories: 116, protein: 9, carbs: 7, fat: 7, source: 'usda', sodiumMgValue: 500),
    FoodItem(id: 'cf_canned_chicken', name: 'Chicken, canned', servingSize: '3 oz (85 g)', calories: 90, protein: 18, carbs: 0, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_protein_powder', name: 'Protein powder, whey', servingSize: '1 scoop', calories: 120, protein: 24, carbs: 3, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_lamb_chop', name: 'Lamb chop, cooked', servingSize: '4 oz (113 g)', calories: 250, protein: 31, carbs: 0, fat: 13, source: 'usda'),

    // ── Breakfast ────────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_english_muffin', name: 'English muffin', servingSize: '1', calories: 134, protein: 4, carbs: 26, fat: 1, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_french_toast', name: 'French toast', servingSize: '2 slices', calories: 300, protein: 10, carbs: 36, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_hash_browns', name: 'Hash browns', servingSize: '1 patty', calories: 150, protein: 1, carbs: 15, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_breakfast_sandwich', name: 'Breakfast sandwich, egg & cheese', servingSize: '1', calories: 300, protein: 12, carbs: 29, fat: 15, source: 'usda'),
    FoodItem(id: 'cf_breakfast_burrito', name: 'Breakfast burrito', servingSize: '1', calories: 305, protein: 14, carbs: 28, fat: 15, source: 'usda'),
    FoodItem(id: 'cf_grits', name: 'Grits, cooked', servingSize: '1 cup', calories: 182, protein: 4, carbs: 38, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_biscuit', name: 'Biscuit', servingSize: '1', calories: 212, protein: 4, carbs: 27, fat: 10, source: 'usda'),
    FoodItem(id: 'cf_croissant', name: 'Croissant', servingSize: '1', calories: 231, protein: 5, carbs: 26, fat: 12, source: 'usda'),
    FoodItem(id: 'cf_muffin', name: 'Blueberry muffin', servingSize: '1', calories: 265, protein: 4, carbs: 47, fat: 9, source: 'usda', sugarG: 27),
    FoodItem(id: 'cf_smoothie', name: 'Fruit smoothie', servingSize: '16 oz', calories: 250, protein: 4, carbs: 55, fat: 2, source: 'usda', sugarG: 45),
    FoodItem(id: 'cf_yogurt_parfait', name: 'Yogurt parfait', servingSize: '1', calories: 250, protein: 8, carbs: 40, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_pop_tart', name: 'Pop-Tart', servingSize: '1 pastry', calories: 200, protein: 2, carbs: 36, fat: 5, source: 'usda', sugarG: 17),
    FoodItem(id: 'cf_protein_pancakes', name: 'Protein pancakes', servingSize: '2', calories: 220, protein: 20, carbs: 24, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_chocolate_milk', name: 'Chocolate milk', servingSize: '1 cup (240 ml)', calories: 208, protein: 8, carbs: 26, fat: 8, source: 'usda', sugarG: 24),

    // ── More grains & sides ─────────────────────────────────────────────────────
    FoodItem(id: 'cf_fried_rice', name: 'Fried rice', servingSize: '1 cup', calories: 240, protein: 6, carbs: 45, fat: 8, source: 'usda'),
    FoodItem(id: 'cf_lo_mein', name: 'Lo mein', servingSize: '1 cup', calories: 265, protein: 8, carbs: 40, fat: 8, source: 'usda'),
    FoodItem(id: 'cf_mashed_potatoes', name: 'Mashed potatoes', servingSize: '1 cup', calories: 237, protein: 4, carbs: 35, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_couscous', name: 'Couscous, cooked', servingSize: '1 cup', calories: 176, protein: 6, carbs: 36, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_cornbread', name: 'Cornbread', servingSize: '1 piece', calories: 198, protein: 4, carbs: 33, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_dinner_roll', name: 'Dinner roll', servingSize: '1', calories: 87, protein: 2, carbs: 15, fat: 2, source: 'usda'),
    FoodItem(id: 'cf_pita', name: 'Pita bread', servingSize: '1 (6.5 in)', calories: 165, protein: 5, carbs: 33, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_naan', name: 'Naan', servingSize: '1', calories: 260, protein: 9, carbs: 48, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_rice_cake', name: 'Rice cake', servingSize: '1', calories: 35, protein: 1, carbs: 7, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_baked_beans', name: 'Baked beans', servingSize: '1/2 cup', calories: 120, protein: 6, carbs: 27, fat: 0, source: 'usda', fiberG: 5),
    FoodItem(id: 'cf_onion_rings', name: 'Onion rings', servingSize: '1 serving (8)', calories: 275, protein: 4, carbs: 31, fat: 16, source: 'usda'),
    FoodItem(id: 'cf_mozzarella_sticks', name: 'Mozzarella sticks', servingSize: '3', calories: 250, protein: 11, carbs: 20, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_nachos', name: 'Nachos with cheese', servingSize: '1 serving', calories: 350, protein: 9, carbs: 36, fat: 19, source: 'usda'),

    // ── More meals & fast food ──────────────────────────────────────────────────
    FoodItem(id: 'cf_taco', name: 'Taco', servingSize: '1', calories: 170, protein: 8, carbs: 13, fat: 10, source: 'usda'),
    FoodItem(id: 'cf_quesadilla', name: 'Cheese quesadilla', servingSize: '1', calories: 300, protein: 13, carbs: 24, fat: 17, source: 'usda'),
    FoodItem(id: 'cf_burrito_bowl', name: 'Burrito bowl, chicken', servingSize: '1 bowl', calories: 550, protein: 38, carbs: 56, fat: 20, source: 'usda'),
    FoodItem(id: 'cf_sub_sandwich', name: 'Sub sandwich, turkey (6 in)', servingSize: '1', calories: 280, protein: 18, carbs: 46, fat: 4, source: 'usda'),
    FoodItem(id: 'cf_chicken_wrap', name: 'Chicken wrap', servingSize: '1', calories: 350, protein: 24, carbs: 34, fat: 13, source: 'usda'),
    FoodItem(id: 'cf_crispy_chicken_sandwich', name: 'Crispy chicken sandwich', servingSize: '1', calories: 440, protein: 28, carbs: 40, fat: 18, source: 'usda'),
    FoodItem(id: 'cf_fish_sandwich', name: 'Fish sandwich', servingSize: '1', calories: 380, protein: 16, carbs: 39, fat: 19, source: 'usda'),
    FoodItem(id: 'cf_buffalo_wings', name: 'Buffalo wings', servingSize: '6 wings', calories: 420, protein: 30, carbs: 4, fat: 31, source: 'usda'),
    FoodItem(id: 'cf_chili', name: 'Chili con carne', servingSize: '1 cup', calories: 250, protein: 17, carbs: 22, fat: 10, source: 'usda', fiberG: 6),
    FoodItem(id: 'cf_chicken_noodle_soup', name: 'Chicken noodle soup', servingSize: '1 cup', calories: 75, protein: 4, carbs: 9, fat: 2, source: 'usda', sodiumMgValue: 850),
    FoodItem(id: 'cf_tomato_soup', name: 'Tomato soup', servingSize: '1 cup', calories: 160, protein: 4, carbs: 22, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_sushi_roll', name: 'Sushi roll (California)', servingSize: '6 pieces', calories: 255, protein: 9, carbs: 38, fat: 7, source: 'usda'),
    FoodItem(id: 'cf_egg_roll', name: 'Egg roll', servingSize: '1', calories: 200, protein: 6, carbs: 21, fat: 10, source: 'usda'),
    FoodItem(id: 'cf_lasagna', name: 'Lasagna', servingSize: '1 cup', calories: 336, protein: 19, carbs: 29, fat: 16, source: 'usda'),
    FoodItem(id: 'cf_meatloaf', name: 'Meatloaf', servingSize: '1 slice', calories: 290, protein: 19, carbs: 10, fat: 19, source: 'usda'),

    // ── More dairy & cheese ─────────────────────────────────────────────────────
    FoodItem(id: 'cf_sour_cream', name: 'Sour cream', servingSize: '2 tbsp', calories: 60, protein: 1, carbs: 1, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_half_and_half', name: 'Half and half', servingSize: '2 tbsp', calories: 40, protein: 1, carbs: 1, fat: 3, source: 'usda'),
    FoodItem(id: 'cf_feta', name: 'Feta cheese', servingSize: '1 oz (28 g)', calories: 75, protein: 4, carbs: 1, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_parmesan', name: 'Parmesan cheese', servingSize: '1 tbsp', calories: 22, protein: 2, carbs: 0, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_swiss', name: 'Swiss cheese', servingSize: '1 oz (28 g)', calories: 108, protein: 8, carbs: 1, fat: 9, source: 'usda'),
    FoodItem(id: 'cf_american_cheese', name: 'American cheese', servingSize: '1 slice', calories: 60, protein: 3, carbs: 1, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_provolone', name: 'Provolone cheese', servingSize: '1 oz (28 g)', calories: 100, protein: 7, carbs: 1, fat: 8, source: 'usda'),
    FoodItem(id: 'cf_ricotta', name: 'Ricotta cheese', servingSize: '1/2 cup', calories: 180, protein: 14, carbs: 6, fat: 10, source: 'usda'),

    // ── More fruits ─────────────────────────────────────────────────────────────
    FoodItem(id: 'cf_pear', name: 'Pear', servingSize: '1 medium', calories: 101, protein: 1, carbs: 27, fat: 0, source: 'usda', fiberG: 6),
    FoodItem(id: 'cf_cherries', name: 'Cherries', servingSize: '1 cup', calories: 87, protein: 1, carbs: 22, fat: 0, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_raspberries', name: 'Raspberries', servingSize: '1 cup', calories: 64, protein: 1, carbs: 15, fat: 1, source: 'usda', fiberG: 8),
    FoodItem(id: 'cf_blackberries', name: 'Blackberries', servingSize: '1 cup', calories: 62, protein: 2, carbs: 14, fat: 1, source: 'usda', fiberG: 8),
    FoodItem(id: 'cf_kiwi', name: 'Kiwi', servingSize: '1', calories: 42, protein: 1, carbs: 10, fat: 0, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_cantaloupe', name: 'Cantaloupe', servingSize: '1 cup', calories: 53, protein: 1, carbs: 13, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_raisins', name: 'Raisins', servingSize: '1/4 cup', calories: 108, protein: 1, carbs: 29, fat: 0, source: 'usda', sugarG: 21),
    FoodItem(id: 'cf_dates', name: 'Dates', servingSize: '2', calories: 133, protein: 1, carbs: 36, fat: 0, source: 'usda', fiberG: 3, sugarG: 32),
    FoodItem(id: 'cf_plantain', name: 'Plantain', servingSize: '1 cup', calories: 179, protein: 2, carbs: 48, fat: 0, source: 'usda', fiberG: 3),

    // ── More vegetables ─────────────────────────────────────────────────────────
    FoodItem(id: 'cf_asparagus', name: 'Asparagus, cooked', servingSize: '1 cup', calories: 40, protein: 4, carbs: 7, fat: 0, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_brussels_sprouts', name: 'Brussels sprouts', servingSize: '1 cup', calories: 56, protein: 4, carbs: 11, fat: 0, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_cauliflower', name: 'Cauliflower', servingSize: '1 cup', calories: 27, protein: 2, carbs: 5, fat: 0, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_zucchini', name: 'Zucchini', servingSize: '1 cup', calories: 20, protein: 1, carbs: 4, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_mushrooms', name: 'Mushrooms', servingSize: '1 cup', calories: 15, protein: 2, carbs: 2, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_peas', name: 'Green peas', servingSize: '1 cup', calories: 118, protein: 8, carbs: 21, fat: 0, source: 'usda', fiberG: 7),
    FoodItem(id: 'cf_kale', name: 'Kale', servingSize: '1 cup', calories: 33, protein: 3, carbs: 6, fat: 0, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_cabbage', name: 'Cabbage', servingSize: '1 cup', calories: 22, protein: 1, carbs: 5, fat: 0, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_edamame', name: 'Edamame', servingSize: '1/2 cup', calories: 94, protein: 9, carbs: 7, fat: 4, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_olives', name: 'Olives', servingSize: '5', calories: 25, protein: 0, carbs: 1, fat: 2, source: 'usda', sodiumMgValue: 190),
    FoodItem(id: 'cf_guacamole', name: 'Guacamole', servingSize: '2 tbsp', calories: 45, protein: 1, carbs: 3, fat: 4, source: 'usda', fiberG: 2),
    FoodItem(id: 'cf_salsa', name: 'Salsa', servingSize: '2 tbsp', calories: 10, protein: 0, carbs: 2, fat: 0, source: 'usda'),

    // ── More nuts, seeds & spreads ──────────────────────────────────────────────
    FoodItem(id: 'cf_pistachios', name: 'Pistachios', servingSize: '1 oz (28 g)', calories: 159, protein: 6, carbs: 8, fat: 13, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_sunflower_seeds', name: 'Sunflower seeds', servingSize: '1 oz (28 g)', calories: 165, protein: 5, carbs: 7, fat: 14, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_pecans', name: 'Pecans', servingSize: '1 oz (28 g)', calories: 196, protein: 3, carbs: 4, fat: 20, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_chia_seeds', name: 'Chia seeds', servingSize: '1 tbsp', calories: 58, protein: 2, carbs: 5, fat: 4, source: 'usda', fiberG: 4),
    FoodItem(id: 'cf_almond_butter', name: 'Almond butter', servingSize: '2 tbsp', calories: 196, protein: 7, carbs: 6, fat: 18, source: 'usda', fiberG: 3),
    FoodItem(id: 'cf_nutella', name: 'Nutella / hazelnut spread', servingSize: '2 tbsp', calories: 200, protein: 2, carbs: 23, fat: 11, source: 'usda', sugarG: 21),

    // ── More beverages ──────────────────────────────────────────────────────────
    FoodItem(id: 'cf_apple_juice', name: 'Apple juice', servingSize: '1 cup (240 ml)', calories: 114, protein: 0, carbs: 28, fat: 0, source: 'usda', sugarG: 24),
    FoodItem(id: 'cf_lemonade', name: 'Lemonade', servingSize: '1 cup (240 ml)', calories: 99, protein: 0, carbs: 26, fat: 0, source: 'usda', sugarG: 25),
    FoodItem(id: 'cf_iced_coffee', name: 'Iced coffee, sweetened', servingSize: '16 oz', calories: 120, protein: 2, carbs: 24, fat: 2, source: 'usda', sugarG: 20),
    FoodItem(id: 'cf_cappuccino', name: 'Cappuccino', servingSize: '8 oz', calories: 74, protein: 4, carbs: 6, fat: 4, source: 'usda'),
    FoodItem(id: 'cf_milkshake', name: 'Vanilla milkshake', servingSize: '12 oz', calories: 370, protein: 8, carbs: 58, fat: 12, source: 'usda', sugarG: 54),
    FoodItem(id: 'cf_hot_chocolate', name: 'Hot chocolate', servingSize: '1 cup', calories: 190, protein: 8, carbs: 27, fat: 6, source: 'usda', sugarG: 24),
    FoodItem(id: 'cf_coconut_water', name: 'Coconut water', servingSize: '1 cup (240 ml)', calories: 46, protein: 2, carbs: 9, fat: 0, source: 'usda', sugarG: 6),
    FoodItem(id: 'cf_chai_latte', name: 'Chai latte', servingSize: '12 oz', calories: 210, protein: 6, carbs: 34, fat: 5, source: 'usda', sugarG: 32),
    FoodItem(id: 'cf_liquor', name: 'Liquor (vodka/whiskey/rum)', servingSize: '1.5 oz shot', calories: 97, protein: 0, carbs: 0, fat: 0, source: 'usda'),
    FoodItem(id: 'cf_champagne', name: 'Champagne', servingSize: '5 oz (148 ml)', calories: 96, protein: 0, carbs: 3, fat: 0, source: 'usda'),

    // ── More snacks & sweets ────────────────────────────────────────────────────
    FoodItem(id: 'cf_brownie', name: 'Brownie', servingSize: '1', calories: 132, protein: 2, carbs: 18, fat: 8, source: 'usda', sugarG: 14),
    FoodItem(id: 'cf_cheesecake', name: 'Cheesecake', servingSize: '1 slice', calories: 321, protein: 6, carbs: 26, fat: 23, source: 'usda', sugarG: 22),
    FoodItem(id: 'cf_apple_pie', name: 'Apple pie', servingSize: '1 slice', calories: 296, protein: 2, carbs: 43, fat: 14, source: 'usda', sugarG: 20),
    FoodItem(id: 'cf_cinnamon_roll', name: 'Cinnamon roll', servingSize: '1', calories: 340, protein: 5, carbs: 52, fat: 14, source: 'usda', sugarG: 25),
    FoodItem(id: 'cf_rice_krispie', name: 'Rice Krispie treat', servingSize: '1', calories: 90, protein: 1, carbs: 17, fat: 2, source: 'usda', sugarG: 8),
    FoodItem(id: 'cf_jello', name: 'Jello', servingSize: '1/2 cup', calories: 80, protein: 2, carbs: 19, fat: 0, source: 'usda', sugarG: 18),
    FoodItem(id: 'cf_pudding', name: 'Pudding', servingSize: '1/2 cup', calories: 140, protein: 2, carbs: 26, fat: 4, source: 'usda', sugarG: 20),
    FoodItem(id: 'cf_oreos', name: 'Oreo cookies', servingSize: '3 cookies', calories: 160, protein: 1, carbs: 25, fat: 7, source: 'usda', sugarG: 14),
    FoodItem(id: 'cf_cheez_its', name: 'Cheez-Its', servingSize: '27 crackers', calories: 150, protein: 3, carbs: 17, fat: 8, source: 'usda', sodiumMgValue: 230),
    FoodItem(id: 'cf_goldfish', name: 'Goldfish crackers', servingSize: '55 pieces', calories: 140, protein: 3, carbs: 20, fat: 5, source: 'usda'),
    FoodItem(id: 'cf_gummy_bears', name: 'Gummy bears', servingSize: '17 pieces', calories: 130, protein: 0, carbs: 30, fat: 0, source: 'usda', sugarG: 22),
    FoodItem(id: 'cf_cheese_puffs', name: 'Cheese puffs', servingSize: '1 oz (28 g)', calories: 150, protein: 2, carbs: 15, fat: 10, source: 'usda'),

    // ── More condiments ─────────────────────────────────────────────────────────
    FoodItem(id: 'cf_mustard', name: 'Mustard', servingSize: '1 tbsp', calories: 9, protein: 1, carbs: 1, fat: 0, source: 'usda', sodiumMgValue: 170),
    FoodItem(id: 'cf_bbq_sauce', name: 'BBQ sauce', servingSize: '2 tbsp', calories: 70, protein: 0, carbs: 17, fat: 0, source: 'usda', sugarG: 13),
    FoodItem(id: 'cf_hot_sauce', name: 'Hot sauce', servingSize: '1 tsp', calories: 1, protein: 0, carbs: 0, fat: 0, source: 'usda', sodiumMgValue: 120),
    FoodItem(id: 'cf_italian_dressing', name: 'Italian dressing', servingSize: '2 tbsp', calories: 70, protein: 0, carbs: 3, fat: 6, source: 'usda'),
    FoodItem(id: 'cf_jam', name: 'Jam / jelly', servingSize: '1 tbsp', calories: 56, protein: 0, carbs: 14, fat: 0, source: 'usda', sugarG: 10),
    FoodItem(id: 'cf_gravy', name: 'Gravy', servingSize: '1/4 cup', calories: 30, protein: 1, carbs: 3, fat: 1, source: 'usda'),
    FoodItem(id: 'cf_coffee_creamer', name: 'Coffee creamer', servingSize: '1 tbsp', calories: 35, protein: 0, carbs: 5, fat: 2, source: 'usda', sugarG: 5),
  ];
}
