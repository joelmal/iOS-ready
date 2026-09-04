# ADR-0004: One AI gateway, three real implementations, visible degradation

- **Status:** accepted
- **Date:** 2026-09-04
- **Deciders:** project owner (master plan LD-21 to LD-26, §13)

## Context

The product needs AI grading to be genuinely good, but three constraints pull against
naively calling a provider:

1. **No secret may ship in the iPhone app** — ever.
2. Development, tests and CI must never require credentials, or the whole project
   stalls behind an API key.
3. The first user must be able to study on a plane, for free.

## Decision

All AI access goes through one `AIGateway` protocol with three shipped implementations:

- **`MockGateway`** — deterministic, offline, used by every automated test.
- **`HeuristicGateway`** — local rubric/synonym scoring. **A real feature, not a stub:**
  it grades against the question's authored `expectedConcepts` and `misconceptions` and
  produces specific, useful feedback offline.
- **`RemoteGateway`** — a real model, reached via a local Mac proxy that holds the key,
  or (personal builds only) a key the user typed into Settings and stored in the Keychain.

Resolution is automatic and the active mode is **always visible in the UI** as a badge.
Degradation is never silent, because the user must know how much to trust the feedback.

Evidence from different graders carries different weight: heuristic 0.35, AI answer
grade 0.60, AI code review 0.70, automated test 1.00.

## Consequences

**Easier:** the product works with no credentials, no network and no cost. Tests never
touch the network. Providers can change without touching feature code.

**Harder:** question content must carry synonym and misconception lists for the
heuristic path to work. That is real authoring effort.

**Accepted cost:** that authoring effort — and it is worth it, because those same
fields anchor AI grading and make it auditable rather than mood-dependent.

## Alternatives considered

- **Remote-only, with a stub for tests.** Simpler, and it makes the product useless
  offline and unusable before an API key exists. Rejected against the "useful to me as
  soon as possible" goal.
- **Embedding a key for personal convenience.** Rejected outright (LD-20).

## Revisit when

Distribution to a second human is contemplated — at which point remote calls must move
behind a server-side proxy before anything ships (master plan 26.1).
