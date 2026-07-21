import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/food_combo.dart';
import 'package:spanx/features/nutrition/data/food_item.dart';
import 'package:spanx/features/nutrition/screen/barcode_scan_screen.dart';
import 'package:spanx/features/nutrition/widgets/nutrition_sheets.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class FoodEntryScreen extends StatefulWidget {
  final String meal;
  const FoodEntryScreen({super.key, required this.meal});

  @override
  State<FoodEntryScreen> createState() => _FoodEntryScreenState();
}

class _FoodEntryScreenState extends State<FoodEntryScreen>
    with SingleTickerProviderStateMixin {
  final NutritionController c = NutritionController.to;
  final TextEditingController _searchC = TextEditingController();
  final TextEditingController _qName = TextEditingController();
  final TextEditingController _qCal = TextEditingController();
  final TextEditingController _qProtein = TextEditingController();
  final TextEditingController _qCarbs = TextEditingController();
  final TextEditingController _qFat = TextEditingController();
  final TextEditingController _qFiber = TextEditingController();
  final TextEditingController _qSugar = TextEditingController();
  final TextEditingController _qSodium = TextEditingController();
  late final TabController _tab;

  final RxList<FoodItem> _results = <FoodItem>[].obs;
  final RxBool _searching = false.obs;
  final RxBool _searched = false.obs;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchC.dispose();
    _qName.dispose();
    _qCal.dispose();
    _qProtein.dispose();
    _qCarbs.dispose();
    _qFat.dispose();
    _qFiber.dispose();
    _qSugar.dispose();
    _qSodium.dispose();
    super.dispose();
  }

  Future<void> _quickAddSave() async {
    final name = _qName.text.trim();
    final cal = double.tryParse(_qCal.text.trim()) ?? -1;
    if (name.isEmpty || cal < 0) {
      _snack('Add a name and calories.');
      return;
    }
    FocusScope.of(context).unfocus();
    // Detailed fields are only read when Detailed mode is on, and a blank one
    // stays null (not 0) so it reads as "not recorded".
    final detailed = c.detailedEntry.value;
    final food = FoodItem(
      id: 'quickadd_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      servingSize: '1 serving',
      calories: cal,
      protein: double.tryParse(_qProtein.text.trim()) ?? 0,
      carbs: double.tryParse(_qCarbs.text.trim()) ?? 0,
      fat: double.tryParse(_qFat.text.trim()) ?? 0,
      source: 'quickadd',
      fiberG: detailed ? _optD(_qFiber.text) : null,
      sugarG: detailed ? _optD(_qSugar.text) : null,
      sodiumMgValue: detailed ? _optD(_qSodium.text) : null,
    );
    final ok = await c.addFood(food: food, meal: widget.meal, quantity: 1);
    if (ok && mounted) {
      Get.back(); // back to dashboard
      Get.snackbar('Added', '$name added to ${_cap(widget.meal)}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _kCard,
          colorText: _kText,
          margin: EdgeInsets.all(12.r));
    } else if (!ok) {
      _snack('Could not save — storage unavailable.');
    }
  }

  void _snack(String msg) => Get.snackbar('', msg,
      titleText: const SizedBox.shrink(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _kCard,
      colorText: _kText,
      margin: EdgeInsets.all(12.r));

  Future<void> _runSearch() async {
    final q = _searchC.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    _searching.value = true;
    _searched.value = true;
    final res = await c.api.searchFoods(q);
    _results.assignAll(res);
    _searching.value = false;
  }

  Future<void> _log(FoodItem food) async {
    final added = await NutritionSheets.adjustNew(c, food, widget.meal);
    if (added && mounted) Get.back(); // return to dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _quickAddTab(),
                _searchTab(),
                _myFoodsTab(),
                _recentTab(),
                _scanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2)),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('Add to ${_cap(widget.meal)}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              SizedBox(height: 8.h),
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp),
                tabs: const [
                  Tab(text: 'Quick Add'),
                  Tab(text: 'Search'),
                  Tab(text: 'My Foods'),
                  Tab(text: 'Recent'),
                  Tab(text: 'Scan'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── QUICK ADD TAB (first — lowest friction) ──────────────────────────────────
  Widget _quickAddTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: _kRed, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Ate out or not sure of the exact food? Just drop a name and '
                    'calories — that\'s all you need.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp, color: _kText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _qField(_qName, 'What did you eat? (e.g. Chipotle bowl)'),
          SizedBox(height: 12.h),
          _qField(_qCal, 'Calories', number: true),
          SizedBox(height: 12.h),
          Obx(() {
            final detailed = c.detailedEntry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Macros (optional)',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp, color: _kMuted)),
                    ),
                    _detailToggle(detailed),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                        child: _qField(_qProtein, 'Protein g', number: true)),
                    SizedBox(width: 8.w),
                    Expanded(child: _qField(_qCarbs, 'Carbs g', number: true)),
                    SizedBox(width: 8.w),
                    Expanded(child: _qField(_qFat, 'Fat g', number: true)),
                  ],
                ),
                if (detailed) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                          child: _qField(_qFiber, 'Fiber g', number: true)),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: _qField(_qSugar, 'Sugar g', number: true)),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: _qField(_qSodium, 'Sodium mg', number: true)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text('Sodium is in milligrams (mg) — everything else is grams.',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.sp, color: _kMuted)),
                ],
              ],
            );
          }),
          SizedBox(height: 22.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _quickAddSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('Add to ${_cap(widget.meal)}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// Basic = protein/carbs/fat only. Detailed adds fiber/sugar/sodium. The
  /// choice is remembered across launches by the controller.
  Widget _detailToggle(bool detailed) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _detailSegment('Basic', !detailed, () => c.setDetailedEntry(false)),
          _detailSegment('Detailed', detailed, () => c.setDetailedEntry(true)),
        ],
      ),
    );
  }

  Widget _detailSegment(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: sel ? _kRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : _kMuted)),
      ),
    );
  }

  static double? _optD(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Widget _qField(TextEditingController controller, String hint,
      {bool number = false}) {
    return TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
        filled: true,
        fillColor: _kCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none),
      ),
    );
  }

  // ── SEARCH TAB ───────────────────────────────────────────────────────────────
  Widget _searchTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchC,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp, color: _kText),
                  decoration: InputDecoration(
                    hintText: 'Search foods…',
                    hintStyle: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp, color: _kMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: _kMuted, size: 20.r),
                    filled: true,
                    fillColor: _kCard,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: _runSearch,
                child: Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                      color: _kRed, borderRadius: BorderRadius.circular(14.r)),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 22.r),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_searching.value) {
              return Center(child: CircularProgressIndicator(color: _kRed));
            }
            if (!_searched.value) {
              return _hint(Icons.search_rounded,
                  'Search the food database', 'Type a food and tap search.');
            }
            if (_results.isEmpty) {
              return _emptyWithCreate('No matches found.');
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 24.r),
              itemCount: _results.length + 1,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, i) {
                if (i == _results.length) return _createFoodTile();
                return _foodTile(_results[i]);
              },
            );
          }),
        ),
      ],
    );
  }

  // ── MY FOODS TAB (+ combos) ──────────────────────────────────────────────────
  Widget _myFoodsTab() {
    return Obx(() {
      c.allEntries.length; // reactive
      c.combos.length; // reactive
      final foods = c.myFoods;
      final combos = c.combos;
      if (foods.isEmpty && combos.isEmpty) {
        return _emptyWithCreate(
            'Foods you log will show up here for quick re-adding.');
      }
      return ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          _sectionLabel('Combos', Icons.dashboard_customize_rounded),
          SizedBox(height: 8.h),
          _saveComboTile(),
          if (combos.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ...combos.map((combo) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _comboTile(combo),
                )),
          ],
          SizedBox(height: 18.h),
          _sectionLabel('My Foods', Icons.restaurant_rounded),
          SizedBox(height: 8.h),
          if (foods.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text('Foods you log will appear here.',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp, color: _kMuted)),
            )
          else
            ...foods.map((f) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _foodTile(f),
                )),
          SizedBox(height: 8.h),
          _createFoodTile(),
        ],
      );
    });
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kText, size: 16.r),
        SizedBox(width: 6.w),
        Text(text,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText)),
      ],
    );
  }

  Widget _saveComboTile() {
    return GestureDetector(
      onTap: () => NutritionSheets.saveCombo(c),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _kRed.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: _kRed, size: 20.r),
            SizedBox(width: 8.w),
            Text('Save as combo',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _kRed)),
          ],
        ),
      ),
    );
  }

  Widget _comboTile(FoodCombo combo) {
    return GestureDetector(
      onTap: () async {
        final n = await c.logCombo(combo, widget.meal);
        if (n > 0 && mounted) {
          Get.back();
          _snack('Logged ${combo.name} ($n items)');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ]),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Icon(Icons.layers_rounded, color: _kRed, size: 18.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(combo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text(
                      '${combo.items.length} items · ${combo.calories.round()} cal',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.sp, color: _kMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _confirmDeleteCombo(combo),
              child: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCombo(FoodCombo combo) {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: 'Delete combo?',
      middleText: 'Remove "${combo.name}" from your saved combos.',
      confirm: TextButton(
        onPressed: () {
          Get.back();
          c.deleteCombo(combo.id);
        },
        child: const Text('Delete', style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text('Cancel')),
    );
  }

  // ── RECENT TAB ───────────────────────────────────────────────────────────────
  Widget _recentTab() {
    return Obx(() {
      c.allEntries.length; // reactive
      final recent = c.recentEntries;
      if (recent.isEmpty) {
        return _emptyWithCreate('Your last 20 logged items will appear here.');
      }
      return ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: recent.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => _foodTile(recent[i].foodItem),
      );
    });
  }

  // ── SCAN TAB ─────────────────────────────────────────────────────────────────
  Widget _scanTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r)),
              child: Icon(Icons.qr_code_scanner_rounded,
                  color: _kRed, size: 44.r),
            ),
            SizedBox(height: 20.h),
            Text('Scan a barcode',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 8.h),
            Text(
              'Point your camera at a product barcode to pull its nutrition from Open Food Facts.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp, color: _kMuted, height: 1.5),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                label: Text('Open Scanner',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openScanner() async {
    final code = await Get.to<String>(() => const BarcodeScanScreen());
    if (code == null || code.isEmpty) return;
    final food = await c.api.lookupBarcode(code);
    if (food == null) {
      _notFoundDialog();
      return;
    }
    _log(food);
  }

  void _notFoundDialog() {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: 'Not found',
      middleText:
          'That barcode isn\'t in the database. You can add it manually instead.',
      confirm: TextButton(
        onPressed: () {
          Get.back();
          NutritionSheets.createFood(c, widget.meal);
        },
        child: Text('Create Food', style: TextStyle(color: _kRed)),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text('Close')),
    );
  }

  // ── shared tiles ─────────────────────────────────────────────────────────────
  Widget _foodTile(FoodItem food) {
    return GestureDetector(
      onTap: () => _log(food),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ]),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  SizedBox(height: 3.h),
                  Text(
                    '${food.calories.round()} cal · P ${food.protein.round()} · C ${food.carbs.round()} · F ${food.fat.round()}  ·  ${food.servingSize}',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 10.sp, color: _kMuted),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Icon(Icons.add_rounded, color: _kRed, size: 20.r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createFoodTile() {
    return GestureDetector(
      onTap: () => NutritionSheets.createFood(c, widget.meal),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _kRed.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, color: _kRed, size: 20.r),
            SizedBox(width: 8.w),
            Text('Create New Food',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _kRed)),
          ],
        ),
      ),
    );
  }

  Widget _emptyWithCreate(String msg) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_rounded,
                color: _kRed.withOpacity(0.35), size: 44.r),
            SizedBox(height: 14.h),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp, color: _kMuted, height: 1.5)),
            SizedBox(height: 18.h),
            SizedBox(width: 220.w, child: _createFoodTile()),
          ],
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kRed.withOpacity(0.35), size: 44.r),
            SizedBox(height: 14.h),
            Text(title,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 6.h),
            Text(sub,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, color: _kMuted)),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
