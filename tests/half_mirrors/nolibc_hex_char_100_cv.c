/* declared: '\x100' is a constraint violation (6.4.4.4#9) that both engines and gcc -w accept as the wrapped value 0 (gcc -pedantic-errors rejects it). Unmoved. */
int main(void) { int c = '\x100'; return c & 0xff; }
