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
