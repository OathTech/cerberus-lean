#include <wchar.h>
int main(void) {
  wchar_t ws[] = L"ab";
  wchar_t c = L'A';
  return (ws[0] == L'a') + (ws[1] == L'b') + (ws[2] == 0) + (c == 65);  /* 4 */
}
