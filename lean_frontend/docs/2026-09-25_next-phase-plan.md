# Next-phase plan — quality of life, defect fixes, extending usefulness (2026-09-25)

> **READ §11 FIRST (2026-09-27).** §11 is the CURRENT sequence, status and
> decision set; it supersedes the phase order of §3, the decision rows of §6
> and the rulings table of §10 wherever they differ. §3 remains the item
> catalogue (descriptions, sources, prices unless §11 re-prices them). Do not
> brief a worker from a §3 or §6 row without checking §11.

STATUS: PROPOSAL for operator discussion, prepared by the orchestrator [AGENT],
revised once after an independent adversarial review (§7). Not a charter.
Nothing below is ruled; every item that changes a ruling, a shared-model
definition or the consumer-visible surface is listed in §6 as an operator
decision. Prices are S/M/L at the project's measured hot factor, the sizing
used by the dated records; they are estimates, not measurements.

Commissioned [USER 2026-09-25], verbatim: "We just cut a release for
cerberus-lean and lem-lean. Can you do a planning pass for the next phase of
work. Note that we have pending concurrency support so we'll want to avoid that
in our plans. Instead we want to work on QoL improvements pending defect fixes,
extending usefulness. Review the whole project (and lem-lean) and propose a
sequence of work from here. Note the final release process is still running but
we don't expect substantial technical changes on main". Then: "Let's write all
this up as a detailed plan, then send a subagent to evaluate and critique it".

Grounded against (read 2026-09-25):

- cerberus-lean `mdd/cerberus-lean` @ `683dc186c` (the fresh-clone-fix landing,
  which moved the mainline from `db5e1feb5` while this plan was under review);
  lem-lean `mdd/lean-backend` @ `c2a68e7`; `deps/lem-pinned` = `c2a68e7`; every
  cerberus pin site = `c2a68e79…`. No release tag exists in either repository
  yet; the candidate names are `cerberus-lean-v0.1.0-alpha.1` and
  `lean-backend-v0.1.0-alpha.1` ([follow-up record](2026-09-25_public-readiness-followup.md)).
- `TODO.md`, `SUPPORTED.md`, `VALIDATION.md` §2/§3/§5/§9, `DESIGN.md`,
  `README.md`, `CLAUDE.md`, `scripts/LADDER.md`, the
  [forward assessment](2026-08-31_semantics-forward-assessment.md), the
  public-readiness records (2026-09-24/25), lem-lean `doc/lean-backend/TODO.md`
  and its 2026-09-25 follow-up and review, `docs/upstream-tray/INDEX.md`.
- cerberus-sl at `/home/dev/projects/cerberus-sl`, pin `2b51d2a57`
  (`scripts/semantics-pin.env:26`), LemLib rev `38f87d5` in its Lake manifests,
  its `docs/2026-09-18_hidden-state-upstream-note.md` and
  `Corpus/Capture/Pipeline.lean`.
- Three read-only surveys run the same day (consumer needs; cerberus-lean
  tooling/validation; lem-lean backend), then the adversarial review of the
  first draft (§7). Facts taken from a survey and not re-read by the
  orchestrator are marked **[survey]**; everything else was read first-hand or
  re-verified during the review. Derived counts are labelled derived.

## 0. Scope, exclusions, and the release freeze

**In scope.** Three buckets, in the operator's words: quality-of-life
improvements, pending defect fixes, extending usefulness. Both repositories.
The consumer (cerberus-sl) is a first-class beneficiary.

**Out of scope.**

- Concurrency, under the standing ruling [USER 2026-09-24] quoted in `TODO.md`:
  "FYI, I have concluded the concurrency branch prototype has failed, and I'm
  working on a remediation. But that dependency should be considered dead for
  now." The SC recovery plan, `arc/sc-wp0` and its two audits are a separate,
  operator-owned track; the pending WP0 landing sign-off is NOT a step of this
  plan and nothing here depends on it. One Phase 4 item (the upstream re-sync)
  necessarily touches the concurrency SURFACE (`cmm_csem.lem`'s
  `LemUnsupported.Cmm.*` markers must be re-applied over upstream's changes);
  it is flagged there.
- The verification layer. The semantics is the product; reasoning lives in
  cerberus-sl. Two items that would produce theorems about the semantics'
  own hypotheses (P2b-4, the `driver_globals` determinism lemma in P2b-5) are
  therefore NOT scheduled: they sit in §6 Q12 and proceed only on an explicit
  operator yes, under the standing [USER 2026-09-08] "nothing new out of
  policy" rule.
- Anything landing on either mainline while `release.py --mode full` and the
  tagging are in progress. Phase 0 is branch-only work.

**What this plan is not.** Not a claim about the release's certification, not a
re-adjudication of any [USER] ruling (candidates that touch a ruling are
listed as decisions, §6), not a schedule with dates. The grind ban, the
two-tier gate practice, the per-merge audit ask and the memory cap on every
Lean invocation apply to every slice below unchanged.

## 1. Where things stand — findings

### 1.1 The release heads carried a wrong install pin — found twice, landed once

At `db5e1feb5` (the sweep landing) `lean_frontend/README.md:93` pinned lem-lean
at `67ec5de…` while `lakefile.toml:70`, the three `lake-manifest.json` files
and `scripts/fork_drift_manifest.txt`'s `lem-pin` were `c2a68e79…`; the
README's own line 92 says the two must be equal. `check_fork_drift.sh:164-186`
prefix-compares `lem -v` against the manifest pin, so a newcomer following the
README got a red row 1 on an otherwise working build (the two lem commits
generate byte-identical trees). This plan's first draft reported it as F-0.

The release overseer found the same defect independently through the M9
fresh-clone exercise and landed the fix while this plan was under review:
`mdd/cerberus-lean` `db5e1feb5` → `683dc186c` ([USER 2026-09-25] "Great, agree
on the reviewer, agree on the merge, agree on M9 exit"), carrying the README
pin at `c2a68e79…`, a fork-drift merge-base diff fix, and a new row-1 leg
`scripts/check_pin_sites.sh` (the lem-lean pin is ONE value at the manifest
`lem-pin`, the Lake rev, the three lake-manifests and the README's `opam pin`
command; 8 plants, fail-closed — `CLAUDE.md:146`, `LADDER.md:43`). Nothing
remains for this plan except P0-1's verification at the tag.

Residual, docs only: the front documents' "documentation check" headers still
name Lem `67ec5de` as the checked revision (`README.md:4`, `SUPPORTED.md:3`,
`TODO.md:9-10`, `VALIDATION.md`); `CLAUDE.md:5` now carries the clarifying
"the pinned Lem mainline is `c2a68e7…`, ahead of the checked revision by
comments and records only". P1e-5 makes the other four say the same or drop
the hash. (Correction from the first draft: the sweep commit `ab6522db8`
changed ONE line of `lean_frontend/README.md`, not two; and lem-lean's
`lean-lib/NOTICE.md` did change between `67ec5de` and `c2a68e7` — +2 lines, the
sweep's T3 maintainer-confirmation line — so the README's NOTICE link at the
`67ec5de` blob is one revision behind; `LICENSE` is unchanged.)

### 1.2 Open defects by the zero-discrepancy rule

The standing list (`VALIDATION.md` §3 "Still open" + `TODO.md`), all with named
movers. One row was found RESOLVED-but-unrecorded during the review.

| ID | Defect | Where | Mover shape | Price |
|---|---|---|---|---|
| D-1 | libc-body UB carries `<unknown location>` on Lean, the libc source location on the oracle (Z1-A1) | `VALIDATION.md` §3 | a libc pin vehicle that carries locations (the `--libc` pin is the oracle's Core TEXT dump) | M |
| D-2 | `aligned_alloc(0, n)`: oracle `Division_by_zero` (kind-2), Lean `DUMMY(align_alloc)` / loud refusal, neither principled (Z2-M-01) | `VALIDATION.md` §3; tray 34 | operator decision on the logical meaning; shared-model change (`std.core:385` guard and/or Core UB045) | S once ruled |
| D-3 | Union twin of the cross-TU compatibility fix: `PEmemberof(union)` and `memValueFromValue`'s union arm keep exact tag identity | `TODO.md` "Union twin" (charter §8 item 7) | the same `are_compatible` consult at both sites; shared-model change, own charter | S–M, operator sign-off |
| D-4 | ~~`cerberus-lean --batch --fuel N a.json b.json` refused as `unknown flag` (F-A8)~~ — **RESOLVED, TODO row stale.** Reproduced at `683dc186c` (review F6): `Main.lean:1295-1316`'s argument loop matches `"--fuel" :: v :: rest` at any position; run verbatim below. | `TODO.md` C4 follow-ups | retire the row (P1e-2) | — |
| D-5 | `test_elab.sh`'s 3 recorded DIFF rows: `Main.ppCoreSignature` does not mirror `pp_cond` (Z-40) | `VALIDATION.md` §3 "Instruments, not semantics" | mirror the filter | S |
| D-6 | 9 csmith `TIMEOUT` rows + 11 gcc-lane `SKIP_LEAN_TIMEOUT` rows are class-(b) VIOLATIONS pending one measured completion each | `VALIDATION.md` §3(b) | measure once on a quiet box, record per row | S each (measurement) |
| D-7 | Non-UTF-8 bytes in a TEXT field of the Cabs JSON make the bridge REFUSE where the oracle proceeds | `VALIDATION.md` §3(b); `TODO.md` F3 residual | an encoder decision for text fields (`cabs_json.ml:600/602/657`, an OCaml exporter file, not `.lem`) | S |
| D-8 | `_Alignas` member alignment ignored by `are_compatible_aux` (`ctype_aux.lem:141` `(*TODO alignment*)`); frontend gap F-A2 (`_Alignas(type)` on a char member bypasses completeness) | `TODO.md` 2026-09-15 follow-ups (a); C4 audit F-A2 | shared-model fixes, same class as draft 39; tray drafts first | S draft / operator decision |
| D-9 | The committed `tests/ci_sweep/results/*.tsv` hold the 2026-08-22 run's CONTENT (last touched by the 2026-09-02 mem-scale instrument commit `de574fbc8`); the 2026-09-06 re-record lives in a docs evidence directory only (Z-42/Z-75) | `VALIDATION.md` §3 | adopt or label; instrument commit | S |
| D-10 | The gcc lane records oracle-suspect rows as `TRIAGED_*`; the `PINNED_TRAY_<n>` class (charter §4.2) is owed | `VALIDATION.md` §3 | classifier + ledger change | S |
| D-11 | R3 has no `-- ISO-fix register R3` marker in `CerbMem.lean`; the register↔marker bijection check is owed (charter §1.4 (vii)) | `VALIDATION.md` §2 | marker + check | S |

D-4's reproduction (orchestrator, 2026-09-25, primary checkout at `683dc186c`,
`tests/multi_tu/basic/tu{1,2}.c` bridged with `scripts/cerberus --cabs-json`):

```text
$ LEAN_ABORT_ON_PANIC=1 .lake/build/bin/cerberus-lean --batch --fuel 100000000 tu1.json tu2.json
EXECUTION 0:
Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
… (31 executions, all identical to the run without --fuel)
rc=0
```

Resource-class violations with structural movers are in §1.4.

### 1.3 The consumer's friction is packaging, not semantics **[survey; every site cited below was re-read by the orchestrator or the reviewer]**

cerberus-sl's four Lake packages `require CerberusLean` by path
(`../.cerberus-ws/lean_frontend`), sharing one `packagesDir`; their LemLib rev
is `38f87d5` (behind the current `c2a68e7`, so every re-pin they take is a
TWO-pin move). What it imports: `CerbMem`, `Core*`, `CerbND`, `Driver`,
`CerberusFresh`, the `*_lemMeasureProofs` modules, `CerbMemAllocatorProofs`,
`CerbGlobal`, `CerbLocation`, `CerbUtils`, `CerberusImpl`, `LemLibTheorems`,
`LemLibPmapLaws`; its capture tool also imports the frontend (`Cabs_to_ail`,
`GenTyping`, `Translation`, `CoreParser`, `CabsImport`, …). Its endpoint
statement is `runNDFuel n (drive … (convert_file F) …) (initial_driver_state supply top digest (convert_file F) CerbFS.fs_initial_state)`.

Friction:

- **It cannot `import Main`**, so `Corpus/Capture/Pipeline.lean:14-32` copies
  `loadCoreStdlib`, `loadCoreImpl`, the success path of `frontendTU`, the link
  fold, `runDigest` and `defaultAddressSpaceTop` "replicated verbatim … kept
  identical to the pin by reading". Its header mirrors `Main.lean @ 34ac493f9`,
  the INTERIM pin, while `semantics-pin.env:26` is `2b51d2a57`: the copy is
  already one pin behind its own header (review F10). Every pipeline change we
  make is a silent drift risk for them.
- **It links `native/md5.o` by hand**: `moreLinkArgs =
  ["../.cerberus-ws/lean_frontend/native/md5.o"]` on every executable
  (`Corpus/lakefile.toml:34,40,46`).
- **A plain clone is not buildable**: `srcDir = "generated"` and
  `lean_frontend/generated` is gitignored (`.gitignore:22`; `git ls-files` = 0),
  so a Lake `require` by git URL cannot build. Their `setup-cerberus-dep.sh`
  copies `generated/`, `native/` and `.lake` from the shared checkout and
  re-patches the 49 hand-written seams (`handwritten_copy.manifest` at the pin,
  non-comment lines = 49) to the pinned versions.
- **Requests still open** from `docs/2026-09-18_hidden-state-upstream-note.md`,
  read at the cited lines: item 4 (`:86-100`) asks for STRUCTURED
  CONSTRUCTORS — `MerrOutOfMemory` in `mem_error` (shared-model:
  `mem_common.lem`, `impl_mem.ml`, `CerbMem`), and "if cheap"
  `kill_reason.FuelExhausted` / `ModelFailStop : String → kill_reason` in place
  of `Error0 <opaque Loc> msg` — only the interim `CerbMem.oomKill` def exists;
  item 5 (the configuration as a reader parameter; the switch arms are explicit
  `if has_switch … then … else …` since seam-hygiene H2 but the parameter is
  not); item 8 (a `WFfile` well-formedness predicate, "not urgent"); item 9
  (`:146-153`) asks that `bounded_integer` be "an ND choice in `ndM`, never a
  pure function returning `lo` (a rule proving it returns `lo` would be unsound
  against the oracle's random draw)" and names `dynamicAddrs` never pruned
  (tray 19 / R4 DEFERRED). Items 1, 2, 3, 6, 7 are landed.
- **Consumer-side observations we can make cheaper** **[survey]**: no Core
  quoting facility (they derive `Repr` across the AST by hand); their coverage
  matrix lists UNVERIFIED elaboration shapes that "need a frontend run to
  settle" (37 lines in `docs/2026-09-24_coverage-matrix.md` per the reviewer)
  — the Lean driver's `--pp-core` answers this but no one-liner is documented;
  "multiple translation units: unverified whether the Lean pipeline links
  them" — it does (`test_multi_tu.sh`), a documentation gap.
- **Re-pin state**: pin `2b51d2a57` (2026-09-23 mainline with the matcher fix);
  178 mainline commits since their original `679181d1b`; the 2026-09-25 consumer
  note recommends ONE re-pin at the announcement tag. Their semantics build is
  "once per pin", the last incremental one 54 modules in 46 s **[survey]**.

### 1.4 The scale ceiling — the largest usefulness limiter

All registered, all class (b) with movers, none a stack-size knob (registered
defect shape, [USER 2026-09-02]):

- **Zero-initialised aggregates above ~8×10^6 elements HANG** (exit 124, CPU
  < 0.1 s): the Lean 4.32.2 runtime enters closures by indirect CALL in
  `lean_apply_*` on 22 of 24 arity paths, one frame per element in a
  function-typed monad's run loop, plus the overflow-handler deadlock (tray
  `lean4/01`). Movers: lem-lean TODO row 1 (run-loop rendering of
  `mapM`/`sequence`/`foldrM` for function-typed monads — class 0, Lean-emission
  only, "needs its own ruling before dispatch") and the upstream `.lem`
  accumulate-and-reverse shape (tray 18; built, measured, REVERTED [USER
  2026-09-02] as "poor roi for a change to the trust surface"). The standing
  [AGENT 2026-09-02] Q5 ruling preferred the `.lem` route with the lem-backend
  route as "FALLBACK CANDIDATE"; the user's revert closed the `.lem` route, so
  the fallback is the only open one — and its rendering is NOT designed.
- **Loop shapes between 10^5 and 10^6 iterations die on the native stack**
  (`d_loop_1000000.c`, `e_memcpy_1000000.c`: exit 134 / 124 handler park) at
  the default fuel 10^8 (`TODO.md` "Step-runner execution ceiling").
  `docs/2026-08-31_stack-ceiling-design.md` is **PARKED** ("the registered
  premise is stale": at its mainline the binding ceiling was the 10^6 fuel
  budget); since the fuel-parameter arc the process stack binds AGAIN. There is
  no current design for an iterative or trampolined step runner; the forward
  assessment's F6.1 names the route, not a design.
- **Front-end `mkListN` ceiling**: a 10^6-element zero-initialised local
  aggregate exhausts fuel in `mkListN_aux_lemFuel` (a pure-return-worker
  PANIC); evidence for a per-declaration budget, "a ruling item, not applied".
- **Byte-list memory representation** materialises large untouched allocations
  (`array.c` OOM panic, `pr20621-1.c`, `mem_malloc_4gb_lazy.c` OOM-KILLED at
  6 G); mover: chunked/sparse bytes in `CerbMem` "profile first".
- **Speed**: ~15–20× slower than the oracle on recursion-heavy shapes in
  exhaustive mode (`VALIDATION.md` §3(b)); 1.4–1.5× on a single trace
  **[survey, mem-scale profile]**. Fuel-measure overhead 7.5%/7.3% paired CPU on
  the 369/371 rows against the operator's <10% price; `sia_csmith_078`'s spike
  unreproduced, `sa_csmith_419` still over 15 s (`TODO.md` C3 follow-ups). No
  Lean-vs-oracle benchmark number is published (forward assessment F6.7).

### 1.5 Hygiene debt

- **Docs**: `lean_frontend/docs/` has 289 entries (255 files + ~33 evidence
  directories), 48 MB, ~40 MB of it tracked non-markdown evidence across
  ~1,078 files (derived; the first draft's 41 MB / 1,101 were the same
  measurement rounded differently), and NO index or README (only the upstream
  tray has one). The 2026-09-24 untracking covered `*.tar.gz` only. lem-lean's
  review N1 asks for the same current/history index on its side.
- **TODO.md** is 745 lines of prose, mixing RESOLVED history with open rows,
  and carries at least two stale rows found in this pass (D-4 above; the
  comment-only `lemDefaultFuel` row, §3 Slice 2c); lem-lean's `TODO.md` is a
  22-row register table and is the better shape. Front-doc counts go stale by
  hand (`TODO.md` (d)).
- **Branches/worktrees**: at the 2026-09-25 inventory, cerberus 53 branches /
  22 worktrees, lem 14 / 7 (deletions "operator-only"); live counts today are
  higher (cerberus 63 / 26, lem 15 / 4 per the reviewer) as the release work
  adds review branches; a stray `wip/fuel-parameter-C1-scratch` branch; three
  `upstream-pr/*` worktrees whose patches are Draft in the tray.
- **Driver CLI**: no `--help` (usage appears only on bad input, in two
  disagreeing strings, `Main.lean:275` and `:1430`); no exit-code table; the
  runtime directory is found by probing three relative paths with no override
  (`Main.lean:476-486`); the non-batch path exits 0 after "linking failed!"
  (`Main.lean:1012-1015`) and after Killed executions (`:1157`); no documented
  one-liner from a `.c` file to a verdict (the README's only run path is the
  differential harness; the `CLAUDE.md` two-step omits `LEAN_ABORT_ON_PANIC=1`
  and is refused as written, `Main.lean:1224-1230`).
- **Rituals**: provisioning the fork-drift oracle is a 9-command manual recipe
  (`VALIDATION.md` "Provisioning the fork-drift oracle"), and the first
  post-landing row 1 on the primary checkout was red for exactly the missing
  `CERB_UPSTREAM_TREE`; the pristine oracle is separate provisioning; sharded
  csmith campaigns (K=1..6, K=1..34) are run by hand; baseline re-records are
  by-hand instrument commits; the README's "small set" of seven commands is not
  a `release.py` preset. One locale-dependent order remains
  (`test_csmith_corpus.sh:72` `find | sort`; the `LC_ALL=en_US.utf8` in the
  recorded row-1 command is the S6 plant proving locale-independence, not a
  dependency — corrected from the first draft).
- **Build**: 7 build steps after a 4-step opam setup; `make lean-build`
  (`Makefile:380-384`) exists, runs `lake build` under `scripts/capped`, and is
  not the documented path (the first draft wrongly called it uncapped);
  `build_lean` refuses on a stale hand-written copy rather than syncing;
  `md5.o` has no automatic rebuild; stale untracked
  `native/{debug,fresh_int,tags}.o` from 2026-08-22 with no source sit in the
  tree and are hashed by `tools/check_driver_fresh.sh:114`; `generated/`
  regeneration does not wipe first (fail-open shape, `TODO.md` "Regeneration
  recipe"); the Lake package SET is unpinned (`TODO.md`).
- **No Lean CI** on either public repository (public-readiness S3; the
  inherited workflows cover upstream OCaml/CHERI). The evidence is dated manual
  records. A hosted runner cannot honour the 32 G caps.

### 1.6 lem-lean state **[survey; counts re-verified where marked]**

- Generated cerberus tree: 219 files, 58,306 lines (verified). Zero `set_option
  maxHeartbeats`/`maxRecDepth`, zero `axiom`, zero `native_decide`, zero
  `noncomputable` (verified). 302 line-anchored `partial def` in 32 files, all
  outside the exec cone (`check_exec_totality.sh`'s allowlist is empty;
  "frontend partiality remains", `SUPPORTED.md`).
- **Defect, undocumented until this pass**: `§` in `.lem` comments is emitted
  as `Â§` — 470 occurrences in 24 generated Lean files and 29 OCaml generated
  files (verified). It is an UPSTREAM Lem defect: the pristine oracle tree
  (built with upstream Lem `3802cb0`,
  `.validation-foundations/independent-oracle-v2/cerberus/ocaml_frontend/generated/`)
  has it in 28 files, and the root cause is the lexer — `lem-lean/src/lexer.mll:61`
  `let r = Ulib.Text.of_latin1` with comment tokens built through it (UTF-8
  bytes read as Latin-1, re-emitted as UTF-8); the fork's diff to `lexer.mll` is
  the keyword table only. (The first draft inferred "upstream too" from the
  fork-drift byte-identity, which is unsound because the fork-drift oracle tree
  is generated with the FORK's lem — review F1; the conclusion stands on the
  pristine-tree evidence.) A fork fix would move OCaml text in ~29 files and
  multiply fork-drift pins; the right vehicle is a tray report
  (`docs/upstream-tray/lem/`) and an upstream-first fix.
- **Readability**: whole definitions on one line; `Translation.lean:509` is
  104,493 characters (verified); 353 lines over 1,000 characters (verified); no
  `.lem` line references in the output. The consumer reads generated code to
  mirror step equations (~6,268 lines of hand-written mirrors in `Lang.lean` +
  `Round*.lean` **[survey]**).
- **Diagnostics**: 28 user-facing refusals are raised at `Ast.Unknown` (no
  source location; `grep -n err_general src/lean_backend.ml | grep -c
  Ast.Unknown` = 28, verified by the reviewer) — instance-method
  reader/fuel/supply, Inhabited, `Type 1` BEq/Ord, derived-Ord order; a
  measure/hypothesis mistake surfaces only as a Lean build error in the
  auxiliary file (TODO row 20, by design); the runtime fuel-exhaustion panic
  text "lem: fuel exhausted" names no function (the text is also the harness
  FUEL classifier's marker, so any change must keep the marker).
- **Toolchain split**: LemLib `lean-lib/lean-toolchain` = 4.28.0; cerberus =
  4.32.2 (verified). The 4.32 pairing is exercised only by cerberus. No written
  policy.
- **Backlog** (`doc/lean-backend/TODO.md`, a 22-row table): row 1 run-loop
  rendering (M, needs ruling); row 4 library-name entanglement (M, "the largest
  upstreamability friction"); row 6 effect-free emission (M); row 9 qualified
  constructor patterns instead of `One0` renames (M, consumer-visible); row 12
  well-founded LemLib recursions blocking kernel computation (S); row 13 fuel
  monotonicity (L both routes, operator decision, deferred); row 18
  declare-family consolidation (M) with [USER 2026-09-04] "definitely worth
  doing before we get to stable", sequenced "AFTER the cerberus fuel half
  (C1/C2) lands — no churn under the consumer's re-pin — and BEFORE the
  upstream lem submission" — both conditions are now met; the S notes m3
  (fail-open `add_avoid_type` `None`; the `output.ml` UTF-8 decode edit and two
  other shared-path edits), m8 (`mkdir -p` with ignored exit), m10 (LemLib
  residuals), row 3 (`ground_rep` probe), row 5 (Ott regeneration), row 7
  (OCaml `genlist` quadratic), row 8 (`real`/`float64` support decision), rows
  16, 20, 21, the possibly-dead multi-clause render path, output cosmetics.
- **String representation**: Lem strings are Lean Unicode scalars, OCaml's are
  bytes; the 2026-09-03 design ruled it "a BUG to fix", sized L, not
  implemented; two parity XFAILs (`p_str_bytes`, `p_str_escapes`). Cerberus's
  exec paths are byte-carriers by seam (C-TF1, `CerbEscape`), so this is a
  general-backend fidelity item, not a cerberus blocker.
- **Upstream relation**: 233 commits ahead of the locally cached `master`, 0
  behind; the cache was cloned 2026-08-18 and its `master` is dated 2026-06-09
  (UNVERIFIED-OFFLINE whether GitHub has moved); the diff is 479 files,
  +52,055/−265 lines (reviewer's measurement; the first draft quoted the
  2026-09-24 review's older 461 / +48,664); the stated intent is
  upstreamability (`README.md` "plausibly acceptable to rems-project/lem").

### 1.7 Upstream staleness and the operator's external exits

`deps/cerberus-upstream` and the fork's merge-base are `b9aeedcb4`, dated
2026-08-13 — six weeks at the time of writing. The forward assessment priced
the re-sync M and noted the renumbering machinery (`fork_renumber.ml` + three
ocaml-only target_reps) as the dominant rebase cost; six weeks of upstream on
top makes M–L the honest price. The tray holds 49 reports: 48 Draft, 0 Sent,
1 Filed (Cerberus #1009), 0 Closed (`INDEX.md:20`, derived 2026-09-25); three
prepared PR branches (`upstream-pr/{bswap64,char-escapes,pp-roundtrip}`). The
ISO-fix register's "filed upstream" criterion is unmet for every entry
(`VALIDATION.md` §2; orchestrator note §10 G5 — operator decision).

Operator-only external exits already recorded elsewhere and NOT this plan's
work: the M9 anonymous clone / fresh dependency-download checks and the
post-tag verification block (follow-up record); the GitHub "Issue creation is
restricted in this repository" banner on both repositories (orchestrator note
§10 A1; lem follow-up `:39-42`); the announcement wording.

## 2. Sequencing principles

1. **Trust-stability first.** Rank by gain × low trust impact: instruments,
   docs and Lean-only emission changes before any shared-model change; the
   reference model stays the obviously-right mirror of upstream's OCaml; any
   fast path is proven equal behind the interface, never an unproven executable
   substitute (the standing "no internal trust gaps" practice).
2. **One change at a time.** Each slice is exactly one of: instrument/gate,
   docs, Lean-only declare/emission change, hand-written seam mirror, OCaml
   exporter/harness change, or a RULED shared-model change. Never two kinds in
   one commit.
3. **Minimise consumer re-pins, and count them honestly.** Every
   generated-surface change (dead fuel binders, constructor renames, declare
   consolidation, line-broken emission, the run-loop rendering) is BUNDLED into
   the Phase 2 pin bump, with a generated-tree diff manifest in the consumer
   note. §4 states the resulting re-pin count. Every re-pin is a two-pin move
   for cerberus-sl (semantics commit + LemLib rev).
4. **Profile before optimising.** Phase 3 starts with numbers; no data-structure
   or representation change is dispatched without a profile that names it.
5. **Fail-closed shapes first among the S items.** The regeneration recipe's
   stamp-over-leftovers, the unpinned package set and lem-lean's m3/m8 are
   fail-open shapes and rank above cosmetic items by house rule.
6. **Gates are for trust properties; everything else is a speedbump.**
   Documentation-consistency checks (derived counts, the docs index, the
   knob table) ship as `--check` modes run at claim points, not as row-1 gates.
   Census/register gates already owed by a charter (package set, ISO-fix
   marker bijection, `PINNED_TRAY`) are gates.
7. **Design passes are scoped WITH the operator before dispatch.** Items whose
   mechanism is understood but whose rendering or design does not exist (the
   run-loop rendering, the step-runner ceiling, the sparse memory
   representation) get a design note first; the plan schedules the note, not
   the implementation.
8. **Network-gated and L items last**, each behind its own charter and an
   explicit appetite decision (§6).
9. **The house practices are unchanged**: branches in worktrees, ff-only merges
   on per-merge sign-off, the pre-merge audit ask unconditional, FULL gate at
   claim points and labelled FAST-GATE between, gate tails recorded verbatim,
   the grind ban and the memory cap on every Lean invocation.

## 3. The sequence

Each item: ID · item · repo · price · trust impact (I = instrument/docs only;
E = Lean-only emission or seam, oracle byte-identical; C = consumer-visible
surface; M = shared-model, needs a [USER] ruling) · source. "Exit criteria" is
the phase's or slice's completion condition (the word "gate" is reserved for
the ladder's gates).

### Phase 0 — release freeze: branch-only preparation

Nothing lands on a mainline until the tags exist and the overseer declares the
release done. Everything here is prepared on branches in `worktrees/`.

| ID | Item | Repo | Price | Impact | Source |
|---|---|---|---|---|---|
| P0-1 | **Pin-site verification at the tag**: F-0 is landed (`683dc186c`, `check_pin_sites.sh`); the only remaining step is to confirm, at the tagged commit, that the leg is in row 1 and green, and that the README's NOTICE/LICENSE links point at the tagged lem revision. No code. | cerberus | S | I | §1.1 |
| P0-2 | **Consumer note at the tag**: confirm to cerberus-sl the ONE re-pin at `cerberus-lean-v0.1.0-alpha.1` AND the LemLib rev move `38f87d5` → the tagged lem-lean commit (the `never_extract` runtime change applies to them); list what Phase 2 will change for them (§5); ask them to rank the open items 4/5/8/9 of their 2026-09-18 note. | cerberus (docs) | S | I | §1.3 |
| P0-3 | **Worktree/branch retirement proposal**: from the 2026-09-25 inventory plus the release-week additions, a list of finished `audit/*`, `cleanup/*`, `review/*`, `docs/*` worktrees and merged branches to remove; the operator deletes (§6 Q9). Parked records (`park/*` tags, `arc/segment-ladder`, `arc/t5-seal`, the concurrency branches) are never candidates. | both | S | I | §1.5 |
| P0-4 | **This plan** as a dated record on `docs/next-phase-plan-20260925` (based on `683dc186c`), merged ff-only after the release on the usual sign-off. | cerberus (docs) | S | I | — |

Exit criteria: none beyond P0-1's observation.

### Phase 1 — the debt basket (S items; five slices, no `.lem` edits, no shared-model change)

Order: 1a → 1b → 1c → 1d → 1e. Slice 1d (lem-lean) precedes any cerberus
slice that touches the generated tree (Phase 2) so its LemLib changes ride the
Phase 2 pin bump instead of forcing their own.

#### Slice 1a — cerberus-lean instruments and gates (fail-closed shapes first)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P1a-1 | **Wipe-then-regenerate** in `make lean-prelude-src` / `make prelude-src` (hand-written copies re-copied by the same recipe) so the lem-sync stamp covers exactly the recipe's output; plus a clean-build leg for orphaned `.lake/build` artifacts at boundaries. | S | I | `TODO.md` "Regeneration recipe" |
| P1a-2 | **Lake dependency-set pin gate** (owed, `TODO.md`): read all three `lake-manifest.json`, assert the package set equals a reviewed list, fail on non-manifest directories in the shared `packagesDir`. | S | I | `TODO.md` "Pin the Lake dependency SET" |
| P1a-3 | **R3 marker + register↔marker bijection check** (owed by charter §1.4 (vii)): `grep "ISO-fix register R"` vs the §2 table, both directions. | S | I | `VALIDATION.md` §2; D-11 |
| P1a-4 | **`PINNED_TRAY_<n>` class** in `test_gcc_oracle.sh` (owed by charter §4.2) for confirmed shared-source oracle bugs with a draft; the pin flips to AGREE on the upstream fix, any other movement is a regression. | S | I | D-10 |
| P1a-5 | **Raw-string awareness** in `check_theorem_axioms.sh`'s stripper, or a `r#"` ban probe. | S | I | `TODO.md` |
| P1a-6 | **Native-object hygiene**: `lean-native-obj` rebuilt by `build_lean` when `md5.c` is newer than `md5.o` (or the stamp names the `.c` hash); stale `native/*.o` for deleted sources deleted and excluded from the freshness stamp. | S | I | `TODO.md` "Driver-freshness stamp"; §1.5 |
| P1a-7 | **Freshness-stamp inputs**: exclude `Version` from the oracle link (or document it in `tools/check_driver_fresh.sh`) and record `deps/lem-pinned` HEAD in the oracle stamp. | S | I | `TODO.md` "Driver-freshness stamp" (a)/(b) |
| P1a-8 | **Derived counts** for `LADDER.md`, `VALIDATION.md` §5 and `SUPPORTED.md`: a generator reading the baseline files, with a `--check` mode run at claim points (a speedbump, not a row-1 gate — principle 6). | S | I | `TODO.md` (d) |
| P1a-9 | **Speclab leak checks' oracle-differential leg**: wire the oracle's `--batch-alloc-census` line into the speclab lanes. | S | I | `TODO.md` |
| P1a-10 | **Provisioning as commands**: `scripts/provision_fork_drift_oracle.sh` (the 9-step recipe; idempotent; refuses on a wrong merge-base) and a `release.py --mode smoke` preset for the README's seven-command set; both documented in VALIDATION/README. | S | I | §1.5 rituals |
| P1a-11 | **CI-sweep TSV adoption** (D-9): replace the 2026-08-22 content with the 2026-09-06 re-record or label the committed files historical in their header; one instrument commit. | S | I | `VALIDATION.md` §3 |
| P1a-12 | **Match-pattern audit leftovers as probes**: `equalInferred`'s tuple zip (`core_typing_aux.lem`), `to_pure`'s `Ecase`/`Esave` traversals — reported without a live counterexample; write the probes, fix only if one fires (a fix would be a shared-model change, Slice 2d). | S | I | `TODO.md` match-pattern closure (iv) |

Exit criteria: Tier A green (FAST-GATE label on intermediate commits); the new
gates' plant batteries red/green with tails recorded verbatim; Tier B at the
slice boundary. No baseline moves except P1a-11's dedicated instrument commit.

#### Slice 1b — driver CLI, bridge, and the printer mirror

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P1b-1 | **Driver CLI polish**: `--help` with one usage string; a documented exit-code table; a `--runtime-dir <path>` / `CERB_RUNTIME_DIR` override of the three-path probe; and a README "one C file to one verdict" recipe that sets `LEAN_ABORT_ON_PANIC=1`; the `CLAUDE.md` end-to-end commands corrected. | M (six sub-items) | E | §1.5 |
| P1b-2 | **Non-batch exit status**: exit nonzero after "linking failed!" and after Killed executions — AFTER checking what the oracle's `main.ml` human mode exits on the same runs (mirror-OCaml; a divergence is documented in-code as deliberate or not made). | S | E | `Main.lean:1012-1015`, `:1157` |
| P1b-3 | **`ppCoreSignature` mirrors `pp_cond`** (D-5); the 3 `test_elab.sh` DIFF rows retire in a dedicated instrument commit. | S | E | `VALIDATION.md` §3 |
| P1b-4 | **Text-field encoder** for the Cabs JSON (D-7): `json_of_bytes` at the three text sites of `cabs_json.ml`, or an explicit refusal with the reason; the bridge probe extended. An OCaml exporter change, not `.lem`; no oracle verdict moves. | S | E (exporter) | `VALIDATION.md` §3(b) |

Exit criteria: Tier A; `test_parse.sh`'s Unicode diagnostic probes; the
oracle's human-mode exit codes recorded beside the Lean ones in the record.

#### Slice 1c — measurements and tray drafting (no code)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P1c-1 | **D-6 measurements**: run the 9 csmith TIMEOUT and 11 gcc `SKIP_LEAN_TIMEOUT` rows once each on a quiet box with `uptime` recorded; per-row completion evidence into the record; re-records only with clear margin per the LADDER load caveat. | S | I | `VALIDATION.md` §3(b) |
| P1c-2 | **Tray drafts owed**: the sizeof/alignof-Union `Tags` GLOBAL crash ("NO TRAY DRAFT YET", `TODO.md`); the `_Alignas` alignment-specifier gap (D-8, draft 39's related observations); the `Â§` Lem lexer defect (`docs/upstream-tray/lem/02-…`, `lexer.mll:61`, reproducer); the F-A2 frontend gap. Drafting only. | S each | I | `TODO.md`; §1.6 |
| P1c-3 | **CerbFS served-pattern probe family** (read, rewind-reread, read-only reopen) under `tests/parity-probes/` with recorded verdicts. | S | I | `TODO.md` "CerbFS real-fs mover" (i) |
| P1c-4 | **Pinned tests for two implemented-but-untested semantics** (`_Bool` trap-representation UB; locking stores) and the **killed-not-UB inventory** as negative tests. | S | I | forward assessment F1.7/F1.8 |

Exit criteria: records committed; no baseline moves without a dedicated
instrument commit and margin evidence.

#### Slice 1d — lem-lean S items (before any cerberus generated-tree change)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P1d-1 | **Source locations on every refusal**: replace `Ast.Unknown` at the 28 user-facing `err_general` sites with the definition's location; message wording reviewed once. | M | I | §1.6 diagnostics |
| P1d-2 | **Fail-open shapes**: `target_trans.ml` `add_avoid_type` `None` → refusal; `process_file.ml` `mkdir -p` exit checked; the remaining m3 shared-path edits (`target_binding.ml` suffix fallback, `typed_ast_syntax.ml` class-path entities, `output.ml` UTF-8 decode) gated to the Lean target or justified in-code. | S | I | lem TODO m3/m8 |
| P1d-3 | **`ground_rep` supply-drawing-arguments probe** + the positive `tests/comprehensive` case; **the possibly-dead multi-clause render path** probed, then kept under test or deleted. | S | I | lem TODO row 3; notes |
| P1d-4 | **LemLib m10 residuals**: `int32Asr`/`int64Asr` positive-branch shift on the unnormalised value, `setSigmaBy` ignoring its comparator, dead `listGet?`/`listGet!`, duplicate `lemStringFromNatHelper`, one in-code class note for division-by-zero totalising to 0. Behaviour-affecting ones need the parity suite and ride the Phase 2 cerberus re-pin. | S | E | lem TODO m10 |
| P1d-5 | **Toolchain policy**: align `lean-lib/lean-toolchain` to 4.32.2 (the consumer's toolchain) and state the rule "LemLib builds on the largest consumer's toolchain; a bump is a pin-dance step". Decision §6 Q6. | S | I | §1.6 |
| P1d-6 | **Fuel-exhaustion message** names the worker while keeping the exact `lem: fuel exhausted` marker prefix the harness classifier reads (`scripts/fuel_classify.sh`); plant-tested on both sides. | S | E | §1.6 |
| P1d-7 | **Lem-side record errata** carried from cerberus (`TODO.md` "Lem-side record errata to carry to lem-lean": the 2026-09-03 parity-fix record §5's `CerbMem.lean:1352` claim, the "(22) now render through lemNatDiv" wording, the missed `Std.Data.TreeMap` import, `Utils.default0`). Docs only. | S | I | `TODO.md` |
| P1d-8 | **Ott regeneration residual** if the Ott tooling is available; otherwise recorded as still pending. | S | I | lem TODO row 5 |
| P1d-9 | **Output cosmetics** (double spaces, `(({ … } : T))`) — only if P2c-3's printer does not subsume them. | S | E | lem TODO notes |

Exit criteria: `make -C tests/comprehensive lean` + `make nonlean-regress`
green (the 505 s combined gate), the strict native parity probes; because
LemLib may change (P1d-4/5), a cerberus pin bump follows — bundled into Phase
2's, not its own (§4).

#### Slice 1e — docs and registers

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P1e-1 | **`docs/README.md` index** in both repositories: the current-facing documents (front docs, SUPPORTED, the standing registers) vs the dated history, one line per record, generated from filenames + first heading with a `--check` mode run at claim points (a speedbump). | S | I | §1.5; lem review N1 |
| P1e-2 | **TODO.md → register table** (the lem-lean shape: `# | item | source | price | owner/decision`), RESOLVED rows and the two stale rows found here (D-4; the `lemDefaultFuel` comment row) moved to a dated `todo-history-archive` record; every open row with an ID this plan can cite. | S | I | §1.5 |
| P1e-3 | **Evidence-tracking policy**: extend the 2026-09-24 tarball rule to large JSON/log evidence (a size threshold; the record keeps SHA-256 + the reproduction command, as the follow-up records already do); untrack-in-index only, no history rewrite. Decision §6 Q10. | S | I | `2026-09-24_evidence-archive-untracking.md` |
| P1e-4 | **Environment-knob reference**: one table of every `CERB_*`, `SKIP_BUILD`, `TIMEOUT_SECS`, `ENFORCE`, `LEAN_ABORT_ON_PANIC` variable the scripts read, with defaults and owning lane; a grep-derived `--check` that the table is complete. | S | I | §1.5 |
| P1e-5 | **Front-doc pin citations**: the "documentation check" headers name the pin they were checked at AND the current pin (as `CLAUDE.md:5` now does), or drop the Lem hash in favour of "the lakefile rev"; the README's NOTICE/LICENSE links at the tagged revision. | S | I | §1.1 |
| P1e-6 | **The 2026-09-11 "doc residuals outside the fence"** and the **risk-map comment fixes**: the observation-contract matrix row for 6b's labelled projection; the tray `README.md` §4 triage table beyond draft 36; `test_immaculate.sh:22-27` naming R5; VALIDATION §2's R4 paragraph; `fuel_hypotheses.txt:43-46` and `CerbTagsWf.lean:19-40` restated as a conjectured frontend invariant; `CerbGlobal.lean:17`; `unsafebaseio_allowlist.txt:41`; LADDER Tier B row 9's "90" → 91/91. | S | I | `TODO.md` |

Exit criteria: link-check of the index; the derived-count, index and knob-table
`--check` modes green.

### Phase 2 — consumer usefulness (M; four slices, ONE consumer re-pin)

The whole phase lands as ONE pin bump for cerberus-sl (semantics + LemLib).
Slice 2d (ruled shared-model fixes) is dispatched as soon as its rulings
arrive and may precede 2a–2c; it rides the same re-pin.

#### Slice 2a — packaging (forward assessment F4.1, F4.4, F4.6)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P2a-1 | **`CerberusLean.Pipeline` library module**: `loadCoreStdlib`, `loadCoreImpl`, `frontendTU`, `loadLibc`, the link fold, `runDigest`, `defaultFuel`/`defaultAddressSpaceTop` and `runPipeline`'s pure core move out of `Main.lean`; `Main` becomes a thin CLI over it. The no-fuel-numerals gate's allowlisted site moves with `defaultFuel` in the same commit, with a plant confirming the old site is no longer allowlisted. cerberus-sl deletes `Corpus/Capture/Pipeline.lean`'s copy. | M | C | §1.3 |
| P2a-2 | **Export `md5.o`** through the lakefile (`extern_lib` or equivalent) so consumers stop passing `moreLinkArgs` by hand; the `lean-native-obj` step becomes a Lake facet or is documented as the one prerequisite. | S | C | §1.3 |
| P2a-3 | **A git `require` that builds**: EITHER commit `lean_frontend/generated/` (guarded by the lem-sync stamp and `check_handwritten_sync.sh`; costs: 219-file commits with 100 KB lines at every lem re-pin, `new-worktree.sh` and the consumer's `setup-cerberus-dep.sh` change, divergence from upstream's convention of gitignoring `ocaml_frontend/generated`) OR a Lake facet that regenerates from `.lem` (needs the lem toolchain at the consumer). Decision §6 Q2. | M–L | C | §1.3 |
| P2a-4 | **Consumer-facing targets**: a `CerberusLean` library target that does not drag the 17 test `lean_exe`s; the test exes under a `test` facet; `defaultTargets` reviewed. | S | C | forward F4.1 |
| P2a-5 | **One-page API doc** (`lean_frontend/API.md`): the exec-facing entry set (`driver2`, `drive`, `initial_driver_state`, `desugar`, `annotate_program`, `translate`, `link`, `convert_file`, `runNDFuel`, `CerbCall.driveCall`, the readers, the parameters fuel/top/digest and their domains), the outcome types, the hypothesis register, multi-TU + libc loading, and the "C snippet → Core" and "C file → verdict" one-liners. | S | I | §1.3 |
| P2a-6 | **Versioned JSON outcome schema** for `--batch` (verdict, value, stdout/stderr bytes escaped, blocked, kill class, fuel/top used) beside the existing text form; `scripts/observations.py` gains a decoder; the text form stays the lanes' pinned projection until a dedicated re-record. | S–M | I | forward F4.4 |

#### Slice 2b — the consumer's open reasoning asks

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P2b-1 | **Structured kill reasons** — two shapes, decision §6 Q3: (i) what the consumer asked (item 4): `MerrOutOfMemory` as a `mem_error` constructor (shared-model: `mem_common.lem`, `impl_mem.ml`, `CerbMem`) and `kill_reason.FuelExhausted` / `ModelFailStop : String → kill_reason` in place of `Error0 <opaque Loc> msg`; (ii) the `TODO.md` C-TF1 (b) alternative: `CerbFuel.fuelExhaustedLoc` and `CerbFail.modelFailStopLoc` as transparent `def`s (`Loc.other "…"`), which removes two boundary-opaque rows (10 → 8) without new constructors. (i) is the consumer's ask and needs a shared-model ruling; (ii) deviates from the C1 Option-C precedent. | S–M | C, M for (i) | consumer item 4; `TODO.md` C-TF1 (b) |
| P2b-2 | **Configuration as a reader parameter** (consumer item 5): `CerbGlobal`'s eleven plain `def`s become a reader-lifted record with the default as the seed, so a theorem quantifies over the switch set while matched mode instantiates the default. This is REGISTERED work, not a re-adjudication: the [USER 2026-09-03] Q7 ruling refused plumbing "in this arc" (`docs/2026-09-03_zero-discrepancy-design.md:662-665`), and `VALIDATION.md` §9 records "Step 2 — the configuration as a reader-lifted parameter — is a separate slice". Dispatch decision §6 Q3. `using_concurrency` stays `false` and out of scope. | M | C (Lean-only declares) | `VALIDATION.md` §3(c)/§9; `DESIGN.md` §4 |
| P2b-3 | **Decidable acyclicity checker** as a load-time Tier C instrument: a bounded rank computation on `fmapElements` with the theorem `check tags = true → CerbTagsWf.Acyclic tags`, so the lanes assert the invariant on every loaded program and the consumer discharges its entry hypothesis by evaluation. The theorem is about the checker, not a new program proof. | S–M | I (+ one theorem) | `TODO.md` C4 follow-ups |
| P2b-4 | **NOT SCHEDULED — needs an explicit yes (§6 Q12):** prove the value-arena hypothesis for `drive`'s final state from `prepare_exit`'s definition and the singleton-thread part (`hack`/`to_pure`/`to_pures` lose their hypothesis rows, `fuel_hypotheses.txt` 12 → 9). `TODO.md` calls this "consumer-side; not done"; it is verification-layer work by the brief's exclusion. | M | I (theorem) | `TODO.md` "finalize/hack boundary" |
| P2b-5 | **Hygiene residuals the consumer named** (item 9): `bounded_integer` as an ND CHOICE in `ndM` (their ask; today `CerbUtils.boundedIntegerImpl` is permanent-declared on the boundary for OCaml module-shape parity, `VALIDATION.md` §9) — a mirror question against `impl_mem.ml`'s random draw, decision §6 Q4, NOT a transparent def returning `lo` (that is what they warned against); `dynamicAddrs` pruning (R4, tray 19) — mirrored today, admission needs a ruling; the `driver_globals` determinism lemma sits with P2b-4 in Q12. | S each | C | consumer item 9 |
| P2b-6 | **`WFfile`**: a stated well-formedness predicate for frontend output (consumer item 8, "not urgent"), as a definition with the lanes asserting it, no proof claimed. | S | I | consumer item 8 |

#### Slice 2c — the ONE generated-surface bundle (two-repo pin dance)

Every item that changes generated heads or text is here, so cerberus-sl sees
one diff manifest. Lem first (ff-only), re-pin, re-gate, then cerberus.

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P2c-1 | **Dead `[LemFuel]` binders**: the ~20 `CerbMem` functions that carry the binder only to reach the now-fuel-free layout wrappers (`grep -c '\[LemFuel\]' CerbMem.lean` = 23) and `mem.lem`'s `fuel_consumer` declares for them; a Lean-only cascade through generated heads; OCaml byte-identical by construction. | S–M | E, C | `TODO.md` C4 follow-ups |
| P2c-2 | **`.lem` hygiene riding the same stamp move**: `core_linking.lem:61-63`'s dangling `set_fold` declare (a target_rep'd val emits no definition on either target; both generated trees unchanged; the lem-sync SOURCE hash moves); the comment-only `lemDefaultFuel` mentions in `defacto_memory.lem:2681` and `formatted.lem:327` (`monadic_parsing.lem:113` no longer has one) — `grep -l lemDefaultFuel ocaml_frontend/generated/*.ml` returns NOTHING, so these comments are NOT propagated and the OCaml tree does not move (review F2; the first draft's Q2 asked for a ruling on a trade-off that does not exist). | S | E (source stamp only) | `TODO.md` |
| P2c-3 | **Declare-family consolidation** (lem TODO row 18): ~10 Lean-only declare forms → the TERMINATION / AMBIENT / STATE / REPRESENTATION families; behaviour-preserving; the cerberus `.lem` declare lines renamed in the same pin bump (Lean-only lines); gated by the comprehensive suite, the invariance witnesses and byte-identical regeneration of BOTH cerberus trees; the manual chapter rewritten around the families. [USER 2026-09-04] "definitely worth doing before we get to stable". | M–L | E, C (declare text) | lem TODO 18 |
| P2c-4 | **Qualified constructor patterns** (lem TODO row 9): constructors keep their lem names (`One`, not `One0`); pattern and application rendering emit `T.C`. A RENAME WAVE through cerberus-sl's ~6,268 lines of hand-written mirrors; decision §6 Q5 — do it now, in this bundle, or not at all. | M | C | lem TODO 9 |
| P2c-5 | **Line-broken emission**: a width-bounded pretty-printer for definitions (today 104 KB single lines), `.lem` line references in a leading comment per definition. Text-only; exit criteria: byte-identical OCaml AND a declaration census of the generated `.olean`s equal before/after (names, types, values by `#print`-level comparison) — not the sampled unit/gate results alone (a sampled check is a fail-open shape, review §5). | M–L | E | §1.6 readability |
| P2c-6 | **Well-founded → structural in LemLib** (lem TODO row 12): `gen_pow_aux`, `lemStringFromNat*Helper`, `listSet`, `boolListFromNatural`, `bitSeqBinopAux`, where a consumer computes through them. | S | E | lem TODO 12 |
| P2c-7 | **Library-side declares for the hardcoded library names** (lem TODO row 4) if it fits the bundle; otherwise Phase 4. | M | E | lem TODO 4 |
| P2c-8 | **The Phase 3 run-loop rendering (P3-3)** rides this bundle IF its design note (P3-2b) is approved in time; otherwise it costs the consumer a separate re-pin, stated in §4. | — | C | §3 Phase 3 |

#### Slice 2d — ruled shared-model fixes (dispatched when ruled; may precede 2a–2c)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P2d-1 | **Union twin** (D-3): the `are_compatible` consult at `core_eval.lem`'s `PEmemberof(union)` arm and `core_aux.lem:204-208`'s union arm; the reproducer from `TODO.md` pinned in `tests/multi_tu_tray/`; draft 38 gains a union subsection; the pristine register gains its row. Ruling §6 Q1. | S–M | M | `TODO.md`; draft 38 |
| P2d-2 | **`aligned_alloc(0, n)`** (D-2) once the logical meaning is ruled (§6 Q1). | S | M | `VALIDATION.md` §3; tray 34 |
| P2d-3 | **`_Alignas` alignment specifiers** in `are_compatible_aux` and the F-A2 frontend completeness gap (D-8), after their tray drafts (P1c-2), if ruled (§6 Q1). | S–M | M | `TODO.md` |
| P2d-4 | **`MerrOutOfMemory`** (P2b-1 shape (i)) if ruled — the shared-model half of that item. | S | M | consumer item 4 |

Phase 2 exit criteria: lem-lean comprehensive + parity green; cerberus Tier A +
Tier B (both pristine rows, the three-engine report — MANDATORY for any
shared-model slice, `VALIDATION.md` §0); the OCaml generated tree byte-identical
for 2a/2b/2c, the 2d deltas each hash-pinned in `fork_drift_manifest.txt` with
a dated NOTE and a pristine-register row; the generated Lean diff enumerated;
`check_theorem_axioms.sh`'s boundary population re-pinned with its dated NOTE;
the consumer note lists every renamed constant and the LemLib rev.

### Phase 3 — scalability without trust cost (profile first)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P3-1 | **Driver-vs-oracle benchmark** (forward F6.7): `measure_csmith_cpu.py` over the standard corpora, wall and CPU ratios published in `VALIDATION.md` §5 as a Tier C instrument; the fuel-measure 7.5% figure re-measured at the current pin; a driver footprint measurement on the big TUs (forward F6.5). | S | I | §1.4 |
| P3-2a | **Asymptotics profile** (forward F6.2): one Lean profiler pass on a large TU (`chvalid.c`, a large csmith file, `sa_csmith_419.c`) and on the `d_loop_100000` / `b_zero_local_100000` probes; a written finding naming the hot paths in classic PL terms. | S | I | §1.4 |
| P3-2b | **Design note: run-loop rendering of monadic list combinators** (lem TODO row 1) — the rendering does not exist; the note states the transformation, its class (Lean-emission only), the invariance argument, the completion gate, and a dry run on one combinator. Scope decided WITH the operator (§6 Q7); nothing is implemented before the note is approved. | S | I | `TODO.md` KNOWN HANG; lem TODO 1 |
| P3-2c | **Design pass: the step-runner process-stack ceiling** — the 2026-08-31 design is PARKED on a stale premise and the ceiling has returned at 10^8 fuel; a fresh note proposes the executable-face route (iterative/trampolined run loop) with a kernel-checked equivalence to the definitional runner, or names why none is possible. No `implemented_by` shortcut: the fast path is proven equal or it is not shipped (the "no internal trust gaps" practice; a declared boundary row would be a §6 decision, not a default). Scope decided WITH the operator (§6 Q8). | S–M | I | `docs/2026-08-31_stack-ceiling-design.md`; §1.4 |
| P3-3 | **Run-loop rendering — implementation**, if P3-2b is approved: class 0. Exit criteria: `a_zero_global_10000000.c` completes with the oracle's verdict as STATUS, never timing; `b_zero_local_1000000` re-measured. Generated-surface change → the Phase 2 bundle or its own re-pin (§4). | M | E, C | lem TODO 1 |
| P3-4 | **Step-runner ceiling — implementation**, if P3-2c produces a proven-equal design. Exit criteria: `d_loop_1000000.c` and `e_memcpy_1000000.c` complete with the oracle's values. | M (a guess until the design exists) | E (proven-equal) | §1.4 |
| P3-5 | **`mkListN_aux` operand-bounded measure** (n elements) so the front-end aggregate ceiling is a measured worker, not a fuel PANIC. | S | E | `TODO.md` "Front-end mkListN ceiling" |
| P3-6 | **Only if P3-2a names it**: hot-path structure swaps via kernel-checked equivalence lemmas; a sparse/chunked `CerbMem` byte representation with a compact unspecified-region form behind a data-refinement proof against the byte-list model (the OOM rows). A representation design pass first, scoped with the operator. | L | E (proven-equal) | `VALIDATION.md` §3(b) |
| P3-7 | **libc-body UB locations** (D-1): a libc pin vehicle carrying locations — the oracle's `--pp=core` gains a location-preserving mode for the libc dump, or the libc is loaded from the 12 metadata TUs' Cabs JSON through the pipeline (slower; measured first). A correspondence bug, so it outranks the perf items if P3-1 shows no perf crisis. | M | E (oracle exporter + seam) | `VALIDATION.md` §3 |
| P3-8 | **Lane wall-clock** (forward F6.4): sharding presets in `release.py`, driver startup amortisation; measured before/after. The ND-branch evaluation strategy (forward F6.6) is deferred until P3-2a says branching is a cost. | S | I | forward F6.4 |

Exit criteria per item as stated; every completion criterion asserts STATUS,
never timing; the tripwire (~1 h) is a STOP-AND-REPORT event.

### Phase 4 — fidelity, coverage, upstream (partly network-gated; L items are named deferrals)

| ID | Item | Price | Impact | Source |
|---|---|---|---|---|
| P4-1 | **Fork-delta triage for upstreaming** (forward F2.3): the manifest's 85 oracle-surface files + 30 generated deltas classified upstreamable / fork-permanent / dissolvable-on-resync; the upstreaming menu; plus the **byte-identity discipline write-up** for upstream's eyes (forward F2.4). | S–M | I | forward F2.3/F2.4 |
| P4-2 | **Upstream re-sync** (forward F2.2): fetch at a network window, measure the delta from `b9aeedcb4`, rebase the fork; the renumbering machinery is the known cost; `deps/cerberus-upstream` and the pristine oracle move together; every lane re-baselined in dedicated instrument commits; the `LemUnsupported.Cmm.*` markers on `cmm_csem.lem` re-applied over upstream's changes (the one place this plan touches the concurrency surface). Its own arc with its own audit. | M–L | M (upstream content) | §1.7 |
| P4-3 | **Tray filing** (operator, network): the 48 drafts in the INDEX's TRUE-BUG-first order, the three prepared PR branches, the P1c-2 drafts, and the ISO-fix register's "filed upstream" criterion met or re-adjudicated (§6 Q11). | S prep | I | §1.7 |
| P4-4 | **lem-lean library-name entanglement** (lem TODO row 4, if not in P2c-7) and **effect-free emission** (row 6) — the upstream-submission prerequisites the review's N2 deferred to "the upstream-submission plan". | M + M | E | lem TODO 4/6 |
| P4-5 | **Coverage probes**, S each, oracle support assessed first: bitfields (kernel-pervasive; csmith runs with bitfields excluded today), varargs (`Va_*` OBSCURE for the consumer), GNU dialect file-by-file behind upstream's own support, float arithmetic breadth; the CI sweep's 820 non-comparable rows mined into a ranked feature-gap list (766 are oracle rejects, so most gaps are upstream's); the elab-lane and immaculate follow-ups (forward F3.6). | S each | I | forward F1.3–F1.6, F3.4, F3.6 |
| P4-6 | **Quantify "well tested"** (validity instruments, borderline to the brief — explicit yes, §6 Q12): a construct-coverage counter in the driver (forward F5.3); a mutation-score run over N seeded model bugs (F5.4) including ONE seeded lem-backend bug to demonstrate the differential catch (F5.2's argument, stated in VALIDATION); both Tier C instruments with published tables. | M + M | I | forward F5.2–F5.4 |
| P4-7 | **NAMED DEFERRAL — the PNVI provenance port** (forward F1.1): the flagship fidelity item, L, outside this brief's three buckets; needs its own charter, the instruments of P4-6 in place, and an appetite decision (§6 Q12). Nothing is scheduled. | L | M | forward F1.1 |
| P4-8 | **NAMED DEFERRAL — Lem byte-string representation** (lem 2026-09-03 design: "a BUG to fix"): L; a general-backend fidelity item, not a cerberus blocker; appetite decision (§6 Q12). Nothing is scheduled. | L | E | §1.6 |
| P4-9 | **Scale fuzzing**: a scheduled csmith campaign beyond the 25-seed smoke kit ("explicitly NEXT-arc" in `fuzz_csmith.sh`), sharded, as a Tier C instrument; the CoreParser hash-id residual probed once (forward F5.5, act only if cheap). | S–M | I | §1.5; forward F5.5 |
| P4-10 | **Trust-surface risk map repeat** (master plan step 7) after Phases 2–3, fresh auditor, baseline = the alpha tag. | M | I | `TODO.md` "Whole-project trust-surface risk map" |

## 4. Dependencies and ordering hazards

- **Consumer re-pins, counted honestly.** (1) the announcement tag (Phase 0);
  (2) the Phase 2 bundle — Slices 1d (LemLib), 2a, 2b, 2c and any ruled 2d
  item, one pin bump; (3) POSSIBLY a third for P3-3 if its design note is
  approved after the Phase 2 bump has landed — the consumer note says so in
  advance. Each is a two-pin move (semantics commit + LemLib rev). The first
  draft's "one per phase" undercounted: P1b-1 (now P2c-1) would have made
  Phase 1 a re-pin too; it has moved.
- **Slice 1d before Phase 2**: LemLib changes (P1d-4, P1d-5) otherwise force a
  cerberus pin bump of their own.
- **P2a-1 (Pipeline module)** moves `defaultFuel`: the
  `check_no_fuel_numerals.sh` allowlist line moves in the same commit; a plant
  confirms the old site is no longer allowlisted.
- **P2a-3 (committing `generated/`)** changes the repository's shape and every
  worktree recipe (`new-worktree.sh` copies `generated/` today) and the
  consumer's setup script; the lem-sync stamp becomes the guard that a
  committed tree equals the recipe's output. Decided before any Phase 2 code
  (§6 Q2).
- **P2b-2 (configuration as a parameter)** is a reader-lift through many
  generated heads: it belongs in the 2c bundle if dispatched, never mid-phase.
- **Slice 2d** items are shared-model changes: each needs its ruling, its tray
  draft and its pristine-register row BEFORE the code, and the three-engine
  report at landing.
- **P3-3 (run-loop rendering)** changes the generated Lean of every
  function-typed-monad combinator use: a generated-surface change, bundled
  with a consumer re-pin, never mid-phase.
- **P4-2 (re-sync)** invalidates the pristine oracle at `b9aeedcb4`, the
  fork-drift manifest's merge-base and every hash pin: its own arc with its own
  audit, never combined with a semantics slice.
- Nothing here may land on `mdd/*` until the release overseer declares the
  tagging finished; all Phase 0/1 work proceeds on branches meanwhile.

## 5. Consumer impact summary (for the cerberus-sl note)

| Phase | What they see | Action |
|---|---|---|
| 0 | the tag; the README pin fix; LemLib gained `never_extract` on `fuelExhausted` (runtime, no API change) | re-pin once at the tag: semantics commit + LemLib rev |
| 1 | nothing until Phase 2 (Slice 1d's LemLib changes ride the Phase 2 bump) | none |
| 2 | `CerberusLean.Pipeline` replaces their copy; `md5.o` exported; a buildable git `require` (or facet); API.md; kill reasons structured (shape per Q3); dead fuel binders gone from ~20 `CerbMem` heads; declare text consolidated; constructor names un-suffixed IF Q5 says yes (a rename wave through their mirrors); union/aligned_alloc verdict changes IF ruled; LemLib m10/toolchain changes | one two-pin re-pin with the diff manifest; delete `Capture/Pipeline.lean` and the `moreLinkArgs`; rename constants per the manifest; `Lang.oomKill`'s string match breaks loudly by design |
| 3 | P3-3 is a generated-surface change (a re-pin, bundled with Phase 2 if its design is approved in time); P3-4/P3-6 are proven-equal executable-face changes with no definitional change | a re-pin only for P3-3 |
| 4 | the upstream re-sync moves the shared model | a scouted re-pin of their own |

## 6. Decisions requested from the operator

Each with the orchestrator's recommendation [AGENT]; none is assumed. Every
item marked C (consumer-visible) in §3 is covered by Q2, Q3, Q4, Q5 or the
Phase 2 bundle's single re-pin (P2a-1/2/4, P2c-1/3 are surface changes the
consumer has asked for or that shrink their work; they need no separate
ruling, only the manifest).

| # | Decision | Options | Recommendation |
|---|---|---|---|
| Q1 | Shared-model fixes (Slice 2d): the union twin (P2d-1), `aligned_alloc(0,n)` (P2d-2), the `_Alignas` gaps (P2d-3) | per item: fix ahead of upstream with a tray draft + register row, or mirror and wait | union twin: fix (same class as the [USER 2026-09-10] struct ruling); `aligned_alloc`: rule the logical meaning first (Core UB045 vs the ISO 7.22.3.1 guard); `_Alignas`: drafts first, decide on the drafts |
| Q2 | Packaging shape (P2a-3): commit `lean_frontend/generated/` or ship a regeneration facet | (a) commit the tree; (b) facet | (a), with the costs stated in P2a-3 accepted knowingly: it is the only shape that makes a git `require` work for every consumer without a lem toolchain, and the lem-sync stamp already guards the tree's identity. If the 219-file re-pin commits are unacceptable, (b) |
| Q3 | The consumer's two reasoning asks: kill-reason shape (P2b-1: (i) structured constructors incl. `MerrOutOfMemory`, a shared-model change; (ii) transparent `Loc` defs, Lean-only) and WHEN to dispatch the registered configuration-parameter step 2 (P2b-2) | P2b-1: (i), (ii), both, neither; P2b-2: Phase 2 / later | P2b-1: (ii) now in the bundle (pure benefit to theorems, no model change) and (i)'s `MerrOutOfMemory` as a 2d item if the consumer ranks it first; P2b-2: Phase 2 bundle if the consumer confirms they will quantify over it, else later |
| Q4 | `bounded_integer` (P2b-5): keep the permanent-declared boundary row, or model it as an ND choice in `ndM` as the consumer asks | keep / ND choice | ND choice only if `impl_mem.ml`'s draw is genuinely a semantic choice (mirror question first); otherwise keep and answer the consumer with the cite |
| Q5 | Constructor un-suffixing (P2c-4): a rename wave through cerberus-sl's mirrors | do it in the Phase 2 bundle / never | do it now or never — a later rename costs a second wave; ask the consumer before deciding |
| Q6 | LemLib toolchain: align to 4.32.2 (P1d-5) | align / keep 4.28 with a stated policy | align |
| Q7 | Run-loop rendering (P3-2b/P3-3): commission the design note | commission now for Phase 3 / defer | commission the note now (S); the mechanism is understood, the rendering is not; the `.lem` alternative is closed by the [USER 2026-09-02] revert |
| Q8 | The step-runner ceiling design pass (P3-2c): scope | proven-equal route only / also consider a declared boundary row / defer | proven-equal route only; a boundary row is a trust-surface change and would need its own case |
| Q9 | Branch/worktree deletions (P0-3) | the proposed list | delete finished audit/cleanup/review/docs worktrees; keep every parked record |
| Q10 | Evidence-tracking policy for large JSON/log evidence (P1e-3) | threshold + untrack / keep tracking | a size threshold with SHA-256 + reproduction command in the record |
| Q11 | The ISO-fix register's "filed upstream" criterion, unmet for R1/R2/R3/R5 | file at the next network window / relax to "prepared, filing owed" | file; until then label the entries "PREPARED, filing owed" in §2 |
| Q12 | Appetite and explicit-yes items outside or at the edge of the brief: P2b-4 (the value-arena theorem), the `driver_globals` determinism lemma, P4-6 (coverage/mutation instruments), P4-7 (PNVI, L), P4-8 (byte strings, L) | per item: yes now / after Phase 3 / no | P4-6 after Phase 2 (it arms Phase 4); P2b-4 and the lemma only on a consumer request; P4-7/P4-8 after Phase 3, each behind its own charter |
| Q13 | Lean CI for the public repositories | a self-hosted runner honouring the caps / none, dated records remain the evidence | a self-hosted runner for row 1 + the six small lanes only, if a machine is available |
| Q14 | Wider use of the `failure-class` observation projection (parked at the 2026-09-11 landing as "a separate operator decision") | widen / keep to row 6b | keep to row 6b unless a lane needs it |

## 7. Independent review — findings and dispositions

Commissioned with the plan ([USER 2026-09-25] "then send a subagent to
evaluate and critique it"); a fresh reviewer (Claude Fable, general-purpose,
read-only) received the first draft and the source list; verdict "needs rework
on §1.6/§1.1 wording, P1b-3/Q2, P2b-2/Q5, P2b-5, P3-4, and the phase/re-pin
structure; the finding F-0 and most tables are sound". Every factual finding
was re-verified by the orchestrator by measurement before being applied
(house rule: audit findings are claims). Dispositions:

| # | Sev | Finding (reviewer) | Verification | Disposition |
|---|---|---|---|---|
| F1 | MAJOR | The `Â§`-is-upstream inference from fork-drift byte-identity is unsound (the fork-drift tree is built with the fork's lem); the sound evidence is the pristine tree (28 files) and `lexer.mll:61` `of_latin1`. | Verified: 28 pristine files; `lexer.mll:61,188,216-218`; fork diff to `lexer.mll` 13 lines (keywords). | APPLIED — §1.6 rewritten; P1c-2 cites `lexer.mll`. |
| F2 | MAJOR | P1b-3/Q2 rest on a false premise: `lemDefaultFuel` comments are not propagated to OCaml; only two `.lem` files still carry the word. | Verified: `grep -l … ocaml_frontend/generated/*.ml` = 0; `defacto_memory.lem:2681`, `formatted.lem:327` only. | APPLIED — Q2 deleted; the item is P2c-2 (source stamp only); TODO row marked stale (P1e-2). |
| F3 | MAJOR | P2b-2 misstates the Q7 ruling: it refused plumbing "in this arc"; VALIDATION §9 registers step 2 as a separate slice. | Verified: `2026-09-03_zero-discrepancy-design.md:662-665`; `VALIDATION.md` §9. | APPLIED — reframed as registered work; Q3 is a dispatch decision. |
| F4 | MAJOR | "`make lean-build` runs an uncapped `lake build`" is false. | Verified: `Makefile:380-384` uses `../scripts/capped`. | APPLIED — claim removed, correction noted in §1.5. |
| F5 | MINOR | Sweep changed ONE README line; NOTICE did change (+2) between `67ec5de` and `c2a68e7`. | Verified. | APPLIED — §1.1. |
| F6 | MINOR | D-4 (F-A8) unreproduced at the current parser. | Reproduced by execution: works (§1.2). | APPLIED — D-4 RESOLVED, TODO row stale. |
| F7 | MINOR | Only one locale-dependent order remains; `LC_ALL=en_US.utf8` is the S6 plant. | Verified against the follow-up record. | APPLIED. |
| F8 | MINOR | Counts: lem TODO 22 rows; lem-vs-master 479 files / +52,055; cache 2026-08-18, master 2026-06-09; `partial def` 302/32; evidence 1,078 / 40 MB; branch counts "at the inventory". | lem TODO rows recounted (22); others taken as the reviewer's measurement, labelled derived. | APPLIED. |
| F9 | MINOR | D-9 phrasing (TSVs last committed 2026-09-02, content 2026-08-22). | Accepted. | APPLIED. |
| F10 | NOTE | Consumer item 4 asks structured constructors, item 9 asks `bounded_integer` as an ND choice; `Pipeline.lean`'s header mirrors the interim pin. | Verified at `hidden-state-upstream-note.md:86-100,146-153`; `Pipeline.lean:14-32`. | APPLIED — P2b-1 both shapes, P2b-5 rewritten, §1.3. |
| F11 | NOTE | Verified-as-stated list (28 refusal sites, tray counts, 104,493 chars, etc.). | — | Recorded. |
| C | MAJOR | Completeness: ~20 TODO/forward-assessment/consumer items omitted without saying so. | Each checked against `TODO.md`/forward assessment. | APPLIED — folded into P1a-9/12, P1c-2, P1d-7, P1e-6, P3-1/8, P4-1/5/6/9; the rest listed in §8 with reasons. |
| S | MAJOR | Scope: P2b-4 is verification-layer work and touches "nothing new out of policy"; P4-7 is fidelity research; P4-6 borderline; P4-2 touches the concurrency surface. | Accepted. | APPLIED — P2b-4 unscheduled (Q12); P4-7/P4-8 named deferrals; P4-6 explicit-yes; P4-2 flagged. |
| Q | MAJOR | Sequencing: three re-pins not one; P1c (LemLib) before P1b; Slice 1b mixed kinds; Slice 1a too large; Q1(a) contradicted §0. | Accepted. | APPLIED — §4 recount; 1d before Phase 2; Slice 1b split into 1a/1b/1c/2c/2d; F-0 landed by the overseer so Q1 is moot. |
| H | MAJOR | House rules: doc-consistency checks as row-1 gates (proliferation); P3-4's `implemented_by` alternative; P2c-3's sampled census; P1a-6's exit codes without the OCaml mirror check; a private memory-file name cited as a principle. | Accepted. | APPLIED — principle 6 (speedbumps); P3-2c proven-equal only; P2c-5 declaration census; P1b-2 mirror check first; principle 1 rewritten in words. |
| I | NOTE | Consumer impact understated for the rename wave and for committing `generated/`. | Accepted. | APPLIED — Q5 and Q2 argue both sides; §5 rewritten. |
| P | NOTE | Prices: P1a-6 and P1c-1 are M; P2a-3, P2c-1, P2c-3, P4-2 are M–L; P3-4 needs a design pass first (the stack-ceiling design is PARKED on a stale premise). | Verified the PARKED disposition at `2026-08-31_stack-ceiling-design.md:11-19`. | APPLIED — re-priced; P3-2c added. |
| R | NOTE | Q7 "rule for it" overreaches: the rendering is undesigned; the standing [AGENT 2026-09-02] Q5 preferred the `.lem` route. | Partly disputed: the `.lem` route was built and REVERTED by [USER 2026-09-02], so the fallback is the only open route; but the rendering is indeed undesigned. | APPLIED as "commission the design note" (Q7). |
| D | NOTE | Document quality: §1.3 header, C-impact items not all in §6, §5 row 3 vs §4, "Gate" as a reserved word. | Accepted. | APPLIED. |

Not verifiable by the reviewer and still not verified here: the survey-only
figures marked **[survey]**; whether GitHub `master` of lem-lean has moved
(offline); the three-engine report tallies (not re-run for this plan).

## 8. Deliberately omitted or deferred, with reasons

- **The 17 UNKNOWN failure-reach register rows** (`TODO.md` pure-failure
  correspondence tripwire): they move only by a witness or an invariant through
  `--emit`/`--reseal`; no scheduled work, the tripwire stands.
- **The in-process consumer / strict-result correspondence design**
  (`VALIDATION.md` §3 "Still open"; `docs/2026-09-07_pure-failure-correspondence-design.md`):
  PARKED by [USER 2026-09-07] option C; nothing here reopens it.
- **The `refsOf ty = []` guarded environment bound** (`TODO.md` C3 follow-ups):
  needs a kernel-checked sufficiency proof and workload evidence; environment
  measures cost ≤ 0.25% on the profiles; not worth a slice until P3-2a says so.
- **Defacto memory model rows in the exec-cone module lists (D-C2-7)**: 12
  dead fuel'd rows; a list-membership decision with no behaviour; folded into
  P1e-2's register rewrite as a row for the operator, not scheduled.
- **lem TODO rows 13 (fuel monotonicity, L, operator decision), 16, 20, 21, 22,
  23**: 13 is deferred by its own record; 16/21 lift when a consumer needs
  them; 20 is a documented limit; 22/23 are the cerberus half, already
  delivered (the hypothesis register and `hyp=` reporting exist).
- **lem TODO row 7 (OCaml `genlist` quadratic)** and **row 8 (`real`/`float64`
  on Lean `Float`)**: neither is used by cerberus; row 8 is an operator call
  with no requester.
- **Forward assessment F5.7 (baseline-freshness gate)**: substantially covered
  since by the lem-sync stamp, the driver-freshness stamp and the
  hand-written-copy gate; not re-listed.
- **Forward assessment F5.6 (elaboration-in-statement probe)** and **F6.6
  (ND-branch strategy)**: research-shaped; F6.6 waits on P3-2a.
- **The legacy csmith run**: separately owned, excluded by `TODO.md`'s header.
- **The concurrency track** in its entirety (§0).

## 9. What this plan does not claim

It does not claim the release is certified, that any item is approved, that
the prices are measurements, that the consumer will take the re-pins on any
schedule, or that the reviewer's unverified figures are facts. Every gate tail
that supports a claim in a later record is recorded verbatim there, not here.

## 10. Addendum 2026-09-27 — mainline movement and the operator's rulings

### 10.1 What moved (orchestrator [AGENT], measured 2026-09-27)

This branch was rebased from `683dc186c` onto `mdd/cerberus-lean` @
`5ecc0aa33` (docs-only, no conflict). lem-lean `mdd/lean-backend` is unchanged
at `c2a68e7`. The upstream-tracking `master` is unchanged locally at
`b9aeedcb4`; the box is offline, so upstream itself is UNVERIFIED.

- **The release is done.** `cerberus-lean-v0.1.0-alpha.1` and
  `lean-backend-v0.1.0-alpha.1` exist and were verified from anonymous clones
  (`9bf8cdaa6`); cerberus-sl's final pin is the tag. P0-1 is closed and P0-2's
  tag half is done.
- **Q11 is resolved by the operator's action, not by this plan.** VALIDATION §2
  (`cfc275d84`) records [USER 2026-09-26] "these have been filed privately in
  that I have notified the cerberus maintainers" for reports 10/11/13/40 as
  **Sent**, and states that this meets the register's "filed upstream"
  criterion. The tray inventory is 44 Draft / 4 Sent / 1 Filed.
- **SC WP0 landed on the mainline** (`5ecc0aa33`, [USER 2026-09-27] "Great go
  ahead and merge."): opt-in passive memory-access receipts in `CerbMem.lean`,
  `mem_common.lem` and the four OCaml memory models, a row-1
  `memory-access-test`, and an independent sequential repair (`d61dcb9c4`:
  trapping `_Bool` loads keep the completed read state, mirroring
  `Concrete.load`). §0's exclusion of concurrency rested on the 2026-09-24
  ruling; the SC track is now live under the operator's later MVP direction and
  edits the same memory model as P2c-1, P2b-1(i)/P2d-4 and P3-6. The `_Bool`
  half of P1c-4 is partly covered by the repair's `MonadicFailstop` witnesses.

### 10.2 Rulings (verbatim, [USER 2026-09-27])

| Q | Verbatim | Consequence for the plan |
|---|---|---|
| Q1 | "I think we should slice these as 'obviously wrong' vs. 'real semantic work' - it sounds like the union twin is a mistake, and can be fixed. The other two might be more like 'hard to decide, the model should return some 'shrug shoulders, unsupported' value" | P2d-1 (union twin) is RULED a bug-fix: dispatchable, same shape as the 2026-09-10 struct fix. P2d-2 (`aligned_alloc(0, n)`) and P2d-3 (`_Alignas`) become LOUD UNSUPPORTED refusals (class (c) missing feature), not a chosen semantics. See 10.3 for one sub-case that may belong in the other bucket. |
| Q2 | "got it, so this is about whether a Lean client can use Cerberus as a library through lake? In that case, let's commit it." | P2a-3 option (a): commit `lean_frontend/generated/`. |
| Q3 | "agree on both" | P2b-1: shape (ii), transparent kill-location defs, in the Phase 2 bundle; `MerrOutOfMemory` only if cerberus-sl ranks it first. P2b-2: Phase 2 if cerberus-sl confirms it will quantify over the configuration. |
| Q4 | "agree" | P2b-5: mirror question first; ND choice only if `impl_mem.ml`'s draw is a semantic choice, else keep the boundary row and answer the consumer with the cite. |
| Q5 | "agree" | P2c-4: in the Phase 2 bundle or never; ask cerberus-sl before deciding. |
| Q6 | "agree, and we should figure out how to stay in sync in future" | P1d-5: align LemLib to 4.32.2; a sync mechanism is owed (10.4). |
| Q7 / Q8 | "agree" | P3-2b and P3-2c commissioned as design notes; the step-runner route is proven-equal only. |
| Q9 / Q10 | "agree" | P0-3 deletion list and P1e-3 evidence policy proceed (deletions remain operator-executed). |
| Q12 | "I don't feel opinionated about these. As you recommend." | Adopted as recommended: P4-6 after Phase 2; P2b-4 and the determinism lemma only on a consumer request; P4-7/P4-8 after Phase 3, each with its own charter. |
| Q13 | "the memory caps are only needed for this machine because it's used for many builds. We should just worry about the GH upstream. And maybe take the caps out of ci?" | Q13 becomes a GitHub-hosted CI item, scoped in 10.5. |
| Q14 | "I don't have enough context ot decide this" | No ruling. Status quo holds (the projection stays on row 6b only); explained in 10.6 for a later decision. |

### 10.3 Q1 — the "unsupported" bucket, as implemented [AGENT]

- `aligned_alloc(0, n)`: today Lean returns `Undefined DUMMY(align_alloc)` for
  `(0, 8)` and a loud refusal for `(0, 0)`; the oracle raises
  `Division_by_zero`, a kind-2 host artifact. Both arms become one attributed
  refusal. This is a Lean-side change within class (c); the `zd-z2m01-*` pins
  are re-recorded in a dedicated instrument commit; tray 34 records the choice.
- `_Alignas` member alignment in `are_compatible_aux`: refuse when two
  cross-TU members differ ONLY in an alignment specifier, rather than silently
  treating them as compatible. This moves both fork engines (a shared-model
  change); the pristine register gains a row.
- **Flagged for the operator [AGENT]: F-A2 may be "obviously wrong".**
  `struct A { _Alignas(struct A) char c; }` violates an ISO constraint (C11
  §6.5.3.4#1; gcc rejects), is accepted by the frontend, and then hangs both
  oracles. Rejecting it at the frontend is a constraint check, arguably the
  union-twin bucket rather than "unsupported". Either way the result is a loud
  failure; the difference is only whether the message says "constraint
  violation" or "unsupported". Recommendation: constraint violation. Proceeds
  as "unsupported" unless the operator says otherwise.
- Both remain behind the SC coordination point (10.7) because P2d-2 touches
  `CerbMem`.

### 10.4 Q6 — keeping the toolchains in sync (proposal [AGENT])

Lake builds a dependency with the ROOT package's toolchain, so cerberus already
compiles LemLib on 4.32.2; the drift is only that lem-lean's OWN tests run on
4.28. Proposal: (1) lem-lean's `lean-lib/lean-toolchain` follows the largest
consumer's toolchain; (2) a Lean bump is a step of the two-repo pin dance
(lem first, then cerberus), recorded in both repos' pin notes; (3)
`check_pin_sites.sh` gains one line comparing the two `lean-toolchain` files,
as a speedbump at claim points, not a new gate.

### 10.5 Q13 — GitHub CI (scoping [AGENT])

- `scripts/capped` stays in the scripts: on this shared box it prevents OOM
  kills across agents. In CI it is switched off by the existing loud opt-out
  `CERB_MEM_MAX=none` in the workflow environment. Deleting the caps from the
  scripts would break the local rule; the environment variable removes them
  from CI only. This is necessary, not just tidier: on a hosted runner the
  cgroup route is unavailable and a present-but-unusable `systemd-run` makes
  `capped` FAIL (README cap notes).
- Scope: the README recipe, row 1 and the six small lanes, on both
  repositories (lem-lean: the comprehensive suite and `nonlean-regress`).
- Unknown to measure first: whether a standard hosted runner's RAM fits the
  cold Lean build. If not, a larger runner or a cached-`.lake` job.
- Adding a workflow and pushing it is a public action: each push needs the
  operator's explicit authorization at the time.

### 10.6 Q14 — context for a later decision

Two engines number symbols differently, so an error message that embeds a
symbol id (`Symbol(123, …)`) differs between them even when the failure is the
same. The `failure-class` projection rewrites `Symbol(<digits>, ` to
`Symbol(_, ` inside Error/Undefined payloads only, and nothing else. It is used
on exactly one lane today, the multi-TU tray (row 6b), where two rows would
otherwise mismatch on numbering alone. The question is whether any other lane
may use it. Widening it hides nothing but symbol numbers, yet every weakened
comparison is less detection, and [USER 2026-08-31] holds that output depending
on symbol numbering is itself a defect. No lane needs it now, so nothing is
blocked. It comes back only if a lane hits the same problem.

### 10.7 New coordination point with the SC track [AGENT]

The plan does not do SC work. Its memory-model items (P2c-1 dead fuel binders,
P2b-1(i)/P2d-4 `MerrOutOfMemory`, P2d-2 `aligned_alloc`, P3-6 byte
representation) are sequenced after checking `SC-CONCURRENCY.md`'s next work
packages, so the two tracks do not edit `CerbMem.lean` / `mem_common.lem` /
`impl_mem.ml` in parallel. This is a scheduling question for the operator and
the SC track's owner; everything not touching those files proceeds unaffected.

## 11. Second review and the current sequence (2026-09-27)

### 11.1 The second review

Commissioned [USER 2026-09-27]: "okay, can you do a re-review of this?
Subagent, look for things in the plan that would make it hard to execute and
deliver, or things that would be at odds with project long-term goals". A fresh
reviewer (general-purpose subagent, read-only) read the plan at `919e9ab41`, the
container and global practices, twelve doctrine memories, the forward
assessment, the reasoning-era postmortem and the SC master plan. Verdict,
quoted: "The shape is careful and trust-safe, but it mostly polishes … The
things that decide the long-term goals — Lean failing where the oracle succeeds
(the aim-1 bugs), the scale ceilings, upstream re-convergence, and real-C
coverage — are all conditional or deferred to Phases 3–4."

Load-bearing premises re-verified by the orchestrator before disposition:
`lean_frontend/lem_sync.sha256` is untracked and `tools/check_lem_sync.sh:45-50`
excludes the Lem version and the Makefile sed patch-ups from its hash;
`scripts/new-worktree.sh:78-84` `cp -a`s the primary's `lean_frontend/generated`
over a new worktree; `scripts/common.sh:396-441` applies a second per-test cap
`CERB_TEST_MEM_MAX` (default 4G) with the OOM classification read from the
cgroup, used by nine lane scripts; C11 §6.2.7#1's alignment-specifier clause is
quoted at `docs/2026-09-15_semantics-audit-repairs-premerge-audit.md:45`;
`CerbGlobal.lean:44-54` assigns `using_concurrency`'s step 2 to the concurrency
branch; the zero-discrepancy memory calls the run-loop rendering mandatory for
the zero-init hang; `SC-CONCURRENCY.md` §3/§4 forbids a long-lived branch
accumulating unaudited features; `arc/sc-wp1` (`af1342d32`) already edits
`frontend/model/driver.lem` (+247) and `core_reduction.lem`, and SC S1 owns the
run loop, initialization/finalization, output streaming, resource accounting
and shared-Lem fork/wait repairs.

| # | Sev | Finding | Disposition |
|---|---|---|---|
| E1 | MAJOR | §10.7's SC fence covers three memory files; the real overlap is configuration, outcome types, run loop, CLI, re-sync and the Lem pin. | APPLIED — §11.5 fence; the note to the SC track (11.6). |
| E2 | MAJOR | "ONE consumer re-pin" either is unneeded (the consumer skips heads) or means a merge hold, which SC's plan forbids and which makes audit ranges huge. | APPLIED — slices merge ff-only when ready; the re-pin is a consumer-note cadence with a diff manifest that includes SC-track changes. |
| E3 | MAJOR | Committing `generated/` doubles every seam diff, is not guarded by the untracked stamp, dirties worktrees via `new-worktree.sh`, still needs `md5.o`, and makes Lem re-pins 5 MB diffs. | APPLIED via the ruling in 11.2 (Q2 revised: a release branch/tag carries `generated/`). |
| E4 | MAJOR | The body is stale against §10. | APPLIED — banner at the top; §11 is authoritative. |
| E5 | MAJOR | CI scope misses `CERB_TEST_MEM_MAX`, OOM classification, fork-drift provisioning and the inherited workflows. | APPLIED — 11.4 CI item. |
| E6 | MINOR | Consumer-dependent decisions lack a fallback. | APPLIED — default "not this cycle", logged [AGENT]. |
| E7 | MINOR | P1c-1 needs a quiet-box window and a per-row bound. | APPLIED — cap each row at 10× its lane timeout; rows hitting it are recorded TIMEOUT-confirmed; the quiet-box window is an operator scheduling item. |
| E8 | MINOR | Prices/classes: P1d-1 is M in an S slice; P1b-1 is harness work, not emission; P3-7 is M–L; P1d-5 is S only after a trial build. | APPLIED in 11.4. |
| E9 | MINOR | Design notes need a named referent (postmortem §2). | APPLIED — each note names its canonical technique (11.4). |
| E10 | NOTE | §10.3 decided shared-model shapes by default. | APPLIED — F-A2's bucket is HELD until the operator confirms; `_Alignas` is re-ruled (11.2). |
| G1 | MAJOR | `_Alignas` is ISO-mandated, so "obviously wrong", not "unsupported". | RULED — 11.2 Q1′. |
| G2 | MAJOR | Moving `defaultFuel`/`defaultAddressSpaceTop` into an importable `Pipeline` breaks the no-magic-values rule. | APPLIED — `Pipeline` takes fuel and top as parameters; the defaults stay in `Main`; the numerals allowlist does not move. |
| G3 | MAJOR | Ordering inverts the four aims: aim-1 bugs (oracle succeeds, Lean fails) sit behind packaging. | RULED — 11.2 Q3′; 11.4 order. |
| G4 | MAJOR | Upstreamability last while deltas accumulate. | APPLIED — fork-delta triage in Phase 1; every new OCaml-side delta classified upstreamable / fork-permanent at landing; re-sync at the next network window. |
| G5 | MAJOR | Nothing moves toward larger real C. | APPLIED — real-C reach census in Phase 1 (P1f-2). |
| G6 | MAJOR | Four fragments of one outcome-taxonomy question (kill reasons, "unsupported", JSON kill class, fuel message, SC's five outcomes). | APPLIED — one outcome-taxonomy note co-owned with SC and the consumer (P1f-4) before P2b-1 or the Q1 refusals are coded. |
| G7 | MINOR | P2b-3's "consumer discharges by evaluation" rationale nears the out-of-policy ban. | APPLIED — the checker is a lane instrument only; the rationale dropped; P2b-6 (`WFfile`) moved to the Q12 explicit-yes list. |
| G8 | MINOR | The plan adds docs/check sprawl. | APPLIED — prune first (history records into `docs/history/`), then one index; the doc `--check`s merge into ONE speedbump script. |
| G9 | NOTE | Part of the stack ceiling is in the Lean runtime; a Lean-level trampoline may not fix it. | APPLIED — P3-2c must test that premise first. |

### 11.2 Operator rulings, 2026-09-27 (second round, verbatim)

[USER 2026-09-27]: "(1) agree, (2) how does the eventual 'requires' line in
lean look? If it's still clean, this is fine. (3) agree, (4) agree, write a note
for them in a worktree"

The four questions put to the operator were: (1) move `_Alignas` to the
bug-fix bucket; (2) publish `generated/` on a release branch only, or commit it
on the mainline with three prerequisites; (3) reorder so oracle-mismatch and
scale bugs precede packaging, with fork-delta triage and the real-C census in
Phase 1; (4) contact the SC track's owner to agree the fence.

- **Q1′ — `_Alignas` is a bug-fix.** `are_compatible_aux` compares member
  alignment specifiers (C11 §6.2.7#1); incompatibility flows through the
  existing path; tray draft first, pristine-register row at landing.
  `aligned_alloc(0, n)` stays a loud "unsupported" refusal (§10.2 Q1). F-A2
  (`_Alignas(struct A)` on a char member) remains HELD pending the operator's
  word on "constraint violation" vs "unsupported" (§10.3).
- **Q2′ — release-branch publication of `generated/`.** [AGENT] reading of "this
  is fine": the orchestrator's recommended option — the mainline keeps
  `generated/` gitignored; a release line (tags `cerberus-lean-v*` on commits
  that add the generated tree) is what a Lean client requires. The client's
  `lakefile.toml`, as shown to the operator:

  ```toml
  [[require]]
  name = "CerberusLean"
  git = "https://github.com/OathTech/cerberus-lean"
  rev = "cerberus-lean-v0.2.0"
  subDir = "lean_frontend"
  ```

  Prerequisite: P2a-2 (the package exports `md5.o`), or the client's link
  fails. The release commit is produced by a script (regenerate, add, tag) and
  checked by a regenerate-and-diff comparison against the tagged source.
  E3's mainline costs do not arise; `new-worktree.sh` is unchanged.
- **Q3′ — reorder.** 11.4.
- **Q4′ — the SC note.** 11.6.

### 11.3 Merge and re-pin cadence

Slices merge ff-only to `mdd/cerberus-lean` as each is ready, on per-merge
sign-off with its audit ask, exactly as today. The consumer re-pins at points
the orchestrator names in a consumer note (a tag on the release line), each
with a diff manifest covering everything since their last pin, SC-track
landings included. Consumer-dependent items (P2b-1 shape (i), P2b-2, P2c-4)
default to "not this cycle" [AGENT] if cerberus-sl has not answered when the
relevant slice is briefed.

### 11.4 The current sequence

IDs refer to §3 unless new. Status: DONE / OPEN / HELD (awaiting a decision) /
FENCED (sequenced against the SC track, 11.5).

**Phase 0 — release (done).** P0-1 DONE (tags verified from anonymous clones,
`9bf8cdaa6`). P0-2 half DONE (final pin = the tag); the Phase-1 consumer note
remains. P0-3 OPEN (deletion list; operator executes). P0-4 = this record.

**Phase 1 — fail-closed debt, diagnostics, and direction-setting documents.**

| Slice | Items | Notes |
|---|---|---|
| 1a instruments | P1a-1 … P1a-12 | P1a-8 (derived counts) folds into the single doc speedbump of 1e. |
| 1b CLI/bridge | P1b-1 (re-classed harness, M), P1b-2, P1b-3, P1b-4 | P1b-1/P1b-2 touch `Main.lean`: FENCED with SC's public-mode flags. |
| 1c measurements + drafts | P1c-1 (per-row cap 10× lane timeout; quiet-box window scheduled by the operator), P1c-2 (+ the `_Alignas` draft now as a bug report), P1c-3, P1c-4 | — |
| 1d lem-lean S | P1d-1 (M), P1d-2 … P1d-9; P1d-5 priced after a 4.32.2 trial build | Lem pin moves are FENCED (11.5 rule). |
| 1e docs | prune first (history records to `docs/history/`), then P1e-1 index, P1e-2 … P1e-6; ONE `--check` speedbump script for counts/index/knobs | — |
| **1f direction (NEW)** | **P1f-1** fork-delta triage (was P4-1, incl. the byte-identity write-up) · **P1f-2** real-C reach census: the pKVM buddy allocator case study, a handful of `deps/linux` `lib/` files and the libxml2 TUs through bridge → elaboration → single-trace run on both engines, report-only, refusals and ceilings ranked by cause · **P1f-3** the two design notes P3-2b (run-loop rendering; referent: defunctionalised interpretation of the monadic combinators inside `run`) and P3-2c (step-runner ceiling; referent: CPS/defunctionalisation to an abstract machine with a kernel-checked equivalence; FIRST test whether the ceiling is in the Lean runtime's `lean_apply_*` frames, which a Lean-level trampoline may not remove) · **P1f-4** outcome-taxonomy note co-owned with the SC track and cerberus-sl: normal / UB / unsupported / blocked / exhausted / fail-stop as typed outcomes a theorem can state; covers P2b-1, the Q1 refusals, the P2a-6 JSON kill class, P1d-6 | S each, M for P1f-2. P1f-3's run-loop note and P1f-4 are FENCED (SC S1 owns the run loop; SC constraint 5 owns the outcome split). |

**Phase 2 — correspondence and scale bugs (aim 1; was Phase 3's core).**

| ID | Item | Status |
|---|---|---|
| P2d-1 | union twin (bug-fix) | OPEN — dispatchable now |
| P2d-3 | `_Alignas` compatibility (bug-fix, Q1′) | OPEN after its tray draft |
| P3-3 | run-loop rendering, if P1f-3's note is approved | FENCED |
| P3-4 | step-runner ceiling, if P1f-3's note yields a proven-equal design | FENCED — likely JOINT with SC S1 |
| P3-5 | `mkListN_aux` measure | OPEN |
| P3-7 | libc-body UB locations (re-priced M–L) | OPEN |
| P2d-2 | `aligned_alloc(0, n)` loud refusal, shaped by P1f-4 | FENCED (touches `CerbMem`) |
| P3-1, P3-2a | benchmark + profile (feed P3-6/P3-8) | OPEN |

**Phase 3 — consumer usefulness (was Phase 2), interleaved with Phase 2 as
slices become ready.** P2a-1 (Pipeline takes fuel/top as parameters; defaults
stay in `Main`), P2a-2 (`md5.o` export — prerequisite of the release line),
P2a-3 as Q2′ (release-line script + regenerate-and-diff check, M), P2a-4,
P2a-5, P2a-6 (after P1f-4); P2b-1 shape (ii) (after P1f-4); P2b-2 FENCED
(SC owns `using_concurrency`; the configuration record is designed with them)
and consumer-gated; P2b-3 as a lane instrument only; P2b-5 as ruled (Q4). The
generated-surface bundle P2c-1 … P2c-7 lands together as one lem pin dance,
FENCED on the Lem pin (P2c-1 touches `CerbMem`); P2c-4 consumer-gated.

**Phase 4 — upstream, coverage, instruments.** P4-2 re-sync at the next network
window, preferably before SC S1 lands broadly (it rebases under the SC branches;
coordinated through 11.5). P4-3 filing (operator). P4-4. P4-5 coverage work now
ORDERED by P1f-2's census rather than by guess. P4-6 after Phase 3 (Q12). P4-7,
P4-8 named deferrals. P4-9, P4-10 as before. P3-6 and P3-8 only on P3-2a's
evidence.

**CI (Q13, re-scoped per E5).** GitHub-hosted, both repositories. The workflow
sets `CERB_MEM_MAX=none` AND `CERB_TEST_MEM_MAX=none` (both loud opt-outs; the
caps stay in the scripts for this shared machine). Without cgroups a lane cannot
witness an OOM kill, so in CI an exit 137 is reported as an unclassified kill
and fails the job; the local cap remains the certifying run for OOM rows.
Provisioning: the README recipe, `scripts/provision_fork_drift_oracle.sh`
(P1a-10) for `CERB_UPSTREAM_TREE`, and a Lake cache. First step: measure the
cold build's peak memory on a hosted runner. Whether to keep or disable the
inherited upstream OCaml/CHERI workflows is an operator choice. Every push of
the workflow needs explicit authorization at the time.

### 11.5 The SC fence (proposal, pending agreement with the SC track)

Surfaces both tracks touch, and the proposed owner of each change:

| Surface | Plan items | SC packages | Proposed rule |
|---|---|---|---|
| `driver.lem`, `core_run*.lem`, `core_reduction.lem`, the run loop | P3-3, P3-4, P1f-3 | WP1 (already +247 lines in `driver.lem`), S1 | SC owns; the plan's scale work is a joint note, landing through S1's review or strictly after S1's landing |
| Outcome / kill-reason types | P2b-1, P2d-2, P2a-6, P1d-6, P1f-4 | S1 exit ("Completion/UB/unsupported/blocked/exhausted are distinct") | one jointly owned note (P1f-4) before either codes |
| `global.lem` / `CerbGlobal` configuration record | P2b-2 | S5 public mode; `using_concurrency` step 2 | SC designs the record's concurrency field; the plan lifts the rest after that design exists |
| `CerbMem.lean`, `mem_common.lem`, `impl_mem.ml` | P2c-1, P2d-2, P2d-4, P3-6 | WP0 landed; S4 object/runtime | each side announces a slice here before starting; landings are sequential |
| `Main.lean` CLI | P1b-1, P1b-2, P2a-1 | S5 public mode flags | the plan lands its CLI work first (it is small and SC's mode is S5); SC rebases |
| The lem-lean pin | P1d, P2c | S1 shared-Lem repairs | one Lem pin dance at a time; whoever starts first holds it until its cerberus re-pin lands; the other rebases |
| Upstream re-sync | P4-2 | all SC branches | scheduled jointly; not during an SC landing |

### 11.6 The note to the SC track

Written as `lean_frontend/docs/2026-09-27_note-to-sc-track-next-phase-coordination.md`
on branch `docs/sc-coordination-20260927` (worktree
`worktrees/cerberus-lean-docs/sc-coordination-20260927`), per [USER 2026-09-27]
"write a note for them in a worktree". It carries 11.5 and asks for agreement or
counter-proposal. Not merged; delivery to the SC track's owner is the operator's.
