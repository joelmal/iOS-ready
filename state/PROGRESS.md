# Progress journal

Append-only. One entry per work session. Never rewrite history here.

Write every entry as if the next session has amnesia — because it does
(master plan 27.11). "Working on the dashboard" is useless.

---

## 2026-09-04 — Scaffolding slice (Tier C, no Swift toolchain)

**Environment:** Linux container, Tier C, **no Swift toolchain installed** and
`download.swift.org` is blocked by the outbound proxy (403), so no Swift could be
compiled or tested. Deliberately scoped this session to work that is fully
verifiable without a compiler.

**Done and verified here:**

- `.gitignore`, `.editorconfig`.
- Full command contract: `Makefile` plus `scripts/` — `lib.sh` (shared helpers and
  capability detection), `bootstrap.sh`, `ios-destination.sh`, `test-core.sh`,
  `test-runner.sh`, `build-ios.sh`, `test-ios.sh`, `validate-content.sh`,
  `secret-scan.sh`, `state-check.sh`, `verify.sh`.
- `verify.sh` emits the `VERIFY_SUMMARY` block from master plan 21.2 and correctly
  distinguishes *failed* from *skipped-because-impossible*. Confirmed by running it:
  it failed on a genuinely missing state file, then passed once the file existed.
- Secret scanner **with a proven negative fixture**: `Fixtures/secret-scan/planted.txt`
  plus `secret-scan.sh --self-test`. A scanner that only ever reports "clean" is
  indistinguishable from a broken one.
- All eight content schemas in `Content/schemas/` (competency, question, lesson
  frontmatter, behavioral, snippet challenge, project challenge, mission, interview
  template). Later-milestone schemas were written now so M2–M4 agents do not invent them.
- `scripts/validate_content.py`: dependency-free bootstrap validator implementing a
  JSON Schema subset plus the cross-file rules from 19.4 (duplicate IDs, dangling
  references, prerequisite cycles, missing required concepts, dimension/profile
  mismatch, missing contentVersion). **Also has a negative fixture and self-test**
  (`Fixtures/content-validation/broken/`).
- Sample content: 8 competencies, 5 questions, 1 lesson — written to full quality as
  the template for the M1 authoring effort, not as filler.
- `state/` ledger: `PROJECT_STATE.json`, `REQUIREMENTS.json` (all 113 requirement IDs
  extracted directly from the plan so titles cannot drift), this journal,
  `VERIFICATION_QUEUE.md`, `BLOCKERS.md`, `DECISIONS.md`.
- `AGENTS.md` / `CLAUDE.md`, `README.md`, `docs/` (ARCHITECTURE, DEVELOPMENT, TESTING,
  SECURITY_AND_PRIVACY, CONTENT_AUTHORING, GLOSSARY) and ADRs 0001–0006.
- CI workflow running `make verify` on Linux.

**Learned / worth knowing:**

- The content validator caught four dangling competency references in my own sample
  content on its first run. Left the missing competencies added rather than loosening
  the rule.
- The validator self-test initially failed because two planted violations cancelled
  each other out (a duplicate ID overwrote the entry carrying the prerequisite cycle).
  The fixture was wrong, not the validator. Fixed the fixture.
- `state/ENVIRONMENT.md` is git-ignored on purpose: it describes one machine, and
  committing it would churn and conflict across machines. `bootstrap.sh` regenerates it.
- Master plan Section 22 assumed Tier C always has a Swift toolchain. It does not
  always. Amended the plan to cover the toolchain-absent case.

**Left undone, and why:** everything Swift — M0-R02, R03, R04, R10, R11, R12, R18,
and the Swift halves of R07 and R08. Writing several thousand lines of never-compiled
Swift and handing it to a Mac would have been the exact anti-pattern in 27.8.

**Next step:** see `nextAction` in `state/PROJECT_STATE.json`.
