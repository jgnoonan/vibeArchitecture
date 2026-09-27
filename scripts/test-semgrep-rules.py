#!/usr/bin/env python3
"""Test the vibeArchitecture Semgrep ruleset (checks/semgrep/).

`semgrep --test` prints "All tests passed" even when a rule file fails to
parse, and it passes a rule that has no fixtures at all. This wrapper closes
both holes, so a broken or untested rule fails CI:

  1. Any config error fails.
  2. Any failing rule test fails.
  3. Every rule id must have at least one `ruleid:` fixture that it matches
     (the rule can fire) and at least one `ok:` fixture (it can stay quiet).
  4. Every rule must declare `metadata.va_rules` so findings trace back to a
     rule in rules/*.md.

Requires: semgrep on PATH. Stdlib only otherwise.
Usage: scripts/test-semgrep-rules.py [checks/semgrep]
"""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
RULE_DIR = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "checks" / "semgrep"

ID_RE = re.compile(r"^  - id: (\S+)\s*$")
VA_RULES_RE = re.compile(r"^      va_rules: \[([^\]]+)\]\s*$")
ANNOT_RE = re.compile(r"(?:#|//|<!--|\(\*)\s*(ruleid|ok):\s*([\w.-]+)")


def rule_ids_and_meta(path: pathlib.Path):
    """Return {rule_id: [va rule ids]} from our house YAML layout."""
    rules, current = {}, None
    for line in path.read_text().splitlines():
        m = ID_RE.match(line)
        if m:
            current = m.group(1)
            if current in rules:
                raise SystemExit(f"{path}: duplicate rule id {current}")
            rules[current] = []
            continue
        m = VA_RULES_RE.match(line)
        if m and current:
            rules[current] = [x.strip() for x in m.group(1).split(",") if x.strip()]
    return rules


def main() -> int:
    problems = []
    yaml_files = sorted(RULE_DIR.rglob("*.yaml"))
    if not yaml_files:
        print(f"No rule files under {RULE_DIR}", file=sys.stderr)
        return 1

    proc = subprocess.run(
        ["semgrep", "--test", "--json", "--metrics=off", str(RULE_DIR)],
        capture_output=True, text=True,
    )
    try:
        report = json.loads(proc.stdout)
    except json.JSONDecodeError:
        print(proc.stdout[-2000:], proc.stderr[-2000:], sep="\n", file=sys.stderr)
        print("semgrep --test did not return JSON", file=sys.stderr)
        return 1

    for cfg in report.get("config_with_errors", []):
        problems.append(f"config error: {cfg}")
    for cfg in report.get("config_missing_tests", []):
        problems.append(f"no fixture file for {cfg}")

    results = report.get("results", {})
    total = 0
    for yaml_path in yaml_files:
        rules = rule_ids_and_meta(yaml_path)
        key = next((k for k in results if pathlib.Path(k).resolve() == yaml_path.resolve()), None)
        checks = results.get(key, {}).get("checks", {}) if key else {}
        fixtures = [p for p in yaml_path.parent.glob(yaml_path.stem + ".*") if p.suffix != ".yaml"]
        annotations = {}
        for fx in fixtures:
            for kind, rid in ANNOT_RE.findall(fx.read_text(errors="replace")):
                annotations.setdefault(rid, set()).add(kind)
        for rid, va_rules in rules.items():
            total += 1
            where = f"{yaml_path.relative_to(ROOT) if yaml_path.is_relative_to(ROOT) else yaml_path}:{rid}"
            if not va_rules:
                problems.append(f"{where}: missing metadata.va_rules")
            kinds = annotations.get(rid, set())
            if "ruleid" not in kinds:
                problems.append(f"{where}: no `ruleid:` fixture (cannot prove the rule fires)")
            if "ok" not in kinds:
                problems.append(f"{where}: no `ok:` fixture (cannot prove the rule stays quiet)")
            check = checks.get(rid)
            if check is None:
                problems.append(f"{where}: not exercised by semgrep --test")
                continue
            if not check.get("passed"):
                for fx, m in check.get("matches", {}).items():
                    exp, rep = set(m.get("expected_lines", [])), set(m.get("reported_lines", []))
                    missed, extra = sorted(exp - rep), sorted(rep - exp)
                    problems.append(f"{where}: {pathlib.Path(fx).name} missed lines {missed}, unexpected lines {extra}")
            for err in check.get("errors", []):
                problems.append(f"{where}: {err}")

    if problems:
        print(f"Semgrep ruleset: {len(problems)} problem(s)", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1
    print(f"Semgrep ruleset: {total} rules in {len(yaml_files)} files, all fire on their fixtures and stay quiet on the controls.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
