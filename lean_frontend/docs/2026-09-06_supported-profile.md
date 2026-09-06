# Supported profile, risk map and release obligations

2026-09-06 [AGENT]. This describes the validation-foundations candidate's
evidence and limits. It supersedes unconditional overview claims of one
semantics “by construction” or entirely absent ambient state. Source heads
and finished/unrun gates belong to the
[delivery record](2026-09-06_validation-foundations-delivery.md).
The historical functional candidate completed 32 Tier A+B commands, both
affected reporting measurements and the cold provider/probe recipes. The
[first audit](2026-09-06_validation-foundations-premerge-audit.md) nevertheless
found four P1 and seven P2 defects in instruments and evidence attribution.
The [repair record](2026-09-06_validation-foundations-audit-repairs.md) tracks
the corrections and candidate reruns. Review acceptance and the semantic,
adoption and release exits below remain separate obligations.

## Claims that can currently be made

| Layer | Supported statement | Limit |
|---|---|---|
| Source/reference | Fork OCaml and Lean share the recorded Lem input; seams have explicit reference implementations and drift gates. The pristine execution lane uses upstream Lem and pristine Cerberus in an owned prefix. | Shared OCaml host/toolchain dependencies remain. Neither shared source nor three-way testing proves ISO C conformance. |
| Executable observations | The migrated lanes retain actual status and raw byte streams, reject malformed/incomplete success and compare every printed semantic field according to a declared sequence/set projection. | The printer omits some internal state/error output and carries no total outcome count. GCC's integer-exit projection and litmus's independent reference-set projection are intentionally weaker than full observations. |
| Logical definitions | The checked execution slice has no `partial` definitions, no added axiom declarations and gate-checked proof cones. The cold consumer proves a real singleton successful `drive` result and a delivered map law. | Total functions can still denote opaque/sentinel values at failure. Logical/native agreement and general completion are not established by axiom counts. |
| Runtime boundary | Fresh supply and tag environments are explicit; the default configuration switches became transparent definitions. | Enum registration, native digest and opaque value-equality seams remain on the declared boundary; mutable native implementations are not proved equal to their pure signatures. |
| Domain/configuration | Mainline is the default sequential concrete-memory configuration with recorded LP64/libc assumptions. Fixtures and entry-specific theorem hypotheses are explicit. | General weak memory, CHERI, full filesystem behavior, all C extensions and arbitrary malformed Core are not certified. Documentation alone does not enforce these exclusions. |
| Fuel | Measured sufficiency theorems cover 54 of 81 registered workers, seven under hypotheses; 13 have checked zero-case kills; six lie outside the execution dependency closure; eight remain pending. | The 13 zero cases are not general propagation theorems. The eight pending workers and frontend partiality prevent a universal successful-completion claim. |
| Consumer interface | A fresh provider checkout generates/builds all three Lake packages and supports the provider-owned proof under explicit fixture/map invariants. | No refined-cerberus re-pin, build or adoption evidence is supplied by this agent. The small OCaml client checks a representative package entry, not the whole API. |
| Concurrency | A separate S0–S7 SC prototype exists. Its repaired instrument checks actual statuses, full engine observations and an independent coarse reference set separately. | It is not landed or customer-certified. Mixed-size access overlap, SeqRMW behavior, the provider agreement theorem and current-mainline integration remain obligations. |

There is no currently enforced broad C fragment for which every listed
failure, layout, byte and opaque-boundary condition is known to hold.
Known wrong-answer inputs require repair or a real checked guard before a
release advertises support for their domain. A green baseline that preserves
a known failure is regression evidence, not evidence of agreement on that row.

## Change since the 2026-08-31 baseline

The semantics-first split correctly separated the semantics product from the
parked verification effort. It did not establish a stable customer-ready
release. Subsequent work introduced quantified fuel, sufficiency proofs,
delivered map laws, more faithful memory/pointer behavior, explicit fresh
supply and transparent default configuration definitions. The prototype
added SC execution and, at S7, restored measured original `apply_tree`
bodies and initialization edges.

Validation-foundations adds observation/status discipline across the active
callers, actual-entry adversarial tests, independent pristine execution,
whole-file source pins, the executable ladder/CI entry, and the cold client.
It also exposes wider failure obligations: five measured strictness erasures,
a logical/native difference under a mapped projection, a corrected site
census, and incomplete historical evidence. These are improvements in what
can be checked and claimed; they do not erase the underlying semantic debt.

## Ranked open findings and next actions

Owners below are responsibilities, not messages or new task assignments.
No responsibility for a provider theorem is transferred to refined-cerberus.

| ID / priority | Input or precise obligation; impact | Owner and next action |
|---|---|---|
| VF-1 / release-critical | `tests/failure-probes/discarded_failures.lem`: five forms fail in OCaml and succeed in Lean; mapped projection also separates kernel and native behavior. Consumers cannot use unrestricted value equations as failure correspondence. | Lem + Cerberus maintainers: review the [correspondence proposal](2026-09-06_failure-census-and-correspondence.md), then implement a bounded strict-result vertical slice and propagation proofs. |
| VF-2 / release-critical | `LemLib` string representation; `p_str_bytes` and Unicode `p_str_escapes` expected failures. Exact observation decoding exposes bytes; it does not fix Unicode/byte semantics. | Lem maintainer, then Cerberus provider: implement the reviewed byte representation, regenerate/re-pin together and require parity without those XFAILs. |
| VF-3 / release-critical | `CerberusImpl.lean:55` enum registry reads, native digest in `CerberusFresh`, and `CerbMem` value-equality boundary. Opaque declarations do not determine the runtime state used by native calls. | Cerberus provider: thread or otherwise model the required state; supply kernel contracts or explicitly scoped trusted-boundary claims and reentrancy evidence. |
| VF-4 / release-critical | Seven memory-monad arms and corrected generated inventory; ordinary model error/UB is not the same outcome as deliberate fail-stop. `hack`/`finalize` return pure values. | Cerberus + Lem maintainers: migrate by actual result channel after vocabulary review; retain failure-time output/state and prove propagation through the delivered entry. |
| VF-5 / profile blocker | Layout measure theorems assume `CerbTagsWf.Acyclic`; the `_Alignas(struct A)` counterexample defeats treating frontend acceptance as that theorem. | Cerberus provider: preserve/minimize the source case, prove an enforced admissibility condition or guard/reject; prepare the upstream report. |
| VF-6 / completion blocker | Cross-TU recursive-pointer compatibility reaches the compatibility trio; by-value acyclicity does not bound deep-reference recursion and the reference can diverge. | Cerberus provider: isolate the precise supported compatibility domain or design a reviewed algorithmic fix, preserving the reference classification. |
| VF-7 / proof blocker | Eight pending fuel workers, 13 zero-case-only proofs, parser progress and failure-dependent `to_pure(s)` bounds. | Cerberus/Lem maintainers: prove completion/propagation under explicit hypotheses; no default exposure or arbitrary fuel increase. |
| CR-2 / concurrency blocker | Prototype `CerbConcurrency` represents locations by pointers and can miss different-sized overlapping accesses. A documented SC label does not exclude the bad input dynamically. | Cerberus provider: add a failing overlap case, repair range reasoning or enforce a conservative checked fragment with positive acceptance witnesses. |
| CR-3 / concurrency blocker | Prototype SeqRMW sequencing over-approximates allowed behavior. | Cerberus provider: reduce a counterexample, repair sequencing or refuse that construct explicitly in the supported profile; plant the guard. |
| CR-4 / concurrency blocker | Equality of full sequential/SC states is false because SC records events. Six sequential identity lemmas do not imply observer agreement. | Cerberus provider: prove the accepted observation agreement obligation with `epar_free`, fragment/initial-state conditions and explicit fuel; discuss any necessary change to the accepted contract. |
| VF-8 / inherited defects | Null pointer arithmetic and other immaculate crash/refusal cases retain exact inputs. Agreement on crashing behavior does not supply a C result. | Cerberus provider: preserve three-way evidence, distinguish deliberate model failure from host artifacts, and keep precise upstream drafts. |
| VF-9 / evidence limit | Twelve historical audit logs are missing; original checksums and available files are separately retained. | Cerberus provider: use [the corrected inventory](2026-09-05_whole-project-audit-evidence/README.md); new reproductions carry new dates and hashes. |
| VF-10 / release exit | Final Tier A+B passed 32/32, C1/C4 recorded all prescribed rows, and cold provider/failure evidence completed on identified sources. C2/C3 remain unrun by ownership; customer adoption and successful second-review acceptance remain outstanding. | Preserve the delivered gates/artifacts; customer agent owns adoption; operator decides audit/landing and unavailable evidence. Certification remains incomplete. |
| VF-12 / reporting findings | [Current C4 evidence](2026-09-06_ci-reporting-results.md): one libc UB-location loss, three explicit filesystem refusals and two Lean timeouts among 2,186 rows. | Provider owns location retention (registered Z1-A1), future supported filesystem behavior and identified completion/cost investigation. These six rows are not agreements; 56 historical movements are recorded without blanket causal attribution to this charter. |
| VF-11 / observation limit | Batch Error omits internal stderr and the protocol has no declared outcome count; equal printed records do not prove full-state/exploration equality. | Provider: design a versioned richer protocol if a customer claim needs those fields; keep present comparison projections explicit. |

The full census is the per-site source-obligation register for remaining pure
failures. Unless a specific witness or theorem is supplied, reachability is
unresolved; a dependency edge alone is not labelled C-reachable, and a comment
alone is not labelled proved-unreachable. The generic next action is to prove
the site's precondition or propagate its faithful result, with the provider
responsible for execution seams and Lem for translation/runtime mechanisms.

## Next work and landing decisions

Prefer the proposed [scoped concurrency integration charter](2026-09-06_concurrency-integration-charter.md)
next, if the repaired instruments and final review support it. Its enforced
domain and agreement proof are the acceptance boundary. If that proof needs
the strict-failure transform first, identify the concrete path/precondition
that blocks it and authorize a bounded failure slice before integration.
Do not substitute a weaker unreviewed theorem or a documentation-only guard.

The final review decides the larger failure design, next charter, fresh audit
scope/scale and readiness of each exact branch. Merges remain ff-only with
per-merge operator sign-off after audit; base movement requires revalidation.
Pushing is separate. No final release certification or landing is inferred
from this profile, the cold fixture theorem, or a subset runner report.
