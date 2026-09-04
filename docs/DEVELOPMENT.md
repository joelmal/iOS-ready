# Development

## Setup

```bash
make bootstrap    # detect toolchain, write state/ENVIRONMENT.md
make verify       # establish your baseline
```

`make help` lists everything.

## Environment tiers

`bootstrap` classifies your machine (master plan §22) and records it:

| Tier | What you have | What you can verify |
|---|---|---|
| **A** | macOS + Xcode + simulators | everything |
| **B** | macOS, no full Xcode/simulators | package tests, content, parsers |
| **C** | Linux/container | the above **if** a Swift toolchain exists; otherwise content, docs, state and scripts only |

`make verify` prints your tier and never treats a skip as a pass. If a step could not
run, whatever it would have verified stays unverified — queue it in
`state/VERIFICATION_QUEUE.md`.

## Commands

| Command | Does |
|---|---|
| `make bootstrap` | Detect toolchain, write `state/ENVIRONMENT.md` |
| `make verify` | **The** health check; prints a `VERIFY_SUMMARY` block |
| `make test-core` | `swift test` over `Packages/IOSReadyKit` |
| `make test-runner` | Runner tests (Xcode-dependent cases self-skip) |
| `make build-ios` / `make test-ios` | iPhone app on a resolved simulator (Tier A) |
| `make validate-content` | Content schemas + cross-file rules |
| `make state-check` | `state/` parses and matches the repository |
| `make secret-scan` | Refuse to let a credential reach the repo |
| `make clean` | Remove build/verification output |

## Simulator destinations

**Never hardcode a device name or OS version.** `scripts/ios-destination.sh` resolves
the newest available iPhone simulator dynamically and falls back to
`generic/platform=iOS Simulator`. Hardcoded destinations are the most common cause of
"works on my Mac, fails everywhere else" in iOS CI.

## Content validation, and which validator is authoritative

Two validators implement the same rules from master plan §19.4:

- **`ContentValidationTests`** in `Packages/IOSReadyKit` — **authoritative**. Not yet
  written (M0-R08).
- **`scripts/validate_content.py`** — a dependency-free bootstrap validator so content
  can be authored and checked without a Swift toolchain. Stays afterwards as a fast
  pre-check.

`make validate-content` prefers the Swift one when a toolchain is present. If they
ever disagree, Swift wins and the Python one is the bug.

Both validators, and the secret scanner, ship **negative fixtures** under `Fixtures/`
and `--self-test` modes, because a checker that only ever reports success is
indistinguishable from one that has silently stopped checking. `make verify` runs the
self-tests.

## Secrets

Never commit one. Keys live in the Keychain (app) or the environment (CLI/runner),
never in source, plists, fixtures or content. `make verify` scans tracked files. If
you need a fake credential for a test, put it under `Fixtures/secret-scan/`, which is
excluded from the scan and asserted against by the self-test.

## Troubleshooting

**`make verify` says `swift=absent`.** You have no Swift toolchain. On macOS install
Xcode; on Linux see <https://www.swift.org/install/>. Until then, do not write Swift
you cannot compile — pick up content, docs, schema, or state work instead.

**`state check FAILED: contentCounts ... repository has N`.** The ledger drifted.
The repository is right: update `state/PROJECT_STATE.json`.

**`ios_build=skipped:no-xcode` on a Mac.** `xcodebuild -version` is failing — usually
`xcode-select` pointing at the Command Line Tools rather than Xcode.
