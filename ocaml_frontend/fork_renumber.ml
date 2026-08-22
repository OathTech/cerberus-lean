(* Fork renumbering shims (arc-13 D1: scheme R-B, upstream re-convergence).
   Evidence + decision: lean_frontend/docs/2026-08-22_arc13-s0-scheme-decision.md.

   On the OCAML target the desugar-stage and run-time symbol supplies draw
   from the single ambient counter (Cerb_fresh.int) — exactly un-forked
   upstream's scheme (this IS the mirror: upstream mints every symbol
   through the one counter; upstream generated core_run.ml:612 mints run
   Load symbols via `Symbol.fresh ()`; upstream has no threaded desugar
   supply and no run-seed draw). Symbol-id collisions are impossible by
   construction — one supply, every id a distinct draw — and the fork
   oracle's symbol numbering is byte-identical to upstream's (S0 probe:
   11/11 fixtures + libc.co dump).

   The LEAN target keeps the threaded supplies these shims bypass:
   - desugar: cabs_to_ail_effect.lem fresh_sym_supply (commit 8923d6436 —
     Lean CSE collapses pure-typed Symbol.fresh calls; the state thread is
     the Lean-side fix and stays);
   - run: core_run_aux.lem sym_supply (arc-2 purity — the run relation is
     a pure function of its state on Lean);
   - plus the 2^20 ambient base + trap floor (lean_frontend/native/
     fresh_int.c).
   The `declare ocaml target_rep` seams these functions serve:
   - Cabs_to_ail_effect.fresh_sym_int    (cabs_to_ail_effect.lem)
   - Core_run.fresh_symbol'              (core_run.lem:115)
   - Core_run_aux.initial_core_run_state (core_run_aux.lem:282)

   Backstop scope (narrowed at the arc-13 audit, finding A-F1): the
   single-supply invariant is dynamically CHECKED per TU at the DESUGAR
   seam only (util/cerb_fresh.ml check_ail_window +
   backend/common/ail_sym_hwm.ml) — re-threading fresh_sym_int off the
   counter fails loud in both directions (below- and above-window;
   plant-tested). The RUN seams (fresh_symbol',
   initial_core_run_state) carry NO dynamic check: run-minted symbols
   never pass a hand-written chokepoint outside these shims, and an
   in-shim assertion would be deleted by the very re-thread it is
   meant to catch. Their defense is static: re-threading them at the
   source level changes the generated OCaml call sites and trips the
   fork-drift gate's layer-2 hash pins (scripts/check_fork_drift.sh
   against scripts/fork_drift_manifest.txt), and this hand file is
   itself a manifested, review-bound oracle surface. *)

(* Desugar minting (upstream: Symbol.fresh* -> Cerb_fresh.int, one draw
   per registered identifier/tag/CN-ident/loop-id/marker). The desugM
   state field fresh_sym_supply is DEAD on this target. *)
let fresh_sym_int () = fun st -> Exception.Result (Cerb_fresh.int (), st)

(* Run-time minting (upstream core_run.lem: `Symbol.fresh ()` at the Load
   val_sym site — ambient, one draw per run-minted symbol). *)
let fresh_symbol' run_st = (Symbol.fresh (), run_st)

(* Mirror of core_run_aux.lem:282-289 initial_core_run_state. DELIBERATE
   divergence from the .lem body, documented: sym_supply = 0, NOT an
   ambient draw — upstream has no run-seed draw, and fresh_symbol' above
   never reads the field. The arc-2 seed draw was the last numbering
   divergence from upstream (S0 probe: +1 ambient id per const-expr
   mini-run). *)
let initial_core_run_state xs : Core_run_aux.core_run_state = {
  Core_run_aux.tid_supply = 0;
  aid_supply = 0;
  excluded_supply = 0;
  sym_supply = 0;
  labeled = xs;
}
