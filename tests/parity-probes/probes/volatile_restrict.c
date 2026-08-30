int copy(int * restrict d, const int * restrict s, int n) {
  for (int i = 0; i < n; i++) d[i] = s[i];
  return d[n-1];
}
int main(void) {
  volatile int v = 5;
  v = v + 1;
  int src[3] = {1,2,3}, dst[3];
  return copy(dst, src, 3) + v;  /* 3 + 6 = 9 */
}
