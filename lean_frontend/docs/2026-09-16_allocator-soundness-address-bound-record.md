# Record — allocator soundness (tray 44) + the address-space bound as a quantified parameter + the fork-only OCaml flag (2026-09-16) — PART ONE (C1 + C1b) COMPLETE; C2/C3 RE-CHARTERED SEPARATELY

**Status [AGENT, worker, 2026-09-17]:** PART ONE of the slice is COMPLETE and is the landing
candidate: **C1** `7b51b0b438052d47551009b9f65464d3030e9bf3` (remedy 1 in both OCaml models + the
Lean mirror + the GENERAL kernel theorem + the runtime witness; §C1) and **C1b**
`f9843725d8c4746449bde65f0bbfe6166bfe4d6d` (the row-10 diagnostic projection extended to the
OCaml exception HEADER line, resolving §S1). The FULL gate (`release.py --mode full`, Tier A + B)
is GREEN at the C1b head and the three-engine report's Lean column is unchanged (§FULL, verbatim).
**C2 and C3 are NOT in this part**: the worker stopped at C2's design step (stop rules S3/S6 — the
`initial_driver_state*` signature change ripples into a `.lem` body outside the fence, §C2), and
the operator ruled that C1 lands first and C2/C3 are re-chartered separately as part two — [USER
2026-09-17], verbatim: *"yes, agreed regarding landing C1 as-is and then working on C2/C3
separately"* (given in reply to the orchestrator's proposal that (1) the diagnostic projection be
extended to normalise the position in OCaml's exception HEADER line — this record's §S1
recommendation (ii); (2) C2 take route A with an extended fence; (3) C1 land first as part one
with C2/C3 re-chartered as part two). This record was first committed as an INTERIM stop
(`a2cf688c0`, after C1: stop rules S1 + S3/S6); this amendment carries the ruling, C1b and the FULL
gate. Evidence directory: `docs/2026-09-16_allocator-soundness-address-bound-evidence/` (every
quoted output is verbatim from a file there or from a lane log summarised there).

**Part one / part two.** Part one = C1 + C1b (+ this record) on `arc/allocator-soundness-address-
bound`, the landing candidate for the orchestrator's pre-merge audit; C1's content is exactly as
committed (`7b51b0b43`, untouched by the ruling). Part two = C2 (route A: the address-space bound
as an explicit entry parameter) + C3 (the fork-only `--address-space-top` flag + the tiny-bound
differential lane), to be re-chartered with the fence extension §C2 option (A) lists — the
`.lem` sites `mini_pipeline.lem:163`, `cabs_to_ail_effect.lem` (state + seed + getter),
`cabs_to_ail.lem` (the desugar entry), `backend/common/pipeline.ml`, `Main.lean`'s desugar call, the
three latent OCaml backends (E2) and the eight out-of-fence Lean files (E3). The §C2 options are
kept as written for that charter.

The worktree at this record: `worktrees/cerberus-lean-arc/allocator-soundness-address-bound`,
branch head = this record's commit on top of `7b51b0b43` (C1) on top of `6d9ba82f1`
(the charter, rebased onto mainline `4a23d98aa`).

## 0. Rulings (by pointer; verbatim texts in the charter §0)

- [USER 2026-09-16] fix ahead of upstream ("unambiguously wrong") — charter §0 bullet 1.
- [USER 2026-09-16] the bound is quantified ("running on a tiny machine … the reasoning has to
  quantify over the bound") — charter §0 bullet 2.
- [USER 2026-09-16] one slice as proposed + "an ocaml flag is a good idea" — charter §0 bullet 3.
- [USER 2026-09-03] no-magic-values, verbatim in `DESIGN.md` §4 — charter §0 bullet 4.
- [USER 2026-09-08] nothing new out of policy (the theorem GENERAL, the four states a TEST) — §0 bullet 6.
- [USER 2026-09-17] "(2) agree" — the row-10 diagnostic projection normalises positions inside
  OCaml backtrace FRAMES (`VALIDATION.md` §0/§3) — the ruling §S1 below sits next to.
- Every decision below marked [AGENT] is the worker's, with its one-line reason.

## 1. Errata to the charter's §1 (re-checked against THIS tree, `6d9ba82f1` = mainline `4a23d98aa` + the charter)

All §1 cites re-verified and CORRECT at this tree unless listed: `concrete/impl_mem.ml:9`,
`:503-516` (`:508` the literal), `:1247-1262` (`:1253` the rounding line); `vip:8`, `:170`
(the literal at `:175`), `:202-211`; `symbolic:569`; `cheri-coq:271`; `memory_model.ml:39`;
`impl_mem.mli` = `include Memory_model.Memory`; `mem.lem:41-45`; `driver.lem:1520/:1526/:1535/
:1540`, `val drive :1730`; `driver_ocaml.ml:157/:198`, `driver_conf :11-16` / `.mli:3-8`;
`main.ml:99/:219/:521-524/:566`; `Main.lean:1019/:1150/:1251`; `CerbMem.lean:153/:1780/
:2093-2107`; generated `Driver.lean:489`; `lakefile.toml:248-252`; `test_unit.sh:15`; drift
rows `:359-362`; both `impl_mem.ml` byte-identical to pristine `b9aeedcb4` at the allocator
(diff of `:1247-1262` empty, evidence header of `c1-prefix-negative-control.txt`).

- **E1 (material for C2 — the S3/S6 trigger).** `initial_driver_state_given` has a SHARED-MODEL
  consumer the charter's caller list omits: `frontend/model/mini_pipeline.lem:163`
  `let (init_dr_st, sup') = Driver.initial_driver_state_given sup_after_elab dummy_core_file
  Fs.fs_initial_state in`, inside `evalConstantExpressionAux` (`:95`), reached from
  `evalConstantExpression`/`evalIntegerConstantExpression` (`:221`) ← `cabs_to_ail.lem:1137`
  (`Mini_pipeline.evalIntegerConstantExpression sup loc core_env sigm ty_opt expr`, inside the
  desugar). The charter fences `driver.lem`'s three defs only and forbids "any other `.lem`
  change"; the chartered signature `initial_driver_state_given address_space_top sup file
  fs_state` cannot typecheck without this call site changing — and no bound is in scope there.
- **E2 (C2).** OCaml callers beyond `driver_ocaml.ml:157/:198`: `backend/bmc/bmc_utils.ml:197`
  (`Impl_mem.initial_mem_state`), `backend/ocaml/runtime/rt_ocaml.ml:200-204` (`M.initial_mem_state`
  ×5) and `:355` (`Driver.initial_driver_state dummy_file`), `backend/web/instance.ml:635`
  (`Driver.initial_driver_state core' Sibylfs.fs_initial_state`). None is compiled by the
  ladder's recipe (`dune build backend/driver/main.exe cerberus-lib.install` + `cerberus.install`):
  bmc is package `cerberus-bmc` (needs `z3`), web is `cerberus-web` (needs `lwt`/`cohttp`) — neither
  library is in the switch (`opam list`), so those packages cannot build here at all; `rt_ocaml`'s
  dune stanza is commented out. LATENT breakage under the C2 signature, not ladder-breaking.
- **E3 (C2).** Lean consumers outside the fence: `test/Unit/FuelExemplar.lean:130`
  (`initial_driver_state sup exemplarFile CerbFS.fs_initial_state`); the five speclab gate tests
  `speclab/test/SLUnit/{Tree,Seed,Core,List,ByteArr}GateTest.lean` (`initial_driver_state 0 f
  CerbFS.fs_initial_state`); `tests/mem-scale-probes/micro/Micro.lean:68-104` (`initialMemState`
  ×5; `:16` a `lastAddress` comment); `tests/immaculate/illtyped-store.lean:44` (`initialMemState`).
  `CerbCall.lean` builds no state (the charter's "check": confirmed, `grep initial_driver_state|
  layout_state|initialMemState` empty).
- **E4 (C1).** `Int.ediv_add_emod` / `Int.emod_add_ediv` do not exist under those names on
  Lean 4.32.2 (`Unknown constant`); `Int.emod_def : a % b = a - b * (a / b)`, `Int.emod_nonneg`,
  `Int.not_le` do and suffice (evidence: the proof).
- **E5 (C1).** The charter's theorem hypotheses `0 < align → 0 ≤ sz →` are unnecessary: `align = 0`
  is the refusal arm (never `NDactive`), and for `align ≠ 0` the Euclidean remainder is `≥ 0`; the
  landed theorem has NO hypothesis on `sz`/`align` (the charter's form is it weakened).
- **E6 (C1, proof engineering).** `omega` reads `≤`/`<` only when the relation's type argument is
  literally `Int`; `CerbMem.Address`/`StorageInstanceId` are `abbrev`s of `Int`, and the
  allocator's `if z' ≤ 0` is elaborated at `Address`, so `omega` silently DROPPED that hypothesis
  and the `0 < a` goal (its counterexample listed exactly the surviving facts). The theorem's
  relations are stated at `Int` and `hz'` is restated through `Int.not_le`. Worth a note in the
  house proof toolbox.
- **E7 (docs).** `VALIDATION.md` §3's intro said unobserved fork≠upstream deltas "become entries
  here only once a corpus observes them" — in tension with the charter's C1(f) (a §3 entry for an
  UNOBSERVABLE deviation). [AGENT] amended that sentence (in-fence §3) to name the placement; the
  orchestrator may prefer another wording.
- **E8 (C3).** WP-O's fork-only interface list exists: `scripts/test_upstream_oracle.py:787`
  `{'interface': '--cabs-json, --call, --batch-alloc-census', … 'reason': 'fork-only harness
  rows …'}` — a `not_applicable` report entry; the place `--address-space-top` would be named.
- **E9 (line cites, trivial).** `Main.lean` `let fuel : Nat ← match fuelStr` is `:1270` (charter
  `:1271`); `ALLOW_MAIN` opens at `check_no_fuel_numerals.sh:70` (charter `:69-70`).
- **E10 (gate behaviour, C1).** The axiom gate's D14 leg is a RAW grep (not comment-stripped):
  a docstring MENTIONING the banned tactic trips it (it did, on the first draft; reworded).

## C1 — Allocator soundness (remedy 1) — LANDED `7b51b0b438052d47551009b9f65464d3030e9bf3`

### C1.1 The OCaml diff (the upstream patch hunk; evidence `c1-ocaml-diff.patch`, 52 lines)

`memory/concrete/impl_mem.ml` (the VIP hunk at `memory/vip/impl_mem.ml:207-218` is the same
text at indent 4, `line 8` in the comment):

```diff
       let z = sub st.last_address sz in
-      let (q,m) = quomod z align in
-      let z' = sub z (if q < zero then neg m else m) in
-      if z' <= zero then
+      (* fork fix (upstream-tray draft 44, 2026-09-16): quomod is EUCLIDEAN (line 9), so `sub z (if q < zero then neg m else m)`
+         ADDED m when z < 0 and could succeed in (0, align) over the live object at last_address; kill BEFORE rounding. *)
+      if z < zero then
         fail (MerrOther "Concrete.allocator: failed (out of memory)")
       else
-        return z'
+        let (_, m) = quomod z align in
+        let z' = sub z m in
+        if z' <= zero then
+          fail (MerrOther "Concrete.allocator: failed (out of memory)")
+        else
+          return z'
```

New concrete line numbers: `z` `:1252`; the fix `:1255-1256`; `quomod` `:1258`; `z'` `:1259`;
`z' <= zero` `:1260-1261`; `return z'` `:1263`; `put` `:1264-1270`. Failure text unchanged. The
OCaml-side after-witness by the tray's own method (the new arithmetic in a standalone Zarith
program; `c1-ocaml-after-witness.txt`), verbatim:

```
ediv_rem (-1) 4 = (-1, 3)
last=3 sz=4 align=4: z=-1 -> killed (out of memory) [z < 0, before rounding]
last=7 sz=8 align=8: z=-1 -> killed (out of memory) [z < 0, before rounding]
last=2 sz=4 align=4: z=-2 -> killed (out of memory) [z < 0, before rounding]
last=8 sz=4 align=4: z=4 m=0 z'=4 -> active, address 4
```

### C1.2 The Lean mirror (`lean_frontend/CerbMem.lean` `allocator`, `:2110-`)

Line by line against the new body with the new cites: `z` (`:1252`); `z < 0` → the out-of-memory
kill (`:1255-1256`); THEN the alignment-0 refusal — the kind-2 `Division_by_zero` artifact (Z2 §10)
now sits exactly where the OCaml's `quomod` sits, AFTER the `z < 0` kill ([AGENT]: that is the
faithful order; behaviour differs from the pre-fix mirror only for `align = 0 ∧ z < 0`, unreachable
at upstream's bound, and the OCaml itself kills there before reaching `quomod`); `m = z % align`
(`:1258`, Lean's Int `%` IS `ediv_rem`'s remainder); `z' = z - m` (`:1259`); `z' ≤ 0` kill
(`:1260-1261`); the active arm (`:1263-1270`). The refusal message's cite moves
`impl_mem.ml:1252` → `:1258` (`test/Unit/MonadicFailstop.lean:34` updated in step; [AGENT]
grep'd `tests/`, `scripts/`, `lean_frontend/{test,speclab,corpus}`: nothing else pins that text —
the immaculate `zd-z2m01-*` rows are class pins `MATCH | L=CRASH`).

### C1.3 The theorem (`lean_frontend/CerbMemAllocatorProofs.lean`; `c1-theorem-axioms.txt`)

```
CerbMem.allocator_active_sound : ∀ (st st' : CerbMem.MemState) (sz align id a : Int),
  CerbMem.allocatorStep sz align st = (NDactive (id, a), st') →
    align ∣ a ∧ 0 < a ∧ a + sz ≤ st.lastAddress ∧ st'.lastAddress = a
CerbMem.allocator_below_request_kills : ∀ (st : CerbMem.MemState) (sz align : Int),
  st.lastAddress - sz < 0 →
    CerbMem.allocatorStep sz align st = (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st)
'CerbMem.allocator_active_sound' depends on axioms: [propext, Classical.choice, Quot.sound]
'CerbMem.allocator_below_request_kills' depends on axioms: [propext, Classical.choice, Quot.sound]
```

`allocatorStep sz align st := match allocator sz align with | ND f => f st` — the `CerbFail.step`
shape restated so the seam depends on `CerbMem` alone ([AGENT]: importing `CerbFailProofs` would
put `CerbND` and the driver under a memory-model lemma). GENERAL over every state, size and
alignment; proof = `simp only [allocatorStep, allocator]`, three `split`s (the kill arms close by
constructor clash), `Int.emod_nonneg`, `Int.emod_def`, `Int.not_le`, `generalize` of the two
non-linear terms, `omega`; no `decide` on literals, no option bumps, no D14-banned method. Kernel
checked on every `test_unit.sh` run (the test exe imports the module); registered in
`handwritten_copy.manifest` and as a `lakefile.toml` root (`check_lakefile_roots` requires it).
NOT registered in `check_theorem_axioms.sh`'s `#print axioms` probe leg (out of fence) — open item.

### C1.4 The runtime witness (`test/Unit/AllocatorSoundnessTest.lean`, exe `allocator-soundness-test`)

BEFORE (negative control — the four states on the ACTUAL `CerbMem.allocator` as built at the
charter head, probe `c1-prefix-negative-control.txt`, freshness lines recorded there), verbatim:

```
"last=3 sz=4 align=4: active, id=0 address=2 cursor'=2"
"last=7 sz=8 align=8: active, id=0 address=6 cursor'=6"
"last=2 sz=4 align=4: killed (Concrete.allocator: failed (out of memory)) cursor'=2"
"last=8 sz=4 align=4: active, id=0 address=4 cursor'=4"
```

AFTER (`c1-test-after.txt`), verbatim:

```
allocator-soundness-test: the four draft-44 states on the ACTUAL CerbMem.allocator (remedy 1)
PASS cursor 3, request (4, 4): got AllocatorSoundnessTest.Outcome.outOfMemory 3, expected AllocatorSoundnessTest.Outcome.outOfMemory 3; pre-fix: active, address 2 (the defect)
PASS cursor 7, request (8, 8): got AllocatorSoundnessTest.Outcome.outOfMemory 7, expected AllocatorSoundnessTest.Outcome.outOfMemory 7; pre-fix: active, address 6 (the defect)
PASS cursor 2, request (4, 4): got AllocatorSoundnessTest.Outcome.outOfMemory 2, expected AllocatorSoundnessTest.Outcome.outOfMemory 2; pre-fix: killed (out of memory)
PASS cursor 8, request (4, 4): got AllocatorSoundnessTest.Outcome.active 0 4 4, expected AllocatorSoundnessTest.Outcome.active 0 4 4; pre-fix: active, address 4 (the normal regime)
allocator-soundness-test: OK (4/4 states; kernel theorem CerbMem.allocator_active_sound compiled)
exit=0
```

### C1.5 Drift rows, VALIDATION §3, tray, docs

`scripts/fork_drift_manifest.txt` `[source-content]`: `memory/concrete/impl_mem.ml`
`e55389c6…` → `97a5da4c290f3000a3016b988ef50752ea10caaabc31fa2c86f707284324286b`;
`memory/vip/impl_mem.ml` `1491d4a2…` → `4bc49e634bae47d38e1c1009c9c9679eb3a34c228baf6478770818e614944e90`
(single-row edits + the dated header note "allocator-soundness C1"; no `--refresh`; layer 2
unchanged — no `.lem` touched). `VALIDATION.md` §3 "Fork ≠ pristine": the UNOBSERVABLE
`shared-model-fix` entry (no register row) + the amended intro sentence (E7). Tray 44 "Fork status":
the LANDED line (this record's commit adds the hash). `lean_frontend/CLAUDE.md`: key-files row +
unit-test list. `scripts/upstream_oracle_differences.json`: UNTOUCHED.

### C1.6 The chartered FAST-GATE (verbatim; `c1-fast-gate-tails.txt`; every lane via `scripts/ce`)

```
test_unit rc=0 wall=170s
exec_minimal rc=0 wall=33s
exec_coverage rc=0 wall=51s
exec_debug rc=0 wall=23s
exec_float rc=0 wall=24s
```
`./scripts/test_unit.sh`: `Total: 11 passed, 0 failed`; `allocator-soundness-test: OK (4/4 states;
kernel theorem CerbMem.allocator_active_sound compiled)`; `check_handwritten_sync: OK (49
hand-written files byte-identical to lean_frontend/generated/; …)`; `check_theorem_axioms: D14
grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 49 hand-written seam files +
LemLibTest.lean)`; `check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext,
Classical.choice, Quot.sound])`; `check_no_fuel_numerals: OK (324 files scanned comment-stripped;
…; allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))`; `check_no_fuel_numerals:
SELFTEST OK (20 plants red with the declared label; E5 indirection a recorded known gap; unplanted
set green)`; `check_lakefile_roots: OK (218 roots = 218 generated modules + the exe root Main; 85
auxiliary modules all built)`; `check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest
(set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned
(merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)`;
`check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly …)`;
`check_lem_sync: OK (src 0ea744e44bd25235b4db5b42660406f178879ca5194c707640feb4f814e3793c, gen
bcb2f7d80459eda631942ad09cf31a632640ad5fbfb2bd3d5d678bbf01c6a14b)`.
`test_exec.sh --check-baseline`: `SUMMARY: total=111 match=90 ub_match=18 ub_diff=0 mismatch=0
fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0`
/ `Baseline check: 0 regression(s), 0 improvement(s)`; coverage: `SUMMARY: total=212 match=183
ub_match=16 ub_diff=0 mismatch=0 …` / `Baseline check: 0 regression(s), 0 improvement(s)`; debug:
`SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 …` / `Baseline check: 0
regression(s), 0 improvement(s)`; float: `SUMMARY: total=93 match=93 ub_match=0 ub_diff=0
mismatch=0 …` / `Baseline check: 0 regression(s), 0 improvement(s)`. The OCaml oracle was rebuilt
by the `build_cerberus` recipe (main.exe + cerberus-lib.install; local-prefix install;
cerberus.install; `libc.co` staged; stamp `check_driver_fresh: recorded oracle stamp (bin
187d6fdc… src dbb7b994…)`); `mem_vip` = `cerberus-lib.mem.vip`, so the VIP edit compiled in it.

## S1 — Row 10 after C1: ONE `difference`, a diagnostic-text artefact of the line shift — RESOLVED by C1b

Run as C1's shared-model report (not part of C1's chartered gate). Verbatim tails
(`c1-row10-difference-g2-memcmp-uninit.txt`; logs `.tmp/c1-row10.log`, `.tmp/c1-three-engine.log`):

```
row10 rc=1 wall=114s
Independent oracle scope: tier-b; 855 rows in 114.2s; source unchanged: True
Independent oracle: failed; {'semantic_agreement': 822, 'matching_failure': 27, 'reviewed_difference': 3, 'interface_agreement': 2, 'difference': 1}; …/.tmp/upstream-oracle-bid3d5si/report.json
three-engine rc=1 wall=252s
Three-engine report (Lean column, NOT gating): {'lean_agreement': 813, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}; Lean≠fork rows: 40: …
Independent oracle: failed; {'semantic_agreement': 822, 'matching_failure': 27, 'reviewed_difference': 3, 'interface_agreement': 2, 'difference': 1}; …/.tmp/c1-three-engine/report.json
```

WP-O O5's verdict was `passed; {822, 28, 3, 2}`: exactly ONE case moved `matching_failure` →
`difference`: **`immaculate/libc/g2-memcmp-uninit`** (a standing §1(a) both-crash pair; both
engines rc 125, stdout empty on both). The Lean column is BYTE-FOR-BYTE WP-O's (813/28/12/2, the
same 40 pinned rows) — the mirror moved nothing at upstream's bound. (The three-engine run's
`source unchanged: False` is the worker's doing: an evidence file was written into the tree while
it ran; row 10 proper ran with `source unchanged: True`.)

Diagnosis [AGENT], confirmed by re-running both engines by hand on the case (evidence file, stderr
verbatim, `diff pristine -> fork`): the ONLY line the lane's diagnostic projection does not
normalise is the exception HEADER
```
<           File "memory/concrete/impl_mem.ml", line 2659, characters 16-22: Assertion failed
>           File "memory/concrete/impl_mem.ml", line 2664, characters 16-22: Assertion failed
```
— OCaml's `Assert_failure` printer carries the `memcmp` assert's SOURCE LINE (`get_bytes`,
`assert false`, tray 13's site), which C1's +5 net lines above it moved 2659 → 2664. Every other
differing line is a backtrace FRAME position (`Raised at`/`Called from` … `line N, characters
A-B`) the projection already normalises under [USER 2026-09-17] "(2) agree" — which is why the
case was `matching_failure` at WP-O (fork and pristine had the SAME impl_mem.ml line numbers
until now: the fork's only prior delta in that file was below, at `:2999-3003`). Same failure,
same status, same stdout: a `diagnostic-text`-class difference, precisely the register's
permitted-with-zero-rows class ("a genuine exception-TEXT difference still needs a cited row of
this class", §3).

Why this is a STOP and not a fix: both remedies are outside the fence — (i) a `diagnostic-text`
register row for `immaculate/libc/g2-memcmp-uninit` citing tray 44 + this record
(`scripts/upstream_oracle_differences.json` is forbidden to the worker: "any … register row of any
lane"); (ii) extending the diagnostic projection to normalise the `File "…", line N, characters
A-B:` header of OCaml's assert/match-failure printer exactly as it normalises frames
(`scripts/test_upstream_oracle.py` is WP-O's file, forbidden except the fork-only-flag entry).
Recommendation [AGENT]: **(ii)** — the header carries the same kind of information (a source
position) as the frames the 2026-09-17 ruling normalised, and EVERY future fork edit above
`impl_mem.ml:2659` — C2's `initial_mem_state` change at `:503` is the next one — re-trips it;
(i) would need re-recording at each such edit and would pin a position that is not behaviour. It is
the operator's call ([USER] class ruling territory: the projection's scope). Until then row 10 is
RED on this branch by ONE known, diagnosed, behaviour-free row.

Other Tier B exposure checked: `tests/immaculate/baseline.txt` pins classes (`g2-memcmp-uninit
MATCH | L=CRASH`), no text; no baseline, triage ledger or pin carries `Assert_failure` or an
`impl_mem.ml` line number (`grep` over `tests/`, `scripts/`, `lean_frontend/corpus`: empty).

**RESOLUTION — C1b `f9843725d8c4746449bde65f0bbfe6166bfe4d6d` (2026-09-17).** Ruled by the operator —
[USER 2026-09-17], verbatim: *"yes, agreed regarding landing C1 as-is and then working on C2/C3
separately"* — on the orchestrator's proposal taking recommendation (ii). The worker's fence was
extended for that ONE commit to `scripts/test_upstream_oracle.py`'s diagnostic projection and its
plants, and to the one-sentence doctrine text describing the projection (`VALIDATION.md` §0/§3,
`LADDER.md` row 10). What C1b does: `HEADER_POSITION` — `^( *File "[^"\n]*"), lines? N[-M],
characters A-B(:[^\n]*)$` → `\1, line N, characters A-B\2` — normalises ONLY the position of an
OCaml exception HEADER line (`Assert_failure`/`Match_failure`: `File "<path>", line N[-M],
characters A-B: <text>`); the path (group 1) and the exception text after the colon (group 2)
stay byte-compared; stderr only (`project_diagnostics`); frames unchanged; stdout never projected.
The report's `diagnostic_projection` string names the extension. Plants (hermetic, in the
existing projection plant set), verbatim from `--plant` (`c1b-gates.txt`):

```
PLANT OK   projection/header-position-only: got 'matching_failure', want 'matching_failure'
PLANT OK   projection/header-and-frame-positions-only: got 'matching_failure', want 'matching_failure'
PLANT OK   projection/header-file-path-differs: got 'difference', want 'difference'
PLANT OK   projection/header-exception-text-differs: got 'difference', want 'difference'
PLANT OK   projection/header-shape-in-stdout-not-projected: got 'difference', want 'difference'
PLANT OK   projection/header-shape-in-stdout-raw-sha-differs: got True, want True
PLANT OK   projection/non-header-position-line-differs: got 'difference', want 'difference'
PLANT OK   projection/header-raw-stderr-retained: got True, want True
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
```
(`plant_ok` 43 → 51: the eight header plants; the second plant is the real `g2-memcmp-uninit`
shape after C1's shift — header AND frames moved.) Gates at C1b, verbatim:

```
row10 rc=0 wall=114s
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}
ci rc=0 wall=137s
Independent oracle: passed; {'semantic_agreement': 134, 'matching_incomplete': 2, 'matching_failure': 106}
test_unit rc=0 wall=151s
Total: 11 passed, 0 failed
```
— row 10 is back to WP-O O5's verdict exactly (822/28/3/2; `g2-memcmp-uninit` reads
`matching_failure` again) and the `ci` reporting row is unchanged (134/2/106). No register row
was written; `scripts/upstream_oracle_differences.json` is untouched by this slice. Doctrine: the
ruling is quoted verbatim once, in `VALIDATION.md` §3's `diagnostic-text` bullet; §0 and
`LADDER.md` row 10 point to it. NOT updated (outside the extended fence, for the orchestrator):
`VALIDATION.md` §5's lane-table row for `test_upstream_oracle.py (+ --plant)` still lists the
pre-C1b projection plants only.

## C2 — The bound as an explicit entry parameter — NOT STARTED (stop S3/S6 at the design step)

The chartered route A (`initial_driver_state* address_space_top …`, "nothing else in the model
changes") is not implementable inside the fence: E1 is a `.lem` body change outside it
(`mini_pipeline.lem:163`), and no bound is in scope there — `evalConstantExpressionAux sup loc
(ailnames, stdlib_fun_map, impl) sigm typing_guard ty_opt expr` (`:95`) receives the desugar's
supply and Core environment, nothing about the machine. A literal there is exactly what the
ruling forbids; keeping `initial_driver_state_given`'s old arity needs a bound-free
`Mem.initial_mem_state`, i.e. the literal again. S3 ("ripples beyond the sites named in §1") and
S6 (fence vs typecheck) — STOP before any edit. Nothing of C2 was touched.

Options for the re-charter [AGENT], with the ripple each implies:
- **(A) thread the bound through the desugar state** — `cabs_to_ail_effect.lem` `state` (`:224`)
  gains `address_space_top : integer`, seeded where the supply is seeded (`initial_state :577-578`,
  `val initial_state: nat -> … -> state_with_markers` gains the argument); `Cabs_to_ail.desugar`
  (the entry `pipeline.ml:206` calls with `0 …`; Lean `Main.lean`'s desugar call) gains it; a
  getter beside `get_fresh_sym_supply`; `mini_pipeline.lem:163` passes it to
  `initial_driver_state_given top sup file fs`. The bound then enters the semantics at TWO entry
  points (desugar and execution) from ONE CLI default — both `∀ top`-quantifiable. Fence
  extension: `mini_pipeline.lem` (one line), `cabs_to_ail_effect.lem` (record + seed + getter),
  `cabs_to_ail.lem` (entry signature), `backend/common/pipeline.ml`, `Main.lean`'s desugar call; plus
  E2 (three latent OCaml backends: fix or leave broken by ruling) and E3 (eight Lean files: the
  test-chosen value the ruling allows).
- **(B) `declare {lean} reader val`** — the charter's rejected route; it also does nothing for the
  OCaml side (the OCaml `initial_mem_state` value must still take the bound from somewhere).
- **(C) a [USER] ruling that the const-expr mini-run's memory state is bound-free** — e.g. that an
  INTEGER constant expression (`cabs_to_ail.lem:1137` — the only entry) can never reach `create`, so
  its cursor is dead data and any fixed value is "chosen in a test-suite sense". That needs an
  argument the worker has not made and a ruling the worker cannot give; it also leaves a literal
  in a definition, which the gate would have to allowlist.
Recommendation: **(A)**.

**CONSUMER RE-PIN NOTE (for cerberus-sl, relayed by the operator; refined-cerberus retired,
receives nothing).** C1 changes NO signature. What a consumer sees at `7b51b0b43`:
- `CerbMem.allocator sz align : memM (StorageInstanceId × Address)` — same type; body: the
  exhausted regime (`st.lastAddress - sz < 0`) now KILLS with `Other (MerrOther "Concrete.allocator:
  failed (out of memory)")`, state unchanged; the alignment-0 refusal moved AFTER that kill and its
  message text changed one cite (`impl_mem.ml:1252` → `:1258`). At upstream's bound no program
  observes either (row 10's Lean column unmoved).
- NEW module `CerbMemAllocatorProofs` (`import CerbMemAllocatorProofs`): `CerbMem.allocatorStep`,
  `CerbMem.allocator_active_sound` (statement in §C1.3 — the S2 heap slice's `create` rule can take
  `align ∣ a`, `0 < a`, `a + sz ≤ st.lastAddress`, `st'.lastAddress = a` from ANY active result,
  without assuming the cursor is above the request), `CerbMem.allocator_below_request_kills`.
- `MemState`, `initialMemState`, `initial_driver_state`, `drive`: UNCHANGED (C2 did not land).
PLANNED by the charter for C2 (NOT landed; for the consumer to anticipate, not to act on):
`initialMemState : MemState` → `initialMemState (addressSpaceTop : Int) : MemState`;
`MemState.lastAddress : Address := 0xFFFFFFFFFFFF` → no default (every `{ … : MemState }` literal
must give it); generated `initial_driver_state (sup : Nat) file fs : driver_state × Nat` →
`initial_driver_state (sup : Nat) (top : Int) file fs`; `initial_driver_state_given (sup : Nat)
file fs` → `… (top : Int) …`; `drive` unchanged; consumer theorems quantify `∀ top`; matched mode
instantiates `top = 0xFFFFFFFFFFFF` (= 281474976710655) from `Main.lean`'s `defaultAddressSpaceTop`.
Whether cerberus-sl's `create` rule can drop its bound assumption (its option (b)): for the
POSTCONDITION (disjoint, aligned, positive) YES already at C1 via `allocator_active_sound`; for
PROGRESS (that `create` is active at all) it still needs `st.lastAddress - sz ≥ align`-shaped room —
the theorem is about active results, by design.

## C3 — NOT STARTED (depends on C2). Draft 45 not drafted.

## FULL gate — GREEN at the C1b head `f9843725d` (C1's FULL gate for landing as part one)

Run ONCE at the C1b head, as the operator's instruction requires: `scripts/ce python3
scripts/release.py --mode full --out .tmp/c1b-release` (Tier A + B), then `scripts/ce python3
scripts/test_upstream_oracle.py --with-lean --out .tmp/c1b-three-engine`. Verbatim
(`c1b-full-gate-tails.txt` carries the runner lines and every lane's last verdict line):

```
head f9843725d8c4746449bde65f0bbfe6166bfe4d6d start 2026-09-17T15:07:02Z load 5.37 3.15 1.44
release_full rc=0 wall=5078s
three_engine rc=0 wall=258s
chain done 2026-09-17T16:35:58Z
```
Runner: `PASSED A1 (160.1s)`, `A2 (35.1s)`, `A3 (52.5s)`, `A4 (22.8s)`, `A4b (24.2s)`, `A4c (3.1s)`,
`A5 (23.8s)`, `A6 (2.2s)`, `A6b (3.6s)`, `A7 (10.4s)`, `A8 (8.9s)`, `A9 (17.3s)`, `A10 (17.2s)`,
`A11 (59.9s)`, `B1 (739.2s)`, `B2 (23.5s)`, `B3 (15.4s)`, `B4 (48.3s)`, `B5 (68.3s)`, `B6.1 (169.7s)`,
`B6.2 (2.3s)`, `B6.3 (9.5s)`, `B6.4 (9.0s)`, `B6.5 (9.8s)`, `B6.6 (10.4s)`, `B6.7 (9.1s)`,
`B7 (1409.2s)`, `B8.1 (13.4s)`, `B8.2 (224.9s)`, `B8.3 (6.4s)`, `B8.4 (16.0s)`, `B9 (1295.5s)`,
`B10.1 (115.4s)`, `B10.2 (1.7s)`, `B11.1 (14.9s)`, `B11.2 (6.7s)`, `B12 (416.5s)` — every row PASSED,
no FAILED/SKIP; `Source unchanged: True. Complete tier selection: True.`; `Release certification:
incomplete: reporting/adoption/audit exits require separate evidence.` (the runner's standing
wording: a completed tier is not a customer-ready release claim — LADDER.md).

Per-lane last verdict lines (verbatim): A1 `test_renumber_plants: OK (12 plants: refusals refuse,
admits admit with declared class)` (the test_unit battery, `Total: 11 passed, 0 failed` inside);
A2/A3/A4/A4b `BASELINE OK`; A4c `SUMMARY: exec_match=9 neg_pinned=5 fail=0`; A5 `ALL MATCH RECORDED
BASELINE`; A6/A6b/A7/A8 `ALL PASSED`; A9 `SUMMARY: total=111 same=108 diff=3 ocaml_fail=0
lean_fail=0` (the recorded 3 Z-40 pp-filter rows); A10 `GATE PASS: all lane expectations
pinned-green + baseline unchanged (16/16)`; A11 `BASELINE OK (213 entries, exact match)`; B1/B2/B3
`ALL PASSED`; B4 `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus
fixtures, 21 corpus points)`; B5 `OK: lane matches the committed baseline (MATCH except the ISO-fix
register pins R1 …, R2 …, R3 …, R5 … — VALIDAT…)`; B6.1 `test_speclab: PASS (both pipelines agree on
Specified(0))`; B6.2 `… Specified(2)`; B6.3–B6.7 `test_speclab_{divmod,bytearr,list,tree,seed}:
PASS (--gate)`; B7 `gcc second-oracle lane OK`; B8.1–B8.4 the four plant batteries' OK lines; B9
`observation lane plants: 93/93 passed`; B10.1 `Independent oracle: passed; {'semantic_agreement':
822, 'matching_failure': 28, 'reviewed_difference': 3, 'interface_agreement': 2}`; B10.2
`Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok':
51}`; B11.1 `check_failure_reach: SELFTEST OK (5 plants …)`; B11.2 `check_failure_reach: OK (233
pure failure sites = the 233 register rows exactly …)`; B12 `Independent oracle: passed;
{'semantic_agreement': 4}`.

ZERO movement of any existing baseline row anywhere (the fix is unobservable at upstream's
bound). Load caveat (LADDER.md, B7): the box carried other agents' work during the run (load 16–26
in B1/B7; a restic backup, codex processes) — B1's Lean side ran 1.5–2.5 min/slice against its
~1 min norm and B7 took 1409 s against ~24 min — with NO TIMEOUT-class movement anywhere (B7 `OK`,
B5 at baseline), so no re-run on a quiet box is owed.

The three-engine report at the same head, verbatim: `Three-engine report (Lean column, NOT
gating): {'lean_agreement': 813, 'lean_difference': 28, 'lean_both_undecodable': 12,
'lean_not_applicable': 2}; Lean≠fork rows: 40: …` (the same 40 pinned rows as WP-O and as after
C1) and `Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28,
'reviewed_difference': 3, 'interface_agreement': 2}` — the Lean column is unchanged, pristine vs
fork is at WP-O O5's verdict, and NO register row was added (the allocator deviation is
unobservable on every walked corpus, as §C1.5 claims).

## Measurements (wall clock, this box)

C1: `test_unit.sh` 170 s (incl. the incremental Lean rebuild downstream of `CerbMem` and all 11
exes); exec rows 33 / 51 / 23 / 24 s; OCaml rebuild (incremental) ~7 s; `CerbMem` module rebuild
1.7 s, proof module 0.3 s, test exe link 0.2 s; row 10 114 s; three-engine 252 s; pre-fix probe
~10 s. C1b: `--plant` ~10 s; row 10 114 s; `ci` 137 s; `test_unit.sh` 151 s; FULL gate 5078 s
(≈ 85 min under load 16–26 shared with other agents; Tier A ≈ 7.5 min of it, B1 12.3 min, B7
23.5 min, B9 21.6 min, B12 6.9 min) + three-engine 258 s. Worker wall for part one (reading →
this amendment) ≈ 4 h 10 min; no single non-battery step above ~5 min; the FULL gate is the
operator-requested landing certification (its ~1 h+ is the "long builds of real content" case,
not a grind).

## Open items

1. ~~[operator] §S1 resolution~~ — RESOLVED by the [USER 2026-09-17] ruling and C1b (§S1).
2. **[orchestrator] C2/C3 re-charter (part two)** — option (A) with the extended fence (E1–E3), per
   the ruling; the §C2 options and the planned signature list stand as written.
3. `check_theorem_axioms.sh`'s `#print axioms` probe leg does not name `allocator_active_sound`
   (out of fence); `c1-theorem-axioms.txt` is the evidence meanwhile.
4. E7's wording in `VALIDATION.md` §3 (worker's amendment) and the C1b sentences in §0/§3 and
   `LADDER.md` row 10, for the orchestrator's review; `VALIDATION.md` §5's lane-table row for
   `test_upstream_oracle.py (+ --plant)` still describes the pre-C1b plant set (out of fence).
5. Draft 45 (optional) — not drafted; the facts for it are §C2 (A) and tray 44.
6. cerberus-sl option (b): see the RE-PIN NOTE's last paragraph.
7. `.tmp/` artefacts (`c1-*.log`, `c1b-*.log`, `c1b-release/`, `c1b-three-engine/`,
   `upstream-oracle-*`, `g2/`, `ocaml-witness/`, `lean_frontend/.tmp/*Probe.lean`) are ephemeral per
   the container rule; everything cited is in the evidence directory.
