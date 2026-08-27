# The segment layer — donor correspondence table v1 (arc-18 R2)

STATUS: deliverable of the R2 rung (charter
`docs/2026-08-26_arc18-segment-ladder-charter.md`; the [USER
2026-08-26] mirror-donor discipline made auditable). One row per
construct; STATUS ∈ {MIRRORED (structural mirror with attribution —
RefinedC is BSD), ADAPTED (the donor's idea at our substrate, cite in
code), DIVERGENT (deliberate, rationale here — the charter's named
divergences)}. BRiCk is IDEAS-ONLY (tri-license; no code ported).
Code cites live in the module headers/docstrings; this table is the
audit surface.

| Ours (file:construct) | RefinedC (deps/refinedc) | BRiCk (deps/BRiCk) | Status / rationale |
|---|---|---|---|
| `Seg`/`SegDone` (Segment.lean §1) — ∃-round budgeted segment judgment at the equation calculus | `typed_stmt … (Q : gmap label stmt)` — WPs to label-indexed postconditions (typing/programs.v:68) | `wp (Sseq …) Q` over `Kpred` (logic/stmt.v) | ADAPTED — same Floyd cut-point content, carried at the ∀-fuel relative chain equation instead of a WP (our WP layer consumes segments at the driver-atom rule); DIVERGENT in one deliberate axis: [F7] TOTAL correctness — the budget `B` (Dijkstra/Gries bound function) is the termination measure's shadow; the donors' WP is partial |
| `Seg.trans` / `Seg.iter` / `Seg.while_inv` (Segment.lean §2) | `typed_block` + Lithium's loop handling (programs.v:72, 1084-1093) | `wp_while_inv` + `Kloop` (stmt.v:467-501) | ADAPTED — Hoare sequence/while rules proved once; `Seg.iter` is the VARIABLE-round iteration ([F1]) neither donor needs to state (their WPs are step-indexed, not fuel-relative); budgets add/multiply |
| `SegPoint` (entry/label/call/terminal) (Segment.lean §3) | labels of Caesium's compiled gotos | source AST nodes (`wp_lval`/`wp_operand` indexing) | DIVERGENT (charter-named) — join points are CORE LABELS, not source AST: Core's elaboration already carries its cut points as `save`/`run` labels, so no source reconstruction; source structure survives as presentation (docstrings name the construct) |
| `SegInv`/`InvMap` — invariants as a MAP from labels; obligations DERIVED (`SegInv.BodyOb`/`ExitOb`, `InvMap.while_inv`) | `typed_block (P : iProp) (b : label) … (Q : gmap label stmt)` — THE mirrored shape (programs.v:72) | invariant at the loop node (`wp_while_inv I`) | MIRRORED (RefinedC, structural, attributed in Segment.lean §3) — one declared object per label, never hand-composed obligations |
| `JoinSpellings` + `SegInv.St`'s index routing ([F3]) (Segment.lean §3) | — (Caesium's blocks have one spelling) | — | DIVERGENT-BY-NECESSITY — the C3b measured two-spelling loop-head seam (fall-in vs stored continuation) is a CORE-elaboration artifact neither donor's substrate has; the layer owns the twin vocabulary so the user declares ONE invariant (acceptance: the T5 twins; t7 measured single-spelling — the table degenerates there) |
| `FnSpec` ([F9]) + `Verified`/`WpOb`/`dischargeThr` (Segment.lean §5) | `fn_spec`/`typed_function` (typing/programs.v) | `wp_call`/function specs | MIRRORED in ROLE (one contract form, two roles; Hoare procedure rule + frame), ADAPTED in form: Hoare-style pure pre + result post + seed GUARD slot (the guarded ∀-seed house faces), NOT refinement types — reach-not-clone: our author is an agent writing Lean; the type layer's payoff (annotation compression + search guidance) is deferred (search rides the registry's goal-form keys). PROMOTION-COMPATIBLE per the ratified [USER 2026-08-26] constraint |
| `Summary`/`Summary.consume` (Segment.lean §5) | callee spec consumption at call sites | `wp_call` | ADAPTED — the procedure rule at the equation calculus (SAW-override lineage dissolves here, kernel-checked); form + generic rule landed R2, first worked two-function instance charted at R6 |
| `verify_fn` (SegmentFaces §4) | `typed_function` entry + Lithium init | brick-wp's proof-entry packaging | ADAPTED — statement → WP obligation in one refine through the FnSpec + threaded heap-route adequacy; name kept spec-flavored (not `typed_fn`) because ours is not a typing judgment |
| `seg_auto` (SegmentFaces §5) | Lithium's goal-directed rule application | brick-wp `wp_auto` | ADAPTED — registry-dispatched (R4: goal-form keys, never hardcoded names), per-joint rule selection by registered `variant`, proof-mode resource discovery by shape; full goal-directed SEARCH is arc-19 (charter pre-commitment: start from Lithium's architecture) |
| `seg_env_lookup` (SegmentFaces §2b) | Lithium's `li_tactic` side-condition dischargers | — | ADAPTED — the env-lookup peel automation (skip/hit over the captured-comparator laws; kernel decide at closed layers, omega at seed layers); the R4-priced ∀-k peel automation's concrete-instance base |
| `wpk_seq_write1` + `writeSeq` ghost fold (CerbHeapWalk/CerbHeapRA/MemLocal) | Caesium store rules | HeapLang `wp_store` lineage (cited in-code) | ADAPTED — the loop atom's per-iteration store ladder at machine-atom granularity; pointwise-ladder design per the C3b scratch2 prescription |
| Kernel certificates everywhere (every applied rule an ordinary `addDecl`-checked theorem) | Lithium trusts its solver orchestration; CN trusts SMT | Rocq kernel | DIVERGENT (charter-named) — no solver/automation trust: the meta layer shapes claims, never certifies them (statement-TCB + cone gates enforce) |
| No refinement-type/subsumption layer | THE core RefinedC machinery | — | DIVERGENT (charter-named, reach-not-clone) — breadth stereotyping data may reopen it; a typed view would sit ABOVE `Seg` unchanged |
| No human annotation front-end | RefinedC's C-attribute front-end | — | DIVERGENT (charter-named) — the author is an agent writing Lean directly; agent-facing affordances instead (registry queries, frontier tags, trace atoms) |

## Naming map (walk → segment; user-facing surfaces)

| old (engine-era) | new (user surface) | note |
|---|---|---|
| "walk" (user-facing prose/docs) | "segment" | the drives' outputs are SEGMENT CHAINS; `derive_rounds`/"walk" vocabulary remains engine-room (T5Walks/T7Walks headers say so) |
| per-fixture wp-script proofs (`wp_step`/`wp_rest` ladders) | `verify_fn` + `seg_auto` | T6/T7 landed; T1-T3 re-house at R4 |
| hand fuel arithmetic (`… 999947`) | `SegDone.run` via `driver2_of_seg` | the ∃-round budget meets `lemDefaultFuel` once, in the layer |
| `iter_compose` (fixed-round; retained) | `Seg.iter` (∃-round) | fixed-round stays registered for uniform loops; the segment layer consumes the ∃-round form |
