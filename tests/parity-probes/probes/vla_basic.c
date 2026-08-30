int main(void) {
  int n = 5;
  int a[n];
  for (int i = 0; i < n; i++) a[i] = i*i;
  return a[4] + (int)sizeof(a)/(int)sizeof(int);  /* 16 + 5 = 21 */
}
