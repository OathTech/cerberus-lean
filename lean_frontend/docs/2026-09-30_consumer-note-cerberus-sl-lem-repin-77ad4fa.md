# Consumer note for cerberus-sl: the lem re-pin to `77ad4fa` (read before re-pinning)

From: the cerberus-lean re-pin worker [AGENT], on the orchestrator's brief. Range: `arc/lem-repin-77ad4fa`, which
fast-forwards over mainline `55b04e7a4`. Record: `docs/2026-09-30_lem-repin-77ad4fa-record.md`. The lem-side record is
lem-lean `doc/lean-backend/2026-09-28_linksem-findings.md`.

## What stays the same

- **The OCaml oracle is unchanged.** The generated OCaml is byte-identical.
- **Every differential lane baseline is unchanged** (Tier A exact).
- **The toolchain is unchanged: Lean 4.32.2.** LemLib now uses the same toolchain.

## LemLib API changes

1. **`lemFailStop` and `lemSetExitOnPanic` are removed** (ruling D1(b) [USER 2026-09-30] "D1: agree"). Their
   replacement is `lemRequireAbortOnPanic : IO Unit`, called first in `main`. It refuses to run (exit 2) unless
   `LEAN_ABORT_ON_PANIC=1`, which is the pattern of cerberus-lean's own driver. No cerberus-sl `.lean` file referenced
   the removed names when this note was written (grep).
2. **New LemLib root names are reserved.** Lem renames user definitions that would collide with them:
   `lemChr`, `lemFunctionalBeq`, `lemFunctionalCompare`, `lemIntAsr`, `lemIntLand`, `lemIntLor`, `lemIntLsl`,
   `lemIntLxor`, `lemNatAsr`, `lemNatLand`, `lemNatLnot`, `lemNatLor`, `lemNatLsl`, `lemNatLsr`, `lemNatLxor`,
   `lemRequireAbortOnPanic`, `lemSeq`, plus `lem_if`. Hand-written Lean that defines one of these names at the root
   will clash with LemLib.
3. **`lemSeq` is a new native seam, on the boundary list as TEMPORARY.** Its definition is
   `lemSeq (a : Unit → α) (b : Unit → β) : β := b ()`, and it is **transparent**: proofs see `b ()`. Its run-time body
   `lemSeqImpl` forces `a ()` first, mirroring OCaml's strict `let`. A failure or non-termination in `a` is invisible to
   the logic. In Cerberus every such `a` is a debug `print_debug_pure`/`warn` no-op (268 sites). Its named mover is
   lem-lean TODO 24 (the failure-monad translation). See VALIDATION §3 and `scripts/unsafebaseio_allowlist.txt`.

## Generated-code shapes that proofs see

- **Discarded debug calls.** `match CerbDebug.print_debug_pure … with | () => e` becomes
  `lemSeq (fun _ => CerbDebug.print_debug_pure …) (fun _ => e)`. Add `lemSeq` to any `simp only` / `unfold` set that
  goes through such a site; cerberus-lean needed that in two proofs. cerberus-sl quotes the old shape in at least
  `CerberusIris/CerberusIris/Env.lean:51` and `DriverGlobals.lean:90,201` (grep; not rebuilt here). Expect those to
  need `lemSeq`, and to drop `CerbDebug.print_debug_pure` where it becomes unused.
- **`lem_if`.** Lem's `if` is written `lem_if c then t else e`. The macro expands to exactly
  `@ite _ (c = true) (instDecidableEqBool _ _) t e`, the term Lean elaborates for a Bool `if`. Proofs by `rfl`, `simp`
  or `split` should be unaffected; textual quotes of generated code are not.
- **Empty lists.** Every empty list literal of closed Lem type is written `([] : T)`.
- **Comparison instances (A1).** The 722 failing fallback comparison instances are gone. Comparisons at types with
  function-typed fields (e.g. `pre_execution`, `core_step`, `memory_model`) are now derived. They fail only on reaching a
  closure (`lemFunctionalBeq`/`lemFunctionalCompare`, "compare: functional value", as OCaml does). Instance resolution
  at these types can pick a different, now structural, instance than before.
- **Other shape changes.** 170 more `let`s carry a type annotation, and there are 9 more `@[never_extract]`.

## Re-pin procedure

Pin cerberus-lean by commit in `scripts/semantics-pin.env` once `arc/lem-repin-77ad4fa` has landed. Your workspace's
Lake manifest then resolves LemLib at `77ad4facfc60814a4a3f5d09dc88168ca208b285`.
