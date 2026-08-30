int main(void) {
  int count = 10, acc = 0;
  int n = (count + 3) / 4;
  switch (count % 4) {
  case 0: do { acc++;
  case 3:      acc++;
  case 2:      acc++;
  case 1:      acc++;
          } while (--n > 0);
  }
  return acc;  /* 10 */
}
