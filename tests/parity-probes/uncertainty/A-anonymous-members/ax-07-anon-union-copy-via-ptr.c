struct S { union { int *ip; void *vp; }; }; static void set(struct S *p, void *q){ p->vp = q; } int main(void){ struct S s; int x = 9; set(&s, &x); return s.ip ? *s.ip : 0; }
