# `__builtin_bswap64` crashes on arguments ≥ 2^63 (uncaught `Z.Overflow`)

**Affected:** `ocaml_frontend/ocaml_gcc_builtins.ml:29-40` (`bswap64`;
checked against `master` @ `b9aeedcb4` — our checkout's file is
byte-identical to it, diff-verified 2026-08-22).

## Description

`__builtin_bswap64` takes a `uint64_t`; any value up to 2^64−1 is a
legal argument. The Cerberus implementation begins

```ocaml
let bswap64 n =
  let n = Z.to_int64 n in   (* line 30 *)
  ...
```

`Z.to_int64` RAISES `Z.Overflow` for values outside the **signed** int64
range, i.e. for every argument ≥ 2^63 — half the builtin's legal domain.
Nothing catches it; the tool dies. (`bswap16`/`bswap32` are unaffected:
their arguments arrive already converted to uint16/uint32, inside int64
range. The sibling hazard in `bswap64` is subtler: its *result* is
re-read signed via `Z.of_int64`, so a swapped value with bit 63 set
comes back negative — masked in practice by the consumer converting back
to `unsigned long long`, but worth normalizing while fixing the raise.)

## Reproducer

```c
int main(void) {
  unsigned long long r = __builtin_bswap64(0x8877665544332211ull);
  return (int)(r & 0x7f);
}
```

```
$ cerberus --exec --batch --nolibc b.c
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Cerb_frontend__Ocaml_gcc_builtins.bswap64 in file "ocaml_frontend/ocaml_gcc_builtins.ml", line 30, characters 10-22
```

(verbatim, 2026-08-22, our build — file byte-identical to master.)

```
$ gcc b.c && ./a.out; echo $?
8
```

(the swapped value is 0x1122334455667788; low byte 0x88 & 0x7f = 8.)

## Observed vs expected

- Observed: uncaught `Z.Overflow`, tool crash.
- Expected: `Defined {value: "Specified(8)"}` for the program above
  (byte-swap of the full uint64 domain).

## Impact

Any evaluated `__builtin_bswap64` call whose argument has bit 63 set —
half the legal input space — crashes Cerberus with an internal error
(endianness-conversion code is a natural user of exactly such values).

## Proposed remedy

Compute on `Z` directly (no int64 detour), e.g.:

```ocaml
let bswap64 n =
  let byte i = Z.logand (Z.shift_right n (8*i)) (Z.of_int 0xff) in
  let acc = ref Z.zero in
  for i = 0 to 7 do acc := Z.logor (Z.shift_left !acc 8) (byte i) done;
  !acc
```

(also removes the signed-result `Z.of_int64` wart). Alternatively keep
int64 but convert via the two's-complement pattern
(`Z.signed_extract`/manual wrap) rather than the raising `Z.to_int64`.

## Classification

**TRUE BUG.** The parameter type is unsigned; rejecting (by crash) half
its domain cannot be intended, and the neighbours' explicit `assert`
style shows range restrictions are expressed deliberately when meant.

## Provenance

Found by the arc-14 re-mark (professor A) of our Lean port's
differential campaign, probing the port's own "asserts unreachable from
C" overclaim; pinned three-way in
tests/immaculate/nolibc/g4-bswap64-overflow.c (both backends fail-stop
— our port deliberately mirrors the crash rather than silently
diverging until upstream fixes it).
