#!/bin/bash
# test_verify.sh — the fixture-differential net (tests/verify/ +
# lean_frontend/corpus via tests/corpus pins).
#
# Fail-closed checks per fixture:
#
#   1. PIN PROVENANCE — the pinned Core dump (tests/verify/*.core,
#      tests/corpus/*.core[.sha256]) must be re-derivable from the .c
#      source via the oracle, byte-identically (or by content hash for
#      the large dumps).
#
#   2. MAIN-MODE DIFFERENTIAL — OCaml oracle (--nolibc --exec --batch
#      --mode=exhaustive) vs the Lean pipeline (--batch <cabs-json>) on
#      the fixture's concrete main(), full verdict-line comparison
#      (these are single-verdict programs; any difference is a FAIL).
#
#   3. CALL-POINT DIFFERENTIAL — the Lean driver's --call mode
#      (cerberus-lean --call <f> --call-args <ints>, RelSem.Cerb.callND)
#      at the concrete points of the expectations files, compared
#      against the ORACLE run at the same point: the oracle has no
#      --call mode, so the script renders a wrapper TU (the fixture
#      with `main` preprocessor-renamed + a fresh `main` returning
#      `f(args)`) and runs it main-mode. Both verdicts (Specified
#      value / UB code) must equal each other AND the recorded
#      expectation pin (drift detection on the recorded rows).
#      (Re-based 2026-08-31, semantics-first split: these rows
#      formerly compared against theorem-spec values; they are now
#      pure oracle-differential rows with the pins as recorded
#      provenance.)
#
# Usage: ./scripts/test_verify.sh [-v]

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
set -uo pipefail

VERBOSE=false
[[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]] && VERBOSE=true

VERIFY_DIR="$PROJECT_ROOT/tests/verify"
EXPECT_FILE="$VERIFY_DIR/expectations.txt"
WORK_DIR="$TMP_DIR/verify.$$"
mkdir -p "$WORK_DIR"
register_cleanup "$WORK_DIR"

[[ -d "$VERIFY_DIR" ]] || { echo "Error: $VERIFY_DIR not found" >&2; exit 1; }
[[ -f "$EXPECT_FILE" ]] || { echo "Error: $EXPECT_FILE not found" >&2; exit 1; }

build_cerberus
build_lean

PASS=0
FAIL=0

# Render the oracle wrapper TU for a call point: the fixture with
# `main` preprocessor-renamed out of the way + a fresh main returning
# f(args). Emits the wrapper path on stdout.
render_wrapper() {  # <fixture.c> <fname> <args-csv|->  -> wrapper path
    local cfile="$1" fname="$2" argscsv="$3"
    local wpath="$WORK_DIR/wrap_${fname}_$(echo "$argscsv" | tr ',-' '_m').c"
    local callargs=""
    [[ "$argscsv" != "-" ]] && callargs="$argscsv"
    printf '#define main cerb_fixture_main_\n#include "%s"\n#undef main\nint main(void) { return %s(%s); }\n' \
        "$cfile" "$fname" "$callargs" > "$wpath"
    echo "$wpath"
}

# Extract the verdict token (Specified(N)/Unspecified value, or the
# UB code) from a batch verdict line.
verdict_of() {  # <line>
    case "$1" in
        Defined*)   sed -n 's/^Defined {value: "\([^"]*\)".*/\1/p' <<<"$1" ;;
        Undefined*) sed -n 's/^Undefined {ub: "\([^"]*\)".*/\1/p' <<<"$1" ;;
        *)          echo "<no verdict: $1>" ;;
    esac
}

fail() { echo -e "${RED}FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
pass() { PASS=$((PASS + 1)); $VERBOSE && echo -e "${GREEN}ok${NC}   $1"; }

# ---------------------------------------------------------------------------
# Pin-provenance check (arc-7 S5c, audit-1 F6): the pinned Core dumps the
# theorems' program terms are transcribed from (tests/verify/*.core) must
# be re-derivable from the .c fixtures via the oracle, byte-identically.
# Fail-closed: a drifted pin means the theorem objects describe a program
# the oracle no longer produces.
# ---------------------------------------------------------------------------
for cfile in "$VERIFY_DIR"/*.c; do
    [[ -f "$cfile" ]] || continue
    stem=$(basename "$cfile" .c)
    pin="$VERIFY_DIR/$stem.core"
    if [[ ! -f "$pin" ]]; then
        fail "$stem: pinned Core dump missing ($pin)"
        continue
    fi
    fresh="$WORK_DIR/$stem.fresh.core"
    if ! run_cerberus --nolibc --pp=core "$cfile" > "$fresh" 2>"$WORK_DIR/$stem.pp.err"; then
        fail "$stem: oracle --pp=core derivation failed"
        continue
    fi
    if cmp -s "$fresh" "$pin"; then
        pass "$stem: pin provenance (oracle --pp=core byte-identical)"
    else
        fail "$stem: pin provenance — tests/verify/$stem.core differs from a fresh oracle derivation"
        diff "$pin" "$fresh" | head -10
    fi
done

# ---------------------------------------------------------------------------
# Per-fixture: cabs-json + main-mode differential
# ---------------------------------------------------------------------------
declare -A JSON_OF
fixture_count=0
for cfile in "$VERIFY_DIR"/*.c; do
    [[ -f "$cfile" ]] || continue
    stem=$(basename "$cfile" .c)
    fixture_count=$((fixture_count + 1))
    json="$WORK_DIR/$stem.json"

    if ! run_cerberus --cabs-json "$cfile" > "$json" 2>"$WORK_DIR/$stem.cabs.err"; then
        fail "$stem: cabs-json generation failed"
        continue
    fi
    JSON_OF[$stem]="$json"

    oracle_out=$(timeout 30 bash -c '
        source "'"$SCRIPT_DIR"'/common.sh"
        run_cerberus --nolibc --exec --batch --mode=exhaustive "'"$cfile"'" 2>/dev/null' \
        | grep -E '^(Defined|Undefined|Error|EXECUTION)' || true)
    lean_out=$(timeout 30 env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "$json" 2>/dev/null \
        | grep -E '^(Defined|Undefined|Error|EXECUTION)' || true)

    if [[ -z "$oracle_out" ]]; then
        fail "$stem: oracle produced no verdict"
    elif [[ "$oracle_out" == "$lean_out" ]]; then
        pass "$stem: main-mode differential ($oracle_out)"
    else
        fail "$stem: main-mode differential mismatch"
        echo "    oracle: $oracle_out"
        echo "    lean:   $lean_out"
    fi
done

if [[ $fixture_count -eq 0 ]]; then
    echo "Error: no fixtures found in $VERIFY_DIR (vacuous pass is a failure)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Call-point differentials (expectations.txt): Lean --call vs the
# oracle on a rendered wrapper TU vs the recorded pin — all three must
# agree (fail-closed; a wrapper the oracle cannot run is a FAIL).
# ---------------------------------------------------------------------------
row_count=0
while read -r stem fname argscsv expected; do
    [[ -z "$stem" || "$stem" == \#* ]] && continue
    row_count=$((row_count + 1))
    json="${JSON_OF[$stem]:-}"
    if [[ -z "$json" ]]; then
        fail "$stem $fname($argscsv): no cabs-json (fixture missing/failed)"
        continue
    fi
    if [[ "$argscsv" == "-" ]]; then
        out=$(timeout 30 env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" \
            --batch --call "$fname" "$json" 2>&1 | head -1)
    else
        out=$(timeout 30 env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" \
            --batch --call "$fname" --call-args "$argscsv" "$json" 2>&1 | head -1)
    fi
    lean_got=$(verdict_of "$out")
    wrapper=$(render_wrapper "$VERIFY_DIR/$stem.c" "$fname" "$argscsv")
    oracle_line=$(timeout 30 bash -c '
        source "'"$SCRIPT_DIR"'/common.sh"
        run_cerberus --nolibc --exec --batch --mode=exhaustive "'"$wrapper"'" 2>/dev/null' \
        | grep -E '^(Defined|Undefined|Error)' | head -1 || true)
    oracle_got=$(verdict_of "$oracle_line")
    if [[ "$lean_got" == "$oracle_got" && "$lean_got" == "$expected" ]]; then
        pass "$stem: $fname($argscsv) = $expected (oracle-differential)"
    else
        fail "$stem: $fname($argscsv) — pin $expected, lean $lean_got, oracle $oracle_got"
    fi
done < "$EXPECT_FILE"

if [[ $row_count -eq 0 ]]; then
    echo "Error: no expectation rows (vacuous pass is a failure)" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# THE CORPUS FIXTURE LANE (lean_frontend/corpus — the pinned
# differential-fixture set, hash-gated by check_fixture_freeze.sh);
# dumps pinned under tests/corpus:
#   * the small programs: in-tree pins, byte-identical re-derivation;
#   * the arena programs (p04/p05/p06/p07/p08/p15 — 16–94 MB dumps):
#     CONTENT-HASH pins (the libc.core B-F5 pattern), re-derived and
#     sha256-compared here (their main-mode Lean-exec rows are
#     unpriced — the MB-arena exec cost — and not run);
#   * the small programs: main-mode differential + call-point
#     differential rows (tests/corpus/expectations.txt).
# ---------------------------------------------------------------------------
CORPUS_SRC_DIR="$PROJECT_ROOT/lean_frontend/corpus"
CORPUS_PIN_DIR="$PROJECT_ROOT/tests/corpus"
CORPUS_EXPECT="$CORPUS_PIN_DIR/expectations.txt"
CORPUS_SMALL="p01_clamp p02_sat_add p03_swap_mayalias p09_call_contract p10_gcd_rec p11_gcd_iter p12_pt_midpoint p14_count_pairs"
CORPUS_HASHED="p04_arr_sum p05_find_first p06_arr_reverse p07_list_sum p08_list_reverse p15_scan_classify"

corpus_fixture_count=0
for stem in $CORPUS_SMALL; do
    cfile="$CORPUS_SRC_DIR/$stem.c"
    pin="$CORPUS_PIN_DIR/$stem.core"
    corpus_fixture_count=$((corpus_fixture_count + 1))
    if [[ ! -f "$pin" ]]; then
        fail "corpus/$stem: pinned Core dump missing ($pin)"
        continue
    fi
    fresh="$WORK_DIR/$stem.fresh.core"
    if ! run_cerberus --nolibc --pp=core "$cfile" > "$fresh" 2>"$WORK_DIR/$stem.pp.err"; then
        fail "corpus/$stem: oracle --pp=core derivation failed"
        continue
    fi
    if cmp -s "$fresh" "$pin"; then
        pass "corpus/$stem: pin provenance (byte-identical)"
    else
        fail "corpus/$stem: pin provenance — tests/corpus/$stem.core differs from a fresh oracle derivation"
    fi
    funspin="$CORPUS_PIN_DIR/${stem}_funs.core"
    if [[ -f "$funspin" ]]; then
        sed -n '/^-- Aggregates/,/^-- Globals/p;/^-- Fun map/,$p' "$fresh" \
            | grep -v '^-- Globals' > "$WORK_DIR/$stem.funs.fresh"
        if cmp -s "$WORK_DIR/$stem.funs.fresh" "$funspin"; then
            pass "corpus/$stem: funs-extraction provenance (byte-identical)"
        else
            fail "corpus/$stem: funs-extraction provenance — tests/corpus/${stem}_funs.core differs from the fresh extraction"
        fi
    fi
done
for stem in $CORPUS_HASHED; do
    cfile="$CORPUS_SRC_DIR/$stem.c"
    pin="$CORPUS_PIN_DIR/$stem.core.sha256"
    corpus_fixture_count=$((corpus_fixture_count + 1))
    if [[ ! -f "$pin" ]]; then
        fail "corpus/$stem: content-hash pin missing ($pin)"
        continue
    fi
    fresh="$WORK_DIR/$stem.fresh.core"
    if ! run_cerberus --nolibc --pp=core "$cfile" > "$fresh" 2>"$WORK_DIR/$stem.pp.err"; then
        fail "corpus/$stem: oracle --pp=core derivation failed"
        continue
    fi
    got=$(sha256sum "$fresh" | cut -d" " -f1)
    want=$(cat "$pin")
    if [[ "$got" == "$want" ]]; then
        pass "corpus/$stem: content-hash provenance (sha256 match)"
    else
        fail "corpus/$stem: content-hash provenance — fresh derivation sha256 $got != pinned $want"
    fi
    # batch-B funs-extraction provenance: the pinned *_funs.core
    # (aggregates + fun-map sections — the emitted code's input) must
    # equal the extraction from the fresh derivation, byte-identically.
    funspin="$CORPUS_PIN_DIR/${stem}_funs.core"
    if [[ -f "$funspin" ]]; then
        sed -n '/^-- Aggregates/,/^-- Globals/p;/^-- Fun map/,$p' "$fresh" \
            | grep -v '^-- Globals' > "$WORK_DIR/$stem.funs.fresh"
        if cmp -s "$WORK_DIR/$stem.funs.fresh" "$funspin"; then
            pass "corpus/$stem: funs-extraction provenance (byte-identical)"
        else
            fail "corpus/$stem: funs-extraction provenance — tests/corpus/${stem}_funs.core differs from the fresh extraction"
        fi
    else
        fail "corpus/$stem: funs pin missing ($funspin)"
    fi
    rm -f "$fresh"
done

# batch-A main-mode differential + harness rows
declare -A CORPUS_JSON_OF
for stem in p01_clamp p02_sat_add p03_swap_mayalias p09_call_contract p10_gcd_rec p11_gcd_iter p12_pt_midpoint; do
    cfile="$CORPUS_SRC_DIR/$stem.c"
    json="$WORK_DIR/$stem.json"
    if ! run_cerberus --cabs-json "$cfile" > "$json" 2>"$WORK_DIR/$stem.cabs.err"; then
        fail "corpus/$stem: cabs-json generation failed"
        continue
    fi
    CORPUS_JSON_OF[$stem]="$json"
    oracle_out=$(timeout 30 bash -c "
        source \"$SCRIPT_DIR/common.sh\"
        run_cerberus --nolibc --exec --batch --mode=exhaustive \"$cfile\" 2>/dev/null" \
        | grep -E "^(Defined|Undefined|Error|EXECUTION)" || true)
    lean_out=$(timeout 30 env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" --batch "$json" 2>/dev/null \
        | grep -E "^(Defined|Undefined|Error|EXECUTION)" || true)
    if [[ -z "$oracle_out" ]]; then
        fail "corpus/$stem: oracle produced no verdict"
    elif [[ "$oracle_out" == "$lean_out" ]]; then
        pass "corpus/$stem: main-mode differential ($oracle_out)"
    else
        fail "corpus/$stem: main-mode differential mismatch"
        echo "    oracle: $oracle_out"
        echo "    lean:   $lean_out"
    fi
done

corpus_row_count=0
if [[ -f "$CORPUS_EXPECT" ]]; then
    while read -r stem fname argscsv expected; do
        [[ -z "$stem" || "$stem" == \#* ]] && continue
        corpus_row_count=$((corpus_row_count + 1))
        json="${CORPUS_JSON_OF[$stem]:-}"
        if [[ -z "$json" ]]; then
            fail "corpus/$stem $fname($argscsv): no cabs-json"
            continue
        fi
        out=$(timeout 30 env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN" \
            --batch --call "$fname" --call-args "$argscsv" "$json" 2>&1 | head -1)
        lean_got=$(verdict_of "$out")
        wrapper=$(render_wrapper "$CORPUS_SRC_DIR/$stem.c" "$fname" "$argscsv")
        oracle_line=$(timeout 30 bash -c '
            source "'"$SCRIPT_DIR"'/common.sh"
            run_cerberus --nolibc --exec --batch --mode=exhaustive "'"$wrapper"'" 2>/dev/null' \
            | grep -E '^(Defined|Undefined|Error)' | head -1 || true)
        oracle_got=$(verdict_of "$oracle_line")
        if [[ "$lean_got" == "$oracle_got" && "$lean_got" == "$expected" ]]; then
            pass "corpus/$stem: $fname($argscsv) = $expected (oracle-differential)"
        else
            fail "corpus/$stem: $fname($argscsv) — pin $expected, lean $lean_got, oracle $oracle_got"
        fi
    done < "$CORPUS_EXPECT"
fi
if [[ $corpus_row_count -eq 0 ]]; then
    echo "Error: no corpus expectation rows (vacuous pass is a failure)" >&2
    exit 1
fi

echo ""
echo "test_verify: $PASS passed, $FAIL failed ($fixture_count fixtures, $row_count call points, $corpus_fixture_count corpus fixtures, $corpus_row_count corpus points)"
[[ $FAIL -eq 0 ]] || exit 1
exit 0
