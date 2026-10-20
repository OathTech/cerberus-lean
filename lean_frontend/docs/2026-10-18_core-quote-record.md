# Core quotation record

## Committed history after the 2026-10-20 rebase

The D0–D4 entries below retain the identities at which their measurements were
made. The orchestrator rebased this series before the pre-merge audit; these
are the corresponding commits now on `feature/core-quote`, verified against
both commit chains (pre-rebase hash → committed hash):

| Step | Pre-rebase hash | Committed hash |
|---|---|---|
| Base | `e7e9bb427a514b6053865c303c4af512907da75b` | `2e1777b27775519499aeee469106c5ef56ef4fbb` |
| D0 | `fb8705c686d1de34f66426e3da4f1477d077632e` | `6d2543c9217296b239fcdb0c6a4a9d95c2228d31` |
| D1 | `a81a93a2e3de6e4668147baf1ca612ed8ed29893` | `f67295d4fce6ddaaf2547570fd4fd22e91abce4e` |
| D2 | `d14ad75ce045d1face55a8837da1563314c402f7` | `7b9158a927c5f987c27aeee98f73f92aa58f741e` |
| D2b | `74a9388441baf20ab204de614babd9c6f1526042` | `d5d1cb389ff184e33153e074604ea92a43ece1c4` |
| D3 | `b7240f9a463656c9df1ff75ddad6000833d1872f` | `b844467cae89dcdf8335c0322a23a66169f5ecde` |
| D4 | `65ba8618b9d6f6924fa43f7cfc49e5acf79edb64` | `e557782f2b1dcb5e92457a8e92a2959ef013b6c9` |

`88bf20f5f8acabaa72142653e22a7ec2e0f13359`, cited below, was an ephemeral
crash-recovery snapshot, not a series commit. Its ref was deleted at D4 as
recorded; it has no rebased-series counterpart. The pre-merge audit itself is
`167f1360d6269a33822e1394c77808eb463d05d0`.

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
CERB_MEM_MAX=48G ../scripts/capped lake env lean test/CoreQuote/probes/CoreQuoteInventory.lean
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

The small reproducible sources are `test/CoreQuote/probes/CoreQuoteSmoke.lean` and
`test/CoreQuote/probes/CoreQuotePipelineProbe.lean`. They are development probes, not a
replacement for D3's independent whole-file representation comparison or
its complete required-input census. After the documented project setup,
from the repository root:

```sh
export CERB_MEM_MAX=48G
mkdir -p .tmp/core-quote-d1
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build +CerbQuote)
(cd lean_frontend && ../scripts/capped lake env lean test/CoreQuote/probes/CoreQuoteSmoke.lean)
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
    test/CoreQuote/probes/CoreQuotePipelineProbe.lean) || exit "$?"
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
| `test/CoreQuote/probes/CoreQuoteSmoke.lean` | Six modules emitted; named refusals, six comparator terms and link rules passed |
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

`test/CoreQuote/probes/CoreQuoteCliSmoke.py` is a development probe, with no ladder wiring.
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
python3 lean_frontend/test/CoreQuote/probes/CoreQuoteCliSmoke.py
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


## D3 resumption: canonical invocation convention

[AGENT 2026-10-19, orchestrator] D2b is accepted. The earlier determinism
requirement is replaced by a convention-bound claim: metadata export and the
Lean run use `_build/install/default` as the runtime prefix, from a directory
where the stored relative paths resolve. No source-root parameter, parser change
or position-label rewrite is part of this slice. F7 explains the relative-label
requirement; F8 becomes the required negative control. The previous park is
released on that basis.

The revised controls require no absolute position paths in fixture or libc
literals, a committed libc SHA-256 checked by the test, identical output through
a project-root symlink alias, and an output-free convention-naming refusal from
`lean_frontend/` with `../_build/...`. The required-input census, independent
whole-file comparison, mutation controls and consumer-module interface remain
in scope. The earlier operator ruling still places libc in its own Tier B row.

[AGENT 2026-10-20] Generate the test's constructor visitor from Lean's datatype
declarations, independently of the printer. Compare the resulting constructor
and scalar trees exactly; inspect elaborated Fmap comparator expressions
separately, without identifying constants by computation. This covers all 638
model constructors, including annotations, container tags, cached heights and
floating bits. The visitor traverses 172 instantiated types. Fmap's function
argument alone belongs to the syntax check. A separate original-value census
visits every required input, including the converted libc file.


### F9 — required corpus array exceeded the default elaboration budget

The first complete D3 run passed all ten committed Cabs fixtures and the first
three corpus files, then failed while elaborating `p04_arr_sum.c`. Its
`static int buf[ARENA]` has 1,048,576 entries. The quotation's global initializer
contains `generic_pexpr_.PEctor ctor.Carray`; its list was emitted as one
9,437,292-character expression with 1,048,576 references to the same quoted
integer expression. The module was 10,056,898 bytes. Lean rejected it at the
default 200,000-heartbeat limit (`isDefEq`), exit 1. A measured reproduction took
20.52 seconds and 2,743,876 KB peak RSS. This is a failed required-input check,
not a round-trip success. Neither the 48G cap nor the one-hour stop tripwire
was approached; no elaboration limit was changed.

[AGENT 2026-10-20] Keep short-list emission unchanged. For long lists, carry the
element type and split literal `List.cons` chains into typed blocks, retaining
all elements in order and terminating in the original nil. This addresses the
observed elaboration failure without a list builder, representation change or
limit increase. The independent test views lists as their length and ordered
elements, a lossless flat representation, to avoid recursion proportional to
the million-element list; its census still counts every cons and terminating
nil. Maps and sets keep their recursive representation checks unchanged.


The first typed-cons-block candidate elaborated the array literal successfully
in 162.49 seconds. Its complete consumer check then failed with exit 134:
Lean's interpreter exceeded its recursion stack in `ailErr_mapM`/`bind3`, while
rebuilding the original through `frontendTU`, before representation comparison.
The measured failed invocation took 175.49 seconds and peaked at 22,530,612 KB.
Before further edits, tracked and untracked source state was preserved without
changing the branch in `refs/snapshots/core-quote-d3-checker-crash-20261020`,
commit `88bf20f5f8acabaa72142653e22a7ec2e0f13359`. This was an unverified
recovery snapshot, not a deliverable or a passing gate.

[AGENT 2026-10-20] Share identical long-list constructor blocks as private typed
functions of their tail, and share the resulting closed tails as before. Each
function body contains only the original `List.cons` applications and fixed
quoted elements; the final tail is nil. This avoids repeating a million
constructor applications in source while preserving their denoted list exactly.
There is no append/from-list/replicate builder in the emitted module, no map or
set reconstruction, and no changed limits. Add a varied 257-element list and
its reversed-order negative control to check block boundaries and ordering.

[AGENT 2026-10-20] Compile `CoreQuoteCompare` and its ordinary pipeline imports
as a test support library, and load it only for the comparison/control stage.
This lets the original-value computation use compiled Lean, as the driver does,
instead of the interpreter's deep monadic call stack. Literal elaboration and
`leanchecker` run without this plugin. It adds no native source, extern,
implemented-by replacement, axiom or theorem, and does not change the model or
its pipeline. No stack limit was increased.


The final F9 focused consumer-mode run passes: the array literal is 712,296
bytes, elaboration is 3.04 seconds (exit 0), and independent comparison is
3.15 seconds (exit 0). The entire check, including symlink quotation and the
wrong-cwd negative control, takes 9.51 seconds and peaks at 3,232,528 KB, exit 0.
The census sees all 1,048,576 initializer entries. The varied long-list controls
also pass. No limit was raised. The test support uses Lake's recorded library
dependencies and the existing `native/md5.c` implementation compiled with shared
library visibility; the driver's object hides those symbols. It introduces no
new native implementation. Initial test-command parsing, plugin initialization
and library-loading errors were development failures, corrected before this
passing run.


### D3 required population and consumer check

The independent visitor covers the original D0 inventory: 638 model
constructors, 75 model heads, six container heads and 172 instantiated types.
The checker preserves every payload and constructor tag, comparing lists by a
lossless flat sequence, maps/sets by their original trees and cached heights,
and non-NaN floats by bits. A separate elaborated-expression check retains the
fully instantiated S/O/L/I/N/E terms. It expands generated matchers and normalizes
binder names only; comparator constants and instance dictionaries are never
identified by computation. Generated whole-file BEq is an additional required
check. The original is rebuilt from public pipeline stages, independently of
the printer, using the driver's default switches, supply, link order and final
conversion.

The test executable accepts flag-generated modules: `--module PATH --input JSON`
(repeated inputs in driver order) for user TUs, or `--libc --module PATH` for
standalone converted libc. Its driver subprocesses always use the project root
and `_build/install/default`. The consumer note supplies full commands. The
27 user cases are row 1's twentieth executable; converted libc is the new named
Tier B row 13. Existing lane membership and baselines are unchanged.

Focused reproduction after `make lean-prelude-src` and a capped
`lake build core-quote-test`, from the project root:

```sh
export LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/core-quote-d3/LibcCanonical.lean
```

The second command uses the canonical `--quote-libc` output, prepared using the
consumer note's twelve-metadata-TU recipe. Both commands exit **0**. The first
checks all ten committed Cabs fixtures, all sixteen corpus C files (including
`p10alt_rsum_rec.c`) and the linked `tests/multi_tu/basic` helper reference.
It takes 202.94 seconds and 10,498,784 KB peak RSS, including controls. Libc
elaboration takes 145.48 seconds and comparison 4.66 seconds. Its complete
consumer-mode check takes 158.25 seconds and 14,880,132 KB peak RSS. The earlier
array consumer-mode check also passes, so both external-module modes are exercised.

| Required population | Distinct model constructors | Floating leaves | NaNs | Memory values | Pos.mk | Absolute position paths |
|---|---:|---:|---:|---:|---:|---:|
| Fixtures/corpus/multi-TU (27) | 214 | 0 | 0 | 0 | 8,509,562 | 0 |
| Converted libc (1) | 224 | 28 | 0 | 0 | 15,586 | 0 |
| Combined (28) | 248 | 28 | 0 | 0 | 8,525,148 | 0 |

Combined container counts: `Fmap.empty` 97; `Fmap.mk` 155;
`Pmap.Empty` 5,861; `Pmap.Node` 5,706; `Pset.Empty` 40,734;
`Pset.Node` 0; `List.cons` 15,140,824; `List.nil` 23,530,266.
No required input is refused. Nonempty sets and memory values remain implemented
although absent from this population. NaN is the only data-domain refusal;
the separate negative control requires `globs.Float.NaN` by name.

All required negative controls observe rejection: main, global initializer,
map binding, cached height with the same inorder spine, both empty/mk-empty
directions, signed zero, and the same comparator head with a different explicit
instance. The height, outer-constructor and zero-sign controls also demonstrate
that the weaker BEq accepts their mutation. Positive signed-zero and infinity
controls pass, as do the added long-list/order controls. The absent alias key
is found under the active symbol comparator and missed under the structural
instance. The source-command comparator mutation exits 1 with the named mismatch.

Both fixture and libc root-alias controls are byte-identical; both wrong-cwd
controls exit 2, name the canonical convention and write nothing. Source and
lexing position filenames are both included in the structural path census.
The libc literal is 33,169,038 bytes and its initial committed D3 SHA-256 is
`30bdb3f5db037b5a63a3deaa24cba27f289bd7841770d1e1ebff43699dcbfe06`.
F9's typed-list-block formatting changes D2b's historical experimental hash
`bab902b2a79f5cf836d7a7fcf6996feb5c185042f3905ec899bc2231c819ff3b`;
that experiment was not a committed pin. No execution baseline was changed.
The test checks the new pin and never updates it automatically.

**Named kernel-replay gate:** `lake env leanchecker LibcLiteral`, with the
scratch module directory on `LEAN_PATH`, independently elaborated and without
the test plugin. GNU `time` reports **1.91 seconds wall time; 824,888 KB peak
RSS; exit 0** (Lean 4.32.2, 2026-10-20). This replays the literal declarations
against their imported environment, not a fresh replay of all dependencies.
The consumer note carries the same measurement for replay-tier selection.
No theorem, axiom, unsafe declaration, new extern, implemented-by replacement,
warning suppression or kernel-check bypass was added. The test's partial visitor,
comparison/census and syntax functions, and the printer's partial definitions,
remain instrument code outside the exec cone; D4 will name them at the boundary.


[AGENT 2026-10-20] The new `--core-quote-libc` selection returns after its
successful executable check. Its initial focused invocation also reran the
unit runner's general gates and passed, but that duplicates row 1's existing
battery. Keep all shared gates on the ordinary row-1 path; the separate Tier B
row owns the libc round trip, pin, convention controls and literal replay only.
No pre-existing selection or gate changes behavior.

The final independent visitor regeneration is byte-identical to the committed
source block: 638 model constructors and 172 instantiated types. The final
529-job build passes; no warning originates in the quotation or checker modules.
The broader dependency warning backlog remains under F6's existing disposition.


Final named Tier B row verification, after a fresh `make lean-prelude-src`:
`./scripts/test_unit.sh --core-quote-libc`, **exit 0**, 159.15 seconds wall time,
14,872,440 KB peak RSS. Its final summary is:

```text
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 1 passed, 0 failed
```

This run regenerates and checks the pinned libc literal itself. Its elaboration
is 142.67 seconds, comparison 4.82 seconds, and the separately measured
`lake env leanchecker LibcLiteral` is **exit 0; 1.94 seconds wall time;
825,068 KB peak RSS**. The consumer note uses this final row's measurement.
The alias comparison passes; the wrong-cwd invocation exits 2 and writes
nothing. The final census agrees with the external-module run above. This
verifies the new row, not the complete Tier B close-out reserved for D4.


### D3 Tier A and handoff

After the final handwritten-copy synchronization, command:

```sh
CERB_MEM_MAX=48G ./scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/core-quote-d3/tier-a
```

Run: **2026-10-20 01:01:15–01:23:54 UTC**, process exit **0**.
Every one of the nineteen selected commands has exit status **0**. Exact summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Row 1 reports **20 passed, 0 failed**, including all 27 user-input round trips
and their controls. The existing libc lane reports **43 matches, 0 differences**;
libxml2 URI and every other existing lane retain their baselines. There are no
artifact-inventory issues. Only this gate-result entry and the consumer note's
status were finalized after the run; no implementation or test changed.
Disposable literals, metadata, census output and logs are removed after the
commit. D3 is complete at this worker boundary. D4's explicit instrument boundary
entry and complete Tier B close-out remain open; this is not a full release or
printer-correctness theorem claim.


## D4 — Layout, declared boundary and close-out

[AGENT 2026-10-20, orchestrator close-out direction relayed by the operator]
Move the runnable quotation support and hash pin into the test
tree, retain earlier probes under its `probes/` directory, and make all record
and note citations follow the move. Document every opaque instrument component,
carry the measured ladder costs as speedbump notes, and retire the D3 recovery
snapshot once close-out succeeds. Tier A and the complete Tier B remain required
before the D4 commit; merge and push are outside this task.

[AGENT 2026-10-20] Keep the module names and committed libc hash unchanged while
moving the Lake source directories. The Python runner derives the repository
root from its new location and reads the pin beside itself. The Lean launcher
uses that new runner path. D0–D2 probes retain their historical behavior and
remain outside the ladder.

`VALIDATION.md` §3 now names all seventeen printer partial definitions, the
172 datatype visitors plus four partial comparison/census/syntax functions,
the partial development generator and D0 inventory probe, native `CoreQuoteSupport` plugin and
`--plugin`/`--load-dynlib` loading, test-time shared compilation of `native/md5.c`,
and the required Lake trace schema `2025-09-10`. These are instrument code outside
the exec cone. The named mover is the printer-correctness bridge (charter option
B); this slice delivers option A, not that proof. README, CLAUDE, the ladder and
the consumer note describe the final locations and convention. The consumer
note includes regeneration at a fixed pin and the separately authorized re-pin
recipe, including external-module checks, replay and both release tiers.

Tier A row 1 records the D3 quotation check's measured 203 seconds. Tier B row
13 records its 158 seconds and 14.9 GB; these cost observations are speedbumps,
not new resource gates. F6's warning ownership is unchanged. No theorem or
new native implementation is added by D4.

### D4 focused checks

After `make lean-prelude-src`, capped `lake build core-quote-test` exits 0
(529 jobs). The relocated launcher passes `core-quote-test --fuel 1000000
--fixture`, including whole-file comparison, mutation controls, byte identity
through the root alias and the convention-naming exit-2 refusal with no output.
The moved `test/CoreQuote/CoreQuoteVisitor.lean` regenerates the committed
visitor block byte-for-byte: 638 model constructors, 172 instantiated types,
75 model and six container heads. The relocated D0 inventory probe also exits 0.
Python syntax checks and `git diff --check` pass. All citations to the former
documentation-space code and pin locations have been replaced; module names
are unchanged. The documented partial-definition counts were recounted from
the final sources. No quotation/checker warning is introduced.

### F10 — Relocation exposed a forbidden local fuel instance

The first D4 Tier A run failed: row 1's no-fuel-numerals selftest found
`CoreQuoteCompare.original`'s `letI : LemFuel := ⟨fuel⟩` after its move into the
scanned test tree. Its former documentation-space location was outside that
scanner. The gate's F4 rule rejects that local-instance shape even when the
payload is the externally supplied variable; the documented permitted form is
an explicit application with a variable-fed instance. The quotation tests had
passed. Every other selected command, including all execution-baseline lanes,
passed; no baseline moved.

[AGENT 2026-10-20] Give `original` explicit fuel and switch instance parameters,
then apply it at the comparison entry with the supplied fuel and the same
default switches. This preserves its computation, exposes its inputs in the
signature and follows the existing gate's documented form. No gate, allowlist,
execution code or pin is changed. This is a test-integration repair within D4's
moved support file.

Initial run: `python3 scripts/release.py --mode fast --out
.tmp/core-quote-d4/tier-a`, exit **1**; **2026-10-20 02:08:19–02:35:20 UTC**.
Exact failed summary:

```text
fast: failed; 18/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The repaired support passes the direct no-fuel-numerals gate (351 scanned files),
a fresh handwritten-copy synchronization, the 529-job capped build and the
focused fixture's whole-file/comparator/BEq, mutation and convention checks.
All exit 0. The final full tiers below run after this repair.

### D4 final gates and close-out

A fresh `make lean-prelude-src` preceded each release invocation. Both ran
sequentially under the 48G cap with `LEAN_ABORT_ON_PANIC=1`, from the project
root after F10's repair:

```sh
CERB_MEM_MAX=48G ./scripts/capped python3 scripts/release.py --mode fast \
  --out .tmp/core-quote-d4/tier-a-final
CERB_MEM_MAX=48G ./scripts/capped python3 scripts/release.py --mode full \
  --out .tmp/core-quote-d4/tier-b
```

**Tier A:** 2026-10-20 **02:38:26–03:01:08 UTC**, process exit **0**;
all nineteen selected commands exit **0**. Verbatim summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

**Full A+B (Tier B close-out):** 2026-10-20 **03:01:41–05:14:00 UTC**,
process exit **0**; all forty-three selected commands exit **0**. Verbatim summary:

```text
full: passed; 43/43 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Both runs report complete selection, unchanged source, clean process containment
and no artifact-inventory issues. Row 1 passes all twenty executables, including
all 27 required fixture/corpus/multi-TU round trips and controls. Existing lane
baselines remain unchanged: libc execution has 43 matches and zero differences;
libxml2 URI has all sixteen pinned expectations; the four libxml2 battery slices
match; the GCC lane reports zero regressions and zero improvements; both
pristine-oracle rows and their register plants pass. No baseline or pin was edited.
The full run includes the existing expected refusals, differences and timeout
classes; passing those pinned rows is not a claim of semantic agreement for them.

The final libc quotation row takes 168.825 seconds. Independent literal
elaboration exits 0 in 151.32 seconds and comparison exits 0 in 5.18 seconds.
The relocated pin is byte-identical to D3 and the regenerated literal matches
`30bdb3f5db037b5a63a3deaa24cba27f289bd7841770d1e1ebff43699dcbfe06`.
The census is unchanged: 224 distinct model constructors, 28 floating leaves,
zero NaNs or memory values, 15,586 positions and zero absolute position paths.
The alias output is byte-identical. The wrong-cwd control exits 2, names the
canonical convention and writes nothing. The final row summary is:

```text
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 1 passed, 0 failed
```

**Named kernel-replay gate:** `lake env leanchecker LibcLiteral`, module
**`LibcLiteral`**, process exit **0**. Verbatim GNU `time` measurement from the row:

```text
LibcLiteral leanchecker: 2.05 seconds; 825348 KB peak RSS; exit 0
```

The independently elaborated literal and its imported environment are replayed
without the test plugin; this is not `--fresh` replay of transitive imports.
No theorem, axiom, unsafe declaration, new extern, implemented-by replacement,
warning suppression or kernel-check bypass was added in D4.

Final read-only documentation verification confirms all nine moved files,
seven syntactically valid shell recipe blocks, the current extraction cite
`Main.lean:1252`, and the complete partial-definition inventory. The latter also
names the unwired D0 probe's `inventory` traversal beside the development visitor's
`collect` in `VALIDATION.md` §3. Only gate-result reporting, this boundary-census
report and the consumer status were finalized after the full run; no executable,
test implementation, dependency, baseline or hash pin changed afterward.

The recovery ref `refs/snapshots/core-quote-d3-checker-crash-20261020`, formerly
`88bf20f5f8acabaa72142653e22a7ec2e0f13359`, was deleted with an expected-value
guard and its absence verified. Its recovery purpose is served: D3 is committed
and accepted, and the relocated instrument now passes complete close-out gates.
Disposable D4 logs, literals and generated inventories are removed after their
conclusions are recorded; the active worktree and build remain for the audit.

D0–D4 are complete at this worker boundary, including D2b's canonical-convention
extension. The declared instrument boundary remains, with the printer-correctness
bridge (option B) as its named mover. A fresh pre-merge audit is still required;
this gate result does not claim release certification. No merge or push was made.

## D5 — pre-merge audit fixes (2026-10-20)

[AGENT 2026-10-20, orchestrator direction relayed by the operator] Address
pre-merge audit P2-1, P2-2, P3-1/2/3 and the library-only quotation note in
one D5 commit, with Tier A before commit and the verification in its message.
The resolved guard remains under the existing [USER 2026-10-19] convention.

### P2-1 — measured relative-runtime divergence

The guard's resolved directory membership is retained. VALIDATION's guard
and Z-67 entries, the Z-67 source comment and original retirement record now
state its scope: with relative `--runtime=_build/install/default`, cpp's
`./_build/...` header positions fail the oracle's literal membership test but
pass the port's suffix classifier and resolved guard. Served UB-location
selection can differ. The differential lanes use absolute spellings where
both agree. Quotation still preserves the stored labels; its value and libc
pin are unaffected. Draft 58 and its INDEX row describe the oracle issue and
propose resolved exact membership without rewriting positions.

The new fixture-001 witness calls the built oracle `cerb_util` classifier and
the built Lean suffix classifier on the fixture's actual header spelling.
It checks the unprefixed spelling as an oracle-positive control and runs
both complete drivers on fixture 001 at the relative runtime. The program
has no UB: its equal execution result is a control, not evidence of equal
classification or equal UB-location selection.

### P2-2 — linked library/user round trip

`CoreQuoteCompare.original` now has an independent `linked` mode: load the
library first, carry its returned supply into every user frontend call,
cons each TU onto the library list, then call `link` and `convert_file`.
Metadata and user inputs are separate arguments. No printer operation builds
the expected value. `--libc --module PATH --input JSON ...` checks an external
linked module with the canonical metadata; repeated inputs retain driver
argument order. `--libc` without `--module` runs both the standalone library
and fixture 001 linked to it. Standalone `--libc --module PATH` still checks
the pinned library literal.

Re-traced the library's construction, all nine map fields through
`link_aux` and its reverse-cons fold, and every conversion field. The linked
syntax vector in field order is **L,S,S,I,L,E,L,N,N**:
`tagDefs, enumDefs, stdlib, impl0, funs, extern, funinfo, loop_attributes1,
visible_objects_env0`. The canonical library's tagDefs/funs/funinfo have outer `.mk L` and are the
final left union operands; an outer `.mk` would still win with an empty tree.
`libcMapFromAssoc` starts at `.empty`, so an empty association list would
remain `.empty`; the canonical metadata/dump supplies entries for all three. Its enum/Nat
fields are `.empty`, so TU S/N wins when present; stdlib/impl are shared S/I;
extern is rebuilt by E insertion. The test skips only a literal `.empty`,
whose outer constructor the whole-file comparison independently checks.
S/O/L remain distinct syntax, never reduced into interchangeable comparators.
This agrees with the verified D0 table; no additional producer or union-path
difference was found. The rebase changes none of the audited construction
sources (`Main`, `CoreParser`, translation/effects, linking/conversion, or the
unused typing/rewrite/sequentialise producers); both original run points and
F1/F2 remain as recorded. Relevant checked sites: `Core_linking.lean:444-496`
(`safe_map_union`, every `link_aux` field, fold); `Core_run_aux.lean:931-952`
(`convert_file`); `LemLib.lean:1271-1274` (outer-constructor union).
Current driver anchors are `Main.lean:46,61` (shared stdlib/impl), `:256`
(libc insertion fold), `:793` (loadLibc), `:1163-1205` (library-first supply
and reverse-cons origin/file accumulation), and `:1257` (conversion).

### P3 and driver refusal

The rebase table above preserves historical measurement identities and maps
D0–D4 to the committed series; the consumer note uses the new base and D0.
Tier B probes GNU `time` on PATH (`gtime`, then `time`) before doing work and
fails with a named prerequisite message if neither is GNU. LADDER row 13
and the boundary entry declare this dependency.

The printer retains its ten panic-class indexing/update sites under the
explicit instrument-only exemption in VALIDATION §3, beside the partial
definitions. The allocation/post-order/bounds invariants, native abort setting
and kernel-transparent panic are stated there. This is the P3 alternative
chosen after F12; no theorem or failure-reach gate/register change was added.

`--quote-core` with `--libc` and no user TU now refuses with exit 2 and names
`--quote-libc` as the standalone operation. The Tier B test checks the refusal
and absence of output before loading the large literals.

### F11 — linked replay exposed the test alias lifetime

The first expanded Tier B row failed (exit 1): standalone libc and linked
fixture 001 both elaborated and passed representation/comparator/auxiliary
BEq comparison, but `leanchecker LinkedLiteral` raised a too-many-symbolic-links
exception. Libc's preceding cwd control had left `root-alias` beneath the
scratch module search root; replay recursively followed it back into that
root. This is a test orchestration failure, not a passing replay or a changed
execution baseline. The failed row took 334.90 s, 14,889,816 KB peak RSS.

Before editing or rebuilding, the dirty source tree including untracked draft
58 was preserved at `refs/snapshots/core-quote-d5-checker-symlink-20261020`,
commit `f3492ddbc4a2a7dbf9d357dd901143c8894d05aa`; branches and the normal
index were unchanged. [AGENT 2026-10-20] Scope the alias to its byte-comparison
control and unlink it in `finally`, including failures, before any subsequent
kernel replay. Re-run the expanded row and consumer interface; do not weaken
replay, move the literal pin or keep recovery artifacts after successful repair.
Removing the failed run's alias made replay of the same elaborated
`LinkedLiteral` succeed immediately (exit 0); no literal or environment
artifact was rebuilt for that diagnostic.

### F12 — the attempted failure wrappers lack census owners

The first D5 Tier A run **failed A1** after 657.2 s. The failure-reach
self-test reported both proposed quotation `failwithI` sites as
`UNRESOLVED-OWNER`, not as established non-exec sites. Its environment
(`tests/failure-probes/FailureReach.lean`) does not import `CerbQuote`; its
compiler-range ownership rule therefore cannot identify those declarations.
Making the helpers public would not supply the missing module environment.
The earlier focused build had also caught a namespace typo in those helpers
(`LemLib.failwithI` instead of `failwithI`), corrected before this failed gate.

Stopped the owned release runner after A1 failed. By termination A2 had
passed and A3 was interrupted. Before editing or rebuilding, preserved all dirty sources and untracked draft 58 at
`refs/snapshots/core-quote-d5-tier-a-20261020`, commit
`5d8e736c52f6f1b6d605924300c3d20d8cc5d3cb`, without changing a branch or the
normal index. This was an interrupted, failed partial run, not Tier A success.
Its report retained unchanged source and complete selection:

```text
fast: incomplete; 1/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

[AGENT 2026-10-20] Use P3's expressly permitted indexing exemption rather
than expand the failure-reach tool's import surface outside the D5 fence.
Restore the accepted printer's original access code; document all ten sites
and their source-level invariants beside its partial definitions, including
native abort and kernel transparency. The trust-surface gate and register
remain intact. Rebuild, run the focused failure-reach check and the expanded
Tier B row, then repeat all of Tier A on the final implementation. The recovery
refs are disposable once those checks complete and the fix is committed.

### D5 verification

The focused build (`make lean-prelude-src`, then capped
`lake build cerberus-lean core-quote-test`) passed, 530 jobs. No warning in
CerbQuote or the Core quotation test files; the existing out-of-scope warning
ownership remains as in F6, without suppression. The runtime witness/selftest
passed all 19 witnesses, catching both stub plants. Its measured divergence:

```text
check_runtime_resolution: fixture-001 --runtime=_build/install/default: 154 ./-prefixed header positions; oracle library=false; port library=true; oracle without ./=true (declared divergence)
```

Both actual drivers returned the same complete `Defined` line with
`Specified(42)` for this fixture. Missing-tool and non-GNU-version plants
both gave exit 2 with `Core quote prerequisite: GNU time is required`.

The focused first-fixture round trip and all mutation/local controls passed,
including the same-head/different-instance comparator rejection, NaN refusal,
and canonical cwd controls. The separately converted libc round trip passed
with the unchanged SHA-256
`30bdb3f5db037b5a63a3deaa24cba27f289bd7841770d1e1ebff43699dcbfe06`.

The external linked-module invocation passed:

```sh
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/core-quote-d5/Linked.lean \
  --input tests/fixtures/001-return-literal/cabs.json
```

The input was the unmodified 33,187,748-byte flag-written module, copied from
the first row's disposable scratch before its removal. It passed independent
elaboration, whole-file representation, exact comparator syntax, auxiliary
BEq, both-position-path census, alias byte comparison and wrong-cwd refusal.
Whole consumer command: **159.32 s, 14,891,192 KB peak RSS, exit 0**;
elaboration alone: 146.41 s at the same peak; comparison: 5.10 s. Its census
is 234 distinct model constructors, 28 floating leaves, 0 NaNs, 0 memory
values, 15,652 positions and 0 absolute position paths.

```text
LinkedLiteral leanchecker: 1.97 seconds; 825744 KB peak RSS; exit 0
```

[AGENT 2026-10-20] Keep the linked round trip beside standalone libc in Tier B
row 13: the measured elaboration cost is libc-sized. Row 1 retains the fixture,
corpus and user-only multi-TU checks. The cost is a speedbump measurement, not
a new resource gate. The GNU-time dependency and both replay module names
are declared in LADDER and VALIDATION. No theorem, axiom, native_decide,
unsafe declaration, extern seam or resource-limit increase was added.

The replacement `scripts/test_unit.sh --core-quote-libc` run passed, exit 0,
**297.79 s, 14,895,476 KB peak RSS**. Both standalone and linked literals
passed alias determinism and the convention-naming exit-2/no-output refusal.
The two-case census is 234 distinct model constructors, 56 floating leaves,
0 NaNs, 0 memory values, 31,238 positions and 0 absolute position paths.
Named replay gates, against independently elaborated literals with no plugin:

```text
LibcLiteral leanchecker: 1.86 seconds; 825628 KB peak RSS; exit 0
LinkedLiteral leanchecker: 1.88 seconds; 825816 KB peak RSS; exit 0
CORE_QUOTE_TOTAL inputs=2; model constructors=234; floating=56; NaN=0; memory-values=0; positions=31238; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 1 passed, 0 failed
```

The replacement row's libc elaboration took 138.27 s and its linked
elaboration 130.04 s. The external consumer measurement above is retained
as the consumer-shaped cost; ordinary run-to-run timing variation changes
neither gate outcomes nor the committed pin. F11's failed scratch directory
was removed after its diagnostic replay; the recovery ref is removed at D5
close-out once its preservation purpose has been served.

The successful measurements above precede the F12 indexing-exemption
resolution; final-code results follow below.

After restoring the accepted indexing implementation, the focused build passed
(530 jobs), and `scripts/check_failure_reach.sh --selftest` passed: eight
plants, seven classifier witnesses, K1/R1 ownership witnesses, and the actual
register check (239 sites exactly, 0 DISCARDABLE, no position-class change).
No gate, register or allowlist was changed to obtain this result.

Final-code Tier B row 13 (`scripts/test_unit.sh --core-quote-libc`) passed:
**321.41 s, 14,894,212 KB peak RSS, exit 0**. Standalone and linked modules
both passed whole-file/comparator/auxiliary checks, the absolute-position
census, alias byte equality and the convention-naming exit-2/no-output
control; the libc-only program refusal also passed. The libc pin is unchanged.
Final-code named kernel gates, with no test plugin:

```text
LibcLiteral leanchecker: 1.94 seconds; 825808 KB peak RSS; exit 0
LinkedLiteral leanchecker: 2.01 seconds; 826336 KB peak RSS; exit 0
CORE_QUOTE_TOTAL inputs=2; model constructors=234; floating=56; NaN=0; memory-values=0; positions=31238; absolute-paths=0
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 1 passed, 0 failed
```

### Final D5 gate and close-out

Final Tier A ran 2026-10-20 **07:29:52–07:53:17 UTC**, process exit 0:

```sh
python3 scripts/release.py --mode fast --out .tmp/core-quote-d5/fast-final
```

The shell-local environment set `CERB_MEM_MAX=48G` and
`LEAN_ABORT_ON_PANIC=1`; `make lean-prelude-src` preceded the capped runner.
All nineteen lane exit statuses were 0, containment was cleaned for every
lane, the source was unchanged, selection was complete, and the report had
no artifact issues. Exact release summary:

```text
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Row 1 passed 20/20 executables and all its trust checks, including the unchanged
239-row failure-reach register and the new runtime-classification witness.
All 27 fixture/corpus/user-only multi-TU comparisons passed. The libc execution
lane retained all 43 baseline cases; libxml2 URI retained all 16 cases and
lane expectations. No execution baseline, literal hash pin, generated type,
comparator construction, parser or stored position label changed.

The final required population is 29 round trips (27 user-only, standalone
libc, linked libc + fixture 001): **248 distinct model constructors, 56
floating leaves, 0 NaNs, 0 memory values, 8,540,800 positions, 0 absolute
position paths**. Containers: 100 `Fmap.empty`, 161 `Fmap.mk`, 7,292
`Pmap.Node`, 7,453 `Pmap.Empty`, 66,207 `Pset.Empty`, 0 `Pset.Node`,
15,449,289 `List.cons`, 23,833,703 `List.nil`. Unobserved memory values and
nonempty Psets remain supported by the complete visitor/printer inventory.
Required-input construct refusals: 0; the separate NaN control still refuses
by name. The external linked-module check and final-code Tier B row/replays
are quoted above. D4's full A+B run remains historical; D5 ran the requested
complete Tier A and the changed Tier B row, not a new full A+B campaign.

Both D5 recovery refs were removed with their expected object IDs after the
repairs and final checks served their preservation purpose:
`refs/snapshots/core-quote-d5-checker-symlink-20261020` and
`refs/snapshots/core-quote-d5-tier-a-20261020`. The D3 recovery ref requested
removed at D4 remains absent. Disposable D5 literals, traces, build/gate logs,
probe binaries and owned scratch directories are removed at close-out; the
conclusions and reproduction commands are retained here. The active worktree
and its build remain available for the fresh audit. After the gates, only
result/coverage/close-out documentation and disposable artifacts changed.
The single D5 commit records the verified checks; no merge or push was made.
