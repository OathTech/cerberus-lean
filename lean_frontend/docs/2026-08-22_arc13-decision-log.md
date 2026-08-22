# Arc-13 decision log

- **D1 [AGENT] — S0 verified; THE SCHEME IS R-B, FULL FORM.** Commit
  41f7684a1 docs-only, tree clean, probe cleanup verified (sources
  reverted, generated trees byte-identical to pre-probe, gates
  green). The decision needs no operator escalation — the evidence
  removed the trade: R-B full (un-thread BOTH forked supplies onto
  the single ambient Cerb_fresh.int, OCaml target only, three
  ocaml-only target_rep seams + the 13-line fork_renumber.ml shim;
  zero .lem body changes; Lean target untouched) delivers (i)
  byte-identity with un-forked upstream on 11/11 probed fixtures
  incl. the flagship F-D case landing on the three-way-agreed value
  and libc.co re-deriving byte-identical to upstream's own; (ii)
  collision impossibility by construction (one supply); (iii)
  generated-Lean diff EMPTY (measured — the tripwire does not
  fire); (iv) the fork's oracle-numbering divergence from upstream
  goes to ZERO (the drift manifest's F-D-family deltas shrink toward
  upstream). R-A1/R-A2 rejected with recorded reasons (same cascade
  without the payoff; leakage + a run-supply growth hazard). The
  floor adapts to the single-supply window check and stays as the
  backstop; grandfather machinery becomes dead code, deleted in S1.
  S1 IS GO per the 8-step plan (implementation → cascade → floor
  adaptation → grandfather dissolution), with the replay-economics
  measurement as a first-class deliverable.
