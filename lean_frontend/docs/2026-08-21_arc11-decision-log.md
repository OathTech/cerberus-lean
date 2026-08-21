# Arc-11 decision log

- **D1 [AGENT] — S0 boundary verified; the four §12.7 flags RATIFIED.**
  Commit 31d3c6be4 docs-only, tree clean; re-validation reproduced the
  arc-9 evidence (44/79 exact, census exact, St-v2 boundary
  kernel-defeq at symbolic n) with ONE honest gap: the closed entry
  certificate's shaping recipe was session-scratch and did not survive
  the worktree prune — S1 batch-3's exit test re-derives it via
  trace→replay (upgraded from nice-to-have to the batch's acceptance
  test). Archaeology lead for S1: the S3 build record's configuration
  matrix documents the closing configuration at b44bbdfbf; the engine
  diff b44bbdfbf..head bounds any closure-relevant drift — check both
  before re-deriving from scratch. Ratifications: F12-1 footprint
  incremental-IN/wholesale-DEFERRED (evidence-based; T7 re-price
  trigger stands); F12-2 preview trust = layered guards (the M-priced
  structural monad is recorded as an option if the S5 audit finds the
  layers thin); F12-3 ambiguity static+same-prio-dynamic (full sweeps
  available in preview at slice boundaries); F12-4 sealing-as-default
  surface change (inside the blessed charter; regression bar binding).
- **D2 [AGENT] — S1 boundary verified; S2 GO.** Four batch commits
  (8bd81b7ba/60c351a04/c47c7b8d0/12977f0c9) re-verified: unit 7/7
  (ban list now incl. app_walk_preview), verify 29/29, exec zero
  movement, entry5_walk present as a committed theorem
  (T5Prefix.lean:629, in-build kernel-accepted). The S0 gap is
  CLOSED-BY-EXIT-TEST; the bench thesis-numbers accepted (discovery
  2350ms / cold 39985ms / replay 2593ms — the ~15x replay economics
  the T5 climb needs). Recorded deviations accepted (grammar
  extensions, preview-keeps-certs, deferred fingerprint components +
  per-addDecl kernel split → S5). Register items accepted:
  sealStates entry-store early stop (S2 material — the store-i hadv
  case); the async record/replay sequencing contract (Elab.async
  false, elab warnings — S5 audit visibility). S2 (the T5 climb) is
  GO: the stuck round is typed SEMANTIC with the trace instrument
  live, the gating context-query mode is built for the
  continuation-lambda advance law + round_run_jump, entry5_walk is
  the proof's first segment. D3-class stop rule armed as chartered.
