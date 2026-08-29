# 2026-08-31 — container ROADMAP archive

**What this is.** The container-level `ROADMAP.md` (drafted 2026-08-18
"with Mike"; its own header said "move into a repo if it should be
versioned"), archived verbatim at the CLAUDE.md-hygiene slice — the
container keeps no notes/chronicles. It is the arc index and original
objective list for the Cerberus→Lean effort; the arc-by-arc history it
indexes lives in the dated records in this directory and on the park
branch (`arc/segment-ladder`, tag `park/reasoning-era-20260831`).
Current state supersedes it: `README.md` / `VALIDATION.md` / `TODO.md`
(the semantics product) and the refined-cerberus repo (the successor
verification effort).

---

````````markdown
# Cerberus→Lean Roadmap

Status: drafted 2026-08-18 (with Mike). Lives at container level; move into a
repo if it should be versioned.

## Objectives

1. **Lean backend passes Lem and builds cerberus** — lem's `-lean` backend
   generates a Lean artifact of the cerberus model that compiles cleanly.
2. **OCaml-backend parity** (revised 2026-08-18; supersedes the earlier
   Rocq-parity framing — the Rocq backend is semi-broken and is NOT a gate):
   classic Cerberus capability is the OCaml executable semantics. The target
   is a **runnable Cerberus based in Lean at parity with the OCaml backend**
   on the core C semantics — same results/UB verdicts on the test corpora,
   exhaustive + deterministic modes, LP64, concrete/defacto memory — built in
   Lean so the result can be reasoned about. Parity is *measured* by
   objective 6 (differential testing) — but per the mirror-OCaml doctrine
   (2026-08-19, see CLAUDE.md): gratuitous code-logic divergence from the
   OCaml implementation in hand-written seams is a defect AS SUCH,
   independent of whether any test currently exposes it; deliberate
   divergences are always documented in-code. Out of scope: BMC, CHERI,
   web UI, CN, real concurrency (cmm stays stubbed); the C parser remains
   the thin OCaml front (Cabs JSON boundary).
3. **No cerberus restructuring** — changes to `frontend/model/*.lem` limited to
   `declare lean ...` handlers and equivalents. OCaml backend stays ground truth.
4. **Idiomatic Lem** — every lem extension should be plausibly acceptable to
   rems-project/lem.
5. **Prototype reuse without design bending** — reuse cerberus-lean-prototype's
   test/differential harnesses, corpora, and (selectively) implementations
   behind `target_rep` seams; do NOT absorb its hand-written Core AST/interpreter
   into the generated path.
6. **Differential validation** (added) — every pipeline stage in Lean is
   differentially tested against OCaml cerberus on shared corpora. This gates
   each phase.

Scope decisions (2026-08-18): execution of C programs via the generated Lean
semantics is a **first-class goal** (not just a validation oracle). Upstreaming
to rems-project is an **explicit goal shaping design now** — no fork-only hacks
in lem; cerberus-side hand-written support files have more latitude.

**North star:** a program-verification pipeline for C on top of cerberus-lean,
following the golean layering. **Named long-term target (added 2026-08-19):
verifying libxml2** (`deps/libxml2` @ c6324894 — 55 TUs, ~175k lines).
Realistic shape: verified properties of selected libxml2 functions/modules
(natural entry points: dict.c, chvalid.c, buf.c — self-contained,
data-structure-heavy, I/O-light), not whole-program verification. What the
target re-prioritizes, threaded into the phases below:
- **libc surface** (already the #1 next-arc parity item) becomes strategic,
  not just corpus hygiene — libxml2 leans on string.h/stdlib.h everywhere
  (mitigated by xmlMalloc-style allocator indirection, which is pluggable).
- **Multi-TU translation + real digests**: `CerberusFresh.digest` is
  permanently `""` today, making `from_same_translation_unit` vacuously
  true — latent for single-file tests, load-bearing for a 55-TU library.
- **CerbFS** (largest uncompared seam, survey-flagged) — xmlIO paths;
  deferred if verification starts on I/O-light modules.
- **Scale**: exhaustive-ND execution will not scale to library-sized code;
  deterministic mode + per-function differential harnesses (call a
  function under a driver, not main()) are the instrument to build.
- **Phase-5 design consequence**: the spec/proof story must target LIBRARY
  FUNCTIONS under contracts (CN-style or Iris triples + calling harness),
  and the memory-model interface must cover libxml2's allocator/string
  idioms.
- **Front-end probe (cheap, early, un-arced)**: run a few preprocessed
  libxml2 TUs through OCaml `cerberus --pp core` to price the frontend gap
  (GNU extensions, configure-generated headers) BEFORE any arc commits to
  the target; the OCaml side is the gate — if classic cerberus can't
  elaborate it, neither can we.

The golean layering:
1. **Fuel-based operational semantics** — pure total step/run functions with
   fuel, generated from the .lem model. This is the theorem substrate.
2. **Relational semantics** proved as a layer on top of the fuel opsem.
3. **iris-lean as proof machinery only** — WP/separation logic above the
   relational layer; **adequacy discharges every Iris-level proof into a
   statement over the fuel opsem. Final theorems are opsem-level; Iris and the
   relational layer sit outside the TCB.**

TCB = lem translation + generated fuel opsem (+ Lean kernel). Objective 6
(differential testing vs OCaml cerberus) is the empirical validation of exactly
this trusted object: everything trusted is tested, everything proved is
untrusted machinery.

Consequences threaded through the phases:
- **Phase 0 is decided in direction**: the theorem substrate must be pure —
  hidden-IO effects are disqualified from the TCB path. Monadic lifting (or
  equivalent pure state threading in the lem backend) is the destination;
  Lean-side containment (`@[never_extract]` etc.) is scaffolding only, to
  unblock differential testing while lifting is built.
- **Nondeterminism made explicit**: Core's ND (UB exploration, eval order) in
  the fuel opsem via outcome sets (exhaustive, matching cerberus
  `--mode=exhaustive`) and/or a schedule/oracle parameter the relational layer
  quantifies over. Cerberus already reifies ND in `driver.lem` /
  `core_reduction.lem` — map that structure onto the fuel pattern (obj 3: no
  restructuring).
- The memory model interface must support separation-logic assertions
  (points-to with provenance) — informs the Phase 3 memory-model decision.
- **Model parametricity (operator principle, 2026-08-19)**: the memory/
  concurrency model is an aspect to keep AS PARAMETRIC AS FEASIBLE — the
  research community legitimately disagrees (legacy C11 vs RC11 vs
  promising vs ...), so semantics and reasoning stay cleanly factored to
  admit multiple models with very different approaches. Realistic
  factoring: (a) fix the INTERFACE at the candidate-execution/event
  level (actions, pre-executions, relations — cerberus already has this;
  REMS's ArchSem validates the same design for ISA semantics); (b) a
  model plugs in either as consistency+UB predicates over candidates
  (axiomatic style) or as a step relation carrying a PROVED bridge to
  candidate-level predicates (operational style — the
  executable-equivalent direction); (c) reasoning stack = model-generic
  adequacy core (behavior propositions parameterized by the model's
  observable-behavior function; Iris StateInterp as a per-model slot) +
  PER-MODEL surface-rule libraries — uniform proof rules across models
  are explicitly NOT promised; the bespoke-logic stance covers the
  per-model layer. Precedent already in-tree: the sequential Mem
  interface (concrete/defacto/symbolic pluggable) and cmm_csem's named
  submodel family.
- The prototype's `CN/` + `Verification/` machinery is direct design input for
  the verification layer (obj 5).
- Logistics: `deps/iris-lean` and `deps/golean` are checked out (2026-08-18)
  and readable — fine for design/reference work now. **Not yet buildable
  offline**: Iris pins Lean v4.32.2 (not installed; elan can't download in the
  sandbox) and a Qq commit newer than our mirror snapshot. Fix in a networked
  maintenance window: `elan toolchain install leanprover/lean4:v4.32.2`,
  refresh `deps/mirrors/*`, then `lake build` in `deps/iris-lean/Iris` (and
  optionally IrisMath + mathlib cache) to vendor packages.
- **Toolchain alignment (Phase 5 constraint)**: Iris is on 4.32.x, cerberus
  lean_frontend on 4.29.0, golean on 4.31.0. Using Iris as a Lake dep of the
  cerberus artifact requires one shared toolchain — plan an upgrade of
  lean_frontend (re-validating fresh-int/CSE behavior on the new compiler) or
  pin Iris back. Decide when Phase 5 starts; budget for the bump.

## Current state (see CLAUDE.md for build/test detail)

- Everything builds offline; worktree workflow in place; repos in sync
  (lem-lean `237867b` = opam pin = Lake pin; arcs 1–8 merged, latest
  arc 8 close 2026-08-20).
- Effects/totality: exec slice PURE (enforcing gate), theorem cones
  DAEMON-clean (enforcing gate), and — arc 3 — the whole 11-module exec
  slice TOTAL (`check_exec_totality: CLEAN, 0 allowlisted`, enforcing);
  66 kernel-checked theorems in the unit gate (6 arc-1/2 + 52
  wrapper-defeqs + 8 symbolic-execution).
- Pipeline (arcs 4+5, merged 2026-08-19): full C → execution in Lean,
  differentially validated vs OCaml — tests/minimal 103/106 (zero open
  mismatches), coverage 178/199 comparable (+24 in arc 5: all 20
  libc/builtin linking FAILs closed via the ailname seam), debug green,
  csmith smoke 3/3. REAL multi-TU (generated Core_linking + per-TU MD5
  digests). **libxml2 first contact: chvalid.c through the Lean pipeline
  at 100% differential (1354 boundary points)**; the 5-TU uri closure
  sits at exact --nolibc failure parity. Arc 6 (merged 2026-08-19)
  closed the set: C-libc loading (pinned oracle dump + our linking) →
  **uri gate 16/16 GATING**; varargs (reg 15 FIXED, coverage 183/199);
  perf (battery 4 slices, ratio 1.7× flat, kernel-checked Fmap
  equivalence); first tests/ci exec sweep **110/114 (96%)** vs the
  prototype's ~13 historical; test_core 100% (078 fixed). Register: 12
  open, finding 11 corpus-forced. Phase 5 substrate advanced in
  parallel: spike/relsem has ExecModel (parametric adequacy) +
  runNDT_sound proved; iris-lean builds offline. **Arc 7 merged
  2026-08-20: Layers 2+3 EXIST — the adequacy theorem is proved and the
  FIRST THEOREMS landed (T1-T4: ∀-quantified, interpreter-only,
  kernel-checked statements about compiled C functions, incl. the
  struct exit-criterion and the overflow-precondition discovery)).
  T5 (bounded loop) parked at one session. Toolchain 4.32.2.**
  **Arc 8 merged 2026-08-20 ("the consistent boundary"): DAEMON
  ELIMINATED — the inconsistent axiom family deleted from LemLib; lem
  backend derives real bounded Inhabited instances + threads
  [Inhabited] binders (failwithI everywhere, fail-closed: underivable
  types are loud generation-time errors). T1-T4 cones now exactly
  [propext, runEffectful, Classical.choice, Quot.sound] —
  UNCONDITIONAL kernel certificates; arc-7's qualifier is gone.
  Absence enforced by the in-build gate + a tree-wide name-independent
  generated-axiom census (plant-tested). Zero differential movement
  across the full surface. Audit fixes: L_undefined now mirrors
  OCaml's raise (was silent default — concurrency-arc landmine
  defused). Records: cerberus-lean lean_frontend/docs/2026-08-20_arc8-*.**
  **Arc 10 merged 2026-08-21 ("robustness"): ci 114/114 comparable /
  0 mismatches; 1134 comparison-sorries → 0 (real derived structural
  comparisons, OCaml-parity audited to 24,650 float points);
  float/bytes/csmith-corpus lanes gating; csmith campaign 3169
  programs / 0 Lean-side defects; the F-D REATTRIBUTION (fork-oracle
  declaration-layout corruption = OUR regression, upstream correct —
  repair is the top next-arc item) + the fork-drift gate
  (manifest + hash-pinned generated diffs vs deps/cerberus-upstream).
  Records: docs/2026-08-21_arc10-results.md.**
  **Arc 9 merged 2026-08-21 ("the workbench"): the proof-machinery
  arc — OwnP adoption, 6 kits/54 pins, axiom-free iter_compose,
  app_walk walker + per-stage kernel-certificate emitter
  (plant-tested sound), proof-size gate; calibration ~200→5 lines;
  T5 parked at evidence grade (44/79, named resumption) = workbench-
  v2 exit criterion 1 with the committed survey slate as its spine.
  Records: docs/2026-08-21_arc9-results.md.**
  **Arcs 11+12 merged 2026-08-22: the F-D corruption family is DEAD
  (fail-stop floor; oracle verdicts never silently wrong; upstream
  filing drafts ready) and the workbench-v2 engine is live
  (trace/replay ~15x, context laws, the relsem-package rehearsal
  with real-split findings). T5 at 45/79 with the resumption path
  fully specified (R-S2-1 → R-S2-2 → climb, post-renumbering).
  NEXT: the renumbering arc (preconditions now met), then the
  immaculate pass + grumpy re-mark, then the T5 landing.
  Records: docs/2026-08-21_arc12-results.md +
  docs/2026-08-22_arc11-results.md.**
  **Arc 13 (clean numbering) merged 2026-08-22: fork oracle numbering
  = upstream's byte-identically, F-D closed by construction,
  grandfather register dissolved (516 rows restored, mismatch=0),
  proof re-pin 30s. Arc 14 (immaculate pass + re-mark) merged
  2026-08-22: semantics A− / backend B+ under the grumpy-professor
  standard, immaculate test lane + content-hash pins standing,
  pins lem 861ed81 / cerberus 195964b44, full certification green.
  NEXT: the substantive track — T5 landing + CN warm-up slate
  (specs-are-programs doctrine); A-road polish registered for later.
  Records: docs/2026-08-22_arc13-results.md +
  docs/2026-08-22_arc14-results.md.**
- **[USER 2026-08-22] NORTH STAR (verbatim): "our purpose in all this
  work is to build a verification tool we can use to verify
  substantial parts of the Linux stack. We're primarily interested
  in containment and safety and large portions of Linux are written
  in C. This pushes us towards a very 'boring' spec style, because
  we simply can't read specs at scale and understand them if they
  are fancy, and it push us towards the most aggressive proof
  automation that has ever been implemented in a theorem prover. We
  want to verify vast and unprecedented things."** Design pressure
  this exerts: spec readability over expressiveness (statement-level
  boring; Iris in the back), automation economics over one-off proof
  effort (the workbench bet), containment/safety properties as the
  property class of record, and target selection that climbs toward
  kernel-adjacent C (pKVM buddy, WireGuard are on-mission, not demos).
- **[USER 2026-08-21] Repo-architecture direction — the two-part
  design**: split "cerberus-lean the semantics" (generated port +
  hand seams + differential substrate; BSD; the consumable/
  upstreamable artifact) from "cerberus-lean the verification layer"
  (relsem: workbench + theorems; pins the semantics like it pins
  iris), with per-target example repos (incl. GPL'd ones, per the
  same-day ruling) as a third layer. Sequencing [AGENT-recommended,
  operator-reviewed]: forward-design constraint NOW (one-way
  dependency stays absolute — gate-enforced; interface enumerable);
  rehearse in workbench-v2 (relsem as its own in-repo Lake package);
  cut for real when the kit/wrapper interface stabilizes post-slate
  or the GPL example repo lands — own small arc (history, gate
  re-homing, CI).
- Rocq backend/export: semi-broken (per Mike), not a gate — see obj 2.

## Phase 0 — Effects design + re-sync  ← everything regenerates from here

The keystone: ambient effects (fresh counters, debug output, tagDefs state)
that OCaml gets from mutable refs must work in Lean for BOTH proofs and
execution.

Candidates:
- **(A) effectful declares + runEffectful thunks** (current pin): dead — CSE
  breaks it, proof-hostile, already reverted on lem HEAD.
- **(B) Monadic lifting in the lem backend** (direction sketched in lem
  `549e2ac`): backend-local effect inference — functions touching effectful
  vals become monadic in *Lean output only*, no .lem signature changes
  (preserves obj 3). Honest semantics, best proof story, upstreamable as a
  real lem feature. Highest effort.
- **(C) Lean-side containment**: keep lem pure-looking; implement effectful
  externs in hand-written support files with IO refs + the standard
  `@[never_extract]`/`noinline`/`unsafeBaseIO` idioms (as Lean core does for
  `dbgTrace`). No lem changes at all (obj 3/4 friendly); execution unblocked
  immediately; proof story = swap in a pure model implementation at the same
  target_rep seam. Defers semantic honesty.

Direction (set by the golean layering, see North star): **B is the
destination** — the TCB opsem must be pure, so hidden-IO containment can never
be the proof-facing mechanism. C survives only as scaffolding.

Plan:
- [x] **Scaffolding fix + re-sync** (done 2026-08-18): the effectful
      mechanism was broken three ways — (1) runEffectful_impl reinterpreted
      the io-result object instead of running the action (now unsafeBaseIO);
      (2) closed-term extraction + LCNF CSE cached/merged call sites — fixed
      with `attribute [never_extract] runEffectful` (axiom, defeats CSE) AND
      `@[never_extract, noinline]` on the impl (defeats extraction), both
      load-bearing; (3) not transitive — the lem backend now emits the same
      attributes on generated defs containing effectful calls; (4) native
      C externs updated to the Lean ≥4.29 world-erased convention.
      lem-lean HEAD = opam pin = Lake pin = `dff1957`; `fresh-int-test`
      GREEN; all suites at pre-existing baseline. Known gap: effectful calls
      inside instance methods (attributes not attachable to instance fields).
- [x] **arcs 1+2 (effects-totality / exec-honesty) — MERGED 2026-08-18**:
      lem-lean `mdd/lean-backend` @ d25f982 (reader / fuel / ground_rep /
      reader_seed declares, failwithI/fromJustI, runEffectful fix);
      cerberus-lean `mdd/cerberus-lean` @ 059312666. Delivered: debug
      stubbed pure; tagDefs an honest reader parameter (desugar chain
      needs no reader at all after S6); fresh threaded through
      core_run_state; exec slice PURE (enforcing gate); theorem cones
      DAEMON-clean (enforcing gate); with_tagDefs divergence closed;
      six proof-test theorems + supply lemmas, kernel-only. Both arcs
      adversarially audited (2+2 agents), all findings fixed-or-recorded
      (design note §10-§19). Deferred with records: C-tier generated
      Inhabited fallbacks; fresh state-val for translators (§7c);
      Phase-2 obligations (sym non-escape assertion, sizeof-struct
      const-expr test).

- [ ] Eliminate remaining sorry target_reps: `easy_update_mem_value_aux`
      (defacto_memory), `runND_proxy` (mini_pipeline). NOTE these sit on the
      execution path (memory model, ND driver) — they are Phase 2 blockers,
      not cosmetic.
- [ ] Core text parser gaps (`078-float-special`: builtin/proc ordering).
- [ ] Makefile rule for `native/*.o` (currently hand-compiled).
- [x] **Instance-generation hygiene — arc 8 (DAEMON elimination),
      MERGED 2026-08-20**: the DAEMON axiom family DELETED; backend
      derives real bounded Inhabited instances (fail-closed) + threads
      [Inhabited] binders; all cones DAEMON-free (driver2 =
      [propext, Classical.choice, Quot.sound]); absence gates enforce
      non-reintroduction. Records:
      `cerberus-lean/lean_frontend/docs/2026-08-20_arc8-*`.
- [x] **Totality — arc 3 (totality sweep), MERGED 2026-08-19**: lem-lean
      `mdd/lean-backend` @ 574e326, cerberus-lean @ 96b9223c2(+re-pin).
      Decision settled: the lem backend generates fuel-threaded total
      defs, declare-controlled (`termination_argument` / `fuel val` with
      witness sentinels). Delivered: fuel×reader + fuel×mutual
      composition, `fuelExhausted` opaque witness sentinels, acyclic
      de-mutualization, negative-probe test lane; all 97 exec-slice
      partials resolved (39 structural flips, 52 fuel, ~11 de-mutualized,
      1 excluded sorry stub) — allowlist EMPTY; enforcing totality gate;
      60 new kernel proofs. Audited (2 agents, all claims hold). Deferred
      with records: totality of the exec CALL-GRAPH CLOSURE (≥13 partials
      in 10 non-slice modules on the spine's call path — audit F8);
      runtime-fuel differential is parse-only today; driver-cone
      sorry/DAEMON elimination (D9). Full records:
      `cerberus-lean/lean_frontend/docs/2026-08-18_arc3-*`.

Exit: no sorries; parser suites 100%; axiom surface documented and confined
to declared boundaries. (Optional, non-gating: a quick look at what lem's
Rocq backend does for constructs we handle — occasionally informative for
backend design, but the OCaml backend is the sole ground truth.)

## Phase 2 — Pipeline completion (each stage gated by differential tests)

Order per lean_frontend roadmap, each landing with a differential harness
against OCaml cerberus (reuse prototype patterns; corpora: tests/minimal, ci):
- [ ] Desugar: fix stdlib Fmap conversion; goldens per stage.
- [ ] Typecheck (GenTyping.annotate_program).
- [ ] Translate (Translation.translate).
- [ ] Execute (Driver.drive): differential exit codes/UB verdicts vs OCaml
      (the prototype's interp-diff methodology, retargeted).

Exit: C → … → execution in Lean matches OCaml on tests/minimal (100%) and a
tracked pass-rate on tests/ci.

## Phase 3 — Runnable-parity milestone + prototype convergence

- [ ] **OCaml-parity milestone (obj 2 gate): a runnable Cerberus based in
      Lean** — the Phase 2 pipeline consolidated and validated: differential
      agreement with the OCaml backend across tests/minimal + tests/ci
      (tracked pass-rate), both execution modes, with the reasoning-readiness
      smoke test of stating one nontrivial theorem over the model.
- [ ] Port prototype test infra/corpora onto the main repo where still useful
      (csmith fuzzing harness, coverage suites, GenProof ideas).
- [ ] Memory-model decision: prototype's concrete/provenance model as an
      alternative `mem` instantiation behind the lem interface, or leave.
- [ ] Reduce prototype to a test oracle or archive it. Record decision.

## Phase 4 — Upstreaming & sustainability

- [ ] lem: propose lean backend (+ effects mechanism) to rems-project/lem.
- [ ] cerberus: propose lean_frontend + declares to rems-project/cerberus.
- [ ] CI for the offline build (worktree scripts, mirrors refresh procedure).

## Phase 5 — Verification pipeline (golean layering over cerberus-lean)

The north star. Can begin design work in parallel with Phase 2/3; depends on
the pure fuel opsem from Phases 0–2.

- [ ] Mirror iris-lean into `deps/` (needs maintenance window; see North star).
- [ ] **Layer 1 — fuel opsem as theorem substrate**: substantially
      delivered by arc 3 (the generated step/eval/driver functions ARE
      fuel-based total defs with kernel equations; wrapper-defeq +
      symbolic-execution theorems prove the substrate works). Remaining
      for this item: totalize the call-graph closure (audit F8), clean
      the deep cones (D9), and the API curation (what downstream layers
      see; ND explicitness as outcome sets / oracle parameter).
- [ ] **Layer 2 — relational semantics** proved sound w.r.t. the fuel opsem
      (fuel-erasure / step-indexing lemmas; golean as the pattern).
- [ ] **Layer 3 — iris-lean machinery**: language instance over the relational
      layer, WP calculus, **adequacy theorem landing final statements on the
      fuel opsem** (Iris outside TCB).
- [ ] Separation-logic memory interface: points-to over the cerberus memory
      model (provenance-aware); prototype `Memory/` + `CN/` as design input.
- [ ] Front-end story: CN-style specs vs direct Iris proofs — decide with
      prototype `CN/` experience in hand.
- [ ] End-to-end demo: verified C program (e.g. prototype's Verification/
      examples re-proved through the generated semantics), final theorem
      stated purely over the fuel opsem.

Exit: one C program verified end-to-end; its theorem statement mentions only
the fuel opsem (and the program), not Iris.

## Risks / watch items

- **Effects decision reversal risk**: if C ships first and B never lands, the
  proof artifact carries opaque axioms at effect boundaries — acceptable only
  if documented and confined (obj 2 gate checks this).
- Lean toolchain drift (CSE behavior changed under us once already): pin
  toolchains; re-run fresh-int-test on every toolchain bump.
- Parity scope creep: "runnable Cerberus" must stay scoped to the core C
  semantics (obj 2's out-of-scope list) or Phase 3 never closes.
- Offline sandbox: `lake update` of scoped deps and new opam installs need
  network — batch such changes for networked maintenance windows.
````````
