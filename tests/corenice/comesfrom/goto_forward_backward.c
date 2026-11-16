int main(void) {
  int n = 0;
  goto increment;
again:
  if (n == 4) goto done;
increment:
  n = n + 1;
  goto again;
done:
  return n == 4 ? 0 : 1;
}
