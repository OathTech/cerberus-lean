/-
  RelSem.T2Proof — V2 (2026-08-28): T2 (add) PROVED — the two-argument
  protocol (inject ×2 owns BOTH argument objects) and the CHECKED ADD
  (the overflow guard discharged from the operand and sum ranges).
  Linear round chain; both statement faces off one WP.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.T2Rounds

set_option autoImplicit false

namespace RelSem.T2

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Slate
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  allocX allocXS mr0 mr1 meLoad t1Proj wp_expr_eq
  birth_new birth_pres birth_rev birth_wfp
  birth_new' birth_pres' birth_rev' birth_wfp')
open RelSem.P01 (clsNone dbl_new₁ dbl_new₂ dbl_pres dbl_rev dbl_wfp
  xObjV)
open Iris Iris.BI Iris.ProgramLogic

/-! ## Family-map helpers + ledger literals -/

@[reducible] def updB2 (ar : RExpr) (tr : List trace_event) (n : Nat)
    (pat : generic_pattern sym) (v : value)
    (σ : driver_state) : driver_state :=
  t2fam ar tr n
    { t1Proj σ with f₁ := update_env_aux pat v (t1Proj σ).f₁ }

@[reducible] def updP2 (ar : RExpr) (tr : List trace_event) (n : Nat)
    (σ : driver_state) : driver_state :=
  t2fam ar tr n (t1Proj σ)

@[reducible] def td1 : List Int := [symNum t2symA, symNum t2symB]
@[reducible] def td2 : List Int := symNum t2symA536 :: td1
@[reducible] def td3 : List Int := symNum t2symA535 :: td2
@[reducible] def td4 : List Int :=
  symNum t2symA530 :: symNum t2symA531 :: td3
@[reducible] def td5 : List Int := symNum t2symA537 :: td4

/-! ## THE T2 WP -/

set_option maxHeartbeats 8000000 in
theorem t2_wp (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (hs1 : -2147483648 ≤ x + y) (hs2 : x + y ≤ 2147483647)
    (seed : Nat) [inst : CerbStGS CerbStS] :
    (ctlIs (GF := CerbStS) stHalf
        (ctlOf (initial_driver_state_threaded seed t2File t2Fs)) ∗
      supIs stHalf
        (suppliesOf (initial_driver_state_threaded seed t2File t2Fs)) ∗
      mrestIs stHalf
        (memRestOf (initial_driver_state_threaded seed t2File t2Fs)) ∗
      domIs stHalf ([] : List Int)) ⊢
      WP (callK2 t2File.tagDefs t2File "add"
          [intValue x, intValue y])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ t2Spec x y r⌝ }} := by
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [t2_init_ctl_eq seed, t2_init_sup_eq seed,
    t2_init_mrest_eq seed]
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => t2dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := t2dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [t2Init_inv hσ hsup]; exact t2k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [t2Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [t2Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := t2dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = t2File
      from RelSem.T1.coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    iapply (wpk_seq_read_ctl (GF := CerbStS)
      (g := fun _ => addT2Sym) (c := t2dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => t2k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(t2symA, BTy_object OTy_pointer),
                         (t2symB, BTy_object OTy_pointer)], t2ar0))
        (c := t2dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => t2k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int, signed_int]) (c := t2dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => t2k5_any σ) ?hwp4)
        case hwp4 =>
          intro σv4 hσv4 hwfv4
          iintro ⟨Hc, Hs, Hm, Hd⟩
          -- THE TWO-ARGUMENT INJECTION
          iapply (wpk_seq_alloc_store2 (GF := CerbStS) (mr := mr0)
            (tyA := signed_int) (prefA := PrefOther "callND arg")
            (alignA := 4) (szA := 4) (aA := xAddr)
            (bytesA := xBytes x)
            (tyB := signed_int) (prefB := PrefOther "callND arg")
            (alignB := 4) (szB := 4) (aB := bAddr)
            (bytesB := xBytes y)
            rfl rfl rfl rfl rfl rfl rfl rfl
            (fun σ hmr hinv => t2k6_fam x y σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx, Hab, Hpb⟩
          rw [show mrAlloc (mrAlloc mr0 xAddr) bAddr = t2mr2 from rfl]
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states)
            (c := t2dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf t2mr2
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)
              ∗ allocIs (mrAlloc mr0 xAddr).nextAllocId (.own 1)
                  allocBS
              ∗ pointsToBytes bAddr (.own 1) (xBytes y)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := t2dG_inv hσv5
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
            iintro ⟨Hc, Hd, Hs, Hm, Hax, Hpx, Hab, Hpb⟩
            iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := t2mr2)
              (ty := signed_int) (pref := PrefOther "errno")
              (alignN := 4) (sz := 4) (aNew := t2errAddr)
              (newBytes := RelSem.T1.zeroBytes)
              rfl rfl rfl rfl
              (fun σ hmr hinv => t2k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc t2mr2 t2errAddr = t2mr3 from rfl]
            -- THE SETUP: a's and b's cells BORN
            iapply (wpk_seq_birth2 (GF := CerbStS)
              (x₁ := t2symA) (x₂ := t2symB)
              (v₁ := xPtrV) (v₂ := bPtrV) (d := ([] : List Int))
              (c := t2dGCtl) (c' := t2Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (t2Th0 t2ar0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        t2symB bPtrV
                        (fmapAddBy (fun (s1 s2 : sym) =>
                          Lem_Basic_classes.ordCompare s1 s2)
                          t2symA xPtrV pv.f₀)))
                    σ.core_state0) })
              (by simp) (by simp) (by simp [symNum, t2symA, t2symB])
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t2dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t2dG_inv hσ
                exact dbl_new₂' rfl hf₀ (fun z hz => hf₀none z)
                  (by simp [symNum, t2symB, t2symA]))
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t2dG_inv hσ
                exact dbl_new₁' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := t2dG_inv hσ
                rcases dbl_rev' rfl hf₀ z v' hzv
                  with ⟨v₀, hv₀⟩ | hnum | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr (Or.inr hnum)
                · exact Or.inr (Or.inl hnum))
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := t2dG_inv hσ
                intro f hf
                cases hf with
                | head => exact dbl_wfp' rfl hf₀
                | tail _ h => cases h))
            case happ2 =>
              intro σ hσ hwf hdm
              exact RelSem.Laws.driver_update_ts 0 _ σ rfl
            isplitl [Hc Hd]
            · iframe Hc Hd
            iintro ⟨Hc, Hd, HB, HA⟩
            -- §3 THE BODY -----------------------------------------
            iapply (wpk_seq_read_ctl (GF := CerbStS)
              (g := fun σ => σ)
              (c := t2Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf t2mr3
                ∗ domIs stHalf td1
                ∗ envIs t2symA (.own 1) xPtrV
                ∗ envIs t2symB (.own 1) bPtrV
                ∗ allocIs mr0.nextAllocId (.own 1) allocXS
                ∗ pointsToBytes xAddr (.own 1) (xBytes x)
                ∗ allocIs (mrAlloc mr0 xAddr).nextAllocId (.own 1)
                    allocBS
                ∗ pointsToBytes bAddr (.own 1) (xBytes y)
                ∗ allocIs t2mr2.nextAllocId (.own 1) t2allocErrS
                ∗ pointsToBytes t2errAddr (.own 1)
                    RelSem.T1.zeroBytes))
              (fun σ _ _ => app_nd_get σ) ?hwp6)
            case hwp6 =>
              intro σv6 hσv6 hwfv6
              rw [show List.map Prod.fst
                  σv6.core_state0.thread_states = [0] from by
                obtain ⟨pw, rfl⟩ := t2_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HA, HB, Hax, Hpx, Hab, Hpb,
                Hae, Hpe⟩
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK t2File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest t2File.tagDefs false
                        (driver2_lemFuel 999999 t2File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize t2File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              -- R0: b's cell read (stage-0)
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t2fam0) (x := t2symB) (vx := bPtrV)
                (c' := t2CtlAt t2ar1 [] 1)
                (upd := updP2 t2ar1 [] 1)
                (fun σ hσ hwf => t2_inv0 hσ)
                (fun p hwf hx => t2r0 p (t2fam0_frame hwf) hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HB]
              · iframe Hc HB
              iintro ⟨Hc, HB⟩
              -- R1: a_536 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t2fam t2ar1 [] 1) (x := t2symA536)
                (vNew := bPtrV) (d := td1)
                (c' := t2CtlAt t2ar2 [] 2)
                (upd := updB2 t2ar2 [] 2 t2patA536 bPtrV)
                (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hdm => t2r1 p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t2symA536
                    [update_env_aux t2patA536 (bPtrV) p.f₁] = some (bPtrV)
                  rw [t2upd_a536]
                  exact birth_new (t2fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t2patA536 (bPtrV) p.f₁] = some v'
                  rw [t2upd_a536]
                  exact birth_pres (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t2patA536 (bPtrV) p.f₁] = some v' := hzv
                  rw [t2upd_a536] at hzv'
                  exact birth_rev (t2fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t2patA536 (bPtrV) p.f₁] := hf
                  rw [t2upd_a536] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t2fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA536⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t2fam t2ar2 [] 2) (x := t2symA536) (vx := bPtrV)
                (c' := t2CtlAt t2ar3 [] 3)
                (upd := updP2 t2ar3 [] 3)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hx => t2r2 p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA536]
              · iframe Hc HA536
              iintro ⟨Hc, HA536⟩
              -- R3: THE b LOAD
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := t2CtlAt t2ar3 [] 3)
                (c' := t2CtlAt (t2ar4 y) [meLoadB y] 3)
                (S := ⟨1, 0, 0, seed⟩) (S' := ⟨1, 1, 0, seed⟩)
                (mr := t2mr3) (aid := (mrAlloc mr0 xAddr).nextAllocId) (al := allocBS)
                (addr := bAddr) (bs := xBytes y)
                (upd := fun σ => t2σ (t2ar4 y) (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (t1Proj σ).ls [meLoadB y] 3)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (t2fam t2ar3 [] 3 p)).lastUsedUnionMembers
                      from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t2fam t2ar3 [] 3 p)).funptrmap from rfl, hmr]
                    rfl
                  exact t2r3 y p hget hbytes hlum hfpm hinv hy1 hy2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t2fam t2ar3 [] 3 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl))
              isplitl [Hc Hs Hm Hab Hpb]
              · iframe Hc Hs Hm Hab Hpb
              iintro ⟨Hc, Hs, Hm, Hab, Hpb⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t2fam (t2ar4 y) [meLoadB y] 3) (x := t2symA) (vx := xPtrV)
                (c' := t2CtlAt (t2ar5 y) [meLoadB y] 4)
                (upd := updP2 (t2ar5 y) [meLoadB y] 4)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hx => t2r4 y p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA]
              · iframe Hc HA
              iintro ⟨Hc, HA⟩
              -- R5: a_535 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t2fam (t2ar5 y) [meLoadB y] 4) (x := t2symA535)
                (vNew := xPtrV) (d := td2)
                (c' := t2CtlAt (t2ar6 y) [meLoadB y] 5)
                (upd := updB2 (t2ar6 y) [meLoadB y] 5 t2patA535 xPtrV)
                (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hdm => t2r5 y p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t2symA535
                    [update_env_aux t2patA535 (xPtrV) p.f₁] = some (xPtrV)
                  rw [t2upd_a535]
                  exact birth_new (t2fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t2patA535 (xPtrV) p.f₁] = some v'
                  rw [t2upd_a535]
                  exact birth_pres (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t2patA535 (xPtrV) p.f₁] = some v' := hzv
                  rw [t2upd_a535] at hzv'
                  exact birth_rev (t2fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t2patA535 (xPtrV) p.f₁] := hf
                  rw [t2upd_a535] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t2fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA535⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t2fam (t2ar6 y) [meLoadB y] 5) (x := t2symA535) (vx := xPtrV)
                (c' := t2CtlAt (t2ar7 y) [meLoadB y] 6)
                (upd := updP2 (t2ar7 y) [meLoadB y] 6)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hx => t2r6 y p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA535]
              · iframe Hc HA535
              iintro ⟨Hc, HA535⟩
              -- R7: THE a LOAD
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := t2CtlAt (t2ar7 y) [meLoadB y] 6)
                (c' := t2CtlAt (t2ar8 x y) [meLoad x, meLoadB y] 6)
                (S := ⟨1, 1, 0, seed⟩) (S' := ⟨1, 2, 0, seed⟩)
                (mr := t2mr3) (aid := mr0.nextAllocId) (al := allocXS)
                (addr := xAddr) (bs := xBytes x)
                (upd := fun σ => t2σ (t2ar8 x y) (t1Proj σ).f₁ (t1Proj σ).tS ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS (t1Proj σ).ls [meLoad x, meLoadB y] 6)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (t2fam (t2ar7 y) [meLoadB y] 6 p)).lastUsedUnionMembers
                      from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (t2fam (t2ar7 y) [meLoadB y] 6 p)).funptrmap from rfl, hmr]
                    rfl
                  exact t2r7 x y p hget hbytes hlum hfpm hinv hx1 hx2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ
                  have h := hsup
                  rw [show suppliesOf (t2fam (t2ar7 y) [meLoadB y] 6 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ; rfl))
              isplitl [Hc Hs Hm Hax Hpx]
              · iframe Hc Hs Hm Hax Hpx
              iintro ⟨Hc, Hs, Hm, Hax, Hpx⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2ar8 x y) [meLoad x, meLoadB y] 6)
                (c' := t2CtlAt (t2ar9 x y) [meLoad x, meLoadB y] 7)
                (upd := updP2 (t2ar9 x y) [meLoad x, meLoadB y] 7)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => t2r8 x y p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R9: (a_530, a_531) BORN
              iapply (wpk_seq_birth2_fam (GF := CerbStS)
                (fam := t2fam (t2ar9 x y) [meLoad x, meLoadB y] 7)
                (x₁ := t2symA530) (x₂ := t2symA531)
                (v₁ := loadedV x) (v₂ := loadedV y) (d := td3)
                (c' := t2CtlAt t2ar10 [meLoad x, meLoadB y] 8)
                (upd := updB2 t2ar10 [meLoad x, meLoadB y] 8 t2patT3031 (Vtuple [loadedV x, loadedV y]))
                (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hdm => t2r9 x y p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t2symA530
                    [update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁] = some (loadedV x)
                  rw [t2upd_3031 x y]
                  exact dbl_new₁ (t2fam_frame hwf))
                (fun p hwf hdm => by
                  show lookup_env t2symA531
                    [update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁] = some (loadedV y)
                  rw [t2upd_3031 x y]
                  exact dbl_new₂ (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]))
                    (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁] = some v'
                  rw [t2upd_3031 x y]
                  exact dbl_pres (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]))
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]))
                    (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538]) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁] = some v' := hzv
                  rw [t2upd_3031 x y] at hzv'
                  exact dbl_rev (t2fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t2patT3031 (Vtuple [loadedV x, loadedV y]) p.f₁] := hf
                  rw [t2upd_3031 x y] at hf'
                  cases hf' with
                  | head => exact dbl_wfp (t2fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA530, HA531⟩
              -- R10: THE CHECKED ADD
              iapply (wpk_seq_ctl_env2_fam (GF := CerbStS)
                (fam := t2fam t2ar10 [meLoad x, meLoadB y] 8)
                (x₁ := t2symA530) (x₂ := t2symA531)
                (vx₁ := loadedV x) (vx₂ := loadedV y)
                (c' := t2CtlAt (t2ar11 (x + y)) [meLoad x, meLoadB y] 9)
                (upd := updP2 (t2ar11 (x + y)) [meLoad x, meLoadB y] 9)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf ha hb => t2r10 x y hx1 hx2 hy1 hy2 hs1 hs2 p ha hb)
                (fun p hwf ha hb => rfl) (fun p hwf ha hb => rfl)
                (fun p hwf ha hb => rfl) (fun p hwf ha hb => rfl))
              isplitl [Hc HA530 HA531]
              · iframe Hc HA530 HA531
              iintro ⟨Hc, HA530, HA531⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2ar11 (x + y)) [meLoad x, meLoadB y] 9)
                (c' := t2CtlAt (t2ar12 (x + y)) [meLoad x, meLoadB y] 10)
                (upd := updP2 (t2ar12 (x + y)) [meLoad x, meLoadB y] 10)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => t2r11 (x + y) p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R12: a_537 := the sum BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := t2fam (t2ar12 (x + y)) [meLoad x, meLoadB y] 10) (x := t2symA537)
                (vNew := loadedV (x + y)) (d := td4)
                (c' := t2CtlAt t2ar13 [meLoad x, meLoadB y] 11)
                (upd := updB2 t2ar13 [meLoad x, meLoadB y] 11 t2patA537 (loadedV (x + y)))
                (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hdm => t2r12 (x + y) p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env t2symA537
                    [update_env_aux t2patA537 (loadedV (x + y)) p.f₁] = some (loadedV (x + y))
                  rw [t2upd_a537 (x + y)]
                  exact birth_new (t2fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux t2patA537 (loadedV (x + y)) p.f₁] = some v'
                  rw [t2upd_a537 (x + y)]
                  exact birth_pres (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux t2patA537 (loadedV (x + y)) p.f₁] = some v' := hzv
                  rw [t2upd_a537 (x + y)] at hzv'
                  exact birth_rev (t2fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux t2patA537 (loadedV (x + y)) p.f₁] := hf
                  rw [t2upd_a537 (x + y)] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t2fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA537⟩
              -- R13: the ret jump (a_537 read, a_538 BORN)
              iapply (wpk_seq_birth1_env1_fam (GF := CerbStS)
                (fam := t2fam t2ar13 [meLoad x, meLoadB y] 11) (x := t2symA538)
                (vNew := loadedV (x + y)) (d := symNum t2symA537 :: td4)
                (y := t2symA537) (vy := loadedV (x + y))
                (c' := t2CtlAt t2ar14 [meLoad x, meLoadB y] 12)
                (upd := updB2 t2ar14 [meLoad x, meLoadB y] 12 (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) (loadedV (x + y)))
                (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hdm hy => t2r13 (x + y) hs1 hs2 p hy)
                (fun p hwf hdm hy => rfl) (fun p hwf hdm hy => rfl)
                (fun p hwf hdm hy => rfl)
                (fun p hwf hdm hy => by
                  show lookup_env t2symA538
                    [update_env_aux (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) (loadedV (x + y)) p.f₁] = some (loadedV (x + y))
                  rw [t2upd_a538 (loadedV (x + y))]
                  exact birth_new (t2fam_frame hwf))
                (fun p hwf hdm hy z v' hzv => by
                  show lookup_env z
                    [update_env_aux (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) (loadedV (x + y)) p.f₁] = some v'
                  rw [t2upd_a538 (loadedV (x + y))]
                  exact birth_pres (t2fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, t2symA, t2symB, t2symA530, t2symA531, t2symA535, t2symA536, t2symA537, t2symA538])) z v' hzv)
                (fun p hwf hdm hy z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) (loadedV (x + y)) p.f₁] = some v' := hzv
                  rw [t2upd_a538 (loadedV (x + y))] at hzv'
                  exact birth_rev (t2fam_frame hwf) z v' hzv')
                (fun p hwf hdm hy => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux (mk_sym_pat t2symA538 (BTy_loaded OTy_integer)) (loadedV (x + y)) p.f₁] := hf
                  rw [t2upd_a538 (loadedV (x + y))] at hf'
                  cases hf' with
                  | head => exact birth_wfp (t2fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd HA537]
              · iframe Hc Hd HA537
              iintro ⟨Hc, Hd, HA538, HA537⟩
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := t2fam t2ar14 [meLoad x, meLoadB y] 12) (x := t2symA538) (vx := loadedV (x + y))
                (c' := t2CtlAt (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (upd := updP2 (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf hx => t2r14 (x + y) p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA538]
              · iframe Hc HA538
              iintro ⟨Hc, HA538⟩
              iclear Hs
              iclear Hm
              iclear Hd
              iclear HA
              iclear HB
              iclear HA536
              iclear HA535
              iclear HA530
              iclear HA531
              iclear HA537
              iclear HA538
              iclear Hax
              iclear Hpx
              iclear Hab
              iclear Hpb
              iclear Hae
              iclear Hpe
              -- terminal
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (c' := t2CtlAt (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => t2r15 (x + y) p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (c' := t2CtlAt (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => dnms_nil)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (c' := t2CtlAt (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (upd := fun σ => σ)
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => ndctPick_one)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := t2fam (t2arDone (x + y)) [meLoad x, meLoadB y] 13)
                (c' := t2CtlAt (mk_value_e (loadedV (x + y)))
                  [meLoad x, meLoadB y] 13)
                (upd := fun σ =>
                  { σ with core_state0 :=
                      prepare_exit σ.core_state0 (loadedV (x + y)) })
                (fun σ hσ hwf => t2_inv hσ)
                (fun p hwf => driver2Rest_done rfl)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_get_done_ctl (GF := CerbStS)
                (c := t2CtlAt (mk_value_e (loadedV (x + y)))
                  [meLoad x, meLoadB y] 13)
                (fun σ hσ => by
                  obtain ⟨p, rfl⟩ := t2_inv hσ
                  exact ⟨_, rfl, rfl⟩))
              iexact Hc
            iframe Hc Hs Hm Hd HA HB Hax Hpx Hab Hpb Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx Hab Hpb
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

/-! ## THE T2 THEOREMS -/

theorem t2_threaded_proved : T2ThreadedStatement := by
  intro x y hx hy hs
  obtain ⟨hx1, hx2⟩ := hx
  obtain ⟨hy1, hy2⟩ := hy
  obtain ⟨hs1, hs2⟩ := hs
  exact kCallHarnessAdequateCnsSt_of_wp2 (GF := CerbStS) t2Prior
    t2File.tagDefs t2File "add" [intValue x, intValue y] t2Fs
    (t2Spec x y)
    (fun seed inst => t2_wp x y hx1 hx2 hy1 hy2 hs1 hs2 seed)

theorem t2_ubfree_proved : T2ThreadedUBFreeStatement := by
  intro x y hx hy hs
  obtain ⟨hx1, hx2⟩ := hx
  obtain ⟨hy1, hy2⟩ := hy
  obtain ⟨hs1, hs2⟩ := hs
  exact kCallHarnessUBFreeCnsSt_of_wp2 (GF := CerbStS) t2Prior
    t2File.tagDefs t2File "add" [intValue x, intValue y] t2Fs
    (t2Spec x y)
    (fun seed inst => t2_wp x y hx1 hx2 hy1 hy2 hs1 hs2 seed)

end RelSem.T2
