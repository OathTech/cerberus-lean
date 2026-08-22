# Arc 15 — "the spec lab" (harness-template examples, experimental)

STATUS: BLESSED 2026-08-22 ([USER]: "(1) agree, (2) no strong opinion,
what do you think? (3) no, let's do it"). Decisions: D1 [USER] Lane B
(T5 resumption) runs IN PARALLEL on the preserved workbench-v2
worktree, branch arc/t5-landing; D2 [AGENT, delegated] fresh
lean_frontend/speclab package (churn isolation from relsem + rehearses
the example-repo split); D3 [USER] rung ladder as drafted. Charter
origin [USER 2026-08-22]: "Let's charter an arc building some examples.
We can be a bit experimental here, try some different spec styles, see
what works. I think this is an area where we have the ingredients but
I'm not sure exactly how they should fit together."

Grounding: notes/2026-08-22_harness-statement-template.md (the ratified
template: model-∀ headline, compiled-const-array choice streams,
readback via observation channels, plant tests, generators-as-parsers
lineage), the container CLAUDE.md specs-are-programs doctrine block,
and the north star (boring specs at Linux scale).

## Purpose and stance

Instantiate the harness statement template on a ladder of real
examples, DELIBERATELY EXPERIMENTALLY: where a rung admits more than
one spec style, build the contenders side by side and record the
comparison. The arc's primary product is the SPEC-STYLE REGISTER — a
dated record of what fit together, what fought, and why — plus the
harness idiom library v1 and the revised template. Example count is
secondary. Dead ends are legitimate outcomes: experiments may be
abandoned mid-rung, but every abandonment is a register entry (what was
tried, why it lost), never a silent deletion.

Two standing invariants no experiment may violate: statements stay
executable/first-order (the statement-TCB gate extends to the new
package — Iris/RelSem vocabulary in a statement fails the build; the
escape hatch remains a per-instance operator decision), and every
harness instance stays concretely runnable + oracle-differentiable.

## Slices

S0 — preliminaries + scaffold
  * Read golean's structure-parameterization approach; attribute in the
    idiom library header (standing S0 obligation from the doctrine).
  * argv-parity probe (mechanism B go/no-go): does `main(argc, argv)`
    behave identically oracle-vs-Lean? Record; template stays on
    mechanism A regardless (B is an upgrade, not a dependency).
  * Verify the fork's CN magic-comment filtering in cabs-json (doctrine
    flag from the warm-up notes) on 2-3 deps/cn files.
  * Scaffold: new in-repo Lake package for the lab (proposed:
    lean_frontend/speclab, sibling of relsem, consuming the semantics
    the same one-way way — rehearsing the third layer of the two-part
    design; re-homeable by construction, gates ride along per the
    package-rehearsal findings). mkHarness v1 (Stream → C source
    splicer, template + literal holes), codec library first cut
    (self-delimiting scalar/array codes), plant-test runner.

S1 — R1 scalar rung ("hello template")
  * A scalar function (candidates: deps/cn division/mod family — real
    external code with CN specs for the comparison column). Full pipe
    end-to-end: mkHarness → differential sweep over sampled streams →
    fuzz+shrink smoke → kernel-checked theorem at concrete streams.
  * Style experiments at this rung (cheap here, informative): Form 1
    (expected-array + mismatch-index comparator) vs Form 2 (stdout
    serialization) vs boolean verdict (legitimate here — genuinely
    boolean properties exist at R1); model-∀ vs stream-∀ headline
    ergonomics in Lean. Register entry comparing all.

S2 — R2 array rung (the byte-blaster)
  * Array function (e.g. a deps/cn array example or memcpy-shaped
    target). Byte-blaster codec (stream → buffer verbatim) — this rung
    validates the containment-side story. Fixed length first; symbolic
    length IF T5 tech is available by then (see Lanes), else register
    the concrete-N ceiling and move on.

S3 — R3 list rung (first real builder)
  * Linked list (deps/cn append/queue family). First non-trivial
    builder + walker + comparator idiom; leak conjunct live (teardown +
    empty-allocation-map observable); path-selection idiom prototype.
  * Experiment: comparator-in-C vs serialize-then-judge-in-Lean for the
    SAME property — head-to-head register entry.

S4 — R4 tree rung (the reference instance)
  * The tree-rotation example from the design discussion, built to be
    THE template's reference instance: inductive model, codec,
    builder-correctness statement, decode∘encode=id, path-selected
    interior pointer argument, plant tests, both readback forms.
    This rung's write-up becomes the worked example in the template
    note.

S5 — CN slate seed + close-out
  * 1-2 real deps/cn examples with substantive postconditions restated
    in our template; the CN-vs-us comparison record (modular contracts
    vs closed-program observation + the shared generators-as-parsers
    substrate). Candidate list drawn at S5 from the ~50 non-.error
    DRIVEN/DIRECT corpus files (manifest classes from the cn_coverage
    lane).
  * Close-out: spec-style register finalized; template note revised
    with lessons; idiom library v1 documented; results doc + audit ask.

## Proof-style exploration (bonus objective, [USER 2026-08-22])

"Bonus if the lab explores some styles of proof and whether they might
scale to the sorts of thing we'll encounter in Linux (speculatively,
they don't need to do it)." Alongside the spec-style register, a
PROOF-STYLE REGISTER: per rung, where affordable, discharge the same
obligation in contending styles and grade each — speculatively —
against a Linux-scaling rubric. No rung is obligated to achieve scale;
the deliverable is evidence-graded judgment, not throughput.

Contending styles (initial slate; workers may add):
  P1 walker/certificate (arc-9 app_walk + law tables + per-stage
     certificate emission — mechanical compositional chains);
  P2 Iris WP + adequacy (T1-T4 style: OwnP, lemma kits, framing,
     modular callee treatment — the party in the back);
  P3 trace/replay-driven (arc-11 engine: proof as checked replay of a
     symbolic run, context-indexed laws, typed residuals);
  P4 direct invariant-family/iter_compose (loop rules without full
     Iris ceremony);
  P5 pure-transport division of labor (prove properties of modelFn in
     pure Lean where it's cheap, one builder/adequacy bridge carrying
     them into the semantics — how much of the work can live in pure
     land?).

Scaling rubric (grade 1-5 + a sentence of evidence each):
  (a) proof-lines per C-line and its growth trend across rungs;
  (b) re-pin robustness — cost when the target C changes (trace/replay
      re-pin economics are the benchmark);
  (c) mechanization fraction — obligations discharged by walkers/
      emitters vs by hand;
  (d) elaboration pressure — styles that push toward budget bumps are
      disqualified by the heartbeat doctrine, note early;
  (e) C-shape realism — struct/union-heavy data, interior pointers,
      aliasing, loop nesting, unbounded heap structures (the pKVM
      buddy / WireGuard shapes as the mental target);
  (f) parallelizability — can N workers prove N functions
      independently?
Close-out includes a short speculative memo: which styles plausibly
scale to the kernel-adjacent slate, what's missing from each, and what
the next automation investment should be — feeding the north star's
"most aggressive proof automation" line with data.

## Lanes / T5

Lane A = S0-S5 above. Lane B = the T5 resumption (R-S2-1 first move,
in the preserved workbench-v2 worktree) — T5's symbolic-n iter_compose
tech is what upgrades rungs from concrete-N to parametric, so it is on
this arc's critical path for the PARAMETRIC claims but NOT for the
lab's comparative mission (concrete-N certificates are honest evidence
for style comparison). OPERATOR DECISION REQUESTED: run Lane B in
parallel (disjoint write surfaces: workbench-v2 relsem T5 files vs the
new speclab package; merges serialize per playbook) or defer T5 and
accept concrete-N ceilings this arc.

## Validation and gates

Standard battery stays green throughout (unit 7/7, exec zero-movement,
core ALL, verify, cn_coverage baseline, immaculate, libc, uri). New:
speclab differential lane (sampled-stream sweeps per rung,
baseline-pinned once a rung stabilizes), plant tests MANDATORY per
harness template (broken-target ⇒ red differential + unprovable
theorem, demonstrated per rung), statement-TCB + axiom-cone gates
extended to speclab, proofs capped as always, no heartbeat bumps.
Proof economics observed per rung (lines-per-obligation) — feeding the
automation story, not gating.

## Mechanics

Branch arc/spec-lab (cerberus-lean only; no lem changes anticipated —
if any lem need emerges, STOP and re-charter the pair). Worktree via
new-worktree.sh. Orchestrator/worker doctrine as standing: workers
commit on green, orchestrator verifies independently at slice
boundaries, checkpoints on concrete objects are the operator's,
pre-merge audit ask unconditional, merge ff-only on explicit sign-off.

## Success criteria

1. R1-R4 landed: runnable, differentially validated, plant-tested,
   kernel-certified at concrete streams minimum.
2. The twin registers (spec-style + proof-style): every experiment
   (incl. abandoned ones) recorded with a verdict and a reason; the
   proof-style register closes with the speculative Linux-scaling memo.
3. Idiom library v1 (codecs, builders, comparators, mkHarness) with
   golean attribution.
4. Template note revised; CN slate seeded with the comparison record.
5. If Lane B ran: T5 landed = workbench-v2 exit criterion 1 satisfied.
