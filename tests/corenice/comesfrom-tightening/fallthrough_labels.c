/* Ordinary label entry must work even when its incoming origin set is empty. */
int main(void) {
  unsigned value = 1u;
first:
  value = value + 2u;
second:
  return (int)(value - 3u);
}
