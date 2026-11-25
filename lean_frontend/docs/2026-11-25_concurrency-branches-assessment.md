# Assessment of the concurrency branches (2026-11-25)

An independent, read-only evaluation of the work on branches aimed at
building concurrency support, asked for by the user on 2026-11-25 with the
question: is any of it good and worth continuing, or is it out of date?
Written by an evaluating agent [AGENT 2026-11-25] against mainline
`6796f842b`; transcribed here by the orchestrating agent without change of
substance. It is an input to a decision, not a decision: nothing here has
been ruled on by the user, and no branch has been pruned.

**How to read it.** "Verified" means the evaluator read the code or diff at
the named ref. "Per record" means it relies on the branch's or mainline's own
documents. **Nothing was built or run**, so every pass count and axiom-cone
result quoted from a branch is that branch's own claim. The scope of the
pending redesign of cerberus-lean was unknown to the evaluator.

## Overall

There is no concurrency implementation worth continuing as code: none of
these branches interleaves threads in a design that survives review, and all
are 300 to 680 commits behind a mainline that has changed underneath them.
What is worth keeping is the master plan's design decision, WP0 (landed and
live), a few small proofs and test inputs, and `arc/sc-s1a` as a reference
design for a single-threaded step API. The repository's own "failed"
judgement on the two early attempts is correct; the evaluator confirmed the
central defects in their code.

## 1. `origin/feature/concurrency` (`086d8762d`) and `origin/arc/concurrency-landing` (`1349ec56f`)

1. **What it built.** A `--concurrency=sc` mode: a model selector
   (`CM_sequential`/`CM_sc`), spawn/join scheduling, and a recorder that
   builds a candidate execution beside the run and checks it against
   upstream's `cmm_csem` SC predicates at the end. 13 commits, 97 files,
   +7.5k lines, of which about 1.2k is shared Lem; 30 litmus files and
   compare-exchange on both engines. `arc/concurrency-landing` adds only a
   landing charter and the Codex assessment.
2. **Quality: the architecture is wrong at its centre.**
   - Verified: `sc_tag_thread_state` (`frontend/model/driver.lem:1030-1045`)
     tags the whole arena for `SeqRMW`, by its own comment an
     over-approximation of sequenced-before. Invented ordering can hide
     races.
   - Verified: `scripts/test_litmus.sh:145-146` reads `$?` after
     `if ! run_lean …`, which is always 0, so the lane cannot see exit
     statuses.
   - Per record
     (`lean_frontend/docs/2026-09-19_concurrency-design-assessment.md`,
     reproduced by the orchestrator of the time on both engines): events are
     keyed by pointer value. A single-thread byte read of an `int` gives
     "model inconsistent" under SC, a byte-versus-word race is missed, and
     `memcpy`/`memcmp`/`realloc` bypass the recorder.
   - The end-of-run graph check is a design the master plan now rejects.
3. **Staleness.** Merge-base `31eba718e` (2026-09-05), 680 commits behind. A
   trial merge conflicts in 22 files, including `driver.lem`,
   `core_reduction.lem`, `cmm_csem.lem`, `Main.lean` and measure proofs. It
   predates the fuel, switch and implementation-profile parameters, the
   outcome protocol and the upstream merge-base bump. Rebasing is not
   realistic.
4. **Reviews.** A pre-merge audit on 2026-09-05 said merge-with-fixes (per
   record; its branch `audit/concurrency-premerge` is not in this
   repository). The Codex review of 2026-09-19 said request changes, with
   four P1 findings; the work was then paused.
5. **Verdict: abandon the code.** Salvage the litmus C files as inputs with
   expectations re-derived, and the C1/C2 counterexample programs as
   mandatory regression cases for any future design.

## 2. `origin/arc/sc-prototype-code` (`626643648`) and `origin/docs/sc-prototype-pointer` (`3363f1c16`)

1. **What it built.** A second SC attempt over 2026-09-21 to 09-24: 30
   commits, 404 files, +25.7k lines. A `sc_*.lem` family (`sc_reference.lem`
   alone is 4,206 lines, a derived copy of the cppmem model), +974 lines in
   `driver.lem`, atomics lowering in `translation.lem`, resumable helper
   services, and about 4.8k lines of Lean unit tests. It also carries
   unrelated float, filesystem and Core-parser changes.
2. **Quality: failed, as recorded.**
   - Verified: `sc_note_prefix` (`driver.lem:219-226`) re-interprets and
     re-classifies the whole recorded execution after every memory
     observation (called from `sc_post_memory`, `:249`), and `drive`
     (`:2684+`) decides the result from that graph. Runtime work grows with
     history, and the verdict depends on graph reconstruction.
   - Verified: `sc_candidate.lem:500-517` returns empty race sets whenever
     the interpretation has any issue. That is fail-open on the property the
     mode exists to check.
   - The scope sprawl makes it unauditable as a unit.
3. **Staleness.** Merge-base `5407597d9` (2026-09-20), 484 behind, conflicts
   in about 38 files. The copy holds `tests/libc/libc.core` at the base
   version, so it does not build as it stands (per its own note). Rebasing is
   not realistic.
4. **Reviews.** An independent scope review was frozen on the branch
   (`ff982afae`). The mainline quarry assessment
   (`lean_frontend/docs/2026-09-24_sc-prototype-quarry.md`) is careful and
   the evaluator agrees with it.
5. **Verdict: abandon.** Keep it as a read-only quarry for `atomic_order.lem`
   (58 lines), the CAS/RMW phase tests, the atomic C surface work and
   `tests/sc`. The 21 inputs already on mainline in `tests/sc-recovery/` are
   the useful extraction. The pointer commit should land: mainline
   `SC-CONCURRENCY.md` §5 cites `631382a9d` and `4860f0ef0`, which do not
   exist in this repository.

## 3. `origin/arc/sc-wp1` (`186392a53`) and `origin/review/sc-wp1-20260928` (`1c7e52fad`)

1. **What it built.** A feasibility experiment for the execution strategy:
   70 files, +8.4k lines, mostly documents and evidence. Code is +247 lines
   in `driver.lem` (an `experiment_*` stepper), +22 in `core_reduction.lem`,
   and about 2k lines of Lean tests, including a Lean-only adapter
   (`test/Unit/SCWP1Decision.lean`) that supplies pending-RMW ownership and
   fork/join.
2. **Quality.**
   - The decision itself is the standard SC interleaving shape and the
     evaluator considers it sound: one Core step of one thread at a time over
     the existing memory, RMW split with thread ownership, source order
     tracked separately from scheduler order.
   - Verified: `test/Unit/SCWP1SourceProofs.lean` (143 lines) holds real
     theorems about production definitions (`race_iff`, `unseq_success`,
     `unseq_pairwise`, `hoisting_excludes_prior`), with no `sorry` or extra
     axioms in the source.
   - Verified: `SCWP1Contracts.lean` is statement schemas only, honestly
     labelled.
   - The feature evidence comes from the Lean-only adapter with no oracle
     counterpart, so it does not meet the project's differential rule. It is
     a specification, not validated code.
3. **Staleness.** Base `5ecc0aa33` (2026-09-27), 412 behind. It conflicts in
   `driver.lem`, `FuelExemplar.lean` and the drift manifest, and predates
   even the switch parameter. This does not matter, because the code was
   ruled not to land.
4. **Reviews.** The independent review (ACCEPT on the decision,
   ACCEPT-WITH-FIXES on the package) is on mainline and is thorough:
   rebuilds, plants, and a real unrecorded oracle debug-output change found.
   The 2026-09-29 assessment also reads accurately against the code.
5. **Verdict: salvage parts.** Port `SCWP1SourceProofs.lean`;
   `do_race`/`one_step_unseq_aux` will have changed under mainline's fuel
   treatment, so expect a small adaptation. Keep the contract schemas as the
   starting statement of the correspondence obligations. The review branch is
   redundant: it is `af1342d32` plus the review document, which is on
   mainline.

## 4. `origin/arc/sc-s1a` (`4f1631fe8`) and tags `sc-s1a-pre-rebase-20261003`, `-20261007`

1. **What it built.** The first slice of the master plan's S1: a bounded step
   API in shared Lem for a single thread. 25 files, +3.4k lines: about 380
   lines of new Lem in `driver.lem`, a 617-line charter, a 400-line
   acceptance record, 921 lines of Lean laws, a 494-line differential script,
   and an OCaml probe. Fork, join and any second thread are refused as
   `SC_unsupported`. No thread is ever scheduled.
2. **Quality: the best work here, but narrow.**
   - Verified: the existing handlers are reused unchanged; choice discovery
     reads an already-built node, so it is effect-free; terminal outcomes are
     distinct; refusals are loud. This fits the project's rules.
   - Verified: the Lean laws are bookkeeping (counter accounting, trace
     monotonicity, bad-choice behaviour), not semantics. No `sorry` in the
     source.
   - Per record: 357 programs agree between the SC explorer and `drive` on
     both engines, with six plants.
   - Weaknesses: the budget is `List.replicate n ()`, costing about 3.5 s
     per OCaml run at 10^7; Lean exhaustive exploration has an unexplained
     4–7x slowdown on large sets (acceptance record §9.1); the lifecycle
     remainder is an opaque closure in the configuration, which the record
     itself says must become data before any fidelity proof; `sc_events`
     returns `[]` silently if the trace shrinks.
3. **Staleness.** Base `47348c07e` (2026-10-07), 300 behind, conflicts in 10
   files. This needs a semantic re-do, not a textual rebase:
   - Mainline's `process_core_step2` now routes the startup function's
     return through libc `exit` and calls `driver2` again (`driver.lem`
     around :1420-1470, `fix/stdio-exit-flush`). S1a passes a no-op as
     `driver2` and classifies any lone `Step_done2` as the program exit, so
     on mainline it would resume the lifecycle while the thread still has
     `exit` to run.
   - `driver_state` gained `exit_routed`.
   - Proofs need the third instance parameter (`CerberusImpl.ImplProfile`).
   - The `--sc-run` CLI and its script predate the outcome protocol, the
     Lean 4.35 move and the upstream merge-base bump.
   - Estimate: one to two weeks to re-derive it on mainline with the ladder,
     more if the redesign touches the driver or the ND monad.
4. **Reviews.** The charter had an adversarial review (dispatch with
   amendments, dispositions in its §9). The 2026-10-03 annex on mainline
   reviewed an earlier tip read-only and found nothing against it. The
   implementation never had a pre-merge audit and is not landed. Mainline's
   plan still says "S1: Starting 2026-09-29" and does not mention that S1a
   exists or why work stopped.
5. **Verdict: salvage as a design, re-derive on mainline.** Do not rebase.
   Keep the charter (especially §3.1 and §10, the measured facts about the
   sequential driver) and the differential-row design of
   `scripts/test_sc_step.py`. The two tags are superseded by the branch tip:
   same commits on older bases, differing only by the switch-parameter
   adaptation.

## 5. Mainline state and the route forward

- **WP0** is landed and live: ladder row 13 (`scripts/test_memory_access.py`)
  and `lean_frontend/CerbMemAccessFacts.lean`. It is passive receipts only,
  with no concurrency.
- **`SC-CONCURRENCY.md`** is still a viable route in its constraints and work
  order. Its status section is stale, as noted above. It is also heavy: the
  plan set is about 7k lines of documents against about 135 lines of landed
  semantics.
- **Two risks to put first.** Neither has any prototype yet.
  - The interesting part of S1 (threads, pending RMW) has not been attempted
    on the accepted design.
  - Recovering sequenced-before from Core with negative-action hoisting, and
    an inter-thread race monitor on it, is the hardest problem and the one
    most likely to invalidate the design.
- **First step if work resumes.**
  1. Wait for the redesign scope if it touches `driver.lem`, the ND monad or
     the memory interface; S1 is built directly on those.
  2. Land the pointer fix and a short status correction to the plan.
  3. Before re-deriving S1a, run a small throwaway spike on the source-order
     question, since that decides whether the plan holds.
  4. Then redo S1a on mainline with the exit-routing boundary handled,
     followed by S1b with the store-buffering fixture the annex recommends,
     because upstream `drive` yields one schedule on `par` programs.
- `docs/next-phase-plan-20260925` is the sequential track's plan, not
  concurrency work.

## Branch dispositions recommended by the evaluator

| Ref | Disposition | Why |
|---|---|---|
| `origin/feature/concurrency` | Keep as record | Failed design; source of litmus inputs and counterexamples; the pause note says never delete |
| `origin/arc/concurrency-landing` | Prune | It is `feature/concurrency` plus two document commits; the assessment is identical on mainline and the charter differs trivially. Prune only if `feature/concurrency` stays |
| `origin/arc/sc-prototype-code` | Keep as record | Only surviving copy of the prototype; the plan's quarry |
| `origin/docs/sc-prototype-pointer` | Land (re-cut; it is behind mainline), then prune | Fixes dangling hashes in the master plan |
| `origin/arc/sc-wp1` | Keep as record | Holds the proofs, schemas and evidence that mainline documents cite |
| `origin/review/sc-wp1-20260928` | Prune | Review document is on mainline; the rest is contained in `arc/sc-wp1` |
| `origin/arc/sc-s1a` | Keep | Only copy of the S1 charter, rulings and S1a code; unlanded and unaudited |
| tags `sc-s1a-pre-rebase-20261003`, `-20261007` | Prune | Superseded by the branch tip |
| `origin/docs/next-phase-plan-20260925` | Outside this assessment | Sequential-track plan; decide separately |

## What the evaluator could not determine

- Whether any recorded test result reproduces; nothing was built or run.
- Why work stopped after 2026-10-07; no mainline record says.
- The content of branches that mainline documents cite but this repository
  lacks: `arc/sc-concurrency`, `arc/validation-foundations-concurrency` (the
  litmus-lane repairs), `audit/concurrency-premerge`, and the original
  `arc/sc-prototype`. The offline research material under
  `deps/concurrency-research/` is also absent on this machine.
- The scope of the coming redesign, which decides whether even S1a's design
  survives.
- Whether the WP1 proofs compile on mainline today.
