# Record — allocator soundness (tray 44) + the address-space bound as a quantified parameter + the fork-only OCaml flag (2026-09-16) — PART ONE (C1 + C1b + C1c) COMPLETE, AUDITED, FULL-GATE GREEN; C2/C3 RE-CHARTERED SEPARATELY

**Status [AGENT, worker, 2026-09-17]:** PART ONE of the slice is COMPLETE and is the landing
candidate: **C1** `7b51b0b438052d47551009b9f65464d3030e9bf3` (remedy 1 in both OCaml models + the
Lean mirror + the GENERAL kernel theorem + the runtime witness; §C1), **C1b**
`f9843725d8c4746449bde65f0bbfe6166bfe4d6d` (the row-10 diagnostic projection extended to the
OCaml exception HEADER line, resolving §S1) and **C1c** `b7fec4d63c3069776a728737ddf8e1b32ace0c44`
(the independent pre-merge audit's fixes — its MAJOR M1: the deviation IS observable at upstream's
bound; §M1). The FULL gate (`release.py --mode full`, Tier A + B) is GREEN at the C1c head and the
three-engine report shows the two new witnesses `pristine ≠ fork = Lean` (§FULL, verbatim).
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

**Part one / part two.** Part one = C1 + C1b + C1c (+ this record) on
`arc/allocator-soundness-address-bound`, the landing candidate; audited by an independent auditor
(`worktrees/cerberus-lean-audit/allocator-part-one`,
`lean_frontend/docs/2026-09-17_allocator-part-one-audit-premerge.md`, `c46b303ac` on
`audit/allocator-part-one`: MERGE-WITH-FIXES — one MAJOR, two MINOR, eight NOTEs; the fixes are C1c,
§M1). C1's fix content and C1b's projection are exactly as committed (`7b51b0b43`, `f9843725d`). Part two = C2 (route A: the address-space bound
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
- **E11 (pre-merge audit M3; corrects the "All §1 cites re-verified and CORRECT" sentence above).**
  The pristine ROUNDING line is `memory/concrete/impl_mem.ml:1254` (VIP `:209`); `:1253`/`:208` are
  the `quomod` lines (`1252 let z … / 1253 let (q,m) = quomod … / 1254 let z' = sub z (if q < zero …)`).
  The charter (`:1253`), tray 44 (`:3`, `:15`) and this record's C1 texts carried the off-by-one; the
  worker re-asserted it as verified — wrong. Corrected in C1c everywhere (tray, VALIDATION §3, the
  `CerbMem.lean` docstring, here).
- **E12 (pre-merge audit M1 — MAJOR; the charter's §1 "Observability" paragraph was FALSE).** "Matched
  mode therefore instantiates the bound to upstream's value … every existing baseline row must be
  unmoved" was true, but the tray's premise it rested on — "No C program reaches the regime at the
  default bound … ~2^48 bytes of cumulative allocation" — is false: ONE request larger than the
  cursor by less than `align/2` reaches it (§M1). The worker propagated the false premise into
  VALIDATION §3, the drift header, the docstring, this record and the tray; all corrected in C1c.

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
the immaculate `zd-z2m01-*` rows are CLASS pins: `zd-z2m01-aligned-alloc-zero-zero` `MATCH | L=CRASH`,
the other two `ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", …}` — audit N4(a) corrected the
worker's "all three MATCH | L=CRASH").

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
unchanged — no `.lem` touched). `VALIDATION.md` §3 "Fork ≠ pristine": at C1 an entry labelled
UNOBSERVABLE with no register row — that label was FALSE (audit M1) and C1c replaced the entry by
the two-row `shared-model-fix` bullet (§M1). Tray 44 "Fork status": the LANDED line (this record's
commit adds the hash). `lean_frontend/CLAUDE.md`: key-files row + unit-test list.
`scripts/upstream_oracle_differences.json`: untouched at C1; two rows at C1c.

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
separately"* — on the orchestrator's three-part proposal, whose item (1) [AGENT orchestrator],
verbatim (audit M2 asked for the chain to be verifiable here): *"Extend the projection to normalise
the position in the exception header, keeping the exception kind and file path compared. I recommend
this. Every future edit above that line, including C2's, would otherwise re-trip the lane."* — i.e.
recommendation (ii) above; `VALIDATION.md` §3 cites this paragraph. The worker's fence was
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

## M1 — The pre-merge audit's MAJOR: the deviation IS OBSERVABLE at upstream's bound — RESOLVED by C1c `b7fec4d63c3069776a728737ddf8e1b32ace0c44`

**The finding** (independent auditor, `docs/2026-09-17_allocator-part-one-audit-premerge.md` M1;
reproduced by the orchestrator, then by the worker — verbatim runs below): the exhausted regime
`z = last_address − sz < 0` with `−align/2 < z` is reached by ONE `malloc` request larger than the
cursor by less than `align/2`, not by ~2^48 bytes of cumulative allocation. A program reads its own
cursor as `(uintptr_t)malloc(1)`; `malloc_proxy` (`std.core:350`) `create`s an 8-byte argument
temporary before `alloc` runs, so the cursor at `alloc` is `a − 8`; `IvMaxAlignment` is 8; a request
of `a − 7` bytes gives `z = −1` and pristine returns `z' = z + (z mod 8) = 6`. The auditor's
13-line witness (`repro/w1-minus7.c`, now `tests/minimal/112-allocator-exhausted-single-request.c`)
and its self-checking variant (`w1-overlap.c`, now `113-…-overlap.c`: exit = low byte + 100 if the
object ends above the cursor + 50 if 8-aligned), run as `tests/minimal` is run (`--nolibc --exec
--batch --mode=exhaustive`; Lean through the exec lane's bridge recipe), fresh on this tree
(`c1c-witnesses-three-engines.txt`), verbatim:

```
### 112-allocator-exhausted-single-request / pristine
Defined {value: "Specified(6)", stdout: "", stderr: "", blocked: "false"}
[rc=0]
### 112-allocator-exhausted-single-request / fork
Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
[rc=1]
### 113-allocator-exhausted-single-request-overlap / pristine
Defined {value: "Specified(106)", stdout: "", stderr: "", blocked: "false"}
[rc=0]
### 113-allocator-exhausted-single-request-overlap / fork
Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
[rc=1]
### 112-allocator-exhausted-single-request / LEAN (cerberus-lean --batch, LEAN_ABORT_ON_PANIC=1, capped, …)
Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
[rc=1]
### 113-allocator-exhausted-single-request-overlap / LEAN (…)
Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
[rc=1]
```
— pristine's SUCCESSFUL allocation at address 6 is not 8-aligned and its object ends above the
cursor (overlapping the live temporary): the complete defect signature of draft 44, at upstream's own
bound, in ~40 ms; the fork and Lean kill identically. So the fork≠pristine deviation was OBSERVABLE
and — by `VALIDATION.md` §0's own doctrine ("a delta with no register row is either unobservable on
the corpora or a missing case") — a MISSING register case; the "UNOBSERVABLE … ~2^48" text in
VALIDATION §3, the drift header, the `CerbMem.lean` docstring, this record and tray 44 was FALSE.

**Ruling chain.** [USER 2026-09-17] *"yes, agreed regarding landing C1 as-is and then working on
C2/C3 separately"* (the part-one landing); the orchestrator reproduced M1 and directed C1c as ONE
commit with the fence extended to exactly the files below, plus a supplement (the ISO citation and
the idiom's history). Every C1c decision below is [AGENT worker] within that fence.

**What C1c did (`b7fec4d63`).**
(a) `tests/minimal/112-allocator-exhausted-single-request.c`, `113-allocator-exhausted-single-request-overlap.c`
(headers cite tray 44 and the audit report path). `scripts/exec_baseline.txt`: two new rows via the
lane's own `./scripts/test_exec.sh --write-baseline` — its output is **`CERB_SKIP`** for both
(`c1c-exec-lane-class.txt`), NOT the MATCH the instruction anticipated: `test_exec.sh:553-558`
classes an oracle `Error {` line as an oracle-side non-comparison and never samples Lean ("both
engines kill" is not expressible as agreement in that lane's taxonomy). No existing row moved
(`Baseline check: 0 regression(s), 0 improvement(s)`; `total=111 → 113`, `cerb_skip 3 → 5`). The
files' headers say so. **Fence limit for the orchestrator:** making a fork-vs-Lean LANE gate these
files needs `test_exec.sh` (an agreement class for both-engines-`Error`, keyed on the exact message)
or class pins in `tests/immaculate` — both outside C1c's fence; the fork = Lean evidence is the
three-engine report (Tier C row C5: both witnesses `lean_agreement` — the shared codec DOES read the
identical `Error` line as agreement) and the by-hand runs above.
(b) `scripts/upstream_oracle_differences.json`: two `shared-model-fix` rows (schema 2; citations =
tray 44 + this record; rationale = pristine's ACTIVE misaligned overlapping allocation vs the fork's
kill, C11 §7.22.3#1, the idiom's history; signatures harvested from a row-10 run on this tree —
upstream `status 0`, stdout sha `75f0c56b…` (112) / `e17cb1bc…` (113); fork `status 1`, stdout sha
`ce222125…` (both); diagnostic sha `e3b0c442…` = empty stderr). Before the rows the same tree read
`Independent oracle: failed; {'semantic_agreement': 822, 'matching_failure': 28, 'difference': 2,
'reviewed_difference': 3, 'interface_agreement': 2}`; after: `reviewed_difference: 5`.
(c) Reclassified, every "unobservable"/"~2^48 cumulative" statement deleted: `VALIDATION.md` §3 (the
entry is now the register-row bullet "the allocator's EXHAUSTED regime (2 rows)": OBSERVABLE at
upstream's bound by a single request within `align/2` of the cursor; UNOBSERVED by the previously
walked corpora; the §3 intro turns the erratum into doctrine — "unobserved on the corpora" is a claim
to be tested by seeking a witness), §0 ("exactly 5 `shared-model-fix` rows"); the drift manifest
(a dated C1c header CORRECTION note, the C1 note's line corrected in place, no pin moved); the
`CerbMem.lean` docstring; this record (E12, §C1.5, §FULL).
(d) Tray 44: the Reproducer's "No C program reaches the regime …" struck with a dated [AGENT] erratum
crediting the audit, the witness program and the three-engine runs added; Impact: "one request
larger than the cursor"; Classification: **TRUE BUG (model soundness AND ISO §7.22.3#1)** with C11
§7.22.3#1 quoted verbatim from `tools/n1570.json` (*"The pointer returned if the allocation succeeds
is suitably aligned … Each such allocation shall yield a pointer to an object disjoint from any other
object."*); Description: the idiom is ORIGINAL, not a regression — at upstream `adee05e5a^` (before
the 2026-05-19 commit "Remove indirect use of Z through Lem's Nat_big_num") the allocator read
`let (q,m) = quomod z align in let z' = sub z (if less q zero then negate m else m)` with
`N = Nat_big_num`, whose `quomod = Big_int.quomod_big_int` is ALSO Euclidean (orchestrator's probe:
`Big_int.quomod_big_int (-1) 4 = (-1, 3)`, `(-5) 4 = (-2, 3)`); the fix-up is what one writes for
C-style TRUNCATING division. INDEX entry 44 re-slotted (no longer "minor at the default bound").
(e) M3: `:1253` → `:1254`, VIP `:208` → `:209` (tray, VALIDATION §3, docstring; E11 here). N1: the
gloss "disjoint from everything at or above the cursor" → "its end `a + sz` at or below the cursor
(disjoint from everything at or above it, for `sz ≥ 0`)" in `CerbMemAllocatorProofs.lean`,
`CerbMem.lean`, VALIDATION §3, `lean_frontend/CLAUDE.md`; the kernel statement is untouched. M2: §S1
above. N3: the three §S1 lines re-sourced into `c1-row10-difference-g2-memcmp-uninit.txt`. N4(a):
§C1.2 corrected.

**Pre-commit gates at C1c (verbatim; `c1c-gates.txt`):**
```
row10 rc=0 wall=115s
112/857 reviewed_difference: minimal/112-allocator-exhausted-single-request.c (pristine 0.0s, fork 0.0s)
113/857 reviewed_difference: minimal/113-allocator-exhausted-single-request-overlap.c (pristine 0.0s, fork 0.0s)
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 5, 'interface_agreement': 2}
plant rc=0 wall=2s
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
ci rc=0 wall=137s
Independent oracle: passed; {'semantic_agreement': 134, 'matching_incomplete': 2, 'matching_failure': 106}
exec-baseline rc=0 wall=28s
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
test_unit rc=0 wall=154s
Total: 11 passed, 0 failed
```

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
- The fix IS observable (audit M1, §M1): a program whose single allocation request exceeds the cursor
  now kills out-of-memory instead of receiving an overlapping, misaligned address — cerberus-sl's
  `create` rule is exactly what this protects (`tests/minimal/112-…` is the witness; C11 §7.22.3#1).
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

## FULL gate — GREEN at the C1c head `b7fec4d63` (part one's FULL gate for landing)

Run ONCE at the C1c head, as the orchestrator's instruction requires: `scripts/ce python3
scripts/release.py --mode full --out .tmp/c1c-release` (Tier A + B), then `scripts/ce python3
scripts/test_upstream_oracle.py --with-lean --out .tmp/c1c-three-engine`. Verbatim
(`c1c-full-gate-tails.txt` carries the runner lines, every lane's last verdict line, and the new
files' rows in A2/A9/B7/B10.1 and the three-engine report):

```
head b7fec4d63c3069776a728737ddf8e1b32ace0c44 start 2026-09-17T18:40:35Z load 0.66 0.88 0.96
release_full rc=0 wall=4735s
three_engine rc=0 wall=257s
chain done 2026-09-17T20:03:47Z load 1.77 1.65 1.53
```
Runner: every row PASSED, no FAILED/SKIP — A1 … A11, B1 … B12 (37 rows; `B7 (…)`, `B9 (1307.8s)`,
`B12 (418.5s)` the long ones — timings in the evidence file); `Source unchanged: True. Complete tier
selection: True.`; `Release certification: incomplete: reporting/adoption/audit exits require
separate evidence.` (the runner's standing wording — LADDER.md).

The rows that SEE the two new `tests/minimal` files, verbatim: A2 (`test_exec.sh --check-baseline`)
`[112/113] CERB_SKIP 112-allocator-exhausted-single-request (error: MerrOther )`, `[113/113] CERB_SKIP
113-…-overlap (error: MerrOther )`, `SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0
fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0`,
`Baseline check: 0 regression(s), 0 improvement(s)`; A9 (`test_elab.sh`) `SUMMARY: total=113 same=108
diff=5 ocaml_fail=0 lean_fail=0` — MOVED from `total=111 … diff=3`: `[112/113] DIFF 112-…`, `[113/113]
DIFF 113-…` join `073-exit.libc`, `074-abort.libc`, `098-cross-alloc-ptrdiff.undef` in the lane's
documented one-sided DIFF class for `#include`-declared functions (`test_elab.sh` header: "Header-
defined functions … will still show as one-sided DIFFs — known, recorded"; `stdlib.h`'s `malloc`,
as 073/074) — no baseline is pinned for this lane, rc 0; the recorded state is now 108/5; A7/A8
(`test_parse.sh`, `test_core.sh`) `ALL PASSED` over 113 files; B7 (`test_gcc_oracle.sh
--check-baseline`) `[112/1999] SKIP_LEAN_FAIL tests/minimal/112-…: msg: "MerrOther "`, `[113/1999]
SKIP_LEAN_FAIL … 113-…`, `new file (not in baseline, not fatal): tests/minimal/113-…
SKIP_LEAN_FAIL/-`, `new file (not in baseline, not fatal): tests/minimal/112-… SKIP_LEAN_FAIL/-`,
`gcc second-oracle lane OK` (the skip ledger `scripts/gcc_oracle_baseline.txt` has no rows for them
yet — a dedicated instrument commit, outside this fence: open item); B10.1 (row 10)
`112/857 reviewed_difference: minimal/112-… | 113/857 reviewed_difference: minimal/113-…`,
`Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28,
'reviewed_difference': 5, 'interface_agreement': 2}`; B10.2 `plants_passed; {'semantic_agreement':
1, 'plant_rejected': 1, 'plant_ok': 51}`; B12 `passed; {'semantic_agreement': 4}`. Every other
lane's last line is as at C1b (`c1c-full-gate-tails.txt`): A4c `SUMMARY: exec_match=9 neg_pinned=5
fail=0`, A10 `GATE PASS … (16/16)`, A11 `BASELINE OK (213 entries, exact match)`, B4 `test_verify:
127 passed, 0 failed …`, B5 at baseline, B6.x PASS, B8.x plants OK, B9 `observation lane plants:
93/93 passed`, B11 `check_failure_reach: OK (233 …)`.

ZERO movement of any PINNED baseline row anywhere; the only recorded-state movement is A9's
unpinned DIFF tally (3 → 5, the two new files, known class). Quiet box this time (load 0.7–1.8).

The three-engine report at the same head, verbatim:
```
112/857 reviewed_difference: minimal/112-allocator-exhausted-single-request.c (pristine 0.0s, fork 0.0s) | lean: lean_agreement
113/857 reviewed_difference: minimal/113-allocator-exhausted-single-request-overlap.c (pristine 0.0s, fork 0.0s) | lean: lean_agreement
Independent oracle scope: tier-b; 857 rows in 257.0s; source unchanged: True
Three-engine report (Lean column, NOT gating): {'lean_agreement': 815, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}; Lean≠fork rows: 40: …
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 5, 'interface_agreement': 2}
```
— the two witnesses appear as `pristine ≠ fork = Lean` (`reviewed_difference` by their rows;
`lean_agreement`); the Lean column is WP-O's plus exactly those two agreements (813 → 815; the 40
Lean≠fork rows unchanged, all pinned); no register row beyond the two written.

## Measurements (wall clock, this box)

C1: `test_unit.sh` 170 s (incl. the incremental Lean rebuild downstream of `CerbMem` and all 11
exes); exec rows 33 / 51 / 23 / 24 s; OCaml rebuild (incremental) ~7 s; `CerbMem` module rebuild
1.7 s, proof module 0.3 s, test exe link 0.2 s; row 10 114 s; three-engine 252 s; pre-fix probe
~10 s. C1b: `--plant` ~10 s; row 10 114 s; `ci` 137 s; `test_unit.sh` 151 s; FULL gate 5078 s
(≈ 85 min under load 16–26 shared with other agents; Tier A ≈ 7.5 min of it, B1 12.3 min, B7
23.5 min, B9 21.6 min, B12 6.9 min) + three-engine 258 s. C1c: by-hand three-engine runs ~1 s
each; exec single-file ×2 42 s (incl. the Lean rebuild after the docstring change); `--write-baseline`
27 s; row-10 harvest 116 s; row 10 115 s; `--plant` 2 s; `ci` 137 s; `test_exec --check-baseline`
28 s; `test_unit.sh` 154 s; FULL gate 4735 s (≈ 79 min on a quiet box: B7 ~23 min, B9 ~22 min, B1
~12 min, B12 ~7 min) + three-engine 257 s. Worker wall for part one (reading → this amendment)
≈ 7 h; no single non-battery step above ~5 min; the two FULL gates are the operator-requested
landing certifications (the "long builds of real content" case, not a grind).

## Open items

1. ~~[operator] §S1 resolution~~ — RESOLVED by the [USER 2026-09-17] ruling and C1b (§S1).
2. **[orchestrator] C2/C3 re-charter (part two)** — option (A) with the extended fence (E1–E3), per
   the ruling; the §C2 options and the planned signature list stand as written. The C2/C3 rationale
   "observable only at a tiny bound through the fork-only flag" is gone (M1): the tiny-bound lane
   widens the witness set, it does not create it.
3. **[orchestrator] fork-vs-Lean GATING of the two witnesses** (C1c fence limit, §M1(a)): the exec lane
   records them `CERB_SKIP` and never samples Lean; the three-engine report (Tier C, report-only)
   reads them `lean_agreement`. Options: an exec-lane agreement class for both-engines-`Error` keyed
   on the exact message (`test_exec.sh`), or class pins in `tests/immaculate`; both outside the fence.
4. **[orchestrator] `scripts/gcc_oracle_baseline.txt`** has no rows for the two new files (B7: "new file
   (not in baseline, not fatal) … SKIP_LEAN_FAIL/-") — a dedicated instrument re-record, outside the
   fence.
5. `check_theorem_axioms.sh`'s `#print axioms` probe leg does not name `allocator_active_sound` /
   `allocator_below_request_kills` (audit N6; out of fence); `c1-theorem-axioms.txt` is the evidence.
6. E7's wording in `VALIDATION.md` §3, the C1b sentences in §0/§3 and `LADDER.md` row 10, and C1c's
   §3 rewrite, for the orchestrator's review; `VALIDATION.md` §5's lane-table row for
   `test_upstream_oracle.py (+ --plant)` still describes the pre-C1b plant set and the 3-row register
   (audit N4(b); out of fence). LADDER row 10's "Verdict at WP-O O5 … exactly the 3 tray rows" is a
   dated historical line and stands.
7. Draft 45 (optional) — not drafted; the facts for it are §C2 (A) and tray 44.
8. Audit N5 (out of range): `(size_t)x + 1` truncates to 32 bits on all three engines — a shared-model
   front-end/semantics defect candidate for the upstream tray (pre-existing; zero-discrepancy holds);
   not a merge item.
9. cerberus-sl option (b): see the RE-PIN NOTE's last paragraph.
10. `.tmp/` artefacts (`c1-*`, `c1b-*`, `c1c*`, `c1c-release/`, `c1c-three-engine/`,
    `upstream-oracle-*`, `g2/`, `ocaml-witness/`, `lean_frontend/.tmp/*Probe.lean`) are ephemeral per
    the container rule; everything cited is in the evidence directory.
