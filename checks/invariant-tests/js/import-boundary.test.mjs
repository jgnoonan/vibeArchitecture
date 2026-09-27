// Invariant: only one module may import crypto primitives (VA SYS-005, SEC-069).
// Copy into your test suite, then adjust SRC, ALLOWED and SENSITIVE. Runs with `node --test`.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const SRC = "src";
const ALLOWED = ["src/crypto/"]; // the one place allowed to touch the primitives
const SENSITIVE = /(?:from\s+|require\()\s*["'](?:node:)?(?:crypto|tweetnacl|libsodium-wrappers|@noble\/[\w-]+)["']/;

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    return statSync(p).isDirectory() ? walk(p) : /\.(m?[jt]sx?)$/.test(name) ? [p] : [];
  });
}

// The scanner under test. Keep it a pure function so the negative control can call it.
export function violations(files, read = (f) => readFileSync(f, "utf8")) {
  return files.filter((f) => !ALLOWED.some((a) => f.startsWith(a)) && SENSITIVE.test(read(f)));
}

test("crypto primitives are imported only from the crypto module", () => {
  const files = walk(SRC).map((f) => relative(".", f));
  assert.ok(files.length > 0, `scanned no files under ${SRC}: the invariant would pass vacuously`);
  assert.deepEqual(violations(files), []);
});

test("negative control: the scan flags a known-bad file", () => {
  const bad = { "src/routes/login.js": 'import { createHash } from "node:crypto";' };
  assert.deepEqual(violations(Object.keys(bad), (f) => bad[f]), ["src/routes/login.js"]);
});
