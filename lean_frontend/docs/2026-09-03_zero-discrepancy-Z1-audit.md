# ZERO-DISCREPANCY Z1 — pre-merge audit (2026-09-03)

Audited: branch `arc/zero-discrepancy` @ `e6f86bdcb` (24 commits above
mainline `mdd/cerberus-lean` @ `3d1883644`), in the worktree
`worktrees/cerberus-lean-arc/zero-discrepancy` (read + probes only; nothing
there was edited). This document lives on `audit/z1-premerge` (created from
`e6f86bdcb`). Auditor: the pre-merge auditor [AGENT]; every grading below is
[AGENT]; quoted engine/lane lines are verbatim from this audit's own runs on
the stamped binaries; tallies are labelled derived. The merge itself is
ff-only on operator sign-off and is not this document's decision.

Inputs read in full: the charter `docs/2026-09-03_zero-discrepancy-design.md`
(R3), the Z1 record `docs/2026-09-03_zero-discrepancy-Z1-record.md` (incl.
§10), the change manifest `docs/2026-09-03_zero-discrepancy-Z1-change-manifest.md`,
`VALIDATION.md` ("ISO-fix register" + "Known, LOUD limits"),
`scripts/LADDER.md`, `docs/2026-08-30_gcc-second-oracle-design.md` §2.3/§4,
`git diff 3d1883644..e6f86bdcb` for every product, instrument and baseline
file named in the brief, and the OCaml twins at the cited lines
(`memory/concrete/impl_mem.ml`, `util/cerb_location.ml`, `util/cerb_runtime.ml`,
`parsers/core/core_parser.mly`, `backend/common/driver_ocaml.ml`,
`backend/driver/main.ml`, `backend/common/pipeline.ml`,
`frontend/model/{core_run,core_eval,driver,fs}.lem`,
`sibylfs/src/fs_spec.lem`, the switch's `lib/ocaml/{bytes,string}.ml`).

Operating discipline: every Lean invocation through `scripts/capped` with
`CERB_MEM_MAX=16G`; lanes and probes SERIAL (never two in flight); `ulimit -c 0`;
scratch under the container's ephemeral `.tmp/z1audit/` (deleted at slice end).

Freshness, verbatim (`tools/check_driver_fresh.sh --check`, first action):

```
check_driver_fresh: oracle OK (bin 5b62df0de1e37b90a4a6e828200673a0dbc423f4615145dd7c4e7170d5d7437d, src c9c1a7067139b3ceb4eb0ad6870b93d8d0dbbaa9bd39e0397f11e8c975737a3b)
check_driver_fresh: lean OK (bin 4ebda58b7d04185e2e8d555f55e01e23f99b4f46cf7a30f406cd2c361372ef25, src 5e5df48ac0fd9fb66695f367936d150cdd9454f2c987f2aa81f389358e072336)
```

(= the record §10 orchestrator stamps: oracle `5b62df0d…`, lean `4ebda58b…`.)

## 0. Verdict

**MERGE-WITH-FIXES** [AGENT].

The slice does what it claims: every changed CerbMem/CerbLocation/CoreParser/
Main hunk computes what the cited OCaml computes (§1 below, arm by arm, with
12 three-engine probe re-runs all as recorded); the whole-line extractors are
anchored and complete and the loc/stderr plants go red (§2); the refusals are
loud, attributed and run before any work (§3); the record's quoted lines
reproduce and the census rows cite their commits (§4). One MAJOR finding
(F1) — a CerbFS SERVED path that answers differently from SibylFS on a
reachable input, i.e. exactly the shape Z-27 claims to have closed — plus two
MINOR CLI-contract gaps (F2, F3), tally/cite errata (F4, F5) and notes. F1's
fix is one arm plus one immaculate pin; recommended to land on the branch
(re-gate Tier A) before the ff-merge, since the Z-27 deliverable statement
("the served set IS the correct-answer set") is otherwise false as committed.
None of the findings indicts an execution result on any lane corpus.

Gate evidence gathered here (all rc 0 unless stated): coverage exec lane
(`BASELINE OK`, 3 `dynaddr` rows as pinned), `test_verify.sh` (117/117),
`test_immaculate.sh` (OK at baseline), the gcc second-oracle lane (§2.iv:
first run RED by one load-induced TIMEOUT that hand-retimes to AGREE; second
run quoted in §2.iv).

## 1. Findings (MAJOR → MINOR → NOTE)

### F1 — MAJOR — `CerbFS.fs_truncate` serves a wrong answer for a negative length

`lean_frontend/CerbFS.lean:378-390` (Z-27 commit `deb2338a8`): the served arm
is `else let files' := (path, contents.take len.toNat) :: …; (…, .inr 0)`.
For `len < 0`, `Int.toNat` is 0, so the file is EMPTIED and the call returns
0. SibylFS: `sibylfs/src/fs_spec.lem:4020` `fsm_cond_raise EINVAL (len < 0)`
(`posix/truncate.md EINVAL:1`) — the call fails with EINVAL and the file is
untouched. The header table row "fs_truncate no open fd on the path, len ≤
size → shrink → SERVED" is therefore false on the negative half of "≤".
Reachable from C: `core_run.lem:1320-1326` dispatches `Impl (BuiltinFunction
"truncate")` to `FS_TRUNCATE`; `runtime/libc/include/posix/unistd.h:87` only
comments the prototype out, so a user declaration suffices. Probe (libc,
`.tmp/z1audit/p/trunc_neg.c`: create+write "hello", close, `int r =
truncate("t.txt", -1); return r == -1 ? 1 : 2;`), verbatim:

```
== libc /home/dev/projects/cerberus-lean-proj/.tmp/z1audit/p/trunc_neg.c
fork    rc=0: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
```

A value-level Lean ≠ oracle on a program both engines run — a BUG under §1.1,
and the fail-open shape the slice set out to remove from CerbFS. Exposure is
low (obscure op, user-declared prototype), which is why this is not
DO-NOT-MERGE; but it is a served-set claim that a one-line probe falsifies.
FIX: mirror `fs_spec.lem:4020` — `if len < 0 then (st, .inl (.other
"EINVAL"))` as the first check (the same `.other "EINVAL"` shape `fs_lseek`
already uses; `driver.lem store_error` turns it into errno + −1 exactly as
for the oracle), amend the header row to "0 ≤ len ≤ size", and pin
`trunc_neg.c` in `tests/immaculate/libc/` (expected MATCH `Specified(1)`).
Related, same family (NOTE-grade, listed here so the fix commit can decide):
SibylFS raises `EISDIR` for a directory path (`fs_spec.lem:4025`) where this
model, having no directories, answers `ENOENT` (`fs_truncate`, and likewise
`fs_unlink`/`fs_rename` on a directory path); `fs_open` with `O_CREAT` on a
directory path creates a "file" of that name. Not probed here; the honest
disposition is a refusal for any path the model cannot classify, or a
header note that directory PATHS (not just directory OPS) are out of the
served set.

### F2 — MINOR — the `--parse-core` path bypasses `refuseFlag`

`Main.lean:1080-1081`/`:1110-1111` set `pending := []` for `parseCoreMode`,
and the `--parse-core` branch (`:1179-1208`) consumes `args.drop 1` as file
names with no `--` check. Probes (Lean only), verbatim:

```
-- cerberus-lean --parse-core runtime/libcore/std.core --frobnicate
   rc=1 :: runtime/libcore/std.core: Core file: 22 fun, 52 proc, 0 def/impl, 0 struct/union, 0 glob, 36 builtin uncaught exception: no such file or directory (error code: 4294967294)
-- cerberus-lean --parse-core --batch runtime/libcore/std.core
   rc=1 :: uncaught exception: no such file or directory (error code: 4294967294)
```

Both are the pre-Z-24 shape (a flag treated as a FILE NAME; loud, not
attributed), contradicting `VALIDATION.md:267-276` ("Any other `--` token …
is refused loudly … never treated as a file name (it used to be)") and the
`Main.lean:1069-1076` contract comment. No execution content (`--parse-core`
parses only, and no harness passes it a flag), hence MINOR. FIX: in the
`--parse-core` branch run `refuseFlag` on every `args.drop 1` element that
starts with `--` and is not `--stdin`.

### F3 — MINOR — `--first` is accepted as argv[0] without `--batch`/`--pp-core`

`Main.lean:1081` `rest0 := if batchMode || ppCoreMode then args.drop 1 else
args`, `:1085` `firstTrace := rest0.head? == some "--first"`: with no mode
flag, `rest0 = args`, so a leading `--first` is consumed as the single-trace
switch in HUMAN mode. Probe, verbatim:

```
-- cerberus-lean --first /home/dev/projects/cerberus-lean-proj/.tmp/z1audit/p/fnb.json
   rc=0 ::   return value: 7
```

`refuseFlag`'s own text says "`--first` must immediately follow
`--batch`/`--pp-core`" (and `--first --batch x.json` IS refused, rc 2). A
CLI-contract gap only (the human-mode output is not compared by any lane).
FIX: `firstTrace := (batchMode || ppCoreMode) && rest0.head? == some
"--first"`, so a bare leading `--first` reaches the scan loop and is refused.

### F4 — MINOR — record tallies (derived counts do not reconcile)

- `tests/immaculate/baseline.txt` has **45** non-comment rows (derived:
  `grep -vc '^#\|^$'`), not "44" (record §0 headline). 31 pre-existing + 11
  new at `37d205a0e` + 1 (`zd-z2m02`, `c61b78f70`) + 2 (`zd-z2p01-*`,
  `cf664a2c4`) = 45 (derived from `git show <c> -- tests/immaculate/baseline.txt`).
- DIFF→MATCH flips per commit (derived from the same diffs): `768be3698` 1,
  `c61b78f70` 3, `1c1311a57` **14** (zd-d1, zd-d2, zd-d7, zd-z72-stderr-ub,
  zd-z2p01 ×2, and the 8 pre-existing UB rows g2-memcpy-oob,
  g2-memcpy-readonly, g3-realloc-dead, g3-realloc-non-heap,
  lock-const-global, lock-string-literal, trap-bool-uninit, trap-bool-write),
  `8da338f42` 2 — total **20**. The record says "15 immaculate rows
  DIFF→MATCH" for `1c1311a57` (§2 and §8; the enumerated list there sums to
  14) and "15 flips DIFF→MATCH by fixes" in §0 (12 zd-* flips + 8
  pre-existing = 20; 12 if only the zd-* rows are meant). Erratum of count,
  not of substance — no row's recorded status is wrong (§4.1 below).
- "25 `fs_*` operation entry points": CONFIRMED (derived: 38 `val fs_*` in
  `frontend/model/fs.lem` minus the 11 stat accessors, `fs_string_of_error`
  and `fs_initial_state` = 25).
- §8 table rows vs `git log 3d1883644..e6f86bdcb`: every commit named in §8
  exists with the described content; §10's list omits only the record and
  boundary-review commits it announces ("+ this record commit").

### F5 — MINOR — change-manifest line cites that do not resolve to the named declaration

`docs/2026-09-03_zero-discrepancy-Z1-change-manifest.md` §1, last row:
`Main.lean:1057` is a comment line inside the Z2-FL-03 explanation (the
`IO.getEnv "LEAN_ABORT_ON_PANIC"` check is `Main.lean:1063`); `Main.lean:359`
is inside the batch-format doc comment (`def batchEscape` is `Main.lean:387`).
`Main.lean:1038` (`refuseFlag`) and every other cite in the manifest resolve
exactly (checked: `CerbMem.lean:2640/1912/2003/2007/1232/2370`,
`CoreParser.lean:2333/2319/1281`, `CerbLocation.lean:222/205`;
`CerbFS.lean:437/234/295` in the record). Also NOTE: the record's verbatim
witness `PANIC at CerbMem.killM CerbMem:1944:10` (§2, Z-10) was true of the
worker's pre-rebase build; the stamped binary now prints `CerbMem:1953:10`
(§4.1) — verbatim-then, not a defect.

### F6 — MINOR — gcc-lane triage of `zd-d5-device-range-load.c` (`TRIAGED_UB`) rests on a thin "documented model choice"

Design §4 D3(a): "UB the Cerberus memory model *deliberately* defines
(documented model choices) → `TRIAGED_UB` with the cite". The ledger cite is
`impl_mem.ml:620-624`, whose documentation is `(* TODO: this is stupid …
hardcoded ranges to match the Charon tests... *)`. The classification is
defensible — the program (`*(int*)0xABC`) is natively UB (SIGSEGV 139), the
model defines device memory on purpose, and oracle == Lean == `Specified(3)`
(§4.1) — and it is NOT the D1 stop-and-report class (no engine disagrees
with the other; gcc is not a referee for a deliberately-defined UB). But the
charter's own Z-06 row says the ranges are "ALSO a tray question", no tray
draft exists, and the `PINNED_TRAY_<n>` class the charter §4.2 mandates for
oracle==Lean≠gcc rows does not exist yet (Z4). The two `TRIAGED_ADDR` rows
(`zd-da-offset`: heap-to-stack distance; `zd-da-align16`: `malloc(0) % 16`)
are squarely design §2.3's DIVERGENT `max_alignment` / "allocation addresses"
rows — D2, correctly ledgered, value pins present. RECOMMEND (Z4): draft the
device-ranges tray question and decide then whether `zd-d5` stays
`TRIAGED_UB` or moves to `PINNED_TRAY`; no change needed for this merge.

### F7 — NOTE — gcc lane first run RED by one load-induced `SKIP_LEAN_TIMEOUT`

See §2.iv. `csmith/sia_csmith_477.c` `AGREE → SKIP_LEAN_TIMEOUT` with the
box at load ≈ 30 (other agents); hand-retimed at load 2.4: 17.96 s wall,
`Specified(132)` = gcc exit 132 → AGREE. LADDER.md Tier B row 7 says exactly
this ("a REGRESSION whose only movement is into SKIP_LEAN_TIMEOUT is re-run
on a quiet box before it is read as red"). Not a Z1 defect; the 18 s / 30 s
margin on this row is the standing (b)-class fragility the charter's Z-31
already owns.

### N1 — NOTE — ISO-fix marker bijection will need "sites", not "occurrences"

`-- ISO-fix register R1` appears once (`CerbDecode.lean:84`); `ISO-fix
register R2` appears twice (`:157` docstring, `:166` the code marker). A
future (vii) gate must count marked sites, not grep hits.

### N2 — NOTE — `killM` (and the device `doLoad`/`doStore`) do not update `lastUsed`

`impl_mem.ml:1541` (kill), `:1567` (load), `:1687` (store) set `last_used`;
the Lean `killM` state update sets only `deadAllocations`/`allocations`
(pre-existing, unchanged by Z1). `last_used` is only READ by the JSON state
dump (`impl_mem.ml:2997`) — unobservable on the batch path. Z2 seam row.

### N3 — NOTE — `isLibraryLocation`'s suffix test is exact in practice

`Cerb_runtime.in_runtime x` is always `<prefix>/lib/cerberus-lib/runtime/x`
(`util/cerb_runtime.ml`, `mk`), whether `<prefix>` comes from `--runtime`,
`CERB_INSTALL_PREFIX` or the opam switch; the harnesses pass
`--runtime=$PROJECT_ROOT/_build/install/default` to BOTH the oracle and the
`--cabs-json` step, so every header path Lean sees ends in
`runtime/libc/include/…`, and the suffix test agrees with the oracle's exact
`Filename.dirname` membership on every path either engine produces. The
documented residual (a USER file under a directory literally named
`runtime/libcore` etc.) is the only gap. Also for completeness:
`is_library_location` has two further consumers, `core_reduction.lem:1160/1170`
(the `--rewrite` pass, not on the exec path), beyond the three the record
names.

### N4 — NOTE — loud-but-unattributed CLI shapes outside the `--` contract

`--batch --libc --frobnicate x.json` (the value-consuming flag eats the
token; rc 1 with the `--libc requires at least one --libc-tu` message) and
`--batch -h x.json` (single-dash token → `uncaught exception: no such file
or directory`, rc 1; the oracle's cmdliner accepts `-h`). Neither is a
`--` token in a scan position, so neither contradicts the stated contract;
recorded for the CLI's next pass.

### N5 — NOTE — the exec-lane "same-source perturbation" is not a plant

Inserting a column in `float_inf_to_int_ub.c` moves BOTH engines (shared
front end), so `--check-baseline` on a status-only baseline stays green by
design (§2.i (3c) below — and the front end did not even move the loc for a
space before the cast). The valid plant is the one the record used and this
audit re-ran: a stub that shifts only the Lean side.

### N6 — NOTE — no new fail-open in the changed scripts

`git diff 3d1883644..e6f86bdcb` over `scripts/`, `tests/parity-probes/`,
`tests/noodle-probes/run_noodle.sh`, `tests/mem-scale-probes/`: no added
`2>/dev/null`; the only `|| true` added is `test_golden.sh:33`'s pre-existing
capture idiom (the value is then compared, not absorbed) and
`run_probe.sh:64-65`'s `grep … || true` on display-only lines; `${X:-default}`
occurrences are configuration defaults (`PD_LIBCJSON`, `CERB_TEST_MEM_MAX`).
`test_immaculate.sh:156`'s `2>/dev/null` on the cabs-json step is
pre-existing and guarded by `|| fail`.

## 2. Mirror fidelity — hunk by hunk (question 1)

Method: read the Lean hunk against the OCaml at the cited lines; where a
behaviour is C-observable, re-run the reproducer on fork oracle + upstream
(`deps/cerberus-upstream` @ `b9aeedcb4`, read-only) + Lean (§4.1 has the
verbatim lines). PASS = same arms, same order, same conditions.

| Lean hunk | OCaml | Verdict |
|---|---|---|
| `CerbMem.killM` arm ORDER: null → function → `Prov_none` concrete → `Prov_device` concrete → `Prov_symbolic` → `Prov_some` | `impl_mem.ml:1464-1550` `kill`: `PVnull` (`SW_forbid_nullptr_free` ? `MerrFreeNullPtr` : `return ()`), `PVfunction` → `MerrOther "attempted to kill with a function pointer"`, `(Prov_none, PVconcrete)` → `MerrOther "… lacking a provenance"`, `(Prov_device, PVconcrete)` → `return ()`, `(Prov_symbolic …)` PNVI arm, `(Prov_some …)` | PASS — texts identical; null arm NOT conditional on `is_dyn` (Z-12); Lean's `Prov_symbolic` arm kills loudly (the model never mints it; PNVI refused Z-24) — a declared refusal, not an absorption |
| `Prov_some` arm order: `isDynamic && !dynamicAddrs.contains addr` → dead → `allocations.get?` → `addr == alloc.base` | `:1515-1549`: `if is_dyn then is_dynamic addr` (the POINTER's `addr`) → `is_dead alloc_id` → `get_allocation` → `Z.equal addr alloc.base` | PASS — order and the `addr`-not-`base` test (Z-08); `get_allocation` failure → `MerrOutsideLifetime "Concrete.get_allocation, alloc_id=…"` = `:669-675` (Z-11) |
| dead + static → `panic! "Concrete: FREE was called on a dead allocation"`; dead + dynamic → `Free_dead_allocation` | `:1529-1532` | PASS (Q4 fail-stop with the OCaml text; witness §4.1) |
| `SW_zap_dead_pointers` set → loud kill; default → `return ()` | `:1543-1546` | PASS (refused switch, loud) — the state update omits `last_used` (N2, pre-existing) |
| `deviceRanges` `[(0x40000000,0x40000004),(0xABC,0xAC0)]` | `:620-624` | PASS |
| `isWithinDevice`: `lo ≤ addr && addr + sizeof ty ≤ hi` | `:681-686` `Z.leq min addr && Z.leq (addr + sizeof ty) max` | PASS |
| `ptrfromint`: `wrapI` → `is_PNVI` (loud kill) → `Prov_none`: device (`lo ≤ n && n ≤ hi`, inclusive) → `n == 0` null → concrete; other prov → concrete keeping prov | `:2126-2173` (`Z.leq min n && Z.leq n max` inclusive at `:2165`) | PASS incl. Z-09 (a provenance-carrying 0 stays concrete) |
| `loadM` `Prov_device` → `isWithinDevice ? doLoad addr : OutOfBoundPtr`; arm order null/function/`Prov_none`/device/symbolic | `:1604-1617` `do_load None addr` | PASS (`do_load None` differs only in `last_used`, N2) |
| `storeM` `Prov_device` → `doStore none unionMem addr`; `doStore` skips the `is_locking` readonly update when `allocOpt = none`; the `last_used_union_members` update stays inside `doStore` | `:1711-1724` `do_store None addr`; `:1683-1701` (union-member update inside `do_store`, readonly-kind update only in the `Prov_some` arm `:1776-1787`) | PASS |
| `casePtrval` `[Inhabited α]`; fallback → `panic! "case_ptrval"` | `:1808-1814` `\| _ -> failwith "case_ptrval"` | PASS (witness §4.1: oracles exit 125, Lean 134, same text) |
| `intfromptr` range failure `memFail MerrIntFromPtr loc` | `:2459` `fail ~loc MerrIntFromPtr` | PASS (witness UB024 `<7:11--7:17>`) |
| `copyAllocId iv pv := intfromptr (other "copy_alloc_id") void (Unsigned Intptr_t) pv >>= fun _ => ptrfromint (other "copy_alloc_id") (Unsigned Intptr_t) void iv` | `:2766-2770` | PASS (witness `Specified(2)`) |
| `CerbLocation.simpleLocation`: unknown → `<unknown location>`; other → `<other location: s>`; point → `L:C`; region → `<L:C--L:C>`; regions hd → same; `regions []` → `panic! "hd"` | `util/cerb_location.ml:476-491` (`List.hd` raises `Failure "hd"` on `[]`) | PASS — every batch `loc:` in §4.1 byte-identical |
| `CerbLocation.isLibraryLocation`: `dirname path ∈ {…}` as `dir == d \|\| dir.endsWith ("/" ++ d)` over `runtime/libc/include`, `runtime/libcore`, `runtime/libcore/impls`; `dirname` = Unix `Filename.dirname` (trailing-slash strip, `.`/`/` cases checked) | `:512-520` `Hashtbl.mem excluded (Filename.dirname path)` over `Cerb_runtime.in_runtime "libc/include"/"libcore"/"libcore/impls"` | PASS with the documented residual; exact in practice (N3). `getFilename` handles `regions []` → none like `:493-501` |
| `CoreParser.stampLibraryFile`: every `Aloc unknown` in Pattern/Pexpr/Expr annots, `PEundef` loc, `Action` loc, `Proc`/`ProcDecl`/`BuiltinDecl` loc, tag-def loc, impl `Def`/`IFun` bodies, globs → `Loc.region ⟨file,0,0⟩ ⟨file,0,0⟩ .noCursor`; `relocPE`/`relocE`/`relocAct` are exhaustive matches | `core_parser.mly` stamps `region ($startpos,$endpos)` on: patterns (`:1486-1505`), every pexpr production (`:1554-1629`, `PEundef` at `:1571`), every expr production (`:1642-1700`), actions (`:1744/1746`), `Proc` `decl_loc` (`:1040`), `Symbol.Identifier` (`:1443`), aggregate decls (`:1048`) | PASS for every kind that reaches an `is_library_location` consumer (`core_eval.lem:602` PEundef; `core_run.lem:476` Action; `core_run.lem:781` Expr annots). NOT stamped: `Symbol.Identifier` locs (documented; never consulted on an execution path — they feed error messages only). No node kind the OCaml locates and a consumer reads is missed. Pos payload `(0,0)` is the documented divergence the orchestrator accepted (record §10; Z2 row) |
| `IvMaxAlignment` → `CerbMem.integerIval (CerberusImpl.max_alignment : Int)` (`CerberusImpl.lean:20` = 8) | `core_parser.mly:1536-1537` `integer_ival (Z.of_int (Ocaml_implementation.(get ()).max_alignment))` = 8 | PASS (witness `da_offset` 8, `da_align16` 2) |
| `Main.batchEscape`: `"`/`\` → `\c`; `\n` `\t` `\r` `\b`; 32..126 verbatim; else `\ddd` decimal | `lib/ocaml/bytes.ml:170-212` `unsafe_escape` (= `String.escaped`, `string.ml:109`); the batch printer applies `String.escaped` to stdout/stderr on Defined (`driver_ocaml.ml:98-100`) and to stderr on Undefined (`:122-124`) | PASS — all 256 byte values probed (§2.v): oracle and Lean `Defined` lines `cmp` IDENTICAL, 1540 bytes each |
| Killed-state stderr: `Undef0 loc (ub::_)` → `stderr: "<escaped killed stderr>"`; `Undef0 _ []` → `Error {msg: "[empty UB, probably a cerberus BUG]"}`; `Error0 _ msg` → `Error {msg}`; `Other` → `Error {msg}`; typing/desugar UB lines `stderr: ""` + `simpleLocation` | `driver_ocaml.ml:173-181` (every Killed arm carries `String.concat "" (Dlist.toList …io.stderr)`), the printer renders it only on the Undefined line (`:120-124`; Error `:138` prints msg alone); `main.ml:166-177` `Undefined { ub; stderr= ""; loc }` | PASS (witness `zd-z72` `stderr: "E1"`) |
| `CerbDecode.lean` | — | markers/wording only; the `\| "\\?" => 63` arm and `escaped_char`'s hex form are unchanged (diff is comment-only + the `-- ISO-fix register R2` marker line). No behaviour change — CONFIRMED |
| `CerbFS.lean` | `sibylfs/src/fs_spec.lem`, `frontend/model/driver.lem` | see §3.iii — one served path wrong (F1); every other served row checked against the code and the SibylFS cite |

## 3. Instrument integrity (question 2)

### (i) Whole-line extractors

`scripts/test_exec.sh`, `test_ci_sweep.sh`, `test_cn_coverage.sh`,
`test_multi_tu.sh`, `tests/parity-probes/run_probe.sh`,
`tests/noodle-probes/run_noodle.sh`, `tests/mem-scale-probes/measure.sh`:
`grep -oE '^Undefined \{.*\}$|^Defined \{value: "[^"]*"'` then `sed
's/^Undefined \(.*\)$/UB:\1/'` — `^`-anchored, greedy to the line's final
`}`. `test_verify.sh verdict_of`: `sed -n 's/^Undefined \(.*\)$/\1/p'`. The
speclab family: `grep -oE '^Defined \{value: "[^"]*"|^Undefined \{.*\}$' \|
head -1 \| sed 's/^Defined {value: "//;s/"$//'` — an Undefined line ends in
`}` so the trailing `s/"$//` leaves it whole. Embedded `"` and newline bytes
in a stderr field are `String.escaped` on both sides (`\"`, `\n`; §2.v shows
byte 10 → `\n`, byte 34 → `\"`), so an Undefined verdict is always ONE line
and the extractor keeps all of it. Classification: `test_exec.sh:648-696` —
identical token sequences → MATCH/UB_MATCH; same shape with UB tokens
differing → `UB_DIFF`; `--check-baseline` (`:819-861`) makes `UB_MATCH →
UB_DIFF` a REGRESSION (rc 1). Re-run of the loc plant (one-file dir with
`tests/noodle-probes/float/float_inf_to_int_ub.c`; `SKIP_BUILD=1`, stamps
fresh), verbatim:

```
(3a) baseline written:
[1/1] UB_MATCH float_inf_to_int_ub: UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
float_inf_to_int_ub.c UB_MATCH

(3b) --check-baseline with CERB_LEAN_BIN_OVERRIDE = a stub running the real driver and adding 1 to every Undefined line's END column:
CERB_LEAN_BIN_OVERRIDE ACTIVE: Lean driver replaced by /home/dev/projects/cerberus-lean-proj/.tmp/z1audit/plant/lean_locshift.sh
CERB_LEAN_BIN_OVERRIDE ACTIVE: Lean driver freshness check SKIPPED (plant stub, not the driver)
[1/1] UB_DIFF float_inf_to_int_ub: Lean=UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:20>"} Cerberus=UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
SUMMARY: total=1 match=0 ub_match=0 ub_diff=1 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
REGRESSION: float_inf_to_int_ub.c baseline=UB_MATCH current=UB_DIFF
Baseline check: 1 regression(s), 0 improvement(s)
FAILED: regressions vs baseline
exec lane rc=1

(3c) control — the SOURCE perturbed by one column (a space before `(int)big`), both engines see it:
  int i =  (int)big;
[1/1] UB_MATCH float_inf_to_int_ub: UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
exec lane rc=0
```

The plant goes red on a loc-only difference (3b); (3c) documents why a
source perturbation is not a plant (N5). The stub was removed with the
scratch dir; the corpus file was not modified (a copy was perturbed).

### (ii) `test_immaculate.sh`

`verdict()` (`:106-126`): `UB:` = `sed 's/^Undefined \(.*\)$/\1/p'`,
`VAL:` = the whole Defined payload, `ERR:` = the whole Error payload (the
`[^"]*` truncation of `MerrOther "…"` is gone). Token shapes in the committed
baseline, e.g. `zd-z72-stderr-ub MATCH | L=UB:{ub: "UB043_indirection_invalid_value",
stderr: "E1", loc: "<6:62--6:64>"}`, `zd-d6-free-no-provenance MATCH | L=ERR:{msg:
"MerrOther "attempted to kill with a pointer lacking a provenance""}`. Plant
(stub prefixing `X` to every Undefined line's stderr field), verbatim excerpt:

```
  DIFF           zd-z72-stderr-ub      O[UB:{ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<6:62--6:64>"}] L[UB:{ub: "UB043_indirection_invalid_value", stderr: "XE1", loc: "<6:62--6:64>"}]
  DIFF           zd-d1-float-inf-to-int-ub  O[UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<7:11--7:19>"}] L[UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "X", loc: "<7:11--7:19>"}]
DEVIATION: zd-d1-float-inf-to-int-ub expected [MATCH | L=UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<7:11--7:19>"}] got [DIFF | L=UB:{ub: "UB017_out_of_range_floating_integer_conversion", stderr: "X", loc: "<7:11--7:19>"}]
immaculate plant rc=1
```

(13 UB rows went DIFF under the stub; `g5-escape-roundtrip` stayed DIFF as
recorded.) Unplanted run, verbatim: `OK: lane matches the committed baseline
(MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals
ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH
— VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE /
illtyped-store KILL).` rc 0.

### (iii) `test_golden.sh`

The only change adds `LEAN_ABORT_ON_PANIC=1` to the direct driver invocation
(`:33`); the driver would otherwise refuse (exit 2) and the golden compare
would fail on an absent `return value:`. Correct and necessary.

### (iv) The gcc second-oracle lane

Ledger rows: the 7 `tests/immaculate/nolibc/zd-*.c` rows in
`scripts/gcc_oracle_baseline.txt` (SKIP_UB ×2, TRIAGED_UB, TRIAGED_ADDR ×2,
SKIP_GCC_STDOUT, SKIP_LEAN_CRASH) and the 3 `gcc_oracle_triage.txt` entries
carry the mandatory `gcc=`/`lean=` value pins; classification assessed in F6
(D2 ×2 correct; D3(a) defensible, tray question open). FIRST RUN (box load ≈
30 from other agents; `uptime` at the end: `load average: 7.17, 32.51,
29.97`), verbatim:

```
gcc second-oracle lane: 1960 files (gcc 13.3.0, lean timeout 30s, native timeout 5s, O2 stride 10)
[285/1960] SKIP_UB  tests/immaculate/nolibc/zd-d1-float-inf-to-int-ub.c: (UB:UB017_out_of_range_floating_integer_conversion)
[286/1960] SKIP_UB  tests/immaculate/nolibc/zd-d2-ptr-to-int-narrow-ub.c: (UB:UB024_out_of_range_pointer_to_integer_conversion)
[287/1960] TRIAGED_UB  tests/immaculate/nolibc/zd-d5-device-range-load.c: gcc=139 lean={3} (ledger-declared observer)
[288/1960] TRIAGED_ADDR  tests/immaculate/nolibc/zd-da-align16.c: gcc=3 lean={2} (ledger-declared observer)
[289/1960] TRIAGED_ADDR  tests/immaculate/nolibc/zd-da-offset.c: gcc=64 lean={8} (ledger-declared observer)
[290/1960] SKIP_GCC_STDOUT  tests/immaculate/nolibc/zd-e2-ptr-string-literals.c: (40 bytes)
[291/1960] SKIP_LEAN_CRASH  tests/immaculate/nolibc/zd-z2m02-device-funptr-call.c: (exit 134) PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
[1431/1960] SKIP_LEAN_TIMEOUT  csmith/sia_csmith_477.c
SUMMARY: total=1960 compared=1884 agree=1872 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=46 triaged_addr=11 triaged_ub=1
REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
Baseline check: 1 regression(s), 0 improvement(s)
EXIT=1
```

The one movement is `AGREE → SKIP_LEAN_TIMEOUT` (skip_lean_timeout 12 vs the
record's 11; every other class count equals the record §9.1's second run,
with agree 1872 = 1873 − the timed-out row). Hand re-timing of that row,
staged exactly as the lane stages it (`CSMITH_MINIMAL` + `csmith_cerberus.h`,
Lean `--batch --first`, `scripts/capped`), at load 2.4, verbatim:

```
Defined {value: "Specified(132)", stdout: "", stderr: "", blocked: "false"}
lean wall=17.96s maxrss=1232700KB
gcc exit=132
```

→ AGREE at 18 s against a 30 s bound: the LADDER row-7 load caveat, not a
regression (F7).

**(iv-b) SECOND RUN**, started when the box had quietened (`uptime` at start:
`load average: 5.95, 22.51, 27.78`) but the load climbed back to ≈ 22 from
other agents while it ran (`uptime` at end: `load average: 21.37, 22.94,
22.79`), verbatim:

```
SUMMARY: total=1960 compared=1884 agree=1872 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_stdout=1 skip_lean_crash=8 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=46 triaged_addr=11 triaged_ub=1
REGRESSION: csmith/sia_csmith_477.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-
Baseline check: 1 regression(s), 0 improvement(s)
EXIT=1
```

The same single row, the same single movement, both runs; every other row
unmoved (0 improvements; the 11 baseline `SKIP_LEAN_TIMEOUT` rows are the
same 11). This auditor could NOT obtain a quiet box for a full 24-minute run
(this machine hosts several agents; load 20–30 throughout); the row-level
evidence is the hand timing above (17.96 s, AGREE, at load 2.4), which is
what LADDER row 7 asks for before the movement is read as red. Disposition
[AGENT]: the gcc lane is GREEN modulo one load-sensitive row; the operator
may want one quiet-box full run at merge time, and Z4's Z-31 measurement
should add `sia_csmith_477.c` (18 s / 30 s) to the rows whose margin is
recorded.

### (v) Baseline rows verified by lanes, not by reading

`./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage`, verbatim:

```
[63/202] UB_MATCH dynaddr-001-free-automatic-control: UB:{ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<6:3--6:11>"}
[64/202] UB_MATCH dynaddr-002-malloc0-then-free-automatic: UB:{ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<9:3--9:11>"}
[65/202] MATCH dynaddr-003-malloc0-nonnull: VAL:Specified(1)
SUMMARY: total=202 match=175 ub_match=14 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

`./scripts/test_verify.sh`, verbatim: `test_verify: 117 passed, 0 failed (23
fixtures, 22 call points, 14 corpus fixtures, 21 corpus points)` (the two
reshaped `t2_add` pins `{ub: "UB036_exceptional_condition", stderr: "", loc:
"<5:32--5:37>"}` are among the 117).

The 256-byte escape probe (`write(1, b, 256); write(2, b, 256);`, libc mode),
derived + verbatim head (`cat -v`):

```
Defined {value: "Specified(0)", stdout: "\000\001\002\003\004\005\006\007\b\t\n\011\012\r\014\015\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031 !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\127\128\129\130\131\132\133\134\135\136\1…
byte-compare (cmp oracle lean): IDENTICAL; both lines 1540 bytes
```

(derived: 2 × 733 escaped bytes + the 74-byte frame = 1540, i.e. 28 control
bytes × 4 + 4 short forms × 2 + 93 printables + `"`,`\` × 2 + 129 high bytes
× 4 per stream — the `unsafe_escape` arithmetic exactly.)

## 4. Refusal completeness (question 3)

### (i) `Main.refuseFlag` and the positional contract

Accepted set (from `Main.lean:1078-1124`): `--batch | --pp-core |
--parse-core` at argv[0]; `--first` immediately after `--batch`/`--pp-core`;
in the scan: `--libc <v>`, `--libc-tu <v>`, `--call <v>`, `--call-args <v>`,
`--args <v>`, `--trace-nodes`, and `--stdin` as the one `--` positional
(`readInputs` `:301` refuses `--stdin` mixed with files). Every other `--`
token in the scan → `refuseFlag` (exit 2, attributed). Probes (Lean only,
nolibc json of `int main(void){return 7;}`), verbatim (rc and first line,
truncated at 160 chars):

```
--batch fnb.json                       rc=0 :: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
--batch --first fnb.json               rc=0 :: Defined {value: "Specified(7)", …}
--batch fnb.json --first               rc=2 :: cerberus-lean: refused — --first: known flag out of its canonical position (`--batch`, `--pp-core` or `--parse-core` must be argv[0]; `--first` must immediate
--first --batch fnb.json               rc=2 :: cerberus-lean: refused — --batch: known flag out of its canonical position (…)
--batch fnb.json --switches=PNVI       rc=2 :: cerberus-lean: refused — --switches=PNVI: semantics switches (PVI/PNVI/strict_pointer_arith/CHERI/…) are not supported by this port — matched (default-swi
--batch --switches=PNVI fnb.json       rc=2 :: (same)
--batch fnb.json --concurrency         rc=2 :: cerberus-lean: refused — --concurrency: concurrency is not supported by this port (the oracle's own --concurrency mode is non-functional at b9aeedcb4: `intern
--batch --frobnicate fnb.json          rc=2 :: cerberus-lean: refused — --frobnicate: unknown flag; this port accepts only --batch | --pp-core | --parse-core (argv[0]), --first, --stdin, --libc <core> --li
--pp-core fnb.json --batch             rc=2 :: cerberus-lean: refused — --batch: known flag out of its canonical position (…)
fnb.json --batch                       rc=2 :: cerberus-lean: refused — --batch: known flag out of its canonical position (…)
--stdin --batch                        rc=2 :: cerberus-lean: refused — --batch: known flag out of its canonical position (…)
--batch --stdin fnb.json               rc=1 :: uncaught exception: --stdin cannot be combined with file arguments
--batch --stdin < fnb.json             rc=0 :: Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
--batch --trace-nodes fnb.json         rc=0 :: Defined {value: "Specified(7)", …}
--batch --args "a b" fnb.json          rc=0 :: Defined {value: "Specified(7)", …}
--batch --call-args 1 fnb.json         rc=1 (--call-args without --call)
--first fnb.json                       rc=0 ::   return value: 7            ← F3
--parse-core runtime/libcore/std.core --frobnicate   rc=1 :: … Core file: 22 fun, 52 proc, … uncaught exception: no such file or directory (error code: 4294967294)   ← F2
--parse-core --batch runtime/libcore/std.core        rc=1 :: uncaught exception: no such file or directory (error code: 4294967294)   ← F2
--batch --libc --frobnicate fnb.json   rc=1 (value-consuming flag; N4)
--batch -h fnb.json                    rc=1 :: uncaught exception: no such file or directory (error code: 4294967294)   (N4)
```

Refusal precedes work: `--batch /nonexistent.json --switches=PNVI` → rc 2
refused (the missing file is never opened); `env -u LEAN_ABORT_ON_PANIC
--batch /nonexistent.json` → rc 2 refused on the env check first.

### (ii) `LEAN_ABORT_ON_PANIC`

The check is the first statement of `main` (`Main.lean:1063-1068`), before
any argument is read. Presence semantics verified on a panicking input
(`zd-z2m02-device-funptr-call.c`, nolibc), verbatim:

```
LEAN_ABORT_ON_PANIC='1' rc=134 :: PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
LEAN_ABORT_ON_PANIC='0' rc=134 :: PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
LEAN_ABORT_ON_PANIC=''  rc=134 :: PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
env -u LEAN_ABORT_ON_PANIC --batch fnb.json   rc=2 :: cerberus-lean: refused — LEAN_ABORT_ON_PANIC is not set: …
```

Harness grep (every `.sh` under `scripts/`, `tests/`, `tools/` that names the
driver): all set the variable directly or via `common.sh run_cerberus_lean`
(`test_core.sh` uses `run_cerberus_lean`); the four with zero occurrences —
`scripts/check_fork_drift.sh`, `scripts/fuzz_csmith.sh`,
`tests/mem-scale-probes/run_all.sh`, `tools/check_driver_fresh.sh` — only
name or hash the binary (checked). The record's claim holds.

### (iii) `CerbFS` — the 25 `fs_*` entry points vs the table vs the code

Code read op by op against the header table (`CerbFS.lean:79-128`) and the
SibylFS cites: every REFUSED row is a `panic!` with the `CerbFS refusal
(fail-closed fs-model boundary): <op> — <why>; … (CerbFS.lean header; mover:
…)` prefix (`fs_open` ×3 conditions, `fs_close`/`fs_lseek` on fds 0–2,
`fs_read`/`fs_pread`/`fs_write`/`fs_pwrite` off-pattern offsets, `fs_lseek`
past EOF / bad whence, `fs_truncate` open-fd / larger, `fs_unlink`/`fs_rename`
open-fd, `fs_mkdir`/`fs_rmdir`/`fs_chdir`/`fs_chmod`/`fs_chown`,
`fs_link`/`fs_readlink`/`fs_symlink`, `fs_stat`/`fs_lstat`,
`fs_opendir`/`fs_readdir`/`fs_rewinddir`/`fs_closedir`) — no op still
returns a default where the table says REFUSED. SERVED rows checked against
the SibylFS text: `fs_open` flag bits = `fcntl.h:27-45` = `fs_spec.lem`'s;
EBADF on unknown fds (`fs_spec.lem:4946-4947` read, `:5006-5007` write);
`fs_lseek` negative → EINVAL; `fs_unlink` missing → ENOENT; `fs_rename`
missing → ENOENT. **Record finding 5 CONFIRMED**: `default_pps_fd_table`
(`fs_spec.lem:5690-5696`) maps FD 0/1/2 to `FID 0`, whose
`dummy_fid_state` (`:5806-5812`) has `fids_oflags = finset_empty ()`; `os_read`
(`:4949-4956`) computes `can_read = O_RDONLY ∈ oflags || O_RDWR ∈ oflags ||
(freebsd && O_EXEC ∈ oflags)` → false → `EBADF`; `os_write` (`:5006-5012`)
likewise for `O_WRONLY/O_RDWR` → `EBADF`. Lean's `lookupFd` has no entry for
0–2, so the same `EBADF` falls out — read/pread/pwrite on fds 0–2 correctly
stay SERVED, and `tests/suite/fs/cat.c` stays MATCH. `fs_write` on fds 0–2
never reaches `Fs` (`driver.lem:352-359`: 0 → `error`, 1/2 → the
stdout/stderr records) — CONFIRMED. The ONE served row the code does not
honour is F1 (`fs_truncate` with `len < 0`; SibylFS `:4020` EINVAL); the
directory-PATH residual is N-grade (F1 text). Witnesses (§4.1): `stat.c` and
`freebsd/cat.c` refuse loudly with the attributed text; `zd-*` libc rows
MATCH.

## 5. Record integrity (question 4)

### 5.1 Verbatim spot-checks (12 rows re-run; fork oracle, upstream `b9aeedcb4`, Lean; `rc` = exit)

```
== nolibc tests/noodle-probes/seam/seam_device_range_load.c
fork    rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
== nolibc tests/noodle-probes/float/float_inf_to_int_ub.c
fork    rc=1: Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
upstrm  rc=1: Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
lean    rc=1: Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}
== nolibc tests/noodle-probes/ptr/ptr_to_int_narrow_ub.c
fork    rc=1: Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}
upstrm  rc=1: Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}
lean    rc=1: Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}
== nolibc tests/noodle-probes/dynamic-addrs/da_offset.c
fork    rc=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}
== nolibc tests/noodle-probes/dynamic-addrs/da_align16.c
fork    rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
== nolibc tests/immaculate/nolibc/zd-z2m02-device-funptr-call.c
fork    rc=125: cerberus: internal error, uncaught exception:           Failure("case_ptrval")
upstrm  rc=125: cerberus: internal error, uncaught exception:           Failure("case_ptrval")
lean    rc=134: PANIC at CerbMem.casePtrval CerbMem:1249:4: case_ptrval
== libc tests/noodle-probes/seam/seam_copy_alloc_id.c
fork    rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
== libc tests/noodle-probes/seam/seam_free_no_provenance.c
fork    rc=1: Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}
upstrm  rc=1: Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}
lean    rc=1: Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}
== libc tests/noodle-probes/seam/seam_free_interior_pointer.c
fork    rc=1: Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<7:39--7:50>"}
upstrm  rc=1: Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<7:39--7:50>"}
lean    rc=1: Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<7:39--7:50>"}
== libc tests/noodle-probes/seam/seam_free_device_pointer.c
fork    rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
== libc tests/immaculate/libc/zd-z72-stderr-ub.c
fork    rc=1: Undefined {ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<6:62--6:64>"}
upstrm  rc=1: Undefined {ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<6:62--6:64>"}
lean    rc=1: Undefined {ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<6:62--6:64>"}
== libc tests/suite/fs/stat.c
fork    rc=0: Defined {value: "Specified(0)", stdout: "2049 1 33261 1 0 0 0 10\n", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(0)", stdout: "2049 1 33261 1 0 0 0 10\n", stderr: "", blocked: "false"}
lean    rc=134: PANIC at CerbFS.fs_stat CerbFS:437:2: CerbFS refusal (fail-closed fs-model boundary): stat 'testfile.txt' — SibylFS answers the real st_dev/st_ino/st_mode/st_nlink/uid/gid/rdev/size fields (tests/suite/fs/stat.c: 2049 1 33261 1 0 0 0 10); this model answered zeroed fields except size (0 0 420 1 0 0 0 10); answering would differ from the oracle's SibylFS (CerbFS.lean header; mover: real stat fields)
== libc tests/freebsd/cat.c
fork    rc=0: Defined {value: "Specified(1)", stdout: "stdin", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(1)", stdout: "stdin", stderr: "", blocked: "false"}
lean    rc=134: PANIC at CerbFS.fs_close CerbFS:234:4: CerbFS refusal (fail-closed fs-model boundary): close of fd 1 — fds 0,1,2 are open in SibylFS's initial state; this model has no entry for them and answered EBADF; answering would differ from the oracle's SibylFS (CerbFS.lean header; mover: SibylFS's std fds (fs_spec.lem:5690-5696: fds 0,1,2 are open on a root-directory dummy fid))
== libc tests/immaculate/libc/zd-z2p01-stdout_escape.c
fork    rc=0: Defined {value: "Specified(0)", stdout: "a\bb\007\127\195\169\011\012\027|\n", stderr: "", blocked: "false"}
upstrm  rc=0: Defined {value: "Specified(0)", stdout: "a\bb\007\127\195\169\011\012\027|\n", stderr: "", blocked: "false"}
lean    rc=0: Defined {value: "Specified(0)", stdout: "a\bb\007\127\195\169\011\012\027|\n", stderr: "", blocked: "false"}
```

(The oracle's `uncaught exception` lines carry ANSI colour codes on the
terminal; stripped here, nothing else changed.) Z-10 witnesses via
`tests/noodle-probes/dynamic-addrs/run_dynaddr.sh`, verbatim:

```
--- FORK ORACLE exit=125
          Failure("Concrete: FREE was called on a dead allocation")
--- UPSTREAM ORACLE exit=125
          Failure("Concrete: FREE was called on a dead allocation")
--- LEAN --batch exit=134        (inj_bug.c + --inject inject_rand.core)
PANIC at CerbMem.killM CerbMem:1953:10: Concrete: FREE was called on a dead allocation
```

Every "after" line the record quotes in §1/§2 for these rows reproduces
exactly (the `CerbMem:1944:10` → `1953:10` line-number drift is the
pre-rebase build, F5 note).

### 5.2 Census rows, cites, manifest

Every census row whose class changed in the charter (§2.1 Z-01/02/03/05/06/
07/08/10/72/76, §2.2 Z-09/11/12, §2.3 Z-24/25/27, Z-73/74, §2.4 Z-36, §2.7
Z-67/68/69) cites its Z1 commit id (`768be3698`, `c61b78f70`, `1c1311a57`,
`8da338f42`, `b42776130`, `deb2338a8`) or, for the no-code rows, the record
section — CONFIRMED by reading each row. Manifest cites: F5. `2>/dev/null` /
fail-open defaults in changed scripts: N6 (none introduced).

## 6. What this audit did NOT check

- The full Tier A/B battery was not re-run; this audit ran the lanes its
  questions needed (coverage exec, verify, immaculate, gcc) and relied on the
  record §9 + §10 for the rest (the orchestrator's 19-lane re-run is the
  independent evidence there).
- `test_libxml2.sh`, `test_ci_sweep.sh` (the spot sweep), `test_cn_coverage.sh`,
  the speclab gates, the plant batteries — not re-run here.
- The 145 noodle probe files and tray draft 19 were not re-read for content
  (cherry-pick scope only, per the record's own statement).
- The generated OCaml `sibylfs/generated/sibylfs.ml` wrapper was not read;
  SibylFS behaviour was taken from `fs_spec.lem` at the cited transitions.
- CerbFS directory-PATH behaviours (F1's EISDIR family) were reasoned from
  the code, not probed.
- lem-lean / the generated Lean tree: unchanged in this slice (lem pin
  `3c88f0d`), not audited.
- The oracle-side location oddity noticed in (3c) (a space before the cast
  did not move `<5:11--5:19>`) is shared-front-end behaviour, not
  Lean-vs-oracle; not investigated.

## 7. Provenance

[AGENT] (this auditor): every grading, tally and probe here. Quoted engine and
lane lines are verbatim from runs in the Z1 worktree on the stamped binaries
(`5b62df0d…`/`4ebda58b…`); derived counts are labelled. Nothing in the Z1
worktree, `deps/`, the primary checkouts or any global state was modified;
nothing merged or pushed. Scratch: `.tmp/z1audit/` (container-ephemeral;
deleted at slice end).
