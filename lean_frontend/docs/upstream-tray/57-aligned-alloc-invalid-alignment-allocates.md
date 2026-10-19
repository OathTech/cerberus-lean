# `aligned_alloc(3, 9)` allocates: the proxy checks only that `size` is a multiple of `alignment`, never that the alignment is valid (C17 §7.22.3.1 requires a null return; C11 made it UB)

**Affected:** `runtime/libcore/std.core:380-393` (`aligned_alloc_proxy`;
`:385` `if size rem_t align = 0 then let strong ptr: pointer = alloc(align,
size) in pure(Specified(ptr)) else pure(undef(<<DUMMY(align_alloc)>>))`
— the only check is the size clause). Checked against `master` @
`b9aeedcb4`: the proxy is byte-identical. The Lean port runs the same
`std.core`, so both engines answer the same way. Draft 34 reports the
`align = 0` case of the same proxy (an uncaught `Division_by_zero`).

## Description

C11 §7.22.3.1#2: "The value of `alignment` shall be a valid alignment
supported by the implementation and the value of `size` shall be an
integral multiple of `alignment`" — a `shall` outside a constraint, so a
violation is undefined behaviour. C17, after DR 460, §7.22.3.1#2-3: the
size-multiple requirement is gone and "If the value of `alignment` is not
a valid alignment supported by the implementation the function shall fail
by returning a null pointer." The proxy implements the C11 size clause
(as `DUMMY` UB) and no alignment clause at all: `alignment = 3` is neither
a power of two nor a supported alignment, yet the call allocates at
"alignment 3" and the program's verdict is a defined value.

Witness (measured 2026-10-19 on the fork @ `e7e9bb427`, both engines,
`scripts/test_exec.sh`):

```c
void *aligned_alloc(unsigned long alignment, unsigned long size);
void free(void *p);
int main(void) {
  char *p = aligned_alloc(3, 9); /* 3 is not a valid alignment */
  if (p == 0) return 1;
  p[0] = 42;
  int r = p[0];
  free(p);
  return r;
}
```

```text
[1/1] MATCH aligned-alloc-3-9: VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
```

## Expected

Either reading, stated: under C17, a null pointer for an unsupported
alignment (and no `size` restriction); under C11, undefined behaviour for
both violations. The present proxy is neither: it is the C11 size clause
alone. A validity test (a positive power of two, and at most the
implementation's supported maximum) belongs in the proxy beside the
existing `rem_t` check, which draft 34's zero-alignment guard would share.

## Origin

Filed from cerberus-caesium's note 2, item G2 (2026-10-17), with its
reading corrected here: C17 returns null rather than leaving the call
undefined.
