# Codex charter — fuel-totalise the Ail→Core translation (cerberus-caesium filing F) (2026-10-18, rev 4 after three reviews)

**Branch:** `arc/translation-fuel` · **worktree:** `worktrees/cerberus-lean-arc/translation-fuel`, created primed by the orchestrator
at dispatch (`scripts/new-worktree.sh cerberus-lean arc/translation-fuel`) from a mainline that already carries this charter.
**Worker:** one Codex worker. **Orchestrator:** the Claude session that wrote this; it re-verifies every gate at the boundary and lands.
The worker never merges, never pushes, never edits lem-lean or `deps/`. Rev 2 incorporates the independent review
`docs/2026-10-18_codex-charters-review.md` findings 1, 2, 10, 13, 14, 16.

## 0. Goal and success condition

**Goal.** The six `partial def`s of `lean_frontend/generated/Translation.lean` become fuel'd definitions with kernel equations by the
mechanism the execution cone uses (`declare {lean} fuel val f = …`, `declare {lean} fuel_measure val f = …`), Lean-only, the OCaml
target untouched, so that a consumer can state a theorem about `translate` by induction on typed Ail instead of over quoted Core.

**The six, with their ACTUAL generated signatures (verify at your base):**

| function | `Translation.lean` | shape | required final form |
|---|---|---|---|
| `translate_constant` | `:217` | PURE: `… (cst : constant) : generic_pexpr Unit sym` | MEASURED (structural on `cst`) |
| `collect_cases_` | `:4349` | explicit state passing: `statement → collect_cases_state → Unit × collect_cases_state` | MEASURED (structural on `stmt`) |
| `erase_loop_control_aux` | `:4420` | explicit state passing: `statement → state → statement × state` | MEASURED (structural on `stmt`) |
| `collect_visibles_` | `:4585` | explicit state passing: `statement → state → Unit × state` | MEASURED (structural on `stmt`) |
| `translate_expression` | `:1997` | `[LemFuel] [CerbGlobal.Switches] … : E.elabM (C.expr Unit)` (mutual with `translate_stmt` via the `translate_block_opt` callback) | fuel'd, exhaustion = RECORDED TRANSLATION ERROR (below); MEASURED if a joint measure closes |
| `translate_stmt` | `:4940` | `[LemFuel] [CerbGlobal.Switches] … : E.elabM (C.expr Unit)` | same as `translate_expression` |

**Why the forms are what they are.** `check_fuel_forms.sh` classifies every fuel'd worker: MEASURED needs a `<f>_measure_sufficient`
proof; ABSORBING needs the `_zero` lemma's right-hand side to be the monad's absorbing element with a fuel atom
(`test/Unit/FuelFormsTool.lean:306-308`: heads `NDkilled`/`Killed`/`t0.Error`, atoms `fuelExhaustedLoc`/`fuelExhaustedKill`, and NO
value sentinel such as `fuelExhausted`, `failwithI` or `panic`); AMBIENT is RED only for workers reachable from the drive cone
(`scripts/fuel_forms_pending.txt` header). None of the six can be ABSORBING: `elabM` is a plain state monad
(`frontend/model/translation_effect.lem:49`) with no absorbing element, and the other four have no monad at all. So:
- the four pure/state workers are DONE only when MEASURED; an unproved one is a parked result, not a landable form;
- the two `elabM` workers are MEASURED if a joint measure closes, else AMBIENT (not drive-cone-reachable, so the gate tolerates them);
  in either case their exhaustion value MUST make the translation FAIL at its boundary: `elab_state` carries `errors : list string` with `record_error`
  (`translation_effect.lem:248-256`), and `translate` runs under `runStateM_errors` (`:260-264`, used at `translation.lem:4578`),
  which turns any recorded error into a failure of the whole translation. The exhaustion value is therefore
  `record_error "<fuel-exhausted text>" >> return <any well-typed placeholder>` (the placeholder never ships: the run ends at the
  boundary). A `PEerror` Core node WITHOUT the recorded error is REJECTED (review finding 1): deferred evaluation in dead code is
  not loudness.

**Success condition (all of it, measured, quoted in the record):**
1. `grep -c 'partial def' lean_frontend/generated/Translation.lean` is 0; the generated OCaml tree is byte-identical to the base's
   (`diff -rq`); fork-drift layer 2 unmoved.
2. `check_fuel_forms.sh` green with the four pure/state workers MEASURED (standard axiom cone) and each `elabM` worker MEASURED if its
   (joint) obligation closes, otherwise AMBIENT and NOT reachable from the drive cone (quote the tool's rows for all six; the record's
   form table and the pins match the final choice); `gen_fuel_parametricity.py --check` /
   `TotalityProofTest.lean` Part 1 regenerated and green for whatever AMBIENT wrappers the generated tree now has.
3. **Exhaustion is loud, demonstrated — branched on the worker's FINAL form:** for an AMBIENT `elabM` worker, a low-fuel driver witness
   whose exhausted subtree lies in DEAD code (an uncalled function) still makes the driver fail at the translation boundary with the fuel
   text, plus a control at ordinary fuel that translates and runs; both quoted, and the classification the harness gives the failure
   stated. For a MEASURED worker the CLI fuel does not drive its own arm (`CerbND.lean:386-394`), so the obligations are: the
   measure/sufficiency proof, an ordinary production control, and a UNIT probe that calls the raw `_lemFuel` worker deliberately
   under-fuelled through `runStateM_errors` and shows the recorded error propagating to the boundary failure; unreachability of the
   arm is claimed only with its proved conditions stated. Never substitute an unrelated frontend panic for the promised witness.
4. No verdict moves anywhere: Tier A green before every commit with every existing baseline row unchanged, then Tier B on the final tree.
5. **The consumer-facing equations, per worker, per FINAL form** (review finding 10): for an AMBIENT worker the definitional equation
   `@f ⟨n⟩ <readers/switches> … = f_lemFuel n …` by `rfl` with all instance arguments spelled out (the `driver2` shape,
   `CerbND.lean:365-394` explains the measured case differs); for a MEASURED worker the wrapper's actual equation (worker at the
   measure), the measure, any hypothesis and where production calls discharge it. Unreachability of a zero arm is claimed ONLY where
   the sufficiency proof establishes it.
6. A consumer note `docs/2026-10-18_consumer-note-cerberus-caesium-translation-fuel.md`.

Rulings this rests on, paraphrased: [USER 2026-10-17] this work is needed by cerberus-caesium and is chartered (its note 2 §F; its
agent's list, item 1). [USER 2026-09-03] no magic values: a fuel bound is a quantifiable parameter; an exhaustion value is never a
plausible default result. [USER 2026-09-04] the lem structure is not changed for OCaml's sake — only `declare {lean}` lines are
added here. [USER 2026-09-08] nothing new out of policy: sufficiency proofs are derivations over the recursion's structure or they
are not written. Standing: fail-closed and fail-noisy; never a Lean build uncapped; the grind tripwire; the operator's words are never
quoted verbatim in files or commit messages.

## 1. What is known (verify what you touch)

| Fact | Where |
|---|---|
| The declare syntax and 134 precedents | `grep -rn 'declare {lean} fuel' frontend/model/*.lem`; measures with and without hypotheses: `core_aux.lem:2615-2663`; monadic exhaustion precedents: `driver.lem:1914-1916` |
| Fuel instance already threaded through the front end | `lean_frontend/Main.lean:667` `frontendTU [LemFuel] [CerbGlobal.Switches]`; the two `elabM` workers already bind `[LemFuel]` |
| The error accumulator and the boundary check | `translation_effect.lem:43` (`errors`), `:248-256` (`record_error`, `record_error_at`), `:260-264` (`runStateM_errors`), `translation.lem:4578` |
| The gates that move | `check_fuel_forms.sh` partition (vacuity guards; the four forms partition the table); `gen_fuel_parametricity.py`'s pin list; `TotalityProofTest.lean` Part 1; `scripts/fuel_hypotheses.txt` ONLY if a measure needs a hypothesis (TAB row, `.lem:<line>` cite, reviewer); `scripts/fork_drift_manifest.txt` [source-content] row for `translation.lem` (single-row re-pin with a dated NOTE; `python3 scripts/check_fork_content.py --root . --manifest scripts/fork_drift_manifest.txt --emit` with the path on stdin; never `--refresh`) |
| Proof carriers are discovered by filename | `check_fuel_forms.sh:108-113` finds `*_lemMeasureProofs` modules; a new carrier `lean_frontend/Translation_lemMeasureProofs.lean` needs its Lake root in `lakefile.toml` and its line in `handwritten_copy.manifest` (no static carrier list exists) |
| Mutual recursion is supported by the backend's fuel transform | lem-lean `tests/comprehensive` target `lean-fuel-mutual-reader` |
| Frontend totality is outside the current claim | `lean_frontend/DESIGN.md:125` — this slice extends the claim to the translation; the sentence moves in D5 |

## 2. Deliverables (ordered; each ends with the stated check and a commit)

**D0 — Base.** Tier A on the untouched worktree (the baseline for "no row moves"); the six `partial def` lines; the generated OCaml
tree's hash set.
**D1 — The four pure/state workers, MEASURED.** Declares with `fuel_measure` (structural size of the statement or constant); the
sufficiency proofs in the new carrier; register rows only if a hypothesis is unavoidable. Tier A before each commit. One commit per worker or natural group. **Bound:** a proof that does not close in ordinary time means the measure's shape is
wrong — stop that worker, record why, and continue with the others; it is then NOT done (see §3).
**D2 — The two `elabM` workers.** Declares with the recorded-error exhaustion; success item 3's witnesses for the final form, added as
a unit test or lane plant that FAILS without the recorded error. Attempt a joint measure for the mutual pair; if it closes, MEASURED; otherwise AMBIENT
with the loud boundary. Tier A before each commit.
**D3 — Pins and manifest.** Parametricity pin regenerated; the manifest row re-pinned with a NOTE; `check_fuel_forms.sh` rows quoted.
**D4 — Tier B** (`python3 scripts/release.py --mode full`) on the final tree; quote the summary lines.
**D5 — Documents.** The record `docs/2026-10-18_translation-fuel-record.md` (forms table per success item 5, the witnesses verbatim,
gate output, deviations from this charter with reasons); the consumer note; `DESIGN.md` §4's frontend-totality sentence; `TODO.md`
for anything left AMBIENT or parked; `VALIDATION.md` where it enumerates fuel'd workers or states the totality claim.

## 3. Flex — what you decide, and when to stop instead

- Yours, recorded with [AGENT] and a reason: the order within D1; the exact exhaustion text; the carrier's layout; whether the
  mutual pair gets a joint measure; splitting commits.
- Not yours: any `.lem` BODY change; lem-lean or `deps/`; any baseline row; any default value; widening or weakening a gate; the pins.
- **Partial completion is honest, not landable as "done":** if a pure/state worker stays unmeasured, the slice ships with that worker
  still `partial` (do NOT add a fuel declare whose exhaustion is a plausible value) and the record says so; the orchestrator decides
  whether to land the rest.
- **Stop and report (record + commit on the branch, no merge) when:** the backend cannot express a needed declare (the callback-threaded
  recursion or the mutual block) — write the minimal lem-lean change you believe is needed as a proposal; any existing baseline row
  moves (quote before/after; a finding, not a re-record); a build or proof pass approaches one hour; the generated OCaml tree changes;
  you are done.

## 4. Rules (binding)

- **Environment.** `source /home/dev/projects/cerberus-lean-proj/scripts/env.sh` (or `scripts/ce`); every `lake`/`lean` invocation
  through `scripts/capped` (`CERB_MEM_MAX=48G`, never `none`); one heavy job at a time; exit 137 or a KILLED banner is a failure.
- **Regeneration.** After any `.lem` edit: `make prelude-src`, `make lean-prelude-src`, rebuild the oracle, capped `lake build`; after
  any hand-written `lean_frontend/*.lean` edit: `make lean-prelude-src` before `lake build`.
- **Checks.** Tier A (`python3 scripts/release.py --mode fast`) green before EVERY commit, per `scripts/LADDER.md`'s rule for commits
  and worker-boundary claims; Tier B (`--mode full`) at close-out (D4), quoted. The orchestrator re-runs Tier A at the boundary and
  Tier B before landing; worker-claimed green is never accepted. Proof-bearing deliverables: `#print axioms` on every new lemma shows
  only `propext`, `Classical.choice`, `Quot.sound` (the existing gates enforce the cones); kernel replay of the built carriers with the
  shipped checker (`lake env leanchecker`) is a GATE by the standing rule (the container's Lean trust checks): it is run, the modules
  and the checker's exit status are quoted in the record, and a failed or skipped replay is never accepted because its output was
  quoted. The orchestrator will propose naming this check in the project's working-practices doc; until the operator rules otherwise,
  the standing rule binds.
- **Provenance.** Machine outputs verbatim; derived tallies labelled; your decisions [AGENT]; operator rulings only as paraphrased in
  §0; never a verbatim quotation of the operator. Commit messages state what was verified, with the gate lines, and end with the
  attribution your harness prescribes.
- **No trust gaps.** No `sorry`, `native_decide`, `bv_decide`, new axioms, `unsafe`, `implemented_by`, `extern`.

## 5. Reading list

Container `CLAUDE.md` · `lean_frontend/CLAUDE.md` · `lean_frontend/DESIGN.md` §4 · `lean_frontend/VALIDATION.md` (fuel sections) ·
`scripts/LADDER.md` · `docs/2026-09-04_fuel-parameter-C1-record.md` … `C4-record.md` · `docs/2026-09-05_fuel-parameter-C3-record.md`
§7–§8 · lem-lean `doc/lean-backend/2026-09-03_fuel-parameter-design.md`, `2026-09-04_fuel-measure-record.md`,
`2026-09-05_measure-hypothesis-record.md` · `frontend/model/translation.lem`, `translation_effect.lem` · `lean_frontend/CerbND.lean:365-394`
· `test/Unit/FuelFormsTool.lean` · `docs/2026-10-18_codex-charters-review.md` (findings 1, 2, 10) · the consumer's ask:
`/home/dev/projects/cerberus-caesium/.tmp/filings/2026-10-17_cerberus-lean-note-2.md` §F and
`docs/2026-10-17_consumer-note-cerberus-caesium-response-note-2.md`.
