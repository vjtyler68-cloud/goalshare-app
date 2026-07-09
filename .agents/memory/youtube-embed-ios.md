---
name: YouTube embed on iOS (priming video)
description: Why hand-rolled WKWebView YouTube embeds fail on iOS and what actually works
---

# YouTube embed inside the app (Priming / Morning Ritual)

Playing a YouTube video in an in-app WebView on iOS repeatedly failed. Two hand-rolled `webview_flutter` approaches each produced a different YouTube error:

- **`loadHtmlString` + `baseUrl` → Error 152.** iOS WKWebView does NOT grant `loadHtmlString` content the network origin of `baseUrl`; the page has an opaque/null origin, so the YouTube IFrame API rejects it.
- **`loadRequest` directly to `https://www.youtube.com/embed/<id>` (top-level document) → Error 153 ("Video player configuration error").** A top-level embed load sends no HTTP `Referer`, which YouTube's embed player requires.

**What works:** the dedicated `youtube_player_iframe` package. It renders the IFrame player inside a real iframe with a proper origin/referrer and manages iOS inline playback. Do not try to re-hand-roll WKWebView for YouTube.

**Why:** the failures are about origin/referrer that WKWebView won't fake for local/top-level content — not about player params.

**How to apply:**
- Keep `playsInline: true` (+ inline playback) so it stays in the card, `autoPlay: false`.
- No `YoutubePlayerScaffold` here, so hide the fullscreen button (it has nothing to drive); the external "Watch on YouTube" (`url_launcher`) button is the full-screen path and a guaranteed fallback.
- Version pin: package **5.2.x** needs Dart `^3.5.0` (app floor is `>=3.8.0`); 6.x needs Dart `^3.10.0` / Flutter `>=3.38.0` — only jump to 6.x if the Codemagic stable toolchain is new enough.
- `PrimingController` owns the native player: create it screen-scoped via `Get.put` in `PrimingScreen` and close it in `onClose()`. Do NOT also register it as a global `lazyPut(fenix:true)` binding — that keeps it alive for the whole session and leaks the player.
