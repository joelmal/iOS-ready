# ADR-0006: On-device snippet grading is structural + AI, and says so

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-06, §16.1)

## Context

There is no Swift compiler on iOS. But if coding practice requires sitting at a Mac,
then `implement` and `debug` evidence stops flowing on every day the user does not
open Xcode — which, for someone fitting interview prep around a life, is most days.
A trivia app is exactly what this product is trying not to be.

## Decision

Snippet challenges (small exercises, finish-the-code, find-the-bug, code review) run
**on iPhone**, graded by:

1. **Deterministic structural checks** (weight 0.85) — required/forbidden patterns,
   required signatures, balance checks, declared per challenge.
2. **AI code review** (weight 0.70), told which structural checks passed so it cannot
   contradict them.
3. **Optional deferred compile** (weight 0.95) — if a Mac runner is reachable, the
   snippet is compiled and its tests run there, and a stronger evidence record replaces
   the provisional one. The UI then shows "verified on Mac".

A snippet failing structural checks cannot be scored above 60 by AI review.

## Consequences

**Easier:** hands-on evidence accumulates every day, anywhere. The core loop stays
complete offline.

**Harder:** structural checks can punish a correct solution that took a different
shape. Mitigations: constrain minimally, let AI review move the score within the band,
and offer the Mac-verified upgrade path.

**Accepted cost:** on-device `implement` evidence is genuinely weaker than compiled
evidence, and the weighting says so rather than pretending otherwise. AG-2 still
requires objective evidence before a core competency's implement score exceeds 70.

## Alternatives considered

- **Mac-only coding practice.** Honest and simple; starves the loop. Rejected.
- **Trusting AI review alone on device.** No determinism, no auditability, and it would
  let a confident wrong answer score well. Rejected.

## Revisit when

Fairness complaints appear in practice — the explicit question at Human Review Gate 3.
If structural checks prove too brittle, loosen them toward signature-level checks and
lean harder on the Mac-verified upgrade.
