// sem:S9 probe (arc-14 re-mark, probe-first): the compatible type of an
// all-nonnegative enum. Upstream registers Unsigned Int_ for such enums
// (ocaml_implementation.ml:144-150, via the registered_enums registry);
// the Lean CerberusImpl.typeof_enum stub says Signed Int_ for EVERY
// enum. Observable: (x - 1) on the enum's compatible type — unsigned
// wraps to a huge positive (not < 0), signed gives -1 (< 0).
enum e { A = 0, B = 1, C = 7 };
int main(void) {
  enum e x = A;
  if (x - 1 < 0) return 1;   /* signed compatible type   */
  return 2;                  /* unsigned compatible type */
}
