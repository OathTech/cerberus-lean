/* tray 10 inside a wide string literal: L"a\?b"[1]. gcc 13: Specified(63). Pristine c3ff8c53f: rc 125. Moved. */
#include <stddef.h>
int main(void) { const wchar_t *s = L"a\?b"; return s[1]; }
