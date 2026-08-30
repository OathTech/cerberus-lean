#define TYPE_ID(x) _Generic((x), int: 1, double: 2, char*: 3, default: 0)
int main(void) {
  int i = 0; double d = 0; char *s = 0;
  return TYPE_ID(i) + 10*TYPE_ID(d) + 100*TYPE_ID(s);  /* 321 */
}
