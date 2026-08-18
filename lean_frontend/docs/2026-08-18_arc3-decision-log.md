# Arc 3 decision log (totality sweep)

Autonomous-mode judgement calls, logged for post-arc review. Format:
**D<n>** — decision / why / alternatives considered.

**D1** — Arc runs in `worktrees/{cerberus-lean,lem-lean}-arc/totality-sweep`
on branch `arc/totality-sweep` in both repos; charter committed as the arc's
first commit on the cerberus side. Why: matches arcs 1+2 lane discipline;
primaries stay parked on mainlines. Alternatives: work on primaries (rejected:
playbook requires parked mainlines).

**D2** — S0 census: 97 partial defs in the slice, not the charter's ~41
(hand regexes were indentation/attribute-defeated — §10 failure mode, third
occurrence; the committed gate script is the mechanized count). Core_run and
Mem_aux are already clean; Core_aux holds 35. Charter's allowlist cap (5
target / 10 hard) is kept UNCHANGED despite the doubled census: the cap
guards theorem-surface honesty, not effort. Why: a bigger sweep is more
batches, not a different design. Alternatives: raise cap proportionally
(rejected: cap is about how much of the slice stays opaque to theorems).

**D3** — Gate script committed in reporting mode and left out of
test_unit.sh until the S3 flip to ENFORCE=1; it also fails on STALE
allowlist entries (fail-closed both directions). driver2 census confirms
B1 (fuel×reader) is mandatory — the driver loop is reader-lifted and
inherently non-terminating, so it needs fuel by design.
