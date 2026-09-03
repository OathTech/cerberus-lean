/* Corner: strcat/strncat/strstr/strrchr/memchr/strspn/strcspn (ISO C11
   7.24). Sequenced. (strtok is absent from the Cerberus libc: both engines
   report an unknown procedure — see the record, ODDITY O3.) */
#include <string.h>
#include <stdio.h>
int main(void) {
  char buf[32] = "ab";
  strcat(buf, "cd"); strncat(buf, "efgh", 2);          /* "abcdef" */
  const char *s = "hello world";
  int i1 = (int)(strstr(s, "o w") - s);                 /* 4 */
  int i2 = (int)(strrchr(s, 'o') - s);                  /* 7 */
  int i3 = (int)((char*)memchr(s, 'w', 11) - s);        /* 6 */
  int i4 = (int)strspn("aabbc", "ab");                  /* 4 */
  int i5 = (int)strcspn("hello", "lo");                 /* 2 */
  int i6 = strstr(s, "xyz") == 0;                       /* 1 */
  printf("%s %d %d %d %d %d %d %d\n", buf, (int)strlen(buf), i1, i2, i3, i4, i5, i6);   /* abcdef 6 4 7 6 4 2 1 */
  return 0;
}
