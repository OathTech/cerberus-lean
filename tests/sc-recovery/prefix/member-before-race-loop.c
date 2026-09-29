/* Recovery regression: ordinary private member reads must not disable later
   detection of a race on an unrelated scalar. Both stores finish before loop. */
struct pair { int a; int b; };
int main(void) {
  struct pair p = {19, 23};
  int sum = p.a + p.b;
  int x = 0;
  {-{ { x = 1; } ||| { x = 2; } }-};
  while (1) {}
  return sum + x;
}
