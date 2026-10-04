# lem re-pin to 4e70bb5 — gate record before landing (2026-10-04)

Range: `mdd/cerberus-lean` `9e63218bc` → `arc/lem-repin-4e70bb5`. Author: the orchestrator [AGENT]. Pre-merge audit:
`docs/2026-10-04_lem-repin-4e70bb5-pre-merge-audit.md` (MERGEABLE WITH FIXES; A1/A2/A5 fixed with new selftests, A4
corrected, A3 recorded; the A3 key-disambiguation proposal queued after landing, [USER 2026-10-04] "agree 1-4").
The shared switch's lem and `deps/lem-pinned` were moved to `4e70bb5` ([USER 2026-10-04] "1 / 2 approved"), after
notifying the SC and cerberus-sl sessions; nothing was running on the switch.

## Full ladder on `31732f750` (clean tree, switch lem `4e70bb5`), 2026-10-04T18:43:10Z–20:33:23Z — verbatim

```
=== FULL LADDER on lem repin 4e70bb5 2026-10-04T18:43:10Z head=31732f750 status_lines=0 lem="Lem lean-backend-v0.1.0-alpha.1-63-g4e70bb5" ===
full: passed; 40/40 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== RELEASE EXIT=0 2026-10-04T20:33:23Z ===
```

## Row 1 after the audit fixes (purity gate, fuel-parametricity check, their new selftests) — verbatim

```
Total: 16 passed, 0 failed
check_exec_purity: SELFTEST OK (17 plants with the declared verdict and message; real tree CLEAN)
check_exec_purity: CLEAN (11 modules)
gen_fuel_parametricity: SELFTEST OK (6 plants with the declared FAIL, unplanted control OK, real tree OK)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
```

Derived: the commits after `31732f750` are the audit record, two gate-script fixes (exercised by row 1 above), and
docs.
