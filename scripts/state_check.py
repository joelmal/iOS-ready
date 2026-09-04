#!/usr/bin/env python3
"""Assert the state ledger parses and matches the repository.

The repository is always the source of truth. When this disagrees with
state/, the ledger is wrong and must be corrected (master plan 28.4).
"""
import json, re, os, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors, warnings = [], []


def err(m): errors.append(m)
def warn(m): warnings.append(m)


def load(rel):
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        err(f"missing {rel}")
        return None
    try:
        return json.load(open(p))
    except json.JSONDecodeError as e:
        err(f"{rel}: invalid JSON — {e}")
        return None


def count_content():
    counts = {"competencies": 0, "questions": 0, "behavioral": 0, "snippetChallenges": 0,
              "projectChallenges": 0, "missions": 0, "lessons": 0}
    for p in glob.glob(os.path.join(ROOT, "Content/competencies/*.json")):
        try: counts["competencies"] += len(json.load(open(p)).get("competencies", []))
        except Exception: pass
    for p in glob.glob(os.path.join(ROOT, "Content/questions/*/*.json")):
        try: counts["questions"] += len(json.load(open(p)).get("questions", []))
        except Exception: pass
    for p in glob.glob(os.path.join(ROOT, "Content/behavioral/*.json")):
        try: counts["behavioral"] += len(json.load(open(p)).get("questions", []))
        except Exception: pass
    counts["snippetChallenges"] = len(glob.glob(os.path.join(ROOT, "Content/challenges/snippets/*.json")))
    counts["projectChallenges"] = len(glob.glob(os.path.join(ROOT, "Content/challenges/projects/*/challenge.json")))
    counts["missions"] = len(glob.glob(os.path.join(ROOT, "Content/missions/*.json")))
    counts["lessons"] = len(glob.glob(os.path.join(ROOT, "Content/lessons/*.md")))
    return counts


def main():
    plan = open(os.path.join(ROOT, "IOS_READY_MASTER_PLAN.md")).read()
    plan_ids = set(re.findall(r'\b(M\d-R\d\d)\b', plan))

    reqs_doc = load("state/REQUIREMENTS.json")
    state = load("state/PROJECT_STATE.json")
    if reqs_doc is None or state is None:
        return report()

    reqs = {r["id"]: r for r in reqs_doc.get("requirements", [])}
    valid_status = set(reqs_doc.get("statusLifecycle", []))

    for rid in sorted(plan_ids - set(reqs)):
        err(f"requirement {rid} is in the master plan but missing from REQUIREMENTS.json")
    for rid in sorted(set(reqs) - plan_ids):
        warn(f"requirement {rid} is in REQUIREMENTS.json but not in the master plan")

    for rid, r in sorted(reqs.items()):
        if r.get("status") not in valid_status:
            err(f"{rid}: unknown status '{r.get('status')}'")
        if r.get("status") == "verified" and not r.get("evidence"):
            err(f"{rid}: marked verified with no evidence (28.4)")
        if r.get("status") == "blocked" and not r.get("notes"):
            err(f"{rid}: marked blocked with no notes explaining why")
        for e in r.get("evidence", []):
            path = e.split("::")[0].split(":")[0]
            if "/" in path and not os.path.exists(os.path.join(ROOT, path)):
                err(f"{rid}: evidence path does not exist: {path}")

    # Counts must be recomputed, never trusted.
    actual = count_content()
    claimed = state.get("contentCounts", {})
    for k, v in actual.items():
        if claimed.get(k) != v:
            err(f"PROJECT_STATE.contentCounts.{k} says {claimed.get(k)}, repository has {v}")

    # Tier-A requirements marked verified need a Tier-A verification on record.
    env = os.path.join(ROOT, "state/ENVIRONMENT.md")
    tier = "unknown"
    if os.path.exists(env):
        m = re.search(r"environment tier: ([ABC])", open(env).read())
        if m: tier = m.group(1)
    if tier != "A":
        for rid, r in sorted(reqs.items()):
            if r.get("verificationTier") == "A" and r.get("status") == "verified":
                warn(f"{rid}: marked verified but needs Tier A; current environment is Tier {tier}")

    counts = {}
    for r in reqs.values():
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    print(f"  requirements {len(reqs)}   " +
          "   ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    print(f"  content      " + "   ".join(f"{k} {v}" for k, v in actual.items() if v))
    return report()


def report():
    for w in warnings: print(f"  warn  {w}")
    for e in errors: print(f"  FAIL  {e}")
    if errors:
        print(f"\nstate check FAILED: {len(errors)} error(s)")
        return 1
    print(f"state check passed ({len(warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
