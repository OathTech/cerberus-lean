// Declared typing residual (NOT fixed by the 2026-11-04 rank fix; upstream's deliberate NON-STD arms in
// AilTypesAux.usual_arithmetic_integer_default, ailTypesAux.lem): size_t against long long / unsigned long long
// is TYPED size_t (gcc: unsigned long long), intptr_t against unsigned long / long long is typed intptr_t
// (gcc: unsigned long / long long). The VALUES agree at 64 bits; only _Generic sees the type. Pinned to the
// fork's line; gcc 13 prints "12 12 10 11 12" for the same program.
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#define T(e) _Generic((e), int: 7, unsigned: 8, long: 9, unsigned long: 10, long long: 11, unsigned long long: 12, default: 0)
int main(void) { size_t n = 5; long long ll = 3; unsigned long long ull = 3; intptr_t ip = 5; unsigned long ul = 3;
  printf("%d %d %d %d %d\n", T(n + ll), T(n * ull), T(ip + ul), T(ip - ll), T(ip ^ ull)); return 0; }
