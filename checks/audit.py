#!/usr/bin/env python3
"""Check coverage audit for a project that uses vibeArchitecture.

  python3 vibeArchitecture/checks/audit.py [project-dir] [--tier T] [--out FILE]

Reads the project's tier, .va/config.sh and files, plus this framework's
rules/verification.toml and checks/catalog.toml, and prints a markdown report:

  1. Checks the tier expects, each marked wired / not configured / missing / n/a,
     with the signal that made it relevant.
  2. vibeArchitecture Semgrep rules installed vs available, and version drift.
  3. Rules that no check can verify ("review" and "attest"), for the assurance
     register, so nothing is silently unenforced.

Exit status is 1 when a check that applies at this tier is missing or not
configured, so the audit can itself run in CI. Stdlib only (Python 3.11+).
"""
import argparse
import pathlib
import re
import subprocess
import sys
import tomllib

VA = pathlib.Path(__file__).resolve().parent.parent
TIERS = ["personal", "shared", "public", "business", "regulated"]


def git_files(root):
    try:
        out = subprocess.run(["git", "ls-files"], cwd=root, capture_output=True, text=True, check=True).stdout
        return out.splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return [str(p.relative_to(root)) for p in root.rglob("*") if p.is_file() and ".git" not in p.parts]


def read_config(root):
    cfg = {}
    p = root / ".va" / "config.sh"
    if p.exists():
        for line in p.read_text().splitlines():
            m = re.match(r"^([A-Z_]+)=(['\"])(.*)\2\s*$", line.strip())
            if m:
                cfg[m.group(1)] = m.group(3)
    return cfg


def read_tier(root, override):
    if override:
        return override
    cfg = read_config(root)
    if cfg.get("VA_TIER") in TIERS:
        return cfg["VA_TIER"]
    prof = root / "PROJECT_PROFILE.md"
    if prof.exists():
        m = re.search(r"^\*\*Tier:\*\*\s*([A-Za-z]+)", prof.read_text(), re.M)
        if m and m.group(1).lower() in TIERS:
            return m.group(1).lower()
    return "shared"


def signals(files, root):
    """Facts about the project that switch checks on."""
    has = lambda rx: any(re.search(rx, f) for f in files)
    return {
        "manifest": has(r"(^|/)(package\.json|pyproject\.toml|requirements[^/]*\.txt|Cargo\.toml|go\.mod|Gemfile|composer\.json|pubspec\.yaml|pom\.xml|build\.gradle)$"),
        "workflows": has(r"^\.github/workflows/"),
        "migrations": has(r"(^|/)(migrations|db/migrate|alembic/versions|prisma/migrations|supabase/migrations|drizzle)/"),
        "sql": has(r"\.sql$"),
        "docker": has(r"(^|/)(Dockerfile|Containerfile)[^/]*$|\.dockerfile$"),
        "iac": has(r"\.(tf|tofu)$|(^|/)(cloudformation|cdk\.json|Chart\.yaml|kustomization\.ya?ml)"),
        "web_ui": has(r"\.(jsx|tsx|vue|svelte|astro|html)$"),
        "openapi": has(r"(^|/)(openapi|swagger)[^/]*\.(ya?ml|json)$"),
        "codegen": has(r"(^|/)(openapi-generator|orval\.config|buf\.gen\.ya?ml|schema\.prisma|sqlc\.ya?ml|codegen\.ya?ml)"),
        "db": has(r"(^|/)(schema\.prisma|alembic\.ini|knexfile|drizzle\.config|ormconfig)|\.sql$|(^|/)models\.py$"),
        "ci_github": (root / ".github" / "workflows" / "va-checks.yml").exists(),
        "ci_gitlab": (root / ".va" / "va-checks.gitlab-ci.yml").exists() or (root / ".gitlab-ci.yml").exists(),
        "hooks": (root / ".githooks" / "pre-push").exists(),
        "agent_claude": ".va/hooks/guard.sh" in _read(root / ".claude" / "settings.json"),
        "agent_cursor": ".va/hooks/guard.sh" in _read(root / ".cursor" / "hooks.json"),
        "check": (root / ".va" / "check").exists(),
    }


def _read(p):
    try:
        return p.read_text()
    except OSError:
        return ""


def status_for(cid, sig, cfg, root):
    """Return (status, detail). status: wired | not-configured | missing | n/a | manual | optional"""
    step = sig["check"]
    set_ = lambda k: bool(cfg.get(k, "").strip())
    table = {
        "gate": (step and sig["hooks"], "`.va/check` + `.githooks`"),
        "secrets": (step, "gitleaks step"),
        "env-files": (step, "env-files step"),
        "va-rules": (step and (root / ".va" / "semgrep").exists(), "Semgrep step + .va/semgrep"),
    }
    if cid in table:
        ok, what = table[cid]
        return ("wired" if ok else "missing", what)
    if cid == "deps":
        return ("n/a", "no package manifest") if not sig["manifest"] else ("wired" if step else "missing", "osv-scanner step")
    if cid == "workflows":
        return ("n/a", "no workflows") if not sig["workflows"] else ("wired" if step else "missing", "actionlint + zizmor step")
    if cid in ("migrations-immutable", "migration-lint"):
        if not sig["migrations"]:
            return ("n/a", "no migrations directory")
        if cid == "migration-lint":
            return ("wired", "squawk") if cfg.get("MIGRATION_LINT") == "squawk" else ("optional", "Postgres: set MIGRATION_LINT=squawk")
        return ("wired" if step else "missing", "migrations step")
    if cid == "lint":
        return ("wired" if set_("LINT_CMD") else "not-configured", "LINT_CMD / FORMAT_CHECK_CMD")
    if cid == "lint-a11y":
        return ("n/a", "no web UI") if not sig["web_ui"] else ("manual", "confirm LINT_CMD enables jsx-a11y (or equivalent)")
    if cid == "tests":
        return ("wired" if set_("TEST_CMD") else "not-configured", "TEST_CMD")
    if cid == "tests-db":
        return ("n/a", "no database detected") if not sig["db"] else ("wired" if set_("TEST_DB_CMD") else "not-configured", "TEST_DB_CMD")
    if cid == "migrate-twice":
        return ("n/a", "no migrations") if not sig["migrations"] else ("wired" if set_("MIGRATE_CMD") else "not-configured", "MIGRATE_CMD")
    if cid == "codegen-drift":
        return ("n/a", "no code generation detected") if not sig["codegen"] else ("wired" if set_("CODEGEN_CMD") else "not-configured", "CODEGEN_CMD")
    if cid in ("iac",):
        return ("n/a", "no IaC") if not (sig["iac"] or sig["docker"]) else ("manual", "trivy config in EXTRA_FULL_CMD")
    if cid in ("image-scan",):
        return ("n/a", "no container build") if not sig["docker"] else ("manual", "trivy image in RELEASE_CMD")
    if cid == "a11y-e2e":
        return ("n/a", "no web UI") if not sig["web_ui"] else ("manual", "axe checks in TEST_CMD or EXTRA_FULL_CMD")
    if cid == "contract":
        return ("n/a", "no OpenAPI document") if not sig["openapi"] else ("manual", "contract tests in TEST_CMD")
    if cid == "sbom":
        return ("manual", "syft/trivy sbom in RELEASE_CMD")
    if cid == "repo-settings":
        ci = sig["ci_github"] or sig["ci_gitlab"]
        return ("manual" if ci else "missing", "required `check` status on the default branch (`.va/check doctor`)" if ci else "no CI workflow")
    if cid == "agent-hooks":
        return ("wired" if (sig["agent_claude"] or sig["agent_cursor"]) else "missing", "Claude Code / Cursor guard hooks")
    if cid == "ai-review":
        return ("wired" if (root / ".github" / "workflows" / "va-ai-review.yml").exists() else "manual", "va-ai-review workflow or human review")
    return ("manual", "project-provided")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("project", nargs="?", default=".")
    ap.add_argument("--tier", choices=TIERS)
    ap.add_argument("--out")
    args = ap.parse_args()

    root = pathlib.Path(args.project).resolve()
    matrix = tomllib.loads((VA / "rules" / "verification.toml").read_text())
    catalog = tomllib.loads((VA / "checks" / "catalog.toml").read_text())
    tier = read_tier(root, args.tier)
    ti = TIERS.index(tier)
    files = git_files(root)
    sig = signals(files, root)
    cfg = read_config(root)

    in_scope = []
    for name, section in matrix.items():
        for e in section["rules"]:
            if TIERS.index(e.get("tier", section["tier"])) <= ti:
                in_scope.append((name, section, e))
    needed = {}
    for name, section, e in in_scope:
        for c in e.get("checks", []):
            needed.setdefault(c, []).append(e["id"])

    out = []
    w = out.append
    w(f"# Check coverage audit: {root.name}\n")
    w(f"Tier **{tier}**, vibeArchitecture {(VA / 'ARCHITECT.md').read_text().split('Framework version:** ')[1].split()[0]}. "
      f"{len(in_scope)} rules in scope (conditional rule files included; drop the ones that don't apply).\n")

    w("## Checks\n")
    w("| Check | Status | How | Rules |")
    w("|---|---|---|---|")
    blocking_gaps = 0
    for cid in sorted(needed, key=lambda c: (TIERS.index(catalog[c]["tier"]), c)):
        meta = catalog[cid]
        if TIERS.index(meta["tier"]) > ti:
            continue
        st, how = status_for(cid, sig, cfg, root)
        if st in ("missing", "not-configured"):
            blocking_gaps += 1
        ids = needed[cid]
        w(f"| {meta['title']} (`{cid}`) | **{st}** | {how} | {', '.join(ids[:6])}{' +' + str(len(ids) - 6) if len(ids) > 6 else ''} |")
    w("")
    w("`manual` means vibeArchitecture can't see it from the repo: confirm it and record it in the assurance register.\n")

    w("## vibeArchitecture Semgrep rules\n")
    available = sum(1 for t in TIERS[: ti + 1] for y in (VA / "checks" / "semgrep" / t).glob("*.yaml")
                    for line in y.read_text().splitlines() if line.startswith("  - id: "))
    installed = sum(1 for y in (root / ".va" / "semgrep").rglob("*.yaml")
                    for line in y.read_text().splitlines() if line.startswith("  - id: "))
    ver = _read(root / ".va" / "VERSION").strip() or "not installed"
    w(f"- Installed: {installed} rules (framework version {ver}); available for this tier: {available}.")
    if installed < available:
        w("- **Drift:** run `vibeArchitecture/checks/install.sh --update`.")
    w("")

    for method, heading, blurb in (
        ("review", "Rules verified by review", "No automated check can decide these. Cover them in code review or the AI review job, and log review passes in the assurance register."),
        ("attest", "Rules verified by attestation", "Settings and processes outside the code. Record each one (who confirmed it, when) in the assurance register."),
    ):
        rows = [(n, e) for n, s, e in in_scope
                if method in e["verify"] and not (set(e["verify"]) & {"tool", "pattern", "test", "runtime"})]
        w(f"## {heading} ({len(rows)})\n")
        w(blurb + "\n")
        w("| Rule | File | Starts with |")
        w("|---|---|---|")
        for n, e in rows:
            w(f"| {e['id']} | rules/{n}.md | {e['match']} |")
        w("")

    report = "\n".join(out) + "\n"
    if args.out:
        pathlib.Path(args.out).write_text(report)
        print(f"wrote {args.out}")
    else:
        print(report)
    if blocking_gaps:
        print(f"audit: {blocking_gaps} check(s) this tier expects are missing or not configured.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
