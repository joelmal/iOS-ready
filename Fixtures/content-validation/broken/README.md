# Deliberately broken content fixture

Every file here violates a rule from master plan Section 19.4. It exists so
`scripts/validate_content.py --self-test` can prove the validator still detects
problems. A validator that only ever reports "passed" is indistinguishable from
one that has silently stopped checking.

Planted violations:

| Rule | Violation |
|---|---|
| 1 / schema | `importance: 9` exceeds the 1–5 range |
| 2 | duplicate competency id `swift.alpha` |
| 3 | question references competency `swift.doesNotExist` |
| 4 | prerequisite cycle `swift.gamma -> swift.delta -> swift.gamma` |
| 5 | question has no `required: true` expected concept |

This directory is excluded from the real content scan.
