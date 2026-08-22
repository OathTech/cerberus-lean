/* cn_coverage driver: deps/cn/tests/cn/mutual_rec/mutual_rec3.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Node types from the corpus header mutual_rec.h (include-by-reference).
 * Input: the shape predef_a_tree coerces (p non-null, p->left non-null with
 * empty children, p->right null, per its body/ensures). It rewrites k:=1,
 * v:=0 and returns p. Verdict: (r == &a) + a.k = 1 + 1 = 2. */
#include "mutual_rec.h"

extern struct a_node *predef_a_tree(struct a_node *p);

int main(void)
{
    struct b_node bl = {0, 0};
    struct a_node a = {5, 7, &bl, 0};
    struct a_node *r = predef_a_tree(&a);
    return (r == &a) + a.k;
}
