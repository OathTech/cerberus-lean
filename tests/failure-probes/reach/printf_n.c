int printf(const char *, ...);
int main(void) { int n = 0; printf("ab%n\n", &n); return n; }
