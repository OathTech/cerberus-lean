# Orchestrator handoff — cerberus-lean + lem-lean, state and what's next (2026-09-05, evening)

**Current continuation, 2026-09-06 [AGENT]:** validation foundations has a
repaired candidate for second review. Start with the
[audit repair record](2026-09-06_validation-foundations-audit-repairs.md),
its evidence index and [master plan revision 7](2026-09-05_master-plan.md).
The first audit's eleven findings have implemented and tested repairs;
second-review acceptance and landing remain pending. Discuss the proposed
[SC integration charter](2026-09-06_concurrency-integration-charter.md)
after reviewing this candidate. The remaining text is the earlier assessment
handoff; its old execution queue is superseded. No customer adoption or
legacy-run operation is implied.

**Historical planning note [AGENT, 2026-09-05]:** read
[master plan revision 3](2026-09-05_master-plan.md) for the current work order,
[the customer-readiness assessment](2026-09-05_customer-readiness-assessment.md)
for the newer source/check snapshot, and
[the proposed first charter](2026-09-05_validation-foundations-charter.md)
for the next execution package. The rest of this handoff is the outgoing
agent's historical record; revision 3 replaces the older combined reading
order below. The operator's subsequent instruction leaves the legacy csmith
run with its existing agent until completion, superseding this handoff's
directions to monitor, record or clean up that run. Follow current ownership.

Written by the outgoing orchestrator [AGENT] for the agent picking up the
orchestrator role. Everything here is either measured on the box today or
cites the committed record that carries it. Rulings are quoted verbatim
with [USER] provenance; sizes and sequencing are [AGENT].

Read first, in this order: the container `CLAUDE.md` (working practices —
they are binding), this repo's `CLAUDE.md` + `lean_frontend/CLAUDE.md`,
`lean_frontend/VALIDATION.md` (what the gates guarantee),
`2026-09-05_master-plan.md` **together with**
`2026-09-05_whole-project-audit-response.md` §4 (revision 2 replaces the
plan's §1 amendments and §5 order), and the audit itself
`2026-09-05_whole-project-release-gate-audit.md`.

## 1. Where every pointer is right now

| Thing | Value |
|---|---|
| cerberus-lean mainline `mdd/cerberus-lean` | `0a62dd7f7` (P0 instruments landed; before it: tray 36 `ec919ce0a`, audit + response `61181efd1`, master plan `9a7f7ad31`, fuel-parameter C4 `56b3c9e90`) |
| lem-lean mainline `mdd/lean-backend` | `f6542f8` — and `deps/lem-pinned` = opam `lem` = cerberus Lake `LemLib` rev = `f6542f8`. **Two-repo invariant CLOSED.** |
| upstream Cerberus merge-base | `b9aeedcb4` (`deps/cerberus-upstream`; `master` in both repos is upstream-tracking, NEVER commit there) |
| refined-cerberus (consumer) | their `main` @ `c2ebeb7` (they also wrote a handoff snapshot); their semantics pin is STILL `f95ef8d9c` — re-pin to `0a62dd7f7` is owed by them; consumer change manifests for C1–C4 + CerbGlobal are in this docs dir |
| Neither mainline has been pushed by an agent | pushes are the operator's action, always, at the point of the push |
| Primary checkouts | parked on the mainlines, clean; `cerberus-lean` primary was refreshed (cache-disabled rebuild, driver stamps fresh) at `56b3c9e90`; the P0 landing changed scripts/tests only, so its build products are current |

Worktrees (cerberus-lean): `worktrees/cerberus-lean-arc/zero-discrepancy`
= `arc/next` @ mainline (the general-purpose arc worktree, built);
`worktrees/cerberus-lean-arc/p0-instruments` = `arc/p0-instruments` @
`8e5f198c5` (MERGED content, pre-rebase commits — **delete the worktree and
branch once the csmith sweep below has finished**);
`worktrees/cerberus-lean-feature/concurrency` = `feature/concurrency` @
`086d8762d` (ANOTHER agent's; hands off); three `upstream-pr/*`
worktrees (filing tray patch branches). lem-lean:
`worktrees/lem-lean-arc/fuel-parameter` = `arc/next` @ `f6542f8`.
Parked records (never merge): `arc/segment-ladder`, `arc/t5-seal`,
`wip/fuel-parameter-C1-scratch`, `audit/concurrency-premerge` (`c0a926707`,
the concurrency audit; its worktree is gone, the branch is the record).

## 2. Running / unfinished on the box at handoff

- **csmith corpus sweep** on the merged instrument change: detached
  script `.tmp/p0-reverify.sh`, log `.tmp/p0-reverify.log`, running in
  the `p0-instruments` worktree. The 26-lane battery portion is DONE and
  green (zero movement; gcc lane `agree=1873 disagree=0`, `0 regression(s),
  0 improvement(s)`). Shard 1/6 done: `SUMMARY: total=279 match=127 …
  mismatch=0 … timeout=1 … cerb_skip=151`, `BASELINE OK`. Shards 2–6 were
  running (~27 min each). **What to do with the result:** any moved row is a
  real stdout/stderr discrepancy newly VISIBLE through the widened
  Defined-line comparison (audit F3) — a finding to triage and register,
  never a reason to revert the instrument; zero movement = record the
  verbatim SUMMARY lines in a short note and delete the worktree/branch.
  `.tmp/` is ephemeral: delete the `*.sh`/`*.log` there when done.
- **Other agents on the box** (visible as `codex` processes and the
  concurrency worktree): box discipline is one heavy job per agent, every
  lake/lean through `scripts/capped`, drop to 32–48G under pressure. The
  harness killed background waiters twice today under "low memory"
  notices while `free` showed >100 GB available — treat those kills as
  harness-side, re-check `free -g`, and poll with foreground bounded
  waits (≤10 min) instead.

## 3. What landed today (2026-09-05) and the rulings that came with it

1. **Fuel-parameter arc closed** (lem `f6542f8`; cerberus C4 `56b3c9e90`).
   Fuel is a quantified `[LemFuel]` parameter; 81 fuel'd workers: 54
   MEASURED (kernel-checked sufficiency, 7 under reviewed hypotheses in
   `scripts/fuel_hypotheses.txt`), 13 ABSORBING, 6 unreachable, 8 pending
   (`scripts/fuel_forms_pending.txt`). Records: `2026-09-05_fuel-parameter-C4-record.md`
   (+ C1–C3), lem `doc/lean-backend/2026-09-05_measure-hypothesis-record.md`.
2. **Master plan** `2026-09-05_master-plan.md` (rev 2 after the audit).
3. **Whole-project release-gate audit** (Codex [AGENT]) landed verbatim
   with evidence; orchestrator response verified every premise on the
   box (F1–F4, F8, F9 re-measured TRUE). Gradings and the operator's
   rulings are in the response §2–§3.
4. **P0 instrument slice** (`2026-09-05_p0-instruments-record.md`):
   fork-drift gate locale-independent + fail-closed prerequisites +
   `--selftest` (10 plants); fuel-forms classifier checks argument
   correspondence and the `_zero` lemma's subject (24 plants incl. the
   audit's decoys verbatim); `test_exec.sh` compares the WHOLE Defined
   line (value+stdout+stderr+blocked) with a hermetic selftest; the fuel
   plant's `stub_words` fixed (dash `echo` split the line). Census
   unchanged 81/54/13/8/6; four Tier A lanes zero movement.
5. **Tray draft 36** (`docs/upstream-tray/36-…`): `Core_eval.mk_conv_int`
   bypasses the impl-defined signed non-representable conversion that
   `std.core` calls — latent upstream divergence relayed by
   refined-cerberus; not a Lean-vs-OCaml issue.

Operator rulings of the day (verbatim, all [USER 2026-09-05]):
- On the audit's F1 (discarded pure `failwith`: OCaml raises, Lean drops
  the unused let): "(1) agree, the aim should be to provide the most
  faithful C semantics, per the intent of the authors" → KIND-1: it IS a
  discrepancy class; referent = the authors' intent.
- On the audit's P2 (pure-failure lifting transform in the lem backend):
  "(2) unsure, this feels like it does touch the trust surface because it
  increases the gap between 'obviously right' and what Lean does. Is
  there a route where we prove the two are equivalent?" → NOT authorized
  as a bare transform; the proposed route (response §4 item 4): the
  mirror stays the reference, a lifted `f_exc` twin behind a generated,
  kernel-checked per-function correspondence `f_exc xs = .ok v → f xs =
  v` (the fuel-sufficiency pattern); failure direction differential;
  design note reviewed WITH the operator before any dispatch; census
  first.
- On F9: "(3) agree on the first [consumer re-pin + proofs through = a
  release exit], and the second [C-source examples] depends on how the
  refined-cerberus project evolves".
- On F10: "(4) I think you're right, the matrix may come later but for
  now we mostly inherit trust from Cerberus-upstream" → release-profile
  statement yes; ISO coverage matrix later.
- Landing: "let's land it as you propose, and keep the csmith gate
  running in the background" (P0 landed on the green 26-lane gate; csmith
  post-merge).
- Standing from earlier in the arc (see memory-grade records in
  `DESIGN.md` §4 and `2026-09-03_logical-semantics-referent-ruling.md`):
  no magic values; the four aims (VALIDATION.md §0); "we don't change the
  lem structure for ocaml"; zero Lean-vs-OCaml discrepancies with the
  exception classes (a)–(d); `.lem` edits for Lean plumbing are against
  the rules (the concurrency F2 revert).

## 4. What's next — the order (response §4, rev 2)

| # | Task | Size | Notes / where the detail is |
|---|---|---|---|
| 1 | **Finish the csmith sweep** (§2), delete `arc/p0-instruments` + worktree, `.tmp` cleanup | S | this doc §2 |
| 2 | **Risk-map BASELINE now** — independent auditor, read-only, baseline 2026-08-31: oracle / execution / definitions / trust base / gates / consumer surface; per surface moved · evidence · residual risk · mover. Repeats after the surgery (item 6+). Write the **release-profile statement** alongside (one contract: supported / loudly refused / upstream defect / open port bug) | M | `TODO.md` risk-map row; audit F10; response §3 item 4 |
| 3 | **Census of discardable pure failure sites** on the exec cone (unused lets, unused args, tuple components, ignored results, `hack`/`finalize`/`many`/`many1`/`to_pure(s)`): decides F1's blocker status | S | audit F1/F8; `2026-09-05_typed-failure-outcomes-design.md` (~line 565 already names discarded values) |
| 4 | **Correspondence design note** for pure failure IF the census is non-empty — reviewed with the operator BEFORE dispatch; it fixes the failure family of lem's declare consolidation | M (note) | response §4 item 4; lem `TODO.md` row 18 |
| 5 | **lem L1 declare consolidation** ∥ **C-TF1 monadic seam slice** (7 `memM` failure sites → the memory monad's error; `panic!`→`failwithI` hygiene; failure register + `check_failure_forms` gate) — both after item 4's vocabulary | M each | design note R1; lem TODO 18 |
| 6 | **F5 lane**: pristine `deps/cerberus-upstream` binary vs the fork oracle over the Tier A corpora; content-pin the hand-written oracle files (`util/cerb_fresh.ml`, `ocaml_frontend/fork_renumber.ml`, `backend/driver/main.ml`, …) in `check_fork_drift.sh` layer 1 | M | audit F4/F5; P0 record §F4.4 |
| 7 | **C-Z4 code remainder**: probe integration (`PINNED_TRAY_<n>` gcc class), `test_ci_sweep` re-record, `cerb_skip` ceiling, libc-body UB-loc mover, the **five duplicated value-only extractors** (`test_gcc_oracle.sh:308`, `test_ci_sweep.sh:172`, `test_cn_coverage.sh:243`, `test_multi_tu.sh:114`, `test_verify.sh:72`) → the shared verdict codec, the `batchEscape` per-codepoint vs OCaml per-byte escaping bug (`Main.lean:353`; TODO.md), stale `lembugs` cites, Z2-J bridge fixes, R3 marker + bijection gate, tray drafts owed (F-A2, F-C4-1, Z-73) | M | Z4 docs record §5; P0 record §F3.4 |
| 8 | F6 exposure trace (cerberus, S) + **L4 strings-as-bytes** (lem, L); F7 instances C-B (hash-minted symbols), C-C (enum registry `IO.Ref`), digest; config-as-parameter step 2 after concurrency merges | — | reasoning-artifact audit; string design |
| 9 | **Consumer adoption exit**: refined-cerberus re-pin + proofs through the `[LemFuel]` interface and the `Acyclic` hypotheses | their M | response §3 item 3 |
| 10 | Risk map (repeat) → **fresh-noodler exit test** → stable-profile claim | M + M | convergence ruling 2026-09-03 |
| ∥ | lem: L3 monotonicity decomposed, L5 Pset laws, L6 small TODOs, L7 upstream submission prep, L8 measure cost; C-P1 Tier C timing | — | lem `doc/lean-backend/TODO.md` rows 10–23; C3 record §8.4 |

Open operator decisions carried: master plan §6 D-P2/D-P3/D-P4 (order
detail; whether C-B/C-C ride C-TF1; `are_compatible` ruled ISO-fix vs
pending on upstream — the audit recommends preparing the upstream remedy).

## 5. Other parties — relays owed / expected

- **Concurrency agent** (`feature/concurrency`, now `086d8762d`, moving):
  they were told to rebase onto the mainline, fix F1 (spurious UB005 data
  race on file-scope shared objects) and REVERT F2 (`.lem` restatement of
  `apply_tree` — "lem edits are against the rules"); audit record on
  `audit/concurrency-premerge`. Their merge comes THROUGH the
  orchestrator: re-audit the delta, battery, per-merge operator sign-off,
  ff-only. Announce every mainline move to them (they rebase).
- **refined-cerberus**: re-pin to `0a62dd7f7`; manifests C1–C4 +
  CerbGlobal here; Pmap laws at lem `f6542f8`; they must discharge
  `Acyclic tagDefs` (`CerbTagsWf.lean`). Two notes from them today need
  no action (`…_note-cerberus-lean-subst-esize.md`; the conv-int one
  became tray 36).
- **Upstream tray** (operator's network window): drafts 01–36, `lean4/01`
  (standalone deadlock reproducer, fileable), `lean4/02`, `lem/01`;
  reader's guide `docs/upstream-tray/README.md`.

## 6. Orchestrator practice that bit today (keep doing this)

- **Worker-claimed green is never accepted.** The P0 worker ran the unit
  gate + four lanes; the orchestrator's full battery found the one lane
  it had not run (`test_fuel_plant.sh`) red — a plant defect exposed by
  the fixed instrument. Always run the FULL battery at the boundary.
- **Audit findings are claims**: every premise re-measured before
  grading (all held today, but the grading moved on three of them).
- **ff-only means ff-only**: the P0 branch was based below a docs-moved
  mainline; the fix was a rebase in a separate primed worktree
  (`scripts/new-worktree.sh cerberus-lean <branch> <base>`), patch
  identity checked (`git diff` byte-equal), FAST-GATE re-run on the
  rebased head, labeled as such in the record. Never `branch -f`.
- **Locale is part of the environment**: two gates in a week were
  locale-dependent (`LC_ALL=C` everywhere in scripts that sort/comm).
- **Pre-sign hygiene**: conditional landings are logged in memory with
  the exact condition and marked SPENT when used.
- **Provenance**: every ruling quoted verbatim with [USER date]; agent
  choices marked [AGENT]. The user's pronouns are they/them.
