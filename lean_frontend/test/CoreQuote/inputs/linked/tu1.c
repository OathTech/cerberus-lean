/* Core quotation linked input 1 (quotation hygiene Q6, 2026-10-26): an enum
   definition, a cross-TU extern object, a static object with an initializer
   and a loop, so that the libc-linked comparator positions for enumDefs,
   visible objects and loop attributes carry TU-side values. */
enum colour { RED = 1, GREEN = 2, BLUE = 4 };
extern int shared_counter;
static int local_init = 5;
int bump(int k);
int main(void) {
  int acc = local_init;
  for (int i = 0; i < 3; i++) {
    acc += bump(i);
  }
  return acc + shared_counter + GREEN;
}
