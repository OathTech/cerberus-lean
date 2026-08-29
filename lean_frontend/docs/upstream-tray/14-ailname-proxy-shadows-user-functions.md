# Core-stdlib `ailname` proxies shadow program-defined functions (`read`, `write`, `open`, ...)

**Status: DRAFT — not filed.** Found 2026-08-22 by the CN-tutorial
warm-up differential lane (arc/cn-differential): 6 of the 106 cn-tutorial
exercise files define a function named `read`, and every harness built on
them was refused by the oracle.

## Classification

TRUE BUG. `read` is not a reserved identifier in C (C11 §7.1.3 reserves
`_`-prefixed names and names from included standard headers; POSIX names
are only reserved in POSIX-conforming programs that include the relevant
headers — these programs include nothing). gcc accepts and runs the same
programs with the expected results. Any strictly conforming program that
defines its own `read`, `write`, `open`, `close`, `link`, `stat`, ... is
miscompiled: calls to the program's own function are silently redirected
to the Core stdlib's POSIX proxy.

## Reproducer (2 lines)

```c
unsigned int read(unsigned int *p) { return *p; }
int main(void) { unsigned int a = 42; return read(&a) != 42u; }
```

Upstream `master` @ `b9aeedcb4` (deps/cerberus-upstream, byte-identical
cited files), verbatim:

```
$ cerberus --nolibc --exec --batch readmin.c
Error {msg: "ill-formed program: `readmin.c:2:51-53 (cursor: 2:51): 'Symbol(85, SD_Id("read_proxy"))' does not point to a function (cfunction)'"}

$ cerberus --exec --batch readmin.c        # with libc
Undefined {ub: "UB038_number_of_args", stderr: "", loc: "<2:46--2:54>"}
```

gcc -std=c11 -Wall: compiles warning-free, exit status 0. Elaboration
without execution (`cerberus readmin.c`) succeeds — the bad binding only
surfaces when the call is evaluated (or, under `--nolibc`, when the
proxy symbol resolves to nothing callable).

## Mechanism (verified citations)

* `runtime/libcore/std.core:642`:
  `proc [ailname = "read"] read_proxy (...)` — the Core stdlib claims the
  C name `read` (similarly `pread`, `write`, `open`, `close`, `stat`,
  `link`, `malloc`, `free`, `memcmp`, `printf`, ... — full list below).
* `frontend/model/translation.lem:245` (`translate_function_designator`):
  for ANY identifier expression of function type whose name (`SD_Id str`)
  appears in `stdlib.ailnames`, the elaborated designator is
  `Mem.fun_ptrval sym_proxy` — **unconditionally**, without checking
  whether the translation unit itself defines a function of that name.
  The program's own definition is elaborated, but every call site binds
  to the stdlib proxy instead.
* `frontend/model/translation.lem:4317`: the same unguarded
  `Map.lookup str stdlib.ailnames` redirects the `funinfo` entry for a
  bodiless declaration to the proxy symbol ("get the correct symbol if a
  proxy exists").

Consequences by mode:
* `--nolibc`: the proxy proc exists in the stdlib map but is not a
  linked `cfunction` value → "ill-formed program ... does not point to a
  function". A *well-formed* program is reported ill-formed.
* with libc: the call goes to POSIX `read(fd, buf, size)` → spurious
  `UB038_number_of_args` (or worse, a type-punned call that "works").

Full `ailname` claim list in `std.core` (any of these names is
shadowable): `aligned_alloc chdir chmod chown close closedir free link
lseek lstat malloc memcmp mkdir open opendir pread printf pwrite read
readdir readlink realloc rename rewinddir rmdir stat symlink truncate
umask unlink write` (plus `__builtin_*` / `__any_bounded_int`, which are
reserved-namespace and fine).

## Proposed remedy

Gate the `ailnames` lookup on the program NOT providing its own
definition: in `translate_function_designator` (translation.lem:245) and
at the funinfo site (translation.lem:4317), consult
`stdlib.ailnames` only when the identifier's symbol has no function
definition in the current sigma (the `Just (loc, mrk, _, param_syms,
stmt)` case a few lines below :4317 already distinguishes exactly this).
A program-defined `read` then shadows the stdlib proxy, matching every
other compiler; declared-but-undefined POSIX names keep today's proxy
behavior.

## Cross-checks

* Three-way: gcc well-defined (exit 0) vs upstream cerberus refusal —
  identical failure on our fork (which is faithful-by-design here: the
  Lean pipeline, generated from the same translation.lem, reproduces the
  same `read_proxy` ill-formed error verbatim modulo symbol ids).
* Observed corpus impact: any external C code defining functions with
  POSIX names (`read`, `write`, `open`, `stat`, …) — a common pattern
  in teaching/verification example corpora — is rejected or
  mis-executed. First observed on external example code defining
  `read`; the 2-line reproducer above is a fresh minimal witness.
