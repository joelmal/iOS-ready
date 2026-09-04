# Verification queue

Work that is implemented but could not be verified in the environment where it
was written (master plan Section 22.1). **A milestone cannot pass its Human
Review Gate while this file is non-empty** (27.9 step 6).

Each entry: requirement, what to verify, the exact command, expected result.

---

## M0-R05 — Command contract, Tier A paths

- **Verify:** `build-ios.sh` and `test-ios.sh` actually drive `xcodebuild` correctly
  once `App/*.xcodeproj` exists. Only their skip paths have been exercised.
- **Command:** `make bootstrap && make verify` on macOS with Xcode installed.
- **Expected:** `tier=A`, `ios_build=passed`, `ios_tests=passed` in the
  `VERIFY_SUMMARY` block (after the app target exists — before then, they skip).

## M0-R06 — Dynamic simulator destination resolution

- **Verify:** `scripts/ios-destination.sh` returns a real, bootable destination and
  not the `generic/platform=iOS Simulator` fallback.
- **Command:** `bash scripts/ios-destination.sh` on macOS with simulators installed.
- **Expected:** a string of the form `platform=iOS Simulator,id=<UDID>` where the
  UDID appears in `xcrun simctl list devices available`. The awk/sed parsing of
  `simctl` output has **never been run against real output** — treat it as unproven
  and expect to fix it.

## M0-R19 — CI workflow

- **Verify:** `.github/workflows/verify.yml` actually runs green on a Linux runner.
- **Command:** push the branch and inspect the Actions run.
- **Expected:** `make verify` exits 0 with `result=PASS_WITH_SKIPS`.
