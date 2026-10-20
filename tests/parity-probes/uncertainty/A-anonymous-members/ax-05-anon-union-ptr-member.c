struct S { union { int *ip; char *cp; }; }; int main(void){ struct S s; int x = 7; s.ip = &x; return *s.ip + (int)sizeof(struct S); }
