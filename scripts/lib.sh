#!/usr/bin/env bash
# Shared helpers for iOS Ready scripts. Sourced, not executed.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# --- output helpers -------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_DIM=$'\033[2m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_DIM=""
fi

info()  { printf '%s\n' "$*"; }
head1() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
ok()    { printf '%s  ok%s   %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s  warn%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
fail()  { printf '%s  FAIL%s %s\n' "$C_RED" "$C_RESET" "$*"; }
skip()  { printf '%s  skip %s%s\n' "$C_DIM" "$*" "$C_RESET"; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- capability detection -------------------------------------------------
# Sets: IOSREADY_TIER, IOSREADY_OS, HAS_SWIFT, HAS_XCODEBUILD, HAS_SIMULATORS,
#       SWIFT_VERSION, XCODE_VERSION
detect_capabilities() {
  IOSREADY_OS="$(uname -s)"
  HAS_SWIFT=false; HAS_XCODEBUILD=false; HAS_SIMULATORS=false
  SWIFT_VERSION="absent"; XCODE_VERSION="absent"

  if have swift; then
    HAS_SWIFT=true
    SWIFT_VERSION="$(swift --version 2>/dev/null | head -1 | tr -d '\n')"
  fi

  if [ "$IOSREADY_OS" = "Darwin" ] && have xcodebuild; then
    if xcodebuild -version >/dev/null 2>&1; then
      HAS_XCODEBUILD=true
      XCODE_VERSION="$(xcodebuild -version 2>/dev/null | head -1 | tr -d '\n')"
      if have xcrun && xcrun simctl list devices available 2>/dev/null | grep -q 'iPhone'; then
        HAS_SIMULATORS=true
      fi
    fi
  fi

  if [ "$HAS_XCODEBUILD" = true ] && [ "$HAS_SIMULATORS" = true ]; then
    IOSREADY_TIER="A"
  elif [ "$IOSREADY_OS" = "Darwin" ]; then
    IOSREADY_TIER="B"
  else
    IOSREADY_TIER="C"
  fi

  export IOSREADY_TIER IOSREADY_OS HAS_SWIFT HAS_XCODEBUILD HAS_SIMULATORS \
         SWIFT_VERSION XCODE_VERSION
}

# True when the Swift package exists on disk (it does not until M0-S1 lands).
package_exists() { [ -f "$REPO_ROOT/Packages/IOSReadyKit/Package.swift" ]; }
app_project_exists() { compgen -G "$REPO_ROOT/App/*.xcodeproj" >/dev/null 2>&1; }
runner_exists() { [ -f "$REPO_ROOT/Runner/Package.swift" ]; }
