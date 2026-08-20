# Arc 8 charter: DAEMON elimination ("the consistent boundary")

Date: 2026-08-20. Mode: long-cycle autonomous under the orchestrator/
worker doctrine. BLESSED by operator via launch, 2026-08-20 ("Go ahead,
launch it"). Fully offline. Branch
pair: `arc/daemon-elim` in BOTH repos (this is a lem-heavy arc — the
full two-repo pin dance applies at every lem change and at close).

## Objective

Delete `axiom DAEMON : ∀ {α : Type}, α` (LemLib.lean:25) — the
kernel-verified INCONSISTENT axiom (arc-7 audit-1 F1) — from LemLib and
from every generated cone, so that **T1–T4 become unconditional kernel
certificates** with cones exactly `[propext, runEffectful,
Classical.choice, Quot.sound]`, and no future generated code can ever
reintroduce an axiom-valued inhabitant. Work order:
`lembugs/2026-08-20_daemon-inconsistent-axiom.md`. This executes the
TOP C-tier lem item and the first TEMPORAL boundary-list mover.

## Authorization context

[USER 2026-08-20] The operator authorized revisiting the April-2026
"no [Inhabited a] constraint propagation" ruling after the archaeology
(`notes/2026-08-20_april-inhabited-archaeology.md`, spot-verified).
Key findings that gate this arc's design:
- What April tried (constraints on generated INSTANCE HEADERS, in an
  all-partial-def world) is NOT what this arc does (failwithI + selective
  signature threading + real derived instances). Signature threading was
  never tried.
- April died on FIRST CONTACT with cerberus sources after 4 weeks of
  lem-suite green (`865d1f9`, 2026-04-03). **Standing rule for this arc:
  lem-suite green is NEVER evidence — every probe and every validation
  step is cerberus-scale.**
- The surviving design requirement "does not require [Inhabited a]
  typeclass constraints" (lem-lean `doc/notes/2026-04-09_inhabited_design.md`
  line 8) is REVOKED by this authorization; S1 updates that doc with the
  revocation note and its provenance.

## Durability requirements (design constraints, not aspirations)

[USER 2026-08-20] "If we solve this now, does it solve it for the rest
of the project?" — the arc must make the answer YES for the soundness
class:
1. **Mechanism, not patch.** The backend derivation + threading must be
   a general language-level pass covering future .lem code (incl. the
   318 remaining partial defs' demand shape and future concurrency/cmm
   modules), not a fix for today's ~73 failwith sites. Negative probes
   in tests/comprehensive must exercise shapes NOT present in today's
   cerberus corpus.
2. **Fail-closed, no opaque fallback — the April trap.** April's
   retreat was `sorry`-as-fallback, which is how DAEMON was born. This
   arc bans every opaque inhabitant: underivable Inhabited is a
   GENERATION-TIME ERROR naming the type; the user-facing escape
   hatches are `skip_instances` + hand target_rep instances. No sorry,
   no axiom, no panic-backed stub, ever.
3. **Permanent absence gate.** The in-build audit's DAEMON census flips
   to an ABSENCE assertion (LemLib + full generated tree + relsem);
   `check_theorem_axioms.sh` treats any non-allowlisted axiom in any
   probed cone as fatal (it already does — the allowlist shrinks).
   Reintroduction = build failure forever after.

## Slices

**S0 — the cerberus-scale probe (GO/NO-GO GATE; ~1 session).** The
archaeology's designed probe, run BEFORE any backend code: in a
worktree, hand-edit `generated/` — (a) in-module ndM Inhabited instance
+ failwithI for `msum`/`pick`; (b) `[Inhabited a]` binders on the 3
bare-tyvar stub sites; (c) the partial-def leg: delete DAEMON fallback
instances under 2–3 polymorphic partial defs in NON-totalized modules
and supply real instances. One capped `lake build` per leg — the
compiler enumerates the exact transitive demand set that defeated
April. Output: demand census (which defs need binders; which types need
derived instances; whether demand escapes into the partial-def sea
beyond what real instances cover), instance-method/function-field site
census (the one-level-protection gotcha), and a lem-side design note in
lem-lean `doc/notes/`. GO/NO-GO decision logged with the census as
evidence. NO-GO tripwire: unbounded demand growth → emergency exit with
the census as the record; the DAEMON qualifier stands and the lembugs
entry gains the negative result.

**S1 — backend: derived real Inhabited instances.** lem's Lean backend
derives REAL instances for generated types: nullary constructor when
available; else recursively through the first constructor whose fields
are all inhabitable; `[Inhabited a]` on instance headers only where the
derivation actually consumes the tyvar. April's class-2 failure
(downstream `deriving BEq/Ord` vs constrained bases) gets a dedicated
comprehensive test mirroring `test_parameterized_instances.lem`'s
shapes — now expected to PASS with real instances. Fail-closed per
durability req 2. Probe-first in tests/comprehensive AND a full
cerberus regeneration + capped build in the SAME slice (April lesson —
no lem-only green checkpoints). Hand-written `CerbCoreInstances.lean`
instances retire where the backend now derives them (hand file shrinks;
anything kept documents why).

**S2 — backend: failwith → failwithI + selective threading.** failwith
emission becomes failwithI (`[Inhabited α]`-carrying); a selective
signature pass — reader-lift pre-pass as the template — threads
`[Inhabited a]` binders through exactly the enclosing defs where a
failwith/inhabitant demand sits at a bare-tyvar position (S0's census
is the worklist; instance-implicit binders need no call-site edits).
Ground sites keep the existing ground classification. Mutual/fuel/
reader interaction covered by comprehensive tests including negative
probes. Cerberus-scale validation in-slice, as S1.

**S3 — deletion + regeneration + re-pinning.** Delete DAEMON + DAEMON1
from LemLib; full regeneration; theorem cones re-pinned in `Audit.lean`
to exactly `[propext, runEffectful, Classical.choice, Quot.sound]`;
absence gate lands (durability req 3); hand-axiom census stays exactly
2 (with_tagDefs, forceIO). BEHAVIOR NEUTRALITY: failwithI panics
identically to failwith and derived defaults are only demanded at
unreachable/panic positions — the FULL differential surface must show
ZERO movement (minimal, coverage, ci, debug, uri 16/16, chvalid slice,
multi_tu, libc_exec, verify 29/29). Any movement = a reachable default
= a soundness finding, full stop.

**S4 — close-out.** Results doc; decision log (provenance-tagged);
docs de-stale — the honesty-payoff edit: CLAUDE.md + ROADMAP + results
docs replace every "modulo the DAEMON meta-assumption" qualifier with
the unconditional statement; lembugs entry closed RESOLVED; boundary
list updated (first temporal mover executed). 2-agent adversarial audit,
mandatory scopes: (a) instance-derivation soundness — no derived
default observable in any differential; (b) threading completeness vs
the S0 census; (c) absence-gate fail-closure (negative-tested: plant an
axiom, watch the build die); (d) April-parallel check — did anything
regress to an opaque fallback anywhere. Fix-or-record. Full pin dance:
lem-lean merges first (ff-only), re-pin `deps/lem-pinned` + Lake
manifest to the MERGED lem commit, `make rebuild-lem`, re-run the full
gate, then cerberus ff-only. Merge checklist. **Stop. Do not merge.**

**STRETCH (only if S0–S3 land with slack; park-clause absolute): T5**
(bounded loop) from the arc-7 pricing, stated over the now-clean cones.
T5 must not eat the arc; parking again is a legal outcome.

## Success conditions (machine-checkable)

1. `DAEMON`/`DAEMON1` absent from LemLib and the entire generated tree
   (grep + in-build absence gate, negative-tested); no new axiom, sorry,
   or opaque fallback anywhere (census: hand axioms exactly 2).
2. T1–T4 cones kernel-walked to exactly `[propext, runEffectful,
   Classical.choice, Quot.sound]`; Audit.lean pins updated; statement
   gate unchanged-green.
3. Full validation gate green at every commit, differential surface at
   ZERO movement (any movement = soundness finding, replan trigger —
   never a baseline update).
4. Backend mechanism is general + fail-closed: comprehensive tests
   include shapes beyond today's corpus + negative probes for the
   error path; underivable-type error message names the type and the
   escape hatches.
5. lem-lean `make` + tests/comprehensive green — AND every lem
   checkpoint paired with cerberus-scale regeneration + capped build
   (no lem-only green claims; audit-checked).
6. Records complete; April design-doc requirement 8 revoked with
   provenance; pins aligned (branch heads = opam pin = Lake pin at
   close); merge checklist ready; mainlines untouched.

## Risks / pre-declared calls

- **Demand-set explosion** (the April killer): S0 exists precisely to
  price this before any backend code; NO-GO is a legal, recorded
  outcome.
- **Partial-def sea** (318 defs in non-totalized modules): S0 leg (c)
  prices it; if real instances cover the demand, fine; if a subset
  resists, the orchestrator may scope a targeted totalization of the
  resisting modules (arc-3 machinery, priced) or emergency-exit — never
  an opaque fallback.
- **Elaboration cost** of instance search at cerberus scale: capped
  builds throughout; build-time regression is a recorded finding; any
  heartbeat bump follows the doctrine (register entry + expected
  remover; by definition a defect).
- **Deriving-chain regressions** (April class 2): dedicated tests in
  S1; expr-family sorried-BEq C-tier item is adjacent — worker parks,
  never improvises, if they collide.
- **Behavior neutrality** is load-bearing for the differential
  baselines: the S3 zero-movement bar is absolute.

## Autonomy protocol

As arcs 4–7: workers commit (green gates only, one coherent commit per
slice, verbatim-quoted outputs), orchestrator scopes exactly and
verifies independently at every boundary (worker-claimed green never
accepted), decision log throughout with [USER]/[AGENT] provenance,
merge lives with the operator (unconditional pre-merge audit ask).
Backend passes are delicate — Fable-grade workers for S1/S2; mechanical
regeneration/doc batches may use Opus. Worktrees for both repos;
primaries stay parked. EMERGENCY EXIT always permitted, nature
declared. Tripwires: S0 NO-GO; any gate keepable-green only by
weakening; any differential movement traced to a reachable default;
anything requiring machine-global state.
