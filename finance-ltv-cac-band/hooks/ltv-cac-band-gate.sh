#!/usr/bin/env bash
# PreToolUse gate — checks ONLY that an LTV:CAC ratio in the
# finance-unit-economics record carries a band judgment, and requires
# PROXIMITY: the band word must appear near an actual ratio-token
# occurrence (within a bounded character window), not merely anywhere
# in the file — a band word in an unrelated section does not pass. This
# was already the best-in-repo precedent (issue-13 proposal §2: "no
# functional change" row) — the other 6 gates in this plugin set are
# upgraded to match its adjacency pattern; the check logic here is
# unchanged, only the input plumbing is migrated (below).
# Does not check CAC payback (finance-cac-payback's job), sensitivity
# scenarios (finance-sensitivity-scenario's job), or the churn/NDR
# assumption behind LTV (finance-ltv-churn-assumption's job).
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72) for
# JSON parsing, path normalization, and Write/Edit/MultiEdit content
# reconstruction, closing malformed-JSON-silent-allow and
# MultiEdit-blindness (survey.md §1/§2).
#
# Kill switch: export FINANCE_LTV_CAC_BAND_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-ltv-cac-band: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_LTV_CAC_BAND_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

LCB_PAYLOAD="$payload" LCB_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    def deny(msg):
        sys.stderr.write("finance-ltv-cac-band: refused — %s\n" % msg)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("LCB_PAYLOAD", ""), deny)
    tool = event.get("tool_name") or ""
    ti = event.get("tool_input")
    if not isinstance(ti, dict):
        sys.exit(0)

    target = None
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str) and v:
            target = v
            break
    if target is None:
        sys.exit(0)

    root = os.environ.get("LCB_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
    rel = gate_lib.gate_normalize_path(root, target)
    if rel is None:
        sys.exit(0)

    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/finance-unit-economics\.md$')
    if not RECORD_RE.match(rel):
        sys.exit(0)

    current = None
    p = os.path.join(root, rel)
    if os.path.isfile(p):
        try:
            with open(p, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok or new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting "
            "content from the tool input (tool=%r)." % (rel, tool)
        )

    low = new_text.lower()

    RATIO_RE = re.compile(r'ltv[:\-/]cac')
    BAND_RE = re.compile(r'floor|strong|red flag|3:1|4:1|5:1|2:1')
    PROXIMITY_WINDOW = 120

    ratio_hits = list(RATIO_RE.finditer(low))
    if ratio_hits:
        band_hits = list(BAND_RE.finditer(low))

        def near_a_ratio(band_pos):
            return any(abs(band_pos - r.start()) <= PROXIMITY_WINDOW for r in ratio_hits)

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
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("ltv-cac-band-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-ltv-cac-band: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
