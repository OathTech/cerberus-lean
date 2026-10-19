# Core quotation for cerberus-caesium

Status (2026-10-19): D2b path guard and canonical metadata export implemented;
parked on the F7/F8 determinism findings. The independent whole-file round-trip
test remains for D3. Base
`e7e9bb427a514b6053865c303c4af512907da75b`; D0 checkpoint
`fb8705c686d1de34f66426e3da4f1477d077632e`.

## Relation and intended extraction point

[USER 2026-10-18 relayed] The selected deliverable is a declared-boundary
quotation instrument. It preserves the representation of the executed
`file core_run_annotation`; the consumer owns the subsequent lookup lemma.
It is not a proof of equality with the frontend's result.

The driver value is `runFile := convert_file coreFile` at `Main.lean:1252`,
after the final link. A second quotation covers `convert_file libcFile`
for the result of `loadLibc`, before the user link. The emitted module imports
`Core_run_aux`, uses private typed subterm helpers,
and declares one public `def quotedCore : file core_run_annotation`. It imports
no printer code and uses the pinned toolchain's default elaboration limits.

From the repository root, after the normal build (including
`make lean-prelude-src` before each capped Lake build):

```sh
export LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime ./_build/install/default --fuel 1000000 \
  --quote-core .tmp/Fixture.lean tests/fixtures/001-return-literal/cabs.json
(cd lean_frontend && ../scripts/capped lake env lean ../.tmp/Fixture.lean)
```

Create the output directory first. The runtime's library directories and
imported library locations must resolve to the same directories. D2b accepts
absolute/relative aliases and symlinks but preserves all stored positions.
For portable libc metadata, run `scripts/libc_prep.sh --jsons OUTDIR`; it
exports from the project root using `--runtime=_build/install/default` and
relative source/include paths. Consume those JSONs from the project root and
use `--runtime _build/install/default` for portable quotation artifacts.
D2b's guard change alone does not make output independent of runtime spelling:
parsed `std.core` and `.impl` positions still carry that spelling (record F7).
The alternate-working-directory invocation refuses because relative stored
locations have no explicit project origin (record F8). Implementation is
parked under the operator's refusal stop rule, pending a path-origin and
parser-construction policy. No cross-machine determinism claim is made.
Supply `--libc tests/libc/libc.core`
and one `--libc-tu META.json` per metadata TU, in `scripts/libc_prep.sh` order.
Use `--quote-libc .tmp/Libc.lean` to quote that loader result after conversion,
once. It can be combined with `--quote-core .tmp/Linked.lean` and multiple
user JSON inputs, or used alone with no user input. The record's D2 probe
contains a complete preparation and invocation recipe.

Quotation stops before execution. Success is silent with exit 0; named
quotation failures use `Error {msg: ...}` and exit 1. All requested values
are rendered before any output is published, so a refused value leaves
every destination untouched. Each successful source is published by rename;
an IO failure is an error and can leave an earlier complete output when
two destinations were requested. `--batch` is accepted; execution-observation
flags and `--pp-core` conflict with quotation and are refused. The two
quotation flags require distinct output paths.

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
That entry remains for D4 and will name the instrument's partial definitions,
which are outside the model execution cone.

The printer covers all 75 model datatype heads / 638 constructors, six scalar
types and six container types, including every memory-value constructor.
Its data-domain refusal is `Float.NaN`, qualified with the enclosing file
field; missing, inconsistent or inadmissible comparator provenance is also
refused by name. The public API is
`CerbQuote.moduleSource provenance file : Except CerbQuote.Refusal String`.
Use `translatedProvenance` only for audited translated TUs and `libcProvenance`
only for the library loader result. Retain the driver's reverse-consed list
of origins and use `linkedProvenance` with the successful linked file before
quoting its converted value. Arbitrary maps cannot be validated by inspecting
comparator closures.

D1's focused probes successfully quoted and elaborated the first committed
fixture and converted libc. The libc output is 33,832,667 bytes with 13,318
private helpers; elaboration took 144.99 seconds and 12,055,992 KB peak RSS
(exit 0, cap 48G). Five float cases and a set/comparator case have evaluated
representation assertions. The record gives commands, failures that motivated
the emission design, and final gate results. This evidence does not establish
the complete whole-file relation.

Required-input occurrence counts, the full NaN census, all round trips and
all mutation controls remain for D3. The required population is ten committed
Cabs JSON fixtures, sixteen corpus C files, a linked cross-TU declaration/reference
example, and converted libc. No additional construct refusal is currently
implemented. Full required-set acceptance is not claimed at D2.

D2's actual flags also emitted and elaborated the committed first fixture,
a libc-linked two-TU program and the standalone converted libc. The latter
two elaborations took 101.36 / 100.11 seconds and about 12.1 / 12.1 GB peak
RSS. Library-only output agrees with the separately emitted library. Named
NaN refusals preserve destinations; argument and output-error controls pass.
These are elaboration and CLI checks, not D3's independent round trip.

The D2 precommit Tier A run passed all nineteen commands (exit 0), with
source unchanged during the run; its exact summary is quoted in the record.
F6 distinguishes the nine warnings visible in the baseline build from the
337 warnings replayed when building the seam, and records separate ownership
of the backend-emission backlog and test hygiene. No warning suppression was added.

D2b's precommit Tier A passed all nineteen commands, exit 0, with source
unchanged; the record quotes its summary and the failed determinism probes.
The existing libc execution and libxml2 URI baselines remain unchanged.
The operator placed the future libc round trip in a named Tier B row and
requires the test executable to accept consumer-generated flag modules;
fixture/corpus and multi-TU round trips remain in row 1. D3's portable hash
pin and kernel-replay cost measurement remain outstanding at this park.
