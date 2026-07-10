import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/food_item.dart';
import 'package:spanx/features/nutrition/screen/barcode_scan_screen.dart';
import 'package:spanx/features/nutrition/widgets/nutrition_sheets.dart';

const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
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
  late final TabController _tab;

  final RxList<FoodItem> _results = <FoodItem>[].obs;
  final RxBool _searching = false.obs;
  final RxBool _searched = false.obs;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchC.dispose();
    super.dispose();
  }

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
      decoration: const BoxDecoration(
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
              return const Center(child: CircularProgressIndicator(color: _kRed));
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

  // ── MY FOODS TAB ─────────────────────────────────────────────────────────────
  Widget _myFoodsTab() {
    return Obx(() {
      c.allEntries.length; // reactive
      final foods = c.myFoods;
      if (foods.isEmpty) {
        return _emptyWithCreate('Foods you log will show up here for quick re-adding.');
      }
      return ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: foods.length + 1,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) {
          if (i == foods.length) return _createFoodTile();
          return _foodTile(foods[i]);
        },
      );
    });
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
        child: const Text('Create Food', style: TextStyle(color: _kRed)),
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
