import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../core/daily_checks/daily_check_service.dart';
import '../data/journal_entry.dart';

const String kJournalBox = 'journal_entries';
const int kMinGratitude = 5;
const int kMaxGratitude = 10;

class JournalController extends GetxController {
  /// Shared instance — reused if already registered (survives deep links).
  static JournalController get to => Get.isRegistered<JournalController>()
      ? Get.find<JournalController>()
      : Get.put(JournalController(), permanent: true);

  Box<JournalEntry>? _box;
  final RxBool isReady = false.obs;

  /// All entries, newest first. Reactive so screens rebuild on save/delete.
  final RxList<JournalEntry> entries = <JournalEntry>[].obs;

  // ── lifecycle ────────────────────────────────────────────────────────────��─
  @override
  void onInit() {
    super.onInit();
    _open();
  }

  Future<void> _open() async {
    try {
      // Reuse existing adapter if already registered — avoids collisions.
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(JournalEntryAdapter());
      }
      if (!Hive.isBoxOpen(kJournalBox)) {
        _box = await Hive.openBox<JournalEntry>(kJournalBox);
      } else {
        _box = Hive.box<JournalEntry>(kJournalBox);
      }
      _refresh();
    } catch (_) {
      // Non-fatal — journal simply starts empty this session.
    } finally {
      isReady.value = true;
    }
  }

  void _refresh() {
    final all = _box?.values.toList() ?? <JournalEntry>[];
    all.sort((a, b) => b.date.compareTo(a.date));
    entries.assignAll(all);
  }

  // ── date helpers ─────────────────────────────────────────────────────────��─
  static String keyFor(DateTime d) {
    final only = DateTime(d.year, d.month, d.day);
    return "${only.year.toString().padLeft(4, '0')}-"
        "${only.month.toString().padLeft(2, '0')}-"
        "${only.day.toString().padLeft(2, '0')}";
  }

  JournalEntry? entryFor(DateTime d) => _box?.get(keyFor(d));

  bool get hasEntryToday => entryFor(DateTime.now()) != null;

  // ── mutations ──────────────────────────────────────────────────────────────
  /// Returns true only if the write actually persisted (box is open).
  Future<bool> save(JournalEntry entry) async {
    if (_box == null) return false;
    await _box!.put(entry.id, entry);
    _refresh();
    if (entry.id == keyFor(DateTime.now())) {
      DailyCheckService.to.markDoneToday(DailyCheckFeature.gratitude);
    }
    return true;
  }

  Future<bool> delete(String id) async {
    if (_box == null) return false;
    await _box!.delete(id);
    _refresh();
    return true;
  }

  // ── stats ────────────────────────────────────────────────────────────────��─
  int get totalEntries => entries.length;

  Set<String> get _dayKeys => entries.map((e) => e.id).toSet();

  /// Consecutive days with an entry, ending today. A missing *today* is
  /// forgiven (streak counts back from yesterday) until a full day is skipped.
  int get currentStreak {
    final keys = _dayKeys;
    if (keys.isEmpty) return 0;

    var cursor = DateTime.now();
    if (!keys.contains(keyFor(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!keys.contains(keyFor(cursor))) return 0;
    }

    int streak = 0;
    while (keys.contains(keyFor(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    final days = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toList()
      ..sort();
    if (days.isEmpty) return 0;

    int best = 1, cur = 1;
    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        cur++;
        if (cur > best) best = cur;
      } else if (diff == 0) {
        // same day (shouldn't happen with per-day keys) — ignore
      } else {
        cur = 1;
      }
    }
    return best;
  }

  double _avgRatingWithin(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rated =
        entries.where((e) => e.starRating > 0 && e.date.isAfter(cutoff)).toList();
    if (rated.isEmpty) return 0;
    final sum = rated.fold<int>(0, (p, e) => p + e.starRating);
    return sum / rated.length;
  }

  double get avgLast7 => _avgRatingWithin(7);
  double get avgLast30 => _avgRatingWithin(30);

  /// Star ratings for the last 7 calendar days (0 where no entry) — sparkline.
  List<double> get last7Series {
    final now = DateTime.now();
    final list = <double>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      list.add((_box?.get(keyFor(d))?.starRating ?? 0).toDouble());
    }
    return list;
  }

  // ── search & memories ────────────────────────────────────────────────────��─
  List<JournalEntry> search(String query) {
    final t = query.trim().toLowerCase();
    if (t.isEmpty) return entries.toList();
    return entries.where((e) {
      if (e.dayText.toLowerCase().contains(t)) return true;
      return e.gratitudeItems.any((g) => g.toLowerCase().contains(t));
    }).toList();
  }

  /// Entries from exactly 1 week, 1 month, and 1 year ago (if they exist).
  /// Month/year math is calendar-safe (clamps to the last valid day) so
  /// edge dates like Mar 31 or Feb 29 never overflow into the wrong day.
  List<JournalEntry> get onThisDay {
    final now = DateTime.now();
    final targets = <DateTime>[
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
      _shift(now, months: 1),
      _shift(now, years: 1),
    ];
    final res = <JournalEntry>[];
    for (final t in targets) {
      final e = _box?.get(keyFor(t));
      if (e != null) res.add(e);
    }
    return res;
  }

  /// Subtract [months]/[years] from [d], clamping the day to the last valid
  /// day of the resulting month (avoids DateTime rollover into next month).
  static DateTime _shift(DateTime d, {int months = 0, int years = 0}) {
    var year = d.year - years;
    var month = d.month - months;
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = d.day > lastDayOfMonth ? lastDayOfMonth : d.day;
    return DateTime(year, month, day);
  }
}
