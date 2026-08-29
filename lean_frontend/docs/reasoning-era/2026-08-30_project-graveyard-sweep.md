# Whole-project dead-material sweep

STATUS: FINDINGS, NOT ACTIONS. Operator-commissioned [USER 2026-08-29:
"look through the whole project… Unless they serve us, they die"].
Standard applied: serves the LOGIC-FIRST era (design and prove the
logic; the frozen corpus as validation; the model-validation ledger;
provenance records). The proof-layer rip-out is inventoried elsewhere
(2026-08-29_harness-era-ripout-inventory.md) and NOT duplicated here.
Bias: committed material → death is cheap (history holds it);
uncommitted container material → death is real, provenance checked
per item. Nothing in this document has been deleted.

## 1. KILL LIST (by category)

### 1a. Disk-heavy build/scratch artifacts — ~14 GB reclaimable
| Item | Weight | Verdict |
|---|---|---|
| `cerberus-lean-prototype/` build artifacts (`lean/.lake` 8.5G, `cerberus/_opam` 706M, `cerberus/_build` 310M) | **9.5 G** | DEAD — prototype is ARCHIVED by [USER] ruling (reduce-to-oracle closed); build artifacts of a dead artifact serve nothing. The 74M `.git` + checkout is a separate decision (§4-Q1) |
| `worktrees/cerberus-lean-arc/workbench-v2` (on `arc/t5-seal`) | **1.8 G** | DEAD-pending-operator — the [USER] preservation rationale ("until T5 lands and the ladder migrates") is EXPIRED: the chase era is purged, T5Walks deleted, T5 re-proof owned by the logic. Citation value survives in commits/records without a mounted worktree. Needs the operator's word since a [USER] ruling created it (§4-Q2) |
| `worktrees/cerberus-lean-lem-totalization` + branch `lem-totalization` | **1.5 G** | DEAD — thread B merged into `arc/segment-ladder` @ abf5b4ef5; worktree and branch both disposable now |
| `worktrees/cerberus-lean-spike/` + branch `spike/relsem` | **893 M** | DEAD — Aug-19-era relsem spike (parametric adequacy rehearsal), superseded by the real relsem package (arc-11) and the V-build. Optional: tag before branch delete |
| Container scratch/log dirs: `.perf-logs` 176M, `.v3a-logs` 137M, `.c3b-logs` 28M, `.c3-logs` 25M, `.v2b-logs` 23M, `.r2-scratch` 21M, `.v2-logs` 14M, `.r1-logs` 10M, `.s2b-scratch` 9.4M, `.arc17-probe-scratch`, `.arc18-c3-probe-scratch`, `.c3b-probe-scratch` | **~445 M** | DEAD — every verbatim line the records rely on is quoted in committed records; the logs are redundant evidence. EXCEPTIONS kept until the pending merge lands: `.audit-logs` (324K, the MERGE-SAFE evidence), `.threadB-logs` (608K, the re-gate evidence). `.tmp` excluded (harness-managed) |
| Stray files in `worktrees/` itself: `probe-t4r.log`, `probe-t4s3.log`, `probe-t5.log`, `probe-t5b.log`, `provehyp-current.txt`, `roundeval-head.lean`, `s2logs/` (11M) | ~12 M | DEAD — era scratch littering a structural directory |
| Main checkout `cerberus-lean/lean_frontend/{.lake,relsem/.lake}` | ~1.0 G | DEAD-at-merge — pre-restart-era build state; refreshes on the post-merge rebuild anyway (reclaim then, not now, to keep mainline runnable) |

### 1b. Git branches (committed → cheap death; content merged or superseded)
- **cerberus-lean** DEAD: `arc/effects-totality`, `arc/exec-pipeline`, `arc/layer2`, `arc/libc-linking`, `arc/libc-load`, `arc/t5-landing`, `arc/totality-sweep`, `arc/workbench-v2`, `coherence` (ff-merged at cfeb7af5e), `effect-spike` (its content landed via thread B; recommend tag `archive/effect-spike` first — CLAUDE.md cites the SHA). PENDING-OPERATOR: `arc/t5-seal` (see §4-Q2 — [USER]-parked, rationale expired).
- **lem-lean** DEAD: `arc/effects-totality`, `arc/libc-load`, `arc/totality-sweep` (all merged into `mdd/lean-backend` in their eras). KEEP: `cerberus-pin` (the opam pin), `mdd/lean-backend`, `master` (upstream base).
- Stashes: all three repos EMPTY — nothing to do.

### 1c. Container notes/ — duplicates of in-repo canon (uncommitted, but death loses nothing: the canonical copy is committed)
DEAD (superseded duplicates): `2026-08-27_design-catechism.md` (canon = repo docs, BLESSED), `2026-08-27_target-corpus-draft.md` + `2026-08-27_target-corpus-review.md` (canon in repo docs), `2026-08-27_professor-whole-project-assessment.md` (imported to repo docs at 764c67ba4), `notes/corpus-draft/` 16 .c (frozen canon = `lean_frontend/corpus/`), `2026-08-22_harness-statement-template.md` + `2026-08-23_stepper-arc-design.md` (repo-docs copies are the record; both harness/chase-era besides), `2026-08-25_coherence-charter-draft.md` + `2026-08-26_arc18-segment-ladder-charter-draft.md` (finals committed in repo docs).
DEAD (obsolete-era surveys, low provenance, no live citations found): `2026-08-19_cmm-stage1-survey.md` (superseded by the 08-26 spike), `2026-08-19_libxml2-probe.md` (superseded by prep scripts + census), `2026-08-20_prototype-test-migration-survey.md` (prototype archived), `2026-08-20_april-inhabited-archaeology.md` (duplicate — also in repo docs).

### 1d. Kill-candidates requiring an operator decision (flagged, not adjudicated)
- The three speclab lane scripts for deleted family rungs (`test_speclab_bytearr.sh`, `test_speclab_list.sh`, `test_speclab_tree.sh`) + umbrella entries — model-validation coverage question, already flagged by the rip-out inventory §7.
- `test_golden.sh`/`gen_goldens.sh` — arc-early golden lanes; superseded by the differential suites unless still wired into a tier (LADDER check at execution time).

## 2. STALE-FIX LIST (banner/update cheaper than death)
1. **TODO.md** — "In flight: Arc 18 — the coherence consolidation" block is two eras stale; rewrite at the logic-first reframing slice.
2. **ROADMAP.md** (container) — last touched 2026-08-22; append the restart→logic-first arc lines or banner it as index-to-CLAUDE.md.
3. **CLAUDE.md** — 83 KB; the ACTIVE STATE block has absorbed three eras of rulings. A prune-to-operating-manual pass is DUE per the standing claude-md-hygiene memory (verbatim rulings → a committed rulings ledger; state → pointers). Flagged only; not drafted.
4. **check_proof_size.sh** — dead ban tokens (`app_walk?`, `app_walk_preview`, …) police surfaces deleted at the kill-list execution; prune the clauses (tombstone comments elsewhere are fine — they are doctrine).
5. The 5 harness-primacy-framed docs + catechism §II — already flagged by the rip-out inventory; banners/edits ride the reframing slice.
6. **PROOF.md / DESIGN.md / README.md** — will be rewritten wholesale by the logic-first reframe; no interim fix.
7. `2026-08-27_infrastructure-plan.md` (notes) — partially superseded by logic-first; needs a scope banner (its component designs remain cited).

## 3. SERVES — the survivors (summary)
- **deps/**, all justified: `linux` 4.9G (pKVM target, [USER]-placed), `mirrors` 1.9G (offline insurance), `cerberus-upstream` 534M (fork-drift gate input), `iris-lean` 371M (build-critical via gitconfig redirect), `BRiCk` 140M + `refinedc` + `brick-wp` + `ACL2Lean` (donors, all cited in the paper logic/records), `lem-pinned` (opam pin), `cn` 89M (cn_coverage lane + corpus shapes), `golean` 75M (playbook donor, cited), `libxml2` 63M (capstone target), CN-pKVM (target reference). No dep is uncited.
- **lean_frontend/docs/** (156 dated records) — provenance by design ("the repo is the record"); they serve. Only the 5 flagged docs need banners.
- `notes/upstream/` (the filing tray), `lembugs/` (2), container `scripts/` (ce/env/new-worktree), the three `upstream-pr-*` worktrees (820M — they serve the operator-gated network window; weight noted, kill only if the tray strategy changes).
- All differential lanes and baselines except §1d's flagged three.
- Live notes: the 08-26 spike, 08-27 professor pass + infrastructure plan (bannered), 08-28 perf plan + review, all 08-29/30 documents (the current conversation's working set), donor reviews (acl2lean/cn/iris-litreview/lithium), grumpy audits, fork-drift review, upstream-oracle-build, wireguard scoping, the CLAUDE.md pre-prune archive.

## 4. PROVENANCE-LOSS WARNINGS (uncommitted sole copies — do NOT delete; commit instead)
The following container notes are the SOLE copies of ratified-decision records and in-flight design artifacts. Recommendation: COMMIT them to `lean_frontend/docs/` at the reframing slice, after which their notes copies become §1c-class duplicates:
`2026-08-26_cmm-pkvm-scoping-spike.md` (slate rulings), `2026-08-26_reasoning-layer-design-pass.md` + `2026-08-25_reasoning-coherence-review.md` (era provenance), `2026-08-27_proof-style-professor-pass.md`, `2026-08-27_infrastructure-plan.md`, `2026-08-28_proof-performance-plan{,-review}.md` (operator-signed plan), `2026-08-29_{alloc-nd-evaluation, capability-roadmap, cargo-cult-spot-audit, corpus2-draft, corpus2-review, harness-era-ripout-inventory}.md`, `2026-08-30_core-logic-paper{,-review}.md`, `notes/corpus2-draft/` (pending freeze — canonical only after sign-off). Also `notes/upstream/` (sole copies of 14 drafted upstream reports).

## 5. FIVE BIGGEST SINGLE ITEMS
1. Prototype build artifacts — **9.5 G** (kill now)
2. workbench-v2 worktree — **1.8 G** (operator word: [USER]-created preservation, rationale expired)
3. lem-totalization worktree + branch — **1.5 G** (kill now)
4. spike/relsem worktree + branch — **893 M** (kill now)
5. Container era-logs aggregate — **~445 M**, biggest single `.perf-logs` 176M (kill now, two current-era exceptions until merge)

Total reclaimable without any operator-pending item: **~12.4 G**; with
workbench-v2 and the prototype checkout question: **~14.3 G**.

## 6. Open questions for the operator
- Q1: prototype final form — (a) keep the 74M git checkout as the
  archive (build artifacts die regardless), (b) bare-mirror into
  `deps/mirrors/` (~74M) and delete the checkout, or (c) delete
  outright (remote exists at github:septract/lean-c-semantics; offline
  copy lost). Recommendation: (b).
- Q2: `arc/t5-seal` + workbench-v2 — the [USER] preservation ruling's
  stated rationale is expired; records cite the branch by name.
  Recommendation: tag `archive/t5-seal`, remove the worktree, keep the
  branch pointer as the tag only.
- Q3: the three speclab lane scripts (rip-out §7's question, restated).
- Q4: `upstream-pr-*` worktrees (820M) — keep mounted until the
  network window, or unmount and re-create from branches at the
  window? Recommendation: keep (they are the tray's ready state).

## 7. CONSOLIDATION AND RESTRUCTURING PROPOSALS (operator addendum;
proposals only, boring-by-mandate — established conventions, nothing
invented)

### 7.1 Container layout
**Proposal**: (a) after §4's sole-copy records are committed to repo
docs, `notes/` holds ONLY live working documents; one `notes/attic/`
subdir receives the few uncommitted keepers that are history rather
than working state (the pre-prune archive, era reviews not worth repo
space). No per-era subdirs — the attic + repo-docs flow is the whole
scheme. (b) ONE scratch convention: a single `.logs/` dir with
per-slice subdirs (`.logs/<slice>/`), replacing the nine ad-hoc
dot-dirs; worker-brief boilerplate and the CLAUDE.md convention line
point there; slices delete their subdir at close (record-quoted lines
are the durable evidence).
**Fixes**: the undifferentiated 40-file pile; the dot-dir sprawl that
has twice tripped gates (the in-tree-log D14 episode's cousin risk).
**Cost**: one `mv` session + two doc-line updates. **Timing**: ride
the reframing-and-prune slice.

### 7.2 Repo docs/
**Proposal**: keep the flat dated-journal convention (it is the
ADR-style standard and the provenance chain depends on stable paths —
moving 156 files re-points citations for no gain). Add
`docs/INDEX.md`: one line per record with a STATUS column
(LIVE / SUPERSEDED-BY→ / HISTORICAL), the in-project precedent being
`notes/upstream/INDEX.md`. The SUPERSEDED-banner discipline continues
in-file; the index makes it legible at a glance. Shop-window docs
(README/DESIGN/PROOF/TODO + the coming LOGIC document) remain at
`lean_frontend/` root — the split already exists; the index's header
states it.
**Fixes**: the flat pile hiding the live/superseded distinction.
**Cost**: one generated-then-maintained file; zero moves, zero gate
re-pointing. **Timing**: reframing slice (the index is also where the
5 banner fixes get recorded).

### 7.3 Proof-layer module tree under logic-first (the substantive one)
**Proposal** — mirror Iris's own `base_logic`/`program_logic`/tactics
layering and BRiCk's one-rule-family-per-file convention, making the
KEEP-partition a DIRECTORY structure:
```
relsem/RelSem/
  Resources/      -- the ghost components: CerbStateRA, the interp,
                  --   coherence invariants           (Iris base_logic analogue)
  Logic/          -- THE DELIVERABLE
    Judgments.lean   -- wpPE/wpE(Kpred)/wpA, the contract judgment
    Adequacy.lean    -- ADQ, ∀-state
    Rules/           -- one file per construct family, per the FIGURE's
                     --   own sectioning (Pure, Control, Memory,
                     --   Births, Loops, Calls, ND ...)
  Engine/         -- automation BENEATH the logic: the stepper (split
                  --   per the professor's 8-concern decomposition),
                  --   SegRun, round tactics, minting, SegReg registry
  Application/    -- contracts→corollaries: statement modules, corpus
                  --   proofs+guards, verify_fn faces, fixture data
  Audit.lean      -- gates (stays top-level; keys on the directories)
```
The Rules/ file split is dictated by the ratified paper figure's
sectioning — hence GATED on the paper-logic conversation.
**Fixes**: partition legible and mechanically enforceable (one-route/
proof-size/sweep gates can key on directory prefixes instead of
hand-maintained file lists — a gate simplification, not a new gate);
the professor's monolith finding lands as structure.
**Cost**: S-M mechanical — imports and lakefile roots (mechanical),
plus re-pointing the hand-maintained gate lists (one-route module
list, proof-size slate, Audit sweep imports, census pins), each
plant-tested; doing it in the SAME slice as the prune avoids
re-pointing twice. **Timing**: the reframing-and-prune slice,
immediately post-ratification.

### 7.4 Packages/worktrees
**Proposal**: no package moves now. Note the alignment only: 7.3's
directory split makes the registered repo-split intention a
directory-lift when its arc comes (relsemcore + semantics → the
semantics repo; Resources+Logic+Engine → the verification repo;
Application + corpus → the validation/examples side). Statements
currently straddling relsemcore/relsem are Application-side and
consolidate there under 7.3. speclab's consumed core (Codec/
MkHarness) is Application tooling; its dead rungs die per the
rip-out. Package boundaries themselves: untouched (gate wiring makes
moves expensive for zero present gain). **Timing**: wait.

### 7.5 CLAUDE.md prune (structure only, per the hygiene memory)
**Proposal shape**: three-way split — (a) the OPERATING MANUAL
(stable doctrine, conventions, build/test, ~pointers; target ≤25K);
(b) a committed RULINGS ledger in repo docs (the verbatim [USER]
rulings with dates — they are provenance and belong in the record,
not in working memory); (c) the ACTIVE STATE block compressed to the
arc-index one-liner convention (already used for arcs 1–14) pointing
at records. **Cost**: one careful editorial pass; needs operator eyes
because rulings move homes. **Timing**: its own small pass right
after the reframing slice (the reframe rewrites much of the block
anyway — prune once, after).

### 7.6 scripts/
**Proposal**: KEEP FLAT. The prefix convention (`check_*` gates,
`test_*` lanes, `*_baseline.txt`/manifests data, the rest
instruments/utilities) already encodes the four kinds; subdirs would
re-point LADDER.md, CI wiring, ~60 docs references, and every worker
brief for purely cosmetic gain — the anti-innovation ruling decides
this one. Single addition: a four-way classification header in
LADDER.md (which is already the normative index). Dead-clause pruning
(§2.4) is orthogonal and proceeds. **Cost**: one doc header.
**Timing**: reframing slice.

### Timing summary
Ride the reframing-and-prune slice: 7.1, 7.2, 7.3 (post-ratification,
same motion as the prune), 7.6. Own pass after: 7.5. Wait/note-only:
7.4.
