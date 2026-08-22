# Fix `__builtin_bswap64` crash on arguments >= 2^63

## Problem

`__builtin_bswap64` takes a `uint64_t`, so any value up to 2^64 - 1 is a
legal argument. The implementation
(`ocaml_frontend/ocaml_gcc_builtins.ml`) began with

```ocaml
let bswap64 n =
  let n = Z.to_int64 n in
  ...
```

`Z.to_int64` raises `Z.Overflow` for values outside the **signed** int64
range, i.e. for every argument with bit 63 set — half the builtin's legal
domain, and exactly the kind of value endianness-conversion code feeds
it. Nothing catches the exception, so the tool dies:

```
$ cerberus --exec --batch --nolibc b.c
cerberus: internal error, uncaught exception:
          Z.Overflow
          Raised by primitive operation at Cerb_frontend__Ocaml_gcc_builtins.bswap64
          in file "ocaml_frontend/ocaml_gcc_builtins.ml", line 30, characters 10-22
```

for

```c
int main(void) {
  unsigned long long r = __builtin_bswap64(0x8877665544332211ull);
  return (int)(r & 0x7f);
}
```

where gcc prints exit code 8 (the swapped value is 0x1122334455667788;
0x88 & 0x7f = 8).

`bswap16`/`bswap32` are unaffected: their arguments arrive already
converted to uint16/uint32 range, well inside int64. (Their explicit
`assert`s also show that intentional range restrictions are written out
in this file — the bswap64 raise is not one.)

There was also a subtler wart on the way out: the swapped result was
read back with `Z.of_int64`, i.e. **signed**, so a result with bit 63
set came back as a negative integer for a builtin whose result type is
unsigned (masked in practice by the consumer converting to
`unsigned long long`, but wrong as a value).

## Fix

Reinterpret the argument as a two's complement int64 before converting
(`Z.signed_extract n 0 64`, which cannot overflow `Z.to_int64`), and
read the swapped int64 back as unsigned (`Z.extract ... 0 64`). The
byte-swap logic itself is untouched, so the change is only at the two
conversion edges:

```ocaml
let bswap64 n =
  let n = Z.to_int64 (Z.signed_extract n 0 64) in
  let swapped = (* ... unchanged Int64 byte-shuffle ... *) in
  Z.extract (Z.of_int64 swapped) 0 64
```

## Test

`tests/ci/0345-builtin_bswap64.c` is self-checking (returns 0 on
success, a distinct non-zero code per failing case; compiles and exits 0
under `gcc -std=c11 -Wall`):

- `0x8000000000000001` → `0x0100000000000080` (bit 63 set: the crashing
  half of the domain, expected value from the standard byte-reversal
  semantics),
- `0xffffffffffffffff` → itself (maximal value),
- `0x8877665544332211` → `0x1122334455667788` (crashed before),
- `0x0102030405060708` → `0x0807060504030201` (previously-working half
  of the domain, guards against regression),
- `0` → `0`.

Run with:

```
cd tests
./run-ci.sh 0345-builtin_bswap64.c
```

Before the fix the test dies with the uncaught `Z.Overflow` above; after
it, the run is `Defined {value: "Specified(0)", ...}`. The rest of the
CI lane is unchanged relative to the base commit (verified by running
`./run-ci.sh` on both and diffing the results), and `bswap16`/
`bswap32`/sub-2^63 `bswap64` calls were additionally spot-checked
against gcc.
