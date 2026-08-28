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
import RelSem.CorpusStatements
import RelSem.SegmentFaces

set_option autoImplicit false

namespace RelSem.P01

open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Kit RelSem.Corpus
open RelSem.T1 (T1P RExpr aU intCty xAddr errAddr xPtr errPtr xPtrV
  loadedV xBytes allocX allocXS allocErrS zeroBytes mr0 mr1 mr2 symX
  meLoad birth_new birth_pres birth_rev birth_wfp t1Proj wp_expr_eq
  birth_new' birth_pres' birth_rev' birth_wfp')
open Iris Iris.BI Iris.ProgramLogic

/-! ## Family-map helpers (parser-friendly upds for the bind rounds) -/

@[reducible] def updB (ar : RExpr) (tr : List trace_event) (n : Nat)
    (pat : generic_pattern sym) (v : value)
    (σ : driver_state) : driver_state :=
  p01fam ar tr n
    { t1Proj σ with f₁ := update_env_aux pat v (t1Proj σ).f₁ }

@[reducible] def updP (ar : RExpr) (tr : List trace_event) (n : Nat)
    (σ : driver_state) : driver_state :=
  p01fam ar tr n (t1Proj σ)

/-! ## Ledger literals (the successive domain lists) -/

/-- After the setup (x) and the a_534 bind. -/
@[reducible] def pd1 : List Int := [symNum symX]
@[reducible] def pd2 : List Int := symNum symA534 :: pd1
@[reducible] def pd3 : List Int :=
  symNum symA535 :: symNum symA536 :: pd2
@[reducible] def pd4 : List Int :=
  symNum symA529 :: symNum symA530 :: pd3
@[reducible] def pd5 : List Int := symNum symA527 :: pd4
@[reducible] def pd6 : List Int := symNum symA526 :: pd5


/-! ## THE P01 WP (the round-granular obligation both statement
    faces consume) -/

set_option maxHeartbeats 8000000 in
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
              -- R0/R1: the constant operands evaluate (closed)
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := p01fam0)
                (c' := p01CtlAt p01ar1 [] 1)
                (upd := updP p01ar1 [] 1)
                (fun σ hσ hwf => p01_inv0 hσ)
                (fun p hwf => p01r0 p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := p01fam p01ar1 [] 1)
                (c' := p01CtlAt p01ar2 [] 2)
                (upd := updP p01ar2 [] 2)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf => p01r1 p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R2: x's cell read
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := p01fam p01ar2 [] 2) (x := symX) (vx := xPtrV)
                (c' := p01CtlAt p01ar3 [] 3)
                (upd := updP p01ar3 [] 3)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf hx => p01r2 p (p01fam_frame hwf) hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HX]
              · iframe Hc HX
              iintro ⟨Hc, HX⟩
              -- R3: a_534 BORN
              iapply (wpk_seq_birth1_fam (GF := CerbStS)
                (fam := p01fam p01ar3 [] 3) (x := symA534)
                (vNew := xPtrV) (d := pd1)
                (c' := p01CtlAt p01ar4 [] 4)
                (upd := updB p01ar4 [] 4 patA534 xPtrV)
                (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf hdm => p01r3 p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env symA534
                    [update_env_aux patA534 (xPtrV) p.f₁] = some (xPtrV)
                  rw [update_env_aux_a534]
                  exact birth_new (p01fam_frame hwf))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux patA534 (xPtrV) p.f₁] = some v'
                  rw [update_env_aux_a534]
                  exact birth_pres (p01fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux patA534 (xPtrV) p.f₁] = some v' := hzv
                  rw [update_env_aux_a534] at hzv'
                  exact birth_rev (p01fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux patA534 (xPtrV) p.f₁] := hf
                  rw [update_env_aux_a534] at hf'
                  cases hf' with
                  | head => exact birth_wfp (p01fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA534⟩
              -- R4: the Load operands (a_534 read)
              iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                (fam := p01fam p01ar4 [] 4) (x := symA534) (vx := xPtrV)
                (c' := p01CtlAt p01ar5 [] 5)
                (upd := updP p01ar5 [] 5)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf hx => p01r4 p hx)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                (fun p hwf hx => rfl) (fun p hwf hx => rfl))
              isplitl [Hc HA534]
              · iframe Hc HA534
              iintro ⟨Hc, HA534⟩
              -- R5: THE LOAD (x's bytes recombine to exactly x)
              iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                (c := p01CtlAt p01ar5 [] 5)
                (c' := p01CtlAt (p01ar6 x) [meLoad x] 5)
                (S := ⟨1, 0, 0, seed⟩) (S' := ⟨1, 1, 0, seed⟩)
                (mr := mr2) (aid := mr0.nextAllocId) (al := allocXS)
                (addr := xAddr) (bs := xBytes x)
                (upd := fun σ => p01σ (p01ar6 x) (t1Proj σ).f₁ (t1Proj σ).tS
                  ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS
                  (t1Proj σ).ls [meLoad x] 5)
                (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                  obtain ⟨p, rfl⟩ := p01_inv hσ
                  have hlum : p.ls.lastUsedUnionMembers = [] := by
                    rw [show p.ls.lastUsedUnionMembers
                      = (memRestOf (p01fam p01ar5 [] 5
                          p)).lastUsedUnionMembers from rfl, hmr]
                    rfl
                  have hfpm : p.ls.funptrmap = [] := by
                    rw [show p.ls.funptrmap
                      = (memRestOf (p01fam p01ar5 [] 5 p)).funptrmap
                      from rfl, hmr]
                    rfl
                  exact p01r5 x p hget hbytes hlum hfpm hinv hx1 hx2)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := p01_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := p01_inv hσ; rfl)
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := p01_inv hσ
                  have h := hsup
                  rw [show suppliesOf (p01fam p01ar5 [] 5 p)
                    = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                    Supplies.mk.injEq] at h
                  obtain ⟨h1, h2, h3, h4⟩ := h
                  show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                  rw [h1, h2, h3, h4])
                (fun σ hσ hwf hsup hmr => by
                  obtain ⟨p, rfl⟩ := p01_inv hσ; rfl))
              isplitl [Hc Hs Hm Hax Hpx]
              · iframe Hc Hs Hm Hax Hpx
              iintro ⟨Hc, Hs, Hm, Hax, Hpx⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := p01fam (p01ar6 x) [meLoad x] 5)
                (c' := p01CtlAt (p01ar7 x) [meLoad x] 6)
                (upd := updP (p01ar7 x) [meLoad x] 6)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf => p01r6 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- R7: (a_535, a_536) BORN (the tuple bind)
              iapply (wpk_seq_birth2_fam (GF := CerbStS)
                (fam := p01fam (p01ar7 x) [meLoad x] 6)
                (x₁ := symA535) (x₂ := symA536)
                (v₁ := loadedV x) (v₂ := loadedV 0) (d := pd2)
                (c' := p01CtlAt p01ar8 [meLoad x] 7)
                (upd := updB p01ar8 [meLoad x] 7 patT3536 (Vtuple [loadedV x, loadedV 0]))
                (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf hdm => p01r7 x p)
                (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                (fun p hwf hdm => rfl)
                (fun p hwf hdm => by
                  show lookup_env symA535
                    [update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁] = some (loadedV x)
                  rw [update_env_aux_3536 x]
                  exact dbl_new₁ (p01fam_frame hwf))
                (fun p hwf hdm => by
                  show lookup_env symA536
                    [update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁] = some (loadedV 0)
                  rw [update_env_aux_3536 x]
                  exact dbl_new₂ (p01fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                    (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                (fun p hwf hdm z v' hzv => by
                  show lookup_env z
                    [update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁] = some v'
                  rw [update_env_aux_3536 x]
                  exact dbl_pres (p01fam_frame hwf)
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                    (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                    (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) z v' hzv)
                (fun p hwf hdm z v' hzv => by
                  have hzv' : lookup_env z
                      [update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁] = some v' := hzv
                  rw [update_env_aux_3536 x] at hzv'
                  exact dbl_rev (p01fam_frame hwf) z v' hzv')
                (fun p hwf hdm => by
                  intro f hf
                  have hf' : f ∈ [update_env_aux patT3536 (Vtuple [loadedV x, loadedV 0]) p.f₁] := hf
                  rw [update_env_aux_3536 x] at hf'
                  cases hf' with
                  | head => exact dbl_wfp (p01fam_frame hwf)
                  | tail _ h => cases h))
              isplitl [Hc Hd]
              · iframe Hc Hd
              iintro ⟨Hc, Hd, HA535, HA536⟩
              -- R8: the scrutinee packs (a_535/a_536 read)
              iapply (wpk_seq_ctl_env2_fam (GF := CerbStS)
                (fam := p01fam p01ar8 [meLoad x] 7)
                (x₁ := symA535) (x₂ := symA536)
                (vx₁ := loadedV x) (vx₂ := loadedV 0)
                (c' := p01CtlAt (p01ar9 x) [meLoad x] 8)
                (upd := updP (p01ar9 x) [meLoad x] 8)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf hx1 hx2 => p01r8 x p hx1 hx2)
                (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl)
                (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl))
              isplitl [Hc HA535 HA536]
              · iframe Hc HA535 HA536
              iintro ⟨Hc, HA535, HA536⟩
              iapply (wpk_seq_ctl_fam (GF := CerbStS)
                (fam := p01fam (p01ar9 x) [meLoad x] 8)
                (c' := p01CtlAt (p01ar10 x) [meLoad x] 9)
                (upd := updP (p01ar10 x) [meLoad x] 9)
                (fun σ hσ hwf => p01_inv hσ)
                (fun p hwf => p01r9 x p)
                (fun p hwf => rfl) (fun p hwf => rfl)
                (fun p hwf => rfl) (fun p hwf => rfl))
              isplitl [Hc]
              · iexact Hc
              iintro Hc
              -- THE PATH SPLIT (the branch is symbolic in x)
              by_cases hlt : x < 0
              case pos =>
                -- R10 (T): the compare verdict
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar10 x) [meLoad x] 9)
                  (c' := p01CtlAt (p01ar11 1) [meLoad x] 10)
                  (upd := updP (p01ar11 1) [meLoad x] 10)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r10T x hx1 hx2 hlt p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar11 1) [meLoad x] 10)
                  (c' := p01CtlAt (p01ar12 1) [meLoad x] 11)
                  (upd := updP (p01ar12 1) [meLoad x] 11)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r11 1 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R12 (T): (a_529, a_530) BORN
                iapply (wpk_seq_birth2_fam (GF := CerbStS)
                  (fam := p01fam (p01ar12 1) [meLoad x] 11)
                  (x₁ := symA529) (x₂ := symA530)
                  (v₁ := loadedV 1) (v₂ := loadedV 0) (d := pd3)
                  (c' := p01CtlAt p01ar13 [meLoad x] 12)
                  (upd := updB p01ar13 [meLoad x] 12 patT2930 (Vtuple [loadedV 1, loadedV 0]))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r12 1 p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA529
                      [update_env_aux patT2930 (Vtuple [loadedV 1, loadedV 0]) p.f₁] = some (loadedV 1)
                    rw [update_env_aux_2930 1]
                    exact dbl_new₁ (p01fam_frame hwf))
                  (fun p hwf hdm => by
                    show lookup_env symA530
                      [update_env_aux patT2930 (Vtuple [loadedV 1, loadedV 0]) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_2930 1]
                    exact dbl_new₂ (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patT2930 (Vtuple [loadedV 1, loadedV 0]) p.f₁] = some v'
                    rw [update_env_aux_2930 1]
                    exact dbl_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patT2930 (Vtuple [loadedV 1, loadedV 0]) p.f₁] = some v' := hzv
                    rw [update_env_aux_2930 1] at hzv'
                    exact dbl_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patT2930 (Vtuple [loadedV 1, loadedV 0]) p.f₁] := hf
                    rw [update_env_aux_2930 1] at hf'
                    cases hf' with
                    | head => exact dbl_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA529, HA530⟩
                -- R13 (T): the EQ compare
                iapply (wpk_seq_ctl_env2_fam (GF := CerbStS)
                  (fam := p01fam p01ar13 [meLoad x] 12)
                  (x₁ := symA529) (x₂ := symA530)
                  (vx₁ := loadedV 1) (vx₂ := loadedV 0)
                  (c' := p01CtlAt (p01ar14 0) [meLoad x] 13)
                  (upd := updP (p01ar14 0) [meLoad x] 13)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx1 hx2 => p01r13T x p hx1 hx2)
                  (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl)
                  (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl))
                isplitl [Hc HA529 HA530]
                · iframe Hc HA529 HA530
                iintro ⟨Hc, HA529, HA530⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar14 0) [meLoad x] 13)
                  (c' := p01CtlAt (p01ar15 0) [meLoad x] 14)
                  (upd := updP (p01ar15 0) [meLoad x] 14)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r14 0 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R15 (T): a_527 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam (p01ar15 0) [meLoad x] 14) (x := symA527)
                  (vNew := loadedV 0) (d := pd4)
                  (c' := p01CtlAt p01ar16 [meLoad x] 15)
                  (upd := updB p01ar16 [meLoad x] 15 patA527 (loadedV 0))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r15 0 p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA527
                      [update_env_aux patA527 (loadedV 0) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_a527 0]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA527 (loadedV 0) p.f₁] = some v'
                    rw [update_env_aux_a527 0]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA527 (loadedV 0) p.f₁] = some v' := hzv
                    rw [update_env_aux_a527 0] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA527 (loadedV 0) p.f₁] := hf
                    rw [update_env_aux_a527 0] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA527⟩
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01ar16 [meLoad x] 15) (x := symA527) (vx := loadedV 0)
                  (c' := p01CtlAt (p01ar17 0) [meLoad x] 16)
                  (upd := updP (p01ar17 0) [meLoad x] 16)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r16 0 p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA527]
                · iframe Hc HA527
                iintro ⟨Hc, HA527⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar17 0) [meLoad x] 16)
                  (c' := p01CtlAt (p01ar18 0) [meLoad x] 17)
                  (upd := updP (p01ar18 0) [meLoad x] 17)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r17 0 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar18 0) [meLoad x] 17)
                  (c' := p01CtlAt (p01ar19 Vtrue) [meLoad x] 18)
                  (upd := updP (p01ar19 Vtrue) [meLoad x] 18)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r18T x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R19 (T): the guard cell a_526 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam (p01ar19 Vtrue) [meLoad x] 18) (x := symA526)
                  (vNew := Vtrue) (d := pd5)
                  (c' := p01CtlAt p01ar20 [meLoad x] 19)
                  (upd := updB p01ar20 [meLoad x] 19 patA526 Vtrue)
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r19 Vtrue p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA526
                      [update_env_aux patA526 (Vtrue) p.f₁] = some (Vtrue)
                    rw [update_env_aux_a526 Vtrue]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA526 (Vtrue) p.f₁] = some v'
                    rw [update_env_aux_a526 Vtrue]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA526 (Vtrue) p.f₁] = some v' := hzv
                    rw [update_env_aux_a526 Vtrue] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA526 (Vtrue) p.f₁] := hf
                    rw [update_env_aux_a526 Vtrue] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA526⟩
                -- R20 (T): the Eif takes the then-arm
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01ar20 [meLoad x] 19) (x := symA526) (vx := Vtrue)
                  (c' := p01CtlAt p01arT21 [meLoad x] 20)
                  (upd := updP p01arT21 [meLoad x] 20)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r20T x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA526]
                · iframe Hc HA526
                iintro ⟨Hc, HA526⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT21 [meLoad x] 20)
                  (c' := p01CtlAt p01arT22 [meLoad x] 21)
                  (upd := updP p01arT22 [meLoad x] 21)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r21T x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT22 [meLoad x] 21)
                  (c' := p01CtlAt p01arT23 [meLoad x] 22)
                  (upd := updP p01arT23 [meLoad x] 22)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r22T x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R23 (T): a_540 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam p01arT23 [meLoad x] 22) (x := symA540)
                  (vNew := loadedV 0) (d := pd6)
                  (c' := p01CtlAt p01arT24 [meLoad x] 23)
                  (upd := updB p01arT24 [meLoad x] 23 patA540 (loadedV 0))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r23T x p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA540
                      [update_env_aux patA540 (loadedV 0) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_a540]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA540 (loadedV 0) p.f₁] = some v'
                    rw [update_env_aux_a540]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA540 (loadedV 0) p.f₁] = some v' := hzv
                    rw [update_env_aux_a540] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA540 (loadedV 0) p.f₁] := hf
                    rw [update_env_aux_a540] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA540⟩
                -- R24 (T): the ret jump (a_540 read, a_543 BORN)
                iapply (wpk_seq_birth1_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arT24 [meLoad x] 23) (x := symA543)
                  (vNew := loadedV 0) (d := symNum symA540 :: pd6)
                  (y := symA540) (vy := loadedV 0)
                  (c' := p01CtlAt p01arT25 [meLoad x] 24)
                  (upd := updB p01arT25 [meLoad x] 24 (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV 0))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm hy => p01r24T x p hy)
                  (fun p hwf hdm hy => rfl) (fun p hwf hdm hy => rfl)
                  (fun p hwf hdm hy => rfl)
                  (fun p hwf hdm hy => by
                    show lookup_env symA543
                      [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV 0) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_a543 (loadedV 0)]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm hy z v' hzv => by
                    show lookup_env z
                      [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV 0) p.f₁] = some v'
                    rw [update_env_aux_a543 (loadedV 0)]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm hy z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV 0) p.f₁] = some v' := hzv
                    rw [update_env_aux_a543 (loadedV 0)] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm hy => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV 0) p.f₁] := hf
                    rw [update_env_aux_a543 (loadedV 0)] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd HA540]
                · iframe Hc Hd HA540
                iintro ⟨Hc, Hd, HA543, HA540⟩
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arT25 [meLoad x] 24) (x := symA543) (vx := loadedV 0)
                  (c' := p01CtlAt p01arT26 [meLoad x] 25)
                  (upd := updP p01arT26 [meLoad x] 25)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r25T x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA543]
                · iframe Hc HA543
                iintro ⟨Hc, HA543⟩
                iclear Hs
                iclear Hm
                iclear Hd
                iclear HX
                iclear HA534
                iclear HA535
                iclear HA536
                iclear HA529
                iclear HA530
                iclear HA527
                iclear HA526
                iclear HA540
                iclear HA543
                iclear Hax
                iclear Hpx
                iclear Hae
                iclear Hpe
                -- terminal (T): the done offer, the scheduler pick, the
                -- exit rebuild, the readout
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT26 [meLoad x] 25)
                  (c' := p01CtlAt p01arT26 [meLoad x] 25)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r26T x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT26 [meLoad x] 25)
                  (c' := p01CtlAt p01arT26 [meLoad x] 25)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => dnms_nil)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT26 [meLoad x] 25)
                  (c' := p01CtlAt p01arT26 [meLoad x] 25)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => ndctPick_one)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arT26 [meLoad x] 25)
                  (c' := p01CtlAt (mk_value_e (loadedV 0)) [meLoad x] 25)
                  (upd := fun σ =>
                    { σ with core_state0 :=
                        prepare_exit σ.core_state0 (loadedV 0) })
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => driver2Rest_done rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc

                iapply (wpk_get_done_ctl (GF := CerbStS)
                  (c := p01CtlAt (mk_value_e (loadedV 0)) [meLoad x] 25)
                  (fun σ hσ => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ
                    exact ⟨_, rfl, by
                      show _ = intValue (max x 0)
                      rw [show max x 0 = 0 from by omega]; rfl⟩))
                iexact Hc
              case neg =>
                -- R10 (F): the compare verdict
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar10 x) [meLoad x] 9)
                  (c' := p01CtlAt (p01ar11 0) [meLoad x] 10)
                  (upd := updP (p01ar11 0) [meLoad x] 10)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r10F x hx1 hx2 hlt p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar11 0) [meLoad x] 10)
                  (c' := p01CtlAt (p01ar12 0) [meLoad x] 11)
                  (upd := updP (p01ar12 0) [meLoad x] 11)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r11 0 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R12 (F): (a_529, a_530) BORN
                iapply (wpk_seq_birth2_fam (GF := CerbStS)
                  (fam := p01fam (p01ar12 0) [meLoad x] 11)
                  (x₁ := symA529) (x₂ := symA530)
                  (v₁ := loadedV 0) (v₂ := loadedV 0) (d := pd3)
                  (c' := p01CtlAt p01ar13 [meLoad x] 12)
                  (upd := updB p01ar13 [meLoad x] 12 patT2930 (Vtuple [loadedV 0, loadedV 0]))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r12 0 p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA529
                      [update_env_aux patT2930 (Vtuple [loadedV 0, loadedV 0]) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_2930 0]
                    exact dbl_new₁ (p01fam_frame hwf))
                  (fun p hwf hdm => by
                    show lookup_env symA530
                      [update_env_aux patT2930 (Vtuple [loadedV 0, loadedV 0]) p.f₁] = some (loadedV 0)
                    rw [update_env_aux_2930 0]
                    exact dbl_new₂ (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patT2930 (Vtuple [loadedV 0, loadedV 0]) p.f₁] = some v'
                    rw [update_env_aux_2930 0]
                    exact dbl_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]))
                      (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543]) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patT2930 (Vtuple [loadedV 0, loadedV 0]) p.f₁] = some v' := hzv
                    rw [update_env_aux_2930 0] at hzv'
                    exact dbl_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patT2930 (Vtuple [loadedV 0, loadedV 0]) p.f₁] := hf
                    rw [update_env_aux_2930 0] at hf'
                    cases hf' with
                    | head => exact dbl_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA529, HA530⟩
                -- R13 (F): the EQ compare
                iapply (wpk_seq_ctl_env2_fam (GF := CerbStS)
                  (fam := p01fam p01ar13 [meLoad x] 12)
                  (x₁ := symA529) (x₂ := symA530)
                  (vx₁ := loadedV 0) (vx₂ := loadedV 0)
                  (c' := p01CtlAt (p01ar14 1) [meLoad x] 13)
                  (upd := updP (p01ar14 1) [meLoad x] 13)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx1 hx2 => p01r13F x p hx1 hx2)
                  (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl)
                  (fun p hwf hx1 hx2 => rfl) (fun p hwf hx1 hx2 => rfl))
                isplitl [Hc HA529 HA530]
                · iframe Hc HA529 HA530
                iintro ⟨Hc, HA529, HA530⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar14 1) [meLoad x] 13)
                  (c' := p01CtlAt (p01ar15 1) [meLoad x] 14)
                  (upd := updP (p01ar15 1) [meLoad x] 14)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r14 1 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R15 (F): a_527 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam (p01ar15 1) [meLoad x] 14) (x := symA527)
                  (vNew := loadedV 1) (d := pd4)
                  (c' := p01CtlAt p01ar16 [meLoad x] 15)
                  (upd := updB p01ar16 [meLoad x] 15 patA527 (loadedV 1))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r15 1 p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA527
                      [update_env_aux patA527 (loadedV 1) p.f₁] = some (loadedV 1)
                    rw [update_env_aux_a527 1]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA527 (loadedV 1) p.f₁] = some v'
                    rw [update_env_aux_a527 1]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA527 (loadedV 1) p.f₁] = some v' := hzv
                    rw [update_env_aux_a527 1] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA527 (loadedV 1) p.f₁] := hf
                    rw [update_env_aux_a527 1] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA527⟩
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01ar16 [meLoad x] 15) (x := symA527) (vx := loadedV 1)
                  (c' := p01CtlAt (p01ar17 1) [meLoad x] 16)
                  (upd := updP (p01ar17 1) [meLoad x] 16)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r16 1 p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA527]
                · iframe Hc HA527
                iintro ⟨Hc, HA527⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar17 1) [meLoad x] 16)
                  (c' := p01CtlAt (p01ar18 1) [meLoad x] 17)
                  (upd := updP (p01ar18 1) [meLoad x] 17)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r17 1 p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01ar18 1) [meLoad x] 17)
                  (c' := p01CtlAt (p01ar19 Vfalse) [meLoad x] 18)
                  (upd := updP (p01ar19 Vfalse) [meLoad x] 18)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r18F x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R19 (F): the guard cell a_526 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam (p01ar19 Vfalse) [meLoad x] 18) (x := symA526)
                  (vNew := Vfalse) (d := pd5)
                  (c' := p01CtlAt p01ar20 [meLoad x] 19)
                  (upd := updB p01ar20 [meLoad x] 19 patA526 Vfalse)
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r19 Vfalse p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA526
                      [update_env_aux patA526 (Vfalse) p.f₁] = some (Vfalse)
                    rw [update_env_aux_a526 Vfalse]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA526 (Vfalse) p.f₁] = some v'
                    rw [update_env_aux_a526 Vfalse]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA526 (Vfalse) p.f₁] = some v' := hzv
                    rw [update_env_aux_a526 Vfalse] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA526 (Vfalse) p.f₁] := hf
                    rw [update_env_aux_a526 Vfalse] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA526⟩
                -- R20 (F): the Eif falls through
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01ar20 [meLoad x] 19) (x := symA526) (vx := Vfalse)
                  (c' := p01CtlAt p01arF21 [meLoad x] 20)
                  (upd := updP p01arF21 [meLoad x] 20)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r20F x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA526]
                · iframe Hc HA526
                iintro ⟨Hc, HA526⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam p01arF21 [meLoad x] 20)
                  (c' := p01CtlAt p01arF22 [meLoad x] 21)
                  (upd := updP p01arF22 [meLoad x] 21)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r21F x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R22 (F): x's cell read (the reload begins)
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arF22 [meLoad x] 21) (x := symX) (vx := xPtrV)
                  (c' := p01CtlAt p01arF23 [meLoad x] 22)
                  (upd := updP p01arF23 [meLoad x] 22)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r22F x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HX]
                · iframe Hc HX
                iintro ⟨Hc, HX⟩
                -- R23 (F): a_541 BORN
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam p01arF23 [meLoad x] 22) (x := symA541)
                  (vNew := xPtrV) (d := pd6)
                  (c' := p01CtlAt p01arF24 [meLoad x] 23)
                  (upd := updB p01arF24 [meLoad x] 23 patA541 xPtrV)
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r23F x p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA541
                      [update_env_aux patA541 (xPtrV) p.f₁] = some (xPtrV)
                    rw [update_env_aux_a541]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA541 (xPtrV) p.f₁] = some v'
                    rw [update_env_aux_a541]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA541 (xPtrV) p.f₁] = some v' := hzv
                    rw [update_env_aux_a541] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA541 (xPtrV) p.f₁] := hf
                    rw [update_env_aux_a541] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA541⟩
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arF24 [meLoad x] 23) (x := symA541) (vx := xPtrV)
                  (c' := p01CtlAt p01arF25 [meLoad x] 24)
                  (upd := updP p01arF25 [meLoad x] 24)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r24F x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA541]
                · iframe Hc HA541
                iintro ⟨Hc, HA541⟩
                -- R25 (F): THE SECOND LOAD (same owned bytes)
                iapply (wpk_seq_ctl_sup_mem (GF := CerbStS)
                  (c := p01CtlAt p01arF25 [meLoad x] 24)
                  (c' := p01CtlAt (p01arF26 x) [meLoad x, meLoad x] 24)
                  (S := ⟨1, 1, 0, seed⟩) (S' := ⟨1, 2, 0, seed⟩)
                  (mr := mr2) (aid := mr0.nextAllocId) (al := allocXS)
                  (addr := xAddr) (bs := xBytes x)
                  (upd := fun σ => p01σ (p01arF26 x) (t1Proj σ).f₁ (t1Proj σ).tS
                    ((t1Proj σ).aS + 1) (t1Proj σ).eS (t1Proj σ).sS
                    (t1Proj σ).ls [meLoad x, meLoad x] 24)
                  (fun σ hσ hwf hsup hmr hget hbytes hinv => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ
                    have hlum : p.ls.lastUsedUnionMembers = [] := by
                      rw [show p.ls.lastUsedUnionMembers
                        = (memRestOf (p01fam p01arF25 [meLoad x] 24
                            p)).lastUsedUnionMembers from rfl, hmr]
                      rfl
                    have hfpm : p.ls.funptrmap = [] := by
                      rw [show p.ls.funptrmap
                        = (memRestOf (p01fam p01arF25 [meLoad x] 24 p)).funptrmap
                        from rfl, hmr]
                      rfl
                    exact p01r25F x p hget hbytes hlum hfpm hinv hx1 hx2)
                  (fun σ hσ hwf hsup hmr => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ; rfl)
                  (fun σ hσ hwf hsup hmr => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ; rfl)
                  (fun σ hσ hwf hsup hmr => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ
                    have h := hsup
                    rw [show suppliesOf (p01fam p01arF25 [meLoad x] 24 p)
                      = ⟨p.tS, p.aS, p.eS, p.sS⟩ from rfl,
                      Supplies.mk.injEq] at h
                    obtain ⟨h1, h2, h3, h4⟩ := h
                    show (⟨p.tS, p.aS + 1, p.eS, p.sS⟩ : Supplies) = _
                    rw [h1, h2, h3, h4])
                  (fun σ hσ hwf hsup hmr => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ; rfl))
                isplitl [Hc Hs Hm Hax Hpx]
                · iframe Hc Hs Hm Hax Hpx
                iintro ⟨Hc, Hs, Hm, Hax, Hpx⟩
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01arF26 x) [meLoad x, meLoad x] 24)
                  (c' := p01CtlAt (p01arF27 x) [meLoad x, meLoad x] 25)
                  (upd := updP (p01arF27 x) [meLoad x, meLoad x] 25)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r26F x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                -- R27 (F): a_542 BORN (the reloaded x)
                iapply (wpk_seq_birth1_fam (GF := CerbStS)
                  (fam := p01fam (p01arF27 x) [meLoad x, meLoad x] 25) (x := symA542)
                  (vNew := loadedV x) (d := symNum symA541 :: pd6)
                  (c' := p01CtlAt p01arF28 [meLoad x, meLoad x] 26)
                  (upd := updB p01arF28 [meLoad x, meLoad x] 26 patA542 (loadedV x))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm => p01r27F x p)
                  (fun p hwf hdm => rfl) (fun p hwf hdm => rfl)
                  (fun p hwf hdm => rfl)
                  (fun p hwf hdm => by
                    show lookup_env symA542
                      [update_env_aux patA542 (loadedV x) p.f₁] = some (loadedV x)
                    rw [update_env_aux_a542 x]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm z v' hzv => by
                    show lookup_env z
                      [update_env_aux patA542 (loadedV x) p.f₁] = some v'
                    rw [update_env_aux_a542 x]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux patA542 (loadedV x) p.f₁] = some v' := hzv
                    rw [update_env_aux_a542 x] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux patA542 (loadedV x) p.f₁] := hf
                    rw [update_env_aux_a542 x] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd]
                · iframe Hc Hd
                iintro ⟨Hc, Hd, HA542⟩
                -- R28 (F): the ret jump (a_542 read, a_543 BORN)
                iapply (wpk_seq_birth1_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arF28 [meLoad x, meLoad x] 26) (x := symA543)
                  (vNew := loadedV x) (d := symNum symA542 :: symNum symA541 :: pd6)
                  (y := symA542) (vy := loadedV x)
                  (c' := p01CtlAt p01arF29 [meLoad x, meLoad x] 27)
                  (upd := updB p01arF29 [meLoad x, meLoad x] 27 (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV x))
                  (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hdm hy => p01r28F x hx1 hx2 p hy)
                  (fun p hwf hdm hy => rfl) (fun p hwf hdm hy => rfl)
                  (fun p hwf hdm hy => rfl)
                  (fun p hwf hdm hy => by
                    show lookup_env symA543
                      [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some (loadedV x)
                    rw [update_env_aux_a543 (loadedV x)]
                    exact birth_new (p01fam_frame hwf))
                  (fun p hwf hdm hy z v' hzv => by
                    show lookup_env z
                      [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some v'
                    rw [update_env_aux_a543 (loadedV x)]
                    exact birth_pres (p01fam_frame hwf)
                      (clsNone (fun z v h => hdm z v h) (by simp [symNum, symX, symA534, symA535, symA536, symA529, symA530, symA527, symA526, symA540, symA541, symA542, symA543])) z v' hzv)
                  (fun p hwf hdm hy z v' hzv => by
                    have hzv' : lookup_env z
                        [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] = some v' := hzv
                    rw [update_env_aux_a543 (loadedV x)] at hzv'
                    exact birth_rev (p01fam_frame hwf) z v' hzv')
                  (fun p hwf hdm hy => by
                    intro f hf
                    have hf' : f ∈ [update_env_aux (mk_sym_pat symA543 (BTy_loaded OTy_integer)) (loadedV x) p.f₁] := hf
                    rw [update_env_aux_a543 (loadedV x)] at hf'
                    cases hf' with
                    | head => exact birth_wfp (p01fam_frame hwf)
                    | tail _ h => cases h))
                isplitl [Hc Hd HA542]
                · iframe Hc Hd HA542
                iintro ⟨Hc, Hd, HA543, HA542⟩
                iapply (wpk_seq_ctl_env1_fam (GF := CerbStS)
                  (fam := p01fam p01arF29 [meLoad x, meLoad x] 27) (x := symA543) (vx := loadedV x)
                  (c' := p01CtlAt (p01arF30 x) [meLoad x, meLoad x] 28)
                  (upd := updP (p01arF30 x) [meLoad x, meLoad x] 28)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf hx => p01r29F x p hx)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl)
                  (fun p hwf hx => rfl) (fun p hwf hx => rfl))
                isplitl [Hc HA543]
                · iframe Hc HA543
                iintro ⟨Hc, HA543⟩
                iclear Hs
                iclear Hm
                iclear Hd
                iclear HX
                iclear HA534
                iclear HA535
                iclear HA536
                iclear HA529
                iclear HA530
                iclear HA527
                iclear HA526
                iclear HA541
                iclear HA542
                iclear HA543
                iclear Hax
                iclear Hpx
                iclear Hae
                iclear Hpe
                -- terminal (F): the done offer, the scheduler pick, the
                -- exit rebuild, the readout
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01arF30 x) [meLoad x, meLoad x] 28)
                  (c' := p01CtlAt (p01arF30 x) [meLoad x, meLoad x] 28)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => p01r30F x p)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01arF30 x) [meLoad x, meLoad x] 28)
                  (c' := p01CtlAt (p01arF30 x) [meLoad x, meLoad x] 28)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => dnms_nil)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01arF30 x) [meLoad x, meLoad x] 28)
                  (c' := p01CtlAt (p01arF30 x) [meLoad x, meLoad x] 28)
                  (upd := fun σ => σ)
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => ndctPick_one)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc
                iapply (wpk_seq_ctl_fam (GF := CerbStS)
                  (fam := p01fam (p01arF30 x) [meLoad x, meLoad x] 28)
                  (c' := p01CtlAt (mk_value_e (loadedV x)) [meLoad x, meLoad x] 28)
                  (upd := fun σ =>
                    { σ with core_state0 :=
                        prepare_exit σ.core_state0 (loadedV x) })
                  (fun σ hσ hwf => p01_inv hσ)
                  (fun p hwf => driver2Rest_done rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl)
                  (fun p hwf => rfl) (fun p hwf => rfl))
                isplitl [Hc]
                · iexact Hc
                iintro Hc

                iapply (wpk_get_done_ctl (GF := CerbStS)
                  (c := p01CtlAt (mk_value_e (loadedV x)) [meLoad x, meLoad x] 28)
                  (fun σ hσ => by
                    obtain ⟨p, rfl⟩ := p01_inv hσ
                    exact ⟨_, rfl, by
                      show _ = intValue (max x 0)
                      rw [show max x 0 = x from by omega]; rfl⟩))
                iexact Hc
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

