#!/usr/bin/env bash
# Purity gate for the execution slice (arc 2, S0).
#
# Asserts that the generated execution-slice modules — the fuel-opsem TCB —
# contain no unsafe-extern effect machinery. Exists because a hand-run grep
# census failed exactly here (design note §10: whitespace-defeated pattern,
# sites-vs-callers confusion); this script is the mechanized, gate-wired
# replacement. Patterns are deliberately whitespace-robust.
#
# Modes:
#   reporting (default until S2): print findings, exit 0.
#   enforcing (CERB_PURITY_ENFORCE=1, default after S2 flips it below):
#     any non-allowlisted finding fails the gate.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
GEN=lean_frontend/generated

# The execution slice (fuel-opsem TCB) per the effects design note.
EXEC_MODULES=(Core_run Core_reduction Core_eval Driver Core_run_aux
              Core_aux Defacto_memory Defacto_memory_aux Ctype_aux
              Nondeterminism Mem_aux)

# Forbidden patterns (extended regex, whitespace-robust):
#   runEffectful            — the unsafe scaffold
#   \bfresh[[:space:]]*\(   — bare Symbol.fresh application (any spacing)
#   fresh_(pretty|cn|description|funarg|object_address|pretty_with_id)\b
#   unsafeBaseIO / tagDefsIO / setTagDefsIO / resetTagDefs — extern reads
FORBIDDEN='runEffectful|[^_[:alnum:]]fresh[[:space:]]*\(|fresh_pretty|fresh_cn[^_]|fresh_description|fresh_funarg|fresh_object_address|unsafeBaseIO|tagDefsIO|setTagDefsIO|resetTagDefs'

# ALLOWLIST: exact substrings that are sanctioned exceptions. Each entry
# must cite its justification here.
#   initial_core_run_state — contains the ONE ambient read
#     (Symbol.fresh_int at sym_supply init; arc-2 S1): seeds the threaded
#     supply from the translation-phase counter so run-phase symbol ids
#     cannot collide with translation-phase ids. Everything past init is
#     threaded. The def carries @[never_extract, noinline] (effectful
#     emission), so the seed reads at call time, never cached.
ALLOWLIST=(initial_core_run_state)

# Enforcing by default since S2 (arc-2 charter).
ENFORCE="${CERB_PURITY_ENFORCE:-1}"

findings=0
for m in "${EXEC_MODULES[@]}"; do
  f="$GEN/$m.lean"
  [[ -f "$f" ]] || continue
  while IFS= read -r line; do
    allowed=0
    for a in "${ALLOWLIST[@]}"; do
      [[ "$line" == *"$a"* ]] && allowed=1 && break
    done
    if [[ $allowed -eq 0 ]]; then
      echo "PURITY: ${line:0:160}"
      findings=$((findings + 1))
    fi
  done < <(grep -nE "$FORBIDDEN" "$f" | sed "s|^|$m.lean:|" || true)
done

if [[ $findings -eq 0 ]]; then
  echo "check_exec_purity: CLEAN (${#EXEC_MODULES[@]} modules)"
  exit 0
fi

echo "check_exec_purity: $findings finding(s) in the execution slice"
if [[ "$ENFORCE" == "1" ]]; then
  echo "check_exec_purity: FAIL (enforcing mode)"
  exit 1
else
  echo "check_exec_purity: reporting mode (known state pre-S2; see arc-2 charter)"
  exit 0
fi
