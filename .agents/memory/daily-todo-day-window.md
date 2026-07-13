---
name: Daily to-do day window
description: Rules for the Home "Today's Tasks" card's yesterday/today/tomorrow navigation and per-day Hive persistence.
---

# Daily to-do 3-day window

The Home daily to-do card (`features/home/subflow/todo`) shows one day at a time, selected by an int `dayOffset` on `DailyTodoController` (-1=yesterday, 0=today, +1=tomorrow), clamped to [-1, +1]. It replaced an earlier binary today/yesterday bool toggle.

**Rules to keep consistent:**
- Past days (offset < 0) are **read-only for adds** — check-off / edit / delete still allowed, but `addTodo` is blocked (`canEditActiveDay = dayOffset >= 0`). This protects the 5-tasks-per-calendar-day cap.
- Today **and tomorrow** accept new tasks — tomorrow is the "plan ahead" case the user asked for.
- Only **today** auto-materializes an empty `DailyTodos` Hive record; browsing an empty yesterday/tomorrow writes nothing. Future/past records are created only on first mutation.
- Hive key is always `dayKey(activeDate)` where `activeDate = midnight(today) + dayOffset`. Adds persist to the active day's key (add on tomorrow → tomorrow's key), never today's.
- Midnight rollover timer and app-resume both snap `dayOffset` back to 0.

**Why:** the 5/day limit must stay honest per calendar day, and a shared `DailyTodoController` (permanent) is also read by the Home header progress bar, so wrong-day writes would corrupt both surfaces.
