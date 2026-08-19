/* snprintf + strlen through libc (arc-6 S1).
   RECORDED DIFF — varargs-classified, S2 scope: libc's snprintf does
   va_start and hands the va_list id to the builtin vsnprintf, whose
   formatted.lem:797 `Mem.va_list ap_idx` hits the CerbMem
   vaStart/vaList STUBS (CerbMem.lean:1587-1591, register 15). The
   Lean side panics "TODO: snprintf()" (formatted.lem:806) because the
   stubbed va_list yields no arguments. Oracle: Specified(18).
   Expected to flip to MATCH when S2 lands the varargs memops. */
#include <stdio.h>
#include <string.h>
int main(void) {
  char buf[32];
  int n = snprintf(buf, sizeof buf, "v=%d s=%s", 41, "ok");
  return n + (int)strlen(buf); /* 9 + 9 = 18 */
}
