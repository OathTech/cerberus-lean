# Arc 12 charter: the F-D repair + upstream filings ("the honest oracle")

Date: 2026-08-21. Mode: long-cycle autonomous under the orchestrator/
worker doctrine, PARALLEL STREAM alongside arc 11 (workbench v2).
BLESSED by operator via launch, 2026-08-21. Branch: `arc/honest-oracle`
(cerberus-lean; lem NOT expected — tripwire below).

## Objective

Make the fork's oracle HONEST: the F-D declaration-layout corruption
family (arc-10 reattribution; drift-review S1/S2/S3 members) becomes
IMPOSSIBLE — replaced by loud fail-stop — without changing the
oracle's symbol numbering or the Lean artifact; plus the upstream
filings (F-A, F-B) prepared/finalized. Inputs:
`notes/2026-08-21_fork-drift-review.md` (the three-member family,
the recommended mover, drafted probes),
`docs/2026-08-20_arc10-s4-csmith-campaign.md` §root-cause (tested
predictions), `tests/csmith_findings/` (35 witnesses),
`deps/cerberus-upstream` (built oracle — the acceptance instrument;
recipe: notes/2026-08-21_upstream-oracle-build.md).

## THE REPAIR STRATEGY CONSTRAINT (parallel-safety, binding)

The repair is the FAIL-STOP FLOOR route: mirror the Lean side's
protection (native/fresh_int.c's collision floor semantics) into the
oracle (`util/cerb_fresh.ml` and/or the minimal .lem-level ocaml
target_rep restoration) such that (a) symbol NUMBERING IS UNCHANGED
for every program within the margin — the pinned .core fixtures and
ALL pin-provenance gates stay byte-stable; (b) beyond-margin
programs FAIL LOUDLY (a distinguishable oracle error) instead of
corrupting. RENUMBERING IS OUT OF SCOPE (a later upstream-
coordinated change; record the design note). TRIPWIRES (each =
STOP + operator report): any change to the generated LEAN tree
(check: regenerate + diff = empty), any pin-provenance gate failure,
any .lem edit that is not Lean-token-neutral (verify per edit), any
lem-tool change.

## Parallel-stream discipline (binding)

Write surface: `util/cerb_fresh.ml` + oracle-side OCaml on the
repair path, `frontend/model/` ONLY under the token-neutrality
tripwire, `scripts/fork_drift_manifest.txt` + the drift gate's
pinned hashes (the repair legitimately moves excused-diff hashes —
refresh with justification), exec baselines (F-D rows flip
wrong→loud; every row justified), `tests/csmith_findings/` (witness
reclassification), `notes/upstream/` + filing drafts, docs.
FORBIDDEN: `lean_frontend/relsem/**`, `tests/verify/`,
lakefile/manifest, `scripts/test_unit.sh` + `check_proof_size.sh`
(arc 11's declared surface), lem-lean, hand-written Lean seams.
Merges serialize with arc 11.

## Slices

**S0 — confirm the mechanism (the drift-review probes).** Execute
the drafted probes: the duplicate-(digest,num) scan (`--pp core` /
`-d 5` over >600-decl inputs), the margin measurement (exact
ambient-counter budget), and the S1-vs-S2 member attribution test
(which threading member causes which witness class — the campaign's
head/tail predictions extended). Output: the repair design note —
where the floor goes, what the loud error looks like (a NEW
distinguishable error class, greppable, mirroring the Lean side's
fail-stop message style), which witnesses will reclassify.

**S1 — the floor.** Implement per S0. Bars: (a) all 35 F-D witnesses
reclassify wrong→loud (or, for those within margin, stay correct) —
NONE may remain silently wrong; (b) the three-way instrument
agrees: fork-with-floor ≍ upstream ≍ Lean on every in-margin
witness (upstream oracle per the build recipe); (c) pin-provenance
gates + test_verify byte-stable; (d) generated-Lean diff EMPTY;
(e) standing corpora zero movement outside the justified F-D rows;
(f) the fork-drift gate's hash pins refreshed with the repair as
the recorded justification.

**S2 — witness + baseline reclassification.** Baselines updated
(each F-D row: old status → new loud status, justified);
tests/csmith_findings manifest updated (family status: REPAIRED —
fail-stop; renumbering deferred, design note pointer); the arc-10
results/register cross-referenced by addendum (never rewritten).
Re-run the affected lanes: csmith corpus full pass (sharded),
ci/coverage baselines, one exploration-lane spot batch.

**S3 — upstream filings.** F-A (initializer desugar) + F-B
(address-constant strictness) finalized from the tray: un-forked
repros (verified against deps/cerberus-upstream at b9aeedcb4),
proposed remedies, bug-vs-intended classification (the standing
[USER] requirement), filing-ready text. FILING ITSELF IS
OPERATOR-GATED (network + judgment) — the arc delivers the ready
drafts + a filing checklist. The F-D family is NOT filed (ours);
its design note includes the eventual upstream-coordination sketch
(the renumbering question touches upstream's own margin).

**S4 — close-out.** Results (before/after witness table verbatim;
three-way agreement evidence; margin numbers), decision log, docs
de-stale (the F-D qualifiers across arc-10 records get
resolution-addenda), register updates (F-D CLOSED-BY-FLOOR;
renumbering = new TEMPORAL entry with the upstream-coordination
mover), 2-agent adversarial audit — mandatory scopes: (a) numbering
stability (adversarial: find ANY program whose oracle output
changed outside the loud-error class; the pin-provenance +
generated-Lean-empty checks re-run independently); (b) floor
soundness (can corruption still occur under the floor? plant a
beyond-margin case, verify loud); (c) baseline honesty (every moved
row justified); (d) filing-draft fidelity (repros re-verified
un-forked). Fix-or-record; merge checklist (serialize with arc 11).
Stop. Do not merge.

## Success conditions (machine-checkable)

1. ZERO silently-wrong oracle verdicts remain across all 35
   witnesses + the swept corpora: every F-D case is either correct
   (in-margin, three-way-agreeing) or loudly failing (new error
   class).
2. Symbol numbering provably unchanged: pin-provenance byte-stable,
   test_verify 29/29, generated-Lean diff empty, minimal/uri/
   chvalid/libc zero movement.
3. Drift gate green with refreshed hashes + justification; the
   manifest documents the repair.
4. F-A/F-B filing drafts ready (un-forked repros verified, remedies,
   classifications); F-D design note with the renumbering TEMPORAL
   entry + mover.
5. Zero forbidden-surface touches; zero lem changes; records
   complete; branch gate-green; merge checklist ready.

## Risks / tripwires

- The floor turns out to require renumbering to be sound (e.g. the
  margin is dynamic and unfloorable) → STOP, report: the arc
  replans as a serialized (post-arc-11) renumbering arc with
  fixture re-pinning as a planned cost.
- The S2 member (core_run threading) needs a .lem change that is
  not Lean-token-neutral → same tripwire.
- Oracle rebuild churn: every oracle change re-runs the fast lanes
  before the big ones; capped, 40G while both lanes live.
- Standing: verbatim records, park-don't-improvise, per-merge ask.
