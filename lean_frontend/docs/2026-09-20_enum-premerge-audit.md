# Enum arc — pre-merge audit

**Recommendation: REQUEST CHANGES.** The enum-as-program-data design is a useful improvement, and its main plumbing and kernel-visible lookup work. The current branch nevertheless introduces a reproducible C-pipeline regression in desugar-time typing, changes the signedness function's domain, and leaves two in-tree Core-file constructors ill-typed. Its claim that the mandatory full battery passed also misinterprets a failed source-integrity condition.

[AGENT: Codex], audit started 2026-09-20. Reviewed **`5407597d9eeba0259d65b728e86a860ad4614ab3..0e1968ffb6d4736e60a7b53bee2fb3eb2c336304`**, the three E-A commits on `arc/program-data-parameters`: implementation `3ad477462`, seven witnesses `70408e483`, reconciliation/record `0e1968ffb`. This is **E-A alone**. The digest remains unchanged; its deferral is recorded in the [arc record](2026-09-20_program-data-parameters-EA-DA-record.md) §3.1/§3.7. This audit does not re-audit the already-landed Lem S0.5/S1.5 implementation.

Work ran in isolated `audit/enum-premerge-20260920` and `audit/enum-base-20260920` worktrees. Both sides were regenerated and rebuilt; the pristine oracle was built independently. No implementation, expectation, original worktree or shared opam installation was changed. [Evidence and reproduction](2026-09-20_enum-premerge-audit-evidence/README.md).

## Findings

### E1 — P1: a typing callback captures the empty enum map outside the seed

Locations: `frontend/model/cabs_to_ail.lem:1761` (also the analogous callback construction at 2414); `frontend/model/mini_pipeline.lem:298–304`.

The seed wrapper receives an **already constructed** `GenTyping.annotate_block` callback. Reader lifting supplies that callback with the outer desugar computation's readers, including its initially empty enum map. Seeding `annotate_expression` with the current sigma's map cannot change the environment of the callback passed to it.

The generated call makes the two environments explicit (formatting shortened):

```lean
annotate_expression_seeded
  (Lem_Map.fromList sigm.enum_definitions) desugar_time_tagDefs
  ((annotate_block _lemReader_enum_definitions _lemReader_tagDefs) (some ret_ty))
  sigm gamm CTXsizeof d_e
```

Inside the wrapper the callback is simply forwarded to `annotate_expression en tds`. When a statement expression requires an enum/integer compatibility decision inside the block, the callback consults the wrong map.

Small reproducer:

```c
enum E { A, B };
int main(void) {
    typeof(({ enum E e = A; unsigned int *p = &e; p; })) x = 0;
    return x == 0;
}
```

| Engine/build | Result |
|---|---|
| Fresh base OCaml and Lean | `Specified(1)`, exit 0 |
| Fresh head OCaml | `Specified(1)`, exit 0 |
| Independently built pristine OCaml | `Specified(1)`, exit 0 |
| GCC, GNU C11, `-O0` | Compiles; program exits 1 |
| **Fresh head Lean** | **Exit 134**, `Ocaml_implementation.typeof_enum: 'Symbol(19, SD_Id("E"))' was not registered` |

Six variants reproduce the new failure: pointer initialization, assignment, conditional combination, equality, function argument checking and return checking inside `typeof` statement expressions. All six complete successfully on both fresh base engines and pristine; GCC also accepts and returns the corresponding value. Fifteen other focused pairs agree: 14 successful value executions, including ordinary enum arithmetic and simple `typeof` controls, and one matching undefined-behavior observation. This is a regression, not an existing unsupported-C case or a difference in error formatting.

These are GNU C constructs, consistent with the branch's parser and existing semantics. GCC documents statement expressions and their use with `typeof`. [Statement expressions](https://gcc.gnu.org/onlinedocs/gcc/Statement-Exprs.html), [typeof](https://gcc.gnu.org/onlinedocs/gcc/Typeof.html).

**Required before landing:** construct the block-typing callback inside the same seeded extent as the expression typer. For example, pass the return-type option into a seeded helper that constructs `GenTyping.annotate_block` itself. Review other higher-order arguments at seed boundaries. Retain a successful callback-dependent C witness and a control, comparing complete captures/statuses on both engines; do not accept the new panic as a pinned outcome.

The seven new d3 cases do not exercise this callback path. `EnumDataTest`'s seed-value pin checks the value passed to `is_signed_ity`; it does not call a production `reader_seed` helper. It therefore cannot detect this defect. The record §4.2 and baseline header also incorrectly claim S-7 has no parser-accepted witness: they tried `__typeof__`, whereas this parser recognizes **`typeof`**. Even the simple `typeof(e + 1) y` succeeds on both engines.

The analogous `sizeof(({ ... }))` probes hit an older, shared “Statement expressions are only allowed inside functions” failure, including the integer-only control. I do **not** count those as newly introduced failures; their captures are retained to make that distinction checkable.

### E2 — P2: the new required Core-file field breaks two remaining constructors

Locations: the field addition at `frontend/model/core.lem:421–425`; existing constructors `backend/web/instance.ml:334–346` and `backend/bmc/bmc_utils.ml:413–426`.

Both full record literals omit `enumDefs`. Unlike some historical OCaml-backend literals mentioned in record W9, these two contain all the base's fields. I extracted their actual record expressions, supplied identity stand-ins for the unchanged transformation helpers, and type-checked them against the freshly built interfaces. Condensed results (complete diagnostics are retained in the evidence):

```text
web_record base 0
web_record head 2: Error: Some record fields are undefined: enumDefs
bmc_record base 0
bmc_record head 2: Error: Some record fields are undefined: enumDefs
```

This is an isolated constructor check, not a claim that the complete optional web/BMC toolchains were built. The standard driver build and full battery do not cover these targets. “Not compiler-forced by the selected build” is not evidence that a constructor remains valid after adding a required field.

**Required:** preserve `file.enumDefs`/`file1.enumDefs` at these sites and check the remaining full literals for the same new omission. Do not substitute an empty map when rewriting an existing file. No redesign or optional-backend feature work is needed for this repair.

### E3 — P2: the full-run record wrongly dismisses a source-integrity failure

Locations: record §9.4, lines 803–806 and its concluding claim that the mandatory gate condition is met; `scripts/release.py:397–408,421–423` (unchanged instrument).

The quoted run says:

```text
full: incomplete; 39/39 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
```

The record explains this as the eight files being uncommitted and “incomplete” being ordinary wording for non-tier obligations. Both explanations are wrong for the runner's **tier-run status**. It compares the complete before/after source and external-input identities; a stable dirty tree compares equal. It returns nonzero when that comparison fails. The separate `Release certification: incomplete: reporting/adoption/audit exits require separate evidence` sentence is a different field.

A small local fixture using the actual `release.source_identity` confirms this: an unchanged uncommitted edit gives equality; changing its bytes gives inequality. The original `report.json` and raw run logs are absent from the named run directory and were not retained with the record—§9.6 explicitly deletes `.tmp/eada/`—so this audit cannot identify which source or external input changed during that historical run. I do not infer that semantics changed; the required identity evidence is absent.

**Required:** correct the historical explanation, label that run incomplete, and retain the report and sufficient identity/log evidence for a source-stable run of the final repaired tree. A fresh audit run is independent evidence, not a repair of the historical claim. The fresh verification result below states exactly what this audit observed.

### E4 — P2: full alias normalization changes the signedness predicate's domain

Locations: `frontend/model/implementation.lem:102–104`; charter D2, line 13; the mirrored function at `ocaml_frontend/ocaml_implementation.ml:79–94`.

The new Lean wrapper calls `normalise_integerType` before `is_signed_ity_norm`. OCaml's `Common.is_signed_ity` resolves **only an enum** before inspecting the constructor; `Signed _` returns true and `Unsigned _` returns false without consulting the width-alias table. The explicit OCaml target representation bypasses the new Lem body, so the wrapper introduces a new Lean-only failure on unsupported aliases.

Direct calls using the freshly built interfaces establish the difference:

| Argument | BASE Lean | BASE / HEAD OCaml | HEAD generated Lean wrapper |
|---|---|---|---|
| `Signed (IntN_t 32)` | `true` | `true` | `true` |
| `Signed (IntN_t 128)` | `true` | `true` | Abort, exit 134 |
| `Unsigned (IntN_t 128)` | `false` | `false` | Abort, exit 134 |

The head diagnostic is `DefaultImpl.type_alias_map has no alias for an N-family width of 128`. OCaml probes call the shipped `AilTypesAux.is_signed_ity` alias, linked against each build; Lean probes call the old target representation or the new generated wrapper, respectively, under `lean_probe.sh`. This is a **function-level regression**, not an additional demonstrated successful-C-program regression: I have not established a C entry path that performs this query without first rejecting the unsupported width elsewhere. The source does expose the 128-bit constructors through `builtins.lem`, and the predicate itself previously had these answers.

**Required:** preserve the signedness predicate's original domain by resolving an enum through the map while leaving non-enum constructors alone. Full alias normalization remains appropriate for the size/alignment operations that already perform it. Add a direct signedness control for an unsupported-width constructor beside the ordinary-type and enum controls, and record an erratum to charter D2's blanket “same for `is_signed_ity`” rule. This is a flaw in the prescribed normalization rule, not merely failure to follow the charter.

## Documentation and boundary corrections

These should accompany the repairs, especially because the digest phase no longer provides an imminent documentation close-out:

- `lean_frontend/README.md:14`, `DESIGN.md:96` and `VALIDATION.md:1041` still list the enum registry as a remaining ambient/opaque seam. Update the enum portion for E-A, while keeping the digest boundary explicit. The old effect-erasure page should record that its enum half is retired, without falsely retiring the digest half.
- Rewrite the record's status paragraph around its final state; it still says “IN PROGRESS,” row 1 red, and “Nothing is committed past the charter.” Keep the earlier stops as dated history.
- Correct the S-7 “no accepted witness” claim and the seed-test description (E1). The source census has **22 reader-consumer declarations: 20 in `mem.lem`, two in `implementation.lem`**, not the final record's 18. `Main.lean:521` also calls `enum_definitions` the second reader while listing it first.
- Tighten the consumer note to the generated signatures. Its claim that `Core_typing.*` became reader-taking contradicts its own W13 and the generated tree; the enum field does not make those definitions read the enum map. Its short `sizeofCtype tds (enum s)` example omits the new enum argument. Do not require clients to guess which part of the note is current.

## Design and implementation assessment

The selected representation is appropriate: the desugarer derives compatible types from tag definitions, sigma and Core files carry them, linking merges the maps, and the entry points pass the relevant program data. The desugar-time seed pattern is necessary because the state grows during a TU. E1 is a repairable closure-construction error in that pattern; it does not justify returning to an effect-erased registry. D2's uniform normalization rule needs the narrower treatment of signedness in E4.

The lookup compares symbols by digest and number, matching the previous registry's key semantics. The shared compatible-type rule retains the existing signed/unsigned-int choice. Runtime memory operations thread the map through layout, serialization and reconstruction, and preserve original member types. The external `--call` path passes the linked map and agrees with its C wrapper in the focused enum test. Two multi-TU examples—including distinct signedness under the same enum spelling, and an enum-containing struct shared across TUs—agree in both input orders.

The proof changes inspected are reader-parameter threading. A code comparison after removing the newly introduced reader binders/arguments and comments leaves each of the seven changed sufficiency-proof modules identical to the base; this is a review aid, not a theorem of semantic equivalence. The fresh all-roots build and hardened fuel-forms gate compile the carriers. The reviewed fuel-hypothesis register is byte-identical to the base; the fuel/address-space exemplar remains quantified over fuel and top. `EnumDataTest` establishes kernel-visible enum lookup/layout at its named test maps; it does not prove the whole C frontend's enum-data correspondence.

The native digest implementation, symbol source, pristine-difference register and hand-written copy manifest are unchanged. The immaculate baseline adds exactly seven rows and changes/removes no existing row. The four wrappers preserve their old OCaml target representations; this keeps the OCaml operations unchanged, but does not establish that each new Lean wrapper preserves its original domain (E4). Fresh generated OCaml differs in eleven files, consistent with the new fields, pure helpers and seeded call sites.

## Fresh verification

The fresh standard battery completed at **2026-09-21 01:03:04 UTC**, on the exact reviewed HEAD. It started at 2026-09-20 23:36:38 UTC and took **5,185.3 seconds (86 minutes 25 seconds)**, derived from the report timestamps. Runner exit: **0**. Verbatim summary:

```text
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The derived tier counts are **16/16 Tier A and 23/23 Tier B**, all passed. The source and external-input identities match before/after, and the entire recorded artifact inventory is also identical, including both engine binaries, Lem compiler and runtime checkout. No overrides or artifact-inventory issues were recorded.

Selected results: 13 unit executables passed; fixture/call-point verification passed 127 checks; all 93 harness-entry-point plants passed. The GCC lane processed 2,008 inputs with zero baseline regressions (the seven new enum cases were reported as new, agreeing cases outside its existing ledger). The pristine Tier B corpus passed with **829 semantic agreements, 28 matching failures, seven reviewed differences and two interface agreements**; its separate libxml2 lane had **4/4 semantic agreement**. Those failure/difference classes are retained as such, not counted as semantic agreement.

This fresh run supplies source-stable evidence for the existing suite at this HEAD. It does not cover the newly discovered callback path or restore the signedness predicate's old domain; the focused evidence below is why the recommendation remains request changes.

Focused verification:

- 28 C programs on both freshly built head engines: **15 full-observation agreements (14 value executions and one matching undefined-behavior observation), six new Lean-only aborts (E1), seven rejection/internal-failure probes**. Undefined behavior, rejections and internal failures are not counted as successful value executions.
- 13 relevant programs replayed on fresh base OCaml, fresh base Lean and independently built pristine OCaml; the six regressions are successful controls on all three. Eight GCC compile/run controls also completed.
- Six additional integration pairs (two multi-TU programs in both orders, plain `typeof` arithmetic, enum function/global execution) agree; the enum `--call f --call-args -1` run agrees with its wrapper.
- Two actual record expressions compile against the base and fail against the head with the missing-field error (E2).
- Three signedness arguments on each fresh base/head OCaml and Lean implementation: the supported-width control agrees, while the two unsupported-width queries newly abort only in head Lean (E4). These small probes reused built artifacts while the full corpus lane ran; no further package build was dispatched.
- Original implementation worktrees left unchanged. Reproduction scripts, raw focused captures, input files and build identities are retained with the audit.

Before a merge ask, repair E1/E2/E4, correct E3 and the boundary documentation, add the callback witness and signedness controls, then regenerate/rebuild and re-gate the **final repaired head** with stable source identities. Request a delta audit of those repairs. Do not move the consumer's pin on the strength of the current green sample alone.
