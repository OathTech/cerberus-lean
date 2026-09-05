# Fuel-parameter arc, cerberus half — slice C4 PRE-MERGE AUDIT + hypothesis-register REVIEW (2026-09-05)

Auditor/reviewer [AGENT audit/c4-premerge 2026-09-05], fresh eyes (no part in
the slice). Range `31eba718e..ab342fc6a` on `arc/fuel-parameter-C4` (3 commits:
`be1cebe36` pin bump; `e38d72c83` code + gate + register; `ab342fc6a` docs).
Read in the slice worktree `worktrees/cerberus-lean-arc/zero-discrepancy`
(its stamped binaries; nothing edited there); written only on this branch.
Lanes run AFTER the orchestrator's battery reached `=== DONE`
(`.tmp/c4-reverify.log`), serially, as briefed; probes run on the slice
worktree's binaries and `deps/cerberus-upstream`'s, each under `timeout 60`,
`ulimit -c 0`. Quoted outputs are verbatim (log `.tmp/lanes.log` and the
probe transcripts, ephemeral, deleted at close — everything load-bearing is
quoted here); tallies marked derived are derived. FINDINGS ARE CLAIMS: each
names the file:line it rests on and, for behavioural claims, the
reproduction.

## 0. Verdict

**MERGEABLE (ff-only). The seven register rows are SIGNED (§3), three of
them conditional on a one-line correction of the invariant text/cites they
carry (F-A1, F-A2, F-A3 — the guarantee is real, the cited line is not
where it comes from). No MAJOR finding.** The `.lem` diff is one Lean-only
declare; the OCaml tree is byte-identical (re-verified against the primary);
every obligation has the contract's shape with `lemHyp`, is stated for all
inputs and its cone is within the trio (re-run, §8); the CerbMem refactor
is a delta-unfolding; the gate goes red on all 11 plants and reproduces the
record's line; the three lanes hold. One NEW frontend gap on the way (F-A2:
a `_Alignas(type)` on a character-typed member is never completeness-checked,
the frontend accepts an ISO constraint violation on which BOTH oracles hang
— upstream-tray candidate alongside F-C4-1; the Lean side exhausts loudly
there, exactly as the record predicts for a hypothesis-violating table).
F-C4-1 reproduced on both oracles; the Lean pipeline at the default fuel
dies by NATIVE STACK OVERFLOW, not by the fuel sentinel (F-A7 — a record
erratum, not a fail-open).

| # | Grade | Finding (one line) |
|---|---|---|
| F-A1 | MINOR | Register row 7's `formatted.lem:563,571,579,587,595` are stale by exactly the 10-line comment block the same commit inserted above them; the callers are at `:573,581,589,597,605`. The gate's `.lem:[0-9]` check cannot see a wrong number. |
| F-A2 | MINOR (register/header text) + upstream-tray candidate (frontend) | `_Alignas(type)` on a CHARACTER-typed member bypasses the `alignof_ty` completeness check the register/`CerbTagsWf` cite (`cabs_to_ail.lem:2860-2870`): `ailTypesAux.lem:1291-1292` returns `Just LT` for any character `decl_ty`, and the `Just LT` arm (`cabs_to_ail.lem:2882-2883`) stores `AlignType al_ty` unexamined; no later pass checks it. `struct A { _Alignas(struct A) char c; }` (ISO §6.5.3.4#1 CV; gcc rejects) is accepted, is a by-value self-edge via `alignTypes`, `Acyclic` is FALSE for it, and BOTH oracles hang while the Lean wrapper exhausts loudly (§5.2). |
| F-A3 | NOTE (cite correction) | The FAM element-type guarantee does not come from `cabs_to_ail.lem:1600-1603` (those lines register `FlexibleArrayMember … elem_ty` without looking at `elem_ty`, `:1589-1598`); it comes from the Ail passes: `ailWf.lem:76-80` (`ArrayDeclarationIncompleteType`: `is_complete sigm elem_ty`; `StructMemberFlexibleArrayInArray`) and `genTyping.lem:2346-2349` (`StructMemberFlexibleArray`) — every by-value edge INTO a FAM struct is a CV, so the FAM edge cannot close a cycle. Confirmed by probes (§5.3: the self case and two back-edge variants are refused; the acyclic forward-declared variant runs). |
| F-A4 | MINOR (gate hardening) | `obligationShape` pins `lemHyp`/`lemFuel`/`≤ lemFuel` but does not require the REMAINING binders to occur as arguments of the wrapper side: a hand-written obligation with an extra unnamed Prop binder before `lemHyp` would be MEASURED with a register-matching `hyp`. No instance (the seven statements carry exactly the wrapper's arguments + the three reserved binders, §4). Closure: every other binder must be a `bvar` argument of the RHS wrapper application; plant it. |
| F-A5 | NOTE | `memValueToBytes_measure_sufficient`/`_stable_aux` (`CerbMem_lemMeasureProofs.lean:93,130`) still carry a dead `[LemFuel]` instance binder though the wrapper lost it — inhabited class, not a hypothesis; belongs to the dead-binder cascade item. |
| F-A6 | NOTE | F-C4-4 (`envBound` traverses the environment per layout call): not measurable here; mechanism assessed §7 with the cheaper sufficient measure spelled out. The operator's <10 % bar is UNVERIFIED by this audit. |
| F-A7 | MINOR (record erratum) | F-C4-1 reproduced: fork AND upstream oracle `rc=124` at 60 s on the two-TU `struct node` (§5.1). The Lean pipeline at the default fuel does NOT loop and does NOT reach the fuel sentinel: `Stack overflow detected. Aborting.` `rc=134` in 3 s — the record's "exhausts any fuel here" (§0, §7, `fuel_forms_pending.txt`) is wrong at the default fuel: `are_compatible_aux` is not tail-recursive and the 8 MB native stack is exhausted at a depth far below 10^8. Loud (a crash-class death), not fail-open; but not the FUEL class either — the fuel is not the operative bound for deep non-tail recursion. |
| F-A8 | NOTE | `cerberus-lean --batch --fuel N a.json b.json` (two JSON inputs) is refused as `unknown flag`, while the single-input form is accepted; the message names `--fuel <N>` as accepted. Either the multi-TU form should take `--fuel` or the refusal should say why (`Main.lean:1258` parses `--fuel` in the single-input path). Blocked the fuel-pinning of F-A7's overflow. |

## 1. Scope items 1 and 4 — the `.lem` diff, the OCaml tree, the CerbMem refactor

- `git diff 31eba718e ab342fc6a -- '*.lem'`: ONE file, `frontend/model/formatted.lem`,
  +10 lines: a comment block and
  ``declare {lean} fuel_measure val showNonNegativeWithBasis_aux = `n + 1` assuming `2 ≤ b` ``.
  No `.lem` body change anywhere. The pin: `lakefile.toml` `rev` + the three
  `lake-manifest.json` `d4ba548…` → `f6542f8e6860d12d4655e6648bc4c45dabd1d798`;
  the lakefile also adds the roots `CerbTagsWf`, `Formatted_lemMeasureProofs`.
- OCaml tree re-verified against the primary checkout (`cerberus-lean/`, parked
  on `31eba718e`), verbatim:
  ```
  diff -rq cerberus-lean/ocaml_frontend/generated worktrees/cerberus-lean-arc/zero-discrepancy/ocaml_frontend/generated
  rc=0 files=86
  primary ocaml_frontend/lem_sync.sha256: src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8 gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100
  slice   ocaml_frontend/lem_sync.sha256: src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0 gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100
  ```
  `gen` identical; `src` moved with the `.lem` text — the record's `rc=0 lines=0 files=86` holds.
- CerbMem refactor (`lean_frontend/CerbMem.lean` diff, read in full):
  `CerbTagsWf.lookupEntry m tag := (fmapElements m).find? (fun (s, _) => symbolEquality s tag)`
  is a plain `def` over the former text; the six sites (`offsetsof` struct in
  `tagDefs`; `sizeofCtype`/`alignofCtype` union in `ambient`; `alignofCtype`
  struct in `tagDefs`; the two `reconstructValue` union lookups in `ambient`)
  replace the text by the call with the SAME map and symbol — a
  delta-unfolding, definitionally equal. `mkCtype` loses `private` only. The
  six wrappers drop `[LemFuel]` and pass the measure; the worker bodies are
  otherwise untouched (fuel decrement, arms, OCaml cites). Mirror doctrine:
  the OCaml has no counterpart (Pmap.find); `CerbTagsWf`'s "MIRROR-OCAML NOTE"
  and CerbMem's header say so. Behaviour-identical; the lanes (§8) agree.

## 2. The frontend cites, as read

- `cabs_to_ail.lem:1512-1521 check_members`: function type → CV
  `StructMemberFunctionType`; `E.is_incomplete ty` → CV
  `StructMemberIncompleteType`. Called (`:1575`, `:1583`) BEFORE
  `E.register_tag_definition` (`:1620`): the tag under definition is not in
  `tag_definitions` while its members are checked → a by-value self-reference
  is incomplete → refused.
- `ail/ailTypesAux.lem:222-270 is_complete`: `Void` false; `Basic` true;
  `Array elem n` iff `is_complete elem && isJust n`; `Pointer` TRUE regardless
  of target; `Atomic` iff inner; `Struct sym`/`Union sym` iff `List.lookup sym
  sigm.tag_definitions` is `Just`. Exactly `refsOf`'s edge set (by value
  through `Array0`/`Atomic`, never `Pointer`/function).
- `:1589-1598` the last member: `is_incomplete lastMemb_ty` → STRUCT +
  `Array elem_ty Nothing` + >1 member → `FlexibleArrayMember … elem_ty`
  registered WITHOUT checking `elem_ty` here; the guarantee for that edge is
  the Ail passes (F-A3): `ailWf.lem:76-80` (`ArrayDeclarationIncompleteType`
  guards `is_complete sigm elem_ty` for every array type;
  `StructMemberFlexibleArrayInArray` refuses an array whose element has a
  FAM) and `genTyping.lem:2346-2349 check_member` (`StructMemberFlexibleArray`
  refuses a struct member whose type has a FAM, `has_flexible_array_member`
  recursing through unions `ailTypesAux.lem:172-189`).
- `:2791-2890 desugar_alignment_specifiers` (member path `:2716`), `AlignType
  al_ty`: `agnostic_alignment_requirement_ord decl_ty al_ty`
  (`ailTypesAux.lem:1289-1325`: `ty1 = ty2` → EQ; `is_character ty1` → LT;
  `is_character ty2` → GT; integer pairs; pointer pairs; through arrays; else
  Nothing). `Nothing` → non-agnostic `(alignof_ty decl_ty, alignof_ty al_ty)`
  both `Just` or `E.fail` "(7)"; `alignof_ty = Implementation.alignof_ty
  pseudo_tagDefs` over the CURRENT `tag_definitions`
  (`cabs_to_ail_effect.lem:2187-2204`; Lean `CerberusImpl.alignof_ty` `none`
  on an unknown tag) — LOUD on an incomplete `al_ty`, as the register says.
  But `Just EQ` → `E.return Nothing` and `Just LT` → `E.return (Just al)`
  (`:2882-2883`) never call `alignof_ty`: a character-typed member stores
  `AlignType al_ty` for ANY `al_ty` (F-A2). No Ail pass checks `_Alignas`
  types (the probe §5.2 is the evidence: both oracles hang).

## 3. THE REGISTER REVIEW (scope item 2) — row by row

Method: (a) the `hyp=` text as the tool prints it = the register row,
reproduced by the gate (§6); (b) is the hypothesis exactly what the frontend
guarantees for environments produced by desugar/typing (§2)? (c) is it
SUFFICIENT — does the recursion enter tags ONLY along `refsOfDef` edges? —
read on both the Lean workers (`CerbMem.lean:358-533`) and the OCaml twins
(`impl_mem.ml:98-273`), and witnessed by the obligations compiling (they ARE
the sufficiency theorems).

Sufficiency, read: `sizeof` — `Array (Some n)` → elem; `Atomic` → inner;
`Pointer` → `sizeof_pointer`, NO pointee (`:153-158`; Lean `targetPtrSize`);
`Struct` → `offsetsof ~ignore_flexible:true tagDefs` + `alignof ~tagDefs`
(threaded, `:168-169`); `Union` → `Pmap.find … (Tags.tagDefs ())` (AMBIENT,
`:173`), per member `sizeof`/`alignof ty`/`alignof al_ty` (`:176-187`).
`alignof` — `Array` → elem (any size); `Pointer` no pointee (`:219-225`);
`Struct` threaded (`:229`), init `alignof (Array (elem_ty, None))` for the
FAM (`:234-239`), per member `alignof ty`/`alignof al_ty` (`:242-251`);
`Union` ambient (`:255`), likewise. `offsetsof tagDefs` — `Pmap.find tag_sym
tagDefs` (`:100`), FAM appended as `(ident, (attrs, None, qs, ty))` with the
stored ELEMENT type (`:107-108`), per member `sizeof ~tagDefs ty`, `alignof
~tagDefs ty`/`al_ty` (`:112-122`); union arm: no recursion (`:128-129`).
Every type the recursion enters from an entry is in `memberTypes` (member
`ty`, `alignTypes al`, FAM `elemTy`); every tag it looks up from a type is
in `refsOf`; function arms are `assert false`/`panic`. The Lean workers
mirror arm by arm. `reconstructValue`'s struct arm takes member types from
`offsetsof … (ignoreFlexible := true)` (`CerbMem.lean:1096`), its union arm
from the definition (`:1111-1128`): ⊆ `memberTypes`. The struct/union map
split is exactly the oracle's (`AcyclicPair`: `lookS` = threaded for struct
tags, `lookU` = ambient for union tags); `Ranked`'s disjunction is a superset
that collapses to the one-map condition when the maps coincide (run time)
and to `Acyclic tagDefs` when the ambient is empty (elaboration:
`Translation.lean:509` passes `_lemReader_tagDefs` as the ambient and the
TU's map as `tagDefs`). Ranks on ENTRIES: if `A`'s entry = `B`'s and `A`
references `B` by value then `B` references `B` by value — refused; nothing
lost.

The guarantee (§2): at registration every by-value tag reference of a
definition's MEMBER TYPES resolves to an earlier registration
(`check_members`/`is_complete`, tag inserted after the check); the FAM
element edge cannot close a cycle (F-A3's Ail checks); the `_Alignas(type)`
edge is checked on the non-agnostic path and NOT on the character-member
path (F-A2). So `Acyclic` is exactly the invariant for every program the
frontend accepts EXCEPT the F-A2 class, which is a constraint violation the
frontend fails to diagnose and on which the ORACLE HAS NO BEHAVIOUR (it
hangs, §5.2). A consumer theorem carrying `Acyclic` is therefore never a
false-in-practice premise about a program the oracle terminates on — not
the brief's MAJOR class ("stronger than what the frontend guarantees") in
substance; it IS a misstatement of the invariant column and of
`CerbTagsWf`'s header, corrected below. Per-TU digests in symbols make the
rank lift to the linked table.

| Row | Worker | Hypothesis (`hyp=` text) | Verdict | Reason / required text change |
|---|---|---|---|---|
| 1 | `CerbMem.sizeofCtype_lemFuel` | `CerbTagsWf.Acyclic ambient` | **SIGNED** | Sufficient (struct → `offsetsof`/`alignof` on threaded = ambient; union → ambient; pointers never); guaranteed by `check_members`/`is_complete` for member types. Invariant text: append "except the `_Alignas(type)`-on-a-character-member class (audit F-A2: ISO §6.5.3.4#1 CV undiagnosed; the oracle hangs there)". |
| 2 | `CerbMem.alignofCtype_lemFuel` | `CerbTagsWf.Acyclic ambient` | **SIGNED** (cite correction) | Sufficient (`Array` any size → elem; FAM init `Array0 elemTy none` → `elemTy` ∈ `memberTypes`). Replace the row's "flexible member cabs_to_ail.lem:1600-1603" by "FAM element: ailWf.lem:76-80 (`ArrayDeclarationIncompleteType`, `StructMemberFlexibleArrayInArray`) + genTyping.lem:2346-2349 (`StructMemberFlexibleArray`)" (F-A3). Plus row 1's addendum. |
| 3 | `CerbMem.memberAlign_lemFuel` | `CerbTagsWf.Acyclic ambient` | **SIGNED** (cite correction) | Sufficient (`AlignType al_ty` → `alignof al_ty`, `al_ty` ∈ `alignTypes`). Replace "_Alignas(type) complete at desugaring cabs_to_ail.lem:2860-2870" by "_Alignas(type): completeness-checked by `alignof_ty` on the non-agnostic path (cabs_to_ail.lem:2851-2871) — NOT on the character-member `Just LT` path (:2882-2883, ailTypesAux.lem:1291-1292; audit F-A2): guaranteed by ISO §6.5.3.4#1 on conforming inputs". |
| 4 | `CerbMem.offsetsof_lemFuel` | `CerbTagsWf.AcyclicPair ambient tagDefs` | **SIGNED** | The two-map form is the oracle's split exactly (`impl_mem.ml:100/229` threaded for struct tags; `:173/255` `Tags.tagDefs ()` for union tags); one rank over both is what a cross-map cycle needs (record F-C4-2 correct; `Acyclic ∧ Acyclic` would not do). `offsetsof`'s union arm does not recurse. Row 1's addendum. |
| 5 | `CerbMem.offsetsofMembers_lemFuel` | `CerbTagsWf.Acyclic ambient` | **SIGNED** | Per member `sizeof ty` + `memberAlign al ty`, both covered by rows 1/3. Row 1's addendum. |
| 6 | `CerbMem.reconstructValue_lemFuel` | `CerbTagsWf.Acyclic ambient` | **SIGNED** | Struct arm's member types from `offsetsof … ignoreFlexible := true`; union arm's from the definition (first / recorded / panic default); arrays → elem; pointers → no pointee. Row 1's addendum. |
| 7 | `showNonNegativeWithBasis_aux_lemFuel` | `2 ≤ b` | **SIGNED** (cite correction, F-A1) | Sufficient: `n / b < n` for `n > 0`, `b ≥ 2` (`Nat.div_lt_self`); `b = 1` loops in both. The only callers in the whole `.lem` tree (`grep -rn showNonNegativeWithBasis --include='*.lem'`): `formatted.lem:573` (`10`, `%d/%i`), `:581` (`8`, `%o`), `:589` (`10`, `%u`), `:597` (`16`, `%x`), `:605` (`16`, `%X`) — each a LITERAL; `showNonNegativeWithBasis` (`:338-343`) is `_aux`'s only caller and passes `b` through; no Lean seam calls either (only the proof module names them). No computed base. Cites → `:573,581,589,597,605`. |

Proposed reviewer field for all seven rows (replacing "operator review
pending"): `[AGENT audit/c4-premerge 2026-09-05] SIGNED per
docs/2026-09-05_fuel-parameter-C4-audit-premerge.md §3 (text corrections
applied); operator countersign pending`. The gate reads only "non-blank" in
that field and `.lem:[0-9]` in the invariant field, so the corrections are
gate-neutral. The lem-lean record §10's consumer-side REQUIREMENT ((i) `hyp=`
by the reserved binder; (ii) named, cited, reviewed register) is met with
this review.

## 4. Scope item 3 — the obligations

Statements (`CerbMem_lemMeasureProofs.lean:799-1029`,
`Formatted_lemMeasureProofs.lean:80-83`): each `theorem <f>_measure_sufficient
(<the wrapper's arguments>) (lemHyp : H) (lemFuel : Nat) (lemMeasureLe : μ ≤
lemFuel) : f_lemFuel lemFuel <args> = f <args>` with `μ` the wrapper's actual
fuel argument — the contract shape with the reserved binder, over ALL inputs,
no extra binder (F-A4 is a gate note, not an instance). The generated shell
`Formatted_auxiliary.lean:42-44` delegates to the hand-written proof with the
same telescope. Hygiene grep over the three new/changed proof modules
(`sorry|set_option|native_decide|bv_decide|ofReduce|admit|partial|unsafe|axiom|decide|maxHeartbeats|maxRecDepth|implemented_by|extern`,
comments excluded): only `set_option autoImplicit false` ×3 and one
`decide (R v' ≤ R v)` inside a `List.filter` predicate (a `Decidable`
coercion). Axioms: §8.

## 5. Scope item 5 — F-C4-1 reproduced; F-A2 confirmed; F-A3 refuted as a gap

Binaries: fork `zero-discrepancy/_build/default/backend/driver/main.exe`
(`check_driver_fresh: oracle OK (bin c54c1dee…)` in the battery log),
upstream `deps/cerberus-upstream/_build/default/backend/driver/main.exe`,
Lean `zero-discrepancy/lean_frontend/.lake/build/bin/cerberus-lean` (`lean OK
(bin 32f8b342…)`); flags as `scripts/test_multi_tu.sh` uses them.

### 5.1 F-C4-1 — two TUs, `struct node { int v; struct node *next; }`

`node_a.c`: the struct + `struct node ident(struct node n) { return n; }`;
`node_b.c`: the struct, the prototype, `main` builds a `struct node` and
returns `ident(n).v`. Verbatim:
```
--- [fork oracle 2-TU] rc=124 elapsed=60s            (no output)
--- [upstream oracle 2-TU] rc=124 elapsed=60s        (no output)
--- [lean 2-TU node (default fuel)] rc=134 elapsed=3s
Stack overflow detected. Aborting.
```
(oracle command: `main.exe --runtime=… --nolibc --exec --batch --mode=exhaustive
node_a.c node_b.c`; Lean: `cerberus --cabs-json` per file, then
`LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch node_a.json node_b.json`.)
Classification [AGENT]: upstream TRUE BUG — non-termination on legal C (a
self-referential struct crossing TUs by value; STD §6.2.7#1 structural
compatibility needs an "assumed-compatible" set for recursive types); tray
draft owed (the record's §8 item 2(b)). The path: `memValueFromValue`
(`core_aux.lem:193-197`) → `Ctype_aux.are_compatible` → the cross-TU
`Struct/Struct` arm (`ctype_aux.lem:118-153`) → members → `Pointer/Pointer`
(`:113`) → the other TU's `struct node` → …; `are_compatible` is also
drive-reachable through `step_eval_pexpr` (C2 record row 30). Lean: not a
loop, not the FUEL sentinel — the native stack overflows first (F-A7).
`--fuel` could not be applied to pin this to the fuel'd recursion (F-A8).

### 5.2 F-A2 — `struct A { _Alignas(struct A) char c; }`

`alignas_self.c`: the struct; `main` returns `sizeof(struct A)`. Control
`alignas_ok_control.c`: `struct B { int x; }; struct A { _Alignas(struct B)
char c; };`. gcc: `error: invalid application of '__alignof__' to incomplete
type 'struct A'`. Verbatim:
```
--- [fork oracle alignas_self] rc=124 elapsed=60s
--- [upstream oracle alignas_self] rc=124 elapsed=60s
--- [fork oracle alignas CONTROL] rc=0 elapsed=0s
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
--- [lean alignas_self (default fuel)] rc=134 elapsed=1s
CerbMem.memberAlign: fuel exhausted
backtrace: …
--- [lean alignas CONTROL] rc=0 elapsed=0s
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
```
Reading: the frontend accepts the CV (§2, the `Just LT` path); the table has
`A`'s entry with `alignTypes = [struct A]`, a by-value self-edge; `Acyclic`
is false; the oracle's `alignof (struct A)` → member `c` `AlignType` →
`alignof (struct A)` → … forever (both oracles hang); the Lean measured
wrapper runs out of its `memberBound` fuel and panics with the loud
sentinel — precisely the record's stated behaviour on a hypothesis-violating
table, now reached from C source rather than from hand-authored Core.
Disposition [AGENT]: register/header text correction (row 3, §3), and an
upstream-tray candidate (Cerberus fails to diagnose §6.5.3.4#1 on the
character-member path and then does not terminate) — to be drafted with
F-C4-1's.

### 5.3 F-A3 — the FAM element type (refuted as a gap)

```
--- [fork oracle fam_self: struct S { int n; struct S fam[]; }] rc=1
unknown location  error: constraint violation: struct member with a flexible array member found as element of an array   (§6.7.2.1#3, sentence 2)
--- [upstream oracle fam_self] rc=1   (same message)
--- [fork oracle fam_v1: struct T; struct S { int n; struct T fam[]; }; struct T { struct S s; };] rc=1
fam_v1.c:1:68: error: constraint violation: struct member has a type with a flexible array member
--- [fork oracle fam_v2: struct T; struct S { int n; struct T fam[]; }; struct T { int x; };] rc=0
Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
--- [fork oracle fam_v3: … union U { struct S s; int i; }; struct T { union U u; };] rc=1
fam_v3.c:1:99: error: constraint violation: struct member has a type with a flexible array member
```
The desugaring registers the FAM element unchecked, but the Ail passes
(`ailWf.lem:76-80`, `genTyping.lem:2346-2349`) refuse every by-value edge
into a struct with a FAM, directly or through unions — so the FAM edge can
never be part of a by-value cycle. The register's `:1600-1603` cite is the
wrong line; the guarantee stands (row 2, §3).

## 6. Scope item 7 — the gate

- `lemHyp` pinning: `FuelFormsTool.obligationShape` (read in full) walks the
  telescope with names; `lemFuel` by NAME and `Nat`, must be an argument of
  the worker side; a later binder `LE.le _ _ _ (bvar lemFuel)`; `lemHyp` if
  present at index `jFuel - 1` exactly. The `hyp` column = `ppExpr` of the
  `lemHyp` type under `forallTelescope`, whitespace-normalized; notation via
  `importModules (loadExts := true)` after `enableInitializersExecution` —
  hence `unsafe main`. The census pin `PIN UNSAFEDECL
  lean_frontend/test/Unit/FuelFormsTool.lean main 1` is honest: the tool is
  a `lean_exe` (`lakefile.toml:232-235`, `srcDir = "test"`,
  `supportInterpreter = true`); `grep -rn FuelFormsTool lean_frontend/*.lean`
  finds no importer; it classifies (shape + `collectAxioms`) and proves
  nothing — kernel-irrelevant.
- The register logic (`check_fuel_forms.sh policy`, read in full): table
  side = `(worker, hyp)` of MEASURED rows with a non-empty column 6; register
  side = data rows with 4 TAB fields, `.lem:[0-9]` in field 3, non-blank
  field 4; `comm` both directions. RED paths: `hnew`, `hstale`, `badreg`,
  missing register file. It can go red (11 plants, §9) and did on each.
- Reproduced in `test_unit.sh` (§8), verbatim:
  ```
  check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING, 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
  check_fuel_forms: SELFTEST OK (11 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 3 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register; unplanted table green)
  ```
- F-A4 (the remaining-binders gap) is the one hardening I would add.

## 7. Scope item 6 — F-C4-4, the eager measure (assessment; no code change)

Mechanism, named: the fuel-free wrapper's fuel ARGUMENT is a strict
expression evaluated before the worker runs — `envBound ambient ty := lemSize
ty + defsWeight ambient + 1`, `defsWeight m := ((fmapElements m).map (fun p =>
defSize p.2.2 + 2)).sum` — an enumeration of the whole tag environment plus a
`flatMap`/`map`/`sum` over every member type of every definition, per call
of `sizeofCtype`/`alignofCtype`/`reconstructValue` (and twice over `tagDefs`
for `offsetsof`). O(|environment| + Σ member-type sizes) on EVERY load/store
(`loadM`/`storeM` call `sizeofCtype`), including `sizeof(int)`, to bound a
recursion that is O(structural size) whenever the type is tag-free. On
csmith-sized programs a constant-factor tax; on Linux-scale tag environments
a per-memory-op linear scan — the F-C3-4 mechanism, second instance, and
worse-scaling than C3's (C3's measures were over the argument). NOT measured
here (no build permitted; no C3-head binary): B7 holding row-for-row under a
30 s wall clock is a correctness signal, not a timing one; the <10 % bar is
unverified.

A cheaper SUFFICIENT measure at no trust cost: `envBound' m ty := if refsOf
ty = [] then lemSize ty + 1 else lemSize ty + defsWeight m + 1` (same guard on
`memberBound` over `ty :: alignTypes al`, on `membersBound` over the members'
types, on `reconstructValue`). Sufficient because when `refsOf ty = []` the
recursion performs no tag lookup (every lookup arm is reached only from a
`Struct`/`Union0` head through `Array0`/`Atomic` — `refsOf`'s definition), so
the proof's tag potential `tp ty` is 0 and `pot ty = lemSize ty`; one extra
lemma (`refsOf ty = [] → tp ty = 0`) and the obligation changes only in `μ`.
`refsOf ty = []` is O(lemSize ty). A size-annotated environment would remove
even the remaining scan but changes a representation — not for speed alone.
Recommendation [AGENT]: take the guarded measure in the timing slice the C3
item already owes, with the whole-csmith-lane A/B against the merged head;
do not block C4 on it.

## 8. Scope item 8 — lanes after the battery; `#print axioms`

Orchestrator's battery: `.tmp/c4-reverify.log` reached `=== DONE` (its last
lane `test_gcc_oracle.sh --check-baseline`: `gcc second-oracle lane OK` /
`--- rc=0`); Tier B is the orchestrator's log, not re-run here. Then, in the
slice worktree, serially, `CERB_MEM_MAX=16G SKIP_BUILD=1 scripts/ce …`
(`.tmp/lanes.log`), verbatim:
```
=== …/zero-discrepancy/scripts/test_unit.sh
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (… 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING, 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_fuel_forms: SELFTEST OK (11 plants red with the declared label — 5 on the table, 3 on the hypothesis register, 3 compiled decoy obligations incl. the contradictory-hypothesis decoy caught by the register; unplanted table green)
Total: 6 passed, 0 failed
--- rc=0
=== …/zero-discrepancy/scripts/test_verify.sh
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
--- rc=0
=== …/zero-discrepancy/scripts/test_immaculate.sh
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
--- rc=0
```
`#print axioms` (`capped lake env lean` in the slice worktree's
`lean_frontend`, a scratch file importing `CerbMem_lemMeasureProofs`,
`Formatted_lemMeasureProofs`, `Formatted_auxiliary`), verbatim:
```
'CerbMem.sizeofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.alignofCtype_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memberAlign_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsofMembers_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.offsetsof_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.reconstructValue_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.memValueToBytes_measure_sufficient' depends on axioms: [propext, Classical.choice, Quot.sound]
'showNonNegativeWithBasis_aux_measure_sufficient' depends on axioms: [propext, Quot.sound]
'Formatted_lemMeasureProofs.showNonNegativeWithBasis_aux_measure_sufficient' depends on axioms: [propext, Quot.sound]
--- rc=0
```
All ⊆ the trio.

## 9. Plants (from `test_unit.sh`'s `check_fuel_forms --selftest`, this run)

P1 measured→ambient reachable (step_eval_pexpr) · P2 stale pending pin · P3
sorryAx cone · P4 truncated table · P5 phantom pending row · P6 decoy of
type `True` (to_pure) · P7 decoy with the wrong worker constant (to_pures) ·
P10 COMPILED decoy under `env1 ≠ env1` (hack): MEASURED by shape, RED by the
register (+ the premise check: the tool reports `hyp=env1 ≠ env1`) · P8
register row of `CerbMem.sizeofCtype` deleted · P9 stale row `hack 0 < k` ·
P9b row without a `.lem:` cite — each `PLANT OK` with its declared label
(`.tmp/lanes.log:515-529`), then `UNPLANTED` green. The contradictory-
hypothesis decoy is the right plant for lem audit F1's consumer-side
closure; F-A4 names the one shape the plants do not cover.

## 10. Not checked

- The frontend-guarantee THEOREM (`desugar`'s output is `Acyclic`) — not the
  slice's claim (DOCUMENTED status).
- The ~40 layout lemmas line by line — statements, telescopes, hygiene grep
  and axiom cones read; the kernel checked the proofs (the lane).
- Whether `_lemReader_tagDefs` is empty at elaboration (`Translation.lean:509`)
  — does not bear on the hypothesis' correctness.
- Timing (F-C4-4) — no build/measurement permitted here.
- Pinning F-A7's stack overflow to `are_compatible_aux` by a small `--fuel`
  (F-A8 blocked it); the path is read, not traced at run time.
- lem-lean `f6542f8` itself (audited on its side, MERGEABLE with F1 carried
  here).
- Whether the Lean pipeline classifies `Stack overflow detected. Aborting.`
  (rc 134) as crash or kill in the lanes — a `fuel_classify.sh` question.
