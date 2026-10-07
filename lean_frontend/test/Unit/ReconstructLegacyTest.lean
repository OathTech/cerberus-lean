import CerbMem
import CerbGlobal
-- PNVI arc-end audit F3: compiles the theorem-only seam in row 1 (nothing else in the
-- row-1 build imports it); its theorems' cones are pinned by check_theorem_axioms.sh.
import CerbMemDefaultFacts

/-! # ReconstructLegacyTest — the default-mode `reconstructValue` wrappers equal the pre-S2 text

PNVI arc S2 (2026-10-07; design record `docs/2026-10-04_pnvi-ae-udi-design.md` §B.7,
slice record `docs/2026-10-07_pnvi-s2-data-shapes-record.md`). `CerbMem.reconstructValue_lemFuel`
and `CerbMem.reconstructValue` keep their names and types for the consumer (cerberus-sl,
statement §1.5 item 1) but are now the second projection of the full reconstruction
`CerbMem.reconstructValueAbst_lemFuel`, pinned at `⟨CerbGlobal.defaultSwitches⟩` with the
closure `noOverlapping`. Condition (c) of §B.7: "proved equal to today's value", kernel-checked.

  * `reconstructValueLegacy_lemFuel` / `reconstructValueLegacy` below are the pre-S2
    `CerbMem.reconstructValue_lemFuel` / `CerbMem.reconstructValue` VERBATIM (at mainline
    `47348c07e`; names and recursive calls renamed, nothing else) — a named reference for
    "today's value". NOT executed by anything.
  * `reconstructValueAbst_default_snd_eq_legacy`: for EVERY `find_overlaping` closure, the
    full reconstruction at the default switch set has the legacy value as its second
    component (the closure is never consulted, the taint is discarded) — fuel induction,
    the `reconstructValue_lemFuel_eq_indexed` template.
  * `reconstructValue_lemFuel_eq_legacy` / `reconstructValue_eq_legacy`: the wrappers equal
    the legacy text (instances of the above at `noOverlapping`).
  * `loadM_reconstruct_default`: the reconstruction `loadM` runs — the full one with the
    ambient instance and `findOverlapping st` — has the legacy value at the default set,
    for every state.
  * The mem-scale C1 reference form (`reconstructValue_indexed_lemFuel` and its two
    equalities, mem-scale S1 2026-09-02) is RETIRED here from `CerbMem.lean` (design §B.7,
    "retire into the test module (production carries one implementation)"): restated over
    the legacy copy, and chained to the production wrapper by
    `reconstructValue_lemFuel_eq_indexed` / `reconstructValue_eq_indexed` below — the C1
    equality stays kernel-checked (row 1; `scripts/check_theorem_axioms.sh` mem-scale leg).

The `#print axioms` lines are informational; the axiom gate pins the cones. -/

namespace ReconstructLegacyTest

open CerbMem CerberusImpl

set_option autoImplicit false

/-- `CerbMem`'s private abbreviation, restated so the legacy text below is verbatim. -/
abbrev TagDefs := CerbTags.TagDefsMap

/-! ## The pre-S2 text, verbatim (renamed) -/

/-- Reconstruct a MemValue from bytes — abst, impl_mem.ml:916-1095.
    INVARIANT (differs from OCaml's consume-and-return-rest shape at the
    LEAVES): `bytes` is exactly the sizeof(ty) slice for this value; the
    array arm hands each element exactly its slice in one linear pass
    (C1, see the arm), the struct/union arms re-slice per member.
    `unionmap` is mem_state.last_used_union_members and
    `addr` the value's address — consulted ONLY by the Union arm
    (impl_mem.ml:1080-1087); `funptrmap` is mem_state.funptrmap —
    consulted ONLY by the Pointer-to-Function arm (impl_mem.ml:1004-1016)
    — exactly as in OCaml's abst.
    Not ported: taint tracking (PNVI) and is_zap. -/
def reconstructValueLegacy_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.reconstructValue: fuel exhausted" (.MVunspecified ty)
  | lemFuel + 1 =>
  match ty with
  | Ctype _ (.Basic (.Integer ity)) =>
    -- impl_mem.ml:949-960 (signedness via the implementation, as
    -- AilTypesAux.is_signed_ity does there); provenance via the INTEGER
    -- policy — pvi_split_bytes' combine_prov fold (impl_mem.ml:951,
    -- :455-460). mk_ival (impl_mem.ml:637-644) is the non-PNVI branch:
    -- IV (prov, n) as-is.
    let signed := CerberusImpl.is_signed_ity (CerberusImpl.resolveEnum enumDefs ity)
    match bytesToInt bytes signed with
    | some n => .MVinteger ity (.IV (provFromIntegerBytes bytes) n)
    | none => .MVunspecified ty
  | Ctype _ (.Basic (.Floating fty)) =>
    -- impl_mem.ml:974-985
    match bytesToInt bytes false with
    | some n =>
      let bits : UInt64 := n.toNat.toUInt64
      .MVfloating fty (Float.ofBits bits)
    | none => .MVunspecified ty
  | Ctype _ (.Pointer _ pointeeCty) =>
    -- impl_mem.ml:995-1058. MVpointer stores the POINTEE type: every
    -- OCaml arm builds `MVpointer (ref_ty, ...)` (impl_mem.ml:1007,
    -- 1012, 1019, 1054) — matching `typeof` (impl_mem.ml:1123-1124:
    -- MVpointer (ref_ty, _) → Pointer (no_qualifiers, ref_ty)) and our
    -- own pointerMval/MVpointer.refTy. (Audit-2 C1: this previously
    -- stored the full pointer type `ty` — one indirection too many.)
    -- Provenance via the POINTER policy — AbsByte.split_bytes
    -- (impl_mem.ml:998, :432-453); the ValidPtrProv component is
    -- consulted only under is_PNVI (impl_mem.ml:1021-1053), never
    -- enabled here — see splitBytesProv.
    match bytesToInt bytes false with
    | some 0 =>
      -- both the Function and the object branch map 0 to PVnull
      -- (impl_mem.ml:1005-1007, 1017-1019)
      .MVpointer pointeeCty (.PV .Prov_none (.PVnull pointeeCty))
    | some ptrAddr =>
      let (prov, _validPtrProv) := splitBytesProv bytes
      match pointeeCty with
      | Ctype _ (.Function _ _ _) =>
        -- impl_mem.ml:1004-1015: a pointer-to-function is rebuilt from
        -- the funptrmap entry registered at store time (repr,
        -- impl_mem.ml:1168-1185); the address IS the function symbol's
        -- nat. Unknown address: OCaml failwith — panic. (OCaml's own
        -- FIXME about same-id symbols across files applies unchanged.)
        match funptrmap.find? (fun (a, _) => a == ptrAddr) with
        | some (_, (fileDig, name)) =>
          .MVpointer pointeeCty (.PV prov (.PVfunction (Symbol fileDig ptrAddr.toNat (SD_Id name))))
        | none => failwithI s!"CerbMem.reconstructValue: unknown function pointer: {ptrAddr}"
      | _ =>
        .MVpointer pointeeCty (.PV prov (.PVconcrete none ptrAddr.toNat))
    | none =>
      -- impl_mem.ml:1056-1057 `MVunspecified (Ctype ([], Pointer (no_qualifiers,
      -- ref_ty)))`: the pointee QUALIFIERS are dropped (zero-discrepancy
      -- Z-19: this kept `ty` verbatim; the ctype text is a verdict value
      -- wherever an unspecified pointer is printed)
      .MVunspecified (Ctype [] (.Pointer no_qualifiers pointeeCty))
  | Ctype _ (.Array0 elemCty (some n)) =>
    -- impl_mem.ml:986-994; NOTE OCaml's `self elem_ty cs` does NOT
    -- advance ~addr per element — every element sees the array's addr
    -- (mirrored: nested-union lookups use the array base address).
    -- SHAPE (mem-scale C1, 2026-09-02): ONE consume-and-return-rest pass
    -- over the bytes (`chunksOf`: take elemSize, recurse on the rest),
    -- which is the OCaml `aux`'s shape (impl_mem.ml:987-993: `self
    -- elem_ty cs` returns the unconsumed suffix `cs'`), minus the OCaml's
    -- per-call guard `if List.length bs < sizeof cty then failwith`
    -- (impl_mem.ml:929-930) — DELIBERATELY NOT MIRRORED: that guard
    -- re-walks the remaining list on every recursive call and is what
    -- makes the oracle quadratic in the element count on aggregate
    -- loads (upstream-tray item). The pre-C1 Lean text re-sliced from
    -- the array's start per element (`bytes.drop (i*elemSize) |>.take
    -- elemSize`), also quadratic; `reconstructValueLegacy_lemFuel_eq_indexed`
    -- below is the kernel-checked equality with that reference form
    -- (`reconstructValueLegacy_indexed_lemFuel`). Linear in |bytes|.
    -- Zero-discrepancy Z-18: no zero-sized-element short-circuit — OCaml's
    -- `aux (Z.to_int n)` (:987-993) builds n elements whatever sizeof
    -- elem_ty is; `chunksOf 0 n` yields n empty slices, the same shape.
    -- (A zero-sized element type is anyway rejected by the shared front
    -- end: tests/z2-probes/mem/empty_struct.c is UB061 on all engines.)
    let nNat := n.toNat
    let elemSize := sizeofCtype enumDefs ambient elemCty
    .MVarray ((chunksOf elemSize nNat bytes).map fun elemBytes =>
        reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr elemCty elemBytes)
  | Ctype _ (.Atomic innerCty) =>
    -- impl_mem.ml:1058-1060 (same repr as the non-atomic version)
    reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr innerCty bytes
  | Ctype _ .Byte =>
    -- impl_mem.ml:961-973 ("handled similarly to integers": provenance
    -- via pvi_split_bytes' combine_prov fold, impl_mem.ml:964)
    match bytesToInt (bytes.take 1) false with
    | some n => .MVinteger .Char0 (.IV (provFromIntegerBytes (bytes.take 1)) n)
    | none => .MVunspecified ty
  | Ctype _ (.Struct tagSym) =>
    -- impl_mem.ml:1065-1075: member-wise reconstruct at the offsetsof
    -- offsets (ignore_flexible=true), skipping inter-member padding.
    -- NOTE OCaml's `self ~offset:pad` advances the member addr by the
    -- PADDING before the member only, not by the member offset
    -- (impl_mem.ml:1069-1072) — mirrored quirk; addr is only consulted
    -- by nested union lookups.
    -- An UNKNOWN tag is OCaml's `Pmap.find` Not_found inside `sizeof cty`
    -- (:1067) / `offsetsof` (:1073): the exception escapes and nothing of
    -- the struct is computed — so the leaf is the WHOLE result here, and
    -- the fold runs only once the tag is known to resolve (hotfix
    -- fix/fuel-forms-carriers option (d), 2026-09-20 — record
    -- docs/2026-09-20_fuel-forms-carriers-hotfix-record.md §3.5: the
    -- former shape folded over the failure value's projection
    -- `(failwithI …).fst`, a fail-open-shaped remnant; the row-6 measure
    -- proof needs no equation about the opaque leaf). `offsetsof`'s own
    -- leaf is untouched; the message differs from the oracle's exception
    -- text (failure TEXT is an allowed discrepancy class).
    match CerbTagsWf.lookupEntry ambient tagSym with
    | none => failwithI "CerbMem.reconstructValue: unknown struct tag (OCaml: Pmap.find Not_found in sizeof/offsetsof, impl_mem.ml:1067/1073)"
    | some _ =>
      let (offs, _) := offsetsof enumDefs ambient ambient tagSym (ignoreFlexible := true)
      let (revXs, _) := offs.foldl
        (init := (([] : List (identifier × ctype × MemValue)), (0 : Nat)))
        fun (acc : List (identifier × ctype × MemValue) × Nat) (memb : identifier × ctype × Nat) =>
          let (revXs, prevEnd) := acc
          let (ident, membTy, off) := memb
          let pad := off - prevEnd
          let membBytes := bytes.drop off |>.take (sizeofCtype enumDefs ambient membTy)
          let mval := reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap (addr + (pad : Int)) membTy membBytes
          ((ident, membTy, mval) :: revXs, off + sizeofCtype enumDefs ambient membTy)
      .MVstruct tagSym revXs.reverse
  | Ctype _ (.Union0 tagSym) =>
    -- impl_mem.ml:1076-1096: select the member recorded in
    -- last_used_union_members at this address; default to the FIRST
    -- declared member when absent (:1084-1086).
    match CerbTagsWf.lookupEntry ambient tagSym with
    | some (_, (_, UnionDef membrs)) =>
      match membrs with
      | [] => failwithI "CerbMem.reconstructValue: empty UnionDef (OCaml: match failure)"
      | (firstIdent, (_, _, _, firstTy)) :: _ =>
        -- ident comparison is by NAME (idEqual), as OCaml's
        -- Eq Symbol.identifier instance does (:1088). A recorded identifier
        -- that names no member is OCaml's `assert false` (:1089-1090): the
        -- exception escapes, no member is reconstructed — so the leaf is the
        -- WHOLE result (hotfix fix/fuel-forms-carriers option (d),
        -- 2026-09-20, record §3.5; the former shape recursed on the failure
        -- value's `.snd`). The member is selected BEFORE the recursion; the
        -- recursive call is `self membr_ty bs1` (:1093), the result `MVunion`
        -- (:1094).
        match unionmap.find? (fun (a, _) => a == addr) with
        | none =>
          .MVunion tagSym firstIdent
            (reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr firstTy
              (bytes.take (sizeofCtype enumDefs ambient firstTy)))
        | some (_, membr) =>
          match membrs.find? (fun (i, _) => idEqual i membr) with
          | some (membIdent, (_, _, _, membTy)) =>
            .MVunion tagSym membIdent
              (reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr membTy
                (bytes.take (sizeofCtype enumDefs ambient membTy)))
          | none => failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)"
    | _ => failwithI "CerbMem.reconstructValue: Union tag not a UnionDef (OCaml: assert false)"
  -- impl_mem.ml:978-983: Void, Array (_, None), Function, FunctionNoParams
  -- "must have a known size" → assert false (served-surface audit P3; was a
  -- silent MVunspecified)
  | _ => failwithI "CerbMem.reconstructValue: type without a known size (OCaml: assert false, impl_mem.ml:978-983)"

/-- Measured wrapper (C4): fuel-free, hypothesis `CerbTagsWf.Acyclic ambient`
    (its recursion is on the ctype being reconstructed, through member types
    read from the tag environment); obligation in CerbMem_lemMeasureProofs. -/
def reconstructValueLegacy (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  reconstructValueLegacy_lemFuel (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes

/-! ### C1 reference form + equality theorem (mem-scale S1, 2026-09-02)

`reconstructValueLegacy_indexed_lemFuel` is the PRE-C1 text of
`reconstructValueLegacy_lemFuel` verbatim (name and recursive calls renamed; its
struct/union arms restated identically with the linear form's — hotfix
fix/fuel-forms-carriers option (d), 2026-09-20;
the doc comments of the arms are in the live definition above): its
array arm re-slices from the array's start per element,
`bytes.drop (i * elemSize) |>.take elemSize` — the index-slicing form,
Θ(n²·e). NOT executed by the driver; it exists so that the C1 shape
change is a kernel-checked equality (`reconstructValueLegacy_lemFuel_eq_indexed`).
Charter §1 carve-out [R1/F5]; consumer note: refined-cerberus unfolds
`reconstructValueLegacy_lemFuel` at pointer/struct-typed nodes only
(TreeRotExhibit.lean:148, ListRevExhibit.lean:260), arms C1 leaves
textually intact. -/

/-- Reference form (pre-C1): index-slicing array arm. -/
def reconstructValueLegacy_indexed_lemFuel (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.reconstructValue: fuel exhausted" (.MVunspecified ty)
  | lemFuel + 1 =>
  match ty with
  | Ctype _ (.Basic (.Integer ity)) =>
    let signed := CerberusImpl.is_signed_ity (CerberusImpl.resolveEnum enumDefs ity)
    match bytesToInt bytes signed with
    | some n => .MVinteger ity (.IV (provFromIntegerBytes bytes) n)
    | none => .MVunspecified ty
  | Ctype _ (.Basic (.Floating fty)) =>
    match bytesToInt bytes false with
    | some n =>
      let bits : UInt64 := n.toNat.toUInt64
      .MVfloating fty (Float.ofBits bits)
    | none => .MVunspecified ty
  | Ctype _ (.Pointer _ pointeeCty) =>
    match bytesToInt bytes false with
    | some 0 =>
      .MVpointer pointeeCty (.PV .Prov_none (.PVnull pointeeCty))
    | some ptrAddr =>
      let (prov, _validPtrProv) := splitBytesProv bytes
      match pointeeCty with
      | Ctype _ (.Function _ _ _) =>
        match funptrmap.find? (fun (a, _) => a == ptrAddr) with
        | some (_, (fileDig, name)) =>
          .MVpointer pointeeCty (.PV prov (.PVfunction (Symbol fileDig ptrAddr.toNat (SD_Id name))))
        | none => failwithI s!"CerbMem.reconstructValue: unknown function pointer: {ptrAddr}"
      | _ =>
        .MVpointer pointeeCty (.PV prov (.PVconcrete none ptrAddr.toNat))
    | none =>
      -- impl_mem.ml:1056-1057 `MVunspecified (Ctype ([], Pointer (no_qualifiers,
      -- ref_ty)))`: the pointee QUALIFIERS are dropped (zero-discrepancy
      -- Z-19: this kept `ty` verbatim; the ctype text is a verdict value
      -- wherever an unspecified pointer is printed)
      .MVunspecified (Ctype [] (.Pointer no_qualifiers pointeeCty))
  | Ctype _ (.Array0 elemCty (some n)) =>
    let nNat := n.toNat
    let elemSize := sizeofCtype enumDefs ambient elemCty
    let elems := List.range nNat |>.map fun i =>
        let start := i * elemSize
        let elemBytes := bytes.drop start |>.take elemSize
        reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr elemCty elemBytes
    .MVarray elems
  | Ctype _ (.Atomic innerCty) =>
    reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr innerCty bytes
  | Ctype _ .Byte =>
    match bytesToInt (bytes.take 1) false with
    | some n => .MVinteger .Char0 (.IV (provFromIntegerBytes (bytes.take 1)) n)
    | none => .MVunspecified ty
  | Ctype _ (.Struct tagSym) =>
    match CerbTagsWf.lookupEntry ambient tagSym with
    | none => failwithI "CerbMem.reconstructValue: unknown struct tag (OCaml: Pmap.find Not_found in sizeof/offsetsof, impl_mem.ml:1067/1073)"
    | some _ =>
      let (offs, _) := offsetsof enumDefs ambient ambient tagSym (ignoreFlexible := true)
      let (revXs, _) := offs.foldl
        (init := (([] : List (identifier × ctype × MemValue)), (0 : Nat)))
        fun (acc : List (identifier × ctype × MemValue) × Nat) (memb : identifier × ctype × Nat) =>
          let (revXs, prevEnd) := acc
          let (ident, membTy, off) := memb
          let pad := off - prevEnd
          let membBytes := bytes.drop off |>.take (sizeofCtype enumDefs ambient membTy)
          let mval := reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap (addr + (pad : Int)) membTy membBytes
          ((ident, membTy, mval) :: revXs, off + sizeofCtype enumDefs ambient membTy)
      .MVstruct tagSym revXs.reverse
  | Ctype _ (.Union0 tagSym) =>
    match CerbTagsWf.lookupEntry ambient tagSym with
    | some (_, (_, UnionDef membrs)) =>
      match membrs with
      | [] => failwithI "CerbMem.reconstructValue: empty UnionDef (OCaml: match failure)"
      | (firstIdent, (_, _, _, firstTy)) :: _ =>
        match unionmap.find? (fun (a, _) => a == addr) with
        | none =>
          .MVunion tagSym firstIdent
            (reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr firstTy
              (bytes.take (sizeofCtype enumDefs ambient firstTy)))
        | some (_, membr) =>
          match membrs.find? (fun (i, _) => idEqual i membr) with
          | some (membIdent, (_, _, _, membTy)) =>
            .MVunion tagSym membIdent
              (reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr membTy
                (bytes.take (sizeofCtype enumDefs ambient membTy)))
          | none => failwithI "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)"
    | _ => failwithI "CerbMem.reconstructValue: Union tag not a UnionDef (OCaml: assert false)"
  -- impl_mem.ml:978-983: Void, Array (_, None), Function, FunctionNoParams
  -- "must have a known size" → assert false (served-surface audit P3; was a
  -- silent MVunspecified)
  | _ => failwithI "CerbMem.reconstructValue: type without a known size (OCaml: assert false, impl_mem.ml:978-983)"

/-- C1 equality: the linear (consume-and-return-rest) reconstruction equals
    the index-slicing reference form at every fuel, on every input.
    Induction on fuel; every arm but the array arm is textually identical
    once the recursive calls are rewritten by the induction hypothesis;
    the array arm is `chunksOf_eq_range_map` + `List.map_map`. -/
theorem reconstructValueLegacy_lemFuel_eq_indexed :
    ∀ (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
      (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte),
      reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
        reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes := by
  intro lemFuel
  induction lemFuel with
  | zero => intros; rfl
  | succ lemFuel ih =>
    intro enumDefs ambient unionmap funptrmap addr ty bytes
    have hf : reconstructValueLegacy_lemFuel lemFuel = reconstructValueLegacy_indexed_lemFuel lemFuel := by
      funext e a u f ad t b; exact ih e a u f ad t b
    unfold reconstructValueLegacy_lemFuel reconstructValueLegacy_indexed_lemFuel
    rw [hf]
    -- `panic!` expands to `panicWithPosWithDecl <module> <DECL NAME> <line>
    -- <col> msg`, so the two definitions' panic sites differ textually;
    -- every such term is definitionally `default`, and normalising both
    -- sides to it makes the unchanged arms syntactically equal.
    have hp : ∀ {α : Type} [Inhabited α] (m d : String) (l c : Nat) (msg : String),
        (panicWithPosWithDecl m d l c msg : α) = default := fun _ _ _ _ _ => rfl
    simp only [hp]
    rcases ty with ⟨_, ty⟩
    cases ty with
    | Array0 elemCty n =>
      cases n with
      | none => rfl
      | some n =>
        dsimp only
        rw [chunksOf_eq_range_map, List.map_map]
        rfl
    | Basic bt => cases bt <;> rfl   -- the outer match is stuck until the basic type is split
    | _ => rfl

theorem reconstructValueLegacy_eq_indexed (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    reconstructValueLegacy enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy_indexed_lemFuel (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes :=
  reconstructValueLegacy_lemFuel_eq_indexed (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes


/-! ## The equalities (PNVI arc S2) -/

/-- `Prod.snd` of a fold whose second component evolves independently of the first. -/
theorem foldl_snd_eq {α β γ : Type} {F : γ × β → α → γ × β} {G : β → α → β}
    (h : ∀ c b a, (F (c, b) a).2 = G b a) : ∀ (l : List α) (c : γ) (b : β), (l.foldl F (c, b)).2 = l.foldl G b
  | [], _, _ => rfl
  | a :: l, c, b => by
    simp only [List.foldl_cons]
    have hF : F (c, b) a = ((F (c, b) a).1, G b a) := by rw [← h c b a]
    rw [hF]
    exact foldl_snd_eq h l _ _

/-- The full reconstruction at the DEFAULT switch set, whatever the `find_overlaping`
    closure, has the legacy value as its second component. -/
theorem reconstructValueAbst_default_snd_eq_legacy (fo : Address → OverlapResult) :
    ∀ (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
      (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte),
      (@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ lemFuel enumDefs ambient fo unionmap funptrmap addr ty bytes).2 =
        reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes := by
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
      | some k =>
        simp only [reconstructValueAbst_lemFuel, reconstructValueLegacy_lemFuel, List.map_map,
          Function.comp_def, ih]
    | Atomic c =>
      simp only [reconstructValueAbst_lemFuel, reconstructValueLegacy_lemFuel]
      exact ih _ _ _ _ _ _ _
    | Struct t =>
      simp only [reconstructValueAbst_lemFuel, reconstructValueLegacy_lemFuel]
      cases CerbTagsWf.lookupEntry ambient t with
      | none => rfl
      | some e =>
        simp only []
        cases offsetsof enumDefs ambient ambient t true with
        | mk offs x =>
          simp only []
          congr 1; congr 1; congr 1
          apply foldl_snd_eq
          intro c b a
          obtain ⟨xs, p⟩ := b
          obtain ⟨i, mt, off⟩ := a
          simp only [ih]
    | Union0 t =>
      simp only [reconstructValueAbst_lemFuel, reconstructValueLegacy_lemFuel]
      cases CerbTagsWf.lookupEntry ambient t with
      | none => rfl
      | some e =>
        obtain ⟨s, l, d⟩ := e
        cases d with
        | StructDef _ _ => rfl
        | UnionDef membrs =>
          cases membrs with
          | nil => rfl
          | cons m rest =>
            obtain ⟨firstIdent, at_, al, q, firstTy⟩ := m
            simp only []
            cases List.find? (fun (a, _) => a == addr) unionmap with
            | none => simp only [ih]
            | some am =>
              obtain ⟨a, membr⟩ := am
              simp only []
              cases List.find? (fun (i, _) => idEqual i membr) ((firstIdent, at_, al, q, firstTy) :: rest) with
              | none => rfl
              | some mm =>
                obtain ⟨membIdent, at2, al2, q2, membTy⟩ := mm
                simp only [ih]
    | _ => rfl

theorem reconstructValue_lemFuel_eq_legacy (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    CerbMem.reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes :=
  reconstructValueAbst_default_snd_eq_legacy noOverlapping lemFuel enumDefs ambient unionmap funptrmap addr ty bytes

theorem reconstructValue_eq_legacy (enumDefs : EnumDefs) (ambient : TagDefs)
    (unionmap : List (Int × identifier)) (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    CerbMem.reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy enumDefs ambient unionmap funptrmap addr ty bytes :=
  reconstructValue_lemFuel_eq_legacy _ enumDefs ambient unionmap funptrmap addr ty bytes

/-- What `loadM` runs (`(reconstructValueAbst … (findOverlapping st) …).2`, CerbMem.lean
    `loadM`/`doLoad`), at the default switch set: the legacy value, for every state. -/
theorem loadM_reconstruct_default (st : MemState) (enumDefs : EnumDefs) (ambient : TagDefs)
    (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    (@reconstructValueAbst ⟨CerbGlobal.defaultSwitches⟩ enumDefs ambient (@findOverlapping ⟨CerbGlobal.defaultSwitches⟩ st)
        st.lastUsedUnionMembers st.funptrmap addr ty bytes).2 =
      reconstructValueLegacy enumDefs ambient st.lastUsedUnionMembers st.funptrmap addr ty bytes :=
  reconstructValueAbst_default_snd_eq_legacy _ _ enumDefs ambient _ _ addr ty bytes

/-- The C1 equalities, chained to the PRODUCTION wrapper (their pre-S2 statements, verbatim). -/
theorem reconstructValue_lemFuel_eq_indexed :
    ∀ (lemFuel : Nat) (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
      (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte),
      CerbMem.reconstructValue_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes =
        reconstructValueLegacy_indexed_lemFuel lemFuel enumDefs ambient unionmap funptrmap addr ty bytes :=
  fun n e a u f ad t b => (reconstructValue_lemFuel_eq_legacy n e a u f ad t b).trans
    (reconstructValueLegacy_lemFuel_eq_indexed n e a u f ad t b)

theorem reconstructValue_eq_indexed (enumDefs : EnumDefs) (ambient : TagDefs) (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int) (ty : ctype) (bytes : List AbsByte) :
    CerbMem.reconstructValue enumDefs ambient unionmap funptrmap addr ty bytes =
      reconstructValueLegacy_indexed_lemFuel (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes :=
  reconstructValue_lemFuel_eq_indexed (CerbTagsWf.envBound ambient ty) enumDefs ambient unionmap funptrmap addr ty bytes

#print axioms reconstructValueAbst_default_snd_eq_legacy
#print axioms reconstructValue_lemFuel_eq_legacy
#print axioms reconstructValue_eq_indexed

/-! ## Runtime positive controls of the S2 helpers

The PNVI branches are LIVE under a PNVI switch set (so the default-mode facts above are
not vacuous), and the helpers compute upstream's values on hand-built states. No
refusal arm is exercised (each aborts the process under LEAN_ABORT_ON_PANIC; their pins
are S3/S4's). -/

/-- A named address-space top for the hand-built state (no literal cursor, rule A3). -/
def testTop : Int := 65536

def swDefault : CerbGlobal.Switches := ⟨CerbGlobal.defaultSwitches⟩
def swPlain : CerbGlobal.Switches := ⟨[.PNVI .PLAIN]⟩
def swAE : CerbGlobal.Switches := ⟨[.PNVI .AE]⟩
def swAEUDI : CerbGlobal.Switches := ⟨[.PNVI .AE_UDI]⟩

/-- Two adjacent live allocations: id 0 = [100, 108) unexposed, id 1 = [108, 116) exposed. -/
def st0 : MemState :=
  { initialMemState testTop with
    allocations := ((Std.TreeMap.empty : Std.TreeMap Int Allocation).insert 0 { base := 100, size := 8 }).insert 1
      { base := 108, size := 8, taint := .Exposed } }

def overlapEq : OverlapResult → OverlapResult → Bool
  | .NoAlloc, .NoAlloc => true
  | .SingleAlloc a, .SingleAlloc b => a == b
  | .DoubleAlloc a b, .DoubleAlloc c d => a == c && b == d
  | _, _ => false

def taintEq : ProvTaint → ProvTaint → Bool
  | .NoTaint, .NoTaint => true
  | .NewTaint xs, .NewTaint ys => xs == ys
  | _, _ => false

def provOf : MemValue → Option Provenance
  | .MVpointer _ (.PV p _) => some p
  | _ => none

def provEq : Option Provenance → Option Provenance → Bool
  | some .Prov_none, some .Prov_none => true
  | some (.Prov_some a), some (.Prov_some b) => a == b
  | _, _ => false

def pt : ctype := Ctype [] (.Pointer no_qualifiers (Ctype [] (.Basic (.Integer (.Signed .Int_)))))

/-- Eight bytes encoding 0x1000 with no provenance and no copy offsets (`NotValidPtrProv`). -/
def ptrBytes : List AbsByte :=
  [0x00, 0x10, 0, 0, 0, 0, 0, 0].map fun (v : UInt8) => { value := some v }

def closure7 : Address → OverlapResult := fun _ => .SingleAlloc 7

def checks : List (String × Bool) :=
  let st1 := (st0 : MemState)
  let st1e := { st1 with allocations := st1.allocations.modify 0 fun a => { a with taint := .Exposed } }
  [ ("default: inside unexposed id 0", overlapEq (@findOverlapping swDefault st1 104) (.SingleAlloc 0)),
    ("default: no one-past", overlapEq (@findOverlapping swDefault st1 116) .NoAlloc),
    ("PLAIN: inside id 1, no one-past of id 0", overlapEq (@findOverlapping swPlain st1 108) (.SingleAlloc 1)),
    ("AE: unexposed id 0 not a candidate", overlapEq (@findOverlapping swAE st1 104) .NoAlloc),
    ("AE_UDI: one-past of unexposed id 0 refused, id 1 found", overlapEq (@findOverlapping swAEUDI st1 108) (.SingleAlloc 1)),
    ("AE_UDI: one-past of exposed id 0 + inside id 1 = DoubleAlloc 0 1 (ascending)", overlapEq (@findOverlapping swAEUDI st1e 108) (.DoubleAlloc 0 1)),
    ("AE_UDI: one-past of exposed id 1", overlapEq (@findOverlapping swAEUDI st1 116) (.SingleAlloc 1)),
    ("provsOfBytes: last byte's id first", taintEq (provsOfBytes [{ prov := .Prov_none }, { prov := .Prov_some 3 }, { prov := .Prov_some 5 }]) (.NewTaint [5, 3])),
    ("provsOfBytes: no ids", taintEq (provsOfBytes [{ prov := .Prov_none }, { prov := .Prov_device }]) .NoTaint),
    ("mergeTaint: xs ++ ys", taintEq (mergeTaint (.NewTaint [1]) (.NewTaint [2])) (.NewTaint [1, 2])),
    ("splitBytesProv: one whole copy is ValidPtrProv", (splitBytesProv [{ prov := .Prov_some 1, copyOffset := some 0 }, { prov := .Prov_some 1, copyOffset := some 1 }]).2),
    ("splitBytesProv: consecutive offsets over differing provenances are NotValidPtrProv", !(splitBytesProv [{ prov := .Prov_some 1, copyOffset := some 0 }, { prov := .Prov_some 2, copyOffset := some 1 }]).2),
    ("mkIval: PNVI strips the provenance", match @mkIval swAEUDI (.Prov_some 4) 9 with | .IV .Prov_none 9 => true | _ => false),
    ("mkIval: default keeps it", match @mkIval swDefault (.Prov_some 4) 9 with | .IV (.Prov_some 4) 9 => true | _ => false),
    ("reconstruct, default: shared provenance, closure unused", provEq (provOf (@reconstructValueAbst swDefault fmapEmpty default closure7 [] [] 0 pt ptrBytes).2) (some .Prov_none)),
    ("reconstruct, AE_UDI: NotValidPtrProv consults find_overlaping", provEq (provOf (@reconstructValueAbst swAEUDI fmapEmpty default closure7 [] [] 0 pt ptrBytes).2) (some (.Prov_some 7))),
    ("reconstruct, integer leaf: taint = provs_of_bytes", taintEq (@reconstructValueAbst swDefault fmapEmpty default closure7 [] [] 0
        (Ctype [] (.Basic (.Integer (.Signed .Int_)))) [{ prov := .Prov_some 2, value := some 1 }, { value := some 0 }, { value := some 0 }, { value := some 0 }]).1 (.NewTaint [2])),
    ("wrapper = full reconstruction at default, closure fixed, taint dropped",
      provEq (provOf (CerbMem.reconstructValue fmapEmpty default [] [] 0 pt ptrBytes)) (some .Prov_none)) ]

end ReconstructLegacyTest

def main : IO UInt32 := do
  let mut failed := 0
  for (name, ok) in ReconstructLegacyTest.checks do
    if ok then IO.println s!"  ok   {name}" else
      IO.println s!"  FAIL {name}"; failed := failed + 1
  IO.println "ReconstructLegacyTest: CerbMem.reconstructValue(_lemFuel) = the pre-S2 text (reconstructValueLegacy_lemFuel) and = the C1 index-slicing form; the full reconstruction at the default switch set ignores the find_overlaping closure and its value is the legacy one — kernel-checked at compile time"
  IO.println s!"ReconstructLegacyTest: {ReconstructLegacyTest.checks.length - failed}/{ReconstructLegacyTest.checks.length} runtime positive controls passed"
  return (if failed == 0 then 0 else 1)
