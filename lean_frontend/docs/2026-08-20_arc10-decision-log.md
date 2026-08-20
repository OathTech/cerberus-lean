# Arc-10 decision log

Provenance-tagged per doctrine: [USER] = operator-decided, [AGENT] =
orchestrator judgment call resolved by project principles.

- **D1 [AGENT] — S0 boundary + the six open questions.** Orchestrator
  independently verified: commit a0f3706ab = triage doc + 2 NEW
  scripts only (no forbidden surface, no existing script modified),
  unit gate re-run rc 0. Rulings on the S0 questions:
  (1) Finding 8 (msum-fork trace-count signature, now csmith-forced
  by seed 930005): CerbMem-only attempt PRE-AUTHORIZED in S4; PARK at
  first CerbND contact — the forbidden-surface line is absolute.
  (2) test_exec.sh SKIP_BUILD opt-in env for creduce throughput:
  ALLOWED as an instrument change under the arc-5 discipline — own
  commit, justification, semantics unchanged when unset, zero
  movement evidenced.
  (3) Set-comprehension stub: FOLDED INTO S2 (same fail-closed
  opaque-emission class; coherent with the sweep).
  (4) Column-0 emission: stays PARKED (cosmetic; S2 is already the
  arc's largest slice — no scope creep).
  (5) CerbMem gate-scan extension: PARK CONFIRMED (arc-9
  coordination; post-merge candidate).
  (6) Arc-4 findings 24-30 one-liner extraction: ACCEPTABLE for S4
  classification, provenance labeled DERIVED-from-register (never
  formatted as quotes — the verbatim doctrine).
  Also accepted from S0 evidence: the stack-ceiling register entry is
  STALE (onset now 16384<N<=24576, loud exit-134, not quiet — the
  arc-7 totalization presumably moved it); the S5 results doc carries
  the correction, the item remains FORBIDDEN-surface parked.
- **D2 [AGENT] — S1 boundary verified + coverage-baseline call
  RATIFIED.** Orchestrator re-ran: unit 5/5 (sync gate 21 files),
  minimal zero movement, ci `BASELINE OK` (first re-run attempt used
  the wrong baseline file — --check-baseline defaults to the minimal
  baseline; operator-education note: ci needs
  `--check-baseline=scripts/exec_ci_baseline.txt`). The flagged
  coverage flip (mem3-004-string-write-attempt DIFF → UB_MATCH) is
  RATIFIED as expected-in-class: the file's own header cites
  select_ro_kind impl_mem.ml:1704-1710 — it is a finding-11 test by
  construction; the S0 triage row's pp-class listing was inference,
  now corrected. Scoreboard: ci 111/114 (derived). Finding 11 CLOSED
  (register). Commit 3b82fac70 coherent, no forbidden surfaces.
