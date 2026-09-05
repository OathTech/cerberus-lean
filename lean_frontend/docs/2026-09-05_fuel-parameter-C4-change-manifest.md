# Fuel-parameter arc, cerberus half, slice C4 — change manifest for refined-cerberus (2026-09-05)

Branch `arc/fuel-parameter-C4` (base mainline `mdd/cerberus-lean` @
`31eba718e`, the merged Z3/Z4). Record: `2026-09-05_fuel-parameter-C4-record.md`
(same directory). Author [AGENT] (the C4 worker).

**Lake pin you should take: LemLib `f6542f8e6860d12d4655e6648bc4c45dabd1d798`**
(lem-lean `arc/measure-hypothesis` head, held for the operator's merge ask;
`lean_frontend/lakefile.toml`, all three `lake-manifest.json`). What that lem
brings you: the `declare {lean} fuel_measure val f = `μ` assuming `H``
clause — a sufficiency obligation may carry a HYPOTHESIS on the parameters as
the reserved binder `lemHyp : H` immediately before `lemFuel`; the wrapper
stays fuel-free (lem-lean `doc/lean-backend/2026-09-05_measure-hypothesis-record.md`).
The Lean tree at the pin bump alone was byte-identical (the renderer changes
touch nothing existing).

## 1. Seven workers are fuel-free now — six of them under a hypothesis YOU must supply

| Function (module) | Was (C3) | Is now (C4) | Hypothesis `H` (the `lemHyp` binder) | Measure (`lemMeasureLe : μ ≤ lemFuel`) |
|---|---|---|---|---|
| `CerbMem.sizeofCtype` | `def sizeofCtype [LemFuel] (ambient : TagDefs) (cty : ctype) : Nat := sizeofCtype_lemFuel LemFuel.fuel ambient ambient cty` | `def sizeofCtype (ambient) (cty) : Nat := sizeofCtype_lemFuel (CerbTagsWf.envBound ambient cty) ambient ambient cty` | `CerbTagsWf.Acyclic ambient` | `CerbTagsWf.envBound ambient cty` |
| `CerbMem.alignofCtype` | `[LemFuel] … LemFuel.fuel` | `alignofCtype_lemFuel (CerbTagsWf.envBound ambient cty) ambient ambient cty` | `CerbTagsWf.Acyclic ambient` | `envBound ambient cty` |
| `CerbMem.memberAlign` | `[LemFuel] (ambient) (alignOpt) (ty)` | `memberAlign_lemFuel (CerbTagsWf.memberBound ambient alignOpt ty) ambient ambient alignOpt ty` | `CerbTagsWf.Acyclic ambient` | `memberBound ambient alignOpt ty` |
| `CerbMem.offsetsofMembers` | `[LemFuel] (ambient) (members)` | `offsetsofMembers_lemFuel (CerbTagsWf.membersBound ambient members) ambient ambient members` | `CerbTagsWf.Acyclic ambient` | `membersBound ambient members` |
| `CerbMem.offsetsof` | `[LemFuel] (ambient) (tagDefs) (tagSym) (ignoreFlexible := false)` | `offsetsof_lemFuel (CerbTagsWf.offsetsofBound ambient tagDefs) ambient tagDefs tagSym ignoreFlexible` | `CerbTagsWf.AcyclicPair ambient tagDefs` | `offsetsofBound ambient tagDefs` |
| `CerbMem.reconstructValue` | `[LemFuel] (ambient) (unionmap) (funptrmap) (addr) (ty) (bytes)` | `reconstructValue_lemFuel (CerbTagsWf.envBound ambient ty) ambient unionmap funptrmap addr ty bytes` | `CerbTagsWf.Acyclic ambient` | `envBound ambient ty` |
| `showNonNegativeWithBasis_aux` (`Formatted`) | `def showNonNegativeWithBasis_aux [LemFuel] : List Char → Bool → Nat → Nat → List Char := showNonNegativeWithBasis_aux_lemFuel LemFuel.fuel` | `def showNonNegativeWithBasis_aux (acc : List Char) (useUpper : Bool) (b : Nat) (n : Nat) : List Char := showNonNegativeWithBasis_aux_lemFuel (n + 1) acc useUpper b n` | `2 ≤ b` | `n + 1` |

Also fuel-free (their only fuel need was the layout oracle): `CerbMem.memValueToBytes`
(and `memValueToBytes_lemFuel`, `memValueToBytes_append_lemFuel`, the two
`_eq_append` theorems), `CerbMem.reconstructValue_indexed_lemFuel` and the two
`_eq_indexed` theorems (now stated at `CerbTagsWf.envBound ambient ty`).
`CerbMem.mkCtype` is no longer `private` (the proofs name it).

The obligations (all in `CerbMem_lemMeasureProofs.lean`, namespace `CerbMem`,
and `Formatted_lemMeasureProofs.lean` behind the generated
`Formatted_auxiliary.showNonNegativeWithBasis_aux_measure_sufficient`), every
cone `[propext, Classical.choice, Quot.sound]`:

```lean
theorem CerbMem.sizeofCtype_measure_sufficient (ambient : CerbTags.TagDefsMap) (cty : ctype)
    (lemHyp : CerbTagsWf.Acyclic ambient) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.envBound ambient cty ≤ lemFuel) :
    sizeofCtype_lemFuel lemFuel ambient ambient cty = sizeofCtype ambient cty
theorem CerbMem.offsetsof_measure_sufficient (ambient tagDefs : CerbTags.TagDefsMap) (tagSym : sym) (ignoreFlexible : Bool)
    (lemHyp : CerbTagsWf.AcyclicPair ambient tagDefs) (lemFuel : Nat)
    (lemMeasureLe : CerbTagsWf.offsetsofBound ambient tagDefs ≤ lemFuel) :
    offsetsof_lemFuel lemFuel ambient tagDefs tagSym ignoreFlexible = offsetsof ambient tagDefs tagSym ignoreFlexible
theorem showNonNegativeWithBasis_aux_measure_sufficient (acc : List Char) (useUpper : Bool) (b : Nat) (n : Nat)
    (lemHyp : (2 ≤ b)) (lemFuel : Nat) (lemMeasureLe : (n + 1) ≤ lemFuel) :
    showNonNegativeWithBasis_aux_lemFuel lemFuel acc useUpper b n = showNonNegativeWithBasis_aux acc useUpper b n
```

(the other four `CerbMem` obligations have the same shape with their measure
and `CerbTagsWf.Acyclic ambient`).

## 2. What `CerbTagsWf.Acyclic` IS, and how you discharge it

New hand-written module `lean_frontend/CerbTagsWf.lean` (in
`handwritten_copy.manifest`; imported by `CerbMem`):

```lean
abbrev Entry := CerbLocation.Loc × tag_definition
def lookupEntry (m : TagDefsMap) (tag : sym) : Option (sym × Entry) :=
  (fmapElements m).find? (fun (s, _) => symbolEquality s tag)        -- CerbMem's lookup, named once
def lookup (m) (tag) : Option Entry := (lookupEntry m tag).map Prod.snd
def refsOf : ctype → List sym            -- by-VALUE tag references: Struct/Union0 heads through Array0/Atomic; never Pointer/Function
def memberTypes : tag_definition → List ctype  -- every member's type + its `_Alignas(type)` type + the flexible member's element type
def refsOfDef (d) : List sym := (memberTypes d).flatMap refsOf
def Ranked (lookS lookU : sym → Option Entry) (R : Entry → Nat) : Prop :=
  ∀ t v, (lookS t = some v ∨ lookU t = some v) →
    ∀ t' ∈ refsOfDef v.2, ∀ v', (lookS t' = some v' ∨ lookU t' = some v') → R v' < R v
def Acyclic (m : TagDefsMap) : Prop := ∃ R, Ranked (lookup m) (lookup m) R
def AcyclicPair (ambient tagDefs : TagDefsMap) : Prop := ∃ R, Ranked (lookup tagDefs) (lookup ambient) R
theorem Acyclic.pair : Acyclic m → AcyclicPair m m
```

In words: **some rank on the environment's ENTRIES descends along every
by-value reference that resolves** — the layout recursion enters a struct's
or union's definition only through a type that contains it by value (arrays
and atomics included, pointers and function types excluded: `sizeof(T*)` does
not look at `T`). It is stated over the lookup the code performs (digest+nat
symbol equality, description-insensitive), never over the map's tree, so no
comparator law is involved; ranks are on the stored `Loc × tag_definition`
values, so two symbols resolving to the same entry share its rank.

**Why it holds for every C program the frontend accepts CORRECTLY** (the
register `scripts/fuel_hypotheses.txt` cites this per row; rows signed by the
pre-merge auditor, audit `e9730d1c8`): the frontend accepts a struct/union
definition only when every member's type is complete (`cabs_to_ail.lem:1512`
`check_members`, STD §6.7.2.1#3), and `AilTypesAux.is_complete`
(`ail/ailTypesAux.lem:222`) makes a by-value `Struct sym`/`Union sym` complete
only when `sym` is ALREADY in `sigm.tag_definitions` (a `Pointer` is complete
regardless of its target); the flexible array member's element type is
guaranteed by the Ail passes (`ailWf.lem:76-80`, `genTyping.lem:2346-2349`:
every by-value edge INTO a FAM struct is a constraint violation); an
`_Alignas(type)` is completeness-checked by `alignof_ty` (`cabs_to_ail.lem:
2851-2871`) EXCEPT on a character-typed member (`:2882-2883`,
`ailTypesAux.lem:1291-1292`) — the one known gap: `struct A { _Alignas(struct
A) char c; }` (an ISO §6.5.3.4#1 constraint violation gcc rejects) is accepted,
`Acyclic` is FALSE for it, both oracles hang and the Lean wrapper fails loudly
(audit F-A2; upstream-tray candidate). So **definition order is a rank**: `R :=
the index of the entry in definition order` satisfies `Ranked`. A hand-authored
Core file can violate it too — then the fuel-free wrapper may EXHAUST (the loud
`fuelExhaustedWith` sentinel), as the oracle itself loops there — which is
exactly why the hypothesis is in the obligation and not assumed by the wrapper.

**How you discharge it for YOUR environments.** Your theorems about a program
already assume its tag table is the frontend's; add `CerbTagsWf.Acyclic
tagDefs` to that assumption (it is what the frontend guarantees) and pass it
where a layout theorem needs it. To PROVE it for a concrete table, exhibit
the rank: for a table built by `fmapAddBy` in definition order, `R v :=
position of v in (fmapElements m).map Prod.snd` … or simply the definition
index — and show each member's by-value references resolve to earlier
entries (decidable per entry: `refsOfDef` is a computable list, `lookup` a
list search). For `offsetsof` at elaboration time (`offsetofIval tagDefs
tagDefsMap`), the ambient map is EMPTY and `AcyclicPair {} m` is `Acyclic m`
on the threaded map; at run time both maps are the linked table and
`Acyclic.pair` gives `AcyclicPair m m`. A decidable checker with a soundness
theorem is a registered follow-up (TODO.md, C4 block), not in this slice.

**The measures** (they EXECUTE — the wrappers' fuel arguments; derived from
the hop structure, no budgets): `defSize d := Σ lemSize (memberTypes d)`,
`defsWeight m := Σ_{entries} (defSize + 2)`, `envBound m ty := lemSize ty +
defsWeight m + 1`, `memberBound m al ty := lemSize ty + alignSize al + defsWeight
m + 2`, `membersBound m members := membersSize members + defsWeight m + 2`,
`offsetsofBound ambient tagDefs := defsWeight ambient + 2·defsWeight tagDefs +
3`. For `rfl`/`decide` over a concrete table these are small closed terms;
`defsWeight` is a full traversal of the environment at every call (the
F-C3-4 mechanism; registered follow-up).

## 3. What did NOT change for you

- The remaining eight pending rows (`scripts/fuel_forms_pending.txt`): the
  `ctype_aux` compatibility trio stays AMBIENT — its recursion goes through
  pointers and function types (STD §6.2.7#1), which by-value acyclicity does
  not bound and no frontend-guaranteed hypothesis does (record F-C4-1); `hack`,
  `to_pure`/`to_pures`, `many`/`many1` as before. `memValueFromValue`,
  `step_eval_pexpr`, `easy_update_mem_value_aux`, `memcmp_load_aux` keep
  `[LemFuel]` (they reach the trio).
- The ~20 `CerbMem` functions that took `[LemFuel]` only to reach the layout
  oracle (`sizeofIval`, `loadM`, `storeM`, …) still carry the binder — dead,
  nothing below them reads the ambient fuel; removal is the registered
  follow-up (it cascades through mem.lem's `fuel_consumer` declares into
  generated heads, so it gets its own manifest).
- The generated tree outside `Formatted`/`Formatted_auxiliary`: byte-identical
  to C3's (the OCaml tree byte-identical at every step).

## 4. The gate you can rely on

`scripts/check_fuel_forms.sh` now reports, per MEASURED row, the hypothesis
(the `lemHyp` binder's type, notation-printed) and requires it to equal a row
of the REVIEWED register `scripts/fuel_hypotheses.txt` (worker, exact text,
invariant with a `.lem:<line>` cite, reviewer) — both directions; its
`--selftest` compiles a decoy obligation under the contradictory hypothesis
`env1 ≠ env1` and shows the register turning it red. Read the register as the
list of hypotheses in force: 6 × `CerbTagsWf.Acyclic`/`AcyclicPair`, 1 × `2 ≤ b`.
