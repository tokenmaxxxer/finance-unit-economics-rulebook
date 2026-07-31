#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate — checks ONLY that a CAC payback period in the
# finance-unit-economics record shows its formula inputs (CAC, ARPU)
# visibly next to the number. Does not check the LTV:CAC band
# (finance-ltv-cac-band's job), sensitivity scenarios
# (finance-sensitivity-scenario's job), or the churn/NDR assumption
# behind LTV (finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_CAC_PAYBACK_GATE_OFF=1
set -uo pipefail
deny() { echo "finance-cac-payback: refused — $1" >&2; exit 2; }
case "${FINANCE_CAC_PAYBACK_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
CP_PAYLOAD="$payload" python3 <<'PY'
import json, os, sys

def deny(msg):
    sys.stderr.write("finance-cac-payback: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("CP_PAYLOAD", ""))
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

if "payback" in low and not ("cac" in low and "arpu" in low):
    deny(
        "CAC payback period present with its formula inputs not visible "
        "nearby. Per docs/handbooks/finance-unit-economics/methodology.md, "
        "show CAC / (Monthly ARPU x Gross Margin %) inputs next to the "
        "number — a bare payback number cannot be checked by a reader."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
