# Supported profile and announcement scope

Checked 2026-09-24 against Cerberus `603c9b69bd056cbffeca8a669bc3510a4349f882`
and Lem `6b20bfd02de924d078725efa96c6675115b8b17a`. Baseline inventories
at Cerberus `e9f9d049f`, cleanup changes and the exact rerun set are recorded in
[the remediation record](docs/2026-09-24_public-readiness-remediation.md) and
[the closure record](docs/2026-09-24_public-readiness-closure.md).
This is the current profile; the dated September 6 profile is history.

[AGENT] The announcement can describe an early executable Lean port of the
sequential Cerberus semantics and a general experimental Lem Lean backend.
It should name the limits below. It should not claim full C support,
universal OCaml equivalence, stable APIs or complete release certification.

[USER 2026-09-24]: “We have recently reached the point where our semantics for Cerberus in Lean were accepted by our upstream customer working on reasoning about Cerberus.” This records reported customer acceptance;
it is not a new independent measurement of a downstream checkout.

| Surface | Present evidence | Limit |
|---|---|---|
| Model and observations | Shared Lem input; fork OCaml versus Lean differential lanes; separately pinned pristine-upstream comparisons. `scripts/LADDER.md` defines the lanes and VALIDATION describes their projections. | Printed observations omit some internal state. Shared source and finite tests do not prove general correspondence or ISO C conformance. A registered failure/skip is not an agreement. |
| Execution totality | `scripts/check_exec_totality.sh` is enforced by `scripts/test_unit.sh`; kernel execution cones contain no partial definitions. | Frontend partiality remains. A total function may return an error, kill or opaque failure value; successful completion is not universal. |
| Axioms and native boundary | `check_theorem_axioms.sh`, `check_sorry_token.sh` and `check_exec_purity.sh` check the actual generated, hand-written and consumed LemLib surfaces and pinned boundaries. | No added axiom declarations does not prove native implementations equal their pure signatures. Source censuses and selected theorem-cone checks have distinct scopes (VALIDATION). |
| Fuel | `check_fuel_forms.sh`: 81 workers, comprising 62 measured (12 under hypotheses), 13 checked zero-case kills, six outside the execution closure, zero pending (derived from the registered forms at the baseline pin). | General successor-case propagation and completion monotonicity are not delivered by Lem (TODO 13). Measured stability is not a proof that the sentinel is never reached. Layout acyclicity remains a theorem hypothesis, not a universally established frontend invariant. |
| Program data | Enum compatible types and tag environments are explicit readers; execution symbol digest is `core_run_state.sym_digest`, passed through the driver entries. | The frontend digest/native MD5 seam remains. Reader seeds do not re-seed already-constructed closures; seed positions follow global reader order. |
| Runtime failures and representation | Failure-site and observation gates register known behavior; native harnesses use `LEAN_ABORT_ON_PANIC=1`. | Pure unused failure expressions can be erased. Lem strings use Unicode scalars rather than OCaml bytes; four Lem parity XFAILs remain (two string cases, two deliberate numeric differences). |
| Domain | Default sequential concrete-memory configuration, recorded LP64/libc assumptions, explicit fuel and address-space parameters. | Concurrency/weak memory is not implemented by this profile: `CerbConcurrency` contains stubs, and excluded CMM operations have unsupported markers. Filesystem operations are bounded by `CerbFS` refusals; debug stubs remain. General CHERI, all C extensions and arbitrary malformed Core are not certified. |

There is no enforced broad C fragment for which every failure, byte,
layout and native-boundary precondition is proved. Consumers must state
entry-specific hypotheses and use the current definitions, not infer a
universal theorem from a green differential baseline.

The minimal baseline contains 113 rows: 90 MATCH, 18 UB_MATCH and five
CERB_SKIP (derived from `scripts/exec_baseline.txt`, 2026-09-24 at the
baseline pin). The pristine register has seven `shared-model-fix` case
rows, including two pairs of allocator witnesses; it does not identify
seven independent defects. Full historical ladder/reporting runs keep
their original dates and source pins. The initial MUST checkpoint reran row 1
and six named fast differential lanes; the closure also checks multi-TU,
the multi-TU tray, address-space and immaculate lanes, as recorded above.

Remaining work is tracked in [TODO.md](TODO.md). Concurrency prototypes
and the archived reasoning effort are records, not offered product
features. The successor reasoning project is `cerberus-sl`; the older
`refined-cerberus` checkout was retired on 2026-09-16. Source: [USER 2026-09-16]
"cerberus-sl is our main upstream customer at the moment. I retired refined-cerberus (it got too messy)."
([charter record](docs/2026-09-16_charter-allocator-soundness-address-bound.md),
checked 2026-09-24 at `e9f9d049f`; closure F6).
