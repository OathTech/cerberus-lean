/* C11 6.2.5p20: distinct scalar array elements are distinct objects.
   Selected SC integration probe: expected result 42, empty output, unblocked.
   This is not a claim to enumerate every Core/scheduler execution. */
int main(void) {
  int values[2][3];
  {-{ { values[0][1] = 19; }
  ||| { values[1][2] = 23; } }-};
  return values[0][1] + values[1][2];
}
