# PNVI-ae-udi: `combine_prov` crashes on four files of the PNVI litmus suite (`found a Prov_symbolic`)

**Affected:** `memory/concrete/impl_mem.ml` `combine_prov` (upstream `b9aeedcb4` `:366-394`; the
arm `:391-394`, `(* TODO: this is improvised, need to check with P *)` …
`failwith "Concrete.combine_prov: found a Prov_symbolic"`), reached through `AbsByte.pvi_split_bytes`
(`:455-460`) when `abst` reads the bytes of a stored `Prov_symbolic` pointer as integers.

## Reproducer

Upstream's own suite, `tests/pnvi_testsuite/`, with `--switches=PNVI_ae_udi`, libc mode,
`--exec --batch --mode=exhaustive`: `pointer_offset_from_int_subtraction_auto_yx.c`,
`pointer_offset_from_int_subtraction_global_yx.c`, `provenance_basic_using_uintptr_t_auto_yx.c`,
`provenance_basic_using_uintptr_t_global_yx.c`. Each computes an integer address that is one past
`x` and the start of `y` (both exposed), casts it to `int *` (find_overlaping returns
`DoubleAlloc`, so `ptrfromint` mints a `Prov_symbolic`), stores it in `p`, and calls
`memcmp(&p, &q, sizeof(p))` — libc's `memcmp` loads `p`'s bytes as `unsigned char`.

Verbatim (fork oracle at merge-base `b9aeedcb4`, 2026-10-04; identical in the 2026-10-07 lane run
except the file name; rc 125):

```
cerberus: internal error, uncaught exception:
          Failure("Concrete.combine_prov: found a Prov_symbolic")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Impl_mem.Concrete.AbsByte.pvi_split_bytes.(fun) in file "memory/concrete/impl_mem.ml", line 458, characters 11-39
          Called from Stdlib__List.fold_left in file "list.ml", line 125, characters 24-34
```

Without the switch all four end `Undefined {ub: "UB043_indirection_invalid_value", …}` (no
`Prov_symbolic` is minted in the default model).

## Observed vs expected

Observed: the tool crashes on 4 of the 44 files of the suite written for this model. Expected: a
verdict. Reading a symbolic pointer's representation bytes is ordinary C (`memcmp` of two pointer
objects); the TODO says the integer provenance of such a byte was not settled.

## Impact

PNVI-ae-udi cannot run the representation-inspection half of its own test suite; any program that
copies or compares a pointer object byte-wise after an ambiguous integer-to-pointer cast crashes.
`provs_of_bytes` (`:470-471`, `Prov_symbolic iota -> acc (* TODO(iota) *)`) on the same bytes is
never reached, because `pvi_split_bytes` runs first (`:986`/`:999` before `:988`/`:1001`).

## Proposed remedy

Decide the integer provenance of a `Prov_symbolic` byte (for example: resolve the iota if it is
`Single`, else treat the byte as `Prov_none`, matching `mk_ival`'s "integers carry no provenance
under PNVI"), and settle `provs_of_bytes`'s exposure rule for it at the same time.

## Classification

INTENDED GAP (upstream TODO), crash-severity, on upstream's own test suite.

## Provenance

Measured in the cerberus-lean PNVI design pass (`lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md`
§C.2) and re-observed by the fork's PNVI lane (`scripts/test_pnvi.sh`, 2026-10-07, rows
`REFUSAL R-PNVI-01 ORACLE_CRASH`). Fork status: cerberus-lean REFUSES at this arm (refusal
R-PNVI-01, [USER 2026-10-05]: upstream crashes on the PNVI path are refusals, not mirrors).
Duplicate search: none done (no network at drafting); repeat before filing.
