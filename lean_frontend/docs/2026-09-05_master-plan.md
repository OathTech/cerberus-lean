# Master plan — remaining work on cerberus-lean and lem-lean (2026-09-05)

Written by the orchestrator [AGENT] at the operator's request ("land the
branch, then write a 'master plan' doc with the remaining lem + cerberus
tasks, then pause for a project review" [USER 2026-09-05]). Every item
below points at the record or register that carries its detail; sizes are
S ≤ ½ day, M ≤ 3 days, L = an arc of worker time. Rulings are cited with
[USER] provenance; sequencing and prices are [AGENT].

## 0. Where we stand

- **Mainlines.** cerberus-lean `mdd/cerberus-lean` @ `56b3c9e90`; lem-lean
  `mdd/lean-backend` @ `f6542f8`. Two-repo invariant CLOSED: Lake pin =
  opam lem = `deps/lem-pinned` = lem mainline = `f6542f8`. Neither pushed
  since the operator's last push (pushes are operator actions).
- **The product.** An executable Lean port of the Cerberus C semantics,
  generated from the same `.lem` as the OCaml oracle, hand-written seams
  mirroring the OCaml line by line, validated by differential execution
  (the Tier A/B battery: ~3,500 programs, whole-line verdicts incl. UB
  location, stderr, stdout bytes; gcc as a second oracle on 1,963 points;
  immaculate pins; libxml2; CN corpus). Zero baseline movement at every
  merge since the 2026-08-31 baseline except the ruled fixes.
- **Trust base.** Zero axioms in this repo and LemLib (gate-enforced);
  kernel-only proof methods (gate); 15 opaque boundary rows (down from
  26); the ISO-fix register at three entries (R1, R2, R3 by class —
  [USER 2026-09-05] confirmed); exception classes (a)–(d) unchanged; the
  OCaml generated tree byte-identical to upstream's lem output at every
  merge (fork-drift manifest, 71 files / 22 pinned deltas).
- **The reasoning interface (the customer's).** Fuel is a quantified
  `[LemFuel]` parameter reaching only the partial core: of 81 fuel'd
  workers, 54 are MEASURED (fuel-free, kernel-checked sufficiency, 7
  under a reviewed hypothesis), 13 ABSORBING (typed kill at exhaustion),
  6 unreachable, 8 registered pending (`scripts/fuel_forms_pending.txt`).
  `∀ fuel` theorems are TRUE on every measured/absorbing path. The switch
  surface is plain defs of the default configuration (no opaque reads on
  the exec cone).
- **Records.** Every slice has a dated record, a pre-merge audit and an
  orchestrator boundary review on the mainline; consumer change manifests
  for every re-pin (C1–C4, Z1, Z2, CerbGlobal). Rulings: `DESIGN.md` §4
  ("No magic values", the referent ruling, the four aims in
  `VALIDATION.md` §0), the dated ruling notes.

## 1. Definition of "stable" (the exit the plan aims at) [AGENT proposal]

1. The fresh-noodler convergence test passes: a new adversarial agent
   with a new brief and no access to earlier probe corpora finds ZERO
   C-reachable execution discrepancies, and the whole-line lanes hold
   at zero movement over a full re-sweep ([USER 2026-09-03]: "probably
   correct, but bugs are still possible" is the phase we are leaving).
2. The trust-surface risk map (§3.4 below) reports every surface
   unmoved or moved-with-ruling, with evidence not citation.
3. The fuel register is empty except rows blocked on UPSTREAM bugs
   (`are_compatible` ×3), and every failure site on the exec cone is
   typed-absorbing, proven-unreachable, or in the failure register.
4. The lem declare family is consolidated (§2.1) and the lem submission
   is reviewable by the upstream team.
5. The upstream tray is filed (operator's network window).

## 2. lem-lean — remaining tasks (owner: the sequential orchestrator's lem worktree)

| # | Task | Why | Size | Depends on | Record |
|---|---|---|---|---|---|
| L1 | **Declare-family consolidation** (~10 Lean-only forms → termination / ambient / consumer-mark / supply / representation; readers carried as typeclass instances like `LemFuel`; manual rewritten once) | [USER 2026-09-04] "definitely worth doing before we get to stable"; upstream reviewability (aim 4) | M | after C4 (done) — START NOW; before the upstream submission | lem TODO row 18 |
| L2 | **`failure_outcome` declare** for the 59 generated monadic failure sites (payload = the enclosing monad's absorbing element), DESIGNED INSIDE L1's grammar | typed-failure ruling [USER 2026-09-05 "lowest risk"]: the generated half of the monadic group | S–M (inside L1) | L1 | `2026-09-05_typed-failure-outcomes-design.md` R1 |
| L3 | Fuel monotonicity generation (per-function `f_completes` + `f_mono`) | consumer's request §3 bullet 3; today hand-proved per use | L | L1 (vocabulary) | lem TODO row 13 |
| L4 | Strings-as-bytes (F2) — the last lem-vs-OCaml representation gap; two parity rows are registered XFAIL | zero-discrepancy rule for lem-lean | L | none | `2026-09-03_string-representation-design.md` |
| L5 | `Pset` laws, `remove`, `bindings = toList` for the consumer | follow-on to the Pmap laws | S–M | none | lem TODO row 19 |
| L6 | Small TODOs: non-Prop hypothesis at generation (row 20), `sizeOf` in hypotheses (21), point-free `lemTail` global reservation (22), hypothesis-register mechanics (23), Ott derived artifacts (5) | hygiene | S each | none | lem TODO |
| L7 | **Upstream submission prep**: the declare family (post-L1) as an upstream-reviewable patch series; the lem/01 reproducer executed; the `nonlean-regress` net as the "OCaml untouched" evidence | aim 4; the Cerberus/Lem team's review | M | L1 | `doc/lean-backend/README.md` |
| L8 | Perf: measured-wrapper cost (eager measures, ~7% CPU on one row) — cheaper sufficient measures (`if refsOf ty = [] then …`); lazy-measure scheme only if the Tier C timing says so | [USER 2026-09-05] accepted <10%; trust-surface bar for any scheme | S–M | Tier C timing (C-P1) | C3 record §8.4, C4 F-A6 |

## 3. cerberus-lean — remaining tasks (owner: the sequential orchestrator)

### 3.1 Close-out of the current arcs
| # | Task | Why | Size | Depends on | Record |
|---|---|---|---|---|---|
| C-TF1 | **Typed-failure seam slice**: the 7 `memM` failure sites → the memory monad's error (the driver already turns it into the kill); `panic!` → loud `failwithI` hygiene across the seams; the failure register (every pure failure site by invariant class); `check_failure_forms` gate (typed-absorbing / proven-unreachable / registered pending; fail-closed; plants) | [USER 2026-09-05] decision 4 | M | none | design note §2/§3 R1 |
| C-Z4 | **Z4 code half**: probe integration into lanes (145 noodle + 34 audit probes; the `PINNED_TRAY_<n>` gcc class); `test_ci_sweep` re-record (tripwire-justified); Defined-line stdout widening in `test_exec.sh`; `cerb_skip` ceiling; libc-body UB-loc mover (Z1-A1, S–M); the two stale `lembugs` cites in gated files; Z2-J-01/J-02 bridge fixes + manifest re-pin; R3 `-- ISO-fix register R3` marker + bijection gate; Z-40 elab filter; Z-31 per-row timeout evidence; **tray drafts owed**: F-A2 (`_Alignas` completeness gap → both oracles hang), F-C4-1 (`are_compatible` non-termination on legal two-TU code), Z-73 (oracle silent exit 0), lean4/01 filing notes | charter §4.1/§4.2/§4.3, Z1–Z3 hand-offs | M | Z3 (done) | charter §6; Z4 docs record §5 |
| C-N2 | **Fresh-noodler convergence test** (new agent, new brief, no earlier probes) | the exit test [USER 2026-09-03] | M | C-Z4 | `convergence-phase-and-exit-test` ruling |
| C-RM | **Trust-surface risk map** — independent pass, baseline 2026-08-31: oracle / execution / definitions / trust base / gates / consumer surface; per surface moved·evidence·residual·mover | [USER 2026-09-05] | M | C-Z4 + C-TF1 (so it covers the surgery), BEFORE C-N2 | TODO.md row |
| C-P1 | Tier C timing: whole csmith lane wall-clock at the merged head vs the pre-fuel head (the 7% question) | [USER 2026-09-05] perf ruling | S | none | C3 §8.4 |

### 3.2 Reasoning-artifact audit follow-ups (instances not yet closed)
| # | Instance | Remedy | Size | Status |
|---|---|---|---|---|
| C-A2 | Config as a reader-lifted PARAMETER (step 2; `using_concurrency` owned by `feature/concurrency`) | `drive conf switches fuel …` | M | after concurrency merges |
| C-B | Core-text symbols minted by `String.hash` with digest `""` (Z3 fixed the DIGEST and the libc ordering; the hash-minted NUMBERS and the G6 tripwire remain) | mint from the threaded supply; delete G6 | S–M | open |
| C-C | Enum registry as a process-global `IO.Ref` inside `sizeof_ity` | registry as a VALUE carried with the tag environment | M | open; bundle with C-TF1 or C-A2 |
| C-D/E/F/G/I | front end `partial` (L); digest global (S–M); `runND1` branch-0 choice as ND fork/selector (S); `BEq MemValue` unsafe sandwich (S); opaque no-op shims (S) | as the audit lists | — | open; the S ones can ride C-TF1 |

### 3.3 The fuel residue (8 pending rows)
| Rows | Route | Owner |
|---|---|---|
| `are_compatible_aux` + 2 siblings | UPSTREAM bug (recursion through pointers across TUs — oracle loops); tray draft; no honest hypothesis | C-Z4 (draft); stays pending until upstream fixes or a ruled ISO-fix |
| `hack`, `many`, `many1` | no parameter hypothesis bounds them; lem body change forbidden → typed absorbing outcome (they are monadic/partial) | C-TF1 / L2 |
| `to_pure`, `to_pures` | opaque `failwithI` in the recursion argument | C-TF1 |

### 3.4 Movers outside the arcs (registered, not scheduled)
Z-29 8 M zero-init hang (lem run-loop rendering, L); Z-30 byte-list OOM
(representation refinement, M, parked [USER]); CerbFS real semantics
(optional [USER Q10]); concurrency model instantiation (the
`feature/concurrency` branch — Phase 0 SC-DRF in review; Phases 1–2
per `2026-09-04_concurrency-scoping.md`).

## 4. Other branches and parties

- **`feature/concurrency`** (another agent): S0–S6 declared mergeable;
  pre-merge audit `audit/concurrency-premerge` @ `c0a926707` →
  MERGE-WITH-FIXES: F1 spurious `UB005_data_race` on file-scope shared
  objects under `--concurrency=sc` (fix + file-scope litmus rows); F2 the
  `.lem` restatement of `apply_tree`/`apply_tree_fp_aux` → REVERT to the
  fuel route ([USER 2026-09-05] "lem edits are against the rules");
  rebase onto `56b3c9e90`; then re-audit the delta, battery, operator
  sign-off, ff-merge through the orchestrator.
- **refined-cerberus** (consumer): re-pin to `56b3c9e90`; manifests
  C1–C4 + CerbGlobal on mainline; their restatement slice (~60
  hypotheses → `∀ [LemFuel], … ≤ LemFuel.fuel → …`; layout-oracle
  theorems carry `Acyclic tagDefs`); they discharge `Acyclic` for their
  environments (`CerbTagsWf`); Pmap laws available at lem `f6542f8`.
- **Upstream tray** (operator's network window): Cerberus drafts 02–35
  (+ F-A2, F-C4-1, Z-73 owed), `lean4/01` (standalone reproducer,
  fileable) and `lean4/02`, `lem/01` (reproducer to run first); three PR
  branches. Reader's guide: `docs/upstream-tray/README.md`.

## 5. Proposed order (sequential owner; one heavy worker at a time)

1. L1 declare consolidation (lem, M) ∥ C-TF1 typed-failure seams (cerberus, M) — different repos, no shared files.
2. Pin bump after L1 (a renaming pass over cerberus's `.lem` declare lines, Lean-only).
3. C-Z4 code half (M) incl. the owed tray drafts; C-P1 timing alongside.
4. C-RM risk map (M, independent auditor).
5. C-N2 fresh noodler (M). → "stable" if it passes; else the found rows become a Z5.
6. L7 upstream submission prep; the operator's filing window.
Concurrency merge slots in when its fixes land (any point after 1).

## 6. Decisions the plan still needs from the operator

- D-P1: the "stable" definition in §1 — confirm or amend.
- D-P2: the order in §5 (esp. L1 before C-Z4's pin bump vs after).
- D-P3: C-B/C-C (symbol minting; enum registry) — schedule in C-TF1's
  slice or as their own; both touch the consumer's cone.
- D-P4: whether the `are_compatible` upstream bug warrants a ruled
  ISO-fix on our side (a visited-set compatibility check — a `.lem`
  change, hence against the standing rule unless ruled) or stays pending
  until upstream fixes.

## 7. Provenance

[USER]: the rulings cited inline (dates given). [AGENT] (orchestrator):
the state summary, the stable definition proposal, the task tables,
sizes, order, and the open decisions. Docs-only; nothing merged or
pushed by this note.
