/* gap: L"\377" stores a negative value into a wchar_t object -- the bytes_of_int(signed) assertion on both engines (tray 62, unchanged by this slice); gcc 13: 255. */
#include <stddef.h>
int main(void) { const wchar_t *s = L"\377"; return (int)(s[0] & 0xff); }
