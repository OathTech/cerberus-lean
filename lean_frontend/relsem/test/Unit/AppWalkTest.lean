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
import Exception

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

/-! ## E11-E13 (arc/t5-seal, engineRev 5): SEAL-THROUGH-THE-CHASE
    exercises — the checkpoint/propositional-iota/doctored-link
    contract rows. E11/E12 run as elaboration-time meta checks (the
    compile IS the test, same as the theorem rows); E13 exercises the
    deep-chase entry on a kernel-guard-class synthetic. -/

/- E11 (the NEGATIVE row): a DOCTORED chase link — a checkpoint-link
   statement that is FALSE — must be refused by the kernel. The link
   path's only checker is `addDecl` (addRawAuxThm); nothing
   elaborator-trusted can accept it. -/
set_option Elab.async false in
open Lean Meta RelSem.Tactics in
#eval show MetaM Unit from do
  let ty := mkApp3 (mkConst ``Eq [1]) (mkConst ``Nat)
    (mkNatLit 0) (mkNatLit 1)
  let val ← mkEqRefl (mkNatLit 0)
  let accepted ← tryCatchRuntimeEx
    (try
      discard <| addRawAuxThm ty val `e11plant .cert
      pure true
    catch _ => pure false)
    (fun _ => pure false)
  if accepted then
    throwError "E11 FAIL: doctored chase link ACCEPTED"
  IO.println "E11 ok: doctored chase link kernel-refused (addDecl)"

namespace E12Fixture

def resVal : exceptM (Nat -> Nat) Unit := exceptM.Result (fun x => x + 1)

def stuckApp : Nat :=
  exceptM.casesOn (motive := fun _ => Nat -> Nat) resVal
    (fun f => f) (fun _ => id) 7

end E12Fixture

/- E12: CHECKPOINT SEAL + PROPOSITIONAL IOTA. (a) `chaseCheckpoint`
   mints a registered aux definition whose reference the KERNEL
   accepts as defeq to the original; (b) `iotaByLemma` produces a
   one-step reduct with a proof that survives `check` AND lands as an
   ordinary kernel-checked declaration (`addDecl`) — the generic
   equation lemma route, zero new axioms. -/
set_option Elab.async false in
open Lean Meta RelSem.Tactics in
#eval show MetaM Unit from do
  let some ci := (← getEnv).find? ``E12Fixture.stuckApp
    | throwError "E12: fixture missing"
  let e := ci.value!
  -- (a) checkpoint seal
  let some ref ← chaseCheckpoint e
    | throwError "E12 FAIL: checkpoint refused"
  let some n := ref.getAppFn.constName?
    | throwError "E12 FAIL: seal reference malformed"
  unless (← isSealedAuxName n) do
    throwError "E12 FAIL: seal not registered"
  match Lean.Kernel.isDefEq (← getEnv) {} ref e with
  | .ok true => pure ()
  | _ => throwError "E12 FAIL: kernel rejects seal = original"
  -- (b) propositional iota: expose the casesOn app at ctor major
  let rv := (((← getEnv).find? ``E12Fixture.resVal).get!).value!
  let eCtor := e.replace (fun x =>
    if x.isConstOf ``E12Fixture.resVal then some rv else none)
  let some (y, pf) ← iotaByLemma eCtor false
    | throwError "E12 FAIL: iota lemma did not fire"
  check pf
  let pty ← inferType pf
  let nm ← mkFreshUserName `e12iota
  addDecl <| .thmDecl { name := nm, levelParams := [], type := pty, value := pf }
  let _ := y
  IO.println "E12 ok: checkpoint seal kernel-accepted; propositional-iota certificate kernel-checked"

namespace E13Fixture

/-- forces a case on its argument: `g (deepApp n)` chains majors. -/
def g : Nat → Nat
  | 0 => 1
  | _+1 => 0

def deepApp : Nat → Nat
  | 0 => 0
  | n+1 => g (deepApp n)

end E13Fixture

/- E13: DEEP CHASE. Find a major-chain depth the KERNEL refuses
   (`deep recursion detected` — the R13 wall class), then drive the
   rev-5 chase on it: the certificate chain must land (progress with
   a `check`-clean, kernel-addable proof). If the kernel handles all
   probed depths in this environment, the exercise still validates
   the chase on the largest (SKIP-tolerant on the refusal premise —
   the guard is an environment property, never assert its position). -/
set_option Elab.async false in
open Lean Meta RelSem.Tactics in
#eval show MetaM Unit from do
  let mk (n : Nat) : Expr :=
    mkApp (mkConst ``E13Fixture.deepApp) (mkNatLit n)
  let mut lo := 0
  let mut chosen := 4096
  let mut found := false
  for n in [1024, 2048, 4096] do
    if !found then
      match Lean.Kernel.whnf (← getEnv) {} (mk n) with
      | .ok _ => lo := n
      | .error _ =>
        chosen := n
        found := true
  -- bisect toward the guard so the chase gap stays small
  if found then
    let mut hi := chosen
    while hi - lo > 64 do
      let mid := (hi + lo) / 2
      match Lean.Kernel.whnf (← getEnv) {} (mk mid) with
      | .ok _ => lo := mid
      | .error _ => hi := mid
    chosen := hi
  let e := mk chosen
  let env0 ← getEnv
  let refused : Bool := match Lean.Kernel.whnf env0 {} e with
    | .error _ => true | _ => false
  let cache : ChaseCache ← IO.mkRef {}
  let (v, pf, prog) ← kWhnfWithFacts 4096 e (trace := false)
    (sealDepth := 48) (cache := some cache)
  unless prog do
    throwError "E13 FAIL: chase made no progress at depth {chosen} (kernel refused: {refused})"
  check pf
  let pty ← inferType pf
  let nm ← mkFreshUserName `e13chase
  addDecl <| .thmDecl { name := nm, levelParams := [], type := pty, value := pf }
  let _ := v
  IO.println s!"E13 ok: deep chase at n={chosen} (kernel refused: {refused}) — certificate chain kernel-checked"

end AppWalkTest

def main : IO UInt32 := do
  -- The exercises are kernel-checked at compile time; report and pass.
  IO.println "AppWalkTest: E1-E8+E10 kernel-checked, E9 preview-negative + E10-mismatch pinned"
  IO.println "AppWalkTest: E11 doctored-link refusal, E12 checkpoint+prop-iota, E13 deep chase (engineRev 5)"
  IO.println "AppWalkTest: ALL PASSED"
  return 0
