/* Selected SC integration probe: UB005, both writes target the same element. */
int main(void) {
  int values[2];
  {-{ { values[1] = 19; }
  ||| { values[1] = 23; } }-};
  return 0;
}
