int descend(int n) {
  int result;
  if (n == 0) goto base;
  result = descend(n - 1);
  goto finish;
base:
  result = 0;
finish:
  return result + 1;
}
int main(void) {
  int result = descend(4);
  return result == 5 ? 0 : 1;
}
