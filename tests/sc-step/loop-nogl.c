/* SC S1a row E fixture (charter §3.10): a deterministic infinite loop, no globals.
   sc-step: startup-transitions=1
   sc-step: startup-complete-at=1
   The one lifecycle transition runs drive's startup (thread 0, argc/argv objects,
   errno) up to the boundary node that enters main's body; every later transition is
   one Core reduction of the loop, which touches no memory. Expected on Lean at
   budgets 1, 2, 7, 4096: SCExhausted with core_reductions = budget - 1 and the same
   SCMemory line from budget 1 on. `drive` at the lane's fuel ends in the fuel kill. */
int main(void) {
  while (1) {}
  return 0;
}
