#!/bin/bash
# test_kill_plant.sh — plant test for the per-test memory cap and its KILL
# classification (mem-scale S2, 2026-09-02; charter §6.4, Q2 [USER
# 2026-09-02]). Vacuity must be loud: the Lean driver is replaced by a stub
# (common.sh plant hook CERB_LEAN_BIN_OVERRIDE — banner on every use) that
# allocates 5 GiB of resident memory, so under the 4G per-test cgroup cap
# the kernel SIGKILLs it (exit 137, capped's KILLED banner). Each harness
# that carries the cap must then read its own KILL class — never MATCH,
# never a skip. Assertions are on the harnesses' own output.
#   test_ci_sweep.sh      -> row LEAN_KILL
#   test_libc_exec.sh     -> status KILL, nonzero exit
#   test_immaculate.sh    -> KILL statuses, nonzero exit
#   test_libxml2_uri.sh   -> "killed by SIGKILL (exit 137" lane FAIL
#   test_libxml2.sh       -> "[<slice>] FAIL: Lean KILLED" (one slice)
#   test_gcc_oracle.sh    -> SKIP_LEAN_KILL (its Lean run is not capped —
#                            the stub there kills itself with SIGKILL)
# The oracle-side KILL paths mirror the Lean ones textually; they are not
# plantable without replacing the oracle binary and are not asserted here.
# Nothing here touches the semantics.
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
[[ $rc -eq 137 ]] && grep -q "capped: KILLED" "$WORK/direct.err" \
    && echo "PLANT OK   [cap kills a 5 GiB allocator]: exit $rc, capped KILLED banner present" \
    || { echo "PLANT FAIL [cap kills a 5 GiB allocator]: exit $rc; stderr: $(tail -2 "$WORK/direct.err")" >&2; fail=1; }

export SKIP_BUILD=1
# --- test_ci_sweep.sh -> LEAN_KILL --------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_ci_sweep.sh" --suite ci --max 1 --out "$WORK/sweep" > "$WORK/sweep.log" 2>&1
cat "$WORK/sweep/ci.tsv" >> "$WORK/sweep.log" 2>/dev/null
check "ci_sweep -> LEAN_KILL" $'^ci\ttests/ci/0001-emptymain.c\tLEAN_KILL\texit 137, capped KILLED banner' "$WORK/sweep.log"

# --- test_libc_exec.sh -> KILL ------------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libc_exec.sh" > "$WORK/libc.log" 2>&1; rc=$?
expect_nonzero "libc_exec" $rc
check "libc_exec -> KILL row" '^  KILL  [0-9a-z_-]+: oracle exit 0, lean exit 137 — lean: KILLED \(exit 137; capped KILLED banner present' "$WORK/libc.log"
check "libc_exec no MATCH" '^SUMMARY: match=0 ' "$WORK/libc.log"

# --- test_immaculate.sh -> KILL -----------------------------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_immaculate.sh" > "$WORK/imm.log" 2>&1; rc=$?
expect_nonzero "immaculate" $rc
check "immaculate -> KILL status" '^  KILL ' "$WORK/imm.log"
if grep -qE '^  MATCH ' "$WORK/imm.log"; then echo "PLANT FAIL [immaculate]: a killed Lean run read as MATCH" >&2; fail=1; else echo "PLANT OK   [immaculate no MATCH]"; fi

# --- test_libxml2_uri.sh -> lane FAIL with the 137 label ----------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libxml2_uri.sh" > "$WORK/uri.log" 2>&1; rc=$?
expect_nonzero "libxml2_uri" $rc
check "libxml2_uri -> killed label" 'LEAN_NOLIBC killed by SIGKILL \(exit 137 — the per-test cgroup memory cap' "$WORK/uri.log"

# --- test_libxml2.sh (one slice) -> FAIL: Lean KILLED -------------------
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_alloc" "$SCRIPT_DIR/test_libxml2.sh" chvalid_battery_00 > "$WORK/xml.log" 2>&1; rc=$?
expect_nonzero "libxml2" $rc
check "libxml2 -> Lean KILLED" '^\[chvalid_battery_00\] FAIL: Lean KILLED \(exit 137; capped KILLED banner present' "$WORK/xml.log"

# --- test_gcc_oracle.sh -> SKIP_LEAN_KILL (Lean run uncapped: SIGKILL stub)
CERB_LEAN_BIN_OVERRIDE="$WORK/stub_sigkill" "$SCRIPT_DIR/test_gcc_oracle.sh" --max 1 > "$WORK/gcc.log" 2>&1
check "gcc_oracle -> SKIP_LEAN_KILL" 'SKIP_LEAN_KILL' "$WORK/gcc.log"

if [[ $fail -ne 0 ]]; then echo "test_kill_plant: FAILED"; exit 1; fi
echo "test_kill_plant: all plants read as expected (cap kills; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed, gcc SKIP_LEAN_KILL; no MATCH anywhere)"
