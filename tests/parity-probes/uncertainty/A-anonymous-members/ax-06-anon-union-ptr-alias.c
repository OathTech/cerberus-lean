struct S { union { int *ip; void *vp; }; }; int main(void){ struct S s; int x = 7; s.ip = &x; return s.vp == &x; }
