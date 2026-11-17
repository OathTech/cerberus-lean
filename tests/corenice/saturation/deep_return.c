static int depth(int n) { return n ? depth(n - 1) + 1 : 0; }
int main(void) { return depth(64); }
