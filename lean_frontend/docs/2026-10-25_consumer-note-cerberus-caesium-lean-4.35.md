# cerberus-caesium: the Lean 4.35.0 toolchain move of cerberus-lean

Author: [AGENT 2026-10-26]. Provider branch `arc/lean-4.35` (cerberus-lean), the
same-name pair of lem-lean's landed `arc/lean-4.35` (`mdd/lean-backend` = `e6d8db5`).
This describes the provider candidate, rebased onto the inner_arg_temps landing
(`mdd/cerberus-lean` `2c714c265`); it does not claim a landing, a consumer re-pin or a
build of cerberus-caesium. The checked commands and results are in
[the record](2026-10-25_lean-4.35-cerberus-record.md): the lem move is
output-identical for cerberus-lean's generated tree (record §6.2), the kernel replay
over every changed proof module and LemLib is exit 0 on the rebuilt tree (§6.5), and
the record's §7 carries the full battery and `lake check` results.

## What moves

- Lean `4.32.2` → `4.35.0` (`lean_frontend/lean-toolchain`, `speclab/lean-toolchain`,
  `tests/mem-scale-probes/micro/lean-toolchain`). Lake is 5.0.0: `lake update`
  rewrites `lake-manifest.json` to schema `1.3.0` (path entries gain `"copy": false`)
  and PROPAGATES a dependency's `lean-toolchain` into the workspace's.
- LemLib (lem-lean) `2d3a492` → `e6d8db5`: LemLib on 4.35.0 (`toList_bal` proof
  repaired, two deprecation swaps), the emitter's one output change
  (`@[noinline]` on synthesized tuple-let RHS defs `lemLetRhs_*`) has NO site in
  cerberus-lean's generated tree, which IS byte-identical at the re-pin (both
  generated trees regenerated with lem `e6d8db5`: `diff -r` clean, 0 `lemLetRhs_`
  sites; record §6.2).
- The native object `lean_frontend/native/md5.o` is rebuilt with 4.35.0's `leanc`
  (`make lean-native-obj`); a consumer that compiles its own `native/*.c` must do the
  same — the 4.32.2 object is not to be linked into a 4.35.0 binary.

## What does not move

- No theorem statement in any seam changed. `CerbMemAccessFacts` (the names
  cerberus-sl and cerberus-caesium cite: `loadM_erasure`, `storeM_erasure`,
  `recordAccess_of_observations_none`, the `stopObserving_*` lemmas, …) keeps every
  statement; only `loadM_erasure`'s proof gained two core lemmas in its
  `simp_all only` lists (`not_true_eq_false`, `Bool.false_eq_true`). Kernel replay
  over the module is in the record.
- No semantics change, no emitter change, no API rename. The Core-quoting D3 runner's
  Lake trace-schema pin (`"2025-09-10"`, `linkLibs` as `[path, hash]` pairs) is what
  Lake 5.0.0 writes — the consumer's module replay path
  (`core-quote-test --module`) is unaffected.
- `Float.toBits` on 4.35.0 still canonicalizes every NaN to `0x7ff8000000000000`
  (VALIDATION.md N2 stands); `Float.ofScientific` agrees with a correctly-rounded
  reference on the 200 sweep literals on both toolchains (it was never on
  `CerbFloat.of_string`'s path since 2026-09-11 anyway).

## What cerberus-caesium must do at its re-pin

cerberus-caesium builds `lean_frontend` BY PATH through its `.cerberus-ws` workspace,
so its own `lean-toolchain` must read `leanprover/lean4:v4.35.0` (Lake 5 propagates it
on `lake update`; otherwise set it by hand — a 4.32.2 Lake cannot load 4.35.0
`.olean`s), and its manifests move to schema 1.3.0 on the first `lake update`.
Then expect, in its own seams and proofs, the classes this move hit in
cerberus-lean (each with the repair that worked, record §1.2):

1. **Removed `String` functions** (deprecated in 4.32.2, gone in 4.35.0):
   `dropRight`/`dropRightWhile`/`trim` → `dropEnd`/`dropEndWhile`/`trimAscii`,
   all returning `String.Slice` (`.copy` or `.toString` back to `String`;
   `.isEmpty`/`.toInt?` exist on slices; `String.Slice.length` is deprecated —
   either `.toString.length` (the landed text in cerberus-lean's `Main.lean`) or
   `.copy.length`/`.isEmpty` works); `String.drop` returns a slice too;
   `Slice.dropRight` → `Slice.dropEnd`. Behaviour of the replacements on the
   whitespace and separator classes checked equal (record §1.2 (a)).
2. **`split` on a `lem_if`/`decide` guard after `simp only [worker, intLtb]`**: the
   `Decidable` instance inside the `ite` still names the folded helper after simp
   rewrote the condition, the goal is ill-typed under implicit transparency, and
   4.35.0's `split`/`cases h :` refuse it (`Could not split an 'if' or 'match'
   expression in the goal`). Repair: do not unfold the comparison helper
   (`intLtb`/`intLteb`/`natGtb`/`natGteb`/`intGteb`), `split` on `if intLtb i n = true`,
   and type the bridge (`have h' : i < n := of_decide_eq_true h`). Axioms unchanged
   (`[propext, Quot.sound]`); a `by_cases` repair risks `Classical.choice` in the cone.
3. **`simp_all only […]` no longer closes contradictory-arm goals by itself**: a
   hypothesis left as `¬True` or `false = true` needs `not_true_eq_false` /
   `Bool.false_eq_true` in the `only` set. **`refine` no longer unifies a lemma's
   conclusion through a dead `if false = true then … else …`** on the goal's side:
   rewrite it away first (`rw [ite_eq_right (fun h => Bool.noConfusion h)]`). **A
   term-mode `rfl` (or `by rfl`) argument whose expected type still has
   metavariables** no longer postpones: pass `?_` and discharge the hole with `rfl`
   after the goal fixes them.
4. **Deprecations** (warnings on 4.35.0; next in line for removal): `String.mk` and
   `List.asString` → `String.ofList`; `String.get`/`String.prev`/`String.get!` →
   `String.Pos.Raw.get`/`.prev`/`.get!` (different namespace: `String.Pos.Raw.get s p`);
   `List.Sublist.cons₂` → `cons_cons`; `if_pos`/`if_neg`/`if_false`/`if_true`/
   `ite_cond_eq_false` → `ite_eq_left`/`ite_eq_right`/`ite_false`/`ite_true`/
   `ite_eq_right_of_eq_false` (identical signatures). `#synth BEq` at `Int` or a
   fixed-width type now prints `….instLinearOrderPackage.toBEq`, so a `#guard_msgs`
   pin naming `instBEqOfDecidableEq` there must move (none existed in cerberus-lean).
5. **New `unused simp argument` warnings** where 4.35.0's simp no longer needs a
   lemma (three in cerberus-lean's measure proofs): drop the argument, re-run.
6. **Unchanged on 4.35.0**: the generated tree's two warning kinds (lem-lean TODO 54),
   `-DautoImplicit=false`, `#guard_msgs` texts, the `lake env leanchecker` gate.

Two 4.35.0 facts a consumer may rely on, measured in the record (§2, §3):
- the 128-field constructor runtime limit is gone (127/128/129/255-field structures
  allocate and run; 256 fields do not elaborate on either toolchain). Lem's emitter
  still refuses ≥128-field records (lem-lean TODO 55, pending a ruling);
- the 4.35.0 code generator inlines small non-extractable nullary defs into their
  consumers (lem-lean review P2-1); in cerberus-lean's tree and seams no nullary def
  that mentions an impure seam exists, and the two pure nullary constants that mention
  a failure leaf are read as persistent globals (not inlined). Compiled IR symbols are
  `lp_<package>_<Module>_<name>` under 4.35.0's compiler.

Gate status at the provider: the record's §1.3 (checkpoint checks), §5 (the pre-go
Tier A), §6.5 (kernel replay) and §7 (the full battery and `lake check` after the
rebase).
