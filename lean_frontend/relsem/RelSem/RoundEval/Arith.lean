/-
  RelSem.RoundEval.Arith — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE ARITH MINTER's verdict engine — the bridge lemma
  library (Decidable/Bool-comparator/NonNeg/decide-shape/symCmpO
  bridges), speculative omega (tryOmegaProof), the kernel-decide
  verdict (kernelVerdict), the defeq-preserving Int refolder
  (foldArith), Bool-tower closing (closeBoolTower) and the Prop
  verdict search (propVerdict). Decision procedures at the leaves —
  omega + kernel decide, the S0 ACL2Lean-donor contract; no emission
  happens here (the lanes consume these verdicts).

  Split from RoundEval.lean; code carried VERBATIM apart from
  `private` removed where the lane module consumes a definition.

  House rules: no sorry, no axioms declared here.
-/
import RelSem.RoundEval.Classify
import RelSem.Kit.Map

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

/-! ## THE ARITH MINTER (arc-17 S3 — the S2b §5-identified recipe)

    The measured T4 frontier (S2b record §5): evaluation sticks on
    Int/Nat COMPARISON DECIDABLE TOWERS over pack-bounded binders
    (`match x + 2147483648 with | ofNat _ => isTrue … | negSucc _ =>
    isFalse …` — the inlined stdlib conv body), and a REWRITE cannot
    fix a stuck constructor-match. The minter turns each stuck tower
    into a registered verdict rewrite:

    * DECIDABLE lane: any stuck subterm `d` whose type is
      `Decidable p` is minted to `d = isTrue h` / `d = isFalse h` —
      the verdict bridge is proof irrelevance (`dec_eq_isTrue/False`
      below: every inhabitant of `Decidable p` equals the one the
      side fact dictates), the side fact `h : p`/`¬p` comes from
      OMEGA over the pack's range/apartness hypotheses (open case)
      or from the S0 discharger's kernel-decide contract
      (`of_decide_eq_true` + `Eq.refl`, ground case).
    * BOOL lane: stuck `Nat.ble/blt/beq` applications (the spellings
      Symbol-comparator/`symbolEquality` chains bottom out in when a
      seed-symbolic number meets a static hash) minted to their
      `true`/`false` verdicts through the registered bridge lemmas,
      side facts omega-backed the same way.

    Candidates are collected INNERMOST-FIRST (post-order) so the
    registered patterns stay small (kabstract-cheap); every minted
    fact is an ordinary named theorem (`<base>_hf<i>`, ∀-closed over
    the command telescope) the kernel re-checks at addDecl. The
    registry is grown empirically and FAIL-CLOSED: an unminted stuck
    shape leaves the consumer's frontier to fire with the term
    printed.

    *Lineage (canon-first)*: decision procedures at the leaves —
    omega is the canonical Presburger engine, kernel-decide is the S0
    ACL2Lean-donor contract; the verdict-rewrite framing is ordinary
    conditional rewriting (the hypothesis-mode design), not a new
    proof method. -/

/-- Verdict bridge, positive: every `Decidable p` inhabitant is
    `isTrue h` once `h : p` is in hand (proof irrelevance makes the
    isTrue arm `rfl`). -/
theorem dec_eq_isTrue {p : Prop} (h : p) :
    ∀ d : Decidable p, d = .isTrue h
  | .isTrue _ => rfl
  | .isFalse hn => absurd h hn

/-- Verdict bridge, negative. -/
theorem dec_eq_isFalse {p : Prop} (h : ¬p) :
    ∀ d : Decidable p, d = .isFalse h
  | .isTrue hp => absurd hp h
  | .isFalse _ => rfl

/-! Bool-lane bridges (kernel-cheap; stated at the exact stuck
    spellings `Nat.ble/blt/beq`). -/

theorem nat_ble_true {a b : Nat} (h : a ≤ b) : Nat.ble a b = true :=
  Nat.ble_eq.mpr h

theorem nat_ble_false {a b : Nat} (h : ¬ a ≤ b) : Nat.ble a b = false := by
  cases hb : Nat.ble a b with
  | true => exact absurd (Nat.ble_eq.mp hb) h
  | false => rfl

theorem nat_blt_true {a b : Nat} (h : a < b) : Nat.blt a b = true :=
  Nat.blt_eq.mpr h

theorem nat_blt_false {a b : Nat} (h : ¬ a < b) : Nat.blt a b = false := by
  cases hb : Nat.blt a b with
  | true => exact absurd (Nat.blt_eq.mp hb) h
  | false => rfl

theorem nat_beq_true {a b : Nat} (h : a = b) : Nat.beq a b = true := by
  subst h; simp [Nat.beq_refl]

theorem nat_beq_false {a b : Nat} (h : ¬ a = b) : Nat.beq a b = false := by
  cases hb : Nat.beq a b with
  | true => exact absurd (Nat.eq_of_beq_eq_true hb) h
  | false => rfl

/-! Lem Bool-comparator bridges (`natLtb`-family: `Bool := a < b`
    decide-coercions; proofs are `decide_eq_true/false` at the folded
    spelling). -/

theorem natLtb_true {a b : Nat} (h : a < b) : natLtb a b = true := decide_eq_true h
theorem natLtb_false {a b : Nat} (h : ¬ a < b) : natLtb a b = false := decide_eq_false h
theorem natLteb_true {a b : Nat} (h : a ≤ b) : natLteb a b = true := decide_eq_true h
theorem natLteb_false {a b : Nat} (h : ¬ a ≤ b) : natLteb a b = false := decide_eq_false h
theorem natGteb_true {a b : Nat} (h : a ≥ b) : natGteb a b = true := decide_eq_true h
theorem natGteb_false {a b : Nat} (h : ¬ a ≥ b) : natGteb a b = false := decide_eq_false h
theorem intLtb_true {a b : Int} (h : a < b) : intLtb a b = true := decide_eq_true h
theorem intLtb_false {a b : Int} (h : ¬ a < b) : intLtb a b = false := decide_eq_false h
theorem intLteb_true {a b : Int} (h : a ≤ b) : intLteb a b = true := decide_eq_true h
theorem intLteb_false {a b : Int} (h : ¬ a ≤ b) : intLteb a b = false := decide_eq_false h
theorem intGtb_true {a b : Int} (h : a > b) : intGtb a b = true := decide_eq_true h
theorem intGtb_false {a b : Int} (h : ¬ a > b) : intGtb a b = false := decide_eq_false h
theorem intGteb_true {a b : Int} (h : a ≥ b) : intGteb a b = true := decide_eq_true h
theorem intGteb_false {a b : Int} (h : ¬ a ≥ b) : intGteb a b = false := decide_eq_false h

theorem verdict_transfer_true {p q : Prop} (h : p = q) (hq : q) : p :=
  h ▸ hq
theorem verdict_transfer_false {p q : Prop} (h : p = q) (hnq : ¬q) :
    ¬p := h ▸ hnq

theorem bool_ne_false_of_true {b : Bool} (h : b = true) :
    ¬ b = false := by simp [h]
theorem bool_ne_true_of_false {b : Bool} (h : b = false) :
    ¬ b = true := by simp [h]

/-! decide-shape bridges (the outer-tower lane). -/

theorem decide_not_false {p : Prop} [Decidable p] (h : p) :
    ¬ (decide p = false) := by simp [decide_eq_true h]

theorem decide_not_true {p : Prop} [Decidable p] (h : ¬p) :
    ¬ (decide p = true) := by simp [decide_eq_false h]

/-! Symbol-comparator bridges (the env-lookup lane; the captured
    comparator is Kit/Map's `symCmpO`). -/

theorem symCmpO_ne_num {d1 d2 : String} {n1 n2 : Nat}
    {sd1 sd2 : symbol_description} (hd : d1 = d2) (h : n1 ≠ n2) :
    ¬ RelSem.Kit.symCmpO (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
      = .eq := by
  subst hd
  exact fun hc =>
    h ((RelSem.Kit.symCmpO_eq_iff d1 d1 n1 n2 sd1 sd2).mp hc).2

theorem symCmpO_eq_same (d : String) (n : Nat)
    (sd1 sd2 : symbol_description) :
    RelSem.Kit.symCmpO (Symbol d n sd1) (Symbol d n sd2) = .eq :=
  (RelSem.Kit.symCmpO_eq_iff d d n n sd1 sd2).mpr ⟨rfl, rfl⟩

/-! `Int.NonNeg` bridges (omega treats `NonNeg` as an opaque atom —
    measured; route through `0 ≤ a`, which is `NonNeg (a - 0)`
    definitionally). -/

theorem int_nonneg_of_le {a : Int} (h : 0 ≤ a) : a.NonNeg := by
  have h' : Int.NonNeg (a - 0) := h
  simpa using h'

theorem int_not_nonneg_of_lt {a : Int} (h : a < 0) : ¬ a.NonNeg :=
  fun hn => by
    have h' : (0 : Int) ≤ a := by
      have : Int.NonNeg (a - 0) := by simpa using hn
      exact this
    omega

/-- Speculative tactic proof of `goal` (omega); state fully restored
    on failure (messages included — a failed attempt must not poison
    the log). -/
def tryOmegaProof (goal : Expr) : TermElabM (Option Expr) := do
  let s ← saveState
  try
    let pf ← Term.withoutErrToSorry do
      let pf ← Term.elabTermEnsuringType (← `(by omega)) goal
      Term.synthesizeSyntheticMVarsNoPostponing
      instantiateMVars pf
    if pf.hasSorry || pf.hasExprMVar then
      s.restore
      return none
    return some pf
  catch _ =>
    s.restore
    return none

/-- Ground verdict by the S0 kernel-decide contract (donor pattern:
    synthesize, whnf at `.all` — attribute-blind, so fence-stuck
    ground comparisons resolve here — demand a literal, emit
    `of_decide_eq_true/false` + `Eq.refl`; the kernel recomputes at
    addDecl). -/
def kernelVerdict (p : Expr) : TermElabM (Option (Bool × Expr)) := do
  try
    let inst ← synthInstance (mkApp (mkConst ``Decidable) p)
    let r ← withTransparency .all <| whnf (mkApp2 (mkConst ``decide) p inst)
    if r.isConstOf ``Bool.true then
      return some (true, mkApp3 (mkConst ``of_decide_eq_true) p inst
        (mkApp2 (mkConst ``Eq.refl [1]) (mkConst ``Bool) (mkConst ``Bool.true)))
    if r.isConstOf ``Bool.false then
      return some (false, mkApp3 (mkConst ``of_decide_eq_false) p inst
        (mkApp2 (mkConst ``Eq.refl [1]) (mkConst ``Bool) (mkConst ``Bool.false)))
    return none
  catch _ => return none

/-- DEFEQ-PRESERVING refold of Int-primitive spellings into the
    notation vocabulary omega reads (measured: omega atomizes the raw
    op spellings — `Int.add x c > 0` fails where `x + c > 0`
    succeeds). Two folding layers, both definitional so a proof of
    the folded Prop kernel-checks at the original spelling:

    * op-constant spellings (`Int.add a b` → `a + b`; `subNatNat m n`
      ≡ `(↑m) - (↑n)` by delta/iota);
    * MATCHER spellings — whnf on a stuck operand smears an Int op
      through its constructor match (the round-18 dump: `match x,
      Int.ofNat c with | ofNat m, ofNat n => ofNat (m+n) | …`); a
      matcher app whose type is Int is probed by `isDefEq` against
      the candidate ops at its own scrutinees (both sides unfold to
      the same match, so the probe is cheap and exact). Post-order:
      scrutinees are already folded when the probe fires. -/
def foldArith (e : Expr) : MetaM Expr :=
  Core.transform e (post := fun n => do
    -- nodes under binders carry loose bvars — type inference (mkAppM)
    -- cannot run there; leave them as spelled
    if n.hasLooseBVars then return .done n
    let fn := n.getAppFn
    let .const c _ := fn | return .done n
    let args := n.getAppArgs
    let fold2 (f : Name) : MetaM TransformStep := do
      if args.size == 2 then
        return .done (← mkAppMU f #[args[0]!, args[1]!])
      return .done n
    if c == ``Int.ofNat && args.size == 1 then
      -- omega atomizes raw `Int.ofNat` (measured: literal AND cast
      -- forms); refold to the OfNat/Nat.cast notation it reads
      match args[0]! with
      | .lit (.natVal _) =>
        return .done (← mkAppOptMU ``OfNat.ofNat
          #[some (mkConst ``Int), some args[0]!, none])
      | _ =>
        return .done (← mkAppOptMU ``Nat.cast
          #[some (mkConst ``Int), none, some args[0]!])
    else if c == ``Int.add then fold2 ``HAdd.hAdd
    else if c == ``Int.sub then fold2 ``HSub.hSub
    else if c == ``Int.mul then fold2 ``HMul.hMul
    else if c == ``Int.ediv then fold2 ``HDiv.hDiv
    else if c == ``Int.emod then fold2 ``HMod.hMod
    else if c == ``Int.lt then fold2 ``LT.lt
    else if c == ``Int.le then fold2 ``LE.le
    else if c == ``Nat.lt then fold2 ``LT.lt
    else if c == ``Nat.le then fold2 ``LE.le
    else if c == ``Int.neg && args.size == 1 then
      return .done (← mkAppMU ``Neg.neg #[args[0]!])
    else if c == ``Int.negOfNat && args.size == 1 then
      return .done (← mkAppMU ``Neg.neg
        #[mkApp (mkConst ``Int.ofNat) args[0]!])
    else if c == ``Int.subNatNat && args.size == 2 then
      return .done (← mkAppMU ``HSub.hSub
        #[mkApp (mkConst ``Int.ofNat) args[0]!,
          mkApp (mkConst ``Int.ofNat) args[1]!])
    else if isMatcherAppCore (← getEnv) n then
      -- matcher refold: probe Int-typed matcher apps against the op
      -- table at their own scrutinees
      let ty ← whnf (← inferType n)
      unless ty.isConstOf ``Int do return .done n
      let some ma ← Lean.Meta.matchMatcherApp? n | return .done n
      let discrs := ma.discrs
      let mut allInt := true
      for dsc in discrs do
        unless (← whnf (← inferType dsc)).isConstOf ``Int do
          allInt := false
      unless allInt do return .done n
      let cands : Array Expr ← do
        if discrs.size == 2 then
          pure #[← mkAppMU ``HAdd.hAdd #[discrs[0]!, discrs[1]!],
                 ← mkAppMU ``HSub.hSub #[discrs[0]!, discrs[1]!],
                 ← mkAppMU ``HMul.hMul #[discrs[0]!, discrs[1]!]]
        else if discrs.size == 1 then
          pure #[← mkAppMU ``Neg.neg #[discrs[0]!]]
        else pure #[]
      for cand in cands do
        if ← withNewMCtxDepth (isDefEq n cand) then
          return .done cand
      return .done n
    else return .done n)

/-- Open-case verdict: omega on `p`, then on `¬p`. -/
def openVerdict (p : Expr) : TermElabM (Option (Bool × Expr)) := do
  if let some pf ← tryOmegaProof p then return some (true, pf)
  if let some pf ← tryOmegaProof (mkApp (mkConst ``Not) p) then
    return some (false, pf)
  return none

/-- The Bool-head prop table (shared by the Bool lane and the
    decide-shape lane's registry-scrutinee case): head constant ↦
    (relational Prop, true-bridge, false-bridge).

    ENGINE-TO-LAW RESIDUE (arc-18 C1, recorded): this table and the
    symCmpO bridge pair below are the one surviving hardcoded law
    map in the engine. The bridges are proof-layer constants defined
    IN this module (adjacent to their lane, not Kit laws), and the
    table also DERIVES each bridge's relational Prop — a
    registry-query version needs premise-instantiation machinery the
    arc-19 search will build anyway (its side-condition tracing wants
    exactly that). Registered follow-up, priced S; the C1 record's
    sweep table carries the entry. New bridge heads still register
    fail-closed here (an unlisted head mints nothing and the
    consumer's frontier fires). -/
def boolHeadProp? (c : Name) (a b : Expr) :
    TermElabM (Option (Expr × Name × Name)) := do
  if c == ``Nat.ble then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.nat_ble_true, ``RelSem.RoundEval.nat_ble_false)
  else if c == ``Nat.blt then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.nat_blt_true, ``RelSem.RoundEval.nat_blt_false)
  else if c == ``Nat.beq then
    return some (← mkAppMU ``Eq #[a, b],
      ``RelSem.RoundEval.nat_beq_true, ``RelSem.RoundEval.nat_beq_false)
  else if c == ``natLtb then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.natLtb_true, ``RelSem.RoundEval.natLtb_false)
  else if c == ``natLteb then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.natLteb_true, ``RelSem.RoundEval.natLteb_false)
  else if c == ``natGteb then
    return some (← mkAppMU ``GE.ge #[a, b],
      ``RelSem.RoundEval.natGteb_true, ``RelSem.RoundEval.natGteb_false)
  else if c == ``intLtb then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.intLtb_true, ``RelSem.RoundEval.intLtb_false)
  else if c == ``intLteb then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.intLteb_true, ``RelSem.RoundEval.intLteb_false)
  else if c == ``intGtb then
    return some (← mkAppMU ``GT.gt #[a, b],
      ``RelSem.RoundEval.intGtb_true, ``RelSem.RoundEval.intGtb_false)
  else if c == ``intGteb then
    return some (← mkAppMU ``GE.ge #[a, b],
      ``RelSem.RoundEval.intGteb_true, ``RelSem.RoundEval.intGteb_false)
  else return none

/-- ITERATIVE BOOL-TOWER CLOSER (arc-17 S3): drive a stuck Bool term
    to a literal by alternating (scoped) whnf hops — bridged by
    kernel-deferred refls — with inner-decidable verdict
    substitutions — bridged by congrArg over the proof-irrelevance
    verdict — until a literal falls out. Returns `(lit, h : b = lit)`.
    The verdict search is passed in (breaks the mutual recursion with
    `propVerdict`). -/
partial def closeBoolTower
    (verdict : Expr → TermElabM (Option (Bool × Expr)))
    (b0 : Expr) (cdepth : Nat := 0) :
    TermElabM (Option (Expr × Expr)) := do
  if cdepth > 10 then return none
  let mut bCur := b0
  let mut chain : Option Expr := none   -- : b0 = bCur (syntactic)
  for _ in [0:32] do
    let bv ← (try withCurrHeartbeats (whnf bCur) catch _ => pure bCur)
    if bv != bCur then
      let br ← mkExpectedTypeHint (← mkEqRefl bv) (← mkEq bCur bv)
      chain := some (← match chain with
        | none => pure br
        | some c => mkEqTrans c br)
      bCur := bv
    if bCur.isConstOf ``Bool.true || bCur.isConstOf ``Bool.false then
      let hFin ← match chain with
        | some c => pure c
        | none => mkExpectedTypeHint (← mkEqRefl bCur) (← mkEq b0 bCur)
      return some (bCur, hFin)
    -- registry-headed towers close directly through the bridges
    -- (`BEq.beq` at Nat routes through the Nat.beq bridges — the
    -- conclusions are defeq, carried by the type hint below)
    let regArgs? : Option (Name × Expr × Expr) :=
      match bCur.getAppFn with
      | .const bc _ =>
        let args := bCur.getAppArgs
        if args.size == 2 then some (bc, args[0]!, args[1]!)
        else if bc == ``BEq.beq && args.size == 4
            && args[0]!.isConstOf ``Nat then
          some (``Nat.beq, args[2]!, args[3]!)
        else none
      | _ => none
    if let some (bc, aA, aB) := regArgs? then
        if let some (q0, brTrue, brFalse) ← boolHeadProp? bc aA aB then
          let q ← foldArith q0
          if let some (polq, pfq) ← verdict q then
            let hV ← if polq then mkAppMU brTrue #[pfq]
                     else mkAppMU brFalse #[pfq]
            let litE := if polq then mkConst ``Bool.true
                        else mkConst ``Bool.false
            let hV ← mkExpectedTypeHint hV (← mkEq bCur litE)
            let hFin ← match chain with
              | some c => mkEqTrans c hV
              | none => pure hV
            return some (litE, hFin)
          return none
    let mut progressed := false
    -- Bool.rec / Bool-matcher over a stuck scrutinee: close the
    -- scrutinee recursively and substitute (the race-check
    -- `Bool.rec (…) (…) ((fun x => …) (DA_pos …))` shape)
    let major? : Option Expr ← (do
      if bCur.isAppOf ``Bool.rec && bCur.getAppArgs.size ≥ 1 then
        return some bCur.getAppArgs.back!
      if let some ma ← Lean.Meta.matchMatcherApp? bCur then
        if ma.discrs.size ≥ 1 then
          let dsc := ma.discrs[0]!
          let tyD ← whnfU (← inferType dsc)
          if tyD.isConstOf ``Bool then return some dsc
      return none)
    if let some major := major? then
      unless major.isConstOf ``Bool.true
          || major.isConstOf ``Bool.false do
        let step? ← (try
          (do
            let some (lit', hSub) ←
                closeBoolTower verdict major (cdepth + 1) | return none
            let abst ← abstractExact bCur major
            unless abst.hasLooseBVars do return none
            let bNext := abst.instantiate1 lit'
            let motive := Lean.mkLambda `x .default
              (← inferType major) abst
            let piece ← mkExpectedTypeHint (← mkCongrArg motive hSub)
              (← mkEq bCur bNext)
            return some (bNext, piece)
            : TermElabM (Option (Expr × Expr)))
          catch _ => pure none)
        if let some (bNext, piece) := step? then
          chain := some (← match chain with
            | none => pure piece
            | some c => mkEqTrans c piece)
          bCur := bNext
          progressed := true
    -- find an inner stuck decidable and substitute its verdict
    let inners ← collectMintCands bCur
    for d' in inners do
      if progressed then continue
      if d' == bCur then continue
      if d'.isAppOf ``Decidable.isTrue
          || d'.isAppOf ``Decidable.isFalse then continue
      let step? ← (try
        (do
          let tyW' ← whnfU (← inferType d')
          let mut sub? : Option (Expr × Expr) := none  -- (vTerm, hIn)
          if tyW'.isAppOfArity ``Decidable 1 then
            let q' ← foldArith (← withCurrHeartbeats
              (groundNorm "inner prop" tyW'.appArg!))
            if !(q'.hasExprMVar || q'.hasLooseBVars) then
            if let some (polq, pfq) ← verdict q' then
              let vTerm := if polq then
                  mkApp2 (mkConst ``Decidable.isTrue) q' pfq
                else mkApp2 (mkConst ``Decidable.isFalse) q' pfq
              let hIn := if polq then
                  mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue)
                    q' pfq d'
                else mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse)
                    q' pfq d'
              sub? := some (vTerm, hIn)
          else if tyW'.isConstOf ``Bool && d'.isApp then
            -- Bool-typed inner tower: close recursively
            if let some (lit', hSub) ←
                closeBoolTower verdict d' (cdepth + 1) then
              sub? := some (lit', hSub)
          if sub?.isNone then
            trace[RelSem.roundEval] "closeBoolTower: inner {d'.getAppFn} no verdict"
          let some (vTerm, hIn) := sub? | return none
          -- self-insertion guard (the mintEmit drip lesson)
          if (vTerm.find? (· == d')).isSome then return none
          let abst ← abstractExact bCur d'
          unless abst.hasLooseBVars do return none
          let bNext := abst.instantiate1 vTerm
          let motive := Lean.mkLambda `x .default (← inferType d') abst
          let piece ← mkExpectedTypeHint (← mkCongrArg motive hIn)
            (← mkEq bCur bNext)
          return some (bNext, piece)
          : TermElabM (Option (Expr × Expr)))
        catch ex => (do
          trace[RelSem.roundEval] "closeBoolTower: inner {d'.getAppFn} threw: {ex.toMessageData}"
          pure none))
      if let some (bNext, piece) := step? then
        trace[RelSem.roundEval] "closeBoolTower: subst {d'.getAppFn} ({← bCur.numObjs} → {← bNext.numObjs} objs)"
        chain := some (← match chain with
          | none => pure piece
          | some c => mkEqTrans c piece)
        bCur := bNext
        progressed := true
    unless progressed do
      -- last resort: the DIG hop (smart-unfolding-off `.all` whnf)
      -- exposes towers hidden inside folded definitions; a defeq hop
      let r ← (try
          withCurrHeartbeats <|
            withOptions (fun o => o.set `smartUnfolding false) <|
              withTransparency .all (whnf bCur)
        catch _ => pure bCur)
      if r != bCur then
        let br ← mkExpectedTypeHint (← mkEqRefl r) (← mkEq bCur r)
        chain := some (← match chain with
          | none => pure br
          | some c => mkEqTrans c br)
        bCur := r
      else
        trace[RelSem.roundEval] "closeBoolTower: stuck ({← bCur.numObjs} objs, head {bCur.getAppFn}):{indentExpr bCur}"
        return none
  trace[RelSem.roundEval] "closeBoolTower: fuel out"
  return none

/-- THE PROP-VERDICT SEARCH (shared by the decidable and decide-shape
    lanes; recursion depth-capped). Lanes: `Int.NonNeg` (omega-opaque;
    bridged through `0 ≤ a`); `decide q = true/false` (the tower
    OVER a decide — its truth reduces to `q`'s, and minting it
    substitutes the whole dependent cluster ATOMICALLY, which the
    type-check guard demands); open omega; ground kernel decide. -/
partial def propVerdict (p : Expr) (depth : Nat := 0) :
    TermElabM (Option (Bool × Expr)) := do
  if depth > 10 then return none
  -- syntactic-refl fast path (a = a): omega's certificate for a
  -- reflexive equality can embed the enclosing tower (measured drip);
  -- Eq.refl is the clean witness
  if let some (_, a, b) := p.eq? then
    if a == b then
      return some (true, ← mkEqRefl a)
  -- Int.NonNeg face
  if p.isAppOfArity ``Int.NonNeg 1 then
    let a := p.appArg!
    let zero ← mkAppOptMU ``OfNat.ofNat
      #[some (mkConst ``Int), some (mkRawNatLit 0), none]
    if let some pf ← tryOmegaProof (← mkAppMU ``LE.le #[zero, a]) then
      return some (true,
        ← mkAppMU ``RelSem.RoundEval.int_nonneg_of_le #[pf])
    if let some pf ← tryOmegaProof (← mkAppMU ``LT.lt #[a, zero]) then
      return some (false,
        ← mkAppMU ``RelSem.RoundEval.int_not_nonneg_of_lt #[pf])
    return none
  -- decide-shape face: p = (decide q inst = lit) with the decide
  -- possibly in its unfolded Decidable.rec spelling
  if p.isAppOfArity ``Eq 3 then
    let args := p.getAppArgs
    if args[0]!.isConstOf ``Bool then
      let b := args[1]!
      let lit := args[2]!
      let litT := lit.isConstOf ``Bool.true
      let litF := lit.isConstOf ``Bool.false
      -- closed props go to the kernel lane below
      if (litT || litF) && p.hasFVar then
        -- unwrap IDENTITY matcher debris (`match X with | false =>
        -- false | true => true` from unfolded decide towers): a
        -- single-discr matcher defeq to its own discriminant IS its
        -- discriminant (isDefEq-probed, exact)
        let mut b := b
        for _ in [0:4] do
          let stop ← (do
            if let some ma ← Lean.Meta.matchMatcherApp? b then
              if ma.discrs.size == 1 then
                if ← withNewMCtxDepth
                    (withCurrHeartbeats (isDefEq b ma.discrs[0]!)) then
                  return some ma.discrs[0]!
            return none)
          match stop with
          | some d' => b := d'
          | none => break
        -- registry-headed scrutinee: `(intLteb a b) = lit`-class
        if let .const bc _ := b.getAppFn then
          if b.getAppArgs.size == 2 then
            if let some (q0, brTrue, brFalse) ← boolHeadProp? bc
                b.getAppArgs[0]! b.getAppArgs[1]! then
              let q ← foldArith q0
              if let some (polq, pfq) ← propVerdict q (depth + 1) then
                if polq then
                  let hbt ← mkAppMU brTrue #[pfq]  -- b = true
                  if litT then return some (true, hbt)
                  else return some (false, ← mkAppMU
                    ``RelSem.RoundEval.bool_ne_false_of_true #[hbt])
                else
                  let hbf ← mkAppMU brFalse #[pfq]  -- b = false
                  if litF then return some (true, hbf)
                  else return some (false, ← mkAppMU
                    ``RelSem.RoundEval.bool_ne_true_of_false #[hbf])
              return none
        let qi? : Option (Expr × Expr) ← (do
          if b.isAppOfArity ``decide 2 then
            return some (b.getAppArgs[0]!, b.getAppArgs[1]!)
          if b.isAppOf ``Decidable.rec && b.getAppArgs.size ≥ 1 then
            let major := b.getAppArgs.back!
            let mty ← whnfU (← inferType major)
            if mty.isAppOfArity ``Decidable 1 then
              return some (mty.appArg!, major)
          return none)
        if let some (q0, inst) := qi? then
          let q ← foldArith q0
          if let some (polq, pfq) ← propVerdict q (depth + 1) then
            -- b = true iff q; combine with the literal
            let mk (f : Name) (pf : Expr) : TermElabM Expr :=
              mkAppOptMU f #[some q, some inst, some pf]
            if polq && litT then
              return some (true, ← mk ``decide_eq_true pfq)
            if polq && litF then
              return some (false,
                ← mk ``RelSem.RoundEval.decide_not_false pfq)
            if !polq && litT then
              return some (false,
                ← mk ``RelSem.RoundEval.decide_not_true pfq)
            if !polq && litF then
              return some (true, ← mk ``decide_eq_false pfq)
          return none
        -- ITERATIVE TOWER CLOSURE (arc-17 S3): drive b to a literal
        match ← closeBoolTower (fun q => propVerdict q (depth + 1)) b with
        | some (litE, hFull) =>
          let ok ← (try
              withCurrHeartbeats (check hFull)
              pure true
            catch _ => pure false)
          if ok then
            let bvT := litE.isConstOf ``Bool.true
            if bvT == litT then
              return some (true, hFull)
            else if litT then
              return some (false, ← mkAppMU
                ``RelSem.RoundEval.bool_ne_true_of_false #[hFull])
            else
              return some (false, ← mkAppMU
                ``RelSem.RoundEval.bool_ne_false_of_true #[hFull])
        | none => pure ()
        return none
  match ← (if p.hasFVar then openVerdict p else kernelVerdict p) with
  | some r => return some r
  | none =>
  -- GENERALIZED INNER-VERDICT LANE (arc-17 S3): substitute the
  -- innermost stuck decidable's verdict INTO THE PROP, recurse, and
  -- transfer through the congrArg equality (`p = p[d' := verdict]`)
  -- — the discovery's mixed race-check towers land here.
  if depth ≥ 8 then return none
  unless p.hasFVar do return none
  let inners ← collectMintCands p
  for d' in inners do
    if d'.isAppOf ``Decidable.isTrue
        || d'.isAppOf ``Decidable.isFalse then continue
    if d' == p then continue
    let r? ← (try
      (do
        let tyW' ← whnfU (← inferType d')
        unless tyW'.isAppOfArity ``Decidable 1 do return none
        let q' ← foldArith (← withCurrHeartbeats
          (groundNorm "inner prop" tyW'.appArg!))
        if q'.hasExprMVar || q'.hasLooseBVars then return none
        let some (polq, pfq) ← propVerdict q' (depth + 1) | return none
        let vTerm := if polq then
            mkApp2 (mkConst ``Decidable.isTrue) q' pfq
          else mkApp2 (mkConst ``Decidable.isFalse) q' pfq
        let abst ← abstractExact p d'
        unless abst.hasLooseBVars do return none
        let p' := abst.instantiate1 vTerm
        let hIn := if polq then
            mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue) q' pfq d'
          else mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse) q' pfq d'
        let motive := Lean.mkLambda `x .default (← inferType d') abst
        let hEq ← mkExpectedTypeHint (← mkCongrArg motive hIn)
          (← mkEq p p')
        let pNorm ← foldArith (← withCurrHeartbeats
          (groundNorm "subst prop" p'))
        let some (pol', pf') ← propVerdict pNorm (depth + 1)
          | return none
        withCurrHeartbeats (check hEq)
        if pol' then
          return some (true, ← mkAppOptMU
            ``RelSem.RoundEval.verdict_transfer_true
            #[some p, some p', some hEq, some pf'])
        else
          return some (false, ← mkAppOptMU
            ``RelSem.RoundEval.verdict_transfer_false
            #[some p, some p', some hEq, some pf'])
        : TermElabM (Option (Bool × Expr)))
      catch _ => pure none)
    if let some r := r? then return some r
  return none

end RoundEval
end RelSem
