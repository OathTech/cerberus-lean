struct T { int a; struct { int b; int c; }; };
int main(void){ struct T t = {.c = 5}; return t.a*100 + t.b*10 + t.c; }
