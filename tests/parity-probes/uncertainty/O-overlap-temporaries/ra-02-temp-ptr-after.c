struct S { int a[2]; }; static struct S f(void){ struct S s = {{3,4}}; return s; } int main(void){ int *p = f().a; return p[0]; }
