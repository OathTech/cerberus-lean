# Arc-12 decision log

- **D1 [AGENT] — S0 boundary verified; floor design APPROVED;
  attribution correction ACCEPTED.** Commit bde2f8dce docs-only, tree
  clean, inherited gate green. Rulings: (1) The two-check dynamic
  per-TU floor (forward next≤hwm + backward hwm≥tu_first at a
  post-desugar hook) is APPROVED — strictly better than the charter's
  sketch: hand-OCaml only, zero .lem edits, generated Lean AND
  generated OCaml unchanged (tripwires clean by construction,
  drift-gate layer-2 hashes unmoved). Constant-threshold and
  target_rep-restoration correctly rejected (the latter IS the
  renumbering route — deferred design note stands). Loud class exit
  70 + CERB_FLOOR harness bucket approved (SIGABRT would launder into
  CERB_SKIP — good catch). (2) ATTRIBUTION CORRECTED, accepted on
  20/20 + 0/2-control evidence: the April desugar threading
  (8923d6436) is the whole F-D story; the arc-2 core_run supply is
  EXONERATED for all probed witnesses and survives only as the
  mid-desugar composition window the backward check covers. Arc-10's
  "arc-2 sym_supply prime suspect" naming gets a correction ADDENDUM
  in S2 (never a rewrite) — the drift review's S1-primary call is
  CONFIRMED. (3) New register items accepted: sia_csmith_976 latent
  F-D (baselined as perf timeout, actually 97 collisions); the
  coincidentally-correct MATCH class (~25-40 est., collision
  necessary-not-sufficient — S1's battery sweeps the full corpus
  under the floor, not just DIFF rows); --cabs-json floors too
  (CERB_FLOOR-no-Lean-verdict rows); chvalid TU pre-scan required
  before the ladder sweeps. Margin verdict (mode-dependent but
  runtime-known via the single Cerb_fresh.int chokepoint) = NO
  replan tripwire. S1 is GO per the doc §9 plan.
- **D2 [AGENT, flagged for operator veto] — the §7 parked conflict:
  ruling = B+C CONDITIONAL, D deferred-with-case-recorded.** The S1
  floor is green on every chartered bar (generated trees untouched
  AND gate-verified; 35/35+ witnesses loud; full-corpus sweep
  all-justified incl. the 34 coincidentally-correct flips; Tier-A
  untouched). The conflict: S0's libc-margin claim was WRONG
  (S0 addendum committed) — the pinned libc.co/uri artifacts were
  produced by the collision-exposed oracle, and the floor now
  correctly refuses to regenerate them (test_libc_exec RED at prep,
  uri lane RED). RULINGS: (1) Option B — a cabs-json-EXPORT
  exemption — is approved CONDITIONALLY on a soundness verification:
  the exemption is principled ONLY if the exported artifact is
  pre-desugar Cabs JSON and the corrupted desugar result is
  DISCARDED on that path (verify in main.ml; if the export consumes
  desugar output in any way, B is DEAD and this escalates to the
  operator as A-vs-D). (2) Option C — grandfather the pinned
  libc.co/uri expectations with REGISTER findings: the artifacts are
  collision-exposed but validated-by-agreement (uri 16/16 + libc 7/7
  vs the protected Lean side — coincidental-correctness evidence of
  the same class as the 34 corpus rows); each pinned artifact gets a
  register entry with mover = renumbering-era re-derivation; the uri
  gate's records gain an honesty ADDENDUM (its evidence now carries
  the exposure asterisk). (3) Option D (renumbering) stays OUT of
  this arc (the arc-11 collision we designed around) but the S1
  evidence — THE FORK CANNOT REGENERATE ITS OWN LIBC under the
  floor — is recorded as the strongest renumbering case yet; it
  becomes a first-class agenda item for the post-arc-13 slate.
  (4) The charter's "libc/uri zero movement" bar is AMENDED by this
  ruling to "libc/uri validated-by-agreement, grandfathered with
  register + addenda, lanes re-greened via the verified-sound
  exemption" — a success-condition amendment, hence the operator
  flag: veto reverses to Option A (honest red lanes) pending their
  call.
- **D3 [AGENT] — S2/S3 boundary verified; the D2 condition DISCHARGED;
  S4 GO.** The B-soundness verification passed at the strongest
  evidence grade: code-cited (main.ml:246 discards the desugar
  result; cabs_json.ml is a pure function of the Cabs tree, no symbol
  numbers) AND empirical (the 4 beyond-margin libc TU exports
  byte-identical between collision-possible and collision-impossible
  builds). Orchestrator re-verified: unit 7/7, minimal zero movement
  (cerb_floor=0 on Tier-A), libc_exec ALL MATCH, uri GATE PASS 16/16,
  grandfather-mode containment grep = exactly the two documented
  invocations, and a direct floor-fire on csmith_6000098 producing
  the designed self-documenting violation message (backward check,
  range [0..629], F-D pointer). Grandfather register G1-G4 +
  honesty addenda + the renumbering case accepted; filing drafts
  08/09 (both TRUE BUG classified, repros re-verified un-forked
  today) accepted for the operator's filing checklist. The D2
  operator-veto window REMAINS OPEN through the merge ask (veto
  reverses batch 4's lane re-greens to honest-red; the floor itself
  is unaffected). S4: results doc + merge checklist + the 2-agent
  audit with the worker's suggested added scopes (exemption
  soundness, grandfather containment, fold-v2 completeness plant)
  joined to the charter's mandatory four.
- **D4 [USER 2026-08-21] — D2 RATIFIED; veto window CLOSED early by
  the operator.** Verbatim: "yeah, this is fine - leave as is until we
  fix it." The charter-bar amendment (the verified-sound cabs-json
  export exemption + the grandfathered uri/libc surfaces + the lane
  re-greens) now carries operator authority. The grandfathered state's
  EXPIRY is the RENUMBERING arc — operator-ordered the same day as
  parked-for-immediate execution after the arc-11/arc-12 merges (see
  the container CLAUDE.md ruling) — at which point register G1–G4's
  movers execute and the asterisked artifacts re-derive clean. The
  merge ask itself remains operator-gated as always; the merge
  checklist's veto-window step becomes a ratified-note.
