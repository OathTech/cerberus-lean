#!/bin/bash
# test_pnvi.sh — the PNVI-ae-udi differential lane (PNVI arc S4, 2026-10-07).
#
# Design record lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §D.1/§D.2/§D.5;
# slice record lean_frontend/docs/2026-10-07_pnvi-s4-lane-record.md.
#
# TRUST SURFACE. This lane is the validation evidence for `--switches=PNVI_ae_udi`
# ([USER 2026-10-07]: "we don't want our gates to be adversarially robust unless they are
# trust surfaces" — this one is): BOTH engines run with `--switches=PNVI_ae_udi`, the
# complete observations are compared through the shared codec (scripts/observations.py,
# `full` projection: value, stdout, stderr, UB kind AND location), every row is classified
# by scripts/pnvi_lane.py and checked against the committed baseline
# tests/pnvi_lane/baseline.txt, fail-closed both directions.
#
# Sections (row-name prefix):
#   litmus/   upstream's PNVI litmus suite tests/pnvi_testsuite/*.c (44), libc mode,
#             EXHAUSTIVE on both sides (oracle --mode=exhaustive, Lean without --first;
#             the default-elaborated libc on both sides: the oracle's libc.co, Lean's pinned
#             tests/libc/libc.core dump + 12 metadata TUs — design §B.0's mixing, mirrored)
#   witness/  tests/pnvi_refusals/*.c: small programs that REACH a refusal (the CONTRACT
#             §4.1 witness for each refusal reachable from C that the litmus suite misses),
#             libc mode, exhaustive
#   pkvm/     the census pKVM buddy-allocator drivers (tests/census/pkvm/, the case study
#             at deps/CN-pKVM-buddy-allocator-case-study, census flags, --nolibc):
#             pkvm-alloc / pkvm-free / pkvm-split-merge in FIRST mode (oracle default
#             --mode=random one trace vs Lean --first) — OUTSIDE CONTRACT §1 (design §F.8):
#             their exhaustive sets breach the 4G per-test cap on the oracle (MEASURED, the
#             S4 record); pkvm-init EXHAUSTIVE on both (its UB088 location is
#             trace-dependent, design §C.3/§C.6: the 2-execution set is pinned).
#             page_alloc_census.c (GPL-2.0-only text) is DERIVED at run time into the run
#             directory by tests/census/pkvm/derive_pool_init.py; never committed.
#   minimal/  tests/minimal/*.c (the default exec corpus, Tier A row 2) under the switch,
#             --nolibc exhaustive: ordinary programs are undisturbed.
# Every row also runs the ORACLE WITHOUT the switch; the baseline records whether the
# switch changed the oracle's answer (`default=same|changed`) — the derived "undisturbed"
# tally of the SUMMARY line.
#
# Row classes, the baseline and its hashes: scripts/pnvi_lane.py's docstring. A refusal row
# (Lean refuses with a named R-PNVI-nn where the oracle crashes with THAT upstream failure,
# or runs through an arm upstream flags) is a registered row, never agreement. Fail-closed:
# a missing engine, an empty selection, an unclassified, DIFF or INVALID row is RED.
#
# Usage:
#   scripts/test_pnvi.sh                       the full lane (Tier A row 14, LADDER.md)
#   scripts/test_pnvi.sh --rows REGEX          a SUBSET (checked against the matching
#                                              baseline rows only; never a certification)
#   scripts/test_pnvi.sh --record-baseline     re-record (refused over RED rows; a
#                                              dedicated instrument commit)
#   scripts/test_pnvi.sh --selftest            the plants (below), on a small selection
#   --keep-run DIR                             keep the run's manifest + captures in DIR
#   --baseline FILE                            check against FILE (selftest plants)
#
# Per-engine invocation: scripts/capped at CERB_TEST_MEM_MAX (common.sh CAPPED_TEST,
# default 4G) + `timeout` (TIMEOUT_SECS, default 300 for litmus/witness/pkvm — the
# libc_exec lane's bound — and MINIMAL_TIMEOUT_SECS, default 30 — test_exec.sh's — for
# minimal/), stdin </dev/null, NO_COLOR/TERM pinned by common.sh, Lean with
# LEAN_ABORT_ON_PANIC=1.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/test_pnvi.sh"

MODE=run; ROWS_RE=""; KEEP=""; BASELINE_OVERRIDE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --record-baseline) MODE=record; shift ;;
        --selftest) MODE=selftest; shift ;;
        --rows) ROWS_RE="${2:?--rows needs a regex}"; shift 2 ;;
        --keep-run) KEEP="${2:?--keep-run needs a directory}"; shift 2 ;;
        --baseline) BASELINE_OVERRIDE="${2:?--baseline needs a file}"; shift 2 ;;
        *) echo "test_pnvi: unknown argument $1" >&2; exit 2 ;;
    esac
done

source "$HERE/common.sh"
TIMEOUT_SECS="${TIMEOUT_SECS:-300}"
MINIMAL_TIMEOUT_SECS="${MINIMAL_TIMEOUT_SECS:-30}"
BASELINE="${BASELINE_OVERRIDE:-$PROJECT_ROOT/tests/pnvi_lane/baseline.txt}"
RT="$PROJECT_ROOT/_build/install/default"
SW=--switches=PNVI_ae_udi
die() { echo "test_pnvi: FAIL — $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# --selftest: plants. Each runs THIS lane on a small discriminating selection and must
# be RED for the stated reason; the unplanted control on the same selection must be
# GREEN. Engine plants use common.sh's loud override hooks (CERB_LEAN_BIN_OVERRIDE /
# CERB_ORACLE_BIN_OVERRIDE) with stubs written into scratch; baseline plants re-check the
# control run's captures against doctored baselines (no engine re-run).
# ---------------------------------------------------------------------------
if [[ "$MODE" == selftest ]]; then
    REAL_LEAN="$CERBERUS_LEAN_BIN"; REAL_ORACLE="$CERBERUS_BIN"
    [[ -x "$REAL_LEAN" && -x "$REAL_ORACLE" ]] || die "engines not built ($REAL_LEAN / $REAL_ORACLE)"
    ST=$(mktemp -d "$TMP_DIR/pnvi-selftest.XXXXXXXX") || die "mktemp failed"
    register_cleanup "$ST"
    # the selection: a UB043 -> Defined row (ptrfromint's PNVI arm + exposure), a UB046 row
    # (the live bounds arm of eff_array_shift), an R-PNVI-01 refusal row (oracle crash), the
    # R-PNVI-05 witness (oracle verdict), and pkvm-init (the switch-dependent elaboration:
    # its exhaustive UB088 locations)
    SEL='^(litmus/(pointer_from_int_disambiguation_1|cheri_03_ii|provenance_basic_using_uintptr_t_global_yx)|witness/r05-abst-double-alloc-union-punning|pkvm/pkvm-init)$'
    stub() { # <file> <python body using REAL, args>
        printf "#!/usr/bin/env python3\nimport os, re, subprocess, sys\nREAL = '%s'\nargs = sys.argv[1:]\n%s\n" "$2" "$3" > "$1"
        chmod +x "$1"
    }
    # P1: the flag is ignored — a Lean build that treats ae_udi as the default (the
    # `--switches` argument stripped before the real driver runs; design §D.2 P1)
    stub "$ST/lean-strip" "$REAL_LEAN" 'os.execv(REAL, [REAL] + [a for a in args if not a.startswith("--switches")])'
    # P6: a driver that refuses everything (the refuse-all control; §D.2 P6)
    stub "$ST/lean-refuse" "$REAL_LEAN" 'sys.stderr.write("cerberus-lean: refused — plant: every input refused\n"); sys.exit(2)'
    # P7a: a refusal turned into an unnamed crash (the R-PNVI id and prefix removed)
    stub "$ST/lean-unnamed" "$REAL_LEAN" 'p = subprocess.run([REAL] + args, capture_output=True)
sys.stdout.buffer.write(p.stdout)
sys.stderr.buffer.write(re.sub(rb"PNVI_ae_udi refusal \(unsupported upstream arm\): R-PNVI-[0-9]+b?: ", b"", p.stderr))
sys.exit(134 if p.returncode == -6 else p.returncode)'
    # P7b: a refusal turned into a MIRROR of the oracle's crash text ("both crash alike")
    stub "$ST/lean-mirror" "$REAL_LEAN" 'p = subprocess.run([REAL] + args, capture_output=True)
sys.stdout.buffer.write(p.stdout)
sys.stderr.buffer.write(re.sub(rb"PNVI_ae_udi refusal \(unsupported upstream arm\): R-PNVI-01: [^\n]*", b"Concrete.combine_prov: found a Prov_symbolic", p.stderr))
sys.exit(134 if p.returncode == -6 else p.returncode)'
    # PO: the ORACLE ignores the flag (its answer moves away from the pinned hashes)
    stub "$ST/oracle-strip" "$REAL_ORACLE" 'os.execv(REAL, [REAL] + [a for a in args if not a.startswith("--switches")])'
    fails=0
    expect() { # <label> <want: green|red> <grep-pattern for the reason or ""> <env/cmd...>
        local label="$1" want="$2" pat="$3"; shift 3
        local out rc
        out=$(env "$@" 2>&1); rc=$?
        if [[ "$want" == green ]]; then
            if [[ $rc -eq 0 && "$out" == *"BASELINE OK"* ]]; then echo "  CONTROL OK [$label] -> $(grep -m1 '^SUMMARY' <<<"$out")"
            else echo "  CONTROL FAILED [$label] rc=$rc"; tail -15 <<<"$out"; fails=$((fails+1)); fi
        else
            if [[ $rc -ne 0 ]] && grep -qE "$pat" <<<"$out"; then echo "  PLANT OK   [$label] -> RED: $(grep -m1 -E "$pat" <<<"$out" | cut -c1-190)"
            else echo "  PLANT FAILED [$label] rc=$rc (wanted RED matching /$pat/)"; tail -15 <<<"$out"; fails=$((fails+1)); fi
        fi
    }
    echo "test_pnvi: SELFTEST — selection $SEL"
    expect "control: unplanted selection" green "" "$SELF" --rows "$SEL" --keep-run "$ST/control"
    expect "P1 Lean ignores the switch (flag stripped)" red 'litmus/pointer_from_int_disambiguation_1: class DIFF' \
        CERB_LEAN_BIN_OVERRIDE="$ST/lean-strip" "$SELF" --rows "$SEL"
    expect "P6 Lean refuses everything" red 'lean refused at the CLI' \
        CERB_LEAN_BIN_OVERRIDE="$ST/lean-refuse" "$SELF" --rows "$SEL"
    expect "P7a refusal turned into an unnamed crash" red 'provenance_basic_using_uintptr_t_global_yx: class BOTH_FAIL != baseline REFUSAL R-PNVI-01 ORACLE_CRASH' \
        CERB_LEAN_BIN_OVERRIDE="$ST/lean-unnamed" "$SELF" --rows "$SEL"
    expect "P7b refusal mirrored as the oracle's crash (both crash alike)" red 'provenance_basic_using_uintptr_t_global_yx: class BOTH_FAIL != baseline REFUSAL R-PNVI-01 ORACLE_CRASH' \
        CERB_LEAN_BIN_OVERRIDE="$ST/lean-mirror" "$SELF" --rows "$SEL"
    expect "PO the oracle ignores the switch" red "oracle-side hash .* != baseline" \
        CERB_ORACLE_BIN_OVERRIDE="$ST/oracle-strip" "$SELF" --rows "$SEL"
    expect "missing Lean engine" red 'FAIL — (engines not built|Lean driver missing)' \
        CERB_LEAN_BIN_OVERRIDE="$ST/nonexistent" "$SELF" --rows "$SEL"
    expect "empty selection" red 'empty selection|matches no' "$SELF" --rows '^no-such-row$'
    # baseline plants on the control run's captures (pnvi_lane.py only)
    M="$ST/control/manifest.tsv"
    if [[ -s "$M" ]]; then
        bplant() { # <label> <pattern> <sed transform of the baseline> [selection]
            local label="$1" pat="$2" tr="$3" sel="${4:-$SEL}" f="$ST/baseline.$RANDOM"
            sed -E "$tr" "$BASELINE" > "$f"
            expect "$label" red "$pat" python3 "$HERE/pnvi_lane.py" --manifest "$M" --baseline "$f" --select "$sel"
        }
        bplant "B1 a selected row deleted from the baseline" 'not in the baseline' '/^litmus\/cheri_03_ii /d'
        bplant "B2 a phantom selected row" 'baseline row not run' '$a litmus/cheri_03_iii AGREE oracle=000000000000 default=changed' "$SEL|^litmus/cheri_03_iii\$"
        bplant "B3 a refusal row relabelled as agreement" 'class REFUSAL R-PNVI-01 ORACLE_CRASH != baseline AGREE' \
            's/^(litmus\/provenance_basic_using_uintptr_t_global_yx) REFUSAL R-PNVI-01 ORACLE_CRASH/\1 AGREE/'
        bplant "B4 an oracle hash changed" 'oracle-side hash' 's/^(litmus\/cheri_03_ii [A-Z-]+ oracle=)[0-9a-f]{12}/\1000000000000/'
        bplant "B5 the default-mode comparison flipped" 'default-mode comparison' 's/^(litmus\/cheri_03_ii .*) default=changed$/\1 default=same/'
        bplant "B6 a malformed row class" 'unknown row class' 's/^(litmus\/cheri_03_ii) AGREE /\1 MATCHISH /'
    else
        echo "  PLANT FAILED [baseline plants] the control run left no manifest at $M"; fails=$((fails+1))
    fi
    [[ $fails -eq 0 ]] || { echo "test_pnvi: SELFTEST FAILED ($fails)"; exit 1; }
    echo "test_pnvi: SELFTEST OK (control green; 7 engine plants RED — P1 flag ignored, P6 refuse-everything, P7a unnamed crash, P7b mirrored crash, PO oracle ignores the switch, missing engine, empty selection; 6 baseline plants RED — deleted, phantom, relabelled refusal, oracle hash, default flag, malformed class)"
    exit 0
fi

# ---------------------------------------------------------------------------
# The lane
# ---------------------------------------------------------------------------
[[ -x "$CERBERUS_BIN" ]] || die "oracle driver missing: $CERBERUS_BIN"
[[ -x "$CERBERUS_LEAN_BIN" ]] || die "Lean driver missing: $CERBERUS_LEAN_BIN"
if [[ -z "${CERB_LEAN_BIN_OVERRIDE:-}" && -z "${CERB_ORACLE_BIN_OVERRIDE:-}" ]]; then
    build_cerberus
    build_lean
fi
[[ -d "$RT" ]] || die "runtime not staged: $RT"
mkdir -p "$OBSERVATION_RUN_DIR" || die "cannot create the run directory"
RUN=$(mktemp -d "$OBSERVATION_RUN_DIR/pnvi.XXXXXXXX") || die "mktemp failed"
MANIFEST="$RUN/manifest.tsv"; : > "$MANIFEST"
cd "$PROJECT_ROOT" || die "cannot cd to $PROJECT_ROOT"
selected() { [[ -z "$ROWS_RE" ]] || [[ "$1" =~ $ROWS_RE ]]; }

# one capped, timed, captured engine invocation; never aborts the lane
cap() { # <prefix> <timeout> <cmd...>
    local p="$1" t="$2"; shift 2
    observation_capture "$p" "${CAPPED_TEST[@]}" timeout "${t}s" "$@" < /dev/null > /dev/null || true
}
LEAN=(env LEAN_ABORT_ON_PANIC=1 "$CERBERUS_LEAN_BIN")
ORACLE=("$CERBERUS_BIN" --runtime="$RT")

# libc mode prerequisites (only if a libc-mode row is selected)
LIBC_ARGS=()
need_libc() {
    [[ ${#LIBC_ARGS[@]} -gt 0 ]] && return 0
    local out
    out=$("$PROJECT_ROOT/scripts/libc_prep.sh" --jsons "$RUN/libcjson") || die "libc_prep.sh --jsons failed (pin drift or oracle missing)"
    mapfile -t LJ <<< "$out"
    [[ ${#LJ[@]} -eq 12 ]] || die "expected 12 libc metadata jsons, got ${#LJ[@]}"
    LIBC_ARGS=(--libc "$PROJECT_ROOT/tests/libc/libc.core")
    local j; for j in "${LJ[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done
}

# bridge one TU; a bridge failure makes the row INVALID (its Lean capture is the failure)
bridge() { # <prefix> <out.json> <flags...> -- <tu>
    local p="$1" j="$2"; shift 2
    capture_cabs_json "$j" "$p" "${CAPPED_TEST[@]}" timeout "${TIMEOUT_SECS}s" "${ORACLE[@]}" --cabs-json "$@"
}

nrows=0
# ---- litmus/ and witness/: libc mode, exhaustive ----------------------------------
libc_row() { # <section> <file.c>
    local sect="$1" tu="$2" name; name="$sect/$(basename "$tu" .c)"
    selected "$name" || return 0
    need_libc
    local p="$RUN/${name//\//__}"
    cap "$p.oracle" "$TIMEOUT_SECS" "${ORACLE[@]}" --exec --batch --mode=exhaustive "$SW" "$tu"
    cap "$p.default" "$TIMEOUT_SECS" "${ORACLE[@]}" --exec --batch --mode=exhaustive "$tu"
    if bridge "$p.bridge" "$p.json" "$tu"; then
        cap "$p.lean" "$TIMEOUT_SECS" "${LEAN[@]}" --batch "$SW" "${LIBC_ARGS[@]}" "$p.json"
    else
        echo "bridge failed" > "$p.lean.capture-error"
    fi
    printf '%s\texhaustive\t%s\t%s\t%s\n' "$name" "$p.oracle" "$p.lean" "$p.default" >> "$MANIFEST"
    nrows=$((nrows+1))
}
compgen -G "tests/pnvi_testsuite/*.c" > /dev/null || die "empty litmus corpus tests/pnvi_testsuite"
n_litmus=$(ls tests/pnvi_testsuite/*.c | wc -l)
[[ "$n_litmus" -eq 44 ]] || die "tests/pnvi_testsuite holds $n_litmus .c files, expected upstream's 44"
for tu in tests/pnvi_testsuite/*.c; do libc_row litmus "$tu"; done
compgen -G "tests/pnvi_refusals/*.c" > /dev/null || die "empty witness corpus tests/pnvi_refusals"
for tu in tests/pnvi_refusals/*.c; do libc_row witness "$tu"; done

# ---- pkvm/: the census drivers, --nolibc ------------------------------------------
pkvm_selected=0
for u in pkvm-alloc pkvm-free pkvm-split-merge pkvm-init; do selected "pkvm/$u" && pkvm_selected=1; done
if [[ $pkvm_selected == 1 ]]; then
    PROJ_DEPS=""; d="$PROJECT_ROOT"
    while [[ "$d" != / ]]; do [[ -d "$d/deps" ]] && { PROJ_DEPS="$d/deps"; break; }; d="$(dirname "$d")"; done
    PKVM="${PKVM_CASE_STUDY:-$PROJ_DEPS/CN-pKVM-buddy-allocator-case-study}"
    [[ -f "$PKVM/page_alloc.c" ]] || die "pKVM case study not found (PKVM_CASE_STUDY or deps/CN-pKVM-buddy-allocator-case-study): $PKVM"
    gen=$(python3 tests/census/pkvm/derive_pool_init.py "$PKVM" "$RUN/pkvm-derived") || die "derive_pool_init.py failed"
    [[ "$gen" == "$RUN/pkvm-derived/page_alloc_census.c" && -s "$gen" ]] || die "derive_pool_init.py printed '$gen'"
    PFL=(--nostdinc -I "$PKVM" -I "$PROJECT_ROOT/tests/census/pkvm")
    pkvm_row() { # <unit> <mode first|exhaustive> <tu...>
        local u="$1" m="$2"; shift 2
        local name="pkvm/$u"; selected "$name" || return 0
        local p="$RUN/${name//\//__}" omode=() lmode=() jsons=() i=0 t ok=1
        [[ "$m" == exhaustive ]] && omode=(--mode=exhaustive) || lmode=(--first)
        cap "$p.oracle" "$TIMEOUT_SECS" "${ORACLE[@]}" --nolibc "${PFL[@]}" --exec --batch "${omode[@]}" "$SW" "$@"
        cap "$p.default" "$TIMEOUT_SECS" "${ORACLE[@]}" --nolibc "${PFL[@]}" --exec --batch "${omode[@]}" "$@"
        for t in "$@"; do
            i=$((i+1))
            bridge "$p.bridge$i" "$p.$i.json" "${PFL[@]}" "$t" || { ok=0; break; }
            jsons+=("$p.$i.json")
        done
        if [[ $ok == 1 ]]; then
            cap "$p.lean" "$TIMEOUT_SECS" "${LEAN[@]}" --batch "${lmode[@]}" "$SW" "${jsons[@]}"
        else
            echo "bridge failed" > "$p.lean.capture-error"
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$m" "$p.oracle" "$p.lean" "$p.default" >> "$MANIFEST"
        nrows=$((nrows+1))
    }
    pkvm_row pkvm-alloc first tests/census/pkvm/pkvm_alloc.c "$gen"
    pkvm_row pkvm-free first tests/census/pkvm/pkvm_free.c "$gen"
    pkvm_row pkvm-split-merge first tests/census/pkvm/pkvm_split_merge.c "$gen"
    pkvm_row pkvm-init exhaustive tests/census/pkvm/pkvm_init.c "$PKVM/page_alloc.c"
fi

# ---- minimal/: the default exec corpus under the switch, --nolibc -----------------
for tu in tests/minimal/*.c; do
    name="minimal/$(basename "$tu" .c)"
    selected "$name" || continue
    p="$RUN/${name//\//__}"
    cap "$p.oracle" "$MINIMAL_TIMEOUT_SECS" "${ORACLE[@]}" --nolibc --exec --batch --mode=exhaustive "$SW" "$tu"
    cap "$p.default" "$MINIMAL_TIMEOUT_SECS" "${ORACLE[@]}" --nolibc --exec --batch --mode=exhaustive "$tu"
    if bridge "$p.bridge" "$p.json" "$tu"; then
        cap "$p.lean" "$MINIMAL_TIMEOUT_SECS" "${LEAN[@]}" --batch "$SW" "$p.json"
    else
        echo "bridge failed" > "$p.lean.capture-error"
    fi
    printf '%s\texhaustive\t%s\t%s\t%s\n' "$name" "$p.oracle" "$p.lean" "$p.default" >> "$MANIFEST"
    nrows=$((nrows+1))
done

echo "test_pnvi: $nrows row(s) run${ROWS_RE:+ (selection $ROWS_RE)}"
rc=0
if [[ "$MODE" == record ]]; then
    [[ -z "$ROWS_RE" ]] || die "--record-baseline records the WHOLE lane; drop --rows"
    new="$RUN/baseline.new"
    python3 "$HERE/pnvi_lane.py" --manifest "$MANIFEST" --baseline "$BASELINE" --write-baseline "$new" || exit 1
    { sed -n '/^#/p' "$BASELINE" 2>/dev/null; cat "$new"; } > "$BASELINE.tmp" && mv "$BASELINE.tmp" "$BASELINE"
    echo "test_pnvi: baseline re-recorded at $BASELINE (commit it in a dedicated instrument commit, with the reason)"
else
    python3 "$HERE/pnvi_lane.py" --manifest "$MANIFEST" --baseline "$BASELINE" ${ROWS_RE:+--select "$ROWS_RE"} || rc=1
fi
if [[ -n "$KEEP" ]]; then
    mkdir -p "$KEEP" && cp -r "$RUN"/. "$KEEP"/ || die "cannot keep the run in $KEEP"
    sed -i "s#$RUN/#$KEEP/#g" "$KEEP/manifest.tsv" || die "cannot re-point the kept manifest"
fi
exit $rc
