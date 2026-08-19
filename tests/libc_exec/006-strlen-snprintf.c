/* snprintf + strlen through libc (arc-6 S1).
   S1 recorded this as DIFF — varargs-classified: libc's snprintf does
   va_start and hands the va_list id to the builtin vsnprintf, whose
   formatted.lem:797 `Mem.va_list ap_idx` hit the CerbMem
   vaStart/vaList STUBS (register 15); the Lean side panicked
   "TODO: snprintf()" (formatted.lem:806) because the stubbed va_list
   yielded no arguments. Arc-6 S2 implemented the varargs memops
   (impl_mem.ml:2698-2764 mirror) — now MATCH: Specified(18). */
#include <stdio.h>
#include <string.h>
int main(void) {
  char buf[32];
  int n = snprintf(buf, sizeof buf, "v=%d s=%s", 41, "ok");
  return n + (int)strlen(buf); /* 9 + 9 = 18 */
}
