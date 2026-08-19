// Arc-2 Phase-2 obligation (arc-2 charter S6, landed arc-4 S5): the
// mini_pipeline §10 repro class — a struct sizeof inside an array-size
// constant expression forces the desugar const-expr driver through the
// tag-definition lookup. LP64: sizeof(struct S) = 8, a is int[8],
// sizeof(a) = 32.
struct S {
    int x;
    int y;
};

int main(void)
{
    int a[sizeof(struct S)];
    return sizeof(a);
}
