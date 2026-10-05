/* Census driver: allocate until exhaustion from a 4-page pool (max_order 3,
 * one order-2 block after init). Returns the page indices packed in hex
 * digits: order-0, order-1, order-0, then a further order-0 (expected NULL=15). */
#include "pkvm_driver.h"
int main(void)
{
	struct hyp_pool pool;
	void *a, *b, *c, *d;
	census_setup();
	census_pool_init(&pool, 0, CENSUS_NPAGES, 0, 3);
	a = hyp_alloc_pages(&pool, 0);
	b = hyp_alloc_pages(&pool, 1);
	c = hyp_alloc_pages(&pool, 0);
	d = hyp_alloc_pages(&pool, 0);
	return census_idx(a) | census_idx(b) << 4 | census_idx(c) << 8 | census_idx(d) << 12;
}
