struct S { int a[2]; }; static struct S f(void){ struct S s = {{3,4}}; return s; } int main(void){ return f().a[1]; }
