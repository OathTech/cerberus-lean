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
