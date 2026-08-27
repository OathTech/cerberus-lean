/* P15 scan_classify — NUL-TERMINATED unsigned-char scan + switch classifier
 * (review §6: closes strings/NUL-discipline, integer conversions/char
 * widening, and switch shape in ONE row). Fresh-written (uri.c idiom).
 * The loop bound is the NUL CONVENTION, not an index parameter: deref
 * safety comes from the wf precondition's EXISTS-NUL-within-bounds witness
 * — a genuinely different invariant discipline from P05.
 * BOUNDS (anti-brute-force ruling): NUL position < ARENA = 2^20; bytes
 * full unsigned-char range. Domain non-enumerable.
 * Theorem: forall s wf (exists k < ARENA, s[k] = 0): result = the model
 * count of digit-class bytes strictly before the first NUL. */
#define ARENA 1048576
static const unsigned char choices[] = {'a', '7', '.', '9', 0}; /* SPLICED */
static const int expected_cnt = 2;                              /* SPLICED */
static unsigned char buf[ARENA];
int scan_classify(const unsigned char *s) {
  int c = 0;
  for (int i = 0; s[i] != 0; i = i + 1) {
    switch (s[i]) {                 /* unsigned char widens to int here */
      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9': c = c + 1; break;
      default: break;
    }
  }
  return c;
}
int main(void) {
  int i = 0;
  do { buf[i] = choices[i]; } while (choices[i++] != 0);  /* set_up_memory */
  return scan_classify(buf) == expected_cnt ? 0 : 1;
}
