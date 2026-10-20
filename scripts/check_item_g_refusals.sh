#!/usr/bin/env bash
# check_item_g_refusals.sh — row-1 witnesses for the two "item G" refusals
# (2026-10-20; [USER 2026-10-20] ruled that where upstream Cerberus left a case
# deliberately to a TODO, the fork either leaves it as-is or REFUSES LOUDLY — the
# run dies with a declared unsupported outcome — and never invents a verdict in
# its place; record lean_frontend/docs/2026-10-20_item-g-refusals-record.md).
#
# G1 — memcpy on overlapping objects (C17 7.24.2.1#2 undefined). Upstream's
#   memory/concrete/impl_mem.ml `memcpy` opens with `(* TODO: if ptrval1 and
#   ptrval2 overlap ==> UB *)` (b9aeedcb4 :2636) and copies byte-wise, so both
#   engines answered Specified(7) on upstream-tray draft 56's witness. Now the
#   memory model's copy REFUSES in both engines with ONE text (oracle: `failwith`
#   at the head of `memcpy`; Lean: `failwithI` in CerbMem.memcpyM), when both
#   pointers are concrete in the same allocation, or both are device-memory
#   pointers (ptrfromint mints Prov_device for an integer in device_ranges —
#   the pre-merge audit's P2-1: both engines answered Specified(5)/(111) on
#   such copies before the arm), and [a1, a1+n), [a2, a2+n) intersect, n > 0
#   (a mixed allocation/device pair, reachable only under the fork-only
#   --address-space-top, is a named residual: the record):
#     Concrete.memcpy: refused - memcpy on overlapping objects (...)
# G2 — an allocation with an invalid alignment (not a positive power of two;
#   C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning null). Upstream's
#   runtime/libcore/std.core:385 aligned_alloc_proxy checks only `size rem_t
#   align = 0` and the allocator rounds to ANY alignment (draft 57: both engines
#   allocated at "alignment 3"). Now the ALLOCATOR of both memory models refuses
#   with ONE text (oracle: `failwith` in impl_mem.ml `allocator`, after its
#   out-of-memory kill and before the remainder; Lean: CerbMem.allocator), not
#   std.core (Core text expresses only verdicts, and std.core is shared):
#     Concrete.allocator: refused - allocation with an invalid alignment N (...)
#   Alignment ZERO is out of scope (draft 34: the pre-existing Division_by_zero
#   crash at std.core:385's rem_t) and must be UNCHANGED.
# Shape on each engine: the oracle dies on the uncaught exception (`cerberus:
# internal error, uncaught exception: Failure("<text>")`, exit 125); the Lean
# engine aborts under LEAN_ABORT_ON_PANIC=1 (exit 134) with a PANIC line carrying
# the SAME text; the two texts are compared byte for byte (the allocation id,
# addresses and size inside them are the same on both engines, whose allocators
# mirror each other).
# Controls (Lean = oracle, exit code and verdict line): non-overlapping copies
# (adjacent halves of one object; two objects; a zero-length copy of a pointer
# onto itself; realloc's copy, which is new <- old; an out-of-bounds but
# non-overlapping copy, UB on both — the loop's own checks are unchanged; a
# non-overlapping copy inside device memory);
# aligned_alloc with a valid alignment; ONE allocation at EACH alignment the
# lanes use (measured 2026-10-20: 1, 2, 4, 8, 16 — via aligned_alloc, malloc
# (IvMaxAlignment = 8) and `create` of objects of each alignment); the unchanged
# size-not-a-multiple DUMMY UB; and the unchanged zero-alignment crash (both
# engines die as before, with their pre-existing texts). Fail-closed.
#
# Usage: check_item_g_refusals.sh             the witnesses
#        check_item_g_refusals.sh --selftest  plants: the witnesses must FAIL against
#            (a) `answer`: the pre-fix behaviour of BOTH engines — stubs that answer
#                Defined/Specified(7) on every witness program (the controls run the
#                real engines);
#            (b) `lean-answer`: the real oracle, a Lean stub that answers on every input;
#            (c) `refuse-all`: both engines refuse every input with the two texts
#                (the controls must catch it);
#            (d) `lean-no-abort`: the real Lean output, but exit 0 — a message without
#                a death is not a refusal;
#            (e) `lean-other-text`: the real Lean, its text altered — the two engines'
#                texts must be identical;
#            then the real run.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
NAME=check_item_g_refusals
G1_HEAD='Concrete.memcpy: refused - memcpy on overlapping objects ('
G1_TAIL="C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)"
G2_HEAD='Concrete.allocator: refused - allocation with an invalid alignment '
G2_TAIL="C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning a null pointer (C11: undefined behaviour); upstream allocates under runtime/libcore/std.core:385 aligned_alloc_proxy, whose only check is 'size rem_t align = 0', and impl_mem.ml allocator's quomod (b9aeedcb4 :1253) - the fork refuses rather than decides (item G2, 2026-10-20)"
# the pre-existing zero-alignment crash (draft 34; register row CerbMem.integerRem_t): unchanged
ZERO_ORACLE='Division_by_zero'
ZERO_LEAN="CerbMem.integerRem_t: Division_by_zero (zarith Z.rem raises; mirrors the oracle's uncaught exception, impl_mem.ml:2481-2482 op_ival IntRem_t)"

if [[ "${1:-}" == "--selftest" ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    ANSWER='Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}'
    # (a) answer: on a witness program (w_*.c / w_*.json) under --exec / --batch, answer as
    # both engines did before the fix; everything else (controls, --cabs-json) runs the real engine
    cat > "$ST/oracle-answer" <<EOF
#!/usr/bin/env bash
last="\${@: -1}"
if [[ " \$* " == *" --exec "* && "\$(basename "\$last")" == w_*.c ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_ORACLE" "\$@"
EOF
    cat > "$ST/lean-answer-witnesses" <<EOF
#!/usr/bin/env bash
last="\${@: -1}"
if [[ "\$(basename "\$last")" == w_*.json ]]; then echo '$ANSWER'; exit 0; fi
exec "$REAL_BIN" "\$@"
EOF
    # (b) lean-answer: answer on every input
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' "$ANSWER" > "$ST/lean-answer"
    # (c) refuse-all, in the right shape and words (fixed texts, passed through the
    # environment: they contain quotes), on both sides; the oracle stub still exports
    # Cabs JSON so the Lean stub is exercised
    export PLANT_G1="${G1_HEAD}allocation 1: destination [1, 5) and source [2, 6), n = 4); $G1_TAIL"
    export PLANT_G2="${G2_HEAD}3 (not a positive power of two; size 9); $G2_TAIL"
    cat > "$ST/oracle-refuse-all" <<EOF
#!/usr/bin/env bash
if [[ " \$* " == *" --cabs-json "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
echo 'cerberus: internal error, uncaught exception:' >&2
printf '          Failure("%s")\n' "\$PLANT_G1" "\$PLANT_G2" >&2
exit 125
EOF
    cat > "$ST/lean-refuse-all" <<EOF
#!/usr/bin/env bash
printf 'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: %s\n' "\$PLANT_G1" "\$PLANT_G2" >&2
exit 134
EOF
    # (d) lean-no-abort: the real Lean's output, exit 0
    printf '#!/usr/bin/env bash\n"%s" "$@" 2>&1\nexit 0\n' "$REAL_BIN" > "$ST/lean-no-abort"
    # (e) lean-other-text: the real Lean, its refusal text altered, exit code kept
    printf '#!/usr/bin/env bash\nout=$("%s" "$@" 2>&1); rc=$?\nprintf "%%s\\n" "$out" | sed "s/the fork refuses rather than decides/the fork refuses/"\nexit $rc\n' "$REAL_BIN" > "$ST/lean-other-text"
    chmod +x "$ST"/oracle-answer "$ST"/lean-answer-witnesses "$ST"/lean-answer "$ST"/oracle-refuse-all "$ST"/lean-refuse-all "$ST"/lean-no-abort "$ST"/lean-other-text
    run_plant() {  # <label> <oracle> <lean> <expected failure count> [witness label that MUST be among the failures]...
        local label="$1" o="$2" l="$3" want="$4" got req; shift 4
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" "$0" > "$ST/$label.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$label' PASSED the witnesses (vacuous check)"
            cat "$ST/$label.out"
            exit 1
        fi
        got=$(grep -c 'FAIL —' "$ST/$label.out")
        if [[ "$got" != "$want" ]]; then
            echo "$NAME: SELFTEST FAIL — plant '$label' caught $got failing witness(es), expected exactly $want"
            cat "$ST/$label.out"
            exit 1
        fi
        for req in "$@"; do  # the plant must fail THESE witnesses, not merely some (asm precedent, audit LOW-1)
            if ! grep -qF "FAIL — $req:" "$ST/$label.out"; then
                echo "$NAME: SELFTEST FAIL — plant '$label' did not fail the witness '$req' (the plant does not exercise it)"
                cat "$ST/$label.out"
                exit 1
            fi
        done
        echo "$NAME: selftest plant '$label' caught: $got failing witness(es) (= expected $want${*:+; incl. the required witnesses})"
    }
    # expected counts, derived: 9 witnesses (4 memcpy + 2 device memcpy + 3 alignment), 10 controls (9 verdict
    # controls, of which 2 are UB on both and exit 1, + 1 both-crash control).
    #  answer:          each witness fails the oracle check and the Lean check (the text cross-check needs both texts)  = 9 x 2
    #  lean-answer:     each witness fails the Lean check; every control fails (Lean = oracle)                           = 9 + 10
    #  refuse-all:      the witnesses pass (one shape, identical texts); every control fails                             = 10
    #  lean-no-abort:   each witness fails the Lean exit check; the 2 UB controls (exit 1) and the crash control fail    = 9 + 3
    #  lean-other-text: each witness fails the text cross-check only; the controls pass                                  = 9
    run_plant answer "$ST/oracle-answer" "$ST/lean-answer-witnesses" 18 "memcpy forward overlap (tray-56 witness)" "memcpy overlap in device memory (audit P2-1 probe, 0xABC)" "aligned_alloc(3, 9) (tray-57 witness)"
    run_plant lean-answer "$REAL_ORACLE" "$ST/lean-answer" 19 "memcpy forward overlap (tray-56 witness)" "memcpy overlap in device memory (audit P2-1 probe, 0xABC)" "aligned_alloc(3, 9) (tray-57 witness)" "memcpy of adjacent halves of one object" "non-overlapping memcpy in device memory" "one allocation at each alignment the lanes use"
    run_plant refuse-all "$ST/oracle-refuse-all" "$ST/lean-refuse-all" 10 "memcpy of adjacent halves of one object" "non-overlapping memcpy in device memory" "one allocation at each alignment the lanes use" "aligned_alloc(0, 8): the pre-existing zero-alignment crash is unchanged (draft 34)"
    run_plant lean-no-abort "$REAL_ORACLE" "$ST/lean-no-abort" 12 "memcpy forward overlap (tray-56 witness)" "memcpy overlap in device memory (audit P2-1 probe, 0xABC)" "aligned_alloc(3, 9) (tray-57 witness)"
    run_plant lean-other-text "$REAL_ORACLE" "$ST/lean-other-text" 9 "memcpy forward overlap (tray-56 witness)" "memcpy overlap in device memory (audit P2-1 probe, 0xABC)" "aligned_alloc(3, 9) (tray-57 witness)"
    "$0"; exit $?   # not exec: the EXIT trap must remove $ST
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
W=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$W"' EXIT
cd "$W" || { echo "$NAME: FAIL — cd $W"; exit 1; }
export NO_COLOR=1 TERM=dumb

fails=0; n=0
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }

oracle_exec() {  # <c-file> -> OOUT (stdout+stderr), ORC
    OOUT=$("$ORACLE" --runtime="$PREFIX" --exec --batch --nolibc "$1" 2>&1); ORC=$?
}
lean_batch() {  # <json> -> LOUT (stdout+stderr), LRC
    LOUT=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --runtime="$PREFIX" "$1" 2>&1); LRC=$?
}
cabs_ok() {  # <c-file> <json>: the export must succeed
    "$ORACLE" --runtime="$PREFIX" --cabs-json "$1" > "$2" 2> "$2.err" && [[ -s "$2" ]]
}
verdict_line() { grep -aE '^(Defined|Undefined|Error) ' | head -1; }
text_from() {  # <head> <output>: the refusal text from its head to the end of its line (the oracle's closing `")` removed)
    local line
    line=$(printf '%s\n' "$2" | grep -aF -m1 "$1") || return 1
    line="$1${line#*"$1"}"
    printf '%s' "${line%\")}"
}

witness() {  # <label> <c-file> <head> <tail>: refused on BOTH engines with one text
    local label="$1" c="$2" head="$3" tail="$4" j="$W/$2.json" omsg= lmsg=
    n=$((n + 1))
    oracle_exec "$c"
    if [[ $ORC -eq 125 && "$OOUT" == *"uncaught exception"* && "$OOUT" == *"Failure(\"$head"* && "$OOUT" == *"$tail\")"* ]]; then
        omsg=$(text_from "$head" "$OOUT")
    else
        fail "$label: oracle: expected exit 125 + uncaught Failure(\"$head…$tail\"); got rc=$ORC: ${OOUT:0:400}"
    fi
    if ! cabs_ok "$c" "$j"; then
        fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lean_batch "$j"
    if [[ $LRC -eq 134 && "$LOUT" == *"PANIC"* && "$LOUT" == *"$head"* && "$LOUT" == *"$tail"* ]]; then
        lmsg=$(text_from "$head" "$LOUT")
    else
        fail "$label: Lean: expected exit 134 (abort under LEAN_ABORT_ON_PANIC=1) + a PANIC line carrying '$head…$tail'; got rc=$LRC: ${LOUT:0:400}"
    fi
    if [[ -n "$omsg" && -n "$lmsg" && "$omsg" != "$lmsg" ]]; then
        fail "$label: the two engines' texts differ: oracle [$omsg] vs Lean [$lmsg]"
    fi
}
control() {  # <label> <c-file> <expected oracle verdict line>: Lean = oracle (exit code and verdict line)
    local label="$1" c="$2" want="$3" j="$W/$2.json" o
    n=$((n + 1))
    oracle_exec "$c"
    o=$(printf '%s\n' "$OOUT" | verdict_line)
    [[ "$o" == "$want" ]] || { fail "$label: oracle: expected [$want]; got rc=$ORC [$o]"; return; }
    cabs_ok "$c" "$j" || { fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return; }
    lean_batch "$j"
    [[ $LRC -eq $ORC && "$(printf '%s\n' "$LOUT" | verdict_line)" == "$o" ]] \
        || fail "$label: expected Lean = oracle (rc $ORC, [$o]); got rc=$LRC: ${LOUT:0:300}"
}
crash_control() {  # <label> <c-file> <oracle text> <lean text>: both die exactly as before
    local label="$1" c="$2" otext="$3" ltext="$4" j="$W/$2.json"
    n=$((n + 1))
    oracle_exec "$c"
    [[ $ORC -eq 125 && "$OOUT" == *"uncaught exception"* && "$OOUT" == *"$otext"* ]] \
        || { fail "$label: oracle: expected the pre-existing crash (exit 125, '$otext'); got rc=$ORC: ${OOUT:0:300}"; return; }
    cabs_ok "$c" "$j" || { fail "$label: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return; }
    lean_batch "$j"
    [[ $LRC -eq 134 && "$LOUT" == *"PANIC"* && "$LOUT" == *"$ltext"* ]] \
        || fail "$label: Lean: expected the pre-existing crash (exit 134, '$ltext'); got rc=$LRC: ${LOUT:0:300}"
}

PROTO_MEM='void *memcpy(void *dst, const void *src, unsigned long n);'
PROTO_ALLOC='void *aligned_alloc(unsigned long alignment, unsigned long size); void *malloc(unsigned long size); void *realloc(void *p, unsigned long size); void free(void *p);'
# --- G1 witnesses (upstream-tray draft 56's program first; the backward shape of the retired coverage control mem4-020; the same object; a malloc'd object)
printf '%s\nint main(void) {\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(b, b + 1, 4);          /* overlapping objects: C17 7.24.2.1 UB */\n  return b[0] + b[3];           /* 2 + 5 if copied byte-wise forward */\n}\n' "$PROTO_MEM" > w_memcpy_fwd.c
printf '%s\nint main(void) {\n  char a[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(a + 1, a, 4);\n  return a[0] * 10000 + a[1] * 1000 + a[2] * 100 + a[3] * 10 + a[4];\n}\n' "$PROTO_MEM" > w_memcpy_bwd.c
printf '%s\nint main(void) {\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(b, b, 4);\n  return b[3];\n}\n' "$PROTO_MEM" > w_memcpy_self.c
printf '%s\n%s\nint main(void) {\n  char *p = malloc(8);\n  if (!p) return 99;\n  for (int i = 0; i < 8; i++) p[i] = (char)(i + 1);\n  memcpy(p + 2, p, 4);\n  int r = p[2] + p[5];\n  free(p);\n  return r;\n}\n' "$PROTO_MEM" "$PROTO_ALLOC" > w_memcpy_dyn.c
# --- G1 device-memory witnesses (the pre-merge audit's P2-1 probes: `(char*)0xABC` and `(char*)0x40000000` are
# Prov_device pointers — ptrfromint's device_ranges — which load/store serve; both engines answered
# Specified(5) / Specified(111) before the arm)
printf '%s\nint main(void) {\n  char *p = (char*)0xABC;\n  p[0] = 1; p[1] = 2; p[2] = 3;\n  memcpy(p, p + 1, 2);\n  return p[0] + p[1];\n}\n' "$PROTO_MEM" > w_memcpy_dev_abc.c
printf '%s\nint main(void) {\n  char *p = (char*)0x40000000;\n  p[0] = 1; p[1] = 2; p[2] = 3; p[3] = 4;\n  memcpy(p + 1, p, 3);\n  return p[1] * 100 + p[2] * 10 + p[3];\n}\n' "$PROTO_MEM" > w_memcpy_dev_4000.c
# --- G2 witnesses (draft 57's program first; an even non-power of two; a large one)
printf '%s\nint main(void) {\n  char *p = aligned_alloc(3, 9); /* 3 is not a valid alignment */\n  if (p == 0) return 1;\n  p[0] = 42;\n  int r = p[0];\n  free(p);\n  return r;\n}\n' "$PROTO_ALLOC" > w_alloc_3.c
printf '%s\nint main(void) {\n  char *p = aligned_alloc(6, 12);\n  if (p == 0) return 1;\n  p[0] = 7;\n  int r = p[0];\n  free(p);\n  return r;\n}\n' "$PROTO_ALLOC" > w_alloc_6.c
printf '%s\nint main(void) {\n  char *p = aligned_alloc(1000, 2000);\n  if (p == 0) return 1;\n  p[0] = 9;\n  int r = p[0];\n  free(p);\n  return r;\n}\n' "$PROTO_ALLOC" > w_alloc_1000.c
# --- G1 controls
printf '%s\nint main(void) {\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(b, b + 4, 4);          /* [0,4) and [4,8): adjacent, not overlapping */\n  return b[0] + b[3];           /* 5 + 8 */\n}\n' "$PROTO_MEM" > ctl_memcpy_adjacent.c
printf '%s\nint main(void) {\n  char a[8] = {0};\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(a, b, 8);\n  return a[0] + a[7];           /* 1 + 8 */\n}\n' "$PROTO_MEM" > ctl_memcpy_two_objects.c
printf '%s\nint main(void) {\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(b, b, 0);              /* n = 0: nothing overlaps */\n  return b[1] + 20;             /* 22 */\n}\n' "$PROTO_MEM" > ctl_memcpy_zero_self.c
printf '%s\nint main(void) {\n  char *p = malloc(4);\n  if (!p) return 99;\n  p[0] = 3; p[3] = 4;\n  p = realloc(p, 16);            /* the model copies new <- old: two allocations */\n  if (!p) return 98;\n  int r = p[0] * 10 + p[3];      /* 34 */\n  free(p);\n  return r;\n}\n' "$PROTO_ALLOC" > ctl_memcpy_realloc.c
printf '%s\nint main(void) {\n  char a[8] = {0};\n  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};\n  memcpy(a, b + 6, 4);          /* source [6,10) leaves b: out of bounds, not overlapping */\n  return a[0];\n}\n' "$PROTO_MEM" > ctl_memcpy_oob.c
printf '%s\nint main(void) {\n  char *p = (char*)0xABC;        /* device memory: [0xABC, 0xAC0) */\n  p[0] = 1; p[1] = 2; p[2] = 3; p[3] = 4;\n  memcpy(p, p + 2, 2);          /* [0,2) and [2,4): adjacent, not overlapping */\n  return p[0] * 10 + p[1];      /* 34 */\n}\n' "$PROTO_MEM" > ctl_memcpy_dev.c
# --- G2 controls
printf '%s\nint main(void) {\n  char *p = aligned_alloc(16, 32);\n  if (p == 0) return 1;\n  p[0] = 42;\n  int r = p[0];\n  free(p);\n  return r;\n}\n' "$PROTO_ALLOC" > ctl_alloc_16.c
printf '%s\nint main(void) {\n  char c = 1; short s = 2; int i = 3; long l = 4; long double ld = 5;   /* create at alignof 1, 2, 4, 8, 16 */\n  char *p1 = aligned_alloc(1, 1); char *p2 = aligned_alloc(2, 2); char *p4 = aligned_alloc(4, 4);\n  char *p8 = aligned_alloc(8, 8); char *p16 = aligned_alloc(16, 16); char *pm = malloc(8);   /* malloc: IvMaxAlignment = 8 */\n  if (!p1 || !p2 || !p4 || !p8 || !p16 || !pm) return 99;\n  p1[0] = 1; p2[0] = 2; p4[0] = 4; p8[0] = 8; p16[0] = 16; pm[0] = 32;\n  int r = c + s + i + (int)l + (int)ld + p1[0] + p2[0] + p4[0] + p8[0] + p16[0] + pm[0];   /* 15 + 63 */\n  free(p1); free(p2); free(p4); free(p8); free(p16); free(pm);\n  return r;\n}\n' "$PROTO_ALLOC" > ctl_alignments.c
printf '%s\nint main(void) { void *p = aligned_alloc(16, 8); return p != 0; }\n' "$PROTO_ALLOC" > ctl_alloc_bad_size.c
printf '%s\nint main(void) { void *p = aligned_alloc(0, 8); return p != 0; }\n' "$PROTO_ALLOC" > ctl_alloc_zero.c

witness "memcpy forward overlap (tray-56 witness)" w_memcpy_fwd.c "$G1_HEAD" "$G1_TAIL"
witness "memcpy backward overlap (the retired coverage control mem4-020's shape)" w_memcpy_bwd.c "$G1_HEAD" "$G1_TAIL"
witness "memcpy of an object onto itself" w_memcpy_self.c "$G1_HEAD" "$G1_TAIL"
witness "memcpy overlap inside a malloc'd object" w_memcpy_dyn.c "$G1_HEAD" "$G1_TAIL"
witness "memcpy overlap in device memory (audit P2-1 probe, 0xABC)" w_memcpy_dev_abc.c "$G1_HEAD" "$G1_TAIL"
witness "memcpy backward overlap in device memory (audit P2-1 probe, 0x40000000)" w_memcpy_dev_4000.c "$G1_HEAD" "$G1_TAIL"
witness "aligned_alloc(3, 9) (tray-57 witness)" w_alloc_3.c "$G2_HEAD" "$G2_TAIL"
witness "aligned_alloc(6, 12) (even, not a power of two)" w_alloc_6.c "$G2_HEAD" "$G2_TAIL"
witness "aligned_alloc(1000, 2000)" w_alloc_1000.c "$G2_HEAD" "$G2_TAIL"
control "memcpy of adjacent halves of one object" ctl_memcpy_adjacent.c 'Defined {value: "Specified(13)", stdout: "", stderr: "", blocked: "false"}'
control "memcpy between two objects" ctl_memcpy_two_objects.c 'Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}'
control "memcpy of length 0 of a pointer onto itself" ctl_memcpy_zero_self.c 'Defined {value: "Specified(22)", stdout: "", stderr: "", blocked: "false"}'
control "realloc's copy (new <- old, two allocations)" ctl_memcpy_realloc.c 'Defined {value: "Specified(34)", stdout: "", stderr: "", blocked: "false"}'
control "out-of-bounds, non-overlapping memcpy is the loop's own UB on both" ctl_memcpy_oob.c 'Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<5:3--5:22>"}'
control "non-overlapping memcpy in device memory" ctl_memcpy_dev.c 'Defined {value: "Specified(34)", stdout: "", stderr: "", blocked: "false"}'
control "aligned_alloc(16, 32)" ctl_alloc_16.c 'Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}'
control "one allocation at each alignment the lanes use" ctl_alignments.c 'Defined {value: "Specified(78)", stdout: "", stderr: "", blocked: "false"}'
control "aligned_alloc(16, 8): the size clause's DUMMY UB is unchanged" ctl_alloc_bad_size.c 'Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<2:28--2:48>"}'
crash_control "aligned_alloc(0, 8): the pre-existing zero-alignment crash is unchanged (draft 34)" ctl_alloc_zero.c "$ZERO_ORACLE" "$ZERO_LEAN"

[[ $fails -eq 0 ]] || { echo "$NAME: $fails witness failure(s) over $n cases"; exit 1; }
echo "$NAME: OK ($n cases: 6 overlapping memcpy programs (4 in allocations, 2 in device memory) and 3 invalid-alignment allocations refused by the oracle (uncaught Failure, exit 125) and by the Lean engine (abort, exit 134) with byte-identical texts; 9 controls agree with the oracle (6 non-overlapping copies incl. realloc, an out-of-bounds UB and device memory, aligned_alloc(16, 32), one allocation at each alignment the lanes use, the unchanged size-clause UB); the zero-alignment crash is unchanged on both)"
