---
name: Nav Bar Index Map
description: Bottom nav tab order and the pages list that must stay in sync with it.
---

# Nav Bar Index Map

## The rule
Bottom nav and `MainNavBarController.pages` list must stay in exact sync. The FAB (centre add button) is **not** a tab index — it's an `Expanded` widget in the row that calls `CreateNewMission.show()`.

**Why:** Adding a tab without updating the pages list (or vice versa) causes index-out-of-bounds at runtime.

## Current mapping (as of chat integration)

| Index | Label     | Icon                          | pages[i]       |
|-------|-----------|-------------------------------|----------------|
| 0     | Home      | home_outlined / home_rounded  | HomeScreen()   |
| 1     | Mission   | flag_outlined / flag_rounded  | MissionScreen()|
| —     | FAB       | add (not a tab)               | —              |
| 2     | Analytics | bar_chart_outlined/rounded    | AnalyticsPage()|
| 3     | Messages  | chat_bubble_outline_rounded   | MessagesPage() |
| 4     | Profile   | person_outline / person_rounded | ProfileTabPage()|

## How to apply
When adding a new tab: update BOTH `main_navbar_screen.dart` (add `_NavItem`) AND `main_navbar_controller.dart` (add to `pages` list at the same position).
