# `"hello" + 1` (a string literal plus an integer constant) is not accepted as an address constant in a static initialiser

**Merged into report 09 on 2026-11-07** (`09-address-constant-member-rejected.md`: the same mechanism —
`cabs_to_ail.lem`'s constant-expression predicates — and one patch against `c3ff8c53f`). Fixed in the fork
on 2026-11-07 as a fork-ahead delta (record `lean_frontend/docs/2026-11-07_address-constants-record.md`;
witness `scripts/check_address_constants.sh`, e.g. `ac_str_plus`: `"hello" + 1` runs on both engines, gcc's
101; `ac_str_elem` (`&"hello"[1]`), `ac_str_cast_plus`, `ac_str_concat`, `ac_ctx_struct_str` likewise).

The original draft (2026-09-05) described the missing `AilEstr` arm of `is_address_constant`
(`cabs_to_ail.lem:894-925` at `b9aeedcb4`; upstream `6b65dc04f` later gave `is_lvalue_to_static_object` that arm,
not this predicate), the reproducer `static const char *s = "hello" + 1;` (both engines: the §6.7.9#4
constraint violation; gcc 13.3.0: 101) and the one-arm remedy; report 09 carries the clauses, the reproducer
and the patch now. Not changed: the VALUE of a string literal element (`static char c = "hello"[1];`) is a
read through `[]` (C17 6.6#9); gcc folds it as a 6.6#10 extension, the fork keeps upstream's rejection.
