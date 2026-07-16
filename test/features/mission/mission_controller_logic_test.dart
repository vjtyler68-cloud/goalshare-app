import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mission/model/get_all_mission_model.dart';

void main() {
  // ── ClientTimerEntry ─────────────────────────────────────────────────────

  group('ClientTimerEntry.formatted', () {
    ClientTimerEntry makeTimer({int elapsed = 0}) =>
        ClientTimerEntry(id: '1', name: 'Test', elapsedSeconds: elapsed);

    test('formats zero seconds as 00:00:00', () {
      expect(makeTimer(elapsed: 0).formatted, '00:00:00');
    });

    test('formats 61 seconds as 00:01:01', () {
      expect(makeTimer(elapsed: 61).formatted, '00:01:01');
    });

    test('formats 3600 seconds as 01:00:00', () {
      expect(makeTimer(elapsed: 3600).formatted, '01:00:00');
    });

    test('formats 3661 seconds as 01:01:01', () {
      expect(makeTimer(elapsed: 3661).formatted, '01:01:01');
    });

    test('formats 86399 seconds as 23:59:59', () {
      expect(makeTimer(elapsed: 86399).formatted, '23:59:59');
    });

    test('pads single digit minutes and seconds', () {
      // 65 seconds = 0 hr, 1 min, 5 sec
      expect(makeTimer(elapsed: 65).formatted, '00:01:05');
    });
  });

  group('ClientTimerEntry start / stop', () {
    test('starts not running', () {
      final t = ClientTimerEntry(id: '1', name: 'T');
      expect(t.isRunning, isFalse);
    });

    test('isRunning becomes true after start', () {
      final t = ClientTimerEntry(id: '1', name: 'T');
      t.start(() {});
      expect(t.isRunning, isTrue);
      t.stop();
    });

    test('isRunning becomes false after stop', () {
      final t = ClientTimerEntry(id: '1', name: 'T');
      t.start(() {});
      t.stop();
      expect(t.isRunning, isFalse);
    });

    test('calling start twice does not double-start', () {
      // If it double-started, elapsed would tick at 2× speed — we just
      // verify isRunning stays true and no exception is thrown.
      final t = ClientTimerEntry(id: '1', name: 'T');
      t.start(() {});
      t.start(() {}); // should be a no-op
      expect(t.isRunning, isTrue);
      t.stop();
    });
  });

  // ── MissionController pure / computed logic ──────────────────────────────

  group('MissionController.formattedClientTime', () {
    // We test the public static-like method without initialising the full
    // controller (which makes network calls in onInit). We instantiate it via
    // the default constructor and call the method synchronously.
    late MissionController ctrl;

    setUp(() {
      ctrl = MissionController();
    });

    tearDown(() {
      ctrl.onClose();
    });

    test('returns "00 : 00" for null seconds', () {
      expect(ctrl.formattedClientTime(null), '00 : 00');
    });

    test('returns "00 : 00" for zero seconds', () {
      expect(ctrl.formattedClientTime(0), '00 : 00');
    });

    test('returns "00 : 00" for negative seconds', () {
      expect(ctrl.formattedClientTime(-10), '00 : 00');
    });

    test('returns minutes and hours for 3600 seconds', () {
      expect(ctrl.formattedClientTime(3600), '01 : 00');
    });

    test('returns correct minutes for 90 seconds', () {
      expect(ctrl.formattedClientTime(90), '00 : 01');
    });

    test('returns correct hours and minutes for 7320 seconds (2h 2m)', () {
      expect(ctrl.formattedClientTime(7320), '02 : 02');
    });
  });

  group('MissionController.parsePriority', () {
    late MissionController ctrl;

    setUp(() {
      ctrl = MissionController();
    });

    tearDown(() {
      ctrl.onClose();
    });

    test('parses "High" to GoalPriority.HIGH', () {
      expect(ctrl.parsePriority('High').toString(), contains('HIGH'));
    });

    test('parses "Medium" to GoalPriority.MEDIUM', () {
      expect(ctrl.parsePriority('Medium').toString(), contains('MEDIUM'));
    });

    test('parses "Low" to GoalPriority.LOW', () {
      expect(ctrl.parsePriority('Low').toString(), contains('LOW'));
    });

    test('defaults to LOW for unknown string', () {
      expect(ctrl.parsePriority('Unknown').toString(), contains('LOW'));
    });

    test('defaults to LOW for null', () {
      expect(ctrl.parsePriority(null).toString(), contains('LOW'));
    });
  });

  group('MissionController._recalculateProgress (via fetchProgressInfo)', () {
    late MissionController ctrl;

    setUp(() {
      ctrl = MissionController();
    });

    tearDown(() {
      ctrl.onClose();
    });

    test('totals are zero when mission list is empty', () async {
      ctrl.getAllMissionList.clear();
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalClient.value, 0);
      expect(ctrl.totalReachedClient.value, 0);
      expect(ctrl.totalSalesPercentage.value, 0);
      expect(ctrl.totalTimeSpent.value, '0 Sec');
    });

    test('calculates total clients from mission list', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 5, totalReached: 2, reachedClientsTime: 0),
        GetAllMissionModel(clientTarget: 10, totalReached: 3, reachedClientsTime: 0),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalClient.value, 15);
      expect(ctrl.totalReachedClient.value, 5);
    });

    test('calculates sales percentage correctly', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 100, totalReached: 75, reachedClientsTime: 0),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalSalesPercentage.value, 75);
    });

    test('percentage is 0 when clientTarget is zero', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 0, totalReached: 0, reachedClientsTime: 0),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalSalesPercentage.value, 0);
    });

    test('formats total time as seconds when under 60', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 1, totalReached: 0, reachedClientsTime: 45),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalTimeSpent.value, '45 Sec');
    });

    test('formats total time as minutes when 60–3599 seconds', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 1, totalReached: 0, reachedClientsTime: 120),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalTimeSpent.value, '2 Min');
    });

    test('formats total time as hours when >= 3600 seconds', () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(clientTarget: 1, totalReached: 0, reachedClientsTime: 7200),
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalTimeSpent.value, '2 Hr');
    });

    test('handles null clientTarget / totalReached / reachedClientsTime as 0',
        () async {
      ctrl.getAllMissionList
          ..clear()
          ..addAll([
        GetAllMissionModel(), // all null
          ]);
      await ctrl.fetchProgressInfo();
      expect(ctrl.totalClient.value, 0);
      expect(ctrl.totalReachedClient.value, 0);
      expect(ctrl.totalTimeSpent.value, '0 Sec');
    });
  });

  // ── MissionController counter helpers ───────────────────────────────────

  group('MissionController increment / decrement', () {
    late MissionController ctrl;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ctrl = MissionController();
    });

    tearDown(() {
      ctrl.onClose();
    });

    test('increment increases value by 1', () {
      final before = ctrl.homesKnocked.value;
      ctrl.increment(ctrl.homesKnocked);
      expect(ctrl.homesKnocked.value, before + 1);
    });

    test('decrement decreases value by 1', () {
      ctrl.homesKnocked.value = 5;
      ctrl.decrement(ctrl.homesKnocked);
      expect(ctrl.homesKnocked.value, 4);
    });

    test('decrement does not go below zero', () {
      ctrl.homesKnocked.value = 0;
      ctrl.decrement(ctrl.homesKnocked);
      expect(ctrl.homesKnocked.value, 0);
    });
  });
}
