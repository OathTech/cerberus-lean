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
#undef UINT32_MAX
#define UINT32_MAX UINT_MAX
#undef UINT64_MAX
#define UINT64_MAX ULLONG_MAX
#ifndef IOV_MAX
#define IOV_MAX 1024
#endif
#ifndef NAME_MAX
#define NAME_MAX 1024
#endif
#endif
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(0 < UINT32_MAX);
  P(0 > UINT32_MAX);
  P(0 == UINT32_MAX);
  P(+UINT32_MAX);
  P(-UINT32_MAX);
  P(~UINT32_MAX);
  P(!UINT32_MAX);
  P((+UINT32_MAX) > 0);
  P(sizeof(UINT32_MAX));
  P(sizeof(+UINT32_MAX));
  P(TC(UINT32_MAX));
  P(TC(+UINT32_MAX));
  P(TC(-UINT32_MAX));
  P(TC(~UINT32_MAX));
  P((_Bool)UINT32_MAX);
  P((signed char)UINT32_MAX);
  P((unsigned char)UINT32_MAX);
  P((short)UINT32_MAX);
  P((unsigned short)UINT32_MAX);
  P((int)UINT32_MAX);
  P((unsigned)UINT32_MAX);
  P((long)UINT32_MAX);
  P((unsigned long)UINT32_MAX);
  P((long long)UINT32_MAX);
  P((unsigned long long)UINT32_MAX);
  P((long long)UINT32_MAX > 0);
  P((long long)UINT32_MAX < 0);
  { int x = UINT32_MAX; P(x); }
  { unsigned x = UINT32_MAX; P(x); }
  { long x = UINT32_MAX; P(x); }
  { unsigned long x = UINT32_MAX; P(x); }
  P(UINT32_MAX + 1);
  P(UINT32_MAX - 1);
  P(UINT32_MAX - 1 > 0);
  P(UINT32_MAX + 1 > 0);
  P(UINT32_MAX + 1u);
  P(UINT32_MAX - 1u);
  P(UINT32_MAX + 1l);
  P(UINT32_MAX - 1ul);
  { int p = -1; P(UINT32_MAX < p); }
  { int p = -1; P(UINT32_MAX > p); }
  { int p = -1; P(UINT32_MAX == p); }
  { int p = -1; P(UINT32_MAX != p); }
  { int p = -1; P(UINT32_MAX <= p); }
  { int p = -1; P(UINT32_MAX >= p); }
  { int p = -1; P(p < UINT32_MAX); }
  { int p = -1; P(p > UINT32_MAX); }
  { int p = -1; P(p == UINT32_MAX); }
  { int p = -1; P(p <= UINT32_MAX); }
  { int p = -1; P(UINT32_MAX + p); }
  { int p = -1; P(p + UINT32_MAX); }
  { int p = -1; P(UINT32_MAX - p); }
  { int p = -1; P(p - UINT32_MAX); }
  { int p = -1; P(UINT32_MAX * p); }
  { int p = -1; P(p * UINT32_MAX); }
  { int p = -1; P(UINT32_MAX & p); }
  { int p = -1; P(UINT32_MAX | p); }
  { int p = -1; P(UINT32_MAX ^ p); }
  { int p = -1; P(p & UINT32_MAX); }
  { int p = -1; P(p | UINT32_MAX); }
  { int p = -1; P(1 ? UINT32_MAX : p); }
  { int p = -1; P(1 ? p : UINT32_MAX); }
  { int p = -1; P(0 ? UINT32_MAX : p); }
  { int p = -1; P(TC(UINT32_MAX + p)); }
  { int p = -1; P(TC(p + UINT32_MAX)); }
  { int p = -1; P(TC(1 ? UINT32_MAX : p)); }
  { int p = -1; P(sizeof(UINT32_MAX + p)); }
  { int p = -1; int t = p; t += UINT32_MAX; P(t); }
  { int p = -1; int t = p; t -= UINT32_MAX; P(t); }
  { int p = -1; int t = p; t &= UINT32_MAX; P(t); }
  { int p = -1; int t = p; t |= UINT32_MAX; P(t); }
  { unsigned p = -1; P(UINT32_MAX < p); }
  { unsigned p = -1; P(UINT32_MAX > p); }
  { unsigned p = -1; P(UINT32_MAX == p); }
  { unsigned p = -1; P(UINT32_MAX != p); }
  { unsigned p = -1; P(UINT32_MAX <= p); }
  { unsigned p = -1; P(UINT32_MAX >= p); }
  { unsigned p = -1; P(p < UINT32_MAX); }
  { unsigned p = -1; P(p > UINT32_MAX); }
  { unsigned p = -1; P(p == UINT32_MAX); }
  { unsigned p = -1; P(p <= UINT32_MAX); }
  { unsigned p = -1; P(UINT32_MAX + p); }
  { unsigned p = -1; P(p + UINT32_MAX); }
  { unsigned p = -1; P(UINT32_MAX - p); }
  { unsigned p = -1; P(p - UINT32_MAX); }
  { unsigned p = -1; P(UINT32_MAX * p); }
  { unsigned p = -1; P(p * UINT32_MAX); }
  { unsigned p = -1; P(UINT32_MAX & p); }
  { unsigned p = -1; P(UINT32_MAX | p); }
  { unsigned p = -1; P(UINT32_MAX ^ p); }
  { unsigned p = -1; P(p & UINT32_MAX); }
  { unsigned p = -1; P(p | UINT32_MAX); }
  { unsigned p = -1; P(1 ? UINT32_MAX : p); }
  { unsigned p = -1; P(1 ? p : UINT32_MAX); }
  { unsigned p = -1; P(0 ? UINT32_MAX : p); }
  { unsigned p = -1; P(TC(UINT32_MAX + p)); }
  { unsigned p = -1; P(TC(p + UINT32_MAX)); }
  { unsigned p = -1; P(TC(1 ? UINT32_MAX : p)); }
  { unsigned p = -1; P(sizeof(UINT32_MAX + p)); }
  { unsigned p = -1; P(UINT32_MAX / p); }
  { unsigned p = -1; P(UINT32_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UINT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UINT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UINT32_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UINT32_MAX; P(t); }
  { long p = -1; P(UINT32_MAX < p); }
  { long p = -1; P(UINT32_MAX > p); }
  { long p = -1; P(UINT32_MAX == p); }
  { long p = -1; P(UINT32_MAX != p); }
  { long p = -1; P(UINT32_MAX <= p); }
  { long p = -1; P(UINT32_MAX >= p); }
  { long p = -1; P(p < UINT32_MAX); }
  { long p = -1; P(p > UINT32_MAX); }
  { long p = -1; P(p == UINT32_MAX); }
  { long p = -1; P(p <= UINT32_MAX); }
  { long p = -1; P(UINT32_MAX + p); }
  { long p = -1; P(p + UINT32_MAX); }
  { long p = -1; P(UINT32_MAX - p); }
  { long p = -1; P(p - UINT32_MAX); }
  { long p = -1; P(UINT32_MAX * p); }
  { long p = -1; P(p * UINT32_MAX); }
  { long p = -1; P(UINT32_MAX & p); }
  { long p = -1; P(UINT32_MAX | p); }
  { long p = -1; P(UINT32_MAX ^ p); }
  { long p = -1; P(p & UINT32_MAX); }
  { long p = -1; P(p | UINT32_MAX); }
  { long p = -1; P(1 ? UINT32_MAX : p); }
  { long p = -1; P(1 ? p : UINT32_MAX); }
  { long p = -1; P(0 ? UINT32_MAX : p); }
  { long p = -1; P(TC(UINT32_MAX + p)); }
  { long p = -1; P(TC(p + UINT32_MAX)); }
  { long p = -1; P(TC(1 ? UINT32_MAX : p)); }
  { long p = -1; P(sizeof(UINT32_MAX + p)); }
  { long p = -1; long t = p; t += UINT32_MAX; P(t); }
  { long p = -1; long t = p; t -= UINT32_MAX; P(t); }
  { long p = -1; long t = p; t &= UINT32_MAX; P(t); }
  { long p = -1; long t = p; t |= UINT32_MAX; P(t); }
  { unsigned long p = -1; P(UINT32_MAX < p); }
  { unsigned long p = -1; P(UINT32_MAX > p); }
  { unsigned long p = -1; P(UINT32_MAX == p); }
  { unsigned long p = -1; P(UINT32_MAX != p); }
  { unsigned long p = -1; P(UINT32_MAX <= p); }
  { unsigned long p = -1; P(UINT32_MAX >= p); }
  { unsigned long p = -1; P(p < UINT32_MAX); }
  { unsigned long p = -1; P(p > UINT32_MAX); }
  { unsigned long p = -1; P(p == UINT32_MAX); }
  { unsigned long p = -1; P(p <= UINT32_MAX); }
  { unsigned long p = -1; P(UINT32_MAX + p); }
  { unsigned long p = -1; P(p + UINT32_MAX); }
  { unsigned long p = -1; P(UINT32_MAX - p); }
  { unsigned long p = -1; P(p - UINT32_MAX); }
  { unsigned long p = -1; P(UINT32_MAX * p); }
  { unsigned long p = -1; P(p * UINT32_MAX); }
  { unsigned long p = -1; P(UINT32_MAX & p); }
  { unsigned long p = -1; P(UINT32_MAX | p); }
  { unsigned long p = -1; P(UINT32_MAX ^ p); }
  { unsigned long p = -1; P(p & UINT32_MAX); }
  { unsigned long p = -1; P(p | UINT32_MAX); }
  { unsigned long p = -1; P(1 ? UINT32_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UINT32_MAX); }
  { unsigned long p = -1; P(0 ? UINT32_MAX : p); }
  { unsigned long p = -1; P(TC(UINT32_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UINT32_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UINT32_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UINT32_MAX + p)); }
  { unsigned long p = -1; P(UINT32_MAX / p); }
  { unsigned long p = -1; P(UINT32_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UINT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UINT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UINT32_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UINT32_MAX; P(t); }
  P(UINT64_MAX > 0);
  P(UINT64_MAX < 0);
  P(UINT64_MAX == 0);
  P(UINT64_MAX != 0);
  P(UINT64_MAX >= 0);
  P(UINT64_MAX <= 0);
  P(0 < UINT64_MAX);
  P(0 > UINT64_MAX);
  P(0 == UINT64_MAX);
  P(+UINT64_MAX);
  P(-UINT64_MAX);
  P(~UINT64_MAX);
  P(!UINT64_MAX);
  P((+UINT64_MAX) > 0);
  P(sizeof(UINT64_MAX));
  P(sizeof(+UINT64_MAX));
  P(TC(UINT64_MAX));
  P(TC(+UINT64_MAX));
  P(TC(-UINT64_MAX));
  P(TC(~UINT64_MAX));
  P((_Bool)UINT64_MAX);
  P((signed char)UINT64_MAX);
  P((unsigned char)UINT64_MAX);
  P((short)UINT64_MAX);
  P((unsigned short)UINT64_MAX);
  P((int)UINT64_MAX);
  P((unsigned)UINT64_MAX);
  P((long)UINT64_MAX);
  P((unsigned long)UINT64_MAX);
  P((long long)UINT64_MAX);
  P((unsigned long long)UINT64_MAX);
  P((long long)UINT64_MAX > 0);
  P((long long)UINT64_MAX < 0);
  { int x = UINT64_MAX; P(x); }
  { unsigned x = UINT64_MAX; P(x); }
  { long x = UINT64_MAX; P(x); }
  { unsigned long x = UINT64_MAX; P(x); }
  P(UINT64_MAX + 1);
  P(UINT64_MAX - 1);
  P(UINT64_MAX - 1 > 0);
  P(UINT64_MAX + 1 > 0);
  P(UINT64_MAX + 1u);
  P(UINT64_MAX - 1u);
  P(UINT64_MAX + 1l);
  P(UINT64_MAX - 1ul);
  { int p = -1; P(UINT64_MAX < p); }
  { int p = -1; P(UINT64_MAX > p); }
  { int p = -1; P(UINT64_MAX == p); }
  { int p = -1; P(UINT64_MAX != p); }
  { int p = -1; P(UINT64_MAX <= p); }
  { int p = -1; P(UINT64_MAX >= p); }
  { int p = -1; P(p < UINT64_MAX); }
  { int p = -1; P(p > UINT64_MAX); }
  { int p = -1; P(p == UINT64_MAX); }
  { int p = -1; P(p <= UINT64_MAX); }
  { int p = -1; P(UINT64_MAX + p); }
  { int p = -1; P(p + UINT64_MAX); }
  { int p = -1; P(UINT64_MAX - p); }
  { int p = -1; P(p - UINT64_MAX); }
  { int p = -1; P(UINT64_MAX * p); }
  { int p = -1; P(p * UINT64_MAX); }
  { int p = -1; P(UINT64_MAX & p); }
  { int p = -1; P(UINT64_MAX | p); }
  { int p = -1; P(UINT64_MAX ^ p); }
  { int p = -1; P(p & UINT64_MAX); }
  { int p = -1; P(p | UINT64_MAX); }
  { int p = -1; P(1 ? UINT64_MAX : p); }
  { int p = -1; P(1 ? p : UINT64_MAX); }
  { int p = -1; P(0 ? UINT64_MAX : p); }
  { int p = -1; P(TC(UINT64_MAX + p)); }
  { int p = -1; P(TC(p + UINT64_MAX)); }
  { int p = -1; P(TC(1 ? UINT64_MAX : p)); }
  { int p = -1; P(sizeof(UINT64_MAX + p)); }
  { int p = -1; int t = p; t += UINT64_MAX; P(t); }
  { int p = -1; int t = p; t -= UINT64_MAX; P(t); }
  { int p = -1; int t = p; t &= UINT64_MAX; P(t); }
  { int p = -1; int t = p; t |= UINT64_MAX; P(t); }
  { unsigned p = -1; P(UINT64_MAX < p); }
  { unsigned p = -1; P(UINT64_MAX > p); }
  { unsigned p = -1; P(UINT64_MAX == p); }
  { unsigned p = -1; P(UINT64_MAX != p); }
  { unsigned p = -1; P(UINT64_MAX <= p); }
  { unsigned p = -1; P(UINT64_MAX >= p); }
  { unsigned p = -1; P(p < UINT64_MAX); }
  { unsigned p = -1; P(p > UINT64_MAX); }
  { unsigned p = -1; P(p == UINT64_MAX); }
  { unsigned p = -1; P(p <= UINT64_MAX); }
  { unsigned p = -1; P(UINT64_MAX + p); }
  { unsigned p = -1; P(p + UINT64_MAX); }
  { unsigned p = -1; P(UINT64_MAX - p); }
  { unsigned p = -1; P(p - UINT64_MAX); }
  { unsigned p = -1; P(UINT64_MAX * p); }
  { unsigned p = -1; P(p * UINT64_MAX); }
  { unsigned p = -1; P(UINT64_MAX & p); }
  { unsigned p = -1; P(UINT64_MAX | p); }
  { unsigned p = -1; P(UINT64_MAX ^ p); }
  { unsigned p = -1; P(p & UINT64_MAX); }
  { unsigned p = -1; P(p | UINT64_MAX); }
  { unsigned p = -1; P(1 ? UINT64_MAX : p); }
  { unsigned p = -1; P(1 ? p : UINT64_MAX); }
  { unsigned p = -1; P(0 ? UINT64_MAX : p); }
  { unsigned p = -1; P(TC(UINT64_MAX + p)); }
  { unsigned p = -1; P(TC(p + UINT64_MAX)); }
  { unsigned p = -1; P(TC(1 ? UINT64_MAX : p)); }
  { unsigned p = -1; P(sizeof(UINT64_MAX + p)); }
  { unsigned p = -1; P(UINT64_MAX / p); }
  { unsigned p = -1; P(UINT64_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UINT64_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UINT64_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UINT64_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UINT64_MAX; P(t); }
  { long p = -1; P(UINT64_MAX < p); }
  { long p = -1; P(UINT64_MAX > p); }
  { long p = -1; P(UINT64_MAX == p); }
  { long p = -1; P(UINT64_MAX != p); }
  { long p = -1; P(UINT64_MAX <= p); }
  { long p = -1; P(UINT64_MAX >= p); }
  { long p = -1; P(p < UINT64_MAX); }
  { long p = -1; P(p > UINT64_MAX); }
  { long p = -1; P(p == UINT64_MAX); }
  { long p = -1; P(p <= UINT64_MAX); }
  { long p = -1; P(UINT64_MAX + p); }
  { long p = -1; P(p + UINT64_MAX); }
  { long p = -1; P(UINT64_MAX - p); }
  { long p = -1; P(p - UINT64_MAX); }
  { long p = -1; P(UINT64_MAX * p); }
  { long p = -1; P(p * UINT64_MAX); }
  { long p = -1; P(UINT64_MAX & p); }
  { long p = -1; P(UINT64_MAX | p); }
  { long p = -1; P(UINT64_MAX ^ p); }
  { long p = -1; P(p & UINT64_MAX); }
  { long p = -1; P(p | UINT64_MAX); }
  { long p = -1; P(1 ? UINT64_MAX : p); }
  { long p = -1; P(1 ? p : UINT64_MAX); }
  { long p = -1; P(0 ? UINT64_MAX : p); }
  { long p = -1; P(TC(UINT64_MAX + p)); }
  { long p = -1; P(TC(p + UINT64_MAX)); }
  { long p = -1; P(TC(1 ? UINT64_MAX : p)); }
  { long p = -1; P(sizeof(UINT64_MAX + p)); }
  { long p = -1; long t = p; t += UINT64_MAX; P(t); }
  { long p = -1; long t = p; t -= UINT64_MAX; P(t); }
  { long p = -1; long t = p; t &= UINT64_MAX; P(t); }
  { long p = -1; long t = p; t |= UINT64_MAX; P(t); }
  { unsigned long p = -1; P(UINT64_MAX < p); }
  { unsigned long p = -1; P(UINT64_MAX > p); }
  { unsigned long p = -1; P(UINT64_MAX == p); }
  { unsigned long p = -1; P(UINT64_MAX != p); }
  { unsigned long p = -1; P(UINT64_MAX <= p); }
  { unsigned long p = -1; P(UINT64_MAX >= p); }
  { unsigned long p = -1; P(p < UINT64_MAX); }
  { unsigned long p = -1; P(p > UINT64_MAX); }
  { unsigned long p = -1; P(p == UINT64_MAX); }
  { unsigned long p = -1; P(p <= UINT64_MAX); }
  { unsigned long p = -1; P(UINT64_MAX + p); }
  { unsigned long p = -1; P(p + UINT64_MAX); }
  { unsigned long p = -1; P(UINT64_MAX - p); }
  { unsigned long p = -1; P(p - UINT64_MAX); }
  { unsigned long p = -1; P(UINT64_MAX * p); }
  { unsigned long p = -1; P(p * UINT64_MAX); }
  { unsigned long p = -1; P(UINT64_MAX & p); }
  { unsigned long p = -1; P(UINT64_MAX | p); }
  { unsigned long p = -1; P(UINT64_MAX ^ p); }
  { unsigned long p = -1; P(p & UINT64_MAX); }
  { unsigned long p = -1; P(p | UINT64_MAX); }
  { unsigned long p = -1; P(1 ? UINT64_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UINT64_MAX); }
  { unsigned long p = -1; P(0 ? UINT64_MAX : p); }
  { unsigned long p = -1; P(TC(UINT64_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UINT64_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UINT64_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UINT64_MAX + p)); }
  { unsigned long p = -1; P(UINT64_MAX / p); }
  { unsigned long p = -1; P(UINT64_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UINT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UINT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UINT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UINT64_MAX; P(t); }
  P(UINTMAX_MAX > 0);
  P(UINTMAX_MAX < 0);
  P(UINTMAX_MAX == 0);
  P(UINTMAX_MAX != 0);
  P(UINTMAX_MAX >= 0);
  P(UINTMAX_MAX <= 0);
  P(0 < UINTMAX_MAX);
  P(0 > UINTMAX_MAX);
  P(0 == UINTMAX_MAX);
  P(+UINTMAX_MAX);
  P(-UINTMAX_MAX);
  P(~UINTMAX_MAX);
  P(!UINTMAX_MAX);
  P((+UINTMAX_MAX) > 0);
  P(sizeof(UINTMAX_MAX));
  P(sizeof(+UINTMAX_MAX));
  P(TC(UINTMAX_MAX));
  P(TC(+UINTMAX_MAX));
  P(TC(-UINTMAX_MAX));
  P(TC(~UINTMAX_MAX));
  P((_Bool)UINTMAX_MAX);
  P((signed char)UINTMAX_MAX);
  P((unsigned char)UINTMAX_MAX);
  P((short)UINTMAX_MAX);
  P((unsigned short)UINTMAX_MAX);
  P((int)UINTMAX_MAX);
  P((unsigned)UINTMAX_MAX);
  P((long)UINTMAX_MAX);
  P((unsigned long)UINTMAX_MAX);
  P((long long)UINTMAX_MAX);
  P((unsigned long long)UINTMAX_MAX);
  P((long long)UINTMAX_MAX > 0);
  P((long long)UINTMAX_MAX < 0);
  { int x = UINTMAX_MAX; P(x); }
  { unsigned x = UINTMAX_MAX; P(x); }
  { long x = UINTMAX_MAX; P(x); }
  { unsigned long x = UINTMAX_MAX; P(x); }
  P(UINTMAX_MAX + 1);
  P(UINTMAX_MAX - 1);
  P(UINTMAX_MAX - 1 > 0);
  P(UINTMAX_MAX + 1 > 0);
  P(UINTMAX_MAX + 1u);
  P(UINTMAX_MAX - 1u);
  P(UINTMAX_MAX + 1l);
  P(UINTMAX_MAX - 1ul);
  { int p = -1; P(UINTMAX_MAX < p); }
  { int p = -1; P(UINTMAX_MAX > p); }
  { int p = -1; P(UINTMAX_MAX == p); }
  { int p = -1; P(UINTMAX_MAX != p); }
  { int p = -1; P(UINTMAX_MAX <= p); }
  { int p = -1; P(UINTMAX_MAX >= p); }
  { int p = -1; P(p < UINTMAX_MAX); }
  { int p = -1; P(p > UINTMAX_MAX); }
  { int p = -1; P(p == UINTMAX_MAX); }
  { int p = -1; P(p <= UINTMAX_MAX); }
  { int p = -1; P(UINTMAX_MAX + p); }
  { int p = -1; P(p + UINTMAX_MAX); }
  { int p = -1; P(UINTMAX_MAX - p); }
  { int p = -1; P(p - UINTMAX_MAX); }
  { int p = -1; P(UINTMAX_MAX * p); }
  { int p = -1; P(p * UINTMAX_MAX); }
  { int p = -1; P(UINTMAX_MAX & p); }
  { int p = -1; P(UINTMAX_MAX | p); }
  { int p = -1; P(UINTMAX_MAX ^ p); }
  { int p = -1; P(p & UINTMAX_MAX); }
  { int p = -1; P(p | UINTMAX_MAX); }
  { int p = -1; P(1 ? UINTMAX_MAX : p); }
  { int p = -1; P(1 ? p : UINTMAX_MAX); }
  { int p = -1; P(0 ? UINTMAX_MAX : p); }
  { int p = -1; P(TC(UINTMAX_MAX + p)); }
  { int p = -1; P(TC(p + UINTMAX_MAX)); }
  { int p = -1; P(TC(1 ? UINTMAX_MAX : p)); }
  { int p = -1; P(sizeof(UINTMAX_MAX + p)); }
  { int p = -1; int t = p; t += UINTMAX_MAX; P(t); }
  { int p = -1; int t = p; t -= UINTMAX_MAX; P(t); }
  { int p = -1; int t = p; t &= UINTMAX_MAX; P(t); }
  { int p = -1; int t = p; t |= UINTMAX_MAX; P(t); }
  { unsigned p = -1; P(UINTMAX_MAX < p); }
  { unsigned p = -1; P(UINTMAX_MAX > p); }
  { unsigned p = -1; P(UINTMAX_MAX == p); }
  { unsigned p = -1; P(UINTMAX_MAX != p); }
  { unsigned p = -1; P(UINTMAX_MAX <= p); }
  { unsigned p = -1; P(UINTMAX_MAX >= p); }
  { unsigned p = -1; P(p < UINTMAX_MAX); }
  { unsigned p = -1; P(p > UINTMAX_MAX); }
  { unsigned p = -1; P(p == UINTMAX_MAX); }
  { unsigned p = -1; P(p <= UINTMAX_MAX); }
  { unsigned p = -1; P(UINTMAX_MAX + p); }
  { unsigned p = -1; P(p + UINTMAX_MAX); }
  { unsigned p = -1; P(UINTMAX_MAX - p); }
  { unsigned p = -1; P(p - UINTMAX_MAX); }
  { unsigned p = -1; P(UINTMAX_MAX * p); }
  { unsigned p = -1; P(p * UINTMAX_MAX); }
  { unsigned p = -1; P(UINTMAX_MAX & p); }
  { unsigned p = -1; P(UINTMAX_MAX | p); }
  { unsigned p = -1; P(UINTMAX_MAX ^ p); }
  { unsigned p = -1; P(p & UINTMAX_MAX); }
  { unsigned p = -1; P(p | UINTMAX_MAX); }
  { unsigned p = -1; P(1 ? UINTMAX_MAX : p); }
  { unsigned p = -1; P(1 ? p : UINTMAX_MAX); }
  { unsigned p = -1; P(0 ? UINTMAX_MAX : p); }
  { unsigned p = -1; P(TC(UINTMAX_MAX + p)); }
  { unsigned p = -1; P(TC(p + UINTMAX_MAX)); }
  { unsigned p = -1; P(TC(1 ? UINTMAX_MAX : p)); }
  { unsigned p = -1; P(sizeof(UINTMAX_MAX + p)); }
  { unsigned p = -1; P(UINTMAX_MAX / p); }
  { unsigned p = -1; P(UINTMAX_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UINTMAX_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UINTMAX_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UINTMAX_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UINTMAX_MAX; P(t); }
  { long p = -1; P(UINTMAX_MAX < p); }
  { long p = -1; P(UINTMAX_MAX > p); }
  { long p = -1; P(UINTMAX_MAX == p); }
  { long p = -1; P(UINTMAX_MAX != p); }
  { long p = -1; P(UINTMAX_MAX <= p); }
  { long p = -1; P(UINTMAX_MAX >= p); }
  { long p = -1; P(p < UINTMAX_MAX); }
  { long p = -1; P(p > UINTMAX_MAX); }
  { long p = -1; P(p == UINTMAX_MAX); }
  { long p = -1; P(p <= UINTMAX_MAX); }
  { long p = -1; P(UINTMAX_MAX + p); }
  { long p = -1; P(p + UINTMAX_MAX); }
  { long p = -1; P(UINTMAX_MAX - p); }
  { long p = -1; P(p - UINTMAX_MAX); }
  { long p = -1; P(UINTMAX_MAX * p); }
  { long p = -1; P(p * UINTMAX_MAX); }
  { long p = -1; P(UINTMAX_MAX & p); }
  { long p = -1; P(UINTMAX_MAX | p); }
  { long p = -1; P(UINTMAX_MAX ^ p); }
  { long p = -1; P(p & UINTMAX_MAX); }
  { long p = -1; P(p | UINTMAX_MAX); }
  { long p = -1; P(1 ? UINTMAX_MAX : p); }
  { long p = -1; P(1 ? p : UINTMAX_MAX); }
  { long p = -1; P(0 ? UINTMAX_MAX : p); }
  { long p = -1; P(TC(UINTMAX_MAX + p)); }
  { long p = -1; P(TC(p + UINTMAX_MAX)); }
  { long p = -1; P(TC(1 ? UINTMAX_MAX : p)); }
  { long p = -1; P(sizeof(UINTMAX_MAX + p)); }
  { long p = -1; long t = p; t += UINTMAX_MAX; P(t); }
  { long p = -1; long t = p; t -= UINTMAX_MAX; P(t); }
  { long p = -1; long t = p; t &= UINTMAX_MAX; P(t); }
  { long p = -1; long t = p; t |= UINTMAX_MAX; P(t); }
  { unsigned long p = -1; P(UINTMAX_MAX < p); }
  { unsigned long p = -1; P(UINTMAX_MAX > p); }
  { unsigned long p = -1; P(UINTMAX_MAX == p); }
  { unsigned long p = -1; P(UINTMAX_MAX != p); }
  { unsigned long p = -1; P(UINTMAX_MAX <= p); }
  { unsigned long p = -1; P(UINTMAX_MAX >= p); }
  { unsigned long p = -1; P(p < UINTMAX_MAX); }
  { unsigned long p = -1; P(p > UINTMAX_MAX); }
  { unsigned long p = -1; P(p == UINTMAX_MAX); }
  { unsigned long p = -1; P(p <= UINTMAX_MAX); }
  { unsigned long p = -1; P(UINTMAX_MAX + p); }
  { unsigned long p = -1; P(p + UINTMAX_MAX); }
  { unsigned long p = -1; P(UINTMAX_MAX - p); }
  { unsigned long p = -1; P(p - UINTMAX_MAX); }
  { unsigned long p = -1; P(UINTMAX_MAX * p); }
  { unsigned long p = -1; P(p * UINTMAX_MAX); }
  { unsigned long p = -1; P(UINTMAX_MAX & p); }
  { unsigned long p = -1; P(UINTMAX_MAX | p); }
  { unsigned long p = -1; P(UINTMAX_MAX ^ p); }
  { unsigned long p = -1; P(p & UINTMAX_MAX); }
  { unsigned long p = -1; P(p | UINTMAX_MAX); }
  { unsigned long p = -1; P(1 ? UINTMAX_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UINTMAX_MAX); }
  { unsigned long p = -1; P(0 ? UINTMAX_MAX : p); }
  { unsigned long p = -1; P(TC(UINTMAX_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UINTMAX_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UINTMAX_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UINTMAX_MAX + p)); }
  { unsigned long p = -1; P(UINTMAX_MAX / p); }
  { unsigned long p = -1; P(UINTMAX_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UINTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UINTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UINTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UINTMAX_MAX; P(t); }
  P(UINTPTR_MAX > 0);
  P(UINTPTR_MAX < 0);
  P(UINTPTR_MAX == 0);
  P(UINTPTR_MAX != 0);
  P(UINTPTR_MAX >= 0);
  P(UINTPTR_MAX <= 0);
  P(0 < UINTPTR_MAX);
  P(0 > UINTPTR_MAX);
  P(0 == UINTPTR_MAX);
  P(+UINTPTR_MAX);
  P(-UINTPTR_MAX);
  P(~UINTPTR_MAX);
  P(!UINTPTR_MAX);
  P((+UINTPTR_MAX) > 0);
  P(sizeof(UINTPTR_MAX));
  P(sizeof(+UINTPTR_MAX));
  P(TC(UINTPTR_MAX));
  P(TC(+UINTPTR_MAX));
  P(TC(-UINTPTR_MAX));
  P(TC(~UINTPTR_MAX));
  P((_Bool)UINTPTR_MAX);
  P((signed char)UINTPTR_MAX);
  P((unsigned char)UINTPTR_MAX);
  P((short)UINTPTR_MAX);
  P((unsigned short)UINTPTR_MAX);
  P((int)UINTPTR_MAX);
  P((unsigned)UINTPTR_MAX);
  P((long)UINTPTR_MAX);
  P((unsigned long)UINTPTR_MAX);
  P((long long)UINTPTR_MAX);
  P((unsigned long long)UINTPTR_MAX);
  P((long long)UINTPTR_MAX > 0);
  P((long long)UINTPTR_MAX < 0);
  { int x = UINTPTR_MAX; P(x); }
  { unsigned x = UINTPTR_MAX; P(x); }
  { long x = UINTPTR_MAX; P(x); }
  { unsigned long x = UINTPTR_MAX; P(x); }
  P(UINTPTR_MAX + 1);
  P(UINTPTR_MAX - 1);
  P(UINTPTR_MAX - 1 > 0);
  P(UINTPTR_MAX + 1 > 0);
  P(UINTPTR_MAX + 1u);
  P(UINTPTR_MAX - 1u);
  P(UINTPTR_MAX + 1l);
  P(UINTPTR_MAX - 1ul);
  { int p = -1; P(UINTPTR_MAX < p); }
  { int p = -1; P(UINTPTR_MAX > p); }
  { int p = -1; P(UINTPTR_MAX == p); }
  { int p = -1; P(UINTPTR_MAX != p); }
  { int p = -1; P(UINTPTR_MAX <= p); }
  { int p = -1; P(UINTPTR_MAX >= p); }
  { int p = -1; P(p < UINTPTR_MAX); }
  { int p = -1; P(p > UINTPTR_MAX); }
  { int p = -1; P(p == UINTPTR_MAX); }
  { int p = -1; P(p <= UINTPTR_MAX); }
  { int p = -1; P(UINTPTR_MAX + p); }
  { int p = -1; P(p + UINTPTR_MAX); }
  { int p = -1; P(UINTPTR_MAX - p); }
  { int p = -1; P(p - UINTPTR_MAX); }
  { int p = -1; P(UINTPTR_MAX * p); }
  { int p = -1; P(p * UINTPTR_MAX); }
  { int p = -1; P(UINTPTR_MAX & p); }
  { int p = -1; P(UINTPTR_MAX | p); }
  { int p = -1; P(UINTPTR_MAX ^ p); }
  { int p = -1; P(p & UINTPTR_MAX); }
  { int p = -1; P(p | UINTPTR_MAX); }
  { int p = -1; P(1 ? UINTPTR_MAX : p); }
  { int p = -1; P(1 ? p : UINTPTR_MAX); }
  { int p = -1; P(0 ? UINTPTR_MAX : p); }
  { int p = -1; P(TC(UINTPTR_MAX + p)); }
  { int p = -1; P(TC(p + UINTPTR_MAX)); }
  { int p = -1; P(TC(1 ? UINTPTR_MAX : p)); }
  { int p = -1; P(sizeof(UINTPTR_MAX + p)); }
  { int p = -1; int t = p; t += UINTPTR_MAX; P(t); }
  { int p = -1; int t = p; t -= UINTPTR_MAX; P(t); }
  { int p = -1; int t = p; t &= UINTPTR_MAX; P(t); }
  { int p = -1; int t = p; t |= UINTPTR_MAX; P(t); }
  { unsigned p = -1; P(UINTPTR_MAX < p); }
  { unsigned p = -1; P(UINTPTR_MAX > p); }
  { unsigned p = -1; P(UINTPTR_MAX == p); }
  { unsigned p = -1; P(UINTPTR_MAX != p); }
  { unsigned p = -1; P(UINTPTR_MAX <= p); }
  { unsigned p = -1; P(UINTPTR_MAX >= p); }
  { unsigned p = -1; P(p < UINTPTR_MAX); }
  { unsigned p = -1; P(p > UINTPTR_MAX); }
  { unsigned p = -1; P(p == UINTPTR_MAX); }
  { unsigned p = -1; P(p <= UINTPTR_MAX); }
  { unsigned p = -1; P(UINTPTR_MAX + p); }
  { unsigned p = -1; P(p + UINTPTR_MAX); }
  { unsigned p = -1; P(UINTPTR_MAX - p); }
  { unsigned p = -1; P(p - UINTPTR_MAX); }
  { unsigned p = -1; P(UINTPTR_MAX * p); }
  { unsigned p = -1; P(p * UINTPTR_MAX); }
  { unsigned p = -1; P(UINTPTR_MAX & p); }
  { unsigned p = -1; P(UINTPTR_MAX | p); }
  { unsigned p = -1; P(UINTPTR_MAX ^ p); }
  { unsigned p = -1; P(p & UINTPTR_MAX); }
  { unsigned p = -1; P(p | UINTPTR_MAX); }
  { unsigned p = -1; P(1 ? UINTPTR_MAX : p); }
  { unsigned p = -1; P(1 ? p : UINTPTR_MAX); }
  { unsigned p = -1; P(0 ? UINTPTR_MAX : p); }
  { unsigned p = -1; P(TC(UINTPTR_MAX + p)); }
  { unsigned p = -1; P(TC(p + UINTPTR_MAX)); }
  { unsigned p = -1; P(TC(1 ? UINTPTR_MAX : p)); }
  { unsigned p = -1; P(sizeof(UINTPTR_MAX + p)); }
  { unsigned p = -1; P(UINTPTR_MAX / p); }
  { unsigned p = -1; P(UINTPTR_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += UINTPTR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= UINTPTR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= UINTPTR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= UINTPTR_MAX; P(t); }
  { long p = -1; P(UINTPTR_MAX < p); }
  { long p = -1; P(UINTPTR_MAX > p); }
  { long p = -1; P(UINTPTR_MAX == p); }
  { long p = -1; P(UINTPTR_MAX != p); }
  { long p = -1; P(UINTPTR_MAX <= p); }
  { long p = -1; P(UINTPTR_MAX >= p); }
  { long p = -1; P(p < UINTPTR_MAX); }
  { long p = -1; P(p > UINTPTR_MAX); }
  { long p = -1; P(p == UINTPTR_MAX); }
  { long p = -1; P(p <= UINTPTR_MAX); }
  { long p = -1; P(UINTPTR_MAX + p); }
  { long p = -1; P(p + UINTPTR_MAX); }
  { long p = -1; P(UINTPTR_MAX - p); }
  { long p = -1; P(p - UINTPTR_MAX); }
  { long p = -1; P(UINTPTR_MAX * p); }
  { long p = -1; P(p * UINTPTR_MAX); }
  { long p = -1; P(UINTPTR_MAX & p); }
  { long p = -1; P(UINTPTR_MAX | p); }
  { long p = -1; P(UINTPTR_MAX ^ p); }
  { long p = -1; P(p & UINTPTR_MAX); }
  { long p = -1; P(p | UINTPTR_MAX); }
  { long p = -1; P(1 ? UINTPTR_MAX : p); }
  { long p = -1; P(1 ? p : UINTPTR_MAX); }
  { long p = -1; P(0 ? UINTPTR_MAX : p); }
  { long p = -1; P(TC(UINTPTR_MAX + p)); }
  { long p = -1; P(TC(p + UINTPTR_MAX)); }
  { long p = -1; P(TC(1 ? UINTPTR_MAX : p)); }
  { long p = -1; P(sizeof(UINTPTR_MAX + p)); }
  { long p = -1; long t = p; t += UINTPTR_MAX; P(t); }
  { long p = -1; long t = p; t -= UINTPTR_MAX; P(t); }
  { long p = -1; long t = p; t &= UINTPTR_MAX; P(t); }
  { long p = -1; long t = p; t |= UINTPTR_MAX; P(t); }
  { unsigned long p = -1; P(UINTPTR_MAX < p); }
  { unsigned long p = -1; P(UINTPTR_MAX > p); }
  { unsigned long p = -1; P(UINTPTR_MAX == p); }
  { unsigned long p = -1; P(UINTPTR_MAX != p); }
  { unsigned long p = -1; P(UINTPTR_MAX <= p); }
  { unsigned long p = -1; P(UINTPTR_MAX >= p); }
  { unsigned long p = -1; P(p < UINTPTR_MAX); }
  { unsigned long p = -1; P(p > UINTPTR_MAX); }
  { unsigned long p = -1; P(p == UINTPTR_MAX); }
  { unsigned long p = -1; P(p <= UINTPTR_MAX); }
  { unsigned long p = -1; P(UINTPTR_MAX + p); }
  { unsigned long p = -1; P(p + UINTPTR_MAX); }
  { unsigned long p = -1; P(UINTPTR_MAX - p); }
  { unsigned long p = -1; P(p - UINTPTR_MAX); }
  { unsigned long p = -1; P(UINTPTR_MAX * p); }
  { unsigned long p = -1; P(p * UINTPTR_MAX); }
  { unsigned long p = -1; P(UINTPTR_MAX & p); }
  { unsigned long p = -1; P(UINTPTR_MAX | p); }
  { unsigned long p = -1; P(UINTPTR_MAX ^ p); }
  { unsigned long p = -1; P(p & UINTPTR_MAX); }
  { unsigned long p = -1; P(p | UINTPTR_MAX); }
  { unsigned long p = -1; P(1 ? UINTPTR_MAX : p); }
  { unsigned long p = -1; P(1 ? p : UINTPTR_MAX); }
  { unsigned long p = -1; P(0 ? UINTPTR_MAX : p); }
  { unsigned long p = -1; P(TC(UINTPTR_MAX + p)); }
  { unsigned long p = -1; P(TC(p + UINTPTR_MAX)); }
  { unsigned long p = -1; P(TC(1 ? UINTPTR_MAX : p)); }
  { unsigned long p = -1; P(sizeof(UINTPTR_MAX + p)); }
  { unsigned long p = -1; P(UINTPTR_MAX / p); }
  { unsigned long p = -1; P(UINTPTR_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += UINTPTR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= UINTPTR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= UINTPTR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= UINTPTR_MAX; P(t); }
  P(ULONG_MAX > 0);
  P(ULONG_MAX < 0);
  P(ULONG_MAX == 0);
  P(ULONG_MAX != 0);
  P(ULONG_MAX >= 0);
  P(ULONG_MAX <= 0);
  P(0 < ULONG_MAX);
  P(0 > ULONG_MAX);
  P(0 == ULONG_MAX);
  P(+ULONG_MAX);
  P(-ULONG_MAX);
  P(~ULONG_MAX);
  P(!ULONG_MAX);
  P((+ULONG_MAX) > 0);
  P(sizeof(ULONG_MAX));
  P(sizeof(+ULONG_MAX));
  P(TC(ULONG_MAX));
  P(TC(+ULONG_MAX));
  P(TC(-ULONG_MAX));
  P(TC(~ULONG_MAX));
  P((_Bool)ULONG_MAX);
  P((signed char)ULONG_MAX);
  P((unsigned char)ULONG_MAX);
  P((short)ULONG_MAX);
  P((unsigned short)ULONG_MAX);
  P((int)ULONG_MAX);
  P((unsigned)ULONG_MAX);
  P((long)ULONG_MAX);
  P((unsigned long)ULONG_MAX);
  P((long long)ULONG_MAX);
  P((unsigned long long)ULONG_MAX);
  P((long long)ULONG_MAX > 0);
  P((long long)ULONG_MAX < 0);
  { int x = ULONG_MAX; P(x); }
  { unsigned x = ULONG_MAX; P(x); }
  { long x = ULONG_MAX; P(x); }
  { unsigned long x = ULONG_MAX; P(x); }
  P(ULONG_MAX + 1);
  P(ULONG_MAX - 1);
  P(ULONG_MAX - 1 > 0);
  P(ULONG_MAX + 1 > 0);
  P(ULONG_MAX + 1u);
  P(ULONG_MAX - 1u);
  P(ULONG_MAX + 1l);
  P(ULONG_MAX - 1ul);
  { int p = -1; P(ULONG_MAX < p); }
  { int p = -1; P(ULONG_MAX > p); }
  { int p = -1; P(ULONG_MAX == p); }
  { int p = -1; P(ULONG_MAX != p); }
  { int p = -1; P(ULONG_MAX <= p); }
  { int p = -1; P(ULONG_MAX >= p); }
  { int p = -1; P(p < ULONG_MAX); }
  { int p = -1; P(p > ULONG_MAX); }
  { int p = -1; P(p == ULONG_MAX); }
  { int p = -1; P(p <= ULONG_MAX); }
  { int p = -1; P(ULONG_MAX + p); }
  { int p = -1; P(p + ULONG_MAX); }
  { int p = -1; P(ULONG_MAX - p); }
  { int p = -1; P(p - ULONG_MAX); }
  { int p = -1; P(ULONG_MAX * p); }
  { int p = -1; P(p * ULONG_MAX); }
  { int p = -1; P(ULONG_MAX & p); }
  { int p = -1; P(ULONG_MAX | p); }
  { int p = -1; P(ULONG_MAX ^ p); }
  { int p = -1; P(p & ULONG_MAX); }
  { int p = -1; P(p | ULONG_MAX); }
  { int p = -1; P(1 ? ULONG_MAX : p); }
  { int p = -1; P(1 ? p : ULONG_MAX); }
  { int p = -1; P(0 ? ULONG_MAX : p); }
  { int p = -1; P(TC(ULONG_MAX + p)); }
  { int p = -1; P(TC(p + ULONG_MAX)); }
  { int p = -1; P(TC(1 ? ULONG_MAX : p)); }
  { int p = -1; P(sizeof(ULONG_MAX + p)); }
  { int p = -1; int t = p; t += ULONG_MAX; P(t); }
  { int p = -1; int t = p; t -= ULONG_MAX; P(t); }
  { int p = -1; int t = p; t &= ULONG_MAX; P(t); }
  { int p = -1; int t = p; t |= ULONG_MAX; P(t); }
  { unsigned p = -1; P(ULONG_MAX < p); }
  { unsigned p = -1; P(ULONG_MAX > p); }
  { unsigned p = -1; P(ULONG_MAX == p); }
  { unsigned p = -1; P(ULONG_MAX != p); }
  { unsigned p = -1; P(ULONG_MAX <= p); }
  { unsigned p = -1; P(ULONG_MAX >= p); }
  { unsigned p = -1; P(p < ULONG_MAX); }
  { unsigned p = -1; P(p > ULONG_MAX); }
  { unsigned p = -1; P(p == ULONG_MAX); }
  { unsigned p = -1; P(p <= ULONG_MAX); }
  { unsigned p = -1; P(ULONG_MAX + p); }
  { unsigned p = -1; P(p + ULONG_MAX); }
  { unsigned p = -1; P(ULONG_MAX - p); }
  { unsigned p = -1; P(p - ULONG_MAX); }
  { unsigned p = -1; P(ULONG_MAX * p); }
  { unsigned p = -1; P(p * ULONG_MAX); }
  { unsigned p = -1; P(ULONG_MAX & p); }
  { unsigned p = -1; P(ULONG_MAX | p); }
  { unsigned p = -1; P(ULONG_MAX ^ p); }
  { unsigned p = -1; P(p & ULONG_MAX); }
  { unsigned p = -1; P(p | ULONG_MAX); }
  { unsigned p = -1; P(1 ? ULONG_MAX : p); }
  { unsigned p = -1; P(1 ? p : ULONG_MAX); }
  { unsigned p = -1; P(0 ? ULONG_MAX : p); }
  { unsigned p = -1; P(TC(ULONG_MAX + p)); }
  { unsigned p = -1; P(TC(p + ULONG_MAX)); }
  { unsigned p = -1; P(TC(1 ? ULONG_MAX : p)); }
  { unsigned p = -1; P(sizeof(ULONG_MAX + p)); }
  { unsigned p = -1; P(ULONG_MAX / p); }
  { unsigned p = -1; P(ULONG_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += ULONG_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= ULONG_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= ULONG_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= ULONG_MAX; P(t); }
  { long p = -1; P(ULONG_MAX < p); }
  { long p = -1; P(ULONG_MAX > p); }
  { long p = -1; P(ULONG_MAX == p); }
  { long p = -1; P(ULONG_MAX != p); }
  { long p = -1; P(ULONG_MAX <= p); }
  { long p = -1; P(ULONG_MAX >= p); }
  { long p = -1; P(p < ULONG_MAX); }
  { long p = -1; P(p > ULONG_MAX); }
  { long p = -1; P(p == ULONG_MAX); }
  { long p = -1; P(p <= ULONG_MAX); }
  { long p = -1; P(ULONG_MAX + p); }
  { long p = -1; P(p + ULONG_MAX); }
  { long p = -1; P(ULONG_MAX - p); }
  { long p = -1; P(p - ULONG_MAX); }
  { long p = -1; P(ULONG_MAX * p); }
  { long p = -1; P(p * ULONG_MAX); }
  { long p = -1; P(ULONG_MAX & p); }
  { long p = -1; P(ULONG_MAX | p); }
  { long p = -1; P(ULONG_MAX ^ p); }
  { long p = -1; P(p & ULONG_MAX); }
  { long p = -1; P(p | ULONG_MAX); }
  { long p = -1; P(1 ? ULONG_MAX : p); }
  { long p = -1; P(1 ? p : ULONG_MAX); }
  { long p = -1; P(0 ? ULONG_MAX : p); }
  { long p = -1; P(TC(ULONG_MAX + p)); }
  { long p = -1; P(TC(p + ULONG_MAX)); }
  { long p = -1; P(TC(1 ? ULONG_MAX : p)); }
  { long p = -1; P(sizeof(ULONG_MAX + p)); }
  { long p = -1; long t = p; t += ULONG_MAX; P(t); }
  { long p = -1; long t = p; t -= ULONG_MAX; P(t); }
  { long p = -1; long t = p; t &= ULONG_MAX; P(t); }
  { long p = -1; long t = p; t |= ULONG_MAX; P(t); }
  { unsigned long p = -1; P(ULONG_MAX < p); }
  { unsigned long p = -1; P(ULONG_MAX > p); }
  { unsigned long p = -1; P(ULONG_MAX == p); }
  { unsigned long p = -1; P(ULONG_MAX != p); }
  { unsigned long p = -1; P(ULONG_MAX <= p); }
  { unsigned long p = -1; P(ULONG_MAX >= p); }
  { unsigned long p = -1; P(p < ULONG_MAX); }
  { unsigned long p = -1; P(p > ULONG_MAX); }
  { unsigned long p = -1; P(p == ULONG_MAX); }
  { unsigned long p = -1; P(p <= ULONG_MAX); }
  { unsigned long p = -1; P(ULONG_MAX + p); }
  { unsigned long p = -1; P(p + ULONG_MAX); }
  { unsigned long p = -1; P(ULONG_MAX - p); }
  { unsigned long p = -1; P(p - ULONG_MAX); }
  { unsigned long p = -1; P(ULONG_MAX * p); }
  { unsigned long p = -1; P(p * ULONG_MAX); }
  { unsigned long p = -1; P(ULONG_MAX & p); }
  { unsigned long p = -1; P(ULONG_MAX | p); }
  { unsigned long p = -1; P(ULONG_MAX ^ p); }
  { unsigned long p = -1; P(p & ULONG_MAX); }
  { unsigned long p = -1; P(p | ULONG_MAX); }
  { unsigned long p = -1; P(1 ? ULONG_MAX : p); }
  { unsigned long p = -1; P(1 ? p : ULONG_MAX); }
  { unsigned long p = -1; P(0 ? ULONG_MAX : p); }
  { unsigned long p = -1; P(TC(ULONG_MAX + p)); }
  { unsigned long p = -1; P(TC(p + ULONG_MAX)); }
  { unsigned long p = -1; P(TC(1 ? ULONG_MAX : p)); }
  { unsigned long p = -1; P(sizeof(ULONG_MAX + p)); }
  { unsigned long p = -1; P(ULONG_MAX / p); }
  { unsigned long p = -1; P(ULONG_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += ULONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= ULONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= ULONG_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= ULONG_MAX; P(t); }
  P(IOV_MAX > 0);
  P(IOV_MAX < 0);
  P(IOV_MAX == 0);
  P(IOV_MAX != 0);
  P(IOV_MAX >= 0);
  P(IOV_MAX <= 0);
  P(0 < IOV_MAX);
  P(0 > IOV_MAX);
  P(0 == IOV_MAX);
  P(+IOV_MAX);
  P(-IOV_MAX);
  P(~IOV_MAX);
  P(!IOV_MAX);
  P((+IOV_MAX) > 0);
  P(sizeof(IOV_MAX));
  P(sizeof(+IOV_MAX));
  P(TC(IOV_MAX));
  P(TC(+IOV_MAX));
  P(TC(-IOV_MAX));
  P(TC(~IOV_MAX));
  P((_Bool)IOV_MAX);
  P((signed char)IOV_MAX);
  P((unsigned char)IOV_MAX);
  P((short)IOV_MAX);
  P((unsigned short)IOV_MAX);
  P((int)IOV_MAX);
  P((unsigned)IOV_MAX);
  P((long)IOV_MAX);
  P((unsigned long)IOV_MAX);
  P((long long)IOV_MAX);
  P((unsigned long long)IOV_MAX);
  P((long long)IOV_MAX > 0);
  P((long long)IOV_MAX < 0);
  { int x = IOV_MAX; P(x); }
  { unsigned x = IOV_MAX; P(x); }
  { long x = IOV_MAX; P(x); }
  { unsigned long x = IOV_MAX; P(x); }
  P(IOV_MAX + 1);
  P(IOV_MAX - 1);
  P(IOV_MAX - 1 > 0);
  P(IOV_MAX + 1 > 0);
  P(IOV_MAX + 1u);
  P(IOV_MAX - 1u);
  P(IOV_MAX + 1l);
  P(IOV_MAX - 1ul);
  { int p = -1; P(IOV_MAX < p); }
  { int p = -1; P(IOV_MAX > p); }
  { int p = -1; P(IOV_MAX == p); }
  { int p = -1; P(IOV_MAX != p); }
  { int p = -1; P(IOV_MAX <= p); }
  { int p = -1; P(IOV_MAX >= p); }
  { int p = -1; P(p < IOV_MAX); }
  { int p = -1; P(p > IOV_MAX); }
  { int p = -1; P(p == IOV_MAX); }
  { int p = -1; P(p <= IOV_MAX); }
  { int p = -1; P(IOV_MAX + p); }
  { int p = -1; P(p + IOV_MAX); }
  { int p = -1; P(IOV_MAX - p); }
  { int p = -1; P(p - IOV_MAX); }
  { int p = -1; P(IOV_MAX * p); }
  { int p = -1; P(p * IOV_MAX); }
  { int p = -1; P(IOV_MAX & p); }
  { int p = -1; P(IOV_MAX | p); }
  { int p = -1; P(IOV_MAX ^ p); }
  { int p = -1; P(p & IOV_MAX); }
  { int p = -1; P(p | IOV_MAX); }
  { int p = -1; P(1 ? IOV_MAX : p); }
  { int p = -1; P(1 ? p : IOV_MAX); }
  { int p = -1; P(0 ? IOV_MAX : p); }
  { int p = -1; P(TC(IOV_MAX + p)); }
  { int p = -1; P(TC(p + IOV_MAX)); }
  { int p = -1; P(TC(1 ? IOV_MAX : p)); }
  { int p = -1; P(sizeof(IOV_MAX + p)); }
  { int p = -1; int t = p; t += IOV_MAX; P(t); }
  { int p = -1; int t = p; t -= IOV_MAX; P(t); }
  { int p = -1; int t = p; t &= IOV_MAX; P(t); }
  { int p = -1; int t = p; t |= IOV_MAX; P(t); }
  { unsigned p = -1; P(IOV_MAX < p); }
  { unsigned p = -1; P(IOV_MAX > p); }
  { unsigned p = -1; P(IOV_MAX == p); }
  { unsigned p = -1; P(IOV_MAX != p); }
  { unsigned p = -1; P(IOV_MAX <= p); }
  { unsigned p = -1; P(IOV_MAX >= p); }
  { unsigned p = -1; P(p < IOV_MAX); }
  { unsigned p = -1; P(p > IOV_MAX); }
  { unsigned p = -1; P(p == IOV_MAX); }
  { unsigned p = -1; P(p <= IOV_MAX); }
  { unsigned p = -1; P(IOV_MAX + p); }
  { unsigned p = -1; P(p + IOV_MAX); }
  { unsigned p = -1; P(IOV_MAX - p); }
  { unsigned p = -1; P(p - IOV_MAX); }
  { unsigned p = -1; P(IOV_MAX * p); }
  { unsigned p = -1; P(p * IOV_MAX); }
  { unsigned p = -1; P(IOV_MAX & p); }
  { unsigned p = -1; P(IOV_MAX | p); }
  { unsigned p = -1; P(IOV_MAX ^ p); }
  { unsigned p = -1; P(p & IOV_MAX); }
  { unsigned p = -1; P(p | IOV_MAX); }
  { unsigned p = -1; P(1 ? IOV_MAX : p); }
  { unsigned p = -1; P(1 ? p : IOV_MAX); }
  { unsigned p = -1; P(0 ? IOV_MAX : p); }
  { unsigned p = -1; P(TC(IOV_MAX + p)); }
  { unsigned p = -1; P(TC(p + IOV_MAX)); }
  { unsigned p = -1; P(TC(1 ? IOV_MAX : p)); }
  { unsigned p = -1; P(sizeof(IOV_MAX + p)); }
  { unsigned p = -1; P(IOV_MAX / p); }
  { unsigned p = -1; P(IOV_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += IOV_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= IOV_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= IOV_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= IOV_MAX; P(t); }
  { long p = -1; P(IOV_MAX < p); }
  { long p = -1; P(IOV_MAX > p); }
  { long p = -1; P(IOV_MAX == p); }
  { long p = -1; P(IOV_MAX != p); }
  { long p = -1; P(IOV_MAX <= p); }
  { long p = -1; P(IOV_MAX >= p); }
  { long p = -1; P(p < IOV_MAX); }
  { long p = -1; P(p > IOV_MAX); }
  { long p = -1; P(p == IOV_MAX); }
  { long p = -1; P(p <= IOV_MAX); }
  { long p = -1; P(IOV_MAX + p); }
  { long p = -1; P(p + IOV_MAX); }
  { long p = -1; P(IOV_MAX - p); }
  { long p = -1; P(p - IOV_MAX); }
  { long p = -1; P(IOV_MAX * p); }
  { long p = -1; P(p * IOV_MAX); }
  { long p = -1; P(IOV_MAX & p); }
  { long p = -1; P(IOV_MAX | p); }
  { long p = -1; P(IOV_MAX ^ p); }
  { long p = -1; P(p & IOV_MAX); }
  { long p = -1; P(p | IOV_MAX); }
  { long p = -1; P(1 ? IOV_MAX : p); }
  { long p = -1; P(1 ? p : IOV_MAX); }
  { long p = -1; P(0 ? IOV_MAX : p); }
  { long p = -1; P(TC(IOV_MAX + p)); }
  { long p = -1; P(TC(p + IOV_MAX)); }
  { long p = -1; P(TC(1 ? IOV_MAX : p)); }
  { long p = -1; P(sizeof(IOV_MAX + p)); }
  { long p = -1; long t = p; t += IOV_MAX; P(t); }
  { long p = -1; long t = p; t -= IOV_MAX; P(t); }
  { long p = -1; long t = p; t &= IOV_MAX; P(t); }
  { long p = -1; long t = p; t |= IOV_MAX; P(t); }
  { unsigned long p = -1; P(IOV_MAX < p); }
  { unsigned long p = -1; P(IOV_MAX > p); }
  { unsigned long p = -1; P(IOV_MAX == p); }
  { unsigned long p = -1; P(IOV_MAX != p); }
  { unsigned long p = -1; P(IOV_MAX <= p); }
  { unsigned long p = -1; P(IOV_MAX >= p); }
  { unsigned long p = -1; P(p < IOV_MAX); }
  { unsigned long p = -1; P(p > IOV_MAX); }
  { unsigned long p = -1; P(p == IOV_MAX); }
  { unsigned long p = -1; P(p <= IOV_MAX); }
  { unsigned long p = -1; P(IOV_MAX + p); }
  { unsigned long p = -1; P(p + IOV_MAX); }
  { unsigned long p = -1; P(IOV_MAX - p); }
  { unsigned long p = -1; P(p - IOV_MAX); }
  { unsigned long p = -1; P(IOV_MAX * p); }
  { unsigned long p = -1; P(p * IOV_MAX); }
  { unsigned long p = -1; P(IOV_MAX & p); }
  { unsigned long p = -1; P(IOV_MAX | p); }
  { unsigned long p = -1; P(IOV_MAX ^ p); }
  { unsigned long p = -1; P(p & IOV_MAX); }
  { unsigned long p = -1; P(p | IOV_MAX); }
  { unsigned long p = -1; P(1 ? IOV_MAX : p); }
  { unsigned long p = -1; P(1 ? p : IOV_MAX); }
  { unsigned long p = -1; P(0 ? IOV_MAX : p); }
  { unsigned long p = -1; P(TC(IOV_MAX + p)); }
  { unsigned long p = -1; P(TC(p + IOV_MAX)); }
  { unsigned long p = -1; P(TC(1 ? IOV_MAX : p)); }
  { unsigned long p = -1; P(sizeof(IOV_MAX + p)); }
  { unsigned long p = -1; P(IOV_MAX / p); }
  { unsigned long p = -1; P(IOV_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += IOV_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= IOV_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= IOV_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= IOV_MAX; P(t); }
  P(NAME_MAX > 0);
  P(NAME_MAX < 0);
  P(NAME_MAX == 0);
  P(NAME_MAX != 0);
  P(NAME_MAX >= 0);
  P(NAME_MAX <= 0);
  P(0 < NAME_MAX);
  P(0 > NAME_MAX);
  P(0 == NAME_MAX);
  P(+NAME_MAX);
  P(-NAME_MAX);
  P(~NAME_MAX);
  P(!NAME_MAX);
  P((+NAME_MAX) > 0);
  P(sizeof(NAME_MAX));
  P(sizeof(+NAME_MAX));
  P(TC(NAME_MAX));
  P(TC(+NAME_MAX));
  P(TC(-NAME_MAX));
  P(TC(~NAME_MAX));
  P((_Bool)NAME_MAX);
  P((signed char)NAME_MAX);
  P((unsigned char)NAME_MAX);
  P((short)NAME_MAX);
  P((unsigned short)NAME_MAX);
  P((int)NAME_MAX);
  P((unsigned)NAME_MAX);
  P((long)NAME_MAX);
  P((unsigned long)NAME_MAX);
  P((long long)NAME_MAX);
  P((unsigned long long)NAME_MAX);
  P((long long)NAME_MAX > 0);
  P((long long)NAME_MAX < 0);
  { int x = NAME_MAX; P(x); }
  { unsigned x = NAME_MAX; P(x); }
  { long x = NAME_MAX; P(x); }
  { unsigned long x = NAME_MAX; P(x); }
  P(NAME_MAX + 1);
  P(NAME_MAX - 1);
  P(NAME_MAX - 1 > 0);
  P(NAME_MAX + 1 > 0);
  P(NAME_MAX + 1u);
  P(NAME_MAX - 1u);
  P(NAME_MAX + 1l);
  P(NAME_MAX - 1ul);
  { int p = -1; P(NAME_MAX < p); }
  { int p = -1; P(NAME_MAX > p); }
  { int p = -1; P(NAME_MAX == p); }
  { int p = -1; P(NAME_MAX != p); }
  { int p = -1; P(NAME_MAX <= p); }
  { int p = -1; P(NAME_MAX >= p); }
  { int p = -1; P(p < NAME_MAX); }
  { int p = -1; P(p > NAME_MAX); }
  { int p = -1; P(p == NAME_MAX); }
  { int p = -1; P(p <= NAME_MAX); }
  { int p = -1; P(NAME_MAX + p); }
  { int p = -1; P(p + NAME_MAX); }
  { int p = -1; P(NAME_MAX - p); }
  { int p = -1; P(p - NAME_MAX); }
  { int p = -1; P(NAME_MAX * p); }
  { int p = -1; P(p * NAME_MAX); }
  { int p = -1; P(NAME_MAX & p); }
  { int p = -1; P(NAME_MAX | p); }
  { int p = -1; P(NAME_MAX ^ p); }
  { int p = -1; P(p & NAME_MAX); }
  { int p = -1; P(p | NAME_MAX); }
  { int p = -1; P(1 ? NAME_MAX : p); }
  { int p = -1; P(1 ? p : NAME_MAX); }
  { int p = -1; P(0 ? NAME_MAX : p); }
  { int p = -1; P(TC(NAME_MAX + p)); }
  { int p = -1; P(TC(p + NAME_MAX)); }
  { int p = -1; P(TC(1 ? NAME_MAX : p)); }
  { int p = -1; P(sizeof(NAME_MAX + p)); }
  { int p = -1; int t = p; t += NAME_MAX; P(t); }
  { int p = -1; int t = p; t -= NAME_MAX; P(t); }
  { int p = -1; int t = p; t &= NAME_MAX; P(t); }
  { int p = -1; int t = p; t |= NAME_MAX; P(t); }
  { unsigned p = -1; P(NAME_MAX < p); }
  { unsigned p = -1; P(NAME_MAX > p); }
  { unsigned p = -1; P(NAME_MAX == p); }
  { unsigned p = -1; P(NAME_MAX != p); }
  { unsigned p = -1; P(NAME_MAX <= p); }
  { unsigned p = -1; P(NAME_MAX >= p); }
  { unsigned p = -1; P(p < NAME_MAX); }
  { unsigned p = -1; P(p > NAME_MAX); }
  { unsigned p = -1; P(p == NAME_MAX); }
  { unsigned p = -1; P(p <= NAME_MAX); }
  { unsigned p = -1; P(NAME_MAX + p); }
  { unsigned p = -1; P(p + NAME_MAX); }
  { unsigned p = -1; P(NAME_MAX - p); }
  { unsigned p = -1; P(p - NAME_MAX); }
  { unsigned p = -1; P(NAME_MAX * p); }
  { unsigned p = -1; P(p * NAME_MAX); }
  { unsigned p = -1; P(NAME_MAX & p); }
  { unsigned p = -1; P(NAME_MAX | p); }
  { unsigned p = -1; P(NAME_MAX ^ p); }
  { unsigned p = -1; P(p & NAME_MAX); }
  { unsigned p = -1; P(p | NAME_MAX); }
  { unsigned p = -1; P(1 ? NAME_MAX : p); }
  { unsigned p = -1; P(1 ? p : NAME_MAX); }
  { unsigned p = -1; P(0 ? NAME_MAX : p); }
  { unsigned p = -1; P(TC(NAME_MAX + p)); }
  { unsigned p = -1; P(TC(p + NAME_MAX)); }
  { unsigned p = -1; P(TC(1 ? NAME_MAX : p)); }
  { unsigned p = -1; P(sizeof(NAME_MAX + p)); }
  { unsigned p = -1; P(NAME_MAX / p); }
  { unsigned p = -1; P(NAME_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += NAME_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= NAME_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= NAME_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= NAME_MAX; P(t); }
  { long p = -1; P(NAME_MAX < p); }
  { long p = -1; P(NAME_MAX > p); }
  { long p = -1; P(NAME_MAX == p); }
  { long p = -1; P(NAME_MAX != p); }
  { long p = -1; P(NAME_MAX <= p); }
  { long p = -1; P(NAME_MAX >= p); }
  { long p = -1; P(p < NAME_MAX); }
  { long p = -1; P(p > NAME_MAX); }
  { long p = -1; P(p == NAME_MAX); }
  { long p = -1; P(p <= NAME_MAX); }
  { long p = -1; P(NAME_MAX + p); }
  { long p = -1; P(p + NAME_MAX); }
  { long p = -1; P(NAME_MAX - p); }
  { long p = -1; P(p - NAME_MAX); }
  { long p = -1; P(NAME_MAX * p); }
  { long p = -1; P(p * NAME_MAX); }
  { long p = -1; P(NAME_MAX & p); }
  { long p = -1; P(NAME_MAX | p); }
  { long p = -1; P(NAME_MAX ^ p); }
  { long p = -1; P(p & NAME_MAX); }
  { long p = -1; P(p | NAME_MAX); }
  { long p = -1; P(1 ? NAME_MAX : p); }
  { long p = -1; P(1 ? p : NAME_MAX); }
  { long p = -1; P(0 ? NAME_MAX : p); }
  { long p = -1; P(TC(NAME_MAX + p)); }
  { long p = -1; P(TC(p + NAME_MAX)); }
  { long p = -1; P(TC(1 ? NAME_MAX : p)); }
  { long p = -1; P(sizeof(NAME_MAX + p)); }
  { long p = -1; long t = p; t += NAME_MAX; P(t); }
  { long p = -1; long t = p; t -= NAME_MAX; P(t); }
  { long p = -1; long t = p; t &= NAME_MAX; P(t); }
  { long p = -1; long t = p; t |= NAME_MAX; P(t); }
  { unsigned long p = -1; P(NAME_MAX < p); }
  { unsigned long p = -1; P(NAME_MAX > p); }
  { unsigned long p = -1; P(NAME_MAX == p); }
  { unsigned long p = -1; P(NAME_MAX != p); }
  { unsigned long p = -1; P(NAME_MAX <= p); }
  { unsigned long p = -1; P(NAME_MAX >= p); }
  { unsigned long p = -1; P(p < NAME_MAX); }
  { unsigned long p = -1; P(p > NAME_MAX); }
  { unsigned long p = -1; P(p == NAME_MAX); }
  { unsigned long p = -1; P(p <= NAME_MAX); }
  { unsigned long p = -1; P(NAME_MAX + p); }
  { unsigned long p = -1; P(p + NAME_MAX); }
  { unsigned long p = -1; P(NAME_MAX - p); }
  { unsigned long p = -1; P(p - NAME_MAX); }
  { unsigned long p = -1; P(NAME_MAX * p); }
  { unsigned long p = -1; P(p * NAME_MAX); }
  { unsigned long p = -1; P(NAME_MAX & p); }
  { unsigned long p = -1; P(NAME_MAX | p); }
  { unsigned long p = -1; P(NAME_MAX ^ p); }
  { unsigned long p = -1; P(p & NAME_MAX); }
  { unsigned long p = -1; P(p | NAME_MAX); }
  { unsigned long p = -1; P(1 ? NAME_MAX : p); }
  { unsigned long p = -1; P(1 ? p : NAME_MAX); }
  { unsigned long p = -1; P(0 ? NAME_MAX : p); }
  { unsigned long p = -1; P(TC(NAME_MAX + p)); }
  { unsigned long p = -1; P(TC(p + NAME_MAX)); }
  { unsigned long p = -1; P(TC(1 ? NAME_MAX : p)); }
  { unsigned long p = -1; P(sizeof(NAME_MAX + p)); }
  { unsigned long p = -1; P(NAME_MAX / p); }
  { unsigned long p = -1; P(NAME_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += NAME_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= NAME_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= NAME_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= NAME_MAX; P(t); }
  printf("\n");
  return 0;
}
