/* Census driver: allocate every page singly, free them all, then the whole
 * pool must be available again as one order-2 block (coalescing on free).
 * Returns 0 on success, else the number of the first failed check. */
#include "pkvm_driver.h"
int main(void)
{
	struct hyp_pool pool;
	void *p[CENSUS_NPAGES];
	void *big;
	int i;
	census_setup();
	census_pool_init(&pool, 0, CENSUS_NPAGES, 0, 3);
	for (i = 0; i < CENSUS_NPAGES; i++)
		if (!(p[i] = hyp_alloc_pages(&pool, 0)))
			return 1;
	if (hyp_alloc_pages(&pool, 0))
		return 2;
	for (i = 0; i < CENSUS_NPAGES; i++)
		hyp_put_page(&pool, p[i]);
	big = hyp_alloc_pages(&pool, 2);
	if (big != census_mem)
		return 3;
	if (hyp_page_count(&pool, big) != 1)
		return 4;
	return 0;
}
