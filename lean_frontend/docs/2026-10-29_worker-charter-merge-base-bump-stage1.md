# Worker charter: merge-base bump, stage 1 (b9aeedcb4 → upstream c3ff8c53f)

Date 2026-10-29. Orchestrator [AGENT]. Branch `arc/merge-base-bump`, worktree
`worktrees/cerberus-lean-arc/merge-base-bump`, base = mainline `mdd/cerberus-lean` `676f9f21c`
(Lean 4.35.0, lem `e6d8db5`). The scoping record is in-tree on this branch:
`docs/2026-10-20_merge-base-bump-scoping-record.md` (§1 upstream inventory, §2 conflict map, §3 seam
proposals, §4 lem-lean needs, §5 measure-proof churn, §6 fork-drift re-pin plan, §7 baseline movement,
§8 consumer impact, §9 staged plan, §10 questions). Read it whole before anything else.

## Provenance

- [USER 2026-10-20] the merge-base bump is the right thing and is a staged arc; scoped read-only that day.
- [USER 2026-10-29] the bump runs now, before the remaining crash-to-refusal arms of the survey (the bump
  retires three of them). Fork-ahead deltas are limited to the fork's own fixes and the backports a
  delivery needs (container working-practices doc); upstream fixes arrive with the bump, never ad hoc.
- [USER 2026-10-29] `monomorphic 2.1.0` is installed in the project switch (`opam list` shows it).
- Rulings on the scoping's §10 questions that bear on stage 1 — the orchestrator's recommendations,
  RULED BY THE OPERATOR BEFORE M1's merge commit (the worker records the ruling with its tag in the
  record; if a ruling has not arrived when M0 ends, STOP and report, do not guess):
  Q1 the bump is a true merge commit of upstream into the fork on this arc branch (not a rebase of the
  fork's commits), landed ff-only after the audit, as the fork's earlier upstream merge `24c3314c0`;
  Q5 the stage-1 cut is `c3ff8c53f` (2026-09-30, before the symbolic-memory removal and the Tags/Config
  refactors); Q9 upstream's new switch `branching_on_unspec_is_nd` is REFUSED by `--switches` like every
  other non-PNVI switch (R-PNVI-12 class), not mirrored; Q10 tray filings 01, 04, 15 and 33 are closed in
  the INDEX at stage 1 as fixed upstream and now carried by the base. Q2 is done; Q3/Q4/Q6/Q8 are stage 2.

## What stage 1 is

Commits 1–25 of the scoping's §1 (b9aeedcb4..c3ff8c53f, 25 commits): eleven of the sixteen upstream
FIX rows (766073467 tray 01, 5a3a06036, 588672e95, ad233f84f, 3230aa494 tray 15, cee382443 tray 33,
f10329b44, 97371d8ed, 0fc82e266, cabe81c3b, f4a3a3d54 tray 04), four additions (83f9cc641, c8c085d47,
08e941f0e, 83b1a7424), three refactors (b3e11ea33 sizeof/alignof out of the memory interface, 334a1563b
the elaboration-monad environment, 3771dce03 `Symbol` never opened). Re-simulated 2026-10-29 on
`676f9f21c` with `git merge-tree --write-tree`: 13 conflicted files (the scoping's 11 plus the growth from
the three refusals landed since): `backend/common/pipeline.ml`, `frontend/model/{cabs_to_ail,
cabs_to_ail_effect, core_typing, formatted, implementation, mem, mini_pipeline, translation,
translation_aux, translation_effect}.lem`, `ocaml_frontend/ocaml_implementation.mli`, `tests/tests.sh`.
Upstream's tip moved to `ae70925fc` on 2026-10-22 (one parser-driver commit, outside stage 1).

Things the scoping did not see and this charter adds:
- The three refusals landed since 2026-10-20 sit in the conflicted files and are re-threaded onto
  upstream's rewritten paths, each keeping its witness script green and its text: the union-initializer
  refusal (D11, `desugaring_init.lem`), the anonymous-member refusal (D12, `cabs_to_ail.lem`,
  `desugar_struct_declaration`), the compound-assignment refusal (D13, `translation.lem`, the walker and
  the arm). Where upstream's rewrite changes a refusal's run point (the `eval_mode` constant-expression
  path), measure it again; a refusal that stops being undiscardable is a finding.
- The two landed backports (I0 `f928cddbb`, I0b `1e7df2ac2`) must merge AWAY: after the merge the files
  they touched are upstream's text (verify byte-equality of the relevant hunks against `c3ff8c53f`); their
  manifest NOTEs are closed, their tray entries (15, PR 1020) marked carried by the base.
- The stop vocabulary (design v2 §10, boundaries `libc` and `memory`), the quotation hygiene and the
  Lean 4.35 toolchain are new seams: `CerbStopSites` metadata and the register-migration map move where
  upstream changes a site (the `array_shift_ptrval` crash site becomes UB: §3.4), and nothing may regress
  the kernel-replay or axiom gates.
- `NULL + 0` (survey arm 4, tray 04) is retired by f4a3a3d54: no refusal is written; TODO says so.

## Milestones (one coherent commit each; report after each; the merge commit is M1)

- **M0 — plan on today's base.** Reproduce the merge simulation; write the per-file resolution plan for
  the 13 conflicts (§2's hot-file analysis updated), the seam plan (§3.3 sizeof/alignof reps, §3.4
  array_shift/memcmp/load_character_array in the UB monad with a loc and the CerbMem mirror, §3.5 the
  translation-fuel wrappers against the elabM environment, the Cabs/Ail GNU-label constructor in
  `cabs_json.ml`/`CabsImport.lean`/`CerbPP`, Main.lean's error arms, the refused switch), the
  measure-proof list (§5 stage-1 share), the baseline-movement forecast (§7), and the pristine-instrument
  plan (§6). Commit it as the record's first section. Then STOP for the operator's rulings if any is
  outstanding.
- **M1 — the merge.** `git merge --no-ff c3ff8c53f` with the 13 resolutions (the fork's mechanisms —
  symbol supply, address-space top, run digest, enum reader, switch parameter, seeds — re-threaded once;
  upstream's text everywhere else), the backports merging away, the three refusals re-threaded, the
  `monomorphic` dependency in the build. The OCaml side builds; `make prelude-src lean-prelude-src`
  regenerates both trees; the Lean side need not yet build. The merge commit message lists every
  resolution by file with its rule.
- **M2 — seams.** The hand-written Lean seams per the plan; the Lean build green (`build_lean`, every
  root); the exec-totality list, the failure-reach register (rows that move: the retired crash site,
  any new pure failure site of upstream's), `CerbStopSites`, the migration map, `check_handwritten_sync`.
- **M3 — proofs.** The `*_lemMeasureProofs.lean` carriers upstream's changes break (§5), kernel-only
  tactics, no option bumps; `lake env leanchecker` over every changed carrier (the named trust gate:
  modules and exit status quoted); the axiom censuses.
- **M4 — lanes and baselines.** Focused lanes first (the refusal witnesses, item G, PNVI, memory access,
  the runtime-resolution and quotation witnesses, `libc_prep.sh` with the libc dump re-pinned, the
  tests/ci adoption of upstream's new CI files), then report for the orchestrator's Tier A; baseline
  rows that move are each dispositioned (a moved row is upstream's fix, a retired refusal, or a finding;
  never a silent re-record); `tests/ci/expected` adoptions cite the upstream commit.
- **M5 — fork drift on the moved base.** Per §6: the pristine instrument rebuilt at `c3ff8c53f` in a
  scratch checkout of the mirror (`deps/mirrors/cerberus.git`) under the worktree's `.tmp/` (the
  container's `deps/cerberus-upstream` and `CERB_UPSTREAM_TREE` move only at landing, by the
  orchestrator); `scripts/fork_drift_manifest.txt` re-derived as a reviewed whole (this is the one case
  where the layer-2 set is rebuilt rather than single-row edited: say so in its NOTE, keep every
  fork-ahead justification that survives, drop the ones that merged away); `check_fork_drift.sh` and its
  selftest green; `check_pin_sites.sh` green.
- **M6 — records.** The record `docs/2026-10-29_merge-base-bump-stage1-record.md` (resolutions, seams,
  proofs, moved rows, gate lines verbatim, the backports' disappearance verified, what stage 2 inherits);
  tray INDEX closures (Q10); TODO (the survey arms retired, the bump entry updated, stage 2 queued);
  CONTRACT/VALIDATION/SUPPORTED/README where the base or a behaviour moved; the consumer notes for
  cerberus-caesium and cerberus-sl (§8 stage 1: `desug_config`/`elab_config` arguments, two AST
  constructors, Core-text re-quotes, `Undefined.t` array shift); `lean_frontend/CLAUDE.md`'s
  reconciliation line.

## Gates and process

- You run the focused gates and lanes named above yourself and quote last lines verbatim. You do NOT run
  `release.py`; at M2, M4 and M6 the orchestrator runs Tier A, and the full battery at M6, keeps the
  evidence and sends you the lines. No tree edit while an orchestrator run is in flight. No poller,
  waiter, gate script or sleep loop of any kind; runs longer than a few minutes go through the harness's
  background execution. One heavy job at a time; 1-minute load below 12 before a build or sweep.
- Every lake/lean invocation through `scripts/capped` (`CERB_MEM_MAX=32G`); every make/dune/opam/lane
  command through `/home/dev/projects/cerberus-lean-proj/scripts/ce`. The grind tripwire: a single build
  or proof pass approaching an hour is a stop-and-report.
- The merge commit is the one non-linear commit of this arc (Q1); everything else is linear on top of it.
  Never commit on a mainline; nothing pushed. Never `pgrep -f`/`pkill`. No network: the mirror has what
  the operator fetched on 2026-10-29. `/tmp` is unreadable; scratch under the worktree's `.tmp/`, deleted
  at slice end.
- Records: machine outputs verbatim, derived tallies labelled; provenance tags on every decision; the
  operator's words never quoted. A blocker the charter does not resolve is a committed park record
  (`docs/2026-10-29_merge-base-bump-stage1-park.md`) and a stop.
- Budget: the scoping's 10–12 worker-days plus the audit cycle. Report at every milestone with the
  commit hash, `git diff --stat`, every gate's last lines verbatim, moved rows, and what could not be done.
