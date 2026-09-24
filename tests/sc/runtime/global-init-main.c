/* The whole-program entry must run initialization, main, and final reporting.
   Selected SC integration probe: result 42, empty output, unblocked. */
int global_value = 41;
int main(void) {
  ++global_value;
  return global_value;
}
