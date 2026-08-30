int counter(void) { static int c = 40; return ++c; }
int main(void) { counter(); return counter(); }  /* 42 */
