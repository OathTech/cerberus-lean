# cerberus-sl: the Lean 4.35.0 toolchain move of cerberus-lean

Author: [AGENT 2026-10-26]. Provider branch `arc/lean-4.35` (cerberus-lean), the
same-name pair of lem-lean's landed `arc/lean-4.35` (`mdd/lean-backend` = `e6d8db5`).
This describes the provider candidate; it does not claim a landing, a re-pin of
cerberus-sl or a build of it. The checked commands and results are in
[the record](2026-10-25_lean-4.35-cerberus-record.md). The companion
[Caesium note](2026-10-25_consumer-note-cerberus-caesium-lean-4.35.md) carries the
full list of repair classes with the repairs that worked; this note says what is
specific to cerberus-sl.

## Nothing moves for cerberus-sl until its own re-pin

cerberus-sl consumes cerberus-lean BY COMMIT (`scripts/semantics-pin.env`) and its
five `lean-toolchain` files read `leanprover/lean4:v4.32.2`. They stay so until
cerberus-sl re-pins to a cerberus-lean commit at or after this move's landing; a
4.32.2 Lake cannot load 4.35.0 `.olean`s, so the two moves happen together.

## At the re-pin

- `lake update` (Lake 5.0.0 arrives with the toolchain) propagates cerberus-lean's
  `lean-toolchain` = `v4.35.0` into cerberus-sl's workspace file and rewrites its
  manifests to schema `1.3.0`; the other four `lean-toolchain` files (if they are
  separate Lake roots) move the same way or by hand.
- LemLib is inherited at `e6d8db5` (lem-lean on 4.35.0); cerberus-lean's generated
  tree is expected byte-identical to the 4.32.2 one (the record's P5 section states
  the identity check once run), so no quoted generated term moves.
- Expect the repair classes of the Caesium note in cerberus-sl's own seams and
  proofs: the removed `String` functions; `split` on `lem_if` guards after unfolding
  the comparison helper; `simp_all only` contradictions (`not_true_eq_false`,
  `Bool.false_eq_true`); `refine`/`rfl` through a dead `ite` or with unassigned
  metavariables; the deprecations (`String.mk`/`List.asString` → `String.ofList`,
  `String.get`/`prev` → `String.Pos.Raw.*`, `if_pos`/`if_neg`/`if_false`/`if_true` →
  `ite_eq_left`/`ite_eq_right`/`ite_false`/`ite_true`, `Sublist.cons₂` → `cons_cons`);
  `#guard_msgs` pins naming `instBEqOfDecidableEq` at `Int` or a fixed-width type.
- Native objects compiled with 4.32.2's `leanc` must be rebuilt with 4.35.0's.

## The contracts cerberus-sl cites are unchanged

`CerbMemAccessFacts` (consumer ask (c), DECISIONS C3.399): every exported name keeps
its statement — `loadM_erasure`, `storeM_erasure`, `stopObserving_recordAccess`,
`recordAccess_stopObserving`, `recordAccess_of_observations_none`,
`stopObserving_lastUsed`, the six `stopObserving_<field>` lemmas,
`findOverlapping_stopObserving`, `stopObserving_exposeOnLoad`,
`exposeOnLoad_observations`, `resolveIota_stopObserving`, `liftND_returned_state`.
Only `loadM_erasure`'s PROOF changed (two core lemmas added to its `simp_all only`
lists for the strict-reads-refusal/trap-arm contradictions 4.35.0 leaves open);
`test/Unit/MemoryAccessProofs.lean`'s restatements compile unchanged, and the module
is in the kernel-replay list of the record. `CerbMemDefaultFacts`, the outcome
protocol (`docs/2026-10-20_consumer-note-cerberus-sl-outcome-protocol.md`), the PNVI
contracts and the reconstruction wrappers are untouched.

Two measured 4.35.0 facts (record §2, §3): the 128-field constructor runtime limit is
gone (lem's emitter still refuses ≥128-field records, lem-lean TODO 55, pending a
ruling), and the 4.35.0 code generator's inlining of small nullary defs touches no
impure seam in cerberus-lean's tree (the census is §3 of the record).
