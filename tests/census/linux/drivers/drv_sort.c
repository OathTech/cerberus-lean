/* Census driver (lib/sort.c): heapsort of ints, default swap. */
typedef unsigned long size_t;
void sort(void *base, size_t num, size_t size,
	  int (*cmp)(const void *, const void *),
	  void (*swap)(void *, void *, int));
static int cmp_int(const void *a, const void *b)
{
	int x = *(const int *)a, y = *(const int *)b;
	return x < y ? -1 : x > y;
}
int main(void)
{
	int v[8] = { 5, -1, 9, 3, 3, 0, 42, -7 };
	int i;
	sort(v, 8, sizeof(int), cmp_int, 0);
	for (i = 1; i < 8; i++)
		if (v[i - 1] > v[i]) return i;
	if (v[0] != -7 || v[7] != 42) return 9;
	return 0;
}
