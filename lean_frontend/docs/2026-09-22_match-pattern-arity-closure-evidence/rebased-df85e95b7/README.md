# Evidence — the frozen full battery on the REBASED head (onto mainline `df85e95b7`, 2026-09-22)

`fix/match-pattern-arity` rebased onto the post-enum mainline (record `../../2026-09-20_match-pattern-arity-record.md`
§14). `report.json` and `summary.txt` are the runner's files from `.tmp/mpa/rebased-full/` (`release.py --mode full`),
copied byte-for-byte after the run; `report.json`'s `source_unchanged` must be `true`. Expected on this base: 39/39,
pristine tier-B `{'semantic_agreement': 835, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}`
(E-A's 13 witnesses now on the mainline), chvalid `{'semantic_agreement': 4}`. The parent directory holds the round-1
battery of the pre-rebase head `7884df572`.
