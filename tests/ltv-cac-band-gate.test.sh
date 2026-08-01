#!/usr/bin/env bash
# Gate tests for finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh
# Run: bash tests/ltv-cac-band-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-ltv-cac-band/hooks/ltv-cac-band-gate.sh"
fail=0
outfile="$(mktemp)"
proj="$(mk_project)"
git init -q "$proj"
trap 'rm -f "$outfile"; rm -rf "$proj"' EXIT

write_payload() { # <path> <content>
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
}

multiedit_payload() { # <path> <old> <new>
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": sys.argv[1], "edits": [{"old_string": sys.argv[2], "new_string": sys.argv[3]}]}}))
PY
}

assert_allow() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then
    echo "PASS: $name"
  else
    echo "FAIL (expected allow): $name"; cat "$outfile"; fail=1
  fi
}

assert_deny() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then
    echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
  else
    echo "PASS: $name"
  fi
}

with_band="LTV:CAC ratio is 4.5, a 3:1 floor easily cleared."
no_band="LTV:CAC ratio is 4.5, computed from the model."
band_far_away="LTV:CAC ratio is 4.5. $(python3 -c "print('x' * 300)") elsewhere this quarter is strong for other reasons."

assert_allow "band word near ratio -> allow" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$with_band")"

assert_deny "ratio present, no band word -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_band")"

assert_deny "band word present but outside proximity window -> deny (regression guard)" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$band_far_away")"

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$no_band")"

# --- mandatory: malformed JSON payload -> deny -----------------------------
assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"'

# --- mandatory: MultiEdit bypass check -------------------------------------
mkdir -p "$proj/docs/issue-10/reports"
printf '%s' "$no_band" > "$proj/docs/issue-10/reports/finance-unit-economics.md"
assert_deny "MultiEdit introducing no-band content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_band" "$no_band ratio unchanged")"
rm -f "$proj/docs/issue-10/reports/finance-unit-economics.md"

# --- mandatory: kill switch unrecognized value stays denying --------------
if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_band")" \
    FINANCE_LTV_CAC_BAND_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

# --- kill switch recognized on-value disables the gate ---------------------
if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_band")" \
    FINANCE_LTV_CAC_BAND_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

# --- mandatory: absolute path equivalent to relative path fixture ---------
assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/reports/finance-unit-economics.md" "$no_band")"

# --- mandatory: .. traversal that still ends in the matched suffix --------
assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/reports/../../elsewhere/finance-unit-economics.md" "$no_band")"

missing_core="$(mktemp -d)/no-such-core"
printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/x.md","content":"x"}}' \
  | env CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT_CORE="$missing_core" bash "$gate" >"$outfile" 2>&1
rc=$?
if [ "$rc" = 2 ]; then echo "PASS: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies (exit 2), not silent-allow"
else echo "FAIL: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere must deny (exit 2), got exit $rc"; cat "$outfile"; fail=1; fi

exit "$fail"
