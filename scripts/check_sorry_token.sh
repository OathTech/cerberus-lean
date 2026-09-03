#!/bin/bash
# check_sorry_token.sh — the `sorry`-token SOURCE census (FUEL arc rider,
# 2026-09-03; design lean_frontend/docs/2026-09-02_fuel-arc-design.md §5).
#
# WHY: the axiom gates check `sorryAx` only in PROBED cones
# (check_theorem_axioms.sh) — a `sorry` in an unprobed definition (the
# tree's last one lived in the concurrency model's debug-log string,
# generated Cmm_op.lean, from cmm_op.lem's `target_rep … = \`sorry\``)
# was invisible to every gate. This leg scans the SOURCE TEXT: every
# `sorry` token, comment- and string-stripped (the strip is the point —
# history comments naming sorry must not trip, a live token must), over
#   (1) lean_frontend/generated/*.lean      (lem output + hand-written copies)
#   (2) lean_frontend/*.lean + test/**      (hand-written seams + tests)
#   (3) the consumed LemLib package copy    (.lake/packages/LemLib/lean-lib/**)
# Expected count: 0. Fail-closed: a missing directory or an EMPTY file
# list for any of the three sets is a FAIL (vacuity is loud), a scanner
# failure is a FAIL, any token is a FAIL naming file:line.
#
# Plants (recorded in the arc record; re-runnable):
#   * planted token in a scratch copy of a generated file   -> red
#   * token inside a comment or a string literal            -> NOT counted
#   * empty scan set (a --root with no generated/ files)     -> red
#
# Usage: scripts/check_sorry_token.sh [--root DIR]   (DIR defaults to the repo)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    *) echo "check_sorry_token: unknown argument '$1'" >&2; exit 2 ;;
  esac
done
GEN_DIR="$ROOT/lean_frontend/generated"
HW_DIR="$ROOT/lean_frontend"
LEMLIB_LIB="$ROOT/lean_frontend/.lake/packages/LemLib/lean-lib"
for d in "$GEN_DIR" "$HW_DIR" "$LEMLIB_LIB"; do
  if [[ ! -d "$d" ]]; then
    echo "check_sorry_token: FAIL — scan directory $d missing (fail-closed)"
    exit 1
  fi
done
GEN_LIST=$(find "$GEN_DIR" -maxdepth 1 -name '*.lean' | LC_ALL=C sort)
HW_LIST=$( { find "$HW_DIR" -maxdepth 1 -name '*.lean'; find "$HW_DIR/test" -name '*.lean' 2>/dev/null; } | LC_ALL=C sort)
LEM_LIST=$(find "$LEMLIB_LIB" -name '*.lean' | LC_ALL=C sort)
for pair in "generated:$GEN_LIST" "hand-written:$HW_LIST" "LemLib:$LEM_LIST"; do
  if [[ -z "${pair#*:}" ]]; then
    echo "check_sorry_token: FAIL — ${pair%%:*} scan set is EMPTY (fail-closed; vacuous scan)"
    exit 1
  fi
done
LIST_FILE=$(mktemp)
printf '%s\n%s\n%s\n' "$GEN_LIST" "$HW_LIST" "$LEM_LIST" > "$LIST_FILE"
SCAN=$(python3 - "$LIST_FILE" <<'PYEOF'
import re, sys
# comment/string/char-literal stripper — the same discipline as the
# check_theorem_axioms.sh censuses (newlines preserved for line numbers)
def strip(src):
    cur = []; depth = 0; i = 0; n = len(src)
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
            j = src.find('\n', i); i = n if j == -1 else j; continue
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
            j = src.find('\'', i + 2 if src[i+1] != '\\' else i + 3)
            i = (j + 1) if j != -1 else n
            cur.append(' '); continue
        cur.append(c); i += 1
    return ''.join(cur)
files = [l for l in open(sys.argv[1]).read().splitlines() if l]
print(f"SCANNED {len(files)}")
for path in files:
    clean = strip(open(path, encoding='utf-8').read())
    for m in re.finditer(r"\bsorry\b", clean):
        print(f"SORRY {path}:{clean.count(chr(10), 0, m.start()) + 1}")
PYEOF
) || { echo "check_sorry_token: FAIL — scanner failed (fail-closed)"; rm -f "$LIST_FILE"; exit 1; }
rm -f "$LIST_FILE"
if ! grep -q '^SCANNED ' <<<"$SCAN"; then
  echo "check_sorry_token: FAIL — scanner produced no SCANNED marker (fail-closed)"
  exit 1
fi
NSCANNED=$(grep '^SCANNED ' <<<"$SCAN" | awk '{print $2}')
HITS=$(grep '^SORRY ' <<<"$SCAN" || true)
if [[ -n "$HITS" ]]; then
  echo "check_sorry_token: FAIL — \`sorry\` token(s) in non-comment, non-string position (expected 0; the tree's last one, cmm_op.lem's target_rep, was closed by the FUEL arc rider):"
  echo "$HITS"
  exit 1
fi
echo "check_sorry_token: OK ($NSCANNED files scanned comment-stripped — generated $(wc -l <<<"$GEN_LIST"), hand-written+test $(wc -l <<<"$HW_LIST"), LemLib $(wc -l <<<"$LEM_LIST"); 0 sorry tokens)"
