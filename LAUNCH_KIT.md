# 🚀 GoalShare — App Store Launch Kit

Everything needed to go from TestFlight to the App Store. Items marked **[VJ]**
need Vincent's accounts; everything else is done.

---

## 1. Host the legal pages — [VJ] ~10 min

Files ready in `site/`:
- `site/privacy.html` → upload to Hostinger so it's live at **https://goalsharewin.com/privacy.html**
- `site/terms.html`   → **https://goalsharewin.com/terms.html**

How: hostinger.com → hPanel → **Files → File Manager** → `public_html` → Upload both files.
(Optional: create the `support@goalsharewin.com` mailbox in hPanel → Emails, or set it to forward to vjtyler68@gmail.com.)

---

## 2. App Store listing copy — paste into App Store Connect

**Name (30 chars max):** `GoalShare: Daily Goal Tracker`

**Subtitle (30 chars max):** `Habits, Budget & Motivation`

**Promotional text (170 chars, updatable anytime):**
> Prime your morning, crush your 5 daily tasks, and keep your streak alive. Goals, budget, nutrition & motivation — your whole system in one app. 🔥

**Description:**
```
Your goals deserve a system, not just an app.

GoalShare brings your entire success routine into one place — so every
morning starts with intention and every day ends with progress.

🔥 MORNING PRIMING
Start each day with a guided priming ritual. Build a daily streak and
share it with the world.

✅ TODAY'S 5 TASKS
Five tasks a day. No endless lists, no overwhelm. Finish late? Flip back
to yesterday and still check it off.

🎯 GOALS & MISSIONS
Set your missions, break them into steps, and track your wins.

💰 MY BUDGET
Simple envelope budgeting that lives on your device. Log spending,
crush debts, celebrate pay-offs.

🥗 NUTRITION
Log meals, scan barcodes, track calories and weight — synced with your
daily energy from iPhone and Apple Watch.

📖 BIBLE & GRATITUDE
Read scripture, highlight verses, and keep a daily gratitude journal.

🤝 LEADS
For the closers: keep your contacts, set follow-up reminders, and never
let a lead go cold.

💪 MY WHY & AFFIRMATIONS
Write down the reasons you grind — and see them every day.

Your future is built daily. Start today.
```

**Keywords (100 chars max, comma-separated, no spaces):**
```
goal,habit,streak,daily,planner,budget,motivation,discipline,routine,tracker,affirmation,priming
```

**Support URL:** `https://goalsharewin.com`
**Marketing URL:** `https://goalsharewin.com`
**Privacy Policy URL:** `https://goalsharewin.com/privacy.html`

**App Review notes (paste in the review information box):**
> Demo account — Email: goalshare25@gmail.com  Password: Growth2026
> Sign-up also works with any email; the verification code is emailed.

**Category:** Primary: Productivity · Secondary: Health & Fitness
**Age rating questionnaire:** answer "None" to all sensitive content → results in 4+.
(If the Bible feature triggers a question about "unrestricted web access" — it does not; answer No.)

---

## 3. App Privacy form answers — [VJ] ~15 min (App Store Connect → App Privacy)

Data collection: **Yes, we collect data.**

| ASC Category | Collect? | Linked to user? | Tracking? | Purpose |
|---|---|---|---|---|
| Contact Info → Email Address | ✅ | Yes | No | App Functionality (account) |
| Contact Info → Name | ✅ | Yes | No | App Functionality |
| User Content → Photos or Videos | ✅ | Yes | No | App Functionality (profile/lead photos) |
| User Content → Other User Content | ✅ | Yes | No | App Functionality (goals, journal, notes) |
| Health & Fitness → Health | ✅ (once HealthKit ships) | Yes | No | App Functionality |
| Identifiers / Location / Browsing / Purchases history / Diagnostics | ❌ Not collected | — | — | — |

**Tracking (ATT):** No — the app does not track users across other companies' apps/websites. No IDFA.

---

## 4. Create the subscriptions — [VJ] ~30 min (ASC → Monetization → Subscriptions)

1. Create Subscription Group: `GoalShare Pro`
2. Add two auto-renewable products:
   - `com.goal.monthly` — "GoalShare Pro Monthly" — **$9.99/mo**
   - `com.goal.yearly`  — "GoalShare Pro Yearly"  — **$59.99/yr**
3. On each: add an **Introductory Offer → Free Trial → 7 days** (start date today, no end date).
4. Localization (English): Display name + one-line description, e.g.
   "Unlock everything: goals, budget, nutrition, leads, and more."
5. **Review screenshot** for each product: any screenshot of the paywall screen.
6. In **App Information → License Agreement**: leave standard EULA; put the
   Terms link (goalsharewin.com/terms.html) in the app description footer or paywall (already linked in-app).

---

## 5. Launch-day switches (DO THESE, in order, right before submitting)

1. ☐ Email provider live (finish Brevo verification OR Resend + Hostinger DNS; set `RESEND_API_KEY` or `BREVO_API_KEY` in Railway)
2. ☐ Verify a REAL signup email arrives (I can test in 2 sec)
3. ☐ Railway: **delete `AUTO_VERIFY_SIGNUPS`** (kills static-123456 codes, auto-subscriptions, unverified logins)
4. ☐ Railway: change `SUPER_ADMIN_PASSWORD` from `123456` to something strong (admin@gmail.com password)
5. ☐ Rotate backend secrets exposed in the old .env (JWT secret, Stripe, Cloudinary, DO Spaces)
6. ☐ MongoDB Atlas: narrow Network Access from 0.0.0.0/0 to Railway egress IPs
7. ☐ Final build with the launch config → TestFlight smoke test → **Submit for Review**

---

## 6. Screenshots — [VJ] ~30 min

Apple needs 6.9" (iPhone 15 Pro Max size) screenshots, 3–10 of them. Take these
in the app (portrait), best-looking data on screen:
1. Home (streak card + tasks 4/5 done)
2. Priming screen (streak chip visible)
3. My Budget (envelopes with money in them)
4. Nutrition dashboard
5. Leads list (a few leads with statuses)
6. Bible or Gratitude journal

Just screenshot on your iPhone (same size class) — no design tool needed for v1.
```
