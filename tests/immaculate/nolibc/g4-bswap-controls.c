// G4 controls: bswap16/32/64 on in-range values must MATCH both sides.
// The 16/32 range asserts (ocaml_gcc_builtins.ml:15,22) are unreachable
// from C (the frontend converts the argument to uint16_t/uint32_t
// first). NOT SO for bswap64 (re-mark R2 correction — the original
// comment overclaimed): its Z.to_int64 (ocaml_gcc_builtins.ml:30)
// RAISES on arguments >= 2^63, which are legal C — see
// g4-bswap64-overflow.c (both sides fail-stop; the ORACLE's crash on
// legal C is upstream-tray #12). bswap64's result reinterpretation
// (Z.of_int64: bit-63-set results come back NEGATIVE upstream) is
// exercised by the third case (swapped pattern 0x88... >= 2^63).
int main(void) {
  if (__builtin_bswap16(0x1234) != 0x3412) return 1;
  if (__builtin_bswap32(0x11223344u) != 0x44332211u) return 2;
  if (__builtin_bswap64(0x1122334455667788ull) != 0x8877665544332211ull) return 3;
  return 0;
}
