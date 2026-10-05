/* Census driver (lib/bsearch.c). */
typedef unsigned long size_t;
void *bsearch(const void *key, const void *base, size_t num, size_t size,
	      int (*cmp)(const void *key, const void *elt));
static int cmp_int(const void *k, const void *e)
{
	int a = *(const int *)k, b = *(const int *)e;
	return a < b ? -1 : a > b;
}
static const int tab[7] = { 2, 3, 5, 7, 11, 13, 17 };
int main(void)
{
	int k = 11, m = 4, lo = 2, hi = 17;
	if (bsearch(&k, tab, 7, sizeof(int), cmp_int) != &tab[4]) return 1;
	if (bsearch(&m, tab, 7, sizeof(int), cmp_int) != 0) return 2;
	if (bsearch(&lo, tab, 7, sizeof(int), cmp_int) != &tab[0]) return 3;
	if (bsearch(&hi, tab, 7, sizeof(int), cmp_int) != &tab[6]) return 4;
	return 0;
}
