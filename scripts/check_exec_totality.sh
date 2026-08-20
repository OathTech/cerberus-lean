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
#
# BOUNDARY HONESTY (arc-4 S5f, audit G3; amended arc-7 S2): the 11-module
# list below covers GENERATED modules; since arc-7 S2 the gate ALSO scans
# the hand-written runner CerbND.lean (totalized by the operator's Q1
# AMENDED ruling — partial runND/runND1 are gone and may not return: the
# runner-soundness theorems in lean_frontend/relsem/RelSem/RunND.lean are
# stated against it, and `partial` would silently re-opacify them).
# CerbND thereby LEAVES the arc-4 G3 declared boundary. Still OUTSIDE the
# gate and NOT partial-free: CerbMem.lean carries ONE partial def
# (stringFromMemValue, pp-only — the nine exec-path functions were
# fuel-totalized in arc-7 S4, escalation event 1) and panic! sites;
# CerbTags.lean carries the with_tagDefs axiom.
# Declared-boundary record: 2026-08-19_arc4-results.md (CerbND exit to be
# recorded in the arc-7 results doc at close). Expanding the gate to the
# remaining hand-written seams is a priced next-arc item.
set -u
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GEN="$SCRIPT_DIR/../lean_frontend/generated"
ALLOW="$SCRIPT_DIR/exec_totality_allowlist.txt"
ENFORCE="${ENFORCE:-0}"

# First 11 = same slice as check_exec_purity.sh (keep that prefix in
# lockstep with the purity gate). Arc-7 S5a extends the TOTALITY gate
# (only) over the five modules totalized by the F8 declares sweep
# (D6 gating item; declares in frontend/model/{utils,annot,ctype,core,
# state_exception_undefined}.lem): Utils, Annot, Ctype, Core,
# State_exception_undefined are now partial-free and may not regress —
# the slate theorems' app-equation computations (RelSem/T1.lean etc.)
# need their kernel equations.
EXEC_MODULES=(Core_run Core_reduction Core_eval Driver Core_run_aux
              Core_aux Defacto_memory Defacto_memory_aux Ctype_aux
              Nondeterminism Mem_aux
              Utils Annot Ctype Core State_exception_undefined)

declare -A allowed=()
if [[ -f "$ALLOW" ]]; then
  while IFS= read -r line; do
    entry="${line%%#*}"; entry="${entry//[[:space:]]/}"
    [[ -n "$entry" ]] && allowed["$entry"]=0
  done < "$ALLOW"
fi

findings=0

# scan_one <file> <module-key>: lexer-grade scan of one file, appending to
# the global findings/allowed bookkeeping under <module-key>.
scan_one() {
  local f="$1" m="$2"
  [[ -f "$f" ]] || { echo "check_exec_totality: MISSING $f"; findings=$((findings+1)); return; }
  # Lexer-grade scan (arc-3 audit F1-F5): strings, char literals, `--` line
  # comments, and nested /- -/ block comments are stripped BEFORE matching,
  # and the match is a word-level `partial` followed by `def`/`instance`
  # across any whitespace (catches split lines, `protected`, multi-attribute
  # prefixes). The scan MUST succeed — a scanner failure fails the gate
  # (fail-closed), it does not silently report CLEAN.
  local scan_out scan_rc
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
  local hit name key
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
}

for m in "${EXEC_MODULES[@]}"; do
  scan_one "$GEN/$m.lean" "$m"
done

# Arc-7 S2 (arc-4 G3 item, CerbND leg discharged): the HAND-WRITTEN runner
# joins the boundary — no `partial def` allowed in CerbND.lean anymore
# (header). Both the authoritative hand-written source and the build copy
# in generated/ are scanned: the sync gate keeps them byte-identical, and
# scanning both keeps THIS gate fail-closed against a stale copy.
HAND="$SCRIPT_DIR/../lean_frontend"
scan_one "$HAND/CerbND.lean" "CerbND"
scan_one "$GEN/CerbND.lean" "CerbND"

stale=0
for k in "${!allowed[@]}"; do
  if [[ "${allowed[$k]}" == 0 ]]; then
    echo "  STALE allowlist entry: $k (no matching partial def)"
    stale=$((stale+1))
  fi
done

if [[ $findings -eq 0 && $stale -eq 0 ]]; then
  echo "check_exec_totality: CLEAN (${#EXEC_MODULES[@]} generated modules + hand-written CerbND, ${#allowed[@]} allowlisted)"
  exit 0
fi
echo "check_exec_totality: $findings non-allowlisted partial(s), $stale stale allowlist entr(ies)"
if [[ "$ENFORCE" == "1" ]]; then
  echo "check_exec_totality: FAIL (enforcing mode)"
  exit 1
fi
echo "check_exec_totality: reporting mode (sweep in progress)"
exit 0
