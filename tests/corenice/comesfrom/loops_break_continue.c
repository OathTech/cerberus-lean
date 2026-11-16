int main(void) {
  int total = 0;
  for (int i = 0; i < 6; i++) {
    if (i == 2) continue;
    if (i == 5) break;
    total += i;
  }
  int j = 0;
  while (j < 3) {
    j++;
    if (j == 2) continue;
    total += j;
  }
  do {
    total++;
    if (total == 13) break;
  } while (total < 20);
  return total == 13 ? 0 : 1;
}
