import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/mission/model/get_all_mission_model.dart';

void main() {
  // ── GetAllMissionModel.fromJson ──────────────────────────────────────────

  group('GetAllMissionModel.fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'mission-1',
      'title': 'Close 10 Sales',
      'clientTarget': 10,
      'description': 'Reach 10 clients this week',
      'category': 'Weekly',
      'priority': 'High',
      'dueDate': '2026-07-31T12:00:00.000Z',
      'status': 'ACTIVE',
      'breakTimeSpent': 300,
      'reachedClientsTime': 1800,
      'totalReached': 4,
      'clients': [
        {'status': 'DONE', 'timeSpent': 600},
        {'status': 'PENDING', 'timeSpent': 120},
      ],
    };

    test('parses scalar fields correctly', () {
      final model = GetAllMissionModel.fromJson(fullJson);
      expect(model.id, 'mission-1');
      expect(model.title, 'Close 10 Sales');
      expect(model.clientTarget, 10);
      expect(model.category, 'Weekly');
      expect(model.priority, 'High');
      expect(model.status, 'ACTIVE');
      expect(model.breakTimeSpent, 300);
      expect(model.reachedClientsTime, 1800);
      expect(model.totalReached, 4);
    });

    test('parses dueDate as DateTime', () {
      final model = GetAllMissionModel.fromJson(fullJson);
      expect(model.dueDate, isA<DateTime>());
      expect(model.dueDate!.year, 2026);
      expect(model.dueDate!.month, 7);
      expect(model.dueDate!.day, 31);
    });

    test('sets dueDate to null when missing', () {
      final json = Map<String, dynamic>.from(fullJson)..remove('dueDate');
      final model = GetAllMissionModel.fromJson(json);
      expect(model.dueDate, isNull);
    });

    test('parses clients list', () {
      final model = GetAllMissionModel.fromJson(fullJson);
      expect(model.clients, hasLength(2));
      expect(model.clients!.first.status, 'DONE');
      expect(model.clients!.first.timeSpent, 600);
    });

    test('returns empty clients list when null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['clients'] = null;
      final model = GetAllMissionModel.fromJson(json);
      expect(model.clients, isEmpty);
    });

    test('handles completely empty json', () {
      final model = GetAllMissionModel.fromJson({});
      expect(model.id, isNull);
      expect(model.clientTarget, isNull);
      expect(model.clients, isEmpty);
    });
  });

  // ── GetAllMissionModel.toJson ────────────────────────────────────────────

  group('GetAllMissionModel.toJson', () {
    test('serialises dueDate as ISO 8601 string', () {
      final model = GetAllMissionModel(
        id: 'm1',
        dueDate: DateTime.utc(2026, 8, 15, 12),
      );
      final json = model.toJson();
      expect(json['id'], 'm1');
      expect(json['dueDate'], contains('2026-08-15'));
    });

    test('serialises null dueDate as null', () {
      final model = GetAllMissionModel(id: 'm2');
      expect(model.toJson()['dueDate'], isNull);
    });

    test('serialises clients list', () {
      final model = GetAllMissionModel(
        clients: [Client(status: 'DONE', timeSpent: 90)],
      );
      final json = model.toJson();
      expect((json['clients'] as List).length, 1);
      expect((json['clients'] as List).first['status'], 'DONE');
    });
  });

  // ── Client ───────────────────────────────────────────────────────────────

  group('Client', () {
    test('fromJson / toJson round-trip', () {
      final json = {'status': 'PENDING', 'timeSpent': 45};
      final client = Client.fromJson(json);
      expect(client.status, 'PENDING');
      expect(client.timeSpent, 45);
      expect(client.toJson(), equals(json));
    });

    test('handles null fields', () {
      final client = Client.fromJson({});
      expect(client.status, isNull);
      expect(client.timeSpent, isNull);
    });
  });
}
