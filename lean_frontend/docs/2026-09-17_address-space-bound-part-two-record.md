# Record — address-space bound, PART TWO (2026-09-17) — COMPLETE: C0 (the witnesses' gating pin), C2 (the bound as a quantified entry parameter, route A), C3 (the fork-only flag + the tiny-address-space lane); FULL GATE GREEN (`full: passed; 39/39`, source unchanged) AT THE C3 HEAD

**Status [AGENT, worker, 2026-09-17]:** all three chartered deliverables are LANDED on
`arc/address-space-bound-part-two` (base: mainline `e64819de7`, charter `ea517c1f9`): **C0**
`bda7a3e1b14868699e68682e6d18fe979412b323`, **C2** `24af7239b6c6da4a0c47914124a0e5bd96a0405b`, **C3**
`9a8caddc1cc9d3963e0156ea01d5b3481a028d79`. The slice first STOPPED at C2's design step (stop rules S2 +
S6: the chartered route A ripples into gate-compiled and exported sites outside the fence — the interim
record `5d6d42f5c`, its §C2 ripple table); the orchestrator EXTENDED the fence to exactly the sites that
table listed ("fence extension granted 2026-09-17", [AGENT orchestrator] within the [USER 2026-09-17]
route-A ruling) and ADOPTED the three design recommendations (the OCaml carrier is a `configuration`
FIELD; the lem parameter order is `sup address_space_top …` with the supply binder first; the two
instrument files take test-chosen values independent of the default), and C2/C3 proceeded. The FULL
battery (`release.py --mode full`, Tier A + B, the new Tier A row 12 included) and the three-engine
report (`test_upstream_oracle.py --with-lean`) ran ONCE at the C3 head `9a8caddc1` — §FULL, verbatim.
This record is the LAST commit and ENDS the slice. Evidence directory:
`docs/2026-09-17_address-space-bound-part-two-evidence/` (every quoted output below is a file there).
Charter: `docs/2026-09-17_charter-address-space-bound-part-two.md`; part one:
`docs/2026-09-16_allocator-soundness-address-bound-record.md`.

## 0. Rulings (by pointer; verbatim texts in the charters' §0)

Part two §0: [USER 2026-09-17] the C1-lands-first / C2-C3-separately agreement (route A, extended
fence); [USER 2026-09-17] the consumer confirmation ("part 1 is exactly what they need"; part two "modest
blast radius" — the re-pin note lists signatures and stops); [USER 2026-09-17] the sequence (part two →
enum registry → concurrency). Part one §0: [USER 2026-09-16] the bound is a quantified parameter whose
matched-mode instance is upstream's value; the fork-only OCaml flag is wanted; [USER 2026-09-03] no magic
values; [USER 2026-09-08] nothing new out of policy; the standing constraints. The fence extension and the
adopted recommendations are [AGENT orchestrator], quoted in §C2. Every other decision below is [AGENT
worker] with its one-line reason.

## 1. Errata to the charter's §1/§2 (re-checked against the tree; E1–E9 are the interim record's, kept)

All §1 cites re-verified and CORRECT unless listed (the interim record's list stands: `test_exec.sh:553-558`;
`test_immaculate.sh` verdict() `:100-134`, record block `:245-322`; gcc ledger header `:6-7`; the four
`impl_mem.ml` sites; `memory_model.ml:39`; `mem.lem:41-45`; `CerbMem.lean:153`/`:1780`; generated
`Driver.lean:489`; `driver.lem:1520/:1526/:1535/:1540`; `driver_ocaml.ml:157/:198`, `driver_conf
.ml:11-16`/`.mli:3-8`; `web/instance.ml:635`, `web/dune:10-19`, `rt_ocaml.ml:355`; `common.sh:193/:231`;
`cabs_to_ail.lem:1135/:1137/:4973-4975`; `mini_pipeline.lem:163/:201-206`;
`cabs_to_ail_effect.lem:224/:240/:577-578/:582`, `get_fresh_sym_supply :694`; `pipeline.ml:206`;
`Main.lean:521/:1019/:1150/:1251-1279`; `main.ml:99/:219/:521-524/:566`; `ALLOW_MAIN` at
`check_no_fuel_numerals.sh:70`; the drift rows).

- **E1 (C2; was an S2 trigger — RESOLVED by the fence extension).** `mini_pipeline.lem:163` is inside
  `evalConstantExpressionAux` (`val :88-93`, `let :95`), not `evalIntegerConstantExpression` (`:201-206`,
  which calls Aux at `:221`); Aux's signature gains the parameter too. Aux has no other caller.
- **E2 (C2; was an S2 trigger — RESOLVED).** `desugar` seeds `E.initial_state` only through
  `cabs_to_ail.lem:5050` `E.eval …` → `cabs_to_ail_effect.lem:702-710` `val eval` /
  `cabs_to_ail_effect_eval` → `initial_state` (`:709`); `eval`'s signature gains the parameter.
- **E3 (C2; was an S6 trigger — RESOLVED).** Any carrier of the bound from `main.ml` to
  `pipeline.ml:206` changes the exported `backend/common/pipeline.mli` (`type configuration`; layer-1 drift
  pin `:324`); the FIELD route (adopted) touches its two other constructors (`backend/bmc/main.ml:105`,
  `backend/web/instance.ml:46`, unbuilt) instead of the eight unbuilt callers of `c_frontend_and_elaboration`.
- **E4 (C2, unbuilt OCaml — RESOLVED).** `rt_ocaml.ml:200-204` use `M.initial_mem_state` five more times;
  `bmc_utils.ml:197` uses `Impl_mem.initial_mem_state` (the charter's "bmc does not call the builder" is
  true of `initial_driver_state` only). Both unbuilt (rt_ocaml's dune stanza is commented out; bmc needs
  `z3`). Edited mechanically (§C2 unbuilt-backend note).
- **E5 (C2; was THE S6 trigger — RESOLVED).** `tests/immaculate/illtyped-store.lean:44` applies
  `initialMemState` and is COMPILED AND RUN by `test_immaculate.sh:233-241` (Tier B row 5 = C2's own
  FAST-GATE); `tests/mem-scale-probes/micro/Micro.lean:68-104` uses it five times (the `memscale-micro`
  package, built only by `scripts/build_provider_smoke.py`; `test_release.py:229-245` exercises that
  provider on a fixture tree). Both now take test-chosen values (§C2(e)).
- **E6 (C0 — count).** The gcc lane's default corpus INCLUDES `tests/immaculate/nolibc`
  (`test_gcc_oracle.sh:179`), so C0 needed FOUR ledger rows (the two `tests/minimal` twins + the two
  copies), not the two the charter counts, for the chartered bar "no `new file` lines". [AGENT] four rows.
- **E7 (C0 — instrument; OPEN ITEM for the orchestrator, NOT fixed here by instruction).**
  `test_immaculate.sh --record-baseline` rewrites `tests/immaculate/baseline.txt` from a hardcoded header
  block (`:245-321`) and DROPPED fourteen hand-added header lines (the R5 pin note and the Finding-3 pins
  note, old lines 77-90); [AGENT] restored verbatim by hand so the committed diff is exactly the two rows.
- **E8 (operational).** The primed worktree's `lean_frontend/generated/` and Lean binary PREDATED part one
  (`build_lean` REFUSED: `CERB_DRIVER_STALE … CerbMem.lean not propagated … CerbMemAllocatorProofs.lean
  missing`); `make lean-prelude-src` moved exactly those two files, the lem output being byte-identical
  (`c0-regen-generated-delta.txt`). Priming should regenerate.
- **E9 (trivial cites).** The fork-only interface entry is `test_upstream_oracle.py:840-843` (part one's E8
  said `:787`); the immaculate re-record code is `:245-322` (charter `:59-79`).
- **E10 (C2 — a RULE CONFLICT raised under S6, resolved by the minimal choice; for the orchestrator's
  confirmation).** The charter (reaffirmed in the fence-extension message: "the ONE OCaml numeral in
  `main.ml`") and the extension's instruction that the unbuilt callers in three OTHER packages
  (`cerberus-web`, `cerberus-bmc`, the `rt_ocaml` runtime) "pass the named default" are jointly
  unsatisfiable: a value defined in the `cerberus` EXECUTABLE's `main.ml` is invisible to them, and a
  literal in each would make three more numerals. [AGENT] the ONE OCaml numeral lives in the LIBRARY module
  `backend/common/driver_ocaml.ml` as `address_space_top_default : Z.t = Z.of_int 0xFFFFFFFFFFFF` (declared
  in the `.mli`; beside `driver_conf`, the execution driver's configuration — the natural home), `main.ml`
  references it (both `configuration` and `driver_conf` in C2; the flag's cmdliner default in C3), and the
  unbuilt callers reference `Cerb_backend.Driver_ocaml.address_space_top_default`. The count is ONE
  (`grep -rn 0xFFFFFFFFFFFF` over `memory/ ocaml_frontend/ backend/ frontend/` finds the definition and its
  own comment only — `c2-fast-gate-tails.txt`). `rt_ocaml.ml` would additionally need `cerb_backend` in its
  (commented-out) dune `libraries` to compile — said in its comment; `backend/ocaml/runtime/dune` is
  outside the fence and untouched.
- **E11 (C2, docs).** `VALIDATION.md` §3(c)'s "Accepted command line" bullet is outside the chartered
  `§0/§5/§7` but MUST name the new flag (a stale accepted-flag list is a doc defect): one bullet edited.
- **E12 (C2, FuelExemplar — OWED).** The charter's "the FuelExemplar theorem's statement now quantifies the
  bound too" is not free: `drive_after_setup`'s errno step (`runOne_liftMem_active rfl`) evaluates
  `allocateObject` — hence `allocator`'s two branch conditions — on a CONCRETE cursor by `rfl`, and `S₁`
  is a concrete state; a symbolic `top` needs the conditions discharged from a hypothesis (`8 ≤ top` for the
  4-byte/align-4 errno object) and `S₁` restated symbolically — proof surgery, not a bounded edit (part one's
  S2 pattern: no grind). [AGENT] `dst₀ [LemFuel] (sup : Nat) (top : Int)` and `run` take the top as a
  PARAMETER (the definitions are quantifiable); the theorem is stated at the test-chosen `exemplarTop`
  (0x10000; docstring says so); the `∀ top, 8 ≤ top → …` generalisation is OWED (open items).
- **E13 (C3, refusal shapes).** The fork oracle's `--address-space-top 0` / `abc` are refused by cmdliner's
  own converter error (usage message, exit 124 — cmdliner's parse-error code; `-3` is read as an unknown
  option), where cerberus-lean refuses with exit 2 naming the default: the SHAPES differ by the two CLI
  libraries' design, the CLASS (loud refusal, no fallback) is the same on both.
- **E14 (operational, `release.py`).** The first `--mode fast` certification at the final C2 tree read
  `Source unchanged: False` (rc 1, 14/14 lanes passed) because the worker overwrote an evidence file
  inside the tracked docs directory mid-run — the runner's source identity covers tracked diffs AND
  non-ignored untracked files (`release.py:121-129`), so it fail-closed correctly; re-run with the tree
  untouched (`c2-fast-gate-tails.txt`). Consequence for the FULL run: nothing was written outside the
  ignored `.tmp/` while it ran.

## C0 — The witnesses' gating pin and the gcc ledger — LANDED `bda7a3e1b14868699e68682e6d18fe979412b323`

Unchanged from the interim record (`5d6d42f5c` §C0; evidence `c0-*`). In brief, verbatim where quoted:
the two copies `tests/immaculate/nolibc/tray44-allocator-exhausted-single-request{,-overlap}.c` (bodies
byte-identical to `tests/minimal/112/113`); the immaculate re-record's ONLY change
```
126a127,128
> tray44-allocator-exhausted-single-request MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
> tray44-allocator-exhausted-single-request-overlap MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
```
(both engines' kill on the exhausted regime GATED fork-vs-Lean, Tier B row 5 — part one's open item 3
closed); two `shared-model-fix` register rows (`immaculate/nolibc/tray44-…[-overlap]`, signatures harvested
from the row-10 run: upstream `status 0` stdout `75f0c56b…`/`e17cb1bc…`, fork `status 1` stdout
`ce222125…`, diagnostic `e3b0c442…`) — row 10 `failed; {…, 'reviewed_difference': 5, …, 'difference': 2}` before
them, `passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7,
'interface_agreement': 2}` after, plants `plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1,
'plant_ok': 51}`; four gcc-ledger rows `SKIP_LEAN_FAIL -` at their observed statuses (E6) + a dated note —
full `--check-baseline`: `Baseline check: 0 regression(s), 0 improvement(s)` / `gcc second-oracle lane OK`
(21:36 wall); `test_unit.sh` `Total: 11 passed, 0 failed`; exec minimal/coverage/debug/float `0
regression(s), 0 improvement(s)`.

## C2 — The bound as an explicit entry parameter, route A — LANDED `24af7239b6c6da4a0c47914124a0e5bd96a0405b`

**The design (DESIGN.md §4 "The address-space top joins fuel").** The concrete allocator's initial cursor —
upstream's `last_address = 0xFFFFFFFFFFFF`, a literal in `memory/concrete/impl_mem.ml:508` (VIP `:175`) and
a structure-field default in `CerbMem.lean:153` — is a PARAMETER of the shared model: `mem.lem`
`val initial_mem_state: integer -> mem_state`, threaded to the TWO places the model builds a memory state —
the execution entry (`driver.lem` `initial_driver_state_with top run_st file fs` /
`initial_driver_state top file fs` / `initial_driver_state_given sup top file fs`) and the desugar state
(`cabs_to_ail_effect.lem` `state.address_space_top`, seeded by `initial_state sup top …` through `eval sup
top …` from `Cabs_to_ail.desugar sup top …`, read back by `get_address_space_top` at `cabs_to_ail.lem:1137`
for `Mini_pipeline.evalIntegerConstantExpression sup top …` → `evalConstantExpressionAux sup top …` →
`initial_driver_state_given sup_after_elab top …` at `:163`) — from ONE command-line default per engine:
`Main.lean` `defaultAddressSpaceTop` (`--address-space-top N`) and the fork's
`Driver_ocaml.address_space_top_default` (filled into `Pipeline.configuration.address_space_top` and
`Driver_ocaml.driver_conf.address_space_top` by `main.ml`). Not a reader constant (the rejected route), not a
literal in any definition; `drive` untouched; the allocator (part one) untouched. The parameter is IDENTITY
at its default. **Fence extension granted 2026-09-17** ([AGENT orchestrator], verbatim): *"The fence is
EXTENDED exactly as your record lists … L6 … L10 … O7 … O8/O9 … K4 … K5"* and *"Your three design
recommendations are ADOPTED: (i) the OCaml carrier is a `configuration` FIELD … (ii) the lem parameter order
is `sup address_space_top …` everywhere (the supply binder stays first); (iii) the two instrument files
take test-chosen values independent of `defaultAddressSpaceTop`."*

**What changed (every site of the interim §C2 table, all now in fence; `git show 24af7239b --stat`):**
lem — `mem.lem` (L1), `driver.lem` (L2), `cabs_to_ail_effect.lem` (L3 field, L4 `initial_state`, L5
`get_address_space_top`, L6 `eval`), `cabs_to_ail.lem` (L7 `desugar` + `:5050`, L8 `:1135-1137`),
`mini_pipeline.lem` (L9 `evalIntegerConstantExpression`, L10 `evalConstantExpressionAux` + `:163`); OCaml —
`memory_model.ml:39` `val initial_mem_state: Z.t -> mem_state` (O1); concrete/vip take the argument, the
literal LEAVES (O2); symbolic/cheri-coq `(_address_space_top: Z.t)` accepted and ignored, one-line comment
(O3); `driver_conf + address_space_top: Z.t` (`.ml`/`.mli`), `driver_ocaml.ml:157/:198`
`Driver.initial_driver_state conf.address_space_top file fs_state`, and THE ONE OCaml numeral
`address_space_top_default` (O4; E10); `pipeline.ml` `configuration + address_space_top: Z.t` and `:206`
`Cabs_to_ail.desugar 0 conf.address_space_top …`, `pipeline.mli` the field (O6/O7); `main.ml` both confs
from the named default (O5; C3 replaces it by the flag's value); unbuilt: `web/instance.ml:46` (conf
field) and `:635` (`Driver.initial_driver_state conf.pipeline.address_space_top core' …`), `bmc/main.ml:105`
(conf field), `bmc_utils.ml:197`, `rt_ocaml.ml:200-204` (one local `initial_mem_state` from the named
default) and `:355` — each with a one-line "not ladder-built" comment (O8/O9). Lean — `CerbMem.lean`
`lastAddress : Address` (NO default) and `initialMemState (addressSpaceTop : Int) : MemState :=
{ lastAddress := addressSpaceTop }` (K1); `Main.lean` `defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF  --
ADDRESS-SPACE-DEFAULT (the one allowed address-space numeral)`, `--address-space-top N` parsed exactly like
`--fuel` (absent → default; `0` → "must be a positive integer"; non-numeral → "not a decimal numeral", both
exit 2 naming the default), threaded `runPipeline → frontendTU/loadLibc → desugar` and `→
initial_driver_state`; `refuseFlag`'s accepted list names it (K2); tests/probes with NAMED test-chosen values
independent of the default — `FuelExemplar.exemplarTop = 0x10000` (`dst₀`/`run` take `top`; E12),
`MonadicFailstop.testAddressSpaceTop = 0x10000`, the five SLUnit `gateAddressSpaceTop = 0x100000000`,
`illtyped-store.probeAddressSpaceTop = 0x10000` (its KILL is independent of the value: the guard fires before
any allocation), `Micro.microTop = 1 <<< 47` (a 48-bit-class region — big-integer bytemap keys, the property
the `hi` cases measure — not the default) (K3–K5); `FuelFormsTool.lean` needed no edit (it names constants
only). Gate — `check_no_fuel_numerals.sh` scans A1 `(^|[^0-9a-fA-Fx])0[xX][fF]{12}([^0-9a-fA-F]|$)` (exactly
twelve f's: CerbFloat's 13-digit mantissa masks are not hits), A2 `281474976710655`, A3
`lastAddress :=`/`last_address=` followed by a numeral; `ALLOW_MAIN` gains the one line `def
defaultAddressSpaceTop : Int := 0xFFFFFFFFFFFF`; a `lastAddress` vacuity guard; six `--selftest` plants (a
seam, the generated tree, the allowlisted CONTENT in a non-Main file, a unit test in decimal, speclab, an
in-Lean probe). Docs — DESIGN §4, VALIDATION §0 (matched mode: the flag on neither engine), §3(c) (E11), §7
(the paragraph), `lean_frontend/CLAUDE.md` (CerbMem, Main rows). Drift manifest — 15 `[source-content]` pins
moved, 4 `[expected-semantic]` diff pins moved (`cabs_to_ail_effect.ml`, `cabs_to_ail.ml`,
`mini_pipeline.ml`, `driver.ml`), `mem.ml` ADDED to `[expected-cosmetic]` (its generated delta is
comment-only: the lem comment + the `(*val …*)` echo, verified by comment-strip), one dated header note; the
four unbuilt backends lie OUTSIDE the gate's oracle SURFACES and are not manifested (the gate said so —
`c2-drift-manifest.diff`, `c2-drift-before-repin.txt`). Regeneration moved exactly `Cabs_to_ail`,
`Cabs_to_ail_effect`, `Mini_pipeline`, `Driver`, `CerbMem`, `Main` on the Lean side and `mini_pipeline.ml`,
`cabs_to_ail.ml`, `driver.ml`, `cabs_to_ail_effect.ml`, `mem.ml` on the OCaml side.

**CONSUMER RE-PIN NOTE (for cerberus-sl, relayed by the operator; pin target = the head carrying this
record — `scripts/semantics-pin.env`; nothing more).** Old → new, exactly:
- `CerbMem.MemState.lastAddress : Address := 0xFFFFFFFFFFFF` → `lastAddress : Address` (no default: every
  `{ … : MemState }` literal must give it; `{ st with … }` forms unaffected).
- `CerbMem.initialMemState : MemState` → `CerbMem.initialMemState (addressSpaceTop : Int) : MemState`.
- generated `initial_driver_state (_lemSupply_fresh_int : Nat) file fs : driver_state × Nat` →
  `initial_driver_state (_lemSupply_fresh_int : Nat) (address_space_top1 : Int) file fs : driver_state × Nat`
  (the supply binder stays first).
- generated `initial_driver_state_given (sup : Nat) file fs : driver_state × Nat` →
  `initial_driver_state_given (sup : Nat) (address_space_top1 : Int) file fs`.
- generated `initial_driver_state_with (run_st) file fs : driver_state` →
  `initial_driver_state_with (address_space_top1 : Int) (run_st) file fs`.
- generated `desugar [LemFuel] (tagDefs) (sup : Nat) core_eval_stuff cn_eval_stuff startup_str tunit` →
  `desugar [LemFuel] (tagDefs) (sup : Nat) (address_space_top1 : Int) core_eval_stuff cn_eval_stuff
  startup_str tunit`.
- generated `Cabs_to_ail_effect.initial_state (fresh_sym_supply_seed : Nat) core_eval_stuff cn_eval_stuff`
  → `… (fresh_sym_supply_seed : Nat) (address_space_top1 : Int) core_eval_stuff cn_eval_stuff`;
  `cabs_to_ail_effect_eval (sup : Nat) core_eval_stuff cn_eval_stuff m` → `… (sup : Nat)
  (address_space_top1 : Int) …`; NEW `get_address_space_top : state_with_markers → exceptM (Int ×
  state_with_markers) …`; the `state` structure gains `address_space_top : Int`.
- generated `Mini_pipeline.evalIntegerConstantExpression [LemFuel] (tagDefs) (sup : Nat) loc core_env sigm
  ty_opt expr` → `… (sup : Nat) (address_space_top1 : Int) loc …`; `evalConstantExpressionAux` likewise.
- `drive`, `CerbMem.allocator`, `CerbMemAllocatorProofs.*`: UNCHANGED. Consumer theorems quantify `∀ top`
  beside `∀ fuel`; matched mode instantiates `top = 0xFFFFFFFFFFFF` (= 281474976710655) from `Main.lean`
  `defaultAddressSpaceTop`; a tiny `top` is a legitimate instance (the allocator kills out of memory exactly
  where `allocator_active_sound` says the cursor is below the request).

**The chartered gates, verbatim (`c2-fast-gate-tails.txt`; every lane via `scripts/ce`; at the committed
C2 tree unless noted):**
```
fast: passed; 14/14 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Total: 11 passed, 0 failed
check_no_fuel_numerals: SELFTEST OK (26 plants red with the declared label — F1-F6 and A1-A3; E5 indirection a recorded known gap; unplanted set green)
check_no_fuel_numerals: OK (324 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
test_speclab_divmod: PASS (--gate) / test_speclab_bytearr: PASS (--gate) / test_speclab_list: PASS (--gate) / test_speclab_tree: PASS (--gate) / test_speclab_seed: PASS (--gate)   [Tier B row 6, the five edited SLUnit gates; pre-string tree]
```
ZERO movement: row 10 reads exactly C0's verdict (the parameter is identity at its default); every Tier A
baseline unmoved (14/14). The six A-plants (`PLANT OK   [A1 the default hex in a seam]`, `[A1 lowercase hex
in the generated tree]`, `[A1 allowlist-shaped line outside Main]`, `[A2 the default in decimal in a unit
test]`, `[A3 lastAddress literal in speclab]`, `[A3 last_address= literal in a probe]`) are in the tails
file. CLI smoke (`c2-cli-smoke.txt`): `--address-space-top 0` → `refused — … must be a positive integer …
default 281474976710655 …` rc 2; `abc`/`-5` → `not a decimal numeral …` rc 2; `64` and `8` → `Specified(42)`;
`7` → `Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}` (the errno `int` needs top ≥ 8);
the tray-44 witness kills at the default and at 4096; the fork oracle at the default is unchanged.

**The unbuilt-backend note ([AGENT], the orchestrator's decision "keep them compiling in principle").**
`backend/web/instance.ml`, `backend/bmc/main.ml`, `backend/bmc/bmc_utils.ml`, `backend/ocaml/runtime/rt_ocaml.ml`
received the mechanical edit; none is compiled by the ladder (`cerberus-web` needs lwt/cohttp,
`cerberus-bmc` needs z3 — neither in the switch; rt_ocaml's stanza is commented out), so "compiles in
principle" is a reading, not a build result; rt_ocaml additionally needs `cerb_backend` in its libraries
(E10). They were identical to pristine upstream at HEAD and now differ; they are outside the drift gate's
oracle surfaces.

## C3 — The fork-only OCaml flag and the tiny-address-space differential lane — LANDED `9a8caddc1cc9d3963e0156ea01d5b3481a028d79`

**(a) The flag.** `backend/driver/main.ml` `address_space_top` (the `--batch-alloc-census` shape): a `Z.t`
cmdliner converter (`Z.of_string`; positive only; decimal or `0x`/`0o`/`0b`), default
`Driver_ocaml.address_space_top_default`, wired into the `cerberus` term and BOTH `configuration` and
`driver_conf` (one value, two entry points). `--help` (`c3-oracle-flag-help-and-refusals.txt`), verbatim:
```
       --address-space-top=N (absent=281474976710655)
           (fork addition; FORK-ONLY, no pristine counterpart) the top of the
           address space: the concrete/VIP allocator's initial cursor, i.e.
           the memory state every run starts from. A positive integer
           (decimal, or 0x/0o/0b prefixed); default = upstream's
           0xFFFFFFFFFFFF. Received by both the desugarer's
           constant-expression mini-run and the execution driver.
```
Refusals: `0` → `cerberus: option --address-space-top: the address-space top must be a positive integer`
(usage, exit 124 — E13); `abc` → `… (decimal or 0x/0o/0b)`; `0x40` accepted (`Specified(12)` on two-ints).
Row 10's `not_applicable` fork-only interface list gains `--address-space-top` (matched mode never passes
it — the report shows `--cabs-json, --call, --batch-alloc-census, --address-space-top`).

**(b) The lane.** `scripts/test_address_space.sh` + `tests/address_space/{two-ints,three-ints-then-array,
array-40,nested-scopes,malloc-one}.c` × tops `64 32 8` (at 8 the errno `int` fits at 4 and the SECOND object of
every program exhausts). Per case: the fork oracle (`--nolibc --exec --batch --mode=exhaustive
--address-space-top N`) and cerberus-lean (`--batch --address-space-top N` on the oracle's cabs-json), both
captured by `observation_capture`, compared as COMPLETE observations by `observations.py compare --policy
batch --projection full --comparison sequence` (no codec change) — any difference is `LEAN≠FORK`, fatal (S4);
then the fork's tokens vs `tests/address_space/expectations.txt`, fail-closed both directions (a missing,
extra or changed row and a missing/unreadable file are fatal); `--record-expectations` refuses unless every
case agreed. The committed expectations (the first agreeing run; `c3-lane-record-check-selftest.txt`), verbatim:
```
array-40	64	VAL:{value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
array-40	32	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
array-40	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
malloc-one	64	VAL:{value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}
malloc-one	32	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
malloc-one	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
nested-scopes	64	VAL:{value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
nested-scopes	32	VAL:{value: "Specified(9)", stdout: "", stderr: "", blocked: "false"}
nested-scopes	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
three-ints-then-array	64	VAL:{value: "Specified(6)", stdout: "", stderr: "", blocked: "false"}
three-ints-then-array	32	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
three-ints-then-array	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
two-ints	64	VAL:{value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}
two-ints	32	VAL:{value: "Specified(12)", stdout: "", stderr: "", blocked: "false"}
two-ints	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
```
(the footprints predicted in each program's header held: e.g. three-ints-then-array = 4 + 4·3 + 16 = 32
bytes fits at 64 and exhausts at 32 because `z = 16 − 16 = 0` is not a positive address). Verdicts, verbatim:
```
test_address_space: OK (15 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
  PLANT OK   [P1 exhausted case forged to the pre-fix ACTIVE verdict (Specified(6) where the kill is pinned)] ->   EXPECT FAIL  three-ints-then-array top=32: expected [VAL:{value: "Specified(6)", …}] observed [ERR:{…out of memory…}]
  PLANT OK   [P2 missing expectations file] ->   EXPECT FAIL  expectations file not found: …
  PLANT OK   [P3 truncated expectations (last row dropped)] ->   EXPECT FAIL  two-ints top=8: observed but NOT in the expectations file (…)
  PLANT OK   [P4 a row for a case this run never produced] ->   EXPECT FAIL  absent-program top=64: pinned in the expectations file but NOT a case of this run
test_address_space: SELFTEST OK (4 plants rejected — the forged pre-fix ACTIVE verdict, a missing file, a truncated file, a phantom row; the committed file green)
```
Wall: 3.9 s per pass. No S4: all 15 cases LEAN = FORK.

**(c) LADDER/VALIDATION.** Tier A row 12 (`./scripts/test_address_space.sh --selftest`; `./scripts/test_address_space.sh`
— `release.py --list` shows `A12.1`/`A12.2`), VALIDATION §5 row, the row-10 exclusion entry. **(d) Drift:**
`main.ml` re-pinned (single row) + a C3 header note. **(e) Draft 45:** NOT drafted (optional; open items).

**C3's FAST-GATE, verbatim (`c3-*`):** `Total: 11 passed, 0 failed`; `check_fork_drift: OK — layer 1: 76 …
layer 2: 25 …`; `Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28,
'reviewed_difference': 7, 'interface_agreement': 2}`; `plants_passed; {'semantic_agreement': 1,
'plant_rejected': 1, 'plant_ok': 51}`.

## FULL gate — `release.py --mode full` (Tier A + B) at the C3 head `9a8caddc1`, ONCE

`release.py --mode full --out .tmp/c3-release-full`, every lane of Tier A (16, row 12's two commands included) and Tier B (23) at the C3 head, nothing touching the tree meanwhile; certification lines verbatim:
```
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```
(`release_certification` reads `"incomplete: reporting/adoption/audit exits require separate evidence"` — the runner's standing statement that a completed tier is not a customer release; LADDER preamble.) Per lane (id status seconds; `c3-release-full-tails.txt` has each lane's verbatim verdict tail and stdout sha256): A1 passed 208s / A2 passed 33s / A3 passed 51s / A4 passed 22s / A4b passed 24s / A4c passed 3s / A5 passed 22s / A6 passed 2s / A6b passed 4s / A7 passed 10s / A8 passed 9s / A9 passed 17s / A10 passed 16s / A11 passed 57s / A12.1 passed 4s / A12.2 passed 4s / B1 passed 602s / B2 passed 23s / B3 passed 15s / B4 passed 45s / B5 passed 67s / B6.1 passed 2s / B6.2 passed 2s / B6.3 passed 3s / B6.4 passed 3s / B6.5 passed 3s / B6.6 passed 4s / B6.7 passed 3s / B7 passed 1297s / B8.1 passed 13s / B8.2 passed 227s / B8.3 passed 6s / B8.4 passed 16s / B9 passed 1300s / B10.1 passed 115s / B10.2 passed 2s / B11.1 passed 15s / B11.2 passed 7s / B12 passed 418s. Load-bearing verdict lines, verbatim:
```
[A1] Total: 11 passed, 0 failed
[A1] check_no_fuel_numerals: OK (324 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
[A1] check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
[A2] SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
[A2] Baseline check: 0 regression(s), 0 improvement(s)
[A3] Baseline check: 0 regression(s), 0 improvement(s)
[A4] Baseline check: 0 regression(s), 0 improvement(s)
[A4b] Baseline check: 0 regression(s), 0 improvement(s)
[A10] GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
[A11] BASELINE OK (213 entries, exact match)
[A12.1] test_address_space: SELFTEST OK (4 plants rejected — the forged pre-fix ACTIVE verdict, a missing file, a truncated file, a phantom row; the committed file green)
[A12.2] test_address_space: OK (15 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
[B1] ALL PASSED
[B4] test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
[B5] OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtype
[B7] SUMMARY: total=2001 compared=1916 agree=1904 agree_nd=0 triaged=12 disagree=0 o2_agree=196 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=13 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
[B7] Baseline check: 0 regression(s), 0 improvement(s)
[B7] gcc second-oracle lane OK
[B9] observation lane plants: 93/93 passed
[B10.1] Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
[B10.2] Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
[B11.2] check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent
[B12] Independent oracle: passed; {'semantic_agreement': 4}
```
Zero movement of any baseline row anywhere (every `Baseline check: 0 regression(s), 0 improvement(s)`; the immaculate lane at the C0 baseline; row 10 at exactly C0's `reviewed_difference: 7`); the two new Tier A commands green.

## The three-engine report — `test_upstream_oracle.py --with-lean` at `9a8caddc1` (the flag never passed)

`test_upstream_oracle.py --with-lean --out .tmp/c3-with-lean` (Tier C row C5; the flag is never passed; wall 4:12), verbatim:
```
Independent oracle scope: tier-b; 859 rows in 252.0s; source unchanged: True
Three-engine report (Lean column, NOT gating): {'lean_agreement': 817, 'lean_difference': 28, 'lean_both_undecodable': 12, 'lean_not_applicable': 2}; Lean≠fork rows: 40: minimal/073-exit.libc.c, minimal/074-abort.libc.c, minimal/097-null-ptr-arith.undef.c, coverage/builtin/builtin-006-exit.libc.c, coverage/expr/expr-007-bitfield-ops.c, coverage/io/io-004-puts.libc.unsupported.c, coverage/libc/libc-002-calloc.c, coverage/libc/libc-011-memset.c, coverage/libc/libc-012-strlen.c, coverage/mem/mem-007-zero-size-array.c, coverage/misc/misc-001-void-ptr-arith.c, coverage/union3/union3-004-union-copy.c, coverage/union3/union3-005-union-return.c, debug/libc-01-memset.libc.c, debug/libc-02-strlen.libc.c, debug/ub-static-reject.c, debug/valid-04-exit-before-oob.c, bytes/byte_is_not_char.c, bytes/no_add.c, bytes/no_shift_left.c, bytes/no_shift_right.c, bytes/only_unsigned_char.c, immaculate/nolibc/f3-raw-high-byte-char-const, immaculate/nolibc/f3-raw-high-byte-int, immaculate/nolibc/f3-raw-high-byte-uchar, immaculate/nolibc/g4-bswap64-overflow, immaculate/nolibc/g5-decode-multichar, immaculate/nolibc/g5-decode-question, immaculate/nolibc/offsetof-union-member, immaculate/nolibc/r5-hex-subnormal-double-rounding, immaculate/nolibc/zd-e2-ptr-string-literals, immaculate/nolibc/zd-z2fl03-nan-to-int, immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc, immaculate/nolibc/zd-z2m02-device-funptr-call, immaculate/libc/g2-memcmp-uninit, immaculate/libc/g5-escape-roundtrip, immaculate/libc/s4b-memcmp-hugesize, immaculate/libc/zd-z2f04-closedir, immaculate/libc/zd-z2m01-aligned-alloc-zero-zero, immaculate/libc/zd-z2m01-aligned-alloc-zero
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
```
The four rows this slice added to the walked corpora, verbatim:
```
112/859 reviewed_difference: minimal/112-allocator-exhausted-single-request.c (pristine 0.0s, fork 0.0s) | lean: lean_agreement
113/859 reviewed_difference: minimal/113-allocator-exhausted-single-request-overlap.c (pristine 0.0s, fork 0.0s) | lean: lean_agreement
786/859 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap (pristine 0.0s, fork 0.0s) | lean: lean_agreement
787/859 reviewed_difference: immaculate/nolibc/tray44-allocator-exhausted-single-request (pristine 0.0s, fork 0.0s) | lean: lean_agreement
```
The Lean column is the WP-O-recorded state plus the four new agreeing rows (813 → 817 `lean_agreement`; 28 / 12 / 2 unchanged); the 40 `Lean≠fork` rows are the 40 recorded pins of the owning lanes (the list is in `c3-with-lean-report.txt` — libc exit/abort rows, the immaculate both-crash and ISO-fix pins, the `tests/bytes` reject rows, …), i.e. ZERO new rows and no zero-discrepancy finding (charter S4 not triggered at the default top either).

## Measurements (wall clock, this box; load ≈ 1.5–3)

C0: `make lean-prelude-src` 19.7 s; engine rebuild 1.0 s + 35.6 s; immaculate 67 s; row 10 ≈ 114 s; gcc
`--check-baseline` 21:36; `test_unit.sh` 2:42; exec rows 27.6/50.6/22.3/23.7 s. C2: `make prelude-src
lean-prelude-src` 35.4 s; `build_cerberus` 7.9 s, `build_lean` 47.5 s (the CerbMem/Driver/desugar cone;
Lake's cache held the rest); speclab `lake build` ≈ 6 min (148 jobs); `test_unit.sh` 3:43; immaculate 1:06;
row 10 1:55; `release.py --mode fast` 7:57; the five speclab gates 1:20 + 4 × 8 s. C3: `build_cerberus`
(main.ml) 2.8 s; the lane 3.9 s per pass; `test_unit.sh` 3:28; row 10 1:55; FULL 1:17:55 (39 lanes; B1 10:02, B7 21:37, B9 21:40, B12 6:58 dominate);
`--with-lean` 4:12.

## Open items

1. **[orchestrator] E10 — confirm the OCaml numeral's home** (`backend/common/driver_ocaml.ml`
   `address_space_top_default`, not `main.ml`): the [AGENT] resolution of the rule conflict; a one-line
   relocation if refused (then the unbuilt callers need a ruling that they may reference nothing).
2. **[owed] the FuelExemplar `∀ top` generalisation** (E12): `exemplar_certified_shipped_forall (fuel) (top)
   (h : 8 ≤ top)` needs `drive_after_setup`'s errno `rfl` replaced by a lemma discharging `allocator`'s two
   branch conditions from `h` and `S₁` restated in `top`; `dst₀`/`run` already take `top`.
3. **[orchestrator, instrument] E7** — `test_immaculate.sh --record-baseline` strips hand-added header notes
   (not fixed here by instruction).
4. **[orchestrator, operational] E8** — worktree priming should regenerate `lean_frontend/generated/`.
5. **Draft 45** ("the address-space top as a driver parameter") — not drafted; the facts are §C2 here and
   part one's §C2 (A); the fork's flag text (§C3(a)) is the proposal's shape.
6. **The enum-registry slice** (next, per the [USER 2026-09-17] sequence): `CerberusImpl.lean`
   untouched here; the `refuseFlag`/`--fuel`/`--address-space-top` parsing block in `Main.lean` is the
   pattern for any further CLI parameter; `check_no_fuel_numerals.sh` shows how a new numeral class joins the
   gate (shapes + allowlist line + plants + a vacuity guard).
7. **cerberus-sl**: the re-pin target is the head carrying this record; the signature list is the
   CONSUMER RE-PIN NOTE (§C2) and nothing more.
8. `.tmp/` artefacts (`c0-*`, `c2-*`, `c3-*`, `smoke*`, the release/row-10 report dirs) are ephemeral;
   everything cited is in the evidence directory.
