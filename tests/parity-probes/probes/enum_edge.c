enum E { A = -1, B = 2147483647, C = 5 };
int main(void) {
  enum E e = B;
  return (e == 2147483647) + (A == -1) + (C == 5);  /* 3 */
}
