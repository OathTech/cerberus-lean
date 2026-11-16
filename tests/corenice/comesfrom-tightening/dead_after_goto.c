/* The second goto remains syntactically present but cannot execute. */
int main(void) {
  goto done;
  goto unused;
unused:
  return 47;
done:
  return 0;
}
