#!/usr/bin/env bash
# The one command that decides whether the project is healthy.
# Master plan Section 21.2.
#
# Exit code is non-zero if anything that COULD run failed. Steps that are
# impossible in this environment are skipped, recorded, and are not failures —
# but they are also never silently treated as passes.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
detect_capabilities

failed=0
declare -a SKIPPED=()
declare -A RESULT=()

run_step() {
  local key="$1" label="$2"; shift 2
  head1 "$label"
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed 's/^/  /'
  case "$rc" in
    0)  RESULT[$key]="passed" ;;
    78) local reason; reason="$(printf '%s' "$out" | sed -n 's/.*: //p' | head -1)"
        RESULT[$key]="skipped:${reason:-unavailable}"
        SKIPPED+=("$key — ${reason:-unavailable}") ;;
    *)  RESULT[$key]="failed"; failed=1 ;;
  esac
}

head1 "iOS Ready verify"
info "  environment tier   $IOSREADY_TIER   ($IOSREADY_OS)"
info "  swift              $SWIFT_VERSION"
info "  xcode              $XCODE_VERSION"
if [ "$IOSREADY_TIER" != "A" ]; then
  warn "Not Tier A: iOS build and simulator tests cannot run here and will be skipped."
  warn "Anything they would have verified must stay 'implemented-pending-verification'."
fi

run_step secret_scan       "Secret scan"              bash "$REPO_ROOT/scripts/secret-scan.sh"
run_step secret_scan_self  "Secret scan self-test"    bash "$REPO_ROOT/scripts/secret-scan.sh" --self-test
run_step content_validation "Content validation"      bash "$REPO_ROOT/scripts/validate-content.sh"
run_step content_self_test "Content validator self-test" python3 "$REPO_ROOT/scripts/validate_content.py" --self-test
run_step state_check       "State integrity"          bash "$REPO_ROOT/scripts/state-check.sh"
run_step core_tests        "Core package tests"       bash "$REPO_ROOT/scripts/test-core.sh"
run_step runner_tests      "Runner tests"             bash "$REPO_ROOT/scripts/test-runner.sh"
run_step ios_build         "iOS build"                bash "$REPO_ROOT/scripts/build-ios.sh"
run_step ios_tests         "iOS tests"                bash "$REPO_ROOT/scripts/test-ios.sh"

result="PASS"
[ "${#SKIPPED[@]}" -gt 0 ] && result="PASS_WITH_SKIPS"
[ "$failed" -ne 0 ] && result="FAIL"

head1 "Summary"
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  warn "${#SKIPPED[@]} step(s) skipped — not verified here:"
  for s in "${SKIPPED[@]}"; do info "      $s"; done
  info ""
  info "  Queue anything these would have verified in state/VERIFICATION_QUEUE.md."
fi

echo
echo "VERIFY_SUMMARY_BEGIN"
echo "tier=$IOSREADY_TIER"
echo "swift=$([ "$HAS_SWIFT" = true ] && echo present || echo absent)"
for k in secret_scan secret_scan_self content_validation content_self_test state_check \
         core_tests runner_tests ios_build ios_tests; do
  echo "$k=${RESULT[$k]:-not_run}"
done
echo "result=$result"
echo "VERIFY_SUMMARY_END"

[ "$failed" -eq 0 ] || exit 1
exit 0
