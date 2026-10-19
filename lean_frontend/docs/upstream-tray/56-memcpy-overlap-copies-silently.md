# `memcpy` on overlapping objects copies silently: the memory model's `memcpy` has no overlap check, so a C17 §7.24.2.1 UB program gets a defined verdict

**Affected:** `memory/concrete/impl_mem.ml:2679-2690` (`memcpy`; the body
opens with `(* TODO: if ptrval1 and ptrval2 overlap ==> UB *)` and then
copies byte by byte, forward, `load`/`store` of `unsigned_char` at
`array_shift_ptrval` offsets `0 … size-1`); `runtime/libcore/std.core:398-408`
(`memcpy_proxy`: `memop(Memcpy, s1, s2, n)` after loading the three
arguments, no check of its own). Checked against `master` @ `b9aeedcb4`:
the `memcpy` function (upstream `:2635`) and the proxy are byte-identical.
The Lean port mirrors the loop (`lean_frontend/CerbMem.lean:3568`,
`memcpyM`, per its header's `impl_mem.ml` cite) and therefore answers the
same way.

## Description

C17 §7.24.2.1#2: "If copying takes place between objects that overlap, the
behavior is undefined." The model's `memcpy` neither detects the overlap
nor reports it; the forward byte loop produces the "obvious" forward-copy
result and the program's verdict is a defined value. The `TODO` in the
function records the intent to make it UB.

Witness (measured 2026-10-19 on the fork @ `e7e9bb427`, both engines,
`scripts/test_exec.sh`; the Lean port agrees with the oracle, so this is a
report about the shared semantics, not a port discrepancy):

```c
void *memcpy(void *dst, const void *src, unsigned long n);
int main(void) {
  char b[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  memcpy(b, b + 1, 4);          /* overlapping objects: C17 7.24.2.1 UB */
  return b[0] + b[3];           /* 2 + 5 if copied byte-wise forward */
}
```

```text
[1/1] MATCH memcpy-overlap: VAL:{value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

## Expected

An undefined-behaviour verdict for an overlapping copy (a dedicated UB
identifier, or the proxy's `DUMMY` form), or a documented reading if the
permissive answer is deliberate. The overlap test is a comparison of the
two pointers' allocation ids and byte ranges, both available to `memcpy`
through the same `PV` values it already shifts.

## Origin

Filed from cerberus-caesium's note 2, item G1 (2026-10-17): its harness
hook refuses the overlap and is stuck on this difference. Draft 53 is a
separate `memcpy` report (a crash on a symbolic pointer).
