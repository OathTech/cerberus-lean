# ZERO-DISCREPANCY — census charter (2026-09-03)

Branch `arc/zero-discrepancy` @ base mainline `72164481a`. Docs-only
slice: this charter and nothing else. Author: the charter worker
[AGENT]; every ruling quoted below is [USER 2026-09-03] unless marked
otherwise; every classification, price and count is [AGENT] and open
to operator override at the §7 asks.

Inputs read in full: the noodler's record
`docs/2026-09-03_noodle-cerberus-lean.md` and probe corpus
`tests/noodle-probes/` (branch `noodle/semantics` @ `798cca224`, 145
probes / 11 directories, per-probe INTEGRATION columns); `VALIDATION.md`;
`docs/2026-08-30_parity-detective-report.md`;
`docs/2026-08-31_trust-basket.md`; `docs/2026-09-02_fuel-arc-design.md`
§2 (branch `arc/fuel`); `docs/2026-09-02_mem-scale-record.md`;
`docs/upstream-tray/INDEX.md` (18 + 1 drafts);
`lean_frontend/handwritten_copy.manifest` (22 files); the lane
baselines (`scripts/exec_*_baseline.txt`, `scripts/gcc_oracle_baseline.txt`,
`scripts/gcc_oracle_triage.txt`, `tests/immaculate/baseline.txt`,
`tests/libc_exec/baseline.txt`, `tests/libxml2/uri_baseline.txt`,
`tests/cn_coverage/baseline.txt`, the committed `tests/ci_sweep/results/*.tsv`
and the `tests/parity-probes/sweep-2026-08-30/*.tsv` snapshot).

Probes run for this charter (read could not settle them; binaries
rebuilt in this worktree by the harness's own `build_cerberus`/
`build_lean`, stamps recorded; `scripts/capped`, `CERB_MEM_MAX=16G`):
the mode-flag probes of §2.3 (`.zd-scratch/probes/`, ephemeral — the
verbatim lines are quoted where used) and one run of `test_elab.sh` to
name its three recorded DIFF rows.

Revision R1 (2026-09-03, same day): the orchestrator's fresh review of
`6a55dc74d` returned RATIFY-WITH-AMENDMENTS (F1–F11 + register + refusal
+ Q recommendations + scope). Every amendment was applied only after its
cite was re-verified in this worktree (file:line read, or probe re-run
and quoted verbatim); the reviewer's probes were re-run, not trusted.
Row ids Z-72…Z-75 are new; changed rows say "(R1)".

Revision R2 (2026-09-03): addendum from the dynamic_addrs investigation
(branch `probe/dynamic-addrs` @ `2700f99c0`, record
`docs/2026-09-03_dynamic-addrs-investigation.md`, probes
`tests/noodle-probes/dynamic-addrs/`, tray draft 19 — which takes the
number 19, so this charter's planned drafts renumber to 20–33). Cites
re-read in this worktree; quoted lines verbatim from that branch's
`results.log`. New rows Z-76, Z-77; Z-10 amended; R4 added to §2.6.

Terminology, fixed for the whole document:

- **oracle** — the OCaml Cerberus built from this repository's `.lem`
  + OCaml sources, run in the MATCHED MODE (same `--nolibc`/libc
  linkage, `--mode=exhaustive` or `--first` ≙ single trace, default
  switches, no `--concurrency`). **upstream** — un-forked
  `deps/cerberus-upstream` @ `b9aeedcb4`, the third point.
- **execution discrepancy** — on a program both engines run, a
  difference in the verdict the semantics reports: the outcome class
  (`Defined`/`Undefined`/`Error`/tool failure), the value, the UB code,
  the UB location, stdout/stderr bytes, the trace set.
- **mirror** — make the Lean text compute what the OCaml text
  computes, with a `file:line` cite (the mirror-OCaml doctrine,
  container CLAUDE.md).

## 0. Headline

Under the rule of §1 the census of §2 has **77 rows** (R1: 71 + 4; R2: + 2). Derived totals by
class (the class vocabulary is §1.5):

| Class | Rows | What it means |
|---|---|---|
| BUG-FIX | 26 | Lean ≠ oracle, or a refusal that is not loud-and-attributed, or a fail-open path; mirror the oracle (Z1–Z3) |
| EXCEPTION (a) message text | 6 | failure class identical, text differs; declared (Z-38's claim must still be MEASURED, R1 F10) |
| EXCEPTION (b) resource | 3 | 2 are (b)-VIOLATIONS (Lean fails where the oracle succeeds — BUG with a named mover), 1 is a lane bound tolerated only per row with measured completion evidence (Q5) |
| EXCEPTION (b)/fuel | 1 | fuel exhaustion, accepted verbatim |
| EXCEPTION (c) missing feature | 2 | loud, feature-attributed refusal verified (CerbFS refused set); concurrency (once the Z-24 refusal lands) |
| ORACLE-SUSPECT → mirrored + tray | 17 | Lean == oracle ≠ ISO/gcc; correct under the rule; tray draft (incl. Z-77, tray 19) |
| REGISTER CANDIDATE (class (d)) | 4 rows / 4 candidates (R4's row is Z-77) | existing Lean-right/oracle-wrong pins (R1–R3; reviewer recommends ADMIT, R3 under (ii')) + R4 (dynamic_addrs; recommendation DEFER); operator rules per entry |
| RULING PENDING | 1 | Z-73: a failure-vs-success class difference Lean introduced deliberately (fail-closed over an oracle silent-success) — Q8 |
| Z2-DISPOSED | 6 | header-declared seam divergences the audit must mirror or declare-with-reachability-argument (none may stay "recorded") |
| INSTRUMENT / OUT-OF-SCOPE | 8 | not Lean-vs-oracle execution content (native layout; pp-filter granularity; stale cites; stale sweep snapshot incl. the 43 `CERB_INCONSISTENT` rows; bridge; debug stubs) |
| SEAM INDEX | 3 | §2.7 pointers from a seam file to rows above (not counted twice) |

Derived: 26+6+3+1+2+17+4+1+6+8+3 = 77.

The three most consequential findings of the census itself (beyond the
noodler's D1–D7): (i) the Lean driver has NO switch/mode plumbing and
treats `--switches=PNVI` and `--concurrency` as file names — loud, but
not feature-attributed (§2.3, probe-verified); (ii) `CerbFS` refuses
loudly on its five refused paths but still SERVES silently-divergent
answers on named residual paths (missing-file open, `O_EXCL`, zeroed
`stat`, success-returning no-op directory ops, errno-returning
link ops) — a silent-absorption shape rule 2(c) forbids (§2.3); (iii)
the 8 M-element zero-init hang and the byte-list OOM class are
(b)-VIOLATIONS as the operator phrased (b) — Lean fails where the
oracle succeeds — and must carry named movers, not a "known limit"
label (§2.4).

## 1. The rule and the exception classes

### 1.1 The rule [USER 2026-09-03], verbatim

> "All *execution* discrepancies are definitionally bugs (other
> machinery intended to support proof is allowed but should have no
> semantic / execution effect whatsoever and all legacy permission
> revoked"

For cerberus-lean: **Lean ≠ oracle (matched mode) on a program both
run = bug.** The oracle's own deviations from ISO C are MIRRORED
faithfully and filed upstream — the rule is Lean ≠ oracle, not Lean ≠
ISO. Consequences the census applies mechanically:

- "legacy permission revoked": every previously "declared",
  "documented-deliberate", "unobservable" or "temporal-boundary"
  divergence is re-classified below; the label is not a class.
- proof-support machinery (fuel wrappers, reader lifting, opaque
  boundary constants) is permitted only with zero execution effect;
  the fuel design's own guarantee ("sufficient-fuel behaviour is
  unchanged", fuel design §2) is the template.

### 1.2 The exception classes [USER 2026-09-03], verbatim where quoted

**(a) Failure-path MESSAGE TEXT** may differ; the failure-vs-success
classification must be identical. (A tool crash on both sides is
"identical failure class" — the panic text may differ from the OCaml
exception text; a crash on one side and a verdict on the other is NOT.)

**(b) RESOURCE LIMITS** — Lean must not fail where the oracle succeeds;
the converse is acceptable. FUEL exhaustion is accepted under (b):

> "fuel is a reasonable exception because we could always just run the
> semantics with more fuel"

**(c) MISSING FEATURES**:

> "*missing features* are allowed deviations if they are cleanly
> identified. CerbFS is kind of an obscure feature as is concurrency,
> it's unclear if we'll support it"

Operationalised: a LOUD, feature-attributed refusal where the oracle
answers is allowed; a different answer, or a silent absorption (an
errno, a default, a zero) never is. "Loud" = non-zero exit + a message
naming the feature and the boundary; "attributed" = the message names
the missing feature, not a symptom (a file-not-found error for a flag
is loud but not attributed — §2.3).

### 1.3 UB location is behaviour [USER 2026-09-03]

The orchestrator's [AGENT] interpretation — UB LOCATION is part of the
semantics' own deterministic report (the oracle prints it), not runtime
exception text — was put to the operator and **agreed ("(1) agree")**.
Recorded as [USER 2026-09-03]: **location discrepancies are BUG-FIX
rows under §1.1, not exempt under (a)**; the lanes' loc-stripping
(`test_exec.sh` `extract_verdict_seq` greps `ub:` only;
`test_immaculate.sh` normalises "to ignore source locations";
`tests/parity-probes/run_probe.sh` `seq()`; `test_ci_sweep.sh`) is an
instrument blind spot to close after D1/D2 land (§4.1, a baseline
instrument commit). The hedge is removed from this document.

### 1.4 A fourth class — (d) ISO-CORRECTNESS FIXES, the register [USER 2026-09-03 / AGENT proposal]

Operator ruling, verbatim:

> "I think that a short listed set of fixes is in keeping for the
> purpose of cerberus-lean but the bar for such a fix must be extremely
> high."

Design [AGENT, for ratification at §7 Q2]: an explicit **ISO-fix
register** in `VALIDATION.md` — a short, enumerated list of the places
where Lean deliberately deviates from the oracle TOWARD ISO C. Anything
not on the register is BUG-FIX (mirror the oracle + tray). Admission
criteria, each concrete and checkable:

- **(i) Unambiguous oracle bug against a cited clause.** The oracle
  behaviour violates a quoted ISO C11/C17 clause with no plausible
  alternative reading (implementation-defined, unspecified and
  Cerberus-model stances — PVI address comparison, `long double` = 8,
  the exit-code range — are excluded by construction).
- **(ii) A second, independent oracle agrees with Lean** on a
  deterministic, UB-free reproducer: native `gcc -O0` (the second-oracle
  lane's recipe, `docs/2026-08-30_gcc-second-oracle-design.md` §2.1) and,
  where available, clang.
- **(ii') Substitute for UB reproducers (R1 review, tightened):** where
  no native answer exists, ALL THREE must hold: (1) the oracle failure
  is a NON-SEMANTIC HOST EXCEPTION (`Z.Overflow`/`Not_found`/`assert` on
  a host-int conversion) raised BEFORE the semantic path; (2) the Lean
  code is a line-mirror of the OCaml path MINUS that conversion; (3) the
  SECOND ORACLE is the oracle itself with the tray draft's remedy
  applied to a scratch build, shown to produce the Lean verdict.
  Consequence: F2 `(int)NaN` (tray 15's non-finite class) is eligible
  under the same shape; `g4-bswap64-overflow` is NOT (no ISO clause — a
  GNU builtin).
- **(iii) Filed upstream**: a tray draft exists and the register entry
  cross-references it (and the issue URL once filed).
- **(iv) Pinned in the immaculate lane** as a Lean-right/oracle-wrong
  pair whose row comment cites the register entry, so the pair flips
  to MATCH — and the entry is RETIRED — when upstream fixes it. The
  register is therefore self-emptying by construction.
- **(v) Each entry is individually [USER]-ruled**; an agent may
  PROPOSE (this document does, §2.6) and never add.
- **(vi) Soft cap ≤ 10 entries.** Growth toward the cap is itself a
  signal to escalate upstream (file, or carry the fix as an upstream
  PR branch under `upstream-pr/*`), not to widen the register.
- **(vii) Grep-able code marker.** Each entry names its Lean code site,
  and that site carries the literal comment `-- ISO-fix register R<n>`
  (replacing any "DELIBERATE DIVERGENCE"/"never fix-to-match" wording,
  e.g. `CerbDecode.lean:84-91` → R1). A gate can then assert the
  register and the marker set are in bijection.

Register entry shape (one line each, in `VALIDATION.md` §"ISO-fix
register"): `R<n> | <oracle behaviour, file:line> | <ISO clause> | <2nd
oracle evidence> | tray <k> | immaculate pin <row> | [USER <date>]`.

### 1.5 Class vocabulary used in §2

`BUG-FIX` · `EXC(a)` · `EXC(b)` (with `VIOLATION` when Lean fails where
the oracle succeeds) · `EXC(b)/fuel` · `EXC(c)` · `SUSPECT→tray`
(oracle-suspect, mirrored — correct under the rule) · `REG-CAND`
(class (d) candidate, §2.6) · `INSTRUMENT` (a lane/pp artefact, no
execution content) · `OUT-OF-SCOPE` (not Lean-vs-oracle).

## 2. THE CENSUS

Every known Lean-vs-oracle execution difference, one row each. Columns:
id · source cite · oracle behaviour · Lean behaviour · class (with the
argument) · fix location + price (S ≤ ½ day, M ≤ 3 days, L = arc).
Quoted engine lines are verbatim from the cited records or from this
charter's probes; tallies are derived.

### 2.1 The noodler's discrepancies D1–D7 (+ O1, D3)

| id | cite | oracle | Lean | class | fix + price |
|---|---|---|---|---|---|
| Z-01 (D1) | noodle §0 D1; `float/float_inf_to_int_ub.c` | `Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<5:11--5:19>"}` | `… loc: "unknown location"` — every UB raised while executing std.core code (UB017, UB153a/b, UB158, Invalid_format, the 47 `undef(<<DUMMY>>)` sites) loses the C site | **BUG-FIX** (§1.3) | `CoreParser.lean:201/204/1097` stamp std.core nodes with a `Loc.region` whose file is the std.core path so `CerbLocation.isLibraryLocation` holds (mirror `core_parser.mly:1571`); then the shared `core_eval.lem:596-603` / `core_run.lem:778-784` substitution works as on OCaml. **S** |
| Z-02 (D2) | noodle §2 D2; `ptr/ptr_to_int_narrow_ub.c` | `Undefined {ub: "UB024_out_of_range_pointer_to_integer_conversion", stderr: "", loc: "<7:11--7:17>"}` | `… loc: "other_location(Concrete)"` | **BUG-FIX** (§1.3) | `CerbMem.lean:2297` `memFail (MerrIntFromPtr)` → `memFail MerrIntFromPtr loc` (mirror `impl_mem.ml:2459` `fail ~loc`). **S** |
| Z-03 (O1) | noodle §0 O1; this charter's probe P-C3 | `loc: "<6:10--6:12>"` (`Cerb_location.simple_location`) | `loc: ".zd-scratch/probes/pnvi.c:6:10-12"` (`CerbLocation.stringFromLocation`) | **BUG-FIX** — the `loc` field is behaviour (§1.3); its RENDERING must agree byte-wise or no lane can compare it. Cheaper and doctrinally right to mirror the printer than to normalise in every harness | `CerbLocation.lean` batch renderer mirrors `simple_location` (`util/cerb_location.ml`), cite. **S** (prerequisite of §4.1) |
| Z-04 (D3) | noodle §3 D3; `Main.lean:389-391`; `tests/libxml2/uri_baseline.txt` | `Error {msg: "ill-formed program: \`calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}` | `Error {msg: "Illformed_program: calling an unknown procedure: Symbol(968, SD_Id("memset"))"}` | **EXC(a)** — both `Error`, text differs; declared in-code (`driverErrorBatchMsg` "DELIBERATE divergence, documented"). The embedded symbol id is tray 17 (oracle-side defect, mirrored) | none required; optional mirror of `pp_errors.ml:501` if the Pp machinery is ever ported |
| Z-73 (R1 F2a) | `Main.lean:349` (declared-deviation list) + `:900-902` | `runND` returning ZERO executions: the oracle prints nothing and exits 0 | `Error {msg: "cerberus-lean: runND returned no executions"}`, exit 1 ("we refuse to look like success") | **RULING PENDING (Q8)** — a deliberate failure-vs-success CLASS difference, which (a) does not cover; either keep the fail-closed refusal and DECLARE it as a class-(c)-style loud boundary, or mirror the oracle's silent success. Interaction: the fuel arc's `runNDFuel` exhaustion leaf yields exactly this shape (fuel design §3.1 "runner, today"), so Q8's answer decides that row's post-fuel classification too | none until ruled; **S** either way |
| Z-74 (R1 F2b) | `Main.lean:347` | non-UB front-end failures: diagnostic on STDERR only, exit non-zero | `Error {msg: …}` line on STDOUT, exit non-zero | **EXC(a)** — channel/text differ; Z1 must SHOW (not assume) the exit class is identical on the reject corpora (`tests/bytes` NEG leg, the `.error.c` rows) | none; Z1 evidence row |
| Z-05 (D4) | noodle §4 D4; `seam/seam_copy_alloc_id.c` | `Defined {value: "Specified(2)", …}` (upstream identical) | `Defined {value: "Specified(1)", …}` — `copyAllocId` returns the pointer unchanged | **BUG-FIX** (value-level; the RefinedC builtin `builtins.lem:470`) | `CerbMem.lean:2547` mirror `impl_mem.ml:2766-2770` (intfromptr range check, then `ptrfromint ival`), incl. the UB024 failure path. **S** |
| Z-06 (D5) | noodle §4 D5; `seam/seam_device_range_load.c` | `Defined {value: "Specified(3)", …}` — `device_ranges = [(0x40000000,0x40000004);(0xABC,0xAC0)]` (`impl_mem.ml:620-624`), `Prov_device` via `ptrfromint` (`:2164-2167`), load/store accept `is_within_device` (`:1611-1617`, `:1718-1724`) | `Undefined {ub: "UB043_indirection_invalid_value", …}` — no device arm; comments at `CerbMem.lean:1940-1942/1985-1988/2048-2050` assert "the device_ranges list is empty in this pipeline" (false) | **BUG-FIX** — the oracle's behaviour is mirrored, however odd; if judged an upstream artefact it is ALSO a tray question, never a silent Lean deviation | `CerbMem.lean:2275-2283` + load/store/kill device arms; delete the false comments. **S** |
| Z-07 (D6) | noodle §4 D6; `seam/seam_free_no_provenance.c`, `seam_free_device_pointer.c` | `Error {msg: "MerrOther "attempted to kill with a pointer lacking a provenance""}`; device pointer → `Defined {value: "Specified(3)"}` (`impl_mem.ml:1470-1476`) | both → `Undefined {ub: "UB179a_non_matching_allocation_free", …, loc: "unknown location"}` (`CerbMem.lean:1904`, catch-all `:1920`) | **BUG-FIX** (verdict class: Error vs UB; Defined vs UB) | mirror the three arms (function ptr → MerrOther; `Prov_none` concrete → MerrOther "…lacking a provenance"; `Prov_device` → return). **S** (the `loc` is Z-01) |
| Z-72 (R1 F1) | probe (this charter, R1): `fprintf(stderr,"E1"); int *p = 0; return *p;` libc mode | `Undefined {ub: "UB043_indirection_invalid_value", stderr: "E1", loc: "<2:62--2:64>"}` — the killed state's accumulated stderr (`driver_ocaml.ml:176-178` `String.concat "" (Dlist.toList dr_st.…io.stderr)` → printer `:123`) | `Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: ".zd-scratch/p/se1.c:2:62-64"}` — `Main.lean:917` prints `stderr: \"\"` LITERALLY on every Undefined line. Control `fprintf(stderr,"E2"); return 3;` agrees on both (`Defined {value: "Specified(3)", stdout: "", stderr: "E2", blocked: "false"}`) | **BUG-FIX** (stderr bytes are part of the verdict; invisible today only because every extractor keeps `ub:` alone) | `Main.lean:917` (and the `Error0`/empty-UB arms, `driver_ocaml.ml:173-181`): render the killed state's stderr. **S**, Z1, MUST land with Z-01/02/03 — it trips the moment whole lines are compared |
| Z-76 (R2) | dynamic-addrs record §6; `tests/noodle-probes/dynamic-addrs/{da_offset.c,da_align16.c,core_maxalign.core,inj_maxalign.c}` | Core constant `IvMaxAlignment` evaluates to `DefaultImpl.max_alignment` = 8 (`core_parser.mly:1536-1537` `integer_ival (… (get ()).max_alignment)`; `ocaml_implementation.ml:151-152`); `core_maxalign.core` → fork AND upstream `Defined {value: "Specified(8)", …}`; `da_offset.c` `Specified(8)`; `da_align16.c` `Specified(2)` | `CoreParser.lean:1281-1282` HARDCODES `CerbMem.integerIval 16` — while `CerberusImpl.lean:20` itself declares `max_alignment : Nat := 8`; `inj_maxalign.c` (injection) `Specified(16)`; `da_offset.c` `Specified(16)`; `da_align16.c` `Specified(3)`. Every Lean `malloc`/`realloc` (std.core `alloc(IvMaxAlignment, …)`) is 16-aligned vs 8 on the oracle | **BUG-FIX** (value-level; unseen because no corpus observes heap addresses mod 16; gcc's 16 agrees with the WRONG side — the gcc lane referees ISO values, not layout) | `CoreParser.lean:1282` → `CerbMem.integerIval CerberusImpl.max_alignment`. **S**, Z1. Lesson for Z2: this is a hand-written seam (CoreParser) — the seam-by-seam pass should have caught a literal where the OCaml reads the implementation record; cite as motivation for Z2's CoreParser-vs-`core_parser.mly` pass (every `IV*`/impl-constant production checked against its OCaml evaluation) |
| Z-08 (D7) | noodle §4 D7; `seam/seam_free_interior_pointer.c` | `Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<2:39--2:50>"}` — `is_dynamic addr` FIRST (`impl_mem.ml:1515-1549`) | `Error {msg: "MerrUndefinedFree Free_out_of_bound"}` — dead → lookup → `addr != base` → dynamic, and tests `alloc.base` where OCaml tests the pointer's `addr` | **BUG-FIX** (verdict class) | `CerbMem.lean:1905-1914` reorder to the OCaml check sequence; test `addr`. **S** |

### 2.2 The CerbMem seam read — the undeclared divergences, each disposed

Source: noodle §4 "Seam candidates NOT observable from C today". The
brief counted them as "11"; the record's bullet list expands to 15
individually disposable items (derived; the brief's 11 is not
reconciled to any sub-count in the record — recorded, not important).
None may stay "unobservable": under §1.1 an undeclared divergence in
the Lean text is either mirrored or declared in-code with the
reachability argument, and the seam audit (§3) verifies which.

| id | cite (Lean vs OCaml) | oracle | Lean | class | fix + price |
|---|---|---|---|---|---|
| Z-09 | `CerbMem.lean:2282` vs `impl_mem.ml:2163-2173` | `ptrfromint` maps `n = 0` to `PVnull` only when no provenance is carried (per the OCaml arm structure) | `if n == 0 then PVnull` regardless of `prov` | **BUG-FIX** — unobservable today ONLY because P2 (Z-40) strips provenance on every arithmetic path; the moment upstream fixes P2 and Lean mirrors it, this becomes value-visible. Fix now, before it can bite | mirror the arm. **S** |
| Z-10 (R2) | `CerbMem.lean:1906-1909` vs `impl_mem.ml:1527-1534` (`:1532` `failwith "Concrete: FREE was called on a dead allocation"`) | dead-allocation arm: `failwith` (uncaught exception, exit 125) for a NON-dynamic kill of a dead allocation — witnessed: `core_bug_then_kill.core` on both oracles (dynamic-addrs row k) | `UB179b_dead_allocation_free` regardless of `isDynamic` — witnessed: `inj_bug.c` + `inject_rand.core` → `Undefined {ub: "UB179b_dead_allocation_free", stderr: "", loc: "tests/noodle-probes/dynamic-addrs/inj_bug.c:10:3-12"}` (row n') | **BUG-FIX** — a one-sided oracle crash; under Q4's recommendation Lean mirrors it as a fail-stop with the OCaml text (a failure-class difference, not (a)). Reachability: only after an ACCEPTED wrong `free` — i.e. only through the tray-19 `dynamic_addrs` defect (Z-77) or the fork-only `cerb::with_address` — say so in-code. The kill-check ORDER difference the same investigation recorded is Z-07/Z-08 (noodle D6/D7), not a new row | mirror as a fail-stop (`panic!` with the OCaml text). **S** |
| Z-11 | `CerbMem.lean:1909` vs `impl_mem.ml:669-675` (`get_allocation`) | missing allocation → UB009 (via `get_allocation`) | UB179a | **BUG-FIX** (UB code) | mirror. **S** |
| Z-12 | `CerbMem.lean:1901-1903` vs `impl_mem.ml:1465-1469` | non-dynamic kill of NULL succeeds | fails (UB179a) | **BUG-FIX** (verdict class) | mirror. **S** |
| Z-13 (R1) | `CerbMem.lean:1849-1850`, `:1877-1878` vs `impl_mem.ml:1290`, `:1247-1258` | no clamp: size/align 0 flow through; negative sizes are the OCaml's own arithmetic | TWO distinct silent normalisations: `allocateObject` clamps BOTH size and align with `.max 1` (`:1849-1850`); `allocateRegion` clamps only align (`:1877`) and `size := sizeN.toNat` (`:1878`) silently maps a NEGATIVE size to 0 | **BUG-FIX** — unreachable today (`int a[0]` rejected by the shared front end, probe S8) but a silent normalisation with no cite; mirror or declare with the reachability argument in-code | mirror (delete the clamps, keep the OCaml arithmetic). **S** |
| Z-14 | `CerbMem.lean:1845` vs `impl_mem.ml:1291-1297` | `req_addr_opt = Some _` → `failwith` | argument ignored | **BUG-FIX** (silent absorption of a fail-stop) | mirror the fail-stop. **S** |
| Z-15 | `CerbMem.lean:1884` vs `impl_mem.ml:1428-1429` | `allocate_region` records `PrefMalloc` unconditionally | stores the caller's `pref` | **BUG-FIX** — the prefix is printed by the mirrored `pp_prefix` (`CerbPP.stringFromSymbol_prefix`) on pointer-value renderings; observable wherever a malloc'd pointer value is printed with its prefix | mirror. **S** |
| Z-16 | `CerbMem.lean:591-602/504-510` vs `impl_mem.ml:1096-1113` | `bytes_of_int` asserts on out-of-range | wraps silently | **BUG-FIX** (silent absorption of a fail-stop); unreachable today (`conv_int` precedes every store) — mirror the assert anyway | mirror. **S** |
| Z-17 | `CerbMem.lean:2303-2304` vs `impl_mem.ml:2244-2356` | `eff_array_shift_ptrval`: null → UB046; GNU void-element arm; union-member tag dropped | delegates to the pure shift: null → `panic!` (`:1506-1507`); void case differs; tag kept | **BUG-FIX** — reachable only under strict/PNVI/CHERI (`translation.lem:2112-2119`), all of which Lean will REFUSE (Z-24/25); still a panic where the oracle gives UB046 — mirror rather than carry a dead panic | port `eff_array_shift_ptrval`. **S** |
| Z-18 | `CerbMem.lean:951` vs `impl_mem.ml:986-994` | `reconstruct` on zero-sized-element arrays takes the OCaml path | short-circuits | **BUG-FIX** (mirror or declare; unreachable with the front end's zero-size rejection) | mirror. **S** |
| Z-19 | `CerbMem.lean:931` vs `impl_mem.ml:1056-1057` | unspecified pointer value's ctype drops pointee qualifiers | keeps them | **BUG-FIX** — `Unspecified('<ctype>')` is a VERDICT VALUE (batch prints it); a qualifier in the ctype text is a visible value difference on any unspecified-pointer read | mirror. **S** |
| Z-20 | `CerbMem.lean:2402-2403` vs `impl_mem.ml:2683` | `realloc` `get_allocation` failure carries `other "Concrete.realloc"` loc | passes no loc (its own comment quotes the OCaml loc) | **BUG-FIX** (§1.3 — loc is behaviour) | pass the loc. **S** |
| Z-21 | `CerbMem.lean:2225-2228` vs `impl_mem.ml:2067-2070` | one `MerrOther` message | two messages + a `FunctionNoParams` arm | **EXC(a)** — same failure class (`Error`), text differs. Mirror anyway in Z2 (trivial) so the census row retires | mirror. **S** |
| Z-22 | `CerbMem.lean:1759-1764`, `:2548` vs `impl_mem.ml:2175-2191` | CHERI intrinsics: `assert false` | return values | **BUG-FIX** — a value where the oracle fail-stops (silent absorption); unreachable once CHERI is refused (Z-24) but a dead fail-open path is still the banned shape | mirror as fail-stop. **S** |
| Z-23 | `CerbMem.lean:2425, 563, 2175, 2389, 2344, 2311` (stale cites → `impl_mem.ml:1704-1710/1776-1787, 1202, 1954-2063, 2679, 2664-2666, 2635-2645`) | — | — | **INSTRUMENT** (doc integrity; no execution content) | re-cite in Z2. **S** |

### 2.3 VALIDATION.md's declared boundaries, re-classified

| id | boundary | oracle | Lean (today, verified) | class | fix + price |
|---|---|---|---|---|---|
| Z-24 | **PVI vs PNVI** (VALIDATION.md §5 does not name it; `CerbGlobal.lean:is_PNVI_impl := false`, `has_strict_pointer_arith_impl := false`, `switchesRef` permanently `[]` — no setter exists) | `--switches=PNVI` CHANGES the answer: probe P-C1 default `Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<6:10--6:12>"}`; P-C2 with `--switches=PNVI` `Defined {value: "Specified(20)", stdout: "", stderr: "", blocked: "false"}` | matched (default) mode agrees: P-C3 `Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: ".zd-scratch/probes/pnvi.c:6:10-12"}`. The FLAG is not refused: `Main.lean:1024-1027` treats any unknown token as a file name → P-A1 `uncaught exception: no such file or directory (error code: 4294967294)` / `file: --switches=PNVI`, rc 1 | **BUG-FIX → then EXC(c)**. Loud but NOT feature-attributed (§1.2(c)); a harness that ever passed a switch would get a misleading error, and a MISORDERED legitimate flag is a file name (`Main.lean:980-982` admits it; R1 probe, verbatim: `cerberus-lean --batch at.json --first` → `uncaught exception: no such file or directory (error code: 4294967294)` / `file: --first`, rc 1). Under the rule a fail-open CLI is a defect; the refusal must also reject KNOWN flags out of canonical position | `Main.lean` arg loop: any `--`-prefixed token not in the accepted set → `cerberus-lean: refused — <flag>: semantics switches / concurrency / <x> are not supported by this port (VALIDATION.md §<census>)`, exit 2. Plant: the P-A probes. **S** (plumbing the switches for real is M and NOT proposed — mode parity is the harness contract) |
| Z-25 | **Concurrency stubs** (VALIDATION.md §5 "temporal, the cmm instantiation is the mover"; `CerbConcurrency.lean` `statically_satisfied := true`; `CerbGlobal.using_concurrency := false`; TODO.md "Concurrency (cmm) instantiation") | `--concurrency` on ANY program: probe P-B3 `internal error: CONCURRENCY IS BROKEN` … `Failure("internal error: CONCURRENCY IS BROKEN")` (raised from `nondeterminism.ml:64` via `smt2.ml:38`) — the oracle has no working concurrency mode; the shared `.lem` hard-codes `perform_action_request2 false (*TODO!!! with_concurrency*)` (`driver.lem:980`). Matched (default) mode: atomics run sequentially and AGREE (noodle `elab/elab_atomic_qualifier_seq.c` "AGREE 3-way 8"; R1 probe `_Atomic int a = 5; a += 2; a++; return a;` — oracle `Defined {value: "Specified(8)", stdout: "", stderr: "", blocked: "false"}`, Lean identical, gcc exit 8; the earlier `atomic_fetch_add`-under-`--nolibc` probe was vacuous (both-reject on an undeclared identifier) and is withdrawn) | a program reaching the stubs in matched mode computes what the oracle computes (`Global.using_concurrency ()` gates only the `core_run_aux.lem:342/411/429/494` bookkeeping, false on both sides). The FLAG is not refused: P-A2 `uncaught exception: no such file or directory` / `file: --concurrency` | **EXC(c) once Z-24's refusal lands** — no silent computation exists: with the flag the oracle itself fail-stops, without it both engines agree. The stub is therefore NOT a BUG row; the refusal quality is (Z-24). VALIDATION.md must say "concurrency: not supported; the oracle's own mode is non-functional at `b9aeedcb4`". Whether the cmm instantiation mover becomes OPTIONAL is a PRODUCT-SCOPE change → operator ASK, §7 Q9 (R1) | rides Z-24. **S** |
| Z-26 | **CerbFS — refused set** (trust-basket §2/§7; `CerbFS.lean` header) | SibylFS answers | five refusal sites, all `panic!` with a named reason, e.g. `CerbFS.lean:221`: `PANIC at CerbFS.fs_read CerbFS:221:8: CerbFS refusal (fail-closed fs-model boundary): read on fd 4 at offset 5 of 12-byte file …` (verbatim in `tests/ci_sweep/results/tcc.tsv` for `tests/tcc/40_stdio.c`); `fs_open :166` (write/truncate intent), `fs_write :200`, `fs_pwrite :241`, `fs_pread :260` | **EXC(c) — VERIFIED loud and feature-attributed** on every refused path (5/5 sites carry "CerbFS refusal (fail-closed fs-model boundary)" + the operation + the header/mover cite; harnesses run `LEAN_ABORT_ON_PANIC=1`) | none for the refused set; whether the real-fs mover (TODO.md, priced M) becomes OPTIONAL is a PRODUCT-SCOPE change → operator ASK, §7 Q10 (R1) |
| Z-27 | **CerbFS — served-but-divergent residuals** (header "KNOWN-DIVERGENT AND STILL SERVED"; `fs_open :148-151` missing file created without `O_CREAT`; `O_EXCL` ignored; `fs_stat :3xx` zeroed fields except size; plus, un-named in the header: `fs_mkdir/fs_chmod/fs_chdir/fs_chown/fs_rmdir` return success as no-ops, `fs_link/fs_readlink/fs_symlink` return `ENOSYS` which `driver.lem store_error` turns into errno + −1 for the C program to absorb) | POSIX/SibylFS answers: ENOENT, EEXIST, real stat fields, real directory state | silently served different answers. Witnesses: `tests/suite/fs/stat.c` STDOUT_DIFF (`Lean=… stdout: "0 0 420 1 0 0 0 10\n"` vs the oracle's SibylFS values); `tests/freebsd/cat.c` LEAN_FAIL `msg: "assert() failure"` (oracle `Specified(1)`) | **BUG-FIX** — exactly the silent absorption (c) forbids ("a different answer or a silent absorption never is"). Every op the model cannot answer as SibylFS does must REFUSE like the five refused sites. R1 F9 completes the residual list: `fs_opendir` (`:335` always a fresh fd, no directory check), `fs_readdir` (`:339` always empty), `fs_rewinddir`/`fs_closedir`, `fs_truncate`/`fs_unlink`/`fs_rename` on the in-memory table (no fd/offset interaction), `fs_lseek` past EOF (accepted, later read refuses or serves EOF), `fs_lstat` = `fs_stat` | `CerbFS.lean`: the Z1 deliverable is an OP-BY-OP served/refused table for all 24 `fs_*` entry points (each op: SibylFS behaviour → Lean behaviour → SERVED-correct / REFUSED-loud, nothing else), committed into the header and this census; refuse missing-file open without `O_CREAT`, any `O_EXCL`, `stat`/`lstat`, the directory ops, the `ENOSYS` trio and every table op the model cannot answer as SibylFS does — or implement them (M). **S** for the refusals; the served-pattern probe family (TODO.md item (i)) pins the served set |
| Z-28 | **libc-mode allocation-address ordering** (detective RC-2; 6 `tests/pnvi_testsuite` STDOUT_DIFF rows in `tests/ci_sweep/results/pnvi.tsv`: `pointer_from_integer_2g.c`, `provenance_equality_auto_yx.c`, `…global_fn_yx.c`, `…global_yx.c`, `…uintptr_t_global_yx.c`, `provenance_lost_escape_1.c`) | `g1=(@54, 0xfffffffff1d8)` — program globals interleaved among the libc TUs' globals | `g1=(@69, 0xffffffffede4)` — all libc TU globals first, program globals after; locals identical; nolibc layout byte-identical | **BUG-FIX** (stdout bytes differ; addresses are values under PVI — `(long)&g` is a `Defined` value) | `Main.lean` multi-TU link: mirror the oracle's TU/global ordering (`pipeline.ml` link order); the comparison harness gives the exact oracle trace. **S-M** (= Z3) |
| Z-29 | **~8 M-element zero-init static hang** (VALIDATION.md §5 "Known, LOUD limits"; mem-scale record §S1'; `tests/mem-scale-probes/probes/a_zero_global_10000000.c`) | completes (10 M: ~76–246 s, 7.7 GB) | HANG (exit 124, CPU/wall < 0.1) — Lean-runtime `lean_apply_*` frames in the Ail typing monad's run loop + the runtime's overflow-handler deadlock (tray lean4/01) | **EXC(b) VIOLATION = BUG** — (b) says "Lean must not fail where the oracle succeeds"; loudness (HANG class, S0) is necessary, not sufficient. A named mover is mandatory: the lem-backend run-loop rendering (mem-scale record §S1' options; TODO.md), tail-position rendering of function-typed monads so the runtime does not stack a frame per element | lem-arc (lem-lean `mdd/lean-backend`), **L**; cross-ref TODO.md + tray 18 (upstream `.lem` shape) + tray lean4/01 |
| Z-30 | **byte-list memory representation OOM** (detective RC-3; `tests/suite/parsing/array.c` `LEAN_CRASH exit 134: INTERNAL PANIC: out of memory`; `pr20621-1.c` LEAN_TIMEOUT = OOM-in-disguise; noodle R1 `mem/mem_malloc_4gb_lazy.c` and `mem_calloc_overflow.c` OOM-KILLED at 6G ON THE POST-MEM-SCALE BINARY) | answers immediately (lazy allocation) | OOM-KILLED / out-of-memory panic | **EXC(b) VIOLATION = BUG** with a named mover: the mem-scale arc's C1+C3 landed (record §S1) and the residual is measured by R1 on `72164481a`; the mover is the representation change (chunked/sparse bytes with a compact unspecified-region form — detective RC-3 fix direction; profile first) | `CerbMem.lean` byte path. **M**; the sweep rows re-measure in Z4's instrument re-run |
| Z-31 | **exhaustive-mode wall-clock margins** (detective RC-4: `pr63209.c`, `pr69320-4.c` AGREE at 60–90 s; csmith baseline 8 `TIMEOUT` rows `sa_197/419/435, sia_072/161/169/976/996`; gcc lane 11 `SKIP_LEAN_TIMEOUT`; noodle `ptr_struct_assign.c` unsequenced form 67,650 traces oracle ~100 s / Lean > 60 s; `lib_strtol_edges.c` both-timeout) | completes within the lane bound | ~15–20× slower on recursion-heavy shapes; same verdicts when the bound is raised | **EXC(b) — tolerated ONLY PER ROW with measured completion at a larger bound** (R1 Q5): `pr63209.c`/`pr69320-4.c` have it (detective RC-4, AGREE at 60–90 s); the 8 csmith `TIMEOUT` rows and the 11 gcc-lane `SKIP_LEAN_TIMEOUT` rows do NOT — until each is shown to complete and agree at a larger bound it is a (b)-VIOLATION pending evidence, not a tolerated bound | Z4: one uncapped-timeout measurement per undemonstrated row (verdict equality, recorded per row); perf itself is "profile before optimizing", L |
| Z-32 | **fuel exhaustion** (`sia_csmith_477.c`, `sia_csmith_769.c` `LEAN_CRASH` = `lem: fuel exhausted`; gcc lane `SKIP_LEAN_CRASH` same two; VALIDATION.md `lemDefaultFuel` = 10^6) | completes | exit 134 `lem: fuel exhausted` today; after the fuel arc a typed `Error {msg: "lem: fuel exhausted"}` / FUEL class | **EXC(b)/fuel** — accepted verbatim: "fuel is a reasonable exception because we could always just run the semantics with more fuel" | none; the fuel arc's harness FUEL class (fuel design §3) makes the rows self-describing |

### 2.4 Lane baselines, sweeps and pins — every row whose class means "Lean differs"

Enumerated from the baseline files at `72164481a`. The exec baselines
(`exec_baseline`, `exec_ci_baseline`, `exec_coverage_baseline`,
`exec_debug_baseline`, `exec_float_baseline`) contain **no** MISMATCH/
DIFF/UB_DIFF rows — every non-MATCH row is `CERB_SKIP` (oracle-side;
Lean not reached). `tests/libc_exec/baseline.txt` 7/7 MATCH;
`tests/cn_coverage/baseline.txt` 207 MATCH + 6 UB_MATCH; `test_multi_tu`
and `test_verify` have no recorded non-agreement. The rows that remain:

| id | cite | oracle | Lean | class | fix + price |
|---|---|---|---|---|---|
| Z-33 | `tests/immaculate/baseline.txt` `g5-decode-question ORACLE_CRASH \| L=VAL:Specified(63)` (`'\?'`) | uncaught `Failure` from `decode_character_constant_aux` (tray 10) | `Specified(63)`; gcc lane `AGREE gcc=63 lean={63}` | **REG-CAND R1** (§2.6) — under §1.1 alone this is Lean ≠ oracle (verdict vs failure) → BUG-FIX mirror; the register is the only home for keeping it | operator rules (§7 Q2); if refused: mirror the crash (fail-stop with the OCaml text), keep the pin as `MATCH \| L=CRASH`, tray 10 stays. **S** either way |
| Z-34 | `g5-escape-roundtrip DIFF \| L=VAL:Specified(127)` (`%c` of 127) | 87 (decimal `Char.escaped` read back as octal; tray 11) | 127; gcc 127 | **REG-CAND R2** (§2.6) | as Z-33: rule, else mirror the corruption (mirror `escaped_char`/decoder round-trip; **S**) |
| Z-35 | `s4b-memcmp-hugesize ORACLE_CRASH \| L=UB:UB_CERB002a_out_of_bound_load` | uncaught `Z.Overflow` at `impl_mem.ml:2660` `Z.to_int` (tray 13) | the UB verdict the oracle's own checked per-byte load produces | **REG-CAND R3** (§2.6) — criterion (ii) is not satisfiable as written (the program is UB, native has no answer); §7 Q3 proposes (ii') | rule; else mirror the `Z.to_int` crash as a fail-stop (**S**) — which deletes a correct UB verdict, hence the ask |
| Z-36 | noodle E2 `ptr/ptr_string_literals.c` (`"\?"` in a STRING literal) | exit 125 `Failure("decode_character_constant, started like an octal constant, but failed: ?")` (`translation.ml:3032`) | `98 65 66 4 83 52 3 10 9 92 34 39 63 0 4` = gcc byte-for-byte | **REG-CAND R1** (same decoder as Z-33; one register entry covers both) + tray 10 addendum; pin as immaculate `ORACLE_CRASH` pair | as Z-33 |
| Z-37 | immaculate `MATCH \| L=CRASH` rows: `g2-memcmp-uninit`, `g4-bswap64-overflow` (tray 12), `g5-decode-multichar`, `offsetof-union-member` (`PANIC at CerbMem.sizeofCtype_lemFuel CerbMem:415:15: CerbMem.sizeofCtype: Union tag not a UnionDef`); gcc lane `SKIP_LEAN_CRASH` for the same + `tests/minimal/097-null-ptr-arith.undef.c` (tray 04) and `csmith/sa_csmith_002/003/005` ("translation failwithI; `CERB_SKIP` upstream-baseline class") | uncaught exception / `failwith` | `panic!` with the mirrored text | **EXC(a)** — identical failure class, text differs. Z2 verifies each pair is a genuine both-crash (the offsetof-union-member oracle side must be shown to fail too, not merely `CERB_SKIP` for another reason) | none; Z2 evidence row |
| Z-38 | gcc lane `SKIP_LEAN_FAIL` rows: `073-exit.libc.c`, `074-abort.libc.c`, `tests/debug/libc-01/02`, `valid-04-exit-before-oob.c`, `ub-static-reject.c`, `csmith/smx_csmith_6.c`, immaculate `g1-ge-funptr`/`g1-lt-null` (`L=ERR:Memory WIP: …`) | `CERB_SKIP` / reject / `Memory WIP` error in the same mode | reject / error | **EXC(a) — CLAIMED, not measured** (R1 F10): the claim rests on two lanes' skip bookkeeping (`CERB_SKIP` in exec + `SKIP_LEAN_FAIL` in gcc), which is not a witnessed both-fail on the same input in the same mode. Z2 imposes Z-37's verification: run each pair, quote both failure lines | Z2 evidence row |
| Z-39 | `tests/libxml2/uri_baseline.txt` `OCAML_NOLIBC` vs `LEAN_NOLIBC` | `Error {msg: "ill-formed program: \`calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}` exit 1 | `Error {msg: "Illformed_program: calling an unknown procedure: Symbol(968, SD_Id("memset"))"}` exit 1 | **EXC(a)** (= Z-04) + tray 17 (the embedded id) | none |
| Z-40 | `test_elab.sh` 3 recorded DIFF rows (`SUMMARY: total=106 same=103 diff=3`; named by this charter's run): `073-exit.libc`, `074-abort.libc` (+42 `procdecl` lines on the Lean side: `abort`, `abs`, `aligned_alloc`, `atexit`, …), `098-cross-alloc-ptrdiff.undef` (`+tagdef struct __cerbty_unnamed_tag_0 members=__dummy_max_align_t`) | `--pp core` prints only MAIN-file-located declarations (`pp_core.ml pp_cond`) | `--pp-core` prints header-located libc declarations / `max_align_t` too | **INSTRUMENT** — a pretty-printer FILTER difference at signature level, no execution content (the same program's exec rows MATCH/CERB_SKIP). Worth fixing so `DIFF` in this lane means something: apply the main-file filter on the Lean side (mirror `pp_cond`) | `Main.lean ppCoreSignature`. **S** (Z4) |
| Z-41 | `scripts/gcc_oracle_triage.txt` 9 `TRIAGED_ADDR` rows (`tests/debug/align-01…04`, `intfromptr-05/07/08/09/10`) | (oracle == Lean; nolibc layout byte-identical — detective RC-2) | — | **OUT-OF-SCOPE** — these compare Cerberus's abstract allocator against gcc's NATIVE layout; both conforming; not Lean-vs-oracle. Stay triaged by-file | none |
| Z-42 | `tests/ci_sweep/results/*.tsv` rows already covered: `suite/fs/stat.c` STDOUT_DIFF and `freebsd/cat.c` LEAN_FAIL (→ Z-27), `tcc/40_stdio.c` LEAN_CRASH refusal (→ Z-26, correct), `suite/parsing/array.c` + `pr20621-1.c` (→ Z-30), 6 pnvi STDOUT_DIFF (→ Z-28), `pr63209.c`/`pr69320-4.c` (→ Z-31), `pr44468.c` LEAN_CRASH (STALE — fixed `ba24da12e`; the committed TSVs predate it) | | | **INSTRUMENT** — the committed sweep TSVs are a 2026-08-22 snapshot; TODO.md registers the pending re-record | Z4 re-run after Z1–Z3 (measurement sweep; tripwire-justified in advance) |
| Z-75 (R1 F7) | `tests/ci_sweep/results/{ci,cheri_smoke,suite,torture_not_std_compliant}.tsv`: 43 `CERB_INCONSISTENT` rows (derived count; "exec succeeded but `--cabs-json` failed") | exec verdict OK | Lean never reached at recording time. STALE like `pr44468.c`: trust-basket item (c) made `--cabs-json` parse-only; R1 probe `tests/ci/0069-const_expr.c` → `--cabs-json` rc 0 and Lean `Undefined {ub: "UB084", …}` = oracle `Undefined {ub: "UB084", stderr: "", loc: "<5:5--5:6>"}` (trust-basket §3 (ii) recorded 43/43 AGREE) | **INSTRUMENT (stale)** with a RULE for the re-record: any row that SURVIVES the Z4 re-record as `CERB_INCONSISTENT` is a class-(c) BRIDGE-ATTRIBUTION question (Z-70: is the refusal loud and attributed to the bridge?), never INSTRUMENT by default | Z4 re-record |

### 2.5 ORACLE-SUSPECTs — Lean == oracle ≠ ISO/gcc: mirrored (correct) + tray

Each is correct under §1.1 as it stands. The census records them so
that (a) nobody "fixes" Lean toward ISO outside the register, and (b)
each has a tray draft (§5) and a gcc-lane pinned pair that flips to
AGREE when upstream fixes it (§4.2). Upstream-confirmed = re-verified
on `deps/cerberus-upstream` @ `b9aeedcb4` by the noodler.

| id | finding (noodle id) | oracle == Lean | ISO / gcc | mechanism (oracle-side, file:line) | tray |
|---|---|---|---|---|---|
| Z-43 | U1 `size_t` UAC at 32 bits | `705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705` | gcc `5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001`; 6.3.1.8p1 | `ailTypesAux.lem lt_integer_rank_ISO` `\| _ -> false` for macro types; `translation.lem:1444-1477` | 20 |
| Z-44 | P2 provenance lost through integer arithmetic (PVI) | `UB043_indirection_invalid_value` for `(int*)(u + 4ul)` | gcc 20; the PVI model's own point | `core_eval.lem:57-80` `mk_conv_int`, `:29-46` `mk_wrapI` rebuild `IV (Prov_none, n)` | 21 |
| Z-45 | P1 pointer difference over pointers-to-arrays | `8 3 2 2 4 8` | gcc `2 1 2 2 1 8`; 6.5.6p9 | `impl_mem.ml:1961-1967` strips one `Array` layer; `CerbMem.lean:2184-2187` mirrors WITH cite (delete the strip in the same slice upstream fixes it) | 22 |
| Z-46 | E4 string literals cannot initialise char-array members/elements | constraint violation / `typechecking failed` | gcc 99/98; 6.7.9p14+p20 | initializer typing (desugar/typing) | 23 |
| Z-47 | L3 FILE-buffered stdout dropped at termination / reordered vs the printf proxy | `stdout: ""` for `fputs("out", stdout); return 0;` | gcc `out`; 7.22.4.4p4, 5.1.2.2.3 | `runtime/libc/src/stdio.c` FILE buffer + driver stdout record; no flush on main-return/exit | 24 |
| Z-48 | L4 atexit handlers not run on return from main | `m`, value 4 | gcc `m21`; 5.1.2.2.3, 7.22.4.4p3 | driver main-return path bypasses libc `exit` | 25 |
| Z-49 | L5 `%*d` crashes both engines | `Failure("internal error: TODO: formatted.lem 6")` / `PANIC … TODO: formatted.lem 6` | gcc `[   9]`; 7.21.6.1p5 | `formatted.lem` unimplemented `*` | 26 |
| Z-50 | L6 `%x/%X/%o` with `int` argument → UB153b | `UB153b_illtyped_argument_for_format` | gcc `[ff][FF][10]`; 7.21.6.1p9 + 6.5.2.2p6 | `formatted.lem` type check over-strict | 27 |
| Z-51 | E3 `?:` in a static initialiser rejected | "not a compile-time constant" / `desugaring failed` | gcc 10; 6.6p3/p6/p7 | desugarer's constant evaluator lacks the conditional arm | 28 |
| Z-52 | E5 `"hello" + 1` not an address constant | reject | gcc 101; 6.6p9 | string-literal base in address-constant folding (tray-09-adjacent) | 29 |
| Z-53 | L1 `strncmp(s1, s2, 0)` compares one character | `Specified(2)` | gcc 1; 7.24.4.4p2-3 | `runtime/libc/src/string.c:85-90` | 30 |
| Z-54 | L2 libc `calloc` has no `nmemb*size` overflow check | (masked by Z-43 truncation, then Z-30 OOM on Lean) | C17 7.22.3.2 | `runtime/libc/src/stdlib.c:125-134` | 31 |
| Z-55 | F1 `float` evaluated and stored as double; `sizeof(float) == 8` | `0 100000000 1 16777217 1 0 1 0`; sizeof 8 | gcc `1 100000001 0 16777216 0 0 1 1`; 4; 6.3.1.5, 5.2.4.2.2 | `ocaml_implementation.ml:206-208` `RealFloating Float -> Some 8 (* TODO:hack ==> 4 *)`; `impl_mem.ml:1155`; `CerberusImpl.lean` mirrors. R1 F6: the ISO case is NOT "unambiguous" — 6.2.5p10 permits `float`'s value set to equal `double`'s, and then 6.3.1.5 requires no rounding; the actual defect is INCONSISTENCY with `runtime/libc/include/float.h:4` `FLT_MANT_DIG 24` (5.2.4.2.2). gcc-lane class stays D2 `TRIAGED_FLOAT` (design §2.3), not a shared-source pin | 32 (M upstream; see §7 Q6) |
| Z-56 | O6 `(x & 0) + 3` with indeterminate `x` → UB036 | `UB036_exceptional_condition` | gcc 3 | classification of an unspecified operand of signed `+` | 33 (question) |
| Z-57 | prior tray items already mirrored: 15 `_Bool b = 0.5` → 0; 16 `snprintf` truncation return; 04 null-pointer-arith crash (both crash); 05 `va_arg` type check absent | mirrored | ISO | tray 15/16/04/05 | existing |
| Z-58 | F2 `(int)NaN` crashes both (`Z.Overflow` / `PANIC at CerbFloat.truncToInt`) | both fail | UB017 would be the verdict | tray 15's non-finite class | existing (immaculate crash-pair candidate, §4.2) |
| Z-77 (R2) | `dynamic_addrs` never cleaned: a zero-size `alloc` at a live object's base makes `free` of that object pass the dynamic check (dynamic-addrs record §1/§3) | Core-level, BOTH oracles: `core_bug.core` (`create(16,int); alloc(8,0); free(x)`) → `Defined {value: "Specified(0)", …}`; control `core_control.core` → `Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<5:3--5:14>"}`; Lean faithful mirror via libc injection (`inj_bug_bexit.c` + `inject_rand.core` → `Specified(0)`; control → `UB179a`). NOT reachable from C through `malloc`/`aligned_alloc`/`realloc` (argument temporaries, `translation.lem:4435`; `da_bug.c` → `UB179a` on all three engines) | ISO 7.22.3.3p2; Cerberus's own UB179a | `impl_mem.ml:497/:661-663/:1433` address-keyed `dynamic_addrs`, only writer `allocate_region`, never erased in `kill` (:1464-1550); `CerbMem.lean:135/:1888/:1913-1914` mirror line for line | 19 (drafted on `probe/dynamic-addrs`); disposition MIRROR + tray; register candidate R4 (§2.6) |

(The noodler's record says "ORACLE-SUSPECT … **14**" but enumerates 13
ids — U1, P1, P2, L1–L6, E3–E5, F1; derived discrepancy recorded. The
tray plan of §5 drafts those 13 plus O6 as a question and E2 as a
tray-10 addendum; R2: tray 19 is the dynamic-addrs draft, so the plan's
numbers are 20–33.)

### 2.6 Adjudication of the existing Lean-right/oracle-wrong pins against the class-(d) bar

The immaculate baseline carries three rows whose comments say "Never
fix-to-match" (`tests/immaculate/baseline.txt` header, `test_immaculate.sh:19-25`).
Under §1.1 that instruction is REVOKED unless the pin enters the
register; the "Never fix-to-match" text is itself a legacy permission
and is rewritten in Z1 to cite the register or the mirror. Evidence per
criterion (§1.4), [AGENT] assessment for the operator's per-entry
ruling:

| cand. | pin | (i) unambiguous clause | (ii) second oracle | (iii) tray | (iv) pinned | verdict [AGENT] |
|---|---|---|---|---|---|---|
| **R1** | `g5-decode-question` (+ E2 string-literal form, Z-36) | YES — 6.4.4.4#1 lists `\?` as a simple escape; #4 gives 63; upstream's own lexer accepts it (`c_lexer.mll:417`, tray validation pass) | YES — gcc exit 63 (`AGREE gcc=63 lean={63}`; reviewer's gcc: `"a\?b"` bytes `97 63 98 0`); E2: Lean == gcc byte-for-byte | YES — tray 10 (+ addendum for the string-literal form) | YES — `ORACLE_CRASH \| L=VAL:Specified(63)`; E2 pin to be added | **meets (i)–(iv)**; reviewer: **ADMIT**; the entry must cite the code site `CerbDecode.lean:91` (`\| "\\?" => 63`) and carry the (vii) marker |
| **R2** | `g5-escape-roundtrip` | YES — 7.21.6.1#8 `%c` writes the `int` converted to `unsigned char`; the oracle stores 87 for 127 (decimal-vs-octal re-read, a data-corruption bug, not a reading) | YES — gcc 127 (tray 11 records "gcc (and our Lean port) return 127") | YES — tray 11 | YES — `DIFF \| L=VAL:Specified(127)` | **meets (i)–(iv)**; reviewer: **ADMIT**; the entry names the exact escape round-trip site on the Lean side (the `%c` store path that does NOT re-decode through the octal reader — Z2 locates and marks it per (vii)) |
| **R3** | `s4b-memcmp-hugesize` | PARTIAL — the program is UB (7.24.1p2 pointer validity); the "unambiguous" part is that a TOOL CRASH (`Z.Overflow`) is never a semantics; the oracle's own checked path (`impl_mem.ml` per-byte load) yields `UB_CERB002a` | NOT AS WRITTEN — no native answer exists for a UB program | YES — tray 13 | YES — `ORACLE_CRASH \| L=UB:UB_CERB002a_out_of_bound_load` | **fails (ii) literally**; reviewer: **ADMIT under the TIGHTENED (ii')** of §1.4 — (1) `Z.Overflow` is a host-int conversion raised before the semantic path (`impl_mem.ml:2660` `Z.to_int`), (2) `CerbMem` memcmp is the line-mirror minus that conversion, (3) the second oracle is a scratch oracle build with tray 13's Z-native remedy shown to give `UB_CERB002a`. Z4 produces (3); until then the pin stays as recorded |

| **R4** (R2) | `dynamic_addrs` (Z-77, tray 19): Lean `killM` would key the dynamic check on allocation IDENTITY instead of `dynamicAddrs.contains base` | YES — 7.22.3.3p2; Cerberus's own UB179a names the case | PARTLY — glibc rejects `free(&x)` (rows a/b: SIGSEGV/abort) but only on the C shape, which Cerberus already rejects; no native oracle runs the Core shape; (ii') (3) would need a scratch oracle build with the tray-19 id-keyed remedy | drafted (19), not filed | NOT POSSIBLE with today's lanes — no single input reproduces the defect on both engines (Core-only; C blocked by temporaries); the oracle side needs a `.core` runner, the Lean side injection | **FOR admission**: the semantics ACCEPTS a UB program (the class a verifier consumer cares about most); the id-keyed fix is small and verdict-preserving on non-colliding programs; the consumer works at Core level where the shape IS reachable. **AGAINST**: (iv) is unmeetable today (an unpinned deviation is exactly the trust gap the bar excludes); C exposure nil (UB179a on all engines); refined-cerberus's logic is sound regardless (its `free` precondition implies the engine's check); mirror doctrine prefers upstream-first; the fix sits next to Z-07/Z-08's check-order alignment. [AGENT] recommendation: **DEFER** — file tray 19, keep mirroring, revisit if upstream declines/stalls AND a Core-level differential lane exists (see §4.2 instrument gap) |

Everything else on the immaculate baseline is `MATCH` (incl. the
both-crash rows, Z-37) or the in-Lean `TRIPWIRE`/`KILL` probes (no
oracle side). No pin encodes a Lean deviation toward ISO other than
R1–R3; R4 is a candidate with no pin (by construction, today).

### 2.7 Other hand-written seams — rows visible from the headers (the §3 audit produces the rest)

| id | seam | divergence as declared today | class | disposition |
|---|---|---|---|---|
| Z-59 (R1 F3 — evidence corrected, conclusion survives) | `CerbND.lean` header + `:127` ("same no-pruning divergence as NDguard" for `NDbranch`) vs `smt2.ml` `runND` applying `with_constraints`/`check_sat` (`impl_mem.ml:321-361` `cs_module`) | The first draft's evidence was WRONG: `nd_guard` (`nondeterminism.lem:222-223`) produces `kill`, not `NDguard`. `NDguard` is produced by `addConstraints` (`nondeterminism.lem:234-237`, `:499-502`), which IS called in the exec cone: `driver.lem:148` (the `PEconstrained` arm of `print_eval_conv_aux`) and `defacto_memory.lem:513/517` (defacto model, not linked). `PEconstrained` arises only when `Mem.eq_ival`/`lt_ival`/`le_ival` return `Nothing` (`core_eval.lem:352-378`), and the Concrete model ALWAYS returns `Some` (`impl_mem.ml:2556-2562`) — so `NDguard` is unreachable by that argument, not by "no caller". `NDbranch`: produced at `nondeterminism.lem:422` (`msum`, `NDbranch empty …`) with EMPTY constraints (`:465` variant commented out) → `with_constraints` on the oracle side is trivially SAT → exploring both sides is exactly what the oracle does. Noodle: trace COUNTS agree on every completing probe (8/8, 2/2, 40/40, 140/140, 280/280, 67650/67650) | Z2-DISPOSED: DECLARE with the corrected argument in-code, plus the TRIPWIRE stated as a mirror check — "`CerbMem.eqIval`/`ltIval`/`leIval` (`CerbMem.lean:1434-1439`) are total `some`, mirroring `impl_mem.ml:2556-2562`" (a unit test or `#guard`); if any of them ever returns `none`, mirror `with_constraints` evaluation (**S**) | Z2 |
| Z-60 | `CerbCall.lean` header: "the call-site `conv_int` range conversion is NOT reproduced — an injected integer must fit the parameter type (out-of-range injections are the caller's responsibility)" | a fail-OPEN instrument contract; oracle twin = the rendered wrapper TU (`test_verify.sh render_wrapper`) which DOES convert | **BUG-FIX** (instrument fail-closed rule): refuse out-of-range injections loudly (`kill`) or reproduce `conv_int`. **S** | Z2 |
| Z-61 | `CerbPP.lean` "Residual placeholders" (`<...>`-bracketed) | reach no compared text by design ("an honest mismatch, never oracle-shaped") | INSTRUMENT — Z2 verifies by grep that no residual printer is on a batch-verdict path (`Main.lean` batch renderers) | Z2 |
| Z-62 | `CerbFloat.lean` `Ord Float`: "+0.0/-0.0 compare equal here — OCaml's compare distinguishes them" | value-visible only if a float keys a set/map on an exec path | Z2-DISPOSED: prove unreachable (no `Set Float` in the exec cone) or mirror `Stdlib.compare`. **S** | Z2 |
| Z-63 | `CerbDecode.lean` `read_digit`: "returns 0 for a non-digit where upstream's read_digit computes garbage" (sem:N11) | garbage-for-garbage; declared unreachable (every caller validates first) | Z2-DISPOSED: re-verify the caller set; if reachable, mirror. **S** | Z2 |
| Z-64 | `CerberusFresh.lean` digest in hex form vs OCaml raw 16-byte `Digest.t` | equality-preserving (injective); only `compare = 0` is consumed | Z2-DISPOSED: declared and argued in-code; confirm no ORDER on digests reaches an exec path (an order on hex ≠ order on raw bytes) | Z2 |
| Z-65 | `CerberusImpl.lean` LP64 table vs `ocaml_implementation.ml` `DefaultImpl` | mirrors incl. F1's `float = 8` | Z2-DISPOSED: diff the two tables entry by entry (sizeof/alignof/`is_signed`/`char` signedness/`max_align_t`) | Z2 |
| Z-66 | `CerbGlobal.lean` (Z-24), `CerbConcurrency.lean` (Z-25), `CerbDebug.lean`/`CerbUtils.lean` no-op stubs | debug/profiling not on any differential path (effect retirement C1) | INSTRUMENT; Z2 confirms the debug level is 0 on the oracle in matched mode (`Cerb_debug` default) so `print_debug` output cannot differ | Z2 |
| Z-67 (R1) | `CerbLocation.lean` vs `util/cerb_location.ml` | Z-03 rendering; `isLibraryLocation` (`:180-185`) is NOT correct (the first draft said so wrongly): it matches ANY path segment equal to `libcore`/`include`/`impls`, where the oracle's `is_library_location` (`util/cerb_location.ml:512-520`) tests the RUNTIME-prefixed paths `Cerb_runtime.in_runtime "libc/include"`/`"libcore"`/`"libcore/impls"` — a user file under a directory named `include/` is library-classified on Lean only (D1's substitution then fires wrongly). Added to Z-01's scope: mirror the runtime-prefix check | SEAM INDEX → BUG-FIX rows Z-01 (widened)/Z-03 | Z1 |
| Z-68 | `CoreParser.lean` vs `parsers/core/core_parser.mly` | Z-01 loc stamping; G6 hash-collision TRIPWIRE (Lean fail-stops where the oracle's digest-keyed symbols cannot collide) | SEAM INDEX → BUG-FIX Z-01; the tripwire is an unreachable-by-construction divergence, declared | Z1 / Z2 |
| Z-69 | `Main.lean` driver glue vs `backend/driver/main.ml` + `pipeline.ml` | Z-24 (flag handling), Z-28 (link order), Z-04 (error text), `--args` mirrored with cites | SEAM INDEX → BUG-FIX Z-24/Z-28 | Z1 / Z3 |
| Z-70 | `CabsImport.lean` vs `backend/lean_export/cabs_json.ml` | strict schema, hard errors — the bridge; its failures are `CERB_INCONSISTENT`/bridge classes, never a Lean verdict | INSTRUMENT (bridge); Z2 confirms every parse failure is loud | Z2 |
| Z-71 | instance files (`CerbCabsInstances`, `CerbCtypeInstances`, `CerbFunMapInstances`, `CerbStepInstances`) vs OCaml polymorphic compare / `ctypeEqual` | `CerbCtypeInstances` BEq = annotation-insensitive `ctypeEqual` (the model's own); Ord delegated to the derived compare; `CerbStepInstances` mirrors `driver.lem:1410` blocked-thread equality | Z2-DISPOSED: check each instance against the OCaml equality it replaces (poly-compare vs structural) at every exec use site | Z2 |

## 3. THE SEAM-BY-SEAM MIRROR AUDIT (slice Z2 deliverable)

Method that found 4 of the 7 noodler discrepancies: read the Lean seam
against its OCaml twin LINE BY LINE (not by probe), list every
divergence as a candidate, then probe each C-observable candidate on
fork oracle + upstream + Lean, and dispose each in-code (mirror with
cite, or declare with the reachability argument) AND as a census row.
Mandated for every file in `handwritten_copy.manifest` (22):

| Lean seam (lines) | OCaml twin | Audit focus | Rows expected |
|---|---|---|---|
| `CerbMem.lean` (2561) | `memory/concrete/impl_mem.ml` (module `Concrete`) | RE-READ the parts the noodler's Explore agent covered only by summary: `abst`/`repr` provenance handling, `eq/lt/le/ge/diff_ptrval`, `memcpy/memcmp/realloc`, varargs, `max/min_ival`, `op_ival`, `sizeof/alignof/offsetsof` (the `offsetof-union-member` panic), `case_ptrval`, `ptrfromint`/`intfromptr` incl. device + PNVI arms even though refused | Z-09…Z-23 dispositions + new |
| `CerbND.lean` (275) | `ocaml_frontend/smt2.ml` `runND` + `nondeterminism.lem` + `driver_ocaml.ml:158` `batch_drive` | `NDguard`/`NDbranch`/`NDnd` handling; trace ORDER (batch prints in enumeration order — is the order identical? counts agree, order is unverified); `--first` vs `--mode=random` (the oracle's single trace is RANDOM — which trace does `--first` pick and which does the oracle? lanes compare `--first` only against single-verdict programs); `nd_status` rendering | Z-59 + order row |
| `CerbPP.lean` (238) + the `CerbMem` sub-printers | `ocaml_frontend/pprinters/pp_core.ml`, `pp_symbol.ml`, `pp_mem.ml` | every printer that reaches a batch verdict line (`Specified(…)`, `Unspecified('…')`, pointer/prefix renderings, `mem_error` Show) — byte identity; residual placeholders off-path (Z-61) | Z-61 + any value-rendering row |
| `CerbCall.lean` (227) | NO OCaml twin — the oracle twin is `test_verify.sh render_wrapper`'s TU | the injection protocol vs the elaborated call site (`create`/`store`/`conv_int`); Z-60 fail-open | Z-60 |
| `CerbFS.lean` (347) | `sibylfs/` via the OCaml `Sibylfs` wrapper + `driver.lem` fs steps (`store_error`, `:211-247`) | the served/refused/residual partition against SibylFS op by op (Z-26/Z-27); the errno path | Z-27 |
| `CerberusFresh.lean` (176) | `Cerb_fresh`, `Digest`, `native/md5.c` | Z-64 (equality only); symbol ids vs the single-supply scheme (the tolerated renumbering class, VALIDATION.md §2) | Z-64 |
| `Main.lean` (1138) | `backend/driver/main.ml`, `backend/common/pipeline.ml`, `driver_ocaml.ml` | CLI (Z-24), link order (Z-28), `prepare_main_args`/`--args` (`main.ml:111-113/512-514`, cited), batch renderers (`driver_ocaml.ml:22-30` cited), exit-code mapping (`expected_exit_for` in the harnesses) | Z-24, Z-28, Z-04 |
| `CerbUtils.lean` (189), `CerbDebug.lean` (42) | `cerb_debug.ml`, misc | no-op stubs off every differential path (Z-66) | Z-66 |
| `CerbLocation.lean` (207) | `util/cerb_location.ml`, `cerb_position.mli` | `simple_location` rendering (Z-03), `is_library_location` (`:512`), region arithmetic used by D1's substitution | Z-01/Z-03 |
| `CerbGlobal.lean` (146), `CerbConcurrency.lean` (33) | `cerb_global.ml`, `switches.ml`, `cmm_csem.lem` | Z-24/Z-25 refusal; every `Switches.has_switch` read in the exec cone evaluates as the oracle's DEFAULT set (enumerate: `SW_strict_reads`, `SW_forbid_nullptr_free`, `SW_zap_dead_pointers`, `SW_inner_arg_temps`, `SW_permissive_printf`, `SW_no_integer_provenance`, `SW_CHERI`, `SW_PNVI`, `SW_strict_pointer_arith` … — the oracle's default for each vs Lean's constant) | switch-default table row(s) |
| `CerberusImpl.lean` (254) | `ocaml_implementation.ml` `DefaultImpl` | Z-65 table diff | Z-65 |
| `CerbFloat.lean` (314) | `util/cerb_floating.ml`, OCaml `Float` builtins, `impl_mem.ml:1155/2554` | Z-62; `truncToInt` crash parity (F2); rounding-mode assumptions | Z-62 |
| `CerbDecode.lean` (164) | `ocaml_frontend/decode.ml` | Z-63; the `'\?'`/`"\?"` arms (R1: Lean has them, the oracle does not — the register decides) | Z-63, R1 |
| `CerbTags.lean` (36) | `ocaml_frontend/tags.ml` | value-threaded table vs the oracle's mutable global: same table at every read (multi-TU link order matters — Z-28) | (Z-28) |
| `CoreParser.lean` (2166) | `parsers/core/core_parser.mly` (+ `core_lexer.mll`) | Z-01 stamping; every production's annotation/loc; `PEundef`/`PEerror` loc; the G6 tripwire | Z-01, Z-68 |
| `CabsImport.lean` (755) | `backend/lean_export/cabs_json.ml` | schema strictness (Z-70); no defaulting anywhere | Z-70 |
| `CerbCabsInstances`, `CerbCtypeInstances`, `CerbFunMapInstances`, `CerbStepInstances` (72/51/75/226) | OCaml polymorphic `compare`/`=` at each use site; `ctype.lem ctypeEqual` | Z-71: which equality the OCaml uses at each exec site and whether the Lean instance agrees (annotation sensitivity; NaN; closures) | Z-71 |

Deliverables of Z2: (1) every divergence found gets a census row
(appended to §2 under "Z2 additions" with the same columns); (2) every
row is disposed IN CODE — mirrored with `file:line`, or declared
deliberate with the reachability argument next to the code; (3) a
probe per C-observable candidate, three-engine, pinned per §4.2; (4)
the stale-cite pass (Z-23).

## 4. INSTRUMENT CHANGES

### 4.1 Close the loc (and stderr) blind spot (after Z-01/02/03/72 land)

The `loc` and `stderr` fields become part of the compared verdict in
every lane that extracts UB verdicts. R1 F4 corrected the first draft:
the byte-compare lanes do NOT already see loc — `test_multi_tu.sh`,
`test_verify.sh` and `test_cn_coverage.sh` also run ub-only extractors.
Sites (enumerated and re-verified; one baseline instrument commit with
the justification in its header — LADDER.md convention):

- `scripts/test_exec.sh` `extract_verdict_seq` (`:337-347`, the
  `grep -oE 'Undefined \{ub: "[^"]*"|Defined \{value: "[^"]*"'`
  shape): compare the whole `Undefined {…}` line; also the
  newline-in-ub hardening (detective §4) since it is the same lines.
  Status-only baselines do not move; the csmith wrapper inherits.
- `scripts/test_ci_sweep.sh` `:165-170` — same extractor; DELETE the
  legacy comment `:32-33` ("loc strings deliberately differ across the
  two pipelines, Main.lean:344 'harness never compares loc'").
- `scripts/test_cn_coverage.sh:238`, `scripts/test_multi_tu.sh:113`
  (same `grep -oE` shape), `scripts/test_verify.sh:72`
  (`sed -n 's/^Undefined {ub: "\([^"]*\)".*/\1/p'`),
  `tests/mem-scale-probes/measure.sh:82` (adds `Error {msg: …}`),
  `tests/parity-probes/run_probe.sh` `seq()`,
  `tests/noodle-probes/run_noodle.sh`: same change.
- the speclab family's verdict extractor (reviewer-cited as
  `test_speclab.sh` `seqof`; this charter's grep of that file finds no
  `Undefined` extractor and `:51` is the usage text — Z1 locates the
  actual site in the speclab scripts before changing it).
- `scripts/test_immaculate.sh` normaliser (`:78-104`): stop stripping
  the location; re-record `tests/immaculate/baseline.txt` (UB rows gain
  the loc in the token).
- `lean_frontend/Main.lean:344` — delete the declared deviation "loc
  strings use CerbLocation.stringFromLocation (harness never compares
  loc)" once Z-03 mirrors `simple_location`; the remaining three
  declared deviations are census rows (Z-61, Z-74, Z-73).
- `scripts/test_gcc_oracle.sh`: unaffected (oracle-independent; UB rows
  are `SKIP_UB`).
- Plants: a one-column loc perturbation in D1's reproducer
  (`float_inf_to_int_ub.c`) must turn the exec lane red; Z-72's `se1.c`
  must be DIFF before and MATCH after; D1/D2 probes likewise.

### 4.2 Integrate the 145 noodle probes per their INTEGRATION columns

Counts are the record's (derived); the per-probe rows are in each
`tests/noodle-probes/<area>/README.md`.

| Probe class | Count | Target | Expected class | Gate? |
|---|---|---|---|---|
| 3-way AGREE, deterministic, UB-free, prints/returns | ~78 | `tests/minimal`-style exec lane (nolibc) / `tests/libc_exec` (libc); return-value-only ones also into the gcc second-oracle corpus | MATCH / AGREE | yes |
| oracle == Lean agreed UB code | 12 | exec lane | UB_MATCH (now loc-inclusive) | yes |
| oracle == Lean ≠ gcc (U1, P1, L1, L3, L4, L6 witnesses) | ~14 | exec/libc_exec MATCH; gcc lane as pinned pairs in a NEW, DISTINCT class `PINNED_TRAY_<n>` (R1 F5: the first draft's `TRIAGED_U1/_P1/_F1/_LIBC` CONTRADICTED the lane's design — `docs/2026-08-30_gcc-second-oracle-design.md` §4 reserves `TRIAGED_*` for D2/D3(a)/D4 "neither side wrong", and an OCaml-agrees-with-Lean disagreement is the D1 shared-source class: stop/report/file). `PINNED_TRAY_<n>` = a CONFIRMED shared-source oracle bug with a tray draft; contract: the pin flips to AGREE on the upstream fix, any other movement is a regression. Amend design §4 and the acceptance lists `test_gcc_oracle.sh:223` and `:582` (`TRIAGED_ADDR\|TRIAGED_FLOAT\|TRIAGED_UB\|TRIAGED_ORDER`) in the same instrument commit | MATCH + `PINNED_TRAY_<n>` | MATCH yes; gcc pin |
| oracle == Lean ≠ gcc on FLOAT WIDTH / long double / `max_align_t` / `rand` observers (F1 witnesses) | ~6 | already the design's D2 class `TRIAGED_FLOAT` (§2.3 implementation-profile table); F1 is reconciled as D2 (impl-defined value set, F6), with tray 31 recording the `FLT_MANT_DIG` inconsistency | MATCH + `TRIAGED_FLOAT` | MATCH yes; gcc pin |
| Lean ≠ oracle: D4–D7 (+ D1/D2 loc reproducers) | 5 (+2) | `tests/immaculate/` DIFF rows with the Lean pin — RED until Z1 fixes them, then re-recorded MATCH (the immaculate-style pinned pair: the lane fails closed both ways, so the fix commit MUST re-record) | DIFF → MATCH | pinned pair |
| both-reject / both-crash controls (E1, E3–E7, F2, L5, `strtok`, `vscanf`) | 12 | immaculate crash pairs (L5, F2 — `MATCH \| L=CRASH`); both-reject controls reporting-only | CRASH-pair / SKIP | pins only |
| both-slow exhaustive (`strtol`) | 1 | `--first` reporting lane | — | no |
| Lean OOM (RC-3 witnesses) | 2 | `tests/mem-scale-probes` family (Z-30's measurement) | LEAN_KILL | no |
| ORACLE-SUSPECT reproducers (13) | 13 | pinned MIRRORED-AGREEMENT (exec/libc_exec MATCH) + gcc pinned pair + the tray cross-reference in the probe header (so a future "fix" toward ISO trips the exec lane's improvement-fails-too rule and the row points at the register) | MATCH + pin | yes |
| E2 (`ptr_string_literals.c`) | 1 | immaculate `ORACLE_CRASH` pair, Lean pin `VAL:Specified(0)` + tray-10 addendum; register R1 | pair | pin |
| (R2) `dynamic-addrs/da_control.c`, `da_bug.c`, `da_malloc0_nonnull.c` | 3 | exec corpus (nolibc) | MATCH / UB_MATCH | yes |
| (R2) `dynamic-addrs/da_offset.c`, `da_align16.c` | 2 | `tests/immaculate/nolibc/` DIFF rows pinned at the Lean values `VAL:Specified(16)` / `VAL:Specified(3)` — RED until Z-76 lands, then re-recorded MATCH | DIFF → MATCH | pinned pair |
| (R2) `dynamic-addrs/core_*.core` (8) + `inj_*` (4 C + 4 `.core` injection bodies) | 16 | reporting-only pins cross-referenced from tray 19: the `.core` rows run on the two OCaml oracles only, the `inj_*` rows on Lean only (libc-body injection). **INSTRUMENT GAP, registered follow-up**: no lane runs `.core` inputs on both sides (the Lean driver's `--parse-core` parses only). A Core-level differential lane (a Lean `.core` runner over the existing CoreParser + `drive`) would make Core-only shapes pinnable and R4-class register entries admissible under (iv). Priced **S-M**; TODO.md entry in Z4 | pins only | no |

The gcc lane stays Tier B (LADDER.md Tier B row 7; ~24 min).

### 4.3 The VALIDATION.md rewrite (Z4, with Z1's baseline commit as the first pointer)

The trust story's headline becomes: the RULE (§1.1 verbatim), the
FOUR exception classes with their operational tests, the ISO-fix
REGISTER (initially the operator-ruled subset of R1–R3, or empty), and
a pointer to this census as the enumeration of every known Lean-vs-
oracle difference with its class. The §5 boundary paragraph is
rewritten from "declared MODEL boundary" language to the class
vocabulary: CerbFS = (c) with the refused set enumerated; concurrency
= (c) "not supported; the oracle's mode is non-functional"; switches =
(c) refused; fuel = (b)/fuel; the 8 M hang and the byte-list OOM =
(b)-VIOLATIONS with named movers. "Never fix-to-match" is deleted in favour of register citations at
every site (R1 F11, verified): `tests/immaculate/baseline.txt:37` and
`:40`; `scripts/test_immaculate.sh:258` and `:261` (the writer template
that regenerates the header); `tests/immaculate/libc/g5-escape-roundtrip.c:8`;
`CerbDecode.lean:84-91` ("DELIBERATE DIVERGENCE from upstream" → the R1
register cite + (vii) marker). Doc integrity in the same slice:
`scripts/LADDER.md:69` "15 DIFF are the F-D fork-oracle class" is stale
(the csmith baseline has 0 DIFF rows: 1160 MATCH / 499 CERB_SKIP /
8 TIMEOUT / 2 LEAN_CRASH) — rewrite.

## 5. UPSTREAM TRAY — drafts to add (Z4)

Numbering continues the tray (18 on mainline + 19 on `probe/dynamic-addrs`; R2 renumbered this plan from 19–32 to 20–33). Order = the brief's
(upstream value): each draft carries its noodle probe as the
reproducer (verbatim three-engine lines from `results.log`), the
mechanism cite, the ISO clause, a proposed remedy, the TRUE BUG /
INTENDED GAP / UNCLEAR classification, and the provenance note per the
[USER 2026-08-23] labeling policy; INDEX.md gets a dated block and the
filing checklist gains the new numbers.

| # | draft | class | reproducer |
|---|---|---|---|
| 19 | `19-dynamic-addrs-never-cleaned.md` — ALREADY DRAFTED on `probe/dynamic-addrs` @ `2700f99c0` (Z-77; TRUE BUG, memory-model soundness gap, low C exposure; INDEX entry there) — merges with that branch, not re-drafted here | TRUE BUG | `dynamic-addrs/core_bug.core` (+ `inj_bug_bexit.c` on Lean) |
| 20 | `20-size-t-integer-rank-uac.md` (U1) | TRUE BUG | `int/int_size_t_uac_rank.c` |
| 21 | `21-provenance-lost-through-arithmetic-pvi.md` (P2) | TRUE BUG vs the PVI model / UNCLEAR if intended — ask | `ptr/ptr_intptr_arith_roundtrip.c` |
| 22 | `22-ptrdiff-strips-array-layer.md` (P1) | TRUE BUG | `ptr/ptr_array_ptrdiff_scaling.c` |
| 23 | `23-string-literal-init-of-char-array-members.md` (E4) | TRUE BUG | `elab/elab_string_member_init.c`, `elab_string_struct_member_init.c` |
| 24 | `24-stdio-buffer-not-flushed-at-exit.md` (L3) | TRUE BUG | `lib/lib_stdio_unflushed_lost.c` (+2) |
| 25 | `25-atexit-not-run-on-main-return.md` (L4) | TRUE BUG | `lib/lib_atexit_order.c` |
| 26 | `26-printf-star-width-crash.md` (L5) | TRUE BUG (crash on legal input) | `lib/lib_printf_star_width.c` |
| 27 | `27-printf-hex-int-argument-ub153b.md` (L6) | TRUE BUG (over-strict) | `lib/lib_printf_hex_int_arg.c` |
| 28 | `28-conditional-in-static-initializer.md` (E3) | TRUE BUG | `elab/elab_const_expr_ternary_init.c` |
| 29 | `29-string-literal-address-constant.md` (E5) | TRUE BUG (tray-09-adjacent) | `elab/elab_addr_const_string_plus.c` |
| 30 | `30-strncmp-zero-length.md` (L1) | TRUE BUG (libc) | `mem/mem_strncmp_zero.c` |
| 31 | `31-calloc-overflow-check.md` (L2) | TRUE BUG (libc, minor) | `mem/mem_calloc_overflow.c` |
| 32 | `32-float-evaluated-as-double.md` (F1) | INTENDED GAP (literal `TODO:hack`) with an observable inconsistency against `float.h` `FLT_MANT_DIG 24` (F6) | `float/float_single_precision.c` |
| 33 | `33-unspecified-operand-exceptional-condition-question.md` (O6) | UNCLEAR — question | `misc/misc_unspec_absorbed.c` |
| 10 (addendum) | string-literal form of `\?` (E2) | — | `ptr/ptr_string_literals.c` |

## 6. SLICES AND GATES

Ordered by execution-correctness impact, S items first. Every slice
ends with the full battery (LADDER.md Tier A + Tier B incl. the gcc
lane), fresh stamped binaries, verbatim summaries in the slice record,
one coherent commit per slice on green gates; the orchestrator
re-verifies at each boundary. Baseline/instrument moves are dedicated
commits.

| Slice | Scope (census rows) | Gate bar | Price |
|---|---|---|---|
| **Z1 — the D-fixes + loc/stderr instrument + refusal hygiene** (AFTER the fuel arc merges: shared `Main.lean` and harness files) | Z-05 (D4, value-level, FIRST), Z-06/07/08 (D5–D7 verdict class), Z-01/02/03 (D1/D2/O1 loc + renderer; Z-01 widened to the `isLibraryLocation` runtime-prefix mirror, Z-67), Z-72 (stderr on Undefined lines — must land with Z-01/02/03), Z-76 (`IvMaxAlignment` 16 → `CerberusImpl.max_alignment`; the two `da_*` immaculate pins flip), Z-10 (static kill of a dead allocation → fail-stop mirror, per Q4), Z-24 (CLI refusal, feature-attributed, incl. known flags out of position; covers Z-25), Z-27 (CerbFS op-by-op served/refused table + loud refusals), Z-74 (exit-class evidence), Z-73 per the Q8 ruling, then §4.1 (loc-aware lanes, one instrument commit) and the seven immaculate-style pins (§4.2 row 4) added RED before the fixes and re-recorded MATCH after | Tier A+B green; the 7 pins flip DIFF→MATCH; loc plant red/green; P-A/P-C probes refuse with the attributed text; `stat.c`/`cat.c` move from STDOUT_DIFF/LEAN_FAIL to a `CerbFS refusal` (loud) in a spot sweep of `tests/suite/fs` + `tests/freebsd` | S × 10 ≈ 3–4 days |
| **Z2 — the seam-by-seam audit** (§3; R2 motivation: Z-76 was a literal in a hand-written seam that a CoreParser-vs-`core_parser.mly` line pass would have caught) | read-only pass → census rows (appended "Z2 additions") → fixes: Z-09…Z-22 (14 S mirrors), Z-59…Z-65, Z-70/71 dispositions, Z-23 cites, Z-60 fail-closed injection | every new row disposed in-code; three-engine probe per C-observable candidate, pinned; Tier A+B green; no row left "unobservable" | M (≈ 1 week; the CerbMem re-read dominates) |
| **Z3 — libc allocation-order mirror** | Z-28 | the 6 pnvi rows MATCH in a `tests/pnvi_testsuite` spot sweep; `addr_layout.c`-style probe pinned in libc_exec; Tier A+B green | S-M |
| **Z4 — probe integration + tray + VALIDATION rewrite + re-sweep** | §4.2 (145 probes into lanes; new gcc triage classes), §5 (14 drafts 20–33 + the tray-10 addendum + INDEX; 19 merges from `probe/dynamic-addrs`), §4.3 (VALIDATION.md headline + register instantiation per the §7 rulings; `tests/immaculate` header rewrite), Z-40 (elab main-file filter), Z-42 (the `test_ci_sweep.sh` re-record — measurement sweep, tripwire justification written in advance), the R2 probe rows (§4.2) and the Core-level-differential-lane TODO entry | Tier A+B green at the new baselines; the sweep TSVs re-recorded in a dedicated instrument commit; INDEX consistent | M |
| **Movers outside this arc (named, not scheduled here)** | Z-29 (lem-arc run-loop rendering, L), Z-30 (byte representation, M — profile first), CerbFS real semantics (M, optional once Z-27 lands) | — | — |

Dependencies: Z1 waits for the fuel merge (both touch `Main.lean` and
the classifying harnesses); Z2 and Z3 are independent of each other
and of Z1 except for shared `CerbMem.lean` hunks (Z2 rebases on Z1);
Z4 last (its pins encode the post-fix state). Each slice's record is a
dated `docs/2026-09-xx_zero-discrepancy-Z<n>-record.md`; the census
table in this file is the living register — rows change class only by
a commit that cites its evidence.

## 7. OPEN QUESTIONS FOR THE OPERATOR

Only genuine ones. Q1 is recorded as ruled. Each of Q2–Q10 carries the
R1 reviewer's RECOMMENDATION [AGENT, orchestrator review of `6a55dc74d`]
for the operator to accept or override.

- **Q1 (RULED — recorded).** UB location is behaviour: [USER
  2026-09-03] "(1) agree". Applied throughout (Z-01/02/03/20, §4.1).
- **Q2 — ratify the class-(d) register criteria (i)–(vii) and rule
  R1/R2 individually ((v)).** RECOMMENDATION: ratify (i)–(vii); ADMIT
  R1 (`'\?'`/`"\?"` = 63; gcc exit 63 and `"a\?b"` bytes `97 63 98 0`;
  tray 10; code site `CerbDecode.lean:91`) and R2 (`%c` 127 vs oracle
  87; gcc exit 127; tray 11; entry names the exact escape round-trip
  site). Anything refused becomes a mirror commit in Z1 (pins turn
  `MATCH | L=CRASH`). **R4 (R2, dynamic_addrs / tray 19):** both sides
  in §2.6; RECOMMENDATION [AGENT]: DEFER — Core-only shape, so no lane
  can pin a Lean-right/oracle-wrong pair today; C exposure nil; the
  consumer's logic is sound regardless; revisit if upstream declines
  AND a Core-level differential lane exists. If admitted now, the
  honest entry says "pinned by `tests/noodle-probes/dynamic-addrs/`
  (oracle `.core` rows vs Lean injection rows), not by the immaculate
  lane".
- **Q3 — ratify the TIGHTENED (ii') for UB reproducers and rule R3.**
  (ii') = §1.4: (1) non-semantic host exception raised before the
  semantic path; (2) Lean is the line-mirror minus that conversion;
  (3) second oracle = the oracle with the tray remedy applied to a
  scratch build. RECOMMENDATION: ratify; ADMIT R3 (`s4b-memcmp-hugesize`,
  tray 13) once Z4 produces (3). Consequence noted: F2 `(int)NaN` is
  eligible under the same shape; `g4-bswap64-overflow` is not.
- **Q4 — tool crashes as behaviour.** RECOMMENDATION: confirm that a
  ONE-SIDED oracle crash (uncaught exception) outside the register
  requires a Lean fail-stop carrying the OCaml text; (a) covers
  BOTH-side crashes only (Z-10/14/16/22 apply this to CerbMem's
  `failwith`/`assert false` arms).
- **Q5 — wall-clock margins under (b).** RECOMMENDATION: TOLERATED
  conditional on PER-ROW measured completion (verdict equality) at a
  larger bound. `pr63209.c`/`pr69320-4.c` have it; the 8 csmith
  `TIMEOUT` rows and the 11 gcc-lane `SKIP_LEAN_TIMEOUT` rows do not —
  undemonstrated rows are (b)-VIOLATIONS pending evidence (Z4 measures
  each once).
- **Q6 — F1 (`float` as double, `sizeof(float) == 8`) and the
  register.** RECOMMENDATION: do NOT admit. The premise "(i)
  unambiguous" was overstated: ISO 6.2.5p10 permits `float`'s value
  set to be `double`'s, and 6.3.1.5 then requires no rounding; the real
  defect is the inconsistency with `runtime/libc/include/float.h:4`
  `FLT_MANT_DIG 24` (5.2.4.2.2) — an upstream `TODO:hack` of size M.
  Mirror; tray 31; gcc-lane class stays `TRIAGED_FLOAT`.
- **Q7 — mode flags: refuse or plumb?** RECOMMENDATION: REFUSE now
  (Z-24, S, class (c); includes known flags out of canonical position);
  plumbing the switch set into `CerbGlobal` (M) is not wanted in this
  arc.
- **Q8 (NEW, R1 F2a) — `runND` returning zero executions (Z-73).**
  Lean prints `Error {msg: "cerberus-lean: runND returned no
  executions"}` and exits 1 where the oracle prints nothing and exits 0
  — a deliberate failure-vs-success class difference (a) does not
  cover. Options: (A) keep the fail-closed refusal and DECLARE it as a
  loud boundary (the fuel arc's `runNDFuel` exhaustion leaf has the
  same shape, so this also fixes that row's classification); (B)
  mirror the oracle's silent success. RECOMMENDATION [AGENT]: (A) —
  a silent exit 0 with no verdict is the fail-open shape the working
  practices ban; the oracle's behaviour is an upstream question (tray
  candidate), not a behaviour to reproduce.
- **Q9 (NEW, R1 scope) — is the concurrency (cmm) instantiation mover
  now OPTIONAL?** The first draft DECIDED this (Z-25); it is a
  product-scope change and is therefore an ASK. Evidence: the oracle's
  own `--concurrency` mode fail-stops (`CONCURRENCY IS BROKEN`) at
  `b9aeedcb4`; matched mode agrees. RECOMMENDATION: optional (TODO.md
  "Queued larger work" entry re-labelled "optional; blocked on upstream
  having a working mode to mirror").
- **Q10 (NEW, R1 scope) — is the CerbFS real-fs mover now OPTIONAL?**
  Same shape as Q9 (first draft decided it at Z-26). Evidence: the
  refused set is loud and attributed; Z-27 makes the residuals loud.
  RECOMMENDATION: optional once Z-27 lands (the served set is then
  exactly the correct-answer set and every other op refuses).

## 8. Provenance

[USER 2026-09-03]: the rule (§1.1), the exception classes (a)–(c)
(§1.2), the fuel quote, the UB-location ruling ("(1) agree", §1.3), the
class-(d) ruling quote (§1.4). [USER 2026-08-31 / 2026-09-02] rulings
cited from `VALIDATION.md` and the trust-basket record where quoted.
[AGENT, orchestrator review of `6a55dc74d`, applied as R1]: findings
F1–F11, the register recommendations, the refusal-verdict corrections,
the Q recommendations and the Q9/Q10 scope re-framing — each applied
only after this worker re-verified the cite or re-ran the probe
(quoted verbatim; probes `.zd-scratch/p/`, ephemeral).
[AGENT, dynamic-addrs investigation `probe/dynamic-addrs` @ `2700f99c0`,
relayed by the orchestrator as R2]: Z-76, Z-77, the Z-10 witnesses, R4
and its DEFER recommendation, the Core-level-lane instrument gap; cites
re-read here, engine lines verbatim from that branch's `results.log`.
[AGENT] (this charter): the register criteria (i)–(vii) as a proposal,
every census row's class and price, the R1–R3 adjudication, the
seam-audit mandate, the instrument plan, the tray plan, the slice
order, the probes of §2.3 (`.zd-scratch/probes/`, ephemeral; quoted
lines verbatim from this charter's runs), and the elab-lane row naming
(one harness run); R1 probes: `se1.c`/`se2.c` (stderr), `at.c`
(atomics, three engines), `at.json --first` (misordered flag),
`tests/ci/0069-const_expr.c` (stale `CERB_INCONSISTENT`). Derived tallies are labelled derived; quoted engine
lines are verbatim from the cited records or runs. No product code,
gate, baseline or other document was modified in this slice; nothing
was merged or pushed.
