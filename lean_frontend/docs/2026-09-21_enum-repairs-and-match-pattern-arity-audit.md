# Enum repairs and tuple-pattern arity: pre-merge correctness audit

[AGENT — independent review, begun 2026-09-21; completed 2026-09-22]

**Scope:** the complete changes in `0e1968ffb..e2fc391f2` (enum repair delta,
`d995e7f57`, `e2fc391f2`) and `5407597d9..14457f1a0` (fresh item-7 audit,
`0c15a1c11`, `14457f1a0`). The user explicitly requested correctness concerns
beyond the worker's summary and implementation fence. Related pre-existing
defects are distinguished from newly introduced behavior below.

**Verdict:** the enum repairs close E1–E4 from the earlier audit.
Correct the new register explanation in N2. Both independently rebuilt
heads passed all 39 full-battery commands on unchanged source.
The two new arity guards are correct, but item 7 has two P2 findings in the
surrounding typing/binding paths, plus inaccurate assurance text. I recommend
addressing R1/R2 before landing item 7.

At audit start, the main checkout remained at
`5407597d9eeba0259d65b728e86a860ad4614ab3`. The requested heads were on separate
feature branches, not merged into main. Both were audited in isolated
worktrees; no implementation, feature branch, or mainline was modified.
This is not certification of a combined integration head.

## R1 — P2: Core typing still accepts a tuple mismatch by deleting operands

**At `14457f1a0`:** `frontend/model/core_typing.lem:884–887`, reached through
the pattern-inference branches at `:772–782`, `:1174–1181`, and the ordinary
`Elet` rule at `:1709–1718`. The tuple-pattern guard at `:182–195` does not
cover these paths. The analogous `Eunseq` rule at `:1786–1795` also truncates.

Reproducer (`core-probes/pure-let-mismatch.core` in the evidence):

```text
proc main (): eff loaded integer :=
  pure (Specified (let (a: integer, b: integer) = (1, 2, 3) in a + b))
```

Run the freshly built fork with its own runtime:

```sh
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --nolibc --exec --batch --mode=exhaustive witness.core
```

Derived comparison from retained subprocess captures:

| Engine/tree | Default | Add `--typecheck-core` |
|---|---|---|
| Base `5407597d9` | `Specified(3)`, exit 0 | `Specified(3)`, exit 0 |
| Pristine `b9aeedcb4` | `Specified(3)`, exit 0 | `Specified(3)`, exit 0 |
| Arity head `14457f1a0` | `PElet: the pattern didn't match pe1`, exit 1 | `Specified(3)`, exit 0 |

This is not merely permissive acceptance. `--pp=core --typecheck-core` prints
the tuple as **`(1, 2)`**, whereas the default dump retains **`(1, 2, 3)`**.
The checker infers the pair type from the annotated pattern, then checks the
triple expression against that pair type. Its unchecked `List.zip bTys pes`
returns a new expression with the last operand removed. It never calls the
new `typecheck_pattern` guard.

The same happens to an effect-expression operand:

```text
proc main (): eff loaded integer :=
  let weak (a: integer, b: integer) = unseq(pure (1), pure (2), pure (3)) in
    pure (Specified (a + b))
```

The typed dump contains `unseq(pure(1), pure(2))`. The audit's freshly built
Lean probe independently observes both transformations: three tuple operands
become two; three `Eunseq` operands become two. These are runtime evaluations
of the actual generated `partial` typing definitions, not kernel theorems
about them.

The deletion can suppress an actual failure. In either example, replace
the surplus `3` by `error(<<<surplus>>>, 3)` (inside `pure` for the `Eunseq`
version). On **base, pristine, and repaired head**, default execution gives
`Error {msg: "surplus"}`, exit 1; adding `--typecheck-core` gives
`Specified(3)`, exit 0. The two additional witnesses and all twelve
executions are retained in `discarded-error-results.json`.

**Provenance and impact:** operand truncation is pre-existing. The new matcher
now rejects the pure-let mismatch, while the existing typechecker can erase
it and restore successful execution. This defeats the repair's stated
typing protection on a supported Core input route. No C-elaborator-produced
witness is claimed. It also falsifies the new record's unqualified claim at
`2026-09-20_match-pattern-arity-record.md:265–266` that a Core input with a
mismatched arity now fails typing.

**Before landing:** fail closed at the tuple-expression and tuple-producing
expression checks which can bypass the pattern rule; check both length
directions, nested tuples, and preservation of operands on a fitting input.
Include the actual `PElet`/`Elet` inference route in the regression evidence.
Retain the new pattern guard. Correct the record's claim to describe what is
actually enforced. The unchanged `Epar` tuple zip at `:1853` is another site
to assess when closing this class; the current finding's executable evidence
is for the tuple constructor and `Eunseq`.

## R2 — P2: other binding paths bypass the matcher; rewriting now changes the result

**At `14457f1a0`:** `frontend/model/core_run.lem:872–879` updates the ordinary
let environment directly with `update_env`; `core_aux.lem:2459–2462` still
zips tuple patterns and values without an arity check. In contrast,
`core_eval.lem:1007–1018` evaluates `PElet` through `select_case`, so it now
uses the repaired matcher.

Reproducer (`core-probes/let-mismatch.core`):

```text
proc main (): eff loaded integer :=
  let (a: integer, b: integer) = (1, 2, 3) in
    pure (Specified (a + b))
```

Use the same execution command as R1, with and without `--rewrite`.

| Tree | Default | Add `--rewrite` |
|---|---|---|
| Base `5407597d9` | `Specified(3)`, exit 0 | `Specified(3)`, exit 0 |
| Arity head `14457f1a0` | `Specified(3)`, exit 0 | `PElet: the pattern didn't match pe1`, exit 1 |

The rewriter's ordinary-let rule (`core_rewrite.lem:1122–1130`) converts this
`Elet` into a `PElet`; the two binding mechanisms now disagree. A nested
tuple reproduces the same change (`Specified(7)` versus the error). The
unchecked environment update is old; this particular rewrite/default
disagreement is newly observable with the matcher repair.

The safety argument used to exclude the remaining substitution helpers is
also false. The new record at `:269–271` and tray draft 45 at `:133–136` say
`subst_pattern_val` and a purported `subst_pattern_pexpr` run only after a
successful match. There is no `subst_pattern_pexpr` definition here. Actual
paths include:

* `to_pure` → `subst_pattern` (`core_aux.lem:1536–1546`);
* `pure_propagation2` → `subst_pattern` (`core_rewrite.lem:1187–1193`,
  `:1219–1225`);
* `subst_pattern` / `unsafe_subst_pattern` → `subst_pattern_val` on tuple
  components, without `match_pattern`.

The audit's `ArityAudit.lean` kernel-checks the concrete counterexample:
`match_pattern pair triple = none` while `subst_pattern_val pair triple body`
and both expression-substitution helpers substitute the prefix successfully.
These facts use the shipped definitions; no old matcher was reimplemented.

**Before landing:** give the other reachable tuple-binding paths an explicit,
consistent mismatch policy and establish the preconditions of the
substitution helpers, or guard them. A proved and enforced entry invariant
is also a possible solution; the present optional checker does not provide
it, as R1 demonstrates. Do not use the repaired matcher as a
dominance argument for functions that never call it. Correct the consumer
note/tray and add a charter erratum for the false premise. The intended
`select_case` behavior should remain `none`/fall-through, as the consumer
requested. These are malformed Core inputs, not evidence of a C regression;
the concern matters here because repairing behavior on such Core inputs is
the feature's purpose.

## N1 — P3: correct the remaining axiom and count claims

Tray draft 45 at line 190 still calls the new facts “axiom-free,” despite the
record's erratum saying this was corrected. The facts depend on `propext`;
`T1_anyFuel` uses the standard trio. The executable's final message at
`test/Unit/MatchPatternArityTest.lean:208` says the printed set is `[propext]`
“on each,” even though its own `#guard_msgs` pin for `T1_anyFuel` says otherwise.
The pins themselves are correct and this does not invalidate the proofs.
The record's “14 exes now” count also includes an exe absent from this
separate branch: there are 13 here. Correct the public assurance text.

## N2 — P3: the new enum failure row overlooks the oracle's parser rejection

At `e2fc391f2`, `scripts/failure_reach_register.txt:255` marks the new
`Implementation.typeof_enum` failure reachable and describes a Core-text
`is_signed_ity` query with an enum tag as a “both-crash pair by construction.”
It acknowledges that no fixture witnesses the claim. The assertion
overlooks a parser barrier: the fork's Core lexer has its enum token commented out
(`parsers/core/core_lexer.mll:20`), and its parser has no enum type arm.

The retained `register-route/enum-query.core` is:

```text
proc main (): eff loaded integer :=
  pure (Specified (if is_signed('enum E') then 1 else 0))
```

Both the freshly built fork and pristine driver reject this at parse time
with `unknown ctype 'enum'`, exit 1. Neither calls the enum lookup. Replacing
`enum E` with `signed int` executes successfully and returns `Specified(1)`.
Lean's `--parse-core` accepts both files; its parser explicitly documents
enum syntax as an extension over the oracle (`CoreParser.lean:514–525`).
That command only parses, so its success is not an execution result.

**Correction:** supply a genuine supported entry trace for the classification,
or qualify it as an unestablished route. Directly calling the model with a
missing enum key can fail, but that alone does not establish the claimed
Core-text pair. This finding does not assert that the failure leaf is
globally unreachable or that the enum repair introduces a C discrepancy.
The older `lookupEnum` row contains the same unsupported rationale and
should be corrected when repairing the new row.

## Range 1: closure of the earlier enum findings

The earlier audit is commit `880a8ead8`,
`lean_frontend/docs/2026-09-20_enum-premerge-audit.md`, over
`5407597d9..0e1968ffb`. This review checks its findings against the repair
delta, and examines the new code/tests/register and ledger changes.

| Earlier finding | Independent result on `e2fc391f2` |
|---|---|
| E1: callback captured the empty reader | Closed. Generated `annotate_expression_seeded` now calls `annotate_expression en tds ((annotate_block en tds) ret_ty) …`. Both callers pass return-type data. All ten seed definitions were reviewed for function-valued inputs; the other seeds do not transport an already reader-bound callback. |
| E2: optional-backend record literals omitted `enumDefs` | Closed. Extracted current web/BMC expressions compile against freshly built interfaces and preserve the input field. This is a constructor check, not a complete optional-backend dependency build. |
| E3: incomplete run misrepresented as green | Closed. The record corrects the old run and retains a report whose source, external inputs, and entire recorded artifact inventories are equal before/after; all 39 commands passed. Its six witness hashes match the committed files. This worker evidence is supplementary to the independent runs below. |
| E4: signedness normalized unsupported widths | Closed. `resolve_enum` only resolves `.Enum`; the existing scalar constructors are preserved. Fresh OCaml and Lean calls return `true`, `true`, `false` for signed 32, signed 128, unsigned 128. The unit proof controls and negative were reviewed and compiled. |

The complete previous 28-program focused set was replayed, plus four new
local/signed/nested/shadowed enum callback cases. Derived outcome: **24
successful Lean/fork agreements**, one matching UB observation, two
front-end rejection pairs, and five shared statement-expression/`sizeof`
internal failures already present on the base. All six former enum crashes
now execute successfully. The 24 successful cases also agree with freshly
built pristine Cerberus and GCC `-std=gnu11 -O0` (native exit values are
compared modulo 256; all these examples return small nonnegative values and
produce no output). No new discrepancy was found in this focused set. Comparing the original
28-case captures with this replay changes only the six repaired Lean crashes
and the absolute scratch path embedded in the two Lean rejection messages.

The GCC ledger changes are exactly **13 additions, zero removals, zero
changes to old rows** (2,001 → 2,014 data rows); 12 are `AGREE -`, one is
`AGREE O2_AGREE`. The immaculate baseline gains exactly the six callback
rows (75 → 81 data rows), with no old row altered or removed. The reader
consumer census is 22: 20 in `mem.lem`, two in `implementation.lem`.
The front-document and effect-erasure corrections appropriately remove the
enum registry from the boundary while leaving the digest boundary visible.

## What is sound in item 7

Both added guards check length equality before the unchanged folds. On a
fitting tuple, binding order and typed sub-patterns are preserved. A mismatch
returns `Nothing` in the matcher and the existing structured `MismatchExpected`
error in the pattern checker. The selector is unchanged and continues after
`Nothing`. Nested failure does not leak partial bindings.

The audit independently regenerated both targets. The OCaml changes from the
base are exactly `core_aux.ml` and `core_typing.ml`; the Lean model changes
are `Core_aux.lean`, `Core_typing.lean`, and the copied measure-proof source.
The measure theorem statement is byte-identical. Its proof rebuilt, and the
audit's kernel probe imports it from that build. The manifest's new typing
row and moved matcher row accurately describe these generated changes.

The focused Lean probe checks 196 flat/nested/typing/selector cases over
arities 0–6, kernel equations for empty and nested tuples, actual
`subst_sym_expr`/`subst_sym_pexpr` selector use, and a general equation for
the exact Boolean arity guard at any positive worker fuel. It also records
the remaining wrong typing behavior in R1. Compiling the branch's actual
new unit source against the clean base fails at T1a/T1b/T2 and their axiom
pins, demonstrating sensitivity to the old matcher.

Core-text replay on fresh fork/base/pristine engines reproduces the tray
witness in both default and typed modes, both mismatch directions, nested
patterns, fitting control, pure `case`, and no fallback. With no matching
arm the head reaches an existing internal-error path; it does not acquire
a successful result. The `Driver.can_advance` failure leaf is already
`REACHABLE` in `failure_reach_register.txt:239`; this witness does not
introduce a new failure leaf. The Lean CLI's `--parse-core` mode only
parses the standalone Core inputs used here. The Lean execution evidence
therefore comes from direct compiled-model probes.

## Independent builds, batteries, and retained evidence

| Audited head | Independent full run | Pristine tier-B counts |
|---|---|---|
| Enum `e2fc391f2` | 39/39 passed; 2026-09-21 22:20:15–23:48:40 UTC (88m25s) | 835 semantic agreements; 28 matching failures; 7 reviewed differences; 2 interface agreements |
| Arity `14457f1a0` | 39/39 passed; 2026-09-21 23:48:40–2026-09-22 01:17:50 UTC (89m10s) | 822 semantic agreements; 28 matching failures; 7 reviewed differences; 2 interface agreements |

Both reports certify complete tier selections on the exact clean heads.
For each run, the source identity, external inputs, and every artifact
identity recorded by the runner are equal before/after. Both GCC lanes
report zero regressions and zero improvements (2,014 enum-head cases;
2,001 arity-head cases). Each separate pristine `chvalid` row reports
four semantic agreements. The full batteries do not exercise the
counterexamples in R1/R2.

Both audit trees were regenerated through the project `scripts/ce`
environment, with `DUNE_CACHE=disabled`, forced Dune targets, all Lean roots
plus the driver rebuilt, and independent pristine oracles built locally.
Every Lean probe used the repository probe/cap mechanism, with an 8 GiB cap;
the build/battery cap was 32 GiB. One heavy build/battery ran at a time.
Only ignored scratch was written during the batteries. The advance
justification for the long standard corpus sweeps was stated before launch;
no long proof-search or term-grinding job was used.

The [retained evidence directory](2026-09-21_enum-repairs-and-match-pattern-arity-audit-evidence/README.md)
contains exact source inputs, reproduction
scripts, focused raw captures, generated-source excerpts, source/build
stamps, full runner reports, lane receipts, and checksums. The diagnostic
collectors record unsuccessful cases as well as successful ones; their
own exit code is not a substitute for inspecting each recorded engine
status and observation.

## Integration requirements

These branches overlap in five paths, contrary to the charter's “files are
disjoint” sentence. A `git merge-tree` dry computation (no branch movement)
reports conflicts in `lakefile.toml`, `test_unit.sh`, and
`fork_drift_manifest.txt`; `core_typing.lem` and the measure-proof file combine
textually. Retain both unit registrations and compose/recompute the typing
module's content/delta pins from the combined source. Do not pick either
branch's hash for the combined module. Rebase/integrate and re-gate the actual
landing head under the project's normal process. No merge or push was
performed by this audit.
