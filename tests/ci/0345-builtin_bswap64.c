// __builtin_bswap64 must accept its full uint64_t domain (values >= 2^63 included)
int main(void)
{
  if (__builtin_bswap64(0x8000000000000001ull) != 0x0100000000000080ull) return 1;
  if (__builtin_bswap64(0xffffffffffffffffull) != 0xffffffffffffffffull) return 2;
  if (__builtin_bswap64(0x8877665544332211ull) != 0x1122334455667788ull) return 3;
  if (__builtin_bswap64(0x0102030405060708ull) != 0x0807060504030201ull) return 4;
  if (__builtin_bswap64(0ull) != 0ull)                                   return 5;
  return 0;
}
