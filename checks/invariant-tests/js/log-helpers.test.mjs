// Invariant: server logs never receive personal data or secrets (VA PRIV-023, DATA-031, OBS-006).
// The Semgrep rule va-sensitive-value-logged-* catches obvious names (password, token...).
// This test enforces your project's own list (email, phone, message body...) against
// your own log helpers. Adjust SRC, LOG_CALL and PERSONAL. Runs with `node --test`.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const SRC = "src";
const LOG_CALL = /\b(?:logger|log|console)\.(?:debug|info|warn|error|log)\(([^;]*)\)/g;
const PERSONAL = /\b(?:email|phone(?:Number)?|address|fullName|dateOfBirth|dob|ssn|messageBody|body\.text|ipAddress)\b/;

function walk(dir) {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? walk(p) : /\.(m?[jt]sx?)$/.test(n) ? [p] : [];
  });
}

export function leaks(files, read = (f) => readFileSync(f, "utf8")) {
  const out = [];
  for (const f of files) {
    for (const m of read(f).matchAll(LOG_CALL)) if (PERSONAL.test(m[1])) out.push(`${f}: ${m[0].slice(0, 80)}`);
  }
  return out;
}

test("log calls carry no personal data", () => {
  const files = walk(SRC).map((f) => relative(".", f));
  assert.ok(files.length > 0, `scanned no files under ${SRC}: the invariant would pass vacuously`);
  assert.deepEqual(leaks(files), []);
});

test("negative control: a log call with an email is caught", () => {
  const bad = { "src/signup.js": 'logger.info("signup", { email: user.email });' };
  assert.equal(leaks(Object.keys(bad), (f) => bad[f]).length, 1);
});
