---
name: GoalShare backend auth & upload quirks
description: Non-obvious behaviors of the Railway backend around JWT auth headers, error status codes, and multipart uploads.
---

# GoalShare Railway backend quirks

Backend is a separate Railway service (NOT in this repo): `goalshare-backend-production.up.railway.app/api/v1`. Only compiled JS is deployed, so fixes must be app-side.

## Authorization header: send the RAW JWT, no "Bearer " prefix
The auth middleware passes the **entire** `Authorization` header value straight into `jwt.verify()` without stripping `Bearer `. Verified against the live API:
- `Authorization: Bearer <valid-jwt>` → `{"success":false,"message":"invalid token"}`
- `Authorization: <valid-jwt>` (raw) → gets past parsing to signature check

**How to apply:** every authenticated request must set `headers['Authorization'] = token;` (raw), never `'Bearer $token'`. Applies to normal and multipart requests.

## Auth error status codes are inconsistent
- **Missing** token → HTTP **401** `"You are not authorized!"`
- **Invalid/expired/malformed** token → HTTP **500** with `{"success":false,"message":"invalid token" | "jwt expired" | "jwt malformed"}`

**Why it matters:** handling only HTTP 401 lets an expired token slip through as a raw "invalid token" message, stranding the user on a logged-in screen (manual sign-out/in loop). The app's network layer detects JWT-verify error messages on ANY status and forces a clean re-login. Match only JWT-library messages (`invalid token`, `jwt expired`, `token expired`, `jwt malformed`) — NOT generic words like `unauthorized`/`invalid signature`, which can appear in legit business/payment errors. Do not treat 403 (forbidden) as a session expiry.

## Multipart uploads: never set Content-Type manually
For `http.MultipartRequest`, do NOT add `'Content-Type': 'multipart/form-data'` to headers. The http package auto-generates it WITH the required `boundary=...` on `send()`; a manual header strips the boundary and the server can't parse the body — the upload fails (often silently if there's no error branch). Set only `Authorization`. Vision board upload hit exactly this bug.
