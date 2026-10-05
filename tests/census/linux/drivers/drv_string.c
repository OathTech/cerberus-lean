/* Census driver (lib/string.c). */
typedef unsigned long size_t;
size_t strlen(const char *s);
int strcmp(const char *a, const char *b);
int strncmp(const char *a, const char *b, size_t n);
char *strcpy(char *d, const char *s);
char *strchr(const char *s, int c);
char *strrchr(const char *s, int c);
char *strstr(const char *a, const char *b);
size_t strspn(const char *s, const char *accept);
int strcasecmp(const char *a, const char *b);
void *memchr(const void *s, int c, size_t n);
int main(void)
{
	char buf[16];
	const char *s = "hello, world";
	if (strlen(s) != 12) return 1;
	if (strcmp(s, "hello") <= 0 || strcmp("abc", "abd") >= 0 || strcmp(s, s)) return 2;
	if (strncmp(s, "help", 3) || !strncmp(s, "help", 4)) return 3;
	if (strcpy(buf, s) != buf || strcmp(buf, s)) return 4;
	if (strchr(s, 'o') != s + 4 || strrchr(s, 'o') != s + 8 || strchr(s, 'z')) return 5;
	if (strstr(s, "wor") != s + 7 || strstr(s, "xyz")) return 6;
	if (strspn(s, "hel") != 4) return 7;
	if (strcasecmp("HeLLo", "hello")) return 8;
	if (memchr(s, ',', 12) != s + 5) return 9;
	return 0;
}
