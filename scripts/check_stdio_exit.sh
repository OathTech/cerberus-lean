#!/usr/bin/env bash
# check_stdio_exit.sh — row-1 witnesses for program termination with the C library linked
# (upstream-tray reports 24 and 25; charter lean_frontend/docs/2026-11-05_worker-charter-stdio-exit-flush.md;
# record lean_frontend/docs/2026-11-05_stdio-exit-flush-record.md; contract D15).
#
# Upstream's driver ends the program at the startup function's return (driver.lem process_core_step2,
# Step_done2 -> prepare_exit) without entering the C library's `exit`, and the shipped library's `exit`
# ran the atexit handlers but flushed no stream, so every FILE buffer still holding data at termination
# was lost (`fputs("out", stdout); return 0;` printed nothing; `puts("a"); puts("b");` printed only `a`
# because the shipped stdout turns fully buffered after its first write) and the handlers registered by
# a program that returns from main never ran. Since 2026-11-06 the SHARED driver routes the startup
# function's return through the library's `exit` whenever the linked Core file defines one (libc mode;
# C17 5.1.2.2.3), the library's `exit` flushes every open stream after the handlers (7.22.4.4#2-#4), its
# `vfprintf` flushes the stream's pending buffer before the builtin writes through the descriptor, each
# engine withholds std.core's `printf` proxy from a libc-mode program so the identifier resolves to the
# library's own `printf` (7.21.3: a stream's writes are ordered; the proxy wrote past the buffer), and
# `vprintf` is defined (7.21.6.10) -- both engines: the driver by generation, the library through the
# pinned Core dumps, the proxy rule mirrored in main.ml's prelude and Main.lean's stdlib load.
#
# Witnesses: tests/stdio_exit/*.c, each pinned in tests/stdio_exit/expected.txt to ONE line that both
# engines' --batch output must equal byte for byte (so Lean = oracle follows), with equal exit codes:
#   - the flush_*, order_* and atexit_* rows and the two controls are pinned to gcc 13's line
#     (tests/stdio_exit/gcc.txt: `Defined {value: "Specified(<$?>)", stdout: "<gcc stdout>", stderr:
#     "<gcc stderr>", blocked: "false"}`, derived 2026-11-06 with `gcc -std=c11 -w -O0`, the streams
#     captured separately; every program UB-free by construction except the one declared below);
#   - the FORK-PINNED rows (the declared list below) are pinned to the fork's own line, gcc's beside it in
#     gcc.txt: status_* (the model reports the returned int; the host's $? is n mod 256), impl_* (_Exit,
#     quick_exit, abort after buffered output: 7.22.4.5#2 / 7.22.4.7#3 / 7.22.4.1#2, implementation-defined;
#     the shipped library wrote the first newline-terminated line through before turning fully buffered,
#     gcc with a pipe prints nothing);
#     atexit_libc_handler_calls_exit (UB 7.22.4.4#3) is pinned to the shipped library's (musl's) text, which
#     gcc/glibc also follow -- a gcc-pinned row, declared, not a fork reading;
#   - gap_fopen_unclosed: the oracle's in-memory filesystem answers, the Lean engine REFUSES fopen
#     (contract D2): the oracle's line and the Lean refusal are pinned (a gap control, not an agreement);
#   - nolibc_*: under --nolibc on BOTH engines, compared under the symbol-number projection `Symbol(_, ` (the
#     engines number symbols differently; ladder row 6b's rule) with equal exit codes: the two tray reproducers
#     keep upstream's path (no library: `atexit` an unknown procedure, `__stdout` unresolved), and the pre-merge
#     review's three programs that DEFINE `exit` themselves with external linkage (UB 7.1.3) pin the rule: the
#     library's shape `void (signed int)` is routed and, returning, is the loud kill; another arity or return type
#     is not routed and keeps the mainline's answer.
# Negative control: tests/stdio_exit/pristine.txt carries pristine c3ff8c53f's lines; the `pristine-pair`
# plant must FAIL exactly the moved rows. A row whose pin equals neither gcc's line nor the declared
# fork-pinned list is a FAIL (a silent re-pin cannot pass).
# Fail-closed.
#
# Usage: check_stdio_exit.sh             the witnesses
#        check_stdio_exit.sh --selftest  plants (on the PLANT subset, then the real run):
#            (a) `pristine-pair`: both engines replay pristine's lines
#            (b) `lean-pristine`: the real oracle, the Lean engine replays pristine's lines
#            (c) `lean-fixed`: the Lean engine answers one fixed line on every input
#            (d) `oracle-rc`: the real oracle's output with its exit code forced to 1
#            (e) `expect-tamper`: one pinned line altered by a character (the expectation side)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_BIN="$ROOT/lean_frontend/.lake/build/bin/cerberus-lean"
BIN="${CERB_LEAN_BIN_OVERRIDE:-$REAL_BIN}"
REAL_ORACLE="$ROOT/_build/default/backend/driver/main.exe"
ORACLE="${CERB_ORACLE_BIN_OVERRIDE:-$REAL_ORACLE}"
PREFIX="$ROOT/_build/install/default"
CASES="$ROOT/tests/stdio_exit"
EXPECT="${CERB_SE_EXPECT_OVERRIDE:-$CASES/expected.txt}"
GCC_LINES="$CASES/gcc.txt"
PRISTINE="$CASES/pristine.txt"
ONLY="${CERB_SE_ONLY:-}"
NAME=check_stdio_exit
# the declared fork-pinned rows (their pins differ from gcc's line; the reasons are in each program's header)
FORK_PINNED="status_return_300 status_return_minus_one status_return_256_handler impl_Exit_after_buffered impl_quick_exit_after_buffered impl_abort_after_buffered"
GAP_FS="gap_fopen_unclosed"
GAP_LEAN_TEXT='"REFUSAL","fs","open"'
# the plant subset: moved rows + unmoved rows + the gap control + a nolibc control
PLANT_MOVED="flush_fputs_no_newline flush_puts_twice atexit_on_return order_fputs_then_printf status_return_300"
PLANT_SAME="atexit_on_exit_control order_write_fd"
PLANT_GAP="gap_fopen_unclosed"
PLANT_NOLIBC="nolibc_atexit_on_return"

if [[ "${1:-}" == --selftest ]]; then
    mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
    ST=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.selftest.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
    trap 'rm -rf "$ST"' EXIT
    [[ -f "$PRISTINE" ]] || { echo "$NAME: FAIL — $PRISTINE missing"; exit 1; }
    export PLANT_PRISTINE="$PRISTINE"
    # the oracle stubs delegate every invocation that is not an --exec run (the --cabs-json export and
    # libc_prep.sh's --pp=core / --cabs-json, which honour the override too) to the real oracle
    cat > "$ST/oracle-pristine" <<EOS
#!/usr/bin/env bash
if [[ " \$* " != *" --exec "* ]]; then exec "$REAL_ORACLE" "\$@"; fi
last="\${@: -1}"; b=\$(basename "\${last%.c}")
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
printf '%s\n' "\$line"; exit 0
EOS
    cat > "$ST/lean-pristine" <<EOS
#!/usr/bin/env bash
last="\${@: -1}"; b=\$(basename "\${last%.json}"); b=\${b%.c}
line=\$(awk -F'\t' -v n="\$b" '\$1==n{print substr(\$0, length(n)+2)}' "\$PLANT_PRISTINE")
[[ -n "\$line" ]] || { echo "stub: no pristine line for \$b" >&2; exit 99; }
printf '%s\n' "\$line"; exit 0
EOS
    printf '#!/usr/bin/env bash\necho %q\nexit 0\n' 'Defined {value: "Specified(0)", stdout: "out", stderr: "", blocked: "false"}' > "$ST/lean-fixed"
    printf '#!/usr/bin/env bash\nif [[ " $* " != *" --exec "* ]]; then exec "%s" "$@"; fi\n"%s" "$@"\nexit 1\n' "$REAL_ORACLE" "$REAL_ORACLE" > "$ST/oracle-rc"
    chmod +x "$ST"/oracle-pristine "$ST"/lean-pristine "$ST"/lean-fixed "$ST"/oracle-rc
    awk -F'\t' -v OFS='\t' '$1=="flush_puts_twice"{sub(/stdout: "a/, "stdout: \"z", $0)} {print}' "$EXPECT" > "$ST/expected-tampered.txt"
    cmp -s "$ST/expected-tampered.txt" "$EXPECT" && { echo "$NAME: SELFTEST FAIL — the tamper plant did not alter the expectation"; exit 1; }
    run_plant() {  # <label> <oracle> <lean> <expect-file> <expected failure count> [required failing program]...
        local label="$1" o="$2" l="$3" e="$4" want="$5" got req; shift 5
        if CERB_ORACLE_BIN_OVERRIDE="$o" CERB_LEAN_BIN_OVERRIDE="$l" CERB_SE_EXPECT_OVERRIDE="$e" \
           CERB_SE_ONLY="$PLANT_MOVED $PLANT_SAME $PLANT_GAP $PLANT_NOLIBC" "$0" > "$ST/$label.out" 2>&1; then
            echo "$NAME: SELFTEST FAIL — plant '$label' PASSED the witnesses (vacuous check)"; cat "$ST/$label.out"; exit 1
        fi
        got=$(grep -c 'FAIL —' "$ST/$label.out")
        if [[ "$got" != "$want" ]]; then
            echo "$NAME: SELFTEST FAIL — plant '$label' caught $got failing check(s), expected exactly $want"; cat "$ST/$label.out"; exit 1
        fi
        for req in "$@"; do
            grep -qF "FAIL — $req:" "$ST/$label.out" || { echo "$NAME: SELFTEST FAIL — plant '$label' did not fail '$req'"; cat "$ST/$label.out"; exit 1; }
        done
        echo "$NAME: selftest plant '$label' caught: $got failing check(s) (= expected $want${*:+; incl. the required programs})"
    }
    # Expected counts, derived on the plant subset (5 moved + 2 same rows, 1 gap control, 1 nolibc control = 9).
    # Checks per row: C1 oracle rc 0 + line = pin, C2 Lean line = pin, C3 Lean rc = oracle rc; the gap control:
    # C1 oracle rc 0 + line = pin, C2 Lean rc 134 + the refusal text; the nolibc control: C1 oracle rc 1 + projected
    # line = pin, C2 Lean rc 1 + projected line = pin. The replay stubs answer rc 0 with the pristine line (no
    # pristine line -> exit 99, no verdict); status_return_300 is FORK-PINNED (its pin is the fork's line, which
    # pristine does not print).
    #  pristine-pair: 5 moved x (C1 + C2) = 10; the 2 same pass; gap: the oracle stub replays pristine = the pin -> C1
    #                 passes, the Lean stub rc 0 without the refusal -> C2 = 1; nolibc: stub rc 0 -> C1 + C2 = 2  = 13
    #  lean-pristine: 5 moved x C2 = 5; gap C2 = 1; nolibc: Lean stub rc 0 -> C2 = 1                          = 7
    #  lean-fixed:    7 Defined rows: C2 fails on 6 (flush_fputs_no_newline's pin IS the fixed line) = 6; gap C2 = 1;
    #                 nolibc C2 = 1                                                                            = 8
    #  oracle-rc:     7 Defined rows x (C1 rc 1 + C3 0 != 1) = 14; gap C1 = 1; nolibc passes (rc 1 is its pin)  = 15
    #  expect-tamper: flush_puts_twice: the pin classification (neither gcc's line nor declared) + C1 + C2      = 3
    run_plant pristine-pair "$ST/oracle-pristine" "$ST/lean-pristine" "$EXPECT" 13 flush_fputs_no_newline flush_puts_twice atexit_on_return order_fputs_then_printf status_return_300 gap_fopen_unclosed nolibc_atexit_on_return
    run_plant lean-pristine "$REAL_ORACLE" "$ST/lean-pristine" "$EXPECT" 7 flush_fputs_no_newline status_return_300
    run_plant lean-fixed "$REAL_ORACLE" "$ST/lean-fixed" "$EXPECT" 8 flush_puts_twice atexit_on_exit_control gap_fopen_unclosed nolibc_atexit_on_return
    run_plant oracle-rc "$ST/oracle-rc" "$REAL_BIN" "$EXPECT" 15 flush_fputs_no_newline order_write_fd gap_fopen_unclosed
    run_plant expect-tamper "$REAL_ORACLE" "$REAL_BIN" "$ST/expected-tampered.txt" 3 flush_puts_twice
    "$0"; exit $?
fi

[[ -x "$BIN" ]] || { echo "$NAME: FAIL — driver not built: $BIN"; exit 1; }
[[ -x "$ORACLE" ]] || { echo "$NAME: FAIL — oracle not built: $ORACLE"; exit 1; }
[[ -f "$PREFIX/lib/cerberus-lib/runtime/libcore/std.core" ]] || { echo "$NAME: FAIL — oracle runtime not staged under $PREFIX"; exit 1; }
[[ -f "$PREFIX/lib/cerberus/runtime/libc/libc.co" ]] || { echo "$NAME: FAIL — the libc object is not staged under $PREFIX (dune build cerberus.install)"; exit 1; }
[[ -d "$CASES" && -f "$EXPECT" && -f "$GCC_LINES" ]] || { echo "$NAME: FAIL — witness programs or expectations missing ($CASES, $EXPECT, $GCC_LINES)"; exit 1; }
mkdir -p "$ROOT/.tmp/scripts" || { echo "$NAME: FAIL — cannot create $ROOT/.tmp/scripts"; exit 1; }
WD=$(mktemp -d "$ROOT/.tmp/scripts/$NAME.XXXXXX") || { echo "$NAME: FAIL — mktemp"; exit 1; }
trap 'rm -rf "$WD"' EXIT
export NO_COLOR=1 TERM=dumb
# the libc transport: the pinned Core text dump + the twelve metadata TUs (libc_prep.sh, fail-closed on pin drift)
libc_jsons=$("$ROOT/scripts/libc_prep.sh" --jsons "$WD/libcjson") || { echo "$NAME: FAIL — libc_prep.sh --jsons failed (pin drift or oracle missing)"; exit 1; }
mapfile -t LIBC_JSONS <<< "$libc_jsons"
[[ ${#LIBC_JSONS[@]} -eq 12 ]] || { echo "$NAME: FAIL — expected 12 libc metadata jsons, got ${#LIBC_JSONS[@]}"; exit 1; }
LIBC_ARGS=(--libc "$ROOT/tests/libc/libc.core"); for j in "${LIBC_JSONS[@]}"; do LIBC_ARGS+=(--libc-tu "$j"); done

fails=0; n=0; nmoved=0; ngcc=0; nfork=0; ngap=0; nnolibc=0
# the total and the four class counts are PINNED (review P3-3): a dropped row cannot pass silently
WANT_N=46; WANT_GCC=34; WANT_FORK=6; WANT_GAP=1; WANT_NOLIBC=5
fail() { echo "$NAME: FAIL — $*"; fails=$((fails + 1)); }
pinned() { awk -F'\t' -v n="$1" '$1==n{print substr($0, length(n)+2)}' "$2"; }
verdict_line() { grep -aE '^(Defined|Undefined|Error|Killed) ' | head -1; }
project() { sed -E 's/Symbol\([0-9]+, /Symbol(_, /g'; }
selected() { [[ -z "$ONLY" ]] || [[ " $ONLY " == *" $1 "* ]]; }
declared_fork_pinned() { [[ " $FORK_PINNED " == *" $1 "* ]]; }

classify_pin() {  # <name> <pin>: the pin must be gcc's line or the row must be declared fork-pinned; counts
    local name="$1" want="$2" g; g=$(pinned "$name" "$GCC_LINES")
    if [[ "$want" == "$g" ]]; then
        declared_fork_pinned "$name" && fail "$name: declared FORK-PINNED but its pin equals gcc's line (retire the declaration)"
        ngcc=$((ngcc + 1))
    else
        declared_fork_pinned "$name" || fail "$name: pinned to a line that is not gcc's (gcc.txt) and not declared FORK-PINNED"
        nfork=$((nfork + 1))
    fi
}
witness() {  # <name>: libc mode on both engines; both batch lines = the pin; exit codes agree
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    [[ -f "$c" ]] || { fail "$name: program missing: $c"; return; }
    n=$((n + 1)); classify_pin "$name" "$want"
    if [[ -f "$PRISTINE" && "$(pinned "$name" "$PRISTINE")" != "$want" ]]; then nmoved=$((nmoved + 1)); fi
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 0 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 0 [${want:0:200}]; got rc=$orc [${o:0:200}] $(head -c 200 "$j.oerr")"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "${LIBC_ARGS[@]}" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line)
    [[ "$l" == "$want" ]] || fail "$name: Lean: expected [${want:0:200}]; got rc=$lrc [${l:0:200}] $(head -c 200 "$j.lerr")"
    [[ $lrc -eq $orc ]] || fail "$name: exit codes differ: oracle $orc, Lean $lrc"
}
gap_control() {  # <name>: the oracle answers the pinned line; the Lean engine refuses fopen (contract D2)
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want oout orc o lout lrc
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    n=$((n + 1)); ngap=$((ngap + 1))
    oout=$("$ORACLE" --runtime="$PREFIX" --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line)
    [[ $orc -eq 0 && "$o" == "$want" ]] || fail "$name: oracle: expected rc 0 [$want]; got rc=$orc [${o:0:200}]"
    if ! "$ORACLE" --runtime="$PREFIX" --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "${LIBC_ARGS[@]}" "$j" 2>&1); lrc=$?
    [[ $lrc -eq 134 && "$lout" == *"$GAP_LEAN_TEXT"* ]] || fail "$name: Lean: expected the D2 refusal (rc 134, $GAP_LEAN_TEXT); got rc=$lrc ${lout:0:300}"
}
nolibc_control() {  # <name>: --nolibc on both engines; the projected lines = the pin; exit codes equal (0 for a Defined pin, 1 otherwise)
    local name="$1" c="$CASES/$1.c" j="$WD/$1.json" want wrc oout orc o lout lrc l
    selected "$name" || return
    want=$(pinned "$name" "$EXPECT")
    [[ -n "$want" ]] || { fail "$name: no pinned expectation in $EXPECT"; return; }
    n=$((n + 1)); nnolibc=$((nnolibc + 1))
    if [[ "$want" == Defined* ]]; then wrc=0; else wrc=1; fi
    oout=$("$ORACLE" --runtime="$PREFIX" --nolibc --exec --batch "$c" 2> "$j.oerr"); orc=$?
    o=$(printf '%s\n' "$oout" | verdict_line | project)
    [[ $orc -eq $wrc && "$o" == "$want" ]] || fail "$name: oracle (--nolibc): expected rc $wrc [$want]; got rc=$orc [${o:0:200}]"
    if ! "$ORACLE" --runtime="$PREFIX" --nolibc --cabs-json "$c" > "$j" 2> "$j.err" || [[ ! -s "$j" ]]; then
        fail "$name: oracle --cabs-json failed: $(head -c 300 "$j.err")"; return
    fi
    lout=$(env LEAN_ABORT_ON_PANIC=1 "$BIN" --batch --first --runtime="$PREFIX" "$j" 2> "$j.lerr"); lrc=$?
    l=$(printf '%s\n' "$lout" | verdict_line | project)
    [[ $lrc -eq $wrc && "$l" == "$want" ]] || fail "$name: Lean (nolibc): expected rc $wrc [$want]; got rc=$lrc [${l:0:200}]"
}

while IFS=$'\t' read -r name _; do
    [[ -n "$name" && "$name" != \#* ]] || continue
    case "$name" in
        gap_*)    gap_control "$name" ;;
        nolibc_*) nolibc_control "$name" ;;
        *)        witness "$name" ;;
    esac
done < "$EXPECT"
for name in $FORK_PINNED; do grep -q "^$name	" "$EXPECT" || fail "$name: declared FORK-PINNED but absent from $EXPECT"; done
if [[ -z "$ONLY" ]]; then  # the whole set: the pinned totals (a subset run is a plant or a focused check, not the gate)
    [[ $n -eq $WANT_N && $ngcc -eq $WANT_GCC && $nfork -eq $WANT_FORK && $ngap -eq $WANT_GAP && $nnolibc -eq $WANT_NOLIBC ]] \
        || fail "the witness set is not the pinned set: $n programs ($ngcc gcc-pinned, $nfork fork-pinned, $ngap gap, $nnolibc nolibc); expected $WANT_N ($WANT_GCC/$WANT_FORK/$WANT_GAP/$WANT_NOLIBC)"
fi

[[ $fails -eq 0 ]] || { echo "$NAME: $fails failing check(s) over $n programs"; exit 1; }
echo "$NAME: OK ($n programs in libc mode: $ngcc batch lines of both engines = gcc 13's pinned line, exit codes equal — the flush-at-termination rows (puts/fputs/fwrite/putchar twice and in a loop, an unterminated last write, fflush mid-way, setvbuf full/line/none, exit() and the } of main), the ordered-stream rows (fputs then printf/fprintf/vprintf, (printf)(...) and a call through &printf, every FILE writer before a printf, printf's return value, stderr, write(2)), the atexit rows (on return, in a callee, three in reverse, a handler that writes, a handler that calls exit = the shipped library's text, exit from a nested call) and the exit() control; $nfork pinned to the fork's declared lines with gcc's beside them in gcc.txt (the status beyond 0..255, _Exit/quick_exit/abort after buffered output); $ngap gap control (fopen refused on the Lean engine, contract D2); $nnolibc nolibc controls (the two tray reproducers on upstream's path; a program-defined exit of the library's shape routed and refused when it returns, two other shapes not routed; both engines); $nmoved rows moved from pristine c3ff8c53f's lines)"
