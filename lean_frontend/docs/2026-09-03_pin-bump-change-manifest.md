# Pin bump 3c88f0d — consumer change manifest (for refined-cerberus)

Date: 2026-09-03. Branch `arc/pin-bump` (off mainline `f95ef8d9c`).
Record: `docs/2026-09-03_pin-bump-record.md`. Lem-side record (the
authority on WHY each change exists): lem-lean
`doc/lean-backend/2026-09-03_parity-fix-record.md` (§1 per-finding,
§5 consumer impact, §6 audit response). Worker: [AGENT]; every name
below is in the tree at the commit this manifest ships in, every line
cite is against LemLib at `3c88f0d` (`lean-lib/LemLib.lean` unless
stated), and every count is a derived grep tally over
`lean_frontend/generated/` unless quoted.

This manifest is what the re-pin carries: the lem-lean parity-fix
mainline, i.e. LemLib's exec-cone-visible surface moved from
`045dcb0` to `3c88f0d`. The `.lem` model did NOT change (the OCaml
generated tree is byte-identical, record §2); everything here is the
Lean rendering of the same model.

## 0. The pin

| Where | Before | After |
|---|---|---|
| `lean_frontend/lakefile.toml` `[[require]] LemLib` `rev` | `045dcb0d57a171eb4fb3a6eb5abe288c227270ce` | `3c88f0d7e5556491d733932c503c1637ae186f54` |
| `lean_frontend/lake-manifest.json` LemLib `rev`/`inputRev` | `045dcb0d…` | `3c88f0d7…` |
| `lean_frontend/speclab/lake-manifest.json` LemLib `rev`/`inputRev` | `045dcb0d…` | `3c88f0d7…` |
| `tests/mem-scale-probes/micro/lake-manifest.json` LemLib `rev`/`inputRev` | `045dcb0d…` | `3c88f0d7…` |
| opam `lem` (local switch, pin `deps/lem-pinned#cerberus-pin`) `source-hash` | `045dcb0d…` | `3c88f0d7…` (`lem -v` → `Lem 3c88f0d`) |

lem-lean `mdd/lean-backend` head = `deps/lem-pinned` HEAD = opam
source-hash = all three Lake pins = `3c88f0d7e5556491d733932c503c1637ae186f54`.

## 1. Types that changed shape (consumer-visible)

| Name | Before (`045dcb0`) | After (`3c88f0d`) | Where |
|---|---|---|---|
| `Pset α` (lem `set 'a`) | `List α` (sorted list; `set 'a` rendered as `List`) | `inductive Pset (α : Type) \| Empty \| Node …` — the verbatim port of ocaml-lib/pset.ml (AVL); iteration ascending under the set's comparator | `LemLib.lean:328` |
| `Pmap α β` | (none — `Fmap` was `Std.TreeMap`-backed) | `inductive Pmap (α β : Type) \| Empty \| Node …` — verbatim port of ocaml-lib/pmap.ml | `LemLib.lean:755` |
| `Fmap α β` (lem `map 'k 'v`) | `Std.TreeMap`-backed structure (`fmapOfSpine` builder) | `inductive Fmap (α β : Type) \| empty \| mk (cmp : α → α → LemOrdering) (m : Pmap α β)` — the comparator is CAPTURED at first insert (pmap.ml `{cmp; m}`) | `LemLib.lean:1052` |
| `fmapElements m` | spine order of the old rep | `Pmap.bindings m.rep` — ascending under the captured comparator | `LemLib.lean:1089` |
| `BEq (Pset α)` / `Ord (Pset α)`, `BEq (Fmap α β)` / `Ord (Fmap α β)` | list instances | structural on the ascending element/binding spines (see the LemLib census note X1: OCaml's polymorphic compare RAISES on Pset/Pmap records) | `LemLib.lean` after `:728` / after `:1096` |

Generated modules whose text now carries `Pset`: `Cmm_aux Cmm_csem
Cmm_op Core_linking Core_run Core_run_aux Defacto_memory Driver Utils`
(derived grep). Every generated `set` operation renders as the
comparator-keyed LemLib primitive on `Pset` (`setFromListBy`,
`setToList`, `setAddBy`, `setMemberBy`, `setFilterBy`, `setFold`,
`setChoose`, … `LemLib.lean:690-725`); the list-backed
`Lem_Set.filter` is gone (commented out, `LemLib/Set.lean:116`) — use
`setFilterBy cmp p s`.

Removed LemLib names (cerberus references at the bump: `fmapOfSpine`
only — Main.lean, replaced, §4): `fmapOfSpine`, `fromNat32`,
`fromNat64`, `toNat32`, `toNat64`, `lemCmpToOrd`, `LemInt32`,
`LemInt64`, `lemInt32Abs`, `lemInt64Abs`, `lemInt32ToNat`, `set_tc`,
`set_tc_go`, `sortedCompareBy`, the `Std.TreeMap` Fmap internals.
LemLib no longer imports `Std.Data.TreeMap`: a consumer that used
`Std.TreeMap` through LemLib's transitive import must import it
itself (`CerbMem.lean` does so now, §4).

## 2. Derived instance shapes (parity-fix F4)

55 generated variant types moved from `deriving BEq, Ord` (declaration-
index rank) to the backend's derived pair `T.beq_derived` /
`T.compare_derived` with `T.ctor_rank_ocaml : T → Nat` (OCaml polymorphic-
compare rank: nullary constructors below block constructors, declaration
order within each class), wired as `instance : BEq T` / `instance : Ord T`
and the `SetType` comparator (`match T.compare_derived x y with | .lt =>
LemOrdering.LT | …`). Count derived: 55 `-  deriving BEq, Ord` lines in
the generated-tree diff, 0 added; `ctor_rank_ocaml` definitions 35 → 90.
The newly ranked types (derived, `comm` of the two `def T.ctor_rank_ocaml`
sets):

`ail_builtin annot binaryOperator cerb_attribute cn_base_type cn_const
cn_error cn_to_extract cn_to_instantiate cn_var_kind constant
core_base_type core_linking_cause core_parser_cause core_run_cause
core_tau_step_kind core_typing_cause cparser_cause ctor desugar_cause
desug_init_error expr_ctx field_width generic_memop generic_selection
genIntegerType genType identifier_kind illegal_initialisation inferred
init_element integerBaseType integerType integer_type_match label_annot
mem_cheri_error mem_error misc_violation namespace0 ordinary_kind
precision prefix0 program_behaviours program_behaviours_fp pure_memop
registration rf_program_behaviours step_kind symbol_description
typing_misc_error undefined_behaviour undefinedness value violation
vip_error`

Consumer consequence: `Ord.compare` on any of these (and on every
`Pset`/`Fmap` keyed by them) now orders as OCaml's `compare` does;
`Set.choose`/`fmapElements`/`topo_order`-style observables move toward
the oracle. Proof terms that unfolded `deriving Ord`'s `Ord.compare`
on these types must unfold `T.compare_derived` instead.

## 3. Library functions renamed at their use sites (parity-fix F7, F1/D1, N4)

Tail-recursive deep-list rewrites (each with a kernel-checked equation
to the definition it replaces in `lean-lib/LemLibTheorems.lean`,
namespace `LemLibTheorems`):

| Generated call | Was | Sites (derived) | Equation |
|---|---|---|---|
| `lemListFoldr f init l` (`LemLib.lean:1593`, `l.toArray.foldr f init`) | `List.foldr f init l` | 71 across 20 modules (Core_aux 12, Cmm_op 10, Cabs_to_ail 8, Core_typing 6, Core_rewrite 6, …) | `lemListFoldr_eq` |
| `lemListZip` (`:1584`) | `List.zip` | 58 (Translation 19, Core_typing 11, Core_aux 8, …) | `lemListZip_eq` |
| `lemListUnzip` (`:1590`) | `List.unzip` | 6 | `lemListUnzip_eq` |
| `lemListUpdate` (`:1606`) | lem `List.update` | 3 (Defacto_memory) | `lemListUpdate_eq` |
| `lemListMapi` (`:1620`) | lem `List.mapi` | 3 (Translation) | `lemListMapi_eq` |
| `lemListDeleteFirst` (`:1600`) | lem `List.deleteFirst` | 1 | `lemListDeleteFirst_eq` |
| `lemStringConcat` (`:1663`) | lem `String.concat` | 5 (Cabs_to_ail) | `lemStringConcat_eq` |

NOTE for proofs: `lemListFoldr` does NOT reduce by `dsimp`/`rfl` on a
literal list the way `List.foldr` did (it is an `Array.foldr`); rewrite
through `LemLibTheorems.lemListFoldr_eq` first. This bit this repo's
own `test/Unit/FuelExemplar.lean` (§4).

Numeric renderings (`LemLib.lean:1318-1322`, `:1500-1510`):

| Generated call | Was | Sites | Behaviour change |
|---|---|---|---|
| `lemIntegerDiv a b` | `a / b` (Lean `Int.div`, `x / 0 = 0`) | 7 (Defacto_memory_aux; every divisor is the literal `2`) | PANICS (`lemDivByZero`, `failwithI`) on a zero divisor where the OCaml raises `Division_by_zero` — unreachable at these sites |
| `lemNatDiv` / `lemNatMod` | `/` / `%` on `Nat` | 1 each (Formatted.lean:435, `showNonNegativeNumber`'s base) | same; the base is never 0 there |
| `lemIntFromInteger i` | identity `( n)` | 21 across 10 modules (Cabs_to_ail 3, Defacto_memory 3, Translation 3, Driver 2, …) | `failwithI "Failure \"int_of_big_int\" …"` outside the OCaml 63-bit `int` range, where the reference raises the same `Failure` |
| `lemNatFromNatural` | identity | 1 (Enum.lean:58 `fromEnum`) | same 63-bit check |

`int32`/`int64` render as `Int32`/`Int64` — NOT used by cerberus (0 sites).

## 4. Hand-written seams changed in this bump (the diff of the commit)

| File | Change | Why |
|---|---|---|
| `lean_frontend/Main.lean` (`libcMapFromAssoc`, 4 call sites in `loadLibc`'s assembly) | `fmapOfSpine cmp l` → `libcMapFromAssoc cmp l := l.foldl (fun acc (k, v) => fmapAddBy cmp k v acc) fmapEmpty` | `fmapOfSpine` removed; the new helper mirrors the OCaml `map_from_assoc` (backend/common/pipeline.ml:653-654, `List.fold_left … Pmap.add … (Pmap.empty compare)`), left fold / last key wins; the four lists are duplicate-free by construction so the fold direction is unobservable |
| `lean_frontend/CerbCall.lean:77` (`funSymsNamed`) | `Lem_Set.filter p dom` → `setFilterBy (fun s1 s2 => ordCompare s1 s2) p dom` | `Lem_Set.filter` gone; comparator-keyed pset.ml `filter`; the domain is a `Pset sym` |
| `lean_frontend/CerbFunMapInstances.lean` (header comment + one arm comment) | "THE REQUIREMENT IS PHANTOM" paragraph rewritten | `Lem_Map_extra.fold` (LemLib/Map_extra.lean:36) is now `setFold … (fmapToSetBy (pairCompare setElemCompare setElemCompare) m)`: the value comparator IS passed and is reached only when two bindings' keys compare EQ under `SetType sym` (= `symbol_compare`, the map's own comparator) — never, for a map's bindings. Instance body unchanged |
| `lean_frontend/CerbUtils.lean` | `set_fold` (List-typed, "Lem sets are sorted lists") DELETED | dead: no generated module referenced it; premise false. Residue: `frontend/model/core_linking.lem:61-63` still declares the unused `val set_fold` with `declare lean target_rep function set_fold = \`CerbUtils.set_fold\`` — a dangling declare for an unused val (lem emits nothing for it; any future use fails loudly at Lean build). Not touched here: editing the `.lem` is outside this slice's byte-identity contract (record §7) |
| `lean_frontend/CerbMem.lean:9` | `import Std.Data.TreeMap` added | `MemState.allocations`/`.bytemap` are `Std.TreeMap` (arc-6 S3); the import was transitive through LemLib until this bump |
| `lean_frontend/test/Unit/FuelExemplar.lean` | `import LemLibTheorems`; in `driver2_done`: `dsimp only [List.map]; rw [LemLibTheorems.lemListFoldr_eq]; dsimp only [List.foldr]` replaces `dsimp only [List.map, List.foldr]` | the generated `nd_mapM` folds with `lemListFoldr` (§3) |
| `lean_frontend/lakefile.toml`, the three `lake-manifest.json` | the pin (§0) | — |

No semantics change beyond what the new lem forces; no `.lem` change;
no baseline moved (record §5).

## 5. Things that did NOT change (checked)

- Generated ROOT definition names: none newly renamed (F8's extended
  reserved list hits only the hand-written `main`); the 13 root defs and
  17 constructors renamed at `bc1bae7` (`attribute0 … throw0`; `Add0 …
  One0`) are unchanged. The `Default` class field `Utils.default0` is
  UNCHANGED (the lem record §5 predicted it would revert to `default`;
  it did not — observation, no cerberus impact).
- One local binder rename only: `Core.pcreate_readonly`'s parameter
  `init1` → `init` (the reserved-list scope change; cosmetic).
- Generation-time refusals (`LemUnsupported.*`): 0 markers in the
  generated tree.
- The OCaml generated tree (`ocaml_frontend/generated`, `sibylfs/generated`):
  byte-identical (record §2).
- Every differential baseline in the repo: unmoved (record §5) — in
  particular the libxml2-uri diagnostic row that embeds a Lean symbol id
  (C1-F2, `Symbol(968, SD_Id("memset"))`) did NOT renumber under F6.
