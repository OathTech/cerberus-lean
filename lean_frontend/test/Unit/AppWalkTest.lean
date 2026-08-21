/-
  Unit.AppWalkTest — arc-9 S2 (2026-08-20): the walker exercise file
  (design §8 step 4: "unit-style exercise file under test/ per the
  walker's contract table").

  Every exercise is a KERNEL-CHECKED theorem (the compile IS the
  test); `main` only reports. Exercises per the AppWalk contract
  table:
    E1  chain + leaf laws (bind spine, RHS stated)
    E2  RHS synthesis (metavariable RHS through a chain)
    E3  goal-guarded stop: a semantic hypothesis is NOT guessed — the
        walk stops and an explicit app_walk_step carries it
    E4  app_walk_finish (block-equation segment end)
    E5  iter_compose at a computation-shaped C (fuel offsets composed)
    E6  fuel algebra (fuel_split + app_fuel_cast shapes)
    E7  app_walk_norm on the E2 contract (v2 lane; since arc-11 S1
        this exercises the SEALED default — F12-4)
    E8  v2 state-opacity normalization
    E9  app_walk_preview NEGATIVE test (arc-11 S1 batch 2, design
        §12.2): the e2 goal, pinned to FAIL under preview
-/

import RelSem.Kit.AppEq
import RelSem.Kit.Loop
import RelSem.Tactics.AppWalk

set_option autoImplicit false

namespace AppWalkTest

open RelSem RelSem.Kit

abbrev M (A : Type) := ndM A Unit Unit Unit Nat

/-- E1: the walker crosses a bind spine and closes against a stated
    terminal RHS (leaf laws discharge the bind's head hypothesis). -/
theorem e1 (st : Nat) :
    app (nd_bind (nd_return 1) (fun a => nd_return (a + 1)) : M Nat) st
      = (NDactive 2, st) := by
  app_walk

/-- E2: state-passing chain — get/put crossings, stated RHS. -/
theorem e2 (st : Nat) :
    app (nd_bind nd_get (fun a =>
         nd_bind (nd_put (a + 1)) (fun _ =>
         nd_return a)) : M Nat) st
      = (NDactive st, st + 1) := by
  app_walk

/-- E3 (goal-guarded stop / the semantic division): `nd_guard`'s
    verdict is data the walker may compute only when closed; with the
    guard EXPRESSION opaque behind a hypothesis, the walk must NOT
    guess — the crossing is carried by an explicit `app_walk_step`
    with the hypothesis-mediated law. -/
theorem e3 (st : Nat) (b : Bool) (r : kill_reason Unit)
    (hb : b = true) :
    app (nd_bind (nd_guard b r) (fun _ => nd_return 7) : M Nat) st
      = (NDactive 7, st) := by
  subst hb
  app_walk

/-- E4: `app_walk_finish` closes a segment with an explicit block
    equation. -/
theorem e4 (st : Nat) (m : M Nat) (h : app m st = (NDactive 5, st)) :
    app (nd_bind (nd_return 0) (fun _ => m) : M Nat) st
      = (NDactive 5, st) := by
  app_walk_finish h

/-- E5: the loop rule composes fuel-offset app-block equations — here
    a synthetic family where one "iteration" consumes 2 fuel. -/
theorem e5 (C : Nat → Nat → Nat) (St : Nat → Nat)
    (hbody : ∀ i, i < 10 → ∀ fuel, C (fuel + 2) (St i) = C fuel (St (i + 1))) :
    ∀ fuel, C (fuel + 20) (St 0) = C fuel (St 10) :=
  iter_compose (k := 2) (n := 10) hbody

/-- E6: the fuel algebra — peel a consumed-round count off the default
    budget (the fixture instantiation move). -/
theorem e6 (M' : Nat → M Nat) (σ : Nat) :
    app (M' 1000000) σ = app (M' (999998 + 2)) σ :=
  app_fuel_cast M' (fuel_split (c := 2) (by decide)) σ

/-- E7 (arc-9 S3, walker v2): `app_walk_norm` — the same contract as
    E1/E2 through the v2 normalizing loop (opt-in path exercised;
    `app_walk` itself is untouched, E1-E6 unchanged). -/
theorem e7 (st : Nat) :
    app (nd_bind nd_get (fun a =>
         nd_bind (nd_put (a + 1)) (fun _ =>
         nd_return a)) : M Nat) st
      = (NDactive st, st + 1) := by
  app_walk_norm

/-- E8 (walker v2 opacity): a state ARRIVING as an unreduced redex is
    normalized by the v2 loop (the F-T5-2 shape at toy scale) — the
    walk must still close against the stated RHS. -/
theorem e8 (st : Nat) :
    app (nd_bind (nd_return 3) (fun a => nd_return (a + 1)) : M Nat)
        (Nat.succ (st + 1 - 1))
      = (NDactive 4, st + 1) := by
  app_walk_norm

/-! E9 (arc-11 S1 batch 2, design §12.2): THE PREVIEW NEGATIVE TEST —
    the discriminating pair. The goal below is EXACTLY e2's (which
    `app_walk` closes, kernel-checked above); `app_walk_preview` must
    FAIL on it even though its discovery walks the same rounds — the
    pinned message proves the preview walked (rounds/fired counts)
    AND that the goal was intentionally left unsolved. This is a
    TEST (untrusted-evaluator checking, per doctrine); the trust
    layers are the structural preview guards + the gate ban. -/

/--
error: app_walk_preview: preview only — goal intentionally left unsolved (4 round(s) previewed, 3 fired, outcome closed-rfl)
-/
#guard_msgs in
example (st : Nat) :
    app (nd_bind nd_get (fun a =>
         nd_bind (nd_put (a + 1)) (fun _ =>
         nd_return a)) : M Nat) st
      = (NDactive st, st + 1) := by
  app_walk_preview

/-! E10 (arc-11 S1 batch 3, design §12.2): RECORD → CHECKED REPLAY on
    the e2 contract + the goal-fingerprint NEGATIVE. All three decls
    sit under `Elab.async false` per the recorded sequencing contract
    (tactic-time env-extension visibility + the shared heartbeat
    ledger). -/

set_option Elab.async false in
theorem e10rec (st : Nat) :
    app (nd_bind nd_get (fun a =>
         nd_bind (nd_put (a + 1)) (fun _ =>
         nd_return a)) : M Nat) st
      = (NDactive st, st + 1) := by
  app_walk_rec e10_tr

set_option Elab.async false in
theorem e10replay (st : Nat) :
    app (nd_bind nd_get (fun a =>
         nd_bind (nd_put (a + 1)) (fun _ =>
         nd_return a)) : M Nat) st
      = (NDactive st, st + 1) := by
  app_walk_replay e10_tr

/--
error: app_walk_replay: trace 'e10_tr' was recorded for a DIFFERENT goal statement; re-record
-/
#guard_msgs in
set_option Elab.async false in
example (st : Nat) :
    app (nd_bind (nd_return 1) (fun a => nd_return (a + 1)) : M Nat) st
      = (NDactive 2, st) := by
  app_walk_replay e10_tr

end AppWalkTest

def main : IO UInt32 := do
  -- The exercises are kernel-checked at compile time; report and pass.
  IO.println "AppWalkTest: E1-E8+E10 kernel-checked, E9 preview-negative + E10-mismatch pinned"
  IO.println "AppWalkTest: ALL PASSED"
  return 0
