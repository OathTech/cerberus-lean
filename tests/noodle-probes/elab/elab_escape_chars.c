/* Corner: simple and numeric escape sequences in character constants
   (ISO C11 6.4.4.4): \a \b \f \v \0 \x7f \177 \' \" \\ and a bare '"'.
   ('\?' is tray 10, excluded.) */
#include <stdio.h>
int main(void) {
  printf("%d %d %d %d %d %d %d %d %d %d %d\n", '\a', '\b', '\f', '\v', '\0', '\x7f', '\177', '\'', '\"', '\\', '"');   /* 7 8 12 11 0 127 127 39 34 92 34 */
  return 0;
}
