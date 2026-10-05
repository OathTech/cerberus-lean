/* Census driver (lib/math/gcd.c). Returns 0 when every check holds, else the
 * number of the first failed check. Prototype restated from include/linux/gcd.h. */
unsigned long gcd(unsigned long a, unsigned long b);
int main(void)
{
	if (gcd(48, 18) != 6) return 1;
	if (gcd(0, 5) != 5) return 2;
	if (gcd(17, 5) != 1) return 3;
	if (gcd(1UL << 40, 1UL << 12) != 1UL << 12) return 4;
	return 0;
}
