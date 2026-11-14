// gcc 13's line on both engines: the direct __cerbvar_* limit spellings of the exact-width, least and fast families (the non-FIXED_STDINT branch of <stdint.h>): compared with 0, promoted, converted
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#ifndef __cerb__
#define __cerbvar_INT8_MIN ((signed char)SCHAR_MIN)
#define __cerbvar_INT8_MAX ((signed char)SCHAR_MAX)
#define __cerbvar_UINT8_MAX ((unsigned char)UCHAR_MAX)
#define __cerbvar_INT16_MIN ((short)SHRT_MIN)
#define __cerbvar_INT16_MAX ((short)SHRT_MAX)
#define __cerbvar_UINT16_MAX ((unsigned short)USHRT_MAX)
#define __cerbvar_INT32_MIN ((int)INT_MIN)
#define __cerbvar_INT32_MAX ((int)INT_MAX)
#define __cerbvar_UINT32_MAX ((unsigned)UINT_MAX)
#define __cerbvar_INT64_MIN ((long)LONG_MIN)
#define __cerbvar_INT64_MAX ((long)LONG_MAX)
#define __cerbvar_UINT64_MAX ((unsigned long)ULONG_MAX)
#define __cerbvar_INT_LEAST8_MIN ((signed char)SCHAR_MIN)
#define __cerbvar_INT_LEAST8_MAX ((signed char)SCHAR_MAX)
#define __cerbvar_UINT_LEAST8_MAX ((unsigned char)UCHAR_MAX)
#define __cerbvar_INT_LEAST16_MIN ((short)SHRT_MIN)
#define __cerbvar_INT_LEAST16_MAX ((short)SHRT_MAX)
#define __cerbvar_UINT_LEAST16_MAX ((unsigned short)USHRT_MAX)
#define __cerbvar_INT_LEAST32_MIN ((int)INT_MIN)
#define __cerbvar_INT_LEAST32_MAX ((int)INT_MAX)
#define __cerbvar_UINT_LEAST32_MAX ((unsigned)UINT_MAX)
#define __cerbvar_INT_LEAST64_MIN ((long)LONG_MIN)
#define __cerbvar_INT_LEAST64_MAX ((long)LONG_MAX)
#define __cerbvar_UINT_LEAST64_MAX ((unsigned long)ULONG_MAX)
#define __cerbvar_INT_FAST8_MIN ((signed char)SCHAR_MIN)
#define __cerbvar_INT_FAST8_MAX ((signed char)SCHAR_MAX)
#define __cerbvar_UINT_FAST8_MAX ((unsigned char)UCHAR_MAX)
#define __cerbvar_INT_FAST16_MIN ((short)SHRT_MIN)
#define __cerbvar_INT_FAST16_MAX ((short)SHRT_MAX)
#define __cerbvar_UINT_FAST16_MAX ((unsigned short)USHRT_MAX)
#define __cerbvar_INT_FAST32_MIN ((int)INT_MIN)
#define __cerbvar_INT_FAST32_MAX ((int)INT_MAX)
#define __cerbvar_UINT_FAST32_MAX ((unsigned)UINT_MAX)
#define __cerbvar_INT_FAST64_MIN ((long)LONG_MIN)
#define __cerbvar_INT_FAST64_MAX ((long)LONG_MAX)
#define __cerbvar_UINT_FAST64_MAX ((unsigned long)ULONG_MAX)
#endif
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  P(__cerbvar_INT8_MIN > 0);
  P(__cerbvar_INT8_MIN < 0);
  P(__cerbvar_INT8_MIN == 0);
  P(__cerbvar_INT8_MIN != 0);
  P(__cerbvar_INT8_MIN >= 0);
  P(__cerbvar_INT8_MIN <= 0);
  P(0 < __cerbvar_INT8_MIN);
  P(0 > __cerbvar_INT8_MIN);
  P(0 == __cerbvar_INT8_MIN);
  P(+__cerbvar_INT8_MIN);
  P(-__cerbvar_INT8_MIN);
  P(~__cerbvar_INT8_MIN);
  P(!__cerbvar_INT8_MIN);
  P((+__cerbvar_INT8_MIN) > 0);
  P(sizeof(__cerbvar_INT8_MIN));
  P(sizeof(+__cerbvar_INT8_MIN));
  P(TC(__cerbvar_INT8_MIN));
  P(TC(+__cerbvar_INT8_MIN));
  P(TC(-__cerbvar_INT8_MIN));
  P(TC(~__cerbvar_INT8_MIN));
  P((_Bool)__cerbvar_INT8_MIN);
  P((signed char)__cerbvar_INT8_MIN);
  P((unsigned char)__cerbvar_INT8_MIN);
  P((short)__cerbvar_INT8_MIN);
  P((unsigned short)__cerbvar_INT8_MIN);
  P((int)__cerbvar_INT8_MIN);
  P((unsigned)__cerbvar_INT8_MIN);
  P((long)__cerbvar_INT8_MIN);
  P((unsigned long)__cerbvar_INT8_MIN);
  P((long long)__cerbvar_INT8_MIN);
  P((unsigned long long)__cerbvar_INT8_MIN);
  P((long long)__cerbvar_INT8_MIN > 0);
  P((long long)__cerbvar_INT8_MIN < 0);
  { int x = __cerbvar_INT8_MIN; P(x); }
  { unsigned x = __cerbvar_INT8_MIN; P(x); }
  { long x = __cerbvar_INT8_MIN; P(x); }
  { unsigned long x = __cerbvar_INT8_MIN; P(x); }
  P(__cerbvar_INT8_MIN + 1);
  P(__cerbvar_INT8_MIN - 1);
  P(__cerbvar_INT8_MIN - 1 > 0);
  P(__cerbvar_INT8_MIN + 1 > 0);
  P(__cerbvar_INT8_MIN + 1u);
  P(__cerbvar_INT8_MIN - 1u);
  P(__cerbvar_INT8_MIN + 1l);
  P(__cerbvar_INT8_MIN - 1ul);
  P(__cerbvar_INT8_MAX > 0);
  P(__cerbvar_INT8_MAX < 0);
  P(__cerbvar_INT8_MAX == 0);
  P(__cerbvar_INT8_MAX != 0);
  P(__cerbvar_INT8_MAX >= 0);
  P(__cerbvar_INT8_MAX <= 0);
  P(0 < __cerbvar_INT8_MAX);
  P(0 > __cerbvar_INT8_MAX);
  P(0 == __cerbvar_INT8_MAX);
  P(+__cerbvar_INT8_MAX);
  P(-__cerbvar_INT8_MAX);
  P(~__cerbvar_INT8_MAX);
  P(!__cerbvar_INT8_MAX);
  P((+__cerbvar_INT8_MAX) > 0);
  P(sizeof(__cerbvar_INT8_MAX));
  P(sizeof(+__cerbvar_INT8_MAX));
  P(TC(__cerbvar_INT8_MAX));
  P(TC(+__cerbvar_INT8_MAX));
  P(TC(-__cerbvar_INT8_MAX));
  P(TC(~__cerbvar_INT8_MAX));
  P((_Bool)__cerbvar_INT8_MAX);
  P((signed char)__cerbvar_INT8_MAX);
  P((unsigned char)__cerbvar_INT8_MAX);
  P((short)__cerbvar_INT8_MAX);
  P((unsigned short)__cerbvar_INT8_MAX);
  P((int)__cerbvar_INT8_MAX);
  P((unsigned)__cerbvar_INT8_MAX);
  P((long)__cerbvar_INT8_MAX);
  P((unsigned long)__cerbvar_INT8_MAX);
  P((long long)__cerbvar_INT8_MAX);
  P((unsigned long long)__cerbvar_INT8_MAX);
  P((long long)__cerbvar_INT8_MAX > 0);
  P((long long)__cerbvar_INT8_MAX < 0);
  { int x = __cerbvar_INT8_MAX; P(x); }
  { unsigned x = __cerbvar_INT8_MAX; P(x); }
  { long x = __cerbvar_INT8_MAX; P(x); }
  { unsigned long x = __cerbvar_INT8_MAX; P(x); }
  P(__cerbvar_INT8_MAX + 1);
  P(__cerbvar_INT8_MAX - 1);
  P(__cerbvar_INT8_MAX - 1 > 0);
  P(__cerbvar_INT8_MAX + 1 > 0);
  P(__cerbvar_INT8_MAX + 1u);
  P(__cerbvar_INT8_MAX - 1u);
  P(__cerbvar_INT8_MAX + 1l);
  P(__cerbvar_INT8_MAX - 1ul);
  P(__cerbvar_UINT8_MAX > 0);
  P(__cerbvar_UINT8_MAX < 0);
  P(__cerbvar_UINT8_MAX == 0);
  P(__cerbvar_UINT8_MAX != 0);
  P(__cerbvar_UINT8_MAX >= 0);
  P(__cerbvar_UINT8_MAX <= 0);
  P(0 < __cerbvar_UINT8_MAX);
  P(0 > __cerbvar_UINT8_MAX);
  P(0 == __cerbvar_UINT8_MAX);
  P(+__cerbvar_UINT8_MAX);
  P(-__cerbvar_UINT8_MAX);
  P(~__cerbvar_UINT8_MAX);
  P(!__cerbvar_UINT8_MAX);
  P((+__cerbvar_UINT8_MAX) > 0);
  P(sizeof(__cerbvar_UINT8_MAX));
  P(sizeof(+__cerbvar_UINT8_MAX));
  P(TC(__cerbvar_UINT8_MAX));
  P(TC(+__cerbvar_UINT8_MAX));
  P(TC(-__cerbvar_UINT8_MAX));
  P(TC(~__cerbvar_UINT8_MAX));
  P((_Bool)__cerbvar_UINT8_MAX);
  P((signed char)__cerbvar_UINT8_MAX);
  P((unsigned char)__cerbvar_UINT8_MAX);
  P((short)__cerbvar_UINT8_MAX);
  P((unsigned short)__cerbvar_UINT8_MAX);
  P((int)__cerbvar_UINT8_MAX);
  P((unsigned)__cerbvar_UINT8_MAX);
  P((long)__cerbvar_UINT8_MAX);
  P((unsigned long)__cerbvar_UINT8_MAX);
  P((long long)__cerbvar_UINT8_MAX);
  P((unsigned long long)__cerbvar_UINT8_MAX);
  P((long long)__cerbvar_UINT8_MAX > 0);
  P((long long)__cerbvar_UINT8_MAX < 0);
  { int x = __cerbvar_UINT8_MAX; P(x); }
  { unsigned x = __cerbvar_UINT8_MAX; P(x); }
  { long x = __cerbvar_UINT8_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT8_MAX; P(x); }
  P(__cerbvar_UINT8_MAX + 1);
  P(__cerbvar_UINT8_MAX - 1);
  P(__cerbvar_UINT8_MAX - 1 > 0);
  P(__cerbvar_UINT8_MAX + 1 > 0);
  P(__cerbvar_UINT8_MAX + 1u);
  P(__cerbvar_UINT8_MAX - 1u);
  P(__cerbvar_UINT8_MAX + 1l);
  P(__cerbvar_UINT8_MAX - 1ul);
  P(__cerbvar_INT16_MIN > 0);
  P(__cerbvar_INT16_MIN < 0);
  P(__cerbvar_INT16_MIN == 0);
  P(__cerbvar_INT16_MIN != 0);
  P(__cerbvar_INT16_MIN >= 0);
  P(__cerbvar_INT16_MIN <= 0);
  P(0 < __cerbvar_INT16_MIN);
  P(0 > __cerbvar_INT16_MIN);
  P(0 == __cerbvar_INT16_MIN);
  P(+__cerbvar_INT16_MIN);
  P(-__cerbvar_INT16_MIN);
  P(~__cerbvar_INT16_MIN);
  P(!__cerbvar_INT16_MIN);
  P((+__cerbvar_INT16_MIN) > 0);
  P(sizeof(__cerbvar_INT16_MIN));
  P(sizeof(+__cerbvar_INT16_MIN));
  P(TC(__cerbvar_INT16_MIN));
  P(TC(+__cerbvar_INT16_MIN));
  P(TC(-__cerbvar_INT16_MIN));
  P(TC(~__cerbvar_INT16_MIN));
  P((_Bool)__cerbvar_INT16_MIN);
  P((signed char)__cerbvar_INT16_MIN);
  P((unsigned char)__cerbvar_INT16_MIN);
  P((short)__cerbvar_INT16_MIN);
  P((unsigned short)__cerbvar_INT16_MIN);
  P((int)__cerbvar_INT16_MIN);
  P((unsigned)__cerbvar_INT16_MIN);
  P((long)__cerbvar_INT16_MIN);
  P((unsigned long)__cerbvar_INT16_MIN);
  P((long long)__cerbvar_INT16_MIN);
  P((unsigned long long)__cerbvar_INT16_MIN);
  P((long long)__cerbvar_INT16_MIN > 0);
  P((long long)__cerbvar_INT16_MIN < 0);
  { int x = __cerbvar_INT16_MIN; P(x); }
  { unsigned x = __cerbvar_INT16_MIN; P(x); }
  { long x = __cerbvar_INT16_MIN; P(x); }
  { unsigned long x = __cerbvar_INT16_MIN; P(x); }
  P(__cerbvar_INT16_MIN + 1);
  P(__cerbvar_INT16_MIN - 1);
  P(__cerbvar_INT16_MIN - 1 > 0);
  P(__cerbvar_INT16_MIN + 1 > 0);
  P(__cerbvar_INT16_MIN + 1u);
  P(__cerbvar_INT16_MIN - 1u);
  P(__cerbvar_INT16_MIN + 1l);
  P(__cerbvar_INT16_MIN - 1ul);
  P(__cerbvar_INT16_MAX > 0);
  P(__cerbvar_INT16_MAX < 0);
  P(__cerbvar_INT16_MAX == 0);
  P(__cerbvar_INT16_MAX != 0);
  P(__cerbvar_INT16_MAX >= 0);
  P(__cerbvar_INT16_MAX <= 0);
  P(0 < __cerbvar_INT16_MAX);
  P(0 > __cerbvar_INT16_MAX);
  P(0 == __cerbvar_INT16_MAX);
  P(+__cerbvar_INT16_MAX);
  P(-__cerbvar_INT16_MAX);
  P(~__cerbvar_INT16_MAX);
  P(!__cerbvar_INT16_MAX);
  P((+__cerbvar_INT16_MAX) > 0);
  P(sizeof(__cerbvar_INT16_MAX));
  P(sizeof(+__cerbvar_INT16_MAX));
  P(TC(__cerbvar_INT16_MAX));
  P(TC(+__cerbvar_INT16_MAX));
  P(TC(-__cerbvar_INT16_MAX));
  P(TC(~__cerbvar_INT16_MAX));
  P((_Bool)__cerbvar_INT16_MAX);
  P((signed char)__cerbvar_INT16_MAX);
  P((unsigned char)__cerbvar_INT16_MAX);
  P((short)__cerbvar_INT16_MAX);
  P((unsigned short)__cerbvar_INT16_MAX);
  P((int)__cerbvar_INT16_MAX);
  P((unsigned)__cerbvar_INT16_MAX);
  P((long)__cerbvar_INT16_MAX);
  P((unsigned long)__cerbvar_INT16_MAX);
  P((long long)__cerbvar_INT16_MAX);
  P((unsigned long long)__cerbvar_INT16_MAX);
  P((long long)__cerbvar_INT16_MAX > 0);
  P((long long)__cerbvar_INT16_MAX < 0);
  { int x = __cerbvar_INT16_MAX; P(x); }
  { unsigned x = __cerbvar_INT16_MAX; P(x); }
  { long x = __cerbvar_INT16_MAX; P(x); }
  { unsigned long x = __cerbvar_INT16_MAX; P(x); }
  P(__cerbvar_INT16_MAX + 1);
  P(__cerbvar_INT16_MAX - 1);
  P(__cerbvar_INT16_MAX - 1 > 0);
  P(__cerbvar_INT16_MAX + 1 > 0);
  P(__cerbvar_INT16_MAX + 1u);
  P(__cerbvar_INT16_MAX - 1u);
  P(__cerbvar_INT16_MAX + 1l);
  P(__cerbvar_INT16_MAX - 1ul);
  P(__cerbvar_UINT16_MAX > 0);
  P(__cerbvar_UINT16_MAX < 0);
  P(__cerbvar_UINT16_MAX == 0);
  P(__cerbvar_UINT16_MAX != 0);
  P(__cerbvar_UINT16_MAX >= 0);
  P(__cerbvar_UINT16_MAX <= 0);
  P(0 < __cerbvar_UINT16_MAX);
  P(0 > __cerbvar_UINT16_MAX);
  P(0 == __cerbvar_UINT16_MAX);
  P(+__cerbvar_UINT16_MAX);
  P(-__cerbvar_UINT16_MAX);
  P(~__cerbvar_UINT16_MAX);
  P(!__cerbvar_UINT16_MAX);
  P((+__cerbvar_UINT16_MAX) > 0);
  P(sizeof(__cerbvar_UINT16_MAX));
  P(sizeof(+__cerbvar_UINT16_MAX));
  P(TC(__cerbvar_UINT16_MAX));
  P(TC(+__cerbvar_UINT16_MAX));
  P(TC(-__cerbvar_UINT16_MAX));
  P(TC(~__cerbvar_UINT16_MAX));
  P((_Bool)__cerbvar_UINT16_MAX);
  P((signed char)__cerbvar_UINT16_MAX);
  P((unsigned char)__cerbvar_UINT16_MAX);
  P((short)__cerbvar_UINT16_MAX);
  P((unsigned short)__cerbvar_UINT16_MAX);
  P((int)__cerbvar_UINT16_MAX);
  P((unsigned)__cerbvar_UINT16_MAX);
  P((long)__cerbvar_UINT16_MAX);
  P((unsigned long)__cerbvar_UINT16_MAX);
  P((long long)__cerbvar_UINT16_MAX);
  P((unsigned long long)__cerbvar_UINT16_MAX);
  P((long long)__cerbvar_UINT16_MAX > 0);
  P((long long)__cerbvar_UINT16_MAX < 0);
  { int x = __cerbvar_UINT16_MAX; P(x); }
  { unsigned x = __cerbvar_UINT16_MAX; P(x); }
  { long x = __cerbvar_UINT16_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT16_MAX; P(x); }
  P(__cerbvar_UINT16_MAX + 1);
  P(__cerbvar_UINT16_MAX - 1);
  P(__cerbvar_UINT16_MAX - 1 > 0);
  P(__cerbvar_UINT16_MAX + 1 > 0);
  P(__cerbvar_UINT16_MAX + 1u);
  P(__cerbvar_UINT16_MAX - 1u);
  P(__cerbvar_UINT16_MAX + 1l);
  P(__cerbvar_UINT16_MAX - 1ul);
  P(__cerbvar_INT32_MIN > 0);
  P(__cerbvar_INT32_MIN < 0);
  P(__cerbvar_INT32_MIN == 0);
  P(__cerbvar_INT32_MIN != 0);
  P(__cerbvar_INT32_MIN >= 0);
  P(__cerbvar_INT32_MIN <= 0);
  P(0 < __cerbvar_INT32_MIN);
  P(0 > __cerbvar_INT32_MIN);
  P(0 == __cerbvar_INT32_MIN);
  P(+__cerbvar_INT32_MIN);
  P(~__cerbvar_INT32_MIN);
  P(!__cerbvar_INT32_MIN);
  P((+__cerbvar_INT32_MIN) > 0);
  P(sizeof(__cerbvar_INT32_MIN));
  P(sizeof(+__cerbvar_INT32_MIN));
  P(TC(__cerbvar_INT32_MIN));
  P(TC(+__cerbvar_INT32_MIN));
  P(TC(-__cerbvar_INT32_MIN));
  P(TC(~__cerbvar_INT32_MIN));
  P((_Bool)__cerbvar_INT32_MIN);
  P((signed char)__cerbvar_INT32_MIN);
  P((unsigned char)__cerbvar_INT32_MIN);
  P((short)__cerbvar_INT32_MIN);
  P((unsigned short)__cerbvar_INT32_MIN);
  P((int)__cerbvar_INT32_MIN);
  P((unsigned)__cerbvar_INT32_MIN);
  P((long)__cerbvar_INT32_MIN);
  P((unsigned long)__cerbvar_INT32_MIN);
  P((long long)__cerbvar_INT32_MIN);
  P((unsigned long long)__cerbvar_INT32_MIN);
  P((long long)__cerbvar_INT32_MIN > 0);
  P((long long)__cerbvar_INT32_MIN < 0);
  { int x = __cerbvar_INT32_MIN; P(x); }
  { unsigned x = __cerbvar_INT32_MIN; P(x); }
  { long x = __cerbvar_INT32_MIN; P(x); }
  { unsigned long x = __cerbvar_INT32_MIN; P(x); }
  P(__cerbvar_INT32_MIN + 1);
  P(__cerbvar_INT32_MIN + 1 > 0);
  P(__cerbvar_INT32_MIN + 1u);
  P(__cerbvar_INT32_MIN - 1u);
  P(__cerbvar_INT32_MIN + 1l);
  P(__cerbvar_INT32_MIN - 1ul);
  P(__cerbvar_INT32_MAX > 0);
  P(__cerbvar_INT32_MAX < 0);
  P(__cerbvar_INT32_MAX == 0);
  P(__cerbvar_INT32_MAX != 0);
  P(__cerbvar_INT32_MAX >= 0);
  P(__cerbvar_INT32_MAX <= 0);
  P(0 < __cerbvar_INT32_MAX);
  P(0 > __cerbvar_INT32_MAX);
  P(0 == __cerbvar_INT32_MAX);
  P(+__cerbvar_INT32_MAX);
  P(-__cerbvar_INT32_MAX);
  P(~__cerbvar_INT32_MAX);
  P(!__cerbvar_INT32_MAX);
  P((+__cerbvar_INT32_MAX) > 0);
  P(sizeof(__cerbvar_INT32_MAX));
  P(sizeof(+__cerbvar_INT32_MAX));
  P(TC(__cerbvar_INT32_MAX));
  P(TC(+__cerbvar_INT32_MAX));
  P(TC(-__cerbvar_INT32_MAX));
  P(TC(~__cerbvar_INT32_MAX));
  P((_Bool)__cerbvar_INT32_MAX);
  P((signed char)__cerbvar_INT32_MAX);
  P((unsigned char)__cerbvar_INT32_MAX);
  P((short)__cerbvar_INT32_MAX);
  P((unsigned short)__cerbvar_INT32_MAX);
  P((int)__cerbvar_INT32_MAX);
  P((unsigned)__cerbvar_INT32_MAX);
  P((long)__cerbvar_INT32_MAX);
  P((unsigned long)__cerbvar_INT32_MAX);
  P((long long)__cerbvar_INT32_MAX);
  P((unsigned long long)__cerbvar_INT32_MAX);
  P((long long)__cerbvar_INT32_MAX > 0);
  P((long long)__cerbvar_INT32_MAX < 0);
  { int x = __cerbvar_INT32_MAX; P(x); }
  { unsigned x = __cerbvar_INT32_MAX; P(x); }
  { long x = __cerbvar_INT32_MAX; P(x); }
  { unsigned long x = __cerbvar_INT32_MAX; P(x); }
  P(__cerbvar_INT32_MAX - 1);
  P(__cerbvar_INT32_MAX - 1 > 0);
  P(__cerbvar_INT32_MAX + 1u);
  P(__cerbvar_INT32_MAX - 1u);
  P(__cerbvar_INT32_MAX + 1l);
  P(__cerbvar_INT32_MAX - 1ul);
  P(__cerbvar_UINT32_MAX > 0);
  P(__cerbvar_UINT32_MAX < 0);
  P(__cerbvar_UINT32_MAX == 0);
  P(__cerbvar_UINT32_MAX != 0);
  P(__cerbvar_UINT32_MAX >= 0);
  P(__cerbvar_UINT32_MAX <= 0);
  P(0 < __cerbvar_UINT32_MAX);
  P(0 > __cerbvar_UINT32_MAX);
  P(0 == __cerbvar_UINT32_MAX);
  P(+__cerbvar_UINT32_MAX);
  P(-__cerbvar_UINT32_MAX);
  P(~__cerbvar_UINT32_MAX);
  P(!__cerbvar_UINT32_MAX);
  P((+__cerbvar_UINT32_MAX) > 0);
  P(sizeof(__cerbvar_UINT32_MAX));
  P(sizeof(+__cerbvar_UINT32_MAX));
  P(TC(__cerbvar_UINT32_MAX));
  P(TC(+__cerbvar_UINT32_MAX));
  P(TC(-__cerbvar_UINT32_MAX));
  P(TC(~__cerbvar_UINT32_MAX));
  P((_Bool)__cerbvar_UINT32_MAX);
  P((signed char)__cerbvar_UINT32_MAX);
  P((unsigned char)__cerbvar_UINT32_MAX);
  P((short)__cerbvar_UINT32_MAX);
  P((unsigned short)__cerbvar_UINT32_MAX);
  P((int)__cerbvar_UINT32_MAX);
  P((unsigned)__cerbvar_UINT32_MAX);
  P((long)__cerbvar_UINT32_MAX);
  P((unsigned long)__cerbvar_UINT32_MAX);
  P((long long)__cerbvar_UINT32_MAX);
  P((unsigned long long)__cerbvar_UINT32_MAX);
  P((long long)__cerbvar_UINT32_MAX > 0);
  P((long long)__cerbvar_UINT32_MAX < 0);
  { int x = __cerbvar_UINT32_MAX; P(x); }
  { unsigned x = __cerbvar_UINT32_MAX; P(x); }
  { long x = __cerbvar_UINT32_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT32_MAX; P(x); }
  P(__cerbvar_UINT32_MAX + 1);
  P(__cerbvar_UINT32_MAX - 1);
  P(__cerbvar_UINT32_MAX - 1 > 0);
  P(__cerbvar_UINT32_MAX + 1 > 0);
  P(__cerbvar_UINT32_MAX + 1u);
  P(__cerbvar_UINT32_MAX - 1u);
  P(__cerbvar_UINT32_MAX + 1l);
  P(__cerbvar_UINT32_MAX - 1ul);
  P(__cerbvar_INT64_MIN > 0);
  P(__cerbvar_INT64_MIN < 0);
  P(__cerbvar_INT64_MIN == 0);
  P(__cerbvar_INT64_MIN != 0);
  P(__cerbvar_INT64_MIN >= 0);
  P(__cerbvar_INT64_MIN <= 0);
  P(0 < __cerbvar_INT64_MIN);
  P(0 > __cerbvar_INT64_MIN);
  P(0 == __cerbvar_INT64_MIN);
  P(+__cerbvar_INT64_MIN);
  P(~__cerbvar_INT64_MIN);
  P(!__cerbvar_INT64_MIN);
  P((+__cerbvar_INT64_MIN) > 0);
  P(sizeof(__cerbvar_INT64_MIN));
  P(sizeof(+__cerbvar_INT64_MIN));
  P(TC(__cerbvar_INT64_MIN));
  P(TC(+__cerbvar_INT64_MIN));
  P(TC(-__cerbvar_INT64_MIN));
  P(TC(~__cerbvar_INT64_MIN));
  P((_Bool)__cerbvar_INT64_MIN);
  P((signed char)__cerbvar_INT64_MIN);
  P((unsigned char)__cerbvar_INT64_MIN);
  P((short)__cerbvar_INT64_MIN);
  P((unsigned short)__cerbvar_INT64_MIN);
  P((int)__cerbvar_INT64_MIN);
  P((unsigned)__cerbvar_INT64_MIN);
  P((long)__cerbvar_INT64_MIN);
  P((unsigned long)__cerbvar_INT64_MIN);
  P((long long)__cerbvar_INT64_MIN);
  P((unsigned long long)__cerbvar_INT64_MIN);
  P((long long)__cerbvar_INT64_MIN > 0);
  P((long long)__cerbvar_INT64_MIN < 0);
  { int x = __cerbvar_INT64_MIN; P(x); }
  { unsigned x = __cerbvar_INT64_MIN; P(x); }
  { long x = __cerbvar_INT64_MIN; P(x); }
  { unsigned long x = __cerbvar_INT64_MIN; P(x); }
  P(__cerbvar_INT64_MIN + 1);
  P(__cerbvar_INT64_MIN + 1 > 0);
  P(__cerbvar_INT64_MIN + 1u);
  P(__cerbvar_INT64_MIN + 1l);
  P(__cerbvar_INT64_MIN - 1ul);
  P(__cerbvar_INT64_MAX > 0);
  P(__cerbvar_INT64_MAX < 0);
  P(__cerbvar_INT64_MAX == 0);
  P(__cerbvar_INT64_MAX != 0);
  P(__cerbvar_INT64_MAX >= 0);
  P(__cerbvar_INT64_MAX <= 0);
  P(0 < __cerbvar_INT64_MAX);
  P(0 > __cerbvar_INT64_MAX);
  P(0 == __cerbvar_INT64_MAX);
  P(+__cerbvar_INT64_MAX);
  P(-__cerbvar_INT64_MAX);
  P(~__cerbvar_INT64_MAX);
  P(!__cerbvar_INT64_MAX);
  P((+__cerbvar_INT64_MAX) > 0);
  P(sizeof(__cerbvar_INT64_MAX));
  P(sizeof(+__cerbvar_INT64_MAX));
  P(TC(__cerbvar_INT64_MAX));
  P(TC(+__cerbvar_INT64_MAX));
  P(TC(-__cerbvar_INT64_MAX));
  P(TC(~__cerbvar_INT64_MAX));
  P((_Bool)__cerbvar_INT64_MAX);
  P((signed char)__cerbvar_INT64_MAX);
  P((unsigned char)__cerbvar_INT64_MAX);
  P((short)__cerbvar_INT64_MAX);
  P((unsigned short)__cerbvar_INT64_MAX);
  P((int)__cerbvar_INT64_MAX);
  P((unsigned)__cerbvar_INT64_MAX);
  P((long)__cerbvar_INT64_MAX);
  P((unsigned long)__cerbvar_INT64_MAX);
  P((long long)__cerbvar_INT64_MAX);
  P((unsigned long long)__cerbvar_INT64_MAX);
  P((long long)__cerbvar_INT64_MAX > 0);
  P((long long)__cerbvar_INT64_MAX < 0);
  { int x = __cerbvar_INT64_MAX; P(x); }
  { unsigned x = __cerbvar_INT64_MAX; P(x); }
  { long x = __cerbvar_INT64_MAX; P(x); }
  { unsigned long x = __cerbvar_INT64_MAX; P(x); }
  P(__cerbvar_INT64_MAX - 1);
  P(__cerbvar_INT64_MAX - 1 > 0);
  P(__cerbvar_INT64_MAX - 1u);
  P(__cerbvar_INT64_MAX - 1ul);
  P(__cerbvar_UINT64_MAX > 0);
  P(__cerbvar_UINT64_MAX < 0);
  P(__cerbvar_UINT64_MAX == 0);
  P(__cerbvar_UINT64_MAX != 0);
  P(__cerbvar_UINT64_MAX >= 0);
  P(__cerbvar_UINT64_MAX <= 0);
  P(0 < __cerbvar_UINT64_MAX);
  P(0 > __cerbvar_UINT64_MAX);
  P(0 == __cerbvar_UINT64_MAX);
  P(+__cerbvar_UINT64_MAX);
  P(-__cerbvar_UINT64_MAX);
  P(~__cerbvar_UINT64_MAX);
  P(!__cerbvar_UINT64_MAX);
  P((+__cerbvar_UINT64_MAX) > 0);
  P(sizeof(__cerbvar_UINT64_MAX));
  P(sizeof(+__cerbvar_UINT64_MAX));
  P(TC(__cerbvar_UINT64_MAX));
  P(TC(+__cerbvar_UINT64_MAX));
  P(TC(-__cerbvar_UINT64_MAX));
  P(TC(~__cerbvar_UINT64_MAX));
  P((_Bool)__cerbvar_UINT64_MAX);
  P((signed char)__cerbvar_UINT64_MAX);
  P((unsigned char)__cerbvar_UINT64_MAX);
  P((short)__cerbvar_UINT64_MAX);
  P((unsigned short)__cerbvar_UINT64_MAX);
  P((int)__cerbvar_UINT64_MAX);
  P((unsigned)__cerbvar_UINT64_MAX);
  P((long)__cerbvar_UINT64_MAX);
  P((unsigned long)__cerbvar_UINT64_MAX);
  P((long long)__cerbvar_UINT64_MAX);
  P((unsigned long long)__cerbvar_UINT64_MAX);
  P((long long)__cerbvar_UINT64_MAX > 0);
  P((long long)__cerbvar_UINT64_MAX < 0);
  { int x = __cerbvar_UINT64_MAX; P(x); }
  { unsigned x = __cerbvar_UINT64_MAX; P(x); }
  { long x = __cerbvar_UINT64_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT64_MAX; P(x); }
  P(__cerbvar_UINT64_MAX + 1);
  P(__cerbvar_UINT64_MAX - 1);
  P(__cerbvar_UINT64_MAX - 1 > 0);
  P(__cerbvar_UINT64_MAX + 1 > 0);
  P(__cerbvar_UINT64_MAX + 1u);
  P(__cerbvar_UINT64_MAX - 1u);
  P(__cerbvar_UINT64_MAX + 1l);
  P(__cerbvar_UINT64_MAX - 1ul);
  P(__cerbvar_INT_LEAST8_MIN > 0);
  P(__cerbvar_INT_LEAST8_MIN < 0);
  P(__cerbvar_INT_LEAST8_MIN == 0);
  P(__cerbvar_INT_LEAST8_MIN != 0);
  P(__cerbvar_INT_LEAST8_MIN >= 0);
  P(__cerbvar_INT_LEAST8_MIN <= 0);
  P(0 < __cerbvar_INT_LEAST8_MIN);
  P(0 > __cerbvar_INT_LEAST8_MIN);
  P(0 == __cerbvar_INT_LEAST8_MIN);
  P(+__cerbvar_INT_LEAST8_MIN);
  P(-__cerbvar_INT_LEAST8_MIN);
  P(~__cerbvar_INT_LEAST8_MIN);
  P(!__cerbvar_INT_LEAST8_MIN);
  P((+__cerbvar_INT_LEAST8_MIN) > 0);
  P(sizeof(__cerbvar_INT_LEAST8_MIN));
  P(sizeof(+__cerbvar_INT_LEAST8_MIN));
  P(TC(__cerbvar_INT_LEAST8_MIN));
  P(TC(+__cerbvar_INT_LEAST8_MIN));
  P(TC(-__cerbvar_INT_LEAST8_MIN));
  P(TC(~__cerbvar_INT_LEAST8_MIN));
  P((_Bool)__cerbvar_INT_LEAST8_MIN);
  P((signed char)__cerbvar_INT_LEAST8_MIN);
  P((unsigned char)__cerbvar_INT_LEAST8_MIN);
  P((short)__cerbvar_INT_LEAST8_MIN);
  P((unsigned short)__cerbvar_INT_LEAST8_MIN);
  P((int)__cerbvar_INT_LEAST8_MIN);
  P((unsigned)__cerbvar_INT_LEAST8_MIN);
  P((long)__cerbvar_INT_LEAST8_MIN);
  P((unsigned long)__cerbvar_INT_LEAST8_MIN);
  P((long long)__cerbvar_INT_LEAST8_MIN);
  P((unsigned long long)__cerbvar_INT_LEAST8_MIN);
  P((long long)__cerbvar_INT_LEAST8_MIN > 0);
  P((long long)__cerbvar_INT_LEAST8_MIN < 0);
  { int x = __cerbvar_INT_LEAST8_MIN; P(x); }
  { unsigned x = __cerbvar_INT_LEAST8_MIN; P(x); }
  { long x = __cerbvar_INT_LEAST8_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST8_MIN; P(x); }
  P(__cerbvar_INT_LEAST8_MIN + 1);
  P(__cerbvar_INT_LEAST8_MIN - 1);
  P(__cerbvar_INT_LEAST8_MIN - 1 > 0);
  P(__cerbvar_INT_LEAST8_MIN + 1 > 0);
  P(__cerbvar_INT_LEAST8_MIN + 1u);
  P(__cerbvar_INT_LEAST8_MIN - 1u);
  P(__cerbvar_INT_LEAST8_MIN + 1l);
  P(__cerbvar_INT_LEAST8_MIN - 1ul);
  P(__cerbvar_INT_LEAST8_MAX > 0);
  P(__cerbvar_INT_LEAST8_MAX < 0);
  P(__cerbvar_INT_LEAST8_MAX == 0);
  P(__cerbvar_INT_LEAST8_MAX != 0);
  P(__cerbvar_INT_LEAST8_MAX >= 0);
  P(__cerbvar_INT_LEAST8_MAX <= 0);
  P(0 < __cerbvar_INT_LEAST8_MAX);
  P(0 > __cerbvar_INT_LEAST8_MAX);
  P(0 == __cerbvar_INT_LEAST8_MAX);
  P(+__cerbvar_INT_LEAST8_MAX);
  P(-__cerbvar_INT_LEAST8_MAX);
  P(~__cerbvar_INT_LEAST8_MAX);
  P(!__cerbvar_INT_LEAST8_MAX);
  P((+__cerbvar_INT_LEAST8_MAX) > 0);
  P(sizeof(__cerbvar_INT_LEAST8_MAX));
  P(sizeof(+__cerbvar_INT_LEAST8_MAX));
  P(TC(__cerbvar_INT_LEAST8_MAX));
  P(TC(+__cerbvar_INT_LEAST8_MAX));
  P(TC(-__cerbvar_INT_LEAST8_MAX));
  P(TC(~__cerbvar_INT_LEAST8_MAX));
  P((_Bool)__cerbvar_INT_LEAST8_MAX);
  P((signed char)__cerbvar_INT_LEAST8_MAX);
  P((unsigned char)__cerbvar_INT_LEAST8_MAX);
  P((short)__cerbvar_INT_LEAST8_MAX);
  P((unsigned short)__cerbvar_INT_LEAST8_MAX);
  P((int)__cerbvar_INT_LEAST8_MAX);
  P((unsigned)__cerbvar_INT_LEAST8_MAX);
  P((long)__cerbvar_INT_LEAST8_MAX);
  P((unsigned long)__cerbvar_INT_LEAST8_MAX);
  P((long long)__cerbvar_INT_LEAST8_MAX);
  P((unsigned long long)__cerbvar_INT_LEAST8_MAX);
  P((long long)__cerbvar_INT_LEAST8_MAX > 0);
  P((long long)__cerbvar_INT_LEAST8_MAX < 0);
  { int x = __cerbvar_INT_LEAST8_MAX; P(x); }
  { unsigned x = __cerbvar_INT_LEAST8_MAX; P(x); }
  { long x = __cerbvar_INT_LEAST8_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST8_MAX; P(x); }
  P(__cerbvar_INT_LEAST8_MAX + 1);
  P(__cerbvar_INT_LEAST8_MAX - 1);
  P(__cerbvar_INT_LEAST8_MAX - 1 > 0);
  P(__cerbvar_INT_LEAST8_MAX + 1 > 0);
  P(__cerbvar_INT_LEAST8_MAX + 1u);
  P(__cerbvar_INT_LEAST8_MAX - 1u);
  P(__cerbvar_INT_LEAST8_MAX + 1l);
  P(__cerbvar_INT_LEAST8_MAX - 1ul);
  P(__cerbvar_UINT_LEAST8_MAX > 0);
  P(__cerbvar_UINT_LEAST8_MAX < 0);
  P(__cerbvar_UINT_LEAST8_MAX == 0);
  P(__cerbvar_UINT_LEAST8_MAX != 0);
  P(__cerbvar_UINT_LEAST8_MAX >= 0);
  P(__cerbvar_UINT_LEAST8_MAX <= 0);
  P(0 < __cerbvar_UINT_LEAST8_MAX);
  P(0 > __cerbvar_UINT_LEAST8_MAX);
  P(0 == __cerbvar_UINT_LEAST8_MAX);
  P(+__cerbvar_UINT_LEAST8_MAX);
  P(-__cerbvar_UINT_LEAST8_MAX);
  P(~__cerbvar_UINT_LEAST8_MAX);
  P(!__cerbvar_UINT_LEAST8_MAX);
  P((+__cerbvar_UINT_LEAST8_MAX) > 0);
  P(sizeof(__cerbvar_UINT_LEAST8_MAX));
  P(sizeof(+__cerbvar_UINT_LEAST8_MAX));
  P(TC(__cerbvar_UINT_LEAST8_MAX));
  P(TC(+__cerbvar_UINT_LEAST8_MAX));
  P(TC(-__cerbvar_UINT_LEAST8_MAX));
  P(TC(~__cerbvar_UINT_LEAST8_MAX));
  P((_Bool)__cerbvar_UINT_LEAST8_MAX);
  P((signed char)__cerbvar_UINT_LEAST8_MAX);
  P((unsigned char)__cerbvar_UINT_LEAST8_MAX);
  P((short)__cerbvar_UINT_LEAST8_MAX);
  P((unsigned short)__cerbvar_UINT_LEAST8_MAX);
  P((int)__cerbvar_UINT_LEAST8_MAX);
  P((unsigned)__cerbvar_UINT_LEAST8_MAX);
  P((long)__cerbvar_UINT_LEAST8_MAX);
  P((unsigned long)__cerbvar_UINT_LEAST8_MAX);
  P((long long)__cerbvar_UINT_LEAST8_MAX);
  P((unsigned long long)__cerbvar_UINT_LEAST8_MAX);
  P((long long)__cerbvar_UINT_LEAST8_MAX > 0);
  P((long long)__cerbvar_UINT_LEAST8_MAX < 0);
  { int x = __cerbvar_UINT_LEAST8_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_LEAST8_MAX; P(x); }
  { long x = __cerbvar_UINT_LEAST8_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_LEAST8_MAX; P(x); }
  P(__cerbvar_UINT_LEAST8_MAX + 1);
  P(__cerbvar_UINT_LEAST8_MAX - 1);
  P(__cerbvar_UINT_LEAST8_MAX - 1 > 0);
  P(__cerbvar_UINT_LEAST8_MAX + 1 > 0);
  P(__cerbvar_UINT_LEAST8_MAX + 1u);
  P(__cerbvar_UINT_LEAST8_MAX - 1u);
  P(__cerbvar_UINT_LEAST8_MAX + 1l);
  P(__cerbvar_UINT_LEAST8_MAX - 1ul);
  P(__cerbvar_INT_LEAST16_MIN > 0);
  P(__cerbvar_INT_LEAST16_MIN < 0);
  P(__cerbvar_INT_LEAST16_MIN == 0);
  P(__cerbvar_INT_LEAST16_MIN != 0);
  P(__cerbvar_INT_LEAST16_MIN >= 0);
  P(__cerbvar_INT_LEAST16_MIN <= 0);
  P(0 < __cerbvar_INT_LEAST16_MIN);
  P(0 > __cerbvar_INT_LEAST16_MIN);
  P(0 == __cerbvar_INT_LEAST16_MIN);
  P(+__cerbvar_INT_LEAST16_MIN);
  P(-__cerbvar_INT_LEAST16_MIN);
  P(~__cerbvar_INT_LEAST16_MIN);
  P(!__cerbvar_INT_LEAST16_MIN);
  P((+__cerbvar_INT_LEAST16_MIN) > 0);
  P(sizeof(__cerbvar_INT_LEAST16_MIN));
  P(sizeof(+__cerbvar_INT_LEAST16_MIN));
  P(TC(__cerbvar_INT_LEAST16_MIN));
  P(TC(+__cerbvar_INT_LEAST16_MIN));
  P(TC(-__cerbvar_INT_LEAST16_MIN));
  P(TC(~__cerbvar_INT_LEAST16_MIN));
  P((_Bool)__cerbvar_INT_LEAST16_MIN);
  P((signed char)__cerbvar_INT_LEAST16_MIN);
  P((unsigned char)__cerbvar_INT_LEAST16_MIN);
  P((short)__cerbvar_INT_LEAST16_MIN);
  P((unsigned short)__cerbvar_INT_LEAST16_MIN);
  P((int)__cerbvar_INT_LEAST16_MIN);
  P((unsigned)__cerbvar_INT_LEAST16_MIN);
  P((long)__cerbvar_INT_LEAST16_MIN);
  P((unsigned long)__cerbvar_INT_LEAST16_MIN);
  P((long long)__cerbvar_INT_LEAST16_MIN);
  P((unsigned long long)__cerbvar_INT_LEAST16_MIN);
  P((long long)__cerbvar_INT_LEAST16_MIN > 0);
  P((long long)__cerbvar_INT_LEAST16_MIN < 0);
  { int x = __cerbvar_INT_LEAST16_MIN; P(x); }
  { unsigned x = __cerbvar_INT_LEAST16_MIN; P(x); }
  { long x = __cerbvar_INT_LEAST16_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST16_MIN; P(x); }
  P(__cerbvar_INT_LEAST16_MIN + 1);
  P(__cerbvar_INT_LEAST16_MIN - 1);
  P(__cerbvar_INT_LEAST16_MIN - 1 > 0);
  P(__cerbvar_INT_LEAST16_MIN + 1 > 0);
  P(__cerbvar_INT_LEAST16_MIN + 1u);
  P(__cerbvar_INT_LEAST16_MIN - 1u);
  P(__cerbvar_INT_LEAST16_MIN + 1l);
  P(__cerbvar_INT_LEAST16_MIN - 1ul);
  P(__cerbvar_INT_LEAST16_MAX > 0);
  P(__cerbvar_INT_LEAST16_MAX < 0);
  P(__cerbvar_INT_LEAST16_MAX == 0);
  P(__cerbvar_INT_LEAST16_MAX != 0);
  P(__cerbvar_INT_LEAST16_MAX >= 0);
  P(__cerbvar_INT_LEAST16_MAX <= 0);
  P(0 < __cerbvar_INT_LEAST16_MAX);
  P(0 > __cerbvar_INT_LEAST16_MAX);
  P(0 == __cerbvar_INT_LEAST16_MAX);
  P(+__cerbvar_INT_LEAST16_MAX);
  P(-__cerbvar_INT_LEAST16_MAX);
  P(~__cerbvar_INT_LEAST16_MAX);
  P(!__cerbvar_INT_LEAST16_MAX);
  P((+__cerbvar_INT_LEAST16_MAX) > 0);
  P(sizeof(__cerbvar_INT_LEAST16_MAX));
  P(sizeof(+__cerbvar_INT_LEAST16_MAX));
  P(TC(__cerbvar_INT_LEAST16_MAX));
  P(TC(+__cerbvar_INT_LEAST16_MAX));
  P(TC(-__cerbvar_INT_LEAST16_MAX));
  P(TC(~__cerbvar_INT_LEAST16_MAX));
  P((_Bool)__cerbvar_INT_LEAST16_MAX);
  P((signed char)__cerbvar_INT_LEAST16_MAX);
  P((unsigned char)__cerbvar_INT_LEAST16_MAX);
  P((short)__cerbvar_INT_LEAST16_MAX);
  P((unsigned short)__cerbvar_INT_LEAST16_MAX);
  P((int)__cerbvar_INT_LEAST16_MAX);
  P((unsigned)__cerbvar_INT_LEAST16_MAX);
  P((long)__cerbvar_INT_LEAST16_MAX);
  P((unsigned long)__cerbvar_INT_LEAST16_MAX);
  P((long long)__cerbvar_INT_LEAST16_MAX);
  P((unsigned long long)__cerbvar_INT_LEAST16_MAX);
  P((long long)__cerbvar_INT_LEAST16_MAX > 0);
  P((long long)__cerbvar_INT_LEAST16_MAX < 0);
  { int x = __cerbvar_INT_LEAST16_MAX; P(x); }
  { unsigned x = __cerbvar_INT_LEAST16_MAX; P(x); }
  { long x = __cerbvar_INT_LEAST16_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST16_MAX; P(x); }
  P(__cerbvar_INT_LEAST16_MAX + 1);
  P(__cerbvar_INT_LEAST16_MAX - 1);
  P(__cerbvar_INT_LEAST16_MAX - 1 > 0);
  P(__cerbvar_INT_LEAST16_MAX + 1 > 0);
  P(__cerbvar_INT_LEAST16_MAX + 1u);
  P(__cerbvar_INT_LEAST16_MAX - 1u);
  P(__cerbvar_INT_LEAST16_MAX + 1l);
  P(__cerbvar_INT_LEAST16_MAX - 1ul);
  P(__cerbvar_UINT_LEAST16_MAX > 0);
  P(__cerbvar_UINT_LEAST16_MAX < 0);
  P(__cerbvar_UINT_LEAST16_MAX == 0);
  P(__cerbvar_UINT_LEAST16_MAX != 0);
  P(__cerbvar_UINT_LEAST16_MAX >= 0);
  P(__cerbvar_UINT_LEAST16_MAX <= 0);
  P(0 < __cerbvar_UINT_LEAST16_MAX);
  P(0 > __cerbvar_UINT_LEAST16_MAX);
  P(0 == __cerbvar_UINT_LEAST16_MAX);
  P(+__cerbvar_UINT_LEAST16_MAX);
  P(-__cerbvar_UINT_LEAST16_MAX);
  P(~__cerbvar_UINT_LEAST16_MAX);
  P(!__cerbvar_UINT_LEAST16_MAX);
  P((+__cerbvar_UINT_LEAST16_MAX) > 0);
  P(sizeof(__cerbvar_UINT_LEAST16_MAX));
  P(sizeof(+__cerbvar_UINT_LEAST16_MAX));
  P(TC(__cerbvar_UINT_LEAST16_MAX));
  P(TC(+__cerbvar_UINT_LEAST16_MAX));
  P(TC(-__cerbvar_UINT_LEAST16_MAX));
  P(TC(~__cerbvar_UINT_LEAST16_MAX));
  P((_Bool)__cerbvar_UINT_LEAST16_MAX);
  P((signed char)__cerbvar_UINT_LEAST16_MAX);
  P((unsigned char)__cerbvar_UINT_LEAST16_MAX);
  P((short)__cerbvar_UINT_LEAST16_MAX);
  P((unsigned short)__cerbvar_UINT_LEAST16_MAX);
  P((int)__cerbvar_UINT_LEAST16_MAX);
  P((unsigned)__cerbvar_UINT_LEAST16_MAX);
  P((long)__cerbvar_UINT_LEAST16_MAX);
  P((unsigned long)__cerbvar_UINT_LEAST16_MAX);
  P((long long)__cerbvar_UINT_LEAST16_MAX);
  P((unsigned long long)__cerbvar_UINT_LEAST16_MAX);
  P((long long)__cerbvar_UINT_LEAST16_MAX > 0);
  P((long long)__cerbvar_UINT_LEAST16_MAX < 0);
  { int x = __cerbvar_UINT_LEAST16_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_LEAST16_MAX; P(x); }
  { long x = __cerbvar_UINT_LEAST16_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_LEAST16_MAX; P(x); }
  P(__cerbvar_UINT_LEAST16_MAX + 1);
  P(__cerbvar_UINT_LEAST16_MAX - 1);
  P(__cerbvar_UINT_LEAST16_MAX - 1 > 0);
  P(__cerbvar_UINT_LEAST16_MAX + 1 > 0);
  P(__cerbvar_UINT_LEAST16_MAX + 1u);
  P(__cerbvar_UINT_LEAST16_MAX - 1u);
  P(__cerbvar_UINT_LEAST16_MAX + 1l);
  P(__cerbvar_UINT_LEAST16_MAX - 1ul);
  P(__cerbvar_INT_LEAST32_MIN > 0);
  P(__cerbvar_INT_LEAST32_MIN < 0);
  P(__cerbvar_INT_LEAST32_MIN == 0);
  P(__cerbvar_INT_LEAST32_MIN != 0);
  P(__cerbvar_INT_LEAST32_MIN >= 0);
  P(__cerbvar_INT_LEAST32_MIN <= 0);
  P(0 < __cerbvar_INT_LEAST32_MIN);
  P(0 > __cerbvar_INT_LEAST32_MIN);
  P(0 == __cerbvar_INT_LEAST32_MIN);
  P(+__cerbvar_INT_LEAST32_MIN);
  P(~__cerbvar_INT_LEAST32_MIN);
  P(!__cerbvar_INT_LEAST32_MIN);
  P((+__cerbvar_INT_LEAST32_MIN) > 0);
  P(sizeof(__cerbvar_INT_LEAST32_MIN));
  P(sizeof(+__cerbvar_INT_LEAST32_MIN));
  P(TC(__cerbvar_INT_LEAST32_MIN));
  P(TC(+__cerbvar_INT_LEAST32_MIN));
  P(TC(-__cerbvar_INT_LEAST32_MIN));
  P(TC(~__cerbvar_INT_LEAST32_MIN));
  P((_Bool)__cerbvar_INT_LEAST32_MIN);
  P((signed char)__cerbvar_INT_LEAST32_MIN);
  P((unsigned char)__cerbvar_INT_LEAST32_MIN);
  P((short)__cerbvar_INT_LEAST32_MIN);
  P((unsigned short)__cerbvar_INT_LEAST32_MIN);
  P((int)__cerbvar_INT_LEAST32_MIN);
  P((unsigned)__cerbvar_INT_LEAST32_MIN);
  P((long)__cerbvar_INT_LEAST32_MIN);
  P((unsigned long)__cerbvar_INT_LEAST32_MIN);
  P((long long)__cerbvar_INT_LEAST32_MIN);
  P((unsigned long long)__cerbvar_INT_LEAST32_MIN);
  P((long long)__cerbvar_INT_LEAST32_MIN > 0);
  P((long long)__cerbvar_INT_LEAST32_MIN < 0);
  { int x = __cerbvar_INT_LEAST32_MIN; P(x); }
  { unsigned x = __cerbvar_INT_LEAST32_MIN; P(x); }
  { long x = __cerbvar_INT_LEAST32_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST32_MIN; P(x); }
  P(__cerbvar_INT_LEAST32_MIN + 1);
  P(__cerbvar_INT_LEAST32_MIN + 1 > 0);
  P(__cerbvar_INT_LEAST32_MIN + 1u);
  P(__cerbvar_INT_LEAST32_MIN - 1u);
  P(__cerbvar_INT_LEAST32_MIN + 1l);
  P(__cerbvar_INT_LEAST32_MIN - 1ul);
  P(__cerbvar_INT_LEAST32_MAX > 0);
  P(__cerbvar_INT_LEAST32_MAX < 0);
  P(__cerbvar_INT_LEAST32_MAX == 0);
  P(__cerbvar_INT_LEAST32_MAX != 0);
  P(__cerbvar_INT_LEAST32_MAX >= 0);
  P(__cerbvar_INT_LEAST32_MAX <= 0);
  P(0 < __cerbvar_INT_LEAST32_MAX);
  P(0 > __cerbvar_INT_LEAST32_MAX);
  P(0 == __cerbvar_INT_LEAST32_MAX);
  P(+__cerbvar_INT_LEAST32_MAX);
  P(-__cerbvar_INT_LEAST32_MAX);
  P(~__cerbvar_INT_LEAST32_MAX);
  P(!__cerbvar_INT_LEAST32_MAX);
  P((+__cerbvar_INT_LEAST32_MAX) > 0);
  P(sizeof(__cerbvar_INT_LEAST32_MAX));
  P(sizeof(+__cerbvar_INT_LEAST32_MAX));
  P(TC(__cerbvar_INT_LEAST32_MAX));
  P(TC(+__cerbvar_INT_LEAST32_MAX));
  P(TC(-__cerbvar_INT_LEAST32_MAX));
  P(TC(~__cerbvar_INT_LEAST32_MAX));
  P((_Bool)__cerbvar_INT_LEAST32_MAX);
  P((signed char)__cerbvar_INT_LEAST32_MAX);
  P((unsigned char)__cerbvar_INT_LEAST32_MAX);
  P((short)__cerbvar_INT_LEAST32_MAX);
  P((unsigned short)__cerbvar_INT_LEAST32_MAX);
  P((int)__cerbvar_INT_LEAST32_MAX);
  P((unsigned)__cerbvar_INT_LEAST32_MAX);
  P((long)__cerbvar_INT_LEAST32_MAX);
  P((unsigned long)__cerbvar_INT_LEAST32_MAX);
  P((long long)__cerbvar_INT_LEAST32_MAX);
  P((unsigned long long)__cerbvar_INT_LEAST32_MAX);
  P((long long)__cerbvar_INT_LEAST32_MAX > 0);
  P((long long)__cerbvar_INT_LEAST32_MAX < 0);
  { int x = __cerbvar_INT_LEAST32_MAX; P(x); }
  { unsigned x = __cerbvar_INT_LEAST32_MAX; P(x); }
  { long x = __cerbvar_INT_LEAST32_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST32_MAX; P(x); }
  P(__cerbvar_INT_LEAST32_MAX - 1);
  P(__cerbvar_INT_LEAST32_MAX - 1 > 0);
  P(__cerbvar_INT_LEAST32_MAX + 1u);
  P(__cerbvar_INT_LEAST32_MAX - 1u);
  P(__cerbvar_INT_LEAST32_MAX + 1l);
  P(__cerbvar_INT_LEAST32_MAX - 1ul);
  P(__cerbvar_UINT_LEAST32_MAX > 0);
  P(__cerbvar_UINT_LEAST32_MAX < 0);
  P(__cerbvar_UINT_LEAST32_MAX == 0);
  P(__cerbvar_UINT_LEAST32_MAX != 0);
  P(__cerbvar_UINT_LEAST32_MAX >= 0);
  P(__cerbvar_UINT_LEAST32_MAX <= 0);
  P(0 < __cerbvar_UINT_LEAST32_MAX);
  P(0 > __cerbvar_UINT_LEAST32_MAX);
  P(0 == __cerbvar_UINT_LEAST32_MAX);
  P(+__cerbvar_UINT_LEAST32_MAX);
  P(-__cerbvar_UINT_LEAST32_MAX);
  P(~__cerbvar_UINT_LEAST32_MAX);
  P(!__cerbvar_UINT_LEAST32_MAX);
  P((+__cerbvar_UINT_LEAST32_MAX) > 0);
  P(sizeof(__cerbvar_UINT_LEAST32_MAX));
  P(sizeof(+__cerbvar_UINT_LEAST32_MAX));
  P(TC(__cerbvar_UINT_LEAST32_MAX));
  P(TC(+__cerbvar_UINT_LEAST32_MAX));
  P(TC(-__cerbvar_UINT_LEAST32_MAX));
  P(TC(~__cerbvar_UINT_LEAST32_MAX));
  P((_Bool)__cerbvar_UINT_LEAST32_MAX);
  P((signed char)__cerbvar_UINT_LEAST32_MAX);
  P((unsigned char)__cerbvar_UINT_LEAST32_MAX);
  P((short)__cerbvar_UINT_LEAST32_MAX);
  P((unsigned short)__cerbvar_UINT_LEAST32_MAX);
  P((int)__cerbvar_UINT_LEAST32_MAX);
  P((unsigned)__cerbvar_UINT_LEAST32_MAX);
  P((long)__cerbvar_UINT_LEAST32_MAX);
  P((unsigned long)__cerbvar_UINT_LEAST32_MAX);
  P((long long)__cerbvar_UINT_LEAST32_MAX);
  P((unsigned long long)__cerbvar_UINT_LEAST32_MAX);
  P((long long)__cerbvar_UINT_LEAST32_MAX > 0);
  P((long long)__cerbvar_UINT_LEAST32_MAX < 0);
  { int x = __cerbvar_UINT_LEAST32_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_LEAST32_MAX; P(x); }
  { long x = __cerbvar_UINT_LEAST32_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_LEAST32_MAX; P(x); }
  P(__cerbvar_UINT_LEAST32_MAX + 1);
  P(__cerbvar_UINT_LEAST32_MAX - 1);
  P(__cerbvar_UINT_LEAST32_MAX - 1 > 0);
  P(__cerbvar_UINT_LEAST32_MAX + 1 > 0);
  P(__cerbvar_UINT_LEAST32_MAX + 1u);
  P(__cerbvar_UINT_LEAST32_MAX - 1u);
  P(__cerbvar_UINT_LEAST32_MAX + 1l);
  P(__cerbvar_UINT_LEAST32_MAX - 1ul);
  P(__cerbvar_INT_LEAST64_MIN > 0);
  P(__cerbvar_INT_LEAST64_MIN < 0);
  P(__cerbvar_INT_LEAST64_MIN == 0);
  P(__cerbvar_INT_LEAST64_MIN != 0);
  P(__cerbvar_INT_LEAST64_MIN >= 0);
  P(__cerbvar_INT_LEAST64_MIN <= 0);
  P(0 < __cerbvar_INT_LEAST64_MIN);
  P(0 > __cerbvar_INT_LEAST64_MIN);
  P(0 == __cerbvar_INT_LEAST64_MIN);
  P(+__cerbvar_INT_LEAST64_MIN);
  P(~__cerbvar_INT_LEAST64_MIN);
  P(!__cerbvar_INT_LEAST64_MIN);
  P((+__cerbvar_INT_LEAST64_MIN) > 0);
  P(sizeof(__cerbvar_INT_LEAST64_MIN));
  P(sizeof(+__cerbvar_INT_LEAST64_MIN));
  P(TC(__cerbvar_INT_LEAST64_MIN));
  P(TC(+__cerbvar_INT_LEAST64_MIN));
  P(TC(-__cerbvar_INT_LEAST64_MIN));
  P(TC(~__cerbvar_INT_LEAST64_MIN));
  P((_Bool)__cerbvar_INT_LEAST64_MIN);
  P((signed char)__cerbvar_INT_LEAST64_MIN);
  P((unsigned char)__cerbvar_INT_LEAST64_MIN);
  P((short)__cerbvar_INT_LEAST64_MIN);
  P((unsigned short)__cerbvar_INT_LEAST64_MIN);
  P((int)__cerbvar_INT_LEAST64_MIN);
  P((unsigned)__cerbvar_INT_LEAST64_MIN);
  P((long)__cerbvar_INT_LEAST64_MIN);
  P((unsigned long)__cerbvar_INT_LEAST64_MIN);
  P((long long)__cerbvar_INT_LEAST64_MIN);
  P((unsigned long long)__cerbvar_INT_LEAST64_MIN);
  P((long long)__cerbvar_INT_LEAST64_MIN > 0);
  P((long long)__cerbvar_INT_LEAST64_MIN < 0);
  { int x = __cerbvar_INT_LEAST64_MIN; P(x); }
  { unsigned x = __cerbvar_INT_LEAST64_MIN; P(x); }
  { long x = __cerbvar_INT_LEAST64_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST64_MIN; P(x); }
  P(__cerbvar_INT_LEAST64_MIN + 1);
  P(__cerbvar_INT_LEAST64_MIN + 1 > 0);
  P(__cerbvar_INT_LEAST64_MIN + 1u);
  P(__cerbvar_INT_LEAST64_MIN + 1l);
  P(__cerbvar_INT_LEAST64_MIN - 1ul);
  P(__cerbvar_INT_LEAST64_MAX > 0);
  P(__cerbvar_INT_LEAST64_MAX < 0);
  P(__cerbvar_INT_LEAST64_MAX == 0);
  P(__cerbvar_INT_LEAST64_MAX != 0);
  P(__cerbvar_INT_LEAST64_MAX >= 0);
  P(__cerbvar_INT_LEAST64_MAX <= 0);
  P(0 < __cerbvar_INT_LEAST64_MAX);
  P(0 > __cerbvar_INT_LEAST64_MAX);
  P(0 == __cerbvar_INT_LEAST64_MAX);
  P(+__cerbvar_INT_LEAST64_MAX);
  P(-__cerbvar_INT_LEAST64_MAX);
  P(~__cerbvar_INT_LEAST64_MAX);
  P(!__cerbvar_INT_LEAST64_MAX);
  P((+__cerbvar_INT_LEAST64_MAX) > 0);
  P(sizeof(__cerbvar_INT_LEAST64_MAX));
  P(sizeof(+__cerbvar_INT_LEAST64_MAX));
  P(TC(__cerbvar_INT_LEAST64_MAX));
  P(TC(+__cerbvar_INT_LEAST64_MAX));
  P(TC(-__cerbvar_INT_LEAST64_MAX));
  P(TC(~__cerbvar_INT_LEAST64_MAX));
  P((_Bool)__cerbvar_INT_LEAST64_MAX);
  P((signed char)__cerbvar_INT_LEAST64_MAX);
  P((unsigned char)__cerbvar_INT_LEAST64_MAX);
  P((short)__cerbvar_INT_LEAST64_MAX);
  P((unsigned short)__cerbvar_INT_LEAST64_MAX);
  P((int)__cerbvar_INT_LEAST64_MAX);
  P((unsigned)__cerbvar_INT_LEAST64_MAX);
  P((long)__cerbvar_INT_LEAST64_MAX);
  P((unsigned long)__cerbvar_INT_LEAST64_MAX);
  P((long long)__cerbvar_INT_LEAST64_MAX);
  P((unsigned long long)__cerbvar_INT_LEAST64_MAX);
  P((long long)__cerbvar_INT_LEAST64_MAX > 0);
  P((long long)__cerbvar_INT_LEAST64_MAX < 0);
  { int x = __cerbvar_INT_LEAST64_MAX; P(x); }
  { unsigned x = __cerbvar_INT_LEAST64_MAX; P(x); }
  { long x = __cerbvar_INT_LEAST64_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_LEAST64_MAX; P(x); }
  P(__cerbvar_INT_LEAST64_MAX - 1);
  P(__cerbvar_INT_LEAST64_MAX - 1 > 0);
  P(__cerbvar_INT_LEAST64_MAX - 1u);
  P(__cerbvar_INT_LEAST64_MAX - 1ul);
  P(__cerbvar_UINT_LEAST64_MAX > 0);
  P(__cerbvar_UINT_LEAST64_MAX < 0);
  P(__cerbvar_UINT_LEAST64_MAX == 0);
  P(__cerbvar_UINT_LEAST64_MAX != 0);
  P(__cerbvar_UINT_LEAST64_MAX >= 0);
  P(__cerbvar_UINT_LEAST64_MAX <= 0);
  P(0 < __cerbvar_UINT_LEAST64_MAX);
  P(0 > __cerbvar_UINT_LEAST64_MAX);
  P(0 == __cerbvar_UINT_LEAST64_MAX);
  P(+__cerbvar_UINT_LEAST64_MAX);
  P(-__cerbvar_UINT_LEAST64_MAX);
  P(~__cerbvar_UINT_LEAST64_MAX);
  P(!__cerbvar_UINT_LEAST64_MAX);
  P((+__cerbvar_UINT_LEAST64_MAX) > 0);
  P(sizeof(__cerbvar_UINT_LEAST64_MAX));
  P(sizeof(+__cerbvar_UINT_LEAST64_MAX));
  P(TC(__cerbvar_UINT_LEAST64_MAX));
  P(TC(+__cerbvar_UINT_LEAST64_MAX));
  P(TC(-__cerbvar_UINT_LEAST64_MAX));
  P(TC(~__cerbvar_UINT_LEAST64_MAX));
  P((_Bool)__cerbvar_UINT_LEAST64_MAX);
  P((signed char)__cerbvar_UINT_LEAST64_MAX);
  P((unsigned char)__cerbvar_UINT_LEAST64_MAX);
  P((short)__cerbvar_UINT_LEAST64_MAX);
  P((unsigned short)__cerbvar_UINT_LEAST64_MAX);
  P((int)__cerbvar_UINT_LEAST64_MAX);
  P((unsigned)__cerbvar_UINT_LEAST64_MAX);
  P((long)__cerbvar_UINT_LEAST64_MAX);
  P((unsigned long)__cerbvar_UINT_LEAST64_MAX);
  P((long long)__cerbvar_UINT_LEAST64_MAX);
  P((unsigned long long)__cerbvar_UINT_LEAST64_MAX);
  P((long long)__cerbvar_UINT_LEAST64_MAX > 0);
  P((long long)__cerbvar_UINT_LEAST64_MAX < 0);
  { int x = __cerbvar_UINT_LEAST64_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_LEAST64_MAX; P(x); }
  { long x = __cerbvar_UINT_LEAST64_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_LEAST64_MAX; P(x); }
  P(__cerbvar_UINT_LEAST64_MAX + 1);
  P(__cerbvar_UINT_LEAST64_MAX - 1);
  P(__cerbvar_UINT_LEAST64_MAX - 1 > 0);
  P(__cerbvar_UINT_LEAST64_MAX + 1 > 0);
  P(__cerbvar_UINT_LEAST64_MAX + 1u);
  P(__cerbvar_UINT_LEAST64_MAX - 1u);
  P(__cerbvar_UINT_LEAST64_MAX + 1l);
  P(__cerbvar_UINT_LEAST64_MAX - 1ul);
  P(__cerbvar_INT_FAST8_MIN > 0);
  P(__cerbvar_INT_FAST8_MIN < 0);
  P(__cerbvar_INT_FAST8_MIN == 0);
  P(__cerbvar_INT_FAST8_MIN != 0);
  P(__cerbvar_INT_FAST8_MIN >= 0);
  P(__cerbvar_INT_FAST8_MIN <= 0);
  P(0 < __cerbvar_INT_FAST8_MIN);
  P(0 > __cerbvar_INT_FAST8_MIN);
  P(0 == __cerbvar_INT_FAST8_MIN);
  P(+__cerbvar_INT_FAST8_MIN);
  P(-__cerbvar_INT_FAST8_MIN);
  P(~__cerbvar_INT_FAST8_MIN);
  P(!__cerbvar_INT_FAST8_MIN);
  P((+__cerbvar_INT_FAST8_MIN) > 0);
  P(sizeof(__cerbvar_INT_FAST8_MIN));
  P(sizeof(+__cerbvar_INT_FAST8_MIN));
  P(TC(__cerbvar_INT_FAST8_MIN));
  P(TC(+__cerbvar_INT_FAST8_MIN));
  P(TC(-__cerbvar_INT_FAST8_MIN));
  P(TC(~__cerbvar_INT_FAST8_MIN));
  P((_Bool)__cerbvar_INT_FAST8_MIN);
  P((signed char)__cerbvar_INT_FAST8_MIN);
  P((unsigned char)__cerbvar_INT_FAST8_MIN);
  P((short)__cerbvar_INT_FAST8_MIN);
  P((unsigned short)__cerbvar_INT_FAST8_MIN);
  P((int)__cerbvar_INT_FAST8_MIN);
  P((unsigned)__cerbvar_INT_FAST8_MIN);
  P((long)__cerbvar_INT_FAST8_MIN);
  P((unsigned long)__cerbvar_INT_FAST8_MIN);
  P((long long)__cerbvar_INT_FAST8_MIN);
  P((unsigned long long)__cerbvar_INT_FAST8_MIN);
  P((long long)__cerbvar_INT_FAST8_MIN > 0);
  P((long long)__cerbvar_INT_FAST8_MIN < 0);
  { int x = __cerbvar_INT_FAST8_MIN; P(x); }
  { unsigned x = __cerbvar_INT_FAST8_MIN; P(x); }
  { long x = __cerbvar_INT_FAST8_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_FAST8_MIN; P(x); }
  P(__cerbvar_INT_FAST8_MIN + 1);
  P(__cerbvar_INT_FAST8_MIN - 1);
  P(__cerbvar_INT_FAST8_MIN - 1 > 0);
  P(__cerbvar_INT_FAST8_MIN + 1 > 0);
  P(__cerbvar_INT_FAST8_MIN + 1u);
  P(__cerbvar_INT_FAST8_MIN - 1u);
  P(__cerbvar_INT_FAST8_MIN + 1l);
  P(__cerbvar_INT_FAST8_MIN - 1ul);
  P(__cerbvar_INT_FAST8_MAX > 0);
  P(__cerbvar_INT_FAST8_MAX < 0);
  P(__cerbvar_INT_FAST8_MAX == 0);
  P(__cerbvar_INT_FAST8_MAX != 0);
  P(__cerbvar_INT_FAST8_MAX >= 0);
  P(__cerbvar_INT_FAST8_MAX <= 0);
  P(0 < __cerbvar_INT_FAST8_MAX);
  P(0 > __cerbvar_INT_FAST8_MAX);
  P(0 == __cerbvar_INT_FAST8_MAX);
  P(+__cerbvar_INT_FAST8_MAX);
  P(-__cerbvar_INT_FAST8_MAX);
  P(~__cerbvar_INT_FAST8_MAX);
  P(!__cerbvar_INT_FAST8_MAX);
  P((+__cerbvar_INT_FAST8_MAX) > 0);
  P(sizeof(__cerbvar_INT_FAST8_MAX));
  P(sizeof(+__cerbvar_INT_FAST8_MAX));
  P(TC(__cerbvar_INT_FAST8_MAX));
  P(TC(+__cerbvar_INT_FAST8_MAX));
  P(TC(-__cerbvar_INT_FAST8_MAX));
  P(TC(~__cerbvar_INT_FAST8_MAX));
  P((_Bool)__cerbvar_INT_FAST8_MAX);
  P((signed char)__cerbvar_INT_FAST8_MAX);
  P((unsigned char)__cerbvar_INT_FAST8_MAX);
  P((short)__cerbvar_INT_FAST8_MAX);
  P((unsigned short)__cerbvar_INT_FAST8_MAX);
  P((int)__cerbvar_INT_FAST8_MAX);
  P((unsigned)__cerbvar_INT_FAST8_MAX);
  P((long)__cerbvar_INT_FAST8_MAX);
  P((unsigned long)__cerbvar_INT_FAST8_MAX);
  P((long long)__cerbvar_INT_FAST8_MAX);
  P((unsigned long long)__cerbvar_INT_FAST8_MAX);
  P((long long)__cerbvar_INT_FAST8_MAX > 0);
  P((long long)__cerbvar_INT_FAST8_MAX < 0);
  { int x = __cerbvar_INT_FAST8_MAX; P(x); }
  { unsigned x = __cerbvar_INT_FAST8_MAX; P(x); }
  { long x = __cerbvar_INT_FAST8_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_FAST8_MAX; P(x); }
  P(__cerbvar_INT_FAST8_MAX + 1);
  P(__cerbvar_INT_FAST8_MAX - 1);
  P(__cerbvar_INT_FAST8_MAX - 1 > 0);
  P(__cerbvar_INT_FAST8_MAX + 1 > 0);
  P(__cerbvar_INT_FAST8_MAX + 1u);
  P(__cerbvar_INT_FAST8_MAX - 1u);
  P(__cerbvar_INT_FAST8_MAX + 1l);
  P(__cerbvar_INT_FAST8_MAX - 1ul);
  P(__cerbvar_UINT_FAST8_MAX > 0);
  P(__cerbvar_UINT_FAST8_MAX < 0);
  P(__cerbvar_UINT_FAST8_MAX == 0);
  P(__cerbvar_UINT_FAST8_MAX != 0);
  P(__cerbvar_UINT_FAST8_MAX >= 0);
  P(__cerbvar_UINT_FAST8_MAX <= 0);
  P(0 < __cerbvar_UINT_FAST8_MAX);
  P(0 > __cerbvar_UINT_FAST8_MAX);
  P(0 == __cerbvar_UINT_FAST8_MAX);
  P(+__cerbvar_UINT_FAST8_MAX);
  P(-__cerbvar_UINT_FAST8_MAX);
  P(~__cerbvar_UINT_FAST8_MAX);
  P(!__cerbvar_UINT_FAST8_MAX);
  P((+__cerbvar_UINT_FAST8_MAX) > 0);
  P(sizeof(__cerbvar_UINT_FAST8_MAX));
  P(sizeof(+__cerbvar_UINT_FAST8_MAX));
  P(TC(__cerbvar_UINT_FAST8_MAX));
  P(TC(+__cerbvar_UINT_FAST8_MAX));
  P(TC(-__cerbvar_UINT_FAST8_MAX));
  P(TC(~__cerbvar_UINT_FAST8_MAX));
  P((_Bool)__cerbvar_UINT_FAST8_MAX);
  P((signed char)__cerbvar_UINT_FAST8_MAX);
  P((unsigned char)__cerbvar_UINT_FAST8_MAX);
  P((short)__cerbvar_UINT_FAST8_MAX);
  P((unsigned short)__cerbvar_UINT_FAST8_MAX);
  P((int)__cerbvar_UINT_FAST8_MAX);
  P((unsigned)__cerbvar_UINT_FAST8_MAX);
  P((long)__cerbvar_UINT_FAST8_MAX);
  P((unsigned long)__cerbvar_UINT_FAST8_MAX);
  P((long long)__cerbvar_UINT_FAST8_MAX);
  P((unsigned long long)__cerbvar_UINT_FAST8_MAX);
  P((long long)__cerbvar_UINT_FAST8_MAX > 0);
  P((long long)__cerbvar_UINT_FAST8_MAX < 0);
  { int x = __cerbvar_UINT_FAST8_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_FAST8_MAX; P(x); }
  { long x = __cerbvar_UINT_FAST8_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_FAST8_MAX; P(x); }
  P(__cerbvar_UINT_FAST8_MAX + 1);
  P(__cerbvar_UINT_FAST8_MAX - 1);
  P(__cerbvar_UINT_FAST8_MAX - 1 > 0);
  P(__cerbvar_UINT_FAST8_MAX + 1 > 0);
  P(__cerbvar_UINT_FAST8_MAX + 1u);
  P(__cerbvar_UINT_FAST8_MAX - 1u);
  P(__cerbvar_UINT_FAST8_MAX + 1l);
  P(__cerbvar_UINT_FAST8_MAX - 1ul);
  P(__cerbvar_INT_FAST16_MIN > 0);
  P(__cerbvar_INT_FAST16_MIN < 0);
  P(__cerbvar_INT_FAST16_MIN == 0);
  P(__cerbvar_INT_FAST16_MIN != 0);
  P(__cerbvar_INT_FAST16_MIN >= 0);
  P(__cerbvar_INT_FAST16_MIN <= 0);
  P(0 < __cerbvar_INT_FAST16_MIN);
  P(0 > __cerbvar_INT_FAST16_MIN);
  P(0 == __cerbvar_INT_FAST16_MIN);
  P(+__cerbvar_INT_FAST16_MIN);
  P(-__cerbvar_INT_FAST16_MIN);
  P(~__cerbvar_INT_FAST16_MIN);
  P(!__cerbvar_INT_FAST16_MIN);
  P((+__cerbvar_INT_FAST16_MIN) > 0);
  P(sizeof(__cerbvar_INT_FAST16_MIN));
  P(sizeof(+__cerbvar_INT_FAST16_MIN));
  P(TC(__cerbvar_INT_FAST16_MIN));
  P(TC(+__cerbvar_INT_FAST16_MIN));
  P(TC(-__cerbvar_INT_FAST16_MIN));
  P(TC(~__cerbvar_INT_FAST16_MIN));
  P((_Bool)__cerbvar_INT_FAST16_MIN);
  P((signed char)__cerbvar_INT_FAST16_MIN);
  P((unsigned char)__cerbvar_INT_FAST16_MIN);
  P((short)__cerbvar_INT_FAST16_MIN);
  P((unsigned short)__cerbvar_INT_FAST16_MIN);
  P((int)__cerbvar_INT_FAST16_MIN);
  P((unsigned)__cerbvar_INT_FAST16_MIN);
  P((long)__cerbvar_INT_FAST16_MIN);
  P((unsigned long)__cerbvar_INT_FAST16_MIN);
  P((long long)__cerbvar_INT_FAST16_MIN);
  P((unsigned long long)__cerbvar_INT_FAST16_MIN);
  P((long long)__cerbvar_INT_FAST16_MIN > 0);
  P((long long)__cerbvar_INT_FAST16_MIN < 0);
  { int x = __cerbvar_INT_FAST16_MIN; P(x); }
  { unsigned x = __cerbvar_INT_FAST16_MIN; P(x); }
  { long x = __cerbvar_INT_FAST16_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_FAST16_MIN; P(x); }
  P(__cerbvar_INT_FAST16_MIN + 1);
  P(__cerbvar_INT_FAST16_MIN - 1);
  P(__cerbvar_INT_FAST16_MIN - 1 > 0);
  P(__cerbvar_INT_FAST16_MIN + 1 > 0);
  P(__cerbvar_INT_FAST16_MIN + 1u);
  P(__cerbvar_INT_FAST16_MIN - 1u);
  P(__cerbvar_INT_FAST16_MIN + 1l);
  P(__cerbvar_INT_FAST16_MIN - 1ul);
  P(__cerbvar_INT_FAST16_MAX > 0);
  P(__cerbvar_INT_FAST16_MAX < 0);
  P(__cerbvar_INT_FAST16_MAX == 0);
  P(__cerbvar_INT_FAST16_MAX != 0);
  P(__cerbvar_INT_FAST16_MAX >= 0);
  P(__cerbvar_INT_FAST16_MAX <= 0);
  P(0 < __cerbvar_INT_FAST16_MAX);
  P(0 > __cerbvar_INT_FAST16_MAX);
  P(0 == __cerbvar_INT_FAST16_MAX);
  P(+__cerbvar_INT_FAST16_MAX);
  P(-__cerbvar_INT_FAST16_MAX);
  P(~__cerbvar_INT_FAST16_MAX);
  P(!__cerbvar_INT_FAST16_MAX);
  P((+__cerbvar_INT_FAST16_MAX) > 0);
  P(sizeof(__cerbvar_INT_FAST16_MAX));
  P(sizeof(+__cerbvar_INT_FAST16_MAX));
  P(TC(__cerbvar_INT_FAST16_MAX));
  P(TC(+__cerbvar_INT_FAST16_MAX));
  P(TC(-__cerbvar_INT_FAST16_MAX));
  P(TC(~__cerbvar_INT_FAST16_MAX));
  P((_Bool)__cerbvar_INT_FAST16_MAX);
  P((signed char)__cerbvar_INT_FAST16_MAX);
  P((unsigned char)__cerbvar_INT_FAST16_MAX);
  P((short)__cerbvar_INT_FAST16_MAX);
  P((unsigned short)__cerbvar_INT_FAST16_MAX);
  P((int)__cerbvar_INT_FAST16_MAX);
  P((unsigned)__cerbvar_INT_FAST16_MAX);
  P((long)__cerbvar_INT_FAST16_MAX);
  P((unsigned long)__cerbvar_INT_FAST16_MAX);
  P((long long)__cerbvar_INT_FAST16_MAX);
  P((unsigned long long)__cerbvar_INT_FAST16_MAX);
  P((long long)__cerbvar_INT_FAST16_MAX > 0);
  P((long long)__cerbvar_INT_FAST16_MAX < 0);
  { int x = __cerbvar_INT_FAST16_MAX; P(x); }
  { unsigned x = __cerbvar_INT_FAST16_MAX; P(x); }
  { long x = __cerbvar_INT_FAST16_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_FAST16_MAX; P(x); }
  P(__cerbvar_INT_FAST16_MAX + 1);
  P(__cerbvar_INT_FAST16_MAX - 1);
  P(__cerbvar_INT_FAST16_MAX - 1 > 0);
  P(__cerbvar_INT_FAST16_MAX + 1 > 0);
  P(__cerbvar_INT_FAST16_MAX + 1u);
  P(__cerbvar_INT_FAST16_MAX - 1u);
  P(__cerbvar_INT_FAST16_MAX + 1l);
  P(__cerbvar_INT_FAST16_MAX - 1ul);
  P(__cerbvar_UINT_FAST16_MAX > 0);
  P(__cerbvar_UINT_FAST16_MAX < 0);
  P(__cerbvar_UINT_FAST16_MAX == 0);
  P(__cerbvar_UINT_FAST16_MAX != 0);
  P(__cerbvar_UINT_FAST16_MAX >= 0);
  P(__cerbvar_UINT_FAST16_MAX <= 0);
  P(0 < __cerbvar_UINT_FAST16_MAX);
  P(0 > __cerbvar_UINT_FAST16_MAX);
  P(0 == __cerbvar_UINT_FAST16_MAX);
  P(+__cerbvar_UINT_FAST16_MAX);
  P(-__cerbvar_UINT_FAST16_MAX);
  P(~__cerbvar_UINT_FAST16_MAX);
  P(!__cerbvar_UINT_FAST16_MAX);
  P((+__cerbvar_UINT_FAST16_MAX) > 0);
  P(sizeof(__cerbvar_UINT_FAST16_MAX));
  P(sizeof(+__cerbvar_UINT_FAST16_MAX));
  P(TC(__cerbvar_UINT_FAST16_MAX));
  P(TC(+__cerbvar_UINT_FAST16_MAX));
  P(TC(-__cerbvar_UINT_FAST16_MAX));
  P(TC(~__cerbvar_UINT_FAST16_MAX));
  P((_Bool)__cerbvar_UINT_FAST16_MAX);
  P((signed char)__cerbvar_UINT_FAST16_MAX);
  P((unsigned char)__cerbvar_UINT_FAST16_MAX);
  P((short)__cerbvar_UINT_FAST16_MAX);
  P((unsigned short)__cerbvar_UINT_FAST16_MAX);
  P((int)__cerbvar_UINT_FAST16_MAX);
  P((unsigned)__cerbvar_UINT_FAST16_MAX);
  P((long)__cerbvar_UINT_FAST16_MAX);
  P((unsigned long)__cerbvar_UINT_FAST16_MAX);
  P((long long)__cerbvar_UINT_FAST16_MAX);
  P((unsigned long long)__cerbvar_UINT_FAST16_MAX);
  P((long long)__cerbvar_UINT_FAST16_MAX > 0);
  P((long long)__cerbvar_UINT_FAST16_MAX < 0);
  { int x = __cerbvar_UINT_FAST16_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_FAST16_MAX; P(x); }
  { long x = __cerbvar_UINT_FAST16_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_FAST16_MAX; P(x); }
  P(__cerbvar_UINT_FAST16_MAX + 1);
  P(__cerbvar_UINT_FAST16_MAX - 1);
  P(__cerbvar_UINT_FAST16_MAX - 1 > 0);
  P(__cerbvar_UINT_FAST16_MAX + 1 > 0);
  P(__cerbvar_UINT_FAST16_MAX + 1u);
  P(__cerbvar_UINT_FAST16_MAX - 1u);
  P(__cerbvar_UINT_FAST16_MAX + 1l);
  P(__cerbvar_UINT_FAST16_MAX - 1ul);
  P(__cerbvar_INT_FAST32_MIN > 0);
  P(__cerbvar_INT_FAST32_MIN < 0);
  P(__cerbvar_INT_FAST32_MIN == 0);
  P(__cerbvar_INT_FAST32_MIN != 0);
  P(__cerbvar_INT_FAST32_MIN >= 0);
  P(__cerbvar_INT_FAST32_MIN <= 0);
  P(0 < __cerbvar_INT_FAST32_MIN);
  P(0 > __cerbvar_INT_FAST32_MIN);
  P(0 == __cerbvar_INT_FAST32_MIN);
  P(+__cerbvar_INT_FAST32_MIN);
  P(~__cerbvar_INT_FAST32_MIN);
  P(!__cerbvar_INT_FAST32_MIN);
  P((+__cerbvar_INT_FAST32_MIN) > 0);
  P(sizeof(__cerbvar_INT_FAST32_MIN));
  P(sizeof(+__cerbvar_INT_FAST32_MIN));
  P(TC(__cerbvar_INT_FAST32_MIN));
  P(TC(+__cerbvar_INT_FAST32_MIN));
  P(TC(-__cerbvar_INT_FAST32_MIN));
  P(TC(~__cerbvar_INT_FAST32_MIN));
  P((_Bool)__cerbvar_INT_FAST32_MIN);
  P((signed char)__cerbvar_INT_FAST32_MIN);
  P((unsigned char)__cerbvar_INT_FAST32_MIN);
  P((short)__cerbvar_INT_FAST32_MIN);
  P((unsigned short)__cerbvar_INT_FAST32_MIN);
  P((int)__cerbvar_INT_FAST32_MIN);
  P((unsigned)__cerbvar_INT_FAST32_MIN);
  P((long)__cerbvar_INT_FAST32_MIN);
  P((unsigned long)__cerbvar_INT_FAST32_MIN);
  P((long long)__cerbvar_INT_FAST32_MIN);
  P((unsigned long long)__cerbvar_INT_FAST32_MIN);
  P((long long)__cerbvar_INT_FAST32_MIN > 0);
  P((long long)__cerbvar_INT_FAST32_MIN < 0);
  { int x = __cerbvar_INT_FAST32_MIN; P(x); }
  { unsigned x = __cerbvar_INT_FAST32_MIN; P(x); }
  { long x = __cerbvar_INT_FAST32_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_FAST32_MIN; P(x); }
  P(__cerbvar_INT_FAST32_MIN + 1);
  P(__cerbvar_INT_FAST32_MIN + 1 > 0);
  P(__cerbvar_INT_FAST32_MIN + 1u);
  P(__cerbvar_INT_FAST32_MIN - 1u);
  P(__cerbvar_INT_FAST32_MIN + 1l);
  P(__cerbvar_INT_FAST32_MIN - 1ul);
  P(__cerbvar_INT_FAST32_MAX > 0);
  P(__cerbvar_INT_FAST32_MAX < 0);
  P(__cerbvar_INT_FAST32_MAX == 0);
  P(__cerbvar_INT_FAST32_MAX != 0);
  P(__cerbvar_INT_FAST32_MAX >= 0);
  P(__cerbvar_INT_FAST32_MAX <= 0);
  P(0 < __cerbvar_INT_FAST32_MAX);
  P(0 > __cerbvar_INT_FAST32_MAX);
  P(0 == __cerbvar_INT_FAST32_MAX);
  P(+__cerbvar_INT_FAST32_MAX);
  P(-__cerbvar_INT_FAST32_MAX);
  P(~__cerbvar_INT_FAST32_MAX);
  P(!__cerbvar_INT_FAST32_MAX);
  P((+__cerbvar_INT_FAST32_MAX) > 0);
  P(sizeof(__cerbvar_INT_FAST32_MAX));
  P(sizeof(+__cerbvar_INT_FAST32_MAX));
  P(TC(__cerbvar_INT_FAST32_MAX));
  P(TC(+__cerbvar_INT_FAST32_MAX));
  P(TC(-__cerbvar_INT_FAST32_MAX));
  P(TC(~__cerbvar_INT_FAST32_MAX));
  P((_Bool)__cerbvar_INT_FAST32_MAX);
  P((signed char)__cerbvar_INT_FAST32_MAX);
  P((unsigned char)__cerbvar_INT_FAST32_MAX);
  P((short)__cerbvar_INT_FAST32_MAX);
  P((unsigned short)__cerbvar_INT_FAST32_MAX);
  P((int)__cerbvar_INT_FAST32_MAX);
  P((unsigned)__cerbvar_INT_FAST32_MAX);
  P((long)__cerbvar_INT_FAST32_MAX);
  P((unsigned long)__cerbvar_INT_FAST32_MAX);
  P((long long)__cerbvar_INT_FAST32_MAX);
  P((unsigned long long)__cerbvar_INT_FAST32_MAX);
  P((long long)__cerbvar_INT_FAST32_MAX > 0);
  P((long long)__cerbvar_INT_FAST32_MAX < 0);
  { int x = __cerbvar_INT_FAST32_MAX; P(x); }
  { unsigned x = __cerbvar_INT_FAST32_MAX; P(x); }
  { long x = __cerbvar_INT_FAST32_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_FAST32_MAX; P(x); }
  P(__cerbvar_INT_FAST32_MAX - 1);
  P(__cerbvar_INT_FAST32_MAX - 1 > 0);
  P(__cerbvar_INT_FAST32_MAX + 1u);
  P(__cerbvar_INT_FAST32_MAX - 1u);
  P(__cerbvar_INT_FAST32_MAX + 1l);
  P(__cerbvar_INT_FAST32_MAX - 1ul);
  P(__cerbvar_UINT_FAST32_MAX > 0);
  P(__cerbvar_UINT_FAST32_MAX < 0);
  P(__cerbvar_UINT_FAST32_MAX == 0);
  P(__cerbvar_UINT_FAST32_MAX != 0);
  P(__cerbvar_UINT_FAST32_MAX >= 0);
  P(__cerbvar_UINT_FAST32_MAX <= 0);
  P(0 < __cerbvar_UINT_FAST32_MAX);
  P(0 > __cerbvar_UINT_FAST32_MAX);
  P(0 == __cerbvar_UINT_FAST32_MAX);
  P(+__cerbvar_UINT_FAST32_MAX);
  P(-__cerbvar_UINT_FAST32_MAX);
  P(~__cerbvar_UINT_FAST32_MAX);
  P(!__cerbvar_UINT_FAST32_MAX);
  P((+__cerbvar_UINT_FAST32_MAX) > 0);
  P(sizeof(__cerbvar_UINT_FAST32_MAX));
  P(sizeof(+__cerbvar_UINT_FAST32_MAX));
  P(TC(__cerbvar_UINT_FAST32_MAX));
  P(TC(+__cerbvar_UINT_FAST32_MAX));
  P(TC(-__cerbvar_UINT_FAST32_MAX));
  P(TC(~__cerbvar_UINT_FAST32_MAX));
  P((_Bool)__cerbvar_UINT_FAST32_MAX);
  P((signed char)__cerbvar_UINT_FAST32_MAX);
  P((unsigned char)__cerbvar_UINT_FAST32_MAX);
  P((short)__cerbvar_UINT_FAST32_MAX);
  P((unsigned short)__cerbvar_UINT_FAST32_MAX);
  P((int)__cerbvar_UINT_FAST32_MAX);
  P((unsigned)__cerbvar_UINT_FAST32_MAX);
  P((long)__cerbvar_UINT_FAST32_MAX);
  P((unsigned long)__cerbvar_UINT_FAST32_MAX);
  P((long long)__cerbvar_UINT_FAST32_MAX);
  P((unsigned long long)__cerbvar_UINT_FAST32_MAX);
  P((long long)__cerbvar_UINT_FAST32_MAX > 0);
  P((long long)__cerbvar_UINT_FAST32_MAX < 0);
  { int x = __cerbvar_UINT_FAST32_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_FAST32_MAX; P(x); }
  { long x = __cerbvar_UINT_FAST32_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_FAST32_MAX; P(x); }
  P(__cerbvar_UINT_FAST32_MAX + 1);
  P(__cerbvar_UINT_FAST32_MAX - 1);
  P(__cerbvar_UINT_FAST32_MAX - 1 > 0);
  P(__cerbvar_UINT_FAST32_MAX + 1 > 0);
  P(__cerbvar_UINT_FAST32_MAX + 1u);
  P(__cerbvar_UINT_FAST32_MAX - 1u);
  P(__cerbvar_UINT_FAST32_MAX + 1l);
  P(__cerbvar_UINT_FAST32_MAX - 1ul);
  P(__cerbvar_INT_FAST64_MIN > 0);
  P(__cerbvar_INT_FAST64_MIN < 0);
  P(__cerbvar_INT_FAST64_MIN == 0);
  P(__cerbvar_INT_FAST64_MIN != 0);
  P(__cerbvar_INT_FAST64_MIN >= 0);
  P(__cerbvar_INT_FAST64_MIN <= 0);
  P(0 < __cerbvar_INT_FAST64_MIN);
  P(0 > __cerbvar_INT_FAST64_MIN);
  P(0 == __cerbvar_INT_FAST64_MIN);
  P(+__cerbvar_INT_FAST64_MIN);
  P(~__cerbvar_INT_FAST64_MIN);
  P(!__cerbvar_INT_FAST64_MIN);
  P((+__cerbvar_INT_FAST64_MIN) > 0);
  P(sizeof(__cerbvar_INT_FAST64_MIN));
  P(sizeof(+__cerbvar_INT_FAST64_MIN));
  P(TC(__cerbvar_INT_FAST64_MIN));
  P(TC(+__cerbvar_INT_FAST64_MIN));
  P(TC(-__cerbvar_INT_FAST64_MIN));
  P(TC(~__cerbvar_INT_FAST64_MIN));
  P((_Bool)__cerbvar_INT_FAST64_MIN);
  P((signed char)__cerbvar_INT_FAST64_MIN);
  P((unsigned char)__cerbvar_INT_FAST64_MIN);
  P((short)__cerbvar_INT_FAST64_MIN);
  P((unsigned short)__cerbvar_INT_FAST64_MIN);
  P((int)__cerbvar_INT_FAST64_MIN);
  P((unsigned)__cerbvar_INT_FAST64_MIN);
  P((long)__cerbvar_INT_FAST64_MIN);
  P((unsigned long)__cerbvar_INT_FAST64_MIN);
  P((long long)__cerbvar_INT_FAST64_MIN);
  P((unsigned long long)__cerbvar_INT_FAST64_MIN);
  P((long long)__cerbvar_INT_FAST64_MIN > 0);
  P((long long)__cerbvar_INT_FAST64_MIN < 0);
  { int x = __cerbvar_INT_FAST64_MIN; P(x); }
  { unsigned x = __cerbvar_INT_FAST64_MIN; P(x); }
  { long x = __cerbvar_INT_FAST64_MIN; P(x); }
  { unsigned long x = __cerbvar_INT_FAST64_MIN; P(x); }
  P(__cerbvar_INT_FAST64_MIN + 1);
  P(__cerbvar_INT_FAST64_MIN + 1 > 0);
  P(__cerbvar_INT_FAST64_MIN + 1u);
  P(__cerbvar_INT_FAST64_MIN + 1l);
  P(__cerbvar_INT_FAST64_MIN - 1ul);
  P(__cerbvar_INT_FAST64_MAX > 0);
  P(__cerbvar_INT_FAST64_MAX < 0);
  P(__cerbvar_INT_FAST64_MAX == 0);
  P(__cerbvar_INT_FAST64_MAX != 0);
  P(__cerbvar_INT_FAST64_MAX >= 0);
  P(__cerbvar_INT_FAST64_MAX <= 0);
  P(0 < __cerbvar_INT_FAST64_MAX);
  P(0 > __cerbvar_INT_FAST64_MAX);
  P(0 == __cerbvar_INT_FAST64_MAX);
  P(+__cerbvar_INT_FAST64_MAX);
  P(-__cerbvar_INT_FAST64_MAX);
  P(~__cerbvar_INT_FAST64_MAX);
  P(!__cerbvar_INT_FAST64_MAX);
  P((+__cerbvar_INT_FAST64_MAX) > 0);
  P(sizeof(__cerbvar_INT_FAST64_MAX));
  P(sizeof(+__cerbvar_INT_FAST64_MAX));
  P(TC(__cerbvar_INT_FAST64_MAX));
  P(TC(+__cerbvar_INT_FAST64_MAX));
  P(TC(-__cerbvar_INT_FAST64_MAX));
  P(TC(~__cerbvar_INT_FAST64_MAX));
  P((_Bool)__cerbvar_INT_FAST64_MAX);
  P((signed char)__cerbvar_INT_FAST64_MAX);
  P((unsigned char)__cerbvar_INT_FAST64_MAX);
  P((short)__cerbvar_INT_FAST64_MAX);
  P((unsigned short)__cerbvar_INT_FAST64_MAX);
  P((int)__cerbvar_INT_FAST64_MAX);
  P((unsigned)__cerbvar_INT_FAST64_MAX);
  P((long)__cerbvar_INT_FAST64_MAX);
  P((unsigned long)__cerbvar_INT_FAST64_MAX);
  P((long long)__cerbvar_INT_FAST64_MAX);
  P((unsigned long long)__cerbvar_INT_FAST64_MAX);
  P((long long)__cerbvar_INT_FAST64_MAX > 0);
  P((long long)__cerbvar_INT_FAST64_MAX < 0);
  { int x = __cerbvar_INT_FAST64_MAX; P(x); }
  { unsigned x = __cerbvar_INT_FAST64_MAX; P(x); }
  { long x = __cerbvar_INT_FAST64_MAX; P(x); }
  { unsigned long x = __cerbvar_INT_FAST64_MAX; P(x); }
  P(__cerbvar_INT_FAST64_MAX - 1);
  P(__cerbvar_INT_FAST64_MAX - 1 > 0);
  P(__cerbvar_INT_FAST64_MAX - 1u);
  P(__cerbvar_INT_FAST64_MAX - 1ul);
  P(__cerbvar_UINT_FAST64_MAX > 0);
  P(__cerbvar_UINT_FAST64_MAX < 0);
  P(__cerbvar_UINT_FAST64_MAX == 0);
  P(__cerbvar_UINT_FAST64_MAX != 0);
  P(__cerbvar_UINT_FAST64_MAX >= 0);
  P(__cerbvar_UINT_FAST64_MAX <= 0);
  P(0 < __cerbvar_UINT_FAST64_MAX);
  P(0 > __cerbvar_UINT_FAST64_MAX);
  P(0 == __cerbvar_UINT_FAST64_MAX);
  P(+__cerbvar_UINT_FAST64_MAX);
  P(-__cerbvar_UINT_FAST64_MAX);
  P(~__cerbvar_UINT_FAST64_MAX);
  P(!__cerbvar_UINT_FAST64_MAX);
  P((+__cerbvar_UINT_FAST64_MAX) > 0);
  P(sizeof(__cerbvar_UINT_FAST64_MAX));
  P(sizeof(+__cerbvar_UINT_FAST64_MAX));
  P(TC(__cerbvar_UINT_FAST64_MAX));
  P(TC(+__cerbvar_UINT_FAST64_MAX));
  P(TC(-__cerbvar_UINT_FAST64_MAX));
  P(TC(~__cerbvar_UINT_FAST64_MAX));
  P((_Bool)__cerbvar_UINT_FAST64_MAX);
  P((signed char)__cerbvar_UINT_FAST64_MAX);
  P((unsigned char)__cerbvar_UINT_FAST64_MAX);
  P((short)__cerbvar_UINT_FAST64_MAX);
  P((unsigned short)__cerbvar_UINT_FAST64_MAX);
  P((int)__cerbvar_UINT_FAST64_MAX);
  P((unsigned)__cerbvar_UINT_FAST64_MAX);
  P((long)__cerbvar_UINT_FAST64_MAX);
  P((unsigned long)__cerbvar_UINT_FAST64_MAX);
  P((long long)__cerbvar_UINT_FAST64_MAX);
  P((unsigned long long)__cerbvar_UINT_FAST64_MAX);
  P((long long)__cerbvar_UINT_FAST64_MAX > 0);
  P((long long)__cerbvar_UINT_FAST64_MAX < 0);
  { int x = __cerbvar_UINT_FAST64_MAX; P(x); }
  { unsigned x = __cerbvar_UINT_FAST64_MAX; P(x); }
  { long x = __cerbvar_UINT_FAST64_MAX; P(x); }
  { unsigned long x = __cerbvar_UINT_FAST64_MAX; P(x); }
  P(__cerbvar_UINT_FAST64_MAX + 1);
  P(__cerbvar_UINT_FAST64_MAX - 1);
  P(__cerbvar_UINT_FAST64_MAX - 1 > 0);
  P(__cerbvar_UINT_FAST64_MAX + 1 > 0);
  P(__cerbvar_UINT_FAST64_MAX + 1u);
  P(__cerbvar_UINT_FAST64_MAX - 1u);
  P(__cerbvar_UINT_FAST64_MAX + 1l);
  P(__cerbvar_UINT_FAST64_MAX - 1ul);
  printf("\n");
  return 0;
}
