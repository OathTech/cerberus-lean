/-
  RelSem.Kit.Audit — arc-9 S2 (2026-08-20): per-public-lemma exactness
  pins for the L1 kits (design §4, gap G9; golean Audit/Kit.lean
  pattern — exactness on TOP of the RelSem-wide sweep, which only
  bounds cones from above).

  Every PUBLIC kit lemma gets a verbatim `#print axioms` pin via
  `#guard_msgs`. Re-baselining requires the docstring reason in the
  same commit; never re-baseline to launder growth. This file is
  imported by RelSem/Audit.lean, so `lake build` enforces it.

  Substrate-quoting lemmas (they mention generated driver/eval code)
  sit at the classical trio; the pure crossings are [propext]-grade;
  THE LOOP RULE is pinned AXIOM-FREE (design §2: "pure Nat-induction
  over equation transitivity — zero axioms").
-/

import RelSem.Kit.AppEq
import RelSem.Kit.Eval
import RelSem.Kit.Round
import RelSem.Kit.Loop
import RelSem.Kit.Mem
import RelSem.Kit.Map

-- Kit/Loop — the loop rule + fuel algebra
/-- info: 'RelSem.Kit.iter_compose' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Kit.iter_compose
/-- info: 'RelSem.Kit.iter_compose_from' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Kit.iter_compose_from
/-- info: 'RelSem.Kit.app_fuel_cast' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Kit.app_fuel_cast
/-- info: 'RelSem.Kit.fuel_split' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Kit.fuel_split

-- Kit/Eval — the eval crossings
/-- info: 'RelSem.Kit.eubind_defined' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Kit.eubind_defined
/-- info: 'RelSem.Kit.stub_defined' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Kit.stub_defined
/-- info: 'RelSem.Kit.eumapM_one' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Kit.eumapM_one
/-- info: 'RelSem.Kit.liftCore_run_defined' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.liftCore_run_defined
/-- info: 'RelSem.Kit.aux2_step' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.aux2_step
/-- info: 'RelSem.Kit.aux2_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.aux2_done

-- Kit/Round — the dnms round glue + advance classes + action unfolds
/-- info: 'RelSem.Kit.dnms_round' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.dnms_round
/-- info: 'RelSem.Kit.dnms_terminal' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.dnms_terminal
/-- info: 'RelSem.Kit.advance_tau_misc' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.advance_tau_misc
/-- info: 'RelSem.Kit.advance_runstate_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.advance_runstate_eval
/-- info: 'RelSem.Kit.advance_runstate_tau_misc' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.advance_runstate_tau_misc
/-- info: 'RelSem.Kit.advance_action_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.advance_action_unfold
/-- info: 'RelSem.Kit.advance_action_request' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.advance_action_request
/-- info: 'RelSem.Kit.perform_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_unfold
/-- info: 'RelSem.Kit.ars_load_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.ars_load_unfold
/-- info: 'RelSem.Kit.ars_create_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.ars_create_unfold
/-- info: 'RelSem.Kit.ars_store_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.ars_store_unfold
/-- info: 'RelSem.Kit.ars_kill_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.ars_kill_unfold

-- Kit/Mem — the memory-op blocks (arc-9 S2 wave 2)
/-- info: 'RelSem.Kit.mem_alloc_block' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.mem_alloc_block
/-- info: 'RelSem.Kit.mem_store_block' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.mem_store_block
/-- info: 'RelSem.Kit.mem_load_block' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.mem_load_block
/-- info: 'RelSem.Kit.mem_kill_block' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.mem_kill_block
/-- info: 'RelSem.Kit.mem_prefix_block' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.mem_prefix_block

-- Kit/Map — the lawful-map lookup layer (arc-9 S3 wave 3; design
-- §11.2 — the P2 route generalized from bytemaps to environments)
/-- info: 'RelSem.Kit.symOrd_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.symOrd_eval
/-- info: 'RelSem.Kit.symCmpAlt_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.symCmpAlt_eval
/-- info: 'RelSem.Kit.strCompare_lt' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.strCompare_lt
/-- info: 'RelSem.Kit.strCompare_self' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.strCompare_self
/-- info: 'RelSem.Kit.strCompare_gt' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.strCompare_gt
/-- info: 'RelSem.Kit.digest_compare_lt' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.digest_compare_lt
/-- info: 'RelSem.Kit.digest_compare_self' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.digest_compare_self
/-- info: 'RelSem.Kit.digest_compare_gt' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.digest_compare_gt
/-- info: 'RelSem.Kit.symCmp_bridge' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.symCmp_bridge
/-- info: 'RelSem.Kit.symCmpO_eq_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.symCmpO_eq_iff
/-- info: 'RelSem.Kit.transCmpPre' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Kit.transCmpPre
/-- info: 'RelSem.Kit.instTransCmpSymCmpO' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.instTransCmpSymCmpO
/-- info: 'RelSem.Kit.fmapAddBy_built_empty' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapAddBy_built_empty
/-- info: 'RelSem.Kit.fmapAddBy_built' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapAddBy_built
/-- info: 'RelSem.Kit.fmapLookupBy_addBy_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapLookupBy_addBy_eq
/-- info: 'RelSem.Kit.fmapLookupBy_addBy_ne' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapLookupBy_addBy_ne
/-- info: 'RelSem.Kit.tmInt_get?_insert_self' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.tmInt_get?_insert_self
/-- info: 'RelSem.Kit.tmInt_get?_insert_ne' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.tmInt_get?_insert_ne

-- Kit/Round — the NEG-transform draw laws (arc-9 S3 wave 3)
/-- info: 'RelSem.Kit.eid_draw_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.eid_draw_eval
/-- info: 'RelSem.Kit.sym_draw_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.sym_draw_eval

-- Kit/Round — the perform layer (arc-9 S2 wave 2)
/-- info: 'RelSem.Kit.liftMem_unfold' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.liftMem_unfold
/-- info: 'RelSem.Kit.app_liftMem_active' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.app_liftMem_active
/-- info: 'RelSem.Kit.aid_draw' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.aid_draw
/-- info: 'RelSem.Kit.perform_create' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_create
/-- info: 'RelSem.Kit.perform_load' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_load
/-- info: 'RelSem.Kit.perform_store' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_store
/-- info: 'RelSem.Kit.perform_kill' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_kill
-- arc-17 S2: the seq_rmw construct law (the S1-registered census gap).
/-- info: 'RelSem.Kit.perform_seqrmw' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.perform_seqrmw
