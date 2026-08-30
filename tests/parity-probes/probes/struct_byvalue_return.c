struct Big { int a[7]; };
struct Big mk(void) {
  struct Big b;
  for (int i = 0; i < 7; i++) b.a[i] = i;
  return b;
}
int main(void) {
  struct Big b = mk();
  return b.a[6] * 7;  /* 42 */
}
