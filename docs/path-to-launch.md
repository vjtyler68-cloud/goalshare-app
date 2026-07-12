# GoalShare — Path to Launch (Team Handoff)

**Last updated:** July 12, 2026
**Audience:** Whoever is helping build GoalShare (backend dev + AI teammate "Claude"). Written in plain language on purpose — you should be able to read this top to bottom and know exactly what to build and why.

---

## 0. TL;DR — read this first

GoalShare is already a **real, working app**. It has real accounts, a real server, cloud chat, and it builds and installs on iPhones. It is not a toy or a prototype.

What stands between "working app" and "safe to give to paying customers" is a short list of gaps. The **single most important one** is that a salesperson's **Leads (their customer list) are stored only on their phone** — not on the server. If they delete the app or lose the phone, those leads are gone forever. For a sales tool, the leads ARE the product, so this is priority #1.

The rest of this doc explains the app, then lists every remaining task in priority order, with enough detail that a developer (or Claude) can just start building.

---

## 1. What the app is

GoalShare is a mobile app for **door-to-door sales reps** that also includes **personal wellness tools**. Think of it as two things in one:

1. **A sales toolkit** — track leads/customers, set follow-up reminders, see analytics, run "missions" (daily sales goals).
2. **A personal growth toolkit** — budget tracker, nutrition/calorie tracker, journaling, Bible reading, affirmations, goal-setting, chat with other users.

It is a **paid app** — users are supposed to pay for a subscription to get in.

---

## 2. How the app is built (the 3 pieces)

There are **three separate systems**. It's important to know which piece each task belongs to, because they're owned/edited differently.

### Piece A — The phone app (Flutter)
- Written in **Flutter/Dart**. This is the code in this repository.
- Uses the **GetX** pattern for state management and navigation.
- This is the part the **Replit agent edits**.
- It is built into an installable iPhone app using **Codemagic** (a cloud build service). There is no way to compile it on the Replit machine — every change is verified by kicking off a Codemagic build and testing on a device.
- The app's build number lives in `pubspec.yaml` on the `version:` line (currently `1.5.0+86`). Bump it every release.

### Piece B — The server (Railway REST API) ← **this is Claude's / the backend dev's lane**
- A separate backend hosted on **Railway**.
- Base URL: `https://goalshare-backend-production.up.railway.app/api/v1`
- **The Replit agent CANNOT edit this backend.** Any task that says "new endpoint" or "server-side" must be done by the backend developer (or Claude, if Claude has access to the backend repo).
- Auth quirk to know: the app sends the **raw JWT token** in the `Authorization` header — **no `Bearer ` prefix.** Keep that convention.

**Endpoints that already exist today:**
| Area | Endpoints |
|---|---|
| Auth | `POST /auth/login`, `POST /auth/register`, `POST /auth/verify-email-with-otp`, `POST /auth/forget-password`, `GET /auth/verify-auth`, `POST /auth/logout` |
| Profile | `GET /user/me`, `POST /users/update-profile`, `POST /user/update-profile-image` |
| Budget | `GET /budget/my`, `POST /budget/target`, `POST /budget/{id}/income`, `POST /budget/{id}/expense` |
| Subscription | `GET /subscription/my-subscription`, `GET /subscription`, `POST /subscription/buy-plan` |
| Content | `GET/POST/DELETE /global/mywhy`, `GET/POST/DELETE /global/affirmation`, `GET/POST/PATCH /goals`, `GET/POST /vision`, `GET/POST /follow/*` |

### Piece C — Chat (Firebase Firestore)
- Real-time chat is powered by **Firebase Firestore** (Google's cloud database), separate from the Railway backend.
- Data lives in a `conversations` collection with a `messages` sub-collection.

### Where data lives today (very important)
Some data is on the **server** (safe, backed up, follows the user to any device). Some data is **only on the phone** (lost if the app is deleted or the phone is lost, and NOT shared between the user's own devices).

| Data | Where it lives now | Safe / backed up? |
|---|---|---|
| Account, login, profile | Server (Railway) | ✅ Yes |
| Chat messages | Firebase | ✅ Yes |
| Budget | Phone (partial server endpoints exist) | ⚠️ Partly |
| **Leads (customer list)** | **Phone only** | ❌ **No — biggest risk** |
| Nutrition / calories / weight | Phone only | ❌ No |
| Journal, daily to-dos, Bible highlights | Phone only | ❌ No |

"Phone only" storage uses a local database called **Hive**. The relevant Hive boxes are: `leads_v1`, `budget_v1`, `nutrition_entries`, `nutrition_goals`, `weight_entries`, `daily_todos_v1`, `gratitude_journal`, `bible_highlights`.

---

## 3. The launch task list (in priority order)

Each task below has: **What & why**, **Who owns it**, **Exactly what to build**, and **How we know it's done**.

---

### ⭐ TASK 1 — Save Leads to the server (stop losing customer data)

**What & why:**
Right now a rep's entire lead list lives only on their phone. Delete the app → leads gone. New phone → leads don't follow them. For a sales app this is the most serious gap. We need the leads to live on the server, so they're backed up and appear on any device the rep logs into.

**Who owns it:**
- **Backend dev / Claude:** build the new server endpoints (Piece B).
- **Replit agent:** change the phone app to read/write leads from those endpoints instead of only the local Hive box, and migrate any leads already on the phone up to the server the first time.

**Exactly what to build — new server endpoints (mount under `/api/v1`):**

All of these require the logged-in user's token and must **only ever return/modify that user's own leads** (scope every query by the authenticated user id on the server — never trust an id sent by the app for ownership).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/leads` | Return all of the current user's leads |
| `POST` | `/leads` | Create one lead |
| `PATCH` | `/leads/{id}` | Update one lead |
| `DELETE` | `/leads/{id}` | Delete one lead |
| `POST` | `/leads/sync` | (Optional but recommended) Accept an array of leads and upsert them — used once to push a phone's existing leads up to the server |

**The exact shape of a Lead** (this matches the app's data model exactly, so please use these field names):

```json
{
  "id": "string",
  "name": "string (required)",
  "phone": "string",
  "email": "string",
  "address": "string",
  "company": "string",
  "status": "one of: New | Contacted | Appointment | Won | Lost",
  "notes": "string",
  "reminderAt": "ISO-8601 datetime string, or null",
  "createdAt": "ISO-8601 datetime string",
  "updatedAt": "ISO-8601 datetime string"
}
```

Notes for the backend dev:
- `status` is one of exactly five values: `New`, `Contacted`, `Appointment`, `Won`, `Lost`. Reject or default anything else to `New`.
- `id` today is generated on the phone. Two safe options: (a) let the app keep generating the id and you store it, or (b) you generate a server id and return it. If you generate your own, return it in the response so the app can adopt it. Pick one and tell the app team.
- Timestamps are ISO-8601 strings (e.g. `2026-07-12T14:30:00.000`).
- **Photos:** each lead can have a photo, but the photo file currently lives on the phone only (the model just stores a file name). For version 1, **leave photos on the phone** — do NOT try to sync the image binary yet. If we want photos backed up later, add a `POST /leads/{id}/photo` upload that mirrors the existing `/user/update-profile-image` pattern. Call this a v2 follow-up.

**Exactly what to change in the phone app (Replit agent):**
- Update `lib/features/leads/controller/leads_controller.dart` so add/edit/delete also call the new endpoints, not just the local Hive box.
- Keep the local Hive box as an **offline cache** so the app still works with no signal, then sync when back online. (Reps are literally walking around outside — offline support matters.)
- On first launch after this ships, push any leads already in the local `leads_v1` box up to the server via `POST /leads/sync`, then mark them as synced so we don't duplicate.

**How we know it's done:**
- Add a lead on Phone A → log into the same account on Phone B → the lead is there.
- Delete and reinstall the app → leads come back after login.

---

### ⭐ TASK 2 — Keep each account's data separate on a shared phone

**What & why:**
Today, the "phone only" data (leads, budget, nutrition, journal, to-dos) is stored in one bucket per phone, **not per account**. So if two people log into the same phone, or you log out of the admin account and into a test account, you'd see the *other* person's leads/budget/etc. This is confusing and a privacy problem.

> Note: We just fixed a *related* bug where the **profile** was showing the previous account after switching (build 1.5.0+86). That fix was for the profile identity. This task is about the **on-device Hive data**, which is a separate storage layer and still shared across accounts.

**Who owns it:** Replit agent (this is all in the phone app).

**Exactly what to build:**
- Include the logged-in user's id in the name of each per-user Hive box, e.g. `leads_v1_<userId>` instead of `leads_v1`. Do the same for `budget_v1`, `nutrition_*`, `daily_todos_v1`, `gratitude_journal`.
- Leave truly shared/global caches (like `bible_cache`) alone — those aren't personal data.
- On logout, close the per-user boxes so nothing from the old account lingers.

**How we know it's done:**
- Log in as Account A, add a lead. Log out, log in as Account B → Account B sees an empty list, not A's lead. Log back into A → A's lead is still there.

**Ordering note:** Once Task 1 (leads on the server) is done, leads will naturally be per-account because the server scopes by user. So Task 2 mainly matters for the data that stays on the phone (budget, nutrition, journal, to-dos). Do Task 1 first, then Task 2 for the remaining local-only features.

---

### TASK 3 — Turn the real signup/paywall back on (fix email verification)

**What & why:**
New users are supposed to (1) sign up, (2) verify their email with a one-time code (OTP), and (3) pay for a subscription. Right now the **OTP verification email isn't sending**, so to keep testing we added a temporary "whitelist" that lets specific test emails (`goalshare25` and `goalshare25+anything@gmail.com`) skip the paywall. That whitelist is a **testing shortcut, not a real feature** — real customers can't get in until email works.

**Who owns it:**
- **Backend dev / Claude:** fix the email-sending service so `POST /auth/verify-email-with-otp` actually delivers the code (check the email provider / SMTP / API key config on Railway).
- **Replit agent:** once email works, remove the test-account whitelist bypass in `lib/core/utils/test_accounts.dart` so everyone goes through the normal signup + payment flow.

**How we know it's done:**
- A brand-new email address can sign up, receives the code, verifies, is asked to pay, and only gets in after paying — with no special-casing.

---

### TASK 4 — Lock down chat security

**What & why:**
Chat works, but the security is at "get it working" level (an MVP tradeoff). Before real users are messaging each other, we want to make sure people can only read/write their own conversations and can't be impersonated.

**Who owns it:** Whoever manages the Firebase project (likely the backend dev / Claude), with app-side support from the Replit agent.

**Exactly what to build:**
- Move chat identity onto real authenticated user ids (tie the Firebase user to the logged-in GoalShare account rather than a loosely-mapped local id).
- Add **Firestore security rules** so a user can only read/write conversations they're a participant in. Right now the protection is weaker than it should be.

**How we know it's done:**
- A user cannot read or write a conversation they're not part of, verified by testing the Firestore rules.

---

### TASK 5 — Finish Budget server sync

**What & why:**
Budget is in a half-and-half state: the server already has budget endpoints (`/budget/my`, `/budget/target`, etc.), but the app treats the phone as the main copy. We should make the server the source of truth so budgets are backed up and follow the user, the same as leads.

**Who owns it:** Replit agent (endpoints already exist), with backend dev confirming the endpoints cover everything the app stores (categories, goals, debts, transactions, income — all amounts are stored as **integer cents**, not dollars, to avoid rounding errors).

**How we know it's done:**
- Enter a budget on Phone A → see it on Phone B after login.

---

### TASK 6 — Decide what happens to Nutrition / Journal / To-dos

**What & why:**
These are personal-tracking features that currently live only on the phone. They're lower stakes than leads, but users would still be upset to lose months of food logs or journal entries. Decision needed: back them up to the server too, or explicitly accept that they're device-only.

**Who owns it:** Product decision first (you), then Replit agent + backend dev if we choose to sync.

Good news: **Nutrition needs no paid API** — food search and barcode lookup use the free **Open Food Facts** service, so there's nothing to pay for or swap out there.

**How we know it's done:**
- A clear decision is made and, if syncing, the same "works across devices / survives reinstall" test passes.

---

### TASK 7 — Pre-launch checklist (the boring but required stuff)

**What & why:** These are the things app stores and real users expect before a public launch.

- **Privacy policy + terms** (required by Apple/Google, especially since you collect customer contact data and health-ish nutrition data).
- **App Store / Play Store listing:** screenshots, description, icon, category, age rating.
- **Crash & error monitoring** (e.g. Firebase Crashlytics or Sentry) so you find out when the app breaks in the wild instead of hearing it from an angry user.
- **Data export / delete for users** (increasingly required by privacy law — a user can request their data or account deletion).
- **A real support contact** (email or in-app) for when something goes wrong.

**Who owns it:** Mostly you (product/business), with the Replit agent wiring in crash monitoring and any in-app legal links.

---

## 4. Suggested order of attack

1. **Task 1 — Leads to the server** (biggest risk, do first).
2. **Task 3 — Email/OTP + paywall** (you can't onboard real customers until this works; backend dev can do this in parallel with Task 1).
3. **Task 2 — Per-account data separation** for the remaining local-only features.
4. **Task 5 — Budget sync.**
5. **Task 4 — Chat security hardening.**
6. **Task 6 — Nutrition/journal/to-do decision.**
7. **Task 7 — Pre-launch checklist**, finished right before submitting to the app stores.

---

## 5. Two-lane summary (who does what)

**Backend dev / Claude (Railway server + Firebase):**
- Build the `/leads` endpoints (Task 1).
- Fix the OTP verification email (Task 3).
- Add Firestore security rules + real chat auth (Task 4).
- Confirm budget endpoints cover the full model (Task 5).

**Replit agent (this Flutter repo):**
- Wire the app's leads to the new endpoints + migrate on-device leads + keep offline cache (Task 1).
- Scope on-device Hive data per account (Task 2).
- Remove the test whitelist once email works (Task 3).
- Make the server the source of truth for budget (Task 5).
- Add crash monitoring + in-app legal links (Task 7).

**You (product/business):**
- Decide on Nutrition/journal syncing (Task 6).
- Privacy policy, terms, store listings, support contact (Task 7).
