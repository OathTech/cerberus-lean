int left_value;
int right_value;
int left(void) {
  int n = 0;
again:
  n++;
  if (n < 2) goto again;
  left_value = n;
  return n;
}
int right(void) {
  int n = 0;
  goto increment;
increment:
  n++;
  if (n < 3) goto increment;
  right_value = n;
  return n;
}
int main(void) {
  int sum = left() + right();
  return sum == 5 && left_value == 2 && right_value == 3 ? 0 : 1;
}
