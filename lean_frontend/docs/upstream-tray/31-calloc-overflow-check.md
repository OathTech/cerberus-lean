# libc `calloc` has no `nmemb * size` overflow check (returns a block for a request whose byte count overflows `size_t`)

**Status (2026-09-05, before filing):** the upstream evidence below was
re-verified on this date; one column of our own three-engine record
moved since it was first taken (our Lean port used to run out of memory
on this probe and now returns the same value as the OCaml oracle), so
this draft is held for a second look by the operator before it is filed.
Nothing in the upstream-facing claim depends on that column.

**Affected:** `runtime/libc/src/stdlib.c:125-134` (`calloc`). Checked
against `master` @ `b9aeedcb4`: byte-identical.

## Description

```c
void *calloc(size_t nmemb, size_t size)
{
  unsigned char *ret;
  ret = malloc(nmemb * size);
  if (!ret)
    return ret;
  for (int i=0; i < nmemb*size; i++)
    ret[i] = 0;
  return ret;
}
```

(stdlib.c:125-134, verbatim.) The product `nmemb * size` is computed in
`size_t` and passed to `malloc` with no overflow check. C17 §7.22.3.2#2
(the C11 text as clarified by DR 460): "The `calloc` function allocates
space for an array of `nmemb` objects, each of whose size is `size`. …
If the product of `nmemb` and `size` would overflow `size_t`, the
`calloc` function returns a null pointer" — hosted implementations
(glibc, musl) check `nmemb && size > SIZE_MAX / nmemb`. musl's `calloc`,
from which this file derives, has the check; the Cerberus copy dropped
it. (Secondary: the zeroing loop's counter is an `int`, so a block of
more than `INT_MAX` bytes is never fully zeroed — another consequence of
not bounding the request.)

## Reproducer

`tests/noodle-probes/mem/mem_calloc_overflow.c`:

```c
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  void *p = calloc(SIZE_MAX / 2 + 2, 2);
  return p == 0 ? 1 : 2;
}
```

```
$ cerberus --exec --batch --mode=exhaustive mem_calloc_overflow.c
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`,
shipped libc; the fork's oracle at `928aa1e76` and our Lean port print
the identical line.)

```
$ gcc -std=c11 -O0 mem_calloc_overflow.c && ./a.out; echo $?
1
```

(gcc 13.3.0 / glibc; verbatim 2026-09-05.)

A caveat on THIS probe's arithmetic: on Cerberus the request is
additionally distorted by the `size_t` rank defect reported separately
(tray 20): `SIZE_MAX / 2 + 2` is computed at 32 bits and re-wrapped, so
the product that reaches `malloc` is 4294967298 rather than the wrapped
2 that a conforming implementation would compute — either way a
non-null pointer comes back for a request that a conforming `calloc` must
refuse. A probe independent of tray 20 is `calloc((size_t)1 << 63, 4)`
(the product wraps to 0): a conforming `calloc` returns NULL; this
`calloc` calls `malloc(0)`, which in the Cerberus model returns a
non-null pointer. We have not run that variant; it is offered as a
check, not as evidence.

## Observed vs expected

- Observed: non-null result for an overflowing request.
- Expected: `NULL` (C17 §7.22.3.2#2).

## Impact

Minor in practice (overflowing `calloc` requests are rare and usually a
bug in the calling program) but it is exactly the class of check
verification users rely on the model to enforce: a program that guards
`if (!p)` after `calloc` believes it has `nmemb * size` bytes when it has
a wrapped-around amount.

## Proposed remedy

```c
void *calloc(size_t nmemb, size_t size)
{
  if (size && nmemb > (size_t)-1 / size) return 0;   /* C17 §7.22.3.2 */
  size_t total = nmemb * size;
  unsigned char *ret = malloc(total);
  if (!ret) return ret;
  for (size_t i = 0; i < total; i++) ret[i] = 0;
  return ret;
}
```

(also making the zeroing loop's counter a `size_t`).

## Classification

**TRUE BUG (libc, minor).** The C17 wording is explicit; the musl
ancestor has the check; the omission has no comment.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L2). Re-verified 2026-09-05 on the un-forked upstream binary +
runtime @ `b9aeedcb4`, the fork's oracle and the Lean port (lines above
verbatim). Localisation and this draft by Claude (Fable 5.1) under
operator direction; the filed issue carries an AI-provenance note per the
tray's policy.
