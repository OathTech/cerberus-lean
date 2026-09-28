// ts-memcmp-struct-padding (2026-09-28 thin-surface tests): memcmp over a
// struct whose padding bytes were never written. The concrete model's memcmp
// asserts that every byte is an integer byte: the oracle fails its assertion
// (impl_mem.ml memcmp get_bytes) and Lean mirrors it as a model failure
// (CerbMem "Concrete.memcmp: non-integer byte"). Pinned as the both-crash
// pair (MATCH | L=CRASH).
#include <string.h>
struct s { char c; int i; };
int main(void) {
  struct s a, b;
  a.c = 1; a.i = 2; b.c = 1; b.i = 2;
  return memcmp(&a, &b, sizeof a) == 0;
}
