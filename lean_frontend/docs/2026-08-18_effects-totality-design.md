# Effects + totality design note (arc 1, slice 1)

Status: DRAFT — ends at the slice-1 USER CHECKPOINT (design ruling).
Charter: `2026-08-18_arc1-effects-totality-charter.md`. Pattern source:
golean (`deps/golean/docs/2026-07-18_totality-fuel-decision.md`,
`2026-07-21_eval-totalization-correspondence.md`).

## 1. Census (measured on `arc/effects-totality` @ bd9824e37, lem dff1957)

Effects — 6 effectful vals in 3 model files, 315 generated call sites:

| Effect | Vals | Sites | Where |
|---|---|---|---|
| debug | `get_level`, `print_debug` | **302** | everywhere (30 modules) |
| fresh | `fresh_int` | 8 | Symbol (7 wrappers), Translation_effect |
| tagDefs | `tagDefs`, `set_tagDefs`, `reset_tagDefs` | 5 | Ctype_aux (reads), Core_unstruct |

Transitive caller closure of the 13 non-debug sites: **263 defs** across the
pipeline. But restricted to the **execution slice** (Core_run, Core_reduction,
Core_eval, Driver, Defacto_memory, Core_aux — the fuel-opsem TCB):

- `fresh` usage: **zero**. All fresh flows through desugar/translation.
- tagDefs usage: **reads only** (6 sites, all in Defacto_memory via
  `get_structDef`/`get_unionDef`/`get_membersDefs`); writes happen only in
  desugaring (`register_tag_definition`) and Core_unstruct.
- debug: stubbable (§3).

Totality — 444 `partial def` in the built tree = **306 lem-generated**
(Cabs_to_ail 50, Core_aux 37, Core_rewrite 16, Defacto_memory 15,
GenTyping 14, Core_reduction 11, …) + 138 hand-written parsing infra
(CoreParser 87, CabsImport 37 — not proof-path).

## 2. Structural findings (change the problem)

- **F1 — HOL precedent for debug stubs**: `debug.lem` already declares
  `hol target_rep function get_level u = 0`. Debug effects are semantically
  inert; theorem-prover targets stub them.
- **F2 — the model already has the tagDefs seam**: `ctype_aux.lem` defines
  `get_structDef_with_tagDefs` (parameterized) with `get_structDef` as the
  global-reading convenience wrapper. tagDefs is set-then-frozen: written
  during desugar, read-only during execution.
- **F3 — defacto_memory is already monadic**: own state monad `impl_memM`
  with `get`/`put`; `fresh_allocation_id` is *already threaded through
  monad state*, and `print_debugM` exists. The effectful externs in the
  Lean port are conveniences of the port, not structural necessities of
  the model.
- **F4 — nondeterminism is already reified**: `ndM` is a constructor tree
  (`NDnd`/`NDguard`/`NDbranch`/`NDstep`) with explicit state. Outcome-set
  (exhaustive) semantics is first-class in the model; the fuel opsem
  interprets this tree. No ND design work needed at the lem level.
- **F5 — lem has a termination-settings hook**: `try_termination_proof`
  consults per-constant termination settings; the backend already emits
  `def` (Lean equation compiler) when set, `partial def` otherwise. A fuel
  mode slots into existing machinery.
- **F6 — TCB scoping**: goal 2's theorem substrate is the *Core execution*
  semantics. Desugar/translation are *translators*: in the TCB the way the
  OCaml C parser is — validated differentially (goal 1), not proved over.
  The scaffold (never_extract + unsafe externs) is sound for translators
  indefinitely; it must merely never be reachable from proof-path terms.

## 3. Effects design options

- **O-A: full monadic lifting** (the `549e2ac` sketch at full generality).
  Backend effect inference; the 263-def closure re-typed into an effect
  monad in Lean output. Honest everywhere; largest lem feature; churns the
  entire generated surface; most upstream-review risk.
- **O-B: stratified honesty (RECOMMENDED)**:
  1. *debug* → pure stubs on the proof path (`get_level = 0`,
     `print_debug _ _ = ()`), HOL-style, via ordinary `lean` target_reps.
     Kills 302/315 sites. (Execution keeps IO externs only if we decide
     debug output from the Lean pipeline is worth a dual-flavor mechanism —
     default: no; differential debugging uses the OCaml side.)
  2. *tagDefs on the execution slice* → **reader-style threading**,
     backend-lifted: a `declare {lean} reader val tagDefs`-class mechanism
     making defs that (transitively) read tagDefs take it as an extra
     Lean-side argument, seeded at the opsem entry point. Reader lifting is
     argument-threading only — no bind restructuring — and the measured
     scope is ~75 exec-slice defs. Aligns with F2 (the model's own
     `_with_tagDefs` shape) without touching `.lem`.
  3. *fresh + tagDefs-writes* (desugar/translation only) → keep the
     scaffold, marked execution-only. Their honest treatment becomes part
     of a later "verified translation" arc if ever wanted; F6 says it is
     not on the goal-2 critical path.
- **O-C: scaffold everywhere, prove around it** — rejected: memory ops
  read tagDefs, so the exec slice would have unsafe externs reachable from
  proof-facing terms. Fails the TCB statement.

## 4. Totality design (golean pattern, adapted)

1. **Structural first**: most of the 306 recursions are over syntax/value
   trees (ctype, expr, mem_value). Flip these to plain `def` via lem's
   existing termination settings (per-family declares; Lean's equation
   compiler does the work). Expect a long tail that needs small backend
   fixes rather than fuel.
2. **Fuel only at genuinely non-structural points**: the driver/reduction
   step loops and env-mediated recursions. New declare (strawman syntax:
   `declare {lean} fuel val core_steps`) emitting a fuel'd worker
   (`f_fuel : Nat → …`, sentinel on zero — composed into the existing
   error/ndM channel, no new carrier) + a thin wrapper at default fuel so
   call sites are unchanged (golean's exact shape; their cost line —
   "fuel large enough" side conditions, dischargeable — accepted).
3. Fuel is decremented only at the declared points, never on structural
   descent: it bounds step counts/nesting depth, not value size.

## 5. TCB statement (the design's honesty contract)

Proof path (exec slice, post-design): pure defs, tagDefs by argument,
debug stubbed, ND as tree interpretation, fuel explicit. Axioms: none
reachable except the declared boundary list (DAEMON Inhabited fallbacks —
audited separately, Phase 1). Scaffold (`runEffectful` + unsafe externs):
reachable only from translator stages; the correspondence obligation
execution↔proof is *definitional equality per def* (same generated code,
differing only in the three seams above), not a simulation proof.

## 6. Slice-2 exemplar (proposal — CHARTER DEVIATION, flagged)

The charter named `fresh_int` as the exemplar. The census shows fresh is
NOT on the proof path; the representative exemplar is:

- **tagDefs-read reader lifting** through `get_structDef` →
  `Defacto_memory.get_membersDefs` → one memory op, seeded at an entry
  point; `fresh-int-test` stays green via scaffold (unchanged, execution);
  a new unit test exercises the lifted path.
- **One fuel'd family**: a small non-structural exec-slice recursion
  (candidate: the `core_steps`-style loop in Core_run or the ctype
  resolution in Defacto_memory), plus one structural family flipped to
  total `def` via termination settings.
- **Toy theorem** over the exemplar output (e.g. a `get_membersDefs`
  lookup lemma, or determinism of the fuel'd step on a trivial program) —
  the reasoning smoke test the scaffold cannot pass.

## 7. CHECKPOINT RULINGS (user, 2026-08-18 — slice 1)

All four recommendations ruled as recommended: **O-B stratified honesty**;
**debug stubbed everywhere** (revisit on pain); **reader lifting as a lem
declare class** (upstreamable); **exemplar swapped to tagDefs+fuel** (the
charter's fresh_int exemplar is superseded — fresh stays scaffold-only in
translator stages, its honest treatment deferred to a possible future
verified-translation arc). Q5 (fuel declare shape) deliberately left to
slice-2 iteration.

## 7a. Slice-2 findings (implementation, 2026-08-18)

- Debug stubs (2a): 315 → 16 runEffectful sites; gate at baseline.
- Reader lifting (2b): implemented in lem (`declare {lean} reader val`,
  lem-lean `b51ef11`) — fixpoint pre-pass per module (emission renders
  last-to-first, so in-order registration was unsound; caught by the
  transitivity test), parameter injection at the bare-Constant rendering
  (exactly once), fail-closed on instance methods. Applied to `tagDefs`:
  full cerberus build green with only **two hand-written seed sites**
  (`desugar`, `drive` in Main.lean), both seeded from the live global via
  the hardened accessor (`CerbTags.tagDefs`, now `never_extract`).
- Debug stubs NARROWED the reader closure sharply: GenTyping/AilTypesAux
  no longer lift at all (their effect use was debug-only); the tagDefs
  read closure is desugar-init + Defacto_memory + Core_run/Driver.
- **Seed-freshness argument**: OCaml's global is also unset during
  desugaring (desugar threads tag defs in its own monad state; only later
  stages call set_tagDefs), so entry seeding ≡ OCaml behavior — EXCEPT
  across mid-phase writes: the single `with_tagDefs` rebinding site
  (mini_pipeline, WIP translator glue) and any set-then-read within one
  lifted region (Core_unstruct — audit when the pipeline reaches it).
  Recorded as a correctness obligation for the Phase-2 desugar arc, not a
  blocker: the execution slice seeds at `drive` AFTER registration, which
  is unconditionally correct.

## 7b. Slice-2c findings — totality exemplar + reasoning smoke test

- The existing lem hook works unchanged for the structural case:
  `declare {lean} termination_argument f = automatic` (placed AFTER the
  definition) flips emission from `partial def` to `def`, and Lean's
  equation compiler accepts `core_object_type_of_ctype` (ctype-structural).
  No new lem feature needed for this class — the totality work for the
  ~306 generated partials is a declare-audit sweep plus fixes for
  whatever the checker rejects.
- `zeros_aux` REJECTED as expected: its Struct/Union cases recurse on
  member types fetched from tagDefs — env-mediated recursion, golean's
  `.defined` class exactly. Reverted to `partial`, designated the first
  fuel candidate. The fuel declare (Q5) remains the one unimplemented
  mechanism; its design should carry a sentinel expression per declare
  (generic honest fuel-out values don't exist without type knowledge).
- **Reasoning smoke test green** (`effects-proof-test`, in the unit
  gate): three SYMBOLIC `rfl` theorems over the now-total
  `core_object_type_of_ctype` (impossible over `partial def` — no
  equations) and a lookup theorem over reader-lifted `get_membersDefs`
  (impossible over the extern scaffold — the state was invisible). Plain
  `rfl`, no native_decide, no axioms beyond the kernel.

## 7d. Slice-2d findings — the fuel declare (implemented)

`declare {lean} fuel val f = \`sentinel\`` landed in lem (64fa622): total
worker (structural on an explicit Nat), self-calls rewritten to the
decremented binder, point-free wrapper at LemLib.lemDefaultFuel so call
sites are unchanged and proofs unfold wrapper → worker definitionally.
Fail-closed on multi-clause/mutual/instances/reader-combination. Applied
to `zeros_aux` with sentinel `CerbMem.zerosFuelExhausted ()` (a hand-
written panic helper — lem's backtick strings cannot contain double
quotes, so string-literal sentinels are expressed via helpers). Lake pin
moved to the lem arc branch per the charter pin-dance. Proof test grew a
wrapper-defeq theorem and a fuel-symbolic integer-case theorem, both rfl.
The exemplar chartered for slice 2 is now COMPLETE: reader + structural
totality + fuel + theorems, all gated.

## 7c. fresh as an explicit choice-stream input (user question, 2026-08-18)

Ruled direction for the eventual honest treatment of `fresh` (parked until
a verified-translation arc needs it): an explicit CONSUMED stream/counter
input — i.e. state threading, not reader (consumption must advance, which
is exactly what reader cannot express). With the canonical stream 0,1,2,…
this is extensionally identical to OCaml's `Cerb_fresh.int`, preserving
symbol numbering and hence stage-by-stage differential comparability.
Mechanism when needed: a `declare {lean} state val` sibling of the reader
declare, threading through the desugar/translation monads the model
already has. Two alternatives considered and rejected:
- splittable supply (UniqSupply-style, reader-shaped): keeps the cheap
  transform but numbering diverges from OCaml — breaks the differential
  instrument for exactly the stages it would serve;
- ND choice stream (oracle sense): over-general — fresh is deterministic
  bookkeeping, not latitude; supply-quantified theorems would pay a
  permanent tax for envelope width the OCaml semantics does not have.

## 8. Open questions as posed (for the record)

1. O-B (stratified) vs O-A (full lifting) — is execution-slice honesty +
   translators-in-TCB acceptable as the goal-2 stance? (Recommended: yes;
   it matches "OCaml parser stays a trusted front".)
2. Debug on the Lean execution path: stub everywhere (lose Lean-side debug
   output, simplest) or dual-flavor (keep IO externs for execution)?
   (Recommended: stub everywhere; revisit on pain.)
3. Reader-lifting mechanism shape: new declare class in lem (upstreamable,
   recommended) vs hand-maintained parameterized shadow defs in the
   support files (no lem change, more drift risk)?
4. Exemplar swap per §6 (recommended) or keep fresh_int as chartered?
5. Fuel declare naming/shape — bless the strawman or iterate at slice 2?

## 9. Scale plan (slice 3, 2026-08-18)

**Effects: the goal-2 path is already converted.** After the exemplar, the
13 remaining runEffectful sites are all translator-stage (fresh + tagDefs
writes), which the O-B ruling leaves on the scaffold indefinitely. No
further effects work is needed for the fuel-opsem TCB. Deferred, with
recorded designs: fresh → consumed-stream state threading (§7c, a
'declare {lean} state val' sibling) when a verified-translation arc wants
it.

**Totality: one mechanical arc remains for the exec slice.** ~90 of the
306 lem-generated partials are execution-slice (Core_aux 37,
Defacto_memory 15, Core_reduction 11, Core_eval/Core_run/Core_typing ~20).
Strategy per the exemplar: batch `termination_argument = automatic`
declares, let Lean's checker adjudicate, fuel the rejects (the driver/
core_run step loops return ndM — honest error-channel sentinels exist).
Proposed as the next arc (**arc 2: totalize-exec-slice**), mechanical
enough for batched work, exit = zero partials in the exec-slice modules +
the proof test extended per converted family. Translator-stage partials
(Cabs_to_ail 50 etc.) can wait for their pipeline arcs.

**Known hazards carried forward** (all recorded above): instance-method
reader gap (fail-closed will fire visibly if pipeline work puts a lifted
call in an instance); with_tagDefs rebinding in mini_pipeline (Phase-2
desugar obligation); fuel wrappers restart the budget per external call
(right for depth-bounding; revisit if a cross-call budget is ever needed).

**Lem feature census for upstreaming** (Phase 4 input): effectful (fixed),
reader, fuel, termination_argument (pre-existing), extra_import,
skip_instances — all declare-scoped, no .lem model restructuring anywhere.

## 10. PRE-MERGE AUDIT RESULTS (2 adversarial agents, 2026-08-18) — CORRECTIONS

The audit refuted several of this note's claims. Corrections, binding over
anything above:

- **§1/§5/§9 are WRONG that the execution slice is fresh-free.**
  `Symbol.fresh` is called from `core_run.lem:585` (the Load action) and
  `core_reduction.lem:1251,1294` (SeqRMW/Neg) — so `runEffectful` + the
  unsafe extern counter ARE reachable from the opsem. The census grep was
  defeated by generated-code whitespace (`fresh  ()` vs pattern `fresh (`)
  and by counting where runEffectful SITES live instead of which stages
  CALL them. Honest fresh treatment is therefore ON the goal-2 critical
  path (see §11 options). Corollary: the never_extract protection being
  one-level-deep (audit) means closed applications of step functions are
  in the hazard class until this is fixed.
- **§7b's "no axioms beyond the kernel" is WRONG.** All six theorems
  depend on the DAEMON axiom (∀ {α : Type}, α — False-implying, hence the
  axiom environment is inconsistent for external checkers). The theorems
  remain non-vacuous as rfl-proofs (deletion-tested by the audit), but
  they certify nothing to a consumer until DAEMON is repaired. DAEMON
  repair (real Inhabited derivation or Nonempty-bounded axiom) is promoted
  to a top Phase-1 priority.
- **§5's axiom boundary list was incomplete**: besides DAEMON, sorryAx is
  on the exec slice (`easy_update_mem_value` target_rep in Defacto_memory
  — a known Phase-1 item — plus ~76 instance-fallback sorries in exec
  modules), and runEffectful (via fresh, above).
- **§7a's seed-freshness argument fails for the desugar seed TODAY**, not
  just in a future arc: `Cabs_to_ail` → `evalIntegerConstantExpression` →
  mini_pipeline's `with_tagDefs` extent runs the driver on the STALE entry
  seed (e.g. `int a[sizeof(struct S)]`), and worse, reads are SPLIT within
  that extent: hand-written CerbMem reads the swapped global while
  generated code reads the stale parameter. The `drive` seed remains
  correct. Note mini_pipeline.lem is port-local glue, not upstream model —
  it can be restructured freely (objective 3 does not protect it).
- **§4 deviations reconciled**: fuel decrements on ALL self-calls of a
  fuel'd def (whole-def fuel), not only non-structural ones; and the
  zeros_aux sentinel is a panic-returning-default, not an error-channel
  value. Both intended for the exemplar; §4's stronger phrasing withdrawn.
- Lem-side mechanism fixes landed in response (lem arc 1033246): pre-pass
  Val_def granularity (class-method poisoning), fuel-wrapper attributes,
  honest one-level-deep comment, infix-gap documentation.
- Theorem-strength notes accepted: wrapper-defeq certifies shape only;
  fuel recursion is not yet exercised by any theorem.

## 11. Replanning input: is the requirement set satisfiable? (2026-08-18)

The audit sharpened a real three-way tension at exec-slice fresh:
(a) honesty (no hidden state under theorems), (b) objective 3 (declares
only, no .lem restructuring), (c) OCaml-identical observable behavior.
Pick any two cleanly; all three need one of these relaxations:

- **R1 — backend monadification, scoped**: a `declare {lean} state val`
  that threads a counter through the fresh closure on the exec slice
  (step_ctx/core_action_step and callers), Lean-output-only. Keeps (b)
  and (c); costs the O-A machinery we hoped to avoid (bends objective 4's
  "keep lem reasonable" — this is a real compiler feature, upstream
  review risk).
- **R2 — small upstreamable .lem patch**: thread the fresh counter
  through the EXISTING core-run thread state (the model already threads
  state everywhere else; OCaml upstream might well accept explicit
  threading as an improvement). Bends (b)'s letter, arguably keeps its
  spirit ("mergeable with upstream").
- **R3 — relax numbering parity for exec-slice bookkeeping symbols**:
  derive names deterministically from data already in scope. Bends (c)
  for traces/goldens (final verdicts likely unaffected); requires R1- or
  R2-style plumbing anyway to get the in-scope data — so R3 alone does
  not close the gap.

Also required regardless of choice: DAEMON repair (Phase 1, promoted) and
mini_pipeline restructuring (port-local, unprotected). The requirement
set is NOT unsatisfiable on current evidence — but it requires choosing
R1 or R2, and that choice is the user's.

## 12. §11 resolution direction (discussion, 2026-08-18): R1 + id-insensitive differential

Measurement collapsed the R1 cost: the exec-slice fresh closure is FIVE
defs (step_ctx, core_action_step + 3 transitive callers in Core_run /
Core_reduction / Driver). And the user's observation — make the
differential id-insensitive — removes R1's one brittle invariant:

- Verdict-level differential is already id-insensitive (symbol numbers
  never flow into values). Trace/golden comparison gets a first-occurrence
  alpha-canonicalization normalizer (both sides; also thread ids). This
  forgives sequence offsets without masking structural divergence.
- The remaining requirement is within-Lean uniqueness only (exec-phase
  numbers must not collide with translation-phase numbers —
  symbolEquality discriminates on n): one seed line at the drive seam
  (threaded counter starts at the scaffold counter's value), locally
  auditable, and eventually provable (counter monotonicity lemma over the
  threaded state).
- R2 (model-level threading) is retired as the near-term plan but remains
  the principled endgame if upstream cerberus wants explicit threading;
  R1 does not foreclose it (the .lem stays pristine).

Mechanism for arc 2: 'declare {lean} state val' — deliberately
restricted (first-order, non-mutual, fail-closed on everything exotic),
threading (counter →) and (× counter) through the five-def chain,
terminating at the hand-written driver-state seam. AWAITING USER RULING.

## 13. THE NEEDLE-THREADING PLAN (arc 2 effects, derisked — 2026-08-18)

Structural evidence gathered after §12 kills R1 and shrinks R2 below what
either option assumed:

- **R1 is structurally dead**: the three fresh sites sit inside E-monad
  bind continuations (core_run.lem:585 under `E.fresh_action_id >>= fun
  load_aid -> …`; core_reduction.lem:1251,1294 under
  `E.fresh_excluded_id >>= …`). Def-level first-order state threading
  cannot reach them; only monad-aware lifting could — the genuinely hard
  transform. The §12 five-def closure was def-granular and misleading.
  The 'declare {lean} state val' feature is CANCELLED: not needed.
- **The model already owns the idiom**: core_run_state threads
  tid_supply / aid_supply / excluded_supply, with
  `fresh_action_id' = State.modify (bump)` (core_run.lem:108-113). The
  three `Symbol.fresh ()` calls are anomalies one line away from the
  house pattern.

**The patch (R2-micro)** — smaller than either §11 option:
1. `core_run_aux.lem`: add `sym_supply : nat` to core_run_state;
   `initial_core_run_state` gains a seed parameter for it.
2. `core_run.lem`: add `fresh_symbol'` mirroring `fresh_action_id'`
   (build `Symbol (digest()) n SD_None` from the supply) + `E.fresh_symbol`
   via `SEU.runS`; mirror in core_reduction's E.
3. Three call sites: `let sym = Symbol.fresh () in` becomes
   `E.fresh_symbol >>= fun sym ->` — the idiom already on adjacent lines.
4. Seeding: OCaml init passes one `Cerb_fresh.int ()` read (behavior ≈
   today: numbers continue after translation); Lean's hand-written driver
   seam passes the scaffold counter (uniqueness vs translation-phase
   numbers by construction). Trace-level numbering drift is covered by
   the id-insensitive differential (§12).

**Stages, each independently green and revertible:**
- **S0 — mechanize the census that failed**: `scripts/check_exec_purity.sh`
  in the gate — whitespace-robust greps asserting no runEffectful /
  `fresh ()` / unsafe reads in generated exec-slice modules. Starts in
  REPORTING mode (documents the 3 known sites); flips to ENFORCING at S2.
  This is the anti-recurrence fix for the §10 census failure.
- **S1 — the .lem patch**, validated OCaml-first: full OCaml build +
  existing suites. HONEST LIMIT: OCaml run-phase behavior has no
  end-to-end differential until Phase 2; mitigations are the patch's
  shape-preservation (supply idiom), S5's targeted audit, and the S0
  script. Single commit; revert = git revert, no mechanism coupling.
- **S2 — Lean regen falls out for free** (ordinary state-monad lem code —
  no lem backend change). S0 script flips to enforcing; proof test gains
  a fresh_symbol' distinctness/sequence lemma — now PROVABLE (threaded).
- **S3 — seed wiring** both sides + uniqueness invariant recorded +
  monotonicity lemma stub over the threaded supply.
- **S4 — id-canonicalizer** utility (first-occurrence renumbering of
  symbol/thread ids) with its own unit test; wired into trace/golden
  diffs when Phase 2 produces them.
- **S5 — focused 1-agent audit of the .lem diff** (semantic preservation
  vs OCaml), then the standard merge dance.

Also in arc 2, unchanged: DAEMON repair (independent workstream) and
mini_pipeline restructure (port-local). Both out of this needle.

Net derisk vs the §12 plan: the delicate compiler transform is
ELIMINATED rather than restricted; the .lem diff is ~15 lines in
established house style with an upstreamable story ("thread symbol
freshness like every other supply; remove a hidden global"); the
failure mode that caused §10 (unverifiable census) becomes a gate check.

## 14. S5 DAEMON repair — investigation + options (checkpoint packet)

Root cause localized: `LemLib.failwith`'s REFERENCE body is `DAEMON`
(`def failwith {α} (_msg) : α := DAEMON`), so every def with an error
branch transitively depends on the False-implying axiom — that is why the
exemplar theorems are tainted. Fallback-instance surface: 55
`default := DAEMON` Inhabited instances across generated code (Cn 20,
Core 14, AilSyntax 5, Nondeterminism 4, Core_aux 2, singles); the exec
slice touches ~7.

- **A — de-axiomatize failwith** (small): `failwith [Inhabited α] :=
  default`. Call sites unchanged (implicit instance); every failwith at a
  really-Inhabited type (all Option-returning defs, incl.
  core_object_type_of_ctype) becomes DAEMON-free immediately; gaps
  surface as compile errors (fail-closed) and resolve via the fallback
  instances where they exist.
- **B' — make DAEMON consistent** (small): bound it —
  `DAEMON {α} [Nonempty α] : α` (an axiom with models: choice), keep the
  unsafe implemented_by for execution. Fallback instances then need
  `Nonempty T`: backend emits `deriving Nonempty` on generated inductives
  (Lean derives it even for recursive/parametric types — no computation
  needed). Axiom set becomes CONSISTENT everywhere; #print axioms shows
  [DAEMON] only where genuinely stuck, and DAEMON no longer implies False.
- **C — kill the fallbacks** (larger, later): real derived Inhabited in
  the backend + hand instances for stragglers (CerbInhabitedInstances
  exists for this); delete DAEMON entirely. Cleanup, not required for
  "theorems certify".

RECOMMENDATION: A + B' in this arc (both small; merge-bar condition
"proof-test theorems DAEMON-clean" is met by A alone for the current
six theorems, with B' making any residual taint harmless); C deferred.
AWAITING S5 RULING.

## 15. S5 REVISED after design archaeology (2026-08-18) — §14's A+B' is withdrawn

A history agent reconstructed the Apr-2026 inhabitation churn (six
approaches in ~48h; full narrative with shas in its report; primary
sources: lem-lean doc/notes/2026-04-09_inhabited_design.md and commits
9e4f4eb→8648411). Decisive findings against §14:

- **A re-enters the abandoned mechanism.** [Inhabited a] constraint
  propagation through generated signatures was built and deliberately
  deleted (aaf7a64), and "does not require [Inhabited a] typeclass
  constraints" is a WRITTEN requirement of the converged design
  (2026-04-09 note line 8). Concrete first casualty under A:
  Nondeterminism.msum/pick — polymorphic failwith at ndM types with no
  constraints; closing their compile errors means re-implementing the
  deleted machinery.
- **B''s "consistent everywhere" is unmet as scoped**: six hand-written
  UNCONDITIONAL axioms in CerbInhabitedInstances.lean:42-76
  (exceptM/errorM/t0/nd_status/nd_action/ndM _default_safe) are
  False-implying for empty parameters and were missed by §14's census —
  the same census failure-class as §10, again.
- **§14's deriving-Nonempty claim was unevidenced**: untested on function
  fields, generated mutual blocks, and Type-1 indexed blocks.
- **A's ':= default' body is proof-theoretically WORSE than DAEMON**:
  error branches become provably equal to legitimate defaults (cf. the
  808cb3e1b defaults-leak lesson); DAEMON's opacity was accidentally a
  claim-strength feature.
- Also: lean_frontend/CLAUDE.md references lembugs/ which has never
  existed on any branch (doc rot, fix in passing); the 2026-04-09 note
  and backend manual still describe the pre-8648411 noncomputable design
  (stale, fix in passing).

**REVISED S5 design ("site-typed failwith split"):**
1. New `opaque failwithI {α} [Inhabited α] (msg : String) : α` in LemLib
   with `@[implemented_by]` panic. Opaque + bounded ⇒ NO axiom,
   consistent, computable at runtime, and UNPROVABLE-equal to anything
   (stronger claim hygiene than both DAEMON and `:= default`).
2. The lem backend emits `failwithI` at call sites whose type is
   SYNTACTICALLY CONCRETE (the overwhelming majority, incl. every
   exec-slice site) and keeps legacy `failwith` (DAEMON) at
   type-variable-typed sites (msum/pick class) — zero constraint
   propagation, zero signature changes: the Apr-9 requirement holds.
3. Gate: `#print axioms` check on the proof-test theorems added to the
   unit gate (DAEMON-clean cones = the merge-bar condition), rather than
   claiming global consistency.
4. The six hand-written _default_safe axioms: repaired in the same slice
   (opaque + appropriate bounds at their monadic types) — they are ours.
5. deriving Nonempty: NOT USED — the untested claim is dodged entirely.
   Global DAEMON elimination stays C-tier cleanup (future arc).

AWAITING S5 RULING on the revised design.

## 16. S5 derisk frame (the eye-of-the-needle answer, 2026-08-18)

How we know the failwith split cannot repeat the April blow-ups — each
recorded killer mapped to a STRUCTURAL absence, not an assurance:
init-panic (da293cd) → failwithI is opaque, nothing init-evaluates;
constraint propagation (aaf7a64) → classification is syntactic and total
(failwithI ONLY at sites with zero free type variables; `a × Nat` counts
as variable), so no signature can change by construction; noncomputable
cascade (e8dadf7) + partial-def killer (8648411) → opaque+implemented_by
is computable and instances are untouched; defaults-leak (808cb3e1b) →
opaque has no equations: strictly FEWER provable facts than today,
byte-identical runtime.

Residual named risk: a GROUND-typed failwith site whose type has no
Inhabited instance at all (skip_instances class) → per-site Lean compile
error, remedied by classifying that site back to legacy. Bounded,
enumerable, fail-closed.

Sequencing: (S5a, DONE) axiom-cone tripwire `check_theorem_axioms.sh` in
the unit gate, pinning the current cones (EXPECT=daemon; flip to clean is
a deliberate commit) — bonus evidence: fresh_symbol' is ALREADY
zero-axiom. (S5b) probes in lem's comprehensive suite covering every
classification edge (ground / tyvar / ground-in-partial-def /
ground-in-mutual / msum-shaped polymorphic) BEFORE touching cerberus.
(S5c) backend emission + LemLib failwithI; regen; mechanized
classification census (counts recorded, no hand greps); flip the gate to
clean. (S5d) the six hand axioms, each with its own bound or an honest
documented exclusion. Rollback at every stage: one commit per repo.

## 17. S5c LANDED (2026-08-18) — theorem cones DAEMON-clean

Mechanized census after the change: **232 failure sites → failwithI**
(ground-typed, axiom-free), **50 legacy** (type-variable class, per the
classification rule). The one residual-risk firing was `Inhabited
(Int ⊕ integer_value_base)` — Lean core lacks Sum instances; added to
LemLib (left-biased + low-priority right). fromJust cleaned via the new
general `declare {lean} ground_rep` (fromJustI: real success equation,
opaque failure leaf — the lookup theorem still proves by rfl).

Axiom cones (gate-enforced, default EXPECT=clean):
- core_object_type_of_ctype: NO axioms
- fresh_symbol': NO axioms
- zeros_aux, get_membersDefs: propext/Classical.choice/Quot.sound only
  (the standard consistent trio)

Gates: unit 3/3 (proof test green through fromJustI), parse ALL, core
104/105 baseline, purity CLEAN enforcing, axiom gate OK at clean.
Placement lesson re-learned twice: declares FOLLOW their binding.
Remaining in S5: S5d — the six hand-written _default_safe axioms in
CerbInhabitedInstances.lean.

## 18. S6 LANDED — the with_tagDefs divergence closed (2026-08-18)

Mechanism: 'declare {lean} reader_seed val f' (lem) — a def whose FIRST
argument is the injection value for reader-lifted callees in its body
(lexical seeding, the static complement to the by-design-unsupported
dynamic rebinding). mini_pipeline restructured target-neutrally:
run_const_expr_driver tds dr_st BUILDS the driver action (driver2 binds
its tagDefs source at construction — the audit's key mechanism insight)
and runs it under with_tagDefs tds, so hand-written memory reads (the
scaffold global) and generated reads (the seed) BOTH equal tds: the
split-read divergence is closed by construction. Verified in emission:
'(driver2 tds)'.

Cascade bonus: the desugar chain's ONLY tagDefs consumer was this
driver, so Cabs_to_ail/evalConstantExpressionAux/desugar dropped out of
the lifted set entirely — Main's desugar seed (and its §7a staleness
argument) is DELETED, not defended. Exactly one reader entry seed
remains (drive, post-registration — unconditionally correct) plus the
lexical seed with the translated definitions.

Phase-2 obligation retained: an end-to-end test of the repro class
(int a[sizeof(struct S)]) when the desugar pipeline completes.
Gates: 3/3 unit, purity CLEAN, axiom gate OK, parse ALL, core baseline.
