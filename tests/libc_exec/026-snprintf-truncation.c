// 026: snprintf truncation, size 0, NULL buffer with size 0, empty format
// (served-surface probe p2_snprintf, verbatim). The model returns the number
// of characters STORED (not the untruncated length): a shared-model
// behaviour, observed in both engines.
#include <stdio.h>
#include <string.h>
int main(void) {
  char buf[8];
  memset(buf, 'X', 8);
  int a = snprintf(buf, 4, "%d", 123456);      /* -> "123", returns 6 */
  int b = snprintf(buf + 4, 0, "%s", "zzz");   /* size 0: nothing written, returns 3 */
  int c = snprintf(NULL, 0, "%d%d", 12, 34);   /* returns 4 */
  int d = snprintf(buf, 8, "");                /* returns 0, buf = "" */
  return a * 1000 + b * 100 + c * 10 + (d == 0) + (buf[0] == 0 ? 0 : 50000) + (buf[4] == 'X' ? 0 : 60000);
}
