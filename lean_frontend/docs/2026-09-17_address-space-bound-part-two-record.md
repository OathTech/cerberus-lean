# Record — address-space bound, PART TWO (2026-09-17) — INTERIM: C0 LANDED (the witnesses' gating pin); C2/C3 STOPPED at the design step (stop rules S2 + S6: the chartered C2 ripples into gate-compiled and exported sites outside the fence)

**Status [AGENT, worker, 2026-09-17]:** **C0 is COMPLETE and LANDED** on `arc/address-space-bound-part-two` as
`bda7a3e1b14868699e68682e6d18fe979412b323` (two `tests/immaculate/nolibc` GATING copies of the tray-44 witnesses, the immaculate re-record
showing EXACTLY two new rows, their two `shared-model-fix` register rows, four gcc-ledger rows — §C0, every gate
verbatim). **C2 was NOT started**: before any edit, the design step found that the chartered route A cannot be
implemented inside the §3 fence — the `initialMemState (addressSpaceTop : Int)` signature breaks a GATE-compiled
Lean probe outside the fence (`tests/immaculate/illtyped-store.lean:44`, run by `test_immaculate.sh:233-241`,
Tier B row 5 and C2's own FAST-GATE), the desugar-state threading needs two `.lem` sites the fence does not
name (`cabs_to_ail_effect.lem` `eval`, `mini_pipeline.lem` `evalConstantExpressionAux`), and the OCaml
threading needs `backend/common/pipeline.mli` (exported signatures; layer-1 pinned) — §C2 has the COMPLETE
ripple map and the fence extension the re-charter needs, so one round trip closes it. **C3 depends on C2.**
This record is the interim stop; it ENDS the worker's turn. Charter:
`docs/2026-09-17_charter-address-space-bound-part-two.md` (`ea517c1f9`, on mainline `e64819de7`); part one:
`docs/2026-09-16_allocator-soundness-address-bound-record.md`. Evidence directory:
`docs/2026-09-17_address-space-bound-part-two-evidence/` (every quoted output below is a file there).

## 0. Rulings (by pointer; verbatim texts in the charters' §0)

Part two §0: [USER 2026-09-17] the C1-lands-first / C2-C3-separately agreement (route A, extended fence);
[USER 2026-09-17] the consumer confirmation ("part 1 is exactly what they need"; part two "modest blast
radius" — the re-pin note lists signatures and stops); [USER 2026-09-17] the sequence (part two → enum
registry → concurrency). Part one §0: [USER 2026-09-16] the bound is a quantified parameter whose matched-mode
instance is upstream's value; the fork-only OCaml flag is wanted; [USER 2026-09-03] no magic values; [USER
2026-09-08] nothing new out of policy; the standing constraints. Every decision below is [AGENT worker] with
its one-line reason.

## 1. Errata to the charter's §1/§2 (re-checked against THIS tree, `ea517c1f9` = `e64819de7` + the charter)

All §1 cites re-verified and CORRECT unless listed: `test_exec.sh:553-558` (`Error {` → CERB_SKIP);
`test_immaculate.sh` `:94`/`:129` (the `ERR:` token — verdict() at `:100-134`), the record block `:245-322`
(the charter's `:59-79` is the option parsing / prerequisites; the header text is regenerated at `:245-321`);
gcc ledger header `:6-7`; `concrete/impl_mem.ml:503-516` (`:508`), `vip:170` (literal `:175`), `symbolic:569`,
`cheri-coq:271`; `memory_model.ml:39`; `mem.lem:41-45`; `CerbMem.lean:153`/`:1780`; generated `Driver.lean:489`
`layout_state := CerbMem.initialMemState`; `driver.lem:1520/:1526/:1535/:1540`; `driver_ocaml.ml:157/:198`,
`driver_conf .ml:11-16` / `.mli:3-8`; `web/instance.ml:635`, `web/dune:10-19`, `rt_ocaml.ml:355`;
`common.sh:193/:231`; `cabs_to_ail.lem:1135/:1137/:4973-4975`; `mini_pipeline.lem:163/:201-206`;
`cabs_to_ail_effect.lem:224/:240/:577-578/:582`, `get_fresh_sym_supply :694`; `pipeline.ml:206`;
`Main.lean:521/:1019/:1150/:1251-1279`; `main.ml:99/:219/:521-524/:566`; `ALLOW_MAIN` opens at
`check_no_fuel_numerals.sh:70`; drift rows for all four `impl_mem.ml` (`:381-384`), `driver_ocaml.ml{,i}`
(`:321-322`), `pipeline.ml{,i}` (`:323-324`), `main.ml` (`:326`), `memory_model.ml` (`:387`).

- **E1 (C2 — an S2 trigger).** `mini_pipeline.lem:163` (`Driver.initial_driver_state_given sup_after_elab
  dummy_core_file Fs.fs_initial_state`) is inside `evalConstantExpressionAux` (`val :88-93`, `let :95`), NOT
  inside `evalIntegerConstantExpression` (`:201-206`, which calls Aux at `:221`). The charter's "`→ :163`"
  glosses the intermediate definition: threading a bound to `:163` changes `evalConstantExpressionAux`'s
  `val`/`let` — a `.lem` site the fence does not name ("`evalIntegerConstantExpression`'s signature and
  `:163`" only). Aux has no other caller (grep: `:221` only).
- **E2 (C2 — an S2 trigger).** `desugar` does NOT seed `E.initial_state` directly: `cabs_to_ail.lem:5050`
  `E.eval sup core_eval_stuff cn_eval_stuff (…)` → `cabs_to_ail_effect.lem:702-710` `val eval: forall 'a. nat ->
  … -> desugM 'a -> …` / `let cabs_to_ail_effect_eval sup core_eval_stuff cn_eval_stuff m = State_exception.eval
  begin … end (initial_state sup core_eval_stuff cn_eval_stuff)` / `let inline eval = cabs_to_ail_effect_eval`.
  So `eval`'s `val`/`let` gain the parameter too — the fence names only "the `state` field, `initial_state`,
  one getter". The charter's §1 also omits `initial_state`'s only caller, `:709`.
- **E3 (C2 — an S6 trigger: fence vs typecheck).** `pipeline.ml:206`'s `Cabs_to_ail.desugar 0 …` sits in the
  LOCAL `let desugar cabs_tunit` (`:200`) of `c_frontend` (`:180`), whose signature — and the `configuration`
  record (`:72-84`) — is EXPORTED by `backend/common/pipeline.mli` (`val c_frontend`, `val
  c_frontend_and_elaboration`, `type configuration`). Any carrier of the bound from `main.ml` to `:206` (a
  `configuration` field or a labelled argument) changes `pipeline.mli`, which the fence does not list
  (`backend/common/{driver_ocaml.ml,driver_ocaml.mli,pipeline.ml}`) and which is a layer-1 drift pin
  (`fork_drift_manifest.txt:324`). Downstream: a `configuration` FIELD touches its two other constructors
  (`backend/bmc/main.ml:105`, `backend/web/instance.ml:46`, both unbuilt); a labelled ARGUMENT touches the
  eight other callers of `c_frontend_and_elaboration` (`backend/{playground,rustic,ail_playground,absint,
  bmc,ocaml/driver}/main.ml`, `backend/web/instance.ml:101`, all unbuilt). Recommendation §C2: the FIELD.
- **E4 (C2, unbuilt OCaml).** `backend/ocaml/runtime/rt_ocaml.ml:200-204` use `M.initial_mem_state` FIVE more
  times (`eq`/`lt`/`gt`/`le`/`ge`: `Option.get (M.eq_ival (Some M.initial_mem_state) n m)`) — the charter fences
  `:355` only; `backend/bmc/bmc_utils.ml:197` `f (Impl_mem.initial_mem_state)` — the charter's "`backend/bmc/`
  does not call the builder" is true of `initial_driver_state` and FALSE of `initial_mem_state`. Both files are
  unbuilt (rt_ocaml's `dune` stanza is commented out; bmc is package `cerberus-bmc`, needs `z3`, not in the
  switch): LATENT breakage under C2's `initial_mem_state: Z.t -> mem_state`, of the E2-of-part-one kind.
- **E5 (C2 — THE S6 trigger; a GATE breaks).** The charter's Lean caller list (Main, FuelExemplar,
  FuelFormsTool, the five SLUnit tests, MonadicFailstop) omits two consumers part one's record E3 named:
  `tests/immaculate/illtyped-store.lean:44` `| ND f => (f initialMemState).1` — this in-Lean probe is COMPILED
  AND RUN by `test_immaculate.sh:233-241` (`lake env lean --run "$CORPUS/illtyped-store.lean" --fuel …`; a
  compile error yields no `ILLTYPED_STATUS` line and the lane `fail`s), i.e. Tier B row 5 and C2's own
  FAST-GATE, so the chartered `initialMemState (addressSpaceTop : Int)` cannot land without editing a file
  outside the fence; and `tests/mem-scale-probes/micro/Micro.lean:68-104` (`initialMemState` ×5, the
  `memscale-micro` Lake package) — built only by `scripts/build_provider_smoke.py` (the consumer-pin smoke
  instrument, `PACKAGES` at `:27`; no LADDER tier; `scripts/test_release.py:229-245` exercises that provider on
  a FIXTURE tree, not this one), so LATENT, not gate-breaking. `AllocatorSoundnessTest.lean:33` `{ lastAddress
  := last }` and the two `docs/…audit-evidence/*.lean` probes give the field explicitly and keep compiling.
- **E6 (C0 — count).** The gcc lane's default corpus INCLUDES `tests/immaculate/nolibc` (`test_gcc_oracle.sh:179`),
  so the two immaculate copies C0(a) adds are "new file" rows there too: the chartered bar "no `new file`
  lines" needs FOUR ledger rows (the two `tests/minimal` twins + the two copies), not the two the charter and
  its fence count. [AGENT] four rows, all at their OBSERVED status (§C0(c)); the fence's "two new rows" was the
  author's tally of the same instrument change, and two rows would have left the chartered bar red.
- **E7 (C0 — instrument).** `test_immaculate.sh --record-baseline` rewrites `tests/immaculate/baseline.txt`
  from a HARDCODED header block (`:245-321`) and therefore DROPPED fourteen hand-added header lines (the R5 pin
  note and the Finding-3 pins note, old lines 77-90; `c0-immaculate-baseline.diff` shows the raw re-record
  removing them). [AGENT] restored verbatim by hand so the committed diff is EXACTLY the two new rows (the
  charter's bar). The script is outside the fence; open item.
- **E8 (operational).** The primed worktree's `lean_frontend/generated/` and Lean binary PREDATED part one:
  `build_lean` REFUSED (`CERB_DRIVER_STALE … CerbMem.lean not propagated … CerbMemAllocatorProofs.lean
  missing` — the sync gate, fail-closed as designed); `scripts/ce make lean-prelude-src` moved exactly
  `CerbMem.lean` (+ `CerbMemAllocatorProofs.lean` new) and every lem-generated file was byte-identical
  (`c0-regen-generated-delta.txt`); both engines then rebuilt green (`c0-engine-rebuild-tail.txt`: `build_cerberus
  rc=0`, `✔ [285/285] Built «cerberus-lean»:exe`, `build_lean rc=0`). The priming step should run the regen.
- **E9 (trivial cites).** The fork-only interface entry is `scripts/test_upstream_oracle.py:840-843` (part one's
  E8 said `:787`); the immaculate `--record-baseline` code is `:245-322` (charter `:59-79`).

## C0 — The witnesses' gating pin and the gcc ledger — LANDED `bda7a3e1b14868699e68682e6d18fe979412b323`

**(a) The two immaculate copies.** `tests/immaculate/nolibc/tray44-allocator-exhausted-single-request.c` and
`tray44-allocator-exhausted-single-request-overlap.c`: program bodies BYTE-IDENTICAL to `tests/minimal/112-…`
/ `113-…` (checked by `diff` from the first `#include`), fresh headers citing tray 44, part one's record §M1 /
open item 3, the charter, the exec lane's CERB_SKIP reason, the pinned row and the register key. [AGENT] name
prefix `tray44-`: the directory's register-id prefix convention (`r5-` = ISO-fix register R5) with the tray id
spelled out, distinct from the `g`/`f`/`s`/`zd` audit-finding prefixes. The lane's own `--record-baseline`
(`c0-immaculate-record-lane-output.txt`), verbatim:
```
  MATCH          tray44-allocator-exhausted-single-request  O[ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}] L[ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}]
  MATCH          tray44-allocator-exhausted-single-request-overlap  O[ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}] L[ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}]
```
The committed `tests/immaculate/baseline.txt` vs mainline (`c0-immaculate-baseline.diff`, after E7's header
restoration), verbatim — the ONLY change, two new rows, no existing row moved (S1 not triggered):
```
126a127,128
> tray44-allocator-exhausted-single-request MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
> tray44-allocator-exhausted-single-request-overlap MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
[diff rc=1]
```
Both engines' kill on the exhausted regime is now GATED fork-vs-Lean (Tier B row 5), closing part one's open
item 3; the `tests/minimal` twins stay `CERB_SKIP` in the exec lane, as recorded.

**(b) The register rows.** Row 10 walks the two new files and — before their rows — read them RED
(`c0-row10-before-after.txt`), verbatim:
```
786/859 difference: immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap (pristine 0.0s, fork 0.0s)
787/859 difference: immaculate/nolibc/tray44-allocator-exhausted-single-request (pristine 0.0s, fork 0.0s)
Independent oracle: failed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 5, 'interface_agreement': 2, 'difference': 2}
```
Signatures harvested from that run's `report.json` (the immaculate lane's flags: `--exec --batch --nolibc`,
no `--mode`, 60 s): `tray44-…-single-request` — upstream `status 0`, stdout sha `75f0c56b9343f53f5a0ea7250e83
2069fe6148c811b2213e6d9fba7b24aadd41`; fork `status 1`, stdout sha `ce222125f809d9e97ee1a7685c64eadff5eb5ce46
9ee81642a4ea4e16571f966`; `…-overlap` — upstream `status 0`, stdout sha `e17cb1bc5caaced5c76d327c79a9f2fe28871
277a1adf293b0ffc6a747678edb`; fork `status 1`, stdout sha `ce222125…` (the same kill line); diagnostic sha
`e3b0c442…` (empty stderr) on all four sides — identical to the `tests/minimal` twins' pinned signatures (same
program, same verdict lines). Two `shared-model-fix` rows added to `scripts/upstream_oracle_differences.json`
(`c0-register.diff`: 38 lines added, 0 removed; the original re-serialises byte-identically): keys
`immaculate/nolibc/tray44-allocator-exhausted-single-request[-overlap]`, citations = the twins' (tray 44, part
one's record) + this charter, rationale = the twins' with the CERB_SKIP sentence replaced by the GATING-PIN
sentence (this copy is walked by `test_immaculate.sh`, which pins `MATCH | L=ERR:{…}`). After the rows, and
the plants (`c0-row10-before-after.txt`), verbatim:
```
786/859 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap (pristine 0.0s, fork 0.0s)
787/859 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request (pristine 0.0s, fork 0.0s)
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
```
(`reviewed_difference` 5 → 7 — the charter's expected count; nothing else moved.)

**(c) The gcc ledger.** Observation run `scripts/ce ./scripts/test_gcc_oracle.sh --no-csmith tests/minimal
tests/immaculate/nolibc` (`c0-gcc-ledger.txt`), verbatim:
```
[112/149] SKIP_LEAN_FAIL  tests/minimal/112-allocator-exhausted-single-request.c: msg: "MerrOther "
[113/149] SKIP_LEAN_FAIL  tests/minimal/113-allocator-exhausted-single-request-overlap.c: msg: "MerrOther "
[138/149] SKIP_LEAN_FAIL  tests/immaculate/nolibc/tray44-allocator-exhausted-single-request.c: msg: "MerrOther "
[139/149] SKIP_LEAN_FAIL  tests/immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap.c: msg: "MerrOther "
SUMMARY: total=149 compared=103 agree=100 agree_nd=0 triaged=3 disagree=0 o2_agree=8 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=8 skip_ub=27 triaged_addr=2 triaged_ub=1
gcc second-oracle lane OK
```
(Lean's verdict is the `Error {…}` kill line, so there is no gcc comparison — `SKIP_LEAN_FAIL`, O2 `-`; the
native binary's `malloc(a - 7)` for a ~2^47-byte request returns NULL → exit 4, which the lane never reaches
for this class.) Four rows hand-inserted at their C-sorted positions (after `trap-bool-write.c`; after
`minimal/111-…`) + a four-line dated header note after the Z1 note (E6 for the count); `c0-gcc-ledger.txt`
carries the ledger diff. The full `--check-baseline` (Tier B row 7, csmith tier included), verbatim:
```
SUMMARY: total=2001 compared=1916 agree=1904 agree_nd=0 triaged=12 disagree=0 o2_agree=196 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=13 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Checking against baseline: scripts/gcc_oracle_baseline.txt
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
(no "new file" line in the check; the four new rows read SKIP_LEAN_FAIL at [112/2001], [113/2001], [321/2001], [322/2001]; wall 21:36.59; c0-gcc-check-baseline-tail.txt)
```

**(d) The C0 FAST-GATE (verbatim; `c0-fast-gate-tails.txt`; every lane via `scripts/ce`):**
```
test_immaculate.sh (compare mode): OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_unit.sh: Total: 11 passed, 0 failed
  check_no_fuel_numerals: OK (218 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
  check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 24 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
test_exec.sh --check-baseline: SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s)
coverage: SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s)
debug: SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s)
float: SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0 / Baseline check: 0 regression(s), 0 improvement(s)
```
Zero movement of any existing row anywhere; row 10 gained exactly the two chartered rows.

## C2 — The bound as an explicit entry parameter (route A) — NOT STARTED: stop S2 + S6 at the design step

No file of C2 was touched. The chartered route A is RIGHT and implementable — but not inside this fence. The
complete ripple map (every site that MUST change for the chartered signatures to typecheck and every gate to
stay green), with the fence verdict per site:

| # | site | change | in fence? |
|---|------|--------|-----------|
| L1 | `frontend/model/mem.lem:41` | `val initial_mem_state: integer -> mem_state` (target_reps unchanged) | yes |
| L2 | `driver.lem:1520/:1526/:1535/:1540` | `initial_driver_state_with address_space_top run_st file fs_state` with `layout_state= Mem.initial_mem_state address_space_top`; `initial_driver_state address_space_top file fs_state`; `initial_driver_state_given address_space_top sup file fs_state` | yes |
| L3 | `cabs_to_ail_effect.lem:224-240` `state` | `+ address_space_top: integer` beside `fresh_sym_supply` | yes |
| L4 | `cabs_to_ail_effect.lem:577-582` `initial_state` | `val initial_state: nat -> integer -> …`; `let initial_state fresh_sym_supply_seed address_space_top core_eval_stuff cn_eval_stuff = <| … address_space_top= address_space_top; … |>` | yes |
| L5 | `cabs_to_ail_effect.lem:694` (beside) | `val get_address_space_top: desugM integer` / `modify_inner (fun st -> (st.address_space_top, st))` | yes |
| **L6** | **`cabs_to_ail_effect.lem:702-710` `eval`/`cabs_to_ail_effect_eval`** | `val eval: forall 'a. nat -> integer -> …`; `let cabs_to_ail_effect_eval sup address_space_top core_eval_stuff cn_eval_stuff m = … (initial_state sup address_space_top core_eval_stuff cn_eval_stuff)` | **NO (E2)** |
| L7 | `cabs_to_ail.lem:4973-4975` + `:5050` `desugar` | `val desugar: nat -> integer -> …`; `let desugar sup address_space_top core_eval_stuff cn_eval_stuff startup_str (TUnit edecls) = … E.eval sup address_space_top core_eval_stuff cn_eval_stuff (…)` | yes |
| L8 | `cabs_to_ail.lem:1135-1137` | `E.get_address_space_top >>= fun address_space_top -> E.liftException (Mini_pipeline.evalIntegerConstantExpression sup address_space_top loc core_env sigm ty_opt expr)` | yes |
| L9 | `mini_pipeline.lem:201-206` `evalIntegerConstantExpression` | `nat -> integer -> Loc.t -> …`; passes it to Aux at `:221` | yes |
| **L10** | **`mini_pipeline.lem:88-95` `evalConstantExpressionAux`** | `nat -> integer -> Loc.t -> …`; `let evalConstantExpressionAux sup address_space_top loc … =`; `:163` `Driver.initial_driver_state_given address_space_top sup_after_elab dummy_core_file Fs.fs_initial_state` | **NO (E1)** |
| O1 | `ocaml_frontend/memory_model.ml:39` | `val initial_mem_state: Z.t -> mem_state` | yes |
| O2 | `memory/concrete/impl_mem.ml:503-516`, `vip:170-176` | `let initial_mem_state address_space_top = { … last_address= address_space_top; … }` (the literal LEAVES) | yes |
| O3 | `memory/symbolic/impl_mem.ml:569`, `cheri-coq:271` | `let initial_mem_state (_address_space_top: Z.t) = …` + one-line comment (no cursor) | yes |
| O4 | `backend/common/driver_ocaml.ml:11-16` / `.mli:3-8`; `:157`/`:198` | `driver_conf + address_space_top: Z.t`; `Driver.initial_driver_state conf.address_space_top file fs_state` | yes |
| O5 | `backend/driver/main.ml` (`:125-126` conf, `:323` driver_conf) | `let address_space_top_default = Z.of_int 0xFFFFFFFFFFFF (* the ONE OCaml address-space numeral; was memory/concrete/impl_mem.ml:508 *)`; both confs filled from it | yes |
| O6 | `backend/common/pipeline.ml:72-84` `configuration`, `:206` | `configuration + address_space_top: Z.t`; `Cabs_to_ail.desugar 0 conf.address_space_top (…)` | yes (.ml) |
| **O7** | **`backend/common/pipeline.mli`** `type configuration` | `+ address_space_top: Z.t;` (E3; the only exported-signature change under the FIELD route; drift row `:324`) | **NO** |
| O8 | `backend/web/instance.ml:46` (conf), `:635`; `backend/bmc/main.ml:105` (conf) | mechanical: the field from a named default; `Driver.initial_driver_state <default> core' …` — unbuilt (`cerberus-web`, `cerberus-bmc`) | :635 yes; :46 and bmc **NO** |
| **O9** | **`backend/ocaml/runtime/rt_ocaml.ml:200-204`**, `:355`; **`backend/bmc/bmc_utils.ml:197`** | `M.initial_mem_state <default>` ×5, `Driver.initial_driver_state <default> dummy_file …`, `Impl_mem.initial_mem_state <default>` — unbuilt (E4) | :355 yes; the rest **NO** |
| K1 | `lean_frontend/CerbMem.lean:153`, `:1780` | `lastAddress : Address` (no default); `def initialMemState (addressSpaceTop : Int) : MemState := { lastAddress := addressSpaceTop }` | yes |
| K2 | `Main.lean` `:521`, `:1019`, `:1150`-area, `:1251-1279` | `def defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF  -- ADDRESS-SPACE-DEFAULT (the one allowed address-space numeral)`; `--address-space-top N` (the `--fuel` shape; absent → default; non-numeral or `≤ 0` → refusal naming the default); `desugar fmapEmpty supply addressSpaceTop coreEvalStuff cnInit "main" tunit`; `initial_driver_state supply addressSpaceTop runFile fsState` | yes |
| K3 | `test/Unit/FuelExemplar.lean:130`, `FuelFormsTool.lean:109` (name list only — no change needed unless the cone check needs the new binder), `MonadicFailstop.lean:24`; `speclab/test/SLUnit/{Tree,Seed,Core,List,ByteArr}GateTest.lean` | test-chosen values; the FuelExemplar theorem quantifies `top` (docstring) | yes |
| **K4** | **`tests/immaculate/illtyped-store.lean:44`** | `(f (initialMemState <test-chosen>)).1` — GATE-compiled (E5) | **NO** |
| K5 | `tests/mem-scale-probes/micro/Micro.lean:68-104` | `initialMemState <test-chosen>` ×5 — instrument package (E5) | NO (latent) |
| G | `scripts/check_no_fuel_numerals.sh` (+ `--selftest` plants), `scripts/fork_drift_manifest.txt` rows for O1-O7, DESIGN §4, VALIDATION §0/§7, `lean_frontend/CLAUDE.md`, generated trees | as chartered (the drift manifest needs `pipeline.mli`'s row too) | yes (+ .mli row) |

**Fence extension the re-charter needs (exactly):** `frontend/model/cabs_to_ail_effect.lem` `eval` /
`cabs_to_ail_effect_eval` (`:702-710`, signature + the one call); `frontend/model/mini_pipeline.lem`
`evalConstantExpressionAux` (`:88-95`, signature + the `:163` call); `backend/common/pipeline.mli` (`type
configuration`, one field; + its drift row); `backend/ocaml/runtime/rt_ocaml.ml:200-204` and
`backend/bmc/bmc_utils.ml:197`, `backend/bmc/main.ml:105`, `backend/web/instance.ml:46` (the mechanical
unbuilt edits, or a ruling that unbuilt backends may be left broken — either way named);
`tests/immaculate/illtyped-store.lean:44` (one test-chosen value); `tests/mem-scale-probes/micro/Micro.lean:68-104`
(five). Everything else in the table is already fenced. [AGENT] design recommendations for the re-charter,
each with its reason: (i) the OCaml carrier is a `configuration` FIELD (O6/O7), not a labelled argument — one
exported type changes and two unbuilt constructors, versus eight unbuilt callers; and it mirrors how the
execution side carries the bound (`driver_conf`); the driver passes the SAME `address_space_top_default` into
both records at `main.ml:125`/`:323`, so the two entry points share one value by construction. (ii) The
lem-side parameter order is `sup address_space_top …` everywhere (charter §2(a)), so the generated Lean reads
`desugar (tagDefs) (sup : Nat) (address_space_top : Int) …` and `initial_driver_state (sup : Nat)
(address_space_top : Int) file fs` (the supply binder stays first: it is lem's `supply` transform's slot). (iii)
`Micro.lean`/`illtyped-store.lean` take `defaultAddressSpaceTop`-INDEPENDENT test values (they are not
consumers of Main; the ruling allows a test-chosen value) — `illtyped-store` should keep the OCaml value's
magnitude irrelevant to its KILL verdict (the store guard fires before any allocation).

**Why stop rather than proceed (the rule reading).** S2 is literal for L6 and L10 ("a `.lem` site not
listed"); S6 (fence vs the gate) is literal for K4 — the chartered `initialMemState` signature makes Tier B row
5 (and every FAST-GATE from C0 on) go RED unless a file outside the fence is edited; O7 is a fence-vs-typecheck
conflict of E3's kind. The brief: "The fence (§3) is exact" and "Stop rules … commit what is green, write the
interim state into the record, END YOUR TURN". C0 is green and committed; this is the interim state.

**CONSUMER RE-PIN NOTE (for cerberus-sl, relayed by the operator).** C0 changes NO signature and NO Lean
definition: cerberus-sl has nothing to do at this head; the pin target remains part one's landing (mainline
`e64819de7`; `CerbMem.allocator`'s type unchanged; `CerbMemAllocatorProofs.allocator_active_sound`). The
PLANNED C2 signatures (for the consumer to anticipate, not act on; unchanged from part one's record except the
desugar entry): `initialMemState : MemState` → `initialMemState (addressSpaceTop : Int) : MemState`;
`MemState.lastAddress : Address := 0xFFFFFFFFFFFF` → `lastAddress : Address` (no default — every `{ … :
MemState }` literal gives it); generated `initial_driver_state (sup : Nat) file fs : driver_state × Nat` →
`initial_driver_state (sup : Nat) (address_space_top : Int) file fs`; `initial_driver_state_given (sup : Nat)
file fs` → `initial_driver_state_given (sup : Nat) (address_space_top : Int) file fs` (lem order
`address_space_top sup` per the charter; the generated binder order is lem's); generated `desugar [LemFuel]
(tagDefs) (sup : Nat) core_eval_stuff cn_eval_stuff startup_str tunit` → `… (sup : Nat) (address_space_top :
Int) core_eval_stuff …`; `drive` UNCHANGED; consumer theorems quantify `∀ top`; matched mode instantiates `top
= 0xFFFFFFFFFFFF` (= 281474976710655) from `Main.lean`'s `defaultAddressSpaceTop`.

## C3 — NOT STARTED (depends on C2). Draft 45 not drafted.

## Measurements (wall clock, this box; load ≈ 1.5-2.8)

`make lean-prelude-src` 19.7 s; engine rebuild (`build_cerberus` 1.0 s incremental + `build_lean` 35.6 s —
Lake's content-hash cache held the post-C1 artifacts); `test_immaculate.sh --record-baseline` 67 s (compare
mode 66 s); row 10 114.7 s / 113.7 s (859 rows), `--plant` ~2 s; gcc observation run (149 files, no csmith)
46.5 s; `test_unit.sh` 2:42.11; the four exec rows 27.6 s / 50.6 s / 22.3 s / 23.7 s (minimal / coverage / debug /
float); full gcc `--check-baseline` 21:36.59 (csmith tier included; load ≈ 2).

## Open items

1. **[orchestrator] the C2/C3 re-charter** with the fence extension of §C2 (nine sites, all named with lines) and
   the two design points (configuration FIELD; parameter order). Nothing of C2 was edited; the tree at this head
   is C0 only.
2. **[orchestrator, instrument]** `test_immaculate.sh --record-baseline` strips hand-added header notes (E7): either
   move the R5/Finding-3 notes into the script's header block or make the re-record preserve `#` lines it did
   not write. Out of fence here.
3. **[orchestrator, operational]** worktree priming should regenerate `lean_frontend/generated/` (E8) — the primed
   Lean binary was pre-part-one and the sync gate had to refuse.
4. Draft 45 (optional) — not drafted; facts: part one's §C2 (A) + §C2 here.
5. The `.tmp/` artefacts (`c0-*`, `c0-row10*/`) are ephemeral; everything cited is in the evidence directory.
