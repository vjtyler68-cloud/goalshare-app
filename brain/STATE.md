# STATE — tracked & deferred

> Medium-cadence memory (review ~weekly or at each milestone). The **board** of what's
> active, what's parked, and the current facts. When something in [[LOG]] proves durable,
> promote it here. When a tracked item ships, move it to "Done" with a date.

## Current facts (verify before relying)

- **Version**: `pubspec.yaml` = `1.3.0+13`. Build 13 uploaded to TestFlight (Complete).
- **Next build** = 14: must bump to `1.3.0+14` and will include the `AppSnackBar` fix
  (already committed locally as `6f765eb`, not yet pushed/built).
- **Immediate blocker**: TestFlight "redeem code" → internal group **"Testing 001" has
  0 testers**. Add `vjtyler68@gmail.com` as a tester to unblock install.
- **Backend host drift** ⚠️: memory says `api.goalsharewin.com`; an earlier session note
  said `https://goalshare-backend-production.up.railway.app/api/v1`. **Confirm the real
  one** in `lib/core/network_caller/endpoints.dart` before trusting either.
- **Browser automation**: Playwright driver scaffolded in `C:\flutter\pw-driver\`
  (`serve.js` = long-lived Chrome w/ persistent profile + CDP :9222; `act.js` = attach &
  act). Pending Node install (winget). User logs in once; Claude drives after.

## Tracked (active — work these next)

1. **Get Build 13 onto a phone** → add tester to "Testing 001" → install → confirm it
   launches without crashing. This is the gate for everything else (first real crash
   signal since the fixes).
2. **Finish Playwright driver** → Node install → `npm i` in `pw-driver` →
   `npx playwright install chromium` → run `serve.js` → user logs in → drive ASC.
3. **If Build 13 still crashes**: pull the symbolicated crash log from App Store Connect
   (build → Crashes tab) and fix the *actual* cause, then ship Build 14.
4. **Bundle Google Fonts** in `assets/` + `pubspec.yaml`; stop runtime HTTP font fetch.

## Deferred (backlog — someday / not now)

- Android: fix Codemagic keystore upload (binary `goalshare.keystore`, not base64 txt);
  set up Google Play internal testing (needs 12 testers for production).
- App Store public release: screenshots, description, privacy policy URL, age rating.
- Migrate network layer to `network_config_v2.dart`; adopt repository pattern (examples
  already in `lib/core/data/repositories/`).
- Add tests (none exist). Implement token-refresh flow. Implement dark mode.
- Backend: rotate exposed `.env` secrets (Stripe, DB, Cloudinary, DO Spaces, JWT); add
  rate limiting on auth endpoints.
- Dashboard: confirm Authorization `Bearer` header in RTK Query `baseApi.ts`.

## Done (shipped — newest first)

- 2026-06: Build 13 — auto encryption-compliance (Info.plist), dep caching, push trigger.
- 2026-06: Three-layer launch crash hardening (see [[CLAUDE]] crash-safety contract).
- 2026-06: `AppSnackBar` hardened against launch-time throws (`6f765eb`, awaiting build).
- earlier: security/cleanup pass — secure-storage tokens, removed stored passwords,
  Bearer fixes, AppSnackBar everywhere, optimistic deletes w/ rollback across many
  controllers (auth, home, mission, budget, vision, nudges, profile).
