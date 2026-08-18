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

**D4** — LEMLIB env var must point at the arc lem's library/ when running
a checkout lem against cerberus (the opam lem bakes its share path; a
checkout lem searches CWD). Recorded for the worker recipe.

**D5** — Two lem extensions beyond the charter's B1/B2, both probe-first:
(a) witness-based opaque panic sentinels (LemLib.fuelExhausted[With]) —
polymorphic/pure return types get honest-LOUD fuel exhaustion with zero
[Inhabited] propagation and clean cones; (b) acyclic de-mutualization of
rec-and blocks — cerberus's subst/convert families are DAGs, and keeping
them mutual both blocked per-member termination declares and would have
forced fuel onto non-recursive defs. Alternatives rejected: fueling whole
DAG families (dishonest bloat), eta-expansion tweaks (probe showed the real
blocker is pair-list nesting, which eta does not fix).

**D6** — Pair-list (Ecase-style) recursion is beyond Lean 4.29 automatic
derivation (probe: attach fires but the decreasing goal cannot chain
through the pair match). Such defs get FUEL, not parking. Witness rule,
uniform across the sweep: any well-typed constructible value (input arg
when types match) — honesty lives in the opaque panic, NOT in the witness,
so no per-monad error-channel spelunking; soft sentinels (e.g. Sum.inr of
the input) only where string-free and semantically clean.

**D7** — Batch cadence: per-batch gates = OCaml prelude+dune build, full
lake build, test_unit (purity+axioms), test_parse, test_core at 104/105
baseline. Batch A (Core_run_aux) green on all.
