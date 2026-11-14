// KEPT (upstream's behaviour for wchar_t / wint_t, pinned to pristine c3ff8c53f's line; gcc 13's line beside in kept.txt): wchar_t objects, casts and wide character constants on their own: promotion, unary operators, shifts, conversions
// Generated 2026-11-14 from the measured vicinity of the wchar_t rank correction (record
// lean_frontend/docs/2026-11-14_wchar-rank-record.md, section 3); one value per expression, in order.
#include <stdio.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#define P(e) printf("%llu ", (unsigned long long)(e))
#define TC(e) _Generic((e), _Bool:1, char:2, signed char:3, unsigned char:4, short:5, unsigned short:6, int:7, unsigned:8, long:9, unsigned long:10, long long:11, unsigned long long:12, default:99)
int main(void) {
  { wchar_t w = 0; P(+w); }
  { wchar_t w = 0; P(-w); }
  { wchar_t w = 0; P(~w); }
  { wchar_t w = 0; P(!w); }
  { wchar_t w = 0; P(w > 0); }
  { wchar_t w = 0; P(w < 0); }
  { wchar_t w = 0; P(w == 0); }
  { wchar_t w = 0; P((+w) > 0); }
  { wchar_t w = 0; P(sizeof(w)); }
  { wchar_t w = 0; P(sizeof(+w)); }
  { wchar_t w = 0; P(TC(w)); }
  { wchar_t w = 0; P(TC(+w)); }
  { wchar_t w = 0; P(TC(-w)); }
  { wchar_t w = 0; P(TC(~w)); }
  { wchar_t w = 0; P(w << 1); }
  { wchar_t w = 0; P(w >> 1); }
  { wchar_t w = 0; P(1 << w); }
  { wchar_t w = 0; P(w + 1); }
  { wchar_t w = 0; P(w + 1 > 0); }
  { wchar_t w = 0; P(w + 1u); }
  { wchar_t w = 0; P(w++); }
  { wchar_t w = 0; P(w && 1); }
  { wchar_t w = 0; P(w ? 2 : 3); }
  { wchar_t w = 0; P((_Bool)w); }
  { wchar_t w = 0; P((signed char)w); }
  { wchar_t w = 0; P((unsigned char)w); }
  { wchar_t w = 0; P((short)w); }
  { wchar_t w = 0; P((unsigned short)w); }
  { wchar_t w = 0; P((int)w); }
  { wchar_t w = 0; P((unsigned)w); }
  { wchar_t w = 0; P((long)w); }
  { wchar_t w = 0; P((unsigned long)w); }
  { wchar_t w = 0; P((long long)w); }
  { wchar_t w = 0; P((unsigned long long)w); }
  { wchar_t w = 5; P(+w); }
  { wchar_t w = 5; P(~w); }
  { wchar_t w = 5; P(!w); }
  { wchar_t w = 5; P(w > 0); }
  { wchar_t w = 5; P(w < 0); }
  { wchar_t w = 5; P(w == 0); }
  { wchar_t w = 5; P((+w) > 0); }
  { wchar_t w = 5; P(sizeof(w)); }
  { wchar_t w = 5; P(sizeof(+w)); }
  { wchar_t w = 5; P(TC(w)); }
  { wchar_t w = 5; P(TC(+w)); }
  { wchar_t w = 5; P(TC(-w)); }
  { wchar_t w = 5; P(TC(~w)); }
  { wchar_t w = 5; P(w << 1); }
  { wchar_t w = 5; P(w >> 1); }
  { wchar_t w = 5; P(1 << w); }
  { wchar_t w = 5; P(w + 1); }
  { wchar_t w = 5; P(w - 1); }
  { wchar_t w = 5; P(w - 1 < 0); }
  { wchar_t w = 5; P(w + 1 > 0); }
  { wchar_t w = 5; P(w + 1u); }
  { wchar_t w = 5; P(w++); }
  { wchar_t w = 5; P(--w); }
  { wchar_t w = 5; P(w && 1); }
  { wchar_t w = 5; P(w ? 2 : 3); }
  { wchar_t w = 5; P((_Bool)w); }
  { wchar_t w = 5; P((signed char)w); }
  { wchar_t w = 5; P((unsigned char)w); }
  { wchar_t w = 5; P((short)w); }
  { wchar_t w = 5; P((unsigned short)w); }
  { wchar_t w = 5; P((int)w); }
  { wchar_t w = 5; P((unsigned)w); }
  { wchar_t w = 5; P((long)w); }
  { wchar_t w = 5; P((unsigned long)w); }
  { wchar_t w = 5; P((long long)w); }
  { wchar_t w = 5; P((unsigned long long)w); }
  { wchar_t w = 200000005; P(+w); }
  { wchar_t w = 200000005; P(~w); }
  { wchar_t w = 200000005; P(!w); }
  { wchar_t w = 200000005; P(w > 0); }
  { wchar_t w = 200000005; P(w < 0); }
  { wchar_t w = 200000005; P(w == 0); }
  { wchar_t w = 200000005; P((+w) > 0); }
  { wchar_t w = 200000005; P(sizeof(w)); }
  { wchar_t w = 200000005; P(sizeof(+w)); }
  { wchar_t w = 200000005; P(TC(w)); }
  { wchar_t w = 200000005; P(TC(+w)); }
  { wchar_t w = 200000005; P(TC(-w)); }
  { wchar_t w = 200000005; P(TC(~w)); }
  { wchar_t w = 200000005; P(w << 1); }
  { wchar_t w = 200000005; P(w >> 1); }
  { wchar_t w = 200000005; P(w + 1); }
  { wchar_t w = 200000005; P(w - 1); }
  { wchar_t w = 200000005; P(w - 1 < 0); }
  { wchar_t w = 200000005; P(w + 1 > 0); }
  { wchar_t w = 200000005; P(w - 10 < 0); }
  { wchar_t w = 200000005; P(w + 1u); }
  { wchar_t w = 200000005; P(w - 6l); }
  { wchar_t w = 200000005; P(w++); }
  { wchar_t w = 200000005; P(--w); }
  { wchar_t w = 200000005; P(w && 1); }
  { wchar_t w = 200000005; P(w ? 2 : 3); }
  { wchar_t w = 200000005; P((_Bool)w); }
  { wchar_t w = 200000005; P((signed char)w); }
  { wchar_t w = 200000005; P((unsigned char)w); }
  { wchar_t w = 200000005; P((short)w); }
  { wchar_t w = 200000005; P((unsigned short)w); }
  { wchar_t w = 200000005; P((int)w); }
  { wchar_t w = 200000005; P((unsigned)w); }
  { wchar_t w = 200000005; P((long)w); }
  { wchar_t w = 200000005; P((unsigned long)w); }
  { wchar_t w = 200000005; P((long long)w); }
  { wchar_t w = 200000005; P((unsigned long long)w); }
  { wchar_t w = 2147483647; P(+w); }
  { wchar_t w = 2147483647; P(~w); }
  { wchar_t w = 2147483647; P(!w); }
  { wchar_t w = 2147483647; P(w > 0); }
  { wchar_t w = 2147483647; P(w < 0); }
  { wchar_t w = 2147483647; P(w == 0); }
  { wchar_t w = 2147483647; P((+w) > 0); }
  { wchar_t w = 2147483647; P(sizeof(w)); }
  { wchar_t w = 2147483647; P(sizeof(+w)); }
  { wchar_t w = 2147483647; P(TC(w)); }
  { wchar_t w = 2147483647; P(TC(+w)); }
  { wchar_t w = 2147483647; P(TC(-w)); }
  { wchar_t w = 2147483647; P(TC(~w)); }
  { wchar_t w = 2147483647; P(w >> 1); }
  { wchar_t w = 2147483647; P(w - 1); }
  { wchar_t w = 2147483647; P(w - 1 < 0); }
  { wchar_t w = 2147483647; P(w + 1 > 0); }
  { wchar_t w = 2147483647; P(w - 10 < 0); }
  { wchar_t w = 2147483647; P(w + 1u); }
  { wchar_t w = 2147483647; P(w - 6l); }
  { wchar_t w = 2147483647; P(--w); }
  { wchar_t w = 2147483647; P(w && 1); }
  { wchar_t w = 2147483647; P(w ? 2 : 3); }
  { wchar_t w = 2147483647; P((_Bool)w); }
  { wchar_t w = 2147483647; P((signed char)w); }
  { wchar_t w = 2147483647; P((unsigned char)w); }
  { wchar_t w = 2147483647; P((short)w); }
  { wchar_t w = 2147483647; P((unsigned short)w); }
  { wchar_t w = 2147483647; P((int)w); }
  { wchar_t w = 2147483647; P((unsigned)w); }
  { wchar_t w = 2147483647; P((long)w); }
  { wchar_t w = 2147483647; P((unsigned long)w); }
  { wchar_t w = 2147483647; P((long long)w); }
  { wchar_t w = 2147483647; P((unsigned long long)w); }
  P(L'a');
  P(L'a' + 1);
  P(L'a' > 0);
  P(TC(L'a'));
  P(sizeof(L'a'));
  P((wchar_t)-1 < 0);
  P((wchar_t)-1);
  P((wchar_t)-1 > 0);
  P((wchar_t)3000000000u);
  P((wchar_t)5 / -1);
  P((wchar_t)5 < -1);
  P((wchar_t)5 < -1l);
  P((wchar_t)5 < 4294967295u);
  P(~(wchar_t)5 < 0);
  P(TC((wchar_t)5 + 1));
  P(TC((wchar_t)5 + 1l));
  P(TC((wchar_t)5 + 1u));
  P(TC(+(wchar_t)5));
  P(TC(1 ? (wchar_t)5 : (short)1));
  P(sizeof((wchar_t)5 + (short)1));
  P(L"ab"[0]);
  P(L"ab"[0] + 1 > 0);
  P(sizeof(L"ab"));
  { wchar_t a[3] = {1, 2, 3}; P(a[1] + a[2]); }
  { wchar_t w = 7; wchar_t *q = &w; P(*q * 2); }
  { wchar_t w = 7; int i = 9; P(i > w ? i : w); }
  { wchar_t w = 7; long l = 8589934592; P(w + l); }
  { wchar_t w = 7; long l = 8589934592; P(l + w); }
  { wchar_t w = 7; long l = 8589934592; P(w < l); }
  { wchar_t w = 7; unsigned long l = 8589934592; P(w + l); }
  { wchar_t w = 7; long long l = 8589934592; P(w + l); }
  { wchar_t w = 7; long long l = 8589934592; P(l - w); }
  { wchar_t w = 7; unsigned long long l = 8589934592; P(l * w); }
  { wchar_t w = 7; int i = -9; P(w + i); }
  { wchar_t w = 7; int i = -9; P(w + i < 0); }
  { wchar_t w = 7; int i = -9; P(w > i); }
  { wchar_t w = 7; short i = -9; P(w > i); }
  printf("\n");
  return 0;
}
