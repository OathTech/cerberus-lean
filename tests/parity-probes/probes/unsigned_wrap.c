int main(void) {
  unsigned u = 0u - 1u;          /* wraps: UINT_MAX */
  unsigned v = 4294967295u + 1u; /* wraps: 0 */
  return (u == 4294967295u) + (v == 0u);  /* 2 */
}
