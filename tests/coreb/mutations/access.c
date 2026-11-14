/* Dropping an observed access must fail even though the exit value stays 7. */
int main(void) { int x = 7; int *p = &x; *p = 7; return *p; }
