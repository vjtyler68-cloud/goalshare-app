# LOG — append & review

> **Karpathy append-and-review.** One running note. **Newest at the top.** Whenever
> anything happens — an idea, a fix, a blocker, a TODO, a decision — prepend a dated
> line. Old entries sink under gravity. Periodically skim; **rescue** anything still
> live by copy-pasting it back to the top (or promote it into `STATE.md`). Rarely delete
> — irrelevant things just sink. `Ctrl+F` is the index.
>
> Format: `## YYYY-MM-DD` headers, newest first. Tags: `todo:` `blocked:` `decision:`
> `fix:` `idea:` for easy search. Cross-link with `[[STATE]]` / `[[DECISIONS]]`.

---

## 2026-06-16

- fix: **UNBLOCKED TestFlight** — added tester `vjtyler68@gmail.com` to internal group
  "Testing 001" (was 0 testers → redeem-code prompt). Done autonomously via the
  Playwright driver. Group has all 6 builds; internal testers install without review.
- decision: Playwright driver WORKS end-to-end (Node v24 portable at `C:\flutter\node`,
  winget install had hung ~25min so bypassed with the official zip). `serve.js` =
  long-lived Chrome + CDP :9222 w/ persistent profile (already ASC-authenticated);
  `act.js` goto/click/fill/text; `probe.js` dumps links/buttons. This is how Claude
  drives the browser now (computer-use Chrome is read-only).
- finding: crash feedback exists ONLY for builds 7 & 8 ("immediate crash"), device
  iPhone 15 Pro Max / iOS 26.5. **No crashes logged for 10–13 (never installed).**
  Symbolicated stack trace is Mac-only ("Open in Xcode") — not readable on Windows.
  → Only way to verify the fixes is to install Build 13 now. blocked: needs the user
  to install on the phone.
- decision: built the second brain — `CLAUDE.md` + `brain/{LOG,STATE,DECISIONS}.md`.
  Layered cadence: LOG every session, [[STATE]] ~weekly, [[DECISIONS]] only on
  fundamental learnings. Supersedes the old verbose INDEX/FINAL_SUMMARY docs.
- todo: install Node (winget, in progress) → Playwright driver in `C:\flutter\pw-driver`
  so Claude can drive the browser autonomously (Chrome is read-only to computer-use).
- fix: hardened `AppSnackBar` — whole body in try/catch (commit `6f765eb`, local, NOT
  yet in a build). Rides along with the next build.
- idea: bundle Google Fonts in assets to kill the runtime HTTP font fetch at launch.

## 2026-06-13 → 06-15

- blocked: TestFlight shows "redeem code" → root cause: internal group **"Testing 001"
  has 0 testers**. Fix = add `vjtyler68@gmail.com` to the group. NOT a build problem.
- fix: Build 13 — added `ITSAppUsesNonExemptEncryption=false` to Info.plist so the App
  Store Connect encryption-compliance prompt is answered automatically.
- fix: added Codemagic dependency cache (`~/.pub-cache`, `ios/Pods`) → builds dropped
  from ~15 min to ~6 min. Added push-trigger on `main` (auto-trigger unreliable so far —
  still needs a manual "Start new build" click sometimes).
- fix: Builds 11/12/13 — kept bumping `+build` because Apple rejects duplicate build
  numbers ("previousBundleVersion" / DUPLICATE entity error).
- fix: Build 10/11 crash-hardening — `runZonedGuarded` + `FlutterError.onError` +
  `initHive()` try/catch in `main.dart`; `AppSizes` safe defaults (no `late`);
  no-internet navigation guard. See crash-safety contract in [[CLAUDE]].
- decision: confirmed Flutter **cannot** run on iPhone from Windows (no macOS/Xcode).
  iOS testing path is Codemagic → TestFlight only.

## earlier (pre-06-13, from prior review)

- Large controller/security cleanup pass: secure-storage tokens, removed stored
  passwords, Bearer prefix fixes, AppSnackBar everywhere, optimistic deletes with
  rollback. Full list lives in `brain/STATE.md` → "Done".
