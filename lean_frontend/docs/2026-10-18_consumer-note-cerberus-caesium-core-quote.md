# Core quotation for cerberus-caesium

Status (2026-10-19): D0 audit only; the quotation flag, printer and round-trip
test are not implemented at this checkpoint. Base
`e7e9bb427a514b6053865c303c4af512907da75b`.

## Relation and intended extraction point

[USER 2026-10-18 relayed] The selected deliverable is a declared-boundary
quotation instrument. It preserves the representation of the executed
`file core_run_annotation`; the consumer owns the subsequent lookup lemma.
It is not a proof of equality with the frontend's result.

The driver value is `runFile := convert_file coreFile` at `Main.lean:1212`,
after the final link. A second quotation covers `convert_file libcFile`
for the result of `loadLibc`, before the user link. The eventual module
must elaborate under the project's pinned toolchain and imports. Its flag
invocation and definition name will be documented when D2 lands.

Every record field, scalar, annotation, initializer, constructor and
container payload belongs to the relation. `Fmap.empty` stays `.empty`;
`Fmap.mk` preserves the captured comparator term selected from verified
provenance and the entire `Pmap` tree, including cached heights. `Pset`
trees preserve shape, elements and heights. Non-NaN floats preserve bits,
including both zero signs and infinities. NaNs are refused by name.
The primary whole-file comparison must recurse structurally; ordinary
map/set `BEq` loses tree information and ctype `BEq` loses annotations.
Generated whole-file `BEq` is an additional check on admitted inputs,
and a false result remains a failure. Stored-key lookups alone cannot
identify a comparator.

## Verified comparator provenance

The complete construction audit, exact terms and current source locations
are in [the D0 record](2026-10-18_core-quote-record.md#verified-field-provenance).
Its monomorphic comparator vocabulary is:

```lean
-- S
@Lem_Map.MapKeyType.mapKeyCompare sym
  (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)
-- O
@Lem_Basic_classes.ordCompare sym instEq0Sym_1 instOrd0Sym_1
-- L
symbol_compare
-- I
implementation_constant_compare
-- N
@defaultCompare Nat instOrdNat
-- E
fun (a b : identifier) =>
  match a with
  | .Identifier _ sa =>
    match b with
    | .Identifier _ sb => @defaultCompare String String.instOrd sa sb
```

| Field | Translated TU construction | Standalone libc construction | Final link / conversion |
|---|---|---|---|
| `tagDefs` | `fromList S` | fold insertion with `L` | outer-constructor-sensitive union / retain |
| `enumDefs` | `fromList S` | `.empty` | same union / retain |
| `stdlib` | shared `loadCoreStdlib`, `fromList S` | same shared map | take first argument's field / map values |
| `impl0` | shared `loadCoreImpl`, insert `I` | same shared map | take first argument's field / map values |
| `funs` | insert `O` from `.empty`, both declarations and definitions | fold insertion with `L` | outer-constructor-sensitive union / map values |
| `extern` | insert `E` from `.empty`, then map values | linked metadata's external map | `link_extern`'s insertion fold with `E` / retain |
| `funinfo` | insert `O` from `.empty`, all proxy/declaration/definition branches | fold insertion with `L` | outer-constructor-sensitive union / retain |
| `loop_attributes1` | insert `N` into initially empty desugar state | `.empty` | outer-constructor-sensitive union / retain |
| `visible_objects_env0` | insert `N` into initially empty elaboration state | `.empty` | disjointness-checked union / retain |

Union retains a left `.mk` comparator even if its tree is empty; it takes
the right comparator only when the left is `.empty`, and two `.empty`
operands yield `.empty`. The explicit comparator argument to union is
ignored. `link` folds with `link_aux next accumulated`; combined with
the driver's reverse-consing, union provenance prefers the earliest
original input having an outer `.mk`, with libc first when present.
Conversion's value maps preserve the outer constructor and tree heights.

Differences from the charter's provenance-path table are findings F1/F2
in the record: the constant-expression mini-pipeline constructs and
converts an additional dummy file, and Core typing/rewriting/sequentialising
provide other file transformations. The mini-run's file remains internal;
the other three functions have no production callers on this driver path.
Core typing would rebuild `stdlib`/`funs` with `S` and `impl0` with
`@Lem_Map.MapKeyType.mapKeyCompare implementation_constant
(@Lem_Map.instMapKeyTypeOfSetType implementation_constant
instSetTypeImplementation_constant_1)`; it retains the other six maps.
Rewriting and sequentialising preserve map representations. This audit
is not a guarantee about
arbitrary `file` values supplied by other producers. Both actual driver
link sites (libc metadata and final user link) were traced. Generated
Translation citations have also drifted; the record gives current lines.
No conflicting comparator ordering was found at the declared quotation
point.

The derived `labeled` and `core_extern` maps are outside the file quotation.
Their constructors were audited separately: both create maps with `O`;
`collect_saves` also follows the two outer-constructor union branches.

## Boundary and outstanding acceptance

The intended `VALIDATION.md` boundary entry is the Core quotation instrument:
representation comparison and source-inspected comparator provenance are
computed evidence, kernel-opaque as a link to the pipeline. The named
boundary mover is the printer-correctness bridge (charter option B).
That entry is not yet installed at D0.

The type inventory is complete: 75 model datatype heads / 638 constructors,
six scalar types and six container types. Required-input occurrence counts,
NaN absence, any additional named refusals, all round trips and all mutation
controls are still to be measured. D0 does not claim any input was quoted.
The required population is ten committed Cabs JSON fixtures, sixteen corpus
C files, a linked cross-TU declaration/reference example, and converted libc.
The final invocation, module shape, refusal counts and test results remain
for D1–D4.

The untouched-base Tier A run passed all nineteen commands (exit 0), with
source unchanged. The record also identifies nine existing compiler
warnings outside the slice's edit fence; no warning suppression was added.
