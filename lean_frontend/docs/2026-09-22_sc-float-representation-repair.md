# SC CAS exposed a floating-point representation defect

[AGENT, 2026-09-22] Work in `arc/sc-prototype`, after protocol commit
`06681abd3`. This is an inherited Lean port defect, not the upstream padding
model gap covered by the [user's fail-closed decision](2026-09-21_sc-upstream-gap-policy.md).
The repair is promoted and passes native component checks and Tier A. The full
run exposed a new fixture's dependence on NaN operand selection, discussed
below; fresh integration after that fixture refinement remains outstanding.

## GCC diagnostic and fixture refinement

The first full integration run passes 28 lanes before the GCC second-oracle
lane reports `109-nan-arithmetic.c`: GCC returns 1, Lean returns 0. The original
input and stdout/stderr are retained in the stopped full report and in
`.tmp/sc-prototype/nan-gcc-fixture-review/`. No passing full run is claimed.

A minimized native diagnostic prints the bits of `a+b` for a negative signaling
NaN with payload 1 and a positive quiet NaN with payload 2. GCC `-O0` produces
`7ff8000000000002`, whereas `-O2` produces `fff8000000000001`. The original
fixture returns 1 and 0 respectively. Pristine and fork both return 0; the
repaired Lean result is also 0. The evidence identifies operand selection in
this test, not a newly discovered Lean/OCaml arithmetic mismatch. Exact pinned
OCaml behavior remains the target of the separate 784-row matrix.

For the ordinary C regression, both operands now have the same negative sign
and payload 1, one signaling and one quiet. This preserves checks that arithmetic
retains the payload and quiets the signaling NaN, without making the result
depend on which operand's representation is selected. The refined fixture
returns zero on GCC at both optimization levels and on pristine/fork/Lean.
The retained earlier native SC recorder, whose float seam predates the repair,
still returns `Specified(1)` on a selected trace of the refined input. That is
an explicit negative control, not current SC certification. Commands, original
statuses, source hashes and all five binary hashes are in the scratch report.

The full runner was stopped and allowed to finish its report before editing.
Its status is incomplete with source unchanged; the first 28 lanes passed and
B7 was interrupted. Only the new fixture is refined. Its expected result stays
zero, the exact reference matrix stays unchanged, and neither a comparator nor
the GCC triage ledger is weakened. A new complete integration run follows.

## Concrete counterexample

An atomic `double` contains bits `0x7ff8000000000001`; expected contains
`0x7ff8000000000002`. Strong CAS must report unequal representations. The draft
correctly reports failure, but its actual typed write-back on Lean writes
`0x7ff8000000000000` into expected. The native OCaml draft retains payload 1.
Both preserve the expected-read, object-read and expected-write phase sequence.

Two ordinary C programs independently expose the same defect: union-based
representation initialization followed by a typed double copy, and `memcpy`
into a double followed by a typed copy and `memcpy` back. For both programs:

| Engine | Result | Process exit |
|---|---|---|
| Pristine upstream `b9aeedcb4` | `Specified(1)` (bits preserved) | 0 |
| Fork OCaml with the atomic foundations | `Specified(1)` | 0 |
| Lean with the atomic foundations | `Specified(0)` (payload lost) | 0 |

The exact C sources, Core dumps, bridge inputs, commands, binary identities,
stdout/stderr and original statuses are in `.tmp/sc-prototype/nan-representations/`.
The original CAS failure appears both in the interpreter and the fresh native
closure (`sc-cas-draft/cas-controls-4.log` and
`sc-cas-draft/native-probe-1/controls-repair.log`). Eleven of twelve CAS groups
pass there; the different-payload write-back group fails. This is not a green
CAS result.

## Cause and repair

The concrete OCaml model uses `Int64.float_of_bits` when reconstructing floating
values and `Int64.bits_of_float` when storing them. Its typed load/store thus
preserve a NaN's representation without executing arithmetic. The port used
Lean `Float.ofBits`/`Float.toBits`. The installed 4.32.2 runtime canonicalizes NaNs
in both functions; their disassembly and shared-library hash are retained in
`.tmp/sc-prototype/nan-arithmetic-2/lean-runtime.json` and adjacent captures.
A freshly compiled native CAS test confirms that this is not an interpreter-only
artifact.

The draft `CerbFloat.Value` stores the 64-bit representation explicitly. Its
memory encoding and decoding are direct projections with two kernel round-trip
laws over every bit pattern. Numeric projection to Lean `Float` is used for
comparisons and finite arithmetic, never for copying/serializing the value.
The `Float.float` Lem target and `Mem.floating_value` seam use the same carrier,
so formatting and callbacks cannot silently discard sign/payload information.
Signed NaNs also retain their sign in the existing formatting algorithms.

Arithmetic NaN propagation follows the pinned concrete OCaml target on x86-64,
including quieting signaling operands. This choice is a concrete implementation
correspondence, not a claim that ISO C universally chooses one NaN payload.
The source is `memory/concrete/impl_mem.ml`'s four `op_fval` arms; the machine
behavior is specified in Intel SDM volume 1, §4.8.3.5, table 4-7, and §4.8.3.7.
The former describes first-NaN selection and quieting for SSE; the latter gives
the indefinite representation used for invalid arithmetic. [Intel SDM](https://cdrdv2-public.intel.com/782149/253665-sdm-vol-1.pdf)
No foreign primitive, new axiom or toolchain modification is introduced.

The actual native `Impl_mem.op_fval` test covers 14 operands crossed with one
another for all four operators: both zeros, ±1, both infinities, both signs and
two payloads of quiet and signaling NaNs. All 784 interpreted Lean rows match
that captured table in the isolated draft. Ordinary memory setup goes through
real allocation, integer storage, `memcpy` to a non-atomic double, and typed
loading; no unsafe coercion manufactures an abstract OCaml floating value.

## Validation status and instrumentation corrections

The native paired CAS controls now have 18 original protocol groups plus 12 CAS
groups passing (`sc-cas-draft/ocaml-probe-9/`). They include interleaving witnesses
with 175 and 210 alternatives. Attempt 10 aligns the double desired value to 1 in both fixtures and again
passes all 30 groups. Original differing-input captures remain retained.
No claim of complete observation-transcript parity follows from these Boolean
component controls alone.

The arithmetic matrix's compile and run both exit 0. The initial runner then
failed while retaining a library hash at an incorrect filename. That failure is
retained in `nan-arithmetic-2.log`; `sources-repaired.json` hashes the actual
`mem_concrete.cmxa` and test binary without rerunning or altering the captures.
Earlier failed CAS test attempts are also retained: abstract OCaml type and
callback-arity errors, then fixture initialization that incorrectly accessed
an atomic object via an integer/byte lvalue. These are probe defects, not CAS
outcomes; the working fixture initializes the atomic object with a typed store.

The float draft's first generation attempt rejected stale draft dependency
paths. The second generated the old CAS root set, leaving `Float` import-only;
compilation correctly failed on that stale module. The third additionally emits
the direct float users. Leaf compilation and the 784-row arithmetic execution
pass. Frontend closure, actual memory-copy/CAS controls, native execution,
production promotion, gate reviews and integration remain outstanding.

Full regeneration of both targets passes. The partial-root attempt had exposed
an additional generated-name collision (`wip0`) when combined with the unchanged
frontend; the repair uses the complete Makefile source lists, separately for
OCaml and Lean. A probe started before full generation finished also failed on
the old `Float` module; that attempt is retained and is not compilation evidence.
After generation completed, the full `Main` dependency closure compiles.
`CoreParser` now carries the same explicit representation in numeric tokens and
constructs signed infinity/NaN text spellings directly from their bits; `CerbPP`
passes the carrier into the existing formatting routines. The initial PP unit
probe then exposed a scratch module-path problem for `Unit.BatchEscapeTest`;
the probe must compile the complete requested `Unit` closure into its overlay.

Three further C regressions establish distinct production failures before the
repair: copying all eight NaN kind/sign/payload combinations, arithmetic with
signaling/quiet operands, and printing a negative NaN. Pristine and fork agree
on each. Lean fails the first two return-value checks and prints `nan` where the
references print `-nan`. These original captures are in
`.tmp/sc-prototype/nan-representations-more/`. A fresh isolated native `Main`
is being built in resumable chunks, with per-module source/dependency keys and
commands retained under `sc-float-draft/native-main/`; chunk exit 75 means the
build is unfinished, not a failed C execution or a passed native check.

## Promoted result

The fresh isolated native frontend passes all five C regressions with stdout
byte-identical to the fork; pristine agrees on the same observations. The
combined float/CAS draft passes all twelve interpreted CAS groups. The repaired
pretty-printer test and all 42 literal pins pass. Its former `0/0 -> "nan"`
expectation depended on the acknowledged lost-sign caveat; the actual concrete
arithmetic matrix produces negative indefinite NaN, and the C formatting
reproduction confirms `-nan`. Explicit positive/negative representation tests
now cover both signs.

The repair and CAS phases are promoted together. Both production builds and
seven native test executables pass, including all twelve CAS groups and all
784 arithmetic rows. The [atomic slice review](2026-09-22_sc-atomic-slice-review.md)
records current identities and outstanding integration checks. Evidence remains
in the named scratch directories until checkpoint retention. The five C inputs
are `tests/float/106`–`110` with new MATCH entries; no prior baseline is weakened.

## Completed checkpoint validation

The [atomic evidence index](2026-09-21_sc-prototype-evidence/atomic/README.md)
now retains this repair's commands, representations, arithmetic table, C
reproductions, original failures and all integration attempts. Fresh Tier A+B
passes 39/39 commands on unchanged sources with no artifact issues. The GCC
lane passes 2,006 cases after the documented fixture refinement. The 864-case
three-engine report preserves the prior 40 Lean discrepancy IDs; all five new
float fixtures agree across pristine, fork and Lean. Seven native component
executables and six production controls/mutations pass, including CAS's actual
representation-sensitive write-back. These are checkpoint results, not a
completed SC executor or a universal floating-point payload policy.
