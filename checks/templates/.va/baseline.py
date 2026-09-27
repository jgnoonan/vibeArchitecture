#!/usr/bin/env python3
"""Semgrep findings baseline for the vibeArchitecture check command. Framework-owned.

A baseline lets a project adopt the checks without fixing every existing
finding first: recorded findings don't block, new ones do, and the file can
only shrink unless someone accepts an addition with a reason and an expiry.

  baseline.py check  <semgrep.json> --baseline <file>
      Exit 1 if any ERROR finding is not in the baseline (or its entry expired).
      WARNING findings are printed but never fail.
  baseline.py record <semgrep.json> --baseline <file> [--expires YYYY-MM-DD]
      Create the adoption baseline. Refuses if the file already exists.
  baseline.py accept <semgrep.json> --baseline <file> --reason "..." --expires YYYY-MM-DD
      Add the current new ERROR findings, each with the reason and expiry given.
  baseline.py prune  <semgrep.json> --baseline <file>
      Drop entries that no longer occur (fixed findings).

Fingerprint: rule id + path + the matched line's text with whitespace
collapsed, so findings survive unrelated edits that move line numbers.
Stdlib only.
"""
import argparse
import datetime as dt
import hashlib
import json
import pathlib
import sys

DEFAULT_ADOPTION_DAYS = 180


def rule_id(check_id: str) -> str:
    return check_id.rsplit(".", 1)[-1]


def line_text(path: str, line: int) -> str:
    try:
        lines = pathlib.Path(path).read_text(errors="replace").splitlines()
        return " ".join(lines[line - 1].split()) if 0 < line <= len(lines) else ""
    except OSError:
        return ""


def fingerprint(result) -> str:
    rid = rule_id(result["check_id"])
    text = line_text(result["path"], result["start"]["line"])
    raw = f"{rid}\0{result['path']}\0{text}".encode()
    return hashlib.sha256(raw).hexdigest()[:20]


def load_results(path):
    data = json.loads(pathlib.Path(path).read_text())
    for err in data.get("errors", []):
        level = err.get("level", "error")
        if level == "error":
            print(f"semgrep error: {err.get('message', err)}", file=sys.stderr)
    return data.get("results", [])


def load_baseline(path):
    p = pathlib.Path(path)
    if not p.exists():
        return {"version": 1, "entries": []}
    return json.loads(p.read_text())


def save_baseline(path, data):
    p = pathlib.Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    data["entries"].sort(key=lambda e: (e["path"], e["rule"], e["line"]))
    p.write_text(json.dumps(data, indent=2) + "\n")


def describe(r):
    sev = r["extra"].get("severity", "?")
    msg = " ".join(r["extra"].get("message", "").split())
    return f"{r['path']}:{r['start']['line']}  [{sev}] {rule_id(r['check_id'])}\n    {msg}"


def today():
    return dt.date.today()


def partition(results, baseline):
    """Return (new_errors, warnings, expired, stale_count)."""
    budget = {}
    expired_fps = set()
    for e in baseline["entries"]:
        exp = e.get("expires")
        if exp and dt.date.fromisoformat(exp) < today():
            expired_fps.add(e["fingerprint"])
            continue
        budget[e["fingerprint"]] = budget.get(e["fingerprint"], 0) + 1
    new_errors, warnings, expired = [], [], []
    used = {}
    for r in results:
        sev = r["extra"].get("severity", "ERROR")
        if sev != "ERROR":
            warnings.append(r)
            continue
        fp = fingerprint(r)
        if used.get(fp, 0) < budget.get(fp, 0):
            used[fp] = used.get(fp, 0) + 1
            continue
        (expired if fp in expired_fps else new_errors).append(r)
    stale = sum(budget.values()) - sum(used.values())
    return new_errors, warnings, expired, stale


def entry(r, reason, expires):
    return {
        "fingerprint": fingerprint(r),
        "rule": rule_id(r["check_id"]),
        "path": r["path"],
        "line": r["start"]["line"],
        "reason": reason,
        "expires": expires,
    }


def cmd_check(args):
    results = load_results(args.results)
    baseline = load_baseline(args.baseline)
    new_errors, warnings, expired, stale = partition(results, baseline)
    for r in warnings:
        print(f"warning: {describe(r)}")
    for r in expired:
        print(f"EXPIRED baseline entry, now blocking: {describe(r)}")
    for r in new_errors:
        print(f"{describe(r)}")
    baselined = len([r for r in results if r["extra"].get("severity") == "ERROR"]) - len(new_errors) - len(expired)
    print(f"\nva-rules: {len(new_errors) + len(expired)} blocking, {len(warnings)} warning(s), {baselined} baselined")
    if stale and not args.diff_scan:
        print(f"  {stale} baseline entr{'y is' if stale == 1 else 'ies are'} fixed; shrink the baseline: "
              f"python3 .va/baseline.py prune {args.results} --baseline {args.baseline}")
    if new_errors or expired:
        print("  Fix the finding. If it is a true false positive, add `nosemgrep: <rule-id>` on that line with a reason.")
        return 1
    return 0


def cmd_record(args):
    if pathlib.Path(args.baseline).exists():
        print(f"{args.baseline} already exists. Baselines only shrink; use `accept` with a reason for a deliberate addition.",
              file=sys.stderr)
        return 1
    expires = args.expires or (today() + dt.timedelta(days=DEFAULT_ADOPTION_DAYS)).isoformat()
    results = [r for r in load_results(args.results) if r["extra"].get("severity") == "ERROR"]
    data = {"version": 1, "created": today().isoformat(),
            "entries": [entry(r, "adoption baseline", expires) for r in results]}
    save_baseline(args.baseline, data)
    print(f"recorded {len(results)} existing finding(s) in {args.baseline}, expiring {expires}")
    return 0


def cmd_accept(args):
    if not args.reason or not args.expires:
        print("accept needs --reason and --expires", file=sys.stderr)
        return 2
    dt.date.fromisoformat(args.expires)
    baseline = load_baseline(args.baseline)
    new_errors, _, expired, _ = partition(load_results(args.results), baseline)
    for r in new_errors + expired:
        baseline["entries"].append(entry(r, args.reason, args.expires))
    save_baseline(args.baseline, baseline)
    print(f"accepted {len(new_errors) + len(expired)} finding(s) until {args.expires}: {args.reason}")
    return 0


def cmd_prune(args):
    if pathlib.Path(str(args.results) + ".diff-scan").exists():
        print(f"{args.results} only covers new code (pre-push); pruning from it would empty the baseline. "
              "Run `.va/check full` and prune from .va/logs/semgrep-full.json.", file=sys.stderr)
        return 2
    baseline = load_baseline(args.baseline)
    present = {}
    for r in load_results(args.results):
        fp = fingerprint(r)
        present[fp] = present.get(fp, 0) + 1
    kept = []
    for e in baseline["entries"]:
        if present.get(e["fingerprint"], 0) > 0:
            present[e["fingerprint"]] -= 1
            kept.append(e)
    removed = len(baseline["entries"]) - len(kept)
    baseline["entries"] = kept
    save_baseline(args.baseline, baseline)
    print(f"pruned {removed} fixed finding(s); {len(kept)} remain")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["check", "record", "accept", "prune"])
    ap.add_argument("results")
    ap.add_argument("--baseline", required=True)
    ap.add_argument("--reason")
    ap.add_argument("--expires")
    ap.add_argument("--diff-scan", action="store_true",
                    help="results cover new code only (semgrep --baseline-commit): don't report fixed entries")
    args = ap.parse_args()
    return {"check": cmd_check, "record": cmd_record, "accept": cmd_accept, "prune": cmd_prune}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
