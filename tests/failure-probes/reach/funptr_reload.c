int main(void) { void (*f)(void) = (void (*)(void))0xABC; void (*g)(void); g = f; return g == f; }
