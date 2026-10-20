struct T { int a; struct { int b; int c; }; int d; };
int main(void){ struct T t = {1, {2, 3}, 4}; return t.a + t.b*10 + t.c*100 + t.d; }
