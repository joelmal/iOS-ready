# Glossary

Mirrors `IOS_READY_MASTER_PLAN.md` Section 31.

| Term | Meaning |
|---|---|
| **Competency** | A single testable skill with a stable ID; the join key for all content and scoring |
| **Dimension** | One of `explain`, `implement`, `debug`, `apply` |
| **Dimension profile** | Which dimensions matter for a competency, and their weights |
| **Evidence record** | An immutable graded outcome appended to the log; the only input to scoring |
| **Projection** | A derived value (competency state, readiness) computed purely from evidence |
| **Confidence** | How much real, diverse, recent evidence supports a score, 0–1 |
| **Unproven** | Confidence < 0.5; capped at 50 in roll-ups |
| **Stale** | Last evidence older than the competency's half-life |
| **Floor** | A minimum a category or core competency must meet for a tier, regardless of average |
| **Blocker** | A specific unmet tier requirement plus the action that clears it |
| **Tier (readiness)** | Foundation / Mid-Level / Strong Mid-Level / Senior |
| **Tier (environment)** | A / B / C — what the current machine can verify |
| **Slice** | Smallest coherent unit of work leaving the project green and demonstrably better |
| **HRG** | Human Review Gate at a milestone boundary |
| **Runner** | The Mac process that builds, tests, inspects and grades real Xcode submissions |
| **Gateway** | The AI abstraction (`Mock`, `Heuristic`, `Remote`) |
| **Structural check** | A deterministic pattern/signature check on submitted code |
| **Day-1 Usable** | The M1 bar: a real 30–60 minute study session, offline, no credentials |
