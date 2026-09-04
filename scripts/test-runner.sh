#!/usr/bin/env bash
# Run the Mac challenge-runner tests. Xcode-dependent cases skip themselves.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

if ! runner_exists; then
  skip "runner tests: Runner/ does not exist yet"
  exit 78
fi
if [ "$HAS_SWIFT" != true ]; then
  skip "runner tests: no Swift toolchain in this environment"
  exit 78
fi

cd "$REPO_ROOT/Runner"
swift test "$@"
