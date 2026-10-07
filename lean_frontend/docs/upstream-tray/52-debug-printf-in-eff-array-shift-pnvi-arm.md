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
