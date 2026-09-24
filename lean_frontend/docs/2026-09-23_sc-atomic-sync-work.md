# SC physical atomic sources and reference synchronization: validated query component

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


September 23, [AGENT], under the SC prototype charter and the user's general
fail-closed policy. This component exposes two shared queries over actual
recorded effects. It does not enable the public SC checker or finish its
location/value/order interpretation.

`Sc_atomic_sources` retains each completed atomic read, its full per-byte source
vector, a resolved original store when available, the physical action edge, and
every resolution issue. It searches only that read's older history suffix. A
candidate requires a unique store, the same storage/range, and unique action
aliases; later stores and the write phase of the same RMW cannot supply that
read. An unresolved candidate is diagnostic information, never evidence that
synchronization is absent. Ordinary representation reads remain separate work.

`Sc_synchronization` takes the action, source-order, modification-order and
non-atomic reads-from interpretations explicitly. It resolves the physical
atomic receipts and applies the pinned reference release-sequence, hypothetical
release-sequence and fence-aware synchronization definitions. The existing
all-vertex HB query expands action edges through every physical occurrence.
Missing/ambiguous endpoints, wrong action kinds and atomic targets supplied as
non-atomic RF remain explicit issues alongside the complete original inputs.

The query does not establish C object identity, reconstructed C value equality,
correctness of its supplied orders, race freedom, or consistent-candidate
membership. It introduces no new language exclusion or supported verdict.
SC-G02/G03/G07/G08 and the documented lock-free preprocessing dependency remain
open. Existing fault prefixes and public checker-pending behavior remain intact.

## Validation plan and prepared evidence

The isolated combined preparation passes 30 paired controls and 13 kernel laws
with only standard kernel axioms. Earlier drafts retain ten selected native
C/RMW/publication/fence controls and two synchronization mutations. Production
validation must compile the installed queries, repeat paired controls and the
law census, replay the complete C relation/erasure checks, and reject both
mutations while a positive clone and unchanged production rerun pass. These C
checks retain their explicit candidate projection and are not full C verdicts.

Regenerate both targets, rebuild with Dune caching disabled, install only to this
worktree and review the fork manifest. The frozen normal 39-command full ladder
and mandatory 864-case three-engine report then compare against the preceding
global-binding checkpoint, retaining every existing discrepancy and failed
attempt. No behavioral baseline change is proposed.

## Full-run resource scope

The integration campaign is an aggregate of bounded corpus/gate processes, at
an 8 GiB overall cap and 4 GiB per large C control, under the existing documented
long-corpus exception. Individual development builds remain bounded to 30 minutes;
isolated proof checks use 512 MiB and 20 seconds. No hour-long build/proof grind or
limit increase is authorized. Keep tracked sources and index frozen through both
final reports. Customer sources remain strictly read-only.


## Production development validation

Build 1 regenerates both targets, forces the cache-disabled native build,
installs locally, rebuilds libc, and builds all Lean roots and affected tests.
Component check 1 stops at whitespace: an extra final blank line in the new Lean
fixture. Removing it changes no definition; build 2 rebuilds the affected Lean
targets. Component check 2 then passes all 30 paired controls and 13 imported
kernel laws, with exact runtime stdout and only standard kernel axioms.
Freshness, handwritten copies, unchanged failure-reach register and whitespace
checks pass. The manifest review adds only the two queries and six native
fixture/build files, and changes the existing Makefile pin; existing generated
semantic/cosmetic pins are unchanged. Two failed historical-comment parsing
assertions and their correction are retained with the manifest review.

Production plants 1 compiles an isolated positive clone and two mutations. The
clone matches all 30 production results. Removing fence-aware SW or suppressing
unresolved-source diagnostics each fails its designated control. The local
mutant module is bound before opening the production package, preventing that
package from shadowing the mutation. An untouched production rerun matches its
original transcript and artifact hashes; sources remain unchanged.

Actual-C check 1 recompiles both diagnostic instruments against the installed
production library. Ten selected RMW/publication/fence executions match complete
RF, RS, HRS, SW and all-vertex HB relations against the prior explicit reference
calculation. Removing only the added query-result field recovers the complete
previous JSON on every case. The explicit action/value/location/MO/non-atomic RF
projection remains an input to this diagnostic. These checks are native and
finite; they do not establish paired C-to-candidate correspondence, all schedules,
or a race/consistency verdict. The frozen full integration now passes, as recorded below.

## Meaning of the query diagnostics

The six physical-source cases retain bad capture shape, unavailable storage,
absence of a single contributing store, ambiguous store identity, different
ranges and ambiguous action aliases. The four synchronization cases retain an
unresolved physical source, ambiguous action endpoints, wrong action kinds and
an atomic target supplied in the non-atomic RF input. Complete original effects,
byte vectors, selected store where available, candidate inputs and issues remain
inspectable in the shared definitions. The returned HB result retains its own
diagnostics as well; consumers must inspect both channels.

These are unresolved or malformed projection evidence, not automatic C UB or a
new upstream semantic-gap classification. Missing information cannot establish
that synchronization is absent. The relevant actual object/value/location and
source-graph interpretation must be resolved before a final verdict. Valid
ordinary representation operations remain implementation work; SC-G02 applies
only where the evidenced unresolved composition is actually required.


## Frozen integration and remaining work

The final component check repeats all 30 paired controls and 13 imported laws.
`atomic-sync-integration-full-20260923` passes all 39 selected lanes, with source
unchanged and no artifact issues. The mandatory 864-case three-engine report
passes with source unchanged. An independent comparison against the preceding
global-binding checkpoint finds zero changes to complete projected observations
or classifications. The same 40 known Lean discrepancy/undecodable IDs remain:
822 agreement, 29 differences, 11 both-undecodable, 2 not-applicable. Passing the
report does not turn its discrepant cases into agreement.

The [retained evidence](2026-09-21_sc-prototype-evidence/atomic-sync/README.md)
includes exact commands, source/build identities, captures, failed attempts,
proof sources, compiled mutations, and unchanged-production reruns. Archive
members are read back and hashed. The worktree's installed modules are the ones
used by the production C controls. No behavioral baseline or failure-reach
register changed.

These queries still require a justified interpretation of C actions, locations,
values and orders. Missing or ambiguous physical-source evidence remains visible;
it cannot establish that synchronization is absent. The public checker remains
pending, with independent faults and alternatives preserved. Continue the whole
charter through that interpretation, actual linker/artifact ownership, precise
library/boundary guards, lifetime composition and complete public outcomes.
Unadopted linker proof work is retained separately with explicit assumptions.
Customer sources remain strictly read-only; no merge or push occurred.
