#!/usr/bin/env bash
# Build the iPhone app for a dynamically resolved simulator destination.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

if ! app_project_exists; then
  skip "ios build: App/*.xcodeproj does not exist yet"
  exit 78
fi
if [ "$IOSREADY_TIER" != "A" ]; then
  skip "ios build: requires Tier A (macOS + Xcode + simulators); this is Tier $IOSREADY_TIER"
  exit 78
fi

project="$(ls -d "$REPO_ROOT"/App/*.xcodeproj | head -1)"
dest="$("$REPO_ROOT/scripts/ios-destination.sh")"
info "  project     $(basename "$project")"
info "  destination $dest"

xcodebuild build \
  -project "$project" \
  -scheme "${IOSREADY_SCHEME:-IOSReady}" \
  -destination "$dest" \
  -quiet \
  ${IOSREADY_WARNINGS_AS_ERRORS:+SWIFT_TREAT_WARNINGS_AS_ERRORS=YES}
