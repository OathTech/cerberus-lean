# Ordinary RMW scheduling and physical byte-source accounting

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


This follows the validated CAS/float checkpoint `fb72dd9fb` under the SC
prototype charter. It is a current implementation slice, not the completed
SC checker or a whole-program definedness claim. Both production builds, targeted native controls, all 39 Tier A/B lanes and the
mandatory three-engine report pass. The [retained evidence](2026-09-21_sc-prototype-evidence/rmw-byte-sources/README.md)
records the source identities and original outcomes.

## Ordinary read/modify/write

The current Core `SeqRMW` represents ordinary C read/modify/write behavior.
[Memarian's thesis](https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-981.pdf),
printed pp.64/67, distinguishes its exclusion of intervening indeterminately
sequenced calls within the same thread from interleaving by another thread.
The previous SC handler grouped its load and store into one scheduling service,
which omitted the latter interleavings.

The SC scheduler now performs the original load and value calculation, then
owns a pending `SeqRMWWriteRequest2`. Other threads remain eligible; the same
thread must finish that request before taking another Core alternative. The
resumed store invokes the authoritative memory operation on the current state,
so an intervening lifetime end or write failure is neither bypassed nor checked
against a saved memory snapshot. The read-to-write edge, polarized receipt,
original completion builder and legacy trace update survive both phases. The
ordinary sequential handler remains byte-for-byte unchanged. The CAS wrapper
shares the owned-request suspension mechanism with unchanged diagnostics.

Paired native Lean/OCaml controls pass seven groups, including 495 cross-thread
alternatives, two indeterminate-call orders and 90 lifetime alternatives. A
read-only-store failure retains its read, exact UB and unchanged bytes. The
Lean protocol, CAS and fence controls also pass against this implementation.
Five real C controls agree exhaustively on complete observation sequences:
postfix old/new values, prefix increment, compound assignment and indeterminate
calls. The parallel increment C case times out in both exhaustive engines at
12 seconds; selected executions pass in both engines. That timeout remains
incomplete and is not claimed as exhaustive agreement or a race verdict.

The new pure-failure guard in `step_ctx_with` is reviewed as unreachable on the
public drive path: `step_action_with` cannot produce `SeqRMWWriteRequest2`.
The SC driver creates it directly in its pending list and `sc_service_step`
consumes it without passing through the Core action-to-context mapper. This
source-invariant review does not quantify over arbitrary fabricated states.

## Physical read-byte origins

`Sc_byte_sources` computes one physical origin for each actually captured read
byte by scanning its exact older journal suffix. It chooses the latest covering
store occurrence or allocation in the same storage instance. Equal-value stores
remain distinct; reads cannot replace a writer. Missing history, unresolved
storage and deallocation are distinct results. No new memory load, value
re-encoding or mutation is performed. The observed representation remains
authoritative when metadata affects its interpretation.

Eight actual-memory controls pass in both generated targets: mixed whole/byte
writers, repeated reads, equal-value overwrite, the four distinct writes of a
real memcpy, normal completion, a trapped read's retained origin, allocation
and lifetime boundaries, and different storage identities at the same address.
The Lean module exports five general kernel laws about the generated functions:
empty history, read skipping, latest-store selection, deallocation boundaries
and captured-byte cardinality. `CerbSCOperational` additionally exports the
three kernel retention laws checked during the prior checkpoint: request
ownership, the exact older journal, and one additional occurrence.
These are operational accounting laws, not a
Cmm reads-from/value or ISO memory-location correspondence theorem.

N1570 3.14 and 5.1.2.4 distinguish C memory locations from storage allocation
and byte ranges. The pinned Cmm footprint/value adapter still has placeholders;
this slice does not assign those missing meanings. The new leaf is shared Lem
source, with a handwritten proof module and registered native unit entry.

## Validation provenance and remaining work

Isolated drafts and original failed attempts are retained under
`.tmp/sc-prototype/sc-seq-rmw-draft` and `sc-byte-sources-draft`. RMW generation 1,
OCaml probe 3, native probe 1 plus source-checked updated leaves 3–6, and the
C entry's recorded resume establish the results above. Original probe syntax,
constructor and short native-build failures remain failures/incomplete.
Byte-source generation 2 resolves an OCaml reserved-word collision; OCaml
probe 2 and Lean probe 7 pass all eight controls. Generation 1's five Lean
controls are narrower earlier evidence, not the completed current test set.

Both production targets regenerate with shared source identity
`8a744ea087fde6211b2207c597c06059197a67fee226e08b3194fbdadfabe1c9`.
All 56 handwritten copies match. The OCaml build/local install and the 442-job
Lean production/control build pass. Five native production control executables
pass (RMW, byte sources, protocol, CAS and fences). The retention-law rebuild
also passes; the native driver remains byte-identical.

The failure census is 241 sites: 239 in the execution closure and two unresolved
owners, with 174 invariant-unreachable, 48 reachable, 19 unknown and zero
discardable. The sole new row is the internal ordinary-RMW guard described
above; every prior row is unchanged. The fork review pins 91 source files,
32 differing existing generated files and the new `sc_byte_sources.ml` leaf.
Only Makefile, Core reduction and driver identities change among prior source
entries; only Core reduction and driver change among prior generated entries.
Historical comments and the `renumber=arc13` metadata are retained.

Six fresh native production connection controls/mutations pass: positive RMW,
regrouped RMW phases, positive byte accounting, reads treated as writers,
ignored store storage identity and ignored deallocation. Every mutant compiles
and is rejected by its expected executed witness; a compiler failure, panic or
timeout is not accepted as detection. Sources, commands, statuses and hashes
are retained in `rmw-byte-production-plants`.

The full run completed on frozen sources with no artifact issue. All 864
three-engine rows retain the prior 40 discrepancy IDs. Helper internal order and interruption,
location/RF composition, SC consistency/races, public interfaces and the remaining
charter obligations continue after this slice. No customer write, mainline merge
or push is involved.
