int main(void) {
  int a[4] = {1,2,3,4};
  int *end = a + 4;         /* one past: OK */
  int s = 0;
  for (int *p = a; p != end; p++) s += *p;
  return s + (end - a);     /* 10 + 4 = 14 */
}
