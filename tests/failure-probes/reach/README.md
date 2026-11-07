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
    CERB_MEM_MAX=4G scripts/capped timeout 60s env LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --runtime=$RT --batch --first [--args A] [--libc tests/libc/libc.core --libc-tu <12 jsons from scripts/libc_prep.sh --jsons>] x.json

(`scripts/test_exec.sh <file>` alone reports these as CERB_SKIP — the oracle crashes first and the Lean side
is never sampled — so the two-engine recipe above is the one that shows both lines.)

Verbatim outputs on mainline 4d1088004 (ANSI codes stripped from the oracle stderr; first exception line):

## printf_star_prec.c  [nolibc]  — RETIRED AS A FAILURE WITNESS 2026-11-07 (fix/printf-refusals, upstream-tray report 26)
Both engines print the value since the `*` precision is read from the argument (C17 7.21.6.1#5); kept as a
value witness of the fix. Verbatim on the fix/printf-refusals M1 tree:
oracle exit=0: Defined {value: "Specified(0)", stdout: "007\n", stderr: "", blocked: "false"}
lean   exit=0: Defined {value: "Specified(0)", stdout: "007\n", stderr: "", blocked: "false"}
(before: oracle exit=125 `internal error: TODO: Formatted.convert, * prec`, lean exit=134 the same PANIC text)

## printf_star_prec_f.c  [nolibc]  — RETIRED AS A FAILURE WITNESS 2026-11-07 (the same fix)
oracle exit=0: Defined {value: "Specified(0)", stdout: "1.50\n", stderr: "", blocked: "false"}
lean   exit=0: Defined {value: "Specified(0)", stdout: "1.50\n", stderr: "", blocked: "false"}

## printf_star_prec_s.c  [nolibc]  — RETIRED AS A FAILURE WITNESS 2026-11-07 (the same fix)
oracle exit=0: Defined {value: "Specified(0)", stdout: "ab\n", stderr: "", blocked: "false"}
lean   exit=0: Defined {value: "Specified(0)", stdout: "ab\n", stderr: "", blocked: "false"}

## printf_star_width.c  [nolibc]  — RETIRED AS A FAILURE WITNESS 2026-11-07 (the same fix)
oracle exit=0: Defined {value: "Specified(0)", stdout: "    7\n", stderr: "", blocked: "false"}
lean   exit=0: Defined {value: "Specified(0)", stdout: "    7\n", stderr: "", blocked: "false"}
(before: oracle exit=125 `internal error: TODO: formatted.lem 6`, lean exit=134 the same PANIC text)

## printf_lc.c  [nolibc]  — a DECLARED REFUSAL since 2026-11-07 (contract D16; the row-1 witness is scripts/check_printf_refusals.sh)
oracle exit=125: internal error: Formatted.convert: refused - the %lc conversion (C17 7.21.6.1#8 c with l: the wint_t argument is converted through an ls conversion of a two-element wchar_t array); upstream's arm is the uncaught internal error 'NOT YET SUPPORTED: %lc' (formatted.lem c3ff8c53f :612), a crash on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Formatted.convert: refused - the %lc conversion (C17 7.21.6.1#8 c with l: the wint_t argument is converted through an ls conversion of a two-element wchar_t array); upstream's arm is the uncaught internal error 'NOT YET SUPPORTED: %lc' (formatted.lem c3ff8c53f :612), a crash on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
(before: `NOT YET SUPPORTED: %lc` on both)

## printf_n.c  [nolibc]  — a DECLARED REFUSAL since 2026-11-07 (contract D16; the row-1 witness is scripts/check_printf_refusals.sh)
oracle exit=125: internal error: Formatted.convert: refused - the %n conversion (C17 7.21.6.1#8 n: the number of characters written so far is stored into the signed int the argument points to; no argument is converted); upstream's arm is the uncaught internal error 'WIP: Formatted.convert, CS_n' (formatted.lem c3ff8c53f :697), a crash on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
lean   exit=134: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Formatted.convert: refused - the %n conversion (C17 7.21.6.1#8 n: the number of characters written so far is stored into the signed int the argument points to; no argument is converted); upstream's arm is the uncaught internal error 'WIP: Formatted.convert, CS_n' (formatted.lem c3ff8c53f :697), a crash on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
(before: `WIP: Formatted.convert, CS_n` on both)

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
- printf_star_prec.c, printf_star_prec_f.c, printf_star_prec_s.c, printf_star_width.c -> the four `* prec` / `formatted.lem 6`
  sites are GONE since 2026-11-07 (fix/printf-refusals: a `*` width or precision is read from the argument in
  `printf_aux`, formatted.lem `load_star_argument`); their register rows were retired and both engines print the
  values above. The one site the fix added to the register, `Formatted.convert` `is_alias_base`'s alias-table
  invariant (`"Formatted.convert: the implementation's alias table maps …"`, PURE, NON-TAIL/LAMBDA-BODY), is
  UNREACHABLE-BY-INVARIANT (the j/z/t arms pass literal macro-type constructors the alias table maps to a
  Signed/Unsigned base type) and has no witness program.
- printf_lc.c            -> generated/Formatted.lean convert, `failwithI (wide_refusal CS_c) : ndM …` — MONADIC (no register row). A DECLARED REFUSAL (contract D16).
- printf_n.c             -> generated/Formatted.lean convert, `failwithI n_refusal : ndM …` — MONADIC (no register row). A DECLARED REFUSAL (contract D16).
- funptr_reload.c        -> lean_frontend/CerbMem.lean:1045 reconstructValue, `panic! "unknown function pointer"` (impl_mem.ml failwith) — PURE, TAIL. Input class: IMPLEMENTATION-DEFINED (C11 6.3.2.3p5 int→function-pointer conversion; the value is only copied, never called — no UB). A model fail-stop on a load of a forged function-pointer value.
- atomic_fence.c         -> generated/Core_reduction.lean:434 step_action, `failwithI "TODO[Core_reduction]: Fence"` — PURE, TAIL. Well-typed UB-free C11 (`atomic_thread_fence`, libc mode); class (c) concurrency-feature refusal.
- args_backslash.c       -> lean_frontend/CerbDecode.lean:121 decode_character_constant_aux via Driver.prepare_main_args (driver.lem: `Decode.decode_character_constant (String.toString [c])` per argv byte) — PURE, TAIL. Input class: HARNESS BOUNDARY (the `--args` string contains a backslash); the C program itself is well-typed and UB-free.
