# Core quotation for cerberus-caesium

Status: D5 is complete. Final Tier A passes 19/19 commands, and Tier B row 13
passes both standalone and linked libc round trips and kernel replays.
D5 addresses the pre-merge audit with linked-libc coverage and an explicit
runtime divergence; D4's full A+B close-out remains the earlier full run.
Gate results and the pre-rebase → committed history map are in
[the record](2026-10-18_core-quote-record.md). Current base `2e1777b27`;
committed D0 checkpoint `6d2543c9217296b239fcdb0c6a4a9d95c2228d31`.

## Relation and intended extraction point

[USER 2026-10-18 relayed] The selected deliverable is a declared-boundary
quotation instrument. It preserves the representation of the executed
`file core_run_annotation`; the consumer owns the subsequent lookup lemma.
It is not a proof of equality with the frontend's result.

The driver value is `runFile := convert_file coreFile` at `Main.lean:1257`,
after the final link. A second quotation covers `convert_file libcFile`
for the result of `loadLibc`, before the user link. The emitted module imports
`Core_run_aux`, uses private typed constructor helpers,
and declares one public `def quotedCore : file core_run_annotation`. It imports
no printer code and uses the pinned toolchain's default elaboration limits.

From the repository root, after the normal build (including
`make lean-prelude-src` before each capped Lake build):

```sh
export LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 \
  --quote-core .tmp/Fixture.lean tests/fixtures/001-return-literal/cabs.json
(cd lean_frontend && ../scripts/capped lake env lean ../.tmp/Fixture.lean)
```

Create the output directory first. The **canonical Core quotation convention**
is to export metadata and invoke the Lean driver with exactly
`--runtime=_build/install/default`, from the project root. Consumers may use a
directory containing a fixed relative runtime link at that location, as
cerberus-caesium does. The stored relative header paths must resolve there.
`scripts/libc_prep.sh --jsons OUTDIR` produces metadata under this convention.
A symlink alias of the project root preserves the same literal bytes.

The path guard compares resolved directories for exact membership; stored source
and lexing labels are never rewritten. F7 records why absolute runtime spelling
changes the artifact. F8 records why running from `lean_frontend/` with
`../_build/...` refuses: the metadata's relative header paths do not resolve
there. These are the convention's positive and negative cases, not promises of
invariance under arbitrary runtime spelling or working directory. A refusal
names the convention and writes no module.

Update [AGENT 2026-10-26] (quotation hygiene Q1; [USER 2026-10-21] ruling B
of the D5 re-review): the fork ORACLE now classifies by the same rule as this
guard — suffix AND resolved membership (`util/cerb_location.ml`
`is_library_location`, a fork-ahead delta over pristine's literal
`<runtime-as-given>/<dir>` comparison; [upstream draft 58](upstream-tray/58-relative-runtime-library-location.md)
is the report, its remedy implemented in the fork). The divergence class the
D5 text below this paragraph described — an absolute or `./` label under the
relative runtime, a relative or `./` label under an absolute one, a `#line`
alias, on which the served UB location differed (oracle `<2:10--2:15>`, port
`<11:10--11:23>`) — NO LONGER EXISTS: `scripts/check_runtime_resolution.sh`
now pins both classifiers agreeing on fixture 001's `./` label and four
`#line` plants (`./`, unprefixed, absolute, `libcore`) served at the same
call site `<11:10--11:23>` by both engines. A consumer executing the quoted
file inherits a classification both engines share. The quoted labels/value
are unchanged by this.

Update [AGENT 2026-10-26] (quotation hygiene Q2; [USER 2026-10-21] ruling C): the
convention is now ENFORCED when quoting. `--quote-core`/`--quote-libc` REFUSE — a
REFUSAL envelope on stderr, boundary `runtime`, item `--runtime`, exit 2, empty
stdout, no module written — unless the runtime is given on the command line with
the value `_build/install/default` (either `--runtime=` or `--runtime ` form; an
absolute spelling, or the runtime taken from `CERB_INSTALL_PREFIX`, is refused
naming that spelling) AND every source label AND every lexing label of every
input (your TUs and the libc metadata TUs) is portable: relative and under the
project root. An input exported under an absolute runtime carries absolute
labels and is refused naming the first such label; so does an input exported
from an ABSOLUTE SOURCE PATH, whose `lexing_file` labels are absolute even when
a `#line` rename makes its `file` labels relative (fixed 2026-10-27, pre-merge
review P1-1; the first version checked `file` only). Re-export from the project
root with the canonical runtime spelling AND a project-relative source path
(`scripts/libc_prep.sh --jsons` for the metadata). Your recipe above already
satisfies both conditions (the fixed relative runtime link at
`_build/install/default` in your directory is the canonical spelling). Execution
with `--batch` is unaffected. The re-review's P3-1 observation that non-portable
literals were emitted silently no longer holds.

Update [AGENT 2026-10-26] (quotation hygiene Q6; the re-review's P3-2): the linked
population now includes a second, richer two-TU case
(`test/CoreQuote/inputs/linked/tu{1,2}.c`: an enum definition in each TU, a cross-TU
extern object, statics with initializers, a loop), libc-linked in Tier B row 13
(`LinkedRich`, with its own `leanchecker` replay) and user-only in row 1 (`MultiRich`),
so the comparator positions for `enumDefs`, visible objects and loop attributes carry
TU-side values rather than `.empty` on both sides; the fixture-001 figures quoted in
the sections above are the historical D5 population.

Supply `--libc tests/libc/libc.core`
and one `--libc-tu META.json` per metadata TU, in `scripts/libc_prep.sh` order.
Use `--quote-libc .tmp/Libc.lean` to quote that loader result after conversion,
once. It can be combined with `--quote-core .tmp/Linked.lean` and multiple
user JSON inputs, or used alone with no user input. A standalone Bash recipe,
from the project root, is:

```bash
mkdir -p .tmp/core-quote
scripts/libc_prep.sh --jsons .tmp/core-quote/metadata > .tmp/core-quote/metadata-paths
mapfile -t metadata < .tmp/core-quote/metadata-paths
libc_args=(--libc tests/libc/libc.core)
for path in "${metadata[@]}"; do libc_args+=(--libc-tu "$path"); done
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 \
  --quote-libc .tmp/Libc.lean "${libc_args[@]}"
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 "${libc_args[@]}" \
  --quote-core .tmp/Linked.lean tests/fixtures/001-return-literal/cabs.json
```

Quotation stops before execution. Success is silent with exit 0; named
quotation failures use `Error {msg: ...}` and exit 1. All requested values
are rendered before any output is published, so a refused value leaves
every destination untouched. Each successful source is published by rename;
an IO failure is an error and can leave an earlier complete output when
two destinations were requested. `--batch` is accepted; execution-observation
flags and `--pp-core` conflict with quotation and are refused. The two
quotation flags require distinct output paths. `--quote-core` with `--libc`
but no user TU refuses with exit 2; use `--quote-libc` for the library alone.

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

The complete construction audit, exact terms and source locations verified at D0
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
For a linked library/user file, the independent syntax vector in table order
is **L,S,S,I,L,E,L,N,N**. Libc's outer `.mk L` wins for tagDefs/funs/funinfo;
its `.empty` enum/Nat fields yield the TU's S/N when present. The whole-file
comparison checks every outer constructor; no comparator is demanded of
`.empty`, and no equal-behaving comparator is substituted.

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
Translation citations drifted from the charter; the record gives the D0-verified lines.
No conflicting comparator ordering was found at the declared quotation
point.

The derived `labeled` and `core_extern` maps are outside the file quotation.
Their constructors were audited separately: both create maps with `O`;
`collect_saves` also follows the two outer-constructor union branches.

## Reproducing the round trip

After the normal driver build, build the consumer-runnable test:

```sh
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build core-quote-test)
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 --libc
```

The first test invocation runs all ten committed Cabs fixtures, all sixteen corpus
inputs (including `p10alt_rsum_rec.c`), and `tests/multi_tu/basic`'s cross-TU
`helper` declaration/reference. The second test invocation checks both the
separately converted libc and fixture 001 linked with its twelve metadata TUs.
The ladder invokes these through `scripts/test_unit.sh` (row 1) and
`scripts/test_unit.sh --core-quote-libc` (Tier B row 13), respectively.

To witness a flag-generated module in a consumer checkout at the same pin,
run from that checkout's root:

```sh
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --module .tmp/Fixture.lean --input tests/fixtures/001-return-literal/cabs.json
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/Libc.lean
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/Linked.lean --input tests/fixtures/001-return-literal/cabs.json
```

For a user-only quotation, repeat `--input` for linked TUs in driver argument
order. `--libc --module` without `--input` checks the separately converted
library module; adding `--input` selects the linked mode, again in driver
argument order. Both regenerate the same twelve metadata TUs. The committed
hash applies only to the standalone library, not to a user-specific linked module.
The test uses the default switches and address-space top and the supplied fuel;
quote the module with those same settings. Libc mode regenerates its twelve
canonical metadata TUs; the standalone check verifies the committed hash.
The driver subprocess always runs with the project root as its cwd and the exact canonical runtime
spelling. The test needs the normal OCaml/Lean build and GNU `time` for the libc
replay/elaboration measurements (probed as `gtime` or `time` on PATH;
absence or a non-GNU implementation fails by name). Scratch artifacts are
removed on success; failures identify
the disposable diagnostic directory.

The literal is elaborated independently, then imported into a checker module.
[`test/CoreQuote/CoreQuoteCompare.lean`](../test/CoreQuote/CoreQuoteCompare.lean) rebuilds the original from public pipeline stages, ending
with `convert_file`. It is compiled as test support so large frontend traversals
use native Lean rather than the interpreter stack. The test plugin is loaded
only for comparisons and controls; independent literal elaboration and kernel
replay do not load it. The test visitor is generated by [`test/CoreQuote/CoreQuoteVisitor.lean`](../test/CoreQuote/CoreQuoteVisitor.lean)
from the datatype declarations, without importing or reading the printer. It
compares tagged constructor/scalar trees: all fields, outer Fmap constructors,
Pmap/Pset shape and cached heights, ctype annotations and floating bits. Lists
use a flat, length-and-order-preserving view to handle million-element array
initializers without recursive cons frames; the census counts their cons/nil
constructors. Long quoted lists themselves use typed literal-cons blocks, sharing identical
blocks as functions of their tail and sharing closed tails. The output uses
constructor applications, with no append/from-list/replicate builder. No
printer text or printer `Term` is used as equality. The additional generated
whole-file `BEq` must also succeed, on the NaN-free domain only.

The comparator check inspects elaborated expressions using a separate S/O/L/I/N/E
specification. It expands only quotation helpers to expose file/map constructors.
For comparator expressions it expands elaborator-registered matchers, erases
metadata and alpha-renames binders, since those names vary with module elaboration.
It retains every comparator constant and explicit dictionary argument, without
reducing S/O/L or identifying them by their behavior. The same-head/different-instance
mutation fails this check; an absent symbol alias is found by the active comparator
and missed by the structural comparator. The remaining controls change main, a
global initializer, a map binding, a cached height with identical inorder bindings,
both empty/mk-empty directions, and a zero's sign. Unchanged signed zeros and
both infinities pass. A varied 257-element list passes and its reversed-order
mutation fails, exercising the long-list block boundaries. NaN is tested
separately as a named refusal.

## Boundary and coverage

The [Core quotation instrument boundary in VALIDATION §3](../VALIDATION.md#core-quotation-instrument-boundary)
names the printer's seventeen partial definitions, the test's partial visitor,
comparison/census and syntax traversal, its development generator and D0 inventory probe, native test
plugin and shared digest compilation, the Lake trace-schema dependency, and
the instrument-only exemption for its ten panic-class sharing-plan accesses
(record F12). The recipes enable `LEAN_ABORT_ON_PANIC=1`; the relevant
post-order/bounds invariants are source evidence, not a kernel proof.
All are instrument code outside the model execution cone. Representation
comparison and source-inspected comparator provenance are computed evidence,
kernel-opaque as a connection to the pipeline. The named mover is the
printer-correctness bridge (charter option B); this delivery is option A.

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

The D3 round trips cover ten committed Cabs JSON fixtures, all sixteen corpus
C files, one linked cross-TU declaration/reference case, and converted libc.
The fixture/corpus/multi-TU population exercises 214 distinct model constructors
and 8,509,562 positions; it contains no floating leaves, NaNs, memory values or
absolute position paths. All 27 comparisons pass. The complete run, including
mutations and cwd controls, took 202.94 seconds and 10,498,784 KB peak RSS,
exit 0, under the 48G cap. These are measurements, not resource limits.

F9 in the record documents the required million-element array's initial
elaboration failure and the typed-cons-block repair. No generated type,
parser, label, comparator construction, execution baseline or elaboration limit
changed. The required-input round trips validate the repaired renderer; D1/D2's
earlier elaboration-only evidence is retained in the record.

F6 distinguishes the nine warnings visible in the baseline build from the
337 warnings replayed when building the seam, and records separate ownership
of the backend-emission backlog and test hygiene. No warning suppression was added.

The standalone libc check also passes, using a module written by `--quote-libc`
and supplied through the consumer `--module` interface. Its literal is
33,169,038 bytes. Elaboration took 145.48 seconds, independent comparison
4.66 seconds, and the complete consumer check 158.25 seconds with 14,880,132 KB
peak RSS, exit 0. No limits were increased.

| Required population | Distinct model constructors | Floating leaves | NaNs | Memory values | Positions | Absolute position paths |
|---|---:|---:|---:|---:|---:|---:|
| 10 fixtures + 16 corpus + linked multi-TU | 214 | 0 | 0 | 0 | 8,509,562 | 0 |
| Converted libc | 224 | 28 | 0 | 0 | 15,586 | 0 |
| Combined | 248 | 28 | 0 | 0 | 8,525,148 | 0 |

The combined census sees 97 `Fmap.empty`, 155 `Fmap.mk`, 5,706 `Pmap.Node`
and 5,861 `Pmap.Empty` occurrences. All 40,734 observed Psets are `Pset.Empty`;
nonempty Psets and memory values are supported but absent from the required
population. The constructor visitor covers those unobserved constructors too.
There is no additional construct refusal beyond NaN; required-input refusals: 0.
The NaN negative control separately observes `globs.Float.NaN`.

The committed pin in [`test/CoreQuote/core-quote-libc.sha256`](../test/CoreQuote/core-quote-libc.sha256) is:

```text
30bdb3f5db037b5a63a3deaa24cba27f289bd7841770d1e1ebff43699dcbfe06
```

The test checks that hash, exact bytes through a symlink alias of the project
root, and the convention-naming exit-2 refusal from `lean_frontend/`, with no
output. Both position filenames are inspected structurally. F9's renderer repair
changes the bytes from D2b's historical experiment; this is the first committed
D3 pin, not a changed execution baseline.

**Kernel-replay measurement:** `lake env leanchecker LibcLiteral` on the
independently elaborated module, Lean 4.32.2, **exit 0; 1.94 seconds wall time;
825,068 KB peak RSS** (GNU `time`, 2026-10-20). The Tier B row reproduces and
prints this measurement. It replays the literal's declarations against its
imported environment; it is not `--fresh` replay of all transitive imports.
Neither elaboration nor replay loads the comparison plugin. This measurement
is available for the consumer's replay-tier decision; it is not a resource cap.

D4's final Tier A passes all 19 commands and full A+B passes all 43, both
exit 0 with unchanged source and complete selection. Row 1 reports 20/20
executables passing; Tier B row 13 reproduces the unchanged libc hash and
convention controls. Its fresh `lake env leanchecker LibcLiteral` measurement
is **exit 0; 2.05 seconds wall time; 825,348 KB peak RSS** (2026-10-20), against
the same independently elaborated literal and imported environment described
above. The [close-out record](2026-10-18_core-quote-record.md#d4-final-gates-and-close-out)
quotes both release summaries and records the scoped F10 test-layout repair.
The independent pre-merge audit is recorded at `167f1360d`; D5 dispositions
and fresh verification are in the record. D4's full-run results above remain
historical measurements, not a claim that D5 reran every Tier B row.

D5 adds the linked library/user population: fixture 001 with the twelve
canonical metadata TUs, checked also through the external
`--libc --module PATH --input JSON` interface. Its flag-written literal is
33,187,748 bytes. The consumer check passed in **159.32 seconds, 14,891,192 KB
peak RSS**, exit 0; elaboration alone was 146.41 seconds and comparison
5.10 seconds. It exercises 234 distinct model constructors, 28 floating
leaves, no NaNs or memory values, 15,652 positions and no absolute position
paths. Both position filenames, the exact comparator vector and the full
representation are checked.

Its independent **`lake env leanchecker LinkedLiteral`** replay passed in
**1.97 seconds, 825,744 KB peak RSS, exit 0** (GNU time, Lean 4.32.2,
2026-10-20). Like libc replay, it loads no test plugin and is not `--fresh`
replay of all transitive imports. This is the consumer's linked-literal replay
measurement. The linked case belongs in Tier B row 13 beside libc because
its elaboration cost is libc-sized; row 1's 27 user-only cases remain there.
F11 in the record describes the initial test-alias lifetime failure and repair.
The repaired complete Tier B row passes both cases in 297.79 seconds at
14,895,476 KB peak RSS, exit 0; its fresh replay measurements are libc
1.86 seconds / 825,628 KB and linked 1.88 seconds / 825,816 KB, both exit 0.
The standalone SHA-256 remains unchanged. After resolving F12 with the
permitted indexing exemption, the final-code row passed again in **321.41
seconds, 14,894,212 KB peak RSS, exit 0**. Its fresh `LibcLiteral` replay was
**1.94 seconds / 825,808 KB, exit 0**, and `LinkedLiteral` replay was
**2.01 seconds / 826,336 KB, exit 0**, with the same no-plugin/imported-environment
scope described above.

The final D5 required population comprises 29 round trips: the 27 user-only
cases plus standalone and linked libc. Together they exercise **248 distinct
model constructors, 56 floating leaves and 8,540,800 positions**, with **zero
NaNs, memory values, absolute position paths or required-input construct
refusals**. They contain 100 `Fmap.empty`, 161 `Fmap.mk`, 7,292 `Pmap.Node`,
7,453 `Pmap.Empty`, 66,207 empty Psets and no nonempty Psets; those unobserved
constructors remain supported. Final Tier A passed all 19 commands on
2026-10-20, with unchanged source and complete selection; its exact summary
and the final-code Tier B measurements are in the D5 record.

## Regenerating and deliberately re-pinning libc

Use a checkout at the intended immutable Cerberus revision with its pinned
Lean/Lem toolchain and the normal OCaml/runtime build from the frontend README.
The artifact depends on that revision, its runtime/dump, and the canonical
invocation convention. Record all three when adopting a new pin. Run the
following Bash commands from the project root; they also produce a fixture
literal for the consumer interface:

```bash
set -euo pipefail
export LEAN_ABORT_ON_PANIC=1 CERB_MEM_MAX=48G
./scripts/capped make lean-prelude-src
(cd lean_frontend && ../scripts/capped lake build cerberus-lean core-quote-test)
mkdir -p .tmp/core-quote-repin
scripts/libc_prep.sh --jsons .tmp/core-quote-repin/metadata \
  > .tmp/core-quote-repin/metadata-paths
mapfile -t metadata < .tmp/core-quote-repin/metadata-paths
[[ ${#metadata[@]} == 12 ]]
libc_args=(--libc tests/libc/libc.core)
for path in "${metadata[@]}"; do libc_args+=(--libc-tu "$path"); done
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 \
  --quote-libc .tmp/core-quote-repin/Libc.lean "${libc_args[@]}"
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 \
  --quote-core .tmp/core-quote-repin/Fixture.lean \
  tests/fixtures/001-return-literal/cabs.json
./scripts/capped lean_frontend/.lake/build/bin/cerberus-lean \
  --runtime=_build/install/default --fuel 1000000 "${libc_args[@]}" \
  --quote-core .tmp/core-quote-repin/Linked.lean \
  tests/fixtures/001-return-literal/cabs.json
sha256sum .tmp/core-quote-repin/Libc.lean
```

For regeneration at the existing pin, leave the committed hash untouched and
run all three consumer checks below. The libc check compares SHA-256 with the pin,
elaborates the external literal, compares its entire representation and
comparator terms with a newly rebuilt original, counts position paths, tests
root/alias determinism and wrong-cwd refusal, and measures kernel replay.

An unexpected hash difference is a failure requiring investigation, never an
automatic re-baseline. Only after an explicitly authorized revision/format
change and review of its cause, replace the pin with the candidate's hash:

```bash
python3 -c 'import hashlib; from pathlib import Path; Path("lean_frontend/test/CoreQuote/core-quote-libc.sha256").write_text(hashlib.sha256(Path(".tmp/core-quote-repin/Libc.lean").read_bytes()).hexdigest() + "\n")'
```

That command is the deliberate re-pin step; skip it when reproducing an
existing pin. Then require the complete checks before committing a changed pin:

```bash
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --module .tmp/core-quote-repin/Fixture.lean \
  --input tests/fixtures/001-return-literal/cabs.json
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/core-quote-repin/Libc.lean
./scripts/capped lean_frontend/.lake/build/bin/core-quote-test --fuel 1000000 \
  --libc --module .tmp/core-quote-repin/Linked.lean \
  --input tests/fixtures/001-return-literal/cabs.json
./scripts/capped make lean-prelude-src
./scripts/capped python3 scripts/release.py --mode fast
./scripts/capped make lean-prelude-src
./scripts/capped python3 scripts/release.py --mode full
```

The libc test reports the `lake env leanchecker LibcLiteral` exit status, wall
time and peak RSS; the linked check similarly replays `LinkedLiteral`.
Update the consumer replay measurement when adopting a new
pin. Review the candidate's byte change, full census and every refusal, retain
the independently checked comparator provenance, and commit the pin with its
justified source change and gate conclusions. An execution-lane baseline move
remains a stop, not permission to re-pin it. Delete the disposable
`.tmp/core-quote-repin` directory after recording the conclusions; do not commit
literal dumps or traces.
