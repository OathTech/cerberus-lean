/* Corner: pointer -> unsigned long -> (+ 4ul) -> pointer round trip within
   one array object: defined under ISO C11 6.3.2.3p5 (impl-defined, the
   Cerberus/x86-64 impl documents the identity mapping) and under the PVI
   provenance model (provenance carried through integer arithmetic).
   gcc returns 20. */
int main(void) {
  int a[2] = {10, 20};
  unsigned long u = (unsigned long)&a[0];
  int *q = (int*)(u + 4ul);
  return *q;
}
