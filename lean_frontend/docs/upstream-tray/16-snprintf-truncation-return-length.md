# `snprintf` returns the truncated length on truncation, not the would-have-been length

**Affected:** `frontend/model/formatted.lem:787-804` (`vsnprintf`;
checked against `master` @ `b9aeedcb4`; our checkout's copy differs
from it only by Lean-backend annotation lines — the `vsnprintf` body is
byte-identical, diff-verified 2026-08-30). Reached from C via
`runtime/libc/src/stdio.c:678-684` (`snprintf` → `vsnprintf` →
`__builtin_vsnprintf`, :715-719), dispatched to `Formatted.vsnprintf`
at `frontend/model/driver.lem:437`.

## Description

C11 §7.21.6.5#3: "The `snprintf` function returns the number of
characters that would have been written had `n` been sufficiently
large, not counting the terminating null character … Thus, the
null-terminated output has been completely written if and only if the
returned value is nonnegative and less than `n`."

`vsnprintf` formats the full output `cs`, truncates it to `n-1`
characters for storage (formatted.lem:799-800 — the stored bytes and
NUL terminator are correct), but then returns the length of the
*truncated* list:

```
let cs' = List.take (natFromInteger (n-1)) cs in
store_chars_in_array true s_ptrval cs' >>= fun () ->
Mem.return (Right (U.return (integerFromNat (List.length cs'))))
```

(formatted.lem:799-801) — `List.length cs'` where ISO requires
`List.length cs`. The `n = 0` path (formatted.lem:792-793) has the
same defect in extreme form: it returns 0 unconditionally without
formatting at all, where ISO requires the would-have-been length with
nothing written.

## Reproducer

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

(verbatim, 2026-08-30, upstream binary + upstream runtime/libc at
`b9aeedcb4` via `CERB_INSTALL_PREFIX`.)

```
$ gcc -std=c11 snprintf_trunc.c && ./a.out; echo $?
15
```

(gcc 13.3.0; verbatim 2026-08-30.) Decomposed: all three buffer-byte
checks pass on BOTH engines (`b` holds `"123\0"` — storage-side
truncation is correct); the divergence is isolated to the return
value, 3 (truncated) vs 6 (would-have-been).

## Observed vs expected

- Observed: `snprintf(b, 4, "%d", 123456)` returns 3.
- Expected: returns 6; §7.21.6.5#3's completeness test
  (`ret < n` ⇔ output complete) then works.

## Impact

The return value is *the* standard truncation-detection and sizing
mechanism, and this defect inverts it: on truncation the returned
value is always `n-1 < n`, so the documented completeness test
concludes the output was completely written exactly when it was not.
The common two-pass idiom `len = snprintf(NULL, 0, ...)` (or any
small-buffer probe) sizes the allocation at 0 / the probe size instead
of the needed length. `vsprintf` is unaffected in practice (it passes
`INT_MAX`, stdio.c:721-724); every bounded formatted write is
affected.

## Proposed remedy

Return the untruncated length, and format before the `n = 0`
short-circuit:

```
| Right (U.Defined cs) ->
    let cs' = List.take (natFromInteger (n-1)) cs in
    store_chars_in_array true s_ptrval cs' >>= fun () ->
    Mem.return (Right (U.return (integerFromNat (List.length cs))))
```

plus restructuring so `n = 0` still runs `printf_aux` and returns
`length cs` while storing nothing (the current early return at
formatted.lem:792-793 must not skip formatting). Encoding-error and
INT_MAX edge cases (§7.21.6.5#3's negative return) are pre-existing
TODOs in the same file and out of scope here.

## Classification

**TRUE BUG.** The truncation of the *stored* bytes is implemented
carefully (take `n-1`, forced NUL), so §7.21.6.5 is clearly intended;
the return value simply reuses the truncated list where the standard
specifies the untruncated count.

## Provenance

Found by the 2026-08-30 parity-detective beyond-testset probe campaign
of our Lean port (`lean_frontend/docs/2026-08-30_parity-detective-report.md`
§4, oracle-wrong suspect 2): both engines return 9 (`AGREE`) — the
Lean port deliberately mirrors the shared `formatted.lem`, so this is
an upstream defect, not a port divergence. Repro re-verified
2026-08-30 against the un-forked `deps/cerberus-upstream` binary and
runtime @ `b9aeedcb4`.
