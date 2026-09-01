# C2 ratchet + finalization slice record — effect retirement (arc close construction step)

Date: 2026-09-01. Branch `arc/effect-retirement`, worktree
`worktrees/cerberus-lean-arc/effect-retirement`, base `1b40098ed` (C1
close). Worker: C2. Charter: `docs/2026-08-31_effect-retirement-design.md`
@ `64dd6efeb` §7 (deletions + ratchet + plants), §1 (the customer
contract), §8.1 C2, §9 (rulings), as amended by the accepted L2-audit
ratchet legs (lem-lean `doc/lean-backend/2026-09-01_L2-deletion-record.md`
+ addendum). Provenance [AGENT] throughout unless marked [USER]; quoted
outputs verbatim; derived tallies labeled.

Session note: the worker session was TWICE terminated mid-slice by an
infrastructure error (API credit exhaustion; orchestrator-relayed,
resolved both times). Kill 1 landed after the step-2 conversion's
first spot-run: on revival the ground truth was re-established from
git/pin state and every gate relevant to the uncommitted change was
RE-RUN before committing (the step-2 spot-run below is the re-run).
Kill 2 landed mid-close-out-battery (after a green Tier A): per the
resume instruction the FULL battery was re-run FROM THE START on the
final tree — partial pre-kill greens were discarded; §7's results are
entirely from the post-resume run (each interrupted battery chunk
re-run whole, no partial credit taken).

## 1. Commits (each green at its boundary)

| Step | Commit | Content |
|---|---|---|
| 0 | `fb2b0d075` | lem pin bump to the L2 deletion head `045dcb0` (axiom-free LemLib): deps/lem-pinned reset, opam lem rebuild, Lake pins (lakefile + both manifests), fresh rebuilds + byte-compares |
| 2 | `3e75cd5d7` | `CerberusFresh.digest` → kernel-checked opaque (Q4 promoted deliverable) + allowlist PIN population section |
| 1 | `705f6326e` | the gate ratchet: five legs in `check_theorem_axioms.sh`, purity-header update, plants red-green |
| 3 | `42b7586d8` | `check_renumber_only.py` hardening (string/comment holes), committed plant fixtures + `test_renumber_plants.sh` (wired into test_unit), 70-row re-check |
| 4 | `0fedb4d89` | VALIDATION.md/shop-window finalization, upstream-divergence note, C1-F2 → upstream-tray 17, change-manifest C2 addendum, SKIP_BUILD freshness fix + plant |
| close | (this record's commit) | close-out battery + this record |

Step order note: step 2 (the digest conversion) was executed before
step 1 (the ratchet) so that the ratchet's leg-3 population pin could
be written once, against the post-conversion population. [AGENT]
sequencing decision; both steps' gates green at their commits.

## 2. Step 0 — pin bump to the axiom-free lem (`045dcb0`)

- `deps/lem-pinned` fetched + reset `af5df71` → `045dcb0` (L2 deletion
  `faa9fe4` + riders `7e56047` + record `7a4925d` + audit response
  `045dcb0`); shared-switch lem rebuilt (`opam upgrade --switch=.
  --no-depexts lem`, exit 0 — the same [AGENT]-sanctioned in-arc
  shared-state mutation as C1, restore expectation unchanged: the
  arc-close pin dance re-points everything at the merged lem head).
- Lake pins: `lean_frontend/lakefile.toml` rev + root and speclab
  `lake-manifest.json` at `045dcb0d57a171eb4fb3a6eb5abe288c227270ce`
  (`lake update LemLib` in both packages; relsemcore is a lib of the
  root package — no separate manifest).
- **The deletion arriving in the consumer, verified on the consumed
  copy** (`.lake/packages/LemLib` @ `045dcb0`):
  `grep -rnE '^\s*axiom ' lean-lib/ --include='*.lean'` → **0 hits**;
  `runEffectful` tokens only at `LemLib.lean:32-33`, inside the
  charter-mandated HISTORY comment.
- OCaml generated tree: `clean-prelude-src` + re-derive under lem
  `045dcb0` → `diff -qr` vs pre-bump snapshot **byte-identical**
  (sibylfs likewise) — charter §6.4 layer 1 holds; the L2 deletion is
  Lean-target-only.
- Lean generated tree: `rm -rf` + regenerate → **byte-identical**,
  modulo two STALE UNTRACKED arc-7-era files (`CerbCoreInstances.lean`,
  `CerbInhabitedInstances.lean` — DAEMON-era leftovers, imported by
  nothing, absent from the lakefile roots) absent from the fresh
  derivation. [AGENT] disposition: stale artifacts, correctly dropped
  by the clean re-derivation.
- Oracle rebuilt `DUNE_CACHE=disabled` (driver +
  `cerberus-lib.install` + `dune install cerberus-lib` +
  `cerberus.install`), exits 0; Lean rebuilt fresh (capped 32G): root
  365 jobs, speclab 137 jobs, `lean-native-obj` + relink.
- Quick gates: `test_unit.sh` exit 0; exec minimal `BASELINE OK` exit 0.

## 3. Step 2 — digest → kernel-checked opaque (commit `3e75cd5d7`)

The last `unsafeBaseIO` of the C2-convert class leaves. New chain
(the forceIO/with_tagDefs pattern exactly):

```lean
@[extern "cerb_digest_get", never_extract, noinline]
private unsafe opaque digestPure : @& Unit → String :=
  fun _ => ""  -- explicit witness (C2): the C global's initial value

@[never_extract, noinline]
private unsafe def digest_impl (_ : Unit) : String :=
  digestPure ()

@[implemented_by digest_impl]
opaque digest : Unit → String :=
  fun _ => ""  -- explicit witness (C2), kernel-checked
attribute [never_extract] digest
```

No new C code: under the ≥4.29 world-erased calling convention
`cerb_digest_get` already has the pure-extern shape (one unit arg,
direct string result), so the same symbol backs both `digestIO`
(BaseIO, kept for hand-written callers) and `digestPure`.

**The L2-audit armor lesson applied** (L2 record addendum F1:
closed-term extraction reaches THROUGH outer attributes): the INNER
extern `digestPure` itself carries `never_extract, noinline`, so the
closed application `digestPure ()` inside `digest_impl` cannot be
extracted into a module-init constant (which would freeze the pre-set
`""` digest — the exact tickPair vacuity shape). The in-file docstring
carries the armor-placement rationale with the L2 cite.

**Differential spot-run — byte-identical pre/post** (pre captured on
the committed step-0 binary; post RE-RUN after the session revival on
a fresh rebuild):

- `fresh-int-test` (supply threading laws + RFC 1321 md5 vectors +
  `testDigestGlobal`, the per-TU pickup probe under two `setDigestIO`
  sites — the exact anti-freeze behavioral witness): `4 passed, 0
  failed`, output byte-identical pre/post.
- `test_multi_tu.sh` (digest-differentiated TUs;
  `from_same_translation_unit` live): verbatim rows both sides
  `[1] MATCH basic: 31 execution(s), VAL:Specified(42)` /
  `[2] MATCH tentative: 1 execution(s), VAL:Specified(42)` /
  `SUMMARY: total=2 match=2 fail=0`; the only differing lines in the
  raw logs are dune's sandbox parent-directory probe warnings in the
  lane preamble (invocation-cwd noise; both runs exit 0).

Allowlist updated in the same commit: the digest row moved to the
CONVERTED section; the machine-readable `PIN` population section
added (leg-3 input; 61 rows).

## 4. Step 1 — the gate ratchet (commit `705f6326e`)

`check_theorem_axioms.sh` gains the five C2 legs (charter §7.2 as
amended by the accepted L2-audit legs; source-scan census = PRIMARY
evidence, kernel probes = spot checks, per the §7.2
partial-def-opacity caveat — stated in the gate's own header). Green
at HEAD, verbatim:

```
check_theorem_axioms: C2 ratchet OK (290 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 61 pinned rows exactly; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
```

Leg inventory (each fail-closed on missing dir / empty input):

1. **LemLib recursive zero-axiom census** — comment-stripped scan of
   `.lake/packages/LemLib/lean-lib/**/*.lean`; the file list must
   contain `lean-lib/LemLib/` subdirectory entries (a flat-glob
   regression is loud, charter A3); the L2 HISTORY comment does not
   trip (the DAEMON-precedent adjudication the L2 record flagged —
   ruled here [AGENT]: comment-strip, matching the axiom census
   discipline).
2. **`runEffectful` token ban** — comment-stripped, over the LemLib
   copy + `generated/` + all hand-written lean_frontend sources
   (test/relsemcore/speclab included; `.lake` trees excluded).
3. **Seam-population pin** — the census of `@[implemented_by]`
   targets, `unsafe def/opaque/abbrev/...` declarations, and
   `unsafeBaseIO` occurrences (keyed by enclosing declaration) must
   equal the allowlist PIN rows exactly, BOTH directions; stray
   non-declaration `unsafe` tokens fail. LemLib survivors:
   `failwithIImpl` + `fuelExhaustedWithImpl` (the L2 record's
   enumerated pair); cerberus survivors per the Q4 classes. This is
   the leg banning axiom-free reintroduction of the effect projection
   via opaque + implemented_by + unsafeBaseIO (the L2 audit's
   accepted proposal).
4. **Ban-surface assertion** — the lem tests/ scaffolds are outside
   the surface DELIBERATELY (they hand-write unsafe externs by
   design: `TupleLetTick.lean`, the m7 pin). Asserted, not assumed:
   the package clone must contain `tests/comprehensive` WITH ≥1
   would-trip token, and the scan list must reach nothing under the
   package outside `lean-lib/`.
5. **Exec-entry exact census** — the full §1.3 entry set (`driver2`,
   `drive`, `initial_driver_state`, `desugar`, `annotate_program`,
   `translate`, `link`, `convert_file`, `RelSem.Cerb.callND`; 9
   probes = C1's 8 + callND re-included), exact allowlist
   `[propext, Classical.choice, Quot.sound]`, per-probe fail-closed.

`check_exec_purity.sh`'s boundary-honesty header updated to the
shrunk seam list (§7.2 last item).

### 4.1 Plants (each executed, red observed, reverted, green re-verified)

**P2** (generated census, standing plant re-run) — scratch axiom in
`generated/Core_indet.lean`:

```
check_theorem_axioms: FAIL — generated-tree census: axiom declaration(s) found (allowlist is EMPTY since arc-17 S2b — with_tagDefs/forceIO are opaques now; any axiom must be deliberately registered here):
AXIOM Core_indet.lean:44:c2PlantGenAx
```

**P3** (recursive LemLib census, BOTH positions) — top-level:

```
check_theorem_axioms: FAIL — C2 ratchet leg 1: axiom declaration(s) on the zero-axiom surface (LemLib declares ZERO axioms since L2; cerberus since arc-17 S2b):
AXIOM lean_frontend/.lake/packages/LemLib/lean-lib/LemLib.lean:1031:c2PlantLemAx
```

and the SUBDIRECTORY case (the flat-glob regression scenario):

```
AXIOM lean_frontend/.lake/packages/LemLib/lean-lib/LemLib/Num.lean:1395:c2PlantSubdirAx
```

**runEffectful token, non-comment position** — in
`generated/Symbol.lean` (`#check runEffectful` appended):

```
check_theorem_axioms: FAIL — C2 ratchet leg 2: runEffectful token in non-comment position (the effect projection was DELETED by the effect-retirement arc; charter section 7):
RUNEFF lean_frontend/generated/Symbol.lean:360
```

and in the LemLib copy (`def runEffectful ...` in `LemLib/Num.lean`):
`RUNEFF lean_frontend/.lake/packages/LemLib/lean-lib/LemLib/Num.lean:1395`.
CONTROL: with no plant, the L2 HISTORY comment (LemLib.lean:32-33,
naming `runEffectful` twice) produces 0 FAILs — the comment-strip
adjudication works.

**Leg-3 new-pair plant** — an `unsafe def` + `unsafeBaseIO` +
`@[implemented_by]` triple appended to hand-written `CerbUtils.lean`:

```
check_theorem_axioms: FAIL — C2 ratchet leg 3: NEW implemented_by/unsafe/unsafeBaseIO site(s) not in the pinned population (scripts/unsafebaseio_allowlist.txt PIN rows). Every such seam is a declared-boundary decision — register it there with its Q4 class, or remove it:
IMPLBY CerbUtils.lean c2PlantImpl
UNSAFEBASEIO CerbUtils.lean c2PlantImpl
UNSAFEDECL CerbUtils.lean c2PlantImpl
  at lean_frontend/CerbUtils.lean:191
  at lean_frontend/CerbUtils.lean:190
  at lean_frontend/CerbUtils.lean:190
```

**Vacuity plants** (empty-input → red NOT green, each with its named
message): (a) LemLib `lean-lib` dir moved away →
`FAIL — C2 ratchet: lean_frontend/.lake/packages/LemLib/lean-lib missing (fail-closed; is the LemLib package materialized?)`;
(b) dir present but empty →
`FAIL — C2 ratchet: recursive LemLib file list is EMPTY (fail-closed)`;
(c) allowlist stripped of PIN rows →
`FAIL — C2 ratchet leg 3: no PIN rows in scripts/unsafebaseio_allowlist.txt (fail-closed; the population pin has no input)`;
(d) allowlist file missing →
`FAIL — C2 ratchet: scripts/unsafebaseio_allowlist.txt missing (fail-closed; leg 3 has no pin input)`.
Finding during planting, fixed in the same commit: trip (c) was
fail-closed but SILENT as first written (`set -e` killed the
`grep | awk | sort` pipeline before the message) — made fail-NOISY
with `|| true` on the two grep pipelines; the quoted messages above
are from the fixed script.

**P5** (entry-cone axiom) — `axiom c2PlantEntryAx : True` planted into
`generated/Driver.lean` with `driver2`'s body made to depend on it
(`have _ : True := c2PlantEntryAx; ...`), Driver rebuilt. Full gate:
red at the PRIMARY census leg (`AXIOM Driver.lean:386:c2PlantEntryAx`
— defense in depth: an in-repo axiom cannot reach leg 5 because the
source-scan legs fire first, which is the designed layering). Leg 5's
own detection verified independently on the same planted tree — probe
verbatim:

```
'driver2' depends on axioms: [c2PlantEntryAx, propext, Classical.choice, Quot.sound]
LEG5-PARSE VERDICT: FAIL — driver2: c2PlantEntryAx
```

(the gate's exact-allowlist parse block run standalone over the probe
output). Reverted, rebuilt, full gate green.

**P1** (as amended by the L2 refusal decision — generation-time
refusal, not parse error; the lem suite carries it forever as
`negative/neg_effectful_retired.lem`) — re-executed here against the
INSTALLED lem @ `045dcb0` on a scratch `.lem`, exit 1, verbatim:

```
Error: Lean backend: val scratch_counter — 'declare {lean} effectful' is retired on the lean target; use supply lifting instead ('declare {lean} supply val', the deterministic state-passing transform). The library's effect-projection axiom and the call-site wrap were deleted by the effect-retirement arc (charter: cerberus-lean lean_frontend/docs/2026-08-31_effect-retirement-design.md @64dd6efeb, section 7.1)
```

**P4** (G-λ) — the suite's own `neg_supply_lambda.lem` run against
the installed lem, exit 1, verbatim:

```
Error: Lean backend: supply draw (or supply-lifted call) under a lambda (unsupported: a linear supply cannot be captured by a closure — restructure so the draw happens outside the lambda, or thread the state explicitly in the model)
  original input: "fun x -> x + tick ()"
```

## 5. Step 3 — check_renumber_only.py hardening (commit `42b7586d8`)

Route decision [AGENT] (the brief left it open): **string-aware +
comment-aware canonicalization**, not refuse-preconditions — detecting
the precondition needs the same lexer anyway, and this route keeps
legitimately-renumbered artifacts adjudicable while STRICTLY
TIGHTENING both legs (the gate only ever admits, never excuses).
Mechanics: inputs lex into CODE / STRING / `--`-COMMENT segments;
strings compare VERBATIM on both legs (closes s5 + l1); comments are
id-canonicalized but ATOMIC tokens on the LAYOUT leg (whitespace never
collapses across a comment's terminating newline — closes l3/l4);
unterminated strings refuse loudly. The :47-48 over-claiming docstring
is rewritten to state exactly what each leg guarantees.

**Hole demonstration** (the four adversarial pairs against the
PRE-hardening script — each wrongly ADMITTED, proving the fixtures
realize the audit's holes; content reconstructed [AGENT] from the C2
brief's hole descriptions, the audit's own pair files not being
committed):

```
RENUMBER-ONLY ADMIT old-script/s5_string_content class=STRICT ids=2 moved=2 canon=e5f6a72ca44e
RENUMBER-ONLY ADMIT old-script/l1_string_ws class=LAYOUT ids=1 moved=1 canon=dc9e5ac43cf1
RENUMBER-ONLY ADMIT old-script/l3_comment_absorb class=LAYOUT ids=1 moved=0 canon=16134bd21ab0
RENUMBER-ONLY ADMIT old-script/l4_comment_release class=LAYOUT ids=1 moved=0 canon=7d013db193a5
```

Against the hardened script all four REFUSE; committed as
`tests/renumber_plants/` (+ the re-committed C1-era plants: count
mismatch, appended line, token change, section reorder; + two
positive ADMIT controls as vacuity guards), run by
`scripts/test_renumber_plants.sh`, wired into `test_unit.sh` forever.
Battery verbatim:
`test_renumber_plants: OK (10 plants: refusals refuse, admits admit with declared class)`.

**The 70-row re-check** (every C1-admitted row re-adjudicated under
the hardened instrument):

- 64 text-pinned rows (7 verify + 7 corpus text + 7 corpus funs + 39
  speclab + 1 libc.core + 3 goldens), old/new extracted from the C1
  family commits (`<commit>^` vs `<commit>`): **64/64 ADMIT, 43
  STRICT / 21 LAYOUT**; `ids=`/`moved=` identical to the C1 evidence
  rows on every row; `canon=` identical on every STRICT row (LAYOUT
  canon digests differ by design — the compared form is now the
  segmented token stream).
- 6 content-hash rows (p04/p05/p06/p07/p08/p15): predecessors
  RECONSTRUCTED by rebuilding the pre-C1 oracle at `90c82505d` (temp
  worktree, regenerated + `DUNE_CACHE=disabled`) — **RECON-OK 6/6**
  vs the pre-rebaseline sha256 pins; successors derived from the
  current oracle — **NEW-OK 6/6** vs the committed pins; hardened
  checker verbatim (ids/moved/canon EXACTLY the C1 rows):

```
RENUMBER-ONLY ADMIT corpus/p04_arr_sum.core.sha256 class=STRICT ids=150 moved=19 canon=998132ac77ba
RENUMBER-ONLY ADMIT corpus/p05_find_first.core.sha256 class=STRICT ids=162 moved=18 canon=e9e36d8664a5
RENUMBER-ONLY ADMIT corpus/p06_arr_reverse.core.sha256 class=STRICT ids=238 moved=86 canon=10cf9cfbd970
RENUMBER-ONLY ADMIT corpus/p07_list_sum.core.sha256 class=STRICT ids=181 moved=21 canon=a228bb7f361b
RENUMBER-ONLY ADMIT corpus/p08_list_reverse.core.sha256 class=STRICT ids=263 moved=121 canon=1b24503f01c7
RENUMBER-ONLY ADMIT corpus/p15_scan_classify.core.sha256 class=STRICT ids=151 moved=8 canon=215ecf769e38
```

**DERIVED TALLY: 70 rows re-checked, 70 ADMIT (49 STRICT / 21
LAYOUT), verdicts unchanged vs C1, 0 findings.**

## 6. Step 4 — finalization (commit `0fedb4d89`)

Per the step-4 commit message (authoritative list): VALIDATION.md
(gate rows rewritten; the tolerated-renumbering upstream-divergence
note; the §5 boundary story — zero axioms anywhere as the headline,
the Q4-classified survivor seams, CerbFS + CerbDebug stubs +
concurrency stubs as the remaining declared model boundary; the
customer-contract acceptance statement, §1.3 universal form, declared
**MET** with the gate as enforcement); DESIGN.md effects paragraph;
README trust sentence; lean_frontend/CLAUDE.md boundary line; TODO.md
effect-axiom row closed; the effect-erasure invariant page
scope-shrink addendum (charter §7.1); fork-drift manifest header note
finalized (gate item (c)); the C1 change manifest's C2 addendum
(recipient: refined-cerberus); **finding C1-F2 registered where
findings live**: upstream-tray draft `17-diagnostic-embeds-symbol-id.md`
+ INDEX row (TRUE BUG minor; `core_run.lem:69`).

**SKIP_BUILD note closed** (S fix, C1-audit note-2):
`verify_skip_build_freshness` in `common.sh` (both lem-sync stamps,
fail-closed) called from all six SKIP_BUILD entry points. Plant
verbatim: fresh stamps → lane green (`BASELINE OK`, exit 0); a `.lem`
source edited under `SKIP_BUILD=1` →
`Error: SKIP_BUILD=1 but the OCaml lem-sync stamp check failed (stale generated tree / stale driver hazard — rebuild, don't skip)`,
exit 1; reverted → green.

## 7. Close-out battery (final tree; capped/ce; exits verbatim)

(Grind-rule note, written before launch: the csmith corpus and gcc
lane passes are measurement sweeps over differential corpora — the
sanctioned >1hr category — run sharded per the brief.)

All binaries fresh from this session: oracle DUNE_CACHE=disabled from
the re-derived generated tree (byte-identity vs pre-bump verified at
step 0); Lean full capped rebuilds; freshness stamps green (and now
enforced in every SKIP_BUILD lane).

**Tier A (all exit 0):** unit=0 exec_minimal=0 exec_coverage=0
exec_debug=0 exec_float=0 bytes=0 libc_exec=0 multi_tu=0 parse=0
core=0 elab=0 libxml2_uri=0 cn_coverage=0.
Verbatim: coverage/debug `Baseline check: 0 regression(s), 0
improvement(s)`; elab
`SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0`
(recorded state); uri `GATE PASS: all lane expectations pinned-green
+ baseline unchanged (16/16)`. test_unit includes the full ratcheted
gate — verbatim:

```
check_theorem_axioms: C2 ratchet OK (290 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 61 pinned rows exactly; lem tests/ scaffolds asserted outside the surface)
check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])
test_renumber_plants: OK (10 plants: refusals refuse, admits admit with declared class)
```

and the entry census, verbatim (all 9):

```
'driver2' depends on axioms: [propext, Classical.choice, Quot.sound]
'drive' depends on axioms: [propext, Classical.choice, Quot.sound]
'initial_driver_state' depends on axioms: [propext, Classical.choice, Quot.sound]
'desugar' depends on axioms: [propext, Classical.choice, Quot.sound]
'annotate_program' depends on axioms: [propext, Classical.choice, Quot.sound]
'translate' depends on axioms: [propext, Classical.choice, Quot.sound]
'link' depends on axioms: [propext, Classical.choice, Quot.sound]
'convert_file' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.callND' depends on axioms: [propext, Classical.choice, Quot.sound]
```

**Tier B (all exit 0):** libxml2_full=0 — verbatim
`SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)`;
parse_ci=0; core_ci=0; verify=0 — verbatim
`test_verify: 117 passed, 0 failed (23 fixtures, 22 call points, 14
corpus fixtures, 21 corpus points)`; immaculate=0 (incl. the
union-arm witness, verbatim
`MATCH offsetof-union-member O[CRASH] L[CRASH]` — risk R5 green — and
the illtyped-store probe legs); speclab selftest=0 plant=0 +
divmod/bytearr/list/tree/seed gates all =0.

**Second-oracle gcc lane** (exit 0), verbatim — baseline UNMOVED
(byte-identical to the C1 close-out summary):

```
SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=7 skip_lean_timeout=11 skip_oracle=3 skip_ub=43 triaged_addr=9
```

**Tier C:** csmith corpus, all 6 shards
`--check-baseline --shard k/6`: `BASELINE OK`, exit 0, k=1..6 (1669
files total; two background-runner kills at the harness's task
ceiling interrupted shard 2 and then shard 3 mid-run — each
interrupted shard re-run WHOLE, no partial credit, exactly the C1
precedent); ci scoreboard
no-regression probe
(`--check-baseline=scripts/exec_ci_baseline.txt tests/ci`): exit 0,
`Baseline check: 0 regression(s), 0 improvement(s)`.

**Final plant confirmation at the close-out tree:** the renumber
plant battery re-run standalone (verbatim above, OK 10/10) and the P1
refusal probe re-run against the installed lem (refusal message
re-observed verbatim).

**Movement: NONE.** No baseline, pin, or recorded state moved in this
slice — as briefed (the slice adds gates and converts one opaque);
the stop-and-report condition never fired.

## 8. Pin / worktree state at close

- `deps/lem-pinned` @ `045dcb0` = opam lem source = Lake pins (root +
  speclab manifests) = the lem arc branch head. Branch heads = opam
  pin = Lake pin; the arc's pin-dance close condition holds at the
  worktree level (the ff-merge itself is the operator's, per the
  standing rules — NO merge, NO push performed).
- The `.c2-scratch/` container dir (snapshots, battery logs, probe
  files, the reconstructed predecessor dumps, the pre-C1 temp
  worktree — removed) is ephemeral and deleted at slice end; every
  load-bearing output is quoted verbatim here or committed.

## 9. Deviations / adjudications ([AGENT] unless marked)

1. Step order 0→2→1→3→4 (conversion before ratchet), §1 note.
2. The two stale untracked generated-tree files dropped at step 0
   (§2) — disposition recorded, nothing referenced them.
3. P1/P5 plant semantics follow the L2 refusal decision and the
   census-first layering respectively (§4.1) — both are the charter's
   plants as amended by the accepted L2 records, quoted with their
   actual firing legs.
4. The s5/l1/l3/l4 fixture CONTENT is an [AGENT] reconstruction from
   the brief's hole descriptions (the audit's pair files are not
   in-repo); each is demonstrated to realize its hole against the
   pre-hardening script (§5).
5. The leg-3 silent-vs-noisy fail-closed fix (§4.1 vacuity plant c)
   was folded into the step-1 commit with the plant that found it.
6. LAYOUT-class canon digests are not comparable across the step-3
   hardening (serialization changed); STRICT digests are, and were
   verified identical (§5).

---

## Addendum (audit response, 2026-09-01): the C2 fresh audit's two MAJOR fail-open gaps fixed + minors

[AGENT] (C2 worker, responding to the C2 fresh audit — verdict
MERGE-SAFE-WITH-NOTES with two MAJOR fail-open findings demonstrated
live, orchestrator-relayed; fix-pre-merge ruling [AGENT,
orchestrator]: the ratchet is the contract's enforcement, a fail-open
gate is a defect as such). One audit-response commit.

### MAJOR-1 (fail-open): non-ASCII declaration names invisible to the censuses — FIXED

The name class `[A-Za-z_0-9α-ω.']+` required ≥1 matching character,
so `axiom «auditEvil» : False` made the WHOLE regex fail and the
axiom invisible to ratchet leg 1 AND the generated-tree census (the
auditor elaborated a `False` theorem from it in the project toolchain
— a live fail-open demonstration; the legacy `^axiom` grep only sees
line-anchored spellings). Fix: every load-bearing keyword match fires
on the KEYWORD alone (`\baxiom\b`, name report-only `\S+`); the
IMPLBY/UNSAFEDECL/DECL name captures widened to `[^\s\]\[,:(){}]+` so
a non-ASCII name still PRODUCES a census row (which then mismatches
the ASCII pin set and fails) instead of defeating the match.

Plants (each red observed verbatim, reverted, green re-verified):

- indented `  axiom «auditEvil» : False` in hand-written
  CerbUtils.lean (invisible to the legacy line-anchored grep — the
  audited shape):
  `AXIOM lean_frontend/CerbUtils.lean:190:«auditEvil»` (leg 1 red);
- same shape in generated/Core_indet.lean:
  `AXIOM Core_indet.lean:44:«auditEvil»` (generated census red);
- ASCII control `axiom c2AsciiCtrl : True` still red;
- non-ASCII implemented_by target `@[implemented_by «evilImpl»]`:
  leg 3 red naming `IMPLBY lean_frontend/CerbUtils.lean «evilImpl» 1`.

### MAJOR-2 (fail-open): the bare-@[extern] class was outside the population pin — FIXED

A non-unsafe `@[extern "sym"] opaque` (exactly the existing
digestIO/setDigestIO/md5Hex shape) passed the leg-3 pin. Fix: an
EXTERN row kind joins the scanner (attribute-tolerant regex over
stacked attribute blocks + modifier prefixes) and the pin; a
catch-all fails any ATTRIBUTE-position `extern` not consumed by a
pinnable declaration match (covers the `attribute [extern ...]`
spelling; the catch-all is attribute-scoped because bare `extern` is
also a legitimate model identifier — the Core file record's `extern`
field — which a token-level ban would false-positive on, measured:
21 identifier sites). Pinned extern population (all
CerberusFresh.lean, count 2 = hand-written + generated copy): `md5Hex`
(pure MD5 extern), `digestIO`/`setDigestIO` (BaseIO digest externs,
honest IO signatures), `digestPure`/`forceThunkIO` (the
kernel-checked opaque chains' inner externs). Zero externs elsewhere
(LemLib copy included), scan-verified.

Plants: `@[extern "c2_plant_sym"] opaque c2PlantExtern` → leg 3 red
naming `EXTERN lean_frontend/CerbUtils.lean c2PlantExtern 1`;
`attribute [extern "c2_plant_sym2"] c2PlantExtern2` → red
`EXTERNOTHER lean_frontend/CerbUtils.lean - ...:191`.

### minor-1: pin keys path-qualified + counted — FIXED

Old keying was basename + set semantics (a pinned pair reappearing
from a different directory was invisible — auditor's plantsub demo).
PIN rows are now `PIN KIND PATH NAME COUNT` with normalized
path-qualified keys (generated/ copies fold onto their hand-written
source at count 2; the LemLib copy onto `lem-lean/lean-lib/` at count
1); malformed rows fail; the census compares at exact counts. 66 rows
(61 prior + 5 EXTERN). Plants, both directions:
`lean_frontend/plantsub/CerbGlobal.lean` reusing the pinned
confRef pair → red naming the path-qualified rows at count 1; a
duplicate `logRef` occurrence in the hand-written file → red
(`UNSAFEDECL lean_frontend/CerbUtils.lean logRef 3` vs pinned 2, all
six sites listed).

### minor-3: check_renumber_only.py CRLF — FIXED, ruling [AGENT]

Universal-newline reads translated `\r\n`→`\n`, so a full CRLF
rewrite (including INSIDE string literals) admitted as STRICT,
contradicting the strings-verbatim docstring. Fix: `newline=''` both
sides. Ruling [AGENT] on the residual class: CR inside a STRING
refuses (verbatim contract); a pure code/comment-side CRLF rewrite
admits as class=LAYOUT, never STRICT — it is a whitespace-only layout
change (tokens, strings, comment extents, emission order all still
required identical) and the LAYOUT class in the evidence row surfaces
it for review. Comment tokens additionally strip boundary whitespace
(a `\r` before the comment-terminating `\n` is layout, not content).
Docstring corrected. New committed fixtures: `crlf_string`
(CRLF inside a multi-line string literal → REFUSE; note the fixture's
string must itself span a newline — the first attempt with a
single-line string correctly admitted LAYOUT, since no string byte
changed) and `crlf_code` (string-free CRLF rewrite + consistent
renumber → ADMIT class=LAYOUT). Battery now 12 plants, verbatim:
`test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)`.

### minor-2: the improvement-asymmetry claim + the gcc topology row — RECONCILED (record-integrity correction)

VALIDATION.md §2 claimed baselines fail closed in both directions
universally; `test_gcc_oracle.sh` fails on regressions only and
surfaces improvements loudly at rc 0 (the lane's own audited design).
The sentence now states the exec-lane rule and the gcc-lane exception
with its rationale.

Topology note surfaced by the audit (registered here as a CORRECTION
to the C1/C2 records' "baseline UNMOVED" phrasing), **as corrected by
the delta audit — this paragraph is a correction-of-a-correction**:
this addendum's first version misstated the arithmetic ("becomes
agree=1872/skip_lean_crash=8 post-rebase" and "does not appear in
this branch's runs" — both WRONG). Measured reality (delta audit +
worker re-measurement agree): the `offsetof-nested-struct` flip
SKIP_LEAN_CRASH→AGREE is ALREADY inside the printed
`agree=1871 ... skip_lean_crash=9` — the SUMMARY counts CURRENT
actuals, and the Lean side already returns
`Defined {value: "Specified(0)", ...}` on that file at this tree
(worker-re-measured via the lane's own oracle-cabs-json →
`cerberus-lean --batch` path; the immaculate lane's committed
baseline row 65 `offsetof-nested-struct MATCH | L=VAL:Specified(0)`
says the same). What is STALE is the baseline FILE row
(`scripts/gcc_oracle_baseline.txt:1847
tests/immaculate/nolibc/offsetof-nested-struct.c SKIP_LEAN_CRASH`),
and the visible signature in this branch's runs is the per-row check:
`improvement: ...` +
`Baseline check: 0 regression(s), 1 improvement(s)` at rc 0 (the
lane's audited improvements-warn design). Post-rebase expectation:
the SUMMARY **stays** `agree=1871/skip_lean_crash=9` and the
improvement line DISAPPEARS when the mainline-sanctioned baseline-row
re-record (the trust-basket regen, mainline `df63018e3`) reconciles.
The C1/C2 phrasing "baseline UNMOVED" is corrected to: **the SUMMARY
actuals are unmoved; one stale baseline-FILE row
(offsetof-nested-struct) is surfaced as the lane's standing
improvement warning, reconciling at the arc-close rebase.**

### Notes registered (no code this slice)

- **Lake dependency-set pin (follow-up, TODO.md):** no gate asserts
  the lake-manifest package set (a future `require` joins the built
  surface outside every census), and the shared packagesDir can carry
  stale non-manifest package dirs; a manifest-driven package-set leg
  is the named follow-up.
- Leg 4's third assertion is tautological today (the list is built by
  find over lean-lib/) — kept as a guard on future list-construction
  edits, annotated in-script.
- The legacy line-anchored `^axiom` hand-written census is redundant
  with ratchet leg 1 — kept as an independent cheap tripwire,
  annotated in-script.

### Re-verification at the audit-response tree (exits verbatim)

- Ratcheted gate green, verbatim:
  `check_theorem_axioms: C2 ratchet OK (290 files scanned recursively: 0 axioms, 0 runEffectful, seam population = the 66 pinned path-qualified counted rows exactly incl. the extern class; lem tests/ scaffolds asserted outside the surface)`;
  `check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆ [propext, Classical.choice, Quot.sound])`.
- Instrument plant battery:
  `test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)` (wired in test_unit).
- **The 70-row re-check re-run under the audit-fixed instrument:
  70/70 ADMIT (49 STRICT / 21 LAYOUT), ids/moved identical to the C1
  evidence rows on every row, STRICT canon digests identical**
  (predecessors for the 6 hash rows re-reconstructed: pre-C1 oracle
  rebuilt at `90c82505d`, RECON-OK 6/6; successors NEW-OK 6/6; the 6
  checker rows byte-identical to §5's).
- Full Tier A re-run: 13/13 exit 0 (unit, exec minimal/coverage/
  debug/float, bytes, libc_exec, multi_tu, parse, core, elab,
  libxml2_uri `GATE PASS ... (16/16)`, cn_coverage).
- gcc second-oracle lane: exit 0, SUMMARY verbatim
  `SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=7 skip_lean_timeout=11 skip_oracle=3 skip_ub=43 triaged_addr=9`
  — SUMMARY actuals unmoved (the offsetof-nested-struct row is
  already AGREE inside these actuals; the stale baseline-FILE row
  surfaces as the lane's standing rc-0 improvement warning — see the
  corrected minor-2 note above).

---

## Addendum 2 (delta-audit response, 2026-09-01): the residual IMPLBY asymmetry closed

[AGENT] (C2 worker; the delta audit of `04dffcc9d` returned NOT-CLEAR
on one residual MAJOR-class hole — the MAJOR-1 fix was asymmetric).
One commit.

**The hole:** the IMPLBY census still required whitespace after the
keyword (`\bimplemented_by\s+NAME`), so `@[implemented_by«name»]` —
NO whitespace — escaped the census entirely while axiom got
keyword-alone matching and extern/unsafe got catch-alls. The spelling
is LIVE Lean (worker re-verified on the project toolchain 4.32.2:
`@[implemented_by«realImpl»] opaque probeA : Unit → Nat` with
`def realImpl (_ : Unit) : Nat := 42` compiles and `#eval probeA ()`
returns **42** — a working behavior redirect). The
`attribute [implemented_by ...]` spelling was probed too: it
ELABORATES (exit 0) but is behaviorally INERT post-hoc on 4.32.2
(`#eval` returns the opaque's default 0, not the impl's 43) — banned
anyway (a future toolchain might honor it, and the token has no
honest reason to appear outside the pinned forms).

**The fix (symmetric now):** the IMPLBY emission takes OPTIONAL
whitespace (`\bimplemented_by\b\s*` + the wide name class), and an
attribute-position IMPLBYOTHER catch-all mirrors EXTERNOTHER — any
`@[...implemented_by...]` / `attribute [...implemented_by...]` block
not consumed by a pinnable IMPLBY census match fails naming itself.
Every implemented_by attribute occurrence is now either a pinned
IMPLBY row or a red IMPLBYOTHER.

**Plants (each red verbatim, reverted, clean-tree green):**

- the auditor's exact shape (`def realImpl ...` +
  `@[implemented_by«realImpl»] opaque c2PlantIB2 : Unit → Nat` in
  hand-written CerbUtils.lean):
  `IMPLBY lean_frontend/CerbUtils.lean «realImpl» 1` — leg 3 red
  (population mismatch, the no-whitespace census row now fires);
- the `attribute [implemented_by realImpl2] c2PlantIB3` spelling:
  `IMPLBY lean_frontend/CerbUtils.lean realImpl2 1` — leg 3 red (the
  keyword+optional-ws emission fires inside the attribute block; red
  via the census row, with IMPLBYOTHER as the net behind it);
- IMPLBYOTHER leg vacuity-tested with the degenerate
  `@[implemented_by]` (no target — name capture cannot fire):
  `IMPLBYOTHER lean_frontend/CerbUtils.lean - lean_frontend/CerbUtils.lean:190`
  — its own red message, proving the catch-all leg is live.

**Erratum to Addendum 1's minor-2 note (correction-of-a-correction,
provenance in place):** the topology arithmetic is corrected in the
minor-2 section above — the flip is already inside the printed
SUMMARY actuals (worker re-measured the row's current Lean behavior
directly), the stale artifact is the baseline FILE row
(`gcc_oracle_baseline.txt:1847`), the visible signature is the rc-0
`Baseline check: 0 regression(s), 1 improvement(s)` warning, and the
post-rebase expectation is an UNCHANGED summary with the warning
disappearing — not "1872/8".

**Registered (TODO.md, beside the Lake-pin follow-up):** the census
stripper does not know Lean raw string literals (`r#"..."#`); zero
exist on the scanned surface today (grep-verified); stripper
hardening or a raw-string ban probe is the named follow-up.

**Close-out at this tree:** full ratcheted gate green (verbatim
below) + `test_unit.sh` exit 0.

---

## Addendum 3 (arc-close rebase, 2026-09-01): rebase onto the trust-basket mainline `df63018e3`

[AGENT] (rebase worker; the ff-merge itself remains the operator's —
NO merge, NO push performed). The arc (26 commits, based
`58ec50779`, old tip `d0165cfed`) was rebased onto mainline
`df63018e3` (the 9-commit trust-basket slice + the sanctioned gcc
baseline regeneration). New tip after rebase: `7a9fec9e2` (26
commits, count preserved); this record commit rides on top.

### Conflict log

`git rebase df63018e3` completed with ZERO textual conflicts. The
file-overlap audit (not assumed from the clean rebase): the
intersection of basket-touched and arc-touched file sets is exactly
one file, `scripts/common.sh`, which git auto-merged; the merged
result was reviewed line-by-line and carries BOTH intents:

- basket side (items a/d): `build_cerberus`/`build_lean` gate on the
  build's exit status; driver-freshness stamps recorded on success
  (`tools/check_driver_fresh.sh --record-*`); the `SKIP_BUILD=1`
  driver-stamp check block (`--check-oracle`/`--check-lean`);
- C2 side: `verify_skip_build_freshness` (both lem-sync stamps,
  fail-closed) — still defined and still invoked by all 6 lanes
  (`test_exec.sh`, `test_ci_sweep.sh`, `test_speclab{,_list,_seed,
  _tree}.sh`).

Non-conflicts by construction, verified: `lean_frontend/CerbFS.lean`
was never touched by the arc — the basket's fail-closed refusals ride
through intact; `VALIDATION.md`/`TODO.md` were never touched by the
basket — the C2 rewrites stand with nothing to absorb. The
old-tip→new-tip diff is exactly the basket's 10 files (nothing else
moved in the replay).

### Re-derivation + rebuild at the rebased head

- `make prelude-src` + `make lean-prelude-src` from the rebased
  `.lem` sources (lem @ `045dcb0`): `git status --porcelain` EMPTY on
  both generated trees — the committed trees are byte-identical to
  the re-derivation. Stamps: src `f4c0096697fb…`, OCaml gen
  `295e4f8291c9…`, Lean gen `580dab66f849…`.
- Fresh builds through the (merged) helpers: oracle
  `DUNE_CACHE=disabled` via `build_cerberus` (stamp recorded, bin
  `c30d4d43accb…`); Lean via `build_lean` capped (stamp recorded, bin
  `91c805fb050f…`).
- Pins verified `045dcb0d57a171eb4fb3a6eb5abe288c227270ce`
  everywhere: `deps/lem-pinned` HEAD = opam lem pin source = root
  Lake manifest (rev + inputRev) = speclab manifest (rev + inputRev).

### Battery at the rebased head (grind note, written before launch: the gcc + csmith passes are measurement sweeps over differential corpora — the sanctioned category — run sharded)

**Tier A (13/13, every rc 0):** test_unit (full ratcheted gate,
verbatim: `check_theorem_axioms: C2 ratchet OK (290 files scanned
recursively: 0 axioms, 0 runEffectful, seam population = the 66
pinned path-qualified counted rows exactly incl. the extern class;
lem tests/ scaffolds asserted outside the surface)`;
`check_theorem_axioms: C2 entry census OK (9 entries, every cone ⊆
[propext, Classical.choice, Quot.sound])` — all 9 entry lines
re-observed at exactly `[propext, Classical.choice, Quot.sound]`;
`test_renumber_plants: OK (12 plants: refusals refuse, admits admit
with declared class)`); exec minimal/coverage/float `Baseline check:
0 regression(s), 0 improvement(s)`; exec debug `0 regression(s), 1
improvement(s)` rc 0 — the attributed reconciliation, below; bytes
`SUMMARY: exec_match=9 neg_pinned=5 fail=0` (the basket's extended
NEG leg, green); libc_exec `SUMMARY: match=7 diff=0`; multi_tu
`SUMMARY: total=2 match=2 fail=0`; parse + core 100%; elab
`SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0`
(recorded state); libxml2_uri `GATE PASS: all lane expectations
pinned-green + baseline unchanged (16/16)`; cn_coverage
`BASELINE OK (213 entries, exact match)`.

**Tier B (12/12, every rc 0):** libxml2 full
`SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations
each)`; parse tests/ci; core tests/ci; verify `test_verify: 117
passed, 0 failed (23 fixtures, 22 call points, 14 corpus fixtures,
21 corpus points)`; immaculate at the committed baseline incl. both
offsetof rows (verbatim: `MATCH offsetof-nested-struct
O[VAL:Specified(0)] L[VAL:Specified(0)]` and
`MATCH offsetof-union-member O[CRASH] L[CRASH]`); speclab
`--selftest` + `--plant` + divmod/bytearr/list/tree/seed `--gate`.

**gcc second-oracle lane** (rc 0, `gcc second-oracle lane OK`),
SUMMARY verbatim:

```
SUMMARY: total=1953 compared=1880 agree=1871 agree_nd=0 triaged=9 disagree=0 o2_agree=190 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=44 triaged_addr=9
```

with `Baseline check: 0 regression(s), 0 improvement(s)` — the
per-run improvement warning of the C1/C2 era is GONE, exactly the
Addendum-2 erratum's post-rebase expectation (the regenerated
baseline `df63018e3` absorbed the four adjudicated rows; skip_oracle
is 0 and no longer printed).

**Tier C:** csmith corpus, all 6 shards
`--check-baseline --shard k/6`, k=1..6: each
`Baseline check: 0 regression(s), 0 improvement(s)` + `BASELINE OK`,
rc 0 (1669 files; one background-runner kill at the harness's task
ceiling interrupted shard 2 mid-run — re-run WHOLE, no partial
credit, the C1/C2 precedent). ci scoreboard no-regression probe
(`--check-baseline=scripts/exec_ci_baseline.txt tests/ci`): rc 0,
`Baseline check: 0 regression(s), 18 improvement(s)` — the
attributed reconciliation, below.

**Probes (reconciliation (b), values verbatim):** `fgetc_eof.c`
`AGREE VAL:Specified(2)`; `fseek_read.c` + `fread_seq.c` +
`fopen_trunc_reopen.c` all refuse loudly (lean exit 134), the
trunc-reopen refusal re-observed verbatim (`PANIC at CerbFS.fs_open
CerbFS:166:6: CerbFS refusal (fail-closed fs-model boundary): open
of existing 2-byte file 't.txt' with write/truncate intent (oflag
292) …`). P1 lem refusal re-run against the installed lem @
`045dcb0` on the committed suite plant
(`negative/neg_effectful_retired.lem`): exit 1, the retirement
message re-observed verbatim.

### Reconciliation vs the briefed expectations

- (a) gcc lane: EXACT — SUMMARY matches the briefed expectation
  field-for-field, `0 regression(s), 0 improvement(s)`.
- (b) CerbFS probes: refusals re-observed, fgetc_eof AGREE — met.
- (c) immaculate offsetof pair: both MATCH at baseline — met.
- (d) "everything else byte-at-baseline": met with ONE attributed
  exception class, reported here for operator adjudication
  ([AGENT] finding, not in the briefed list): the mainline
  `--cabs-json` stop-after-parse fix (`80e674ee2`) also unblocks
  exec-lane rows whose oracle EXEC succeeds (with UB) but whose
  cabs-json previously failed — every such row was
  `CERB_INCONSISTENT` ("exec succeeded but cabs-json failed") and now
  compares. Movement observed: `tests/debug/ub-inconsistent.c`
  `CERB_INCONSISTENT → UB_MATCH` (Tier A debug lane, 1 improvement,
  rc 0; run row verbatim `[66/90] UB_MATCH ub-inconsistent:
  UB:UB061_no_named_members`) and 18 tests/ci rows
  `CERB_INCONSISTENT → UB_MATCH` (Tier C scoreboard probe, rc 0; all
  18 are `.undef.c`/`.error.c`-class files). This is the exec-lane
  echo of expectation (a)'s root cause, anticipated as a class by the
  basket record §3(c) ("these rows move in the first full post-(c)
  run"); it PRE-EXISTS the rebase on mainline (fix + untouched
  baselines both in `df63018e3`). Its sibling
  `tests/debug/ub-static-reject.c` stays `CERB_SKIP` (oracle exec
  fails — different class), and the csmith corpus baseline is
  untouched (its skip rows are oracle-EXEC failures), both as the
  basket record predicted. Baselines deliberately NOT regenerated
  [AGENT], matching the basket worker's own disposition: the lanes
  are rc 0, the movement stays visible on every run, and re-recording
  (exec_debug_baseline.txt row 97 + the 18 exec_ci_baseline.txt rows)
  is an operator decision at merge.
- Beyond the above: NOTHING moved — no baseline, pin, or recorded
  state was modified by this rebase pass.

### State at close

`arc/effect-retirement` @ `7a9fec9e2` + this record commit;
`df63018e3..HEAD` = the same 26 arc commits + the record; worktree
clean; pins `045dcb0` everywhere; both driver-freshness stamps
recorded from this session's builds. The `.tmp/rebase-battery/`
scratch dir (lane logs, probe outputs) is ephemeral and deleted at
slice end; every load-bearing output is quoted verbatim above.

### Closing note (2026-09-01): the flagged reconciliation-(d) rows re-recorded

[USER 2026-09-01] sanction, verbatim: "great, let's run the regen".
[AGENT] (baseline-regen worker, branch `fix/exec-regen` from mainline
`bbdbacaff`; NO merge, NO push). The 19 exec-lane rows flagged above
under reconciliation (d) are re-recorded in one dedicated baseline
commit, attributed to the trust-basket oracle driver fix `80e674ee2`
(`backend/driver/main.ml` `--cabs-json` stops after parse+serialize;
its own message names the class: "parity-detective §2,
CERB_INCONSISTENT class", 43 blocked rows unlocked, 43/43 AGREE).

- Pre-flight: fresh builds through the helpers — oracle
  `DUNE_CACHE=disabled` via `build_cerberus` (bin `c93bbfebd196…`,
  stamp recorded); Lean via `build_lean` under `CERB_MEM_MAX=32G`
  (bin `91c805fb050f…` — byte-identical to the bin recorded in this
  Addendum, stamp recorded). lem-sync `--check` OK (gen
  `295e4f8291c9…`, as above) and `--check-lean` OK (gen
  `6c2ae2041cce…` — NOT the `580dab66f849…` recorded above; explained
  below). Pins unchanged (`045dcb0`).
- Step 1, check mode BEFORE any edit, verbatim: debug lane
  `Baseline check: 0 regression(s), 1 improvement(s)` / `BASELINE OK`
  rc 0, the one line `improvement: ub-inconsistent.c
  baseline=CERB_INCONSISTENT current=UB_MATCH` (run row `[66/90]
  UB_MATCH ub-inconsistent: UB:UB061_no_named_members`); ci scoreboard
  `Baseline check: 0 regression(s), 18 improvement(s)` / `BASELINE OK`
  rc 0, all 18 `baseline=CERB_INCONSISTENT current=UB_MATCH`, and the
  18 names are set-equal to the baseline's CERB_INCONSISTENT rows
  (diff empty). 1 + 18 = 19, all improvement-direction, one class.
- Step 2: `--write-baseline` to scratch paths, row-set delta vs the
  committed files = exactly those 19 rows (`diff` of non-comment
  lines), then spliced into the committed files (precedent
  `acf65b54c` / `e0d3ad1f7`: hand-maintained header blocks preserved,
  dated attribution notes prepended, the debug `ub n=3` summary line
  annotated). `git diff -U0` row lines: -19/+19, nothing else.
- Step 3, check mode AFTER: debug `Baseline check: 0 regression(s),
  0 improvement(s)` / `BASELINE OK` rc 0, `SUMMARY: total=90 match=66
  ub_match=20 … cerb_inconsistent=0`; ci `Baseline check:
  0 regression(s), 0 improvement(s)` / `BASELINE OK` rc 0, `SUMMARY:
  total=242 match=91 ub_match=41 … cerb_skip=110 cerb_inconsistent=0`.
  test_unit on the committed tree: rc 0 (`check_theorem_axioms: C2
  ratchet OK (292 files scanned recursively: …)`, `C2 entry census OK
  (9 entries, …)`, `test_renumber_plants: OK (12 plants: …)`).

**[AGENT] finding (observation, no action taken; for the operator):
stale primed files in the git-ignored Lean generated tree.** The gen
stamp `6c2ae2041cce…` (193 files) vs this Addendum's `580dab66f849…`,
and the ratchet's `292 files scanned` vs the `290` above, are the same
2-file delta: `lean_frontend/generated/CerbCoreInstances.lean` and
`CerbInhabitedInstances.lean` — retired by `fc7c5b0eb` (2026-08-20,
Arc-8 S4), never produced by lem at this commit (verified by a fresh
`lem` run into a temp outdir: 170 files, every one byte-identical to
the worktree's copy; +21 hand-written copies = 191; the worktree's 2
extras are dated Aug 20 and are also present in the primary checkout,
i.e. worktree priming carries them). They are INERT: no Lake root, no
import, no Makefile entry (the identical Lean binary hash corroborates).
But the `lean-prelude-src` recipe only `rm -f`s the Core_unstruct pair
(C1), so retired generated files persist in a git-ignored directory
and are then INCLUDED in both the lem-sync gen stamp and the
driver-fresh Lean src hash — the stamps bless whatever is present.
Not remediated in this slice (deleting them invalidates both stamps
and forces a rebuild cascade — out of the sanctioned scope); left for
an operator decision (candidate: make the recipe wipe
`lean_frontend/generated/*.lean` before generating, mirroring
`clean-prelude-src`).

State at close: `fix/exec-regen` = mainline `bbdbacaff` + this one
commit; worktree clean; `.tmp/` scratch (lane logs, scratch baselines)
deleted at slice end; every load-bearing output quoted verbatim above.
