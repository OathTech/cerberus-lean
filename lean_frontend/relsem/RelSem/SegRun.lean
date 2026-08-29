/-
  RelSem.SegRun — V2b (2026-08-28): BLOCK-FUSED SEGMENT RULES over the
  per-round assertion layer (infrastructure plan component H, first
  tranche; the mover for the V2 grind-shape finding).

  WHAT THIS FIXES (measured, V2 record §3): the per-round proof idiom
  is O(rounds × paths) generated text — one ~10–60-line `wpk_*`
  application per machine round (P01's proof file: 1,387 lines for a
  5-line C program; P02 was PARKED at 63–117 rounds × 4 paths). This
  module makes a straight-line RUN of rounds discharge as ONE
  application: the `SegStep` sequent composes per-round links by the
  Hoare sequence rule, every link rides ONE canonical resource context
  (`SegCtx`), and the cut-point stepper tactic (RelSem/SegStepper.lean)
  assembles the per-block chain from the registered round-equation
  supply. Engine content per program collapses from ~1 lemma
  application per round to ~1 fused fact per basic block.

  LINEAGE (canon-first, per mechanism):
  * Floyd 1967 cut points / Hoare 1969 sequence rule — `SegStep.trans`
    IS the sequence rule at the round-granular WP; blocks end at the
    cut points (branches, terminal), where `wpk_case_*` /
    `segstep_done` take over.
  * The canonical resource context — Lithium's context discipline
    (deps/refinedc/theories/lithium: goals carry a normal-form
    context, rules never reassociate): `SegCtx` fixes ONE ∗-order
    (ctl, supplies, dom-ledger, env cells, memory residual, alloc
    fragments, byte ranges), so composition needs no BI permutation;
    cell access is by the once-proved `envCells_focus` accessor
    (bigSepL_lookup_acc shape, Iris BigOp lineage).
  * The per-link rules delegate to the V1/V2 `wpk_*` state rules
    (CerbStateWP/CerbStateStep) — the escalation ladder's floor is
    unchanged: every stride a `SegStep` chain takes is one registered
    wpk rule a hand proof can apply.
  * Fused birth legs: the four env-update obligations of a birth
    round (new/preserve/reverse/wf) are derived ONCE here from the
    Kit map laws + the domain ledger (`clsNone` reasoning), so a
    birth link's premises collapse to the round equation + the
    machine-insert spelling + ledger freshness.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.CerbStateStep
import RelSem.PerStepPeel
import RelSem.SegReg

set_option autoImplicit false

namespace RelSem.Seg

open RelSem RelSem.Cerb RelSem.CerbSt
open Iris Iris.BI Iris.ProgramLogic

variable {GF : BundledGFunctors}

/-! ## §1 The canonical resource context -/

/-- Env cells at full fraction (the locals the run has born). -/
@[reducible] def envCells [CerbStGS GF] : List (sym × value) → IProp GF
  | [] => iprop(emp)
  | (x, v) :: rest => iprop(envIs x (.own 1) v ∗ envCells rest)

/-- Allocation fragments at full fraction. -/
@[reducible] def allocCells [CerbStGS GF] :
    List (Int × CerbMem.Allocation) → IProp GF
  | [] => iprop(emp)
  | (aid, al) :: rest => iprop(allocIs aid (.own 1) al ∗ allocCells rest)

/-- Byte-range fragments at full fraction. -/
@[reducible] def byteCells [CerbStGS GF] :
    List (Int × List CerbMem.AbsByte) → IProp GF
  | [] => iprop(emp)
  | (a, bs) :: rest => iprop(pointsToBytes a (.own 1) bs ∗ byteCells rest)

/-- The domain-ledger image of an env-cell list (births cons cells
    and ledger entries in lockstep, so the ledger is DERIVED). -/
@[reducible] def domOf (env : List (sym × value)) : List Int :=
  env.map (fun c => symNum c.1)

/-- THE CANONICAL SEGMENT CONTEXT (Lithium-lineage normal form): one
    fixed ∗-order carrying everything a body segment owns. Links
    consume and produce THIS shape only — composition never
    reassociates. -/
@[reducible] def SegCtx [CerbStGS GF] (c : driver_state) (S : Supplies)
    (env : List (sym × value)) (mr : CerbMem.MemState)
    (al : List (Int × CerbMem.Allocation))
    (bs : List (Int × List CerbMem.AbsByte)) : IProp GF :=
  iprop(ctlIs stHalf c ∗ supIs stHalf S ∗ domIs stHalf (domOf env) ∗
    envCells env ∗ mrestIs stHalf mr ∗ allocCells al ∗ byteCells bs)

/-- Focus one env cell (the accessor, ⊣⊢ both ways — proved once;
    `bigSepL_lookup_acc` shape). -/
theorem envCells_focus [CerbStGS GF] :
    ∀ {env : List (sym × value)} {i : Nat} {x : sym} {vx : value},
    env[i]? = some (x, vx) →
    (envCells env : IProp GF) ⊣⊢
      envIs x (.own 1) vx ∗ envCells (env.eraseIdx i)
  | [], i, _, _, h => by simp at h
  | (y, vy) :: rest, 0, x, vx, h => by
    obtain ⟨rfl, rfl⟩ : y = x ∧ vy = vx := by simpa using h
    exact .rfl
  | (y, vy) :: rest, i + 1, x, vx, h => by
    have hrest : rest[i]? = some (x, vx) := by simpa using h
    calc (envCells ((y, vy) :: rest) : IProp GF)
        ⊣⊢ envIs y (.own 1) vy ∗ envCells rest := .rfl
      _ ⊣⊢ envIs y (.own 1) vy ∗
            (envIs x (.own 1) vx ∗ envCells (rest.eraseIdx i)) :=
          sep_congr .rfl (envCells_focus hrest)
      _ ⊣⊢ envIs x (.own 1) vx ∗
            (envIs y (.own 1) vy ∗ envCells (rest.eraseIdx i)) :=
          sep_left_comm

/-- Focus one allocation fragment. -/
theorem allocCells_focus [CerbStGS GF] :
    ∀ {al : List (Int × CerbMem.Allocation)} {j : Nat} {aid : Int}
      {a : CerbMem.Allocation},
    al[j]? = some (aid, a) →
    (allocCells al : IProp GF) ⊣⊢
      allocIs aid (.own 1) a ∗ allocCells (al.eraseIdx j)
  | [], j, _, _, h => by simp at h
  | (i0, a0) :: rest, 0, aid, a, h => by
    obtain ⟨rfl, rfl⟩ : i0 = aid ∧ a0 = a := by simpa using h
    exact .rfl
  | e :: rest, j + 1, aid, a, h => by
    have hrest : rest[j]? = some (aid, a) := by simpa using h
    calc (allocCells (e :: rest) : IProp GF)
        ⊣⊢ allocIs e.1 (.own 1) e.2 ∗ allocCells rest := by
          cases e; exact .rfl
      _ ⊣⊢ allocIs e.1 (.own 1) e.2 ∗
            (allocIs aid (.own 1) a ∗ allocCells (rest.eraseIdx j)) :=
          sep_congr .rfl (allocCells_focus hrest)
      _ ⊣⊢ allocIs aid (.own 1) a ∗
            (allocIs e.1 (.own 1) e.2 ∗ allocCells (rest.eraseIdx j)) :=
          sep_left_comm

/-- Focus one byte range. -/
theorem byteCells_focus [CerbStGS GF] :
    ∀ {bs : List (Int × List CerbMem.AbsByte)} {j : Nat} {a : Int}
      {b : List CerbMem.AbsByte},
    bs[j]? = some (a, b) →
    (byteCells bs : IProp GF) ⊣⊢
      pointsToBytes a (.own 1) b ∗ byteCells (bs.eraseIdx j)
  | [], j, _, _, h => by simp at h
  | (a0, b0) :: rest, 0, a, b, h => by
    obtain ⟨rfl, rfl⟩ : a0 = a ∧ b0 = b := by simpa using h
    exact .rfl
  | e :: rest, j + 1, a, b, h => by
    have hrest : rest[j]? = some (a, b) := by simpa using h
    calc (byteCells (e :: rest) : IProp GF)
        ⊣⊢ pointsToBytes e.1 (.own 1) e.2 ∗ byteCells rest := by
          cases e; exact .rfl
      _ ⊣⊢ pointsToBytes e.1 (.own 1) e.2 ∗
            (pointsToBytes a (.own 1) b ∗ byteCells (rest.eraseIdx j)) :=
          sep_congr .rfl (byteCells_focus hrest)
      _ ⊣⊢ pointsToBytes a (.own 1) b ∗
            (pointsToBytes e.1 (.own 1) e.2 ∗
              byteCells (rest.eraseIdx j)) :=
          sep_left_comm

/-! ## §2 The segment sequent -/

/-- THE CONTEXT RECORD: the canonical context's components as DATA —
    the sequent below is indexed by records, so chain composition
    unifies FIRST-ORDER (constructor against constructor), never
    through the assertion. -/
structure Ctx where
  c : driver_state
  S : Supplies
  env : List (sym × value)
  mr : CerbMem.MemState
  al : List (Int × CerbMem.Allocation)
  bs : List (Int × List CerbMem.AbsByte)

/-- The context's assertion. -/
@[reducible] def Ctx.interp [CerbStGS GF] (Γ : Ctx) : IProp GF :=
  SegCtx Γ.c Γ.S Γ.env Γ.mr Γ.al Γ.bs

/-- THE SEGMENT SEQUENT: `n` scheduler rounds of the peeled dnms loop
    transform context `Γ` into `Δ` — stated as a WP transformer so
    per-block facts discharge the goal in ONE application. The fuel is
    split `F = f + n` (the caller supplies the literal split, so
    Nat-literal goals unify without add-inversion). -/
def SegStep [CerbStGS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (tid : Nat) (n : Nat) (Γ Δ : Ctx) : Prop :=
  ∀ (F f : Nat), F = f + n →
    ∀ (acc : Fmap thread_id (List core_step2)) (xs' : List Nat)
      (k : Fmap thread_id (List core_step2) → KDriveExpr)
      (s : Stuckness) (E : CoPset) (Φ : DriveVal → IProp GF),
    Ctx.interp (GF := GF) Γ ∗
        (Ctx.interp Δ -∗
          WP (dnmsK tagDefs f acc tid xs' k) @ s ; E {{ Φ }}) ⊢
      WP (dnmsK tagDefs F acc tid xs' k) @ s ; E {{ Φ }}

namespace SegStep

variable [CerbStGS GF]
variable {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
variable {tid : Nat}

/-- The empty segment. -/
theorem refl {Γ : Ctx} : SegStep (GF := GF) tagDefs tid 0 Γ Γ := by
  intro F f hF acc xs' k s E Φ
  have : F = f := by omega
  subst this
  exact wand_elim_right

/-- SEGMENTS COMPOSE (the Hoare sequence rule; round counts add). -/
theorem trans {n m : Nat} {Γ Δ Θ : Ctx}
    (h₁ : SegStep (GF := GF) tagDefs tid n Γ Δ)
    (h₂ : SegStep (GF := GF) tagDefs tid m Δ Θ) :
    SegStep (GF := GF) tagDefs tid (n + m) Γ Θ := by
  intro F f hF acc xs' k s E Φ
  refine (sep_mono_right (BI.wand_intro ?_)).trans
    (h₁ F (f + m) (by omega) acc xs' k s E Φ)
  exact (sep_comm.1.trans (h₂ (f + m) f rfl acc xs' k s E Φ))

/-- CONSUME a segment fact at the goal (the one-application face the
    proofs and the stepper use). -/
theorem consume {n : Nat} {Γ Δ : Ctx}
    (h : SegStep (GF := GF) tagDefs tid n Γ Δ)
    {F f : Nat} (hF : F = f + n)
    {acc : Fmap thread_id (List core_step2)} {xs' : List Nat}
    {k : Fmap thread_id (List core_step2) → KDriveExpr}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hcont : Ctx.interp (GF := GF) Δ ⊢
      WP (dnmsK tagDefs f acc tid xs' k) @ s ; E {{ Φ }}) :
    Ctx.interp (GF := GF) Γ ⊢
      WP (dnmsK tagDefs F acc tid xs' k) @ s ; E {{ Φ }} := by
  refine (sep_emp.2.trans (sep_mono_right ?_)).trans
    (h F f hF acc xs' k s E Φ)
  exact BI.wand_intro (emp_sep.1.trans hcont)

end SegStep

/-! ## §3 The standard family pack

    Every fixture family (`t1fam`, `p01fam`, …) is a builder over ONE
    pack shape: the top env frame + the four supplies + the layout.
    The link rules below are generic over the builder; the fixture's
    shape facts (`thread0Env = [p.f₁]` etc.) enter as `rfl` premises. -/

/-- The family parameter pack (T1P re-homed — the fixture alias
    `T1P := Seg.Pack` keeps the V2 engine rooms word-for-word). -/
structure Pack where
  f₁ : Fmap sym value
  tS : Nat
  aS : Nat
  eS : Nat
  sS : Nat
  ls : CerbMem.MemState

/-- The generic pack projection (`t1Proj` re-homed; program-blind —
    reads the pack fields off any driver state). -/
@[reducible] def packProj (σ : driver_state) : Pack :=
  { f₁ := (match σ.core_state0.thread_states with
      | (_, (_, th)) :: _ =>
        (match th.env with | f :: _ => f | [] => fmapEmpty)
      | [] => fmapEmpty),
    tS := σ.core_run_state0.tid_supply,
    aS := σ.core_run_state0.aid_supply,
    eS := σ.core_run_state0.excluded_supply,
    sS := σ.core_run_state0.sym_supply,
    ls := σ.layout_state }

/-- The action-id bump (what a memory-action round draws). -/
@[reducible] def bumpA (S : Supplies) : Supplies :=
  { S with aid := S.aid + 1 }

/-- Freshness-refutation helpers (the stepper's ledger discharge —
    membership refuted structurally; `Decidable (a ∈ l)` is absent in
    this prelude, `Decidable (a = b)` at `Int` is kernel-decidable). -/
theorem not_mem_nil_int (a : Int) : ¬ a ∈ ([] : List Int) :=
  fun h => nomatch h

theorem not_mem_cons_of {a b : Int} {l : List Int}
    (h1 : a ≠ b) (h2 : ¬ a ∈ l) : ¬ a ∈ b :: l := by
  intro h
  cases h with
  | head => exact h1 rfl
  | tail _ h => exact h2 h

/-- Frame well-formedness off the single-frame shape fact. -/
theorem wfFrame_of {σ : driver_state} {f : Fmap sym value}
    (hth : thread0Env σ = [f]) (hwf : EnvWf σ) : EnvWfFrame f :=
  hwf f (by rw [hth]; exact List.Mem.head _)

/-- Env well-formedness from the single frame. -/
theorem envWf_of_frame {σ : driver_state} {f : Fmap sym value}
    (hth : thread0Env σ = [f]) (hf : EnvWfFrame f) : EnvWf σ := by
  intro fr hfr
  rw [hth] at hfr
  cases hfr with
  | head => exact hf
  | tail _ h => cases h

/-- The ledger fact at the frame. -/
theorem envDom_frame {σ : driver_state} {f : Fmap sym value}
    {d : List Int} (hth : thread0Env σ = [f]) (hdm : EnvDom σ d) :
    ∀ z v, lookup_env z [f] = some v → symNum z ∈ d :=
  fun z v hz => hdm z v (by
    show lookup_env z (thread0Env σ) = some v
    rw [hth]; exact hz)

/-! ## §4 Birth legs (T1/P01 engine legs PROMOTED to the engine home —
    the V2 record's "promoted to a Kit home when a second program
    consumes them"; sources: T1Rounds birth_*, P01Rounds dbl_*/clsNone,
    carried verbatim modulo the shared `ins` notation). -/

/-- The machine binds' insert spelling. -/
local notation "ins" => @fmapAddBy sym value Lem_Map.instBEqOfMapKeyType
  (@Lem_Map.mapKeyCompare sym _)

theorem symCmpO_refl (z : sym) : RelSem.Kit.symCmpO z z = .eq := by
  obtain ⟨d, n, sd⟩ := z
  exact (RelSem.Kit.symCmpO_eq_iff d d n n sd sd).2 ⟨rfl, rfl⟩

theorem mapKeyCompare_is_symCmpO :
    lemCmpToOrd (@Lem_Map.mapKeyCompare sym _) = RelSem.Kit.symCmpO :=
  rfl

section BirthLegs

variable {b b₁ b₂ : sym} {v v₁ v₂ : value} {f : Fmap sym value}

/-- Birth NEW: the just-bound cell reads back (T1Rounds birth_new,
    verbatim). -/
theorem birth_new (hb : EnvWfFrame f) :
    lookup_env b [ins b v f] = some v := by
  rw [show lookup_env b [ins b v f]
    = fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b (ins b v f) from by
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b
        (ins b v f) <;>
      simp [lookup_env, h]]
  cases hb with
  | inl he =>
    subst he
    exact @RelSem.Kit.fmapLookupBy_addBy_empty_eq sym value
      Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
      (@Lem_Map.mapKeyCompare sym _) RelSem.Kit.instTransCmpSymCmpO
      b b v (by rw [mapKeyCompare_is_symCmpO]; exact
        symCmpO_refl b)
  | inr hbuilt =>
    exact @RelSem.Kit.fmapLookupBy_addBy_eq sym value
      Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
      RelSem.Kit.instTransCmpSymCmpO _ _ b b v f hbuilt
      (symCmpO_refl b)

/-- Birth PRESERVE (the born symbol's cmp-class is unbound;
    T1Rounds birth_pres, verbatim). -/
theorem birth_pres (hb : EnvWfFrame f)
    (hsh : ∀ z : sym, RelSem.Kit.symCmpO b z = .eq →
      lookup_env z [f] = none) :
    ∀ z v', lookup_env z [f] = some v' →
      lookup_env z [ins b v f] = some v' := by
  intro z v' hz
  have hlk : ∀ (g : Fmap sym value) (w : Option value),
      (fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z g = w) →
      lookup_env z [g] = w := by
    intro g w hw
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z g <;>
      simp [lookup_env, h] <;> simp [h] at hw <;> exact hw
  have hzf : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z f
      = some v' := by
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z f
    · simp [lookup_env, h] at hz
    · simp [lookup_env, h] at hz; rw [hz]
  by_cases hcmp : RelSem.Kit.symCmpO b z = .eq
  · exact absurd (hsh z hcmp) (by rw [hz]; simp)
  · cases hb with
    | inl he =>
      subst he
      rw [show fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
          (Fmap.empty : Fmap sym value) = none from rfl] at hzf
      cases hzf
    | inr hbuilt =>
      refine hlk _ (some v') ?_
      rw [@RelSem.Kit.fmapLookupBy_addBy_ne sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hcmp]
      exact hzf

/-- Birth REVERSE (T1Rounds birth_rev, verbatim). -/
theorem birth_rev (hb : EnvWfFrame f) :
    ∀ z v', lookup_env z [ins b v f] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b := by
  intro z v' hz
  by_cases hcmp : RelSem.Kit.symCmpO b z = .eq
  · right
    obtain ⟨d1, n1, sd1⟩ := b
    obtain ⟨d2, n2, sd2⟩ := z
    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 d2 n1 n2
      sd1 sd2).1 hcmp
    simp [symNum, hn]
  · left
    have hzin : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
        (ins b v f) = some v' := by
      cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
          (ins b v f)
      · simp [lookup_env, h] at hz
      · simp [lookup_env, h] at hz; rw [hz]
    cases hb with
    | inl he =>
      subst he
      rw [show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl,
        @RelSem.Kit.fmapLookupBy_addBy_empty_ne sym value
          Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
          (@Lem_Map.mapKeyCompare sym _) RelSem.Kit.instTransCmpSymCmpO
          b z v (by rw [mapKeyCompare_is_symCmpO]; exact hcmp)] at hzin
      cases hzin
    | inr hbuilt =>
      rw [@RelSem.Kit.fmapLookupBy_addBy_ne sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hcmp] at hzin
      exact ⟨v', by simp [lookup_env, hzin]⟩

/-- Birth WF (T1Rounds birth_wfp, verbatim). -/
theorem birth_wfp (hb : EnvWfFrame f) : EnvWfFrame (ins b v f) := by
  cases hb with
  | inl he =>
    subst he
    exact Or.inr (by
      rw [← mapKeyCompare_is_symCmpO,
        show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl]
      exact @RelSem.Kit.fmapAddBy_built_empty sym value
        Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _)
        b v)
  | inr hbuilt =>
    exact Or.inr (@RelSem.Kit.fmapAddBy_built sym value
      Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
      (@Lem_Map.mapKeyCompare sym _) b v f hbuilt)

/-- REBIND preserve (V3a continuation — the label-jump rebind
    class): re-inserting a key at its CURRENT value changes no
    lookup. With `fmapLookupBy_congr` this is the "cmp-equal aliases"
    leg the V2 write rule anticipated. -/
theorem rebind_pres (hb : EnvWfFrame f)
    (hself : lookup_env b [f] = some v) :
    ∀ z, lookup_env z [ins b v f] = lookup_env z [f] := by
  intro z
  have hshim : ∀ (m : Fmap sym value), lookup_env z [m]
      = fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z m := by
    intro m
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z m <;>
      simp [lookup_env, h]
  have hshimb : lookup_env b [f]
      = fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b f := by
    cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b f <;>
      simp [lookup_env, h]
  have hbuilt : RelSem.Kit.FmapBuilt RelSem.Kit.symCmpO f := by
    cases hb with
    | inl he =>
      subst he
      rw [hshimb] at hself
      exact absurd hself (by
        rw [RelSem.Kit.fmapLookupBy_empty]; simp)
    | inr h => exact h
  by_cases hz : RelSem.Kit.symCmpO b z = .eq
  · have hzb : RelSem.Kit.symCmpO z b = .eq := by
      obtain ⟨d1, n1, s1⟩ := b
      obtain ⟨d2, n2, s2⟩ := z
      obtain ⟨hd, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 d2 n1 n2
        s1 s2).1 hz
      exact (RelSem.Kit.symCmpO_eq_iff d2 d1 n2 n1 s2 s1).2
        ⟨hd.symm, hn.symm⟩
    rw [hshim, hshim,
      @RelSem.Kit.fmapLookupBy_addBy_eq sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hz,
      @RelSem.Kit.fmapLookupBy_congr sym value
        Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
        RelSem.Kit.instTransCmpSymCmpO _ z b f hbuilt hzb,
      ← hshimb, hself]
  · rw [hshim, hshim]
    exact @RelSem.Kit.fmapLookupBy_addBy_ne sym value
      Lem_Map.instBEqOfMapKeyType RelSem.Kit.symCmpO
      RelSem.Kit.instTransCmpSymCmpO _ _ b z v f hbuilt hz

/-- Ledger-to-class emptiness (the `hsh` feeder). -/
theorem clsNone {d : List Int}
    (hdm : ∀ z v', lookup_env z [f] = some v' → symNum z ∈ d)
    (hfresh : symNum b ∉ d) :
    ∀ z : sym, RelSem.Kit.symCmpO b z = .eq →
      lookup_env z [f] = none := by
  intro z hz
  cases hlk : lookup_env z [f] with
  | none => rfl
  | some vz =>
    exfalso
    have hin := hdm z vz hlk
    obtain ⟨d1, n1, s1⟩ := b
    obtain ⟨dz, nz, sz⟩ := z
    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dz n1 nz
      s1 sz).1 hz
    apply hfresh
    rw [show symNum (Symbol d1 n1 s1) = ((n1 : Int)) from rfl, hn]
    exact hin

/-- Double-birth NEW₁. -/
theorem dbl_new₁ (hwf : EnvWfFrame f) :
    lookup_env b₁ [ins b₁ v₁ (ins b₂ v₂ f)] = some v₁ :=
  birth_new (birth_wfp hwf)

/-- Double-birth NEW₂. -/
theorem dbl_new₂ (hwf : EnvWfFrame f)
    (hn₁ : ∀ z : sym, RelSem.Kit.symCmpO b₁ z = .eq →
      lookup_env z [f] = none)
    (hnum_ne : symNum b₁ ≠ symNum b₂) :
    lookup_env b₂ [ins b₁ v₁ (ins b₂ v₂ f)] = some v₂ := by
  refine birth_pres (birth_wfp hwf) ?_ b₂ v₂ (birth_new hwf)
  intro z hz
  cases hlk : lookup_env z [ins b₂ v₂ f] with
  | none => rfl
  | some vz =>
    exfalso
    rcases birth_rev hwf z vz hlk with ⟨v₀, hv₀⟩ | hnum
    · rw [hn₁ z hz] at hv₀; cases hv₀
    · obtain ⟨d1, n1, s1⟩ := b₁
      obtain ⟨d2, n2, s2⟩ := b₂
      obtain ⟨dz, nz, sz⟩ := z
      obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dz n1 nz
        s1 sz).1 hz
      simp [symNum] at hnum hnum_ne
      omega

/-- Double-birth PRESERVE. -/
theorem dbl_pres (hwf : EnvWfFrame f)
    (hn₁ : ∀ z : sym, RelSem.Kit.symCmpO b₁ z = .eq →
      lookup_env z [f] = none)
    (hn₂ : ∀ z : sym, RelSem.Kit.symCmpO b₂ z = .eq →
      lookup_env z [f] = none)
    (hnum_ne : symNum b₁ ≠ symNum b₂) :
    ∀ z v', lookup_env z [f] = some v' →
      lookup_env z [ins b₁ v₁ (ins b₂ v₂ f)] = some v' := by
  intro z v' hz
  refine birth_pres (birth_wfp hwf) ?_ z v'
    (birth_pres hwf hn₂ z v' hz)
  intro w hw
  cases hlk : lookup_env w [ins b₂ v₂ f] with
  | none => rfl
  | some vw =>
    exfalso
    rcases birth_rev hwf w vw hlk with ⟨v₀, hv₀⟩ | hnum
    · rw [hn₁ w hw] at hv₀; cases hv₀
    · obtain ⟨d1, n1, s1⟩ := b₁
      obtain ⟨d2, n2, s2⟩ := b₂
      obtain ⟨dw, nw, sw⟩ := w
      obtain ⟨-, hnw⟩ := (RelSem.Kit.symCmpO_eq_iff d1 dw n1 nw
        s1 sw).1 hw
      simp [symNum] at hnum hnum_ne
      omega

/-- Double-birth REVERSE. -/
theorem dbl_rev (hwf : EnvWfFrame f) :
    ∀ z v', lookup_env z [ins b₁ v₁ (ins b₂ v₂ f)] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b₁ ∨
        symNum z = symNum b₂ := by
  intro z v' hz
  rcases birth_rev (birth_wfp hwf) z v' hz with ⟨v₀, hv₀⟩ | hnum
  · rcases birth_rev hwf z v₀ hv₀ with ⟨v₁', hv₁⟩ | hnum2
    · exact Or.inl ⟨v₁', hv₁⟩
    · exact Or.inr (Or.inr hnum2)
  · exact Or.inr (Or.inl hnum)

/-- Double-birth WF. -/
theorem dbl_wfp (hwf : EnvWfFrame f) :
    EnvWfFrame (ins b₁ v₁ (ins b₂ v₂ f)) :=
  birth_wfp (birth_wfp hwf)

end BirthLegs

/-! ## §5 The link rules — one `SegStep 1` intro per round class, all
    at the canonical context (composition is `SegStep.trans`, no
    reassociation). Every link delegates to the corresponding
    registered `wpk_*` state rule: the escalation ladder's floor. -/

section Links

variable [CerbStGS GF]
variable {td : Fmap sym (CerbLocation.Loc × tag_definition)} {tid : Nat}
variable {famI famO : Pack → driver_state} {cI cO : driver_state}
variable {S : Supplies} {env : List (sym × value)}
variable {mr : CerbMem.MemState}
variable {al : List (Int × CerbMem.Allocation)}
variable {bs : List (Int × List CerbMem.AbsByte)}

/-- Shape facts of a standard family builder (all `rfl` per fixture):
    the single env frame, the supplies, the layout, and the pack
    projection round-trip. -/
structure FamShape (fam : Pack → driver_state) : Prop where
  th : ∀ p, thread0Env (fam p) = [p.f₁]
  sup : ∀ p, suppliesOf (fam p) = ⟨p.tS, p.aS, p.eS, p.sS⟩
  lay : ∀ p, (fam p).layout_state = p.ls
  proj : ∀ p, packProj (fam p) = p

/-- TAU LINK: a round that moves only control (arena/trace/counter).
    Consumes the round equation; context otherwise unchanged. -/
@[step_law (kind := segLink) (variant := tau) (side := fed)
  (frontier := "seg/link-tau")
  (trace := "{law := link_ctl, joint := seg/link, hyps := [happ : fed(round eq)]}")
  (lineage := "Hoare sequence-rule link at the canonical segment context; delegates to wpk_seq_ctl_fam (tau round class)")]
theorem link_ctl
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP), famO p))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  iapply (wpk_seq_ctl_fam (GF := GF) (fam := famI)
    (upd := fun σ => famO (packProj σ)) (c' := cO)
    hinv
    (fun p hwf => by
      rw [hIn.proj p]; exact happ p (wfFrame_of (hIn.th p) hwf))
    (fun p _ => by rw [hIn.proj p]; exact hctlO p)
    (fun p _ => by rw [hIn.proj p, hOut.lay p, hIn.lay p])
    (fun p _ => by rw [hIn.proj p, hOut.sup p, hIn.sup p])
    (fun p _ => by rw [hIn.proj p, hOut.th p, hIn.th p]))
  isplitl [Hc]
  · iexact Hc
  iintro Hc
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- Env-lookup bridging (family level → frame level). -/
private theorem envLk_of {fam : Pack → driver_state} {p : Pack}
    {x : sym} {vx : value}
    (hth : thread0Env (fam p) = [p.f₁])
    (hx : envLookup (fam p) x = some vx) :
    lookup_env x [p.f₁] = some vx := by
  rw [show envLookup (fam p) x = lookup_env x (thread0Env (fam p))
    from rfl, hth] at hx
  exact hx

/-- ENV-READ LINK: a round characterized by one owned cell at a
    symbolic value (cell `i` of the context). -/
@[step_law (kind := segLink) (variant := env1) (side := fed)
  (frontier := "seg/link-env1")
  (trace := "{law := link_ctl_env1, joint := seg/link, hyps := [hcell : ground(index), happ : fed(round eq)]}")
  (lineage := "sequence-rule link with one focused env cell (envCells_focus accessor); delegates to wpk_seq_ctl_env1_fam")]
theorem link_ctl_env1 {i : Nat} {x : sym} {vx : value}
    (hcell : env[i]? = some (x, vx))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ → lookup_env x [p.f₁] = some vx →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP), famO p))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (envCells_focus hcell).1 $$ He with ⟨Hx, He⟩
  iapply (wpk_seq_ctl_env1_fam (GF := GF) (fam := famI)
    (x := x) (vx := vx) (dq := .own 1)
    (upd := fun σ => famO (packProj σ)) (c' := cO)
    hinv
    (fun p hwf hx => by
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf) (envLk_of (hIn.th p) hx))
    (fun p _ _ => by rw [hIn.proj p]; exact hctlO p)
    (fun p _ _ => by rw [hIn.proj p, hOut.lay p, hIn.lay p])
    (fun p _ _ => by rw [hIn.proj p, hOut.sup p, hIn.sup p])
    (fun p _ _ => by rw [hIn.proj p, hOut.th p, hIn.th p]))
  isplitl [Hc Hx]
  · iframe Hc Hx
  iintro ⟨Hc, Hx⟩
  icases (envCells_focus hcell).2 $$ [$Hx $He] with He
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- TWO-CELL READ LINK (the tuple-pack / compare round class). The
    second index addresses the context AFTER the first focus. -/
@[step_law (kind := segLink) (variant := env2) (side := fed)
  (frontier := "seg/link-env2")
  (trace := "{law := link_ctl_env2, joint := seg/link, hyps := [hcell₁/hcell₂ : ground(index), happ : fed(round eq)]}")
  (lineage := "sequence-rule link with two focused env cells; delegates to wpk_seq_ctl_env2_fam")]
theorem link_ctl_env2 {i₁ i₂ : Nat} {x₁ x₂ : sym} {vx₁ vx₂ : value}
    (hcell₁ : env[i₁]? = some (x₁, vx₁))
    (hcell₂ : (env.eraseIdx i₁)[i₂]? = some (x₂, vx₂))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ → lookup_env x₁ [p.f₁] = some vx₁ →
      lookup_env x₂ [p.f₁] = some vx₂ →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP), famO p))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (envCells_focus hcell₁).1 $$ He with ⟨Hx₁, He⟩
  icases (envCells_focus hcell₂).1 $$ He with ⟨Hx₂, He⟩
  iapply (wpk_seq_ctl_env2_fam (GF := GF) (fam := famI)
    (x₁ := x₁) (x₂ := x₂) (vx₁ := vx₁) (vx₂ := vx₂)
    (dq₁ := .own 1) (dq₂ := .own 1)
    (upd := fun σ => famO (packProj σ)) (c' := cO)
    hinv
    (fun p hwf hx₁ hx₂ => by
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envLk_of (hIn.th p) hx₁) (envLk_of (hIn.th p) hx₂))
    (fun p _ _ _ => by rw [hIn.proj p]; exact hctlO p)
    (fun p _ _ _ => by rw [hIn.proj p, hOut.lay p, hIn.lay p])
    (fun p _ _ _ => by rw [hIn.proj p, hOut.sup p, hIn.sup p])
    (fun p _ _ _ => by rw [hIn.proj p, hOut.th p, hIn.th p]))
  isplitl [Hc Hx₁ Hx₂]
  · iframe Hc Hx₁ Hx₂
  iintro ⟨Hc, Hx₁, Hx₂⟩
  icases (envCells_focus hcell₂).2 $$ [$Hx₂ $He] with He
  icases (envCells_focus hcell₁).2 $$ [$Hx₁ $He] with He
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- REBIND LINK (V3a continuation — the label-jump class:
    `save`/`run L(x₁,x₂)` re-bind EXISTING keys to their current cell
    values; the spine respells, every lookup is preserved, the ghost
    env is untouched). Two cells READ; delegates to
    `wpk_seq_ctl_env2_lk`. -/
@[step_law (kind := segLink) (variant := rebind2) (side := fed)
  (frontier := "seg/link-rebind2")
  (trace := "{law := link_ctl_rebind2, joint := seg/link, hyps := [hcell : ground(index), happ : fed(round eq at the reinsert spelling)]}")
  (lineage := "lookup-preserving env respell at the label jump; rebind_pres legs; delegates to wpk_seq_ctl_env2_lk")]
theorem link_ctl_rebind2 {i₁ i₂ : Nat} {x₁ x₂ : sym} {vx₁ vx₂ : value}
    (hcell₁ : env[i₁]? = some (x₁, vx₁))
    (hcell₂ : (env.eraseIdx i₁)[i₂]? = some (x₂, vx₂))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ → lookup_env x₁ [p.f₁] = some vx₁ →
      lookup_env x₂ [p.f₁] = some vx₂ →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with f₁ := ins x₁ vx₁ (ins x₂ vx₂ p.f₁) }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (envCells_focus hcell₁).1 $$ He with ⟨Hx₁, He⟩
  icases (envCells_focus hcell₂).1 $$ He with ⟨Hx₂, He⟩
  iapply (wpk_seq_ctl_env2_lk (GF := GF)
    (c := cI) (c' := cO) (S := S)
    (x₁ := x₁) (x₂ := x₂) (vx₁ := vx₁) (vx₂ := vx₂)
    (dq₁ := .own 1) (dq₂ := .own 1)
    (upd := fun σ =>
      famO { packProj σ with
        f₁ := ins x₁ vx₁ (ins x₂ vx₂ (packProj σ).f₁) })
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envLk_of (hIn.th p) hx₁) (envLk_of (hIn.th p) hx₂))
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      intro z
      rw [hIn.proj p]
      have hf : EnvWfFrame p.f₁ := wfFrame_of (hIn.th p) hwf
      have h1 : lookup_env x₁ [p.f₁] = some vx₁ :=
        envLk_of (hIn.th p) hx₁
      have h2 : lookup_env x₂ [p.f₁] = some vx₂ :=
        envLk_of (hIn.th p) hx₂
      show envLookup (famO { p with
          f₁ := ins x₁ vx₁ (ins x₂ vx₂ p.f₁) }) z
        = envLookup (famI p) z
      rw [show envLookup (famO { p with
            f₁ := ins x₁ vx₁ (ins x₂ vx₂ p.f₁) }) z
          = lookup_env z (thread0Env (famO { p with
              f₁ := ins x₁ vx₁ (ins x₂ vx₂ p.f₁) })) from rfl,
        hOut.th,
        show envLookup (famI p) z
          = lookup_env z (thread0Env (famI p)) from rfl,
        hIn.th p]
      have h1' : lookup_env x₁ [ins x₂ vx₂ p.f₁] = some vx₁ := by
        rw [rebind_pres hf h2 x₁]; exact h1
      rw [rebind_pres (birth_wfp hf) h1' z, rebind_pres hf h2 z])
    (fun σ hσ hwf hsup hx₁ hx₂ => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      have hf : EnvWfFrame p.f₁ := wfFrame_of (hIn.th p) hwf
      exact envWf_of_frame (hOut.th _)
        (birth_wfp (birth_wfp hf))))
  isplitl [Hc Hs Hx₁ Hx₂]
  · iframe Hc Hs Hx₁ Hx₂
  iintro ⟨Hc, Hs, Hx₁, Hx₂⟩
  icases (envCells_focus hcell₂).2 $$ [$Hx₂ $He] with He
  icases (envCells_focus hcell₁).2 $$ [$Hx₁ $He] with He
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- One-cell REBIND LINK. -/
@[step_law (kind := segLink) (variant := rebind1) (side := fed)
  (frontier := "seg/link-rebind1")
  (trace := "{law := link_ctl_rebind1, joint := seg/link, hyps := [hcell : ground(index), happ : fed(round eq at the reinsert spelling)]}")
  (lineage := "lookup-preserving env respell, one cell; delegates to wpk_seq_ctl_env1_lk")]
theorem link_ctl_rebind1 {i : Nat} {x : sym} {vx : value}
    (hcell : env[i]? = some (x, vx))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ → lookup_env x [p.f₁] = some vx →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with f₁ := ins x vx p.f₁ }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (envCells_focus hcell).1 $$ He with ⟨Hx, He⟩
  iapply (wpk_seq_ctl_env1_lk (GF := GF)
    (c := cI) (c' := cO) (S := S)
    (x := x) (vx := vx) (dq := .own 1)
    (upd := fun σ =>
      famO { packProj σ with f₁ := ins x vx (packProj σ).f₁ })
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envLk_of (hIn.th p) hx))
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      intro z
      rw [hIn.proj p]
      have hf : EnvWfFrame p.f₁ := wfFrame_of (hIn.th p) hwf
      have h1 : lookup_env x [p.f₁] = some vx :=
        envLk_of (hIn.th p) hx
      show envLookup (famO { p with f₁ := ins x vx p.f₁ }) z
        = envLookup (famI p) z
      rw [show envLookup (famO { p with f₁ := ins x vx p.f₁ }) z
          = lookup_env z (thread0Env (famO { p with
              f₁ := ins x vx p.f₁ })) from rfl,
        hOut.th,
        show envLookup (famI p) z
          = lookup_env z (thread0Env (famI p)) from rfl,
        hIn.th p]
      exact rebind_pres hf h1 z)
    (fun σ hσ hwf hsup hx => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      have hf : EnvWfFrame p.f₁ := wfFrame_of (hIn.th p) hwf
      exact envWf_of_frame (hOut.th _) (birth_wfp hf)))
  isplitl [Hc Hs Hx]
  · iframe Hc Hs Hx
  iintro ⟨Hc, Hs, Hx⟩
  icases (envCells_focus hcell).2 $$ [$Hx $He] with He
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- BIRTH LINK: a round that binds ONE fresh local. The cell is
    minted against the derived domain ledger; the four env-update
    obligations are discharged ONCE here from the Kit map laws. -/
@[step_law (kind := segLink) (variant := birth1) (side := fed)
  (frontier := "seg/link-birth1")
  (trace := "{law := link_birth1, joint := seg/link, hyps := [hfresh : ground(ledger), happ : fed(round eq at the insert spelling)]}")
  (lineage := "gen_heap alloc-fresh link (fused birth legs); delegates to wpk_seq_birth1_fam")]
theorem link_birth1 {x : sym} {vNew : value}
    (hfresh : symNum x ∉ domOf env)
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      (∀ z v', lookup_env z [p.f₁] = some v' → symNum z ∈ domOf env) →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with f₁ := ins x vNew p.f₁ }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, (x, vNew) :: env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  iapply (wpk_seq_birth1_fam (GF := GF) (fam := famI)
    (x := x) (vNew := vNew) (d := domOf env)
    (upd := fun σ =>
      famO { packProj σ with f₁ := ins x vNew (packProj σ).f₁ })
    (c' := cO)
    hfresh hinv
    (fun p hwf hdm => by
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envDom_frame (hIn.th p) hdm))
    (fun p _ _ => by rw [hIn.proj p]; exact hctlO _)
    (fun p _ _ => by rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun p _ _ => by rw [hIn.proj p, hOut.sup, hIn.sup p])
    (fun p hwf hdm => by
      rw [hIn.proj p]
      show lookup_env x (thread0Env (famO _)) = some vNew
      rw [hOut.th]
      exact birth_new (wfFrame_of (hIn.th p) hwf))
    (fun p hwf hdm z v' hzv => by
      rw [hIn.proj p]
      show lookup_env z (thread0Env (famO _)) = some v'
      rw [hOut.th]
      exact birth_pres (wfFrame_of (hIn.th p) hwf)
        (clsNone (envDom_frame (hIn.th p) hdm) hfresh) z v'
        (envLk_of (hIn.th p) hzv))
    (fun p hwf hdm z v' hzv => by
      rw [hIn.proj p] at hzv
      have hzv' : lookup_env z
          [ins x vNew p.f₁] = some v' := by
        rw [show envLookup (famO { p with f₁ := ins x vNew p.f₁ }) z
          = lookup_env z (thread0Env (famO { p with
              f₁ := ins x vNew p.f₁ })) from rfl, hOut.th] at hzv
        exact hzv
      rcases birth_rev (wfFrame_of (hIn.th p) hwf) z v' hzv'
          with ⟨v₀, hv₀⟩ | hnum
      · refine Or.inl ⟨v₀, ?_⟩
        show lookup_env z (thread0Env (famI p)) = some v₀
        rw [hIn.th p]
        exact hv₀
      · exact Or.inr hnum)
    (fun p hwf hdm => by
      rw [hIn.proj p]
      exact envWf_of_frame (hOut.th _)
        (birth_wfp (wfFrame_of (hIn.th p) hwf))))
  isplitl [Hc Hd]
  · iframe Hc Hd
  iintro ⟨Hc, Hd, Hx⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx, envCells, domOf, List.map_cons]
  iframe Hc Hs Hd Hx He Hm Ha Hb

/-- BIRTH + READ LINK (the label-jump bind: reads cell `iy`, births
    `x`). -/
@[step_law (kind := segLink) (variant := birth1env1) (side := fed)
  (frontier := "seg/link-birth1-env1")
  (trace := "{law := link_birth1_env1, joint := seg/link, hyps := [hfresh : ground, hcell : ground(index), happ : fed(round eq)]}")
  (lineage := "birth+read link (fused legs); delegates to wpk_seq_birth1_env1_fam")]
theorem link_birth1_env1 {x : sym} {vNew : value}
    {iy : Nat} {y : sym} {vy : value}
    (hfresh : symNum x ∉ domOf env)
    (hcell : env[iy]? = some (y, vy))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      (∀ z v', lookup_env z [p.f₁] = some v' → symNum z ∈ domOf env) →
      lookup_env y [p.f₁] = some vy →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with f₁ := ins x vNew p.f₁ }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, (x, vNew) :: env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (envCells_focus hcell).1 $$ He with ⟨Hy, He⟩
  iapply (wpk_seq_birth1_env1_fam (GF := GF) (fam := famI)
    (x := x) (vNew := vNew) (d := domOf env)
    (y := y) (vy := vy) (dqy := .own 1)
    (upd := fun σ =>
      famO { packProj σ with f₁ := ins x vNew (packProj σ).f₁ })
    (c' := cO)
    hfresh hinv
    (fun p hwf hdm hy => by
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envDom_frame (hIn.th p) hdm) (envLk_of (hIn.th p) hy))
    (fun p _ _ _ => by rw [hIn.proj p]; exact hctlO _)
    (fun p _ _ _ => by rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun p _ _ _ => by rw [hIn.proj p, hOut.sup, hIn.sup p])
    (fun p hwf hdm hy => by
      rw [hIn.proj p]
      show lookup_env x (thread0Env (famO _)) = some vNew
      rw [hOut.th]
      exact birth_new (wfFrame_of (hIn.th p) hwf))
    (fun p hwf hdm hy z v' hzv => by
      rw [hIn.proj p]
      show lookup_env z (thread0Env (famO _)) = some v'
      rw [hOut.th]
      exact birth_pres (wfFrame_of (hIn.th p) hwf)
        (clsNone (envDom_frame (hIn.th p) hdm) hfresh) z v'
        (envLk_of (hIn.th p) hzv))
    (fun p hwf hdm hy z v' hzv => by
      rw [hIn.proj p] at hzv
      have hzv' : lookup_env z
          [ins x vNew p.f₁] = some v' := by
        rw [show envLookup (famO { p with f₁ := ins x vNew p.f₁ }) z
          = lookup_env z (thread0Env (famO { p with
              f₁ := ins x vNew p.f₁ })) from rfl, hOut.th] at hzv
        exact hzv
      rcases birth_rev (wfFrame_of (hIn.th p) hwf) z v' hzv'
          with ⟨v₀, hv₀⟩ | hnum
      · refine Or.inl ⟨v₀, ?_⟩
        show lookup_env z (thread0Env (famI p)) = some v₀
        rw [hIn.th p]
        exact hv₀
      · exact Or.inr hnum)
    (fun p hwf hdm hy => by
      rw [hIn.proj p]
      exact envWf_of_frame (hOut.th _)
        (birth_wfp (wfFrame_of (hIn.th p) hwf))))
  isplitl [Hc Hd Hy]
  · iframe Hc Hd Hy
  iintro ⟨Hc, Hd, Hx, Hy⟩
  icases (envCells_focus hcell).2 $$ [$Hy $He] with He
  iapply Hk
  isimp only [Ctx.interp, SegCtx, envCells, domOf, List.map_cons]
  iframe Hc Hs Hd Hx He Hm Ha Hb

/-- DOUBLE-BIRTH LINK (the weak-pair bind: two fresh locals in one
    round). -/
@[step_law (kind := segLink) (variant := birth2) (side := fed)
  (frontier := "seg/link-birth2")
  (trace := "{law := link_birth2, joint := seg/link, hyps := [hfresh₁/hfresh₂/hne : ground(ledger), happ : fed(round eq)]}")
  (lineage := "two-cell alloc-fresh link (fused double legs); delegates to wpk_seq_birth2_fam")]
theorem link_birth2 {x₁ x₂ : sym} {v₁ v₂ : value}
    (hfresh₁ : symNum x₁ ∉ domOf env) (hfresh₂ : symNum x₂ ∉ domOf env)
    (hne : symNum x₁ ≠ symNum x₂)
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      (∀ z v', lookup_env z [p.f₁] = some v' → symNum z ∈ domOf env) →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with f₁ := ins x₁ v₁ (ins x₂ v₂ p.f₁) }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, S, (x₁, v₁) :: (x₂, v₂) :: env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  iapply (wpk_seq_birth2_fam (GF := GF) (fam := famI)
    (x₁ := x₁) (x₂ := x₂) (v₁ := v₁) (v₂ := v₂) (d := domOf env)
    (upd := fun σ =>
      famO { packProj σ with
        f₁ := ins x₁ v₁ (ins x₂ v₂ (packProj σ).f₁) })
    (c' := cO)
    hfresh₁ hfresh₂ hne hinv
    (fun p hwf hdm => by
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf)
        (envDom_frame (hIn.th p) hdm))
    (fun p _ _ => by rw [hIn.proj p]; exact hctlO _)
    (fun p _ _ => by rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun p _ _ => by rw [hIn.proj p, hOut.sup, hIn.sup p])
    (fun p hwf hdm => by
      rw [hIn.proj p]
      show lookup_env x₁ (thread0Env (famO _)) = some v₁
      rw [hOut.th]
      exact dbl_new₁ (wfFrame_of (hIn.th p) hwf))
    (fun p hwf hdm => by
      rw [hIn.proj p]
      show lookup_env x₂ (thread0Env (famO _)) = some v₂
      rw [hOut.th]
      exact dbl_new₂ (wfFrame_of (hIn.th p) hwf)
        (clsNone (envDom_frame (hIn.th p) hdm) hfresh₁) hne)
    (fun p hwf hdm z v' hzv => by
      rw [hIn.proj p]
      show lookup_env z (thread0Env (famO _)) = some v'
      rw [hOut.th]
      exact dbl_pres (wfFrame_of (hIn.th p) hwf)
        (clsNone (envDom_frame (hIn.th p) hdm) hfresh₁)
        (clsNone (envDom_frame (hIn.th p) hdm) hfresh₂)
        hne z v' (envLk_of (hIn.th p) hzv))
    (fun p hwf hdm z v' hzv => by
      rw [hIn.proj p] at hzv
      have hzv' : lookup_env z
          [ins x₁ v₁ (ins x₂ v₂ p.f₁)] = some v' := by
        rw [show envLookup (famO { p with
            f₁ := ins x₁ v₁ (ins x₂ v₂ p.f₁) }) z
          = lookup_env z (thread0Env (famO { p with
              f₁ := ins x₁ v₁ (ins x₂ v₂ p.f₁) })) from rfl,
          hOut.th] at hzv
        exact hzv
      rcases dbl_rev (wfFrame_of (hIn.th p) hwf) z v' hzv'
          with ⟨v₀, hv₀⟩ | hnum
      · refine Or.inl ⟨v₀, ?_⟩
        show lookup_env z (thread0Env (famI p)) = some v₀
        rw [hIn.th p]
        exact hv₀
      · exact Or.inr hnum)
    (fun p hwf hdm => by
      rw [hIn.proj p]
      exact envWf_of_frame (hOut.th _)
        (dbl_wfp (wfFrame_of (hIn.th p) hwf))))
  isplitl [Hc Hd]
  · iframe Hc Hd
  iintro ⟨Hc, Hd, Hx₁, Hx₂⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx, envCells, domOf, List.map_cons]
  iframe Hc Hs Hd Hx₁ Hx₂ He Hm Ha Hb

/-- LOAD LINK (the memory-fact round class): control+supply move fed
    by one focused allocation and one focused byte range (read-only;
    the action-id supply bumps). -/
@[step_law (kind := segLink) (variant := load) (side := fed)
  (frontier := "seg/link-load")
  (trace := "{law := link_load, joint := seg/link, hyps := [hj/hb : ground(index), happ : fed(round eq at footprint facts)]}")
  (lineage := "HeapLang wp_load at the segment link; delegates to wpk_seq_ctl_sup_mem")]
theorem link_load {j jb : Nat} {aid : Int} {alc : CerbMem.Allocation}
    {addr : Int} {bytes : List CerbMem.AbsByte}
    (hj : al[j]? = some (aid, alc))
    (hb : bs[jb]? = some (addr, bytes))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      p.ls.allocations.get? aid = some alc →
      (∀ i : Nat, (hi : i < bytes.length) →
        p.ls.bytemap.get? (addr + (i : Int)) = some bytes[i]) →
      memRestOf (famI p) = mr → MemInv p.ls →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with aS := p.aS + 1 }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, bumpA S, env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (allocCells_focus hj).1 $$ Ha with ⟨Haj, Ha⟩
  icases (byteCells_focus hb).1 $$ Hb with ⟨Hbj, Hb⟩
  iapply (wpk_seq_ctl_sup_mem (GF := GF)
    (c := cI) (c' := cO) (S := S) (S' := bumpA S)
    (mr := mr) (aid := aid) (al := alc) (addr := addr) (bs := bytes)
    (dqm := stHalf) (dqa := .own 1) (dqb := .own 1)
    (upd := fun σ =>
      famO { packProj σ with aS := (packProj σ).aS + 1 })
    (fun σ hσ hwf hsup hmr hget hbytes hminv => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      refine happ p (wfFrame_of (hIn.th p) hwf) ?_ ?_ hmr ?_
      · rw [← hIn.lay p]; exact hget
      · intro i hi
        rw [← hIn.lay p]; exact hbytes i hi
      · rw [← hIn.lay p]; exact hminv)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.th, hIn.th p]))
  isplitl [Hc Hs Hm Haj Hbj]
  · iframe Hc Hs Hm Haj Hbj
  iintro ⟨Hc, Hs, Hm, Haj, Hbj⟩
  icases (allocCells_focus hj).2 $$ [$Haj $Ha] with Ha
  icases (byteCells_focus hb).2 $$ [$Hbj $Hb] with Hb
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- SUPPLY-DELTA TAU LINK (V3a continuation — the NEG-transform
    round class): a control move that also DRAWS from the fresh
    supplies (the negative-action rewrite draws one excluded id and
    one symbol; `Erun` argument folds can draw likewise). The four
    deltas are per-class constants; the context's supply component
    moves by exactly them. Lineage: link_ctl + the ghost supply
    counters (the arc-13 threading); delegates to wpk_seq_ctl_sup. -/
@[step_law (kind := segLink) (variant := ctlSup) (side := fed)
  (frontier := "seg/link-ctl-sup")
  (trace := "{law := link_ctl_sup, joint := seg/link, hyps := [happ : fed(round eq with supply delta)]}")
  (lineage := "sequence-rule link with a fresh-supply delta (NEG rewrite class); delegates to wpk_seq_ctl_sup")]
theorem link_ctl_sup {dT dA dE dS : Nat}
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with
               tS := p.tS + dT, aS := p.aS + dA,
               eS := p.eS + dE, sS := p.sS + dS }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, ⟨S.tid + dT, S.aid + dA, S.exc + dE, S.symc + dS⟩,
        env, mr, al, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  iapply (wpk_seq_ctl_sup (GF := GF)
    (c := cI) (c' := cO) (S := S)
    (S' := ⟨S.tid + dT, S.aid + dA, S.exc + dE, S.symc + dS⟩)
    (upd := fun σ =>
      famO { packProj σ with
               tS := (packProj σ).tS + dT, aS := (packProj σ).aS + dA,
               eS := (packProj σ).eS + dE, sS := (packProj σ).sS + dS })
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      exact happ p (wfFrame_of (hIn.th p) hwf))
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.th, hIn.th p]))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-- STORE LINK (V3a continuation, work-order item (ii)): the Store
    action round — one focused allocation (read) and one focused byte
    range REWRITTEN; the action-id supply bumps; the touched byte
    cell moves to the context front (cons-of-eraseIdx spelling — the
    definitional re-assembly, no list surgery lemmas). -/
@[step_law (kind := segLink) (variant := store) (side := fed)
  (frontier := "seg/link-store")
  (trace := "{law := link_store, joint := seg/link, hyps := [hj/hb/hlen : ground, happ : fed(round eq at footprint facts)]}")
  (lineage := "HeapLang wp_store at the segment link; delegates to wpk_seq_ctl_sup_store")]
theorem link_store {j jb : Nat} {aid : Int} {alc : CerbMem.Allocation}
    {addr : Int} {old new : List CerbMem.AbsByte}
    (hj : al[j]? = some (aid, alc))
    (hb : bs[jb]? = some (addr, old))
    (hlen : new.length = old.length)
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      p.ls.allocations.get? aid = some alc →
      (∀ i : Nat, (hi : i < old.length) →
        p.ls.bytemap.get? (addr + (i : Int)) = some old[i]) →
      memRestOf (famI p) = mr → MemInv p.ls →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with
                    aS := p.aS + 1,
                    ls := CerbMem.writeBytesTo p.ls addr new }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, bumpA S, env, mr, al,
        (addr, new) :: bs.eraseIdx jb⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (allocCells_focus hj).1 $$ Ha with ⟨Haj, Ha⟩
  icases (byteCells_focus hb).1 $$ Hb with ⟨Hbj, Hb⟩
  iapply (wpk_seq_ctl_sup_store (GF := GF)
    (c := cI) (c' := cO) (S := S) (S' := bumpA S)
    (mr := mr) (aid := aid) (al := alc) (addr := addr)
    (old := old) (new := new) (dqm := stHalf) (dqa := .own 1)
    (upd := fun σ =>
      famO { packProj σ with
               aS := (packProj σ).aS + 1,
               ls := CerbMem.writeBytesTo σ.layout_state addr new })
    hlen
    (fun σ hσ hwf hsup hmr hget hbytes hminv => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      have hls : (famI p).layout_state = p.ls := hIn.lay p
      rw [show CerbMem.writeBytesTo (famI p).layout_state addr new
        = CerbMem.writeBytesTo p.ls addr new from by rw [hls]]
      refine happ p (wfFrame_of (hIn.th p) hwf) ?_ ?_ hmr ?_
      · rw [← hIn.lay p]; exact hget
      · intro i hi
        rw [← hIn.lay p]; exact hbytes i hi
      · rw [← hIn.lay p]; exact hminv)
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.th, hIn.th p]))
  isplitl [Hc Hs Hm Haj Hbj]
  · iframe Hc Hs Hm Haj Hbj
  iintro ⟨Hc, Hs, Hm, Haj, Hbj⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx, byteCells, allocCells]
  icases (allocCells_focus hj).2 $$ [$Haj $Ha] with Ha
  iframe Hc Hs Hd He Hm Ha Hbj Hb

/-- CREATE LINK (V3a continuation, work-order item (ii)): the Create
    action round — a fresh object minted (uninitialized bytes); new
    allocation and byte cells enter at the context front; the
    memory residual moves by `mrAlloc`. -/
@[step_law (kind := segLink) (variant := create) (side := fed)
  (frontier := "seg/link-create")
  (trace := "{law := link_create, joint := seg/link, hyps := [hsz/haddr/hnz : ground, happ : fed(round eq)]}")
  (lineage := "HeapLang wp_alloc at the segment link; delegates to wpk_seq_ctl_sup_alloc")]
theorem link_create {ty : ctype} {pref : prefix0}
    {alignN : Int} {sz : Nat} {aNew : Int}
    (hsz : (CerbMem.sizeofCtype ty).max 1 = sz)
    (haddr : ((CerbMem.alignDown (mr.lastAddress - sz).toNat
        (alignN.toNat.max 1) : Nat) : Int) = aNew)
    (hnz : (aNew == (0 : Int)) = false)
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      memRestOf (famI p) = mr → MemInv p.ls →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with
                    aS := p.aS + 1,
                    ls := CerbMem.writeBytesTo
                      ({ p.ls with
                          nextAllocId := mr.nextAllocId + 1,
                          lastAddress := aNew,
                          allocations := p.ls.allocations.insert
                            mr.nextAllocId
                            { base := aNew, size := sz, ty := some ty,
                              prefix_ := pref } })
                      aNew (List.replicate sz
                        { prov := .Prov_none, copyOffset := none,
                          value := none }) }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, bumpA S, env, mrAlloc mr aNew,
        (mr.nextAllocId,
          ({ base := aNew, size := sz, ty := some ty,
             prefix_ := pref } : CerbMem.Allocation)) :: al,
        (aNew, List.replicate sz
          ({ prov := .Prov_none, copyOffset := none,
             value := none } : CerbMem.AbsByte)) :: bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  iapply (wpk_seq_ctl_sup_alloc (GF := GF)
    (c := cI) (c' := cO) (S := S) (S' := bumpA S)
    (mr := mr) (ty := ty) (pref := pref) (alignN := alignN)
    (sz := sz) (aNew := aNew)
    (upd := fun σ =>
      famO { packProj σ with
               aS := (packProj σ).aS + 1,
               ls := CerbMem.writeBytesTo
                 ({ σ.layout_state with
                     nextAllocId := mr.nextAllocId + 1,
                     lastAddress := aNew,
                     allocations := σ.layout_state.allocations.insert
                       mr.nextAllocId
                       { base := aNew, size := sz, ty := some ty,
                         prefix_ := pref } })
                 aNew (List.replicate sz
                   { prov := .Prov_none, copyOffset := none,
                     value := none }) })
    hsz haddr hnz
    (fun σ hσ hwf hsup hmr hminv => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      have hls : (famI p).layout_state = p.ls := hIn.lay p
      rw [hls]
      refine happ p (wfFrame_of (hIn.th p) hwf) hmr ?_
      · rw [← hIn.lay p]; exact hminv)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      have hid : (famI p).layout_state.nextAllocId = mr.nextAllocId := by
        rw [show (famI p).layout_state.nextAllocId
          = (memRestOf (famI p)).nextAllocId from rfl, hmr]
      rw [hIn.proj p, hOut.lay, hIn.lay p]
      rw [show (famI p).layout_state = p.ls from hIn.lay p] at hid
      rw [hid])
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.th, hIn.th p]))
  isplitl [Hc Hs Hm]
  · iframe Hc Hs Hm
  iintro ⟨Hc, Hs, Hm, Ha2, Hb2⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx, byteCells, allocCells]
  iframe Hc Hs Hd He Hm Ha2 Ha Hb2 Hb

/-- KILL LINK (V3a continuation, work-order item (ii)): the Kill
    action round — the focused allocation fragment CONSUMED (freed);
    the memory residual moves by `mrKill`; the byte capital stays in
    the context. -/
@[step_law (kind := segLink) (variant := kill) (side := fed)
  (frontier := "seg/link-kill")
  (trace := "{law := link_kill, joint := seg/link, hyps := [hj : ground(index), happ : fed(round eq at the alloc fact)]}")
  (lineage := "HeapLang wp_free at the segment link; delegates to wpk_seq_ctl_sup_kill")]
theorem link_kill {j : Nat} {aid : Int} {alc : CerbMem.Allocation}
    (hj : al[j]? = some (aid, alc))
    (hIn : FamShape famI) (hOut : FamShape famO)
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      p.ls.allocations.get? aid = some alc →
      memRestOf (famI p) = mr → MemInv p.ls →
      app (dnmsRoundM td tid) (famI p)
        = (NDactive (Sum.inl NOWAKEUP),
           famO { p with
                    aS := p.aS + 1,
                    ls := { p.ls with
                        deadAllocations := aid :: p.ls.deadAllocations,
                        allocations := p.ls.allocations.erase aid } }))
    (hctlO : ∀ p, ctlOf (famO p) = cO) :
    SegStep (GF := GF) td tid 1 ⟨cI, S, env, mr, al, bs⟩
      ⟨cO, bumpA S, env, mrKill mr aid, al.eraseIdx j, bs⟩ := by
  intro F f hF acc xs' k s E Φ
  subst hF
  show SegCtx cI S env mr al bs ∗ _ ⊢
    WP (KExpr.seq (dnmsRoundM td tid) _) @ s ; E {{ Φ }}
  iintro ⟨⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩, Hk⟩
  icases (allocCells_focus hj).1 $$ Ha with ⟨Haj, Ha⟩
  iapply (wpk_seq_ctl_sup_kill (GF := GF)
    (c := cI) (c' := cO) (S := S) (S' := bumpA S)
    (mr := mr) (aid := aid) (al := alc)
    (upd := fun σ =>
      famO { packProj σ with
               aS := (packProj σ).aS + 1,
               ls := { σ.layout_state with
                   deadAllocations :=
                     aid :: σ.layout_state.deadAllocations,
                   allocations :=
                     σ.layout_state.allocations.erase aid } })
    (fun σ hσ hwf hsup hmr hget hminv => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]
      have hls : (famI p).layout_state = p.ls := hIn.lay p
      rw [hls]
      refine happ p (wfFrame_of (hIn.th p) hwf) ?_ hmr ?_
      · rw [← hIn.lay p]; exact hget
      · rw [← hIn.lay p]; exact hminv)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.lay, hIn.lay p])
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p]; exact hctlO _)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.sup]
      rw [hIn.sup p] at hsup
      cases hsup
      rfl)
    (fun σ hσ hwf hsup hmr => by
      obtain ⟨p, rfl⟩ := hinv σ hσ hwf
      rw [hIn.proj p, hOut.th, hIn.th p]))
  isplitl [Hc Hs Hm Haj]
  · iframe Hc Hs Hm Haj
  iintro ⟨Hc, Hs, Hm⟩
  iapply Hk
  isimp only [Ctx.interp, SegCtx]
  iframe Hc Hs Hd He Hm Ha Hb

/-! ## §6 The fused TERMINAL rule: the done-offer round, the dnms
    residual, the scheduler pick, the exit rebuild, and the readout —
    one application (the five-block coda of every V2 proof). -/

/-- TERMINAL SEGMENT (fused): from the terminal control point, the
    whole harness tail discharges — the postcondition holds at the
    finalize readout of the exit family. Extra context resources are
    dropped (affine). -/
@[step_law (kind := segLink) (variant := done) (side := fed)
  (frontier := "seg/done")
  (trace := "{law := seg_done, joint := seg/done, hyps := [happ : fed(terminal round eq), hexit : rfl, hpost : fed(readout)]}")
  (lineage := "Floyd terminal cut point: done offer + scheduler pick + prepare_exit + readout fused; delegates to wpk_seq_ctl_fam × 4 + wpk_get_done_ctl")]
theorem seg_done {famI famO : Pack → driver_state}
    {cI cO : driver_state} {rv : value}
    {S : Supplies} {env : List (sym × value)}
    {mr : CerbMem.MemState}
    {al : List (Int × CerbMem.Allocation)}
    {bs : List (Int × List CerbMem.AbsByte)}
    {φ : DriveVal → Prop}
    (hinv : ∀ σ, ctlOf σ = cI → EnvWf σ → ∃ p, σ = famI p)
    (hinvO : ∀ σ, ctlOf σ = cO → ∃ p, σ = famO p)
    (hctlI : ∀ p, ctlOf (famI p) = cI)
    (happ : ∀ p, EnvWfFrame p.f₁ →
      app (dnmsRoundM td 0) (famI p)
        = (NDactive (Sum.inr [Step_done2 rv]), famI p))
    (hIn : FamShape famI)
    (hexit : ∀ p, { famI p with
        core_state0 := prepare_exit (famI p).core_state0 rv }
      = famO p)
    (hctlO : ∀ p, ctlOf (famO p) = cO)
    (hthO : ∀ p, thread0Env (famO p) = thread0Env (famI p))
    (hpost : ∀ p, φ (Outcome.value (finalize td "callND" (famO p))))
    {F f f' : Nat} (hF : F = f + 2)
    {s : Stuckness} {E : CoPset} :
    (SegCtx (GF := GF) cI S env mr al bs) ⊢
      WP (dnmsK td F fmapEmpty 0 [] (fun m =>
        KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest td false (driver2_lemFuel f' td)
              tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr' =>
              KExpr.done (Outcome.value
                (finalize td "callND" dr')))))))
        @ s ; E {{ o, ⌜φ o⌝ }} := by
  subst hF
  iintro ⟨Hc, Hs, Hd, He, Hm, Ha, Hb⟩
  iclear Hs
  iclear Hd
  iclear He
  iclear Hm
  iclear Ha
  iclear Hb
  -- the terminal round: the done step is offered (state unchanged)
  show ctlIs stHalf cI ⊢
    WP (KExpr.seq (dnmsRoundM td 0) _) @ s ; E {{ _ }}
  iintro Hc
  iapply (wpk_seq_ctl_fam (GF := GF) (fam := famI)
    (upd := fun σ => σ) (c' := cI)
    hinv
    (fun p hwf => happ p (wfFrame_of (hIn.th p) hwf))
    (fun p _ => hctlI p) (fun p _ => rfl)
    (fun p _ => rfl) (fun p _ => rfl))
  isplitl [Hc]
  · iexact Hc
  iintro Hc
  -- the dnms residual returns the accumulator
  iapply (wpk_seq_ctl_fam (GF := GF) (fam := famI)
    (upd := fun σ => σ) (c' := cI)
    hinv
    (fun p _ => dnms_nil)
    (fun p _ => hctlI p) (fun p _ => rfl)
    (fun p _ => rfl) (fun p _ => rfl))
  isplitl [Hc]
  · iexact Hc
  iintro Hc
  -- the scheduler pick (one offer)
  iapply (wpk_seq_ctl_fam (GF := GF) (fam := famI)
    (upd := fun σ => σ) (c' := cI)
    hinv
    (fun p _ => ndctPick_one)
    (fun p _ => hctlI p) (fun p _ => rfl)
    (fun p _ => rfl) (fun p _ => rfl))
  isplitl [Hc]
  · iexact Hc
  iintro Hc
  -- the done processing: prepare_exit rebuilds the state
  iapply (wpk_seq_ctl_fam (GF := GF) (fam := famI)
    (upd := fun σ =>
      { σ with core_state0 := prepare_exit σ.core_state0 rv })
    (c' := cO)
    hinv
    (fun p _ => driver2Rest_done rfl)
    (fun p _ => by rw [hexit p]; exact hctlO p)
    (fun p _ => rfl) (fun p _ => rfl)
    (fun p _ => by
      show thread0Env ({ famI p with
        core_state0 := prepare_exit (famI p).core_state0 rv })
        = thread0Env (famI p)
      rw [hexit p]
      exact hthO p))
  isplitl [Hc]
  · iexact Hc
  iintro Hc
  -- the readout
  iapply (wpk_get_done_ctl (GF := GF) (c := cO)
    (fun σ hσ => by
      obtain ⟨p, rfl⟩ := hinvO σ hσ
      exact hpost p))
  iexact Hc

end Links

end RelSem.Seg
