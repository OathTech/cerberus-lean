**Whole-project semantics audit — 2026-09-11**

Saved from the project-review conversation at the user's request. The audit
was read-only; saving this document is a subsequent documentation-only change.
The findings and test results below describe the audited revisions, not a new
validation run performed while saving the report.

| Repository | Audited revision |
|---|---|
| Cerberus Lean | `e30810be76e4150fa9bd8e2f0736282a30b6da30` |
| Lem Lean | `f6542f8e6860d12d4655e6648bc4c45dabd1d798` |
| Pinned pristine Cerberus upstream | `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` |
| Refined Cerberus, consulted for consumer requirements | `6be4b822b379f085233806fedb900db79d0bd453` |

Source links are relative to this document. Links into sibling repositories
assume the project workspace layout. Line anchors refer to the audited state.
Temporary probes and their raw outputs were removed at the end of the audit;
this document preserves the reported results and examples, not an archived
release receipt or a complete raw-evidence bundle.

Cerberus Lean is a substantial executable port with useful foundations for
downstream reasoning. Its shared Lem sources, explicit memory state, growing
collection of kernel-checked lemmas, and careful differential infrastructure
are real strengths.

However, I would currently treat it as a semantics for a **restricted Cerberus
configuration with known gaps**, rather than a generally faithful ISO C
foundation. I confirmed two end-to-end port discrepancies, several inherited
semantic and completeness problems, and important differences between the
logical meaning of some Lean definitions and their native execution.

For supporting Iris, the most urgent work is to make failures, ambient state,
admissibility conditions, and fuel guarantees precise. That work belongs in
the semantic provider without importing Iris or moving ownership reasoning
into this project.

This was a read-only audit of Cerberus Lean at `e30810be76`, Lem Lean at
`f6542f8e68`, and selected upstream sources pinned at `b9aeedcb4d`. I inspected
`refined-cerberus` only where it clarified what a downstream consumer needs.
All repositories remained unchanged during the audit, and I removed my
temporary probes.

**Scope and validation.** I examined the generation pipeline, handwritten
semantic implementations, frontend and Core interchange, concrete memory,
nondeterminism, failure and fuel handling, runtime libraries, proof interfaces,
and validation infrastructure. This is a system-wide engineering and semantic
audit, not an exhaustive proof of every definition.

The handwritten frontend contains 46 Lean files, approximately 17,700 lines.
The generated directory contains 216 files, approximately 57,100 lines,
including synchronized copies of those 46 handwritten files. Lem's consumed
runtime adds 35 Lean files.

I checked the existing binaries' source-freshness records before running
differential probes. The following results are from this audit, rather than
copied from planning documents:

| Test group | Files | Matching Defined/UB observations | Identical other errors | Other outcomes, excluded from semantic agreement |
|---|---:|---:|---:|---:|
| Minimal | 106 | 103 | 0 | 3 |
| Floating point | 69 | 69 | 0 | 0 |
| Debug | 90 | 86 | 0 | 4 |
| Coverage | 212 | 199 | 3 | 10 |
| Library-loaded execution | 12 | 12 | 0 | 0 |
| **Total** | **489** | **469** | **3** | **17** |

The first 477 files used `--nolibc`. The 12 library tests loaded the library
on both sides; I also checked the pinned Core dump against a newly printed
dump and checked the staged oracle library against its build artifact.
Comparisons retained complete batch output, including execution order and
multiplicity, and process exit status.

These comparisons used the **local OCaml fork versus Lean**. I inspected the
pristine pinned upstream source to distinguish inherited defects, but did not
rebuild and execute an independent pristine upstream oracle.

Additional checks passed:

- Handwritten/generated synchronization: all 46 copies matched.
- Totality, purity, forbidden-fuel-numeral, and live-`sorry` checks passed within their declared scopes.
- Observation-harness tests: 22 passed.
- Release-harness tests: 16 passed.
- The consumed `LemLibPmapLaws` elaborated under Cerberus Lean's toolchain.
- Targeted kernel probes confirmed both useful fuel/failure lemmas and the problematic equations discussed below.

I did not rerun the entire release ladder, a clean rebuild, all Lem backend
suites, or the full CN, Csmith, speclab, and libxml2 workloads.

**1. Highest priority: ordinary Lean values still represent failures that should stop computation.**

The most consequential design problem is the remaining use of pure functions
to represent abrupt failure.

[LemLib.lean](../../../lem-lean/lean-lib/LemLib.lean#L155) provides opaque,
inhabited values with native panic implementations. Ordinary `panic!` also has
a default-valued logical interpretation. Opacity can prevent unfolding a
failure value, but it cannot make evaluating that value an unavoidable effect.

I kernel-checked these representative equations:

```lean
theorem panic_is_default :
    (panic! "failure" : Nat) = 0 := rfl

theorem discarded_stop (n : Nat) :
    (failwithI (α := Nat) "failure", n).2 = n := rfl
```

The project already contains stronger generated examples involving discarded
bindings, arguments, projections, results, and callbacks in
[FailureMain.lean](../../tests/failure-probes/FailureMain.lean#L1).

This matters in two distinct ways:

- An OCaml computation may fail while the corresponding Lean expression can discard the failure and return normally.
- A theorem can correctly describe the Lean term while failing to justify the intended native failure behavior.

This is a semantic correspondence problem, not evidence that Lean's logic is
inconsistent.

Requiring `LEAN_ABORT_ON_PANIC=1` is useful for native execution, but does not
solve discarded computations or the logical interpretation. Similarly, "no
`sorry`" and "no unexpected axioms" do not establish equivalence between an
`implemented_by` implementation and its logical declaration.

There has been meaningful progress. [CerbFail.lean](../CerbFail.lean#L11) now
represents selected failures through the nondeterminism monad, and
[CerbFailProofs.lean](../CerbFailProofs.lean#L74) proves propagation through the
actual memory-to-driver pipeline. Those changes should be extended.

The current failure reachability register still contains 48 `REACHABLE` sites,
19 `UNKNOWN` sites, and 166 classified as `UNREACHABLE-BY-INVARIANT`. Those
classifications are useful audit information; they are not all proved
reachability exclusions.

**Recommended change:** represent reachable failure through an explicit result
or semantic effect. Where a helper is intentionally defined only on a valid
domain, provide a checked domain and prove that normal execution stays within
it. Prioritize failures inside callbacks, discarded intermediate results, and
parser alternatives.

Also give budget exhaustion, unsupported features, internal model failure, and
C undefined behavior distinct structural representations. Current distinctions
partly depend on special locations and messages inside a general error
constructor. Explicit constructors would make downstream statements
substantially clearer.

**2. Hidden enum and digest state remains an obstacle to compositional reasoning.**

Most semantic state is explicit, which is the right design. Two important
exceptions remain.

[CerberusImpl.lean](../CerberusImpl.lean#L55) stores enum information in an
`IO.Ref`, then exposes lookups and registration through apparently pure
functions. Their types do not describe the registry on which they depend.

[CerberusFresh.lean](../CerberusFresh.lean#L110) exposes the current
translation-unit digest through a pure interface backed by mutable native
state. The implementation needs `never_extract`, `noinline`, and an evaluation
barrier to prevent computations from moving across digest updates. The native
storage is a process global in [md5.c](../native/md5.c#L149).

Hashing a supplied string is a reasonable pure primitive. Reading the current
translation unit from mutable process state is a different operation.

I did not reproduce interference between simultaneous sessions. The confirmed
problem is structural: the public types cannot express session independence,
registry preservation, or dependence on the selected translation unit.

**Recommended change:** thread an explicit elaboration context containing enum
information, translation-unit identity, and fresh-name state. Keep any native
implementation behind an interface with a clear correspondence contract.

The recent replacement of fixed configuration reads with transparent
definitions in `CerbGlobal` demonstrates the benefit of removing unnecessary
ambient state. Continue that direction.

**3. Confirmed port bug: valid UTF-8 C source can produce unreadable Cabs JSON.**

I ran:

```c
int main(void) {
    return sizeof("é");
}
```

The OCaml driver returned `Specified(3)`. JSON export succeeded, but Lean
failed while reading the JSON with "containing non UTF-8 data."

The exporter represents literal fragments using raw OCaml strings. A valid
multibyte source character can become separate byte fragments that are
individually invalid UTF-8 JSON strings. See
[cabs_json.ml](../../backend/lean_export/cabs_json.ml#L115).

This exposes a live case beyond the "both engines fail" explanation in
[CabsImport.lean](../CabsImport.lean#L32).

There is also a broader runtime representation issue: OCaml strings are byte
sequences, whereas ordinary Lean string traversal operates on Unicode
characters. Lem's parity register still records open failures for
`p_str_bytes` and `p_str_escapes`.

**Recommended change:** establish a byte-preserving representation across the
entire boundary:

- C literal contents and modeled byte strings should preserve arbitrary bytes.
- JSON must encode those bytes unambiguously.
- Diagnostic text should remain explicitly Unicode text.
- Lem string operations must agree with the selected byte representation.

A JSON escaping fix is necessary, but does not by itself repair all string
operations. Test all 256 byte values, embedded NULs, multibyte source text,
escapes, and round trips through both exporters and runtime operations.

**4. Confirmed port bug: hexadecimal floating literals can overflow before scaling.**

[CerbFloat.parseHex](../CerbFloat.lean#L139) constructs an exact natural-number
mantissa, converts it to `Float`, and only then applies the binary exponent:

```lean
Float.scaleB (Float.ofNat mantissa) ...
```

That conversion can overflow even when the final literal denotes a small
finite value.

I generated a literal consisting of `0x1`, followed by 260 zeroes, followed by
`p-1040`. Its value is exactly 1. For a program returning whether that literal
equals `1.0`:

| Engine | Result |
|---|---|
| OCaml | `Specified(1)` |
| Lean | `Specified(0)` |

Both executions completed successfully. This is a wrong answer, rather than a
diagnostic difference.

The 69 existing floating-point tests all matched, illustrating the need for
adversarial conversion tests beyond ordinary arithmetic examples.

**Recommended change:** normalize the significand and exponent before
conversion and implement a well-specified rounding procedure. Cover long
significands, cancellation between mantissa size and exponent, subnormals,
rounding ties, overflow, underflow, and signed zero.

Separately, the selected implementation represents `float`, `double`, and
`long double` using the same eight-byte floating representation. That mirrors
the upstream concrete model's explicit hacks in
[CerberusImpl.lean](../CerberusImpl.lean#L200). It must be part of the advertised
target profile; users should not infer an ordinary host ABI from the integer
and pointer widths.

**5. Confirmed inherited bug: array bounds are ignored by cross-unit compatibility checking.**

The array arm in [ctype_aux.lem](../../frontend/model/ctype_aux.lem#L100)
contains:

```text
match (n1_opt, n1_opt)
```

It compares the first bound with itself, rather than comparing the two bounds.

I kernel-checked that the compatibility helper accepts `int[1]` and `int[2]`.
I also reproduced the consequence across translation units:

```c
/* a.c */
int f(int (*p)[1]) { return 7; }

/* b.c */
int f(int (*p)[2]);
int main(void) {
    int a[2] = {0, 0};
    return f(&a);
}
```

Both engines returned `Specified(7)`. The typo also exists in the pinned
pristine upstream source.

C11 requires compatible constant-bound array types to have equal bounds, and
declarations referring to the same function must have compatible types. This
example violates those requirements.
[N1570, §§6.7.6.2 and 6.2.7](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

**Recommended change:** fix the shared Lem definition and add independently
specified positive and negative compatibility tests. Differential agreement
cannot detect a defect shared by both engines.

The recent assumed-tag-pair implementation is nevertheless a substantial
improvement: recursive compatibility now terminates with hypothesis-free
measure proofs. Termination and correctness should be tracked separately; the
successful termination repair did not catch this pre-existing wrong answer.

**6. Recursive cross-unit values still fail after the compatibility termination repair.**

The existing [cross-unit node example](../../tests/failure-probes/cross_tu_node/node_a.c#L1)
passes a recursive structure by value between two translation units:

```c
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
```

The caller constructs a node and evaluates `ident(n).v`.

In the current binaries, both engines terminate with a mismatched-tag error.
The older comments saying that this example loops or overflows the stack are
stale. A corresponding pointer-based control example completed correctly.

The remaining failure occurs because
[Core member selection](../../frontend/model/core_eval.lem#L940) compares tag
identity where a value crossing translation units can carry a distinct
compatible tag.

**Recommended change:** make compatibility, call-boundary value transport, and
member selection agree on how compatible cross-unit types are represented.
Options include canonicalizing compatible tags or explicitly transporting
values across compatible representations.

The acceptance tests should include returned structures, passed structures,
nested structures, recursive pointer members, and incompatible structures that
must remain rejected. A compatibility termination theorem alone cannot
establish this end-to-end property.

**7. Frontend completeness is weaker than the coverage directory suggests.**

Two existing coverage examples demonstrate ordinary union initialization being
rejected by both engines:

- [Copying a union into an initializer](../../tests/coverage/union3/union3-004-union-copy.c#L1).
- [Initializing from a union-valued function call](../../tests/coverage/union3/union3-005-union-return.c#L1).

The upstream diagnostic reveals that initialization has descended into the
union's first member and is trying to initialize an integer from a union. The
shared implementation explicitly identifies this problem in
[desugaring_init.lem](../../frontend/model/desugaring_init.lem#L592).

Compatible union expressions are permitted as union initializers.
[N1570, §6.7.9](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

Bit-fields are also explicitly unsupported on the current frontend path; the
bit-field coverage example is rejected during desugaring.

These are completeness gaps rather than Lean-versus-OCaml discrepancies. A
file's presence in `tests/coverage` does not establish successful support for
its feature.

**Recommended change:** publish feature coverage by outcome: supported
execution, recognized UB, unsupported feature, frontend defect, and unresolved
oracle failure. Repair ordinary aggregate initialization before treating the
aggregate fragment as broadly usable.

Diagnostic quality also needs attention. Lean often reduces the upstream
explanation to "typechecking failed at …" or "desugaring failed at …" in
[Main.lean](../Main.lean#L545). Preserve structured causes and relevant types so
users can distinguish unsupported constructs from invalid programs.

**8. Upstream agreement does not establish ISO C correctness.**

The current configuration fixes the concrete memory model and default
switches. `--iso`, alternative switch sets, and concurrency configuration are
refused. This is a particular semantic profile.

I confirmed two examples where both engines return a defined result:

```c
int main(void) {
    int a = 0, b = 0;
    return &a < &b;
}
```

```c
int main(void) {
    float f = 1.0;
    return *(int *)&f;
}
```

Both returned `Specified(0)`.

The first performs a relational comparison between unrelated objects. The
second accesses an object through an incompatible effective type. Both have
undefined behavior under the relevant C11 rules.
[N1570, §§6.5.8 and 6.5](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

The implementation explains these results:

- [Pointer relationals](../CerbMem.lean#L2505) use concrete address ordering under the default configuration.
- [Loads](../CerbMem.lean#L2313) check several validity conditions but do not enforce the complete effective-type discipline.

The modeled `memcpy` also documents missing overlap enforcement. Overlap is
prohibited by the C library specification.
[N1570, §7.24.2.1](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)

Conversely, the targeted checks for signed overflow, division by zero,
unsequenced modification, negative quotient/remainder, and Boolean conversion
behaved correctly relative to the oracle.

**Recommended change:** state three separate contracts:

1. Correspondence with the pinned Cerberus configuration.
2. Intentional changes from that upstream behavior.
3. The ISO C fragment and implementation assumptions justified for users.

For downstream C verification, either provide a stricter profile or make the
restrictions required by the proof explicit. A Cerberus `Defined` result cannot
currently serve as an unrestricted ISO-definedness certificate.

My concrete standards checks used C11 draft N1570, matching the model's cited
clauses. This audit does not establish C23 coverage.

**9. Fuel handling has improved considerably, but its strongest advertised interpretation needs narrowing.**

The production runners now have kernel-visible equations. Exhaustion is
observable rather than silently becoming an empty behavior list. Fuel is
supplied through the caller's `LemFuel` parameter rather than hidden numeric
defaults.

[CerbNDFuelProofs.lean](../CerbNDFuelProofs.lean#L393) proves an important
property: once observation of a fixed computation completes without exhaustion,
increasing observer fuel preserves the complete result list. The proofs
preserve order, multiplicity, and state. Bind and lift stability results extend
this foundation.

However, increasing the observer budget for a fixed computation is different
from rebuilding the entire driver computation with another captured `LemFuel`
instance. The project correctly contains a
[counterexample demonstrating that distinction](../test/Unit/NDFuelStabilityTest.lean#L125).

The remaining register now contains **two workers**, `many_lemFuel` and
`many1_lemFuel`, not the larger numbers found in older documents. Their parser
exhaustion is represented by a value indistinguishable from ordinary parser
failure. Backtracking is therefore especially relevant.

**Recommended change:** retain the useful existing theorems, then prove the
corresponding property for the actual family of generated driver computations.
Make parser exhaustion structurally distinct from parse failure.

For `many` and `many1`, exposing the input as a recursion parameter and proving
consumption on successful iterations is a reasonable repair. A planning
restriction against changing the shared Lem body should not determine the
long-term semantic design.

**10. Some termination hypotheses are not established by frontend acceptance.**

The measured layout machinery and [CerbTagsWf](../CerbTagsWf.lean#L1) provide
useful formal vocabulary for acyclic tag environments. The missing link is a
general guarantee that accepted input satisfies those predicates.

I confirmed the documented counterexample:

```c
struct A {
    _Alignas(struct A) char c;
};
int main(void) {
    return sizeof(struct A);
}
```

The oracle timed out; Lean aborted on layout fuel exhaustion. The frontend has
accepted a type dependency that violates the intended acyclicity condition.

Likewise, arena-shape hypotheses such as `IsValuePexpr` and `IsPureExpr` are
useful, but comments identifying expected callers do not replace preservation
proofs.

**Recommended change:** introduce a checked semantic input boundary. It should
establish tag well-formedness, required expression shapes, supported
configuration, and other assumptions needed by measured helpers.

A practical path is a decidable checker returning evidence, followed by
preservation lemmas for the relevant transformations. This would let
downstream users rely on a compact certified interface instead of
reconstructing frontend invariants from comments.

**11. Public comparison instances are unsuitable as general reasoning interfaces.**

[CerbMem.lean](../CerbMem.lean#L251) exports placeholder instances including:

- Pointer and memory-value orderings that always return `.eq`.
- Allocation and memory-state Boolean equality that always return `false`.
- Memory-state ordering that always returns `.eq`.

I kernel-checked that `s == s` is false for every `MemState`.

The comments say these instances are not used as keys on current execution
paths. I found no demonstrated current execution discrepancy caused by them.
Nevertheless, exporting them as ordinary instances creates an avoidable hazard
for future semantic code and downstream consumers.

There are legitimate comparison distinctions elsewhere. Ctype equality ignores
annotations while ordering includes them; symbol comparisons also have
representation-specific conventions. Those require explicit equivalence
relations and comparator laws, rather than assuming every equality denotes
Lean equality.

**Recommended change:** remove or narrowly scope placeholder instances. Export
named comparisons with documented laws. Implement structural memory-value
comparison where appropriate, while accounting for floating-point behavior
such as NaN.

The current `memValueSize` machinery already provides a basis for total
structural definitions.

**12. The Core and libc interchange works on its pinned inputs, but is a fragile long-term boundary.**

The library loader is more carefully engineered than a simple textual import.
It verifies a pinned Core dump, re-elaborates 12 source translation units to
recover omitted metadata, and reconciles symbols before linking. All 12
library-loaded tests passed in this audit.

Nevertheless, [Main.loadLibc's documented contract](../Main.lean#L74) exposes
substantial complexity:

- The printed dump omits important metadata.
- Bodies and metadata come through different paths.
- Tags and functions are reconciled by names.
- Globals are reconciled by position.
- Same-named static functions are not faithfully distinguished by the printed representation alone.

[CoreParser](../CoreParser.lean#L2347) also interns names using a 64-bit hash.
Its collision check covers one parsed file, not all linked inputs together.
Name interning does not reproduce all upstream scope and duplicate-declaration
checks.

These are source-confirmed interface limitations, not additional reproduced
ordinary-C mismatches.

**Recommended change:** introduce a versioned, lossless Core interchange
containing the complete AST, symbol identities, metadata, implementation
profile, and source provenance. Prefer generated serialization over relying on
pretty-printer conventions.

For proof-producing consumers, identify the exact imported program artifact.
A theorem about a Lean Core value needs an explicit connection to the source
and configuration the user believes it represents.

Partial parsing itself need not block an operational semantics project. The
critical requirement is a reliable boundary between untrusted imported data
and the validated semantic object used in proofs.

**13. Nondeterminism is well handled for the concrete profile, but its API is broader than its implemented interpretation.**

The exhaustive runner carefully preserves upstream branch ordering and
multiplicity. This is a significant strength: merely comparing sets or the
first successful result would miss real differences.

The runner does not implement general constraint checking. Its justification
relies on properties of the concrete model's producers: integer comparisons
resolve concretely, and the relevant branch constraints are empty. Supporting
lemmas and call-site analysis make that credible for the intended path.

However, the generic runner type also permits computations containing
arbitrary guards and branches. Downstream clients must not infer a general
symbolic interpretation from that type.

Similarly, `--first` selects a fixed branch policy. It does not reproduce
OCaml's random selection and is not generally interchangeable with taking the
first printed exhaustive result.

**Recommended change:** specify admissibility for runner inputs, or
parameterize constraint interpretation. Prove the concrete driver satisfies
that condition. Keep trace-selection policy explicit in both APIs and tests.

For Iris support, expose operational facts about actual reductions and
primitive actions. A small-step view can be defined from the existing
implementation and related to its runner; it need not become a competing
semantics.

**14. Filesystem and concurrency support need explicit boundaries.**

`CerbFS` is a deliberately limited in-memory model, whereas the OCaml
implementation uses SibylFS. Explicitly refusing unsupported operations is
preferable to returning misleading successful results.

Two issues remain:

- Refusals frequently use the pure-panic mechanism discussed above.
- The claimed exact supported subset has qualifications. For example, [CerbFS's own operation table](../CerbFS.lean#L1) records that directory paths are not distinguished from missing files for some operations.

This needs an input/state restriction or a better path model before "every
served operation matches" becomes a robust contract.

Concurrency is outside the implemented profile.
[CerbConcurrency.statically_satisfied](../CerbConcurrency.lean#L20) returns
`true`, and the CLI rejects concurrency configuration. The presence of
concurrency-related generated modules does not establish SC or C11 concurrency
support.

**Recommended change:** make supported external operations and execution modes
explicit capabilities. Refuse unsupported capabilities structurally. Broaden
filesystem or concurrency semantics after the failure and state contracts are
dependable.

I would not make concurrency the next major milestone simply because a
planning document places it next.

**15. Lem Lean is a useful foundation, but backend translation remains part of the assurance gap.**

Several runtime choices are well motivated:

- Preserving Pmap/Pset behavior avoids accidentally changing traversal order and representative selection.
- [LemLibPmapLaws](../../../lem-lean/lean-lib/LemLibPmapLaws.lean#L351) provides real well-formedness and lookup-after-insert laws.
- Tail-recursive runtime replacements have accompanying equivalence proofs.
- Generated measures and separately checked sufficiency obligations provide a productive route from executable recursion to usable equations.
- Unsupported facilities are often rejected during generation instead of being silently accepted.

The remaining concerns are concentrated:

- Byte-string representation is unfinished.
- Abrupt-failure translation is not generally faithful.
- Map/set laws cover only part of the API consumers may need.
- The backend is a large collection of interacting transformations without a general translation-correctness theorem.
- State, reader, fuel, closure, and callback transformations need interaction tests, not merely isolated examples.

The parity register also contains intentional departures from OCaml machine
limitations, such as unbounded integer conversions. Those should not
automatically be "fixed" to reproduce incidental OCaml overflow. The relevant
contract must distinguish Lem's intended semantics from limitations of one
executable target.

Cerberus consumes the pinned runtime under Lean 4.32.2 while Lem's standalone
runtime toolchain names 4.28.0. The law module elaborated under the consumer
toolchain in this audit, but both configurations should be explicit CI
targets.

**Recommended change:** prioritize byte and failure semantics, then extend
laws according to actual consumer operations—removal, union, folds, membership,
and extensional reasoning. Maintain small backend counterexamples for
combinations of effects and transformations.

**16. Validation is strong at detecting regression, but its claims need clearer limits.**

The source-freshness checks, library-content checks, observation parser,
cancellation tests, and refusal to treat incomplete release subsets as full
certification are valuable. This is infrastructure worth preserving.

The main limitation is what differential testing can establish:

- Both engines can share a wrong answer.
- Both can reject valid C.
- An oracle crash provides no positive semantic evidence.
- A test may exercise only one constrained configuration.
- A native execution comparison does not establish the meaning of the corresponding Lean term.

The newly reproduced byte and floating-point discrepancies also show that
historical "zero discrepancy" language is too broad.

The speclab families provide useful independent expected behavior for selected
functions. They remain bounded validation, not a general correctness theorem
connecting the complete C frontend to the model.

**Recommended change:** retain separate evidence categories for upstream
correspondence, independent language requirements, logical properties,
native/logical correspondence, and supported-feature coverage.

Documentation should distinguish current contracts from historical records.
Specific stale statements include the recursive-node failure mode, older
fuel-pending counts, and the byte-import "both fail" explanation. Long
historical comments are currently making it harder to identify the active
invariant.

**What Cerberus Lean should provide to Iris consumers.** The provider does not
need Iris dependencies, ghost state, ownership predicates, or
weakest-precondition rules. It should provide dependable operational
definitions and reusable facts about them.

The highest-value provider interface would contain:

| Provider guarantee | Benefit to downstream reasoning |
|---|---|
| Explicit configuration and elaboration context | Theorems describe all inputs affecting behavior |
| Validated program and state invariants | Consumers receive established hypotheses |
| Structural failure and exhaustion outcomes | Safety statements cannot accidentally discard failures |
| Primitive memory equations and preservation lemmas | Proofs follow the actual implementation |
| Byte read/write and disjointness laws | Consumers can build separation arguments |
| Allocation, liveness, provenance, and metadata laws | Ownership accounts for the complete memory model |
| Driver-family fuel refinement | Bounded execution supports meaningful semantic claims |
| Runner/reduction correspondence | Adequacy connects to the canonical operational semantics |

Some useful provider-level facts already exist downstream. For example,
[Heap.lean](../../../refined-cerberus/cerberus-heaplang/CerberusHeapLang/Heap.lean#L308)
proves byte-map update and read-after-write properties about `CerbMem` itself.
Generalizing those into Cerberus Lean would reduce duplicated implementation
knowledge while leaving Iris-specific ownership reasoning downstream.

Frame properties must account for allocation liveness, provenance, union
metadata, and function-pointer encoding where relevant. Byte-map disjointness
alone is not a complete memory abstraction.

**Suggested implementation order.** I recommend the following sequence, with
concrete completion criteria:

| Priority | Work | Completion criterion |
|---|---|---|
| **Immediate repairs** | Byte-preserving Cabs import; hexadecimal literal conversion; array-bound compatibility | Reproductions above pass, with independent expected results and neighboring negative cases |
| **Highest structural priority** | Typed failure propagation; distinct exhaustion and unsupported outcomes | Reachable failures cannot become normal results through projection, callbacks, mapping, or backtracking |
| **Next** | Explicit enum/digest context; remove placeholder public instances | Semantic dependencies appear in types; session independence and comparison contracts are stated |
| **Next** | Checked input invariants and parser progress | Accepted semantic objects carry the hypotheses required by measured helpers |
| **Next** | Cross-unit aggregate transport and union initialization | Ordinary aggregate examples execute correctly; incompatible cases remain rejected |
| **Next** | Provider memory laws and whole-driver fuel refinement | A small downstream proof uses published interfaces without unfolding implementation internals |
| **Then** | Lossless Core interchange and improved diagnostics | Imported artifacts preserve identities and metadata; errors retain their causes |
| **Then** | Broader ISO profiles, filesystem support, and concurrency | Each extension has explicit semantics, independent tests, and preservation obligations |

Alongside these changes, maintain a short current-status document identifying
the supported C fragment, target representation, memory model, switches,
library scope, known inherited defects, intentional divergences, and proof
guarantees. Generate counts and check results where possible.

The next convincing milestone would be a restricted C verification profile
whose accepted programs have checked invariants, whose failures cannot
disappear, whose behavior does not depend on hidden process state, and whose
operational laws support a downstream Iris proof through a stable provider
API.
