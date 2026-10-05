/* Census driver: hyp_pool_init as shipped (4 pages at pfn 0, none reserved).
 * Expected on a faithful semantics: UB — get_order() has an empty body and
 * hyp_pool_init uses its value. */
#include "pkvm_driver.h"
int main(void)
{
	struct hyp_pool pool;
	census_setup();
	return hyp_pool_init(&pool, 0, CENSUS_NPAGES, 0);
}
