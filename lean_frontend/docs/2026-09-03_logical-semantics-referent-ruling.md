# The referent is the logical semantics — ruling (2026-09-03)

[USER 2026-09-03], verbatim, refining the "No magic values" principle
(`DESIGN.md` §4): "The only refinement I'd make is that ocaml limits that
are hardcoded thanks to ocaml-level execution issues are also forbidden,
the real thing is the logical semantics". Together with, the same day:
"any instance of a value that can be quantified over by a context /
theorem is fine. Defaults that are chosen eg. in test suites are fine.
Any and all magic values that are hardcoded and can't be quantified over
are definitionally bugs (unless they mirror lem or ISO-C design
choices)".

## What it changes [AGENT reading, for the operator's confirmation]

The zero-discrepancy rule (`2026-09-03_zero-discrepancy-design.md` §1)
says Lean computes what the oracle computes. Its referent is now stated
precisely: the LOGICAL semantics the oracle implements — the lem model,
the Core stdlib, ISO C where the model is silent — not the OCaml
runtime's execution accidents. Two classes of one-sided oracle failure
therefore part ways:

1. **Semantic fail-stops**: a `failwith`/`assert` the MODEL writes
   deliberately (`impl_mem.ml` "FREE was called on a dead allocation",
   `case_ptrval`, unsupported CHERI intrinsics). These ARE the
   semantics' design choices → mirrored (Q4: `panic!` with the OCaml
   text; later the typed-outcome pass). Unchanged.
2. **OCaml-execution artifacts**: `Z.Overflow`/`Failure` from host-int
   conversions (`Z.to_int`, `Nat_big_num.to_int`), `Division_by_zero`
   from a missing guard, `Stack_overflow`, 63-bit `int` wrap, polymorphic
   compare raising on closures. These are NOT semantics → Lean
   implements the logical meaning of the model at that point, the case
   is LOGGED (upstream tray) and PINNED (immaculate Lean-right/
   oracle-wrong pair that flips when upstream fixes it). Previously such
   cases needed an individual ISO-fix register ruling under criterion
   (ii′); under this refinement they are a CLASS admission — the
   register still lists them (visibility, the pin, the tray cross-ref)
   but the per-entry "extremely high bar" applies to deviations of kind
   1, not kind 2.

Consequences [AGENT] put to the operator:

- Register R3 (`s4b-memcmp-hugesize`, `Z.to_int` at `impl_mem.ml:2660`):
  ADMITTED by class (was: conditional on a scratch-oracle build).
- `aligned_alloc(0, n)` (Z2 audit M-01): the oracle's `Division_by_zero`
  in `Concrete.op_ival` is kind 2 → NOT mirrored as a crash. The logical
  meaning must be stated (ISO 7.22.3.1 / Cerberus's own UB045 for an
  invalid alignment; today Lean answers `DUMMY(align_alloc)` for `(0,8)`
  and a value for `(0,0)`, neither principled) → a decision row, tray
  draft, pin.
- lem-lean: the 2^62 conversion checks kept at `3c88f0d` (Lean failing
  where `Nat_big_num.to_int` raises) are kind 2 → REMOVED in the
  fuel-parameter arc; Lean's `natFromNatural` etc. follow lem's logical
  semantics (unbounded). The parity runner records the OCaml-target
  raise as a documented OCaml deviation, not a parity requirement.
- The lem-lean exception classes (a) message text / (b) resource /
  (c) missing feature are unchanged; "OCaml-execution artifact" is not
  an exception to zero discrepancies — it is a statement of which side
  is the deviant.
- Z4's VALIDATION rewrite states the referent in the headline.

## Provenance

[USER 2026-09-03]: the quoted rulings. [AGENT] (orchestrator): the two
classes, the consequences list. Docs-only; nothing merged or pushed.
