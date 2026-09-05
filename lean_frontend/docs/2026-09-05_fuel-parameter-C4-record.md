# Fuel-parameter arc, cerberus half — slice C4 record (2026-09-05)

Branch `arc/fuel-parameter-C4` (worktree `worktrees/cerberus-lean-arc/zero-discrepancy`),
ff-rebased at the start of the slice from `eb27fa70f` onto mainline
`mdd/cerberus-lean` @ `31eba718e` (the merged Z3 + Z4 docs + typed-failure R1;
the coordinator's instruction — done before any work, so every build and
gate of this slice is on the rebased base; no textual conflict arose because
the branch had no commits yet; the VALIDATION.md/TODO.md edits below were
made on the REWRITTEN VALIDATION.md). Charter (the orchestrator's brief): the
Lake pin bump to lem-lean `f6542f8` (the measure-hypothesis slice — the
`assuming` clause) and the twelve hypothesis-carrying measured rows. Worker
[AGENT]; rulings quoted with [USER] provenance; every quoted output is
verbatim from this worktree (`.tmp/c4/` logs, ephemeral, deleted at slice
end); tallies marked "derived" are derived. Nothing merged, nothing pushed;
lem-lean, `deps/`, the primary checkout and the other worktrees untouched.

## 0. Summary — READ THIS FIRST

- **Pin bump** (commit 1/3 `be1cebe36`, alone): LemLib `d4ba548` → `f6542f8`
  in `lakefile.toml` + the three `lake-manifest.json`. Regenerated from
  re-derived trees: OCaml BYTE-IDENTICAL (86/86, `gen 295e4f82…` unchanged),
  sibylfs identical, the LEAN tree byte-identical in its 170 lem-generated
  files and every seam copy except the four hand-written files Z3 changed on
  the mainline (`CabsImport`, `CerberusFresh`, `CoreParser`, `Main` — sha-
  checked: pre = `eb27fa70f`'s, post = HEAD's; `gen e48450a7…` unchanged).
  `test_unit` + Tier A rows 2–11 green (§6.1).
- **The hypothesis vocabulary** (commit 2/3): NEW seam module
  `lean_frontend/CerbTagsWf.lean` — `lookup`/`lookupEntry` (CerbMem's tag
  lookup named once), `refsOf`/`memberTypes`/`refsOfDef` (the by-VALUE
  reference graph), `Ranked`, **`Acyclic m := ∃ R, Ranked (lookup m) (lookup m)
  R`**, `AcyclicPair ambient tagDefs` (the two-map form `offsetsof` needs), and
  the measures `envBound`/`memberBound`/`membersBound`/`offsetsofBound`
  (structural size + the environment's weight; §2). The frontend guarantee is
  DOCUMENTED with cites (`cabs_to_ail.lem:1512 check_members`,
  `ail/ailTypesAux.lem:222 is_complete`, `:1600-1603`, `:2860-2870`), not
  proved from the Lean-side table construction (§2.3 says why).
- **Seven of the twelve rows are MEASURED under a hypothesis** (commit 2/3):
  the six hand-written `CerbMem` workers (`sizeofCtype`, `alignofCtype`,
  `memberAlign`, `offsetsofMembers`, `offsetsof`, `reconstructValue`) by hand
  in the generated `assuming` shape, proofs in `CerbMem_lemMeasureProofs.lean`
  (one joint five-part strong induction for the layout block + the
  `reconstructValue` induction over it, §3), and `showNonNegativeWithBasis_aux`
  via lem's ``declare {lean} fuel_measure val … = `n + 1` assuming `2 ≤ b` ``
  (the first generated hypothesis-carrying row; proof in NEW
  `Formatted_lemMeasureProofs.lean`). Every cone `[propext, Classical.choice,
  Quot.sound]`; no `sorry`, no option bump. `memValueToBytes` lost its
  `[LemFuel]` with them (its only fuel need was the layout oracle).
- **Three rows stay PENDING with a FINDING (F-C4-1, §7):** the `ctype_aux`
  trio (`are_compatible_aux` + 2) recurses through POINTER and FUNCTION types
  (STD §6.2.7#1 structural compatibility, the cross-TU Struct/Struct arm), so
  by-value acyclicity does not bound it — the lem dry run's proposed
  `Acyclic p.1 ∧ Acyclic p.2` is INSUFFICIENT, and the sufficient hypothesis
  (acyclicity through all references) is NOT frontend-guaranteed (linked lists
  are legal C): `struct node { struct node *next; }` in two TUs makes the
  oracle recurse forever (both oracles `rc=124` at 60 s; the Lean driver dies
  by native stack overflow, rc=134, before any fuel is consumed — audit
  F-A7). Per the brief, a finding, not a fix. `hack`, `many`,
  `many1`, `to_pure`, `to_pures` stay as before. Register 15 → 8.
- **The gate + the register** (commit 2/3): `FuelFormsTool` pins the fuel
  binder by NAME `lemFuel` (lem audit N1), recognizes the hypothesis-carrying
  form by its reserved binder `lemHyp` immediately before it, and reports the
  hypothesis (notation-printed) as a new `hyp` column; `check_fuel_forms.sh`
  requires every MEASURED-under-hypothesis row to equal a row of the NEW
  reviewed register `scripts/fuel_hypotheses.txt` (worker · exact hypothesis ·
  frontend invariant with `.lem:<line>` cite · reviewer), both directions,
  plant-tested with 11 plants incl. a COMPILED decoy under the contradictory
  hypothesis `env1 ≠ env1` (MEASURED by shape, RED by the register — the lem
  audit's F1 closed on the consumer side, §5); 12 after the audit response
  (§9a: every non-reserved binder must be a wrapper argument, plant P11). The
  register rows are SIGNED by the pre-merge auditor (§9a); the operator's
  merge "yes" is the final signature. Gate: `54 MEASURED (7 under a
  hypothesis), 13 ABSORBING, 8 pending, 6 unreachable`.
- **OCaml byte identity at every step** (§2.2, §4): the `.lem` change is one
  Lean-only declare + a comment block in `formatted.lem`; `gen 295e4f82…`
  throughout.
- **Battery** (§6): full Tier A + Tier B on fresh stamped binaries — see §6.2.
- **Decisions for the operator**: §8. **Commits**: §9. **Not done**: §10.

## 1. Rulings in force

[USER 2026-09-05] "agree, go ahead with option 1" — hypothesis-carrying
obligations, Lean-only (the lem `assuming` clause; the C2 record's D-C2-1).
[USER 2026-09-04] "we don't change the lem structure for ocaml" — the OCaml
generated tree is byte-identical at every step (§2.2, §4). [USER 2026-09-03]
no magic values — every measure here is an expression over the parameters
whose constants are hop counts derived in the proof (§2.4). [USER 2026-09-03]
the semantics is a reasoning artifact — the hypothesis is a Prop the
consumer's theorems carry, never something the wrapper assumes. Each fuel'd
call starts from the full ambient — unchanged (the remaining ambient
wrappers are untouched).

## 2. The pin bump and the predicates

### 2.1 Pin evidence (commit 1/3 `be1cebe36`)

opam (done by the orchestrator before the slice): `opam exec --switch=. -- lem -v`
→ `Lem f6542f8`; `deps/lem-pinned` HEAD `f6542f8e6860d12d4655e6648bc4c45dabd1d798`.
Lake: `lakefile.toml` `rev` → that hash (comment records the bump); `lake update
LemLib` (capped, `CERB_MEM_MAX=32G`) in `lean_frontend` (verbatim: `info: LemLib:
URL has changed; deleting '…/lean_frontend/.lake/packages/LemLib' and cloning
again` / `info: LemLib: cloning https://github.com/OathTech/lem-lean` / `info:
LemLib: checking out revision 'f6542f8e6860d12d4655e6648bc4c45dabd1d798'`), then
`speclab` and `tests/mem-scale-probes/micro` (`info: toolchain not updated;
already up-to-date`). All three manifests `"rev"`/`"inputRev"` = the hash.

### 2.2 The two trees at the bump

Snapshots of the `eb27fa70f` head's `lean_frontend/generated/` (205 files),
`ocaml_frontend/generated/` (86) and `sibylfs/generated/` (16) taken BEFORE
the rebase and regeneration (`.tmp/c4/pre/`; the branch had no commits, and
no `.lem` differs between `eb27fa70f` and `31eba718e` — `git diff --stat` on
`frontend/ ocaml_frontend/ backend/ sibylfs/` is `backend/driver/main.ml | 17`
only). Then `make clean-prelude-src prelude-src`, `rm -rf lean_frontend/generated
&& make lean-prelude-src`, verbatim stamps:

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)
```

— both `gen` hashes the C3/eb27fa70f head's. The diffs, verbatim (`.tmp/c4/pinbump-diff.txt`):

```
OCAML diff -rq rc=0 lines=0 files=86
SIBYLFS diff -rq rc=0 lines=0 files=16
LEAN diff -rq rc=1 lines=4 files=205
  Files .tmp/c4/pre/lean/CabsImport.lean and lean_frontend/generated/CabsImport.lean differ
  Files .tmp/c4/pre/lean/CerberusFresh.lean and lean_frontend/generated/CerberusFresh.lean differ
  Files .tmp/c4/pre/lean/CoreParser.lean and lean_frontend/generated/CoreParser.lean differ
  Files .tmp/c4/pre/lean/Main.lean and lean_frontend/generated/Main.lean differ
```

The four are Z3's hand-written changes, not lem's output — sha-checked
(prefixes): `CabsImport pre=f299cedd70e5 eb27=f299cedd70e5 post=c1756e3190cb
head=c1756e3190cb`, `CerberusFresh pre=c3d10fc2f362 eb27=c3d10fc2f362
post=4ada084cc409 head=4ada084cc409`, `CoreParser pre=9c66b0119299
eb27=9c66b0119299 post=523300f8f3ab head=523300f8f3ab`, `Main pre=285b818b1300
eb27=285b818b1300 post=313fa340997c head=313fa340997c`. **The Lean tree at the
pin bump is EMPTY-diff on every lem-generated file** (the lem record §5.6's
prediction holds on the real tree). Oracle rebuilt `DUNE_CACHE=disabled`
(Z3's `main.ml` had changed): `check_driver_fresh: recorded oracle stamp (bin
f43350f96e609b86317dd91e106397d6fd4d7c885e244a32eb5493618f32085a, src
69a0a3bce0ed30c7612d80656485d680bc7e6a62b75f658590742e61ce4a21d3)`; `build_lean`
→ `Build completed successfully (271 jobs).` / `check_driver_fresh: recorded
lean stamp (bin 17a894c3f22e9340505b983ea02ccff6df6b42e54734b56e0df8076ec157429c,
src 1db760a4a3c1bc4fa245cd801368997f84653575e240c3f0554f4cf26b2106e9)`.

### 2.3 The predicates (`lean_frontend/CerbTagsWf.lean`) and their guarantee status

The layout oracle recurses through TAG LOOKUPS: a struct's size is computed
from its members' types, read from the tag environment. The predicate is
stated over the LOOKUP the code performs and over the by-VALUE reference
graph:

- `lookupEntry m tag := (fmapElements m).find? (fun (s, _) => symbolEquality s tag)`
  — CerbMem's exact lookup text (digest+nat, description-insensitive), named
  ONCE; the six CerbMem lookup sites now call it (a defeq-preserving refactor
  the proofs need: two textually identical pattern-lambdas in two modules
  elaborate to two matcher constants, which `split`/`rw` cannot identify).
  `lookup m tag := (lookupEntry m tag).map Prod.snd` (the entry).
- `refsOf : ctype → List sym` — `Struct t`/`Union0 t` → `[t]`, through `Array0`
  and `Atomic`, NOTHING through `Pointer` or a function type (impl_mem.ml's
  pointer arms return the pointer size without looking at the pointee).
- `memberTypes : tag_definition → List ctype` — every member's type, its
  `_Alignas(type)` type (memberAlign enters it, impl_mem.ml:115-122), and a
  struct's flexible array member's element type (offsetsof appends it,
  :104-108; alignof folds `Array0 elemTy none` in, :234-239).
  `refsOfDef d := (memberTypes d).flatMap refsOf`.
- `Ranked lookS lookU R := ∀ t v, (lookS t = some v ∨ lookU t = some v) → ∀ t' ∈
  refsOfDef v.2, ∀ v', (lookS t' = some v' ∨ lookU t' = some v') → R v' < R v`.
  Two lookups because struct tags resolve in the THREADED map and union tags
  in the AMBIENT one (impl_mem.ml:173/:255, the mirrored upstream asymmetry).
- **`Acyclic m := ∃ R : Entry → Nat, Ranked (lookup m) (lookup m) R`** — some rank
  on the environment's ENTRIES (the stored `Loc × tag_definition` values, so
  two symbols resolving to the same entry share its rank) descends along every
  by-value reference that resolves. The hypothesis of the five one-map wrappers
  and of `reconstructValue`.
- **`AcyclicPair ambient tagDefs := ∃ R, Ranked (lookup tagDefs) (lookup ambient) R`**
  — the hypothesis of `offsetsof ambient tagDefs`: ONE rank for both maps.
  `Acyclic ambient ∧ Acyclic tagDefs` would NOT do: a struct in `tagDefs`
  containing by value a union of `ambient` containing that struct is a cycle
  across the two maps that each map's own rank misses. `Acyclic.pair : Acyclic
  m → AcyclicPair m m` (the run-time case; at elaboration time the ambient map
  is empty and `AcyclicPair {} m` is `Acyclic m` on the threaded map).

**Guarantee status: DOCUMENTED, not proved.** The brief asked to prove the
frontend guarantee "where it is provable from the Lean-side tag table
construction, else document the frontend invariant with the cite". The tag
table is built by the desugaring (`cabs_to_ail.lem`, lem-generated); a Lean
theorem "every table `desugar` produces is `Acyclic`" is a theorem about the
whole desugaring pass — not this slice's size. The invariant, with cites, is
in the module header, in the register, and in the manifest: `check_members`
(`cabs_to_ail.lem:1512`, STD §6.7.2.1#3) refuses a member of function or
INCOMPLETE type; `AilTypesAux.is_complete` (`ail/ailTypesAux.lem:222`) makes a
by-value `Struct sym`/`Union sym` complete only when `sym` is ALREADY in
`sigm.tag_definitions`, `Array` iff its element type is (and sized), `Atomic`
iff its inner type is, `Pointer` regardless of its target; the flexible array
member's ELEMENT type is guaranteed by the Ail passes (`ailWf.lem:76-80`,
`genTyping.lem:2346-2349` — every by-value edge INTO a FAM struct is a
constraint violation; audit F-A3 corrected the first version's
`cabs_to_ail.lem:1600-1603`, which registers the FAM without looking at the
element type); `_Alignas(type)` is completeness-checked by `alignof_ty` on the
non-agnostic path (`cabs_to_ail.lem:2851-2871`) — NOT on the character-member
`Just LT` path (`:2882-2883`, `ailTypesAux.lem:1291-1292`): audit F-A2, the
frontend GAP of §9. Hence, for every program the frontend ACCEPTS CORRECTLY,
definition order is a rank on the by-value graph. A hand-authored Core file
(or the F-A2 class) can violate it; the wrapper then may exhaust (loud), where
the oracle loops. `Acyclic` is an existential over ranks, not decidable as stated; a
decidable bounded-traversal checker with a soundness theorem (the Tier C
load-time instrument the brief called optional) is a registered follow-up
(TODO.md, C4 block), not done here.

### 2.4 The measures (execute; every constant is a hop count)

`defSize d := Σ lemSize (memberTypes d)`; `defsWeight m := Σ_{(_, (_, d)) ∈
fmapElements m} (defSize d + 2)`; `envBound m ty := lemSize ty + defsWeight m +
1` (sizeof, alignof, reconstructValue); `alignSize`, `memberBound m al ty :=
lemSize ty + alignSize al + defsWeight m + 2`; `membersSize`, `membersBound m
members := membersSize members + defsWeight m + 2`; `offsetsofBound ambient
tagDefs := defsWeight ambient + 2·defsWeight tagDefs + 3`. Why: along any path
of the recursion each ENTRY is entered at most once (the rank strictly
descends), and between two hops the recursion descends structurally inside one
entry's member types; the longest hop (sizeof → offsetsof → offsetsofMembers →
sizeof/memberAlign → alignof) spends two frames beyond the structural ones —
the `+ 2` per entry; the `+ 1`/`+ 2`/`+ 3` per wrapper are its own frames
(§3.1). The lem dry run's `(tagCount + 1) * (lemSize + defsSize + 1)` was
a proposal; the linear form is what the proof yields (the product form's
compression of the rank to `tagCount` was not needed: the weight of the
entries ranked below `v` is bounded by the whole weight directly).

## 3. The proofs

### 3.1 The layout block (`CerbMem_lemMeasureProofs.lean`, section `Layout`/`LayoutStable`/`LayoutObligations`)

Given a rank `R` and a list `L` of entries both lookups return elements of:
`W R L v := Σ_{v' ∈ L, R v' ≤ R v} (defSize v'.2 + 2)` (the weight of the entries
ranked at most `v`); `tp ty` (the tag potential: `W v` when `ty`'s head tag —
through arrays/atomics — resolves to `v`, else 0); **`pot ty := lemSize ty + tp
ty`**; `mPot al ty := max (pot ty) (alignPot al)`; `membersPot` (max over a
member list); `oPot t flag` (`membersPot (structMembers membrs flex flag) + 3`
when `t` resolves to a struct, else 1). The five measures: alignof `pot`,
sizeof `pot + 1`, memberAlign `mPot + 1`, offsetsofMembers `membersPot + 2`,
offsetsof `oPot`. Key lemmas: `W_step` (the hop inequality: `v ∈ L → R v' < R v
→ W v' + (defSize v.2 + 2) ≤ W v`), `tp_spec` (a tag potential is 0 or the
weight of an entry one of the type's by-value references resolves to),
`pot_member` (THE HYPOTHESIS AT WORK: `y ∈ memberTypes v.2 → pot y + 2 ≤ W v` —
`Ranked` gives `R v' < R v` for the entry `y`'s reference resolves to, `W_step`
turns it into the two spare frames), `structMembers_types` (every member the
offsetsof fold visits, flexible member appended or not, has its types among
the definition's `memberTypes`). `layout_stable_aux` is ONE joint statement
(∧ of five) by strong induction on the bound `k`, each part the C2/C3
template (`cases f`/`cases g`, `simp only [worker]`, `split` on the lookup,
the induction hypotheses as `key` rewrites, `lfoldl_congr` for the member
folds). The concrete measures dominate: `W_le_total` (a filtered weight ≤
the whole weight), `sum_entries` (= `defsWeight`), `pot_le`/`mPot_le_size`/
`membersPot_le_size`/`membersPot_le_entry`. The five obligations instantiate
`L := entries ambient` (one map) or `entries ambient ++ entries tagDefs`
(offsetsof) and read `R` from the hypothesis.

### 3.2 `reconstructValue` (section `Reconstruct`)

Its struct arm's member types come out of the (now fuel-free) `offsetsof`
wrapper, so the proof characterizes that output: `offsetsofMembers_types` (the
fold conses one `(ident, ty, off)` per member — `foldl_offs_mem`), `offsetsof_types`
(`∀ x ∈ (offsetsof_lemFuel (n + 2) …).1, ∃ v, lookup tagDefs t = some v ∧ x.2.1 ∈
memberTypes v.2`; the `panic!` arm is `default` by `rfl`, `panic_eq_default`);
the wrapper's fuel `offsetsofBound ambient ambient` is rewritten to the
`(… + 1) + 2` form. The union arm's member is one of three things (the first
member, the recorded member found by `idEqual`, or the panic default `(default,
Ctype default Void0)` with `pot = 2`) — `split` twice, each bounded. Stability
by strong induction on `pot ty`; the arrays through `lmap_congr`, the struct
fold through `to_congr`.

### 3.3 `showNonNegativeWithBasis_aux` (`Formatted_lemMeasureProofs.lean`, NEW)

The lem suite's `ndigits` template: `lemNatDiv_of_pos` (`0 < b → lemNatDiv n b
= n / b`), strong induction on `n`, the hypothesis `2 ≤ b` used exactly at
`Nat.div_lt_self` — without it the statement is false (the lem record §3's
kernel-checked counterexample for `ndigits` at `b = 1`).

### 3.4 Axioms, verbatim (`lake env lean` on a scratch file importing the proofs)

```
'CerbMem.sizeofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.alignofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memberAlign_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsofMembers_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsof_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.reconstructValue_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memValueToBytes_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
```

(`showNonNegativeWithBasis_aux_measure_sufficient`'s cone is `axioms=ok` in
the gate's table, §5; the tool probes every obligation AND proof constant.)
No `set_option`, no `sorry` (check_sorry_token), kernel-only tactics.

### 3.5 Slips caught on the way (recorded, not hidden)

- The first `pot_struct` said `1 + W v`; `lemSize (Ctype _ (Struct t))` is 2
  (`Ctype` and `Struct` each count 1) — the checker caught it; the hop
  constants have one frame more slack than §2.4's derivation needs.
- `rw [hinit]` on a `match flex with …` stated in the proof file failed —
  the goal's match is CerbMem's matcher constant, the proof's a fresh one;
  the arm was restructured to `cases flex` first (the same lesson made the
  lookup a named function, §2.3).
- The `Basic` arms need `cases bty` before the nested-pattern match reduces
  (`| .Basic (.Integer _)`/`| .Basic (.Floating _)`).
- `List.find?`/`fmapLookupBy`: the lem rows would have needed a lemma relating
  `Pmap.find?` under an OPAQUE captured comparator to `bindings` membership
  (provable as a tree walk without comparator laws) — moot, the rows stay
  pending (§7).

## 4. OCaml byte identity and the Lean tree after the declare

After the `formatted.lem` edit (one declare + one 10-line comment block, the
whole `.lem` diff of this slice), `make prelude-src`, verbatim:

```
check_lem_sync: recorded ocaml_frontend/lem_sync.sha256 (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
prelude-src rc=0
OCAML diff -rq (vs pre-C4 snapshot, after the formatted.lem declare) rc=0 lines=0 files=86
```

— **BYTE-IDENTICAL** (the `gen` hash is the pre-arc one; `src` moves with the
`.lem` text by construction). Lean: `check_lem_sync: recorded
lean_frontend/lem_sync.sha256 (src 97732651…, gen
11c6b37a5dc95ed9f2ec3d1f6f3e157e1f0309c7236e247b9d279deaf1ab2938)`; `diff -rq`
vs the pre snapshot (Z3's four excluded), verbatim:

```
LEAN diff -rq vs pre (Z3 four excluded): 6 entries
  Files .tmp/c4/pre/lean/CerbMem.lean and lean_frontend/generated/CerbMem.lean differ
  Files .tmp/c4/pre/lean/CerbMem_lemMeasureProofs.lean and lean_frontend/generated/CerbMem_lemMeasureProofs.lean differ
  Only in lean_frontend/generated: CerbTagsWf.lean
  Files .tmp/c4/pre/lean/Formatted_auxiliary.lean and lean_frontend/generated/Formatted_auxiliary.lean differ
  Files .tmp/c4/pre/lean/Formatted.lean and lean_frontend/generated/Formatted.lean differ
  Only in lean_frontend/generated: Formatted_lemMeasureProofs.lean
```

The generated wrapper and obligation, verbatim (`Formatted.lean`,
`Formatted_auxiliary.lean:42-44`):

```lean
def showNonNegativeWithBasis_aux ( acc : List (Char)) ( useUpper : Bool) ( b : Nat) ( n : Nat) : List (Char) := showNonNegativeWithBasis_aux_lemFuel (n + 1)  acc  useUpper  b  n
theorem showNonNegativeWithBasis_aux_measure_sufficient ( acc : List (Char)) ( useUpper : Bool) ( b : Nat) ( n : Nat) (lemHyp : (2 ≤ b)) (lemFuel : Nat) (lemMeasureLe : (n + 1) ≤ lemFuel) :
    showNonNegativeWithBasis_aux_lemFuel lemFuel  acc  useUpper  b  n = showNonNegativeWithBasis_aux  acc  useUpper  b  n :=
  Formatted_lemMeasureProofs.showNonNegativeWithBasis_aux_measure_sufficient  acc  useUpper  b  n lemHyp lemFuel lemMeasureLe
```

`[LemFuel]` binders (derived; comment-stripped grep of `[LemFuel]` in
`lean_frontend/generated/`, seam copies excluded / all files): generated
model 251 → 249 (`Formatted` 19 → 17 — no caller of the wrapper carried the
binder for it alone); all files incl. seams 317 → 300; the `CerbMem` seam 38 →
23 (the five layout wrappers, `reconstructValue` + its `_indexed` twin and two
theorems, `memValueToBytes` + `_append` twin and two theorems; the 23 left are
the callers' dead binders — TODO.md C4 block). Ambient generated wrappers 23 →
22 (`gen_fuel_parametricity --emit` regenerated the pins).

Oracle re-stamped `DUNE_CACHE=disabled`: `check_driver_fresh: recorded oracle
stamp (bin 10c1aefddb1fa3bf9db27164837ad35f1269a2bac978b2f1b7932f629aa6daf9, src
46d26f1f7ede22ffb6d3ff563194b8423a297775cef211805388c6c88217efda)`; `build_lean`
→ `Build completed successfully (271 jobs).` / `check_driver_fresh: recorded
lean stamp (bin 32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6,
src …)` — the Lean binary of the slice head (its `src` stamp moved once more
with the proof-module fixes; `bin` unchanged, the proofs are not linked).

## 5. The gate, the registers and the plants

`FuelFormsTool.lean`: `obligationShape` (was `obligationShapeMismatch`) walks
the ∀-telescope WITH binder names; the fuel binder is the one NAMED `lemFuel`
(`Nat`, an argument of the worker side), the measure hypothesis a later binder
`_ ≤ lemFuel`, and a binder named `lemHyp`, if present, must be immediately
before `lemFuel` (lem audit N1: the old check accepted ANY `Nat` binder with a
`≤` — e.g. `2 ≤ b` itself). The `lemHyp` type is pretty-printed under the
obligation's binder names (`Lean.PrettyPrinter.ppExpr` in a `forallTelescope`)
and whitespace-normalized into a 6th TSV column `hyp`. For notation to print
(`2 ≤ b`, not `instLENat.le 2 b`) the imported `app_unexpander` extension must
be loaded: `importModules (loadExts := true)` after
`Lean.enableInitializersExecution` — which is `unsafe`, so `main` is `unsafe`
and the C2 ratchet census pins it (`PIN UNSAFEDECL
lean_frontend/test/Unit/FuelFormsTool.lean main 1`, an INSTRUMENT-side unsafe
with its Q4 note in `scripts/unsafebaseio_allowlist.txt`; nothing in the
semantics imports the tool). The summary line gains `measured_under_hyp=N`.

`scripts/check_fuel_forms.sh`: `policy <table> <pending> <hypotheses>` adds
the register checks (a data row must have 4 TAB fields, a `.lem:<line>` cite,
a reviewer; table (worker, hyp) pairs = register pairs, both directions).
`scripts/fuel_hypotheses.txt` (NEW, 7 rows — the six `CerbMem` workers under
`CerbTagsWf.Acyclic ambient` / `AcyclicPair ambient tagDefs`, and
`showNonNegativeWithBasis_aux` under `2 ≤ b` with its five call sites cited);
reviewer field: `[AGENT C4 worker 2026-09-05]; operator review pending (C4
record §8)`. `scripts/fuel_forms_pending.txt`: the tag-lookup block replaced
by the DEEP-REFERENCE block (3 rows, the corrected reason), the
`showNonNegativeWithBasis_aux` row deleted — 15 → 8 (`are_compatible_aux`,
`are_compatible_params_aux0`, `are_compatible_params0`, `hack`, `to_pure`,
`to_pures`, `many`, `many1`). The plants: P6/P7 retargeted from
`CerbMem.sizeofCtype`/`alignofCtype` (real obligations now — a decoy of a real
obligation is a duplicate constant, not a plant) to `to_pure`/`to_pures`; NEW
P8 (a measured-under-hypothesis worker's register row deleted), P9 (a stale
register row `hack_lemFuel  0 < k`), P9b (a row without a `.lem:` cite), P10
(the COMPILED decoy `hack_measure_sufficient … (lemHyp : env1 ≠ env1) (lemFuel :
Nat) (_lemMeasureLe : 0 ≤ lemFuel) : hack_lemFuel lemFuel … = hack … := absurd rfl
lemHyp` — the tool reports it MEASURED with `hyp=env1 ≠ env1`, asserted as
the plant's premise; the register has no row → RED). Verbatim
(`.tmp/c4/gate-selftest.log`):

```
    plant table: FUEL_FORM	hack_lemFuel	MEASURED	yes/-	obligation=hack_measure_sufficient axioms=ok	env1 ≠ env1
    plant table: FUEL_FORM	to_pure_lemFuel	AMBIENT	yes/-	MALFORMED obligation=to_pure_measure_sufficient: conclusion is not an equation	
    plant table: FUEL_FORM	to_pures_lemFuel	AMBIENT	yes/-	MALFORMED obligation=to_pures_measure_sufficient: left-hand head `to_pures` is not the worker `to_pures_lemFuel`	
  PLANT OK   [P6 decoy obligation of type True (to_pure)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:
  PLANT OK   [P7 decoy obligation with the wrong worker constant (to_pures)] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:
  PLANT OK   [P10 decoy obligation under the CONTRADICTORY hypothesis env1 ≠ env1 (hack): MEASURED by shape, RED by the register] -> check_fuel_forms: FAIL — worker(s) MEASURED under a hypothesis with no reviewed register row for that exact hypothesis in …/scripts/fuel_hypotheses.txt (worker TAB hypothesis):
  PLANT OK   [P10 premise] -> the tool reports hack_lemFuel MEASURED hyp=env1 ≠ env1 (shape alone cannot see the contradiction)
  PLANT OK   [P8 register row of a measured-under-hypothesis worker deleted (CerbMem.sizeofCtype)] -> check_fuel_forms: FAIL — worker(s) MEASURED under a hypothesis with no reviewed register row for that exact hypothesis in …/scripts/fuel_hypotheses.txt (worker TAB hypothesis)
  PLANT OK   [P9 stale register row (hack under 0 < k)] -> check_fuel_forms: FAIL — hypothesis register row(s) whose worker is not MEASURED under that exact hypothesis (stale register row; edit the register):
  PLANT OK   [P9b register row without a .lem:<line> cite] -> check_fuel_forms: FAIL — hypothesis register row(s) not of the form <worker> TAB <hyp> TAB <invariant with a .lem:<line> cite> TAB <reviewer>:
check_fuel_forms: SELFTEST OK (11 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 3 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register; unplanted table green)
check_fuel_forms: forms partition OK (54 MEASURED + 13 ABSORBING + 8 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING, 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

(P1–P5 as before, all `PLANT OK`; the two `…/scripts/fuel_hypotheses.txt`
paths are abbreviated here, the log has the absolute path.) The `hyp` column
of the real table, verbatim (`.tmp/c4/tool-table.tsv`, columns 2 and 6):

```
CerbMem.alignofCtype_lemFuel | CerbTagsWf.Acyclic ambient
CerbMem.memberAlign_lemFuel | CerbTagsWf.Acyclic ambient
CerbMem.offsetsofMembers_lemFuel | CerbTagsWf.Acyclic ambient
CerbMem.offsetsof_lemFuel | CerbTagsWf.AcyclicPair ambient tagDefs
CerbMem.reconstructValue_lemFuel | CerbTagsWf.Acyclic ambient
CerbMem.sizeofCtype_lemFuel | CerbTagsWf.Acyclic ambient
showNonNegativeWithBasis_aux_lemFuel | 2 ≤ b
```

`test_unit.sh` on the slice head — see §6.2's gate tail.

## 6. Battery (fresh stamped binaries; default fuel; serial, `SKIP_BUILD=1`)

### 6.1 Tier A at the pin bump (commit 1/3), rows 2–11 — every lane rc 0

Stamps: oracle `bin f43350f9…`, lean `bin 17a894c3…` (§2.2); `test_unit.sh` rc 0
(its lines: `check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED …, 13
ABSORBING, 15 reachable-AMBIENT = the 15 rows …, 6 …)`, `gen_fuel_parametricity:
OK (23 … = the 23 pins …)`, `check_lakefile_roots: OK (204 roots …)`,
`check_sorry_token: OK (282 files …)`, `Total: 6 passed, 0 failed`). Rows 2–11
(`.tmp/c4/battery-pinbump/rc.txt`, every `rc=0`), summary lines verbatim:

| Row | Verbatim |
|---|---|
| A2_minimal (rc=0) | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3_coverage (rc=0) | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4_debug (rc=0) | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b_float (rc=0) | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c_bytes (rc=0) | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A5_libc_exec (rc=0) | `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE` (12 = Z3's baseline, one row more than C3's 11) |
| A6_multi_tu (rc=0) | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7_parse (rc=0) | `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8_core (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9_elab (rc=0) | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| A10_uri (rc=0) | `[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)` / `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11_cn (rc=0) | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |

### 6.2 Tier A + Tier B on the slice head

Stamps: oracle `bin 10c1aefd…`/`src 46d26f1f…` (§4), lean `bin 32f8b342…`/`src
fc62dc9a…` (the 2/3 head; `check_driver_fresh --check` OK inside every lane's
`SKIP_BUILD=1` freshness check). Mainline `mdd/cerberus-lean` re-checked
immediately before the battery: still `31eba718e` — no second rebase was
needed (the coordinator's instruction: rebase before the final battery). Box
rule: no other battery running (`pgrep`), load 1.41 at start; the box's load
average rose to `51.14` (1-min) at 17:32 from another agent's work — AFTER B7
had finished (B7 ran 17:06–17:28 at load 3.6–4.4) — and no lane moved.

`test_unit.sh` on this head, rc 0, the gate lines verbatim (sorted, unique;
`.tmp/c4/test_unit3.log`):

```
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING, 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (11 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 3 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register; unplanted table green)
check_handwritten_sync: OK (37 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lakefile_roots: OK (206 roots = 206 generated modules + the exe root Main; 85 auxiliary modules all built)
check_lem_sync: lean OK (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 11c6b37a5dc95ed9f2ec3d1f6f3e157e1f0309c7236e247b9d279deaf1ab2938)
check_lem_sync: OK (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_no_fuel_numerals: OK (290 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
check_sorry_token: OK (286 files scanned comment-stripped — generated 207, hand-written+test 44, LemLib 35; 0 sorry tokens)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: C2 ratchet OK (326 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 37 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: generated-tree census OK (207 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
✓ core-parser-test PASSED
✓ effects-proof-test PASSED
✓ fresh-int-test PASSED
✓ fuel-exemplar-test PASSED
gen_fuel_parametricity: OK (22 ambient fuel wrappers in the generated tree = the 22 pins of TotalityProofTest.lean Part 1, both directions)
✓ pp-test PASSED
test_fuel_classifier: 18 fixtures, ALL OK
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
Total: 6 passed, 0 failed
TotalityProofTest: all proofs kernel-checked at compile time (fuel parametricity of every fuel'd def + symbolic execution)
✓ totality-proof-test PASSED
```

28 lanes serially (`.tmp/c4/battery.sh head AB`, `.tmp/c4/battery-head/rc.txt`):
**28 × `rc=0`, ZERO baseline movement** — every line row-for-row the C3 /
Z3 baselines (A5 `match=12` is Z3's). Per-lane summary lines, verbatim:

| Row | Verbatim |
|---|---|
| A10_uri (rc=0) | `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)` |
| A11_cn (rc=0) | `SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0` / `BASELINE OK (213 entries, exact match)` |
| A2_minimal (rc=0) | `SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A3_coverage (rc=0) | `SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4b_float (rc=0) | `SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A4c_bytes (rc=0) | `SUMMARY: exec_match=9 neg_pinned=5 fail=0` |
| A4_debug (rc=0) | `SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0` / `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK` |
| A5_libc_exec (rc=0) | `SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED BASELINE` |
| A6_multi_tu (rc=0) | `SUMMARY: total=2 match=2 fail=0` / `ALL PASSED` |
| A7_parse (rc=0) | `Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A8_core (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| A9_elab (rc=0) | `SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0` |
| B1_libxml2 (rc=0) | `SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)` / `ALL PASSED` |
| B2_parse_ci (rc=0) | `Lean front end: 117 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 2 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)` / `Success rate:   51% (of cerberus successes)` / `ALL PASSED` |
| B3_core_ci (rc=0) | `Success rate:   100% (of cerberus successes)` / `ALL PASSED` |
| B4_verify (rc=0) | `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)` |
| B5_immaculate (rc=0) | `OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).` |
| B6a_speclab_self (rc=0) | `test_speclab [selftest] …/.tmp/scripts/speclab.ChhQrzx8rv/identity.c` / `test_speclab: PASS (both pipelines agree on Specified(0))` |
| B6b_speclab_plant (rc=0) | `test_speclab [plant] …/.tmp/scripts/speclab.YYYWLbU3IQ/plant.c` / `test_speclab: PASS (both pipelines agree on Specified(2))` |
| B6c_divmod (rc=0) | `CoreGateTest: ALL PASSED` / `test_speclab_divmod: PASS (--gate)` |
| B6d_bytearr (rc=0) | `ByteArrGateTest: ALL PASSED` / `test_speclab_bytearr: PASS (--gate)` |
| B6e_list (rc=0) | `ListGateTest: ALL PASSED` / `test_speclab_list: PASS (--gate)` |
| B6f_tree (rc=0) | `TreeGateTest: ALL PASSED` / `test_speclab_tree: PASS (--gate)` |
| B6g_seed (rc=0) | `SeedGateTest: ALL PASSED` / `test_speclab_seed: PASS (--gate)` |
| B7_gcc (rc=0) | `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1` / `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK` |
| B8a_hang (rc=0) | `test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)` |
| B8b_kill (rc=0) | `test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)` |
| B8c_fuel (rc=0) | `test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)` |

(the two speclab scratch paths abbreviated `…/.tmp/scripts/`; the B7 line
in full: `SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12
disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9
skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1` /
`Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane
OK` — the C3 record §13's row exactly; no row entered `SKIP_LEAN_TIMEOUT`, so
the eager `envBound` measure (F-C4-4) did not push any csmith row over the
lane's 30 s wall clock.)

## 7. Findings

- **F-C4-1 (the `ctype_aux` trio is not bounded by by-value acyclicity; no
  frontend-guaranteed hypothesis bounds it).** `Ctype_aux.are_compatible_aux`
  (`frontend/model/ctype_aux.lem:88-193`) implements STD §6.2.7#1 structurally:
  its `Pointer/Pointer` arm recurses into the pointee types (`:113`), its
  `Function/Function` arm into return and parameter types (`:108-109`), and
  its `Struct/Struct` arm — for two tags NOT from the same translation unit
  with the same name — looks both definitions up and recurses into the member
  pairs (`:122-153`; unions `:155-186`). So the recursion's graph is the
  DEEP-reference graph (through pointers), which C programs make cyclic all
  the time: with `struct node { struct node *next; }` in two translation units
  and a `struct node` value crossing them (the exec-path call site is
  `core_aux.lem:195`, `memValueFromValue`'s `Struct/OVstruct` arm comparing the
  ctype's tag with the loaded value's), the oracle recurses forever (OCaml:
  `Stack_overflow`) and the Lean driver fails loudly by NATIVE STACK OVERFLOW
  (`Stack overflow detected. Aborting.`, rc=134, ~3 s) before any fuel is
  consumed — `are_compatible_aux` is not tail-recursive and the 8 MB native
  stack goes first (audit F-A7 erratum: the first version of this sentence
  said "exhausts any fuel"; both oracles `rc=124` at 60 s, audit §5.1). The
  lem dry run's
  proposal `CerbTagsWf.Acyclic p.1 ∧ CerbTagsWf.Acyclic p.2` (measure
  `envBound p.1 p0.2 + envBound p.2 p1.2 + 1`) is therefore INSUFFICIENT — the
  obligation would be false for such environments; the hypothesis that IS
  sufficient (a rank descending through ALL references) is not frontend-
  guaranteed. Per the brief ("a hypothesis stronger than the frontend
  guarantees is a finding to report, not a fix") the three rows stay PENDING
  with the corrected reason; `paramsBound` was not introduced (nothing uses
  it). No probe was run in this slice (Tier C; TODO.md C4 block registers it
  with the upstream-tray candidate: the standard's compatibility rule needs an
  "assumed compatible" set for recursive types).
- **F-C4-2 (the two-map form is needed, and `Acyclic ∧ Acyclic` is not
  enough for it).** §2.3: `offsetsof ambient tagDefs` resolves struct tags in
  the threaded map and union tags in the ambient one; a cycle across the two
  maps is invisible to each map's own rank. `AcyclicPair` states one rank for
  both. Live at elaboration time (`offsetofIval tagDefs tagDefsMap`, the
  ambient EMPTY — CerbMem's layout header), where it reduces to `Acyclic` of
  the threaded map.
- **F-C4-3 (the tool's pretty-printer needs the loaded extensions).** Without
  `loadExts := true` the delaborator has no `app_unexpander` table and prints
  `instLENat.le 2 b`; with it (and hence `unsafe main`, census-pinned) `2 ≤ b`.
  The register compares TEXT, so the printing path is part of the gate's
  contract — recorded in the tool's header.
- **F-C4-4 (the measures' eager cost — the F-C3-4 mechanism, second
  instance).** `envBound` traverses the whole tag environment (`defsWeight`)
  on every layout call, including `sizeof(int)`. Not A/B-timed in this slice
  (no C3-head binary at hand after the rebuild); B7 held row-for-row (§6.2),
  so no row crossed the lane's timeout. Registered with the C3 timing item
  (TODO.md C4 block) with the cheaper sufficient measure named (pay the
  traversal only when `refsOf ty ≠ []`), for the operator to weigh against
  the trust-surface bar.

## 8. Decisions for the operator (nothing here was decided by me)

1. **The hypothesis register's reviewer field.** All 7 rows carry `[AGENT C4
   worker 2026-09-05]; operator review pending` — the register is meant to be
   REVIEWED; the operator (or a fresh reviewer) should read the invariant
   column against the cites and replace the field with their sign-off (or
   strike a row, which makes the gate RED until the hypothesis is changed).
2. **F-C4-1's disposition**: (a) keep the trio pending (done), (b) a probe +
   upstream-tray draft for the oracle's non-termination, (c) a lem body change
   (an "assumed compatible" accumulator, the standard's own device) — NOT
   Lean-only ("we don't change the lem structure for ocaml" — but here the
   OCaml would change behaviour too: it fixes a non-termination).
3. **The dead `[LemFuel]` binders** of the ~20 `CerbMem` callers and mem.lem's
   `fuel_consumer` declares (TODO.md C4 block): its own slice, with a
   generated-tree manifest for refined-cerberus, or leave.
4. **The decidable acyclicity instrument** (TODO.md C4 block): worth a Tier C
   lane check at load time? (`Acyclic` stays the abstract hypothesis either way.)
5. **F-C4-4**: accept (as F-C3-4 was, under the <10 % bar — to be measured with
   the C3 item on the whole csmith lane), or take the cheaper measure now.
6. **Pre-merge audit ask (unconditional):** proposed scope = the full range
   `31eba718e..HEAD`; proof-bearing surface = the 6 `CerbMem` obligations + their
   ~40 lemmas, `Formatted_lemMeasureProofs`; hypothesis surface = `CerbTagsWf`
   (is `Acyclic` exactly the frontend's invariant? is `refsOf`/`memberTypes`
   complete — every type the layout recursion enters?), the register's cites;
   mirror-doctrine surface = the `lookupEntry` refactor and the six wrapper
   changes in `CerbMem.lean`, the `formatted.lem` declare; gate surface =
   `FuelFormsTool.lean` (the named-binder pins, the `unsafe main`),
   `check_fuel_forms.sh` (the register logic and the 11 plants), the census
   PIN row.

## 9. Commits

| # | Commit | Content | Verified before commit |
|---|---|---|---|
| 1/3 | `be1cebe36` | Lake pin bump `d4ba548` → `f6542f8` (lakefile + 3 manifests), nothing else; base `31eba718e` (ff-rebase before any work) | trees regenerated from re-derived sources: OCaml/sibylfs BYTE-IDENTICAL, Lean byte-identical on every lem-generated file (§2.2); `DUNE_CACHE=disabled build_cerberus`, `build_lean`; `test_unit.sh` rc 0; Tier A rows 2–11 rc 0 (§6.1) |
| 2/3 | `e38d72c83` | `CerbTagsWf.lean` (NEW), the `CerbMem` lookup refactor + six measured wrappers, `CerbMem_lemMeasureProofs` (the layout block + `reconstructValue`), the `formatted.lem` declare + NEW `Formatted_lemMeasureProofs`, `FuelFormsTool` (named binders, `hyp` column, `unsafe main`), `check_fuel_forms.sh` (register logic, 11 plants), NEW `fuel_hypotheses.txt`, `fuel_forms_pending.txt` 15 → 8, pins 23 → 22, the census PIN row | OCaml byte-identical (§4); `#print axioms` of the seven `CerbMem` obligations standard-three (§3.4); `make lean-prelude-src` + `build_lean` + oracle cache-disabled, stamps OK; `test_unit.sh` rc 0 with the gate lines of §5/§6.2; one commit because the gate is fail-closed both ways (a measured row without its register row, or the register without the plants' targets, is a RED tree) |
| 3/3 | `ab342fc6a` | this record, the change manifest, `VALIDATION.md` (§6 row, §7 table 54/13/8/6 + the register), `TODO.md` (C4 block), `lean_frontend/CLAUDE.md` (the gate line) | docs-only; the battery of §6.2 on the 2/3 head |
| 4 | (audit response, this commit) | register corrections + signatures, F-A2/F-A7 text, F-A4 (`obligationShape` binder check + plant P11), F-A5 (dead `[LemFuel]`), TODO rows F-A2/F-A6/F-A7/F-A8, §9a | `make lean-prelude-src`, `lake build CerberusLean fuel-forms-tool`, `build_lean`, `check_driver_fresh --check`; `check_fuel_forms --selftest` (12 plants), `test_unit.sh`, exec minimal `--check-baseline`, `test_verify.sh`, `test_immaculate.sh` — every rc 0 (§9a) |


## 9a. Pre-merge audit response (audit `2026-09-05_fuel-parameter-C4-audit-premerge.md` @ `e9730d1c8`, branch `audit/c4-premerge`; verdict MERGEABLE, no MAJOR; all seven register rows SIGNED with three cite corrections)

One audit-response commit on `arc/fuel-parameter-C4` (the coordinator's
direction); every gate below re-run with its exit code checked explicitly.

- **The register** (`scripts/fuel_hypotheses.txt`): F-A1 — row 7's caller
  cites `:563,571,579,587,595` were stale by exactly the 10-line comment block
  the same commit inserted above them → `formatted.lem:573,581,589,597,605`
  (the gate's `.lem:[0-9]` check cannot see a wrong number — a limit of the
  format check, recorded). F-A3 — the FAM element-type guarantee comes from
  the Ail passes (`ailWf.lem:76-80` + `genTyping.lem:2346-2349`), not
  `cabs_to_ail.lem:1600-1603` → rows 2/3 and the header. F-A2 — row 3's
  `_Alignas(type)` text now names the checked path (`cabs_to_ail.lem:2851-2871`)
  and the UNCHECKED character-member path (`:2882-2883`,
  `ailTypesAux.lem:1291-1292`); rows 1/2/4/5/6 carry the F-A2 exception
  clause. Reviewer field on all 7 rows: `[AGENT auditor 2026-09-05, audit
  e9730d1c8] SIGNED; [USER] sign-off at merge`; the header states that the
  operator's explicit merge "yes" is the FINAL signature. The same
  corrections in `CerbTagsWf.lean`'s header, §2.3 above and the manifest.
- **F-A2 — a frontend-invariant GAP (record + TODO, no code).** `struct A {
  _Alignas(struct A) char c; }` is an ISO §6.5.3.4#1 constraint violation
  (gcc: `invalid application of '__alignof__' to incomplete type`) that the
  frontend ACCEPTS: `ailTypesAux.lem:1291-1292` returns `Just LT` for any
  character `decl_ty` and the `Just LT` arm (`cabs_to_ail.lem:2882-2883`)
  stores `AlignType al_ty` unexamined. The table then has a by-value self-edge
  through `alignTypes`, `Acyclic` is FALSE for it, BOTH oracles hang (`rc=124`
  at 60 s) and the Lean wrapper fails loudly (`CerbMem.memberAlign: fuel
  exhausted`, rc=134, 1 s; the control `_Alignas(struct B)` runs on all three,
  `Specified(4)`) — audit §5.2, verbatim there. Reading: the hypothesis is
  HONEST (the environment is not acyclic), the guarantee is "for programs the
  frontend accepts correctly", and Lean fails loudly where the oracle loops
  (the class-(b) direction of the zero-discrepancy rule); a frontend true-bug
  upstream-tray candidate (the Z4 code half owes the draft; TODO.md C4 block).
- **F-A7 — record erratum.** F-C4-1's two-TU `struct node`: the Lean driver
  at the default fuel dies by NATIVE STACK OVERFLOW (`Stack overflow detected.
  Aborting.`, rc=134, ~3 s), not by the fuel sentinel — corrected in §0, §7,
  `fuel_forms_pending.txt` and TODO.md ("exhausts any fuel" → "fails loudly by
  stack overflow before the fuel is consumed; the oracle loops"). Still an
  upstream TRUE BUG (both oracles `rc=124` at 60 s) → tray draft owed (Z4 code
  half); the stack-overflow-vs-fuel point is noted for the mem-scale/stack-
  ceiling backlog (TODO.md).
- **F-A4 — gate hardening (code).** `obligationShape` now requires EVERY binder
  that is not `lemHyp`, `lemFuel` or the `≤ lemFuel` hypothesis to occur as an
  argument of the WRAPPER side (an extra unnamed Prop binder is an
  unregistered second hypothesis). Plant P11: a decoy of the REAL registered
  obligation `CerbMem.sizeofCtype_measure_sufficient` with an extra Prop binder
  `(extra : cty ≠ cty)` before `lemHyp : CerbTagsWf.Acyclic ambient` (the
  register's exact text), compiled with the real `CerbMem_lemMeasureProofs`
  excluded from the tool's imports (`FUELFORMS_EXCLUDE_MODULES`, selftest
  only) — without the check it would be MEASURED and register-matched;
  verbatim:

```
    plant table: FUEL_FORM	CerbMem.sizeofCtype_lemFuel	AMBIENT	yes/-	MALFORMED obligation=CerbMem.sizeofCtype_measure_sufficient: binder `extra` (#2) is neither reserved (`lemHyp`/`lemFuel`/the `≤ lemFuel` hypothesis) nor an argument of the wrapper side	
  PLANT OK   [P11 decoy of a REAL obligation with an EXTRA Prop binder and the register's exact hypothesis (CerbMem.sizeofCtype): MALFORMED by the binder check] -> check_fuel_forms: FAIL — obligation(s) named <f>_measure_sufficient whose TYPE is not the contract's shape (∀ …, μ ≤ lemFuel → worker lemFuel … = wrapper …) — never MEASURED:
  PLANT OK   [P11 premise] -> the tool reports CerbMem.sizeofCtype_lemFuel MALFORMED: binder `extra` is neither reserved nor a wrapper argument
```

- **F-A5** — the dead `[LemFuel]` on `memValueToBytes_stable_aux`/
  `_measure_sufficient` dropped (rebuild; the obligation's shape unchanged).
- **F-A6 / F-A8** — TODO rows: the cheaper sufficient measure (`if refsOf ty
  = [] then lemSize ty + 1 else envBound …`, proof: `refsOf ty = [] → tp ty =
  0`) for the C3 timing slice; the multi-JSON `--fuel` argument-order refusal
  (`cerberus-lean --batch --fuel N a.json b.json` → `unknown flag`).

Gates on the audit-response head (`.tmp/c4ar-*.log`, each rc checked), verbatim:

```
lib build rc=0
check_driver_fresh rc=0
selftest rc=0
test_unit rc=0
exec_minimal rc=0
verify rc=0
immaculate rc=0
check_driver_fresh: oracle OK (bin f6a52b7ed9927b9ed36383a4295116999146c0191a23d09c842ec9700b922665, src 46d26f1f7ede22ffb6d3ff563194b8423a297775cef211805388c6c88217efda)
check_driver_fresh: lean OK (bin 32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6, src 89a31871cc2e83121d7efb009c35aa6c50216b31f6dad88cee4688b0786edf28)
Total: 6 passed, 0 failed
check_driver_fresh: lean OK (bin 32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6, src 89a31871cc2e83121d7efb009c35aa6c50216b31f6dad88cee4688b0786edf28)
check_driver_fresh: oracle OK (bin f6a52b7ed9927b9ed36383a4295116999146c0191a23d09c842ec9700b922665, src 46d26f1f7ede22ffb6d3ff563194b8423a297775cef211805388c6c88217efda)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING, 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (12 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 4 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register and the extra-binder decoy caught by the shape check; unplanted table green)
check_handwritten_sync: OK (37 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_lakefile_roots: OK (206 roots = 206 generated modules + the exe root Main; 85 auxiliary modules all built)
check_sorry_token: OK (286 files scanned comment-stripped — generated 207, hand-written+test 44, LemLib 35; 0 sorry tokens)
check_theorem_axioms: C2 ratchet OK (326 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
gen_fuel_parametricity: OK (22 ambient fuel wrappers in the generated tree = the 22 pins of TotalityProofTest.lean Part 1, both directions)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

(Note: the ORACLE binary in this worktree was relinked at 17:37:44 by a process outside this slice — after the §6.2 battery's last lane; `bin` now `c54c1dee…`, `src 46d26f1f…` UNCHANGED, so it is a product of the same sources; the Lean binary was rebuilt here after the F-A5 change. The `.tmp/c4ar-*` logs are ephemeral, deleted at the end of this response.)

## 10. Not done, and why

- Rows 7–9 (the `ctype_aux` trio): PENDING by finding F-C4-1 (the obstacle is
  not a proof difficulty but a false obligation under any frontend-guaranteed
  hypothesis; reproduced by the audit, §9). Rows 10–12 (`hack`, `many`, `many1`) and `to_pure`/`to_pures`:
  not this mechanism's customers (lem record §6.3, C2 D-C2-3/4/5). So 13 − 3
  − 3 = 7 rows measured, 8 pending (the register's count).
- The frontend guarantee PROOF (a theorem about the desugaring's output) — out
  of size; documented with cites (§2.3). The decidable instrument — optional per
  the brief, registered.
- The A/B timing of the measures' cost (F-C4-4) — registered with C3's item.
- The dead-binder cascade (TODO.md C4 block) — its own slice.
- refined-cerberus untouched (the manifest is theirs); lem-lean untouched (no
  lem change was needed; the `Pmap.find?`→bindings lemma the lem rows would
  have needed was not written).

## 11. Worktree state at close

Branch `arc/fuel-parameter-C4`; `lean_frontend/generated/` and
`ocaml_frontend/generated/` are the REAL trees (lem-sync stamped, §4); both
driver binaries fresh (`check_driver_fresh --check`); `.tmp/c4/` (the
snapshots, lane logs, drafts) is ephemeral and deleted at slice end;
everything load-bearing is quoted here.


## 10. Orchestrator boundary review [AGENT, orchestrator, 2026-09-05]

Independent full battery on `ab342fc6a` (the slice head) in this worktree:
26 lanes serially, every one rc 0, zero baseline movement (`SUMMARY:
total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 …` /
`Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle
lane OK`). Pre-merge audit + register review
`2026-09-05_fuel-parameter-C4-audit-premerge.md`: MERGEABLE; all seven
hypothesis-register rows SIGNED by the fresh reviewer with cite
corrections (applied in `49e98d9cf`, §9a, together with the F-A4 shape
hardening, F-A5, and the F-A2/F-A7 record errata). Second independent run
on `49e98d9cf` + the audit document cherry-picked: rebuild (lean stamp
`bin 32f8b3427f02…`), `check_driver_fresh` OK, then `test_unit.sh`
(incl. the 12-plant fuel-forms selftest), exec minimal
`--check-baseline`, `test_verify.sh`, `test_immaculate.sh`, speclab
selftest + plant + the five gates, `test_fuel_plant.sh` — 13 lanes, 13 ×
rc 0. Merge ask goes to the operator on this head; per the register's
header, the operator's explicit merge "yes" is the register's FINAL
signature. Upstream findings owed to the tray (Z4 code half): F-A2
(`_Alignas(struct A)` on a character member accepted; both oracles
hang), F-C4-1 (`are_compatible` non-termination on a two-TU
self-referential struct; both oracles time out).
