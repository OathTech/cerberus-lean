/* P09 call_contract — a helper whose SPEC MUST BE USED, plus frame across the
 * call. Families: call/return with contract (F5), frame (F9), pointer deref
 * (F7). Fresh-written.
 * BOUNDS (anti-brute-force ruling + review H4, derived inline): hazards are
 * v+1 at each bump AND the final x+y (which can UNDERFLOW at negative a,b —
 * the review's H4 lower-bound hole, closed here). Pre: 0 <= a, 0 <= b,
 * a + b <= INT_MAX - 2 (mathematical-integer bound; ~2^61 valid pairs,
 * non-enumerable; every intermediate then in range).
 * bump's contract: {p |-> v, 0 <= v <= INT_MAX-1} bump(p) {p |-> v+1}; the
 * caller consumes it TWICE with the sibling cell framed.
 * NOTE (operator-settled, Q3): inlining bump's body is NOT a legitimate
 * technique for this theorem — the program exists to force contract
 * consumption; the recursive rung (P10) is the structural backstop (its
 * data-dependent call depth cannot be inlined away). No mechanical gate,
 * per the operator's no-gate-grind ruling.
 * Theorem: forall a b in the derived range: result = (a+1)+(b+1). */
void bump(int *p) { *p = *p + 1; }
int harness(int a, int b) {
  int x = a, y = b;
  bump(&x);          /* frame: y untouched */
  bump(&y);          /* frame: x untouched */
  return x + y;
}
int main(void) { return harness(20, 21) == 43 ? 0 : 1; }
