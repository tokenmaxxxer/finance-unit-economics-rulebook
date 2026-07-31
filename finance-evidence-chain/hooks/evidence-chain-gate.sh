#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — checks ONLY that every metric
# named in a finance-unit-economics phase-1 proposal is sourced or
# assumption-labeled, and chained back to this role's own mandate. The
# mandate-chain check requires TWO independent signals (a mandate-naming
# word AND a separate causal/necessity word) — a lone "→" or a lone
# connective word does not satisfy it.
# Does not check proposal shape (finance-proposal-shape's job) or any
# phase-2 record content (finance-ltv-cac-band / finance-cac-payback /
# finance-sensitivity-scenario / finance-ltv-churn-assumption's job).
#
# Kill switch: export FINANCE_EVIDENCE_CHAIN_GATE_OFF=1
set -uo pipefail
role="${CLAUDE_ROLE:-finance-unit-economics}"
deny() { echo "finance-evidence-chain: refused — $1" >&2; exit 2; }
case "${FINANCE_EVIDENCE_CHAIN_GATE_OFF:-}" in ""|0|false|no|off) ;; *) exit 0 ;; esac
command -v python3 >/dev/null 2>&1 || deny "requires python3, which is not on PATH; denying rather than guessing."
payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0
FE_PAYLOAD="$payload" FE_ROLE="$role" python3 <<'PY'
import json, os, re, sys

def deny(msg):
    sys.stderr.write("finance-evidence-chain: refused — %s\n" % msg)
    sys.exit(2)

try:
    event = json.loads(os.environ.get("FE_PAYLOAD", ""))
except Exception:
    sys.exit(0)
ti = event.get("tool_input") if isinstance(event, dict) else None
target = None
if isinstance(ti, dict):
    for k in ("file_path", "notebook_path"):
        v = ti.get(k)
        if isinstance(v, str) and v:
            target = v
            break
if not target:
    sys.exit(0)
rel = target.replace("\\", "/")
is_proposal = (
    os.environ.get("FE_ROLE") == "finance-unit-economics"
    and re.search(r'(^|/)docs/issue-[0-9]+/proposals/[^/]+\.md$', rel) is not None
)
if not is_proposal:
    sys.exit(0)

content = (ti.get("content") or ti.get("new_string") or "")
low = content.lower()
has = lambda *n: any(x in low for x in n)

missing = []
if has("cac", "ltv", "payback", "sensitivity"):
    if not has("http://", "https://", "working from named-framework assumption"):
        missing.append("source-or-assumption-label")
    # Two-signal chain check: a lone arrow or a lone connective word is not
    # a chain, only a punctuation mark or a floating word. Require at least
    # one word that names/references the mandate AND at least one separate
    # word that expresses causal necessity — two distinct categories, not
    # any-one-of-a-flat-list. A single bare "→" with nothing else fails
    # both categories and is correctly denied.
    mandate_ref = has("mandate", "단위경제상 성립")
    causal_link = has("necessary", "필요", "→", "therefore", "따라서")
    if not (mandate_ref and causal_link):
        missing.append("evidence-to-mandate-chain")
if missing:
    deny(
        "phase-1 proposal is missing: " + ", ".join(missing)
        + ". Per docs/handbooks/finance-unit-economics/methodology.md, every "
          "adopted metric must be sourced or assumption-labeled, and chained "
          "to this role's own mandate (단위경제상 성립하는가), not to general "
          "industry convention. A single bare arrow or connective word alone "
          "does not satisfy this — the chain needs a word that names the "
          "mandate AND a separate word expressing causal necessity."
    )
sys.exit(0)
PY
_fc_rc=$?
exit "$_fc_rc"
