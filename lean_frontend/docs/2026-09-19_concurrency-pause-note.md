# Concurrency — PAUSED (2026-09-19): the decision, the state, the re-entry point

**Status:** [USER 2026-09-19] decision, recorded by the orchestrator [AGENT]. This note is the shop-window pointer for everything concurrency-related in this repository until the work resumes.

## 0. The decision (verbatim)

[USER 2026-09-19]: *"Hm, okay. I wonder whether we should pause on concurrency and just get sequential cerberus-lean to the best possible state. It sounds like this needs a rethink and redesign, and we have a backlog our customer needs"* — then, to the orchestrator's proposal (park both branches as the record; land Codex's assessment and this note as docs; record the decision; pick up the sequential backlog in the order of §4): *"Agreed, go ahead"*.

Earlier rulings this pauses, not reverses: [USER 2026-09-04] the parametric model with an SC instance first ("the trick would be building it so that we *don't* commit to it as the long term path"); [USER 2026-09-16] "We will eventually need concurrency - the overall north star is the same, i.e Linux system code"; [USER 2026-09-17] the consumer will eventually use one model and "the model with concurrency is in some sense the 'real' model"; [USER 2026-09-17] "Great, I agree with all of this" to the landing scoping note (`2026-09-17_concurrency-landing-scoping-note.md`, erratum `bb09cb745`).

## 1. Why (the assessment, verified)

Codex's independent assessment of the landing charter and the legacy branch — `2026-09-19_concurrency-design-assessment.md` (+ evidence dir), landed here as received — found, and the orchestrator REPRODUCED on both engines with freshly built binaries of the branch:

- **C1 (P1)** — the SC instance's recorder identifies memory events by POINTER VALUE (the branch's own "locations are pointer values, the upstream footprint dummy instantiation"), so a single-thread byte read of an `int` (`Specified(1)` sequentially) and a byte write into one (`Specified(256)`) both read `model inconsistent … at leaf well_formed_rf` under `--concurrency=sc`, and a byte-versus-word race across threads is NOT reported.
- **C2 (P1)** — `memcpy`/`memcmp`/`realloc` update the concrete bytes without recording any event: a spawn-free `memcpy` then `return x` is `Specified(7)` sequentially and model-inconsistent under SC.
- **C3 (P1)** — the withdrawn charter's agreement statement (sequential = SC on `sc_fragment_ok ∧ epar_free` programs) is FALSE as written (the C1/C2 programs pass the scan), and its abstract SC theory lacks hypotheses (per-thread sequencing; read-value = write-value), shown by counterexamples executed against the generated predicate.
- **C4 (P1)** — the legacy litmus lane ignores exit statuses (`$?` after `if ! run_lean …`, `scripts/test_litmus.sh:145-146` on the branch) and can certify incomplete executions; repaired on `arc/validation-foundations-concurrency` (`51b855aec`, `eb926f8d3`, `2460ef33f`, record `86a2aea54` = `feature/concurrency` + four commits), which any resumption must start from.
- **C5 (P2)** — the sequencing approximation tags unsequenced siblings as sequenced (`add_to_sb_ctx`; SeqRMW tags the whole arena) — an over-approximation of `sb` that can hide cross-thread races through invented ordering.
- Trust-story corrections: a predicate on a recorded graph is not program adequacy; the safety observation for racy programs and prefixes must be defined across all schedules; the selector is an extension point, not an interface with laws; the model-switch rule needs target definedness and observation inclusion, and the literature's SC result is restricted (no low-level atomics; atomic initialisation first); oracle roles stay separate (concurrency is a fork-only lane; no pristine register rows).

The orchestrator's reading (given to the operator 2026-09-19): the SC-model IDEA is sound — an interleaving semantics is the right target for a fault-avoiding logic, resting on C11's DRF-SC theorem with its stated conditions — but the branch's ARCHITECTURE is wrong at its centre: events keyed by pointer identity instead of the memory model's own range footprints, the race verdict computed from that graph, memory operations outside it. Salvageable: the typed model selector, the interleaving scheduler (spawn/join, scheduling points), the typed refusals, compare-exchange on both engines, the litmus corpus with its mechanical reference and recovered upstream sets, the dead-stub retirement, the sequential-identity lemmas, and the axiomatic bridge as a MEMBERSHIP VALIDATION on correctly built data. Not salvageable as-is: the S3 recorder's location model, the memop handling, the sequencing edges, the race-verdict source, the legacy lane's status handling.

## 2. The state (parked, untouched)

- `feature/concurrency` @ `086d8762d` (S0–S7; the other agent's Phase-0 work) and `arc/validation-foundations-concurrency` @ `86a2aea54` (+ the lane repairs) — PARKED as records; never rebase or delete; the resumption salvages from them by cherry-pick (prune-don't-merge).
- `arc/concurrency-landing` @ `1349ec56f` (the withdrawn charter + Codex's assessment; cut from `086d8762d`) — parked; its two docs commits are on the mainline via this branch.
- `audit/concurrency-premerge` @ `c0a926707` — the 2026-09-05 pre-merge audit (MERGE-WITH-FIXES; F1/F2 fixed in S7; M1 the `sc_fragment_ok` premise) — a record.
- The scoping note `2026-09-17_concurrency-landing-scoping-note.md` (mainline) — its §3 trust story stands in outline; its §4 deliverables and its model-switch paragraph are SUPERSEDED by the assessment's corrections (§1 above) and by the re-entry design (§3).
- Drift at the pause: 13 (+4) commits over merge base `31eba718e`; mainline 172 commits past it at `a8d00feed`; 23 non-doc files touched on both sides; tray drafts 36/37/38 on the branch collide with mainline's 36–38 (mainline ends at 44).

## 3. The re-entry point (when resumed)

**Stage 0 — a revised scoping note, reviewed by Codex before any charter:** the SC instance as interleaving over the byte memory, events identified by FOOTPRINT (`Mem.footprint`/`overlapping`, the concrete model's own notion) and conflicts by overlap; memory operations as range events; `sb` from Core's actual sequencing (no tagging of unsequenced siblings); the axiomatic bridge kept as a membership check on correctly built data; the supported domain stated and ENFORCED (typed refusal on anything the recorder cannot account for); the observation contract for racy programs across all schedules; theorem statements with their real hypotheses (single-thread agreement over the enforced domain; membership of race-free traces; DRF-SC transport NAMED with the sublanguage and atomic-initialisation conditions); the salvage list above; the lane rebuilt on the current observation codec with the repairs.
**Stage 1 — a NEW branch from the then-current mainline by salvage:** selector, scheduler, refusals, compare-exchange, surface cleanup; the runtime guard that makes `CM_sc` fail closed off its domain; the single-thread agreement lemma over the enforced domain; litmus 30/30; sequential invariance; FULL; audit; land. The consumer stays on `CM_sequential`.
**Stage 2 — make the instance correct:** footprint recording, overlap races, memops, sequencing fidelity, the membership theorem, the refusals lifted, the twin lane over the exec corpora; then the consumer's move to one model.
**Stage 3 — later:** the DRF-SC transport argument, an external litmus oracle (`herd7`; a network window), a weak instance.
Prerequisites that make Stage 1 simpler if they land first: the program-data parameters arc (retires the last effect-erased seams; settles `drive`'s entry signature) and the outcomes design (restructures the kill constructors).

## 4. The sequential backlog this pause serves (the operator's order, 2026-09-19)

1. The program-data parameters arc — the program-data parameters design note (2026-09-18, on the UNLANDED docs branch `docs/program-data-parameters-design` @ `1c319a40e`, awaiting the operator's Q1–Q4; it lands with that arc's charter): the enum registry (the consumer's highest uncontested request), the digest with it if taken; retires the effect-erasure invariant page.
2. The outcomes design — `2026-09-16_lean-only-outcomes-implementation-plan.md` R1: S1-pre (the R2 shared prototype on both targets), WP0 (lem-lean `inhabited_exclude`), WP1; the consumer-migration section recounted against cerberus-sl.
3. CerbGlobal step 2 — the configuration as a reader parameter (the consumer's item 5, first half).
4. Instrument debts: the immaculate lane's `--record-baseline` stripping header notes (E7); worktree priming regenerating `generated/` (E8); the optional tray proposal draft 45; the master plan's open decision D4; master plan revision 11.
5. What cerberus-sl's next rungs surface (their pointer rows and `free`: `dynamicAddrs` keying, tray 19; `bounded_integer` as an ND choice).

## 5. Provenance

[USER] quotations verbatim (§0). Facts: Codex's assessment and its evidence (as received); the orchestrator's reproductions 2026-09-19 (both engines, both models, four programs); `git` measurements at `a8d00feed`. Assessments [AGENT], agreed [USER 2026-09-19].
