// R2 (arc-14 re-mark): __builtin_bswap64 with an argument >= 2^63 —
// LEGAL C (the parameter type is uint64_t). Three-way:
//   gcc:    swapped value (low byte 0x88 -> returns 8 here);
//   ORACLE: uncaught Z.Overflow crash (ocaml_gcc_builtins.ml:30
//           Z.to_int64 raises on >= 2^63) — a crash on legal C,
//           upstream-tray #12;
//   Lean:   panics at the mirrored guard (CerbUtils.gcc_builtin_bswap64
//           mirrors the raise as a loud panic — mirrored, not improved,
//           the memcmp-assert policy).
// EXPECTED lane row: both CRASH (MATCH, agreed fail-stop), pinned.
int main(void) {
  unsigned long long r = __builtin_bswap64(0x8877665544332211ull);
  return (int)(r & 0x7f);
}
