# Worker charter: the implementation profile is a parameter — plain `char` signedness selectable on both engines

Date 2026-11-22. Orchestrator [AGENT]. Branch `arc/impl-profile`, worktree `worktrees/cerberus-lean-arc/impl-profile`,
base = mainline `mdd/cerberus-lean` `77229f846` plus the scoping document (`docs/2026-11-20_impl-profile-scoping.md`,
carried onto this branch; READ IT FIRST: its sections 1-3 are the map, its option (b) is what this charter builds).
Roadmap `docs/2026-11-10_roadmap-maintenance-and-reporting.md`, active item 3: the consumer refinedc-lean is blocked
(its frontend must evaluate constants as upstream RefinedC does, with unsigned plain `char`).

## Rulings

[USER 2026-11-22] (1) start now; (2) execution under the unsigned-`char` configuration is made CONSISTENT by fixing
upstream's start-up binding in the fork (a fork-ahead fix with a tray report), not refused and not mirrored;
(3) validation of the second configuration is a witness lane alone, not a second pass of the execution and libc rows.
[AGENT 2026-11-22, orchestrator] settling the scoping document's remaining questions: the selector is upstream's
profile NAME (`default`, `hafnium`), the default stays `DefaultImpl` and every existing baseline, pin and digest stays
byte-identical under it; the class is named for the implementation and carries today's one differing field, so a
later field does not thread a second binder; the second configuration is described in SUPPORTED/CONTRACT as
consumer-configured and covered by the witness lane only; the pristine-oracle gate does not cover it (accepted); the
`.impl` Core file axis (`--impl`) is untouched; Morello/CHERI is untouched; contract D6 (LP64) is unaffected.

## The principle

One configuration value, visible in the types on the Lean side and selected once at the entry point on each engine,
read by EVERY phase that depends on it: the desugarer's constant evaluation, the Ail typing, the elaboration, Core's
signedness tests, the integer ranges and limit macros, the memory model's store/load, the decoder. No phase reads a
different value from another; no reader captures the value before selection.

## S1: threading with ZERO behaviour change (commit, then the orchestrator runs Tier A)

- Lean: the profile becomes an instance-implicit parameter in the manner of the PNVI switch set
  (`docs/2026-10-05_pnvi-s1-switch-parameter-record.md`; lem's `declare {lean} reader val … = instance`; the lem
  mechanism exists at the current pin, no lem change is expected: if one is needed, STOP and report). The hand-written
  constant at `CerberusImpl.lean:114` and every seam that branches on it (`CerbDecode.lean`, `CerbMem.lean` sites the
  scoping lists) read the instance. No instance is declared in the repository except by the entry points
  (`Main.lean`, `CerbCall.lean`, the test executables), as for the switch set; extend the existing speedbump
  (`check_no_fuel_numerals.sh` rule W1's shape) to the new class.
- OCaml: unchanged in S1 (the oracle already reads `Ocaml_implementation.get ()`).
- Acceptance: with the default instance every gate, baseline, libc dump pin and Core-quotation digest is
  byte-identical; the fuel-forms gate, the fuel-parametricity pins, the measure proofs and the axiom census pass with
  the extra binder; KERNEL REPLAY over every changed proof module is owed and quoted; `rfl` lemmas in the style of
  `has_switch_*_default` state that the default instance gives today's values.

## S2: the selector, upstream's binding fixed, the witness lane

- Upstream's defect (scoping section 1): `ailTypesAux.lem:28` binds `is_signed_ity` at module initialisation, so on
  the OCaml engine a later `set HafniumImpl.impl` leaves the elaboration, Core's signedness tests and the memory model
  on the default while the constant evaluator and the ranges change (pristine under Hafnium: `char c = (char)200;`
  dies in `impl_mem.ml` `bytes_of_int(signed)`). FIX in the shared Lem: the binding becomes a function of its
  argument; find every OTHER top-level capture of the profile in the model and the hand-written OCaml (the scoping
  searched per line: search properly, including multi-line bindings and partial applications) and fix each the same
  way; register the fork-ahead delta, single-row manifest edits with a dated NOTE; tray report with the reproducer
  on pristine driven through the library as RefinedC drives it, and the patch.
- Selectors: the fork's OCaml driver gains `--impl-profile=default|hafnium` calling upstream's `set` BEFORE any phase
  runs (an unknown name refuses, exit 2, as `--switches` does); the Lean driver gains the same flag building the
  run's instance; the Cabs JSON export records the profile it was produced under and the Lean driver REFUSES a JSON
  whose recorded profile differs from its flag (the preprocessor's limit macros and the parser's results are already
  baked into the JSON: a mismatch would be the mixed configuration this slice exists to prevent); a JSON without the
  field is refused, fixtures regenerated, `cabs-import-test` gains the cases. The library entry RefinedC-style
  consumers use (in-process selection) is documented with the exact call on each side.
- The witness lane `scripts/check_impl_profile.sh` in ladder row 1 (a core under a minute with plants; a fuller
  matrix as a Tier B row if larger): under `hafnium`, both engines agree byte for byte and equal gcc
  `-funsigned-char` on: the consumer's two symptoms (switch labels 255/128, the two-element array, the enumerator),
  `CHAR_MIN`/`CHAR_MAX`, plain-`char` conversions, comparisons, promotions and arithmetic, character and string
  literals with high bytes, store/load through `char` lvalues of values above 127 (the pristine crash), `char`
  bit-fields, `_Generic` on `char`, the libc string functions in libc mode; under `default` the same programs equal
  gcc `-fsigned-char`; the mixed-configuration refusal; pristine-under-Hafnium's crash as the negative control.
- Every existing lane, baseline and pin unchanged under the default (measure, do not assume): because you add a
  field to the Cabs JSON and regenerate fixtures, run EVERY lane that reads those fixtures or enumerates the touched
  corpora before calling S2 complete, as separate background jobs on a still tree; quote each.

## S3: documents

The record `docs/2026-11-22_impl-profile-record.md`; CONTRACT (D20), SUPPORTED (the second configuration as
consumer-configured), VALIDATION, LADDER, TODO; the tray report; consumer notes: refinedc-lean (how to select the
profile in process and at the driver, what changes in constant evaluation, the JSON field), cerberus-caesium and
cerberus-sl (every reader that gains the instance binder: list the definitions, as the unreferenced-binders note
did; a proof that mentions them needs the instance in scope; the default instance's `rfl` lemmas).

## Process

Focused gates yourself; never `scripts/release.py` in any form. All make/dune through
`/home/dev/projects/cerberus-lean-proj/scripts/ce`; lake/lean through `scripts/capped`, `CERB_MEM_MAX=32G`; the build
is under `-DwarningAsError=true` and stays so; no `set_option`, no resource-limit change. Start with a forced
regeneration and full rebuild. Check `/proc/loadavg` (< 12) and `free -g` before heavy jobs; long runs as separate
harness background jobs, none approaching an hour, on a STILL tree (no tracked-file edits while a gate runs); no
poller, watcher or sleep loop; never `pgrep -f`/`pkill`. No network; `/tmp` unreadable; scratch under the worktree's
`.tmp/`, deleted at the end. A claim in the record is exactly as wide as the probes or the structural argument behind
it; say which. Commits per stage on green gates, provenance tags, never quote the operator, no speculation about
upstream's plans, ending with `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing pushed; no mainline
commit. Tell the orchestrator (SendMessage to "main") when S1 is committed and continue. A blocker the charter does
not resolve: a committed park record (`docs/2026-11-22_impl-profile-park.md`) and a stop.
Report: hashes, the diff stat, gate lines verbatim, the list of readers that gained the binder (derived count), the
captures found and fixed, the witness matrix (hafnium / default / gcc / pristine-under-Hafnium), what was not done.
