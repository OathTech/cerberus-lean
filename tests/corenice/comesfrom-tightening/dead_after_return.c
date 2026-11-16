/* A return is lowered through a continuation jump; its suffix is dead. */
int main(void) {
  return 0;
  goto unused;
unused:
  return 47;
}
