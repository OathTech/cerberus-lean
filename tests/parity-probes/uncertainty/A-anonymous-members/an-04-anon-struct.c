struct T { int a; struct { int b; int c; }; };
int main(void){ struct T t = {1, 2, 3}; return t.a + t.b*10 + t.c*100; }
