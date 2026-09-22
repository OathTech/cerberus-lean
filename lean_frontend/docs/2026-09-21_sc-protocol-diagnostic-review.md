# SC protocol: seven exact upstream diagnostic differences

2026-09-21, [AGENT]. The first protocol full validation ran all 39 selected
commands with unchanged sources and no artifact issues; 38 passed. B10.1
failed on the seven cases below. Its failed status remains in the original
report. These are existing upstream failure paths, not new successful C runs.

| Case | Renamed backtrace frame |
|---|---|
| `minimal/097-null-ptr-arith.undef.c` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |
| `immaculate/nolibc/zd-z2fl03-nan-to-int` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |
| `immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |
| `immaculate/nolibc/zd-z2m02-device-funptr-call` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |
| `immaculate/libc/s4b-memcmp-hugesize` | `Driver.perform_memop_request2` → `perform_memop_with` |
| `immaculate/libc/zd-z2m01-aligned-alloc-zero-zero` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |
| `immaculate/libc/zd-z2m01-aligned-alloc-zero` | `Core_reduction.step_ctx.(fun)` → `step_ctx_with.(fun)` |

For every pair the original exit is 125 on both engines and stdout is
byte-identical. Applying the existing approved diagnostic projection, then
replacing exactly the one listed frame in the pristine diagnostic, yields the
fork diagnostic byte-for-byte. This check was used only for review; it is not
added to the comparison instrument. In particular, exception payloads and
function/file names remain meaningful and globally compared.

The shared refactoring moves the existing sequential reduction/memop bodies
into helpers with optional SC context and completion receipts. Their disabled
wrappers retain sequential execution. The changed frame therefore has a direct
source explanation. Register seven `diagnostic-text` entries binding both full
signatures: status, original stdout hash and the already-defined diagnostic
hash. The register does not admit other crashes, new payloads or other frame
changes. The seven earlier semantic/discrepancy entries are unchanged.

[Exact review and captures](2026-09-21_sc-prototype-evidence/protocol-diagnostics/review.json)
retain the original commands, statuses and hashes. Numbered folders alongside
the review contain the original stdout/stderr/status/command bytes for each
pair; `files.json` inventories them. These cases remain reviewed differences,
never successful semantic agreement or evidence of SC support. No fixture
baseline, observation codec or global diagnostic projection was changed.

The manifest comment restoration is separately recorded there. It restores
287 lost historical comment lines while preserving the complete non-comment
payload. Fresh checks on September 22 pass: all 16 Tier A commands, the
859-case three-engine pristine gate, 53 comparator plant rows and fork-drift.
The Lean column retains exactly the same 40 differing/undecodable IDs as the
observer checkpoint. The original full run remains recorded as failed, 38/39.
[Repair evidence](2026-09-21_sc-prototype-evidence/protocol/integration/README.md)
retains both reports and verifies identical executable/runtime inputs for the
unaffected Tier B results; it does not claim a newly green full run.
