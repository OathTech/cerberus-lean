/* NEW VARIANT of upstream-tray item 08 (nested-braced-init invalid
   node): 2-D *struct* arrays crash where the tray's 2-D scalar
   control works. BOTH engines die with the identical message
   "Translation called on Ail program with an invalid node" (oracle
   failwith = Lean LemLib panic) — message-level parity even in the
   defect. Dominant cause of the ~57% oracle skip rate on fresh
   csmith seeds (parity-detective report §5). */
struct S { unsigned f0; signed char f1; };
static struct S g[1][1] = {{{1,2}}};
int main(void) { return g[0][0].f0; }
