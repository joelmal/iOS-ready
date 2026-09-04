#!/usr/bin/env python3
"""Bootstrap content validator for iOS Ready.

This is the PRE-TOOLCHAIN validator. It exists so content can be authored and
checked in environments without a Swift toolchain. The authoritative enforcement
mechanism is `ContentValidationTests` in Packages/IOSReadyKit (master plan
Section 19.4, requirement M0-R08); when a Swift toolchain is present,
scripts/validate-content.sh prefers that and this script is a fast pre-check.

It implements a small subset of JSON Schema (type/required/properties/items/
enum/pattern/min-max/minItems) against Content/schemas/*.json, plus the
cross-file rules from Section 19.4 that JSON Schema cannot express.

Dependency-free by design: stdlib only, so it runs anywhere.
"""

import json
import re
import sys
import glob
import os

ROOT = os.environ.get("IOSREADY_CONTENT_ROOT") or os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))
errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


# --------------------------------------------------------------------------
# Minimal JSON Schema subset
# --------------------------------------------------------------------------
def validate(instance, schema, path, schemas):
    t = schema.get("type")
    if t == "object":
        if not isinstance(instance, dict):
            err(f"{path}: expected object, got {type(instance).__name__}")
            return
        for key in schema.get("required", []):
            if key not in instance:
                err(f"{path}: missing required property '{key}'")
        props = schema.get("properties", {})
        for key, value in instance.items():
            if key in props:
                validate(value, props[key], f"{path}.{key}", schemas)
    elif t == "array":
        if not isinstance(instance, list):
            err(f"{path}: expected array, got {type(instance).__name__}")
            return
        if "minItems" in schema and len(instance) < schema["minItems"]:
            err(f"{path}: needs at least {schema['minItems']} item(s), has {len(instance)}")
        if "items" in schema:
            for i, item in enumerate(instance):
                validate(item, schema["items"], f"{path}[{i}]", schemas)
    elif t == "string":
        if not isinstance(instance, str):
            err(f"{path}: expected string, got {type(instance).__name__}")
            return
        if "enum" in schema and instance not in schema["enum"]:
            err(f"{path}: '{instance}' is not one of {schema['enum']}")
        if "pattern" in schema and not re.match(schema["pattern"], instance):
            err(f"{path}: '{instance}' does not match pattern {schema['pattern']}")
    elif t == "integer":
        if not isinstance(instance, int) or isinstance(instance, bool):
            err(f"{path}: expected integer, got {type(instance).__name__}")
            return
        if "minimum" in schema and instance < schema["minimum"]:
            err(f"{path}: {instance} is below minimum {schema['minimum']}")
        if "maximum" in schema and instance > schema["maximum"]:
            err(f"{path}: {instance} is above maximum {schema['maximum']}")
    elif t == "boolean":
        if not isinstance(instance, bool):
            err(f"{path}: expected boolean, got {type(instance).__name__}")
    elif t == "number":
        if not isinstance(instance, (int, float)) or isinstance(instance, bool):
            err(f"{path}: expected number, got {type(instance).__name__}")


def load_schema(name):
    p = os.path.join(ROOT, "Content", "schemas", name)
    if not os.path.exists(p):
        err(f"schema missing: Content/schemas/{name}")
        return None
    with open(p) as f:
        return json.load(f)


def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        err(f"{os.path.relpath(path, ROOT)}: invalid JSON — {e}")
        return None


def parse_frontmatter(text):
    """Tiny YAML frontmatter reader: scalars and '- ' lists only."""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    out, key = {}, None
    for raw in text[3:end].splitlines():
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.lstrip().startswith("- ") and key:
            out.setdefault(key, []).append(line.lstrip()[2:].strip())
            continue
        if ":" in line:
            key, _, value = line.partition(":")
            key, value = key.strip(), value.strip()
            if value == "":
                out[key] = []
            elif value.isdigit():
                out[key] = int(value)
            else:
                out[key] = value.strip('"\'')
    return out


# --------------------------------------------------------------------------
def main():
    schemas = {}
    for name in ("competency", "question", "lesson-frontmatter"):
        s = load_schema(f"{name}.schema.json")
        if s:
            schemas[name] = s
    # Later-milestone schemas must at least be valid JSON.
    for p in glob.glob(os.path.join(ROOT, "Content", "schemas", "*.json")):
        load_json(p)
    if errors:
        return report()

    competencies, questions = {}, {}

    # --- competencies ---
    for p in sorted(glob.glob(os.path.join(ROOT, "Content", "competencies", "*.json"))):
        rel = os.path.relpath(p, ROOT)
        doc = load_json(p)
        if doc is None:
            continue
        if "contentVersion" not in doc:
            err(f"{rel}: missing contentVersion (rule 11)")
        for i, c in enumerate(doc.get("competencies", [])):
            validate(c, schemas["competency"], f"{rel}[{i}]", schemas)
            cid = c.get("id")
            if not cid:
                continue
            if cid in competencies:
                err(f"{rel}: duplicate competency id '{cid}' (rule 2)")
            competencies[cid] = c
            if c.get("category") and cid.split(".")[0] != c["category"]:
                warn(f"{rel}: '{cid}' id prefix does not match category '{c['category']}'")

    # --- questions ---
    for p in sorted(glob.glob(os.path.join(ROOT, "Content", "questions", "*", "*.json"))):
        rel = os.path.relpath(p, ROOT)
        doc = load_json(p)
        if doc is None:
            continue
        if "contentVersion" not in doc:
            err(f"{rel}: missing contentVersion (rule 11)")
        for i, q in enumerate(doc.get("questions", [])):
            validate(q, schemas["question"], f"{rel}[{i}]", schemas)
            qid = q.get("id")
            if not qid:
                continue
            if qid in questions:
                err(f"{rel}: duplicate question id '{qid}' (rule 2)")
            questions[qid] = q

            for cid in q.get("competencyIds", []):
                if cid not in competencies:
                    err(f"{rel}: '{qid}' references unknown competency '{cid}' (rule 3)")
            primary = q.get("primaryCompetencyId")
            if primary and primary not in q.get("competencyIds", []):
                err(f"{rel}: '{qid}' primaryCompetencyId '{primary}' not in competencyIds")

            concepts = q.get("expectedConcepts", [])
            if not concepts:
                err(f"{rel}: '{qid}' has no expectedConcepts (rule 5)")
            elif not any(c.get("required") for c in concepts):
                err(f"{rel}: '{qid}' has no required expectedConcepts (rule 5)")

            # rule 6: dimension must carry weight in the primary competency profile
            PROFILE_ZERO = {
                "concept": set(), "balanced": set(), "code": set(),
                "diagnostic": set(), "design": set(),
                "narrative": {"implement", "debug", "apply"},
            }
            comp = competencies.get(primary)
            if comp:
                zero = PROFILE_ZERO.get(comp.get("dimensionProfile"), set())
                if q.get("dimension") in zero:
                    err(f"{rel}: '{qid}' dimension '{q['dimension']}' has zero weight "
                        f"in profile '{comp['dimensionProfile']}' of '{primary}' (rule 6)")

    # --- prerequisite graph (rules 3 and 4) ---
    for cid, c in competencies.items():
        for pre in c.get("prerequisites", []):
            if pre not in competencies:
                warn(f"competency '{cid}': prerequisite '{pre}' not defined yet (rule 3)")
        for rel_id in c.get("relatedCompetencies", []):
            if rel_id not in competencies:
                warn(f"competency '{cid}': relatedCompetency '{rel_id}' not defined yet")

    WHITE, GREY, BLACK = 0, 1, 2
    color = {cid: WHITE for cid in competencies}

    def visit(node, stack):
        color[node] = GREY
        for pre in competencies[node].get("prerequisites", []):
            if pre not in competencies:
                continue
            if color[pre] == GREY:
                err(f"prerequisite cycle: {' -> '.join(stack + [node, pre])} (rule 4)")
            elif color[pre] == WHITE:
                visit(pre, stack + [node])
        color[node] = BLACK

    for cid in competencies:
        if color[cid] == WHITE:
            visit(cid, [])

    # --- lessons ---
    for p in sorted(glob.glob(os.path.join(ROOT, "Content", "lessons", "*.md"))):
        rel = os.path.relpath(p, ROOT)
        with open(p) as f:
            fm = parse_frontmatter(f.read())
        if fm is None:
            err(f"{rel}: missing or malformed YAML frontmatter")
            continue
        validate(fm, schemas["lesson-frontmatter"], rel, schemas)
        cid = fm.get("competencyId")
        if cid and cid not in competencies:
            err(f"{rel}: frontmatter competencyId '{cid}' does not exist (rule 10)")
        for qid in fm.get("relatedQuestionIds", []) or []:
            if qid not in questions:
                err(f"{rel}: relatedQuestionId '{qid}' does not exist (rule 3)")

    print(f"  competencies {len(competencies)}   questions {len(questions)}   "
          f"lessons {len(glob.glob(os.path.join(ROOT, 'Content', 'lessons', '*.md')))}")
    return report()


def report():
    for w in warnings:
        print(f"  warn  {w}")
    for e in errors:
        print(f"  FAIL  {e}")
    if errors:
        print(f"\ncontent validation FAILED: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"content validation passed ({len(warnings)} warning(s))")
    return 0


def self_test():
    """Prove the validator still detects planted violations (see Fixtures)."""
    import subprocess
    fixture = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "Fixtures", "content-validation", "broken")
    if not os.path.isdir(fixture):
        print("  FAIL  self-test: fixture missing at Fixtures/content-validation/broken")
        return 1
    env = dict(os.environ, IOSREADY_CONTENT_ROOT=fixture)
    proc = subprocess.run([sys.executable, os.path.abspath(__file__)],
                          capture_output=True, text=True, env=env)
    out = proc.stdout
    expected = [
        ("rule 2 (duplicate id)", "duplicate competency id"),
        ("rule 3 (dangling reference)", "unknown competency"),
        ("rule 4 (prerequisite cycle)", "prerequisite cycle"),
        ("rule 5 (no required concept)", "no required expectedConcepts"),
        ("schema range check", "above maximum"),
    ]
    missed = [label for label, needle in expected if needle not in out]
    if proc.returncode == 0:
        print("  FAIL  self-test: validator passed content that should have failed")
        return 1
    if missed:
        print(f"  FAIL  self-test: validator no longer detects {', '.join(missed)}")
        return 1
    print(f"  ok   content validator self-test: all {len(expected)} planted violations detected")
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    sys.exit(main())
