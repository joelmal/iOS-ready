#!/usr/bin/env bash
# Run the platform-agnostic domain package tests (master plan Section 17.1).
# Exit codes: 0 pass, 1 fail, 78 skipped (nothing to run in this environment).
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

if ! package_exists; then
  skip "core tests: Packages/IOSReadyKit does not exist yet"
  exit 78
fi
if [ "$HAS_SWIFT" != true ]; then
  skip "core tests: no Swift toolchain in this environment"
  exit 78
fi

cd "$REPO_ROOT/Packages/IOSReadyKit"
swift test "$@"
