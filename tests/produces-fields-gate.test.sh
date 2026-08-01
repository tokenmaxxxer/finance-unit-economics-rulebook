#!/usr/bin/env bash
# Gate tests for finance-unit-economics/hooks/produces-fields-gate.sh
# (issue-13: this gate previously shipped with no test file at all).
# Run: bash tests/produces-fields-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-unit-economics/hooks/produces-fields-gate.sh"
fail=0
outfile="$(mktemp)"
proj="$(mk_project)"
git init -q "$proj"
trap 'rm -f "$outfile"; rm -rf "$proj"' EXIT

write_payload() {
  python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
}
multiedit_payload() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": sys.argv[1], "edits": [{"old_string": sys.argv[2], "new_string": sys.argv[3]}]}}))
PY
}
assert_allow() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then echo "PASS: $name"
  else echo "FAIL (expected allow): $name"; cat "$outfile"; fail=1; fi
}
assert_deny() {
  local name="$1" payload="$2"
  if run_gate "$gate" "$proj" "$payload" >"$outfile" 2>&1; then echo "FAIL (expected deny): $name"; cat "$outfile"; fail=1
  else echo "PASS: $name"; fi
}

full_record=$'## cac\n$300 this cycle.\n\n## ltv\n$1200 on contribution margin.\n\n## ltv-cac-ratio\n4:1, strong.\n\n## cac-payback-period\n9 months.\n\n## sensitivity-note\nbase case vs downside, +/-10%.'
missing_ltv=$'## cac\n$300 this cycle.\n\n## ltv-cac-ratio\n4:1, strong.\n\n## cac-payback-period\n9 months.\n\n## sensitivity-note\nbase case vs downside, +/-10%.'
stray_substring=$'## cac\n$300 this cycle, unrelated mention of ltv here in prose.\n\n## ltv-cac-ratio\n4:1, strong.\n\n## cac-payback-period\n9 months.\n\n## sensitivity-note\nbase case vs downside, +/-10%.'
heading_no_number=$'## cac\nsee appendix for the figure.\n\n## ltv\n$1200 on contribution margin.\n\n## ltv-cac-ratio\n4:1, strong.\n\n## cac-payback-period\n9 months.\n\n## sensitivity-note\nbase case vs downside, +/-10%.'

assert_allow "all five PRODUCES fields as headings with numbers -> allow" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$full_record")"

assert_deny "ltv heading entirely absent -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$missing_ltv")"

assert_deny "stray 'ltv' substring in cac section, no real ltv heading -> deny (section-heading upgrade)" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$stray_substring")"

assert_deny "cac heading present but no numeric content in its own section -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$heading_no_number")"

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$missing_ltv")"

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"'

mkdir -p "$proj/docs/issue-10/reports"
printf '%s' "$missing_ltv" > "$proj/docs/issue-10/reports/finance-unit-economics.md"
assert_deny "MultiEdit leaving ltv heading absent -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/reports/finance-unit-economics.md" "$missing_ltv" "$missing_ltv still missing ltv")"
rm -f "$proj/docs/issue-10/reports/finance-unit-economics.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$missing_ltv")" \
    FINANCE_UNIT_ECONOMICS_CYCLE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$missing_ltv")" \
    FINANCE_UNIT_ECONOMICS_CYCLE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/reports/finance-unit-economics.md" "$missing_ltv")"

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/reports/../../elsewhere/finance-unit-economics.md" "$missing_ltv")"

exit "$fail"
