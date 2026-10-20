struct T { int a; struct { int b; int c; }; };
static struct T t = {1, 2, 3};
int main(void){ return t.a + t.b*10 + t.c*100; }
