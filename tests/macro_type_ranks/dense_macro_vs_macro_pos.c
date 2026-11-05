// Macro type against macro type (pre-merge review P3-1, 2026-11-04): the seven header-reachable macro integer
// types pairwise, both operand orders, a big (2^32+5; wchar_t 2^31-safe) and a small operand per type so no
// product overflows, every operator, the conditional operator, every op= on a 64-bit left operand (a wchar_t
// object cannot hold the results: tray 62's store crash). intptr_t is paired with the SIGNED macro types only:
// against an unsigned 64-bit partner upstream's NON-STD Signed Intptr_t typing arm reports a false UB036
// (filed; pinned by gap_intptr_t_unsigned_false_ub036), which this witness does not re-pin.
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
int main(void) {
  int c = 1;
  size_t b_size_t = 4294967301ULL, s_size_t = 3;
  ptrdiff_t b_ptrdiff_t = 4294967301ULL, s_ptrdiff_t = 3;
  intptr_t b_intptr_t = 4294967301ULL, s_intptr_t = 3;
  uintptr_t b_uintptr_t = 4294967301ULL, s_uintptr_t = 3;
  intmax_t b_intmax_t = 4294967301ULL, s_intmax_t = 3;
  uintmax_t b_uintmax_t = 4294967301ULL, s_uintmax_t = 3;
  wchar_t b_wchar_t = 200000005, s_wchar_t = 3;
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_size_t), (unsigned long long)(b_size_t - s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_size_t), (unsigned long long)(b_size_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t * b_size_t), (unsigned long long)(b_size_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_size_t), (unsigned long long)(b_size_t & s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_size_t), (unsigned long long)(b_size_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t | b_size_t), (unsigned long long)(b_size_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_size_t), (unsigned long long)(b_size_t != s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_size_t), (unsigned long long)(b_size_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t < b_size_t), (unsigned long long)(b_size_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_size_t), (unsigned long long)(b_size_t >= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_size_t), (unsigned long long)(s_size_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t + s_size_t), (unsigned long long)(s_size_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_size_t), (unsigned long long)(s_size_t / b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_size_t), (unsigned long long)(s_size_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t % s_size_t), (unsigned long long)(s_size_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_size_t), (unsigned long long)(s_size_t ^ b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_size_t), (unsigned long long)(s_size_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t == s_size_t), (unsigned long long)(s_size_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_size_t), (unsigned long long)(s_size_t <= b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_size_t), (unsigned long long)(s_size_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t > s_size_t), (unsigned long long)(s_size_t >= b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_size_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t << 1), (unsigned long long)(b_size_t >> 1), (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(c ? b_size_t : b_ptrdiff_t), (unsigned long long)(c ? b_ptrdiff_t : b_size_t));
  { size_t t = b_size_t; t += s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t -= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t *= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t /= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t %= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t &= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t |= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t ^= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t += s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_size_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_size_t; printf("%llu ", (unsigned long long)t); }
  printf("|size_t/ptrdiff_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t + s_uintptr_t), (unsigned long long)(s_uintptr_t + b_size_t), (unsigned long long)(b_size_t - s_uintptr_t), (unsigned long long)(s_uintptr_t - b_size_t), (unsigned long long)(b_size_t * s_uintptr_t), (unsigned long long)(s_uintptr_t * b_size_t), (unsigned long long)(b_size_t / s_uintptr_t), (unsigned long long)(s_uintptr_t / b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t % s_uintptr_t), (unsigned long long)(s_uintptr_t % b_size_t), (unsigned long long)(b_size_t & s_uintptr_t), (unsigned long long)(s_uintptr_t & b_size_t), (unsigned long long)(b_size_t | s_uintptr_t), (unsigned long long)(s_uintptr_t | b_size_t), (unsigned long long)(b_size_t ^ s_uintptr_t), (unsigned long long)(s_uintptr_t ^ b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t == s_uintptr_t), (unsigned long long)(s_uintptr_t == b_size_t), (unsigned long long)(b_size_t != s_uintptr_t), (unsigned long long)(s_uintptr_t != b_size_t), (unsigned long long)(b_size_t < s_uintptr_t), (unsigned long long)(s_uintptr_t < b_size_t), (unsigned long long)(b_size_t <= s_uintptr_t), (unsigned long long)(s_uintptr_t <= b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t > s_uintptr_t), (unsigned long long)(s_uintptr_t > b_size_t), (unsigned long long)(b_size_t >= s_uintptr_t), (unsigned long long)(s_uintptr_t >= b_size_t), (unsigned long long)(s_size_t + b_uintptr_t), (unsigned long long)(b_uintptr_t + s_size_t), (unsigned long long)(s_size_t - b_uintptr_t), (unsigned long long)(b_uintptr_t - s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t * b_uintptr_t), (unsigned long long)(b_uintptr_t * s_size_t), (unsigned long long)(s_size_t / b_uintptr_t), (unsigned long long)(b_uintptr_t / s_size_t), (unsigned long long)(s_size_t % b_uintptr_t), (unsigned long long)(b_uintptr_t % s_size_t), (unsigned long long)(s_size_t & b_uintptr_t), (unsigned long long)(b_uintptr_t & s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t | b_uintptr_t), (unsigned long long)(b_uintptr_t | s_size_t), (unsigned long long)(s_size_t ^ b_uintptr_t), (unsigned long long)(b_uintptr_t ^ s_size_t), (unsigned long long)(s_size_t == b_uintptr_t), (unsigned long long)(b_uintptr_t == s_size_t), (unsigned long long)(s_size_t != b_uintptr_t), (unsigned long long)(b_uintptr_t != s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t < b_uintptr_t), (unsigned long long)(b_uintptr_t < s_size_t), (unsigned long long)(s_size_t <= b_uintptr_t), (unsigned long long)(b_uintptr_t <= s_size_t), (unsigned long long)(s_size_t > b_uintptr_t), (unsigned long long)(b_uintptr_t > s_size_t), (unsigned long long)(s_size_t >= b_uintptr_t), (unsigned long long)(b_uintptr_t >= s_size_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t << 1), (unsigned long long)(b_size_t >> 1), (unsigned long long)(b_uintptr_t << 1), (unsigned long long)(b_uintptr_t >> 1), (unsigned long long)(c ? b_size_t : b_uintptr_t), (unsigned long long)(c ? b_uintptr_t : b_size_t));
  { size_t t = b_size_t; t += s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t -= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t *= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t /= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t %= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t &= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t |= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t ^= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t += s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t -= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t *= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t /= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t %= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t &= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t |= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t ^= s_size_t; printf("%llu ", (unsigned long long)t); }
  printf("|size_t/uintptr_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t + s_intmax_t), (unsigned long long)(s_intmax_t + b_size_t), (unsigned long long)(b_size_t - s_intmax_t), (unsigned long long)(s_intmax_t - b_size_t), (unsigned long long)(b_size_t * s_intmax_t), (unsigned long long)(s_intmax_t * b_size_t), (unsigned long long)(b_size_t / s_intmax_t), (unsigned long long)(s_intmax_t / b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t % s_intmax_t), (unsigned long long)(s_intmax_t % b_size_t), (unsigned long long)(b_size_t & s_intmax_t), (unsigned long long)(s_intmax_t & b_size_t), (unsigned long long)(b_size_t | s_intmax_t), (unsigned long long)(s_intmax_t | b_size_t), (unsigned long long)(b_size_t ^ s_intmax_t), (unsigned long long)(s_intmax_t ^ b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t == s_intmax_t), (unsigned long long)(s_intmax_t == b_size_t), (unsigned long long)(b_size_t != s_intmax_t), (unsigned long long)(s_intmax_t != b_size_t), (unsigned long long)(b_size_t < s_intmax_t), (unsigned long long)(s_intmax_t < b_size_t), (unsigned long long)(b_size_t <= s_intmax_t), (unsigned long long)(s_intmax_t <= b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t > s_intmax_t), (unsigned long long)(s_intmax_t > b_size_t), (unsigned long long)(b_size_t >= s_intmax_t), (unsigned long long)(s_intmax_t >= b_size_t), (unsigned long long)(s_size_t + b_intmax_t), (unsigned long long)(b_intmax_t + s_size_t), (unsigned long long)(s_size_t - b_intmax_t), (unsigned long long)(b_intmax_t - s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t * b_intmax_t), (unsigned long long)(b_intmax_t * s_size_t), (unsigned long long)(s_size_t / b_intmax_t), (unsigned long long)(b_intmax_t / s_size_t), (unsigned long long)(s_size_t % b_intmax_t), (unsigned long long)(b_intmax_t % s_size_t), (unsigned long long)(s_size_t & b_intmax_t), (unsigned long long)(b_intmax_t & s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t | b_intmax_t), (unsigned long long)(b_intmax_t | s_size_t), (unsigned long long)(s_size_t ^ b_intmax_t), (unsigned long long)(b_intmax_t ^ s_size_t), (unsigned long long)(s_size_t == b_intmax_t), (unsigned long long)(b_intmax_t == s_size_t), (unsigned long long)(s_size_t != b_intmax_t), (unsigned long long)(b_intmax_t != s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t < b_intmax_t), (unsigned long long)(b_intmax_t < s_size_t), (unsigned long long)(s_size_t <= b_intmax_t), (unsigned long long)(b_intmax_t <= s_size_t), (unsigned long long)(s_size_t > b_intmax_t), (unsigned long long)(b_intmax_t > s_size_t), (unsigned long long)(s_size_t >= b_intmax_t), (unsigned long long)(b_intmax_t >= s_size_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t << 1), (unsigned long long)(b_size_t >> 1), (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(c ? b_size_t : b_intmax_t), (unsigned long long)(c ? b_intmax_t : b_size_t));
  { size_t t = b_size_t; t += s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t -= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t *= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t /= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t %= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t &= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t |= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t ^= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t += s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_size_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_size_t; printf("%llu ", (unsigned long long)t); }
  printf("|size_t/intmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t + s_uintmax_t), (unsigned long long)(s_uintmax_t + b_size_t), (unsigned long long)(b_size_t - s_uintmax_t), (unsigned long long)(s_uintmax_t - b_size_t), (unsigned long long)(b_size_t * s_uintmax_t), (unsigned long long)(s_uintmax_t * b_size_t), (unsigned long long)(b_size_t / s_uintmax_t), (unsigned long long)(s_uintmax_t / b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t % s_uintmax_t), (unsigned long long)(s_uintmax_t % b_size_t), (unsigned long long)(b_size_t & s_uintmax_t), (unsigned long long)(s_uintmax_t & b_size_t), (unsigned long long)(b_size_t | s_uintmax_t), (unsigned long long)(s_uintmax_t | b_size_t), (unsigned long long)(b_size_t ^ s_uintmax_t), (unsigned long long)(s_uintmax_t ^ b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t == s_uintmax_t), (unsigned long long)(s_uintmax_t == b_size_t), (unsigned long long)(b_size_t != s_uintmax_t), (unsigned long long)(s_uintmax_t != b_size_t), (unsigned long long)(b_size_t < s_uintmax_t), (unsigned long long)(s_uintmax_t < b_size_t), (unsigned long long)(b_size_t <= s_uintmax_t), (unsigned long long)(s_uintmax_t <= b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t > s_uintmax_t), (unsigned long long)(s_uintmax_t > b_size_t), (unsigned long long)(b_size_t >= s_uintmax_t), (unsigned long long)(s_uintmax_t >= b_size_t), (unsigned long long)(s_size_t + b_uintmax_t), (unsigned long long)(b_uintmax_t + s_size_t), (unsigned long long)(s_size_t - b_uintmax_t), (unsigned long long)(b_uintmax_t - s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t * b_uintmax_t), (unsigned long long)(b_uintmax_t * s_size_t), (unsigned long long)(s_size_t / b_uintmax_t), (unsigned long long)(b_uintmax_t / s_size_t), (unsigned long long)(s_size_t % b_uintmax_t), (unsigned long long)(b_uintmax_t % s_size_t), (unsigned long long)(s_size_t & b_uintmax_t), (unsigned long long)(b_uintmax_t & s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t | b_uintmax_t), (unsigned long long)(b_uintmax_t | s_size_t), (unsigned long long)(s_size_t ^ b_uintmax_t), (unsigned long long)(b_uintmax_t ^ s_size_t), (unsigned long long)(s_size_t == b_uintmax_t), (unsigned long long)(b_uintmax_t == s_size_t), (unsigned long long)(s_size_t != b_uintmax_t), (unsigned long long)(b_uintmax_t != s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t < b_uintmax_t), (unsigned long long)(b_uintmax_t < s_size_t), (unsigned long long)(s_size_t <= b_uintmax_t), (unsigned long long)(b_uintmax_t <= s_size_t), (unsigned long long)(s_size_t > b_uintmax_t), (unsigned long long)(b_uintmax_t > s_size_t), (unsigned long long)(s_size_t >= b_uintmax_t), (unsigned long long)(b_uintmax_t >= s_size_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t << 1), (unsigned long long)(b_size_t >> 1), (unsigned long long)(b_uintmax_t << 1), (unsigned long long)(b_uintmax_t >> 1), (unsigned long long)(c ? b_size_t : b_uintmax_t), (unsigned long long)(c ? b_uintmax_t : b_size_t));
  { size_t t = b_size_t; t += s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t -= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t *= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t /= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t %= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t &= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t |= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t ^= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t += s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t -= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t *= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t /= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t %= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t &= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t |= s_size_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t ^= s_size_t; printf("%llu ", (unsigned long long)t); }
  printf("|size_t/uintmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_size_t), (unsigned long long)(b_size_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_size_t), (unsigned long long)(b_size_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_size_t), (unsigned long long)(b_size_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_size_t), (unsigned long long)(b_size_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_size_t), (unsigned long long)(b_size_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_size_t), (unsigned long long)(b_size_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_size_t), (unsigned long long)(b_size_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_size_t), (unsigned long long)(b_size_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_size_t), (unsigned long long)(b_size_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_size_t), (unsigned long long)(b_size_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_size_t), (unsigned long long)(s_size_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_size_t), (unsigned long long)(s_size_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_size_t), (unsigned long long)(s_size_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_size_t), (unsigned long long)(s_size_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_size_t), (unsigned long long)(s_size_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_size_t), (unsigned long long)(s_size_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_size_t), (unsigned long long)(s_size_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_size_t), (unsigned long long)(s_size_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_size_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_size_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_size_t), (unsigned long long)(s_size_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_size_t), (unsigned long long)(s_size_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_size_t), (unsigned long long)(s_size_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_size_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_size_t << 1), (unsigned long long)(b_size_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_size_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_size_t));
  { size_t t = b_size_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { size_t t = b_size_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|size_t/wchar_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t + s_intptr_t), (unsigned long long)(s_intptr_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_intptr_t), (unsigned long long)(s_intptr_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_intptr_t), (unsigned long long)(s_intptr_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_intptr_t), (unsigned long long)(s_intptr_t / b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t % s_intptr_t), (unsigned long long)(s_intptr_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_intptr_t), (unsigned long long)(s_intptr_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_intptr_t), (unsigned long long)(s_intptr_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_intptr_t), (unsigned long long)(s_intptr_t ^ b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t == s_intptr_t), (unsigned long long)(s_intptr_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_intptr_t), (unsigned long long)(s_intptr_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_intptr_t), (unsigned long long)(s_intptr_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_intptr_t), (unsigned long long)(s_intptr_t <= b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t > s_intptr_t), (unsigned long long)(s_intptr_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_intptr_t), (unsigned long long)(s_intptr_t >= b_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_intptr_t), (unsigned long long)(b_intptr_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_intptr_t), (unsigned long long)(b_intptr_t - s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t * b_intptr_t), (unsigned long long)(b_intptr_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_intptr_t), (unsigned long long)(b_intptr_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_intptr_t), (unsigned long long)(b_intptr_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_intptr_t), (unsigned long long)(b_intptr_t & s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t | b_intptr_t), (unsigned long long)(b_intptr_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_intptr_t), (unsigned long long)(b_intptr_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_intptr_t), (unsigned long long)(b_intptr_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_intptr_t), (unsigned long long)(b_intptr_t != s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t < b_intptr_t), (unsigned long long)(b_intptr_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_intptr_t), (unsigned long long)(b_intptr_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_intptr_t), (unsigned long long)(b_intptr_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_intptr_t), (unsigned long long)(b_intptr_t >= s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(b_intptr_t << 1), (unsigned long long)(b_intptr_t >> 1), (unsigned long long)(c ? b_ptrdiff_t : b_intptr_t), (unsigned long long)(c ? b_intptr_t : b_ptrdiff_t));
  { ptrdiff_t t = b_ptrdiff_t; t += s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t += s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t -= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t *= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t /= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t %= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t &= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t |= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t ^= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  printf("|ptrdiff_t/intptr_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t + s_uintptr_t), (unsigned long long)(s_uintptr_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_uintptr_t), (unsigned long long)(s_uintptr_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_uintptr_t), (unsigned long long)(s_uintptr_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_uintptr_t), (unsigned long long)(s_uintptr_t / b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t % s_uintptr_t), (unsigned long long)(s_uintptr_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_uintptr_t), (unsigned long long)(s_uintptr_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_uintptr_t), (unsigned long long)(s_uintptr_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_uintptr_t), (unsigned long long)(s_uintptr_t ^ b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t == s_uintptr_t), (unsigned long long)(s_uintptr_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_uintptr_t), (unsigned long long)(s_uintptr_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_uintptr_t), (unsigned long long)(s_uintptr_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_uintptr_t), (unsigned long long)(s_uintptr_t <= b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t > s_uintptr_t), (unsigned long long)(s_uintptr_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_uintptr_t), (unsigned long long)(s_uintptr_t >= b_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_uintptr_t), (unsigned long long)(b_uintptr_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_uintptr_t), (unsigned long long)(b_uintptr_t - s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t * b_uintptr_t), (unsigned long long)(b_uintptr_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_uintptr_t), (unsigned long long)(b_uintptr_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_uintptr_t), (unsigned long long)(b_uintptr_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_uintptr_t), (unsigned long long)(b_uintptr_t & s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t | b_uintptr_t), (unsigned long long)(b_uintptr_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_uintptr_t), (unsigned long long)(b_uintptr_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_uintptr_t), (unsigned long long)(b_uintptr_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_uintptr_t), (unsigned long long)(b_uintptr_t != s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t < b_uintptr_t), (unsigned long long)(b_uintptr_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_uintptr_t), (unsigned long long)(b_uintptr_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_uintptr_t), (unsigned long long)(b_uintptr_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_uintptr_t), (unsigned long long)(b_uintptr_t >= s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(b_uintptr_t << 1), (unsigned long long)(b_uintptr_t >> 1), (unsigned long long)(c ? b_ptrdiff_t : b_uintptr_t), (unsigned long long)(c ? b_uintptr_t : b_ptrdiff_t));
  { ptrdiff_t t = b_ptrdiff_t; t += s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t += s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t -= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t *= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t /= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t %= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t &= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t |= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t ^= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  printf("|ptrdiff_t/uintptr_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t + s_intmax_t), (unsigned long long)(s_intmax_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_intmax_t), (unsigned long long)(s_intmax_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_intmax_t), (unsigned long long)(s_intmax_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_intmax_t), (unsigned long long)(s_intmax_t / b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t % s_intmax_t), (unsigned long long)(s_intmax_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_intmax_t), (unsigned long long)(s_intmax_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_intmax_t), (unsigned long long)(s_intmax_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_intmax_t), (unsigned long long)(s_intmax_t ^ b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t == s_intmax_t), (unsigned long long)(s_intmax_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_intmax_t), (unsigned long long)(s_intmax_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_intmax_t), (unsigned long long)(s_intmax_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_intmax_t), (unsigned long long)(s_intmax_t <= b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t > s_intmax_t), (unsigned long long)(s_intmax_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_intmax_t), (unsigned long long)(s_intmax_t >= b_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_intmax_t), (unsigned long long)(b_intmax_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_intmax_t), (unsigned long long)(b_intmax_t - s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t * b_intmax_t), (unsigned long long)(b_intmax_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_intmax_t), (unsigned long long)(b_intmax_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_intmax_t), (unsigned long long)(b_intmax_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_intmax_t), (unsigned long long)(b_intmax_t & s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t | b_intmax_t), (unsigned long long)(b_intmax_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_intmax_t), (unsigned long long)(b_intmax_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_intmax_t), (unsigned long long)(b_intmax_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_intmax_t), (unsigned long long)(b_intmax_t != s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t < b_intmax_t), (unsigned long long)(b_intmax_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_intmax_t), (unsigned long long)(b_intmax_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_intmax_t), (unsigned long long)(b_intmax_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_intmax_t), (unsigned long long)(b_intmax_t >= s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(c ? b_ptrdiff_t : b_intmax_t), (unsigned long long)(c ? b_intmax_t : b_ptrdiff_t));
  { ptrdiff_t t = b_ptrdiff_t; t += s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t += s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  printf("|ptrdiff_t/intmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t + s_uintmax_t), (unsigned long long)(s_uintmax_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_uintmax_t), (unsigned long long)(s_uintmax_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_uintmax_t), (unsigned long long)(s_uintmax_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_uintmax_t), (unsigned long long)(s_uintmax_t / b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t % s_uintmax_t), (unsigned long long)(s_uintmax_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_uintmax_t), (unsigned long long)(s_uintmax_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_uintmax_t), (unsigned long long)(s_uintmax_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_uintmax_t), (unsigned long long)(s_uintmax_t ^ b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t == s_uintmax_t), (unsigned long long)(s_uintmax_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_uintmax_t), (unsigned long long)(s_uintmax_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_uintmax_t), (unsigned long long)(s_uintmax_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_uintmax_t), (unsigned long long)(s_uintmax_t <= b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t > s_uintmax_t), (unsigned long long)(s_uintmax_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_uintmax_t), (unsigned long long)(s_uintmax_t >= b_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_uintmax_t), (unsigned long long)(b_uintmax_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_uintmax_t), (unsigned long long)(b_uintmax_t - s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t * b_uintmax_t), (unsigned long long)(b_uintmax_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_uintmax_t), (unsigned long long)(b_uintmax_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_uintmax_t), (unsigned long long)(b_uintmax_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_uintmax_t), (unsigned long long)(b_uintmax_t & s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t | b_uintmax_t), (unsigned long long)(b_uintmax_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_uintmax_t), (unsigned long long)(b_uintmax_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_uintmax_t), (unsigned long long)(b_uintmax_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_uintmax_t), (unsigned long long)(b_uintmax_t != s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t < b_uintmax_t), (unsigned long long)(b_uintmax_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_uintmax_t), (unsigned long long)(b_uintmax_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_uintmax_t), (unsigned long long)(b_uintmax_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_uintmax_t), (unsigned long long)(b_uintmax_t >= s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(b_uintmax_t << 1), (unsigned long long)(b_uintmax_t >> 1), (unsigned long long)(c ? b_ptrdiff_t : b_uintmax_t), (unsigned long long)(c ? b_uintmax_t : b_ptrdiff_t));
  { ptrdiff_t t = b_ptrdiff_t; t += s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t += s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t -= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t *= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t /= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t %= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t &= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t |= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t ^= s_ptrdiff_t; printf("%llu ", (unsigned long long)t); }
  printf("|ptrdiff_t/uintmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_ptrdiff_t), (unsigned long long)(b_ptrdiff_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_ptrdiff_t), (unsigned long long)(s_ptrdiff_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_ptrdiff_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_ptrdiff_t), (unsigned long long)(s_ptrdiff_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_ptrdiff_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_ptrdiff_t << 1), (unsigned long long)(b_ptrdiff_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_ptrdiff_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_ptrdiff_t));
  { ptrdiff_t t = b_ptrdiff_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { ptrdiff_t t = b_ptrdiff_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|ptrdiff_t/wchar_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t + s_intmax_t), (unsigned long long)(s_intmax_t + b_intptr_t), (unsigned long long)(b_intptr_t - s_intmax_t), (unsigned long long)(s_intmax_t - b_intptr_t), (unsigned long long)(b_intptr_t * s_intmax_t), (unsigned long long)(s_intmax_t * b_intptr_t), (unsigned long long)(b_intptr_t / s_intmax_t), (unsigned long long)(s_intmax_t / b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t % s_intmax_t), (unsigned long long)(s_intmax_t % b_intptr_t), (unsigned long long)(b_intptr_t & s_intmax_t), (unsigned long long)(s_intmax_t & b_intptr_t), (unsigned long long)(b_intptr_t | s_intmax_t), (unsigned long long)(s_intmax_t | b_intptr_t), (unsigned long long)(b_intptr_t ^ s_intmax_t), (unsigned long long)(s_intmax_t ^ b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t == s_intmax_t), (unsigned long long)(s_intmax_t == b_intptr_t), (unsigned long long)(b_intptr_t != s_intmax_t), (unsigned long long)(s_intmax_t != b_intptr_t), (unsigned long long)(b_intptr_t < s_intmax_t), (unsigned long long)(s_intmax_t < b_intptr_t), (unsigned long long)(b_intptr_t <= s_intmax_t), (unsigned long long)(s_intmax_t <= b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t > s_intmax_t), (unsigned long long)(s_intmax_t > b_intptr_t), (unsigned long long)(b_intptr_t >= s_intmax_t), (unsigned long long)(s_intmax_t >= b_intptr_t), (unsigned long long)(s_intptr_t + b_intmax_t), (unsigned long long)(b_intmax_t + s_intptr_t), (unsigned long long)(s_intptr_t - b_intmax_t), (unsigned long long)(b_intmax_t - s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t * b_intmax_t), (unsigned long long)(b_intmax_t * s_intptr_t), (unsigned long long)(s_intptr_t / b_intmax_t), (unsigned long long)(b_intmax_t / s_intptr_t), (unsigned long long)(s_intptr_t % b_intmax_t), (unsigned long long)(b_intmax_t % s_intptr_t), (unsigned long long)(s_intptr_t & b_intmax_t), (unsigned long long)(b_intmax_t & s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t | b_intmax_t), (unsigned long long)(b_intmax_t | s_intptr_t), (unsigned long long)(s_intptr_t ^ b_intmax_t), (unsigned long long)(b_intmax_t ^ s_intptr_t), (unsigned long long)(s_intptr_t == b_intmax_t), (unsigned long long)(b_intmax_t == s_intptr_t), (unsigned long long)(s_intptr_t != b_intmax_t), (unsigned long long)(b_intmax_t != s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t < b_intmax_t), (unsigned long long)(b_intmax_t < s_intptr_t), (unsigned long long)(s_intptr_t <= b_intmax_t), (unsigned long long)(b_intmax_t <= s_intptr_t), (unsigned long long)(s_intptr_t > b_intmax_t), (unsigned long long)(b_intmax_t > s_intptr_t), (unsigned long long)(s_intptr_t >= b_intmax_t), (unsigned long long)(b_intmax_t >= s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t << 1), (unsigned long long)(b_intptr_t >> 1), (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(c ? b_intptr_t : b_intmax_t), (unsigned long long)(c ? b_intmax_t : b_intptr_t));
  { intptr_t t = b_intptr_t; t += s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t -= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t *= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t /= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t %= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t &= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t |= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t ^= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t += s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_intptr_t; printf("%llu ", (unsigned long long)t); }
  printf("|intptr_t/intmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_intptr_t), (unsigned long long)(b_intptr_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_intptr_t), (unsigned long long)(b_intptr_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_intptr_t), (unsigned long long)(b_intptr_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_intptr_t), (unsigned long long)(b_intptr_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_intptr_t), (unsigned long long)(b_intptr_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_intptr_t), (unsigned long long)(b_intptr_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_intptr_t), (unsigned long long)(b_intptr_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_intptr_t), (unsigned long long)(b_intptr_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_intptr_t), (unsigned long long)(b_intptr_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_intptr_t), (unsigned long long)(b_intptr_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_intptr_t), (unsigned long long)(s_intptr_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_intptr_t), (unsigned long long)(s_intptr_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_intptr_t), (unsigned long long)(s_intptr_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_intptr_t), (unsigned long long)(s_intptr_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_intptr_t), (unsigned long long)(s_intptr_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_intptr_t), (unsigned long long)(s_intptr_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_intptr_t), (unsigned long long)(s_intptr_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_intptr_t), (unsigned long long)(s_intptr_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intptr_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_intptr_t), (unsigned long long)(s_intptr_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_intptr_t), (unsigned long long)(s_intptr_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_intptr_t), (unsigned long long)(s_intptr_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_intptr_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intptr_t << 1), (unsigned long long)(b_intptr_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_intptr_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_intptr_t));
  { intptr_t t = b_intptr_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intptr_t t = b_intptr_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|intptr_t/wchar_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t + s_intmax_t), (unsigned long long)(s_intmax_t + b_uintptr_t), (unsigned long long)(b_uintptr_t - s_intmax_t), (unsigned long long)(s_intmax_t - b_uintptr_t), (unsigned long long)(b_uintptr_t * s_intmax_t), (unsigned long long)(s_intmax_t * b_uintptr_t), (unsigned long long)(b_uintptr_t / s_intmax_t), (unsigned long long)(s_intmax_t / b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t % s_intmax_t), (unsigned long long)(s_intmax_t % b_uintptr_t), (unsigned long long)(b_uintptr_t & s_intmax_t), (unsigned long long)(s_intmax_t & b_uintptr_t), (unsigned long long)(b_uintptr_t | s_intmax_t), (unsigned long long)(s_intmax_t | b_uintptr_t), (unsigned long long)(b_uintptr_t ^ s_intmax_t), (unsigned long long)(s_intmax_t ^ b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t == s_intmax_t), (unsigned long long)(s_intmax_t == b_uintptr_t), (unsigned long long)(b_uintptr_t != s_intmax_t), (unsigned long long)(s_intmax_t != b_uintptr_t), (unsigned long long)(b_uintptr_t < s_intmax_t), (unsigned long long)(s_intmax_t < b_uintptr_t), (unsigned long long)(b_uintptr_t <= s_intmax_t), (unsigned long long)(s_intmax_t <= b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t > s_intmax_t), (unsigned long long)(s_intmax_t > b_uintptr_t), (unsigned long long)(b_uintptr_t >= s_intmax_t), (unsigned long long)(s_intmax_t >= b_uintptr_t), (unsigned long long)(s_uintptr_t + b_intmax_t), (unsigned long long)(b_intmax_t + s_uintptr_t), (unsigned long long)(s_uintptr_t - b_intmax_t), (unsigned long long)(b_intmax_t - s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t * b_intmax_t), (unsigned long long)(b_intmax_t * s_uintptr_t), (unsigned long long)(s_uintptr_t / b_intmax_t), (unsigned long long)(b_intmax_t / s_uintptr_t), (unsigned long long)(s_uintptr_t % b_intmax_t), (unsigned long long)(b_intmax_t % s_uintptr_t), (unsigned long long)(s_uintptr_t & b_intmax_t), (unsigned long long)(b_intmax_t & s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t | b_intmax_t), (unsigned long long)(b_intmax_t | s_uintptr_t), (unsigned long long)(s_uintptr_t ^ b_intmax_t), (unsigned long long)(b_intmax_t ^ s_uintptr_t), (unsigned long long)(s_uintptr_t == b_intmax_t), (unsigned long long)(b_intmax_t == s_uintptr_t), (unsigned long long)(s_uintptr_t != b_intmax_t), (unsigned long long)(b_intmax_t != s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t < b_intmax_t), (unsigned long long)(b_intmax_t < s_uintptr_t), (unsigned long long)(s_uintptr_t <= b_intmax_t), (unsigned long long)(b_intmax_t <= s_uintptr_t), (unsigned long long)(s_uintptr_t > b_intmax_t), (unsigned long long)(b_intmax_t > s_uintptr_t), (unsigned long long)(s_uintptr_t >= b_intmax_t), (unsigned long long)(b_intmax_t >= s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t << 1), (unsigned long long)(b_uintptr_t >> 1), (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(c ? b_uintptr_t : b_intmax_t), (unsigned long long)(c ? b_intmax_t : b_uintptr_t));
  { uintptr_t t = b_uintptr_t; t += s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t -= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t *= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t /= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t %= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t &= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t |= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t ^= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t += s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  printf("|uintptr_t/intmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t + s_uintmax_t), (unsigned long long)(s_uintmax_t + b_uintptr_t), (unsigned long long)(b_uintptr_t - s_uintmax_t), (unsigned long long)(s_uintmax_t - b_uintptr_t), (unsigned long long)(b_uintptr_t * s_uintmax_t), (unsigned long long)(s_uintmax_t * b_uintptr_t), (unsigned long long)(b_uintptr_t / s_uintmax_t), (unsigned long long)(s_uintmax_t / b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t % s_uintmax_t), (unsigned long long)(s_uintmax_t % b_uintptr_t), (unsigned long long)(b_uintptr_t & s_uintmax_t), (unsigned long long)(s_uintmax_t & b_uintptr_t), (unsigned long long)(b_uintptr_t | s_uintmax_t), (unsigned long long)(s_uintmax_t | b_uintptr_t), (unsigned long long)(b_uintptr_t ^ s_uintmax_t), (unsigned long long)(s_uintmax_t ^ b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t == s_uintmax_t), (unsigned long long)(s_uintmax_t == b_uintptr_t), (unsigned long long)(b_uintptr_t != s_uintmax_t), (unsigned long long)(s_uintmax_t != b_uintptr_t), (unsigned long long)(b_uintptr_t < s_uintmax_t), (unsigned long long)(s_uintmax_t < b_uintptr_t), (unsigned long long)(b_uintptr_t <= s_uintmax_t), (unsigned long long)(s_uintmax_t <= b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t > s_uintmax_t), (unsigned long long)(s_uintmax_t > b_uintptr_t), (unsigned long long)(b_uintptr_t >= s_uintmax_t), (unsigned long long)(s_uintmax_t >= b_uintptr_t), (unsigned long long)(s_uintptr_t + b_uintmax_t), (unsigned long long)(b_uintmax_t + s_uintptr_t), (unsigned long long)(s_uintptr_t - b_uintmax_t), (unsigned long long)(b_uintmax_t - s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t * b_uintmax_t), (unsigned long long)(b_uintmax_t * s_uintptr_t), (unsigned long long)(s_uintptr_t / b_uintmax_t), (unsigned long long)(b_uintmax_t / s_uintptr_t), (unsigned long long)(s_uintptr_t % b_uintmax_t), (unsigned long long)(b_uintmax_t % s_uintptr_t), (unsigned long long)(s_uintptr_t & b_uintmax_t), (unsigned long long)(b_uintmax_t & s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t | b_uintmax_t), (unsigned long long)(b_uintmax_t | s_uintptr_t), (unsigned long long)(s_uintptr_t ^ b_uintmax_t), (unsigned long long)(b_uintmax_t ^ s_uintptr_t), (unsigned long long)(s_uintptr_t == b_uintmax_t), (unsigned long long)(b_uintmax_t == s_uintptr_t), (unsigned long long)(s_uintptr_t != b_uintmax_t), (unsigned long long)(b_uintmax_t != s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t < b_uintmax_t), (unsigned long long)(b_uintmax_t < s_uintptr_t), (unsigned long long)(s_uintptr_t <= b_uintmax_t), (unsigned long long)(b_uintmax_t <= s_uintptr_t), (unsigned long long)(s_uintptr_t > b_uintmax_t), (unsigned long long)(b_uintmax_t > s_uintptr_t), (unsigned long long)(s_uintptr_t >= b_uintmax_t), (unsigned long long)(b_uintmax_t >= s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t << 1), (unsigned long long)(b_uintptr_t >> 1), (unsigned long long)(b_uintmax_t << 1), (unsigned long long)(b_uintmax_t >> 1), (unsigned long long)(c ? b_uintptr_t : b_uintmax_t), (unsigned long long)(c ? b_uintmax_t : b_uintptr_t));
  { uintptr_t t = b_uintptr_t; t += s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t -= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t *= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t /= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t %= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t &= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t |= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t ^= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t += s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t -= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t *= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t /= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t %= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t &= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t |= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t ^= s_uintptr_t; printf("%llu ", (unsigned long long)t); }
  printf("|uintptr_t/uintmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_uintptr_t), (unsigned long long)(b_uintptr_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_uintptr_t), (unsigned long long)(b_uintptr_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_uintptr_t), (unsigned long long)(b_uintptr_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_uintptr_t), (unsigned long long)(b_uintptr_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_uintptr_t), (unsigned long long)(b_uintptr_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_uintptr_t), (unsigned long long)(b_uintptr_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_uintptr_t), (unsigned long long)(b_uintptr_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_uintptr_t), (unsigned long long)(b_uintptr_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_uintptr_t), (unsigned long long)(b_uintptr_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_uintptr_t), (unsigned long long)(b_uintptr_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_uintptr_t), (unsigned long long)(s_uintptr_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_uintptr_t), (unsigned long long)(s_uintptr_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_uintptr_t), (unsigned long long)(s_uintptr_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_uintptr_t), (unsigned long long)(s_uintptr_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_uintptr_t), (unsigned long long)(s_uintptr_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_uintptr_t), (unsigned long long)(s_uintptr_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_uintptr_t), (unsigned long long)(s_uintptr_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_uintptr_t), (unsigned long long)(s_uintptr_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintptr_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_uintptr_t), (unsigned long long)(s_uintptr_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_uintptr_t), (unsigned long long)(s_uintptr_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_uintptr_t), (unsigned long long)(s_uintptr_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_uintptr_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintptr_t << 1), (unsigned long long)(b_uintptr_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_uintptr_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_uintptr_t));
  { uintptr_t t = b_uintptr_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintptr_t t = b_uintptr_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|uintptr_t/wchar_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t + s_uintmax_t), (unsigned long long)(s_uintmax_t + b_intmax_t), (unsigned long long)(b_intmax_t - s_uintmax_t), (unsigned long long)(s_uintmax_t - b_intmax_t), (unsigned long long)(b_intmax_t * s_uintmax_t), (unsigned long long)(s_uintmax_t * b_intmax_t), (unsigned long long)(b_intmax_t / s_uintmax_t), (unsigned long long)(s_uintmax_t / b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t % s_uintmax_t), (unsigned long long)(s_uintmax_t % b_intmax_t), (unsigned long long)(b_intmax_t & s_uintmax_t), (unsigned long long)(s_uintmax_t & b_intmax_t), (unsigned long long)(b_intmax_t | s_uintmax_t), (unsigned long long)(s_uintmax_t | b_intmax_t), (unsigned long long)(b_intmax_t ^ s_uintmax_t), (unsigned long long)(s_uintmax_t ^ b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t == s_uintmax_t), (unsigned long long)(s_uintmax_t == b_intmax_t), (unsigned long long)(b_intmax_t != s_uintmax_t), (unsigned long long)(s_uintmax_t != b_intmax_t), (unsigned long long)(b_intmax_t < s_uintmax_t), (unsigned long long)(s_uintmax_t < b_intmax_t), (unsigned long long)(b_intmax_t <= s_uintmax_t), (unsigned long long)(s_uintmax_t <= b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t > s_uintmax_t), (unsigned long long)(s_uintmax_t > b_intmax_t), (unsigned long long)(b_intmax_t >= s_uintmax_t), (unsigned long long)(s_uintmax_t >= b_intmax_t), (unsigned long long)(s_intmax_t + b_uintmax_t), (unsigned long long)(b_uintmax_t + s_intmax_t), (unsigned long long)(s_intmax_t - b_uintmax_t), (unsigned long long)(b_uintmax_t - s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t * b_uintmax_t), (unsigned long long)(b_uintmax_t * s_intmax_t), (unsigned long long)(s_intmax_t / b_uintmax_t), (unsigned long long)(b_uintmax_t / s_intmax_t), (unsigned long long)(s_intmax_t % b_uintmax_t), (unsigned long long)(b_uintmax_t % s_intmax_t), (unsigned long long)(s_intmax_t & b_uintmax_t), (unsigned long long)(b_uintmax_t & s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t | b_uintmax_t), (unsigned long long)(b_uintmax_t | s_intmax_t), (unsigned long long)(s_intmax_t ^ b_uintmax_t), (unsigned long long)(b_uintmax_t ^ s_intmax_t), (unsigned long long)(s_intmax_t == b_uintmax_t), (unsigned long long)(b_uintmax_t == s_intmax_t), (unsigned long long)(s_intmax_t != b_uintmax_t), (unsigned long long)(b_uintmax_t != s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t < b_uintmax_t), (unsigned long long)(b_uintmax_t < s_intmax_t), (unsigned long long)(s_intmax_t <= b_uintmax_t), (unsigned long long)(b_uintmax_t <= s_intmax_t), (unsigned long long)(s_intmax_t > b_uintmax_t), (unsigned long long)(b_uintmax_t > s_intmax_t), (unsigned long long)(s_intmax_t >= b_uintmax_t), (unsigned long long)(b_uintmax_t >= s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(b_uintmax_t << 1), (unsigned long long)(b_uintmax_t >> 1), (unsigned long long)(c ? b_intmax_t : b_uintmax_t), (unsigned long long)(c ? b_uintmax_t : b_intmax_t));
  { intmax_t t = b_intmax_t; t += s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_uintmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t += s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t -= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t *= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t /= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t %= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t &= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t |= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t ^= s_intmax_t; printf("%llu ", (unsigned long long)t); }
  printf("|intmax_t/uintmax_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_intmax_t), (unsigned long long)(b_intmax_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_intmax_t), (unsigned long long)(b_intmax_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_intmax_t), (unsigned long long)(b_intmax_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_intmax_t), (unsigned long long)(b_intmax_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_intmax_t), (unsigned long long)(b_intmax_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_intmax_t), (unsigned long long)(b_intmax_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_intmax_t), (unsigned long long)(b_intmax_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_intmax_t), (unsigned long long)(b_intmax_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_intmax_t), (unsigned long long)(b_intmax_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_intmax_t), (unsigned long long)(b_intmax_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_intmax_t), (unsigned long long)(s_intmax_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_intmax_t), (unsigned long long)(s_intmax_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_intmax_t), (unsigned long long)(s_intmax_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_intmax_t), (unsigned long long)(s_intmax_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_intmax_t), (unsigned long long)(s_intmax_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_intmax_t), (unsigned long long)(s_intmax_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_intmax_t), (unsigned long long)(s_intmax_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_intmax_t), (unsigned long long)(s_intmax_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_intmax_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_intmax_t), (unsigned long long)(s_intmax_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_intmax_t), (unsigned long long)(s_intmax_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_intmax_t), (unsigned long long)(s_intmax_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_intmax_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_intmax_t << 1), (unsigned long long)(b_intmax_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_intmax_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_intmax_t));
  { intmax_t t = b_intmax_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { intmax_t t = b_intmax_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|intmax_t/wchar_t ");
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintmax_t + s_wchar_t), (unsigned long long)(s_wchar_t + b_uintmax_t), (unsigned long long)(b_uintmax_t - s_wchar_t), (unsigned long long)(s_wchar_t - b_uintmax_t), (unsigned long long)(b_uintmax_t * s_wchar_t), (unsigned long long)(s_wchar_t * b_uintmax_t), (unsigned long long)(b_uintmax_t / s_wchar_t), (unsigned long long)(s_wchar_t / b_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintmax_t % s_wchar_t), (unsigned long long)(s_wchar_t % b_uintmax_t), (unsigned long long)(b_uintmax_t & s_wchar_t), (unsigned long long)(s_wchar_t & b_uintmax_t), (unsigned long long)(b_uintmax_t | s_wchar_t), (unsigned long long)(s_wchar_t | b_uintmax_t), (unsigned long long)(b_uintmax_t ^ s_wchar_t), (unsigned long long)(s_wchar_t ^ b_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintmax_t == s_wchar_t), (unsigned long long)(s_wchar_t == b_uintmax_t), (unsigned long long)(b_uintmax_t != s_wchar_t), (unsigned long long)(s_wchar_t != b_uintmax_t), (unsigned long long)(b_uintmax_t < s_wchar_t), (unsigned long long)(s_wchar_t < b_uintmax_t), (unsigned long long)(b_uintmax_t <= s_wchar_t), (unsigned long long)(s_wchar_t <= b_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintmax_t > s_wchar_t), (unsigned long long)(s_wchar_t > b_uintmax_t), (unsigned long long)(b_uintmax_t >= s_wchar_t), (unsigned long long)(s_wchar_t >= b_uintmax_t), (unsigned long long)(s_uintmax_t + b_wchar_t), (unsigned long long)(b_wchar_t + s_uintmax_t), (unsigned long long)(s_uintmax_t - b_wchar_t), (unsigned long long)(b_wchar_t - s_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintmax_t * b_wchar_t), (unsigned long long)(b_wchar_t * s_uintmax_t), (unsigned long long)(s_uintmax_t / b_wchar_t), (unsigned long long)(b_wchar_t / s_uintmax_t), (unsigned long long)(s_uintmax_t % b_wchar_t), (unsigned long long)(b_wchar_t % s_uintmax_t), (unsigned long long)(s_uintmax_t & b_wchar_t), (unsigned long long)(b_wchar_t & s_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintmax_t | b_wchar_t), (unsigned long long)(b_wchar_t | s_uintmax_t), (unsigned long long)(s_uintmax_t ^ b_wchar_t), (unsigned long long)(b_wchar_t ^ s_uintmax_t), (unsigned long long)(s_uintmax_t == b_wchar_t), (unsigned long long)(b_wchar_t == s_uintmax_t), (unsigned long long)(s_uintmax_t != b_wchar_t), (unsigned long long)(b_wchar_t != s_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu %llu %llu ", (unsigned long long)(s_uintmax_t < b_wchar_t), (unsigned long long)(b_wchar_t < s_uintmax_t), (unsigned long long)(s_uintmax_t <= b_wchar_t), (unsigned long long)(b_wchar_t <= s_uintmax_t), (unsigned long long)(s_uintmax_t > b_wchar_t), (unsigned long long)(b_wchar_t > s_uintmax_t), (unsigned long long)(s_uintmax_t >= b_wchar_t), (unsigned long long)(b_wchar_t >= s_uintmax_t));
  printf("%llu %llu %llu %llu %llu %llu ", (unsigned long long)(b_uintmax_t << 1), (unsigned long long)(b_uintmax_t >> 1), (unsigned long long)(b_wchar_t << 1), (unsigned long long)(b_wchar_t >> 1), (unsigned long long)(c ? b_uintmax_t : b_wchar_t), (unsigned long long)(c ? b_wchar_t : b_uintmax_t));
  { uintmax_t t = b_uintmax_t; t += s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t -= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t *= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t /= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t %= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t &= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t |= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  { uintmax_t t = b_uintmax_t; t ^= s_wchar_t; printf("%llu ", (unsigned long long)t); }
  printf("|uintmax_t/wchar_t ");
  printf("\n"); return 0;
}
