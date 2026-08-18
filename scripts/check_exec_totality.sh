#!/usr/bin/env bash
# Totality gate for the execution slice (arc 3).
#
# Asserts that the generated execution-slice modules contain no `partial`
# definitions outside the committed allowlist. Counting is line-anchored but
# indentation/attribute-tolerant: the arc-3 S0 census found 97 partials where
# hand regexes had found 41 — mutual-block members are indented and some defs
# carry attributes (design note §10 failure mode, third occurrence).
#
# Modes:
#   default    — report findings, always exit 0 (sweep-in-progress mode)
#   ENFORCE=1  — exit 1 on any non-allowlisted finding OR any stale
#                allowlist entry (fail-closed in both directions)
set -u
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GEN="$SCRIPT_DIR/../lean_frontend/generated"
ALLOW="$SCRIPT_DIR/exec_totality_allowlist.txt"
ENFORCE="${ENFORCE:-0}"

# Same slice as check_exec_purity.sh (keep the two lists in lockstep).
EXEC_MODULES=(Core_run Core_reduction Core_eval Driver Core_run_aux
              Core_aux Defacto_memory Defacto_memory_aux Ctype_aux
              Nondeterminism Mem_aux)

declare -A allowed=()
if [[ -f "$ALLOW" ]]; then
  while IFS= read -r line; do
    entry="${line%%#*}"; entry="${entry//[[:space:]]/}"
    [[ -n "$entry" ]] && allowed["$entry"]=0
  done < "$ALLOW"
fi

findings=0
for m in "${EXEC_MODULES[@]}"; do
  f="$GEN/$m.lean"
  [[ -f "$f" ]] || { echo "check_exec_totality: MISSING $f"; findings=$((findings+1)); continue; }
  while IFS= read -r hit; do
    name=$(sed -E 's/^[0-9]+:[[:space:]]*(@\[[^]]*\][[:space:]]*)?(private[[:space:]]+)?partial[[:space:]]+(def|instance)[[:space:]]+([A-Za-z_0-9'\''.]+).*/\4/' <<<"$hit")
    key="$m.$name"
    if [[ -n "${allowed[$key]+x}" ]]; then
      allowed["$key"]=1
    else
      echo "  PARTIAL $key  (${hit%%:*})"
      findings=$((findings+1))
    fi
  done < <(python3 - "$f" <<'PYEOF'
# Blank out nested /- -/ block comments, then emit lines that declare a
# partial def/instance (a sorry-target_rep'd def can be a whole partial def
# inside a block comment — arc-3 S0 false positive, easy_update_mem_value_aux).
import re, sys
src = open(sys.argv[1]).read()
out, depth, i, cur = [], 0, 0, []
while i < len(src):
    two = src[i:i+2]
    if two == '/-':
        depth += 1; i += 2; continue
    if two == '-/' and depth > 0:
        depth -= 1; i += 2; continue
    ch = src[i]
    if depth == 0:
        cur.append(ch)
    elif ch == '\n':
        cur.append('\n')
    i += 1
pat = re.compile(r'^[ \t]*(@\[[^\]]*\][ \t]*)?(private[ \t]+)?partial[ \t]+(def|instance)[ \t]')
for n, line in enumerate(''.join(cur).split('\n'), 1):
    if pat.match(line):
        print(f"{n}:{line}")
PYEOF
)
done

stale=0
for k in "${!allowed[@]}"; do
  if [[ "${allowed[$k]}" == 0 ]]; then
    echo "  STALE allowlist entry: $k (no matching partial def)"
    stale=$((stale+1))
  fi
done

if [[ $findings -eq 0 && $stale -eq 0 ]]; then
  echo "check_exec_totality: CLEAN (${#EXEC_MODULES[@]} modules, ${#allowed[@]} allowlisted)"
  exit 0
fi
echo "check_exec_totality: $findings non-allowlisted partial(s), $stale stale allowlist entr(ies)"
if [[ "$ENFORCE" == "1" ]]; then
  echo "check_exec_totality: FAIL (enforcing mode)"
  exit 1
fi
echo "check_exec_totality: reporting mode (sweep in progress)"
exit 0
