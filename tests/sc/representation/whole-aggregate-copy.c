/* Whole aggregate initialization and assignment retain their complete values.
   Partial/member composition is exercised by separate probes. */
struct pair { int x, y; };
char greeting[] = "hi";
int main(void) {
  struct pair source = {19, 23};
  struct pair destination = source;
  destination = source;
  return 0;
}
