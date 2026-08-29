/* P22 fnptr_apply — function pointers / indirect call. EXPLORATORY-2 (uri.c
 * has none — census §9; libxml2's SAX layer and kernel ops tables will force
 * it at those rungs; RefinedC binary_search's cmp-pointer is the donor
 * class, BSD — text fresh). Families: Cfunction VALUES through a store/load
 * roundtrip (an fn-ptr-typed CELL — new memRW content), the `cfunction()`
 * type-compatibility memop, and per-arm FnSpec selection composed with V4's
 * call rule. Depends on V4.
 * HONEST FRAMING (review C3): the intended proof IS
 * devirtualization-per-arm — after by_cases on sel, each arm's callee is a
 * concrete Cfunction value consuming its own contract; and in Core EVERY
 * call is already ccall-of-a-Cfunction-value, so the "indirect" rule
 * largely rides V4's direct form. What this row does NOT touch: a function
 * pointer arriving as a QUANTIFIED ARGUMENT carrying a contract assumption
 * (the RefinedC binary_search class) — unreachable in the scalar-harness
 * style (a fn-ptr cannot enter the call boundary) and ADDED to the recorded
 * deferral list with its trigger (libxml2 SAX layer / kernel ops tables).
 * Theorem: forall sel x, INT_MIN/2 <= x <= INT_MAX/2: outcomes =
 * { Specified (sel /= 0 ? x+1 : x+x) }, no UB.
 * BOUNDS (derived): |x| <= 2^30-ish covers both callees' arithmetic
 * (x+1 and x+x in range); sel full range. Domain ~2^63. */
static int inc1(int x) { return x + 1; }
static int dbl(int x) { return x + x; }
int apply(int sel, int x) {
  int (*f)(int) = sel ? inc1 : dbl;
  return f(x);
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (apply(1, 4) == 5 && apply(0, 4) == 8) ? 0 : 1; }
