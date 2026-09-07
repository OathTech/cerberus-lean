# tests/failure-probes/reach — reachability WITNESSES for the pure-failure census (2026-09-07)

Record: lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md (Q2/Q3).
NOT wired into any lane. Each file is a small C program that drives BOTH engines into a deliberate
model failure on the DEFAULT configuration: the oracle raises (exit 125, uncaught exception), the Lean
driver panics (exit 134 under LEAN_ABORT_ON_PANIC=1, which the driver requires). Both-crash means the
failure CLASS matches; it is not semantic agreement. Every program below is well-typed C; the input class
(UB / implementation-defined / feature refusal / harness boundary) is stated per file.

Recipe (the immaculate lane's run_c_case, scripts/test_immaculate.sh:145-176), from the repo root with
scripts/env.sh sourced and the driver binaries freshness-checked (tools/check_driver_fresh.sh --check):

    O=_build/default/backend/driver/main.exe; RT=_build/install/default
    CERB_MEM_MAX=4G scripts/capped timeout 60s opam exec --switch=. -- $O --runtime=$RT --exec --batch [--nolibc] [--args A] <file.c>
    CERB_MEM_MAX=4G scripts/capped timeout 60s opam exec --switch=. -- $O --runtime=$RT --cabs-json <file.c> > x.json
    CERB_MEM_MAX=4G scripts/capped timeout 60s env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --batch --first [--args A] [--libc tests/libc/libc.core --libc-tu <12 jsons from scripts/libc_prep.sh --jsons>] x.json

(`scripts/test_exec.sh <file>` alone reports these as CERB_SKIP — the oracle crashes first and the Lean side
is never sampled — so the two-engine recipe above is the one that shows both lines.)

Verbatim outputs on mainline 4d1088004 (ANSI codes stripped from the oracle stderr; first exception line):

## printf_star_prec.c  [nolibc]
oracle exit=125: internal error: TODO: Formatted.convert, * prec
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO: Formatted.convert, * prec

## printf_star_prec_f.c  [nolibc]
oracle exit=125: internal error: TODO: Formatted.convert, * prec
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO: Formatted.convert, * prec

## printf_star_prec_s.c  [nolibc]
oracle exit=125: internal error: TODO: Formatted.convert, * prec
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO: Formatted.convert, * prec

## printf_star_width.c  [nolibc]
oracle exit=125: internal error: TODO: formatted.lem 6
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO: formatted.lem 6

## printf_lc.c  [nolibc]
oracle exit=125: internal error: NOT YET SUPPORTED: %lc
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: NOT YET SUPPORTED: %lc

## printf_n.c  [nolibc]
oracle exit=125: internal error: WIP: Formatted.convert, CS_n
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: WIP: Formatted.convert, CS_n

## funptr_reload.c  [nolibc]
oracle exit=125: Failure("unknown function pointer: 2748")
lean   exit=134: PANIC at CerbMem.reconstructValue_lemFuel CerbMem:1045:18: unknown function pointer: 2748

## atomic_fence.c  [libc]
oracle exit=125: internal error: TODO[Core_reduction]: Fence
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO[Core_reduction]: Fence

## args_backslash.c  [nolibc] (with --args 'a' on both engines)
oracle exit=125: Failure("decode_character_constant, invalid constant: '\'")
lean   exit=134: PANIC at _private.CerbDecode.0.CerbDecode.decode_character_constant_aux CerbDecode:121:11: decode_character_constant: invalid char constant ==> \ (decode.ml:199-200)

Site classes (census record Q1/Q3; 'pure' = one of the 231 pure exec-closure sites, 'monadic' = one of the 67):
- printf_star_prec.c     -> generated/Formatted.lean:490 convert, `let prec := match prec_opt with … | some P_asterisk => failwithI "TODO: Formatted.convert, * prec"` — PURE, NON-TAIL/LET-BOUND (the F1 shape) and USED (both engines crash). Well-typed UB-free C; class (c) feature refusal (`%.*d`).
- printf_star_prec_f.c   -> the SAME :490 site fires for `%.*f` (the arm-local :494 `* prec` copy is dominated — evaluation order).
- printf_star_prec_s.c   -> the SAME :490 site fires for `%.*s` (the arm-local :494 `TODO(2)` copy is dominated).
- printf_star_width.c    -> generated/Formatted.lean:499 printf_aux, `failwithI "TODO: formatted.lem 6"` — PURE, LET-BOUND, USED. Class (c) (`%*d`).
- printf_lc.c            -> generated/Formatted.lean:494 convert, `failwithI "NOT YET SUPPORTED: %lc" : ndM …` — MONADIC. Class (c).
- printf_n.c             -> generated/Formatted.lean:494 convert, `failwithI "WIP: Formatted.convert, CS_n" : ndM …` — MONADIC. Class (c).
- funptr_reload.c        -> lean_frontend/CerbMem.lean:1045 reconstructValue, `panic! "unknown function pointer"` (impl_mem.ml failwith) — PURE, TAIL. Input class: IMPLEMENTATION-DEFINED (C11 6.3.2.3p5 int→function-pointer conversion; the value is only copied, never called — no UB). A model fail-stop on a load of a forged function-pointer value.
- atomic_fence.c         -> generated/Core_reduction.lean:434 step_action, `failwithI "TODO[Core_reduction]: Fence"` — PURE, TAIL. Well-typed UB-free C11 (`atomic_thread_fence`, libc mode); class (c) concurrency-feature refusal.
- args_backslash.c       -> lean_frontend/CerbDecode.lean:121 decode_character_constant_aux via Driver.prepare_main_args (driver.lem: `Decode.decode_character_constant (String.toString [c])` per argv byte) — PURE, TAIL. Input class: HARNESS BOUNDARY (the `--args` string contains a backslash); the C program itself is well-typed and UB-free.
