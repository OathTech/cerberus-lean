/* Census driver (lib/hexdump.c): hex_to_bin, hex2bin, bin2hex (the
 * printk/snprintf-backed dump functions are not called). */
typedef unsigned long size_t;
int hex_to_bin(unsigned char ch);
int hex2bin(unsigned char *dst, const char *src, size_t count);
char *bin2hex(char *dst, const void *src, size_t count);
int main(void)
{
	unsigned char b[3];
	char h[7];
	const unsigned char in[3] = { 0x0a, 0xff, 0x10 };
	if (hex_to_bin('a') != 10 || hex_to_bin('F') != 15 || hex_to_bin('7') != 7) return 1;
	if (hex_to_bin('g') != -1) return 2;
	if (hex2bin(b, "0aff10", 3) != 0 || b[0] != 0x0a || b[1] != 0xff || b[2] != 0x10) return 3;
	if (hex2bin(b, "0z", 1) != -22) return 4;               /* -EINVAL */
	if (bin2hex(h, in, 3) != h + 6) return 5;
	h[6] = 0;
	if (h[0] != '0' || h[1] != 'a' || h[2] != 'f' || h[5] != '0') return 6;
	return 0;
}
