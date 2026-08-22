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
- **D2 [AGENT] — S1/S2 boundary verified; S3 GO.** Orchestrator
  re-verified at 59781c611: unit 7/7 (both packages), drift gate
  green (56-file manifest, renumber=arc13), exec zero movement with
  cerb_floor=0, uri 16/16 plain (grandfather gone), and an
  independent byte-identity spot: fork and upstream --pp core
  output LITERALLY IDENTICAL on t1_id (a_525 both sides). THE
  ECONOMICS FINDING accepted with its honest refinement: full proof
  package re-elaboration = 30.5s / zero manual edits (1,510
  scripted token replacements) — at T1-T4 scale renumbering is
  essentially free and REPLAY WAS NOT NEEDED (no stored traces;
  the 15x thesis becomes load-bearing only at T5-walk scale) — the
  workbench prediction refined, not refuted, and recorded as such.
  516 floors → real verdicts with mismatch=0 (three-way 6/6
  byte-level); exploration yield 5x on the identical seed block;
  jitter pair re-recorded properly under the B-F5 bar (3x uncapped,
  stable). Parked items handled: notes/upstream/07 addendum
  appended by the orchestrator (container surface); WalkBench
  breakage REGISTERED (not an arc-13 surface — zero tactic diffs;
  mover = workbench maintenance at the T5 resumption). S3: results,
  de-stale, audits (mandatory scopes per charter incl. the re-pin
  completeness tree-wide old-id sweep), checklist.
- **C1 [AGENT, S3 audit correction — D1's text above left untouched
  per record doctrine].** D1's payoff clause (iv) ("the drift
  manifest's F-D-family deltas shrink toward upstream") stated the
  wrong object (audit finding B-F4). The TRUE claim, and the one the
  evidence supports: the fork oracle's OUTPUT/numbering divergence
  from upstream went to ZERO (byte-identity, triple-verified — S0
  probes 11/11, libc dump, D2's independent spot). The SEAM-CODE
  manifest deltas did NOT shrink: of the six re-pinned
  [expected-semantic] generated files, four are size-unchanged
  (cabs_to_ail 24→24, cabs_to_ail_effect 85→85, core_reduction
  30→30, core_run 17→17 changed lines vs upstream) and two GREW
  (core_run_aux 16→20, driver 1→3) — all six justified
  (target_rep call-site rewrites to Fork_renumber.*; measured at
  the audit fix against the mainline generated tree). The
  correction is propagated with labels at the S0 doc §6 and the
  results cascade table; D1's decision itself (scheme R-B) is
  unaffected — byte-identity, not delta size, was its load-bearing
  evidence.
