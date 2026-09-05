# `--concurrency` is accepted by the driver and dies with `internal error: CONCURRENCY IS BROKEN`; a working restoration exists (the fork's parametric SC instance)

**Classification:** INTENDED GAP (a literal `error`), but user-facing: the
flag is documented ("Activate the C11 concurrency", main.ml:460) and
accepted, and both engines otherwise SERIALIZE `par` programs silently —
one Defined outcome, no race verdict, no refusal — which is fail-open.

**Affected (upstream `master` @ b9aeedcb4):** `backend/driver/main.ml`
:459-461 (the cmdliner flag; a comment there asks whether the flag is
used), :124 (`set_cerb_conf … ~concurrency`), :275 (`driver_conf`);
`frontend/model/driver.lem` :1862-1864:

```
        driver2 with_concurrency >>
        if with_concurrency then
          error "CONCURRENCY IS BROKEN"
```

and `can_advance` (:907-935 in our numbering at the fork's merge base),
which treats memory actions as non-scheduling points, so without the flag
a `{-{ … ||| … }-}` program runs each thread to completion in order.

## Reproducers (upstream binary, `--nolibc --exec --batch --mode=exhaustive`)

| program | expected (C11 / SC) | upstream, no flag | upstream, `--concurrency` |
|---|---|---|---|
| SB with `seq_cst` stores/loads, returns `r1 + 2*r2` | {1, 2, 3} | `Defined {value: "Specified(1)", …}` only | `internal error: CONCURRENCY IS BROKEN` |
| MP, both accesses NON-atomic, returns `r` | data race (UB) | `Defined {value: "Specified(0)", …}`, no UB | same internal error |

## Proposed remedy (two tiers)

1. Minimal: refuse `par`/thread creation when concurrency is off with a
   typed error, and refuse the flag with a clear message while the C11
   path is broken — never serialize silently.
2. Restoration: make the concurrency model an explicit parameter of the
   driver and provide the SC-DRF instance — interleavings enumerated
   (memory actions become scheduling points once two threads exist), the
   axiomatic model's candidate execution recorded alongside, `data_races`
   → UB005, SC consistency checked at trace end, everything outside the
   SC fragment (non-`seq_cst` orders, fences) refused by name. Our fork
   implements exactly this (`--concurrency=sc`, cerberus-lean
   `feature/concurrency`, 2026-09-04/05; 24-program litmus corpus at the
   upstream `tests.ml` expectation sets; design in
   `lean_frontend/docs/2026-09-04_concurrency-phase0-sc-charter.md`); the
   patch is `.lem`-side and generates into the OCaml driver unchanged in
   spirit. We would be glad to upstream it if there is interest.

## Also in the fork's shared `.lem`: `atomic_compare_exchange_*` execute

Upstream @ b9aeedcb4 elaborates `atomic_compare_exchange_{strong,weak}_explicit`
to Core `CompareExchangeStrong/Weak` actions and then dies in the reduction
with `internal error: TODO[Core_reduction]: CompareExchangeStrong` (both
with and without `--concurrency`; `core_reduction.lem`, the two `error
"TODO…"` arms). The fork gives the two actions reduction rules (C11
7.17.7.4: load expected and object, compare with the memory model's integer
equality, store desired or write back; the weak form's spurious failure as a
nondeterministic branch), integer objects only; the four `RMW-*` rows of the
fork's litmus corpus pin `{5}`, `{0}`, `{0,5}`, `{0}` on both engines and
both models (the recovered upstream `RMW-*.core` header expectations). This
is a sequential-visible behaviour change of the oracle (from an internal
error to a verdict), offered alongside the SC instance.

Provenance: measured 2026-09-04 (charter §2, verbatim outputs); the
scheduler finding is draft 37; the compare_exchange rules 2026-09-05 (S4). [AGENT]-drafted; filing is the operator's
call.
