# ZERO-DISCREPANCY Z1 — consumer change manifest (for refined-cerberus / cerberus-heaplang)

Date: 2026-09-03. Branch `arc/zero-discrepancy`, slice Z1. Charter:
`docs/2026-09-03_zero-discrepancy-design.md` (R3, all §7 asks RULED
[USER 2026-09-03]); slice record: `docs/2026-09-03_zero-discrepancy-Z1-record.md`.
Author: the orchestrator [AGENT], from the record and the diff
`mdd/cerberus-lean..HEAD`; every name below is in the tree at this
commit (line numbers computed from the files at write time).

The rule this slice implements [USER 2026-09-03]: every Lean-vs-oracle
EXECUTION difference is a bug; Lean now computes what upstream Cerberus
computes on every row listed. For a consumer that pins `drive`, the
re-pin therefore MOVES ANSWERS only where Lean was previously WRONG
against the oracle. No name your theorems quantify over was renamed;
one signature gained an instance binder (`casePtrval`).

## 1. Semantics-visible changes (affect `drive`'s results)

| Name | Change | Where / mirror |
|---|---|---|
| `CerbMem.copyAllocId` | real: `intfromptr … >>= ptrfromint` (was identity) | `lean_frontend/CerbMem.lean:2640` ↔ `impl_mem.ml:2766-2770` |
| `CerbMem.killM` | arm ORDER and arms re-mirrored: null free succeeds; function-pointer / no-provenance → `MerrOther` texts; device → return; `is_dynamic` on the pointer's ADDRESS; dead-allocation static kill → `panic!` (Q4) | `lean_frontend/CerbMem.lean:1912` ↔ `impl_mem.ml:1464-1550` |
| `CerbMem.deviceRanges`, `CerbMem.isWithinDevice` | NEW; device arms in `ptrfromint`, load, store | `lean_frontend/CerbMem.lean:2003`, `:2007` ↔ `impl_mem.ml:620-624/:681-686/:1611-1617/:1718-1724/:2163-2173` |
| `CerbMem.casePtrval` | SIGNATURE: gains `[Inhabited α]`; the fail-open fallback is now `panic! "case_ptrval"` | `lean_frontend/CerbMem.lean:1232` ↔ `impl_mem.ml:1814` |
| `CerbMem.intfromptr` | `MerrIntFromPtr` failure carries the call loc | `lean_frontend/CerbMem.lean:2370` ↔ `impl_mem.ml:2459` |
| `CoreParser.parseLibraryFile`, `CoreParser.stampLibraryFile` | NEW; std.core/impl nodes stamped with a `Loc.region ⟨file,0,0⟩ ⟨file,0,0⟩` (file only; line/col not tracked — documented Pos-payload divergence) | `lean_frontend/CoreParser.lean:2333`, `:2319` ↔ `core_parser.mly:1571/1744/1746` |
| `IvMaxAlignment` (CoreParser) | 16 → `CerberusImpl.max_alignment` (= 8): every `malloc`/`realloc`/`aligned_alloc` via std.core is now 8-aligned like the oracle | `lean_frontend/CoreParser.lean:1281` ↔ `core_parser.mly:1536-1537` |
| `CerbLocation.simpleLocation` | NEW; the oracle's `<L:C--L:C>` / `<unknown location>` / `<other location: s>` rendering, used by every batch `loc:` field | `lean_frontend/CerbLocation.lean:222` ↔ `util/cerb_location.ml:476-491` |
| `CerbLocation.isLibraryLocation` | runtime-relative SUFFIX test (`runtime/libc/include`, `runtime/libcore`, `runtime/libcore/impls`); the any-segment heuristic is gone | `lean_frontend/CerbLocation.lean:205` ↔ `util/cerb_location.ml:512-520` |
| `CerbFS.fs_*` (25 ops) | every op the model cannot answer as SibylFS does now REFUSES (`panic!`, attributed) instead of serving a default; served set = the op-by-op table in the header | `lean_frontend/CerbFS.lean` header table |
| `Main.refuseFlag`, startup `LEAN_ABORT_ON_PANIC` check, `Main.batchEscape` | BINARY ONLY: unknown/misplaced flags → exit 2; refuses to start without `LEAN_ABORT_ON_PANIC`; batch `stdout:`/`stderr:` fields escaped as OCaml `String.escaped`; killed-state stderr rendered on Undefined lines; zero-executions refusal declared (Q8 = A) | `lean_frontend/Main.lean:1038`, `:1057`, `:359` |

## 2. What you will observe on re-pin

- **Heap addresses shift.** `malloc`/`realloc`/`aligned_alloc` through
  std.core were 16-aligned on Lean and are now 8-aligned like the
  oracle (`IvMaxAlignment`). Any test that pins a concrete heap address
  or an address-derived value moves; any theorem stated over addresses
  symbolically is unaffected. (Probes: `tests/noodle-probes/dynamic-addrs/da_offset.c`
  8 vs 16, `da_align16.c` 2 vs 3 — now equal to the oracle.)
- **`free` verdicts on odd pointers change class**: null → success;
  function pointer / provenance-less → `Error (MerrOther …)`; device →
  success; interior pointer → UB179a (was `Error MerrUndefinedFree`);
  wrong-object free of a DEAD allocation → `panic!` (was UB179b) — the
  latter reachable only through the tray-19 `dynamic_addrs` defect,
  which is still MIRRORED (register candidate R4 DEFERRED [USER 2026-09-03]).
- **Device address range** `[0x40000000,0x40000004) ∪ [0xABC,0xAC0)`
  is now honoured (loads/stores succeed as on the oracle).
- **UB locations** raised inside std.core code now carry the C site
  (`<L:C--L:C>`), and `MerrIntFromPtr` carries its loc; every `loc:`
  render is the oracle's `simple_location` shape. If you compare
  driver output strings, they changed shape; verdict classes did not.
- **`casePtrval`** callers must have `Inhabited α` in scope; its
  previous fallback returned a value where the oracle raised — if a
  proof relied on that fallback it was relying on a bug.
- **CerbFS**: programs touching `stat`, directory ops, `O_EXCL`,
  missing-file open without `O_CREAT`, `lseek` past EOF, the `ENOSYS`
  trio now REFUSE loudly (`panic!`) instead of returning a default.
  In-process, a `panic!` still denotes the `Inhabited` default — see
  `docs/2026-09-03_typed-failure-outcomes-ruling.md` (the typed-outcome
  pass is scheduled after Z1–Z4; until then treat inputs reaching a
  panic as PROVISIONAL per your own rule).

## 3. Binary-only changes (irrelevant to in-process consumers)

Flag refusal (exit 2, attributed), the `LEAN_ABORT_ON_PANIC` startup
requirement, `String.escaped` rendering of batch io fields, the
Undefined-line stderr field, the zero-executions refusal declaration.
None of these is reachable from `drive`.

## 4. Unchanged

`CerbFuel.*`, `CerbND.drive`/`drive_lemFuel`/`fuelExhaustedKill`,
`CerbND.ndDefaultFuel`, `CerbCall.driveCall` (its fail-open injection
contract, Z-60, is Z2's), every generated module (the lem pin is
unchanged at `3c88f0d`; no `.lem` changed in this slice), the memory
model's representation (Z-30 is a later mover).

## 5. Gate evidence

Worker battery: record §9. Orchestrator re-run (independent, fresh
stamps, serial): see the boundary-review section appended to the
record. The register (VALIDATION.md "ISO-fix register") now lists the
three places Lean deliberately differs from the oracle (R1, R2
admitted; R3 conditional) — everything else is a mirror.
