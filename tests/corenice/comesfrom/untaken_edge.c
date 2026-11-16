int main(void) {
  int n = 0;
  if (0) goto done;
  goto entered;
entered:
  n = 7;
  goto done;
done:
  return n == 7 ? 0 : 1;
}
