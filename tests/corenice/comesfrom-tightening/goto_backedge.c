/* A reachable jump cycle needs a fixed point, not one traversal. */
int main(void) {
  unsigned count = 0u;
  goto body;
  return 47;
body:
  count = count + 1u;
  if (count < 4u) goto body;
  goto done;
  return 48;
done:
  return (int)(count - 4u);
}
