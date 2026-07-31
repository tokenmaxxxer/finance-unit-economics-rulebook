#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate — checks ONLY that an LTV:CAC ratio in the
# finance-unit-economics record carries a band judgment, and requires
# PROXIMITY: the band word must appear near an actual ratio-token
# occurrence (within a bounded character window), not merely anywhere
# in the file — a band word in an unrelated section no longer passes.
# Does not check CAC payback (finance-cac-payback's job), sensitivity
# scenarios (finance-sensitivity-scenario's job), or the churn/NDR
# assumption behind LTV (finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_LTV_CAC_BAND_GATE_OFF=1
set -uo pipefail
deny() { echo "finance-ltv-cac-band: refused — $1" >&2; exit 2; }
case "${FINANCE_LTV_CAC_BAND_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
LCB_PAYLOAD="$payload" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-ltv-cac-band: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("LCB_PAYLOAD", ""))
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

RATIO_RE = re.compile(r'ltv[:\-/]cac')
BAND_RE = re.compile(
    r'floor|strong|red flag|3:1|4:1|5:1|2:1'
)
PROXIMITY_WINDOW = 120  # chars, either side of the ratio-token occurrence

ratio_hits = list(RATIO_RE.finditer(low))
if ratio_hits:
    band_hits = list(BAND_RE.finditer(low))
    def near_a_ratio(band_pos):
        return any(
            abs(band_pos - r.start()) <= PROXIMITY_WINDOW for r in ratio_hits
        )
    has_proximate_band = any(near_a_ratio(b.start()) for b in band_hits)
    if not has_proximate_band:
        deny(
            "LTV:CAC ratio present with no band judgment found near it "
            "(proximity check: a band word must occur within "
            + str(PROXIMITY_WINDOW) + " characters of a ratio-token "
            "occurrence, not merely anywhere in the file). Per "
            "docs/handbooks/finance-unit-economics/methodology.md, interpret "
            "against the accepted bands (>=3:1 floor, 4:1-5:1 strong, <2:1 "
            "red flag) — a bare ratio number, or a band word parked in an "
            "unrelated section, is indistinguishable from an unread one."
        )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
