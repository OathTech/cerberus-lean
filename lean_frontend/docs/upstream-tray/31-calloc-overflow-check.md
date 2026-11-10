# libc `calloc` multiplies `nmemb * size` without an overflow check (a wrapped request returns a block) — WITHDRAWN as a C17 defect report, kept as a hardening note

**Status, 2026-11-10: WITHDRAWN as a C17 defect report, pending a check against a primary copy of the standard.**
[AGENT 2026-11-10] An earlier version of this file quoted, as C17 7.22.3.2#2, a sentence requiring `calloc` to return a
null pointer when `nmemb * size` overflows. That sentence is NOT in the C11 text shipped with Cerberus
(`tools/n1570.html`, 7.22.3.2), whose whole normative text is: "The calloc function allocates space for an array of
nmemb objects, each of whose size is size. The space is initialized to all bits zero." (#2) and "The calloc function
returns either a null pointer or a pointer to the allocated space." (#3). No copy of C17 was available to verify it
there; by recollection, and by the secondary sources the pre-merge review of 2026-11-10 consulted, the explicit
wraparound wording arrived with C23, and the "DR 460" attribution was wrong. Neither was checked against the documents
themselves. Until someone checks a primary source, this file makes no claim that C17 requires the null return.

What remains, and is measured: the multiplication wraps silently, so a caller that asks for `nmemb` objects of `size`
bytes can receive a non-null pointer to fewer bytes (the two runs at the end of this file, on un-forked upstream at
`c3ff8c53f`; glibc returns NULL for both). That is offered as a hardening note for the shipped library, not as a
conformance defect.

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
`size_t` and passed to `malloc` with no overflow check. C11 7.22.3.2#2
(`tools/n1570.html`): "The calloc function allocates space for an array of
nmemb objects, each of whose size is size." (A sentence about overflow that
stood here as a quotation was removed on 2026-11-10: see the status at the
top.) Hosted implementations
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
- Suggested: `NULL`, as glibc and musl return (not claimed as a C17 requirement; see the status at the top).

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
  if (size && nmemb > (size_t)-1 / size) return 0;   /* the product would wrap */
  size_t total = nmemb * size;
  unsigned char *ret = malloc(total);
  if (!ret) return ret;
  for (size_t i = 0; i < total; i++) ret[i] = 0;
  return ret;
}
```

(also making the zeroing loop's counter a `size_t`).

## Classification

**HARDENING NOTE (libc)** since 2026-11-10; it was drafted as TRUE BUG (libc, minor) on the strength of the
quotation that has been removed. The musl ancestor has the check; the omission has no comment.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L2). Re-verified 2026-09-05 on the un-forked upstream binary +
runtime @ `b9aeedcb4`, the fork's oracle and the Lean port (lines above
verbatim). Localisation and this draft by Claude (Fable 5.1) under
operator direction; the filed issue carries an AI-provenance note per the
tray's policy.

## Re-run at `c3ff8c53f` (2026-11-10): still reproduces; the independent variant is now evidence; a quotation corrected

(Un-forked upstream binary + runtime @ `c3ff8c53f`, both fork engines and gcc 13.3.0 `-std=c11 -w -O0`, all run on 2026-11-10; outputs verbatim. [AGENT 2026-11-10], the reporting slice.)

```
$ cerberus --exec --batch mem_calloc_overflow.c
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

(gcc/glibc exits 1.) `runtime/libc/src/stdlib.c:125-134` is unchanged at `c3ff8c53f`. The variant this report
offered "as a check, not as evidence" — independent of report 20's `size_t` arithmetic — has now been run:

```c
#include <stdlib.h>
int main(void) { void *p = calloc((size_t)1 << 63, 4); return p == 0 ? 1 : 2; }
```

```
$ cerberus --exec --batch calloc_wrap0.c
Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

(gcc/glibc exits 1.) The product wraps to 0 and `malloc(0)` returns a non-null pointer.

The correction to the Description that stood here was moved to the status at the top of this file on 2026-11-10.

Fork status: unchanged in both engines (identical lines). The fork has not changed this behaviour.
