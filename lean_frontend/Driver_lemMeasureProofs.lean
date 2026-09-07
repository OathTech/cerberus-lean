/-
  Driver_lemMeasureProofs — the hand-written proof of the one `fuel_measure`
  obligation lem emits into Driver_auxiliary.lean (fuel-pending close-out
  2026-09-08, option C of the pure-failure reachability census; Lean-only
  declare in frontend/model/driver.lem):

    hack   measure `lemSize pexpr1`   assuming `CerbCoreShape.IsValuePexpr pexpr1`

  `hack` (driver.lem:1446-1457) is a step-until-value loop: it steps its pexpr
  with `step_eval_pexpr` and recurses on the RESULT until `valueFromPexpr`
  accepts it — no data measure over the parameters bounds that in general (C2
  record D-C2-4). Under the hypothesis the argument already IS a value
  (`Pexpr _ () (PEval cval)`): `step_eval_pexpr` returns it unchanged
  (core_eval.lem:583-584, the `PEval` arm — annotations reset to `[]`) and
  `valueFromPexpr` accepts it (core_aux.lem:862-868), so ONE iteration returns
  `cval` at every positive fuel; the measure `lemSize pexpr1 ≥ 1`
  (CerbMeasureLemmas.pexpr_lemSize_pos) is therefore sufficient — the least
  parameter expression the declare grammar admits for a one-hop bound (a bare
  numeral is refused, lem FM-literal). The hypothesis holds at `hack`'s only
  exec-path call site, `finalize` (driver.lem:1473-1477), by `prepare_exit`
  (driver.lem:1309-1316) — CerbCoreShape.lean's header has the argument, the
  register scripts/fuel_hypotheses.txt the row.

  Shape: not the induction template (nothing descends) — two computation
  lemmas at `Nat.succ` fuel, then both sides of the obligation are the same
  value. Kernel-only tactics; no option bumps; no `sorry`.

  MIRROR-OCAML NOTE: proofs about the Lean total worker; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Driver
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Driver_lemMeasureProofs

/-- `step_eval_pexpr`'s worker on a VALUE pexpr at any positive fuel returns
    the value pexpr with its annotations reset (core_eval.lem:583-584, the
    `PEval cval -> EU.return pexpr_` arm under `Pexpr [] () <$> …`). -/
theorem step_eval_pexpr_value [LemFuel] (m : Nat) (hm : 1 ≤ m)
    (td : Fmap sym (CerbLocation.Loc × tag_definition)) (n : Nat) (loc1 : CerbLocation.Loc)
    (pcl : Option CerbLocation.Loc) (ce : Fmap sym sym) (env1 : List (Fmap sym value))
    (mso : Option CerbMem.MemState) (file1 : generic_file Unit core_run_annotation) (hc : Bool)
    (annots : List annot) (cval : value) :
    step_eval_pexpr_lemFuel m td n loc1 pcl ce env1 mso file1 hc (Pexpr annots () (PEval cval)) =
      Result (Defined (Pexpr [] () (PEval cval))) := by
  cases m with
  | zero => omega
  | succ m =>
    simp only [step_eval_pexpr_lemFuel]
    rfl

/-- `hack`'s worker on a VALUE pexpr at any positive fuel is that value: one
    `step_eval_pexpr` (the measured wrapper, at its own measure ≥ 1) returns
    the value pexpr and `valueFromPexpr` accepts it (core_aux.lem:862-868). -/
theorem hack_value [LemFuel] (m : Nat) (hm : 1 ≤ m)
    (td : Fmap sym (CerbLocation.Loc × tag_definition)) (ce : Fmap sym sym)
    (env1 : List (Fmap sym value)) (mem_st : CerbMem.MemState)
    (file1 : generic_file Unit core_run_annotation) (csm : Fmap sym object_value)
    (annots : List annot) (cval : value) :
    hack_lemFuel m td ce env1 mem_st file1 csm (Pexpr annots () (PEval cval)) = cval := by
  cases m with
  | zero => omega
  | succ m =>
    simp only [hack_lemFuel, CerbDebug.print_debug_pure, step_eval_pexpr,
      step_eval_pexpr_value _ (pexpr_lemSize_pos (Pexpr annots () (PEval cval))), valueFromPexpr]

/-- THE OBLIGATION, exactly as Driver_auxiliary.lean states and delegates it:
    under `IsValuePexpr pexpr1`, at every fuel at or above `lemSize pexpr1` the
    worker equals the wrapper (both are the pexpr's value). -/
theorem hack_measure_sufficient [LemFuel]
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (core_extern1 : Fmap sym sym) (env1 : List (Fmap sym value)) (mem_st : CerbMem.MemState)
    (core_file1 : generic_file Unit core_run_annotation) (concur_sym_map : Fmap sym object_value)
    (pexpr1 : generic_pexpr Unit sym) (lemHyp : CerbCoreShape.IsValuePexpr pexpr1) (lemFuel : Nat)
    (lemMeasureLe : generic_pexpr.lemSize pexpr1 ≤ lemFuel) :
    hack_lemFuel lemFuel _lemReader_tagDefs core_extern1 env1 mem_st core_file1 concur_sym_map pexpr1 =
      hack _lemReader_tagDefs core_extern1 env1 mem_st core_file1 concur_sym_map pexpr1 := by
  obtain ⟨annots, cval, rfl⟩ := lemHyp
  have hpos := pexpr_lemSize_pos (Pexpr annots () (PEval cval) : pexpr)
  unfold hack
  rw [hack_value lemFuel (by omega), hack_value _ hpos]

end Driver_lemMeasureProofs
