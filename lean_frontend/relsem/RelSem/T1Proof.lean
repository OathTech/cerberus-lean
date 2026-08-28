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

/-! ## The bind-round family maps (named `upd` functions) -/

@[reducible] def updR1 (σ : driver_state) : driver_state :=
  t1fam arena2 [] 2
    { t1Proj σ with
        f₁ := update_env_aux patA499 xPtrV (t1Proj σ).f₁ }

@[reducible] def updR3 (x : Int) (σ : driver_state) : driver_state :=
  t1fam (arena4 x) [meLoad x] 3
    { t1Proj σ with aS := (t1Proj σ).aS + 1 }

@[reducible] def updR5 (x : Int) (σ : driver_state) : driver_state :=
  t1fam bodyTail [meLoad x] 5
    { t1Proj σ with
        f₁ := update_env_aux patA500 (loadedV x) (t1Proj σ).f₁ }

@[reducible] def updR6 (x : Int) (σ : driver_state) : driver_state :=
  t1fam arena7 [meLoad x] 6
    { t1Proj σ with
        f₁ := update_env_aux
          (mk_sym_pat symA526 (BTy_loaded OTy_integer)) (loadedV x)
          (t1Proj σ).f₁ }

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

/-! ## THE T1 THEOREM -/

set_option maxHeartbeats 4000000 in
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
              -- R0: evaluate x (the cell READ at its symbolic value)
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t1fam0) (x := symX) (vx := xPtrV)
                (c' := t1CtlAt arena1 [] 1)
                (upd := fun σ => t1fam arena1 [] 1 (t1Proj σ))
                (fun σ hσ hwf => t1_inv0 hσ)
                (fun p hwf hx => t1r0v x p (t1fam0_frame hwf) hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HX]
              · iframe Hc HX
              iintro ⟨Hc, HX⟩
              -- R1: bind the parameter copy a_524 (BORN)
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t1fam arena1 [] 1) (x := symA524)
                (vNew := xPtrV) (d := d1)
                (c' := t1CtlAt arena2 [] 2)
                (upd := updR1)
                (by simp [d1, symNum, symA524, symX])
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf hdm => t1r1 p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env symA524
                    [update_env_aux patA499 xPtrV p.f₁] = some xPtrV
                  rw [update_env_aux_a524]
                  exact birth_new (t1fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux patA499 xPtrV p.f₁] = some v'
                  rw [update_env_aux_a524]
                  refine birth_pres (t1fam_frame hwf) ?_ z v' hzv
                  intro w hw
                  cases hlk : lookup_env w [p.f₁] with
                  | none => rfl
                  | some vw =>
                    exfalso
                    have hin := hdm w vw hlk
                    obtain ⟨db, nb, sdb⟩ := w
                    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff
                      _ db _ nb _ sdb).1 hw
                    simp only [symNum] at hin
                    rw [← hn] at hin
                    simp [d1, symNum, symX] at hin)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux patA499 xPtrV p.f₁]
                      = some v' := hzv
                  rw [update_env_aux_a524] at hzv'
                  exact birth_rev (t1fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux patA499 xPtrV p.f₁]
                    := hf
                  rw [update_env_aux_a524] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t1fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA524⟩
              -- R2: the Load's pointer operand (a_524's cell read)
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t1fam arena2 [] 2) (x := symA524)
                (vx := xPtrV) (c' := t1CtlAt arena3 [] 3)
                (upd := fun σ => t1fam arena3 [] 3 (t1Proj σ))
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf ha => t1r2 p ha)
                (fun p hwf ha => rfl) (fun p hwf ha => rfl)
                (fun p hwf ha => rfl) (fun p hwf ha => rfl))
              isplitl [Hc HA524]
              · iframe Hc HA524
              iintro ⟨Hc, HA524⟩
              -- R3: THE LOAD (x's bytes recombine to exactly x; one
              -- action id drawn)
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := t1CtlAt arena3 [] 3)
                (c' := t1CtlAt (arena4 x) [meLoad x] 3)
                (S := ⟨1, 0, 0, seed⟩) (S' := ⟨1, 1, 0, seed⟩)
                (mr := mr2) (aid := mr0.nextAllocId) (al := allocXS)
                (addr := xAddr) (bs := xBytes x)
                (upd := updR3 x)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (t1fam arena3 [] 3
                          p)).lastUsedUnionMembers from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t1fam arena3 [] 3 p)).funptrmap
                      from rfl, hmr]
                    rfl
                  exact t1r3 x p hget hbytes hlum hfpm hinv hx1 hx2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t1fam arena3 [] 3 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ; rfl))
              isplitl [Hc Hs Hm Hax Hpx]
              · iframe Hc Hs Hm Hax Hpx
              iintro ⟨Hc, Hs, Hm, Hax, Hpx⟩
              -- R4: the Ebound wrapper strips
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t1fam (arena4 x) [meLoad x] 3)
                (c' := t1CtlAt (arena5 x) [meLoad x] 4)
                (upd := fun σ => t1fam (arena5 x) [meLoad x] 4
                  (t1Proj σ))
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf => t1r4 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R5: bind a_525 (the loaded value BORN into a cell)
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t1fam (arena5 x) [meLoad x] 4)
                (x := symA525) (vNew := loadedV x) (d := d2)
                (c' := t1CtlAt bodyTail [meLoad x] 5)
                (upd := updR5 x)
                (by simp [d2, d1, symNum, symA525, symA524, symX])
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf hdm => t1r5 x p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env symA525
                    [update_env_aux patA500 (loadedV x) p.f₁]
                    = some (loadedV x)
                  rw [update_env_aux_a525]
                  exact birth_new (t1fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux patA500 (loadedV x) p.f₁]
                    = some v'
                  rw [update_env_aux_a525]
                  refine birth_pres (t1fam_frame hwf) ?_ z v' hzv
                  intro w hw
                  cases hlk : lookup_env w [p.f₁] with
                  | none => rfl
                  | some vw =>
                    exfalso
                    have hin := hdm w vw hlk
                    obtain ⟨db, nb, sdb⟩ := w
                    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff
                      _ db _ nb _ sdb).1 hw
                    simp only [symNum] at hin
                    rw [← hn] at hin
                    simp [d2, d1, symNum, symA524, symX] at hin)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux patA500 (loadedV x) p.f₁]
                      = some v' := hzv
                  rw [update_env_aux_a525] at hzv'
                  exact birth_rev (t1fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈
                      [update_env_aux patA500 (loadedV x) p.f₁]
                    := hf
                  rw [update_env_aux_a525] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t1fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA525⟩
              -- R6: the Erun jump — conv_loaded_int evaluates (the
              -- range check rides `intRange x`), a_526 BORN
              iapply (wpk_seq_birth1_env1_fam (GF := CerbStS)
                (fam := t1fam bodyTail [meLoad x] 5)
                (x := symA526) (vNew := loadedV x) (d := d3)
                (y := symA525) (vy := loadedV x)
                (c' := t1CtlAt arena7 [meLoad x] 6)
                (upd := updR6 x)
                (by simp [d3, d2, d1, symNum, symA526, symA525,
                  symA524, symX])
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf hdm ha => t1r6 x hx1 hx2 p ha)
                (fun p hwf hdm ha => rfl) (fun p hwf hdm ha => rfl)
                (fun p hwf hdm ha => rfl)
                (fun p hwf hdm ha => by
                  show lookup_env symA526
                    [update_env_aux
                      (mk_sym_pat symA526 (BTy_loaded OTy_integer))
                      (loadedV x) p.f₁] = some (loadedV x)
                  rw [update_env_aux_a526]
                  exact birth_new (t1fam_frame hwf))
                (fun p hwf hdm ha z v' hzv => by
                  show lookup_env z
                    [update_env_aux
                      (mk_sym_pat symA526 (BTy_loaded OTy_integer))
                      (loadedV x) p.f₁] = some v'
                  rw [update_env_aux_a526]
                  refine birth_pres (t1fam_frame hwf) ?_ z v' hzv
                  intro w hw
                  cases hlk : lookup_env w [p.f₁] with
                  | none => rfl
                  | some vw =>
                    exfalso
                    have hin := hdm w vw hlk
                    obtain ⟨db, nb, sdb⟩ := w
                    obtain ⟨-, hn⟩ := (RelSem.Kit.symCmpO_eq_iff
                      _ db _ nb _ sdb).1 hw
                    simp only [symNum] at hin
                    rw [← hn] at hin
                    simp [d3, d2, d1, symNum, symA525, symA524,
                      symX] at hin)
                (fun p hwf hdm ha z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux
                        (mk_sym_pat symA526 (BTy_loaded OTy_integer))
                        (loadedV x) p.f₁] = some v' := hzv
                  rw [update_env_aux_a526] at hzv'
                  exact birth_rev (t1fam_frame hwf) z v' hzv')
                (fun p hwf hdm ha => by
                  intro f hf
                  have hf' : f ∈
                      [update_env_aux
                        (mk_sym_pat symA526 (BTy_loaded OTy_integer))
                        (loadedV x) p.f₁] := hf
                  rw [update_env_aux_a526] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t1fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd HA525]
              · iframe Hc Hd HA525
              iintro ⟨Hc, Hd, HA526, HA525⟩
              -- R7: a_526 evaluates (the return value reaches the
              -- arena)
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t1fam arena7 [meLoad x] 6) (x := symA526)
                (vx := loadedV x)
                (c' := t1CtlAt (arena8 x) [meLoad x] 7)
                (upd := fun σ => t1fam (arena8 x) [meLoad x] 7
                  (t1Proj σ))
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf ha => t1r7 x p ha)
                (fun p hwf ha => rfl) (fun p hwf ha => rfl)
                (fun p hwf ha => rfl) (fun p hwf ha => rfl))
              isplitl [Hc HA526]
              · iframe Hc HA526
              iintro ⟨Hc, HA526⟩
              -- R8 (terminal round): the done step is offered
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t1fam (arena8 x) [meLoad x] 7)
                (c' := t1CtlAt (arena8 x) [meLoad x] 7)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf => t1r8 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- the dnms residual returns the accumulator
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t1fam (arena8 x) [meLoad x] 7)
                (c' := t1CtlAt (arena8 x) [meLoad x] 7)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf => dnms_nil)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- the scheduler pick (one offer)
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t1fam (arena8 x) [meLoad x] 7)
                (c' := t1CtlAt (arena8 x) [meLoad x] 7)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf => ndctPick_one)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- the done processing: prepare_exit rebuilds the state
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t1fam (arena8 x) [meLoad x] 7)
                (c' := t1CtlAt (mk_value_e (loadedV x)) [meLoad x] 7)
                (upd := fun σ =>
                  { σ with core_state0 :=
                      prepare_exit σ.core_state0 (loadedV x) })
                (fun σ hσ hwf => t1_inv hσ)
                (fun p hwf => driver2Rest_done rfl)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- THE TERMINAL READOUT: finalize reads the arena — the
              -- result is EXACTLY intValue x
              iclear Hs
              iclear Hm
              iclear Hd
              iclear HX
              iclear HA524
              iclear HA525
              iclear HA526
              iclear Hax
              iclear Hpx
              iclear Hae
              iclear Hpe
              iapply (wpk_get_done_ctl (GF := CerbStS)
                (c := t1CtlAt (mk_value_e (loadedV x)) [meLoad x] 7)
                (fun σ hσ => by
                  obtain ⟨p, rfl⟩ := t1_inv hσ
                  exact ⟨_, rfl, rfl⟩))
              iexact Hc
            iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

end RelSem.T1
