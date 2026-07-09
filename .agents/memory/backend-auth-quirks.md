---
name: GoalShare backend auth & upload quirks
description: Non-obvious behaviors of the Railway backend around JWT auth headers, error status codes, and multipart uploads.
---

# GoalShare Railway backend quirks

Backend is a separate Railway service (NOT in this repo): `goalshare-backend-production.up.railway.app/api/v1`. Only compiled JS is deployed, so fixes must be app-side.

## Authorization header: send the RAW JWT, no "Bearer " prefix
The auth middleware passes the **entire** `Authorization` header value straight into `jwt.verify()` without stripping `Bearer `. Verified against the live API:
- `Authorization: Bearer <valid-jwt>` → `{"success":false,"message":"invalid token"}`
- `Authorization: <valid-jwt>` (raw) → gets past parsing to signature check

**How to apply:** every authenticated request must set `headers['Authorization'] = token;` (raw), never `'Bearer $token'`. Applies to normal and multipart requests.

## Auth error status codes are inconsistent
- **Missing** token → HTTP **401** `"You are not authorized!"`
- **Invalid/expired/malformed** token → HTTP **500** with `{"success":false,"message":"invalid token" | "jwt expired" | "jwt malformed"}`

**Why it matters:** handling only HTTP 401 lets an expired token slip through as a raw "invalid token" message, stranding the user on a logged-in screen (manual sign-out/in loop). The app's network layer detects JWT-verify error messages on ANY status and forces a clean re-login. Match only JWT-library messages (`invalid token`, `jwt expired`, `token expired`, `jwt malformed`) — NOT generic words like `unauthorized`/`invalid signature`, which can appear in legit business/payment errors. Do not treat 403 (forbidden) as a session expiry.

## In-app YouTube playback (priming screen)
Uses `youtube_player_iframe` (v5). On iOS the embed runs in a WKWebView that has no page origin, so YouTube's IFrame API can fail to initialize and the WebView falls back to the YouTube homepage (Home/Shorts/You bar visible = this failure, NOT the embed). Fix: set `YoutubePlayerParams(origin: 'https://www.youtube.com', playsInline: true)`. Video id lives in `kPrimingVideoId`. Confirm a video is embeddable via `https://www.youtube.com/oembed?url=...&format=json` before debugging code. In-app WebView playback CANNOT be verified from the container (only real iOS/TestFlight), so a guaranteed `url_launcher` "Watch on YouTube" fallback (external launch of `youtube.com/watch?v=<id>`) was added alongside the embed so the feature always works. Launching an https URL externally needs NO `LSApplicationQueriesSchemes` entry.

## ADMIN role is blocked (403) from user-scoped `/global/*` feature routes
`POST /global/mywhy` (and siblings) are gated to regular USER accounts. An ADMIN-role account (the app special-cases `role == 'ADMIN'`) gets HTTP **403 "Forbidden!"** even with a valid token — the app code is correct, this is a backend role guard. Diagnose "Forbidden!" toasts by checking the logged-in account's role before touching app code; test personal features with a normal user, not the admin account.

## Home "My Why" / "Affirmation" endpoint paths (verified against live API)
Create/get/delete use INCONSISTENT paths — verify with a `curl` probe (no token → 401 = route exists, 404 = wrong path) before trusting the constants:
- My Why: create/get/delete all `/global/mywhy` (delete appends `/:id`).
- Affirmation: create `/global/affirmation`; get + delete `/global/affirmation/my-affirmation` (delete appends `/:id`). NOTE create path differs from get/delete. (`/global/my-affirmation` is a 404 — was a bug.)

## Multipart uploads: never set Content-Type manually
For `http.MultipartRequest`, do NOT add `'Content-Type': 'multipart/form-data'` to headers. The http package auto-generates it WITH the required `boundary=...` on `send()`; a manual header strips the boundary and the server can't parse the body — the upload fails (often silently if there's no error branch). Set only `Authorization`. Vision board upload hit exactly this bug.

## Vision board `year` field: send ISO, parse defensively
Create sends `data` JSON with `year` — must be ISO-8601 (`DateTime.toIso8601String()`), NOT a human format like "dd MMMM yyyy". The model does `DateTime.parse(json['year'])`; a non-ISO value throws and (inside `assignAll(list.map(...))`) blanks the ENTIRE board, so saved items never appear = looks like "won't save". Model now uses `DateTime.tryParse` so one bad record can't nuke the list. Multipart `send()` also given a 30s timeout so flaky network doesn't hang the spinner forever.

## HomeMyWhyModel (shared by My Why + Affirmations): tryParse timestamps
My Why and Affirmations both use `HomeMyWhyModel` and POST `{'text': ...}`. Its `fromJson` must use `DateTime.tryParse` for createdAt/updatedAt — with `DateTime.parse`, a non-ISO timestamp threw: on CREATE success the code does `fromJson(response['data'])`, so the throw fell into the catch and showed "Something went wrong" DESPITE a successful save (false negative), and the GET list load threw too. Same failure pattern as the vision board `year` field. Endpoints verified: create `/global/affirmation`, get/delete `/global/affirmation/my-affirmation`. Admin accounts still get 403 on these (backend role gate) — create path surfaces that message; GET stays silent by design (runs on every home init).
