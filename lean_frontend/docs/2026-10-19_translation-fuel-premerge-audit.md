# Pre-merge audit: arc/translation-fuel (049eb9a0a..aecdd8708)

Trimmed independent audit (one fresh reviewer, ~13 minutes of run time, scope: the four sufficiency proofs, the recorded-error boundary semantics including the dead-code witness, the classifier's plant coverage, the consumer note's claims; the reviewer was free to look anywhere). Launched by the orchestrator 2026-10-19 with the pre-merge ask outstanding; the P1 was reproduced independently by the orchestrator on the slice's binary and the pre-slice primary binary (same program, fuel 128: slice prints `Undefined {ub: "UB036_exceptional_condition", …}` exit 1, pre-slice panics exit 134; default fuel: `Specified(192)` on both). Disposition of each finding is in the follow-up commit(s) and the landing note. Verbatim report follows.


Reviewer: independent (Claude Fable 5.1), 2026-10-19. Worktree
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/translation-fuel,
HEAD aecdd8708. No tracked file was modified; `git status --porcelain` is empty
after the review. Scratch under .tmp/audit-translation-fuel-20261019/.

## Verdict: NOT MERGEABLE

The slice's central invariant ("exhaustion records an error so
runStateM_errors refuses the entire translation") does not hold on a
production call path inside this repository, and the slice turns a
previously loud failure on that path into a silent, wrong semantic verdict.

## Findings

### P1 — Translation fuel exhaustion inside a constant expression is laundered into `Undefined {ub: "UB036_exceptional_condition"}` (silent, exit 1, no FUEL marker); regression vs. base

Files: frontend/model/mini_pipeline.lem:124,157 (generated
lean_frontend/generated/Mini_pipeline.lean:142,175);
frontend/model/translation.lem:4607-4612 (the new ambient fuel val declares);
lean_frontend/VALIDATION.md (new paragraph after the (A)/(B)/(C) table);
consumer note section "Both zero arms"; commit message 17eeb7708.

Claim: the desugarer's constant-expression evaluator (Mini_pipeline.toCore)
calls the ambient translate_expression wrapper and runs it with plain
TranslateEff.runStateM, which discards st.errors; the zero arm's mk_skip_e is
then executed by the mini-run and its failure is reported as a desugar-time UB.

Mechanism (code as committed):
- mini_pipeline.lem:124: toCore = TranslateEff.bind (translate_expression Nothing true ECTX_other ... a_e) ... — the ambient wrapper, budget LemFuel.fuel = --fuel N.
- mini_pipeline.lem:157: let (core_expr, translate_final_st) = TranslateEff.runStateM (toCore a_expr) (TranslateEff.elab_init sup callconv) — not runStateM_errors; the recorded fuelExhaustedMsg is dropped.
- mini_pipeline.lem:211-216: the mini-run of the skip-replaced Core yields ND.Killed _ (ND.Undef ub_loc [ub]) -> Eff.fail (ub_loc, DESUGAR (Desugar_UndefinedBehaviour ub)) -> the driver prints a UB verdict.
- Reached from cabs_to_ail.lem:1140,1761,2414,3220 and ctype_aux.lem (enum constants, array sizes, case labels, sizeof of VLA-shaped types, ...), i.e. from every driver entry point that desugars (--batch, --pp-core, --call; Main.frontendTU, Main.lean:652).

Reproduction on the slice's own built binary (fixtures in the scratch dir;
.json produced by the worktree's OCaml --cabs-json; LEAN_ABORT_ON_PANIC=1,
scripts/capped, --batch --first):

    === cexpr-enum fuel=128 rc=1
    stdout: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:646--1:1039>"}
    stderr:
    === cexpr-enum fuel=100000000 rc=0
    stdout: Defined {value: "Specified(192)", stdout: "", stderr: "", blocked: "false"}
    === cexpr-array fuel=128 rc=1
    stdout: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:653--1:1052>"}
    === cexpr-case fuel=128 rc=1
    stdout: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:681--1:1074>"}
    === cexpr-sizeof fuel=128 rc=1
    stdout: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:670--1:1069>"}
    === cexpr-static-init fuel=128 rc=134
    stderr: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted

(cexpr-enum.c = `enum { X = 1 + (1 + (... 192 deep ... 0)) }; int main(void) { return X; }`;
array/case/sizeof variants put the same expression in an array bound, a case
label, and sizeof(int[...]). Only the static-initializer form goes through
translate_program/runStateM_errors and fails loudly.)

Bisection pinning it to translation fuel (same binary):

    === enum-d60  fuel=128 rc=134 | err: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: TODO error: the driver found less/more than one active execution
    === enum-d100 fuel=128 rc=134 | err: (same)
    === enum-d150 fuel=128 rc=1   | out: Undefined {ub: "UB036_exceptional_condition", ...}
    === cexpr-enum fuel=300  rc=134 | err: ... TODO error: the driver found less/more than one active execution
    === cexpr-enum fuel=1000 rc=0   | out: Defined {value: "Specified(192)", ...}

Depth < fuel: translation succeeds and the mini-run's execution exhausts
(loud). Depth > fuel: the translation zero arm fires and the verdict is UB.

Regression: the pre-slice binary (primary checkout, HEAD 049eb9a0a, generated
Translation.lean with `partial def translate_expression`) on JSON from its own
oracle:

    === PRE-SLICE enum-d150 fuel=128 rc=134 | err: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: TODO error: the driver found less/more than one active execution
    === PRE-SLICE cexpr-enum fuel=128 rc=134 | err: (same)
    === PRE-SLICE cexpr-enum fuel=1000 rc=0   | out: Defined {value: "Specified(192)", ...}

Before the slice every low-fuel outcome on this path was a failwithI panic
(exit 134). After it, a fuel-dependent outcome is an Undefined verdict with
exit 1 and empty stderr: the exec lane will read it as a verdict MISMATCH
against the oracle rather than FUEL, and a Lean-only consumer gets a false UB
claim. --pp-core shows the same:

    === --pp-core cexpr-enum fuel=128 rc=1
    stdout: Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:646--1:1039>"}

Statements this falsifies, as committed: translation.lem:4608-4609 ("so
runStateM_errors refuses the entire translation even for dead code.
mk_skip_e is only a typed intermediate: the boundary cannot return it");
VALIDATION.md ("runStateM_errors rejects the entire translation ... The exec
lane reports fatal FUEL, never agreement" — the record repeats this); the
consumer note ("translate finishes through runStateM_errors, which rejects
the accumulated error" — true of translate, but the note's own next sentence,
"Callers using the raw state computation must also check its errors",
describes exactly what Mini_pipeline fails to do); commit 17eeb7708
("record an error so exhaustion rejects the entire translation, including
dead code"). None of the slice's tests cover a constant expression:
test_translation_fuel.sh puts the deep expression in a function body.

Fix direction (reviewer's view, not a prescription): the ambient pair's
exhaustion must be absorbing on every run point, not just translate. Either
make Mini_pipeline (and any other raw runStateM consumer) go through
runStateM_errors, or make the zero arm itself fatal (failwithI), or give
elabM a real failure channel. Whichever is chosen needs a witness on the
constant-expression path added to test_translation_fuel.sh, and the three
documents plus the lem comment corrected.

### P3 — test_fuel_plant.sh row "exec/real driver at --fuel 1 -> translation FUEL:panic" does not witness the translation boundary it is named for

File: scripts/test_fuel_plant.sh:181-182 (comment at :158-160).

Claim: the row's assertion
'^\[1/1\] FUEL 001-return-literal \(FUEL:panic, exit 134\): lem: fuel exhausted$'
is satisfied equally by the pre-slice opaque-sentinel panic (bare
`lem: fuel exhausted` line, also FUEL:panic, exit 134) because
test_exec.sh:632 prints a fixed suffix:
echo "[$file_num/$total_to_test] FUEL $filename ($fuel_kind, exit $lean_exit): lem: fuel exhausted".
Nothing in the row reads stderr for the failwithIImpl envelope. The boundary
IS the translation one today (I ran it: rc=134, stderr
`PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted`),
but the row would stay green if the ambient zero arms regressed to the pure
sentinel. test_translation_fuel.sh does grep the envelope, so the property is
covered elsewhere; the row's comment and name overclaim.

### P3 — The record certifies a commit that is not on the branch

File: lean_frontend/docs/2026-10-18_translation-fuel-record.md (title block,
"Completion and deviations", "Orchestrator review follow-up").

Claim: the record's full-tier result is attributed to f12d9645a, which is not
reachable from arc/translation-fuel (`git branch -a --contains f12d9645a`
prints nothing). 17eeb7708 is that commit rebased from b1c539c45 onto
049eb9a0a; `git diff --stat f12d9645a 17eeb7708` shows one file, the landing's
docs/2026-10-18_codex-charters-review.md (+1287), so the certified tree differs
from the branch's only by a docs file. The record should say the rebase
happened and that 17eeb7708 carries the identical implementation tree; a
reader cannot currently verify the "at f12d9645a" claims from the branch.

### Note — the mini-run's execution exhaustion is a failwithI "TODO error: ..." panic, not FUEL-classified (pre-existing)

File: frontend/model/mini_pipeline.lem:216.

Pre-slice and post-slice alike, exhausting the ND fuel inside the
constant-expression mini-run reports `TODO error: the driver found less/more
than one active execution` (exit 134), which classify_fuel_outcome does not
recognise (the exec lane will call it LEAN_CRASH). Not introduced by this
slice; recorded because it is the other half of the same hole and any fix for
P1 on this path will meet it.

### Note — "outside the execution dependency closure" is true of the gate's roots, not of the binary

VALIDATION.md (C) row and the record's "AMBIENT, outside drive closure". The
fuel-forms closure starts at drive/initial_driver_state/the ND
runners/CerbCall.driveCall; translate_expression/translate_stmt run on every
invocation via Main.frontendTU (Main.lean:652) and via Cabs_to_ail ->
Mini_pipeline. The row's hedge ("no general API unreachability claim") covers
it, and the classification is pre-existing gate policy, but P1 shows why the
hedge matters.

## Checked, no finding

- Obligations vs proofs. The four generated obligations
  (generated/Translation_auxiliary.lean:19-42) delegate to
  Translation_lemMeasureProofs.*_measure_sufficient with the same binders and
  types; #check prints the contract shape (cst.lemSize <= lemFuel ->
  translate_constant_lemFuel lemFuel ... cst = translate_constant ... cst, and
  likewise for the three statement workers). The hand-written copy under
  generated/ is byte-identical to lean_frontend/Translation_lemMeasureProofs.lean.
- Proof structure. Each _stable theorem is a strong induction on a size
  bound; the succ/succ step unfolds one layer of the worker on both sides and
  uses the IH only on strict subtrees (key), including list elements via
  constant_mem_lt/statement_mem_lt and List.map_congr_left. The Lem bodies
  (translation.lem:194, :3241, :3316, :3428) recurse only on immediate
  subterms or List.map/mapM_/mapM0 over immediate child lists, so lemSize of
  the argument does bound the recursion. Stability as stated does not itself
  assert the zero arm is unreached; the proof's shape (succ-arm unfolding at
  every level) is what makes it unreachable at the wrapper's fuel, and the
  docs say exactly that.
- Axiom cones. #print axioms on the four sufficiency theorems, the four
  _stable lemmas, translate_expression_lemFuel_zero,
  translate_stmt_lemFuel_zero, and both TranslationFuelTest.*_zero_boundary
  theorems: all [propext, Classical.choice, Quot.sound]; no sorry.
- Function-body path. wrapped_translate_expression ->
  E.track_temporary_objects (translation_effect.lem:180-186) and
  with_block_objects (:148-178) rebuild the state from the inner st', so
  recorded errors survive to translate_program's runStateM_errors
  (translation.lem:4578). test_translation_fuel.sh's two witnesses (dead
  function body) genuinely exercise this path; the plant it describes
  (replace the zero arm with return0 mk_skip_e) would fail it.
- Boundary theorems. statement_zero_boundary/expression_zero_boundary are
  rfl against runStateM_errors ... (elab_init ...) = failwithI
  CerbFuel.fuelExhaustedMsg; runStateM_errors fails on the FIRST recorded
  error (List.reverse st.errors), so with a clean initial state the
  exhaustion message is the one reported.
- Classifier. FUEL_ELAB_PANIC_LINE_RE anchors the whole line, requires decl
  failwithIImpl, tolerates line/column drift, and requires exit 134. The
  envelope format matches LemLib: failwithIImpl uses panic! (prefixed
  envelope) while fuelExhaustedWithImpl uses bare @panic (bare line), so the
  two sub-kinds are distinct. No other failwithI site in the tree carries the
  reserved message (grep over lean_frontend/*.lean and generated/*.lean:
  none). `bash scripts/test_fuel_classifier.sh`: `23 fixtures, ALL OK`;
  plants cover recognised (exit 134 + exact envelope) and not-recognised
  (exit 1; other message; message suffix; envelope inside quoted program
  stdout).
- Loop row. execution-loop.c at --fuel 8 and --fuel 128 both give
  `Error {msg: "lem: fuel exhausted"}` exit 1 (FUEL:kill); default gives
  Defined ... Specified(0). Since translation exhaustion is now always a 134
  panic, FUEL:kill, exit 1 does witness execution exhaustion.
- Pre-slice census. Six partial defs in the primary checkout's
  generated/Translation.lean (lines 217, 1997, 4349, 4420, 4585, 4940); zero
  in the slice's. DESIGN.md's "six former partial workers" is correct.
- Fuel-forms gate. The record's verbatim rows classify the four as MEASURED
  and the two as AMBIENT, ambient_reachable=0; the pending register has no
  data rows, consistent with the gate's closure roots.
- Manifest. sha256sum frontend/model/translation.lem = 09475cc7...86d69c =
  the new manifest row; # NOTE lines already exist in the file (lines 1-10),
  so the parser tolerates them.
- Parametricity pins. 14 -> 16 in TotalityProofTest.lean and both selftest
  controls of gen_fuel_parametricity.py; the two new rfl examples spell out
  both instance arguments.
- Provenance tags. aecdd8708 re-tags the P2/P3 instruction from [USER] to
  [AGENT] with the relay stated; the remaining [USER] entry (gate scheduling)
  and [AGENT] entries read as the right attribution. Commit messages describe
  what was done; 17eeb7708's "rejects the entire translation, including dead
  code" is the P1 overclaim.
- Not run by me. lake env leanchecker replay and the full battery (they are
  the orchestrator's gates and a battery is in flight); the OCaml
  byte-identity claim (fork-drift gate).
