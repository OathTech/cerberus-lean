/* SC S1a row F control (charter §3.10 row F, §3.11 plant P4): a Cerberus par block.
   Both engines must classify the fork as unsupported:
   SCUnsupported {msg: "sc: fork (Step_spawn_threads2, Core par): S1b"}
   (S1a refuses BEFORE advance_step would spawn the children.) */
int main(void) {
  int x = 0;
  {-{ { x = 1; } ||| { x = 2; } }-};
  return x;
}
