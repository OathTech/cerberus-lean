/-
  RelSem.T5Iter — arc-11 S2 (2026-08-21): T5 ITERATION GROUNDWORK,
  wave 1 — THE ENV-LOOKUP FAMILY (the §11.2 hypothesis-mediated
  route, S2 record: docs/2026-08-21_arc11-s2-build.md).

  Proves the St-v2 environment family's lookup laws through Kit/Map's
  FmapBuilt + lookup engine: built-ness of `envL` at every index, the
  whole-chain lookup of the parameter pointer (`envL_lookup_n` — the
  two stuck-seed keys discharge from hdig/hseed + the slate j-bound),
  and the chain-head lookups (`envL_lookup_i`/`envL_lookup_s`).
  Consumed by the hbody climb as walker context facts (the
  equation-fact chase; kernel-side fact matching).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.T5Prefix

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T1 (memD3 intCty xPtr xAddr xPtrV)

/-! ## Comparator NE/EQ helpers -/

theorem symCmpO_ne_of_id (d1 d2 : String) (n1 n2 : Nat)
    (s1 s2 : symbol_description) (h : n1 ≠ n2) :
    symCmpO (Symbol d1 n1 s1) (Symbol d2 n2 s2) ≠ .eq :=
  fun hc => h ((symCmpO_eq_iff d1 d2 n1 n2 s1 s2).mp hc).2

theorem symCmpO_self (d : String) (n : Nat) (s : symbol_description) :
    symCmpO (Symbol d n s) (Symbol d n s) = .eq :=
  (symCmpO_eq_iff d d n n s s).mpr ⟨rfl, rfl⟩

/-! ## Built-ness of the env family -/

theorem e0_built : FmapBuilt symCmpO e0 := rfl

theorem eIns_built {k : sym} {v : value} {m : Fmap sym value}
    (h : FmapBuilt symCmpO m) : FmapBuilt symCmpO (eIns k v m) :=
  fmapAddBy_built h

theorem envL_built (n : Int) (j : Nat) : FmapBuilt symCmpO (envL n j) := by
  induction j with
  | zero =>
    show FmapBuilt symCmpO (eIns _ _ (eIns _ _ (eIns _ _ (eIns _ _
      (eIns _ _ (eIns _ _ e0))))))
    iterate 6 apply eIns_built
    exact e0_built
  | succ j ih =>
    show FmapBuilt symCmpO (envIter n j (envL n j))
    unfold envIter
    iterate 23 apply eIns_built
    exact ih

/-- Skip law at the family spelling. -/
theorem lookup_eIns_ne {a k : sym} {v : value} {m : Fmap sym value}
    (hm : FmapBuilt symCmpO m) (h : symCmpO k a ≠ .eq) :
    fmapLookupBy symOrd a (eIns k v m) = fmapLookupBy symOrd a m :=
  fmapLookupBy_addBy_ne hm h

/-- Hit law at the family spelling. -/
theorem lookup_eIns_eq {a k : sym} {v : value} {m : Fmap sym value}
    (hm : FmapBuilt symCmpO m) (h : symCmpO k a = .eq) :
    fmapLookupBy symOrd a (eIns k v m) = some v :=
  fmapLookupBy_addBy_eq hm h

/-! ## The lookup family (symN through the whole chain; symI/symS at
    the chain head) -/

/-- envL lookup of `n`'s pointer (descends the whole chain; the two
    stuck-seed keys need hdig/hseed + the j-bound). -/
theorem envL_lookup_n (n : Int) (j : Nat) (hj : j ≤ 100)
    (hdig : CerberusFresh.digest () = "")
    (hseed : seedT5 = 1048577) :
    fmapLookupBy symOrd symN (envL n j) = some xPtrV := by
  induction j with
  | zero => rfl
  | succ j ih =>
    have hj' : j ≤ 100 := Nat.le_of_succ_le hj
    show fmapLookupBy symOrd symN (envIter n j (envL n j)) = _
    unfold envIter
    have b0 := envL_built n j
    have b1 := eIns_built (k := symA543) (v := RelSem.T1.xPtrV) b0
    have b2 := eIns_built (k := symA542) (v := iPtrV) b1
    have b3 := eIns_built (k := symA545) (v := ldi n) b2
    have b4 := eIns_built (k := symA544) (v := ldi j) b3
    have b5 := eIns_built (k := symA538) (v := ldi 0) b4
    have b6 := eIns_built (k := symA537) (v := ldi 1) b5
    have b7 := eIns_built (k := symA535) (v := ldi 0) b6
    have b8 := eIns_built (k := symA532) (v := Vtrue) b7
    have b9 := eIns_built (k := symA556) (v := iPtrV) b8
    have b10 := eIns_built (k := symA555) (v := sPtrV) b9
    have b11 := eIns_built (k := symA550) (v := ldi (sV j)) b10
    have b12 := eIns_built (k := symA551) (v := ldi j) b11
    have b13 := eIns_built (k := symA557) (v := ldi (sV j + (j : Int))) b12
    have b14 := eIns_built (k := symA549) (v := sPtrV) b13
    have b15 := eIns_built (k := unitSym (2*j)) (v := ldi (sV j + (j : Int))) b14
    have b16 := eIns_built (k := symA564) (v := iPtrV) b15
    have b17 := eIns_built (k := symA560) (v := ldi 1) b16
    have b18 := eIns_built (k := symA559) (v := ldi j) b17
    have b19 := eIns_built (k := symA565) (v := ldi ((j : Int) + 1)) b18
    have b20 := eIns_built (k := symA558) (v := iPtrV) b19
    have b21 := eIns_built (k := unitSym (2*j+1)) (v := ldi ((j : Int) + 1)) b20
    have b22 := eIns_built (k := symI) (v := iPtrV) b21
    -- the two stuck-seed NE facts
    have hu0 : symCmpO (unitSym (2*j)) symN ≠ .eq := by
      show symCmpO (Symbol (CerberusFresh.digest ()) (seedT5 + 2*j)
        SD_None) symN ≠ .eq
      rw [hdig, hseed]
      exact symCmpO_ne_of_id _ _ _ _ _ _ (by omega)
    have hu1 : symCmpO (unitSym (2*j+1)) symN ≠ .eq := by
      show symCmpO (Symbol (CerberusFresh.digest ()) (seedT5 + (2*j+1))
        SD_None) symN ≠ .eq
      rw [hdig, hseed]
      exact symCmpO_ne_of_id _ _ _ _ _ _ (by omega)
    rw [lookup_eIns_ne b22 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b21 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b20 hu1,
        lookup_eIns_ne b19 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b18 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b17 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b16 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b15 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b14 hu0,
        lookup_eIns_ne b13 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b12 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b11 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b10 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b9 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b8 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b7 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b6 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b5 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b4 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b3 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b2 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b1 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide)),
        lookup_eIns_ne b0 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
    exact ih hj'

/-- symI at the chain (second insert at both branches). -/
theorem envL_lookup_i (n : Int) (j : Nat) :
    fmapLookupBy symOrd symI (envL n j) = some iPtrV := by
  cases j with
  | zero => rfl
  | succ j =>
    show fmapLookupBy symOrd symI (envIter n j (envL n j)) = _
    unfold envIter
    have b21 : FmapBuilt symCmpO (eIns (unitSym (2*j+1))
        (ldi ((j : Int) + 1)) (eIns symA558 iPtrV (eIns symA565
        (ldi ((j : Int) + 1)) (eIns symA559 (ldi j) (eIns symA560
        (ldi 1) (eIns symA564 iPtrV (eIns (unitSym (2*j))
        (ldi (sV j + (j : Int))) (eIns symA549 sPtrV (eIns symA557
        (ldi (sV j + (j : Int))) (eIns symA551 (ldi j) (eIns symA550
        (ldi (sV j)) (eIns symA555 sPtrV (eIns symA556 iPtrV
        (eIns symA532 Vtrue (eIns symA535 (ldi 0) (eIns symA537
        (ldi 1) (eIns symA538 (ldi 0) (eIns symA544 (ldi j)
        (eIns symA545 (ldi n) (eIns symA542 iPtrV (eIns symA543 xPtrV
        (envL n j)))))))))))))))))))))) := by
      iterate 21 apply eIns_built
      exact envL_built n j
    have b22 := eIns_built (k := symI) (v := iPtrV) b21
    rw [lookup_eIns_ne b22 (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
    exact lookup_eIns_eq b21 (symCmpO_self _ _ _)

/-- symS at the chain head. -/
theorem envL_lookup_s (n : Int) (j : Nat) :
    fmapLookupBy symOrd symS (envL n j) = some sPtrV := by
  cases j with
  | zero => rfl
  | succ j =>
    show fmapLookupBy symOrd symS (envIter n j (envL n j)) = _
    unfold envIter
    have b22 : FmapBuilt symCmpO (eIns symI iPtrV (eIns (unitSym (2*j+1))
        (ldi ((j : Int) + 1)) (eIns symA558 iPtrV (eIns symA565
        (ldi ((j : Int) + 1)) (eIns symA559 (ldi j) (eIns symA560
        (ldi 1) (eIns symA564 iPtrV (eIns (unitSym (2*j))
        (ldi (sV j + (j : Int))) (eIns symA549 sPtrV (eIns symA557
        (ldi (sV j + (j : Int))) (eIns symA551 (ldi j) (eIns symA550
        (ldi (sV j)) (eIns symA555 sPtrV (eIns symA556 iPtrV
        (eIns symA532 Vtrue (eIns symA535 (ldi 0) (eIns symA537
        (ldi 1) (eIns symA538 (ldi 0) (eIns symA544 (ldi j)
        (eIns symA545 (ldi n) (eIns symA542 iPtrV (eIns symA543 xPtrV
        (envL n j))))))))))))))))))))))) := by
      iterate 22 apply eIns_built
      exact envL_built n j
    exact lookup_eIns_eq b22 (symCmpO_self _ _ _)

end RelSem.T5
