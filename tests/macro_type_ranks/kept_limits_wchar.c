// KEPT (upstream's behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f's line; gcc 13's line beside in kept.txt): WCHAR_MIN and WCHAR_MAX compared with 0, promoted, converted, and against int, unsigned, long, unsigned long (0, 1, -1)
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(WCHAR_MAX > 0);
  P(WCHAR_MAX < 0);
  P(WCHAR_MAX == 0);
  P(WCHAR_MAX != 0);
  P(WCHAR_MAX >= 0);
  P(WCHAR_MAX <= 0);
  P(0 < WCHAR_MAX);
  P(0 > WCHAR_MAX);
  P(0 == WCHAR_MAX);
  P(+WCHAR_MAX);
  P(~WCHAR_MAX);
  P(!WCHAR_MAX);
  P((+WCHAR_MAX) > 0);
  P(sizeof(WCHAR_MAX));
  P(sizeof(+WCHAR_MAX));
  P(TC(WCHAR_MAX));
  P(TC(+WCHAR_MAX));
  P(TC(-WCHAR_MAX));
  P(TC(~WCHAR_MAX));
  P((_Bool)WCHAR_MAX);
  P((signed char)WCHAR_MAX);
  P((unsigned char)WCHAR_MAX);
  P((short)WCHAR_MAX);
  P((unsigned short)WCHAR_MAX);
  P((int)WCHAR_MAX);
  P((unsigned)WCHAR_MAX);
  P((long)WCHAR_MAX);
  P((unsigned long)WCHAR_MAX);
  P((long long)WCHAR_MAX);
  P((unsigned long long)WCHAR_MAX);
  P((long long)WCHAR_MAX > 0);
  P((long long)WCHAR_MAX < 0);
  { int x = WCHAR_MAX; P(x); }
  { unsigned x = WCHAR_MAX; P(x); }
  { long x = WCHAR_MAX; P(x); }
  { unsigned long x = WCHAR_MAX; P(x); }
  P(WCHAR_MAX - 1);
  P(WCHAR_MAX - 1 > 0);
  P(WCHAR_MAX - 1u);
  P(WCHAR_MAX - 1ul);
  { int p = 0; P(WCHAR_MAX < p); }
  { int p = 0; P(WCHAR_MAX > p); }
  { int p = 0; P(WCHAR_MAX == p); }
  { int p = 0; P(WCHAR_MAX != p); }
  { int p = 0; P(WCHAR_MAX <= p); }
  { int p = 0; P(WCHAR_MAX >= p); }
  { int p = 0; P(p < WCHAR_MAX); }
  { int p = 0; P(p > WCHAR_MAX); }
  { int p = 0; P(p == WCHAR_MAX); }
  { int p = 0; P(p <= WCHAR_MAX); }
  { int p = 0; P(WCHAR_MAX + p); }
  { int p = 0; P(p + WCHAR_MAX); }
  { int p = 0; P(WCHAR_MAX - p); }
  { int p = 0; P(p - WCHAR_MAX); }
  { int p = 0; P(WCHAR_MAX * p); }
  { int p = 0; P(p * WCHAR_MAX); }
  { int p = 0; P(WCHAR_MAX & p); }
  { int p = 0; P(WCHAR_MAX | p); }
  { int p = 0; P(WCHAR_MAX ^ p); }
  { int p = 0; P(p & WCHAR_MAX); }
  { int p = 0; P(p | WCHAR_MAX); }
  { int p = 0; P(1 ? WCHAR_MAX : p); }
  { int p = 0; P(1 ? p : WCHAR_MAX); }
  { int p = 0; P(0 ? WCHAR_MAX : p); }
  { int p = 0; P(TC(WCHAR_MAX + p)); }
  { int p = 0; P(TC(p + WCHAR_MAX)); }
  { int p = 0; P(TC(1 ? WCHAR_MAX : p)); }
  { int p = 0; P(sizeof(WCHAR_MAX + p)); }
  { int p = 0; int t = p; t += WCHAR_MAX; P(t); }
  { int p = 0; int t = p; t -= WCHAR_MAX; P(t); }
  { int p = 0; int t = p; t &= WCHAR_MAX; P(t); }
  { int p = 0; int t = p; t |= WCHAR_MAX; P(t); }
  { int p = 1; P(WCHAR_MAX < p); }
  { int p = 1; P(WCHAR_MAX > p); }
  { int p = 1; P(WCHAR_MAX == p); }
  { int p = 1; P(WCHAR_MAX != p); }
  { int p = 1; P(WCHAR_MAX <= p); }
  { int p = 1; P(WCHAR_MAX >= p); }
  { int p = 1; P(p < WCHAR_MAX); }
  { int p = 1; P(p > WCHAR_MAX); }
  { int p = 1; P(p == WCHAR_MAX); }
  { int p = 1; P(p <= WCHAR_MAX); }
  { int p = 1; P(WCHAR_MAX - p); }
  { int p = 1; P(p - WCHAR_MAX); }
  { int p = 1; P(WCHAR_MAX * p); }
  { int p = 1; P(p * WCHAR_MAX); }
  { int p = 1; P(WCHAR_MAX & p); }
  { int p = 1; P(WCHAR_MAX | p); }
  { int p = 1; P(WCHAR_MAX ^ p); }
  { int p = 1; P(p & WCHAR_MAX); }
  { int p = 1; P(p | WCHAR_MAX); }
  { int p = 1; P(1 ? WCHAR_MAX : p); }
  { int p = 1; P(1 ? p : WCHAR_MAX); }
  { int p = 1; P(0 ? WCHAR_MAX : p); }
  { int p = 1; P(TC(WCHAR_MAX + p)); }
  { int p = 1; P(TC(p + WCHAR_MAX)); }
  { int p = 1; P(TC(1 ? WCHAR_MAX : p)); }
  { int p = 1; P(sizeof(WCHAR_MAX + p)); }
  { int p = 1; P(WCHAR_MAX / p); }
  { int p = 1; P(WCHAR_MAX % p); }
  { int p = 1; int t = p; t -= WCHAR_MAX; P(t); }
  { int p = 1; int t = p; t &= WCHAR_MAX; P(t); }
  { int p = 1; int t = p; t |= WCHAR_MAX; P(t); }
  { int p = -1; P(WCHAR_MAX < p); }
  { int p = -1; P(WCHAR_MAX > p); }
  { int p = -1; P(WCHAR_MAX == p); }
  { int p = -1; P(WCHAR_MAX != p); }
  { int p = -1; P(WCHAR_MAX <= p); }
  { int p = -1; P(WCHAR_MAX >= p); }
  { int p = -1; P(p < WCHAR_MAX); }
  { int p = -1; P(p > WCHAR_MAX); }
  { int p = -1; P(p == WCHAR_MAX); }
  { int p = -1; P(p <= WCHAR_MAX); }
  { int p = -1; P(p + WCHAR_MAX); }
  { int p = -1; P(p - WCHAR_MAX); }
  { int p = -1; P(p * WCHAR_MAX); }
  { int p = -1; P(WCHAR_MAX & p); }
  { int p = -1; P(WCHAR_MAX | p); }
  { int p = -1; P(WCHAR_MAX ^ p); }
  { int p = -1; P(p & WCHAR_MAX); }
  { int p = -1; P(p | WCHAR_MAX); }
  { int p = -1; P(1 ? WCHAR_MAX : p); }
  { int p = -1; P(1 ? p : WCHAR_MAX); }
  { int p = -1; P(0 ? WCHAR_MAX : p); }
  { int p = -1; P(TC(WCHAR_MAX + p)); }
  { int p = -1; P(TC(p + WCHAR_MAX)); }
  { int p = -1; P(TC(1 ? WCHAR_MAX : p)); }
  { int p = -1; P(sizeof(WCHAR_MAX + p)); }
  { int p = -1; int t = p; t += WCHAR_MAX; P(t); }
  { int p = -1; int t = p; t -= WCHAR_MAX; P(t); }
  { int p = -1; int t = p; t &= WCHAR_MAX; P(t); }
  { int p = -1; int t = p; t |= WCHAR_MAX; P(t); }
  { unsigned p = 0; P(WCHAR_MAX < p); }
  { unsigned p = 0; P(WCHAR_MAX > p); }
  { unsigned p = 0; P(WCHAR_MAX == p); }
  { unsigned p = 0; P(WCHAR_MAX != p); }
  { unsigned p = 0; P(WCHAR_MAX <= p); }
  { unsigned p = 0; P(WCHAR_MAX >= p); }
  { unsigned p = 0; P(p < WCHAR_MAX); }
  { unsigned p = 0; P(p > WCHAR_MAX); }
  { unsigned p = 0; P(p == WCHAR_MAX); }
  { unsigned p = 0; P(p <= WCHAR_MAX); }
  { unsigned p = 0; P(WCHAR_MAX + p); }
  { unsigned p = 0; P(p + WCHAR_MAX); }
  { unsigned p = 0; P(WCHAR_MAX - p); }
  { unsigned p = 0; P(WCHAR_MAX * p); }
  { unsigned p = 0; P(p * WCHAR_MAX); }
  { unsigned p = 0; P(WCHAR_MAX & p); }
  { unsigned p = 0; P(WCHAR_MAX | p); }
  { unsigned p = 0; P(WCHAR_MAX ^ p); }
  { unsigned p = 0; P(p & WCHAR_MAX); }
  { unsigned p = 0; P(p | WCHAR_MAX); }
  { unsigned p = 0; P(1 ? WCHAR_MAX : p); }
  { unsigned p = 0; P(1 ? p : WCHAR_MAX); }
  { unsigned p = 0; P(0 ? WCHAR_MAX : p); }
  { unsigned p = 0; P(TC(WCHAR_MAX + p)); }
  { unsigned p = 0; P(TC(p + WCHAR_MAX)); }
  { unsigned p = 0; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned p = 0; P(sizeof(WCHAR_MAX + p)); }
  { unsigned p = 0; unsigned t = p; t += WCHAR_MAX; P(t); }
  { unsigned p = 0; unsigned t = p; t &= WCHAR_MAX; P(t); }
  { unsigned p = 0; unsigned t = p; t |= WCHAR_MAX; P(t); }
  { unsigned p = 1; P(WCHAR_MAX < p); }
  { unsigned p = 1; P(WCHAR_MAX > p); }
  { unsigned p = 1; P(WCHAR_MAX == p); }
  { unsigned p = 1; P(WCHAR_MAX != p); }
  { unsigned p = 1; P(WCHAR_MAX <= p); }
  { unsigned p = 1; P(WCHAR_MAX >= p); }
  { unsigned p = 1; P(p < WCHAR_MAX); }
  { unsigned p = 1; P(p > WCHAR_MAX); }
  { unsigned p = 1; P(p == WCHAR_MAX); }
  { unsigned p = 1; P(p <= WCHAR_MAX); }
  { unsigned p = 1; P(WCHAR_MAX - p); }
  { unsigned p = 1; P(WCHAR_MAX * p); }
  { unsigned p = 1; P(p * WCHAR_MAX); }
  { unsigned p = 1; P(WCHAR_MAX & p); }
  { unsigned p = 1; P(WCHAR_MAX | p); }
  { unsigned p = 1; P(WCHAR_MAX ^ p); }
  { unsigned p = 1; P(p & WCHAR_MAX); }
  { unsigned p = 1; P(p | WCHAR_MAX); }
  { unsigned p = 1; P(1 ? WCHAR_MAX : p); }
  { unsigned p = 1; P(1 ? p : WCHAR_MAX); }
  { unsigned p = 1; P(0 ? WCHAR_MAX : p); }
  { unsigned p = 1; P(TC(WCHAR_MAX + p)); }
  { unsigned p = 1; P(TC(p + WCHAR_MAX)); }
  { unsigned p = 1; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned p = 1; P(sizeof(WCHAR_MAX + p)); }
  { unsigned p = 1; P(WCHAR_MAX / p); }
  { unsigned p = 1; P(WCHAR_MAX % p); }
  { unsigned p = 1; unsigned t = p; t &= WCHAR_MAX; P(t); }
  { unsigned p = 1; unsigned t = p; t |= WCHAR_MAX; P(t); }
  { unsigned p = -1; P(WCHAR_MAX < p); }
  { unsigned p = -1; P(WCHAR_MAX > p); }
  { unsigned p = -1; P(WCHAR_MAX == p); }
  { unsigned p = -1; P(WCHAR_MAX != p); }
  { unsigned p = -1; P(WCHAR_MAX <= p); }
  { unsigned p = -1; P(WCHAR_MAX >= p); }
  { unsigned p = -1; P(p < WCHAR_MAX); }
  { unsigned p = -1; P(p > WCHAR_MAX); }
  { unsigned p = -1; P(p == WCHAR_MAX); }
  { unsigned p = -1; P(p <= WCHAR_MAX); }
  { unsigned p = -1; P(WCHAR_MAX - p); }
  { unsigned p = -1; P(p - WCHAR_MAX); }
  { unsigned p = -1; P(WCHAR_MAX & p); }
  { unsigned p = -1; P(WCHAR_MAX | p); }
  { unsigned p = -1; P(WCHAR_MAX ^ p); }
  { unsigned p = -1; P(p & WCHAR_MAX); }
  { unsigned p = -1; P(p | WCHAR_MAX); }
  { unsigned p = -1; P(1 ? WCHAR_MAX : p); }
  { unsigned p = -1; P(1 ? p : WCHAR_MAX); }
  { unsigned p = -1; P(0 ? WCHAR_MAX : p); }
  { unsigned p = -1; P(TC(WCHAR_MAX + p)); }
  { unsigned p = -1; P(TC(p + WCHAR_MAX)); }
  { unsigned p = -1; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned p = -1; P(sizeof(WCHAR_MAX + p)); }
  { unsigned p = -1; P(WCHAR_MAX / p); }
  { unsigned p = -1; P(WCHAR_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= WCHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= WCHAR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= WCHAR_MAX; P(t); }
  { long p = 0; P(WCHAR_MAX < p); }
  { long p = 0; P(WCHAR_MAX > p); }
  { long p = 0; P(WCHAR_MAX == p); }
  { long p = 0; P(WCHAR_MAX != p); }
  { long p = 0; P(WCHAR_MAX <= p); }
  { long p = 0; P(WCHAR_MAX >= p); }
  { long p = 0; P(p < WCHAR_MAX); }
  { long p = 0; P(p > WCHAR_MAX); }
  { long p = 0; P(p == WCHAR_MAX); }
  { long p = 0; P(p <= WCHAR_MAX); }
  { long p = 0; P(WCHAR_MAX + p); }
  { long p = 0; P(p + WCHAR_MAX); }
  { long p = 0; P(WCHAR_MAX - p); }
  { long p = 0; P(p - WCHAR_MAX); }
  { long p = 0; P(WCHAR_MAX * p); }
  { long p = 0; P(p * WCHAR_MAX); }
  { long p = 0; P(WCHAR_MAX & p); }
  { long p = 0; P(WCHAR_MAX | p); }
  { long p = 0; P(WCHAR_MAX ^ p); }
  { long p = 0; P(p & WCHAR_MAX); }
  { long p = 0; P(p | WCHAR_MAX); }
  { long p = 0; P(1 ? WCHAR_MAX : p); }
  { long p = 0; P(1 ? p : WCHAR_MAX); }
  { long p = 0; P(0 ? WCHAR_MAX : p); }
  { long p = 0; P(TC(WCHAR_MAX + p)); }
  { long p = 0; P(TC(p + WCHAR_MAX)); }
  { long p = 0; P(TC(1 ? WCHAR_MAX : p)); }
  { long p = 0; P(sizeof(WCHAR_MAX + p)); }
  { long p = 0; long t = p; t += WCHAR_MAX; P(t); }
  { long p = 0; long t = p; t -= WCHAR_MAX; P(t); }
  { long p = 0; long t = p; t &= WCHAR_MAX; P(t); }
  { long p = 0; long t = p; t |= WCHAR_MAX; P(t); }
  { long p = 1; P(WCHAR_MAX < p); }
  { long p = 1; P(WCHAR_MAX > p); }
  { long p = 1; P(WCHAR_MAX == p); }
  { long p = 1; P(WCHAR_MAX != p); }
  { long p = 1; P(WCHAR_MAX <= p); }
  { long p = 1; P(WCHAR_MAX >= p); }
  { long p = 1; P(p < WCHAR_MAX); }
  { long p = 1; P(p > WCHAR_MAX); }
  { long p = 1; P(p == WCHAR_MAX); }
  { long p = 1; P(p <= WCHAR_MAX); }
  { long p = 1; P(p + WCHAR_MAX); }
  { long p = 1; P(WCHAR_MAX - p); }
  { long p = 1; P(p - WCHAR_MAX); }
  { long p = 1; P(WCHAR_MAX * p); }
  { long p = 1; P(p * WCHAR_MAX); }
  { long p = 1; P(WCHAR_MAX & p); }
  { long p = 1; P(WCHAR_MAX | p); }
  { long p = 1; P(WCHAR_MAX ^ p); }
  { long p = 1; P(p & WCHAR_MAX); }
  { long p = 1; P(p | WCHAR_MAX); }
  { long p = 1; P(1 ? WCHAR_MAX : p); }
  { long p = 1; P(1 ? p : WCHAR_MAX); }
  { long p = 1; P(0 ? WCHAR_MAX : p); }
  { long p = 1; P(TC(WCHAR_MAX + p)); }
  { long p = 1; P(TC(p + WCHAR_MAX)); }
  { long p = 1; P(TC(1 ? WCHAR_MAX : p)); }
  { long p = 1; P(sizeof(WCHAR_MAX + p)); }
  { long p = 1; P(WCHAR_MAX / p); }
  { long p = 1; P(WCHAR_MAX % p); }
  { long p = 1; long t = p; t += WCHAR_MAX; P(t); }
  { long p = 1; long t = p; t -= WCHAR_MAX; P(t); }
  { long p = 1; long t = p; t &= WCHAR_MAX; P(t); }
  { long p = 1; long t = p; t |= WCHAR_MAX; P(t); }
  { long p = -1; P(WCHAR_MAX < p); }
  { long p = -1; P(WCHAR_MAX > p); }
  { long p = -1; P(WCHAR_MAX == p); }
  { long p = -1; P(WCHAR_MAX != p); }
  { long p = -1; P(WCHAR_MAX <= p); }
  { long p = -1; P(WCHAR_MAX >= p); }
  { long p = -1; P(p < WCHAR_MAX); }
  { long p = -1; P(p > WCHAR_MAX); }
  { long p = -1; P(p == WCHAR_MAX); }
  { long p = -1; P(p <= WCHAR_MAX); }
  { long p = -1; P(p + WCHAR_MAX); }
  { long p = -1; P(WCHAR_MAX - p); }
  { long p = -1; P(p - WCHAR_MAX); }
  { long p = -1; P(p * WCHAR_MAX); }
  { long p = -1; P(WCHAR_MAX & p); }
  { long p = -1; P(WCHAR_MAX | p); }
  { long p = -1; P(WCHAR_MAX ^ p); }
  { long p = -1; P(p & WCHAR_MAX); }
  { long p = -1; P(p | WCHAR_MAX); }
  { long p = -1; P(1 ? WCHAR_MAX : p); }
  { long p = -1; P(1 ? p : WCHAR_MAX); }
  { long p = -1; P(0 ? WCHAR_MAX : p); }
  { long p = -1; P(TC(WCHAR_MAX + p)); }
  { long p = -1; P(TC(p + WCHAR_MAX)); }
  { long p = -1; P(TC(1 ? WCHAR_MAX : p)); }
  { long p = -1; P(sizeof(WCHAR_MAX + p)); }
  { long p = -1; long t = p; t += WCHAR_MAX; P(t); }
  { long p = -1; long t = p; t -= WCHAR_MAX; P(t); }
  { long p = -1; long t = p; t &= WCHAR_MAX; P(t); }
  { long p = -1; long t = p; t |= WCHAR_MAX; P(t); }
  { unsigned long p = 0; P(WCHAR_MAX < p); }
  { unsigned long p = 0; P(WCHAR_MAX > p); }
  { unsigned long p = 0; P(WCHAR_MAX == p); }
  { unsigned long p = 0; P(WCHAR_MAX != p); }
  { unsigned long p = 0; P(WCHAR_MAX <= p); }
  { unsigned long p = 0; P(WCHAR_MAX >= p); }
  { unsigned long p = 0; P(p < WCHAR_MAX); }
  { unsigned long p = 0; P(p > WCHAR_MAX); }
  { unsigned long p = 0; P(p == WCHAR_MAX); }
  { unsigned long p = 0; P(p <= WCHAR_MAX); }
  { unsigned long p = 0; P(WCHAR_MAX + p); }
  { unsigned long p = 0; P(p + WCHAR_MAX); }
  { unsigned long p = 0; P(WCHAR_MAX - p); }
  { unsigned long p = 0; P(WCHAR_MAX * p); }
  { unsigned long p = 0; P(p * WCHAR_MAX); }
  { unsigned long p = 0; P(WCHAR_MAX & p); }
  { unsigned long p = 0; P(WCHAR_MAX | p); }
  { unsigned long p = 0; P(WCHAR_MAX ^ p); }
  { unsigned long p = 0; P(p & WCHAR_MAX); }
  { unsigned long p = 0; P(p | WCHAR_MAX); }
  { unsigned long p = 0; P(1 ? WCHAR_MAX : p); }
  { unsigned long p = 0; P(1 ? p : WCHAR_MAX); }
  { unsigned long p = 0; P(0 ? WCHAR_MAX : p); }
  { unsigned long p = 0; P(TC(WCHAR_MAX + p)); }
  { unsigned long p = 0; P(TC(p + WCHAR_MAX)); }
  { unsigned long p = 0; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned long p = 0; P(sizeof(WCHAR_MAX + p)); }
  { unsigned long p = 0; unsigned long t = p; t += WCHAR_MAX; P(t); }
  { unsigned long p = 0; unsigned long t = p; t &= WCHAR_MAX; P(t); }
  { unsigned long p = 0; unsigned long t = p; t |= WCHAR_MAX; P(t); }
  { unsigned long p = 1; P(WCHAR_MAX < p); }
  { unsigned long p = 1; P(WCHAR_MAX > p); }
  { unsigned long p = 1; P(WCHAR_MAX == p); }
  { unsigned long p = 1; P(WCHAR_MAX != p); }
  { unsigned long p = 1; P(WCHAR_MAX <= p); }
  { unsigned long p = 1; P(WCHAR_MAX >= p); }
  { unsigned long p = 1; P(p < WCHAR_MAX); }
  { unsigned long p = 1; P(p > WCHAR_MAX); }
  { unsigned long p = 1; P(p == WCHAR_MAX); }
  { unsigned long p = 1; P(p <= WCHAR_MAX); }
  { unsigned long p = 1; P(WCHAR_MAX - p); }
  { unsigned long p = 1; P(WCHAR_MAX * p); }
  { unsigned long p = 1; P(p * WCHAR_MAX); }
  { unsigned long p = 1; P(WCHAR_MAX & p); }
  { unsigned long p = 1; P(WCHAR_MAX | p); }
  { unsigned long p = 1; P(WCHAR_MAX ^ p); }
  { unsigned long p = 1; P(p & WCHAR_MAX); }
  { unsigned long p = 1; P(p | WCHAR_MAX); }
  { unsigned long p = 1; P(1 ? WCHAR_MAX : p); }
  { unsigned long p = 1; P(1 ? p : WCHAR_MAX); }
  { unsigned long p = 1; P(0 ? WCHAR_MAX : p); }
  { unsigned long p = 1; P(TC(WCHAR_MAX + p)); }
  { unsigned long p = 1; P(TC(p + WCHAR_MAX)); }
  { unsigned long p = 1; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned long p = 1; P(sizeof(WCHAR_MAX + p)); }
  { unsigned long p = 1; P(WCHAR_MAX / p); }
  { unsigned long p = 1; P(WCHAR_MAX % p); }
  { unsigned long p = 1; unsigned long t = p; t &= WCHAR_MAX; P(t); }
  { unsigned long p = 1; unsigned long t = p; t |= WCHAR_MAX; P(t); }
  { unsigned long p = -1; P(WCHAR_MAX < p); }
  { unsigned long p = -1; P(WCHAR_MAX > p); }
  { unsigned long p = -1; P(WCHAR_MAX == p); }
  { unsigned long p = -1; P(WCHAR_MAX != p); }
  { unsigned long p = -1; P(WCHAR_MAX <= p); }
  { unsigned long p = -1; P(WCHAR_MAX >= p); }
  { unsigned long p = -1; P(p < WCHAR_MAX); }
  { unsigned long p = -1; P(p > WCHAR_MAX); }
  { unsigned long p = -1; P(p == WCHAR_MAX); }
  { unsigned long p = -1; P(p <= WCHAR_MAX); }
  { unsigned long p = -1; P(WCHAR_MAX - p); }
  { unsigned long p = -1; P(p - WCHAR_MAX); }
  { unsigned long p = -1; P(WCHAR_MAX & p); }
  { unsigned long p = -1; P(WCHAR_MAX | p); }
  { unsigned long p = -1; P(WCHAR_MAX ^ p); }
  { unsigned long p = -1; P(p & WCHAR_MAX); }
  { unsigned long p = -1; P(p | WCHAR_MAX); }
  { unsigned long p = -1; P(1 ? WCHAR_MAX : p); }
  { unsigned long p = -1; P(1 ? p : WCHAR_MAX); }
  { unsigned long p = -1; P(0 ? WCHAR_MAX : p); }
  { unsigned long p = -1; P(TC(WCHAR_MAX + p)); }
  { unsigned long p = -1; P(TC(p + WCHAR_MAX)); }
  { unsigned long p = -1; P(TC(1 ? WCHAR_MAX : p)); }
  { unsigned long p = -1; P(sizeof(WCHAR_MAX + p)); }
  { unsigned long p = -1; P(WCHAR_MAX / p); }
  { unsigned long p = -1; P(WCHAR_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t -= WCHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= WCHAR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= WCHAR_MAX; P(t); }
  P(WCHAR_MIN > 0);
  P(WCHAR_MIN < 0);
  P(WCHAR_MIN == 0);
  P(WCHAR_MIN != 0);
  P(WCHAR_MIN >= 0);
  P(WCHAR_MIN <= 0);
  P(0 < WCHAR_MIN);
  P(0 > WCHAR_MIN);
  P(0 == WCHAR_MIN);
  P(+WCHAR_MIN);
  P(~WCHAR_MIN);
  P(!WCHAR_MIN);
  P((+WCHAR_MIN) > 0);
  P(sizeof(WCHAR_MIN));
  P(sizeof(+WCHAR_MIN));
  P(TC(WCHAR_MIN));
  P(TC(+WCHAR_MIN));
  P(TC(-WCHAR_MIN));
  P(TC(~WCHAR_MIN));
  P((_Bool)WCHAR_MIN);
  P((signed char)WCHAR_MIN);
  P((unsigned char)WCHAR_MIN);
  P((short)WCHAR_MIN);
  P((unsigned short)WCHAR_MIN);
  P((int)WCHAR_MIN);
  P((unsigned)WCHAR_MIN);
  P((long)WCHAR_MIN);
  P((unsigned long)WCHAR_MIN);
  P((long long)WCHAR_MIN);
  P((unsigned long long)WCHAR_MIN);
  P((long long)WCHAR_MIN > 0);
  P((long long)WCHAR_MIN < 0);
  { int x = WCHAR_MIN; P(x); }
  { unsigned x = WCHAR_MIN; P(x); }
  { long x = WCHAR_MIN; P(x); }
  { unsigned long x = WCHAR_MIN; P(x); }
  P(WCHAR_MIN + 1);
  P(WCHAR_MIN + 1 > 0);
  P(WCHAR_MIN + 1u);
  P(WCHAR_MIN + 1l);
  { int p = 0; P(WCHAR_MIN < p); }
  { int p = 0; P(WCHAR_MIN > p); }
  { int p = 0; P(WCHAR_MIN == p); }
  { int p = 0; P(WCHAR_MIN != p); }
  { int p = 0; P(WCHAR_MIN <= p); }
  { int p = 0; P(WCHAR_MIN >= p); }
  { int p = 0; P(p < WCHAR_MIN); }
  { int p = 0; P(p > WCHAR_MIN); }
  { int p = 0; P(p == WCHAR_MIN); }
  { int p = 0; P(p <= WCHAR_MIN); }
  { int p = 0; P(WCHAR_MIN + p); }
  { int p = 0; P(p + WCHAR_MIN); }
  { int p = 0; P(WCHAR_MIN - p); }
  { int p = 0; P(WCHAR_MIN * p); }
  { int p = 0; P(p * WCHAR_MIN); }
  { int p = 0; P(WCHAR_MIN & p); }
  { int p = 0; P(WCHAR_MIN | p); }
  { int p = 0; P(WCHAR_MIN ^ p); }
  { int p = 0; P(p & WCHAR_MIN); }
  { int p = 0; P(p | WCHAR_MIN); }
  { int p = 0; P(1 ? WCHAR_MIN : p); }
  { int p = 0; P(1 ? p : WCHAR_MIN); }
  { int p = 0; P(0 ? WCHAR_MIN : p); }
  { int p = 0; P(TC(WCHAR_MIN + p)); }
  { int p = 0; P(TC(p + WCHAR_MIN)); }
  { int p = 0; P(TC(1 ? WCHAR_MIN : p)); }
  { int p = 0; P(sizeof(WCHAR_MIN + p)); }
  { int p = 0; int t = p; t += WCHAR_MIN; P(t); }
  { int p = 0; int t = p; t &= WCHAR_MIN; P(t); }
  { int p = 0; int t = p; t |= WCHAR_MIN; P(t); }
  { int p = 1; P(WCHAR_MIN < p); }
  { int p = 1; P(WCHAR_MIN > p); }
  { int p = 1; P(WCHAR_MIN == p); }
  { int p = 1; P(WCHAR_MIN != p); }
  { int p = 1; P(WCHAR_MIN <= p); }
  { int p = 1; P(WCHAR_MIN >= p); }
  { int p = 1; P(p < WCHAR_MIN); }
  { int p = 1; P(p > WCHAR_MIN); }
  { int p = 1; P(p == WCHAR_MIN); }
  { int p = 1; P(p <= WCHAR_MIN); }
  { int p = 1; P(WCHAR_MIN + p); }
  { int p = 1; P(p + WCHAR_MIN); }
  { int p = 1; P(WCHAR_MIN * p); }
  { int p = 1; P(p * WCHAR_MIN); }
  { int p = 1; P(WCHAR_MIN & p); }
  { int p = 1; P(WCHAR_MIN | p); }
  { int p = 1; P(WCHAR_MIN ^ p); }
  { int p = 1; P(p & WCHAR_MIN); }
  { int p = 1; P(p | WCHAR_MIN); }
  { int p = 1; P(1 ? WCHAR_MIN : p); }
  { int p = 1; P(1 ? p : WCHAR_MIN); }
  { int p = 1; P(0 ? WCHAR_MIN : p); }
  { int p = 1; P(TC(WCHAR_MIN + p)); }
  { int p = 1; P(TC(p + WCHAR_MIN)); }
  { int p = 1; P(TC(1 ? WCHAR_MIN : p)); }
  { int p = 1; P(sizeof(WCHAR_MIN + p)); }
  { int p = 1; P(WCHAR_MIN / p); }
  { int p = 1; P(WCHAR_MIN % p); }
  { int p = 1; int t = p; t += WCHAR_MIN; P(t); }
  { int p = 1; int t = p; t &= WCHAR_MIN; P(t); }
  { int p = 1; int t = p; t |= WCHAR_MIN; P(t); }
  { int p = -1; P(WCHAR_MIN < p); }
  { int p = -1; P(WCHAR_MIN > p); }
  { int p = -1; P(WCHAR_MIN == p); }
  { int p = -1; P(WCHAR_MIN != p); }
  { int p = -1; P(WCHAR_MIN <= p); }
  { int p = -1; P(WCHAR_MIN >= p); }
  { int p = -1; P(p < WCHAR_MIN); }
  { int p = -1; P(p > WCHAR_MIN); }
  { int p = -1; P(p == WCHAR_MIN); }
  { int p = -1; P(p <= WCHAR_MIN); }
  { int p = -1; P(p - WCHAR_MIN); }
  { int p = -1; P(WCHAR_MIN & p); }
  { int p = -1; P(WCHAR_MIN | p); }
  { int p = -1; P(WCHAR_MIN ^ p); }
  { int p = -1; P(p & WCHAR_MIN); }
  { int p = -1; P(p | WCHAR_MIN); }
  { int p = -1; P(1 ? WCHAR_MIN : p); }
  { int p = -1; P(1 ? p : WCHAR_MIN); }
  { int p = -1; P(0 ? WCHAR_MIN : p); }
  { int p = -1; P(TC(WCHAR_MIN + p)); }
  { int p = -1; P(TC(p + WCHAR_MIN)); }
  { int p = -1; P(TC(1 ? WCHAR_MIN : p)); }
  { int p = -1; P(sizeof(WCHAR_MIN + p)); }
  { int p = -1; int t = p; t -= WCHAR_MIN; P(t); }
  { int p = -1; int t = p; t &= WCHAR_MIN; P(t); }
  { int p = -1; int t = p; t |= WCHAR_MIN; P(t); }
  { unsigned p = 0; P(WCHAR_MIN < p); }
  { unsigned p = 0; P(WCHAR_MIN > p); }
  { unsigned p = 0; P(WCHAR_MIN == p); }
  { unsigned p = 0; P(WCHAR_MIN != p); }
  { unsigned p = 0; P(WCHAR_MIN <= p); }
  { unsigned p = 0; P(WCHAR_MIN >= p); }
  { unsigned p = 0; P(p < WCHAR_MIN); }
  { unsigned p = 0; P(p > WCHAR_MIN); }
  { unsigned p = 0; P(p == WCHAR_MIN); }
  { unsigned p = 0; P(p <= WCHAR_MIN); }
  { unsigned p = 0; P(WCHAR_MIN + p); }
  { unsigned p = 0; P(p + WCHAR_MIN); }
  { unsigned p = 0; P(WCHAR_MIN - p); }
  { unsigned p = 0; P(p - WCHAR_MIN); }
  { unsigned p = 0; P(WCHAR_MIN * p); }
  { unsigned p = 0; P(p * WCHAR_MIN); }
  { unsigned p = 0; P(WCHAR_MIN & p); }
  { unsigned p = 0; P(WCHAR_MIN | p); }
  { unsigned p = 0; P(WCHAR_MIN ^ p); }
  { unsigned p = 0; P(p & WCHAR_MIN); }
  { unsigned p = 0; P(p | WCHAR_MIN); }
  { unsigned p = 0; P(1 ? WCHAR_MIN : p); }
  { unsigned p = 0; P(1 ? p : WCHAR_MIN); }
  { unsigned p = 0; P(0 ? WCHAR_MIN : p); }
  { unsigned p = 0; P(TC(WCHAR_MIN + p)); }
  { unsigned p = 0; P(TC(p + WCHAR_MIN)); }
  { unsigned p = 0; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned p = 0; P(sizeof(WCHAR_MIN + p)); }
  { unsigned p = 0; unsigned t = p; t += WCHAR_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t -= WCHAR_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t &= WCHAR_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t |= WCHAR_MIN; P(t); }
  { unsigned p = 1; P(WCHAR_MIN < p); }
  { unsigned p = 1; P(WCHAR_MIN > p); }
  { unsigned p = 1; P(WCHAR_MIN == p); }
  { unsigned p = 1; P(WCHAR_MIN != p); }
  { unsigned p = 1; P(WCHAR_MIN <= p); }
  { unsigned p = 1; P(WCHAR_MIN >= p); }
  { unsigned p = 1; P(p < WCHAR_MIN); }
  { unsigned p = 1; P(p > WCHAR_MIN); }
  { unsigned p = 1; P(p == WCHAR_MIN); }
  { unsigned p = 1; P(p <= WCHAR_MIN); }
  { unsigned p = 1; P(WCHAR_MIN + p); }
  { unsigned p = 1; P(p + WCHAR_MIN); }
  { unsigned p = 1; P(p - WCHAR_MIN); }
  { unsigned p = 1; P(WCHAR_MIN * p); }
  { unsigned p = 1; P(p * WCHAR_MIN); }
  { unsigned p = 1; P(WCHAR_MIN & p); }
  { unsigned p = 1; P(WCHAR_MIN | p); }
  { unsigned p = 1; P(WCHAR_MIN ^ p); }
  { unsigned p = 1; P(p & WCHAR_MIN); }
  { unsigned p = 1; P(p | WCHAR_MIN); }
  { unsigned p = 1; P(1 ? WCHAR_MIN : p); }
  { unsigned p = 1; P(1 ? p : WCHAR_MIN); }
  { unsigned p = 1; P(0 ? WCHAR_MIN : p); }
  { unsigned p = 1; P(TC(WCHAR_MIN + p)); }
  { unsigned p = 1; P(TC(p + WCHAR_MIN)); }
  { unsigned p = 1; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned p = 1; P(sizeof(WCHAR_MIN + p)); }
  { unsigned p = 1; P(WCHAR_MIN / p); }
  { unsigned p = 1; P(WCHAR_MIN % p); }
  { unsigned p = 1; unsigned t = p; t += WCHAR_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t -= WCHAR_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t &= WCHAR_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t |= WCHAR_MIN; P(t); }
  { unsigned p = -1; P(WCHAR_MIN < p); }
  { unsigned p = -1; P(WCHAR_MIN > p); }
  { unsigned p = -1; P(WCHAR_MIN == p); }
  { unsigned p = -1; P(WCHAR_MIN != p); }
  { unsigned p = -1; P(WCHAR_MIN <= p); }
  { unsigned p = -1; P(WCHAR_MIN >= p); }
  { unsigned p = -1; P(p < WCHAR_MIN); }
  { unsigned p = -1; P(p > WCHAR_MIN); }
  { unsigned p = -1; P(p == WCHAR_MIN); }
  { unsigned p = -1; P(p <= WCHAR_MIN); }
  { unsigned p = -1; P(WCHAR_MIN + p); }
  { unsigned p = -1; P(p + WCHAR_MIN); }
  { unsigned p = -1; P(p - WCHAR_MIN); }
  { unsigned p = -1; P(WCHAR_MIN * p); }
  { unsigned p = -1; P(p * WCHAR_MIN); }
  { unsigned p = -1; P(WCHAR_MIN & p); }
  { unsigned p = -1; P(WCHAR_MIN | p); }
  { unsigned p = -1; P(WCHAR_MIN ^ p); }
  { unsigned p = -1; P(p & WCHAR_MIN); }
  { unsigned p = -1; P(p | WCHAR_MIN); }
  { unsigned p = -1; P(1 ? WCHAR_MIN : p); }
  { unsigned p = -1; P(1 ? p : WCHAR_MIN); }
  { unsigned p = -1; P(0 ? WCHAR_MIN : p); }
  { unsigned p = -1; P(TC(WCHAR_MIN + p)); }
  { unsigned p = -1; P(TC(p + WCHAR_MIN)); }
  { unsigned p = -1; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned p = -1; P(sizeof(WCHAR_MIN + p)); }
  { unsigned p = -1; P(WCHAR_MIN / p); }
  { unsigned p = -1; P(WCHAR_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += WCHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= WCHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= WCHAR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= WCHAR_MIN; P(t); }
  { long p = 0; P(WCHAR_MIN < p); }
  { long p = 0; P(WCHAR_MIN > p); }
  { long p = 0; P(WCHAR_MIN == p); }
  { long p = 0; P(WCHAR_MIN != p); }
  { long p = 0; P(WCHAR_MIN <= p); }
  { long p = 0; P(WCHAR_MIN >= p); }
  { long p = 0; P(p < WCHAR_MIN); }
  { long p = 0; P(p > WCHAR_MIN); }
  { long p = 0; P(p == WCHAR_MIN); }
  { long p = 0; P(p <= WCHAR_MIN); }
  { long p = 0; P(WCHAR_MIN + p); }
  { long p = 0; P(p + WCHAR_MIN); }
  { long p = 0; P(WCHAR_MIN - p); }
  { long p = 0; P(p - WCHAR_MIN); }
  { long p = 0; P(WCHAR_MIN * p); }
  { long p = 0; P(p * WCHAR_MIN); }
  { long p = 0; P(WCHAR_MIN & p); }
  { long p = 0; P(WCHAR_MIN | p); }
  { long p = 0; P(WCHAR_MIN ^ p); }
  { long p = 0; P(p & WCHAR_MIN); }
  { long p = 0; P(p | WCHAR_MIN); }
  { long p = 0; P(1 ? WCHAR_MIN : p); }
  { long p = 0; P(1 ? p : WCHAR_MIN); }
  { long p = 0; P(0 ? WCHAR_MIN : p); }
  { long p = 0; P(TC(WCHAR_MIN + p)); }
  { long p = 0; P(TC(p + WCHAR_MIN)); }
  { long p = 0; P(TC(1 ? WCHAR_MIN : p)); }
  { long p = 0; P(sizeof(WCHAR_MIN + p)); }
  { long p = 0; long t = p; t += WCHAR_MIN; P(t); }
  { long p = 0; long t = p; t -= WCHAR_MIN; P(t); }
  { long p = 0; long t = p; t &= WCHAR_MIN; P(t); }
  { long p = 0; long t = p; t |= WCHAR_MIN; P(t); }
  { long p = 1; P(WCHAR_MIN < p); }
  { long p = 1; P(WCHAR_MIN > p); }
  { long p = 1; P(WCHAR_MIN == p); }
  { long p = 1; P(WCHAR_MIN != p); }
  { long p = 1; P(WCHAR_MIN <= p); }
  { long p = 1; P(WCHAR_MIN >= p); }
  { long p = 1; P(p < WCHAR_MIN); }
  { long p = 1; P(p > WCHAR_MIN); }
  { long p = 1; P(p == WCHAR_MIN); }
  { long p = 1; P(p <= WCHAR_MIN); }
  { long p = 1; P(WCHAR_MIN + p); }
  { long p = 1; P(p + WCHAR_MIN); }
  { long p = 1; P(p - WCHAR_MIN); }
  { long p = 1; P(WCHAR_MIN * p); }
  { long p = 1; P(p * WCHAR_MIN); }
  { long p = 1; P(WCHAR_MIN & p); }
  { long p = 1; P(WCHAR_MIN | p); }
  { long p = 1; P(WCHAR_MIN ^ p); }
  { long p = 1; P(p & WCHAR_MIN); }
  { long p = 1; P(p | WCHAR_MIN); }
  { long p = 1; P(1 ? WCHAR_MIN : p); }
  { long p = 1; P(1 ? p : WCHAR_MIN); }
  { long p = 1; P(0 ? WCHAR_MIN : p); }
  { long p = 1; P(TC(WCHAR_MIN + p)); }
  { long p = 1; P(TC(p + WCHAR_MIN)); }
  { long p = 1; P(TC(1 ? WCHAR_MIN : p)); }
  { long p = 1; P(sizeof(WCHAR_MIN + p)); }
  { long p = 1; P(WCHAR_MIN / p); }
  { long p = 1; P(WCHAR_MIN % p); }
  { long p = 1; long t = p; t += WCHAR_MIN; P(t); }
  { long p = 1; long t = p; t -= WCHAR_MIN; P(t); }
  { long p = 1; long t = p; t &= WCHAR_MIN; P(t); }
  { long p = 1; long t = p; t |= WCHAR_MIN; P(t); }
  { long p = -1; P(WCHAR_MIN < p); }
  { long p = -1; P(WCHAR_MIN > p); }
  { long p = -1; P(WCHAR_MIN == p); }
  { long p = -1; P(WCHAR_MIN != p); }
  { long p = -1; P(WCHAR_MIN <= p); }
  { long p = -1; P(WCHAR_MIN >= p); }
  { long p = -1; P(p < WCHAR_MIN); }
  { long p = -1; P(p > WCHAR_MIN); }
  { long p = -1; P(p == WCHAR_MIN); }
  { long p = -1; P(p <= WCHAR_MIN); }
  { long p = -1; P(WCHAR_MIN + p); }
  { long p = -1; P(p + WCHAR_MIN); }
  { long p = -1; P(p - WCHAR_MIN); }
  { long p = -1; P(WCHAR_MIN * p); }
  { long p = -1; P(p * WCHAR_MIN); }
  { long p = -1; P(WCHAR_MIN & p); }
  { long p = -1; P(WCHAR_MIN | p); }
  { long p = -1; P(WCHAR_MIN ^ p); }
  { long p = -1; P(p & WCHAR_MIN); }
  { long p = -1; P(p | WCHAR_MIN); }
  { long p = -1; P(1 ? WCHAR_MIN : p); }
  { long p = -1; P(1 ? p : WCHAR_MIN); }
  { long p = -1; P(0 ? WCHAR_MIN : p); }
  { long p = -1; P(TC(WCHAR_MIN + p)); }
  { long p = -1; P(TC(p + WCHAR_MIN)); }
  { long p = -1; P(TC(1 ? WCHAR_MIN : p)); }
  { long p = -1; P(sizeof(WCHAR_MIN + p)); }
  { long p = -1; long t = p; t += WCHAR_MIN; P(t); }
  { long p = -1; long t = p; t -= WCHAR_MIN; P(t); }
  { long p = -1; long t = p; t &= WCHAR_MIN; P(t); }
  { long p = -1; long t = p; t |= WCHAR_MIN; P(t); }
  { unsigned long p = 0; P(WCHAR_MIN < p); }
  { unsigned long p = 0; P(WCHAR_MIN > p); }
  { unsigned long p = 0; P(WCHAR_MIN == p); }
  { unsigned long p = 0; P(WCHAR_MIN != p); }
  { unsigned long p = 0; P(WCHAR_MIN <= p); }
  { unsigned long p = 0; P(WCHAR_MIN >= p); }
  { unsigned long p = 0; P(p < WCHAR_MIN); }
  { unsigned long p = 0; P(p > WCHAR_MIN); }
  { unsigned long p = 0; P(p == WCHAR_MIN); }
  { unsigned long p = 0; P(p <= WCHAR_MIN); }
  { unsigned long p = 0; P(WCHAR_MIN + p); }
  { unsigned long p = 0; P(p + WCHAR_MIN); }
  { unsigned long p = 0; P(WCHAR_MIN - p); }
  { unsigned long p = 0; P(p - WCHAR_MIN); }
  { unsigned long p = 0; P(WCHAR_MIN * p); }
  { unsigned long p = 0; P(p * WCHAR_MIN); }
  { unsigned long p = 0; P(WCHAR_MIN & p); }
  { unsigned long p = 0; P(WCHAR_MIN | p); }
  { unsigned long p = 0; P(WCHAR_MIN ^ p); }
  { unsigned long p = 0; P(p & WCHAR_MIN); }
  { unsigned long p = 0; P(p | WCHAR_MIN); }
  { unsigned long p = 0; P(1 ? WCHAR_MIN : p); }
  { unsigned long p = 0; P(1 ? p : WCHAR_MIN); }
  { unsigned long p = 0; P(0 ? WCHAR_MIN : p); }
  { unsigned long p = 0; P(TC(WCHAR_MIN + p)); }
  { unsigned long p = 0; P(TC(p + WCHAR_MIN)); }
  { unsigned long p = 0; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned long p = 0; P(sizeof(WCHAR_MIN + p)); }
  { unsigned long p = 0; unsigned long t = p; t += WCHAR_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t -= WCHAR_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t &= WCHAR_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t |= WCHAR_MIN; P(t); }
  { unsigned long p = 1; P(WCHAR_MIN < p); }
  { unsigned long p = 1; P(WCHAR_MIN > p); }
  { unsigned long p = 1; P(WCHAR_MIN == p); }
  { unsigned long p = 1; P(WCHAR_MIN != p); }
  { unsigned long p = 1; P(WCHAR_MIN <= p); }
  { unsigned long p = 1; P(WCHAR_MIN >= p); }
  { unsigned long p = 1; P(p < WCHAR_MIN); }
  { unsigned long p = 1; P(p > WCHAR_MIN); }
  { unsigned long p = 1; P(p == WCHAR_MIN); }
  { unsigned long p = 1; P(p <= WCHAR_MIN); }
  { unsigned long p = 1; P(WCHAR_MIN + p); }
  { unsigned long p = 1; P(p + WCHAR_MIN); }
  { unsigned long p = 1; P(p - WCHAR_MIN); }
  { unsigned long p = 1; P(WCHAR_MIN * p); }
  { unsigned long p = 1; P(p * WCHAR_MIN); }
  { unsigned long p = 1; P(WCHAR_MIN & p); }
  { unsigned long p = 1; P(WCHAR_MIN | p); }
  { unsigned long p = 1; P(WCHAR_MIN ^ p); }
  { unsigned long p = 1; P(p & WCHAR_MIN); }
  { unsigned long p = 1; P(p | WCHAR_MIN); }
  { unsigned long p = 1; P(1 ? WCHAR_MIN : p); }
  { unsigned long p = 1; P(1 ? p : WCHAR_MIN); }
  { unsigned long p = 1; P(0 ? WCHAR_MIN : p); }
  { unsigned long p = 1; P(TC(WCHAR_MIN + p)); }
  { unsigned long p = 1; P(TC(p + WCHAR_MIN)); }
  { unsigned long p = 1; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned long p = 1; P(sizeof(WCHAR_MIN + p)); }
  { unsigned long p = 1; P(WCHAR_MIN / p); }
  { unsigned long p = 1; P(WCHAR_MIN % p); }
  { unsigned long p = 1; unsigned long t = p; t += WCHAR_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t -= WCHAR_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t &= WCHAR_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t |= WCHAR_MIN; P(t); }
  { unsigned long p = -1; P(WCHAR_MIN < p); }
  { unsigned long p = -1; P(WCHAR_MIN > p); }
  { unsigned long p = -1; P(WCHAR_MIN == p); }
  { unsigned long p = -1; P(WCHAR_MIN != p); }
  { unsigned long p = -1; P(WCHAR_MIN <= p); }
  { unsigned long p = -1; P(WCHAR_MIN >= p); }
  { unsigned long p = -1; P(p < WCHAR_MIN); }
  { unsigned long p = -1; P(p > WCHAR_MIN); }
  { unsigned long p = -1; P(p == WCHAR_MIN); }
  { unsigned long p = -1; P(p <= WCHAR_MIN); }
  { unsigned long p = -1; P(WCHAR_MIN + p); }
  { unsigned long p = -1; P(p + WCHAR_MIN); }
  { unsigned long p = -1; P(p - WCHAR_MIN); }
  { unsigned long p = -1; P(WCHAR_MIN * p); }
  { unsigned long p = -1; P(p * WCHAR_MIN); }
  { unsigned long p = -1; P(WCHAR_MIN & p); }
  { unsigned long p = -1; P(WCHAR_MIN | p); }
  { unsigned long p = -1; P(WCHAR_MIN ^ p); }
  { unsigned long p = -1; P(p & WCHAR_MIN); }
  { unsigned long p = -1; P(p | WCHAR_MIN); }
  { unsigned long p = -1; P(1 ? WCHAR_MIN : p); }
  { unsigned long p = -1; P(1 ? p : WCHAR_MIN); }
  { unsigned long p = -1; P(0 ? WCHAR_MIN : p); }
  { unsigned long p = -1; P(TC(WCHAR_MIN + p)); }
  { unsigned long p = -1; P(TC(p + WCHAR_MIN)); }
  { unsigned long p = -1; P(TC(1 ? WCHAR_MIN : p)); }
  { unsigned long p = -1; P(sizeof(WCHAR_MIN + p)); }
  { unsigned long p = -1; P(WCHAR_MIN / p); }
  { unsigned long p = -1; P(WCHAR_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += WCHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= WCHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= WCHAR_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= WCHAR_MIN; P(t); }
  printf("\n");
  return 0;
}
