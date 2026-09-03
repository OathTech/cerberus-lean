/* Z2 probe (CerbCall.lean:182-184 allocates errno inside callFinish, AFTER
   injectArgs; driver.lem `drive` allocates errno BEFORE main's argument
   temporaries). Observable through the parameter object's address.
   Lean: --call f --call-args 1; oracle: errno_order_wrapper.c. */
int f(int x) { return (int)((long)&x & 0xffff); }
