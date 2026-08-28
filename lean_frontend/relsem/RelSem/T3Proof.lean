/-
  RelSem.T3Proof — V2 (2026-08-28): T3 (roundtrip) PROVED — the
  memory-WRITING program: a local object is created, the loaded
  argument stored into it, read back (the byte roundtrip through a
  freshly-owned object), and the object killed — through the three
  new round classes (alloc/store/kill at round granularity). Both
  statement faces off one WP.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.T3Rounds

set_option autoImplicit false

namespace RelSem.T3

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Slate
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr errAddr errPtr xPtrV
  loadedV xBytes allocX allocXS allocErrS zeroBytes mr0 mr1 mr2
  meLoad t1Proj wp_expr_eq
  birth_new birth_pres birth_rev birth_wfp
  birth_new' birth_pres' birth_rev' birth_wfp')
open RelSem.P01 (clsNone xObjV)
open Iris Iris.BI Iris.ProgramLogic

@[reducible] def updB3 (ar : RExpr) (tr : List trace_event) (n : Nat)
    (pat : generic_pattern sym) (v : value)
    (σ : driver_state) : driver_state :=
  t3fam ar tr n
    { t1Proj σ with f₁ := update_env_aux pat v (t1Proj σ).f₁ }

@[reducible] def updP3 (ar : RExpr) (tr : List trace_event) (n : Nat)
    (σ : driver_state) : driver_state :=
  t3fam ar tr n (t1Proj σ)

@[reducible] def ud1 : List Int := [symNum t3symV]
@[reducible] def ud2 : List Int := symNum t3symx :: ud1
@[reducible] def ud3 : List Int := symNum t3symA526 :: ud2
@[reducible] def ud4 : List Int := symNum t3symA525 :: ud3
@[reducible] def ud5 : List Int := symNum t3symA527 :: ud4
@[reducible] def ud6 : List Int := symNum t3symA528 :: ud5

/-! ## THE T3 WP -/

set_option maxHeartbeats 8000000 in
theorem t3_wp (x : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (seed : Nat) [inst : CerbStGS CerbStS] :
    (ctlIs (GF := CerbStS) stHalf
        (ctlOf (initial_driver_state_threaded seed t3File t3Fs)) ∗
      supIs stHalf
        (suppliesOf (initial_driver_state_threaded seed t3File t3Fs)) ∗
      mrestIs stHalf
        (memRestOf (initial_driver_state_threaded seed t3File t3Fs)) ∗
      domIs stHalf ([] : List Int)) ⊢
      WP (callK2 t3File.tagDefs t3File "roundtrip" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ t3Spec x r⌝ }} := by
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [t3_init_ctl_eq seed, t3_init_sup_eq seed,
    t3_init_mrest_eq seed]
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => t3dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := t3dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [t3Init_inv hσ hsup]; exact t3k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [t3Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [t3Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := t3dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = t3File
      from RelSem.T1.coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    iapply (wpk_seq_read_ctl (GF := CerbStS)
      (g := fun _ => roundtripT3Sym) (c := t3dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => t3k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(t3symV, BTy_object OTy_pointer)], t3ar0))
        (c := t3dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => t3k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int]) (c := t3dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => t3k5_any σ) ?hwp4)
        case hwp4 =>
          intro σv4 hσv4 hwfv4
          iintro ⟨Hc, Hs, Hm, Hd⟩
          iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr0)
            (ty := signed_int) (pref := PrefOther "callND arg")
            (alignN := 4) (sz := 4) (aNew := xAddr)
            (newBytes := xBytes x)
            rfl rfl rfl rfl
            (fun σ hmr hinv => t3k6_fam x σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx⟩
          rw [show mrAlloc mr0 xAddr = mr1 from rfl]
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states)
            (c := t3dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf mr1
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := t3dG_inv hσv5
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
            iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr1)
              (ty := signed_int) (pref := PrefOther "errno")
              (alignN := 4) (sz := 4) (aNew := errAddr)
              (newBytes := zeroBytes)
              rfl rfl rfl rfl
              (fun σ hmr hinv => t3k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc mr1 errAddr = mr2 from rfl]
            -- THE SETUP: v's cell BORN
            iapply (wpk_seq_birth1 (GF := CerbStS) (x := t3symV)
              (vNew := xPtrV) (d := ([] : List Int))
              (c := t3dGCtl) (c' := t3Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (t3Th0 t3ar0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        t3symV xPtrV pv.f₀))
                    σ.core_state0) })
              (by simp)
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t3dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t3dG_inv hσ
                exact birth_new' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := t3dG_inv hσ
                rcases birth_rev' rfl (b := t3symV) (v := xPtrV) hf₀
                    z v' hzv with ⟨v₀, hv₀⟩ | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr hnum)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t3dG_inv hσ
                intro f hf
                cases hf with
                | head => exact birth_wfp' rfl hf₀
                | tail _ h => cases h))
            case happ2 =>
              intro σ hσ hwf hdm
              exact RelSem.Laws.driver_update_ts 0 _ σ rfl
            isplitl [Hc Hd]
            · iframe Hc Hd
            iintro ⟨Hc, Hd, HV⟩
            -- §3 THE BODY -----------------------------------------
            iapply (wpk_seq_read_ctl (GF := CerbStS)
              (g := fun σ => σ)
              (c := t3Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf mr2
                ∗ domIs stHalf ud1
                ∗ envIs t3symV (.own 1) xPtrV
                ∗ allocIs mr0.nextAllocId (.own 1) allocXS
                ∗ pointsToBytes xAddr (.own 1) (xBytes x)
                ∗ allocIs mr1.nextAllocId (.own 1) allocErrS
                ∗ pointsToBytes errAddr (.own 1) zeroBytes))
              (fun σ _ _ => app_nd_get σ) ?hwp6)
            case hwp6 =>
              intro σv6 hσv6 hwfv6
              rw [show List.map Prod.fst
                  σv6.core_state0.thread_states = [0] from by
                obtain ⟨pw, rfl⟩ := t3_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HV, Hax, Hpx, Hae, Hpe⟩
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK t3File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest t3File.tagDefs false
                        (driver2_lemFuel 999999 t3File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize t3File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              -- R0 (stage-0): the Create's operands (closed)
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam0)
                (c' := t3CtlAt t3ar1 [] 1)
                (upd := updP3 t3ar1 [] 1)
                (fun σ hσ hwf => t3_inv0 hσ)
                (fun p hwf => t3r0 p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R1: THE CREATE (the local object born; its footprint minted)
              iapply (wpk_seq_ctl_sup_alloc (GF := CerbStS)
                (c := t3CtlAt t3ar1 [] 1)
                (c' := t3CtlAt t3ar2 [t3meAlloc] 1)
                (S := ⟨1, 0, 0, seed⟩) (S' := ⟨1, 1, 0, seed⟩)
                (mr := mr2) (ty := intCty) (pref := PrefOther "Core")
                (alignN := 4) (sz := 4) (aNew := locAddr)
                (upd := fun σ => t3σ t3ar2 (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (t3layoutAlloc (t1Proj σ).ls) [t3meAlloc] 1)
                rfl rfl rfl
                (fun σ hσ hwf hsup hmr hinv => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have hlast : p.ls.lastAddress = mr2.lastAddress := by
                    rw [show p.ls.lastAddress
                      = (memRestOf (t3fam t3ar1 [] 1 p)).lastAddress from rfl, hmr]
                  have hnext : p.ls.nextAllocId = 2 := by
                    rw [show p.ls.nextAllocId
                      = (memRestOf (t3fam t3ar1 [] 1 p)).nextAllocId from rfl, hmr]
                    rfl
                  exact t3r1 p hlast hnext)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t3fam t3ar1 [] 1 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl))
              isplitl [Hc Hs Hm]
              · iframe Hc Hs Hm
              iintro ⟨Hc, Hs, Hm, Haloc, Hploc⟩
              rw [show mrAlloc mr2 locAddr = t3mr3 from rfl]
              -- R2: the local pointer cell x BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t3fam t3ar2 [t3meAlloc] 1) (x := t3symx)
                (vNew := locPtrV) (d := ud1)
                (c' := t3CtlAt t3ar3 [t3meAlloc] 2)
                (upd := updB3 t3ar3 [t3meAlloc] 2 t3patX locPtrV)
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm => t3r2 p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t3symx
                    [update_env_aux t3patX (locPtrV) p.f₁] = some (locPtrV)
                  rw [t3upd_x]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t3patX (locPtrV) p.f₁] = some v'
                  rw [t3upd_x]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t3patX (locPtrV) p.f₁] = some v' := hzv
                  rw [t3upd_x] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t3patX (locPtrV) p.f₁] := hf
                  rw [t3upd_x] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HX⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar3 [t3meAlloc] 2) (x := t3symV) (vx := xPtrV)
                (c' := t3CtlAt t3ar4 [t3meAlloc] 3)
                (upd := updP3 t3ar4 [t3meAlloc] 3)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r3 p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HV]
              · iframe Hc HV
              iintro ⟨Hc, HV⟩
              -- R4: a_526 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t3fam t3ar4 [t3meAlloc] 3) (x := t3symA526)
                (vNew := xPtrV) (d := ud2)
                (c' := t3CtlAt t3ar5 [t3meAlloc] 4)
                (upd := updB3 t3ar5 [t3meAlloc] 4 t3patA526 xPtrV)
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm => t3r4 p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t3symA526
                    [update_env_aux t3patA526 (xPtrV) p.f₁] = some (xPtrV)
                  rw [t3upd_a526]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t3patA526 (xPtrV) p.f₁] = some v'
                  rw [t3upd_a526]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t3patA526 (xPtrV) p.f₁] = some v' := hzv
                  rw [t3upd_a526] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t3patA526 (xPtrV) p.f₁] := hf
                  rw [t3upd_a526] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA526⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar5 [t3meAlloc] 4) (x := t3symA526) (vx := xPtrV)
                (c' := t3CtlAt t3ar6 [t3meAlloc] 5)
                (upd := updP3 t3ar6 [t3meAlloc] 5)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r5 p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA526]
              · iframe Hc HA526
              iintro ⟨Hc, HA526⟩
              -- R6: THE ARGUMENT LOAD
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := t3CtlAt t3ar6 [t3meAlloc] 5)
                (c' := t3CtlAt (t3ar7 x) [meLoad x, t3meAlloc] 5)
                (S := ⟨1, 1, 0, seed⟩) (S' := ⟨1, 2, 0, seed⟩)
                (mr := t3mr3) (aid := mr0.nextAllocId) (al := allocXS)
                (addr := xAddr) (bs := xBytes x)
                (upd := fun σ => t3σ (t3ar7 x) (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (t1Proj σ).ls [meLoad x, t3meAlloc] 5)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (t3fam t3ar6 [t3meAlloc] 5 p)).lastUsedUnionMembers
                      from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t3fam t3ar6 [t3meAlloc] 5 p)).funptrmap from rfl, hmr]
                    rfl
                  exact t3r6 x p hget hbytes hlum hfpm hinv hx1 hx2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t3fam t3ar6 [t3meAlloc] 5 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl))
              isplitl [Hc Hs Hm Hax Hpx]
              · iframe Hc Hs Hm Hax Hpx
              iintro ⟨Hc, Hs, Hm, Hax, Hpx⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3ar7 x) [meLoad x, t3meAlloc] 5)
                (c' := t3CtlAt (t3ar8 x) [meLoad x, t3meAlloc] 6)
                (upd := updP3 (t3ar8 x) [meLoad x, t3meAlloc] 6)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => t3r7 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R8: a_525 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t3fam (t3ar8 x) [meLoad x, t3meAlloc] 6) (x := t3symA525)
                (vNew := loadedV x) (d := ud3)
                (c' := t3CtlAt t3ar9 [meLoad x, t3meAlloc] 7)
                (upd := updB3 t3ar9 [meLoad x, t3meAlloc] 7 t3patA525 (loadedV x))
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm => t3r8 x p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t3symA525
                    [update_env_aux t3patA525 (loadedV x) p.f₁] = some (loadedV x)
                  rw [t3upd_a525 x]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t3patA525 (loadedV x) p.f₁] = some v'
                  rw [t3upd_a525 x]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t3patA525 (loadedV x) p.f₁] = some v' := hzv
                  rw [t3upd_a525 x] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t3patA525 (loadedV x) p.f₁] := hf
                  rw [t3upd_a525 x] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA525⟩
              -- R9: the Store operands (two cells + the conv chain)
              iapply (wpk_seq_ctl_env2_fam (GF := CerbStS)
                (fam := t3fam t3ar9 [meLoad x, t3meAlloc] 7)
                (x₁ := t3symx) (x₂ := t3symA525)
                (vx₁ := locPtrV) (vx₂ := loadedV x)
                (c' := t3CtlAt (t3ar10 x) [meLoad x, t3meAlloc] 8)
                (upd := updP3 (t3ar10 x) [meLoad x, t3meAlloc] 8)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf ha hb => t3r9 x hx1 hx2 p ha hb)
                (fun p hwf ha hb => rfl) (fun p hwf ha hb => rfl)
                (fun p hwf ha hb => rfl) (fun p hwf ha hb => rfl))
              isplitl [Hc HX HA525]
              · iframe Hc HX HA525
              iintro ⟨Hc, HX, HA525⟩
              -- R10: THE STORE (the owned uninitialized range rewritten)
              iapply (wpk_seq_ctl_sup_store (GF := CerbStS)
                (c := t3CtlAt (t3ar10 x) [meLoad x, t3meAlloc] 8)
                (c' := t3CtlAt (t3ar11) [t3meStore x, meLoad x, t3meAlloc] 8)
                (S := ⟨1, 2, 0, seed⟩) (S' := ⟨1, 3, 0, seed⟩)
                (mr := t3mr3) (aid := mr2.nextAllocId) (al := allocLoc)
                (addr := locAddr) (old := uninit4) (new := xBytes x)
                (upd := fun σ => t3σ (t3ar11) (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (CerbMem.writeBytesTo (t1Proj σ).ls locAddr (xBytes x)) [t3meStore x, meLoad x, t3meAlloc] 8)
                rfl
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t3fam (t3ar10 x) [meLoad x, t3meAlloc]
                          8 p)).funptrmap from rfl, hmr]
                    rfl
                  have hout := t3r10 x p hget hfpm
                  rw [show ({ p.ls with funptrmap := [] } : CerbMem.MemState)
                    = p.ls from by rw [← hfpm]] at hout
                  exact hout)
                (fun σ hσ hwf hsup => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t3fam (t3ar10 x) [meLoad x, t3meAlloc] 8 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl))
              isplitl [Hc Hs Hm Haloc Hploc]
              · iframe Hc Hs Hm Haloc Hploc
              iintro ⟨Hc, Hs, Hm, Haloc, Hploc⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3ar11) [t3meStore x, meLoad x, t3meAlloc] 8)
                (c' := t3CtlAt t3ar12 [t3meStore x, meLoad x, t3meAlloc] 9)
                (upd := updP3 t3ar12 [t3meStore x, meLoad x, t3meAlloc] 9)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => t3r11 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar12 [t3meStore x, meLoad x, t3meAlloc] 9) (x := t3symx) (vx := locPtrV)
                (c' := t3CtlAt t3ar13 [t3meStore x, meLoad x, t3meAlloc] 10)
                (upd := updP3 t3ar13 [t3meStore x, meLoad x, t3meAlloc] 10)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r12 x p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HX]
              · iframe Hc HX
              iintro ⟨Hc, HX⟩
              -- R13: a_527 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t3fam t3ar13 [t3meStore x, meLoad x, t3meAlloc] 10) (x := t3symA527)
                (vNew := locPtrV) (d := ud4)
                (c' := t3CtlAt t3ar14 [t3meStore x, meLoad x, t3meAlloc] 11)
                (upd := updB3 t3ar14 [t3meStore x, meLoad x, t3meAlloc] 11 t3patA527 locPtrV)
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm => t3r13 x p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t3symA527
                    [update_env_aux t3patA527 (locPtrV) p.f₁] = some (locPtrV)
                  rw [t3upd_a527]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t3patA527 (locPtrV) p.f₁] = some v'
                  rw [t3upd_a527]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t3patA527 (locPtrV) p.f₁] = some v' := hzv
                  rw [t3upd_a527] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t3patA527 (locPtrV) p.f₁] := hf
                  rw [t3upd_a527] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA527⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar14 [t3meStore x, meLoad x, t3meAlloc] 11) (x := t3symA527) (vx := locPtrV)
                (c' := t3CtlAt t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12)
                (upd := updP3 t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r14 x p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA527]
              · iframe Hc HA527
              iintro ⟨Hc, HA527⟩
              -- R15: THE LOCAL LOAD (the roundtrip readback)
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := t3CtlAt t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12)
                (c' := t3CtlAt (t3ar16 x) [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 12)
                (S := ⟨1, 3, 0, seed⟩) (S' := ⟨1, 4, 0, seed⟩)
                (mr := t3mr3) (aid := mr2.nextAllocId) (al := allocLoc)
                (addr := locAddr) (bs := xBytes x)
                (upd := fun σ => t3σ (t3ar16 x) (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (t1Proj σ).ls [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 12)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (t3fam t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12 p)).lastUsedUnionMembers
                      from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t3fam t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12 p)).funptrmap from rfl, hmr]
                    rfl
                  exact t3r15 x p hget hbytes hlum hfpm hinv hx1 hx2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t3fam t3ar15 [t3meStore x, meLoad x, t3meAlloc] 12 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl))
              isplitl [Hc Hs Hm Haloc Hploc]
              · iframe Hc Hs Hm Haloc Hploc
              iintro ⟨Hc, Hs, Hm, Haloc, Hploc⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3ar16 x) [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 12)
                (c' := t3CtlAt (t3ar17 x) [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 13)
                (upd := updP3 (t3ar17 x) [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 13)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => t3r16 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R17: a_528 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t3fam (t3ar17 x) [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 13) (x := t3symA528)
                (vNew := loadedV x) (d := ud5)
                (c' := t3CtlAt t3ar18 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 14)
                (upd := updB3 t3ar18 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 14 t3patA528 (loadedV x))
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm => t3r17 x p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t3symA528
                    [update_env_aux t3patA528 (loadedV x) p.f₁] = some (loadedV x)
                  rw [t3upd_a528 x]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t3patA528 (loadedV x) p.f₁] = some v'
                  rw [t3upd_a528 x]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t3patA528 (loadedV x) p.f₁] = some v' := hzv
                  rw [t3upd_a528 x] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t3patA528 (loadedV x) p.f₁] := hf
                  rw [t3upd_a528 x] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA528⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar18 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 14) (x := t3symx) (vx := locPtrV)
                (c' := t3CtlAt t3ar19 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (upd := updP3 t3ar19 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r18 x p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HX]
              · iframe Hc HX
              iintro ⟨Hc, HX⟩
              -- R19: THE KILL (the local freed; the fragment consumed)
              iapply (wpk_seq_ctl_sup_kill (GF := CerbStS)
                (c := t3CtlAt t3ar19 [t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (c' := t3CtlAt t3ar20 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (S := ⟨1, 4, 0, seed⟩) (S' := ⟨1, 5, 0, seed⟩)
                (mr := t3mr3) (aid := mr2.nextAllocId) (al := allocLoc)
                (upd := fun σ => t3σ t3ar20 (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS ({ (t1Proj σ).ls with deadAllocations := 2 :: (t1Proj σ).ls.deadAllocations, allocations := (t1Proj σ).ls.allocations.erase 2 }) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (fun σ hσ hwf hsup hmr hget hinv => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have hdead : p.ls.deadAllocations.contains 2 = false := by
                    rw [show p.ls.deadAllocations
                      = (memRestOf (t3fam t3ar19 [t3meLoad2 x, t3meStore x,
                          meLoad x, t3meAlloc] 15 p)).deadAllocations
                      from rfl, hmr]
                    rfl
                  exact t3r19 x p hdead hget)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t3fam t3ar19 [t3meLoad2 x, t3meStore x,
                      meLoad x, t3meAlloc] 15 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ; rfl))
              isplitl [Hc Hs Hm Haloc]
              · iframe Hc Hs Hm Haloc
              iintro ⟨Hc, Hs, Hm⟩
              rw [show mrKill t3mr3 mr2.nextAllocId = t3mr4 from rfl]
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam t3ar20 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 15)
                (c' := t3CtlAt t3ar21 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 16)
                (upd := updP3 t3ar21 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 16)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => t3r20 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R21: the ret jump (a_528 read, a_529 BORN)
              iapply (wpk_seq_birth1_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar21 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 16) (x := t3symA529)
                (vNew := loadedV x) (d := ud6)
                (y := t3symA528) (vy := loadedV x)
                (c' := t3CtlAt t3ar22 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 17)
                (upd := updB3 t3ar22 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 17 (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) (loadedV x))
                (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hdm hy => t3r21 x hx1 hx2 p hy)
                (fun p hwf hdm hy => rfl) (fun p hwf hdm hy => rfl)
                (fun p hwf hdm hy => rfl)
                (fun p hwf hdm hy => by
                  show lookup_env t3symA529
                    [update_env_aux (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some (loadedV x)
                  rw [t3upd_a529 (loadedV x)]
                  exact birth_new (t3fam_frame hwf))
                (fun p hwf hdm hy z v' hzv => by
                  show lookup_env z
                    [update_env_aux (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some v'
                  rw [t3upd_a529 (loadedV x)]
                  exact birth_pres (t3fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t3symV, t3symx, t3symA525, t3symA526, t3symA527, t3symA528, t3symA529])) z v' hzv)
                (fun p hwf hdm hy z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some v' := hzv
                  rw [t3upd_a529 (loadedV x)] at hzv'
                  exact birth_rev (t3fam_frame hwf) z v' hzv')
                (fun p hwf hdm hy => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux (mk_sym_pat t3symA529 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] := hf
                  rw [t3upd_a529 (loadedV x)] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t3fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd HA528]
              · iframe Hc Hd HA528
              iintro ⟨Hc, Hd, HA529, HA528⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t3fam t3ar22 [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 17) (x := t3symA529) (vx := loadedV x)
                (c' := t3CtlAt (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (upd := updP3 (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf hx => t3r22 x p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA529]
              · iframe Hc HA529
              iintro ⟨Hc, HA529⟩
              iclear Hs
              iclear Hm
              iclear Hd
              iclear HV
              iclear HX
              iclear HA526
              iclear HA525
              iclear HA527
              iclear HA528
              iclear HA529
              iclear Hax
              iclear Hpx
              iclear Hae
              iclear Hpe
              iclear Hploc
              -- terminal
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (c' := t3CtlAt (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => t3r23 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (c' := t3CtlAt (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => dnms_nil)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (c' := t3CtlAt (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => ndctPick_one)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t3fam (t3arDone x) [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (c' := t3CtlAt (mk_value_e (loadedV x))
                  [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (upd := fun σ =>
                  { σ with core_state0 :=
                      prepare_exit σ.core_state0 (loadedV x) })
                (fun σ hσ hwf => t3_inv hσ)
                (fun p hwf => driver2Rest_done rfl)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_get_done_ctl (GF := CerbStS)
                (c := t3CtlAt (mk_value_e (loadedV x))
                  [t3meKill, t3meLoad2 x, t3meStore x, meLoad x, t3meAlloc] 18)
                (fun σ hσ => by
                  obtain ⟨p, rfl⟩ := t3_inv hσ
                  exact ⟨_, rfl, rfl⟩))
              iexact Hc
            iframe Hc Hs Hm Hd HV Hax Hpx Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

/-! ## THE T3 THEOREMS -/

theorem t3_threaded_proved : T3ThreadedStatement := by
  intro x hx
  obtain ⟨hx1, hx2⟩ := hx
  exact kCallHarnessAdequateCnsSt_of_wp2 (GF := CerbStS) t3Prior
    t3File.tagDefs t3File "roundtrip" [intValue x] t3Fs (t3Spec x)
    (fun seed inst => t3_wp x hx1 hx2 seed)

theorem t3_ubfree_proved : T3ThreadedUBFreeStatement := by
  intro x hx
  obtain ⟨hx1, hx2⟩ := hx
  exact kCallHarnessUBFreeCnsSt_of_wp2 (GF := CerbStS) t3Prior
    t3File.tagDefs t3File "roundtrip" [intValue x] t3Fs (t3Spec x)
    (fun seed inst => t3_wp x hx1 hx2 seed)

end RelSem.T3
