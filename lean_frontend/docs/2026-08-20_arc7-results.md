# Arc 7 results: Layer 2 + first adequacy ("the bridge")

Companion to the charter (2026-08-19_arc7-layer2-charter.md), decision
log D1–D9 (provenance-tagged), the S3/S4 worker records
(2026-08-20_arc7-s3-layer2-slate.md, 2026-08-20_arc7-s4-iris-coupling.md;
S1/S0, S2 and S5a are recorded in their commit messages — 0dd436db5,
d84fb08b9, e7c4d5fd0/ec8036910/bab651a16, 5b007a549/59e3ef350/8b799e036),
and the spike record (2026-08-19_relsem-spike.md).

## Headline

**The program's first novel theorems: T1–T4 — ∀-quantified,
interpreter-only, kernel-checked statements about real compiled C
programs — PROVED through the full Iris weakest-precondition route and
discharged by an in-repo adequacy theorem.** T4 (struct member
write/read, the charter's exit criterion) included. Every statement
instantiates the charter's template

    ∀ args, P args → every outcome of run(compile(f), inject args)
                      is Specified (s args)   [in particular: no UB]

concretely: `T?Statement` quantifies the arguments as Lean integers,
carries the range precondition (T2's no-signed-overflow precondition
was FORCED by the UB obligation, exactly as the slate table predicted),
and concludes `CallHarnessAdequate` — a Prop over **the production
runner only** (`CerbND.runND` on `callND` over the pinned compiled Core
term): no Iris, no relational layer, no `Step` in any statement
(mechanized: the in-build statement-TCB gate). The exit-criterion
statement, verbatim (RelSem/T4.lean):

```lean
def T4Statement : Prop :=
  T4EnvHyp →
  ∀ x : Int, intRange x →
    CallHarnessAdequate t4File.tagDefs t4File "memb"
      [intValue x] t4Fs (t4Spec x)

theorem T4 : T4Statement := ...
```

**T4EnvHyp, honestly:** T4's struct layout and fresh-binder transform
read three process-global externs the kernel cannot see through — the
tag-definitions global (`with_tagDefs`), the TU-digest global and the
fresh-int supply (both via `runEffectful`). `T4EnvHyp` hypothesizes
exactly the state the harness establishes (`CerbTags.tagDefs () =
t4File.tagDefs`; digest `""`; first fresh draw `1048577`, the
start-of-process value of native/fresh_int.c). This is the DECLARED
census boundary made **visible in the statement** instead of hidden in
an axiom cone: a reader sees precisely which environment facts the
theorem assumes, and the concrete harness (Main `--call` under
`setTagDefsIO`) establishes them. T1–T3 need no such hypotheses. The
pattern is the standing template for future struct/fresh-drawing
fixtures (D9).

Every slate cone is exactly `[DAEMON, propext, runEffectful,
Classical.choice, Quot.sound]` — classical trio + the two declared
LemLib boundary axioms — pinned exactly and build-enforced in
relsem/RelSem/Audit.lean (sweep at close: 2119 declarations, 0 sorryAx
exceptions). Proofs at DEFAULT elaborator budgets throughout (D8-clean
by grep). T5 (bounded loop) is parked with pricing, which the charter
explicitly allows (bar: "T5 proved-or-parked-with-pricing").

Substrate riders: CerbND totalized (the operator's Q1 AMENDED ruling —
the executable runner IS the proof object; arc-2's declared
RunNDActiveSound seam now PROVED), CerbMem's 9 exec-path functions
totalized, 5 more generated modules totalized (arc-3 F8 residue), the
D3 sorryAx evicted, toolchain bumped 4.29.0 → 4.32.2 on full gate
evidence with zero movement, iris-lean coupled as a Lake dep
contributing ZERO axioms to the pure coupling layer.

## Slice ledger

| slice | result |
|---|---|
| S1/S0 | branch assembly (spike/relsem rebased in — 9 commits, LIVE input per plan) + in-build RelSem axiom audit (golean pattern; sweep-last lesson encoded); TOOLCHAIN BUMP 4.29.0 → 4.32.2 ADOPTED on full gate evidence, zero movement (option (ii) fallback assessed: iris-lean v4.29.1 lacks GenHeap — degraded, moot); batteries → v4.32.0 (iris-vendored rev, offline); compiler delta registered (column-0 continuation parse) with fix-forward; ARC-BLOCKING sorryAx finding registered + pinned fail-closed (D3) |
| S2 | CerbND TOTALIZED (runNDFuel + wrappers; loud panic-at-exhaustion, proof-transparent — the D4 transparency asymmetry, endorsed); runner soundness PROVED against the production runner (runND_sound, runNDActiveSound — spike RunNDT deleted in favor of the real artifact); totality gate extended over hand-written CerbND.lean (both copies, fail-closed); D3 sorryAx EVICTED (CerbFunMapInstances.lean, phantom SetType requirement — audit exceptions 5 → 0) |
| S3 | symbolic-argument harness (callND/callConfig; caller protocol read off the real elaborated Core — int params by pointer); T1–T5 fixtures + test_verify.sh (23/23; T2's UB036 overflow rows recorded); trace evidence: every slate run is ONE ND node → the by-need work is the APP-EQUATION layer, not Step arms; fuel-erasure + reachability lemma layer (behaviors_active_iff etc., 30 FuelHooks); zero escalation events |
| S4 | rule-library INVENTORY FIRST (reuse-vs-build table R1–R10); iris-lean Lake dep @ 79dab15; language instance; StateInterp = full-driver-state ghost_var (the SC slot instantiation, slot documented); wp_app_active/killed + wp_callND; **THE ADEQUACY THEOREM proved, fallback NOT taken**; T1 through the full WP route conditional on T1AppEq; term-emission instrument (kernel-transparent pinned program terms + byte drift gate); escalation events: CerbMem exec-path totalization (9 fns); F8 residue enumerated + priced (the S5 gating item) |
| S5a | the F8 fuel sweep (declares-only .lem changes; totality gate 11 → 16 generated modules + CerbND, 0 allowlisted); T1 UNCONDITIONAL via the compositional app-equation chain (post-OOM: no whole-run reductions, default budgets); THE SLATE CLIMB — T2 (15 rounds), T3 (23), T4 (56, exit criterion) UNCONDITIONAL through the fixture-generic SlateWP bridge; T5 PARKED with pricing; the in-build statement-TCB gate (negative-tested); drift gate grown to 22 concrete points on the assembled theorem objects |
| S5b | close-out prep (this doc, de-stale, merge checklist); the two adversarial audits follow |

## Success conditions vs the charter (one by one)

1. **The slate** — MET. T1–T3 + T4 (exit criterion) proved,
   kernel-checked, through the WP route (D5 ruling: the direct route is
   cross-check scaffolding only — both routes exist for each theorem);
   T1 landed first as the plumbing validator (S4/S5a); every statement
   Iris/RelSem-free by the MECHANIZED in-build statement gate
   (RelSem/Audit.lean, negative-tested in-build on t1_wp: "12 slate
   statements fuel-opsem-clean"); axiom cones exactly classical trio +
   declared boundary, pinned exactly, build-enforced; D14 gate green
   throughout. T5 parked-with-pricing — the charter bar
   ("proved-or-parked-with-pricing") is met on its parked leg; pricing
   below.
2. **CerbND totalized** — MET. Totality gate extended over it (S2, both
   copies, negative-tested); runner soundness in-repo
   (RelSem/RunND.lean: runND_sound, runNDActiveSound, behaviors_*_iff);
   hand-written axiom census still exactly 2 (with_tagDefs, forceIO —
   gate-enforced). Zero movement: Tier A green at EVERY commit (unit
   incl. sync/census/purity/totality/axiom-cone gates; minimal,
   coverage, debug baselines rc 0; libc_exec 7/7; multi_tu 2/2; parse
   ALL; core 106/106; elab recorded state; uri GATE PASS 16/16), plus
   battery slices at the S0/S2 boundaries and chvalid_battery_00 (1354
   points ALL PASSED) at the S5a close; test_verify 23/23 from S3 on.
   The tests/ci reporting sweep is not in Tier A and was not re-run
   mid-arc; it is listed in the merge checklist's post-merge
   certification (derived note, per LADDER.md placement).
3. **In-build axiom audit** — MET. relsem/RelSem/Audit.lean (S1),
   golean pattern: exhaustive module-of-origin sweep over every
   RelSem.* constant, build-failing outside the declared boundary,
   exact `#guard_msgs` pins on every load-bearing theorem, sweep as the
   file's last element, RelSem in defaultTargets (plain `lake build`
   runs it). Negative-tested at install; its fail-closed stale-exception
   tripwire fired as designed at the S2 eviction.
4. **Parametricity + slot documentation** — MET. Layer 3 consumes only
   the ExecModel interface (statement shapes are
   `ExecModel.Adequate`/`.UBFree` at `callConfig`; the adequacy
   conclusion is `CallAdequate` = `seqModel.Adequate`); the Language
   coupling is per-model BY DESIGN (the forward-design contract: the
   adequacy SHAPE is model-generic, S4 record §2); the StateInterp slot
   is parameterized and documented against the concurrency
   forward-design constraints (S4 record §3), with gen_heap catalogued
   as the Q4-refinement fill.
5. **Toolchain decision documented with gate evidence** — MET. Bump
   adopted on the full gate net (commit 0dd436db5 quotes the evidence
   verbatim: unit, all baselines rc 0, uri 16/16, battery 00+01, parse/
   core/elab); one compiler-delta register entry (column-0 continuation
   parse; principled fix = lem backend never emits column-0
   continuations — lem-lean follow-on); rebuild discipline recorded
   (make lean-prelude-src + make lean-native-obj — leanc changed).
6. **Records / audits / gate-green / checklist / mainlines** —
   Records complete (D-log D1–D9 provenance-tagged; verbatim-quote rule
   observed); arc branch `arc/layer2` gate-green at head; merge
   checklist ready (2026-08-20_arc7-merge-checklist.md); mainlines
   untouched. **Audits: 2 adversarial, IN PROGRESS at close-prep** —
   dispositions land in an addendum to this doc; the arc is not
   closeable before they do.

## Doctrine ledger (what landed this arc, and where enforced)

- **D14 ban** (standing since arc 6): enforced this arc by
  check_theorem_axioms.sh (grep leg now scans lean_frontend/relsem/;
  ofReduce* always-fatal in every probed cone) AND by the new in-build
  RelSem audit's exact pins (an ofReduce* axiom cannot enter a pinned
  cone unnoticed). The golean in-build Audit.lean pattern — the arc-7
  adoption item — is now LIVE (charter success condition 3).
- **The statement-TCB gate** (new, S5a): slate statements must mention
  no Iris-rooted constant and none of Step/Steps/CsSem/DSteps/stateIs;
  in-build, build-failing, negative-tested in-build (t1_wp must be and
  is rejected). RelSem/Audit.lean.
- **capped / never-uncapped** (D7 [USER-prompted], from the S5a OOM
  session kill): `scripts/capped` (cgroup MemoryMax via systemd-run,
  default 64G, CERB_MEM_MAX override, `=none` loud opt-out;
  breach-kill verified rc 137). Rules standing in the container
  CLAUDE.md: never run lake/lean uncapped; #eval-first; monolithic
  whole-run rfl/decide on driver executions BANNED as a proof method —
  build the compositional equation-lemma chain instead (S5a's T1–T4
  chains are the existence proof that this works).
- **Heartbeat-hacking doctrine** (D8 [USER]): elaborator-budget raises
  are by-definition defects unless investigated and agreed; codified in
  the container CLAUDE.md; enforced by audit grep — D9 verified ZERO
  budget bumps in relsem/ by grep.
- **Verbatim-transcript rule** (standing since arc 6): observed — gate
  outputs in commits/records are literal; derived tallies labeled (as
  in success condition 2 above).

## Register movements

**OUT (fixed / discharged this arc):**

- Arc-2 declared seam `RunNDActiveSound` — PROVED (S2; a standing IOU
  closed).
- D3 sorryAx finding (sorried generated SetType instance via
  Lem_Map_extra.fold's PHANTOM instance requirement) — EVICTED (S2,
  CerbFunMapInstances.lean; audit exceptions 5 → 0).
- Arc-4 G3 declared-boundary item, CerbND leg — DISCHARGED: CerbND
  totalized and inside the totality gate; `partial` may not return.
- Arc-4 G3, CerbMem leg — PARTIALLY discharged: the 9 exec-path
  functions totalized (S4 escalation event 1: memberAlign,
  offsetsofMembers, offsetsof, sizeofCtype, alignofCtype,
  memValueToBytes, reconstructValue, typeofMval,
  unqualifyAndUnatomic); only `stringFromMemValue` (pp-only) remains
  partial, plus panic! sites; CerbMem.lean is still outside the gate's
  scan (scanner extension is mechanical — priced).
- Arc-3 F8 (call-graph escapees) — PARTIALLY discharged (S5a,
  declares-only): **Utils, Annot, Ctype, Core,
  State_exception_undefined joined the totality gate** (now 16
  generated modules + hand-written CerbND, 0 allowlisted). Remaining
  F8 residue outside the slate path stays open.

**IN (new entries):**

- **The OOM incident + mitigation** (D7): a whole-driver-run rfl probe
  (maxHeartbeats 8000000) ate the 125G box and killed the session.
  Mitigation landed (scripts/capped + the three standing rules).
  Residual register item: none for the mechanism itself; the lesson is
  doctrine (above).
- **expr-family sorried BEq instance** (D9): C-tier lem item — the lem
  backend emits a sorried BEq for the expr family; surfaced during
  S5a. Lem-lean follow-on (NOT this arc's pin; lem untouched).
- **Compiler-delta / column-0 emission** (S0): lem's Lean backend can
  emit column-0 continuation arguments mid-definition; 4.32's parser
  rejects them. Fixed-forward this arc by a token-neutral .lem
  reindent; principled fix = lem backend never emits column-0
  continuations. C-tier lem-lean item.
- **The T4EnvHyp pattern** (D9, banked as the standing pattern):
  process-global externs surface as explicit statement hypotheses —
  reuse for every future struct/fresh-drawing fixture.
- **Lake lib-root wiring gotcha** (D9, recipe note): a module absent
  from its lib root builds green without being elaborated — a
  false-positive green until imported. Check roots when adding proof
  modules.
- **CoreParser totalization** (S4): parked — the term-emission
  instrument made it non-blocking; statement-side nicety.
- **Term-emission growth** (S4/S5a): whole-linked-file emission (full
  stdlib + main + function-pointer values) for T5-at-scale and
  libxml2-scale statements.
- **gen_heap-over-heapOf** (S4): the Q4 granularity refinement's first
  work item; entry points catalogued (S4 record §0.1) — a parameter
  fill of the documented slot.
- **iris-lean mirror** (D6): deps/mirrors/iris-lean.git needed at the
  next network window (recorded in deps/gitconfig too).
- **T5** (D9): parked with pricing (below).

## Pins at close

Single-repo arc: lem-lean UNTOUCHED (zero commits; zero model-.lem
semantic changes — the arc's .lem edits are declares-only totality
annotations + one token-neutral reindent, both cerberus-side). LemLib
pin: Lake manifest `bd7e2eb` = deps/lem-pinned `bd7e2eb` = opam pin —
unchanged from the arc-6 close, verified at S5b. New pins this arc:
iris `79dab154a` + Qq `38d591e77` + batteries `023ce7d62` (v4.32.0),
all resolved offline via deps/gitconfig redirects. Toolchain:
leanprover/lean4:v4.32.2.

## Arc-8 pricing

1. **T5** (bounded-loop sum) — ONE SESSION: fuel induction over a
   ~30-round loop block with a (i, sum i) state-family invariant; the
   machinery (SlateWP bridge, request-arm unfolds, byte-roundtrip
   lemmas) all exists; the induction scaffold is the only new object.
   Its fixture, oracle dump, assembled t5File and 4 concrete
   expectation rows are already in-repo and drift-gated.
2. **gen_heap granularity refinement (Q4)**: finer Step + gen_heap over
   heapOf as the StateInterp fill; moves points-to/frame/loop reasoning
   up to WP level. Entry points catalogued; slot designed for exactly
   this swap.
3. **libxml2 chvalid-predicate slate entry (charter stretch "S")**: one
   chvalid predicate, ∀ code point, vs the range tables — needs
   whole-linked-file term emission (register item above) + the
   established harness.
4. **Concurrency arc tray** (banked notes + spike docs + survey): cmm
   instance = new Language coupling + StateInterp fill under the SAME
   adequacy shape — the forward-design constraint held all arc.
5. **pp-placeholder text class** (arc-6 carry: 3 ci non-agreements +
   mem3-004).
6. **Register burn-down**: read-only allocations (finding 11,
   corpus-forced, top of queue since arc 6); stack-ceiling guard;
   remaining F8 residue; CerbMem gate-scan extension; CoreParser
   totalization (parked).
7. **Lem C-tier items** (lem-lean, next time the pin moves): expr-BEq
   sorried instance; column-0 continuation emission; DAEMON instance
   fallbacks (standing temporal-boundary mover).
