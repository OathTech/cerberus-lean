/* zero-discrepancy Z2 fixture (2026-09-03; audit row Z2-C-01 / charter Z-60, tests/z2-probes/call/bool_param.c;
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). `--call f --call-args 2` on a _Bool parameter: the
   elaborated call site converts the argument with conv_loaded_int (translation.lem:948-953 → std.core conv_int:
   `_Bool` → 0 if the value compares equal to 0, else 1), so the oracle's wrapper answers Specified(1); the
   pre-Z2 CerbCall stored the raw 2 and the _Bool load trapped UB012. Rows exercise 0, 1, 2 and a negative. */
int f(_Bool b) { return b; }
int main(void) { return f(1); }
