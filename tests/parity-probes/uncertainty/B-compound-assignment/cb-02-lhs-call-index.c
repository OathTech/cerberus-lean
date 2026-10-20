static int n; static int g(void){ n++; return 0; }
int main(void){ int a[2] = {0, 0}; a[g()] += 4; return n*10 + a[0]; }
