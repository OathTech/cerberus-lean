# The effect-erasure soundness invariant (arc-14 S1 F5, sem:S17)

> **SCOPE-SHRINK ADDENDUM (effect-retirement C2, 2026-09-01 — charter
> §7.1: addendum, not deletion).** The effect-retirement arc deleted
> most of the seam table below: `CerbTags.*` (the tag table is passed
> by value), the fresh counter (`fresh_int` is an explicit threaded
> supply; `native/fresh_int.c` is gone), `CerbDebug`'s level globals,
> and `LemLib.runEffectful` itself (deleted at L2; lem now REFUSES
> `declare {lean} effectful`). The invariant below REMAINS NORMATIVE
> for the surviving pure-signature seams — the per-TU DIGEST read
> (`CerberusFresh.digest`, since C2 a kernel-checked opaque chain over
> a pure `@[extern]` binding, with the never-relate-across-`setDigestIO`
> obligation unchanged), the `CerbGlobal` config/switch refs, and
> `CerberusImpl`'s enum registry — all machine-pinned in
> `scripts/unsafebaseio_allowlist.txt` with their Q4 classifications.
> The table below is the 2026-08-22 record, kept verbatim.

Date: 2026-08-22. Status: normative. This page states, ONCE, the
soundness invariant governing every seam that gives a PURE-typed Lean
signature to a read or write of mutable native/global state. It replaces
the prose previously distributed across four file comments and an arc
doc; each such seam now points here.

## The seams

Cerberus's OCaml frontend reads and writes process-global mutable state
(the struct/union tag table, the fresh-symbol/digest counters, the debug
level, the config/switches). The Lean port mirrors these as functions
with PURE signatures (`Unit → T`, `T → Unit`), backed by native C globals
or `IO.Ref` cells through `@[extern]` / `@[implemented_by] … unsafeBaseIO`:

| Seam | State | Backing |
|------|-------|---------|
| `CerbTags.tagDefs / set_tagDefs / with_tagDefs / reset_tagDefs` | struct/union tag definitions | native C global (`native/tags.c`) |
| `CerberusFresh.fresh_int` / `digest` (via `runEffectful`) | fresh-symbol counter, TU digest | native C global (`native/fresh_int.c`) |
| `CerbDebug.get_level / set_level` | debug verbosity | native C global (`native/debug.c`) |
| `CerbGlobal.*` (confRef, switchesRef) | config + switches | `IO.Ref` via `unsafeBaseIO` (write-free today) |

`LemLib.runEffectful` is the generic version of the same trick for the
lem backend's effectful declares.

## The invariant

> **A pure application of an effect-erased seam is meaningful ONLY within
> a single ambient state. No proof may relate the values of two such
> applications made across a state-mutating boundary (a `set_*`, a
> `with_*` scope entry/exit, a `reset_*`), and no theorem STATEMENT may
> mention such an application.**

Formally: `tagDefs ()` is, to the kernel, a fixed opaque value; the
runtime makes it observe the current C global, which the kernel cannot
see. Two syntactically identical calls are provably equal in the logic
(`tagDefs () = tagDefs ()` by `rfl`) while the runtime disagrees across a
`set_tagDefs` — the classic `unsafePerformIO` referential-transparency
breach. This is SOUND to *execute* (the driver threads the ambient state
correctly) but UNSOUND to *reason about* as if pure. The statement-TCB
gate exists precisely so no theorem depends on it.

## The two obligations on every seam

1. **Armour.** Every `*_impl` and every top-level ref/opaque wrapper
   carries `@[never_extract, noinline]` (and the exposed opaque gets an
   `attribute [never_extract]`). Without it the compiler may (a) CSE two
   reads that straddle a write into one, or (b) cache a closed read as a
   startup constant evaluated before any write, or (c) inline a ref
   allocation so each use mints a fresh cell. The armour is not optional
   decoration — it is what makes the runtime semantics match the intended
   ambient-state reading. (CerbGlobal's refs are write-free today, so the
   breach is currently unobservable there; the armour is still mandatory,
   so a future setter or compiler upgrade cannot silently break it.)

2. **Never discard a write in pure position.** A `set_*` / `reset_*` whose
   Lean signature returns `Unit` is dead-code-eliminated when its result
   is discarded (`let _ := set_level x`), because a pure Unit-valued call
   with an unused result has no observable effect *in the logic*. Every
   hand-written call site that needs the write to happen MUST call the
   underlying `BaseIO` action directly (`← setLevelIO x`, `← reset…IO ()`),
   inside an IO/BaseIO do-block. (Found the hard way: arc-4 S3b for
   CerbTags; re-found at arc-14 S1 F5 for the `CerbDebug.set_level` call
   in `Main.lean`.)

## Enforcement

- The exec-slice PURITY gate (`scripts/check_exec_purity.sh`) and the
  theorem-axiom cones (`scripts/check_theorem_axioms.sh`) pin the
  seam axioms (`with_tagDefs`, `forceIO`) and keep the erased reads out
  of proof cones.
- The statement-TCB gate (`relsem/RelSem/Audit.lean`) fails the build if a
  slate theorem statement mentions a seam application.
- This page is the single normative reference; the seam-file comments
  (CerbTags, CerberusFresh, CerbDebug, CerbGlobal) cross-reference it
  rather than restating the argument.

## Temporal note

CerbGlobal's `IO.Ref`-via-`unsafeBaseIO` backing is the weakest of the
four (no native global, no `initialize`); it is acceptable only because
it is write-free. The registered forward path (should a setter ever be
needed) is to converge it onto either the native-C-global pattern
(`CerbTags`) or Lean's `initialize` idiom — armour alone does not make an
`IO.Ref` a process-global if writes are introduced.
