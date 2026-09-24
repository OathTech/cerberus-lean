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
context supplied by Core/driver. It must be passive when disabled, must not
duplicate byte reconstruction, and must not add scheduling interruptions inside
an existing request. The concurrent justification for grouping helper accesses
is a separate obligation from sequential effect erasure. Source order must be
carried through helper requests and consumed by the completed checker.

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
| E08 `D:816`, `M:2643`, `L:2883` memcpy | Forward checked unsigned-char load/store pairs; returns destination | Current request runs the existing loop without scheduler yields. Preserve partial prefix if a later read/write fails; preserve upstream overlap omission as an upstream issue | Primitive byte effects, not final diff; copy/read, copy race, unchanged destination bytes, mid-copy fault |
| E09 `D:821`, `M:2657`, `L:2918` memcmp | Reads the entire first range and then the entire second; returns comparison integer | Do not replace with an early-exit comparison. Unspecified bytes/faults follow current checks; first difference does not remove later reads | E01 for all actual reads; race beyond first unequal byte, second-buffer fault |
| E10 `D:830`, `M:2676`, `L:2945` realloc | Validate old object, allocate, copy `min(old,new)` bytes, kill old, return new; null path allocates | Preserve helper order and completed allocation/copy on failure; do not invent rollback or shortcut lifetime events | E03/E05/E08; grow/shrink/null, failure during copy, old-pointer use |

## Library, runtime and startup paths

| ID / source | Effects and result | Ordering / failure obligations | Observation point and required test |
|---|---|---|---|
| E11 `F:375` character-array reader; `F:479,668,694` printf conversions | Loads format and argument representations, including `%s`/`%p`; formatted text/result | Reads belong to executing thread/library call; retain actual stopping/iteration and load faults | E01 underneath all formatted calls; shared format/string races, fault after a prefix |
| E12 `F:797,807` store characters | Checked char stores including terminating byte as implemented; returns unit | Retain partial output-buffer writes and length behavior | E02; snprintf/vsnprintf output alias and readonly/faulting tail |
| E13 `D:238,250,299–344` filesystem helpers | read/getcwd buffers, dirent allocation/initialization, stat field stores | Keep filesystem step grouping, caller identity, error handling and prior filesystem state | E01–E04 beneath helper Mem monads; buffer publication, partial stat/dirent failure |
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
4. SC fences require a fence-aware upstream predicate and operation-specific
   frontend treatment. The all-SC fence seed stays PENDING until resolved;
   weak-order operations stay outside SC without silent coercion.
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
the [byte-metadata follow-up](2026-09-21_sc-prototype-evidence/atomic-completion/followup/byte-metadata.md).
No configuration or semantics was changed to satisfy that expectation.
