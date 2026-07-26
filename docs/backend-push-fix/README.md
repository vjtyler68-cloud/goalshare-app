# Backend push fix — replace firebase-admin sending with direct FCM HTTP v1

## Problem (proven, not theorized)
Every `sendPushToUser` call fails with:

```
[push] send failed: Request is missing required authentication credential. Expected OAuth 2 access token...
```

i.e. firebase-admin sends the FCM request with **no Authorization header**. This
happens on both Node 18 and Node 22 (verified: rebuilt on nodejs_22, error persists).
The service-account key itself is **valid** — verified independently by manually
signing a JWT with the same `FIREBASE_SERVICE_ACCOUNT` value, exchanging it at
`oauth2.googleapis.com/token` (success), and calling
`https://fcm.googleapis.com/v1/projects/goalshare-966d1/messages:send` (auth
accepted; only the dummy device token was rejected, as expected).

So: key good, Google good, firebase-admin's send path broken in this deployment.

## Fix
Stop using firebase-admin for sending. Do the proven flow directly with
`node:crypto` + `fetch` (zero new dependencies):

1. Replace `src/app/utils/fcm.ts` with `fcm.ts` from this folder.
2. Replace `dist/app/utils/fcm.js` with `fcm.js` from this folder
   (**required** — Railway runs the committed `dist/`, there is no build step).
3. Commit both, push to `goalshare-backend` main. Railway auto-deploys.

Exports are unchanged (`sendPushToUser`, `isPushReady`) — no other file needs edits.

## Notes
- firebase-admin stays installed; `Push.controller.js`'s temporary `/push/debug`
  `send=1` path and its Firestore probe still use it directly. Since fcm no longer
  initializes admin, the debug endpoint's send/firestore probes may need
  `admin.initializeApp({credential: admin.credential.cert(...)})` of their own —
  or just rely on real `/push/notify` sends, which this fix covers.
- Token-rot self-healing kept: `UNREGISTERED`/`INVALID_ARGUMENT`/404 clears the
  user's stored fcmToken.
- OAuth access tokens are cached for ~50 minutes.
- After deploy, verification from the Replit side: send `/push/notify` and watch
  Railway logs — the credential error must be gone and phones with a stored
  token must get the banner.
