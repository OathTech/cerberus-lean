int main(void) { int a['\377' > 0 ? 2 : 1]; a[0] = 0; return (int)(sizeof a / sizeof a[0]) + a[0]; }
