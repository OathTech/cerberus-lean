struct A { char c[16]; }; int main(void){ struct A v4 = { "foo" }; return v4.c[1]; }
