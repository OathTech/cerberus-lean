# MEMORY-SCALE arc — implementation record (class-0 slices S0 / S1 / S1' / S2)

Date: 2026-09-02. Branch `arc/mem-scale`, rebased onto mainline
`ddcfc9199` (from `bbdbacaff`; no conflicts). Author: implementation
worker. Governing document: `2026-09-01_mem-scale-design.md` (charter
v0-R1.1, RULED); measurements: `2026-09-01_mem-scale-profile.md`. This
record is written per slice as each closes (kill-loss containment);
every quoted output is verbatim, derived tallies are labelled derived.

Hard invariants held throughout (charter §1, §6.5): the reference
memory model's observable behaviour does not change; no fuel / stack /
`maxRecDepth` / heartbeat bump anywhere; no `native_decide` /
`bv_decide` / `ofReduce*`; every algorithmic shape divergence from the
OCaml is documented in-code with the cite.

Pre-fix driver binaries (the S1' plant reference), sha256 prefixes at
the start of the arc (tree `e7f91cf78`, stamps fresh per
`tools/check_driver_fresh.sh`): oracle `c93bbfebd196f782`, Lean
`91c805fb050f76be`.

## S0 — loudness (HANG classification) — DONE

### What changed

- `scripts/common.sh`: `TIME_BIN=/usr/bin/time`, `require_time_bin`
  (fail-closed), `time_record_cpu_wall`, `classify_exit124` — exit 124
  with (User+System)/wall < 0.1 → `HANG(cpu Xs of Ys wall; timeout
  Ns)`, else `TIMEOUT(cpu … ; timeout Ns)`; an unreadable time record
  is a HARNESS ERROR (rc 1), never a TIMEOUT. Plant hook
  `CERB_LEAN_BIN_OVERRIDE` (loud banner on every use; the SKIP_BUILD
  Lean freshness check is skipped LOUDLY under it).
- `scripts/test_exec.sh`: both driver runs wrapped in `$TIME_BIN -v -o
  <record> timeout …` (GNU time propagates exit status unchanged —
  verified 139/134/124/70); new status `HANG` (rank 0, fatal in default
  mode, fatal on a new file, never `UNSUPPORTED`-absorbed); `hang=` in
  the SUMMARY line; the oracle-side exit 124 stays `CERB_SKIP` with the
  CPU/wall ratio printed in the skip line.
- `scripts/test_ci_sweep.sh`: `LEAN_HANG` / `CERB_HANG` rows (the
  sweep already subdivides oracle failures), same wrapper.
- `scripts/test_hang_plant.sh` (new): drives both lanes with a sleeping
  stub and a busy-looping stub, asserts the readings, and asserts the
  classifier's fail-closed path.
- `lean_frontend/docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`
  (new; INDEX pointer added): the Lean runtime report draft.
- `lean_frontend/TODO.md` KNOWN HANG item (c) marked done.

### Plant evidence (verbatim, `scripts/test_hang_plant.sh`, 2026-09-02)

```
PLANT OK   [exec/sleep → HANG]: [1/1] HANG 001-return-literal (Lean HANG(cpu 0.00s of 3.00s wall; timeout 3s))
PLANT OK   [exec/sleep summary]: FAILED: 1 Lean HANG(s) — exit 124 with CPU/wall < 0.1: no output, no exit (charter C9 shape)
PLANT OK   [exec/busy → TIMEOUT]: [1/1] TIMEOUT 001-return-literal (Lean TIMEOUT(cpu 3.00s of 3.00s wall; timeout 3s))
PLANT OK   [exec/busy summary]: FAILED: 1 Lean timeout(s)
PLANT OK   [sweep/sleep → LEAN_HANG]: ci	tests/ci/0001-emptymain.c	LEAN_HANG	HANG(cpu 0.00s of 3.00s wall; timeout 3s)
PLANT OK   [sweep/busy → LEAN_TIMEOUT]: ci	tests/ci/0001-emptymain.c	LEAN_TIMEOUT	TIMEOUT(cpu 2.99s of 3.00s wall; timeout 3s)
PLANT OK   [classifier fail-closed]: HARNESS ERROR: time record /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/mem-scale/.tmp/scripts/hang-plant.sKJ0b5Kl9Z/does-not-exist.time missing
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
```

### The real input (S0 gate) — verbatim, `SKIP_BUILD=1 TIMEOUT_SECS=400 CERB_MEM_MAX=32G scripts/capped scripts/test_exec.sh tests/mem-scale-probes/probes/a_zero_global_10000000.c`, pre-fix Lean binary `91c805fb050f76be`

```
[1/1] HANG a_zero_global_10000000 (Lean HANG(cpu 3.29s of 400.12s wall; timeout 400s))
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=1 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
FAILED: 1 Lean HANG(s) — exit 124 with CPU/wall < 0.1: no output, no exit (charter C9 shape)
FAILED: zero comparisons happened (all files skipped) — vacuous run
```

(The oracle completed the 10 M input inside the 400 s budget first —
the file reached the Lean side.) This row doubles as the S1' plant's
pre-fix reference.

### Do any committed rows change class? Verified, not assumed — NONE

- `scripts/exec_csmith_corpus_baseline.txt` carries 8 `TIMEOUT` rows;
  re-materialised (the lane's shim) and re-run through test_exec.sh at
  the lane's `TIMEOUT_SECS=15`, verbatim:

```
[1/8] TIMEOUT sa_csmith_197 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[2/8] TIMEOUT sa_csmith_419 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[3/8] TIMEOUT sa_csmith_435 (Lean TIMEOUT(cpu 14.97s of 15.01s wall; timeout 15s))
[4/8] TIMEOUT sia_csmith_072 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[5/8] TIMEOUT sia_csmith_161 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[6/8] TIMEOUT sia_csmith_169 (Lean TIMEOUT(cpu 15.01s of 15.02s wall; timeout 15s))
[7/8] TIMEOUT sia_csmith_976 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
[8/8] TIMEOUT sia_csmith_996 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
```

  All CPU-bound (ratio ≈ 1.0): the class is unchanged, no baseline
  commit needed. No other exec baseline carries a TIMEOUT row.
- `tests/ci_sweep/results/*.tsv` (Tier-C reporting artifact, not a
  gate) carries 3 `LEAN_TIMEOUT` rows (libc mode). Re-measured with
  the sweep's exact command under `/usr/bin/time -v` at 15 s and 60 s
  (verbatim, derived columns = the raw time -v fields):

```
40_stdio timeout=15s rc=134 user=1.37 sys=0.03 wall=0:02.47
40_stdio timeout=60s rc=134 user=1.34 sys=0.04 wall=0:02.45
pr69320-4 timeout=15s rc=124 user=14.88 sys=0.11 wall=0:15.00
pr69320-4 timeout=60s rc=0 user=31.88 sys=0.13 wall=0:32.02
pr20621-1 timeout=15s rc=124 user=14.79 sys=0.23 wall=0:15.02
pr20621-1 timeout=60s rc=134 user=21.76 sys=0.31 wall=0:23.14
```

  None is HANG-shaped (CPU ≈ wall on every 124). OBSERVATION, not
  caused by S0 and not acted on here: `tests/tcc/40_stdio.c` now exits
  134 in 2.5 s on the current binary where the committed sweep row says
  `LEAN_TIMEOUT` — the committed sweep TSV predates the current driver
  (a Tier-C artifact re-record is a separate deliberate instrument run;
  registered for the orchestrator). No CERB_TIMEOUT row was
  re-measured (the oracle fails loudly on its own ceiling; its class is
  unchanged by construction — `CERB_TIMEOUT` rows stay `CERB_TIMEOUT`
  unless CPU-idle, which this instrument would now reveal on the next
  sweep).

### Tier-A exec rows under the new classifier (verbatim SUMMARY + verdict)

```
=== minimal: test_exec.sh --check-baseline
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== coverage
SUMMARY: total=199 match=174 ub_match=12 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== debug
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== float
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### The Lean upstream report — standalone reproducer: negative result

A standalone Lean 4.32.2 program with the same non-tail monadic `mapM`
shape overflows and aborts LOUDLY ("Stack overflow detected.
Aborting.", SIGABRT) at 10^7 elements; a variant allocating a large
`ByteArray` per element (malloc path) did not deadlock in 3 trials at
each of three sizes. So the deadlock requires the fault to land while
a lock is held, which our driver does deterministically and the toy
does not; the draft carries the in-project reproducer and the negative
result. [AGENT] slip, recorded: those six variant-B trials were run
WITHOUT `scripts/capped` (they page-faulted up to 94 GB RSS for 60 s
each on the shared box) — every later run in this arc is capped.

### Decisions in S0 (provenance)

- [AGENT] Oracle-side exit 124 in `test_exec.sh` keeps its `CERB_SKIP`
  class (adding an oracle-side status there would widen the baseline
  taxonomy for a class the oracle has never exhibited — it fails
  loudly on its own ceiling); the ratio is printed in the skip line so
  an oracle-side hang cannot pass unremarked. `test_ci_sweep.sh`, which
  already subdivides oracle failures, gets `CERB_HANG`.
- [AGENT] A HANG on an `*.unsupported.c` file is `HANG`, not
  `UNSUPPORTED`: no output + no exit is never "expected".
- [AGENT] The plant is driven through the real lanes via a loud
  `CERB_LEAN_BIN_OVERRIDE` hook rather than by unit-testing the
  classifier alone, so the lanes' status plumbing (record_status,
  SUMMARY, fatal exit) is what is asserted.

## S1 — C1 + C3 in place, kernel-checked equalities — DONE

### What changed (`lean_frontend/CerbMem.lean`; copied to `generated/` by the Makefile rule)

- C1: `reconstructValue_lemFuel`'s ARRAY arm is one linear
  consume-and-return-rest pass — `chunksOf elemSize n bytes` (new,
  `take e` :: recurse on `drop e`) mapped by the element reconstruction
  — instead of `bytes.drop (i*elemSize) |>.take elemSize` per index
  (Θ(n²·e)). In-code note cites `impl_mem.ml:987-993` (the OCaml `aux`'s
  consume-and-return-rest shape) and `impl_mem.ml:929-930` (the per-call
  `List.length` guard, DELIBERATELY NOT MIRRORED — documented divergence:
  that guard is the oracle's own quadratic mechanism, tray item). Every
  other arm's text is unchanged. The `INVARIANT` doc line is updated to
  say the array arm hands each element exactly its slice in one pass.
- C3: `memValueToBytes_lemFuel`'s STRUCT arm conses each member's chunk
  (`List.replicate pad paddingByte ++ bs`) onto a reversed chunk list and
  flattens once, instead of `accBs ++ pad ++ bs` inside the left fold
  (`impl_mem.ml:1207-1212`'s `acc @ … @ bs` shape — shared upstream
  shape; documented divergence in-code). Every other arm unchanged.
- Reference forms (NOT executed; they exist so the divergences are
  theorems, not claims — charter §1 carve-out [R1/F5], §7 mitigation):
  `reconstructValue_indexed_lemFuel` (the pre-C1 text verbatim, name and
  recursive calls renamed) and `memValueToBytes_append_lemFuel` (the
  pre-C3 text likewise).
- Theorems (all kernel-checked, no `sorry`, no `native_decide`/
  `bv_decide`/`ofReduce*`, no new axioms; cones below):
  - `CerbMem.chunksOf_eq_range_map : chunksOf e n l = (List.range n).map
    fun i => (l.drop (i*e)).take e` — induction on `n` generalising `l`;
    `List.range_succ_eq_map`, `List.drop_drop`, `Nat.succ_mul`.
  - `CerbMem.reconstructValue_lemFuel_eq_indexed : ∀ fuel …,
    reconstructValue_lemFuel fuel … = reconstructValue_indexed_lemFuel
    fuel …` — induction on fuel; `unfold` both, rewrite the recursive
    calls by the IH (`funext`), normalise `panic!` sites to `default`
    (`panicWithPosWithDecl` embeds the declaration name, so the two
    texts differ there; it is definitionally `default`), `cases` on the
    ctype (one extra `cases` on the basic type, where the outer match is
    otherwise stuck); the array arm is `chunksOf_eq_range_map` +
    `List.map_map`; every other arm `rfl`.
  - `CerbMem.reconstructValue_eq_indexed` — the `lemDefaultFuel` instance.
  - `CerbMem.foldl_append_eq_flatten_reverse{_aux}` — the list fact
    behind C3, stated over the struct arm's exact accumulator shape
    (`γ × Nat × List α`) for an arbitrary per-member `step`; induction
    on the list generalising the accumulator.
  - `CerbMem.memValueToBytes_lemFuel_eq_append : ∀ fuel …` — induction on
    fuel; struct arm by `List.append_assoc` (the reference arm is
    `(accBs ++ pad) ++ bs`, `++` being left-associative) then the fold
    lemma with `step` given in projection form; every other arm `rfl`.
  - `CerbMem.memValueToBytes_eq_append` — the `lemDefaultFuel` instance.
- `scripts/check_theorem_axioms.sh`: new "mem-scale S1 leg" probing the
  six theorems (exactly-one-line fail-closed; exact allowlist
  `[propext, Classical.choice, Quot.sound]`). Verbatim from
  `test_unit.sh` on the S1 tree:

```
'CerbMem.chunksOf_eq_range_map' depends on axioms: [propext, Quot.sound]
'CerbMem.reconstructValue_lemFuel_eq_indexed' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.reconstructValue_eq_indexed' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.foldl_append_eq_flatten_reverse' depends on axioms: [propext]
'CerbMem.memValueToBytes_lemFuel_eq_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memValueToBytes_eq_append' depends on axioms: [propext, Classical.choice, Quot.sound]
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
```

  (`foldl_append_eq_flatten_reverse_aux` is probed by hand with the same
  cone `[propext]`; the gate lists the six names the manifest names.)
- Consumer manifest: `2026-09-02_mem-scale-change-manifest.md` (every
  charter §5.4 site, re-verified against refined-cerberus @ `e9bcaef`;
  finds a PRE-EXISTING pin delta — the effect-retirement `ambient :
  TagDefs` parameter — that the consumer must absorb at its next pin
  bump regardless of S1).
- Consumer-shape probe (in this tree; refined-cerberus itself builds
  against its own pinned workspace and is not rebuildable against this
  worktree without doctoring its instrument): the exact tactic prefix
  of `TreeRotExhibit.lean:145-149` / `ListRevExhibit.lean:257-261` —
  `rw [show reconstructValue = reconstructValue_lemFuel lemDefaultFuel
  from rfl, show lemDefaultFuel = 999999 + 1 from rfl]; unfold
  CerbMem.reconstructValue_lemFuel <ptrTy> <ty>; dsimp only; rw [hb];
  rcases … splitBytesProv …; split …` — elaborates on a pointer-typed
  node against the S1 body, and the null round trip closes by `rfl`
  (probe file compiled with zero diagnostics under `lake env lean`).

### Exponents before → after (this box, Lean `--first`, `CERB_MEM_MAX=32G`, `tests/mem-scale-probes/measure.sh`; DERIVED exponent = log(wall ratio)/log(size ratio); absolute times environment-dependent, ratios/exponents robust — profile §3.0)

Pre-fix Lean binary `91c805fb050f76be`, post-fix `406960e92de44c2f`. Raw
rows verbatim (probe mode engine exit wall_s maxrss_kb verdict note cpu_s):

```
# before
c_struct_ret_16384	nolibc	lean-first	0	0.33	89668	VAL:Specified(7)	-	0.32
c_struct_ret_65536	nolibc	lean-first	0	4.26	149244	VAL:Specified(7)	-	4.26
c_struct_ret_262144	nolibc	lean-first	0	62.97	375464	VAL:Specified(7)	-	62.96
c_struct_arg_16384	nolibc	lean-first	0	0.37	90884	VAL:Specified(0)	-	0.37
c_struct_arg_65536	nolibc	lean-first	0	4.47	147252	VAL:Specified(0)	-	4.47
# after
c_struct_ret_16384	nolibc	lean-first	0	0.09	94004	VAL:Specified(7)	-	0.08
c_struct_ret_65536	nolibc	lean-first	0	0.28	153020	VAL:Specified(7)	-	0.28
c_struct_ret_262144	nolibc	lean-first	0	1.18	379004	VAL:Specified(7)	-	1.18
c_struct_arg_16384	nolibc	lean-first	0	0.08	94856	VAL:Specified(0)	-	0.08
c_struct_arg_65536	nolibc	lean-first	0	0.27	151228	VAL:Specified(0)	-	0.26
```

Verdicts identical before/after on every row (`Specified(7)` /
`Specified(0)`). Derived:

| probe pair | before wall s | before exponent | after wall s | after exponent |
|---|---|---|---|---|
| c_struct_ret_16384 → c_struct_ret_65536 | 0.33 → 4.26 | 1.85 | 0.09 → 0.28 | 0.82 |
| c_struct_ret_65536 → c_struct_ret_262144 | 4.26 → 62.97 | 1.94 | 0.28 → 1.18 | 1.04 |
| c_struct_arg_16384 → c_struct_arg_65536 | 0.37 → 4.47 | 1.80 | 0.08 → 0.27 | 0.88 |

Micro-benchmark (`tests/mem-scale-probes/micro`, rebuilt against the
post-fix library; in-process ms around the timed call; raw rows in
`results/2026-09-02_s1-micro-before-after.tsv`; the c_struct rows in `results/2026-09-02_s1-cstruct-before-after.tsv`):

| micro case | N → N' | before ms | before exponent | after ms | after exponent |
|---|---|---|---|---|---|
| reconstruct_chararray | 16384 → 65536 | 111 → 1829 | 2.02 | 2 → 6 | 0.79 |
| reconstruct_chararray | 65536 → 262144 | 1829 → 28097 | 1.97 | 6 → 32 | 1.21 |
| reconstruct_chararray | 262144 → 524288 | 28097 → 113235 | 2.01 | 32 → 70 | 1.13 |
| reconstruct_intarray | 16384 → 65536 | 29 → 454 | 1.98 | 1 → 4 | 1.00 |
| reconstruct_intarray | 65536 → 262144 | 454 → 6983 | 1.97 | 4 → 18 | 1.08 |
| copy_chararray | 16384 → 65536 | 114 → 1744 | 1.97 | 6 → 22 | 0.94 |
| copy_chararray | 65536 → 262144 | 1744 → 28582 | 2.02 | 22 → 119 | 1.22 |

After-only ladder, `reconstruct_chararray` (ms): 16384: 2, 65536: 6,
262144: 32, 524288: 70, 1048576: 138, 4194304: 550 — a 4 MB `char`
aggregate load reconstructs in 0.55 s (the charter's estimate for 1 MB
under the old shape was ~450 s). The c_struct_ret 64K→256K wall
collapse the charter named (5.85 s → 114 s in the profile's environment;
4.26 → 62.97 s here) is 0.28 → 1.18 s after.

C3 has no probe in the corpus (single-member structs); its evidence is
the equality theorem and the unmoved battery.

### S1 battery (verbatim per-lane summary; `SKIP_BUILD=1` on stamped binaries oracle `c93bbfebd196f782` / Lean `406960e92de44c2f`; Tier A + Tier B + gcc lane + csmith spot shards 1/6 and 4/6; columns: lane rc wall-s last-summary-lines)

```
unit                         rc=0      17s    OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce] test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class) 
exec_minimal                 rc=0      11s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
exec_coverage                rc=0      22s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
exec_debug                   rc=0       9s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
exec_float                   rc=0       7s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
bytes                        rc=0       9s  [NEG_OK] only_unsigned_char.c: Lean-side desugar/typing rejection at the committed diagnostic line 1 (rc 1) SUMMARY: exec_match=9 neg_pinned=5 fail=0 
libc_exec                    rc=0      14s  check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 9099c2a8cf348ee28dc1da206b3c4c9b62962ecf2b6bfcc442f22116ddde22a6) SUMMARY: match=7 diff=0 
multi_tu                     rc=0       1s  SUMMARY: total=2 match=2 fail=0 ALL PASSED 
parse_minimal                rc=0      11s  Lean parse:     106 ok, 0 failed ALL PASSED 
core_minimal                 rc=0       8s  Lean parse:     106 ok, 0 failed ALL PASSED 
elab                         rc=0      17s    LEAN_FAIL:  0 SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0 
libxml2_uri                  rc=0      11s  check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 9099c2a8cf348ee28dc1da206b3c4c9b62962ecf2b6bfcc442f22116ddde22a6) GATE PASS: all lane expectations pinned-green + bas
cn_coverage                  rc=0      39s  SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 BASELINE OK (213 
libxml2                      rc=0     705s  SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) ALL PASSED 
parse_ci                     rc=0      78s  Lean parse:     247 ok, 0 failed ALL PASSED 
core_ci                      rc=0      15s  Lean parse:     128 ok, 0 failed ALL PASSED 
verify                       rc=0      49s  check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 9099c2a8cf348ee28dc1da206b3c4c9b62962ecf2b6bfcc442f22116ddde22a6) test_verify: 117 passed, 0 failed (23 fixtures, 22 
immaculate                   rc=0      22s  check_driver_fresh: lean OK (bin 406960e92de44c2f42d1680095bc1527b4516854b59d9a79f327bdb869c234d7, src 9099c2a8cf348ee28dc1da206b3c4c9b62962ecf2b6bfcc442f22116ddde22a6) OK: lane matches the committed post-S1 baseline (mo
speclab_selftest             rc=0     167s  check_lem_sync: lean OK (src f4c0096697fb68c508acbe35423ed0fce77c6988ceafcaffe772924358e8a624, gen 6c2ae2041cceb0aed61cae04917144131fe96940e2aec6213d43b13b9d8fd5e7) test_speclab: PASS (both pipelines agree on Specified(0
speclab_plant                rc=0       0s  check_lem_sync: lean OK (src f4c0096697fb68c508acbe35423ed0fce77c6988ceafcaffe772924358e8a624, gen 6c2ae2041cceb0aed61cae04917144131fe96940e2aec6213d43b13b9d8fd5e7) test_speclab: PASS (both pipelines agree on Specified(2
speclab_divmod               rc=0       5s  CoreGateTest: ALL PASSED test_speclab_divmod: PASS (--gate) 
speclab_bytearr              rc=0       3s  ByteArrGateTest: ALL PASSED test_speclab_bytearr: PASS (--gate) 
speclab_list                 rc=0       3s  ListGateTest: ALL PASSED test_speclab_list: PASS (--gate) 
speclab_tree                 rc=0       4s  TreeGateTest: ALL PASSED test_speclab_tree: PASS (--gate) 
speclab_seed                 rc=0       2s  SeedGateTest: ALL PASSED test_speclab_seed: PASS (--gate) 
gcc_oracle                   rc=0    1082s  Baseline check: 0 regression(s), 0 improvement(s) gcc second-oracle lane OK 
csmith_1of6                  rc=0    2349s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
csmith_4of6                  rc=0     801s  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
```

Every lane rc 0; every baseline check `0 regression(s), 0 improvement(s)`; libxml2 `total=4 match=4`; cn_coverage `BASELINE OK (213`; gcc second-oracle lane `0 regression(s)` (1953 files). Byte-at-baseline.

## S1' — C9 at source (`.lem` accumulate-and-reverse) — STOP-AND-REPORT (completion gate fails at 10 M; passes at 8 M; cause located in the Lean runtime's closure application)

Status: work applied in the working tree, NOT committed (the slice's
gate is not green; charter §6.3 / brief: "If the Lean→C toolchain does
not realise the tail call and the gate fails: STOP-AND-REPORT — backend
fallback is a separate slice needing a ruling"). Snapshot of the
uncommitted tree: `.tmp/memscale/s1p/s1prime-worktree.patch` (ephemeral)
— files: `frontend/model/ail/errorMonad.lem`,
`frontend/model/state_exception.lem`, `frontend/model/undefined.lem`,
`scripts/fork_drift_manifest.txt`, `lean_frontend/docs/upstream-tray/
INDEX.md`, new `lean_frontend/docs/upstream-tray/18-monadic-list-
combinators-non-tail.md`.

### What was done

- `.lem` rewrites (each with an in-code semantics argument — action
  order, state threading, first-failure short-circuit and result list
  unchanged): `ailErr_mapM` → tail-position `ailErr_mapM_aux` +
  `List.reverse`; `state_exception.lem` `sequence` (:50) →
  `stExpect_sequence_aux`; `foldrM` (:79) → `stExcept_foldlM` over the
  reversed list (a right fold runs the last element first — preserved);
  `undefined.lem` `sequence` → `sequence_aux`. Lean-target-only
  `termination_argument = automatic` declares for the three new aux
  functions (all three render as total `def`s; `foldrM`'s declare removed
  since it is no longer recursive). Regenerated BOTH trees (`make
  prelude-src`, `make lean-prelude-src`; lem-sync stamps recorded);
  oracle rebuilt cache-disabled (`DUNE_CACHE=disabled dune build --force
  …` then `build_cerberus`), Lean driver rebuilt via `build_lean`.
  Post-S1' binaries: oracle `7cdafba40004e924`, Lean `16772ec9b0a9d8f5`.
- Generated-OCaml text changes in exactly 3 modules (errorMonad.ml,
  state_exception.ml, undefined.ml); fork-drift manifest hand-edited
  (2 new `[files]`, 3 new `[expected-semantic]` hashes, NOTE with the
  justification; `--refresh` was NOT taken wholesale — it strips the
  manifest's documented header and rewrites `[meta]`): gate verbatim
  `check_fork_drift: OK — layer 1: 74 oracle-surface files = manifest;
  layer 2: 25 differing generated files, all hash-pinned`.
- Tray draft 18 (upstream-facing; INDEX entry).

### Completion gate (`CERB_MEM_MAX=32G`, `measure.sh --nolibc --timeout 900`; verdict equality, never timing)

Pre-fix plant (S0 section, Lean `91c805fb050f76be`, verbatim):
`[1/1] HANG a_zero_global_10000000 (Lean HANG(cpu 3.29s of 400.12s wall; timeout 400s))`.

Post-fix rows, verbatim (probe mode engine exit wall_s maxrss_kb verdict note cpu_s):

```
a_zero_global_10000000	nolibc	oracle	0	75.84	7811460	VAL:Specified(7)	-	73.43
a_zero_global_8000000	nolibc	oracle	0	45.63	6284928	VAL:Specified(7)	-	45.62
a_zero_global_8000000	nolibc	lean-first	0	20.28	5651660	VAL:Specified(7)	-	20.27
a_zero_global_10000000	nolibc	lean-first	124	900.09	3087260	NONE	HANG(cpu 6.76s of 900.09s wall; timeout 900s);	6.76
```

- 8 M: COMPLETES on both engines with equal verdict (`VAL:Specified(7)`,
  exit 0) — pre-fix this input hung (profile §6.3 bisect row: exit 124).
  GATE MET for the 8 M variant.
- 10 M: oracle completes (`VAL:Specified(7)`; note the oracle is itself
  3× faster than pre-fix — 75.8 s vs 246 s — the OCaml `List.fold_right`
  / non-tail recursion was on its path too); Lean still HANGs. GATE NOT
  MET for the 10 M input. (The 8 M probe file is the bisect text
  `char g[8000000]; int main(void) { g[8000000 - 1] = 7; return
  g[8000000 - 1] + g[0]; }`, ephemeral in `.tmp/memscale/s1p/probes/`.)

### Where the residual recursion is (first-hand)

- Stage: human-mode stage markers on the 10 M input (verbatim last
  lines of stdout before the park: `desugaring succeeded! …
  typechecking AIL...`, then nothing; `/usr/bin/time`: User 3.49 s,
  System 0.52 s, wall 2:30.08, RSS 3089620 kB, exit 124). `--pp-core`
  alone: exit 124, 5.84 s + 0.89 s CPU of 400 s wall, RSS 3087316 kB.
  So it is still the Ail typing stage, whose only N-element traversal
  is `E.mapM (typecheck_constant loc) csts` (genTyping.lem:484) — the
  site that was rewritten.
- Per-element stack arithmetic (DERIVED; 1 GiB runtime-thread stack):
  pre-fix 7 M completes / 8 M hangs ⇒ 134 B < S_old < 153 B per element;
  post-fix 8 M completes / 10 M hangs ⇒ 107 B < S_new < 134 B. The
  rewrite removed only ~20–45 B per element: one small frame per
  element REMAINS.
- Our emitted C is tail-shaped: `objdump -d` of the driver, verbatim —
  `lp_CerberusLean_bind3___redArg___lam__0`: `c1b143: jmp 4dadef0
  <lean_apply_2>`; `lp_CerberusLean_ailErr__mapM__aux___redArg___lam__1`:
  `c1b81e: jmp 4dac4e0 <lean_apply_1>` (the C source: `return
  lean_apply_2(v_f_186_, v_fst_198_, v_snd_199_)` / `return
  lean_apply_1(...)`).
- The RUNTIME's closure application is NOT a tail call. Census of the
  `call`/`jmp` instructions inside `libleanshared.so` (Lean 4.32.2)
  `lean_apply_1` and `lean_apply_2`, verbatim (`objdump -d`, counted):

```
=== lean_apply_1: call/jmp instruction census
     22 call   *0x8(%rbx)
      2 jmp    *%rcx
      2 call <lean_dec_ref_cold@@Base>
      1 call <mi_heap_malloc_small@@Base+0x47600>
      1 call <mi_heap_malloc_small@@Base+0x47460>
      1 call <lean_free_object@@Base>
      1 call <lean_apply_m@@Base+0x3c0>
      1 call   *0x8(%rcx)
=== lean_apply_2: call/jmp instruction census
     19 call   *0x8(%rax)
      4 call <lean_dec_ref_cold@@Base>
      3 call   *0x8(%rbx)
      2 jmp    *%rdi
      1 call <_ZN4lean5curryEPvjPP11lean_object@@Base>
      1 call <lean_free_object@@Base>
      1 call <lean_apply_n@@Base>
      1 call <lean_apply_m@@Base+0x3c0>
```

  `*0x8(%rbx)` / `*0x8(%rax)` is the closure's function pointer
  (`lean_closure_object.m_fun`): on 22 of 24 arity paths in
  `lean_apply_1` (and 22 of 24 in `lean_apply_2`) the closure body is
  entered by CALL, with runtime work after it (the exclusive-closure
  paths free the closure / adjust counts after the callee returns), so
  each closure application through the runtime costs one `lean_apply_*`
  frame. A function-typed monad's run loop (`bind`'s continuation
  applied per element) therefore accumulates one runtime frame per
  element no matter how the `.lem` is shaped — the frame our tail-shaped
  C still pays. This is exactly the charter §6.0 fallback condition
  ("the tail call through the closure application in bind's run
  function is not, in practice, compiled as a tail call by the Lean → C
  → clang pipeline"), located one level lower than anticipated (in
  `lean_apply_*`, not in clang's treatment of our C).

### Behaviour preservation evidence on the S1' tree (partial; the full battery was NOT run — stop-and-report)

Tier-A smoke on the stamped S1' binaries (verbatim lane summaries):

```
unit           rc=0  check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound]) check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ th
exec_minimal   rc=0  Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK
libc_exec      rc=0  SUMMARY: match=7 diff=0
cn_coverage    rc=0  SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 BASELINE OK (213 entries, e
```

(`test_unit.sh` includes the lem-sync stamp gate on both re-derived
trees and the fork-drift gate with the hand-edited manifest.)

### Options for the ruling (not decided here)

1. Commit S1' as a PARTIAL slice ("ceiling moved 7–8 M → 8–10 M
   elements; behaviour preserved" — requires the full battery first)
   and open the backend/runtime fallback slice.
2. Revert S1' (drop the `.lem` changes) and go straight to the
   fallback design.
3. The fallback itself is a two-repo/runtime question: (a) a lem-backend
   rendering of monadic list combinators for function-typed monads as
   an explicit RUN LOOP (interpret the list in the `run` function
   directly, no per-element closure application), or (b) a Lean-runtime
   change making `lean_apply_*`'s exact-arity paths tail calls
   (upstream) — (b) would also close the fail-open handler class if
   combined with the lean4/01 report. Either is a new charter item with
   its own ruling; NOT a stack-size knob.

### Not started because of the stop

S2 (C2 harness migration + parity confirmation) and the close-out
battery were not started; the brief's "stop-and-report on the
completion gate failing" governs.

### Ruling and revert (appended after the stop)

[USER 2026-09-02], verbatim as relayed by the orchestrator: "yeah,
revert S1' I think - poor roi for a change to the trust surface".
Rationale as relayed: the rewrite touches three model `.lem` files
(oracle text moves in 3 generated modules) for an onset move from ~7 M
to ~9 M elements, with the actual ceiling in the Lean runtime; the
ceiling is now loud (S0) and registered (VALIDATION.md §5, TODO.md) and
the fallback (lem-backend run-loop rendering, Lean-emission-only) is
queued for a lem arc with its own ruling.

Revert executed: `git checkout` of `frontend/model/ail/errorMonad.lem`,
`frontend/model/state_exception.lem`, `frontend/model/undefined.lem`,
`scripts/fork_drift_manifest.txt`; both trees regenerated from the
reverted `.lem` (`make prelude-src` / `make lean-prelude-src`) — lem-sync
stamps back to the S1 values (verbatim: `check_lem_sync: recorded
lean_frontend/lem_sync.sha256 (src f4c0096697fb68c508acbe35423ed0fce77c6988ceafcaffe772924358e8a624,
gen 6c2ae2041cceb0aed61cae04917144131fe96940e2aec6213d43b13b9d8fd5e7)`,
identical to the S1 battery's `speclab_selftest` line); fork-drift gate
back to its pre-S1' shape (verbatim: `check_fork_drift: OK — layer 1:
72 oracle-surface files = manifest; layer 2: 22 differing generated
files, all hash-pinned`); `ailErr_mapM_aux` absent from both generated
trees (grep count 0/0); oracle rebuilt cache-disabled (`--force`) and
Lean driver rebuilt via `build_lean`, stamps re-recorded: Lean bin
`406960e92de44c2f` — BYTE-IDENTICAL to the S1 binary; oracle bin
`77de74dcb4872e03` with source-set hash `a54c0b1f…` identical to the
pre-S1' oracle stamp (the forced cache-disabled rebuild is not
bit-reproducible; the source hash is the identity). KEPT from S1': tray draft 18 + its INDEX entry
(upstream-facing; the OCaml side would also benefit — the oracle ran the
10 M input 3× faster under the rewrite).

Cap-rule reminder acknowledged [orchestrator]: every driver/lake/lean
invocation — ad-hoc reproducers included — goes through `scripts/capped`.

## S2 — C2 harness migration (Q2) + baselines + parity confirmation — DONE

Commits: harness migration `e02d4105a`; fix-up (OOM witness) `e866357c6`;
baseline instrument `de574fbc8`. Binaries throughout: oracle
`77de74dcb4872e03`, Lean `406960e92de44c2f` (the S1 binary, byte-identical).

### What changed

- `scripts/common.sh`: `CAPPED_TEST=(env CERB_MEM_MAX=$TEST_MEM_MAX
  scripts/capped)` with `CERB_TEST_MEM_MAX` (default 4G, cgroup RSS);
  `is_cap_kill <rc> <stderr-file>` (exit 137 AND capped's `OOM-KILLED`
  witness), `kill_label`.
- All 22 `ulimit -v 4000000` sites replaced: `test_ci_sweep.sh` (3),
  `test_libc_exec.sh` (3), `test_libxml2.sh` (4), `test_libxml2_uri.sh`
  (2), `test_immaculate.sh` (3), `test_gcc_oracle.sh` (2, the native
  runs — stderr now captured), `tests/parity-probes/run_probe.sh` (3).
  `grep ulimit` over the seven files now hits comments only.
- KILL classes (never agreement, never a skip): ci_sweep `LEAN_KILL` /
  `CERB_KILL` (distinct from `*_CRASH`); libc_exec `KILL`; immaculate
  token `KILL` (two KILLs never MATCH); libxml2 / uri `FAIL: … OOM-KILLED`;
  gcc_oracle `SKIP_GCC_KILL` (native breach); run_probe `OOM-KILLED` note.
- `scripts/capped` (fix-up): reads the cgroup's `memory.events oom_kill`
  before removing the cgroup and prints `capped: OOM-KILLED (… memory.events
  oom_kill=N …)` on a breach; any other 137/143 keeps a generic
  `KILLED (… NOT a cap breach …)` banner. Verified (verbatim):

```
capped: OOM-KILLED (exit 137 — cgroup memory cap CERB_MEM_MAX=1G breached; memory.events oom_kill=1; NOT a pass)
capped: KILLED (exit 137 — signal death, NOT a cap breach: no cgroup OOM event recorded (oom_kill=0); e.g. timeout -k SIGKILL or the program's own exit status; NOT a pass)
capped: KILLED (exit 137 — signal death, NOT a cap breach: no cgroup OOM event recorded (oom_kill=0); e.g. timeout -k SIGKILL or the program's own exit status; NOT a pass)
```

  (a 2 GiB allocator under 1G; `sh -c 'exit 137'`; `sh -c 'kill -KILL $$'`.)
- `scripts/LADDER.md` Conventions → MIGRATED; `VALIDATION.md` §2 gains
  the per-test resource-limits paragraph (HANG + KILL, both loud).

### Two findings during the slice (both fixed before any baseline moved)

1. Exit 137 is not a witness. The first re-derivation of the gcc lane
   read 4 rows `SKIP_GCC_KILL` where the ledger says `AGREE gcc=137
   lean={137}` — `sa_csmith_77`, `sia_csmith_1001`, `sia_csmith_345`,
   `sia_csmith_878` exit with THEIR OWN status 137 (checksum byte) in
   0.00 s at 2 MB RSS, and `capped` bannered every 137. Fixed at the
   source of truth (the kernel's `memory.events oom_kill` counter);
   the four rows AGREE again (gcc lane below: 0 regressions).
2. A vacuous plant pass. The first `test_kill_plant.sh` "immaculate →
   KILL" leg matched only the by-design `KILL` of the in-Lean
   `illtyped-store` probe: the LEAN-side `verdict` call did not receive
   its stderr file, so a killed Lean read as `CRASH` — and against the
   oracle-CRASH rows (`g4-bswap64-overflow`, `g5-decode-*`,
   `offsetof-union-member`, `g2-memcmp-uninit`, `s4b-memcmp-hugesize`)
   that read `MATCH`: exactly the laundering the plant exists for. The
   "no MATCH" leg caught it; fixed (`verdict … "$OUTPUT_DIR/$name.lerr"`),
   the plant now names a real C row.

### Plant evidence (verbatim, `scripts/test_kill_plant.sh`, final code)

```
PLANT OK   [cap kills a 5 GiB allocator]: exit 137, capped: OOM-KILLED (exit 137 — cgroup memory cap CERB_MEM_MAX=4G breached; memory.events oom_kill=1
PLANT OK   [ci_sweep -> LEAN_KILL]: ci	tests/ci/0001-emptymain.c	LEAN_KILL	exit 137, capped OOM-KILLED (memory cap 4G breached)
PLANT OK   [ci_sweep SIGKILL stub -> LEAN_CRASH (not the cap class)]: ci	tests/ci/0001-emptymain.c	LEAN_CRASH	exit 137: (no PANIC line captured)
PLANT OK   [libc_exec -> KILL row]:   KILL  001-exit: oracle exit 0, lean exit 137 — lean: OOM-KILLED (exit 137; cgroup memory cap CERB_TEST_MEM_MAX=4G breached — memory.events oom_kill=1)
PLANT OK   [libc_exec no MATCH]: SUMMARY: match=0 diff=7
PLANT OK   [libc_exec SIGKILL stub -> DIFF (not KILL)]: SUMMARY: match=0 diff=7
PLANT OK   [immaculate -> KILL status on a C row]:   KILL           g1-ge-funptr          O[ERR:Memory WIP: ge_ptrval] L[KILL]
PLANT OK   [immaculate no MATCH]
PLANT OK   [libxml2_uri -> killed label]: FAIL: LEAN_NOLIBC killed by SIGKILL (exit 137 — the per-test cgroup memory cap CERB_TEST_MEM_MAX=4G if the lane's stderr carries capped's OOM-KILLED witness banner, otherwise an external SIGKILL): c
PLANT OK   [libxml2 -> Lean OOM-KILLED]: [chvalid_battery_00] FAIL: Lean OOM-KILLED (exit 137; cgroup memory cap CERB_TEST_MEM_MAX=4G breached — memory.events oom_kill=1)
PLANT OK   [gcc_oracle exit(137) native -> compared (AGREE gcc=137 lean={137}), not SKIP_GCC_KILL]: [1/1] AGREE O2_AGREE .tmp/scripts/kill-plant.r5ZXx31jsh/gcc137/exit137.c: gcc=137 lean={137}
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
```

### Baseline re-derivation under the cap — enumeration (verbatim lane lines; final harness code)

```
libc_exec        rc=0      14s  SUMMARY: match=7 diff=0
libxml2_uri      rc=0      12s  libxml2 uri 5-TU harness (arc-6 S4 GATE, 16-URI corpus) GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
immaculate       rc=0      25s  OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
gcc_oracle       rc=0    1158s  SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9 Baseline check: 0 regression(s), 0 improvement(s)
libxml2          rc=0     661s  SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) ALL PASSED
```

(libxml2 ran on the migration commit's code; its 137 paths were not
exercised and are textually the only S2 delta since.) MOVED rows: none
in any gate baseline. The expected class (rows that died under `ulimit
-v` and now complete) has no members in the committed baselines — the
libxml2 lanes were already green (the charter's "biased against Lean"
concern did not manifest as rows) — and its two known instances are the
detective's non-baselined rows, re-run through the migrated
`run_probe.sh` (libc mode, 4G resident cap), verbatim:

```
=== det_array (run_probe.sh libc mode, cap 4G)
=== ORACLE (exit 0) ===
=== LEAN (exit 0) ===
=== VERDICT ===
AGREE VAL:Specified(0)
=== det_pr20621-1 (run_probe.sh libc mode, cap 4G)
=== ORACLE (exit 0) ===
=== LEAN (exit 0) ===
=== VERDICT ===
AGREE VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|VAL:Specified(0)|V
```

Tier-C sweep artifact re-recorded in the instrument commit
(`tests/ci_sweep/results/tcc.tsv`, full tcc suite, 70 rows before and
after; `SWEEP SUMMARY suite=tcc mode=libc total=70 match=62 ub_match=2
… lean_crash=1 lean_kill=0 … cerb_kill=0`): ONE class move —
`tests/tcc/40_stdio.c LEAN_TIMEOUT → LEAN_CRASH` (`exit 134: PANIC at
CerbFS.fs_read CerbFS:221:8: CerbFS refusal (fail-closed fs-model
boundary): read on fd 4 at offset 5 of 12-byte file 'fred.txt'`),
attributed to the trust-basket CerbFS fail-closed change `9152d2afe`
(postdates the recorded sweep; stale row, not a cap effect). Detail-only:
`15_recursion.c CERB_TIMEOUT >15s → TIMEOUT(cpu 15.03s of 15.03s wall;
timeout 15s)` (S0's note); `24_math_library.c`, `81_types.c`,
`82_attribs_position.c` CERB_REJECT details embed the recording
worktree path (cosmetic). The other 14 sweep TSVs are not re-recorded
(separate deliberate instrument run).

### Parity confirmation (charter §4, F4 rules) — `tests/mem-scale-probes/results/2026-09-02_s2-parity.tsv`

Run: `run_all.sh --engines oracle-random,lean-first --timeout 600`,
`CERB_MEM_MAX=32G`, box otherwise idle; oracle bin `986d9fa7f5dde61e`
(source-set hash `a54c0b1f…` — the harnesses' own `build_cerberus` relinks
the oracle non-reproducibly; the source hash is the identity), Lean
`406960e92de44c2f`. Method (DERIVED, `.tmp/memscale/parity_table.py`,
ephemeral; the table is reproduced here in full): ratios on the
INCREMENTAL cost over the same-mode/engine `z_base` row (the profile §3
method), fixed startup reported separately; rows whose oracle increment
is below resolution (<0.5 s and <32 MB) are labelled, not scored;
non-completing rows are attributed blockers or out of domain, never
counted. Every Lean exit-134 row was checked for its marker: all six read
`lem: fuel exhausted` (C8).

Fixed startup cost (z_base, both engines):
  libc    lean-first     wall 2.51 s  RSS 223 MB
  libc    oracle-random  wall 0.48 s  RSS 108 MB
  nolibc  lean-first     wall 0.05 s  RSS 74 MB
  nolibc  oracle-random  wall 0.07 s  RSS 43 MB

| probe | mode | oracle Δwall s / ΔRSS MB / verdict | lean Δwall s / ΔRSS MB / verdict | Δwall ratio | ΔRSS ratio | raw wall / RSS ratio | status |
|---|---|---|---|---|---|---|---|
| a_uninit_local_1000 | nolibc | 0.00 / -0 / VAL:Specified(7) | 0.00 / 0 / VAL:Specified(7) | — | — | 0.71 / 1.75 | below resolution (oracle increment <0.5 s, <32 MB) |
| a_uninit_local_10000 | nolibc | 0.01 / 2 / VAL:Specified(7) | 0.00 / 0 / VAL:Specified(7) | — | — | 0.62 / 1.65 | below resolution (oracle increment <0.5 s, <32 MB) |
| a_uninit_local_100000 | nolibc | 0.13 / 22 / VAL:Specified(7) | 0.17 / 19 / VAL:Specified(7) | — | — | 1.10 / 1.44 | below resolution (oracle increment <0.5 s, <32 MB) |
| a_uninit_local_1000000 | nolibc | 0.63 / 220 / VAL:Specified(7) | 0.81 / 213 / VAL:Specified(7) | 1.29 | 0.97 | 1.23 / 1.09 | MET |
| a_uninit_local_10000000 | nolibc | 12.71 / 2218 / VAL:Specified(7) | 18.33 / 2137 / VAL:Specified(7) | 1.44 | 0.96 | 1.44 / 0.98 | MET |
| a_zero_global_1000 | nolibc | 0.00 / 0 / VAL:Specified(7) | 0.00 / 0 / VAL:Specified(7) | — | — | 0.71 / 1.72 | below resolution (oracle increment <0.5 s, <32 MB) |
| a_zero_global_10000 | nolibc | 0.05 / 8 / VAL:Specified(7) | 0.03 / 6 / VAL:Specified(7) | — | — | 0.67 / 1.57 | below resolution (oracle increment <0.5 s, <32 MB) |
| a_zero_global_100000 | nolibc | 0.54 / 95 / VAL:Specified(7) | 0.38 / 66 / VAL:Specified(7) | 0.70 | 0.69 | 0.70 / 1.02 | MET |
| a_zero_global_1000000 | nolibc | 4.28 / 879 / VAL:Specified(7) | 2.53 / 669 / VAL:Specified(7) | 0.59 | 0.76 | 0.59 / 0.81 | MET |
| a_zero_global_10000000 | nolibc | 240.60 s / 7517 MB / VAL:Specified(7) | 600.09 s / 2656 MB / NONE HANG(cpu 3.23s of 600.09s wall; timeout 600s); | — | — | — | BLOCKER: C9 (HANG) |
| b_zero_local_1000 | nolibc | 0.03 / 4 / VAL:Specified(7) | 0.12 / 2 / VAL:Specified(7) | — | — | 1.70 / 1.64 | below resolution (oracle increment <0.5 s, <32 MB) |
| b_zero_local_10000 | nolibc | 0.26 / 44 / VAL:Specified(7) | 0.58 / 28 / VAL:Specified(7) | 2.23 | 0.64 | 1.91 / 1.18 | MET |
| b_zero_local_100000 | nolibc | 3.22 / 434 / VAL:Specified(7) | 8.19 / 297 / VAL:Specified(7) | 2.54 | 0.68 | 2.50 / 0.78 | MET |
| b_zero_local_1000000 | nolibc | 22.04 s / 4478 MB / VAL:Specified(7) | 1.10 s / 103 MB / NONE | — | — | — | BLOCKER: C8 (fuel) |
| b_zero_local_10000000 | nolibc | 601.01 s / 17449 MB / NONE TIMEOUT(600s); | 1.10 s / 100 MB / NONE | — | — | — | OUT OF DOMAIN: oracle exit 124 TIMEOUT(600s);; Lean exit 134 - |
| c_struct_arg_1024 | nolibc | 0.00 / 1 / VAL:Specified(0) | 0.02 / 0 / VAL:Specified(0) | — | — | 1.00 / 1.68 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_arg_4096 | nolibc | 0.06 / 5 / VAL:Specified(0) | 0.07 / 5 / VAL:Specified(0) | — | — | 0.92 / 1.63 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_arg_16384 | nolibc | 0.44 / 18 / VAL:Specified(0) | 0.11 / 18 / VAL:Specified(0) | — | — | 0.31 / 1.52 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_arg_65536 | nolibc | 5.42 / 80 / VAL:Specified(0) | 0.65 / 72 / VAL:Specified(0) | 0.12 | 0.89 | 0.13 / 1.19 | MET |
| c_struct_arg_262144 | nolibc | 56.87 / 317 / VAL:Specified(0) | 1.08 / 293 / VAL:Specified(0) | 0.02 | 0.92 | 0.02 / 1.02 | MET |
| c_struct_ret_1024 | nolibc | 0.01 / 1 / VAL:Specified(7) | 0.03 / -0 / VAL:Specified(7) | — | — | 1.00 / 1.67 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_ret_4096 | nolibc | 0.08 / 6 / VAL:Specified(7) | 0.05 / 4 / VAL:Specified(7) | — | — | 0.67 / 1.58 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_ret_16384 | nolibc | 0.45 / 19 / VAL:Specified(7) | 0.16 / 15 / VAL:Specified(7) | — | — | 0.40 / 1.43 | below resolution (oracle increment <0.5 s, <32 MB) |
| c_struct_ret_65536 | nolibc | 5.37 / 84 / VAL:Specified(7) | 0.63 / 73 / VAL:Specified(7) | 0.12 | 0.88 | 0.12 / 1.17 | MET |
| c_struct_ret_262144 | nolibc | 57.02 / 338 / VAL:Specified(7) | 1.22 / 296 / VAL:Specified(7) | 0.02 | 0.88 | 0.02 / 0.97 | MET |
| d_loop_1000 | nolibc | 0.21 / 3 / VAL:Specified(-25) | 0.62 / 13 / VAL:Specified(-25) | — | — | 2.39 / 1.90 | below resolution (oracle increment <0.5 s, <32 MB) |
| d_loop_10000 | nolibc | 1.86 / 22 / VAL:Specified(15) | 6.50 / 167 / VAL:Specified(15) | 3.49 | 7.59 | 3.39 / 3.71 | UNMET (wall RSS) |
| d_loop_100000 | nolibc | 17.24 s / 277 MB / VAL:Specified(-97) | 5.84 s / 321 MB / NONE | — | — | — | BLOCKER: C8 (fuel) |
| d_loop_1000000 | nolibc | 131.56 s / 2439 MB / VAL:Specified(63) | 11.46 s / 441 MB / NONE | — | — | — | BLOCKER: C8 (fuel) |
| e_memcpy_1000 | libc | 0.19 / -1 / VAL:Specified(7) | 0.43 / 2 / VAL:Specified(7) | — | — | 4.39 / 2.09 | below resolution (oracle increment <0.5 s, <32 MB) |
| e_memcpy_10000 | libc | 1.34 / 19 / VAL:Specified(7) | 4.27 / 15 / VAL:Specified(7) | 3.19 | 0.77 | 3.73 / 1.86 | UNMET (wall) |
| e_memcpy_100000 | libc | 7.29 s / 392 MB / VAL:Specified(7) | 7.21 s / 450 MB / NONE | — | — | — | BLOCKER: C8 (fuel) |
| e_memcpy_1000000 | libc | 114.37 s / 3058 MB / VAL:Specified(7) | 26.12 s / 1248 MB / NONE | — | — | — | BLOCKER: C8 (fuel) |

DERIVED: both-complete rows above resolution: MET=10, UNMET/mismatch=2; below resolution=14; blockers (oracle completes, Lean does not)=6 [('a_zero_global_10000000', 'nolibc', 'C9 (HANG)'), ('b_zero_local_1000000', 'nolibc', 'C8 (fuel)'), ('d_loop_100000', 'nolibc', 'C8 (fuel)'), ('d_loop_1000000', 'nolibc', 'C8 (fuel)'), ('e_memcpy_100000', 'libc', 'C8 (fuel)'), ('e_memcpy_1000000', 'libc', 'C8 (fuel)')]; out of domain (oracle does not complete)=1

Reading [AGENT]:
- Target MET on 10 of the 12 scorable both-complete rows; Lean's
  incremental RSS is ≤ the oracle's on EVERY scorable row (ΔRSS ratio
  0.64–0.97), and after S1 the aggregate-load rows are 8–50× FASTER than
  the oracle (`c_struct_*` 64K/256K: Δwall ratio 0.12 / 0.02 — the
  oracle's own `List.length` guard is now the only quadratic left, tray
  item).
- UNMET, both outside the memory model: `d_loop_10000` (Δwall 3.49×,
  ΔRSS 7.59× — the interpreter's per-step retention, charter C7,
  flagged out of this arc; 10^4 stores of one byte each) and
  `e_memcpy_10000` (Δwall 3.19× vs the 3.0 bound — marginal; libc-mode
  `memset`+`memcpy` through the Core libc, the interpreter again).
- Fixed startup cost is the dominant term on every small row and is
  NOT the memory model: libc mode Lean 2.51 s / 223 MB vs oracle
  0.48 s / 108 MB (loading the 12 libc metadata cabs-jsons + the pinned
  `libc.core` text); nolibc 0.05 s / 74 MB vs 0.07 s / 43 MB. Raw
  ratios on the tiny rows (up to 5.2× wall in libc mode) are this
  constant.
- Blockers (oracle completes, Lean does not): C9 `a_zero_global_10000000`
  (HANG — the registered ceiling, S1' reverted); C8 fuel ×5
  (`b_zero_local_1000000`, `d_loop_100000`, `d_loop_1000000`,
  `e_memcpy_100000`, `e_memcpy_1000000`) — `lemDefaultFuel` binds first
  on every long execution, as the charter predicted. Out of domain:
  `b_zero_local_10000000` (oracle TIMEOUT at 600 s / 17.4 GB; Lean fuel).
- Verdicts equal on every both-complete row.
