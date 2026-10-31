# Pre-merge review: merge-base bump stage 1 (`arc/merge-base-bump` @ `055602f61`)

Reviewer: [AGENT 2026-10-30, reviewer] (fresh, independent). Worktree
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/merge-base-bump`, twelve commits over
`676f9f21c`, merge commit `a44c6e0b8` with upstream `c3ff8c53f`. Read-only: no tracked file edited, no
lake/dune/make, no lane script, git state untouched. Scratch: `/home/dev/projects/cerberus-lean-proj/.tmp/review-bump/`
(`probes/*.c`, `run_probes.sh`, `run_lean.sh`, `probes*.log`, `lean.log`, `out/*.json`, `{old,new}_carrier.txt`).

## Verdict

**NOT MERGEABLE as it stands — one P1 that needs an operator ruling and a small fix, then mergeable.**
Everything else I checked (the 13 resolutions, S2, the backport, the restatement, LOC_ONLY, the refusals, the
manifest re-derivation, kernel replay, the baselines I spot-checked) holds up. The P1 is a regression of the
fork's own oracle on valid C that the arc did not notice and whose record text claims the opposite; it is the
second half of the very upstream regression window the arc already found (tray 67), so the remedy is in reach.

## Scope and what I ran

Read: the container and `lean_frontend` practices, the charter, the scoping record (§ pointers), the whole
stage-1 record, the two consumer notes, CONTRACT/VALIDATION/SUPPORTED/TODO/tray INDEX/tray 67 lines that moved,
`scripts/fork_drift_manifest.txt` (NOTE block), `scripts/upstream_oracle_differences.json` (the two new rows),
`tests/libc_exec/dispositions.txt`, the LOC_ONLY classifiers in `scripts/test_libc_exec.sh` and
`scripts/inner_arg_temps_lane.py`, `CerbStopSites.lean`, `CerberusImpl.lean` (layout block + reps + doc),
`CerbMem.lean` (`arrayShiftPtrval`, `memcpyM`, `memcmpM`), `Main.lean` (`elabConf`), `ocaml_implementation.ml`
and `memory/concrete/impl_mem.ml` at `c3ff8c53f`, `pipeline.ml`, `tags.ml`.

Diffs read in full: `git diff c3ff8c53f a44c6e0b8 -- frontend/model/{mini_pipeline,implementation,
cabs_to_ail_effect,translation,translation_effect,core_typing,mem}.lem` and the first 260 lines for
`cabs_to_ail.lem`; the fork-side removals `git diff a44c6e0b8^1 a44c6e0b8 -- …` for mini_pipeline,
translation (fork-marker lines), translation_effect; `git show 736690a65 -- frontend/model/mini_pipeline.lem
ocaml_frontend/ocaml_implementation.ml`; `git log --stat b9aeedcb4..c3ff8c53f`; `git diff 676f9f21c HEAD --stat`.

Runs (verbatim commands; all read-only on built binaries):

```
# four engines on each probe (fork oracle, pristine c3ff8c53f, pristine b9aeedcb4, Lean):
cd /home/dev/projects/cerberus-lean-proj/.tmp/review-bump
./run_probes.sh /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/merge-base-bump/.validation-foundations/independent-oracle-v2/cerberus/_build/install/default probes/p*.c
#   inside: scripts/ce <engine>/main.exe --runtime=<its install> --nolibc --exec --batch --mode=exhaustive <f.c>
#           scripts/ce <fork>/main.exe --runtime=... --cabs-json <f.c> > out/<f>.json
#           LEAN_ABORT_ON_PANIC=1 lean_frontend/.lake/build/bin/cerberus-lean --batch --runtime=<fork install> out/<f>.json
# the pre-merge fork oracle (mainline checkout, 676f9f21c) on the P1 probes:
scripts/ce /home/dev/projects/cerberus-lean-proj/cerberus-lean/_build/default/backend/driver/main.exe --runtime=/home/dev/projects/cerberus-lean-proj/cerberus-lean/_build/install/default --nolibc --exec --batch --mode=exhaustive probes/p24_alignas_union_twice.c   # and p25, p27, p29
# kernel replay, independent of the record's run (LEAN_PATH built by hand, no lake):
cd lean_frontend && CERB_MEM_MAX=8G LEAN_PATH="$PWD/.lake/build/lib/lean:$PWD/.lake/packages/LemLib/lean-lib/.lake/build/lib/lean:$PWD/.lake/packages/batteries/.lake/build/lib/lean:$PWD/.lake/packages/Qq/.lake/build/lib/lean:$PWD/.lake/packages/iris/.lake/build/lib/lean" ../scripts/capped ~/.elan/toolchains/leanprover--lean4---v4.35.0/bin/leanchecker CerberusImpl_lemMeasureProofs CerberusImpl CerbMem Translation_lemMeasureProofs Defacto_memory_lemMeasureProofs
#   -> leanchecker exit=0
# manifest layer-2 spot check against the scratch pristine tree:
diff .tmp/pristine-c3ff8c53f/ocaml_frontend/generated/{formatted,translation_aux,mini_pipeline,ctype}.ml ocaml_frontend/generated/…
# moved carrier = namespace rename: deleted lines of the old CerbMem carrier (CerbMem.->CerberusImpl.) vs the new file
comm -13 old_carrier.txt new_carrier.txt ; comm -23 old_carrier.txt new_carrier.txt
```

Probe results (31 programs; `probes.log`, `probes2.log`, `probes3.log`, `lean.log`) are summarised under each finding
and in "What held up".

## Findings

### P1 — Desugar-time `alignof` of a union now crashes the fork ORACLE where it answered before the merge; the Lean engine still answers; the divergence is unregistered and the record claims it cannot occur

**Claim under review.** Record §2.1 (S1): "unobservable at every stage-1 call site (the wrappers pass one map
twice …)"; `lean_frontend/CerberusImpl.lean:286-293` ("at every stage-1 call site that is unobservable") and
`:622-627` ("at desugar time (`get_alignof`) the explicit map is the desugar state's real table where upstream's
global is EMPTY (`Pmap.find` Not_found — a crash the fork's pre-merge pseudo-map `alignof_ty` already answered
with the value; re-measured by the alignas witnesses at M4)"). Record §4.9: "No finding; nothing refused".

**Evidence.** `cabs_to_ail_effect.lem:2285-2299` `get_alignof` returns a closure over
`Implementation.alignof_ty` = `Ocaml_implementation.alignof` on the oracle, whose union arm at `c3ff8c53f`
reads the Tags GLOBAL (`ocaml_implementation.ml:566`, fork `:579`), unset during desugaring
(`backend/common/pipeline.ml:272` resets it; `backend/driver/main.ml:352` sets it after elaboration). The
closure is applied wherever two alignments are compared: `cabs_to_ail.lem:2912` `desugar_alignment_specifiers`
(two `_Alignas` on one declaration) and `cabs_to_ail_effect.lem:2303` `get_compatible_alignment_requirements`
(an aligned redeclaration). On Lean, `CerberusImpl.alignof_ty` (`CerberusImpl.lean:631`) is the one-map wrapper
over the EXPLICIT map (`_readerTagDefs` unused), so the union arm reads the desugar state's real table and
answers.

Verbatim (scratch `probes2.log`; the pre-merge fork oracle from the mainline checkout `676f9f21c`):

```
##### p24_alignas_union_twice        union U { int x; double y; }; _Alignas(union U) _Alignas(1) char c; int main(void){ return _Alignof(union U); }
--- fork oracle (c3ff8c53f-based):   Failure("Tags definitions must be set by Tags.set_tagDefs before any use")
                                     Called from Cerb_frontend__Ocaml_implementation.alignof … line 579 … Called from …Cabs_to_ail.desugar_alignment_specifiers   [exit 125]
--- pristine c3ff8c53f:              the same Failure, Ocaml_implementation.alignof line 566   [exit 125]
--- pristine b9aeedcb4 (old base):   Defined {value: "Specified(8)", …}   [exit 0]
--- lean (cabs-json from fork oracle): Defined {value: "Specified(8)", …}   [exit 0]
--- mainline checkout oracle (676f9f21c, pre-merge fork): Defined {value: "Specified(8)", …}
##### p25_alignas_union_redecl       extern _Alignas(union U) char c; extern _Alignas(union U) char c;
--- fork oracle: the same Failure via Cabs_to_ail_effect.get_compatible_alignment_requirements [exit 125]; pristine c3ff8c53f: same;
--- pristine b9aeedcb4: Specified(0); lean: Specified(0); pre-merge fork oracle: Specified(0)
##### p27_alignas_struct_union_twice struct S { char a; union U u; }; _Alignas(struct S) _Alignas(2) char c;
--- fork oracle: same Failure (alignof :579 from alignof.(fun) :572) [exit 125]; pristine c3ff8c53f: same;
--- pristine b9aeedcb4: Specified(8); lean: Specified(8); pre-merge fork oracle: Specified(8)
##### p28_alignas_struct_twice_control (no union): Specified(8) on all four engines
```

So: (i) valid C (`_Alignas(union U) _Alignas(1) char c;` is well-formed, C17 6.7.5) crashes the merged fork
oracle where the pre-merge fork oracle answered — the arc moved the oracle from an answer to a crash;
(ii) Lean answers, so the fork now carries a Lean-vs-oracle crash/answer divergence in matched mode that no lane,
pin, census row (VALIDATION §3) or register row records (the corpora have no two-specifier `_Alignas` with a
union; `tests/ci/0330-alignas.syntax-only.c` has two specifiers but `int`, and is parse-only); (iii) the record's
"unobservable at every stage-1 call site" is false — it is observable exactly at `get_alignof`; (iv) the record's
and `CerberusImpl.lean:626`'s description of the oracle's failure ("empty (Not_found)") is wrong — the global is
UNSET and the failure is `Failure("Tags definitions must be set …")`; (v) this is the second half of the same
b3e11ea33..736690a65 regression window that tray 67 describes: at `b9aeedcb4` the desugarer's `alignof_ty` was
`Ocaml_implementation.alignof_proxy` over a pseudo-map and never touched the global; b3e11ea33 routed it through
the moved `alignof` whose union arm still reads the global; 736690a65's ONE OCaml line
(`ocaml_implementation.ml:566`: `Pmap.find tag_sym (Tags.tagDefs ())` → `Pmap.find tag_sym tagDefs`) closes it.
Tray 67 as filed covers only the mini-run half. The charter's M0 explicitly asked that "`alignof_ty` on an
incomplete type must stay a loud refusal, never `0`" and that M4 re-measure the alignas witnesses; the witnesses
(`tests/coverage/alignas/*`, `zd-ta-alignas-*`, `d3-s3-alignas-enum`) never apply the closure to a union.

**Why it blocks.** The standing rules: zero Lean-vs-OCaml behavioural discrepancies; every known difference is
in the census or a register; a record's claim of unobservability must be true. A crash is not a silently wrong
answer, so this is not the worst class — but it is an unregistered regression of the oracle surface introduced by
this arc, contradicted by its own record, and the arc's S1 doc leans on the false claim to justify the deferred
proof restatement.

**Concrete fix (needs an operator ruling, the same shape as the §2b.1 ruling).**
1. Ask the operator to extend the authorized 736690a65 backport to its second one-line part:
   `ocaml_frontend/ocaml_implementation.ml` `alignof`'s union arm, `Pmap.find tag_sym (Tags.tagDefs ())` →
   `Pmap.find tag_sym tagDefs` (verbatim 736690a65's hunk). Both engines then answer, which is upstream's own
   next-commit semantics and what the fork answered before. Register it: the `[source-content]` row for
   `ocaml_implementation.ml` re-pinned with a dated justification, manifest NOTE fork-ahead delta (1) extended
   ("two lines of 736690a65"), tray 67 extended to the desugar-time `alignof` half with p24/p25/p27 as
   reproducers, TODO stage-2 "leaves" list updated.
   Fail-closed alternative if the ruling declines: keep the oracle's crash and make the Lean path a declared
   refusal at `get_alignof` for union-containing types (a crash → refusal refinement on the oracle too would be
   the cleaner mirror), with the pair pinned.
2. Either way: an immaculate pin for each of the three shapes (`zd-ta-alignas-union-twice`, `-union-redecl`,
   `-struct-union-twice`) with the expected class; VALIDATION §3 census row until both engines agree.
3. Correct the record (§2.1 S1, §4.9 "No finding") and `CerberusImpl.lean:286-293`, `:622-627`
   (the failure is `Failure("Tags definitions must be set…")`, it IS observable at `get_alignof`, and
   pre-merge BOTH engines answered — the oracle via `alignof_proxy`).
4. Re-run the affected rows (A2/A3 coverage alignas, B5 immaculate, B10/B12 pristine register, fork-drift) after
   the fix.

### P2 — The `offsetof-union-member` Lean stop now names an upstream site that no longer fails there; the register's reason text is stale

**Claim.** Failure-reach register row 75 (`scripts/failure_reach_register.txt:75`):
`CerberusImpl.sizeofCtype_lemFuel … REACHABLE … witness tests/immaculate/nolibc/offsetof-union-member.c: both crash
(oracle Failure("Tags definitions must be set…"), Lean PANIC CerbMem:478)`; `CerbStopSites.sizeofUnion`
(`CerbStopSites.lean:100-102`) cites `ocaml_implementation.ml:501-504` at `c3ff8c53f`.

**Evidence.** `probes2.log` p29 (= the immaculate witness): fork oracle and pristine `c3ff8c53f` crash in
`Ocaml_implementation.alignof` (`:579` / `:566`, the Tags-global union arm, reached from `offsetsof` `:468`/`:455`);
the Lean stop prints `UPSTREAM_CRASH CerberusImpl.sizeofUnion … ocaml_implementation.ml 501 504 "| Union tag_sym ->
begin match Pmap.find tag_sym tagDefs with …"` — that upstream arm reads the THREADED map since b3e11ea33 and does
not fail on this input. The Lean worker fails at its `sizeofCtype` union arm because it reads `ambient` (empty at
elaboration time) where upstream's `sizeof` union arm reads the threaded map; the real upstream crash is the
`alignof` union arm (`:565-568`, which `CerbStopSites.alignofUnion` quotes correctly). Both engines crash, so the
pin's class is unchanged, but the stop record is a misattributed mirror and the register reason still cites
`CerbMem:478` (the pre-move file and line; the re-key kept the stale text).

**Fix.** Either make `sizeofCtype_lemFuel`'s union arm read `tagDefs` (the threaded map) as upstream's `:502`
does — then the Lean failure moves to the `alignof` union arm exactly as upstream's (this is the per-function
lookup the record deferred to stage 2; if deferred, say so in the stop record), or at minimum re-cite the Lean
`sizeofUnion` stop to the live upstream failure (`alignof` `:565-568` via `offsetsof`) and rewrite row 75's reason
(`CerbMem:478` → the `CerberusImpl.lean` line; the Lean site is the `ambient` lookup, not a mirror of `:501-504`).
`CerberusImpl.lean:289` ("deliberately … unobservable") should name this pin as the one observable site at
elaboration time (crash/crash, different arm).

### P3 — The charter's D13 const-expression re-measure is not recorded; upstream's new check makes it moot

**Claim.** Record §0.12: the D13 run point in the constant-expression path "must stay a pure `error`,
undiscardable — re-measured with the witness inside a case label and an array bound". Neither §1.5, §2b.5 nor
§4 records that measurement; `scripts/check_compound_assignment_refusal.sh` has no such witness
(`w_*` names are all expression-level).

**Evidence.** `probes.log` p15 (`switch (1) { case (i += 1, 1): … }`): fork oracle and pristine `c3ff8c53f`
both report `constraint violation: expression is not an integer constant expression` (upstream 97371d8ed, before
elaboration; the old base crashed in `gentpying.annotate_expression`); Lean: `desugaring failed at …:3:21-32`.
The refusal is no longer reachable from a case label; that is fine, but it is a measured fact the record should
state (and the D13 record's "mini_pipeline.lem:181 … would discard a recorded error" rationale now rests on the
remaining mini-run entries only).

**Fix.** One sentence in the record (§1.5 or §4.9) with the p15 observation; optionally a control row in the
witness script.

### P3 — Doc accuracy nits

- `lean_frontend/docs/2026-10-30_consumer-note-cerberus-sl-merge-base-bump-stage1.md` (N4 bullet) names the lane
  class `LOCATION-ONLY`; the lanes, VALIDATION N4 and SUPPORTED say `LOC_ONLY` / `LOC_ONLY-FIRST`. Rename.
- Record §2.1 / `CerberusImpl.lean:626`: "upstream's global is EMPTY (`Pmap.find` Not_found)" → it is UNSET
  (`Failure("Tags definitions must be set …")`); folded into P1 item 3.
- Tray 67's title/scope should say the window has two halves (mini-run tag map; desugar-time `alignof` union
  arm) — folded into P1 item 1.

## What held up (checked, no finding)

- **The 13 resolutions vs rules R1–R5** (hot files read against both parents): `mini_pipeline.lem` — fork's
  `sup top` before upstream's `elab_conf` (R1), `evalIntegerConstantExpression[_seeded]` returns `(n, sup')`,
  upstream's `eval_mode`/`Loc.locOf d_expr`/`runElabM … (elab_initial_state sup)` (R2/R3), `Symbol.digest ()`,
  the five seeds incl. `typecheckAil_promoted_seeded`; `implementation.lem` — the E-A block verbatim, upstream's
  two vals with Lean reps and `reader_consumer` only (the merge commit carried `fuel_consumer` declares that M2
  removed; the record says so, HEAD is consistent); `cabs_to_ail_effect.lem` — `initial_state sup top desug_conf`,
  `eval` returning the triple, upstream's real `(loc, StructDef/UnionDef)` map in `get_alignof` with the fork's
  seed; `translation.lem` — `while_`/`do_`/`case_`/`default_` mints as `E.fresh_elab_*` at upstream's chain
  positions, `E.mapM` over `found_cases` in list order (R4), `translate sup … conf …` returning `(file, supply)`,
  D13 walker gains `AilElabel_addressGNU -> false`, declares renamed to `collect_switch_content_aux`;
  `translation_effect.lem` — upstream's `elab_config`/function-typed `elabM` with the fork's `fresh_supply` field
  and `elab_initial_state seed`, the fold in `with_block_objects` threads `fresh_elab_int conf stx`; the dead
  `push_block_objects`/`pop_block_objects` deleted (verified: no caller in `frontend`, `backend`,
  `lean_frontend/*.lean`, `lean_frontend/test`); `core_typing.lem` — upstream's `ArityMismatchRun` for `Erun`,
  the fork's tray-45 guards elsewhere (R3); `mem.lem` — `sizeof_ival`/`alignof_ival` gone, `offsetof_ival` rep kept.
  Nothing fork-own survives where upstream's text should have replaced it; no mechanism lost.
- **S1 mirror**: `CerberusImpl.lean:380-610` is the moved block with upstream cites; the reps (`:628-632`) are the
  one-map wrappers (fuel-free, explicit map). The two-map asymmetry IS the P1 above; otherwise faithful. The moved
  carrier is a namespace rename: every deleted line of the old `CerbMem_lemMeasureProofs.lean` reappears
  (`CerbMem.`→`CerberusImpl.`) and the new file adds only its header, four imports, `namespace`/`end` and
  `set_option autoImplicit false` (`old_carrier.txt`/`new_carrier.txt`, `comm`).
- **S2**: `arrayShiftPtrval` (`CerbMem.lean:1671-1694`) = `impl_mem.ml:2026-2044` arm for arm (Prov_symbolic
  refusal kept inside the `Undefined.t` body; null and function pointer `.Undef loc [UB046]`; concrete
  `.Defined`); `memcpyM` lifts dst then src through `lift_undef` (`:2459-2460` order), loads/stores at `loc`;
  `memcmpM` loads at `loc` and lifts the unit shift (`:2477`). Probes (fork / pristine-cut / Lean all agree; old
  base in brackets): null shift `UB046 <3:12--3:17>` [crash]; `NULL + 0` `UB046` [crash]; function-pointer cast
  shift `Error MerrOther isWellAligned_ptrval` (dies earlier, same on all); `memcpy(NULL, …)` `UB046 <4:3--4:27>`
  [crash]; `memcmp(a, NULL, 2)` `UB019 <4:10--4:34>` [`<unknown location>`]; `memcmp` out of bounds
  `UB_CERB002a <5:10--5:25>` [`<unknown location>`]; `memcpy` from a function pointer `UB_CERB002a` (all four).
- **The backport**: `mini_pipeline.lem:194,204` = 736690a65's two mini_pipeline lines (`core_tagDefs` binding
  and `C.tagDefs= core_tagDefs`; the record says "one line" — the binding line is the same hunk, fine). Regression
  reproduced: p10 (`char buf[sizeof(struct S)]`) pristine `c3ff8c53f` `Not_found` at `offsetsof :439`, old base
  16, fork 16, Lean 16. The pristine-register row (`minimal/106`) and tray 67 match this.
- **The restatement** (`formatted.lem:802-824` vs upstream `:760-782`): the list moves from a trailing `function`
  to an explicit parameter; `loc` is `Loc.other "…"` (pure), every caller applies all three arguments, so the
  shapes are extensionally identical; the generated delta is exactly the 12 lines (comment + header + `match cs
  with`), as the manifest NOTE says; the `.(fun)` frame-name difference is the registered digit9 row.
- **LOC_ONLY**: `test_libc_exec.sh:81-104` admits a pair only if identical after stripping `loc`, every Lean
  `loc` is `<unknown location>`, no oracle one is, and a dated line for THAT row exists in
  `tests/libc_exec/dispositions.txt` (else DIFF, with a stderr line); `inner_arg_temps_lane.py:116-133` is the
  same predicate per token line. Both selftests plant the accepted pair and the rejected neighbours (record
  §2d, lines quoted). Baseline row `016-strstr-twoway-oob LOC_ONLY` with the disposition. VALIDATION N4 and
  SUPPORTED state the limitation plainly (oracle's location is the reference; one row; remover queued). Narrow,
  fail-closed, honest. The mechanism is confirmed in nolibc mode by the memcmp probes (locations now carried on
  both engines; Lean's libc transport is the only path without them).
- **Refusals**: D11/D12/D13 (p12/p13/p14) fire on both engines with byte-identical texts (oracle
  `Failure("internal error: …")` exit 125; Lean `PANIC … failwithI` with the same string); the GNU label address
  refuses on both in matched mode (`use of GNU address-of-label extension (try --permissive)` / Lean
  `desugaring failed at …:2:22-27`); upstream's refused switch is expected by `check_cli_refusals.sh:86`;
  `Main.lean:813-819` `elabConf` mirrors `pipeline.ml:726-737` field by field.
- **Upstream commits verified end to end** (old base in brackets): 0fc82e266 casts in ICE — 9 on fork/pristine/Lean
  [refused "cast operator in integer constant expressions"]; cee382443 — `if (x)` on an unspecified `x` is
  `UB_CERB004_unspecified__if` on all three [two executions], `switch` likewise `__switch` [UB036];
  97371d8ed — non-constant case label is a constraint violation on both [crash]; 3230aa494 — `_Bool b = 0.5` is 1
  on all three [0]; 766073467 — `2.5 * 2.0` 5 everywhere (R6 was unreachable, as VALIDATION says);
  83f9cc641 — `return f();` in a void function is a constraint violation on both in matched mode; f4a3a3d54 and
  b3e11ea33 as above (the latter is the P1 window).
- **Manifest re-derivation**: `translation_aux.ml` 0 differing lines (LEFT, as claimed), `formatted.ml` 12
  (ENTERED, the restatement), `mini_pipeline.ml` carries the backport, `ctype.ml` one blank line (cosmetic);
  86 generated files in the scratch pristine tree. NOTE block matches what I diffed.
- **Kernel replay**: my own `leanchecker` over `CerberusImpl_lemMeasureProofs CerberusImpl CerbMem
  Translation_lemMeasureProofs Defacto_memory_lemMeasureProofs` → exit 0 (the record's 17-module run quoted exit
  0; I did not repeat all 17).
- **Baseline rows**: 097/0120/0121 (null shift → `UB046`) and `ts-fmt-s-null` are f4a3a3d54 as cited (reproduced
  by p01/p03/p20); `zd-ta-alignas-huge-*` → b3e11ea33 as cited (the `Z.to_int` reads are gone from the cut's
  `alignof`, read); `s4b-memcmp-hugesize` loc token → f4a3a3d54 (memcmp loads at `loc`, reproduced by p21);
  tray closures 01/04/15/33 and the open 67 consistent with the INDEX; forecast misses (B5, A5/float-literal
  register) recorded in §0.9 and §5b as misses.

## Residual uncertainty

- I did not run any lane script or the battery (constraint); A1/Tier B/C greens rest on the record's quoted lines
  and the orchestrator's running battery. I replayed 5 of the 17 modules through `leanchecker`.
- The libc-mode Lean path (N4) was not exercised by me (the Lean `--libc` run needs the 12 metadata TUs from
  `libc_prep.sh --jsons`, a lane helper); I verified the mechanism in nolibc mode and read the classifiers.
- The P1 shapes I found are the ones reachable through `get_alignof`'s two callers; I did not enumerate every other
  desugar-time path into `Implementation.alignof_ty` (there is none in `frontend/model` besides the seed — `git
  grep`), nor elaboration-time ones beyond `offsetof` (P2).
- The two-map union arms vs upstream's half-moved arms at RUN time (both maps = the Core file's table) I argued
  from the code, not by a dedicated probe beyond p17 (`_Alignof(union U)` in an array bound: 8 on all engines).

---

## Dispositions (added by the arc's worker at the close-out, 2026-10-30 [AGENT]; the record's §6.6.2 is the same table)

| finding | disposition |
|---|---|
| P1 | FIXED by the ruling [USER 2026-10-30] (option 1): 736690a65's alignof line carried ahead with the one-call Lean mirror (`CerbMem.offsetofIval`); the three shapes pinned `MATCH` in the immaculate lane, `offsetof-union-member` `MATCH | L=VAL Specified(0)`; four `shared-model-fix` register rows; manifest NOTE (1), tray 67, TODO, VALIDATION moved; the record's §2.1 claim corrected inline (M6b, M6c — `docs/2026-10-29_merge-base-bump-stage1-record.md` §6b, §6c) |
| P2 | FIXED: `CerbStopSites.sizeofUnion` re-cited (M6b) and, with every call one-map, back to upstream's `:501-504` (M6c); register row 75's reason rewritten and its reach `UNREACHABLE-BY-INVARIANT`, resealed |
| P3 (D13 re-measure) | FIXED: recorded with a five-engine re-measurement (record §6b.1) |
| P3 (class name) | FIXED: `LOC_ONLY` / `LOC_ONLY-FIRST` in the cerberus-sl note |
| Residual uncertainties | answered in the record §6.6.2 (the battery; the libc lanes; the enumerated paths into the layout family; the two-map question moot after M6c) |
