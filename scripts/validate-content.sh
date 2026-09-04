#!/usr/bin/env bash
# Validate Content/ against Content/schemas/ and the cross-file rules in
# master plan Section 19.4.
#
# Prefers the authoritative Swift ContentValidationTests when a toolchain is
# available; otherwise falls back to the dependency-free Python pre-check so
# content can still be authored and verified in a toolchain-less environment.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

if [ "$HAS_SWIFT" = true ] && package_exists; then
  if (cd "$REPO_ROOT/Packages/IOSReadyKit" && swift test --filter ContentValidationTests) ; then
    ok "content validation (Swift, authoritative)"
    exit 0
  else
    fail "content validation (Swift, authoritative)"
    exit 1
  fi
fi

python3 "$REPO_ROOT/scripts/validate_content.py"
