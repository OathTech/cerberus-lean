/-
  RelSem.P02Proof — V2b (2026-08-28): P02 (sat_add) PROVED at the
  registered statements — THE V2 PARK KILLED. The five data paths
  (hi / lo / three mid variants incl. a = 0) discharge through the
  segment layer: the stepper runs every straight-line block, the
  case structure is the C source's (a > 0, then the guard compare;
  a < 0, then the second guard; the a = 0 residue by subst), the
  readouts and the guard/overflow side conditions are the only
  arithmetic (omega). The caller protocol is T2Proof's two-argument
  text at p02File (fusion of the protocol is the registered next
  tranche).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.P02Rounds
import RelSem.P02RoundsA
import RelSem.P02RoundsB
import RelSem.P02RoundsC
import RelSem.P02RoundsD
import RelSem.SegStepper
import RelSem.CerbStateAdequacy
import RelSem.SegmentFaces

set_option autoImplicit false
-- the tree-standing P02 file cap (matches P02Rounds/P02Guard/the
-- chunks; the walk's per-round isolation still gives each round a
-- fresh count — no per-decl budgets anywhere)
set_option maxHeartbeats 2000000

namespace RelSem.P02

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Corpus
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  allocX allocXS mr0 mr1 t1Proj wp_expr_eq)
open RelSem.T2 (bAddr bPtr bPtrV allocB allocBS meLoadB
  dbl_new₁' dbl_new₂' dbl_rev' dbl_wfp')
open Iris Iris.BI Iris.ProgramLogic

/-! ## The segment-layer instance data -/

/-- FamShape at any P02-family instance (all rfl). -/
def p02Shape (ar : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (p02fam ar tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

/-- FamShape at the stage-0 family. -/
def p02Shape0 : Seg.FamShape p02fam0 :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

/-- The two-argument domain ledger (T2Proof's `td1` shape at the
    p02 argument symbols). -/
@[reducible] def td1 : List Int := [symNum p02s_a, symNum p02s_b]

open RelSem.Seg in
/-- THE P02 BODY: stepper runs between the cut points. Case structure
    = the C source's; the a = 0 residue substitutes. (Authored
    against the stepper's cut-point stops; the seg_done exits are
    filled per path.) -/
theorem p02_body (a b : Int) (seed : Nat) [CerbStGS CerbStS]
    (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647)
    (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647) :
    (Ctx.interp (GF := CerbStS)
      ⟨p02Ctl0, ⟨1, 0, 0, seed⟩, [(p02s_a, xPtrV), (p02s_b, bPtrV)], p02mr3, [(mr0.nextAllocId, allocXS), ((mrAlloc mr0 xAddr).nextAllocId, allocBS), (p02mr2.nextAllocId, p02allocErrS)], [(xAddr, xBytes a), (bAddr, xBytes b), (p02errAddr, RelSem.T1.zeroBytes)]⟩) ⊢
      WP (dnmsK p02File.tagDefs 1000000 fmapEmpty 0 []
        (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest p02File.tagDefs false
              (driver2_lemFuel 999999 p02File.tagDefs) tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr_st' =>
              KExpr.done (Outcome.value
                (finalize p02File.tagDefs "callND" dr_st')))))))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ p02Spec a b r⌝ }} := by
  seg_run
  by_cases hga : 0 < a
  · -- a > 0: the first guard fires
    seg_run
    by_cases hgb : 2147483647 - a < b
    · -- HI: positive saturation
      seg_run
      exact seg_done (f' := 999999) (f := 999936)
        (famI := p02fam p02ar62 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59)
        (famO := p02fam (mk_value_e (loadedV 2147483647)) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59)
        (cO := p02CtlAt (mk_value_e (loadedV 2147483647)) [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59)
        (rv := loadedV 2147483647)
        (hinv := fun σ h _ => p02_inv (h.trans (p02ctl_anchor _ _ _))) (hinvO := fun σ h => p02_inv h)
        (hctlI := fun p => (p02ctl_any _ _ _ _).trans (p02ctl_anchor _ _ _).symm)
        (happ := fun p _ => p02term_hi a b p)
        (hIn := p02Shape p02ar62 [p02meLoadB b, p02meLoadA a, p02meLoadA a] 59)
        (hexit := fun p => rfl) (hctlO := fun p => p02ctl_any _ _ _ _)
        (hthO := fun p => rfl) (hF := rfl)
        (hpost := by
          exact fun p => ⟨_, rfl, by
            unfold p02Spec
            rw [show satAdd a b = (2147483647 : Int) from by
              unfold satAdd; split <;> omega]; rfl⟩)
    · -- MID-A: in-range sum
      seg_run
      exact seg_done (f' := 999999) (f := 999888)
        (famI := p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104)
        (famO := p02fam (mk_value_e (loadedV (a + b))) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104)
        (cO := p02CtlAt (mk_value_e (loadedV (a + b))) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104)
        (rv := loadedV (a + b))
        (hinv := fun σ h _ => p02_inv (h.trans (p02ctl_anchor _ _ _))) (hinvO := fun σ h => p02_inv h)
        (hctlI := fun p => (p02ctl_any _ _ _ _).trans (p02ctl_anchor _ _ _).symm)
        (happ := fun p _ => p02term_mA a b p)
        (hIn := p02Shape (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadB b, p02meLoadA a, p02meLoadA a] 104)
        (hexit := fun p => rfl) (hctlO := fun p => p02ctl_any _ _ _ _)
        (hthO := fun p => rfl) (hF := rfl)
        (hpost := by
          exact fun p => ⟨_, rfl, by
            unfold p02Spec
            rw [show satAdd a b = (a + b : Int) from by
              unfold satAdd; split <;> omega]; rfl⟩)
  · -- a ≤ 0 (the guard is the cut point itself — no rounds fire
    -- before the second split; V2b's estimate had a stray walk here)
    by_cases hgl : a < 0
    · -- a < 0: the second guard
      seg_run
      by_cases hgc : b < -2147483648 - a
      · -- LO: negative saturation
        seg_run
        exact seg_done (f' := 999999) (f := 999887)
          (famI := p02fam p02ar201 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107)
          (famO := p02fam (mk_value_e (loadedV (-2147483648))) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107)
          (cO := p02CtlAt (mk_value_e (loadedV (-2147483648))) [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107)
          (rv := loadedV (-2147483648))
          (hinv := fun σ h _ => p02_inv (h.trans (p02ctl_anchor _ _ _))) (hinvO := fun σ h => p02_inv h)
          (hctlI := fun p => (p02ctl_any _ _ _ _).trans (p02ctl_anchor _ _ _).symm)
          (happ := fun p _ => p02term_lo a b p)
          (hIn := p02Shape p02ar201 [p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 107)
          (hexit := fun p => rfl) (hctlO := fun p => p02ctl_any _ _ _ _)
          (hthO := fun p => rfl) (hF := rfl)
          (hpost := by
          exact fun p => ⟨_, rfl, by
            unfold p02Spec
            rw [show satAdd a b = (-2147483648 : Int) from by
              unfold satAdd; split <;> omega]; rfl⟩)
      · -- MID-B: in-range sum
        seg_run
        exact seg_done (f' := 999999) (f := 999882)
          (famI := p02fam (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110)
          (famO := p02fam (mk_value_e (loadedV (a + b))) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110)
          (cO := p02CtlAt (mk_value_e (loadedV (a + b))) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110)
          (rv := loadedV (a + b))
          (hinv := fun σ h _ => p02_inv (h.trans (p02ctl_anchor _ _ _))) (hinvO := fun σ h => p02_inv h)
          (hctlI := fun p => (p02ctl_any _ _ _ _).trans (p02ctl_anchor _ _ _).symm)
          (happ := fun p _ => p02term_mB a b p)
          (hIn := p02Shape (p02ar125 a b) [p02meLoadA a, p02meLoadB b, p02meLoadB b, p02meLoadA a, p02meLoadA a, p02meLoadA a] 110)
          (hexit := fun p => rfl) (hctlO := fun p => p02ctl_any _ _ _ _)
          (hthO := fun p => rfl) (hF := rfl)
          (hpost := by
          exact fun p => ⟨_, rfl, by
            unfold p02Spec
            rw [show satAdd a b = (a + b : Int) from by
              unfold satAdd; split <;> omega]; rfl⟩)
    · -- a = 0: the residue path, by subst
      have ha0 : a = 0 := by omega
      subst ha0
      -- THE SPELLING BRIDGE (PERF-1): the walk carries the shared
      -- supply's arena constants instantiated at a = 0; the mC
      -- supply is spelled at its own literal constants. One rfl
      -- re-homes the control image onto the mC chain (the two
      -- spellings are definitionally equal — literal arithmetic
      -- only); the walk then stays on mC spellings by construction.
      rw [show (p02ar12 0 : RelSem.T1.RExpr) = p02ar205 from rfl]
      seg_run
      -- bridge 2: the second guard's mC spelling
      rw [show (p02ar86 0 : RelSem.T1.RExpr) = p02ar209 from rfl]
      seg_run
      exact seg_done (f' := 999999) (f := 999909)
        (famI := p02fam (p02ar214 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85)
        (famO := p02fam (mk_value_e (loadedV b)) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85)
        (cO := p02CtlAt (mk_value_e (loadedV b)) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85)
        (rv := loadedV b)
        (hinv := fun σ h _ => p02_inv (h.trans (p02ctl_anchor _ _ _))) (hinvO := fun σ h => p02_inv h)
        (hctlI := fun p => (p02ctl_any _ _ _ _).trans (p02ctl_anchor _ _ _).symm)
        (happ := fun p _ => p02term_mC b p)
        (hIn := p02Shape (p02ar214 b) [p02meLoadA (0), p02meLoadB b, p02meLoadA (0), p02meLoadA (0)] 85)
        (hexit := fun p => rfl) (hctlO := fun p => p02ctl_any _ _ _ _)
        (hthO := fun p => rfl) (hF := rfl)
        (hpost := by
          exact fun p => ⟨_, rfl, by
            unfold p02Spec
            rw [show satAdd 0 b = (b : Int) from by
              unfold satAdd; split <;> omega]; rfl⟩)

theorem p02_wp (x y : Int)
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647)
    (hy1 : -2147483648 ≤ y) (hy2 : y ≤ 2147483647)
    (seed : Nat) [inst : CerbStGS CerbStS] :
    (ctlIs (GF := CerbStS) stHalf
        (ctlOf (initial_driver_state_threaded seed p02File corpusFs)) ∗
      supIs stHalf
        (suppliesOf (initial_driver_state_threaded seed p02File corpusFs)) ∗
      mrestIs stHalf
        (memRestOf (initial_driver_state_threaded seed p02File corpusFs)) ∗
      domIs stHalf ([] : List Int)) ⊢
      WP (callK2 p02File.tagDefs p02File "sat_add"
          [intValue x, intValue y])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ p02Spec x y r⌝ }} := by
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [p02_init_ctl_eq seed, p02_init_sup_eq seed,
    p02_init_mrest_eq seed]
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => p02dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := p02dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [p02Init_inv hσ hsup]; exact p02k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [p02Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [p02Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := p02dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = p02File
      from RelSem.T1.coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    iapply (wpk_seq_read_ctl (GF := CerbStS)
      (g := fun _ => satAddP02Sym) (c := p02dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => p02k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(p02s_a, BTy_object OTy_pointer),
                         (p02s_b, BTy_object OTy_pointer)], p02ar0))
        (c := p02dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => p02k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int, signed_int]) (c := p02dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => p02k5_any σ) ?hwp4)
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
            (fun σ hmr hinv => p02k6_fam x y σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx, Hab, Hpb⟩
          rw [show mrAlloc (mrAlloc mr0 xAddr) bAddr = p02mr2 from rfl]
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states)
            (c := p02dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf p02mr2
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)
              ∗ allocIs (mrAlloc mr0 xAddr).nextAllocId (.own 1)
                  allocBS
              ∗ pointsToBytes bAddr (.own 1) (xBytes y)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := p02dG_inv hσv5
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
            iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := p02mr2)
              (ty := signed_int) (pref := PrefOther "errno")
              (alignN := 4) (sz := 4) (aNew := p02errAddr)
              (newBytes := RelSem.T1.zeroBytes)
              rfl rfl rfl rfl
              (fun σ hmr hinv => p02k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc p02mr2 p02errAddr = p02mr3 from rfl]
            -- THE SETUP: a's and b's cells BORN
            iapply (wpk_seq_birth2 (GF := CerbStS)
              (x₁ := p02s_a) (x₂ := p02s_b)
              (v₁ := xPtrV) (v₂ := bPtrV) (d := ([] : List Int))
              (c := p02dGCtl) (c' := p02Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (p02Th0 p02ar0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        p02s_b bPtrV
                        (fmapAddBy (fun (s1 s2 : sym) =>
                          Lem_Basic_classes.ordCompare s1 s2)
                          p02s_a xPtrV pv.f₀)))
                    σ.core_state0) })
              (by simp) (by simp) (by simp [symNum, p02s_a, p02s_b])
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p02dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p02dG_inv hσ
                exact dbl_new₂' rfl hf₀ (fun z hz => hf₀none z)
                  (by simp [symNum, p02s_b, p02s_a]))
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p02dG_inv hσ
                exact dbl_new₁' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := p02dG_inv hσ
                rcases dbl_rev' rfl hf₀ z v' hzv
                  with ⟨v₀, hv₀⟩ | hnum | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr (Or.inr hnum)
                · exact Or.inr (Or.inl hnum))
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p02dG_inv hσ
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
              (c := p02Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf p02mr3
                ∗ domIs stHalf td1
                ∗ envIs p02s_a (.own 1) xPtrV
                ∗ envIs p02s_b (.own 1) bPtrV
                ∗ allocIs mr0.nextAllocId (.own 1) allocXS
                ∗ pointsToBytes xAddr (.own 1) (xBytes x)
                ∗ allocIs (mrAlloc mr0 xAddr).nextAllocId (.own 1)
                    allocBS
                ∗ pointsToBytes bAddr (.own 1) (xBytes y)
                ∗ allocIs p02mr2.nextAllocId (.own 1) p02allocErrS
                ∗ pointsToBytes p02errAddr (.own 1)
                    RelSem.T1.zeroBytes))
              (fun σ _ _ => app_nd_get σ) ?hwp6)
            case hwp6 =>
              intro σv6 hσv6 hwfv6
              rw [show List.map Prod.fst
                  σv6.core_state0.thread_states = [0] from by
                obtain ⟨pw, rfl⟩ := p02_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HA, HB, Hax, Hpx, Hab, Hpb,
                Hae, Hpe⟩
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK p02File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest p02File.tagDefs false
                        (driver2_lemFuel 999999 p02File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize p02File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              -- §3 THE BODY: hand off to the stepper-run body lemma
              iapply (p02_body x y seed hx1 hx2 hy1 hy2)
              isimp only [Seg.Ctx.interp, Seg.SegCtx,
                Seg.envCells, Seg.allocCells, Seg.byteCells,
                Seg.domOf, List.map_cons, List.map_nil]
              iframe Hc Hs Hm Hd HA HB Hax Hpx Hab Hpb Hae Hpe
            iframe Hc Hs Hm Hd HA HB Hax Hpx Hab Hpb Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx Hab Hpb
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd


/-! ## THE P02 THEOREMS -/

/-- P02's spec as an `FnSpec` (`verify_fn`'s role-1 object). -/
abbrev p02FnSpec : Seg.FnSpec (Int × Int) :=
  { fname := "sat_add",
    args := fun xy => [intValue xy.1, intValue xy.2],
    pre := fun xy => T1.intRange xy.1 ∧ T1.intRange xy.2,
    post := fun xy r => p02Spec xy.1 xy.2 r }

/-- **P02 (sat_add) PROVED** at the registered statement. -/
theorem p02_proved : P02Statement := by
  verify_fn p02FnSpec
  exact p02_wp a.1 a.2 ha.1.1 ha.1.2 ha.2.1 ha.2.2 seed

/-- **P02 UB-freedom PROVED** (the same WP). -/
theorem p02_ubfree_proved : P02UBFreeStatement := by
  verify_fn p02FnSpec
  exact p02_wp a.1 a.2 ha.1.1 ha.1.2 ha.2.1 ha.2.2 seed

end RelSem.P02
