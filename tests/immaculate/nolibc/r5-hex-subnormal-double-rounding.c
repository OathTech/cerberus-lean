/* ISO-fix register R5 (VALIDATION.md §2, [USER 2026-09-15]): ORACLE-WRONG pin — the OCaml
   runtime's caml_float_of_hex (runtime/floats.c:355,369) rounds a >53-bit hexadecimal
   mantissa twice when the result is subnormal; C11 §6.4.4.2#3 requires hexadecimal
   floating constants to be correctly rounded (FLT_RADIX = 2). Exact value
   2^-1023 + 0.746 subnormal quanta; correct rounding gives 2^-1023 + 2^-1074 =
   0x1.0000000000002p-1023 (Lean, gcc, Python float.fromhex: 1); the oracle gives
   0x1p-1023 (0). Recorded DIFF in tests/immaculate/baseline.txt; flips to MATCH and
   retires R5 when the OCaml runtime is fixed (upstream-tray ocaml/01, Cerberus-facing 40).
   Record: lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md §D1/§D1b. */
int main(void) { return 0x8000000000000BFp-1082 == 0x1.0000000000002p-1023; }
