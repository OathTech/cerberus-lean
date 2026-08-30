int main(void) {
  int x = 4;
  int s = -1;
  return x << s;  /* UB: negative shift */
}
