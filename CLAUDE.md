# Agent instructions — iOS Ready

> This file is a copy of `AGENTS.md` so both Claude Code and other agents discover
> the same instructions. Edit `AGENTS.md` and copy it here; do not let them diverge.

Short on purpose. The specification is `IOS_READY_MASTER_PLAN.md`; this file
tells you how to work in this repository. Do not duplicate the plan here.

## Before substantial work

1. Read `IOS_READY_MASTER_PLAN.md`. It is authoritative. Start with Sections 0, 5
   (Locked Decisions), 6 (Scope), 21 (Commands), 22 (Environment tiers),
   27 (Autonomous Development Protocol), 28 (State).
2. Run `make bootstrap`, then `make verify`, to establish the **actual** baseline.
   Never trust the ledger over a fresh verification.
3. Read `state/PROJECT_STATE.json`, `state/REQUIREMENTS.json`,
   `state/VERIFICATION_QUEUE.md`, `state/BLOCKERS.md`.
4. Reconcile: if the ledger claims something the repository does not support,
   **correct the ledger first** and note it in `state/PROGRESS.md`.
5. Read the current milestone section (25.x) in full. Do not implement future
   milestones.

Full sequence: master plan 27.2.

## Working rules

- Work the current milestone only, in the smallest coherent vertical slice that
  leaves `make verify` green.
- Tests are part of the implementation, not a follow-up.
- Run `make verify` before every commit. Never claim success without it; quote the
  `VERIFY_SUMMARY` block when reporting.
- **Never weaken or delete a test to go green.** If a test is genuinely wrong, fix it
  in a separate commit that explains why.
- **Never mark a requirement `verified` in an environment that cannot verify it.** Use
  `implemented-pending-verification` and add an entry to `state/VERIFICATION_QUEUE.md`
  with the exact command a Tier-A machine must run.
- Never commit secrets. `make verify` runs a scanner; do not work around it.
- Content goes in `Content/` as data, never hardcoded in Swift.
- Never hardcode a simulator name; use `scripts/ios-destination.sh`.
- No new dependencies without an ADR in `docs/adr/`.
- Update `state/` **in the same commit** as the work it describes.
- Commit messages: `M<n>-R<nn>: <summary>`.
- **Do not merge to `main`.** One milestone branch at a time.
- Stop at milestone boundaries (Human Review Gates) unless explicitly authorized to
  continue.

The full anti-pattern table is master plan 27.8. Read it once; it is short and it is
the difference between useful autonomy and confident nonsense.

## Environment tiers

`make bootstrap` detects and records the tier in `state/ENVIRONMENT.md`:

- **Tier A** — macOS + Xcode + simulators: everything.
- **Tier B** — macOS without full Xcode/simulators: package tests, content, parsers.
- **Tier C** — Linux/container: package tests (if a Swift toolchain exists), content
  validation, parser tests over recorded fixtures, authoring, docs, state.
  **A Tier C box may have no Swift toolchain at all** — then no Swift can be compiled
  or tested here, and all Swift work must be queued rather than claimed.

Roughly 80% of this project's logic is verifiable below Tier A by design. Batch UI,
simulator, and runner work for Tier A sessions.

## Writing state

Write `state/PROGRESS.md` as if the next session has amnesia — because it does.
"Working on the dashboard" is useless. Name the requirement, what exists, what does
not, and the exact next step.
