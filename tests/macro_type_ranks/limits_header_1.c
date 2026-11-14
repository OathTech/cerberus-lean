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
#undef INT16_MAX
#define INT16_MAX SHRT_MAX
#undef INT16_MIN
#define INT16_MIN SHRT_MIN
#undef INT32_MAX
#define INT32_MAX INT_MAX
#undef INT32_MIN
#define INT32_MIN INT_MIN
#undef INT64_MAX
#define INT64_MAX LLONG_MAX
#endif
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(CHAR_BIT > 0);
  P(CHAR_BIT < 0);
  P(CHAR_BIT == 0);
  P(CHAR_BIT != 0);
  P(CHAR_BIT >= 0);
  P(CHAR_BIT <= 0);
  P(0 < CHAR_BIT);
  P(0 > CHAR_BIT);
  P(0 == CHAR_BIT);
  P(+CHAR_BIT);
  P(-CHAR_BIT);
  P(~CHAR_BIT);
  P(!CHAR_BIT);
  P((+CHAR_BIT) > 0);
  P(sizeof(CHAR_BIT));
  P(sizeof(+CHAR_BIT));
  P(TC(CHAR_BIT));
  P(TC(+CHAR_BIT));
  P(TC(-CHAR_BIT));
  P(TC(~CHAR_BIT));
  P((_Bool)CHAR_BIT);
  P((signed char)CHAR_BIT);
  P((unsigned char)CHAR_BIT);
  P((short)CHAR_BIT);
  P((unsigned short)CHAR_BIT);
  P((int)CHAR_BIT);
  P((unsigned)CHAR_BIT);
  P((long)CHAR_BIT);
  P((unsigned long)CHAR_BIT);
  P((long long)CHAR_BIT);
  P((unsigned long long)CHAR_BIT);
  P((long long)CHAR_BIT > 0);
  P((long long)CHAR_BIT < 0);
  { int x = CHAR_BIT; P(x); }
  { unsigned x = CHAR_BIT; P(x); }
  { long x = CHAR_BIT; P(x); }
  { unsigned long x = CHAR_BIT; P(x); }
  P(CHAR_BIT + 1);
  P(CHAR_BIT - 1);
  P(CHAR_BIT - 1 > 0);
  P(CHAR_BIT + 1 > 0);
  P(CHAR_BIT + 1u);
  P(CHAR_BIT - 1u);
  P(CHAR_BIT + 1l);
  P(CHAR_BIT - 1ul);
  { int p = -1; P(CHAR_BIT < p); }
  { int p = -1; P(CHAR_BIT > p); }
  { int p = -1; P(CHAR_BIT == p); }
  { int p = -1; P(CHAR_BIT != p); }
  { int p = -1; P(CHAR_BIT <= p); }
  { int p = -1; P(CHAR_BIT >= p); }
  { int p = -1; P(p < CHAR_BIT); }
  { int p = -1; P(p > CHAR_BIT); }
  { int p = -1; P(p == CHAR_BIT); }
  { int p = -1; P(p <= CHAR_BIT); }
  { int p = -1; P(CHAR_BIT + p); }
  { int p = -1; P(p + CHAR_BIT); }
  { int p = -1; P(CHAR_BIT - p); }
  { int p = -1; P(p - CHAR_BIT); }
  { int p = -1; P(CHAR_BIT * p); }
  { int p = -1; P(p * CHAR_BIT); }
  { int p = -1; P(CHAR_BIT & p); }
  { int p = -1; P(CHAR_BIT | p); }
  { int p = -1; P(CHAR_BIT ^ p); }
  { int p = -1; P(p & CHAR_BIT); }
  { int p = -1; P(p | CHAR_BIT); }
  { int p = -1; P(1 ? CHAR_BIT : p); }
  { int p = -1; P(1 ? p : CHAR_BIT); }
  { int p = -1; P(0 ? CHAR_BIT : p); }
  { int p = -1; P(TC(CHAR_BIT + p)); }
  { int p = -1; P(TC(p + CHAR_BIT)); }
  { int p = -1; P(TC(1 ? CHAR_BIT : p)); }
  { int p = -1; P(sizeof(CHAR_BIT + p)); }
  { int p = -1; int t = p; t += CHAR_BIT; P(t); }
  { int p = -1; int t = p; t -= CHAR_BIT; P(t); }
  { int p = -1; int t = p; t &= CHAR_BIT; P(t); }
  { int p = -1; int t = p; t |= CHAR_BIT; P(t); }
  { unsigned p = -1; P(CHAR_BIT < p); }
  { unsigned p = -1; P(CHAR_BIT > p); }
  { unsigned p = -1; P(CHAR_BIT == p); }
  { unsigned p = -1; P(CHAR_BIT != p); }
  { unsigned p = -1; P(CHAR_BIT <= p); }
  { unsigned p = -1; P(CHAR_BIT >= p); }
  { unsigned p = -1; P(p < CHAR_BIT); }
  { unsigned p = -1; P(p > CHAR_BIT); }
  { unsigned p = -1; P(p == CHAR_BIT); }
  { unsigned p = -1; P(p <= CHAR_BIT); }
  { unsigned p = -1; P(CHAR_BIT + p); }
  { unsigned p = -1; P(p + CHAR_BIT); }
  { unsigned p = -1; P(CHAR_BIT - p); }
  { unsigned p = -1; P(p - CHAR_BIT); }
  { unsigned p = -1; P(CHAR_BIT * p); }
  { unsigned p = -1; P(p * CHAR_BIT); }
  { unsigned p = -1; P(CHAR_BIT & p); }
  { unsigned p = -1; P(CHAR_BIT | p); }
  { unsigned p = -1; P(CHAR_BIT ^ p); }
  { unsigned p = -1; P(p & CHAR_BIT); }
  { unsigned p = -1; P(p | CHAR_BIT); }
  { unsigned p = -1; P(1 ? CHAR_BIT : p); }
  { unsigned p = -1; P(1 ? p : CHAR_BIT); }
  { unsigned p = -1; P(0 ? CHAR_BIT : p); }
  { unsigned p = -1; P(TC(CHAR_BIT + p)); }
  { unsigned p = -1; P(TC(p + CHAR_BIT)); }
  { unsigned p = -1; P(TC(1 ? CHAR_BIT : p)); }
  { unsigned p = -1; P(sizeof(CHAR_BIT + p)); }
  { unsigned p = -1; P(CHAR_BIT / p); }
  { unsigned p = -1; P(CHAR_BIT % p); }
  { unsigned p = -1; unsigned t = p; t += CHAR_BIT; P(t); }
  { unsigned p = -1; unsigned t = p; t -= CHAR_BIT; P(t); }
  { unsigned p = -1; unsigned t = p; t &= CHAR_BIT; P(t); }
  { unsigned p = -1; unsigned t = p; t |= CHAR_BIT; P(t); }
  { long p = -1; P(CHAR_BIT < p); }
  { long p = -1; P(CHAR_BIT > p); }
  { long p = -1; P(CHAR_BIT == p); }
  { long p = -1; P(CHAR_BIT != p); }
  { long p = -1; P(CHAR_BIT <= p); }
  { long p = -1; P(CHAR_BIT >= p); }
  { long p = -1; P(p < CHAR_BIT); }
  { long p = -1; P(p > CHAR_BIT); }
  { long p = -1; P(p == CHAR_BIT); }
  { long p = -1; P(p <= CHAR_BIT); }
  { long p = -1; P(CHAR_BIT + p); }
  { long p = -1; P(p + CHAR_BIT); }
  { long p = -1; P(CHAR_BIT - p); }
  { long p = -1; P(p - CHAR_BIT); }
  { long p = -1; P(CHAR_BIT * p); }
  { long p = -1; P(p * CHAR_BIT); }
  { long p = -1; P(CHAR_BIT & p); }
  { long p = -1; P(CHAR_BIT | p); }
  { long p = -1; P(CHAR_BIT ^ p); }
  { long p = -1; P(p & CHAR_BIT); }
  { long p = -1; P(p | CHAR_BIT); }
  { long p = -1; P(1 ? CHAR_BIT : p); }
  { long p = -1; P(1 ? p : CHAR_BIT); }
  { long p = -1; P(0 ? CHAR_BIT : p); }
  { long p = -1; P(TC(CHAR_BIT + p)); }
  { long p = -1; P(TC(p + CHAR_BIT)); }
  { long p = -1; P(TC(1 ? CHAR_BIT : p)); }
  { long p = -1; P(sizeof(CHAR_BIT + p)); }
  { long p = -1; long t = p; t += CHAR_BIT; P(t); }
  { long p = -1; long t = p; t -= CHAR_BIT; P(t); }
  { long p = -1; long t = p; t &= CHAR_BIT; P(t); }
  { long p = -1; long t = p; t |= CHAR_BIT; P(t); }
  { unsigned long p = -1; P(CHAR_BIT < p); }
  { unsigned long p = -1; P(CHAR_BIT > p); }
  { unsigned long p = -1; P(CHAR_BIT == p); }
  { unsigned long p = -1; P(CHAR_BIT != p); }
  { unsigned long p = -1; P(CHAR_BIT <= p); }
  { unsigned long p = -1; P(CHAR_BIT >= p); }
  { unsigned long p = -1; P(p < CHAR_BIT); }
  { unsigned long p = -1; P(p > CHAR_BIT); }
  { unsigned long p = -1; P(p == CHAR_BIT); }
  { unsigned long p = -1; P(p <= CHAR_BIT); }
  { unsigned long p = -1; P(CHAR_BIT + p); }
  { unsigned long p = -1; P(p + CHAR_BIT); }
  { unsigned long p = -1; P(CHAR_BIT - p); }
  { unsigned long p = -1; P(p - CHAR_BIT); }
  { unsigned long p = -1; P(CHAR_BIT * p); }
  { unsigned long p = -1; P(p * CHAR_BIT); }
  { unsigned long p = -1; P(CHAR_BIT & p); }
  { unsigned long p = -1; P(CHAR_BIT | p); }
  { unsigned long p = -1; P(CHAR_BIT ^ p); }
  { unsigned long p = -1; P(p & CHAR_BIT); }
  { unsigned long p = -1; P(p | CHAR_BIT); }
  { unsigned long p = -1; P(1 ? CHAR_BIT : p); }
  { unsigned long p = -1; P(1 ? p : CHAR_BIT); }
  { unsigned long p = -1; P(0 ? CHAR_BIT : p); }
  { unsigned long p = -1; P(TC(CHAR_BIT + p)); }
  { unsigned long p = -1; P(TC(p + CHAR_BIT)); }
  { unsigned long p = -1; P(TC(1 ? CHAR_BIT : p)); }
  { unsigned long p = -1; P(sizeof(CHAR_BIT + p)); }
  { unsigned long p = -1; P(CHAR_BIT / p); }
  { unsigned long p = -1; P(CHAR_BIT % p); }
  { unsigned long p = -1; unsigned long t = p; t += CHAR_BIT; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= CHAR_BIT; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= CHAR_BIT; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= CHAR_BIT; P(t); }
  P(CHAR_MAX > 0);
  P(CHAR_MAX < 0);
  P(CHAR_MAX == 0);
  P(CHAR_MAX != 0);
  P(CHAR_MAX >= 0);
  P(CHAR_MAX <= 0);
  P(0 < CHAR_MAX);
  P(0 > CHAR_MAX);
  P(0 == CHAR_MAX);
  P(+CHAR_MAX);
  P(-CHAR_MAX);
  P(~CHAR_MAX);
  P(!CHAR_MAX);
  P((+CHAR_MAX) > 0);
  P(sizeof(+CHAR_MAX));
  P(TC(+CHAR_MAX));
  P(TC(-CHAR_MAX));
  P(TC(~CHAR_MAX));
  P((_Bool)CHAR_MAX);
  P((signed char)CHAR_MAX);
  P((unsigned char)CHAR_MAX);
  P((short)CHAR_MAX);
  P((unsigned short)CHAR_MAX);
  P((int)CHAR_MAX);
  P((unsigned)CHAR_MAX);
  P((long)CHAR_MAX);
  P((unsigned long)CHAR_MAX);
  P((long long)CHAR_MAX);
  P((unsigned long long)CHAR_MAX);
  P((long long)CHAR_MAX > 0);
  P((long long)CHAR_MAX < 0);
  { int x = CHAR_MAX; P(x); }
  { unsigned x = CHAR_MAX; P(x); }
  { long x = CHAR_MAX; P(x); }
  { unsigned long x = CHAR_MAX; P(x); }
  P(CHAR_MAX + 1);
  P(CHAR_MAX - 1);
  P(CHAR_MAX - 1 > 0);
  P(CHAR_MAX + 1 > 0);
  P(CHAR_MAX + 1u);
  P(CHAR_MAX - 1u);
  P(CHAR_MAX + 1l);
  P(CHAR_MAX - 1ul);
  { int p = -1; P(CHAR_MAX < p); }
  { int p = -1; P(CHAR_MAX > p); }
  { int p = -1; P(CHAR_MAX == p); }
  { int p = -1; P(CHAR_MAX != p); }
  { int p = -1; P(CHAR_MAX <= p); }
  { int p = -1; P(CHAR_MAX >= p); }
  { int p = -1; P(p < CHAR_MAX); }
  { int p = -1; P(p > CHAR_MAX); }
  { int p = -1; P(p == CHAR_MAX); }
  { int p = -1; P(p <= CHAR_MAX); }
  { int p = -1; P(CHAR_MAX + p); }
  { int p = -1; P(p + CHAR_MAX); }
  { int p = -1; P(CHAR_MAX - p); }
  { int p = -1; P(p - CHAR_MAX); }
  { int p = -1; P(CHAR_MAX * p); }
  { int p = -1; P(p * CHAR_MAX); }
  { int p = -1; P(CHAR_MAX & p); }
  { int p = -1; P(CHAR_MAX | p); }
  { int p = -1; P(CHAR_MAX ^ p); }
  { int p = -1; P(p & CHAR_MAX); }
  { int p = -1; P(p | CHAR_MAX); }
  { int p = -1; P(1 ? CHAR_MAX : p); }
  { int p = -1; P(1 ? p : CHAR_MAX); }
  { int p = -1; P(0 ? CHAR_MAX : p); }
  { int p = -1; P(TC(CHAR_MAX + p)); }
  { int p = -1; P(TC(p + CHAR_MAX)); }
  { int p = -1; P(TC(1 ? CHAR_MAX : p)); }
  { int p = -1; P(sizeof(CHAR_MAX + p)); }
  { int p = -1; int t = p; t += CHAR_MAX; P(t); }
  { int p = -1; int t = p; t -= CHAR_MAX; P(t); }
  { int p = -1; int t = p; t &= CHAR_MAX; P(t); }
  { int p = -1; int t = p; t |= CHAR_MAX; P(t); }
  { unsigned p = -1; P(CHAR_MAX < p); }
  { unsigned p = -1; P(CHAR_MAX > p); }
  { unsigned p = -1; P(CHAR_MAX == p); }
  { unsigned p = -1; P(CHAR_MAX != p); }
  { unsigned p = -1; P(CHAR_MAX <= p); }
  { unsigned p = -1; P(CHAR_MAX >= p); }
  { unsigned p = -1; P(p < CHAR_MAX); }
  { unsigned p = -1; P(p > CHAR_MAX); }
  { unsigned p = -1; P(p == CHAR_MAX); }
  { unsigned p = -1; P(p <= CHAR_MAX); }
  { unsigned p = -1; P(CHAR_MAX + p); }
  { unsigned p = -1; P(p + CHAR_MAX); }
  { unsigned p = -1; P(CHAR_MAX - p); }
  { unsigned p = -1; P(p - CHAR_MAX); }
  { unsigned p = -1; P(CHAR_MAX * p); }
  { unsigned p = -1; P(p * CHAR_MAX); }
  { unsigned p = -1; P(CHAR_MAX & p); }
  { unsigned p = -1; P(CHAR_MAX | p); }
  { unsigned p = -1; P(CHAR_MAX ^ p); }
  { unsigned p = -1; P(p & CHAR_MAX); }
  { unsigned p = -1; P(p | CHAR_MAX); }
  { unsigned p = -1; P(1 ? CHAR_MAX : p); }
  { unsigned p = -1; P(1 ? p : CHAR_MAX); }
  { unsigned p = -1; P(0 ? CHAR_MAX : p); }
  { unsigned p = -1; P(TC(CHAR_MAX + p)); }
  { unsigned p = -1; P(TC(p + CHAR_MAX)); }
  { unsigned p = -1; P(TC(1 ? CHAR_MAX : p)); }
  { unsigned p = -1; P(sizeof(CHAR_MAX + p)); }
  { unsigned p = -1; P(CHAR_MAX / p); }
  { unsigned p = -1; P(CHAR_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += CHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= CHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= CHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= CHAR_MAX; P(t); }
  { long p = -1; P(CHAR_MAX < p); }
  { long p = -1; P(CHAR_MAX > p); }
  { long p = -1; P(CHAR_MAX == p); }
  { long p = -1; P(CHAR_MAX != p); }
  { long p = -1; P(CHAR_MAX <= p); }
  { long p = -1; P(CHAR_MAX >= p); }
  { long p = -1; P(p < CHAR_MAX); }
  { long p = -1; P(p > CHAR_MAX); }
  { long p = -1; P(p == CHAR_MAX); }
  { long p = -1; P(p <= CHAR_MAX); }
  { long p = -1; P(CHAR_MAX + p); }
  { long p = -1; P(p + CHAR_MAX); }
  { long p = -1; P(CHAR_MAX - p); }
  { long p = -1; P(p - CHAR_MAX); }
  { long p = -1; P(CHAR_MAX * p); }
  { long p = -1; P(p * CHAR_MAX); }
  { long p = -1; P(CHAR_MAX & p); }
  { long p = -1; P(CHAR_MAX | p); }
  { long p = -1; P(CHAR_MAX ^ p); }
  { long p = -1; P(p & CHAR_MAX); }
  { long p = -1; P(p | CHAR_MAX); }
  { long p = -1; P(1 ? CHAR_MAX : p); }
  { long p = -1; P(1 ? p : CHAR_MAX); }
  { long p = -1; P(0 ? CHAR_MAX : p); }
  { long p = -1; P(TC(CHAR_MAX + p)); }
  { long p = -1; P(TC(p + CHAR_MAX)); }
  { long p = -1; P(TC(1 ? CHAR_MAX : p)); }
  { long p = -1; P(sizeof(CHAR_MAX + p)); }
  { long p = -1; long t = p; t += CHAR_MAX; P(t); }
  { long p = -1; long t = p; t -= CHAR_MAX; P(t); }
  { long p = -1; long t = p; t &= CHAR_MAX; P(t); }
  { long p = -1; long t = p; t |= CHAR_MAX; P(t); }
  { unsigned long p = -1; P(CHAR_MAX < p); }
  { unsigned long p = -1; P(CHAR_MAX > p); }
  { unsigned long p = -1; P(CHAR_MAX == p); }
  { unsigned long p = -1; P(CHAR_MAX != p); }
  { unsigned long p = -1; P(CHAR_MAX <= p); }
  { unsigned long p = -1; P(CHAR_MAX >= p); }
  { unsigned long p = -1; P(p < CHAR_MAX); }
  { unsigned long p = -1; P(p > CHAR_MAX); }
  { unsigned long p = -1; P(p == CHAR_MAX); }
  { unsigned long p = -1; P(p <= CHAR_MAX); }
  { unsigned long p = -1; P(CHAR_MAX + p); }
  { unsigned long p = -1; P(p + CHAR_MAX); }
  { unsigned long p = -1; P(CHAR_MAX - p); }
  { unsigned long p = -1; P(p - CHAR_MAX); }
  { unsigned long p = -1; P(CHAR_MAX * p); }
  { unsigned long p = -1; P(p * CHAR_MAX); }
  { unsigned long p = -1; P(CHAR_MAX & p); }
  { unsigned long p = -1; P(CHAR_MAX | p); }
  { unsigned long p = -1; P(CHAR_MAX ^ p); }
  { unsigned long p = -1; P(p & CHAR_MAX); }
  { unsigned long p = -1; P(p | CHAR_MAX); }
  { unsigned long p = -1; P(1 ? CHAR_MAX : p); }
  { unsigned long p = -1; P(1 ? p : CHAR_MAX); }
  { unsigned long p = -1; P(0 ? CHAR_MAX : p); }
  { unsigned long p = -1; P(TC(CHAR_MAX + p)); }
  { unsigned long p = -1; P(TC(p + CHAR_MAX)); }
  { unsigned long p = -1; P(TC(1 ? CHAR_MAX : p)); }
  { unsigned long p = -1; P(sizeof(CHAR_MAX + p)); }
  { unsigned long p = -1; P(CHAR_MAX / p); }
  { unsigned long p = -1; P(CHAR_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += CHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= CHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= CHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= CHAR_MAX; P(t); }
  P(CHAR_MIN > 0);
  P(CHAR_MIN < 0);
  P(CHAR_MIN == 0);
  P(CHAR_MIN != 0);
  P(CHAR_MIN >= 0);
  P(CHAR_MIN <= 0);
  P(0 < CHAR_MIN);
  P(0 > CHAR_MIN);
  P(0 == CHAR_MIN);
  P(+CHAR_MIN);
  P(-CHAR_MIN);
  P(~CHAR_MIN);
  P(!CHAR_MIN);
  P((+CHAR_MIN) > 0);
  P(sizeof(+CHAR_MIN));
  P(TC(+CHAR_MIN));
  P(TC(-CHAR_MIN));
  P(TC(~CHAR_MIN));
  P((_Bool)CHAR_MIN);
  P((signed char)CHAR_MIN);
  P((unsigned char)CHAR_MIN);
  P((short)CHAR_MIN);
  P((unsigned short)CHAR_MIN);
  P((int)CHAR_MIN);
  P((unsigned)CHAR_MIN);
  P((long)CHAR_MIN);
  P((unsigned long)CHAR_MIN);
  P((long long)CHAR_MIN);
  P((unsigned long long)CHAR_MIN);
  P((long long)CHAR_MIN > 0);
  P((long long)CHAR_MIN < 0);
  { int x = CHAR_MIN; P(x); }
  { unsigned x = CHAR_MIN; P(x); }
  { long x = CHAR_MIN; P(x); }
  { unsigned long x = CHAR_MIN; P(x); }
  P(CHAR_MIN + 1);
  P(CHAR_MIN - 1);
  P(CHAR_MIN - 1 > 0);
  P(CHAR_MIN + 1 > 0);
  P(CHAR_MIN + 1u);
  P(CHAR_MIN - 1u);
  P(CHAR_MIN + 1l);
  P(CHAR_MIN - 1ul);
  { int p = -1; P(CHAR_MIN < p); }
  { int p = -1; P(CHAR_MIN > p); }
  { int p = -1; P(CHAR_MIN == p); }
  { int p = -1; P(CHAR_MIN != p); }
  { int p = -1; P(CHAR_MIN <= p); }
  { int p = -1; P(CHAR_MIN >= p); }
  { int p = -1; P(p < CHAR_MIN); }
  { int p = -1; P(p > CHAR_MIN); }
  { int p = -1; P(p == CHAR_MIN); }
  { int p = -1; P(p <= CHAR_MIN); }
  { int p = -1; P(CHAR_MIN + p); }
  { int p = -1; P(p + CHAR_MIN); }
  { int p = -1; P(CHAR_MIN - p); }
  { int p = -1; P(p - CHAR_MIN); }
  { int p = -1; P(CHAR_MIN * p); }
  { int p = -1; P(p * CHAR_MIN); }
  { int p = -1; P(CHAR_MIN & p); }
  { int p = -1; P(CHAR_MIN | p); }
  { int p = -1; P(CHAR_MIN ^ p); }
  { int p = -1; P(p & CHAR_MIN); }
  { int p = -1; P(p | CHAR_MIN); }
  { int p = -1; P(1 ? CHAR_MIN : p); }
  { int p = -1; P(1 ? p : CHAR_MIN); }
  { int p = -1; P(0 ? CHAR_MIN : p); }
  { int p = -1; P(TC(CHAR_MIN + p)); }
  { int p = -1; P(TC(p + CHAR_MIN)); }
  { int p = -1; P(TC(1 ? CHAR_MIN : p)); }
  { int p = -1; P(sizeof(CHAR_MIN + p)); }
  { int p = -1; int t = p; t += CHAR_MIN; P(t); }
  { int p = -1; int t = p; t -= CHAR_MIN; P(t); }
  { int p = -1; int t = p; t &= CHAR_MIN; P(t); }
  { int p = -1; int t = p; t |= CHAR_MIN; P(t); }
  { unsigned p = -1; P(CHAR_MIN < p); }
  { unsigned p = -1; P(CHAR_MIN > p); }
  { unsigned p = -1; P(CHAR_MIN == p); }
  { unsigned p = -1; P(CHAR_MIN != p); }
  { unsigned p = -1; P(CHAR_MIN <= p); }
  { unsigned p = -1; P(CHAR_MIN >= p); }
  { unsigned p = -1; P(p < CHAR_MIN); }
  { unsigned p = -1; P(p > CHAR_MIN); }
  { unsigned p = -1; P(p == CHAR_MIN); }
  { unsigned p = -1; P(p <= CHAR_MIN); }
  { unsigned p = -1; P(CHAR_MIN + p); }
  { unsigned p = -1; P(p + CHAR_MIN); }
  { unsigned p = -1; P(CHAR_MIN - p); }
  { unsigned p = -1; P(p - CHAR_MIN); }
  { unsigned p = -1; P(CHAR_MIN * p); }
  { unsigned p = -1; P(p * CHAR_MIN); }
  { unsigned p = -1; P(CHAR_MIN & p); }
  { unsigned p = -1; P(CHAR_MIN | p); }
  { unsigned p = -1; P(CHAR_MIN ^ p); }
  { unsigned p = -1; P(p & CHAR_MIN); }
  { unsigned p = -1; P(p | CHAR_MIN); }
  { unsigned p = -1; P(1 ? CHAR_MIN : p); }
  { unsigned p = -1; P(1 ? p : CHAR_MIN); }
  { unsigned p = -1; P(0 ? CHAR_MIN : p); }
  { unsigned p = -1; P(TC(CHAR_MIN + p)); }
  { unsigned p = -1; P(TC(p + CHAR_MIN)); }
  { unsigned p = -1; P(TC(1 ? CHAR_MIN : p)); }
  { unsigned p = -1; P(sizeof(CHAR_MIN + p)); }
  { unsigned p = -1; P(CHAR_MIN / p); }
  { unsigned p = -1; P(CHAR_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += CHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= CHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= CHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= CHAR_MIN; P(t); }
  { long p = -1; P(CHAR_MIN < p); }
  { long p = -1; P(CHAR_MIN > p); }
  { long p = -1; P(CHAR_MIN == p); }
  { long p = -1; P(CHAR_MIN != p); }
  { long p = -1; P(CHAR_MIN <= p); }
  { long p = -1; P(CHAR_MIN >= p); }
  { long p = -1; P(p < CHAR_MIN); }
  { long p = -1; P(p > CHAR_MIN); }
  { long p = -1; P(p == CHAR_MIN); }
  { long p = -1; P(p <= CHAR_MIN); }
  { long p = -1; P(CHAR_MIN + p); }
  { long p = -1; P(p + CHAR_MIN); }
  { long p = -1; P(CHAR_MIN - p); }
  { long p = -1; P(p - CHAR_MIN); }
  { long p = -1; P(CHAR_MIN * p); }
  { long p = -1; P(p * CHAR_MIN); }
  { long p = -1; P(CHAR_MIN & p); }
  { long p = -1; P(CHAR_MIN | p); }
  { long p = -1; P(CHAR_MIN ^ p); }
  { long p = -1; P(p & CHAR_MIN); }
  { long p = -1; P(p | CHAR_MIN); }
  { long p = -1; P(1 ? CHAR_MIN : p); }
  { long p = -1; P(1 ? p : CHAR_MIN); }
  { long p = -1; P(0 ? CHAR_MIN : p); }
  { long p = -1; P(TC(CHAR_MIN + p)); }
  { long p = -1; P(TC(p + CHAR_MIN)); }
  { long p = -1; P(TC(1 ? CHAR_MIN : p)); }
  { long p = -1; P(sizeof(CHAR_MIN + p)); }
  { long p = -1; long t = p; t += CHAR_MIN; P(t); }
  { long p = -1; long t = p; t -= CHAR_MIN; P(t); }
  { long p = -1; long t = p; t &= CHAR_MIN; P(t); }
  { long p = -1; long t = p; t |= CHAR_MIN; P(t); }
  { unsigned long p = -1; P(CHAR_MIN < p); }
  { unsigned long p = -1; P(CHAR_MIN > p); }
  { unsigned long p = -1; P(CHAR_MIN == p); }
  { unsigned long p = -1; P(CHAR_MIN != p); }
  { unsigned long p = -1; P(CHAR_MIN <= p); }
  { unsigned long p = -1; P(CHAR_MIN >= p); }
  { unsigned long p = -1; P(p < CHAR_MIN); }
  { unsigned long p = -1; P(p > CHAR_MIN); }
  { unsigned long p = -1; P(p == CHAR_MIN); }
  { unsigned long p = -1; P(p <= CHAR_MIN); }
  { unsigned long p = -1; P(CHAR_MIN + p); }
  { unsigned long p = -1; P(p + CHAR_MIN); }
  { unsigned long p = -1; P(CHAR_MIN - p); }
  { unsigned long p = -1; P(p - CHAR_MIN); }
  { unsigned long p = -1; P(CHAR_MIN * p); }
  { unsigned long p = -1; P(p * CHAR_MIN); }
  { unsigned long p = -1; P(CHAR_MIN & p); }
  { unsigned long p = -1; P(CHAR_MIN | p); }
  { unsigned long p = -1; P(CHAR_MIN ^ p); }
  { unsigned long p = -1; P(p & CHAR_MIN); }
  { unsigned long p = -1; P(p | CHAR_MIN); }
  { unsigned long p = -1; P(1 ? CHAR_MIN : p); }
  { unsigned long p = -1; P(1 ? p : CHAR_MIN); }
  { unsigned long p = -1; P(0 ? CHAR_MIN : p); }
  { unsigned long p = -1; P(TC(CHAR_MIN + p)); }
  { unsigned long p = -1; P(TC(p + CHAR_MIN)); }
  { unsigned long p = -1; P(TC(1 ? CHAR_MIN : p)); }
  { unsigned long p = -1; P(sizeof(CHAR_MIN + p)); }
  { unsigned long p = -1; P(CHAR_MIN / p); }
  { unsigned long p = -1; P(CHAR_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += CHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= CHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= CHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= CHAR_MIN; P(t); }
  P(INT16_MAX > 0);
  P(INT16_MAX < 0);
  P(INT16_MAX == 0);
  P(INT16_MAX != 0);
  P(INT16_MAX >= 0);
  P(INT16_MAX <= 0);
  P(0 < INT16_MAX);
  P(0 > INT16_MAX);
  P(0 == INT16_MAX);
  P(+INT16_MAX);
  P(-INT16_MAX);
  P(~INT16_MAX);
  P(!INT16_MAX);
  P((+INT16_MAX) > 0);
  P(sizeof(+INT16_MAX));
  P(TC(+INT16_MAX));
  P(TC(-INT16_MAX));
  P(TC(~INT16_MAX));
  P((_Bool)INT16_MAX);
  P((signed char)INT16_MAX);
  P((unsigned char)INT16_MAX);
  P((short)INT16_MAX);
  P((unsigned short)INT16_MAX);
  P((int)INT16_MAX);
  P((unsigned)INT16_MAX);
  P((long)INT16_MAX);
  P((unsigned long)INT16_MAX);
  P((long long)INT16_MAX);
  P((unsigned long long)INT16_MAX);
  P((long long)INT16_MAX > 0);
  P((long long)INT16_MAX < 0);
  { int x = INT16_MAX; P(x); }
  { unsigned x = INT16_MAX; P(x); }
  { long x = INT16_MAX; P(x); }
  { unsigned long x = INT16_MAX; P(x); }
  P(INT16_MAX + 1);
  P(INT16_MAX - 1);
  P(INT16_MAX - 1 > 0);
  P(INT16_MAX + 1 > 0);
  P(INT16_MAX + 1u);
  P(INT16_MAX - 1u);
  P(INT16_MAX + 1l);
  P(INT16_MAX - 1ul);
  { int p = -1; P(INT16_MAX < p); }
  { int p = -1; P(INT16_MAX > p); }
  { int p = -1; P(INT16_MAX == p); }
  { int p = -1; P(INT16_MAX != p); }
  { int p = -1; P(INT16_MAX <= p); }
  { int p = -1; P(INT16_MAX >= p); }
  { int p = -1; P(p < INT16_MAX); }
  { int p = -1; P(p > INT16_MAX); }
  { int p = -1; P(p == INT16_MAX); }
  { int p = -1; P(p <= INT16_MAX); }
  { int p = -1; P(INT16_MAX + p); }
  { int p = -1; P(p + INT16_MAX); }
  { int p = -1; P(INT16_MAX - p); }
  { int p = -1; P(p - INT16_MAX); }
  { int p = -1; P(INT16_MAX * p); }
  { int p = -1; P(p * INT16_MAX); }
  { int p = -1; P(INT16_MAX & p); }
  { int p = -1; P(INT16_MAX | p); }
  { int p = -1; P(INT16_MAX ^ p); }
  { int p = -1; P(p & INT16_MAX); }
  { int p = -1; P(p | INT16_MAX); }
  { int p = -1; P(1 ? INT16_MAX : p); }
  { int p = -1; P(1 ? p : INT16_MAX); }
  { int p = -1; P(0 ? INT16_MAX : p); }
  { int p = -1; P(TC(INT16_MAX + p)); }
  { int p = -1; P(TC(p + INT16_MAX)); }
  { int p = -1; P(TC(1 ? INT16_MAX : p)); }
  { int p = -1; P(sizeof(INT16_MAX + p)); }
  { int p = -1; int t = p; t += INT16_MAX; P(t); }
  { int p = -1; int t = p; t -= INT16_MAX; P(t); }
  { int p = -1; int t = p; t &= INT16_MAX; P(t); }
  { int p = -1; int t = p; t |= INT16_MAX; P(t); }
  { unsigned p = -1; P(INT16_MAX < p); }
  { unsigned p = -1; P(INT16_MAX > p); }
  { unsigned p = -1; P(INT16_MAX == p); }
  { unsigned p = -1; P(INT16_MAX != p); }
  { unsigned p = -1; P(INT16_MAX <= p); }
  { unsigned p = -1; P(INT16_MAX >= p); }
  { unsigned p = -1; P(p < INT16_MAX); }
  { unsigned p = -1; P(p > INT16_MAX); }
  { unsigned p = -1; P(p == INT16_MAX); }
  { unsigned p = -1; P(p <= INT16_MAX); }
  { unsigned p = -1; P(INT16_MAX + p); }
  { unsigned p = -1; P(p + INT16_MAX); }
  { unsigned p = -1; P(INT16_MAX - p); }
  { unsigned p = -1; P(p - INT16_MAX); }
  { unsigned p = -1; P(INT16_MAX * p); }
  { unsigned p = -1; P(p * INT16_MAX); }
  { unsigned p = -1; P(INT16_MAX & p); }
  { unsigned p = -1; P(INT16_MAX | p); }
  { unsigned p = -1; P(INT16_MAX ^ p); }
  { unsigned p = -1; P(p & INT16_MAX); }
  { unsigned p = -1; P(p | INT16_MAX); }
  { unsigned p = -1; P(1 ? INT16_MAX : p); }
  { unsigned p = -1; P(1 ? p : INT16_MAX); }
  { unsigned p = -1; P(0 ? INT16_MAX : p); }
  { unsigned p = -1; P(TC(INT16_MAX + p)); }
  { unsigned p = -1; P(TC(p + INT16_MAX)); }
  { unsigned p = -1; P(TC(1 ? INT16_MAX : p)); }
  { unsigned p = -1; P(sizeof(INT16_MAX + p)); }
  { unsigned p = -1; P(INT16_MAX / p); }
  { unsigned p = -1; P(INT16_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += INT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT16_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT16_MAX; P(t); }
  { long p = -1; P(INT16_MAX < p); }
  { long p = -1; P(INT16_MAX > p); }
  { long p = -1; P(INT16_MAX == p); }
  { long p = -1; P(INT16_MAX != p); }
  { long p = -1; P(INT16_MAX <= p); }
  { long p = -1; P(INT16_MAX >= p); }
  { long p = -1; P(p < INT16_MAX); }
  { long p = -1; P(p > INT16_MAX); }
  { long p = -1; P(p == INT16_MAX); }
  { long p = -1; P(p <= INT16_MAX); }
  { long p = -1; P(INT16_MAX + p); }
  { long p = -1; P(p + INT16_MAX); }
  { long p = -1; P(INT16_MAX - p); }
  { long p = -1; P(p - INT16_MAX); }
  { long p = -1; P(INT16_MAX * p); }
  { long p = -1; P(p * INT16_MAX); }
  { long p = -1; P(INT16_MAX & p); }
  { long p = -1; P(INT16_MAX | p); }
  { long p = -1; P(INT16_MAX ^ p); }
  { long p = -1; P(p & INT16_MAX); }
  { long p = -1; P(p | INT16_MAX); }
  { long p = -1; P(1 ? INT16_MAX : p); }
  { long p = -1; P(1 ? p : INT16_MAX); }
  { long p = -1; P(0 ? INT16_MAX : p); }
  { long p = -1; P(TC(INT16_MAX + p)); }
  { long p = -1; P(TC(p + INT16_MAX)); }
  { long p = -1; P(TC(1 ? INT16_MAX : p)); }
  { long p = -1; P(sizeof(INT16_MAX + p)); }
  { long p = -1; long t = p; t += INT16_MAX; P(t); }
  { long p = -1; long t = p; t -= INT16_MAX; P(t); }
  { long p = -1; long t = p; t &= INT16_MAX; P(t); }
  { long p = -1; long t = p; t |= INT16_MAX; P(t); }
  { unsigned long p = -1; P(INT16_MAX < p); }
  { unsigned long p = -1; P(INT16_MAX > p); }
  { unsigned long p = -1; P(INT16_MAX == p); }
  { unsigned long p = -1; P(INT16_MAX != p); }
  { unsigned long p = -1; P(INT16_MAX <= p); }
  { unsigned long p = -1; P(INT16_MAX >= p); }
  { unsigned long p = -1; P(p < INT16_MAX); }
  { unsigned long p = -1; P(p > INT16_MAX); }
  { unsigned long p = -1; P(p == INT16_MAX); }
  { unsigned long p = -1; P(p <= INT16_MAX); }
  { unsigned long p = -1; P(INT16_MAX + p); }
  { unsigned long p = -1; P(p + INT16_MAX); }
  { unsigned long p = -1; P(INT16_MAX - p); }
  { unsigned long p = -1; P(p - INT16_MAX); }
  { unsigned long p = -1; P(INT16_MAX * p); }
  { unsigned long p = -1; P(p * INT16_MAX); }
  { unsigned long p = -1; P(INT16_MAX & p); }
  { unsigned long p = -1; P(INT16_MAX | p); }
  { unsigned long p = -1; P(INT16_MAX ^ p); }
  { unsigned long p = -1; P(p & INT16_MAX); }
  { unsigned long p = -1; P(p | INT16_MAX); }
  { unsigned long p = -1; P(1 ? INT16_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INT16_MAX); }
  { unsigned long p = -1; P(0 ? INT16_MAX : p); }
  { unsigned long p = -1; P(TC(INT16_MAX + p)); }
  { unsigned long p = -1; P(TC(p + INT16_MAX)); }
  { unsigned long p = -1; P(TC(1 ? INT16_MAX : p)); }
  { unsigned long p = -1; P(sizeof(INT16_MAX + p)); }
  { unsigned long p = -1; P(INT16_MAX / p); }
  { unsigned long p = -1; P(INT16_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT16_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT16_MAX; P(t); }
  P(INT16_MIN > 0);
  P(INT16_MIN < 0);
  P(INT16_MIN == 0);
  P(INT16_MIN != 0);
  P(INT16_MIN >= 0);
  P(INT16_MIN <= 0);
  P(0 < INT16_MIN);
  P(0 > INT16_MIN);
  P(0 == INT16_MIN);
  P(+INT16_MIN);
  P(-INT16_MIN);
  P(~INT16_MIN);
  P(!INT16_MIN);
  P((+INT16_MIN) > 0);
  P(sizeof(+INT16_MIN));
  P(TC(+INT16_MIN));
  P(TC(-INT16_MIN));
  P(TC(~INT16_MIN));
  P((_Bool)INT16_MIN);
  P((signed char)INT16_MIN);
  P((unsigned char)INT16_MIN);
  P((short)INT16_MIN);
  P((unsigned short)INT16_MIN);
  P((int)INT16_MIN);
  P((unsigned)INT16_MIN);
  P((long)INT16_MIN);
  P((unsigned long)INT16_MIN);
  P((long long)INT16_MIN);
  P((unsigned long long)INT16_MIN);
  P((long long)INT16_MIN > 0);
  P((long long)INT16_MIN < 0);
  { int x = INT16_MIN; P(x); }
  { unsigned x = INT16_MIN; P(x); }
  { long x = INT16_MIN; P(x); }
  { unsigned long x = INT16_MIN; P(x); }
  P(INT16_MIN + 1);
  P(INT16_MIN - 1);
  P(INT16_MIN - 1 > 0);
  P(INT16_MIN + 1 > 0);
  P(INT16_MIN + 1u);
  P(INT16_MIN - 1u);
  P(INT16_MIN + 1l);
  P(INT16_MIN - 1ul);
  { int p = -1; P(INT16_MIN < p); }
  { int p = -1; P(INT16_MIN > p); }
  { int p = -1; P(INT16_MIN == p); }
  { int p = -1; P(INT16_MIN != p); }
  { int p = -1; P(INT16_MIN <= p); }
  { int p = -1; P(INT16_MIN >= p); }
  { int p = -1; P(p < INT16_MIN); }
  { int p = -1; P(p > INT16_MIN); }
  { int p = -1; P(p == INT16_MIN); }
  { int p = -1; P(p <= INT16_MIN); }
  { int p = -1; P(INT16_MIN + p); }
  { int p = -1; P(p + INT16_MIN); }
  { int p = -1; P(INT16_MIN - p); }
  { int p = -1; P(p - INT16_MIN); }
  { int p = -1; P(INT16_MIN * p); }
  { int p = -1; P(p * INT16_MIN); }
  { int p = -1; P(INT16_MIN & p); }
  { int p = -1; P(INT16_MIN | p); }
  { int p = -1; P(INT16_MIN ^ p); }
  { int p = -1; P(p & INT16_MIN); }
  { int p = -1; P(p | INT16_MIN); }
  { int p = -1; P(1 ? INT16_MIN : p); }
  { int p = -1; P(1 ? p : INT16_MIN); }
  { int p = -1; P(0 ? INT16_MIN : p); }
  { int p = -1; P(TC(INT16_MIN + p)); }
  { int p = -1; P(TC(p + INT16_MIN)); }
  { int p = -1; P(TC(1 ? INT16_MIN : p)); }
  { int p = -1; P(sizeof(INT16_MIN + p)); }
  { int p = -1; int t = p; t += INT16_MIN; P(t); }
  { int p = -1; int t = p; t -= INT16_MIN; P(t); }
  { int p = -1; int t = p; t &= INT16_MIN; P(t); }
  { int p = -1; int t = p; t |= INT16_MIN; P(t); }
  { unsigned p = -1; P(INT16_MIN < p); }
  { unsigned p = -1; P(INT16_MIN > p); }
  { unsigned p = -1; P(INT16_MIN == p); }
  { unsigned p = -1; P(INT16_MIN != p); }
  { unsigned p = -1; P(INT16_MIN <= p); }
  { unsigned p = -1; P(INT16_MIN >= p); }
  { unsigned p = -1; P(p < INT16_MIN); }
  { unsigned p = -1; P(p > INT16_MIN); }
  { unsigned p = -1; P(p == INT16_MIN); }
  { unsigned p = -1; P(p <= INT16_MIN); }
  { unsigned p = -1; P(INT16_MIN + p); }
  { unsigned p = -1; P(p + INT16_MIN); }
  { unsigned p = -1; P(INT16_MIN - p); }
  { unsigned p = -1; P(p - INT16_MIN); }
  { unsigned p = -1; P(INT16_MIN * p); }
  { unsigned p = -1; P(p * INT16_MIN); }
  { unsigned p = -1; P(INT16_MIN & p); }
  { unsigned p = -1; P(INT16_MIN | p); }
  { unsigned p = -1; P(INT16_MIN ^ p); }
  { unsigned p = -1; P(p & INT16_MIN); }
  { unsigned p = -1; P(p | INT16_MIN); }
  { unsigned p = -1; P(1 ? INT16_MIN : p); }
  { unsigned p = -1; P(1 ? p : INT16_MIN); }
  { unsigned p = -1; P(0 ? INT16_MIN : p); }
  { unsigned p = -1; P(TC(INT16_MIN + p)); }
  { unsigned p = -1; P(TC(p + INT16_MIN)); }
  { unsigned p = -1; P(TC(1 ? INT16_MIN : p)); }
  { unsigned p = -1; P(sizeof(INT16_MIN + p)); }
  { unsigned p = -1; P(INT16_MIN / p); }
  { unsigned p = -1; P(INT16_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INT16_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT16_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT16_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT16_MIN; P(t); }
  { long p = -1; P(INT16_MIN < p); }
  { long p = -1; P(INT16_MIN > p); }
  { long p = -1; P(INT16_MIN == p); }
  { long p = -1; P(INT16_MIN != p); }
  { long p = -1; P(INT16_MIN <= p); }
  { long p = -1; P(INT16_MIN >= p); }
  { long p = -1; P(p < INT16_MIN); }
  { long p = -1; P(p > INT16_MIN); }
  { long p = -1; P(p == INT16_MIN); }
  { long p = -1; P(p <= INT16_MIN); }
  { long p = -1; P(INT16_MIN + p); }
  { long p = -1; P(p + INT16_MIN); }
  { long p = -1; P(INT16_MIN - p); }
  { long p = -1; P(p - INT16_MIN); }
  { long p = -1; P(INT16_MIN * p); }
  { long p = -1; P(p * INT16_MIN); }
  { long p = -1; P(INT16_MIN & p); }
  { long p = -1; P(INT16_MIN | p); }
  { long p = -1; P(INT16_MIN ^ p); }
  { long p = -1; P(p & INT16_MIN); }
  { long p = -1; P(p | INT16_MIN); }
  { long p = -1; P(1 ? INT16_MIN : p); }
  { long p = -1; P(1 ? p : INT16_MIN); }
  { long p = -1; P(0 ? INT16_MIN : p); }
  { long p = -1; P(TC(INT16_MIN + p)); }
  { long p = -1; P(TC(p + INT16_MIN)); }
  { long p = -1; P(TC(1 ? INT16_MIN : p)); }
  { long p = -1; P(sizeof(INT16_MIN + p)); }
  { long p = -1; long t = p; t += INT16_MIN; P(t); }
  { long p = -1; long t = p; t -= INT16_MIN; P(t); }
  { long p = -1; long t = p; t &= INT16_MIN; P(t); }
  { long p = -1; long t = p; t |= INT16_MIN; P(t); }
  { unsigned long p = -1; P(INT16_MIN < p); }
  { unsigned long p = -1; P(INT16_MIN > p); }
  { unsigned long p = -1; P(INT16_MIN == p); }
  { unsigned long p = -1; P(INT16_MIN != p); }
  { unsigned long p = -1; P(INT16_MIN <= p); }
  { unsigned long p = -1; P(INT16_MIN >= p); }
  { unsigned long p = -1; P(p < INT16_MIN); }
  { unsigned long p = -1; P(p > INT16_MIN); }
  { unsigned long p = -1; P(p == INT16_MIN); }
  { unsigned long p = -1; P(p <= INT16_MIN); }
  { unsigned long p = -1; P(INT16_MIN + p); }
  { unsigned long p = -1; P(p + INT16_MIN); }
  { unsigned long p = -1; P(INT16_MIN - p); }
  { unsigned long p = -1; P(p - INT16_MIN); }
  { unsigned long p = -1; P(INT16_MIN * p); }
  { unsigned long p = -1; P(p * INT16_MIN); }
  { unsigned long p = -1; P(INT16_MIN & p); }
  { unsigned long p = -1; P(INT16_MIN | p); }
  { unsigned long p = -1; P(INT16_MIN ^ p); }
  { unsigned long p = -1; P(p & INT16_MIN); }
  { unsigned long p = -1; P(p | INT16_MIN); }
  { unsigned long p = -1; P(1 ? INT16_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INT16_MIN); }
  { unsigned long p = -1; P(0 ? INT16_MIN : p); }
  { unsigned long p = -1; P(TC(INT16_MIN + p)); }
  { unsigned long p = -1; P(TC(p + INT16_MIN)); }
  { unsigned long p = -1; P(TC(1 ? INT16_MIN : p)); }
  { unsigned long p = -1; P(sizeof(INT16_MIN + p)); }
  { unsigned long p = -1; P(INT16_MIN / p); }
  { unsigned long p = -1; P(INT16_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT16_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT16_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT16_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT16_MIN; P(t); }
  P(INT32_MAX > 0);
  P(INT32_MAX < 0);
  P(INT32_MAX == 0);
  P(INT32_MAX != 0);
  P(INT32_MAX >= 0);
  P(INT32_MAX <= 0);
  P(0 < INT32_MAX);
  P(0 > INT32_MAX);
  P(0 == INT32_MAX);
  P(+INT32_MAX);
  P(-INT32_MAX);
  P(~INT32_MAX);
  P(!INT32_MAX);
  P((+INT32_MAX) > 0);
  P(sizeof(INT32_MAX));
  P(sizeof(+INT32_MAX));
  P(TC(INT32_MAX));
  P(TC(+INT32_MAX));
  P(TC(-INT32_MAX));
  P(TC(~INT32_MAX));
  P((_Bool)INT32_MAX);
  P((signed char)INT32_MAX);
  P((unsigned char)INT32_MAX);
  P((short)INT32_MAX);
  P((unsigned short)INT32_MAX);
  P((int)INT32_MAX);
  P((unsigned)INT32_MAX);
  P((long)INT32_MAX);
  P((unsigned long)INT32_MAX);
  P((long long)INT32_MAX);
  P((unsigned long long)INT32_MAX);
  P((long long)INT32_MAX > 0);
  P((long long)INT32_MAX < 0);
  { int x = INT32_MAX; P(x); }
  { unsigned x = INT32_MAX; P(x); }
  { long x = INT32_MAX; P(x); }
  { unsigned long x = INT32_MAX; P(x); }
  P(INT32_MAX - 1);
  P(INT32_MAX - 1 > 0);
  P(INT32_MAX + 1u);
  P(INT32_MAX - 1u);
  P(INT32_MAX + 1l);
  P(INT32_MAX - 1ul);
  { int p = -1; P(INT32_MAX < p); }
  { int p = -1; P(INT32_MAX > p); }
  { int p = -1; P(INT32_MAX == p); }
  { int p = -1; P(INT32_MAX != p); }
  { int p = -1; P(INT32_MAX <= p); }
  { int p = -1; P(INT32_MAX >= p); }
  { int p = -1; P(p < INT32_MAX); }
  { int p = -1; P(p > INT32_MAX); }
  { int p = -1; P(p == INT32_MAX); }
  { int p = -1; P(p <= INT32_MAX); }
  { int p = -1; P(INT32_MAX + p); }
  { int p = -1; P(p + INT32_MAX); }
  { int p = -1; P(p - INT32_MAX); }
  { int p = -1; P(INT32_MAX * p); }
  { int p = -1; P(p * INT32_MAX); }
  { int p = -1; P(INT32_MAX & p); }
  { int p = -1; P(INT32_MAX | p); }
  { int p = -1; P(INT32_MAX ^ p); }
  { int p = -1; P(p & INT32_MAX); }
  { int p = -1; P(p | INT32_MAX); }
  { int p = -1; P(1 ? INT32_MAX : p); }
  { int p = -1; P(1 ? p : INT32_MAX); }
  { int p = -1; P(0 ? INT32_MAX : p); }
  { int p = -1; P(TC(INT32_MAX + p)); }
  { int p = -1; P(TC(p + INT32_MAX)); }
  { int p = -1; P(TC(1 ? INT32_MAX : p)); }
  { int p = -1; P(sizeof(INT32_MAX + p)); }
  { int p = -1; int t = p; t += INT32_MAX; P(t); }
  { int p = -1; int t = p; t -= INT32_MAX; P(t); }
  { int p = -1; int t = p; t &= INT32_MAX; P(t); }
  { int p = -1; int t = p; t |= INT32_MAX; P(t); }
  { unsigned p = -1; P(INT32_MAX < p); }
  { unsigned p = -1; P(INT32_MAX > p); }
  { unsigned p = -1; P(INT32_MAX == p); }
  { unsigned p = -1; P(INT32_MAX != p); }
  { unsigned p = -1; P(INT32_MAX <= p); }
  { unsigned p = -1; P(INT32_MAX >= p); }
  { unsigned p = -1; P(p < INT32_MAX); }
  { unsigned p = -1; P(p > INT32_MAX); }
  { unsigned p = -1; P(p == INT32_MAX); }
  { unsigned p = -1; P(p <= INT32_MAX); }
  { unsigned p = -1; P(INT32_MAX + p); }
  { unsigned p = -1; P(p + INT32_MAX); }
  { unsigned p = -1; P(INT32_MAX - p); }
  { unsigned p = -1; P(p - INT32_MAX); }
  { unsigned p = -1; P(INT32_MAX * p); }
  { unsigned p = -1; P(p * INT32_MAX); }
  { unsigned p = -1; P(INT32_MAX & p); }
  { unsigned p = -1; P(INT32_MAX | p); }
  { unsigned p = -1; P(INT32_MAX ^ p); }
  { unsigned p = -1; P(p & INT32_MAX); }
  { unsigned p = -1; P(p | INT32_MAX); }
  { unsigned p = -1; P(1 ? INT32_MAX : p); }
  { unsigned p = -1; P(1 ? p : INT32_MAX); }
  { unsigned p = -1; P(0 ? INT32_MAX : p); }
  { unsigned p = -1; P(TC(INT32_MAX + p)); }
  { unsigned p = -1; P(TC(p + INT32_MAX)); }
  { unsigned p = -1; P(TC(1 ? INT32_MAX : p)); }
  { unsigned p = -1; P(sizeof(INT32_MAX + p)); }
  { unsigned p = -1; P(INT32_MAX / p); }
  { unsigned p = -1; P(INT32_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += INT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT32_MAX; P(t); }
  { long p = -1; P(INT32_MAX < p); }
  { long p = -1; P(INT32_MAX > p); }
  { long p = -1; P(INT32_MAX == p); }
  { long p = -1; P(INT32_MAX != p); }
  { long p = -1; P(INT32_MAX <= p); }
  { long p = -1; P(INT32_MAX >= p); }
  { long p = -1; P(p < INT32_MAX); }
  { long p = -1; P(p > INT32_MAX); }
  { long p = -1; P(p == INT32_MAX); }
  { long p = -1; P(p <= INT32_MAX); }
  { long p = -1; P(INT32_MAX + p); }
  { long p = -1; P(p + INT32_MAX); }
  { long p = -1; P(INT32_MAX - p); }
  { long p = -1; P(p - INT32_MAX); }
  { long p = -1; P(INT32_MAX * p); }
  { long p = -1; P(p * INT32_MAX); }
  { long p = -1; P(INT32_MAX & p); }
  { long p = -1; P(INT32_MAX | p); }
  { long p = -1; P(INT32_MAX ^ p); }
  { long p = -1; P(p & INT32_MAX); }
  { long p = -1; P(p | INT32_MAX); }
  { long p = -1; P(1 ? INT32_MAX : p); }
  { long p = -1; P(1 ? p : INT32_MAX); }
  { long p = -1; P(0 ? INT32_MAX : p); }
  { long p = -1; P(TC(INT32_MAX + p)); }
  { long p = -1; P(TC(p + INT32_MAX)); }
  { long p = -1; P(TC(1 ? INT32_MAX : p)); }
  { long p = -1; P(sizeof(INT32_MAX + p)); }
  { long p = -1; long t = p; t += INT32_MAX; P(t); }
  { long p = -1; long t = p; t -= INT32_MAX; P(t); }
  { long p = -1; long t = p; t &= INT32_MAX; P(t); }
  { long p = -1; long t = p; t |= INT32_MAX; P(t); }
  { unsigned long p = -1; P(INT32_MAX < p); }
  { unsigned long p = -1; P(INT32_MAX > p); }
  { unsigned long p = -1; P(INT32_MAX == p); }
  { unsigned long p = -1; P(INT32_MAX != p); }
  { unsigned long p = -1; P(INT32_MAX <= p); }
  { unsigned long p = -1; P(INT32_MAX >= p); }
  { unsigned long p = -1; P(p < INT32_MAX); }
  { unsigned long p = -1; P(p > INT32_MAX); }
  { unsigned long p = -1; P(p == INT32_MAX); }
  { unsigned long p = -1; P(p <= INT32_MAX); }
  { unsigned long p = -1; P(INT32_MAX + p); }
  { unsigned long p = -1; P(p + INT32_MAX); }
  { unsigned long p = -1; P(INT32_MAX - p); }
  { unsigned long p = -1; P(p - INT32_MAX); }
  { unsigned long p = -1; P(INT32_MAX * p); }
  { unsigned long p = -1; P(p * INT32_MAX); }
  { unsigned long p = -1; P(INT32_MAX & p); }
  { unsigned long p = -1; P(INT32_MAX | p); }
  { unsigned long p = -1; P(INT32_MAX ^ p); }
  { unsigned long p = -1; P(p & INT32_MAX); }
  { unsigned long p = -1; P(p | INT32_MAX); }
  { unsigned long p = -1; P(1 ? INT32_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INT32_MAX); }
  { unsigned long p = -1; P(0 ? INT32_MAX : p); }
  { unsigned long p = -1; P(TC(INT32_MAX + p)); }
  { unsigned long p = -1; P(TC(p + INT32_MAX)); }
  { unsigned long p = -1; P(TC(1 ? INT32_MAX : p)); }
  { unsigned long p = -1; P(sizeof(INT32_MAX + p)); }
  { unsigned long p = -1; P(INT32_MAX / p); }
  { unsigned long p = -1; P(INT32_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT32_MAX; P(t); }
  P(INT32_MIN > 0);
  P(INT32_MIN < 0);
  P(INT32_MIN == 0);
  P(INT32_MIN != 0);
  P(INT32_MIN >= 0);
  P(INT32_MIN <= 0);
  P(0 < INT32_MIN);
  P(0 > INT32_MIN);
  P(0 == INT32_MIN);
  P(+INT32_MIN);
  P(~INT32_MIN);
  P(!INT32_MIN);
  P((+INT32_MIN) > 0);
  P(sizeof(INT32_MIN));
  P(sizeof(+INT32_MIN));
  P(TC(INT32_MIN));
  P(TC(+INT32_MIN));
  P(TC(-INT32_MIN));
  P(TC(~INT32_MIN));
  P((_Bool)INT32_MIN);
  P((signed char)INT32_MIN);
  P((unsigned char)INT32_MIN);
  P((short)INT32_MIN);
  P((unsigned short)INT32_MIN);
  P((int)INT32_MIN);
  P((unsigned)INT32_MIN);
  P((long)INT32_MIN);
  P((unsigned long)INT32_MIN);
  P((long long)INT32_MIN);
  P((unsigned long long)INT32_MIN);
  P((long long)INT32_MIN > 0);
  P((long long)INT32_MIN < 0);
  { int x = INT32_MIN; P(x); }
  { unsigned x = INT32_MIN; P(x); }
  { long x = INT32_MIN; P(x); }
  { unsigned long x = INT32_MIN; P(x); }
  P(INT32_MIN + 1);
  P(INT32_MIN + 1 > 0);
  P(INT32_MIN + 1u);
  P(INT32_MIN - 1u);
  P(INT32_MIN + 1l);
  P(INT32_MIN - 1ul);
  { int p = -1; P(INT32_MIN < p); }
  { int p = -1; P(INT32_MIN > p); }
  { int p = -1; P(INT32_MIN == p); }
  { int p = -1; P(INT32_MIN != p); }
  { int p = -1; P(INT32_MIN <= p); }
  { int p = -1; P(INT32_MIN >= p); }
  { int p = -1; P(p < INT32_MIN); }
  { int p = -1; P(p > INT32_MIN); }
  { int p = -1; P(p == INT32_MIN); }
  { int p = -1; P(p <= INT32_MIN); }
  { int p = -1; P(INT32_MIN - p); }
  { int p = -1; P(p - INT32_MIN); }
  { int p = -1; P(INT32_MIN & p); }
  { int p = -1; P(INT32_MIN | p); }
  { int p = -1; P(INT32_MIN ^ p); }
  { int p = -1; P(p & INT32_MIN); }
  { int p = -1; P(p | INT32_MIN); }
  { int p = -1; P(1 ? INT32_MIN : p); }
  { int p = -1; P(1 ? p : INT32_MIN); }
  { int p = -1; P(0 ? INT32_MIN : p); }
  { int p = -1; P(TC(INT32_MIN + p)); }
  { int p = -1; P(TC(p + INT32_MIN)); }
  { int p = -1; P(TC(1 ? INT32_MIN : p)); }
  { int p = -1; P(sizeof(INT32_MIN + p)); }
  { int p = -1; int t = p; t -= INT32_MIN; P(t); }
  { int p = -1; int t = p; t &= INT32_MIN; P(t); }
  { int p = -1; int t = p; t |= INT32_MIN; P(t); }
  { unsigned p = -1; P(INT32_MIN < p); }
  { unsigned p = -1; P(INT32_MIN > p); }
  { unsigned p = -1; P(INT32_MIN == p); }
  { unsigned p = -1; P(INT32_MIN != p); }
  { unsigned p = -1; P(INT32_MIN <= p); }
  { unsigned p = -1; P(INT32_MIN >= p); }
  { unsigned p = -1; P(p < INT32_MIN); }
  { unsigned p = -1; P(p > INT32_MIN); }
  { unsigned p = -1; P(p == INT32_MIN); }
  { unsigned p = -1; P(p <= INT32_MIN); }
  { unsigned p = -1; P(INT32_MIN + p); }
  { unsigned p = -1; P(p + INT32_MIN); }
  { unsigned p = -1; P(INT32_MIN - p); }
  { unsigned p = -1; P(p - INT32_MIN); }
  { unsigned p = -1; P(INT32_MIN * p); }
  { unsigned p = -1; P(p * INT32_MIN); }
  { unsigned p = -1; P(INT32_MIN & p); }
  { unsigned p = -1; P(INT32_MIN | p); }
  { unsigned p = -1; P(INT32_MIN ^ p); }
  { unsigned p = -1; P(p & INT32_MIN); }
  { unsigned p = -1; P(p | INT32_MIN); }
  { unsigned p = -1; P(1 ? INT32_MIN : p); }
  { unsigned p = -1; P(1 ? p : INT32_MIN); }
  { unsigned p = -1; P(0 ? INT32_MIN : p); }
  { unsigned p = -1; P(TC(INT32_MIN + p)); }
  { unsigned p = -1; P(TC(p + INT32_MIN)); }
  { unsigned p = -1; P(TC(1 ? INT32_MIN : p)); }
  { unsigned p = -1; P(sizeof(INT32_MIN + p)); }
  { unsigned p = -1; P(INT32_MIN / p); }
  { unsigned p = -1; P(INT32_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INT32_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT32_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT32_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT32_MIN; P(t); }
  { long p = -1; P(INT32_MIN < p); }
  { long p = -1; P(INT32_MIN > p); }
  { long p = -1; P(INT32_MIN == p); }
  { long p = -1; P(INT32_MIN != p); }
  { long p = -1; P(INT32_MIN <= p); }
  { long p = -1; P(INT32_MIN >= p); }
  { long p = -1; P(p < INT32_MIN); }
  { long p = -1; P(p > INT32_MIN); }
  { long p = -1; P(p == INT32_MIN); }
  { long p = -1; P(p <= INT32_MIN); }
  { long p = -1; P(INT32_MIN + p); }
  { long p = -1; P(p + INT32_MIN); }
  { long p = -1; P(INT32_MIN - p); }
  { long p = -1; P(p - INT32_MIN); }
  { long p = -1; P(INT32_MIN * p); }
  { long p = -1; P(p * INT32_MIN); }
  { long p = -1; P(INT32_MIN & p); }
  { long p = -1; P(INT32_MIN | p); }
  { long p = -1; P(INT32_MIN ^ p); }
  { long p = -1; P(p & INT32_MIN); }
  { long p = -1; P(p | INT32_MIN); }
  { long p = -1; P(1 ? INT32_MIN : p); }
  { long p = -1; P(1 ? p : INT32_MIN); }
  { long p = -1; P(0 ? INT32_MIN : p); }
  { long p = -1; P(TC(INT32_MIN + p)); }
  { long p = -1; P(TC(p + INT32_MIN)); }
  { long p = -1; P(TC(1 ? INT32_MIN : p)); }
  { long p = -1; P(sizeof(INT32_MIN + p)); }
  { long p = -1; long t = p; t += INT32_MIN; P(t); }
  { long p = -1; long t = p; t -= INT32_MIN; P(t); }
  { long p = -1; long t = p; t &= INT32_MIN; P(t); }
  { long p = -1; long t = p; t |= INT32_MIN; P(t); }
  { unsigned long p = -1; P(INT32_MIN < p); }
  { unsigned long p = -1; P(INT32_MIN > p); }
  { unsigned long p = -1; P(INT32_MIN == p); }
  { unsigned long p = -1; P(INT32_MIN != p); }
  { unsigned long p = -1; P(INT32_MIN <= p); }
  { unsigned long p = -1; P(INT32_MIN >= p); }
  { unsigned long p = -1; P(p < INT32_MIN); }
  { unsigned long p = -1; P(p > INT32_MIN); }
  { unsigned long p = -1; P(p == INT32_MIN); }
  { unsigned long p = -1; P(p <= INT32_MIN); }
  { unsigned long p = -1; P(INT32_MIN + p); }
  { unsigned long p = -1; P(p + INT32_MIN); }
  { unsigned long p = -1; P(INT32_MIN - p); }
  { unsigned long p = -1; P(p - INT32_MIN); }
  { unsigned long p = -1; P(INT32_MIN * p); }
  { unsigned long p = -1; P(p * INT32_MIN); }
  { unsigned long p = -1; P(INT32_MIN & p); }
  { unsigned long p = -1; P(INT32_MIN | p); }
  { unsigned long p = -1; P(INT32_MIN ^ p); }
  { unsigned long p = -1; P(p & INT32_MIN); }
  { unsigned long p = -1; P(p | INT32_MIN); }
  { unsigned long p = -1; P(1 ? INT32_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INT32_MIN); }
  { unsigned long p = -1; P(0 ? INT32_MIN : p); }
  { unsigned long p = -1; P(TC(INT32_MIN + p)); }
  { unsigned long p = -1; P(TC(p + INT32_MIN)); }
  { unsigned long p = -1; P(TC(1 ? INT32_MIN : p)); }
  { unsigned long p = -1; P(sizeof(INT32_MIN + p)); }
  { unsigned long p = -1; P(INT32_MIN / p); }
  { unsigned long p = -1; P(INT32_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT32_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT32_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT32_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT32_MIN; P(t); }
  P(INT64_MAX > 0);
  P(INT64_MAX < 0);
  P(INT64_MAX == 0);
  P(INT64_MAX != 0);
  P(INT64_MAX >= 0);
  P(INT64_MAX <= 0);
  P(0 < INT64_MAX);
  P(0 > INT64_MAX);
  P(0 == INT64_MAX);
  P(+INT64_MAX);
  P(-INT64_MAX);
  P(~INT64_MAX);
  P(!INT64_MAX);
  P((+INT64_MAX) > 0);
  P(sizeof(INT64_MAX));
  printf("\n");
  return 0;
}
