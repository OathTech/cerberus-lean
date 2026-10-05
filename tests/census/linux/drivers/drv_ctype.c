/* Census driver (lib/ctype.c: the _ctype table). Bit names restated from
 * include/linux/ctype.h. */
#define _U 0x01
#define _L 0x02
#define _D 0x04
#define _C 0x08
#define _P 0x10
#define _S 0x20
#define _X 0x40
#define _SP 0x80
extern const unsigned char _ctype[];
int main(void)
{
	if (_ctype['A'] != (_U | _X)) return 1;
	if (_ctype['z'] != _L) return 2;
	if (_ctype['7'] != _D) return 3;
	if (_ctype[' '] != (_S | _SP)) return 4;
	if (_ctype['\n'] != (_C | _S)) return 5;
	if (_ctype['!'] != _P) return 6;
	return 0;
}
