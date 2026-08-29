/* P21 union_pick — unions, non-punning discipline. EXPLORATORY-2 (uri.c has
 * none — census §9; kernel code uses them moderately; RefinedC's
 * simple_union.c/tagged_union machinery is the donor shape, BSD — text
 * fresh). Families (review precision): the UNION MEMBER vocabulary —
 * memberof/member_shift at union type + union-typed create/store/kill
 * (Core-verified; the whole-union `store(…, Unspecified)` init touches
 * memRW at union type — slightly more than field views), NOT the PEunion
 * ctor. Per-path member discipline: each path READS the member it WROTE —
 * no effective-type/punning UB; punning rows stay deferred with the ptr-int
 * address-observability family.
 * Dishonest-pass note: the tag branch is the covered case-split; the union
 * content is unavoidable — both arms go through union-typed member access,
 * and the else-arm's value is the reinterpreted shifted member (no
 * union-free route to the spec value exists).
 * Theorem: forall tag x in int range: outcomes = { Specified (pickModel tag
 * x) }, no UB — pickModel: tag /= 0 -> x; tag = 0 -> (x mod 2^32) >> 1
 * (the unsigned reinterpretation halved, always < 2^31 so the int
 * conversion is in range - derivation inline).
 * BOUNDS: full range both. */
union uv { int i; unsigned int u; };
int pick(int tag, int x) {
  union uv v;
  int r;
  if (tag) { v.i = x; r = v.i; }
  else { v.u = (unsigned int)x; r = (int)(v.u >> 1); }
  return r;
}
/* oracle differential sample only — NOT the theorem (catechism §V:
 * model-validation ledger; the theorem quantifies, this main is one point). */
int main(void) { return (pick(1, -5) == -5 && pick(0, 6) == 3) ? 0 : 1; }
