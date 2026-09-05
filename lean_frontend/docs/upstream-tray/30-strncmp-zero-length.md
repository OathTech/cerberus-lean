# libc `strncmp(s1, s2, 0)` compares one character instead of none

**Affected:** `runtime/libc/src/string.c:85-90` (`strncmp`). Checked
against `master` @ `b9aeedcb4`: byte-identical.

## Description

```c
int strncmp(const char *s1, const char *s2, size_t n)
{
  while ((*s1 && *s1 == *s2) && --n > 0)
    s1++, s2++;
  return (*s1 - *s2);
}
```

(string.c:85-90, verbatim.) The length test `--n > 0` is evaluated AFTER
the first character comparison and the function unconditionally returns
`*s1 - *s2`, so with `n == 0` the first characters are compared and their
difference returned (`--n` also wraps `size_t` 0 to `SIZE_MAX`, which is
harmless here only because the loop body is skipped). C11 §7.24.4.4#2-3:
"compares not more than `n` characters"; for `n == 0` no characters are
compared and the result is 0.

## Reproducer

`tests/noodle-probes/mem/mem_strncmp_zero.c`:

```c
#include <string.h>
int main(void) {
  return strncmp("abc", "xyz", 0) == 0 ? 1 : 2;
}
```

```
$ cerberus --exec --batch --mode=exhaustive mem_strncmp_zero.c
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`,
shipped libc; the fork's oracle at `928aa1e76` and our Lean port print
the identical line.)

```
$ gcc -std=c11 -O0 mem_strncmp_zero.c && ./a.out; echo $?
1
```

(gcc 13.3.0; verbatim 2026-09-05.) The wider probe
`mem/mem_strlen_strcmp_edges.c` prints `-23` in its `strncmp(…, 0)`
column where gcc prints `0`; its other `string.h` columns agree.

## Observed vs expected

- Observed: `strncmp("abc", "xyz", 0)` = `'a' - 'x'` = -23 (nonzero →
  the probe returns 2).
- Expected: 0 (→ 1).

## Impact

`strncmp(a, b, len)` with a computed `len` that can be 0 (prefix matching,
tokenisers, `strncmp(p, q, end - p)`) takes the wrong branch. Silent
wrong value in the shipped libc, affecting every libc-mode run.

## Proposed remedy

musl's shape (this libc derives from musl, which has the check):

```c
int strncmp(const char *l, const char *r, size_t n)
{
  if (!n--) return 0;
  for (; *l && *r && n && *l == *r; l++, r++, n--);
  return *l - *r;
}
```

or minimally `if (n == 0) return 0;` before the loop.

## Classification

**TRUE BUG.** The standard is explicit; the shipped code's only
deviation from its musl ancestor is the missing zero-length check.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L1); both engines agree (shared libc), gcc differs. Re-verified
2026-09-05 on the un-forked upstream binary + runtime @ `b9aeedcb4`, the
fork's oracle and the Lean port (lines above verbatim). Localisation and
this draft by Claude (Fable 5.1) under operator direction; the filed
issue carries an AI-provenance note per the tray's policy.
