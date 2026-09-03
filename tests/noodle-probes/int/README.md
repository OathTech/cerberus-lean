# int/ — integer semantics probes (nolibc mode)

All 16 accepted probes AGREE oracle==Lean; where gcc is comparable it
agrees too (`results.log`). Integration target for AGREE rows:
`tests/minimal`-style exec lane (`test_exec.sh`, expected MATCH) and the
gcc second-oracle corpus (expected AGREE; probes printing stdout are
SKIP_GCC_STDOUT there — return-value-only probes are the gcc-lane
shape). Gate-worthy: all deterministic, oracle-accepted, UB-free or with
agreed UB code.

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| int_mixed_sign_cmp.c | usual arithmetic conversions, mixed signedness at every rank (6.3.1.8) | AGREE 3-way | exec MATCH, gate-worthy |
| int_conv_outofrange.c | impl-defined out-of-range conversion to signed (6.3.1.3p3) | AGREE 3-way | exec MATCH |
| int_shift_defined.c | defined/impl-defined shifts: negative >>, promotion before <<, long long (6.5.7) | AGREE 3-way | exec MATCH |
| int_divmod_negative.c | truncation toward zero, remainder sign, all ranks (6.5.5p6) | AGREE 3-way | exec MATCH |
| int_unary_minus_unsigned.c | unary -/~ on unsigned and promoted narrow unsigned (6.5.3.3) | AGREE 3-way | exec MATCH |
| int_bool_from_int_ptr.c | _Bool from 256/65536/2^32/pointers, ++/-- on _Bool (6.3.1.2) | AGREE 3-way | exec MATCH |
| int_char_signedness.c | plain char signed; hex escapes; comparisons (6.2.5p15) | AGREE 3-way | exec MATCH |
| int_constant_types.c | integer-constant typing via sizeof/signedness (6.4.4.1p5) | AGREE 3-way | exec MATCH |
| int_narrow_compound_assign.c | compound assign/++ on narrow types wraps, no UB (6.5.16.2) | AGREE 3-way | exec MATCH |
| int_llong_boundaries.c | ULLONG wrap, 0x8000000000000000 is unsigned long (6.4.4.1p5) | AGREE 3-way | exec MATCH |
| int_cond_operator_types.c | ?: result type under UAC (6.5.15p5) | AGREE oracle==Lean; gcc differs ONLY on `sizeof(t?1.0f:1)` (8 vs 4) = float/README ORACLE-SUSPECT F1 | exec MATCH; gcc-lane would need the float column dropped |
| int_ub_codes_overflow.c | UB036 for -INT_MIN (6.5p5) | AGREE UB036 | exec UB_MATCH |
| int_ub_codes_mul.c | UB036 for promoted unsigned short product (6.5p5) | AGREE UB036 | exec UB_MATCH |
| int_shift_ub_codes.c | UB052a negative left operand of << (6.5.7p4) | AGREE UB052a | exec UB_MATCH |
| int_shift_right_toolarge.c | UB51b >> by width (6.5.7p3) | AGREE UB51b | exec UB_MATCH |
| int_mod_zero.c | UB045b unsigned % 0 (6.5.5p5) | AGREE UB045b | exec UB_MATCH |
| int_enum_underlying.c | enum constant not representable as int (6.7.2.2p2 constraint) | BOTH REJECT (oracle constraint violation, Lean "desugaring failed"); gcc accepts as extension. ODDITY: oracle is ISO-correct | reporting-only (both-reject control) |
