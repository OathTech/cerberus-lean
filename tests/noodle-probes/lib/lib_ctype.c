/* Corner: <ctype.h> classification and case mapping on values in the
   unsigned char range (ISO C11 7.4). Sequenced. */
#include <ctype.h>
#include <stdio.h>
int main(void) {
  int r[10];
  r[0] = isalpha('a') != 0; r[1] = isdigit('7') != 0; r[2] = toupper('a'); r[3] = tolower('Z'); r[4] = isspace('\n') != 0;
  r[5] = isxdigit('f') != 0; r[6] = ispunct('!') != 0; r[7] = isalnum('_') != 0; r[8] = toupper('1'); r[9] = isupper(200) != 0;
  printf("%d %d %d %d %d %d %d %d %d %d\n", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]);   /* 1 1 65 122 1 1 1 0 49 0 */
  return 0;
}
