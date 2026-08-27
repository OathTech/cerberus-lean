/* R6 CENSUS c4 (arc-18 breadth campaign): hex-digit value — the
   three-way range ladder of deps/libxml2/uri.c:1559 is_hex /
   1601-1613 hex-decode arms (census rows O3 + §2).
   Theorem shape: forall seed, outcomes(hex_val(102)) =
   {Specified(15)}, no UB. */
int hex_val(int c)
{
  if (c >= '0' && c <= '9') {
    return c - '0';
  }
  if (c >= 'a' && c <= 'f') {
    return c - 'a' + 10;
  }
  if (c >= 'A' && c <= 'F') {
    return c - 'A' + 10;
  }
  return -1;
}

int main(void) { return hex_val(102); }
