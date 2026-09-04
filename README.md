# iOS Ready

An iPhone-first iOS **interview-readiness engine and comeback bootcamp**: it finds
what you would struggle with in a real iOS interview, prescribes targeted practice,
verifies that you can actually write and debug the code, rehearses realistic
interviews, and produces a readiness score backed by evidence rather than vibes.

**Status: pre-implementation.** The specification is complete; application code has
not been written. See `state/PROJECT_STATE.json` for exactly where things stand.

## Read this first

- **`IOS_READY_MASTER_PLAN.md`** — the single source of truth: product, curriculum,
  scoring mathematics, architecture, milestones, and the autonomous development
  protocol. Everything else is subordinate to it.
- **`AGENTS.md`** — how a coding agent should work in this repository.
- **`docs/ARCHITECTURE.md`** — module map and dependency rules.
- **`docs/DEVELOPMENT.md`** — setup and commands.

## Quick start

```bash
make bootstrap   # detect the toolchain, write state/ENVIRONMENT.md
make verify      # the one command that decides whether the project is healthy
make help        # everything else
```

`make verify` runs everything possible in your environment and prints a summary
saying what ran, what was skipped, and why. Skipped-because-impossible is not a
failure — but it is never silently treated as a pass either.

## What is here now

| Path | Contents |
|---|---|
| `IOS_READY_MASTER_PLAN.md` | The specification |
| `Makefile`, `scripts/` | The command contract (master plan §21) |
| `Content/schemas/` | Schemas for competencies, questions, lessons, challenges, missions |
| `Content/` | Sample content: 8 competencies, 5 questions, 1 lesson |
| `state/` | Machine-readable project state and the requirement ledger |
| `docs/`, `docs/adr/` | Architecture, development, testing, security, decision records |
| `Fixtures/` | Negative fixtures proving the validators actually detect problems |

Not yet created: `Packages/IOSReadyKit` (domain logic), `App/` (the iPhone client),
`Runner/` (the Mac challenge runner). Those are Milestone 0 slices S1–S5 and need a
Swift toolchain.

## Requirements

- **Everything:** macOS with Xcode (Tier A).
- **Most of it:** any machine with a Swift toolchain (Tier B/C) — the domain logic,
  scoring, content and parsers are deliberately platform-agnostic.
- **Content, docs and state work:** any machine with Python 3 and bash.
