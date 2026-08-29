# 2026-08-31 — container operating-manual archive (the pre-hygiene CLAUDE.md)

**What this is.** The container folder's `CLAUDE.md` (the local set's
operating manual, ~89KB at archive time), preserved verbatim at the
CLAUDE.md-hygiene slice that followed the semantics-first separation
([USER 2026-08-31]: "CLAUDE.md shouldn't be a log of all decisions —
we want it to be a clean working practices doc. And we want to avoid
notes in the overall container (which isn't a repo, and is local
only)."). The container CLAUDE.md was rewritten as a working-practices
document; its entire historical content — the arc histories, the
reasoning-era ACTIVE STATE block, and the verbatim operator rulings —
moved here wholesale. The reasoning-era rulings in the body below are
HISTORICAL here: they live operatively on the park branch
(`arc/segment-ladder`, tag `park/reasoning-era-20260831`) and in
`POSTMORTEM-AND-FORWARD-BRIEF.md`; the successor verification effort
(refined-cerberus) carries its own rulings register.

## Rulings that remain operative for semantics work (extracted)

Full verbatim text for each is in the archived body below (and the
container CLAUDE.md carries them as practices).

- **No machine-global state** — never modify ~/.gitconfig, the opam
  default switch, shell profiles, or shared caches; all mechanisms
  directory- or environment-scoped; any proposed exception needs
  explicit at-the-moment operator approval.
- **The grind ban + tripwire** [USER 2026-08-24/25] — no stupid grind
  campaigns; a build/proof pass approaching ~1hr is a stop-and-report
  event; >1hr needs written extraordinary justification in advance
  (measurement sweeps over differential corpora may qualify). The
  banned PATTERN: bulk kernel checks / brute-force elaboration in
  place of structure; long builds of real content are fine.
- **Canon-first + classical naming** [USER 2026-08-24/28] — reach for
  the field's established mechanisms before novel tricks; every
  mechanism named in classic PL terms before adoption; house jargon
  for mechanisms is banned.
- **Non-kernel proof methods banned** [operator 2026-08-19] —
  `native_decide`, `bv_decide`, anything carrying `Lean.ofReduce*`;
  `#guard` is a test, never "kernel-checked". Gate-enforced in the
  semantics repo (axiom censuses + cones + the D14 scan).
- **Certification integrity** (2026-08-22) — build-rule-affecting
  validation runs cache-disabled from re-derived trees; audit plants
  mandate rebuild-after-revert; verified-vs-loaded artifact gaps are
  findings; never 2>/dev/null an install/build step.
- **Anti-gate-grind calibration** [USER 2026-08-27] — gates are
  reserved for load-bearing TRUST properties (cones, fork-drift,
  statement TCB); discipline points get documentation notes and
  structurally-forcing examples, not per-concern gate proliferation.
- **Mirror-OCaml doctrine** (2026-08-19) — gratuitous Lean↔OCaml
  divergence in hand-written seams is a defect as such: mirror with
  file:line cites, or document the divergence as deliberate in-code.
- **No-internal-trust-gaps** (2026-08-19) — agreement between Lean
  artifacts is a theorem, not a test; kernel-opaque artifacts are
  eliminated or sit on the declared boundary list (permanent or
  temporal-with-mover).
- **Heartbeat hacking is a bad smell** (2026-08-20) — maxHeartbeats /
  maxRecDepth bumps are by definition defects: register + expected
  remover; permanent only after investigation and operator agreement.
- **Capped builds + box discipline** (2026-08-20/26) — every
  lake/lean invocation through `scripts/capped`; one heavy worker at
  a time; suspect box OOM on unexplained session death; commit
  promptly (kill-loss containment).
- **Record integrity** — quoted outputs are verbatim; derived tallies
  labeled; [AGENT]/[USER] provenance on decisions; a committed park
  record ends the slice.
- **The honest-gaps principle** [USER 2026-08-27] — "we want to leave
  real gaps as real, not leave them looking valid when they're not."

---

## The archived manual, verbatim (container CLAUDE.md as of 2026-08-31)

````````markdown
# cerberus-lean-proj

**THE SEPARATION [USER 2026-08-31, supersedes the reasoning-era
active state below]**: "a clean separation of the reasoning work
(completely failed in my view) and the cerberus-lean semantics (a
smashing success)." THE REASONING EFFORT IS PARKED — branch
`arc/segment-ladder`, tag `park/reasoning-era-20260831`, carrying
the complete decision record (all 38 design docs/reviews committed
at 39f3a64a4) — never merged, preserved for any future attempt. THE
PRODUCT is the SEMANTICS: branch `core/semantics-first` (from the
park head, so the totalization and all semantics improvements are
kept) is being stripped of the reasoning layer and re-presented as
the clean, differentially-validated executable Core semantics
(split worker in flight; then audit → [USER] merge sign-off →
mainline). Ratified kills executed 2026-08-31: prototype build
artifacts (8.5G), spike/lem/workbench worktrees removed (branches
tagged where content-bearing: park/effect-spike-content-landed,
park/spike-relsem-20260819; arc/t5-seal branch preserved per its
standing ruling), 8 ancient merged arc branches deleted,
reasoning-era scratch dirs deleted, container-notes duplicates
deleted (all preserved on the park branch). Surviving branches:
the park, t5-seal, core/semantics-first, mainline, 3 upstream-PR
(network-window tray). PENDING [USER]: the prototype checkout's
final form (rec: bare-mirror into deps/mirrors, delete the 1.2G
checkout). POST-MERGE S SLICE, [USER 2026-08-31, the
refined-cerberus practice adopted for the local set]: "CLAUDE.md
shouldn't be a log of all decisions — we want it to be a clean
working practices doc. And we want to avoid notes in the overall
container (which isn't a repo, and is local only)." The slice:
(1) EVERY CLAUDE.md in the local set pruned to a clean
working-practices document — decision history and rulings move to
COMMITTED repo docs (the rulings-ledger shape from restructuring
proposal 7.5), state becomes pointers; this file's giant
reasoning-era block below is HISTORICAL and goes to a committed
record wholesale; (2) NO CONTAINER NOTES going forward — working
documents are born in repo docs and committed (the surviving
container notes/ content — the postmortem, the forward
assessment, upstream/ tray — gets committed to the appropriate
repo and the container notes/ dir retires); (3) the scratch/logs
convention stays container-side but ephemeral-only
(slice-deleted). Executes immediately after the merge lands.

Container folder (not itself a git repo) for the Cerberus→Lean project.
Everything needed to build lives inside this folder plus `~/.elan` toolchains.
**Do not modify machine-global state** (~/.gitconfig, opam default switch,
shell profiles, shared caches) — this machine runs several agents. All
project mechanisms here are directory- or environment-scoped.

NORTH STAR [USER 2026-08-22, verbatim]: "our purpose in all this work is
to build a verification tool we can use to verify substantial parts of
the Linux stack. We're primarily interested in containment and safety
and large portions of Linux are written in C. This pushes us towards a
very 'boring' spec style, because we simply can't read specs at scale
and understand them if they are fancy, and it push us towards the most
aggressive proof automation that has ever been implemented in a theorem
prover. We want to verify vast and unprecedented things." This is the
load-bearing rationale for boring-specs-in-front, the automation
investment, and the kernel-adjacent target slate (pKVM buddy, WireGuard
are the point, not demos); prioritize what scales to vast C codebases.

This file is the OPERATING MANUAL. History lives in dated docs:
arc charters/results in `cerberus-lean/lean_frontend/docs/`, design
notes in `notes/`, the arc index in `ROADMAP.md`. (Pre-prune archive of
this file: notes/2026-08-23_claude-md-pre-prune-archive.md.)

## Layout

| Path | What |
|------|------|
| `cerberus-lean/` | Main repo, branch `mdd/cerberus-lean` (C semantics + `lean_frontend/` Lean port generated from .lem via lem; `relsem/` proof package; `speclab/` spec-lab package) |
| `lem-lean/` | Lem fork, branch `mdd/lean-backend` (Lean backend + `lean-lib/` LemLib runtime) |
| `cerberus-lean-prototype/` | ARCHIVED 2026-08-27 ([USER] kill-quick ruling): earlier Core-JSON interpreter prototype — superseded by the main pipeline; no maintenance; reduce-to-oracle option closed |
| `deps/lem-pinned/` | git worktree of lem-lean (branch `cerberus-pin`) — the lem version cerberus-lean builds with (see Known issues for the pin) |
| `deps/mirrors/` | bare mirrors of all Lake/git dependencies (offline insurance; linux deliberately unmirrored — its checkout .git is the copy) |
| `deps/cerberus-upstream/` | un-forked upstream cerberus @ b9aeedcb4 (fork's merge-base; `upstream` fetch-only remote on cerberus-lean) — three-way-differential instrument + upstream-repro baseline; builds offline (recipe: notes/2026-08-21_upstream-oracle-build.md) |
| `deps/refinedc/` | RefinedC (Rocq) — Lithium automation engine + Caesium C semantics, design donors (litreview brief: notes/2026-08-21_iris-litreview-brief.md) |
| `deps/cn/` | CN repo (rems-project/cn, BSD-2) — spec-language + verification-tool reference; `tests/cn` = the 213-program corpus behind the cn_coverage lane and the spec-lab targets |
| ~~`deps/cn-tutorial/`~~ | REMOVED 2026-08-22 ([USER] ruling): no license → never vendor, never derive (the Yolo rule). All CN-corpus work is CLEAN-ROOM from `deps/cn/tests/cn`; if CN adds a license the tutorial corpus can return |
| `deps/CN-pKVM-buddy-allocator-case-study/` | CN pKVM buddy-allocator case study — candidate verification target + statement-shape reference (GPL-2.0) |
| `deps/linux/` | Linux kernel tree (4.9G) — pristine pKVM source at arch/arm64/kvm/hyp/nvhe/ (GPL-2.0). [USER 2026-08-21]: GPL'd verification examples are SUPPORTED but likely live in a SEPARATE REPO (kernel-target arc charters the split) |
| `deps/gitconfig` | insteadOf redirects GitHub dep URLs → local paths; active ONLY via `GIT_CONFIG_GLOBAL` (never installed globally) |
| `scripts/env.sh` | source before building: opam switch + git redirects, shell-scoped |
| `scripts/ce` | the env-trap killer: `scripts/ce <cmd>` runs any command with env.sh sourced — USE THIS for every make/dune/opam/git-redirect-dependent one-liner |
| `scripts/new-worktree.sh` | create build-primed worktrees for parallel work |
| `worktrees/` | parallel working copies (keep them here). PRESERVED: `cerberus-lean-arc/workbench-v2` (T5 resumption scratch — do not prune until T5 lands and the ladder migrates to committed modules) |

SPEC DOCTRINE (ratified 2026-08-22/23, full text + amendments in
`notes/2026-08-22_harness-statement-template.md`): HARNESSES ARE
PROGRAMS — specs are runnable C harnesses; all variation enters as a
COMPILED CONST choice-stream array (mkHarness : Stream → CProgram;
program family, zero runtime magic; rand()/ND-for-data rejected);
model-∀ headlines over first-order inductive models with stream lemmas
underneath (both codec laws); readback via observation channels
(Form 1 expected-array + mismatch-index default; statements never
mention memory); plant tests mandatory (vacuity must be loud); the
leak conjunct as an outcome observable. STATEMENT-LEVEL ONLY — "boring
executable specs in the front, Iris party in the back": proof-layer
reasoning is unrestricted (rep predicates, framing, callee contracts)
and discharges through adequacy. THE ESCAPE HATCH IS GOVERNED:
statement-level SL specs require a written-up, priced, per-instance
OPERATOR DECISION (the statement-TCB gate makes drift build-fatal).
Next-arc design (compositional stepper: laws+seals+residuals+
OVERRIDES): notes/2026-08-23_stepper-arc-design.md.

## Building

```bash
source scripts/env.sh    # or prefix everything with scripts/ce

# cerberus-lean — OCaml side (switch at cerberus-lean/_opam, OCaml 5.4.0)
cd cerberus-lean
opam exec --switch=. -- make prelude-src                     # .lem → OCaml (needs lem)
opam exec --switch=. -- dune build backend/driver/main.exe cerberus-lib.install
opam exec --switch=. -- dune install cerberus-lib
opam exec --switch=. -- dune build cerberus.install          # REQUIRED for libc-mode lanes (stages libc.co)

# cerberus-lean — Lean side (Lean 4.32.2)
make lean-prelude-src              # .lem → Lean into lean_frontend/generated/
make lean-native-obj               # after any native/*.c change (stale .o fail-stops)
cd lean_frontend && ../scripts/capped lake build             # NEVER uncapped
cd relsem && ../../scripts/capped lake build                 # proof package (in-build gates)
cd ../speclab && ../../scripts/capped lake build             # spec-lab package

# lem-lean
cd lem-lean/lean-lib && lake build                           # LemLib (Lean 4.28.0)
# lem the OCaml tool is opam-pinned from deps/lem-pinned

# prototype (own local switch at cerberus/_opam per its Makefile)
cd cerberus-lean-prototype
make cerberus-setup        # needs dune <3.24 in that switch (3.23.1 installed)
cd lean && lake build      # Lean 4.26.0 + mathlib (cache already fetched)
```

Tests: see `cerberus-lean/scripts/LADDER.md` (normative tiers) and the
gate list under Known issues. Prototype: `./scripts/test_interp.sh`.

## Parallel work via worktrees

```bash
./scripts/new-worktree.sh cerberus-lean my-branch   # or lem-lean
```
Creates `worktrees/<repo>-<branch>` with `.lake` primed (no network
needed), `_opam` symlinked to the main checkout's switch (shared —
don't add/remove opam packages from a worktree), `_build`/`generated/`/
`native/` copied, and the lem-sync stamp carried.

cerberus-lean's Lake dep `LemLib` resolves (via `deps/gitconfig`) to the
local `lem-lean` checkout, so commits in any lem-lean worktree are
immediately fetchable: bump the rev with `lake update LemLib` after
pointing the manifest at the new commit.

## Playbook — branch-and-merge (adopted from golean, 2026-08-18)

Pattern source: `deps/golean/CLAUDE.md`. The repo is the record:
decisions go in dated files, never just chat.

- **Arcs.** Work runs in arcs, each with a charter in
  `cerberus-lean/lean_frontend/docs/YYYY-MM-DD_*.md` (lem-side notes in
  lem-lean `doc/notes/`). Charters are DRAFT until the user blesses
  them; checkpoints inside an arc are decided by the user on concrete
  objects. ARC HISTORY (one line each; details in each arc's results
  doc + ROADMAP.md):
  - 1+2 (2026-08-18) effects/exec-honesty; 3 totality sweep; 4 exec
    pipeline; 5 link & libc; 6 libc & speed + uri gate (all 08-19).
  - 7 (08-20) the bridge: first theorems T1-T4 via Iris WP + adequacy.
  - 8 (08-20) DAEMON eliminated — unconditional kernel certificates.
  - 9 (08-21) the workbench: kits, @[app_eq] law table, app_walk +
    certificate emitter; T5 parked at evidence grade.
  - 10 (08-21) robustness: derived comparisons, csmith campaign, the
    F-D reattribution (fork regression), fork-drift gate.
  - 11 (08-22) workbench v2: trace/replay, context laws, the relsem
    package rehearsal. 12 (08-22) honest oracle: F-D fail-stop floor.
  - 13 (08-22) clean numbering: oracle numbering = upstream's
    byte-identically; F-D closed by construction; grandfather
    dissolved; lem-sync + libc.co staging gates born.
  - 14 (08-22) immaculate pass + re-mark: grumpy-professor remediation,
    re-grade semantics A− / backend B+ (operator-accepted);
    test_immaculate lane; two oracle-wrong finds pinned Lean-right.
  - cn-coverage (08-22, own lane): 213/213 CN-corpus differential,
    CoreParser scan_ub mirror fix (its first catch).
  - 15 (08-22/23) the spec lab, three streams, all merged 08-23:
    Lane A COMPLETE — 5 rungs (scalar→bytes→list→tree→CN seed),
    ~1,970 differential executions all agreeing, twin registers +
    Linux-scaling memo, template amendments, amortization 2 fresh CN
    targets/31.5 min; CI sweep — 2,186 files, 1,316 comparable, ZERO
    mismatches, 1 new defect (pr44468 offsetsof panic, S-M); Lane B —
    historic T5 blocker killed (instance-implicit divergence), 13/79,
    parked at the R13 kernel-depth wall.
  ACTIVE STATE: the SEAL-THROUGH-THE-CHASE approach ran and was
  FALSIFIED (engine built + R13 re-attacked on branch arc/t5-seal:
  the wall is kernel unfold-ORDER, not depth — no statement shape
  fixes it; unbounded navigation-shape ladder). [USER 2026-08-24]:
  the chase machinery is design debt at the WRONG ABSTRACTION LEVEL
  — branch arc/t5-seal PARKED UNMERGED (prune-don't-merge ruling;
  workbench-v2 worktree sits on it, preserved). STRATEGY PIVOT
  [USER]: (1) build a CERTIFIED SYMBOLIC EXECUTOR — symStep over a
  reified SymState with a once-proved soundness theorem vs the fuel
  opsem; instance proofs by kernel reflection (legal: kernel
  computation, not ofReduce*; the old rfl-ban was a perf rule about
  the raw interpreter); (2) reconstruct C-source program structure
  from Core's compiled shapes (elaboration is stereotyped; spec-lab
  measured vocabulary saturation) → derived proof rules per source
  construct incl. logical loop invariants; brick-wp (deps/) is
  "literally this" for BRICK — primary donor, with Lithium. What
  survives the pivot: law tables/context laws (semantic equations
  the soundness proof consumes), the R13/falsification record (cite
  the parked branch), engine bug knowledge. T5 remains parked at
  13/79 (mainline state). SUPERSEDING PLAN (whole-project audit +
  [USER] blessing, 2026-08-24): THE IRIS REFOUNDING — charter MERGED
  at lean_frontend/docs/2026-08-24_arc16-iris-refounding-charter.md
  (part 1: S0 freeze gate + IPM perf probe → S1 per-step language
  instance → S2 CerbMem heap RA [risk item, exit ramp] → S3
  primitive WP laws + wp-tactics → S4 ACCEPTANCE: re-prove T1-T4 at
  identical statements/cones in ~tens of lines). S2/S3 DESIGN
  GUIDANCE [USER 2026-08-24 + S0 measurements, the two faces of one
  rule]: the state INTERPRETATION is legitimately a concrete
  authoritative map (GenHeap shape; appears only in adequacy
  plumbing) — but PROOF-LEVEL assertions (invariants, pre/posts,
  summaries) must ABSTRACT over unmodified heap: footprint
  points-to + rep predicates + big-ops, the frame rule carrying the
  untouched rest implicitly; never enumerate allocations as flat
  ∗-chains (standard SL discipline; S0 measured its mechanical
  shadow — iframe quadratic in context width, heartbeat cliff at
  ~150-200 hypotheses, term-elaboration death at ~250 flat
  conjuncts). [USER]: study RefinedC CLOSELY for S2 — Caesium has
  the same problem (Iris heap over a real provenance-carrying C
  memory model): how its heap RA is shaped, how typed points-to
  layers over bytes, how Lithium keeps contexts footprint-sized
  (deps/refinedc, theories/{caesium,lithium}). [USER 2026-08-24,
  part-2 design principle]: GIANT TERMS IN GOALS ARE A
  REPRESENTATION SMELL — a (mild) signal the tactic library is
  wrong (the S3 whnf cliff: core_file inlined in every state term,
  though the program is INVARIANT across execution — index it,
  don't inline it). Escalation: (1) named states / program-as-
  parameter (S3's cheap regime, S4 rides it); (2) the discharge
  engine — SHAPE CORRECTED by the ACL2Lean donor review
  (notes/2026-08-24_acl2lean-donor-review.md): the donor BUILT the
  monolithic verified-checker-by-reflection route and PIVOTED to a
  PROOF-PRODUCING checker (MetaM emitting ordinary kernel terms per
  instance; ratified invariant prohibits a monolithic Derivation
  inductive + one soundness theorem). Our part-2 engine follows:
  reflection at the LEAVES (proveByDecide-style memoized decide for
  ground side conditions — LIFT), proof-producing emission for step
  structure, giant invariant data reflected ONCE into named
  constants (derive_world → derive_state, the S3 park fix, S) and
  referenced by name, fuel-robust ∃N∀f≥N lemma statements.
  Pre-discovered kernel cliffs: fixed 200k whnf budget
  (maxHeartbeats 0 does NOT lift it; concrete-discriminant rfl
  stays cheap), kernel recursion depth. Candidate trust import:
  comparator+nanoda independent-kernel validation probe (S,
  operator-gated). Ban-compliant throughout (kernel decide, no
  ofReduce*). PART-2 CHARTER ITEM. Operational corollary:
  parallel Lean builds contend hard on this shared box — one heavy
  worker at a time, CERB_MEM_MAX=48G habit, stagger heavy lanes;
  [USER 2026-08-26]: silent session kills are often box-level OOM —
  the MAIN agent process is uncapped and is the natural victim;
  suspect OOM on any unexplained session death (swap residue is the
  tell), run batteries strictly serially, avoid coinciding with
  backup jobs, drop to 32G under pressure; commit promptly rather
  than batching work into long uncommitted windows (kill-loss
  containment);
  part 2 =
  T5-by-invariant, spec-lab exec endpoints, THE PURGE (~700K chase
  text, one commit, gate re-registrations), docs. Post-mortem:
  docs/2026-08-24_chase-era-postmortem.md. Audit headline: our Iris
  consumption was 4 import lines of a 281-module dep that already
  holds the full IPM + GenHeap + total-WP + the HeapLang worked
  template — the chase compensated for the missing instantiation.
  Stepper design note SUPERSEDED (both copies headered); the
  certified-executor sketch was never written (absorbed: reflection
  = side-condition solvers inside the Iris frame). QUEUED (registered, priced in
  the arc-14/15 records): A-road polish basket (backend L-slice,
  S13/S15 gaps, ott finish), stack-ceiling guard, cmm/concurrency arc
  (RESCOPED 2026-08-26, [USER]-ratified per the pKVM spike:
  lock-invariants M + schedule-streams face M + lem-generated C11
  model from upstream cmm_csem.lem M-L; weak-memory logic deferred
  as its own future program — [USER] "PhD level work in itself";
  choice streams = schedules; spec-lab findings feed its design),
  pKVM buddy target (PROMOTED — needs no cmm arc: segment layer +
  FnSpec + lock-contract idiom + 2 axiomatized asm lock primitives
  as temporal boundary entries), WireGuard ladder (demoted behind
  pKVM — RCU in allowedips is the harder concurrency), repo split
  (own small arc),
  upstream filing tray (~16 drafts, notes/upstream/ + 3 PR branches —
  operator network window), CoreParser enum-ctype gap (S), oracle
  allocation-census line (S), mechanism-B --args flag (S).
- **Branches + worktrees.** All work on arc branches in worktrees;
  primary checkouts stay parked on the mainlines.
- **Two-repo pin dance.** Branch pair with the same name in both repos.
  Merge order at arc end: lem-lean first (ff-only into
  `mdd/lean-backend`), re-pin cerberus to the MERGED lem commit, re-run
  the gate, then cerberus merges ff-only. An arc is closed only when
  branch heads = opam pin = Lake pin.
- **The validation gate** (green before any checkpoint claim, audit, or
  merge): lem-lean `make` + `tests/comprehensive: make lean`; cerberus
  full battery (test_unit 7/7, test_verify, test_exec zero-movement,
  test_core ALL, cn_coverage baseline, immaculate baseline, libc, uri
  + the speclab lanes). No new sorry/axioms outside the declared
  boundary list. A green build is not evidence of correctness; the
  differential baselines are the signal.
- **Pre-merge audit: the ASK is unconditional.** Before any merge,
  propose audit scope + scale to the user; they may waive or trim, but
  the ask is never skipped. Companion habit (professor re-review,
  2026-08-23): merges that change proof capability re-read
  lean_frontend/PROOF.md §3 (in-flight/proved status) for currency —
  docs rot at milestones, not at embarrassments.
- **Merges are ff-only, exactly** — rebase if the mainline moved,
  re-gate, re-ask. No merge commits, no `git branch -f`, no pointer
  surgery. `git push` is a separate, operator-gated action.
- **Orchestrator/worker execution (2026-08-19).** Arcs run as SEQUENCED
  SUBAGENT WORKERS with the main agent as orchestrator: it owns
  charters, decision logs, exact worker scoping (files in scope,
  mechanisms, validation commands with exit-code discipline,
  park-don't-improvise), independent gate verification at boundaries
  (worker-claimed green is never accepted — re-run), audits, and pin
  dances. WORKERS COMMIT their own work: only on green gates, one
  coherent commit per slice, message states what was verified. QUOTED
  OUTPUTS ARE VERBATIM: anything formatted as tool output must be
  literal; derived tallies are fine but LABELED as derived — a
  doctored transcript is a record-integrity finding even if its
  numbers are right. MERGE LIVES WITH THE USER: ff-only on explicit
  per-merge sign-off; the ask is unconditional. A COMMITTED PARK
  RECORD ENDS THE SLICE (2026-08-25, from the S3 stop): a worker
  that writes a park/frontier record and then keeps working past it
  without orchestrator approval is in violation — the record IS the
  stop signal; post-park pushing is the seal-era pattern regardless
  of how green the prior milestones were. Status pings require an
  IMMEDIATE interim reply (SendMessage to main works mid-task);
  silence during active work is not an acceptable status.
- **Parallel streams** on disjoint worktree pairs, one per arc branch:
  (1) write surfaces disjoint; (2) opam-installed lem is SWITCH-GLOBAL
  — streams needing different lem use the per-worktree checkout lem,
  only the closing arc re-syncs the pin; (3) merges serialize (second
  stream rebases, re-gates, re-asks); (4) workers within a stream stay
  sequenced.
- **Mirror-OCaml doctrine (2026-08-19).** Gratuitous Lean↔OCaml logic
  divergence in hand-written seams is a DEFECT AS SUCH — no observable
  failure required. Each divergence is either eliminated (mirror the
  OCaml, cite file:line in a comment) or documented in-code as
  deliberate with rationale. Undocumented divergence = defect.
  Register: `lean_frontend/docs/2026-08-19_arc4-seam-survey.md`.
  Audits check citations against the cited code.
- **No-internal-trust-gaps doctrine (2026-08-19).** If two Lean
  artifacts must agree, that agreement is a THEOREM, not a test.
  Kernel-opaque artifacts (partial def, axiom, implemented_by) are
  eliminated (fuel-totalize) or sit on the DECLARED BOUNDARY LIST with
  an immovable-object justification. Immovable objects: the OCaml
  oracle, native C externs, the Lean kernel/compiler. Boundary entries
  are PERMANENT (those three) or TEMPORAL — temporal entries carry an
  expected mover + a FORWARD-DESIGN constraint (nothing built today may
  make the move harder; e.g. no baked-in single-thread/SC assumptions
  the cmm instantiation would unwind). [USER 2026-08-24] THE EFFECT
  AXIOMS ARE TEMPORAL, NOT PERMANENT: runEffectful/forceIO/
  with_tagDefs are reclassified TEMPORAL — expected mover = effect
  state (fresh-symbol supply, tagDefs) modeled INSIDE the machine
  state via Lean-target-only threading (the arc-13 pattern; OCaml
  target stays ambient forever for upstream byte-identity), natural
  vehicle the cmm arc or earlier; operator: "kill this sooner rather
  than later"; end state = theorem cones EXACTLY the classical trio
  {propext, Classical.choice, Quot.sound}, no magic. SPIKE PROVED
  REACHABLE 2026-08-24 (branch effect-spike @ 7f4100a5c, parked
  per spike doctrine): T1ThreadedOutcomes — ∀-seed (STRONGER than
  the ambient theorem), cone exactly the trio, in-build pinned;
  runEffectful enters T1's cone through exactly ONE generated def
  (initial_core_run_state's supply seed; mid-run draws already
  state-threaded — arc-13's legacy); ZERO lem-backend changes;
  OCaml-fidelity gates all green. [USER 2026-08-24] APPROVED: the
  real elimination FOLDS INTO arc-16 S4 — S4's success criterion
  becomes "T1-T4 re-proved cheaply through the Iris machinery AT
  THE THREADED STATE, cones exactly the classical trio"; the
  charter's S4 text gets amended on the arc branch at the S2→S3
  boundary (orchestrator task); with_tagDefs/forceIO (digest/
  tagDefs seam, S-M) attempted in S4, parked-with-price if it
  spreads. Proof half NOT done early: it would ride the chase
  machinery scheduled for deletion (statements re-derived there
  anyway; T4 dissolves its fresh conjunct; one systematic hazard
  recorded:
  whole-stage rfl needs CLOSED states — seed-quantified proofs
  route memory ops through the kit, style now hardened to
  necessity). [USER 2026-08-24] MODEL-LEVEL END STATE — freshness
  as CAN'T-HAPPEN NONDETERMINISM: the allocator picks values
  nondeterministically; a consistency predicate (all draws
  distinct) discards inconsistent executions (assume-not-assert);
  the counter is a REFINEMENT whose metatheorem (monotone ⇒
  distinct) is BOTH the implementation's correctness AND the
  anti-vacuity witness (at least one consistent execution exists —
  plant-test doctrine demands this stays a theorem). Lineages:
  assume-discipline, HeapLang alloc-ND (per-step premise — use
  where the constraint is prefix-closed, as freshness is; WP-
  friendlier), axiomatic-model candidate filtering (end-of-run
  form — NOT prefix-closed constraints; what cmm needs anyway),
  CompCert-style renaming/equivariance (one representative run
  suffices — why the exhaustive runner never enumerates name
  choices; executable+differential faces stay the counter).
  Sequencing: S4 lands the ∀-seed threaded form as chartered;
  ND+filter is the cmm-arc formulation (freshness = its warm-up
  client, shared machinery). [USER 2026-08-24, extension]: SL
  INTERNALIZES the can't-happen pattern — memory allocation is the
  same shape, and ∗ is distinctness made local: double allocation
  isn't filtered, it's UNCONSTRUCTIBLE (exclusive points-to = RA
  invalidity; the frame-preserving update at alloc is the per-step
  can't-happen certificate, "the environment establishes it";
  consistency metatheorem = RA validity, proved once in GenHeap).
  CANDIDATE consequences — [USER 2026-08-24]: "memory allocation
  is a subtle matter for separation logic due to the global
  effects it hides. This is *one* way to deal with this, and we
  should evaluate before executing" — DESIGN-EVALUATION GATE
  before any of this executes (at the S4/part-2 charter): S2 may
  inherit alloc-freshness from GenHeap; the symbol supply may
  become a ghost resource (mono-counter/GhostMap shape); fresh
  symbols / alloc / cmm event ids may unify. EVALUATE AGAINST the
  known subtleties of C memory that break the clean SL alloc
  story: address OBSERVABILITY (PNVI/casts expose concrete
  addresses — measured in our own corpus: the pnvi sweep's
  stdout address diffs — so naive equivariance/renaming fails
  where programs observe addresses), provenance in the RA,
  allocation FAILURE nondeterminism (malloc null), finite address
  space/alignment, allocation-id reuse. Caesium's treatment of
  exactly these is the evaluation's reference point. Native extern
  counters survive only as compiled-side implementation of the
  modeled supply, out of every cone. HARDENED forward-design
  constraint: any design that would make this threading harder is a
  defect (statement layer already leads — f.tagDefs passed
  explicitly; keep new statements/machinery supply-passable). Entries without justification,
  or temporal entries without a mover, are findings. (The DAEMON axiom
  saga — lem's inconsistent inhabitant marker, deleted arc-8 with
  standing absence gates — is this doctrine's case study:
  lembugs/2026-08-20_daemon-inconsistent-axiom.md.)
- **Non-kernel proof methods are BANNED (operator, 2026-08-19):**
  `native_decide`, `bv_decide`, anything carrying
  `Lean.ofReduceBool`/`ofReduceNat`. `#guard` is untrusted-evaluator
  checking — fine AS A TEST, never described as kernel-checked.
  Enforcement: exact transitive axiom-set assertions (classical trio +
  declared boundary only), build-failing; ofReduce* always-fatal in
  every probed cone; tactic names grep-banned in proof files.
- **Grind campaigns are BANNED (operator, 2026-08-24, verbatim):**
  "you are banned from stupid grind campaigns. That is, any build
  that requires more than 1hr is highly suspicious. Do not just run
  the kernel against a bazillion terms. Your main skill is
  iteration. Long grind campaigns are poison to iteration. Don't
  do it, it's banned unless there is an extraordinarily strong
  justification." Enforcement: any worker brief includes a
  time-suspicion tripwire — a build/proof pass approaching ~1hr is
  a STOP-AND-REPORT event, not a thing to wait out; orchestrator
  scoping must decompose work into iterable slices; a >1hr campaign
  requires a written extraordinary justification IN ADVANCE
  (operator-visible), never retroactively. Measurement sweeps
  (differential corpora) may qualify for justification; kernel
  grind never has. Case study: the 10-hour seal-engine session.
  [USER 2026-08-24, refinement]: "grinding on a proof is somewhat
  reasonable IF THE REASONING IS COMPLEX. Do not just wait on a
  shell script that is brute force elaborating a term. Be
  suspicious of a subagent trying to force-grind a term. Building a
  sophisticated proof may require a long time, that's fine." The
  banned thing is precisely "dumbly throwing a bazillion terms at
  the kernel" ([USER]: "pointless and stupid") — NOT long build-out:
  long construction of a sophisticated proof, and legitimately long
  builds of real content, are fine. The tripwire is the PATTERN,
  with wall-clock as its symptom: volume of kernel checks hoping to
  succeed where structure hasn't; kernel-vs-giant-term standoffs;
  elaboration as a substitute for thought. Orchestrator suspicion
  heuristic: a worker feeding the kernel bulk terms is suspect; one
  building hard content — even slowly — is working. THIRD SPECIES
  [USER 2026-08-25] — PROOF GRIND: "an agent takes a giant term and
  then proves it grindingly tactic by tactic, where an automation
  step would knock it out immediately." The landed-and-green manual
  wall is still grind: the long script CONCEALS the real finding
  (the missing automation step). Test: a long manual tactic run
  over a big goal means the deliverable is the missing tactic/law/
  minter — build THAT, then the short proof; the proof-size gate's
  40-manual-step bar is this rule's mechanical floor (keep tight,
  never raise). WHY [USER
  2026-08-24]: "the aim here is verifying vast software. We can't
  grind our way to success. We need powerful automation to help us
  scale" — grind is O(program size) forever; automation is
  proved-once-fires-everywhere. At the north star's scale the
  distinction is not efficiency, it is feasibility.
- **Never run a Lean build uncapped (2026-08-20).** Every lake/lean
  invocation goes through `cerberus-lean/scripts/capped` (cgroup
  MemoryMax 64G default, CERB_MEM_MAX override, `=none` loud opt-out).
  `lean -M` and `prlimit --as` do NOT work. Companion habits: #eval
  the Bool before asking the kernel; whole-driver-run rfl/decide is
  banned (compositional equation chains instead).
- **Two-part-design intention (operator, 2026-08-21):** intended
  end-state = repo split: "cerberus-lean the semantics" vs "the
  verification layer" (relsem), plus per-target example repos (incl.
  GPL'd ones). Standing FORWARD-DESIGN CONSTRAINT: no gratuitous
  coupling across that seam — semantics→verification dependency
  strictly one-way (gate-enforced), the consumed interface stays
  enumerable, gates riding the semantics build stay re-homeable.
  Violations are TEMPORAL-class defects (register + mover). The
  arc-11 package rehearsal banked the split's design data.
- **Canon-first proof scaling (operator, 2026-08-24, verbatim):** "the
  field of formal verification has tried to solve scalable proof over
  many years. Our first tools should be the ones people have built up
  over many years: abstraction, invariants, symbolic execution,
  simulation / bisimulation, framing / separation, protocol calculi
  etc. We should NOT be throwing energy into funny tricks if we
  haven't exhausted these powerful core ideas. We may *eventually*
  need new ideas which haven't been covered in the literature. But
  for now, our first direction when scaling our proof engine should
  be this, not funny hacks over the representation, or grinding."
  Enforcement: any charter proposing proof-engine machinery NAMES the
  canonical lineage of each mechanism (or explicitly justifies
  novelty as post-exhaustion); representation-level tricks and grind
  plans are findings absent that justification. Case study: the
  seal-through-the-chase episode (parked unmerged, arc/t5-seal).
  [USER 2026-08-24, clarifying ruling]: "we are building an
  IRIS-BASED PROGRAM VERIFIER FOR C because that is what will scale.
  Hacking things out one step at a time will not." Iris is the FIRST
  port of call — its built-in machinery (WP calculus, invariants,
  framing, ghost state) and the ideas the community has encoded into
  it (mapped in our lit review: notes/2026-08-21_iris-litreview-
  brief.md + the iris-rules-automation survey; donors: RefinedC/
  Lithium, brick-wp). Proof-engine design starts from "what does
  Iris already provide" before anything bespoke.
  [USER 2026-08-24, the REUSE DISCIPLINE]: much of the machinery we
  need is embodied in iris-lean or built by other Iris projects (the
  ported lit review + papers). (1) USE that machinery where it
  exists; (2) build IRIS-COMPATIBLE machinery where it's missing;
  (3) REUSE IDEAS freely when they solve our problem; (4) NOTICE
  when our custom solutions are converging on Iris ideas and map
  them into reusable proof infra. None of which says don't innovate
  — just take care not to duplicate where we can reuse. (Point 4 is
  a standing audit lens: convergent-but-custom machinery is a
  refactor-to-Iris finding, not a keeper.)
  [USER 2026-08-24, refinement — the TRICK FILTER]: the problem is
  never cleverness ("we will need every lever we can get to make
  this scale") — the problem is STUPID tricks: (prong 1)
  non-scalable GRINDING that wouldn't extend past the current
  example (instance enumeration in mechanism costume), or (prong 2)
  hacks WITHOUT INSIGHT into the abstraction being manipulated
  (steering behavior we neither control nor model — learning the
  abstraction by collision is the tell). A good trick states in one
  sentence what abstraction it exploits and why the next example
  gets it for free. Refines, not replaces, canon-first: canonical
  tools pass by construction; novel tricks must pass explicitly.
  WHY canon passes by construction (2026-08-24, relayed insight):
  "Separation logic is a 'clever trick' partly because Reynolds and
  O'Hearn struck gold, but partly because the community has spent 20
  years poking at it and finding all the dumb problems. There's an
  evolutionary process where some things work and some don't. And if
  we come up with a new 'clever trick' we have to do that evolution
  ourselves. Better for it to have been done for us over decades."
  Canonical tools arrive PRE-DEBUGGED by decades of communal
  selection; a novel trick's price includes running that whole
  evolutionary process alone (the seal episode ran 18
  collision-iterations of private evolution and only reached
  "falsified"). Novelty must budget for its own evolution — which
  is why it comes after exhaustion, not before.
- **Proof-scaling philosophy (operator, 2026-08-21):** "keep trust
  surfaces very clean, but we're happy to do whatever clever tricks
  make the proof scale *for kernel-certified steps*. No insane hacks
  for specifications." Statements and the TCB are pristine; proof
  MACHINERY may be engineered aggressively so long as every step lands
  as an ordinary kernel-certified obligation and the meta-code stays
  reviewable. Refines, never relaxes, the non-kernel ban.
- **Certification-integrity rules (2026-08-22):** (1) validation of
  build-rule-affecting changes must be CACHE-DISABLED
  (DUNE_CACHE=disabled + --force) from a checkout with RE-DERIVED
  generated trees (lem-sync content-hash gate enforces); (2) audit
  PLANT recipes mandate REBUILD-AFTER-REVERT; audit pairs sharing a
  worktree sequence binary-affecting plants; (3) VERIFIED-vs-LOADED
  artifact gaps are findings — check the artifact the consumer
  actually loads (libc.co staging gate is the pattern); never
  2>/dev/null an install/build step.
- **Heartbeat hacking is a bad smell (operator, 2026-08-20):** raising
  maxHeartbeats/maxRecDepth means brute-forcing what needs better
  structure. Bumps are BY DEFINITION defects: register entry + expected
  remover; permanent only after investigation AND explicit operator
  agreement. Un-registered bumps are audit findings.
- Machine-global state remains forbidden (top of this file); opam
  switch-level ops work in-session, config-level ops are operator-run.

## Offline / sandbox notes

Designed to work with no network: toolchains preinstalled (elan
4.26/4.28/4.29/4.32), opam packages installed, Lake deps cloned +
mirrored locally, mathlib olean cache + cvc5 downloaded. Refresh
mirrors (network required):
`for m in deps/mirrors/*.git; do GIT_CONFIG_GLOBAL=/dev/null git -C $m fetch; done`

## Known issues / current pins (as of 2026-08-23, post arc-15)

- Pins: lem-lean `mdd/lean-backend` @ `cf9e04c` (shop-window docs
  merge 2026-08-23, professor-graded A−; docs-only, so the opam +
  Lake pins deliberately REMAIN at `861ed81` — the arc-14 backend
  immaculate slice; next functional lem arc re-pins. History in
  ROADMAP). GOTCHA (hit at this merge): the primary checkout's
  in-tree ./lem binary goes stale vs fork grammar additions — run
  root `make` before trusting tests/comprehensive there. cerberus-lean
  `mdd/cerberus-lean` @ `e59bcbb84` (ARC-16 PART 1 MERGED
  2026-08-24, audit MERGE-SAFE zero-MAJOR, [USER] ratified the
  MINOR-1 tens-of-lines reading with standing DOWN-PRESSURE ON
  PROOF LENGTH as automation grows. Landed: per-step language
  instance, CerbMem heap RA (GenHeap byte points-to + framing demo,
  trio cone), loop peels + 15-law library + wp-tactics (11 manual
  steps → 9 tactic lines), chase freeze gate, S4 acceptance: T1-T3
  RE-PROVED AT ∀-SEED THREADED STATE — 25 pins, cones EXACTLY
  {propext, Classical.choice, Quot.sound}, no runEffectful; T4
  stopped at a kernel-witnessed diagnosis: unrestricted ∀-seed T4
  is FALSE (hash-collision capture; fix = seed-apartness + env
  algebra, M, part 2). Ambient T1-T4 stand until the purge. PART 2
  NEXT — ORIENTATION RULING [USER 2026-08-24]: "CN feels like an
  extension, not the main line. Our main line is building a
  scalable proof automation framework inside Iris for theorem
  proving use. Ultimately, we want to be able to verify libxml2 via
  this framework. CN is a kind of nice convenience, but the core of
  this is building a clean, well-structured automation / tactic
  library using the powerful affordances offered by iris-lean and
  ideas from our inspiration in other academic work." MAIN LINE:
  equation-supply frontier (fixture-independent per-construct
  laws), the ACL2Lean-shaped discharge engine, T4-apartness env
  algebra, T5-by-invariant, the purge, spec-lab family-∀ endpoints,
  the LIBXML2 LADDER (uri.c — differential corpus + 16/16 gate
  already standing — as the framework's graduation target).
  EXTENSION TRACK (convenience; never blocks main line): CN-1+
  ladder, Fulminate lanes. Typed views serve BOTH (main-line
  citizens). ARC 17 LAUNCHED 2026-08-24: charter BLESSED + MERGED
  (docs/2026-08-24_arc17-automation-framework-charter.md; slices
  S0 discharge substrate → S1 equation-supply frontier → S2
  T4-apartness → S2b boundary-axiom endgame → S3 T5-by-invariant →
  S4 family-∀ → S5 purge → S6 libxml2 rung; the LITHIUM/CAESIUM
  PARITY GOAL as FLOOR-not-ceiling with the four-component ledger.
  [USER 2026-08-25, parity refinement — REACH, NOT CLONE]: "we
  should take care to not over-clone refinedc. The purpose is a bit
  different, they want to support human devs, while our main aim is
  to support AI-DRIVEN PROOF. So we should aim for similar reach,
  but we don't have to clone their user-facing infra." Consequences:
  parity is measured in REACH (what can be verified at what cost),
  never in interface; DE-SCOPED: human annotation-syntax ergonomics,
  IDE tooling, human-readable error engineering beyond honesty;
  BUILT INSTEAD (agent-facing affordances, several already exist):
  machine-consumable stuck goals/holes, replayable trace formats
  (the S0 schema), programmatically queryable registry (C1),
  cheap-probe iteration affordances, the PLAYBOOK with dumb-agent
  probe (C6 = our ergonomics layer, for agents), measurement hooks
  (down-pressure register). CN frontend stays extension-track
  convenience — an agent authors proof-layer artifacts in Lean
  natively; reach parity ≠ annotation parity
  + S6 parity-distance table; RefinedC license re-verified BSD).
  ARC-17 CONSOLIDATION MERGED 2026-08-25 @ `da279e0cb` (audit
  MERGE-SAFE zero-MAJOR; 19 commits: discharge substrate, law
  registry + PASSED generalization probe [t6: never-seen program,
  zero fixture equations, trio cone], round evaluator +
  hypothesis-threading, env algebra, arith minter, builder-walk
  engine, THE AXIOM ENDGAME [census 0, no-cone gate 114], capped
  KILL banner, honest parked frontiers [T4 round 22, T5 walk 43/72
  record-only]). Stash@{0} on cerberus-lean = triaged S3 post-park
  delta (1/3 salvage → arc-18 C1; probes preserved at container
  .arc17-probe-scratch/). S3 incident: post-park pushing stopped by
  orchestrator; assessment 1/3 machinery 1/6 seeds 1/2 grind;
  park-ends-slice doctrine born. ARC 18 — THE COHERENCE ARC —
  LAUNCHED 2026-08-25: charter BLESSED ([USER]: Q1 DELETE dormant
  peels/wpk laws, Q2 FULL CerbMemInterp migration + exit ramp, Q3
  ONE arc) at worktree cerberus-lean-coherence branch coherence,
  lean_frontend/docs/2026-08-25_arc18-coherence-charter.md; inputs:
  the coherence review (notes/2026-08-25_reasoning-coherence-
  review.md — MIXED verdict, six seams, "leave exactly one route")
  + the stash assessment. Ladder: C0 doc-truth+contracts → C1 one
  registry + RoundEval decomposition + salvage → C2 one-route
  migration (byte-stable cones) → C3 identity law + T4 + T5 → C4
  statement homing + family-∀ → C5 EXTENDED purge (arc-7 shell +
  dormant peels + chase + ambient; review re-run as audit) → C6
  PLAYBOOK (dumb-agent probe acceptance). T5 AFTER consolidation
  (adjudicated: landing first = proving twice). [USER 2026-08-26,
  design ruling — THE HOARE LAYER + THE PROOF-STYLE PROFESSOR
  TEST]: for simple programs the machine's reasoning and a human's
  correctness argument should MOSTLY COINCIDE — "reasoning over
  straight-line program sequences to join points" (Hoare style:
  segment triples composed by the sequence rule, if = join,
  invariants only at loop heads). The "walks" are
  interpreter-structural and correctly SUSPECT as a user-facing
  idiom: rounds/walks are engine-room equation supply, consumed
  ONCE per derived SEGMENT RULE (the decompilation layer at
  C-statement granularity, one level above the Core-construct
  laws), never in user proofs. THE TEST [USER]: "can the grumpy
  professor understand our reasoning style, or is it just
  uninterpretable 'term wrangling'" — a professor pass over PROOF
  TEXTS, same standard as the docs professor. Companion campaign
  [USER]: prove A BUNCH MORE SMALL PROGRAMS — breadth at low
  difficulty shakes out design-layer bugs (the spec-lab pattern
  aimed at the proof layer); acceptance per program = STRUCTURAL
  COINCIDENCE (proof shape mirrors program shape) + the professor
  reading; a program whose proof can't take that shape is a design
  finding, not a proof to grind. SEQUENCING RATIFIED [USER
  2026-08-26]: Hoare layer + breadth campaign AFTER C4, BEFORE
  C3c/C5/C6 — gated on (1) a WHOLE-PROJECT DESIGN PASS first
  ("avoid baroque machinery hanging around if it's not needed" —
  a baroqueness audit of everything built, delete-or-justify; and
  the reasoning layer designed COMPARATIVELY vs brick-wp /
  RefinedC-Lithium-Caesium / CN's judgment styles / full BRiCk
  (deps/BRiCk, cloned 2026-08-26 [USER]: "the 'middle layer'
  before automation is applied" — BedRock's C++ program logic,
  exactly the layer we are choosing; tri-license
  BedRock-LGPL2.1+addendum/LLVM — IDEAS-ONLY usage, any code reuse
  needs a license read first, unlike the BSD donors) — triples vs
  typing judgments vs wp: adopt deliberately, not by inertia), and
  (2) OPERATOR DISCUSSION before sign-off — the design pass's
  output is a discussion document, not a charter; no
  reasoning-layer imposition without the conversation. EXECUTED
  2026-08-26: design pass ran (notes/2026-08-26_reasoning-layer-
  design-pass.md) → operator conversation → DECISION SLATE RATIFIED
  [USER 2026-08-26]: single LONG-CYCLE charter, right-thing-now
  ruling ("if we're confident, we should move towards the right
  thing"; narrow slices only at genuine unknowns); SL segment
  triples at Core labels, types-later-maybe; invariants = ordinary
  proof content; C3c DEAD as a work item (T5 lands once, through
  the layer); MIRROR-DONOR DISCIPLINE [USER, verbatim]: "match /
  mirror BRiCk / refinedC in places it makes sense. Not
  gratuitously be different" — mirror-OCaml extended to the proof
  layer, donor-correspondence table as audited deliverable; call
  rule = STANDARD SL FnSpec + frame (typed_function/wp_call
  mirror; SAW whole-state staging retired as stale pre-Iris
  design); corpus = census-ramp-to-uri.c ("final exam trivial",
  >20 programs ok) + difficulty-biased EDGE tier ([USER]: "Easy
  cases should be easy, hard cases test the edges") + per-program
  anti-grind budget (2 consecutive over-budget = campaign halt).
  CHARTER audited (Fable pragmatics pass SOUND-WITH-AMENDMENTS,
  F1-F9 folded — headliners: ∃-ROUND judgment from day one since
  fixed-round iter_compose can't state branch-in-loop; R3 purge
  import-scan-scoped since AppEq/AppWalk/PerStepRunner are live
  deps until R4/R5/R7; R4 repriced M-L; R2/R4-close mandatory
  success reports). R0 EXECUTED 2026-08-26: independent gate audit
  MERGE-SAFE zero-MAJOR (4 MINOR fix-forwards FF-1..4 registered
  in-charter, incl. lake-lean probe-recipe breakage on the
  C1-decomposed engine modules), C0-C4 ff-MERGED to mainline @
  cfeb7af5e on [USER] sign-off ("land these first"). Long cycle
  runs on branch arc/segment-ladder (coherence worktree) @
  b8baec82f; charter = lean_frontend/docs/2026-08-26_arc18-
  segment-ladder-charter.md (R1 open-memory minting → R2 full
  layer → R3 purge → R4 T5+re-housing M-L → R5 T4-apartness → R6
  breadth 3-tier → R7 purge remainder → R8 playbook hard-bar → R9
  uri.c capstone stretch). ALL FIVE ON-DECK DECISIONS RATIFIED
  [USER 2026-08-26]: (1) FnSpec promotion-ready = ratified
  forward-design constraint; (2) safety-only breadth lane IN
  (UB-freedom cost measured alongside functional proofs — the
  containment product tier's data); (3) substrate SIZE LADDER in,
  with ruling: when the ladder finds a substrate cliff, the answer
  is BETTER ABSTRACTIONS, NOT GRIND (remediation is
  representational/abstraction work — consistent with the
  heartbeat-hacking smell and giant-terms-are-a-representation-
  smell doctrines, never budget bumps or wait-it-out); (4)
  cmm/pKVM scoping spike RAN 2026-08-26 (notes/2026-08-26_cmm-
  pkvm-scoping-spike.md) — HEADLINE: pKVM EL2 is lock-disciplined
  sequential C (74 spinlock sites vs 3 bare atomics, zero smp_mb;
  only ordering-bearing code = the ~40-line asm ticket spinlock,
  unparseable by Cerberus, contracted primitive under ANY model);
  buddy allocator = pure sequential-under-lock (CN case study
  precedent: locks commented out, Owned(pool) as lock-held
  resource) → NEEDS NO CMM ARC, path = segment layer + FnSpec +
  M-priced lock-contract idiom (CSL ownership transfer); WireGuard
  is HARDER (RCU in allowedips) — pKVM stays first and moves
  EARLIER. SPIKE FOLLOW-ONS RATIFIED [USER 2026-08-26]: (a) the
  two lock implementations become AXIOMATIZED TRUSTED PRIMITIVES
  when the pKVM target starts (temporal boundary entries; mover =
  the eventual weak-memory logic); (b) queued cmm arc RESCOPED to
  lock-invariants (M) + schedule-streams face (M) + lem-GENERATED
  C11 model from upstream cmm_csem.lem (M-L), weak-memory program
  logic explicitly deferred; (c) lock-shaped ownership-transfer
  worked example added to the R6 breadth edge tier (charter edit
  rides the R2-boundary commit). [USER 2026-08-26, verbatim]: "We
  will eventually need to build a weak memory logic, but it's PhD
  level work in itself" — classified as its own future PROGRAM
  (post-exhaustion, XL, Lean-ecosystem-gap-binding), never a rung
  of a near arc; (5) charter
  BLESSED (status flip + PENDING→RATIFIED tags committed at the R2
  boundary @ 86dcd5ce1). LADDER PROGRESS (2026-08-27): R0–R4
  COMPLETE on arc/segment-ladder, every boundary independently
  re-verified. R1 open-memory minting @ 0bc67d121 (memRW laws
  insufficient in COUNT not kind, +7; T6 on the open route, OwnP
  exemption cleared). R2 the layer @ 710f25f9c/09c322067/c490a1b44
  (∃-round judgment + variable-round while_inv proved once; FnSpec;
  T6 body verbatim = `verify_fn pickSpec; seg_auto`; T7
  branch-in-loop flagship 249ln/19 steps at 95/72/94 data-dependent
  rounds; [F3] twins demo; donor table; seg_env_lookup + write1
  built as engine, species-3). R3 purge @ 78439359c (zero-importer
  trio deleted, kept-live table = R7 work order). R4 @
  4774a8a97..03402431b: **T5 PROVED at the chartered ∀-n input
  family** (0≤n≤100, outcomes = {Specified(n(n−1)/2)}, no UB;
  RelSem/T5.lean 114ln/4 manual steps; proof = `verify_fn sumSpec;
  seg_auto`; symbolic trip count through the once-proved rule;
  trio cones); [F8] MEASUREMENT: 28-field pack → 24
  frame-internalized / 4 pure-supply (dig/seed-apartness/range —
  the expected ghost-supply survivors) / **0 OTHER** — stop-event
  clear, the layer's central claim MEASURED TRUE; scratch2 was the
  one new mechanism-kind (C3b's pre-priced item); T1/T2/T3
  re-housed byte-stable as 2-liners, hand wpK walks deleted;
  legacy T5 chain retired (carriers 112→104); heartbeat-poisoning
  family fixed STRUCTURALLY (keyed DiscrTree pre-selection +
  per-probe budgets — registered evidence for arc-19's Lithium
  pre-commitment). Registry census 168, sweep 8469, engine 6860
  baselined, statement slate 31. R5 COMPLETE @ 8b9365e2c (T4
  PROVED guarded, round-22 frontier DISSOLVED — artifact of the
  materialized drive; R7 unblocked, T1AppEq live-route clearance
  grep-proven). R6 BREADTH COMPLETE @ e59825cc0: census artifact
  pre-registered [F9]; 11 programs PROVED (5 easy / 4 census incl.
  first corpus loop + 2-arg / 2 edge: return-in-loop + break at
  ZERO extra composition cost) at COST FLOOR 2 manual
  steps/theorem, loops = 1 invariant (~25 ln); saturation: ZERO
  engine laws for scalars, campaign total = 1 law + 8 feeder
  lines; statement slate 55, census 327, all cones trio. FOUR
  PARKED-PRICED frontiers (committed reproducers, over-budget
  streak 0, no halt — parks are vocabulary frontiers): (1) ARRAY
  LANE S-M (PEarray_shift pure-eval at open anchors; blocks the
  uri.c scan rows → R6b); (2) CALL RULE M — root cause
  AilTypesAux.are_compatible is a generated PARTIAL DEF,
  kernel-opaque (totalization slice = R6c; FnSpec/consume + lock
  example wait on it); (3) depth cliff (20-write mint >25min vs
  90s @ depth 2 — better-abstractions item: index the mint's
  anchor states) + width cap (2 scratch ranges, analytical); (4)
  family-∀ at the already-registered C4 symbolic-file frontier.
  [USER 2026-08-27, CALIBRATION RULING]: "we don't need to make
  every example just verify_fn; auto — that's probably impossible
  for more complex functions. But it's great for simple ones! I'd
  expect some working tactics, similar to brick_wp in complex
  cases." — 2-step form = the SIMPLE-program gold standard, not a
  universal bar; complex functions may use a legible
  working-tactic vocabulary (brick-wp lineage); professor
  standard judges structural coincidence + legibility, never
  literal step-count. AND [USER]: calls — "We'll need to make the
  model total in the proper way" — R6c totalization ENDORSED
  (no-internal-trust-gaps standard move, model-proper, no hacks).
  [USER 2026-08-27, ESCALATION-LADDER RULING]: "make sure you're
  designing this so it fits with the broad Iris / refinedC / Brick
  lineage. Powerful automation available, but breakouts to more
  fine-grain tactics always possible" — standing design
  constraint: every automation level sits on named, individually
  applicable rules (brick-wp lemmas+thin-macros discipline);
  seg_auto ON TOP of working tactics ON TOP of registered laws; no
  closed black-box path — anything auto does must be reachable by
  hand. Array slice briefed accordingly (canonical
  array-points-to/carve-out shape, donor cites).
  PROFESSOR PASS RAN 2026-08-27 (notes/2026-08-27_proof-style-
  professor-pass.md): verdict PASS-WITH-FINDINGS — statements
  uniformly A, Segment.lean A- ("legible Floyd-cut-points logic"),
  flagships B+, corpus files B-/C+ on leakage+boilerplate.
  SHARPEST FINDING: corpus-tier invariants on concrete-input
  programs are CIRCULAR (at_ k := compOf(walk-endpoint k) — the
  invariant restates what the run reached; human content lives in
  comments; dead _hfind lookup) — "a costume over symbolic
  evaluation"; T5's triF (kernel-checked closed form) is the
  genuine article, proving the fix PRESENTATIONAL not structural.
  Top-3 (legibility-per-effort): (1) mint the harness spine
  (arc-19 frontier = now the BINDING legibility constraint, ~5:1
  boilerplate tax); (2) invariants CARRY VALUES, states derived
  (kills the circularity + spelling tables in user text); (3)
  seg_obligation tactic + named supplyCeil. Could-not-reconstruct
  list (5 items) = doc obligations for R8. DISPOSITION [AGENT,
  operator-visible]: improvements 2+3 = an in-arc slice BEFORE R8
  (the playbook must teach the honest idiom); improvement 1 stays
  arc-19-front; reconstruct-list rides R8. [USER 2026-08-27,
  QUANTIFIED-INPUTS RULING — reshapes the arc]: "we'll want to
  upgrade whichever of the programs we can to quantified inputs,
  and delete the rest of the examples. Concrete inputs are a
  degenerate kind of proof, uninteresting for us." Reading
  (operator-visible): the ruling targets PROOF-LAYER theorems —
  concrete-input standalone THEOREMS are degenerate (the
  professor's circularity finding is their symptom: on a
  determined run the invariant restates the walk). Concrete
  harness POINTS survive in non-proof roles only:
  differential-oracle anchors + anti-vacuity SAMPLES derived as
  one-line corollaries of the proved families (the C4
  family→sample pattern, plant-test doctrine). [USER 2026-08-27,
  THE CANONICAL PROPERTY — foundational, quote]: "We're
  specifically interested in proofs established in the CN /
  RefinedC / Floyd-Hoare / OHearn style… harness_f(init, args) {
  set_up_memory(init) // precondition; return = f(args); final =
  check_memory(init, return); return final }… forall init, args:
  f_precondition(init, args) && cerb_semantics(harness_f, init,
  args) ~~> result ==> result = some(final) && f_postcondition(
  init, args, final). From this perspective we are NOT INTERESTED
  AT ALL IN CONCRETE EXECUTION AT SPECIFIC VALUES. If we wanted
  that, we would just run the interpreter… We also don't care
  about enumerative techniques. We are doing FORMAL VERIFICATION
  here, that's the point." Machinery mapping: pre = range/
  footprint hypotheses; set_up_memory = harness prologue; exec =
  CallHarnessAdequateThr (outcome-set, stronger than ~~>Some);
  check_memory = observation-channel readback (statements never
  mention memory); post = spec. KEY DESIGN CONSEQUENCE [AGENT,
  from this ruling]: quantify init AT THE CALL BOUNDARY — the
  harness takes init as CALL ARGUMENTS and its prologue stores
  them (set_up_memory as ordinary C code), the compiled file
  stays FIXED — the already-proved T4/T5 quantification route;
  DISSOLVES most of the symbolic-file family-∀ frontier for
  fixed-size init (compiled-const streams remain for unbounded/
  structured init per arc-15 doctrine). Differential/concrete
  points = MODEL-VALIDATION instruments (TCB leg), never
  verification results — two separate ledgers. Consequence: the
  legibility slice becomes the QUANTIFIED-INPUT SLICE (M) —
  upgrade slate+corpus programs to ∀-input statements (T4/T5
  house shape) with VALUE-CARRYING invariants (kills circularity
  AND makes invariants load-bearing); seg_obligation+supplyCeil
  rides along; programs that cannot upgrade within current
  vocabulary are DELETED with the gap recorded (they return when
  vocabulary lands). The honest breadth measurement = per-program
  cost of the QUANTIFIED proofs. R6b re-briefed mid-flight: scan
  batch targets ∀-input statements (symbolic buffer contents,
  data-dependent trip counts); parks expected and honest.
  SUPERSEDING EVENT 2026-08-27: [USER] killed R6b mid-flight and
  mandated a PROFESSOR WHOLE-PROJECT ASSESSMENT under the verbatim
  aim "BUILD A VERIFICATION FRAMEWORK SIMILAR TO BRICK OR
  REFINEDC… NOT executing code at specific inputs… NOT doing
  enumeration. COMPLETELY FORBIDDEN as proof strategies."
  Assessment (docs/2026-08-27_professor-whole-project-
  assessment.md + disposition record, committed @ 764c67ba4)
  headline: "a sound, kernel-certified, Iris-carried
  CONCRETE-TRACE EVALUATOR wearing program-logic vocabulary" —
  substrate cannot cross a data-dependent branch at a symbolic
  value; missing middle (per-construct symbolic rules, assertion
  layer over locals, case-splitting executor) IS what
  BRiCk/RefinedC are; trust discipline better than donors'.
  DISPOSITION [USER 2026-08-27]: (1) KILL LIST RATIFIED +
  EXECUTING (26 concrete theorems incl. T6/T7 pairs + 22 corpus,
  4 parked reproducers, ambient slate + chase ~10k lines, ~240
  literal-address supply entries, spec-lab 23 sample defs,
  EXEC-EQUATION CAMPAIGN CANCELLED-not-parked; kill-now vs
  killed-by-registration split for KEEP-load-bearing items, sole
  expected deferral = whole-run mint mode carrying kept T1–T5
  proofs); (2) conversion table TO-BE-RATIFIED (KEEP: Seg
  algebra, FnSpec, heap RA, WP rules, Kit laws, registry,
  adequacy, T1–T5 statements, codecs, gates; CONVERT: restIs
  decomposition L, per-construct rules M-L, RoundEval chassis →
  case-splitting symbolic stepper L); (3) build plan B0–B6
  TO-BE-RATIFIED (B0 ban gate S → B1 assertion layer L → B2
  per-construct + case-split THE HEART L → B3 automation → B4
  calls → B5 predicate invariants, acceptance = corpus restated
  ∀-input → B6 purge remainder; supersedes remaining R-ladder on
  ratification). Orchestration lesson logged: the R6 brief
  anchored on the concrete fixture pattern and measured
  steps-per-theorem without requiring quantifier structure — the
  professor's circularity finding + [USER] caught it; the B0
  mechanical ban gate is the fail-closed fix. THE RESTART PLAN
  [USER 2026-08-27, the five steps — the new master sequence]:
  (1) target examples from CN and RefinedC, harnesses exercising
  them at ARBITRARY INPUT MEMORY via the const-embedding pattern;
  (2) theorems over these that "clearly unambiguously and with no
  doubt whatsoever" require ALL the complexities a program logic
  handles (memory, looping, calls, returns, arithmetic, pointers,
  …) — a TINY target corpus requiring all reasoning families real
  C needs; (3) AGGRESSIVE REVIEW of exactly this corpus: small
  but challenging? actually defined to exercise the required
  reasoning? does passing it put us on the way to a verifier? any
  concrete-input garbage hints?; (4) FREEZE AND CANONIZE — all
  target-corpus changes forbidden without USER-level sign-off
  (mechanical freeze gate); (5) professor-level planning for the
  infrastructure that handles this corpus. Reading [AGENT,
  operator-visible]: steps 1–5 SUPERSEDE the pending
  (2)-conversion-table and (3)-B-plan ratifications — both become
  INPUTS to step 5's plan, judged against the frozen corpus; the
  kill-list execution continues unaffected. License: corpus
  derivations from BSD sources (deps/cn tests BSD-2, refinedc
  BSD) with per-program attribution; GPL stays out. [USER
  2026-08-27, ANTI-GATE-GRIND RULING]: "we don't want to end up
  in 'gate grind' — mechanical gates can just pile up. Let's just
  get the corpus figured out." Calibration: gates are reserved
  for load-bearing TRUST properties (cones, statement TCB,
  fork-drift); discipline points get DOCUMENTATION notes and
  STRUCTURALLY-FORCING examples instead (inlining-not-legit = an
  inline note on the contract program + recursion (fib/fact) as
  the structural backstop — the contract IS the induction
  hypothesis, no inlining possible). No per-concern gate
  proliferation; reviewer re-briefed accordingly. KILL LIST
  EXECUTED 2026-08-27 @ 24987aa12+820d87748 (orchestrator
  re-verified): 40 .lean files deleted, ~18,600 lines removed —
  all 26 concrete theorems, ambient slate + arc-7 shell + chase
  tactics, 30 speclab sample defs, exec-equation campaign
  CANCELLED in PROOF.md; runEffectful CARRIER REGISTER = ZERO
  (axiom endgame complete — the residual boundary item is outside
  every cone in the repo); one-route OwnP register EMPTY;
  check_chase_freeze.sh DELETED (allowlist emptied); census
  328→166, sweep→6024, slate 55→13, test_verify re-baselined
  133→63 (all 22 fixtures KEPT on the test ledger); T1–T5
  threaded statements byte-stable, cones trio-exact.
  Killed-by-registration deferrals (trigger = B-plan re-proof):
  whole-run mint mode + T1–T5 walk engine rooms (T1-T3AppEq
  SPLIT: carriers deleted, trio-clean supply renamed T?Walks),
  iter_compose (conversion unratified), runEffectful (lem-side,
  zero-carrier). Salvages: the `within` byte law; C9T's ∀-x
  statement shape banked as a B5 acceptance row. CORPUS v2
  READY-TO-FREEZE (15 programs + gcd_rec recommended over rsum;
  all samples oracle-verified; π-skeleton verified dodge-proof;
  freeze package + 6 sign-off questions PRESENTED, awaiting
  [USER]). Catechism carries the intended-design stack ([USER]:
  executable semantics ⇧ relational ⇧ Iris ⇩ target; statements
  anchor at layer 1, proofs travel down through adequacy).
  CORPUS FROZEN 2026-08-27 @ 3b2352485+83b733c08 ([USER]: "the
  corpus as proposed looks good") — 15 programs + gcd_rec
  confirmed, hash-manifest freeze riding check_proof_size
  (plant-tested both directions), catechism BLESSED in-repo.
  STEP-5 INFRA PLAN delivered (notes/2026-08-27_infrastructure-
  plan.md): components A–H, slices V0–V6 with corpus-row exits;
  [USER] blessed all six recommendations EXCEPT Q3 AMENDED:
  FRESHNESS GUARDS DIE AT V0 (consistency-predicate form +
  anti-vacuity metatheorem; the counter stays the executable/
  differential face; the SL/alloc UNIFICATION stays gated at V5
  per the Caesium design evaluation). KILL-QUICK ADJUDICATION
  RATIFIED [USER 2026-08-27]: "go ahead with the aggressive kill
  plan… We want to leave real gaps as real, not leave them
  looking valid when they're not" (THE HONEST-GAPS PRINCIPLE,
  verbatim, standing): (1) T1–T5 WALK ENGINE ROOMS + WHOLE-RUN
  MINT MODE KILLED NOW — the repo temporarily has ZERO proved
  flagship theorems (statements stay honest-unproved; V2/V3
  re-prove; V1 keeps a minimal adequacy smoke); (2) iter_compose
  dies V0; (3) R1/R5 family-∀ speclab targets die V0 (the frozen
  corpus is THE target slate); (4) arc-18 R-ladder formally
  SUPERSEDED (charter banner); (5) --args flag iceboxed; (6)
  enum-ctype demoted to parser-completeness; (7) runEffectful
  fate decided by the V0 call-site census; (8) FF-1 probe-recipe
  fix promoted to V0; (9) oracle allocation-census scheduled with
  V5 (P13's leak leg); (10) PROTOTYPE ARCHIVED [USER]
  (reduce-to-oracle option closed; no further maintenance). V0
  COMPLETE @ 80fb47ef0 (orchestrator re-verified): 31-row slate
  honest-unproved in ConsistentRun form (14/15 corpus; P13 → V5
  alloc-ND gate; P06/P08 wf 1≤|xs| deviation = OPEN [USER] freeze
  question), concrete-input ban live in-build (4 negative probes),
  kill basket executed (engine's first shrink 6964→6318), censuses
  done (are_compatible heads V4; runEffectful 8+1 split), FF-1
  fixed (scripts/lean_probe.sh). V1 IN FLIGHT (assertion layer,
  L): FIVE-component decomposition (ctl / env-ghost_map / supply /
  memRest / heap); projection wall hit + resolved CANONICALLY
  (existentially-quantified auth env + lookup-level COHERENCE
  invariant; Fmap captured-closure obstruction documented);
  runtime cell-birth scoped to V2 (near P01's path, in that
  brief). [USER 2026-08-28, THE LOCALITY-RETROFIT FRAMING]: "This
  is actually where the real work lives for Cerberus —
  retrofitting locality onto the real C model (rather than
  RefinedC's easier semantics) is difficult… the refinedC proofs
  definitionally must have solved some of these issues, so feel
  free to take inspiration." Standing consequence: locality
  obligations (per-primitive coherence preservation, the alloc
  global-freshness bridge, address observability) CITE Caesium
  counterparts (ghost_state.v heapGS/wf invariants, lifting
  lemmas, alloc/alive machinery — BSD, mirror with attribution)
  and DOCUMENT THE DELTA where Cerberus demands more — the delta
  is the project's genuinely novel content, kept visible as such.
  V1 COMPLETE 2026-08-28 @ d19d50ca3..9afcd8cf4 (orchestrator
  re-verified; all 5 exits): CerbStateRA 6-part decomposition
  (bytes/allocs/env-ghost_map/ctl/supply/memrest; Caesium mirrors
  cited file:line, deltas in record §4 — Fmap coherence-relation
  vs their exact projection; env has NO Caesium counterpart,
  their locals are heap; fused-interpreter step characterization
  = ctl-token inversion + Kit crossings + THE F-TRICK, the V2
  rule layer's seed); general adequacy + Thr/Cns bridges
  trio-pinned; THE EXHIBIT demo_wp/demo_adequate GREEN (x at
  SYMBOLIC vx survives the real y-rebind round BY FRAME; layer-1:
  ∀ vx w0 w supplies, every runND outcome = value vx); THE DELETE
  executed (restIs route −4,163 lines, old tokens gate-banned,
  one interpretation again); Tier A 16/16, statements
  byte-stable, engine SegmentFaces 1176→656. Honest gaps with
  movers (record §6): env-cell BIRTH mid-run (V2, near P01),
  FnSpec Thr-face + dormant verify_fn (V2 re-target),
  mono-counter supply (chartered), write-ladder ghost move (V3a),
  multi-thread coherence (cmm). V2 COMPLETE 2026-08-28 @
  ..289b0b70b (orchestrator re-verified after fixing an
  in-tree-scratch D14 false trip — worker logs relocated to
  container .v2-logs/, the arc-17 logs-at-container rule
  re-learned; sources clean): **P01 THE EMBLEM PROVED** at the
  frozen statement (∀x clamp = max(x,0); by_cases at the symbolic
  compare, path condition as pure fact, frame carries memory
  across the branch; user text = `verify_fn p01FnSpec; exact
  p01_wp…`, cone trio) + UB twin; T1/T2/T3 re-proved per-round
  (T3 = create/store/kill through NEW alloc/store/kill round
  rules, HeapLang lineage); verify_fn revived at Cns faces; birth
  = ledger-certified (domain-ledger 7th component,
  instance-GENERIC legs — the Fmap instance-spelling wall's
  reusable fix); case-split landed as the by_cases idiom (rounds
  deterministic given path condition — no wpk_if_split lemma
  needed, recorded); census 99 laws, statement gate 31, Tier A
  green. PARKS: **P02 parked on the GRIND-SHAPE FINDING**
  (measured 63–117 rounds × 4 paths ≈ 4× P01's per-round text;
  species-3 — the missing deliverable is the SEGMENT RULE
  consuming round supply once; park APPROVED [AGENT], the
  clause-(d) mechanism working); P03 parked pre-authorized (call
  frames, M, V4-adjacent); per-fixture proof files (p01_wp 1387
  ln) UNREGISTERED at proof-size gate — OPEN FINDING, mover = the
  segment slice (files register when they shrink). Instrument
  incident self-reported + fixed (fail-open probe grep; exit
  codes now checked). V2b DISPATCHED: THE SEGMENT/STEPPER SLICE
  (block-fused segment rules consuming round equations once + the
  cut-point stepper tactic; acceptance = P02 proved + P01's
  engine file collapses; then V3a). M1 in @ 73c8379c6: SegRun
  fused rules, T1 body = ONE chain @ ~6 ln/round vs V2's ~40,
  escalation ladder intact (link rules delegate to registered
  rules). [USER 2026-08-28, OPERATING MODE]: "If you're making
  progress, you can keep rolling — you only need to check in with
  me if we're not making progress towards the end-state. Keep a
  close eye on the results for signs of 'cargo cult iris' i.e
  Iris in form but not substance in the various ways we've seen
  before." STANDING AUTONOMY: slices chain without awaiting
  sign-off while progress toward 15/15-at-clause-(d) holds;
  check-in triggers = stalls, walls beyond price, design
  findings, cargo-cult signs. THE CARGO-CULT-IRIS WATCH
  (operational signs, from the observed disease forms): (a)
  assertions/invariants that RESTATE computed state rather than
  constrain (the circularity form); (b) rules whose premises
  secretly demand ground data (symbolic in name only); (c)
  ceremonial framing (everything in the footprint — whole-state
  pins wearing ∗); (d) case-splits that only fire at closed
  discriminants; (e) ghost state that MIRRORS state rather than
  abstracts (coherence/ledger smuggling whole-state reasoning);
  (f) per-instance WP lemmas in rule costume (enumeration); (g)
  bridges that only discharge at closed programs. INSTRUMENTS:
  generalization probes on never-seen programs, clause-(d) mass
  ratios, the V6 professor pass, and a CARGO-CULT SPOT AUDIT at
  the V3 boundary (fresh reviewer, substance questions: is envIs
  consumed at symbolic values in anger; is the frame rule
  load-bearing or ceremonial; do the fused rules fire on a
  program they weren't built against). BUILD-ECONOMICS:
  ACTIVE-BINDING (2026-08-28, operator-flagged from throughput
  data — V2b worker ~55k tokens/hr vs ~400k for
  reasoning-dominated slices ⇒ ~85% wall-clock waiting on the
  checker; orchestrator's "not yet binding" call was WRONG,
  conceded). Immediate: per-file probes for failure discovery
  (chunk builds = background confirmation only), mandatory
  overlap, one measured 2×48G parallel-build experiment.
  Structural (V3a item #1, PROMOTED): named/indexed machine-state
  constants (the giant-terms fix — cuts elaboration AND enables
  safe parallelism) + block-granular supply generation (~5× fewer
  lemmas). Orchestrator batteries scoped for supply/docs-only
  deltas (full battery stands for build-rule/gate changes per
  certification-integrity). [USER 2026-08-28, THE SCALING-CREEP
  RULING, verbatim, standing]: scaling is "EXACTLY the point
  where previously a bunch of garbage forbidden hacks and
  cheating has started to creep in… we're going to actually do
  this properly." Performance work = the maximum-risk surface for
  the forbidden classes; perf plans are DISCUSSED before
  dispatch and adversarially reviewed before execution. [USER
  2026-08-28, THE CLASSICAL-NAMING RULING]: every proposed
  optimization must be identified in CLASSIC PL TERMS
  (abstraction? memoization? sharing? reflection?) and its
  legitimacy understood BEFORE imposing — "optimizations which
  couple to the representation structure without insight are
  absolutely totally and completely forbidden, and making up your
  own terms ('seal engine') is also forbidden." A mechanism that
  cannot be named classically is presumptively a hack; house
  jargon for mechanisms is BANNED — textbook names only. (Seal-
  era classification: legitimate kernel = SHARING/let-abstraction,
  classical + semantics-preserving; illegitimate part = steering
  the kernel's unfolding order without a model — prong-2
  coupling. The discipline extracts the kernel, refuses the
  coupling.) PERF-PLAN AGENT AUTHORIZED [USER]: (1) how RefinedC
  scales (closest analog); (2) our representation + the V2b
  branch; (3) the fix AT THE IRIS LEVEL (judgment/logic level,
  never term hacks). Plan → adversarial review → operator
  sign-off → execute. EXECUTED: plan (notes/2026-08-28_proof-
  performance-plan.md — mechanisms all classically named; C =
  functional-big-step→small-step characterization, Owens–Myreen–
  Kumar–Tan lineage) + hostile review (…-plan-review.md, verdict
  SOUND-WITH-AMENDMENTS A1–A11: PERF-2 exit tightened
  [syntax-cited cut points + structural bound + pre-registered
  never-seen program], CC2 re-attributed to CHAIN SHAPE not
  arena size, r257 = undiagnosed possible 4th cost center to
  triage, Lithium L1 corrected [A+D jointly kill CC1], opacity
  needs light enforcement, V3a-folding gets a probe-no-go ramp;
  mechanism C ADJUDICATED AUTHENTIC — the steering test passed
  by construction). [USER 2026-08-28] SIGNED OFF: "extremely
  reasonable. Let's do it. Be a bit careful of gate grind here,
  we don't need to 'solve' adversarial optimization" —
  enforcement stays LIGHT (opacity ban = one grep line riding an
  existing gate; exit definitions are measurement discipline,
  not new gates; no policing apparatus). PERF-0+1 COMPLETE
  2026-08-28 @ 987f7905f..836fb5fd4 (orchestrator re-verified,
  tree clean): **P02 PROVED** at the frozen statements (trio
  cones; the V2 park dead; corpus 3/15 + 4 T-flagships). THE
  PROFILE VERDICT: cost ~100% elaborator tactic execution (kernel
  34.5ms TOTAL vs 237s); dominant center = step-discovery
  Meta.whnf re-derived per unification; Kernel.whnf runs the
  IDENTICAL term in 8ms (~8,600×). Fix = seg_discover
  (kernel-pinned discovery equations — sharing + ACL2Lean
  kernel-leaf pattern, ordinary rfl, no ofReduce*, no steering) +
  arm-form committed keys + 18 @[seg_block] fused facts (Floyd
  composition at generation time). EXITS MET: supply closure 52+
  min → 147.3s (21×; ≤300s target, 2× headroom); SLOW register
  DELETED 26→0 (budgets removed, not shrunk); 2×48G parallel =
  2.85× @ 2.2GB peak; r257 triaged = CC1 wrong-form, no 4th
  center. Honest residuals: fusion 48/349 (birth-block extension
  priced), 2 rfl spelling bridges (mC path), proof files over the
  250 bar (deferred to segment rules, bar NOT raised).
  [USER 2026-08-29, Q1 SETTLED after full technical discussion]:
  BRIDGE ROUTE A RATIFIED — the three-piece structure agreed:
  (i) guarded WP under the WindowApart pure precondition =
  ordinary hypothetical judgment, logic unchanged; (ii) the
  supply-tracking walk conclusion (draws = [seed,seed+B)) = a
  minted semantic fact; (iii) ONE transport lemma equating
  ConsistentRun (run-level) with WindowApart (arithmetic) =
  classical DATA REFINEMENT of ND freshness by the counter. The
  logic assumes freshness by fiat; the machine delivers it only
  on the consistent family; theorems quantify exactly there.
  Executable runs are always consistent (draws small, hashes
  ~1e17; anti-vacuity proved); bad runs = mathematical points at
  adversarial seeds; static-static collisions = parse fail-stop.
  EQUIVARIANCE REGISTERED [USER]: "seeds don't matter" (all
  consistent runs observationally equivalent; the exercised run
  their canonical representative — CompCert renaming lineage;
  plausible since observation channels are symbol-free; the
  ADDRESS analogue is measurably FALSE per PNVI) is "a theorem
  that's true, but we haven't proved yet… we can prove it
  later" — L-class simulation, OWNER = the cmm arc (its
  ND+filter formulation needs the representative-run argument
  anyway); side benefit when proved: oracle runs become evidence
  about the whole family. NOT on the corpus critical path.
  [USER 2026-08-29, Q2–Q6 RULED]: Q2 — alloc-ND design
  evaluation is RESEARCH NOW ("this problem has been richly
  explored in separation logic / iris, so we should draw on
  that") — agent dispatched (SL/Iris allocation literature +
  Caesium reference + the August subtleties list); Q3 professor
  cadence as recommended (sample post-arrays, full at 15/15);
  Q4 polish basket BINDING before any fourth program; Q5 P13
  registration at heap-summit-open; Q6 EXTENDED — "build a
  further corpus intended to exercise these features. Go
  hunting, basically" + "exercise the existing features across
  some more small examples, try to shake out bugs": CORPUS-2
  authoring dispatched (the unowned-tail features, SAME pipeline
  as corpus-1: author → adversarial review → operator freeze;
  corpus additions need [USER] sign-off by the freeze rules) +
  a SHAKEOUT CAMPAIGN (more small programs over covered
  vocabulary, quantified statements only, budget-disciplined —
  doubles as the polish basket's validation corpus; sequenced
  post-bridge). MERGE: audit MERGE-SAFE zero-MAJOR (3 MINOR
  fix-forward LANDED @ b7035a195 — incl. a worker integrity
  catch: refused to label a nonexistent t1_ubfree as proved;
  freeze gate addition-blind-proofed, plant-tested); awaiting
  explicit [USER] per-merge sign-off. [USER 2026-08-29, THE
  CONTRACTS-PRIMACY RULINGS — the malloc-null colloquy, banked]:
  (1) MODEL-REFINEMENT LEDGER created: ISO nondeterminism the
  model resolves one way must appear as explicit precondition/
  outcome/scope line, NEVER ambient assumption (entries:
  malloc-failure — remedy = harness failable-allocator wrapper,
  F1 RE-SCOPED not withdrawn, p24 drafted; address-reuse —
  conservative for UAF, uncovered = reuse-observation-via-cast,
  tray remedy); (2) the "exhaustion unreachable ~2^60" framing
  STRUCK (reachable in few steps via large requests;
  boot-anchoring licenses nothing); (3) [USER verbatim]: "There
  isn't really a distinction in hoare logic between compositional
  and non-compositional reasoning. Compositional is the only
  thing you get. There's no magic 'boot context'" +
  main-is-not-boot + "composition first, logic first, 'for any
  context'": CONTRACTS ARE PRIMARY — FnSpec ∀-ambient-context =
  the verification artifact; harness theorems = DERIVED
  COROLLARIES at a stated init (the observable/differential
  face, legitimate as explicit scope only). DAMAGE ASSESSMENT
  delivered: rules/adequacy/RA layers CLEAN (built ∀-context);
  the bias lives in proof ARTIFACTS (body lemmas/minted supply
  anchored at harness-specific ambient families = one context
  enumerated). CORRECTION: (a) bridge brief amended pre-dispatch
  — T5 stated contract-grade day one; (b) generalization pass on
  the 6 existing proofs rides the polish basket (S-M; the minter
  regenerates anchors anyway); (c) allocation headroom =
  space-credits-or-robustness decision at V4 FnSpec design (now
  the build's load-bearing design event); (d) ACCEPTANCE
  AMENDMENT pending [USER]: a corpus row counts when its
  ∀-context contract exists AND the frozen theorem derives from
  it; (e) catechism composition-first addition rides the
  sign-off bundle. CORPUS-2 REVIEW: REVISE-THEN-FREEZE, 8×
  ACCEPT all-textual (no corpus-1 disease recurrence; C2 factual
  fix: switch = if-dispatch + save/run, zero Ecase; bitfields/
  u64/enums flagged table holes); revision pass dispatched incl.
  p24 + primacy reframing; freeze package to [USER] after the
  delta re-review. V3a
  [USER 2026-08-29, THE LOGIC-FIRST RULING — the top-level goal
  restated, verbatim]: "there's a 'logic-first' design pass
  needed which involves treating the rules of the logic as the
  real first-class artifacts, and then ripping out any
  specialization to the harnesses that has crept in. To say
  again, the top level goal here is to design and prove *the
  logic*." THE DELIVERABLE OF THE PROJECT = THE LOGIC: a named,
  presentable program logic for Cerberus Core — judgment forms +
  the rule figure, every rule a ∀-context kernel theorem —
  with harness/corollary machinery strictly downstream
  APPLICATION, and crept harness-specialization ripped out.
  [USER 2026-08-29, THE ANTI-INNOVATION RULING — verbatim,
  standing, sharpens mirror-donor into a review criterion]: "if
  we're doing something different from RefinedC / Brick, why? The
  default should be do what they do. Don't invent stuff that's
  unnecessary. Innovation is bad, innovate only when necessary,
  by default do what previous logics have done, unless the needs
  of Cerberus force a different choice. And even then, we should
  ask is this a real cerberus constraint, or a BS constraint that
  comes from some previous mis-design choice." Every divergence
  is audited into three bins: UNNECESSARY INVENTION (adopt
  theirs) / REAL CERBERUS CONSTRAINT (forcing fact stated, about
  Cerberus not our machinery) / INHERITED PSEUDO-CONSTRAINT
  (traces to OUR prior design choice — name it, price its
  revisit; the most valuable finding class, never hidden in bin
  2). The paper-logic review carries this as a first-class
  section. PAPER LOGIC DESIGNED + HOSTILE-REVIEWED (notes/
  2026-08-30_core-logic-paper.md + -review.md): verdict
  RATIFY-WITH-AMENDMENTS — 5 MAJORs, ALL one species: rules
  written against IDEALIZATIONS instead of the
  model-as-executably-is (label scoping vs procedure-wide
  resolution; totality/variant broken twice; E9b unsound vs the
  join-time race check; M8/M9 vs the PVI reality; 2 missing
  memops) — the paper's own §B.5 discipline is the fix
  everywhere; citations verified exemplary; expressiveness: all
  15 corpus rows + p24 expressible. DIVERGENCE AUDIT bin-3
  headline: the ENV-CELL SORT = inherited pseudo-constraint (its
  forcing fact was the INTERPRETER's env, not Core's meaning;
  binders immutable; substitution-everywhere was the missing
  menu option). [USER 2026-08-30, DN-1 RULED]:
  **SUBSTITUTION-EVERYWHERE in the logic, environment-as-
  engine** — "Push the abstraction higher, don't lose any
  reasoning, support a cleaner reasoning layer." Env cells/
  births/ledger/coherence LEAVE the figure — they become the
  engine's proof technique inside the per-construct
  environment≈substitution correspondence lemmas (mechanism-C-
  shaped; V1's machinery demoted-not-wasted); label jumps =
  INSTANTIATION (RefinedC typed_block shape — the V3a rebind
  class DISSOLVES); correspondence family priced M-L + two
  pre-commit probes (label-args reading vs the model; Core
  subst feasibility). v2 revision IN FLIGHT (all MAJORs + DN
  adjudications + [USER 2026-08-30] the FLEX section: pivot
  axes — partial-correctness sibling, cmm re-entry seams,
  PNVI-switch additivity, contracts-promotion, the substitution
  exit ramp, weak-memory non-foreclosure — each with a
  revisable/foreclosed verdict). [USER 2026-08-30, FRESH-EYES
  REVIEW RULING — process, standing]: "we should do a *fresh*
  re-review… We shouldn't converge through implied agreement…
  this is the core document for the whole effort" — v2 gets a
  NEW Fable-class reviewer (not the v1 reviewer, not the
  designer), FULL review not a delta pass; criteria: coherent
  with what Cerberus actually gives us / will work / sound / a
  clean Iris-based logic / the flex assessment. STANDING RULE:
  core documents at major revisions get fresh full reviews,
  never same-reviewer delta convergence. Then → THE RATIFICATION
  CONVERSATION (logic v2 + rip-out inventory + graveyard kill
  list ~12.4GB + restructuring 7.1–7.6) → the reframing-and-
  prune slice → ONE merge to main. Design-pass SCOPE UNDER
  OPERATOR DISCUSSION before any
  commissioning — [USER 2026-08-29]: "don't commission the pass
  before we've decided what to do in it" — the SECOND instance
  of this orchestrator error (first: the perf plan); STANDING
  RULE hardened: design-level passes get their scope DECIDED
  WITH the operator before any agent is briefed; a brief is a
  bundle of decisions, not a substitute for the conversation. V3a
  DISPATCHED (PERF-2 folded): mechanism C probe-first
  (functional-big-step characterization, 2-3 constructs, NO-GO
  RAMP, kernel-pin device reused) → loop rules (save/run + Seg
  composition + the VARIANT rule) → exits: T5 re-proved at ∀-n +
  P11 (gcd variant) + the TIGHTENED PERF-2 exit (pre-registered
  never-seen program, zero generated per-round facts, structural
  bound) + birth-block fusion extension. [USER 2026-08-28, THE
  JUDGE]: "The best judge of this is the adversarial professor
  class audit. Get a subagent to role play as the PL expert, get
  them to poke and prod. Not needed now, but use this as needed
  to shake out 'form but not substance' bugs." — the ADVERSARIAL
  PL-PROFESSOR AUDIT is the designated cargo-cult instrument,
  deployed AT ORCHESTRATOR DISCRETION (as-needed triggers: any
  watch-sign observed, a new abstraction layer landing,
  pre-merge; scheduled: the V3-boundary spot audit and V6 both
  run in this mode — fresh agent, PL-expert persona,
  poke-and-prod brief against the substance questions, findings
  not grades). [USER
  2026-08-27, ANTI-BRUTE-FORCE BOUNDS RULING]: "we don't need to
  cap at all, just make it some insanely large number that fits
  in the type. In general, the code can be small but we SHOULD
  NOT pick values that could be brute forced." Every corpus
  precondition bound = the largest value the type admits; where
  overflow-safety forces tighter, DERIVE from the type limit and
  document (65535-scale, never 100-scale). The test for every
  constant: if enumeration is even conceivable as a strategy, the
  bound is too small. (Supersedes the reviewer's CAP=100
  suggestion; author re-briefed mid-revision.) Prior
  `1bd65e295` CN-0 spec-AST exporter merged
  2026-08-24: `--cn-spec-json` oracle output mode, off-by-default,
  zero-movement proven, drift-manifest 59 files; headline finding:
  the CN grammar is IN the fork's parser and the CN AST is
  LEM-GENERATED — CN-2's Lean AST comes free from lean-prelude-src.
  CN ladder + dispositions: notes/2026-08-24_cn-on-iris-
  investigation.md. Prior `5014fc4ae` post-mortem+charter; prior
  `48fd90d37` review-path docs merge: the
  two-minute tour + the C-to-theorem trust chain, professor
  coherence-passed; the harness-template, stepper-design, and
  WireGuard-scoping notes live in lean_frontend/docs/ with the
  container copies as operator working copies; prior `5f4d9cb4e`
  shop-window docs merge
  2026-08-23: lean_frontend README/DESIGN/PROOF/TODO + provenance +
  CLAUDE.md prune, professor-audited A−; prior `39aabec47` arc-15
  three-stream merge). opam
  pin (`deps/lem-pinned`, branch `cerberus-pin`) and the Lake manifest
  both point at `861ed81` (arc-14 close pin dance; lem untouched
  since).
- Gates in `./scripts/test_unit.sh` (all enforcing): exec-slice purity
  + theorem-axiom cones + exec-slice totality + hand-written↔generated
  sync + axiom censuses + unsafeCast ban + lem-sync content-hash +
  fork-drift (manifest + pinned generated diffs vs
  deps/cerberus-upstream) + proof-size. Differential gates:
  `test_exec.sh` (106 baseline), coverage, `test_multi_tu.sh`,
  `test_libc_exec.sh`, `test_libxml2.sh` (Tier B),
  `test_libxml2_uri.sh` (16/16 GATING), `test_cn_coverage.sh`
  (213-entry baseline), `test_immaculate.sh`, tests/float +
  tests/bytes + csmith lanes, the 5 `test_speclab_*.sh` lanes,
  `test_ci_sweep.sh` (reporting instrument). Ladder tiers are
  normative: `cerberus-lean/scripts/LADDER.md`. Any test_core red is a
  regression (106/106 since arc-6).
- **Effectful/extern gotchas:** BaseIO externs follow the Lean ≥4.29
  world-erased convention; Lake does not track `native/*.o` as link
  inputs (`make lean-native-obj` after any native/*.c change — stale
  .o fail-stops via the fresh-counter floor); instance fields can't
  carry attributes, so effectful calls inside instance methods are
  only protected one level down.
- Prototype `test_interp.sh`: 100% on tests/minimal; 13 failures on
  upstream tests/ci (WIP coverage gaps; prototype disposition —
  reduce-to-oracle vs archive — is an open roadmap item).
- Offline caveats: `opam install` of NEW packages and `lake update` of
  the scoped `batteries` need network; everything installed/cloned
  works offline. Manifest-driven `lake build` is fully offline.
- opam in the sandbox (nono profile claude-local ≥1.7.0):
  install/reinstall/upgrade/pin of LOCAL-source packages work
  in-session; `~/.opam/config` is read-only, so switch create/remove
  and default-switch changes are operator-run. Update lem after a
  lem-lean commit: `git -C deps/lem-pinned reset --hard <commit>`
  then, from `cerberus-lean/`:
  `opam upgrade --switch=. --no-depexts lem` (path form required —
  it is a LOCAL switch; `--no-depexts` because system-package
  detection fails in-sandbox).
````````
