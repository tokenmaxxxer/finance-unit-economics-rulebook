#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate — checks ONLY that an LTV figure in the
# finance-unit-economics record states its churn-rate/NDR (net dollar
# retention) assumption explicitly nearby. A band judgment on the
# LTV:CAC ratio (finance-ltv-cac-band's job) does not substitute for
# this. Does not check CAC payback (finance-cac-payback's job) or
# sensitivity scenarios (finance-sensitivity-scenario's job).
#
# Kill switch: export FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF=1
set -uo pipefail
deny() { echo "finance-ltv-churn-assumption: refused — $1" >&2; exit 2; }
case "${FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
LCA_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-ltv-churn-assumption: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("LCA_PAYLOAD", ""))
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

if "ltv" in low:
    churn_assumption = re.search(
        r'\bchurn\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bchurn\b'
        r'|\bndr\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bndr\b'
        r'|net dollar retention[^.\n]{0,60}?\d|\d[^.\n]{0,60}?net dollar retention'
        r'|working from named-framework assumption',
        low,
    )
    if not churn_assumption:
        deny(
            "LTV figure present with no churn-rate or NDR (net dollar "
            "retention) assumption stated explicitly nearby. Per "
            "docs/handbooks/finance-unit-economics/methodology.md, LTV must "
            "state the retention assumption it is computed from — a band "
            "judgment on the LTV:CAC ratio (finance-ltv-cac-band's job) does "
            "not substitute for stating what churn/NDR the LTV number itself "
            "assumes."
        )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
