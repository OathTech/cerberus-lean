/* gap: a multi-character constant (tray 63) crashes both engines in the decoder's catch-all; gcc 13: 98 (implementation-defined). */
int main(void) { int c = 'ab'; return c & 0xff; }
