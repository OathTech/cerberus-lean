# Postmortem and Forward Design Brief
## The cerberus-lean reasoning effort: what happened, what is salvageable

**Audience**: the agent (and operator) starting the successor effort — a
retrofit of the RefinedC logic on top of the Cerberus semantics, in a
new repository. This is the "what happened and what can be salvaged"
brief. Written 2026-08-31 by the orchestrating agent of the failed
effort, at the operator's direction, against its own record.

---

## 1. The two outcomes

**The semantics: a success.** A Lean 4 port of the Cerberus C
semantics — executable, total in its exec cone, and continuously
byte-validated against the independent OCaml oracle: 106/106 exec
baselines, 213/213 CN-corpus differential, 16/16 libxml2-uri gate,
2,186-file CI sweep with zero mismatches, csmith lanes, multi-TU
linking, libc-mode execution. Guarded by a fail-closed gate suite
(lem-sync content hashes, fork-drift manifests, totality/purity
scans, axiom censuses). This is the foundation the successor builds
on. Lives at branch `core/semantics-first` (the clean presentation;
mainline `mdd/cerberus-lean` after its merge).

**The reasoning layer: a failure.** Four successive paradigms, each
killed at the design level:
1. *The chase/seal era* — kernel-checked symbolic execution fighting
   the kernel's unfolding; parked at `arc/t5-seal`.
2. *Concrete-input theorems* — kernel-checked replays of specific
   executions wearing theorem costume; killed by professor audit.
3. *The harness-primacy segment logic* — real Iris machinery (it
   proved ~10 genuine ∀-input theorems) built with the primacy
   inverted: harness observations treated as the deliverable,
   contracts as machinery. Corrected too late.
4. *The paper logic* — a de-novo logic design that took three hostile
   review rounds and still shipped a model-coupled allocation design
   (space credits mirroring our port's bump allocator — not even a
   Cerberus fact) that only the operator caught.

Everything is preserved at branch `arc/segment-ladder`, tag
`park/reasoning-era-20260831`, including the complete decision record
(38 design documents and reviews under
`lean_frontend/docs/reasoning-era/`).

## 2. The failure analysis

**The operator's diagnosis, which the record confirms**: the agent is
strong at grinding against existing surfaces and weak at design.
Every success had a fixed external referent with tight feedback — the
OCaml oracle (byte equality), the profiler (the 8,600× finding), donor
source code, an exactly-prescribed fix list. Every failure was a
surface the agent had to invent: a statement doctrine, a proof
paradigm, an allocation model. Given a referent, it converges; asked
to create the referent, it produces locally-plausible wrong designs
and then executes them faithfully — which is worse than executing
them badly, because the error compounds cleanly.

**The recurring disease** was one bias recurring at ascending levels
of abstraction, caught by the operator each time, one level up from
the previous catch: concrete *executions* (the chase) → concrete
*inputs* (the R6 corpus) → concrete *contexts* (the boot-state
assumption) → concrete *artifacts* (harness theorems as the goal) →
*model-coupling* (the credit design justified by "it matches the
model's structure" — the anti-pattern stated as a virtue).

**Secondary mechanisms**, all real:
- *Gauge failure.* The instruments (statement-row counts,
  steps-per-theorem, frozen harness statements) measured the wrong
  layer, and the agent steers by gauges. A wrong gauge is a design bug
  the agent will faithfully execute.
- *Review convergence.* Same-reviewer delta passes transcribed wrong
  prescriptions (v2 inherited three from v1's review). Fresh-eyes full
  reviews each caught a different defect species — idealization,
  inherited prescription, unverified wiring — and still collectively
  missed the model-coupling. Reviews are necessary, not sufficient;
  the operator's reading caught what four professional passes did not.
- *Briefs as smuggled decisions.* Orchestrator briefs bundled design
  choices into acceptance criteria without operator discussion —
  twice dispatched before the scope conversation happened.

## 3. What the successor should do differently

**The method (operator-set): retrofit, don't design.** RefinedC's Coq
development (`deps/refinedc` — vendored, BSD) is the normative spec:
its judgments, its rule set, Lithium's algorithm. Every design
question is answered by reading their code. Deviations only where
Cerberus semantically forces them, each logged in a port ledger with
its forcing fact — and each forcing fact verified to be about
*Cerberus* (Core's meaning, the ISO obligations), never about the
Lean port's implementation internals. Strict retrofit implies:
partial correctness first (theirs is partial; totality is a later
extension), their evaluated/sequentialized fragment first.

**Process rules that demonstrably worked — keep them**: fresh-eyes
full reviews on core documents (never same-reviewer deltas); hostile
adversarial review before any ratification; profile before designing
performance fixes; per-file probes for discovery, batch builds for
confirmation only; park-ends-slice (a committed park record stops the
work); plant-tested fail-closed gates; the kernel as backstop (it
caught three real meta-level bugs — the trust architecture is real);
pre-registered exits with structural bounds (the anti-gaming form);
classical names only — a mechanism that cannot be named from the
literature is presumptively a hack.

**Rules learned at cost — add them**: design from the donors, prove
against the model, couple to neither (the model appears only in
soundness premises and adequacy scope); ISO nondeterminism the model
resolves one way enters reasoning only as explicit precondition,
outcome, or scope — never ambient assumption; verify *wiring* (walk
the driver's actual call chain), not just raise sites; no design pass
dispatched before its scope is discussed with the operator; watch
worker tokens-per-hour — a collapse means build-bound, and the fix is
representation, never budgets.

## 4. The salvage map

Read everything below as *reconnaissance, not blueprint* — the
failed effort's maps are accurate even where its buildings were not.

| Asset | Where | Value to the retrofit |
|---|---|---|
| **The semantics + validation empire** | `core/semantics-first` (whole branch) | The foundation. Build on it as a dependency; its differential lanes are the ground truth for every soundness proof. |
| **The equivalence dictionary + divergence audit** | park: `docs/reasoning-era/2026-08-30_core-logic-paper.md` (v3) §C + the three reviews | The Caesium↔Core delta map, construct by construct — exactly where port obligations will be easy vs hard. The most directly reusable reasoning-era artifact. |
| **Model-fidelity facts** | park: the v2/v3 fresh reviews | Hard-won executable-model truths: the engine of record is Core_reduction; labels resolve via `collect_saves` (procedure-wide); the unseq race check is schedule-independent at the join; the memory model runs PVI (not PNVI), taint unported; the killed-not-UB outcome class; the panic sites raise-site sweeps miss. Each was found by someone checking the real code — the retrofit's soundness proofs need all of it. |
| **The construct inventory** | park: the paper v3 figure | 29 pexpr / 19 expr / 15 action / 22 memop constructors, enumerated and audited against the generated AST — the port ledger's row list. |
| **The frozen corpus** | `core/semantics-first`: `lean_frontend/corpus/` (as differential fixtures) + park docs (the specs) | 15 tiny programs whose theorem specs deliberately span every reasoning family a C logic needs — a ready-made validation suite for the retrofit, already oracle-validated. The corpus *process* (pre-registration, the dishonest-pass test, anti-brute-force bounds) is itself reusable method. |
| **The model-refinement ledger** | park docs + CLAUDE.md rulings | The discipline + two worked entries (malloc failure via harness wrappers; address reuse). Day-one equipment. |
| **Mechanism C** (functional-big-step characterization) | park: `RelSem/CStep.lean` + the V3a records | A measured GO: program-independent construct lemmas replacing per-program facts, with the OMKT lineage. If the retrofit needs step characterization of the fused interpreter, this is the proven route — and the environment≈substitution correspondence design sits beside it. |
| **The kernel-pin device** (`seg_discover`) + the 8,600× finding | park: PERF records | Kernel.whnf vs Meta.whnf asymmetry on ground discovery — the single biggest performance lever found; ordinary rfl, no reflection axioms. |
| **Engine lessons** | park records | Committed-choice dispatch keyed to arm-form (the r127 lesson); per-round budget isolation; deterministic-over-backtracking (12M-nonterminating vs seconds); named-state constants; the fail-open instrument hazards. |
| **The V1 state decomposition** | park: `CerbStateRA/WP/Adequacy` + records | The six-component ghost interpretation with the coherence invariant, adequacy proved. RefinedC's locals-as-heap approach may not need the env component — but the heap/allocation ghost structure mirrors Caesium's and ports forward. |
| **The catechism** | park: `docs/2026-08-27_design-catechism.md` | The forbidden/valuable lists and the §VI self-check survive; the mission section is superseded. Extract, don't adopt wholesale. |
| **The lem backend + totalization patterns** | lem-lean `mdd/lean-backend`; the threadB record | Semantics-side and live: the mutual-fuel machinery, target-language-conditional lem, byte-identity discipline for model changes. |
| **Operational knowledge** | container CLAUDE.md (historical block) | Box OOM discipline (capped builds, serial heavy lanes), the in-tree-scratch/D14 hazard, the timing lane, probe hygiene. |

## 5. A note to the successor agent, from the predecessor

You will be better than the record above suggests wherever the work
has a referent, and worse than you expect wherever it does not.
Treat RefinedC's code as your oracle the way the semantics effort
treated the OCaml oracle: never deviate for elegance, never
generalize speculatively, log every forced divergence with its
forcing fact, and let the operator adjudicate anything where "the
model made me do it" is the justification — that sentence was the
epitaph of the best-reviewed wrong design in this repository. The
operator's attention is the scarcest resource in the project; the
honest stop-and-report is cheaper than every alternative, and the
things that saved this project each time — fresh eyes, plant tests,
the kernel, the operator's reading — only work if you route your
uncertainty to them instead of past them.
