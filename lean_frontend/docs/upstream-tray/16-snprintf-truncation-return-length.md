# `snprintf` returns the truncated length on truncation, not the would-have-been length; with `n = 0` it returns 0 without formatting; a format whose conversion reports UB dies with `TODO: snprintf()`

**Affected:** `frontend/model/formatted.lem` @ `c3ff8c53f` `:788-812` (`vsnprintf`): `:794` (`if n = 0 then
Mem.return (Right (U.return 0))` — no formatting), `:803` (`Mem.return (Right (U.return (integerFromNat
(List.length cs'))))` — the TRUNCATED list's length), `:805` (`| _ -> error "TODO: snprintf()"` — the
`U.Undef`/`U.Error`/`Left` results of `printf_aux` are an uncaught internal error). Reached from C via
`runtime/libc/src/stdio.c` (`snprintf` → `vsnprintf` → `__builtin_vsnprintf`), dispatched to
`Formatted.vsnprintf` at `frontend/model/driver.lem` (`FS_VSNPRINTF`). The shared model: the OCaml backend and
our Lean port fail identically.

## Description

C17 7.21.6.5#2-#3: "The snprintf function is equivalent to fprintf, except that the output is written into an
array … If n is zero, nothing is written, and s may be a null pointer. Otherwise, output characters beyond
the n-1st are discarded rather than being written to the array, and a null character is written at the end
of the characters actually written into the array. … The snprintf function returns the number of characters
that would have been written had n been sufficiently large, not counting the terminating null character, or
a negative value if an encoding error occurred. Thus, the null-terminated output has been completely written
if and only if the returned value is nonnegative and less than n."

`vsnprintf` formats the full output `cs`, truncates it to `n-1` characters for storage (the stored bytes
and the NUL terminator are correct), but returns the length of the *truncated* list:

```
let cs' = List.take (natFromInteger (n-1)) cs in
store_chars_in_array true s_ptrval cs' >>= fun () ->
Mem.return (Right (U.return (integerFromNat (List.length cs'))))
```

— `List.length cs'` where ISO requires `List.length cs`. The `n = 0` path returns 0 unconditionally without
formatting at all (ISO: the would-have-been length, nothing written). And where `printf` passes a
conversion's UB verdict (`UB153a`, `UB153b`, …) to the driver as a verdict, `vsnprintf`'s catch-all arm
turns it into an uncaught internal error.

## Reproducers

`tests/parity-probes/probes/snprintf_trunc.c` in our tree:

```c
#include <stdio.h>
int main(void) {
  char b[4];
  int n = snprintf(b, sizeof b, "%d", 123456);
  return n*2 + (b[3] == 0) + (b[0]=='1') + (b[2]=='3');  /* 12+1+1+1 = 15 */
}
```

```
$ cerberus --exec --batch snprintf_trunc.c
Defined {value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc.)

```
$ gcc -std=c11 snprintf_trunc.c && ./a.out; echo $?
15
```

(gcc 13.3.0; verbatim 2026-11-07.) Decomposed: all three buffer-byte checks pass on BOTH engines (`b` holds
`"123\0"` — storage-side truncation is correct); the divergence is isolated to the return value, 3
(truncated) vs 6 (would-have-been). Further, measured 2026-11-07 (same binary): `snprintf((char *)0, 0,
"%d%d", 12, 34)` returns 0 (gcc 4); `snprintf(b, 0, "%s", "zzz")` returns 0 (gcc 3); `snprintf(b, 1, "%d",
99)` returns 0 (gcc 2, `b[0] == 0` on both); `snprintf(b, 8, "%d")` dies with `internal error: TODO:
snprintf()` (exit 125) where `printf("%d")` is reported as `UB153a_insufficient_arguments_for_format`.

## Observed vs expected

- Observed: `snprintf(b, 4, "%d", 123456)` returns 3; `snprintf(NULL, 0, …)` returns 0; a format UB crashes.
- Expected: returns 6 / 4; §7.21.6.5#3's completeness test (`ret < n` ⇔ output complete) then works; the UB
  verdict is `printf`'s.

## Impact

The return value is *the* standard truncation-detection and sizing mechanism, and this defect inverts it: on
truncation the returned value is always `n-1 < n`, so the documented completeness test concludes the output
was completely written exactly when it was not. The common two-pass idiom `len = snprintf(NULL, 0, ...)` (or
any small-buffer probe) sizes the allocation at 0 / the probe size instead of the needed length. `vsprintf`
is unaffected in practice (it passes `INT_MAX`, stdio.c); every bounded formatted write is affected.

## Proposed remedy

Format whatever `n` is, store at most `n-1` characters and the null only when `n > 0`, return the untruncated
length, and pass `printf_aux`'s `U.Undef`/`U.Error`/`Left` results through as `printf` does:

```
match parse format frmt with
  | [(fs, [])] ->
      Mem.va_list ap_idx >>= fun args ->
      printf_aux loc eval_conv [] fs args >>= function
        | Right (U.Defined cs) ->
            begin if n = 0 then Mem.return ()
            else store_chars_in_array true s_ptrval (List.take (natFromInteger (n-1)) cs) end >>= fun () ->
            Mem.return (Right (U.return (integerFromNat (List.length cs))))
        | Right (U.Error loc str) -> Mem.return (Right (U.Error loc str))
        | Right (U.Undef loc ubs) -> Mem.return (Right (U.Undef loc ubs))
        | Left err -> Mem.return (Left err)
      end
  | _ -> …Invalid_format…
```

Encoding-error and INT_MAX edge cases (§7.21.6.5#3's negative return) are pre-existing TODOs in the same
file and out of scope here.

## Fork status (2026-11-07, branch `fix/printf-refusals`, contract D16)

FIXED in our fork's shared `formatted.lem` exactly as proposed, both engines by generation; witness
`scripts/check_printf_refusals.sh` (the `sn_trunc`, `sn_zero_null`, `sn_zero_buf`, `sn_one`, `sn_exact_fit`,
`sn_one_short`, `sn_big`, `sn_empty_fmt`, `sn_sizing_idiom`, `sn_star`, `sn_trunc_star`, `vsn_user_wrapper` rows
pinned to gcc 13's lines; `sn_ub_insufficient`, `sn_ub_illtyped`, `sn_zero_ub` pinned to `printf`'s UB
verdicts). Three `tests/libc_exec` rows (026, 027, 028) now print gcc's values on both engines and are
`shared-model-fix` rows of the pristine-lane register. The fork-ahead delta leaves when upstream absorbs the fix.

## Classification

**TRUE BUG.** The truncation of the *stored* bytes is implemented carefully (take `n-1`, forced NUL), so
§7.21.6.5 is clearly intended; the return value simply reuses the truncated list where the standard
specifies the untruncated count.

## Provenance

Found by the 2026-08-30 parity-detective beyond-testset probe campaign of our Lean port
(`lean_frontend/docs/2026-08-30_parity-detective-report.md` §4, oracle-wrong suspect 2): both engines return
9 (`AGREE`) — the Lean port deliberately mirrors the shared `formatted.lem`, so this is an upstream defect,
not a port divergence. Repro re-verified 2026-08-30 @ `b9aeedcb4` and 2026-11-07 @ `c3ff8c53f` against the
un-forked `deps/cerberus-upstream` binary and runtime; the `n = 0` and crash siblings from the true-bug audit
of 2026-11-04 (row 16) and the fix/printf-refusals vicinity probe. Localisation and this draft by Claude
(Fable 5.1) under operator direction; the filed issue carries an AI-provenance note per the tray's policy.
