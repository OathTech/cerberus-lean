# SC-D15: atomic-allocation representation access reports UB042

[AGENT, September 23] The existing concrete object model refuses selected byte
loads/stores into an atomic scalar before the atomic-source query is reached.
This is a retained model outcome, not a new race, successful atomic read, or
confirmed ISO classification. No semantics change is introduced by this review.

`member-boundary-2` runs two unchanged-source controls through pinned pristine,
fork OCaml and Lean. Each declares a global `_Atomic(unsigned int) x`; main
loads or stores `((unsigned char *)&x)[1]`. All three engines exit 1 with the
same full decoded `UB042_access_atomic_structUnion_member` observation. The
native tools also print the existing two allocation/range diagnostics; their
raw stderr is retained. This tool-stream difference was already declared by
Z2-M-17, whose old fixture accesses a member of an atomic struct.

The native `is_atomic_member_access` function is byte-identical in pristine and
the fork (`memory/concrete/impl_mem.ml:773–790`). Its condition tests every
allocation with an atomic declared type, without first requiring struct/union.
The access must have the allocation's base, full size and equal type, or the
helper returns true. `Mem_common.undefinedFromMem_error` maps AtomicMemberof to
UB042 (`frontend/model/mem_common.lem:302–303`); the Lean helper mirrors the same
condition (`CerbMem.lean:2526`). Source excerpts and file hashes are retained.

In the unchecked SC recorder, a local atomic initialization followed by the
same byte store stops with this earlier UB042. A proposed subsequent atomic
load or restoring whole store is never reached. `partial-c-2` keeps exact
instrument erasure for both refusals and two completing controls: a whole
atomic-source load and an ordinary ordered byte update. `partial-c-1` failed its
expectation that the partial atomic store would complete; this is retained and
corrected, not counted as evidence for a reached mixed-source atomic load.
`member-boundary-1` expected the long UB description instead of the actual short
identifier; its failed assertion is also retained.

The [selected C11 draft](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
was rechecked on September 23. Section 6.5.2.3 paragraph 5 addresses atomic
structure/union members. Sections 6.2.6.1 paragraph 4 and 6.5 paragraph 7 provide
object-representation and character-access rules. Section 6.2.5 paragraph 27
also permits atomic representation differences. The scalar reproducer does not
meet the structure/union description. These clauses motivate a scope review;
they do not by themselves settle the entire atomic representation composition.
No substitute success value or new ISO UB rule is selected here.

Policy: preserve the pinned refusal and its original state/effect prefix, and
identify it as this concrete-model boundary in any correspondence claim. Do not
replace it with an atomic RF diagnostic or use it to infer that every ordinary
representation operation is forbidden. Removal requires a pinned/reviewed
resolution of the concrete atomic-allocation check and the applicable atomic
representation semantics, followed by paired C controls. The public SC checker
remains pending; this draft does not implement a new guard or change defaults.

The [boundary register](2026-09-22_sc-boundary-register.md) records SC-D15.
All cited attempts and captures are retained in the [spawn/HB component
evidence](2026-09-21_sc-prototype-evidence/spawn-hb/README.md).
