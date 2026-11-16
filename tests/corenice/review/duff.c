int main(void) {
  int n = 7, x = 0;
  switch (n % 4) {
    case 0: do { x++;
    case 3: x++;
    case 2: x++;
    case 1: x++;
    } while ((n -= 4) > 0);
  }
  return x != 7;
}
