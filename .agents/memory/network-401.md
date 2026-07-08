---
name: Network 401 Auto-Logout
description: How both network configs handle expired sessions — clear storage and redirect to login.
---

# Network 401 Auto-Logout

## The rule
Both `NetworkConfig` (v1) and `NetworkConfigV2` clear the user's stored token and navigate to `/login` when the server returns 401.

**Why:** Before this was added, a 401 only showed a snackbar. Users stayed on authenticated screens with a dead session, causing cascading failures on every subsequent request.

## How to apply

**NetworkConfig (v1):** `network_config.dart` — synchronous, uses `await LocalService().clearUserData()` then `Get.offAllNamed(AppRoutes.loginScreen)` inside the response handler (which is already async).

**NetworkConfigV2:** `network_config_v2.dart` — `_handleResponse` is **sync**, so logout is done via `Future.microtask(() async { ... })` to avoid calling Get navigation from within a synchronous response parse. This is safe because the `UnauthorizedException` is thrown immediately after scheduling the microtask.

## Important
Never call `Get.offAllNamed` synchronously inside `_handleResponse` in V2 — the method is sync and the navigator isn't ready mid-parse. Always use `Future.microtask`.
