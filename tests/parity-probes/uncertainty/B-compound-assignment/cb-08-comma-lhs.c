static int n; int main(void){ int a[2] = {0, 0}; a[(n++, 0)] += 3; return n*10 + a[0]; }
