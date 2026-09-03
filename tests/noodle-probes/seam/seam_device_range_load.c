/* Corner (seam): an integer in the concrete model's hard-coded device range
   (impl_mem.ml:620-624: [0x40000000,0x40000004] and [0xABC,0xAC0]) casts to a
   Prov_device pointer whose loads succeed (impl_mem.ml:2164-2167, 1611-1617).
   Lean drops the device arm (CerbMem.lean:2275-2283; its comment claims the
   list is empty). oracle: Specified(3)   Lean: UB043. */
int main(void) { int x = 5; int *p = (int*)0xABC; int y = *p; (void)y; return 3; }
