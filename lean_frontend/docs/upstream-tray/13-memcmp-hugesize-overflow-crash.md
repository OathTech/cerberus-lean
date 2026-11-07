# `memcmp` with a huge size crashes the tool (uncaught `Z.Overflow`)

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-07 as a fork-ahead delta (the oracle's `memcmp` counts
on `Z`, so a huge size reaches the checked per-byte load's own `UB_CERB002a_out_of_bound_load` verdict — the Lean
engine's answer since 2026-08, under the fork's ISO-fix register row R3, now retired; record
`lean_frontend/docs/2026-11-07_half-mirrors-oracle-record.md`; witness `scripts/check_half_mirrors.sh`, ladder row
1); Sent upstream (communicated privately, 2026-09-26), no public issue URL. Line cite corrected 2026-11-07: the
`Z.to_int size_n` reads are `memory/concrete/impl_mem.ml:2481-2482` at `c3ff8c53f` (`:2660` was `b9aeedcb4`; the
true-bug audit of 2026-11-04 re-observed the crash at upstream's tip `ae70925fc`, there `:2503-2504`). The patch at
the end is against `c3ff8c53f` (`git apply --check` in the pristine checkout: OK, 2026-11-07).

**Affected:** `memory/concrete/impl_mem.ml:2660` (`Concrete.memcmp`;
checked against `master` @ `b9aeedcb4` — the fork-drift manifest pins our
memory/concrete tree byte-identical to it on this file's surface, and the
cited line is upstream's own `Z.to_int size_n`).

## Description

`memcmp`'s concrete implementation converts the size argument with
`Z.to_int`:

```ocaml
     get_bytes ptrval1 [] (Z.to_int size_n) >>= fun bytes1 ->   (* :2660 *)
```

`Z.to_int` RAISES `Z.Overflow` for values outside the OCaml `int` range.
A C program can pass any `size_t` value — e.g. `(size_t)-1` = 2^64−1.
Reading past the object is UB, so a UB verdict would be fine; instead the
tool dies with an internal error before any semantic judgment.

## Reproducer

```c
#include <string.h>
int main(void) {
  char a[4] = {1,2,3,4};
  char b[4] = {1,2,3,4};
  return memcmp(a, b, (size_t)-1);
}
```

```
$ cerberus --exec --batch m.c
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Z.to_int in file "z.ml", line 221, characters 46-56
          Called from Cerb_frontend__Impl_mem.Concrete.memcmp in file "memory/concrete/impl_mem.ml", line 2660, characters 26-43
```

(verbatim, 2026-08-22, our build; the memcmp path and cited line are
upstream's.)

## Observed vs expected

- Observed: uncaught `Z.Overflow`, tool crash.
- Expected: a UB verdict — the per-byte read leaves the 4-byte object at
  offset 4, e.g. `Undefined {ub: "UB_CERB002a_out_of_bound_load", ...}`
  (that is precisely what our Lean port's checked per-byte loop reports
  for this program: the recursion kills at the first out-of-bounds load
  long before any count-dependent conversion matters).

## Impact

Any evaluated `memcmp` (and by the same `Z.to_int`-on-size shape,
sibling paths worth auditing — see remedy) whose size argument exceeds
`max_int` crashes Cerberus with an internal error on a program whose
misbehavior the tool exists to diagnose. Values like `(size_t)-1` arise
readily from underflowed size computations — exactly the buggy programs
one feeds a UB checker.

## Proposed remedy

Iterate on `Z` (or clamp the loop by the failing load): `get_bytes`
already loads byte-at-a-time through the checked `load`, which reports
the out-of-bounds UB on its own; counting down a `Z.t` instead of an
`int` removes the conversion entirely. More generally, the
`Z.to_int`/`Z.to_int64` family on C-controlled quantities is a crash
class worth a one-pass audit (cf. our report 12, `bswap64`'s
`Z.to_int64`).

## Classification

**TRUE BUG.** The conversion is an implementation detail leaking as a
crash on reachable input; the checked per-byte load machinery
immediately below it already implements the correct (UB-verdict)
behavior for the same program.

## Provenance

Found by professor B′ in the arc-14 S4b re-grade of our Lean port
(hunting residual crash paths after the port's memcmp was re-mirrored
through checked loads); pinned three-way in
tests/immaculate/libc/s4b-memcmp-hugesize.c (lane row ORACLE_CRASH with
the Lean UB token pinned).

## Fork status and patch (2026-11-07)

Fixed in the fork on 2026-11-07 ([USER 2026-11-04] agreed the fix pass under the standing bar; no semantics is
invented: the verdict is the one the memory model's own checked load already produces for the program, reached
instead of a host-integer exception). Before and after, verbatim (the fork's oracle at `1e5f2cbca` = pristine
`c3ff8c53f`, then the fixed tree; `--exec --batch` with the shipped library):

```text
$ cerberus --exec --batch m.c        # the reproducer above
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Z.to_int in file "z.ml", line 221, characters 46-56              (rc 125, before)
Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<5:10--5:34>"}                     (rc 1, after; = the Lean engine byte for byte)
```

Sibling sites checked (2026-11-07): `memcpy` already loops on `Z` (`Z.lt i size_n`), `realloc` takes `Z.min
alloc.size size_n` and allocates on `Z`, and `memset`/`memmove`/`strncmp`/`strncpy`/`calloc` are C code in the
shipped library (each access checked by the model) — a huge `size_t` reaches the out-of-bound UB or the
allocator's out-of-memory failure on every engine. The other `Z.to_int` reads in the file are sizes of TYPES
(`sizeof`, the file's own "will raise Overflow on huge structs" TODOs) or allocation sizes bounded by the address
space, not C-controlled counts.

The patch (the count on `Z`; the comment is the fork's registration note and may be dropped):

```diff
--- a/memory/concrete/impl_mem.ml
+++ b/memory/concrete/impl_mem.ml
@@ -2468,18 +2468,29 @@
   
   (* TODO: validate more, but looks good *)
   let memcmp loc ptrval1 ptrval2 (IV (_, size_n)) =
-    let rec get_bytes ptrval acc = function
-      | 0 ->
-          return (List.rev acc)
-      | size ->
-          load loc Ctype.unsigned_char ptrval >>= function
-            | (_, MVinteger (_, (IV (byte_prov, byte_n)))) ->
-                Nondeterminism.lift_undef (array_shift_ptrval loc ptrval Ctype.unsigned_char (IV (Prov_none, Z.one))) >>= fun ptr' ->
-                get_bytes ptr' (byte_n :: acc) (size-1)
-            | _ ->
-                assert false in
-     get_bytes ptrval1 [] (Z.to_int size_n) >>= fun bytes1 ->
-     get_bytes ptrval2 [] (Z.to_int size_n) >>= fun bytes2 ->
+    (* FORK FIX (2026-11-07, upstream-tray report 13; a fork-ahead delta, registered in
+       scripts/fork_drift_manifest.txt): the byte count stays on Z. Upstream converts the
+       C-controlled size with `Z.to_int size_n` BEFORE any byte is read, which raises an
+       uncaught Z.Overflow for a size outside OCaml's native int range (`memcmp(a, b,
+       (size_t)-1)`): a crash where the semantics' own verdict belongs, since the checked
+       per-byte `load` below reports the out-of-bound read (UB_CERB002a) long before the count
+       matters. The Lean engine's CerbMem.memcmpM feeds the size to the same checked loads
+       directly; both engines now answer identically. A count <= 0 is an empty comparison
+       (result 0) on both engines -- CerbMem.memcmpM's `Int.toNat`, and the shape of memcpy's
+       `Z.lt i size_n` loop above; a negative count is unreachable from C, a size_t being
+       non-negative after conv_int (upstream's `| size` arm recursed forever on one). *)
+    let rec get_bytes ptrval acc size =
+      if Z.leq size Z.zero then
+        return (List.rev acc)
+      else
+        load loc Ctype.unsigned_char ptrval >>= function
+          | (_, MVinteger (_, (IV (byte_prov, byte_n)))) ->
+              Nondeterminism.lift_undef (array_shift_ptrval loc ptrval Ctype.unsigned_char (IV (Prov_none, Z.one))) >>= fun ptr' ->
+              get_bytes ptr' (byte_n :: acc) (Z.pred size)
+          | _ ->
+              assert false in
+     get_bytes ptrval1 [] size_n >>= fun bytes1 ->
+     get_bytes ptrval2 [] size_n >>= fun bytes2 ->
      
      let open Z in
      return (IV (Prov_none, List.fold_left (fun acc (n1, n2) ->
```
