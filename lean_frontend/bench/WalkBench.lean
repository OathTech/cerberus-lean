/-
  bench/WalkBench.lean — arc-11 S1 batch 3 (2026-08-21): the walker
  METRICS instrument (design §12.2 three-metric discipline; Lithium
  review §6 item 7 — the standing microbenchmark lane).

  RUN ON DEMAND (Tier C reporting, slice boundaries):
      ../scripts/capped lake env lean bench/WalkBench.lean
  NOT part of any build target. EXIT 1 BY DESIGN: the preview lane
  fails by construction (preview never closes a goal); the `BENCH`
  lines + structured trace dumps on the output are the product.

  Columns land VERBATIM in build records:
    * discovery      = preview wall (search + normalization + kernel
                       checks, no round/goal proof assembly);
    * full walk      = record-mode wall (discovery + certificates);
    * checked replay = replay wall (choice removed, checking intact).
  The kernel FINAL-check share is not tactic-visible; records derive
  it (whole-file wall minus tactic walls) and label it DERIVED.

  This file is an instrument, not a proof surface: the closed
  theorems in it are ordinary kernel-checked declarations, but no
  in-tree result depends on them.
-/

import RelSem.T1AppEq
import RelSem.T5Prefix

set_option autoImplicit false
set_option Elab.async false

namespace WalkBench

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T1
open RelSem.T5

open Lean Elab Tactic in
elab "timedp" s:str t:tacticSeq : tactic => do
  let t0 ← IO.monoMsNow
  try evalTactic t
  finally logInfo m!"BENCH {s.getString}: {(← IO.monoMsNow) - t0}ms"

/-! B1 — discovery: the T1 calibration segment under PREVIEW (stops
    at the first semantic crossing, R3 — the laws-only boundary;
    FAILS BY DESIGN: preview never closes). -/
example (x : Int) :
    app (dnms lemDefaultFuel fmapEmpty [0]) (mkDr th0 (memD3 x) rsD3 [] 0)
      = (NDactive (accDone x), mkDr (th8 x) (memD3 x) rsR6 [meLoad x] 7) := by
  timedp "B1 T1-dnms discovery (preview to semantic stop)"
    app_walk_preview

/-! B2 — full walk: the T5 entry theorem, sealed walk + kernel-defeq
    boundary, RECORDED under `bench_entry_tr`. -/
theorem benchEntryRec (n : Int) (fuel : Nat) :
    app (dnms5 (fuel + 21) fmapEmpty [0])
        (mkDr5 th0T5 (memD3 n) rsD5 [] 0)
      = app (dnms5 fuel fmapEmpty [0]) (StT5 n 0) := by
  timedp "B2 entry full walk + closure (recorded)"
    (app_walk_rec bench_entry_tr 25; app_defeq)

/-! B3 — checked replay of B2's trace (same statement). -/
theorem benchEntryReplay (n : Int) (fuel : Nat) :
    app (dnms5 (fuel + 21) fmapEmpty [0])
        (mkDr5 th0T5 (memD3 n) rsD5 [] 0)
      = app (dnms5 fuel fmapEmpty [0]) (StT5 n 0) := by
  timedp "B3 entry checked replay + closure"
    (app_walk_replay bench_entry_tr; app_defeq)

end WalkBench
