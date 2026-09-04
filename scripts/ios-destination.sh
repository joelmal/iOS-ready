#!/usr/bin/env bash
# Resolve an iOS Simulator destination dynamically.
# NEVER hardcode a device name or OS version (master plan Section 21.4).
# Prints a destination string suitable for `xcodebuild -destination`.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ "$(uname -s)" != "Darwin" ] || ! have xcrun; then
  echo "generic/platform=iOS Simulator"
  exit 0
fi

# Newest available iPhone simulator, preferring higher runtime versions.
device="$(xcrun simctl list devices available 2>/dev/null \
  | awk '/^-- iOS /{rt=$3} /iPhone/ && /\(/ {print rt"\t"$0}' \
  | sed -E 's/\(([A-F0-9-]{36})\).*$/\1/' \
  | sort -rV \
  | head -1 || true)"

if [ -z "$device" ]; then
  echo "generic/platform=iOS Simulator"
  exit 0
fi

udid="$(echo "$device" | awk -F'\t' '{print $2}' | sed -E 's/.*\(([A-F0-9-]{36})\).*/\1/' | tr -d ' ')"
if [ -n "$udid" ]; then
  echo "platform=iOS Simulator,id=$udid"
else
  echo "generic/platform=iOS Simulator"
fi
