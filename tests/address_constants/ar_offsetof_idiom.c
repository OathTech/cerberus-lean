struct S { char c; int x; }; static int off = (int)(unsigned long)&((struct S *)0)->x - 1; int main(void) { return off; }
