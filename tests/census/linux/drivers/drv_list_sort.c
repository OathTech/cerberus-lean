/* Census driver (lib/list_sort.c): merge sort of a 6-element list_head list.
 * struct list_head restated from include/linux/types.h. */
struct list_head { struct list_head *next, *prev; };
void list_sort(void *priv, struct list_head *head,
	       int (*cmp)(void *, const struct list_head *, const struct list_head *));
struct item { int v; struct list_head node; };
static long node_off; /* offsetof(struct item, node), computed without a null-pointer member access */
#define ITEM(n) ((const struct item *)((const char *)(n) - node_off))
static int cmp(void *priv, const struct list_head *a, const struct list_head *b)
{
	return ITEM(a)->v > ITEM(b)->v;
}
static void add_tail(struct list_head *n, struct list_head *h)
{
	n->prev = h->prev; n->next = h; h->prev->next = n; h->prev = n;
}
int main(void)
{
	struct item it[6] = { {4}, {1}, {5}, {1}, {9}, {2} };
	struct list_head head = { &head, &head };
	struct list_head *p;
	int i, last = -1, n = 0;
	node_off = (char *)&it[0].node - (char *)&it[0];
	for (i = 0; i < 6; i++)
		add_tail(&it[i].node, &head);
	list_sort(0, &head, cmp);
	for (p = head.next; p != &head; p = p->next) {
		if (ITEM(p)->v < last) return 1;
		if (p->next->prev != p) return 2;
		last = ITEM(p)->v; n++;
	}
	if (n != 6) return 3;
	if (it[1].node.next != &it[3].node) return 4; /* stability: equal keys keep order */
	return 0;
}
