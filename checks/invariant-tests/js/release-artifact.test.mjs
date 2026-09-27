// Invariant: the release build contains no debug features (VA UNI-039).
// Run after the production build, e.g. RELEASE_CMD='npm run build && node --test test/release-artifact.test.mjs'.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";

const DIST = process.env.RELEASE_DIR ?? "dist";
const FORBIDDEN = [
  [/https?:\/\/(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?/, "development endpoint"],
  [/__DEV_LOGIN__|devLogin|DEBUG_PANEL|enableDebugTools/, "developer-only feature flag"],
  [/sk_test_[0-9A-Za-z]{10,}|pk_test_[0-9A-Za-z]{10,}/, "test-mode payment key"],
];

function walk(dir) {
  return readdirSync(dir).flatMap((n) => (statSync(join(dir, n)).isDirectory() ? walk(join(dir, n)) : [join(dir, n)]));
}

export function findings(files, read = (f) => readFileSync(f, "latin1")) {
  const out = [];
  for (const f of files) {
    if (f.endsWith(".map")) out.push(`${f}: source map shipped in the release`);
    const text = read(f);
    for (const [rx, what] of FORBIDDEN) if (rx.test(text)) out.push(`${f}: ${what}`);
  }
  return out;
}

test("release artifact has no debug features", () => {
  assert.ok(existsSync(DIST), `${DIST} not found: build the release first`);
  const files = walk(DIST);
  assert.ok(files.length > 0, `${DIST} is empty: the invariant would pass vacuously`);
  assert.deepEqual(findings(files), []);
});

test("negative control: a dev endpoint in a bundle is caught", () => {
  const bad = { "dist/app.js": 'fetch("http://localhost:3000/api")' };
  assert.equal(findings(Object.keys(bad), (f) => bad[f]).length, 1);
});
