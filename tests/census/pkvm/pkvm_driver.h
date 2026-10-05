/* Census P1f-2 (2026-10-04) pKVM buddy-allocator DRIVER support [AGENT].
 * Drivers only call the case study's existing functions on chosen inputs;
 * this header supplies what page_alloc.c leaves to its environment:
 *   - the header chain, in page_alloc.c's own order (page_alloc.c:9-28);
 *   - a definition of hyp_physvirt_offset (memory.h declares it extern;
 *     page_alloc.c never defines it);
 *   - the "physical memory" (CENSUS_NPAGES pages) and the vmemmap indexed by
 *     pfn, with phys(census_mem) = 0, so pfn i <-> census_mem + i*PAGE_SIZE;
 *   - the PROTOTYPE of census_pool_init. Its definition is NOT in this
 *     repository: page_alloc.c is GPL-2.0-only, so derive_pool_init.py
 *     derives it at run time from the case study's own hyp_pool_init
 *     (renamed, new last parameter max_order, get_order(...) -> max_order;
 *     the case study gives get_order an EMPTY body, a CN-frontend
 *     workaround, so hyp_pool_init uses the value of a non-void function
 *     that fell off its end: UB088). Driver pkvm_init.c calls hyp_pool_init
 *     itself to record that; the others call census_pool_init, which the
 *     census links from the derived TU (page_alloc_census.c, under the
 *     census output directory, never committed). [AGENT 2026-10-05,
 *     pre-merge audit M2] */
#include "posix_types.h"
#include "stddef.h"
#define bool _Bool
#define true 1
#include "const.h"
#define PAGE_SHIFT 12
#include "page-def.h"
#include "limits.h"
#include "mmzone.h"
#include "uapi-int-ll64.h"
#include "int-ll64.h"
#include "types.h"
#include "kernel.h"
#include "list.h"
#include "minmax.h"
#include "memory.h"
#include "gfp.h"

#define CENSUS_NPAGES 4

s64 hyp_physvirt_offset;
static unsigned char census_mem[CENSUS_NPAGES * PAGE_SIZE];
static struct hyp_page census_vmemmap[CENSUS_NPAGES];

static void census_setup(void)
{
	__hyp_vmemmap = census_vmemmap;
	cn_virt_base = census_mem;
	hyp_physvirt_offset = -(s64)(u64)census_mem;  /* phys(census_mem) = 0 */
}

/* defined in the run-time-derived TU (see above) */
int census_pool_init(struct hyp_pool *pool, u64 pfn, unsigned int nr_pages,
		     unsigned int reserved_pages, u8 max_order);

/* page index of an allocation, or 15 for NULL */
static int census_idx(void *p)
{
	if (!p)
		return 15;
	return (int)(((unsigned char *)p - census_mem) / PAGE_SIZE);
}
