# tests/litmus — the concurrency litmus corpus

Charter: `lean_frontend/docs/2026-09-04_concurrency-phase0-sc-charter.md`
(slice S0 created this directory; exit criterion E1 is the lane going green
against `expectations.txt`). Lane: `scripts/test_litmus.sh` (header has the
contract). Everything here is C: the 2017 upstream Core litmus files no
longer parse with today's Core grammar (measured 2026-09-04), and the C
front end is the pipeline's standing boundary anyway.

## Files

| File | What |
|---|---|
| `*.c` | one litmus program each; the header comment names the shape, the class, the target outcome set and its independent source |
| `expectations.txt` | the Phase-0 TARGET: `<file> <class> <set>` rows (grammar in the file header) |
| `before_baseline.txt` | the MEASURED pin (`--record-before`), re-recorded deliberately by the slice that moves a row |
| `sc_reference.py` | the SC-DRF reference enumerator: derives every SC-class set mechanically from a hand transcription of the program; `--check expectations.txt` is the lane's first step |

## Program conventions

- Parallel composition is Cerberus's `{-{ ... ||| ... }-}` (the
  double-brace `{{{ ||| }}}` of the 2017 upstream files is rejected by
  today's parser: "unexpected token after '}' and before '|||'").
- Atomics are declared in the specifier form `_Atomic(int)`. The qualifier
  form `_Atomic int x` is REJECTED by the front end (both engines, same
  text): `constraint violation: address argument to atomic operation must be
  a pointer to _Atomic type ('signed int' invalid)` — the qualifier is lost
  on the declared type. Upstream-tray candidate (C11 6.7.3 allows the
  qualifier form); not this arc's business. The upstream-derived files
  below were respelled accordingly (recorded in their headers).
- The return value encodes the outcome (`r1 + 2*r2`, …); outcome tokens
  are the engines' batch verdicts: `Specified(v)`, `UB005_data_race`.
- Classes: `SC` = inside the SC-DRF fragment F_SC (charter §3), `RMW` =
  inside F_SC via `seq_cst` compare-exchange (slice S4), `NONSC` = outside
  F_SC (target `REFUSE`).

## Provenance of the shapes and sets

- Upstream cerberus `tests/concurrency/` (29 files, deleted upstream
  2017-04-27 in `9efe31119`; recovered read-only from `9efe31119^` in
  `deps/cerberus-upstream`): the shapes of `SB`, `LB`, `MP`, `IRIW`,
  `coherence+*`, `hb-mo-cycle`, `datarace+*`, `RMW-*`; the expected outcome
  SETS survive in this fork's `backend/common/tests.ml:77-89` and in the
  `.core` header comments. Where an upstream row used release/acquire we
  strengthened to `seq_cst` for the SC class (the set is unchanged where
  tests.ml has both variants: SB `[1;2;3]`, LB `[0;1;2]`, hb-mo-cycle
  `[1;2;3]`, IRIW all-but-5) and kept the original as a `NONSC` row.
- `sc_reference.py` re-derives every SC set; on 2026-09-04 it agreed with
  every recovered upstream set it overlaps and produced the one new set
  (`WRC+sc+sc_sc+sc_sc.c` → `{0,1,4,5,7}`: `z2 = 1` forces `z1 = 1` and
  `z3 = 1`).
- `MP+na+na.c`, `LB+rlx_rlx+rlx_rlx.c`, `SB+sc_sc+sc_sc.c`: the charter's
  2026-09-04 probes. `fence+sc_sc.c`: fences are outside `SC_condition`
  (`frontend/concurrency/cmm_csem.lem:2564-2577`).
- Not carried over: upstream `WRC+rel+acq_rel+acq_acq.c` (C++ `x.store`
  syntax with `.readsvalue`, not C), `dummy.c`; the `tests/bmc/concurrency`
  corpus (uses the BMC-only `__BMC_ASSUME`; a Phase-1 candidate together
  with the BMC backend as a second oracle, charter D6).

## Reading `before_baseline.txt`

The pin is re-recorded by the slice that moves it, and the move is
described in that slice's record:

- **S0 (2026-09-04, pre-S1 tree)**: every row was ONE outcome — the
  sequential driver ran each thread to completion before the scheduler
  picked (charter §2.1, the fail-open finding); `RMW-*` and `fence` rows
  were matched internal errors (`TODO[Core_reduction]: …`).
- **S1+S2 (2026-09-04)**: the lane runs every row under `--concurrency=sc`
  on both engines. `SC`-class rows carry their SC outcome SETS (identical
  to the `expectations.txt` targets for every multi-outcome row); the
  five race rows still report Defined values (race detection is S3);
  `NONSC` rows are the typed refusal `model refused: atomic memory order …`
  (matched on both engines; `fence+sc_sc.c` is refused on its relaxed
  accesses before the fence is reached); `RMW` rows are still the matched
  `TODO[Core_reduction]` internal error (S4). The lane's SEQ leg pins the
  sequential model's spawn refusal on one file run without the flag.

- **S3 (2026-09-05)**: the five race rows report `UB005_data_race`
  (`datarace+Wna_sc+sc_Rna.c` = `{Specified(1),UB005_data_race}`: the one
  synchronised interleaving is race-free); every SC row equals its target.

- **S4 (2026-09-05)**: the four `RMW-*` rows execute (`compare_exchange_
  {strong,weak}` reduction rules; the weak form's spurious failure is an ND
  branch): `{5}`, `{0}`, `{0,5}`, `{0}` — the recovered upstream expectation
  sets. The pin now EQUALS `expectations.txt` on every row (charter exit
  criterion E1); LADDER row 12 runs the lane in `--check` mode.
