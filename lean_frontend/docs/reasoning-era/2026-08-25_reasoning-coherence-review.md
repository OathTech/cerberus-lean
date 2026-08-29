# Design-coherence review: the reasoning stack (2026-08-25)

[AGENT] review, commissioned by the operator. Question: does the
overall design of the reasoning hang together as a COHERENT STORY?
Reviewed world: the post-merge tree — worktree
`worktrees/cerberus-lean-automation-framework` @ `628730b2c` (arc-17
S3 close), diffed against mainline (the merge adds exactly the arc-17
modules: ConstructLaws, DeriveState, Kit/Env, RoundEval, T4Threaded,
T6Probe, WpGround). Method: reconstruct the story from the shop window
(README/DESIGN/PROOF), the container doctrine, and the artifacts;
every load-bearing claim below was verified by grep/read against the
tree, not taken from the records. Paths are relative to
`cerberus-lean/lean_frontend/` unless noted.

## 1. The story as it is (the newcomer's reconstruction)

One semantics, two backends, oracle-differentially validated; boring
executable statements over the fuel opsem, gate-enforced
(`relsem/RelSem/Audit.lean` statement gate, 27 slate statements);
zero in-repo axioms (arc-17 S2b: `with_tagDefs`/`forceIO` are
kernel-witnessed opaques, boundary-opaque gate), one temporal
dep-axiom (`runEffectful`) with an exact 114-name carrier pin. That
half of the story is genuinely one design and is the project's best
asset: the trust chain reads the same in PROOF.md §1, in the gates,
and in the cones.

Behind the statements, the newcomer finds FIVE generations of proof
machinery coexisting:

1. **The arc-7 whole-run atomic route** (`RelSem/IrisLang.lean`,
   `IrisState/IrisRules/IrisAdequacy`, `SlateWP.lean`): one
   `CerbPrimStep` wraps a whole-run `app` equation; OwnP over
   `driver_state`. STILL LOAD-BEARING for the ambient T1–T4
   (`T3.lean:47` `callHarnessAdequate_of_app_eq_wp` → `SlateWP` →
   `IrisAdequacy`). Retires implicitly with the ambient family at the
   S5 purge — but is not on the purge inventory by name.
2. **The chase corpus** (`Tactics/AppWalk.lean` 2435 lines,
   `WalkTrace`, the four `T*AppEq` round-chain files, `T5Prefix`):
   frozen (check_chase_freeze, 8-file allowlist), purge-bound,
   feeding the ambient route's equations meanwhile.
3. **The arc-16 refounding, landed half**: the KExpr per-step
   language (`RelSem/PerStep.lean`, `PerStepIris`, `PerStepCall`) +
   OwnP state interpretation + threaded statement faces
   (`Threaded.lean`) — this is what the flagship theorems
   (`T1Threaded`–`T3Threaded`, `T6Probe.lean`'s `T6Threaded`)
   actually run on: a WP walk over `callK` at `stateIs`, ~15 tactic
   lines per fixture, trio cones.
4. **The arc-16 refounding, dormant half**: the loop peels
   (`PerStepPeel.lean`: `dnmsK`/`driver2K`/`callK2`) + the 15
   per-round WP laws (`PerStepLaws.lean` `wpk_round_*`) + the CerbMem
   heap RA (`CerbHeapRA/CerbHeapWP`: GenHeap byte points-to,
   ghost-map allocations, rest cell, 4 op rules, own adequacy).
   Verified: NO consumer outside their own files, Audit pins, and the
   smoke/demo files (`PerStepTacSmoke`, `CerbHeapDemo.lean`'s
   `two_alloc_frame`). The ambient-facing peel adequacy bridge
   `kCallHarnessAdequate_of_wpK2` sits on the runEffectful carrier
   list; no threaded twin exists — the peels never joined the world
   the flagships live in.
5. **The arc-17 automation framework**: `derive_state`/`derive_rounds`
   (`DeriveState.lean`, `RoundEval.lean` — now 3383 lines of meta,
   larger than the walker it replaces) mint named states and
   per-round `app` equations by applying registered laws
   (`Kit/Round`, `Kit/Mem`, `Kit/Env`, `Kit/Map`,
   `ConstructLaws.lean`), with hypothesis packs, the arith minter,
   and builder walks; `wp_step`/`wp_pures` (`PerStepTactics.lean`)
   consume the minted equations; `wp_side` → `WpGround.lean`. This is
   the engine that made T6 zero-fixture-equation and moved T4 to
   round 22 and T5 to 43/≈72.

The landed proof route, in one sentence: **the evaluator mints named
per-round equations from construct laws; they compose (via
`Kit/Loop.lean` `iter_compose` for loops) into per-stage equations; a
thin 15-line WP walk over `callK` under whole-state OwnP feeds them
to `wp_step`; threaded adequacy lands the fuel-opsem statement at
trio cones.** Statement faces come in three families × two
initial-state conventions: `CallHarnessAdequate`/`UBFree` (ambient,
`relsemcore/RelSem/Call.lean:322/369`), their `Thr` twins
(`relsem/RelSem/Threaded.lean:82/95`), and the spec lab's
`HarnessRunsTo` (ambient, whole-program `drive`,
`speclab/SpecLab/DivModFiles.lean:144`, defined once and referenced
by all six families), plus per-fixture `T?Statement` /
`T?ThreadedStatement` / `T?Outcomes` wrappers and T4's guarded
`T4SeedApart` face.

## 2. Coherence verdict: MIXED — one new design landed, four old
   routes still standing, and two gaps between the new design and
   its own charter

- **One design, demonstrably working**: the arc-17 route is coherent
  end-to-end, its layer contracts are real (evaluator supplies BY
  NAME, tactics consume, frontier tags fail closed), and its scaling
  evidence is honest (T6: 51/51 rounds mechanical, zero fixture
  equation lemmas; walls answered by design, no budget bumps).
- **Accretion around it**: routes 1, 2, and 4 above are simultaneous
  in-tree presences. Routes 1–2 are scheduled debt (the purge), but
  the purge inventory as chartered ("~700K: AppWalk, WalkTrace,
  round-walk idiom, AppEq files, T5 walk scaffolding, instruments")
  names neither the arc-7 Iris route nor the dormant arc-16 half —
  the tree is on course to purge the chase and KEEP two other
  parallel step-machineries nothing consumes.
- **Gap vs the Iris-first charter, honestly stated**: (a) the WP
  layer in landed proofs is thin — the driver loop enters as ONE
  composed equation (`r_driver`), so Iris carries the harness spine
  and adequacy, while the loop content lives in the equation calculus;
  the layer that would make Iris carry the loop (peels + `wpk_round_*`)
  is parked and unconsumed. (b) Framing — the abstraction the charter
  names as THE scaling buy ("a function's proof touches only its
  footprint") — is exercised by zero landed theorems; every flagship
  binds whole-state `stateIs`. Both gaps have charted paths (S6, the
  parity ledger), but today the artifacts realize "kernel-checked
  equation calculus with an Iris shim," not yet "Iris-based program
  verifier." That is a true description the shop window does not
  currently give.

## 3. Seam-by-seam findings

### Seam 1 — two step-machineries (KExpr instance vs round evaluator)
**Finding**: in the landed proofs the relationship IS the one-story
version: the evaluator is an equation SUPPLIER; WP steps over `callK`
consume its mints (verified: `T6Probe.lean:259`, `T1Threaded.lean:467`
walk `callK`; `RoundEval` consumes `Kit.*`/`Laws.*` by name). The
two-story risk is the DORMANT peel route: `dnmsK`/`driver2K`/
`wpk_round_*` define a parallel per-round WP discharge that the T5
plan (arc-17 S3 §3.6: iter_compose + fuel algebra + wpK walk) does
not use. If T5 lands equation-side, the peels are a second engine
with no consumer — chase-shaped debt built by the refounding itself.
**Severity**: friction now; becomes a standing incoherence at S5 if
the purge doesn't rule on it. **Should be**: one declared story —
"equations are the supply; WP granularity is a free choice per proof"
— with the peels either adopted as the T5+/concurrency-era round
carrier (they are the only place ND-per-round structure exists, which
the cmm arc will want) or parked-not-merged-style deleted at S5 with
the arc-16 S3 record as their archive. A decision, not code, is the
missing artifact.

### Seam 2 — two state interpretations (OwnP vs CerbMemInterp)
**Finding**: verified — every landed theorem binds `[CerbGS …]`
(OwnP); `CerbHeapGS`/`CerbMemInterp` consumers are exactly
`CerbHeapWP`, `CerbHeapDemo` (`two_alloc_frame`), `PerStepTacSmoke`,
and Audit pins. The heap RA is demonstration-only; the S2-recorded
coexistence hazard (two `IrisGS_gen` routes selected by class binder,
"no file may bind both") is documented but unresolved by any gate.
**Severity**: not blocking S4/S5; BLOCKING for arc-18 parity —
Lithium-style `find_in_context` search needs footprint-shaped
hypotheses (`pointsToBytes`, `allocIs`), which whole-state `stateIs`
goals never produce. A goal-directed searcher over OwnP goals has
nothing to search. **Consolidates at**: S6 — the libxml2 rung should
be REQUIRED to run its memory reasoning under `CerbMemInterp` (the
round-neighbor heap laws are priced S–M in the arc-16 S3 record §3),
making the heap route load-bearing on one real theorem before arc-18
charters search over it. Long-run: one interpretation, or OwnP
explicitly labeled "harness-spine bootstrap, retiring."

### Seam 3 — the law-registry zoo
**Finding**: four vocabularies, one of them mechanically indexed and
that one orphaned. (a) `@[app_eq]` (DiscrTree scoped-env extension,
`Tactics/AppEqAttr.lean:96`) — consumed ONLY by the frozen walker
(verified: `appEqMatches` appears only in `AppWalk.lean`; RoundEval
has zero references). The freeze-gate header's claim
(`scripts/check_chase_freeze.sh`: "the @[app_eq] law table itself
SURVIVES the purge — the charter's primitive-law layer consumes it")
is TRUE of the lemmas, FALSE of the mechanism — the current law layer
consumes the lemmas by hardcoded name. (b) `Kit/*` named lemmas —
consumed by RoundEval's hardcoded dispatch and the fixtures.
(c) `ConstructLaws.lean` (`RelSem.Laws.*`, 8 laws) — the only module
with actual registry DISCIPLINE (shape docstrings, trace-atom
schemas, fixture-free gate) but no machine-readable index.
(d) `PerStepLaws.lean` (15 `wpk_*` WP laws) — unconsumed (seam 1).
Plus the tactic-facing layer (`wp_step`/`wp_side`/`wp_ground`).
**Severity**: BLOCKING arc-18 — the charter's centerpiece is
"deterministic decomposition over the S1 rule registry," and there is
no queryable registry, only a module convention plus an evaluator
switch statement. The S1 record §5 honestly enumerates the
unique-rule-per-goal-form gaps; nothing has closed them.
**Consolidation**: ONE attribute-indexed registry (the AppEqAttr
DiscrTree code is a ready in-house donor — the chase built the right
indexing mechanism and the refounding left it unwired); entries carry
law + goal-form key + frontier tag + trace schema; RoundEval dispatch
and `wp_side` consult it. Price M. Natural home: ride S5 (the purge
re-registers gates anyway) or open arc-18 with it.

### Seam 4 — the statement-form zoo
**Finding**: the idioms are: ambient call-face + UBFree
(relsemcore), threaded twins (relsem), speclab whole-program
`HarnessRunsTo` (ambient; note it is defined ONCE and shared — the
S2b record's "copied per family" overstates; other families reference
`DivMod.HarnessRunsTo`), per-fixture Statement/Outcomes wrappers, and
T4's guarded face. Load-bearing differences: call-a-function vs
run-the-whole-program (the harness doctrine makes the whole-program
form the doctrinally primary one), spec-predicate vs verdict-int, and
T4's apartness hypothesis (a semantic necessity, kernel-witnessed).
Historical differences: ambient vs threaded (converging), and the
Thr faces living in the PROOF package (`relsem/RelSem/Threaded.lean`)
— which the S2b record itself flags as the blocker for threading
speclab (the one-way semantics→verification seam forbids speclab
importing relsem). **Severity**: friction; one piece (statement-face
homing) is a REQUIRED prerequisite for S4. **Post-purge target
vocabulary** (one sentence): a semantics-side threaded initial state
+ two faces — `HarnessRunsToThr f seed spec` (whole-program, primary)
and `CallHarnessAdequateThr` (function-call fixtures, labeled as the
slate idiom) — with UBFree and Outcomes as derived forms and ambient
faces deleted or inverted into labeled corollaries. The homing must
be a MOVE, not a mirror-def (the project's own mirror doctrine makes
a duplicated initial-state def a standing divergence risk). Small
residue: `T4ThreadedStatement` is landed but absent from the
statement gate's slate list — add it or annotate why.

### Seam 5 — ambient vs threaded duality (does the plan converge?)
**Finding**: verified — the 114-name carrier pin
(`Audit.lean:1033 runEffectfulCarriers`) is exactly the ambient
family plus its route-demo theorems (`T1_perStep`, `t1_wpK_tac`,
`kCallHarnessAdequate_of_wpK2`, the labeled bridges). OUTSIDE that
set, the duality is kept alive by exactly: (a) speclab — 46
statements + 15 proof lemmas quoting the ambient initial state,
pinned quartet in `speclab/SpecLabAudit.lean`, registered for the S4
family-∀ re-land (M + the seam-4 S prerequisite); (b) the ambient
statement DEFS themselves (`relsemcore/Call.lean`,
`HarnessRunsTo`) — defs carry no cones but keep the vocabulary
alive; the purge should rule on them; (c) compiled driver paths —
permanent by design, out of every cone. So YES, the plan converges
IF S4 executes as registered; no hidden third population was found.
One planning note: purging the 114 carriers deletes the theorems that
are the ONLY consumers of `PerStepSmoke`/`PerStepTacSmoke` and the
`_of_wpK2` bridges — the purge inventory should name those modules
explicitly (see seam 1) or they survive as empty shells.
**Severity**: on-plan; inventory-completeness risk only.

### Seam 6 — the proof-route ladder's layer contracts
**Finding**: evaluator→tactic contract: DEFINED and in-tree
(DeriveState/PerStepTactics headers + the S0 record §1.1: minted
equations feed `wp_step` by name; frontier-tag taxonomy). Tactic→
invariant contract: iter_compose (`Kit/Loop.lean:56`) is a PURE
fuel-composition lemma consuming the evaluator's `chain` mode
(`_chainrel` ∀-fuel equations) — defined, exercised on smoke, T5
unlanded. Note the honest naming issue: "T5 by invariant" is an
invariant at the EQUATION level (a state family `St : Nat → σ`), not
an Iris-level invariant rule — fine, but the charter's "iter_compose/
löb" phrasing suggests an Iris story the artifacts don't have (löb
appears nowhere; verified). Invariant→search contract: NOT defined —
it exists as the S1 record §5 gap list plus the S0 trace-format SPEC
(designed, unimplemented, schemas embedded in docstrings). The
arc-18 contract currently lives across six dated records.
**Severity**: friction now, arc-18-blocking in aggregate with seam 3.
**Consolidation**: one living machinery document (or the registry
module's header, gate-checked like the shop window) stating the
ladder's contracts as they ARE — the shop-window doctrine applied to
the proof machinery, which currently has no shop window at all.

### Additional findings (outside the given map)

- **F7 — shop-window rot, front and center**: `TODO.md` "In flight"
  still headlines "In-chase sealing + landing T5" citing the seals
  section of the SUPERSEDED stepper design, and "Next, in sequence"
  lists "The compositional stepper" — both falsified/superseded by
  the operator's own 08-24 rulings; only the axiom item was updated
  in S2b. `PROOF.md` §4 still presents the walker/sealing/replay
  workbench as the CURRENT machinery with the refounding as
  "direction of travel," while §1/§3 (rewritten in S2b) describe the
  post-refounding world — the document disagrees with itself about
  which era it is. Severity: cosmetic in mechanism, high in
  professor-visibility; violates the shop-window doctrine verbatim.
- **F8 — the evaluator's growth is the recurrence-risk locus**:
  `RoundEval.lean` at 3383 lines with dual execution modes
  (materialized vs builder, split after a measured both-ways
  regression), transparency fences, `.all` digs, and closure lanes.
  Outputs are kernel-checked (right trust story) and every wall was
  answered with design, but the S3 record itself flags one region as
  "representation-level combat, the trick-filter prong-2 tell." The
  coherent end-state is the one the pull_constrained fix models:
  recurring engine behavior migrates into REGISTERED LAWS and the
  engine stays a thin law-applier. Without that standing rule, the
  evaluator is where the chase's failure mode would reincarnate.
- **F9 — worktree hygiene at merge**: untracked scratch
  (`relsem/ProbeStd.lean`, `ProbeT5Body.lean`, `ProbeWhnf.lean`)
  sits in the worktree although the S3 record claims probe scratch
  was deleted. Untracked, so it cannot merge — but delete before the
  merge audit or the record is inaccurate.

## 4. Prioritized consolidation moves (priced, sequenced against
   S3b identity-law → S4 family-∀ → S5 purge → S6 libxml2 → arc-18)

1. **Doc truth pass (S; before/with the merge or S3b).** Rewrite
   TODO.md's In-flight/Next to the arc-17 plan; rewrite PROOF.md §4
   to present evaluator+laws+WP as current and the walker as
   purge-bound legacy; fix the check_chase_freeze header's @[app_eq]
   claim. Cheapest coherence per line in the repo.
2. **Purge-scope ruling (decision + S; at the S5 charter).** Extend
   the purge inventory from "the chase surfaces" to "everything not
   on the one route": arc-7 `IrisLang/IrisState/IrisRules/
   IrisAdequacy` + `SlateWP` (fall with the ambient family),
   `PerStepSmoke`/`PerStepTacSmoke`, the `_of_wpK2` bridges, the
   ambient statement faces (delete or invert to labeled corollaries),
   and an explicit KEEP-or-DELETE ruling on the peels +
   `PerStepLaws` (keep only with a named future consumer — the cmm
   arc's per-round ND granularity is the honest candidate — else
   prune-don't-merge applies to one's own refounding too). The S5
   success bar becomes: exactly ONE step-machinery, ONE
   interpretation binding per theorem, ONE statement family +
   labeled derivations.
3. **The one registry (M; ride S5 or open arc-18).** Seam 3's
   attribute-indexed registry unifying Kit/ConstructLaws entries
   (and the surviving wpk laws if kept), with goal-form keys,
   frontier tags, and trace schemas as fields; RoundEval dispatch
   and wp_side consult it; the AppEqAttr DiscrTree machinery is the
   donor or is deleted. This is the artifact arc-18's charter
   already assumes exists.
4. **Statement homing + family-∀ (S prerequisite + M; = S4 as
   registered).** Move (not mirror) the threaded initial state and
   faces semantics-side; define the threaded whole-program face;
   re-land speclab statements threaded in the same rewrite. Add
   `T4ThreadedStatement` to the statement gate.
5. **Make the heap RA load-bearing (M–L; = S6's shape).** The
   libxml2 rung's memory reasoning runs under `CerbMemInterp`
   (round-neighbor heap laws, S–M per arc-16 S3 §3); success
   criterion: one real theorem whose proof FRAMES. Resolve the
   dual-interpretation hazard in the same slice (declare roles or
   unify).
6. **Engine-to-law migration rule (S, standing).** Charter language
   for arc-18: any RoundEval mechanism that encodes SEMANTIC
   knowledge (as opposed to elaborator-handling) and fires twice
   becomes a registered law; the evaluator's line count is a watched
   metric with down-pressure like proof length.

## 5. Closing judgment

The single change that would most improve coherence: **broaden S5
from "delete the chase" to "leave exactly one route," with the
unified law registry as its constructive core (moves 2+3 as one
package).** The project's stated principles are all conditionally
satisfied by the arc-17 route — kernel-only, canon-named, statements
boring and fuel-opsem-only, walls answered with design — and its one
genuinely landed novelty (law-driven minting) passes the trick
filter. What breaks the story today is not any single wrong artifact
but that the tree still contains every previous answer to the same
question: four step-machineries, two interpretations, four law
vocabularies, two statement conventions. The purge is already the
designated consolidation vehicle; as chartered it removes only the
oldest layer. Aim it at "one route survives," make the registry that
route's public interface, and the post-S5 tree tells one story that
arc-18 can search over — which is the story the operator already
blessed.
