# ZERO-DISCREPANCY — Z2 seam-by-seam mirror audit, READ PHASE (2026-09-03)

Branch `audit/z2-seams` off mainline `046e5cdd4` (worktree
`worktrees/cerberus-lean-audit/z2-seams`). READ PHASE: this record + the
probe corpus `tests/z2-probes/` and nothing else — no product code, gate,
or baseline was modified; nothing merged or pushed. The Z2 FIX phase
(rebased on Z1) takes this document as its work order (§6).

Charter: `docs/2026-09-03_zero-discrepancy-design.md` (branch
`arc/zero-discrepancy` @ `cf32c81e8`) — §1 the rule, §2.2/§2.7 the rows
re-verified here, §3 THE SEAM-BY-SEAM MIRROR AUDIT (this mandate), §7 the
rulings. Method inputs: the noodler's CerbMem seam read
(`docs/2026-09-03_noodle-cerberus-lean.md` §4, branch `noodle/semantics`)
and the Z-76 lesson (`docs/2026-09-03_dynamic-addrs-investigation.md` §6,
branch `probe/dynamic-addrs`: a hand-written seam hard-coded 16 where the
OCaml reads the implementation record's 8).

THE RULE [USER 2026-09-03]: every Lean-vs-oracle execution discrepancy on a
program both engines run in matched mode is a bug (verdict class, value,
UB code, UB LOCATION, stdout/stderr bytes, trace set). Exceptions only:
(a) failure MESSAGE TEXT, (b) resource limits where the oracle also
fails / fuel, (c) missing features behind a LOUD feature-attributed
refusal, (d) the ISO-fix register (R1, R2 admitted; R3 conditional).
Proof-support machinery is allowed only with ZERO execution effect.
"Unobservable today" is not a class: every divergence in the Lean text
is either mirrored (with a `file:line` cite) or declared in-code with a
reachability argument. Every classification below is [AGENT]; quoted
engine lines are verbatim from `tests/z2-probes/*/README.md` (and the
ephemeral `.tmp/z2/*.log` they were transcribed from); tallies are
labelled derived.

Binaries: rebuilt in this worktree by `scripts/common.sh build_cerberus`
+ `CERB_MEM_MAX=16G build_lean`; `tools/check_driver_fresh.sh --check`
verbatim: `check_driver_fresh: oracle OK (bin 6f59798cba4fae1fb6eeadb5145f7b77f041603953ece5d8ca5fc3a621caf06d, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)`
/ `check_driver_fresh: lean OK (bin 8c484a477dc862bc255ba8a46f1b6791cb994a18a8b42e1fe77689aa82a1ff6a, src 60f9b3efb82e380130da3727a74627602f476cc0828a0db67dcc33a387bdf091)`.
Third engine: un-forked `deps/cerberus-upstream` (`--version` verbatim
`git-cn-pin-18-gb9aeedcb4`), read-only, its built driver. Every Lean run
through `scripts/capped` (`CERB_MEM_MAX=16G` for the build, 4G per probe).
No Tier A/B lane was run (no product code changed).

Line numbers: Lean cites are the tree at `046e5cdd4` (the charter's
CerbMem cites were taken at `72164481a` and are +6 here — the file grew
from 2561 to 2567 lines); OCaml cites are the same tree (impl_mem.ml is
byte-identical to upstream through :2998).

## 0. Headline

Manifest note (derived): `lean_frontend/handwritten_copy.manifest` lists
**23** files at `046e5cdd4` — the charter's "22" predates `CerbFuel.lean`
(the fuel arc). All 23 were read.

| Seam | Candidates | C-observable (matched mode) | Probe-confirmed Lean≠oracle | Probe-REFUTED (reachability or claim) | Notes |
|---|---|---|---|---|---|
| `CerbMem.lean` | 31 (§2.1: 15 re-verified Z-09…Z-23 + 16 new) | 8 | 5 (3 distinct findings: `aligned_alloc(0,·)` ×3 witnesses, `device_funptr_call`, `free_funptr` = Z-07) | 3 (empty-struct `% 0`; FunctionNoParams `isWellAligned` arm; Z-19 text via cast) | Z-23 re-cite: the charter's six sites are already corrected in-tree except one (`:569` cites `:1200`, the def is `:1202`) |
| `CerbND.lean` | 3 | 0 | 0 | — (trace ORDER verified identical on 6-way/2-way; Z-59 argument verified) | `--first` = first branch = LAST printed execution on both sides; oracle default mode is RANDOM |
| `Main.lean` (renderers/CLI) | 7 | 3 | 1 NEW (`batchEscape` stdout/stderr bytes) + Z-72/Z-03 cross-refs | — | exit-code mapping verified equal |
| `CerbPP.lean` + CerbMem printers | 1 (Z-61) | 0 | 0 | — | every batch-line printer verified byte-identical by reading |
| `CerbLocation.lean` | 2 | 1 (= Z-03) | — (Z-03 known) | — | cursor suffix dropped in `stringFromLocation` (text-only) |
| `CerbCall.lean` | 5 | 2 (`--call` harness) | 2 (`_Bool` injection; errno allocation order) | — | fail-open header contract (Z-60) confirmed |
| `CerbFS.lean` (cross-check) | 7 residuals missed by Z-27's list | 2 probed | 1 (`lseek` invalid whence) | 1 both-crash (`closedir`) | for Z1's op-by-op table |
| `CerberusFresh.lean` | 1 | 0 | — | — | hex order isomorphism CORRECT; digest VALUES differ (multi-TU order) |
| `CerbUtils`/`CerbDebug` | 2 | 0 | — | — | debug level 0 in matched mode confirmed (Z-66) |
| `CerbGlobal`/`CerbConcurrency` | 2 | 0 | — | — | full switch-default table: every exec read = the oracle's default |
| `CerberusImpl.lean` | 4 | 1 | 1 (`__cerbty_int32_t` normalisation → panic) | 1 (the `<stdint.h>` route) | impl table entry-by-entry equal otherwise |
| `CerbFloat.lean` | 3 | 1 (INSTRUMENT) | 1 INSTRUMENT (panic-without-flag → value) | 2 (hex-float rounding; decimal sweep 200/200) | Z-62 disposed (unreachable by construction) |
| `CerbDecode.lean` | 1 | 0 | — | — | Z-63 disposed (caller set verified) |
| `CerbTags.lean` | 1 unsettled | 0 | — | — | libc-mode merge vs `union` not traced |
| `CoreParser.lean` | 21 | 3 (incl. Z-76, Z-01) | 1 NEW (`inf` in libc.core) | — (1 not settled: `strtof_fltmax.c` triple timeout) | every `IV*`/impl production checked; 14 fail-open parser arms (hand-written Core only) |
| `CabsImport.lean` | 2 | 0 | — | — | Z-70 holds; 4 schema leniencies listed |
| the 4 instance files | 2 | 0 | — | — | Z-71: agree at every exec site; one fragility, one unsettled |
| `CerbFuel.lean` | 0 | 0 | — | — | zero execution effect confirmed |
| **Derived totals** | **~95 candidate rows** | **21 C-observable (incl. cross-refs Z-01/03/72/76, Z-07)** | **12 runs / 9 distinct Lean≠oracle findings (8 NEW: Z2-M-01, Z2-M-02, Z2-P-01, Z2-CP-01, Z2-I-01, Z2-F-01, Z2-C-01, Z2-C-02; + Z-07 re-witnessed; 1 INSTRUMENT Z2-FL-03)** | **3 refuted + 1 not evidenced** | 34 probe programs |

Top findings by execution impact (verbatim lines in the probe READMEs):

1. **`aligned_alloc(0, n)`** (`tests/z2-probes/mem/aligned_alloc_zero*.c`):
   oracle (fork AND upstream) `Division_by_zero` uncaught exception, exit
   125 (`Raised at Z.rem … Called from Cerb_frontend__Impl_mem.Concrete.op_ival in file "memory/concrete/impl_mem.ml", line 2482`);
   Lean `Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "unknown location"}` for
   `aligned_alloc(0, 8)` and **`Defined {value: "Specified(1)", …}`** for
   `aligned_alloc(0, 0)`. The hand-written `std.core:385` `size rem_t align`
   has no UB045 guard, so `CerbMem.integerRem_t`'s "unreachable behind
   Core's division-by-zero UB guards" declaration (CerbMem.lean:1322-1327)
   is FALSE. BUG-FIX under Q4 (one-sided oracle crash → Lean fail-stop
   carrying the OCaml text) + tray candidate. Z2-M-01.
2. **Batch `stdout:`/`stderr:` escaping** (`tests/z2-probes/main/stdout_escape.c`):
   oracle `stdout: "a\bb\007\127\195\169\011\012\027|\n"`, Lean emits raw
   control bytes and re-encodes each byte ≥ 0x80 as UTF-8 (`C3 A9` →
   `C3 83 C2 A9`). `Main.lean:366-373 batchEscape` vs `driver_ocaml.ml:101`
   `String.escaped`. BUG-FIX, S. Z2-P-01.
3. **`case_ptrval` fail-open fallback** (`tests/z2-probes/mem/device_funptr_call.c`):
   oracle `Failure("case_ptrval")` exit 125 on `((void(*)(void))0xABC)()`
   (device-range address → `Prov_device`); Lean `Error {msg: "Illformed_program: … does not point to a function"}`.
   `CerbMem.lean:1240` `| .PV _ (.PVconcrete _ addr) => onConcrete none addr -- fallback`
   vs `impl_mem.ml:1814` `| _ -> failwith "case_ptrval"`. Today masked by
   Z-06 (Lean never mints `Prov_device`); the moment Z1 lands Z-06 without
   this mirror, the fallback turns a crash into a VALUE path. Z2-M-02.
4. **`allocateRegion` eager byte materialisation** (`CerbMem.lean:1895-1896`
   vs `impl_mem.ml:1420-1435`, which writes NO bytemap bytes): not a
   verdict difference, but the exact one-line cause of the Z-30 malloc OOM
   class (`malloc_oom_msg.c`: the oracle answers
   `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}`
   after four 2^46-byte mallocs; Lean was not run — it would materialise
   2^46 bytes). Deleting the two lines is behaviour-preserving
   (`readBytesFrom` already defaults absent bytes to unspecified). S, and it
   also retires the message-text row Z2-M-03 if done together. Z2-M-04.

Everything else found is either a crash-parity mirror, a declared
unreachable-by-construction shape, or message text (§2).

## 1. Method (as executed)

For every manifest file: the Lean text read against its OCaml twin line by
line (the §3 table's twins), every divergence listed as a candidate with
both cites and both texts quoted, reachability classified, and every
C-observable candidate probed on the three engines with
`tests/z2-probes/run_z2.sh` (fork oracle / upstream / Lean; full-line
compare, `LINE-DIFF` when only a non-`value` field differs). FINDINGS ARE
CLAIMS: no row asserts a divergence without the OCaml read at the cited
line; where a probe contradicted the reading, the probe wins and the row
says so (three such rows in §2.1). The CerbMem and CoreParser reads were
prioritised per the brief; the parallel readers' results (§2.4–§2.18)
were re-verified at their cited lines before being adopted here where a
row is classified BUG-FIX or C-observable; rows adopted on the reader's
reading alone say "(reader)" and are candidates for the FIX phase to
re-read.

## 2. Seam-by-seam candidate rows

Row columns: id · Lean cite + text · OCaml cite + text · what differs ·
reachability · class · fix + price. Reachability vocabulary: **C** =
C-observable in matched mode; **REFUSED** = only via a refused mode /
feature; **UNREACH** = unreachable by construction (argument given);
**TEXT** = failure-message text only.

### 2.1 `CerbMem.lean` (2567) vs `memory/concrete/impl_mem.ml` (module `Concrete`)

Coverage of the mandated re-read: `abst`/`repr` (:916-1095 / :1139-1220 vs
`reconstructValue_lemFuel` :881-1010, `memValueToBytes_lemFuel` :587-687,
`splitBytesProv`/`provFromIntegerBytes` :543-573, `bytesToInt`/`intToBytes`
:510-535), `eq/lt/le/ge/diff_ptrval` (:1830-2063 vs :2079-2218),
`memcpy/memcmp/realloc` (:2635-2696 vs :2326-2426), varargs (:2698-2764 vs
:2447-2550), `max/min_ival` (:2367-2434 vs :1267-1304), `op_ival` +
bitwise (:2464-2511 vs :1340-1429), `sizeof/alignof/offsetsof` (:98-273 vs
:248-503), `case_ptrval`/`case_funsym_opt` (:1808-1827 vs :1232-1250),
`ptrfromint`/`intfromptr` (:2126-2173, :2439-2461 vs :2281-2306) incl. the
device and PNVI arms, plus allocation/kill (:1247-1550 vs :1850-1927),
load/store (:1552-1789 vs :1967-2078), the shifts (:2203-2360 vs
:1510-1550, :2309-2313), `copy_alloc_id`, `bytefromint`/`intfrombyte`, the
pretty-printers (:550-615, :2602-2634 vs :1575-1760) and the `fail`
mapping (:540-546 vs :1784-1794). Verified-matching (no row): `combine_prov`,
`AbsByte.split_bytes`/`pvi_split_bytes` folds (argument order preserved),
`int_of_bytes`/`bytes_of_int` value paths, `typeof`, `ctype_mem_compatible`
(`unqualify_and_unatomic` incl. the Byte→`unsigned char` and the
`is_register := false` map), `readonly_status` selection, `select_ro_kind`,
the load arm ORDER (dead → bounds(get_allocation) → atomic) and the store
arm ORDER (bounds → readonly → atomic, no dead check), `is_atomic_member_access`'s
three-way conjunct, the `_Bool` trap check (`AilTypesAux.is_Bool` is the
bare `Ctype _ (Basic (Integer Bool))` shape, ailTypesAux.lem:109-114),
`eq_ptrval` arm for arm incl. the `msum` fork labels, the four relational
operators' non-strict paths and MerrWIP texts (probe `ptr_lt_null.c`
AGREE), `diff_ptrval`'s strict path and array-layer strip, `realloc`'s arm
sequence and UB179c/d family, `va_*` incl. the "not initiliased" spelling,
`memcmp`'s `Cerb_location.unknown` loads and `Z.compare` fold, `memcpy`'s
checked per-byte loop, `max_ival`/`min_ival` per integer type incl. the
Wint_t asymmetry and Bool = 255, `op_ival` provenance rules, `offsetof_ival`
(name-only `idEqual` = symbol.lem:8-14 `Identifier _ str` equality),
`member_shift_ptrval`, all printers (`(struct s){.m= v}`, `NULL(ty)`,
`Cfunction(sym)`, `(@id, 0x…)`, `@empty`/`@device`), and `AilTypesAux.is_signed_ity
= Implementation.is_signed_ity` (ailTypesAux.lem:28) so `abst`'s signedness
source is the same implementation record `CerberusImpl.is_signed_ity` mirrors.
Proof-support forms (`memValueToBytes_append_lemFuel`,
`reconstructValue_indexed_lemFuel`, `chunksOf_eq_range_map`, the `_eq_`
theorems) are referenced only inside CerbMem.lean (grep: 23 in-file
references, 0 elsewhere) and not by the live definitions — zero execution
effect, as the rule requires.

#### 2.1.1 New rows

| id | Lean | OCaml | differs | reach | class | fix + price |
|---|---|---|---|---|---|---|
| **Z2-M-01** | `CerbMem.lean:1333` `def integerRem_t (a b : Int) : Int := Int.tmod a b` (+ `:1330` `integerDiv_t`, `:1337` `integerRem_f`), doc `:1322-1327` "Zero divisor: zarith raises Division_by_zero … unreachable behind Core's division-by-zero UB guards (UB045)" | `impl_mem.ml:2481-2482` `IntRem_t -> IV (combine_prov prov1 prov2, Z.integerRem_t n1 n2)` with `:11` `let integerRem_t = (mod)` = `Z.rem` → raises `Division_by_zero` | total function vs uncaught exception | **C** — `runtime/libcore/std.core:385` `if size rem_t align = 0` in `aligned_alloc_proxy` has no guard. PROBED: `aligned_alloc(0, 8)` → oracle ×2 exit 125 `Division_by_zero`; Lean `Undefined {ub: "DUMMY(align_alloc)", …}`; `aligned_alloc(0, 0)` → Lean `Defined {value: "Specified(1)", …}` | **BUG-FIX** (Q4: one-sided oracle crash → Lean fail-stop with the OCaml text; the aligned_alloc crash is ALSO an oracle defect → tray draft) | `opIval`: `IntRem_t`/`IntRem_f` with `n2 == 0` → `panic!`/fail-stop carrying `Division_by_zero` (cite :2481-2484, z.ml:96); `IntDiv` keeps its explicit zero guard (:2479-2480); `diffPtrval`'s `integerDiv_t … (sizeofCtype …)` divisor is ≥1 for every complete type — declare. Rewrite the `:1322-1327` doc. **S** |
| **Z2-M-02** | `CerbMem.lean:1240` `| .PV _ (.PVconcrete _ addr) => onConcrete none addr -- fallback` | `impl_mem.ml:1814` `| _ -> failwith "case_ptrval"` (the `Prov_device`/`Prov_symbolic` concrete arms) | value vs crash | **C** once Z-06 lands (today Lean mints no `Prov_device`, so the fallback is dead; the oracle already crashes). PROBED `device_funptr_call.c`: oracle ×2 exit 125 `Failure("case_ptrval")`; Lean `Error {msg: "Illformed_program: …:9:18-43: does not point to a function"}` (crash vs Error class TODAY) | **BUG-FIX** (Q4) — MUST land in the same commit as Z-06 | `casePtrval`: replace the fallback with `panic! "case_ptrval"` (cite :1814). **S**. Callers: core_eval.lem:920, core_run.lem:997 (Eccall), core_reduction.lem:1369 |
| **Z2-M-03** | `CerbMem.lean:1859` and `:1887` `(NDkilled (Other (MerrOther "out of memory")), st)` | `impl_mem.ml:1255` `fail (MerrOther "Concrete.allocator: failed (out of memory)")` | Error-line text | **C** (oracle line PROBED `malloc_oom_msg.c`: `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}`; Lean not run — Z-30 OOM precedes it) | EXC(a) — mirror anyway (trivial) | one string, both sites. **S** |
| **Z2-M-04** | `CerbMem.lean:1895-1896` `let st' := writeBytesTo st' alignedAddr (List.replicate size { prov := .Prov_none, copyOffset := none, value := none })` | `impl_mem.ml:1420-1435` `allocate_region` updates `allocations` and `dynamic_addrs` only — no bytemap write (`fetch_bytes` :708-722 defaults an absent byte to `AbsByte.v Prov_none None`) | eager O(size) materialisation vs lazy | not a verdict difference; it IS the Z-30 mechanism for `malloc`/`calloc`/`realloc` (`readBytesFrom` :1807-1811 defaults absent bytes identically) | INSTRUMENT / Z-30 mover (S part) | delete the two lines (mirror :1420-1435 exactly); re-measure `mem_malloc_4gb_lazy.c`/`mem_calloc_overflow.c`. **S** |
| **Z2-M-05** | `CerbMem.lean:1855-1856` `let align := alignN.toNat.max 1` / `let size := (sizeofCtype tagDefs ty).max 1`; `:1883` `alignN.toNat.max 1`; `:1884` `let size := sizeN.toNat` | `impl_mem.ml:1247-1257` `allocator`: `quomod z align` (Division_by_zero on 0), `:1289` `let size = sizeof ty`, `:1420` `allocator size_n align_n` | = charter **Z-13** (clamps / negative→0) | UNREACH for `create` (alignof ≥ 1, sizeof of a complete type ≥ 1 — probe `empty_struct.c`: the GNU empty struct is UB061 on all three engines); **C** for `alloc(0, 0)` via `aligned_alloc(0, 0)` — but only past Z2-M-01's crash, which the mirror closes first | BUG-FIX (Z-13 confirmed; reachability sharpened) | delete the clamps; `align = 0` → `panic!` mirroring `Division_by_zero` (`:1252`); negative size: `Z.sub last_address sz` grows the address — mirror the Int arithmetic (no `toNat`). **S** |
| **Z2-M-06** | `CerbMem.lean:2445` `def prefixOfPointer (_ : PointerValue) : memM (Option String) := memReturn none` | `impl_mem.ml:1364-1418` computes `Some (string_of_prefix alloc.prefix ^ …)` for `Prov_some` pointers | value | UNREACH in batch: the only callers are `driver.lem:689/702/714`, which store the prefix in `dr_st.trace` (`ME_load/ME_store/ME_seq_rmw`), consumed by `--trace`/UI only | declare-with-argument (or port, S-M) | in-code declaration with the three driver.lem cites; port if `--trace` parity is ever wanted |
| **Z2-M-07** | `CerbMem.lean:1308` `def concurReadIval (_ : integerType) (_ : sym) : IntegerValue := integerIval 0` | `impl_mem.ml:2361-2362` `failwith "TODO: concurRead_ival"` | value vs crash (fail-open) | REFUSED (concurrency; Z-24/Z-25) | BUG-FIX shape (dead fail-open path) | `panic!` with the OCaml text. **S** |
| **Z2-M-08** | `CerbMem.lean:1399,1409,1417,1425` `let size := match CerberusImpl.sizeof_ity ity with \| some n => n \| none => 4` | `impl_mem.ml:2497-2511` never consults sizeof: `IV (prov, Z.(sub (neg n) (of_int 1)))`, `Z.logand/logor/logxor` on unbounded Z | Lean re-normalises through a width (with a `none => 4` DEFAULT); OCaml is two's-complement on Z | UNREACH for in-range operands (both agree; `~` on unsigned types is elaborated as `max - e`, translation.lem:1569-1575, never `bitwise_complement`); the `none => 4` arm is a fail-OPEN default where the OCaml has no such read | declare + delete the default | mirror the OCaml (pure Z arithmetic, no width) — simpler AND exact; or keep the width path and make `none` a `panic!`. **S** |
| **Z2-M-09** | `CerbMem.lean:2231-2234` two messages `"called isWellAligned_ptrval on void"` / `"… on a function type"` + a `.FunctionNoParams _` arm | `impl_mem.ml:2067-2069` `\| Void \| Function _ -> fail (MerrOther "called isWellAligned_ptrval on void or a function type")`; `FunctionNoParams` falls to `alignof ref_ty` = `assert false` (`:216-218`) | = charter **Z-21** + a crash-vs-Error class difference on FunctionNoParams | TEXT for the two messages; FunctionNoParams UNSETTLED — both probe shapes (`funptr_noparams_deref.c`, `…2.c`) are rejected by the shared front end (constraint violations, both engines) | EXC(a) → mirror; FunctionNoParams arm → mirror as `panic!` (Q4) | one message; `.FunctionNoParams _ =>` panic with the alignof assert text. **S** |
| **Z2-M-10** | `CerbMem.lean:2241` `memReturn (addr % (alignofCtype tagDefs ty).max 1 == 0)` | `impl_mem.ml:2080` `Z.(equal (modulus addr (of_int (alignof ref_ty))) zero)` | `.max 1` clamp | UNREACH (alignof ≥ 1 for every non-void non-function complete type; `empty_struct.c` refutes the alignof-0 route) | declare (or drop the clamp) | drop `.max 1`, cite. **S** |
| **Z2-M-11** | `CerbMem.lean:314` `some (AlignInteger al_n) => al_n.toNat`; `:337` `let x := lastOffset % align`; `:398` `n.toNat * sizeofCtype …`; `:404` `maxOffset % align`; `:419` `maxSize % maxAlign` | `impl_mem.ml:118` `al_n` (Z), `:123` `modulus last_offset align` (Division_by_zero on 0), `:151` `mul n (sizeof …)`, `:169-171`, `:189-191`; `:247/:268` `Z.to_int al_n` (Overflow on huge) | Nat truncation / `% 0` totalisation | UNREACH: alignments come from `alignof` (≥1) or `_Alignas` (front-end validated, ≥1 or a type); array sizes are front-end non-negative; the member-less struct is UB061 (probe) | declare-with-argument (one note for the layout family) | header note. **S** |
| **Z2-M-12** | `CerbMem.lean:2548` `(NDkilled (Other (MerrOther "va_list: index <> 0 (OCaml assert, impl_mem.ml:2760)")), st)` | `impl_mem.ml:2760` `assert (n = 0)` | Error verdict vs crash | UNREACH (declared in-code with the argument: `va_list` is applied only to a fresh `va_start` id) | declared — accept; or mirror as `panic!` for uniformity with Q4 | optional **S** |
| **Z2-M-13** | `CerbMem.lean:2367-2373` `size_n.toNat` (memcmp), `:2338` (memcpy), doc "CLAMPS a negative size_n to 0 … upstream … recurses … forever" | `impl_mem.ml:2652-2660` `Z.to_int size_n` then `\| size -> … (size-1)` | negative size: empty vs non-termination | UNREACH (size_t after conv_int is non-negative) — declared in-code | declared — accept | — |
| **Z2-M-14** | `CerbMem.lean:1257-1259` doc "the CerberusImpl stub returns Signed Int_ — the real per-program enum registry is survey finding 18b, deliberately left a stub" | `CerberusImpl.lean:26-68` IS a registry mirror of `ocaml_implementation.ml:124-150` (`register_enum`/`typeof_enum`, panics on an unregistered tag) | stale doc | — (probe `enum_conv.c` AGREE `Specified(1)`; `enum_underlying.c` both-reject: enumerators > INT_MAX are §6.6#4 violations on the shared front end) | INSTRUMENT (doc integrity) | rewrite the docstring. **S** |
| **Z2-M-15** | `CerbMem.lean:1946-1950` header "the device_ranges list is empty in this pipeline — no device allocations exist" and `:2055` "empty device ranges → always out of bounds" | `impl_mem.ml:620-624` two hard-coded ranges | false statement (= charter Z-06's comments) | — | INSTRUMENT (rides Z-06) | delete with Z-06 |
| **Z2-M-16** | `CerbMem.lean:142` `lastUsed : Option StorageInstanceId := none` — never written (grep: no writer) | `impl_mem.ml:1262,1282,1507,1541,1567,1687` write `last_used`; the only READ is `:2997` (`serialise_mem_state`, UI JSON) | state field never maintained | UNREACH (no exec-path reader; PNVI-ae-udi and the UI are the consumers) | declare-with-argument | one comment on the field. **S** |
| **Z2-M-17** | `CerbMem.lean:1955-1965` `isAtomicMemberAccess` (pure) | `impl_mem.ml:698-702` additionally `Printf.fprintf stderr "addr: %s <--> alloc.base: %s\n"` / `"\|lvalue_ty\|: …"` on the TOOL's stderr | two tool-stderr lines | **C** for the tool stream only; verdict identical — PROBED `atomic_member_stderr.c`: all three `UB042_access_atomic_structUnion_member`; oracle stderr carries `addr: 281474976710644 <--> alloc.base: 281474976710644` / `\|lvalue_ty\|: 4 <--> \|alloc\|: 8` | INSTRUMENT (not the program's `stderr:` field; any lane that byte-compares merged tool output must know) | note in-code; no mirror (the batch contract is the verdict line) |
| **Z2-M-18** | `CerbMem.lean:2036-2041` ill-typed-store guard — "OCaml's diagnostic printfs (:1674-1680) are not mirrored" | `impl_mem.ml:1674-1680` four `Printf.printf "STORE …"` lines on the TOOL's STDOUT before `fail (MerrOther "store with an ill-typed memory value")` | tool-stdout lines precede the Error line on the oracle | UNREACH (Core typing forbids an ill-typed store; declared in-code) | declared — accept | — |
| **Z2-M-19** | `CerbMem.lean:1440-1444` `eqIval/ltIval/leIval … some (…)` | `impl_mem.ml:2556-2562` `Some (Z.equal …)` / `Some (Z.compare … = -1)` / `Some (cmp = -1 \|\| cmp = 0)` | none — VERIFIED total `some` both sides (charter Z-59's tripwire premise) | — | verified-matching | add the `#guard`/unit test Z-59 asks for. **S** |
| **Z2-M-20** | `CerbMem.lean:2118-2136` `eqPtrval` — `SW_strict_pointer_equality` branch (`impl_mem.ml:1852-1853`) not ported; `:2152-2181` relationals — `SW_strict_pointer_relationals` (`:1889-1895` etc.) not ported; `:2193-2218` `diffPtrval` — `SW_pointer_arith PERMISSIVE` (`:1970-1975`) not ported; `:1901-1927` `killM` — `SW_forbid_nullptr_free` (`:1466`) / `SW_zap_dead_pointers` (`:1511,1547`) not ported; `:1850` `allocateObject` — `SW_zero_initialised` (`:1310`) not ported; `:1967` `loadM` — `SW_strict_reads` (`:1593`) not ported; `:2281` `ptrfromint` / `:2294` `intfromptr` — `is_PNVI ()` arms (`:2147-2160`, `:2445-2452`) not ported | — | each is a switch-conditioned arm | REFUSED (Z-24: switches are refused, not plumbed; the DEFAULT set is what matters — §2.10's table) | declare-with-argument per site, pointing at §2.10 | one header note listing the seven switches + the default table row. **S** |

#### 2.1.2 Charter rows Z-09…Z-23 re-verified at the current lines

| id | current Lean cite | OCaml cite (verified) | verdict of the re-read |
|---|---|---|---|
| Z-09 | `:2288` `if n == 0 then memReturn (.PV .Prov_none (.PVnull refTy))` (regardless of `prov`) | `:2161-2172`: `Prov_none` → device check → `n = 0` → null → concrete; `\| _ -> return (PV (prov, PVconcrete (None, n)))` (a provenance-carrying 0 stays concrete) | CONFIRMED; also the device arm (:2164-2166) is missing here = Z-06's second site |
| Z-10 | `:1912-1913` `if st.deadAllocations.contains allocId then fail_ (MerrUndefinedFree Free_dead_allocation)` (both `isDynamic` values) | `:1527-1532` `if is_dyn then fail … Free_dead_allocation else failwith "Concrete: FREE was called on a dead allocation"` | CONFIRMED (Q4: mirror the `failwith` as a fail-stop) |
| Z-11 | `:1915` `\| none => fail_ (MerrUndefinedFree Free_non_matching)` | `:1534` `get_allocation ~loc alloc_id` → `:669-675` `fail ~loc (MerrOutsideLifetime …)` → UB009 (`mem_common.lem:249-250`) | CONFIRMED (UB code differs) |
| Z-12 | `:1907-1909` `PVnull` → `if isDynamic then (NDactive (), st) else fail_ (… Free_non_matching)` | `:1465-1469` `if has_switch SW_forbid_nullptr_free then fail MerrFreeNullPtr else return ()` (both `is_dyn`) | CONFIRMED; UNREACH from C (a non-dynamic `kill` only ever receives the created object's pointer) — mirror anyway; `SW_forbid_nullptr_free` default → §2.10 |
| Z-13 | `:1855-1856`, `:1883-1884` | `:1289`, `:1247-1257`, `:1420` | CONFIRMED — see Z2-M-05 for the sharpened reachability |
| Z-14 | `:1850` `(_ : Option Int)` — `req_addr_opt` ignored | `:1291-1295` `Some addr -> failwith "TODO: cerb::with_address() is yet implemented"` | CONFIRMED (fork-only `cerb::with_address` attribute; UNREACH on upstream inputs) |
| Z-15 | `:1890` `prefix_ := pref` | `:1429` `{prefix= Symbol.PrefMalloc; …}` (argument `pref` unused, `:1428` TODO) | CONFIRMED; the prefix reaches only `prefix_of_pointer` (Z2-M-06, trace-only) and the `is_locking` readonly kind (`:1704-1710`) — a `realloc`'d region is never `store`d with `is_locking`; UNREACH in batch, mirror anyway |
| Z-16 | `:510-516` `intToBytes` (no range assert); `:518-535` `bytesToInt` (no `[]`/`>16` asserts) | `:1096-1113` `bytes_of_int` `assert false` on out-of-range or `nbits > 128` (preceded by a `Printf.printf "failed: bytes_of_int…"` on the TOOL's stdout); `:739-760` `int_of_bytes` asserts on `[]` and `> 16` bytes | CONFIRMED; UNREACH (`conv_int` precedes every store; loads are sizeof-sliced) — mirror the asserts as `panic!` |
| Z-17 | `:2309-2310` `effArrayShiftPtrval … := memReturn (arrayShiftPtrval …)`; `:1513` `panic! "array_shift_ptrval: shift on null pointer is UB"` | `:2244-2356` `eff_array_shift_ptrval`: null → `fail ~loc MerrArrayShift` (UB046); `offset = sizeof ty * ival` (NO void byte-granularity — `sizeof void` is `assert false`, unlike the pure `:2203-2207` GNU arm); `PVconcrete (None, shifted)` drops the union-member tag; strict/PNVI bounds arms | CONFIRMED with two more deltas (void, member tag); REFUSED (`PtrArrayShift` only under strict/PNVI/CHERI, translation.lem:2112-2119) — port the OCaml function |
| Z-18 | `:957` `if elemSize == 0 then .MVarray []` | `:986-994` `aux (Z.to_int n)` always builds `n` elements | CONFIRMED; UNREACH (zero-sized element types are rejected: `empty_struct.c` UB061; `int a[0]` S8) |
| Z-19 | `:937` `\| none => .MVunspecified ty` (pointer arm) | `:1056-1057` `MVunspecified (Ctype ([], Pointer (no_qualifiers, ref_ty)))` | CONFIRMED; the ctype text is not verdict-reachable by the cast route (probe `unspec_const_ptr.c`: all three `Unspecified('signed int')`); `ctype_mem_compatible` erases qualifiers, so the store guard cannot see it either — mirror anyway (S) |
| Z-20 | `:2401-2404` `failReason (MerrOutsideLifetime …)` with the DEFAULT loc `other "Concrete"` | `:2683` `get_allocation ~loc:(Cerb_location.other "Concrete.realloc")` | CONFIRMED; UNREACH (a dynamic, non-dead address always has its allocation) — pass the loc anyway |
| Z-21 | `:2231-2234` | `:2067-2069` | CONFIRMED → Z2-M-09 |
| Z-22 | `:1765-1770` `deriveCap … := v1`, `capAssignValue … := v`, `nullCap … := integerIval 0`, `ptrTIntValue … := iv`, `cheriPointerHashPrintf … := ""`, `getIntrinsicTypeSpec … := none`; `:2554` `callIntrinsic … := memReturn none` | `:2175-2191` all `assert false (* CHERI only *)` | CONFIRMED (values where the oracle fail-stops); REFUSED (CHERI) — mirror as `panic!` |
| Z-23 | the six charter sites at `+6`: `:569` cites `impl_mem.ml:1200` (def is `:1202` `let padding_byte _ = AbsByte.v Prov_none None`); `:2181` diff_ptrval `1954-1984` ✓; `:2317` memcpy `2635-2646` ✓; `:2350` memcmp `2662-2664` ✓; `:2395` realloc `:2675/:2678` ✓; `:2431` update_prefix `1349-1362` ✓ | — | five of six already corrected in-tree; ONE stale (`:569` → `:1202`). Additional stale statements: Z2-M-14, Z2-M-15, and `:1322-1327` (Z2-M-01's false "unreachable") |

Noodle's D-rows re-read (Z-05…Z-08): each confirmed at the cited OCaml
lines (`copy_alloc_id` :2766-2770; the device arms :2164-2167/:1611-1617/
:1718-1724; `kill` :1470-1476 and the :1518→:1527→:1534 order); no new
detail beyond Z2-M-02's `case_ptrval` dependency on Z-06 and the `free_funptr.c`
witness (`free((void*)main)` is the `Prov_none` arm, not the `PVfunction`
arm — a function pointer stored through `void*` re-enters as
`PVconcrete` with `Prov_none`, so the `PVfunction` arm of `kill` is UNREACH
from C).

### 2.2 `CerbND.lean` (471) vs `smt2.ml` `runND` + `frontend/model/nondeterminism.lem` + `driver_ocaml.ml` `batch_drive`

(`frontend/model/nondeterminism.lem` is the one built — `Makefile:177`
`LEM_SRC_AUX`; `frontend/concurrency/nondeterminism.lem` is not in the list.)

| id | finding | evidence | class |
|---|---|---|---|
| **Z2-N-01** (trace ORDER) | identical enumeration order on both sides | reading (reader B, re-verified): `smt2.ml:75-82` `foldlM (fun acc (idx,(info,m_act)) -> aux m_act st' >>= fun z -> return (z @ acc)) []` gives `R_{n-1} @ … @ R_0`; `NDbranch` `xs1 @ xs2` (`:132`); `CerbND.lean:123-125/:141-143` `branches.foldl (fun acc (_, branch) => runNDFuel fuel branch st' ++ acc) []`, `:136` `left ++ right` — same shape. PROBED `tests/z2-probes/nd/order3.c` (6 traces, distinct values): fork = upstream = Lean `EXECUTION 0..5` = `129, 138, 219, 237, 318, 327` in that order; `order2.c` `12, 21`; `order_ptreq.c` 2 traces both sides | verified-matching (the charter's open question is CLOSED) |
| **Z2-N-02** (`--first` vs the oracle's single trace) | the oracle's DEFAULT `--mode` is `Random` (`backend/driver/main.ml:438-441` `Arg.(value & opt (enum ["exhaustive", Exhaustive; "random", Random]) Random & info ["mode"] …)`; `smt2.ml:23-31,68,109-116` `Random.int (List.length xs)`, PRNG self-initialised `driver_ocaml.ml:153,194`); Lean `--first` = `runND1Fuel` (`CerbND.lean:190-221`) takes index 0 / `left` at every choice point | PROBED on `order3.c`: oracle no `--mode` ×3 → `327`, `138`, `318`; `--mode=random` ×5 → `138, 237, 129, 138, 318`; Lean `--first` ×3 → `327` (= the LAST line of the exhaustive order on both engines). Nothing enforces the lanes' "single-verdict programs only" precondition for `--first` pairs (comment-only: `test_libxml2.sh:22-27`, `test_gcc_oracle.sh:28`, `CerbND.lean:165-177`) | INSTRUMENT — no execution discrepancy; recommend (i) a spot-check that `--first` fixtures have exactly one exhaustive verdict, (ii) a help-text note that `--first` follows the first branch (printed last) |
| **Z2-N-03** (= Z-59) | `NDguard`/`NDbranch` pruning: unreachable by construction | `NDbranch` producer `ifM` only in `defacto_memory.lem` (not linked); `NDguard` producer `addConstraints` only at `driver.lem:148` under `PEconstrained`, whose sole origins are the `Nothing` arms of `Mem.eq_ival/lt_ival/le_ival` (`core_eval.lem:355,375,389,404,419`), total `Some` at `impl_mem.ml:2556-2562` and total `some` at `CerbMem.lean:1440-1444` (Z2-M-19); `smt2.ml:42-44`'s `NDactive` `check_sat` failwith likewise unreachable (`runEff (ma true)`, `impl_mem.ml:340`) | Z2-DISPOSED: rewrite `CerbND.lean:5-14,127-136` from "recorded divergence — not implemented" to "unreachable by construction" with these cites; add the `#guard` on Z2-M-19. **S** |
| Z2-N-04 (= Z-73) | `NDnd []` → Lean `Error {…}` exit 1 vs oracle silent exit 0 | UNREACH: `msum []`/`pick []` are `error` on both sides (`nondeterminism.lem:139-140,191-193`; generated `Nondeterminism.lean:246,277` `failwithI`) | declared (RULED Q8 = A) |

### 2.3 `Main.lean` (1151) vs `backend/driver/main.ml` / `pipeline.ml` / `driver_ocaml.ml`; `CerbPP.lean` (238) + the CerbMem printers vs `pp_core.ml`/`pp_symbol.ml`/`pp_mem.ml`

Verified byte-identical by reading (reader B; I re-read the renderer
sites): `Defined {value: "%s", stdout: "%s", stderr: "%s", blocked: "%s"}`
(`driver_ocaml.ml:99-102` ↔ `Main.lean:922`), `Undefined {ub: "%s", stderr: "%s", loc: "%s"}`
(`:123-127` ↔ `:930`), `Error {msg: "%s"}` unescaped both (`:142-144` ↔
`:932`), the `EXECUTION %d:` header only when > 1 execution (`:72,:96` ↔
`:916-919`), the verdict mapping (Active→Defined; `Undef0 (loc, [])` →
`Error "[empty UB, probably a cerberus BUG]"` both; `Error0`→msg;
`Other`→`Show mem_error`), exit codes (single Defined→0 incl.
Unspecified, single Undefined/Error→1, multiple→0, front-end failure→1;
`main.ml:189-207,180-182` ↔ `Main.lean:938-941,556/587/849`; the harness
`scripts/test_exec.sh:364-372 expected_exit_for` encodes the same),
`Specified(n)` = `Z.to_string` at debug < 3, `Unspecified('<ctype>')`
(`pp_core.ml:307-308` ↔ `CerbPP.lean:92`), `Pp_core_ctype.pp_ctype` arm for
arm, `pp_symbol` `to_string`/`to_string_pretty`, pointer/provenance/
mem-value printers, `comma_list` = `", "` (flat `IfFlat` arm of
`PPrint.ToBuffer.compact`), the per-file link fold and `Core_linking.link`
order (libc first), default `core_passes` = identity
(`Core_indet.hackish_order`, `core_indet.lem:502-504`), `.co` libs skip
`core_passes`, `--args` split on `[ \t]+` with `"cmdname"` prepended
(`main.ml:111-113`, `pipeline.ml:604` ↔ `Main.lean:1049-1051,894`),
`Tags.set_tagDefs` from the LINKED file before exec ↔ the reader-passed
`runFile.tagDefs`. Z-61: every `<core_expr>`/`<core_pexpr>`/`<core_state>`
placeholder call site in the exec cone (`core_run.lem:826,1358,1416,1486`,
`core_eval.lem:122,518-522,568,720,977,1010`, `core_reduction.lem:274,332,
1004,1212,1459`, `driver.lem:1457,1486,1497`, `core_aux.lem:1475,2419`)
feeds an `error`/`Illformed_program`/debug string → `Error {msg}` text or
nothing; none feeds a `Defined`/`Undefined` field — CONFIRMED (EXC(a)).

| id | Lean | OCaml | differs | reach | class | fix + price |
|---|---|---|---|---|---|---|
| **Z2-P-01** | `Main.lean:366-373` `batchEscape`: `"`→`\"`, `\`→`\\`, `\n`,`\t`,`\r`; `else String.singleton c` | `driver_ocaml.ml:101` `(String.escaped stdout) (String.escaped stderr)`; OCaml `Bytes.escaped` (`_opam/lib/ocaml/bytes.ml` `unsafe_escape`): `'"' \| '\\' \| '\n' \| '\t' \| '\r' \| '\b'` → 2 chars, `' ' .. '~'` verbatim, everything else `\ddd` DECIMAL per byte | control bytes raw vs escaped; `\b` raw vs `\b`; every byte ≥ 0x7F raw (and re-encoded as UTF-8: the Lean io strings hold one char per program byte, so 0xC3 0xA9 becomes 4 output bytes) vs `\195\169` | **C** — PROBED `tests/z2-probes/main/stdout_escape.c`: oracle ×2 `stdout: "a\bb\007\127\195\169\011\012\027\|\n"`; Lean `stdout: "a^Hb^G^?M-CM-^CM-BM-)^K^L^[\|\n"` (`cat -v`); `stderr_escape.c`: `stderr: "E\b\007\255\|"` vs `"E^H^GM-CM-?\|"`. Unseen by every lane because the extractors keep the `value:` token only (charter §4.1) | **BUG-FIX** (stdout/stderr bytes are verdict content) | rewrite `batchEscape` over the chars' codes (0..255) with the `unsafe_escape` classes, cite bytes.ml. **S**. Rides §4.1's whole-line comparison |
| Z2-P-02 (= Z-03/Z-01) | `Main.lean:930` (also `:553,:584`) `loc: \"{CerbLocation.stringFromLocation loc}\"` — the `location_to_string` family (`CerbLocation.lean:193-205`) | `driver_ocaml.ml:126` `Cerb_location.simple_location loc` (`util/cerb_location.ml:476-490`: `"%d:%d"` / `"<%s--%s>"` first region only / `"<unknown location>"` / `"<other location: str>"`) | printer family | **C** on every UB line (every UB probe in this record shows it, e.g. `<5:28--5:48>` vs `unknown location` / `tests/z2-probes/…:6:1-12`) | cross-ref BUG-FIX Z-03 (Z1) | note for Z1: `simple_location` uses `List.hd` on the region list — `Loc_regions ([], _)` would raise; reachability of that shape on the batch path is unsettled |
| Z2-P-03 (= Z-72) | `Main.lean:930` literal `stderr: \"\"` | `driver_ocaml.ml:176-178` `String.concat "" (Dlist.toList dr_st.…io.stderr)` | program stderr dropped on UB lines | **C** | cross-ref Z-72 (Z1) | `io_state.stderr` is available on the killed state (`generated/Core_run_aux.lean:317`) |
| Z2-P-04 | `CerbLocation.lean:197-200` `.region p1 p2 _ => …` (cursor ignored) | `util/cerb_location.ml:219-223` appends `" (cursor: " ^ … ^ ")"` for `PointCursor`/`RegionCursor` | the `location_to_string` mirror drops the cursor suffix | TEXT (reaches `Error {msg: …}` via `Illformed_program ("[" ^ Loc.stringFromLocation loc ^ "] …")`, core_eval.lem:499) | EXC(a) — undeclared mirror gap; mirror (S) or declare |
| Z2-P-05 (= Z-04) | `Main.lean:405-413` `driverErrorBatchMsg` (`Illformed_program: …` etc.) | `pp_errors.ml:499-509` `"ill-formed program: \`" ^ str ^ "'"`, `"found an empty stack: …"`, `"reached the end of a procedure"`, `"unknown implementation constant"`, `"unresolved symbol: … at …"` | Error text | TEXT | EXC(a), declared; the five strings are plain concatenations (only `Pp_ail.pp_id` needs a mirror) — cheap to close. **S** |
| Z2-P-06 (= Z-74) | `Main.lean:555,586,848,617,1144` front-end/link/libc/json failures → `Error {msg: …}` on STDOUT, exit 1 | `main.ml:180-182` `prerr_endline (Pp_errors.to_string err); epilogue 1` (stdout empty) | channel + presence of a verdict line | failure class identical | declared (Z-74); optional stderr mirror **S** |
| Z2-P-07 (= Z-24) | `Main.lean:993-994,998-1042` unknown flags → file names | `main.ml:323-560` cmdliner (`--switches`, `--mode`, `--iso`, `--charon-batch`, `--json-batch`, …) | not loudly refused | — | cross-ref Z-24 (Z1) |
| Z2-P-08 | Lean prints nothing on the tool's stderr in batch | `main.ml:159-160` `Printf.fprintf stderr "Time spent: %f seconds\n"` | tool stderr | not behaviour | note (lanes already filter `^Time spent`) |

Z-76-shape literals in these files (values agree today; §3 lists them):
`Main.lean:772` impl path; `:759` `"/std.core"` (+`:486-496` runtime dir
candidates) where `pipeline.ml:32-35` picks `std_inner_arg_temps.core`
under `SW_inner_arg_temps`; `:571` `Normal_callconv` where `pipeline.ml:266-267`
is switch-dependent; `:894` concurrency `false` where `main.ml:308` reads
the flag; `:879` `CerbFS.fs_initial_state` where `pipeline.ml:597-599`
reads `--fs`; `CerbDebug.lean:28` `get_level … := 0` read by
`CerbMem.lean:1601` (`name{n}` at level > 4) and `:1720` (`<@prov>:n` at
level ≥ 3) where the oracle reads `!Cerb_debug.debug_level` (default 0,
`main.ml:105`); `CerbMem.lean:2118-2136` the un-ported
`SW_strict_pointer_equality` branch where `main.ml:137-143` `Switches.set
switches` (default `[]`).

### 2.4 `CerbCall.lean` (231) vs `scripts/test_verify.sh render_wrapper` + `translation.lem` call-site protocol

(reader D; both C-observable rows PROBED, `tests/z2-probes/call/README.md`.)

| id | Lean | oracle twin | differs | reach | class | fix + price |
|---|---|---|---|---|---|---|
| **Z2-C-01** (= Z-60) | `CerbCall.lean:36-40` header "the call-site `conv_int` range conversion is NOT reproduced — an injected integer must fit the parameter type (out-of-range injections are the caller's responsibility)"; `:94-103` `memValueFromValue … CerbMem.storeM` (raw store) | wrapper TU call site: `translation.lem:948-953` `mkcall_conv_loaded_int_` → `std.core:32-33` (`_Bool`: `n = 0 → 0 else 1`; others `wrapI`/`is_representable`) | unenforced contract = fail-OPEN | `--call` harness only. PROBED `bool_param.c` `--call-args 2`: Lean `Undefined {ub: "UB012_lvalue_read_trap_representation", …}`; fork/upstream wrapper `Defined {value: "Specified(1)", …}` | **BUG-FIX** (instrument fail-closed rule) | refuse loudly (kill with an attributed message) any injection outside `[Ivmin, Ivmax]` of the parameter type or a `_Bool` ∉ {0,1} — **S**; or reproduce `conv_int` — **M** |
| **Z2-C-02** | `CerbCall.lean:182-184` errno `allocateObject … (PrefOther "errno")` inside `callFinish`, i.e. AFTER `injectArgs` (`:227-229`) | `driver.lem drive` allocates errno BEFORE the arena is set; the wrapper `main`'s argument temporaries are `pcreate`d later (`translation.lem:964-966`) | allocation ORDER → parameter addresses/alloc-ids | `--call` only. PROBED `errno_order.c`: Lean `Specified(65528)`, both wrapper oracles `Specified(65524)` (4 bytes = the errno object) | **BUG-FIX** (harness fidelity) | allocate errno first in `driveCall`. **S** |
| Z2-C-03 | `CerbCall.lean:94-96` a non-fitting value → `kill (Other (DErr_other "driveCall: argument value does not fit the parameter type"))`; floating parameters not supported | `translation.lem:954-958` `fvfromint` conversion | loud but not feature-ATTRIBUTED | `--call` | declare/attribute the message (**S**) |
| Z2-C-04 | `:99` `PrefOther "driveCall arg"` | `translation.lem:965` `PrefFunArg …` | prefix (only `selectRoKind` on locking stores — never, `:103` `false`) | UNREACH | declare |
| Z2-C-05 | `:205` returns `f`'s raw Core value | the wrapper's `main` applies `int` conversion and rejects non-int-convertible returns | lane contract | self-detecting (the three-way check fails) | INSTRUMENT: state "int-returning, integer-parameter functions only" in both the header and test_verify.sh (**S**) |

### 2.5 `CerbFS.lean` (347) — cross-check only (Z1 owns the op-by-op table)

Entry-point classification (reader D, line: word): `fs_open` :142 RESIDUAL /
REFUSED :166; `fs_close` :170 SERVED; `fs_write` :182 SERVED / REFUSED :200;
`fs_read` :202 SERVED / REFUSED :221; `fs_mkdir` :223, `fs_chmod` :273,
`fs_chdir` :276, `fs_chown` :279, `fs_rmdir` :291 RESIDUAL no-ops;
`fs_pwrite` :226 / `fs_pread` :243 SERVED / REFUSED :241/:260; `fs_rename`
:262, `fs_truncate` :294, `fs_unlink` :301 RESIDUAL; `fs_umask` :269
RESIDUAL; `fs_link` :282, `fs_readlink` :285, `fs_symlink` :288 ENOSYS;
`fs_lseek` :307 RESIDUAL; `fs_stat` :326 / `fs_lstat` :332 RESIDUAL;
`fs_opendir` :335, `fs_readdir` :339, `fs_rewinddir` :342, `fs_closedir` :344
RESIDUAL. All 25 `fs.lem:73-171` ops present with matching arities; the errno
path (`driver.lem` `store_error` → `translate_errno ("__cerbvar_" ^ name)`)
shares the lem table (EACCES 5, EBADF 11, EEXIST 22, EINVAL 29, ENOENT 46,
ENOSYS 56; unknown → loud `error`). Residuals the charter's Z-27 list MISSES
(for Z1's table; the first PROBED):

| id | Lean | expected (POSIX/SibylFS) | evidence | class |
|---|---|---|---|---|
| **Z2-F-01** | `CerbFS.lean:311-318` `fs_lseek` invalid `whence` → `\| _ => entry.offset` (success) | EINVAL / −1 | PROBED `fs/lseek_whence.c`: oracles `Specified(9)`, Lean `Specified(13)` | **BUG-FIX** (silent absorption) — add to Z-27 |
| Z2-F-02 | `:314-317` `SEEK_END` on an fd whose path no longer resolves → `entry.offset + offset` | EBADF/inode size | reading | BUG-FIX (fail-open) — Z-27 |
| Z2-F-03 | `:187,:231` `(lookupFile st entry.path).getD []`; `:208` read after unlink → ENOENT | POSIX keeps the open inode; the path must not reappear | reading (write after `unlink` re-creates the path) | BUG-FIX (`getD`) — Z-27 |
| Z2-F-04 | `:335-337` `fs_opendir` fd not registered; `:344-345` `fs_closedir = fs_close` → EBADF | 0 | PROBED `fs/closedir.c`: BOTH oracles crash `Failure("internal error: can_advance: Step_error2 ==> …the value of a store(signed int*) didn't match the lvalue type: Specified(1)")`; Lean panics with the same text and `Specified(3)` — both-crash EXC(a); the EBADF outcome is not reachable via `opendir`/`closedir` from C | EXC(a); the embedded fd (1 vs 3; `CerbFS.lean:100 nextFd := 3`) is a Z-76-shape fs literal |
| Z2-F-05 | `:182` `fs_write` ignores `size` | SibylFS bounds by `size` | reading; settles only if `\|buf\| ≠ size` can arise at `core_run.lem:1240-1245` | INSTRUMENT |
| Z2-F-06 | `:269-271` `fs_umask` stores the raw int; `:102 umask := 0o022`; `:70-71 mode := 0o644`, `nlink := 1` vs header `:44-45` "zeroed fields except size" | SibylFS state values | reading | Z-76-shape literals (fs model) + header fix |
| Z2-F-07 | `:301` `fs_unlink` of a missing path → 0 | ENOENT | reading | BUG-FIX — Z-27 |

### 2.6 `CerberusFresh.lean` (176) vs `util/cerb_fresh.ml` + `Digest` (Z-64)

Reader C, re-verified: the hex-vs-raw ORDER isomorphism claim
(`CerberusFresh.lean:17-21`) is CORRECT — lowercase hex is a monotone
byte-wise encoding of equal-length digests, so `compare` on hex agrees with
`Digest.compare = String.compare` (`digest.ml:71`) on raw bytes; Z-64's
"only `compare = 0` is consumed" is therefore not even needed. What DOES
differ is the digest VALUE: the oracle digests the `.c` file
(`cerb_fresh.ml:88-95` `Digest.file filename`), Lean digests the cabs-json
text (`Main.lean:625,641,820` `setDigestIO (md5Hex content)`), so the relative
order of two TUs' digests — hence the iteration order of any sym-keyed
`Map`/`Set` mixing symbols from different TUs (`symbol.lem:157-160`
`symbol_compare` orders by digest first) — can differ. Reachability: multi-TU
only, and only through an order-sensitive exec-path iteration, of which none
was found (`file.globs` is a list; `core_linking.lem:294` uses `union`). Row
**Z2-D-01**: INSTRUMENT — grep-audit `Map.fold/bindings/Set.toList` over sym
keys on the exec path (or digest the same artefact). Also the absolute
`fresh_int` numbering differs (process-global supply incl. std.core parsing
vs Lean's threaded supply) — visible only in `Unresolved_symbol`/
`Illformed_program` texts (EXC(a), = Z-04's embedded ids).

### 2.7 `CerbUtils.lean` (182) / `CerbDebug.lean` (42) vs `ocaml_gcc_builtins.ml`, `cerb_debug.ml`, `cerb_any.ml` (Z-66)

Reader C, verified: the oracle's debug level is `0` in matched mode
(`cerb_debug.ml:27 let debug_level = ref 0`, set only by `-d`,
`main.ml:105,343-345`); `print_debug` (level ≥ 1), `warn` (level > 1 unless
`~always`, used only at `main.ml:139`), `output_string2` (level > 0) are all
silent at 0 → Z-66 CONFIRMED; the CerbMem printers' level-gated arms
(`:1601` `name{n}` at > 4, `:1720` `<@prov>:n` at ≥ 3) are inert on both
sides. GCC builtins mirror per line (`ffs`, `ctz` (0 is UB-guarded at
`std.core:818-819`), `bswap16/32/64` asserts, `is_power_of_two`). Two rows:

| id | finding | class |
|---|---|---|
| Z2-U-01 | `CerbDebug.lean:38` `print_unsupported (_ : String) : Unit := ()` vs `cerb_debug.ml:43-45` unconditional `prerr_string "unsupported: "…` — reached only on `translation_effect.lem:250-265` `record_error` → `error` crash paths | EXC(a) (tool stderr on a both-crash path) |
| Z2-U-02 | `CerbUtils.lean:71-76` `boundedIntegerImpl lo hi := pure lo` vs `util/cerb_any.ml:1-9` `Random.self_init (); Random.int64 …` — the ORACLE is non-reproducible here (`any_bounded_int`, `core_run.lem:1063-1068`, `<any.h>`) | declare-with-argument (no matchable oracle value; state it in-code) |

### 2.8 `CerbLocation.lean` (207) vs `util/cerb_location.ml` / `cerb_position.ml(i)`

Reader C, verified against my UB probes: rendering is Z-03 (Z2-P-02);
`isLibraryLocation` is Z-67 (confirmed; extra detail: `libc/include/posix/*.h`
is NOT library for the oracle — `Hashtbl.mem excluded (Filename.dirname
path)` over exactly `in_runtime "libc/include"`, `"libcore"`,
`"libcore/impls"`, `cerb_location.ml:512-523` — but IS for Lean's
segment test `:180-185`; practically unreachable since the posix headers
carry no function bodies). The UB-location substitution
(`core_eval.lem:596-603`, `core_run.lem:778-784`) uses only
`is_library_location` — no region arithmetic is involved, so D1's fix needs
no CerbLocation arithmetic beyond the runtime-prefix mirror. Remaining rows:
**Z2-L-01** = Z2-P-04 (cursor suffix dropped; TEXT); Z2-L-02 `posLt`
(`:116-118`) tie-breaks same-line positions by column where the OCaml
(`:109-114`) uses `pos_cnum` — equal unless two positions share a source
line from different preprocessed lines (cosmetic; declare); `outer_bbox []`
→ `assert false` vs `(default, default)` (`:122`) and `regions [] _` →
`failwith` (`:33-36`) has no Lean constructor guard (`CabsImport.lean:131`
builds `.regions` from JSON directly) — UNREACH, declare; Z2-L-03 the
structural `Ord Loc` (`:13-17,63-74`) vs OCaml polymorphic compare on a
differently-ordered record — no Loc-keyed set iteration in the exec cone
(declared `:44-46`).

### 2.9 `CerbGlobal.lean` (146) / `CerbConcurrency.lean` (33) — THE SWITCH-DEFAULT TABLE

How the oracle populates switches (reader C, verified): `main.ml:129-143` —
`switches` defaults to `[]` (`:531-533`), `is_cheri_memory ()` false for the
concrete model, `iso_switches` false ⇒ `Switches.set []` ⇒ `internal_ref =
[]` (`switches.ml:47-48`); `has_switch sw = List.mem sw !internal_ref`
(`:54-55`) ⇒ FALSE for every switch; nothing is implied on by default
(`set_iso_switches` `:144-151` only under `--iso`). Config `main.ml:124`
`set_cerb_conf ~backend_name:"Driver" ~exec exec_mode ~concurrency QuoteStd
~defacto ~permissive ~agnostic ~ignore_bitfields`, all flags default false;
`exec_mode` default `Random` (`:438-441`).

| read site (exec cone) | oracle default | Lean | match |
|---|---|---|---|
| `SW_inner_arg_temps` — `core_run.lem:954,964`, `translation.lem:4329,4365,4380`, `mini_pipeline.lem:139`, `pipeline.ml:34,267` | false | `CerbGlobal.has_switch` over `switchesRef = []` → false | yes |
| `SW_permissive_printf` — `formatted.lem:705` | false | false | yes |
| `SW_strict_reads` — `impl_mem.ml:1593`, `pipeline.ml:573` | false | not ported (`CerbMem.lean:1971`) | yes (fixed at the default) |
| `SW_forbid_nullptr_free` — `impl_mem.ml:1466` | false | not ported | yes |
| `SW_zap_dead_pointers` — `impl_mem.ml:1510,1544` | false | not ported | yes |
| `SW_zero_initialised` — `impl_mem.ml:1310` | false | not ported | yes |
| `SW_strict_pointer_equality` — `impl_mem.ml:1852` | false | not ported | yes |
| `SW_strict_pointer_relationals` — `impl_mem.ml:1889-1939` | false | not ported | yes |
| `SW_pointer_arith PERMISSIVE/STRICT` — `impl_mem.ml:1970,2265-2350` | false | not ported | yes |
| `SW_PNVI *` / `is_PNVI` — `impl_mem.ml:627-638,765,1022,1562,2146,2446`; `translation.lem:2112,2249,3178` | false | `is_PNVI_impl := false` (`CerbGlobal.lean:107`) | yes |
| `has_strict_pointer_arith` — `translation.lem:2112,2249,2939,3178` | false | `:= false` (`:109`) | yes |
| `is_CHERI` — 32 generated reads | false | `has_switch .cheri` → false | yes |
| `SW_copy_prop` — `pipeline.ml:580` | false | n/a (pass not run on either side by default) | yes |
| `SW_at_magic_comments`, `SW_magic_comment_char_dollar`, `SW_revocation` | false; no exec-cone read | — | yes |
| `SW_no_integer_provenance` | constructor ABSENT from `switches.ml:1-44` (the lem `global.lem:81` target_rep names a non-existent OCaml constructor) | `CerbGlobal.lean:29` `no_integer_provenance` dead constructor | Z2-G-02 (INSTRUMENT: delete) |
| `Global.using_concurrency` — `core_run_aux.lem:342,411,429,494` | false | false | yes |
| `Global.current_execution_mode` — `driver.lem:748` (dead), `:1380` | `Some Exhaustive` under `--mode=exhaustive`; `Some Random` under the bare default | `none` | equivalent at `:1380` under `--mode=exhaustive` (else-branch both); Z2-G-01 |
| `Global.backend_name` — `core_aux.lem:552-553`, `cabs_to_ail_effect.lem:676`, `translation.lem:409,1732,1741,1822,1830,4120`, `translation_effect.lem:231` (all `= "Cn"`/`"Bmc"` tests) | `"Driver"` | `"cerberus-lean"` | yes (both ≠) |
| `Global.isDefacto/isPermissive/isAgnostic/isIgnoreBitfields` — `genTyping.lem:298,1406-1425`, `cabs_to_ail.lem:1779,…,2732`, `cabs_to_ail_effect.lem:2225-2245` | false | false | yes |
| `Cerb_debug.debug_level` — `debug.lem:22` | 0 | `debug.lem:27 get_level u = 0`; `CerbDebug.lean:28` | yes |

Rows: **Z2-G-01** — `CerbGlobal.lean:38` `execMode := none` (never set) vs
`Some Exhaustive`/`Some Random`: equivalent at the one live read
(`driver.lem:1380`) whenever the oracle runs `--mode=exhaustive`; two lanes
(`scripts/test_immaculate.sh:122`, `scripts/test_libc_exec.sh:87`) omit
`--mode`, so the oracle takes the `Random` then-branch there — for
single-threaded programs the unique step is picked either way (no observable
difference), but the lanes should pass `--mode=exhaustive` for the matched
mode's sake (INSTRUMENT, S). **Z2-G-02** — the dead `no_integer_provenance`
constructor (INSTRUMENT, S). `CerbConcurrency.lean:166 statically_satisfied
:= true` — the `.lem` has no OCaml body either (`cmm_csem.lem:654-656`);
reached only under `using_concurrency` (false both) — EXC(c)/Z-25.

### 2.10 `CerberusImpl.lean` (254) vs `ocaml_implementation.ml` `DefaultImpl` (Z-65)

Entry-by-entry (reader C, verified; `MorelloImpl` is installed only under
`is_cheri_memory`, `main.ml:131`): `sizeof_pointer`/`alignof_pointer` 8/8;
`max_alignment` 8 (`:151-152` ↔ `:20`); `sizeof_ity` Char/Bool 1, Ichar/
Short/Int_/Long/LongLong 1/2/4/8/8, IntN_t/least/fast 8/16/32/64 → 1/2/4/8
(OCaml via the alias table `:155-160`, Lean `(n+7)/8` and a nested `if`),
Intmax_t/Intptr_t 8, Enum via `typeof_enum`, Wchar_t/Wint_t 4, Size_t/
Ptrdiff_t 8, Ptraddr_t 8; `sizeof_fty` 8/8/8 (Z-55); `alignof_*` = sizeof
tables; `is_signed_ity` with `~char_is_signed:true` (Char→true, Bool→false,
Size_t→false, Wchar_t/Wint_t/Ptrdiff_t→true, Ptraddr_t→false, Enum via
registry); `precision_ity` 8n−1/8n; `typeof_enum`/`register_enum` = the
GCC rule (`Signed Int_` iff some `n < 0` else `Unsigned Int_`; duplicate →
false; unregistered → crash both) — probe `enum_conv.c` AGREE. Rows:

| id | Lean | OCaml | differs | reach | class | fix + price |
|---|---|---|---|---|---|---|
| **Z2-I-01** | `CerberusImpl.lean:245-252` `normalise_integerType`: no arm for `Signed/Unsigned (IntN_t \| Int_leastN_t \| Int_fastN_t \| Intmax_t \| Intptr_t)` | `ocaml_implementation.ml:37-54` `aux_ibty` aliases them through `type_alias_map` (`:154-171`: 8→Ichar, 16→Short, 32→Int_, 64→Long, Intmax_t/Intptr_t→Long; `Option.get` raises for other n) | `ailTypesAux.lem:302-303` `(Signed (IntN_t _), _) -> fail ()` arms become reachable on Lean | **C** but only via the DIRECT `__cerbty_intN_t`-family spellings (`builtins.lem:11-69`): the shared headers alias `int32_t` to `signed int` (`stdint.h:11`), so ordinary C never produces `IntN_t` — PROBED: `int32_uac.c`/`int32_compat.c`/`int32_printf.c` AGREE; `cerbty_int32_uac.c` oracles `Specified(1)`, Lean exit 134 `PANIC … AilTypesAux.le_integer_range: internal error` | **BUG-FIX** | add the `aux_ibty` arm with the alias table; `panic!` for n ∉ {8,16,32,64} (mirroring `Option.get None`). **S-M** |
| Z2-I-02 | `:251` `\| .Ptraddr_t => .Unsigned .Long` | `:65-66` `\| ity -> ity` (then `le_integer_range` errors "WIP … Ptraddr_t") | Lean computes where the oracle crashes | `ptraddr_t` is `#ifdef __CHERI__` only (`stddef.h:8-10`); direct `__cerbty_ptraddr_t` spelling reachable | declare or mirror the crash. **S** |
| Z2-I-03 | `:101-111` `IntN_t n => (n+7)/8`, `Int_leastN_t n => if n ≤ 8 … else 8` | `:40` `Option.get` raises for n ∉ {8,16,32,64} (`__cerbty_int128_t`, `builtins.lem:19,53`) | value vs crash | direct spelling only (no header typedefs `int128`) | BUG-FIX (mirror crash; fold into Z2-I-01). **S** |
| Z2-I-04 | `:195,199-200,204-210` `alignof_ty` fail paths → `none` | `:446-447,464-466` `assert false`; `:491,509` `Pmap.find` `Not_found` | crash vs `none` | UNREACH (Ail typing rejects sizeof/alignof of void/function/incomplete) | declare-with-argument. **S** |

### 2.11 `CerbFloat.lean` (314) vs `cerb_floating.ml`, OCaml `Float`, `impl_mem.ml:1155/2523-2554` (Z-62)

Reader C, verified + probed (`tests/z2-probes/float/README.md`): `truncToInt`
is bit-exact trunc-toward-zero = `Z.of_float`; NaN/inf crash class matches
UNDER `LEAN_ABORT_ON_PANIC=1` (probe `nan_to_int_nopanicflag.c`: oracles
`Z.Overflow` exit 125, Lean `PANIC at CerbFloat.truncToInt CerbFloat:302:4`
exit 134); finite out-of-range → same exact integer → `std.core:86-90`
UB017 on both; `fvfromint` = `Float.ofInt` is exact-then-single-rounded for
|n| < 2^64 (`OfScientific.lean:36-40`: no truncation when `m.log2 ≤ 63`) =
strtod of `Z.to_string n` (`impl_mem.ml:2549-2551`) — every reachable C
integer is ≤ 64 bits; `eq/lt/le` IEEE on both; byte encoding `bits_of_float`
↔ `toBits`. **Z-62 disposed**: `CerbFloat.floatMul/Add/Sub/Div/of_int/
floatEq/Lt/Le` and the `Ord Float` instance are referenced ONLY from
`generated/Defacto_memory.lean` and `generated/Float.lean` (grep), never from
the concrete cone (`opFval` uses `*` directly, `CerbMem.lean:1458`); no
`Set Float`/`compare` on floats in the exec cone (`AilSyntax.lean:328`
compares the literal STRING) — UNREACH by construction; declare with this
argument (the `cerb_floating.ml:5 let mul = (+.)` oddity is the defacto
model's, not ours). Rows:

| id | finding | evidence | class |
|---|---|---|---|
| Z2-FL-01 | `CerbFloat.lean:152-155` hex-float mantissa rounding claim (reader) | PROBED `hexfloat_round.c`: `Specified(111)` on all three → REFUTED | verified-matching |
| Z2-FL-02 | `CerbFloat.lean:102-130` `parseDecimal` via Lean 4.32 `Float.ofScientific` (truncating `(m<<<k)/5^e`, then 64-bit truncation, then 53-bit rounding — double rounding possible) vs `float_of_string` (strtod, correctly rounded) | PROBED `decimal_sweep.c`: 200 literals, IEEE bit patterns byte-identical on all three → NOT EVIDENCED; the structural risk stays a reading-level claim | INSTRUMENT: larger sweep in Z4's measurement lane, or a correctly-rounded parser as hardening (M) |
| **Z2-FL-03** | every `panic!` that mirrors an OCaml `failwith`/`assert`/exception (`CerbFloat.lean:178,301-302`, `CerberusImpl.lean:62`, `CerbDecode.lean:98-128`, `CerbUtils.lean:130,140,149,166`, the CerbMem panics) is a crash-to-VALUE conversion unless `LEAN_ABORT_ON_PANIC=1`: Lean prints the PANIC and continues with `default` | PROBED: WITHOUT the flag `nan_to_int_nopanicflag.c` → exit 0, `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}` after the PANIC line; every lane sets the flag, `Main.lean` never does (grep `AbortOnPanic`: none) | **INSTRUMENT (fail-closed hygiene), CONFIRMED**: `Main.lean` must refuse to run (or set the runtime flag) unless abort-on-panic is in force; plant: run without the flag, expect the refusal. **S** |

### 2.12 `CerbDecode.lean` (164) vs `ocaml_frontend/decode.ml` (Z-63, R1/R2)

Reader C, verified: `read_digit` callers on BOTH sides are exactly
`decode_integer_constant` (lexer-digit input, `cabs_to_ail.lem:1089`), the
hex/octal escape spans (validated first; the `'0'..'8'` octal quirk
`decode.ml:191` mirrored at `CerbDecode.lean:118`, `read_digit '8' = 8` on
both), and `cerb_attributes.lem:38,74` — a non-digit cannot reach it →
**Z-63 disposed** (declare with this caller set). Character table arms,
`\x` empty → crash both, multi-char/bare `\`/non-ASCII → crash both, `wrapI`
Euclidean form, prefix/basis logic (`0x`/`0b`/leading-`0` octal/bare `"0"`),
`encode_character_constant` low-8-bits — all mirror. `\?` → 63 (`:91`) and
the hex `escaped_char` (`:152-162`) are the ISO-fix register R1/R2 (marked,
not classified here). Rows: **Z2-DC-01** `CerbDecode.lean:30-36` empty-string
input decodes to `(Decimal, 0)` where `decode.ml:7-8,18` `str.[0]` raises
`Invalid_argument` — reachable only via the fork-only
`[[cerb::with_address("")]]` (`cerb_attributes.lem:38,74`); BUG-FIX
(fail-closed panic, S). Z-76-shape: `CerbDecode.lean:47-48` `min := -(2^(8-1))`,
`max := (2^(8-1))-1` hard-code signed `char` where `decode.ml:204-210` reads
`impl.is_signed_ity Ctype.Char` from `Ocaml_implementation.get ()` (values
agree; §3).

### 2.13 `CerbTags.lean` (36) vs `ocaml_frontend/tags.ml` (27)

Reader C: pure type + fail-closed stub (`:33-34` panic); every applied
`tagDefs ()` is reader-lifted (`ctype_aux.lem:31-34`); the oracle sets the
global once at `main.ml:306-307` from the LINKED file and scopes const-expr
runs with `with_tagDefs` (`mini_pipeline.lem:77`); Lean seeds
`runFile.tagDefs` at `Main.lean:894/896`. NOT SETTLED (Z2-T-01): the
libc-mode metadata merge `Main.lean:652-709` (`libcInsertChecked`) is a
hand-written path whose equality with lem `union` on duplicate keys
(`core_linking.lem:294`) was not traced; and the const-expr seed
(`reader_seed run_const_expr_driver` vs `with_tagDefs tds`) is equal by
construction only if the seed is the same `tds` — to verify in the FIX phase
(Z-28 territory).

### 2.14 `CoreParser.lean` (2166) vs `parsers/core/core_parser.mly` (+ `core_lexer.mll`, `core_parser_util.ml`)

Reachability frame (reader A, verified; `tests/z2-probes/coreparser/README.md`):
Lean parses exactly `std.core`, the `.impl` file (both also parsed by the
OCaml grammar) and, in libc mode, the pinned `--pp=core` dump
`tests/libc/libc.core` (the oracle uses the in-memory `libc.co` — a
pp-round-trip class); C TUs are never Core text. Verified-matching (reader
A): lexer classes and every punctuation/operator token; the UB-name path
(`:1096-1102` = `scan_ub` `mll:221-234`: bimap first, `DUMMY(…)` unwrap,
else fail; the SAME generated `ub_str_bimap`; probe `aligned_alloc_bad_size.c`
`DUMMY(align_alloc)` AGREE); every CORE-dialect ctype spelling used by
std.core (21 distinct); core object/base types; the 13-way `ctor` table;
`memory_order`, 20 `memop_op`s; values (`NULL(ty)` → `nullPtrval`,
`INT_CONST` → `integer_ival`); patterns incl. right-assoc `::`; pexprs incl.
binop precedence/associativity for `\/ /\ = > < >= <= + - :: * / rem_t rem_f`
(`:755-763` = `.mly:1189-1195`); exprs incl. `save`/`run`/`unseq`/`bound`;
actions incl. `kill('ty', pe)` → `Kill (Static0 ct)`; declarations incl.
`proc [ailname]`, `glob`, `def struct/union` with the FAM rule; the ailnames
map. Every `IV*`/implementation-constant production checked (the Z-76
mandate): `IvMaxAlignment` is the one literal (Z-76 itself); `Ivmax`/`Ivmin`/
`Ivsizeof`/`Ivalignof`/`IvCOMPL`/`IvAND`/`IvOR`/`IvXOR` route to the same
`Mem.*_ival` on both sides; `<impl>` constants go through a hand-maintained
table (Z2-CP-08). Candidate rows:

| id | Lean | OCaml | differs | reach | class | fix + price |
|---|---|---|---|---|---|---|
| Z2-CP-00 (= Z-76) | `CoreParser.lean:1281-1282` `\| some "IvMaxAlignment" => … CerbMem.integerIval 16`; dead twin `:870-871` | `core_parser.mly:1536-1537` `IVMAX_ALIGNMENT { … integer_ival (… (get ()).max_alignment) }` = 8 | literal vs record | **C** (every `malloc`/`realloc`) | BUG-FIX (Z1) | `CerberusImpl.max_alignment`; delete `:870-871`. **S** |
| **Z2-CP-01** | `:1072` `lexIdent` … `:1321-1328` `PEsym (mkSym id)` — `inf`/`nan` lex as identifiers | the pp prints `OVfloating` via `string_of_float` (`pp_core.ml:279-282`) → `inf`/`-inf`/`nan`; the OCaml grammar has NO float literal (`mll:290-291`) | `PEsym "inf"` (unbound) vs `OVfloating +∞` in the oracle's AST | **C**, libc mode: `libc.core:53897,53906` (`proc decfloat`) + 2 more sites. PROBED `strtod_inf.c`: oracles 10 × `Defined {value: "Specified(1)", …}`; Lean 10 × `Error {msg: "Unresolved_symbol: Symbol(_, 13557763317115745599, _) at unknown location"}` | **BUG-FIX** (every `strtod`/`strtof` overflow in libc mode) | map `inf`/`nan` (and `-` + float) to `OVfloating`; tripwire: no binder named `inf`/`nan`. **S** |
| Z2-CP-02 | `:118-120` `.float (CerbFloat.of_string s)` parses the dump text as written | `pp_core.ml:282` `string_of_float` = `%.12g` — `libc.core:41698` `Specified(3.40282347e+38)` is FLT_MAX with 3 digits lost | the pinned dump is LOSSY for floats needing > 12 significant digits | **C** in principle (libc mode, `__floatscan`/`strtof` boundary); PROBED `strtof_fltmax.c`: all three engines exceed 60 s (exhaustive; three `strtof` calls) — NOT SETTLED | INSTRUMENT / boundary: regenerate the pin with an exact float printer (`%.17g`/`%h`) via `scripts/libc_prep.sh`, or declare the boundary; re-probe single-trace in Z4. **M** |
| Z2-CP-03 | `:980-983` `pPexprMinus` — unary minus binds tighter than `* / rem_t rem_f :: ^` | `.mly:1595-1597` `MINUS pexpr` at MINUS's precedence (`:1192`), so those operators shift INTO the operand (`- a rem_f b` = `0-(a rem_f b)`) | tree shape | hand-written Core only (std.core: no unary minus on non-literals; libc.core: only `-1` literals, value-equal) | BUG-FIX (mirror; fail-closed for hand-written inputs) | negative literal atom, else operand at prec 5. **S** |
| Z2-CP-04 | `:755-763` `OpExp => (7, 8)` — `a ^ b ^ c` accepted as `(a^b)^c` | `:1195` `%nonassoc CARET` → Parser.Error | Lean accepts what the oracle rejects | hand-written only | BUG-FIX (fail-closed) | reject a chained `^`. **S** |
| Z2-CP-05 | `:1180-1181,1355-1361` `if` as a binop operand takes bounded branches | `:1118` `%nonassoc ELSE` lowest → `a + if c then x else y * 2` has else-branch `y * 2` | tree shape | hand-written only (in-code note `:1335-1351`) | declare-with-argument (state the OCaml precedence explicitly). **S** |
| Z2-CP-06 | `:1771-1786` layout rule for `;` sequels (column-based) | `:1133-1134,1677-1679` `%right SEMICOLON`, ELSE lower → an outdented `; e3` after an `if` is INSIDE the else on the oracle | tree shape | hand-written only (std.core has zero `;` sequencing) | declare-with-argument (note `:1743-1768` exists; add the grammar contrast). **S** |
| Z2-CP-07 | `:132-140` `lexStrGo` decodes `\n \t \\ \"` and maps other `\c` → `c`; accepts newlines | `mll:257-274,296` keeps escapes VERBATIM, rejects newlines | string content | hand-written only (`[ailname = "…"]` and `error("…")`; no backslashes in any corpus) | BUG-FIX (mirror: raw text, reject `\n` and unlisted escapes). **S** |
| Z2-CP-08 | `:244-288` `pImplConstant` hand table with a `BuiltinFunction s` FALLBACK for unknown names | `mll:209-219` `scan_impl`: `Pmap.find id Implementation.impl_map` (`implementation.lem:306-337`) else `builtin_` prefix else `raise Core_lexer_invalid_implname` | fail-OPEN tail; several spellings (`<sizeof>`, `<alignof>`, `<Ctype.min/max>`, `<Characters.*>`, `<Environment.*>`, `<Bitfield_other_types>`, `<Atomic_bitfield_permitted>`) mis-map | UNREACH on the corpora (std.core/.impl/libc.core `<…>` token sets enumerated and all correctly mapped; the in-code note `:266-285` omits libc.core) | BUG-FIX (fail-closed): the table = the generated `impl_map` + the `builtin_` rule, `fail` otherwise. **S** |
| Z2-CP-09 | `:308-314` `pIopFromStr … else IOpAdd`; `:1299-1318` `wrapI_`/`catch_exceptional_condition_` prefix match | `mll:119-128` only `_{add,sub,mul,shl,shr}` are keywords; anything else is `SYM` → unresolved | `wrapI_div(`/`wrapI_rem_t(`/`wrapI_xyz(` silently become `IOpAdd` — the pp CAN print `_div`/`_rem_t` (`pp_core.ml:418-419`) | corpora: libc.core has only `_add/_sub/_mul` | BUG-FIX (fail-closed): exact suffix table incl. `_div`, `_rem_t`, `_shl`, `_shr`; `fail` otherwise. **S** |
| Z2-CP-10 | `:1642-1649` `pcall(f` requires a comma-less zero-arg form; `:1964-1974` `builtin` requires `: eff bTy`; `:826-834` `PtrMemberShift[s, .cid]` requires the dot | pp forms: `pcall(f, )` (`pp_core.ml:636`), `builtin sym (bTys)` (`:786-788`), `PtrMemberShift[s, cid]` (`pp_mem.ml:70-71`) | Lean fails LOUDLY on the pp forms | latent (libc.core has none of the three) | EXC(c)-loud → BUG-FIX when a future dump contains them: accept the pp forms. **S** |
| Z2-CP-11 | `:1925-1930` `pDefUnion` drops a trailing `T x[]` member; `:1826-1837` `pDefFields` accepts zero fields; `:2004-2007` empty input → empty `CoreFile` (docstring `:2139-2141` says it fails); `:1321-1328` bare `_` → `PEsym`; `:234-236` `ensureListBTy` fallback | `.mly:1775-1777` keeps the union member; `:1759-1761` non-empty; `:1215-1217` non-empty; `mll:328` `_` → UNDERSCORE (Parser.Error); `:68-71` `failwith` | fail-OPEN parser arms | hand-written only (the `[]: <elem>` list form MUST stay accepted — the pp prints it, `pp_core.ml:464`; libc.core ×3) | BUG-FIX (fail-closed) except the declared `ensureListBTy` pp case. **S** |
| Z2-CP-12 | `:191-192` `mkSym name := Symbol "" name.hash.toNat (SD_Id name)` — no scoping/arity/duplicate/startup checks; the G6 hash-collision TRIPWIRE (`:2042-2069`, declaration text confirmed) | `.mly:182-227` scoped `register_sym`/`lookup_sym`; `:236,330,364-496,890-892,979` the `Core_parser_*` errors | malformed text refused by the oracle, accepted by Lean | hand-written only | declare-with-argument (extend the G6 note); optional post-parse resolution pass (**M**) |
| Z2-CP-13 | `:657-683` `OTy_struct (mkSym (stripRawSymSuffix tag))` | `.mly:1381-1386` dummy `Symbol ("", 0, SD_Id name)`; the pp prints `SD_unnamed_tag` as `a_N` here (`pp_symbol.ml:9-10`) vs `__cerbty_unnamed_tag_N` in ctype positions | anonymous C tags collapse to `a` on Lean (all unnamed tags collide) and differ from the ctype-position symbol | libc.core: all tags named; consumers `core_aux.lem:58,98,121,145` — impact UNSETTLED (needs an anonymous-struct libc-mode run) | Z2-CP-13 → FIX phase measurement. **S/M** |
| Z2-CP-14 | `:200-204` `loc0 := CerbLocation.unknown`, `annots0 := [Aloc loc0]` for every parsed node incl. `PEundef` (`:1097,1100`) | `.mly:1571` `PEundef (region ($startpos,$endpos) NoCursor, ub)`; every node `[Aloc (region …)]` | std.core UB locations | **C** (= charter Z-01, RULED [USER 2026-09-03] §1.3: location IS behaviour — reader A's "rule conflict" is already adjudicated) | cross-ref BUG-FIX Z-01 (Z1) |
| Z2-CP-15 | `:1492-1516` `SeqRMW false pe1 pe2 s pe3` (faithful) | `.mly:767-774` `SeqRMW (b, pe1, pe3, sym, pe3)` — the ORACLE drops `pe2` | oracle-side parser bug | hand-written only (libc.core's 199 `seq_rmw` are pp → Lean, matching the oracle's in-memory AST) | declare-with-argument + upstream tray (SUSPECT). **S** |
| Z2-CP-16 | `:360-390`/`:474-495` no `int_leastN_t`/`int_fastN_t`/`wchar_t`/`wint_t`/`ptraddr_t`/`int128_t`/`byte` ctype spellings | `.mly:1331-1338` `Builtins.translate_builtin_typenames`; pp spells them (`pp_core_ctype.ml:25-27,44-47,89-90`) | loud `unknown ctype` vs accepted | latent (zero occurrences in the corpora) | EXC(c)-loud → BUG-FIX: add the spellings. **S** |
| Z2-CP-17 | `:1192-1194` `True`/`False`/`Unit` and the keyword arms `:1074-1288` | the pp prints every symbol plain (`pp_symbol.ml:12-24`) | a C identifier named `True`/`False`/`Unit` would parse as a VALUE (silent); `error`/`not`/… loud | pp-only hazard; libc.core clean | INSTRUMENT: tripwire — fail if any parsed binder/param/proc is a keyword. **S** |
| Z2-CP-18 | `:857` `lexKw "Cfunction_value"`, `:870` `lexKw "Ivmax_alignment"` (misspelled, dead) | keywords `Cfunction`/`IvMaxAlignment` (`mll:80,88`) | dead arms; fail-open if ever reached | UNREACH | BUG-FIX (delete). **S** |
| Z2-CP-19 | `:1267-1280` `Cfunction(sym)` → `CerbMem.funPtrval s` | `.mly:1540-1541` `CFUNCTION_VALUE … (*TODO*) … null_ptrval Ctype.void` | real fn pointer vs NULL | hand-written only (libc.core uses it and Lean matches the oracle's in-memory AST) | declared in-code (`:1271-1276`) — confirmed |
| Z2-CP-20 | binder-shadowing under by-name symbol interning (`:191-192`): `Esseq(Esseq(pat,e1,body), rest)` and `Esseq(pat,e1,Esseq(body,rest))` print identically (`pp_core.ml:398-402,648-649`) | — | a same-named outer symbol used in `rest` is captured by `pat` | libc mode in principle; probe of the dump: no repeated `create`/`alloc`/`create_readonly` binder within a proc, none shadowing a parameter or `glob` (other binding forms not enumerated) | INSTRUMENT: assert per-proc binder-name uniqueness at libc load (fail-closed). **M** |

### 2.15 `CabsImport.lean` (755) vs `backend/lean_export/cabs_json.ml` (639) (Z-70)

Reader D: Z-70 HOLDS — no `getD`/`.get!`/`default`/`<|>`/`try`/`panic!` in
the file; all 34 `| t => err …` catch-alls throw; fixed-arity tuple checks
error; no absent-field → `none` absorption (each of the 30 `json_of_option`
emit sites pairs with `getOption`, absence is a `getField` error); every
`cabs.lem` constructor emitted and read with identical field names; the
location JSON is lossless for every field the exec-cone printers read.
Leniencies (schema widening, not fail-open on emitted data): `getNat`
accepts `.str` (`:66-75`; OCaml emits `` `Int `` only), `getTag` accepts a
bare string for object nodes (`:48-56`), unknown keys ignored / duplicate
keys first-wins (`:37-46`), `jsonToAttribute` lacks the `expectTag
"Attribute"` check (`:582-600` vs `cabs_json.ml:567`). Rows: **Z2-J-01**
`cabs_json.ml:621-633` `EDecl_funcCN _ | EDecl_lemmaCN _ | … -> None` +
`:636 filter_map` SILENTLY drops CN declarations the desugarer would process
(`cabs_to_ail.lem:4916-4927`) — unreachable in matched mode (plain cerberus
emits `EDecl_magic`, which IS serialised) but the fail-open shape; EXC(c)
fix: `failwith` (S). **Z2-J-02** non-UTF-8 bytes in a C string literal:
the lexer (`c_lexer.mll:434-453`) yields one 1-byte string per byte,
`cabs_json.ml:118-119` writes them raw → the JSON is not UTF-8 → Lean's
`IO.FS.readFile` (`Main.lean:637,1106`) fails "containing non UTF-8 data"
(loud, not attributed); the ORACLE also fails (`decode.ml:199-200` failwith)
— EXC(a) today, latent bridge fail-point; INSTRUMENT: encode bytes ≥ 0x80 as
U+00XX in `json_of_string` so Lean sees one `Char` per byte (S). Not
settled: whether `Json.parse` rejects trailing content.

### 2.16 The four instance files (Z-71)

Reader D's use-site table, verified where load-bearing:
`CerbCabsInstances` — nullary Cabs enums (`SC_*`, `Q_*`, `FS_*`) compared by
`=`/`List.elem` in `cabs_to_ail*.lem` (:1435-1438, :2168-2197, :2541-2593,
:3583-4838; `cabs_to_ail_effect.lem:1584-1591`) ↔ structural `BEq` — AGREE
(no payload). `CerbCtypeInstances` — the lem `instance (Eq ctype) let (=) =
ctypeEqual` (`ctype.lem:182-184`) is inlined by BOTH backends
(`generated/core_eval.ml:346` ↔ `Core_eval.lean:138`; counts 1/2/1/4 over
core_eval/mem_common/translation/cabs_to_ail match), the dictionary path
`Eq0 ctype := ctypeEqual` (prio 1000) beats the structural fallback (500),
and no ctype-keyed `Fmap/Pset/TreeMap` exists in the exec cone — AGREE.
FRAGILE (Z2-Q-01): hand-written `==` on `ctype` resolves per import graph —
`CerbMem.lean:197` (`.MVunspecified t1, .MVunspecified t2 => t1 == t2`) gets
the STRUCTURAL `beq_derived` (annotation-sensitive = OCaml poly `=`, correct
for `impl_mem.ml`'s `=`), while `CerbStepInstances.lean:111,130` gets
`ctypeEqual` (annotation-INSENSITIVE) though the header `:18` claims
poly-equality parity — unreachable (`driver.lem:1376,1410` compare only
against the nullary `Step_blocked2`), declare or use `beq_derived` (S).
`CerbFunMapInstances` — the `failwithI` value-compare leg (`:207-209`) is
unreachable: `SetType sym` = `ordCompare` (prio 1000), `MapKeyType` derived
from it, `fmapToSetBy` applies the value comparator only on EQ keys; NOT
SETTLED (Z2-Q-02): `generated/Core_typing.lean` folds a fun map
(`core_typing.lem:1875`) without importing `CerbFunMapInstances` — which
instance it resolves is unverified (the header's own rule `:180-184` says it
must). `CerbStepInstances` — `beqCoreStep2` vs `driver.ml:1745-1747`
`Lem.option_equal (=) … (Some Step_blocked2)`: OCaml `=` against an immediate
never descends into closures; Lean's same-ctor panic arms unreachable; the
`Float` leaf `f1 == f2` (`:102`) is IEEE like OCaml `=`; `blockTag` order
verified against `core_reduction.lem:114-130` — AGREE.

### 2.17 `CerbFuel.lean` (73)

Proof-support only: `driverFuel := 100000000`, `fuelExhaustedLoc` an
`opaque` `Loc.other "lem: fuel exhausted"`, `fuelExhaustedMsg`
reporting-only; nothing is read by any `.lem` term or OCaml text; the only
execution effect is the FUEL kill at exhaustion (EXC(b)/fuel, Z-32/Z-73).
Zero execution effect otherwise — confirmed.

### 2.18 Manifest coverage

All 23 manifest files read (the charter's "22" predates `CerbFuel.lean`);
`lean_frontend/*.lean` and `generated/*.lean` copies verified byte-identical
for every seam (readers A/C `cmp`/`diff`; the sync gate's precondition).

## 3. Z-76-shape literal census — a LITERAL in a hand-written seam where the OCaml reads a record/config/implementation/registry value

Values agree today unless marked; each is a candidate to route through the
same source the OCaml reads (or to declare, with the reachability of the
alternative value).

| # | Lean site | literal | what the OCaml reads | agree today? |
|---|---|---|---|---|
| 1 | `CoreParser.lean:1282` (+ dead `:871`) | `integerIval 16` | `core_parser.mly:1537` `(Ocaml_implementation.get ()).max_alignment` = 8 | **NO** (Z-76) |
| 2 | `CerbMem.lean:279` | `targetPtrSize : Nat := 8` | `impl_mem.ml:153-158,219-225,1160-1164,2134` `(get ()).sizeof_pointer` | yes |
| 3 | `CerbMem.lean:1399,1409,1417,1425` | `\| none => 4` | no OCaml read at all (`impl_mem.ml:2497-2511` is width-free) | fail-open default (Z2-M-08) |
| 4 | `CerbMem.lean:1859,1887` | `"out of memory"` | `impl_mem.ml:1255` `"Concrete.allocator: failed (out of memory)"` | **NO** (text, Z2-M-03) |
| 5 | `CerberusImpl.lean:20` | `max_alignment := 8` | `ocaml_implementation.ml:151-152` (the `selected` impl ref, `:413-425`; Morello 16) | yes |
| 6 | `CerberusImpl.lean:96-113,124-136,154-157,170-172,201` | every size/align literal | `(get ()).sizeof_*`/`alignof_*` + `type_alias_map` (`:154-171`) | yes (except the missing `IntN_t` aliasing, Z2-I-01) |
| 7 | `CerberusImpl.lean:82` | `Char0 => true` | `:257` `~char_is_signed:true` | yes |
| 8 | `CerbDecode.lean:47-48` | `-(2^(8-1))`, `(2^(8-1))-1` | `decode.ml:204-210` `impl.is_signed_ity Ctype.Char` via `Ocaml_implementation.get ()` | yes |
| 9 | `CerbDebug.lean:28`; `debug.lem:27` | `get_level … := 0` | `!Cerb_debug.debug_level` (`main.ml:105`, `-d`) | yes (matched mode) |
| 10 | `CerbGlobal.lean:37-43,107,109` | `backendName := "cerberus-lean"`, `execMode := none`, `concurrency/defacto/permissive/agnostic/ignoreBitfields := false`, `is_PNVI := false`, `has_strict_pointer_arith := false` | `!!cerb_conf` (`main.ml:124`), `!internal_ref` (`switches.ml:156-160`) | yes at every exec read (§2.9) |
| 11 | `Main.lean:772` | impl path `…/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl` | `main.ml:350` `--impl` default + `pipeline.ml:47` | yes |
| 12 | `Main.lean:759` (+ `:486-496`) | `"/std.core"` | `pipeline.ml:32-35` (`std_inner_arg_temps.core` under `SW_inner_arg_temps`), `Cerb_runtime.in_runtime`, `--runtime` | yes |
| 13 | `Main.lean:571` | `Normal_callconv` | `pipeline.ml:266-267` switch-dependent | yes |
| 14 | `Main.lean:894` | concurrency `false`; `"cmdname"` | `main.ml:308`; `pipeline.ml:604` (same literal) | yes |
| 15 | `Main.lean:879` | `CerbFS.fs_initial_state` | `pipeline.ml:597-599` `--fs DIR` | yes (no `--fs`) |
| 16 | `Main.lean:553,584` | `stderr: \"\"` on desugar/typing UB | `main.ml:170,177` the same literal | yes (`:930` is Z-72) |
| 17 | `CerbFS.lean:70-71,100,102,165` | `mode := 0o644`, `nlink := 1`, `nextFd := 3`, `umask := 0o022`, `O_WRONLY/O_RDWR/O_TRUNC` bit tests | SibylFS model state / `fcntl.h:29,31,36` (bits verified equal) | bits yes; state values unverified (fs model) |
| 18 | `CerbCall.lean:183,186` | `PrefOther "errno"`, `Signed Int_` zero | `driver.lem drive` (same literals) | yes (the ORDER is Z2-C-02) |
| 19 | `CoreParser.lean:244-288, 308-314, 755-763` | hand tables for `<impl>` names, `wrapI_*` suffixes, operator precedence | `implementation.lem:306-337` `impl_map` + `mll:214`; `mll:119-128`; `.mly:1189-1195` | yes on the corpora; fail-open tails (Z2-CP-08/09) |
| 20 | `CoreParser.lean:200-204` | `loc0 := unknown`, `annots0` | lexer positions (`.mly:1571` etc.) | **NO** (Z-01) |
| 21 | `CerbND.lean:85`, `CerbFuel.lean:71` | `ndDefaultFuel`, `driverFuel := 10^8` | no counterpart (EXC(b)) | — |
| 22 | `CerbConcurrency.lean:166` | `statically_satisfied := true` | no OCaml body (`cmm_csem.lem:654-656`) | — (Z-25) |

## 4. Probe corpus index

`tests/z2-probes/` — 34 probe programs in 8 directories, runner `run_z2.sh`,
per-directory README tables with the verbatim three-engine lines and the
proposed lane. Derived: 12 Lean≠oracle runs (9 distinct findings: Z2-M-01
×3 witnesses, Z2-M-02, Z-07 (`free_funptr`), Z2-P-01 ×2, Z2-CP-01, Z2-I-01,
Z2-F-01, Z2-C-01, Z2-C-02), 3 reader claims REFUTED by probe (Z2-I-01 on the
`<stdint.h>` route — confirmed on the direct-spelling route; Z2-FL-01; the
empty-struct `% 0` route), 1 not evidenced (Z2-FL-02, 200/200 agree), 2 not
settled (`strtof_fltmax.c` triple timeout; FunctionNoParams `isWellAligned`
arm — both shapes rejected by the shared front end), 1 INSTRUMENT confirmed
(Z2-FL-03 panic-without-flag → value). The `nd/` single-trace runs are
recorded in `nd/README.md` (verbatim).

## 5. Work order for the Z2 FIX phase (rebased on Z1), ordered by execution impact

Every row lands with its in-code disposition (mirror + cite, or the
declaration text + reachability argument) and, where C-observable, its
probe pinned per charter §4.2 (immaculate DIFF/CRASH pairs added RED, flipped
on the fix). Prices are S unless marked.

1. **Z2-M-01** `opIval` `IntRem_t`/`IntRem_f` zero divisor → fail-stop with
   the OCaml text; rewrite `CerbMem.lean:1322-1327`; pins `aligned_alloc_zero*.c`
   (+ tray draft: oracle crash on `aligned_alloc(0, n)`).
2. **Z2-P-01** `batchEscape` = OCaml `Bytes.escaped` classes (by char code);
   pins `main/stdout_escape.c`, `stderr_escape.c`; rides §4.1's whole-line
   compare.
3. **Z2-CP-01** `inf`/`nan` (and `-`+float) → `OVfloating` in `pPexprAtom`;
   binder-name tripwire; pins `coreparser/strtod_inf.c`.
4. **Z2-M-02** `casePtrval` fallback → `panic! "case_ptrval"` — MUST land
   with Z-06 (Z1) — pins `mem/device_funptr_call.c`.
5. **Z2-I-01/03/02** `normalise_integerType` `aux_ibty` arm + crash mirrors;
   pins `impl/cerbty_int32_uac.c`.
6. **Z2-C-01/02** `driveCall`: errno first; refuse out-of-range / `_Bool`
   injections loudly (or mirror `conv_int`, M); pins `call/*` as test_verify
   rows.
7. **Z2-FL-03** `Main.lean` refuses to run without abort-on-panic (plant).
8. **Z2-F-01/02/03/07** → hand to Z1's Z-27 op-by-op table (CerbFS
   `lseek` whence/`SEEK_END`, `getD` after unlink, `unlink` of a missing
   path).
9. The Z-09…Z-22 mirrors (14 S rows, §2.1.2) + Z2-M-03/04/05/07/08/09/10
   (allocator text, `allocateRegion` lazy bytes, clamps, `concurReadIval`,
   bitwise width defaults, `isWellAligned` message + FunctionNoParams
   panic, `.max 1`).
10. Declarations (in-code text with the argument): Z2-M-06/11/12/13/16/17/18/20,
    Z2-N-03 (Z-59 rewrite + `#guard` Z2-M-19), Z2-P-04/05/06, Z2-L-02/03,
    Z2-G-01/02, Z2-I-04, Z2-U-02, Z2-DC-01 (fail-closed), Z2-J-01/02,
    Z2-Q-01, Z2-CP-03…CP-20 (fail-closed parser arms + declarations + the
    tray for CP-15), the Z-62/Z-63/Z-64/Z-65/Z-66/Z-70/Z-71 dispositions
    as written in §2.6–§2.16.
11. Doc integrity: Z-23 (`CerbMem.lean:569` → `:1202`), Z2-M-14/15, and the
    manifest count (23) in the charter.

## 6. Not settled (and why)

- `strtof_fltmax.c` (Z2-CP-02): all three engines > 60 s in exhaustive mode;
  needs a single-trace/longer-bound run (Z4 measurement lane). The dump
  lossiness is a fact regardless (`libc.core:41698`).
- FunctionNoParams `isWellAligned_ptrval` arm (Z2-M-09): no accepted C shape
  found (two shapes rejected by the shared front end); mirror as `panic!`
  anyway.
- Z2-FL-02 decimal double rounding: not evidenced on 200 literals; the
  algorithm admits it structurally — a larger sweep or a hardening rewrite.
- Z2-T-01 libc-mode tagDefs merge (`Main.lean:652-709`) vs lem `union` on
  duplicate keys; const-expr seed equality — trace in the FIX phase.
- Z2-Q-02 which `SetType (generic_fun_map_decl …)` instance
  `generated/Core_typing.lean` resolves (no `CerbFunMapInstances` import).
- Z2-CP-13 anonymous-tag `OTy_struct` symbol conflation (`a_N` → `a`) —
  needs a libc-mode anonymous-struct run.
- Z2-CP-20 binder shadowing under by-name interning beyond the three binding
  forms enumerated; the proposed load-time uniqueness tripwire settles it.
- Z2-D-01 order-sensitive sym-keyed iteration on the exec path (multi-TU
  digests differ by construction) — grep-audit pending.
- Z2-F-05 whether `|buf| ≠ size` can arise at `core_run.lem:1240-1245`.
- `Loc_regions ([], _)` on the oracle batch path (`simple_location` uses
  `List.hd`) — reachability unknown (Z1's Z-03 mirror should copy the
  behaviour exactly, i.e. fail).
- `Json.parse` trailing-content behaviour (Z2-J).
- Reader-only rows adopted without an independent re-read of every cited
  line: the CoreParser hand-written-only rows (Z2-CP-03…CP-12, CP-15…CP-20),
  the CabsImport leniency census, the instance-file use-site census — each
  is marked "(reader)" by section and is a candidate for the FIX phase to
  re-read at its cites before editing.

## 7. Provenance

[USER 2026-09-03]: the rule and the exception classes (charter §1, quoted in
the header), UB location is behaviour (§1.3), the R1/R2/R3/R4 and Q2–Q10
rulings (charter §7). [AGENT] (this audit): every classification, price,
reachability argument and tally; the probe programs and the runner; the
CerbMem, CerbND and Main/CerbPP reads (first-hand); the adoption and
re-verification of the four parallel readers' reports (CoreParser; CerbND/
Main/CerbPP; the small config/impl/float/decode/tags/utils/debug/location/
fresh/fuel seams; CabsImport/instances/CerbCall/CerbFS) — where a reader's
claim was probed, the probe's verdict is recorded and wins (three claims
refuted, one not evidenced, seven confirmed). Every quoted engine line is
verbatim from the probe READMEs / `.tmp/z2/*.log` (ephemeral, per container
practice); every OCaml cite was read in this worktree at `046e5cdd4`. No
product code, gate, baseline or other document was modified; nothing merged
or pushed.
