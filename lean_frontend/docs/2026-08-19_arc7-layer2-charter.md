# Arc 7 charter: Layer 2 + first adequacy ("the bridge")

Date: 2026-08-19. Mode: long-cycle autonomous under the orchestrator/
worker doctrine; provenance-tagged decisions; verbatim-transcript rule;
D14 proof-method ban in force. DRAFT until operator-blessed.

## Objective

Build the GoLean Layer-2/minimal-Layer-3 stack over the arc-1..6
substrate and land **the program's first novel theorem**: an end-to-end,
adequacy-discharged, kernel-checked statement about a real C program.

EXIT CRITERION (teeth): one theorem, about one tests/minimal C program
(candidate: a struct-carrying program, e.g. 025-struct-basic or the
sizeof-struct obligation test), of the shape "every outcome of the
totalized runner on the compiled Core of P is Specified(v)" — PROVED via
an Iris weakest-precondition derivation over the relational layer and
DISCHARGED by an adequacy theorem, such that: (a) the STATEMENT mentions
only the fuel opsem, the program, and pure specification values — no
Iris, no relational layer (golean statement-TCB discipline, mechanized);
(b) the kernel axiom cone of the final theorem = the classical trio +
declared-boundary axioms only (D14 gate + in-build audit).

## Verification-target slate (operator directives, 2026-08-19 —
## golean-proven practice: fix the slate before building the logic)

Three operator rulings shape every slate entry: (1) theorems are
**QUANTIFIED over all possible inputs** to the function — this is not
concrete evaluation; a closed program provable by running the
interpreter once validates nothing about the logic; (2) theorems are
**stated over the interpreter only** (the totalized runner on the
compiled Core) — Iris is the proof layer and never appears in a
statement; (3) fix the slate first.

The targets are therefore C FUNCTIONS verified under a symbolic-argument
harness: quantification enters by injecting universally-quantified
Core/memory values as the function's arguments at the Core call
boundary (this harness instrument is also the future per-function
libxml2 differential/verification vehicle). Statement template, for
function f, pure spec s, precondition P:

  ∀ args, P args → every outcome of run(compile(f), inject args)
                    is Specified (s args)   [in particular: no UB]

| # | target function (fixtures in tests/verify/) | theorem (∀ args) | rules forced |
|---|---|---|---|
| T1 | `int id(int x) { return x; }` | ∀ x : int-range, outcomes = {Specified(x)}, no UB | adequacy plumbing + symbolic argument injection + return — the smoke theorem, LANDS FIRST; trivial only in PROOF SIZE, already ∀-quantified |
| T2 | `int add(int a, int b) { return a + b; }` | ∀ a b WITH the no-signed-overflow precondition, outcomes = {Specified(a+b)} | pure-step, bind; the precondition is FORCED by the UB-freedom obligation (signed overflow is UB) — the slate's first real spec-discovery |
| T3 | `int roundtrip(int v) { int x = v; return x; }` | ∀ v, outcomes = {Specified(v)}, no UB | alloc, store, load points-to, frame |
| T4 | `struct S { int a; int b; };` member write/read of symbolic v | ∀ v, outcomes = {Specified(v)}, no UB | struct-layout points-to (member offsets) — THE EXIT-CRITERION THEOREM |
| T5 | `int sum(int n)` bounded loop | ∀ n in a stated range, outcomes = {Specified(closed-form n)}, no UB | loop invariant rule + fuel erasure |
| S | (stretch, arc-8 pricing only) one chvalid predicate | ∀ code point, agrees with the range tables | call into linked libxml2 code |

Bar: T1-T3 + T4 (exit criterion) proved; T5 proved-or-parked-with-
pricing. Each fixture ALSO gets a concrete-instance differential test
(sanity net under the theorem, never a substitute for it). The
symbolic-argument harness (Core-level call with quantified values,
memory state threaded) is S3/S4 infrastructure — its design must
respect parametricity (ExecModel-level, not driver-hardcoded).

## Inputs (all banked)

spike/relsem branch (ExecModel parametric interface; runNDT +
runNDT_sound + fuel-monotonicity PROVED; 10-rule Step; IrisCoupling
sketch TYPECHECKED against built iris-lean; Q1-Q4 resolutions incl. the
operator's totalize-don't-bridge ruling); iris-lean builds offline
(4.32.2, program_logic advanced); golean Audit.lean pattern (D14 arc-7
adoption item); model-parametricity principle; bespoke-logic stance
(minimal base, per-target rules); concurrency forward-design constraints
(don't foreclose: thread pool stays in Config, StateInterp is a slot,
adequacy quantifies behaviors).

## Slices

**S0 — the toolchain decision (before anything else).** Our repo is
Lean 4.29.0; iris-lean is 4.32.2; Layer 3 requires importing iris-lean
into our build. Options: (i) BUMP lean_frontend (and the LemLib dep
compilation) to 4.32.2 — the ROADMAP's long-flagged decision, due now;
(ii) pin iris-lean back to a 4.29-era release IF one exists with
program_logic adequate (check its release history); (iii) park Layer 3
(unacceptable — it guts the exit criterion; emergency-exit territory).
Method for (i): probe-bump in the arc worktree (lean-toolchain +
lakefile deps), full gate net — this is EXACTLY what six arcs of gates
exist for: fresh-int/CSE sensitivity (arc-0's original hazard),
effect-erasure armor, sync, purity/totality/axiom gates, and the ENTIRE
differential corpus (minimal/coverage/debug/ci/libc/uri/battery) as the
behavioral regression net. Toolchain bumps are arc-level decisions
(playbook): the [AGENT] decision is made ON THE GATE EVIDENCE and
logged with it; a red that cannot be fixed forward cheaply = fall back
to (ii), and if (ii) is inadequate = emergency exit for replan.
Compiler-behavior deltas found en route are register items.

**S1 — branch assembly.** First commit on the arc branch: the
operator-commissioned weak-memory survey doc + the .gitignore papers/
entry currently uncommitted on the primary (operator content; commit
message credits provenance; operator instruction 2026-08-19). Then merge
spike/relsem into the arc branch (its lakefile [[lean_lib]] line is the
known rebase point) — the spike becomes load-bearing code and its
RelSem lib joins the gates: adopt the golean in-build Audit.lean pattern
NOW (exact-axiom-set assertions for RelSem + proof modules,
build-failing) so everything after S1 grows under it.

**S2 — totalize CerbND (the operator's Q1 ruling, executed).** Replace
partial runND/runND1 with the fuel-totalized runner (transfer runNDT per
spike §C2): explicit exhaustion marker (NOT silent []), lemDefaultFuel
budget, --first equivalent preserved. Migration safety = the ENTIRE
standing corpus net green with zero movement (the arc-5/6 pattern);
prove in-repo: runner-vs-Step soundness (transfer runNDT_sound) and the
wrapper/defeq discipline. Extend check_exec_totality.sh's boundary to
CerbND.lean (arc-4 G3 item, partially discharged) — CerbMem stays
declared-boundary this arc (priced, not expanded). The declared
hand-written-axiom census stays 2.

**S3 — Layer 2 to exit-theorem strength (sequential fragment).** Extend
Step to the driver granularity the exit program needs (memory
load/store/create arms via the liftMem lens, call/return, the pure-eval
arm — coverage BY NEED per the bespoke stance, not completeness);
fuel-erasure lemmas for the touched fuel'd functions (wrapper-defeq
hooks); the ExecModel instance theorems connecting Step-reachability to
runner outcomes (soundness direction; completeness ONLY if the adequacy
proof demands it — decide on evidence, log). All under the in-build
audit; all statements through the ExecModel interface (parametricity:
Layer 3 consumes the interface, never the concrete driver types
directly).

**S4 — Layer 3 minimal.** Add iris-lean as a Lake dep (pinned rev;
mirrors updated at the next network window — record). FIRST STEP,
before proving anything (operator directive — the golean anti-pattern
was subagents hacking away instead of building the proof infra they
needed): INVENTORY what iris-lean already provides and REUSE it — the
ported program_logic's generic WP rules (bind, frame, mono, pure-step
machinery), gen_heap's pointsTo + alloc/update/load lemma stack, the
proof mode (Iris tactics) — the spike catalogued the INTERFACE; this
step catalogues the RULE LIBRARY, with a written reuse-vs-build call
per slate-needed rule. Then: instantiate the language (from the spike's
typechecked sketch); StateInterp over MemState as the SC instantiation
of the parameterized slot (document the slot per the concurrency
constraint); prove ONLY the slate-needed rules NOT already provided
(the bespoke stance + the slate are the scope fence; a rule wishlist
beyond the slate = park + register).
PROOF-FIGHT ESCALATION RULE (all S3-S5 workers, in every brief): if a
proof turns into case-bashing or exceeds a short honest attempt, STOP —
name the missing lemma/rule, check iris-lean for it, build it if
absent, then resume. Long boring hacking campaigns where a proof rule
was available are findings, not effort; the S5 audit checks for
hack-shaped proofs (long tactic scripts where a rule existed or should
have been extracted). Then THE ADEQUACY THEOREM: Iris
triple ⇒ ExecModel-level behavior statement. This is the arc's hard
center; if the driver-granularity coupling fights, the pre-approved
fallback is adequacy for a restricted Config class that still covers the
exit program (restriction documented, generalization priced for arc 8).

**S5 — the exit theorem + close-out.** Prove the exit-criterion theorem;
mechanize the statement-TCB check (golean Audit.lean §statement-gate
style: the headline theorem's statement must not mention Iris/RelSem
names — build-failing check, not convention). Results doc; decision log;
docs de-stale (incl. toolchain notes everywhere if bumped); 2-agent
adversarial audit (mandatory scopes: adequacy-proof soundness reading;
statement-TCB + axiom cones; toolchain-bump behavioral review incl.
differential re-verification; spike-merge integrity; citation/provenance
checks); fix-or-record; pin dance (lem untouched expected — else full
dance); merge checklist (spike/relsem merges WITH this arc). Stop. Do
not merge.

## Success conditions (machine-checkable)

1. The slate: T1-T3 + T4 (exit criterion) proved, kernel-checked; every
   slate theorem's statement is Iris/RelSem-free (mechanized check);
   axiom cones = classical trio + declared boundary (in-build audit +
   D14 gate). T1 (trivial no-UB) lands FIRST as the plumbing validator.
   T5 proved-or-parked-with-pricing.
2. CerbND totalized: totality gate extended over it; runner soundness
   theorem in-repo; census still 2; zero movement across ALL standing
   corpora (minimal 103/106, coverage 183/199, debug, libc_exec 7/7,
   uri 16/16 GATING, ci 110/114 reporting, battery 4/4, multi_tu,
   parse/core 100%).
3. golean-pattern in-build axiom audit live over RelSem + proof modules.
4. Layer 3 consumes only the ExecModel interface (parametricity held);
   the StateInterp slot + behavior-quantified adequacy shape documented
   against the concurrency forward-design constraints.
5. Toolchain decision documented WITH the gate evidence; if bumped:
   every toolchain-sensitive gate green + full differential re-run, and
   compiler-delta register entries for anything found.
6. Records complete (provenance-tagged D-log, verbatim transcripts);
   audits done; arc branch `arc/layer2` gate-green; merge checklist
   ready; mainlines untouched.

## Risks / pre-declared calls

- The 4.32 bump is the biggest mechanical risk — six arcs of gates are
  the net; the CSE/effect-erasure history says trust the gates, not
  hope. Revert path: worktree discard + option (ii).
- iris-lean API drift: pin the rev; upstream tracking is a follow-on
  maintenance item, not this arc's problem.
- Adequacy difficulty: fallback pre-approved (restricted Config class);
  emergency exit if even the restricted form fights fundamentally.
- WP scope creep: the exit theorem is the fence; everything else parks.
- Perf of proofs on 4.32 (elaboration changes): Tier A time budget
  monitored; a big regression is a register item, not a blocker.

## Autonomy protocol

As arcs 4-6: workers commit (green gates only, verbatim quotes),
orchestrator scopes/verifies/logs (provenance-tagged), merge is the
operator's. PLUS the proof-infra discipline (operator, from golean
experience): proof workers think about what infrastructure they need
before grinding; the escalation rule above is mandatory in every proof
worker's brief; reuse-from-iris-lean is checked before building.
Emergency-exit tripwires: no viable toolchain option; adequacy
unprovable even restricted; any gate keepable-green only by weakening;
machine-global need.
