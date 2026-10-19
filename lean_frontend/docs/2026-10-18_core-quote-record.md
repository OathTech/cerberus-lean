# Core quotation record

## D0 — construction and representation audit (2026-10-19)

Base: `e7e9bb427a514b6053865c303c4af512907da75b`, branch
`feature/core-quote`. The worktree was clean before the baseline run.
The governing document is `2026-10-18_codex-charter-core-quote.md`, revision 5.
No production implementation or theorem is added by D0.

[AGENT 2026-10-19, orchestrator dispatch relayed by the operator] The dispatch requires the baseline, reachable-constructor
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

- [x] Every constructor reported by the inventory has a printing or named
  refusal branch, recursively through every payload (completed in D1).
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

**F6 — the baseline and dependency builds emit existing compiler warnings.**
Tier A's unit build reports unused `termination_by` clauses in
`generated/Symbol.lean:451,485` and `generated/Ctype_aux.lean:443,450`,
and missing reducibility attributes on class-valued definitions in
`test/Unit/FuelExemplar.lean:132`, `ReconstructLegacyTest.lean:517-518`,
and `PnviArmsTest.lean:42-43`. These nine diagnostics were those visible in that
Tier A build, not the complete dependency-warning inventory; they predate
D0 and the new inventory emits none.

[AGENT 2026-10-19, orchestrator ruling relayed by the operator] The seam
build replays 337 warnings from the generated tree, including 229
unreferenced pattern variables and 103 unused `termination_by` clauses;
none originate in `CerbQuote`. The backend-emission backlog belongs to
lem-lean work owned elsewhere; the five test-file class-valued definitions
belong to the orchestrator's separate hygiene slice. No warning is suppressed
or repaired outside this slice's fence.

D2 independently reproduced that seam-only replay count with
`capped lake build +CerbQuote` after synchronization (exit 0): 337 total,
229 unreferenced variables, 103 unused termination clauses, and five
deprecations in the copied handwritten dependencies `CerbLocation:225,228`
(three), `CerbFloat:294` (one), `CerbCtypeMeasure:232` (one). These five
are distinct from the baseline's five test-definition diagnostics. The
broader `+CerbQuote cerberus-lean` build replays 849 existing warnings
across its larger dependency closure, including 837 under `generated/`
(which also contains handwritten copies); none are from `CerbQuote`.
The changed driver lines introduce no warning. This expands the observation,
not the worker's repair scope.

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


## D1 — representation printer (2026-10-19)

[AGENT 2026-10-19, orchestrator ruling relayed by the operator] The separate consumer-list reference in charter §5
resolves to the complete requirement already in §0, including its correction.
The existing nine warnings are outside this worker's repair scope: backend
termination diagnostics and test hygiene have separate owners. D1 retained
F6 without edits; D2 expands its warning-build scope.

`CerbQuote.lean` supplies `moduleSource : Provenance → file core_run_annotation
→ Except Refusal String`, plus `quoteFile` and the producer-specific provenance
helpers. It is registered in `handwritten_copy.manifest` and the library roots.
There is no driver flag yet. The only output-module import is `Core_run_aux`;
the public value is `quotedCore : file core_run_annotation`.

[AGENT 2026-10-19] Emit fully instantiated, exhaustive constructor cases for
the audited root. Use exact typed subterm sharing and separate private helper
definitions to keep elaboration manageable without changing model values.

Coverage audit: all **638 model constructors** have printing branches:
637 explicitly named payload cases and the twelve-field `generic_file.mk`
case. Each payload case uses every argument once in constructor order.
The six scalar and six container heads are also covered. All memory-value
constructors are supported; there is no memory-value refusal. Recursive
payload walkers and the syntax work-list use `partial def`: this instrument
has exhaustive runtime coverage, not a kernel proof of termination or
printer correctness. These instrument definitions are outside the model
execution cone and will be named in the D4 boundary entry. No theorem, axiom,
native seam, `unsafe`, `sorry`,
`implemented_by` attribute, or kernel-check bypass was added in source.

`Fmap.empty` and `Fmap.mk _ Pmap.Empty` remain distinct. The printer follows
every `Pmap.Node` and `Pset.Node` field, including cached heights; it never
reconstructs a container from bindings. All twelve file fields, all fourteen
`annot` cases, the three annotation sets, ctype annotations, locations and
complete symbols have explicit traversal. `Float.ofBits` carries non-NaN
binary64 representations. A NaN is refused before calling `toBits`, with a
name such as `funs.Float.NaN`, including when nested in a memory value.

`translatedProvenance` and `libcProvenance` are restricted by contract to their
D0-audited construction sites. `linkedProvenance` mirrors the reverse-consed
input order and `link_aux next accumulated` fold; libc retains precedence
when its outer map is `.mk`, even with an empty tree. The exact S/O/L/I/N/E
terms are emitted without substituting extensionally similar comparators.
Unexpected outer constructors, missing provenance and a comparator outside
the field's admitted vocabulary produce named errors. These are construction
records supplied by the caller, not closure introspection or a proof about
arbitrary externally constructed files.

The extern insertion fold differs from union: a right `.mk E .Empty` inserted
into left `.empty` still yields `.empty`. The final successful linked file
supplies that outer tag; its construction comparator remains E. This follows
`Core_linking.link_extern:33-176`, `link_aux:452-485` and `link:486-496`;
the inspected driver still reverse-conses libc first (`Main:1124-1171`).
This is an implementation detail of the D0 provenance result, not an additional
producer path or a revision of F1/F2.

The emitter interns exact quotation syntax (constructor names, literal text,
fully instantiated type text and child IDs), using no model equality.
Formatting thresholds select repeated subterms and chunks for private typed
helpers; the dependencies are acyclic and preserve each original constructor.
No comparator is shared by comparing its behaviour. The output does not
change Lean's default heartbeat or recursion limits.

### Focused reproduction and results

The small reproducible sources are `docs/CoreQuoteSmoke.lean` and
`docs/CoreQuotePipelineProbe.lean`. They are development probes, not a
replacement for D3's independent whole-file representation comparison or
its complete required-input census. After the documented project setup,
from the repository root:

```sh
export CERB_MEM_MAX=48G
mkdir -p .tmp/core-quote-d1
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build +CerbQuote)
(cd lean_frontend && ../scripts/capped lake env lean docs/CoreQuoteSmoke.lean)
for quoted in .tmp/core-quote-d1/Float*.lean .tmp/core-quote-d1/SetsAndComparators.lean; do
  (cd lean_frontend && ../scripts/capped lake env lean "../$quoted") || exit "$?"
done
```

The probe emits five float modules (+0, -0, the smallest positive subnormal,
+infinity, -infinity) and one set/comparator module. Their evaluated assertions
check the emitted float bits, escaped symbol digest and description, map outer
constructors and height 91, and all three noncanonical set shapes/heights.
Separate checks reject NaN and invalid provenance, check all six exact
comparator spellings, and exercise libc-first and extern-insertion corner
cases. The final run results are recorded below.

The pipeline probe reuses the existing native digest wrapper; it introduces
no new native source or production seam. After the normal driver/native build:

```sh
cc -shared lean_frontend/.lake/build/ir/CerberusFresh.c.o.export \
  lean_frontend/native/md5.o -o .tmp/core-quote-d1/fresh-runtime.so
./scripts/capped scripts/libc_prep.sh --jsons "$PWD/.tmp/core-quote-d1/libc-json" \
  > .tmp/core-quote-d1/libc-json-paths.txt
export CERB_QUOTE_FUEL=1000000 CERB_QUOTE_TOP=18446744073709551616
for CERB_QUOTE_PROBE in fixture libc; do
  export CERB_QUOTE_PROBE
  (cd lean_frontend && ../scripts/capped lake env lean \
    --load-dynlib=../.tmp/core-quote-d1/fresh-runtime.so \
    docs/CoreQuotePipelineProbe.lean) || exit "$?"
done
for quoted in PipelineQuoted LibcQuoted; do
  (cd lean_frontend && /usr/bin/time -f '%e seconds; %M KB peak RSS; exit %x' \
    ../scripts/capped lake env lean "../.tmp/core-quote-d1/$quoted.lean") || exit "$?"
done
```

The fixture is `001-return-literal`; the libc probe loads all twelve metadata
TUs and the committed bodies (191 procedures, 68 globals). Both quote after
`convert_file`. The literal imports neither `Main` nor `CerbQuote`. Passing
elaboration is positive D1 evidence only; these probes do not compare the
whole original and elaborated files.

Development failures were not counted as passes. An initial pipeline probe
loaded only `md5.o`, which lacked the compiled `CerberusFresh.setDigestIO`
wrapper and crashed (exit 134) before quotation. The dirty worktree was
snapshotted to a local ref before further edits; linking the existing wrapper
object with the existing native object fixed the probe setup. Initial target,
syntax and type errors were corrected before the passing runs.

The first libc literal, a single 51,875,828-byte expression, failed the default
200,000-heartbeat limit at `isDefEq` (82.41 s, 10,009,180 KB peak RSS, exit 1).
Sharing through a single `where` declaration still failed at `whnf`
(20,084,239 bytes; 67.79 s, 4,979,584 KB, exit 1). These failures motivated
the private typed helper emission above; neither run approached the 48G cap
or the one-hour tripwire. No limit was raised or warning suppressed.

D2's flag, D3's complete representation comparison, mutation controls and
required-input refusal census, and D4's boundary entry/Tier B remain open.
No new theorem was declared, so D1 does not introduce a kernel-replay gate.


Final focused results (all process exits 0):

| Check | Result |
|---|---|
| Synchronize, then `capped lake build +CerbQuote` | Success; no diagnostic attributed to the new seam |
| `docs/CoreQuoteSmoke.lean` | Six modules emitted; named refusals, six comparator terms and link rules passed |
| All six emitted assertion modules | Elaboration and evaluated representation assertions passed |
| Fixture generation / elaboration | 439,633 bytes; generation 2.91 s / 941,400 KB; elaboration 1.87 s / 824,432 KB |
| Converted libc generation / elaboration | 33,832,667 bytes, 13,318 helpers; generation 38.61 s / 1,365,932 KB; elaboration 144.99 s / 12,055,992 KB |

Memory figures are peak RSS from `/usr/bin/time`; every Lean invocation used
`CERB_MEM_MAX=48G`. The successful libc traversal did not encounter a NaN;
that is not the all-required-input census reserved for D3. Lake replayed
existing dependency diagnostics; the seam and focused probes introduced none.

### Tier A before the D1 commit

Command (after `make lean-prelude-src`, with `CERB_MEM_MAX=48G`):

```sh
python3 scripts/release.py --mode fast --out .tmp/core-quote-d1/tier-a
```

Run: 2026-10-19 21:12:30–21:32:12 UTC. Process exit **0**; all nineteen
lane exit statuses were **0**. The completed implementation and focused
probe sources were fixed during the run. The runner reported:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

No existing lane row moved. This paragraph records the gate result after
completion; the temporary literal modules, native wrapper bundle and logs
are reconstructible from the commands above and are removed after commit.
D1 is ready for the D2 handoff. Tier B remains the D4 close-out gate.


## D2 — driver quotation flags (2026-10-19)

[AGENT 2026-10-19] Use `--quote-core OUT.lean` for the linked program and
`--quote-libc LIB.lean` for the separately converted library. Both modes
share execution's loading, frontend, linking and conversion path, and return
after quotation, before driver initialization. Library-only quotation accepts
no user TU when the library and all metadata TUs are supplied. Reject flags
that request execution observations together with quotation.

The code records `libcProvenance libcFile` on the successful `loadLibc` result
(`Main.lean:1163-1167`) and `translatedProvenance coreFile` on each successful
user `frontendTU` result (`1189-1192`). Origins and files are reverse-consed
together. The final `link coreFiles` remains at `1203`; successful
`coreFile` supplies `linkedProvenance origins coreFile` at `1257`.
`runFile := convert_file coreFile` is now at `1244`, and its quotation at
`1260` uses that provenance. The separate libc conversion is at `1167`,
quoted once at `1252`. Both flags may be requested in the same invocation.

These are current D2 locations; the D0/D1 locations above describe their
respective committed trees. The unchanged metadata link is now at
`Main.lean:822`. The library comparator alias is at `247`, the tag/funinfo
rebuild at `994`, and the function rebuild at `1026`. Reinspection of
`Core_linking.lean:444-496` and `Core_run_aux.lean:931-952` confirms the
D0/D1 per-field construction and outer-constructor rules. No producer or
union path was replaced. The second explicit `Main` conversion is the
chartered standalone-library quotation; the mini-pipeline conversion in
F1 remains a separate internal constant-expression evaluation. F1/F2 remain
findings against the charter's original path table.

[AGENT 2026-10-19] Render all requested modules before writing any output.
Publish each complete source through an exclusively created sibling scratch
directory and rename; remove that scratch directory afterwards. A named
quotation refusal leaves all requested output paths untouched. Publication
of two successful renders is per file: an IO failure on the second output
can leave the first complete module, and is reported as an error.

Quotation errors use the existing `Error {msg: ...}` stdout record, escaped
with `CerbEscape.text`, and exit 1. NaN errors include the enclosing field
and `Float.NaN`. Output errors name the destination and exit 1. Invalid
flag combinations/repetitions use the existing attributed CLI refusal
shape and exit 2; missing required arguments use exit 1. Successful quotation
is silent and exits 0. `--batch` is compatible; `--pp-core`, `--first`,
`--call`, `--call-args`, `--args` and `--trace-nodes` are incompatible.
Both output paths must be distinct. Normal execution without either flag
continues through the original driver path.

The sharing plan now carries `Option (type text × child ID)` for helpers.
Rendering consumes that typed child directly; the former `unreachable!` arm
is absent. The seventeen partial instrument definitions (fifteen recursive
payload walkers, `intern`, `renderTasks`) remain outside the model execution
cone: they are called only on the quotation branch, which returns before
`initial_driver_state` and `drive`. They will be named in D4's boundary
entry; no termination or printer-correctness theorem is asserted here.
No new theorem was added, so D2 introduces no new kernel-replay gate.

### Focused reproduction

`docs/CoreQuoteCliSmoke.py` is a development probe, with no ladder wiring.
After the documented project environment setup, from the repository root:

```sh
export CERB_MEM_MAX=48G
mkdir -p .tmp/core-quote-d2
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build +CerbQuote cerberus-lean)
./scripts/capped scripts/libc_prep.sh --jsons "$PWD/.tmp/core-quote-d2/libc-json" \
  > .tmp/core-quote-d2/libc-json-paths.txt
source scripts/common.sh
for n in 1 2; do
  capture_cabs_json "$PWD/.tmp/core-quote-d2/tu$n.json" \
    "$PWD/.tmp/core-quote-d2/tu$n-capture" ./scripts/capped "$CERBERUS_BIN" \
    --runtime="$PWD/_build/install/default" --cabs-json "tests/multi_tu/basic/tu$n.c" || exit "$?"
done
python3 lean_frontend/docs/CoreQuoteCliSmoke.py
```

The probe uses the committed fixture's exact relative runtime prefix, and
the freshly generated multi-TU/libc metadata's absolute runtime prefix.
An initial attempt to use the absolute prefix with the committed fixture
failed the existing library-location guard (exit 2); correcting the
invocation fixed the setup. This failure was not counted as a passing run.
The NaN controls use a private copy of `libcore`, add an unused floating
function returning NaN, and adjust only the copied fixture's runtime-location
prefix to match. Neither pinned input nor installed runtime is edited.

The output literals import only `Core_run_aux`. Elaboration uses the normal
pinned toolchain defaults under the 48G cap. The linked case is the existing
`tests/multi_tu/basic` pair: one TU declares/calls the other's `helper`,
with distinct same-named statics. It is linked with libc while the same
invocation also emits the standalone converted libc. The library-only mode
emits byte-identical source to that standalone output.

The small D1 float/set/comparator probe and all six emitted assertion modules
were rerun after the sharing-plan change, all exit 0. D3's independent
whole-file comparison, mutation controls and complete input census remain
open. Its test wiring awaits the relayed operator decision on libc row-1
placement; no test executable or ladder row is added by D2.


Focused results:

| Check | Result |
|---|---|
| Synchronized seam + driver build | Exit 0; no warning from `CerbQuote` or changed driver lines |
| CLI fixture output | 394,761 bytes; generation 0.08 s / 83,256 KB; elaboration 1.61 s / 824,488 KB; both exit 0 |
| CLI linked two-TU + libc output | 34,028,318 bytes, 13,437 helpers; elaboration 101.36 s / 12,115,992 KB, exit 0 |
| CLI standalone libc output from that invocation | 33,832,667 bytes, 13,318 helpers; elaboration 100.11 s / 12,053,664 KB, exit 0 |
| Combined linked + libc generation | 4.89 s / 567,112 KB, exit 0 |
| Library-only generation | 3.07 s / 558,660 KB, exit 0; source equals the standalone output above |
| Five argument-refusal controls | Expected exits 1/1/2/2/2 and diagnostic text observed |
| Output-path failure | Existing Error shape, exit 1; no module created |
| NaN with absent / existing destination | Named `stdlib.Float.NaN`, exit 1 in both cases; absent stays absent, existing content unchanged |

Memory figures are peak RSS from `/usr/bin/time`; all heavy commands were
capped at 48G. No elaboration limit was raised. Both large literal
elaborations were comfortably below the cap and the one-hour tripwire.

The positive CLI checks completed before the first NaN setup attempt failed:
Python's copy preserved Dune's mode 0444. Reusing that copy also failed when
copying over its read-only files. `nono why --self --path ... --op write`
reported ALLOWED; this was a local test-copy permission issue, not a
confirmed sandbox denial. The probe now recreates its private runtime
directory and replaces only its own copied `std.core`. The eight refusal
and output controls were rerun successfully after this setup correction;
previously passing large elaborations were not repeated. No machine-global
permission or runtime file was changed. The full script above reproduces
both groups; the focused rerun executes its shared definitions and the block
starting `for label, args, code, marker in [...]`.


### Tier A before the D2 commit and parked handoff

Command, with the project environment and `CERB_MEM_MAX=48G`:

```sh
python3 scripts/release.py --mode fast --out .tmp/core-quote-d2/tier-a
```

Run: 2026-10-19 22:16:49–22:36:09 UTC, process exit **0**. All nineteen
selected commands passed. The implementation, probe and documentation
sources were fixed during the run; the runner reported:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

No lane row or baseline moved. This gate-result paragraph and the consumer
note's gate status were added after completion. Reconstructible `.tmp`
outputs are removed after commit. Tier B remains the D4 close-out gate.

[AGENT 2026-10-19] Park at the completed D2 handoff. D3 test wiring is
not started while the libc round-trip placement decision is pending relay;
the D3 whole-file relation, controls and census remain outstanding.


## D2b — portable libc metadata and resolved directory guard (2026-10-19)

[USER 2026-10-19] Extend this step's fence to the driver's library-directory
guard, `scripts/libc_prep.sh`, consumer convention text in README/VALIDATION
and this note, with `scripts/common.sh` only if a lane requires it. Compare
resolved directories by exact membership; retain stored positions. Export
libc metadata from the project root using the canonical relative runtime
prefix. Existing libc-mode lanes must retain their baselines; a refusal or
movement requires a committed park and operator approval before repair.

[USER 2026-10-19] Place the libc round trip in a new named Tier B row.
Fixture/corpus and multi-TU checks remain in row 1. The test executable
must also check modules emitted by the flag for consumers at their pin.

[AGENT 2026-10-19, relayed] D2 was independently accepted after both flags,
elaboration and refusals were exercised. D3 must also pin and check the
libc literal's SHA-256, reject absolute position
paths, compare output across runtime spellings and working directories, and
measure kernel replay of the elaborated libc literal for the consumer note.

`Main.refuseLibraryLocations` resolves the three runtime directories and
each suffix-matching imported directory with `IO.FS.realPath`. Resolution
errors and foreign directories retain the attributed exit-2 refusal.
This deliberately differs from the oracle's literal-directory test at
`util/cerb_location.ml:512-523`; exact membership, rather than prefix or
suffix membership, remains the criterion. No imported field is edited.
The new code does not change file construction, map unions, provenance or
conversion. The final quotation point moved to `Main.lean:1252`.

The metadata exporter now runs from the project root with
`--runtime=_build/install/default`, `-I runtime/libc/include`,
`-I runtime/libc/include/posix` and `runtime/libc/src/<tu>.c`.
Those are the same include directories as the build at
`runtime/libc/dune:146-153`. The old metadata export was at
`scripts/libc_prep.sh:198-200`; its `:82` runtime argument belongs to the
dump regeneration, which remains unchanged. All twelve new JSONs have
zero absolute source-position paths and zero absolute lexing-position
paths. Their digest inputs and TU order are unchanged.

Metadata consumers traced: `test_libc_exec.sh`, `test_libxml2_uri.sh`,
`test_immaculate.sh`, `test_ci_sweep.sh`, `test_pnvi.sh`,
`test_speclab_{divmod,list,tree}.sh`, and `test_upstream_oracle.py`.
Their driver calls run from the project root; no lane or `common.sh` edit
is needed to resolve the new metadata paths.

Compile attempts found an unbound local-helper result type and a missing
String-to-FilePath conversion. Both were corrected; a focused Lean check
passed. The failed attempts are not gate evidence. The existing D2 NaN
probe now copies the runtime header directory too, so its private runtime
supplies all three directories required by the resolved-membership guard.


**F7 — metadata is not the only path-bearing input to the libc literal.**
With the same canonical metadata, both `--quote-libc` runs from the project
root succeed, but absolute and relative runtime prefixes produce different
source. The absolute-prefix output contains 282 emitted `Pos.mk` source
paths for `std.core` and two for the `.impl` file with the machine's root
prefix; the relative-prefix output has no absolute `Pos.mk` source path.
These are occurrences in the shared literal source, not an expanded
whole-value census. Removing only the root prefix from the absolute-prefix
output makes the two sources byte-identical; this diagnostic comparison
does not change either output. Sizes are 33,336,641 / 33,290,633 bytes.

The construction sites are `Main.lean:1111,1116,1130,1135`: file lookup paths
are also the arguments to `CoreParser.parseLibraryFile`. The parser's
location resolution (`CoreParser.lean:2533,2545-2546,2716`) constructs both
source and lexing paths from that argument. Thus a guard-only change cannot
establish D3's runtime-spelling determinism. This is an additional input
provenance finding, beyond the metadata-header positions identified in
the relayed direction. The quoting seam correctly preserves these values.

[AGENT 2026-10-19] Keep parser construction sites unchanged pending approval
of a path-origin policy; the current guard-only fence does not settle them.
An explicit source-root argument could anchor relative imported locations
and provide relative labels when library positions are first constructed,
without rewriting stored positions. This proposal is pending approval and
is not implemented. D3 determinism and its SHA-256 pin remain open.


### D2b focused checks and reproduction

After the documented project environment setup, from the repository root:

```sh
export CERB_MEM_MAX=48G
mkdir -p .tmp/core-quote-d2b
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build cerberus-lean)
./scripts/capped scripts/libc_prep.sh --jsons "$PWD/.tmp/core-quote-d2b/libc-json" \
  > .tmp/core-quote-d2b/libc-json-paths.txt
./scripts/capped scripts/check_runtime_resolution.sh
./scripts/capped scripts/test_libc_exec.sh
./scripts/capped scripts/test_libxml2_uri.sh
```

Results: synchronized build exit 0; all 17 runtime-resolution witnesses
pass; libc execution matches all 43 baseline cases; libxml2's four lanes
retain their pinned expectations, including exact agreement on all 16
libc URI cases. Both lane commands exit 0 with no baseline edits. Additional
fixture controls using `./_build/./install/default` and a private symlink
to the installed prefix both return the expected 42, exit 0. Foreign and
missing runtime-directory witnesses still refuse as specified.

The D2 CLI recipe was rerun with its temporary directory changed to
`.tmp/core-quote-d2b`, using newly exported metadata and the same two user
TUs. The complete probe exits 0: three literals elaborate, library-only
source agrees, and all eight refusal/output controls pass. Fixture
elaboration: 1.56 s / 824,732 KB. Linked two-TU+libc: 102.12 s /
12,121,460 KB. Standalone libc: 107.72 s / 12,050,272 KB. All elaborations
exit 0 at the pinned defaults under the 48G cap. No theorem was added;
D3's requested literal kernel-replay measurement remains outstanding.

F7's spelling comparison is reproduced using the same twelve paths:

```bash
export LEAN_ABORT_ON_PANIC=1
mapfile -t metadata < .tmp/core-quote-d2b/libc-json-paths.txt
libc_args=(--libc tests/libc/libc.core)
for path in "${metadata[@]}"; do libc_args+=(--libc-tu "$path"); done
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime "$PWD/_build/install/default" --fuel 1000000 \
  --quote-libc .tmp/core-quote-d2b/Abs.lean "${libc_args[@]}"
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime _build/install/default --fuel 1000000 \
  --quote-libc .tmp/core-quote-d2b/Rel.lean "${libc_args[@]}"
cmp .tmp/core-quote-d2b/Abs.lean .tmp/core-quote-d2b/Rel.lean
```

Both quotation commands exit 0; the byte comparison **fails**. This is
not a D3 pass or a portable-literal SHA-256 pin. The absolute output's
remaining path source is documented in F7 above.


**F8 — the required alternate working directory refuses.**
With the same canonical metadata and absolute paths to the metadata files,
dump and output, invoking from `lean_frontend/` with
`--runtime ../_build/install/default` exits **2**. Runtime lookup succeeds,
but the stored `./_build/install/default/.../libc/include/builtins.h`
directory resolves against `lean_frontend/`, where it does not exist.
The refusal names that source directory and no output module is written.
The required cross-working-directory determinism check therefore **fails**.

Reproduction, after the metadata preparation above:

```bash
export LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G
quote_root="$PWD"
mapfile -t metadata < .tmp/core-quote-d2b/libc-json-paths.txt
libc_args=(--libc "$quote_root/tests/libc/libc.core")
for path in "${metadata[@]}"; do libc_args+=(--libc-tu "$path"); done
(cd lean_frontend && ../scripts/capped .lake/build/bin/cerberus-lean \
  --runtime ../_build/install/default --fuel 1000000 \
  --quote-libc "$quote_root/.tmp/core-quote-d2b/OtherCwd.lean" "${libc_args[@]}")
```

### Tier A and committed park

The already-running precommit gate was allowed to finish after F8; no
implementation change followed the refusal. Command:

```sh
CERB_MEM_MAX=48G python3 scripts/release.py --mode fast --out .tmp/core-quote-d2b/tier-a
```

Run: 2026-10-19 22:55:43–23:14:25 UTC, process exit **0**. All nineteen
lane exit statuses were **0**. The exact summary was:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

No existing lane row or baseline moved. Documentation of F8, gate status,
and the placement ruling's attribution was finalized after the run; no
implementation or probe changed. Temporary literals, metadata and logs
are reconstructible and removed after this commit.

**Park status:** the new F8 refusal triggers the operator's stop rule.
The scoped D2b changes are committed with passing Tier A and explicit F7/F8
failures, not a determinism claim. Proceeding requires approval of the
source-origin/parser-construction policy outside the guard-only extension.
D3 wiring, the independent whole-file comparison and controls, the portable
SHA-256 pin and libc kernel-replay measurement are not implemented. The
operator's Tier B placement and consumer-module requirement are recorded
above for resumption. Tier B close-out and the D4 boundary entry remain open.
