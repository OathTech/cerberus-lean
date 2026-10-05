/* Census driver (lib/math/lcm.c, linked with lib/math/gcd.c). */
unsigned long lcm(unsigned long a, unsigned long b);
unsigned long lcm_not_zero(unsigned long a, unsigned long b);
int main(void)
{
	if (lcm(4, 6) != 12) return 1;
	if (lcm(0, 6) != 0) return 2;
	if (lcm_not_zero(0, 7) != 7) return 3;
	if (lcm(21, 6) != 42) return 4;
	return 0;
}
