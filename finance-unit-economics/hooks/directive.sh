#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
you_decide="YOU DECIDE: 단위경제상 성립하는가"
use_when="USE_WHEN: 가격/비용 구조가 걸린 결정일 때"
produces="PRODUCES (required record fields): unit economics model (CAC/LTV/margin), sensitivity note"
hand_off="HAND-OFF: 실제 가격 숫자 결정은 → pricing"
core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
