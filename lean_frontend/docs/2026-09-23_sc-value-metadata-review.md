# Validated lossless values and variadic metadata queries

2026-09-23. Parent `3f9705c9b`. This slice continues SC-P03/P05 under the
SC charter; it does not complete the public checker or change the pinned model.
Current production sources generate and compile in both targets. Component
validation and the frozen full ladder/three-engine comparison pass. Public SC
verdict integration remains unfinished.
Historical ignored drafts and their failed experiments are not validated code.

The concrete object model supplies a structural value key retaining every field,
including integer/pointer provenance, type annotations, aggregate tags and exact
floating bit words. Ordinary C value equality and existing memory operations
are unchanged. The key is a lossless identity, not automatically a Cmm RF value:
signed/unsigned views, qualified/annotated types and pointer reconstruction still
require the representation-source adapter. Other memory instances explicitly
return no key rather than fabricating one.

The reference carrier uses the standalone upstream natural-number wrappers.
`scripts/sync_sc_reference.py` derives separate Lem modules with unchanged
predicate bodies, an explicit carrier import, natural action IDs and explicit
declaration renames for both targets. Both generation recipes check that derivation. No Lem
backend/pin mutation or generated-file rewrite supplies the new instance.
The existing Core Cmm instance remains intact. This copied source includes
historical inactive predicates/stubs; it does not establish a complete
whole-program reference theorem or authorize using `statically_satisfied`.

The varargs query extracts actual `Observe_varargs` occurrences and preserves
their request/thread/abstract-ID identity and multiplicity. Read/read and
distinct-ID pairs do not conflict; create/advance/delete are metadata changes.
The supplied relation must be the final adapter's justified happens-before.
Occurrence-ID ordering merely deduplicates witnesses. No fake byte write,
scheduling edge, implicit lock or public verdict is introduced by this query.

Isolated native drafts exercised four shared/copy/ordered C controls and four
intra-thread sequencing controls, with original failures retained. Production
paired controls and Lean laws now compile. The value controls cover
all 144 comparisons of twelve floating patterns, provenance, types, aggregate
fields and metadata distinctions; current paired execution passes.
Raw-key Boolean comparison must be inspected separately from structural-key
injectivity. Kernel laws may state only their checked domains.

The full ladder and mandatory three-engine report below close this component
checkpoint. Public prefix-fault/RF integration and the remaining charter obligations
continue beyond this adapter slice; none are relabelled upstream gaps.

The first normal native build exposed automatic name suffixes that were absent
from isolated generation. The derivation now supplies explicit names on both
targets, keeping the reference carrier distinct without depending on Lem's
whole-invocation collision suffixes. Predicate bodies remain unchanged. Dune's
parent-directory sandbox warning is removed by its explicit worktree root.

## Component evidence

Production native build 2 passes the engine, local install, libc and controls;
the 453-job Lean build passes after three initial proof repairs and ordinary
source-copy regeneration. Original failed attempts are retained. The explicit
integer comparison proof follows the actual Lem instance (comparison through
`Eq0`), not an assumed `LawfulBEq` instance. No proof/resource limit was raised.

`value-metadata-checks-1` records eighteen paired value groups, ten paired metadata
groups, fifteen exported-law axiom checks and nine source-derivation checks.
Every paired line matches exactly. The additional metadata controls retain
duplicates and prefix witnesses while excluding ordinary object observations.
The laws prove structural key injectivity, actual interner branch equations,
preservation of the bound used for token freshness, metadata separation/order
rules and actual journal origin of extracted events and conflict witnesses.
Only the standard `propext`, `Classical.choice` and `Quot.sound` axioms occur.
These statements do not prove that raw key equality is the final RF equivalence
or supply a general Boolean-comparison theorem for every nested key field.

`value-metadata-c/paired-1` compares eight actual C inputs through each frontend
and recorder. Metadata events (including occurrence/request/thread/cursor IDs),
pair witnesses, graph-issue counts and complete value/output/blocking results
match exactly. Shared-cursor and copy/advance controls have three and one
inter-thread pairs; independent copies and join order have none. Two unsequenced
`va_arg` expansions have three intra-thread pairs; comma order, real function
wrappers and separate copied cursors have none. These use a diagnostic native
branch-zero selector matching Lean's first-trace selection. They are selected
records, not complete behavior sets or public SC verdicts. The source-only
relation suffices for these controls; final queries must use actual full hb.

The first isolated Lean diagnostic failed on unqualified JSON names; the second
compiled but needed its two newly imported query objects at link time. The
third links the checked existing Main object and freshly built query objects,
hash-verifying inputs rather than substituting an old runner. Both failures
remain raw evidence. The actual production drivers remained unchanged.

`value-metadata-plants-1` compiles nine isolated controls against real adapter
bodies: three positive copies pass; loss of floating bits/provenance, reuse of
one token for distinct values, treating advance as read, treating occurrence
IDs as hb, and dropping extracted events each fail at their intended control.
Production source and artifacts are never replaced by these mutations.

The fork manifest adds exactly four shared modules and four control files.
Seven prior source hashes change; the only existing generated-module delta is
`mem.ml`. All prior review text and classifications are retained. Derivation
plants reject a changed predicate body, action carrier, target name and donor,
and require each restored fixture to pass.

## Integration plan and advance resource justification

[AGENT, before dispatch] Run the complete 39-command Tier A+B ladder and then
the mandatory 864-case three-engine report on frozen production and docs.
The preceding campaign took about 92 minutes. This expected duration is a
bounded corpus/driver/fault-plant measurement required by the charter's shared
slice gates, not proof or term grind. Use one 8 GiB worker, existing command
limits and cache-disabled native builds. Do not raise proof, heartbeat,
recursion or runtime-fuel bounds. Retain incomplete/failed runs, and never call
a subset the full ladder. This is the advance justification for exceeding one
hour. Continue the whole SC charter after the validated checkpoint; public
fault/HB/location/RF integration remains unfinished.

The first full attempt stopped after A1 exposed missing imports in the failure
census instrument. Standalone reference predicates were scanned without their
compiler declaration ranges. The instrument now imports the new modules; its
execution roots, classification rules and 241-row register are unchanged. The
focused census and all five mutation controls pass with every existing row
unchanged. A2 passed; A3 was interrupted deliberately to repair the instrument.
That incomplete attempt, original diagnostics and unchanged-source result are
retained and are not a full-ladder pass.

The focused unit rerun passes. A separate sequencing diagnostic exposed an
OCaml fixture error: structural constructor order differs from Cmm's action-ID
set order for Store/Load pairs. Native value controls now use the actual action
comparator and corresponding pair order, and check well-formed threads before
testing RF. This strengthens the fixture without changing predicate bodies or
production memory operations. The source manifest changes only that control's
content pin; all prior classification/comment text is preserved. Final paired
checks and mutation checks are repeated against this fixture repair.

`value-metadata-checks-2` and `value-metadata-plants-2` pass after the comparator
repair: all 18/10 groups, 15 law checks, nine derivation checks and nine compiled
controls/mutants. The fork-content gate passes. The freshness check correctly rejected the
native stamp after the control source changed: the source set deliberately
includes controls as well as engine code. A shell sequence hid that nonzero
exit behind a later successful command, and full r2 was started prematurely.
It was stopped during A1, before any certification claim. Retain the raw
rejection and incomplete run. Rebuild/record both engines through the normal
recipe, then check each prerequisite exit explicitly before a fresh full run.

`value-metadata-build-5` passes every normal native/Lean build, install and stamp
step. `value-metadata-readiness-3` explicitly checks each subprocess exit: both
freshness and manifest return zero, and all four checked component binaries are
unchanged. Start full r3 in a new directory with frozen source/docs and the
advance resource justification above; retain both interrupted predecessors.


## Retained checkpoint and remaining integration

[AGENT] The third full attempt passed all 39 Tier A+B commands, with unchanged
source identity and no artifact issue. The mandatory 864-case three-engine run
also passed on that same frozen identity. Comparison with the atomic-interface
checkpoint finds no changed row classification or complete decoded observation;
all 40 existing Lean discrepancy IDs are unchanged. The compiler corpus has no
baseline regression. Earlier interrupted runs remain separate evidence.

The [retained evidence](2026-09-21_sc-prototype-evidence/value-metadata/summary.json)
includes source hashes, component controls, all full-run attempts, failed
build/proof recipes, raw process observations and a verified archive manifest.
Successful reconstructed Cabs inputs and rebuildable binaries are separately
hash-inventoried; failed bridges and every engine diagnostic remain captured.
No source, configuration, pristine reference or Lem pin was changed during the
final measurements. This validates the component slice, not the whole prototype.

Follow-up diagnostics are retained separately from adopted implementation:

- The [sequencing controls](2026-09-21_sc-prototype-evidence/value-metadata/atomic-sequencing-followup.md)
  extend SC-G07 to mixed ordinary/atomic unsequenced evaluations and preserve
  independently established same-scalar UB035 faults. No new guard is installed.
- The [actual-C projection review](2026-09-21_sc-prototype-evidence/value-metadata/candidate-projection-followup.md)
  records ordinary aggregate/member, flag-initialization and signed/unsigned
  view failures of the deliberately incomplete range/raw-key adapter. These
  remain implementation obligations. An inconsistent racy projection must not
  erase the concrete trace or its fault witness.
- The [initialization review](2026-09-21_sc-prototype-evidence/value-metadata/initialization-composition-followup.md)
  retains thirteen paired C controls and separate Cmm queries. Heap allocation
  and child errno can supply unspecified values without an ordinary store;
  automatic declarations can have a real unspecified store. Their reference
  composition remains under review, without a new gap ID, invented store or UB.
- The [metadata HB follow-up](2026-09-21_sc-prototype-evidence/value-metadata/metadata-hb-followup.md)
  has five native relation diagnostics and five paired source-only recorder
  controls. SC publication removes the shared-cursor witnesses, while ordinary
  publication, an unused atomic store and a different atomic object do not.
  This is not yet a paired production implementation of full happens-before.

An ordinary declaration followed by `atomic_init` fails the narrower
`SC_condition` but passes the already reviewed fence-aware condition. Final
integration therefore uses the pinned fence-aware reference with the explicit
SC request domain. The stronger initialization hypothesis belongs in any
theorem that needs it, not in a runtime refusal. No universal equivalence theorem
or new weak-order support follows from these finite controls.

Continue the whole charter: finish atomic interfaces, location/value and full-HB
composition, precise registered guards, prefix faults and complete public
outcomes. No intermediate component checkpoint reduces that target.
