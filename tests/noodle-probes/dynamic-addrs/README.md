# dynamic-addrs/ — `free` of a non-malloc'd object accepted after a zero-size dynamic allocation at the same base

Probe directory from the 2026-09-03 investigation of the consumer's note
`refined-cerberus/docs/2026-09-03_upstream-note-dynamic-addrs.md`
(record: `lean_frontend/docs/2026-09-03_dynamic-addrs-investigation.md`;
upstream draft: `lean_frontend/docs/upstream-tray/19-dynamic-addrs-never-cleaned.md`).
NOTHING here is a gate: no baseline wiring, no CI. `results.log` is the
verbatim four-engine pin produced by `run_dynaddr.sh` (fork oracle
`git-cn-pin-609-g72164481a`, un-forked upstream oracle
`git-cn-pin-18-gb9aeedcb4`, Lean driver built from this tree, gcc 13.3.0
`-std=c11 -O0 -w`), 2026-09-03.

ISO cite for every `free`-side probe: C11 §7.22.3.3p2 — "if the argument
does not match a pointer earlier returned by a memory management
function, or if the space has been deallocated by a call to `free` or
`realloc`, the behavior is undefined." Cerberus's verdict for it is
`UB179a_non_matching_allocation_free` (mem_common.lem:279-280).

## The finding in one line

The concrete memory model records dynamic allocations by ADDRESS
(`dynamic_addrs`, impl_mem.ml:497; prepended at :1433, never removed;
`is_dynamic` = `List.mem`, :661-663) and admits zero-size regions, so a
`alloc(8, 0)` issued while the allocation cursor sits at the base `B` of
a live automatic object mints a region at `B` and makes `free` of the
AUTOMATIC object pass the dynamic check. CONFIRMED at the Core level on
both OCaml oracles and (by libc-body injection) on the Lean port; NOT
reachable from C through the library allocation functions on any of the
three engines, because every call to `malloc`/`aligned_alloc`/`realloc`
creates an argument temporary between the caller's last object and the
`alloc` (translation.lem:4435), so `malloc(0)` always lands on its own
(dead-by-return) temporary. A second, unrelated finding fell out:
the Lean Core parser hardcodes `IvMaxAlignment` = 16 where the oracle
evaluates it to 8 (`da_offset.c`, `da_align16.c`, `*_maxalign.*`).

## Probes

Modes: `.c` files run on all four engines with `--nolibc` (malloc/free
resolve to the std.core proxies); `.core` files run on the two OCaml
oracles only (the Lean driver has no `.core` runner); `inj_*.c` +
`inject_*.core` is the Lean-side Core-level instrument (`--inject`:
`rand`, a no-parameter libc function, gets the Core body in the
`inject_*.core` file via `cerberus-lean --libc`; the oracles cannot link
a `.c` with a `.core` — verbatim `error: undefined startup function`).

| Probe | Corner | fork oracle | upstream oracle | Lean (`--batch` = `--first`) | gcc | Class |
|---|---|---|---|---|---|---|
| `da_control.c` | C: `free(&x)`, no malloc | `UB179a` | `UB179a` | `UB179a` | abort 134 `munmap_chunk(): invalid pointer` | AGREE (control) |
| `da_bug.c` | C: the note's shape, `malloc(0); free(&x)` | `UB179a` | `UB179a` | `UB179a` | SIGSEGV 139 | AGREE — the C shape does NOT reproduce the claim |
| `da_offset.c` | C: `&x - malloc(0)` in bytes | `Specified(8)` | `Specified(8)` | `Specified(16)` | (native layout, meaningless) | **LEAN!=ORACLE** — IvMaxAlignment 8 vs 16 |
| `da_align16.c` | C: `malloc(0) % 16 == 0` (+2·`&x % 16 == 0`) | `Specified(2)` | `Specified(2)` | `Specified(3)` | 3 (glibc: 16-aligned) | **LEAN!=ORACLE** — same root |
| `da_malloc0_nonnull.c` | C: `malloc(0) != NULL` | `Specified(1)` | `Specified(1)` | `Specified(1)` | 1 | AGREE (malloc(0) is non-null in the model) |
| `core_control.core` | Core: `create; free(x)` | `UB179a` | `UB179a` | n/a | n/a | control |
| `core_bug.core` | Core: `create; alloc(8,0); free(x)` | `Specified(0)` | `Specified(0)` | n/a (see `inj_bug_bexit.c`) | n/a | **ORACLE-SUSPECT** (the claim, Core level) |
| `core_ptreq.core` | Core: `PtrEq(x, q)` | `{Specified(0), Specified(1)}` | same | n/a | n/a | base coincidence (see note below) |
| `core_dup.core` | Core: two zero-size regions at B, free both, free(x) | `Specified(0)` | `Specified(0)` | n/a (see `inject_rand_dup.core`) | n/a | ORACLE-SUSPECT (duplicate-address case) |
| `core_dup_dead.core` | Core: free the same zero-size region twice | `UB179b` | `UB179b` | n/a | n/a | control — ids stay distinct, double free caught |
| `core_use_after_free.core` | Core: load x after the accepted free | `UB010_pointer_to_dead_object` | same | n/a | n/a | consequence (x is dead) |
| `core_bug_then_kill.core` | Core: the accepted free, then x's scope-exit kill | uncaught `Failure("Concrete: FREE was called on a dead allocation")` exit 125 | same | n/a (Lean: `UB179b`, see `inj_bug.c`) | n/a | ORACLE_CRASH vs Lean UB (secondary divergence) |
| `core_maxalign.core` | Core: `IvMaxAlignment` | `Specified(8)` | `Specified(8)` | n/a | n/a | the model constant |
| `inj_bug.c` + `inject_rand_control.core` | Lean: no alloc in `rand`, `free(&x)` | — | — | `UB179a` | — | Lean control |
| `inj_bug.c` + `inject_rand.core` | Lean: `alloc(8,0)` in `rand`, `free(&x)`, then main's scope exit | — | — | `UB179b_dead_allocation_free` at the free's loc | — | free ACCEPTED (no UB179a); x's scope-exit kill finds it dead |
| `inj_bug_bexit.c` + `inject_rand.core` | same, `__builtin_exit(0)` before scope exit | — | — | `Specified(0)` | — | **the claim, Lean side** — mirrors `core_bug.core` |
| `inj_bug_bexit.c` + `inject_rand_dup.core` | Lean duplicate-address case | — | — | `Specified(0)` | — | mirrors `core_dup.core` |
| `inj_maxalign.c` + `inject_maxalign.core` | Lean: `IvMaxAlignment` | — | — | `Specified(16)` | — | **LEAN!=ORACLE** (8 on both oracles) |

Notes.
- `core_ptreq.core`: `PtrEq` on pointers with different provenance is
  nondeterministic in the concrete model (`eq_ptrval`, impl_mem.ml:
  1851-1858: `Prov_some a1, Prov_some a2` compares allocation ids, and
  the exhaustive driver explores both outcomes); the two-execution
  output is what equal-address/different-provenance looks like — a
  different address would give a single `Specified(1)`. `IntFromPtr`
  returns `Unspecified` here for both pointers (PNVI exposure), so the
  arithmetic form was not usable at Core level.
- gcc column: `da_offset.c`'s exit is native heap-vs-stack distance
  (ASLR; 208 and 192 on two runs) and carries no information; the
  `free(&x)` rows record glibc's behaviour as the second-oracle datum
  (it rejects: abort/SIGSEGV).
- The `inj_bug.c` UB179b line's `loc` is the `free` call; the verdict is
  raised by main's block-exit `kill` of `x` (Lean `killM` :1906-1907 maps a
  dead allocation to `Free_dead_allocation` for static and dynamic kills
  alike, where OCaml's static arm `failwith`s, impl_mem.ml:1532).

## INTEGRATION (recommendation; nothing integrated here)

| Probe(s) | Target lane | Expected class |
|---|---|---|
| `da_control.c`, `da_bug.c`, `da_malloc0_nonnull.c` | exec corpus (`tests/minimal`-style, nolibc) | MATCH / UB_MATCH (three-way agreement; `da_bug.c` documents that the C shape does not reach the defect) |
| `da_offset.c`, `da_align16.c` | `tests/immaculate/nolibc/` DIFF rows, Lean pin `VAL:Specified(16)` / `VAL:Specified(3)` — flip to MATCH when `CoreParser.lean:1282` reads `CerberusImpl.max_alignment` (oracle-right, Lean-wrong; NOT an ISO-fix-register candidate) | DIFF → MATCH |
| `core_*.core` | oracle-only reporting rows: `tests/core/`-style, tray 19 cross-reference. No differential lane runs `.core` inputs on both sides — a Core-level differential lane would be new infrastructure (see the record, disposition) | pins only |
| `inj_*` | Lean-only reporting rows (libc-injection instrument); pair with the `core_*` pins by shape | pins only |
| immaculate Lean-right/oracle-wrong PAIR for the claim | NOT available today: no single input runs the defect on both engines (Core-level only; the C shape is blocked by argument temporaries on both). Admission to the ISO-fix register (R4) would first need a Core-level or injection-capable pinned lane | — |

## Running

```bash
scripts/ce scripts/libc_prep.sh --jsons .tmp/pd/libcjson                 # once, for --inject
D=tests/noodle-probes/dynamic-addrs
scripts/ce $D/run_dynaddr.sh $D/da_*.c $D/core_*.core
scripts/ce $D/run_dynaddr.sh --inject $D/inject_rand.core $D/inj_bug.c $D/inj_bug_bexit.c
```
