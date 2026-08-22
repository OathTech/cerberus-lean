/* cn_coverage driver: deps/cn/tests/cn/mutual_rec/mutual_rec1.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * Node types come from the corpus header mutual_rec.h (include-by-reference,
 * resolved via -I to the corpus directory). Input: the two-node A-tree
 * a{v:5} -> left b{null,null} (a well-formed A_Tree per the predicate).
 * Verdict: 5 (walk_a_tree sums node values into global_val). */
#include "mutual_rec.h"

extern unsigned int global_val;
extern void walk_a_tree(struct a_node *p);

int main(void)
{
    struct b_node bl = {0, 0};
    struct a_node a = {1, 5, &bl, 0};
    walk_a_tree(&a);
    return (int) global_val;
}
