---
name: Codemagic config source (UI editor vs codemagic.yaml)
description: How to tell which config source Codemagic actually uses, and why codemagic.yaml edits sometimes do nothing.
---

# Codemagic: UI Workflow Editor vs codemagic.yaml

Codemagic runs a build from **one** config source: either the **UI Workflow Editor** (settings in the Codemagic dashboard) OR the repo's **codemagic.yaml**. Only one is active per workflow. If the UI editor is selected, **every edit to `codemagic.yaml` is ignored** — including Xcode version, build-number logic, and signing.

**The tell (how to know which is active without dashboard access):** look at the uploaded build number and Xcode version in the build log.
- `codemagic.yaml` here sets build number to a Unix timestamp (`date +%s`, ~1.78 billion). If the uploaded build number is a small integer (e.g. 40), the yaml did NOT run → **UI editor is active**.
- Same logic for Xcode: yaml says `latest`; if the log shows an old pinned Xcode (e.g. 16.4), the yaml isn't being used.

**Why it matters:** many hours were lost editing `codemagic.yaml` (auto-increment, Xcode version) while the UI editor was the real source, so nothing changed. Settings must be changed in whichever source is active.

**How to apply:** Before editing `codemagic.yaml` to fix a build, confirm it's the active config source (in Codemagic UI: workflow → Configuration, set to "codemagic.yaml"). Switching to yaml as the source also permanently fixes build-number collisions (the timestamp step runs). Only the user can flip this in the dashboard.

## Apple iOS SDK floor
Apple rejects uploads (409 STATE_ERROR.VALIDATION_ERROR) built with an SDK below its current floor — e.g. "must be built with the iOS 26 SDK or later (Xcode 26+)". Fix = bump Xcode in the *active* config source. Old Xcode pins (added to dodge Flutter lifecycle crashes) become dead ends when the floor rises; current stable Flutter handles new iOS lifecycles, so the pin's original reason is usually already moot.
