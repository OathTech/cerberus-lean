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
#undef INT64_MAX
#define INT64_MAX LLONG_MAX
#undef INT64_MIN
#define INT64_MIN LLONG_MIN
#undef INT8_MAX
#define INT8_MAX SCHAR_MAX
#undef INT8_MIN
#define INT8_MIN SCHAR_MIN
#endif
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(sizeof(+INT64_MAX));
  P(TC(INT64_MAX));
  P(TC(+INT64_MAX));
  P(TC(-INT64_MAX));
  P(TC(~INT64_MAX));
  P((_Bool)INT64_MAX);
  P((signed char)INT64_MAX);
  P((unsigned char)INT64_MAX);
  P((short)INT64_MAX);
  P((unsigned short)INT64_MAX);
  P((int)INT64_MAX);
  P((unsigned)INT64_MAX);
  P((long)INT64_MAX);
  P((unsigned long)INT64_MAX);
  P((long long)INT64_MAX);
  P((unsigned long long)INT64_MAX);
  P((long long)INT64_MAX > 0);
  P((long long)INT64_MAX < 0);
  { int x = INT64_MAX; P(x); }
  { unsigned x = INT64_MAX; P(x); }
  { long x = INT64_MAX; P(x); }
  { unsigned long x = INT64_MAX; P(x); }
  P(INT64_MAX - 1);
  P(INT64_MAX - 1 > 0);
  P(INT64_MAX - 1u);
  P(INT64_MAX - 1ul);
  { int p = -1; P(INT64_MAX < p); }
  { int p = -1; P(INT64_MAX > p); }
  { int p = -1; P(INT64_MAX == p); }
  { int p = -1; P(INT64_MAX != p); }
  { int p = -1; P(INT64_MAX <= p); }
  { int p = -1; P(INT64_MAX >= p); }
  { int p = -1; P(p < INT64_MAX); }
  { int p = -1; P(p > INT64_MAX); }
  { int p = -1; P(p == INT64_MAX); }
  { int p = -1; P(p <= INT64_MAX); }
  { int p = -1; P(INT64_MAX + p); }
  { int p = -1; P(p + INT64_MAX); }
  { int p = -1; P(p - INT64_MAX); }
  { int p = -1; P(INT64_MAX * p); }
  { int p = -1; P(p * INT64_MAX); }
  { int p = -1; P(INT64_MAX & p); }
  { int p = -1; P(INT64_MAX | p); }
  { int p = -1; P(INT64_MAX ^ p); }
  { int p = -1; P(p & INT64_MAX); }
  { int p = -1; P(p | INT64_MAX); }
  { int p = -1; P(1 ? INT64_MAX : p); }
  { int p = -1; P(1 ? p : INT64_MAX); }
  { int p = -1; P(0 ? INT64_MAX : p); }
  { int p = -1; P(TC(INT64_MAX + p)); }
  { int p = -1; P(TC(p + INT64_MAX)); }
  { int p = -1; P(TC(1 ? INT64_MAX : p)); }
  { int p = -1; P(sizeof(INT64_MAX + p)); }
  { int p = -1; int t = p; t += INT64_MAX; P(t); }
  { int p = -1; int t = p; t -= INT64_MAX; P(t); }
  { int p = -1; int t = p; t &= INT64_MAX; P(t); }
  { int p = -1; int t = p; t |= INT64_MAX; P(t); }
  { unsigned p = -1; P(INT64_MAX < p); }
  { unsigned p = -1; P(INT64_MAX > p); }
  { unsigned p = -1; P(INT64_MAX == p); }
  { unsigned p = -1; P(INT64_MAX != p); }
  { unsigned p = -1; P(INT64_MAX <= p); }
  { unsigned p = -1; P(INT64_MAX >= p); }
  { unsigned p = -1; P(p < INT64_MAX); }
  { unsigned p = -1; P(p > INT64_MAX); }
  { unsigned p = -1; P(p == INT64_MAX); }
  { unsigned p = -1; P(p <= INT64_MAX); }
  { unsigned p = -1; P(INT64_MAX - p); }
  { unsigned p = -1; P(p - INT64_MAX); }
  { unsigned p = -1; P(INT64_MAX & p); }
  { unsigned p = -1; P(INT64_MAX | p); }
  { unsigned p = -1; P(INT64_MAX ^ p); }
  { unsigned p = -1; P(p & INT64_MAX); }
  { unsigned p = -1; P(p | INT64_MAX); }
  { unsigned p = -1; P(1 ? INT64_MAX : p); }
  { unsigned p = -1; P(1 ? p : INT64_MAX); }
  { unsigned p = -1; P(0 ? INT64_MAX : p); }
  { unsigned p = -1; P(TC(INT64_MAX + p)); }
  { unsigned p = -1; P(TC(p + INT64_MAX)); }
  { unsigned p = -1; P(TC(1 ? INT64_MAX : p)); }
  { unsigned p = -1; P(sizeof(INT64_MAX + p)); }
  { unsigned p = -1; P(INT64_MAX / p); }
  { unsigned p = -1; P(INT64_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= INT64_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT64_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT64_MAX; P(t); }
  { long p = -1; P(INT64_MAX < p); }
  { long p = -1; P(INT64_MAX > p); }
  { long p = -1; P(INT64_MAX == p); }
  { long p = -1; P(INT64_MAX != p); }
  { long p = -1; P(INT64_MAX <= p); }
  { long p = -1; P(INT64_MAX >= p); }
  { long p = -1; P(p < INT64_MAX); }
  { long p = -1; P(p > INT64_MAX); }
  { long p = -1; P(p == INT64_MAX); }
  { long p = -1; P(p <= INT64_MAX); }
  { long p = -1; P(INT64_MAX + p); }
  { long p = -1; P(p + INT64_MAX); }
  { long p = -1; P(p - INT64_MAX); }
  { long p = -1; P(INT64_MAX * p); }
  { long p = -1; P(p * INT64_MAX); }
  { long p = -1; P(INT64_MAX & p); }
  { long p = -1; P(INT64_MAX | p); }
  { long p = -1; P(INT64_MAX ^ p); }
  { long p = -1; P(p & INT64_MAX); }
  { long p = -1; P(p | INT64_MAX); }
  { long p = -1; P(1 ? INT64_MAX : p); }
  { long p = -1; P(1 ? p : INT64_MAX); }
  { long p = -1; P(0 ? INT64_MAX : p); }
  { long p = -1; P(TC(INT64_MAX + p)); }
  { long p = -1; P(TC(p + INT64_MAX)); }
  { long p = -1; P(TC(1 ? INT64_MAX : p)); }
  { long p = -1; P(sizeof(INT64_MAX + p)); }
  { long p = -1; long t = p; t += INT64_MAX; P(t); }
  { long p = -1; long t = p; t -= INT64_MAX; P(t); }
  { long p = -1; long t = p; t &= INT64_MAX; P(t); }
  { long p = -1; long t = p; t |= INT64_MAX; P(t); }
  { unsigned long p = -1; P(INT64_MAX < p); }
  { unsigned long p = -1; P(INT64_MAX > p); }
  { unsigned long p = -1; P(INT64_MAX == p); }
  { unsigned long p = -1; P(INT64_MAX != p); }
  { unsigned long p = -1; P(INT64_MAX <= p); }
  { unsigned long p = -1; P(INT64_MAX >= p); }
  { unsigned long p = -1; P(p < INT64_MAX); }
  { unsigned long p = -1; P(p > INT64_MAX); }
  { unsigned long p = -1; P(p == INT64_MAX); }
  { unsigned long p = -1; P(p <= INT64_MAX); }
  { unsigned long p = -1; P(INT64_MAX + p); }
  { unsigned long p = -1; P(p + INT64_MAX); }
  { unsigned long p = -1; P(INT64_MAX - p); }
  { unsigned long p = -1; P(p - INT64_MAX); }
  { unsigned long p = -1; P(INT64_MAX * p); }
  { unsigned long p = -1; P(p * INT64_MAX); }
  { unsigned long p = -1; P(INT64_MAX & p); }
  { unsigned long p = -1; P(INT64_MAX | p); }
  { unsigned long p = -1; P(INT64_MAX ^ p); }
  { unsigned long p = -1; P(p & INT64_MAX); }
  { unsigned long p = -1; P(p | INT64_MAX); }
  { unsigned long p = -1; P(1 ? INT64_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INT64_MAX); }
  { unsigned long p = -1; P(0 ? INT64_MAX : p); }
  { unsigned long p = -1; P(TC(INT64_MAX + p)); }
  { unsigned long p = -1; P(TC(p + INT64_MAX)); }
  { unsigned long p = -1; P(TC(1 ? INT64_MAX : p)); }
  { unsigned long p = -1; P(sizeof(INT64_MAX + p)); }
  { unsigned long p = -1; P(INT64_MAX / p); }
  { unsigned long p = -1; P(INT64_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT64_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT64_MAX; P(t); }
  P(INT64_MIN > 0);
  P(INT64_MIN < 0);
  P(INT64_MIN == 0);
  P(INT64_MIN != 0);
  P(INT64_MIN >= 0);
  P(INT64_MIN <= 0);
  P(0 < INT64_MIN);
  P(0 > INT64_MIN);
  P(0 == INT64_MIN);
  P(+INT64_MIN);
  P(~INT64_MIN);
  P(!INT64_MIN);
  P((+INT64_MIN) > 0);
  P(sizeof(INT64_MIN));
  P(sizeof(+INT64_MIN));
  P(TC(INT64_MIN));
  P(TC(+INT64_MIN));
  P(TC(-INT64_MIN));
  P(TC(~INT64_MIN));
  P((_Bool)INT64_MIN);
  P((signed char)INT64_MIN);
  P((unsigned char)INT64_MIN);
  P((short)INT64_MIN);
  P((unsigned short)INT64_MIN);
  P((int)INT64_MIN);
  P((unsigned)INT64_MIN);
  P((long)INT64_MIN);
  P((unsigned long)INT64_MIN);
  P((long long)INT64_MIN);
  P((unsigned long long)INT64_MIN);
  P((long long)INT64_MIN > 0);
  P((long long)INT64_MIN < 0);
  { int x = INT64_MIN; P(x); }
  { unsigned x = INT64_MIN; P(x); }
  { long x = INT64_MIN; P(x); }
  { unsigned long x = INT64_MIN; P(x); }
  P(INT64_MIN + 1);
  P(INT64_MIN + 1 > 0);
  P(INT64_MIN + 1u);
  P(INT64_MIN + 1l);
  P(INT64_MIN - 1ul);
  { int p = -1; P(INT64_MIN < p); }
  { int p = -1; P(INT64_MIN > p); }
  { int p = -1; P(INT64_MIN == p); }
  { int p = -1; P(INT64_MIN != p); }
  { int p = -1; P(INT64_MIN <= p); }
  { int p = -1; P(INT64_MIN >= p); }
  { int p = -1; P(p < INT64_MIN); }
  { int p = -1; P(p > INT64_MIN); }
  { int p = -1; P(p == INT64_MIN); }
  { int p = -1; P(p <= INT64_MIN); }
  { int p = -1; P(INT64_MIN - p); }
  { int p = -1; P(p - INT64_MIN); }
  { int p = -1; P(INT64_MIN & p); }
  { int p = -1; P(INT64_MIN | p); }
  { int p = -1; P(INT64_MIN ^ p); }
  { int p = -1; P(p & INT64_MIN); }
  { int p = -1; P(p | INT64_MIN); }
  { int p = -1; P(1 ? INT64_MIN : p); }
  { int p = -1; P(1 ? p : INT64_MIN); }
  { int p = -1; P(0 ? INT64_MIN : p); }
  { int p = -1; P(TC(INT64_MIN + p)); }
  { int p = -1; P(TC(p + INT64_MIN)); }
  { int p = -1; P(TC(1 ? INT64_MIN : p)); }
  { int p = -1; P(sizeof(INT64_MIN + p)); }
  { int p = -1; int t = p; t -= INT64_MIN; P(t); }
  { int p = -1; int t = p; t &= INT64_MIN; P(t); }
  { int p = -1; int t = p; t |= INT64_MIN; P(t); }
  { unsigned p = -1; P(INT64_MIN < p); }
  { unsigned p = -1; P(INT64_MIN > p); }
  { unsigned p = -1; P(INT64_MIN == p); }
  { unsigned p = -1; P(INT64_MIN != p); }
  { unsigned p = -1; P(INT64_MIN <= p); }
  { unsigned p = -1; P(INT64_MIN >= p); }
  { unsigned p = -1; P(p < INT64_MIN); }
  { unsigned p = -1; P(p > INT64_MIN); }
  { unsigned p = -1; P(p == INT64_MIN); }
  { unsigned p = -1; P(p <= INT64_MIN); }
  { unsigned p = -1; P(INT64_MIN + p); }
  { unsigned p = -1; P(p + INT64_MIN); }
  { unsigned p = -1; P(INT64_MIN & p); }
  { unsigned p = -1; P(INT64_MIN | p); }
  { unsigned p = -1; P(INT64_MIN ^ p); }
  { unsigned p = -1; P(p & INT64_MIN); }
  { unsigned p = -1; P(p | INT64_MIN); }
  { unsigned p = -1; P(1 ? INT64_MIN : p); }
  { unsigned p = -1; P(1 ? p : INT64_MIN); }
  { unsigned p = -1; P(0 ? INT64_MIN : p); }
  { unsigned p = -1; P(TC(INT64_MIN + p)); }
  { unsigned p = -1; P(TC(p + INT64_MIN)); }
  { unsigned p = -1; P(TC(1 ? INT64_MIN : p)); }
  { unsigned p = -1; P(sizeof(INT64_MIN + p)); }
  { unsigned p = -1; P(INT64_MIN / p); }
  { unsigned p = -1; P(INT64_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INT64_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT64_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT64_MIN; P(t); }
  { long p = -1; P(INT64_MIN < p); }
  { long p = -1; P(INT64_MIN > p); }
  { long p = -1; P(INT64_MIN == p); }
  { long p = -1; P(INT64_MIN != p); }
  { long p = -1; P(INT64_MIN <= p); }
  { long p = -1; P(INT64_MIN >= p); }
  { long p = -1; P(p < INT64_MIN); }
  { long p = -1; P(p > INT64_MIN); }
  { long p = -1; P(p == INT64_MIN); }
  { long p = -1; P(p <= INT64_MIN); }
  { long p = -1; P(INT64_MIN - p); }
  { long p = -1; P(p - INT64_MIN); }
  { long p = -1; P(INT64_MIN & p); }
  { long p = -1; P(INT64_MIN | p); }
  { long p = -1; P(INT64_MIN ^ p); }
  { long p = -1; P(p & INT64_MIN); }
  { long p = -1; P(p | INT64_MIN); }
  { long p = -1; P(1 ? INT64_MIN : p); }
  { long p = -1; P(1 ? p : INT64_MIN); }
  { long p = -1; P(0 ? INT64_MIN : p); }
  { long p = -1; P(TC(INT64_MIN + p)); }
  { long p = -1; P(TC(p + INT64_MIN)); }
  { long p = -1; P(TC(1 ? INT64_MIN : p)); }
  { long p = -1; P(sizeof(INT64_MIN + p)); }
  { long p = -1; long t = p; t -= INT64_MIN; P(t); }
  { long p = -1; long t = p; t &= INT64_MIN; P(t); }
  { long p = -1; long t = p; t |= INT64_MIN; P(t); }
  { unsigned long p = -1; P(INT64_MIN < p); }
  { unsigned long p = -1; P(INT64_MIN > p); }
  { unsigned long p = -1; P(INT64_MIN == p); }
  { unsigned long p = -1; P(INT64_MIN != p); }
  { unsigned long p = -1; P(INT64_MIN <= p); }
  { unsigned long p = -1; P(INT64_MIN >= p); }
  { unsigned long p = -1; P(p < INT64_MIN); }
  { unsigned long p = -1; P(p > INT64_MIN); }
  { unsigned long p = -1; P(p == INT64_MIN); }
  { unsigned long p = -1; P(p <= INT64_MIN); }
  { unsigned long p = -1; P(INT64_MIN + p); }
  { unsigned long p = -1; P(p + INT64_MIN); }
  { unsigned long p = -1; P(INT64_MIN - p); }
  { unsigned long p = -1; P(p - INT64_MIN); }
  { unsigned long p = -1; P(INT64_MIN * p); }
  { unsigned long p = -1; P(p * INT64_MIN); }
  { unsigned long p = -1; P(INT64_MIN & p); }
  { unsigned long p = -1; P(INT64_MIN | p); }
  { unsigned long p = -1; P(INT64_MIN ^ p); }
  { unsigned long p = -1; P(p & INT64_MIN); }
  { unsigned long p = -1; P(p | INT64_MIN); }
  { unsigned long p = -1; P(1 ? INT64_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INT64_MIN); }
  { unsigned long p = -1; P(0 ? INT64_MIN : p); }
  { unsigned long p = -1; P(TC(INT64_MIN + p)); }
  { unsigned long p = -1; P(TC(p + INT64_MIN)); }
  { unsigned long p = -1; P(TC(1 ? INT64_MIN : p)); }
  { unsigned long p = -1; P(sizeof(INT64_MIN + p)); }
  { unsigned long p = -1; P(INT64_MIN / p); }
  { unsigned long p = -1; P(INT64_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT64_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT64_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT64_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT64_MIN; P(t); }
  P(INT8_MAX > 0);
  P(INT8_MAX < 0);
  P(INT8_MAX == 0);
  P(INT8_MAX != 0);
  P(INT8_MAX >= 0);
  P(INT8_MAX <= 0);
  P(0 < INT8_MAX);
  P(0 > INT8_MAX);
  P(0 == INT8_MAX);
  P(+INT8_MAX);
  P(-INT8_MAX);
  P(~INT8_MAX);
  P(!INT8_MAX);
  P((+INT8_MAX) > 0);
  P(sizeof(+INT8_MAX));
  P(TC(+INT8_MAX));
  P(TC(-INT8_MAX));
  P(TC(~INT8_MAX));
  P((_Bool)INT8_MAX);
  P((signed char)INT8_MAX);
  P((unsigned char)INT8_MAX);
  P((short)INT8_MAX);
  P((unsigned short)INT8_MAX);
  P((int)INT8_MAX);
  P((unsigned)INT8_MAX);
  P((long)INT8_MAX);
  P((unsigned long)INT8_MAX);
  P((long long)INT8_MAX);
  P((unsigned long long)INT8_MAX);
  P((long long)INT8_MAX > 0);
  P((long long)INT8_MAX < 0);
  { int x = INT8_MAX; P(x); }
  { unsigned x = INT8_MAX; P(x); }
  { long x = INT8_MAX; P(x); }
  { unsigned long x = INT8_MAX; P(x); }
  P(INT8_MAX + 1);
  P(INT8_MAX - 1);
  P(INT8_MAX - 1 > 0);
  P(INT8_MAX + 1 > 0);
  P(INT8_MAX + 1u);
  P(INT8_MAX - 1u);
  P(INT8_MAX + 1l);
  P(INT8_MAX - 1ul);
  { int p = -1; P(INT8_MAX < p); }
  { int p = -1; P(INT8_MAX > p); }
  { int p = -1; P(INT8_MAX == p); }
  { int p = -1; P(INT8_MAX != p); }
  { int p = -1; P(INT8_MAX <= p); }
  { int p = -1; P(INT8_MAX >= p); }
  { int p = -1; P(p < INT8_MAX); }
  { int p = -1; P(p > INT8_MAX); }
  { int p = -1; P(p == INT8_MAX); }
  { int p = -1; P(p <= INT8_MAX); }
  { int p = -1; P(INT8_MAX + p); }
  { int p = -1; P(p + INT8_MAX); }
  { int p = -1; P(INT8_MAX - p); }
  { int p = -1; P(p - INT8_MAX); }
  { int p = -1; P(INT8_MAX * p); }
  { int p = -1; P(p * INT8_MAX); }
  { int p = -1; P(INT8_MAX & p); }
  { int p = -1; P(INT8_MAX | p); }
  { int p = -1; P(INT8_MAX ^ p); }
  { int p = -1; P(p & INT8_MAX); }
  { int p = -1; P(p | INT8_MAX); }
  { int p = -1; P(1 ? INT8_MAX : p); }
  { int p = -1; P(1 ? p : INT8_MAX); }
  { int p = -1; P(0 ? INT8_MAX : p); }
  { int p = -1; P(TC(INT8_MAX + p)); }
  { int p = -1; P(TC(p + INT8_MAX)); }
  { int p = -1; P(TC(1 ? INT8_MAX : p)); }
  { int p = -1; P(sizeof(INT8_MAX + p)); }
  { int p = -1; int t = p; t += INT8_MAX; P(t); }
  { int p = -1; int t = p; t -= INT8_MAX; P(t); }
  { int p = -1; int t = p; t &= INT8_MAX; P(t); }
  { int p = -1; int t = p; t |= INT8_MAX; P(t); }
  { unsigned p = -1; P(INT8_MAX < p); }
  { unsigned p = -1; P(INT8_MAX > p); }
  { unsigned p = -1; P(INT8_MAX == p); }
  { unsigned p = -1; P(INT8_MAX != p); }
  { unsigned p = -1; P(INT8_MAX <= p); }
  { unsigned p = -1; P(INT8_MAX >= p); }
  { unsigned p = -1; P(p < INT8_MAX); }
  { unsigned p = -1; P(p > INT8_MAX); }
  { unsigned p = -1; P(p == INT8_MAX); }
  { unsigned p = -1; P(p <= INT8_MAX); }
  { unsigned p = -1; P(INT8_MAX + p); }
  { unsigned p = -1; P(p + INT8_MAX); }
  { unsigned p = -1; P(INT8_MAX - p); }
  { unsigned p = -1; P(p - INT8_MAX); }
  { unsigned p = -1; P(INT8_MAX * p); }
  { unsigned p = -1; P(p * INT8_MAX); }
  { unsigned p = -1; P(INT8_MAX & p); }
  { unsigned p = -1; P(INT8_MAX | p); }
  { unsigned p = -1; P(INT8_MAX ^ p); }
  { unsigned p = -1; P(p & INT8_MAX); }
  { unsigned p = -1; P(p | INT8_MAX); }
  { unsigned p = -1; P(1 ? INT8_MAX : p); }
  { unsigned p = -1; P(1 ? p : INT8_MAX); }
  { unsigned p = -1; P(0 ? INT8_MAX : p); }
  { unsigned p = -1; P(TC(INT8_MAX + p)); }
  { unsigned p = -1; P(TC(p + INT8_MAX)); }
  { unsigned p = -1; P(TC(1 ? INT8_MAX : p)); }
  { unsigned p = -1; P(sizeof(INT8_MAX + p)); }
  { unsigned p = -1; P(INT8_MAX / p); }
  { unsigned p = -1; P(INT8_MAX % p); }
  { unsigned p = -1; unsigned t = p; t += INT8_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT8_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT8_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT8_MAX; P(t); }
  { long p = -1; P(INT8_MAX < p); }
  { long p = -1; P(INT8_MAX > p); }
  { long p = -1; P(INT8_MAX == p); }
  { long p = -1; P(INT8_MAX != p); }
  { long p = -1; P(INT8_MAX <= p); }
  { long p = -1; P(INT8_MAX >= p); }
  { long p = -1; P(p < INT8_MAX); }
  { long p = -1; P(p > INT8_MAX); }
  { long p = -1; P(p == INT8_MAX); }
  { long p = -1; P(p <= INT8_MAX); }
  { long p = -1; P(INT8_MAX + p); }
  { long p = -1; P(p + INT8_MAX); }
  { long p = -1; P(INT8_MAX - p); }
  { long p = -1; P(p - INT8_MAX); }
  { long p = -1; P(INT8_MAX * p); }
  { long p = -1; P(p * INT8_MAX); }
  { long p = -1; P(INT8_MAX & p); }
  { long p = -1; P(INT8_MAX | p); }
  { long p = -1; P(INT8_MAX ^ p); }
  { long p = -1; P(p & INT8_MAX); }
  { long p = -1; P(p | INT8_MAX); }
  { long p = -1; P(1 ? INT8_MAX : p); }
  { long p = -1; P(1 ? p : INT8_MAX); }
  { long p = -1; P(0 ? INT8_MAX : p); }
  { long p = -1; P(TC(INT8_MAX + p)); }
  { long p = -1; P(TC(p + INT8_MAX)); }
  { long p = -1; P(TC(1 ? INT8_MAX : p)); }
  { long p = -1; P(sizeof(INT8_MAX + p)); }
  { long p = -1; long t = p; t += INT8_MAX; P(t); }
  { long p = -1; long t = p; t -= INT8_MAX; P(t); }
  { long p = -1; long t = p; t &= INT8_MAX; P(t); }
  { long p = -1; long t = p; t |= INT8_MAX; P(t); }
  { unsigned long p = -1; P(INT8_MAX < p); }
  { unsigned long p = -1; P(INT8_MAX > p); }
  { unsigned long p = -1; P(INT8_MAX == p); }
  { unsigned long p = -1; P(INT8_MAX != p); }
  { unsigned long p = -1; P(INT8_MAX <= p); }
  { unsigned long p = -1; P(INT8_MAX >= p); }
  { unsigned long p = -1; P(p < INT8_MAX); }
  { unsigned long p = -1; P(p > INT8_MAX); }
  { unsigned long p = -1; P(p == INT8_MAX); }
  { unsigned long p = -1; P(p <= INT8_MAX); }
  { unsigned long p = -1; P(INT8_MAX + p); }
  { unsigned long p = -1; P(p + INT8_MAX); }
  { unsigned long p = -1; P(INT8_MAX - p); }
  { unsigned long p = -1; P(p - INT8_MAX); }
  { unsigned long p = -1; P(INT8_MAX * p); }
  { unsigned long p = -1; P(p * INT8_MAX); }
  { unsigned long p = -1; P(INT8_MAX & p); }
  { unsigned long p = -1; P(INT8_MAX | p); }
  { unsigned long p = -1; P(INT8_MAX ^ p); }
  { unsigned long p = -1; P(p & INT8_MAX); }
  { unsigned long p = -1; P(p | INT8_MAX); }
  { unsigned long p = -1; P(1 ? INT8_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INT8_MAX); }
  { unsigned long p = -1; P(0 ? INT8_MAX : p); }
  { unsigned long p = -1; P(TC(INT8_MAX + p)); }
  { unsigned long p = -1; P(TC(p + INT8_MAX)); }
  { unsigned long p = -1; P(TC(1 ? INT8_MAX : p)); }
  { unsigned long p = -1; P(sizeof(INT8_MAX + p)); }
  { unsigned long p = -1; P(INT8_MAX / p); }
  { unsigned long p = -1; P(INT8_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT8_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT8_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT8_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT8_MAX; P(t); }
  P(INT8_MIN > 0);
  P(INT8_MIN < 0);
  P(INT8_MIN == 0);
  P(INT8_MIN != 0);
  P(INT8_MIN >= 0);
  P(INT8_MIN <= 0);
  P(0 < INT8_MIN);
  P(0 > INT8_MIN);
  P(0 == INT8_MIN);
  P(+INT8_MIN);
  P(-INT8_MIN);
  P(~INT8_MIN);
  P(!INT8_MIN);
  P((+INT8_MIN) > 0);
  P(sizeof(+INT8_MIN));
  P(TC(+INT8_MIN));
  P(TC(-INT8_MIN));
  P(TC(~INT8_MIN));
  P((_Bool)INT8_MIN);
  P((signed char)INT8_MIN);
  P((unsigned char)INT8_MIN);
  P((short)INT8_MIN);
  P((unsigned short)INT8_MIN);
  P((int)INT8_MIN);
  P((unsigned)INT8_MIN);
  P((long)INT8_MIN);
  P((unsigned long)INT8_MIN);
  P((long long)INT8_MIN);
  P((unsigned long long)INT8_MIN);
  P((long long)INT8_MIN > 0);
  P((long long)INT8_MIN < 0);
  { int x = INT8_MIN; P(x); }
  { unsigned x = INT8_MIN; P(x); }
  { long x = INT8_MIN; P(x); }
  { unsigned long x = INT8_MIN; P(x); }
  P(INT8_MIN + 1);
  P(INT8_MIN - 1);
  P(INT8_MIN - 1 > 0);
  P(INT8_MIN + 1 > 0);
  P(INT8_MIN + 1u);
  P(INT8_MIN - 1u);
  P(INT8_MIN + 1l);
  P(INT8_MIN - 1ul);
  { int p = -1; P(INT8_MIN < p); }
  { int p = -1; P(INT8_MIN > p); }
  { int p = -1; P(INT8_MIN == p); }
  { int p = -1; P(INT8_MIN != p); }
  { int p = -1; P(INT8_MIN <= p); }
  { int p = -1; P(INT8_MIN >= p); }
  { int p = -1; P(p < INT8_MIN); }
  { int p = -1; P(p > INT8_MIN); }
  { int p = -1; P(p == INT8_MIN); }
  { int p = -1; P(p <= INT8_MIN); }
  { int p = -1; P(INT8_MIN + p); }
  { int p = -1; P(p + INT8_MIN); }
  { int p = -1; P(INT8_MIN - p); }
  { int p = -1; P(p - INT8_MIN); }
  { int p = -1; P(INT8_MIN * p); }
  { int p = -1; P(p * INT8_MIN); }
  { int p = -1; P(INT8_MIN & p); }
  { int p = -1; P(INT8_MIN | p); }
  { int p = -1; P(INT8_MIN ^ p); }
  { int p = -1; P(p & INT8_MIN); }
  { int p = -1; P(p | INT8_MIN); }
  { int p = -1; P(1 ? INT8_MIN : p); }
  { int p = -1; P(1 ? p : INT8_MIN); }
  { int p = -1; P(0 ? INT8_MIN : p); }
  { int p = -1; P(TC(INT8_MIN + p)); }
  { int p = -1; P(TC(p + INT8_MIN)); }
  { int p = -1; P(TC(1 ? INT8_MIN : p)); }
  { int p = -1; P(sizeof(INT8_MIN + p)); }
  { int p = -1; int t = p; t += INT8_MIN; P(t); }
  { int p = -1; int t = p; t -= INT8_MIN; P(t); }
  { int p = -1; int t = p; t &= INT8_MIN; P(t); }
  { int p = -1; int t = p; t |= INT8_MIN; P(t); }
  { unsigned p = -1; P(INT8_MIN < p); }
  { unsigned p = -1; P(INT8_MIN > p); }
  { unsigned p = -1; P(INT8_MIN == p); }
  { unsigned p = -1; P(INT8_MIN != p); }
  { unsigned p = -1; P(INT8_MIN <= p); }
  { unsigned p = -1; P(INT8_MIN >= p); }
  { unsigned p = -1; P(p < INT8_MIN); }
  { unsigned p = -1; P(p > INT8_MIN); }
  { unsigned p = -1; P(p == INT8_MIN); }
  { unsigned p = -1; P(p <= INT8_MIN); }
  { unsigned p = -1; P(INT8_MIN + p); }
  { unsigned p = -1; P(p + INT8_MIN); }
  { unsigned p = -1; P(INT8_MIN - p); }
  { unsigned p = -1; P(p - INT8_MIN); }
  { unsigned p = -1; P(INT8_MIN * p); }
  { unsigned p = -1; P(p * INT8_MIN); }
  { unsigned p = -1; P(INT8_MIN & p); }
  { unsigned p = -1; P(INT8_MIN | p); }
  { unsigned p = -1; P(INT8_MIN ^ p); }
  { unsigned p = -1; P(p & INT8_MIN); }
  { unsigned p = -1; P(p | INT8_MIN); }
  { unsigned p = -1; P(1 ? INT8_MIN : p); }
  { unsigned p = -1; P(1 ? p : INT8_MIN); }
  { unsigned p = -1; P(0 ? INT8_MIN : p); }
  { unsigned p = -1; P(TC(INT8_MIN + p)); }
  { unsigned p = -1; P(TC(p + INT8_MIN)); }
  { unsigned p = -1; P(TC(1 ? INT8_MIN : p)); }
  { unsigned p = -1; P(sizeof(INT8_MIN + p)); }
  { unsigned p = -1; P(INT8_MIN / p); }
  { unsigned p = -1; P(INT8_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INT8_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t -= INT8_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INT8_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INT8_MIN; P(t); }
  { long p = -1; P(INT8_MIN < p); }
  { long p = -1; P(INT8_MIN > p); }
  { long p = -1; P(INT8_MIN == p); }
  { long p = -1; P(INT8_MIN != p); }
  { long p = -1; P(INT8_MIN <= p); }
  { long p = -1; P(INT8_MIN >= p); }
  { long p = -1; P(p < INT8_MIN); }
  { long p = -1; P(p > INT8_MIN); }
  { long p = -1; P(p == INT8_MIN); }
  { long p = -1; P(p <= INT8_MIN); }
  { long p = -1; P(INT8_MIN + p); }
  { long p = -1; P(p + INT8_MIN); }
  { long p = -1; P(INT8_MIN - p); }
  { long p = -1; P(p - INT8_MIN); }
  { long p = -1; P(INT8_MIN * p); }
  { long p = -1; P(p * INT8_MIN); }
  { long p = -1; P(INT8_MIN & p); }
  { long p = -1; P(INT8_MIN | p); }
  { long p = -1; P(INT8_MIN ^ p); }
  { long p = -1; P(p & INT8_MIN); }
  { long p = -1; P(p | INT8_MIN); }
  { long p = -1; P(1 ? INT8_MIN : p); }
  { long p = -1; P(1 ? p : INT8_MIN); }
  { long p = -1; P(0 ? INT8_MIN : p); }
  { long p = -1; P(TC(INT8_MIN + p)); }
  { long p = -1; P(TC(p + INT8_MIN)); }
  { long p = -1; P(TC(1 ? INT8_MIN : p)); }
  { long p = -1; P(sizeof(INT8_MIN + p)); }
  { long p = -1; long t = p; t += INT8_MIN; P(t); }
  { long p = -1; long t = p; t -= INT8_MIN; P(t); }
  { long p = -1; long t = p; t &= INT8_MIN; P(t); }
  { long p = -1; long t = p; t |= INT8_MIN; P(t); }
  { unsigned long p = -1; P(INT8_MIN < p); }
  { unsigned long p = -1; P(INT8_MIN > p); }
  { unsigned long p = -1; P(INT8_MIN == p); }
  { unsigned long p = -1; P(INT8_MIN != p); }
  { unsigned long p = -1; P(INT8_MIN <= p); }
  { unsigned long p = -1; P(INT8_MIN >= p); }
  { unsigned long p = -1; P(p < INT8_MIN); }
  { unsigned long p = -1; P(p > INT8_MIN); }
  { unsigned long p = -1; P(p == INT8_MIN); }
  { unsigned long p = -1; P(p <= INT8_MIN); }
  { unsigned long p = -1; P(INT8_MIN + p); }
  { unsigned long p = -1; P(p + INT8_MIN); }
  { unsigned long p = -1; P(INT8_MIN - p); }
  { unsigned long p = -1; P(p - INT8_MIN); }
  { unsigned long p = -1; P(INT8_MIN * p); }
  { unsigned long p = -1; P(p * INT8_MIN); }
  { unsigned long p = -1; P(INT8_MIN & p); }
  { unsigned long p = -1; P(INT8_MIN | p); }
  { unsigned long p = -1; P(INT8_MIN ^ p); }
  { unsigned long p = -1; P(p & INT8_MIN); }
  { unsigned long p = -1; P(p | INT8_MIN); }
  { unsigned long p = -1; P(1 ? INT8_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INT8_MIN); }
  { unsigned long p = -1; P(0 ? INT8_MIN : p); }
  { unsigned long p = -1; P(TC(INT8_MIN + p)); }
  { unsigned long p = -1; P(TC(p + INT8_MIN)); }
  { unsigned long p = -1; P(TC(1 ? INT8_MIN : p)); }
  { unsigned long p = -1; P(sizeof(INT8_MIN + p)); }
  { unsigned long p = -1; P(INT8_MIN / p); }
  { unsigned long p = -1; P(INT8_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += INT8_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INT8_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INT8_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INT8_MIN; P(t); }
  P(INTMAX_MAX > 0);
  P(INTMAX_MAX < 0);
  P(INTMAX_MAX == 0);
  P(INTMAX_MAX != 0);
  P(INTMAX_MAX >= 0);
  P(INTMAX_MAX <= 0);
  P(0 < INTMAX_MAX);
  P(0 > INTMAX_MAX);
  P(0 == INTMAX_MAX);
  P(+INTMAX_MAX);
  P(-INTMAX_MAX);
  P(~INTMAX_MAX);
  P(!INTMAX_MAX);
  P((+INTMAX_MAX) > 0);
  P(sizeof(INTMAX_MAX));
  P(sizeof(+INTMAX_MAX));
  P(TC(INTMAX_MAX));
  P(TC(+INTMAX_MAX));
  P(TC(-INTMAX_MAX));
  P(TC(~INTMAX_MAX));
  P((_Bool)INTMAX_MAX);
  P((signed char)INTMAX_MAX);
  P((unsigned char)INTMAX_MAX);
  P((short)INTMAX_MAX);
  P((unsigned short)INTMAX_MAX);
  P((int)INTMAX_MAX);
  P((unsigned)INTMAX_MAX);
  P((long)INTMAX_MAX);
  P((unsigned long)INTMAX_MAX);
  P((long long)INTMAX_MAX);
  P((unsigned long long)INTMAX_MAX);
  P((long long)INTMAX_MAX > 0);
  P((long long)INTMAX_MAX < 0);
  { int x = INTMAX_MAX; P(x); }
  { unsigned x = INTMAX_MAX; P(x); }
  { long x = INTMAX_MAX; P(x); }
  { unsigned long x = INTMAX_MAX; P(x); }
  P(INTMAX_MAX - 1);
  P(INTMAX_MAX - 1 > 0);
  P(INTMAX_MAX - 1u);
  P(INTMAX_MAX - 1ul);
  { int p = -1; P(INTMAX_MAX < p); }
  { int p = -1; P(INTMAX_MAX > p); }
  { int p = -1; P(INTMAX_MAX == p); }
  { int p = -1; P(INTMAX_MAX != p); }
  { int p = -1; P(INTMAX_MAX <= p); }
  { int p = -1; P(INTMAX_MAX >= p); }
  { int p = -1; P(p < INTMAX_MAX); }
  { int p = -1; P(p > INTMAX_MAX); }
  { int p = -1; P(p == INTMAX_MAX); }
  { int p = -1; P(p <= INTMAX_MAX); }
  { int p = -1; P(INTMAX_MAX + p); }
  { int p = -1; P(p + INTMAX_MAX); }
  { int p = -1; P(p - INTMAX_MAX); }
  { int p = -1; P(INTMAX_MAX * p); }
  { int p = -1; P(p * INTMAX_MAX); }
  { int p = -1; P(INTMAX_MAX & p); }
  { int p = -1; P(INTMAX_MAX | p); }
  { int p = -1; P(INTMAX_MAX ^ p); }
  { int p = -1; P(p & INTMAX_MAX); }
  { int p = -1; P(p | INTMAX_MAX); }
  { int p = -1; P(1 ? INTMAX_MAX : p); }
  { int p = -1; P(1 ? p : INTMAX_MAX); }
  { int p = -1; P(0 ? INTMAX_MAX : p); }
  { int p = -1; P(TC(INTMAX_MAX + p)); }
  { int p = -1; P(TC(p + INTMAX_MAX)); }
  { int p = -1; P(TC(1 ? INTMAX_MAX : p)); }
  { int p = -1; P(sizeof(INTMAX_MAX + p)); }
  { int p = -1; int t = p; t += INTMAX_MAX; P(t); }
  { int p = -1; int t = p; t -= INTMAX_MAX; P(t); }
  { int p = -1; int t = p; t &= INTMAX_MAX; P(t); }
  { int p = -1; int t = p; t |= INTMAX_MAX; P(t); }
  { unsigned p = -1; P(INTMAX_MAX < p); }
  { unsigned p = -1; P(INTMAX_MAX > p); }
  { unsigned p = -1; P(INTMAX_MAX == p); }
  { unsigned p = -1; P(INTMAX_MAX != p); }
  { unsigned p = -1; P(INTMAX_MAX <= p); }
  { unsigned p = -1; P(INTMAX_MAX >= p); }
  { unsigned p = -1; P(p < INTMAX_MAX); }
  { unsigned p = -1; P(p > INTMAX_MAX); }
  { unsigned p = -1; P(p == INTMAX_MAX); }
  { unsigned p = -1; P(p <= INTMAX_MAX); }
  { unsigned p = -1; P(INTMAX_MAX - p); }
  { unsigned p = -1; P(p - INTMAX_MAX); }
  { unsigned p = -1; P(INTMAX_MAX & p); }
  { unsigned p = -1; P(INTMAX_MAX | p); }
  { unsigned p = -1; P(INTMAX_MAX ^ p); }
  { unsigned p = -1; P(p & INTMAX_MAX); }
  { unsigned p = -1; P(p | INTMAX_MAX); }
  { unsigned p = -1; P(1 ? INTMAX_MAX : p); }
  { unsigned p = -1; P(1 ? p : INTMAX_MAX); }
  { unsigned p = -1; P(0 ? INTMAX_MAX : p); }
  { unsigned p = -1; P(TC(INTMAX_MAX + p)); }
  { unsigned p = -1; P(TC(p + INTMAX_MAX)); }
  { unsigned p = -1; P(TC(1 ? INTMAX_MAX : p)); }
  { unsigned p = -1; P(sizeof(INTMAX_MAX + p)); }
  { unsigned p = -1; P(INTMAX_MAX / p); }
  { unsigned p = -1; P(INTMAX_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= INTMAX_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INTMAX_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INTMAX_MAX; P(t); }
  { long p = -1; P(INTMAX_MAX < p); }
  { long p = -1; P(INTMAX_MAX > p); }
  { long p = -1; P(INTMAX_MAX == p); }
  { long p = -1; P(INTMAX_MAX != p); }
  { long p = -1; P(INTMAX_MAX <= p); }
  { long p = -1; P(INTMAX_MAX >= p); }
  { long p = -1; P(p < INTMAX_MAX); }
  { long p = -1; P(p > INTMAX_MAX); }
  { long p = -1; P(p == INTMAX_MAX); }
  { long p = -1; P(p <= INTMAX_MAX); }
  { long p = -1; P(INTMAX_MAX + p); }
  { long p = -1; P(p + INTMAX_MAX); }
  { long p = -1; P(p - INTMAX_MAX); }
  { long p = -1; P(INTMAX_MAX * p); }
  { long p = -1; P(p * INTMAX_MAX); }
  { long p = -1; P(INTMAX_MAX & p); }
  { long p = -1; P(INTMAX_MAX | p); }
  { long p = -1; P(INTMAX_MAX ^ p); }
  { long p = -1; P(p & INTMAX_MAX); }
  { long p = -1; P(p | INTMAX_MAX); }
  { long p = -1; P(1 ? INTMAX_MAX : p); }
  { long p = -1; P(1 ? p : INTMAX_MAX); }
  { long p = -1; P(0 ? INTMAX_MAX : p); }
  { long p = -1; P(TC(INTMAX_MAX + p)); }
  { long p = -1; P(TC(p + INTMAX_MAX)); }
  { long p = -1; P(TC(1 ? INTMAX_MAX : p)); }
  { long p = -1; P(sizeof(INTMAX_MAX + p)); }
  { long p = -1; long t = p; t += INTMAX_MAX; P(t); }
  { long p = -1; long t = p; t -= INTMAX_MAX; P(t); }
  { long p = -1; long t = p; t &= INTMAX_MAX; P(t); }
  { long p = -1; long t = p; t |= INTMAX_MAX; P(t); }
  { unsigned long p = -1; P(INTMAX_MAX < p); }
  { unsigned long p = -1; P(INTMAX_MAX > p); }
  { unsigned long p = -1; P(INTMAX_MAX == p); }
  { unsigned long p = -1; P(INTMAX_MAX != p); }
  { unsigned long p = -1; P(INTMAX_MAX <= p); }
  { unsigned long p = -1; P(INTMAX_MAX >= p); }
  { unsigned long p = -1; P(p < INTMAX_MAX); }
  { unsigned long p = -1; P(p > INTMAX_MAX); }
  { unsigned long p = -1; P(p == INTMAX_MAX); }
  { unsigned long p = -1; P(p <= INTMAX_MAX); }
  { unsigned long p = -1; P(INTMAX_MAX + p); }
  { unsigned long p = -1; P(p + INTMAX_MAX); }
  { unsigned long p = -1; P(INTMAX_MAX - p); }
  { unsigned long p = -1; P(p - INTMAX_MAX); }
  { unsigned long p = -1; P(INTMAX_MAX * p); }
  { unsigned long p = -1; P(p * INTMAX_MAX); }
  { unsigned long p = -1; P(INTMAX_MAX & p); }
  { unsigned long p = -1; P(INTMAX_MAX | p); }
  { unsigned long p = -1; P(INTMAX_MAX ^ p); }
  { unsigned long p = -1; P(p & INTMAX_MAX); }
  { unsigned long p = -1; P(p | INTMAX_MAX); }
  { unsigned long p = -1; P(1 ? INTMAX_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INTMAX_MAX); }
  { unsigned long p = -1; P(0 ? INTMAX_MAX : p); }
  { unsigned long p = -1; P(TC(INTMAX_MAX + p)); }
  { unsigned long p = -1; P(TC(p + INTMAX_MAX)); }
  { unsigned long p = -1; P(TC(1 ? INTMAX_MAX : p)); }
  { unsigned long p = -1; P(sizeof(INTMAX_MAX + p)); }
  { unsigned long p = -1; P(INTMAX_MAX / p); }
  { unsigned long p = -1; P(INTMAX_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t += INTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INTMAX_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INTMAX_MAX; P(t); }
  P(INTMAX_MIN > 0);
  P(INTMAX_MIN < 0);
  P(INTMAX_MIN == 0);
  P(INTMAX_MIN != 0);
  P(INTMAX_MIN >= 0);
  P(INTMAX_MIN <= 0);
  P(0 < INTMAX_MIN);
  P(0 > INTMAX_MIN);
  P(0 == INTMAX_MIN);
  P(+INTMAX_MIN);
  P(~INTMAX_MIN);
  P(!INTMAX_MIN);
  P((+INTMAX_MIN) > 0);
  P(sizeof(INTMAX_MIN));
  P(sizeof(+INTMAX_MIN));
  P(TC(INTMAX_MIN));
  P(TC(+INTMAX_MIN));
  P(TC(-INTMAX_MIN));
  P(TC(~INTMAX_MIN));
  P((_Bool)INTMAX_MIN);
  P((signed char)INTMAX_MIN);
  P((unsigned char)INTMAX_MIN);
  P((short)INTMAX_MIN);
  P((unsigned short)INTMAX_MIN);
  P((int)INTMAX_MIN);
  P((unsigned)INTMAX_MIN);
  P((long)INTMAX_MIN);
  P((unsigned long)INTMAX_MIN);
  P((long long)INTMAX_MIN);
  P((unsigned long long)INTMAX_MIN);
  P((long long)INTMAX_MIN > 0);
  P((long long)INTMAX_MIN < 0);
  { int x = INTMAX_MIN; P(x); }
  { unsigned x = INTMAX_MIN; P(x); }
  { long x = INTMAX_MIN; P(x); }
  { unsigned long x = INTMAX_MIN; P(x); }
  P(INTMAX_MIN + 1);
  P(INTMAX_MIN + 1 > 0);
  P(INTMAX_MIN + 1u);
  P(INTMAX_MIN + 1l);
  P(INTMAX_MIN - 1ul);
  { int p = -1; P(INTMAX_MIN < p); }
  { int p = -1; P(INTMAX_MIN > p); }
  { int p = -1; P(INTMAX_MIN == p); }
  { int p = -1; P(INTMAX_MIN != p); }
  { int p = -1; P(INTMAX_MIN <= p); }
  { int p = -1; P(INTMAX_MIN >= p); }
  { int p = -1; P(p < INTMAX_MIN); }
  { int p = -1; P(p > INTMAX_MIN); }
  { int p = -1; P(p == INTMAX_MIN); }
  { int p = -1; P(p <= INTMAX_MIN); }
  { int p = -1; P(INTMAX_MIN - p); }
  { int p = -1; P(p - INTMAX_MIN); }
  { int p = -1; P(INTMAX_MIN & p); }
  { int p = -1; P(INTMAX_MIN | p); }
  { int p = -1; P(INTMAX_MIN ^ p); }
  { int p = -1; P(p & INTMAX_MIN); }
  { int p = -1; P(p | INTMAX_MIN); }
  { int p = -1; P(1 ? INTMAX_MIN : p); }
  { int p = -1; P(1 ? p : INTMAX_MIN); }
  { int p = -1; P(0 ? INTMAX_MIN : p); }
  { int p = -1; P(TC(INTMAX_MIN + p)); }
  { int p = -1; P(TC(p + INTMAX_MIN)); }
  { int p = -1; P(TC(1 ? INTMAX_MIN : p)); }
  { int p = -1; P(sizeof(INTMAX_MIN + p)); }
  { int p = -1; int t = p; t -= INTMAX_MIN; P(t); }
  { int p = -1; int t = p; t &= INTMAX_MIN; P(t); }
  { int p = -1; int t = p; t |= INTMAX_MIN; P(t); }
  { unsigned p = -1; P(INTMAX_MIN < p); }
  { unsigned p = -1; P(INTMAX_MIN > p); }
  { unsigned p = -1; P(INTMAX_MIN == p); }
  { unsigned p = -1; P(INTMAX_MIN != p); }
  { unsigned p = -1; P(INTMAX_MIN <= p); }
  { unsigned p = -1; P(INTMAX_MIN >= p); }
  { unsigned p = -1; P(p < INTMAX_MIN); }
  { unsigned p = -1; P(p > INTMAX_MIN); }
  { unsigned p = -1; P(p == INTMAX_MIN); }
  { unsigned p = -1; P(p <= INTMAX_MIN); }
  { unsigned p = -1; P(INTMAX_MIN + p); }
  { unsigned p = -1; P(p + INTMAX_MIN); }
  { unsigned p = -1; P(INTMAX_MIN & p); }
  { unsigned p = -1; P(INTMAX_MIN | p); }
  { unsigned p = -1; P(INTMAX_MIN ^ p); }
  { unsigned p = -1; P(p & INTMAX_MIN); }
  { unsigned p = -1; P(p | INTMAX_MIN); }
  { unsigned p = -1; P(1 ? INTMAX_MIN : p); }
  { unsigned p = -1; P(1 ? p : INTMAX_MIN); }
  { unsigned p = -1; P(0 ? INTMAX_MIN : p); }
  { unsigned p = -1; P(TC(INTMAX_MIN + p)); }
  { unsigned p = -1; P(TC(p + INTMAX_MIN)); }
  { unsigned p = -1; P(TC(1 ? INTMAX_MIN : p)); }
  { unsigned p = -1; P(sizeof(INTMAX_MIN + p)); }
  { unsigned p = -1; P(INTMAX_MIN / p); }
  { unsigned p = -1; P(INTMAX_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INTMAX_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INTMAX_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INTMAX_MIN; P(t); }
  { long p = -1; P(INTMAX_MIN < p); }
  { long p = -1; P(INTMAX_MIN > p); }
  { long p = -1; P(INTMAX_MIN == p); }
  { long p = -1; P(INTMAX_MIN != p); }
  { long p = -1; P(INTMAX_MIN <= p); }
  { long p = -1; P(INTMAX_MIN >= p); }
  { long p = -1; P(p < INTMAX_MIN); }
  { long p = -1; P(p > INTMAX_MIN); }
  { long p = -1; P(p == INTMAX_MIN); }
  { long p = -1; P(p <= INTMAX_MIN); }
  { long p = -1; P(INTMAX_MIN - p); }
  { long p = -1; P(p - INTMAX_MIN); }
  { long p = -1; P(INTMAX_MIN & p); }
  { long p = -1; P(INTMAX_MIN | p); }
  { long p = -1; P(INTMAX_MIN ^ p); }
  { long p = -1; P(p & INTMAX_MIN); }
  { long p = -1; P(p | INTMAX_MIN); }
  { long p = -1; P(1 ? INTMAX_MIN : p); }
  { long p = -1; P(1 ? p : INTMAX_MIN); }
  { long p = -1; P(0 ? INTMAX_MIN : p); }
  { long p = -1; P(TC(INTMAX_MIN + p)); }
  { long p = -1; P(TC(p + INTMAX_MIN)); }
  { long p = -1; P(TC(1 ? INTMAX_MIN : p)); }
  { long p = -1; P(sizeof(INTMAX_MIN + p)); }
  { long p = -1; long t = p; t -= INTMAX_MIN; P(t); }
  { long p = -1; long t = p; t &= INTMAX_MIN; P(t); }
  { long p = -1; long t = p; t |= INTMAX_MIN; P(t); }
  { unsigned long p = -1; P(INTMAX_MIN < p); }
  { unsigned long p = -1; P(INTMAX_MIN > p); }
  { unsigned long p = -1; P(INTMAX_MIN == p); }
  { unsigned long p = -1; P(INTMAX_MIN != p); }
  { unsigned long p = -1; P(INTMAX_MIN <= p); }
  { unsigned long p = -1; P(INTMAX_MIN >= p); }
  { unsigned long p = -1; P(p < INTMAX_MIN); }
  { unsigned long p = -1; P(p > INTMAX_MIN); }
  { unsigned long p = -1; P(p == INTMAX_MIN); }
  { unsigned long p = -1; P(p <= INTMAX_MIN); }
  { unsigned long p = -1; P(INTMAX_MIN + p); }
  { unsigned long p = -1; P(p + INTMAX_MIN); }
  { unsigned long p = -1; P(INTMAX_MIN - p); }
  { unsigned long p = -1; P(p - INTMAX_MIN); }
  { unsigned long p = -1; P(INTMAX_MIN * p); }
  { unsigned long p = -1; P(p * INTMAX_MIN); }
  { unsigned long p = -1; P(INTMAX_MIN & p); }
  { unsigned long p = -1; P(INTMAX_MIN | p); }
  { unsigned long p = -1; P(INTMAX_MIN ^ p); }
  { unsigned long p = -1; P(p & INTMAX_MIN); }
  { unsigned long p = -1; P(p | INTMAX_MIN); }
  { unsigned long p = -1; P(1 ? INTMAX_MIN : p); }
  { unsigned long p = -1; P(1 ? p : INTMAX_MIN); }
  { unsigned long p = -1; P(0 ? INTMAX_MIN : p); }
  { unsigned long p = -1; P(TC(INTMAX_MIN + p)); }
  { unsigned long p = -1; P(TC(p + INTMAX_MIN)); }
  { unsigned long p = -1; P(TC(1 ? INTMAX_MIN : p)); }
  { unsigned long p = -1; P(sizeof(INTMAX_MIN + p)); }
  { unsigned long p = -1; P(INTMAX_MIN / p); }
  { unsigned long p = -1; P(INTMAX_MIN % p); }
  { unsigned long p = -1; unsigned long t = p; t += INTMAX_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t -= INTMAX_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t &= INTMAX_MIN; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INTMAX_MIN; P(t); }
  P(INTPTR_MAX > 0);
  P(INTPTR_MAX < 0);
  P(INTPTR_MAX == 0);
  P(INTPTR_MAX != 0);
  P(INTPTR_MAX >= 0);
  P(INTPTR_MAX <= 0);
  P(0 < INTPTR_MAX);
  P(0 > INTPTR_MAX);
  P(0 == INTPTR_MAX);
  P(+INTPTR_MAX);
  P(-INTPTR_MAX);
  P(~INTPTR_MAX);
  P(!INTPTR_MAX);
  P((+INTPTR_MAX) > 0);
  P(sizeof(INTPTR_MAX));
  P(sizeof(+INTPTR_MAX));
  P(TC(INTPTR_MAX));
  P(TC(+INTPTR_MAX));
  P(TC(-INTPTR_MAX));
  P(TC(~INTPTR_MAX));
  P((_Bool)INTPTR_MAX);
  P((signed char)INTPTR_MAX);
  P((unsigned char)INTPTR_MAX);
  P((short)INTPTR_MAX);
  P((unsigned short)INTPTR_MAX);
  P((int)INTPTR_MAX);
  P((unsigned)INTPTR_MAX);
  P((long)INTPTR_MAX);
  P((unsigned long)INTPTR_MAX);
  P((long long)INTPTR_MAX);
  P((unsigned long long)INTPTR_MAX);
  P((long long)INTPTR_MAX > 0);
  P((long long)INTPTR_MAX < 0);
  { int x = INTPTR_MAX; P(x); }
  { unsigned x = INTPTR_MAX; P(x); }
  { long x = INTPTR_MAX; P(x); }
  { unsigned long x = INTPTR_MAX; P(x); }
  P(INTPTR_MAX - 1);
  P(INTPTR_MAX - 1 > 0);
  P(INTPTR_MAX - 1u);
  P(INTPTR_MAX - 1ul);
  { int p = -1; P(INTPTR_MAX < p); }
  { int p = -1; P(INTPTR_MAX > p); }
  { int p = -1; P(INTPTR_MAX == p); }
  { int p = -1; P(INTPTR_MAX != p); }
  { int p = -1; P(INTPTR_MAX <= p); }
  { int p = -1; P(INTPTR_MAX >= p); }
  { int p = -1; P(p < INTPTR_MAX); }
  { int p = -1; P(p > INTPTR_MAX); }
  { int p = -1; P(p == INTPTR_MAX); }
  { int p = -1; P(p <= INTPTR_MAX); }
  { int p = -1; P(INTPTR_MAX + p); }
  { int p = -1; P(p + INTPTR_MAX); }
  { int p = -1; P(p - INTPTR_MAX); }
  { int p = -1; P(INTPTR_MAX * p); }
  { int p = -1; P(p * INTPTR_MAX); }
  { int p = -1; P(INTPTR_MAX & p); }
  { int p = -1; P(INTPTR_MAX | p); }
  { int p = -1; P(INTPTR_MAX ^ p); }
  { int p = -1; P(p & INTPTR_MAX); }
  { int p = -1; P(p | INTPTR_MAX); }
  { int p = -1; P(1 ? INTPTR_MAX : p); }
  { int p = -1; P(1 ? p : INTPTR_MAX); }
  { int p = -1; P(0 ? INTPTR_MAX : p); }
  { int p = -1; P(TC(INTPTR_MAX + p)); }
  { int p = -1; P(TC(p + INTPTR_MAX)); }
  { int p = -1; P(TC(1 ? INTPTR_MAX : p)); }
  { int p = -1; P(sizeof(INTPTR_MAX + p)); }
  { int p = -1; int t = p; t += INTPTR_MAX; P(t); }
  { int p = -1; int t = p; t -= INTPTR_MAX; P(t); }
  { int p = -1; int t = p; t &= INTPTR_MAX; P(t); }
  { int p = -1; int t = p; t |= INTPTR_MAX; P(t); }
  { unsigned p = -1; P(INTPTR_MAX < p); }
  { unsigned p = -1; P(INTPTR_MAX > p); }
  { unsigned p = -1; P(INTPTR_MAX == p); }
  { unsigned p = -1; P(INTPTR_MAX != p); }
  { unsigned p = -1; P(INTPTR_MAX <= p); }
  { unsigned p = -1; P(INTPTR_MAX >= p); }
  { unsigned p = -1; P(p < INTPTR_MAX); }
  { unsigned p = -1; P(p > INTPTR_MAX); }
  { unsigned p = -1; P(p == INTPTR_MAX); }
  { unsigned p = -1; P(p <= INTPTR_MAX); }
  { unsigned p = -1; P(INTPTR_MAX - p); }
  { unsigned p = -1; P(p - INTPTR_MAX); }
  { unsigned p = -1; P(INTPTR_MAX & p); }
  { unsigned p = -1; P(INTPTR_MAX | p); }
  { unsigned p = -1; P(INTPTR_MAX ^ p); }
  { unsigned p = -1; P(p & INTPTR_MAX); }
  { unsigned p = -1; P(p | INTPTR_MAX); }
  { unsigned p = -1; P(1 ? INTPTR_MAX : p); }
  { unsigned p = -1; P(1 ? p : INTPTR_MAX); }
  { unsigned p = -1; P(0 ? INTPTR_MAX : p); }
  { unsigned p = -1; P(TC(INTPTR_MAX + p)); }
  { unsigned p = -1; P(TC(p + INTPTR_MAX)); }
  { unsigned p = -1; P(TC(1 ? INTPTR_MAX : p)); }
  { unsigned p = -1; P(sizeof(INTPTR_MAX + p)); }
  { unsigned p = -1; P(INTPTR_MAX / p); }
  { unsigned p = -1; P(INTPTR_MAX % p); }
  { unsigned p = -1; unsigned t = p; t -= INTPTR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INTPTR_MAX; P(t); }
  { unsigned p = -1; unsigned t = p; t |= INTPTR_MAX; P(t); }
  { long p = -1; P(INTPTR_MAX < p); }
  { long p = -1; P(INTPTR_MAX > p); }
  { long p = -1; P(INTPTR_MAX == p); }
  { long p = -1; P(INTPTR_MAX != p); }
  { long p = -1; P(INTPTR_MAX <= p); }
  { long p = -1; P(INTPTR_MAX >= p); }
  { long p = -1; P(p < INTPTR_MAX); }
  { long p = -1; P(p > INTPTR_MAX); }
  { long p = -1; P(p == INTPTR_MAX); }
  { long p = -1; P(p <= INTPTR_MAX); }
  { long p = -1; P(INTPTR_MAX + p); }
  { long p = -1; P(p + INTPTR_MAX); }
  { long p = -1; P(p - INTPTR_MAX); }
  { long p = -1; P(INTPTR_MAX * p); }
  { long p = -1; P(p * INTPTR_MAX); }
  { long p = -1; P(INTPTR_MAX & p); }
  { long p = -1; P(INTPTR_MAX | p); }
  { long p = -1; P(INTPTR_MAX ^ p); }
  { long p = -1; P(p & INTPTR_MAX); }
  { long p = -1; P(p | INTPTR_MAX); }
  { long p = -1; P(1 ? INTPTR_MAX : p); }
  { long p = -1; P(1 ? p : INTPTR_MAX); }
  { long p = -1; P(0 ? INTPTR_MAX : p); }
  { long p = -1; P(TC(INTPTR_MAX + p)); }
  { long p = -1; P(TC(p + INTPTR_MAX)); }
  { long p = -1; P(TC(1 ? INTPTR_MAX : p)); }
  { long p = -1; P(sizeof(INTPTR_MAX + p)); }
  { long p = -1; long t = p; t += INTPTR_MAX; P(t); }
  { long p = -1; long t = p; t -= INTPTR_MAX; P(t); }
  { long p = -1; long t = p; t &= INTPTR_MAX; P(t); }
  { long p = -1; long t = p; t |= INTPTR_MAX; P(t); }
  { unsigned long p = -1; P(INTPTR_MAX < p); }
  { unsigned long p = -1; P(INTPTR_MAX > p); }
  { unsigned long p = -1; P(INTPTR_MAX == p); }
  { unsigned long p = -1; P(INTPTR_MAX != p); }
  { unsigned long p = -1; P(INTPTR_MAX <= p); }
  { unsigned long p = -1; P(INTPTR_MAX >= p); }
  { unsigned long p = -1; P(p < INTPTR_MAX); }
  { unsigned long p = -1; P(p > INTPTR_MAX); }
  { unsigned long p = -1; P(p == INTPTR_MAX); }
  { unsigned long p = -1; P(p <= INTPTR_MAX); }
  { unsigned long p = -1; P(INTPTR_MAX - p); }
  { unsigned long p = -1; P(INTPTR_MAX & p); }
  { unsigned long p = -1; P(INTPTR_MAX | p); }
  { unsigned long p = -1; P(INTPTR_MAX ^ p); }
  { unsigned long p = -1; P(p & INTPTR_MAX); }
  { unsigned long p = -1; P(p | INTPTR_MAX); }
  { unsigned long p = -1; P(1 ? INTPTR_MAX : p); }
  { unsigned long p = -1; P(1 ? p : INTPTR_MAX); }
  { unsigned long p = -1; P(0 ? INTPTR_MAX : p); }
  { unsigned long p = -1; P(sizeof(INTPTR_MAX + p)); }
  { unsigned long p = -1; P(INTPTR_MAX / p); }
  { unsigned long p = -1; P(INTPTR_MAX % p); }
  { unsigned long p = -1; unsigned long t = p; t &= INTPTR_MAX; P(t); }
  { unsigned long p = -1; unsigned long t = p; t |= INTPTR_MAX; P(t); }
  P(INTPTR_MIN > 0);
  P(INTPTR_MIN < 0);
  P(INTPTR_MIN == 0);
  P(INTPTR_MIN != 0);
  P(INTPTR_MIN >= 0);
  P(INTPTR_MIN <= 0);
  P(0 < INTPTR_MIN);
  P(0 > INTPTR_MIN);
  P(0 == INTPTR_MIN);
  P(+INTPTR_MIN);
  P(~INTPTR_MIN);
  P(!INTPTR_MIN);
  P((+INTPTR_MIN) > 0);
  P(sizeof(INTPTR_MIN));
  P(sizeof(+INTPTR_MIN));
  P(TC(INTPTR_MIN));
  P(TC(+INTPTR_MIN));
  P(TC(-INTPTR_MIN));
  P(TC(~INTPTR_MIN));
  P((_Bool)INTPTR_MIN);
  P((signed char)INTPTR_MIN);
  P((unsigned char)INTPTR_MIN);
  P((short)INTPTR_MIN);
  P((unsigned short)INTPTR_MIN);
  P((int)INTPTR_MIN);
  P((unsigned)INTPTR_MIN);
  P((long)INTPTR_MIN);
  P((unsigned long)INTPTR_MIN);
  P((long long)INTPTR_MIN);
  P((unsigned long long)INTPTR_MIN);
  P((long long)INTPTR_MIN > 0);
  P((long long)INTPTR_MIN < 0);
  { int x = INTPTR_MIN; P(x); }
  { unsigned x = INTPTR_MIN; P(x); }
  { long x = INTPTR_MIN; P(x); }
  { unsigned long x = INTPTR_MIN; P(x); }
  P(INTPTR_MIN + 1);
  P(INTPTR_MIN + 1 > 0);
  P(INTPTR_MIN + 1u);
  P(INTPTR_MIN + 1l);
  P(INTPTR_MIN - 1ul);
  { int p = -1; P(INTPTR_MIN < p); }
  { int p = -1; P(INTPTR_MIN > p); }
  { int p = -1; P(INTPTR_MIN == p); }
  { int p = -1; P(INTPTR_MIN != p); }
  { int p = -1; P(INTPTR_MIN <= p); }
  { int p = -1; P(INTPTR_MIN >= p); }
  { int p = -1; P(p < INTPTR_MIN); }
  { int p = -1; P(p > INTPTR_MIN); }
  { int p = -1; P(p == INTPTR_MIN); }
  { int p = -1; P(p <= INTPTR_MIN); }
  { int p = -1; P(INTPTR_MIN - p); }
  { int p = -1; P(p - INTPTR_MIN); }
  { int p = -1; P(INTPTR_MIN & p); }
  { int p = -1; P(INTPTR_MIN | p); }
  { int p = -1; P(INTPTR_MIN ^ p); }
  { int p = -1; P(p & INTPTR_MIN); }
  { int p = -1; P(p | INTPTR_MIN); }
  { int p = -1; P(1 ? INTPTR_MIN : p); }
  { int p = -1; P(1 ? p : INTPTR_MIN); }
  { int p = -1; P(0 ? INTPTR_MIN : p); }
  { int p = -1; P(TC(INTPTR_MIN + p)); }
  { int p = -1; P(TC(p + INTPTR_MIN)); }
  { int p = -1; P(TC(1 ? INTPTR_MIN : p)); }
  { int p = -1; P(sizeof(INTPTR_MIN + p)); }
  { int p = -1; int t = p; t -= INTPTR_MIN; P(t); }
  { int p = -1; int t = p; t &= INTPTR_MIN; P(t); }
  { int p = -1; int t = p; t |= INTPTR_MIN; P(t); }
  { unsigned p = -1; P(INTPTR_MIN < p); }
  { unsigned p = -1; P(INTPTR_MIN > p); }
  { unsigned p = -1; P(INTPTR_MIN == p); }
  { unsigned p = -1; P(INTPTR_MIN != p); }
  { unsigned p = -1; P(INTPTR_MIN <= p); }
  { unsigned p = -1; P(INTPTR_MIN >= p); }
  { unsigned p = -1; P(p < INTPTR_MIN); }
  { unsigned p = -1; P(p > INTPTR_MIN); }
  { unsigned p = -1; P(p == INTPTR_MIN); }
  { unsigned p = -1; P(p <= INTPTR_MIN); }
  { unsigned p = -1; P(INTPTR_MIN + p); }
  { unsigned p = -1; P(p + INTPTR_MIN); }
  { unsigned p = -1; P(INTPTR_MIN & p); }
  { unsigned p = -1; P(INTPTR_MIN | p); }
  { unsigned p = -1; P(INTPTR_MIN ^ p); }
  { unsigned p = -1; P(p & INTPTR_MIN); }
  { unsigned p = -1; P(p | INTPTR_MIN); }
  { unsigned p = -1; P(1 ? INTPTR_MIN : p); }
  { unsigned p = -1; P(1 ? p : INTPTR_MIN); }
  { unsigned p = -1; P(0 ? INTPTR_MIN : p); }
  { unsigned p = -1; P(TC(INTPTR_MIN + p)); }
  { unsigned p = -1; P(TC(p + INTPTR_MIN)); }
  { unsigned p = -1; P(TC(1 ? INTPTR_MIN : p)); }
  { unsigned p = -1; P(sizeof(INTPTR_MIN + p)); }
  { unsigned p = -1; P(INTPTR_MIN / p); }
  { unsigned p = -1; P(INTPTR_MIN % p); }
  { unsigned p = -1; unsigned t = p; t += INTPTR_MIN; P(t); }
  { unsigned p = -1; unsigned t = p; t &= INTPTR_MIN; P(t); }
  printf("\n");
  return 0;
}
