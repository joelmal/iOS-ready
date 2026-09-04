# Implementation decisions and deferred ideas

Small decisions that did not warrant a full ADR, plus ideas deliberately not
implemented so they are neither lost nor silently built (master plan 28.3).

---

## Decisions

**D-001 — `state/ENVIRONMENT.md` is git-ignored.** It describes one machine. Committing
it would churn on every push from a different machine and conflict constantly.
`bootstrap.sh` regenerates it; `state-check.sh` tolerates its absence.

**D-002 — Later-milestone content schemas written during M0.** The plan only requires
schemas for content that exists yet, but writing all eight now costs little and stops
M2/M3/M4 agents inventing incompatible shapes. They are versioned and may be revised
at their milestone.

**D-003 — `scripts/validate_content.py` is explicitly a *pre-toolchain* validator.**
The authoritative validator remains the Swift `ContentValidationTests` (M0-R08).
`validate-content.sh` prefers Swift when a toolchain exists. The Python one stays
afterwards as a fast pre-commit check and as the only option in toolchain-less
environments. Both must implement the same rules from 19.4; if they diverge, Swift wins.

**D-004 — Both the secret scanner and the content validator ship negative fixtures
and `--self-test` modes.** A checker that only ever reports success is indistinguishable
from one that has silently stopped checking. `make verify` runs both self-tests.

**D-005 — Sample content written to full production quality.** M0 only needs enough
content to prove the pipeline, but the samples double as the authoring template for
the 150-question M1 effort, so shortcuts here would propagate.

## Deferred ideas (do not implement without a decision)

- **Content authoring CLI** (`scripts/new-question.sh` scaffolding a question from a
  competency ID). Likely worth it once authoring starts in volume at M1-S9. Not now.
- **A pre-commit hook** wiring `make verify`. Useful, but hooks are per-clone and
  easy to bypass; CI is the real gate. Revisit if the loop gets sloppy.
- **`swiftformat` / `swiftlint`.** `make lint` is a deliberate no-op until a human
  decides the friction is worth it (master plan M0-R05: "only if it adds low-friction
  value").
