# Arc-12 merge checklist (the honest oracle)

Prepared 2026-08-21 at S4 close-out. **MERGE LIVES WITH THE USER — this
checklist is preparation only; the ff-only merge executes on explicit
per-merge sign-off, after the 2-agent adversarial audit and the D2
VETO WINDOW (open through the merge ask; a veto reverts batch 4's lane
re-greens to Option A honest-red — the floor itself is unaffected).**

## Facts (rev-parsed at checklist time)

- `mdd/cerberus-lean` (mainline): `a8da194b21eaaac3607238d09a1db8c6d66a5415`
- `arc/honest-oracle` at checklist time: `7fd47f816` (+1 final S4
  commit after this file; the merge ask states the audited head)
- merge-base(mainline, arc/honest-oracle) = `a8da194b2` = the mainline
  head → **ff-only is possible today** (branch is a strict descendant).
- `arc/workbench-v2` (arc 11): `bfe16ad17e3c88884655ff15aec54978db26eb81`
  (also based on `a8da194b2`).
- **lem-lean: ZERO changes** — no lem branch pair exists for this arc
  (charter expectation held); opam pin + Lake manifest untouched
  (`lake-manifest.json`, `lakefile.lean` not in the diff). No pin
  dance needed.

## Serialization with arc 11 (both orders stated)

File-level intersection, measured
(`git diff mdd..branch --name-only`, comm -12): exactly ONE file —
`lean_frontend/CLAUDE.md` (arc-11 edits the check_proof_size
paragraph at ~line 106; arc-12 adds a scripts-table row + a pipeline
-status line, both additive, different regions). Cross-merge dry run:
`git merge-tree --write-tree HEAD arc/workbench-v2` → exit 0, ZERO
conflicted files (auto-merges cleanly).

- **Order A (arc 11 first):** mainline ff-forwards to `bfe16ad17`;
  arc-12 rebases onto it (expected conflict-free per the dry run),
  re-runs the full gate (below), re-asks, then mainline ff-forwards
  to the rebased arc-12 head.
- **Order B (arc 12 first):** mainline ff-forwards to the audited
  arc-12 head; arc-11 rebases (same single-file, conflict-free
  expectation), re-gates on ITS bars (note: arc-11's relsem/test
  surfaces are disjoint from arc-12's oracle surfaces — but its
  in-build gates rerun against the floored oracle-side scripts
  unchanged for it), re-asks.

Constraint honored: merges serialize; the second stream rebases +
re-gates + re-asks. No merge commits, no pointer surgery.

## Pre-merge gate (run at the audited head; verbatim results banked in the S1/S2+S3/results records for THIS head)

Tier A / gates, all green at S4 close (re-run after any rebase):
1. `./scripts/test_unit.sh` — exit 0 (includes check_fork_drift with
   the refreshed manifest, sync gates, axiom censuses, totality/purity).
2. `./scripts/test_parse.sh` ALL, `./scripts/test_core.sh` 106/106.
3. `./scripts/test_exec.sh tests/minimal` — 103/106 comparable-agree,
   `cerb_floor=0`.
4. ci / coverage / float / debug `--check-baseline` lanes — 0
   regressions, `cerb_floor=0`; bytes + multi_tu ALL.
5. `./scripts/test_verify.sh` — 29/29 (pin-provenance byte-stable).
6. `./scripts/test_libc_exec.sh` — 7/7 (D2 export exemption);
   `./scripts/test_libxml2_uri.sh` — GATE PASS 16/16 (D2 grandfather).
7. Tier B: `./scripts/test_libxml2.sh` — 4/4 slices MATCH.
8. Corpus: `./scripts/test_csmith_corpus.sh --check-baseline` (full or
   sharded union) — 0 regressions vs the arc-12 re-baseline.
9. Neutrality invariants: `make lean-prelude-src` → zero
   generated-Lean diff; `check_fork_drift.sh` OK with layer-2 hashes
   unchanged.

## Audit hand-off (mandatory scopes per charter S4 + D3 additions)

(a) numbering stability (adversarial: any oracle-output change outside
the loud classes; pin-provenance + generated-tree checks re-run
independently); (b) floor soundness (plant a beyond-margin case;
verify loud; try to corrupt UNDER the floor); (c) baseline honesty
(every moved row justified — the 51 rank-changing corpus rows + the
465 relabels); (d) filing-draft fidelity (repros re-verified
un-forked); (e) D2 exemption soundness argument (main.ml:246 discard +
byte-identical exports); (f) grandfather-env containment (grep:
exactly two invocations in test_libxml2_uri.sh); (g) fold-v2
completeness (plant a symbol in an unwalked position → must be seen or
must not compile).

## Forbidden-surface confirmation (for the audit)

Whole-arc diff (`mdd/cerberus-lean..arc/honest-oracle`) = 21 files:
4 oracle OCaml + 4 scripts/baselines + 12 docs/records +
tests/csmith_findings/README.md + lean_frontend/CLAUDE.md.
Grep-verified ABSENT from the diff: `lean_frontend/relsem/**`,
`tests/verify/**`, `lakefile*`/`lake-manifest*`,
`scripts/test_unit.sh`, `scripts/check_proof_size.sh`, any `.lem`,
any `frontend/**`, anything in lem-lean (separate repo, untouched).

## Post-merge follow-ups (not blockers)

- Operator: D2 veto decision recorded; F-A/F-B filing per the tray
  checklist (network window).
- Post-arc-13 agenda: the renumbering arc
  (`2026-08-21_arc12-renumbering-case.md`) — retires register G1–G4.
