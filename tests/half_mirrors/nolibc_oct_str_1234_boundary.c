/* control: an octal escape takes at most three digits ("\1234" = 'S' then '4'). gcc 13 and every engine: Specified(167). Unmoved. */
int main(void) { const char *s = "\1234"; return s[0] * 2 + (s[1] == '4'); }
