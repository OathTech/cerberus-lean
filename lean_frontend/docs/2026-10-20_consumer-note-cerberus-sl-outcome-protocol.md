# cerberus-sl: outcome-protocol producer and reconstruction contracts

Author: [AGENT 2026-10-20]. Provider branch `arc/outcome-protocol`, checkpoint C.
This describes the provider candidate. It does not claim a consumer re-pin or a
build of cerberus-sl. The [checkpoint record](2026-10-20_outcome-protocol-record.md)
supplies the checked commands and results; the complete protocol delivery still
includes checkpoints D and E.

## Reconstruction references now take their direct diagnostics explicitly

The production names, types and default-switch behavior of
`CerbMem.reconstructValue_lemFuel` and `CerbMem.reconstructValue` are retained.
Their failure messages now carry the outcome envelope. Equality to the old
literal-message reference is no longer the compatibility claim: opaque
`failwithI` applications at different messages cannot be equated by unfolding.

`Unit.ReconstructLegacyTest` provides `ReconstructionDiagnostics`, containing
the six direct failure messages, including an address-dependent unknown-function
message. Both the linear and indexed reference algorithms take this record as
their first argument. The reference-to-reference equations quantify over every
such record. Their historical instance, `historicalDiagnostics`, recovers the
previously frozen bodies through `historical_linear_recovers` and
`historical_indexed_recovers`. Those bodies retain their historical strings,
including old source descriptions. Shared layout and decoding callees are not
frozen by those two theorems.

The production equations use `productionDiagnostics`, constructed at the
production renderer. For example, `reconstructValueAbst_default_snd_eq_legacy`
now concludes:

```lean
(@reconstructValueAbst_lemFuel ⟨CerbGlobal.defaultSwitches⟩ fuel enumDefs
  ambient fo unionmap funptrmap addr ty bytes).2 =
  reconstructValueLegacy_lemFuel productionDiagnostics fuel enumDefs ambient
    unionmap funptrmap addr ty bytes
```

All previous input quantifiers remain: every fuel, environment, overlap closure,
map, address, type and byte list. No reachability hypothesis removes a failure
arm. The wrapper, indexed-reference and `loadM_reconstruct_default` equations
use the same production instance. A proof that applies a reference directly
must supply its diagnostic argument; a proof that depends on an old failure
string must address the changed contract explicitly. A historical instance
cannot be substituted for the production instance without a new proof.

The theorem-only seam `CerbMemDefaultFacts` continues to relate the actual
production functions at the default switch set. Its public statements do not
change. The public `CerbMem.loadM_erasure` and its test restatement
`MemoryAccessProofs.load_erasure` also retain their all-switch statements.
The switch-refusal adapter now has a fixed killed node and returns its input
state; unfolding that adapter suffices for the existing erasure proof.

## Stops retain their existing channels

The nine migrated typed failures still use `Error0 modelFailStopLoc message`.
The message is an envelope carrying UPSTREAM_CRASH or INVARIANT metadata.
`CerbFail.failStopKill`, the kill lift and the failure-time state contract retain
their types and constructors. Refusals use the runtime panic boundary or CLI
stderr/exit 2; they are not newly inserted into ordinary Error records.

The fixed-node switch adapter unfolds to:

```lean
ND fun s => (NDkilled (failwithI (CerbStop.render (.refusal r))), s)
```

Its monomorphic `refusalKill` helper makes the pure failure leaf visible to the
existing execution-register census. It introduces no new opaque atom. As with
the other runtime panic boundaries, executable refusal requires the existing
`LEAN_ABORT_ON_PANIC=1` contract; the kernel does not prove that native abort.
The existing `pnviRefuseM` whole-monad adapter is unchanged apart from rendering
its structured refusal metadata.

Collection completeness means every complete **emitted** stop record. A pure
abort during exhaustive exploration can discard previously evaluated typed
stops before printing starts. The constant-expression mini-run also has a
generated result consumer that can turn a typed failure into an unattributed
legacy panic. Neither limitation is repaired by this producer migration; the
structural-outcome arc remains the named mover. The ModelFailure sentinel
collision remains an operational limit as described in design v2 §1.2.

The seven existing reconstruction census entries remain, with the two historical
recovery theorems added. Checkpoint C records the full axiom census and kernel
replay over the changed modules and dependencies. Runtime controls are separate
evidence and do not replace those kernel checks.
