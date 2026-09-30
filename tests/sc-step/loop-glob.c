/* SC S1a row E fixture (charter §3.10): the deterministic loop with one initialised
   global.
   sc-step: startup-transitions=2
   sc-step: startup-complete-at=13
   Lifecycle transition 1 enters the global's initialiser body at a boundary; the
   initialiser's 11 Core reductions (transitions 2-12, the last the Step_done2 exit that
   runs prepare_exit and hands control back; the count is the Core shape of
   `int g = 41`: create, store, ... to the value — measured once on Lean at
   1864c6562+S1a and pinned here) end at transition 12; lifecycle transition 13 enters
   main's body. Expected at budget B: transitions = B; transitions - core_reductions = 1
   for B < 13 and = 2 (startup-transitions) for B >= 13; the SCMemory line is the same
   for every B >= 13 (errno allocated, the loop touches no memory) and differs from
   B < 13 (g's object, then errno, are created during the startup). */
int g = 41;
int main(void) {
  while (1) {}
  return g;
}
