#!/usr/bin/env bash
# Gate tests for finance-cac-payback/hooks/cac-payback-gate.sh
# Run: bash tests/cac-payback-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-cac-payback/hooks/cac-payback-gate.sh"
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

with_inputs="CAC payback period is 9 months, computed as CAC \$300 / (ARPU \$50 x 60% margin)."
no_inputs="CAC payback period is 9 months."
far_glossary="Glossary: CAC \$300, ARPU \$50. $(python3 -c "print('x' * 2000)") CAC payback period is 9 months, unchanged."

assert_allow "cac/arpu near payback -> allow" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$with_inputs")"

assert_deny "payback present, no inputs at all -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_inputs")"

assert_deny "cac/arpu in distant glossary, not near payback -> deny (adjacency upgrade)" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$far_glossary")"

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$no_inputs")"

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"'

mkdir -p "$proj/docs/issue-10/reports"
printf '%s' "$no_inputs" > "$proj/docs/issue-10/reports/finance-unit-economics.md"
assert_deny "MultiEdit introducing no-inputs content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_inputs" "$no_inputs still bare")"
rm -f "$proj/docs/issue-10/reports/finance-unit-economics.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_inputs")" \
    FINANCE_CAC_PAYBACK_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_inputs")" \
    FINANCE_CAC_PAYBACK_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/reports/finance-unit-economics.md" "$no_inputs")"

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/reports/../../elsewhere/finance-unit-economics.md" "$no_inputs")"

exit "$fail"
