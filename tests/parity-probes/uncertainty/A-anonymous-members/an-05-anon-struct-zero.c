struct T { int a; struct { int b; int c; }; };
int main(void){ struct T t = {1}; return t.a + t.b + t.c; }
