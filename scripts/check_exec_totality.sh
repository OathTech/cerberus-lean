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
  # Lexer-grade scan (arc-3 audit F1-F5): strings, char literals, `--` line
  # comments, and nested /- -/ block comments are stripped BEFORE matching,
  # and the match is a word-level `partial` followed by `def`/`instance`
  # across any whitespace (catches split lines, `protected`, multi-attribute
  # prefixes). The scan MUST succeed — a scanner failure fails the gate
  # (fail-closed), it does not silently report CLEAN.
  scan_out=$(python3 - "$f" <<'PYEOF'
import re, sys
src = open(sys.argv[1]).read()
cur = []
depth = 0
i = 0
n = len(src)
while i < n:
    two = src[i:i+2]
    if depth > 0:
        if two == '/-': depth += 1; i += 2; continue
        if two == '-/': depth -= 1; i += 2; continue
        if src[i] == '\n': cur.append('\n')
        i += 1; continue
    if two == '/-':
        depth += 1; i += 2; continue
    if two == '--':
        j = src.find('\n', i)
        i = n if j == -1 else j
        continue
    c = src[i]
    if c == '"':
        cur.append(' '); i += 1
        while i < n:
            if src[i] == '\\': i += 2; continue
            if src[i] == '"': i += 1; break
            if src[i] == '\n': cur.append('\n')
            i += 1
        continue
    if c == '\'' and i + 1 < n and (src[i+1] == '\\' or (i + 2 < n and src[i+2] == '\'')):
        # char literal 'x' or '\n'
        j = src.find('\'', i + 2 if src[i+1] != '\\' else i + 3)
        i = (j + 1) if j != -1 else n
        cur.append(' ')
        continue
    cur.append(c); i += 1
clean = ''.join(cur)
for m in re.finditer(r'\bpartial\s+(def|instance)\s+([A-Za-z_0-9α-ω.\']*)', clean):
    line = clean.count('\n', 0, m.start()) + 1
    print(f"{line}:{m.group(2) or '<anonymous>'}")
PYEOF
)
  scan_rc=$?
  if [[ $scan_rc -ne 0 ]]; then
    echo "check_exec_totality: SCANNER FAILED on $f (rc=$scan_rc)"
    echo "check_exec_totality: FAIL (fail-closed)"
    exit 1
  fi
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    name="${hit#*:}"
    key="$m.$name"
    if [[ -n "${allowed[$key]+x}" ]]; then
      allowed["$key"]=1
    else
      echo "  PARTIAL $key  (line ${hit%%:*})"
      findings=$((findings+1))
    fi
  done <<< "$scan_out"
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
