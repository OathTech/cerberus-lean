static int n; static int a[2]; static int *g(void){ n++; return &a[0]; }
int main(void){ *g() += 3; return n*10 + a[0]; }
