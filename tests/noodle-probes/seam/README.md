# seam/ — CerbMem-vs-impl_mem.ml divergences, probe-confirmed

Found by a line-by-line read of `lean_frontend/CerbMem.lean` against
`memory/concrete/impl_mem.ml` (record §4), then confirmed by running each
reproducer through the fork oracle, the Lean driver AND the un-forked
upstream oracle @ b9aeedcb4 (upstream == fork oracle on all five: these
are Lean-side). `results.log` holds the verbatim pair. All five are the
headline DISCREPANCY class; each is the immaculate-style pinned pair that
flips to MATCH when CerbMem is fixed.

| Probe | Mode | oracle | Lean | Record |
|---|---|---|---|---|
| seam_copy_alloc_id.c | libc | `Specified(2)` | `Specified(1)` | D4 (value-level) |
| seam_device_range_load.c | nolibc | `Specified(3)` | `UB043_indirection_invalid_value` | D5 |
| seam_free_no_provenance.c | libc | `Error {msg: "MerrOther \"attempted to kill with a pointer lacking a provenance\""}` | `UB179a_non_matching_allocation_free` | D6 |
| seam_free_device_pointer.c | libc | `Specified(3)` | `UB179a_non_matching_allocation_free` | D6 |
| seam_free_interior_pointer.c | libc | `UB179a_non_matching_allocation_free` | `Error {msg: "MerrUndefinedFree Free_out_of_bound"}` | D7 |

Integration: `tests/immaculate/` DIFF rows (Lean pin = the Lean column),
or the exec lanes as recorded DIFF/CERB_ERROR-vs-UB rows. gcc has no
say (the programs are UB or Cerberus-specific).
