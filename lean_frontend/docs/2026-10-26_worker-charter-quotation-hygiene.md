# Worker charter: quotation hygiene and the stop-vocabulary amendment (2026-10-26)

Branch `feature/quotation-hygiene`, worktree `worktrees/cerberus-lean-feature/quotation-hygiene`,
based on mainline `704c4e697` (Lean 4.35.0, lem `e6d8db5`). Worker: a Fable subagent.
Status: ACTIVE from dispatch. A second slice (`fix/anonymous-members-refusal`) runs in
parallel on this box: see "Box rules".

## Why and what was decided

- [USER 2026-10-21] rulings B and C of the Core-quoting D5 re-review
  (`lean_frontend/docs/2026-10-20_core-quote-d5-rereview.md`): (B) mirror the port's
  resolved-path library-location rule into the fork's OCaml oracle so both engines agree;
  (C) refuse quotation under non-canonical runtime spellings instead of emitting
  machine-specific literals silently. [AGENT 2026-10-21] packaged as this follow-up slice.
- The stop vocabulary (outcome protocol, design
  `lean_frontend/docs/2026-10-20_outcome-protocol-design-v2.md`) has no boundary for
  model-level refusals: the two inner_arg_temps libc refusals carry boundary `cli`, item
  `--libc`, as a stopgap, and item G's two memory-model refusals are legacy panics
  (TODO.md entries from 2026-10-26). This slice drafts the amendment and migrates them.
- Two queued transport/lane items from the inner_arg_temps review
  (`lean_frontend/docs/2026-10-26_inner-arg-temps-premerge-review.md` P2-3, P2-4) and
  one from the Core-quoting re-review (P3-2) are in scope because they touch the same
  files.
- Standing rules (container `CLAUDE.md`): upstream's judgement stands, mistakes are
  overridden in BOTH engines and registered as fork-ahead deltas with the tray report;
  no silently wrong answer; refusals are declared, attributed stops.

Read first: the container `CLAUDE.md`, `lean_frontend/CLAUDE.md`, the two reviews above,
the outcome-protocol design and record, `lean_frontend/docs/2026-10-18_core-quote-record.md`,
the consumer note `2026-10-18_consumer-note-cerberus-caesium-core-quote.md`, and
`scripts/check_runtime_resolution.sh`.

## Checkpoints (commit per checkpoint on green focused checks; Tier A at each commit;
## the full battery at close-out)

### Q1 — mirror the resolved-path library-location rule into the oracle (ruling B)
- Today: the oracle's `util/cerb_location.ml:512-523` `is_library_location` compares the
  literal `Filename.dirname path` against literal `Cerb_runtime.in_runtime` keys; the port
  (`CerbLocation.lean` suffix test + `Main.lean` `refuseLibraryLocations`, resolved-directory
  membership) accepts any spelling that resolves to a library directory, so a `./`-prefixed
  or absolute label is classified differently by the two engines and the served UB
  location can differ (the D5 pin in `check_runtime_resolution.sh`: dot `<2:10--2:15>`
  oracle vs `<11:10--11:23>` port).
- Change the FORK's oracle rule to resolved real paths (`Unix.realpath` or the fork's
  existing helper) of the label's directory against the realpath'd runtime library
  directories, so both engines classify identically. Mirror doctrine: cite the port's rule
  at the site; document the divergence from pristine upstream as the deliberate fork-ahead
  delta (tray 58 is the report; mark its remedy "implemented in the fork").
- The served-divergence pin becomes an AGREEMENT check: dot and nodot plants must now
  agree between engines (keep the plants; flip the expectations; a plant whose engines
  disagree is red). Re-pin `util/cerb_location.ml`'s `[source-content]` row with a dated
  NOTE (never `--refresh`). Update VALIDATION's guard and Z-67 entries, README's
  convention bullet, the consumer note: the admitted divergence class no longer exists.
- Watch the pristine-oracle lanes (B10.x): the pristine binary keeps the literal rule; the
  lanes use absolute spellings on both sides so no row should move — if one does,
  register it exactly (the inner_arg_temps B10.1 precedent), never baseline it blindly.

### Q2 — refuse quotation under non-canonical runtime spellings (ruling C)
- With `--quote-core` or `--quote-libc`: the driver REFUSES (a REFUSAL envelope through
  `CerbStop.exitRefusals`, boundary `runtime`, item `--runtime`, exit 2, empty stdout)
  unless the runtime is given in the canonical relative spelling the convention states
  (`_build/install/default` from the project root, or a directory carrying that fixed
  relative runtime link) AND every source label of the inputs is portable (relative,
  under the project root). The refusal names the first offending spelling or label.
- Witnesses in `check_runtime_resolution.sh` (an absolute `--runtime` with
  `--quote-core`; an input with an absolute label; the canonical case as the control);
  `test_stops.py` keeps decoding the envelope; VALIDATION, README, the consumer note say
  the rule.

### Q3 — the stop-vocabulary amendment: model-level boundaries
- Draft a dated amendment section in the design v2 adding boundaries `libc` (library
  transport refusals) and `memory` (declared refusals in the concrete memory model where
  upstream left a TODO), [AGENT, proposed; the operator ratifies at landing]. Implement:
  `CerbStop.Boundary` constructors and their JSON names; `scripts/observations.py`'s
  accepted boundary names; `CerbStopSites.lean` metadata; the register-migration TSV;
  plants in `scripts/test_stops.py` and the lanes' stop-policy matrices
  (`test_observation_lanes.py --stop-policy-only`).
- Migrate: the two inner_arg_temps libc refusals (`Main.lean`, `R-IAT-LIBC-SYMBOL-LOSS`
  and the dump/mode calling-convention mismatch) from boundary `cli`/`--libc` to `libc`;
  item G's two memory refusals (`CerbMem.lean`: the overlapping-memcpy and
  invalid-alignment leaves, record `2026-10-20_item-g-refusals-record.md`) from legacy
  `failwithI` texts to `failwithI (CerbStop.render (.refusal …))` with boundary `memory`,
  keeping each leaf's kernel face opaque and the ND node shape unchanged (the allocator's
  `NDkilled (CerbFail.failStopKill …)` form stays; only the rendered text changes).
  TRUST SURFACE: `CerbMemAccessFacts`, `CerbMemAllocatorProofs` and
  `Unit.MemoryAccessProofs` must keep every statement; kernel replay over them (and
  `CerbStopSites`) before the checkpoint claim; the item-G witness script's pinned texts
  move to the envelope form (explain). The union-initializer refusal (generated Lem
  `error`) stays legacy, stated.
- Update the consumer notes (caesium, cerberus-sl) and the outcome-protocol record's
  "incoming refusals" table.

### Q4 — the bare-name census speedbump (inner_arg_temps review P2-3)
- `scripts/libc_prep.sh --check`: for both dumps, print each library at `-d5`
  (`name{n}`), group by name per proc, and compare the set of procs whose bare names map
  to more than one symbol number against a reviewed, committed register (the review's
  list: 7 procs in the variant dump, 10 in Normal); a new entry fails loudly. State in
  VALIDATION that this is a speedbump, not transport fidelity. Plant it.

### Q5 — the csmith-corpus row for inner_arg_temps (review P2-4)
- A Tier C (reporting) row running `scripts/inner_arg_temps_lane.py`'s fuzz logic over
  `tests/csmith/*` (1669 files that pass the frontend) under the switch: engine agreement
  within the mode on complete sequences; cross-mode distinct-outcome SET equality on the
  oracle; record size, time and classes in the record. A discrepancy is a FINDING (stop,
  report, tray draft), never a baseline. This is a measurement sweep (grind tripwire:
  justify its wall time in the record before running it; shard if needed).

### Q6 — a richer linked quotation population (Core-quoting re-review P3-2)
- Add to the Core quotation test a linked multi-TU case that populates the comparator
  positions asserted by reading only (an enum definition, a cross-TU extern, a static
  with an initializer); it joins row 1's round trips.

### Close-out
- Record `lean_frontend/docs/2026-10-26_quotation-hygiene-record.md`: every change
  file:line, every gate verbatim, the amendment text, the kernel replay, the census
  register, the csmith sweep figures; TODO.md entries closed; tray 58 updated; consumer
  notes; CONTRACT entries as needed (the model-level refusal boundaries); full battery.

## Non-goals
No lem-lean change; no semantic change beyond the ruled refusals and the mirrored
rule; the union-initializer refusal stays as it is; the merge-base bump is parked.

## Box rules and practices
Another worker (`fix/anonymous-members-refusal`) runs in parallel. Before any Tier A or
battery: `uptime` 1-minute load below 8 AND no other `release.py` running (check
`ps -u dev -o args | grep -c '[r]elease.py'` is 0); otherwise wait and retry every two
minutes. Capped builds may overlap. Every lake/lean call through `scripts/capped`.
One coherent commit per checkpoint; provenance tags ([USER …] only for the operator's
rulings; relayed orchestrator text `[AGENT …, relayed by the operator]`); never quote
the operator; never `pgrep -f`/`pkill`; no push; park (committed park record) on any
wrong premise or any baseline movement outside the stated expectations.
