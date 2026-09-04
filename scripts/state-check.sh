#!/usr/bin/env bash
# Validate state/ integrity (master plan Section 28.4): files parse, every
# requirement ID in the plan exists in the ledger, nothing is marked verified
# without evidence, and content counts match reality rather than being trusted.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
python3 "$REPO_ROOT/scripts/state_check.py"
