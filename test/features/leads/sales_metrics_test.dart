import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:spanx/features/leads/controller/leads_controller.dart';
import 'package:spanx/features/leads/model/lead.dart';

/// The CRM getters are pure over the in-memory `leads` list (onInit, which opens
/// Hive, is only invoked by Get.put — not by the bare constructor), so they can
/// be tested directly.
void main() {
  Lead lead(String status, double value, {DateTime? closedAt, DateTime? remind}) {
    final now = DateTime.now();
    return Lead(
      id: '$status$value${closedAt ?? ''}${remind ?? ''}',
      name: 'L',
      status: status,
      dealValue: value,
      closedAt: closedAt,
      reminderAt: remind,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('pipeline value sums only open leads', () {
    final c = LeadsController();
    c.leads.assignAll([
      lead('New', 1000),
      lead('Appointment', 4000),
      lead('Won', 9000, closedAt: DateTime.now()),
      lead('Lost', 2000, closedAt: DateTime.now()),
    ]);
    expect(c.pipelineValue, 5000); // New + Appointment only
    expect(c.valueForStatus('Won'), 9000);
  });

  test('close rate = won / (won + lost)', () {
    final c = LeadsController();
    c.leads.assignAll([
      lead('Won', 1, closedAt: DateTime.now()),
      lead('Won', 1, closedAt: DateTime.now()),
      lead('Won', 1, closedAt: DateTime.now()),
      lead('Lost', 1, closedAt: DateTime.now()),
      lead('New', 1),
    ]);
    expect(c.closeRate.round(), 75); // 3 / 4
  });

  test('revenue this month counts only Won closed this month', () {
    final c = LeadsController();
    final lastMonth = DateTime.now().subtract(const Duration(days: 40));
    c.leads.assignAll([
      lead('Won', 5000, closedAt: DateTime.now()),
      lead('Won', 3000, closedAt: DateTime.now()),
      lead('Won', 9999, closedAt: lastMonth), // excluded — prior month
    ]);
    expect(c.revenueThisMonth, 8000);
    expect(c.dealsWonThisMonth, 2);
    expect(c.avgDealThisMonth, 4000);
  });

  test('follow-ups due include overdue open leads only', () {
    final c = LeadsController();
    c.leads.assignAll([
      lead('New', 0, remind: DateTime.now().subtract(const Duration(days: 1))),
      lead('Contacted', 0, remind: DateTime.now().add(const Duration(days: 5))),
      lead('Won', 0,
          closedAt: DateTime.now(),
          remind: DateTime.now().subtract(const Duration(days: 1))),
    ]);
    // Only the overdue OPEN lead counts (future one and the Won one excluded).
    expect(c.followUpsDue.length, 1);
  });

  test('stale leads = open leads not touched in 7+ days', () {
    final c = LeadsController();
    final old = DateTime.now().subtract(const Duration(days: 10));
    final recent = DateTime.now().subtract(const Duration(days: 2));
    c.leads.assignAll([
      Lead(id: 'a', name: 'Old', status: 'New', createdAt: old, updatedAt: old),
      Lead(
          id: 'b',
          name: 'Fresh',
          status: 'New',
          createdAt: recent,
          updatedAt: recent),
      // Old but recently touched via an activity → NOT stale.
      Lead(
          id: 'c',
          name: 'Touched',
          status: 'Contacted',
          createdAt: old,
          updatedAt: old,
          activities: [LeadActivity(type: 'call', at: DateTime.now())]),
      // Old + open? No — Won leads never count as stale.
      Lead(
          id: 'd',
          name: 'Closed',
          status: 'Won',
          createdAt: old,
          updatedAt: old,
          closedAt: old),
    ]);
    final stale = c.staleLeads();
    expect(stale.length, 1);
    expect(stale.first.id, 'a');
  });

  test('bestMonth returns the highest-revenue won month', () {
    final c = LeadsController();
    c.leads.assignAll([
      lead('Won', 5000, closedAt: DateTime(2026, 3, 10)),
      lead('Won', 3000, closedAt: DateTime(2026, 3, 20)), // Mar = 8000
      lead('Won', 9000, closedAt: DateTime(2026, 6, 5)), // Jun = 9000
    ]);
    final best = c.bestMonth;
    expect(best.value, 9000);
    expect(best.key, 'Jun 2026');
  });

  tearDown(Get.reset);
}
