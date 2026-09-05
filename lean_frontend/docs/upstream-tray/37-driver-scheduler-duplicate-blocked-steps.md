# The exhaustive driver branches over k IDENTICAL `Step_blocked2` entries of a parent waiting on k children — k^rounds redundant traces, no new outcomes

**Classification:** TRUE BUG (performance / trace multiplicity; verdict
SETS are unaffected). Reachable only with a concurrency-enabled driver
(upstream's `--concurrency` path is `error "CONCURRENCY IS BROKEN"`,
driver.lem:1864 — see draft 38 — so upstream cannot observe it today;
it becomes load-bearing the moment threads run).

**Affected (upstream `master` @ b9aeedcb4, `frontend/model/driver.lem`):**
the per-thread step enumeration hands the parent thread's steps to
`ND.pick (SK_misc ["driver 2"]) tid_steps` :1388-1389 / the exhaustive
arm :1402-1410. A thread whose top expression is an `Ewait`/`par` join on
k unfinished children yields k structurally identical
`Core_reduction.Step_blocked2` entries (one per child context), and
`ND.pick` branches over all of them every scheduling round; the branches
are indistinguishable and reconverge, so the trace count is multiplied
by k at every round the parent is blocked.

## Evidence (our fork, where the SC scheduler runs; `-d5`, verbatim)

```
picking step for thread(0) size: 2 ==> [Step_blocked2; Step_blocked2]
```

Store-buffering (2 threads): 496 traces for 3 outcomes; WRC (3 threads):
218,484 traces in 23.4 s; IRIW (4 threads): unfinished at 300 s and 15 GB
RSS. After collapsing identical blocked steps to one per thread: SB 20,
WRC 336 (0.07 s), IRIW 6300 (1.05 s) — exactly the interleaving counts
(10!/(4!4!) for IRIW), outcome sets unchanged.

## Proposed remedy

In the thread-step enumeration, keep at most one `Step_blocked2` per
thread (they carry no distinguishing payload): e.g. after computing a
thread's step list, `if List.all (= Step_blocked2) steps then
[Step_blocked2] else steps`. Our fork does this in
`new_drive_core_threads` (pattern-based, no equality on closures).

Provenance: measured 2026-09-04 (cerberus-lean concurrency Phase 0,
record `lean_frontend/docs/2026-09-04_concurrency-S1-S2-record.md` §2.2).
[AGENT]-drafted; filing is the operator's call.
