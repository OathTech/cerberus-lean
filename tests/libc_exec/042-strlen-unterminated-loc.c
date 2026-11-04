// 042: strlen on an unterminated array: the out-of-bounds load happens INSIDE libc (musl's strlen
// loop, string.c), so the oracle reports the C-library location and the Lean engine, which runs libc
// from the pinned Core text dump (no location annotations), reports <unknown location>: the declared
// transport limitation N4 (VALIDATION.md 2b). Recorded LOC_ONLY; the witness 016 carried until 2026-11-04,
// when the macro-type-rank fix removed its out-of-bounds read (a 32-bit narrowing in two-way strstr).
#include <string.h>
int main(void) { char a[4] = "abcd"; return (int)strlen(a); }
