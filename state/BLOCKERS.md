# Blockers

Open blockers only. Each: what is blocked, why, what was tried, what is needed
from a human, and what work continued instead (master plan 27.6).

---

## B-001 — No Swift toolchain available in the web/container environment

- **Blocks:** every Swift requirement in M0 (R02, R03, R04, R10, R11, R12, R18, and
  the Swift halves of R07 and R08), and therefore all of M0-S1 through M0-S5.
- **Why:** the Claude Code web container runs Linux with no Swift installed, and the
  outbound proxy returns 403 for `download.swift.org`, so the toolchain cannot be
  fetched either.
- **Tried:** `which swift` (absent); `curl -I https://download.swift.org/...`
  (`CONNECT tunnel failed, response 403`).
- **Needed from a human:** run the Swift milestones on the MacBook (Tier A), or
  provision a container image that ships a Swift toolchain.
- **Work continued instead:** the entire non-Swift scaffolding slice — command
  contract, validators with negative fixtures, content schemas, sample content, state
  ledger, docs, ADRs, CI. See the 2026-09-04 entry in `PROGRESS.md`.
- **Status:** open. Not a defect in the project; a property of this environment.
