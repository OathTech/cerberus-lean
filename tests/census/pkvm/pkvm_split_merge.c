/* Census driver: split and merge. One order-0 allocation splits the order-2
 * block (free lists afterwards: order 0 and order 1 non-empty, order 2
 * empty); hyp_get_page/hyp_put_page move the refcount without freeing; the
 * final put frees and merges back (order 2 non-empty, orders 0/1 empty).
 * Returns a bitmask of the free-list states plus refcounts. */
#include "pkvm_driver.h"
static int lists(struct hyp_pool *pool)
{
	return !list_empty(&pool->free_area[0])
	     | !list_empty(&pool->free_area[1]) << 1
	     | !list_empty(&pool->free_area[2]) << 2;
}
int main(void)
{
	struct hyp_pool pool;
	void *a;
	int r, before, after_split, rc_got, rc_put, after_merge;
	census_setup();
	census_pool_init(&pool, 0, CENSUS_NPAGES, 0, 3);
	before = lists(&pool);
	a = hyp_alloc_pages(&pool, 0);
	after_split = lists(&pool);
	hyp_get_page(&pool, a);
	rc_got = hyp_page_count(&pool, a);
	hyp_put_page(&pool, a);
	rc_put = hyp_page_count(&pool, a);
	hyp_put_page(&pool, a);
	after_merge = lists(&pool);
	r = before | after_split << 3 | rc_got << 6 | rc_put << 8 | after_merge << 10;
	return r;
}
