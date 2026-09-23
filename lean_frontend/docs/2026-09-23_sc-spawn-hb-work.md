# SC lexical spawn and happens-before queries: validated component

**Current status:** all 39 full validation lanes and the mandatory 864-case
three-engine report pass with unchanged observations/classifications. The final
focused check covers 43 paired controls and 52 imported laws. This does not
complete the public SC checker. Earlier entries below retain their development
status and failed attempts.

[AGENT, 2026-09-23] Continuation after the validated filesystem component at
`4afc1877b`. The public SC entry remains checker-pending. This slice repairs
SC-P08 and promotes the prepared action-identity and happens-before queries;
it does not certify complete SC execution.

The spawn source rationale and failed pristine/native controls are retained in
[filesystem evidence](2026-09-21_sc-prototype-evidence/filesystem-repair/README.md),
under `sc-spawn-label-draft/review.md`. C translation keeps branch labels in their
enclosing procedure, and `Erun` uses that procedure to resolve them. The actual
`Epar` producer now calls a shared constructor that inherits the lexical owner,
keeps an empty stack and preserves the original environment. The existing
Driver still allocates child errno. Direct and nested loops remain in scope.
Seven constructor laws and eleven paired controls were previously checked;
production connection and actual paired C validation remain to be done.

The shared HB query retains the complete source graph and expands each reference
synchronization edge through every action alias, including both RMW occurrences.
Missing or ambiguous mappings remain diagnostics; intermediate non-action
vertices remain in the closure. Cycles are reported as graph facts. This query
does not derive RF or synchronization, interpret C locations, or emit a language
verdict. The prepared thirty identity and twelve HB/prefix laws state local or
conditional facts; they do not prove executable Pset closure correctness or
universal reachable-input premises. Thirty-two paired query controls and native
actual-C diagnostics support integration, with failures retained in the same
filesystem archive.

Build and test changes regenerate both targets and disable the Dune cache.
Validation must cover imported laws, the actual spawn producer, paired C loop
controls, complete HB relation observations and sensitive production mutations,
then the normal full ladder and mandatory three-engine report. The ordinary
aggregate-corpus exception to the one-hour build limit applies only to the
sequential bounded validation lanes; no individual build/proof is given a larger
bound. Customer sources remain read-only; no merge or push is authorized.

A trailing blank line in the preceding filesystem proof file is removed without
changing its declarations. The prior filesystem validation's whitespace check
did not inspect that then-untracked file; the next checks include new files.


## Production connection and focused validation

Paired generation and a cache-disabled native build succeed. Lean build attempts
1 and 2 retain a namespace qualification error in the promoted HB law;
3 succeeds. The initial spawn producer law omitted Core's existing source-location
update. The corrected law preserves the actual update and proves the inherited
owner and empty child stacks. Two further laws show that arbitrary Epar bodies
have the required context decomposition and connect the producer unconditionally
at that arena. These statements impose no loop or expression-shape restriction.
The suite now exports ten spawn and forty-two identity/HB laws.

`components-1` checks 43 paired controls and fifty then-imported laws; a final
run below must include the two new direct-producer laws. `actual-c-1` checks the
shared production HB query on six original C/RMW controls, with complete native
JSON erasure equal to the retained pre-promotion observations. `spawn-c-2` checks
four actual C controls in both engines: direct while, direct for, nested branch
loops, and an ordinary function-call loop. All return Specified(1), with empty
output. Full native JSON equals the earlier isolated repair on identical paths;
paired effect metadata matches with rendered location/type/value explicitly
outside that projection. Attempt1 used the wrong runtime working directory;
its failed capture is retained, with no semantic claim.

`plants-1` compiles three isolated mutations of the actual generated producers.
Selecting one expanded alias fails the RMW expansion control; dropping diagnostics
fails missing/duplicate-mapping controls; clearing the lexical owner at Epar
reproduces the direct-loop internal error. Positive query and actual C production
controls pass, including a production rerun after the mutant. Production inputs
and source hashes are unchanged. No mutation was installed into the worktree's
production artifact tree. The full integration ladder remains pending.


## Frozen integration and remaining obligations

Build5 regenerates both targets and rebuilds the native artifacts with the Dune
cache disabled. Components2 checks all 43 paired controls and all 52 imported laws,
using only standard axioms. The updated drift manifest includes exactly the
reviewed shared constructor/query modules, their fixtures and build connections;
only the existing reducer's generated semantic hash changes. The failure-reach
register passes unchanged. Intent-to-add paths were included in the whitespace
check; trailing spaces in generated fixture copies were removed.

`spawn-hb-integration-full-20260923` passes all 39 selected lanes, with source
unchanged and no artifact issues. The mandatory 864-case report passes. Its exact
prior-row review finds zero observation/classification changes from the filesystem
checkpoint. The same 40 known Lean discrepancy/undecodable IDs remain (822
agreement, 29 differences, 11 both-undecodable, 2 not-applicable). Passing this report
does not relabel those cases as semantic agreement. The
[retained evidence](2026-09-21_sc-prototype-evidence/spawn-hb/README.md) contains
commands, identities, raw captures, failures, proofs and compiled mutants;
archive member hashes are checked by reading the archives back.

The evidence also includes an unadopted atomic physical-source query. Sixteen
paired controls, five local retention laws and six native actual-C/RMW erasures
pass. Source-shape receipts retain every byte contributor and both RMW aliases;
no nearest-whole-store substitution can hide an intervening partial write.
Ordinary representation reads remain outside that atomic-only query without a
new refusal. Four additional native C controls preserve two completing cases
and two earlier model faults. The [atomic-allocation boundary review](2026-09-23_sc-atomic-allocation-boundary.md)
records the newly observed scope of that existing UB042 path (SC-D15), including
paired/pristine evidence and the distinction from an established ISO ruling.
No atomic-source draft is connected to production in this component.

The unadopted synchronization follow-up passes fourteen paired controls, eight
kernel laws and ten native C relation/erasure checks, including SC fences; two
compiled mutations are rejected. It uses the pinned predicates directly and
still requires a justified action/location/value/MO projection and non-atomic
RF input. The global-binding follow-up passes ten paired controls, eight laws
(including exact factorization of the existing Driver update) and four native
initializer/fault-prefix erasures; three compiled mutations are rejected. A further linker-attribution draft passes twelve paired controls, seven kernel
laws and four native C erasures. An adversarial comparator control reproduces
the earlier input-search attribution mistake; following the actual map merge
and retaining the original defining key corrects that case. No draft implements
a library guard or completes SC checking. Their README files in the same archive retain exact scope,
commands and all failed attempts. Six additional native library controls
distinguish the rand/srand exception from the at_quick_exit internal-object case;
source-ordered controls have no corresponding unordered overlap. These are
selected source-order diagnostics, not full HB or SC verdicts. The focused
source audit also records commented-out and unbuilt library bodies, preventing
text matches from becoming false loaded-library evidence.

Continue the whole charter: derive actual atomic synchronization, complete
location/value/representation and lifetime composition, connect the precise
library and other boundary guards, and expose complete public SC outcomes over
all alternatives and fault prefixes. Reference SW remains an explicit input to
the HB query; its finite checks and conditional laws do not supply universal
reachable-input hypotheses or a complete checker. Customer sources remain
strictly read-only; no merge or push occurred.


## Public-entry documentation correction

The prior SC-P01 row incorrectly said the public SC entry refuses before
execution. The actual `Driver.drive true` definition first enables recording,
then binds `drive_recorded true`, and returns checker-pending only on a successful
continuation. An earlier kill remains that earlier fault under the existing ND
bind; deterministic divergence never reaches the final pending-checker kill.
The existing `SCFaults` regression explicitly checks the post-execution pending
outcome and retained effects. This is a correction to the work record, not a
behavior change or a completed prefix-checker claim. The earlier filesystem
work record's contrary sentence is corrected with this dated explanation.
