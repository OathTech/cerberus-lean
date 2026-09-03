# elab/ — elaboration-surface probes (nolibc mode)

Findings: record §E3 (`?:` in static initialisers rejected), §E4 (string
literal initialising array members rejected), §E5 (`"lit" + 1` address
constant rejected), controls E6/E7 (K&R, implicit int: both-reject by
design).

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| elab_tentative_defs.c | tentative definitions; extern incomplete array completed later (6.9.2) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_brace_elision_designators.c | brace elision, designators, override (6.7.9p17-20) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_string_init_sizing.c | top-level char arrays from string literals incl. no-NUL fit (6.7.9p14) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_string_member_init.c | `char a[2][3] = {"ab","cd"}` (6.7.9p14/p20) | BOTH REJECT (constraint violation); gcc 99 — ORACLE-SUSPECT E4 (upstream-confirmed) | reporting-only; flips to MATCH when fixed |
| elab_string_struct_member_init.c | `struct{char c[3];} w = {{"ab"}}` | BOTH REJECT; gcc 98 — E4 | reporting-only |
| elab_generic_static_assert.c | _Generic incl. qualifier stripping, _Static_assert, _Alignof (6.5.1.1, 6.7.10) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_atomic_qualifier_seq.c | _Atomic int compound assignment/++ in single-threaded code (6.7.3) | AGREE 3-way 8 | exec MATCH (concurrency-stub boundary exercised, agrees) |
| elab_typedef_shadow_scope.c | typedef shadowed by variable, struct tag scopes, incomplete-then-complete (6.2.1, 6.7.2.3) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_funcptr_decl_syntax.c | array of fn ptrs, fn returning fn ptr, ptr to fn (6.7.6.3) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_sizeof_no_eval.c | sizeof does not evaluate; precedence (6.5.3.4) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_escape_chars.c | simple/octal/hex escapes (6.4.4.4) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_const_expr_static_init.c | relational/sizeof/shift/%/unsigned-wrap/address constants in static init (6.6) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_const_expr_ternary_init.c | `?:` in a static initialiser (6.6p6-7) | BOTH REJECT ("not a compile-time constant"); gcc 10 — ORACLE-SUSPECT E3 (upstream-confirmed) | reporting-only; flips when fixed |
| elab_const_expr_ternary_contexts.c | `?:` in enum/array-size/case contexts | AGREE 3-way 10 (control) | exec MATCH |
| elab_addr_const_string_plus.c | `"hello" + 1` address constant in static init (6.6p9) | BOTH REJECT; gcc 101 — ORACLE-SUSPECT E5 (tray-09-adjacent) | reporting-only |
| elab_prototype_promotions.c | narrow prototyped parameters receive converted values (6.5.2.2p7) | AGREE 3-way | exec MATCH, gate-worthy |
| elab_kr_definition.c | K&R identifier-list definition (6.9.1p6) | BOTH REJECT "K&R-style declaration (unsupported)" (front-end, by design) — E6 control | reporting-only (both-reject) |
| elab_implicit_int_decl.c | implicit int (not C11) | BOTH REJECT (parse) — E7 control; gcc extension | reporting-only (both-reject) |
