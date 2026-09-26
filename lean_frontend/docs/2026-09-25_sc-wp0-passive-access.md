# SC WP0: passive concrete load/store observations

Implementation candidate on `arc/sc-wp0`, rebased onto mainline
`db5e1feb54226a6335aa89d0824aa9e313314020`. The independent `_Bool` repair
is the preceding commit `917961adf00fbb4ae4ed4aac8a3e0ee889d3aa08`.
The original identity was `8c522512f`; the first full-suite run used its
earlier rebase, `2fef39d04f16882cb252396f3cbf8ace79e4d562`. Its [record](2026-09-25_sc-wp0-bool-load-repair.md)
retains the original failing witnesses and fast-suite evidence.

The governing master plan is `SC-CONCURRENCY.md` on `arc/sc-concurrency`,
`533fab987`. [AGENT] This is its finite F1/F2 slice and only the F3 representation
access used by the diagnostic. It introduces no SC interpreter, scheduler,
suspension constructor, graph checker, race policy, atomicity policy or Iris
integration. WP1 starts after independent acceptance and landing of WP0.

[USER] The user requested independently validated, early landings, treating
the failed prototype as a quarry; narrowed the MVP to coherent, correct SC
semantics without Iris integration; and directed "proceed with WP0". That
scope is recorded in the master plan and
`lean_frontend/docs/2026-09-25_sc-semantics-mvp-scope.md` at `533fab987`.
[AGENT] The implementation, receipt fields, hook placement, reuse of existing
transport, diagnostic design and drain policy below are agent decisions under
that direction, not individually prescribed user requirements.

## Integration contract

[AGENT] The existing memory primitives remain the authority for values, bytes,
allocation checks and failures. The paired scope remains mainline’s concrete
memory model with the Lean default switch profile. Optional receipts are appended inside the
paired OCaml/Lean concrete implementations:

* Load: after fetching bytes and reconstructing the value, alongside the
  existing `last_used` update, before the `_Bool` trap check.
* Store: at the actual representation write. A same-value store still
  produces a receipt. The ordinary returned memory state includes the
  primitive's existing read-only/union bookkeeping.

[AGENT] The shared `mem_common.lem` constructor contains source location, access
kind, requested C type, original pointer, resolved allocation ID when
available, actual byte address, byte views, actual reconstructed/stored
memory value, and the store's existing `is_locking` argument (`None` for a
load). That argument marks read-only storage; it is not an SC atomicity rule.

The byte view preserves all four concrete provenance cases and their IDs,
pointer-copy offsets, and specified/unspecified bytes. The touched range
has the byte list's length. It is not inferred from allocation size or from
the returned type-sized footprint. No universal scalar value, C location
equivalence, byte-source history, or previous-memory snapshot is introduced.

[AGENT] `begin_observing`/`beginObserving` enables capture idempotently; enabling
again preserves pending receipts. `take_observations`/`takeObservations`
returns execution order and empties the buffer while leaving it enabled.
`stop_observing`/`stopObserving` discards the buffer and disables capture.
The default is disabled. VIP, symbolic and CHERI explicitly decline enable
and drain through `None`; an unsupported model is not an empty trace.

[AGENT] The actual consumer is the paired `access_probe` / `memory-access-test`
diagnostic. It runs production primitives, uses the existing `liftND` to
embed memory in an enclosing state, and drains the returned state. No ND
implementation change or new adapter is needed. Constraints, ordered
alternatives, original kill reasons and enclosing state are preserved;
the diagnostic does not solve guards or admit executions.

[AGENT] Receipts are primitive facts. They do not determine source sequencing, C
memory-location identity, one logical C action, or a scheduler step. They
do not make helpers resumable. Only load/store producers are covered;
allocation, lifetime, helper-specific and metadata observation extensions
wait for their first execution consumer. A helper that calls a primitive
may incidentally emit its receipt; that is not a completeness claim for
the helper or evidence about its first internal race.

## Erasure and storage

`Unit.MemoryAccessProofs` proves, over the actual `loadM` and `storeM`,
that erasing observation from the returned node/state equals executing
with observation disabled initially. The statements quantify over the
whole memory state, type tables, pointers, values, the store flag and
caller-selected fuel. They cover errors as well as successful operations.
They do not assume correctness of a separate state model. Standard kernel
axioms are reported by `#print axioms`; no new axiom or admitted proof is used.

The existing `liftND` state theorem covers every returned action constructor
at positive outer fuel. Zero fuel does not evaluate the action; the existing
generated zero equation describes exhaustion. Preservation of action
constructors also requires enough fuel for `liftAction`; a fuel-exhausted
transport is not advertised as a successful observation.

These laws compare enabled and disabled execution of the current primitive.
Historical equivalence additionally relies on the small reviewed hook diff
and the sequential differential gates. The preceding trapping-load repair
is deliberately outside this erasure baseline [AGENT].

Enabled capture costs one receipt plus a byte-list projection per primitive;
disabled capture does not copy the byte list. Draining reverses the pending
receipt list once. There is no scan of prior actions or old memory states.
[AGENT] Storage is **drainable, not unconditionally capped**: it grows with work
since the last drain. The streaming diagnostic drains every primitive and
retains at most one pending receipt; the two-operation failure witness
retains two. An unbounded monadic helper still needs a justified yielding
strategy in WP1/S1. This API supplies neither that bound nor preemption.

## Evidence and audit boundary

`python3 scripts/test_memory_access.py` builds both consumers and is Tier A
row 13. [AGENT] Its expected transcript is independently specified from the fixture
operations and LP64 representations, rather than recorded from an engine.
It checks the entire stdout, requires empty stderr and a successful exit,
and has controls for lost writes, failure state, pointer provenance, bytes,
dropped alternatives, swallowed failure, exit status and unexpected stderr.

The primitive witnesses include identical repeated stores, byte updates to
an integer, pointer representation/reconstruction, negative-zero double
bits, array representation/reconstruction, unspecified bytes, trapping
reads, rejected null accesses, the read-only-marking store flag, and one
or two completed accesses followed by failure. The transport witnesses
exercise all six existing ND constructors and both descendants of each
choice. Re-enable and repeated drain controls catch prefix loss/replay.

Each native primitive run additionally compares the actual full state and
result against disabled execution. The Lean diagnostic compares every
sequential state field explicitly: the production `BEq MemState` and
`BEq Allocation` instances are intentionally degenerate and unsuitable for
this test. The general erasure theorems use equality of the whole state.

`--cost` measures fixed-state streams of 100,000 / 200,000 / 400,000 stores,
three repetitions on each engine with capture on/off. It checks one receipt
per observed store and zero retained receipts after draining. Timing is
evidence, not a semantic acceptance threshold or a claim about the future
SC scheduler. The rebased candidate passed all 39 diagnostic/cost runs.
The [measurement report](sc-wp0-evidence/access-cost.json) records source/binary
hashes and all repetitions. The fixed diagnostic transcripts are retained for
[native](sc-wp0-evidence/access-native.txt),
[Lean at fuel 17](sc-wp0-evidence/access-lean-17.txt) and
[Lean at fuel 64](sc-wp0-evidence/access-lean-64.txt).

Median elapsed seconds (whole diagnostic process, including fixed startup):

| Engine / capture | 100k | 200k | 400k | Maximum measured RSS |
|---|---:|---:|---:|---:|
| OCaml / off | 0.056 | 0.089 | 0.159 | 30,476 KiB |
| OCaml / on | 0.057 | 0.095 | 0.162 | 30,660 KiB |
| Lean / off | 0.051 | 0.098 | 0.191 | 9,468 KiB |
| Lean / on | 0.057 | 0.111 | 0.220 | 9,324 KiB |

All stream runs retained zero receipts after draining. These small fixed-width
probes are consistent with operation-proportional work and bounded live
storage under this drain policy; they are not general asymptotic proofs.

Concrete and VIP interfaces are build-checked. Optional symbolic/CHERI
builds cannot be checked in this environment: their existing `z3` and
`coq-core.kernel` dependencies are absent. Their changes are limited to
the explicit unsupported implementation of the new signature members.

The shared Lem installation moved during development. The first witnesses
used the original mainline pin `38f87d5`; a temporary worktree-local generator
kept that experiment isolated. This candidate now inherits mainline's
accepted `c2a68e79b6369e19f099dfa48767319c1daf19b3` pin and is regenerated
and validated with it. The intervening mainline cleanup includes the Lem
`fuelExhausted` native-extraction fix and strengthened gates, so the final
candidate repeats the full ladder after that rebase. No shared switch was
modified by this work.

Quarry provenance: the opt-in receipt idea and primitive hook locations
were inspected at donor `arc/sc-prototype` runtime tip
`631382a9d23a709112f38add53357d4cbe6fc108`. The implementation was re-derived
on current mainline. The donor's ND changes, suspension machinery, other
receipt families, scalar abstraction, scheduler, monitor and acceptance
status were not inherited.

## Final validation and review boundary

The final candidate passed **40/40 Tier A+B commands** under
`release.py --mode full`, with source unchanged, complete tier selection,
no artifact issues, and unchanged compiler and Lem runtime checkout identities.
The [full-run record](sc-wp0-evidence/access-full-validation.json) preserves
the tested source hashes, binary identities, command results and raw-log hashes.
It includes the standing WP0 diagnostic, 93/93 observation-instrument controls,
the 2,014-case GCC lane with zero baseline regressions or improvements, and
both pristine-oracle gates. No baseline or behavioral exception was changed.

The final [three-engine report](sc-wp0-evidence/access-three-engine.json)
also completed with source unchanged: 872 rows, comprising 835 pristine/fork
semantic agreements, 28 matching failures, seven existing registered
differences and two interface agreements. Its reporting-only Lean column has
830 agreements, 28 differences, 12 both-undecodable cases and two inapplicable
rows. The 40 non-agreement case names equal the previously documented
[O2 inventory](2026-09-16_pristine-oracle-instrument-record.md#4-o2--three-engines-57a0e4ee0);
the owning baseline gates passed. These existing classifications are not
relabelled as agreement.

The earlier full run and three-engine run remain in the `before-final-rebase`
records as historical evidence. Final validation above was repeated after
the mainline cleanup and Lem repin. Regeneration produced byte-identical
Cerberus generated files; the WP0 runtime and diagnostic sources were also
unchanged across the rebase. The final proofs use the default heartbeat budget.
The final native concrete/VIP/probe build used `DUNE_CACHE=disabled` and
`dune build --force`; Lean builds were capped. The 39-run focused/cost report
above was refreshed on the final pin before the full run.

**Status: implemented and validated; independent audit and landing pending.**
Review the isolated `_Bool` state repair separately, then the receipt hook
placement/data fidelity, whole-state erasure, existing ND transport, and
draining/cost contract together with their actual diagnostic consumer. The
runtime hook diff is small; the diagnostic and proof are part of its audit
unit. Optional symbolic/CHERI compilation remains the dependency limitation
described above. Full-tier completion does not constitute independent semantic
acceptance or a public SC release. No mainline merge or push has been performed.
Acceptance and landing close WP0; WP1 has not started.

## Consumer exposure and skeptical-review closure (2026-09-26, orchestrator [AGENT])

Skeptical review `2026-09-26_sc-wp0-skeptical-review.md` (Claude Fable, fresh reviewer): verdict "merge-ready after ONE
docs-only P2 (F1)". Closed here:

- **F1 (P2) — consumer exposure.** cerberus-sl (pin `2b51d2a57`) proves its memory lemmas by UNFOLDING the production
  `loadM`/`storeM` over an arbitrary `σ : MemState`. With receipts ENABLED (`σ.observations = some _`) five of its kernel
  lemmas become false, not merely rebuilt: `MemLoc.lean:26 loadM_loc_indep`, `:35 storeM_loc_indep` (a receipt carries
  `loc` into the SUCCESS state), `UnseqReads.lean:151 loadM_lastUsed_only`, `HeapModel.lean:267 storeM_active`,
  `:287 loadM_active`. Structural-pattern risk is zero (no `MemState.mk`/`.ext`/anonymous-constructor sites; 537
  `{… : MemState}` literals are transparent to the new defaulted field). Remedy on their side: the hypothesis
  `σ.observations = none`, which every primitive preserves when capture is disabled (`disabled_recordAccess`,
  `load_erasure`/`store_erasure` in `Unit.MemoryAccessProofs`). Consumer note:
  `2026-09-26_consumer-note-cerberus-sl-sc-wp0.md`. Neither WP0 record nor the two prior audits had mentioned the consumer.
- **F2 (P3) — evidence heads.** The committed "final" reports (`access-full-validation.json`, `access-three-engine.json`,
  `access-cost.json`) record `head = 917961adf` on a DIRTY tree; the reviewer verified all fifteen
  `tested_changed_source_sha256` values equal the `4e86ea091` blobs, so the tested content is the reviewed content. The
  "Final validation" section above names no head; this sentence does.
- **F3 (P3) — cap.** `scripts/test_memory_access.py` now runs both executables under `scripts/capped` with the per-test
  cap (`CERB_TEST_MEM_MAX`, default 4G; `/usr/bin/time` inside the cap), per `scripts/common.sh`'s `CAPPED_TEST`
  convention. The build steps were already capped.
- **F4 (P3) — wiring/docs.** `memory-access-test` joins row 1's executable list (`17 0 on`), so `Unit.MemoryAccessProofs`
  compiles in row 1 and not only via row 13; `lean_frontend/CLAUDE.md` names the executable and the script;
  `SUPPORTED.md`'s Domain row names the opt-in receipt buffer as a passive instrument, not SC execution.
- **F5 (P3) — the lem ruling.** `mem_common.lem` gains three TYPES shared by both targets; the generated OCaml changes
  only by those type definitions (the sole new layer-2 row, `mem_common.ml`). [USER 2026-09-04] "we don't change the lem
  structure for ocaml" targets function/body restructuring for the Lean target's sake; a single-source data type both
  implementations consume is the mirror-correct choice (a hand copy on either side would be the divergence), and the
  OCaml output gained no behaviour. [AGENT] judged within the ruling's purpose; recorded here for the operator.
- **F6 (N) — store-hook placement.** OCaml records inside its first `update` before the union/read-only bookkeeping;
  Lean after. Same receipt content, equal final states; now a deliberate-divergence note in `CerbMem.lean`.
- Notes F7–F12 (refused `strict_reads` arm returns `st`; MemState has 15 fields; fuel numerals 17/64 in the Python
  harness under the CERB_TEST_FUEL precedent; symbolic/CHERI stubs type-correct by inspection but uncompiled; evidence is
  184 KiB of JSON/txt, no archives; the 8 Python `assert` controls vanish under `-O`) stand as recorded.

