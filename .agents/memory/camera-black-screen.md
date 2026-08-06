---
name: Camera black screen root cause
description: Why both mobile_scanner screens went black despite run=true/perm=true — custom pre-warmed FlutterEngine broke external-texture compositing.
---

Both scanners (nutrition barcode + QR Connect) showed black/blank while the camera reported `isRunning=true`, `hasCameraPermission=true`, valid frame size, no error.

**Root cause:** the camera preview is a Flutter EXTERNAL TEXTURE. A hand-rolled pre-warmed FlutterEngine in SceneDelegate (FlutterViewController hosted as a child VC) stopped external textures from compositing. The same custom engine also broke SafeArea top inset (reported 0) and firebase_messaging auto-registration.

**Fix:** revert AppDelegate + SceneDelegate + Info.plist to the framework-managed implicit-engine default (`flutter create` layout, FlutterViewController from Main.storyboard as window root). Keep the APNs→FCM bridge in AppDelegate; recreate MethodChannels on the implicit engine.

**Why:** wasted a full day of guessing (permissions, mobile_scanner version, lifecycle stops) because the failure layer was rendering, not the camera session.

**How to apply:** if a camera/video preview is black while the session reports running, suspect the engine/texture-compositing layer first — check for custom FlutterEngine hosting before touching plugin code. The always-on `cam: run/perm/size/err` diag line added to both scanner screens was the tool that isolated it; remove it once scanners are confirmed working (or reuse the pattern for future texture bugs).
