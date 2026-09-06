# Validation foundations — fresh document review and corrections

2026-09-06 [AGENT]. A fresh reviewer found **one major documentary
semantic overclaim and three minor issues** at
`df40f6aa195fff9c6b0723a4d69484cd3266867c`. All four are corrected in this
documentation checkpoint. No implementation, test, gate membership, semantic
baseline or Lem pin changes are required by these findings.

**Landing is held for a renewed user decision.** The review's major finding
means the conditional merge authorization below was not satisfied. Fix size
and finding severity are different: the erroneous claim is consequential
even though its repair is a few sentences. This record does not authorize
another gate-hardening campaign or declare customer release readiness.

## Authorization and independent scope

[USER], the instruction initiating this review:

> Great, run a tightly focused document review as you propose. If it results in no major findings, fix what it finds, then execute the merge

The agreed scope was material accuracy, scope/guarantee overclaims,
consistency with the project doctrine, and coherent next priorities. The
reviewer was a newly delegated agent, `/root/fresh_document_review`, which
had not implemented or repaired this work. It read the complete assigned
documents, rather than just the repair diff. Its severity judgments and the
coordinator's corrections below are [AGENT] assessments.

Fully read by the reviewer:

- Container, repository and frontend `CLAUDE.md` files.
- Frontend `README.md`, `DESIGN.md`, `VALIDATION.md` and `TODO.md`.
- `scripts/LADDER.md`, the master plan, orchestrator handoff, supported
  profile and proposed concurrency integration charter.
- The observation contract, failure census/correspondence proposal,
  provider-smoke record, CI reporting record, original delivery record,
  audit-repair record and repair evidence index.

It checked consequential claims against compact reports, the provider proof
source, the runtime boundary register, relevant script/source passages and
Git ancestry/package manifests. It did not run tests or builds, expand large
archives, or operate customer, legacy-run or other worktrees. This discharges
the standing fresh-reader requirement for this major document revision; it
does not silently accept the finding or extend the user's merge condition.

## Findings and exact corrections

Locations in this table refer to the reviewed `df40f6aa195f` source.

| ID / severity | Finding and evidence | Correction in this checkpoint |
|---|---|---|
| D1 / major | `VALIDATION.md:598–601` and `:665–668` assert that every oracle-terminating run has a fuel budget at which Lean agrees; the latter appears among the explicitly supported claims. Calling it a design rationale does not qualify the universal assertion enough. The current C4 `fprintf_then_fscanf.c` witness has matching UB048 codes but different locations because Lean's libc Core text omits them; extra fuel cannot recover the missing location. Missing-feature refusals are another non-fuel limitation. | Both passages now distinguish quantified fuel and the delivered local lemmas from unestablished general completion, propagation, stability and correspondence. Explicit domain/failure/state/runtime assumptions remain necessary; more fuel does not repair non-fuel discrepancies. |
| D2 / minor | `VALIDATION.md:680–699` calls its runtime-boundary list exhaustive but omits the private `CerbMem.beqMemValueSafe` opaque, implemented by unsafe `beqMemValueImpl` (`CerbMem.lean:239–242`). The machine register and supported profile already disclose it. | Add the equality seam and its unproved logical/native correspondence obligation to the list. |
| D3 / minor | Master plan `:229–230` still says two Lean timeouts; the repaired C4 measurement and other current summaries say three. | Correct the count to three. Preserve the recorded timeout classification movement and historical measurements. |
| D4 / minor | Frontend `CLAUDE.md:288` says URI oracle invocations use the arc-12 grandfather exception. `test_libxml2_uri.sh:139–143` records its removal by arc-13 single-supply renumbering. | Describe the ordinary invocation and remove the obsolete exception instruction. |

The coordinator checked the supporting source and applied these corrections.
The master plan, current handoff and validation overview also point to this
review and distinguish its completed review from the pending landing
decision. Earlier audit reports and evidence remain historical records.
No second independent review of this correction diff is claimed.

The major finding does not identify a new executable regression. It corrects
what the provider promises about known behavior. The review found no other
major issue in its bounded document scope; it was not a renewed code audit.

## Validation and source boundary

The executable source remains the fully tested functional candidate
`de9f6d3612232d581622afcdf0b23cdaf31fa09d`. Its retained full Tier A+B
measurement is 32/32 at 4,073.980 summed seconds; the cold provider rehearsal
completed all 20 commands. The cold theorem concerns its fixed completed
Core fixture and delivered map law, not arbitrary C or customer adoption.

For this review, the coordinator independently verified:

- All 31 files in the repair packet's `SHA256SUMS` and all eight files in the
  second-review packet's checksum list, without expanding their archives.
- The retained full report's SHA-256, complete 32-command selection,
  successful statuses, unchanged source and every recorded command-log hash.
- No executable or ladder change between the functional candidate and
  `df40f6aa195f`, and a documentation-only correction diff thereafter.
- Lem mainline, pinned-source HEAD and `cerberus-pin`, installed compiler
  version, opam pin target, and all three Lake manifest revisions/input
  revisions agree on `f6542f8e6860d12d4655e6648bc4c45dabd1d798`.
- Cerberus mainline remains `89f7e688530c6910884518811d645e4e892e4507`,
  an ancestor of the primary candidate. The older concurrency instrument
  companion `86a2aea547804b78eb7f1eae633bb9c24c713b7f` is separate.

The pinned Lem worktree has three pre-existing untracked OCaml installation
files; they were not changed or removed. No functional Lem work occurred,
so a new two-repository pin dance is unnecessary for this candidate.

The documentation checkpoint passed **Tier A 13/13**, 386.136 summed seconds,
through the project environment with `CERB_MEM_MAX=32G` and
`DUNE_CACHE=disabled`. Source and external inputs were unchanged throughout;
there were no artifact issues and all owned command scopes were removed.
The 29 changed artifact hashes are version-bearing OCaml/runtime products
and freshness stamps; the Lean executable and both driver source
fingerprints are unchanged. These differences are recorded, not hidden.

The [compact evidence archive](validation-foundations-document-review-evidence.tar.gz)
contains 35 verified members: the report and derived checkpoint summary,
all 26 command logs, the tested diff and five tested document snapshots.
It is 316,706 bytes; SHA-256:
`9bfc16c70ab4dde6aa49e08c71eff9cd28247f4306d7bedf6bbfdb7f1ff78ed4`.
Every archived member was read back and checked against its original bytes.
Publication after the run changes only this result paragraph and adds that
archive. No full semantic corpus is duplicated. The retained full/cold
measurements are not presented as newly executed.

## Landing and next work

The primary candidate remains eligible for a fast-forward from the unchanged
mainline, subject to renewed user authorization after this major finding.
There is no merge or push in this checkpoint. Recheck heads and pins at the
actual merge; mainline movement requires the standing revalidation/discussion
procedure. Push authorization is separate.

The implementation recommendation is unchanged: end the validation-only arc
and discuss the scoped SC integration charter, including its supported
domain and provider agreement theorem. Keep the small maintenance
simplifications from the repairing-agent second review bounded. C2/C3 stay
outside this dispatch, refined-cerberus adoption stays with its agent, and
the original concurrency worktree remains untouched.
