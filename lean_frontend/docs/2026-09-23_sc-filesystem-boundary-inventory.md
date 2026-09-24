# Checked filesystem boundary inventory

**Historical technical record.** Current work order, status and acceptance are
owned solely by the [SC execution roadmap](2026-09-21_charter-sc-prototype.md).
Old next-step, freeze, proof-count and campaign instructions below are retired.
Unique source findings are retained only until their C1 extraction.


[AGENT, 2026-09-23] This inventory supplements SC-D07 and SC-D09–14 in the
[live register](2026-09-22_sc-boundary-register.md). The
[repair record](2026-09-23_sc-filesystem-repair-work.md) and
[retained evidence](2026-09-21_sc-prototype-evidence/filesystem-repair/README.md)
record validation, failed attempts and the exact supported domain.

The checked entry returns ordinary errno separately from a stopped result. All
stopped results preserve a typed fault and last-defined filesystem state. Driver
keeps that receipt separately from its ordinary committed filesystem state; no
Core completion, errno write or step increment occurs on a filesystem fault.
An earlier Core/memory fault keeps its own constructor and completed effects.
None of the filesystem special constructors constitutes an ISO C UB verdict.

## Upstream-selected open specials (SC-D07)

The following conditions contribute possible outcomes to the pinned ordered
check composition. A row is reached only when that outcome is actually selected
by the original wrapper; flags alone are not an early-refusal test. Path errors,
rights, other flags and permissions can change the selected result. The paired
30-case and1,608-case open checks exercise this ordering. Production open always
receives an effective mode: the wrapper supplies0777 if omitted, so the source's
missing-mode FIXME branch is inactive in this interface.

| Trigger in selected open checks | Native special kind | Pinned source |
|---|---|---|
| Directory with O_TRUNC | Implementation_defined | `sibylfs/src/fs_spec.lem:3068` |
| Directory with O_EXEC | Unspecified | `sibylfs/src/fs_spec.lem:3073` |
| Regular file with O_SEARCH | Unspecified | `sibylfs/src/fs_spec.lem:3084` |
| O_EXCL without O_CREAT | Undefined | `sibylfs/src/fs_spec.lem:3017` |
| O_TRUNC without O_RDWR/O_WRONLY | Undefined | `sibylfs/src/fs_spec.lem:3026` |
| Not exactly one decoded file access mode | Undefined | `sibylfs/src/fs_spec.lem:3033` |
| Creation permissions outside the allowed12bits after logical word conversion | Undefined | `sibylfs/src/fs_spec.lem:3000` |

All seven retain their exact upstream reason and TAU phase. `OS_special` has no
successor state; the receipt is the state before that failing transition. Do
not roll back prior operations or invent an after-state. Removal requires a
reviewed change in the pinned reference contract and corresponding controls;
changing the model failure into errno or success is not a local port fix.

## Other deliberate upstream boundaries

- SC-D09: `run_umask` passes RV_file_perm to return_nat, which cannot decode it.
  Its mask update and OS_RETURN have already completed. The receipt retains that
  updated state and raw return; no successful old-mask return is invented.
- SC-D10: the exact source failure in `list_array.lem:180` when a requested source
  slice exceeds supplied bytes. Preserve reached phase/state and check priority;
  EBADF or negative-offset EINVAL may prevent it. No blanket length guard.
- SC-D12: ordinary C umask's header/proxy width mismatch causes an earlier memory
  load fault. That existing constructor survives; it is not reclassified as the
  later filesystem decoder failure. The inner-argument proxy remains separately
  unvalidated by that ordinary-C control.

- SC-D14: the existing directory-stream C proxy control (Z2-F-04) reaches an
  internal native store-type mismatch. Lean reaches its missing opendir coverage
  first. Both observations remain distinct; the full error is deliberately
  pinned in the immaculate baseline. Port directory streams and independently
  review the native proxy failure; neither supports a guessed result or ISO UB.

Arbitrary native Failure, host integer overflow, allocation failure, and timeout
are not converted into these model faults. Logical32bit conversion follows the
existing LemLib ruling, not the OCaml host integer range.

## Available-guidance port gaps (SC-D07 and SC-D11)

These are acknowledged missing implementations, never passing support:

| Reached entry / state | Missing operation or representation | Resolution |
|---|---|---|
| mkdir, rmdir, chdir | Directory transitions and path/cwd state | Port pinned directory state and operation/error selection |
| chmod, chown | Permission/ownership-changing transitions | Port actual changes and their later observations; the reduced state already stores file modes, despite historical diagnostic wording |
| link, symlink, readlink | Hard-link inode identity and symbolic-link resolution | Port pinned link state and operations |
| stat, lstat | Complete native stat fields and symlink behavior | Port actual metadata, preserving store_stat's memory/commit behavior |
| opendir, readdir, rewinddir, closedir | Directory streams and cursors | Port stream handles/positions; original rewinddir ignores ordinary errno only |
| unlink of a file with an open descriptor | Inode retention after name removal | Preserve live open descriptions through unlink |
| rename/replacement involving a file with open descriptors | Inode identity and open descriptions across name changes | Port source/destination inode identity, including replacement |
| A manually supplied non-root cwd reaches open/truncate/unlink/rename | Non-root path resolution absent from this reduced state | Port directory/cwd semantics; this state is not produced by current successful chdir |
| Whole FsState ordering | Correspondence to native full filesystem-state ordering | Supply reviewed order/correspondence; the inherited always-equal result is replaced by explicit refusal |

Root-directory descriptors0–2, descriptor reuse, rights, normal direct-root
file open/read/write/pread/pwrite/close/lseek, truncate, and the reviewed closed-
file unlink/rename domain are implemented and tested. A successful call in that
reduced domain does not assert full SibylFS coverage. The placeholder fs_state
printer is not an identity or a serialization of the retained state.

Some inherited runtime refusal strings describe the earlier implementation
(e.g. chmod's missing permission state). The current missing transition and
resolution above are authoritative; no success or errno is substituted for it.

## Protocol failures, not language exclusions

Native checked transitions report empty transition/result sets with their phase.
Lean reports missing contents/modes after a successful resolution, empty check
results, or a supposedly successful operation with an incompatible resolution.
These diagnose broken state invariants or adapter assumptions. They are retained
as FsFault.protocol; they are not newly forbidden C constructs or new ISO UB.
Repair a reachable protocol defect rather than adding a runtime precondition.
The Driver's normal result continuation is unchanged, including memory failures
before the old filesystem commit point and independent ND alternatives.

## Trace/instrument finding (SC-D13)

The previous native recorder used Random.int despite its first_smt2 filename;
Lean used the first alternative. With matched first selection and identical
original C paths, all four small recorded-C controls have identical effect
metadata. Their original differences were4/7/3 cleanup storage/range entries and
28 parallel entries. Full native-to-native captures retain every field and show
that changing this selector accounts for the observed differences. No semantics
was changed. This resolves that finite instrument discrepancy, not all traces.

The old raw_journal_equal label is misleading: the existing paired metadata
projection omits rendered location/type/value. It retains occurrence/request/
thread/scope IDs, source annotations, ranges, byte bits, provenance and copy
indices. The exact projection and original failed comparison remain archived.
Two larger C-libc recordings remain incomplete at their unchanged20second bound.
