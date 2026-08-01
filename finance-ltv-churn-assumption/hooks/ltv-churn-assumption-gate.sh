#!/usr/bin/env bash
# PreToolUse gate — checks ONLY that an LTV figure in the
# finance-unit-economics record states its churn-rate/NDR (net dollar
# retention) assumption explicitly nearby. Per issue-13 A+ upgrade, the
# existing 60-char sentence-level window is KEPT (it already correctly
# rejects "churn mentioned nowhere near a number") but is additionally
# required to fall within the SAME section as the ltv occurrence it is
# meant to qualify (survey.md §6, proposal §2 row 6) — a churn+digit pair
# elsewhere in the document no longer qualifies an unrelated ltv mention.
# A band judgment on the LTV:CAC ratio (finance-ltv-cac-band's job) does
# not substitute for this. Does not check CAC payback
# (finance-cac-payback's job) or sensitivity scenarios
# (finance-sensitivity-scenario's job).
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72) for
# JSON parsing, path normalization, and Write/Edit/MultiEdit content
# reconstruction, closing malformed-JSON-silent-allow and
# MultiEdit-blindness (survey.md §1/§2).
#
# Kill switch: export FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "ltv-churn-assumption-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-ltv-churn-assumption: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_LTV_CHURN_ASSUMPTION_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

LCA_PAYLOAD="$payload" LCA_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    def deny(msg):
        sys.stderr.write("finance-ltv-churn-assumption: refused — %s\n" % msg)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("LCA_PAYLOAD", ""), deny)
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

    root = os.environ.get("LCA_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
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

    def section_spans(text):
        heads = list(re.finditer(r'(?m)^(#{1,6})[ \t]*(.+?)[ \t]*$', text))
        if not heads:
            return [(0, len(text))]
        spans = []
        for i, m in enumerate(heads):
            level = len(m.group(1))
            start = m.end()
            end = len(text)
            for m2 in heads[i + 1:]:
                if len(m2.group(1)) <= level:
                    end = m2.start()
                    break
            spans.append((start, end))
        return spans

    if "ltv" in low:
        CHURN_RE = re.compile(
            r'\bchurn\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bchurn\b'
            r'|\bndr\b[^.\n]{0,60}?\d|\d[^.\n]{0,60}?\bndr\b'
            r'|net dollar retention[^.\n]{0,60}?\d|\d[^.\n]{0,60}?net dollar retention'
            r'|working from named-framework assumption'
        )
        spans = section_spans(new_text)
        churn_assumption = False
        for m in re.finditer(r'ltv', low):
            pos = m.start()
            sec = next(((s, e) for s, e in spans if s <= pos < e), None)
            if sec is None:
                continue
            s, e = sec
            if CHURN_RE.search(low[s:e]):
                churn_assumption = True
                break
        if not churn_assumption:
            deny(
                "LTV figure present with no churn-rate or NDR (net dollar "
                "retention) assumption stated explicitly nearby, WITHIN THE SAME "
                "SECTION as the LTV occurrence. Per "
                "docs/handbooks/finance-unit-economics/methodology.md, LTV must "
                "state the retention assumption it is computed from — a band "
                "judgment on the LTV:CAC ratio (finance-ltv-cac-band's job) does "
                "not substitute for stating what churn/NDR the LTV number itself "
                "assumes, and a churn+number pair in an unrelated section does "
                "not qualify a different LTV mention."
            )
    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("ltv-churn-assumption-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-ltv-churn-assumption: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
