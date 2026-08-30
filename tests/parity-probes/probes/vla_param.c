int sum(int n, int a[n]) {
  int s = 0;
  for (int i = 0; i < n; i++) s += a[i];
  return s;
}
int main(void) {
  int a[4] = {1,2,3,4};
  return sum(4, a);  /* 10 */
}
