#!/bin/bash
# test_cn_spec_export.sh — golden-output lane for the CN spec-AST exporter
# (`cerberus --cn-spec-json`; backend/lean_export/cn_spec_json.ml; design:
# lean_frontend/docs/2026-08-24_cn0-spec-export.md).
#
# Tier C reporting lane (CN-0, 2026-08-24): NOT wired into test_unit.sh
# until the schema stabilizes; run it standalone. The script itself is
# fail-closed — any golden diff, schema violation, or fail-open symptom
# exits 1.
#
# What it checks:
#   1. GOLDEN DIFFS — the exporter's byte output over a representative
#      slice of the CN corpus (deps/cn/tests/cn, BSD-2, consumed
#      BY REFERENCE like test_cn_coverage.sh — no corpus text is copied
#      into this repo) must equal the committed goldens in
#      tests/cn_spec_export/golden/. The exporter runs with the corpus
#      dir as cwd and a bare filename so embedded source locations are
#      checkout-relative and the goldens are machine-independent.
#   2. SCHEMA VALIDITY — every golden re-parses as JSON with exactly the
#      v1 envelope (cn_spec_json_version=1; toplevel/functions/stray;
#      per-function name/name_loc/def_loc/spec/loops/statements/
#      ghost_calls).
#   3. FAIL-CLOSED PLANTS (run every pass, not just at audit time):
#      a malformed CN annotation (tests/cn_spec_export/malformed.c) and
#      a split spec (tests/cn_spec_export/split.c) must BOTH exit
#      nonzero with a located error on stderr and an EMPTY stdout —
#      silent omission in either lane is the defect this lane exists to
#      catch.
#
# Updating goldens is a deliberate, reviewed act: --write-golden.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

# --- corpus discovery (test_cn_coverage.sh house pattern) -------------------
CORPUS=""
if [[ -n "${CN_CORPUS_DIR:-}" ]]; then
    CORPUS="$CN_CORPUS_DIR"
else
    d="$PROJECT_ROOT"
    while [[ "$d" != "/" ]]; do
        if [[ -d "$d/deps/cn/tests/cn" ]]; then
            CORPUS="$d/deps/cn/tests/cn"
            break
        fi
        d=$(dirname "$d")
    done
fi
if [[ -z "$CORPUS" || ! -d "$CORPUS" ]]; then
    echo "Error: CN corpus not found (deps/cn/tests/cn above $PROJECT_ROOT; set CN_CORPUS_DIR)" >&2
    exit 1
fi
CORPUS=$(cd "$CORPUS" && pwd)

GOLDEN_DIR="$PROJECT_ROOT/tests/cn_spec_export/golden"
FIXTURE_DIR="$PROJECT_ROOT/tests/cn_spec_export"

# The representative slice (CN-0 design §4): the arc-15 spec-lab
# comparison functions + datatype/predicate/lemma/ghost-rich picks.
SLICE=(
    division.c                        # requires/ensures, pure constraint
    mod.c                             # same shape, mod
    memcpy.c                          # each/RW arrays, loop invariant, focus/instantiate
    swap_pair.c                       # each/RW, statement-level ghosts, trusted main
    append.c                          # datatype + [rec] function + [rec] predicate + unfold
    reverse.c                         # accesses, lemmas, apply
    mergesort.c                       # multi-function, rich toplevel
    fun_ptr_extern.c                  # prototype spec (cn_decl_spec) + predicate
    ghost_args_and_nested_function.c  # call-site ghost arguments
    tree_rev01.c                      # tree predicate
)

WRITE_GOLDEN=0
[[ "${1:-}" == "--write-golden" ]] && WRITE_GOLDEN=1

command -v python3 >/dev/null || { echo "Error: python3 required for the schema check" >&2; exit 1; }
if [[ ! -f "$CERBERUS_BIN" ]]; then
    echo "Error: oracle binary missing ($CERBERUS_BIN) — build it first" >&2
    echo "  (opam exec --switch=. -- dune build backend/driver/main.exe)" >&2
    exit 1
fi

OUT_DIR="$TMP_DIR/cn_spec_export.$$"
mkdir -p "$OUT_DIR"
register_cleanup "$OUT_DIR"

export_one() {  # <dir> <file> <stdout-path> <stderr-path>; returns exporter rc
    local dir="$1" file="$2" out="$3" err="$4"
    (cd "$dir" && opam exec --switch="$PROJECT_ROOT" -- \
        "$CERBERUS_BIN" --nolibc --cn-spec-json "$file") >"$out" 2>"$err"
}

fails=0

# --- 1+2: goldens + schema over the slice -----------------------------------
for f in "${SLICE[@]}"; do
    if [[ ! -f "$CORPUS/$f" ]]; then
        echo "FAIL [$f] corpus file missing from $CORPUS (corpus drift)" ; fails=$((fails+1)); continue
    fi
    out="$OUT_DIR/$f.json"; err="$OUT_DIR/$f.err"
    if ! export_one "$CORPUS" "$f" "$out" "$err"; then
        echo "FAIL [$f] exporter exited nonzero:"
        sed 's/^/    /' "$err" | head -8
        fails=$((fails+1)); continue
    fi
    if ! python3 - "$out" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
assert set(d) == {"cn_spec_json_version", "file", "toplevel", "functions", "stray"}, f"envelope keys: {sorted(d)}"
assert d["cn_spec_json_version"] == 1, d["cn_spec_json_version"]
assert set(d["stray"]) == {"loops", "statements", "ghost_calls"}
for fn in d["functions"]:
    assert set(fn) == {"name", "name_loc", "def_loc", "spec", "loops", "statements", "ghost_calls"}, \
        f"function keys: {sorted(fn)}"
PYEOF
    then
        echo "FAIL [$f] schema check failed"; fails=$((fails+1)); continue
    fi
    if [[ $WRITE_GOLDEN -eq 1 ]]; then
        mkdir -p "$GOLDEN_DIR"
        cp "$out" "$GOLDEN_DIR/$f.json"
        echo "WROTE [$f] golden"
    elif [[ ! -f "$GOLDEN_DIR/$f.json" ]]; then
        echo "FAIL [$f] golden missing: tests/cn_spec_export/golden/$f.json (run --write-golden and review)"
        fails=$((fails+1))
    elif ! diff -q "$GOLDEN_DIR/$f.json" "$out" >/dev/null; then
        echo "FAIL [$f] output differs from golden:"
        diff "$GOLDEN_DIR/$f.json" "$out" | head -12 | sed 's/^/    /'
        fails=$((fails+1))
    else
        echo "PASS [$f]"
    fi
done

# --- 3: the fail-closed plants ----------------------------------------------
plant() {  # <fixture-basename> <required-stderr-regex>
    local f="$1" regex="$2"
    local out="$OUT_DIR/$f.json" err="$OUT_DIR/$f.err"
    if export_one "$FIXTURE_DIR" "$f" "$out" "$err"; then
        echo "FAIL [plant:$f] exporter exited 0 on a broken annotation (FAIL-OPEN)"
        fails=$((fails+1)); return
    fi
    if [[ -s "$out" ]]; then
        echo "FAIL [plant:$f] nonzero exit but stdout nonempty (partial output)"
        fails=$((fails+1)); return
    fi
    if ! grep -qE "$regex" "$err"; then
        echo "FAIL [plant:$f] stderr does not match /$regex/:"
        sed 's/^/    /' "$err" | head -6
        fails=$((fails+1)); return
    fi
    echo "PASS [plant:$f] (loud error, empty stdout)"
}
plant malformed.c 'error:'
plant split.c 'split magic comments'

# --- summary -----------------------------------------------------------------
n_golden=${#SLICE[@]}
if [[ $fails -eq 0 ]]; then
    echo "test_cn_spec_export: PASS ($n_golden goldens + schema + 2 plants)"
else
    echo "test_cn_spec_export: FAIL ($fails failures)"
    exit 1
fi
