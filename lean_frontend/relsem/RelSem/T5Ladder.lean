/-
  RelSem.T5Ladder — arc/t5-seal (2026-08-23): T5 ITERATION GROUNDWORK,
  wave 2 — THE INTERSTITIAL PREFIX-ENV LOOKUP LADDER (audit W-1
  promotion; the arc-15 resumption record §4's "promotion plan"
  executed: the ProbeT5S4c have-fact ladder, validated to 13/79 on
  the symbolic-j hbody walk, restated as committed theorems).

  Shape: `envP1 … envP22` are the 22 interstitial prefixes of the
  iteration env chain (`envIter n k` applied oldest-first over
  `envL n k` — the environments the walk's chase materializes
  mid-round), one `envPi_built` per prefix, and one lookup lemma per
  ladder entry (probe names in comments). The walker consumes these
  as context facts via the equation-fact chase (kernel-side defeq
  matching crosses the def wrappers and the `(k := j+1)` cast
  spellings — validated by the probe reaching 13/79 on exactly these
  statements).

  The three unitSym-crossing lookups (p15/p21/p22) take the stuck-seed
  hypotheses (`hdig`/`hseed`) + the slate iteration bound (`hk`),
  exactly the `envL_lookup_n` discipline (T5Iter).

  House rules: no sorry, no axioms. Under the in-build audit
  (Audit.lean pins the family's cones exactly).
-/

import RelSem.T5Iter

set_option autoImplicit false

namespace RelSem.T5

open RelSem RelSem.Cerb RelSem.Slate RelSem.Kit
open RelSem.T1 (xPtrV)

/-! ## The interstitial prefix-env family (envIter n k's inserts,
    oldest-first over `envL n k`; the probe instantiates `k := j+1`) -/

def envP1 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA543 xPtrV (envL n k)
def envP2 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA542 iPtrV (envP1 n k)
def envP3 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA545 (ldi n) (envP2 n k)
def envP4 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA544 (ldi k) (envP3 n k)
def envP5 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA538 (ldi 0) (envP4 n k)
def envP6 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA537 (ldi 1) (envP5 n k)
def envP7 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA535 (ldi 0) (envP6 n k)
def envP8 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA532 Vtrue (envP7 n k)
def envP9 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA556 iPtrV (envP8 n k)
def envP10 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA555 sPtrV (envP9 n k)
def envP11 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA550 (ldi (sV k)) (envP10 n k)
def envP12 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA551 (ldi k) (envP11 n k)
def envP13 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA557 (ldi (sV k + (k : Int))) (envP12 n k)
def envP14 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA549 sPtrV (envP13 n k)
def envP15 (n : Int) (k : Nat) : Fmap sym value :=
  eIns (unitSym (2*k)) (ldi (sV k + (k : Int))) (envP14 n k)
def envP16 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA564 iPtrV (envP15 n k)
def envP17 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA560 (ldi 1) (envP16 n k)
def envP18 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA559 (ldi k) (envP17 n k)
def envP19 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA565 (ldi ((k : Int) + 1)) (envP18 n k)
def envP20 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symA558 iPtrV (envP19 n k)
def envP21 (n : Int) (k : Nat) : Fmap sym value :=
  eIns (unitSym (2*k+1)) (ldi ((k : Int) + 1)) (envP20 n k)
def envP22 (n : Int) (k : Nat) : Fmap sym value :=
  eIns symI iPtrV (envP21 n k)

/-- Coherence: the full iteration chain is exactly one more insert on
    the deepest prefix (a rfl pin — the prefixes cannot drift from
    `envIter`). -/
theorem envP22_spec (n : Int) (k : Nat) :
    envL n (k+1) = eIns symS sPtrV (envP22 n k) := rfl

/-! ## Built-ness of every prefix -/

theorem envP1_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP1 n k) :=
  eIns_built (envL_built n k)
theorem envP2_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP2 n k) :=
  eIns_built (envP1_built n k)
theorem envP3_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP3 n k) :=
  eIns_built (envP2_built n k)
theorem envP4_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP4 n k) :=
  eIns_built (envP3_built n k)
theorem envP5_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP5 n k) :=
  eIns_built (envP4_built n k)
theorem envP6_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP6 n k) :=
  eIns_built (envP5_built n k)
theorem envP7_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP7 n k) :=
  eIns_built (envP6_built n k)
theorem envP8_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP8 n k) :=
  eIns_built (envP7_built n k)
theorem envP9_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP9 n k) :=
  eIns_built (envP8_built n k)
theorem envP10_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP10 n k) :=
  eIns_built (envP9_built n k)
theorem envP11_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP11 n k) :=
  eIns_built (envP10_built n k)
theorem envP12_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP12 n k) :=
  eIns_built (envP11_built n k)
theorem envP13_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP13 n k) :=
  eIns_built (envP12_built n k)
theorem envP14_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP14 n k) :=
  eIns_built (envP13_built n k)
theorem envP15_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP15 n k) :=
  eIns_built (envP14_built n k)
theorem envP16_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP16 n k) :=
  eIns_built (envP15_built n k)
theorem envP17_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP17 n k) :=
  eIns_built (envP16_built n k)
theorem envP18_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP18 n k) :=
  eIns_built (envP17_built n k)
theorem envP19_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP19 n k) :=
  eIns_built (envP18_built n k)
theorem envP20_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP20 n k) :=
  eIns_built (envP19_built n k)
theorem envP21_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP21 n k) :=
  eIns_built (envP20_built n k)
theorem envP22_built (n : Int) (k : Nat) : FmapBuilt symCmpO (envP22 n k) :=
  eIns_built (envP21_built n k)

/-! ## unitSym comparator NE (stuck-seed keys; the `envL_lookup_n`
    discipline: hdig/hseed pin the extern reads, the slate bound
    feeds omega) -/

theorem unitSym_cmp_ne (j : Nat) (a : sym)
    (hdig : CerberusFresh.digest () = "")
    (hseed : seedT5 = 1048577)
    (hj : j ≤ 700) (ha : 1050000 < symId a) :
    symCmpO (unitSym j) a ≠ .eq := by
  cases a with
  | Symbol d m sd =>
    show symCmpO (Symbol (CerberusFresh.digest ()) (seedT5 + j) SD_None)
      (Symbol d m sd) ≠ .eq
    rw [hdig, hseed]
    have hm : 1050000 < m := ha
    exact symCmpO_ne_of_id _ _ _ _ _ _ (by omega)

/-! ## The lookup ladder (one lemma per probe entry; probe hypothesis
    names in comments — the r-round progression's fact supply) -/

-- hlk513
theorem envP1_lookup_a543 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA543 (envP1 n k) = some xPtrV :=
  lookup_eIns_eq (envL_built n k) (symCmpO_self _ _ _)

-- hpI1
theorem envP1_lookup_i (n : Int) (k : Nat) :
    fmapLookupBy symOrd symI (envP1 n k) = some iPtrV := by
  show fmapLookupBy symOrd symI (eIns symA543 xPtrV (envL n k)) = _
  rw [lookup_eIns_ne (envL_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envL_lookup_i n k

-- hlk512
theorem envP2_lookup_a542 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA542 (envP2 n k) = some iPtrV :=
  lookup_eIns_eq (envP1_built n k) (symCmpO_self _ _ _)

-- hpA543_2
theorem envP2_lookup_a543 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA543 (envP2 n k) = some xPtrV := by
  show fmapLookupBy symOrd symA543 (eIns symA542 iPtrV (envP1 n k)) = _
  rw [lookup_eIns_ne (envP1_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP1_lookup_a543 n k

-- hpA542_3
theorem envP3_lookup_a542 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA542 (envP3 n k) = some iPtrV := by
  show fmapLookupBy symOrd symA542 (eIns symA545 (ldi n) (envP2 n k)) = _
  rw [lookup_eIns_ne (envP2_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP2_lookup_a542 n k

-- hpA544_4
theorem envP4_lookup_a544 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA544 (envP4 n k) = some (ldi k) :=
  lookup_eIns_eq (envP3_built n k) (symCmpO_self _ _ _)

-- hpA545_4
theorem envP4_lookup_a545 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA545 (envP4 n k) = some (ldi n) := by
  show fmapLookupBy symOrd symA545 (eIns symA544 (ldi k) (envP3 n k)) = _
  rw [lookup_eIns_ne (envP3_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP2_built n k) (symCmpO_self _ _ _)

-- hpA537_6
theorem envP6_lookup_a537 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA537 (envP6 n k) = some (ldi 1) :=
  lookup_eIns_eq (envP5_built n k) (symCmpO_self _ _ _)

-- hpA538_6
theorem envP6_lookup_a538 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA538 (envP6 n k) = some (ldi 0) := by
  show fmapLookupBy symOrd symA538 (eIns symA537 (ldi 1) (envP5 n k)) = _
  rw [lookup_eIns_ne (envP5_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP4_built n k) (symCmpO_self _ _ _)

-- hpA544_7
theorem envP7_lookup_a544 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA544 (envP7 n k) = some (ldi k) := by
  show fmapLookupBy symOrd symA544 (eIns symA535 (ldi 0) (envP6 n k)) = _
  rw [lookup_eIns_ne (envP6_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symA544 (eIns symA537 (ldi 1) (envP5 n k)) = _
  rw [lookup_eIns_ne (envP5_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symA544 (eIns symA538 (ldi 0) (envP4 n k)) = _
  rw [lookup_eIns_ne (envP4_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP4_lookup_a544 n k

-- hpA545_7
theorem envP7_lookup_a545 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA545 (envP7 n k) = some (ldi n) := by
  show fmapLookupBy symOrd symA545 (eIns symA535 (ldi 0) (envP6 n k)) = _
  rw [lookup_eIns_ne (envP6_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symA545 (eIns symA537 (ldi 1) (envP5 n k)) = _
  rw [lookup_eIns_ne (envP5_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symA545 (eIns symA538 (ldi 0) (envP4 n k)) = _
  rw [lookup_eIns_ne (envP4_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP4_lookup_a545 n k

-- hpI8
theorem envP8_lookup_i (n : Int) (k : Nat) :
    fmapLookupBy symOrd symI (envP8 n k) = some iPtrV := by
  show fmapLookupBy symOrd symI (eIns symA532 Vtrue (envP7 n k)) = _
  rw [lookup_eIns_ne (envP7_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA535 (ldi 0) (envP6 n k)) = _
  rw [lookup_eIns_ne (envP6_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA537 (ldi 1) (envP5 n k)) = _
  rw [lookup_eIns_ne (envP5_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA538 (ldi 0) (envP4 n k)) = _
  rw [lookup_eIns_ne (envP4_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA544 (ldi k) (envP3 n k)) = _
  rw [lookup_eIns_ne (envP3_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA545 (ldi n) (envP2 n k)) = _
  rw [lookup_eIns_ne (envP2_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA542 iPtrV (envP1 n k)) = _
  rw [lookup_eIns_ne (envP1_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP1_lookup_i n k

-- hpS9
theorem envP9_lookup_s (n : Int) (k : Nat) :
    fmapLookupBy symOrd symS (envP9 n k) = some sPtrV := by
  show fmapLookupBy symOrd symS (eIns symA556 iPtrV (envP8 n k)) = _
  rw [lookup_eIns_ne (envP8_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA532 Vtrue (envP7 n k)) = _
  rw [lookup_eIns_ne (envP7_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA535 (ldi 0) (envP6 n k)) = _
  rw [lookup_eIns_ne (envP6_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA537 (ldi 1) (envP5 n k)) = _
  rw [lookup_eIns_ne (envP5_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA538 (ldi 0) (envP4 n k)) = _
  rw [lookup_eIns_ne (envP4_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA544 (ldi k) (envP3 n k)) = _
  rw [lookup_eIns_ne (envP3_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA545 (ldi n) (envP2 n k)) = _
  rw [lookup_eIns_ne (envP2_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA542 iPtrV (envP1 n k)) = _
  rw [lookup_eIns_ne (envP1_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA543 xPtrV (envL n k)) = _
  rw [lookup_eIns_ne (envL_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envL_lookup_s n k

-- hpA555_10
theorem envP10_lookup_a555 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA555 (envP10 n k) = some sPtrV :=
  lookup_eIns_eq (envP9_built n k) (symCmpO_self _ _ _)

-- hpA556_11
theorem envP11_lookup_a556 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA556 (envP11 n k) = some iPtrV := by
  show fmapLookupBy symOrd symA556 (eIns symA550 (ldi (sV k)) (envP10 n k)) = _
  rw [lookup_eIns_ne (envP10_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symA556 (eIns symA555 sPtrV (envP9 n k)) = _
  rw [lookup_eIns_ne (envP9_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP8_built n k) (symCmpO_self _ _ _)

-- hpA550_12
theorem envP12_lookup_a550 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA550 (envP12 n k) = some (ldi (sV k)) := by
  show fmapLookupBy symOrd symA550 (eIns symA551 (ldi k) (envP11 n k)) = _
  rw [lookup_eIns_ne (envP11_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP10_built n k) (symCmpO_self _ _ _)

-- hpA551_12
theorem envP12_lookup_a551 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA551 (envP12 n k) = some (ldi k) :=
  lookup_eIns_eq (envP11_built n k) (symCmpO_self _ _ _)

-- hpA549_14
theorem envP14_lookup_a549 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA549 (envP14 n k) = some sPtrV :=
  lookup_eIns_eq (envP13_built n k) (symCmpO_self _ _ _)

-- hpA557_14
theorem envP14_lookup_a557 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA557 (envP14 n k)
      = some (ldi (sV k + (k : Int))) := by
  show fmapLookupBy symOrd symA557 (eIns symA549 sPtrV (envP13 n k)) = _
  rw [lookup_eIns_ne (envP13_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP12_built n k) (symCmpO_self _ _ _)

-- hpI15 (crosses unitSym (2k) — stuck-seed hypotheses)
theorem envP15_lookup_i (n : Int) (k : Nat) (hk : k ≤ 300)
    (hdig : CerberusFresh.digest () = "")
    (hseed : seedT5 = 1048577) :
    fmapLookupBy symOrd symI (envP15 n k) = some iPtrV := by
  show fmapLookupBy symOrd symI
    (eIns (unitSym (2*k)) (ldi (sV k + (k : Int))) (envP14 n k)) = _
  rw [lookup_eIns_ne (envP14_built n k)
    (unitSym_cmp_ne _ _ hdig hseed (by omega) (by decide))]
  show fmapLookupBy symOrd symI (eIns symA549 sPtrV (envP13 n k)) = _
  rw [lookup_eIns_ne (envP13_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA557 (ldi (sV k + (k : Int))) (envP12 n k)) = _
  rw [lookup_eIns_ne (envP12_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA551 (ldi k) (envP11 n k)) = _
  rw [lookup_eIns_ne (envP11_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA550 (ldi (sV k)) (envP10 n k)) = _
  rw [lookup_eIns_ne (envP10_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA555 sPtrV (envP9 n k)) = _
  rw [lookup_eIns_ne (envP9_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA556 iPtrV (envP8 n k)) = _
  rw [lookup_eIns_ne (envP8_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP8_lookup_i n k

-- hpA564_16
theorem envP16_lookup_a564 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA564 (envP16 n k) = some iPtrV :=
  lookup_eIns_eq (envP15_built n k) (symCmpO_self _ _ _)

-- hpA559_18
theorem envP18_lookup_a559 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA559 (envP18 n k) = some (ldi k) :=
  lookup_eIns_eq (envP17_built n k) (symCmpO_self _ _ _)

-- hpA560_18
theorem envP18_lookup_a560 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA560 (envP18 n k) = some (ldi 1) := by
  show fmapLookupBy symOrd symA560 (eIns symA559 (ldi k) (envP17 n k)) = _
  rw [lookup_eIns_ne (envP17_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP16_built n k) (symCmpO_self _ _ _)

-- hpA558_20
theorem envP20_lookup_a558 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA558 (envP20 n k) = some iPtrV :=
  lookup_eIns_eq (envP19_built n k) (symCmpO_self _ _ _)

-- hpA565_20
theorem envP20_lookup_a565 (n : Int) (k : Nat) :
    fmapLookupBy symOrd symA565 (envP20 n k) = some (ldi ((k : Int) + 1)) := by
  show fmapLookupBy symOrd symA565 (eIns symA558 iPtrV (envP19 n k)) = _
  rw [lookup_eIns_ne (envP19_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact lookup_eIns_eq (envP18_built n k) (symCmpO_self _ _ _)

-- hpI21 (crosses unitSym (2k+1) and unitSym (2k))
theorem envP21_lookup_i (n : Int) (k : Nat) (hk : k ≤ 300)
    (hdig : CerberusFresh.digest () = "")
    (hseed : seedT5 = 1048577) :
    fmapLookupBy symOrd symI (envP21 n k) = some iPtrV := by
  show fmapLookupBy symOrd symI
    (eIns (unitSym (2*k+1)) (ldi ((k : Int) + 1)) (envP20 n k)) = _
  rw [lookup_eIns_ne (envP20_built n k)
    (unitSym_cmp_ne _ _ hdig hseed (by omega) (by decide))]
  show fmapLookupBy symOrd symI (eIns symA558 iPtrV (envP19 n k)) = _
  rw [lookup_eIns_ne (envP19_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA565 (ldi ((k : Int) + 1)) (envP18 n k)) = _
  rw [lookup_eIns_ne (envP18_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA559 (ldi k) (envP17 n k)) = _
  rw [lookup_eIns_ne (envP17_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA560 (ldi 1) (envP16 n k)) = _
  rw [lookup_eIns_ne (envP16_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symI (eIns symA564 iPtrV (envP15 n k)) = _
  rw [lookup_eIns_ne (envP15_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP15_lookup_i n k hk hdig hseed

-- hpS22 (crosses both unitSym binders)
theorem envP22_lookup_s (n : Int) (k : Nat) (hk : k ≤ 300)
    (hdig : CerberusFresh.digest () = "")
    (hseed : seedT5 = 1048577) :
    fmapLookupBy symOrd symS (envP22 n k) = some sPtrV := by
  show fmapLookupBy symOrd symS (eIns symI iPtrV (envP21 n k)) = _
  rw [lookup_eIns_ne (envP21_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS
    (eIns (unitSym (2*k+1)) (ldi ((k : Int) + 1)) (envP20 n k)) = _
  rw [lookup_eIns_ne (envP20_built n k)
    (unitSym_cmp_ne _ _ hdig hseed (by omega) (by decide))]
  show fmapLookupBy symOrd symS (eIns symA558 iPtrV (envP19 n k)) = _
  rw [lookup_eIns_ne (envP19_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA565 (ldi ((k : Int) + 1)) (envP18 n k)) = _
  rw [lookup_eIns_ne (envP18_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA559 (ldi k) (envP17 n k)) = _
  rw [lookup_eIns_ne (envP17_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA560 (ldi 1) (envP16 n k)) = _
  rw [lookup_eIns_ne (envP16_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA564 iPtrV (envP15 n k)) = _
  rw [lookup_eIns_ne (envP15_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS
    (eIns (unitSym (2*k)) (ldi (sV k + (k : Int))) (envP14 n k)) = _
  rw [lookup_eIns_ne (envP14_built n k)
    (unitSym_cmp_ne _ _ hdig hseed (by omega) (by decide))]
  show fmapLookupBy symOrd symS (eIns symA549 sPtrV (envP13 n k)) = _
  rw [lookup_eIns_ne (envP13_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA557 (ldi (sV k + (k : Int))) (envP12 n k)) = _
  rw [lookup_eIns_ne (envP12_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA551 (ldi k) (envP11 n k)) = _
  rw [lookup_eIns_ne (envP11_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA550 (ldi (sV k)) (envP10 n k)) = _
  rw [lookup_eIns_ne (envP10_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  show fmapLookupBy symOrd symS (eIns symA555 sPtrV (envP9 n k)) = _
  rw [lookup_eIns_ne (envP9_built n k)
    (symCmpO_ne_of_id _ _ _ _ _ _ (by decide))]
  exact envP9_lookup_s n k

/-! ## The a543 miss facts (extern/funs — the PEcall resolution
    misses; probe hext513/hfun513) -/

theorem extern_lookup_a543 :
    fmapLookupBy symOrd symA543 (create_extern_symmap t5File) = none := by
  rfl

theorem funs_lookup_a543 :
    fmapLookupBy symOrd symA543 t5File.funs = none := by
  rfl

end RelSem.T5
