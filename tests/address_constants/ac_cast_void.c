struct I { int x; }; struct S { int a; int b; int arr[3]; struct I i; };
static int g = 3; static int ga[3] = {1, 2, 3}; static int g2[2][2] = {{1, 2}, {3, 4}};
static struct S gs = {1, 3, {1, 2, 3}, {3}};
static struct S gsa[2]; /* filled by main: a braced initializer of an array of structs with an array member is draft 08 (an invalid node at translation), another mechanism */
static int *gp = &g; static struct S *gsp = &gs; int f(void) { return 3; } enum { TWO = 2 };
static int *q = (void *)&g; int main(void) { gsa[1].a = 1; gsa[1].b = 3; gsa[1].arr[0] = 1; gsa[1].arr[1] = 2; gsa[1].arr[2] = 3; gsa[1].i.x = 3; return *q; }
