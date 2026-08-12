# 🤖 GoalShare — Google Play Launch Kit

Android/Play-Console counterpart to `LAUNCH_KIT.md` (which covers iOS/App Store).
App already exists in Play Console (package **`com.goal.share`**) with internal +
closed testing tracks. This kit is everything needed to finish the listing and
push the current build (1.6.1+189) toward production.

---

## 1. Privacy policy — ✅ DONE (live)

**Privacy policy URL** (paste in Play Console → Policy → App content → Privacy policy):
```
https://goalshare-backend-production.up.railway.app/privacy
```
Live now (HTTP 200), Android-accurate. (A prettier `goalsharewin.com/privacy.html`
can replace it later — same content — but this one is valid and unblocks you today.)

---

## 2. Store listing copy — paste into Play Console → Grow → Store listing → Main store listing

**App name (30 chars max):**
```
GoalShare: Daily Goal Tracker
```

**Short description (80 chars max):**
```
Goals, habits, budget & nutrition — your whole success routine in one app.
```

**Full description (4000 chars max):**
```
Your goals deserve a system, not just an app.

GoalShare brings your entire success routine into one place — so every morning starts with intention and every day ends with progress.

🔥 MORNING PRIMING
Start each day with a guided priming ritual. Build a daily streak and share it with the world.

✅ TODAY'S 5 TASKS
Five tasks a day. No endless lists, no overwhelm. Finish late? Flip back to yesterday and still check it off.

🎯 GOALS & MISSIONS
Set your missions, break them into steps, and track your wins.

💰 MY BUDGET
Simple envelope budgeting that lives on your device. Log spending, crush debts, celebrate pay-offs.

🥗 NUTRITION
Log meals, scan barcodes, and track calories, macros and weight over time.

📖 BIBLE & GRATITUDE
Read scripture, highlight verses, and keep a daily gratitude journal.

🤝 LEADS
For the closers: keep your contacts, set follow-up reminders, and never let a lead go cold.

💪 MY WHY & AFFIRMATIONS
Write down the reasons you grind — and see them every day.

🤝 FRIENDS & ACCOUNTABILITY
Add friends, share your streak, and stay accountable together.

Your future is built daily. Start today.
```

**App category:** Productivity (primary). Health & Fitness is a fine alternative.
**Tags:** goal setting, habit tracker, planner, budget, motivation.
**Contact email:** support@goalsharewin.com
**Website (optional):** https://goalsharewin.com

---

## 3. Graphics — Play requirements (different from Apple)

| Asset | Spec | Status |
|---|---|---|
| **App icon** | 512×512 PNG, 32-bit | ✅ **DONE** → `play_assets/icon-512.png` |
| **Feature graphic** | **1024×500** PNG/JPEG | ✅ **DONE** → `play_assets/feature-graphic-1024x500.png` |
| **Phone screenshots** | 2–8, PNG/JPEG, 9:16 portrait, each side 320–3840 px | ☐ Need device/emulator — capture the scenes below. |
| Tablet screenshots | Optional | Skip for v1 unless targeting tablets. |

Screenshot scenes (portrait, best-looking data on screen):
1. Home (streak card + tasks 4/5 done)
2. Priming screen (streak chip visible)
3. My Budget (envelopes with money)
4. Nutrition dashboard
5. Leads list (a few leads with statuses)
6. Bible or Gratitude journal

---

## 4. App content declarations — Play Console → Policy → App content

Complete each section (this is the "Set up your app" checklist):

- **Privacy policy:** URL from §1.
- **App access:** "All functionality is available without special access" is FALSE
  (login required). Provide test credentials so Google can review:
  > Demo — Email: goalshare25@gmail.com  Password: Growth2026
  > (Signup also works with any email; verification code is emailed.)
- **Ads:** No, this app does not contain ads.
- **Content rating (IARC questionnaire):** Category: Utility/Productivity.
  Answer **No** to violence, sexual, drugs, gambling, etc.
  ⚠️ The app HAS chat/friends (user-to-user communication + shared content) — answer
  **Yes** to "Do users interact or share content / can they communicate?" This is
  honest and typically results in a **Teen** rating for the social feature; that's fine.
- **Target audience & content:** Target age **13+** (select 13-15, 16-17, 18+).
  App is NOT directed to children under 13 (matches privacy policy). This keeps it
  out of the Families program / Play's child-privacy requirements.
- **News app:** No.
- **COVID-19 contact tracing/status:** No.
- **Data safety:** see §5.
- **Government app:** No.
- **Financial features:** The budget is a personal money-tracker (no payments/loans/
  crypto) → answer No to the regulated-financial-product questions.

---

## 5. Data safety form — Play Console → Policy → App content → Data safety

**Does your app collect or share user data?** Yes.
**Is all data encrypted in transit?** Yes.
**Do you provide a way to request data deletion?** Yes — in-app (Profile → Delete
Account) and by email. Provide the deletion URL/email: support@goalsharewin.com.

Data types to declare (Collected = sent off device to your Railway server):

| Data type | Collected | Shared | Purpose | Required? |
|---|---|---|---|---|
| Personal info → Name | Yes | No | App functionality, Account management | Required |
| Personal info → Email address | Yes | No | App functionality, Account management | Required |
| Photos → Photos | Yes | No | App functionality (profile photo) | Optional |
| App activity → Other user-generated content (goals, journal, chat) | Yes | No | App functionality | Optional |
| App info & performance → Crash logs | Yes | No | App functionality (stability) | Optional |
| App info & performance → Diagnostics | Yes | No | App functionality | Optional |

Do NOT declare (stays on device / not collected on Android): budget, nutrition logs,
daily tasks, leads, streaks, Bible highlights. Do NOT declare Health data unless the
Android build actually reads Health Connect (iOS-only today — verify before ticking).
No advertising, no data sold/shared with third parties.

---

## 6. In-app purchases — Play Console → Monetize → Products → Subscriptions

The app looks up product ID **`monthly`** (see `premium_service.dart`). Create it:

1. Create a **subscription** with product ID: `monthly`
2. Name: "GoalShare Pro Monthly"
3. Add a **base plan** (auto-renewing, monthly) — price e.g. **$9.99/mo**
   - Optional: add a **7-day free-trial offer** on the base plan.
4. Activate the subscription.
5. To test: add your Google account as a **License tester**
   (Play Console → Setup → License testing) so purchases are free/sandboxed.

⚠️ Note: iOS uses `com.goal.monthly` / `com.goal.yearly`, but the Android code
currently requests just `monthly`. Keep the Play product ID exactly `monthly`
(or update `premium_service.dart` if you prefer a namespaced ID).

---

## 7. Release flow (once the signed .aab is built)

1. **Internal testing** track → Create new release → upload `app-release.aab`
   (versionCode 189). Add yourself as an internal tester → install on a real device.
2. Smoke test: login, core tabs, chat, paywall/subscription, notifications.
3. Promote → **Closed testing** (already have a track) if you want wider testing.
4. Complete all §4/§5 declarations (Play blocks production until they're green).
5. Promote to **Production** → Google review (hours-to-days for a first prod release).

---

## Status snapshot (2026-08-11)
- ✅ Privacy policy live
- ✅ Firebase Android app registered + wired
- ⏳ Signed .aab building (fixing first-time Android build issues)
- ☐ Finish App content + Data safety (§4/§5)
- ☐ Create `monthly` subscription (§6)
- ☐ Feature graphic + Android screenshots (§3)
- ☐ Upload build → internal testing → production
