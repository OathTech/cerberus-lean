# SC boundary inputs

Minimal inputs extracted from the prototype investigations. These are regression
inputs for integration, not passing public SC tests: the production classifier
is still incomplete. The [boundary register](../../../lean_frontend/docs/2026-09-22_sc-boundary-register.md)
owns each trigger and required classification. The
[roadmap](../../../lean_frontend/docs/2026-09-21_charter-sc-prototype.md) owns work.

The reference is Cerberus `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`.
Historical source excerpts, selected journals and commands are recoverable at
`03f7c5f32:lean_frontend/docs/2026-09-21_sc-prototype-evidence/`; repeated campaign
archives have deliberately been removed from the working tree. Selected traces
are not exhaustive outcome sets.

| Inputs | Meaning and controls |
|---|---|
| `g01` | Padded/unpadded CAS and representation comparison. Unspecified bytes require G01 after the completed reads; initialized representations do not. Atomic initialization races retain their separate classification. |
| `g02` | Whole-scalar/byte access, disjoint scalar representation bytes, separate array elements and structure members; scalar-race and join-order controls. Preserve actual source order and subobjects. A byte width or shared allocation alone is not an unsupported trigger. |
| `g03` | Ordered/parallel `fputc` and zero-length stream operations. Concurrent `fread` still touches FILE state. The `fwrite` investigations timed out; those inputs establish no reached gap. |
| `g04` | Abstract unspecified memory orders, discarded results, earlier argument UB and known invalid CAS orders. Preserve fault priority and completed arguments. |
| `g05` | Generic pointer fetch add/sub, dead calls, argument faults and ordinary pointer operator controls. Generic fetch is the recorded ambiguity; ordinary atomic pointer operators are not excluded. |
| `g06` | Runtime query arguments/null/dead/unevaluated controls and small preprocessing translation units. Numeric use of an absent lock-free marker must not silently become zero. Stringification, `defined`, and unevaluated branches are distinct. These preprocessing files need not contain `main`. |
| `g07` | Implicit and macro atomic reads without source sequencing; comma, actual function calls and ordinary-read controls. Failed Cmm thread well-formedness is a composition gap, not a C UB proof. |
| `g08` | Ordered/parallel registration and stream controls. Registration traces expose missing protection of shared library internals. Open/close inputs timed out and supply no completed verdict. |
| `d10`, `d12` | C memory-failure prefix and ordinary `umask` proxy-width mismatch. The latter faults before the later FS decoder boundary. |
| `d15` | Existing concrete atomic-allocation byte-access refusal. Retain upstream UB042 transport without claiming that the scalar example establishes the ISO atomic-member clause. |
| `d16` | Same-Core global initializers distinguishing a loaded value from a constructor. Core text transport loses that administrative distinction; driver counters must not define semantic correspondence or HB. |

D09/D10's direct filesystem transition controls already live in
`lean_frontend/test/Unit/FSBoundary.lean` and `memory/concrete/sc_controls/`.
D14's existing directory-stream discrepancy remains in the immaculate corpus;
it is not duplicated here. The FS operation/coverage map is in the
[effect inventory](../../../lean_frontend/docs/2026-09-21_sc-effect-inventory.md#filesystem-coverage-and-reached-failures).

For complete C inputs, use the actual C frontends with the required libc mode.
For G06 preprocessing controls, inspect preprocessing directly. For D16, supply
the same Core value to both engines. Do not infer success from a selected run,
component query, timeout, or the current completion-time checker placeholder.
