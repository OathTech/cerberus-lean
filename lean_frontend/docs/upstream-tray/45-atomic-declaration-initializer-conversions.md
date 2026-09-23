# Atomic declaration initializers skip ordinary value conversions

September 23, 2026, [AGENT]. Local draft, not filed. Reproduced against pinned
pristine `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` and the SC prototype's fork.
No duplicate search or moving-upstream verification is claimed.

These programs require ordinary scalar initializer conversions under
[N1570 6.7.9p11](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf):

```c
int main(void) { _Atomic(int*) x=0; return 0; }
```

```c
int main(void) { _Atomic(unsigned char) x=257; return 0; }
```

```c
int main(void) { _Atomic(int) x=3.9; return 0; }
```

Run each with `--nolibc --batch --exec --mode=exhaustive`, using each engine's
own staged runtime. Both engines exit 125. The pointer case reaches a store of
integer zero to pointer type; the floating case reaches a store of floating 3.9
to integer type. Their first failure causes agree exactly. The narrowing case
reaches the concrete `bytes_of_int` range assertion. These are failed executions,
not three agreed C outcomes. Raw captures and exact commands are in the SC
atomic-interface completion evidence described by its
[review](../2026-09-23_sc-atomic-completion-review.md).

Four controls complete with `Specified(0)` in pristine and fork: explicit
`(int*)0`, a pointer-valued address initializer, an uninitialized atomic pointer
declaration, and ordinary `int *x=0`. This narrows the finding to conversion paths;
it does not suggest refusing all atomic declarations.

Pinned `frontend/model/translation.lem`'s `AilSdeclaration` arm (upstream line
4095) matches `Ctype.proj_ctype_ ty` with `Ctype.unatomic_` commented out. Its
later arithmetic conversion test also examines the atomic wrapper. The relevant
logic is unchanged in the fork. A prospective fix should use the corresponding
non-atomic value type for conversion while retaining the actual atomic object
type on allocation and initialization stores. It needs automatic/static,
aggregate-member, qualified, null-pointer, narrowing and floating controls;
this draft has not implemented or validated that repair.

The concurrency recorder retains the pointer case's explicit model type error
and completed prefix; it must not substitute the later lock-free configuration
gap, C UB or successful completion. This is an existing upstream-model defect
under SC-D05, distinct from an unresolved concurrency composition boundary.

AI provenance: investigated and drafted by Codex during the user-authorized SC
prototype work. No issue, PR or message has been sent externally.
