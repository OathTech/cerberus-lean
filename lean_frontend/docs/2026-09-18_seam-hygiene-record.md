# Record — seam hygiene: opaque failures in the hand-written seams, explicit switch arms, a named OOM kill (2026-09-18/19)

**Status:** [AGENT worker, Claude Fable] record ending the slice chartered in
`2026-09-18_charter-seam-hygiene.md` (branch `arc/seam-hygiene`, worktree
`worktrees/cerberus-lean-arc/seam-hygiene`, charter head `0eafc94a4` on mainline `0457732e1`).
Deliverables, in order: **H1 `fce1de9f8`**, **H2 `ee1eaf94d`**, **H3 `dde3b766b`**, this record (`34b8e15a8`), then — after the independent pre-merge audit (`audit/seam-hygiene` @ `05d208f45`, MERGE-WITH-FIXES, no MAJOR) — **H4 `cef347c6c`** (the audit's fixes, §10) and this amendment.
The slice first STOPPED at charter rule S3 (then S1) after H1 was built and gated (§3 — the
interim record of that stop was commit `db640b214`; its content is folded in here); the
orchestrator verified both blocking facts and EXTENDED THE FENCE (§0), after which H1–H3 landed
as chartered. The FULL battery (`release.py --mode full`, Tier A + B) ran once at the H3 head
(§5.6). Working tree at this commit: clean; `generated/` in sync; the built binaries correspond
to HEAD (stamps recorded by `build_lean`/`build_cerberus`).

## 0. Rulings (by pointer) and the fence extensions

Charter §0 verbatim quotes: [USER 2026-09-18] "Great, charter the planned slice"; [USER 2026-09-17]
"Makes sense, Let's do the sequence as you propose…"; the consumer's principle (cerberus-sl C3.10);
[USER 2026-09-08] "we should *NOT* be building anything new out-of-policy"; [USER 2026-09-11]
execution mode. All decisions below are [AGENT] (worker) unless marked; the orchestrator's are
marked [AGENT orchestrator].

**Fence extensions granted 2026-09-19** ([AGENT orchestrator], after verifying the S3 facts of §3
and the `CerbSwitch` gap of §4 against `ocaml_frontend/switches.ml:5,15,18,32`), each "within the
charter's rulings":

1. **fence extension granted 2026-09-19 — `scripts/observations.py`, the panic-origin acceptance
   ONLY:** accept the actually printed origin `_private.LemLib.0.failwithIImpl` (keep the old
   literal only if shown to be printed — it never is, so it was replaced); reconcile
   `IMMACULATE_PANICS` to exactly the seam origins that still panic under their own names after H1
   (the one KEPT site `CerberusImpl.lean:69`, nothing else; unknown origins stay
   `ProtocolError('unreviewed panic origin')`, fail-closed); plants in `scripts/test_observations.py`
   (mangled origin accepted under batch/immaculate/litmus semantics, stale seam origin rejected,
   unknown rejected); then H1 committed with the immaculate lane GREEN at the committed baseline.
2. **fence extension granted 2026-09-19 — `lean_frontend/CerbGlobal.lean`:** `CerbSwitch` gains the
   four missing constructors mirroring `switches.ml` byte-for-byte in naming
   (`strict_pointer_equality`, `strict_pointer_relationals`, `pointer_arith` with its
   `PERMISSIVE | STRICT` payload as a Lean inductive from `switches.ml:5,65-67`, `zero_initialised`),
   plain-`def`/`rfl`-lemma shape, `has_switch` extended; then H2's eight arms as chartered; the
   charter's impl_mem.ml cites corrected to THIS tree's lines in the record.
3. **fence extension granted 2026-09-19 — `scripts/check_theorem_axioms.sh`:** the `OPAQUE_WANT`
   rows for the opaques H3 deletes may be REMOVED and the population re-pinned as a reviewed number,
   before/after counts in the commit message and the record; the census stays fail-closed.

Also [AGENT orchestrator]: the FAST-GATE per commit includes Tier A rows 2–4b and row 10 + `--plant`;
the FULL battery once at the H3 head; S1–S6 as chartered.

## 1. What happened, in order (derived timeline)

1. Read the charter and every cited file; re-checked each cite against this tree (errata: §6).
2. The primed worktree was STALE on both sides against its own sources (both generated trees and
   both driver binaries predated the mainline's last landing): `tools/check_driver_fresh.sh
   --check-lean` → `CERB_DRIVER_STALE` (CerbMem.lean/Main.lean not propagated,
   CerbMemAllocatorProofs.lean copy missing); `check_lem_sync.sh --check` → `CERB_LEM_SYNC_STALE`;
   `build_cerberus` failed on the stale OCaml tree (`driver.ml:1948 … Impl_mem.initial_mem_state
   has type Z.t -> Impl_mem.mem_state`). Rebuilt at the charter head before any "before" evidence:
   `make clean-prelude-src prelude-src`, `build_cerberus`, `make lean-prelude-src`, `build_lean`
   (stamps recorded). The standing pristine-oracle manifest was present and valid as stated.
3. BEFORE evidence at `0eafc94a4` (§2.4, §2.5): both orchestrator probes compile by `rfl`; three
   REACHABLE immaculate programs abort at their seam sites (exit 134); `check_theorem_axioms.sh`
   opaque population 16, seam pins 38; `check_failure_reach.sh` OK (233 = 233).
4. H1 built: 109 `panic!` → `failwithI`; two pair-equality theorems needed IDENTICAL leaf messages
   (§2.1); my register re-keying mis-paired two same-key rows and the gate named them (§2.2);
   `test_unit` green; the immaculate lane RED on 9 rows — **S3 → S1, STOP** (§3), interim record
   `db640b214`, H1 preserved as a patch.
5. Fence extended (§0). Codec fixed + plants (§3.2); H1 patch re-applied; gates green; **H1
   `fce1de9f8`**.
6. H2: `CerbGlobal` constructors + the eight arms + test + docs; two elaboration fixes (an
   `example`'s `memReturn (a1 > a2)` needed `decide`; nothing semantic); gates green; **H2
   `ee1eaf94d`**.
7. H3: the old-`BEq` witness probe BEFORE deleting the impl (§5.3); `oomKill`, identities,
   structural `BEq`, census rows; two doc-comment placement fixes (`/--` before `mutual`/`namespace`
   → `/-!`); gates green; FULL battery; **H3 `dde3b766b`**; this record.

## 2. H1 — opaque failures in the seams (`fce1de9f8`)

### 2.1 The sites

`2026-09-18_seam-hygiene-evidence/h1-site-table.md` is the per-site table (file, post-edit line,
kernel owner from the register, reach class, action). Derived tally: **98 register rows REPLACED**
(all 98 hand-written `panic!` rows: CerbMem 44, CerbFS 36, CerbDecode 7, CerbUtils 4, CerberusImpl 3,
Main 1, CoreParser 1, CerbLocation 1, CerbFloat 1); **11 out-of-closure sites REPLACED with the
trivially same edit** (CerbMem: `memValueToBytes_append_lemFuel` ×2, `reconstructValue_indexed_lemFuel`
×4, `concurReadIval`, `cheriPointerHashPrintf`, `getIntrinsicTypeSpec`; `CerbLocation.simpleLocation`;
`CerbFloat.of_string`) — [AGENT] so no fence file mixes the two leaves; **1 KEPT**:
`CerberusImpl.lean:69` (`typeof_enum_impl`, `pure (panic! …)` inside the `unsafe` enum-registry impl —
the enum seam is fence-FORBIDDEN, and it is not a register row). Every other site, including
`Main.lean:70` (`loadCoreImpl`'s unreachable `.error` arm — a pure position whose value enters the
impl map) and `CoreParser.lean:2413` (`scanStep`'s fuel sentinel — pure), was replaced.

**Self-locating prefixes (19 sites)** — [AGENT] rule: a message that names NO site (the OCaml text is
`"case_ptrval"`, `"hd"`, `"TODO: …"`, `"unknown function pointer: …"`, `"failed: bytes_of_int(…"`,
`"the concrete memory model requires a complete implementation …"`, or the variable `e`) gains the
prefix `<Module>.<fn>: ` and keeps the OCaml text as its suffix; a message already carrying an OCaml
`Module.fn:`/`fn:` name or the `CerbFS refusal (…)` form is byte-identical. Prefixed:
`CerbMem.targetPtrSize`, `sizeofCtype` ×2, `alignofCtype` ×2, `intToBytes`, `memValueToBytes` ×4 (both
workers, SAME prefix), `reconstructValue` ×2 (both workers, SAME prefix), `casePtrval`, `maxIval`,
`minIval`, `concurReadIval`, `arrayShiftPtrval`, `CerbLocation.simpleLocation`, `Main.loadCoreImpl`.
**Constraint discovered:** `CerbMem.lean`'s `rfl` arms of the pair-equality theorems
`memValueToBytes_lemFuel = memValueToBytes_append_lemFuel` and
`reconstructValue_lemFuel = reconstructValue_indexed_lemFuel` closed with `panic!` because both leaves
reduced to `default`; with `failwithI` they close only if the message STRINGS are identical (verbatim
first attempt: `error: generated/CerbMem.lean:962:11: Tactic `rfl` failed: The left-hand side` …
`:1280:11 …`). Same prefix on both members of each pair; those theorems now ENFORCE message identity
between the paired workers.

**Imports:** `CerbUtils`, `CerbLocation`, `CerbFloat`, `CerbFS` had NO imports, so bare `failwithI` was
`Unknown identifier` (36 errors in CerbFS alone); `import LemLib` added as line 1 of each. `failwithI`
is a TOP-LEVEL LemLib constant (no `LemLib` namespace exists — LemLib.lean's namespaces are `Vector`,
`Pset`, `Pmap`, `LemUnsupported`), so the charter's `LemLib.failwithI` is a shorthand (E4); the census
tokenizer (`[\w][\w'.!?]*`) would lex a qualified spelling as ONE token that is not `failwithI` and drop
the site from the census, so the bare spelling is load-bearing for the register gate.

### 2.2 The register re-record

`scripts/failure_reach_register.txt`: exactly the 98 hand-written `panic!` rows — 84 rows in
`token`+`seal`; 14 rows in `token`+`msg`+`seal` (the `msg` column is the census's derived 60-char KEY
and follows a prefixed message; E7); `file`, `definition`, `scope`, `position`, `position_reviewed`,
`reach`, `need`, `cite`, `note` byte-identical on every row (verified column-by-column); tally line
unchanged. Reseal, verbatim: `check_failure_reach: resealed 233 rows of scripts/failure_reach_register.txt
(review change: commit with the justification)` — justification = charter H1. Position classes
UNCHANGED on all 98 rows. Gate (verbatim, every run since):

    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)

Incident: my re-keying script paired the 11 sites sharing the old key `"the concrete memory model
requires a complete implementatio` by line order and mis-keyed `maxIval`/`minIval`; the gate's first
run named exactly those (verbatim, from the worker's terminal — that log was overwritten by the re-run):

    check_failure_reach: FAIL —
      NEW pure exec-closure site (no register row — review it): lean_frontend/CerbMem.lean:1419 CerbMem.maxIval failwithI «"CerbMem.maxIval: the concrete memory model requires a compl» position=LET-BOUND scope=EXEC
      NEW pure exec-closure site (no register row — review it): lean_frontend/CerbMem.lean:1447 CerbMem.minIval failwithI «"CerbMem.minIval: the concrete memory model requires a compl» position=ARGUMENT scope=EXEC
      STALE register row (site gone or its key moved): lean_frontend/CerbMem.lean CerbMem.maxIval failwithI «"CerbMem.memValueToBytes_append: the concrete memory model r» scope=EXEC
      STALE register row (site gone or its key moved): lean_frontend/CerbMem.lean CerbMem.minIval failwithI «"CerbMem.memValueToBytes_append: the concrete memory model r» scope=EXEC

The two rows were re-keyed from the live census by kernel owner (`…evidence/h1_register.py` is the
script WITH its defect, kept as the record of what ran). The tripwire caught it both directions.

### 2.3 The hermetic test

`lean_frontend/test/Unit/OpaqueFailureTest.lean` (`opaque-failure-test`; registered in
`lakefile.toml` with `moreLinkArgs = ["native/md5.o"]` like every CerbMem-importing exe, and in
`scripts/test_unit.sh`): `#guard_msgs` on the two FAILING tactic `rfl`s (a transparent leaf would make
`rfl` succeed, the expected error would be missing, and the build RED — the loud direction); a
text-independent check that `failwithI` is an `opaqueInfo` in the compiled environment (`#eval` in
`CommandElabM`); positive controls (default arms reduce by `rfl`; registered arms `#check`). H2 and H3
added their sections (§4.3, §5.3). Final run line: `opaque-failure-test: PASS — the two seam
identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment,
default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by
rfl); oomKill named; STD_/timing identities; structural BEq MemValue agrees with the retired impl on 23
pairs`.

### 2.4 Kernel probes, before/after (verbatim; `…evidence/probe-before.*`, `probe-after.*`)

BEFORE (charter head, fresh build): `lean_probe.sh ProbeBefore.lean` → rc 0, no diagnostics — both
`example … := rfl` compile. AFTER (H1):

    ProbeAfter.lean:3:76: error: Type mismatch
      rfl
    has type
      ?m.7 = ?m.7
    but is expected to have type
      CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none = CerbMem.Provenance.Prov_none
    ProbeAfter.lean:4:48: error: Type mismatch
      rfl
    has type
      ?m.5 = ?m.5
    but is expected to have type
      CerbMem.bytesToInt [] false = none
    ProbeAfter.lean:6:79: error: Tactic `rfl` failed: The left-hand side
      CerbMem.combineProv (CerbMem.Provenance.Prov_symbolic 0) CerbMem.Provenance.Prov_none
    is not definitionally equal to the right-hand side
      CerbMem.Provenance.Prov_none
    ProbeAfter.lean:7:51: error: Tactic `rfl` failed: The left-hand side
      CerbMem.bytesToInt [] false
    is not definitionally equal to the right-hand side
      none

and the two positive controls (default arms) elaborate without error.

### 2.5 Runtime transcripts, before/after (verbatim first stderr lines; full files in the evidence dir)

Three REACHABLE register sites driven by `tests/immaculate/nolibc` programs through the fork oracle's
`--cabs-json` and `LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --first`; exit 134 and empty stdout on
every run (the charter asked for two; the third shows a prefixed message):

| program (site) | BEFORE `0eafc94a4` | AFTER H1 |
|---|---|---|
| `g4-bswap64-overflow` (`CerbUtils.gcc_builtin_bswap64`, text unchanged) | `PANIC at CerbUtils.gcc_builtin_bswap64 CerbUtils:172:4: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)` |
| `zd-z2fl03-nan-to-int` (`CerbFloat.truncToInt`, text unchanged) | `PANIC at CerbFloat.truncToInt CerbFloat:426:4: CerbFloat.truncToInt: nan/inf (OCaml Z.of_float raises Z.Overflow)` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: CerbFloat.truncToInt: nan/inf (OCaml Z.of_float raises Z.Overflow)` |
| `zd-z2m02-device-funptr-call` (`CerbMem.casePtrval`, PREFIXED) | `PANIC at CerbMem.casePtrval CerbMem:1385:4: case_ptrval` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: CerbMem.casePtrval: case_ptrval` |

Same message text (or the OCaml text as the suffix of the self-locating prefix), same exit status; only
the `PANIC at <site>` head moves — to the PRIVATE-mangled LemLib name (§3).

### 2.6 Gates at the H1 commit (verbatim; `…evidence/test_unit_h1_verdicts.txt`, `test_immaculate_h1_green.txt`, `gates_h1_verdicts.txt`)

`test_unit.sh` (incl. the register gate) and the immaculate lane:

    Total: 12 passed, 0 failed
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 16 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (377 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; r
    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).

Tier A rows 2, 3, 4, 4b (each `SUMMARY` line followed by its `Baseline check` line, in that order) and row 10 + `--plant`:

    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-o0po2fcr/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-06ozer03/report.json

(The failure-reach line of §2.2 is part of `test_unit`. The census is unchanged by H1 — 16 opaques,
38 pins — as expected.)

## 3. The S3 stop and its resolution — the codec pinned the panic SITE name

### 3.1 The finding (before the fence extension)

`LEAN_PANIC = re.compile(rb'PANIC at ([^ \r\n]+) [^\r\n]+:[0-9]+:[0-9]+: (.+)')` (observations.py:53)
captures the site; its ONE consumer is `failure_message` (:199-209), reached only under the `litmus`
and `immaculate` policies (`batch` never gets there — `FUEL_RECORD` first, then `FATAL`). Before H1:

    if lean[1] != b'LemLib.failwithIImpl' and not (
            policy == 'immaculate' and lean[1] in IMMACULATE_PANICS):
        raise ProtocolError('unreviewed panic origin')

with `IMMACULATE_PANICS` = eight seam SITE names. Facts established: (1) LemLib's impl is `private`
(`LemLib.lean:167 @[never_extract] private unsafe def failwithIImpl`), so the runtime prints
`PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: <msg>` — NEVER `LemLib.failwithIImpl`; the
codec's unconditional accept-literal was dead code and the codec's own plants carried the unmangled
name (a LATENT defect independent of this slice: any generated-model `failwithI` crash under those
policies would have read `unreviewed panic origin`); (2) therefore under `immaculate` the only accepted
Lean panic origins were the eight seam sites — the lane pinned them; H1 moved every seam site to the
mangled LemLib name. Codec on the captured stderr, verbatim (`…evidence/codec-before-after.txt`):

    [immaculate/before] g4-bswap64-overflow rc=0: INTERNAL_ERROR:{msg: "Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)"}
    [immaculate/after] g4-bswap64-overflow rc=2: OBSERVATION ERROR: unreviewed panic origin
    [batch/before] g4-bswap64-overflow rc=2: OBSERVATION ERROR: fatal engine diagnostic; no completed observation
    [batch/after] g4-bswap64-overflow rc=2: OBSERVATION ERROR: fatal engine diagnostic; no completed observation
    [immaculate/after with the site rewritten to the codec's literal LemLib.failwithIImpl]: INTERNAL_ERROR:{msg: "Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)"}

and the lane (`…evidence/test_immaculate_h1_full.log`): 9 of 66 rows `MATCH | L=CRASH → INVALID |
L=INVALID` (`zd-z2f04-closedir, g4-bswap64-overflow, zd-z2fl03-nan-to-int, offsetof-union-member,
f3-raw-high-byte-{char-const,int,uchar}, zd-z2m02-device-funptr-call, g5-decode-multichar` — exactly the
crash rows whose Lean side was a seam `panic!`; the two typed `ModelFailure` kills did not move). Two
`IMMACULATE_PANICS` entries were already dead (`CerbMem.memcmpM.getBytes`, `CerbMem.allocator` — typed
kills since C-TF1). `scripts/test_parse.sh:178` greps `failwithIImpl` as a substring and is unaffected
(its `INTERNAL_ERROR_EXPECTED` class widens to seam failures on `*.error.c` inputs; none exist today).

### 3.2 The resolution (fence extension 1)

`scripts/observations.py`: `LEMLIB_FAILWITHI_ORIGIN = b'_private.LemLib.0.failwithIImpl'` replaces the
never-printed literal (replaced, not kept — it is never printed: the impl is `private`; the record's
transcripts are the demonstration); `IMMACULATE_PANICS = {b'_private.CerberusImpl.0.CerberusImpl.typeof_enum_impl'}`
— the one KEPT seam `panic!` (`typeof_enum_impl` is `private`, hence the mangled name, the same shape as
the retired `_private.CerbDecode.0.…` entry); unknown origins remain `ProtocolError('unreviewed panic
origin')`. `scripts/test_observations.py`: the four fabricated `LemLib.failwithIImpl` plant lines carry
the real origin; the immaculate coarse-crash plant's accepted origin is the KEPT site; new
`test_panic_origin_acceptance_after_seam_hygiene`: a REAL captured line accepted under `immaculate` and
`litmus` (`InternalError`) and `fatal engine diagnostic` under `batch` (unchanged class); the old literal
rejected; the stale seam origin `CerbMem.casePtrval` rejected under immaculate; an unknown origin
rejected under both failure policies; the KEPT origin accepted under immaculate only. `python3
scripts/test_observations.py` → `Ran 24 tests … OK`; against HEAD's `observations.py` in a scratch copy
the new plants ERROR/FAIL (`…evidence/codec-plants-vs-HEAD-observations.txt`; that copy's one unrelated
FAIL is the shell-capture test lacking its fixture dir in the scratch). Not touched (outside the
extension, harmless): `scripts/test_observation_lanes.py:59`'s fabricated origin sits in a fuel line
that `FUEL_RECORD` matches regardless of origin.

## 4. H2 — the switch-conditioned arms in the explicit shape (`ee1eaf94d`)

### 4.1 CerbGlobal (fence extension 2)

`PointerArithMode | PERMISSIVE | STRICT` (switches.ml:5, read at :65-67 by `--switches=
strict_pointer_arith`/`permissive_pointer_arith`); `CerbSwitch` gains `pointer_arith (mode)`,
`strict_pointer_equality` (:15), `strict_pointer_relationals` (:18), `zero_initialised` (:32) — names
mirror switches.ml minus the `SW_` prefix, the file's existing convention; `has_strict_pointer_arith`
is now its OCaml body `has_switch (.pointer_arith .STRICT)` (switches.ml:159-160; it was the value
`false` "since `SW_pointer_arith` is not in the lem subset"); eight `has_switch_*_eq : … = false := rfl`
lemmas beside the generic `has_switch_eq`. `SW_PNVI` gained no constructor (not granted); `is_PNVI ()`
stays the value `false`. No generated module matches on `CerbSwitch` (`Global.lean:61` abbreviates it;
the other four uses are signatures), so the new constructors break nothing.

### 4.2 The eight arms (CerbMem.lean; THIS tree's impl_mem.ml lines — the charter's were +8 off, E5)

Guards sit exactly where the OCaml tests the switch; every default computation is byte-for-byte; the
set branch is a loud kill naming the un-ported arm in the `zap_dead_pointers` text pattern.

| Lean def | OCaml guard (this tree) | shape |
|---|---|---|
| `eqPtrval` | `has_switch SW_strict_pointer_equality` :1860-1861 | after the pure `sameProv` let: `if has_switch .strict_pointer_equality then kill … else if sameProv …` |
| `lt/gt/le/gePtrval` | `has_switch SW_strict_pointer_relationals` :1897 / :1915 / :1930 / :1947 | concrete/concrete arm: `if … then kill … else memReturn (a1 < a2)` (etc.) |
| `diffPtrval` | `has_switch (SW_pointer_arith PERMISSIVE)` :1978-1983 | guard wraps the whole match: `if … then (NDkilled …, st) else match …` |
| `effArrayShiftPtrval` | `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` :2345-2346 (Prov_some), :2357-2358 (Prov_none); Prov_device :2362-2364 unguarded | concrete arm: `if (prov ≠ Prov_device) && (has_switch (.pointer_arith .STRICT) ∨ (is_PNVI () ∧ ¬has_switch (.pointer_arith .PERMISSIVE))) then kill … else memReturn …` |
| `allocateObject` | `has_switch SW_zero_initialised` :1318-1324 (the `None` init branch's bytemap choice) | `if initOpt.isNone && has_switch .zero_initialised then (NDkilled …, st) else <unchanged body>` — that branch's own test, hoisted |
| `loadM` | `has_switch SW_strict_reads` :1601-1606 (after the trap check) | `doLoad`: `if isTrap … else if has_switch .strict_reads then (NDkilled …, st) else (NDactive …)` |
| `ptrfromint` | `is_PNVI ()` :2154 | already in the shape (unchanged) |
| `intfromptr` | `has_switch (SW_PNVI AE) ∨ has_switch (SW_PNVI AE_UDI)` :2454-2461 | concrete arm: `if is_PNVI () then kill … else …` — the coarser predicate (implies both; documented in-code) |

Already in the shape before this slice: `killM`'s `SW_forbid_nullptr_free` (:1474) and
`SW_zap_dead_pointers` (:1518/:1552). The Z2-M-20 docstring is rewritten from "not ported, declared" to
"ported in the explicit shape; the set branch is a loud kill", with this table's lines; the
relationals/diff/eff-shift comments follow. Not in the eight (recorded): `load`'s PNVI
`expose_allocations` arm (:1570). The older per-arm `:NNNN` comments elsewhere in CerbMem predate the +8
shift (stated in the docstring; not rewritten — outside the arms this slice touches).

### 4.3 Kernel-visibility test and the census row

`OpaqueFailureTest.lean`: `has_switch .strict_pointer_equality = false`, `.strict_pointer_relationals`,
`(.pointer_arith .PERMISSIVE)`, `(.pointer_arith .STRICT)`, `.zero_initialised`, `.strict_reads`,
`.forbid_nullptr_free`, `.zap_dead_pointers`, `is_PNVI () = false`, `has_strict_pointer_arith () = false`
— all by `rfl`; and an arm IS its default by `rfl`: `gtPtrval loc (concrete a1) (concrete a2) =
memReturn (decide (a1 > a2))` for symbolic `a1 a2`. Z2-M-20 lives in the dated Z2 record
(`2026-09-04_zero-discrepancy-Z2-record.md:316`), not in VALIDATION.md (E1); VALIDATION §3's "(c)
Semantics switches" paragraph gained the sentence that the arms are in the explicit shape and the row is
closed; `lean_frontend/CLAUDE.md`'s CerbGlobal row updated. Dated records were not edited.

### 4.4 Gates at the H2 commit (verbatim; `…evidence/gates_h2_verdicts.txt` — `test_unit`, immaculate, rows 2/3/4/4b as SUMMARY + Baseline pairs, row 10 + `--plant`)

    opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl
    Total: 12 passed, 0 failed
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 16 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVA
    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VAL
    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
    SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-e928pnd5/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-t6b89_dm/report.json

(The register is unchanged by H2: the kills are `NDkilled`/`kill (Other …)` nodes, not census tokens.)

## 5. H3 — named kills and hygiene (`dde3b766b`)

### 5.1 `oomKill`

`def CerbMem.oomKill : kill_reason mem_error := Other (MerrOther "Concrete.allocator: failed (out of
memory)")` — the exact type of the allocator's kill — used at BOTH kill sites (impl_mem.ml:1255-1256,
:1260-1261 mirrors). `CerbMemAllocatorProofs.allocator_below_request_kills` restated as
`allocatorStep sz align st = (NDkilled oomKill, st)`; the proof is unchanged (`simp [allocatorStep,
allocator, h]`). `#print axioms` (verbatim, `…evidence/h3-print-axioms.txt`):

    'CerbMem.allocator_below_request_kills' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
    'CerbMem.oomKill' does not depend on any axioms
    CerbMem.allocator_below_request_kills : ∀ (st : CerbMem.MemState) (sz align : Int),
      st.lastAddress - sz < 0 → CerbMem.allocatorStep sz align st = (NDkilled CerbMem.oomKill, st)

`AllocatorSoundnessTest.lean` unchanged (it matches the string; the runtime value is the same).

### 5.2 The timing/log stubs as identities

Verified the log is read nowhere: outside `CerbUtils.lean` the only mentions of `logRef`/
`timingStackRef`/`STD_impl`/`*_timing_impl` were the allowlist rows and `OPAQUE_WANT`; the `.lem`
callers are `boot.lem:4-10` (target_reps) and `cabs_to_ail_effect.lem:1601-1626` (`STD_ "§…" $ …`,
value position); generated call sites pass the two explicit arguments only (`CerbUtils.STD_ "§6.2.2#3"
(…)`). Now `def begin_timing (_ : String) : Unit := ()`, `def end_timing (_ : Unit) : Unit := ()`,
`def STD_ {α : Type} (_ : String) (x : α) : α := x` — the `IO.Ref`s, impls, `implemented_by`s and the
`[Inhabited α]` binder deleted. By `rfl`: `STD_ s x = x`, `begin_timing s = ()`, `end_timing () = ()`.

### 5.3 A structural `BEq MemValue` (S4 not triggered)

Replaced the `unsafe beqMemValueImpl` / `@[implemented_by] private opaque beqMemValueSafe` sandwich by a
`mutual` block `beqMemValue` / `beqMemValueList` / `beqMemValueMembers` in the shape of the file's own
`memValueSize` (structural recursion over the nested `List` payloads; Lean 4.32.2 accepts it with no
`termination_by`, no `partial`, no `unsafe`, no option). Same OCaml-`(=)`-parity semantics: every payload
compared, `MVfloating` via `Float`'s `==` (NaN ≠ NaN), a length mismatch `false`. **Agreement with the
retired impl:** witnessed BEFORE deletion through `==` on the build that still carried it — 23 pairs
covering every constructor, equal/unequal, nesting, NaN (`…evidence/beq-memvalue-old-witness.{lean,txt}`);
`OpaqueFailureTest.lean`'s `BeqWitness` pins those answers and `main` exits 1 on any disagreement
(plant: flipping `("fnan,fnan", false)` to `true` → `opaque-failure-test: FAIL — the structural BEq
MemValue disagrees …`, exit 1, `…evidence/beq-agreement-plant.txt`); two pairs also by `rfl`.

### 5.4 The census (fence extension 3)

`scripts/unsafebaseio_allowlist.txt`: the 3 CerbUtils KEEP rows (`timingStackRef`, `logRef`, `STD_impl`)
and 13 PIN rows removed (CerbUtils: IMPLBY `begin_timing_impl`/`end_timing_impl`/`STD_impl`, UNSAFEBASEIO
`logRef`/`STD_impl`/`timingStackRef`, UNSAFEDECL `begin_timing_impl`/`end_timing_impl`/`logRef`/`STD_impl`/
`timingStackRef`; CerbMem: IMPLBY + UNSAFEDECL `beqMemValueImpl`); `boundedIntegerImpl`'s three rows stay.
`scripts/check_theorem_axioms.sh` `OPAQUE_WANT`: `CerbUtils.lean:begin_timing`, `end_timing`, `STD_`,
`CerbMem.lean:beqMemValueSafe` removed; history comment extended. **Counts:** boundary-opaque population
**16 → 12**; seam pins **38 → 25**. Verbatim (`…evidence/check_theorem_axioms_h3.txt`):

    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (377 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; …)

The census stays fail-closed: an unregistered opaque or a missing registered one is RED by its own
logic (unchanged code paths; only rows moved).

### 5.5 Gates at the H3 commit (verbatim; `…evidence/gates_h3_verdicts.txt` — same layout as §4.4)

    opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl
    Total: 12 passed, 0 failed
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (377 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVA
    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VAL
    SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
    Baseline check: 0 regression(s), 0 improvement(s)
    SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
    SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
    SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-ci3jlzgl/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-h6dtsq_f/report.json

### 5.6 The FULL battery at the H3 head (`release.py --mode full`, Tier A + B; verbatim per-lane tails)

`scripts/ce python3 scripts/release.py --mode full --out .tmp/seam-hygiene/release-full/run` at `dde3b766b`
(wall ~105 min; box load ≈1.1 throughout — no wall-clock class under pressure; another agent's Lake
build was seen on the box earlier in the slice, not during this run). `summary.txt`, verbatim:

    full: incomplete; 39/39 selected commands completed successfully.
    Source unchanged: False. Complete tier selection: True.
    Release certification: incomplete: reporting/adoption/audit exits require separate evidence.

**39/39 lanes PASSED, 0 FAILED; zero movement of any baseline row.** `Source unchanged: False`
because the working tree was dirty DURING the run with DOCS ONLY — this record, `lean_frontend/CLAUDE.md`
(two doc lines) and the evidence directory being written (`git status` at the end of the run: those
paths and nothing else; no `.lean`, `.sh`, `.py`, `.txt` register or baseline changed — every lane ran
the committed `dde3b766b` sources and binaries). "Release certification: incomplete" is `release.py`'s
standing footer (reporting/adoption/audit exits are separate evidence), not a lane result. release.py's
own evidence directory is 12 GB of raw observations (kept container-side, ephemeral); committed here:
`release-full/summary.txt`, `report.json`, `release_full.log` and the per-lane tails below
(`release-full/release-full-tails.txt`, the last three stdout lines of every lane + release.py's PASSED line):

```
# release.py --mode full at H3 head dde3b766b — per-lane verbatim tails (last 3 stdout lines of each lane) + release.py's PASSED lines
# release log: 39 PASSED / 0 FAILED

=== A1: PASSED A1 (215.8s)
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)

=== A2: PASSED A2 (29.8s)

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK

=== A3: PASSED A3 (51.2s)

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK

=== A4: PASSED A4 (22.7s)

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK

=== A4b: PASSED A4b (23.9s)

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK

=== A4c: PASSED A4c (3.1s)

SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS

=== A5: PASSED A5 (21.9s)

SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE

=== A6: PASSED A6 (2.2s)
==================================================
SUMMARY: total=2 match=2 fail=0
ALL PASSED

=== A6b: PASSED A6b (3.5s)
==================================================
SUMMARY: total=7 match=7 fail=0
ALL PASSED

=== A7: PASSED A7 (10.4s)
batch diagnostic producers: 8/8 passed
cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
ALL PASSED

=== A8: PASSED A8 (8.9s)
Success rate:   100% (of cerberus successes)

ALL PASSED

=== A9: PASSED A9 (16.7s)
  LEAN_FAIL:  0

SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0

=== A10: PASSED A10 (16.5s)

==================================================
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)

=== A11: PASSED A11 (57.8s)

Checking against baseline (exact match, fail-closed both directions): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/tests/cn_coverage/baseline.txt
BASELINE OK (213 entries, exact match)

=== A12.1: PASSED A12.1 (4.9s)
  REVERTED (the committed expectations):
  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
test_address_space: SELFTEST OK (14 plants — P1 the discriminator's derived pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain 

=== A12.2: PASSED A12.2 (4.4s)

  EXPECT OK    18 pinned rows = 18 observed cases, every token identical
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)

=== B1: PASSED B1 (606.0s)
==================================================
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
ALL PASSED

=== B2: PASSED B2 (22.9s)
batch diagnostic producers: 8/8 passed
cabs bytes probe: 128 raw bytes 0x80..0xFF crossed the bridge as one code point each (valid UTF-8 JSON; Lean sizeof = 129)
ALL PASSED

=== B3: PASSED B3 (14.9s)
Success rate:   100% (of cerberus successes)

ALL PASSED

=== B4: PASSED B4 (45.3s)
check_driver_fresh: recorded lean stamp (bin a4c5fef9c6684cd6623acf0d8839e498f5d14e9fb720254642170fc717b908ff, src 795a03670377b004e9f10c9e6bc8e6861fec9e32988e2648504f69c219363e81)

test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)

=== B5: PASSED B5 (66.5s)
  KILL           illtyped-store      

OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in

=== B6.1: PASSED B6.1 (162.3s)
  lean:   exit=0 verdict=Specified(0)
  expect: Specified(0)
test_speclab: PASS (both pipelines agree on Specified(0))

=== B6.2: PASSED B6.2 (2.2s)
  lean:   exit=0 verdict=Specified(2)
  expect: Specified(2)
test_speclab: PASS (both pipelines agree on Specified(2))

=== B6.3: PASSED B6.3 (9.0s)
  PASS  exec [plant]: Specified(1) — the wrong-operator plant is RED in-logic
CoreGateTest: ALL PASSED
test_speclab_divmod: PASS (--gate)

=== B6.4: PASSED B6.4 (8.4s)
  PASS  exec [getarr plant]: Specified(1) — the wrong-index plant is RED in-logic
ByteArrGateTest: ALL PASSED
test_speclab_bytearr: PASS (--gate)

=== B6.5: PASSED B6.5 (8.8s)
  PASS  leak [build-only]: final allocations = 1
ListGateTest: ALL PASSED
test_speclab_list: PASS (--gate)

=== B6.6: PASSED B6.6 (9.5s)
  PASS  leak [build-only]: final allocations = 1
TreeGateTest: ALL PASSED
test_speclab_tree: PASS (--gate)

=== B6.7: PASSED B6.7 (8.2s)
  PASS  exec [swap plant]: Specified(9) — the lost-update plant is RED in-logic at post-state cell 1, byte 0
SeedGateTest: ALL PASSED
test_speclab_seed: PASS (--gate)

=== B7: PASSED B7 (1299.0s)

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK

=== B8.1: PASSED B8.1 (13.4s)
PLANT OK   [sweep/busy → LEAN_TIMEOUT]: ci	tests/ci/0001-emptymain.c	LEAN_TIMEOUT	TIMEOUT(cpu 2.99s of 3.00s wall; timeout 3s)
PLANT OK   [classifier fail-closed]: HARNESS ERROR: time record /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/scripts/hang-plant.ly50C06wsj/does-not-exist.time missing
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)

=== B8.2: PASSED B8.2 (226.5s)
PLANT OK   [libxml2 -> Lean OOM-KILLED]: [chvalid_battery_00] FAIL: Lean OOM-KILLED (exit 137; cgroup memory cap CERB_TEST_MEM_MAX=4G breached — memory.events oom_kill=1)
PLANT OK   [gcc_oracle exit(137) native -> compared (AGREE gcc=137 lean={137}), not SKIP_GCC_KILL]: [1/1] AGREE  .tmp/scripts/kill-plant.ai7bRSCbt0/gcc137/exit137.c: gcc=137 lean={137}
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)

=== B8.3: PASSED B8.3 (6.3s)
PLANT OK   [--fuel without an argument refused]

test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)

=== B8.4: PASSED B8.4 (15.8s)
PLANT OK [measure/ordinary]
PLANT OK [exec/malformed]
test_failstop_plant: PASS (11 class and rejection checks)

=== B9: PASSED B9 (1322.5s)
PLANT OK   speclab_seed: descendant-oom
PLANT OK   speclab_seed: oracle-exit2
observation lane plants: 93/93 passed

=== B10.1: PASSED B10.1 (117.3s)
859/859 semantic_agreement: corpus/p12_pt_midpoint (pristine 0.0s, fork 0.0s)
Independent oracle scope: tier-b; 859 rows in 117.0s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/seam-hygiene/release-full/run/B10.1/independent-oracle/report.json

=== B10.2: PASSED B10.2 (1.8s)
3/3 plant_ok: plant/withheld-row:minimal/112-allocator-exhausted-single-request.c — minimal/112-allocator-exhausted-single-request.c: with its register row -> reviewed_difference; row withheld -> difference (completed semantic observations differ)
Independent oracle scope: plant; 53 rows in 1.6s; source unchanged: True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/seam-hygiene/release-full/run/B10.2/independent-oracle/report.json

=== B11.1: PASSED B11.1 (16.4s)
  UNPLANTED:
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every
check_failure_reach: SELFTEST OK (5 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally — and the unplanted register green)

=== B11.2: PASSED B11.2 (7.2s)
check_failure_reach: instrument built + census taken in 7 s (FAILURE_REACH rows 21249, FAILURE_RANGE rows 11307; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1253,"handwritten:pure_or_unresolved":121})
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row

=== B12: PASSED B12 (505.6s)
4/4 semantic_agreement: libxml2/chvalid/chvalid_battery_03 (pristine 84.3s, fork 55.6s)
Independent oracle scope: libxml2_chvalid; 4 rows in 505.4s; source unchanged: True
Independent oracle: passed; {'semantic_agreement': 4}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/seam-hygiene/release-full/run/B12/independent-oracle/report.json

=== summary.txt
full: incomplete; 39/39 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

## 6. Errata to the charter's §1 (each re-checked against this tree)

- **E1** Z2-M-20 is not a row of `VALIDATION.md` §3; it lives in the dated Z2 audit/record
  (`2026-09-03_zero-discrepancy-Z2-audit.md:201`, `2026-09-04_zero-discrepancy-Z2-record.md:316`);
  VALIDATION §3's relevant text is the "(c) Semantics switches" paragraph (updated).
- **E2** four of the eight switches had no `CerbSwitch` constructor (resolved by fence extension 2).
- **E3** `OPAQUE_WANT` lives in `check_theorem_axioms.sh`, not the allowlist (resolved by extension 3).
- **E4** the library constant is top-level `failwithI` (no `LemLib` namespace); the four leaf seams needed
  `import LemLib`; the census tokenizer requires the bare spelling.
- **E5** impl_mem.ml cites in this tree (+8 vs the charter): `SW_strict_pointer_equality` :1860;
  relationals :1897/:1915/:1930/:1947; `diff_ptrval` PERMISSIVE :1978; `eff_array_shift_ptrval`
  :2273-2274, :2292, :2345-2346, :2357-2358 (device :2362-2364); `allocate_object` :1318; `load` :1601;
  `ptrfromint` :2154; `intfromptr` :2454 and its guard is the AE/AE_UDI pair, not `is_PNVI ()`;
  `SW_forbid_nullptr_free` :1474; `SW_zap_dead_pointers` :1518/:1552; the allocator kill sites are
  `CerbMem.lean:2133`/`:2140` at the charter head.
- **E6** the runtime panic site of `failwithI` is `_private.LemLib.0.failwithIImpl`, not
  `LemLib.failwithIImpl` — the S3 trigger and a latent codec defect (§3).
- **E7** the register's `msg` column is a derived key and must follow a prefixed message (14 rows).
- **E8** paired worker definitions related by `rfl` theorems must carry IDENTICAL leaf messages (§2.1).
- **E9** the primed worktree was stale on both generated trees and both binaries (§1.2).

## 7. Open items (for the operator; none blocks the slice)

- `CerbTags.lean:34` (`tagDefsUnreachable`) still panics under its own name — a tripwire outside the exec
  closure and outside the fence; deliberately NOT in `IMMACULATE_PANICS`, so under the immaculate policy
  it would read `unreviewed panic origin` — the loud behaviour a tripwire wants.
- `scripts/test_observation_lanes.py:59` carries a fabricated `LemLib.failwithIImpl` in a fuel line
  (matched by `FUEL_RECORD` regardless of origin; harmless; outside the extension).
- VALIDATION.md's gate-table text for `check_theorem_axioms.sh` says "15 registered rows since
  2026-09-05" — it was 16 before this slice and is 12 now; outside the fence (§6 of VALIDATION).
- `SW_PNVI` has no `CerbSwitch` constructor: `is_PNVI ()` stays the value `false`, and `intfromptr`'s
  guard uses it as the coarser predicate (documented in-code). `load`'s PNVI `expose_allocations` arm
  (:1570) is not in the explicit shape (not one of the eight).
- The older per-arm `:NNNN` comments in CerbMem predate the part-one +8 shift of impl_mem.ml.
- `test_parse.sh:178`'s `INTERNAL_ERROR_EXPECTED` class now also covers seam failures on `*.error.c`
  inputs (none exist on the corpora today).

## 8. Consumer note (cerberus-sl)

You can now state, against the H3 head: **no hand-written seam failure in the execution dependency
closure has a kernel equation** — every one of the register's 98 sites is LemLib's `opaque failwithI`
(your §1 item 3's two probes fail by `rfl`, pinned by `test/Unit/OpaqueFailureTest.lean`; the reach
classes of `scripts/failure_reach_register.txt` remain reviewed claims, not theorems). **Every
switch-conditioned arm of impl_mem.ml reduces to its default by `rfl`**: `CerbGlobal.has_switch sw =
false` for every `sw` (`has_switch_eq`) and the eight named lemmas, `is_PNVI () = false`,
`has_strict_pointer_arith () = false`; `CerbSwitch` now carries `strict_pointer_equality`,
`strict_pointer_relationals`, `pointer_arith PERMISSIVE|STRICT`, `zero_initialised` (item 5, seam-only
part). **`CerbMem.oomKill`** names the allocator's kill and `allocator_below_request_kills` is stated
with it (item 4, interim; `MerrOutOfMemory` remains a shared-model slice). **The timing/log stubs are
value identities** (`CerbUtils.STD_ s x = x` by `rfl`) and **`BEq MemValue` is structural**
(`CerbMem.beqMemValue`, kernel-transparent) (item 9). Boundary-opaque population 12; the remaining
opaques are the digest boundary, `bounded_integer`, the enum registry (items 1/2 — separate slices),
`CerbFuel.fuelExhaustedLoc` and `CerbFail.modelFailStopLoc`.

## 9. Evidence (`2026-09-18_seam-hygiene-evidence/`)

H1: `h1-candidate.patch` (the candidate as applied; historical), `h1-site-table.md`, `h1_edit.py`,
`h1_register.py` (with its pairing defect, §2.2), `probe-before.*`, `probe-after.*`, `before-*`/`after-*`
stderr + rc + line1 for the three programs, `after-unmangled-demo.stderr`, `codec-before-after.txt`,
`codec-plants-vs-HEAD-observations.txt`, `check_theorem_axioms_before.txt`, `check_failure_reach_before.txt`,
`check_failure_reach_h1.txt`, `test_unit_h1_full.log` + `test_unit_h1_verdicts.txt`,
`test_immaculate_h1_full.log` (the S3 RED run), `test_immaculate_h1_green.txt` + `_full.log`,
`gates_h1_rows2-4b_row10_full.log` + `gates_h1_verdicts.txt`. H2: `gates_h2_full.log` +
`gates_h2_verdicts.txt`. H3: `beq-memvalue-old-witness.{lean,txt}`, `beq-agreement-plant.txt`,
`h3-print-axioms.txt`, `check_theorem_axioms_h3.txt`, `gates_h3_full.log` + `gates_h3_verdicts.txt`,
`release-full/` (`summary.txt`, `report.json`, `release_full.log`, `release-full-tails.txt`). H4 (§10): `test_unit_h4_full.log` + `test_unit_h4_verdicts.txt`, `gates_h4_full.log` + `gates_h4_verdicts.txt`, `release-fast-h4/{summary.txt,report.json}`, `record-quote-check-h4.txt` (the M1 re-check of every quoted line). Container-side
scratch (`.tmp/seam-hygiene/`, build logs, cabs-jsons) is ephemeral and not committed.

## 10. Audit fixes (H4 `cef347c6c`) — the independent pre-merge audit and what changed

**The audit:** branch `audit/seam-hygiene` @ `05d208f45`, report
`lean_frontend/docs/2026-09-19_seam-hygiene-audit-premerge.md` (+ its evidence dir), worktree
`worktrees/cerberus-lean-audit/seam-hygiene` (read-only to the worker). Verdict [AGENT auditor]:
**MERGE-WITH-FIXES, no MAJOR**; it reproduced everything — 0 hunks of class (f) (a hunk changing a
default arm), the FULL battery clean at `34b8e15a8` (`full: passed; 39/39 … Source unchanged: True.`),
row 10 `{822, 28, 7, 2}`, the structural `BEq` against the retired impl on 1156 pairs with 0
disagreements. The orchestrator ([AGENT orchestrator], 2026-09-19) directed the fixes below as ONE
commit plus this amendment, with the FULL battery NOT re-run for a constructor reorder + comments + docs
— the audit's clean FULL at `34b8e15a8` is the reference; gates at the H4 head: `test_unit.sh`,
`release.py --mode fast`, `test_immaculate.sh`, row 10 + `--plant`.

### 10.1 Per finding → change

| finding | change (file:line at `cef347c6c`) |
|---|---|
| **M4** MINOR — `CerbSwitch`'s derived `Inhabited` default had moved (`.strict_reads` → `.pointer_arith .PERMISSIVE`) because H2 placed the new constructors FIRST: kernel-visible, unclaimed (no consumer: every use is a `has_switch …` call) | `lean_frontend/CerbGlobal.lean`: the four constructors are APPENDED after the lem subset (`… | cheri | pointer_arith (mode) | strict_pointer_equality | strict_pointer_relationals | zero_initialised`) with a comment naming the hazard; `default = .strict_reads` again, PINNED by `example : (default : CerbSwitch) = .strict_reads := rfl` beside the `has_switch_*_eq` lemmas and by the same example in `test/Unit/OpaqueFailureTest.lean`. Lesson recorded: a derived instance is constructor-order-dependent — an E-list item the slice should have caught (the same hazard class as the outcomes design's generated-default finding). |
| **M1** MINOR — record §2.6 quoted `375 files` under "verbatim"; no evidence file carries it (H1 evidence: `377`; BEFORE: `374`) | Record §2.6, §4.4, §5.5 REBUILT mechanically from the evidence files (`test_unit_h1_verdicts.txt`, `test_immaculate_h1_green.txt`, `gates_h{1,2,3}_verdicts.txt`): every quoted line is now a stand-alone line pulled from its file (my labels — `row 2:`, `(each …)` — moved out of the code blocks; the abbreviated `…` lines replaced by the full lines). Re-check of EVERY quoted line of this amended record (`…evidence/record-quote-check-h4.txt`; the check excludes its own output): 216 quoted lines, each an exact substring (ellipsis-split) of some evidence file, EXCEPT 8 that are labelled as such in the text: the 5 lines of the register gate's first RED run (§2.2 — quoted from the terminal; that log was overwritten; audit N4) and the 3-line pre-H1 source excerpt of `observations.py:207-209` (§3.1 — reproducible as `git show 0eafc94a4:scripts/observations.py`). The `375` was a hand-edited number in a verbatim block: the house rule was breached and is now met. |
| **M2** MINOR — `h1-site-table.md` rows 828/837/1190 named `_append`/`_indexed` prefixes the code does not carry | The three rows now state the prefixes actually in the code (`CerbMem.memValueToBytes:` / `CerbMem.reconstructValue:` — the SAME prefix as the paired worker, §2.1) and say the edit plan's prefix was equalised before the build (the table had been generated from the plan, not the tree). |
| **M3** MINOR — `VALIDATION.md:1027-1030` still enumerated the deleted `CerbMem.beqMemValueSafe` as a runtime-boundary row with a live VF-3 obligation; `TODO.md:232` likewise; `VALIDATION.md:722` said "15 registered rows" | `VALIDATION.md`: the bullet is a LEFT-the-boundary history line pointing at §5.3 (the VF-3 correspondence obligation for this row CLOSED — witnessed 23 pairs here, 1156 by the audit); the gate-table parenthetical reads "12 registered rows since seam-hygiene H3, 2026-09-19 — …; history: 15 … 16 … 12"; `TODO.md`'s residual retires `beqMemValueSafe` (F7's digest obligation stays). Both files are in the fence for this ([AGENT orchestrator]). |
| **N1** NOTE — `oomKill`'s docstring cites were −3 off | `CerbMem.lean` oomKill docstring: `impl_mem.ml:1258-1259 and :1263-1264 in this tree; the allocator's older per-line comments are −3 from these`. |
| **N2** NOTE — the `intfromptr` comment inverted the implication | `CerbMem.lean` intfromptr arm comment: `is_PNVI ()` "is IMPLIED BY either disjunct — and also by `SW_PNVI PLAIN`, where the OCaml takes the default arm — so its `false` (Z-24) refutes both". Record §4.2's row says the same ("the coarser predicate"). |
| **N3** NOTE — `doLoad`'s header said strict_reads is "refused set" two lines above the explicit guard | `CerbMem.lean` doLoad header: the PNVI `expose_allocations` arm (:1570) "is DECLARED (refused set, Z-24; not one of the eight explicit arms); SW_strict_reads (:1601-1606) is the EXPLICIT `if has_switch .strict_reads then <loud kill> else …` guard below (seam-hygiene H2)". |
| **N8** NOTE (optional — taken, trivial with a plant) — `LEAN_PANIC`'s free-form location field absorbed a second space after the origin | `scripts/observations.py`: `LEAN_PANIC = rb'PANIC at ([^ \r\n]+) ([^ \r\n]+:[0-9]+:[0-9]+): (.+)'` (the location has no spaces), payload = group 3; plant `test_panic_origin_location_field_is_not_free_form` in `scripts/test_observations.py`: the real line accepted under immaculate/litmus; the same line with a second space after the origin, or a space inside the location, is no Lean panic header → `fatal engine diagnostic` (the FATAL class, fail-closed). `python3 scripts/test_observations.py` → `Ran 25 tests … OK`. |

### 10.2 Recorded observations (no change; the auditor's notes stand)

- **N4** — the §2.2 FAIL transcript has no evidence file: quoted from the worker's terminal; the log was
  overwritten by the green re-run. Disclosed in the record then and now; nothing can restore it.
- **N5** — the KEPT origin in `IMMACULATE_PANICS`, `_private.CerberusImpl.0.CerberusImpl.typeof_enum_impl`,
  is INFERRED from Lean's private-name mangling (`_private.<module>.0.<decl>`, the same shape the
  lane-witnessed `_private.CerbDecode.0.CerbDecode.decode_character_constant_aux` entry had) — it has NOT
  been witnessed by a run. No `tests/immaculate` (or other corpus) program reaches the unregistered-enum
  panic: `typeof_enum` is consulted only for enum tags the same elaboration registered, and a use of an
  unregistered tag is a constraint violation the frontend rejects earlier; constructing a reaching program
  was not attempted. If the name is wrong, the failure mode is the loud one (`unreviewed panic origin`),
  never a silent acceptance.
- **N6** — the fork oracle CLI ACCEPTS `--switches=strict_reads` (and answers as without); the Z-24 refusal
  is the LEAN driver's, and no lane passes switches to the oracle. The record's "the switch set is refused"
  means: refused by this port and never set by any lane on either engine.
- **N7** — the SET branches are refusals of the whole operation, not ports of the OCaml arm (e.g. `loadM`
  kills on EVERY load under `SW_strict_reads`, where the OCaml fails only on `MVunspecified`). This is the
  charter's chosen shape (`<loud kill: … is not ported …>`, the `zap_dead_pointers` precedent), unreachable
  under the refused set; porting the arms is a different slice.
- **N9** — the register seal covers the eight class columns, not the `need`/`cite`/`note` prose (by design,
  `check_failure_reach.py:SEALED`); "every row sealed" in this record means exactly that.
- **N10** — the audit's primed worktree was stale on both sides, as the worker's was (E9): a second
  occurrence of the `new-worktree.sh` priming shape (it copies `_build`/`generated/` from the primary,
  which had moved past its binaries) — outside this slice; for the operator.

### 10.3 Gates at the H4 head `cef347c6c` (verbatim; `…evidence/test_unit_h4_verdicts.txt`, `gates_h4_verdicts.txt`, `release-fast-h4/`)

`test_unit.sh` (before the commit, on the H4 content; the same run is A1 of the fast battery below):

    Total: 12 passed, 0 failed
    check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 12 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
    check_theorem_axioms: C2 ratchet OK (378 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 25 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-
    opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce; every switch-conditioned arm reduces to its default (has_switch … = false by rfl

`release.py --mode fast` at the head:

    PASSED A1 (296.4s)
    PASSED A2 (58.2s)
    PASSED A3 (51.8s)
    PASSED A4 (22.8s)
    PASSED A4b (24.3s)
    PASSED A4c (3.2s)
    PASSED A5 (25.4s)
    PASSED A6 (2.2s)
    PASSED A6b (3.6s)
    PASSED A7 (10.4s)
    PASSED A8 (8.9s)
    PASSED A9 (16.8s)
    PASSED A10 (16.7s)
    PASSED A11 (58.2s)
    PASSED A12.1 (4.9s)
    PASSED A12.2 (4.5s)
    fast: passed; 16/16 selected commands completed successfully.
    Source unchanged: True. Complete tier selection: True.

`test_immaculate.sh`, row 10, row 10 `--plant` at the head:

    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and th
    Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-77rkym22/report.json
    Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/seam-hygiene/.tmp/upstream-oracle-8ryk4vno/report.json

FULL battery: NOT re-run ([AGENT orchestrator]: a constructor reorder + comments + docs); the reference
is the audit's clean FULL at `34b8e15a8` — `full: passed; 39/39 selected commands completed successfully.
Source unchanged: True.` (audit report §2.7).
