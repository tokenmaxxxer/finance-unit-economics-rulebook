#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate — checks ONLY that a sensitivity/scenario section in
# the finance-unit-economics record carries at least two distinct
# labeled numeric scenarios, not a token-only heading. Does not check
# the LTV:CAC band (finance-ltv-cac-band's job), CAC payback
# (finance-cac-payback's job), or the churn/NDR assumption behind LTV
# (finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_SENSITIVITY_SCENARIO_GATE_OFF=1
set -uo pipefail
deny() { echo "finance-sensitivity-scenario: refused — $1" >&2; exit 2; }
case "${FINANCE_SENSITIVITY_SCENARIO_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
SS_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-sensitivity-scenario: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("SS_PAYLOAD", ""))
except Exception:
    sys.exit(0)
ti = event.get("tool_input") if isinstance(event, dict) else None
target = None
if isinstance(ti, dict):
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str):
            target = v
            break
if not target or not target.replace("\\", "/").endswith("/reports/finance-unit-economics.md"):
    sys.exit(0)

content = (ti.get("content") or ti.get("new_string") or "") if isinstance(ti, dict) else ""
low = content.lower()

scenario_labels = re.findall(
    r'\bscenario\s*\d\b|\bbase case\b|\bdownside\b|\bupside\b|\bbull\b|\bbear\b',
    low,
)
if "sensitivity" in low and len(set(scenario_labels)) < 2:
    deny(
        "sensitivity section present with fewer than two labeled numeric "
        "scenarios. Per docs/handbooks/finance-unit-economics/methodology.md, "
        "give at least two distinct scenarios (e.g. base case vs. downside) "
        "— a heading with one scenario, or numbers with no scenario labels, "
        "is a token-only heading, not the content."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
