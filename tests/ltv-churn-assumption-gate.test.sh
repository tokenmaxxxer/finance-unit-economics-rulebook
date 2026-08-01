#!/usr/bin/env bash
# Gate tests for finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh
# Run: bash tests/ltv-churn-assumption-gate.test.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
. "$here/tests/_env.sh"
gate="$here/finance-ltv-churn-assumption/hooks/ltv-churn-assumption-gate.sh"
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

with_churn="LTV computed on contribution margin, assuming 5% monthly churn."
no_churn="LTV computed on contribution margin, a strong figure this quarter."
churn_wrong_section=$'## Churn model\nchurn is 5% monthly for the whole book.\n\n## LTV\nLTV is a strong figure this quarter.'

assert_allow "ltv present with nearby churn percentage -> allow" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$with_churn")"

assert_deny "ltv present with no churn/NDR assumption anywhere -> deny" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_churn")"

assert_deny "churn+digit pair in unrelated section, ltv mention unqualified -> deny (section-scope upgrade)" \
  "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$churn_wrong_section")"

assert_allow "foreign path is a no-op regardless of content" \
  "$(write_payload "docs/issue-10/reports/qa.md" "$no_churn")"

assert_deny "malformed JSON payload -> deny (fail-closed)" '{"tool_name":"Write"'

mkdir -p "$proj/docs/issue-10/reports"
printf '%s' "$no_churn" > "$proj/docs/issue-10/reports/finance-unit-economics.md"
assert_deny "MultiEdit introducing no-churn content -> deny (parity with Write)" \
  "$(multiedit_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_churn" "$no_churn still bare")"
rm -f "$proj/docs/issue-10/reports/finance-unit-economics.md"

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_churn")" \
    FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF=maybe >"$outfile" 2>&1; then
  echo "FAIL: kill switch with unrecognized value must stay active (deny)"; cat "$outfile"; fail=1
else
  echo "PASS: kill switch unrecognized value -> gate stays active"
fi

if run_gate "$gate" "$proj" "$(write_payload "docs/issue-10/reports/finance-unit-economics.md" "$no_churn")" \
    FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF=1 >"$outfile" 2>&1; then
  echo "PASS: kill switch=1 allows would-be-denied write"
else
  echo "FAIL: kill switch=1 should disable the gate"; cat "$outfile"; fail=1
fi

assert_deny "absolute path resolves to same verdict as relative path" \
  "$(write_payload "$proj/docs/issue-10/reports/finance-unit-economics.md" "$no_churn")"

assert_allow "path with .. escaping docs/ scope is a no-op, not a match" \
  "$(write_payload "docs/issue-9/reports/../../elsewhere/finance-unit-economics.md" "$no_churn")"

missing_core="$(mktemp -d)/no-such-core"
printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/x.md","content":"x"}}' \
  | env CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT_CORE="$missing_core" bash "$gate" >"$outfile" 2>&1
rc=$?
if [ "$rc" = 2 ]; then echo "PASS: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere denies (exit 2), not silent-allow"
else echo "FAIL: CLAUDE_PLUGIN_ROOT_CORE pointed nowhere must deny (exit 2), got exit $rc"; cat "$outfile"; fail=1; fi

exit "$fail"
