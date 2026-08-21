struct S { int f0; int f3; };
static struct S g_arr[2][2] = {{{1,2},{3,4}},{{5,6},{7,8}}};
static struct S *g_p = &g_arr[1][0];
static int *g_q = &g_arr[1][0].f3;
int main(void) { return g_p->f0 + *g_q; }
