#!/usr/bin/env python3
"""Keep rules/verification.toml honest.

Fails (exit 1) when:
  - a rule bullet in rules/*.md has no matrix entry, or matches more than one
  - a matrix entry matches no bullet (the rule was reworded or removed)
  - an id is duplicated, malformed, or uses the wrong prefix for its file
  - a verify method or tier is unknown
  - a tool/test/runtime entry names no check, or names a check missing from checks/catalog.toml
  - an entry says "pattern" but no Semgrep rule in checks/semgrep/ cites it
  - a Semgrep rule cites an id that is missing, or whose entry does not say "pattern"

Usage:
  scripts/verify-matrix.py              # verify
  scripts/verify-matrix.py --summary    # verify, then print a coverage table (markdown)

Stdlib only; needs Python 3.11+ (tomllib).
"""
import pathlib
import re
import sys

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    sys.exit("verify-matrix.py needs Python 3.11+ (tomllib)")

ROOT = pathlib.Path(__file__).resolve().parent.parent
MATRIX = ROOT / "rules" / "verification.toml"
CATALOG = ROOT / "checks" / "catalog.toml"
SEMGREP = ROOT / "checks" / "semgrep"

PREFIX = {
    "accessibility": "A11Y", "api": "API", "compliance": "COMP", "data": "DATA",
    "infrastructure": "INFRA", "mobile": "MOB", "multi-agent": "MAI", "observability": "OBS",
    "performance": "PERF", "privacy": "PRIV", "reliability": "REL", "security": "SEC",
    "system-design": "SYS", "testing": "TEST", "universal": "UNI",
}
METHODS = ["tool", "pattern", "test", "runtime", "review", "attest", "guidance"]
NEEDS_CHECK = {"tool", "test", "runtime"}
TIERS = ["personal", "shared", "public", "business", "regulated"]


def clean(text: str) -> str:
    text = re.sub(r"^\[ \]\s*", "", text)
    return text.replace("**", "").replace("`", "")


def bullets(path: pathlib.Path):
    return [clean(line[2:].strip()) for line in path.read_text().splitlines() if line.startswith("- ")]


def semgrep_citations():
    cited = {}
    for y in sorted(SEMGREP.rglob("*.yaml")):
        rid = None
        for line in y.read_text().splitlines():
            m = re.match(r"^  - id: (\S+)", line)
            if m:
                rid = m.group(1)
            m = re.match(r"^      va_rules: \[([^\]]+)\]", line)
            if m and rid:
                for v in m.group(1).split(","):
                    cited.setdefault(v.strip(), []).append(f"{y.relative_to(ROOT)}:{rid}")
    return cited


def main() -> int:
    problems = []
    matrix = tomllib.loads(MATRIX.read_text())
    catalog = tomllib.loads(CATALOG.read_text())
    cited = semgrep_citations()

    rule_files = {p.stem: p for p in (ROOT / "rules").glob("*.md") if p.stem != "_index"}
    for name in sorted(set(rule_files) - set(matrix)):
        problems.append(f"rules/{name}.md has no [{name}] section in the matrix")
    for name in sorted(set(matrix) - set(rule_files)):
        problems.append(f"matrix section [{name}] has no rules/{name}.md")

    seen_ids, entries = {}, {}
    for name in sorted(set(rule_files) & set(matrix)):
        section = matrix[name]
        if section.get("tier") not in TIERS:
            problems.append(f"[{name}] tier {section.get('tier')!r} is not one of {TIERS}")
        texts = bullets(rule_files[name])
        hits = [0] * len(texts)
        for e in section.get("rules", []):
            rid, match = e.get("id", ""), e.get("match", "")
            where = f"{name}:{rid or '?'}"
            if not re.fullmatch(rf"{PREFIX[name]}-\d{{3}}", rid):
                problems.append(f"{where}: id must look like {PREFIX[name]}-NNN")
            if rid in seen_ids:
                problems.append(f"{where}: duplicate id (also in {seen_ids[rid]})")
            seen_ids[rid] = name
            entries[rid] = e
            matched = [i for i, t in enumerate(texts) if t.startswith(match)]
            if len(matched) != 1:
                problems.append(f"{where}: match {match!r} hits {len(matched)} bullets in rules/{name}.md (need exactly 1)")
            for i in matched:
                hits[i] += 1
            verify = e.get("verify", [])
            if not verify or any(v not in METHODS for v in verify):
                problems.append(f"{where}: verify {verify} must be a non-empty subset of {METHODS}")
            checks = e.get("checks", [])
            if NEEDS_CHECK & set(verify) and not checks:
                problems.append(f"{where}: verify includes {sorted(NEEDS_CHECK & set(verify))} but names no check")
            for c in checks:
                if c not in catalog:
                    problems.append(f"{where}: check {c!r} is not in checks/catalog.toml")
            if "tier" in e and e["tier"] not in TIERS:
                problems.append(f"{where}: tier {e['tier']!r} is not one of {TIERS}")
            if "pattern" in verify and rid not in cited:
                problems.append(f"{where}: says 'pattern' but no rule in checks/semgrep/ cites it")
        for i, n in enumerate(hits):
            if n == 0:
                problems.append(f"rules/{name}.md bullet has no matrix entry: {texts[i][:90]!r}")

    for rid, sources in sorted(cited.items()):
        if rid not in entries:
            problems.append(f"{sources[0]} cites {rid}, which is not in the matrix")
        elif "pattern" not in entries[rid].get("verify", []):
            problems.append(f"{sources[0]} cites {rid}, but its matrix entry does not list 'pattern'")

    if problems:
        print(f"verification matrix: {len(problems)} problem(s)", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    total = len(entries)
    print(f"verification matrix: {total} rules classified, {len(cited)} backed by Semgrep rules, all consistent.")
    if "--summary" in sys.argv:
        print_summary(matrix)
    return 0


def print_summary(matrix):
    automated = {"tool", "pattern", "test", "runtime"}
    print("\n| Tier | Rules in scope | Automated (tool, pattern, test, runtime) | Review | Attest only | Guidance |")
    print("|---|---|---|---|---|---|")
    for t_i, tier in enumerate(TIERS):
        scope = auto = review = attest = guid = 0
        for name, section in matrix.items():
            for e in section["rules"]:
                eff = e.get("tier", section["tier"])
                if TIERS.index(eff) > t_i:
                    continue
                scope += 1
                v = set(e["verify"])
                if v & automated:
                    auto += 1
                elif "review" in v:
                    review += 1
                elif "attest" in v:
                    attest += 1
                else:
                    guid += 1
        pct = f"{auto / scope:.0%}" if scope else "-"
        print(f"| {tier.title()} | {scope} | {auto} ({pct}) | {review} | {attest} | {guid} |")
    print("\nConditional files (privacy, multi-agent, mobile, system-design, compliance) are counted at their base tier.")


if __name__ == "__main__":
    sys.exit(main())
