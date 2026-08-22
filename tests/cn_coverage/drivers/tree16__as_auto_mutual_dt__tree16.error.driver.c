/* cn_coverage driver: deps/cn/tests/cn/tree16/as_auto_mutual_dt/tree16.error.c
 * Corpus file license: BSD-2-Clause (deps/cn/LICENSE); fresh authorship for
 * the cerberus-lean CN-coverage lane (see ../README.md).
 * struct node re-declared as a compatible type (the corpus defines it in the
 * .c file; 16 = the corpus NUM_NODES). Input: root{v:1} with child{v:7} at
 * slot 3 and the one-step path [3] (indices in [0,16), path_len 1 <= LEN_LIMIT,
 * per the lookup_rec requires). lookup_rec finds the child and writes 7.
 * Verdict: 16 + 10*r + out = 33. */
struct node;

typedef struct node *tree;

struct node {
  int v;
  tree nodes[16];
};

extern int lookup_rec(tree t, int *path, int i, int path_len, int *v);
extern int cn_get_num_nodes(void);
int main(void)
{
    struct node child = {7, {0}};
    struct node root = {1, {0}};
    int path[1] = {3};
    int out = 0;
    int r;
    root.nodes[3] = &child;
    r = lookup_rec(&root, path, 0, 1, &out);
    return cn_get_num_nodes() + 10 * r + out;
}
