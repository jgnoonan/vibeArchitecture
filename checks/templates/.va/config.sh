# vibeArchitecture check configuration. Project-owned: edit freely; updates never overwrite it.
# Sourced by .va/check (bash). Leave a command empty to mark its step "not applicable".
# Every command must exit non-zero on failure. Don't pipe a check into another
# command (`cmd | tail`): the pipe's exit code hides the check's.

# Project tier from PROJECT_PROFILE.md: personal | shared | public | business | regulated
VA_TIER='__TIER__'

# Default branch, if it isn't what origin/HEAD says.
MAIN_BRANCH=""

# pre-commit: fast formatting check (should take seconds).
FORMAT_CHECK_CMD='__FORMAT_CHECK_CMD__'

# pre-push and CI: linter with warnings as errors (include accessibility lint at Public tier+).
LINT_CMD='__LINT_CMD__'

# pre-push and CI: unit and behavioural tests.
TEST_CMD='__TEST_CMD__'

# CI only: database-backed tests. Runs with VA_REQUIRE_DB=1 exported; the suite must
# FAIL (not skip) when that is set and the database is unreachable.
TEST_DB_CMD=""

# CI only: apply migrations to the test database. Run twice; both runs must succeed.
MIGRATE_CMD=""

# Migrations directory (auto-detected if empty: migrations, db/migrations, db/migrate,
# prisma/migrations, supabase/migrations, alembic/versions, drizzle).
MIGRATIONS_DIR=""

# Set to "squawk" to lint Postgres .sql migrations with squawk.
MIGRATION_LINT=""

# Regenerate generated code (API clients, ORM clients, bindings). The step fails if this
# changes or creates files. Runs in CI; set CODEGEN_ON_PUSH=1 to also run at pre-push.
CODEGEN_CMD=""
CODEGEN_ON_PUSH=""

# Extra Semgrep configs, space-separated (e.g. "p/ci p/javascript" registry rulesets).
SEMGREP_EXTRA_CONFIG=""

# Manifests that intentionally have no lockfile (space-separated paths, e.g. a published library).
LOCKFILE_EXEMPT=""

# Anything else: pre-push, CI, and release. Chain with && so any failure fails the step.
EXTRA_PUSH_CMD=""
EXTRA_FULL_CMD=""
RELEASE_CMD=""
