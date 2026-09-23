# SC-D07 filesystem findings and required repairs

[AGENT, September 23] Direct calls to the pinned SibylFS wrapper and production
CerbFS expose inherited port defects while preparing actual SC stream controls.
The upstream semantics is available. These are required repairs, not new ISO
ambiguities, caller UB, or accepted restrictions on concurrency. Production
CerbFS is unchanged by the prefix component. Its historical assertion that
every served operation matches SibylFS is contradicted by these observations.

The [baseline](2026-09-21_sc-prototype-evidence/prefix-integration/followup/filesystem-baseline.md),
[source review](2026-09-21_sc-prototype-evidence/prefix-integration/followup/filesystem-source.md),
and [unadopted proposal](2026-09-21_sc-prototype-evidence/prefix-integration/followup/filesystem-proposal.md)
provide the source locations and individual cases. Exact sources, commands,
channels, failed attempts and frozen source identities are retained in the
prefix component archive under `sc-fs-standard-draft/`.

| Trigger / cases | Observed native behavior and port defect | Required repair |
|---|---|---|
| Reuse after close: 5, 15 | Lowest free descriptor is reused; Lean's monotone counter returns a different number | Allocate the least currently unused descriptor |
| Wrong access rights: 7, 8 | Readonly write and writeonly read return EBADF; Lean succeeds | Retain actual open-description rights and check them before buffer operations |
| Initial descriptors and reuse: 0–4, 10–14, 27 | Native 0/1/2 share dummy FID 0 and its offset; Lean refuses supported close/seek/reuse operations | Represent aliases, preserve errors without updates, distinguish a reused descriptor from the original dummy |
| Oversized buffer with invalid descriptor/rights: 28–31 | Native returns EBADF before buffer processing; Lean refuses too early | Preserve the reference check order |
| Invalid fd and seek command: 22 | Native selects EINVAL; Lean selects EBADF | Mirror the pinned wrapper's selection among allowed errors |
| Invalid modes or permissions: 17, 18, 25, 26 | Native selects a named special failure; Lean returns descriptor 3 | Preserve the precise upstream special outcome, never success or C UB |
| Missing parent/root path: 19, 24 | Native returns ENOENT/EISDIR; Lean creates a file | Port path resolution and composed open checks |
| Existing invalid modes / EXCL without create: 20, 21 | Native selects a special failure or ENOENT; Lean reaches a different blanket refusal | Preserve argument combinations and model-specific outcome identity |

Cases 6, 9, 12, 16, 23 are completed agreement controls. Derived over the 32 unique
paired cases: 5 exact completions, 7 different completed answers, and 20 cases
with a refusal/failure on at least one side. Four of those 20 are native special
failures incorrectly completed by Lean. Two refusals are not counted as
agreement. The earlier parallel ftell case still has no final Lean journal: its
opaque filesystem refusal escapes the ordinary ND result. Failure transport
and actual C stream controls remain part of the repair.

An additional thirty-case **native-only** open matrix checks path, mode and
permission combinations. There is no blanket path-first or flag-first rule:
missing parent plus invalid modes/permissions returns ENOENT; missing final
component with trailing slash and those invalid arguments selects the extra-
permission-bits special. Existing file/.. returns ENOTDIR, so lexical path
normalization cannot erase traversal checks. Exactly two leading slashes are
supported by the selected POSIX architecture; no new refusal is justified.

The isolated descriptor proposal completes 24 exact paired cases and has twelve
kernel laws over its allocation, rights, offset and preservation behavior. It
is not adopted, and it does not fix the separately recorded open/path/permission
cases. Promotion requires those repairs, an accurate coverage account, installed
regressions, actual C stream controls and the normal integration checks.

Host integer overflow is separate from deliberate model failures; no artificial
Lean integer bound is authorized. File descriptors, open descriptions and FILE
objects are distinct identities. Filesystem repairs do not implement stream
locks or supply new C happens-before edges. SC-G03 remains an independent
missing-synchronization boundary.
