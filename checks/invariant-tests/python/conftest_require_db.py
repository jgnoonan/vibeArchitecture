"""Make database-backed tests fail loudly instead of skipping (VA TEST-021/TEST-022).

Merge into your tests/conftest.py. `.va/check full` runs TEST_DB_CMD with
VA_REQUIRE_DB=1; then an unreachable database fails the run instead of
skipping every database test and reporting green.
"""
import os

import pytest


@pytest.fixture(scope="session")
def db():
    url = os.environ.get("DATABASE_URL")
    try:
        if not url:
            raise RuntimeError("DATABASE_URL is not set")
        conn = connect(url)  # noqa: F821  (your connection function)
    except Exception as exc:  # pragma: no cover
        if os.environ.get("VA_REQUIRE_DB") == "1":
            pytest.fail(f"database tests must run here but the database is unavailable: {exc}", pytrace=False)
        pytest.skip(f"SKIPPING database tests: {exc}")
    yield conn
    conn.close()
