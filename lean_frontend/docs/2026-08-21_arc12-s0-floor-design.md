# Arc-12 S0: the F-D mechanism CONFIRMED + the fail-stop floor design

Date: 2026-08-21. Worker: arc-12 S0 (charter:
`2026-08-21_arc12-honest-oracle-charter.md`; inputs: the fork-drift review
`notes/2026-08-21_fork-drift-review.md`, arc-10 campaign §root-cause,
`tests/csmith_findings/`). Worktree `arc/honest-oracle` @ `505025da3`
(clean; docs-only slice). Instruments: fork oracle
`_build/default/backend/driver/main.exe` (`--version` verbatim:
`git-cn-pin-271-ga8da194b2` — the pre-charter tree; the charter commit
505025da3 is docs-only, no oracle-source delta), upstream oracle
`deps/cerberus-upstream/_build/default/backend/driver/main.exe`
(`git-cn-pin-18-gb9aeedcb4`, the merge-base build per
`notes/2026-08-21_upstream-oracle-build.md`).

Worktree baseline re-confirmed before probing — `SKIP_BUILD=1
./scripts/test_exec.sh tests/minimal`, exit 0, verbatim summary line:

```
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_inconsistent=0
```

Slice discipline: probes are oracle RUNS + source READS only; zero source
edits anywhere; scratch lives in `_build/s0probe/` (gitignored). The probe
scripts are inlined in §1.1 for regeneration.

## 0. Executive summary

1. **Mechanism CONFIRMED, deterministically and without execution.** The
   fork oracle's own `--pp core -d5` output contains duplicate
   same-digest `(digest, num)` symbol pairs — two DISTINCT program symbols
   that compare EQUAL under `symbol.lem` symbolEqual — on **every one of
   the 20 probed F-D witnesses** (16 in-tree corpus rows + 3 committed
   generated witnesses + ub010_dead_object_reduced). The upstream oracle
   at the merge-base shows **zero** duplicates on the same inputs.
2. **Exact margin (first-TU, --nolibc): ambient window starts at id 483**;
   the first synthetic collision appears at exactly **N = 464** top-level
   declarations (the 465th declaration's desugar id 483 == main's
   `ret_483` return-label id). Margin onset is sharp and linear:
   duplicate-count = N − 463 on the synthetic shape.
3. **Member attribution: S1 (desugar threading, commit `8923d6436`) is
   the whole story for all probed witnesses; S2 (arc-2 run-supply,
   commit `80b0f6d20`) is EXONERATED for them** — run-supply ids seed at
   ~5,000–8,700 (above every program symbol), while every observed
   collision is desugar-id (locals `l_N`, params `p_N`, loop-ids
   `__cerb_continueN`, `main`) vs translation-minted ambient label/temp
   (`ret_/break_/continue_/while_N`, `a_N`). This CORRECTS the arc-10
   record's "prime suspect: arc-2 threaded sym_supply" and CONFIRMS the
   drift review's S1-primary recommendation.
4. **Margin is mode- and input-DEPENDENT but runtime-KNOWN — no replan
   tripwire.** libc mode ≈ 11,250 (libc.co parse draws ~10.8k ids first);
   multi-TU margins grow per TU; const-expr initializers consume 3–8
   ambient ids each mid-desugar. Every ambient draw passes through the
   single `Cerb_fresh.int`, so a PER-TU DYNAMIC floor (compare actual
   desugar high-water mark against actual ambient ids) is sound in every
   mode without knowing any constant.
5. **The floor**: two checks in hand OCaml ONLY (`util/cerb_fresh.ml` +
   a post-desugar hook in `backend/common/pipeline.ml` + an Ail
   max-symbol fold). ZERO `.lem` edits, zero lem-tool changes, zero
   Lean-tree impact, numbering bit-for-bit unchanged in-margin. The
   charter's alternative (ocaml target_rep restoration) is analyzed and
   REJECTED: it cannot be numbering-neutral (§4.2).
6. Predicted movement: all 35 F-D witnesses → LOUD; csmith-corpus
   baseline rows 15 DIFF + sa_190 + sia_976 → FLOOR; ~2–4% of the 1,070
   corpus MATCH rows (sampled 3/89) are coincidentally-correct-with-
   collisions and flip to loud; tests/minimal 0/106 and tests/ci 0/128
   move — Tier-A lanes are untouched.

## 1. Probe evidence (verbatim)

### 1.1 Probe tooling (inlined for regeneration)

Generator (`gen_decls.py`): N scalar globals `int g<i> = i % 100;` + a
main returning `(g0 + g{N/2} + g{N-1}) % 128`. Scanner (`scan_dups.py`):
over `--pp core -d5` output — at `-d5` the pp annotates every named
symbol as `name{num}` and SD_None symbols as `a_num` — take everything
after the `-- C function types` marker (the sections above it, STDLIB and
IMPL, carry their own digests; equal nums there are cross-digest, not
collisions), drop `(name,num)` pairs already seen above the marker
(stdlib/impl symbols referenced in TU bodies), classify names of shape
`X_num` whose suffix equals their own num as translation-minted
(labels/temps), and report any num claimed by ≥ 2 distinct names. A num
with two claimants inside the TU sections is two distinct symbols with
equal `(digest, num)` — symbolEqual-EQUAL by symbol.lem:136-150
(description ignored; the `-d5` "suspicious equality" hook at :141-144 is
the same predicate).

Scanner false-positive control (methodology note): a first naive scan
flagged nums 470-472 at N=453 — inspection showed the partners were
`n{470}`/`ty{471}`/`n{472}` INSIDE the `-- BEGIN IMPL` section
(impl-file digest), e.g. verbatim:

```
848:fun <Bitwise_complement> (ty{471}: ctype, n{470}: integer): integer :=
```

— cross-digest, excluded. All results below use the digest-aware scanner.

### 1.2 The duplicate-(digest,num) scan + exact margin (task 1)

Sweep at the work-order N values, fork oracle
`--nolibc --pp core -d5` (verbatim console):

```
N=100 cerb_exit=0 total-dup-nums=0
N=300 cerb_exit=0 total-dup-nums=0
N=450 cerb_exit=0 total-dup-nums=0
N=480 cerb_exit=0 total-dup-nums=15
N=500 cerb_exit=0 total-dup-nums=35
N=600 cerb_exit=0 total-dup-nums=135
N=800 cerb_exit=0 total-dup-nums=335
```

Bisect (verbatim):

```
N=463 total-dup-nums=0
N=464 total-dup-nums=1
N=465 total-dup-nums=2
N=466 total-dup-nums=3
N=467 total-dup-nums=4
```

First colliding pairs at N=466/467 (verbatim):

```
DUP num=483: ['g464', 'ret_483']
DUP num=484: ['a_484', 'g465']
DUP num=485: ['a_485', 'main']
```

Reading: desugar ids are 0-based with a 19-id builtin preamble (g0 = 19,
…, g464 = 483, main last); the TU's first ambient draw is id **483**
(main's return label `ret_483`), then `a_484`… So the very first
beyond-margin symbol collides with **main's return label** — the
Esave/Erun label machinery — and the next ones with SD_None temporaries.
Margin onset is exact (N = 464 ⟺ max desugar id ≥ 483) and duplicate
count grows +1 per +1 declaration (constant margin for a fixed shape;
input-dependence enters only through the per-TU draw dynamics, §3).

In-margin reference (N=100): translation temps start at `a_484`,
`ret_483` first — ambient window base 483 confirmed independently.

**Collision is necessary but NOT sufficient for misbehavior** — the
synthetic scalar shape executes CORRECTLY on both oracles even far
beyond margin (fork vs upstream `--nolibc --exec --batch
--mode=exhaustive`, verbatim, N=600 shown; N=450/463/464/466/500
identical-by-pair as well):

```
N=600 FORK: Defined {value: "Specified(99)", stdout: "", stderr: "", blocked: "false"}
N=600 UPST: Defined {value: "Specified(99)", stdout: "", stderr: "", blocked: "false"}
```

The colliding pairs here (glob keys vs let-scoped temporaries and main's
ret label) never meet in a way this benign layout observes; the F-D
witnesses corrupt because their collisions capture LOOP labels and
locals inside save/run continuations. This is the basis of the
coincidentally-correct class (§5.2, §8): a program can carry live
collisions and still be right today — one head-morph from wrong. The
floor deliberately treats collision itself as the failure condition.

### 1.3 Witness scans — all F-D witnesses carry collisions (task 2 input)

Committed artifacts (`tests/csmith_findings/oracle/`, headers staged per
the manifest recipe), fork oracle `--nolibc --pp core -d5` (verbatim):

```
csmith_6000018: exit=0 total-dup-nums=32 :: DUP num=591: ['j', 'ret_591'];DUP num=592: ['__cerb_continue26', 'continue_592'];DUP num=595: ['break_595', 'l_171'];
csmith_6000038: exit=0 total-dup-nums=9 :: DUP num=552: ['main', 'ret_552'];DUP num=554: ['break_554', 'i'];DUP num=555: ['continue_555', 'j'];
csmith_6000098: exit=0 total-dup-nums=15 :: DUP num=594: ['__cerb_continue21', 'ret_594'];DUP num=597: ['continue_597', 'main'];DUP num=599: ['continue_599', 'i'];
ub010_dead_object_reduced: exit=0 total-dup-nums=94 :: DUP num=527: ['l_78', 'ret_527'];DUP num=528: ['continue_528', 'l_84'];DUP num=529: ['break_529', 'l_85'];
```

The 16 in-tree corpus F-D rows (15 DIFF + sa_csmith_190), corpus-lane
header substitution applied (verbatim):

```
small_arrays/csmith_19: exit=0 total-dup-nums=107 | DUP num=600: ['continue_600', 'l_383']
small_arrays/csmith_28: exit=0 total-dup-nums=112 | DUP num=575: ['__cerb_continue15', 'ret_575']
small_arrays/csmith_95: exit=0 total-dup-nums=129 | DUP num=623: ['l_535', 'ret_623']
small_arrays/csmith_120: exit=0 total-dup-nums=202 | DUP num=616: ['break_616', 'l_760']
small_arrays/csmith_149: exit=0 total-dup-nums=145 | DUP num=554: ['l_536', 'ret_554']
small_arrays/csmith_168: exit=0 total-dup-nums=182 | DUP num=596: ['l_554', 'ret_596']
small_arrays/csmith_190: exit=0 total-dup-nums=91 | DUP num=585: ['__cerb_continue17', 'continue_585']
small_arrays/csmith_218: exit=0 total-dup-nums=247 | DUP num=641: ['p_23', 'ret_641']
small_arrays/csmith_317: exit=0 total-dup-nums=119 | DUP num=594: ['__cerb_continue19', 'continue_594']
small_arrays/csmith_350: exit=0 total-dup-nums=99 | DUP num=601: ['break_601', 'l_517']
small_arrays/csmith_369: exit=0 total-dup-nums=114 | DUP num=554: ['l_390', 'ret_554']
small_arrays/csmith_371: exit=0 total-dup-nums=115 | DUP num=589: ['__cerb_continue16', 'break_589']
small_int_arith/csmith_081: exit=0 total-dup-nums=29 | DUP num=483: ['l_147', 'ret_483']
small_int_arith/csmith_1168: exit=0 total-dup-nums=154 | DUP num=485: ['p_15', 'ret_485']
small_int_arith/csmith_136: exit=0 total-dup-nums=57 | DUP num=485: ['a_485', 'l_122']
small_int_arith/csmith_897: exit=0 total-dup-nums=181 | DUP num=485: ['l_841', 'ret_485']
```

20/20 probed F-D artifacts collision-positive; every first collision is a
desugar symbol (local / param / loop-id / `main`) against a
translation-minted label or SD_None temporary.

**Negative controls.** Upstream oracle, same inputs, same scanner
(verbatim):

```
upstream 6000098: total-dup-nums=0
upstream sia_081: total-dup-nums=0
```

Non-F-D non-MATCH corpus rows (pure-perf TIMEOUTs + LEAN_CRASHes),
verbatim:

```
small_arrays/csmith_435: total-dup-nums=0
small_int_arith/csmith_041: total-dup-nums=0
small_int_arith/csmith_072: total-dup-nums=0
small_int_arith/csmith_139: total-dup-nums=0
small_int_arith/csmith_161: total-dup-nums=0
small_int_arith/csmith_169: total-dup-nums=0
small_int_arith/csmith_976: total-dup-nums=97
small_int_arith/csmith_996: total-dup-nums=0
small_int_arith/csmith_477: total-dup-nums=0
small_int_arith/csmith_769: total-dup-nums=0
```

The classifier separation is essentially perfect: F-D rows 16/16
positive, non-F-D rows 9/10 negative. The exception, **sia_csmith_976**
(baselined TIMEOUT/pure-perf), carries 97 collisions → REGISTER ITEM
(§8): latent F-D under a perf timeout; predicted FLOOR under the repair.

**Run-time confirmation**: fork `--nolibc --exec --batch
--mode=exhaustive -d5` on csmith_6000038 — the symbol.lem:141
"suspicious equality" hook (digest+num equal, descriptions differ) fires
**11,206** times in one execution (verbatim count via
`grep -c "suspicious equality"`: `11206`). The colliding pairs are live
in the interpreter's equality traffic, not just in the pp.

### 1.4 Id-range analysis per witness (S1-vs-S2 discriminator, task 2)

Derived from the same `-d5` dumps (ranges tool inlined with the scanner;
"ambient" = self-numbered labels + `a_N` temps, "desugar" = the rest,
stdlib/impl-pair-excluded; derived tallies):

```
csmith_6000018: desugar n=289 min=9 max=645 | ambient n=7243 min=591 max=8662 | overlap n=32 first=[591, 592, 595, 596, 597]
csmith_6000038: desugar n=226 min=9 max=569 | ambient n=4917 min=552 max=6090 | overlap n=9  first=[552, 554, 555, 556, 557]
csmith_6000098: desugar n=284 min=9 max=629 | ambient n=5415 min=594 max=6676 | overlap n=15 first=[594, 597, 599, 600, 601]
ub010_dead_object_reduced: desugar n=302 min=9 max=667 | ambient n=520 min=483 max=1295 | overlap n=94 first=[527, 528, ...]
```

(Each witness also has 335–357 desugar ids minted but not surviving into
the pp — the desugar supply is 0-based contiguous, so its high-water mark
exceeds the max VISIBLE id; relevant to §4.4.)

## 2. Member attribution (task 2): S1 primary — CONFIRMED and sharpened

**S1 (desugar supply threaded 0-based, commit `8923d6436`,
cabs_to_ail_effect.lem:568 `fresh_sym_supply= 0`, :618-648 helpers;
loop-id sites cabs_to_ail.lem:3802/3834/3865/3964) is the mechanism of
every probed witness.** The collision is: desugar-threaded ids (locals,
params, loop-ids, function syms — everything `register_identifier` mints,
NOT just top-level declarations) reaching the ambient window [483, …)
occupied by TRANSLATION-minted symbols — above all the Esave/Erun label
symbols (`ret_N`/`break_N`/`continue_N`/`while_N`, translation.lem's
ambient `Symbol.fresh*` sites) and SD_None temporaries `a_N`. With
symbolEqual/symbol_compare keyed on (digest, num) only, a desugar local
IS the label as a map key: label lookup and Esave substitution
(core_run.lem:1502-1541) then hit the wrong entry — the
wrong-continuation jumps, spurious UB and value corruption of the arc-10
§root-cause trace, and exactly its head/tail-morph behavior (a HEAD
declaration shifts which desugar id lands on which fixed label id; a
TAIL declaration adds ids past the collision window without moving the
existing pairs).

**S2 (run supply seeded from one ambient draw, commit `80b0f6d20`,
core_run_aux.lem:287, consumed via core_run.lem:115-120 `fresh_symbol'`
/ `Symbol.fresh_given_int`) is EXONERATED for all probed witnesses**: the
driver-run seed is drawn AFTER translation, so run-minted ids start above
the entire ambient window (≥ 6,090–8,662 here) while desugar ids top out
at 569–667 — the ranges cannot intersect for these programs. S2 remains
live only in COMPOSITION (mini_pipeline const-expr runs seeded
mid-desugar while the desugar supply is still climbing — the drift
review's new observation), and the floor's backward check covers exactly
that window (§4.4). S2's conceded non-escape obligation (run ids vs
ambient ids drawn after the same run's init) stays open in general but is
narrowed by draw-site enumeration (§3.3): no exec-stage ambient draw site
exists apart from run-init seeds themselves.

**S3 (SeqRMW draw-time hoist)**: run-threaded like S2, ids far above
every program symbol once desugar-vs-ambient disjointness is enforced;
id-order-cosmetic. No action in this arc; an atomics-under-high-decl
spot probe belongs to the S2 slice batch.

**Witness-class mapping** (which member produces which class —
work-order question): all three classes are S1, differing only in WHICH
ambient symbol the colliding desugar id captures:
- captured label whose continuation shape still typechecks → silent
  value corruption / wrong checksum (6000098-class);
- captured label with ill-typed continuation → `can_advance:
  Step_error2 ==> Load/Store` internal errors (6000018-morph /
  B1-seed class);
- captured pointer/value temporary (`a_N`) or lifetime-tracked binder →
  spurious UB010/UB009/UB002 (sa_-corpus class, 136-class `a_485`).

## 3. The margin per mode (task 3)

### 3.1 Measurements

| Mode | First ambient id of TU-1 | Evidence |
|---|---|---|
| `--nolibc`, single TU, `--pp` or `--exec` | **483** (fixed: std.core + impl parse draws 0..482; core_parser.mly:184/:220) | `ret_483` first at N=464 onset (§1.2); ub010 ambient min 483 |
| libc mode (no `--nolibc`), `--exec` | **≈ 11,250** (libc.co is prepended to the file list, main.ml:156, and its core-parse registers ~10.8k syms/labels first) | first TU temp `a_11253` in the `-d6` exec debug vs `a_487` for the same file nolibc (verbatim tokens; label offset ~4 below the first temp). Sanity: tests/libc/libc.core = 89,582 lines, 673 save labels, 259 top-level defs + per-binder registrations (derived) |
| `--pp core` libc | same as nolibc (pp path runs c_frontend on the file only; libc never parsed — main.ml:246 vs :156) | libc-flag pp outputs byte-identical (1639 = 1639 lines) |
| multi-TU | TU_i window starts where TU_{i-1}'s translation stopped (grows monotonically; per-TU digest keeps cross-TU equal nums harmless) | 2-TU `-d6` run: single ascending temp sequence 484,485,487,488,… spanning both TUs |
| const-expr initializers (any mode) | unchanged window START (483 — the first mini-run seed draws it), but the LIVE translation window shifts up 3–8 ids per initializer (mini_pipeline translation temps + run seed) | 20 × `[2+3]` array sizes: first ret 643; 20 × literal `[5]`: 543; 20 × `enum {K=i+1}`: 643; scalar-only control: 483 (verbatim first-ret values) |

Witness corroboration: visible ambient minima 552/591/594 on the three
committed csmith witnesses = 483 + their const-expr mid-desugar
consumption.

### 3.2 Dynamics verdict — NO replan tripwire

The margin is NOT a constant: it varies by mode (483 vs ~11,250), by
position in a multi-TU link, and by the input's own const-expr content.
But it is **dynamic-BOUNDED-KNOWN, not dynamic-unbounded**: every
ambient draw in the oracle passes through the single
`Cerb_fresh.int` counter (§3.3 enumeration), so at any moment the
oracle can KNOW its exact ambient position, and the desugared Ail
program carries the exact desugar high-water mark. A floor that compares
those two RUNTIME values per TU needs no mode constant at all and is
sound in every mode. The charter tripwire ("margin dynamic and
unfloorable") does NOT fire. (What IS ruled out is any constant-threshold
floor: a 483-based cap would false-fire in libc mode and multi-TU;
a 2^20 rebase would renumber. Both rejected, §4.2.)

### 3.3 Complete ambient-draw-source enumeration (grep-verified this tree)

1. `parsers/core/core_parser.mly:184` (register_sym), `:220`
   (register_label) — every Core-file parse: std.core + .impl (ids
   0..482), libc.co (~10.8k), any linked .co.
2. Translation stage (mints the collision VICTIMS):
   `translation.lem` — 16 `Symbol.fresh*` sites (876, 3838, 3954-5,
   4235, 4265, 4354, 4361, 4412, 4414, …);
   `translation_effect.lem:65,70,107,178`;
   `core_unstruct.lem:260,278`.
3. Run-init seed: `core_run_aux.lem:287` — one draw per driver run
   (exec) and per mini_pipeline const-expr run (mid-desugar).
4. NOT ambient: the desugar stage (zero ambient draws — fully threaded;
   the two `st.symbol_supply` greps at cabs_to_ail_effect.lem:1410/1835
   are inside comment blocks — no such state field exists);
   run-minted symbols (threaded from the seed);
   other backends' sites (backend/ocaml cps_core.ml, rustic) — not on
   the driver path.

## 4. THE FLOOR DESIGN (task 4)

### 4.1 Shape: a two-check runtime floor, hand-OCaml only, zero .lem edits

The Lean side's protection (`native/fresh_int.c`) = base displacement
(2^20) + fail-stop assertion. The oracle CANNOT take the displacement
half (it renumbers, §4.2); it takes the ASSERTION half, generalized to
the per-TU dynamic margin:

Let, per TU (scoped by `set_digest`):
- `M` = desugar high-water mark = max symbol num (TU digest) occurring
  in the desugared Ail program (§4.4 on how it is obtained);
- `tu_first` = the first ambient id drawn after this TU's `set_digest`
  (recorded inside Cerb_fresh at draw time);
- `next` = the ambient id about to be handed out.

**Check B (backward, once, at the post-desugar hook):** if
`M >= tu_first` → some ambient id drawn during this TU's own desugar
(a mini_pipeline const-expr seed or its mini-translation temps) already
falls inside the desugar range → collision has already occurred
(possibly corrupting a const-expr result) → FAIL LOUD.

**Check F (forward, on every subsequent draw under this digest):** if
`next <= M` → the id being minted would equal a live desugar symbol →
FAIL LOUD before handing it out.

Soundness argument: desugar ids are `[0, N_d)`; ambient ids drawn during
the TU are `{tu_first, tu_first+1, …}` (monotone, all through
`Cerb_fresh.int` — §3.3). Any desugar-vs-ambient collision is an ambient
id ≤ max desugar id; every such id either precedes the hook (caught by
B via `tu_first ≤ M`) or follows it (caught by F). Run-threaded ids are
`≥ seed`, and every seed is itself an ambient draw subject to B/F — so a
passing floor also gives `run ids > M` (no run-vs-desugar collision:
closes the S2-composition window). Remaining uncovered pair: run ids vs
ambient ids drawn AFTER that run's init — by §3.3 the only exec-stage
ambient draws are other runs' seeds; overlap between two runs'/branches'
threaded ranges is cross-run and harmless while run symbols stay
run-local (the narrowed O1 residual, recorded, unchanged by this
repair).

In-margin neutrality: both checks are pure comparisons — the counter
sequence, every symbol number, and every byte of oracle output are
UNCHANGED for any program that does not trip them. Numbering-neutrality
is by construction, not by test (and is still re-verified per §7).

### 4.2 Rejected alternatives (recorded per the charter's option list)

- **Ocaml target_rep restoration** (drift review §4's "cleaner, bigger"
  option: point the desugar helpers back at `Cerb_fresh.int` on the
  OCaml target): re-unifies the streams but renumbers EVERY desugar and
  translation symbol (desugar ids become 483+, translation ids shift by
  N_d) → pinned .core fixtures, pin-provenance gates, and every
  committed oracle dump move. **Cannot be numbering-neutral — this IS
  the renumbering route**, out of scope per the charter; it becomes the
  upstream-coordinated design note (§9). Additionally any `.lem` edit
  risks generated-Lean comment echoes (the drift review §3 shows lem
  echoing foreign-target declares as comments), tripping the
  empty-Lean-diff wire; the chosen design avoids .lem entirely.
- **Constant-base floor mirroring 2^20 literally** (rebase
  `util/cerb_fresh.ml`'s counter): renumbers everything; same rejection.
- **Constant-threshold assertion (e.g. 483)**: wrong in libc mode
  (margin ~11,250), wrong for later TUs of a link, silently weak when
  std.core grows. Rejected for the dynamic per-TU comparison.
- **Post-hoc duplicate scan over the final Core file** as the primary
  floor: cannot ATTRIBUTE which of two equal-key symbols is which
  stream post-hoc, and misses equal-description collisions; retained
  only as an optional defense-in-depth diagnostic, not the gate.

### 4.3 Where the floor goes (files, with draw-site citations)

1. **`util/cerb_fresh.ml`** (currently 10 lines, byte-identical to
   upstream — that changes; manifest updated §6). Sketch (S1 implements;
   shapes may adjust to compile, semantics fixed here):

   ```ocaml
   (* fork F-D fail-stop floor (arc-12): see
      lean_frontend/docs/2026-08-21_arc12-s0-floor-design.md.
      Mirrors lean_frontend/native/fresh_int.c's collision floor:
      ambient ids must stay disjoint from the 0-based desugar-threaded
      supply (cabs_to_ail_effect.lem fresh_sym_supply, commit
      8923d6436). Numbering is UNCHANGED for every program that does
      not trip the checks. *)
   let floor = ref 0            (* desugar hwm + 1, current digest *)
   let tu_first = ref (-1)      (* first ambient id since set_digest *)
   let cur_filename = ref ""

   let floor_fail fmt_ctx n m =
     prerr_endline (Printf.sprintf
       "CERB_FRESH_FLOOR_VIOLATION: %s: ambient symbol id %d collides \
        with the desugar-threaded id range [0..%d] of '%s' — this \
        translation unit exceeds the fork oracle's symbol-id margin; \
        refusing to continue (the un-floored oracle would corrupt \
        symbol identity: F-D, tests/csmith_findings/README.md). \
        Renumbering is deferred upstream-coordinated work \
        (docs/2026-08-21_arc12-s0-floor-design.md)." fmt_ctx n m);
     exit 70

   let int : unit -> int =
     let counter = ref (-1) in
     fun () ->
       assert (!counter <> max_int);
       incr counter;
       let n = !counter in
       if !tu_first < 0 then tu_first := n;
       if n < !floor then floor_fail "forward" n (!floor - 1);
       n

   let set_desugar_hwm ~filename m =   (* pipeline hook, post-desugar *)
     if !tu_first >= 0 && m >= !tu_first then
       floor_fail "backward" !tu_first m;
     floor := m + 1

   (* set_digest additionally does: floor := 0; tu_first := -1;
      cur_filename := filename *)
   ```

   Draw sites feeding `int()`: §3.3 items 1–3 (core parser
   register_sym/register_label; translation.lem × 16,
   translation_effect.lem:65/70/107/178, core_unstruct.lem:260/278 via
   `Symbol.fresh*`'s existing `declare ocaml target_rep function
   fresh_int = `Cerb_fresh.int`` at symbol.lem:229; run seeds via
   core_run_aux.lem:287). No draw site changes; the counter's VALUES
   are untouched.

2. **`backend/common/pipeline.ml`** — the hook call. In `c_frontend`'s
   desugar continuation (after `Cabs_to_ail.desugar … >>= fun
   (markers_env, ail_prog)`, pipeline.ml:203):
   `Cerb_fresh.set_desugar_hwm ~filename (Ail_sym_hwm.max_sym ail_prog)`.
   This covers every driver path that desugars (`--exec`, `--pp`,
   elaboration; per-file in multi-TU — each file gets
   `set_digest`, :181, then its own hook). `core_frontend` (.co inputs,
   :262) desugars nothing: `set_digest` resets the floor to 0 and the
   checks are inert there — libc.co and .co linking are unaffected.
   `--cabs-json` DOES desugar (main.ml:243-246 calls `c_frontend`; the
   Cabs export itself predates desugar, but desugar errors already
   surface hard in this mode — the F-E(a) channel), so the floor
   applies uniformly: a beyond-margin file fails loud in cabs-json mode
   too. CONSEQUENCE for the differential harnesses: such files get NO
   Lean-side run via the JSON bridge — they become CERB_FLOOR rows with
   no Lean verdict (honest per the charter; the Lean pipeline's own
   2^20 floor is untouched, and exempting cabs-json would let a
   collision-corrupted const-expr produce a wrong hard-error class
   instead).

3. **`backend/common/ail_sym_hwm.ml`** (new): a complete fold over the
   desugared Ail program returning the max symbol number — sigma
   declarations / object & function definitions (params + body
   statements incl. every `AilSdeclaration` binder and label), tag
   definitions, static assertions, and all expression forms (the live
   desugar symbols are dominated by LOCALS `l_N` — witness data §1.4 —
   so the fold must descend into statements/expressions; it is written
   WITHOUT catch-all wildcards so that new constructors break the
   compile, not the soundness). M from the fold is max-LIVE, which is
   what collisions against live maps require; non-surviving desugar ids
   (§1.4: ~350/witness) are transient and cannot key any live map.

### 4.4 The loud error (the NEW distinguishable class)

- Greppable token: **`CERB_FRESH_FLOOR_VIOLATION`** (one line, stderr,
  exact draft text in §4.3's sketch; mirrors native/fresh_int.c's
  fail-stop comment style: state the invariant, the colliding value,
  the refusal, the pointer).
- Exit code **70** (EX_SOFTWARE): distinct from the runM verdict codes
  (0/1), harness timeout (124), and the signal codes the harnesses
  fold into CERB_SKIP (134/137/139). Deliberately NOT abort(): a
  SIGABRT would be laundered into CERB_SKIP by the current classifiers.
- Harness classification (S1, allowed surface): `test_exec.sh` /
  `test_csmith_corpus.sh` / the ci-scoreboard classifier gain a
  **`CERB_FLOOR`** bucket keyed on the stderr token (checked BEFORE the
  generic oracle-failure → CERB_SKIP fallback so floor hits can never
  be silently skipped); baseline files record `CERB_FLOOR` rows;
  a floor hit on a file not baselined as such is FATAL (fail-closed both
  directions, matching house rules).
- The Lean side is UNTOUCHED (its 2^20 base + trap floor already
  protects it; witness programs keep executing correctly there).

### 4.5 Edge cases (recorded dispositions)

- TU with zero post-desugar ambient draws (declaration-only): check B
  still runs at the hook (it compares recorded values, no draw needed)
  — the const-expr corner (static_assert in a >margin decl-only TU) is
  covered by B, not F.
- Exhaustive-mode ND branches share one run seed; branch-local threaded
  ids may repeat across branches — cross-branch, harmless, unchanged.
- Same file linked twice (same digest twice): second desugar re-mints
  [0,N) under an ambient window that has moved on; per-TU reset keeps
  the checks correct for the second instance; the first instance's syms
  are cross-checked only through linking (which upstream also permits —
  same digest+num can only come from the same file content).
- `Symbol.fresh_pretty_with_id` / `fresh_given_int` (symbol.lem:248,
  262): the former draws ambient (covered); the latter never draws
  (threaded consumers only).

## 5. Predicted reclassification (task 4 deliverable)

### 5.1 The 35 witnesses (per-witness where probed, class-level for the rest)

Predicted status under the floor: **all 35 → LOUD (`CERB_FLOOR`)**; none
stays silently wrong; none is within margin (every one corrupts today,
corruption requires collision, collision trips the floor — and all 20
probed artifacts are scan-positive, §1.3).

| Witness group | Today | Probed evidence | Predicted |
|---|---|---|---|
| corpus 15 DIFF rows (sa_ 19/28/95/120/149/168/218/317/350/369/371, sia_ 081/136/1168/897) | DIFF (oracle spurious UB) | scan-positive 15/15 (§1.3) | CERB_FLOOR (loud) |
| sa_csmith_190 | TIMEOUT (F-D under perf cap) | scan-positive (91 dups) | CERB_FLOOR |
| committed generated: 6000018 (spurious UB), 6000038 (value corr.), 6000098 (value corr.) | oracle wrong vs Lean+gcc+upstream | scan-positive 3/3 | CERB_FLOOR |
| ub010_dead_object_reduced | spurious UB010 in 0.05 s | scan-positive (94 dups) | CERB_FLOOR |
| generated P1/P2/P3/P4 + 6000245 (7 files, regen-by-seed) | value corr. / spurious UB | class-level (same mechanism; S1 re-verifies after regen) | CERB_FLOOR |
| B1 exploration seeds ×8 (internal-error class) | `can_advance: Step_error2` | class-level (the 6000018-morph class is scan-positive) | CERB_FLOOR |

Three-way instrument on all of the above: upstream keeps returning the
correct value (or its honest non-termination for ub010); Lean unchanged;
fork = loud. "Three-way agreement on in-margin witnesses" is then
vacuous for these 35 (none in-margin) and is instead exercised by the
standing corpora (§7).

### 5.2 Standing-baseline movement (predicted rows)

| Lane | Predicted movement |
|---|---|
| `scripts/exec_csmith_corpus_baseline.txt` | 15 DIFF → CERB_FLOOR; sa_csmith_190 TIMEOUT → CERB_FLOOR; **sia_csmith_976 TIMEOUT → CERB_FLOOR** (latent F-D, §1.3); plus the coincidentally-correct class: sampled 3/89 of MATCH rows collision-positive (sa_csmith_172, sa_csmith_324, sia_csmith_1118 — derived estimate ~2–4% of 1,070 MATCH rows ≈ 25–40 files) → CERB_FLOOR, each justified by its own scan line at S2 |
| `test_exec.sh tests/minimal` | zero movement (scan 0/106 collision-positive) |
| tests/ci scoreboard | zero movement (scan 0/128) |
| coverage / debug / float / bytes / multi_tu | predicted zero (small TUs); measured at S1 by running the floored oracle over the full lanes (fail-closed: any unpredicted CERB_FLOOR row is a finding, not a shrug) |
| uri / libc_exec (libc mode) | zero movement (margin ≈ 11,250) |
| libxml2 chvalid/uri slices | predicted zero, but the chvalid TU is the largest standing input → S1 MUST scan it before the lane runs |
| tests/verify (T1-T5) + pin-provenance | zero movement (tiny fixtures; and the floor changes no in-margin byte) |

### 5.3 What each check catches (for the audit's floor-soundness scope)

- Check F alone would miss: nothing in translation, but WOULD miss
  const-expr-window collisions in decl-only TUs (B catches).
- Check B alone would miss: all translation-stage collisions (F
  catches).
- Both together leave: run-vs-run overlaps (harmless while run syms are
  run-local — the narrowed O1 residual; unchanged semantics, register
  entry stays open with reduced scope).

## 6. Drift-gate refresh plan (`check_fork_drift.sh` + manifest)

The repair adds ORACLE-ONLY OCaml drift; the generated trees do not move
(no .lem edits), so **all [expected-semantic] pinned diff hashes stay
AS-IS** and the layer-2 gate stays green unchanged. Layer-1 manifest
(`scripts/fork_drift_manifest.txt`) additions with justification lines:

```
util/cerb_fresh.ml                  # arc-12 F-D fail-stop floor (S0 design doc)
backend/common/pipeline.ml          # arc-12: post-desugar set_desugar_hwm hook
backend/common/ail_sym_hwm.ml       # arc-12: NEW — Ail max-symbol fold for the floor
```

This retires two of the drift review's "important negatives"
(`util/` and `backend/common/` untouched) — deliberately, with this
document as the recorded justification; the [meta] line gains
`floor=arc12` so a future reviewer sees the state change. No lem-pin or
merge-base movement.

## 7. Acceptance-test plan (S1 bars, mechanics)

1. **Numbering neutrality (the tripwire checks, run per oracle
   rebuild):**
   - generated-Lean diff EMPTY: `make lean-prelude-src` + `git diff
     --stat lean_frontend/generated/` = empty (trivially expected: no
     .lem, no lem; still run).
   - generated-OCaml diff EMPTY vs pre-floor: rebuild
     `ocaml_frontend/generated/`, diff against a pre-change snapshot.
   - pin-provenance: `test_verify.sh` 29/29 incl. the 5 oracle
     `--pp core` re-derivations byte-equal to pinned dumps.
   - in-margin byte-stability spot: `--pp core` of decl463 (largest
     in-margin synthetic) byte-identical pre/post floor.
2. **Floor fires correctly:** decl464 (smallest beyond-margin
   synthetic) → exactly one `CERB_FRESH_FLOOR_VIOLATION` line, exit 70;
   decl463 → unchanged output, exit as before. Plant test (audit scope
   b): revert the hook call locally → decl464 corrupts silently again →
   restore (proves the gate is load-bearing).
3. **The 35 witnesses:** each probed artifact + regenerated seeds run
   under the floored oracle → CERB_FLOOR; upstream + Lean unchanged
   (three-way table, verbatim, into the S2 record).
4. **Standing corpora sweeps** (capped 40G, fast lanes first per the
   charter): test_exec minimal → ci scoreboard → coverage → float/bytes
   → multi_tu → libc/uri → libxml2 (chvalid TU pre-scanned) → csmith
   corpus full (sharded). Zero movement outside §5.2's predicted rows;
   every moved row gets its scan line as justification.
5. **Suspicious-equality regression instrument:** `-d5` exec on
   csmith_6000038 under the floored oracle must DIE LOUD before any
   "suspicious equality" line is printed (today: 11,206 of them).

## 8. Register items from this slice

1. **sia_csmith_976**: baselined TIMEOUT/pure-perf but collision-positive
   (97 dups) — latent F-D; its arc-10 "verdict sequences identical
   uncapped" note means coincidentally-correct today. Reclassify at S2.
2. **Coincidentally-correct-with-collisions class** (sa_csmith_172,
   sa_csmith_324, sia_csmith_1118 + est. 25–40 corpus files): correct
   today by layout luck; flip to loud under the floor — this is the
   honest outcome (a head-morph away from corruption), record the
   full list at S2.
3. **O1 narrowed, not closed**: run-local-ness of run-minted symbols
   remains the only unproved disjointness assumption after the floor;
   scope reduced to run-vs-run/post-init-ambient (§4.1, §5.3).
4. **Attribution correction to propagate at S2** (addendum, never
   rewrite): arc-10 campaign record + csmith_findings README name the
   arc-2 threaded sym_supply as prime suspect; the confirmed mechanism
   is the April desugar threading (drift review S1). core_run_aux's
   comment-conceded hole is real but not what fired.
5. **Renumbering design note** (deferred, upstream-coordinated): the
   clean fix re-unifies all minting through one counter (either revert
   S1-on-OCaml via target_rep — renumbering the fork oracle — or
   upstream adopting threaded supplies with a partitioned id space,
   e.g. per-stage high bits). Any such change re-pins every .core
   fixture and both drift-gate hash sets; it also moves upstream's own
   margin question (upstream's single counter is safe only while ALL
   mints go through it — our notes/upstream/07 fragility filing).
   TEMPORAL entry with this as the mover, per charter S3/S4.

## 9. S1 execution plan (proposed order, single worker)

1. Implement `util/cerb_fresh.ml` floor + `set_digest` reset (+
   `ail_sym_hwm.ml`, `pipeline.ml` hook). Build oracle.
2. Neutrality battery (§7.1) — MUST be green before anything else;
   any diff = stop (tripwire).
3. Floor smoke (§7.2 decl463/decl464 + plant test).
4. Harness `CERB_FLOOR` bucket in test_exec.sh + test_csmith_corpus.sh
   (+ ci scoreboard classifier), fail-closed wiring.
5. Witness battery (§7.3) + three-way table.
6. Corpora sweeps in ladder order (§7.4); collect every moved row's
   scan-line justification; update baselines (S2 formally owns the
   baseline commits — split per charter).
7. Drift-manifest refresh (§6) with justification lines; re-run
   check_fork_drift.sh green.
8. Record: floor-implementation note + verbatim acceptance evidence;
   hand S2 the movement list.

Estimated S1 risk points: the Ail fold's completeness (mitigated:
no-wildcard style + the §7.2 plant test + witness battery would expose
an under-approximated M as a witness NOT tripping the floor), and
harness-classifier interaction with `--batch` stdout parsing (floor
message is stderr-only; stdout stays empty on floor exit).

---

## ADDENDUM (arc-12 S1, 2026-08-21) — corrections from implementation-time measurement

This addendum records where S1's measurements corrected this document.
The original text above is unchanged (records discipline). Full S1
evidence: `2026-08-21_arc12-s1-floor-record.md`.

1. **The libc-mode margin row in §3.1 is WRONG.** `.co` files are
   MARSHALLED core objects (`backend/driver/main.ml:26-27
   read_core_object`), not parsed — loading libc.co draws NOTHING from
   `Cerb_fresh.int`, and `set_digest` is not called for it. The
   `a_11253` tokens measured in the `-d6` libc-mode debug were libc.co's
   own SYMBOLS (ids baked at libc build time, when the oracle elaborated
   the libc sources sequentially on one counter), not fresh draws.
   **The C-TU margin in libc mode is the same 483 as nolibc.** The
   floor's per-TU dynamic design is unaffected (it never used the
   constant), but the blast-radius prediction was: libc-mode lanes are
   NOT protected by a large margin — see the S1 record's conflict
   section (uri.c hwm 1798, libc source TUs stdio/stdlib/internal/
   vfscanf hwm 856/673/682/521, all beyond-margin; stdio/stdlib/
   internal/uri.c carry live collisions: 214/58/106/252 duplicate keys).
2. **§4.3's "note the tree-resident nats" choice was implemented and
   then REVERSED (fold v2, symbols only).** Noting loop/marker ints
   made the mark track the raw supply high water, which exceeds the
   live-symbol mark by roughly one draw per source line; the interim v1
   corpus sweep floored 420 of the first 862 corpus files, most with
   zero live collisions. v2 notes only `Symbol.sym` numbers (only
   symbols can collide; no Symbol is built from a loop/marker nat on
   the cerberus path — per-site verified). The §1.2 boundary
   (N=463 pass / N=464 floor) holds under v2 EXACTLY as probed at S0;
   under v1 it was 462/463 (main's function-definition `record_marker`
   draw). Residual documented in ail_sym_hwm.ml's header.
3. **The §5.2 coincidentally-correct estimate (~25-40 files) was
   sample-biased.** The 89-file sample was sia_-dominated (small
   files). For real programs max(live sym) ≈ total supply draws (the
   last-registered symbol sits near the end of the supply sequence),
   so EVERY TU registering more than ~460 identifiers is beyond-margin
   — which includes roughly half of the sa_ (small_arrays, ~700-line)
   subcorpus. The honest movement is structural, not a tail; v2 sweep
   numbers in the S1 record.

---

## SUPERSEDED (arc-13 S1, 2026-08-22) — the floor became the single-supply backstop

The two-check margin floor this document designed is RETIRED: arc-13
D1 (scheme R-B) removed the second id stream, so the margin and both
checks lost their subject. `util/cerb_fresh.ml` now enforces the
single-supply WINDOW invariant (every current-digest Ail symbol num in
`[tu_first .. last_issued]`, digest-filtered (min,max) fold in
ail_sym_hwm.ml) — it detects a RE-INTRODUCTION of the F-D-era
split-stream scheme (plant-tested) and never fires on healthy inputs.
§4.2's "ocaml target_rep restoration — cannot be numbering-neutral —
out of scope per the charter" was correct for arc-12's
numbering-neutral charter; arc-13's charter made renumbering the
point, and that exact route landed. See
`2026-08-22_arc13-s0-scheme-decision.md`.
