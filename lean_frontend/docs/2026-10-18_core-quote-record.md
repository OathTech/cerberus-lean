# Core quotation record

## D0 — construction and representation audit (2026-10-19)

Base: `e7e9bb427a514b6053865c303c4af512907da75b`, branch
`feature/core-quote`. The worktree was clean before the baseline run.
The governing document is `2026-10-18_codex-charter-core-quote.md`, revision 5.
No production implementation or theorem is added by D0.

[USER 2026-10-19] The dispatch requires the baseline, reachable-constructor
inventory and independent construction-path audit to be reported before D1.
The worker must retain representation, establish comparator provenance on
every producer path, and park at a charter stop condition.

[USER 2026-10-18 relayed] Development uses focused checks; each reported
worker boundary and commit requires Tier A, and completed-slice close-out
requires Tier B. New theorems additionally require named kernel replay.

### Baseline and reproduction

The initial command, with the prescribed shell-local project environment and
`CERB_MEM_MAX=48G`, was:

```sh
python3 scripts/release.py --mode fast
```

Untouched-base run: 2026-10-19 19:44:19–20:03:42 UTC, process exit 0.
All nineteen lane exit statuses were 0. The runner's summary was:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

This establishes the requested Tier A baseline; it is not a Tier B or
full-release certification. No lane row moved. Existing compiler warnings
are recorded as F6 below.

[AGENT 2026-10-19] Keep the small inventory source beside this record so
the constructor and instance observations can be reproduced. Commit D0
as a documentation checkpoint before implementing the seam; its commit
message records the final-tree Tier A run. No new ladder gate is added.

The inventory can be regenerated from `lean_frontend/`, after the documented
project build, with:

```sh
CERB_MEM_MAX=48G ../scripts/capped lake env lean docs/CoreQuoteInventory.lean
```

It inspects elaborated constructor types, recursively instantiates their
parameters, and reports the constructor names. Scalar leaves and container
representations are handled explicitly. It also prints the instantiated
comparator terms and representative producer definitions. This is a
development report, not an additional ladder gate or a correctness theorem.

The inventory succeeded (exit 0). An earlier attempt to walk every
expression node in the large elaborator definition timed out at 60 seconds
(exit 124); that approach was removed. Constant-use inspection and the
small producer prints suffice alongside source inspection. The initial
`lean_probe.sh` invocation on a file outside the Lake package failed module
resolution (exit 1); the package's capped `lake env lean` invocation above
resolves the built modules. Neither failure was counted as a successful check.

### Reachable types and coverage checklist

The root is `file core_run_annotation = generic_file Unit core_run_annotation`
(`generated/Core.lean:2490-2508,2548`). Its twelve fields are:

| Field | Representation to preserve |
|---|---|
| `main` | `Option sym`, including the complete symbol description |
| `calling_convention0` | Both calling-convention constructors |
| `tagDefs` | Symbol map of locations and tag definitions |
| `enumDefs` | Symbol map of integer types |
| `stdlib` | Symbol map of all four function-declaration forms |
| `impl0` | Implementation-constant map of `Def` and `IFun` |
| `globs` | Ordered list of complete symbols and `GlobalDef`/`GlobalDecl`; initializer expression included |
| `funs` | Symbol map of all four function-declaration forms |
| `extern` | Identifier map of ordered symbol lists and `linking_kind` |
| `funinfo` | Symbol map of location, attributes, return ctype, parameter list, and both Boolean flags |
| `loop_attributes1` | Nat map of marker, attributes, condition location and loop location |
| `visible_objects_env0` | Nat map of ordered symbol/ctype lists |

Derived inventory: **75 model datatype heads, 638 constructors**, plus six
container heads and six scalar heads, **87 heads total**. The constructor
inventory script emits every constructor name, rather than relying on a
manually abbreviated list. Counts below are derived from that output; `@n`
is the verified declaration line. Every listed type is pending printer and
comparison coverage at this checkpoint.

| Source | Reachable types: declaration line (constructor count) |
|---|---|
| `generated/Core.lean` (28 types, 162 constructors) | `generic_file` @2490 (1); `calling_convention` @2464 (2); `generic_fun_map_decl` @2349 (4); `core_base_type` @118 (8); `core_object_type` @27 (6); `generic_pexpr` @1133 (1); `generic_pexpr_` @1076 (29); `value` @646 (8); `object_value` @439 (6); `loaded_value` @449 (2); `ctor` @779 (17); `generic_pattern` @897 (1); `generic_pattern_` @894 (2); `binop` @284 (14); `iop` @316 (7); `generic_name` @406 (2); `generic_expr` @1928 (1); `generic_expr_` @1886 (19); `generic_paction` @1810 (1); `polarity` @386 (2); `generic_action` @1789 (1); `generic_action_` @1689 (15); `kill_kind` @1664 (2); `pass_by_value_or_pointer` @1866 (2); `dyn_annotation` @1832 (2); `generic_impl_decl` @2323 (2); `generic_globs` @2434 (2); `linking_kind` @2404 (3) |
| `generated/Symbol.lean` | `sym` @237 (1); `symbol_description` @107 (8); `identifier` @22 (1); `prefix0` @413 (7) |
| `CerbLocation.lean` | `Loc` @70 (5); `Pos` @52 (1); `Cursor` @62 (3) |
| `generated/Ctype.lean` | `tag_definition` @413 (2); `alignment` @394 (2); `ctype` @140 (1); `ctype_` @113 (10); `basicType` @70 (2); `floatingType` @50 (1); `realFloatingType` @29 (3); `qualifiers` @90 (1); `flexible_array_member` @375 (1) |
| `generated/Annot.lean` | `attributes` @56 (1); `attribute0` @37 (1); `annot` @274 (14); `bmc_annot` @19 (1); `label_annot` @86 (8); `cerb_attribute` @190 (2); `value_annot` @256 (1); `loop_attribute` @413 (1) |
| `generated/IntegerType.lean` | `integerType` @116 (10); `integerBaseType` @21 (10) |
| `generated/Implementation.lean` | `implementation_constant` @140 (28) |
| `CerbMem.lean` | `IntegerValue` @69 (1); `Provenance` @47 (4); `PointerValue` @63 (1); `PointerValueBase` @55 (3); `MemValue` @79 (7); `Footprint` @116 (1); `FootprintAccess` @113 (2) |
| `generated/Mem_common.lean` | `mem_constraint` @1107 (8); `pure_memop` @818 (5); `derivecap_op` @799 (2); `generic_memop` @904 (22) |
| `generated/Undefined.lean` | `undefined_behaviour` @66 (238); `undefined_by_omission` @46 (2); `unspecified_ub_context` @18 (9) |
| `generated/AilSyntax.lean` | `unaryOperator` @388 (7); `binaryOperator` @412 (10); `arithmeticOperator` @176 (10) |
| `generated/Core_run_aux.lean` | `core_run_annotation` @53 (1) |
| `generated/Cmm_csem.lean` | `memory_order` @212 (7) |
| `generated/Linux.lean` | `linux_memory_order` @13 (10) |

The six scalar heads are `Nat`, `Int`, `String`, `Bool`, `PUnit` (the
reduction of `Unit`), and `Float`. Containers are `List`, `Option`, `Prod`,
`Fmap`, `Pmap`, and `Pset`. Only `Fmap` has a function field. Its comparator
is covered by the provenance table below; no other callable leaf appeared.
`Pmap.Node` carries left tree, key, value, right tree and cached Nat height;
`Pset.Node` carries left tree, element, right tree and cached Nat height.
There is no captured comparator in this Lean `Pset` representation
(pinned `LemLib.lean:469-471,937-940,1192-1194`).

Coverage obligations carried into D1/D3:

- [ ] Every constructor reported by the inventory has a printing or named
  refusal branch, recursively through every payload.
- [ ] The comparison visits the same complete type inventory independently;
  field omissions cannot be hidden by a map-only comparison.
- [ ] `Fmap.empty` and `Fmap.mk _ Pmap.Empty` remain distinct in both
  directions. Every tree shape and cached height is retained.
- [ ] All fourteen `annot` constructors, all three run-annotation set
  fields, every ctype annotation, all five `Pos` fields, and all symbol
  descriptions survive. `CerbCtypeInstances.lean:29-35` confirms that
  ordinary ctype `BEq` is annotation-insensitive; it is not the primary
  comparison.
- [ ] Non-NaN float leaves use their binary64 bits, including signed zero,
  subnormals and infinities; NaNs produce a named refusal before auxiliary
  whole-file `BEq`. This also applies inside `CerbMem.MemValue`.
- [ ] Required-input coverage includes all ten `tests/fixtures/*/cabs.json`,
  all sixteen `lean_frontend/corpus/*.c` (including `p10alt`), a cross-TU
  declaration/reference case, and the separately converted libc file.
  These are file counts, not measured constructor-occurrence counts.
- [ ] The final refusal census is over all those converted values. No
  zero-occurrence or NaN-absence claim is made by this type-only inventory.

### Instantiated comparator vocabulary

The following are complete monomorphic terms, checked against the current
elaborated environment. Short labels in the table are notation in this
record, not new runtime constants.

```lean
-- S: fromList on sym, via the active SetType instance
@Lem_Map.MapKeyType.mapKeyCompare sym
  (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)

-- O: generated sym insertions and derived labeled maps
@Lem_Basic_classes.ordCompare sym instEq0Sym_1 instOrd0Sym_1

-- L: the unfolded Main.libcSymMapCmp alias
symbol_compare

-- I: implementation-file insertions
implementation_constant_compare

-- N: Nat-keyed map insertions
@defaultCompare Nat instOrdNat

-- E: the generated identifier comparator, including its String instance
fun (a b : identifier) =>
  match a with
  | .Identifier _ sa =>
    match b with
    | .Identifier _ sb => @defaultCompare String String.instOrd sa sb
```

`S` resolves through `instSetTypeSym_1` to `O`; neither uses structural
`defaultCompare sym`. The active instances are at
`generated/Symbol.lean:290,330,383`, in contrast to the lower-priority
structural instances at `:244-250`. The constants and their arguments are
printed by the inventory probe, and the elaborated `translate_tag_definitions`
and `loadCoreStdlib` definitions confirm that their original `fromList`
calls captured the active dictionary. `translate_program` and `link_aux`
also refer to those active dictionaries in their compiled definitions.
Do not replace `O` with `L` merely because the intended symbol ordering
agrees: these are distinct construction terms.

`E` is an inlined lambda in generated insertion sites. It is the body of
the active identifier `SetType` instance (`Symbol.lean:59-66`), and ignores
the identifier location. Any named quotation alias must retain this
body and its explicit `String.instOrd`, rather than select structural
identifier ordering. `I` is monomorphic (`Implementation.lean:351`).

Pinned library rules verified directly:

- `LemLib/Map.lean:49-63,101-105`: `fromList` folds insertion from
  `fmapEmpty`, with `mapKeyCompare` from its explicit dictionary.
- `LemLib.lean:1211-1213`: insertion into `.empty` captures the supplied
  comparator; insertion into `.mk c t` retains `c`.
- `LemLib.lean:1271-1274`: union of two `.empty` maps is `.empty`;
  a left `.mk c t` supplies `c` even when `t = .Empty`; a left `.empty`
  and right `.mk c t` supplies the right `c`. The explicit union
  comparator argument is unused.
- `LemLib.lean:1232-1237,1034-1049`: mapping values preserves the outer
  constructor, comparator, key positions and cached heights.

### Verified field provenance

`Translation.lean` in this table is the generated file at this base, not
the older line numbering in the charter. `T` means a translated user or
libc-metadata TU; `Lfile` means the result of `Main.loadLibc`.

| Quoted map | Every producer on the declared driver path | Link and conversion |
|---|---|---|
| `tagDefs` | T: `translate_tag_definitions`, `Translation:5862-5869`, builds with `fromList S` from the sigma list; selected at `5882,6399`. Lfile: the metadata/dump stitch collects a list (`Main:830-870`), then `libcMapFromAssoc L` at `993`. | `Core_linking:465-467`: union chooses the first outer `.mk` by the rule above, so `S` or `L` depending on origins. `Core_run_aux:943` retains the map. |
| `enumDefs` | T: `fromList S sigm.enum_definitions`, `Translation:5885,6400`. Lfile: `.empty`, `Main:1021`. | `Core_linking:468-470`: both constructor branches; an empty libc field does not erase the program comparator. `Core_run_aux:944` retains it. |
| `stdlib` | `loadCoreStdlib`, `Main:45-57`: `fromList S` of `funs ++ procs ++ builtins`; loaded at `1081-1092`, passed to every T and Lfile (`Translation:6401`, `Main:1022`). | `Core_linking:471` takes `f1.stdlib`, with no union; `Core_run_aux:945` maps the declarations, preserving the comparator and tree representation. |
| `impl0` | `loadCoreImpl`, `Main:60-72`: fold insertion with `I` from `.empty`; loaded at `1108`, passed to T and Lfile (`Translation:6402`, `Main:1023`). | `Core_linking:472` takes `f1.impl0`; `Core_run_aux:946` maps the declarations preserving representation. |
| `funs` | T: fold starts `.empty` at `Translation:6295`; declaration insertion `6047-6049` and definition insertion `6282-6289` both capture `O`; result installed at `6406`. Lfile: deduplicated renamed dump declarations, `Main:999-1010`, then `libcMapFromAssoc L` at `1025`. | `Core_linking:474-476`: both union branches, selecting `O` or `L`. `Core_run_aux:948` maps declarations preserving representation. |
| `extern` | `Cabs_to_ail_effect.extract_program`: the fold at `3679-3709` starts `.empty` and inserts with `E`; installed in sigma at `3855`. `GenTyping:3926` retains it. `Translation.translate_extern_map:6362-6373` maps values only. Lfile retains the linked metadata map (`Main:1026`). | `Core_linking:457` calls `link_extern f2.extern f1.extern`. All seven insertion arms (`65,89,114,123,131,159,169`) use `E`; duplicate normal definitions fail. Fold starts with `f1.extern` (`176`), retaining its comparator if `.mk`, capturing `E` on first insertion if `.empty`, or staying `.empty` if no insertion. `Core_run_aux:949` retains it. This is not `fmapUnionBy`. |
| `funinfo` | T: `.empty` at `Translation:6295`; all declaration branches `6050-6061` (proxy, no proxy, non-`SD_Id`) and definition branch `6291-6294` insert with `O`; result at `6408`. Lfile: renamed metadata list `Main:871-874`, rebuilt with `L` at `993`. | `Core_linking:478-480`: both union branches, selecting `O` or `L`. `Core_run_aux:950` retains it. |
| `loop_attributes1` | Desugar state starts `.empty` (`Cabs_to_ail_effect:990`); its sole update inserts with `N` (`2136-2137`); `extract_program:3861` and `GenTyping:3928` retain it; `Translation:6409` selects it. Lfile is `.empty` (`Main:1028`). | `Core_linking:481-482`: both union branches; `Core_run_aux:951` retains it. |
| `visible_objects_env0` | `Translation_effect.elab_init:106` starts `.empty`; sole update at `301-303` inserts with `N`, guarded by the `Cn` backend branch at `291`; `Translation:6410` selects it. Lfile is `.empty` (`Main:1029`). | `Core_linking:483-485` calls `safe_map_union:444-451`: disjointness check then the same outer-constructor-sensitive union, so its `mapKeyCompare` argument cannot change a captured `N`. `Core_run_aux:952` retains it. |

`Main.frontendTU:705-741` separately constructs an enum reader from the same
sigma list; it supplies typing/translation and is not itself the file's
`enumDefs` map. The typed sigma preserves tag/enum lists and external/loop
maps (`GenTyping:3924-3928`). `Cabs_to_ail.desugar:6855-6890` ends at
`extract_program`; `mk_current_ail_sigma`'s empty external/loop maps
(`Cabs_to_ail_effect:3543-3572`) serve intermediate frontend evaluation.
The alternate sigma extraction at `3973,3979` has empty extern and the
same loop-state map; it adds no different comparator provenance.

#### Both link sites and fold direction

`Main.loadLibc:808-824` fronts each metadata TU, reverse-conses the results
and calls `link`. The user pipeline does the same with an optional library
first (`Main:1128-1160`), then calls `link` at `1171`. There are therefore
**two driver link sites**, both audited.

`Core_linking.link:487-496` folds with `link_aux f accumulated`, not
`link_aux accumulated f`. For original processing order `[Lfile,T1,...,Tn]`
(omit `Lfile` without libc), union fields consequently take the comparator
of the earliest original input whose outer constructor is `.mk`; a field
with only `.empty` inputs stays `.empty`. This includes `.mk c .Empty`.
The retained `stdlib`/`impl0` fields end up from the earliest original
input. The external map follows the distinct insertion fold described
above. No claim uses binding-list emptiness to choose provenance.

#### Conversion and non-map fields

Quotation is at `Main:1212` after `link`, before driver initialization;
the `--pp-core` branch at `1206-1208` returns earlier. The separately
quoted library is `convert_file` applied to the `loadLibc` result before
the final user link. `Core_run_aux:931-952` retains `main`, calling
convention and all metadata, maps initializer expressions in the ordered
`globs` list, and maps the three code-valued maps. `convert_action:841-846`
and `convert_expr:874-877,895` replace action/call/run annotations with
`empty_annotation:461-462`: all three sets start as `Pset.Empty`.
Other annotation lists and dynamic annotation payloads are preserved.
Nonempty annotation sets still belong to the type-level checklist.

`main` originates in the typed program's first component (`Translation:6397`),
is `none` for Lfile (`Main:1014`), and is resolved by both branches of
`link_main` (`Core_linking:177-186`), which rejects duplicate entries.
`calling_convention0` originates in `frontendTU`'s `Normal_callconv`
(`Main:739`), is inherited from linked metadata for Lfile (`1015`), and
is checked for equality before the linker retains `f1`'s value (`453-455,464`).
Program `globs` comes from `translate_program` and its object/string-literal
construction folds, then `merge_globs` at `Translation:6403-6405`;
Lfile rebuilds each definition body from the renamed dump while retaining
metadata declaration entries and order (`Main:982-993`). Linking uses
`merge_globs` (`Core_linking:473`): its temporary symbol-keyed lookup map
starts `.empty` and inserts `O` (`427-433`), but only its ordered list is
stored in the file. `convert_globs:923-930` preserves both global
constructors and recursively converts each definition's initializer.

### Findings from the wider construction census

**F1 — an additional conversion/driver run path exists.**
`generated/Mini_pipeline.lean:178-192` constructs and converts a dummy
Core file for constant-expression evaluation. `stdlib` and `impl0` come
from the same `loadCoreStdlib`/`loadCoreImpl` tuple; the other seven maps
are explicitly `.empty`. It uses `initial_driver_state_given` at `194`
and a converted expression as its thread arena at `200`. This constructor
is absent from the charter review's provenance table. Its dummy file does
not escape into the `Main:1212` file; the evaluation result feeds desugaring.
The quotation point remains the final driver file. This is a finding in
the construction inventory, not a second quotation target.

**F2 — three further generic-file transformations exist.**
`Core_typing.typecheck_program:2506-2667` rebuilds `stdlib`, `impl0` and
`funs` using `Core_typing_effect.mapMapM:21-28`, a fold from `.empty`.
The calls at `2548,2571,2626` capture `S` for `stdlib`/`funs` and the
following complete term for `impl0` (also checked by the inventory):

```lean
@Lem_Map.MapKeyType.mapKeyCompare implementation_constant
  (@Lem_Map.instMapKeyTypeOfSetType implementation_constant
    instSetTypeImplementation_constant_1)
```

This is a different construction term from `I`, despite resolving to
the same implementation comparison. The other six maps are retained;
the globals are typechecked as a list. This transform returns
`generic_file core_base_type a`, rather than the quotation root with
`Unit` base annotations, and does not preserve arbitrary input map
representations. `Core_sequentialise.sequentialise_file:87-96` maps only
function values, preserving every map's comparator and representation.
`Core_rewrite.rewrite_file:1219-1220` maps the globals list and function
values (`rewrite_fun_map:1196`), also retaining all nine map comparators
and representations. Searches over the complete
generated tree and hand-written driver found no production callers of
these three functions. They do not enter the admitted quotation point.
The library's already rewritten bodies arrive as parsed text and are
rebuilt by `loadLibc`, as recorded above. These paths were not listed in
the charter's provenance table and must not be mistaken for
representation-preserving alternate entry points.

`Core_indet.hackish_order:519` is the identity on its input file; it
introduces no constructor or comparator and likewise has no production
caller in this tree.

The census also found the generated `Inhabited generic_file` constructor
(`Core:2509-2512`), explicit test files in `Unit.FuelExemplar` and
`Unit.RunDigestTest`, a historical address-space probe in `docs`, and the
five `speclab/SpecLab/*Files.lean` families. These are default/test/harness
construction sites, not inputs to `Main.frontendTU` or `loadLibc`. D0
establishes no blanket comparator guarantee for arbitrary `file` values.

**F3 — generated citations have drifted.** The charter's old Translation
anchors `5643-5650`, `5663-5666`, `5828-5841`, `6143-6154`, `6178-6191`
now correspond to `5862-5869`, `5882-5885`, `6047-6060`, `6362-6373`,
`6397-6410`. `safe_map_union` is at `Core_linking:444`; file fields extend
through `Core:2507`, not `2501`. `Driver` installs `core_extern` at `2394`,
and derives labels at `2413,2422`. The record uses the checked current
locations. No discrepancy in the corrected comparator ordering was
found on the declared quotation path; F1/F2 extend the path census.

**F4 — ctype equality needs the full structural walk.** The earlier
review's warning is confirmed: `CerbCtypeInstances:29-35` discards ctype
annotations for `BEq`. Consequently the independent representation check
must descend through ctype and its annotations, including inside memory
values, and use generated whole-file `BEq` only as the auxiliary check.

**F5 — an existing operator quotation remains in the pinned dependency.**
`LemLib.lean:835-837` contains historical verbatim operator text. It was
reported to the operator and left unchanged under the dependency fence.
This record does not reproduce it.

**F6 — the untouched baseline emits existing compiler warnings.**
Tier A's unit build reports unused `termination_by` clauses in
`generated/Symbol.lean:451,485` and `generated/Ctype_aux.lean:443,450`,
and missing reducibility attributes on class-valued definitions in
`test/Unit/FuelExemplar.lean:132`, `ReconstructLegacyTest.lean:517-518`,
and `PnviArmsTest.lean:42-43`. These nine diagnostics predate D0; the
new inventory emits none. The standing warning-repair rule and this
slice's file fence conflict for these files. Repairs need an operator
scope ruling; no suppression or edit outside the fence was made.

### Derived run-state maps (audited, outside the quoted file)

`Core_aux.empty_saves:2577-2578` and `collect_saves:2667-2672` start both
accumulators at `.empty`. `Esave` inserts with `O` (`2640-2647`). Both
`Ewseq` and `Esseq` map existing values without changing comparators, then
combine via `union_saves` (`2580-2587,2613-2633`). `Epar` has the two nested
unions at `2652-2654`; the final union is at `2672`. Every union follows
both outer-constructor branches. No other expression arm creates a map.
`collect_labeled_continuations_NEW:2824-2837` unions stdlib and functions
only for traversal, starts its outer map `.empty`, and inserts `O` with
the `collect_saves` results as values. Thus inner and outer newly built
label maps use `O` even if input `funs` originated in libc with `L`.

The parallel `m_collect_saves` family starts empty at `2706-2707`, inserts `O`
at `2791`, unions at `2712-2716,2797-2799,2820`, and is not the driver's
label constructor. `Core_linking.create_extern_symmap:498-514` starts
`.empty`; both tentative and normal branches insert `O`, while `LK_none`
retains the accumulator. `Driver:2394,2413,2422` installs these derived
maps. They are not extra fields to serialize.

### Floating input and remaining measurements

The numeric register `scripts/libc_float_literals.txt:6-29` has 24 entries.
`CoreParser:1506-1525` identifies four additional infinity sites; the
zero at `tests/libc/libc.core:53379` and infinity at `53897` are present.
The parser constructs `OVfloating` at `1058,1524,1573`, renaming keeps
it at `2816`, and conversion keeps a `PEval` at `Core_run_aux:749`.
The required libc round trip therefore needs non-NaN floats. The signed
zero bit use and NaN limitation were checked at
`CerbFloat:325-330,348-354,382-388`. These are source facts, not a census
of the converted required inputs, and do not establish NaN absence.

D0 has not run the printer, whole-file round trips, negative controls,
or Tier B. No new theorem was introduced, so there is no new module
requiring kernel replay. D1 must implement the checklist and preserve
per-field producer identity across the link fold; the D3 refusal census
and elaboration measurements remain open.
