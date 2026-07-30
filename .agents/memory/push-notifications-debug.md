---
name: Push notifications debugging saga
description: Root causes and dead ends for GoalShare push (FCM via Railway backend + iOS APNs)
---

## RESOLVED July 30, 2026 — push works end-to-end
The actual missing piece: Firebase Console → Cloud Messaging has **separate Development and
Production APNs key slots**; only Development was filled. TestFlight/App Store builds use the
production APNs lane → Apple rejected everything (`BadEnvironmentKeyInToken`). User uploaded a
fresh .p8 (key CRQKQ35WU7, team VWZJZBW99S) into BOTH slots → delivery confirmed on device.
**Rule: `/push/notify` body field is `toUserId` (NOT `userId`) — wrong field = silent 200 no-op.**
Pending cleanup: remove temp diag logging + `/push/debug` endpoint, sync stale `src/app/utils/fcm.ts` with dist.

## Final root cause (July 26, 2026)
FCM v1 send returns top-level 401 "Request is missing required authentication credential"
— that message is MISLEADING. The real cause is in `error.details[]`:
`FcmError THIRD_PARTY_AUTH_ERROR` + `ApnsError 403 BadEnvironmentKeyInToken`.
i.e. Google auth was ALWAYS fine; **Apple rejects the APNs key/environment combo**.
Fix lives in Firebase Console → Cloud Messaging → APNs key (Team ID / Key ID match)
and/or app signing environment (dev-signed builds create sandbox tokens).

**Rule: always print the FULL error JSON including `details[]` before believing an FCM 401.**

## Dead ends ruled out (don't revisit)
- Service-account key: valid (manual JWT → oauth2 token → FCM send works from Replit).
- firebase-admin init: correct (cert credential); health ok.
- Node version (18 vs 22): irrelevant.
- fetch/undici header dropping: header provably leaves Railway (httpbin echo).
- Railway env/proxy interference: none; responses come from real Google (`scaffolding on HTTPServer2`).
- Query-param `?access_token=` auth: same error (as expected — it's APNs, not OAuth).

## Current backend send path
`dist/app/utils/fcm.js` (runs from committed dist/, NO build step — always edit dist AND src):
direct FCM HTTP v1 via node:https, self-signed JWT + token exchange, token cached ~50min,
token-rot cleanup on UNREGISTERED/INVALID_ARGUMENT. TEMP diag logging still present — remove later.
`/push/debug?key=gsPushDebug_2026&email=...&send=1` = Claude's temp diagnostic endpoint.

## Access & coordination
- Backend repo `vjtyler68-cloud/goalshare-backend` is writable via the Replit **GitHub connector**
  (connectors-sdk proxy → contents API; `listConnections('github')` returned [] — use
  `@replit/connectors-sdk` proxy pattern installed in workspace package.json).
- Railway API (RAILWAY_API_TOKEN secret): deploy via `serviceInstanceDeployV2` (redeploy alone
  reuses old image), logs via `deploymentLogs`, build logs via `buildLogs`.
- User has DUPLICATE accounts: vjtyler68@gmail.com = 6a4f50a9... (no token); the phone's
  live account is 6a5ada8b... (VJT) / 6a5ae287... (Tyler) — has tokens.
