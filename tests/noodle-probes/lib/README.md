# lib/ — libc-mode library probes

Findings: record §L3 (stdio termination/flush), §L4 (atexit on return),
§L5 (`%*d` crash), §L6 (`%x` with int argument UB153b), §O3 (strtok
absent), §O4 (strtol exhaustive explosion). Integration target for AGREE
rows: `test_libc_exec.sh` (MATCH), gcc lane where stdout-free.

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| lib_printf_int_formats.c | hh/h/l/ll/z, flags, width, precision, %c/%s (7.21.6.1), correctly typed args | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_printf_hex_int_arg.c | `%x/%X/%o` with an int argument of representable value (7.21.6.1p9, 6.5.2.2p6) | oracle==Lean UB153b; gcc `[ff][FF][10]` — ORACLE-SUSPECT L6 (over-strict; upstream-confirmed) | libc_exec UB_MATCH; gcc-lane SKIP_UB pinned |
| lib_printf_uint_neg_arg.c | `%u` with -1 (strictly UB) | oracle==Lean UB153b; gcc prints — ODDITY control for L6 | libc_exec UB_MATCH |
| lib_printf_star_width.c | `%*d` (7.21.6.1p5) | BOTH CRASH `TODO: formatted.lem 6` (oracle exit 125 / Lean PANIC 134); gcc `[   9]` — ORACLE-SUSPECT L5 (upstream-confirmed) | immaculate crash pair (both fail-stop); tray candidate |
| lib_printf_return_value.c | printf/putchar return counts (7.21.6.3p3) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_stdio_unflushed_lost.c | `fputs("out", stdout); return 0;` — flush at termination (7.22.4.4p4, 5.1.2.2.3) | oracle==Lean stdout ""; gcc "out" — ORACLE-SUSPECT L3 (upstream-confirmed) | libc_exec MATCH (both engines); pinned pair vs gcc |
| lib_stdio_exit_unflushed_lost.c | same via exit(0) | oracle==Lean " 5\n"; gcc "out 5\n" — L3 | libc_exec MATCH; pinned pair |
| lib_stdio_puts_after_putchar.c | putchar then puts, same stream order (7.21.3) | oracle==Lean "\n"; gcc "\nxy\n" — L3 | libc_exec MATCH; pinned pair |
| lib_stdio_fflush_control.c | fputs; fflush; printf ordering | AGREE 3-way "outz" (control) | libc_exec MATCH, gate-worthy |
| lib_atexit_order.c | atexit handlers on RETURN from main (7.22.4.4p3, 5.1.2.2.3) | oracle==Lean "m"; gcc "m21" — ORACLE-SUSPECT L4 (upstream-confirmed) | libc_exec MATCH; pinned pair vs gcc |
| lib_atexit_exit_control.c | atexit handler on exit() | AGREE 3-way "m1" (control) | libc_exec MATCH, gate-worthy |
| lib_exit_in_callee.c | exit() from nested call flushes proxy stdout | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_exit_code_range.c | exit(300): model Specified(300), OS 44 | oracle==Lean Specified(300); gcc 44 (expected) | libc_exec MATCH; gcc-lane SKIP_VALUE_RANGE-shaped |
| lib_abort_stdout.c | abort after unflushed proxy stdout | oracle==Lean `Specified(127)` stdout "abc" stderr "SIGABRT\n" | libc_exec MATCH (verdict shape) |
| lib_stderr_output.c | fprintf(stderr), fputs/fputc + fflush, returns (7.21.7) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_snprintf_basic.c | snprintf with room (7.21.6.5) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_strtol_edges.c | strtol/strtoul/atoi edges (7.22.1.4) | BOTH exhaustive TIMEOUT (libc-internal nondeterminism); `--first`: oracle `-42 120 26 8 0 1 1 1 1 7 35` == gcc, Lean value agrees — O4 | reporting-only (--first lane) |
| lib_qsort_bsearch.c | qsort/bsearch (7.22.5) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_string_funcs.c | strcat/strncat/strstr/strrchr/memchr/strspn/strcspn (7.24) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_memcmp_strcmp_sign.c | unsigned-char comparison semantics (7.24.4) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_ctype.c | ctype classification/mapping (7.4) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_abs_div.c | abs/labs/llabs/div/ldiv (7.22.6) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| lib_rand_determinism.c | srand/rand reproducibility (7.22.2) | oracle==Lean `838 382 386 1`; gcc differs by design | libc_exec MATCH; gcc SKIP_GCC_STDOUT |
| lib_inline_noreturn_restrict.c | static inline, _Noreturn + exit, restrict (6.7.4, 6.7.3.1) | AGREE 3-way "bye"/3 | libc_exec MATCH, gate-worthy |
