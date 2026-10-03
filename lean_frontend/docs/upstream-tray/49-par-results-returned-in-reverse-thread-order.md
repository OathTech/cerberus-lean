# Core `par(e1, …, en)` returns its results in reverse order: a `List.reverse` was lost when `par` moved into `core_reduction` (2019)

**Affected:** `frontend/model/core_reduction.lem` `Epar` arm (upstream `b9aeedcb4` `:1419`; fork
`:1484-1489`), which builds the parent's continuation as
`mk_unseq_e (List.map mk_wait_e tids)` from the tid list it is given; and
`frontend/model/driver.lem` `advance_step`'s `Step_spawn_threads2` arm (upstream `:1013`; fork
`:1023-1038`), which builds that list by `State.foldlM` with `tid :: th_tids_`, i.e. in **reverse**
spawn order. Neither site reverses it, so the `i`-th component of the tuple `par` returns is the
result of the `(n+1-i)`-th thread.

## Description

Before 2019 every driver built the child tid list the same way (cons) and then reversed it before
building the waits:

```lem
(* e8575cd81 (2016-03-24) model/driver.lem:396-407 *)
| Step_spawn_threads parent_tid parent_th_st th_sts ->
    let ((th_tids, core_st'), run_st') = State.run (
      State.foldM (fun (th_tids_, core_st_) th_st ->
        State.bind (spawn_thread (Just parent_tid) th_st core_st_)
          (fun (tid, core_st_') -> State.return (tid :: th_tids_, core_st_'))
      ) ([], dr_st.core_state) th_sts
    ) dr_st.core_run_state in
    … arena= Core.Eunseq $ List.reverse (List.map (fun z -> Core.Ewait z) th_tids) …
```

The same `List.reverse` is present at `0df8708ad` (2019) `frontend/model/driver.lem:742`.
Commit `650da6dfb` (authored 2019-11-13, committed 2022-06-04, Memarian, "Various stuff: … par()
should work …") replaced the `error "WIP: PAR"` in `core_reduction.lem` with the current `Epar` arm
and its continuation `fun tids -> wrap_expr (Caux.mk_unseq_e (List.map Caux.mk_wait_e tids))`.
The driver's spawn handler still cons-builds `tids`, and no reverse was carried over.

## Reproducer

```core
proc main (): eff loaded integer :=
  let strong (a: loaded integer, b: loaded integer) = par(pure(Specified(1)), pure(Specified(2))) in
  case (a, b) of
    | (Specified(x: integer), Specified(y: integer)) => pure(Specified(x * 10 + y))
  end
```

Run on upstream `b9aeedcb4` (`--runtime=$P --nolibc --exec --batch --mode=exhaustive`,
2026-10-03):

```
Defined {value: "Specified(21)", stdout: "", stderr: "", blocked: "false"}
```

## Observed vs expected

Observed `21`; expected `12` (`a` bound to the first thread's result `1`, `b` to the second's `2`),
which is what the pre-2019 drivers computed.

## Impact

- **C programs cannot observe it.** The C par block (`AilSpar`, `translation.lem` elaboration)
  binds every thread's result to `unit` and discards the tuple
  (`mk_wseq_e (mk_empty_pat (BTy_tuple (replicate … BTy_unit))) (Epar core_ss) mk_skip_e`).
- **Hand-written Core that uses `par` results observes it**, including the historical litmus tests
  under `tests/concurrency/` (2016), which encode outcomes positionally (e.g. `a1 + 2*a2`).

## Proposed remedy

Restore the reverse in one place: either `List.reverse spawn_tids` in the driver's
`Step_spawn_threads2` handler before calling `mk_parent_th_st`, or build the list in spawn order
(`th_tids_ ++ [tid]`). The handler at upstream `driver.lem:567` (the commented-out
`drive_core_thread2`) has the same shape and would need the same change if revived.

## Classification

Regression with a provenance commit (`650da6dfb`). Core-level, not an ISO C question.

## Provenance

Found by the 2026-10-03 concurrency donor archaeology of the cerberus-lean fork
(`lean_frontend/docs/2026-10-03_concurrency-donor-archaeology.md` §2–3, annex A1); the reproducer
was re-run and the cited sites re-read by the fork's orchestrator on 2026-10-03. Fork status: the
fork **mirrors** this behaviour ([USER 2026-09-29] "mirror and refuse seems safest"); its SC slices
label it as this known upstream regression and their fixtures either expect the reversed tuple or
do not bind `par` results. Duplicate search: none done (no network at drafting); repeat before
filing.
