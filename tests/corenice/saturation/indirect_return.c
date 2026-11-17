static int recur(int);
static int (*target)(int) = recur;
static int recur(int n) { return n ? target(n - 1) + 1 : 0; }
int main(void) { return target(12); }
