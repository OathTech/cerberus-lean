# The Design Catechism

STATUS: DRAFT for operator blessing. Once blessed, this is a NORMATIVE
front document: every charter, worker brief, and review cites it as
binding; conflicts with it are findings. Sources: operator rulings
2026-08-22 → 2026-08-27, quoted verbatim where load-bearing.

**READ THIS IF YOU ARE A WORKING AGENT.** This document is addressed
to you, mid-task. It says what this project is, what is valuable, and
what is forbidden. The operative rule [USER 2026-08-27]: **if you are
doing something out of keeping with this, STOP.** Do not finish the
misconceived artifact because it is nearly done, because it is green,
or because your brief seemed to ask for it — a brief cannot authorize
what this document forbids. Stop, write down precisely what you were
doing and why it conflicts, and report (the park record IS the stop;
never push past it). Landing something this document forbids is worse
than landing nothing.

---

## I. What is the task?

To build a **verification framework for C in the BRiCk / RefinedC /
Iris lineage** — a program logic with aggressive, principled
automation — capable of verifying vast real C code. The north star
[USER 2026-08-22]: "our purpose in all this work is to build a
verification tool we can use to verify substantial parts of the Linux
stack… boring specs… the most aggressive proof automation that has
ever been implemented in a theorem prover. We want to verify vast and
unprecedented things." The near target is libxml2; the point targets
are kernel-adjacent (pKVM). [USER 2026-08-27]: "Our aim here is to
BUILD A VERIFICATION FRAMEWORK SIMILAR TO BRICK OR REFINEDC. That's
the aim."

We are **doing formal verification**. We are not building an
interpreter harness, a test oracle, or a benchmark runner — those
exist, serve the model-validation ledger (§V), and are not the task.

**The intended design** [USER 2026-08-27]:

```
executable Cerberus semantics   (fuel opsem, lem-generated — THE TCB;
        ⇧ adequacy               executable + oracle-differential)
relational semantics            (per-step relation / language instance)
        ⇧
Iris reasoning                  (heap RA, WP, contracts, per-construct
        ⇩ proves                 rules, automation — the RefinedC/BRiCk
target program                   analogue; the layer under construction)
```

The load-bearing property of the layering: **statements anchor at the
bottom layer; proofs travel down through adequacy.** A target
theorem's text mentions only the executable semantics (statement-TCB
gate); Iris appears in no statement and no cone (cones exactly the
classical trio). Trust = layer 1 alone; layers 2–3 may be engineered
aggressively. The differential corpus validates layer 1 and nothing
else — the two ledgers separate exactly at the adequacy line. The
automation sits INSIDE the Iris layer on the escalation ladder (§IV.4),
never as a new layer with new trust.

## II. What is a theorem worth proving?

**The canonical property** [USER 2026-08-27]:

```
harness_f(init, args) {
  set_up_memory(init)                 // precondition
  return = f(args)
  final = check_memory(init, return)  // postcondition readback
  return final
}

∀ init, args :
  f_precondition(init, args)
  ∧ cerb_semantics(harness_f, init, args) ~~> result
  ⟹ result = some(final) ∧ f_postcondition(init, args, final)
```

Quantified, all-input properties are the **minimum** specification
class we care about — not the ceiling, the floor. A theorem's value
is measured by the family of executions it constrains. A theorem that
constrains one execution has the value of one interpreter run:
approximately zero. [USER]: "From this perspective, we are NOT
INTERESTED AT ALL IN CONCRETE EXECUTION AT SPECIFIC VALUES. If we
wanted that, we would just run the interpreter. Who cares?"

**Test of worth**: state the theorem in one sentence beginning "for
all…". If the sentence has no ∀ over program-relevant data — or the ∀
ranges over a finite pinned sample — it is not a verification result.

## III. What is forbidden?

These are forbidden **as proof strategies** — categorically, not as
matters of degree:

1. **Concrete-input theorems.** Proof-layer artifacts that establish
   facts about executions at specific values. Includes: theorems with
   literal arguments; finite-sample "families"; kernel-checked
   replays of runs. The emblem of the failure: proving
   `clamp0(-3) = 0` when the specification is `∀x, clamp0(x) =
   max(x,0)`.
2. **Enumeration.** Any strategy whose cost is proportional to the
   number of values, cases, or rounds enumerated rather than to
   program structure. Unrolling-as-verification; per-instance kernel
   volume; sample sets pretending to be quantifiers. Corollary
   [USER 2026-08-27]: statement bounds must be ANTI-BRUTE-FORCE —
   every precondition constant takes the largest value its type
   admits (derive tighter bounds from type limits only where
   overflow-safety forces it, documented). "We SHOULD NOT pick
   values that could be brute forced" — if enumerating the domain is
   even conceivable, the bound is too small, because a small bound
   silently re-admits this forbidden item through the precondition.
3. **Grind**, in all three species [USER 2026-08-24/25]: bulk kernel
   checks in place of structure; brute-force elaboration standoffs;
   and proof-grind — "an agent takes a giant term and then proves it
   grindingly tactic by tactic, where an automation step would knock
   it out immediately." The long manual script conceals the real
   deliverable: the missing automation.
4. **Non-kernel proof methods** (native_decide, bv_decide, any
   ofReduce* cone) — gate-enforced, always fatal.
5. **Budget bumps as fixes.** maxHeartbeats/maxRecDepth raises are by
   definition defects. When the substrate bends, the answer is
   **better abstractions, not grind** [USER 2026-08-27].
6. **Tricks without insight** [USER 2026-08-24]: representation hacks
   that steer behavior we neither control nor model; cleverness that
   does not transfer. "A good trick states in one sentence what
   abstraction it exploits and why the next example gets it for
   free."
7. **Vocabulary costumes.** Program-logic words over machinery that
   does not do program-logic work. An "invariant" that restates what
   the run reached is not an invariant — an invariant CONSTRAINS a
   family of states it has not seen. (The circularity finding,
   2026-08-27, is this rule's case study.)
8. **Fail-open behavior; silent fallbacks; trust gaps.** If two
   artifacts must agree, that agreement is a theorem. Failures are
   loud. Gates are fail-closed and plant-tested.

## IV. What is valuable?

1. **Automation that amortizes.** Proved-once-fires-everywhere:
   per-construct rules, once-proved composition theorems, registered
   law tables, symbolic execution with case-split. Value test: does
   the NEXT program get it for free? Proof cost must track program
   STRUCTURE (loops, calls, branches), never program size, input
   range, or trip count.
2. **Legible reasoning.** For simple programs, the machine's argument
   and the human's Hoare-style argument coincide: spec, invariants at
   loop heads, contracts at calls, automation between. The standard
   is the grumpy professor reading cold. Calibration [USER
   2026-08-27]: "we don't need to make every example just verify_fn;
   auto — that's probably impossible for more complex functions. But
   it's great for simple ones! I'd expect some working tactics,
   similar to brick_wp in complex cases." Judge structural
   coincidence and legibility, never literal step-count.
3. **Canon first, donors mirrored.** The literature's tools before
   novelty (abstraction, invariants, symbolic execution, framing,
   simulation); Iris is the first port of call; match BRiCk/RefinedC
   where sensible — "not gratuitously be different." Novel mechanisms
   name their lineage or justify novelty as post-exhaustion.
4. **The escalation ladder, always open.** Powerful automation on
   top; working tactics beneath; every automation step grounded in a
   named, individually applicable rule. No closed black-box path:
   anything auto does must be reachable by hand.
5. **A pristine trust surface.** Statements boring and
   fuel-opsem-only; every theorem's cone exactly {propext,
   Classical.choice, Quot.sound}; proof MACHINERY may be engineered
   aggressively so long as every step lands as an ordinary
   kernel-certified obligation. "Clever tricks for kernel-certified
   steps; no insane hacks for specifications."
6. **Honest measurement.** Parks with prices; walls converted to
   automation and recorded; claims falsifiable against pre-registered
   artifacts (the census pattern). A green build is not evidence;
   the stated measurement is.

## V. What is concrete execution FOR?

One thing only: **model validation**. The differential corpus, oracle
comparisons, plant tests, and executable harness runs discharge the
"is the semantics faithful" leg of the trust story. This is a
separate ledger from verification: its artifacts are TESTS, labeled
as tests, never presented as theorems, never in any theorem's cone,
and never a substitute for a quantified proof. A test dressed as a
theorem is a record-integrity finding.

## VI. The self-check — ask these BEFORE building, and AGAIN mid-work

Run these questions at the start of any slice and at every natural
pause. A "no" or "I'm not sure" on any of them is a STOP-AND-REPORT
event, not a note for later.

1. What ∀-statement does this serve, and over what family?
2. Does its cost amortize — what does the next program pay?
3. What is its name in the literature? What do the donors do here?
4. Would the professor recognize the reasoning, or is it term
   wrangling in costume?
5. Is any part of it enumeration, grind, or a concrete-input artifact
   wearing quantified vocabulary?
6. When it fails, does it fail loudly, and is the failure a design
   finding or an invitation to push harder? (Park the finding; never
   push past your own park.)
7. Is the trust surface unchanged — and if not, is the change a
   declared, temporal, moving boundary entry?

## VII. The standing enforcement — without gate grind

[USER 2026-08-27]: "we don't want to end up in 'gate grind' —
mechanical gates can just pile up." Enforcement is layered, cheapest
first:

- **This document**: cited by every charter and worker brief; an
  artifact that cannot answer §VI is a finding by default. Discipline
  points are enforced by NOTES in the artifact and by
  STRUCTURALLY-FORCING design (an example that admits no dishonest
  pass beats a gate that polices one).
- **The target corpus** (restart step 4): FROZEN under user-level
  sign-off; it defines success; infrastructure is judged against it.
- **Mechanical gates**: reserved for load-bearing TRUST properties —
  cone pins, statement TCB, non-kernel-method ban, fork-drift,
  lem-sync — plus the one new gate the forbidden class earned: the
  concrete-input statement check. Existing gates stand; new gates
  need the trust-property justification, not a discipline itch.
