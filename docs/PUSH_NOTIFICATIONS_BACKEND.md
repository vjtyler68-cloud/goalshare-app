# Push Notifications — Backend (Railway) implementation

The Flutter app is **done**. It now:

1. Registers each device's FCM token against the logged-in user:
   `PUT /api/v1/user/fcm-token`  body: `{ "token": "<fcm>", "platform": "ios" }` (auth: raw JWT)
2. Asks the server to push a chat peer when a message is sent:
   `POST /api/v1/push/notify`  body: `{ "toUserId": "<id>", "title": "VJ", "body": "hey!" }` (auth: raw JWT)
3. Shows incoming pushes (foreground banner + native background notification).

The backend has to do three things: **store tokens**, **expose those two endpoints**, and
**send a push from the existing friend-request / accept handlers**. FCM sending is **free** on
the Firebase Spark plan (no Blaze, no Cloud Functions) — it's just an authenticated HTTPS call
made by `firebase-admin`, which is fine from Railway.

---

## 1. One-time setup

### a) Service account key (lets Railway send as your Firebase project)

Firebase Console → Project **goalshare-966d1** → ⚙ Project settings → **Service accounts** →
**Generate new private key**. Download the JSON.

**Do not commit it.** Put its contents in a Railway env var. Two common ways:

- Paste the whole JSON into a single env var `FIREBASE_SERVICE_ACCOUNT` (recommended), or
- Base64-encode the file and store as `FIREBASE_SERVICE_ACCOUNT_B64`.

The APNs `.p8` key is already uploaded to Firebase (Key ID `DC9WBK4GN4`, Team ID `VWZJZBW99S`),
so iOS delivery works with no extra APNs config here.

### b) Install the SDK

```bash
npm install firebase-admin
```

---

## 2. Firebase admin singleton — `services/fcm.js`

```js
const admin = require('firebase-admin');

// Parse the service account from env (works for either raw JSON or base64).
function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (raw) return JSON.parse(raw);
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_B64;
  if (b64) return JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
  throw new Error('FIREBASE_SERVICE_ACCOUNT[_B64] env var is not set');
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(loadServiceAccount()) });
}

/**
 * Send a notification to every device token a user has. Prunes tokens that FCM
 * reports as permanently invalid (uninstalled / logged out), so the token list
 * stays clean without any explicit "unregister" call from the app.
 *
 * @param {Array<string>} tokens
 * @param {string} title
 * @param {string} body
 * @param {object} [data]  optional string map (e.g. { type: 'chat' })
 * @returns {Promise<string[]>} tokens that are now invalid and should be removed
 */
async function sendToTokens(tokens, title, body, data = {}) {
  const list = (tokens || []).filter(Boolean);
  if (list.length === 0) return [];

  const res = await admin.messaging().sendEachForMulticast({
    tokens: list,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
    android: {
      priority: 'high',
      notification: { channelId: 'messages', sound: 'default' },
    },
  });

  const invalid = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token' ||
        code === 'messaging/invalid-argument'
      ) {
        invalid.push(list[i]);
      }
    }
  });
  return invalid;
}

module.exports = { admin, sendToTokens };
```

---

## 3. Store tokens on the user

Add an `fcmTokens: string[]` field to your user model/table (an array so one account can be
signed in on more than one device).

**Mongoose:** `fcmTokens: { type: [String], default: [] }`
**SQL/Prisma:** a `fcm_tokens` string array column, or a `device_tokens(user_id, token)` table.

A small helper to remove pruned tokens after a send:

```js
async function removeTokens(userId, tokens) {
  if (!tokens || tokens.length === 0) return;
  // Mongoose example:
  await User.updateOne({ _id: userId }, { $pull: { fcmTokens: { $in: tokens } } });
}
```

---

## 4. The two endpoints the app calls

> Use your existing auth middleware — the one that reads the **raw JWT** (no `Bearer` prefix)
> and sets `req.user`. Same middleware every other authed route uses.

```js
const express = require('express');
const router = express.Router();
const { sendToTokens } = require('../services/fcm');

// 1) Register / refresh this device's token on the logged-in user.
// PUT /api/v1/user/fcm-token   body: { token, platform }
router.put('/user/fcm-token', auth, async (req, res) => {
  try {
    const { token } = req.body || {};
    if (!token) return res.status(400).json({ success: false, message: 'token required' });

    // addToSet = no duplicates. (Mongoose shown; adapt for SQL.)
    await User.updateOne({ _id: req.user.id }, { $addToSet: { fcmTokens: token } });
    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ success: false, message: e.message });
  }
});

// 2) Push another user (used by chat — messages live in Firestore, so the
//    sender's app tells us to notify the peer).
// POST /api/v1/push/notify   body: { toUserId, title, body }
router.post('/push/notify', auth, async (req, res) => {
  try {
    const { toUserId, title, body } = req.body || {};
    if (!toUserId) return res.status(400).json({ success: false, message: 'toUserId required' });

    const target = await User.findById(toUserId).select('fcmTokens');
    if (!target || !target.fcmTokens || target.fcmTokens.length === 0) {
      return res.json({ success: true, delivered: 0 }); // nobody to notify — not an error
    }

    const invalid = await sendToTokens(
      target.fcmTokens,
      title || 'New message',
      body || '',
      { type: 'chat', fromUserId: req.user.id },
    );
    await removeTokens(toUserId, invalid);
    return res.json({ success: true });
  } catch (e) {
    return res.status(500).json({ success: false, message: e.message });
  }
});

module.exports = router;
```

Mount it wherever your other `/api/v1` routes are mounted.

---

## 5. Friend requests & accepts (pure backend — the app already routes these through you)

In your **existing** handlers, after the request/accept succeeds, fire a push. Wrap in
try/catch so a push failure never breaks the friend action.

```js
const { sendToTokens } = require('../services/fcm');

async function pushToUser(userId, title, body, data = {}) {
  try {
    const u = await User.findById(userId).select('fcmTokens fullName');
    if (!u || !u.fcmTokens || u.fcmTokens.length === 0) return;
    const invalid = await sendToTokens(u.fcmTokens, title, body, data);
    await removeTokens(userId, invalid);
  } catch (e) {
    console.error('pushToUser failed', e.message);
  }
}

// --- in POST /friends/requests (send a request), after it's saved: ---
//   `toUserId` = recipient, `sender` = req.user
await pushToUser(
  toUserId,
  'New friend request',
  `${sender.fullName} wants to be friends`,
  { type: 'friend_request' },
);

// --- in POST /friends/requests/:id/accept, after acceptance: ---
//   notify the ORIGINAL sender that they were accepted
await pushToUser(
  request.fromUserId,
  'Friend request accepted',
  `${accepter.fullName} accepted your friend request`,
  { type: 'friend_accept' },
);
```

That's everything. Deploy, and the app starts receiving real pushes.

---

## 6. Quick test

1. Deploy the backend with the env var set.
2. Log into the app on a **real iPhone** (push doesn't work in the simulator).
3. Confirm the token registered: the app calls `PUT /user/fcm-token` right after login — check
   the user doc has an entry in `fcmTokens`.
4. From a second account, send a friend request / a chat message → the first phone pings.

**Gotcha checklist**
- Push only works on a physical device, and only on a TestFlight/dev build signed with the
  **Push Notifications** capability (see the app-side note — the App ID must have it enabled).
- If nothing arrives, log the `admin.messaging()` response; a
  `registration-token-not-registered` means the token is stale (the code above auto-prunes it).
