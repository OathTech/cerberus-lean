# Arc 4 results: first differential execution

Companion to the charter (`2026-08-19_arc4-exec-pipeline-charter.md`),
decision log D1–D12, frontier doc (`2026-08-19_arc4-s0-frontier.md`),
seam survey / defect register (`2026-08-19_arc4-seam-survey.md`),
corpus scoreboard (`2026-08-19_arc4-s4b-corpus-scoreboard.md`), and kit
disposition (`2026-08-19_arc4-prototype-kit-disposition.md`).

## Headline

C programs execute end-to-end through the Lean pipeline and match OCaml
cerberus: **103/106 on tests/minimal** (85 value-match + 18 UB-match,
ZERO mismatches/fails/crashes/timeouts; the 3 non-matches are OCaml-side:
one upstream TODO-crash, two prototype skip-on-Error semantics where both
sides in fact agree). Charter bar was ≥95: exceeded; every non-match
classified.

**Harness soundness (post-S5f hardening — supersedes the original
"passes in default mode" claim, which relied on head-1 verdict
extraction):** `test_exec.sh` now compares the FULL per-execution
verdict sequence on both sides (all Specified values + all UB codes, in
order), derives the expected exit code from the parsed output per the
OCaml main.ml runM convention and treats any deviation as fatal
(LEAN_ERROR) on the Lean side / visible CERB_INCONSISTENT on the OCaml
side, fails a --check-baseline run on any NOT-in-baseline file with a
failing status (no deleted-line laundering), and fails a default-mode
run that performed zero comparisons. tests/minimal holds 103/106 at this
granularity. Remaining recorded caveats (harness header): both-sides-
timeout invisibility (OCaml runs first; its timeout hides a Lean hang on
the same file) and textual stdout spoofing (unreachable without libc).
The tightening reclassified exactly ONE file across all corpora:
coverage `ptr3-006-eq-one-past-end.c` MATCH→MISMATCH — head-1 had been
masking open defect 8 (OCaml eq_ptrval forks 2 executions on a
provenance-mismatched comparison; Lean does not fork), see the
audit-dispositions section.

## Arc trajectory (per-slice, all worker-committed, all
orchestrator-verified)

| slice | result |
|---|---|
| S0 | "silent" rc=1 root-caused (stderr-lost sorry panic in generated BEq core_step2); 105-file frontier map |
| S1a | BEq fix (priority-override instances, OCaml poly-eq parity) → first Active result ever; 0→62 executing |
| S2 | harness ported + Main --batch + first baseline: 73/105 |
| S3a | symbol-id-stream collision (one-line C fix, OCaml invariant mirrored): 91/105, crash class emptied |
| S3b | struct/union concrete memory model (impl_mem.ml port) + ND-order fix + 2 effect-erasure DCE bugs: 97/105 |
| S3c | seam cheap-batch (float parsing/truncation, ptr-diff UB, div/rem semantics, NoProvPtr, decode): 102/105 |
| S4/S4b | signature-level elab differential (102/105 SAME); coverage corpus 95.7%, debug 97.6%, csmith smoke 3/3 |
| S1r | easy_update un-sorried (fuel declare); driver2 sorryAx-free GATED; arc-2 obligations landed (+1 test → 103/106) |

## Success conditions

1. ≥95/105 matching: **103/106** ✓ (all non-matches classified).
2. driver2 cone sorryAx-free, gate-enforced ✓; zero sorry target_reps on
   the execution path ✓ (concurrency stubs remain the declared boundary).
3. Standing gates green at every commit ✓ (356/356 build, unit 4/4,
   purity/cones/totality enforcing, parse ALL, core 105/106 with the
   known 078 Core-text red — whose EXECUTION differential now matches).
4. Model edits declares-only ✓ (audit-verified per batch); ZERO lem
   backend changes this arc — pins untouched at `574e326`, no pin dance
   needed.
5. Prototype kit: harness ported with preserved comparison semantics;
   full port/skip/defer disposition recorded; coverage + debug baselines
   committed (reporting-mode scoreboards); csmith kit ported, smoke run
   clean (oracle yield 12% is the recorded scale bottleneck).

## Defect register (mirror-OCaml doctrine, D8)

Precise recount from the S3c frontier ledger (the earlier "12 FIXED /
~17 OPEN" arithmetic was wrong — the fixed list it printed had 15
entries). 30 survey findings, finding 18 split into 18a/18b, so 31
dispositions:

* **FIXED — 15**: 1, 2, 3, 4, 17, 22 (S3b batch) + 5, 6, 7, 10, 12,
  18a, 20, 26, 28 (S3c batch). All with impl_mem.ml citations.
* **Documented-deliberate — 1**: 18b (enum registry stub — now known to
  be a UB-soundness miss via debug/compat-04; not corpus-forced this
  arc).
* **OPEN — 15**: 8, 9 (eqPtrval msum fork / lt-le UB), 11 (read-only
  prefixes), 13, 14, 15, 16 (store-order / memcpy checks / varargs /
  eff arrayShift), 19, 21, 23 (constraint pruning), 24, 25, 27, 29, 30.

15 + 1 + 15 = 31 dispositions = 30 findings with the 18a/b split.

Post-audit movement (S5f fix batch, see audit dispositions below):
19 (byte-provenance policy) OPEN→**FIXED**; 21 (struct BEq tag-only)
OPEN→**documented-deliberate** (unreachable from live sites, caveat in
CerbStepInstances.lean); 8 remains OPEN but is now VISIBLE (coverage
ptr3-006 reclassified MISMATCH by the sequence-level harness). Register
after S5f: 16 fixed / 3 documented-deliberate / 13 open.

Two register-pattern additions from this arc: effect-erasure (three
instances: runEffectful, set_tagDefs, with_tagDefs — every effectful
seam must be armored or natively sequenced) and description-sensitive
symbol equality.

## Declared boundary (G3 — gate-coverage honesty)

The three standing gates (exec purity, exec totality, theorem-axiom
cones) scan the **11 generated execution-slice modules only**. The
hand-written seams those modules call into are OUTSIDE every gate and
are covered only by this list:

* `CerbMem.lean` — partial defs (layout/repr/abst helpers, typeofMval,
  unqualifyAndUnatomic, stringFromMemValue) and panic! sites (mirroring
  OCaml failwith/assert-false, each cited at the site);
* `CerbND.lean` — partial `runND` (the exhaustive driver loop);
* `CerbTags.lean` — the `with_tagDefs` **axiom** (@[implemented_by] on
  the C-side set/restore extent, native/tags.c; the axiom form is what
  survives DCE — arc-4 S1r). It sits in the Mini_pipeline cone, which
  no axiom probe covers.

Expanding the gates to the hand-written seams is a priced next-arc item
(see pricing list below); no gate-list expansion was made this arc.

## Next-arc pricing (data-backed by the scoreboard)

1. libc/builtin procedure linking — 20 coverage FAILs, the single
   largest parity item.
2. Varargs (register 15) + enum registry (18b).
3. Real Core/ctype pretty-printer — unlocks body-level elab differential
   and fixes the Unspecified(<ctype>) textual class.
4. Register burn-down (~17 open defects; readonly allocations, memcpy
   checks, byte-provenance policy, constraint pruning...).
5. csmith at scale (bottleneck is upstream cerberus strictness on csmith
   output, not our side); creduce needs a networked window.
6. flexible_array_member sorryAx residue (import-leaf limitation —
   C-tier lem-backend item).
7. Gate-list expansion to hand-written seams (see declared-boundary
   section) — purity/totality/axiom coverage of CerbMem/CerbND/CerbTags.

## Audit dispositions (S5f, 2026-08-19; decision log D13)

Two adversarial audits of this record + the S5 substrate. Verdicts:
audit 1 (harness/process) — the harness's head-1 verdict extraction,
exit-code blindness and baseline deleted-line hole were real soundness
gaps; audit 2 (seams/citations) — 8 concrete findings (F5 citation
drift, F8 integer copy_offset, C1 pointer pointee type, C2 provenance
policies, C3 missing store guard, C4 float-mul upstream bug, tags.c
divergences, Main.lean sync laundering). All fix-list items implemented
(S5f worker, 3 commits).

**Fixed** (this batch):
* H1-H4 harness hardening: sequence-level comparison, exit/verdict
  consistency (LEAN_ERROR / CERB_INCONSISTENT), fatal new-failing-file
  baseline rule, zero-comparison failure. Movement: ptr3-006 only
  (defect-8 unmasking, reporting baseline updated with diagnosis).
* C1 MVpointer pointee type; C2 split_bytes/pvi_split_bytes provenance
  policies + integer-repr copy_offset=None (register finding 19 FIXED);
  C3 ill-typed-store guard (typeof + ctype_mem_compatible ports).
  Differential movement from C1-C3: ZERO on all three corpora.
* C5 citation corrections (storeM/loadM line numbers re-derived;
  CerbStepInstances driver.lem:1410 + second site :1376).
* G1 fail-closed exemplar probe; G2 sync gate (caught the stale
  generated/Main.lean — the S1r floor probe was MISSING from the shipped
  binary until this batch); G3 boundary-honesty statements.

**Recorded / documented-deliberate** (this batch):
* CerbFloat.floatMul diverges from upstream's buggy Cerb_floating.mul
  (= addition) — lembugs/2026-08-19_upstream-float-mul.md; the first
  lem-level float-mul differential will show the OCAML side wrong.
* native/tags.c: set overwrites (vs set-once failwith) and get-on-unset
  returns empty (vs failwith) — reasons in the file header.
* CerbStepInstances leaf-parity caveat (BEq PointerValueBase ignores the
  PVnull ctype; beqMemValueImpl struct tag-only et al.) — unreachable
  from the live Step_blocked2-only comparison sites (register finding 21
  → documented-deliberate).
* Harness caveats: both-sides-timeout invisibility; stdout-text spoofing
  (unreachable without libc). Audit's literal "any nonzero Lean exit
  fatal" implemented as exit/verdict CONSISTENCY (both binaries exit 1
  on single-UB by runM convention — the literal rule would flag the
  whole UB corpus); recorded in D13.

**Open** (unchanged by this batch, next-arc register): findings 8
(now VISIBLE via ptr3-006), 9, 11, 13-16, 23-25, 27, 29, 30.
