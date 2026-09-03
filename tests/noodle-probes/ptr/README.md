# ptr/ — pointer, layout and provenance probes (nolibc mode)

Oracle==Lean on every accepted probe (`results.log`; note the runner
displays at most 20 verdict lines per engine — the comparison uses the
full output). Findings: record §D2, §P1, §P2, §E2, §O2.

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| ptr_onepast.c | one-past pointer compare/diff (6.5.6p8, 6.5.8p5) | AGREE 3-way | exec MATCH, gate-worthy |
| ptr_cross_object_eq.c | equality across objects (6.5.9p6) | AGREE 3-way, 8 traces each (unsequenced printf args — counts match) | exec MATCH |
| ptr_cross_object_lt_ub.c | relational across objects is UB (6.5.8p5) | oracle==Lean `Specified(2)` (address compare, no UB); gcc 1 — ODDITY O2 (PVI concrete model compares addresses; program is UB so no referee) | exec MATCH; gcc SKIP (UB program) |
| ptr_int_roundtrip_ops.c | ptr->int->ptr with +/^ arithmetic (6.3.2.3p5) | oracle==Lean UB043; gcc `20 30 40 10 8` — P2 | exec UB_MATCH; gcc-lane: SKIP_UB (Lean verdict UB) — P2 witness |
| ptr_intptr_arith_roundtrip.c | minimal P2: `(int*)(u + 4ul)` | oracle==Lean UB043; gcc 20 — ORACLE-SUSPECT P2 | exec UB_MATCH; gcc-lane SKIP_UB pinned; flips to AGREE when P2 is fixed |
| ptr_to_int_narrow_ub.c | pointer -> int too narrow (6.3.2.3p6) | AGREE UB024; **Lean loc `other_location(Concrete)` vs oracle `<7:11--7:17>`: DISCREPANCY D2** | exec UB_MATCH (loc stripped); D2 reproducer |
| ptr_struct_layout.c | sizeof/offsetof/_Alignof with padding, nested (6.7.2.1) | AGREE 3-way | exec MATCH, gate-worthy |
| ptr_union_punning_bytes.c | punning via unsigned char / same-size unsigned incl. double bits (6.5.2.3 fn95) | AGREE 3-way | exec MATCH, gate-worthy |
| ptr_union_partial_write.c | read wider member than written (6.2.6.1p7) | oracle==Lean `Unspecified('signed int')` | exec MATCH; gcc SKIP_UNSPEC |
| ptr_string_literals.c | concatenation, escapes at boundaries, sizeof (6.4.5) | oracle CRASH (exit 125, `decode_character_constant ... ?` — tray 10's `\?` in STRING-literal form); Lean correct and == gcc `98 65 66 4 83 52 3 10 9 92 34 39 63 0 4` — E2 | immaculate ORACLE_CRASH pair (Lean-right), Lean pin `VAL:Specified(0)` + stdout |
| ptr_2d_array_arith.c | pointer-to-array arithmetic (6.5.6p9) | oracle==Lean `3 8 8 16 12 23 16 21`; gcc `3 8 2 16 12 23 16 21` — P1 | exec MATCH; gcc-lane pinned DISAGREE pair (P1) |
| ptr_array_ptrdiff_scaling.c | minimal P1: `&a[2]-&a[0]` on int[3][4] etc. | oracle==Lean `8 3 2 2 4 8`; gcc `2 1 2 2 1 8` — ORACLE-SUSPECT P1 (upstream-confirmed) | exec MATCH; gcc-lane pinned DISAGREE pair; flips on the impl_mem fix |
| ptr_subobject_bounds.c | inner-array overrun within the outer object (6.5.6p8 UB; PVI per-allocation bounds) | AGREE 3-way 13 (documents the model stance) | exec MATCH; gcc AGREE |
| ptr_funcptr_eq.c | function pointer equality/casts (6.5.9p6, 6.3.2.3p8) | AGREE 3-way | exec MATCH, gate-worthy |
| ptr_uninit_local_read.c | read of indeterminate automatic (6.3.2.1p2) | oracle==Lean `Unspecified('signed int')` | exec MATCH; gcc SKIP_UNSPEC |
| ptr_uninit_struct_member.c | whole-struct copy with an indeterminate member | AGREE 3-way 7 | exec MATCH, gate-worthy |
| ptr_dangling_eq.c | equality against a dead object's address (6.2.4p2) | oracle==Lean `Specified(0)`, 2 traces each | exec MATCH |
| ptr_alignment_observed.c | _Alignof + alignment residues of objects (6.2.8) | AGREE 3-way | exec MATCH, gate-worthy (observes residues, not addresses) |
| ptr_struct_assign.c | struct assign/by-value pass/return (6.5.16.1p2), sequenced | AGREE 3-way `133 227 6 120` | exec MATCH, gate-worthy (the unsequenced form is an RC-4 both-slow 67,650-trace enumeration: Lean >60 s, oracle ~100 s) |
