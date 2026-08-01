#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — checks ONLY that every metric
# named in a finance-unit-economics phase-1 proposal is sourced or
# assumption-labeled, and chained back to this role's own mandate. The
# mandate-chain check requires TWO independent signals (a mandate-naming
# word AND a separate causal/necessity word), and — per issue-13 A+
# upgrade — the two signals must occur in the SAME paragraph (blank-line
# delimited block), not merely anywhere in the document (survey.md §6,
# proposal §2 row 2).
# Does not check proposal shape (finance-proposal-shape's job) or any
# phase-2 record content (finance-ltv-cac-band / finance-cac-payback /
# finance-sensitivity-scenario / finance-ltv-churn-assumption's job).
#
# issue-13 A+ migration: rewired onto core's gate-lib.sh/.py (issue-72) for
# JSON parsing, path normalization, and Write/Edit/MultiEdit content
# reconstruction, closing malformed-JSON-silent-allow and
# MultiEdit-blindness (survey.md §1/§2).
#
# Kill switch: export FINANCE_EVIDENCE_CHAIN_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "evidence-chain-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

deny() { echo "finance-evidence-chain: refused — $1" >&2; exit 2; }

gate_kill_switch_active "${FINANCE_EVIDENCE_CHAIN_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

FE_PAYLOAD="$payload" FE_ROOT="$root" FE_ROLE="${CLAUDE_ROLE:-finance-unit-economics}" GATE_LIB_PY="$GATE_LIB_PY" python3 <<'PY'
import sys as _fc_sys
try:
    import json, os, re, sys, importlib.util

    def deny(msg):
        sys.stderr.write("finance-evidence-chain: refused — %s\n" % msg)
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("FE_PAYLOAD", ""), deny)
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

    root = os.environ.get("FE_ROOT", os.getcwd()).replace("\\", "/").rstrip("/") or "/"
    rel = gate_lib.gate_normalize_path(root, target)
    if rel is None:
        sys.exit(0)

    role = os.environ.get("FE_ROLE", "finance-unit-economics")
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/[^/]+\.md$')
    is_proposal = role == "finance-unit-economics" and PROPOSAL_RE.match(rel) is not None
    if not is_proposal:
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
    has = lambda *n: any(x in low for x in n)

    missing = []
    if has("cac", "ltv", "payback", "sensitivity"):
        if not has("http://", "https://", "working from named-framework assumption"):
            missing.append("source-or-assumption-label")

        mandate_words = ("mandate", "단위경제상 성립")
        causal_words = ("necessary", "필요", "→", "therefore", "따라서")
        chain_ok = False
        for para in re.split(r'\n\s*\n', low):
            if any(w in para for w in mandate_words) and any(w in para for w in causal_words):
                chain_ok = True
                break
        if not chain_ok:
            missing.append("evidence-to-mandate-chain")

    if missing:
        deny(
            "phase-1 proposal is missing: " + ", ".join(missing)
            + ". Per docs/handbooks/finance-unit-economics/methodology.md, every "
              "adopted metric must be sourced or assumption-labeled, and chained "
              "to this role's own mandate (단위경제상 성립하는가) within the SAME "
              "paragraph as the mandate reference — a mandate word in one "
              "paragraph and a causal word in an unrelated paragraph does not "
              "satisfy this."
        )
    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:
    _fc_sys.stderr.write("evidence-chain-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "finance-evidence-chain: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
