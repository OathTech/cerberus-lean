/* cn_coverage driver: deps/cn/tests/cn/mutual_rec/mutual_rec2.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Node types from the corpus header mutual_rec.h (include-by-reference).
 * Input: the two-node A-tree a{k:1,v:2} -> left b{null,null} (well-formed
 * A_Tree, k < INT_MAX per the inc_a_tree body guard). inc_a_tree increments
 * every A-key and returns 1 on success. Verdict: a.k + r = 2 + 1 = 3. */
#include "mutual_rec.h"

extern int inc_a_tree(struct a_node *p);

int main(void)
{
    struct b_node bl = {0, 0};
    struct a_node a = {1, 2, &bl, 0};
    int r = inc_a_tree(&a);
    return a.k + r;
}
