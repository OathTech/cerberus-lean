/* Corner: string.h boundary behaviour: strncpy pads with NUL, strcmp
   compares as unsigned char (ISO C11 7.24.4p1), strchr of NUL, strncmp with
   n = 0, memcmp sign of result. Sequenced statements. */
#include <string.h>
#include <stdio.h>
int main(void) {
  char buf[6] = "xxxxx";
  strncpy(buf, "ab", 5);
  int z = buf[2] + buf[3] + buf[4];          /* 0 */
  char hi[2] = { (char)0x80, 0 };
  int c1 = strcmp(hi, "a") > 0;              /* 1 */
  int c2 = strncmp("abc", "xyz", 0);         /* 0 */
  int c3 = (int)strlen(strchr("hello", '\0')); /* 0 */
  int c4 = memcmp("a", "b", 1) < 0;          /* 1 */
  printf("%d %d %d %d %d %d\n", z, buf[5], c1, c2, c3, c4);   /* 0 120 1 0 0 1 */
  return 0;
}
