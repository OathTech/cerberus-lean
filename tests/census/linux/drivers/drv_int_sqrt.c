/* Census driver (lib/math/int_sqrt.c). */
unsigned long int_sqrt(unsigned long x);
int main(void)
{
	if (int_sqrt(0) != 0) return 1;
	if (int_sqrt(1) != 1) return 2;
	if (int_sqrt(99) != 9) return 3;
	if (int_sqrt(1000000) != 1000) return 4;
	if (int_sqrt(~0UL) != 0xFFFFFFFFUL) return 5;
	return 0;
}
