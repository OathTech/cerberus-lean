# `?:` in a static-storage initialiser is rejected as "initializer element is not a compile-time constant"

**Merged into report 09 on 2026-11-07** (`09-address-constant-member-rejected.md`: the same mechanism —
`cabs_to_ail.lem`'s constant-expression predicates — and one patch against `c3ff8c53f`). Fixed in the fork
on 2026-11-07 as a fork-ahead delta (record `lean_frontend/docs/2026-11-07_address-constants-record.md`;
witness `scripts/check_address_constants.sh`, e.g. `ice_init_cond`: `(3 > 2) ? 10 : 20` runs on both engines,
gcc's 10; `ice_init_cond_divz`, `_nested`, `ctx_block_static_cond` likewise).

The original draft (2026-09-05) described the missing `AilEcond` arm of `is_arithmetic_constant_expression`
(`cabs_to_ail.lem:794-843` at `b9aeedcb4`), the reproducer `static int a = (3 > 2) ? 10 : 20;` (both engines:
the §6.7.9#4 constraint violation; gcc 13.3.0: 10) and the remedy mirroring `is_integer_constant_expression`'s
arms; report 09 carries the clauses, the reproducer and the patch now. Related, still open: an unevaluated
branch that is not itself a constant expression (`1 ? 3 : f()`) is rejected by the fork's arm as by
`is_integer_constant_expression`'s (its own "too strict" TODO); the GNU `?:` in a constant-expression position
is a separate crash (report 09's related findings).
