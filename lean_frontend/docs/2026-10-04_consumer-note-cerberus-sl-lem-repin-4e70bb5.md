# Consumer note for cerberus-sl: the lem re-pin to `4e70bb5` (read before re-pinning)

From: the cerberus-lean re-pin worker [AGENT], on the orchestrator's brief. Range: `arc/lem-repin-4e70bb5`, which
fast-forwards over mainline `9e63218bc`. Record: `docs/2026-10-04_lem-repin-4e70bb5-record.md`. The lem-side records
are lem-lean `doc/lean-backend/2026-10-03_output-niceness-arc-plan.md`, `2026-10-03_backend-hardening-record.md`
(its §8 is a draft cerberus-sl note, read-only analysis at cerberus-sl `12d247c`) and
`2026-10-03_beq-instance-lattice-design.md`.

cerberus-sl currently pins cerberus-lean `2b51d2a57` (LemLib `38f87d5`). Its next re-pin therefore crosses this
re-pin AND the earlier one to `77ad4fa` (`docs/2026-09-30_consumer-note-cerberus-sl-lem-repin-77ad4fa.md`); read
both.

## What stays the same

- **The OCaml oracle is unchanged.** The generated OCaml (`ocaml_frontend/generated`, 86 files, and
  `sibylfs/generated`) is byte-identical to the `77ad4fa` output.
- **Every differential lane baseline is unchanged** (Tier A exact; the record quotes the lines).
- **No `.lem` source changed, and no hand-written seam changed except one proof** (`natEq0_iff`, below).
- **The toolchain is unchanged: Lean 4.32.2.**
- **The relied-on list (VALIDATION §3b) is untouched.** None of the five behaviours (the address-space top, the run
  digest as run-state data, the enum reader, the fail-closed tuple-arity matcher, the fuel-indexed ND runner and its
  kill/out-of-memory outcomes) is in a file whose generated text changed beyond layout and comments, and none of
  their hand-written seams (`CerbND`, `CerbMem`, `CerberusFresh`, `Main`) was edited. The only generated modules
  whose tokens changed are `AilSyntax`, `AilSyntaxAux` and `Cabs` (front-end AST records; §2). Their elaborated
  TERMS can still differ where they compare at a base type with `==`: that is the instance switch of §1, the same in
  every module.

## 1. The BEq instance lattice: `==` at base types is core's (proofs WILL break)

LemLib's `[Eq0 a] : BEq a` bridge now sits below core's `[DecidableEq a] : BEq a`. Generated `==` at `Nat`, `Int`,
`String`, `Bool`, `Char`, `Unit` and the abbreviations of them (`aid`, `thread_id`, `allocation_id`, …) now
elaborates to **core's** `instBEqOfDecidableEq`, not `@instBEqOfEq0 T instEq0T`. For LemLib's base instances the two
are equal (`bridge_<T>_is_core`, by `rfl`), so behaviour is unchanged, but the TERMS differ. `sym`'s digest is the
exception: its `Eq0 String` instance is cerberus's model instance (`Symbol.lean:81`,
`isEqual x y := CerberusFresh.digest_compare x y == (0 : Int)`), and its agreement with equality is the
propositional theorem `CerbCtypeMeasure.digest_compare_eq_zero_iff`, not an `rfl` bridge (corrected per the
pre-merge audit A4, record §9). In both cases: `show`/`change` to the old
comparator body no longer matches, and lemma statements that name the bridge stop matching syntactically
(`rw`/`simp only` with them stop firing). lem-lean's census counts 675 changed Cerberus declarations, all explained
by the instance switch. That census ran on cerberus `51a7402ce`'s tree; `51a7402ce..9e63218bc` adds no instance or
equality declaration (grep; record §9).

cerberus-lean needed exactly one edit, lem-lean's drafted patch (verbatim):
`CerbCtypeMeasure.natEq0_iff` now reads `show (n1 == n2) = true ↔ n1 = n2; exact beq_iff_eq`.

**cerberus-sl sites (re-checked read-only at cerberus-sl `b2dfedd`, 2026-10-04, grep; not built here).** They match
lem-lean's §8 table:

| Site | What breaks | Suggested replacement |
|---|---|---|
| `CerberusIris/CerberusIris/Env.lean:30` `lemNatBeq_iff` | statement names `@instBEqOfEq0 Nat Lem_Num.instEq0Nat_1`; proof `show (match defaultCompare a b …)` (`:31`) | restate as `(a == b) = true ↔ a = b`, proof `beq_iff_eq` |
| `Env.lean:38` `lemNatBeq_eq_decide` (and `:41-42` inside it) | statement names the bridge | restate `(a == b) = decide (a = b)` |
| `CerberusIris/CerberusIris/Lang.lean:178` (`lem_nat_beq_iff`) | `change (match Lem_Basic_classes.setElemCompare …)` | `beq_iff_eq` |
| `CerberusIris/CerberusIris/EvalArms.lean:1598` (`lem_int_beq_iff`) | same shape | `beq_iff_eq` |
| `CerberusIris/CerberusIris/Repr.lean:31` (`int_beq_refl`) | `show (match defaultCompare x x …)` | `beq_self_eq_true` |
| `Repr.lean:411-412` `lem_nat_beq_self` | statement names the bridge; `change (match setElemCompare a a …)` | `beq_self_eq_true` |
| `CerberusIris/CerberusIris/Call.lean:182` (inside `call_proc_eq`) | `change (match setElemCompare params.length params.length …)` | `beq_self_eq_true _` or `simp` |
| `CerberusSL/CerberusSL/StdLibEq.lean:33` `lem_nat_beq_self` | re-export whose statement names the bridge | restate with `==` |

Also re-check the `simp only [… beq_iff_eq]` calls, which were inert on the bridge and will now fire:
`Env.lean:26`, `Recon/Admit.lean:742`, `Recon/Arena.lean:393` (lem-lean §8 names the follow-on `obtain`/`rcases`
shapes). Unaffected: comparator VALUES (`fmapAddBy defaultCompare …` in `DriverLoop.lean:446,528`), which are not `==`.

## 2. Records in mutual/recursive blocks are `structure`s (names kept)

`AilSyntax.statement` (fields `loc`, `desug_info0`, `attrs`, `node`) and `Cabs.specifiers` (fields
`storage_classes`, `type_specifiers`, `type_qualifiers`, `function_specifiers`, `alignment_specifiers`) were
`inductive … | mk …` with hand-emitted `@[inline] def T.field` accessors; they are now `structure`s.

- Kept: the type names, the constructor `T.mk` and its positional argument order, the recursor, and the accessor
  NAMES (now structure projections). `{ s with … }`, anonymous-constructor and positional `T.mk` construction all
  work (cerberus-lean's `CabsImport.lean:661` positional `specifiers.mk …` built unchanged).
- Changed: the accessors are projections, not `def`s, so `unfold statement.loc`/`simp [statement.loc]` behave as for
  any projection; generated construction sites now use structure-instance syntax (`{ loc := …, … }`) and updates use
  `{ stmt with … }` (both elaborate to `statement.mk`); `T.mk._flat_ctor` is new; matcher auxiliaries inside
  `lemSize` were renumbered (`T.lemSize.match_1` new, `T.<first field>.match_1` gone).
- cerberus-sl: grep at `b2dfedd` finds NO use of `statement.mk`, `specifiers.mk`, these accessors, their recursors,
  or `.match_N`/`_hyg` names.

## 3. Layout, comments and printer cleanup (text only)

The generated Lean is laid out over lines (longest line 105,826 → 602 characters), carries the `.lem` authors'
comments, merges `open` lines and adjacent implicit binders (`{a b : Type}`), drops redundant parentheses, and no longer
prints the `/- removed value specification -/` placeholders (1,477 → 0) or the garbled `Â§`. Declarations are
unchanged by this: comparing the old and new trees token by token, after removing comments, whitespace and parentheses
and splitting merged `open`s and binder groups, 167 of the 170 changed generated files are identical, and the
remaining three are §2's. lem-lean's declaration census with macro scopes erased shows the same thing. Two
consequences for proofs:

- **Inaccessible hygienic names may be renumbered** (`…._hyg.N` helpers in `Cabs` and elsewhere). Nothing accessible
  changes.
- **Textual quotes of generated code** (comments, docs, tests that grep the generated files) go stale. cerberus-lean
  had three such instruments (record §4). Line numbers in `generated/*.lean` all moved: re-derive any `File.lean:N`
  citation.

## 4. LemLib deletions (backend hardening, package C)

Removed from LemLib: `natDiv`, `natMod`, `lemBoolToProp`, `listGet?`, `listGet!`, `listSet`, `setPartitionBy`, the root
`unsupportedRational*`/`unsupportedReal*` duplicates, `lemListMapiAux` (+ its theorem), and `Pmap.mem`, `maxBinding?`,
`exists_`, `filter`, `partition`, `compare`. lem-lean counted 0 cerberus-sl hits. Root `apply` is gone; tactic `apply`
is unaffected.

## Re-pin procedure

Pin cerberus-lean by commit in `scripts/semantics-pin.env` once `arc/lem-repin-4e70bb5` has landed. Your workspace's
Lake manifest then resolves LemLib at `4e70bb506d962355b7120260d4d176aa2850dcc3`. Expect to fix the eight §1 sites
(plus the `simp only [… beq_iff_eq]` follow-ons); a full cerberus-sl build is the check.
