/* Census driver (lib/kstrtox.c). */
int kstrtoull(const char *s, unsigned int base, unsigned long long *res);
int kstrtoint(const char *s, unsigned int base, int *res);
int main(void)
{
	unsigned long long u;
	int i;
	if (kstrtoull("12345", 10, &u) || u != 12345) return 1;
	if (kstrtoull("0x1F", 0, &u) || u != 31) return 2;
	if (kstrtoull("017\n", 0, &u) || u != 15) return 3;
	if (kstrtoint("-42", 10, &i) || i != -42) return 4;
	if (kstrtoull("12a", 10, &u) != -22) return 5;          /* -EINVAL */
	if (kstrtoull("18446744073709551616", 10, &u) != -34) return 6; /* -ERANGE */
	return 0;
}
