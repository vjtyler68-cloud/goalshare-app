import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/home/data/daily_spark_quotes.dart';

void main() {
  group('Daily Spark rotation', () {
    test('bundles the full set of quotes', () {
      expect(kDailySparkQuotes.length, 515);
    });

    test('every quote is unique (no repeats within a full lap)', () {
      final quotes = kDailySparkQuotes.map((q) => q.quote).toSet();
      expect(quotes.length, kDailySparkQuotes.length);
    });

    test('every quote and author is non-empty', () {
      for (final q in kDailySparkQuotes) {
        expect(q.quote.trim(), isNotEmpty);
        expect(q.author.trim(), isNotEmpty);
      }
    });

    test('is deterministic — same day always yields the same quote', () {
      final a = sparkQuoteForDay(DateTime(2026, 7, 21));
      final b = sparkQuoteForDay(DateTime(2026, 7, 21, 23, 59));
      expect(a.quote, b.quote);
      expect(a.author, b.author);
    });

    test('advances to a different quote the next day', () {
      final today = sparkQuoteForDay(DateTime(2026, 7, 21));
      final tomorrow = sparkQuoteForDay(DateTime(2026, 7, 22));
      expect(today.quote, isNot(tomorrow.quote));
    });

    test('cycles through all quotes with no gaps over a full lap', () {
      final seen = <String>{};
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < kDailySparkQuotes.length; i++) {
        seen.add(sparkQuoteForDay(day).quote);
        day = day.add(const Duration(days: 1));
      }
      // A full lap touches every distinct quote in the list.
      expect(seen.length, kDailySparkQuotes.length);
    });

    test('index stays in bounds for far-past and far-future dates', () {
      for (final d in [
        DateTime(1990, 1, 1),
        DateTime(2000, 1, 1),
        DateTime(2050, 12, 31),
        DateTime(2199, 6, 15),
      ]) {
        // Must not throw / go out of range.
        expect(() => sparkQuoteForDay(d), returnsNormally);
      }
    });
  });
}
