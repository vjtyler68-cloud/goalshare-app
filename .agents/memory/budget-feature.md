---
name: My Budget feature
description: My Budget is local-first (Hive JSON, integer cents) — backend budget model is too thin to use.
---

# My Budget (local-first envelope budget)

The **My Budget** feature (`lib/features/mybudget/`) is **on-device only** (Hive `Box<String>`,
one JSON blob per month keyed "YYYY-MM" in box `budget_v1`). It does **not** use the
backend `/budget/*` endpoints.

**Why:** the backend budget model is too thin to fix (single `targetAmount`; income
`{name,amount}`; expense `{name,totalAmount}`; **whole dollars only**) and the backend
is not editable from this repl. Precedent: Leads/Nutrition/Gratitude/To-Do are all local.

**How it's built:**
- Pure-Dart JSON models in `data/budget_models.dart` (Leads pattern — NO Hive TypeAdapters/codegen),
  tolerant `fromMap`, all money as **integer cents** (`parseDollarsToCents`, `fmtCents`).
- `data/budget_store.dart` wraps the box with the isReady/graceful-degrade pattern.
- `MyBudgetController` / `MyBudgetScreen` class names + file paths kept so routes
  (`/myBudget`) and `bindings.dart` lazyPut stay valid.
- Model: income sources, savings goals (savings/investing/crypto), debt payoff,
  fixed bills + variable envelopes (weekly ×4 buckets or flat). Month carry-forward
  clears transactions but keeps budgets/targets and rolls unpaid debt.

**Gotcha:** `num.clamp(...)` returns `num` — when the result feeds a typed `int`/`double`
slot (model cents, `CircularProgressIndicator.value`, `FractionallySizedBox` factors),
append `.toInt()`/`.toDouble()` or the Codemagic analyzer errors. No local Dart here, so
this only surfaces at build time.
