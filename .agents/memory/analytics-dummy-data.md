---
name: Analytics tab data sources
description: The displayed Analytics screen uses REAL data; the old AnalyticsController + AnalyticsDummyData is dead legacy
---

# Analytics tab data sources

The Analytics screen shown in the bottom nav is `AnalyticsPage` (`lib/features/analytics_tab/ui/analytics_ui.dart`). It renders **real** data:
- All-time career stats from `AchievementsController` (totalHomesAllTime / totalPeopleAllTime / totalSalesAllTime).
- Today's funnel + header chips from `MissionController` daily metrics (homesKnocked / peopleTalkedTo / salesMade).
- Goal trend, distribution, mission performance, summary cards from `ReportAnalysisController.fetchReportAnalytics()` (backend `getUserReportAnalytics`).

**Dead legacy:** `AnalyticsController` + `AnalyticsData` + `AnalyticsDummyData.generateDummyData()` in analytics_controller.dart/analytics_model.dart are NOT displayed. Only `AnalyticsController.isLoading` (first-load spinner gate) is still referenced. Its `refreshData()` used to be wired to pull-to-refresh but only reloaded the sample data — fixed to reload the real sources.

**How to apply:** To change what the analytics screen shows, edit `analytics_ui.dart` + `ReportAnalysisController`. Don't touch the dummy generator (it's inert). The dead AnalyticsController/AnalyticsData could be deleted in a future cleanup, but the UI still needs its `isLoading` flag unless that's refactored too.
