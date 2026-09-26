# Consumer note for cerberus-sl — SC WP0 lands after the alpha tag (2026-09-26)

Author: the orchestrator [AGENT]. Your committed pin (`2b51d2a57` in `scripts/semantics-pin.env`) and the alpha tag
(`cerberus-lean-v0.1.0-alpha.1` = `cfc275d84`) both predate this change; it arrives at whatever pin you take after
`mdd/cerberus-lean` moves past the WP0 landing.

## What changes for you

- `CerbMem.MemState` gains a 15th field `observations : Option (List AccessReceipt) := none` (defaulted). Every
  `{ σ with … }` update and every projection you write today still typechecks; there are no `MemState.mk` or
  anonymous-constructor sites in your tree (checked 2026-09-26).
- The production `loadM`/`storeM` append a receipt to that field WHEN CAPTURE IS ENABLED (`σ.observations = some _`).
  The default is disabled and nothing in the sequential pipeline enables it. But lemmas you prove by unfolding the
  primitives over an ARBITRARY state are affected: with capture enabled, `MemLoc.lean:26 loadM_loc_indep`,
  `:35 storeM_loc_indep`, `UnseqReads.lean:151 loadM_lastUsed_only`, `HeapModel.lean:267 storeM_active` and
  `:287 loadM_active` are FALSE (the receipt carries the source location and grows the state). Remedy: add the
  hypothesis `σ.observations = none` (or a "sequential profile" predicate implying it); it is preserved by every
  primitive when disabled — see `Unit.MemoryAccessProofs` (`disabled_recordAccess`, `load_erasure`, `store_erasure`,
  stated over the production primitives, standard axioms only).
- Trapping `_Bool` loads now return the completed-read state (`lastUsed` updated), mirroring the OCaml oracle. Only
  a lemma about the state after a `MerrTrapRepresentation` kill could notice.
- New shared types in `Mem_common` (`observed_provenance`, `representation_byte_view`, `access_receipt`); new
  functions `beginObserving`/`stopObserving`/`takeObservations` on `MemState`. No API you use was removed or re-typed.

## Records

`lean_frontend/docs/2026-09-25_sc-wp0-passive-access.md` (contract + consumer-exposure closure), `…-bool-load-repair.md`,
`2026-09-26_sc-wp0-skeptical-review.md` (the review that found the lemma exposure), the two earlier audits on their
branches. The receipts are a passive diagnostic (Tier A row 13), not SC execution; the supported profile is unchanged.
