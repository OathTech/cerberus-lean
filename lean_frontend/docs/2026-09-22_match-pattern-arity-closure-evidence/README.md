# Evidence — the frozen full battery of the match-pattern-arity CLOSURE round (2026-09-22)

The orchestrator's ruling for the closure round (record `../2026-09-20_match-pattern-arity-record.md` §12):
write the record BEFORE starting the battery, touch nothing during it, commit the runner's `report.json`
and `summary.txt` here. Both files are copied byte-for-byte from `.tmp/mpa/closure-full/` (the runner's
`--out`), after the run ended; nothing else in the tree changed between the run's `source_before` and
`source_after` identities (the runner records both in `report.json`: `source_unchanged` must be `true`).

- `report.json` — the runner's full report (lane statuses and wall times, source/build/lem identities before
  and after, the pristine-oracle counts under `B10.1`/`B12`).
- `summary.txt` — the runner's `summary.txt` (the `full: …` / `Source unchanged: …` / `Release certification: …`
  lines), i.e. the verdict quoted verbatim in the record's §12.10.

Expected on this base (mainline `5407597d9`, E-A not landed): 39/39 lanes passed, `Source unchanged: True`,
pristine tier-B `{'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7,
'interface_agreement': 2}`, chvalid `{'semantic_agreement': 4}` — zero movement (stop rule S2 otherwise).

The subdirectory `rebased-df85e95b7/` holds the battery of the head REBASED onto the post-enum mainline (record §14).

The subdirectory `round3-34ac493f9/` holds the battery of closure round 3 (argument-list arity) on the head rebased onto mainline `34ac493f9` (record §15).
