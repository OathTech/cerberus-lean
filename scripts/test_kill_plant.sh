#!/bin/bash
# test_kill_plant.sh — plant test for the per-test memory cap and its KILL
# classification (mem-scale S2, 2026-09-02; charter §6.4, Q2 [USER
# 2026-09-02]). Vacuity must be loud: the Lean driver is replaced by a stub
# (common.sh plant hook CERB_LEAN_BIN_OVERRIDE — banner on every use) that
# allocates 5 GiB of resident memory, so under the 4G per-test cgroup cap
# the kernel SIGKILLs it (exit 137 + capped's OOM-KILLED witness banner, the
# cgroup's memory.events oom_kill counter). Each harness
# that carries the cap must then read its own KILL class — never MATCH,
# never a skip. Assertions are on the harnesses' own output.
#   test_ci_sweep.sh      -> row LEAN_KILL
#   test_libc_exec.sh     -> status KILL, nonzero exit
#   test_immaculate.sh    -> KILL statuses, nonzero exit
#   test_libxml2_uri.sh   -> "killed by SIGKILL (exit 137" lane FAIL
#   test_libxml2.sh       -> "[<slice>] FAIL: Lean KILLED" (one slice)
#   test_gcc_oracle.sh    -> a native run's own exit(137) must still flow
#                            to comparison (never SKIP_GCC_KILL)
# NEGATIVE leg: a stub that SIGKILLs itself (exit 137, NO cgroup OOM event)
# must NOT read as the cap class — ci_sweep LEAN_CRASH "signal exit 137",
# libc_exec DIFF — because capped's OOM-KILLED witness (memory.events
# oom_kill) is what the KILL classes key on, not the bare exit status.
# The oracle-side KILL paths mirror the Lean ones textually; they are not
# plantable without replacing the oracle binary and are not asserted here.
# Nothing here touches the semantics.
# Also plants capped itself (audit m1/m2): an UNREADABLE witness must not be
# reported as "not a cap breach", and a grandchild's OOM kill is bannered
# even when the direct child exits with another status.
# Usage: ./scripts/test_kill_plant.sh   (needs env: scripts/ce; ~5 min)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
command -v python3 >/dev/null || { echo "Error: python3 needed for the allocating stub" >&2; exit 1; }

WORK=$(mktemp -d "$TMP_DIR/kill-plant.XXXXXXXXXX") || { echo "Error: mktemp failed" >&2; exit 1; }
register_cleanup "$WORK"
# 5 GiB resident under a 4 GiB cap: the kernel kills it inside the cgroup.
cat > "$WORK/stub_alloc" <<'EOS'
#!/bin/sh
exec python3 -c 'b = bytearray(5 * 1024 ** 3); print(len(b))'
EOS
cat > "$WORK/stub_sigkill" <<'EOS'
#!/bin/sh
kill -KILL $$
EOS
chmod +x "$WORK/stub_alloc" "$WORK/stub_sigkill"

fail=0
check() {   # <label> <expected-regex> <logfile>
    if grep -qE "$2" "$3"; then echo "PLANT OK   [$1]: $(grep -m1 -E "$2" "$3" | cut -c1-200)"
    else echo "PLANT FAIL [$1]: expected /$2/; got:" >&2; grep -E 'KILL|137|MATCH|FAIL|Error' "$3" | head -8 >&2; fail=1; fi
}
expect_nonzero() { [[ "$2" -ne 0 ]] || { echo "PLANT FAIL [$1]: lane exited 0 on a killed Lean run (must be fatal)" >&2; fail=1; }; }

# first: the cap really kills the stub (no harness in between)
"${CAPPED_TEST[@]}" "$WORK/stub_alloc" > "$WORK/direct.out" 2> "$WORK/direct.err"; rc=$?
[[ $rc -eq 137 ]] && grep -q "capped: OOM-KILLED" "$WORK/direct.err" \
    && echo "PLANT OK   [cap kills a 5 GiB allocator]: exit $rc, $(grep -o 'capped: OOM-KILLED[^;]*; memory.events oom_kill=[0-9]*' "$WORK/direct.err")" \
    || { echo "PLANT FAIL [cap kills a 5 GiB allocator]: exit $rc; stderr: $(tail -2 "$WORK/direct.err")" >&2; fail=1; }

# capped's two honesty paths (audit m1/m2):
# (a) witness UNAVAILABLE — a scratch copy of capped whose memory.events
#     path is bogus must NOT assert "not a cap breach" on a SIGKILL
sed 's|"$CAPPED_CG/memory.events"|"$CAPPED_CG/memory.events.DOES_NOT_EXIST"|' "$CAPPED_BIN" > "$WORK/capped_nowitness"
chmod +x "$WORK/capped_nowitness"
grep -q 'memory.events.DOES_NOT_EXIST' "$WORK/capped_nowitness" || { echo "PLANT FAIL [capped witness-unavailable]: scratch copy did not take the bogus path" >&2; fail=1; }
CERB_MEM_MAX=1G "$WORK/capped_nowitness" sh -c 'kill -KILL $$' > /dev/null 2> "$WORK/nowit.err"; rc=$?
[[ $rc -eq 137 ]] && grep -q "capped: KILLED, OOM witness UNAVAILABLE" "$WORK/nowit.err" \
    && echo "PLANT OK   [capped witness unavailable -> honest banner]: $(grep -o 'capped: KILLED, OOM witness UNAVAILABLE[^;]*' "$WORK/nowit.err")" \
    || { echo "PLANT FAIL [capped witness unavailable]: exit $rc; stderr: $(grep capped: "$WORK/nowit.err")" >&2; fail=1; }
# (b) grandchild OOM — the direct child exits 1 after its own child was
#     OOM-killed: the cgroup still records the event and capped says so
CERB_MEM_MAX=1G "$CAPPED_BIN" sh -c 'python3 -c "b = bytearray(2 * 1024 ** 3)"; exit 1' > /dev/null 2> "$WORK/grand.err"; rc=$?
[[ $rc -eq 1 ]] && grep -q "capped: OOM event recorded in cgroup (memory.events oom_kill=[1-9][0-9]*.*though the command exited rc=1" "$WORK/grand.err" \
    && echo "PLANT OK   [capped grandchild OOM -> bannered despite rc=1]: $(grep -o 'capped: OOM event recorded[^—]*' "$WORK/grand.err" | cut -c1-120)" \
    || { echo "PLANT FAIL [capped grandchild OOM]: exit $rc; stderr: $(grep capped: "$WORK/grand.err")" >&2; fail=1; }

export SKIP_BUILD=1
# --- test_ci_sweep.sh -> LEAN_KILL --------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep" > "$WORK/sweep.log" 2>&1
cat "$WORK/sweep/ci.tsv" >> "$WORK/sweep.log" 2>/dev/null
check "ci_sweep -> LEAN_KILL" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_KILL\texit 137, capped OOM-KILLED' "$WORK/sweep.log"
# negative: SIGKILL stub -> LEAN_CRASH, not LEAN_KILL
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_sigkill" "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep2" > "$WORK/sweep2.log" 2>&1
cat "$WORK/sweep2/ci.tsv" >> "$WORK/sweep2.log" 2>/dev/null
check "ci_sweep SIGKILL stub -> LEAN_CRASH (not the cap class)" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_CRASH\texit 137' "$WORK/sweep2.log"

# --- test_libc_exec.sh -> KILL ------------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libc_exec.sh" > "$WORK/libc.log" 2>&1; rc=$?
expect_nonzero "libc_exec" $rc
check "libc_exec -> KILL row" '^  KILL  [0-9a-z_-]+: oracle exit 0, lean exit 137 — lean: OOM-KILLED \(exit 137; cgroup memory cap' "$WORK/libc.log"
check "libc_exec no MATCH" '^SUMMARY: match=0 ' "$WORK/libc.log"
# negative: SIGKILL stub -> DIFF rows, no KILL
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_sigkill" "$SCRIPT_DIR/test_libc_exec.sh" > "$WORK/libc2.log" 2>&1; rc=$?
expect_nonzero "libc_exec/sigkill" $rc
if grep -qE '^  KILL ' "$WORK/libc2.log"; then echo "PLANT FAIL [libc_exec SIGKILL stub]: bare exit 137 read as the cap class" >&2; fail=1; else check "libc_exec SIGKILL stub -> DIFF (not KILL)" '^SUMMARY: match=0 diff=' "$WORK/libc2.log"; fi

# --- test_immaculate.sh -> KILL -----------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_immaculate.sh" > "$WORK/imm.log" 2>&1; rc=$?
expect_nonzero "immaculate" $rc
# a REAL C row must carry L[KILL] (illtyped-store is KILL by design and
# must not be the only KILL — that was a vacuous pass once)
check "immaculate -> KILL status on a C row" '^  KILL +g1-ge-funptr .*L\[KILL\]' "$WORK/imm.log"
if grep -qE '^  MATCH ' "$WORK/imm.log"; then echo "PLANT FAIL [immaculate]: a killed Lean run read as MATCH" >&2; fail=1; else echo "PLANT OK   [immaculate no MATCH]"; fi

# --- test_libxml2_uri.sh -> lane FAIL with the 137 label ----------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libxml2_uri.sh" > "$WORK/uri.log" 2>&1; rc=$?
expect_nonzero "libxml2_uri" $rc
check "libxml2_uri -> killed label" 'LEAN_NOLIBC killed by SIGKILL \(exit 137 — the per-test cgroup memory cap' "$WORK/uri.log"

# --- test_libxml2.sh (one slice) -> FAIL: Lean KILLED -------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libxml2.sh" chvalid_battery_00 > "$WORK/xml.log" 2>&1; rc=$?
expect_nonzero "libxml2" $rc
check "libxml2 -> Lean OOM-KILLED" '^\[chvalid_battery_00\] FAIL: Lean OOM-KILLED \(exit 137; cgroup memory cap' "$WORK/xml.log"

# --- test_gcc_oracle.sh: a native program's OWN exit(137) still compares -
# (the ledger has four such csmith rows; `--max 1` on a one-file dir with a
# program that exits 137 — the Lean side is the real driver here)
mkdir -p "$WORK/gcc137"; printf 'int main(void) { return 137; }\n' > "$WORK/gcc137/exit137.c"
"$SCRIPT_DIR/test_gcc_oracle.sh" "$WORK/gcc137" > "$WORK/gcc.log" 2>&1
check "gcc_oracle exit(137) native -> compared (AGREE gcc=137 lean={137}), not SKIP_GCC_KILL" 'AGREE +\S*exit137\.c: gcc=137 lean=\{137\}' "$WORK/gcc.log"
if grep -q SKIP_GCC_KILL "$WORK/gcc.log"; then echo "PLANT FAIL [gcc_oracle]: exit(137) read as a cap kill" >&2; fail=1; fi

if [[ $fail -ne 0 ]]; then echo "test_kill_plant: FAILED"; exit 1; fi
echo "test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)"
