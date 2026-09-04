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

## Reading `before_baseline.txt` (recorded 2026-09-04, pre-S1 tree)

Every row is ONE outcome: the sequential driver runs each thread to
completion before the scheduler picks (charter §2.1, the fail-open
finding), so a 2-thread program reports one fixed serialization and no
race verdict. Which serialization wins varies by program (compare
`datarace+Rna+Wna.c` → `Specified(1)` with `MP+na+na.c` → `Specified(0)`).
The `RMW-*` and `fence` rows are matched internal errors
(`TODO[Core_reduction]: …`, `core_reduction.lem:799-814`). The pin exists so
that every movement from here is a deliberate, recorded act of a slice.
