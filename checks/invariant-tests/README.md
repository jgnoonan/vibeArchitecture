# Invariant tests

Some rules are about *your* code's shape, and no generic scanner knows it: which module may touch crypto, what goes into a push payload, whether the release bundle still points at localhost. You enforce those with ordinary tests that read your own source, build output, or payload builders. They need no custom linter and no CI plugin. They run wherever your tests run.

Every invariant test has four parts:

1. **Scan**: read the source, the build artifact, or the output of the real builder.
2. **Assert the invariant**: nothing violates it.
3. **Assert the scan found something**: a test that scanned zero files passes vacuously and proves nothing.
4. **Negative control**: feed the same scanner a known-bad example and assert it is caught. A scanner that can't fail is worse than no scanner, because it looks like coverage.

| Template | Rule | Catalog check |
|---|---|---|
| `js/import-boundary.test.mjs`, `python/test_import_boundary.py` | SYS-005 (module boundaries), SEC-069 (one crypto module) | `invariant-import-boundary` |
| `js/release-artifact.test.mjs` | UNI-039 (release builds have no debug features) | `invariant-release-artifact` |
| `js/log-helpers.test.mjs` | PRIV-023, DATA-031 (no personal data in server logs) | `invariant-log-helpers` |
| `python/test_payload_allowlist.py` | MOB-018, PRIV-023 (third-party payloads carry no content or identity) | `invariant-third-party-payload` |
| `js/require-db.mjs`, `python/conftest_require_db.py` | TEST-021, TEST-022 (skipped tests must not read as green) | `tests-db` |

Copy a template into your test suite and adjust the paths and patterns. It then runs as part of `TEST_CMD`, or `RELEASE_CMD` for the release-artifact test. Record it in the assurance register's **Checks** table.

## Incidents become invariants

When you fix a bug, ask whether it's an instance of a pattern. If it is, write the invariant test that would have caught it: it fails on the broken version and passes on the fix, and it has its own negative control. If the pattern is generic (not specific to your project), propose it upstream as a Semgrep rule in `checks/semgrep/`. See `CONTRIBUTING.md`.
