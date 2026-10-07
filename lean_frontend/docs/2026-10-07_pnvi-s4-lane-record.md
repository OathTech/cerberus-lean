# PNVI arc S4: the differential lane, the CLI acceptance, plants and docs — slice record (2026-10-07)

Branch `arc/pnvi-ae-udi`. Base: `65db09a04` (S3 + the design's §H.1 addendum). Worker: Claude Opus 5.5
(agent). Every judgement no operator quote covers is marked [AGENT]. Quoted gate and tool output is verbatim;
counts marked "derived" are mine. The lem used is the shared `2d3a492` (the pin); no `.lem` file changed.

Commits (in order):

| Commit | What |
|---|---|
| `14057bf1a` | Part 1: the carried-over fixes (S3 review F1 and weak witness, S1 L5 CLI items) |
| `c6ea6a585` | S4: Main accepts `--switches=PNVI_ae_udi`; `scripts/test_pnvi.sh` + `scripts/pnvi_lane.py` + baseline + witnesses; `check_cli_refusals.sh`; the failure-reach register re-review |
| `ddd5d0abb` | S4 docs: CONTRACT / VALIDATION / SUPPORTED / README / `lean_frontend/CLAUDE.md`; upstream tray drafts 50–53 |
| `e60432f28` | S4: the R-PNVI-12 refusal text corrected (text only) |
| `372b6fce6` | S4: the `--selftest` selection uses `pkvm-alloc`, not `pkvm-init` (§5.3) — the gated tree |
| (this record) | this record only |

S4 is the first slice where `PNVI_ae_udi` is user-visible. It is a spec addition (design §E row S4): no
semantic arm changed (S3 wrote them), only the CLI and the evidence.

## 0. Rulings in force (verbatim) and governing documents

- [USER 2026-10-03]: "… we should fall back to loudly rejecting (either as unsupported, or matching upstream)".
- [USER 2026-09-30]: "… we should not fix deviations with special 'magic mode' paths that work exclusively in
  one situation. …" (trimmed at both ends, marked `…`; the committed records — design record §1.1, CONTRACT
  §5 D8 — carry this span).
- [USER 2026-10-05]: "Re PNVI - agree on your recs except for mirroring crashes / obviously wrong behavior.
  These should be refusals surely?"
- [USER 2026-10-07]: "This sounds like a classic case of 'gate cruft' - we don't want our gates to be adversarially robust unless they are trust surfaces".
- Design record `docs/2026-10-04_pnvi-ae-udi-design.md` §C, §D, §E S4, §F.4/§F.5/§F.6/§F.8/§F.12/§F.13, §G,
  §H, §H.1. S3 record `docs/2026-10-07_pnvi-s3-arms-record.md`. S1 record §14 (gate classes).

Applied: the switch set stays ONE parameter read by every site; `--switches=PNVI_ae_udi` only selects the
value of the instance `Main` builds — no PNVI-only entry point (the 2026-09-30 ruling). Every upstream crash
or self-declared-wrong arm reached under the switch is a refusal (the 2026-10-05 ruling), recorded in the lane
as its own registered class. Gate classes (2026-10-07 ruling): the lane is a TRUST SURFACE;
`check_cli_refusals.sh` is a SPEEDBUMP (§1.2, §2.6).

## 1. Part 1: the carried-over fixes (`14057bf1a`)

### 1.1 S3 review F1 — R-PNVI-08 and R-PNVI-10 were failures at the pair type

Both refusals sat as `failwithI (pnviRefusal …)` at the type `nd_action … × MemState` inside an
`ND fun st => …` body. The `Inhabited` instance at that type is `(NDactive default, default)`: the kernel default
of the failure leaf is an ACTIVE result, and the failure census (`scripts/failure_census.py`) excluded the two
sites as `monadic_ascribed` because their enclosing declarations have type `memM _` — a false premise for these
two sites.

Fix (the ascription, preferred over register rows) [AGENT: it is clean and makes the census's rule true]:
`CerbMem.pnviRefuseM (detail) : memM a := failwithI (pnviRefusal detail)`, used at both sites as
`match (pnviRefuseM "R-PNVI-08: …" : memM IntegerValue) with | ND f => f st` (R-PNVI-10 at `memM PointerValue`).
The leaf now sits at `memM`, whose `Inhabited` default is a kill. MEASURED with a scratch probe (deleted):

```
fun st => NDkilled (Undef0 CerbLocation.Loc.unknown [])
NDactive Nat.zero
```

(first line: `(step (default : CerbMem.memM Nat) st).1`; second: the default at the pair's action type with an
inhabited value, the old shape). At run time nothing changes: the leaf aborts before any default is used
(`LEAN_ABORT_ON_PANIC`). Default mode is bit-identical: both arms are unreachable at the default set (they need
a `Prov_symbolic` pointer). The census now counts one hand-written `monadic_ascribed` site (`pnviRefuseM`
itself; row 1's census line `"handwritten:monadic_ascribed":1`).

`pnvi-arms-test`'s refusal pin was widened to accept an `ND` elimination (a matcher or `casesOn`) STUCK on the
leaf, besides the leaf itself. Scratch plant check (a copy of the test, deleted), verbatim first 200 characters:

```
.tmp/PlantPins.lean:316:0: error: PnviArmsTest: R-PNVI-08 — the term does not reduce to `failwithI (pnviRefusal …)` (a mirror or a bare crash?)
.tmp/PlantPins.lean:317:0: error: PnviArmsTest: expected refusal R-PNVI-08, got detail R-PNVI-10: eff_array_shift_ptrval, Prov_symbolic, Double, non-zero shift admitted by both allocations (
.tmp/PlantPins.lean:319:0: error: PnviArmsTest: a negative control reduced to a PNVI refusal: R-PNVI-08: diff_ptrval, (Prov_symbolic, Prov_symbolic), ambiguous intersection with addr1 <> addr2 — imp
```

(a non-refusal `diff_ptrval` term pinned as R-PNVI-08; the R-PNVI-10 term pinned as -08; the R-PNVI-08 term used
as a negative control).

### 1.2 The weak "second failure" witness

The S3 witness loaded through `Double 0 1` at 116, where both candidates fail with `OutOfBoundPtr`: it could not
tell the first failure from the second. Replaced by two witnesses whose candidates fail with DIFFERENT kinds
(`impl_mem.ml:1669` `DeadPtr`, `:1673` `OutOfBoundPtr`): with 0 dead and 1 out of bounds the reported error is
`OutOfBoundPtr`; with 0 out of bounds and 1 dead it is `DeadPtr`. Both pass (`PnviArmsTest: 37/37 runtime
witnesses passed`).

### 1.3 S1 L5 CLI items

1. `--switches` under `--parse-core`, and `--switches=V` before a misplaced `--batch`: the value is now judged by
   the switch parser first (its own per-element refusal; since §2.1, for the accepted value under `--parse-core`
   a specific refusal, and before a misplaced `--batch` the position refusal). Before: `unknown flag; …` and the
   position text respectively.
2. A repeated UNKNOWN name was labelled "override". Now only a name in `read_switch`'s domain
   (`Main.knownSwitch`, `switches.ml:61-102`) enters the override list, as the oracle's `set` does
   (`switches.ml:134-141`): `bogus,bogus` gives "unknown switch name" twice.
3. Cites: `CerbGlobal.lean` (two places) and `Main.lean` now cite `main.ml:134-137` for the CHERI injection.

`check_cli_refusals.sh` pins the four placement verdicts (speedbump). Part 1 was gated with row 1 (§8.1).

## 2. CLI changes (`c6ea6a585`, `e60432f28`)

### 2.1 Main

- `Main.judgeSwitches flag value`: `value == "PNVI_ae_udi"` → `[.PNVI .AE_UDI]`; anything else →
  `refuseSwitches` (exit 2). Both cmdliner forms reach it; a one-element list is the only accepted list.
- `main` builds `switchSet` (`CerbGlobal.defaultSwitches` without the option) and supplies
  `letI : CerbGlobal.Switches := ⟨switchSet⟩` beside the fuel instance. Without `--switches` the value is the
  same `defaultSwitches` as before — the default path is unchanged by construction.
- Every other value stays refused, each element with its own reason: another switch name; plain `PNVI` /
  `PNVI_ae` (unvalidated, design §F.3); `PNVI_ae_udi` inside a longer list ("supported only as the WHOLE switch
  set"); an override (R-PNVI-11); an unknown name (R-PNVI-12); an empty element. A repeated option is refused
  ("cannot be repeated"). `--iso` stays refused by `refuseFlag` (§F.12). Under `--parse-core` the accepted
  switch is refused ("the Core text parser … reads no switch set"). `refuseFlag`'s unknown-flag text lists
  `--switches PNVI_ae_udi`.
- The W1 allowlist line of `scripts/check_no_fuel_numerals.sh` follows the changed `letI` line.

### 2.2 CLI witness lines (verbatim, this tree's binary; each line cut at 400 characters by the probe)

```
$ cerberus-lean --batch --runtime=_build/install/default --switches=PNVI_ae_udi /nonexistent/p.json
uncaught exception: no such file or directory (error code: 4294967294)
  file: /nonexistent/p.json
rc=1
$ cerberus-lean --batch --switches=PNVI x
cerberus-lean: refused — --switches=PNVI: this semantics switch set is not supported (the one supported set is `--switches=PNVI_ae_udi`) — `PNVI`: the PNVI-plain / PNVI-ae provenance variants (switches.ml:78-81) are not validated by any lane (their shared impl_mem.ml arms are mirrored, design §F.3, but only PNVI_ae_udi has a differential lane) (see CONTRACT.md §2/§3 and VALIDATION.md, seman
rc=2
$ cerberus-lean --batch --switches=strict_reads x
cerberus-lean: refused — --switches=strict_reads: this semantics switch set is not supported (the one supported set is `--switches=PNVI_ae_udi`) — `strict_reads`: strict reads (switches.ml:66-67) are not supported: CerbMem's arm is a loud kill, and the oracle's rm_unspecs Core pass (backend/common/pipeline.ml:579) has no Lean counterpart (see CONTRACT.md §2/§3 and VALIDATION.md, semantics sw
rc=2
$ cerberus-lean --batch --iso x
cerberus-lean: refused — --iso: the ISO switch set (switches.ml:144-151 `set_iso_switches`: strict_pointer_arith, strict_reads, zap_dead_pointers, strict_pointer_equality, strict_pointer_relationals, PNVI_ae_udi) is not supported — each of its switches is refused under --switches, and the oracle's rm_unspecs Core pass it enables (backend/common/pipeline.ml:579) has no Lean counterpart (see VAL
rc=2
$ cerberus-lean --batch --switches=PNVI_ae_udi --switches PNVI_ae_udi x
cerberus-lean: option --switches cannot be repeated (as the oracle's command line)
rc=2
$ cerberus-lean --parse-core --switches=PNVI_ae_udi x
cerberus-lean: refused — --switches=PNVI_ae_udi: --parse-core runs only the Core text parser, which reads no switch set; the switch would be silently ignored (see CONTRACT.md §2)
rc=2
$ cerberus-lean --switches=PNVI_ae_udi --batch x
cerberus-lean: refused — --batch: known flag out of its canonical position (`--batch`, `--pp-core` or `--parse-core` must be argv[0]; `--first` must immediately follow `--batch`/`--pp-core`) (see VALIDATION.md, zero-discrepancy Z-24)
rc=2
```

The first command is the acceptance: the driver gets past the CLI and fails at the input read. The override
and unknown-name refusals (`PNVI_ae_udi,PNVI_ae_udi` → "R-PNVI-11", `PNVI_ae_udi,bogus` → "R-PNVI-12") print one
line per element; `check_cli_refusals.sh` asserts both ids. The R-PNVI-12 text was corrected in `e60432f28`: the
oracle runs on WITHOUT the unknown name — the default semantics only when that name is alone.

### 2.3 `scripts/check_cli_refusals.sh` (SPEEDBUMP)

`PNVI_ae_udi` moved from refused to accepted: the `=` and space forms must reach the input read; and an
AGREEMENT WITNESS — one program (a pointer rebuilt bit by bit from an exposed address) run on both engines with
and without the switch: Lean(switch) must equal the oracle(switch), Lean(default) the oracle(default), and the two
answers must differ (so the witness cannot pass with the switch ignored). New refusal pins:
`PNVI_ae_udi,strict_reads` (both elements' reasons), `PNVI_ae_udi,PNVI_ae_udi` (R-PNVI-11), `PNVI_ae_udi,bogus`
(R-PNVI-12), `PNVI_ae_udi,` (an empty element); the placement verdicts of §1.3 plus `--parse-core
--switches=PNVI_ae_udi` and the accepted switch before a misplaced `--batch`. Class [AGENT]: a speedbump — it
pins texts and the acceptance against accidents; the trust property behind the acceptance (agreement under the
switch) is the lane's. Scratch plants (not committed): a stub that strips `--switches` and a refuse-everything
stub each turn it RED (rc 1); for the strip stub the agreement witness reads, verbatim (cut):

```
check_cli_refusals: FAIL — PNVI_ae_udi agreement witness: oracle(sw)=Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} lean(sw)=Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<7:10--7:19>"} oracle(default)=Undefined {ub: "UB043_indirection_invalid_value
```

## 3. The lane: `scripts/test_pnvi.sh` (TRUST SURFACE)

### 3.1 Design

Both engines run with `--switches=PNVI_ae_udi`; the oracle's cabs-json export takes no switch (no PNVI site in
the lexer/parser, design §A.7). Observations are decoded by the shared codec (`scripts/observations.py`, `full`
projection: value, stdout, stderr, UB kind AND location). `scripts/pnvi_lane.py` classifies each side, then the
row, and checks the committed baseline `tests/pnvi_lane/baseline.txt` both directions.

Sections:

| Section | Rows | Mode | Notes |
|---|---|---|---|
| `litmus/` | 44 (`tests/pnvi_testsuite/*.c`, upstream's) | libc mode, EXHAUSTIVE both sides | the oracle's `libc.co` vs Lean's pinned dump + 12 metadata TUs: both default-elaborated (design §B.0) |
| `witness/` | 3 (`tests/pnvi_refusals/*.c`, new) | libc mode, exhaustive | a C program reaching each refusal the litmus suite misses: R-PNVI-05, -06, -07 |
| `pkvm/` | 4 census drivers | `--nolibc`, census flags | allocator drivers in FIRST mode (oracle default `--mode=random` vs Lean `--first`), outside CONTRACT §1; `pkvm-init` exhaustive |
| `minimal/` | 113 (`tests/minimal/*.c`) | `--nolibc`, exhaustive | ordinary programs under the switch |

Every row ALSO runs the oracle without the switch; the baseline records whether the switch changed the oracle's
answer (`default=same|changed`).

Side classes: `OBS` (complete batch observation), `REFUSAL <id>` (Lean: exit 134, LemLib's leaf, the
`PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-nn:` message), `CRASH <msg>` (an internal failure that
is not a PNVI refusal; the oracle's uncaught-exception envelope is decoded by the codec's `immaculate` policy,
Lean's PANIC by `litmus`), `CLI_REFUSAL`, `RESOURCE KILL|TIMEOUT|FUEL`, `INVALID`.

Row classes (the only ones):

| Class | Meaning | Counted as agreement? |
|---|---|---|
| `AGREE` | identical token SEQUENCES, exhaustive | yes |
| `AGREE-FIRST` | the same in first mode | yes, but OUTSIDE CONTRACT §1 (labelled) |
| `REFUSAL R-PNVI-nn ORACLE_CRASH` | Lean refuses with that id where the oracle crashes with THAT id's upstream failure (since the review round, §12: patterns anchored, and an oracle crash an id names REQUIRES that refusal) (a per-id table: -01 `Concrete.combine_prov: found a Prov_symbolic`, -06 `Concrete.array_shift_ptrval found a Prov_symbolic`, -07 `case_ptrval`, -02 the `assert false`, -04 `Not_found`) | NO — a registered refusal row |
| `REFUSAL R-PNVI-nn ORACLE_VERDICT` | Lean refuses where the oracle runs through the flagged arm (allowed only for the ids whose upstream arm answers: -03, -05, -08, -10) | NO — a registered refusal row |
| `RESOURCE oracle:<kind>` | the ORACLE exceeded the bound (VALIDATION §1(b) direction rule) | NO |
| `BOTH_FAIL` | (narrowed by the review round, §12) EXACTLY: one `Error` each, equal under the codec's `failure-class` projection; or a crash on both sides where the oracle's crash is not one an R-PNVI id names (class (a)); Lean side hash-pinned (`lean=`) | NO |

Anything else is `DIFF` (including a refusal paired with the wrong oracle side, a Lean resource failure where
the oracle completes — a (b)-VIOLATION — and a Lean CLI refusal) or `INVALID`; both are always RED and cannot
be written into the baseline. Fail-closed: a missing engine, an empty selection, a baseline row not run, a row
not in the baseline, a changed class, a changed oracle-side hash or a changed `default=` flag is RED. The
litmus corpus must hold exactly upstream's 44 files; the pKVM case study must be present (it is under the
container's `deps/`, or `PKVM_CASE_STUDY`), else the lane fails closed. `page_alloc_census.c` (GPL-2.0-only) is
derived by `tests/census/pkvm/derive_pool_init.py` into the run directory, never into the tree.

Bounds: per engine `scripts/capped` at 4G and `timeout` 300 s (litmus/witness/pkvm, the libc_exec lane's bound)
or 30 s (minimal, test_exec.sh's).

### 3.2 Placement and cost

Full pass 2:49 wall (MEASURED, the first recording run, box load ≈10–15). The 6561-execution litmus file
`pointer_copy_user_ctrlflow_bytewise` costs ~35 s of it (MEASURED as a one-row selection: 35.7 s, both
engines with and without the switch; the oracle alone ~7 s per run). [AGENT] Tier A (design §D.1: Tier A if a
few minutes), LADDER row 14 (`A14.1` the selftest, `A14.2` the lane). The 6561 row stays in the lane on that
measurement.

## 4. The baseline tally

`SUMMARY` line of the recording run (verbatim):

```
SUMMARY: rows=164 AGREE=152 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): litmus:same=27,changed=17 minimal:same=111,changed=2 pkvm:same=1,changed=3 witness:same=0,changed=3
```

Non-agreement rows (verbatim lane lines):

```
  REFUSAL R-PNVI-01 ORACLE_CRASH     litmus/pointer_offset_from_int_subtraction_auto_yx  [Concrete.combine_prov: found a Prov_symbolic]  default=changed
  REFUSAL R-PNVI-01 ORACLE_CRASH     litmus/pointer_offset_from_int_subtraction_global_yx  [Concrete.combine_prov: found a Prov_symbolic]  default=changed
  REFUSAL R-PNVI-01 ORACLE_CRASH     litmus/provenance_basic_using_uintptr_t_auto_yx  [Concrete.combine_prov: found a Prov_symbolic]  default=changed
  REFUSAL R-PNVI-01 ORACLE_CRASH     litmus/provenance_basic_using_uintptr_t_global_yx  [Concrete.combine_prov: found a Prov_symbolic]  default=changed
  REFUSAL R-PNVI-05 ORACLE_VERDICT   witness/r05-abst-double-alloc-union-punning  default=changed
  REFUSAL R-PNVI-06 ORACLE_CRASH     witness/r06-memcpy-symbolic-source  [Concrete.array_shift_ptrval found a Prov_symbolic]  default=changed
  REFUSAL R-PNVI-07 ORACLE_CRASH     witness/r07-call-through-symbolic-pointer  [case_ptrval]  default=changed
  AGREE-FIRST                        pkvm/pkvm-alloc  default=changed
  AGREE-FIRST                        pkvm/pkvm-free  default=changed
  AGREE-FIRST                        pkvm/pkvm-split-merge  default=changed
  BOTH_FAIL                          minimal/073-exit.libc  [both Error, text differs: ERR:{msg: "ill-formed program: `calling an unknown procedure: Symbol(66, SD_Id(\"exit\"))'"}]  default=same
  BOTH_FAIL                          minimal/074-abort.libc  [both Error, text differs: ERR:{msg: "ill-formed program: `calling an unknown procedure: Symbol(60, SD_Id(\"abort\"))'"}]  default=same
```

Derived from the baseline:

- **litmus (44):** 40 AGREE + 4 `REFUSAL R-PNVI-01 ORACLE_CRASH`. The oracle's answer changes under the switch on
  17 files and not on 27 — the design's §C.1 split re-measured (27 unchanged / 17 changed, its 4 crashes among the
  17). On the 13 changed files that do not crash Lean agrees with the oracle under the switch, including the
  6561-execution file (all Defined), `cheri_03_ii` and `pointer_from_int_disambiguation_3` (UB046 at the design's
  locations) and the two `union_punning_2` rows (kind AND location move).
- **R-PNVI-06 via libc memcpy/memcmp (S3 review F2):** not reached by any litmus file (the four R-PNVI-01 files
  crash at `combine_prov` first). Reached by the new witness `r06`, a `memcpy` FROM a symbolic pointer.
- **witness (3):** each is a registered refusal row. `r05` is the only `ORACLE_VERDICT` row: the oracle answers
  `Defined {value: "Specified(2)", …}` through `abst`'s "This is wrong" arm (`impl_mem.ml:1079-1082`, the hack
  returns the first candidate, `y`); Lean refuses (R-PNVI-05). A `r07` variant that stored the function pointer
  first stopped earlier on BOTH engines (`Failure("unknown function pointer: …")`, the default-path `abst` site),
  so the witness calls through the cast directly.
- **minimal (113):** 111 AGREE + 2 BOTH_FAIL. The switch changes the oracle's answer on 2 rows, both agree under
  it: `072-out-of-bounds.undef` (UB_CERB002a → UB046 at the same location: the live PNVI bounds arm) and
  `097-null-ptr-arith.undef` (a crash in default mode, a UB046 verdict under the switch: the effectful shift
  replaces the pure one, which crashes on NULL — upstream tray 04). The two BOTH_FAIL rows are the default
  lane's `CERB_SKIP` pair, same text in both modes. **Ordinary programs are undisturbed:** 111 of 113 give the
  oracle's default answer under the switch, and Lean agrees on all 111 + 2.
- **No disagreement outside the registered classes.** No STOP.

## 5. Plants

### 5.1 The lane's `--selftest` (run per gate, Tier A row `A14.1`)

On a 5-row selection; the control must be green, every plant RED for its stated reason. Verbatim from the
selftest run on the S4 tree before the §5.3 selection change (the gate run's selftest lines are in §8.2):

```
  CONTROL OK [control: unplanted selection] -> SUMMARY: rows=5 AGREE=3 REFUSAL=2 | switch vs default (oracle): litmus:same=0,changed=3 pkvm:same=1,changed=0 witness:same=0,changed=1
  PLANT OK   [P1 Lean ignores the switch (flag stripped)] -> RED:   litmus/pointer_from_int_disambiguation_1: class DIFF != baseline AGREE
  PLANT OK   [P6 Lean refuses everything] -> RED:   DIFF                               litmus/cheri_03_ii  [lean refused at the CLI: cerberus-lean: refused — plant: every input refused]  default=changed
  PLANT OK   [P7a refusal turned into an unnamed crash] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: class BOTH_FAIL != baseline REFUSAL R-PNVI-01 ORACLE_CRASH
  PLANT OK   [P7b refusal mirrored as the oracle's crash (both crash alike)] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: class BOTH_FAIL != baseline REFUSAL R-PNVI-01 ORACLE_CRASH
  PLANT OK   [PO the oracle ignores the switch] -> RED:   litmus/cheri_03_ii: oracle-side hash ed5ba148c54c != baseline 32faef2d53f2 (the oracle's answer moved)
  PLANT OK   [missing Lean engine] -> RED: test_pnvi: FAIL — Lean driver missing: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pnvi-ae-udi/.tmp/scripts/pnvi-selftest.QGcG9HxL/nonexistent
  PLANT OK   [empty selection] -> RED: pnvi_lane: FAIL — empty selection (no rows ran)
  PLANT OK   [B1 a selected row deleted from the baseline] -> RED:   litmus/cheri_03_ii: row ran but is not in the baseline (unclassified)
  PLANT OK   [B2 a phantom selected row] -> RED:   litmus/cheri_03_iii: baseline row not run (missing)
  PLANT OK   [B3 a refusal row relabelled as agreement] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: class REFUSAL R-PNVI-01 ORACLE_CRASH != baseline AGREE
  PLANT OK   [B4 an oracle hash changed] -> RED:   litmus/cheri_03_ii: oracle-side hash 32faef2d53f2 != baseline 000000000000 (the oracle's answer moved)
  PLANT OK   [B5 the default-mode comparison flipped] -> RED:   litmus/cheri_03_ii: default-mode comparison changed != baseline same
  PLANT OK   [B6 a malformed row class] -> RED: pnvi_lane: FAIL — baseline line 33: unknown row class 'MATCHISH'
```

The engine stubs are small Python wrappers (P1 strips `--switches` and execs the real driver; P7a/P7b rewrite the
real driver's refusal message — remove the id, or replace it with the oracle's crash text — and keep its exit
status; PO strips `--switches` from the ORACLE), installed through `common.sh`'s loud override hooks.

### 5.2 The design's plants P1–P8 (§D.2)

| Plant | How | Result |
|---|---|---|
| P1 the flag is ignored at the CLI (= a Lean build that treats ae_udi as the default) | the strip stub, on the WHOLE lane (once) and in every `--selftest` | RED. Whole lane: `SUMMARY: rows=164 AGREE=137 BOTH_FAIL=3 DIFF=24 …`, `pnvi_lane: FAIL — 49 RED item(s):` — exactly the 25 rows where the switch changes the oracle's answer: the 17 litmus rows, `minimal/072`/`097`, the three allocator drivers, the three witnesses (r07 as BOTH_FAIL) |
| P2 the elaborator ignores the switch | scratch build: `CerbGlobal.is_PNVI ()` → `false` at the 3 sites of `generated/Translation.lean` (rebuilt, binary copied, file restored byte-identical and rebuilt) | RED: `SUMMARY: rows=164 AGREE=147 AGREE-FIRST=3 BOTH_FAIL=2 DIFF=5 REFUSAL=7 …`; DIFF on `litmus/cheri_03_ii`, `pointer_from_int_disambiguation_2`, `_3`, `minimal/072-out-of-bounds.undef`, `097-null-ptr-arith.undef` |
| P3 the memory model treats ae_udi as default | scratch build: `findOverlapping`'s `AE_UDI` row `(true, true)` → `(false, false)` | RED: `SUMMARY: rows=164 AGREE=149 AGREE-FIRST=3 BOTH_FAIL=3 DIFF=9 …`, `pnvi_lane: FAIL — 20 RED item(s):` — the 4 R-PNVI-01 rows become DIFF, `pointer_from_int_disambiguation_2`, `provenance_roundtrip_via_intptr_t_onepast`, both `union_punning_2` rows DIFF, `r05` becomes AGREE (the class change is RED), `r06` DIFF, `r07` BOTH_FAIL |
| P4 the inverse (Main passes `[.PNVI .AE_UDI]` unconditionally) | scratch build, then the DEFAULT exec lane (Tier A row 2) against it | RED: `REGRESSION: 072-out-of-bounds.undef.c baseline=UB_MATCH current=UB_DIFF`, `Baseline check: 1 regression(s), 0 improvement(s)`, `FAILED: regressions vs baseline` |
| P5 no hidden default instance | rule W1 of `check_no_fuel_numerals.sh` (S1 §14) | its `--selftest` W1 plants, red in row 1 (`SELFTEST OK (31 plants …)`) |
| P6 the refusal control | `check_cli_refusals.sh`: acceptance control + agreement witness; the lane: the refuse-everything stub | both RED (§2.3, §5.1) |
| P7 a refusal silently turned into a mirror | stubs P7a (unnamed crash) and P7b (the oracle's crash text): the lane requires the named class | RED (§5.1). The compile-time half (a mirror pinned as a refusal fails `pnvi-arms-test`) is §1.1's plant check |
| P8 the instance gate both directions | withdrawn as gate cruft in S1 §14 ([USER 2026-10-07]); W1 is the speedbump | not re-run |

The scratch builds were made in place (edit, capped `lake build cerberus-lean`, binary copied to `.tmp/`,
source restored, rebuilt); every restored file was compared (`cmp`) or grepped back, the handwritten-sync gate
was green after, and the gated tree was rebuilt from the committed sources (§8).

[AGENT] Finding of P2: `pkvm-init` is NOT the elaborator-sensitive row the design expected (§D.2 P2: "RED on …
the `pkvm_init` location row"). Its exhaustive set is the same two executions with and without the switch
(`default=same` in the baseline); the location difference of design §C.3 was a one-trace artefact of the random
mode (§C.6 already suspected that). The elaborator is pinned instead by `cheri_03_ii`, `disambiguation_2/3` and
the two minimal rows.

### 5.3 Selftest selection fixed (`372b6fce6`) [AGENT]

The selection's comment called `pkvm/pkvm-init` the switch-dependent elaboration row; §5.2 shows it is not
(P1 leaves it green). `372b6fce6` replaces it in the selection by `pkvm/pkvm-alloc` (P1 turns it RED; it also
exercises the derivation and the AGREE-FIRST class) and corrects the comment. Tier A (incl. the selftest) ran on
that commit (§8.2).

## 6. pKVM

Measured on the oracle (this worktree's fork oracle, `CERB_MEM_MAX=4G scripts/capped`, census flags, under the
switch), verbatim (my probe's lines; `head=` is the first 200 bytes of stdout):

```
alloc rand1 rc=0 wall=.183701135 maxrss=58340kB lines=1 head=Defined {value: "Specified(61728)", stdout: "", stderr: "", blocked: "false"}
free rand1 rc=0 wall=.184011892 maxrss=60336kB lines=1 head=Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
split rand1 rc=0 wall=.156697755 maxrss=59116kB lines=1 head=Defined {value: "Specified(4508)", stdout: "", stderr: "", blocked: "false"}
init rand1 rc=1 wall=.120433924 maxrss=57516kB lines=1 head=Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:6>"}
init exh rc=0 wall=.117875134 maxrss=58100kB lines=4 head=EXECUTION 0:
Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:17>"}
EXECUTION 1:
Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:6>"}
alloc exh rc=137 wall=135.674557822 maxrss=4204300kB lines=0 head=
==============================================================
capped: OOM-KILLED (exit 137 — cgroup memory cap CERB_MEM_MAX=4G breached; memory.events oom_kill=1; NOT a pass)
==============================================================
```

(rand2/rand3: the same verdict on every unit; the `pkvm-init` random trace gave `<715:2--715:6>` three times.)

- **Allocator drivers** (`pkvm-alloc` 61728, `pkvm-free` 0, `pkvm-split-merge` 4508 — the census's and native
  gcc's values): `AGREE-FIRST` on Lean `--first`, outside CONTRACT §1 (design §F.8). Exhaustive resource limit:
  `pkvm-alloc` breaches the 4G per-test cap on the ORACLE after 135.7 s (above). The Lean exhaustive run was not
  attempted [AGENT: the design's §C.3 reading — every cross-object pointer comparison forks — applies to both
  engines; a Lean run past 4G would be a scheduling question, not evidence]. The lane does not run the
  exhaustive allocator rows (the bound is recorded in the baseline header).
- **`pkvm-init`**: `AGREE`, exhaustive, its two-execution set pinned by the oracle-side hash (locations
  `<715:2--715:17>` and `<715:2--715:6>`, in that order on both engines). The set is the same without the switch.
- No refusal is reached by any pKVM driver (the design's §G.2 prediction holds on these traces).

## 7. Docs and tray

- **CONTRACT.md** §2: "Semantics switches: PNVI_ae_udi supported, matched against the oracle under the same
  switch; every other switch refused." §3: the switch row split into the SUPPORTED `PNVI_ae_udi` row, the
  REFUSED PNVI-ae-udi-arms row (every R-PNVI id with its witness: -01 by 4 litmus files, -05/-06/-07 by the
  witnesses, the rest by compile-time pins; R-PNVI-09 stays a default-path look-alike, §H.1) and the REFUSED
  other-switches row (R-PNVI-11/12). §4.1 names the lane's refusal rows as witnesses.
- **VALIDATION.md** §3(c): the switch row rewritten — the supported set, the refusals as class (c) with ids, the
  fork ≠ Lean note for the registered refusal rows, the §H/§H.1 default-path note; §5: the lane row; the register
  tally.
- **SUPPORTED.md**: a semantics-switch row. **README.md**: one sentence. **`lean_frontend/CLAUDE.md`**: the
  CerbMem/CerbGlobal/Main rows and a script row. **LADDER.md**: row 14; row 1's check_cli_refusals text.
- **The failure-reach register** (`scripts/failure_reach_register.txt`): the 9 PNVI refusal rows re-reviewed,
  because their reach reasons rested on "Main.lean refuses every --switches value". R-PNVI-01 (first-argument
  arm), -05, -06, -07 → REACHABLE with their lane witnesses; -03 → UNKNOWN (it needs a zero-size allocation exactly
  at a boundary; two attempts with `malloc(0)` placed it 8 bytes away); -01 (second-argument arm), -01b, -02, -04
  stay UNREACHABLE-BY-INVARIANT with structural reasons. Resealed: `UNREACHABLE-BY-INVARIANT=173 REACHABLE=44
  UNKNOWN=22` (was 178/40/21).
- **Upstream tray** (reports only, Draft; INDEX rows + the "added since" line): `50-switches-parser-fail-open.md`
  (re-measured: a typo runs PVI; `PNVI,PNVI_ae_udi` runs PLAIN PNVI — MEASURED by the review round on pristine
  upstream `b9aeedcb4` with `tests/pnvi_testsuite/provenance_roundtrip_via_intptr_t_onepast.c`: `--switches=PNVI`
  and the override give UB046, `PNVI_ae_udi` gives `Defined`; the first draft's reproducer printed
  `Specified(7)` under both PNVI variants and could not show it), `51-combine-prov-crash-on-pnvi-litmus.md`,
  `52-debug-printf-in-eff-array-shift-pnvi-arm.md` (code-level; no reproducer found),
  `53-array-shift-ptrval-crash-on-symbolic-pointer-memcpy.md` (repro = witness `r06`). Upstream line numbers were
  re-read at `b9aeedcb4` (`git show b9aeedcb4:memory/concrete/impl_mem.ml`).

## 8. Gates

Gated trees: Part 1 at `14057bf1a`'s working tree (row 1); S4 at `372b6fce6` (Tier A, which runs row 1 as `A1` and
the lane's selftest and the lane as `A14.1`/`A14.2`), with no tracked or untracked change (this record was written
outside the tree during the run). Lean was rebuilt through `scripts/capped` before each (the last rebuild at
`e60432f28`; `372b6fce6` changed one script only).

### 8.1 Part 1: row 1 (`scripts/test_unit.sh` via `scripts/ce`)

Verbatim selected lines:

```
✓ pnvi-arms-test PASSED
PnviArmsTest: 9 refusal pins (R-PNVI-01 ×2, -03, -04, -05, -06, -07, -08, -10) + 2 negative controls checked at compile time
PnviArmsTest: 37/37 runtime witnesses passed
Total: 18 passed, 0 failed
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=178 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_cli_refusals: OK (23 refusals pinned: --concurrency, --iso, 20 --switches= values (every oracle switch-name class, an unknown name, an override, a mixed set, the empty value) and the --switches space form; 4 switch-placement verdicts (--parse-core =/space, before a misplaced --batch, a repeated unknown name not an override); 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
rc=0
```

### 8.2 S4: Tier A (`python3 scripts/release.py --mode fast` via `scripts/ce`) on `372b6fce6`

Verbatim row verdicts (the 19 `PASSED` lines joined onto one line; the joining is mine) and the runner's tail
(`rc=0` is my wrapper's):

```
PASSED A1 (446.3s) PASSED A2 (34.6s) PASSED A3 (73.3s) PASSED A4 (23.5s) PASSED A4b (25.3s) PASSED A4c (3.3s) PASSED A5 (104.7s) PASSED A6 (4.1s) PASSED A6b (3.7s) PASSED A7 (10.7s) PASSED A8 (9.1s) PASSED A9 (17.4s) PASSED A10 (17.9s) PASSED A11 (60.2s) PASSED A12.1 (5.0s) PASSED A12.2 (4.6s) PASSED A13 (1.5s) PASSED A14.1 (65.8s) PASSED A14.2 (161.8s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

The lanes' own last lines, from the run's evidence directory (scratch, deleted at slice end; the row labels are
mine):

```
A2     BASELINE OK
A3     BASELINE OK
A4     BASELINE OK
A4b    BASELINE OK
A4c    ALL AT COMMITTED EXPECTEDS
A5     ALL MATCH RECORDED BASELINE
A6     ALL PASSED
A6b    ALL PASSED
A7     ALL PASSED
A8     ALL PASSED
A9     SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
A10    GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
A11    BASELINE OK (213 entries, exact match)
A12.2  test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
A13    PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
```

Row 1 (`A1`), verbatim selected lines (each distinct line once):

```
✓ pnvi-arms-test PASSED
PnviArmsTest: 37/37 runtime witnesses passed
PnviArmsTest: 9 refusal pins (R-PNVI-01 ×2, -03, -04, -05, -06, -07, -08, -10) + 2 negative controls checked at compile time
Total: 18 passed, 0 failed
check_cli_refusals: OK (24 refusals pinned: --concurrency, --iso, 21 --switches= values (every oracle switch-name class but PNVI_ae_udi alone, an unknown name, overrides, mixed sets, the empty value and a trailing empty element) and the --switches space form; --switches=PNVI_ae_udi ACCEPTED in both forms, and on one program it runs, agrees with the oracle under the same switch and differs from the default; 6 switch-placement verdicts (--parse-core =/space/accepted, before a misplaced --batch refused and accepted, a repeated unknown name not an override); 4 repeated options refused: --runtime, --args, --switches twice (=/= and space/=); control not refused)
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=173 REACHABLE=44 UNKNOWN=22; every row sealed; tally line consistent)
check_no_fuel_numerals: OK (336 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1), no production call of the default-pinned reconstructValue wrappers (W2); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy); W2 wrapper lines seen: 6 of 6)
check_lem_sync: OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen c1bb429a5ccb2b91903f5d02b30141aa2c711c50c2d4d7543b42226e119580f3)
check_lem_sync: lean OK (src 37a9392cf043669821430a08b4c43e58d7ff407a34de470fdffaee929b02e47c, gen aa49e3bfc257299082c3a01287d4b99c91a9164f32f251d02297c808315b77fd)
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
check_handwritten_sync: OK (50 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

The lane (`A14.2`), its last two lines:

```
SUMMARY: rows=164 AGREE=152 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): litmus:same=27,changed=17 minimal:same=111,changed=2 pkvm:same=1,changed=3 witness:same=0,changed=3
pnvi_lane: BASELINE OK (164 rows = the baseline, classes and oracle hashes exact)
```

Its selftest (`A14.1`): the control and the verdict line (the plant lines are those of §5.1, with the control's
selection now carrying `pkvm/pkvm-alloc`):

```
  CONTROL OK [control: unplanted selection] -> SUMMARY: rows=5 AGREE=2 AGREE-FIRST=1 REFUSAL=2 | switch vs default (oracle): litmus:same=0,changed=3 pkvm:same=0,changed=1 witness:same=0,changed=1
test_pnvi: SELFTEST OK (control green; 7 engine plants RED — P1 flag ignored, P6 refuse-everything, P7a unnamed crash, P7b mirrored crash, PO oracle ignores the switch, missing engine, empty selection; 6 baseline plants RED — deleted, phantom, relabelled refusal, oracle hash, default flag, malformed class)
```

A9's five DIFF rows are the recorded ones (S3 record §8.2): the default-mode C→Core elaboration did not move.

### 8.3 An earlier Tier A run on `e60432f28` (superseded, kept for the record)

All 19 commands passed, but the run is NOT a certification: I created this record's file in the tree during
it, so the runner reported the source as changed. Verbatim tail and the report's source fields:

```
PASSED A14.1 (66.2s)
RUN A14.2: ./scripts/test_pnvi.sh
PASSED A14.2 (162.2s)
fast: incomplete; 19/19 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

`source_before.status` was `''`; `source_after.status` was `'?? lean_frontend/docs/2026-10-07_pnvi-s4-lane-record.md'`
(head `e60432f28` and the diff hash identical). The gate of record is §8.2.

## 9. Default-mode zero-change evidence

1. **No `.lem` change**; row 1's `check_lem_sync` prints the same generated-tree hashes as S1–S3 (`c1bb429a…`
   OCaml, `aa49e3bf…` Lean) and the fork-drift layer 2 is unchanged (§8).
2. **The default instance is the same value**: without `--switches`, `switchSet = CerbGlobal.defaultSwitches`, the
   value S1–S3 supplied.
3. **Every Tier A lane at its committed baseline**, incl. A9 (C→Core elaboration) at `same=108 diff=5` — the five
   recorded DIFF rows (§8.2).
4. **The CerbMem/CerbGlobal edits are comments** except Part 1's two refusal sites, which are unreachable at the
   default set; `pnvi-arms-test`'s default-instance controls pass.
5. **The inverse plant P4** shows the default lanes do see the parameter (§5.2).

Nothing in default mode moved. No STOP.

## 10. Deviations

- **D-S4-1 [AGENT] — the refusal witnesses are new test programs** (`tests/pnvi_refusals/`, 3 files). The brief
  listed litmus/pKVM/minimal; the witnesses give R-PNVI-05/-06/-07 the CONTRACT §4.1 lane witness the litmus suite
  does not (R-PNVI-06 is the S3 review's F2). Each file states the arm it reaches.
- **D-S4-2 [AGENT] — the minimal sample is the whole `tests/minimal` corpus** (113 files): cheap (inside the
  2:49 pass), so no sample choice is needed. Tier B additions (`tests/ci`, `tests/libc_exec` under the switch,
  design §D.1 row 3) were not added.
- **D-S4-3 [AGENT] — the baseline pins the ORACLE side too** (a hash per row) and the default-mode comparison.
  This goes beyond "Lean = oracle": an oracle that drifts, or that ignores the switch, is RED (plant PO).
- **D-S4-4 [AGENT] — `BOTH_FAIL` is exactly two shapes** (class (a), VALIDATION §1(a); narrowed by the S4 review
  F1, 2026-10-07): (1) Error/Error — ONE `Error` verdict on each side, EQUAL under the codec's existing
  `failure-class` projection (`scripts/observations.py`: `Symbol(<digits>, ` → `Symbol(_, `, nothing else; the
  projection LADDER row 6b uses), so two Errors of different failure text are DIFF — narrower than §1(a)'s "only
  the text differs", the fail-closed reading; (2) CRASH/CRASH — both engines die with an internal failure and the
  oracle's crash is NOT one an R-PNVI id names. A crash on one side and a verdict (an `Error` included, a Lean
  `ModelFailure` included) on the other is DIFF — for the `ModelFailure` case this is a further [AGENT] narrowing: VALIDATION §1(a) (lines ~209-215) counts a Lean `ModelFailure` against an oracle uncaught exception as a both-fail pair; the lane does not (fail-closed). The REFUSAL-CRASH rule: an oracle crash whose payload fully
  matches an R-PNVI `ORACLE_SIDE` crash pattern (anchored, `fullmatch`) REQUIRES Lean `REFUSAL <that id>` —
  anything else is DIFF. BOTH_FAIL and RESOURCE rows pin a `lean=` hash of the Lean side (required there,
  forbidden elsewhere), so a Lean-side change that keeps the class is RED. The only members are the two
  default-lane `CERB_SKIP` rows, `minimal/073-exit.libc` and `074-abort.libc` (both qualify under shape (1));
  a new member must be baselined. The `verdict` ids (R-PNVI-03/-05/-08/-10): the classifier checks only that the
  oracle answered, not that it took the flagged arm — the per-row review plus the oracle hash cover that.
  Plants P8a/P8b/P8c/B7 (§12).
- **D-S4-5 [AGENT] — the allocator drivers' exhaustive runs are not part of the lane** (resource limit recorded,
  not re-measured per pass; Lean exhaustive not attempted, §6).
- **D-S4-6 [AGENT] — under `--parse-core` the accepted switch is refused**, not ignored (the parser mode reads no
  switch set; ignoring it would be a silent absorption).
- **D-S4-7 [AGENT] — the register re-review is in S4** (design §D.4 put it with the lane); R-PNVI-03 moved to
  UNKNOWN, not to REACHABLE.
- **D-S4-8 [AGENT] — P2 does not turn `pkvm-init` RED** (§5.2 finding); the design's expectation is superseded by the
  measurement.
- **D-S4-9 [AGENT] — R-PNVI-12 text fix as its own commit** (`e60432f28`), found while recording §2.2; Tier A ran
  after it.

## 11. Consumer-visible changes for S5 (cerberus-sl)

- **Signatures: none changed** in `CerbMem`, `CerbGlobal`, the driver entries or the generated tree. New name:
  `CerbMem.pnviRefuseM` (a `memM` refusal). Changed TERMS: `CerbMem.diffPtrval` and `CerbMem.effArrayShiftPtrval`
  (their R-PNVI-08/-10 arms are now `match pnviRefuseM … with | ND f => f st`); frozen fingerprints covering those
  terms may drift (S5 measures). Consumer mentions of both: 0 (S3 record §10).
- **`Main`** (not a library surface for them): `judgeSwitches`, `knownSwitch`, `refuseSwitchesParseCore`; the
  run's instance is `⟨switchSet⟩`.
- **Behaviour at the default instance: unchanged** (§9). Their corpus check and freeze reference run are S5's.
- **New user-visible mode**: `--switches=PNVI_ae_udi`; facts under it (`@… ⟨[.PNVI .AE_UDI]⟩`) are what a future
  reasoning effort would bind (design §F.11).

## 12. Review round (S4 review F1–F6, 2026-10-07)

Scripts and docs only; no Lean semantics change.

- **F1 (trust surface) — `BOTH_FAIL` narrowed to VALIDATION §1(a)** [AGENT, implementing the review's remedy].
  `scripts/pnvi_lane.py`: (i) BOTH_FAIL is exactly Error/Error (one `Error` verdict per side, EQUAL under the
  codec's existing `failure-class` projection — the one LADDER row 6b uses; `scripts/observations.py`'s docstring
  and LADDER row 6b now name this second, non-agreement consumer) or CRASH/CRASH; a crash against any verdict is
  DIFF; (ii) an oracle crash whose payload fully matches an R-PNVI `ORACLE_SIDE` crash pattern REQUIRES Lean
  `REFUSAL <that id>`, anything else DIFF; (iii) BOTH_FAIL and RESOURCE rows pin a `lean=` hash (required on those
  classes, forbidden elsewhere); (iv) plants P8a (the oracle's `combine_prov` crash vs a Lean `Error`), P8b
  (Error/Error, different failure class), P8c (a Lean-side change on a BOTH_FAIL row that keeps the class), B7
  (the `lean=` hash removed); P7a/P7b now assert the CLASSIFIER's DIFF, not only the baseline's class pin; the
  selftest selection gains `minimal/073-exit.libc`. (v) The baseline was re-recorded with
  `scripts/test_pnvi.sh --record-baseline` for the new column only: compared with the previous file, all 164 rows
  keep class, oracle hash and `default=` (a derived comparison by script); the only change is `lean=` on the two
  BOTH_FAIL rows, which both qualify under the narrowed rule:
  ```
  < minimal/073-exit.libc BOTH_FAIL oracle=39fd687e5c3c default=same
  < minimal/074-abort.libc BOTH_FAIL oracle=d75bc58e450c default=same
  ---
  > minimal/073-exit.libc BOTH_FAIL oracle=39fd687e5c3c lean=28d6c879bca1 default=same
  > minimal/074-abort.libc BOTH_FAIL oracle=d75bc58e450c lean=18daf109f90c default=same
  ```
  The re-record is in this one review-round commit, not a separate instrument commit (the round's brief asked for
  one coherent commit). Scope: D-S4-4 (rewritten).
- **F2** — CONTRACT's PNVI row and VALIDATION's PNVI paragraph no longer call R-PNVI-08/-10 "unreachable by
  invariant": they are monadic sites (`pnviRefuseM`) outside the pure failure-reach census; their reach is UNREVIEWED.
- **F3** — tray 50 gains a reproducer that tells plain PNVI from PNVI-ae-udi (upstream's
  `provenance_roundtrip_via_intptr_t_onepast.c` on pristine upstream `b9aeedcb4`: `PNVI` and `PNVI,PNVI_ae_udi`
  give UB046, `PNVI_ae_udi` gives `Defined`), so "runs plain PNVI" is now measured; its Impact sentence is
  corrected (the old one claimed the shown verdicts differ in the override case, where they did not); §7 reworded.
- **F4** — every `ORACLE_SIDE` crash pattern is matched with `fullmatch` (R-PNVI-04 `Not_found`, R-PNVI-07
  `case_ptrval` included); the docstring states that for the `verdict` ids (-03/-05/-08/-10) the classifier cannot
  check the oracle took the flagged arm, and that the per-row review plus the oracle hash cover it.
- **F5** — §0's quotes: the 2026-10-05 quote restored in full (as in the design record); the 2026-09-30 quote's
  trims marked with `…` (the committed records carry only that span). D-S4-8 tagged [AGENT].
- **F6** — `test_pnvi.sh` removes `pkvm-derived/` (the derived GPL-2.0-only `page_alloc_census.c`) and the bridged
  pKVM Cabs JSONs before any `--keep-run` copy, and registers them with common.sh's cleanup so RED runs (whose
  observation directory is kept as evidence) do not keep them; after the selftest, the full lane and Tier A,
  `find .tmp -name page_alloc_census.c` printed nothing.

### 12.1 Gates

Gated tree: `a91d251ec` plus this round's working-tree diff, all files except this §12 (written after the gates);
`git diff a91d251ec -- . ':!lean_frontend/docs/2026-10-07_pnvi-s4-lane-record.md' | sha256sum` =
`6b93a0aace8fb5bad4acf5020f7a596f4d305152f9cdfe718fa51c9fb2814e80`. The Lean build was unchanged (no Lean source
touched; `build_lean` ran inside each lane run). The full lane and row 1 ran separately first, before two comment-only
edits (the `observations.py` docstring, LADDER row 6b); Tier A ran on the final tree and includes row 1 (`A1`), the
selftest (`A14.1`) and the lane (`A14.2`). Verbatim, Tier A's `A14.1` stdout (its CONTROL/PLANT lines each cut
at 260 characters — the cut is mine; the final line whole):

```
  CONTROL OK [control: unplanted selection] -> SUMMARY: rows=6 AGREE=2 AGREE-FIRST=1 BOTH_FAIL=1 REFUSAL=2 | switch vs default (oracle): litmus:same=0,changed=3 minimal:same=1,changed=0 pkvm:same=0,changed=1 witness:same=0,changed=1
  PLANT OK   [P1 Lean ignores the switch (flag stripped)] -> RED:   litmus/pointer_from_int_disambiguation_1: class DIFF != baseline AGREE
  PLANT OK   [P6 Lean refuses everything] -> RED:   DIFF                               litmus/cheri_03_ii  [lean refused at the CLI: cerberus-lean: refused — plant: every input refused]  default=changed
  PLANT OK   [P7a refusal turned into an unnamed crash] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: DIFF — the oracle crash names R-PNVI-01/R-PNVI-01b: Lean must refuse with it; lean: CRASH combine_prov, a Prov_symbolic provenance (fir
  PLANT OK   [P7b refusal mirrored as the oracle's crash (both crash alike)] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: DIFF — the oracle crash names R-PNVI-01/R-PNVI-01b: Lean must refuse with it; lean: CRASH Concrete.combine_prov: found a P
  PLANT OK   [P8a oracle combine_prov CRASH vs Lean Error] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: DIFF — the oracle crash names R-PNVI-01/R-PNVI-01b: Lean must refuse with it; lean: OBS ('ERR:{msg: "plant: a PNVI refusal reported as 
  PLANT OK   [P8b Error vs Error with a different failure class] -> RED:   minimal/073-exit.libc: DIFF — both Error, failure class differs
  PLANT OK   [P8c a Lean-side change on a BOTH_FAIL row (class kept)] -> RED:   minimal/073-exit.libc: lean-side hash 804ab26db86c != baseline 28d6c879bca1 (the Lean side of a BOTH_FAIL row moved)
  PLANT OK   [PO the oracle ignores the switch] -> RED:   litmus/cheri_03_ii: oracle-side hash ed5ba148c54c != baseline 32faef2d53f2 (the oracle's answer moved)
  PLANT OK   [missing Lean engine] -> RED: test_pnvi: FAIL — Lean driver missing: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/pnvi-ae-udi/.tmp/scripts/pnvi-selftest.rv4e05Kd/nonexistent
  PLANT OK   [empty selection] -> RED: pnvi_lane: FAIL — empty selection (no rows ran)
  PLANT OK   [B1 a selected row deleted from the baseline] -> RED:   litmus/cheri_03_ii: row ran but is not in the baseline (unclassified)
  PLANT OK   [B2 a phantom selected row] -> RED:   litmus/cheri_03_iii: baseline row not run (missing)
  PLANT OK   [B3 a refusal row relabelled as agreement] -> RED:   litmus/provenance_basic_using_uintptr_t_global_yx: class REFUSAL R-PNVI-01 ORACLE_CRASH != baseline AGREE
  PLANT OK   [B4 an oracle hash changed] -> RED:   litmus/cheri_03_ii: oracle-side hash 32faef2d53f2 != baseline 000000000000 (the oracle's answer moved)
  PLANT OK   [B5 the default-mode comparison flipped] -> RED:   litmus/cheri_03_ii: default-mode comparison changed != baseline same
  PLANT OK   [B6 a malformed row class] -> RED: pnvi_lane: FAIL — baseline line 35: unknown row class 'MATCHISH'
  PLANT OK   [B7 the lean= hash removed from a BOTH_FAIL row] -> RED: pnvi_lane: FAIL — baseline line 151: class 'BOTH_FAIL' requires a lean= hash
test_pnvi: SELFTEST OK (control green; 10 engine plants RED — P1 flag ignored, P6 refuse-everything, P7a unnamed crash, P7b mirrored crash, P8a oracle crash vs Lean Error, P8b Error/Error failure class differs, P8c BOTH_FAIL Lean side moved, PO oracle ignores the switch, missing engine, empty selection; 7 baseline plants RED — deleted, phantom, relabelled refusal, oracle hash, default flag, malformed class, BOTH_FAIL lean hash missing)
```

Tier A `A14.2` (the full lane):

```
SUMMARY: rows=164 AGREE=152 AGREE-FIRST=3 BOTH_FAIL=2 REFUSAL=7 | switch vs default (oracle): litmus:same=27,changed=17 minimal:same=111,changed=2 pkvm:same=1,changed=3 witness:same=0,changed=3
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
```

Row 1 (`scripts/test_unit.sh` via `scripts/ce`, rc 0) and Tier A `A1`: `Total: 18 passed, 0 failed`. Tier A (`python3 scripts/release.py --mode fast` via `scripts/ce`), the 19 `PASSED` lines joined onto one line (the joining is mine) and the tail (`rc=0` is my wrapper's):

```
PASSED A1 (458.0s) PASSED A2 (29.0s) PASSED A3 (73.0s) PASSED A4 (23.4s) PASSED A4b (25.6s) PASSED A4c (3.3s) PASSED A5 (103.6s) PASSED A6 (4.0s) PASSED A6b (3.7s) PASSED A7 (10.6s) PASSED A8 (9.1s) PASSED A9 (17.2s) PASSED A10 (18.3s) PASSED A11 (59.2s) PASSED A12.1 (5.0s) PASSED A12.2 (4.7s) PASSED A13 (1.6s) PASSED A14.1 (108.1s) PASSED A14.2 (164.2s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
rc=0
```

## 13. Delta review of the fix round (2026-10-07) — orchestrator fixes [AGENT]

Fresh read-only review of `a91d251ec..01e2ee40b`: F1 classifier fix holds (both original holes now DIFF; no new
absorbing path). Findings fixed by the orchestrator in the follow-up commit:
- **F6 not closed (medium):** `common.sh capture_cabs_json` keeps a byte-identical copy of each bridged Cabs JSON
  as `<prefix>.bridgeN.stdout`, which survived in kept evidence dirs (16 copies after one selftest, incl. the Cabs
  JSON of the derived `page_alloc_census.c`). Now registered for cleanup per bridge and removed at the end, with a
  post-check that no `pkvm__*.json` / `pkvm__*.bridge*.stdout` survives (loud die). The §12 F6 statement above
  ("the bridged JSONs are removed") was incomplete until this fix.
- **D-S4-4 / docstring cited §1(a) for the `ModelFailure` rule**, which §1(a) actually contradicts: relabelled as an
  [AGENT] fail-closed narrowing.
- **Two [USER] quotes in §0 trimmed without an ellipsis:** fixed (ellipsis / full opening restored).
- INFO (fail-closed, unchanged): a bare upstream `Not_found` from any site demands R-PNVI-04 (documented).
