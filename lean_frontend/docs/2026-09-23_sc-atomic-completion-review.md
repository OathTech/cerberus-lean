# Remaining atomic interfaces and runtime configuration refusal

September 23, [AGENT], parent `f935305867eb621fd6a7ba422ad53bbe8c031eb2`.
Work under the [SC charter](2026-09-21_charter-sc-prototype.md).
**The component passes all 39 Tier A+B commands and the mandatory 864-case
three-engine comparison. The SC prototype remains incomplete.** SC-G06's
preprocessor path remains an open defect. [Retained evidence](2026-09-21_sc-prototype-evidence/atomic-completion/README.md)
includes failed predecessors and the exact comparison with the prior checkpoint.

## Implemented behavior

`kill_dependency` performs ordinary argument conversion, preserves the resulting
type without default argument promotions, and evaluates the argument once. Its
lowering adds no function boundary, scheduling point, fence or source-order
edge. Core currently carries no dependency relation and the SC request domain
excludes consume; this is the identity-value behavior in that existing setting.
A future dependency-aware executor must preserve the dependency cut explicitly.
The change does not implement weak-memory execution.

`uchar.h` exposes the existing least-width unsigned character carriers, and
`stdatomic.h` supplies `atomic_char16_t`, `atomic_char32_t` and `atomic_wchar_t`.
No Unicode conversion functions are added. The relevant primary references are
[N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf),
7.17.3.1, 7.17.6 and 7.28p2.

`atomic_is_lock_free` checks the existing generic atomic-pointer domain and
evaluates its pointer argument once. It does not load or validate the pointed-to
object. A reached query produces the typed
`Model_gap_atomic_lock_free_configuration`, retaining completed argument effects
and earlier independent faults. Null arguments follow the correction in
[DR465](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0465.html).
Dead calls and unevaluated `sizeof`/`_Generic` operands do not consume the missing
configuration. Both Core parsers preserve the diagnostic identity and source
locations. The internal constant-expression evaluator also transports a reached
typed gap rather than falling into its generic assertion.

The generic A-domain test is the existing `AilTypesAux.is_atomic` check. The
pin's `atomic_flag` is a plain structure with an atomic member, so that declared
type does not satisfy this check. This is a statement about the current type
representation, not a proof that every C implementation must reject such a query.
Its guaranteed flag operations do not license inventing a query value for an
arbitrary structure. Separate flag operations remain implemented. The broader
library-type questions in WG14 [1057](https://open-std.org/JTC1/SC22/WG14/issues/c23/issue1057.html)
and [1058](https://open-std.org/JTC1/SC22/WG14/issues/c23/issue1058.html) are open
C23 research context, not adopted changes to the reference.

All ten `ATOMIC_*_LOCK_FREE` definitions are byte-identical to the parent. Numeric
`#if` still silently consumes their missing markers as zero. This is **not a
complete SC-G06 guard** or a chosen zero-valued configuration. No division-by-zero
marker, suppressible-warning detector, header refusal or target value is adopted.
The preprocessing requirement in [DR458](https://www9.open-std.org/JTC1/SC22/WG14/issues/c11c17/issue0458.html)
remains a separate integration obligation.

## Evidence and its limits

- Both targets regenerate and compile using the normal build and local install.
  Build 1 exposed a missing OCaml token constructor; builds 2 and 3 pass all
  nine generation/build/install/stamp steps after the parser transport repair.
  Build 3 establishes the unchanged source used by full integration.
- Thirty-one actual C `kill_dependency` controls compare complete native/Lean
  outcomes, including exact UB locations, and paired byte journals. Supplemental
  builtin-versus-identity comparisons retain all native journal fields except
  locations between different source texts. Aggregate controls use a conditional
  rvalue, because a plain identity macro preserves an lvalue and reads only a
  selected member. Those two operational observations must not be conflated.
- Seventeen query runtime controls compare complete outcomes and byte prefixes:
  ten configuration gaps, five ordinary values, one prior division fault and
  one prior initializer error. The latter is an existing model defect, not a
  successful query. Five malformed query inputs and three malformed dependency
  calls have reviewed native constraints and exact Lean rejection locations;
  their differently formatted frontend diagnostics are not claimed byte-equal.
- Six actual C alias controls use the installed headers: type/size and
  init/fetch/load behavior agree for each alias. Two static-assert probes reach
  the existing `UB204_illtyped_Static_assert` classifier before evaluation,
  including the short-circuited call. The initial expectation for the latter
  failed and is retained; neither is evidence of mini-pipeline gap transport.
- A separate compiled control calls the actual internal constant-expression
  evaluator with an Ail query and its `sizeof` control. Both targets report the
  exact typed gap/location and the unevaluated value 1. This bypasses the earlier
  C syntax classification deliberately; it does not establish acceptance of
  those static-assert C programs. The Lean probe must be compiled because the
  existing digest external is unavailable to the interpreter.
- The existing paired Core controls now exercise all three gap identities:
  25 exact native/Lean groups, including retained writes, distinct unsequenced
  prefixes, failures during atomic update and prior UB. Parser controls pass
  323 Lean checks and 14 native transport checks. Existing generic gap laws
  rebuild; no new general correspondence theorem is claimed.
- One unchanged compiled lowering control and three isolated mutations pass:
  duplicating the dependency argument, skipping query argument effects and
  changing the gap identity each fail their specified witness. No production
  file is mutated by this instrument.

The paired byte projection retains occurrence/request/thread identities, source
annotations, allocation/lifetime metadata, storage/ranges and specified byte
bits. It omits the native pretty-printed type/value and source-location fields;
byte provenance and copy offsets are not serialized by this projection. Full
batch observations still include exact diagnostic locations. This is distinct
from the lossless logical-value key and its kernel laws.

Failures remain evidence: the original native recorder accidentally shadowed
its deterministic selector with a later module import; the corrected instrument
places the alias after imports. The original aggregate identity controls used
lvalues. The new Lean diagnostic had syntax/constructor/setup failures, and its
first internal-evaluator attempt hit an unavailable interpreter external. Parser
component attempt 1 used the wrong working directory; attempt 2 uses the owning
package. No failed attempt is relabeled a pass or omitted from retention.

## Existing defects discovered by the controls

`_Atomic(int*) x = 0` fails before the query. The unchanged declaration lowering
also misses narrowing and floating-to-integer initializer conversions. The
[upstream draft](upstream-tray/45-atomic-declaration-initializer-conversions.md)
records the pinned source and reproductions. Four ordinary pristine/fork
controls agree and three fail in both engines; failures are not completed
semantic agreement. The SC recorder preserves the pointer initialization's
model type error and prefix. No new concurrency UB or blanket atomic declaration
refusal has been introduced. SC-D05 records this separately from SC-G06.

## Validation protocol and resource justification

The drift manifest and freshness were reviewed after normal regeneration and
building. Sources were then frozen for the full 39-command Tier A+B ladder and
mandatory 864-case three-engine comparison. Every classification and complete
observation was compared with the value/metadata checkpoint; the discrepancy
inventory is unchanged. No baseline or observation projection was weakened.

[AGENT, advance justification] The previous full bounded corpus run took more
than an hour, largely in the observation-plant battery and existing libc
corpora. This slice touches shared typing, lowering and parser transport, so the
same full validation is required. Authorize that expected hour-plus aggregate
measurement run with the existing per-process limits, one heavy worker and an
8 GiB cap. This does not authorize proof grinding, heartbeat/recursion increases,
new corpus campaigns, changed pins or dependency installations.

After this component checkpoint, continue location/value/RF composition, full
HB and prefix-fault integration, the remaining precise boundary guards and the
public operational/C interface. Customer files remain strictly read-only.


## Completed integration and retained follow-up

The corrected full invocation passes all 39 selected commands with unchanged
source identity and no artifact issue. The 864-case comparison preserves every
prior case ID, complete decoded observation and classification, including the
same 40 existing Lean discrepancy/undecodable IDs. Matching failures remain
failures, not semantic agreement. No baseline or comparison was weakened.

The first full attempt is retained as incomplete. Its B8.2 kill plant correctly
failed because the invocation mistakenly raised the per-test cap to 8 GiB, so a
5 GiB plant survived. The owned run was interrupted and the complete selection
repeated with the standard 4 GiB per-test cap and the same 8 GiB outer worker
cap. No source fix or limit increase was used to obtain the passing result.

Independent drafts developed during the freeze are retained with their own
claim boundaries, source and failed attempts: lossless byte keys and actual
copy/lifetime observations; access grouping; call identity, per-branch scope
state and parameter-read witnesses; prefix fault timing; and preprocessor
observer research. They are not promoted by this atomic-interface checkpoint.
The [scope follow-up](2026-09-21_sc-prototype-evidence/atomic-completion/followup/call-scopes.md)
distinguishes internal Core arena completion from C program completion. The
[byte follow-up](2026-09-21_sc-prototype-evidence/atomic-completion/followup/byte-metadata.md)
corrects the earlier assumption that default lifetime end zaps pointer bytes.
The [prefix follow-up](2026-09-21_sc-prototype-evidence/atomic-completion/followup/prefix-faults.md)
shows why an interpretation finding must not hide a later independent Core fault.

Next, connect these components in the substantial location/value/RF/HB and
prefix-observation slice, finish the precise G02/G03/G07/G08 guards and G06
preprocessing refusal, then complete the public operational/C entry. A component
commit is not completion of the charter.
