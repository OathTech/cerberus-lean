// KEPT (upstream's behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f's line; gcc 13's line beside in kept.txt): a wchar_t object (2147483647) against every standard partner type and both enums, both orders, every operator and op=
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
enum EU { EU0 = 0, EU3 = 3, EUBIG = 700000005 };
enum ES { ESNEG = -1, ES3 = 3, ESBIG = 700000005 };
int main(void) {
  { wchar_t w = 2147483647; _Bool p = 0; P(w < p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w > p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w == p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w != p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w <= p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w >= p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p < w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p > w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p == w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w + p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p + w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w - p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p - w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w * p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p * w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w & p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w | p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p & w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; _Bool p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; _Bool p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; _Bool p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; _Bool p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p / w); }
  { wchar_t w = 2147483647; _Bool p = 0; P(p % w); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t += w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; _Bool t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w < p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w > p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w == p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w != p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w <= p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w >= p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p < w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p > w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p == w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w - p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p - w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w * p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p * w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w & p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w | p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p & w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; _Bool p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; _Bool p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; _Bool p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w / p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(w % p); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p / w); }
  { wchar_t w = 2147483647; _Bool p = 3; P(p % w); }
  { wchar_t w = 2147483647; _Bool p = 3; _Bool t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; _Bool t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; _Bool t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; _Bool t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; _Bool t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; _Bool p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; char p = 0; P(w < p); }
  { wchar_t w = 2147483647; char p = 0; P(w > p); }
  { wchar_t w = 2147483647; char p = 0; P(w == p); }
  { wchar_t w = 2147483647; char p = 0; P(w != p); }
  { wchar_t w = 2147483647; char p = 0; P(w <= p); }
  { wchar_t w = 2147483647; char p = 0; P(w >= p); }
  { wchar_t w = 2147483647; char p = 0; P(p < w); }
  { wchar_t w = 2147483647; char p = 0; P(p > w); }
  { wchar_t w = 2147483647; char p = 0; P(p == w); }
  { wchar_t w = 2147483647; char p = 0; P(w + p); }
  { wchar_t w = 2147483647; char p = 0; P(p + w); }
  { wchar_t w = 2147483647; char p = 0; P(w - p); }
  { wchar_t w = 2147483647; char p = 0; P(p - w); }
  { wchar_t w = 2147483647; char p = 0; P(w * p); }
  { wchar_t w = 2147483647; char p = 0; P(p * w); }
  { wchar_t w = 2147483647; char p = 0; P(w & p); }
  { wchar_t w = 2147483647; char p = 0; P(w | p); }
  { wchar_t w = 2147483647; char p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; char p = 0; P(p & w); }
  { wchar_t w = 2147483647; char p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; char p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; char p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; char p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; char p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; char p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; char p = 0; P(p / w); }
  { wchar_t w = 2147483647; char p = 0; P(p % w); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t += w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; char p = 0; char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; char p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; char p = 3; P(w < p); }
  { wchar_t w = 2147483647; char p = 3; P(w > p); }
  { wchar_t w = 2147483647; char p = 3; P(w == p); }
  { wchar_t w = 2147483647; char p = 3; P(w != p); }
  { wchar_t w = 2147483647; char p = 3; P(w <= p); }
  { wchar_t w = 2147483647; char p = 3; P(w >= p); }
  { wchar_t w = 2147483647; char p = 3; P(p < w); }
  { wchar_t w = 2147483647; char p = 3; P(p > w); }
  { wchar_t w = 2147483647; char p = 3; P(p == w); }
  { wchar_t w = 2147483647; char p = 3; P(w - p); }
  { wchar_t w = 2147483647; char p = 3; P(p - w); }
  { wchar_t w = 2147483647; char p = 3; P(w & p); }
  { wchar_t w = 2147483647; char p = 3; P(w | p); }
  { wchar_t w = 2147483647; char p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; char p = 3; P(p & w); }
  { wchar_t w = 2147483647; char p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; char p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; char p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; char p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; char p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; char p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; char p = 3; P(w / p); }
  { wchar_t w = 2147483647; char p = 3; P(w % p); }
  { wchar_t w = 2147483647; char p = 3; P(p / w); }
  { wchar_t w = 2147483647; char p = 3; P(p % w); }
  { wchar_t w = 2147483647; char p = 3; char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; char p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; char p = 3; char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; char p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; char p = 3; char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; char p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; char p = 3; char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; char p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; char p = -3; P(w < p); }
  { wchar_t w = 2147483647; char p = -3; P(w > p); }
  { wchar_t w = 2147483647; char p = -3; P(w == p); }
  { wchar_t w = 2147483647; char p = -3; P(w != p); }
  { wchar_t w = 2147483647; char p = -3; P(w <= p); }
  { wchar_t w = 2147483647; char p = -3; P(w >= p); }
  { wchar_t w = 2147483647; char p = -3; P(p < w); }
  { wchar_t w = 2147483647; char p = -3; P(p > w); }
  { wchar_t w = 2147483647; char p = -3; P(p == w); }
  { wchar_t w = 2147483647; char p = -3; P(p + w); }
  { wchar_t w = 2147483647; char p = -3; P(w & p); }
  { wchar_t w = 2147483647; char p = -3; P(w | p); }
  { wchar_t w = 2147483647; char p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; char p = -3; P(p & w); }
  { wchar_t w = 2147483647; char p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; char p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; char p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; char p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; char p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; char p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; char p = -3; P(w / p); }
  { wchar_t w = 2147483647; char p = -3; P(w % p); }
  { wchar_t w = 2147483647; char p = -3; P(p / w); }
  { wchar_t w = 2147483647; char p = -3; P(p % w); }
  { wchar_t w = 2147483647; char p = -3; char t = p; t += w; P(t); }
  { wchar_t w = 2147483647; char p = -3; char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; char p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; char p = -3; char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; char p = -3; char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; P(w < p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w > p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w == p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w != p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w <= p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w >= p); }
  { wchar_t w = 2147483647; signed char p = 0; P(p < w); }
  { wchar_t w = 2147483647; signed char p = 0; P(p > w); }
  { wchar_t w = 2147483647; signed char p = 0; P(p == w); }
  { wchar_t w = 2147483647; signed char p = 0; P(w + p); }
  { wchar_t w = 2147483647; signed char p = 0; P(p + w); }
  { wchar_t w = 2147483647; signed char p = 0; P(w - p); }
  { wchar_t w = 2147483647; signed char p = 0; P(p - w); }
  { wchar_t w = 2147483647; signed char p = 0; P(w * p); }
  { wchar_t w = 2147483647; signed char p = 0; P(p * w); }
  { wchar_t w = 2147483647; signed char p = 0; P(w & p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w | p); }
  { wchar_t w = 2147483647; signed char p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; signed char p = 0; P(p & w); }
  { wchar_t w = 2147483647; signed char p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; signed char p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; signed char p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; signed char p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; signed char p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; signed char p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; signed char p = 0; P(p / w); }
  { wchar_t w = 2147483647; signed char p = 0; P(p % w); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t += w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; signed char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; P(w < p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w > p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w == p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w != p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w <= p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w >= p); }
  { wchar_t w = 2147483647; signed char p = 3; P(p < w); }
  { wchar_t w = 2147483647; signed char p = 3; P(p > w); }
  { wchar_t w = 2147483647; signed char p = 3; P(p == w); }
  { wchar_t w = 2147483647; signed char p = 3; P(w - p); }
  { wchar_t w = 2147483647; signed char p = 3; P(p - w); }
  { wchar_t w = 2147483647; signed char p = 3; P(w & p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w | p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; signed char p = 3; P(p & w); }
  { wchar_t w = 2147483647; signed char p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; signed char p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; signed char p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; signed char p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; signed char p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; signed char p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; signed char p = 3; P(w / p); }
  { wchar_t w = 2147483647; signed char p = 3; P(w % p); }
  { wchar_t w = 2147483647; signed char p = 3; P(p / w); }
  { wchar_t w = 2147483647; signed char p = 3; P(p % w); }
  { wchar_t w = 2147483647; signed char p = 3; signed char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; signed char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; signed char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; signed char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; signed char p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; signed char p = -3; P(w < p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w > p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w == p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w != p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w <= p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w >= p); }
  { wchar_t w = 2147483647; signed char p = -3; P(p < w); }
  { wchar_t w = 2147483647; signed char p = -3; P(p > w); }
  { wchar_t w = 2147483647; signed char p = -3; P(p == w); }
  { wchar_t w = 2147483647; signed char p = -3; P(p + w); }
  { wchar_t w = 2147483647; signed char p = -3; P(w & p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w | p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; signed char p = -3; P(p & w); }
  { wchar_t w = 2147483647; signed char p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; signed char p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; signed char p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; signed char p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; signed char p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; signed char p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; signed char p = -3; P(w / p); }
  { wchar_t w = 2147483647; signed char p = -3; P(w % p); }
  { wchar_t w = 2147483647; signed char p = -3; P(p / w); }
  { wchar_t w = 2147483647; signed char p = -3; P(p % w); }
  { wchar_t w = 2147483647; signed char p = -3; signed char t = p; t += w; P(t); }
  { wchar_t w = 2147483647; signed char p = -3; signed char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; signed char p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; signed char p = -3; signed char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; signed char p = -3; signed char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w < p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w > p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w == p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w != p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w <= p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w >= p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p < w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p > w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p == w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w + p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p + w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w - p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p - w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w * p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p * w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w & p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w | p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p & w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p / w); }
  { wchar_t w = 2147483647; unsigned char p = 0; P(p % w); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; unsigned char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w < p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w > p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w == p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w != p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p < w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p > w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p == w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w - p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p - w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w & p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w | p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p & w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w / p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(w % p); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p / w); }
  { wchar_t w = 2147483647; unsigned char p = 3; P(p % w); }
  { wchar_t w = 2147483647; unsigned char p = 3; unsigned char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; unsigned char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; unsigned char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; unsigned char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w < p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w > p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w == p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w != p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p < w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p > w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p == w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w - p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p - w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w & p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w | p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p & w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w / p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(w % p); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p / w); }
  { wchar_t w = 2147483647; unsigned char p = -3; P(p % w); }
  { wchar_t w = 2147483647; unsigned char p = -3; unsigned char t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; unsigned char t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; unsigned char t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; unsigned char t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned char p = -3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; short p = 0; P(w < p); }
  { wchar_t w = 2147483647; short p = 0; P(w > p); }
  { wchar_t w = 2147483647; short p = 0; P(w == p); }
  { wchar_t w = 2147483647; short p = 0; P(w != p); }
  { wchar_t w = 2147483647; short p = 0; P(w <= p); }
  { wchar_t w = 2147483647; short p = 0; P(w >= p); }
  { wchar_t w = 2147483647; short p = 0; P(p < w); }
  { wchar_t w = 2147483647; short p = 0; P(p > w); }
  { wchar_t w = 2147483647; short p = 0; P(p == w); }
  { wchar_t w = 2147483647; short p = 0; P(w + p); }
  { wchar_t w = 2147483647; short p = 0; P(p + w); }
  { wchar_t w = 2147483647; short p = 0; P(w - p); }
  { wchar_t w = 2147483647; short p = 0; P(p - w); }
  { wchar_t w = 2147483647; short p = 0; P(w * p); }
  { wchar_t w = 2147483647; short p = 0; P(p * w); }
  { wchar_t w = 2147483647; short p = 0; P(w & p); }
  { wchar_t w = 2147483647; short p = 0; P(w | p); }
  { wchar_t w = 2147483647; short p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; short p = 0; P(p & w); }
  { wchar_t w = 2147483647; short p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; short p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; short p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; short p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; short p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; short p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; short p = 0; P(p / w); }
  { wchar_t w = 2147483647; short p = 0; P(p % w); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t += w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; short p = 0; short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; short p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; short p = 3; P(w < p); }
  { wchar_t w = 2147483647; short p = 3; P(w > p); }
  { wchar_t w = 2147483647; short p = 3; P(w == p); }
  { wchar_t w = 2147483647; short p = 3; P(w != p); }
  { wchar_t w = 2147483647; short p = 3; P(w <= p); }
  { wchar_t w = 2147483647; short p = 3; P(w >= p); }
  { wchar_t w = 2147483647; short p = 3; P(p < w); }
  { wchar_t w = 2147483647; short p = 3; P(p > w); }
  { wchar_t w = 2147483647; short p = 3; P(p == w); }
  { wchar_t w = 2147483647; short p = 3; P(w - p); }
  { wchar_t w = 2147483647; short p = 3; P(p - w); }
  { wchar_t w = 2147483647; short p = 3; P(w & p); }
  { wchar_t w = 2147483647; short p = 3; P(w | p); }
  { wchar_t w = 2147483647; short p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; short p = 3; P(p & w); }
  { wchar_t w = 2147483647; short p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; short p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; short p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; short p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; short p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; short p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; short p = 3; P(w / p); }
  { wchar_t w = 2147483647; short p = 3; P(w % p); }
  { wchar_t w = 2147483647; short p = 3; P(p / w); }
  { wchar_t w = 2147483647; short p = 3; P(p % w); }
  { wchar_t w = 2147483647; short p = 3; short t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; short p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; short p = 3; short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; short p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; short p = 3; short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; short p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; short p = 3; short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; short p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; short p = -3; P(w < p); }
  { wchar_t w = 2147483647; short p = -3; P(w > p); }
  { wchar_t w = 2147483647; short p = -3; P(w == p); }
  { wchar_t w = 2147483647; short p = -3; P(w != p); }
  { wchar_t w = 2147483647; short p = -3; P(w <= p); }
  { wchar_t w = 2147483647; short p = -3; P(w >= p); }
  { wchar_t w = 2147483647; short p = -3; P(p < w); }
  { wchar_t w = 2147483647; short p = -3; P(p > w); }
  { wchar_t w = 2147483647; short p = -3; P(p == w); }
  { wchar_t w = 2147483647; short p = -3; P(p + w); }
  { wchar_t w = 2147483647; short p = -3; P(w & p); }
  { wchar_t w = 2147483647; short p = -3; P(w | p); }
  { wchar_t w = 2147483647; short p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; short p = -3; P(p & w); }
  { wchar_t w = 2147483647; short p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; short p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; short p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; short p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; short p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; short p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; short p = -3; P(w / p); }
  { wchar_t w = 2147483647; short p = -3; P(w % p); }
  { wchar_t w = 2147483647; short p = -3; P(p / w); }
  { wchar_t w = 2147483647; short p = -3; P(p % w); }
  { wchar_t w = 2147483647; short p = -3; short t = p; t += w; P(t); }
  { wchar_t w = 2147483647; short p = -3; short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; short p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; short p = -3; short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; short p = -3; short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w < p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w > p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w == p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w != p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w <= p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w >= p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p < w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p > w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p == w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w + p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p + w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w - p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p - w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w * p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p * w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w & p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w | p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p & w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p / w); }
  { wchar_t w = 2147483647; unsigned short p = 0; P(p % w); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; unsigned short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w < p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w > p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w == p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w != p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p < w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p > w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p == w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w - p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p - w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w & p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w | p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p & w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w / p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(w % p); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p / w); }
  { wchar_t w = 2147483647; unsigned short p = 3; P(p % w); }
  { wchar_t w = 2147483647; unsigned short p = 3; unsigned short t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; unsigned short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; unsigned short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; unsigned short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w < p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w > p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w == p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w != p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p < w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p > w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p == w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w - p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p - w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w & p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w | p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p & w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w / p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(w % p); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p / w); }
  { wchar_t w = 2147483647; unsigned short p = -3; P(p % w); }
  { wchar_t w = 2147483647; unsigned short p = -3; unsigned short t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; unsigned short t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; unsigned short t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; unsigned short t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned short p = -3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; int p = 0; P(w < p); }
  { wchar_t w = 2147483647; int p = 0; P(w > p); }
  { wchar_t w = 2147483647; int p = 0; P(w == p); }
  { wchar_t w = 2147483647; int p = 0; P(w != p); }
  { wchar_t w = 2147483647; int p = 0; P(w <= p); }
  { wchar_t w = 2147483647; int p = 0; P(w >= p); }
  { wchar_t w = 2147483647; int p = 0; P(p < w); }
  { wchar_t w = 2147483647; int p = 0; P(p > w); }
  { wchar_t w = 2147483647; int p = 0; P(p == w); }
  { wchar_t w = 2147483647; int p = 0; P(w + p); }
  { wchar_t w = 2147483647; int p = 0; P(p + w); }
  { wchar_t w = 2147483647; int p = 0; P(w - p); }
  { wchar_t w = 2147483647; int p = 0; P(p - w); }
  { wchar_t w = 2147483647; int p = 0; P(w * p); }
  { wchar_t w = 2147483647; int p = 0; P(p * w); }
  { wchar_t w = 2147483647; int p = 0; P(w & p); }
  { wchar_t w = 2147483647; int p = 0; P(w | p); }
  { wchar_t w = 2147483647; int p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; int p = 0; P(p & w); }
  { wchar_t w = 2147483647; int p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; int p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; int p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; int p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; int p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; int p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; int p = 0; P(p / w); }
  { wchar_t w = 2147483647; int p = 0; P(p % w); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t += w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; int p = 0; int t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; int p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; int p = 3; P(w < p); }
  { wchar_t w = 2147483647; int p = 3; P(w > p); }
  { wchar_t w = 2147483647; int p = 3; P(w == p); }
  { wchar_t w = 2147483647; int p = 3; P(w != p); }
  { wchar_t w = 2147483647; int p = 3; P(w <= p); }
  { wchar_t w = 2147483647; int p = 3; P(w >= p); }
  { wchar_t w = 2147483647; int p = 3; P(p < w); }
  { wchar_t w = 2147483647; int p = 3; P(p > w); }
  { wchar_t w = 2147483647; int p = 3; P(p == w); }
  { wchar_t w = 2147483647; int p = 3; P(w - p); }
  { wchar_t w = 2147483647; int p = 3; P(p - w); }
  { wchar_t w = 2147483647; int p = 3; P(w & p); }
  { wchar_t w = 2147483647; int p = 3; P(w | p); }
  { wchar_t w = 2147483647; int p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; int p = 3; P(p & w); }
  { wchar_t w = 2147483647; int p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; int p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; int p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; int p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; int p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; int p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; int p = 3; P(w / p); }
  { wchar_t w = 2147483647; int p = 3; P(w % p); }
  { wchar_t w = 2147483647; int p = 3; P(p / w); }
  { wchar_t w = 2147483647; int p = 3; P(p % w); }
  { wchar_t w = 2147483647; int p = 3; int t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; int p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; int p = 3; int t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; int p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; int p = 3; int t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; int p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; int p = 3; int t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; int p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; int p = -3; P(w < p); }
  { wchar_t w = 2147483647; int p = -3; P(w > p); }
  { wchar_t w = 2147483647; int p = -3; P(w == p); }
  { wchar_t w = 2147483647; int p = -3; P(w != p); }
  { wchar_t w = 2147483647; int p = -3; P(w <= p); }
  { wchar_t w = 2147483647; int p = -3; P(w >= p); }
  { wchar_t w = 2147483647; int p = -3; P(p < w); }
  { wchar_t w = 2147483647; int p = -3; P(p > w); }
  { wchar_t w = 2147483647; int p = -3; P(p == w); }
  { wchar_t w = 2147483647; int p = -3; P(p + w); }
  { wchar_t w = 2147483647; int p = -3; P(w & p); }
  { wchar_t w = 2147483647; int p = -3; P(w | p); }
  { wchar_t w = 2147483647; int p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; int p = -3; P(p & w); }
  { wchar_t w = 2147483647; int p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; int p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; int p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; int p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; int p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; int p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; int p = -3; P(w / p); }
  { wchar_t w = 2147483647; int p = -3; P(w % p); }
  { wchar_t w = 2147483647; int p = -3; P(p / w); }
  { wchar_t w = 2147483647; int p = -3; P(p % w); }
  { wchar_t w = 2147483647; int p = -3; int t = p; t += w; P(t); }
  { wchar_t w = 2147483647; int p = -3; int t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; int p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; int p = -3; int t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; int p = -3; int t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w < p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w > p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w == p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w != p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w <= p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w >= p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p < w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p > w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p == w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w + p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p + w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w - p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w * p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p * w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w & p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w | p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p & w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p / w); }
  { wchar_t w = 2147483647; unsigned p = 0; P(p % w); }
  { wchar_t w = 2147483647; unsigned p = 0; unsigned t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; unsigned t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; unsigned t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; unsigned t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; unsigned t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w < p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w > p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w == p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w != p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p < w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p > w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p == w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w + p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p + w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w - p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w & p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w | p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p & w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w / p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(w % p); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p / w); }
  { wchar_t w = 2147483647; unsigned p = 3; P(p % w); }
  { wchar_t w = 2147483647; unsigned p = 3; unsigned t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; unsigned t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; unsigned t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; unsigned t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w < p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w > p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w == p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w != p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p < w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p > w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p == w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p - w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w & p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w | p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p & w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w / p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(w % p); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p / w); }
  { wchar_t w = 2147483647; unsigned p = -3; P(p % w); }
  { wchar_t w = 2147483647; unsigned p = -3; unsigned t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = -3; unsigned t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned p = -3; unsigned t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned p = -3; unsigned t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; P(w < p); }
  { wchar_t w = 2147483647; long p = 0; P(w > p); }
  { wchar_t w = 2147483647; long p = 0; P(w == p); }
  { wchar_t w = 2147483647; long p = 0; P(w != p); }
  { wchar_t w = 2147483647; long p = 0; P(w <= p); }
  { wchar_t w = 2147483647; long p = 0; P(w >= p); }
  { wchar_t w = 2147483647; long p = 0; P(p < w); }
  { wchar_t w = 2147483647; long p = 0; P(p > w); }
  { wchar_t w = 2147483647; long p = 0; P(p == w); }
  { wchar_t w = 2147483647; long p = 0; P(w + p); }
  { wchar_t w = 2147483647; long p = 0; P(p + w); }
  { wchar_t w = 2147483647; long p = 0; P(w - p); }
  { wchar_t w = 2147483647; long p = 0; P(p - w); }
  { wchar_t w = 2147483647; long p = 0; P(w * p); }
  { wchar_t w = 2147483647; long p = 0; P(p * w); }
  { wchar_t w = 2147483647; long p = 0; P(w & p); }
  { wchar_t w = 2147483647; long p = 0; P(w | p); }
  { wchar_t w = 2147483647; long p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; long p = 0; P(p & w); }
  { wchar_t w = 2147483647; long p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; long p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; long p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; long p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; long p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long p = 0; P(p / w); }
  { wchar_t w = 2147483647; long p = 0; P(p % w); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; long p = 0; long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; long p = 3; P(w < p); }
  { wchar_t w = 2147483647; long p = 3; P(w > p); }
  { wchar_t w = 2147483647; long p = 3; P(w == p); }
  { wchar_t w = 2147483647; long p = 3; P(w != p); }
  { wchar_t w = 2147483647; long p = 3; P(w <= p); }
  { wchar_t w = 2147483647; long p = 3; P(w >= p); }
  { wchar_t w = 2147483647; long p = 3; P(p < w); }
  { wchar_t w = 2147483647; long p = 3; P(p > w); }
  { wchar_t w = 2147483647; long p = 3; P(p == w); }
  { wchar_t w = 2147483647; long p = 3; P(w + p); }
  { wchar_t w = 2147483647; long p = 3; P(p + w); }
  { wchar_t w = 2147483647; long p = 3; P(w - p); }
  { wchar_t w = 2147483647; long p = 3; P(p - w); }
  { wchar_t w = 2147483647; long p = 3; P(p * w); }
  { wchar_t w = 2147483647; long p = 3; P(w & p); }
  { wchar_t w = 2147483647; long p = 3; P(w | p); }
  { wchar_t w = 2147483647; long p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; long p = 3; P(p & w); }
  { wchar_t w = 2147483647; long p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; long p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; long p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; long p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; long p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long p = 3; P(w / p); }
  { wchar_t w = 2147483647; long p = 3; P(w % p); }
  { wchar_t w = 2147483647; long p = 3; P(p / w); }
  { wchar_t w = 2147483647; long p = 3; P(p % w); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; long p = 3; long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; long p = -3; P(w < p); }
  { wchar_t w = 2147483647; long p = -3; P(w > p); }
  { wchar_t w = 2147483647; long p = -3; P(w == p); }
  { wchar_t w = 2147483647; long p = -3; P(w != p); }
  { wchar_t w = 2147483647; long p = -3; P(w <= p); }
  { wchar_t w = 2147483647; long p = -3; P(w >= p); }
  { wchar_t w = 2147483647; long p = -3; P(p < w); }
  { wchar_t w = 2147483647; long p = -3; P(p > w); }
  { wchar_t w = 2147483647; long p = -3; P(p == w); }
  { wchar_t w = 2147483647; long p = -3; P(p + w); }
  { wchar_t w = 2147483647; long p = -3; P(p - w); }
  { wchar_t w = 2147483647; long p = -3; P(p * w); }
  { wchar_t w = 2147483647; long p = -3; P(w & p); }
  { wchar_t w = 2147483647; long p = -3; P(w | p); }
  { wchar_t w = 2147483647; long p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; long p = -3; P(p & w); }
  { wchar_t w = 2147483647; long p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; long p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; long p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; long p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; long p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long p = -3; P(w / p); }
  { wchar_t w = 2147483647; long p = -3; P(w % p); }
  { wchar_t w = 2147483647; long p = -3; P(p / w); }
  { wchar_t w = 2147483647; long p = -3; P(p % w); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long p = -3; long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w < p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w > p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w == p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w != p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p < w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p > w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p == w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w + p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p + w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w - p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w * p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p * w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w & p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w | p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p & w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p / w); }
  { wchar_t w = 2147483647; unsigned long p = 0; P(p % w); }
  { wchar_t w = 2147483647; unsigned long p = 0; unsigned long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; unsigned long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; unsigned long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; unsigned long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; unsigned long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w < p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w > p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w == p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w != p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p < w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p > w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p == w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w + p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p + w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w - p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w & p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w | p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p & w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w / p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(w % p); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p / w); }
  { wchar_t w = 2147483647; unsigned long p = 3; P(p % w); }
  { wchar_t w = 2147483647; unsigned long p = 3; unsigned long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; unsigned long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; unsigned long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; unsigned long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w < p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w > p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w == p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w != p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p < w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p > w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p == w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p - w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w & p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w | p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p & w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w / p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(w % p); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p / w); }
  { wchar_t w = 2147483647; unsigned long p = -3; P(p % w); }
  { wchar_t w = 2147483647; unsigned long p = -3; unsigned long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = -3; unsigned long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long p = -3; unsigned long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long p = -3; unsigned long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; P(w < p); }
  { wchar_t w = 2147483647; long long p = 0; P(w > p); }
  { wchar_t w = 2147483647; long long p = 0; P(w == p); }
  { wchar_t w = 2147483647; long long p = 0; P(w != p); }
  { wchar_t w = 2147483647; long long p = 0; P(w <= p); }
  { wchar_t w = 2147483647; long long p = 0; P(w >= p); }
  { wchar_t w = 2147483647; long long p = 0; P(p < w); }
  { wchar_t w = 2147483647; long long p = 0; P(p > w); }
  { wchar_t w = 2147483647; long long p = 0; P(p == w); }
  { wchar_t w = 2147483647; long long p = 0; P(w + p); }
  { wchar_t w = 2147483647; long long p = 0; P(p + w); }
  { wchar_t w = 2147483647; long long p = 0; P(w - p); }
  { wchar_t w = 2147483647; long long p = 0; P(p - w); }
  { wchar_t w = 2147483647; long long p = 0; P(w * p); }
  { wchar_t w = 2147483647; long long p = 0; P(p * w); }
  { wchar_t w = 2147483647; long long p = 0; P(w & p); }
  { wchar_t w = 2147483647; long long p = 0; P(w | p); }
  { wchar_t w = 2147483647; long long p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; long long p = 0; P(p & w); }
  { wchar_t w = 2147483647; long long p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; long long p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; long long p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; long long p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; long long p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long long p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long long p = 0; P(p / w); }
  { wchar_t w = 2147483647; long long p = 0; P(p % w); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; long long p = 0; long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long long p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; long long p = 3; P(w < p); }
  { wchar_t w = 2147483647; long long p = 3; P(w > p); }
  { wchar_t w = 2147483647; long long p = 3; P(w == p); }
  { wchar_t w = 2147483647; long long p = 3; P(w != p); }
  { wchar_t w = 2147483647; long long p = 3; P(w <= p); }
  { wchar_t w = 2147483647; long long p = 3; P(w >= p); }
  { wchar_t w = 2147483647; long long p = 3; P(p < w); }
  { wchar_t w = 2147483647; long long p = 3; P(p > w); }
  { wchar_t w = 2147483647; long long p = 3; P(p == w); }
  { wchar_t w = 2147483647; long long p = 3; P(w + p); }
  { wchar_t w = 2147483647; long long p = 3; P(p + w); }
  { wchar_t w = 2147483647; long long p = 3; P(w - p); }
  { wchar_t w = 2147483647; long long p = 3; P(p - w); }
  { wchar_t w = 2147483647; long long p = 3; P(p * w); }
  { wchar_t w = 2147483647; long long p = 3; P(w & p); }
  { wchar_t w = 2147483647; long long p = 3; P(w | p); }
  { wchar_t w = 2147483647; long long p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; long long p = 3; P(p & w); }
  { wchar_t w = 2147483647; long long p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; long long p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; long long p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; long long p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; long long p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long long p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long long p = 3; P(w / p); }
  { wchar_t w = 2147483647; long long p = 3; P(w % p); }
  { wchar_t w = 2147483647; long long p = 3; P(p / w); }
  { wchar_t w = 2147483647; long long p = 3; P(p % w); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; long long p = 3; long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; long long p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; long long p = -3; P(w < p); }
  { wchar_t w = 2147483647; long long p = -3; P(w > p); }
  { wchar_t w = 2147483647; long long p = -3; P(w == p); }
  { wchar_t w = 2147483647; long long p = -3; P(w != p); }
  { wchar_t w = 2147483647; long long p = -3; P(w <= p); }
  { wchar_t w = 2147483647; long long p = -3; P(w >= p); }
  { wchar_t w = 2147483647; long long p = -3; P(p < w); }
  { wchar_t w = 2147483647; long long p = -3; P(p > w); }
  { wchar_t w = 2147483647; long long p = -3; P(p == w); }
  { wchar_t w = 2147483647; long long p = -3; P(p + w); }
  { wchar_t w = 2147483647; long long p = -3; P(p - w); }
  { wchar_t w = 2147483647; long long p = -3; P(p * w); }
  { wchar_t w = 2147483647; long long p = -3; P(w & p); }
  { wchar_t w = 2147483647; long long p = -3; P(w | p); }
  { wchar_t w = 2147483647; long long p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; long long p = -3; P(p & w); }
  { wchar_t w = 2147483647; long long p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; long long p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; long long p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; long long p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; long long p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; long long p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; long long p = -3; P(w / p); }
  { wchar_t w = 2147483647; long long p = -3; P(w % p); }
  { wchar_t w = 2147483647; long long p = -3; P(p / w); }
  { wchar_t w = 2147483647; long long p = -3; P(p % w); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; long long p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; long long p = -3; long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w < p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w > p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w == p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w != p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p < w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p > w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p == w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w + p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p + w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w - p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w * p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p * w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w & p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w | p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p & w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p / w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; P(p % w); }
  { wchar_t w = 2147483647; unsigned long long p = 0; unsigned long long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; unsigned long long t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; unsigned long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; unsigned long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; unsigned long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w < p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w > p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w == p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w != p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p < w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p > w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p == w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w + p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p + w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w - p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w & p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w | p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p & w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w / p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(w % p); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p / w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; P(p % w); }
  { wchar_t w = 2147483647; unsigned long long p = 3; unsigned long long t = p; t += w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; unsigned long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; unsigned long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; unsigned long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w < p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w > p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w == p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w != p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w <= p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w >= p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p < w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p > w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p == w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p - w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w & p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w | p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p & w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w / p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(w % p); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p / w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; P(p % w); }
  { wchar_t w = 2147483647; unsigned long long p = -3; unsigned long long t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = -3; unsigned long long t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = -3; unsigned long long t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; unsigned long long p = -3; unsigned long long t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w < p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w > p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w == p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w != p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w <= p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w >= p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p < w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p > w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p == w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w + p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p + w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w - p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w * p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p * w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w & p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w | p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p & w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; enum EU p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; enum EU p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; enum EU p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; enum EU p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p / w); }
  { wchar_t w = 2147483647; enum EU p = 0; P(p % w); }
  { wchar_t w = 2147483647; enum EU p = 0; enum EU t = p; t += w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; enum EU t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; enum EU t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; enum EU t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; enum EU t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w < p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w > p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w == p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w != p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w <= p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w >= p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p < w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p > w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p == w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w + p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p + w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w - p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w & p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w | p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p & w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; enum EU p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; enum EU p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; enum EU p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w / p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(w % p); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p / w); }
  { wchar_t w = 2147483647; enum EU p = 3; P(p % w); }
  { wchar_t w = 2147483647; enum EU p = 3; enum EU t = p; t += w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; enum EU t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; enum EU t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; enum EU t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; enum EU p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w < p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w > p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w == p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w != p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w <= p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w >= p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p < w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p > w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p == w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w + p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p + w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w - p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p - w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w * p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p * w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w & p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w | p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p & w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; enum ES p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; enum ES p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; enum ES p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; enum ES p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p / w); }
  { wchar_t w = 2147483647; enum ES p = 0; P(p % w); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t += w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; enum ES t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w < p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w > p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w == p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w != p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w <= p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w >= p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p < w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p > w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p == w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w - p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p - w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w & p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w | p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p & w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; enum ES p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; enum ES p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; enum ES p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w / p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(w % p); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p / w); }
  { wchar_t w = 2147483647; enum ES p = 3; P(p % w); }
  { wchar_t w = 2147483647; enum ES p = 3; enum ES t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; enum ES t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; enum ES t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; enum ES t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w < p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w > p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w == p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w != p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w <= p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w >= p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p < w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p > w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p == w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p + w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w & p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w | p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p & w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; enum ES p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; enum ES p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; enum ES p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w / p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(w % p); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p / w); }
  { wchar_t w = 2147483647; enum ES p = -3; P(p % w); }
  { wchar_t w = 2147483647; enum ES p = -3; enum ES t = p; t += w; P(t); }
  { wchar_t w = 2147483647; enum ES p = -3; enum ES t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; enum ES p = -3; enum ES t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; enum ES p = -3; enum ES t = p; t ^= w; P(t); }
  printf("\n");
  return 0;
}
