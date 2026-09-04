# Testing

Authoritative source: `IOS_READY_MASTER_PLAN.md` Section 23.

## Principles

- Business logic requires tests. UI existing is not evidence anything works.
- **Deterministic or it does not count**: no real network, no real clock, no `sleep`,
  no filesystem outside a temp dir, no unseeded randomness. `Clock` and `UUIDProvider`
  are injected from the first commit.
- Never weaken or delete a test to make a build pass. If a test is genuinely wrong,
  fix it in a separate commit that says why.
- Test behavior at module boundaries, not private implementation detail.

## Layers

**Unit** (in `IOSReadyKit`, must run without Xcode): scoring and readiness (the full
list in master plan 11.10), spaced repetition, session generation, content loading and
validation, AI response parsing (valid/malformed/truncated/inconsistent/injection),
the heuristic grader, persistence round trips and migrations, resume parsing and
redaction, xcresult parsing over recorded fixtures, structural checks, and the
module-dependency test.

**Integration**: content → session → attempt → evidence → recomputed readiness with
`MockGateway`, asserting the score actually moves and in the right direction; store
round trip on a temp directory; runner submissions against fixture projects (Tier A).

**UI** (Tier A, deliberately few and stable): complete a question attempt; run and
finish a generated session with progress surviving relaunch; dashboard reflects a
score change; a short mock interview (from M2).

**Benchmarks**: readiness recomputation over 10k evidence records < 200 ms; full
content load < 150 ms; dashboard cold render < 300 ms.

## Coverage posture

No numeric coverage target — coverage percentages invite gaming, which would be
especially ironic in this product. Instead: **every rule in master plan Sections 11,
12, 16.4 and 19.4 has at least one named test**, and every bug fixed gets a regression
test.

## Self-testing checkers

Validators ship negative fixtures and prove they still detect problems:

| Checker | Fixture | Self-test |
|---|---|---|
| Secret scanner | `Fixtures/secret-scan/planted.txt` | `scripts/secret-scan.sh --self-test` |
| Content validator | `Fixtures/content-validation/broken/` | `scripts/validate_content.py --self-test` |

Both run inside `make verify`. When you add a validation rule, add a planted violation
to the fixture and assert it in the self-test — otherwise you cannot tell a passing
checker from a broken one.

## Fixtures

`Fixtures/evidence/*.jsonl` with `*.expected.json` are the golden scoring tests. When
you deliberately retune a scoring constant, regenerate goldens in a **separate commit**
whose message explains the rationale. Never regenerate them to make a failing test pass.
