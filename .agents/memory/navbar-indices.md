---
name: Nav Bar Index Map
description: Bottom nav tab order and the pages list that must stay in sync with it.
---

# Nav Bar Index Map

## The rule
Bottom nav and `MainNavBarController.pages` list must stay in exact sync. The FAB (centre add button) is **not** a tab index — it's an `Expanded` widget in the row that calls `CreateNewMission.show()`.

**Why:** Adding a tab without updating the pages list (or vice versa) causes index-out-of-bounds at runtime.

## Current mapping (Analytics moved under Profile; Goals took its slot)

| Index | Label   | Icon                                            | pages[i]        |
|-------|---------|-------------------------------------------------|-----------------|
| 0     | Home    | home_outlined / home_rounded                    | HomeScreen()    |
| 1     | Mission | flag_outlined / flag_rounded                    | MissionScreen() |
| —     | FAB     | add (not a tab) → CreateNewMission.show()         | —               |
| 2     | Goals   | track_changes_outlined / track_changes_rounded  | GoalsScreen()   |
| 3     | Messages| chat_bubble_outline_rounded                     | MessagesPage()  |
| 4     | Profile | person_outline / person_rounded                 | ProfileTabPage()|

- **Analytics is no longer a bottom tab.** It's opened by push from a Profile menu entry ("Analytics", uses `ProfileMenuItem.icon` IconData instead of an asset). `AnalyticsPage` header has a Back button for this push flow.
- **Mission tab is unchanged** (daily door-knock tracker; its End-of-Day feeds AchievementsController → Analytics).
- **Goals tab** (`lib/features/goals/screen/goals_screen.dart`, "My Goals") lists `MissionController.getAllMissionList` grouped by category (Daily/Weekly/Monthly/Yearly). Missions & Goals share `MissionController` (backend `/goals`); the FAB "+" create dialog is still labeled "Mission".

## How to apply
When adding a new tab: update BOTH `main_navbar_screen.dart` (add `_NavItem`) AND `main_navbar_controller.dart` (add to `pages` list at the same position).
