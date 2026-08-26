# Arc-18 R0 — pre-merge audit record (C0–C4 → mainline)

Independent auditor (fresh agent, standard scope proposed to and not
trimmed by operator), 2026-08-26. Audited HEAD
`cfeb7af5e6a07b6647776ece06a6d9cf2813bc25` (branch `coherence`, clean
tree) against merge base `da279e0cb` (ancestor confirmed; ff shape
valid). 23 commits, 65 files. All batteries re-run by the auditor
(worker green never accepted), strictly serial, CERB_MEM_MAX=48G,
exit codes checked; longest pass ~6 min (grind tripwire untouched).

## VERDICT: MERGE-SAFE — zero MAJOR; 4 MINOR fix-forward; 5 observations

Merge executed 2026-08-26 on [USER] sign-off ("land these first"):
`mdd/cerberus-lean` ff-forwarded da279e0cb → cfeb7af5e.

## Independent gate re-run (verbatim summary lines)

- `test_unit.sh` exit 0: `Total: 7 passed, 0 failed`; gates:
  `check_exec_purity: CLEAN (11 modules)`; `check_theorem_axioms:
  hand-written axiom census OK (0 axioms — the arc-17 S2b end
  state)`; `check_theorem_axioms: generated-tree census OK (195
  files: 0 axioms, boundary opaques present, 0 unsafeCast)`;
  `check_lem_sync: OK`; `check_fork_drift: OK — layer 1: 59
  oracle-surface files = manifest; layer 2: 20 differing generated
  files, all hash-pinned`; `check_proof_size: OK` (incl. honest
  `T5.lean — not present yet (registered, pending)`);
  `check_chase_freeze: OK — ... (8/8 allowlisted files present)`;
  `check_one_route: OK — one state interpretation on the live route
  (34 modules OwnP-free; coexistence hazard clear; OwnP binders
  confined to the retirement register + the labeled T6 exemption)`;
  `check_engine_size: OK (reporting instrument...)`; in-build:
  `runEffectful no-cone gate: carrier set exact (112 registered
  ambient-family theorems; no acquisition, no stale entries)`.
- `test_verify.sh` exit 0: `test_verify: 35 passed, 0 failed (6
  fixtures, 22 harness points)`.
- `test_speclab_divmod.sh --gate` / `test_speclab_seed.sh --gate`
  exit 0: `PASS (--gate)` both, plant-RED lines present.

## Verified claims

- **Statement byte-stability (C4 R6):** true rename
  `relsem/RelSem/Threaded.lean → relsemcore/RelSem/Threaded.lean`
  at 963b4b52d; every statement def textually unchanged
  (T1/T2/T3ThreadedStatement: zero diff lines across the slice;
  CallHarnessAdequateThr absent from the diff). The two OwnP-typed
  bridges left the file but live in PerStepOwnP.lean (moved at C2,
  not lost). Independent LSP cross-check outside lake's cache:
  `RelSem.T1.T1Threaded` and `SpecLabProofs.harnessRunsTo_exclusive`
  cones both exactly {propext, Classical.choice, Quot.sound}.
- **Axiom/cone discipline:** diff-scoped grep of added lines — zero
  sorry/axiom/native_decide/bv_decide/ofReduce (hits are the
  engine's fail-closed rejection throwErrors); zero heartbeat/
  recursion-depth bumps. Census pins match records: 69 step_laws
  (Audit.lean), sweep pin 6784, carrier 112 exact, speclab slate =
  50 by enumeration.
- **The C4 [AGENT] seed-parametricity call:** logged with provenance
  in three places (C4 record §2, Threaded.lean header, commit
  message), rationale stated, consistent with the arc-16 T4
  collision finding; ∀-seed appears only in the two family TARGET
  shapes, both carrying in-file HONESTY LABEL: UNPROVED with
  kernel-checked sample_of_family anti-vacuity links. No trust
  failure.
- **Records vs reality:** C1 registry + census pin; C2 one-route
  gate green, Q1 deletions confirmed (PerStepPeel/PerStepLaws
  gone); C3 identity law + sub-trio pins present; C3b walks observed
  live (`derive_rounds RelSem.T5W.bxzero ... (43 rounds,
  terminal=true)` matching the record verbatim); contracts-doc
  register rows match; parks honestly stated.

## Findings (all fix-forward; movers in the charter's FF register)

- **MINOR-1** probe-recipe breakage for the C1-decomposed engine
  modules: `lake lean` on files importing RelSem.RoundEval.Core
  resolves the module to the ROOT package's build tree and fails
  (repro: `lake lean RelSem/RoundEval/Rounds.lean`); `lake build` +
  gates unaffected. Root `.lake` also carries arc-11-era orphan
  artifacts due for stale-shadow deletion. → FF-1.
- **MINOR-2** two intermediate commits not standalone-buildable
  (disclosed in their messages; HEAD fully validated) — bisect
  hole, hygiene not integrity. → FF-2.
- **MINOR-3** engine-size baseline stale: 5207 (C3) vs 5680
  measured (+473 across C3b/C4), 9 standing WARN lines; growth
  unmentioned in the C3b/C4 records. → FF-3.
- **MINOR-4** PROOF.md §3 stale re T4 (says "scheduled to complete
  ... (arc-18 C3)"; C3 ran, T4 did not complete, R5 OPEN) and the
  landed T5 substrate. → FF-4.
- **Observations:** (a) "kernel-witnessed FALSE" wording in the C4
  record/Threaded header overstates the acceptance doc's careful
  reading (collision kernel-witnessed; falseness additionally rests
  on the capture argument) — decision correct under either reading;
  (b) DivModFiles.lean:191 cites C4 record §4, is §3; (c) C4 record
  quotes the no-cone gate at Audit.lean:1151, now 1160 (content
  identical); (d) cosmetic `grep: binary file matches` noise in
  check_theorem_axioms over relsem/.lake/build/bin (pre-existing);
  (e) audit-environment note: sandbox /tmp is write-only — audit
  logs live at container .tmp/audit18/, both battery runs exit 0.
