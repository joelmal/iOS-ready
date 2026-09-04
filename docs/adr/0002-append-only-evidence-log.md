# ADR-0002: Scores are projections over an append-only evidence log

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-14, LD-35, §18.2)

## Context

The product's central claim is a readiness score. Its scoring constants — source
weights, decay half-life, confidence thresholds, tier floors — are **educated guesses**
that will need retuning once real usage, and ideally a real interview outcome, exist.

If scores are stored as mutable rows updated after each attempt, retuning is
impossible: the early guesses are baked into history and the only options are to keep
them or to throw the history away.

## Decision

Facts are append-only; scores are derived.

- Every graded outcome is appended to an immutable JSONL evidence log.
- Competency, category and readiness scores are computed by a **pure function** of
  `(EvidenceLog, CompetencyRegistry, ScoringConstants, now)`.
- A snapshot caches the derived state for fast launch, tagged with the evidence count
  and constants version it came from; a mismatch triggers full recomputation.
- No SwiftData or Core Data in v1.

## Consequences

**Easier:** retuning constants recomputes all history correctly. Scoring is trivially
testable with golden fixtures. Corruption is bounded to one truncated line. Export is
a file copy. The explainability requirement (tap a score, see the evidence) falls out
of the design instead of being bolted on.

**Harder:** every read path must recompute or trust a snapshot; recomputation has a
performance budget (10k records < 200 ms, benchmarked).

**Accepted cost:** no free query engine. If querying gets complicated, that is the
signal below.

## Alternatives considered

- **Mutable score rows (SwiftData/Core Data).** Conventional, and permanently locks in
  the first guess at every constant. Rejected — this is the one property the product
  cannot afford to lose.
- **Event sourcing with a full CQRS apparatus.** Same benefit, far more machinery than
  a single-user local app needs.

## Revisit when

Evidence exceeds roughly 50k records, or the recomputation benchmark fails, or query
complexity genuinely needs indexing. Then add a SQLite-backed `Store` implementation
*behind the same protocol*, with a migration — and write the ADR that supersedes this.
