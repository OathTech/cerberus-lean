/* varargs × Formatted interplay (arc-6 S2, charter S2 bar).
   A USER variadic wrapper: va_start in user code (CerbMem.vaStart via
   the Va_start memop, driver.lem:847-855), the va_list VALUE (a
   Prov_none integer id) passed into libc's vsnprintf, whose builtin
   consumes it through formatted.lem:797 `Mem.va_list ap_idx`
   (CerbMem.vaList) — memop-varargs and the Formatted printf path
   composed in one trace, plus va_end on the way out.
   "x=7 y=hi" → vsnprintf returns 8, strlen(buf) = 8 → 16. */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

static int fmt_into(char *buf, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsnprintf(buf, n, fmt, ap);
  va_end(ap);
  return r;
}

int main(void) {
  char buf[32];
  int n = fmt_into(buf, sizeof buf, "x=%d y=%s", 7, "hi");
  return n + (int)strlen(buf); /* 8 + 8 = 16 */
}
