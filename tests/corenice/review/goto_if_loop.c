int main(void) {
  int i = 0, x = 0;
  goto hidden;
  while (i < 3) {
    if (0) {
      hidden: x += 3;
    } else { x += 10; }
    i++;
    if (i == 2) continue;
    x++;
  }
  return x != 25;
}
