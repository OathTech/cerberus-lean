# For the concurrency team

Annex to [2026-10-03_concurrency-donor-archaeology.md](2026-10-03_concurrency-donor-archaeology.md)
(the "main record"). Date: 2026-10-03.

[AGENT] Read-only review of `arc/sc-s1a` @ `ad6c784e0` (S1 charter
`2026-09-29_sc-s1-charter.md` as amended, S1a commit, `SC-CONCURRENCY.md`, the
2026-09-24 design and the WP1 decision record). Nothing on the SC branches was
touched. These are inputs, not instructions: the master plan and the charter
remain governing, and every item that touches a [USER] ruling is marked as the
operator's call. **V** = verified in source, a commit or a run; **I** =
inference. Offline material is under `deps/concurrency-research/` (main record
§0).

## A. Items that bear on S1b

### A1. The `par` result order is a 2019 upstream regression, not a positional convention

The charter's S1b brief keeps "upstream's positional result order (`foldlM`
with `::`)" (`2026-09-29_sc-s1-charter.md` §4 S1b). The archaeology shows this
order is a **lost correction**:

- **Before 2019 (V).** Every driver cons-built the child tid list the same way,
  then applied `List.reverse` before building `unseq [wait …]`:
  - 2016 snapshot `model/driver.lem:396-407`
  - 2019 `0df8708ad` `frontend/model/driver.lem:742`
- **2019 (V).** The `reverse` disappeared when `par` moved into
  `core_reduction` in `650da6dfb` (2019-11-13, Memarian, "Various stuff … par()
  should work"). Today's `core_reduction.lem:1488-1489` (fork mainline) builds
  `mk_unseq_e (List.map mk_wait_e tids)` from the cons-built list.
- **Measured on the upstream binary (V).** `par(pure 1, pure 2)` bound to
  `(a, b)` gives `a*10+b = 21`, not 12 (main record §3).
- **Who can see it (V).** C programs cannot: `AilSpar` elaborates every thread
  to `unit` and discards the tuple (`translation.lem` `A.AilSpar` arm). It is
  visible to hand-written Core that uses `par` results. That includes the
  2016 litmus corpus (A4), which encodes outcomes as `a1 + 2*a2`.
- **Within the existing rulings (I).** The [USER 2026-09-29] mirror-and-refuse
  ruling still says to mirror it, and A1 does not argue otherwise. It only
  changes how the behaviour should be labelled: a known upstream regression
  with a provenance commit, for the upstream tray, rather than "upstream's
  positional order".
- **For the operator.** Whether this belongs in the discrepancy register or
  the ISO-fix register (it is a Core-level defect, not an ISO question) is the
  operator's decision.
- **Practical consequence for S1b fixtures.** Any `.core` schedule fixture
  with non-unit `par` results must either expect the reversed tuple or avoid
  binding the results. Otherwise the independently listed expectations will
  disagree with a faithful mirror for a reason unrelated to scheduling.

### A2. Upstream `drive` gives one schedule on `par` programs, so `drive ⊆ SC` is weak evidence

- **What upstream does (V).** Upstream's `can_advance` returns
  `not is_unseq_with_ccall` for action and memop requests, with the comment
  `(* TODO: only correct if there is only ONE thread *)`
  (`driver.lem:900-927`). `drive_nonmemory_steps_aux2` therefore performs
  every load and store eagerly, thread by thread.
- **Measured (V).** With `--debug=5` both `ND.pick` sites report singletons.
  Store-buffering in exhaustive mode returns exactly one outcome
  (main record §3).
- **Our fork (V, source).** It carries the same code, so the S1b claim
  "`drive`'s verdict sequence ⊆ the SC set on every par program" will hold
  with a single-element left side. It is a sanity check, not evidence of
  interleaving.
- **What does carry the evidence.** The charter's "independently listed
  interleavings" rows. Keep them.
- **S1a passes this check (V).** `sc_perform` (`arc/sc-s1a`
  `driver.lem:2066-2072`) does one reduction per call and does **not** reuse
  the eager loop. With S1b's per-transition thread choice, the scheduler is
  what discharges the upstream TODO. A fixture that would fail if the eager
  loop crept back is SB with a store then a load per thread: the SC set must
  contain more than one outcome.

### A3. All-blocked is a distinct terminal: matches the charter

The charter maps "all threads blocked" to `SC_final SC_blocked`, where `drive`
dies in `ND.pick … []`. Both historical drivers instead return silently
(`ND.return ()` with "hack hack, should just exit" comments). Miri does the
same as the charter, as a loud `GlobalDeadlock` (`donors/miri`
`src/concurrency/scheduler.rs`). No change suggested.

### A4. A ready-made litmus corpus for S1b / V1 / S2, from 2016

`deps/concurrency-research/snapshots/cerberus-e8575cd81-2016/tests/concurrency/`
holds 29 files: `.core` litmus tests plus `.c` versions in cppmem syntax.
Expected sets are in the snapshot's `src/tests.ml:75-105`.

- **Inside the SC fragment (I, by DRF-SC for all-SC programs; verify each
  row):** the rows using only `seq_cst` or non-atomic accesses:
  - `SB+Wsc_Rsc+Wsc_Rsc` {1,2,3}
  - `LB+Rsc_Wsc+Rsc_Wsc` {0,1,2}
  - `IRIW+Wsc+Wsc+Rsc_Rsc+Rsc_Rsc` (all but 5)
  - `hb-mo-cycle+Wsc_Wsc_Rsc+Wsc_Wsc_Rsc` {1,2,3}
  - `datarace+Rna+Rna` {0}
  - `datarace+{Wna+Wna, Rna+Wna, Rna+Rna_Wna}` → `Data_race` (useful for S2)

  Their header comments state the intended outcome sets.
- **Outside the fragment:** the rel/acq/rlx rows. These are refusal controls
  for S3.
- **Caveats.** The files use 2016 Core syntax: master no longer parses its own
  copies (`invalid symbol '!'`). They must be re-expressed, which is cheap at
  ≤30 lines each. They observe `par` result order (A1).

## B. Items that bear on S2 (source order and races)

### B1. Correction to the main record, in your favour

The first version of the main record (§6.1) claimed that once the unsequenced
monitor exists, a thread's accesses may be treated as clock-ordered. That is
**wrong**, and `SC-CONCURRENCY.md` constraint 3 is right. 6.5p2 makes UB only
the unsequenced conflicts on the *same* scalar. Unsequenced accesses to
different objects stay unordered by sb, so a per-thread clock invents
happens-before edges. The main record is corrected.

### B2. Miri's detector carries over if indexed by source strand, not by OS thread (I)

Miri (`donors/miri`, Apache-2.0/MIT) is the best executable donor for the
*predicates and lifecycle rules*. Its indexing assumes one totally ordered
strand per thread.

- **Predicates (V, re-checked).** `src/concurrency/data_race.rs`:
  `atomic_read_detect` :655, `atomic_write_detect` :670,
  `non_atomic_read_detect` :689, `non_atomic_write_detect` :716.
- **Lifecycle (V).** `thread_created` :1716 (the child's clock joins the
  creator's, then both tick) and `thread_joined` :1786 (the joiner acquires
  the terminated thread's release clock).
- **The mapping (I).** Read Core's `unseq(e1…en)` as a *fork of n strands*,
  and its sequence point as their *join*. That is the same pair of rules,
  applied at expression granularity. Clocks are then vectors over live strands
  (threads × open unsequenced branches), and Miri's predicates apply unchanged.
  This matches the design doc's "sparse/vector summaries" requirement
  (`2026-09-24_sc-concurrency-design.md` §~257-274) and supplies a concrete,
  battle-tested rule set to state it against.
- **Width (I).** Miri bounds clock width by reusing indices of terminated
  threads (`reuse_candidates`). The strand analogue is reusing a joined
  strand's index once its clock is dominated. The design doc already asks for
  a proof of exactly this "older access is dominated" condition.

### B3. Smaller Miri points relevant to the S2/S3 rows (V unless marked)

- **Byte ranges, not scalar locations.** Clocks live per allocation in a
  range map over byte offsets (`DedupRangeMap<MemoryCellClocks>`), and atomic
  accesses record their size (mixed-size detection). This fits constraint 4
  (byte ranges ≠ C locations ≠ atomic object identity).
- **SC fences** are modelled as an RMW on one global `last_sc_fence` clock.
  That is the simplest fence rule for the all-SC domain (S3).
- **Failed CAS** is an atomic load at the failure ordering. Spurious failure is
  a flag (`can_fail_spuriously`) drawn from an RNG rate. For this project make
  it an `nd`/`sc_choice` alternative, so exhaustive mode enumerates it, with no
  rate literal (I; no-magic-values rule).
- **Fast path.** Detection is skipped while only one thread has ever existed
  (`multi_threaded`). This is a cheap way to keep sequential lanes free of
  monitor cost.

### B4. Monitor state belongs in `sc_config` (I)

Miri keeps its detector in global mutable interpreter state, which works
because it has a single execution path. Here `unseq`/`nd` branch inside one
thread, and `sc_explore` enumerates, so monitor state must be per-branch.
S1a's value-typed `sc_config` already gives this for free if S2 puts the
summaries there. This argues against any `IO.Ref`/opaque side store.

## C. Items that bear on S1d and the explorer

- **Replay format (V).** S1a's `sc_policy_schedule : list sc_choice` is the same
  format as rmem's search driver (`donors/rmem` `src_top/new_run.ml`, a list of
  non-eager transition indices). It is the only one of the formats surveyed
  that also replays `unseq`/`nd` choices; Miri's seed and VST's thread-only
  schedule list cannot. No change suggested.
- **Choice points (V/I).** rmem's eager/non-eager split
  (`machineDefTransitionUtils.lem:454` `is_eager_transition`) is the same idea
  as S1a's "`[x]` creates no node". Keep deterministic reductions out of the
  choice set.
- **History stays in the explorer (V).** rmem keeps `transition_history` in the
  system state ("might have a bad effect on performance") and hashes the
  pretty-printed state for pruning (`hash_of_system_state`). Both are
  anti-patterns S1d already avoids by streaming the trace. GenMC/Nidhugg
  re-execute from the start under a recorded prefix, which keeps a single
  execution history-free.

## D. Items that bear on the later Lean/Iris presentation (no S1 action)

- **iris-lean (V).** `Iris/Iris/ProgramLogic/Language.lean:128` steps a list
  pool `t1 ++ e :: t2 → t1 ++ e' :: t2 ++ efs`, with forks **appended**.
  Cerberus's `thread_states` is an association list with insertion by
  `assoc_insert`. A later Iris instance needs a stated correspondence between
  the two orderings. It is cheap to note now and costly to discover later.
- **HITrees (V).** `donors/hitrees` (Lean 4, BSD-style)
  `src/HITrees/Effects/Conc.lean` gives one thread-pool definition with a
  relational `choose_thread` (:65) and an executable `schedule`. It is a Lean
  precedent for "relational step + executable runner over one definition"
  (S5's semantic interface).

## E. Nothing found that changes the plan

The archaeology found **no** existing working SC interleaver to adopt instead
of the S1 path:

- 2016 `e8575cd81` is the best historical shape. It is the same
  thread-pool / spawn / `wait` mechanics S1b already mirrors, and its RMW was
  unfinished (`error "WIP: Driver.seq ==> RMWRequest"`).
- Master's `driver2` is eager.
- Nothing by Vadim Zaliva exists (main record §4).

The research supports the existing decomposition rather than reopening it.
