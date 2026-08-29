# cerberus-lean-proj

Container folder (not itself a git repo) for the Cerberus→Lean project.
Everything needed to build lives inside this folder plus `~/.elan` toolchains.
**Do not modify machine-global state** (~/.gitconfig, opam default switch,
shell profiles, shared caches) — this machine runs several agents. All
project mechanisms here are directory- or environment-scoped.

## Layout

| Path | What |
|------|------|
| `cerberus-lean/` | Main repo, branch `mdd/cerberus-lean` (C semantics + `lean_frontend/` Lean port generated from .lem via lem) |
| `lem-lean/` | Lem fork, branch `mdd/lean-backend` (Lean backend + `lean-lib/` LemLib runtime) |
| `cerberus-lean-prototype/` | Earlier prototype: Core-JSON interpreter in Lean (`lean/`), own cerberus submodule |
| `deps/lem-pinned/` | git worktree of lem-lean @ `c10548f` (branch `cerberus-pin`) — the lem version cerberus-lean actually builds with (see Known issues) |
| `deps/mirrors/` | bare mirrors of all Lake/git dependencies (offline insurance; incl. iris-lean, cn, the case study since 2026-08-20; linux deliberately unmirrored — its checkout .git is the copy) |
| `deps/cerberus-upstream/` | un-forked upstream cerberus @ b9aeedcb4 (= the fork's merge-base; mirror in deps/mirrors/cerberus.git; `upstream` fetch-only remote on cerberus-lean) — three-way-differential instrument + upstream-repro baseline. BUILDS OFFLINE with the fork's switch+lem (recipe + libc.co caveat: notes/2026-08-21_upstream-oracle-build.md); F-D fork-only status independently confirmed on this build |
| `deps/refinedc/` | RefinedC (gitlab.mpi-sws.org/iris/refinedc; Rocq) — theories/{lithium,caesium,typing}: Lithium automation-engine + Caesium C-semantics design donors for the workbench (vendored 2026-08-21; mirror in deps/mirrors; litreview brief: notes/2026-08-21_iris-litreview-brief.md, external survey commissioned) |
| `deps/cn/` | CN repo (rems-project/cn, split out of cerberus) — spec-language + verification-tool reference (vendored 2026-08-20; tests/cn = 213 spec'd programs) |
| ~~`deps/cn-tutorial/`~~ | REMOVED 2026-08-22 ([USER] ruling): the cn-tutorial repo has NO LICENSE — under the Yolo rule (no license = never vendor, never derive) the vendored copy + mirror were deleted and the tutorial-derived differential lane (arc/cn-differential, 100/100 agreement) was REVERTED unmerged. The replacement coverage campaign is CLEAN-ROOM from `deps/cn/tests/cn` (213 spec'd programs, BSD-2 grant-text-verified) by an agent instructed never to inspect tutorial content. If the CN team adds a license later, the tutorial corpus can return. [USER 2026-08-22]: warm-up slate BEFORE the big targets — the T5-landing arc's T6+ slate draws from these (real external code, existing CN specs as statement-shape reference, direct CN-vs-us comparability, the buddy-allocator on-ramp — buddy is CN's flagship). Differential lane over the corpus = post-renumbering item (new lanes want clean numbering; note our fork already filters CN magic-comments in cabs-json — verify in the probe). [USER 2026-08-22] SPEC STYLE for the warm-ups: golean-style HARNESSES (init memory per the CN precondition → call → readback/verdict-encode the postcondition → tear down), keeping statements in the CallHarnessAdequate interpreter-only form — memory pre/post become init/observation CODE, never resource vocabulary; harness IDIOM LIBRARY not bespoke setups (golean = design donor, attributed); the CN-vs-us comparison states the modular-contracts vs closed-program-observation distinction honestly; teardown enables an interpreter-only LEAK-FREEDOM conjunct (final allocation map empty). [USER 2026-08-22, DOCTRINE-GRADE] HARNESSES ARE PROGRAMS: no magic values or conjured machine states — ALL variation enters through channels the semantics defines for programs (arguments, inputs, ND choice points); "choice is just program-level resolution according to the semantics"; EVERY choice a program makes is replayable via THE CHOICE STREAM; every harness must be RUNNABLE under all circumstances (concretely executable, differential-testable, fuzz/replay-able) — "there's no difference between specifications and programs". Consequences: statements quantify over STREAMS (pure data) via a stream-indexed runner (runNDWith, generalizing runND1/--first) with a one-time bridging theorem to the exhaustive runND enumeration; the T4EnvHyp conditioned-machine-state style is RETIRED by this doctrine (warm-up arc replaces it); the pure model appears only inside spec functions (reference-parser precedent); choice streams = the future cmm arc's schedule mechanism (forward design). S0 open subtlety RESOLVED [USER 2026-08-22]: the choice stream enters as a COMPILED CONST ARRAY — mkHarness : Stream → CProgram splices the literal into a fixed template; harness = program family, choice resolved before the program exists, zero runtime magic; rand() rejected; argv channel = S0 probe; ND primitives stay banned for data (reserved for allocator/cmm schedules). Full template (model-∀ headline, readback equality, plant tests, byte-blaster containment note): notes/2026-08-22_harness-statement-template.md. [USER 2026-08-22, clarification]: this is a STATEMENT-LEVEL property ONLY — golean has essentially this design (attribute at S0); internal reasoning is NOT required to have this shape ("we'll need to support all the Iris compositional reasoning craziness, but this is *outside* the TCB — boring executable specs in the front, Iris party in the back"): representation predicates, framing, modular callee contracts etc. live freely in the proof layer and discharge through adequacy into the boring runnable statement. [USER 2026-08-22] THE ESCAPE HATCH IS GOVERNED: some examples may eventually resist parameter/stream quantification and want Iris-ish statement-level specs (separation-logic properties in the statement) — IF that happens it is a CONSCIOUS OPERATOR DECISION, never drift: the case is written up (why the boring form fails, what the SL statement adds to the TCB), priced, and decided per-instance. Enforcement already exists mechanically — the statement-TCB gate bans Iris/RelSem vocabulary in statements, so any such spec FAILS THE BUILD until the gate's allowlist is deliberately amended; an allowlist amendment without a logged operator decision is a finding. The earlier codec sketch re-houses under this: builder/decoder live IN the program — pure inductive model + pure encode ("the choice stream") in the STATEMENT (the uri reference-parser precedent: pure spec functions are legitimate statement material), a FIXED deterministic C builder consuming the stream (structure params enter via the symbolic-memory injection channel; runtime ND never used for data generation — ND stays the semantics' own), and ONE builder-correctness lemma per structure proved via iter_compose invariant families (the builder invariant IS the representation predicate; T5's symbolic-n form makes parametric length reachable, not just bounded-N) + pure decode∘encode=id converting stream-∀ to pure-model-∀. S0 obligation: read golean's structure-parameterization approach, attributed |
| `deps/CN-pKVM-buddy-allocator-case-study/` | CN pKVM buddy-allocator case study (page_alloc.c + CN specs + coq_lemmas) — candidate verification target + statement-shape reference (vendored 2026-08-20) |
| `deps/linux/` | Linux kernel tree (4.9G) — pristine pKVM source at arch/arm64/kvm/hyp/nvhe/ (vendored 2026-08-20). LICENSE NOTE (sweep 2026-08-21): linux + the CN-pKVM case study are GPL-2.0; all other deps swept clean (BSD/MIT/Apache; lem's standard LGPL-exception files); Yolo has NO license — paper-only, never vendor. [USER 2026-08-21] RULING: a GPL'd verification example is SUPPORTED, but likely built in a SEPARATE REPO — the kernel-target arc's charter designs the split (own repo holding the GPL-derived fixtures/pins + harness glue, consumed like a dep; exact mechanics at charter time) |
| `deps/gitconfig` | insteadOf redirects GitHub dep URLs → local paths; active ONLY via `GIT_CONFIG_GLOBAL` (never installed globally) |
| `scripts/env.sh` | source before building: opam switch + git redirects, shell-scoped |
| `scripts/ce` | **the env-trap killer** ([USER 2026-08-22]): `scripts/ce <cmd>` runs any command with env.sh sourced — USE THIS for every make/dune/opam/git-redirect-dependent one-liner instead of remembering to source (fresh shells kept losing the env during pin dances → cryptic lem/dune/git-128 failures, ≥3 incidents). Queued companion tweak (arc-13 fix batch): `capped` becomes self-sourcing so the entire lake/lean class is trap-immune, + a common.sh fail-fast guard naming the fix |
| `scripts/new-worktree.sh` | create build-primed worktrees for parallel work |
| `worktrees/` | parallel working copies (keep them here) |

## Building

```bash
source scripts/env.sh    # opam switch + offline git redirects (this shell only)

# cerberus-lean — OCaml side (switch lives at cerberus-lean/_opam, OCaml 5.4.0)
cd cerberus-lean
opam exec --switch=. -- make prelude-src                     # .lem → OCaml (needs lem)
opam exec --switch=. -- dune build backend/driver/main.exe cerberus-lib.install
opam exec --switch=. -- dune install cerberus-lib

# cerberus-lean — Lean side (Lean 4.29.0)
make lean-prelude-src                                        # .lem → Lean into lean_frontend/generated/
cd lean_frontend && lake build
# NOTE: native/*.o must exist (no Makefile rule yet); rebuild with:
#   <toolchain>/bin/leanc -c -O2 native/<f>.c -o native/<f>.o

# lem-lean
cd lem-lean/lean-lib && lake build                           # LemLib (Lean 4.28.0)
# lem the OCaml tool is opam-pinned from deps/lem-pinned

# prototype (own local switch at cerberus/_opam per its Makefile)
cd cerberus-lean-prototype
make cerberus-setup        # NOTE: needs dune <3.24 in that switch (dune 3.23.1 installed;
                           # its dune-project uses '(using coq 0.8)', removed in dune 3.24)
cd lean && lake build      # Lean 4.26.0 + mathlib (cache already fetched)
```

Tests: `cerberus-lean`: `./scripts/test_unit.sh`, `./scripts/test_parse.sh`,
`./scripts/test_core.sh`. Prototype: `./scripts/test_interp.sh` etc.

## Parallel work via worktrees

```bash
./scripts/new-worktree.sh cerberus-lean my-branch   # or lem-lean
```
Creates `worktrees/<repo>-<branch>` with `.lake` primed (no network needed),
`_opam` symlinked to the main checkout's switch (shared — don't add/remove
opam packages from a worktree), and `_build`/`generated/`/`native/` copied.

cerberus-lean's Lake dep `LemLib` resolves (via `deps/gitconfig`) to the local
`lem-lean` checkout, so commits made in any lem-lean worktree are immediately
fetchable: bump the rev with `lake update LemLib` after pointing the manifest
at the new commit.

## Playbook — branch-and-merge (adopted from golean, 2026-08-18)

Pattern source: `deps/golean/CLAUDE.md` (merge protocol, audit practice,
worktree-per-lane). Adapted here for the two-repo layout. The repo is the
record: decisions go in dated files, never just chat.

- **Arcs.** Work is organized in arcs, each with a charter in
  `cerberus-lean/lean_frontend/docs/YYYY-MM-DD_*.md` (lem-side design notes
  in lem-lean `doc/notes/`). Charters are DRAFT until the user blesses
  them; checkpoints inside an arc are decided by the user on concrete
  objects. Arcs 1+2 merged 2026-08-18; arcs 3 (totality sweep), 4 (exec
  pipeline, 103/106 differential) and 5 (link & libc: 20/20 linking
  FAILs closed, real multi-TU + MD5 digests, libxml2 chvalid 100%
  differential) merged 2026-08-19; arc 6 (libc & speed: uri gate 16/16
  GATING, varargs reg-15 fixed, Fmap/TreeMap perf with kernel-checked
  equivalence, first tests/ci sweep 110/114) merged 2026-08-19 (charters
  + records in `cerberus-lean/lean_frontend/docs/`); spike/relsem branch
  is LIVE arc-7 input (ExecModel + runNDT_sound), merges with arc 7.
  Arc 9 ("the workbench") merged 2026-08-21: the proof-machinery
  arc — OwnP adoption (iris-lean reuse, hand ghost twin retired),
  six lemma kits + 54 in-build exactness pins incl. the AXIOM-FREE
  iter_compose loop rule, the @[app_eq] law table + app_walk walker
  + per-stage certificate emitter (every step an ordinary
  kernel-checked declaration; plant-tested unable to close false
  goals), proof-size + debug-surface gates, iris pinned at head
  34390a0133. Calibration: ~200 mechanical lines → 5 walker lines
  (T1AppEq 1,038→862). T5 PARKED AT EVIDENCE GRADE (St-v2
  kernel-validated at symbolic n, 44/79 rounds, named resumption
  point) — completion = workbench-v2 exit criterion 1, powered by
  the committed survey slate (iris-rules-automation survey + Lithium
  source review, in docs/). GRUMPY-PROFESSOR CAMPAIGN (2026-08-21,
  [USER]): two read-only code-quality audits (lem backend +
  cerberus semantics; standard = "very grumpy PL professor",
  semantic fragility over style) — both graded B−, 73 findings
  (11 GRAVE), registers in notes/2026-08-21_grumpy-audit-*.md =
  arc-13 "the immaculate pass" S0 input (two slices: impl_mem F-row
  closure + backend de-globalization/Ott-grammar/Set-eq/instance-
  priority guard; serialized after arc-12 — baselines). [USER
  2026-08-21]: after arc-13 lands, a SECOND grumpy audit runs — the
  RE-MARK ("the professor calls us back into his study"): fresh
  auditor instances, same standard + the original registers in hand,
  grading the remediation (did we reach A−? what did the fixes
  regress or miss?) — arc-13's success condition, not an optional
  follow-up. Arcs 11+12 MERGED 2026-08-22 (joint serialized ff-only):
  arc 12 "honest oracle" — the F-D fail-stop floor (zero
  silently-wrong oracle verdicts, numbering bit-stable in-margin,
  CERB_FLOOR bucket; attribution corrected: the April desugar
  threading ALONE; grandfathered libc/uri artifacts per ratified
  D2/D4, expiring at renumbering; filing drafts 08/09 ready in
  notes/upstream/); arc 11 "workbench v2" — trace/replay engine
  (~2.6s checked replays, preview provably non-authoritative),
  context-indexed laws + typed residuals, the PACKAGE REHEARSAL
  (relsem = own Lake package + root-side RelSemCore; gates re-homed,
  plant-tested; real-split findings banked); T5 parked 45/79 +
  symbolic route live, flagship theorems pinned + in-sweep, R-S2-1
  = resumption first move. THE workbench-v2 WORKTREE IS PRESERVED
  post-merge (probe scratch = R-S2-1 resumption material — do not
  prune until T5 lands). Arc 13 ("clean numbering") MERGED
  2026-08-22 + two same-day certification hotfixes: R-B full — the
  fork oracle's numbering IS upstream's (byte-identical everywhere,
  libc.core == upstream's own dump under a content-hash pin); F-D
  CLOSED-BY-CONSTRUCTION (single supply; the floor = backstop,
  scoring its first live catch — a stale generated tree);
  grandfather DISSOLVED, 516 corpus rows restored mismatch=0, fuzz
  yield 5x; proof re-pin 30s/zero manual edits; NEW GATES from the
  incident chain: lem-sync content-hash + libc.co
  staging-verification (+ the certification-integrity doctrine
  block above). Arc 14 ("immaculate pass + re-mark") LAUNCHED
  2026-08-22 on the operator's advance blessing. [USER 2026-08-22,
  operator AFK]: standing permission to "roll right into the
  professor audit, and any follow on fixes" — the arc runs
  autonomously through S4 (the re-mark) + its fix-or-record batch +
  merge-checklist prep; THE MERGE ASK ITSELF awaits the operator's
  return (per-merge sign-off remains unconditional). RE-MARK RESULT:
  B+ / B+ (both from B−); [USER 2026-08-22]: "once we get this
  fixed, a re-grade seems reasonable" — S4b RE-GRADE authorized
  after the A−-basket batch (fresh markers, same standard), before
  the merge ask. [USER 2026-08-22, sequencing ruling]: "save any
  remaining issues for later — we're at a fine state… Regrade and
  then work on some more substantive stuff, then fix the smaller
  things later" — the A-road items (the backend L-slice/pure
  render, S13/S15 gap closure, the ott + filing finish) stay
  REGISTERED with their prices; after arc-14's merge the next arc
  is the SUBSTANTIVE track (T5 landing + the CN warm-up slate per
  the banked spec-layer doctrine), polish resumes later. Arc 14
  MERGED 2026-08-22 (operator sign-off; pin dance lem 861ed81 →
  opam → cerberus 195964b44; full post-merge certification green:
  unit 7/7, verify 29/29, exec 106 zero-movement, core ALL, immaculate
  lane at baseline, libc ALL MATCH, uri 16/16; arc/immaculate
  worktrees + branches pruned, workbench-v2 + cn-coverage worktrees
  preserved). S4b re-grade: semantics A−, backend B+ — both accepted
  by the operator for this pass. Arc 15 ("the spec lab") LAUNCHED
  2026-08-22, charter BLESSED (docs/2026-08-22_arc15-spec-lab-
  charter.md; D1 T5 parallel lane, D2 fresh speclab package, D3
  ladder as drafted + the proof-style bonus objective; grounding:
  notes/2026-08-22_harness-statement-template.md): Lane A =
  spec-lab worktree (S0: mkHarness v1, codecs, probes), Lane B =
  T5 resumption (workbench-v2 worktree, branch arc/t5-landing,
  R-S2-1 first move), plus a [USER-approved] third parallel
  stream: the full upstream CI sweep. ALL THREE STREAMS MERGED
  2026-08-23 (operator sign-off; two audits, both MERGE-SAFE;
  audit-1 MAJOR-1 = docs-only criterion-1 overstatement, fixed
  pre-merge with the honest statement-layer/strict-exec split;
  serialized rebase-regate-merge train; full certification green
  incl. the 5 speclab lanes + cn baseline; spec-lab + ci-sweep
  worktrees/branches pruned). Headlines: Lane A COMPLETE — 5
  rungs, ~1,970 differential executions all agreeing, twin
  registers closed, template note revised (4 normative S4-errata
  amendments), amortization measured (2 fresh CN targets in 31.5
  min, zero new idioms), P5 pure-transport = the workhorse,
  exec-equation campaign parked-priced = the binding constraint;
  CI sweep — 2,186 files, 1,316 comparable, ZERO mismatches, 1
  new defect (pr44468 offsetsof unknown-tag panic, S-M); Lane B —
  the historic T5 blocker KILLED (R-S2-1 instance-implicit
  divergence), 13/79, parked at the R13 kernel-depth wall.
  NEXT-ARC DESIGN BANKED: notes/2026-08-23_stepper-arc-design.md
  (laws+seals+residuals+OVERRIDES, SAW/Lithium donors,
  proof-layer-only compositionality, two-stage summaries;
  sequencing seal-through-the-chase → T5 → stepper; the seal
  go/no-go = the open operator decision). workbench-v2 worktree
  PRESERVED (T5 scratch = resumption material; audit W-1: migrate
  the ladder to committed modules at resumption). NORTH STAR [USER 2026-08-22,
  verbatim]: "our purpose in all this work is to build a
  verification tool we can use to verify substantial parts of the
  Linux stack. We're primarily interested in containment and safety
  and large portions of Linux are written in C. This pushes us
  towards a very 'boring' spec style, because we simply can't read
  specs at scale and understand them if they are fancy, and it push
  us towards the most aggressive proof automation that has ever
  been implemented in a theorem prover. We want to verify vast and
  unprecedented things." This is the load-bearing rationale for the
  boring-specs-in-front doctrine, the automation investment
  (workbench/trace-replay/context laws), and the kernel-adjacent
  target slate (pKVM buddy, WireGuard are the point, not demos);
  prioritize what scales to vast C codebases. [USER
  2026-08-21] ARC-ORDERING RULING (executed): the RENUMBERING arc (oracle
  symbol-id rebase + full fixture re-pin; case/design/inventory in
  the arc-12 renumbering-case doc; dissolves grandfather register
  G1-G4, restores the 516 floored corpus rows + fuzzing yield,
  prerequisite for wireguard/buddy/full-CI-sweep) is
  PARKED-FOR-IMMEDIATE execution: it starts as soon as arc-11
  closes (it needs the fixture surface) and arc-12 is merged (the
  floor remains as its backstop); workbench-v2's trace/replay is
  what makes the re-pin cascade affordable. The "immaculate pass"
  + its grumpy RE-MARK slide one slot behind it (they contend for
  the baseline surface anyway). Arc 10 ("robustness") merged 2026-08-21:
  finding 11 closed (ci 114/114 comparable, 0 mismatches), 1134
  comparison-sorries → 0 (derived structural comparisons, OCaml
  parity audited), float/bytes/csmith-corpus lanes wired gating,
  csmith campaign (3169 programs, 0 Lean-side semantic defects,
  finding 8 fixed), THE F-D REATTRIBUTION (the fork's oracle carries
  a declaration-layout-sensitive corruption family — fork regression,
  NOT upstream: April desugar fresh_sym_supply threading [primary] +
  arc-2 core_run threading; repair = TOP next-arc candidate, priced
  M; see the drift review + campaign record §root-cause), and the
  FORK-DRIFT GATE (52-file oracle-surface manifest + 20 hash-pinned
  generated diffs vs deps/cerberus-upstream, Tier A). Queued:
  stack-ceiling guard, concurrency arc (cmm survey +
  executable-equivalent direction + parametricity principle banked
  in notes/ + spike docs; model-quantified "∀ M ≥ weak floor"
  theorems as the headline shape — wireguard scoping note), WireGuard
  ladder (notes/2026-08-20_wireguard-target-scoping.md) + pKVM buddy
  allocator (deps/) as next targets, upstream filing (F-A/F-B ready
  un-forked in the tray), FULL upstream CI sweep ([USER 2026-08-20]:
  the cerberus repo carries a big heterogeneous CI collection — ~6,000
  .c files under cerberus-lean/tests/ (gcc-torture 2858, ci 250,
  cheri-ci 247, suite 144, tcc 70, pnvi_testsuite 44, hacl-star,
  bytes, freebsd; driver: tests/run-ci.sh) — messy but useful; a
  complete differential run over it is queued (~30 min on a laptop
  OCaml-only, expect much more differentially; run capped, per-test
  timeouts both sides, scoreboard-style classification not gating —
  our exec differentials cover only tests/ci's 128-file subset +
  coverage today; full survey + priced migration slate:
  notes/2026-08-20_prototype-test-migration-survey.md — headline: the
  gcc-torture "success" lane (923 files, breakdown/ as exclude-list)
  is the sweep's spine; tests/float (69 files) sits DEAD in our tree
  (copied arc-4, never wired — small fix); tests/bytes (14 files,
  committed expecteds) never run by anyone). Arc 7 (the bridge) merged 2026-08-20:
  FIRST THEOREMS — T1-T4 ∀-quantified interpreter-only kernel-checked
  statements about compiled C functions via Iris WP + in-repo adequacy
  (toolchain now 4.32.2; iris-lean a pinned Lake dep; CerbND+CerbMem
  totalized; statement-TCB + in-build axiom audits enforcing). Arc 8
  (the consistent boundary) merged 2026-08-20: DAEMON ELIMINATED —
  the inconsistent axiom family + legacy failwith DELETED from LemLib;
  lem backend now DERIVES real bounded Inhabited instances
  (per-constructor, fail-closed: underivable = loud generation-time
  error) and threads [Inhabited tv] binders via a call-graph fixpoint
  (failwithI everywhere); T1-T4 cones now exactly [propext,
  runEffectful, Classical.choice, Quot.sound] — UNCONDITIONAL kernel
  certificates, the arc-7 qualifier is GONE. Absence enforcement:
  in-build Audit gate (closure) + tree-wide NAME-INDEPENDENT generated
  axiom census + unsafeCast ban (plant-tested). April-2026
  archaeology + S0 cerberus-scale probe doctrine (lem-suite green is
  never evidence) in the arc-8 records
  (lembugs/2026-08-20_daemon-inconsistent-axiom.md RESOLVED).
- **Branches + worktrees.** All work on arc branches in worktrees
  (`./scripts/new-worktree.sh <repo> <branch>`); primary checkouts stay
  parked on the mainlines (`mdd/cerberus-lean`, `mdd/lean-backend`).
- **Two-repo pin dance.** Branch pair with the same name in both repos.
  During an arc, cerberus-lean's Lake manifest + `deps/lem-pinned` may
  track lem arc-branch commits. Merge order at arc end: lem-lean first
  (`git merge --ff-only` into `mdd/lean-backend`), then re-pin cerberus to
  the MERGED lem commit, re-run the gate, then cerberus merges ff-only.
  An arc is closed only when branch heads = opam pin = Lake pin.
- **The validation gate** (green before any checkpoint claim, audit, or
  merge): lem-lean `make` + `tests/comprehensive: make lean`; cerberus
  `make lean-build`, `test_unit.sh` 4/4, `test_parse.sh` ALL,
  `test_core.sh` at 106/106 (the 078 red was FIXED in arc 6 — any
  test_core red is a regression). No new sorry/axioms outside the
  declared boundary list. A green build is not evidence of correctness;
  the differential baselines are the signal.
- **Pre-merge audit: the ASK is unconditional.** Before any merge, propose
  audit scope + scale to the user; they may waive or trim, but the ask is
  never skipped. No green gate or urgency substitutes.
- **Merges are ff-only, exactly** — rebase if the mainline moved, re-gate,
  re-ask. No merge commits, no `git branch -f`, no pointer surgery.
  `git push` is a separate, operator-gated action (needs network anyway).
- **Orchestrator/worker execution (doctrine, 2026-08-19).** Arcs run as
  SEQUENCED SUBAGENT WORKERS with the main agent as orchestrator (the
  arc-3 pattern, now standing). The orchestrator's job is SCOPING and
  VERIFYING, not doing: it owns charters, the decision log, exact worker
  scoping (files in scope, mechanisms, sentinel/witness rules, validation
  commands with exit-code discipline, a park-don't-improvise rule),
  independent gate verification at batch boundaries (worker-claimed green
  is never accepted — re-run), audits, and pin dances. WORKERS COMMIT
  their own work — recipe requirement: commit only on green gates, one
  coherent commit per batch/slice, message states what was verified.
  QUOTED OUTPUTS ARE VERBATIM (2026-08-19, arc-6 audit): anything
  presented as tool/harness output in a record must be the literal
  output; derived or corrected tallies are fine but must be LABELED as
  derived, never formatted as a quote. A doctored transcript — even one
  whose numbers are right — is a record-integrity finding.
  MERGE LIVES WITH THE USER: the orchestrator prepares the merge
  checklist and executes ff-only merges only on explicit per-merge
  sign-off; the ask is unconditional. Model per worker is an orchestrator
  call (Fable for delicate backend/audit work, Opus for mechanical
  batches).
- **Parallel streams** (multiple arcs at once) are allowed on disjoint
  worktree pairs, one stream per arc branch. Constraints: (1) write
  surfaces must be disjoint — never two streams editing the same .lem/
  backend region; (2) the opam-installed lem is SWITCH-GLOBAL — streams
  needing different lem versions use the per-worktree checkout lem
  (PATH-prepend + LEMLIB, see Known issues) and only the closing arc
  re-syncs the opam pin; (3) merges serialize — ff-only means the second
  stream rebases on the moved mainline, re-gates, re-asks; (4) workers
  within a stream stay sequenced (shared worktree state).
  toolchain-sensitive; a bump is an explicit arc-level decision).
- **Mirror-OCaml doctrine (2026-08-19).** Gratuitous Lean↔OCaml logic
  divergence in hand-written seam files is a DEFECT AS SUCH — no
  observable differential failure is required for it to count. Every
  divergence must be either (a) eliminated by mirroring the OCaml code
  (with OCaml file:line citations in a comment), or (b) explicitly
  documented in-code as deliberate, with rationale (the backends differ
  in purpose — proof-friendliness, no hidden IO — so justified
  divergence exists, but it is always documented). Undocumented
  divergence = defect. The seam-survey register
  (cerberus-lean `lean_frontend/docs/2026-08-19_arc4-seam-survey.md`)
  tracks the known set; differential failures raise a defect's priority,
  never define it. Audits check citations against the cited code.
- **No-internal-trust-gaps doctrine (2026-08-19).** No trust gap between
  in-Lean artifacts is permitted unless truly forced by an IMMOVABLE
  OBJECT. If two Lean artifacts must agree, that agreement is a THEOREM,
  not a test; if an artifact is opaque to the kernel (partial def, axiom,
  implemented_by), it is either eliminated (fuel-totalize — the arc-3
  pattern, extended to hand-written code per the runND resolution) or it
  sits on the DECLARED BOUNDARY LIST with an explicit immovable-object
  justification. Immovable objects are: the OCaml oracle (differential
  testing is the only tool — it cannot be reasoned about), native C
  externs (the kernel cannot see C; implemented_by trust is forced,
  minimized, and census-pinned), and the Lean kernel/compiler itself.
  Boundary entries are classified PERMANENT (the above) or TEMPORAL
  (2026-08-19 refinement, operator: "some of these objects will
  eventually be moved — e.g. we should design so we can eventually
  support concurrency"). TEMPORAL entries — concurrency/cmm stubs,
  DAEMON instance fallbacks (C-tier lem fix planned), upstream-bug
  mirrors (float sizes, 097), the pp placeholders — carry TWO
  obligations: (1) an expected mover (which future work removes them);
  (2) a FORWARD-DESIGN constraint — nothing built today may make the
  eventual move harder (e.g. Layer-2/3 shapes must not bake in
  single-thread or SC-memory assumptions the cmm instantiation would
  have to unwind). Everything else is a defect: internal differential
  testing is at most a TRANSIENT migration check, never a permanent
  epistemic state. The axiom census, the totality/purity gates, and the
  declared-boundary list in the results docs are this doctrine's
  enforcement surface; boundary-list entries without justification —
  or temporal entries without a mover — are findings.
  **DAEMON HONESTY — RESOLVED (arc-8, 2026-08-20):** lem's
  `axiom DAEMON : ∀ {α : Type}, α` was, AS DECLARED, logically
  INCONSISTENT (`(DAEMON : Empty)` proved `False`, kernel-verified;
  arc-7 audit-1 F1) — theorem cones carrying it were kernel-checked
  only modulo an unreachable-marker meta-assumption. Arc 8 DELETED the
  axiom family (backend-derived real Inhabited instances + failwithI
  threading; no opaque inhabitant of any kind can be emitted — the
  fail-closed path is a generation-time error). The temporal-mover
  obligation was EXECUTED. Standing enforcement: in-build absence gate
  (Audit.lean, import closure + exact cone pins) + tree-wide
  name-independent generated-axiom census & unsafeCast ban
  (check_theorem_axioms.sh, plant-tested). The lesson stands as
  doctrine: no axiom over all `Type` can be a consistent inhabitant
  marker; loud generation-time failure beats any opaque fallback.
  **Non-kernel proof methods are BANNED outright (operator, 2026-08-19):**
  `native_decide`, `bv_decide`, and anything else whose proofs carry
  `Lean.ofReduceBool`/`ofReduceNat` (compiler-trusted evaluation) — plus
  the lesson that `#guard` is UNTRUSTED-evaluator checking and must never
  be described as kernel-checked (it remains fine AS A TEST, labeled as
  such). Enforcement follows golean's mechanism (deps/golean
  proofs/Audit.lean): assert exact transitive axiom sets — allowlist =
  the classical trio {propext, Classical.choice, Quot.sound} for proof
  modules, plus declared-boundary axioms only where declared —
  build-failing. Cerberus-side: ofReduceBool/ofReduceNat are
  always-fatal in every probed cone (axiom gate), tactic names
  grep-banned in hand-written proof files; the golean in-build
  Audit.lean pattern is the adoption target for RelSem/proof libs.
- **Never run a Lean build uncapped (2026-08-20, from golean after an
  OOM session kill).** Every `lake`/`lean` invocation goes through
  `cerberus-lean/scripts/capped` (cgroup MemoryMax 64G default,
  CERB_MEM_MAX override, `=none` loud opt-out). `lean -M` and
  `prlimit --as` do NOT work (golean-measured). Companion habits:
  #eval the Bool before asking the kernel to prove it; whole-driver-run
  rfl/decide is banned as a proof method (compositional equation chains
  instead).
  **Two-part-design intention (operator, 2026-08-21):** the INTENDED
  end-state is a repo split — "cerberus-lean the semantics" (generated
  port + hand seams + differential substrate) vs "cerberus-lean the
  verification layer" (relsem: workbench + theorems, pinning the
  semantics like a dep), with per-target example repos (incl. GPL'd
  ones) as a third layer. Standing FORWARD-DESIGN CONSTRAINT from now:
  avoid building ANY gratuitous coupling across that seam — the
  semantics→verification dependency stays strictly one-way (nothing
  under the semantics surface may import/reference relsem; already
  gate-enforced), the interface the verification layer consumes
  (generated modules, wrapper-defeqs, FuelHooks, CerbND) stays
  enumerable, and in-build gates that ride the semantics build must
  remain re-homeable. Anything that would make the eventual split
  harder is a defect of the TEMPORAL-entry class (register + mover).
  Audits check new cross-seam references. Sequencing + rationale:
  ROADMAP (rehearse in workbench-v2 as an in-repo Lake package; cut
  when the interface stabilizes).
  **Proof-scaling philosophy (operator, 2026-08-21):** "keep trust
  surfaces very clean, but we're happy to do whatever clever tricks
  make the proof scale *for kernel-certified steps*. No insane hacks
  for specifications. Aggressive optimization outside the TCB (but
  keep it clean of course, no need to be messy)." Reading: statements
  and the TCB are pristine — no statement-side cleverness ever; the
  proof MACHINERY (walkers, emitters, discovery engines, obligation
  scheduling) may be engineered aggressively so long as every step
  lands as an ordinary kernel-certified obligation and the meta-code
  stays reviewable library code with contracts. This refines, never
  relaxes, the non-kernel-proof-method ban below.
  **Certification-integrity rules (2026-08-22, from the arc-13
  merge incident chain — three layered illusions each converted to a
  gate):** (1) validation of BUILD-RULE-AFFECTING changes must be
  CACHE-DISABLED (DUNE_CACHE=disabled + --force) from a checkout
  with RE-DERIVED, not inherited, generated trees (the lem-sync
  content-hash gate now enforces generated-OCaml freshness
  build-fatally; dune's cache + worktree priming masked a stale
  F-D-era tree through a whole arc); (2) audit PLANT recipes mandate
  REBUILD-AFTER-REVERT before any further measurement, and audit
  pairs sharing a worktree sequence binary-affecting plants (a
  leftover plant binary nearly manufactured a false MAJOR);
  (3) VERIFIED-vs-LOADED artifact gaps are findings — checks must
  assert the artifact the consumer actually loads (the libc.co
  staging gate is the pattern); never 2>/dev/null an install/build
  step (a swallowed dune-install failure enabled the whole third
  incident).
  **Heartbeat hacking is a bad smell (operator doctrine, 2026-08-20):**
  raising maxHeartbeats/maxRecDepth (or any elaborator budget) typically
  means brute-forcing something that should be done more intelligently —
  the fix is compositional/clever structure that SCALES, not a bigger
  budget. Budget increases are allowed ONLY as explicitly temporary
  measures and are BY DEFINITION defects: each one is a register entry
  with an expected remover, and it may become permanent only after
  investigation AND explicit operator agreement that it is unavoidable.
  Audits grep for set_option maxHeartbeats/maxRecDepth in proof files;
  an un-registered bump is a finding.
- Machine-global state remains forbidden (top of this file); opam
  switch-level ops work in-session, config-level ops are operator-run.

## Offline / sandbox notes

Designed to work with no network: toolchains preinstalled (elan 4.26/4.28/4.29),
opam packages installed, Lake deps cloned + mirrored locally, mathlib olean
cache and cvc5 binary already downloaded. Refresh mirrors (network required):
`for m in deps/mirrors/*.git; do GIT_CONFIG_GLOBAL=/dev/null git -C $m fetch; done`

## Known issues (as of 2026-08-18, post Phase 0 re-sync)

- lem-lean / cerberus-lean pins: lem-lean `mdd/lean-backend` @ `861ed81`
  (arc 14 merged 2026-08-22: backend immaculate slice — St
  de-globalization, reserved-name body-scan, ott grammar productions;
  arc 10 @ 11d4b4c: derived structural comparisons + Sum BEq/Ord +
  Type-1 fail-closed; arc 8 @ 237867b: derived Inhabited + failwithI
  threading + DAEMON deletion; earlier: arcs 1+2 effectful/fuel
  declares, arc 3 totality, arc 6 Fmap/TreeMap). cerberus-lean
  `mdd/cerberus-lean` @ `39aabec47` (arc-15 three-stream merge
  2026-08-23: speclab package + 5 rungs, ci-sweep scoreboards, T5
  13/79 + engine; earlier `db7c82f49`: cn-coverage lane merged
  2026-08-22: 213/213 CN-corpus differential + CoreParser scan_ub
  mirror fix + audit A-1 doc). opam pin (`deps/lem-pinned`,
  branch `cerberus-pin`) and the Lake manifest both point at
  `861ed81` (arc-14 close pin dance, 2026-08-22; lem untouched by
  the cn-coverage merge).
  Gates in `./scripts/test_unit.sh` (all enforcing): exec-slice purity +
  theorem-axiom cones (driver2 sorryAx-free AND DAEMON-free — arc-8 S3
  bar) + exec-slice TOTALITY (empty allowlist; 60 kernel proofs incl.
  52 wrapper-defeqs) + hand-written↔generated SYNC (arc 4; 21 files) +
  hand-written-axiom census (exactly 2: with_tagDefs, forceIO — arc 5)
  + tree-wide generated axiom census & unsafeCast ban (arc-8,
  name-independent, plant-tested). Differential gates:
  `test_exec.sh` 103/106 tests/minimal vs OCaml (baseline
  regression-gated), coverage 183/199 comparable, `test_multi_tu.sh`,
  `test_libc_exec.sh` (C-with-libc mode), `test_libxml2.sh` (chvalid
  100%, 4 slices/1354 pts ~8 min, Tier B), `test_libxml2_uri.sh`
  (16/16 GATING), `test_elab.sh` (reporting), tests/ci scoreboard
  110/114 + debug scoreboard + csmith kit. Ladder tiers are normative:
  `cerberus-lean/scripts/LADDER.md`. NOTE: test_core is 106/106 — the
  078-float-special red is FIXED (arc-6 S1); any test_core red is now a
  regression. D14 ban (native_decide/bv_decide/ofReduce*) enforced in
  the axiom gate. GOTCHA: after
  any `native/*.c` change run `make lean-native-obj` — stale .o now
  FAIL-STOP via the fresh-counter floor assertion (hit at the arc-4
  merge itself). Records:
  `cerberus-lean/lean_frontend/docs/2026-08-18_effects-totality-design.md`
  and `.../2026-08-18_arc3-totality-sweep-{charter,results}.md` +
  decision log D1–D11.
- **Effectful/extern gotchas** (for future work): BaseIO externs follow the
  Lean ≥4.29 world-erased convention (no RealWorld arg, raw return); Lake
  does not track `native/*.o` as link inputs (use `make lean-native-obj`);
  instance fields can't carry attributes, so effectful calls inside
  instance methods are only protected one level down.
- `test_core.sh`: 104/105 — `078-float-special` hits a Core text parser gap
  ("expected 'builtin', got 'proc'").
- Desugar stage incomplete (see `cerberus-lean/lean_frontend/CLAUDE.md`).
- Prototype `test_interp.sh`: 100% match on `tests/minimal`; 13 failures on the
  harder upstream `cerberus/tests/ci` suite (WIP coverage gaps).
- Offline caveats: `opam install` of NEW packages and `lake update` of the
  scoped `batteries` require (Reservoir API) need network; everything already
  installed/cloned works offline. Manifest-driven `lake build` is fully offline.
- opam in the sandbox (nono profile claude-local ≥1.7.0, 2026-08-18): install/
  reinstall/upgrade/pin of LOCAL-source packages (e.g. the lem pin) work
  in-session — opam's log/locks/download-cache are writable; `~/.opam/config`
  is read-only by design, so switch create/remove and default-switch changes
  are operator-run. opam's inner bwrap sandbox is disabled machine-wide
  (wrap-*-commands = []) because bwrap cannot nest inside Landlock; nono
  provides the outer sandbox. Update lem after a lem-lean commit with:
  `git -C deps/lem-pinned reset --hard <commit>` then, from
  `cerberus-lean/`: `opam upgrade --switch=. --no-depexts lem`
  (`--switch=cerberus-lean` fails — it is a LOCAL switch, use the path
  form; `--no-depexts` needed because opam's system-package detection
  fails in-sandbox — verified at the arc-8 merge, 2026-08-20).
