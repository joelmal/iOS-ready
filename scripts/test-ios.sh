#!/usr/bin/env bash
# Run the iPhone app test targets on a dynamically resolved simulator.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

if ! app_project_exists; then
  skip "ios tests: App/*.xcodeproj does not exist yet"
  exit 78
fi
if [ "$IOSREADY_TIER" != "A" ]; then
  skip "ios tests: requires Tier A (macOS + Xcode + simulators); this is Tier $IOSREADY_TIER"
  exit 78
fi

project="$(ls -d "$REPO_ROOT"/App/*.xcodeproj | head -1)"
dest="$("$REPO_ROOT/scripts/ios-destination.sh")"

xcodebuild test \
  -project "$project" \
  -scheme "${IOSREADY_SCHEME:-IOSReady}" \
  -destination "$dest" \
  -resultBundlePath "$REPO_ROOT/verify-output/ios-tests.xcresult" \
  -quiet
