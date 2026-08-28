/-
  RelSem.T1Proof — V2 (2026-08-28): T1 RE-PROVED through the
  decomposed assertion layer at per-round granularity — the V2
  route's first full statement discharge (the pipeline shakedown for
  P01; V2 exit (T1–T3 re-proof clause)).

  THE PROOF SHAPE (professor reading): the callND caller protocol
  (globals, name resolution, ARGUMENT INJECTION — x's cell born with
  its bytes owned, errno), then ONE wpk rule per machine round of the
  id body — evaluate x (its cell read at the SYMBOLIC value), bind
  the parameter copy, LOAD x back (the byte roundtrip: the owned
  bytes recombine to EXACTLY x), convert (the range check discharged
  from `intRange x`), return — and the terminal readout. Every step
  is one registered wpk rule fed by one engine equation
  (RelSem/T1Rounds.lean); the statement discharge rides the
  round-granular adequacy bridge; the cone is exactly the classical
  trio (pinned in Audit.lean).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.T1Rounds
import RelSem.CerbStateAdequacy

set_option autoImplicit false

namespace RelSem.T1

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit
open Iris Iris.BI Iris.ProgramLogic

/-! ## The family projection (the `upd` σ-functions of the round
    rules are family-to-family maps; `t1Proj` reads the family
    parameters back off a family state — `t1Proj (t1fam a tr n p) = p`
    by eta) -/

@[reducible] def t1Proj (σ : driver_state) : T1P :=
  { f₁ := (match σ.core_state0.thread_states with
      | (_, (_, th)) :: _ =>
        (match th.env with | f :: _ => f | [] => fmapEmpty)
      | [] => fmapEmpty),
    tS := σ.core_run_state0.tid_supply,
    aS := σ.core_run_state0.aid_supply,
    eS := σ.core_run_state0.excluded_supply,
    sS := σ.core_run_state0.sym_supply,
    ls := σ.layout_state }

theorem t1Proj_fam (a : RExpr) (tr : List trace_event) (n : Nat)
    (p : T1P) : t1Proj (t1fam a tr n p) = p := rfl


/-! ## Instance-generic birth legs (the harness's setup fold inserts
    at `instBEqSym` + the ordCompare closure — a DIFFERENT elaborated
    spelling from the machine binds' `mapKeyCompare` inserts, and the
    two are not cheaply defeq. The Kit map laws are instance-generic;
    these legs re-derive the T1Rounds birth legs at ANY insert
    spelling whose comparator is `symCmpO`.) -/

section GenericBirth

variable {inst : BEq sym} {pcmp : sym → sym → LemOrdering}

private theorem lk_shim (b : sym) (m : Fmap sym value)
    (w : Option value)
    (hw : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b m = w) :
    lookup_env b [m] = w := by
  cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) b m <;>
    simp [lookup_env, h] <;> simp [h] at hw <;> exact hw

theorem birth_new' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    {b : sym} {v : value} {f : Fmap sym value} (hb : EnvWfFrame f) :
    lookup_env b [@fmapAddBy sym value inst pcmp b v f] = some v := by
  letI : Std.TransCmp (lemCmpToOrd pcmp) :=
    hpc ▸ RelSem.Kit.instTransCmpSymCmpO
  refine lk_shim b _ (some v) ?_
  cases hb with
  | inl he =>
    subst he
    exact RelSem.Kit.fmapLookupBy_addBy_empty_eq
      (by rw [hpc]; exact symCmpO_refl b)
  | inr hbuilt =>
    exact RelSem.Kit.fmapLookupBy_addBy_eq (hpc ▸ hbuilt)
      (by rw [hpc]; exact symCmpO_refl b)

theorem birth_pres' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    {b : sym} {v : value} {f : Fmap sym value} (hb : EnvWfFrame f)
    (hsh : ∀ z : sym, RelSem.Kit.symCmpO b z = .eq →
      lookup_env z [f] = none) :
    ∀ z v', lookup_env z [f] = some v' →
      lookup_env z [@fmapAddBy sym value inst pcmp b v f]
        = some v' := by
  letI : Std.TransCmp (lemCmpToOrd pcmp) :=
    hpc ▸ RelSem.Kit.instTransCmpSymCmpO
  intro z v' hz
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
      refine lk_shim z _ (some v') ?_
      rw [RelSem.Kit.fmapLookupBy_addBy_ne (hpc ▸ hbuilt)
        (by rw [hpc]; exact hcmp)]
      exact hzf

theorem birth_rev' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    {b : sym} {v : value} {f : Fmap sym value} (hb : EnvWfFrame f) :
    ∀ z v', lookup_env z
        [@fmapAddBy sym value inst pcmp b v f] = some v' →
      (∃ v₀, lookup_env z [f] = some v₀) ∨ symNum z = symNum b := by
  letI : Std.TransCmp (lemCmpToOrd pcmp) :=
    hpc ▸ RelSem.Kit.instTransCmpSymCmpO
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
        (@fmapAddBy sym value inst pcmp b v f) = some v' := by
      cases h : fmapLookupBy (@Lem_Map.mapKeyCompare sym _) z
          (@fmapAddBy sym value inst pcmp b v f)
      · simp [lookup_env, h] at hz
      · simp [lookup_env, h] at hz; rw [hz]
    cases hb with
    | inl he =>
      subst he
      rw [show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl,
        RelSem.Kit.fmapLookupBy_addBy_empty_ne
          (by rw [hpc]; exact hcmp)] at hzin
      cases hzin
    | inr hbuilt =>
      rw [RelSem.Kit.fmapLookupBy_addBy_ne (hpc ▸ hbuilt)
        (by rw [hpc]; exact hcmp)] at hzin
      exact ⟨v', by simp [lookup_env, hzin]⟩

theorem birth_wfp' (hpc : lemCmpToOrd pcmp = RelSem.Kit.symCmpO)
    {b : sym} {v : value} {f : Fmap sym value} (hb : EnvWfFrame f) :
    EnvWfFrame (@fmapAddBy sym value inst pcmp b v f) := by
  cases hb with
  | inl he =>
    subst he
    refine Or.inr ?_
    rw [show (Fmap.empty : Fmap sym value) = fmapEmpty from rfl,
      ← hpc]
    exact RelSem.Kit.fmapAddBy_built_empty
  | inr hbuilt =>
    exact Or.inr (RelSem.Kit.fmapAddBy_built hbuilt)

end GenericBirth

/-! ## Bridge-spelling anchors (the adequacy bridge hands tokens at
    `initial_driver_state_threaded seed`; the engine speaks the
    `t1Init`/`mr0` spellings — rfl at abstract seed) -/

theorem init_ctl_eq (seed : Nat) :
    ctlOf (initial_driver_state_threaded seed t1File t1Fs)
      = ctlOf (t1Init 0 CerbMem.initialMemState) := rfl

theorem init_sup_eq (seed : Nat) :
    suppliesOf (initial_driver_state_threaded seed t1File t1Fs)
      = suppliesOf (t1Init seed CerbMem.initialMemState) := rfl

theorem init_mrest_eq (seed : Nat) :
    memRestOf (initial_driver_state_threaded seed t1File t1Fs)
      = mr0 := rfl

/-! ## Ledger stops (the domain ledger's successive values) -/

@[reducible] def d1 : List Int := [symNum symX]
@[reducible] def d2 : List Int := symNum symA524 :: d1
@[reducible] def d3 : List Int := symNum symA525 :: d2

/-- WP congruence along a (default-transparency) expression
    equation — the joint that turns a reduced-but-not-reducibly-so
    goal expression into the peel spelling the round rules speak. -/
theorem wp_expr_eq {GF : BundledGFunctors} [CerbStGS GF]
    {e e' : KDriveExpr} {s : Stuckness} {E : CoPset}
    {Φ : DriveVal → IProp GF} (h : e = e') :
    (WP e' @ s ; E {{ Φ }} : IProp GF) ⊢ WP e @ s ; E {{ Φ }} := by
  subst h
  iintro H
  iexact H

/-! ## The segment-layer instance data (V2b): family shapes + the
    body context + THE BODY CHAIN — the whole straight-line run of
    the id body as ONE composed `SegStep` fact (8 rounds; each link
    is one registered rule fed by one T1Rounds equation). -/

open RelSem.Seg in
/-- FamShape at any T1-family instance (all rfl). -/
def t1Shape (a : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (t1fam a tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

/-- FamShape at the stage-0 family. -/
def t1Shape0 : Seg.FamShape t1fam0 :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

/-- The body-entry env cells (x's parameter cell). -/
@[reducible] def env0 : List (sym × value) := [(symX, xPtrV)]
/-- The body-entry allocation fragments (x's object, errno). -/
@[reducible] def al0 : List (Int × CerbMem.Allocation) :=
  [(mr0.nextAllocId, allocXS), (mr1.nextAllocId, allocErrS)]
/-- The body-entry byte ranges (x's bytes, errno's zeros). -/
@[reducible] def bs0 (x : Int) : List (Int × List CerbMem.AbsByte) :=
  [(xAddr, xBytes x), (errAddr, zeroBytes)]

open RelSem.Seg in
/-- THE T1 BODY as one segment: stage-0 → the terminal control point
    (8 rounds — evaluate x, bind a_524, read it, THE LOAD, unwrap,
    bind a_525, the conv jump, read a_526). -/
theorem t1_seg_body {GF : BundledGFunctors} [CerbStGS GF]
    (x : Int) (seed : Nat)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    SegStep (GF := GF) t1File.tagDefs 0 8
      ⟨t1Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩
      ⟨t1CtlAt (arena8 x) [meLoad x] 7, ⟨1, 1, 0, seed⟩,
        [(symA526, loadedV x), (symA525, loadedV x),
         (symA524, xPtrV), (symX, xPtrV)],
        mr2, al0, bs0 x⟩ := by
  -- R0: evaluate x (env read at index 0)
  refine SegStep.trans (m := 7) (link_ctl_env1 (i := 0)
    (cO := t1CtlAt arena1 [] 1) (by rfl) t1Shape0
    (t1Shape arena1 [] 1) (fun σ h _ => t1_inv0 h)
    (fun p hwf hx => t1r0v x p hwf hx) (fun p => rfl)) ?_
  -- R1: a_524 born
  refine SegStep.trans (m := 6) (link_birth1 (x := symA524)
    (vNew := xPtrV) (cO := t1CtlAt arena2 [] 2)
    (by simp [Seg.domOf, env0, symNum, symX, symA524])
    (t1Shape arena1 [] 1) (t1Shape arena2 [] 2)
    (fun σ h _ => t1_inv h)
    (fun p _ _ => t1r1 p) (fun p => rfl)) ?_
  -- R2: a_524 read (index 0)
  refine SegStep.trans (m := 5) (link_ctl_env1 (i := 0)
    (cO := t1CtlAt arena3 [] 3) (by rfl)
    (t1Shape arena2 [] 2) (t1Shape arena3 [] 3)
    (fun σ h _ => t1_inv h)
    (fun p _ ha => t1r2 p ha) (fun p => rfl)) ?_
  -- R3: THE LOAD (x's bytes recombine to exactly x; aid draw)
  refine SegStep.trans (m := 4) (link_load (j := 0) (jb := 0)
    (cO := t1CtlAt (arena4 x) [meLoad x] 3) (by rfl) (by rfl)
    (t1Shape arena3 [] 3) (t1Shape (arena4 x) [meLoad x] 3)
    (fun σ h _ => t1_inv h)
    (fun p hwf hget hbytes hmr hinv =>
      t1r3 x p hget hbytes
        (by rw [show p.ls.lastUsedUnionMembers
            = (memRestOf (t1fam arena3 [] 3 p)).lastUsedUnionMembers
            from rfl, hmr]; rfl)
        (by rw [show p.ls.funptrmap
            = (memRestOf (t1fam arena3 [] 3 p)).funptrmap
            from rfl, hmr]; rfl)
        hinv hx1 hx2)
    (fun p => rfl)) ?_
  -- R4: the Ebound wrapper strips
  refine SegStep.trans (m := 3) (link_ctl
    (cO := t1CtlAt (arena5 x) [meLoad x] 4)
    (t1Shape (arena4 x) [meLoad x] 3)
    (t1Shape (arena5 x) [meLoad x] 4) (fun σ h _ => t1_inv h)
    (fun p _ => t1r4 x p) (fun p => rfl)) ?_
  -- R5: a_525 born
  refine SegStep.trans (m := 2) (link_birth1 (x := symA525)
    (vNew := loadedV x) (cO := t1CtlAt bodyTail [meLoad x] 5)
    (by simp [Seg.domOf, env0, symNum, symX, symA524, symA525])
    (t1Shape (arena5 x) [meLoad x] 4)
    (t1Shape bodyTail [meLoad x] 5) (fun σ h _ => t1_inv h)
    (fun p _ _ => t1r5 x p) (fun p => rfl)) ?_
  -- R6: the Erun jump (reads a_525 at index 0, births a_526; the
  -- conv range check rides intRange x)
  refine SegStep.trans (m := 1) (link_birth1_env1 (x := symA526)
    (vNew := loadedV x) (iy := 0) (y := symA525) (vy := loadedV x)
    (cO := t1CtlAt arena7 [meLoad x] 6)
    (by simp [Seg.domOf, env0, symNum, symX, symA524, symA525,
      symA526])
    (by rfl) (t1Shape bodyTail [meLoad x] 5)
    (t1Shape arena7 [meLoad x] 6) (fun σ h _ => t1_inv h)
    (fun p _ _ ha => t1r6 x hx1 hx2 p ha) (fun p => rfl)) ?_
  -- R7: a_526 evaluates (index 0)
  exact link_ctl_env1 (i := 0)
    (cO := t1CtlAt (arena8 x) [meLoad x] 7) (by rfl)
    (t1Shape arena7 [meLoad x] 6)
    (t1Shape (arena8 x) [meLoad x] 7) (fun σ h _ => t1_inv h)
    (fun p _ ha => t1r7 x p ha) (fun p => rfl)

/-! ## THE T1 THEOREM -/

theorem t1_threaded_proved : T1ThreadedStatement := by
  intro x hx
  obtain ⟨hx1, hx2⟩ := hx
  refine kCallHarnessAdequateCnsSt_of_wp2 (GF := CerbStS) t1Prior
    t1File.tagDefs t1File "id" [intValue x] t1Fs (t1Spec x) ?_
  intro seed inst
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [init_ctl_eq seed, init_sup_eq seed, init_mrest_eq seed]
  -- §1 THE CALLER PROTOCOL ------------------------------------------
  -- globals: thread 0 spawned (a frame-installing ctl+supply step)
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [t1Init_inv hσ hsup]; exact k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [t1Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [t1Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  -- the state read feeding the stage atoms (core_file is
  -- control-determined)
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = t1File from coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    -- name resolution / body / parameter types (state-preserving)
    iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun _ => idT1Sym)
      (c := dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(symX, BTy_object OTy_pointer)], arena0))
        (c := dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int]) (c := dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => k5_any σ) ?hwp4)
        case hwp4 =>
          intro σv4 hσv4 hwfv4
          iintro ⟨Hc, Hs, Hm, Hd⟩
          -- THE ARGUMENT INJECTION: x's cell allocated + initialized
          iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr0)
            (ty := signed_int) (pref := PrefOther "callND arg")
            (alignN := 4) (sz := 4) (aNew := xAddr)
            (newBytes := xBytes x)
            rfl rfl rfl rfl
            (fun σ hmr hinv => k6_fam x σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx⟩
          rw [show mrAlloc mr0 xAddr = mr1 from rfl]
          -- the thread-states read (the ledger fact rides along)
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states) (c := dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf mr1
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := dG_inv hσv5
            have hf₀ : EnvWfFrame pv.f₀ := hwfv5 pv.f₀ (by
              show pv.f₀ ∈ thread0Env _
              simp [thread0Env])
            have hf₀none : ∀ z : sym,
                lookup_env z [pv.f₀] = none := by
              intro z
              cases hz : lookup_env z [pv.f₀] with
              | none => rfl
              | some v =>
                exact absurd (hdomv5 z v hz) (by simp)
            iintro ⟨Hc, Hd, Hs, Hm, Hax, Hpx⟩
            -- the errno block
            iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr1)
              (ty := signed_int) (pref := PrefOther "errno")
              (alignN := 4) (sz := 4) (aNew := errAddr)
              (newBytes := zeroBytes)
              rfl rfl rfl rfl
              (fun σ hmr hinv => k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc mr1 errAddr = mr2 from rfl]
            -- §2 THE THREAD SETUP: the parameter cell x is BORN ----
            iapply (wpk_seq_birth1 (GF := CerbStS) (x := symX)
              (vNew := xPtrV) (d := ([] : List Int))
              (c := dGCtl) (c' := t1Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (t1Th0 arena0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        symX xPtrV pv.f₀))
                    σ.core_state0) })
              (by simp)
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := dG_inv hσ
                exact birth_new' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := dG_inv hσ
                rcases birth_rev' rfl (b := symX) (v := xPtrV) hf₀
                    z v' hzv with ⟨v₀, hv₀⟩ | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr hnum)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := dG_inv hσ
                intro f hf
                cases hf with
                | head => exact birth_wfp' rfl hf₀
                | tail _ h => cases h))
            case happ2 =>
              intro σ hσ hwf hdm
              exact RelSem.Laws.driver_update_ts 0 _ σ rfl
            isplitl [Hc Hd]
            · iframe Hc Hd
            iintro ⟨Hc, Hd, HX⟩
            -- §3 THE BODY (one wpk rule per machine round) ---------
            iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
              (c := t1Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf mr2
                ∗ domIs stHalf d1
                ∗ envIs symX (.own 1) xPtrV
                ∗ allocIs mr0.nextAllocId (.own 1) allocXS
                ∗ pointsToBytes xAddr (.own 1) (xBytes x)
                ∗ allocIs mr1.nextAllocId (.own 1) allocErrS
                ∗ pointsToBytes errAddr (.own 1) zeroBytes))
              (fun σ _ _ => app_nd_get σ) ?hwp6)
            case hwp6 =>
              intro σv6 hσv6 hwfv6
              rw [show List.map Prod.fst
                  σv6.core_state0.thread_states = [0] from by
                obtain ⟨pw, rfl⟩ := t1_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HX, Hax, Hpx, Hae, Hpe⟩
              -- the singleton-thread dispatch reduces to the peeled
              -- round loop (fuel literal so the round rules unify)
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK t1File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest t1File.tagDefs false
                        (driver2_lemFuel 999999 t1File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize t1File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              -- §3 THE BODY (V2b: ONE fused segment consumes the
              -- whole 8-round run, then the fused terminal —
              -- t1_seg_body + Seg.seg_done via SegStep.consume)
              iapply (Seg.SegStep.consume (GF := CerbStS)
                (t1_seg_body x seed hx1 hx2)
                (F := 1000000) (f := 999992) rfl
                (Seg.seg_done (f' := 999999) (F := 999992)
                  (f := 999990)
                  (famI := t1fam (arena8 x) [meLoad x] 7)
                  (famO := t1fam (mk_value_e (loadedV x)) [meLoad x] 7)
                  (cO := t1CtlAt (mk_value_e (loadedV x)) [meLoad x] 7)
                  (rv := loadedV x)
                  (fun σ h _ => t1_inv h)
                  (fun σ h => t1_inv h)
                  (fun p => rfl)
                  (fun p _ => t1r8 x p)
                  (t1Shape (arena8 x) [meLoad x] 7)
                  (fun p => rfl)
                  (fun p => rfl)
                  (fun p => rfl)
                  (fun p => ⟨_, rfl, rfl⟩)
                  rfl))
              isimp only [Seg.Ctx.interp, Seg.SegCtx, env0, al0, bs0,
                Seg.envCells, Seg.allocCells, Seg.byteCells,
                Seg.domOf, List.map_cons, List.map_nil]
              iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
            iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

end RelSem.T1
