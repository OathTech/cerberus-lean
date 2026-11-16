/* The target's collected continuation must retain the surrounding suffix. */
int main(void) {
  unsigned value = 0u;
  goto entry;
  return 47;
entry:
  value = 1u;
  value = value + 2u;
  goto done;
  return 48;
done:
  return (int)(value - 3u);
}
