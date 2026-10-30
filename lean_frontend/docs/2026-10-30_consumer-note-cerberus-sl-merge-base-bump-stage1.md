# Consumer note for cerberus-sl: the merge-base bump, stage 1 (2026-10-30)

From: the `arc/merge-base-bump` worker [AGENT]. Occasion: the Cerberus merge-base of this fork moved
from upstream `b9aeedcb4` to `c3ff8c53f` (record `docs/2026-10-29_merge-base-bump-stage1-record.md`).
cerberus-sl pins cerberus-lean by commit in `scripts/semantics-pin.env`; this note is what the re-pin
that includes `arc/merge-base-bump` carries, for the consumer's own `DECISIONS`. The companion note for
cerberus-caesium (`docs/2026-10-30_consumer-note-cerberus-caesium-merge-base-bump-stage1.md`) lists
the signature and AST changes in full; this one lists what reaches a consumer of the driver, the
outcome protocol and the memory model.

- **Entry points.** `desugar` takes a `desug_config` after `sup top`; `translate` takes an
  `elab_config` record in place of the calling convention (upstream 334a1563b). `Main.lean` supplies
  the oracle-mirroring defaults (`branching_on_unspec := .Elab_UB`); the new upstream switch
  `branching_on_unspec_is_nd` is refused by `--switches` like every non-PNVI switch.
- **Verdicts that moved** (both engines, lanes re-recorded, record §4): a pure null-pointer shift is
  `UB046_array_pointer_outside` (was a crash on both engines; `Mem.array_shift_ptrval` now returns
  `Undefined.t`, `CerbMem.arrayShiftPtrval` takes a `loc`); `_Alignas(2^62)` layouts and
  `Cerb_floating.mul` agree with Lean (ISO-fix register R6 and R7 retired). No other verdict moved;
  every refusal (D11–D13, asm) is unchanged.
- **Memory-model API.** `CerbMem.sizeofIval`/`alignofIval` are gone; layout is `CerberusImpl.*`
  (`sizeof_ty`, `alignof_ty`, `offsetsof`, …; carrier `CerberusImpl_lemMeasureProofs.lean`).
  `memcmpM` takes a `loc`. The outcome protocol, `CerbMemDefaultFacts`, `CerbMemAccessFacts` and
  the PNVI seams are unchanged.
- **Core text.** Branches on an unspecified value, `do … while` tests and `switch` labels elaborate
  differently (upstream cee382443, 83b1a7424, cabe81c3b); every pinned `.core` text re-derives
  (this repository's did: `tests/verify`, `tests/corpus`, the libc dumps).
- **A declared transport limitation (N4, VALIDATION §2b, SUPPORTED).** The libc Core text dump
  carries no source locations, so a UB raised inside a libc function reports `<unknown location>` on
  the Lean side where the oracle prints the libc source position; the verdict class and UB code
  agree. Both lanes carry the one affected row as `LOC_ONLY` (`LOC_ONLY-FIRST` in the inner_arg_temps lane) with its disposition
  (`tests/libc_exec/dispositions.txt`); the remover is the queued slice "Locations in the Core text
  transport" (`TODO.md`).
- **Diagnostics.** `Errors`/`Constraint` gain upstream's new constructors; `stringOfDesugarCause`
  gains arms; no batch-record field changed.
