# Record — seam hygiene slice: STOPPED at S3/S1 after H1 was built and gated (2026-09-18/19)

**Status:** [AGENT worker, Claude Fable] interim record ending the slice chartered in
`2026-09-18_charter-seam-hygiene.md` (branch `arc/seam-hygiene`, worktree
`worktrees/cerberus-lean-arc/seam-hygiene`, charter head `0eafc94a4` on mainline `0457732e1`).
**Outcome: H1 was implemented, built and gated; it is NOT committed** because the charter's
stop rule **S3** fired (something pins the panic SITE name captured by `scripts/observations.py:53`)
and, as its direct consequence, **S1** (the immaculate lane's classes change: 9 rows). Per the stop
protocol ("commit what is green, write the interim state into the record, end the turn") this record
plus its evidence directory is the only commit; the complete H1 candidate is preserved as a patch that
applies cleanly to the charter head (`2026-09-18_seam-hygiene-evidence/h1-candidate.patch`, 13 files).
H2 and H3 were not started; their pre-work surfaced two further charter-vs-fence conflicts (§4, §5) that
the re-charter should settle at the same time. Working tree at this commit: clean; `generated/` re-synced
to the sources (`make lean-prelude-src`); the built binaries correspond to the H1 CANDIDATE, not to HEAD —
run `make lean-prelude-src` + `build_lean` before trusting them.

## 0. Rulings (by pointer)

Charter §0 verbatim quotes: [USER 2026-09-18] "Great, charter the planned slice"; [USER 2026-09-17]
"Makes sense, Let's do the sequence as you propose…"; the consumer's principle (cerberus-sl C3.10);
[USER 2026-09-08] "we should *NOT* be building anything new out-of-policy"; [USER 2026-09-11]
execution mode. All decisions below are [AGENT] unless marked otherwise.

## 1. What happened, in order (derived timeline)

1. Read the charter and every cited file; re-checked each cite against this tree (errata: §6).
2. The primed worktree was STALE on both sides against its own sources (both generated trees and both
   driver binaries predated the mainline's last landing): `tools/check_driver_fresh.sh --check-lean`
   → `CERB_DRIVER_STALE` (CerbMem.lean/Main.lean not propagated, CerbMemAllocatorProofs.lean copy
   missing); `check_lem_sync.sh --check` → `CERB_LEM_SYNC_STALE`; `build_cerberus` failed on the stale
   OCaml tree (`driver.ml:1948 … Impl_mem.initial_mem_state has type Z.t -> Impl_mem.mem_state`).
   Rebuilt at the charter head before any "before" evidence: `make clean-prelude-src prelude-src`,
   `build_cerberus`, `make lean-prelude-src`, `build_lean` (stamps recorded; §9 logs).
3. BEFORE evidence at `0eafc94a4` (§2.4, §2.5): both orchestrator probes compile by `rfl`; three
   REACHABLE immaculate programs abort at their seam sites (exit 134); `check_theorem_axioms.sh`
   opaque population 16, seam pins 38; `check_failure_reach.sh` OK (233 = 233).
4. H1 applied (§2.1–2.3): 109 `panic!` sites → `failwithI` (98 register rows + 11 out-of-closure
   same-edit sites; 19 with a self-locating prefix; 1 kept), `import LemLib` added to the four leaf
   seams, register re-recorded + `--reseal`, hermetic test written and registered.
5. Two pair-equality theorems in CerbMem broke (`memValueToBytes_lemFuel = memValueToBytes_append_lemFuel`,
   `reconstructValue_lemFuel = reconstructValue_indexed_lemFuel`) because my prefixes gave the PAIRED
   sites different messages and an opaque leaf is definitionally equal only to itself; fixed by giving
   each pair the SAME prefix (§2.1 note). A real consequence of H1 worth stating: those theorems now
   ENFORCE message identity between the paired workers.
6. My register re-keying script paired the 11 sites sharing the old 60-char key
   `"the concrete memory model requires a complete implementatio` by line order and mis-keyed the
   `maxIval`/`minIval` rows; the gate named the exact NEW/STALE pairs and the two rows were re-keyed
   from the live census (§2.2). Final register gate: GREEN.
7. FAST-GATE `test_unit.sh` (via `scripts/ce`): GREEN — 12/12 exes incl. the new test, every gate OK
   (§2.6). AFTER runtime transcripts: same message text, same exit 134, PANIC SITE now
   `_private.LemLib.0.failwithIImpl` (§2.5).
8. **S3.** The AFTER panic origin is the PRIVATE-mangled `_private.LemLib.0.failwithIImpl`, not
   `LemLib.failwithIImpl` (charter §1 erratum E6). `scripts/observations.py:207-209` accepts, under the
   `immaculate`/`litmus` policies, ONLY the literal `LemLib.failwithIImpl` (a name the binary never
   prints — a latent instrument defect) or, under `immaculate`, a member of `IMMACULATE_PANICS` (eight
   seam SITE names). The codec run directly on the captured stderr: BEFORE `INTERNAL_ERROR:{msg:…}`,
   AFTER `OBSERVATION ERROR: unreviewed panic origin` (§3). `test_immaculate.sh`: 9 rows
   `MATCH | L=CRASH → INVALID | L=INVALID` (§2.6) — S1 as well. STOP.
9. The H1 candidate saved as a patch; working tree restored to HEAD; copies re-synced; this record.

## 2. H1 — the work (a candidate, not a deliverable)

### 2.1 The sites

`2026-09-18_seam-hygiene-evidence/h1-site-table.md` is the per-site table (file, post-edit line,
kernel owner from the register, reach class, action). Derived tally (from the table): **98 register
rows REPLACED** (all 98 hand-written `panic!` rows: CerbMem 44, CerbFS 36, CerbDecode 7, CerbUtils 4,
CerberusImpl 3, Main 1, CoreParser 1, CerbLocation 1, CerbFloat 1); **11 out-of-closure sites REPLACED
with the trivially same edit** (CerbMem: `memValueToBytes_append_lemFuel` ×2, `reconstructValue_indexed_lemFuel`
×4, `concurReadIval`, `cheriPointerHashPrintf`, `getIntrinsicTypeSpec`; `CerbLocation.simpleLocation`;
`CerbFloat.of_string`) — [AGENT] taken so no fence file mixes the two leaves; **1 KEPT**:
`CerberusImpl.lean:69` (`typeof_enum_impl`, `pure (panic! …)` inside the `unsafe` enum-registry impl —
the enum seam is fence-FORBIDDEN, and it is not a register row). The default is REPLACE and every other
site, including `Main.lean:70` (`loadCoreImpl`'s unreachable `.error` arm — a pure position whose value
enters the impl map) and `CoreParser.lean:2413` (`scanStep`'s fuel sentinel — pure), was replaced.

**Self-locating prefixes (19 sites)** — [AGENT] rule: a message that names NO site (the OCaml text is
`"case_ptrval"`, `"hd"`, `"TODO: …"`, `"unknown function pointer: …"`, `"failed: bytes_of_int(…"`,
`"the concrete memory model requires a complete implementation …"`, or the variable `e`) gains the
prefix `<Module>.<fn>: ` and keeps the OCaml text as its suffix; a message already carrying an OCaml
`Module.fn:`/`fn:` name or the `CerbFS refusal (…)` form is byte-identical. The prefixed sites:
`CerbMem.targetPtrSize`, `sizeofCtype` ×2, `alignofCtype` ×2, `intToBytes`, `memValueToBytes` ×4 (both
workers, SAME prefix — see below), `reconstructValue` ×2 (both workers, SAME prefix), `casePtrval`,
`maxIval`, `minIval`, `concurReadIval`, `arrayShiftPtrval`, `CerbLocation.simpleLocation`,
`Main.loadCoreImpl`. **Constraint discovered:** `CerbMem.lean:962` and `:1280` are `rfl` arms of the
pair-equality theorems `memValueToBytes_lemFuel = memValueToBytes_append_lemFuel` and
`reconstructValue_lemFuel = reconstructValue_indexed_lemFuel`; with `panic!` the paired leaves differed
only in the macro's decl/line and both reduced to `default`; with `failwithI` they are defeq only if the
message STRINGS are identical. Verbatim (first attempt): `error: generated/CerbMem.lean:962:11: Tactic
`rfl` failed: The left-hand side` … `error: generated/CerbMem.lean:1280:11: Tactic `rfl` failed`.
Fixed by the same prefix on both members of each pair; CerbMem then builds.

**Imports:** `CerbUtils`, `CerbLocation`, `CerbFloat`, `CerbFS` had NO imports (leaf modules), so bare
`failwithI` was `Unknown identifier` (verbatim: `error: generated/CerbFS.lean:253:6: Unknown identifier
`failwithI`` ×36, and the targets `CerbUtils`/`CerbLocation`/`CerbFloat`/`CerbFS` logged failures);
`import LemLib` added as line 1 of each (the spelling every generated module uses). `failwithI` is a
TOP-LEVEL LemLib constant (no `LemLib` namespace exists: LemLib.lean's only namespaces are `Vector`,
`Pset`, `Pmap`, `LemUnsupported`), so the charter's `LemLib.failwithI` is a shorthand (E4) — and the
census tokenizer (`[\w][\w'.!?]*`) would lex a qualified spelling as ONE token that is not
`failwithI`, silently dropping the site from the census; the bare spelling is load-bearing for the gate.

### 2.2 The register re-record

`scripts/failure_reach_register.txt`: exactly the 98 hand-written `panic!` rows edited — 84 rows in
`token`+`seal` only; 14 rows in `token`+`msg`+`seal` (the `msg` column is the census's derived KEY —
the first 60 characters after the token — so it necessarily follows a prefixed message; E7); `file`,
`definition`, `scope`, `position`, `position_reviewed`, `reach`, `need`, `cite`, `note` byte-identical on
every row (verified column-by-column on the diff); tally line unchanged. Reseal line, verbatim:
`check_failure_reach: resealed 233 rows of scripts/failure_reach_register.txt (review change: commit with the justification)`.
Justification = charter H1. Gate after the fix of the two mis-keyed rows (§1 step 6), verbatim
(`…evidence/check_failure_reach_h1.txt`):

    check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent)

Position classes UNCHANGED on all 98 rows (the classifier keys on the tokens around the unit, not on the
token itself) — the possibility the charter flagged did not materialise.

The mis-keying incident (step 6), quoted from the FIRST `test_unit.sh` run (its log was overwritten by
the green re-run; these lines are verbatim from the worker's terminal):

    check_failure_reach: FAIL —
      NEW pure exec-closure site (no register row — review it): lean_frontend/CerbMem.lean:1419 CerbMem.maxIval failwithI «"CerbMem.maxIval: the concrete memory model requires a compl» position=LET-BOUND scope=EXEC
      NEW pure exec-closure site (no register row — review it): lean_frontend/CerbMem.lean:1447 CerbMem.minIval failwithI «"CerbMem.minIval: the concrete memory model requires a compl» position=ARGUMENT scope=EXEC
      STALE register row (site gone or its key moved): lean_frontend/CerbMem.lean CerbMem.maxIval failwithI «"CerbMem.memValueToBytes_append: the concrete memory model r» scope=EXEC
      STALE register row (site gone or its key moved): lean_frontend/CerbMem.lean CerbMem.minIval failwithI «"CerbMem.memValueToBytes_append: the concrete memory model r» scope=EXEC

(`…evidence/h1_register.py` is the script with the line-order pairing defect, kept as the record of what
was run; the correction re-keyed the two rows from the live census by kernel owner. The gate caught it
both directions — the tripwire works.)

### 2.3 The hermetic test

`lean_frontend/test/Unit/OpaqueFailureTest.lean` (in the patch; registered as `opaque-failure-test` in
`lakefile.toml` with `moreLinkArgs = ["native/md5.o"]` like every CerbMem-importing exe, and in
`scripts/test_unit.sh`): `#guard_msgs` on the two FAILING tactic `rfl`s (a transparent leaf would make
`rfl` succeed, the expected error would be missing, and the build RED — the loud direction), a
text-independent check that `failwithI` is an `opaqueInfo` in the compiled environment (`#eval` in
`CommandElabM`, needs `import Lean.Elab.Command`), positive controls (default arms of `combineProv`/
`bytesToInt` reduce by `rfl`; registered arms `#check`), `main` prints PASS. Verbatim run line:
`opaque-failure-test: PASS — the two seam identities are not rfl-provable (#guard_msgs on failing rfl), `failwithI` is opaque in the environment, default arms still reduce`.

### 2.4 Kernel probes, before/after (verbatim; `…evidence/probe-before.lean`, `probe-after.txt`)

BEFORE (charter head, fresh build): `../scripts/lean_probe.sh ../.tmp/seam-hygiene/ProbeBefore.lean` →
rc 0, no diagnostics — both `example … := rfl` compile. AFTER (H1 candidate):

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
`--cabs-json` and `LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --first`; exit status 134 on every run,
stdout empty on every run (the charter asked for two; the third shows a prefixed message):

| program (site) | BEFORE `0eafc94a4` | AFTER H1 |
|---|---|---|
| `g4-bswap64-overflow` (`CerbUtils.gcc_builtin_bswap64`, text unchanged) | `PANIC at CerbUtils.gcc_builtin_bswap64 CerbUtils:172:4: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)` |
| `zd-z2fl03-nan-to-int` (`CerbFloat.truncToInt`, text unchanged) | `PANIC at CerbFloat.truncToInt CerbFloat:426:4: CerbFloat.truncToInt: nan/inf (OCaml Z.of_float raises Z.Overflow)` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: CerbFloat.truncToInt: nan/inf (OCaml Z.of_float raises Z.Overflow)` |
| `zd-z2m02-device-funptr-call` (`CerbMem.casePtrval`, PREFIXED) | `PANIC at CerbMem.casePtrval CerbMem:1385:4: case_ptrval` | `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: CerbMem.casePtrval: case_ptrval` |

Same message text (or the OCaml text as the suffix of the self-locating prefix), same exit status; only
the `PANIC at <site>` head moves — to the PRIVATE-mangled name.

### 2.6 Gates run on the H1 candidate (verbatim verdict lines)

`scripts/ce ./scripts/test_unit.sh` (`…evidence/test_unit_h1_full.log`, verdicts in
`test_unit_h1_verdicts.txt`): `Total: 12 passed, 0 failed`;
`check_theorem_axioms: generated-tree census OK (219 files: 0 axioms, boundary-opaque population = the 16 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)`;
`check_theorem_axioms: C2 ratchet OK (375 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 38 pinned path-qualified counted rows exactly incl. the extern class; …)`;
`check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)`;
`check_sorry_token: OK (318 files scanned comment-stripped — generated 219, hand-written+test 64, LemLib 35; 0 sorry tokens)`;
the failure-reach line of §2.2 (selftest + gate); `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`; 0 `FAILED` lines. (Census unchanged by H1, as expected: the opaque population is 16 before and after; the 38 seam pins unchanged.)

`scripts/ce ./scripts/test_immaculate.sh` (`…evidence/test_immaculate_h1_full.log`): **RED — 9 of the 66
baseline rows moved, 57 at baseline**, every movement the same:

    DEVIATION: zd-z2f04-closedir expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: g4-bswap64-overflow expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: zd-z2fl03-nan-to-int expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: offsetof-union-member expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: f3-raw-high-byte-char-const expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: zd-z2m02-device-funptr-call expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: f3-raw-high-byte-int expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: f3-raw-high-byte-uchar expected [MATCH | L=CRASH] got [INVALID | L=INVALID]
    DEVIATION: g5-decode-multichar expected [MATCH | L=CRASH] got [INVALID | L=INVALID]

These are exactly the `L=CRASH` rows whose Lean side is a SEAM `panic!` (CerbFS `fs_closedir`, CerbUtils
`bswap64`, CerbFloat `truncToInt`, CerbMem `sizeofCtype` (offsetof-union-member) and `casePtrval`,
CerbDecode ×4); the two `L=CRASH` rows that are typed `ModelFailure` kills (`g2-memcmp-uninit`,
`zd-z2m01-aligned-alloc-zero-zero`) did not move. **S1** by the letter; the cause is §3.

NOT run (stopped): `test_exec.sh --check-baseline` rows 2/3/4/4b, row 10 + `--plant`, the FULL battery.
The `batch`-policy lanes are unaffected by construction — a PANIC line is `FATAL` before any origin
check, before and after (§3 codec run) — and row 10 never runs Lean; but that is a claim, not a
measurement, and the orchestrator's re-verification should run them once the S3 decision is taken.

## 3. The S3 finding — `observations.py:53`'s captured site name IS pinned, by an instrument defect

`LEAN_PANIC = re.compile(rb'PANIC at ([^ \r\n]+) [^\r\n]+:[0-9]+:[0-9]+: (.+)')` (:53) captures the
site; its ONE consumer is `failure_message` (:199-209), reached only under the `litmus` and `immaculate`
policies (:284-285; `batch` never gets there — `FUEL_RECORD` first, then `FATAL`):

    if lean[1] != b'LemLib.failwithIImpl' and not (
            policy == 'immaculate' and lean[1] in IMMACULATE_PANICS):
        raise ProtocolError('unreviewed panic origin')

with `IMMACULATE_PANICS = {CerbMem.memcmpM.getBytes, CerbUtils.gcc_builtin_bswap64,
_private.CerbDecode.0.CerbDecode.decode_character_constant_aux, CerbMem.sizeofCtype_lemFuel,
CerbFS.fs_opendir, CerbFloat.truncToInt, CerbMem.allocator, CerbMem.casePtrval}` (:64-68; "New panic
origins need explicit review here"). Facts established here:

1. LemLib's impl is `private` (`LemLib.lean:167 @[never_extract] private unsafe def failwithIImpl`), so
   the runtime prints `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: <msg>` — NEVER
   `LemLib.failwithIImpl`. The codec's unconditional accept-literal is dead code; the charter §1 (and the
   codec's own plants `test_observations.py:235,241,265,277`, `test_observation_lanes.py:59`) carry the
   unmangled name. Demonstrated: the AFTER stderr with the site rewritten to the literal decodes to
   `INTERNAL_ERROR:{msg: "Ocaml_gcc_builtins.bswap64: …"}` (`…evidence/codec-before-after.txt`, last line).
2. Therefore, under `immaculate`, the ONLY accepted Lean panic origins today are the eight
   `IMMACULATE_PANICS` seam sites — the lane pins the site names of its crash rows. H1 moves every seam
   site to the mangled LemLib name → `unreviewed panic origin` → `INVALID`. Codec run on the captured
   stderr, verbatim (`…evidence/codec-before-after.txt`):

        [immaculate/before] g4-bswap64-overflow rc=0: INTERNAL_ERROR:{msg: "Ocaml_gcc_builtins.bswap64: Z.to_int64 overflow (ocaml_gcc_builtins.ml:30)"}
        [immaculate/before] zd-z2m02-device-funptr-call rc=0: INTERNAL_ERROR:{msg: "case_ptrval"}
        [immaculate/after] g4-bswap64-overflow rc=2: OBSERVATION ERROR: unreviewed panic origin
        [immaculate/after] zd-z2m02-device-funptr-call rc=2: OBSERVATION ERROR: unreviewed panic origin
        [batch/before] g4-bswap64-overflow rc=2: OBSERVATION ERROR: fatal engine diagnostic; no completed observation
        [batch/after] g4-bswap64-overflow rc=2: OBSERVATION ERROR: fatal engine diagnostic; no completed observation

3. Two `IMMACULATE_PANICS` entries are ALREADY dead today (`CerbMem.memcmpM.getBytes` → `failStopMem`,
   `CerbMem.allocator` → `CerbFail.failStopKill`, both typed kills since C-TF1); after H1 all eight are dead.
4. Latent today, independent of H1: a REAL generated-model `failwithI` crash (not fuel — fuel is caught by
   `FUEL_RECORD` first) under `litmus`/`immaculate` would ALSO read `unreviewed panic origin`.
5. `scripts/test_parse.sh:178` greps `'PANIC at .*failwithIImpl'` (substring) — matches the mangled name;
   after H1 a seam failure on a `*.error.c` input would count `INTERNAL_ERROR_EXPECTED` instead of
   `LEAN_FAILURE`; no such row exists today (the lane is 100%), so no movement, but the class widens.

**Remedy (for the orchestrator; `scripts/observations.py` and its plants are OUTSIDE this fence):**
(a) accept the real origin — e.g. `lean[1] in (b'LemLib.failwithIImpl', b'_private.LemLib.0.failwithIImpl')`
or a regex `(?:_private\.LemLib\.0\.)?failwithIImpl` — and add a plant with a REAL captured line (this
record has three); (b) decide the fate of `IMMACULATE_PANICS`: after H1 the per-origin review it encoded is
carried by the failure-reach register (every seam failure IS a reviewed row, both directions), so the set
can go, or stay as an empty hook; (c) fix the four plants' fabricated `LemLib.failwithIImpl` lines; then
(d) `git apply lean_frontend/docs/2026-09-18_seam-hygiene-evidence/h1-candidate.patch`, `make
lean-prelude-src`, `build_lean`, re-gate (the immaculate lane must then read all 66 rows at baseline), and
commit H1 with this record's §2 as its justification. [AGENT] I did not touch `observations.py`: the
fence is exact, and whether the immaculate lane should keep a per-origin review is an instrument-design
call.

## 4. H2 pre-work: the eight arms cannot all take the honest shape inside the fence (E2)

`CerbGlobal.CerbSwitch` (CerbGlobal.lean:71-86) has constructors `strict_reads`, `forbid_nullptr_free`,
`zap_dead_pointers`, `inner_arg_temps`, `permissive_printf`, `no_integer_provenance`, `cheri` — and
`is_PNVI () := false`, `has_strict_pointer_arith () := false` as plain defs ("not in the lem subset, so
the test is written as its value"). There is NO predicate for `SW_strict_pointer_equality`,
`SW_strict_pointer_relationals`, `SW_pointer_arith PERMISSIVE` or `SW_zero_initialised`, and `CerbGlobal`
is fence-FORBIDDEN (charter §3). Consequence, arm by arm (this tree's `impl_mem.ml` lines — the charter's
are off by 6–8, E5):

| arm (Lean def) | OCaml guard (this tree) | predicate available? |
|---|---|---|
| `eqPtrval` (:2501) | `has_switch SW_strict_pointer_equality` :1860 | NO |
| `lt/gt/le/gePtrval` (:2541-2564) | `has_switch SW_strict_pointer_relationals` :1897/:1915/:1930/:1947 | NO |
| `diffPtrval` (:2582) | `has_switch (SW_pointer_arith PERMISSIVE)` :1978 | NO |
| `effArrayShiftPtrval` (:2741) | `STRICT ∨ (is_PNVI ∧ ¬PERMISSIVE)` :2273-2274/:2345-2346/:2357-2358 (+ `PERMISSIVE` :2292) | partial (`has_strict_pointer_arith`, `is_PNVI`; no PERMISSIVE) |
| `allocateObject` (:2157) | `has_switch SW_zero_initialised` :1318 | NO |
| `loadM` (:2349) | `has_switch SW_strict_reads` :1601 | YES — `.strict_reads` |
| `ptrfromint` (:2681) | `is_PNVI ()` :2154 | already ported (:2688) |
| `intfromptr` (:2701) | `has_switch (SW_PNVI AE) ∨ has_switch (SW_PNVI AE_UDI)` :2454 | coarser `is_PNVI ()` only (implies both false; a documented over-approximation) |

So 2 of the 8 (`loadM`, `intfromptr`) are doable now; 6 need either new `CerbSwitch` constructors (a
`CerbGlobal` edit — also a question about the lem `switch` type's Lean target_rep and any exhaustive
matches) or CerbMem-local `def … : Bool := false` predicates (fragmenting the configuration surface that
step 2 is meant to lift). [AGENT] Not started: a design decision the fence reserves to the operator. Also
noted: `loadM`'s PNVI `expose_allocations` arm (impl_mem.ml:1570) is declared in the CerbMem comment but is
not in the charter's eight.

## 5. H3 pre-work: the opaque census register is outside the fence (E3)

`OPAQUE_WANT` — the list the boundary-opaque census checks exactly-once, both directions — is an array
INSIDE `scripts/check_theorem_axioms.sh:207-231`, not in `scripts/unsafebaseio_allowlist.txt` (the fence's
named file; the allowlist carries the `PIN` rows). H3(b) deleting `begin_timing`/`end_timing`/`STD_` and
H3(c) deleting `beqMemValueSafe` would each make the census RED (`registered opaque … found 0 time(s)`)
unless those four rows leave `OPAQUE_WANT` — an edit the charter's H3(d) text expects ("the OPAQUE_WANT
population moves DOWN by exactly the deleted rows") but the fence does not permit. H3(a) `oomKill` has no
such dependency. Verified for (b): nothing reads `logRef`/`timingStackRef` — the only mentions outside
CerbUtils.lean are the allowlist rows and `OPAQUE_WANT`; the `.lem` callers are `boot.lem:4-10` and
`cabs_to_ail_effect.lem:1601-1626` (`STD_ "§…" $ …`, value position). Before-counts for the record:
opaque population 16, seam pins 38. [AGENT] Not started (order H1 → H2 → H3 is fixed and H1 is blocked).

## 6. Errata to the charter's §1 (each re-checked against this tree)

- **E1** Z2-M-20 is not a row of `VALIDATION.md` §3; it lives in the dated Z2 audit/record
  (`2026-09-03_zero-discrepancy-Z2-audit.md:201`, `2026-09-04_zero-discrepancy-Z2-record.md:316`);
  VALIDATION §3's relevant text is the "(c) Semantics switches" paragraph.
- **E2** four of the eight switches have no `CerbSwitch` constructor/predicate (§4).
- **E3** `OPAQUE_WANT` lives in `check_theorem_axioms.sh`, outside the fence (§5).
- **E4** the library constant is top-level `failwithI` (no `LemLib` namespace); the four leaf seams need
  `import LemLib`; the census tokenizer requires the bare spelling.
- **E5** impl_mem.ml cites in this tree: `SW_strict_pointer_equality` :1860 (not :1852-1853);
  relationals :1897/:1915/:1930/:1947; `diff_ptrval` PERMISSIVE :1978 (not :1970-1975);
  `eff_array_shift_ptrval` :2273-2274, :2292, :2345-2346, :2357-2358 (not :2265-2350);
  `allocate_object` zero_initialised :1318 (not :1310); `load` strict_reads :1601 (not :1593);
  `ptrfromint` :2154 (not :2147-2160); `intfromptr` :2454 (not :2445-2452) and its guard is the
  AE/AE_UDI pair, not `is_PNVI ()`; `SW_forbid_nullptr_free` :1474; `SW_zap_dead_pointers` :1518/:1552.
  The allocator kill sites are `CerbMem.lean:2133`/`:2140` in this tree (the charter's "~:2120/:2127").
- **E6** the runtime panic site of `failwithI` is `_private.LemLib.0.failwithIImpl`, not
  `LemLib.failwithIImpl` — the S3 trigger (§3).
- **E7** the register's `msg` column is a derived key and must follow a prefixed message (14 rows); "token
  column only" and "prefix where not self-locating" cannot both hold.
- **E8** paired worker definitions related by `rfl` theorems must carry IDENTICAL leaf messages (§2.1).
- **E9** the primed worktree was stale on both generated trees and both binaries (§1 step 2); the
  standing pristine-oracle manifest was present and valid as stated.

## 7. Open items / what is left undone

H1: not committed (S3/S1) — candidate patch + remedy in §3. H2: 2/8 arms doable in-fence, 6 need a
`CerbGlobal` decision (§4). H3: (a) doable; (b)/(c)/(d) blocked by the fence on `check_theorem_axioms.sh`
(§5). Gates not run: Tier A rows 2–4b, row 10 + `--plant`, FULL battery. Instrument findings outside the
fence, for the operator: the codec's dead accept-literal and fabricated plants (§3 items 1, 4);
`test_parse.sh:178`'s class widening (§3 item 5); `IMMACULATE_PANICS` already 2/8 dead.

## 8. Consumer note (cerberus-sl)

Nothing can be stated yet: the seam leaves are still `panic!` at HEAD. Once the H1 candidate lands the
statement will be: no hand-written seam failure in the exec dependency closure has a kernel equation
(every registered site is `failwithI`, `opaque`; the two probes of your §1 item 3 fail by `rfl`, pinned by
`test/Unit/OpaqueFailureTest.lean`), with the caveat that the failure-reach register's reach classes remain
reviewed claims. `CerbMem.oomKill`, the `has_switch … = false` arms and the identity stubs await H2/H3.

## 9. Evidence (`2026-09-18_seam-hygiene-evidence/`)

`h1-candidate.patch` (the complete H1 candidate against `0eafc94a4`; `git apply --check` clean),
`h1-site-table.md` (per-site table), `h1_edit.py` (the edit plan, per-site decisions), `h1_register.py`
(the re-keying script, WITH its line-order defect — see §2.2), `probe-before.lean`/`probe-before.txt`,
`probe-after.lean`/`probe-after.txt`, `before-*.stderr`/`.rc`/`.stderr.line1` and `after-*` for the three
programs, `after-unmangled-demo.stderr` + `codec-before-after.txt` (the §3 codec runs),
`check_theorem_axioms_before.txt`, `check_failure_reach_before.txt`, `check_failure_reach_h1.txt`,
`test_unit_h1_full.log` + `test_unit_h1_verdicts.txt` (the green re-run), `test_immaculate_h1_full.log`.
Container-side scratch (`.tmp/seam-hygiene/`, build logs, cabs-jsons) is ephemeral and not committed.
