---
name: Network reliability / retry policy
description: How transient backend failures are handled client-side, and the strict no-retry-on-writes rule.
---

# Backend reliability (client side)

The Railway backend throws transient failures (cold-start / dyno wake → HTTP
502/503/504 often as HTML, plus connection resets and 429). These are handled by
a shared `RetryPolicy.run(action, {idempotent})` (`lib/core/network_caller/retry_policy.dart`)
wired into BOTH `NetworkConfig` (v1) and `NetworkConfigV2` — without changing any
call-site signatures (there was no local Flutter compile, so keeping signatures
identical is the safety mechanism).

## The hard rule: NEVER auto-retry non-idempotent requests
Only GET (`idempotent: true`) is retried (on Socket/Timeout/ClientException +
429/502/503/504, exp backoff+jitter, 3 attempts). POST/PUT/PATCH/DELETE fail fast.
**Why:** the backend has no idempotency-key/dedupe, and a `SocketException` can
fire *after* the write reached the server — so retrying a write risks duplicating
it (double lead, double mission, etc.). **How to apply:** if you ever want write
retries, add an `Idempotency-Key` header + server-side dedupe first, then flip the
policy — do not loosen it blindly.

## Other foundation notes
- `TimeoutException` name clash: `lib/core/error/exceptions.dart` defines its OWN
  `TimeoutException`. Keep `dart:async` OUT of the two network_config files (they
  rely on the custom one via generic catch); only `retry_policy.dart` imports
  `dart:async` and it must NOT import exceptions.dart.
- Connectivity probe must be fail-open with a ~4s timeout (raw
  `InternetConnectionChecker.hasConnection` can hang on iOS). Both v1 and v2 do
  this now; don't reintroduce a bare `await ...hasConnection`.
- `NetworkConfig.warmUp(url)` is a fire-and-forget ping from `main.dart`'s
  post-frame callback to wake the Railway dyno during splash.
- Two network layers still coexist (v1 ~29 callers returning Map?/null+snackbar,
  v2 ~6 callers throwing typed exceptions). Merging them is a separate, riskier
  refactor — not done.
