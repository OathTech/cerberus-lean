// KEPT (upstream's behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f's line; gcc 13's line beside in kept.txt): WINT_MIN and WINT_MAX compared with 0, promoted, converted, and against int, unsigned, long, unsigned long (0, 1, -1)
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(WINT_MAX > 0);
  P(WINT_MAX < 0);
  P(WINT_MAX == 0);
  P(WINT_MAX != 0);
  P(WINT_MAX >= 0);
  P(WINT_MAX <= 0);
  P(0 < WINT_MAX);
  P(0 > WINT_MAX);
  P(0 == WINT_MAX);
  P(+WINT_MAX);
  P(~WINT_MAX);
  P(!WINT_MAX);
  P((+WINT_MAX) > 0);
  P(sizeof(WINT_MAX));
  P(sizeof(+WINT_MAX));
  P(TC(WINT_MAX));
  P(TC(+WINT_MAX));
  P(TC(-WINT_MAX));
  P(TC(~WINT_MAX));
  P((_Bool)WINT_MAX);
  P((signed char)WINT_MAX);
  P((unsigned char)WINT_MAX);
  P((short)WINT_MAX);
  P((unsigned short)WINT_MAX);
  P((int)WINT_MAX);
  P((unsigned)WINT_MAX);
  P((long)WINT_MAX);
  P((unsigned long)WINT_MAX);
  P((long long)WINT_MAX);
  P((unsigned long long)WINT_MAX);
  P((long long)WINT_MAX > 0);
  P((long long)WINT_MAX < 0);
  { int x = WINT_MAX; P(x); }
  { unsigned x = WINT_MAX; P(x); }
  { long x = WINT_MAX; P(x); }
  { unsigned long x = WINT_MAX; P(x); }
  P(WINT_MAX - 1);
  P(WINT_MAX - 1 > 0);
  P(WINT_MAX - 1u);
  P(WINT_MAX - 1ul);
  { int p = 0; P(WINT_MAX < p); }
  { int p = 0; P(WINT_MAX > p); }
  { int p = 0; P(WINT_MAX == p); }
  { int p = 0; P(WINT_MAX != p); }
  { int p = 0; P(WINT_MAX <= p); }
  { int p = 0; P(WINT_MAX >= p); }
  { int p = 0; P(p < WINT_MAX); }
  { int p = 0; P(p > WINT_MAX); }
  { int p = 0; P(p == WINT_MAX); }
  { int p = 0; P(p <= WINT_MAX); }
  { int p = 0; P(WINT_MAX + p); }
  { int p = 0; P(p + WINT_MAX); }
  { int p = 0; P(WINT_MAX - p); }
  { int p = 0; P(p - WINT_MAX); }
  { int p = 0; P(WINT_MAX * p); }
  { int p = 0; P(p * WINT_MAX); }
  { int p = 0; P(WINT_MAX & p); }
  { int p = 0; P(WINT_MAX | p); }
  { int p = 0; P(WINT_MAX ^ p); }
  { int p = 0; P(p & WINT_MAX); }
  { int p = 0; P(p | WINT_MAX); }
  { int p = 0; P(1 ? WINT_MAX : p); }
  { int p = 0; P(1 ? p : WINT_MAX); }
  { int p = 0; P(0 ? WINT_MAX : p); }
  { int p = 0; P(TC(WINT_MAX + p)); }
  { int p = 0; P(TC(p + WINT_MAX)); }
  { int p = 0; P(TC(1 ? WINT_MAX : p)); }
  { int p = 0; P(sizeof(WINT_MAX + p)); }
  { int p = 0; int t = p; t += WINT_MAX; P(t); }
  { int p = 0; int t = p; t -= WINT_MAX; P(t); }
  { int p = 0; int t = p; t &= WINT_MAX; P(t); }
  { int p = 0; int t = p; t |= WINT_MAX; P(t); }
  { int p = 1; P(WINT_MAX < p); }
  { int p = 1; P(WINT_MAX > p); }
  { int p = 1; P(WINT_MAX == p); }
  { int p = 1; P(WINT_MAX != p); }
  { int p = 1; P(WINT_MAX <= p); }
  { int p = 1; P(WINT_MAX >= p); }
  { int p = 1; P(p < WINT_MAX); }
  { int p = 1; P(p > WINT_MAX); }
  { int p = 1; P(p == WINT_MAX); }
  { int p = 1; P(p <= WINT_MAX); }
  { int p = 1; P(WINT_MAX - p); }
  { int p = 1; P(p - WINT_MAX); }
  { int p = 1; P(WINT_MAX * p); }
  { int p = 1; P(p * WINT_MAX); }
  { int p = 1; P(WINT_MAX & p); }
  { int p = 1; P(WINT_MAX | p); }
  { int p = 1; P(WINT_MAX ^ p); }
  { int p = 1; P(p & WINT_MAX); }
  { int p = 1; P(p | WINT_MAX); }
  { int p = 1; P(1 ? WINT_MAX : p); }
  { int p = 1; P(1 ? p : WINT_MAX); }
  { int p = 1; P(0 ? WINT_MAX : p); }
  { int p = 1; P(TC(WINT_MAX + p)); }
  { int p = 1; P(TC(p + WINT_MAX)); }
  { int p = 1; P(TC(1 ? WINT_MAX : p)); }
  { int p = 1; P(sizeof(WINT_MAX + p)); }
  { int p = 1; P(WINT_MAX / p); }
  { int p = 1; P(WINT_MAX % p); }
  { int p = 1; int t = p; t -= WINT_MAX; P(t); }
  { int p = 1; int t = p; t &= WINT_MAX; P(t); }
  { int p = 1; int t = p; t |= WINT_MAX; P(t); }
  { int p = -1; P(WINT_MAX < p); }
  { int p = -1; P(WINT_MAX > p); }
  { int p = -1; P(WINT_MAX == p); }
  { int p = -1; P(WINT_MAX != p); }
  { int p = -1; P(WINT_MAX <= p); }
  { int p = -1; P(WINT_MAX >= p); }
  { int p = -1; P(p < WINT_MAX); }
  { int p = -1; P(p > WINT_MAX); }
  { int p = -1; P(p == WINT_MAX); }
  { int p = -1; P(p <= WINT_MAX); }
  { int p = -1; P(p + WINT_MAX); }
  { int p = -1; P(WINT_MAX - p); }
  { int p = -1; P(p - WINT_MAX); }
  { int p = -1; P(p * WINT_MAX); }
  { int p = -1; P(WINT_MAX & p); }
  { int p = -1; P(WINT_MAX | p); }
  { int p = -1; P(WINT_MAX ^ p); }
  { int p = -1; P(p & WINT_MAX); }
  { int p = -1; P(p | WINT_MAX); }
  { int p = -1; P(1 ? WINT_MAX : p); }
  { int p = -1; P(1 ? p : WINT_MAX); }
  { int p = -1; P(0 ? WINT_MAX : p); }
  { int p = -1; P(TC(WINT_MAX + p)); }
  { int p = -1; P(TC(p + WINT_MAX)); }
  { int p = -1; P(TC(1 ? WINT_MAX : p)); }
  { int p = -1; P(sizeof(WINT_MAX + p)); }
  { int p = -1; int t = p; t += WINT_MAX; P(t); }
  { int p = -1; int t = p; t -= WINT_MAX; P(t); }
  { int p = -1; int t = p; t &= WINT_MAX; P(t); }
  { int p = -1; int t = p; t |= WINT_MAX; P(t); }
  { unsigned p = 0; P(WINT_MAX < p); }
  { unsigned p = 0; P(WINT_MAX > p); }
  { unsigned p = 0; P(WINT_MAX == p); }
  { unsigned p = 0; P(WINT_MAX != p); }
  { unsigned p = 0; P(WINT_MAX <= p); }
  { unsigned p = 0; P(WINT_MAX >= p); }
  { unsigned p = 0; P(p < WINT_MAX); }
  { unsigned p = 0; P(p > WINT_MAX); }
  { unsigned p = 0; P(p == WINT_MAX); }
  { unsigned p = 0; P(p <= WINT_MAX); }
  { unsigned p = 0; P(WINT_MAX + p); }
  { unsigned p = 0; P(p + WINT_MAX); }
  { unsigned p = 0; P(WINT_MAX - p); }
  { unsigned p = 0; P(WINT_MAX * p); }
  { unsigned p = 0; P(p * WINT_MAX); }
  { unsigned p = 0; P(WINT_MAX & p); }
  { unsigned p = 0; P(WINT_MAX | p); }
  { unsigned p = 0; P(WINT_MAX ^ p); }
  { unsigned p = 0; P(p & WINT_MAX); }
  { unsigned p = 0; P(p | WINT_MAX); }
  { unsigned p = 0; P(1 ? WINT_MAX : p); }
  { unsigned p = 0; P(1 ? p : WINT_MAX); }
  { unsigned p = 0; P(0 ? WINT_MAX : p); }
  { unsigned p = 0; P(TC(WINT_MAX + p)); }
  { unsigned p = 0; P(TC(p + WINT_MAX)); }
  { unsigned p = 0; P(TC(1 ? WINT_MAX : p)); }
  { unsigned p = 0; P(sizeof(WINT_MAX + p)); }
  { unsigned p = 0; unsigned t = p; t += WINT_MAX; P(t); }
  { unsigned p = 0; unsigned t = p; t &= WINT_MAX; P(t); }
  { unsigned p = 0; unsigned t = p; t |= WINT_MAX; P(t); }
  { unsigned p = 1; P(WINT_MAX < p); }
  { unsigned p = 1; P(WINT_MAX > p); }
  { unsigned p = 1; P(WINT_MAX == p); }
  { unsigned p = 1; P(WINT_MAX != p); }
  { unsigned p = 1; P(WINT_MAX <= p); }
  { unsigned p = 1; P(WINT_MAX >= p); }
  { unsigned p = 1; P(p < WINT_MAX); }
  { unsigned p = 1; P(p > WINT_MAX); }
  { unsigned p = 1; P(p == WINT_MAX); }
  { unsigned p = 1; P(p <= WINT_MAX); }
  { unsigned p = 1; P(WINT_MAX - p); }
  { unsigned p = 1; P(WINT_MAX * p); }
  { unsigned p = 1; P(p * WINT_MAX); }
  { unsigned p = 1; P(WINT_MAX & p); }
  { unsigned p = 1; P(WINT_MAX | p); }
  { unsigned p = 1; P(WINT_MAX ^ p); }
  { unsigned p = 1; P(p & WINT_MAX); }
  { unsigned p = 1; P(p | WINT_MAX); }
  { unsigned p = 1; P(1 ? WINT_MAX : p); }
  { unsigned p = 1; P(1 ? p : WINT_MAX); }
  { unsigned p = 1; P(0 ? WINT_MAX : p); }
  { unsigned p = 1; P(TC(WINT_MAX + p)); }
  { unsigned p = 1; P(TC(p + WINT_MAX)); }
  { unsigned p = 1; P(TC(1 ? WINT_MAX : p)); }
  { unsigned p = 1; P(sizeof(WINT_MAX + p)); }
  { unsigned p = 1; P(WINT_MAX / p); }
  { unsigned p = 1; P(WINT_MAX % p); }
  { unsigned p = 1; unsigned t = p; t &= WINT_MAX; P(t); }
  { unsigned p = 1; unsigned t = p; t |= WINT_MAX; P(t); }
  { unsigned p = -1; P(WINT_MAX < p); }
  { unsigned p = -1; P(WINT_MAX > p); }
  { unsigned p = -1; P(WINT_MAX == p); }
  { unsigned p = -1; P(WINT_MAX != p); }
  { unsigned p = -1; P(WINT_MAX <= p); }
  { unsigned p = -1; P(WINT_MAX >= p); }
  { unsigned p = -1; P(p < WINT_MAX); }
  { unsigned p = -1; P(p > WINT_MAX); }
  { unsigned p = -1; P(p == WINT_MAX); }
  { unsigned p = -1; P(p <= WINT_MAX); }
  { unsigned p = -1; P(WINT_MAX - p); }
  { unsigned p = -1; P(p - WINT_MAX); }
  { unsigned p = -1; P(WINT_MAX & p); }
  { unsigned p = -1; P(WINT_MAX | p); }
  { unsigned p = -1; P(WINT_MAX ^ p); }
  { unsigned p = -1; P(p & WINT_MAX); }
  { unsigned p = -1; P(p | WINT_MAX); }
  { unsigned p = -1; P(1 ? WINT_MAX : p); }
  { unsigned p = -1; P(1 ? p : WINT_MAX); }
  { unsigned p = -1; P(0 ? WINT_MAX : p); }
  { unsigned p = -1; P(TC(WINT_MAX + p)); }
  { unsigned p = -1; P(TC(p + WINT_MAX)); }
  { unsigned p = -1; P(TC(1 ? WINT_MAX : p)); }
  { unsigned p = -1; P(sizeof(WINT_MAX + p)); }
  { unsigned p = -1; P(WINT_MAX / p); }
  { unsigned p = -1; P(WINT_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= WINT_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= WINT_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= WINT_MAX; P(t); }
  { long p = 0; P(WINT_MAX < p); }
  { long p = 0; P(WINT_MAX > p); }
  { long p = 0; P(WINT_MAX == p); }
  { long p = 0; P(WINT_MAX != p); }
  { long p = 0; P(WINT_MAX <= p); }
  { long p = 0; P(WINT_MAX >= p); }
  { long p = 0; P(p < WINT_MAX); }
  { long p = 0; P(p > WINT_MAX); }
  { long p = 0; P(p == WINT_MAX); }
  { long p = 0; P(p <= WINT_MAX); }
  { long p = 0; P(WINT_MAX + p); }
  { long p = 0; P(p + WINT_MAX); }
  { long p = 0; P(WINT_MAX - p); }
  { long p = 0; P(p - WINT_MAX); }
  { long p = 0; P(WINT_MAX * p); }
  { long p = 0; P(p * WINT_MAX); }
  { long p = 0; P(WINT_MAX & p); }
  { long p = 0; P(WINT_MAX | p); }
  { long p = 0; P(WINT_MAX ^ p); }
  { long p = 0; P(p & WINT_MAX); }
  { long p = 0; P(p | WINT_MAX); }
  { long p = 0; P(1 ? WINT_MAX : p); }
  { long p = 0; P(1 ? p : WINT_MAX); }
  { long p = 0; P(0 ? WINT_MAX : p); }
  { long p = 0; P(TC(WINT_MAX + p)); }
  { long p = 0; P(TC(p + WINT_MAX)); }
  { long p = 0; P(TC(1 ? WINT_MAX : p)); }
  { long p = 0; P(sizeof(WINT_MAX + p)); }
  { long p = 0; long t = p; t += WINT_MAX; P(t); }
  { long p = 0; long t = p; t -= WINT_MAX; P(t); }
  { long p = 0; long t = p; t &= WINT_MAX; P(t); }
  { long p = 0; long t = p; t |= WINT_MAX; P(t); }
  { long p = 1; P(WINT_MAX < p); }
  { long p = 1; P(WINT_MAX > p); }
  { long p = 1; P(WINT_MAX == p); }
  { long p = 1; P(WINT_MAX != p); }
  { long p = 1; P(WINT_MAX <= p); }
  { long p = 1; P(WINT_MAX >= p); }
  { long p = 1; P(p < WINT_MAX); }
  { long p = 1; P(p > WINT_MAX); }
  { long p = 1; P(p == WINT_MAX); }
  { long p = 1; P(p <= WINT_MAX); }
  { long p = 1; P(p + WINT_MAX); }
  { long p = 1; P(WINT_MAX - p); }
  { long p = 1; P(p - WINT_MAX); }
  { long p = 1; P(WINT_MAX * p); }
  { long p = 1; P(p * WINT_MAX); }
  { long p = 1; P(WINT_MAX & p); }
  { long p = 1; P(WINT_MAX | p); }
  { long p = 1; P(WINT_MAX ^ p); }
  { long p = 1; P(p & WINT_MAX); }
  { long p = 1; P(p | WINT_MAX); }
  { long p = 1; P(1 ? WINT_MAX : p); }
  { long p = 1; P(1 ? p : WINT_MAX); }
  { long p = 1; P(0 ? WINT_MAX : p); }
  { long p = 1; P(TC(WINT_MAX + p)); }
  { long p = 1; P(TC(p + WINT_MAX)); }
  { long p = 1; P(TC(1 ? WINT_MAX : p)); }
  { long p = 1; P(sizeof(WINT_MAX + p)); }
  { long p = 1; P(WINT_MAX / p); }
  { long p = 1; P(WINT_MAX % p); }
  { long p = 1; long t = p; t += WINT_MAX; P(t); }
  { long p = 1; long t = p; t -= WINT_MAX; P(t); }
  { long p = 1; long t = p; t &= WINT_MAX; P(t); }
  { long p = 1; long t = p; t |= WINT_MAX; P(t); }
  { long p = -1; P(WINT_MAX < p); }
  { long p = -1; P(WINT_MAX > p); }
  { long p = -1; P(WINT_MAX == p); }
  { long p = -1; P(WINT_MAX != p); }
  { long p = -1; P(WINT_MAX <= p); }
  { long p = -1; P(WINT_MAX >= p); }
  { long p = -1; P(p < WINT_MAX); }
  { long p = -1; P(p > WINT_MAX); }
  { long p = -1; P(p == WINT_MAX); }
  { long p = -1; P(p <= WINT_MAX); }
  { long p = -1; P(p + WINT_MAX); }
  { long p = -1; P(WINT_MAX - p); }
  { long p = -1; P(p - WINT_MAX); }
  { long p = -1; P(p * WINT_MAX); }
  { long p = -1; P(WINT_MAX & p); }
  { long p = -1; P(WINT_MAX | p); }
  { long p = -1; P(WINT_MAX ^ p); }
  { long p = -1; P(p & WINT_MAX); }
  { long p = -1; P(p | WINT_MAX); }
  { long p = -1; P(1 ? WINT_MAX : p); }
  { long p = -1; P(1 ? p : WINT_MAX); }
  { long p = -1; P(0 ? WINT_MAX : p); }
  { long p = -1; P(TC(WINT_MAX + p)); }
  { long p = -1; P(TC(p + WINT_MAX)); }
  { long p = -1; P(TC(1 ? WINT_MAX : p)); }
  { long p = -1; P(sizeof(WINT_MAX + p)); }
  { long p = -1; long t = p; t += WINT_MAX; P(t); }
  { long p = -1; long t = p; t -= WINT_MAX; P(t); }
  { long p = -1; long t = p; t &= WINT_MAX; P(t); }
  { long p = -1; long t = p; t |= WINT_MAX; P(t); }
  { unsigned long p = 0; P(WINT_MAX < p); }
  { unsigned long p = 0; P(WINT_MAX > p); }
  { unsigned long p = 0; P(WINT_MAX == p); }
  { unsigned long p = 0; P(WINT_MAX != p); }
  { unsigned long p = 0; P(WINT_MAX <= p); }
  { unsigned long p = 0; P(WINT_MAX >= p); }
  { unsigned long p = 0; P(p < WINT_MAX); }
  { unsigned long p = 0; P(p > WINT_MAX); }
  { unsigned long p = 0; P(p == WINT_MAX); }
  { unsigned long p = 0; P(p <= WINT_MAX); }
  { unsigned long p = 0; P(WINT_MAX + p); }
  { unsigned long p = 0; P(p + WINT_MAX); }
  { unsigned long p = 0; P(WINT_MAX - p); }
  { unsigned long p = 0; P(WINT_MAX * p); }
  { unsigned long p = 0; P(p * WINT_MAX); }
  { unsigned long p = 0; P(WINT_MAX & p); }
  { unsigned long p = 0; P(WINT_MAX | p); }
  { unsigned long p = 0; P(WINT_MAX ^ p); }
  { unsigned long p = 0; P(p & WINT_MAX); }
  { unsigned long p = 0; P(p | WINT_MAX); }
  { unsigned long p = 0; P(1 ? WINT_MAX : p); }
  { unsigned long p = 0; P(1 ? p : WINT_MAX); }
  { unsigned long p = 0; P(0 ? WINT_MAX : p); }
  { unsigned long p = 0; P(TC(WINT_MAX + p)); }
  { unsigned long p = 0; P(TC(p + WINT_MAX)); }
  { unsigned long p = 0; P(TC(1 ? WINT_MAX : p)); }
  { unsigned long p = 0; P(sizeof(WINT_MAX + p)); }
  { unsigned long p = 0; unsigned long t = p; t += WINT_MAX; P(t); }
  { unsigned long p = 0; unsigned long t = p; t &= WINT_MAX; P(t); }
  { unsigned long p = 0; unsigned long t = p; t |= WINT_MAX; P(t); }
  { unsigned long p = 1; P(WINT_MAX < p); }
  { unsigned long p = 1; P(WINT_MAX > p); }
  { unsigned long p = 1; P(WINT_MAX == p); }
  { unsigned long p = 1; P(WINT_MAX != p); }
  { unsigned long p = 1; P(WINT_MAX <= p); }
  { unsigned long p = 1; P(WINT_MAX >= p); }
  { unsigned long p = 1; P(p < WINT_MAX); }
  { unsigned long p = 1; P(p > WINT_MAX); }
  { unsigned long p = 1; P(p == WINT_MAX); }
  { unsigned long p = 1; P(p <= WINT_MAX); }
  { unsigned long p = 1; P(WINT_MAX - p); }
  { unsigned long p = 1; P(WINT_MAX * p); }
  { unsigned long p = 1; P(p * WINT_MAX); }
  { unsigned long p = 1; P(WINT_MAX & p); }
  { unsigned long p = 1; P(WINT_MAX | p); }
  { unsigned long p = 1; P(WINT_MAX ^ p); }
  { unsigned long p = 1; P(p & WINT_MAX); }
  { unsigned long p = 1; P(p | WINT_MAX); }
  { unsigned long p = 1; P(1 ? WINT_MAX : p); }
  { unsigned long p = 1; P(1 ? p : WINT_MAX); }
  { unsigned long p = 1; P(0 ? WINT_MAX : p); }
  { unsigned long p = 1; P(TC(WINT_MAX + p)); }
  { unsigned long p = 1; P(TC(p + WINT_MAX)); }
  { unsigned long p = 1; P(TC(1 ? WINT_MAX : p)); }
  { unsigned long p = 1; P(sizeof(WINT_MAX + p)); }
  { unsigned long p = 1; P(WINT_MAX / p); }
  { unsigned long p = 1; P(WINT_MAX % p); }
  { unsigned long p = 1; unsigned long t = p; t &= WINT_MAX; P(t); }
  { unsigned long p = 1; unsigned long t = p; t |= WINT_MAX; P(t); }
  { unsigned long p = -1; P(WINT_MAX < p); }
  { unsigned long p = -1; P(WINT_MAX > p); }
  { unsigned long p = -1; P(WINT_MAX == p); }
  { unsigned long p = -1; P(WINT_MAX != p); }
  { unsigned long p = -1; P(WINT_MAX <= p); }
  { unsigned long p = -1; P(WINT_MAX >= p); }
  { unsigned long p = -1; P(p < WINT_MAX); }
  { unsigned long p = -1; P(p > WINT_MAX); }
  { unsigned long p = -1; P(p == WINT_MAX); }
  { unsigned long p = -1; P(p <= WINT_MAX); }
  { unsigned long p = -1; P(WINT_MAX - p); }
  { unsigned long p = -1; P(p - WINT_MAX); }
  { unsigned long p = -1; P(WINT_MAX & p); }
  { unsigned long p = -1; P(WINT_MAX | p); }
  { unsigned long p = -1; P(WINT_MAX ^ p); }
  { unsigned long p = -1; P(p & WINT_MAX); }
  { unsigned long p = -1; P(p | WINT_MAX); }
  { unsigned long p = -1; P(1 ? WINT_MAX : p); }
  { unsigned long p = -1; P(1 ? p : WINT_MAX); }
  { unsigned long p = -1; P(0 ? WINT_MAX : p); }
  { unsigned long p = -1; P(TC(WINT_MAX + p)); }
  { unsigned long p = -1; P(TC(p + WINT_MAX)); }
  { unsigned long p = -1; P(TC(1 ? WINT_MAX : p)); }
  { unsigned long p = -1; P(sizeof(WINT_MAX + p)); }
  { unsigned long p = -1; P(WINT_MAX / p); }
  { unsigned long p = -1; P(WINT_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t -= WINT_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= WINT_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= WINT_MAX; P(t); }
  P(WINT_MIN > 0);
  P(WINT_MIN < 0);
  P(WINT_MIN == 0);
  P(WINT_MIN != 0);
  P(WINT_MIN >= 0);
  P(WINT_MIN <= 0);
  P(0 < WINT_MIN);
  P(0 > WINT_MIN);
  P(0 == WINT_MIN);
  P(+WINT_MIN);
  P(-WINT_MIN);
  P(~WINT_MIN);
  P(!WINT_MIN);
  P((+WINT_MIN) > 0);
  P(sizeof(WINT_MIN));
  P(sizeof(+WINT_MIN));
  P(TC(WINT_MIN));
  P(TC(+WINT_MIN));
  P(TC(-WINT_MIN));
  P(TC(~WINT_MIN));
  P((_Bool)WINT_MIN);
  P((signed char)WINT_MIN);
  P((unsigned char)WINT_MIN);
  P((short)WINT_MIN);
  P((unsigned short)WINT_MIN);
  P((int)WINT_MIN);
  P((unsigned)WINT_MIN);
  P((long)WINT_MIN);
  P((unsigned long)WINT_MIN);
  P((long long)WINT_MIN);
  P((unsigned long long)WINT_MIN);
  P((long long)WINT_MIN > 0);
  P((long long)WINT_MIN < 0);
  { int x = WINT_MIN; P(x); }
  { unsigned x = WINT_MIN; P(x); }
  { long x = WINT_MIN; P(x); }
  { unsigned long x = WINT_MIN; P(x); }
  P(WINT_MIN + 1);
  P(WINT_MIN + 1 > 0);
  P(WINT_MIN + 1u);
  P(WINT_MIN + 1l);
  { int p = 0; P(WINT_MIN < p); }
  { int p = 0; P(WINT_MIN > p); }
  { int p = 0; P(WINT_MIN == p); }
  { int p = 0; P(WINT_MIN != p); }
  { int p = 0; P(WINT_MIN <= p); }
  { int p = 0; P(WINT_MIN >= p); }
  { int p = 0; P(p < WINT_MIN); }
  { int p = 0; P(p > WINT_MIN); }
  { int p = 0; P(p == WINT_MIN); }
  { int p = 0; P(p <= WINT_MIN); }
  { int p = 0; P(WINT_MIN + p); }
  { int p = 0; P(p + WINT_MIN); }
  { int p = 0; P(WINT_MIN - p); }
  { int p = 0; P(p - WINT_MIN); }
  { int p = 0; P(WINT_MIN * p); }
  { int p = 0; P(p * WINT_MIN); }
  { int p = 0; P(WINT_MIN & p); }
  { int p = 0; P(WINT_MIN | p); }
  { int p = 0; P(WINT_MIN ^ p); }
  { int p = 0; P(p & WINT_MIN); }
  { int p = 0; P(p | WINT_MIN); }
  { int p = 0; P(1 ? WINT_MIN : p); }
  { int p = 0; P(1 ? p : WINT_MIN); }
  { int p = 0; P(0 ? WINT_MIN : p); }
  { int p = 0; P(TC(WINT_MIN + p)); }
  { int p = 0; P(TC(p + WINT_MIN)); }
  { int p = 0; P(TC(1 ? WINT_MIN : p)); }
  { int p = 0; P(sizeof(WINT_MIN + p)); }
  { int p = 0; int t = p; t += WINT_MIN; P(t); }
  { int p = 0; int t = p; t -= WINT_MIN; P(t); }
  { int p = 0; int t = p; t &= WINT_MIN; P(t); }
  { int p = 0; int t = p; t |= WINT_MIN; P(t); }
  { int p = 1; P(WINT_MIN < p); }
  { int p = 1; P(WINT_MIN > p); }
  { int p = 1; P(WINT_MIN == p); }
  { int p = 1; P(WINT_MIN != p); }
  { int p = 1; P(WINT_MIN <= p); }
  { int p = 1; P(WINT_MIN >= p); }
  { int p = 1; P(p < WINT_MIN); }
  { int p = 1; P(p > WINT_MIN); }
  { int p = 1; P(p == WINT_MIN); }
  { int p = 1; P(p <= WINT_MIN); }
  { int p = 1; P(WINT_MIN + p); }
  { int p = 1; P(p + WINT_MIN); }
  { int p = 1; P(p - WINT_MIN); }
  { int p = 1; P(WINT_MIN * p); }
  { int p = 1; P(p * WINT_MIN); }
  { int p = 1; P(WINT_MIN & p); }
  { int p = 1; P(WINT_MIN | p); }
  { int p = 1; P(WINT_MIN ^ p); }
  { int p = 1; P(p & WINT_MIN); }
  { int p = 1; P(p | WINT_MIN); }
  { int p = 1; P(1 ? WINT_MIN : p); }
  { int p = 1; P(1 ? p : WINT_MIN); }
  { int p = 1; P(0 ? WINT_MIN : p); }
  { int p = 1; P(TC(WINT_MIN + p)); }
  { int p = 1; P(TC(p + WINT_MIN)); }
  { int p = 1; P(TC(1 ? WINT_MIN : p)); }
  { int p = 1; P(sizeof(WINT_MIN + p)); }
  { int p = 1; P(WINT_MIN / p); }
  { int p = 1; P(WINT_MIN % p); }
  { int p = 1; int t = p; t += WINT_MIN; P(t); }
  { int p = 1; int t = p; t -= WINT_MIN; P(t); }
  { int p = 1; int t = p; t &= WINT_MIN; P(t); }
  { int p = 1; int t = p; t |= WINT_MIN; P(t); }
  { int p = -1; P(WINT_MIN < p); }
  { int p = -1; P(WINT_MIN > p); }
  { int p = -1; P(WINT_MIN == p); }
  { int p = -1; P(WINT_MIN != p); }
  { int p = -1; P(WINT_MIN <= p); }
  { int p = -1; P(WINT_MIN >= p); }
  { int p = -1; P(p < WINT_MIN); }
  { int p = -1; P(p > WINT_MIN); }
  { int p = -1; P(p == WINT_MIN); }
  { int p = -1; P(p <= WINT_MIN); }
  { int p = -1; P(WINT_MIN + p); }
  { int p = -1; P(p + WINT_MIN); }
  { int p = -1; P(p - WINT_MIN); }
  { int p = -1; P(WINT_MIN * p); }
  { int p = -1; P(p * WINT_MIN); }
  { int p = -1; P(WINT_MIN & p); }
  { int p = -1; P(WINT_MIN | p); }
  { int p = -1; P(WINT_MIN ^ p); }
  { int p = -1; P(p & WINT_MIN); }
  { int p = -1; P(p | WINT_MIN); }
  { int p = -1; P(1 ? WINT_MIN : p); }
  { int p = -1; P(1 ? p : WINT_MIN); }
  { int p = -1; P(0 ? WINT_MIN : p); }
  { int p = -1; P(TC(WINT_MIN + p)); }
  { int p = -1; P(TC(p + WINT_MIN)); }
  { int p = -1; P(TC(1 ? WINT_MIN : p)); }
  { int p = -1; P(sizeof(WINT_MIN + p)); }
  { int p = -1; int t = p; t += WINT_MIN; P(t); }
  { int p = -1; int t = p; t -= WINT_MIN; P(t); }
  { int p = -1; int t = p; t &= WINT_MIN; P(t); }
  { int p = -1; int t = p; t |= WINT_MIN; P(t); }
  { unsigned p = 0; P(WINT_MIN < p); }
  { unsigned p = 0; P(WINT_MIN > p); }
  { unsigned p = 0; P(WINT_MIN == p); }
  { unsigned p = 0; P(WINT_MIN != p); }
  { unsigned p = 0; P(WINT_MIN <= p); }
  { unsigned p = 0; P(WINT_MIN >= p); }
  { unsigned p = 0; P(p < WINT_MIN); }
  { unsigned p = 0; P(p > WINT_MIN); }
  { unsigned p = 0; P(p == WINT_MIN); }
  { unsigned p = 0; P(p <= WINT_MIN); }
  { unsigned p = 0; P(WINT_MIN + p); }
  { unsigned p = 0; P(p + WINT_MIN); }
  { unsigned p = 0; P(WINT_MIN - p); }
  { unsigned p = 0; P(p - WINT_MIN); }
  { unsigned p = 0; P(WINT_MIN * p); }
  { unsigned p = 0; P(p * WINT_MIN); }
  { unsigned p = 0; P(WINT_MIN & p); }
  { unsigned p = 0; P(WINT_MIN | p); }
  { unsigned p = 0; P(WINT_MIN ^ p); }
  { unsigned p = 0; P(p & WINT_MIN); }
  { unsigned p = 0; P(p | WINT_MIN); }
  { unsigned p = 0; P(1 ? WINT_MIN : p); }
  { unsigned p = 0; P(1 ? p : WINT_MIN); }
  { unsigned p = 0; P(0 ? WINT_MIN : p); }
  { unsigned p = 0; P(TC(WINT_MIN + p)); }
  { unsigned p = 0; P(TC(p + WINT_MIN)); }
  { unsigned p = 0; P(TC(1 ? WINT_MIN : p)); }
  { unsigned p = 0; P(sizeof(WINT_MIN + p)); }
  { unsigned p = 0; unsigned t = p; t += WINT_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t -= WINT_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t &= WINT_MIN; P(t); }
  { unsigned p = 0; unsigned t = p; t |= WINT_MIN; P(t); }
  { unsigned p = 1; P(WINT_MIN < p); }
  { unsigned p = 1; P(WINT_MIN > p); }
  { unsigned p = 1; P(WINT_MIN == p); }
  { unsigned p = 1; P(WINT_MIN != p); }
  { unsigned p = 1; P(WINT_MIN <= p); }
  { unsigned p = 1; P(WINT_MIN >= p); }
  { unsigned p = 1; P(p < WINT_MIN); }
  { unsigned p = 1; P(p > WINT_MIN); }
  { unsigned p = 1; P(p == WINT_MIN); }
  { unsigned p = 1; P(p <= WINT_MIN); }
  { unsigned p = 1; P(WINT_MIN + p); }
  { unsigned p = 1; P(p + WINT_MIN); }
  { unsigned p = 1; P(p - WINT_MIN); }
  { unsigned p = 1; P(WINT_MIN * p); }
  { unsigned p = 1; P(p * WINT_MIN); }
  { unsigned p = 1; P(WINT_MIN & p); }
  { unsigned p = 1; P(WINT_MIN | p); }
  { unsigned p = 1; P(WINT_MIN ^ p); }
  { unsigned p = 1; P(p & WINT_MIN); }
  { unsigned p = 1; P(p | WINT_MIN); }
  { unsigned p = 1; P(1 ? WINT_MIN : p); }
  { unsigned p = 1; P(1 ? p : WINT_MIN); }
  { unsigned p = 1; P(0 ? WINT_MIN : p); }
  { unsigned p = 1; P(TC(WINT_MIN + p)); }
  { unsigned p = 1; P(TC(p + WINT_MIN)); }
  { unsigned p = 1; P(TC(1 ? WINT_MIN : p)); }
  { unsigned p = 1; P(sizeof(WINT_MIN + p)); }
  { unsigned p = 1; P(WINT_MIN / p); }
  { unsigned p = 1; P(WINT_MIN % p); }
  { unsigned p = 1; unsigned t = p; t += WINT_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t -= WINT_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t &= WINT_MIN; P(t); }
  { unsigned p = 1; unsigned t = p; t |= WINT_MIN; P(t); }
  { unsigned p = -1; P(WINT_MIN < p); }
  { unsigned p = -1; P(WINT_MIN > p); }
  { unsigned p = -1; P(WINT_MIN == p); }
  { unsigned p = -1; P(WINT_MIN != p); }
  { unsigned p = -1; P(WINT_MIN <= p); }
  { unsigned p = -1; P(WINT_MIN >= p); }
  { unsigned p = -1; P(p < WINT_MIN); }
  { unsigned p = -1; P(p > WINT_MIN); }
  { unsigned p = -1; P(p == WINT_MIN); }
  { unsigned p = -1; P(p <= WINT_MIN); }
  { unsigned p = -1; P(WINT_MIN + p); }
  { unsigned p = -1; P(p + WINT_MIN); }
  { unsigned p = -1; P(p - WINT_MIN); }
  { unsigned p = -1; P(WINT_MIN * p); }
  { unsigned p = -1; P(p * WINT_MIN); }
  { unsigned p = -1; P(WINT_MIN & p); }
  { unsigned p = -1; P(WINT_MIN | p); }
  { unsigned p = -1; P(WINT_MIN ^ p); }
  { unsigned p = -1; P(p & WINT_MIN); }
  { unsigned p = -1; P(p | WINT_MIN); }
  { unsigned p = -1; P(1 ? WINT_MIN : p); }
  { unsigned p = -1; P(1 ? p : WINT_MIN); }
  { unsigned p = -1; P(0 ? WINT_MIN : p); }
  { unsigned p = -1; P(TC(WINT_MIN + p)); }
  { unsigned p = -1; P(TC(p + WINT_MIN)); }
  { unsigned p = -1; P(TC(1 ? WINT_MIN : p)); }
  { unsigned p = -1; P(sizeof(WINT_MIN + p)); }
  { unsigned p = -1; P(WINT_MIN / p); }
  { unsigned p = -1; P(WINT_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += WINT_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= WINT_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= WINT_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= WINT_MIN; P(t); }
  { long p = 0; P(WINT_MIN < p); }
  { long p = 0; P(WINT_MIN > p); }
  { long p = 0; P(WINT_MIN == p); }
  { long p = 0; P(WINT_MIN != p); }
  { long p = 0; P(WINT_MIN <= p); }
  { long p = 0; P(WINT_MIN >= p); }
  { long p = 0; P(p < WINT_MIN); }
  { long p = 0; P(p > WINT_MIN); }
  { long p = 0; P(p == WINT_MIN); }
  { long p = 0; P(p <= WINT_MIN); }
  { long p = 0; P(WINT_MIN + p); }
  { long p = 0; P(p + WINT_MIN); }
  { long p = 0; P(WINT_MIN - p); }
  { long p = 0; P(p - WINT_MIN); }
  { long p = 0; P(WINT_MIN * p); }
  { long p = 0; P(p * WINT_MIN); }
  { long p = 0; P(WINT_MIN & p); }
  { long p = 0; P(WINT_MIN | p); }
  { long p = 0; P(WINT_MIN ^ p); }
  { long p = 0; P(p & WINT_MIN); }
  { long p = 0; P(p | WINT_MIN); }
  { long p = 0; P(1 ? WINT_MIN : p); }
  { long p = 0; P(1 ? p : WINT_MIN); }
  { long p = 0; P(0 ? WINT_MIN : p); }
  { long p = 0; P(TC(WINT_MIN + p)); }
  { long p = 0; P(TC(p + WINT_MIN)); }
  { long p = 0; P(TC(1 ? WINT_MIN : p)); }
  { long p = 0; P(sizeof(WINT_MIN + p)); }
  { long p = 0; long t = p; t += WINT_MIN; P(t); }
  { long p = 0; long t = p; t -= WINT_MIN; P(t); }
  { long p = 0; long t = p; t &= WINT_MIN; P(t); }
  { long p = 0; long t = p; t |= WINT_MIN; P(t); }
  { long p = 1; P(WINT_MIN < p); }
  { long p = 1; P(WINT_MIN > p); }
  { long p = 1; P(WINT_MIN == p); }
  { long p = 1; P(WINT_MIN != p); }
  { long p = 1; P(WINT_MIN <= p); }
  { long p = 1; P(WINT_MIN >= p); }
  { long p = 1; P(p < WINT_MIN); }
  { long p = 1; P(p > WINT_MIN); }
  { long p = 1; P(p == WINT_MIN); }
  { long p = 1; P(p <= WINT_MIN); }
  { long p = 1; P(WINT_MIN + p); }
  { long p = 1; P(p + WINT_MIN); }
  { long p = 1; P(p - WINT_MIN); }
  { long p = 1; P(WINT_MIN * p); }
  { long p = 1; P(p * WINT_MIN); }
  { long p = 1; P(WINT_MIN & p); }
  { long p = 1; P(WINT_MIN | p); }
  { long p = 1; P(WINT_MIN ^ p); }
  { long p = 1; P(p & WINT_MIN); }
  { long p = 1; P(p | WINT_MIN); }
  { long p = 1; P(1 ? WINT_MIN : p); }
  { long p = 1; P(1 ? p : WINT_MIN); }
  { long p = 1; P(0 ? WINT_MIN : p); }
  { long p = 1; P(TC(WINT_MIN + p)); }
  { long p = 1; P(TC(p + WINT_MIN)); }
  { long p = 1; P(TC(1 ? WINT_MIN : p)); }
  { long p = 1; P(sizeof(WINT_MIN + p)); }
  { long p = 1; P(WINT_MIN / p); }
  { long p = 1; P(WINT_MIN % p); }
  { long p = 1; long t = p; t += WINT_MIN; P(t); }
  { long p = 1; long t = p; t -= WINT_MIN; P(t); }
  { long p = 1; long t = p; t &= WINT_MIN; P(t); }
  { long p = 1; long t = p; t |= WINT_MIN; P(t); }
  { long p = -1; P(WINT_MIN < p); }
  { long p = -1; P(WINT_MIN > p); }
  { long p = -1; P(WINT_MIN == p); }
  { long p = -1; P(WINT_MIN != p); }
  { long p = -1; P(WINT_MIN <= p); }
  { long p = -1; P(WINT_MIN >= p); }
  { long p = -1; P(p < WINT_MIN); }
  { long p = -1; P(p > WINT_MIN); }
  { long p = -1; P(p == WINT_MIN); }
  { long p = -1; P(p <= WINT_MIN); }
  { long p = -1; P(WINT_MIN + p); }
  { long p = -1; P(p + WINT_MIN); }
  { long p = -1; P(p - WINT_MIN); }
  { long p = -1; P(WINT_MIN * p); }
  { long p = -1; P(p * WINT_MIN); }
  { long p = -1; P(WINT_MIN & p); }
  { long p = -1; P(WINT_MIN | p); }
  { long p = -1; P(WINT_MIN ^ p); }
  { long p = -1; P(p & WINT_MIN); }
  { long p = -1; P(p | WINT_MIN); }
  { long p = -1; P(1 ? WINT_MIN : p); }
  { long p = -1; P(1 ? p : WINT_MIN); }
  { long p = -1; P(0 ? WINT_MIN : p); }
  { long p = -1; P(TC(WINT_MIN + p)); }
  { long p = -1; P(TC(p + WINT_MIN)); }
  { long p = -1; P(TC(1 ? WINT_MIN : p)); }
  { long p = -1; P(sizeof(WINT_MIN + p)); }
  { long p = -1; long t = p; t += WINT_MIN; P(t); }
  { long p = -1; long t = p; t -= WINT_MIN; P(t); }
  { long p = -1; long t = p; t &= WINT_MIN; P(t); }
  { long p = -1; long t = p; t |= WINT_MIN; P(t); }
  { unsigned long p = 0; P(WINT_MIN < p); }
  { unsigned long p = 0; P(WINT_MIN > p); }
  { unsigned long p = 0; P(WINT_MIN == p); }
  { unsigned long p = 0; P(WINT_MIN != p); }
  { unsigned long p = 0; P(WINT_MIN <= p); }
  { unsigned long p = 0; P(WINT_MIN >= p); }
  { unsigned long p = 0; P(p < WINT_MIN); }
  { unsigned long p = 0; P(p > WINT_MIN); }
  { unsigned long p = 0; P(p == WINT_MIN); }
  { unsigned long p = 0; P(p <= WINT_MIN); }
  { unsigned long p = 0; P(WINT_MIN + p); }
  { unsigned long p = 0; P(p + WINT_MIN); }
  { unsigned long p = 0; P(WINT_MIN - p); }
  { unsigned long p = 0; P(p - WINT_MIN); }
  { unsigned long p = 0; P(WINT_MIN * p); }
  { unsigned long p = 0; P(p * WINT_MIN); }
  { unsigned long p = 0; P(WINT_MIN & p); }
  { unsigned long p = 0; P(WINT_MIN | p); }
  { unsigned long p = 0; P(WINT_MIN ^ p); }
  { unsigned long p = 0; P(p & WINT_MIN); }
  { unsigned long p = 0; P(p | WINT_MIN); }
  { unsigned long p = 0; P(1 ? WINT_MIN : p); }
  { unsigned long p = 0; P(1 ? p : WINT_MIN); }
  { unsigned long p = 0; P(0 ? WINT_MIN : p); }
  { unsigned long p = 0; P(TC(WINT_MIN + p)); }
  { unsigned long p = 0; P(TC(p + WINT_MIN)); }
  { unsigned long p = 0; P(TC(1 ? WINT_MIN : p)); }
  { unsigned long p = 0; P(sizeof(WINT_MIN + p)); }
  { unsigned long p = 0; unsigned long t = p; t += WINT_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t -= WINT_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t &= WINT_MIN; P(t); }
  { unsigned long p = 0; unsigned long t = p; t |= WINT_MIN; P(t); }
  { unsigned long p = 1; P(WINT_MIN < p); }
  { unsigned long p = 1; P(WINT_MIN > p); }
  { unsigned long p = 1; P(WINT_MIN == p); }
  { unsigned long p = 1; P(WINT_MIN != p); }
  { unsigned long p = 1; P(WINT_MIN <= p); }
  { unsigned long p = 1; P(WINT_MIN >= p); }
  { unsigned long p = 1; P(p < WINT_MIN); }
  { unsigned long p = 1; P(p > WINT_MIN); }
  { unsigned long p = 1; P(p == WINT_MIN); }
  { unsigned long p = 1; P(p <= WINT_MIN); }
  { unsigned long p = 1; P(WINT_MIN + p); }
  { unsigned long p = 1; P(p + WINT_MIN); }
  { unsigned long p = 1; P(p - WINT_MIN); }
  { unsigned long p = 1; P(WINT_MIN * p); }
  { unsigned long p = 1; P(p * WINT_MIN); }
  { unsigned long p = 1; P(WINT_MIN & p); }
  { unsigned long p = 1; P(WINT_MIN | p); }
  { unsigned long p = 1; P(WINT_MIN ^ p); }
  { unsigned long p = 1; P(p & WINT_MIN); }
  { unsigned long p = 1; P(p | WINT_MIN); }
  { unsigned long p = 1; P(1 ? WINT_MIN : p); }
  { unsigned long p = 1; P(1 ? p : WINT_MIN); }
  { unsigned long p = 1; P(0 ? WINT_MIN : p); }
  { unsigned long p = 1; P(TC(WINT_MIN + p)); }
  { unsigned long p = 1; P(TC(p + WINT_MIN)); }
  { unsigned long p = 1; P(TC(1 ? WINT_MIN : p)); }
  { unsigned long p = 1; P(sizeof(WINT_MIN + p)); }
  { unsigned long p = 1; P(WINT_MIN / p); }
  { unsigned long p = 1; P(WINT_MIN % p); }
  { unsigned long p = 1; unsigned long t = p; t += WINT_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t -= WINT_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t &= WINT_MIN; P(t); }
  { unsigned long p = 1; unsigned long t = p; t |= WINT_MIN; P(t); }
  { unsigned long p = -1; P(WINT_MIN < p); }
  { unsigned long p = -1; P(WINT_MIN > p); }
  { unsigned long p = -1; P(WINT_MIN == p); }
  { unsigned long p = -1; P(WINT_MIN != p); }
  { unsigned long p = -1; P(WINT_MIN <= p); }
  { unsigned long p = -1; P(WINT_MIN >= p); }
  { unsigned long p = -1; P(p < WINT_MIN); }
  { unsigned long p = -1; P(p > WINT_MIN); }
  { unsigned long p = -1; P(p == WINT_MIN); }
  { unsigned long p = -1; P(p <= WINT_MIN); }
  { unsigned long p = -1; P(WINT_MIN + p); }
  { unsigned long p = -1; P(p + WINT_MIN); }
  { unsigned long p = -1; P(p - WINT_MIN); }
  { unsigned long p = -1; P(WINT_MIN * p); }
  { unsigned long p = -1; P(p * WINT_MIN); }
  { unsigned long p = -1; P(WINT_MIN & p); }
  { unsigned long p = -1; P(WINT_MIN | p); }
  { unsigned long p = -1; P(WINT_MIN ^ p); }
  { unsigned long p = -1; P(p & WINT_MIN); }
  { unsigned long p = -1; P(p | WINT_MIN); }
  { unsigned long p = -1; P(1 ? WINT_MIN : p); }
  { unsigned long p = -1; P(1 ? p : WINT_MIN); }
  { unsigned long p = -1; P(0 ? WINT_MIN : p); }
  { unsigned long p = -1; P(TC(WINT_MIN + p)); }
  { unsigned long p = -1; P(TC(p + WINT_MIN)); }
  { unsigned long p = -1; P(TC(1 ? WINT_MIN : p)); }
  { unsigned long p = -1; P(sizeof(WINT_MIN + p)); }
  { unsigned long p = -1; P(WINT_MIN / p); }
  { unsigned long p = -1; P(WINT_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += WINT_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= WINT_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= WINT_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= WINT_MIN; P(t); }
  printf("\n");
  return 0;
}
