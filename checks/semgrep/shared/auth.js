// Fixtures for auth.yaml.
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const cors = require("cors");
const session = require("express-session");

function jwts(token, key) {
  // ruleid: va-jwt-verify-without-algorithms-js
  jwt.verify(token, key);
  // ruleid: va-jwt-verify-without-algorithms-js
  jwt.verify(token, key, { audience: "api" });
  // ok: va-jwt-verify-without-algorithms-js
  jwt.verify(token, key, { algorithms: ["RS256"], audience: "api" });
  // ruleid: va-jwt-decode-is-not-verify-js
  const claims = jwt.decode(token);
  // ruleid: va-jwt-none-algorithm-js
  jwt.verify(token, key, { algorithms: ["HS256", "none"] });
}

function storage(accessToken, theme) {
  // ruleid: va-token-in-web-storage
  localStorage.setItem("accessToken", accessToken);
  // ruleid: va-token-in-web-storage
  window.sessionStorage.setItem("auth_session", accessToken);
  // ruleid: va-token-in-web-storage
  AsyncStorage.setItem("refresh_token", accessToken);
  // ok: va-token-in-web-storage
  localStorage.setItem("theme", theme);
}

function compare(req, expectedSignature, providedToken, storedToken, apiKey) {
  // ruleid: va-timing-unsafe-compare-js
  if (req.headers.signature === expectedSignature) {}
  // ruleid: va-timing-unsafe-compare-js
  if (providedToken !== storedToken) {}
  // ok: va-timing-unsafe-compare-js
  if (apiKey === undefined) {}
  // ok: va-timing-unsafe-compare-js
  if (crypto.timingSafeEqual(Buffer.from(providedToken), Buffer.from(storedToken))) {}
  // ok: va-timing-unsafe-compare-js
  if (typeof providedToken === "string") {}
}

function hashing(password, user) {
  // ruleid: va-password-fast-hash-js
  const h = crypto.createHash("sha256").update(password).digest("hex");
  // ruleid: va-password-fast-hash-js
  const h2 = crypto.createHash("md5").update(user.password + salt).digest("hex");
  // ok: va-password-fast-hash-js
  const etag = crypto.createHash("sha256").update(body).digest("hex");
}

function randomness() {
  // ruleid: va-insecure-random-secret-js
  const resetToken = Math.random().toString(36).slice(2);
  // ruleid: va-insecure-random-secret-js
  const invite = { inviteCode: Math.floor(Math.random() * 1e6) };
  // ok: va-insecure-random-secret-js
  const jitterMs = Math.random() * 100;
  // ok: va-insecure-random-secret-js
  const resetToken2 = crypto.randomBytes(32).toString("hex");
}

// ruleid: va-insecure-random-secret-js
function generateSessionId() { return Math.random().toString(36); }

function cookies(res) {
  // ruleid: va-cookie-flags-disabled-js
  res.cookie("sid", "x", { httpOnly: false, secure: true });
  // ruleid: va-cookie-flags-disabled-js
  app.use(session({ secret: s, cookie: { secure: false } }));
  // ok: va-cookie-flags-disabled-js
  res.cookie("sid", "x", { httpOnly: true, secure: true, sameSite: "lax" });
  // ok: va-cookie-flags-disabled-js
  app.use(session({ secret: s, cookie: { secure: process.env.NODE_ENV === "production" } }));
}

function corsSetup(app, req, res, allowed) {
  // ruleid: va-cors-reflect-origin-js
  app.use(cors({ origin: true, credentials: true }));
  // ok: va-cors-reflect-origin-js
  app.use(cors({ origin: ["https://app.example.com"], credentials: true }));
  // ruleid: va-cors-reflect-origin-js
  res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
  if (allowed.includes(req.headers.origin)) {
    // ok: va-cors-reflect-origin-js
    res.setHeader("Access-Control-Allow-Origin", req.headers.origin);
  }
  // ruleid: va-csrf-disabled-js
  const opts = { csrf: false };
}

function reversed(expected, req) {
  // ruleid: va-timing-unsafe-compare-js
  if (expected === req.headers.signature) {}
}

function controls(token, key, jwtLib) {
  // ok: va-jwt-decode-is-not-verify-js
  const verified = jwt.verify(token, key, { algorithms: ["RS256"] });
  // ok: va-jwt-none-algorithm-js
  const o = { algorithms: ["RS256", "ES256"] };
  // ok: va-csrf-disabled-js
  const o2 = { csrf: true };
}

function enumCompare(node, SyntaxKind, req) {
  // ok: va-timing-unsafe-compare-js
  if (node.getKind() === SyntaxKind.CommaToken) {}
  // ok: va-timing-unsafe-compare-js
  if (req.body.tokenCount === 3) {}
  // ruleid: va-timing-unsafe-compare-js
  if (req.headers["x-hub-signature"] === computedSignature) {}
}

function prefs(filter, count) {
  // ok: va-token-in-web-storage
  localStorage.setItem("authorFilter", filter);
  // ok: va-token-in-web-storage
  localStorage.setItem("sessionCount", count);
  // ruleid: va-token-in-web-storage
  localStorage.setItem("supabase.auth.token", count);
}
