# Executable concurrency in Cerberus: history, and design donors for SC

Date: 2026-10-03. Branch: `docs/concurrency-donor-research-20261003`.
Status: research record. It makes no decision and changes no plan.
`SC-CONCURRENCY.md` remains the governing plan.

## 0. How to read this record (offline reader)

This record was written by an agent with network access. It is meant for an
agent working **without** network access. Everything it cites is available
locally under `deps/concurrency-research/`, relative to the container root
`/home/dev/projects/cerberus-lean-proj`:

| Path | Contents |
|---|---|
| `deps/concurrency-research/cerberus-full.git` | Bare mirror of `rems-project/cerberus` fetched 2026-10-03. It includes all branches **and all GitHub `refs/pull/*`**, and contains every commit hash cited below. `deps/mirrors/cerberus.git` is older and **lacks** master `b3e11ea33`. Read with `git -C deps/concurrency-research/cerberus-full.git show <rev>:<path>`. |
| `deps/concurrency-research/snapshots/cerberus-e8575cd81-2016/` | Extracted files at `e8575cd81` (2016-03-24, the last known-green concurrency commit): `model/{driver,core_run,core_run_aux,core_driver,nondeterminism}.lem`, `concurrency/cmm_op.lem`, `src/{tests,exhaustive_driver}.ml`, `tests/concurrency/*.core,*.c` (the litmus suite). |
| `deps/concurrency-research/snapshots/cerberus-master-b3e11ea33/` | Extracted files at upstream master `b3e11ea33` (2026-09-19): `frontend/model/{driver,core_reduction,core_run,core_run_aux,nondeterminism}.lem`, `frontend/concurrency/cmm_op.lem`. |
| `deps/concurrency-research/upstream-runs/` | The small `.core`/`.c` programs used for the runs in §3. |
| `deps/concurrency-research/papers/` | PDFs **and** `pdftotext` `.txt` of: Memarian thesis (`memarian-thesis`), OOPSLA'16 (`oopsla16`, `c11op`), PLDI'16, POPL'19, CAV'19 (`cav19`), Lau dissertation (`lau-masters`), Pichon-Pharabod thesis (`jpp-thesis`), Zaliva papers (`z-cherimem-cpp25`, `asplos24`, `tr988`, `z-helix-jfp-2025`, `z-cn-translation-validation-2025`, `icfp21` = Vellvm), Zaliva CV, "Escaping the Quicksand". `cpp25.pdf` has no `.txt`. Use `z-cherimem-cpp25.txt` for the same paper. |
| `deps/concurrency-research/donors/` | Shallow clones of the non-Cerberus donors in §5: `miri`, `ch2o`, `iris`, `iris-lean`, `rmem`, `vst`, `ctrees`, `hitrees`, `c-semantics` (K), `genmc`, `nidhugg`, `c11tester`, and `ccc-code.tar.gz` (CASCompCert). The `*.clone.log` files record source URLs. |

**Provenance.** [USER 2026-10-03]: the developer who described an
"interleaving semantics concurrency model that made its way into Cerberus" was
Vadim Zaliva ("He was quite certain"). Unless marked otherwise, all analysis is
[AGENT]. **V** = verified in source, a commit, or a run. **I** = inference. Three
research subagents produced the raw findings. The orchestrator independently
re-checked the claims marked *(re-checked)*.

## 1. Summary

1. **Upstream Cerberus has had three executable concurrency paths. None works
   today.** (V)
   - (a) 2013: in-`core_run` interleaving filtered by the axiomatic C11 model.
     Removed 2014-05-20.
   - (b) 2014–2016: a thread-pool driver plus Nienhuis's operational C11 model
     (`Cmm_op`). Last green at `e8575cd81` (2016-03-24). Broken by `7d240c0bf`
     (2017-07-23).
   - (c) Memarian's 2019 reduction-context `driver2`. It is in master, but it
     executes memory actions eagerly, so `par` threads run sequentially in a
     fixed order. No interleaving happens and no inter-thread race is detected.
2. **No record of an interleaving model by Vadim Zaliva exists.** His own CPP
   2025 paper says his model has no concurrency (§4). The most likely referent
   is path (b) run *without* `--concurrency`. That mode sent memory actions
   straight to the sequential memory model, giving in effect an SC interleaving
   semantics over Core between 2014 and 2017 (I, from code; never built or
   run). Another possibility is his per-action state-monad memory interface.
3. **Best in-Cerberus donors:**
   - the 2016 driver (`e8575cd81`) for the machine shape;
   - master `core_reduction.lem` for modern-Core fidelity.
4. **Best external donors**, none of which earlier project research covered:
   - **Miri**: scheduler, thread manager and vector-clock race detector as
     separate modules. This is the closest executable analogue.
   - **CH2O**: lock-at-write / unlock-at-sequence-point for unsequenced UB,
     plus a relational/executable equivalence pattern.
   - **iris-lean**: the thread-pool step shape to target.
   - **rmem**: Lem; thread/storage split; eager vs non-eager transitions.
   - **HITrees** (Lean 4): a thread pool with relational and executable
     handlers over one definition.

## 2. History of executable concurrency in upstream Cerberus (all V)

| Date | Commit | Author | Event |
|---|---|---|---|
| 2013-09-11 | `57cd57a0f` | Memarian | cppmem thread syntax `{{{ … \|\|\| … }}}` added to the C parser |
| 2013-10/11 | `4829fb32d`, `1f83559b5`, `9a80e73fb`, `41a5afef8` | Nienhuis | Batty's axiomatic `cmm_csem` wired into `core_run`; C litmus tests; non-atomic race detection; real thread ids |
| 2014-05-20 | `1e55a69bf` / `d62485e34` | Nienhuis | Path (a) removed from `core_run` (−348 lines) |
| 2014-07-03/04 | `eb570d960`, `0f4d89618` | Memarian | New step evaluator; `Epar`/`Ewait`, `thread_states`, `driver.lem` |
| 2014-10-28 | `4425b43cc` | Nienhuis | "The concurrency test-suite runs" (`src/tests.ml`) |
| 2014-11 | `025a2248b`, `7c9453388`, `3b898c538` | both | "Data race detection works"; merge; random mode |
| 2015-04-24 | `a9bbefd15` | Memarian | cppmem notation removed from the old parser |
| 2015-04-27 | `56997c87a`…`257691a73` | Nienhuis | `concurrency/` (`cmm_op.lem` + Isabelle) imported from svn |
| 2015-10-26 | `fb45e56bf` | Memarian | Notation returns as `{-{ s1 \|\|\| s2 }-}` |
| 2016-03-24 | `b5821ae78`, **`e8575cd81`** | Memarian | "concurrency is working \o/", "all the tests work for concurrency". **Last demonstrably green.** |
| 2017-04-27 | `9efe31119` | Gomes | `tests/concurrency/` deleted |
| 2017-07-23 | **`7d240c0bf`** | Memarian | "wip" state-monad refactor: `stepConcurrency` commented out, `error "CONCURRENCY IS BROKEN"` added |
| 2018–2019 | branches `bmc*` | Lau, Pichon-Pharabod | Cerberus-BMC: axiomatic/SMT, not operational (CAV'19) |
| 2019-11-09/11 | `0df8708ad`, `4b5304e56` | Memarian | Reduction-context `core_reduction.lem` + `driver2`; positive/negative actions |
| 2022-03-13 | **`9a18c7335`** (branch `context_coresem`) | Memarian | `can_advance` / eager action execution; merged via `context_coresem_fixed` (tip `c430dafc0`) |

Caveat: an hg→git import (`948648692`, "i hate hg") left several parentless
root commits. Dates are reliable; `--diff-filter=A` is not.

Memarian thesis, p.164 (`papers/memarian-thesis.txt`): "as a result of the
changes and improvements made to the development of Cerberus, this work [the
C11 integration] is not operational in the current source." The Cerberus
homepage says the web UI explores "small **sequential** C test programs".

### 2.1 Path (b) at `e8575cd81`: the best machine-shape donor

Files are in `snapshots/cerberus-e8575cd81-2016/model/`.

- **State.** `driver_state` holds three parts: `core_state`, the layout (memory)
  state, and `concurrency_state: Cmm_op.symState`. The thread pool is
  `core_run.lem:1041`:
  `thread_states: list (thread_id * (maybe thread_id * thread_state))`, where
  the second component is the parent tid.
- **Fork.** `Epar` gives `Step_spawn_threads` (`core_run.lem:1497`, made at
  `:2223`). The driver spawns the children, and the parent arena becomes
  `Eunseq (List.reverse (map Ewait tids))` (`driver.lem:303-315`, `:396-407`).
- **Join.** `Step_thread_done` calls `kill_thread` (`core_run.lem:1250-1264`).
  It removes the child, substitutes the value for `Ewait tid` in the parent, and
  adds asw edges. `Ewait` is `Step_blocked`.
- **Scheduler** *(re-checked)*. `driver` (`driver.lem:760`) first runs
  `drive_core_threads` (`:439`), which advances each thread's non-memory steps
  (`drive_core_thread`, `:194-436`). It then filters non-blocked threads and
  does `ND.pick "driver 4" non_blocked_th_sts` followed by
  `ND.pick "driver 5" (core_thread_step2 …)` (≈`:880-881`). The interleaving
  granularity is therefore one memory action, and the choice is an ND-monad
  pick, so exhaustive mode can enumerate it. Random mode has the
  "HACK … we need to implement back tracking" comment and falls back to
  `bindExhaustive`.
- **Memory side.**
  - With `--concurrency`: `action_request_concurrency` (`:490`) adds the action
    to Nienhuis's symbolic pre-execution. Loads return symbolic
    `IVconcurRead` values. `stepConcurrency` (`:106`) commits actions, and
    constraints go to Z3.
  - Without `--concurrency`: `action_request_sequential` (`:679-736`) calls
    the memory model directly. **That is an SC interleaving** (I: code-read
    only, never built). Gaps: RMW is `error "WIP: Driver.seq ==> RMWRequest"`
    (`:736`), and this mode has no race detection.
- **sb/asw bookkeeping** is done by annotating Core expressions and
  continuations (`core_run_aux.lem`, e.g. `add_to_sb_stack`,
  `add_to_asw_stack`). A race monitor would need this; it already existed.
- **Oracle.** `src/tests.ml:75-105` lists 22 `.core` and 3 `.c` litmus tests
  with expected value sets *(re-checked)*. **Caution:** those expected sets are
  **C11 weak-memory** outcomes for the `Cmm_op` mode. For example,
  `SB+rel_acq+rel_acq` expects `[0;1;2;3]`. They are **not** SC expectations.
  An SC lane must derive its own expected sets; for SB that is {1,2,3}, i.e.
  all except 0, with the encoding of that test. Reuse the programs, not the
  numbers. The datarace rows (expected `Undefined.Data_race`) carry over to SC
  as written (I).

### 2.2 Path (c): master `driver2` (in our fork too)

Files are in `snapshots/cerberus-master-b3e11ea33/frontend/model/`.

- **`core_reduction.lem`.**
  - `step_ctx` decomposes the arena into evaluation contexts (`Cunseq`
    frames).
  - `Epar` gives `Step_spawn_threads2`; the parent gets
    `unseq(wait tid…)`.
  - `Ewait` gives `Step_blocked2`.
  - Negative actions are handled via `break_at_bound_and_sseq` / `Eexcluded`.
  - **Unsequenced races are detected per thread by footprints** (`do_race`,
    UB035).
- **`driver.lem`.**
  - The call chain is `drive` → `driver2` (`:1364`) →
    `new_drive_core_threads` → `drive_nonmemory_steps_aux2`, which repeatedly
    takes the first step whose `can_advance` is true.
  - **`can_advance (Step_action_request2 …)` and `(Step_memop_request2 …)` return
    `not is_unseq_with_ccall`, with the comment
    `(* TODO: only correct if there is only ONE thread *)`** *(re-checked,
    `:900-927`)*. Loads and stores therefore run immediately, and the later
    `ND.pick "driver non_blocked"` only ever sees singletons (debug output in
    §3).
- **Tuple-reversal bug.** Spawn folds the children into a cons-built
  (reversed) tid list, and `core_reduction` builds `unseq(wait …)` in that
  order, so `par(1,2)` returns `(2,1)` *(re-checked by run)*. The same code is
  on our mainline: `mdd/cerberus-lean` `frontend/model/driver.lem:1023-1037`,
  `core_reduction.lem:1488-1489` (V, source). Behaviour on the Lean backend
  was **not measured**. Candidate for the upstream tray.
- **Other gaps.** `with_concurrency` → `error "TODO: perform_action_request2 ==>
  concurrency"` and `"CONCURRENCY IS BROKEN"`. UB005 exists in
  `undefined.lem`, but nothing on this path emits it.
- **Possible minimal repair (I).** Make `can_advance` false for
  action/memop requests when more than one thread is live. The existing
  `ND.pick` over `non_blocked` then becomes a real interleaving point. That
  still leaves race detection, RMW atomicity and the tuple order to do.

### 2.3 The C surface

- The frontend still emits `Epar` from `{-{ s1 ||| s2 }-}`. V path:
  - `parsers/c/c_lexer.mll:654-656`
  - `c_parser.mly:1347-1350`
  - `CabsSpar`
  - `AilSpar` (`cabs_to_ail.lem:4058`)
  - `Epar` (`translation.lem:4176-4182`)

  The syntax is non-standard and undocumented.
- `pthread.h` is `#error "Cerberus doesn't support pthread.h"`.
- Memarian thesis §6.2 p.104: `par` "is used to elaborate cppmem-like thread
  creations…; they are not meant to model more general constructs, such as
  POSIX threads."

## 3. Verbatim runs (upstream binary, 2026-10-03)

Binary: `deps/cerberus-upstream/_build/install/default/bin/cerberus`
(`b9aeedcb4`). Invocation:
`scripts/ce $P/bin/cerberus --runtime=$P --nolibc --exec --batch --mode=exhaustive <file>`,
where `P=deps/cerberus-upstream/_build/install/default`. Programs are in
`deps/concurrency-research/upstream-runs/`.

```
nd.core        (nd(pure(1),pure(2)) control)
EXECUTION 0:
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}

sb2.core       (store buffering via par; SC allows several outcomes)   (re-checked)
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
  --mode=random x20 -> 20 x Specified(1)

parorder.core  (par(pure 1, pure 2) bound to (a,b); returns a*10+b)    (re-checked)
Defined {value: "Specified(21)", stdout: "", stderr: "", blocked: "false"}

race2.core     (two non-atomic stores to x in par)
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}

--concurrency sb2.core
internal error: CONCURRENCY IS BROKEN

sb_c.c  ({-{ {x=1;r1=y;} ||| {y=1;r2=x;} }-}, with libc)
Defined {value: "Specified(10)", stdout: "", stderr: "", blocked: "false"}

pth.c
.../posix/pthread.h:1:2: error: #error "Cerberus doesn't support pthread.h"

--debug=5 sb_pp.core | grep pick
(debug 2): ND2.pick [misc: new_drive_core_threads] (|ms| = singleton)
(debug 2): ND2.pick [misc: driver non_blocked] (|ms| = singleton)
```

Master's `tests/suite/concurrency/*.core` no longer parse
(`invalid symbol '!'`).

## 4. The Vadim Zaliva question

Facts (all V):

- **Commits.** 2037 Zaliva commits across all refs including PRs
  (2021-09 → 2025-03), plus his fork `vzaliva/cerberus` (5 extra CN-proof
  commits). There are **zero** pickaxe hits for `Epar`, `Ewait`, `par(`,
  `spawn_thread` or `tid_supply`. His only edits to execution files are three
  incidental signature changes (`a4a9f8bd2`, `49b05423f`, `36aac3225`).
- **`concurRead_ival`.** `68a6868bc` (2022-09-23) makes the Coq memory
  interface's `concurRead_ival` a `raise "TODO"` stub. It is a leftover hook
  from path (b), not a model.
- **What he did build.** The Coq CHERI memory model as a per-action
  state+error monad: `374dfd693` "memS monad", `memM := errS mem_state …`
  (`coq/CheriMemory/ErrorWithState.v:20`), bridged to OCaml
  (`memory/cheri-coq/impl_mem.ml`), with thread ids passed through. This is the
  interface shape a per-step interleaving driver consumes. It is not a
  scheduler.
- **His own paper.** CPP 2025 (`papers/z-cherimem-cpp25.txt`), p.3:
  "Concurrency. Our memory model does not currently support concurrency because
  it is based on a version of the Cerberus C semantics without support for the
  C/C++11 concurrency." p.12 names Lau (CAV'19) and Nienhuis (OOPSLA'16) as the
  "existing efforts … to add concurrency to Cerberus".
- **Other sources.** His CV, talks, blog, GitHub (all repos and gists), the 39
  forks of cerberus, and GitHub code search all have no concurrency content.
- **Since 2025** he has been a postdoc at Tufts on fault robustness in Lean.
  Nothing from this is published.
- **Unsearchable.** `rems-project/cerberus-old`, the pre-public repo
  referenced by upstream issues #119, #126, #127, #153 and #161, returns 404
  (private or deleted).
- **Near miss.** "Monadic Interpreters for Concurrent Memory Models" (Chappe,
  Henrio, Zakowski, CPP 2025) has a CTrees interleaving stage over Vellvm,
  which is Vadim's ecosystem. Zaliva is not an author (checked against
  Crossref). It is not Cerberus.

Inference: Vadim most plausibly remembered path (b), or Memarian's thread pool,
as group work. The questions to ask him, if needed:

1. Repo, branch, year?
2. Was it `cerberus-old`, private, or Tufts-era?
3. Did it interleave Core `par` threads or work at the memory-interface level?
4. Did it come after his CPP 2025 statement?
5. How did it handle data races?
6. Who holds the code?

## 5. External design donors

The earlier project research (2026-09-19/20/24/30 records) covered weak-memory
*theory*: Batty, OOPSLA'16, RC11, LKMM, Promising, iGPS, Cosmo, AxSL, FastTrack
(as a paper), and CAV'19. The donors below are **executable or structural**,
and none of them was previously surveyed. Clones are in
`deps/concurrency-research/donors/`.

### 5.1 Ranked shortlist

**1. Miri** (`donors/miri` @ dc9d36c; Apache-2.0/MIT). Fit: highest. This is a
sequential interpreter lifted to threads, with the scheduler, thread manager
and race monitor as separate modules.

- **`src/concurrency/scheduler.rs`.** Loom-style policy: run the active thread
  until it blocks, terminates or yields, then rotate. The rotation is
  round-robin under `fixed_scheduling`, else RNG. A `preemption_rate` sets a
  yield flag. If every thread is blocked, the result is
  `TerminationInfo::GlobalDeadlock`, a loud failure.
- **`src/concurrency/thread.rs`.**
  `ThreadState::{Enabled, Blocked{reason, deadline, callback}, Terminated}`,
  `BlockReason`, unblock callbacks, `join_thread`.
- **`src/concurrency/data_race.rs` + `vector_clock.rs`** *(line numbers
  re-checked)*. The four detection predicates: `atomic_read_detect` :655,
  `atomic_write_detect` :670, `non_atomic_read_detect` :689,
  `non_atomic_write_detect` :716.
  - Per-allocation range map of `MemoryCellClocks`: last write as
    (index, timestamp), a read clock, optional atomic clocks, and size for
    mixed-size detection.
  - Thread lifecycle at :1716 (`thread_created`: the child joins the creator's
    clock) and :1786 (`thread_joined` acquires the terminated thread's clock).
  - SC fences are modelled as an RMW on a global `last_sc_fence` clock.
  - Cost is O(live clock width) per access and does not depend on history.
    Vector indices are reused.
- **CAS** (`atomic_compare_exchange` ≈:883-962). It takes
  `can_fail_spuriously`; a failure is an atomic load at the failure ordering.
- **`data_race_handler.rs`.** The exhaustive explorer (GenMC) is a pluggable
  handler that takes over scheduling. It is consulted only before possibly
  atomic instructions.
- **Not needed:** `weak_memory.rs`.

**2. CH2O** (`donors/ch2o` @ 1afb3f6; BSD; sequential). This covers the
**unsequenced-UB** axis, which is orthogonal to threads.

- A write locks its location and records it in a lockset Ω on the value.
  Sequence points unlock only the locations their own sub-expression locked
  (`core_c/expressions.v:29-40`; `memory/memory.v:51-80` `mem_lock` /
  `mem_unlock`).
- Step rules: `core_c/smallstep.v:30-33` (assign locks), `:59-66` (unlock),
  `:121-126` (call unlocks; unsafe redex goes to `Undef`).
- `core_c/executable.v:37,92` (`cexec : … → listset state`) is proven sound
  and complete against the relation (`executable_sound.v`,
  `executable_complete.v`). That is the pattern for "relational step +
  executable successor set".
- Compare master `core_reduction`'s footprint-based `do_race`/UB035, which
  Cerberus already has.

**3. iris-lean** (`donors/iris-lean` @ 6d6544a; Apache-2.0) + upstream Iris.
This is the target **shape** for the exposed step relation.

- `Iris/Iris/ProgramLogic/Language.lean:128`:
  `Step : List Expr × State → List Obs → List Expr × State → Prop`, with
  `t1 ++ e :: t2 → t1 ++ e' :: t2 ++ efs`. Forks are appended at the tail.
- `ProgramLogic/ThreadPool.lean`.
- `HeapLang/Semantics.lean:373` `BaseStep`, `forkS`, `cmpXchgS` (strong only).
- If the Core SC machine is literally
  `(pool, σ⊕monitor) → (pool.set i k' ++ forks, σ')`, a later Iris presentation
  is an instance of it rather than a redefinition (I).
- It is relational only and has no scheduler.

**4. rmem** (`donors/rmem` @ b2d3463; BSD-2 with listed exceptions). Written in
Lem, the same toolchain as Cerberus.

- `src_concurrency_model/machineDefSystem.lem:237-300`
  `enumerate_transitions_of_system`: per-thread and storage transition
  enumeration, with caches invalidated by `changed_tids`.
- `machineDefTransitionUtils.lem:454` `is_eager_transition`. Eager
  (deterministic) transitions are taken without branching; only non-eager
  transitions are choice points.
- Search driver `src_top/new_run.ml`: DFS. Its state-hash pruning hashes the
  pretty-printed state (`hash_of_system_state`), which is an anti-pattern to
  avoid.
- What to take from it is the lessons, not the code.

**5. HITrees** (`donors/hitrees` @ 3ddf725, from git.ista.ac.at/plv/hitrees;
BSD-style; **Lean 4**, toolchain v4.22.0-rc2; not built).

- `src/HITrees/Effects/Conc.lean`:
  `Thread := yielded | completed | blocked`, `ThreadPool := List Thread`
  (:40).
- It has a relational `choose_thread` (:65) and an executable `schedule`
  handler over the same pool. This is the Lean precedent for "one definition,
  relational and executable readings".

**Also relevant, for theorem shape rather than code:**

- **VST Concurrent Permission Machine** (`donors/vst`):
  `concurrency/common/HybridMachineSig.v:319` `machine_step` with a schedule
  list, Fine vs Coarse schedulers, and
  `sc_drf/SC_erasure.v`.
- **CASCompCert** (`donors/ccc-code.tar.gz`, file list only):
  non-preemptive semantics, DRF ⇒ equivalence with preemptive scheduling (the
  "Flip" lemma). Races are excluded by permissions (the step gets stuck), not
  detected.

### 5.2 Other items surveyed (lower fit)

| Item | Why lower |
|---|---|
| K c-semantics (`donors/c-semantics`; NCSA) | Race rule `races.k` co-matches two threads' `<k>` cells, so correctness depends on exhaustive search (anti-pattern). The useful idea is `<locs-written>` cleared at `sequencePoint` (`sequence-point.k`, `io.k`), which is the same as CH2O's. |
| C11Tester (`donors/c11tester`; GPL-2) | `datarace.cc`: a one-word shadow per byte (last-writer epoch + one reader), the FastTrack epoch trick, useful if footprint matters. Switch points only at atomics/thread ops. |
| GenMC (`donors/genmc`), Nidhugg (`donors/nidhugg`; GPL-3) | Stateless re-execution under a recorded prefix keeps a single execution history-free. Graph/DPOR internals are not relevant. |
| CTrees (`donors/ctrees`; MIT; Rocq) | `examples/Yield/Par.v` `schedule`, with layered interpretation (schedule first, memory after). Monadic design idea only. |
| CompCertTSO | Web only; Coq 8.3; labelled thread-LTS × memory-LTS composition. |
| ClightOMP (arXiv 2605.26527) | Not executable, not Cerberus-based; data races excluded by permissions. |
| Veil, Gillian-C, CN/Fulminate, "Escaping the Quicksand", Dartagnan | No donor content (CN/Fulminate: "do not yet support concurrency"). |

No 2023–2026 work adding threads to Cerberus or to Core was found (V: searched
GitHub forks, code search and the literature).

## 6. Design lessons bearing on `SC-CONCURRENCY.md` constraints (I unless cited)

1. **Two monitors, not one.** Cross-thread data races (C11 5.1.2.4) and
   intra-thread unsequenced conflicts (6.5p2) are different rules.
   - Cross-thread: vector clocks give happens-before = sb ∪ sw from the
     *clocks*, never from scheduler order. That satisfies constraint 3
     ("scheduler order does not create happens-before"). Detection soundness
     does not depend on preemption granularity; only coverage does (Miri).
   - Unsequenced: Core already has footprint detection (UB035) in
     `core_reduction`; CH2O is the formal reference.
   - With the unsequenced monitor in place, the race monitor may treat one
     thread's accesses as clock-ordered.
2. **Monitor state lives in the ND state.** `unseq`/`nd` make a single thread's
   execution nondeterministic, so clocks must be per-branch state carried by
   the ND monad, not a global mutable cell as in Miri.
3. **Thread choice is one more ND choice node.** CTrees and HITrees point the
   same way. Exhaustive mode then enumerates `unseq` order, `nd`, thread picks
   and spurious-CAS failures uniformly. A selected execution is the same
   program under a choice oracle. rmem's eager/non-eager split defines which
   steps are choice points: deterministic Core reductions are eager.
4. **Replay format.** A list of (choice-point kind, selected alternative), as in
   rmem `new_run.ml`. This is the only format seen that also replays `unseq`/`nd`
   choices. Miri's seed and VST's thread-only schedule list are degenerate
   cases.
5. **Join and deadlock.** Model `wait` as `Blocked(join t)`, enabled on
   `Terminated t` (Miri). All threads blocked is a loud deadlock outcome, never
   silent termination. The 2016 and master drivers both silently return
   `ND.return ()` with a "hack hack" comment.
6. **Weak CAS spurious failure** should be an `nd` choice, so exhaustive mode
   enumerates it. Any rate used by a random mode is a quantified parameter,
   not a literal (no-magic-values rule).
7. **History-free cost.** Per-access work is O(live clock width), with
   range-coalesced per-allocation clocks and index reuse. A single-thread fast
   path is gated on "more than one thread live" (Miri's `multi_threaded`).
   Exploration history and state hashing stay strictly in the explorer
   (constraint 6).

## 7. Open items

- **Path (b) sequential mode.** Whether it actually enumerated all interleavings
  in 2016 is inferred from code. Building `e8575cd81` would need a 2016-era
  Lem/OCaml toolchain and was not attempted.
- **The tuple-reversal bug on the Lean backend** has not been measured. The
  `.lem` source is shared, so it is expected to reproduce. This matters for the
  S1 "mirror upstream fork/join" ruling ([USER 2026-09-29]): mirroring
  faithfully reproduces the reversal. That is a decision for the operator, not
  for this record.
- **Not inspected:** CASCompCert sources (file list only); HITrees was not
  built; the ClightOMP repo; Nienhuis's OOPSLA'16 supplementary material (not
  located online).
- **`rems-project/cerberus-old`** can only be searched by its owners.
