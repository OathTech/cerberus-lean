# PNVI-ae-udi: a debug `Printf.printf` to stdout in a semantics arm of `eff_array_shift_ptrval`

**Affected:** `memory/concrete/impl_mem.ml` `eff_array_shift_ptrval` (upstream `b9aeedcb4`
`:2244-2356`), `Prov_symbolic` arm, `Double (alloc_id1, alloc_id2)`, non-zero shift, both
preconditions true, not `SW_pointer_arith PERMISSIVE` (`:2283-2291`):

```ocaml
Printf.printf "id1= %s, id2= %s ==> addr= %s\n"
  (Z.to_string alloc_id1) (Z.to_string alloc_id2)
  (Z.to_string shifted_addr);
fail ~loc (MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift")
```

## Description

The arm writes a debug line to the tool's STDOUT and then fails with an `Error` verdict. In
`--batch` mode stdout is the verdict stream, so the line precedes the verdict record. The verdict
text also misspells the model ("PNVI-ae-uid").

## Reproducer

None found: the arm needs a symbolic pointer whose two candidate allocations both admit the same
non-zero shift. The fork's measurements (`-d 10` traces of the 44 PNVI litmus files and four pKVM
drivers, design record §C.6) never print `id1=`. Reported from the code.

**Correction (2026-10-08) [AGENT]: reproducer found.** The arm IS reachable through `member_shift_ptrval`
(upstream `b9aeedcb4` `:2223`), which keeps a symbolic pointer's ambiguous iota and moves the address
with no collapse. The fork's lane witness `tests/pnvi_refusals/r10-array-shift-member-shifted-symbolic.c`:

```c
// PNVI witness for refusal R-PNVI-10 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1; correction in the arm-witness
// record lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md §4.3, review F1).
// Under --switches=PNVI_ae_udi the integer (uintptr_t)&s is one past z AND the start of s
// (both exposed; the condition below checks the adjacency), so p is a Prov_symbolic pointer
// with a `Double` iota. member_shift_ptrval (impl_mem.ml:2267-2286, via
// eff_member_shift_ptrval :2402) keeps that iota with NO collapse; the array shift
// &p->b - 1 then reaches eff_array_shift_ptrval's Prov_symbolic arm with a `Double` iota and
// a non-zero offset: the oracle prints its `id1= …, id2= … ==> addr= …` debug line and
// answers `Error` ("(PNVI-ae-uid) ambiguous non-zero array shift"); cerberus-lean REFUSES
// there (R-PNVI-10).
#include <stdint.h>
struct S { int a; int b; } s;
int z;
int main(void) {
  uintptr_t i = (uintptr_t)(&z + 1);
  uintptr_t j = (uintptr_t)&s;
  if (i != j) return 9;
  struct S *p = (struct S *)j;
  int *t = &p->b - 1;
  return t == &s.a;
}
```

Pristine upstream `b9aeedcb4`, `--exec --batch --mode=exhaustive --switches=PNVI_ae_udi` (verbatim,
MEASURED 2026-10-08):

```
id1= 19, id2= 20 ==> addr= 281474976707756
Error {msg: "MerrOther "(PNVI-ae-uid) ambiguous non-zero array shift""}
```

The "None found" above and "unreachable on every measured input" below are superseded (they remain true of
the litmus and pKVM corpora).

## Proposed remedy

Remove the `Printf.printf` (or route it through `Cerb_debug.print_debug`), and fix the spelling
in the message.

## Classification

TRUE BUG (minor; output hygiene), unreachable on every measured input.

## Provenance

Found in the cerberus-lean PNVI design pass (`lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md`
§G.1 row R16) and re-read against upstream `b9aeedcb4` on 2026-10-07. Fork status: cerberus-lean
REFUSES at this arm (refusal R-PNVI-10, [USER 2026-10-05]; nothing is written to stdout). Duplicate
search: none done (no network at drafting); repeat before filing.
