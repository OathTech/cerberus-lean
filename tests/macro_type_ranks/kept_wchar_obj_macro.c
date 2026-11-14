// KEPT (upstream's behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f's line; gcc 13's line beside in kept.txt): a wchar_t object (200000005, 2147483647) against the other macro integer types and itself, both orders, every operator and op=
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  { wchar_t w = 200000005; size_t p = 0; P(w < p); }
  { wchar_t w = 200000005; size_t p = 0; P(w > p); }
  { wchar_t w = 200000005; size_t p = 0; P(w == p); }
  { wchar_t w = 200000005; size_t p = 0; P(w != p); }
  { wchar_t w = 200000005; size_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; size_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; size_t p = 0; P(p < w); }
  { wchar_t w = 200000005; size_t p = 0; P(p > w); }
  { wchar_t w = 200000005; size_t p = 0; P(p == w); }
  { wchar_t w = 200000005; size_t p = 0; P(w + p); }
  { wchar_t w = 200000005; size_t p = 0; P(p + w); }
  { wchar_t w = 200000005; size_t p = 0; P(w - p); }
  { wchar_t w = 200000005; size_t p = 0; P(p - w); }
  { wchar_t w = 200000005; size_t p = 0; P(w * p); }
  { wchar_t w = 200000005; size_t p = 0; P(p * w); }
  { wchar_t w = 200000005; size_t p = 0; P(w & p); }
  { wchar_t w = 200000005; size_t p = 0; P(w | p); }
  { wchar_t w = 200000005; size_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; size_t p = 0; P(p & w); }
  { wchar_t w = 200000005; size_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; size_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; size_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; size_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; size_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; size_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; size_t p = 0; P(p / w); }
  { wchar_t w = 200000005; size_t p = 0; P(p % w); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; size_t p = 0; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; size_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; P(w < p); }
  { wchar_t w = 200000005; size_t p = 3; P(w > p); }
  { wchar_t w = 200000005; size_t p = 3; P(w == p); }
  { wchar_t w = 200000005; size_t p = 3; P(w != p); }
  { wchar_t w = 200000005; size_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; size_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; size_t p = 3; P(p < w); }
  { wchar_t w = 200000005; size_t p = 3; P(p > w); }
  { wchar_t w = 200000005; size_t p = 3; P(p == w); }
  { wchar_t w = 200000005; size_t p = 3; P(w + p); }
  { wchar_t w = 200000005; size_t p = 3; P(p + w); }
  { wchar_t w = 200000005; size_t p = 3; P(w - p); }
  { wchar_t w = 200000005; size_t p = 3; P(p - w); }
  { wchar_t w = 200000005; size_t p = 3; P(w * p); }
  { wchar_t w = 200000005; size_t p = 3; P(p * w); }
  { wchar_t w = 200000005; size_t p = 3; P(w & p); }
  { wchar_t w = 200000005; size_t p = 3; P(w | p); }
  { wchar_t w = 200000005; size_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; size_t p = 3; P(p & w); }
  { wchar_t w = 200000005; size_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; size_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; size_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; size_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; size_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; size_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; size_t p = 3; P(w / p); }
  { wchar_t w = 200000005; size_t p = 3; P(w % p); }
  { wchar_t w = 200000005; size_t p = 3; P(p / w); }
  { wchar_t w = 200000005; size_t p = 3; P(p % w); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; size_t p = 3; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; size_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; size_t p = -3; P(w < p); }
  { wchar_t w = 200000005; size_t p = -3; P(w > p); }
  { wchar_t w = 200000005; size_t p = -3; P(w == p); }
  { wchar_t w = 200000005; size_t p = -3; P(w != p); }
  { wchar_t w = 200000005; size_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; size_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; size_t p = -3; P(p < w); }
  { wchar_t w = 200000005; size_t p = -3; P(p > w); }
  { wchar_t w = 200000005; size_t p = -3; P(p == w); }
  { wchar_t w = 200000005; size_t p = -3; P(w + p); }
  { wchar_t w = 200000005; size_t p = -3; P(p + w); }
  { wchar_t w = 200000005; size_t p = -3; P(w - p); }
  { wchar_t w = 200000005; size_t p = -3; P(p - w); }
  { wchar_t w = 200000005; size_t p = -3; P(w * p); }
  { wchar_t w = 200000005; size_t p = -3; P(p * w); }
  { wchar_t w = 200000005; size_t p = -3; P(w & p); }
  { wchar_t w = 200000005; size_t p = -3; P(w | p); }
  { wchar_t w = 200000005; size_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; size_t p = -3; P(p & w); }
  { wchar_t w = 200000005; size_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; size_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; size_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; size_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; size_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; size_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; size_t p = -3; P(w / p); }
  { wchar_t w = 200000005; size_t p = -3; P(w % p); }
  { wchar_t w = 200000005; size_t p = -3; P(p / w); }
  { wchar_t w = 200000005; size_t p = -3; P(p % w); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; size_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; size_t p = -3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; size_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; size_t p = -3; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w < p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w > p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w == p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w != p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p < w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p > w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p == w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w + p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p + w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w - p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p - w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w * p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p * w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w & p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w | p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p & w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p / w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; P(p % w); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w < p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w > p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w == p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w != p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p < w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p > w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p == w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w + p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p + w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w - p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p - w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w * p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p * w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w & p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w | p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p & w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w / p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(w % p); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p / w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; P(p % w); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w < p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w > p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w == p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w != p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p < w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p > w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p == w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p + w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p - w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p * w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w & p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w | p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p & w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w / p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(w % p); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p / w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; P(p % w); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; ptrdiff_t p = -3; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w < p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w > p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w == p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w != p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p < w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p > w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p == w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w + p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p + w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w - p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p - w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w * p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p * w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w & p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w | p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p & w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; intptr_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; intptr_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; intptr_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intptr_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p / w); }
  { wchar_t w = 200000005; intptr_t p = 0; P(p % w); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w < p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w > p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w == p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w != p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p < w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p > w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p == w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w + p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p + w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w - p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p - w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w * p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p * w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w & p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w | p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p & w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; intptr_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; intptr_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intptr_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w / p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(w % p); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p / w); }
  { wchar_t w = 200000005; intptr_t p = 3; P(p % w); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w < p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w > p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w == p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w != p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p < w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p > w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p == w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w + p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p + w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w - p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p - w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w * p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p * w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w & p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w | p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p & w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; intptr_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; intptr_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intptr_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w / p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(w % p); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p / w); }
  { wchar_t w = 200000005; intptr_t p = -3; P(p % w); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intptr_t p = -3; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w < p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w > p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w == p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w != p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p < w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p > w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p == w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w + p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p + w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w - p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p - w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w * p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p * w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w & p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w | p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p & w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p / w); }
  { wchar_t w = 200000005; uintptr_t p = 0; P(p % w); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w < p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w > p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w == p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w != p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p < w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p > w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p == w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w + p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p + w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w - p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p - w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w * p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p * w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w & p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w | p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p & w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w / p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(w % p); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p / w); }
  { wchar_t w = 200000005; uintptr_t p = 3; P(p % w); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w < p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w > p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w == p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w != p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p < w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p > w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p == w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w + p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p + w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w - p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p - w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w * p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p * w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w & p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w | p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p & w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w / p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(w % p); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p / w); }
  { wchar_t w = 200000005; uintptr_t p = -3; P(p % w); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintptr_t p = -3; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w < p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w > p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w == p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w != p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p < w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p > w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p == w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w + p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p + w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w - p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p - w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w * p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p * w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w & p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w | p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p & w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; intmax_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; intmax_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; intmax_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intmax_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p / w); }
  { wchar_t w = 200000005; intmax_t p = 0; P(p % w); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w < p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w > p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w == p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w != p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p < w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p > w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p == w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w + p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p + w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w - p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p - w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w * p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p * w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w & p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w | p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p & w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; intmax_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; intmax_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intmax_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w / p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(w % p); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p / w); }
  { wchar_t w = 200000005; intmax_t p = 3; P(p % w); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w < p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w > p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w == p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w != p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p < w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p > w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p == w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p + w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p - w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p * w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w & p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w | p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p & w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; intmax_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; intmax_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; intmax_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w / p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(w % p); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p / w); }
  { wchar_t w = 200000005; intmax_t p = -3; P(p % w); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; intmax_t p = -3; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w < p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w > p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w == p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w != p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p < w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p > w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p == w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w + p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p + w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w - p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w * p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p * w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w & p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w | p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p & w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p / w); }
  { wchar_t w = 200000005; uintmax_t p = 0; P(p % w); }
  { wchar_t w = 200000005; uintmax_t p = 0; uintmax_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; uintmax_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w < p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w > p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w == p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w != p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p < w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p > w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p == w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w + p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p + w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w - p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w * p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p * w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w & p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w | p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p & w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w / p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(w % p); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p / w); }
  { wchar_t w = 200000005; uintmax_t p = 3; P(p % w); }
  { wchar_t w = 200000005; uintmax_t p = 3; uintmax_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; uintmax_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w < p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w > p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w == p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w != p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w <= p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w >= p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p < w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p > w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p == w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p - w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w & p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w | p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w ^ p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p & w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(1 ? w : p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(1 ? p : w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(TC(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(TC(p + w)); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w / p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(w % p); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p / w); }
  { wchar_t w = 200000005; uintmax_t p = -3; P(p % w); }
  { wchar_t w = 200000005; uintmax_t p = -3; uintmax_t t = p; t -= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = -3; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; uintmax_t p = -3; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; uintmax_t p = -3; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w < p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w > p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w == p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w != p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w <= p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w >= p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p < w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p > w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p == w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w + p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p + w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w - p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w * p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p * w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w & p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w | p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(w ^ p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p & w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(1 ? w : p); }
  { wchar_t w = 200000005; wchar_t p = 0; P(1 ? p : w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(TC(w + p)); }
  { wchar_t w = 200000005; wchar_t p = 0; P(TC(p + w)); }
  { wchar_t w = 200000005; wchar_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; wchar_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p / w); }
  { wchar_t w = 200000005; wchar_t p = 0; P(p % w); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w < p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w > p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w == p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w != p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w <= p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w >= p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p < w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p > w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p == w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w + p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p + w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w - p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w * p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p * w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w & p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w | p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w ^ p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p & w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(1 ? w : p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(1 ? p : w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(TC(w + p)); }
  { wchar_t w = 200000005; wchar_t p = 3; P(TC(p + w)); }
  { wchar_t w = 200000005; wchar_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 200000005; wchar_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w / p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(w % p); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p / w); }
  { wchar_t w = 200000005; wchar_t p = 3; P(p % w); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = p; t += w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = p; t *= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = p; t &= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = p; t |= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = p; t ^= w; P(t); }
  { wchar_t w = 200000005; wchar_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; size_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; size_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; size_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; size_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; size_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; size_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; size_t p = 0; P(p - w); }
  { wchar_t w = 2147483647; size_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; size_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; size_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; size_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; size_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; size_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; size_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; size_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; size_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; size_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; size_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; size_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; size_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; size_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; size_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; size_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; size_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p - w); }
  { wchar_t w = 2147483647; size_t p = 3; P(w * p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p * w); }
  { wchar_t w = 2147483647; size_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; size_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; size_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; size_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; size_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; size_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; size_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; size_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; size_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; size_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; size_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; size_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; size_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; size_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; size_t p = -3; P(w + p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p + w); }
  { wchar_t w = 2147483647; size_t p = -3; P(w - p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; size_t p = -3; P(w * p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p * w); }
  { wchar_t w = 2147483647; size_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; size_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; size_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; size_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; size_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; size_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; size_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; size_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; size_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; size_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; size_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; size_t p = -3; size_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p - w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p - w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p * w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p + w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p * w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; ptrdiff_t p = -3; ptrdiff_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p - w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; intptr_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p - w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w * p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p * w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; intptr_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w + p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p + w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w - p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w * p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p * w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; intptr_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intptr_t p = -3; intptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p - w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p - w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w * p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p * w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w + p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p + w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w - p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w * p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p * w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintptr_t p = -3; uintptr_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p - w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; intmax_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p - w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p * w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; intmax_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p + w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p * w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; intmax_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; intmax_t p = -3; intmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; uintmax_t p = 0; uintmax_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; uintmax_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w + p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p + w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; uintmax_t p = 3; uintmax_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = 3; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w < p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w > p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w == p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w != p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w <= p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w >= p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p < w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p > w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p == w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p - w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w & p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w | p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w ^ p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p & w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(1 ? w : p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(1 ? p : w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(TC(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(TC(p + w)); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w / p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(w % p); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p / w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; P(p % w); }
  { wchar_t w = 2147483647; uintmax_t p = -3; uintmax_t t = p; t -= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = -3; uintmax_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = -3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = -3; uintmax_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; uintmax_t p = -3; uintmax_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w < p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w > p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w == p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w != p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w <= p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w >= p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p < w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p > w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p == w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w + p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p + w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w - p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w * p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p * w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w & p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w | p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(w ^ p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p & w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(1 ? w : p); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(1 ? p : w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(TC(w + p)); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(TC(p + w)); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p / w); }
  { wchar_t w = 2147483647; wchar_t p = 0; P(p % w); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = p; t += w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t += p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = p; t *= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t *= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 0; wchar_t t = w; t ^= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w < p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w > p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w == p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w != p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w <= p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w >= p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p < w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p > w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p == w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w - p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w & p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w | p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w ^ p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p & w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(1 ? w : p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(1 ? p : w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(TC(w + p)); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(TC(p + w)); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(TC(1 ? w : p)); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(sizeof(w + p)); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w / p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(w % p); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p / w); }
  { wchar_t w = 2147483647; wchar_t p = 3; P(p % w); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = w; t -= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = p; t &= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = w; t &= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = p; t |= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = w; t |= p; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = p; t ^= w; P(t); }
  { wchar_t w = 2147483647; wchar_t p = 3; wchar_t t = w; t ^= p; P(t); }
  printf("\n");
  return 0;
}
