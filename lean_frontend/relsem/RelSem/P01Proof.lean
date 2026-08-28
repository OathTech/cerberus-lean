/-
  RelSem.P01Proof — V2 (2026-08-28): P01 (clamp0) PROVED — the first
  SYMBOLIC DATA-DEPENDENT BRANCH through the per-round assertion
  layer (the V-plan's defining checkpoint; the target corpus F1/F13
  emblem row).

  THE PROOF SHAPE (professor reading): the callND caller protocol
  (identical to T1's — argument injection owns x's bytes), ten shared
  rounds (two constant evals, the x-cell read, the a_534 bind, THE
  LOAD — x's bytes recombine to exactly x — the tuple pack and
  binds), then the PATH SPLIT `by_cases hlt : x < 0` at the compare
  round: the OpLt verdict chain discharges per side from the range
  facts + the path hypothesis, and the two arms replay their own
  round chains (the else arm RELOADS x through the still-owned
  footprint). Terminal readout: `clamp0(x) = max x 0` per side by
  `omega`. Every step is one registered wpk rule fed by one
  P01Rounds engine equation; cone exactly the classical trio.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.P01Rounds
import RelSem.T1Proof
import RelSem.SegStepper
import RelSem.CorpusStatements
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.P01

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Corpus
open RelSem.T1 (T1P RExpr aU intCty xAddr errAddr xPtr errPtr xPtrV
  loadedV xBytes allocX allocXS allocErrS zeroBytes mr0 mr1 mr2 symX
  meLoad birth_new birth_pres birth_rev birth_wfp t1Proj wp_expr_eq
  birth_new' birth_pres' birth_rev' birth_wfp' env0 al0 bs0)
open Iris Iris.BI Iris.ProgramLogic

/-! ## Ledger literal (the body-entry domain list) -/

/-- After the setup (x's cell). -/
@[reducible] def pd1 : List Int := [symNum symX]

/-! ## The segment-layer instance data (V2b) -/

/-- FamShape at any P01-family instance (all rfl). -/
def p01Shape (a : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (p01fam a tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

open RelSem.Seg in
/-- THE P01 BODY: stepper runs between the cut points — the shared
    prefix to THE BRANCH, one case split on the symbolic input, each
    arm to its terminal; the readouts are the only arithmetic
    (`max x 0` per side by omega). -/
theorem p01_body (x : Int) (seed : Nat) [CerbStGS CerbStS]
    (hx1 : -2147483648 ≤ x) (hx2 : x ≤ 2147483647) :
    (Ctx.interp (GF := CerbStS)
      ⟨p01Ctl0, ⟨1, 0, 0, seed⟩, env0, mr2, al0, bs0 x⟩) ⊢
      WP (dnmsK p01File.tagDefs 1000000 fmapEmpty 0 []
        (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
          KExpr.seq (driver2Rest p01File.tagDefs false
              (driver2_lemFuel 999999 p01File.tagDefs) tid_steps)
            (fun _ => KExpr.seq nd_get (fun dr_st' =>
              KExpr.done (Outcome.value
                (finalize p01File.tagDefs "callND" dr_st')))))))
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ p01Spec x r⌝ }} := by
  seg_run
  by_cases hlt : x < 0
  · -- THE THEN ARM (x < 0): run to the terminal; clamp0 x = 0
    seg_run
    exact seg_done (f' := 999999) (f := 999972)
      (famI := p01fam p01arT26 [meLoad x] 25)
      (famO := p01fam (mk_value_e (loadedV 0)) [meLoad x] 25)
      (cO := p01CtlAt (mk_value_e (loadedV 0)) [meLoad x] 25)
      (rv := loadedV 0)
      (hinv := fun σ h _ => p01_inv h) (hinvO := fun σ h => p01_inv h)
      (hctlI := fun p => rfl)
      (happ := fun p _ => p01r26T x p)
      (hIn := p01Shape p01arT26 [meLoad x] 25)
      (hexit := fun p => rfl) (hctlO := fun p => rfl)
      (hthO := fun p => rfl) (hF := rfl)
      (hpost := by
        exact fun p => ⟨_, rfl, by
          show _ = intValue (max x 0)
          rw [show max x 0 = 0 from by omega]; rfl⟩)
  · -- THE ELSE ARM (x ≥ 0): reload x, return it; clamp0 x = x
    seg_run
    exact seg_done (f' := 999999) (f := 999968)
      (famI := p01fam (p01arF30 x) [meLoad x, meLoad x] 28)
      (famO := p01fam (mk_value_e (loadedV x)) [meLoad x, meLoad x] 28)
      (cO := p01CtlAt (mk_value_e (loadedV x)) [meLoad x, meLoad x] 28)
      (rv := loadedV x)
      (hinv := fun σ h _ => p01_inv h) (hinvO := fun σ h => p01_inv h)
      (hctlI := fun p => rfl)
      (happ := fun p _ => p01r30F x p)
      (hIn := p01Shape (p01arF30 x) [meLoad x, meLoad x] 28)
      (hexit := fun p => rfl) (hctlO := fun p => rfl)
      (hthO := fun p => rfl) (hF := rfl)
      (hpost := by
        exact fun p => ⟨_, rfl, by
          show _ = intValue (max x 0)
          rw [show max x 0 = x from by omega]; rfl⟩)


/-! ## THE P01 WP (the round-granular obligation both statement
    faces consume) -/

theorem p01_wp (x : Int) (hx1 : -2147483648 ≤ x)
    (hx2 : x ≤ 2147483647) (seed : Nat) [inst : CerbStGS CerbStS] :
    (ctlIs (GF := CerbStS) stHalf
        (ctlOf (initial_driver_state_threaded seed p01File corpusFs)) ∗
      supIs stHalf
        (suppliesOf (initial_driver_state_threaded seed p01File corpusFs)) ∗
      mrestIs stHalf
        (memRestOf (initial_driver_state_threaded seed p01File corpusFs)) ∗
      domIs stHalf ([] : List Int)) ⊢
      WP (callK2 p01File.tagDefs p01File "clamp0" [intValue x])
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r : driver_result,
            o = Outcome.value r ∧ p01Spec x r⌝ }} := by
  iintro ⟨Hc, Hs, Hm, Hd⟩
  rw [p01_init_ctl_eq seed, p01_init_sup_eq seed,
    p01_init_mrest_eq seed]
  -- §1 THE CALLER PROTOCOL ------------------------------------------
  iapply (wpk_seq_ctl_sup_lk (GF := CerbStS)
    (upd := fun σ => p01dGσ fmapEmpty 1 0 0 seed σ.layout_state)
    (c' := p01dGCtl) (S' := ⟨1, 0, 0, seed⟩)
    (fun σ hσ hwf hsup => by
      rw [p01Init_inv hσ hsup]; exact p01k1_fam seed _)
    (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl) (fun σ _ _ _ => rfl)
    (fun σ hσ hwf hsup z => by
      rw [p01Init_inv hσ hsup]; rfl)
    (fun σ hσ hwf hsup => by
      rw [p01Init_inv hσ hsup]
      intro f hf
      cases hf with
      | head => exact Or.inl rfl
      | tail _ h => cases h))
  isplitl [Hc Hs]
  · iframe Hc Hs
  iintro ⟨Hc, Hs⟩
  iapply (wpk_seq_read_ctl (GF := CerbStS) (g := fun σ => σ)
    (c := p01dGCtl)
    (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
      ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
    (fun σ _ _ => app_nd_get σ) ?hwp1)
  case hwp1 =>
    intro σv hσv hwfv
    rw [show σv.core_file = p01File
      from RelSem.T1.coreFile_of_ctl hσv]
    iintro ⟨Hc, Hs, Hm, Hd⟩
    iapply (wpk_seq_read_ctl (GF := CerbStS)
      (g := fun _ => clampP01Sym) (c := p01dGCtl)
      (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
        ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
      (fun σ _ _ => p01k3_any σ) ?hwp2)
    case hwp2 =>
      intro σv2 hσv2 hwfv2
      iintro ⟨Hc, Hs, Hm, Hd⟩
      iapply (wpk_seq_read_ctl (GF := CerbStS)
        (g := fun _ => ([(symX, BTy_object OTy_pointer)], p01ar0))
        (c := p01dGCtl)
        (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
          ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
        (fun σ _ _ => p01k4_any σ) ?hwp3)
      case hwp3 =>
        intro σv3 hσv3 hwfv3
        iintro ⟨Hc, Hs, Hm, Hd⟩
        iapply (wpk_seq_read_ctl (GF := CerbStS)
          (g := fun _ => [signed_int]) (c := p01dGCtl)
          (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
            ∗ mrestIs stHalf mr0 ∗ domIs stHalf ([] : List Int)))
          (fun σ _ _ => p01k5_any σ) ?hwp4)
        case hwp4 =>
          intro σv4 hσv4 hwfv4
          iintro ⟨Hc, Hs, Hm, Hd⟩
          iapply (wpk_seq_alloc_store (GF := CerbStS) (mr := mr0)
            (ty := signed_int) (pref := PrefOther "callND arg")
            (alignN := 4) (sz := 4) (aNew := xAddr)
            (newBytes := xBytes x)
            rfl rfl rfl rfl
            (fun σ hmr hinv => p01k6_fam x σ hmr hinv))
          isplitl [Hm]
          · iexact Hm
          iintro ⟨Hm, Hax, Hpx⟩
          rw [show mrAlloc mr0 xAddr = mr1 from rfl]
          iapply (wpk_seq_read_ctl_dom (GF := CerbStS)
            (g := fun σ => σ.core_state0.thread_states)
            (c := p01dGCtl)
            (d := ([] : List Int))
            (R := iprop(supIs (GF := CerbStS) stHalf ⟨1, 0, 0, seed⟩
              ∗ mrestIs stHalf mr1
              ∗ allocIs mr0.nextAllocId (.own 1) allocXS
              ∗ pointsToBytes xAddr (.own 1) (xBytes x)))
            (fun σ _ _ => RelSem.Laws.get_ths_eq σ) ?hwp5)
          case hwp5 =>
            intro σv5 hσv5 hwfv5 hdomv5
            obtain ⟨pv, rfl⟩ := p01dG_inv hσv5
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
              (fun σ hmr hinv => p01k8_fam x σ hmr hinv))
            isplitl [Hm]
            · iexact Hm
            iintro ⟨Hm, Hae, Hpe⟩
            rw [show mrAlloc mr1 errAddr = mr2 from rfl]
            -- §2 THE SETUP: x's cell is BORN --------------------
            iapply (wpk_seq_birth1 (GF := CerbStS) (x := symX)
              (vNew := xPtrV) (d := ([] : List Int))
              (c := p01dGCtl) (c' := p01Ctl0)
              (upd := fun σ =>
                { σ with core_state0 := (update_thread_state 0
                    (p01Th0 p01ar0
                      (fmapAddBy (fun (s1 s2 : sym) =>
                        Lem_Basic_classes.ordCompare s1 s2)
                        symX xPtrV pv.f₀))
                    σ.core_state0) })
              (by simp)
              ?happ2
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p01dG_inv hσ; rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => rfl)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p01dG_inv hσ
                exact birth_new' rfl hf₀)
              (fun σ hσ hwf hdm z v' hzv => by
                exact absurd (hdm z v' hzv) (by simp))
              (fun σ hσ hwf hdm z v' hzv => by
                obtain ⟨pw, rfl⟩ := p01dG_inv hσ
                rcases birth_rev' rfl (b := symX) (v := xPtrV) hf₀
                    z v' hzv with ⟨v₀, hv₀⟩ | hnum
                · rw [hf₀none z] at hv₀; cases hv₀
                · exact Or.inr hnum)
              (fun σ hσ hwf hdm => by
                obtain ⟨pw, rfl⟩ := p01dG_inv hσ
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
            -- §3 THE BODY -----------------------------------------
            iapply (wpk_seq_read_ctl (GF := CerbStS)
              (g := fun σ => σ)
              (c := p01Ctl0)
              (R := iprop(supIs (GF := CerbStS) stHalf
                  ⟨1, 0, 0, seed⟩
                ∗ mrestIs stHalf mr2
                ∗ domIs stHalf pd1
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
                obtain ⟨pw, rfl⟩ := p01_inv0 hσv6; rfl]
              iintro ⟨Hc, Hs, Hm, Hd, HX, Hax, Hpx, Hae, Hpe⟩
              iapply (wp_expr_eq (GF := CerbStS)
                (e' := dnmsK p01File.tagDefs 1000000 fmapEmpty 0 []
                  (fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
                    KExpr.seq (driver2Rest p01File.tagDefs false
                        (driver2_lemFuel 999999 p01File.tagDefs)
                        tid_steps)
                      (fun _ => KExpr.seq nd_get (fun dr_st' =>
                        KExpr.done (Outcome.value
                          (finalize p01File.tagDefs "callND"
                            dr_st'))))))) ?heq)
              case heq => rfl
              -- §3 THE BODY: hand off to the stepper-run body lemma
              iapply (p01_body x seed hx1 hx2)
              isimp only [Seg.Ctx.interp, Seg.SegCtx, T1.env0, T1.al0,
                T1.bs0, Seg.envCells, Seg.allocCells, Seg.byteCells,
                Seg.domOf, List.map_cons, List.map_nil]
              iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
            iframe Hc Hs Hm Hd HX Hax Hpx Hae Hpe
          iframe Hc Hd Hs Hm Hax Hpx
        iframe Hc Hs Hm Hd
      iframe Hc Hs Hm Hd
    iframe Hc Hs Hm Hd
  iframe Hc Hs Hm Hd

/-! ## THE P01 THEOREMS -/

/-- P01's spec as an `FnSpec` — `verify_fn`'s role-1 object (V2
    revival at the Cns faces; must be reducible for the bridge's
    unification against the byte-stable statement text). -/
abbrev p01FnSpec : Seg.FnSpec Int :=
  { fname := "clamp0",
    args := fun x => [intValue x],
    pre := fun x => T1.intRange x,
    post := fun x r => p01Spec x r }

/-- **P01 (clamp) PROVED** — the registered statement, bridged by
    `verify_fn` (statement → the ∀-seed callK2 ledger sequent),
    discharged by the per-round assertion layer. -/
theorem p01_proved : P01Statement := by
  verify_fn p01FnSpec
  exact p01_wp a ha.1 ha.2 seed

/-- **P01 UB-freedom PROVED** (the same WP discharges it). -/
theorem p01_ubfree_proved : P01UBFreeStatement := by
  verify_fn p01FnSpec
  exact p01_wp a ha.1 ha.2 seed

end RelSem.P01

