enum e { A = '\377', B = '\200' };
int main(void) { return (A > 0 ? 2 : 1) + (B == 128 ? 8 : 0) + (A == -1 ? 16 : 0) + (sizeof(enum e) == 4 ? 32 : 0); }
