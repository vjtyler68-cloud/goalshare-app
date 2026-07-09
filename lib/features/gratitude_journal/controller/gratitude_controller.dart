import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../data/daily_gratitude.dart';
import '../data/gratitude_entry.dart';

const String kGratitudeBox = 'gratitude_journal';
const int kMaxGratitude = 10;

class GratitudeController extends GetxController {
  Box<DailyGratitude>? _box;

  final RxList<GratitudeEntry> entries = <GratitudeEntry>[].obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final RxBool isReady = false.obs;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _open();
  }

  Future<void> _open() async {
    try {
      // Hive.initFlutter() is already called at app start; safe to be defensive.
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(GratitudeEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(DailyGratitudeAdapter());
      }

      if (!Hive.isBoxOpen(kGratitudeBox)) {
        _box = await Hive.openBox<DailyGratitude>(kGratitudeBox);
      } else {
        _box = Hive.box<DailyGratitude>(kGratitudeBox);
      }

      _load();
    } catch (_) {
      // Hive failure is non-fatal — journal simply starts empty this session.
    } finally {
      isReady.value = true;
    }
  }

  // ── date helpers ────────────────────────────────────────────────────────────
  String _keyFor(DateTime d) {
    final only = DateTime(d.year, d.month, d.day);
    return "${only.year.toString().padLeft(4, '0')}-"
        "${only.month.toString().padLeft(2, '0')}-"
        "${only.day.toString().padLeft(2, '0')}";
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _load() {
    final key = _keyFor(selectedDay.value);
    final existing = _box?.get(key);
    entries.assignAll(existing?.entries ?? []);
  }

  // ── public getters ─────────────────────────────────────────────────────────
  int get count => entries.length;
  bool get canAddMore => entries.length < kMaxGratitude;
  int get remainingSlots => kMaxGratitude - entries.length;

  bool get isToday => _isSameDay(selectedDay.value, DateTime.now());

  bool get canGoForward {
    final s = selectedDay.value;
    final now = DateTime.now();
    return DateTime(s.year, s.month, s.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  String get headerDate => isToday
      ? 'Today'
      : DateFormat('EEEE, MMM d').format(selectedDay.value);

  String get subHeaderDate => DateFormat('MMMM d, y').format(selectedDay.value);

  // ── navigation ──────────────────────────────────────────────────────────────
  void goPreviousDay() {
    selectedDay.value = selectedDay.value.subtract(const Duration(days: 1));
    _load();
  }

  void goNextDay() {
    if (!canGoForward) return;
    selectedDay.value = selectedDay.value.add(const Duration(days: 1));
    _load();
  }

  void goToday() {
    selectedDay.value = DateTime.now();
    _load();
  }

  // ── mutations ───────────────────────────────────────────────────────────────
  Future<void> add(String text) async {
    final t = text.trim();
    if (t.isEmpty || !canAddMore) return;

    final now = DateTime.now();
    entries.add(GratitudeEntry(
      id: now.microsecondsSinceEpoch.toString(),
      text: t,
      createdAt: now,
    ));
    await _persist();
  }

  Future<void> edit(String id, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    entries[idx] = entries[idx].copyWith(text: t, updatedAt: DateTime.now());
    await _persist();
  }

  Future<void> remove(String id) async {
    entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    final key = _keyFor(selectedDay.value);
    await _box?.put(key, DailyGratitude(dateKey: key, entries: entries.toList()));
    entries.refresh();
  }
}
