# cerberus-caesium: first outcome-protocol delivery

Author: [AGENT 2026-10-20]. Provider candidate on `arc/outcome-protocol`,
checkpoints A–E. This is a provider handoff for review, not an external adoption
or re-pin. The [checkpoint record](2026-10-20_outcome-protocol-record.md) records
the gates and the actual capture demonstrations. The frozen schema and framing
are in [design v2](2026-10-20_outcome-protocol-design-v2.md), including its dated
installed-wrapper amendment. The earlier
[note-2 response](2026-10-17_consumer-note-cerberus-caesium-response-note-2.md)
is historical; this note supplies the delivered interface.

Provider validation is currently parked at the aggregate timing tripwire:
Tier A passed, but Tier B is incomplete (31/42 commands). The capture
demonstrations below passed; provider close-out remains pending in the record.

## What the first delivery exposes

The wire carries one fixed-arity JSON array after `cerberus-lean stop `, with
string version `"1"`. The Python objects retain all fields and every occurrence.
These are diagnostic declarations, not proofs of origin or correspondence.
CONTRACT §1 still permits only verdict, refusal, resource outcome or registered
deviation; the protocol does not create a fifth permitted result.

| Family at this delivery | Channel and status | Meaning and metadata |
|---|---|---|
| Declared driver refusals, including each rejected switch element | One envelope per stderr line; empty stdout; exit 2 after the collection | REFUSAL: boundary, optional item, detail, mover, optional upstream citation and see |
| Existing pure/monadic refusals and twelve config-dead switch guards | Exact LemLib panic; empty stdout; exit 134 with `LEAN_ABORT_ON_PANIC=1` | Same REFUSAL fields; refusal is incomplete, never agreement |
| Hand-written pure mirrors (71 inventoried leaves) | Exact LemLib panic, exit 134 | UPSTREAM_CRASH: site, detail, pinned repository/revision/path/line/text citation, tray state and optional see |
| Hand-written pure guards (16 inventoried leaves, including the reader-lifted CerbTags stub outside both closures) | Exact LemLib panic, exit 134 | INVARIANT: site, detail, required see; a defect regardless of the oracle |
| Nine typed kills: seven mirrors, two port guards | ModelFailure with a second outer escape layer; single record exit 1, framed multiple executions exit 0 | UPSTREAM_CRASH or INVARIANT, same metadata; every complete occurrence and execution index retained |
| Driver guard | One INVARIANT stderr envelope; empty stdout; exit 2 | A defect, not a refusal merely because the exit is 2 |
| Generated envelope-less LemLib failures | Validated panic frame, exit 134 | Legacy, origin unattributed; never inferred SHARED_CRASH |
| Exact ND fuel kill, bare fuel panic, translation fuel panic | Exact Error record at its record position, or exact panic frame | Fuel occurrences with form and execution index; no search within program data or arbitrary diagnostic text |
| Ordinary Defined/Undefined/Error | Existing batch records and exit convention | Ordinary observations; stop-looking data or Error messages have no stop authority |
| Usage errors not already declared refusals; stack aborts; unknown termination | Existing channels/statuses | No new three-class guarantee; unexplained or malformed captures remain failures |
| Host OOM/deadline evidence | Existing caller supervision | Outside `decode_stop`; bare 137 is not OOM, a positive owned `oom_kill` counter is the witness |

The original 122 pure leaves comprise 71 mirrors, 35 refusals and 16 guards.
The fixed-node refusal adapter adds one pure refusal leaf. The execution-scoped
register has 240 rows after migration, including 128 unchanged generated rows;
that register is not the complete producer inventory. Historical coarse crash
pins in validation lanes make no shared-origin claim.

## The actual consumer interface and patch recipe

Read-only check: cerberus-caesium HEAD
`7d23b26413b50d406a6e0963f81775cb04045da0`, clean tree. At that revision,
`scripts/differential.py` defines `run:148`, `parse_driver:547`,
`run_driver:573`, `driver_summary:735` and `summarise_runs:774`.
`scripts/env.sh:65` exports the `cap` function. Recheck those definitions when
applying this recipe; the provider has not changed them.

1. Give the driver invocation a raw-result option in `run` (or a small driver
   adapter). Remove `text=True, errors="replace"` for that invocation, retaining
   `(rc, stdout, stderr, seconds)`, the existing cap and timeout. Keep other
   phases' text behavior. Pin `NO_COLOR=1`, `TERM=dumb` and the already required
   `LEAN_ABORT_ON_PANIC=1`. Do not infer OOM from the runner docstring's 137 label.
2. Import `decode_stop` from the explicitly selected provider checkout matching
   the driver. Check the resolved module path; do not load an arbitrary global
   `observations` module. Invoke it on the complete raw streams and original
   status before `parse_driver`, `bad[:5]` or `head(err, 500)`.
3. Retain the `StopDecode` object in the consumer result: `stops`, `fuel`,
   `legacy_panics`, and `problems`. Each stop occurrence includes channel,
   execution index, source line/byte offset and the complete constructor object.
   Preserve repeated occurrences. Remove the ModelFailure-to-ordinary-Error
   conversion. Ordinary verdicts still use their ordinary grammar; a clean
   empty stop list is not a completion test.
4. Replace the driver path's merged-text fuel search with `bool(decoded.fuel)`.
   Before any status/resource early return in `driver_summary`, attach **all**
   cause collections. Any INVARIANT is a defect even beside a resource or a
   protocol problem. Refusal/upstream stops make the verdict set incomplete.
   Keep legacy/unattributed and malformed separate; neither acquires an origin
   from an absent envelope. Unknown 137 remains unexplained.
5. Store full metadata before display truncation. Existing `save` calls use JSON,
   so do not hand a dataclass or raw bytes directly to `json.dump`: the consumer
   must serialize its own result objects explicitly. `dataclasses.asdict` gives
   occurrence fields; add `entry.stop.kind` because it is a property, and encode
   `LegacyPanic.payload` losslessly (for example hex), with the original capture
   bytes retained by the caller. This is consumer serialization, not a new
   provider Report schema or machine CLI. Truncated text is display only.

The core call is:

```python
decoded = observations.decode_stop(out_bytes, err_bytes, rc)
record["outcome"] = decoded       # internal Python object, before serialization
has_invariant = any(isinstance(o.stop, observations.Invariant)
                    for o in decoded.stops)
```

Do not reduce this object to a single winning class. A later malformed record
does not erase earlier metadata, and retained metadata does not validate a bad
capture. The consumer's existing ordinary completion/comparison checks still
run when there are no stops, fuel, legacy panics or problems. The installed cap
wrapper's exact subshell suffix is now admitted in the single terminal wrapper
slot; arbitrary shell diagnostics remain errors. Its generic KILLED banner is
not an owned positive OOM counter.

## Demonstrated captures and limits

Reproduce from the prepared provider root, with the local toolchain environment:

```sh
CERB_MEM_MAX=48G scripts/capped python3 scripts/test_stops.py \
  --consumer-demo /path/to/cerberus-caesium \
  --out .tmp/outcome-protocol-DE/consumer
```

The demonstration patches only the raw-result option in an in-memory copy of
the current consumer `run` AST, then uses its actual cap/timeout capture shape.
All **22 captures passed**. Native adapter and driver captures cover the table's
classes/channels, multiple switch refusals, all three exact fuel forms and a
real generated legacy panic. Eight separately labelled fixtures cover mixed and
repeated typed causes, verdict/stop and stop/fuel batches, a malformed later
envelope, cross-channel invalidity with both causes retained, and diagnostic
injection through detail, program data and ordinary Error. Expected metadata and
occurrence counts are asserted, not just a nonempty stop list. No fixture is
claimed as a C end-to-end execution.

The design's real mixed program (`g() + f()`, with `g` choosing uninitialized
memcmp versus filesystem open) emitted one UPSTREAM_CRASH ModelFailure at exit
1 under `--first`. Exhaustive mode emitted one filesystem REFUSAL panic at exit
134 with empty stdout and **zero emitted ModelFailures**. Collection completeness
covers **complete emitted records only**: a pure abort during exhaustive
exploration discards already evaluated typed stops before batch printing. The
decoder cannot recover them; absence of a record does not show that its branch
was never evaluated. The constant-expression mini-run has a separate loss of
typed metadata into a generated legacy panic.

The `modelFailStopLoc` sentinel can collide with an ordinary `Loc.other` supplied
through admitted Cabs data. A parsed envelope is diagnostic metadata, not an
authenticity theorem. Pure aborts still use the existing opaque runtime boundary;
no kernel theorem turns that abort into a typed outcome. The named
[structural-outcome arc](2026-09-16_lean-only-outcomes-implementation-plan.md),
including its pure-failure dependency, remains the mover for these limits.
This handoff makes no external adoption claim.
