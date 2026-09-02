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
