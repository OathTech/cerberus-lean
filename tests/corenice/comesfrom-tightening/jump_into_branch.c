/* A reachable label has an unreachable enclosing ordinary branch entry. */
int main(void) {
  unsigned value = 0u;
  goto inner;
  if (value == 0u) {
    return 47;
inner:
    value = 3u;
    goto done;
  }
  return 48;
done:
  return (int)(value - 3u);
}
