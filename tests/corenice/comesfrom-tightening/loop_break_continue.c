/* Loop, continue and break targets all remain live through dead suffixes. */
int main(void) {
  unsigned count = 0u;
  unsigned total = 0u;
  while (count < 5u) {
    count = count + 1u;
    if (count == 2u) {
      continue;
      goto unused;
    }
    if (count == 4u) {
      break;
      goto unused;
    }
    total = total + count;
  }
  return (int)(total - 4u);
unused:
  return 47;
}
