# Evidence — pre-merge audit of `arc/seam-hygiene` (`0457732e1..34b8e15a8`), 2026-09-19

[AGENT auditor] (Claude, Fable 5.1). Every file here is my own run in `worktrees/cerberus-lean-audit/seam-hygiene` at `34b8e15a8` after the rebuild in `00-rebuild.log`. Outputs are verbatim captures; `.py`/`.lean` files are the instruments that produced them. Numbering follows the report's scope items (`../2026-09-19_seam-hygiene-audit-premerge.md`).

| file | what |
|---|---|
| `00-rebuild.log` | the serialized rebuild of both engines (lem-sync stale → `make clean-prelude-src prelude-src`; `build_cerberus`; `make lean-prelude-src`; `build_lean`; both freshness checks OK) |
| `01-classify_hunks.py` / `.out.txt` | item 1: the mechanical hunk classifier over the three code commits' seam-file hunks and its full output (per-hunk classes, the 109 leaf-swap tally, the prefixed sites) |
| `02-AuditProbeA.lean` / `.out.txt` | item 2/4/5: the orchestrator's two `rfl` probes (fail), `#print failwithI` (opaque), `#print axioms` trio, `oomKill`/`STD_`/timing by `rfl`, the auditor's own arm-reduction lemmas (`eqPtrval` ×2, `lePtrval`, `ltPtrval`, `intfromptr`, two guard shapes) |
| `02-AuditProbeVacuity.lean` / `.out.txt` | item 2: the test's `#guard_msgs`-on-failing-`rfl` pattern pointed at the PRE-H1 `combineProv` text → RED; at the head function → GREEN; the transparent leaf reduces by `rfl` |
| `02-AuditProbeDefault.lean` / `.out.txt` | finding M4: `default : CerbSwitch` at the head is `.pointer_arith .PERMISSIVE`, no longer `.strict_reads` |
| `03-codec_plants.py` / `.out.txt` | item 3: 17 cases × 3 policies against the BASE and HEAD `observations.py` side by side (batch identical; origin-set moves; FUEL precedence; forged origins) |
| `03-immaculate_crash_rows.out.txt` | item 3: the 11 `MATCH \| L=CRASH` rows' Lean stderr heads from the FULL run's B5 raw captures, each message checked against the base `panic!` literals |
| `04-switch_refusal_oracle_vs_lean.out.txt`, `04-switch_refusal_lean.out.txt` | item 4: the fork oracle ACCEPTS `--switches=strict_reads`; the Lean driver refuses every spelling (exit 2, attributed) |
| `05-AuditProbeBeq.lean` / `.out.txt` | item 5: the retired `beqMemValueImpl` body (verbatim, as `partial def`) vs the head `BEq MemValue` on all 1 156 ordered pairs of 34 adversarial values — 0 disagreements |
| `06-check_failure_reach_gate.out.txt` | item 6: the register gate at the head (census kept for the plants) |
| `06-register_column_diff.out.txt` | item 6: base-vs-head register, column by column, seals recomputed |
| `06-seal_plants.out.txt` | item 6: five scratch-register plants (reach flip, token flip, msg de-prefix → SEAL MISMATCH; need edit → OK by design; resealed flip → OK with moved counts) |
| `07-census_plants.out.txt` | item 5: three plants on a scratch root for `check_theorem_axioms.sh` (unregistered opaque, missing registered opaque, surviving deleted seam pin) + the unplanted control |
| `08-check_record_quotes.py` / `.out.txt` | item 8: every verbatim line of the record searched in the worker's evidence dir (168 quoted; the unresolved ones are M1 and N4) |
| `09-release-full-summary.txt`, `09-release-full-lanes.txt`, `09-release-full-tails.txt` | item 7: the CLEAN FULL battery at the head — `summary.txt` verbatim, the RUN/PASSED lines, the last lines of each lane's stdout |
| `10-with-lean.txt` | item 7: the three-engine `--with-lean` report at the head |

Scratch (`.tmp/audit/`, git-ignored): the diffs, the scratch census root, the reach census, the release evidence tree (`.tmp/audit/release-full/`, raw observations) — ephemeral.
