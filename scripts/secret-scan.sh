#!/usr/bin/env bash
# Refuse to let a credential reach the repository (master plan LD-20).
# Scans tracked files only. Fixture files that deliberately contain fake
# credentials must live under Fixtures/secret-scan/ and are excluded.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

patterns=(
  'sk-ant-[A-Za-z0-9_-]{16,}'
  'sk-[A-Za-z0-9]{32,}'
  'ghp_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{20,}'
  '-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----'
  '(api[_-]?key|apikey|secret|password|passwd|token)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9/+_-]{20,}["'"'"']'
)

# --- self-test -------------------------------------------------------------
# `--self-test` asserts the patterns still detect a known planted fixture.
# A scanner that only ever returns "clean" is indistinguishable from a broken
# one, so this is part of the contract (master plan M0-R17).
if [ "${1:-}" = "--self-test" ]; then
  fixture="$REPO_ROOT/Fixtures/secret-scan/planted.txt"
  if [ ! -f "$fixture" ]; then
    fail "secret scan self-test: fixture missing at Fixtures/secret-scan/planted.txt"
    exit 1
  fi
  hits=0
  for p in "${patterns[@]}"; do
    if grep -InE "$p" "$fixture" >/dev/null 2>&1; then hits=$((hits + 1)); fi
  done
  if [ "$hits" -ge 3 ]; then
    ok "secret scan self-test: $hits patterns matched the planted fixture"
    exit 0
  fi
  fail "secret scan self-test: only $hits patterns matched; the scanner has regressed"
  exit 1
fi

found=0
files="$(git -C "$REPO_ROOT" ls-files 2>/dev/null || true)"
[ -z "$files" ] && { ok "secret scan: no tracked files yet"; exit 0; }

while IFS= read -r f; do
  case "$f" in
    Fixtures/secret-scan/*) continue ;;
    scripts/secret-scan.sh) continue ;;
    *.xcresult/*) continue ;;
  esac
  [ -f "$REPO_ROOT/$f" ] || continue
  for p in "${patterns[@]}"; do
    if grep -InE "$p" "$REPO_ROOT/$f" >/dev/null 2>&1; then
      fail "possible secret in $f"
      grep -InE "$p" "$REPO_ROOT/$f" | head -3 | sed 's/^/        /'
      found=1
    fi
  done
done <<< "$files"

if [ "$found" -eq 0 ]; then ok "secret scan: clean"; else fail "secret scan: findings above"; fi
exit "$found"
