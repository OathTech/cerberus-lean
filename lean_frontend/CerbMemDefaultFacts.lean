/-
  CerbMemDefaultFacts — kernel bridges from the full reconstruction
  `CerbMem.reconstructValueAbst(_lemFuel)` to the default-mode compatibility
  wrappers `CerbMem.reconstructValue(_lemFuel)` (PNVI arc S2 review fix F1,
  2026-10-07; records docs/2026-10-07_pnvi-s2-data-shapes-record.md §10 and
  docs/2026-10-07_pnvi-s3-arms-record.md).

  A THEOREM-ONLY seam a consumer imports beside `CerbMem`: a proof that unfolds
  `loadM` reaches `(reconstructValueAbst … (findOverlapping st) …).2` at its own
  instance; `loadM_reconstruct_eq_reconstructValue` rewrites it to
  `reconstructValue …` whenever that instance's switch list is
  `CerbGlobal.defaultSwitches`. Kept OUT of `CerbMem.lean` because its statements
  name the default-pinned wrappers, which the production-text speedbump W2
  (`scripts/check_no_fuel_numerals.sh`) keeps out of production code; this file is
  excluded from W2 by name, as the `*_lemMeasureProofs` proof carriers are. No
  definition here; kernel-only tactics, no option bumps. The equality with the
  pre-S2 TEXT stays in the test module (`reconstructValueAbst_default_snd_eq_legacy`,
  test/Unit/ReconstructLegacyTest.lean, row 1).
-/
import CerbMem

namespace CerbMem

set_option autoImplicit true

private abbrev TagDefs := CerbTags.TagDefsMap
private abbrev EnumDefs := CerberusImpl.EnumDefs

/-! ## The bridges

(PNVI arc S2 review fix F1, 2026-10-07.) A consumer that unfolds `loadM` reaches
`(reconstructValueAbst … (findOverlapping st) …).2` at its own instance; these kernel
lemmas rewrite that subterm to the default-mode `reconstructValue …` whenever the
instance's switch list is `CerbGlobal.defaultSwitches` — the closure is irrelevant
there (`reconstructValueAbst_lemFuel_default_closure`: the pointer arm consults it only
under `is_PNVI ()`, which is `false`). The equality with the pre-S2 TEXT stays in the
test module (`reconstructValueAbst_default_snd_eq_legacy`, row 1). -/

/-- The wrapper equation (design §B.7 "`reconstructValue_lemFuel_unfold`"), for `simp only` sets. -/
theorem reconstructValue_lemFuel_unfold (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
      (@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient noOverlapping unionmap funptrmap addr ty bytes).2 :=
  rfl

/-- Closure irrelevance at the default switch set: the WHOLE result (taint and value)
    does not depend on the `find_overlaping` closure. -/
theorem reconstructValueAbst_lemFuel_default_closure (fo fo' : Address → OverlapResult) :
    ∀ (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
      (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte),
      @reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient fo unionmap funptrmap addr ty bytes =
        @reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient fo' unionmap funptrmap addr ty bytes := by
  intro lemFuel
  induction lemFuel with
  | zero => intros; rfl
  | succ n ih =>
    intro enumDefs ambient unionmap funptrmap addr ty bytes
    rcases ty with ⟨_, ty⟩
    cases ty with
    | Basic bt => cases bt <;> rfl
    | Pointer q c => rfl
    | Array0 elemCty k =>
      cases k with
      | none => rfl
      | some k => simp only [reconstructValueAbst_lemFuel, ih]
    | Atomic c =>
      simp only [reconstructValueAbst_lemFuel]
      exact ih _ _ _ _ _ _ _
    | Struct t =>
      simp only [reconstructValueAbst_lemFuel]
      cases CerbTagsWf.lookupEntry ambient t with
      | none => rfl
      | some e => simp only [ih]
    | Union0 t =>
      simp only [reconstructValueAbst_lemFuel]
      cases CerbTagsWf.lookupEntry ambient t with
      | none => rfl
      | some e =>
        obtain ⟨s, l, d⟩ := e
        cases d with
        | StructDef _ _ => rfl
        | UnionDef membrs =>
          cases membrs with
          | nil => rfl
          | cons m rest => simp only [ih]
    | _ => rfl

/-- The fuel'd full reconstruction at the default set, any closure, value component =
    the fuel'd default-mode wrapper. -/
theorem reconstructValueAbst_lemFuel_default_snd (fo : Address → OverlapResult) (lemFuel : Nat) (enumDefs : EnumDefs)
    (ambient : TagDefs) (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype)
    (bytes : List AbsByte) :
    (@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient fo unionmap funptrmap addr ty bytes).2 =
      reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes := by
  rw [reconstructValueAbst_lemFuel_default_closure fo noOverlapping]
  rfl

/-- The same for the measured (fuel-free) pair. -/
theorem reconstructValueAbst_default_snd (fo : Address → OverlapResult) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    (@reconstructValueAbst ⟨CerbGlobal.defaultSwitches⟩ enumDefs ambient fo unionmap funptrmap addr ty bytes).2 =
      reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes :=
  reconstructValueAbst_lemFuel_default_snd fo _ enumDefs ambient unionmap funptrmap addr ty bytes

/-- The form for a consumer's OWN instance: any instance whose switch list is
    `CerbGlobal.defaultSwitches` (e.g. `instance : CerbGlobal.Switches :=
    ⟨CerbGlobal.defaultSwitches⟩`, `h := rfl`). -/
theorem reconstructValueAbst_snd_of_default [inst : CerbGlobal.Switches]
    (h : inst.switches = CerbGlobal.defaultSwitches) (fo : Address → OverlapResult)
    (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    (reconstructValueAbst enumDefs ambient fo unionmap funptrmap addr ty bytes).2 =
      reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes := by
  cases inst with
  | mk sws =>
    obtain rfl : sws = CerbGlobal.defaultSwitches := h
    exact reconstructValueAbst_default_snd fo enumDefs ambient unionmap funptrmap addr ty bytes

/-- The `loadM`-facing form: the exact subterm `loadM`'s `doLoad` builds (the
    `find_overlaping st` closure, the state's union map and funptrmap), rewritten to the
    default-mode `reconstructValue`, at any default-valued instance. -/
theorem loadM_reconstruct_eq_reconstructValue [inst : CerbGlobal.Switches]
    (h : inst.switches = CerbGlobal.defaultSwitches) (st : MemState)
    (enumDefs : EnumDefs) (ambient : TagDefs) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    (reconstructValueAbst enumDefs ambient (findOverlapping st) st.lastUsedUnionMembers st.funptrmap addr ty bytes).2 =
      reconstructValue enumDefs ambient st.lastUsedUnionMembers st.funptrmap addr ty bytes :=
  reconstructValueAbst_snd_of_default h _ enumDefs ambient _ _ addr ty bytes

end CerbMem
