# Core/CoreB execution and comparison

This is a research tool for developing Nice in the independently owned CoreB
path. It runs the unchanged Core and CoreB semantics from the same C input,
records genuine nondeterministic choices on either side, replays them on the
other, and compares observations. It is not a refinement theorem and does not
claim coverage of all C. The broader acceptance criteria remain in
[the baseline scope](coreb-baseline-scope.md).

## Architecture and ownership

```
C --existing OCaml parser--> Cabs JSON
                              |
                    shared typed AIL preparation
                        /                 \
                Core.translate       CoreB.translate
                Core runtime         CoreB runtime
                link + convert       link + convert
                evaluator/driver     evaluator/driver
                        \                 /
                     positional choice runner
                independent observations and outcomes
```

`frontend/coreb/sources.json` owns 18 complete Lem modules and 15 handwritten
support modules. They generate 51 Lean modules, covering syntax, errors,
typing, lowering, linking, runtime parsing, evaluation, reduction, procedure
calls and the driver. All 33 source inputs remain byte-identical to the recorded
Core baseline. B has its own inductives and consumers; it does not execute by
converting programs or continuations back to A.

Cabs/AIL, C types, symbols, locations, memory, ND and other target-neutral
services remain shared. Typed preparation intentionally uses the existing Core
mini-pipeline for constant-expression processing. This comparison therefore
does not independently validate the shared frontend or memory model.

The generator runs the original complete ordered source environment separately,
substituting owned paths, then retains owned outputs. Input-only `-i` handling
was insufficient for the expanded closure because it changed namespace opening
order. Packaging maps owned imports and wraps declarations in `CoreB`; it
qualifies Translation's actual local `open Operators` commands. Strings,
comments, expression terms and proof bodies remain unchanged. It applies the
same removal of the generated `Core_run` stray `import Operators` as the original
recipe. `--check-baseline` checks original and owned sources against the Git
base, and raw generated bodies against Core, except the source-path header.
No Lem compiler change was needed.

`test/CoreB/Interpreter.lean` inspects resolved dependencies from B lowering and
execution, rejects original target entrypoints there, and requires the B parser,
translator, linker, converter, initializer, driver, reducer, procedure call and
evaluator. A small ordinary Lean equation invokes B's actual evaluator on a
value. Its printed axioms are standard-only; it is not a correspondence proof.

## Run it

Provision the pinned Lean/Lem and ordinary OCaml dependencies using the
[provider instructions](../../README.md#build-and-run-one-differential-test).
From this repository root, in Bash:

```bash
cap() { if command -v capped >/dev/null 2>&1; then capped "$@"; else "$@"; fi; }
export CAPPED_MEM_MAX=32G
cap opam exec --switch=. -- make prelude-src lean-prelude-src coreb-prelude-src
cap opam exec --switch=. -- python3 tools/generate_coreb.py --check-baseline
python3 tools/generate_coreb_quote.py --check
cap opam exec --switch=. -- dune build --root . backend/driver/main.exe cerberus-lib.install
cap make lean-native-obj
(cd lean_frontend && cap lake build CerberusCoreB CoreBSeparationTests \
  CoreBDifferential core-diff coreb-diff coreb-pair-check \
  coreb-choice-tests coreb-observation-test)
python3 scripts/coreb-diff.py tests/minimal/021-pointer-basic.c
python3 scripts/coreb-diff.py tests/z2-probes/nd/order3.c --choices 1,1
python3 scripts/coreb-smoke.py
```

`coreb-diff.py` uses the local OCaml producer and runtime by default. Explicit
`--producer`, `--runtime`, `--core-bin` and `--coreb-bin` paths support other
owned builds. `--cabs-json` accepts an already produced input. `--seed` and
`--choices` select a recording policy; neither selects a path by reference
output. Every comparison runs four fresh processes: A record, B replay, B
record, A replay. It also compares the two independent recordings.

The admitted recipe is one translation unit, concrete LP64 memory, no C libc,
normal calling convention, empty switches and explicitly bounded fuel/address
space. The Core runtime is still loaded independently by both paths. Binary
SHA256 identities, input/runtime identities, preparation recipe, fresh supplies,
argv and observation configuration bind the tapes. Different binaries need not
have equal hashes; they must identify the intended comparison pair.

The default per-child limits are 30 seconds, 4 GiB address space and 16 MiB
output. Limits are explicit options. Scratch tapes/traces are temporary and
deleted after comparison. The runner requires `LEAN_ABORT_ON_PANIC=1`; the
orchestrator supplies it. Direct invocation without it refuses.

## What is compared

* Actual ND nodes, node kind, parent payload and complete ordered alternative
  descriptors. Branching entries retain index and duplicate labels; singleton
  nodes consume no tape choice. Missing/surplus entries, invalid indices or
  incompatible descriptors fail. Nontrivial constraints refuse explicitly.
* Driver events with complete payloads: emitted allocations, loads, stores,
  RMW, lifetime ends, pointer shifts and returns.
* Existing passive byte-level access receipts, including direct memory accesses
  omitted by the driver trace: locations, kind, type, pointer/provenance,
  allocation, address, bytes, value and locking flag.
* stdout/stderr deltas at actual ND boundaries, plus full terminal streams,
  result value/blocked status or complete UB/error payload.
* An explicit completion record. EOF, panic, timeout, fuel exhaustion, empty
  frontier, unsupported observations and frontend failure cannot count as a match.

The driver and memory buffers are newest first. The observer checks retention
of their previous suffixes and reverses only the new prefix. Output checks
retention of its previous prefix. Each channel is labelled and associated with
an actual ND boundary. Channels retain their own order; their presentation
does **not** reconstruct interleaving inside a batched ND action.

Complete defined and UB comparisons are distinguished. Matched model errors
remain failures, with a nonzero exit; they never satisfy defined-coverage
targets. Float payloads retain finite bits, including signed zero; NaN refuses
because the available bit conversion does not preserve its full payload.

No heap, AST, environment, continuation or complete runtime state is serialized.
Observation arrays and the existing cumulative buffers are held in memory until
completion. Suffix validation costs time proportional to accumulated history;
resource limits bound this prototype, rather than implying constant-space tracing.

## Structural and runner calibration

`coreb-pair-check` prepares typed AIL once and feeds that same value to both
lowerers. It compares complete linked/converted program artifacts and supplies
through the existing constructor quotation instrument. Its B twin uses an
explicit namespace-erasure map; literal names/values/locations and tree shapes
remain exact. It compares trees in memory without rendering or serializing them.
Function-valued map comparators use the existing audited producer-provenance
contract; this is not equality of arbitrary supplied functions. The instrument
manifest is separate from semantic ownership.

The same helper exhausts small finite choice trees and compares full outcome/
driver-trace multisets, including duplicates, with the existing `CerbND` runner.
It separately checks branch zero and capture-enabled execution against ordinary
capture-disabled execution. `MAX_PATHS` limits replay enumeration; the caller
must also bound time/memory because the existing exhaustive runner enumerates
before its result-count check.

```bash
mkdir -p .tmp/coreb-example
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --cabs-json tests/z2-probes/nd/order3.c > .tmp/coreb-example/input.json
cap timeout 30 env LEAN_ABORT_ON_PANIC=1 \
  lean_frontend/.lake/build/bin/coreb-pair-check \
  _build/install/default .tmp/coreb-example/input.json 10000 18446744073709551615 10
rm -r .tmp/coreb-example
```

## Evidence and remaining scope

At `bcfebb225`, focused builds, five packaging tests, eight subprocess/comparator
tests, the choice-runner controls and 39 observation tests pass. Literal return
has one path; `order3.c` has six. Both pass full artifact comparison, two
artifact negative controls, branch-zero/all-results calibration and passive
capture erasure. The latter compares outcomes/driver trace, not complete states.

All 111 non-libc minimal inputs were sampled bidirectionally: 90 matched defined
runs, 19 matched UB runs, and two matched model-error failures. The two failures
are the deliberate allocator-exhaustion fixtures 112/113; their source comments
specify the out-of-memory behavior. They are excluded from successful coverage.
This was one policy per input, not exhaustive C coverage.

An additional 15 minimal fixtures passed paired artifact comparison and
first/all-results calibration: 003, 007, 011, 015, 017, 022, 024, 025, 027,
041, 045, 056, 059, 061 and 062. These cover loops, recursion, direct/indirect
calls, pointers, arrays, structs/unions, switches and goto. Fixture 017 has
32 paths; the other 14 have one each. Reproduce by supplying each file to the
Cabs-producer/pair-check command above with fuel 1,000,000 and `MAX_PATHS=64`.

`coreb-smoke.py` checks two actual function-evaluation orders with distinct
stdout and the same return value, plus stdout retained before UB. It asserts
the expected output and observation deltas after all four comparison runs.
Direct CLI controls also rejected a missing panic-abort setting, a truncated
choice list and a wrong build identity. A 1 GiB address-space cap failed during
Lean thread startup in that diagnostic attempt; it was a failed run. Repeating
with the harness's normal 4 GiB limit discharged the controls.

The [frozen exact campaign](campaign.md) passed 1,000 distinct defined inputs,
2,000 distinct input/tape pairs and 8,000 fresh interpreter executions in
659.017 seconds. Every input completed two genuinely different tapes in both
directions. There were no mismatches, incomplete runs, UB or model errors in
that generated slice; all six feature-family targets were met.

All six [built source controls](source-mutations.md) passed. Real lowering,
arithmetic, choice-order and observer defects are rejected in both replay
directions under both comparison profiles. Arithmetic changes real stores
while preserving the final result. A real extra singleton ND step is rejected
by exact comparison and accepted by the explicit stutter projection. Native
panic remains incomplete in both profiles, confirmed by signal, marker and
absence of completion. Normal executable hashes stayed unchanged.

The [stutter profile](stutter-comparison.md) coalesces each observation channel
only between genuine branching choices. It retains full branch descriptors,
payloads, per-channel order and outcomes. It does not silently admit new event
schemas, change choice correspondence, or infer cross-channel interleaving.
Use exact mode for the unchanged baseline and opt into this narrower relation
when testing additional nonbranching steps. The large campaign ran in exact
mode; the stutter profile has focused executable and mutation evidence.

The [independent review](interpreter-review.md) assesses this as an adequate
baseline tool for the first Nice changes, within those explicit limits.

Remaining observation limits are specific: the optimized driver batches many
tau/evaluation/label transitions; its existing function-call event has no live
emitter. There is no complete call/jump trace or intra-action cross-channel
ordering. Future Nice breakpoint nodes must emit observations at their actual
execution points. Reconstructing lexical scope or control transitions from
sampled states is not part of this tool. Additional model/Lem instrumentation
should be discussed when a concrete experiment requires it.

The copied parser/linker and quotation/observation instruments retain existing
partial definitions; shared native digest/freshness/runtime seams remain part
of the executable trust boundary. No general equivalence theorem or new
certification mechanism is asserted. Existing OCaml/Lem warnings (including
Menhir conflicts and generator name warnings) were visible during provisioning;
they are not suppressed or counted as new Lean warnings. Lean keeps warnings
as errors. No full consumer theorem campaign or shipping gate was run for this
research build.
