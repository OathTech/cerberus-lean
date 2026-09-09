# ND fuel stability — adversarial audit

[AGENT 2026-09-09, independent adversarial subagent] **Verdict: PASS for the
six-worker, fixed-operand stability slice.** No blocking, high, medium, or
kernel-proof finding. One low documentation finding is recorded below. This
verdict does not authorize merging: the user's external-review pause remains
in force.

Audited candidate: `7c8bbbd3a04f586ede111d7dd9b4b5ffe63caf7a`, based on
`df7ca32fed45acfacf015c35e016ff7a8c4f775a`, on `arc/nd-fuel-stability`.
The scope was all nine changed files, with direct inspection of the shipped
runner and generated bind/lift equations. The audit began on September 8 UTC
and completed its checks on September 9 UTC. Applicable container, repository,
and frontend `CLAUDE.md` instructions were read; no applicable `AGENTS.md` was
found. No implementation, existing record, runtime atom, pin, or baseline was
edited by the auditor. No merge, push, delegation, or separately owned legacy
csmith operation was performed.

## Findings

| ID | Severity | Evidence at the candidate | Disposition |
|---|---|---|---|
| F1 | Low, documentation only | `lean_frontend/docs/2026-09-08_nd-fuel-stability-record.md:119` has a blank line between the command table's separator and its first body row. The blank line terminates the Markdown table, losing the intended body rendering. | Remove that blank line when recording the audit disposition. Reported by the orchestrator and confirmed by this auditor; the orchestrator has prepared the correction for its separate documentation commit. No proof or receipt data change is needed. |

There are no required implementation fixes. The following scope limitations
are properties of the reviewed API, not newly discovered defects.

## Adversarial assessment of the contracts

- **Premises are not hidden completion assumptions about the later run.**
  `CerbNDFuelProofs.lean:393`, `:400`, and `:407` require `n ≤ k` and
  `NoFuel` of the earlier observation. The three worker contracts at `:430`,
  `:437`, and `:447` independently quantify `n ≤ k` and `b ≤ b'`.
  Their conclusions are the `ObservationStability` fields at `:415`, each
  with its own earlier-mode premise. No assumption presupposes the desired
  equality or completion at the larger budget.
- **The equality is exact.** `ResultsRefine` at `:101` retains whole tuples,
  including the state inside `Killed`, the diagnostic-string list, and the
  returned final state. Only an `IsFuel` leaf can be replaced by a result
  block. The `NoFuel` elimination at `:123` therefore produces list equality,
  preserving order and multiplicity. `fold_refines` at `:137` follows the
  shipped prepend fold for `NDnd`/`NDstep` (`CerbND.lean:134`, `:153`), while
  the branch case at `CerbNDFuelProofs.lean:178` follows left-then-right append
  (`CerbND.lean:147`). A fresh probe retained two identical observations;
  the result is not a set or a deduplicated list.
- **Empty results are intentional, and fuel zero cannot masquerade as an
  empty completion.** `NoFuel []` is true, but each zero-budget runner emits
  a singleton fuel kill (`CerbND.lean:121`, `:209`, `:258`). The fresh
  `no_zero_completion` probe proves the exhaustive zero premise impossible
  for every input and initial state. Empty `NDnd`/`NDstep` nodes remain empty
  after their node is inspected. The nested-empty trace probe proves that
  their nonempty label list is preserved even when the observation list is
  empty. This API proves stability of empty enumeration; it does not prove
  that an execution exists or that an active result was reached.
- **First-trace completion does not imply exhaustive completion.**
  `test/Unit/NDFuelStabilityTest.lean:20` and `:40` exhibit an exhausted
  sibling while branch zero is complete. `run1_refines` (`:185` in the proof
  module) follows only the selected head/left child, matching the runner.
  The trace proof at `:225` preserves the whole label/result pair; branch
  counts use `ListRel.length_eq`, and the printer is held fixed. Fresh probes
  exercised `.first` and `.trace` for bind, liftND, and liftAction with
  independent observer/worker bounds, including nonidentity info mapping.
- **Stateful lift cost is accounted for.** The generated mutual equations
  at `generated/Nondeterminism.lean:330` and `:333` spend separate frames in
  liftND and liftAction. The paired induction (`CerbNDFuelProofs.lean:313`)
  follows both and applies the action relation at `put s u` (`:347`). It
  does not require lens laws. The existing witness at
  `test/Unit/NDFuelStabilityTest.lean:83` checks the update before exhaustion
  at worker fuel one. The fresh short-budget probe checks worker fuel five
  on the fork: the deeper result is `Killed (3, 15) fuelExhaustedKill` with
  returned state `(3, 15)`, while the other result remains active at `(2, 11)`.
  Worker fuel six completes both, as the shipped `lift_complete` witness at
  `:86` states. Fresh probes also preserve an `Other` error mapped from Unit
  to Nat and its exact updated state.
- **The fuel predicate is structural and conservative.**
  `CerbNDFuelProofs.lean:15` compares against the full distinguished kill;
  it does not classify rendered message strings or assume location
  distinctness. A deliberate return of that same kill fails `NoFuel`, even
  if its result would otherwise be stable; the fresh sentinel probe proves
  this. Conversely, the existing ordinary-error witness at
  `test/Unit/NDFuelStabilityTest.lean:119` uses the same opaque location with
  a different message and satisfies the premise. The proofs do not establish
  freshness, inequality, or runtime unforgeability of the opaque location.
  Inherited broader atom-interpretation commentary is not needed to justify
  these stability results.
- **Fixed means fixed across both sides.** The wrapper equations at
  `CerbNDFuelProofs.lean:457` install different infrastructure instances but
  pass the same operands, continuations, maps, printers, and initial state.
  The existing captured-input counterexample at
  `test/Unit/NDFuelStabilityTest.lean:129` is substantive. An additional
  fresh counterexample keeps the input leaf fixed but reconstructs a
  continuation returning `LemFuel.fuel`: at distinct positive budgets `n`
  and `k`, both computations return active results and those results differ.
  These theorems cannot be applied to a whole interpreter invocation merely
  by changing its ambient instance. Equality at one given initial state also
  does not imply equality of arbitrary state functions.

The remaining seven absorbing rows, the five reachable pending workers,
general sufficient-fuel existence, whole-interpreter ambient-fuel stability,
and oracle agreement remain open as stated in `TODO.md:67` and the
implementation record at `:196`. The existing fuel-forms classification still
certifies the zero arm, not these successor-case stability contracts.

## Build and gate wiring

The new proof module is in `handwritten_copy.manifest:65` and the library
roots at `lakefile.toml:144`. `test/Unit/TotalityProofTest.lean:48` imports
`Unit.NDFuelStabilityTest`; `lakefile.toml:203` builds that executable from
the test tree. The independent suite passed the source/generated sync gate
and library-root gate, and both new modules were also elaborated directly
from their source files using the package's complete module setup.

`scripts/check_theorem_axioms.sh:875` enumerates all twelve public worker and
wrapper contracts plus four composition/refinement theorems. The probe imports
the new module (`:885`), requires exactly one printed cone per name (`:898`),
and rejects every axiom outside the standard three (`:906`). The independent
run printed all sixteen cones, each within
`[propext, Classical.choice, Quot.sound]`; the full FUEL leg had 63 contracts.
The source censuses and non-kernel-proof-method ban also passed.

The axiom gate checks availability and dependencies; it is not a semantic
shape classifier for these new stability statements. Their actual types,
the compiled concrete witnesses, and the proof review supply that evidence.
No claim is made that the unchanged fuel-forms gate verifies these statements.

## Independent commands and results

Every build/probe shell sourced
`/home/dev/projects/cerberus-lean-proj/scripts/env.sh`, used `login:false`, and
exported `CERB_MEM_MAX=48G`. One heavy job ran at a time. No heartbeat,
recursion-limit, or proof-method override was introduced.

```sh
# Repository root:
./scripts/capped ./scripts/test_unit.sh

# lean_frontend/ (outer cap also contains lean_probe.sh's lake setup-file):
../scripts/capped ../scripts/lean_probe.sh CerbNDFuelProofs.lean
../scripts/capped ../scripts/lean_probe.sh test/Unit/NDFuelStabilityTest.lean
../scripts/capped ../scripts/lean_probe.sh ../.tmp/nd-fuel-stability/audit/Adversarial.lean
```

All four final commands exited 0. The full unit run reported the following
verbatim line and completed every subsequent gate:

```text
Total: 7 passed, 0 failed
```

Both direct source elaborations emitted no diagnostics. The final scratch
probe elaborated all its declarations and printed fourteen cones, all within
the standard three, including three using only `propext` and one using no
axioms. Two earlier scratch-only attempts failed because unqualified imported
helper names were ambiguous, followed by an overbroad qualification edit that
also changed expected label strings. Those probe-authoring errors were fixed
without changing any candidate source or expected semantic value; both failed
logs are retained. No failed candidate check was weakened or skipped.

Raw audit evidence is under `.tmp/nd-fuel-stability/audit/` in this worktree:

| Artifact | SHA-256 |
|---|---|
| `test-unit.log` | `104849a7eb599bc30bd1ae55ceb4513cc8e17a6487a41a7e65166d2777a79815` |
| `Adversarial.lean` | `4c86dc373d49f720ca14351fcb455fd9a73e77fb654e037dec09a7f6bcf4ec60` |
| `adversarial.log` | `ac136a3868a2894a7ffc5f7523d03ad3d3fdcc272bcf2d237d7f0c43db96ddd2` |

The prior full differential run was independently inspected, not rerun.
Its report SHA-256 is
`54303094e4e3840db53c910196459beffcf246737d3427a7181ece00de3bd338`.
The current LADDER file hashes to its recorded membership hash; parsing that
file reproduces the report catalogue. All 35 A+B commands occur in order with
exit 0 and cleaned containment. The three runner-added `--out` suffixes match
the output-directory behavior in `scripts/release.py:266`. All 70 stdout/stderr
log hashes match; report status is passed, selection is complete, sources and
external inputs compare unchanged, and `artifact_issues` is empty.

The B7, B9, and B10 logs confirm 1,963 GCC rows with zero baseline movement,
93/93 observation plants, and the independent-oracle counts of 709 semantic
agreements, one reviewed difference, 11 matching failures, and two interface
agreements, plus the rejected unexpected-verdict plant. These remain sampled
validation results, not consequences of the ND theorem.

Independent hash comparison against the starting snapshot found no movement
in all 63 baseline paths or all 213 generated Lean files. Both new committed
Lean modules match their exact pre-run source hashes in the full report.
The nine-file candidate diff changes no existing runtime implementation,
failure atom, model body, pin, or baseline. `git diff --check` passed. The
implementation, tests, gate code, and build wiring remained unchanged
throughout this audit. After the checks, the orchestrator prepared separate
documentation edits fixing F1 and clarifying “instance declarations” in the
implementation record; those edits are outside this auditor's commit.

## Handoff

[AGENT] The candidate is ready for the requested external review after the
documentation-only F1 correction is recorded. This audit adds only this
document to the branch. The external reviewer should preserve the fixed-input
qualification and distinguish the six local results from whole-interpreter
fuel stability. Mainline remains unmerged; external review and an explicit
per-merge decision are still pending.
