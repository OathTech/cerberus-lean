# Contract D4: the builtin boundary, and two silent fallbacks made loud — record

Date: 2026-09-28. Branch: `arc/contract-enforcement`. Author: the orchestrator [AGENT].
Decision: [USER 2026-09-28] "Yeah, (1) is fine" (D4 option 1: libc supported by mechanism, the 36 `std.core`
builtins a named list with one state each). Findings from `docs/2026-09-28_served-surface-audit.md` P3-1 and P3.

## The builtin table

`CONTRACT.md` §3.1 lists all 36 `builtin` declarations of `runtime/libcore/std.core` (lines 253-813). States were
read from the live dispatch, not from the corpora:

- `Core_reduction.process_impl_proc` (`core_reduction.lem`) handles `errno`, `exit`, `generic_ffs`, `ctz`,
  `bswap16/32/64` and fails `any_bounded_int` with a TODO; its fallback arm fails every other builtin in both engines,
  so an unlisted builtin fails closed.
- `core_reduction_aux.lem` routes `printf`, `vprintf`, `vsnprintf` and the 25 filesystem builtins to driver actions;
  `driver.lem:355-450` serves `write`/`vprintf` on fds 1/2, fails fd 0 in both engines, and sends every other fd and
  every other filesystem action to CerbFS, which refuses (D2). `read` therefore refuses on every fd.

## `any_bounded_int`

The audit found the live stepper fails it in both engines (oracle "internal error: TODO Core_reduction ==>
any_bounded_int()", Lean PANIC with the same text). The seam `CerbUtils.bounded_integer`, which returned `lo`, sits
only on the dead `Core_run.core_thread_step2` path. Changes:

- `bounded_integer` is now a plain def that fails loudly (it can no longer become a silent answer if the stepper
  changes). It leaves the boundary-opaque census (`check_theorem_axioms.sh`, 10 -> 9) and the unsafeBaseIO allowlist
  (1 KEEP row and 3 PIN rows retired); VALIDATION's boundary list updated.
- The register row for the TODO failure moves UNREACHABLE-BY-INVARIANT -> REACHABLE, with witness
  `tests/immaculate/nolibc/zd-any-bounded-int-crash.c` pinned `MATCH | L=CRASH`.

## `CerbMem.reconstructValue`'s wildcard

Both forms ended `| _ => .MVunspecified ty`, covering void, arrays of unknown size, and function types, where the
OCaml asserts false (`impl_mem.ml:978-983`). Now `failwithI` with the cite. One new exec-closure register row
(UNREACHABLE-BY-INVARIANT: a loaded object's type is complete, ISO C11 6.3.2.1p2-4); the indexed form is outside the
exec closure. Register 228 -> 229 rows, resealed.
