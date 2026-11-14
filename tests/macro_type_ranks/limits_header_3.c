// gcc 13's line on both engines: the limit macros of the shipped <limits.h>/<stdint.h> other than WCHAR_*/WINT_*: compared with 0, promoted, converted, and against int, unsigned, long, unsigned long at -1
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#ifndef __cerb__
// gcc is given the shipped <stdint.h>'s own (FIXED_STDINT) definitions of the exact-width limits: glibc types int64_t as long, the shipped header as long long
#undef UINT16_MAX
#define UINT16_MAX USHRT_MAX
#undef UINT32_MAX
#define UINT32_MAX UINT_MAX
#endif
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  { unsigned p = -1; unsigned t = p; t |= INTPTR_MIN; P(t); }
  { long p = -1; P(INTPTR_MIN < p); }
  { long p = -1; P(INTPTR_MIN > p); }
  { long p = -1; P(INTPTR_MIN == p); }
  { long p = -1; P(INTPTR_MIN != p); }
  { long p = -1; P(INTPTR_MIN <= p); }
  { long p = -1; P(INTPTR_MIN >= p); }
  { long p = -1; P(p < INTPTR_MIN); }
  { long p = -1; P(p > INTPTR_MIN); }
  { long p = -1; P(p == INTPTR_MIN); }
  { long p = -1; P(p <= INTPTR_MIN); }
  { long p = -1; P(INTPTR_MIN - p); }
  { long p = -1; P(p - INTPTR_MIN); }
  { long p = -1; P(INTPTR_MIN & p); }
  { long p = -1; P(INTPTR_MIN | p); }
  { long p = -1; P(INTPTR_MIN ^ p); }
  { long p = -1; P(p & INTPTR_MIN); }
  { long p = -1; P(p | INTPTR_MIN); }
  { long p = -1; P(1 ? INTPTR_MIN : p); }
  { long p = -1; P(1 ? p : INTPTR_MIN); }
  { long p = -1; P(0 ? INTPTR_MIN : p); }
  { long p = -1; P(TC(INTPTR_MIN + p)); }
  { long p = -1; P(TC(p + INTPTR_MIN)); }
  { long p = -1; P(TC(1 ? INTPTR_MIN : p)); }
  { long p = -1; P(sizeof(INTPTR_MIN + p)); }
  { long p = -1; long t = p; t -= INTPTR_MIN; P(t); }
  { long p = -1; long t = p; t &= INTPTR_MIN; P(t); }
  { long p = -1; long t = p; t |= INTPTR_MIN; P(t); }
  { unsigned long p = -1; P(INTPTR_MIN < p); }
  { unsigned long p = -1; P(INTPTR_MIN > p); }
  { unsigned long p = -1; P(INTPTR_MIN == p); }
  { unsigned long p = -1; P(INTPTR_MIN != p); }
  { unsigned long p = -1; P(INTPTR_MIN <= p); }
  { unsigned long p = -1; P(INTPTR_MIN >= p); }
  { unsigned long p = -1; P(p < INTPTR_MIN); }
  { unsigned long p = -1; P(p > INTPTR_MIN); }
  { unsigned long p = -1; P(p == INTPTR_MIN); }
  { unsigned long p = -1; P(p <= INTPTR_MIN); }
  { unsigned long p = -1; P(INTPTR_MIN - p); }
  { unsigned long p = -1; P(p - INTPTR_MIN); }
  { unsigned long p = -1; P(INTPTR_MIN & p); }
  { unsigned long p = -1; P(INTPTR_MIN | p); }
  { unsigned long p = -1; P(INTPTR_MIN ^ p); }
  { unsigned long p = -1; P(p & INTPTR_MIN); }
  { unsigned long p = -1; P(p | INTPTR_MIN); }
  { unsigned long p = -1; P(1 ? INTPTR_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INTPTR_MIN); }
  { unsigned long p = -1; P(0 ? INTPTR_MIN : p); }
  { unsigned long p = -1; P(sizeof(INTPTR_MIN + p)); }
  { unsigned long p = -1; P(INTPTR_MIN / p); }
  { unsigned long p = -1; P(INTPTR_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t -= INTPTR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INTPTR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INTPTR_MIN; P(t); }
  P(LONG_MAX > 0);
  P(LONG_MAX < 0);
  P(LONG_MAX == 0);
  P(LONG_MAX != 0);
  P(LONG_MAX >= 0);
  P(LONG_MAX <= 0);
  P(0 < LONG_MAX);
  P(0 > LONG_MAX);
  P(0 == LONG_MAX);
  P(+LONG_MAX);
  P(-LONG_MAX);
  P(~LONG_MAX);
  P(!LONG_MAX);
  P((+LONG_MAX) > 0);
  P(sizeof(LONG_MAX));
  P(sizeof(+LONG_MAX));
  P(TC(LONG_MAX));
  P(TC(+LONG_MAX));
  P(TC(-LONG_MAX));
  P(TC(~LONG_MAX));
  P((_Bool)LONG_MAX);
  P((signed char)LONG_MAX);
  P((unsigned char)LONG_MAX);
  P((short)LONG_MAX);
  P((unsigned short)LONG_MAX);
  P((int)LONG_MAX);
  P((unsigned)LONG_MAX);
  P((long)LONG_MAX);
  P((unsigned long)LONG_MAX);
  P((long long)LONG_MAX);
  P((unsigned long long)LONG_MAX);
  P((long long)LONG_MAX > 0);
  P((long long)LONG_MAX < 0);
  { int x = LONG_MAX; P(x); }
  { unsigned x = LONG_MAX; P(x); }
  { long x = LONG_MAX; P(x); }
  { unsigned long x = LONG_MAX; P(x); }
  P(LONG_MAX - 1);
  P(LONG_MAX - 1 > 0);
  P(LONG_MAX - 1u);
  P(LONG_MAX - 1ul);
  { int p = -1; P(LONG_MAX < p); }
  { int p = -1; P(LONG_MAX > p); }
  { int p = -1; P(LONG_MAX == p); }
  { int p = -1; P(LONG_MAX != p); }
  { int p = -1; P(LONG_MAX <= p); }
  { int p = -1; P(LONG_MAX >= p); }
  { int p = -1; P(p < LONG_MAX); }
  { int p = -1; P(p > LONG_MAX); }
  { int p = -1; P(p == LONG_MAX); }
  { int p = -1; P(p <= LONG_MAX); }
  { int p = -1; P(LONG_MAX + p); }
  { int p = -1; P(p + LONG_MAX); }
  { int p = -1; P(p - LONG_MAX); }
  { int p = -1; P(LONG_MAX * p); }
  { int p = -1; P(p * LONG_MAX); }
  { int p = -1; P(LONG_MAX & p); }
  { int p = -1; P(LONG_MAX | p); }
  { int p = -1; P(LONG_MAX ^ p); }
  { int p = -1; P(p & LONG_MAX); }
  { int p = -1; P(p | LONG_MAX); }
  { int p = -1; P(1 ? LONG_MAX : p); }
  { int p = -1; P(1 ? p : LONG_MAX); }
  { int p = -1; P(0 ? LONG_MAX : p); }
  { int p = -1; P(TC(LONG_MAX + p)); }
  { int p = -1; P(TC(p + LONG_MAX)); }
  { int p = -1; P(TC(1 ? LONG_MAX : p)); }
  { int p = -1; P(sizeof(LONG_MAX + p)); }
  { int p = -1; int t = p; t += LONG_MAX; P(t); }
  { int p = -1; int t = p; t -= LONG_MAX; P(t); }
  { int p = -1; int t = p; t &= LONG_MAX; P(t); }
  { int p = -1; int t = p; t |= LONG_MAX; P(t); }
  { unsigned p = -1; P(LONG_MAX < p); }
  { unsigned p = -1; P(LONG_MAX > p); }
  { unsigned p = -1; P(LONG_MAX == p); }
  { unsigned p = -1; P(LONG_MAX != p); }
  { unsigned p = -1; P(LONG_MAX <= p); }
  { unsigned p = -1; P(LONG_MAX >= p); }
  { unsigned p = -1; P(p < LONG_MAX); }
  { unsigned p = -1; P(p > LONG_MAX); }
  { unsigned p = -1; P(p == LONG_MAX); }
  { unsigned p = -1; P(p <= LONG_MAX); }
  { unsigned p = -1; P(LONG_MAX - p); }
  { unsigned p = -1; P(p - LONG_MAX); }
  { unsigned p = -1; P(LONG_MAX & p); }
  { unsigned p = -1; P(LONG_MAX | p); }
  { unsigned p = -1; P(LONG_MAX ^ p); }
  { unsigned p = -1; P(p & LONG_MAX); }
  { unsigned p = -1; P(p | LONG_MAX); }
  { unsigned p = -1; P(1 ? LONG_MAX : p); }
  { unsigned p = -1; P(1 ? p : LONG_MAX); }
  { unsigned p = -1; P(0 ? LONG_MAX : p); }
  { unsigned p = -1; P(TC(LONG_MAX + p)); }
  { unsigned p = -1; P(TC(p + LONG_MAX)); }
  { unsigned p = -1; P(TC(1 ? LONG_MAX : p)); }
  { unsigned p = -1; P(sizeof(LONG_MAX + p)); }
  { unsigned p = -1; P(LONG_MAX / p); }
  { unsigned p = -1; P(LONG_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= LONG_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= LONG_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= LONG_MAX; P(t); }
  { long p = -1; P(LONG_MAX < p); }
  { long p = -1; P(LONG_MAX > p); }
  { long p = -1; P(LONG_MAX == p); }
  { long p = -1; P(LONG_MAX != p); }
  { long p = -1; P(LONG_MAX <= p); }
  { long p = -1; P(LONG_MAX >= p); }
  { long p = -1; P(p < LONG_MAX); }
  { long p = -1; P(p > LONG_MAX); }
  { long p = -1; P(p == LONG_MAX); }
  { long p = -1; P(p <= LONG_MAX); }
  { long p = -1; P(LONG_MAX + p); }
  { long p = -1; P(p + LONG_MAX); }
  { long p = -1; P(p - LONG_MAX); }
  { long p = -1; P(LONG_MAX * p); }
  { long p = -1; P(p * LONG_MAX); }
  { long p = -1; P(LONG_MAX & p); }
  { long p = -1; P(LONG_MAX | p); }
  { long p = -1; P(LONG_MAX ^ p); }
  { long p = -1; P(p & LONG_MAX); }
  { long p = -1; P(p | LONG_MAX); }
  { long p = -1; P(1 ? LONG_MAX : p); }
  { long p = -1; P(1 ? p : LONG_MAX); }
  { long p = -1; P(0 ? LONG_MAX : p); }
  { long p = -1; P(TC(LONG_MAX + p)); }
  { long p = -1; P(TC(p + LONG_MAX)); }
  { long p = -1; P(TC(1 ? LONG_MAX : p)); }
  { long p = -1; P(sizeof(LONG_MAX + p)); }
  { long p = -1; long t = p; t += LONG_MAX; P(t); }
  { long p = -1; long t = p; t -= LONG_MAX; P(t); }
  { long p = -1; long t = p; t &= LONG_MAX; P(t); }
  { long p = -1; long t = p; t |= LONG_MAX; P(t); }
  { unsigned long p = -1; P(LONG_MAX < p); }
  { unsigned long p = -1; P(LONG_MAX > p); }
  { unsigned long p = -1; P(LONG_MAX == p); }
  { unsigned long p = -1; P(LONG_MAX != p); }
  { unsigned long p = -1; P(LONG_MAX <= p); }
  { unsigned long p = -1; P(LONG_MAX >= p); }
  { unsigned long p = -1; P(p < LONG_MAX); }
  { unsigned long p = -1; P(p > LONG_MAX); }
  { unsigned long p = -1; P(p == LONG_MAX); }
  { unsigned long p = -1; P(p <= LONG_MAX); }
  { unsigned long p = -1; P(LONG_MAX + p); }
  { unsigned long p = -1; P(p + LONG_MAX); }
  { unsigned long p = -1; P(LONG_MAX - p); }
  { unsigned long p = -1; P(p - LONG_MAX); }
  { unsigned long p = -1; P(LONG_MAX * p); }
  { unsigned long p = -1; P(p * LONG_MAX); }
  { unsigned long p = -1; P(LONG_MAX & p); }
  { unsigned long p = -1; P(LONG_MAX | p); }
  { unsigned long p = -1; P(LONG_MAX ^ p); }
  { unsigned long p = -1; P(p & LONG_MAX); }
  { unsigned long p = -1; P(p | LONG_MAX); }
  { unsigned long p = -1; P(1 ? LONG_MAX : p); }
  { unsigned long p = -1; P(1 ? p : LONG_MAX); }
  { unsigned long p = -1; P(0 ? LONG_MAX : p); }
  { unsigned long p = -1; P(TC(LONG_MAX + p)); }
  { unsigned long p = -1; P(TC(p + LONG_MAX)); }
  { unsigned long p = -1; P(TC(1 ? LONG_MAX : p)); }
  { unsigned long p = -1; P(sizeof(LONG_MAX + p)); }
  { unsigned long p = -1; P(LONG_MAX / p); }
  { unsigned long p = -1; P(LONG_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += LONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= LONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= LONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= LONG_MAX; P(t); }
  P(LONG_MIN > 0);
  P(LONG_MIN < 0);
  P(LONG_MIN == 0);
  P(LONG_MIN != 0);
  P(LONG_MIN >= 0);
  P(LONG_MIN <= 0);
  P(0 < LONG_MIN);
  P(0 > LONG_MIN);
  P(0 == LONG_MIN);
  P(+LONG_MIN);
  P(~LONG_MIN);
  P(!LONG_MIN);
  P((+LONG_MIN) > 0);
  P(sizeof(LONG_MIN));
  P(sizeof(+LONG_MIN));
  P(TC(LONG_MIN));
  P(TC(+LONG_MIN));
  P(TC(-LONG_MIN));
  P(TC(~LONG_MIN));
  P((_Bool)LONG_MIN);
  P((signed char)LONG_MIN);
  P((unsigned char)LONG_MIN);
  P((short)LONG_MIN);
  P((unsigned short)LONG_MIN);
  P((int)LONG_MIN);
  P((unsigned)LONG_MIN);
  P((long)LONG_MIN);
  P((unsigned long)LONG_MIN);
  P((long long)LONG_MIN);
  P((unsigned long long)LONG_MIN);
  P((long long)LONG_MIN > 0);
  P((long long)LONG_MIN < 0);
  { int x = LONG_MIN; P(x); }
  { unsigned x = LONG_MIN; P(x); }
  { long x = LONG_MIN; P(x); }
  { unsigned long x = LONG_MIN; P(x); }
  P(LONG_MIN + 1);
  P(LONG_MIN + 1 > 0);
  P(LONG_MIN + 1u);
  P(LONG_MIN + 1l);
  P(LONG_MIN - 1ul);
  { int p = -1; P(LONG_MIN < p); }
  { int p = -1; P(LONG_MIN > p); }
  { int p = -1; P(LONG_MIN == p); }
  { int p = -1; P(LONG_MIN != p); }
  { int p = -1; P(LONG_MIN <= p); }
  { int p = -1; P(LONG_MIN >= p); }
  { int p = -1; P(p < LONG_MIN); }
  { int p = -1; P(p > LONG_MIN); }
  { int p = -1; P(p == LONG_MIN); }
  { int p = -1; P(p <= LONG_MIN); }
  { int p = -1; P(LONG_MIN - p); }
  { int p = -1; P(p - LONG_MIN); }
  { int p = -1; P(LONG_MIN & p); }
  { int p = -1; P(LONG_MIN | p); }
  { int p = -1; P(LONG_MIN ^ p); }
  { int p = -1; P(p & LONG_MIN); }
  { int p = -1; P(p | LONG_MIN); }
  { int p = -1; P(1 ? LONG_MIN : p); }
  { int p = -1; P(1 ? p : LONG_MIN); }
  { int p = -1; P(0 ? LONG_MIN : p); }
  { int p = -1; P(TC(LONG_MIN + p)); }
  { int p = -1; P(TC(p + LONG_MIN)); }
  { int p = -1; P(TC(1 ? LONG_MIN : p)); }
  { int p = -1; P(sizeof(LONG_MIN + p)); }
  { int p = -1; int t = p; t -= LONG_MIN; P(t); }
  { int p = -1; int t = p; t &= LONG_MIN; P(t); }
  { int p = -1; int t = p; t |= LONG_MIN; P(t); }
  { unsigned p = -1; P(LONG_MIN < p); }
  { unsigned p = -1; P(LONG_MIN > p); }
  { unsigned p = -1; P(LONG_MIN == p); }
  { unsigned p = -1; P(LONG_MIN != p); }
  { unsigned p = -1; P(LONG_MIN <= p); }
  { unsigned p = -1; P(LONG_MIN >= p); }
  { unsigned p = -1; P(p < LONG_MIN); }
  { unsigned p = -1; P(p > LONG_MIN); }
  { unsigned p = -1; P(p == LONG_MIN); }
  { unsigned p = -1; P(p <= LONG_MIN); }
  { unsigned p = -1; P(LONG_MIN + p); }
  { unsigned p = -1; P(p + LONG_MIN); }
  { unsigned p = -1; P(LONG_MIN & p); }
  { unsigned p = -1; P(LONG_MIN | p); }
  { unsigned p = -1; P(LONG_MIN ^ p); }
  { unsigned p = -1; P(p & LONG_MIN); }
  { unsigned p = -1; P(p | LONG_MIN); }
  { unsigned p = -1; P(1 ? LONG_MIN : p); }
  { unsigned p = -1; P(1 ? p : LONG_MIN); }
  { unsigned p = -1; P(0 ? LONG_MIN : p); }
  { unsigned p = -1; P(TC(LONG_MIN + p)); }
  { unsigned p = -1; P(TC(p + LONG_MIN)); }
  { unsigned p = -1; P(TC(1 ? LONG_MIN : p)); }
  { unsigned p = -1; P(sizeof(LONG_MIN + p)); }
  { unsigned p = -1; P(LONG_MIN / p); }
  { unsigned p = -1; P(LONG_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += LONG_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= LONG_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= LONG_MIN; P(t); }
  { long p = -1; P(LONG_MIN < p); }
  { long p = -1; P(LONG_MIN > p); }
  { long p = -1; P(LONG_MIN == p); }
  { long p = -1; P(LONG_MIN != p); }
  { long p = -1; P(LONG_MIN <= p); }
  { long p = -1; P(LONG_MIN >= p); }
  { long p = -1; P(p < LONG_MIN); }
  { long p = -1; P(p > LONG_MIN); }
  { long p = -1; P(p == LONG_MIN); }
  { long p = -1; P(p <= LONG_MIN); }
  { long p = -1; P(LONG_MIN - p); }
  { long p = -1; P(p - LONG_MIN); }
  { long p = -1; P(LONG_MIN & p); }
  { long p = -1; P(LONG_MIN | p); }
  { long p = -1; P(LONG_MIN ^ p); }
  { long p = -1; P(p & LONG_MIN); }
  { long p = -1; P(p | LONG_MIN); }
  { long p = -1; P(1 ? LONG_MIN : p); }
  { long p = -1; P(1 ? p : LONG_MIN); }
  { long p = -1; P(0 ? LONG_MIN : p); }
  { long p = -1; P(TC(LONG_MIN + p)); }
  { long p = -1; P(TC(p + LONG_MIN)); }
  { long p = -1; P(TC(1 ? LONG_MIN : p)); }
  { long p = -1; P(sizeof(LONG_MIN + p)); }
  { long p = -1; long t = p; t -= LONG_MIN; P(t); }
  { long p = -1; long t = p; t &= LONG_MIN; P(t); }
  { long p = -1; long t = p; t |= LONG_MIN; P(t); }
  { unsigned long p = -1; P(LONG_MIN < p); }
  { unsigned long p = -1; P(LONG_MIN > p); }
  { unsigned long p = -1; P(LONG_MIN == p); }
  { unsigned long p = -1; P(LONG_MIN != p); }
  { unsigned long p = -1; P(LONG_MIN <= p); }
  { unsigned long p = -1; P(LONG_MIN >= p); }
  { unsigned long p = -1; P(p < LONG_MIN); }
  { unsigned long p = -1; P(p > LONG_MIN); }
  { unsigned long p = -1; P(p == LONG_MIN); }
  { unsigned long p = -1; P(p <= LONG_MIN); }
  { unsigned long p = -1; P(LONG_MIN + p); }
  { unsigned long p = -1; P(p + LONG_MIN); }
  { unsigned long p = -1; P(LONG_MIN - p); }
  { unsigned long p = -1; P(p - LONG_MIN); }
  { unsigned long p = -1; P(LONG_MIN * p); }
  { unsigned long p = -1; P(p * LONG_MIN); }
  { unsigned long p = -1; P(LONG_MIN & p); }
  { unsigned long p = -1; P(LONG_MIN | p); }
  { unsigned long p = -1; P(LONG_MIN ^ p); }
  { unsigned long p = -1; P(p & LONG_MIN); }
  { unsigned long p = -1; P(p | LONG_MIN); }
  { unsigned long p = -1; P(1 ? LONG_MIN : p); }
  { unsigned long p = -1; P(1 ? p : LONG_MIN); }
  { unsigned long p = -1; P(0 ? LONG_MIN : p); }
  { unsigned long p = -1; P(TC(LONG_MIN + p)); }
  { unsigned long p = -1; P(TC(p + LONG_MIN)); }
  { unsigned long p = -1; P(TC(1 ? LONG_MIN : p)); }
  { unsigned long p = -1; P(sizeof(LONG_MIN + p)); }
  { unsigned long p = -1; P(LONG_MIN / p); }
  { unsigned long p = -1; P(LONG_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += LONG_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= LONG_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= LONG_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= LONG_MIN; P(t); }
  P(PTRDIFF_MAX > 0);
  P(PTRDIFF_MAX < 0);
  P(PTRDIFF_MAX == 0);
  P(PTRDIFF_MAX != 0);
  P(PTRDIFF_MAX >= 0);
  P(PTRDIFF_MAX <= 0);
  P(0 < PTRDIFF_MAX);
  P(0 > PTRDIFF_MAX);
  P(0 == PTRDIFF_MAX);
  P(+PTRDIFF_MAX);
  P(-PTRDIFF_MAX);
  P(~PTRDIFF_MAX);
  P(!PTRDIFF_MAX);
  P((+PTRDIFF_MAX) > 0);
  P(sizeof(PTRDIFF_MAX));
  P(sizeof(+PTRDIFF_MAX));
  P(TC(PTRDIFF_MAX));
  P(TC(+PTRDIFF_MAX));
  P(TC(-PTRDIFF_MAX));
  P(TC(~PTRDIFF_MAX));
  P((_Bool)PTRDIFF_MAX);
  P((signed char)PTRDIFF_MAX);
  P((unsigned char)PTRDIFF_MAX);
  P((short)PTRDIFF_MAX);
  P((unsigned short)PTRDIFF_MAX);
  P((int)PTRDIFF_MAX);
  P((unsigned)PTRDIFF_MAX);
  P((long)PTRDIFF_MAX);
  P((unsigned long)PTRDIFF_MAX);
  P((long long)PTRDIFF_MAX);
  P((unsigned long long)PTRDIFF_MAX);
  P((long long)PTRDIFF_MAX > 0);
  P((long long)PTRDIFF_MAX < 0);
  { int x = PTRDIFF_MAX; P(x); }
  { unsigned x = PTRDIFF_MAX; P(x); }
  { long x = PTRDIFF_MAX; P(x); }
  { unsigned long x = PTRDIFF_MAX; P(x); }
  P(PTRDIFF_MAX - 1);
  P(PTRDIFF_MAX - 1 > 0);
  P(PTRDIFF_MAX - 1u);
  P(PTRDIFF_MAX - 1ul);
  { int p = -1; P(PTRDIFF_MAX < p); }
  { int p = -1; P(PTRDIFF_MAX > p); }
  { int p = -1; P(PTRDIFF_MAX == p); }
  { int p = -1; P(PTRDIFF_MAX != p); }
  { int p = -1; P(PTRDIFF_MAX <= p); }
  { int p = -1; P(PTRDIFF_MAX >= p); }
  { int p = -1; P(p < PTRDIFF_MAX); }
  { int p = -1; P(p > PTRDIFF_MAX); }
  { int p = -1; P(p == PTRDIFF_MAX); }
  { int p = -1; P(p <= PTRDIFF_MAX); }
  { int p = -1; P(PTRDIFF_MAX + p); }
  { int p = -1; P(p + PTRDIFF_MAX); }
  { int p = -1; P(p - PTRDIFF_MAX); }
  { int p = -1; P(PTRDIFF_MAX * p); }
  { int p = -1; P(p * PTRDIFF_MAX); }
  { int p = -1; P(PTRDIFF_MAX & p); }
  { int p = -1; P(PTRDIFF_MAX | p); }
  { int p = -1; P(PTRDIFF_MAX ^ p); }
  { int p = -1; P(p & PTRDIFF_MAX); }
  { int p = -1; P(p | PTRDIFF_MAX); }
  { int p = -1; P(1 ? PTRDIFF_MAX : p); }
  { int p = -1; P(1 ? p : PTRDIFF_MAX); }
  { int p = -1; P(0 ? PTRDIFF_MAX : p); }
  { int p = -1; P(TC(PTRDIFF_MAX + p)); }
  { int p = -1; P(TC(p + PTRDIFF_MAX)); }
  { int p = -1; P(TC(1 ? PTRDIFF_MAX : p)); }
  { int p = -1; P(sizeof(PTRDIFF_MAX + p)); }
  { int p = -1; int t = p; t += PTRDIFF_MAX; P(t); }
  { int p = -1; int t = p; t -= PTRDIFF_MAX; P(t); }
  { int p = -1; int t = p; t &= PTRDIFF_MAX; P(t); }
  { int p = -1; int t = p; t |= PTRDIFF_MAX; P(t); }
  { unsigned p = -1; P(PTRDIFF_MAX < p); }
  { unsigned p = -1; P(PTRDIFF_MAX > p); }
  { unsigned p = -1; P(PTRDIFF_MAX == p); }
  { unsigned p = -1; P(PTRDIFF_MAX != p); }
  { unsigned p = -1; P(PTRDIFF_MAX <= p); }
  { unsigned p = -1; P(PTRDIFF_MAX >= p); }
  { unsigned p = -1; P(p < PTRDIFF_MAX); }
  { unsigned p = -1; P(p > PTRDIFF_MAX); }
  { unsigned p = -1; P(p == PTRDIFF_MAX); }
  { unsigned p = -1; P(p <= PTRDIFF_MAX); }
  { unsigned p = -1; P(PTRDIFF_MAX - p); }
  { unsigned p = -1; P(p - PTRDIFF_MAX); }
  { unsigned p = -1; P(PTRDIFF_MAX & p); }
  { unsigned p = -1; P(PTRDIFF_MAX | p); }
  { unsigned p = -1; P(PTRDIFF_MAX ^ p); }
  { unsigned p = -1; P(p & PTRDIFF_MAX); }
  { unsigned p = -1; P(p | PTRDIFF_MAX); }
  { unsigned p = -1; P(1 ? PTRDIFF_MAX : p); }
  { unsigned p = -1; P(1 ? p : PTRDIFF_MAX); }
  { unsigned p = -1; P(0 ? PTRDIFF_MAX : p); }
  { unsigned p = -1; P(TC(PTRDIFF_MAX + p)); }
  { unsigned p = -1; P(TC(p + PTRDIFF_MAX)); }
  { unsigned p = -1; P(TC(1 ? PTRDIFF_MAX : p)); }
  { unsigned p = -1; P(sizeof(PTRDIFF_MAX + p)); }
  { unsigned p = -1; P(PTRDIFF_MAX / p); }
  { unsigned p = -1; P(PTRDIFF_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= PTRDIFF_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= PTRDIFF_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= PTRDIFF_MAX; P(t); }
  { long p = -1; P(PTRDIFF_MAX < p); }
  { long p = -1; P(PTRDIFF_MAX > p); }
  { long p = -1; P(PTRDIFF_MAX == p); }
  { long p = -1; P(PTRDIFF_MAX != p); }
  { long p = -1; P(PTRDIFF_MAX <= p); }
  { long p = -1; P(PTRDIFF_MAX >= p); }
  { long p = -1; P(p < PTRDIFF_MAX); }
  { long p = -1; P(p > PTRDIFF_MAX); }
  { long p = -1; P(p == PTRDIFF_MAX); }
  { long p = -1; P(p <= PTRDIFF_MAX); }
  { long p = -1; P(PTRDIFF_MAX + p); }
  { long p = -1; P(p + PTRDIFF_MAX); }
  { long p = -1; P(p - PTRDIFF_MAX); }
  { long p = -1; P(PTRDIFF_MAX * p); }
  { long p = -1; P(p * PTRDIFF_MAX); }
  { long p = -1; P(PTRDIFF_MAX & p); }
  { long p = -1; P(PTRDIFF_MAX | p); }
  { long p = -1; P(PTRDIFF_MAX ^ p); }
  { long p = -1; P(p & PTRDIFF_MAX); }
  { long p = -1; P(p | PTRDIFF_MAX); }
  { long p = -1; P(1 ? PTRDIFF_MAX : p); }
  { long p = -1; P(1 ? p : PTRDIFF_MAX); }
  { long p = -1; P(0 ? PTRDIFF_MAX : p); }
  { long p = -1; P(TC(PTRDIFF_MAX + p)); }
  { long p = -1; P(TC(p + PTRDIFF_MAX)); }
  { long p = -1; P(TC(1 ? PTRDIFF_MAX : p)); }
  { long p = -1; P(sizeof(PTRDIFF_MAX + p)); }
  { long p = -1; long t = p; t += PTRDIFF_MAX; P(t); }
  { long p = -1; long t = p; t -= PTRDIFF_MAX; P(t); }
  { long p = -1; long t = p; t &= PTRDIFF_MAX; P(t); }
  { long p = -1; long t = p; t |= PTRDIFF_MAX; P(t); }
  { unsigned long p = -1; P(PTRDIFF_MAX < p); }
  { unsigned long p = -1; P(PTRDIFF_MAX > p); }
  { unsigned long p = -1; P(PTRDIFF_MAX == p); }
  { unsigned long p = -1; P(PTRDIFF_MAX != p); }
  { unsigned long p = -1; P(PTRDIFF_MAX <= p); }
  { unsigned long p = -1; P(PTRDIFF_MAX >= p); }
  { unsigned long p = -1; P(p < PTRDIFF_MAX); }
  { unsigned long p = -1; P(p > PTRDIFF_MAX); }
  { unsigned long p = -1; P(p == PTRDIFF_MAX); }
  { unsigned long p = -1; P(p <= PTRDIFF_MAX); }
  { unsigned long p = -1; P(PTRDIFF_MAX + p); }
  { unsigned long p = -1; P(p + PTRDIFF_MAX); }
  { unsigned long p = -1; P(PTRDIFF_MAX - p); }
  { unsigned long p = -1; P(p - PTRDIFF_MAX); }
  { unsigned long p = -1; P(PTRDIFF_MAX * p); }
  { unsigned long p = -1; P(p * PTRDIFF_MAX); }
  { unsigned long p = -1; P(PTRDIFF_MAX & p); }
  { unsigned long p = -1; P(PTRDIFF_MAX | p); }
  { unsigned long p = -1; P(PTRDIFF_MAX ^ p); }
  { unsigned long p = -1; P(p & PTRDIFF_MAX); }
  { unsigned long p = -1; P(p | PTRDIFF_MAX); }
  { unsigned long p = -1; P(1 ? PTRDIFF_MAX : p); }
  { unsigned long p = -1; P(1 ? p : PTRDIFF_MAX); }
  { unsigned long p = -1; P(0 ? PTRDIFF_MAX : p); }
  { unsigned long p = -1; P(TC(PTRDIFF_MAX + p)); }
  { unsigned long p = -1; P(TC(p + PTRDIFF_MAX)); }
  { unsigned long p = -1; P(TC(1 ? PTRDIFF_MAX : p)); }
  { unsigned long p = -1; P(sizeof(PTRDIFF_MAX + p)); }
  { unsigned long p = -1; P(PTRDIFF_MAX / p); }
  { unsigned long p = -1; P(PTRDIFF_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += PTRDIFF_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= PTRDIFF_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= PTRDIFF_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= PTRDIFF_MAX; P(t); }
  P(PTRDIFF_MIN > 0);
  P(PTRDIFF_MIN < 0);
  P(PTRDIFF_MIN == 0);
  P(PTRDIFF_MIN != 0);
  P(PTRDIFF_MIN >= 0);
  P(PTRDIFF_MIN <= 0);
  P(0 < PTRDIFF_MIN);
  P(0 > PTRDIFF_MIN);
  P(0 == PTRDIFF_MIN);
  P(+PTRDIFF_MIN);
  P(~PTRDIFF_MIN);
  P(!PTRDIFF_MIN);
  P((+PTRDIFF_MIN) > 0);
  P(sizeof(PTRDIFF_MIN));
  P(sizeof(+PTRDIFF_MIN));
  P(TC(PTRDIFF_MIN));
  P(TC(+PTRDIFF_MIN));
  P(TC(-PTRDIFF_MIN));
  P(TC(~PTRDIFF_MIN));
  P((_Bool)PTRDIFF_MIN);
  P((signed char)PTRDIFF_MIN);
  P((unsigned char)PTRDIFF_MIN);
  P((short)PTRDIFF_MIN);
  P((unsigned short)PTRDIFF_MIN);
  P((int)PTRDIFF_MIN);
  P((unsigned)PTRDIFF_MIN);
  P((long)PTRDIFF_MIN);
  P((unsigned long)PTRDIFF_MIN);
  P((long long)PTRDIFF_MIN);
  P((unsigned long long)PTRDIFF_MIN);
  P((long long)PTRDIFF_MIN > 0);
  P((long long)PTRDIFF_MIN < 0);
  { int x = PTRDIFF_MIN; P(x); }
  { unsigned x = PTRDIFF_MIN; P(x); }
  { long x = PTRDIFF_MIN; P(x); }
  { unsigned long x = PTRDIFF_MIN; P(x); }
  P(PTRDIFF_MIN + 1);
  P(PTRDIFF_MIN + 1 > 0);
  P(PTRDIFF_MIN + 1u);
  P(PTRDIFF_MIN + 1l);
  P(PTRDIFF_MIN - 1ul);
  { int p = -1; P(PTRDIFF_MIN < p); }
  { int p = -1; P(PTRDIFF_MIN > p); }
  { int p = -1; P(PTRDIFF_MIN == p); }
  { int p = -1; P(PTRDIFF_MIN != p); }
  { int p = -1; P(PTRDIFF_MIN <= p); }
  { int p = -1; P(PTRDIFF_MIN >= p); }
  { int p = -1; P(p < PTRDIFF_MIN); }
  { int p = -1; P(p > PTRDIFF_MIN); }
  { int p = -1; P(p == PTRDIFF_MIN); }
  { int p = -1; P(p <= PTRDIFF_MIN); }
  { int p = -1; P(PTRDIFF_MIN - p); }
  { int p = -1; P(p - PTRDIFF_MIN); }
  { int p = -1; P(PTRDIFF_MIN & p); }
  { int p = -1; P(PTRDIFF_MIN | p); }
  { int p = -1; P(PTRDIFF_MIN ^ p); }
  { int p = -1; P(p & PTRDIFF_MIN); }
  { int p = -1; P(p | PTRDIFF_MIN); }
  { int p = -1; P(1 ? PTRDIFF_MIN : p); }
  { int p = -1; P(1 ? p : PTRDIFF_MIN); }
  { int p = -1; P(0 ? PTRDIFF_MIN : p); }
  { int p = -1; P(TC(PTRDIFF_MIN + p)); }
  { int p = -1; P(TC(p + PTRDIFF_MIN)); }
  { int p = -1; P(TC(1 ? PTRDIFF_MIN : p)); }
  { int p = -1; P(sizeof(PTRDIFF_MIN + p)); }
  { int p = -1; int t = p; t -= PTRDIFF_MIN; P(t); }
  { int p = -1; int t = p; t &= PTRDIFF_MIN; P(t); }
  { int p = -1; int t = p; t |= PTRDIFF_MIN; P(t); }
  { unsigned p = -1; P(PTRDIFF_MIN < p); }
  { unsigned p = -1; P(PTRDIFF_MIN > p); }
  { unsigned p = -1; P(PTRDIFF_MIN == p); }
  { unsigned p = -1; P(PTRDIFF_MIN != p); }
  { unsigned p = -1; P(PTRDIFF_MIN <= p); }
  { unsigned p = -1; P(PTRDIFF_MIN >= p); }
  { unsigned p = -1; P(p < PTRDIFF_MIN); }
  { unsigned p = -1; P(p > PTRDIFF_MIN); }
  { unsigned p = -1; P(p == PTRDIFF_MIN); }
  { unsigned p = -1; P(p <= PTRDIFF_MIN); }
  { unsigned p = -1; P(PTRDIFF_MIN + p); }
  { unsigned p = -1; P(p + PTRDIFF_MIN); }
  { unsigned p = -1; P(PTRDIFF_MIN & p); }
  { unsigned p = -1; P(PTRDIFF_MIN | p); }
  { unsigned p = -1; P(PTRDIFF_MIN ^ p); }
  { unsigned p = -1; P(p & PTRDIFF_MIN); }
  { unsigned p = -1; P(p | PTRDIFF_MIN); }
  { unsigned p = -1; P(1 ? PTRDIFF_MIN : p); }
  { unsigned p = -1; P(1 ? p : PTRDIFF_MIN); }
  { unsigned p = -1; P(0 ? PTRDIFF_MIN : p); }
  { unsigned p = -1; P(TC(PTRDIFF_MIN + p)); }
  { unsigned p = -1; P(TC(p + PTRDIFF_MIN)); }
  { unsigned p = -1; P(TC(1 ? PTRDIFF_MIN : p)); }
  { unsigned p = -1; P(sizeof(PTRDIFF_MIN + p)); }
  { unsigned p = -1; P(PTRDIFF_MIN / p); }
  { unsigned p = -1; P(PTRDIFF_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += PTRDIFF_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= PTRDIFF_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= PTRDIFF_MIN; P(t); }
  { long p = -1; P(PTRDIFF_MIN < p); }
  { long p = -1; P(PTRDIFF_MIN > p); }
  { long p = -1; P(PTRDIFF_MIN == p); }
  { long p = -1; P(PTRDIFF_MIN != p); }
  { long p = -1; P(PTRDIFF_MIN <= p); }
  { long p = -1; P(PTRDIFF_MIN >= p); }
  { long p = -1; P(p < PTRDIFF_MIN); }
  { long p = -1; P(p > PTRDIFF_MIN); }
  { long p = -1; P(p == PTRDIFF_MIN); }
  { long p = -1; P(p <= PTRDIFF_MIN); }
  { long p = -1; P(PTRDIFF_MIN - p); }
  { long p = -1; P(p - PTRDIFF_MIN); }
  { long p = -1; P(PTRDIFF_MIN & p); }
  { long p = -1; P(PTRDIFF_MIN | p); }
  { long p = -1; P(PTRDIFF_MIN ^ p); }
  { long p = -1; P(p & PTRDIFF_MIN); }
  { long p = -1; P(p | PTRDIFF_MIN); }
  { long p = -1; P(1 ? PTRDIFF_MIN : p); }
  { long p = -1; P(1 ? p : PTRDIFF_MIN); }
  { long p = -1; P(0 ? PTRDIFF_MIN : p); }
  { long p = -1; P(TC(PTRDIFF_MIN + p)); }
  { long p = -1; P(TC(p + PTRDIFF_MIN)); }
  { long p = -1; P(TC(1 ? PTRDIFF_MIN : p)); }
  { long p = -1; P(sizeof(PTRDIFF_MIN + p)); }
  { long p = -1; long t = p; t -= PTRDIFF_MIN; P(t); }
  { long p = -1; long t = p; t &= PTRDIFF_MIN; P(t); }
  { long p = -1; long t = p; t |= PTRDIFF_MIN; P(t); }
  { unsigned long p = -1; P(PTRDIFF_MIN < p); }
  { unsigned long p = -1; P(PTRDIFF_MIN > p); }
  { unsigned long p = -1; P(PTRDIFF_MIN == p); }
  { unsigned long p = -1; P(PTRDIFF_MIN != p); }
  { unsigned long p = -1; P(PTRDIFF_MIN <= p); }
  { unsigned long p = -1; P(PTRDIFF_MIN >= p); }
  { unsigned long p = -1; P(p < PTRDIFF_MIN); }
  { unsigned long p = -1; P(p > PTRDIFF_MIN); }
  { unsigned long p = -1; P(p == PTRDIFF_MIN); }
  { unsigned long p = -1; P(p <= PTRDIFF_MIN); }
  { unsigned long p = -1; P(PTRDIFF_MIN + p); }
  { unsigned long p = -1; P(p + PTRDIFF_MIN); }
  { unsigned long p = -1; P(PTRDIFF_MIN - p); }
  { unsigned long p = -1; P(p - PTRDIFF_MIN); }
  { unsigned long p = -1; P(PTRDIFF_MIN * p); }
  { unsigned long p = -1; P(p * PTRDIFF_MIN); }
  { unsigned long p = -1; P(PTRDIFF_MIN & p); }
  { unsigned long p = -1; P(PTRDIFF_MIN | p); }
  { unsigned long p = -1; P(PTRDIFF_MIN ^ p); }
  { unsigned long p = -1; P(p & PTRDIFF_MIN); }
  { unsigned long p = -1; P(p | PTRDIFF_MIN); }
  { unsigned long p = -1; P(1 ? PTRDIFF_MIN : p); }
  { unsigned long p = -1; P(1 ? p : PTRDIFF_MIN); }
  { unsigned long p = -1; P(0 ? PTRDIFF_MIN : p); }
  { unsigned long p = -1; P(TC(PTRDIFF_MIN + p)); }
  { unsigned long p = -1; P(TC(p + PTRDIFF_MIN)); }
  { unsigned long p = -1; P(TC(1 ? PTRDIFF_MIN : p)); }
  { unsigned long p = -1; P(sizeof(PTRDIFF_MIN + p)); }
  { unsigned long p = -1; P(PTRDIFF_MIN / p); }
  { unsigned long p = -1; P(PTRDIFF_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += PTRDIFF_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= PTRDIFF_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= PTRDIFF_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= PTRDIFF_MIN; P(t); }
  P(SIZE_MAX > 0);
  P(SIZE_MAX < 0);
  P(SIZE_MAX == 0);
  P(SIZE_MAX != 0);
  P(SIZE_MAX >= 0);
  P(SIZE_MAX <= 0);
  P(0 < SIZE_MAX);
  P(0 > SIZE_MAX);
  P(0 == SIZE_MAX);
  P(+SIZE_MAX);
  P(-SIZE_MAX);
  P(~SIZE_MAX);
  P(!SIZE_MAX);
  P((+SIZE_MAX) > 0);
  P(sizeof(SIZE_MAX));
  P(sizeof(+SIZE_MAX));
  P(TC(SIZE_MAX));
  P(TC(+SIZE_MAX));
  P(TC(-SIZE_MAX));
  P(TC(~SIZE_MAX));
  P((_Bool)SIZE_MAX);
  P((signed char)SIZE_MAX);
  P((unsigned char)SIZE_MAX);
  P((short)SIZE_MAX);
  P((unsigned short)SIZE_MAX);
  P((int)SIZE_MAX);
  P((unsigned)SIZE_MAX);
  P((long)SIZE_MAX);
  P((unsigned long)SIZE_MAX);
  P((long long)SIZE_MAX);
  P((unsigned long long)SIZE_MAX);
  P((long long)SIZE_MAX > 0);
  P((long long)SIZE_MAX < 0);
  { int x = SIZE_MAX; P(x); }
  { unsigned x = SIZE_MAX; P(x); }
  { long x = SIZE_MAX; P(x); }
  { unsigned long x = SIZE_MAX; P(x); }
  P(SIZE_MAX + 1);
  P(SIZE_MAX - 1);
  P(SIZE_MAX - 1 > 0);
  P(SIZE_MAX + 1 > 0);
  P(SIZE_MAX + 1u);
  P(SIZE_MAX - 1u);
  P(SIZE_MAX + 1l);
  P(SIZE_MAX - 1ul);
  { int p = -1; P(SIZE_MAX < p); }
  { int p = -1; P(SIZE_MAX > p); }
  { int p = -1; P(SIZE_MAX == p); }
  { int p = -1; P(SIZE_MAX != p); }
  { int p = -1; P(SIZE_MAX <= p); }
  { int p = -1; P(SIZE_MAX >= p); }
  { int p = -1; P(p < SIZE_MAX); }
  { int p = -1; P(p > SIZE_MAX); }
  { int p = -1; P(p == SIZE_MAX); }
  { int p = -1; P(p <= SIZE_MAX); }
  { int p = -1; P(SIZE_MAX + p); }
  { int p = -1; P(p + SIZE_MAX); }
  { int p = -1; P(SIZE_MAX - p); }
  { int p = -1; P(p - SIZE_MAX); }
  { int p = -1; P(SIZE_MAX * p); }
  { int p = -1; P(p * SIZE_MAX); }
  { int p = -1; P(SIZE_MAX & p); }
  { int p = -1; P(SIZE_MAX | p); }
  { int p = -1; P(SIZE_MAX ^ p); }
  { int p = -1; P(p & SIZE_MAX); }
  { int p = -1; P(p | SIZE_MAX); }
  { int p = -1; P(1 ? SIZE_MAX : p); }
  { int p = -1; P(1 ? p : SIZE_MAX); }
  { int p = -1; P(0 ? SIZE_MAX : p); }
  { int p = -1; P(TC(SIZE_MAX + p)); }
  { int p = -1; P(TC(p + SIZE_MAX)); }
  { int p = -1; P(TC(1 ? SIZE_MAX : p)); }
  { int p = -1; P(sizeof(SIZE_MAX + p)); }
  { int p = -1; int t = p; t += SIZE_MAX; P(t); }
  { int p = -1; int t = p; t -= SIZE_MAX; P(t); }
  { int p = -1; int t = p; t &= SIZE_MAX; P(t); }
  { int p = -1; int t = p; t |= SIZE_MAX; P(t); }
  { unsigned p = -1; P(SIZE_MAX < p); }
  { unsigned p = -1; P(SIZE_MAX > p); }
  { unsigned p = -1; P(SIZE_MAX == p); }
  { unsigned p = -1; P(SIZE_MAX != p); }
  { unsigned p = -1; P(SIZE_MAX <= p); }
  { unsigned p = -1; P(SIZE_MAX >= p); }
  { unsigned p = -1; P(p < SIZE_MAX); }
  { unsigned p = -1; P(p > SIZE_MAX); }
  { unsigned p = -1; P(p == SIZE_MAX); }
  { unsigned p = -1; P(p <= SIZE_MAX); }
  { unsigned p = -1; P(SIZE_MAX + p); }
  { unsigned p = -1; P(p + SIZE_MAX); }
  { unsigned p = -1; P(SIZE_MAX - p); }
  { unsigned p = -1; P(p - SIZE_MAX); }
  { unsigned p = -1; P(SIZE_MAX * p); }
  { unsigned p = -1; P(p * SIZE_MAX); }
  { unsigned p = -1; P(SIZE_MAX & p); }
  { unsigned p = -1; P(SIZE_MAX | p); }
  { unsigned p = -1; P(SIZE_MAX ^ p); }
  { unsigned p = -1; P(p & SIZE_MAX); }
  { unsigned p = -1; P(p | SIZE_MAX); }
  { unsigned p = -1; P(1 ? SIZE_MAX : p); }
  { unsigned p = -1; P(1 ? p : SIZE_MAX); }
  { unsigned p = -1; P(0 ? SIZE_MAX : p); }
  { unsigned p = -1; P(TC(SIZE_MAX + p)); }
  { unsigned p = -1; P(TC(p + SIZE_MAX)); }
  { unsigned p = -1; P(TC(1 ? SIZE_MAX : p)); }
  { unsigned p = -1; P(sizeof(SIZE_MAX + p)); }
  { unsigned p = -1; P(SIZE_MAX / p); }
  { unsigned p = -1; P(SIZE_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += SIZE_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= SIZE_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= SIZE_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= SIZE_MAX; P(t); }
  { long p = -1; P(SIZE_MAX < p); }
  { long p = -1; P(SIZE_MAX > p); }
  { long p = -1; P(SIZE_MAX == p); }
  { long p = -1; P(SIZE_MAX != p); }
  { long p = -1; P(SIZE_MAX <= p); }
  { long p = -1; P(SIZE_MAX >= p); }
  { long p = -1; P(p < SIZE_MAX); }
  { long p = -1; P(p > SIZE_MAX); }
  { long p = -1; P(p == SIZE_MAX); }
  { long p = -1; P(p <= SIZE_MAX); }
  { long p = -1; P(SIZE_MAX + p); }
  { long p = -1; P(p + SIZE_MAX); }
  { long p = -1; P(SIZE_MAX - p); }
  { long p = -1; P(p - SIZE_MAX); }
  { long p = -1; P(SIZE_MAX * p); }
  { long p = -1; P(p * SIZE_MAX); }
  { long p = -1; P(SIZE_MAX & p); }
  { long p = -1; P(SIZE_MAX | p); }
  { long p = -1; P(SIZE_MAX ^ p); }
  { long p = -1; P(p & SIZE_MAX); }
  { long p = -1; P(p | SIZE_MAX); }
  { long p = -1; P(1 ? SIZE_MAX : p); }
  { long p = -1; P(1 ? p : SIZE_MAX); }
  { long p = -1; P(0 ? SIZE_MAX : p); }
  { long p = -1; P(TC(SIZE_MAX + p)); }
  { long p = -1; P(TC(p + SIZE_MAX)); }
  { long p = -1; P(TC(1 ? SIZE_MAX : p)); }
  { long p = -1; P(sizeof(SIZE_MAX + p)); }
  { long p = -1; long t = p; t += SIZE_MAX; P(t); }
  { long p = -1; long t = p; t -= SIZE_MAX; P(t); }
  { long p = -1; long t = p; t &= SIZE_MAX; P(t); }
  { long p = -1; long t = p; t |= SIZE_MAX; P(t); }
  { unsigned long p = -1; P(SIZE_MAX < p); }
  { unsigned long p = -1; P(SIZE_MAX > p); }
  { unsigned long p = -1; P(SIZE_MAX == p); }
  { unsigned long p = -1; P(SIZE_MAX != p); }
  { unsigned long p = -1; P(SIZE_MAX <= p); }
  { unsigned long p = -1; P(SIZE_MAX >= p); }
  { unsigned long p = -1; P(p < SIZE_MAX); }
  { unsigned long p = -1; P(p > SIZE_MAX); }
  { unsigned long p = -1; P(p == SIZE_MAX); }
  { unsigned long p = -1; P(p <= SIZE_MAX); }
  { unsigned long p = -1; P(SIZE_MAX + p); }
  { unsigned long p = -1; P(p + SIZE_MAX); }
  { unsigned long p = -1; P(SIZE_MAX - p); }
  { unsigned long p = -1; P(p - SIZE_MAX); }
  { unsigned long p = -1; P(SIZE_MAX * p); }
  { unsigned long p = -1; P(p * SIZE_MAX); }
  { unsigned long p = -1; P(SIZE_MAX & p); }
  { unsigned long p = -1; P(SIZE_MAX | p); }
  { unsigned long p = -1; P(SIZE_MAX ^ p); }
  { unsigned long p = -1; P(p & SIZE_MAX); }
  { unsigned long p = -1; P(p | SIZE_MAX); }
  { unsigned long p = -1; P(1 ? SIZE_MAX : p); }
  { unsigned long p = -1; P(1 ? p : SIZE_MAX); }
  { unsigned long p = -1; P(0 ? SIZE_MAX : p); }
  { unsigned long p = -1; P(TC(SIZE_MAX + p)); }
  { unsigned long p = -1; P(TC(p + SIZE_MAX)); }
  { unsigned long p = -1; P(TC(1 ? SIZE_MAX : p)); }
  { unsigned long p = -1; P(sizeof(SIZE_MAX + p)); }
  { unsigned long p = -1; P(SIZE_MAX / p); }
  { unsigned long p = -1; P(SIZE_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += SIZE_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= SIZE_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= SIZE_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= SIZE_MAX; P(t); }
  P(UCHAR_MAX > 0);
  P(UCHAR_MAX < 0);
  P(UCHAR_MAX == 0);
  P(UCHAR_MAX != 0);
  P(UCHAR_MAX >= 0);
  P(UCHAR_MAX <= 0);
  P(0 < UCHAR_MAX);
  P(0 > UCHAR_MAX);
  P(0 == UCHAR_MAX);
  P(+UCHAR_MAX);
  P(-UCHAR_MAX);
  P(~UCHAR_MAX);
  P(!UCHAR_MAX);
  P((+UCHAR_MAX) > 0);
  P(sizeof(+UCHAR_MAX));
  P(TC(+UCHAR_MAX));
  P(TC(-UCHAR_MAX));
  P(TC(~UCHAR_MAX));
  P((_Bool)UCHAR_MAX);
  P((signed char)UCHAR_MAX);
  P((unsigned char)UCHAR_MAX);
  P((short)UCHAR_MAX);
  P((unsigned short)UCHAR_MAX);
  P((int)UCHAR_MAX);
  P((unsigned)UCHAR_MAX);
  P((long)UCHAR_MAX);
  P((unsigned long)UCHAR_MAX);
  P((long long)UCHAR_MAX);
  P((unsigned long long)UCHAR_MAX);
  P((long long)UCHAR_MAX > 0);
  P((long long)UCHAR_MAX < 0);
  { int x = UCHAR_MAX; P(x); }
  { unsigned x = UCHAR_MAX; P(x); }
  { long x = UCHAR_MAX; P(x); }
  { unsigned long x = UCHAR_MAX; P(x); }
  P(UCHAR_MAX + 1);
  P(UCHAR_MAX - 1);
  P(UCHAR_MAX - 1 > 0);
  P(UCHAR_MAX + 1 > 0);
  P(UCHAR_MAX + 1u);
  P(UCHAR_MAX - 1u);
  P(UCHAR_MAX + 1l);
  P(UCHAR_MAX - 1ul);
  { int p = -1; P(UCHAR_MAX < p); }
  { int p = -1; P(UCHAR_MAX > p); }
  { int p = -1; P(UCHAR_MAX == p); }
  { int p = -1; P(UCHAR_MAX != p); }
  { int p = -1; P(UCHAR_MAX <= p); }
  { int p = -1; P(UCHAR_MAX >= p); }
  { int p = -1; P(p < UCHAR_MAX); }
  { int p = -1; P(p > UCHAR_MAX); }
  { int p = -1; P(p == UCHAR_MAX); }
  { int p = -1; P(p <= UCHAR_MAX); }
  { int p = -1; P(UCHAR_MAX + p); }
  { int p = -1; P(p + UCHAR_MAX); }
  { int p = -1; P(UCHAR_MAX - p); }
  { int p = -1; P(p - UCHAR_MAX); }
  { int p = -1; P(UCHAR_MAX * p); }
  { int p = -1; P(p * UCHAR_MAX); }
  { int p = -1; P(UCHAR_MAX & p); }
  { int p = -1; P(UCHAR_MAX | p); }
  { int p = -1; P(UCHAR_MAX ^ p); }
  { int p = -1; P(p & UCHAR_MAX); }
  { int p = -1; P(p | UCHAR_MAX); }
  { int p = -1; P(1 ? UCHAR_MAX : p); }
  { int p = -1; P(1 ? p : UCHAR_MAX); }
  { int p = -1; P(0 ? UCHAR_MAX : p); }
  { int p = -1; P(TC(UCHAR_MAX + p)); }
  { int p = -1; P(TC(p + UCHAR_MAX)); }
  { int p = -1; P(TC(1 ? UCHAR_MAX : p)); }
  { int p = -1; P(sizeof(UCHAR_MAX + p)); }
  { int p = -1; int t = p; t += UCHAR_MAX; P(t); }
  { int p = -1; int t = p; t -= UCHAR_MAX; P(t); }
  { int p = -1; int t = p; t &= UCHAR_MAX; P(t); }
  { int p = -1; int t = p; t |= UCHAR_MAX; P(t); }
  { unsigned p = -1; P(UCHAR_MAX < p); }
  { unsigned p = -1; P(UCHAR_MAX > p); }
  { unsigned p = -1; P(UCHAR_MAX == p); }
  { unsigned p = -1; P(UCHAR_MAX != p); }
  { unsigned p = -1; P(UCHAR_MAX <= p); }
  { unsigned p = -1; P(UCHAR_MAX >= p); }
  { unsigned p = -1; P(p < UCHAR_MAX); }
  { unsigned p = -1; P(p > UCHAR_MAX); }
  { unsigned p = -1; P(p == UCHAR_MAX); }
  { unsigned p = -1; P(p <= UCHAR_MAX); }
  { unsigned p = -1; P(UCHAR_MAX + p); }
  { unsigned p = -1; P(p + UCHAR_MAX); }
  { unsigned p = -1; P(UCHAR_MAX - p); }
  { unsigned p = -1; P(p - UCHAR_MAX); }
  { unsigned p = -1; P(UCHAR_MAX * p); }
  { unsigned p = -1; P(p * UCHAR_MAX); }
  { unsigned p = -1; P(UCHAR_MAX & p); }
  { unsigned p = -1; P(UCHAR_MAX | p); }
  { unsigned p = -1; P(UCHAR_MAX ^ p); }
  { unsigned p = -1; P(p & UCHAR_MAX); }
  { unsigned p = -1; P(p | UCHAR_MAX); }
  { unsigned p = -1; P(1 ? UCHAR_MAX : p); }
  { unsigned p = -1; P(1 ? p : UCHAR_MAX); }
  { unsigned p = -1; P(0 ? UCHAR_MAX : p); }
  { unsigned p = -1; P(TC(UCHAR_MAX + p)); }
  { unsigned p = -1; P(TC(p + UCHAR_MAX)); }
  { unsigned p = -1; P(TC(1 ? UCHAR_MAX : p)); }
  { unsigned p = -1; P(sizeof(UCHAR_MAX + p)); }
  { unsigned p = -1; P(UCHAR_MAX / p); }
  { unsigned p = -1; P(UCHAR_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UCHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UCHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UCHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UCHAR_MAX; P(t); }
  { long p = -1; P(UCHAR_MAX < p); }
  { long p = -1; P(UCHAR_MAX > p); }
  { long p = -1; P(UCHAR_MAX == p); }
  { long p = -1; P(UCHAR_MAX != p); }
  { long p = -1; P(UCHAR_MAX <= p); }
  { long p = -1; P(UCHAR_MAX >= p); }
  { long p = -1; P(p < UCHAR_MAX); }
  { long p = -1; P(p > UCHAR_MAX); }
  { long p = -1; P(p == UCHAR_MAX); }
  { long p = -1; P(p <= UCHAR_MAX); }
  { long p = -1; P(UCHAR_MAX + p); }
  { long p = -1; P(p + UCHAR_MAX); }
  { long p = -1; P(UCHAR_MAX - p); }
  { long p = -1; P(p - UCHAR_MAX); }
  { long p = -1; P(UCHAR_MAX * p); }
  { long p = -1; P(p * UCHAR_MAX); }
  { long p = -1; P(UCHAR_MAX & p); }
  { long p = -1; P(UCHAR_MAX | p); }
  { long p = -1; P(UCHAR_MAX ^ p); }
  { long p = -1; P(p & UCHAR_MAX); }
  { long p = -1; P(p | UCHAR_MAX); }
  { long p = -1; P(1 ? UCHAR_MAX : p); }
  { long p = -1; P(1 ? p : UCHAR_MAX); }
  { long p = -1; P(0 ? UCHAR_MAX : p); }
  { long p = -1; P(TC(UCHAR_MAX + p)); }
  { long p = -1; P(TC(p + UCHAR_MAX)); }
  { long p = -1; P(TC(1 ? UCHAR_MAX : p)); }
  { long p = -1; P(sizeof(UCHAR_MAX + p)); }
  { long p = -1; long t = p; t += UCHAR_MAX; P(t); }
  { long p = -1; long t = p; t -= UCHAR_MAX; P(t); }
  { long p = -1; long t = p; t &= UCHAR_MAX; P(t); }
  { long p = -1; long t = p; t |= UCHAR_MAX; P(t); }
  { unsigned long p = -1; P(UCHAR_MAX < p); }
  { unsigned long p = -1; P(UCHAR_MAX > p); }
  { unsigned long p = -1; P(UCHAR_MAX == p); }
  { unsigned long p = -1; P(UCHAR_MAX != p); }
  { unsigned long p = -1; P(UCHAR_MAX <= p); }
  { unsigned long p = -1; P(UCHAR_MAX >= p); }
  { unsigned long p = -1; P(p < UCHAR_MAX); }
  { unsigned long p = -1; P(p > UCHAR_MAX); }
  { unsigned long p = -1; P(p == UCHAR_MAX); }
  { unsigned long p = -1; P(p <= UCHAR_MAX); }
  { unsigned long p = -1; P(UCHAR_MAX + p); }
  { unsigned long p = -1; P(p + UCHAR_MAX); }
  { unsigned long p = -1; P(UCHAR_MAX - p); }
  { unsigned long p = -1; P(p - UCHAR_MAX); }
  { unsigned long p = -1; P(UCHAR_MAX * p); }
  { unsigned long p = -1; P(p * UCHAR_MAX); }
  { unsigned long p = -1; P(UCHAR_MAX & p); }
  { unsigned long p = -1; P(UCHAR_MAX | p); }
  { unsigned long p = -1; P(UCHAR_MAX ^ p); }
  { unsigned long p = -1; P(p & UCHAR_MAX); }
  { unsigned long p = -1; P(p | UCHAR_MAX); }
  { unsigned long p = -1; P(1 ? UCHAR_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UCHAR_MAX); }
  { unsigned long p = -1; P(0 ? UCHAR_MAX : p); }
  { unsigned long p = -1; P(TC(UCHAR_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UCHAR_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UCHAR_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UCHAR_MAX + p)); }
  { unsigned long p = -1; P(UCHAR_MAX / p); }
  { unsigned long p = -1; P(UCHAR_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UCHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UCHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UCHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UCHAR_MAX; P(t); }
  P(UINT16_MAX > 0);
  P(UINT16_MAX < 0);
  P(UINT16_MAX == 0);
  P(UINT16_MAX != 0);
  P(UINT16_MAX >= 0);
  P(UINT16_MAX <= 0);
  P(0 < UINT16_MAX);
  P(0 > UINT16_MAX);
  P(0 == UINT16_MAX);
  P(+UINT16_MAX);
  P(-UINT16_MAX);
  P(~UINT16_MAX);
  P(!UINT16_MAX);
  P((+UINT16_MAX) > 0);
  P(sizeof(+UINT16_MAX));
  P(TC(+UINT16_MAX));
  P(TC(-UINT16_MAX));
  P(TC(~UINT16_MAX));
  P((_Bool)UINT16_MAX);
  P((signed char)UINT16_MAX);
  P((unsigned char)UINT16_MAX);
  P((short)UINT16_MAX);
  P((unsigned short)UINT16_MAX);
  P((int)UINT16_MAX);
  P((unsigned)UINT16_MAX);
  P((long)UINT16_MAX);
  P((unsigned long)UINT16_MAX);
  P((long long)UINT16_MAX);
  P((unsigned long long)UINT16_MAX);
  P((long long)UINT16_MAX > 0);
  P((long long)UINT16_MAX < 0);
  { int x = UINT16_MAX; P(x); }
  { unsigned x = UINT16_MAX; P(x); }
  { long x = UINT16_MAX; P(x); }
  { unsigned long x = UINT16_MAX; P(x); }
  P(UINT16_MAX + 1);
  P(UINT16_MAX - 1);
  P(UINT16_MAX - 1 > 0);
  P(UINT16_MAX + 1 > 0);
  P(UINT16_MAX + 1u);
  P(UINT16_MAX - 1u);
  P(UINT16_MAX + 1l);
  P(UINT16_MAX - 1ul);
  { int p = -1; P(UINT16_MAX < p); }
  { int p = -1; P(UINT16_MAX > p); }
  { int p = -1; P(UINT16_MAX == p); }
  { int p = -1; P(UINT16_MAX != p); }
  { int p = -1; P(UINT16_MAX <= p); }
  { int p = -1; P(UINT16_MAX >= p); }
  { int p = -1; P(p < UINT16_MAX); }
  { int p = -1; P(p > UINT16_MAX); }
  { int p = -1; P(p == UINT16_MAX); }
  { int p = -1; P(p <= UINT16_MAX); }
  { int p = -1; P(UINT16_MAX + p); }
  { int p = -1; P(p + UINT16_MAX); }
  { int p = -1; P(UINT16_MAX - p); }
  { int p = -1; P(p - UINT16_MAX); }
  { int p = -1; P(UINT16_MAX * p); }
  { int p = -1; P(p * UINT16_MAX); }
  { int p = -1; P(UINT16_MAX & p); }
  { int p = -1; P(UINT16_MAX | p); }
  { int p = -1; P(UINT16_MAX ^ p); }
  { int p = -1; P(p & UINT16_MAX); }
  { int p = -1; P(p | UINT16_MAX); }
  { int p = -1; P(1 ? UINT16_MAX : p); }
  { int p = -1; P(1 ? p : UINT16_MAX); }
  { int p = -1; P(0 ? UINT16_MAX : p); }
  { int p = -1; P(TC(UINT16_MAX + p)); }
  { int p = -1; P(TC(p + UINT16_MAX)); }
  { int p = -1; P(TC(1 ? UINT16_MAX : p)); }
  { int p = -1; P(sizeof(UINT16_MAX + p)); }
  { int p = -1; int t = p; t += UINT16_MAX; P(t); }
  { int p = -1; int t = p; t -= UINT16_MAX; P(t); }
  { int p = -1; int t = p; t &= UINT16_MAX; P(t); }
  { int p = -1; int t = p; t |= UINT16_MAX; P(t); }
  { unsigned p = -1; P(UINT16_MAX < p); }
  { unsigned p = -1; P(UINT16_MAX > p); }
  { unsigned p = -1; P(UINT16_MAX == p); }
  { unsigned p = -1; P(UINT16_MAX != p); }
  { unsigned p = -1; P(UINT16_MAX <= p); }
  { unsigned p = -1; P(UINT16_MAX >= p); }
  { unsigned p = -1; P(p < UINT16_MAX); }
  { unsigned p = -1; P(p > UINT16_MAX); }
  { unsigned p = -1; P(p == UINT16_MAX); }
  { unsigned p = -1; P(p <= UINT16_MAX); }
  { unsigned p = -1; P(UINT16_MAX + p); }
  { unsigned p = -1; P(p + UINT16_MAX); }
  { unsigned p = -1; P(UINT16_MAX - p); }
  { unsigned p = -1; P(p - UINT16_MAX); }
  { unsigned p = -1; P(UINT16_MAX * p); }
  { unsigned p = -1; P(p * UINT16_MAX); }
  { unsigned p = -1; P(UINT16_MAX & p); }
  { unsigned p = -1; P(UINT16_MAX | p); }
  { unsigned p = -1; P(UINT16_MAX ^ p); }
  { unsigned p = -1; P(p & UINT16_MAX); }
  { unsigned p = -1; P(p | UINT16_MAX); }
  { unsigned p = -1; P(1 ? UINT16_MAX : p); }
  { unsigned p = -1; P(1 ? p : UINT16_MAX); }
  { unsigned p = -1; P(0 ? UINT16_MAX : p); }
  { unsigned p = -1; P(TC(UINT16_MAX + p)); }
  { unsigned p = -1; P(TC(p + UINT16_MAX)); }
  { unsigned p = -1; P(TC(1 ? UINT16_MAX : p)); }
  { unsigned p = -1; P(sizeof(UINT16_MAX + p)); }
  { unsigned p = -1; P(UINT16_MAX / p); }
  { unsigned p = -1; P(UINT16_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UINT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UINT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UINT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UINT16_MAX; P(t); }
  { long p = -1; P(UINT16_MAX < p); }
  { long p = -1; P(UINT16_MAX > p); }
  { long p = -1; P(UINT16_MAX == p); }
  { long p = -1; P(UINT16_MAX != p); }
  { long p = -1; P(UINT16_MAX <= p); }
  { long p = -1; P(UINT16_MAX >= p); }
  { long p = -1; P(p < UINT16_MAX); }
  { long p = -1; P(p > UINT16_MAX); }
  { long p = -1; P(p == UINT16_MAX); }
  { long p = -1; P(p <= UINT16_MAX); }
  { long p = -1; P(UINT16_MAX + p); }
  { long p = -1; P(p + UINT16_MAX); }
  { long p = -1; P(UINT16_MAX - p); }
  { long p = -1; P(p - UINT16_MAX); }
  { long p = -1; P(UINT16_MAX * p); }
  { long p = -1; P(p * UINT16_MAX); }
  { long p = -1; P(UINT16_MAX & p); }
  { long p = -1; P(UINT16_MAX | p); }
  { long p = -1; P(UINT16_MAX ^ p); }
  { long p = -1; P(p & UINT16_MAX); }
  { long p = -1; P(p | UINT16_MAX); }
  { long p = -1; P(1 ? UINT16_MAX : p); }
  { long p = -1; P(1 ? p : UINT16_MAX); }
  { long p = -1; P(0 ? UINT16_MAX : p); }
  { long p = -1; P(TC(UINT16_MAX + p)); }
  { long p = -1; P(TC(p + UINT16_MAX)); }
  { long p = -1; P(TC(1 ? UINT16_MAX : p)); }
  { long p = -1; P(sizeof(UINT16_MAX + p)); }
  { long p = -1; long t = p; t += UINT16_MAX; P(t); }
  { long p = -1; long t = p; t -= UINT16_MAX; P(t); }
  { long p = -1; long t = p; t &= UINT16_MAX; P(t); }
  { long p = -1; long t = p; t |= UINT16_MAX; P(t); }
  { unsigned long p = -1; P(UINT16_MAX < p); }
  { unsigned long p = -1; P(UINT16_MAX > p); }
  { unsigned long p = -1; P(UINT16_MAX == p); }
  { unsigned long p = -1; P(UINT16_MAX != p); }
  { unsigned long p = -1; P(UINT16_MAX <= p); }
  { unsigned long p = -1; P(UINT16_MAX >= p); }
  { unsigned long p = -1; P(p < UINT16_MAX); }
  { unsigned long p = -1; P(p > UINT16_MAX); }
  { unsigned long p = -1; P(p == UINT16_MAX); }
  { unsigned long p = -1; P(p <= UINT16_MAX); }
  { unsigned long p = -1; P(UINT16_MAX + p); }
  { unsigned long p = -1; P(p + UINT16_MAX); }
  { unsigned long p = -1; P(UINT16_MAX - p); }
  { unsigned long p = -1; P(p - UINT16_MAX); }
  { unsigned long p = -1; P(UINT16_MAX * p); }
  { unsigned long p = -1; P(p * UINT16_MAX); }
  { unsigned long p = -1; P(UINT16_MAX & p); }
  { unsigned long p = -1; P(UINT16_MAX | p); }
  { unsigned long p = -1; P(UINT16_MAX ^ p); }
  { unsigned long p = -1; P(p & UINT16_MAX); }
  { unsigned long p = -1; P(p | UINT16_MAX); }
  { unsigned long p = -1; P(1 ? UINT16_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UINT16_MAX); }
  { unsigned long p = -1; P(0 ? UINT16_MAX : p); }
  { unsigned long p = -1; P(TC(UINT16_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UINT16_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UINT16_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UINT16_MAX + p)); }
  { unsigned long p = -1; P(UINT16_MAX / p); }
  { unsigned long p = -1; P(UINT16_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UINT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UINT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UINT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UINT16_MAX; P(t); }
  P(UINT32_MAX > 0);
  P(UINT32_MAX < 0);
  P(UINT32_MAX == 0);
  P(UINT32_MAX != 0);
  P(UINT32_MAX >= 0);
  P(UINT32_MAX <= 0);
  printf("\n");
  return 0;
}
