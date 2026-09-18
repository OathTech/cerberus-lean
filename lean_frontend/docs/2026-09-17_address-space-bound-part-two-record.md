# Record — address-space bound, PART TWO (2026-09-17/18) — COMPLETE: C0 (the witnesses' gating pin), C2 (the bound as a quantified entry parameter, route A), C3 (the fork-only flag + the tiny-address-space lane), C4 (the pre-merge audit's fixes + the DOMAIN `0 < top < 2^64`); FULL GATE GREEN at the C3 head AND at the C4 head

**Status [AGENT, worker, 2026-09-18]:** all three chartered deliverables are LANDED on
`arc/address-space-bound-part-two` (base: mainline `e64819de7`, charter `ea517c1f9`): **C0**
`bda7a3e1b14868699e68682e6d18fe979412b323`, **C2** `24af7239b6c6da4a0c47914124a0e5bd96a0405b`, **C3**
`9a8caddc1cc9d3963e0156ea01d5b3481a028d79`; the independent pre-merge audit (Codex, `b7e190f04`,
REQUEST CHANGES: F1–F4 + two corrections) and the consumer review's DOMAIN requirement are applied in **C4**
`dc035396af88355515e651859bcd1543c7ff30bc` — §"Audit fixes" (F1 is DONE: the exemplar theorem is `∀ fuel, ∀ top, 8 ≤ top → …`). The slice first STOPPED at C2's design step (stop rules S2 +
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
- **E12 (C2, FuelExemplar — was OWED; RESOLVED by C4 F1, §"Audit fixes").** The charter's "the FuelExemplar theorem's statement now quantifies the
  bound too" is not free: `drive_after_setup`'s errno step (`runOne_liftMem_active rfl`) evaluates
  `allocateObject` — hence `allocator`'s two branch conditions — on a CONCRETE cursor by `rfl`, and `S₁`
  is a concrete state; a symbolic `top` needs the conditions discharged from a hypothesis (`8 ≤ top` for the
  4-byte/align-4 errno object) and `S₁` restated symbolically — proof surgery, not a bounded edit (part one's
  S2 pattern: no grind). [AGENT] `dst₀ [LemFuel] (sup : Nat) (top : Int)` and `run` take the top as a
  PARAMETER; at C2 the theorem was stated at a test-chosen `exemplarTop` and `run` did NOT yet take `top`
  (the interim text's "`dst₀` and `run`" was wrong of `run` — audit F1). C4 delivers the generalisation:
  `run (n) (top)`, `exemplar_certified_shipped_forall (fuel) (top) (h : 8 ≤ top)`, `exemplarTop` deleted.
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
independent of the default — at C2 `FuelExemplar.exemplarTop = 0x10000` (superseded by C4: `run`/`S₁`/the theorem take `top`; E12),
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
  `defaultAddressSpaceTop`; a tiny `top` is a legitimate instance. The allocator's two kills, exactly (audit
  F4): it kills when `cursor − size < 0` (`allocator_below_request_kills`) and when the aligned-down candidate
  address is `≤ 0`; an ACTIVE result satisfies `allocator_active_sound` — a NECESSARY condition (aligned,
  positive, ending at or below the cursor, becoming the cursor), not a characterisation of failure.
- **THE DOMAIN (C4, from your review — `docs/2026-09-18_s3-checkpoint-review.md`):** `0 < top < 2^64`. Both
  CLIs refuse anything else (and any non-decimal spelling) with one sentence, `the address-space top must fit
  an LP64 pointer: 0 < top < 2^64`, the bound derived from `sizeof_pointer = 8` (`CerberusImpl.sizeof_pointer`;
  `ocaml_implementation.ml DefaultImpl`) — your *"`MemWF.la_wf` in HeapModel.lean, line 140, requires
  `lastAddress ≤ 2^64`; `la_pos` also requires positivity. An unrestricted integer initial cursor does not
  establish these facts."* Consumer theorems quantify `∀ top` UNDER this domain. **The setup hypothesis:** the
  driver's errno `int` (4 bytes, align 4) is the first allocation, so a run reaches `main` only for `8 ≤ top` —
  your *"With a sufficiently small top, the driver can OOM while allocating errno, before `main` or its Iris
  state is initialised."* The exemplar's theorem now carries exactly that hypothesis:
  `FuelExemplar.exemplar_certified_shipped_forall (fuel : Nat) (top : Int) (h : 8 ≤ top)`, with the symbolic
  errno lemma `errnoAction_active (k top) (h : 8 ≤ top) : runOne errnoAction (initialMemState top) = (NDactive
  (errnoPtr top), σstore top)` — `errnoAddr top = top − 4 − (top − 4) % 4` — as the reusable startup fact
  (`test/Unit/FuelExemplar.lean`, a test module; lift it into a seam if you want to import it).

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

C4: the F1 probe iteration ~10 min (06:55–07:05, six probe elaborations of ≤ 2 s each once the imports were
cached; `lake build fuel-exemplar-test` 5.4 s); the lane 4.6 s / selftest 4.8 s (18 cases, 11 plants);
`release.py --mode fast` ≈ 8 min; row 10 ≈ 2 min; FULL 1:20:25.

## Open items

1. **[orchestrator] E10 — confirm the OCaml numeral's home** (`backend/common/driver_ocaml.ml`
   `address_space_top_default`, not `main.ml`): the [AGENT] resolution of the rule conflict; a one-line
   relocation if refused (then the unbuilt callers need a ruling that they may reference nothing).
2. ~~[owed] the FuelExemplar `∀ top` generalisation~~ — DONE in C4 (F1): exactly the route named here
   (`errnoAction_active` for the errno step; `S₁ top` explicit); `run` takes `top` since C4.
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

## Audit fixes — C4 `dc035396af88355515e651859bcd1543c7ff30bc` (pre-merge audit `docs/2026-09-18_address-space-bound-part-two-audit-premerge.md`, Codex, REQUEST CHANGES; + the consumer's review `cerberus-sl/docs/2026-09-18_s3-checkpoint-review.md`)

The audit's F1–F4 and its two corrections, and the DOMAIN requirement the orchestrator relayed from the
consumer's review, are all applied in ONE commit, C4; every decision below is [AGENT worker] within the
orchestrator's instruction (verbatim in this section where it bound a choice).

**F1 — the bound-quantified execution theorem: DONE (not deferred).** `test/Unit/FuelExemplar.lean`:
`exemplar_certified_shipped_forall (fuel : Nat) (top : Int) (h : 8 ≤ top) : ∀ o ∈ run fuel top, (∃ st, o.1 =
Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)` — `run (n : Nat) (top : Int)` runs
the production `drive` from `dst₀ 0 top = (initial_driver_state 0 top exemplarFile fs).1`; `exemplarTop` is
DELETED (the interim record's "`dst₀` and `run` take `top`" was false of `run` — corrected: both do now). The
route the audit asked for: drive's errno step is no longer a `rfl` on a concrete cursor but the lemma
`errnoAction_active (k top) (h : 8 ≤ top) : runOne (@errnoAction ⟨k+1⟩) (initialMemState top) = (NDactive
(errnoPtr top), σstore top)` — `allocator_errno` (the allocator's two kills excluded by `omega` from
`8 ≤ top`: `top − 4 < 0` and the aligned-down candidate `≤ 0`, via `Int`'s Euclidean `%`),
`allocateObject_errno` (the record inserted at id 0, the 4 unspecified bytes written — closed by `trans rfl`
against an EXPLICIT post-allocation state `σalloc top`), `storeM_errno_active` (the store's guards discharged:
type-compatible by `decide`, the record read back at id 0, `isInBounds` by `simp` at the symbolic address,
writable, not an atomic member access). The post-setup state is stated EXPLICITLY — `S₁ [LemFuel] (top) := { s₁
top with layout_state := σstore top, core_state0 := { … thread_states := [(0, (none, thS top))] } }` with
`thS top`'s `errno := errnoPtr top` and the spawned thread's `env := [fmapEmpty]` — and `drive_after_setup (k
top) (h : 8 ≤ top)` CHECKS by its last setup `rfl` that the generated `drive` reaches exactly it;
`round_done (k top)` needs no hypothesis (the `hsteps` `rfl` holds with the post-store memory a SYMBOLIC term —
`step_ctx` on the pure-value arena never forces it: a free-`σ` `rfl` in the development probe
`c4-f1-development-probe.lean`). Axioms (`c4-exemplar-forall-top-axioms.txt`, verbatim): every one of
`exemplar_certified_shipped_forall`, `exemplar_certified_shipped_zero`, `exemplar_killed_at_one`,
`errnoAction_active`, `drive_after_setup`, `round_done` `depends on axioms: [propext, Classical.choice,
Quot.sound]`; kernel-only tactics, no option bumps; `lake build fuel-exemplar-test` re-elaborated the module
in 5.4 s. What the theorem now says for the consumer: at EVERY fuel and EVERY address-space top with room
for the errno object, the shipped pipeline's outcome is the fuel kill or `Specified(42)`; the OOM-before-main
regime (`top < 8`) is outside its statement, as the consumer review's second fact requires one to say.
Wall: ~10 minutes of probe iteration (`06:55 → 07:05`), within the bound.

**F2 — a GENUINE tiny-bound discriminator.** `tests/address_space/window-char-int7.c` — `char c; int a[7];
return (int)((uintptr_t)a & 0xff);` — at top 32: errno → cursor 28, `c` (1, align 1) → 27, `a` (28 bytes,
align 4): `z = 27 − 28 = −1`, inside draft 44's window `−align/2 < z < 0`. What is EXECUTED is the old ALLOCATION SCHEDULE — the pre-fix
`allocator` applied step by step to the exact states — not a complete pre-fix C run through the frontend and
batch printer (re-review correction 2; the C observation `Specified(2)` is DERIVED below): `c4-old-allocator-probe.lean` carries `CerbMem.allocator` at `4a23d98aa` (part one's base —
NOT `e64819de7^`, which is `4539c60e1` and already inside part one's range; the body was extracted by `git
show` and is byte-identical modulo the rename, checked by `diff`) beside this tree's fixed body, both run
over the program's schedule from `initialMemState top` at 64/32/8 (`c4-old-allocator-probe.out`, verbatim):
```
== OLD body (4a23d98aa, pre-remedy-1), top = 32: initialMemState 32
   errno int (size 4, align 4) at cursor 32: ACTIVE id=0 addr=28 cursor'=28
   char c (size 1, align 1) at cursor 28: ACTIVE id=1 addr=27 cursor'=27
   int a[7] (size 28, align 4) at cursor 27: ACTIVE id=2 addr=2 cursor'=2
== FIXED body (this tree, CerbMem.allocator), top = 32: initialMemState 32
   errno int (size 4, align 4) at cursor 32: ACTIVE id=0 addr=28 cursor'=28
   char c (size 1, align 1) at cursor 28: ACTIVE id=1 addr=27 cursor'=27
   int a[7] (size 28, align 4) at cursor 27: KILLED[MerrOther Concrete.allocator: failed (out of memory)] cursor=27
```
(top 64: both ACTIVE at 28; top 8: both kill at `a`). The program's only observable is the low byte of `a`'s
address, so the pre-fix observation is `Specified(2)` (address 2: misaligned, overlapping errno at 28..32 —
the complete draft-44 signature); the fixed engines' real outcome is pinned: the three new rows of
`tests/address_space/expectations.txt` (verbatim; the 15 existing rows unchanged, `diff` = additions only):
```
window-char-int7	64	VAL:{value: "Specified(28)", stdout: "", stderr: "", blocked: "false"}
window-char-int7	32	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
window-char-int7	8	ERR:{msg: "MerrOther \"Concrete.allocator: failed (out of memory)\""}
```
(`Specified(28)` at 64 also confirms the allocation ORDER errno → `c` → `a` on both engines.) Plant P1 now
forges THIS case to `Specified(2)`; the lane header, `expectations.txt`'s header, LADDER A12 and VALIDATION §5
name the discriminator and say every other case is old = fixed (the audit's reconstruction). The audit's
`malloc(9)@32` alternative was not added (one discriminator was asked for; the record notes it).

**F3 — the unterminated final row (fail-open) — fixed.** `scripts/test_address_space.sh` `check_expectations`:
both `read` loops are `while IFS=$'\t' read -r … || [[ -n "$first" ]]; do`, so a nonempty final record cut
by EOF is processed exactly like a terminated one. Plants (`--selftest`, verbatim in `c4-lane-selftest.txt`):
`P5 phantom row WITHOUT a final newline` → `EXPECT FAIL absent-program top=64: pinned … NOT a case of this run`;
`P6 duplicate row WITHOUT a final newline` → `EXPECT FAIL duplicate expectations row for array-40 top=64`; `P7
malformed row WITHOUT a final newline` → `EXPECT FAIL malformed expectations row: 'two-ints	64	'`; `P8 the
committed file with its final newline removed is ACCEPTED (the last row is read)` → `EXPECT OK 18 pinned rows =
18 observed cases`; P2/P3/P4 kept.

**F4 — the allocator contract stated exactly.** `VALIDATION.md` §7 and this record's consumer note: the
allocator kills when `cursor − size < 0` (`CerbMem.allocator_below_request_kills`) and when the aligned-down
candidate is `≤ 0` (cursor 4, request 4, align 4 kills with cursor = request; cursor 5 too — the corpus's
`three-ints-then-array@32` is the equality case); an ACTIVE result satisfies `CerbMem.allocator_active_sound`
— a NECESSARY condition, not a characterisation of failure. The "kills exactly where … `allocator_active_sound`
says" sentence is gone from both.

**Corrections.** (i) Register arithmetic: `minimal/112-…` and `immaculate/nolibc/tray44-…-single-request`
rationales now read "ONE request larger than the cursor by 1 byte (… the cursor at a − 8 and the request is
a − 7 bytes, so z = −1 …; the part-two pre-merge audit corrected the earlier "by 7 bytes")" — the two
`-overlap` rows never said it; signatures untouched (row 10 unmoved). (ii) The record's `run` signature: see
F1 (`run (n : Nat) (top : Int)` — it did NOT take `top` before C4; E12 and open item 2 are amended below).

**DOMAIN (the consumer's review; [AGENT orchestrator] within the ruling).** Both CLIs refuse a top outside
`0 < top < 2^64` with the MIRRORED sentence `the address-space top must fit an LP64 pointer: 0 < top < 2^64`,
each deriving the bound from its implementation's pointer size rather than a numeral: `Main.lean`
`addressSpaceLimit : Nat := match CerberusImpl.sizeof_pointer with | some bytes => 2 ^ (8 * bytes) | none =>
0` (a missing size makes the domain EMPTY — fail-closed) and `main.ml` `Z.shift_left Z.one (8 * bytes)` from
`Ocaml_implementation.DefaultImpl.impl.sizeof_pointer` (`Some 8`); the fork's converter is DECIMAL-ONLY
(`String.for_all` digits) so `0x40` is refused on both engines (the audit's base-prefix asymmetry, mirror
doctrine); non-decimal input says `not a decimal numeral` on both. The exit codes remain the CLI libraries'
(cmdliner 124 — it also wraps and indents its text, which the plant normalises; cerberus-lean 2). Plants (the
lane's `--selftest`, verbatim): `P9 --address-space-top 18446744073709551616 (= 2^64) REFUSED on both engines
with the mirrored domain sentence -> fork rc=124 lean rc=2`; `P10 --address-space-top 0x40 (not decimal)
REFUSED on both engines -> fork rc=124 lean rc=2`; `P11 --address-space-top 64 ACCEPTED on both engines
(window-char-int7 -> Specified(28)) -> fork rc=0 lean rc=0`. Docs: DESIGN.md §4 and VALIDATION.md §7 state
the domain, that consumer theorems quantify `∀ top` under it, and the setup hypothesis `8 ≤ top`. The
CONSUMER RE-PIN NOTE (§C2) gains, verbatim from the consumer review: *"`MemWF.la_wf` in HeapModel.lean, line
140, requires `lastAddress ≤ 2^64`; `la_pos` also requires positivity. An unrestricted integer initial cursor
does not establish these facts."* and *"With a sufficiently small top, the driver can OOM while allocating
errno, before `main` or its Iris state is initialised."* — hence the domain and the `8 ≤ top` startup
hypothesis (the exemplar's theorem now carries exactly that hypothesis and no more).

**E12 — RESOLVED by F1** (the theorem is `∀ top, 8 ≤ top → …`; `run` takes `top`; `exemplarTop` deleted).
**Open item 2 — CLOSED.** Drift manifest: `main.ml` re-pinned once more (single row) + a C4 note; the gate is
green. **E15 (this section).** The pre-fix `CerbMem.allocator` is at `4a23d98aa`, not at `e64819de7^` (which
already carries remedy 1) — the orchestrator's cite was off by the part-one range.

**C4 FAST-GATE at the C4 tree (verbatim; `c4-*`):**
```
fast: passed; 16/16 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Total: 11 passed, 0 failed
check_no_fuel_numerals: OK (324 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
FuelExemplar: exemplar_certified_shipped_forall (∀ fuel, ∀ address-space top ≥ 8 over the shipped `@drive ⟨fuel⟩` from `initial_driver_state _ top`; the consumer's §6 shape, symbolic round library + the symbolic errno lemma) — kernel-checked at compile time
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
test_address_space: SELFTEST OK (11 plants — P1 the discriminator's verified pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain and non-decimal tops REFUSED on both engines, P11 a decimal top accepted; the committed file green)
Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```
The eleven plant lines (`c4-lane-selftest.txt`, verbatim): PLANT OK   [P1 the discriminator window-char-int7@32 forged to its verified PRE-FIX observation (Specified(2) where the kill is pinned)]; PLANT OK   [P2 missing expectations file]; PLANT OK   [P3 truncated expectations (last row dropped)]; PLANT OK   [P4 a row for a case this run never produced]; PLANT OK   [P5 phantom row WITHOUT a final newline]; PLANT OK   [P6 duplicate row WITHOUT a final newline]; PLANT OK   [P7 malformed row WITHOUT a final newline]; PLANT OK   [P8 the committed file with its final newline removed is ACCEPTED (the last row is read)]; PLANT OK   [P9 --address-space-top 18446744073709551616 (= 2^64) REFUSED on both engines with the mirrored domain sentence]; PLANT OK   [P10 --address-space-top 0x40 (not decimal) REFUSED on both engines]; PLANT OK   [P11 --address-space-top 64 ACCEPTED on both engines (window-char-int7.

**FULL gate at the C4 head (`release.py --mode full`, ONCE; verbatim per-lane tails in
`c4-release-full-tails.txt`):**
`release.py --mode full --out .tmp/c4-release-full` at `dc035396a`, nothing touching the tree meanwhile (wall 1:20:25; the record amendment was
held in `.tmp/` until it finished — E14):
```
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
```
Per lane (id status seconds): A1 passed 300s / A2 passed 34s / A3 passed 54s / A4 passed 23s / A4b passed 24s / A4c passed 3s / A5 passed 22s / A6 passed 2s / A6b passed 4s / A7 passed 10s / A8 passed 9s / A9 passed 17s / A10 passed 17s / A11 passed 58s / A12.1 passed 5s / A12.2 passed 4s / B1 passed 618s / B2 passed 23s / B3 passed 15s / B4 passed 46s / B5 passed 67s / B6.1 passed 2s / B6.2 passed 2s / B6.3 passed 3s / B6.4 passed 3s / B6.5 passed 3s / B6.6 passed 4s / B6.7 passed 3s / B7 passed 1311s / B8.1 passed 13s / B8.2 passed 223s / B8.3 passed 6s / B8.4 passed 16s / B9 passed 1310s / B10.1 passed 118s / B10.2 passed 2s / B11.1 passed 15s / B11.2 passed 7s / B12 passed 427s. Load-bearing lines, verbatim:
```
[A1] Total: 11 passed, 0 failed
[A1] check_no_fuel_numerals: OK (324 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
[A1] check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 25 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
[A1] ✓ fuel-exemplar-test PASSED
[A2] SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
[A2] Baseline check: 0 regression(s), 0 improvement(s)
[A3] Baseline check: 0 regression(s), 0 improvement(s)
[A4] Baseline check: 0 regression(s), 0 improvement(s)
[A4b] Baseline check: 0 regression(s), 0 improvement(s)
[A12.1] test_address_space: SELFTEST OK (11 plants — P1 the discriminator's verified pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain and non-decimal tops REFUSED on
[A12.2] test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
[B5] OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtype
[B7] SUMMARY: total=2001 compared=1916 agree=1904 agree_nd=0 triaged=12 disagree=0 o2_agree=196 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=12 skip_lean_fail=13 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
[B7] Baseline check: 0 regression(s), 0 improvement(s)
[B7] gcc second-oracle lane OK
[B10.1] Independent oracle: passed; {'semantic_agreement': 822, 'matching_failure': 28, 'reviewed_difference': 7, 'interface_agreement': 2}
[B10.2] Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
[B11.2] check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=166 REACHABLE=48 UNKNOWN=19; every row sealed; tally line consistent
[B12] Independent oracle: passed; {'semantic_agreement': 4}
```
Zero movement of any baseline row; row 10 exactly C0's verdict; the 18-case lane and its 11 plants green inside the certification.
