int main(void) { char pad = 0; char *p = &(_Alignas(64) char){0}; return ((unsigned long)p % 64 != 0) + pad; }
