# Pre-merge audit — `arc/cerbglobal-defs` (reasoning-artifact audit A step 1) — 2026-09-05

Range audited: mainline `mdd/cerberus-lean` @ `928aa1e76` → `dda02fb61`
(two commits: `016b2a6ea` the change, `dda02fb61` record + change manifest).
Auditor [AGENT] (independent of the slice worker); written on branch
`audit/cerbglobal-premerge` (worktree `worktrees/cerberus-lean-audit/
cerbglobal-premerge`, base `dda02fb61`). Probed tree: the slice worktree
`worktrees/cerberus-lean-arc/zero-discrepancy` at `dda02fb61` with the
orchestrator's stamped binaries (read + lanes only; not edited). Every
quoted line is verbatim from that tree, the OCaml sources at this commit,
or the orchestrator's battery log `.tmp/cerbglobal-reverify.log`
(ephemeral; the lines this audit relies on are quoted here); tallies
marked "derived" are derived by the auditor.

Grades: MAJOR = a default that is not what the oracle computes in
matched mode / a ref that was written somewhere / a census row retired
that still exists / a gate weakened / a CLI-chosen value frozen into a
constant. MINOR = a record inaccuracy or a real but bounded gap. NOTE =
observation, no action required for merge.

## 0. Verdict

**MERGEABLE — no MAJOR.** Findings: 0 MAJOR, 3 MINOR (all record-
precision or pre-existing-gap items; none touches the change's
correctness), 7 NOTEs. The change is what the record says it is: eleven
`opaque … implemented_by` reads over two never-written `IO.Ref`s became
plain `def`s of the oracle driver's default configuration; each default
was checked against the cited OCaml line and is the oracle's; the one
moved value (`backendName`) is unobservable at every read site (all
nine lem sites are `= "Cn"`/`= "Bmc"` tests); the census moved DOWN only
(PIN 66→37, KEEP 8→4 real rows, OPAQUE_WANT 26→15) and both directions of
the pin trip on plants (§3); the exemplar change is kernel-only. The
record's §5.3 causal attribution for the moving oracle hash is wrong in
its "likely" cause but right that no source moved — the actual mechanism
is a git-derived version string embedded in the binary (F3).

Lane re-verification by this auditor after the orchestrator's battery:
§4 (verbatim tails).

## 1. Findings

### F1 (MINOR, record precision) — the `backend_name` read-site census in the record is incomplete (6 of 9 lem sites); the property holds at all 9

Record §2 ("the complete set, from the `.lem`"): `cabs_to_ail_effect.lem:
676`, `translation_effect.lem:231`, `translation.lem:409, 1732, 1741`,
`core_aux.lem:552-553`. Measured (`grep -n 'backend_name'
frontend/model/*.lem`, this tree), the sites outside `global.lem` are:

```
frontend/model/core_aux.lem:552:  let backend = Global.backend_name () in
frontend/model/cabs_to_ail_effect.lem:676:  begin if Global.backend_name () = "Cn" then
frontend/model/translation_effect.lem:231:    if Global.backend_name () = "Cn" then
frontend/model/translation.lem:409:  if Global.backend_name () = "Cn" then
frontend/model/translation.lem:1732:      else if Global.backend_name () = "Cn" then
frontend/model/translation.lem:1741:  begin if Global.backend_name () = "Cn" then
frontend/model/translation.lem:1822:  begin if Global.backend_name () = "Cn" then
frontend/model/translation.lem:1830:  begin if Global.backend_name () = "Cn" then
frontend/model/translation.lem:4120:                if Global.backend_name () = "Cn" then
```

and `core_aux.lem:553` `if backend = "Cn" || backend = "Bmc" then`. Three
sites (`translation.lem:1822, 1830, 4120`) are missing from the record's
enumeration — the Z2 audit's own row (`docs/2026-09-03_zero-discrepancy-
Z2-audit.md:429`) lists all nine. Every one is an equality test against
`"Cn"` or `"Bmc"`; none prints, stores or otherwise inspects the string,
so `"cerberus-lean"` → `"Driver"` (the oracle's, `backend/driver/main.ml:
124` `set_cerb_conf ~backend_name:"Driver" …`) changes no answer. The
generated tree agrees (derived: 9 `CerbGlobal.backend_name` applications
outside `generated/CerbGlobal.lean` — `Cabs_to_ail_effect.lean:787`,
`Translation_effect.lean:206`, `Translation.lean:224, 509 (×4), 704`, all
`== "Cn"`; `Core_aux.lean:384-385` `let backend := …; if (backend == "Cn")
|| (backend == "Bmc")`). NOT a MAJOR: the claim the record rests on is
true; only its evidence list is short. Fix: the record's §2 list should
read the nine sites (a docs-only follow-up, or fold into the merge's
record note).

### F2 (MINOR, record precision) — "two lanes run the oracle without `--mode`" undercounts: four lane scripts do

Record §2.1 and the in-file note: "Two lanes run the oracle without
`--mode`". Measured (the oracle `--exec --batch` invocations lacking
`--mode=exhaustive`): `scripts/test_immaculate.sh:140` (`oflags=(--exec
--batch)`), `scripts/test_libc_exec.sh:87`, `scripts/test_libxml2.sh:162`,
`scripts/test_libxml2_uri.sh:139, 160`. The Z2 audit named the first two
(Z2-G-01 row); the libxml2/URI lanes document their single-trace oracle
mode in their own headers ("default --mode=random: ONE trace"). Under
`Some Random` the oracle takes the then-arm of `driver.lem:1380`; the
equivalence argument (below, item 1) covers all four lanes identically
(single runnable thread), so no lane is affected. Fix: the count in the
record and the `CerbGlobal.lean` comment.

### F3 (MINOR, record §5.3 attribution) — the oracle binary hash moved because the binary EMBEDS `git describe --dirty`, not (as the record guesses) because of the shared opam switch

Record §5.3 observes three oracle `bin` hashes at one `src` hash
(`28fb2198…` before the slice, `eff14bc4…` after the first lane's build,
and the orchestrator's `e09043b6…` in the reverify log) and attributes
the relink to "an input outside the hashed set — the likely one is the
SHARED opam switch". The actual mechanism is in the tree:

```
ocaml_frontend/dune:12-18
(rule
 (targets version.ml)
 (deps (universe))
 (action
  (with-stdout-to version.ml
    (run ocaml -I +unix unix.cma %{dep:../tools/gen_version.ml})))
 (mode fallback))
```

```
tools/gen_version.ml:11-16
let git_version =
  Option.map ((^) "git-") @@ run_cmd "git describe --dirty --always"

let git_version_date =
  Option.bind (run_cmd "git describe --always") (fun hash ->
    run_cmd ("git show --no-patch --format=\"%ci\" " ^ hash))
```

and the built artefact in the slice worktree:

```
_build/default/ocaml_frontend/version.ml
let git_version : string = "git-cn-pin-697-gdda02fb61"
let git_version_date : string = "2026-09-05 08:00:18 +0000"
let version : string = "git-cn-pin-697-gdda02fb61"
```

`Version.version` is read by `backend/driver/main.ml:558` and
`backend/common/pipeline.ml:659`, so it is linked into `main.exe`. The
rule depends on `(universe)` (re-run every build) and the string carries
`--dirty` and the HEAD hash: the three hashes are exactly HEAD `928aa1e76`
clean → `928aa1e76-dirty` (the slice's edits in the working tree during
its battery; reflog: commits at 07:59:54/08:00:18) → `dda02fb61` clean
(the orchestrator's rebuild). This is a fully deterministic, source-
external, semantics-free input. The stamp's source set (`tools/
check_driver_fresh.sh` header, "SOURCE SETS") hashes `*.ml` under
`ocaml_frontend/` — the GENERATED `_build/…/version.ml` is not a source
and the generator `tools/gen_version.ml` is not under a hashed directory,
so the stamp cannot see it; by design it need not.

Assessment of the correctness question the brief asks (§5 below): the
switch IS a link-time input the stamp does not cover, but it is not what
moved here.

### F4 (NOTE) — the KEEP-row tally in the record counts comment mentions

Record §4: "KEEP rows 11 → 7 (derived, `grep -c KEEP`)". `grep -c KEEP`
counts lines containing the token, including the header's class
comments. Real (tab-separated) KEEP rows: 8 → 4 (derived, `grep -cP
'^\S+\t\S+\t\S+\tKEEP'`, before at `928aa1e76` and after). Both tallies
show the same four retirements; the record's is labelled derived. No
action beyond a wording fix.

### F5 (NOTE) — the record cites the consumer's README at `:585-600`; the paragraph is now at `:612-624`

`refined-cerberus/cerberus-heaplang/README.md` (read-only): the
"Which Cerberus configuration" bullet with "the Lean `CerbMem` references
no `CerbGlobal` constant, so `loadM`/`storeM`/`allocateObject`/`eqPtrval`
are switch-independent by construction; the one configuration read on a
proved path, the driver's `current_execution_mode`, is discharged for
both values by `cases` on the opaque test (`driver2_done`,
DriverCollapse.lean)" sits at `:612-624` at the consumer's current head
(the `:585-600` cite is inherited from the 2026-09-03 audit). Content
unchanged; the record's §6 restatement ("TRUE again, by unfolding") is
correct.

### F6 (NOTE) — `feature/concurrency` will auto-merge cleanly on both files; the semantic interaction is a dead `def`, not a conflict

Measured `git diff 928aa1e76..feature/concurrency -- lean_frontend/
CerbGlobal.lean lean_frontend/test/Unit/FuelExemplar.lean` (read-only):
`CerbGlobal.lean` — NO diff (the feature branch has not touched it; its
`using_concurrency` "step 2" is the `concurrency_model` PARAMETER of
`drive`/`step_ctx`/`process_core_step2`, and on that branch
`core_run_aux.lem` no longer reads `Global.using_concurrency` at all —
`feature/concurrency:frontend/model/core_run_aux.lem:29` "process-global
read -- Global.using_concurrency is no longer consulted"; the four
mainline reads `core_run_aux.lem:342,411,429,494` are gone there).
`FuelExemplar.lean` — their diff is 48+/18− in hunks at `:132` (`false` →
`CM_sequential` in `run`), `:258-290` (`loop_step_done`), `:301-316`
(`driver2_done`'s SIGNATURE: `tds false` → `tds CM_sequential`), `:416-
440` (`S₁`, `drive_after_setup`), `:459`, `:489+` (three new `rfl`
examples). This slice's hunks: the header comment `:27-35`, `:57-60`, and
`driver2_done`'s BODY `:336-354` (`cases hmode … | true => … | false =>
…` → `rw [CerbGlobal.current_execution_mode_eq]; rw [if_neg …]`). Their
`:301-316` hunk and this slice's `:336-354` hunk are ~20 unchanged lines
apart, so a 3-way merge resolves both without a conflict marker; the
merged `driver2_done` has their signature and this slice's body, which is
what both parties want (their branch still carries the `cases hmode` body
verbatim — checked in `feature/concurrency:lean_frontend/test/Unit/
FuelExemplar.lean:344-360`). Expected collision: NONE textual. Semantic
after their rebase: `CerbGlobal.using_concurrency` becomes an UNREAD def
(generated read count 4 → 0) with a true `rfl` lemma; the `CerbConf.
concurrency` field is then dead — their slice or step 2 should delete
both (a docs/cleanup point, not a rebase hazard). The scoping table
(`2026-09-04_concurrency-scoping.md` §4, their worktree) said "the
feature branch OWNS A-step-2 for `using_concurrency` only" — satisfied by
the parameter route; no `CerbGlobal` edit is needed from them. Their
branch's merge-base with mainline is `a910f097c` (before C3), so they
rebase over C3 + this slice together; nothing in this range makes that
harder.

### F7 (NOTE) — container CLAUDE.md's lem pin line is stale (`ecf75b4`); the pins are `d4ba548` and do agree

Not this range's doing (the container file is not a repo), recorded
because the record's "lem-lean `d4ba548` everywhere" was checked:
`lean_frontend/lake-manifest.json` LemLib `rev` = `d4ba548d…`;
`deps/lem-pinned` HEAD = `d4ba548d… (Fri Sep 4 23:36:46 2026)`; opam
`lem.2026-05-01 git git+file:///…/deps/lem-pinned#cerberus-pin`; the
switch's `sources/lem` HEAD = `d4ba548d…`. lem-lean mainline
`mdd/lean-backend` = `d4ba548` (`ecf75b4` is its ancestor — the
tails-and-pmap-laws slice landed after). The container CLAUDE.md
"= `ecf75b4`" line is one slice behind; operator's file.

### F8 (NOTE) — no stale reference to a deleted name anywhere outside docs

`grep -rn` for `confRef|switchesRef|getConf|has_switch_impl|
backend_name_impl|is_PNVI_impl|using_concurrency_impl` over `scripts/`,
`tools/`, `lean_frontend/*.lean`, `test/`, `speclab/`, both Makefiles:
zero hits (the allowlist's retired-section comment excepted). No gate
script carries a now-vacuous expectation on a deleted site.

### F9 (NOTE) — `current_execution_mode = none` and the `--first` deferral: `none` is behaviour-identical to the oracle's `Some Exhaustive` at both read sites, and to `Some Random` for every program this port reaches

Read sites, enumerated (model → generated): `driver.lem:748`
(`perform_action_request2`: `let _execution_mode_is_random = match
Global.current_execution_mode () with …` — an UNUSED binding; the only
other occurrence of the name in `frontend/model` or `generated/` is its
definition) → `Driver.lean:317`; `driver.lem:1380` (`driver2`: `begin if
Global.current_execution_mode () = Just Global.Random then …`) →
`Driver.lean:425` `if (maybeEqualBy (fun x y => x == y)
(CerbGlobal.current_execution_mode ()) (some CerbGlobal.ExecutionMode.
random)) then …`. So exactly one LIVE read on the exec cone. Its arms
(`driver.lem:1380-1428`): then — `ND.bindExhaustive (ND.pick (SK_misc
["driver 2"]) tid_steps) (fun (tid, step_opt) -> match step_opt with Just
step -> process_core_step2 … | Nothing -> ND.return ())`; else — filter
`tid_steps` to `non_blocked`, then `ND.pick (SK_misc ["driver
non_blocked"]) non_blocked >>= function (_, Nothing) -> ND.return () |
(_, Just step) -> process_core_step2 …`. For `none` and `Some Exhaustive`
the test is false — identical. For the oracle's `Some Random` (the four
`--mode`-less lanes, F2) the arms differ only in (a) `bindExhaustive` vs
`>>=` over the pick and (b) whether blocked threads are filtered; with a
single runnable thread (the only situation matched mode reaches —
`--concurrency` is refused, Z-24, and the oracle's is "BROKEN") the pick
is over a singleton in both arms and the same step is processed. The
Z2-G-01 instrument row says the same and recommends the lanes pass
`--mode=exhaustive` (INSTRUMENT, S) — still open, not this slice's.

`--first` did NOT flow into the ref: `Main.lean:1130` `let firstTrace :=
(batchMode || ppCoreMode) && rest0.head? == some "--first"`, `:1304`
passes it to `runPipeline`, `:967` `([], if firstTrace then CerbND.runND1
driverAction drSt else CerbND.runND driverAction drSt)`; no path names
`confRef`/`execMode` (grep, §F8). So the constant is not a frozen CLI
value — the brief's MAJOR class does not apply. The record's deferral
("should `--first` read as `Random`" → step 2) is the right call: making
it `some .random` would move the Lean side onto the then-arm in `--first`
runs (a behaviour change on the branch shape, moot at single thread) for
no matched-mode gain; when the read becomes a parameter the driver can
supply whatever mirrors the oracle's `--mode` exactly.

### F10 (NOTE, pre-existing, out of range) — `test_verify.sh` ignores `SKIP_BUILD=1`

`scripts/test_verify.sh:48-49` calls `build_cerberus` / `build_lean`
unconditionally and the script never reads `SKIP_BUILD` (grep: 0 hits;
`test_unit.sh` and `test_immaculate.sh` likewise have no `SKIP_BUILD`
logic but do not build the drivers). `common.sh`'s `SKIP_BUILD=1` path
adds the freshness `--check` at source time; it does not suppress a
lane's own build call. Consequence here: none (the incremental builds
produced byte-identical binaries and re-recorded identical stamps, §4.2).
Consequence in general: a "run on the stamped binaries only" intention
is not honoured by this lane — a discipline note for the lane's header,
not a gate.

## 2. Item-by-item checks (the brief's scope 1–5)

### 2.1 The eleven reads vs the OCaml (brief item 1)

Read at the cited lines (`util/cerb_global.ml`, `ocaml_frontend/
switches.ml`, `backend/driver/main.ml`; this tree):

| Lean `def` | Value | OCaml (verbatim) | Default origin (verbatim) | Oracle's in matched mode? |
|---|---|---|---|---|
| `backend_name` | `"Driver"` | `cerb_global.ml:45-46` `let backend_name () = !!cerb_conf.backend_name` | `main.ml:124` `set_cerb_conf ~backend_name:"Driver" ~exec exec_mode ~concurrency QuoteStd ~defacto ~permissive ~agnostic ~ignore_bitfields;` | yes (was `"cerberus-lean"`; F1: unobservable) |
| `current_execution_mode` | `none` | `:63-64` `!!cerb_conf.exec_mode_opt` | `:36` `let exec_mode_opt = if exec then Some exec_mode else None`; `main.ml:438-441` `Arg.(value & opt (enum ["exhaustive", Exhaustive; "random", Random]) Random & info ["mode"] …)` | oracle holds `Some Exhaustive`/`Some Random`; equivalent at every read (F9); declared Z2-G-01 |
| `using_concurrency` | `false` | `:48-49` `concurrency_mode () = !!cerb_conf.concurrency` | `main.ml:496-498` `Arg.(value & flag & info["concurrency"] ~doc)` (`(* TODO: is this flag being used? *)`) | yes |
| `isDefacto` | `false` | `:51-52` | `main.ml:515-517` `Arg.(value & flag & info["defacto"] ~doc)` | yes |
| `isPermissive` | `false` | `:54-55` | `main.ml:519-521` `Arg.(value & flag & info["permissive"] ~doc)` | yes |
| `isAgnostic` | `false` | `:57-58` | `main.ml:421-424` `Arg.(value & flag & info ["agnostic"] ~doc)` | yes |
| `isIgnoreBitfields` | `false` | `:60-61` | `main.ml:426-432` `Arg.(value & flag & info ["dignore-bitfields"] ~doc)` | yes |
| `has_switch sw` | `false` ∀ sw | `switches.ml:54-55` `let has_switch sw = List.mem sw !internal_ref` | `:47-48` `let internal_ref = ref []`; written only by `Switches.set switches` / `set_iso_switches ()` (`main.ml:137-143`) from `--switches`/`--iso`; the CHERI variant's `"CHERI" :: switches` (`:130-136`) is under `is_cheri_memory ()` — not this build | yes |
| `is_CHERI` | `false` | `:153-154` `List.exists (function SW_CHERI -> true \| _ -> false) !internal_ref` | over `[]` | yes |
| `is_PNVI` | `false` | `:156-157` `List.exists (function SW_PNVI _ -> true \| _ -> false) !internal_ref` | over `[]`; `SW_PNVI` not in the lem subset `global.lem:60-67` | yes |
| `has_strict_pointer_arith` | `false` | `:159-160` ``has_switch (SW_pointer_arith `STRICT)`` | over `[]`; not in the lem subset | yes |

`Arg.flag` is `false` unless the flag is passed; the port refuses
`--switches*`, `--concurrency` and every `--mode` (`Main.lean:1081-1091`,
Z-24; `:1084` "CerbGlobal's switch set is permanently empty"), and the
lanes never pass `--defacto/--permissive/--agnostic/--dignore-bitfields/
--iso/--switches` to the oracle (grep over `scripts/*.sh`: no hits). No
default is invented; each is the value `set_cerb_conf` receives with no
flag passed. The eleven `_eq` theorems are `rfl` on closed terms
(`CerbGlobal.lean:186-196`); `conf : CerbConf := {}` and `switches := []`
are the projected values; `CerbConf`, `ExecutionMode`, `CerbSwitch`
(with the Z2-G-02 `no_integer_provenance` note) are unchanged. The
hand-written file and `generated/CerbGlobal.lean` are byte-identical
(`cmp`).

Exec-cone read sites (so the reader can see what the `rfl`s now close):
`Core_run.lean:424` `core_thread_step2` (`has_switch .inner_arg_temps`),
`Driver.lean:317, 425` (F9), `CerbMem.lean:2167` `if CerbGlobal.has_switch
.forbid_nullptr_free then fail_ MerrFreeNullPtr`, `:2212` `if
CerbGlobal.has_switch .zap_dead_pointers then`, `:2630` `if
CerbGlobal.is_PNVI () then`, `Core_run_aux.lean:451, 463, 472, 484`
(`using_concurrency`). Elaboration-cone reads (derived census over
`generated/*.lean` excluding the seam copy): `is_CHERI` 32, `isAgnostic`
12, `has_switch` 9, `backend_name` 9, `using_concurrency` 4, `is_PNVI` 4,
`has_strict_pointer_arith` 4, `isPermissive` 3, `current_execution_mode`
2, `isIgnoreBitfields` 1, `isDefacto` 1 — the record's §1 numbers, re-
derived, equal.

Setter search (the "a ref WAS written" MAJOR class): `grep -rn` for
`confRef|switchesRef|set_cerb_conf|setConf|CerbGlobal\.set|Switches\.set|
getConf|\.modify` over all `*.lean` under `lean_frontend/` INCLUDING
`generated/`, excluding `.lake/`: hits are comments only
(`CerbGlobal.lean:24,39,90` and its copy; `CerbMem.lean:2246` and its copy
— a doc cite of `Switches.set []`). No setter existed before the change
either: at `928aa1e76` the only references to the refs were their two
definitions and the two reads inside `CerbGlobal.lean` (record §1,
re-verified by `git show 928aa1e76:lean_frontend/CerbGlobal.lean` +
grep). Behaviour identical by construction — confirmed.

### 2.2 Deletions and census (brief item 2)

`lean_frontend/CerbGlobal.lean` after: `grep -n 'unsafe\|opaque\|
implemented_by'` → two hits, both comment text (`:14`, `:183`); zero
`unsafeBaseIO` (even in comments — the allowlist header's
comment-mention list correctly drops `CerbGlobal.lean:51`). Diff
`928aa1e76..dda02fb61 -- scripts/unsafebaseio_allowlist.txt`: exactly 29
`PIN … lean_frontend/CerbGlobal.lean …` lines removed — derived count by
class: IMPLBY 11 (`backend_name_impl, current_execution_mode_impl,
has_strict_pointer_arith_impl, has_switch_impl, isAgnostic_impl,
is_CHERI_impl, isDefacto_impl, isIgnoreBitfields_impl, isPermissive_impl,
is_PNVI_impl, using_concurrency_impl`), UNSAFEBASEIO 4 (`confRef, getConf,
has_switch_impl, switchesRef`), UNSAFEDECL 14 (the 11 `_impl` + `confRef,
getConf, switchesRef`) = 29; PIN rows 66 → 37 (derived `grep -c '^PIN '`
before/after). KEEP rows removed: 4 (`confRef, switchesRef, getConf,
has_switch_impl`, class `temporal(post-arc-parameter-plumbing-slice)`),
8 → 4 real rows (F4). `scripts/check_theorem_axioms.sh` `OPAQUE_WANT`:
26 → 15 (derived count of quoted rows), the 11 removed rows all
`CerbGlobal.lean:*`; the 15 remaining are the 7 `CerberusFresh` digest
rows, 4 `CerbUtils`, 2 `CerberusImpl`, `CerbMem.lean:beqMemValueSafe`,
`CerbFuel.lean:fuelExhaustedLoc` — the manifest's list, exactly. No row
was added anywhere; no population moved up. Gate text changes: the
OPAQUE_WANT comment, `check_exec_purity.sh:41-48` (comment only, no code
line changed — checked hunk by hunk), `VALIDATION.md` gate row (26 → 15
with the reason), the trust-boundary list; `TODO.md` and `lean_frontend/
CLAUDE.md` table row. Nothing weakened: both-directions pins remain (the
`UNREGISTERED` and `found 0 time(s)` legs, `check_theorem_axioms.sh:232-
250`); plants in §3.

### 2.3 `FuelExemplar` (brief item 3)

The one proof change is `driver2_done`'s scheduler-mode step: `cases
hmode : maybeEqualBy … (CerbGlobal.current_execution_mode ()) (some
.random) with | true => … | false => …` (two arms, 17 lines) → `rw
[CerbGlobal.current_execution_mode_eq]; rw [if_neg (fun h =>
Bool.noConfusion h)]` then the former `false` arm verbatim. Kernel-only:
`rw` with a `rfl` lemma. `grep -n 'set_option\|maxRecDepth\|
maxHeartbeats\|native_decide\|bv_decide\|ofReduce\|decide +kernel\|
sorry'` over the file → one hit, `:88 set_option autoImplicit false`
(pre-existing). No bump. The exemplar's axiom cones are covered by the
FUEL leg of `check_theorem_axioms.sh` (`34 contract lemmas … + the ∀-fuel
exemplar and its instances …, every cone ⊆ [propext, Classical.choice,
Quot.sound]`), quoted in §4 from this auditor's run — unchanged from the
C3 record's line. Header comment edits (`:27-35`, `:57-60`) describe the
read as a plain def now; accurate.

### 2.4 Concurrency-branch interaction (brief item 4)

F6.

### 2.5 The oracle-relink observation (brief item 5)

Mechanism: F3 (the version string). On the brief's questions:

- *Does the stamp's source set cover the switch?* No, by declaration:
  `tools/check_driver_fresh.sh` header, "Declared non-goals … the opam
  switch / Lean toolchain binaries and the Lake packages tree are not
  hashed (the manifest pin is the identity)". The oracle DOES link
  switch-installed OCaml libraries — `backend/driver/dune` `(libraries
  result cmdliner str unix mem_concrete cerberus-lib.backend_common
  lean_export)` and transitively `lem` (`ocaml_frontend/dune:10`
  `(libraries unix lem pprint cerb_util sibylfs)`), whose `_opam/lib/lem`,
  `lem_num`, `lem_zarith` were reinstalled today at 02:43:38 (mtime; the
  opam pin `lem.2026-05-01 … deps/lem-pinned#cerberus-pin` at `d4ba548`,
  F7). A lem runtime change WOULD relink the oracle at an unchanged source
  hash and could change behaviour; the stamp would not see it. That is
  the real (pre-existing) gap; it is governed by the pin invariant
  ("branch heads = opam pin = Lake pin") rather than by the stamp.
- *Correctness risk of a lane running a binary linked against another
  checkout's installed files?* Bounded: (i) `main.exe` is a native OCaml
  executable — its libraries are linked in at link time, so nothing in
  the switch is read at RUN time; (ii) the workspace defines
  `cerberus-lib` itself, so dune links the in-tree library, not
  `_opam/lib/cerberus-lib` — the shared-switch rewrite the record points
  at does not enter the link; (iii) the runtime FILES (Core stdlib,
  `libc.co`, includes) are resolved by `--runtime=` — `scripts/common.sh:
  244` `"$CERBERUS_BIN" --runtime="$PROJECT_ROOT/_build/install/default"
  "$@"` and every direct lane invocation above passes `--runtime=
  "$RUNTIME_DIR"` — so lanes read THIS worktree's staged runtime, never
  the switch's (`util/cerb_runtime.ml:45-51`: `specified_runtime` has
  highest priority). The only cross-checkout channel is the one in the
  previous bullet (the switch's `lem*`/other OCaml libs), and its inputs
  are pinned by the two-repo pin dance.
- *Reproducibility nuisance?* Yes, permanent and by design: `bin` hashes
  differ across commits and across dirty/clean states of the SAME
  sources; two content-identical worktrees on different commits get
  different oracle hashes (the stamp header anticipates this for the
  `commit` line but the `bin` line inherits it via `version.ml`).

Recommendation ([AGENT], for the operator): (a) amend record §5.3's
"likely" attribution to the measured mechanism (docs-only, this audit
suffices as the record of it); (b) if the operator wants the stamp to
mean "same bytes ⇔ same sources", either exclude `Version` from the
oracle (a `--version`-only concern — the string is printed, not
consumed) or accept the nuisance and document it in the stamp header;
(c) the lem-runtime gap is worth one line in the stamp header's
non-goals naming `lem`/`lem_zarith` explicitly, and, if wanted, a cheap
extra leg: record `git -C deps/lem-pinned rev-parse HEAD` in the oracle
stamp and compare on `--check` (the pin is the identity the header
already appeals to). None of (a)–(c) blocks this merge.

## 3. Plants (both directions of the census pin) — run in THIS worktree on a copy of the slice's `generated/` and LemLib package

Setup: `lean_frontend/generated/` (205 files) and `lean_frontend/.lake/
packages/LemLib/` copied byte-for-byte from the slice worktree into this
(otherwise unbuilt) worktree; a `lake` stub that exits 99 with `AUDIT
GUARD: lake invoked …` was first on `PATH` so that no leg could reach a
Lean build here (none did — each plant exits at its own leg). Each plant
was reverted afterwards (`git checkout` / re-copy; `git status` clean but
for this document). `bash scripts/check_theorem_axioms.sh` each time.

P1 — re-register a retired opaque row: `'CerbGlobal.lean:has_switch'`
appended to `OPAQUE_WANT`. rc=1:

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: FAIL — boundary-opaque census: registered opaque CerbGlobal.lean:has_switch found 0 time(s) in the build copy, expected exactly 1 (0 = copy-pipeline/scanner drift or opaque->def; 2+ = duplicated; fail-closed)
```

P2 — an unregistered opaque reappears in the seam's build copy: `opaque
plantProbe : Unit → Bool` appended to `lean_frontend/generated/
CerbGlobal.lean`. rc=1:

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: FAIL — boundary-opaque census: UNREGISTERED opaque CerbGlobal.lean:plantProbe (x1) in the build tree — every opaque is a declared-boundary decision; register it in OPAQUE_WANT with its class, or remove it
```

P3 — a retired PIN row re-added to the allowlist: `PIN IMPLBY
lean_frontend/CerbGlobal.lean backend_name_impl 2`. rc=1 (and, unplanted
at that leg, the opaque census on the copied tree reports the 15):

```
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: FAIL — C2 ratchet leg 3: pinned population row(s) NOT FOUND at their pinned count (scanner or copy-pipeline drift, or a survivor deleted/duplicated without updating the pin — update scripts/unsafebaseio_allowlist.txt consciously):
IMPLBY lean_frontend/CerbGlobal.lean backend_name_impl 2
```

Both directions of both pins are live: a row without a site fails (P1,
P3), a site without a row fails (P2). The retired rows could not have
been retired vacuously (P1/P3 show the gate would have refused the
old rows against the new tree), and no opaque can return to
`CerbGlobal.lean` unnoticed (P2).

## 4. Lanes (this auditor, after the orchestrator's `=== DONE`; serial; `SKIP_BUILD=1` so the stamped binaries are `--check`ed, not rebuilt; `CERB_MEM_MAX=16G`, `ulimit -c 0`)

Precondition: the orchestrator's battery log ended `=== DONE` at
08:53:57 UTC (every `--- rc=0`; 26 sections: `rebuild`, `check_driver_
fresh --check`, `test_unit`, 4× `test_exec`, `test_bytes`, `test_libc_
exec`, `test_multi_tu`, `test_parse`, `test_core`, `test_elab`, `test_
libxml2_uri`, `test_cn_coverage`, `test_parse tests/ci`, `test_core
tests/ci`, `test_verify`, `test_immaculate`, 2× `test_speclab`, `test_
hang_plant`, `test_kill_plant`, `test_fuel_plant`, `test_libxml2`,
`test_gcc_oracle`). Its stamps: `check_driver_fresh: oracle OK (bin
e09043b6e572e61d44ffd14efaa5a36bb038bb7f12f2bf454f040177dced5e2d, src
7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)` /
`lean OK (bin 00edd6fd350dd67a27f7c11d82545a2caf05cafd992e60ec8fccc44f73c2550a,
src e9f05dfb8921eadea7fbc2f972e04d43d297aee7474ec431d3711bc082eec63b)` —
the same two pairs every lane below re-checked (the `lean` `src` hash
equals the record's §5; the oracle `bin` differs from the record's
`eff14bc4…` for the reason in F3, `src` equal).

### 4.1 `./scripts/test_unit.sh` — rc=0 (08:54:44 → 08:57:02 UTC)

```
check_driver_fresh: oracle OK (bin e09043b6e572e61d44ffd14efaa5a36bb038bb7f12f2bf454f040177dced5e2d, src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)
check_driver_fresh: lean OK (bin 00edd6fd350dd67a27f7c11d82545a2caf05cafd992e60ec8fccc44f73c2550a, src e9f05dfb8921eadea7fbc2f972e04d43d297aee7474ec431d3711bc082eec63b)
check_handwritten_sync: OK (35 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
✓ effects-proof-test PASSED
✓ totality-proof-test PASSED
Done: 292 passed, 0 failed
✓ core-parser-test PASSED
✓ fresh-int-test PASSED
✓ pp-test PASSED
FuelExemplar: exemplar_certified_shipped_forall (∀ fuel over the shipped `@drive ⟨fuel⟩`; the consumer's §6 shape, symbolic round library) — kernel-checked at compile time
FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the runner's distinguished kill) — kernel-checked at compile time
FuelExemplar: exemplar_killed_at_one (fuel 1 → the kill at the first memory operation; fuels ≥ 2 deliver Specified(42)) — kernel-checked at compile time
✓ fuel-exemplar-test PASSED
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (205 files: 0 axioms, boundary-opaque population = the 15 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_theorem_axioms: C2 ratchet OK (321 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 37 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: D14 grep-ban OK (no native_decide/bv_decide in 1 tree(s) + 35 hand-written seam files + LemLibTest.lean)
check_theorem_axioms: driver2 cone sorryAx-free + ofReduce*-free + DAEMON-free (arc-8 S3 bar)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: mem-scale S1 leg OK (6 C1/C3 equality theorems, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: FUEL arc leg OK (34 contract lemmas — 9 generated _zero + the CerbND runner leaves/parametricity pins + the ∀-fuel exemplar and its instances + the 3 fuel_measure sufficiency obligations (generated statement + hand-written proof), every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (282 files scanned comment-stripped — generated 205, hand-written+test 42, LemLib 35; 0 sorry tokens)
test_fuel_classifier: 18 fixtures, ALL OK
check_no_fuel_numerals: OK (286 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
check_lakefile_roots: OK (204 roots = 204 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: OK (81 fuel'd workers: 47 MEASURED (every obligation + proof cone ⊆ the standard three), 13 ABSORBING, 15 reachable-AMBIENT = the 15 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_lem_sync: lean OK (src 35721b02e35a47e204820dca79adc99697bc81cf7bfa6727420cbe92e87fe4b8, gen e48450a7c3ef435844a6de36180fa1a473126c3bf0a5a8a1e1f23b0bea740218)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```

The two census lines are the ones this audit is about: `boundary-opaque
population = the 15 registered rows` (was 26 at `928aa1e76`, the C3
record §6.1) and `seam population = the 37 pinned … rows` (was 66). The
FUEL leg line (the exemplar's cones) is identical to the C3 record's. The
lem-sync stamps (`gen 295e4f82…`, `gen e48450a7…`) equal the C3 head's —
no `.lem` output moved (the record's §5.1 claim, re-verified).

### 4.2 `./scripts/test_verify.sh` — rc=0 (08:57:30 → 08:58:35 UTC)

```
check_driver_fresh: oracle OK (bin e09043b6e572e61d44ffd14efaa5a36bb038bb7f12f2bf454f040177dced5e2d, src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)
check_driver_fresh: lean OK (bin 00edd6fd350dd67a27f7c11d82545a2caf05cafd992e60ec8fccc44f73c2550a, src e9f05dfb8921eadea7fbc2f972e04d43d297aee7474ec431d3711bc082eec63b)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```

(F10: this lane calls `build_cerberus`/`build_lean` unconditionally
(`scripts/test_verify.sh:48-49`; the lane has no `SKIP_BUILD` handling),
so it re-ran the incremental builds and re-recorded both stamps — with
byte-identical hashes: `recorded oracle stamp (bin e09043b6…, src
7f1a0c0a…)`, `recorded lean stamp (bin 00edd6fd…, src e9f05dfb…)` — then
`--check`ed them four more times, all OK.)

### 4.3 `./scripts/test_immaculate.sh` — rc=0 (08:59:03 → 09:01:00 UTC)

```
check_driver_fresh: oracle OK (bin e09043b6e572e61d44ffd14efaa5a36bb038bb7f12f2bf454f040177dced5e2d, src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)
check_driver_fresh: lean OK (bin 00edd6fd350dd67a27f7c11d82545a2caf05cafd992e60ec8fccc44f73c2550a, src e9f05dfb8921eadea7fbc2f972e04d43d297aee7474ec431d3711bc082eec63b)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

### 4.4 Tier B (not re-run by this auditor) — the orchestrator's reverify log, verbatim verdict lines

```
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the …
test_speclab: PASS (both pipelines agree on Specified(0))
test_speclab: PASS (both pipelines agree on Specified(2))
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
ALL PASSED
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
=== DONE
```

(`test_parse tests/ci` / `test_core tests/ci`: `Cerberus --pp:  128 ok,
122 failed` / `Lean parse:     128 ok, 0 failed` / `ALL PASSED`; the four
`test_exec` rows and `test_cn_coverage`: `Baseline check: 0
regression(s), 0 improvement(s)`.) Every number equals the record's §5.2
table and the C3 record's — derived comparison, row for row. The
orchestrator's log omitted no Tier B lane the record ran except the five
`test_speclab_*.sh --gate` rows, which the record §5.2 reports green
(`… PASS (--gate)`) on the same Lean binary hash `00edd6fd…`.

## 5. Not checked

- No Tier A rows 2–11 or Tier B lanes were re-run by this auditor
  beyond the three the brief names; Tier B evidence is the orchestrator's
  battery log (§4.4 cites its verdict lines) and the record's §5.2 table.
- The consumer's actual proofs were not re-run against this head (their
  pin is the mainline commit; the change manifest is for their re-pin).
- `feature/concurrency`'s own build/gates were not run; F6 is a diff
  reading, not a rebase rehearsal.
- The OCaml oracle was not rebuilt by this auditor; F3's mechanism is
  established from the tree's rule + generator + the built `version.ml`
  + the reflog, not by reproducing the three hashes.
- Whether `Epar`/thread spawn can ever yield ≥2 runnable threads in
  matched mode (which would separate the two arms at `driver.lem:1380`
  under the oracle's `Some Random`) was not re-derived; the Z2 audit's
  single-thread premise is taken as given (F9).
