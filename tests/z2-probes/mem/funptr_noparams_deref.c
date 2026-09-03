/* Z2 probe (isWellAligned_ptrval): impl_mem.ml:2067-2069 matches `Void |
   Function _` only, so a FunctionNoParams ref type falls to the concrete arm
   and calls alignof, which `assert false`s (:216-218) — an oracle crash;
   CerbMem.isWellAlignedPtrval has an explicit FunctionNoParams arm failing
   MerrOther (charter Z-21). Reachable only if a PtrWellAligned/ValidForDeref
   memop is emitted with a K&R function ref type. nolibc. */
int f();
int f() { return 7; }
int main(void) { int (*fp)() = f; return (*fp)(); }
