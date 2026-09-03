# ZERO-DISCREPANCY — slice Z1 record (2026-09-03)

Branch `arc/zero-discrepancy`, rebased onto mainline `046e5cdd4` at the
start and again onto `3d1883644` (three docs-only mainline commits) before
the final battery, at the orchestrator's instruction — commit ids below
are the post-rebase ones (the four docs-only charter commits replayed as
`d2d710659..1d6638b0a`; the probe
corpora cherry-picked linearly: `noodle/semantics` `815f97974..798cca224`
→ `42b86a135..dbb19d69a`, `probe/dynamic-addrs` `2700f99c0` → `927426b86`;
every cherry-pick verified to touch only `tests/noodle-probes/`,
`lean_frontend/docs/` and `docs/upstream-tray/`). Charter:
`docs/2026-09-03_zero-discrepancy-design.md` (R3, §7 asks RULED). Worker:
the Z1 worker [AGENT]; every decision below is [AGENT] unless marked
[USER]; quoted engine lines are verbatim from this worktree's runs on
stamped binaries; tallies marked derived.

THE RULE implemented ([USER 2026-09-03], charter §1.1): every Lean-vs-
oracle EXECUTION discrepancy (verdict class, value, UB code, UB LOCATION,
stdout/stderr bytes, trace set) on a program both engines run in matched
mode is a bug — mirror the OCaml with a `file:line` cite. Exceptions only:
(a) failure-path message TEXT; (b) resource limits ("Lean may fail where
the oracle succeeds is a BUG; the converse is fine") + fuel; (c) missing
features behind a LOUD, feature-ATTRIBUTED refusal; (d) the ISO-fix
register. Rulings in force: Q4 (one-sided oracle crash → Lean fail-stop
with the OCaml text), Q7 (refuse flags, do not plumb), Q8 = A (keep the
zero-executions refusal, DECLARE it).

Build: from re-derived trees (`rm -rf lean_frontend/generated`; `make
clean-prelude-src prelude-src`; `make lean-prelude-src lean-native-obj`;
`DUNE_CACHE=disabled build_cerberus`; `CERB_MEM_MAX=32G build_lean`;
`tools/check_driver_fresh.sh --check` green), verbatim at the start:

```
check_lem_sync: OK (src 4f2e089b39d5b371973513b3350f81d1b89871976f77df9ba4a25da3421d0c54, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_driver_fresh: recorded oracle stamp (bin 4e8c81b64828fe685022b1922880510aa77e7d6b692e5c0610963b18e1635a64, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
check_driver_fresh: recorded lean stamp (bin 8c484a477dc862bc255ba8a46f1b6791cb994a18a8b42e1fe77689aa82a1ff6a, src 60f9b3efb82e380130da3727a74627602f476cc0828a0db67dcc33a387bdf091)
check_driver_fresh: oracle OK … check_driver_fresh: lean OK …
```

Tier A at the start (13 rows incl. 4b/4c, all rc 0): the same summaries as
§9's first column. Every lane in this record ran SERIALLY: two lanes (or a
probe and a lane) in flight at once in this sandbox make the ORACLE side
fail en masse — `SUMMARY: total=106 match=3 … cerb_skip=103` and a
transient `Command not found …/main.exe` at the `--cabs-json` step — an
opam-exec contention artefact, observed twice and reproduced by
re-running serially (`match=85 ub_match=18 cerb_skip=3`). Recorded as an
operating note; no instrument was changed for it.

Third engine: un-forked upstream `deps/cerberus-upstream` @ `b9aeedcb4`
(read-only; its verdict equalled the fork oracle's on every row probed —
the discrepancies below are all Lean-side).

## 0. Headline

| | before Z1 | after Z1 |
|---|---|---|
| census rows fixed (mirror + cite) | — | Z-05, Z-06, Z-07, Z-08, Z-10, Z-01, Z-02, Z-03, Z-67, Z-72, Z-76 (+ the same-hunk seam rows Z-09, Z-11, Z-12; + Z2 audit rows Z2-M-02, Z2-P-01, Z2-FL-03) |
| refusal hygiene | flags became file names; panics could continue to a value; CerbFS served silently-divergent answers | Z-24/Z-25 attributed refusals (exit 2); LEAN_ABORT_ON_PANIC required; CerbFS op-by-op table, every non-SibylFS answer refuses |
| instrument | every lane kept the UB code alone | every extractor compares the whole `Undefined {…}` line; immaculate compares whole Defined/Undefined/Error payloads |
| immaculate pins | 31 rows | 46 rows (derived, `grep -vc '^#\|^$'`: 31 + 11 at `37d205a0e` + 1 `zd-z2m02` + 2 `zd-z2p01-*` + 1 `zd-f1` at the audit response; the first draft said 44 — audit F4); 20 flips DIFF→MATCH across the slice (derived from the per-commit baseline diffs: 1 + 3 + 14 + 2; the first draft said 15), of which 12 are `zd-*` pins and 8 are pre-existing UB rows that gained the oracle's `<L:C--L:C>` |
| register | "DELIBERATE DIVERGENCE"/"never fix-to-match" labels | ISO-fix register R1, R2 ADMITTED, R3 ADMITTED CONDITIONAL; `-- ISO-fix register R<n>` markers |

## 1. Findings are claims — the pre-fix measurements

All 17 charter reproducers re-run on the rebuilt binaries BEFORE any code
change (`.tmp/z1/probes-before.log`, ephemeral; fork oracle `--exec
--batch --mode=exhaustive [--nolibc]`, upstream identical flags, Lean
`--batch [--libc …]`), verbatim:

```
seam_copy_alloc_id.c [libc]      oracle Defined {value: "Specified(2)", …}  Lean Defined {value: "Specified(1)", …}
seam_device_range_load.c [nolibc] oracle Defined {value: "Specified(3)", …} Lean Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "tests/noodle-probes/seam/seam_device_range_load.c:6:59-61"}
seam_free_no_provenance.c [libc]  oracle Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}  Lean Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "unknown location"}
seam_free_device_pointer.c [libc] oracle Defined {value: "Specified(3)", …}  Lean Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "unknown location"}
seam_free_interior_pointer.c [libc] oracle Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<7:39--7:50>"}  Lean Error {msg: "MerrUndefinedFree Free_out_of_bound"}
float_inf_to_int_ub.c [nolibc]    oracle Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}  Lean … loc: "unknown location"
ptr_to_int_narrow_ub.c [nolibc]   oracle Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}  Lean … loc: "other_location(Concrete)"
se1.c [libc] (fprintf(stderr,"E1"); *NULL)  oracle Undefined {ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<2:62--2:64>"}  Lean … stderr: "", loc: ".tmp/z1/p/se1.c:2:62-64"
se2.c [libc] (control)            all three Defined {value: "Specified(3)", stdout: "", stderr: "E2", blocked: "false"}
da_offset.c [nolibc]              oracle Specified(8)   Lean Specified(16)
da_align16.c [nolibc]             oracle Specified(2)   Lean Specified(3)
da_control.c / da_bug.c [nolibc]  all three UB179a (oracle loc <6:3--6:11> / <12:3--12:11>; Lean "unknown location")
da_malloc0_nonnull.c [nolibc]     all three Specified(1)
at.c [nolibc] (_Atomic a=5; a+=2; a++)  all three Defined {value: "Specified(8)", …}
ptr_string_literals.c [nolibc]    oracles exit 125 Failure("decode_character_constant, started like an octal constant, but failed: ?")  Lean Defined {value: "Specified(0)", stdout: "98 65 66 4 83 52 3 10 9 92 34 39 63 0 4\n", …}
g5-decode-question.c [nolibc]     oracles the same Failure, exit 125     Lean Specified(63)
g5-escape-roundtrip.c [libc]      oracles Specified(87)                   Lean Specified(127)
```

Every row measured as the census says. One cite delta, cosmetic: the
charter quotes `seam_free_interior_pointer.c`'s oracle loc as
`<2:39--2:50>` (the noodler's scratch copy); the committed probe carries a
five-line header, so the loc is `<7:39--7:50>`. Not an erratum of
substance.

Flag probes (`.tmp/z1/p/pnvi.c`: `int a = 20; unsigned long u =
(unsigned long)&a; int *q = (int*)(u + 0ul); return *q;`), verbatim:

```
P-C1 oracle default:            Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<5:10--5:12>"}  rc=1
P-C2 oracle --switches=PNVI:    Defined {value: "Specified(20)", stdout: "", stderr: "", blocked: "false"}  rc=0
P-C3 Lean default:              Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: ".tmp/z1/p/pnvi.c:5:10-12"}  rc=1
P-A1 Lean --switches=PNVI:      uncaught exception: no such file or directory (error code: 4294967294) / file: --switches=PNVI  rc=1
P-A2 Lean --concurrency:        … file: --concurrency  rc=1
P-A3 Lean --batch at.json --first: … file: --first  rc=1
P-B3 oracle --concurrency:      internal error: CONCURRENCY IS BROKEN / cerberus: internal error, uncaught exception
```

Z-10 witnesses: fork oracle on `core_bug_then_kill.core` → uncaught
`Failure("Concrete: FREE was called on a dead allocation")`, exit 125
(`core_bug.core` Specified(0), `core_control.core` UB179a `<5:3--5:14>`);
Lean libc injection `inj_bug.c` + `inject_rand.core` → `Undefined {ub:
"UB179b_dead_allocation_free", stderr: "", loc:
"tests/noodle-probes/dynamic-addrs/inj_bug.c:10:3-12"}`; `inj_bug_bexit.c`
→ `Defined {value: "Specified(0)", …}` (the mirrored tray-19 defect).

Z-27 witnesses (libc): `tests/suite/fs/stat.c` oracle `Defined {value:
"Specified(0)", stdout: "2049 1 33261 1 0 0 0 10\n", …}` vs Lean `stdout:
"0 0 420 1 0 0 0 10\n"`; `tests/freebsd/cat.c` oracle `Defined {value:
"Specified(1)", stdout: "stdin", …}` vs Lean `Error {msg: "assert()
failure"}`.

The three Z2-audit additions relayed by the orchestrator (branch
`audit/z2-seams` @ `9e86fe67c`), re-measured here before acting:
`device_funptr_call.c` [nolibc] oracles exit 125 `Failure("case_ptrval")`,
Lean `Error {msg: "Illformed_program: …:9:18-43: does not point to a
function"}`; `stdout_escape.c` [libc] oracle `stdout:
"a\bb\007\127\195\169\011\012\027|\n"`, Lean (cat -v)
`"a^Hb^G^?M-CM-^CM-BM-)^K^L^[|\n"`; `stderr_escape.c` oracle `stderr:
"E\b\007\255|"`, Lean `"E^H^GM-CM-?|"`; `nan_to_int_nopanicflag.c` WITHOUT
`LEAN_ABORT_ON_PANIC`: the PANIC line then `Defined {value:
"Specified(0)", stdout: "", stderr: "", blocked: "false"}`, exit 0 (oracle
uncaught `Z.Overflow`, exit 125). All three as stated.

## 2. The rows, in order (reproducer · oracle · Lean before · mirror · Lean after)

### Z-05 (D4) — `copy_alloc_id` — commit `768be3698`
Reproducer `tests/noodle-probes/seam/seam_copy_alloc_id.c` (libc). Oracle
`Defined {value: "Specified(2)", …}`; Lean before `Specified(1)`. Mirror:
`CerbMem.copyAllocId` ↔ `impl_mem.ml:2766-2770` — `intfromptr (other
"copy_alloc_id") void (Unsigned Intptr_t) pv >>= fun _ -> ptrfromint (other
"copy_alloc_id") (Unsigned Intptr_t) void iv` (was `memReturn pv`, no
comment). Lean after `Defined {value: "Specified(2)", stdout: "", stderr:
"", blocked: "false"}`. Pin zd-d4-copy-alloc-id DIFF→MATCH.

### Z-06 (D5), Z-07 (D6), Z-08 (D7), Z-10 (+ Z-09/Z-11/Z-12 same hunk; + Z2-M-02) — commit `c61b78f70`
- Z-06 `seam_device_range_load.c` (nolibc): oracle `Specified(3)`; Lean
  before UB043. Mirror: `CerbMem.deviceRanges` ↔ `impl_mem.ml:620-624`,
  `isWithinDevice` ↔ `:681-686`, `ptrfromint` PVI arm structure ↔
  `:2163-2173`, load/store device arms ↔ `:1611-1617`/`:1718-1724`
  (`doStore` takes the OCaml `alloc_id_opt`); the three FALSE
  "device_ranges is empty in this pipeline" comments deleted. After
  `Defined {value: "Specified(3)", …}`.
- Z-07 `seam_free_no_provenance.c` / `seam_free_device_pointer.c` (libc):
  oracle `Error {msg: "MerrOther "attempted to kill with a pointer lacking
  a provenance""}` / `Specified(3)`; Lean before UB179a both. Mirror:
  `CerbMem.killM` arms ↔ `impl_mem.ml:1465-1476` (null: success unless
  `SW_forbid_nullptr_free` — Z-12; function ptr / Prov_none → the two
  MerrOther texts; Prov_device → return). After: identical to the oracle
  lines.
- Z-08 `seam_free_interior_pointer.c` (libc): oracle UB179a `<7:39--7:50>`;
  Lean before `Error {msg: "MerrUndefinedFree Free_out_of_bound"}`. Mirror:
  the `Prov_some` arm's ORDER ↔ `impl_mem.ml:1515-1549` — `is_dynamic addr`
  (the pointer's address, not `alloc.base`) → `is_dead` → `get_allocation`
  (MerrOutsideLifetime → UB009, `:669-675` — Z-11) → `addr = alloc.base`.
  After `Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "",
  loc: "<7:39--7:50>"}` (the loc completed by Z-01).
- Z-10: static kill of a DEAD allocation ↔ `impl_mem.ml:1531-1532`
  `failwith "Concrete: FREE was called on a dead allocation"` → Lean
  `panic!` with that text (Q4). Witness after: `inj_bug.c` +
  `inject_rand.core` → `PANIC at CerbMem.killM CerbMem:1944:10: Concrete:
  FREE was called on a dead allocation`, exit 134 (was UB179b). In-code
  reachability note: only after an ACCEPTED wrong free — the tray-19
  dynamic_addrs address-keying defect (Z-77) or `cerb::with_address`.
- Z2-M-02 `device_funptr_call.c` (nolibc): `CerbMem.casePtrval`'s fail-open
  fallback ↔ `impl_mem.ml:1814` `failwith "case_ptrval"` → `panic!
  "case_ptrval"` (`[Inhabited α]` binder added). After: `PANIC at
  CerbMem.casePtrval CerbMem:1249:4: case_ptrval`, exit 134 (oracles exit
  125, same text). Pin zd-z2m02-device-funptr-call MATCH | L=CRASH.
- Also in the hunk: `SW_zap_dead_pointers`/`is_PNVI` arms are LOUD kills
  ("not ported — switches are refused (Z-24)") rather than silently the
  default; Prov_symbolic loud.

### Z-01 (D1), Z-02 (D2), Z-03 (O1), Z-67, Z-72 (+ Z2-P-01) — commit `1c1311a57`
- Z-01 `float_inf_to_int_ub.c` (nolibc): oracle UB017 `<5:11--5:19>`; Lean
  before `loc: "unknown location"`. Mirror: `CoreParser.parseLibraryFile
  file input` = `parseFile` + `stampLibraryFile` — a post-parse pass
  stamping every `Aloc unknown`/`PEundef unknown`/`Action unknown`/Proc,
  ProcDecl, BuiltinDecl, tag-definition loc with `Loc.region ⟨file,0,0⟩
  ⟨file,0,0⟩ .noCursor` ↔ `core_parser.mly:1571/1744/1746` `region
  ($startpos, $endpos)`; `Main` loads std.core and the impl file through
  it (`pipeline.ml:29-34/:47`). DOCUMENTED DIVERGENCE (Pos payload only):
  line/column are not tracked (no line table in the Parsec state; the
  parse is on every run's hot path); only the FILE is consulted by any
  execution-path consumer (`is_library_location`: `core_eval.lem:602`,
  `core_run.lem:476/781`) and no std.core position is ever printed. After
  `Undefined {ub: "UB017_out_of_range_floating_integer_conversion",
  stderr: "", loc: "<5:11--5:19>"}`.
- Z-67: `CerbLocation.isLibraryLocation` ↔ `util/cerb_location.ml:512-520`
  (`Filename.dirname path` ∈ {`runtime/libc/include`, `runtime/libcore`,
  `runtime/libcore/impls`}, tested as a runtime-relative SUFFIX — the
  runtime root is not plumbed; documented residual: a USER file under a
  directory literally named `runtime/libcore` etc.; mover: plumb the root
  from Main). The old any-segment heuristic (`include/` anywhere =
  library) is gone.
- Z-02 `ptr_to_int_narrow_ub.c` (nolibc): oracle UB024 `<7:11--7:17>`; Lean
  before `other_location(Concrete)`. Mirror: `CerbMem.intfromptr` `memFail
  MerrIntFromPtr loc` ↔ `impl_mem.ml:2459` `fail ~loc`. After `<7:11--7:17>`.
- Z-03: `CerbLocation.simpleLocation` ↔ `util/cerb_location.ml:476-491`
  (`<L:C--L:C>`, `<unknown location>`, `<other location: s>`; empty
  regions → the OCaml `List.hd` failure) used by every batch `loc:` field
  (`driver_ocaml.ml:113/127`, `main.ml:166-177`). The Main.lean declared
  deviation "loc strings … (harness never compares loc)" is DELETED.
- Z-72 `se1.c` (libc): oracle `stderr: "E1"`; Lean before `stderr: ""`
  (literal). Mirror: the Undefined line's stderr = the KILLED state's
  `String.concat "" (Dlist.toList dr_st.core_state.io.stderr)`
  (`driver_ocaml.ml:173-181`), `String.escaped`. After `Undefined {ub:
  "UB043_indirection_invalid_value", stderr: "E1", loc: "<2:62--2:64>"}`.
  (The plain batch Error line prints msg alone on the oracle, `:138` —
  unchanged.)
- Z2-P-01 `stdout_escape.c`/`stderr_escape.c` (libc): `Main.batchEscape` ↔
  OCaml `String.escaped` = `Bytes.unsafe_escape` (the switch's
  `lib/ocaml/bytes.ml:170-212`): `" \ \n \t \r \b` short forms, 32..126
  verbatim, else decimal `\ddd`; the io strings hold one Char per program
  byte so the output is pure ASCII (no UTF-8 re-encoding of bytes ≥ 0x80).
  After: `stdout: "a\bb\007\127\195\169\011\012\027|\n"` and `stderr:
  "E\b\007\255|"` — identical to the oracle.
- Baseline: 14 immaculate rows DIFF→MATCH (derived by recount, audit F4; the first draft said 15: zd-d1, zd-d2, zd-d7,
  zd-z72-stderr-ub, both zd-z2p01, and the 8 pre-existing UB rows now
  carrying the oracle's `<L:C--L:C>`).

### Z-76 (R2) — commit `8da338f42`
`da_offset.c`/`da_align16.c` (nolibc): oracle `Specified(8)`/`Specified(2)`;
Lean before `Specified(16)`/`Specified(3)`. Mirror: `CoreParser`
`IvMaxAlignment` → `CerbMem.integerIval (CerberusImpl.max_alignment : Int)`
↔ `core_parser.mly:1536-1537` (`DefaultImpl.max_alignment = 8`,
`ocaml_implementation.ml:151-152`). After `Specified(8)`/`Specified(2)`.
Pins zd-da-offset/-align16 DIFF→MATCH. No exec-lane row moved (nothing in
those corpora observes heap addresses modulo 16 — as the charter said).

### Z-24, Z-25, Z-73 (+ Z2-FL-03) — commit `b42776130`
`Main.refuseFlag`: every `--` token the positional parser does not accept
→ `cerberus-lean: refused — <flag>: <feature> … (see VALIDATION.md,
zero-discrepancy Z-24)`, exit 2 — attributed for `--switches=…`
(semantics switches; P-C1/P-C2 above show the oracle's flag changes the
answer), `--concurrency` (the oracle's own mode is non-functional:
`CONCURRENCY IS BROKEN`, P-B3), a KNOWN flag out of canonical position,
and any unknown flag; `--stdin` stays the one `--` positional. Z2-FL-03:
the driver refuses to start (exit 2) unless `LEAN_ABORT_ON_PANIC` is set —
the runtime tests PRESENCE (measured: `"1"`, `"0"`, `""` all abort; unset
continues to a value). Harness grep: every script invoking the driver
sets the flag except `scripts/test_golden.sh` (now does); `check_fork_
drift.sh`, `fuzz_csmith.sh`, `tests/mem-scale-probes/run_all.sh` only
name the binary. Z-73: declared in `Main.lean` and `VALIDATION.md`
("Known, LOUD limits"), Q8 = A. Plants, verbatim:

```
--batch pnvi.json --switches=PNVI → cerberus-lean: refused — --switches=PNVI: semantics switches (PVI/PNVI/strict_pointer_arith/CHERI/…) are not supported by this port — … (see VALIDATION.md, zero-discrepancy Z-24)  rc=2
--batch at.json --concurrency     → … --concurrency: concurrency is not supported by this port (the oracle's own --concurrency mode is non-functional at b9aeedcb4: `internal error: CONCURRENCY IS BROKEN`); …  rc=2
--batch at.json --first           → … --first: known flag out of its canonical position (…)  rc=2
--pp-core at.json --batch         → … --batch: known flag out of its canonical position (…)  rc=2
--batch at.json --frobnicate      → … --frobnicate: unknown flag; this port accepts only …  rc=2
--batch --first at.json           → Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}  rc=0
--batch --stdin < at.json         → the same line  rc=0
--parse-core runtime/libcore/std.core → runtime/libcore/std.core: Core file: 22 fun, 52 proc, 0 def/impl, 0 struct/union, 0 glob, 36 builtin  rc=0
env -u LEAN_ABORT_ON_PANIC --batch nan.json → cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set: …  rc=2
LEAN_ABORT_ON_PANIC=1 --batch nan.json → PANIC at CerbFloat.truncToInt CerbFloat:302:4: … rc=134   (oracle: uncaught Z.Overflow, exit 125)
```

### Z-27 — CerbFS — commit (this slice, "C7")
Deliverable: the op-by-op served/refused table for all 25 `fs_*`
operation entry points of `frontend/model/fs.lem` (derived count — the
charter said 24; the lem interface has mkdir, open, close, write, read,
pwrite, pread, rename, umask, chmod, chdir, chown, link, readlink,
symlink, rmdir, truncate, unlink, lseek, stat, lstat, opendir, readdir,
rewinddir, closedir = 25, plus the 11 pure stat accessors), committed
into the `CerbFS.lean` header and reproduced in §6 below. SibylFS's
behaviour is the POSIX model's (`sibylfs/generated/sibylfs.ml run_<op>` =
one `OS_*` transition of `fs_spec.lem`). Refusals added (same shape as
the five existing sites, `CerbFS refusal (fail-closed fs-model boundary):
<op> … (CerbFS.lean header; mover: …)`): open of a missing file without
O_CREAT; any O_EXCL; existing-file open with O_APPEND (joins write/trunc);
stat/lstat; mkdir/rmdir/chdir/chmod/chown; link/readlink/symlink;
opendir/readdir/rewinddir/closedir; truncate with an open fd on the path
or to a larger length; unlink/rename with an open fd on the path; lseek
past EOF or with an invalid whence; lseek/close on fds 0,1,2. SERVED and
verified against SibylFS: read/pread/pwrite on fds 0,1,2 answer EBADF on
BOTH sides — SibylFS's std fds are open on a dummy fid with NO access flag
(`fs_spec.lem:5690-5696`, `:5806-5812`; `os_read` `can_read` false →
EBADF `:4949-4956`; write `:5006-5012`) — so `tests/suite/fs/cat.c`
(`read(0)`) stays MATCH; `fs_unlink` of a missing path now answers ENOENT
(was 0). Witnesses after, verbatim:

```
tests/suite/fs/stat.c   oracle Defined {value: "Specified(0)", stdout: "2049 1 33261 1 0 0 0 10\n", …}
                        Lean   PANIC at CerbFS.fs_stat CerbFS:437:2: CerbFS refusal (fail-closed fs-model boundary): stat 'testfile.txt' — SibylFS answers the real st_dev/… fields …  exit 134
tests/freebsd/cat.c     oracle Defined {value: "Specified(1)", stdout: "stdin", …}
                        Lean   PANIC at CerbFS.fs_close CerbFS:234:4: CerbFS refusal (fail-closed fs-model boundary): close of fd 1 — fds 0,1,2 are open in SibylFS's initial state; …  exit 134   (its fclose(stdout); the old `assert() failure` was libc's fclose on the EBADF)
tests/suite/fs/cat.c    both   Defined {value: "Specified(1)", stdout: "cat: read error\n", …}   (read(0) → EBADF on both)
tests/tcc/40_stdio.c    Lean   PANIC at CerbFS.fs_read CerbFS:295:8: … read on fd 4 at offset 5 of the 12-byte file 'fred.txt' …   (unchanged class)
tests/suite/fs/{mkdir,putc_then_getc,stdout,echo,grep}.c  MATCH (mkdir.c never calls mkdir without args)
```

Spot sweep (`test_ci_sweep.sh --suite suite --suite freebsd --out
.tmp/z1/sweep`, SKIP_BUILD=1, stamps fresh; NOT a re-record of the
committed TSVs — that is Z4), verbatim summaries:

```
SWEEP SUMMARY suite=suite mode=libc total=144 match=39 ub_match=32 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=1 lean_kill=0 lean_error=0 lean_timeout=0 lean_hang=0 cerb_reject=50 cerb_error=20 cerb_timeout=2 cerb_hang=0 cerb_crash=0 cerb_kill=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
SWEEP SUMMARY suite=freebsd mode=libc total=2 match=1 ub_match=0 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=1 lean_kill=0 lean_error=0 lean_timeout=0 lean_hang=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_hang=0 cerb_crash=0 cerb_kill=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

Movement vs the committed 2026-08-22 TSVs (derived by joining on the
path): `tests/suite/fs/stat.c STDOUT_DIFF → LEAN_CRASH` (the refusal) and
`tests/freebsd/cat.c LEAN_FAIL → LEAN_CRASH` (the refusal) — the two
expected; and six STALE-snapshot movements NOT caused by this slice:
`desugaring/15-parameter_type_list_incomplete.error.c`,
`initialisation/constraints_vs_semantics.c`,
`parsing/global_prototype_def.fail.c`, `typing/void_indir.c`,
`undefined/UB008_multiple_linkage.c` `CERB_INCONSISTENT → UB_MATCH`
(the charter's Z-75 class: the trust-basket parse-only `--cabs-json`)
and `parsing/array.c LEAN_CRASH → MATCH` (the mem-scale arc's C1+C3, Z-42
"STALE"). No other row moved.

### Z-74 — exit-class evidence (no code)
`.tmp/z1/z74.sh` over the reject corpora — the 5 `tests/bytes` NEG files
+ the 107 `tests/ci/*.error.c` — oracle `--exec --batch --mode=exhaustive
--nolibc` vs the Lean pipeline (`--cabs-json` then `--batch`). Every one
of the 112 rows has the SAME exit class on both sides (derived tally):

```
oracle=REJECT/lean=VERDICT-FAIL: 102   (oracle rc 1, diagnostic on stderr; Lean rc 1 + `Error {msg: "typechecking|desugaring failed at …"}` on stdout)
oracle=REJECT/lean=PARSE-REJECT:   3   (0084-KO1, 0113-cast_assign_parsing, 0339-invalid-string-character: the shared C parser rejects; `--cabs-json` fails, Lean never runs)
oracle=VERDICT-FAIL/lean=VERDICT-FAIL: 3 (0257 UB059 / 0262 UB078 both `Undefined` rc 1; 0294 both `Error {msg: "no startup function was declared"}`)
oracle=REJECT/lean=REJECT:         4   (both CRASH with mirrored text: 0120/0121 `Failure("TODO(pure shift a null pointer …"` ↔ `PANIC at CerbMem.arrayShiftPtrval …`; 0258 `AilTypesAux.is_complete: called an a function type`; 0270 `Desugaring_init.lookup_struct_members: Nothing or empty Struct definition` — oracle exit 125, Lean exit 134)
```

Zero rows SUCCESS on either side. EXC(a) confirmed by measurement, not
by skip bookkeeping.

### Z-73 — declared (Q8 = A); no reproducer from C found
`runND` returning zero executions has no C-reachable reproducer in this
worktree's corpora (it requires an ND node with no successors); the
refusal is declared in-code and in VALIDATION.md as ruled. The fuel
arc's `runNDFuel` exhaustion leaf yields `[(Killed st0 fuelExhaustedKill,
…)]` (one execution), not zero, so only the design-level classification
is shared.

## 3. Z2-audit additions folded into Z1 (orchestrator relay, [AGENT])

| Z2 row | where it landed | measured here (before → after) |
|---|---|---|
| Z2-M-02 `casePtrval` fail-open fallback vs `impl_mem.ml:1814` `failwith "case_ptrval"` | commit `c61b78f70` (with Z-06, as required) | `device_funptr_call.c`: oracles exit 125 `Failure("case_ptrval")`; Lean `Error {msg: "Illformed_program: …"}` → `PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval` exit 134; pin `zd-z2m02-device-funptr-call` MATCH \| L=CRASH |
| Z2-P-01 `batchEscape` vs `String.escaped` | pin commit `cf664a2c4` (DIFF) + fix commit `1c1311a57` (MATCH) | `stdout_escape.c`: Lean `"a^Hb^G^?M-CM-^CM-BM-)^K^L^[\|\n"` → `"a\bb\007\127\195\169\011\012\027\|\n"` = oracle; `stderr_escape.c`: `"E^H^GM-CM-?\|"` → `"E\b\007\255\|"` = oracle |
| Z2-FL-03 panic-without-flag continues to a value | commit `b42776130` (with Z-24) | `nan_to_int_nopanicflag.c` unset → `Defined {value: "Specified(0)", …}` exit 0; now `cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set …` exit 2; with the flag PANIC exit 134 (oracle Z.Overflow 125). Harness grep: only `scripts/test_golden.sh` lacked the flag (added) |

FYI rows noted, no action: Z-59 closes (trace ORDER identical); `allocateRegion`'s eager `List.replicate` is the Z-30 cause (mem-scale mover).

## 4. Instrument commit (§4.1) — whole-line UB comparison everywhere

Sites changed (one commit): `scripts/test_exec.sh extract_verdict_seq`
(+ header note; both patterns `^`-anchored), `scripts/test_ci_sweep.sh`
(the same; the stale `:32-33` "loc strings deliberately differ …
Main.lean:344" comment DELETED), `scripts/test_cn_coverage.sh`,
`scripts/test_multi_tu.sh`, `scripts/test_verify.sh verdict_of`,
`tests/mem-scale-probes/measure.sh verdict_of`,
`tests/parity-probes/run_probe.sh seq()`, `tests/noodle-probes/run_noodle.sh
seqof()`, and the speclab family — LOCATED: `scripts/test_speclab.sh:97/:107`
and `test_speclab_{seed,list,tree,divmod,bytearr}.sh` `ORACLE_VERDICT`/
`LEAN_VERDICT` keep the Defined VALUE only (no Undefined extractor existed —
the charter's cite was uncertain, the reviewer's `seqof` name was
`run_noodle.sh`'s); an Undefined line on either side now surfaces as its
own whole-line token instead of an absent token. `test_immaculate.sh` was
made whole-payload in the pin commits (§2). `test_gcc_oracle.sh` untouched
(oracle-independent; UB rows are `SKIP_UB`). The token for a UB row is now
`UB:{ub: "X", stderr: "S", loc: "L"}`; status-only baselines do not move.

Plants (verbatim; `CERB_LEAN_BIN_OVERRIDE` = the documented plant-stub
hook, freshness check loudly SKIPPED):

```
(a) current binary:  [1/1] UB_MATCH float_inf_to_int_ub: UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
                     [1/1] UB_MATCH ptr_to_int_narrow_ub: UB:{ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}
(b) PRE-FIX binary (snapshot of lean 8c484a47…, the slice's starting binary):
                     [1/1] UB_DIFF float_inf_to_int_ub: Lean=UB:{… loc: "unknown location"} Cerberus=UB:{… loc: "<5:11--5:19>"}
                     [1/1] UB_DIFF ptr_to_int_narrow_ub: Lean=UB:{… loc: "other_location(Concrete)"} Cerberus=UB:{… loc: "<7:11--7:17>"}
(c) one-column loc perturbation (a stub shifting every Undefined line's end column by +1):
                     [1/1] UB_DIFF float_inf_to_int_ub: Lean=UB:{… loc: "<5:11--5:20>"} Cerberus=UB:{… loc: "<5:11--5:19>"}
                     SUMMARY: total=1 match=0 ub_match=0 ub_diff=1 …
(e) immaculate lane with the PRE-FIX binary, the loc/stderr/escape rows all DIFF (they are MATCH on the current binary):
                     zd-d1 … loc: "unknown location";  zd-d2 … loc: "other_location(Concrete)";  zd-z72-stderr-ub … stderr: "" …;
                     zd-z2p01-stdout_escape … stdout: "abÃ©|\n";  zd-z2p01-stderr_escape … stderr: "Eÿ|"
```

Instrument NOTE found while planting (pre-existing, unchanged here):
`test_exec.sh` in default (non-baseline) mode does not count `UB_DIFF`
toward its exit code (only MISMATCH/FAIL/CRASH/FUEL/ERROR/TIMEOUT/HANG do —
the recorded-DIFF design); a UB_DIFF turns the LANE red through
`--check-baseline` (UB_MATCH → UB_DIFF is a REGRESSION). Plant (c′) below
shows that path.

## 5. The ISO-fix register — instantiated (charter §1.4/§2.6/§4.3, RULED R3)

`VALIDATION.md` gains the "ISO-fix register" section with R1 (`'\?'`/
`"\?"` = 63; site `CerbDecode.lean` `| "\\?" => 63`; gcc 63 and `"a\?b"` →
`97 63 98 0`; tray 10 + the E2 addendum; pins `g5-decode-question` and the
new `zd-e2-ptr-string-literals` ORACLE_CRASH pairs) and R2 (`%c` 127 vs
oracle 87; the exact Lean-side round-trip site is `CerbDecode.escaped_char`
— hex `\xNN`, read back exactly by `decode_character_constant`, where the
oracle's `Char.escaped` decimal `\ddd` is re-read as octal inside
`formatted.lem:769-771 store_chars_in_array`; gcc 127; tray 11; pin
`g5-escape-roundtrip`), both ADMITTED [USER 2026-09-03]; R3
(`s4b-memcmp-hugesize`) ADMITTED CONDITIONAL — pending Z4's (ii′)(3)
scratch-oracle evidence; pin stays as recorded. The (vii) markers `-- ISO-
fix register R1` / `R2` sit at the two code sites; the "DELIBERATE
DIVERGENCE"/"never fix-to-match" wording is gone from `CerbDecode.lean`,
`tests/immaculate/baseline.txt` (header, via the writer template in
`scripts/test_immaculate.sh`) and `tests/immaculate/libc/g5-escape-
roundtrip.c`. The rest of the VALIDATION.md headline rewrite is Z4's.

## 6. CerbFS — the op-by-op table (copy of the `CerbFS.lean` header; Z-27)

| op | SibylFS (POSIX) | Lean |
|---|---|---|
| fs_open existing file, read-only | fd, offset 0 | SERVED |
| fs_open missing file with O_CREAT, no O_EXCL | created empty, fd | SERVED |
| fs_open missing file WITHOUT O_CREAT | ENOENT | REFUSED (was: created empty) |
| fs_open any O_EXCL | EEXIST if it exists, else create | REFUSED (was: ignored) |
| fs_open existing file with write/trunc/append intent | per flags | REFUSED |
| fs_close fd ≥ 3 open / unknown | 0 / EBADF | SERVED |
| fs_read offset 0 (prefix) / at EOF | bytes / 0 | SERVED |
| fs_read other offsets | bytes from the offset | REFUSED |
| fs_read fd 0,1,2 | EBADF (dummy fid, no read flag: fs_spec.lem:4949-4956/:5806-5812) | SERVED |
| fs_read unknown fd | EBADF | SERVED |
| fs_write fd ≥ 3 at offset == size / other offset / unknown fd | n / overwrite / EBADF | SERVED / REFUSED / SERVED (fds 0-2 never reach Fs: driver.lem:352-359) |
| fs_pread offset 0 or EOF, fs_pwrite at size | as read/write, offset untouched | SERVED |
| fs_pread/fs_pwrite other offsets | | REFUSED |
| fs_pread/fs_pwrite fd 0,1,2 | EBADF | SERVED |
| fs_lseek fd ≥ 3, valid whence, result in [0,size] / negative | offset / EINVAL | SERVED |
| fs_lseek past EOF / invalid whence | POSIX offset past EOF / EINVAL | REFUSED (was: accepted / offset kept) |
| fs_lseek, fs_close on fd 0,1,2 | performed on the std fd | REFUSED (was: EBADF) |
| fs_umask | previous mask | SERVED |
| fs_truncate no open fd, len ≤ size | shrink | SERVED |
| fs_truncate open fd on the path, or len > size | offsets keep / zero-extension | REFUSED (was: List.take) |
| fs_unlink no open fd / open fd on the path | removed / persists until close | SERVED / REFUSED (was: removed); missing path ENOENT (was: 0) |
| fs_rename no open fd / open fd on either path | renamed / fd follows | SERVED / REFUSED (was: fd kept the old path) |
| fs_mkdir, fs_rmdir, fs_chdir, fs_chmod, fs_chown | POSIX dir/permission semantics | REFUSED (were: success no-ops) |
| fs_link, fs_readlink, fs_symlink | POSIX link semantics | REFUSED (were: ENOSYS → errno −1) |
| fs_stat, fs_lstat | real fields | REFUSED (were: zeroed except size) |
| fs_opendir, fs_readdir, fs_rewinddir, fs_closedir | directory streams | REFUSED (were: fresh fd / empty / no-op / close) |

Count: 25 operation entry points (derived) — the charter's "24" is an
erratum of count, not of substance.

## 7. Errata candidates and findings outside the Z1 rows (parked, not acted on)

1. **libc-body UB locations** (FINDING, execution discrepancy, not in the
   census): a UB raised INSIDE a libc C body reports the libc source
   location on the oracle (its libc.co carries the locations) and
   `<unknown location>` on Lean (the `--libc` pin is the oracle's Core
   TEXT dump, which has no locations; `parseLibraryFile` is deliberately
   not applied to it — the libc bodies are NOT library-located on the
   oracle either). Witness: `tests/suite/fs/fprintf_then_fscanf.c` UB048
   oracle `<116:23--116:30>` = `runtime/libc/src/stdio.c:116` (`f->shcnt =
   f->buf - f->rpos;`) vs Lean `<unknown location>`; also
   `s4b-memcmp-hugesize`'s Lean token. Under the rule this is a BUG (UB
   loc is behaviour) with a named mover: a libc pin vehicle that carries
   locations (a `--pp=core` variant printing locs, or a Lean reader of the
   marshalled `.co`) — priced S–M; it will surface as `UB_DIFF` rows in
   Z4's `test_ci_sweep.sh` re-record (the sweep now compares whole lines).
   Proposed census row for Z4.
2. **`test_exec.sh` default mode does not fail on `UB_DIFF`** (only via
   `--check-baseline`) — pre-existing; the gate rows all run
   `--check-baseline`, so no gate is fail-open; recorded for Z4's
   VALIDATION rewrite (the "recorded-DIFF" design should say so).
3. **Charter count erratum**: 25 `fs_*` operation entry points, not 24.
4. **Charter cite delta**: `seam_free_interior_pointer.c` oracle loc is
   `<7:39--7:50>` in the committed probe (the charter quotes the scratch
   copy's `<2:39--2:50>`).
5. **Defined-line stdout in `test_exec.sh`**: the exec lanes keep the
   Defined VALUE only (the libc `.libc.c` coverage rows' stdout is never
   compared there; ci_sweep/libc_exec/immaculate compare it). Charter
   §4.1 enumerated the Undefined lines only; widening `VAL:` to the whole
   Defined line is a Z4 candidate (would be a `MISMATCH` class on any
   stdout difference).
6. **Concurrent lanes in this sandbox** make the oracle side `CERB_SKIP`
   en masse (opam-exec contention) — operating note (§0); the lanes'
   fail-closed classification caught it (no false MATCH), but a
   half-skipped run reads as green in default mode only because CERB_SKIP
   is a non-fatal class — worth a `cerb_skip` ceiling in Z4.
7. **Same-hunk seam rows** Z-09, Z-11, Z-12 (Z2's list) were fixed inside
   Z1's Z-06/Z-07/Z-08 mirrors (they are the same OCaml arms); recorded in
   the census as FIXED with the hunk cite rather than left for Z2.
9. **Line-number drift of quoted PANIC witnesses** (audit F5): the `PANIC at
   CerbMem.killM CerbMem:1944:10` line in §2 was verbatim on the PRE-rebase
   build; the stamped binary after the rebase and the audit response prints
   `CerbMem:1953:10` (re-measured on `inj_bug.c` + `inject_rand.core`,
   verbatim: `PANIC at CerbMem.killM CerbMem:1953:10: Concrete: FREE was
   called on a dead allocation`). Verbatim-then, not a defect; quoted line
   numbers in panic texts are build-relative.
10. **`zd-d5` `TRIAGED_UB` is provisional** (audit F6): the D3(a)
   "documented model choice" rests on impl_mem.ml:620-624's own `TODO …
   hardcoded ranges` comment; the charter's Z-06 makes the ranges a tray
   question and no draft exists yet. The triage row now says so; Z4 drafts
   the tray question and decides whether the row stays `TRIAGED_UB` or
   moves to the `PINNED_TRAY_<n>` class of charter §4.2.
11. **gcc lane load caveat fired for the auditor** (audit F7): two auditor
   runs at box load 20–30 went red on the single row `csmith/sia_csmith_477.c
   AGREE → SKIP_LEAN_TIMEOUT`; hand-retimed at load 2.4 it completes in
   17.96 s (bound 30 s) with `Specified(132)` = gcc 132 → AGREE. This is
   LADDER.md Tier B row 7's recorded caveat firing, not a regression; no
   baseline change. Z4's Z-31 measurement should add this row's 18 s / 30 s
   margin to the recorded set.
8. **Speclab derived pin encoded the wrong alignment**: `SpecLab/
   ListAppendCore.lean` (generated from the parsed std.core closure) had
   `alloc((16 : Int), size)`; regenerated (commit `8442a67d8`). Any other
   derived artefact that renders `IvMaxAlignment` would show the same
   drift — none did in the battery.

Out of Z1 scope, untouched: Z-28 (Z3), Z-29/Z-30/Z-31 movers, the Z2 seam
audit rows other than the three relayed, Z-40/Z-42/Z-75 (Z4), the tray
drafts 20–33 (Z4), the VALIDATION.md headline rewrite (Z4), the noodle
probe integration beyond the 14 files pinned here (Z4).

## 8. Baseline movement table (every recorded movement, with its commit)

| baseline | row(s) | from → to | commit / cause |
|---|---|---|---|
| tests/immaculate | 11 new `zd-*` pins | (new) DIFF ×9, ORACLE_CRASH ×1 (zd-e2), DIFF zd-z72 | `37d205a0e` pin commit (loc+stderr-aware UB token, whole-payload ERR token) |
| tests/immaculate | g2-memcpy-oob, g2-memcpy-readonly, g3-realloc-dead, g3-realloc-non-heap, lock-const-global, lock-string-literal, trap-bool-uninit, trap-bool-write | MATCH → DIFF (Lean `file:L:C-C` vs oracle `<L:C--L:C>`, honest under the new token) | `37d205a0e` |
| tests/coverage (`scripts/exec_coverage_baseline.txt`) | dynaddr-001/-002 UB_MATCH, dynaddr-003 MATCH | (new rows, hand-inserted) | `37d205a0e` |
| tests/immaculate | zd-d4-copy-alloc-id | DIFF → MATCH | `768be3698` (Z-05) |
| tests/immaculate | zd-d5-device-range-load, zd-d6-free-device-pointer, zd-d6-free-no-provenance | DIFF → MATCH; zd-d7 DIFF (token ERR → UB179a@unknown); + zd-z2m02-device-funptr-call MATCH\|L=CRASH (new) | `c61b78f70` (Z-06/07/08/10, Z2-M-02) |
| tests/immaculate | zd-z2p01-stdout_escape, zd-z2p01-stderr_escape (new) | DIFF; 21 VAL rows reshape to the whole Defined payload (all MATCH) | `cf664a2c4` pin commit |
| tests/immaculate | zd-d1, zd-d2, zd-d7, zd-z72-stderr-ub, zd-z2p01 ×2 + the 8 pre-existing UB rows above | DIFF → MATCH (14 rows — recounted, audit F4); s4b-memcmp-hugesize token loc "unknown location" → "<unknown location>" | `1c1311a57` (Z-01/02/03/67/72, Z2-P-01) |
| tests/immaculate | zd-da-offset, zd-da-align16 | DIFF → MATCH | `8da338f42` (Z-76) |
| tests/immaculate | header only (register wording; rows unchanged) | — | register commit |
| tests/verify/expectations.txt | t2_add ×2 UB pins | code-only → whole payload (Lean == oracle, unchanged verdict) | `666694a07` (§4.1) |
| speclab `SpecLab/ListAppendCore.lean` (derived pin) | malloc_proxy alloc align | `(16 : Int)` → `(8 : Int)` | `8442a67d8` (Z-76 consequence) |
| ci_sweep scratch spot sweep (NOT the committed TSVs) | suite/fs/stat.c, freebsd/cat.c | STDOUT_DIFF / LEAN_FAIL → LEAN_CRASH (CerbFS refusal) | `deb2338a8` (Z-27) — expected; + 6 stale-snapshot movements (§2, Z-27) not caused here |
| scripts/gcc_oracle_baseline.txt + gcc_oracle_triage.txt | 7 new tests/immaculate/nolibc/zd-*.c rows (SKIP_UB ×2, SKIP_GCC_STDOUT, SKIP_LEAN_CRASH, TRIAGED_ADDR ×2, TRIAGED_UB) | (new rows; three triaged as divergence-class observers, §9.1) | `794d7372d` |
| every other Tier A/B baseline (exec minimal/coverage/debug/float, bytes, libc_exec, multi_tu, parse/core/elab, uri, cn_coverage, verify, speclab gates, libxml2; every pre-existing gcc-lane row) | — | no movement | — |

Expected-movement checklist from the brief: the 7+2 immaculate pins
DIFF→MATCH ✓ (7 = zd-d1/d2/d4/d5/d6×2/d7; +2 = zd-da-offset/-align16);
`stat.c`/`cat.c` → loud CerbFS refusal in the spot sweep ✓; UB rows in
immaculate gaining the loc token ✓ (all 8, via a DIFF interlude at the pin
commit). Movements NOT on the list, each understood: the 6 stale-snapshot
sweep rows (§2, Z-27); the two verify UB pins (token shape); the speclab
derived pin (Z-76 consequence); the s4b token loc rendering.

## 9. The final battery — Tier A + Tier B on the rebased head (`3d1883644` + 21 commits), fresh stamps

Freshness (`tools/check_driver_fresh.sh --check`, verbatim):
```
check_driver_fresh: oracle OK (bin 69e1625994c5fbcd2328126c55e5b78d7835314286b731bf25f5197d40a2589f, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
check_driver_fresh: lean OK (bin 4ebda58b7d04185e2e8d555f55e01e23f99b4f46cf7a30f406cd2c361372ef25, src 5e5df48ac0fd9fb66695f367936d150cdd9454f2c987f2aa81f389358e072336)
```

Every row per `scripts/LADDER.md`, run SERIALLY with `SKIP_BUILD=1` (the stamp is the freshness proof), one line per lane — `rc` and the verbatim SUMMARY/gate line(s):

```
### TIER A
### ./scripts/test_unit.sh rc=0 (12s) ::
      All PP tests passed Total: 6 passed, 0 failed 
### ./scripts/test_exec.sh --check-baseline rc=0 (11s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage rc=0 (22s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug rc=0 (9s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float rc=0 (8s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_bytes.sh rc=0 (5s) ::
      SUMMARY: exec_match=9 neg_pinned=5 fail=0 
### ./scripts/test_libc_exec.sh rc=0 (13s) ::
      SUMMARY: match=7 diff=0 ALL MATCH RECORDED BASELINE 
### ./scripts/test_multi_tu.sh rc=0 (2s) ::
      SUMMARY: total=2 match=2 fail=0 ALL PASSED 
### ./scripts/test_parse.sh rc=0 (9s) ::
      Lean parse:     106 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) ALL PASSED 
### ./scripts/test_core.sh rc=0 (9s) ::
      Lean parse:     106 ok, 0 failed ALL PASSED 
### ./scripts/test_elab.sh rc=0 (15s) ::
      SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0 
### ./scripts/test_libxml2_uri.sh rc=0 (11s) ::
      GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16) 
### ./scripts/test_cn_coverage.sh --check-baseline rc=0 (27s) ::
      SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 BASELINE OK (213 entries, exact match) 
### TIER B
### ./scripts/test_libxml2.sh rc=0 (618s) ::
      SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each) ALL PASSED 
### ./scripts/test_parse.sh tests/ci rc=0 (22s) ::
      Lean parse:     128 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) ALL PASSED 
### ./scripts/test_core.sh tests/ci rc=0 (15s) ::
      Lean parse:     128 ok, 0 failed ALL PASSED 
### ./scripts/test_verify.sh rc=0 (51s) ::
      test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points) 
### ./scripts/test_immaculate.sh rc=0 (35s) ::
      OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL). 
### ./scripts/test_speclab.sh --selftest rc=0 (3s) ::
      test_speclab: PASS (both pipelines agree on Specified(0)) 
### ./scripts/test_speclab.sh --plant rc=0 (1s) ::
      test_speclab: PASS (both pipelines agree on Specified(2)) 
### ./scripts/test_speclab_divmod.sh --gate rc=0 (2s) ::
      CoreGateTest: ALL PASSED test_speclab_divmod: PASS (--gate) 
### ./scripts/test_speclab_bytearr.sh --gate rc=0 (2s) ::
      ByteArrGateTest: ALL PASSED test_speclab_bytearr: PASS (--gate) 
### ./scripts/test_speclab_list.sh --gate rc=0 (3s) ::
      ListGateTest: ALL PASSED test_speclab_list: PASS (--gate) 
### ./scripts/test_speclab_tree.sh --gate rc=0 (3s) ::
      TreeGateTest: ALL PASSED test_speclab_tree: PASS (--gate) 
### ./scripts/test_speclab_seed.sh --gate rc=0 (2s) ::
      SeedGateTest: ALL PASSED test_speclab_seed: PASS (--gate) 
### ./scripts/test_hang_plant.sh rc=0 (14s) ::
      
### ./scripts/test_kill_plant.sh rc=0 (164s) ::
      PLANT OK   [libc_exec no MATCH]: SUMMARY: match=0 diff=7 PLANT OK   [libc_exec SIGKILL stub -> DIFF (not KILL)]: SUMMARY: match=0 diff=7 
### ./scripts/test_fuel_plant.sh rc=0 (5s) ::
      PLANT OK   [parse/abort -> LEAN_FAILURE counted]: Lean parse:     0 ok, 0 failed, 0 timeout (>60s; fatal), 1 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL) 
```

Verbatim SUMMARY / baseline-check lines from the per-lane logs (lane key = the command, characters mangled to `_`):
```
__scripts_test_bytes_sh:
  SUMMARY: exec_match=9 neg_pinned=5 fail=0
__scripts_test_cn_coverage_sh___check_baseline:
  SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
  BASELINE OK (213 entries, exact match)
__scripts_test_core_sh:
  Total:          106
__scripts_test_core_sh_tests_ci:
  Total:          250
__scripts_test_elab_sh:
  SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
__scripts_test_exec_sh___check_baseline:
  SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
__scripts_test_exec_sh___check_baseline=scripts_exec_coverage_baseline_txt_tests_coverage:
  SUMMARY: total=202 match=175 ub_match=14 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
__scripts_test_exec_sh___check_baseline=scripts_exec_debug_baseline_txt_tests_debug:
  SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
__scripts_test_exec_sh___check_baseline=scripts_exec_float_baseline_txt_tests_float:
  SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
__scripts_test_libc_exec_sh:
  SUMMARY: match=7 diff=0
__scripts_test_libxml2_sh:
  SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
__scripts_test_libxml2_uri_sh:
  GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
__scripts_test_multi_tu_sh:
  SUMMARY: total=2 match=2 fail=0
__scripts_test_parse_sh:
  Total:          106
__scripts_test_parse_sh_tests_ci:
  Total:          250
__scripts_test_unit_sh:
  Total: 6 passed, 0 failed
__scripts_test_verify_sh:
  test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)
```

### 9.1 The gcc second-oracle lane (Tier B row 7) — RED once, then green

First run on the rebased head (the Z1 pins had entered the lane's corpus: 1953 → 1960 rows), verbatim:
```
SUMMARY: total=1960 compared=1885 agree=1873 agree_nd=0 triaged=9 disagree=3 o2_agree=190 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=46 triaged_addr=9
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-d5-device-range-load.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-da-align16.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-da-offset.c DISAGREE/-
Baseline check: 3 regression(s), 0 improvement(s)
FAILED: 3 unresolved DISAGREE row(s) — triage per the design note before anything else
[287/1960] DISAGREE  tests/immaculate/nolibc/zd-d5-device-range-load.c: gcc=139 lean={3}
[288/1960] DISAGREE  tests/immaculate/nolibc/zd-da-align16.c: gcc=3 lean={2}
[289/1960] DISAGREE  tests/immaculate/nolibc/zd-da-offset.c: gcc=64 lean={8}
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-d5-device-range-load.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-da-align16.c DISAGREE/-
REGRESSION: new file with disagreeing status: tests/immaculate/nolibc/zd-da-offset.c DISAGREE/-
```

Understood as three divergence-class OBSERVERS (design §4 D2/D3(a)), not semantics disagreements — the two `da_*` files observe heap layout (Cerberus's 8-byte malloc alignment, now = the oracle, vs glibc's 16) and `zd-d5` is native UB (SIGSEGV) that the Cerberus model DEFINES via its hard-coded device ranges (impl_mem.ml:620-624; oracle == Lean). Ledger commit `794d7372d`: three `gcc_oracle_triage.txt` entries with value pins (TRIAGED_ADDR ×2, TRIAGED_UB ×1 — the first TRIAGED_UB use) and the seven new baseline rows. Rerun, verbatim:
```
SUMMARY: total=1960 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=46 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
[285/1960] SKIP_UB  tests/immaculate/nolibc/zd-d1-float-inf-to-int-ub.c: (UB:UB017_out_of_range_floating_integer_conversion)
[286/1960] SKIP_UB  tests/immaculate/nolibc/zd-d2-ptr-to-int-narrow-ub.c: (UB:UB024_out_of_range_pointer_to_integer_conversion)
[287/1960] TRIAGED_UB  tests/immaculate/nolibc/zd-d5-device-range-load.c: gcc=139 lean={3} (ledger-declared observer)
[288/1960] TRIAGED_ADDR  tests/immaculate/nolibc/zd-da-align16.c: gcc=3 lean={2} (ledger-declared observer)
[289/1960] TRIAGED_ADDR  tests/immaculate/nolibc/zd-da-offset.c: gcc=64 lean={8} (ledger-declared observer)
[290/1960] SKIP_GCC_STDOUT  tests/immaculate/nolibc/zd-e2-ptr-string-literals.c: (40 bytes)
[291/1960] SKIP_LEAN_CRASH  tests/immaculate/nolibc/zd-z2m02-device-funptr-call.c: (exit 134) PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
```
Movement in this lane: the 7 new rows only; every pre-existing row unmoved (0 regressions, 0 improvements). Wall: 1106 s (first run), within the ~24 min expectation.

## 10. Commits on `arc/zero-discrepancy` above the mainline `3d1883644` (post-rebase ids; `git log --oneline mdd/cerberus-lean..HEAD`)

```
794d7372d zero-discrepancy Z1 instrument: gcc second-oracle ledgers — 7 rows for the new tests/immaculate/nolibc/zd-*.c pins; 3 triaged (2 TRIAGED_A
89ff009f7 zero-discrepancy: the ISO-fix register instantiated — R1, R2 ADMITTED, R3 ADMITTED CONDITIONAL [USER 2026-09-03]; (vii) code markers repla
666694a07 zero-discrepancy Z1 instrument (§4.1): every Undefined-line extractor compares the WHOLE line — ub code, killed-state stderr and loc
8442a67d8 zero-discrepancy Z-76 follow-up (instrument): regenerate the speclab ListAppendCore pinned module — it embedded IvMaxAlignment = 16
deb2338a8 zero-discrepancy Z-27: CerbFS op-by-op served/refused table; every operation the model cannot answer as SibylFS does REFUSES loudly
b42776130 zero-discrepancy Z-24/Z-25/Z-73 (+Z2-FL-03): refuse unsupported and misplaced flags (attributed, exit 2); require LEAN_ABORT_ON_PANIC; decla
8da338f42 zero-discrepancy Z-76 (R2, dynamic-addrs §6): IvMaxAlignment reads CerberusImpl.max_alignment (8), mirroring core_parser.mly:1536-1537
1c1311a57 zero-discrepancy Z-01/Z-02/Z-03/Z-67/Z-72 (+Z2-P-01): UB location and the batch line's stderr/stdout are behaviour — mirror the oracle byt
cf664a2c4 zero-discrepancy Z1 instrument: pin the Z2-P-01 batch-escape reproducers RED; immaculate Defined token is the whole payload
c61b78f70 zero-discrepancy Z-06/Z-07/Z-08/Z-10 (+Z2-M-02): CerbMem kill arms and check order, device ranges, case_ptrval fail-stop — mirror impl_mem
768be3698 zero-discrepancy Z-05 (noodle D4): copy_alloc_id mirrors impl_mem.ml:2766-2770 — the result takes address AND provenance from the integer
37d205a0e zero-discrepancy Z1 instrument: pin the census reproducers RED before the fixes (immaculate loc+stderr-aware token; coverage da_* rows)
927426b86 probe/dynamic-addrs: reproduce the consumer's dynamic_addrs claim (Core-level CONFIRMED, C-unreachable), tray draft 19, R4 candidate, probes
dbb19d69a noodle: record — correct the derived probe count (145 files, 11 dirs)
10af2f9c8 noodle: seam shard (D4 copy_alloc_id value divergence, D5 device range, D6/D7 free verdict classes) + misc/mtu shards + final ranked report
0c79cd97f noodle: shards 3-5 (ctl/lib/elab/out) — L3 stdio dropped at exit, L4 atexit on return, L5 %*d crash, L6 %x int arg UB, E3 ?: static init, 
f3998e1ed noodle: shard 2 (ptr + mem probes) — U1 size_t UAC at 32 bits, P1 ptrdiff array scaling, P2 provenance lost through arithmetic, L1 strncmp
42b86a135 noodle: shard 1 (int + float probes) + record skeleton — D1 UB loc lost for std.core-raised UBs, F1 float-as-double
1d6638b0a zero-discrepancy: charter R3 — §7 asks ruled ([USER 2026-09-03] "Agree re lem. Agree re Q2-10 and R4")
62661d9eb zero-discrepancy: charter R2 — dynamic_addrs addendum (Z-76, Z-77, Z-10, R4)
e6e5b5e3b zero-discrepancy: charter R1 — review amendments F1-F11, register, refusal, Q8-Q10
d2d710659 zero-discrepancy: the census charter (docs/2026-09-03_zero-discrepancy-design.md)
(+ this record commit: the Z1 record and the charter census-row updates)
```

Provenance: every ruling cited is [USER 2026-09-03] as relayed in the brief and the charter (§1, §7); every classification, cite, measurement and text here is [AGENT] (the Z1 worker), quoted outputs verbatim, tallies marked derived. Nothing merged, nothing pushed; the primary checkout, `deps/`, `lem-lean/` and other worktrees untouched; the only scratch (`.tmp/z1/`, git-ignored) is ephemeral and will be deleted at slice end.


## 10. Orchestrator boundary review [AGENT, orchestrator, 2026-09-03]

Independent re-verification at the slice boundary (worker-claimed green
is never accepted). In this worktree at head `8827a433f` (rebased on
`3d1883644`): `make lean-prelude-src`; `DUNE_CACHE=disabled build_cerberus`
(oracle stamp bin `5b62df0de1e3…` — a fresh cache-disabled build, hence a
different binary hash from the worker's `69e16259…`; same source hash);
`CERB_MEM_MAX=32G build_lean` (lean stamp bin `4ebda58b7d04…` — identical
to the worker's, so the Lean binary is bit-for-bit the one the worker
gated); `check_driver_fresh --check` OK. Then every gate lane SERIALLY
(the worker's operating note about concurrent lanes → oracle `CERB_SKIP`
noise was respected): 19 lanes, 19 × rc 0, no baseline movement anywhere.
Verbatim closing lines of the three load-bearing lanes (the re-run log
kept each lane's last four lines, so the per-class SUMMARY counts of the
exec and gcc lanes are not in it — their baseline verdict lines are):

```
exec minimal:  Baseline check: 0 regression(s), 0 improvement(s)
               BASELINE OK
libxml2:       SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
gcc lane:      Baseline check: 0 regression(s), 0 improvement(s)
               gcc second-oracle lane OK
```

The full log is ephemeral (`.tmp/z1-reverify.log`, container scratch,
deleted at slice end); every SUMMARY/BASELINE line matched the worker's
§9 verbatim where both were recorded.

Decision confirmed [AGENT, orchestrator]: Z-01's std.core stamping with
`Loc.region ⟨file,0,0⟩ ⟨file,0,0⟩` (file tracked, line/column not) is
ACCEPTED as a documented Pos-payload divergence under the mirror-or-
document clause — the only execution-path consumer of a std.core
position is `is_library_location` (file), and the oracle substitutes the
C call-site loc for every library-located UB before printing. Registered
as a Z2 fix-phase row: if the Parsec parser can carry a line table
cheaply (S), mirror the positions; otherwise the declaration stands and
the edge (a library-located UB with NO C call site available for
substitution would print `<0:0--0:0>` here vs the oracle's std.core
position) is probed and recorded.

Spot re-runs by the orchestrator earlier the same day (before Z1 acted)
confirmed the two relayed Z2 rows on stamped binaries: `stdout_escape.c`
(oracle `stdout: "a\bb\007\127\195\169\011\012\027|\n"` vs Lean raw
bytes) and `aligned_alloc_zero_nolibc.c` (oracles exit 125
`Division_by_zero`, Lean a UB verdict) — the latter is Z2's, not fixed
here. Consumer change manifest for this slice:
`docs/2026-09-03_zero-discrepancy-Z1-change-manifest.md`.

## 11. Audit response (pre-merge audit `docs/2026-09-03_zero-discrepancy-Z1-audit.md` @ `audit/z1-premerge` `7f8549fe7`: MERGE-WITH-FIXES)

One audit-response commit on top of the orchestrator's boundary review
`e6f86bdcb`. Findings are claims: F1 was re-measured on the stamped
binaries (oracle `6e63ade6…`, lean `4ebda58b…`) BEFORE any change.

**F1 (MAJOR) — `CerbFS.fs_truncate` served a negative length.** Auditor's
probe (libc; `create+write "hello"; close; int r = truncate("t.txt", -1);
return r == -1 ? 1 : 2;`, user-declared prototype), verbatim:

```
before  fork-oracle rc=0: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
        upstream    rc=0: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
        Lean        rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
after   Lean        rc=0: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

REPRODUCED (the served arm `contents.take len.toNat` emptied the file and
returned 0). Mirror: `fs_spec.lem:4020` `fsm_cond_raise EINVAL (len < 0)`
(posix/truncate.md EINVAL:1) as the FIRST check — `(st, .inl (.other
"EINVAL"))`, the shape `fs_lseek` already used; `driver.lem store_error`
turns it into errno + −1 exactly as for the oracle. Header row now reads
"0 ≤ len ≤ size → SERVED; negative → EINVAL SERVED". Pin
`tests/immaculate/libc/zd-f1-truncate-negative-length.c`, measured in the
lane on the pre-fix binary then after the fix:

```
before  DIFF   zd-f1-truncate-negative-length  O[VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}] L[VAL:{value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}]
after   (see §11.1 — re-recorded MATCH)
```

Same-shape re-check of every signed argument the code converted with
`.toNat` (each now MIRRORED or REFUSED, never clamped; cites in-code and
in the header table): every fd → `fd.natAbs` (`sibylfs.ml:169-170`
`fd_of_int n = FD (abs n)`; `.toNat` mapped every negative fd to 0, so
`close(-1)`/`lseek(-1,…)` answered EBADF where SibylFS acts on fd 1) —
`isStdFd` now tests the abs value; every read/write count → `natAbs`
(`sibylfs.ml run_read/run_pread/run_write/run_pwrite` `abs (to_int size)`);
`fs_write`/`fs_pwrite` write exactly |count| bytes of the buffer and REFUSE
when |count| exceeds the buffer (the shorter-buffer arm is not mirrored);
`fs_pread` negative offset → EINVAL (`fs_spec.lem:3392`); `fs_pwrite`
negative offset → EINVAL (`:4287`); `fs_open` negative oflag → REFUSED
(SibylFS tests the bits of `Nat_big_num.to_int32 oflag`; `.toNat` read it
as no flags = a read-only open); `fs_lseek` fd → natAbs (its negative
result was already EINVAL, `:5119`); `fs_umask` `old.toNat` untouched (the
previous mask is never negative; a negative NEW mask is observable only
through stat/open modes, refused). The auditor's N-grade directory-PATH
residual (EISDIR at `:4025` vs this model's ENOENT for `truncate`/
`unlink`/`rename` on a directory path; `open` with O_CREAT on a directory
path) is stated in the header table as NOT DISTINGUISHED (the model has no
path classifier) — not fixed here.

**F2 (MINOR) — `--parse-core` bypassed `refuseFlag`.** The branch now runs
`refuseFlag` over every `--` token in its file list (`--stdin` excepted).
Plants, verbatim (rc and first line):

```
--parse-core runtime/libcore/std.core --frobnicate → cerberus-lean: refused — --frobnicate: unknown flag; this port accepts only … rc=2
--parse-core --batch runtime/libcore/std.core       → cerberus-lean: refused — --batch: known flag out of its canonical position (…) rc=2
--parse-core runtime/libcore/std.core               → runtime/libcore/std.core: Core file: 22 fun, 52 proc, 0 def/impl, 0 struct/union, 0 glob, 36 builtin rc=0
```

**F3 (MINOR) — bare leading `--first` accepted in human mode.**
`firstTrace := (batchMode || ppCoreMode) && rest0.head? == some "--first"`;
a bare `--first` reaches the scan and is refused. Plants, verbatim:

```
--first fnb.json          → cerberus-lean: refused — --first: known flag out of its canonical position (…) rc=2
--batch --first fnb.json  → Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} rc=0
--pp-core --first fnb.json → (signature dump) rc=0;   --batch fnb.json → Defined {value: "Specified(7)", …} rc=0
```

**F4 (MINOR) — tallies** recounted (derived, labelled) and corrected in
§0/§2/§8: 46 immaculate rows after this commit (45 at the audit; the
first draft said 44), 14 flips at `1c1311a57` (not 15), 20 flips across
the slice.

**F5 (MINOR) — cites**: the change manifest's `Main.lean:1057`/`:359` →
`:1063` (the `IO.getEnv` check) / `:387` (`def batchEscape`), recomputed
after this commit's edits (`refuseFlag` stays `:1038`; `firstTrace` is
`:1087`); the `CerbMem:1944:10` witness is annotated as pre-rebase (§7.9),
re-measured `CerbMem:1953:10`.

**F6** — provisional note added to the `zd-d5` triage row and §7.10.
**F7** — recorded in §7.11 (LADDER row-7 load caveat; no baseline change).
**N-notes** — left as the auditor recorded them.

### 11.1 Gates after the audit-response commit (serial, capped 32G, fresh stamps)

Freshness (`--check`, verbatim) and every lane line (`rc`, wall, verbatim SUMMARY/baseline line), from the serial gate run after the edits (lean stamp `ba5a7ec0…`):

```
check_driver_fresh: oracle OK (bin 6e63ade67b7395d50e0345ccc84eefe97b0a99cdba94439831d9ff1a4e2f1217, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
check_driver_fresh: lean OK (bin ba5a7ec0229f9a9c9d0964add550e14eeb289ec5a5ee2d03ee67c78daaf20b80, src 9e8574f24e59a6e94cdfa4921fa6e49490a1ee6397ff0c0f30382ae0c96008cc)
### imm check rc=1 ::
      DEVIATION: zd-f1-truncate-negative-length expected [<absent>] got [MATCH | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}] 
### ./scripts/test_immaculate.sh --record-baseline rc=0 (37s) ::
      BASELINE RECORDED: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/zero-discrepancy/tests/immaculate/baseline.txt 
### ./scripts/test_immaculate.sh rc=0 (38s) ::
      OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL). 
### ./scripts/test_unit.sh rc=0 (12s) ::
      All PP tests passed Total: 6 passed, 0 failed 
### ./scripts/test_exec.sh --check-baseline rc=0 (12s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage rc=0 (22s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug rc=0 (10s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float rc=0 (8s) ::
      Baseline check: 0 regression(s), 0 improvement(s) BASELINE OK 
### ./scripts/test_bytes.sh rc=0 (2s) ::
      SUMMARY: exec_match=9 neg_pinned=5 fail=0 
### ./scripts/test_libc_exec.sh rc=0 (13s) ::
      SUMMARY: match=7 diff=0 ALL MATCH RECORDED BASELINE 
### ./scripts/test_multi_tu.sh rc=0 (2s) ::
      SUMMARY: total=2 match=2 fail=0 ALL PASSED 
### ./scripts/test_parse.sh rc=0 (10s) ::
      Lean parse:     106 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) ALL PASSED 
### ./scripts/test_core.sh rc=0 (8s) ::
      Lean parse:     106 ok, 0 failed ALL PASSED 
### ./scripts/test_elab.sh rc=0 (18s) ::
      SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0 
### ./scripts/test_libxml2_uri.sh rc=0 (21s) ::
      GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16) 
### ./scripts/test_cn_coverage.sh --check-baseline rc=0 (56s) ::
      SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0 BASELINE OK (213 entries, exact match) 
### ./scripts/test_verify.sh rc=0 (76s) ::
      test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures, 21 corpus points) 
### ./scripts/test_hang_plant.sh rc=0 (13s) ::
      
### ./scripts/test_kill_plant.sh rc=0 (171s) ::
      PLANT OK   [libc_exec no MATCH]: SUMMARY: match=0 diff=7 PLANT OK   [libc_exec SIGKILL stub -> DIFF (not KILL)]: SUMMARY: match=0 diff=7 
### ./scripts/test_fuel_plant.sh rc=0 (5s) ::
      PLANT OK   [parse/abort -> LEAN_FAILURE counted]: Lean parse:     0 ok, 0 failed, 0 timeout (>60s; fatal), 1 lean failure(s) (crash / nonzero exit without a printed verdict; fatal) test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL) 
### ./scripts/test_gcc_oracle.sh --check-baseline rc=0 (1278s) ::
      SUMMARY: total=1960 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=46 triaged_addr=11 triaged_ub=1 Baseline check: 0 regression(s), 0 improvement(s) 
+zd-f1-truncate-negative-length MATCH | L=VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}   (the only baseline row change; 46 rows)
```

The gcc lane went green first time here (box load 0.5–9 at the start); the auditor's load-caveat row `csmith/sia_csmith_477.c` stayed AGREE (skip_lean_timeout=11 = the baseline's 11). Every other Tier A/B row unmoved. Scratch `.tmp/z1a/` deleted at the end of this response.
