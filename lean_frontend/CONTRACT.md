# The cerberus-lean contract

Status: **adopted 2026-09-29**; the operator decisions are in §5. Author: the orchestrator [AGENT], on the
[USER 2026-09-28] direction that the correct fix is to define much more explicitly the contract cerberus-lean is
trying to establish, then make sure the well-built features are supported and the poorly-built ones are
appropriately rejected. Occasion: the CerbFS path defect
(`docs/2026-09-28_cerbfs-path-hotfix-record.md`), a SERVED wrong answer in a surface the project never tried to
clone, with no discrepancy found in the core semantics.

## 1. What cerberus-lean promises

cerberus-lean is a Lean 4 artifact that is meant to mean **what the Cerberus OCaml implementation means**, for a
declared set of C programs and a declared configuration. Concretely, for every input, an execution ends in exactly one of:

1. **The same observable verdict as the oracle** — value, stdout, stderr, the UB it reports — under the documented
   observation comparison (VALIDATION §4); or
2. **A loud refusal** — a nonzero exit and a message that names the unsupported feature and the boundary it belongs to;
   or
3. **A resource outcome** — fuel exhaustion or a declared resource limit, never counted as agreement (class (b)); or
4. **A registered deviation** — one of the few [USER]-ruled ISO fixes (class (d)), a [USER]-ruled named deviation where
   the mismatch cannot easily be resolved (class (e), VALIDATION §2b), or a failure whose message text alone differs
   (class (a)).

There is no fifth outcome. **A different answer, or a silent absorption (a default, an errno, a zero, a success no-op),
where the oracle answers, is a defect by definition** — wherever in the tree it occurs, supported area or not. The
pathleak bug was a fifth outcome.

The outcome protocol reports stop metadata within these four outcomes; it does
not add another permitted result. Migrated refusals expose `REFUSAL`, migrated
hand-written mirrors expose `UPSTREAM_CRASH` with pinned upstream attribution,
and port guards expose `INVARIANT` (a defect, even when the oracle crashes).
Generated envelope-less panics and the three unmigrated D10/D11 refusal sites
remain legacy, origin unattributed. Their refusal semantics are unchanged, but
the generic decoder cannot attribute them as REFUSAL. The
[migration map](docs/2026-10-20_outcome-protocol-register-migration.tsv) names
the memory-model metadata and shared-desugarer mapping movers. Exit codes
alone do not establish these classes or prove shared origin. The first-delivery
[family table and consumer API](docs/2026-10-20_consumer-note-cerberus-caesium-outcome-protocol.md)
state the precise scope.

Collection completeness covers complete **emitted** records only. A pure abort
can discard earlier typed stops during exhaustive exploration before printing;
the constant-expression mini-run can also replace typed metadata with a legacy
panic. ModelFailure's location sentinel is not an authenticated origin tag.
These stated limits remain with the named
[structural-outcome arc](docs/2026-09-16_lean-only-outcomes-implementation-plan.md),
including the queued pure-failure work; this diagnostic protocol does not repair
them or prove correspondence.

What the contract does NOT promise: ISO C conformance beyond the oracle's; agreement outside the declared configuration;
correctness of the oracle itself (the upstream tray records where we believe it is wrong); a proof of correspondence.
The evidence is differential testing on documented corpora plus kernel-checked local properties of the Lean artifact
(totality, axiom cone, fuel contracts); **testing samples behaviour and does not prove equivalence** (VALIDATION §9) —
which is exactly why every unmodelled surface must refuse rather than guess.

## 2. The declared configuration

Matched (default-switch) mode of the oracle at the fork merge-base `b9aeedcb4`; sequential execution; the concrete
memory model; LP64; `--nolibc` and libc modes as exercised by the lanes; explicit `--fuel` and address-space parameters.
**Semantics switches: PNVI_ae_udi supported, matched against the oracle under the same switch; every other switch
refused.** The switch set is a parameter of the semantics (`[CerbGlobal.Switches]`, PNVI arc S1, 2026-10-05). The binary
supplies the default `[]` unless `--switches=PNVI_ae_udi` is given (PNVI arc S4, 2026-10-07): then `[PNVI_ae_udi]`, and §1
applies with the oracle run under the SAME switch (`scripts/test_pnvi.sh`, LADDER Tier A row 14). Every other
`--switches` value — another switch name, plain `PNVI`/`PNVI_ae`, a mixed list, an override (R-PNVI-11), an unknown name
(R-PNVI-12) — and `--iso` is refused at the CLI (`Main.lean` `judgeSwitches`/`refuseSwitches`, per element; `refuseFlag`),
including where the oracle silently ignores the name. Inside the PNVI-ae-udi semantics, the upstream arms that crash,
print debug output or call themselves wrong are refused (§3, the R-PNVI rows); the default set is unchanged by all of
this.

**The address-space top: the default is the promise; other values are a proof-use parameter.** `--address-space-top N`
is a DELIBERATE lift of upstream's constant for proof use — [USER 2026-10-03] ruled that the address-space-top
restriction is lifted specifically so that Cerberus can be treated as a proof artifact, accepted the recommendations
under that framing, and ruled that work enabling the Iris reasoning is not reverted. Its default mirrors upstream
exactly (`memory/concrete/impl_mem.ml` `last_address= Z.of_int 0xFFFFFFFFFFFF; (* TODO: this is a random impl-def
choice *)`, `Main.lean` `defaultAddressSpaceTop`), and §1 is promised at that default only. A NON-DEFAULT value is
outside the mirroring promise: pristine upstream has no such parameter, so there is nothing to mirror; the fork oracle's
own fork-only flag is an instrument (the tiny-top lane, LADDER A12), not the referent; and at very large tops (≥ 2^62)
objects become allocatable whose sizes OCaml's `Z.to_int` cannot represent, where the fork oracle would raise and Lean
computes (`docs/2026-10-03_total-arith-and-bookkeeping-record.md` §2.3 O-1). The fork's other memory models accept the
fork-only flag and IGNORE it (`memory/symbolic/impl_mem.ml` `initial_mem_state (_address_space_top: Z.t)`,
`memory/cheri-coq/impl_mem.ml` likewise) — those models exist on the fork oracle only (separate executables:
`cerberus-cheri`; the symbolic driver is commented out of `backend/driver/dune`); cerberus-lean has the concrete model
alone, and any model-selecting flag is an unknown flag, refused (exit 2, zero-discrepancy Z-24).

**Exhaustive mode is the promise; `--first` is outside it.** In the default (exhaustive) mode Lean explores every
nondeterministic branch, as the oracle's `--mode=exhaustive` does, and §1 applies to the whole verdict set. `--first`
follows only the first branch (`CerbND.runND1Fuel`), where the oracle's `--mode=random` draws branches from a
time-seeded generator: the two can serve different members of the same exhaustive set on a program whose result
depends on evaluation order. `--first` is a harness convenience (the libc_exec and libxml2 lanes use it, and are sound
only for programs whose result does not depend on the trace), not part of the §1 promise.

## 3. Feature areas and their states

Three states only: **SUPPORTED** (differentially validated; any disagreement is a bug), **REFUSED** (loud,
feature-attributed; each refusal has a witness), **OUT OF SCOPE** (not an input the artifact accepts at all).

| Area | State | Evidence / refusal witness | Open questions |
|---|---|---|---|
| C frontend (parse → Cabs → Ail → Core) | SUPPORTED | shared OCaml parser; Lean desugar/typing/elaboration differentially tested (row 1 parser tests, all Tier A/B lanes) | frontend is `partial` (not kernel-evaluable) — a stated limit, not a discrepancy |
| Inline assembly (GNU `asm`/`__asm__`: basic, extended, `asm goto`, asm labels on declarators) | **REFUSED** (D9) in both engines, where upstream silently erases it: an asm statement fails desugaring in the shared `.lem` (`feature not yet supported: inline assembly (asm statement) is unsupported`; Lean `--batch` reports `desugaring failed at` the asm location), an asm label on a declarator fails in the shared parser (`unimplemented keyword 'asm (inline assembly label on a declarator is unsupported)'`), so no Cabs reaches the Lean engine | `scripts/check_asm_refusal.sh` (row 1): 4 statement + 3 label witnesses, 2 controls, 3 plants | file-scope `asm(...)` is not in the grammar: a syntax error (loud, not attributed); `__asm` (no trailing underscores) is an ordinary identifier |
| Two upstream TODOs of the concrete memory model, item G (cerberus-caesium's note 2): `memcpy` on overlapping objects (C17 7.24.2.1#2 undefined; upstream's `impl_mem.ml` `memcpy` carries `(* TODO: if ptrval1 and ptrval2 overlap ==> UB *)` and copies byte-wise, tray 56) and an allocation with an invalid alignment (not a positive power of two; C17 7.22.3.1#2-3; upstream's `std.core:385` `aligned_alloc_proxy` checks only `size rem_t align = 0` and the allocator rounds to any alignment, tray 57) | **REFUSED** (D10) in both engines, where upstream answers a defined value: the memory model's `memcpy` (oracle `failwith`, Lean `CerbMem.memcpyM` `failwithI`) and its `allocator` (oracle `failwith`, Lean `CerbMem.allocator`) die with ONE text. The copy is refused when both pointers are concrete in the same allocation (`Prov_some`), or both are device-memory pointers (`Prov_device`, the fixed `device_ranges` an integer cast reaches — the pre-merge audit's P2-1), and the byte ranges intersect; the remaining pointer shapes cannot complete a copy (`Prov_none` fails at the first byte, `Prov_symbolic` dies in the pure `array_shift_ptrval`, `PVnull`/`PVfunction` fail in `load`; the audit's probes), except one named residual: an allocation/device pair, reachable only when an allocation lies inside a device range, i.e. under the fork-only `--address-space-top` (outside §2's promise), which both engines still serve (record §2: without the allocation's bounds, which `memcpy` does not consult, it cannot be told from an out-of-bounds run into device memory). The refusal fires before any access check, so an overlapping copy of a dead or out-of-bounds object is refused, not reported as that UB — `Concrete.memcpy: refused - memcpy on overlapping objects (…)` / `Concrete.allocator: refused - allocation with an invalid alignment N (…)`, each naming the clause, upstream's TODO/line and that the fork refuses rather than decides; oracle uncaught `Failure`, exit 125; Lean abort under `LEAN_ABORT_ON_PANIC=1`, exit 134 | `scripts/check_item_g_refusals.sh` (row 1): 6 overlapping-memcpy + 3 invalid-alignment witnesses with the two engines' texts compared byte for byte, 9 controls (incl. one allocation at each alignment the lanes use) + the unchanged zero-alignment crash, 5 plants | alignment zero stays the pre-existing `Division_by_zero` crash (tray 34, out of scope); both texts remain envelope-less at this delivery; the named memory-model refusal metadata extension under structural-outcome WP2 must settle their boundary vocabulary and migrate both producers and witnesses together |
| Union initializers whose member designator names a member other than the first, item U (tray 59 (a)): upstream's live initializer desugarer `desugaring_init.lem` `constructValue_aux` builds EVERY braced union initializer as the FIRST member whatever the designators say (its own `TODO: this is only correct if the first member was the one initialised` and level-0 print `constructValue_aux: is WRONG for union ==> always assigning the first member`; the init-map key `Elem_union` carries no member identity), so `union U { int i; unsigned char c[4]; } u = { .c = {1,2,3,4} }` answered 0 on both engines where gcc gives 104 | **REFUSED** (D11) in both engines, in the SHARED desugarer's `moveTo_aux` Union arm — the one place the designated member is decidable — when a member designator on a union names a non-first member: at any depth, any storage class, arrays of unions, nested unions, compound literals, a union inside a struct; the text names the union, the designator and the first member, C17 6.7.9#17-19, upstream's TODO and print, and that the fork refuses rather than decides — `Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); …`; oracle `Cerb_debug.error` (`internal error: <text>` + uncaught `Failure`, exit 125); Lean `failwithI` (abort under `LEAN_ABORT_ON_PANIC=1`, exit 134), the texts byte-identical. Positional and first-member-designated initializers (incl. mixing with the first member only, `{ 9, .a = 2 }` → 2), `{ 0 }` on a smaller first member (read back as Unspecified, both engines), the anonymous-union-in-struct path (its members are spliced into the enclosing struct's member list, so `.c` resolves through the struct) and a union inside a struct initialised positionally or at its first member are UNCHANGED and agree with the oracle | `scripts/check_union_init_refusals.sh` (row 1): 14 witnesses with the two engines' texts compared byte for byte, 12 controls, 1 gap control (the struct-from-struct-variable rejection unchanged on both), 5 plants | tray 59 (b)/(c) stay as upstream has them: a struct/union VALUE as a member initializer and a designated union compound literal in the initializer position are constraint violations on both engines (gcc accepts); an anonymous union member is flattened into the enclosing struct's layout (`sizeof` 12 where gcc has 8, no aliasing) — not refused, reported |
| Core dynamics (driver, reduction, pure eval) | SUPPORTED | Tier A/B lanes, pristine 835/28/7/2, gcc oracle, csmith corpus | none known; this is where the report found nothing |
| Concrete memory model | SUPPORTED | CerbMem mirror with cites; immaculate lane; allocator soundness theorem | the SC receipt buffer is disabled by default (WP0) |
| Function pointers | SUPPORTED, including round trips through integers and `void*` (libc's `atexit` uses one); their numeric value — through an integer conversion, their bytes or `%p` — is named deviation N1 | `zd-funptr-*` rows, libc_exec `040`/`041` | none |
| Integer/float/layout implementation choices | SUPPORTED (LP64); printing a NaN with `%f` REFUSED (its text depends on the NaN's sign bit, which Lean cannot read); a NaN's sign and payload bits in memory are named deviation N2; float constants in the libc Lean loads are rounded to 12 digits in one place (named deviation N3) | CerberusImpl, CerbFloat, float/bytes lanes | other ABIs OUT OF SCOPE (D6) |
| libc (the oracle's libc.co, loaded) | functions written in C (`runtime/libc/src/*.c`): SUPPORTED — they run through the same Core semantics as user code — but thinly tested (§3.2); the 36 **builtins** of `runtime/libcore/std.core` (hand-implemented in each engine): one state each, §3.1 (D4) | libc_exec lane, libxml2 lanes | a UB raised inside a libc C body is reported at `<unknown location>` by Lean and at the libc source location by the oracle (VALIDATION §3, Z1-A1: an open bug with a named mover) |
| Filesystem (CerbFS) | **REFUSED** (D2) — every filesystem operation, including `read` on any fd; `write`/`vprintf` on fds 1/2 are served (the driver routes them to the stdout/stderr records, never reaching CerbFS) | `zd-fs-*`, `zd-f1-truncate-negative-length`, `zd-z2f01-lseek-whence` pinned refusals | none |
| Standard input / environment / argv | stdin REFUSED (every read reaches CerbFS, D2; the oracle models an empty stdin); `getenv` served by libc C code; argv SUPPORTED | `zd-fs-stdin-read` pinned refusal; argv lane (5 programs) | UTF-8 `--args` unmeasured |
| Concurrency (threads, atomics, Epar, C11 model) | REFUSED at the CLI flag; default-mode atomics and `{-{ ||| }-}` SUPPORTED as the oracle's sequential reading | `refuseFlag`; served-surface audit: 15 default-mode probes agree, `statically_satisfied` has no generated caller | none |
| Semantics switch `PNVI_ae_udi` (`--switches=PNVI_ae_udi`) | SUPPORTED (2026-10-07), matched against the oracle under the same switch | `scripts/test_pnvi.sh` (Tier A row 14): upstream's 44 PNVI litmus files exhaustive, `tests/minimal` under the switch, the pKVM census drivers; `check_cli_refusals.sh` (acceptance + one agreement witness) | the pKVM allocator drivers are compared in `--first` only (their exhaustive sets exceed the 4G cap on the oracle: outside §1, §2); the refused arms below |
| PNVI-ae-udi arms upstream itself leaves as crashes, debug prints or self-declared wrong code | **REFUSED** (class (c), [USER 2026-10-05]): `PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-nn: …`, exit 134. R-PNVI-01 `combine_prov` on a symbolic byte (impl_mem.ml:390-394; -01b `provs_of_bytes`, shadowed), -02 `find_overlaping`'s `assert false`, -03 its dropped third candidate, -04 `lookup_iota`'s `Not_found`, -05 `abst`'s "This is wrong" arm, -06 pure `array_shift_ptrval` on a symbolic pointer, -07 `case_ptrval` on a symbolic pointer, -08 `diff_ptrval`'s invariant failure, -10 the stdout-printing arm of `eff_array_shift_ptrval` | lane witnesses (`test_pnvi.sh`, each a registered `REFUSAL` row, never agreement): -01 by 4 upstream litmus files where the oracle crashes; -05 (`tests/pnvi_refusals/r05-…`, the oracle answers through the flagged arm), -06 (`r06-memcpy-symbolic-source.c`), -07 (`r07-call-through-symbolic-pointer.c`) where the oracle crashes; -01b, -02, -03, -04, -08, -10 by compile-time pins (`test/Unit/PnviArmsTest.lean`) — no C witness found. Reach: -01b, -02, -04 unreachable by invariant and -03 UNKNOWN (reviewed rows of `scripts/failure_reach_register.txt`); -08 and -10 are MONADIC sites (`pnviRefuseM` inside an `ND` body) outside that pure-site census, so their reach is UNREVIEWED (no register row; -10's arm is never taken on any litmus or pKVM trace, MEASURED, design §G R16 — a measurement, not a reach argument) | R-PNVI-09 (`eff_array_shift_ptrval`'s `PVfunction` arm) is a DEFAULT-path site and stays a mirrored fail-stop with the other default-path look-alikes (design §H.1), pending the queued default-path consistency review |
| Non-default memory models (symbolic, VIP, CHERI), every other switch (plain PNVI, PNVI_ae, strict reads, strict pointer arithmetic, …) and `--iso` | REFUSED at the CLI | `judgeSwitches` / `refuseSwitches` / `refuseFlag` (`check_cli_refusals.sh`), incl. R-PNVI-11 (an override in one list) and R-PNVI-12 (an unknown name), where the oracle ignores the name and runs on | none |
| Debug/pretty-print seams (CerbDebug, CerbPP) | OUT OF SCOPE for verdicts | no-op stubs; served-surface audit: no verdict path reads them | none |
| Core text (CoreParser) | SUPPORTED for the runtime's own Core files (`std.core`, the implementation file, the libc dump), which every run parses; no mode executes user-written Core text (`--parse-core` and `--pp-core` are diagnostics) | core-parser tests (292 checks); verify lane | none |

### 3.1 The builtin boundary (D4)

`runtime/libcore/std.core` declares 36 `builtin` procedures. Unlike libc's C functions, each is implemented by hand in
both engines, so each has its own state. The live stepper's fallback arm fails any builtin not handled here, in both
engines, so a builtin added upstream fails closed until it is reviewed and listed.

| Builtin(s) | State | Where / evidence |
|---|---|---|
| `printf`, `vprintf`, `vsnprintf` | SUPPORTED (`vprintf` to fds 1/2; other fds reach CerbFS and refuse) | generated `Formatted`; immaculate programs that print (measured: 11 files call printf), libc_exec, libxml2 |
| `exit` | SUPPORTED | generated `Core_reduction`; every lane's exit path |
| `errno` | SUPPORTED | generated `Core_reduction`; libc_exec |
| `generic_ffs`, `ctz`, `bswap16`, `bswap32`, `bswap64` | SUPPORTED | `CerbUtils` line mirrors of `ocaml_gcc_builtins.ml`; immaculate `g4-*` rows |
| `write` | SUPPORTED on fds 1/2; fd 0 fails in both engines; other fds REFUSED (CerbFS) | `driver.lem` routing |
| `read` | REFUSED (CerbFS, every fd) | D2 |
| `any_bounded_int` | NOT SERVED by either engine: both fail it (`core_reduction.lem:1012-1013`) | `zd-any-bounded-int-crash` pinned MATCH / both crash |
| `open`, `close`, `pread`, `pwrite`, `lseek`, `truncate`, `link`, `readlink`, `symlink`, `unlink`, `rename`, `rmdir`, `mkdir`, `stat`, `lstat`, `umask`, `chmod`, `chdir`, `chown`, `opendir`, `readdir`, `rewinddir`, `closedir` | REFUSED (D2) | `CerbFS` refusals; `zd-fs-*` rows |

### 3.2 How deeply each part is tested

SUPPORTED means "differentially tested, and any disagreement is a bug". It does not mean every part is tested equally.
The measurement behind this section is `docs/2026-09-28_test-depth-map.md` (static counts of the gated lane programs
that exercise each part; there is no coverage instrumentation, so the counts are proxies), re-counted after the
edge-case tests of `docs/2026-09-28_thin-surface-tests-record.md` and the four rows added with the fixes that followed
them. The gating lanes hold 972 programs that agree with the oracle (measured by the map's census script on the
range head; the two `%f`-of-a-NaN rows are refusal pins, not agreement).

**Deeply tested:** the C frontend and Core dynamics (generated from the same Lem source as the oracle), load/store and
allocation, integer and floating-point arithmetic (also checked against gcc as a second oracle), the exhaustive runner
and the batch output format. Every program exercises these.

**Less deeply tested — treat results here with more suspicion.** These are served, and a disagreement is still a bug,
but fewer gated programs exercise them, and most are hand-written Lean rather than shared generated code. Counts are
gated agreement programs, before → after the 2026-09-28 edge-case tests:

| Part | Programs | Depth now | Why it matters |
|---|---|---|---|
| libc breadth | 11 → 62 of the 188 libc functions called directly; libc mode 32 single-trace → 61 single-trace + 2 exhaustive | THIN | most libc functions are still called by no test, and libc mode is mostly compared single-trace |
| `printf("%f")` | 0 → 13 | MODERATE | `CerbFloat.formatFixed` is an independent reimplementation of glibc's `%f` |
| printf width, precision, flags; `%c`/`%x`/`%X`/`%o` | 0 → 22; 0/1/0/0 → 6/8/2/3 | MODERATE | formatting is shared code, `%c` goes through hand-written escaping |
| `realloc`, `memcpy`, `memcmp`, `memset` | 4/5/2/1 → 16/15/7/5 | MODERATE (`memcmp`, `memset` thin) | hand-written `CerbMem` routines |
| `snprintf`/`vsnprintf`, `errno`, `exit`, `atexit` | 2/1/1/0 → 6/5/4/2 | THIN | return values and status codes |
| argv | 5 | THIN | non-ASCII arguments fail in both engines (with different messages) |
| programs of several translation units | 8 → 14 | MODERATE | linking and cross-TU identity |
| default-mode atomics and `{-{ ||| }-}` | 1 | THIN | shared code, lower risk |
| `--first` mode | not checked to be one of the exhaustive results | outside §1 | outside the §1 promise (§2) |
| non-batch CLI output | never compared (only `--batch` output is the compared interface) | outside §1 | human-readable format, exits 0 for every outcome, as the oracle's does |

The **refused** parts (filesystem, stdin, concurrency and switch flags, the PNVI-ae-udi refusals, `%f` of a NaN, inline assembly, the item-G memory-model TODOs, union initializers designating a non-first member) are pinned by
witnesses and are not "thinly tested": they do not answer.

## 4. How the contract is enforced

1. **Every REFUSED area has at least one witness in a lane that pins the refusal**, so a return to a silent answer turns
   a gate red: the filesystem and stdin (`zd-fs-*`, `zd-f1-*`, `zd-z2f01-*` immaculate rows), `any_bounded_int` (`zd-any-bounded-int-crash`), `%f` of a NaN (`fmt-007*.unsupported.c`), the CLI flags (`scripts/check_cli_refusals.sh`,
   row 1), the PNVI-ae-udi refusals reachable from C (`scripts/test_pnvi.sh`'s `REFUSAL` rows, Tier A row 14, which
   assert the refusal id and the oracle side), inline assembly (`scripts/check_asm_refusal.sh`, row 1, which asserts the message too) and the
   item-G memory-model refusals (`scripts/check_item_g_refusals.sh`, row 1, which asserts the message on both engines and their equality) and the
   union-initializer refusal (`scripts/check_union_init_refusals.sh`, row 1, likewise).
   Limit: the immaculate and coverage witnesses pin the crash CLASS (`L=CRASH`, `UNSUPPORTED`), not the refusal
   message, under those lanes' coarse crash policy (VALIDATION §1(a)); the message is fixed in the refusing code, and
   `check_cli_refusals.sh` asserts it for the CLI flags.
2. **A served-surface audit (the lesson of pathleak).** Every hand-written seam that can answer where it has no model —
   default arms, stub bodies, `Inhabited` defaults, lookups keyed on unnormalised data — is enumerated and classified:
   mirrors the oracle (with a cite), refuses (with a witness), or is unreachable (with the reason). The failure-reach
   register already does this for FAILURE sites; the audit extends the question to SUCCESS paths that answer without a
   model. Proposed as a fresh-reviewer pass with a finding ledger, before the contract is adopted.
3. **Adversarial inputs per area**, written from the contract rather than from the corpora: path spellings, fd reuse,
   environment and argv shapes, concurrency constructs in default mode. The corpora are upstream's tests and never
   exercised these.
4. `CONTRACT.md` becomes the front-page statement; `SUPPORTED.md` becomes its dated evidence table; VALIDATION keeps the
   mechanics. The announcement text points at `CONTRACT.md`.

## 5. Decisions

- **D1 — adopted** ([USER 2026-09-28] agreed): the outcome promise in §1 is the normative statement.
- **D2 — refuse the filesystem for now** ([USER 2026-09-28] chose refusal as the safer option). Implemented:
  every CerbFS operation refuses with a feature-attributed message; `write` to fds 1/2 stays served (driver-routed,
  never CerbFS). Three immaculate rows moved from MATCH to pinned refusals; the full ladder passed
  (`docs/2026-09-28_cerbfs-refuse-all-record.md`).
- **D3 — adopted** ([USER 2026-09-28] agreed): the served-surface audit (§4.2) ran
  (`docs/2026-09-28_served-surface-audit.md`). Its P1 finding (function-pointer numbers) is named deviation N1 ([USER 2026-09-28] agreed with option (1)),
  covering the integer conversion too after refusing it broke `atexit` ([USER 2026-09-28] agreed to the proposed
  `atexit` handling).
- **D4 — adopted, option 1** ([USER 2026-09-28] accepted option (1)): libc is supported by mechanism. Functions written
  in C inherit the core semantics' state; the 36 builtins are a named list with one state each (§3.1). `any_bounded_int`
  is listed as not served by either engine (the audit found it fails in both); its dead Lean seam, which returned `lo`,
  now fails loudly (`docs/2026-09-28_contract-enforcement-builtins-record.md`).
- **D5 — adopted, amended** ([USER 2026-09-28] agreed, amended to link it from the top-level README.md): this document is the
  public statement, linked from the top-level README.
- **D6 — LP64 only** ([USER 2026-09-28] agreed on the ABI): LP64 (the x86-64 Linux data model) is the one supported
  ABI, the only one the lanes test; every other ABI is out of scope.
- **D7 — a NaN's bits are named deviation N2** ([USER 2026-09-29] agreed on all three points, on the recommendation to register
  the pre-merge audit's F2 rather than refuse storing NaNs): Lean's float store canonicalizes NaNs, so their bytes
  differ from the oracle's (VALIDATION §2b).
- **D8 — the libc dump's float rounding is named deviation N3** ([USER 2026-09-30] chose option (3) for now, leaving
  (1) or (2) as possible later work), with a float-literal inventory check. Standing rule [USER 2026-09-30]:
  deviations are not fixed with special-case paths that work only in one situation.
- **D9 — inline assembly is refused** ([USER 2026-10-05] ruled that inline asm is a loud refusal). Upstream erases
  it (an asm statement desugars to a skip; an asm label is dropped by the parser), so a program whose meaning lives in its
  asm ran as if the asm were absent (real-C census §4.5: both engines `Specified(1)` where gcc gives 5). The refusal is on
  the general path of the shared model and parser, so the oracle and Lean refuse identically and no asm semantics is
  invented; a deliberate fork-vs-pristine difference, manifested in the fork-drift gate. No gated lane row moved
  (`docs/2026-10-05_asm-refusal-record.md`).
- **D10 — the item-G memory-model TODOs are refused** ([USER 2026-10-20] ruled that where upstream Cerberus left a case
  deliberately to a TODO, the fork either leaves it as-is or REFUSES LOUDLY — the run dies with a declared unsupported
  outcome — and never invents a verdict (no UB verdict, no error verdict) in its place, nor answers silently wrong). Two
  cases from cerberus-caesium's note 2 (upstream-tray drafts 56/57): an overlapping `memcpy` (both engines answered
  `Specified(7)` on the draft's witness) and an allocation with an invalid alignment (`aligned_alloc(3, 9)` allocated at
  "alignment 3"). Both refusals sit in the concrete memory model of BOTH engines — `memcpy` and the `allocator`, not the
  shared `std.core` (Core text expresses only verdicts) — with byte-identical texts; alignment zero (tray 34's
  pre-existing crash) is unchanged. Two gated lane rows were literally these cases
  (`tests/coverage/mem4/mem4-020-memcpy-overlap.c`, `tests/libc_exec/009-aligned-alloc-3.c`), each a deliberate control
  of the superseded stance; [USER 2026-10-20] ruled them retired from the lanes with their baseline rows, the witness
  script carrying their purpose (`docs/2026-10-20_item-g-refusals-record.md`).
- **D11 — union initializers designating a non-first member are refused** ([USER 2026-10-20] ruled, under the same
  rule as D10, that for union initializers the fork refuses rather than fixes — "refuse until it hurts" — that no C
  initialization semantics is to be claimed obvious, and that the parts upstream does not know about go to the upstream
  tray). Upstream's live initializer desugarer (`frontend/model/desugaring_init.lem` `constructValue_aux`) builds every
  braced union initializer as the FIRST member whatever the designators say, under its own TODO and a level-0 "is WRONG
  for union" print, so twelve well-formed programs answered silently wrong on both engines (tray 59 (a)). The refusal sits
  in the SHARED desugarer's `moveTo_aux` Union arm — the one place the designated member is decidable (the init-map key
  `Elem_union` carries no member identity) — as a Lem `error`, so the oracle (`Cerb_debug.error`) and Lean (`failwithI`)
  refuse with one text by generation; a deliberate fork-vs-pristine difference manifested in the fork-drift gate (the
  file was byte-identical to upstream before: new `desugaring_init.lem` / `desugaring_init.ml` rows). Measured over every
  corpus the lanes walk: exactly one gated program is a refused case — `tests/coverage/union3/union3-003-union-init.c`
  (`{ .c = 'A' }`, `c` the second member; Tier A row 3) — reported under the slice's STOP rule and RETIRED with its
  baseline row ([USER 2026-10-20], the item-G precedent: the project tolerates no silently wrong answer, and a MATCH on a
  wrong answer is not evidence; the witness script carries its shape) (`docs/2026-10-20_union-init-refusal-record.md`). Not refused, reported in tray 59 (b)/(c): the
  struct/union-value and designated-compound-literal initializer rejections, and the anonymous-union layout.
- **Agent-called dispositions under these rulings** [AGENT 2026-09-28]: `%f` of a NaN is refused rather than
  registered (it can be refused cheaply and precisely; Lean cannot read a NaN's sign), and the other disagreements that
  record found (its D3–D6, a separate numbering from this section's) are dispositioned in `docs/2026-09-28_thin-surface-tests-record.md` (addendum).