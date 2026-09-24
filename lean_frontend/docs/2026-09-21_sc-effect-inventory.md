# SC prototype: effect inventory at the implementation base

This is a coverage/source specification, not a work queue. Use the
[SC execution roadmap](2026-09-21_charter-sc-prototype.md) for current status and
execution order. The original line references are from September 21; each row
states an obligation, not a claim that its producer/checker is still unimplemented.


The original source inventory is at `5407597d9eeba0259d65b728e86a860ad4614ab3`;
line numbers below describe that tree. Primitive observation and much execution
machinery now exist. Their complete connection to public SC checking remains
open under roadmap C2/C3. This table does not maintain a second status ledger.

## Common obligations

The selected object-model instance is the existing concrete default used by the
OCaml/Lean matched mode. This does not add restrictions to its C programs.
Existing configuration/model omissions remain existing omissions; another
memory-model implementation must not silently return an empty concurrency
effect stream. The interface is `frontend/model/mem.lem`, mirrored by
`ocaml_frontend/memory_model.ml`; the implementations are
`memory/concrete/impl_mem.ml` and `lean_frontend/CerbMem.lean`.

For every row, preserve the exact returned value, checks, memory metadata and
failure-time state of these implementations. `Nondeterminism.nd_bind` propagates
the state returned with a killed action; a successful prefix is not rolled back.
`Driver.liftMem` uses `ND.liftND` and therefore observes state at nondeterministic
nodes as well as success/failure. Extracting effects only in the successful
continuation would lose effects before a fault. State differences alone would
lose reads and equal-value stores.

The implemented observation boundary records primitive completed accesses and
lifetime changes at the memory implementation, with actor and source-order
context supplied by Core/driver. Observation itself does not change scheduling
or duplicate byte reconstruction. Separately enabled SC helper suspension does
permit interruption between primitive effects within a request; ordinary
sequential execution retains the original grouping. The actual policy, atomic
exclusions and filesystem ownership are described in the
[operational contract](2026-09-21_sc-operational-contract.md#helper-scheduling-policy).
Its concurrent justification is separate from sequential erasure. Source order
must be carried through helper requests and consumed by the completed checker.

In the table, `D`, `F`, `M`, and `L` mean `frontend/model/driver.lem`,
`frontend/model/formatted.lem`, `memory/concrete/impl_mem.ml`, and
`lean_frontend/CerbMem.lean`. "Test" names a required scenario, not a completed
test. Cmm scalar predicates are not a complete oracle for the rows involving
representation, dynamic allocation, or hidden helper accesses.

## Access and lifetime paths

| ID / source | Effects and result | Ordering / failure obligations | Observation point and required test |
|---|---|---|---|
| E01 `D:692`, `M:1560`, `L:2419` load | Checked typed read, byte/provenance reconstruction, union/member checks, last-used metadata; returns footprint and memory value | Request's source order and memory order; preserve trap/unspecified behavior and failure before a completed read | Primitive checked read; int/byte views, missing initialization, partial atomic-object access |
| E02 `D:705`, `M:1675`, `L:2474` store | Checked write, encoded bytes, function-pointer map, union member, optional readonly locking, last-used metadata; returns footprint | Record equal-value writes too; keep access/type/readonly checks before mutation | Primitive committed write; same-value race, overlapping offsets, disjoint subobjects |
| E03 `D:672`, `M:1428`, `L:2256` allocate region | Allocator cursor/id state, live allocation and dynamic address; returns pointer | Fresh identity and exact OOM state; allocation is not an ordinary store | Allocation installation; zero size, exhausted address space, repeated allocations |
| E04 `D:682`, `M:1296`, `L:2210` create object | Allocation plus unspecified representation or supplied initialization, readonly status and function-pointer encoding; returns pointer | Optional initialization bypasses `store`; distinguish unspecified representation from an initialized value; preserve allocator changes on later failure | Creation and initialized bytes at their source; strings, const objects, temporaries, atomic initialization |
| E05 `D:739`, `M:1472`, `L:2272` kill | Lifetime end and allocation removal/dead list; returns unit. Native pointer zapping is behind a switch disabled in the matched profile | Checked static/dynamic deallocation, preserved provenance rules; zapping is model metadata, not an invented source-level write by every affected thread | Lifetime end plus explicit metadata classification; invalid free, stale pointer, copied pointer, reuse |
| E06 `D:715` ordinary `SeqRMW` | Checked load, Core calculation, checked store; returns old/new values and updates trace | This is ordinary C increment/update, not an atomic RMW. Preserve exclusion/source-sequencing rules. Failed calculation/store retains the read and preceding state | E01/E02 with distinct event ids and correct continuation annotations; `x++ + y`, `x++ + x`, failed update |
| E07 atomic RMW/CAS requests | Object read and possible write; CAS also reads expected and may update expected | Strong/weak mismatch and spurious failure; object RMW indivisibility is distinct from expected-object effects; validate success/failure orders and operand evaluation | E01/E02 grouped according to reference action; exchange, CAS equal/unequal/spurious, effectful arguments |
| E08 `D:816`, `M:2643`, `L:2883` memcpy | Forward checked unsigned-char load/store pairs; returns destination | The original sequential request has no internal scheduler yield. SC helper suspension can yield between primitive effects, retaining loop order and current-state checks at resume. Preserve partial failure and the upstream overlap omission; validate the scheduling interpretation separately | Primitive byte effects, not final diff; copy/read, copy race, unchanged destination bytes, mid-copy fault |
| E09 `D:821`, `M:2657`, `L:2918` memcmp | Reads the entire first range and then the entire second; returns comparison integer | Do not replace with an early-exit comparison. Unspecified bytes/faults follow current checks; first difference does not remove later reads | E01 for all actual reads; race beyond first unequal byte, second-buffer fault |
| E10 `D:830`, `M:2676`, `L:2945` realloc | Validate old object, allocate, copy `min(old,new)` bytes, kill old, return new; null path allocates | Preserve helper order and completed allocation/copy on failure; do not invent rollback or shortcut lifetime events | E03/E05/E08; grow/shrink/null, failure during copy, old-pointer use |

## Library, runtime and startup paths

| ID / source | Effects and result | Ordering / failure obligations | Observation point and required test |
|---|---|---|---|
| E11 `F:375` character-array reader; `F:479,668,694` printf conversions | Loads format and argument representations, including `%s`/`%p`; formatted text/result | Reads belong to executing thread/library call; retain actual stopping/iteration and load faults | E01 underneath all formatted calls; shared format/string races, fault after a prefix |
| E12 `F:797,807` store characters | Checked char stores including terminating byte as implemented; returns unit | Retain partial output-buffer writes and length behavior | E02; snprintf/vsnprintf output alias and readonly/faulting tail |
| E13 `D:238,250,299–344` filesystem helpers | read/getcwd buffers, dirent allocation/initialization, stat field stores | Preserve the abstract FS transaction against competing FS services, while SC suspension permits intervening Core/memory work. Keep caller identity, error handling and failure-time state; ownership is not an ISO stream lock | E01–E04 beneath helper Mem monads; buffer publication, partial stat/dirent failure |
| E14 `D:409,420,441` formatted filesystem operations | printf/vprintf/vsnprintf memory accesses plus FS output | Observable output and memory effects are both retained; output is not a substitute for effect recording | E11/E12 with FS-step context; output bytes and memory race controls |
| E15 `D:219` errno error store | Writes current thread's errno object | Error handling itself may access memory; original child creation has null errno (`Core_run:1650` TODO), requiring an explicit integration repair/reference record | E02, thread initialization; child filesystem error, independent errno objects |
| E16 `D:1675–1719,1796–1838` argv/argc | Allocations and stores for argument strings, pointer array, argc and argv | Both entry constructions need coverage; initialization precedes main/children; preserve address-space failures | E01–E04 under initial-thread context; argv access after spawn, startup OOM |
| E17 `D:1868–1873` initial errno | Allocation and zero store | Before main, not an unowned action or unsequenced sibling | E02/E04 with initialization order; errno and global initialization trace |
| E18 runtime Core library / C libc | Ordinary Core calls eventually reach action/memop/FS requests | Inventory covers mechanisms, not just names like memcpy. Keep call/return order; do not suppress accesses because code is in the library | Existing request paths plus E11–E17; real C-to-Core libc examples |

## Metadata, pure operations and other implementations

| ID / source | Effects and result | Ordering / failure obligations | Observation point and required test |
|---|---|---|---|
| E19 `D:769–811,825,834–843` pointer difference/comparison/check/shift | Consult pointer/allocation/layout state as implemented; pointer/bool/integer result | No ordinary object read is implied by consulting validity metadata. Preserve lifetime-sensitive checks and failures; equal pointers alone do not define a conflict range | Retain whole Mem transition; pointer checks beside deallocation, disjoint offsets |
| E20 `D:778,782,873` casts / copy allocation id | Default concrete casts carry provenance and addresses; nondefault PNVI arms can expose allocation or create symbolic provenance | Do not turn provenance metadata into C stores, or silently claim unsupported configuration coverage. `copy_alloc_id` composes both casts | Preserve checked metadata transition; pointer/integer roundtrip, cast failure |
| E21 `D:857–869`, `F:834,870`, `M:2706–2775`, `L:3057–3128` varargs | va_start/copy allocate abstract ids, va_arg advances cursor and returns a pointer, va_end removes id, va_list reads list | va_arg does not itself load the pointed-to value; subsequent Core/Formatted load does. Shared abstract varargs metadata needs an explicit concurrency interpretation, not ordinary byte-write invention | Preserve metadata effects; variadic call, exhausted list, sharing/va_copy distinction |
| E22 update_prefix / prefix_of_pointer | Debug/source prefix metadata or query, not an object-value store | Preserve existing implementation behavior and known diagnostic-only Lean difference; not synchronization | State transition retained; prefix changes around same-value stores |
| E23 `D:881`, `M:2198`, `L:3139` memory intrinsic | Concrete instance's existing unsupported intrinsic failure; CHERI has a different implementation | Preserve an evidenced upstream/model limit. Do not use concrete's no-effect failure to classify CHERI as effect free | Model-specific port-gap record if another instance is added |
| E24 `Mem.sequencePoint` | Current concrete no-op; interface hook for other models | Core exclusions/source sequencing are not replaced by this hook | Core sequencing tests; check another implementation before enabling SC there |
| E25 constant-expression/elaboration and pure Core evaluation | Layout/type/value computation; memory state may be read for pointer operations | Pre-execution computations are not invented runtime thread actions. Never execute/erase a runtime Mem effect in this classification | Source-call audit plus normal frontend gates |

## Open integration questions, not runtime exclusions

1. The actual byte footprint, allocation identity, scalar C memory location,
   and atomic-object identity need distinct representations. `Mem.overlapping`
   excludes read/read pairs; it is not an intersection operator. Cmm's overlap
   adapter is a stub (`cmm_aux.lem:11–47`) and its undefinedness still uses the
   equal-location predicate (`cmm_csem.lem:3405`). This is not solved by swapping
   pointer equality for address overlap.
2. The scheduler needs source annotations for helper effects and a correct
   continuation update. Legacy whole-arena tagging invents `sb` edges for
   unsequenced siblings. Source `sb`, `asw`, `hb` and scheduling order remain
   separate; Cmm candidate membership and fault detection remain separate too.
3. Lifetime metadata, allocator reuse ordering and
   abstract varargs state require a documented composition with concurrency.
   The scalar SC checker excludes Alloc/Dealloc; that is a checker limitation,
   not authorization to exclude dynamic memory at runtime.
4. SC fences use the fence-aware upstream predicate and operation-specific
   frontend treatment. The all-SC callable-fence seed now has passing selected
   executions through both bundled-library paths; this is not exhaustive C
   coverage. Weak-order operations stay outside SC without silent coercion.
5. Effects inside a request do not themselves establish permitted yields. The
   selected grouping must be justified against Core/historical integration and
   the named concurrency reference, including faults and incomplete prefixes.

The September 19 byte/copy/race reproductions are retained in the audit evidence
directory. They are historical measurements until rerun on fresh prototype
artifacts. This inventory does not count those failures as already repaired.


September 23 clarification: E05 inventories the native zapping source path,
not an enabled effect of the concrete matched profile. Native kill invokes it
only with `SW_zap_dead_pointers`; Lean's supported switch value is false and
its alternative explicitly refuses. Paired actual-body controls show target
removal/dead identity with unchanged stored pointer bytes and no extra C store.
The failed contrary expectation and its source-based correction are retained in
the byte-metadata follow-up.
No configuration or semantics was changed to satisfy that expectation.

## Filesystem coverage and reached failures

The checked entry returns ordinary errno separately from a stopped result. All
stopped results preserve a typed fault and last-defined filesystem state. Driver
keeps that receipt separately from its ordinary committed filesystem state; no
Core completion, errno write or step increment occurs on a filesystem fault.
An earlier Core/memory fault keeps its own constructor and completed effects.
None of the filesystem special constructors constitutes an ISO C UB verdict.

### Upstream-selected open specials (SC-D07)

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

### Other deliberate upstream boundaries

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

### Available-guidance port gaps (SC-D07 and SC-D11)

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

### Protocol failures, not language exclusions

Native checked transitions report empty transition/result sets with their phase.
Lean reports missing contents/modes after a successful resolution, empty check
results, or a supposedly successful operation with an incompatible resolution.
These diagnose broken state invariants or adapter assumptions. They are retained
as FsFault.protocol; they are not newly forbidden C constructs or new ISO UB.
Repair a reachable protocol defect rather than adding a runtime precondition.
The Driver's normal result continuation is unchanged, including memory failures
before the old filesystem commit point and independent ND alternatives.
