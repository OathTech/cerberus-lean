# Independent review of the five worker charters — 2026-10-18

## Verdicts

| Charter | Verdict | Main reason |
|---|---|---|
| Translation fuel | **not ready** | The proposed exhaustion representation can be ignored, and the advertised all-ABSORBING intermediate result cannot satisfy the existing classifier. |
| Core quotation | **not ready** | The acceptance check does not establish the promised equality; maps also make the proposed canonical reconstruction a substantive design issue. |
| Stack ceiling | **not ready** | The proposed intervention does not address recursion inside an ND action, and the acceptance criteria reject successful completion of finite programs. |
| Outcome protocol S1–S2 | **not ready** | Dispatch is correctly gated, but the charter also contains an impossible migration restriction and promises distinctions that need S3. Its referenced classifier has unresolved acceptance defects. |
| Failure-monad design | **ready with edits** | The design scope and repository boundary are sound. Make the measurement and reproducibility requirements concrete before dispatch. |

These are independent review judgements [AGENT 2026-10-18]. No charter was
edited. The outcome verdict does not treat its explicit dispatch gate as an
accidental omission: acceptance of a corrected design and recorded rulings
remain prerequisites even after the charter findings are fixed.

## Scope and evidence

Reviewed the four cerberus charters at `19196fb2ac6c769d7e9cfdc172303c8e68ddd110`
and the lem charter at `d0f597259e29ca3155e1bb3356aca983d6e50e7c`. References to
their lines below use those versions. The cerberus source/response base is
`32ab44e4a76dc68d11baffc77f7aca95b4e71efc`; the outcome design is
`99a8ddb7834c2ba890fb65083f10ea69d06b1a36`. Lem mainline was
`c74091d0aa2528b53fc6275d28e4d0aac54e9476`; cerberus's functional Lem pin is
`2d3a492758cb23dc4e417f2961983d25b36ce130`.

Read the container and frontend `CLAUDE.md` files first, then the charters,
consumer filing A–F, response note, referenced outcome design, relevant
source and instruments, and the September 11 charter precedents. The
review used source inspection and small read-only inventories. No build,
lane, Lean invocation, driver run or new runtime measurement was performed.
Generated Lean is untracked: its cited locations were inspected in the
existing primary generated tree, with the corresponding tracked sources
checked at the base. This is not a regeneration/freshness certification.

The review and artifact instructions are applied together: source review
is read-only; the explicitly requested new review worktree, this report
and its local commit are the sole mutations [USER 2026-10-18, scope
paraphrased]. No merge, push, shared build-state change or charter edit is
part of this review.

## Findings, most severe first

### 1. [P1] An error node in translated code is not an absorbing translation failure

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:63–68`
(also `:25–28`, `:103–104`).

D1 recommends returning a Core `PEerror` node while preserving the state.
That is a successful translation result containing executable error syntax.
An uncalled function or untaken branch can contain that node without the
driver ever evaluating it. The cited `core_eval.lem:605` establishes what
happens *when evaluated*, not propagation of translation exhaustion. The
existing large-default-fuel lanes cannot establish the missing property.
This permits a worker to meet the local zero equation and green-lane bars
while accepting an incompletely translated program.

The fact table also overlooks an existing reporting route:
`frontend/model/translation_effect.lem:43,248–264` carries `errors`, with
`record_error` and `runStateM_errors`; `translation.lem:4578` uses that final
check. This is not an absorbing monad, but it matters when choosing an
exhaustion policy.

**Suggested fix:** require a translation-boundary failure whenever a
reachable translation worker exhausts, or prove that exhaustion cannot
occur in the supported wrapper. Specify its resource classification and
the consumer-facing logical contract. Add a low-fuel witness with the
exhausted subtree in dead code, plus a successful control. Investigate the
existing error accumulator for the actual elaboration-monad workers; if
safe propagation needs a forbidden body/type/backend change, stop for a
new scope. Do not accept deferred `PEerror` evaluation as the proof of
loudness.

### 2. [P1] The six-ABSORBING fallback is unavailable under the required gate

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:70–83`
(also `:48–53`, `:96–104`).

The charter makes six ABSORBING workers an acceptable first commit and
allows failed measure attempts to remain ABSORBING. At this base,
`test/Unit/FuelFormsTool.lean:306–308,427–442` requires a typed absorbing
head and a fuel atom, and explicitly excludes `fuelExhausted`,
`fuelExhaustedWith`, `failwithI` and panic sentinels. A `PEerror` result does
not qualify. A loud pure sentinel does not qualify either. The charter
forbids widening or weakening the gate.

This is compounded by the wrong return-type inventory. In the inspected
`generated/Translation.lean`, `translate_constant:217–219` returns a pure
`generic_pexpr`, not `elabM`; `collect_cases_:4349–4350` and
`collect_visibles_:4585–4586` are state computations returning `Unit`, not
lists; `erase_loop_control_aux:4420–4421` is also state-passing. D1's
three-versus-three grouping is not the actual type boundary. Green gates
alone would also be insufficient if these new workers merely appear as
AMBIENT outside the execution dependency closure.

**Suggested fix:** replace the table with the actual signatures and give
each worker a feasible required form. For pure/state helpers without a
typed absorbing result, make the needed sufficiency proof a completion
condition; an unproved helper is a parked result, not the promised
landable all-ABSORBING slice. If a different accepted form or outcome
mechanism is required, obtain that design decision first. Inspect the six
named classifier rows explicitly. Do not change the classifier to call
ordinary Core syntax absorbing.

### 3. [P1] The quotation test can pass while the promised Lean equality is false

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:18–24`
(also `:38–41`, `:58–70`).

Runtime `printed == original` does not establish propositional equality.
There is a concrete lossy comparison in this representation:
`lem-lean@2d3a492:lean-lib/LemLib.lean:1192–1194,1241–1242` compares `Fmap`
binding lists while ignoring its captured comparator and tree
representation. The comparator is used by lookup (`:1216–1219`). Changing
such a field can leave the charter's check green. The proposed single
altered-field plant can choose a field that BEq does observe and miss
these failures entirely. `Core.lean:2514` is a `SetType` instance, not the
BEq declaration.

Canonical map reconstruction may be extensionally appropriate for a
particular consumer, but it is not automatically equality of the actual
Lean `Fmap` values. Arbitrary captured functions cannot be recovered by a
generic value printer. This needs a supported-domain/provenance argument,
not an instruction to use BEq. The container's `CLAUDE.md:201–205` also
requires a theorem for agreement between Lean artifacts.

**Suggested fix:** settle the exact relation first. For literal equality,
preserve all relevant representation fields and known comparator
provenance, and provide a kernel-checked correctness bridge for the
supported quotation representation; validate its axiom cone and replay
with the toolchain checker. Keep runtime fixture round trips as additional
evidence. If only an extensional/canonical relation is feasible, propose
that change of consumer contract explicitly and prove that relation;
do not silently substitute BEq. Include representation/comparator-sensitive
negative controls and a stop rule if the proof or supported-domain design
exceeds the slice.

### 4. [P1] Rewriting the outer ND runner does not control recursion inside an action

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:39–42,53–58`.

The charter identifies `drive_nonmemory_steps_aux2` as the exhausting
recursion but recommends an explicit continuation structure or depth
budget in `CerbND.lean`. Those are different layers. `CerbND.lean:127`
calls `m_act st0` before it can inspect another node or decrement its own
budget. The inspected `generated/Nondeterminism.lean:338–351` executes an
active bind continuation immediately; `generated/Driver.lean:1313–1338`
recurses through those continuations. The inner computation can therefore
consume stack without returning control to the outer runner. An outer
depth guard cannot interrupt that call.

The stop rule for a Lem-only remedy is useful, but D0 measures a backtrace,
not whether the proposed intervention can reach the offending recursion.
It leaves the worker directed toward a substantial rewrite with no
established causal connection to the failure.

**Suggested fix:** add a bounded design checkpoint that distinguishes
stack in action production/bind continuations from stack in traversal of
returned ND nodes. Demonstrate a control point on the production failing
path before implementing the runner rewrite or guard. If the required
change belongs in generated Driver/Nondeterminism, propose a supported
source/target-representation or backend slice, with correspondence
obligations and an explicit repository boundary. Do not doctor generated
output or silently clamp the ambient semantic fuel.

### 5. [P1] Stack acceptance wrongly requires two finite programs to fail

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:9–21`.

`tests/mem-scale-probes/probes/d_loop_1000000.c:1–6` performs a finite
million-element loop; `e_memcpy_1000000.c:1–7` performs finite memset/memcpy
operations. They are not unbounded programs. A structural stack fix may
let either complete normally when its budgets suffice, but success item 1
requires a fuel/resource outcome for all four witnesses at every tested
fuel. This rewards a new premature cutoff and rejects a correct
completion. No required positive control or explicit preservation theorem
checks that a new guard leaves successful runs intact.

**Suggested fix:** separate diverging witnesses, which must stop through
the declared resource channel, from finite stress cases, which may either
complete with the oracle's full observation or exhaust a named budget.
Require a positive below-bound completion and the existing design's
preservation property, proved for the altered runner where appropriate.
Identify the diverging-callee source and exact commands. The Lean CLI has
no `--mode=exhaustive` option (`Main.lean:1391–1394,1520–1535`); use its
default exhaustive mode, and `--first` for its single-trace mode. Give the
OCaml flags separately.

### 6. [P1] S1–S2 cannot deliver the advertised upstream/shared distinction for all A–D cases

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:13–27,61–62`.

The success condition promises that the consumer can classify note-2 A–D
by class. A1/A2/A6/A7 and the `truncToInt` portion of A5 are hand-written
pure mirrors. Their envelope migration is S3, explicitly forbidden here.
Under the design's `:237` rule, they still read as `SHARED_CRASH`, not the
`UPSTREAM_CRASH` promised by its consumer mapping (`:260–267`). The design
itself admits this temporary misattribution at `:309–314` yet claims the
consumer receives its answer at S1. Choosing one easy program per letter
can conceal the unconverted subclasses.

**Suggested fix:** state the S1–S2 transitional contract precisely, with a
table for each consumer message family and the slice that makes its class
accurate. Keep those remaining pure mirrors explicitly outstanding in
the consumer note. Alternatively move the full consumer-classification
exit to an S3 charter. Do not expand S1–S2 implicitly or report coarse
misattribution as the requested distinction.

### 7. [P1] The inherited classifier invents an OOM diagnosis from a bare exit 137

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:18–22,38–39`,
through `2026-10-17_outcome-protocol-design.md:233`.

The required decision procedure classifies any status 137 as
`RESOURCE/cap`. The existing codec (`scripts/observations.py:282–283`)
rejects such a capture; it does not establish that an OOM occurred.
`scripts/LADDER.md:144–150` expressly distinguishes the positive cgroup
OOM witness from bare status 137, and row B9 includes a native exit-137
plant. A program can exit 137 without hitting a cap, or be killed for a
different reason. The design's claimed equivalence with today's rule is
false.

**Suggested fix:** require cap evidence for `/cap`; leave an unexplained
137 unclassified/RED unless a separately approved generic termination
class is introduced. Add the native-exit and signal-without-OOM controls
to the classifier acceptance cases. Resolve this in the design before
dispatch, not by letting the implementation worker improvise.

### 8. [P2] The outcome design supplies contradictory answers for the same capture

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:18–22,48–49`,
through `2026-10-17_outcome-protocol-design.md:238–239,284–286`.

The ordered procedure says an envelope inside an ordinary `Error` record
is RED, while the plant list says the same capture remains a VERDICT.
The charter requires both every procedure rule and the plant matrix.
It also says every class forged in every other class's shape is rejected,
although the design deliberately admits several classes on the same
channel and treats envelope text in program data as ordinary data.

**Suggested fix:** reconcile the decision procedure and plants in the
accepted design. State acceptance per class/channel/data position, rather
than the blanket cross-class rejection claim. Ordinary program data must
not acquire authority merely because it resembles an envelope. The
worker should receive one expected result for each capture.

### 9. [P2] S2 forbids the register fields that the migration must change

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:25–26,51–52`.

The charter permits a register re-seal with changes to the note column
only. A new message expression changes the `msg` key and therefore its
seal. `scripts/failure_reach_register.txt:18–26` defines both; the design
explicitly authorizes message-key and seal changes at `:318–320` while
preserving reach/position classifications. A note-only edit cannot match
the new census, so the required row-1 gate cannot pass.

**Suggested fix:** authorize exactly the affected message keys and seals,
plus explanatory notes; retain position/reach/need/invariant/witness
claims unless a separate finding is raised. Review each old-to-new site
mapping rather than treating a reseal as automatic approval.

### 10. [P2] The required fuel equation is false for measured wrappers

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:25–28,77–83`.

The record must give `@f ⟨n⟩ = f_lemFuel n` for each of the six while D3
tries to make them measured. A measured wrapper calls its worker at its
input-derived measure, not at the ambient `n`. Some retain an ambient
instance only for callees. The cited `CerbND.lean:365–394` explicitly
distinguishes these cases and explains why that equation is false for
measured `hack`. A sufficiency equation also establishes stability above
a bound; by itself it does not prove that no zero arm was visited.

**Suggested fix:** require the actual wrapper equation per final form,
with all reader/switch arguments; for measured workers state the measure,
sufficiency hypotheses and their discharge at production calls. Claim
unreachability only where the structural proof establishes it. Keep the
ambient-parametricity pins limited to their actual inventory.

### 11. [P2] The stack file fence cannot support its new-resource alternative

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:17–21,60–61,80–83`.

A new resource text/class must be recognized by every owning classifier,
but the file fence allows plant scripts and baselines, not the classifier
implementations (`observations.py`, `common.sh`, the exec/CI/GCC lanes and
mem-scale measurement classifier as applicable). Copying the current fuel
text avoids some edits but conflates depth exhaustion with semantic fuel
exhaustion. The outcome design separately fixes the resource forms and
forbids spelling RESOURCE in an envelope. No dependency order reconciles
these two workers' choices.

The charter also directs re-recording rows in exec/immaculate baselines
without identifying existing rows for these four witnesses. The two
named stress programs live in the mem-scale suite; the consumer witnesses
are not pinned by this charter. Historical measurements must not be
rewritten as if they had measured the new implementation.

**Suggested fix:** settle the resource wire contract and worker ordering
before dispatch. Either use an explicitly justified existing outcome or
authorize the exact classifier files and contract/proof updates needed.
Inventory the actual affected rows at D0; add a reproducible regression
witness where none exists, and record fresh measurements separately from
historical results. Preserve the stop on unexpected baseline movement.

### 12. [P2] Quotation acceptance does not exercise its multi-TU promise

**Location:** `lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:16–21,48–59`.

Single- and multi-TU inputs are required, but the mandatory round-trip
fixtures are all individual translation units. The existing multi-TU
execution lane does not invoke the new quotation flag. A worker can
quote a pre-link file, or attach the flag only to the single-TU path, and
pass the stated quotation tests. The pre-conversion `file Unit` and
post-conversion `file core_run_annotation` also coexist in Main
(`:1203–1212`); the exact extraction point should be explicit.

**Suggested fix:** require one linked multi-TU round trip with a
cross-TU declaration/reference and pin the value after `convert_file` at
the same execution entry used by the driver. Retain the single-TU tests
and refusal controls. This is a small addition, not a new exhaustive
coverage matrix.

### 13. [P2] The charters silently reduce the standing validation obligations

**Locations:** translation `2026-10-18_codex-charter-translation-fuel.md:22–24,85,114–117`;
quotation `2026-10-18_codex-charter-core-quote.md:53–62`;
stack `2026-10-18_codex-charter-stack-ceiling.md:25,65`;
outcome `2026-10-18_codex-charter-outcome-protocol-s1-s2.md:47–55`;
all four are under `lean_frontend/docs/`.

Several deliverables explicitly commit on row 1 alone, and final exits
name only Tier A or selected Tier B rows. The normative
`scripts/LADDER.md:37,66–70,153–154` requires Tier A at commit/worker
boundaries and Tier B at slice/close-out boundaries; the container
`CLAUDE.md:151–160` likewise requires the prescribed battery before a
checkpoint/audit/merge claim. No scoped waiver is recorded. In addition,
the outcome charter omits B5 at S2 although its own design's `:305`
requires it.

**Suggested fix:** distinguish intermediate implementation checks from
certified worker handoff, then state who runs each required boundary
check. Preserve the standing obligations or obtain an explicit scoped
waiver. In proof-bearing slices also name kernel replay with the shipped
Lean 4.32.2 checker and axiom checks on the new headline lemmas, as the
supplied global instructions require. This review's explicit no-build
constraint is not a waiver for future implementation workers.

### 14. [P2] Importing translation's rules verbatim imports an unrelated manifest edit

**Locations:** `lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:77–81`,
`2026-10-18_codex-charter-stack-ceiling.md:80–83`, and
`2026-10-18_codex-charter-outcome-protocol-s1-s2.md:69–70` in the same directory.

Each imports translation charter §4 verbatim. That section includes
re-pinning the `translation.lem` source-content row in the fork-drift
manifest (`translation-fuel.md:114–117`). That action is unrelated to
these workers and lies outside their fences; the outcome design even
requires the manifest to remain unchanged. The imported instructions
therefore conflict rather than merely supplying common build discipline.

**Suggested fix:** reference only named common rules, or put a short
common-rule paragraph in each charter. Keep the translation manifest
instruction local to its own deliverable. Ensure dispatch makes the
referenced charter/design versions available: a fresh branch from the
current mainline contains none of the five new charters or the unmerged
outcome design.

### 15. [P2] The failure-monad spike can produce numbers without pricing the mechanism

**Location:** `doc/lean-backend/2026-10-18_codex-charter-failure-monad-design.md:24–31,55–64`.

The arbitrary one-module choice and a comprehensive-suite summary are
not yet a measurable runtime-cost experiment. The parity runner builds
both targets before executing probes and reports parity, not isolated
execution cost (`tests/comprehensive/parity/run.sh:7–17,249`). Timing the
whole runner can predominantly measure compilation; a failure-only tiny
probe can predominantly measure startup. The charter also allows the
prototype to remain uncommitted or on an unlanded scratch commit without
requiring a reconstruction recipe in the delivered design. Its stated
conclusions could then be neither representative nor reproducible.

**Suggested fix:** require a bounded effectful workload with both success
and failure paths, explain why it exercises the proposed binds, verify
the result, and time current versus prototype binaries separately from
generation/compilation on the same runtime inputs. Specify enough
repetition to expose startup noise, without turning this into a campaign.
Keep the minimal source/prototype recipe and commands with the note;
delete ephemeral output and do not depend on an orphan scratch branch.
Explain that the A5 probes' expected-failure registry makes a repaired
probe an expected-pass finding under the old runner
(`run.sh:42–47`), not a reason to preserve the defect or silently move
production baselines. If the spike cannot produce valid measurements,
label the design incomplete on cost rather than successful under the
full success condition. Retain the existing stop rule and prohibition on
landing backend/runtime implementation changes.

### 16. [P3] Correct the remaining factual citations and counters before dispatch

**Locations:** translation `2026-10-18_codex-charter-translation-fuel.md:48–55`;
quotation `2026-10-18_codex-charter-core-quote.md:27,38–39`;
stack `2026-10-18_codex-charter-stack-ceiling.md:39,88`;
all under `lean_frontend/docs/`.

The six generated Translation line numbers are correct in the inspected
tree, as are the important `translation_effect.lem:49`, `core.lem:234`,
`core_eval.lem:605`, `translation.lem:1401`, `Main.lean:667`,
`Core.lean:2490/2509/2514`, and the two failure-monad proof citations.
The incorrect signatures/equality conclusions drawn from some of these
are substantive findings above, not line drift. Other corrections:

- The complete `drive_nonmemory_steps_aux2` body is
  `frontend/model/driver.lem:1066–1095`; the cited `1062–1090` starts in the
  preceding definition and omits the final recursive call.
- `--pp-core` is a signature-only dump, not an existing full Core-text
  printer mirroring `pp_core.ml`; `Main.lean:470–491` says so. Its actual
  `ppCoreSignature` definition begins at `:509`.
- Adding `core-quote-test` inside row A1 changes the unit-executable count
  from 19 to 20. It does not change the number of fast-ladder commands
  from 19 to 20: `scripts/release.py:53–85` enumerates commands, not the
  exes inside `test_unit.sh`.
- The fuel-forms carrier list is discovered from generated filenames
  (`scripts/check_fuel_forms.sh:108–113`); there is no static carrier list
  to amend. A new proof file still needs the appropriate Lake root and
  handwritten-copy registration.

**Suggested fix:** correct these descriptions and counters, attach the
actual dispatch source/pin identities, and recheck affected references
after any sibling landing. Do not change a gate merely to manufacture a
predicted summary count.

## Additional observations

The response note's no-fork-ahead disposition of A/C/D/E is respected by
the intended scopes. None of these charters should be widened into a
null-arithmetic UB repair, UB088 policy change, or implementation of
shared-model TODOs. The failure-monad charter correctly calls out the
earlier correspondence concern and leaves operator boundary decisions
open. The explicit repository fences, no-push rules, bounded proof work,
and stop-on-unexpected-baseline-movement rules are useful and should be
retained when repairing the acceptance conditions.

No identifiable verbatim operator quotation was found in the five new
charters. Their historical [USER] attributions were checked against
available project records where provided, not authenticated against an
unavailable conversation transcript. One pre-existing issue encountered
in the supporting material: the older pinned Lem revision `2d3a492`
still contains direct operator quotations in `lean-lib/LemLib.lean:94–97`
and `:269`, among other comments; current Lem mainline has paraphrased
them. No quotation is reproduced here, and no pin change, removal or
history rewrite was performed. The September charter precedents also
contain obsolete instructions to preserve verbatim rulings; current
record-integrity rules take precedence over that historical format.

This report is a static charter review. It claims neither that a proposed
repair has been implemented nor that any current engine run passed or
failed anew.

## Second pass — 2026-10-18, rev 2 and the two consumer decisions

### Verdicts and scope

| Charter | Second-pass verdict | Disposition |
|---|---|---|
| Translation fuel | **still open** | Original finding 13 remains. New finding S6 makes the acceptance table contradict the permitted measured result. |
| Core quotation | **still open** | Original findings 3 and 13 remain. The selected boundary instrument is legitimate, but its strengthened comparison still does not justify the lookup claim (S1). New factual correction S7. |
| Stack ceiling | **still open** | Original findings 5 and 13 remain. The default-only mechanism cannot deliver the newly mandatory million-element completion controls (S2); acceptance coverage and regeneration also need repair (S4, S5). |
| Outcome protocol S1–S2 | **still open** | Findings 6–9 are closed in the charter. Finding 13 remains, and S5 is new. The separate design acceptance and fresh-review gate remains binding. |
| Failure-monad design | **closed** | Finding 15 is fixed by a meaningful runtime experiment and a reconstructible prototype. No new finding; ready as a bounded design pass. |

These are independent judgements [AGENT 2026-10-18]. Of the original
16 findings, **13 are closed and 3 remain open: 3, 5 and 13**. Closed means
the charter now requires an adequate repair, not that the implementation
or its tests have passed. New findings below are identified separately.

Reviewed cerberus charters at
`ee6cc316dcf7024f4f733adbcc76b092e5ac662c`, the Lem charter at
`d6a8f0c7fcf7c42d3fcbd497069a9c246c4c6188`, and the outcome design including
errata at `5d31318daa7ee2f58ee545c8a6765c1f25b5bdbb`. The prior report is
`3a1555f829483ed961ae27e814ea587735c8a197`. Source mainline remains
`32ab44e4a76dc68d11baffc77f7aca95b4e71efc`; Lem implementation claims below
use the functional pin `2d3a492758cb23dc4e417f2961983d25b36ce130`.

The standing instructions, original report and response note remain the
basis of this review. Rechecked the revised requirements against the
relevant source, historical stack measurements and consumer witness
records. Generated-source references retain the first pass's limitation:
inspection of the existing tree, checked against tracked source, without
regeneration or a freshness claim. No build, lane, Lean invocation,
driver run or new timing experiment was performed. The only changes are
this appended section and its requested local commit. The first report
is preserved unchanged.

The consumer's two decisions are treated as settled scope, paraphrased
here: quotation may remain a declared-boundary instrument; a reduced
CLI fuel default is an acceptable operational remedy, with the
structural repair left as a proposal. Neither decision authorizes a
false lookup-equivalence claim, weaker standing gates, or a new
requirement that the million-element programs finish. No additional
operator quotation was identified in the five revised charters.

### Disposition of every original finding

In this table, T, Q, S and O denote respectively the translation-fuel,
core-quote, stack-ceiling and outcome-protocol-s1-s2 files named in the
first section, under `lean_frontend/docs/2026-10-18_codex-charter-*.md`.
M denotes `doc/lean-backend/2026-10-18_codex-charter-failure-monad-design.md`
in lem-lean. Line numbers are rev 2.

| Original finding | Status | Evidence and remaining action |
|---|---|---|
| 1. Deferred error node | **closed** | T:33–39,47–49,85–87 require recording exhaustion in the translation state, a boundary failure, and a dead-code plant that fails without recording. `translation_effect.lem:250–264` supplies the existing mechanism. This is a runtime boundary guarantee, not a new typed-failure theorem. |
| 2. Impossible all-ABSORBING fallback | **closed** | T:15–38 gives the actual return shapes, requires measured pure/state workers, and classifies error-recording `elabM` workers as ambient outside the execution closure. T:99–104 prevents an unproved pure worker being reported done. Reconcile the optional measured pair with item 2 as S6 requests. |
| 3. Quotation relation | **still open** | Q:15–46 settles relation A and the boundary entry, but Q:29–33,43 asserts lookup/extensional agreement from insufficient checks. S1 gives the remaining counterexamples and a repair within A. |
| 4. Wrong recursion layer | **closed** | S:29–32,42–45,61–62,76–78 explicitly distinguishes action production from outer traversal. The selected default change reaches the existing ambient budget; the structural proposal keeps the repository boundary. |
| 5. Finite versus diverging acceptance | **still open** | S:21–26 correctly separates them, but S:36–38 now requires both million-element programs to finish at a larger explicit fuel. S2 explains why this is incompatible with the selected mechanism on the recorded premise. |
| 6. Premature classification promise | **closed in the charter** | O:18–29 supplies a per-family transition table, and O:41,64–65 requires the consumer demonstration and disclosure. Design §8:423–425 requires the original overclaim to be corrected before acceptance. |
| 7. Bare 137 attributed to OOM | **closed in the charter** | O:32–36 explicitly requires positive cap evidence, leaves unexplained 137 red, and adds native-137 and signal controls. Design §8:413–418 records the same correction. |
| 8. Data envelope and admission contradictions | **closed in the charter** | O:33–36 makes program-data envelopes ordinary verdict data and predicates negative plants on the admission matrix. Design §8:419–422 requires the contradictory rule and blanket plant wording to be repaired. |
| 9. Register mutation prohibited | **closed** | O:38–40,61–62 expressly permits affected message keys and seals, with a mapping and unchanged reach/position/invariant information. |
| 10. False measured-wrapper equation | **closed** | T:51–55 requires the equation appropriate to each final form and limits zero-arm claims to what is established. |
| 11. Resource wire contract and baseline scope | **closed** | S:49–50 chooses the existing fuel channel, S:72–74 inventories affected rows, and S:39–40 separates new measurements from history. The conditional new-resource file-fence tail at S:99–100 is now dead text and should be deleted for consistency. |
| 12. Missing multi-TU round trip/extraction point | **closed** | Q:9–10,35–37,50–58 fixes the post-conversion object, adds a linked cross-TU case and the library quotation, and excludes derived run-state maps. |
| 13. Reduced validation | **still open** | T:113–116, Q:111–113, S:95–97 and O:78–80 retain row-1-only commits and partial close-out batteries; T additionally demotes replay to a speedbump. S3 addresses all four. The specifically missing outcome B5 is fixed at O:40–41,62. |
| 14. Imported translation manifest instruction | **closed** | Q:113, S:96–97 and O:79–80 explicitly exempt it. The cerberus dispatch paragraphs require the charter, and O:8–9 also the accepted design, on the dispatch base. Exempting all regeneration in S/O is a new defect, S5. |
| 15. Vacuous/nonreproducible cost experiment | **closed** | M:25–31,63–68 requires effectful success and failure workloads, runtime-only repeated timings, source and rebuild commands, an explicit incomplete-cost result on failure, and honest handling of expected-failure repairs. |
| 16. Incorrect references and counters | **closed for the listed defects** | T:69–75 fixes discovery of the proof carrier; Q:12–13,55 fixes the printer description and executable/command counts; S:61,68,105 fixes the driver body and mode flags. Q:80 introduces a separate inaccurate description, S7. |

The outcome design's body has deliberately not yet been reconciled with
its errata. O:3–6 requires that reconciliation, a fresh full review by a
new reviewer, and operator acceptance before dispatch. Thus findings
6–8 are closed as charter requirements, not an approval of the design at
`5d31318da`. This second pass by the original reviewer does not substitute
for that fresh full review.

### S1. [P1, original 3 still open] Comparator names and binding spines are not sufficient to establish lookup agreement

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:22–33,40–44,57–60,101–104`.

Declaring the instrument as a boundary resolves the earlier choice of
relation. It does not make the new assertion of extensional map
equality true. There are two independent missing conditions.

First, the name of a polymorphic constant is not the comparator
function. At the pin, `LemLib/Map.lean:49–63` makes `mapKeyCompare` a
projection from a `MapKeyType` instance; `:101–105` passes that instance
through `fromList`. `LemLib/Basic_classes.lean:143–146` likewise gives
`ordCompare` implicit equality and ordering instances. Distinct instance
arguments can produce different lookup behaviour while the printed head
name is unchanged. Even singleton maps can have identical binding
spines but disagree on a query identified with the stored key by only
one comparator. The required different-name negative control does not
catch this.

This is relevant to the actual inventory: `generated/Symbol.lean:237–250`
defines structural instances, while `:277–286,290–343,383–385` supplies
symbol comparisons that ignore descriptions. The table's parenthetical
identification of `mapKeyCompare` with `defaultCompare` cannot be assumed
merely from the name. The worker's existing verification requirement is
useful, but must identify the fully instantiated function.

Second, the captured comparator and the tree both determine lookup.
Pinned `LemLib.lean:1216–1220` uses the captured comparator with
`Pmap.find?`; `:994–1000` follows tree branches. Equality at `:1241–1242`
compares only the inorder list produced by `:1176–1181`. The `Pmap`
constructor at `:937–940` imposes no search-order invariant.

A source-level counterexample, not an executed test: with ordinary
ascending natural-number comparison, take one tree with root `(1,a)`
and left child `(2,b)`, and a second with root `(2,b)` and right child
`(1,a)`. Both inorder lists are `[(2,b),(1,a)]`; the same named comparator
and equal scalar values pass the specified pair of comparisons. Lookup
of 1 returns `a` in the first and misses in the second. These are not
ordered search trees. That is the missing hypothesis, not a claim that
the current frontend has produced these trees.

Rebuilding only ordered trees under the same lawful comparator can make
spine equality useful. The charter neither requires establishing that
condition for the source and literal nor requires preserving the source
tree. Its permission to canonicalize maps leaves this choice open.
`fmapUnionBy` at the pin (`:1269–1274`) also ignores its explicit
comparator argument and chooses a captured one; seeing a comparator
name at a linking call is not evidence about the result's comparator or
both inputs' ordering.

**Suggested fix:** retain A, but define an adequate representation
contract. Name monomorphic comparator constants with their types and
all instance arguments fixed, or compare those full elaborated terms.
Trace the captured comparator from construction, including empty/nonempty
union cases and libc loading: `Main.lean:246,993,1025` uses
`libcSymMapCmp`, and `Core_linking.lean:465–485` preserves a selected
input comparator. The table must distinguish these construction paths.
Do not compare a printer-supplied label against another copy of that label.

For trees, either require and check preservation of the actual `Pmap`
representation, or require orderedness/uniqueness and comparator laws
that justify reconstruction on the admitted inputs. Refuse unsupported
provenance or a failed invariant. Include a same-name/different-instance
control and a same-spine/different-search-tree control. The existing
`BEq` and name checks can remain, but cannot be advertised as sufficient
by themselves. This need not become a general printer-correctness proof;
the boundary declaration and the consumer's separately owned lemma stay.

### S2. [P1, original 5 still open] The new positive controls require a structural repair from a default-only change

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:19,24–26,33–41,79–80`.

Success item 2 makes completion of the two million-element finite stress
programs mandatory at some explicit fuel. The known premise is that
these very programs hit the native stack before exhausting a sufficiently
large fuel: `TODO.md:530–548` records the million-element failures at
`10^8`, and completion of the corresponding `100000` cases. The present
charter chooses only a different CLI default. Supplying the old explicit
fuel bypasses that change, and increasing it does not shorten the
recursive continuation chain. Lowering it stops the run before completion.

On that premise, this acceptance item cannot be met by D3. The worker
must either stop unnecessarily, exceed the chosen repository/mechanism
scope, or weaken the result. The new consumer decision permits default
exhaustion and retains explicit fuel; it does not establish that arbitrary
finite runs can be made stack-safe just by supplying more fuel. The
unqualified preservation sentence at line 19 also conflicts with the
accepted possibility of lower-default exhaustion for previously
completing programs.

**Suggested fix:** use the known-completing smaller finite programs as
positive controls, comparing the same explicit fuel and oracle
observation before and after. Keep the million-element cases as required
default-budget resource witnesses, allowing complete matching observations
if fresh evidence supports them. Record that explicit high budgets still
expose the structural limit until the separate proposal is implemented.
Express preservation at the same explicit budget, and inventory any
default-budget row movement. Do not require million-element completion
from this slice.

### S3. [P2, original 13 still open] Renaming checks intermediate and boundary has not restored the required gates

**Locations:**
`lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:113–116`;
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:93–97,111–113`;
`lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:95–97`;
`lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:58–62,78–80`.

All four still permit commits on row 1 alone and prescribe only selected
Tier B rows, or none, at final handoff. The orchestrator is assigned only
an independent Tier A rerun. `scripts/LADDER.md:37,66–70,153–154`,
`lean_frontend/VALIDATION.md:1231–1249` and container `CLAUDE.md:151–160`
retain the wider commit, boundary and close-out obligations. There is no
recorded waiver. Relabeling the same reduced checks does not close the
finding. The outcome charter has correctly restored its particular B5.

Translation additionally calls kernel replay a nonblocking speedbump.
That contradicts the supplied Lean trust instructions, which designate
kernel replay and axiom checking as trust-surface gates. This project's
pinned Lean 4.32.2 has the replay checker; an unspecified conditional
report is not the requested requirement.

**Suggested fix:** state the applicable Tier A commit and full boundary
obligations, with explicit worker/orchestrator ownership, or obtain and
record a scoped waiver before dispatch. Name the shipped kernel replay
and axiom checks as gates for proof-bearing deliverables. Extra checks
can remain focused; do not present a selected subset as the complete
standing certification.

### S4. [P2, new] The 60-second criterion does not cover the programs whose reclassification is promised

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:5–11,21–41,46–47,72–80`.

The decision and consumer note promise results for five consumer failures,
but the characterisation identifies four programs and the timed acceptance
at lines 33–35 applies only to the two diverging witnesses. The finite
stress rows may consequently still run past 60 seconds at the new
default while D3's named plant passes. The fifth consumer case is not
identified. A generic replacement for the diverging callee can also
erase its relevant nondeterministic behaviour.

The consumer's actual W5 diverging callee is specified in
`cerberus-caesium/scripts/check-w4-m0-witnesses.py:40–43`. Its recorded
low-fuel runs contain both UB043 and fuel leaves
(`docs/2026-10-17_W4-M0-witnesses.md:54–63`). A whole-run FUEL classification
for incomplete exploration must not discard or relabel the UB leaf.
The expected leaf counts embedded at script line 43 are themselves
superseded by that record, so copying the old expectation would be wrong.

The historical numbers do **not** prove that the lower-default decision
is infeasible. `docs/2026-08-31_stack-ceiling-design.md:81–94` has small-loop
completion around 4 seconds and deep-recursion completion around
24–30 seconds near its `10^6` exhaustion edge. Its derived rates at
`:194` suggest roughly 4–33 seconds of stepping for that budget. Those
are useful starting points, not fresh timings for the specified programs,
the whole frontend, both modes, or the current implementation.

Nor do the records justify keeping all previously completing programs
at the new default: the old approximately 55–61 fuel/loop-iteration
estimate (`:109–112`) puts a 100000-iteration loop around 5.5–6.1 million
fuel, while the old recursion rate at that budget suggests minutes.
This is a derived cross-shape warning, not an impossibility proof or a
measurement of W5, whose callee loops rather than recurses in C.

**Suggested fix:** name every consumer failure whose reclassification
will be claimed; obtain the missing identities before dispatch or narrow
the claim explicitly. Require a table for each exact input in each mode
at the selected default: full invocation, wall time including the
pipeline, process status, outcome channel and all emitted leaves. A
timeout, signal, panic-only FUEL label or missing result must fail the
new no-signal record requirement. Preserve the W5 mixed outcomes.

Use a bounded, stated fuel search and empirically justified safety margin;
claim the largest validated candidate in that search, not a global maximum
from a few samples. Keep a stop if the required table has no feasible
default. With S2's finite controls fixed, the old records support trying
the choice, not rejecting it in advance or declaring it already feasible.

### S5. [P2, new] The regeneration exemption drops the mandatory hand-written-copy step

**Locations:**
`lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:95–100`;
`lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:78–81`.

Both exempt the translation charter's regeneration instruction because
they change no `.lem` files. That instruction also includes the separate
hand-written Lean copy step (T:111–112). These workers edit `Main.lean`
and/or seams, whose compiled copies live in `generated/`.

`lean_frontend/CLAUDE.md:248–269` requires synchronizing those copies;
`Makefile:315–329,365–367` and
`lean_frontend/handwritten_copy.manifest:34,39,43,58` show this includes
Main, CerbFS, CerbMem and CerbND. Omitting the copy yields a stale build
or a red sync gate. No `.lem` change is needed for this requirement to
apply.

**Suggested fix:** exempt only `.lem` regeneration/oracle rebuilding
and translation-specific fork-drift re-pinning. Retain the prescribed
hand-written synchronization before every affected Lean build, including
manifest registration for the new outcome seam. Do not hand-edit the
generated copies as a repair.

### S6. [P3, new] Translation's mandatory final forms reject its expressly permitted measured pair

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:23–24,44–46,85–87,96–97`.

The table, D2 and flex section permit a joint measure for the two
`elabM` workers. Success item 2 nevertheless mandates AMBIENT for those
same workers. A successful joint proof therefore fails the literal
acceptance condition. The error-recording explanation at line 33 has
the same unconditional wording.

**Suggested fix:** require each pair member to be MEASURED when its
obligation closes, otherwise AMBIENT with the specified boundary failure
and execution-closure check. Require the reported form table and pins to
match that final choice. No gate change is needed.

### S7. [P3, new] The quotation fact table describes linked Core as pre-link

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:80`.

At the cited `Main.lean:1203–1212`, `coreFile` is already the successful
result of `link coreFiles` (`:1171,1192`). It is pre-conversion, not
pre-link. The goal and multi-TU acceptance elsewhere now select the
correct object, so this is a contradictory fact-table description rather
than a missing extraction decision.

**Suggested fix:** describe it as the linked `file Unit`, immediately
before `convert_file`, and keep the existing post-conversion quotation
point.

## Third pass — 2026-10-18, rev 3 and the corrected representation contract

### Verdicts and review basis

| Charter | Third-pass verdict | Reason |
|---|---|---|
| Translation fuel | **new finding** | S6's final-form table is fixed, but the required end-to-end exhaustion plant still excludes a successful measured implementation (R7). The commit/close-out checks are repaired; replay policy awaits its recorded dispatch disposition. |
| Core quotation | **still open** | S1/original 3 is substantially repaired, but the contract loses the `Fmap.empty` constructor and omits whole-object checks; its comparator control also needs an absent alias query (R1, R2, R4). R3 identifies an additional value-equality problem under the new representation claim. |
| Stack ceiling | **still open** | S2/original 5 is closed. S4's witness identities and mixed outcomes are addressed, but the numerical deadline still excludes finite default-budget witnesses in the selection and stop predicates (R5). |
| Outcome protocol S1–S2 | **still open** | S5 is closed and the final battery is repaired. S3/original 13 retains a slice-boundary gap at S1 (R6). Design acceptance and fresh full review remain separate prerequisites. |
| Failure-monad design | **closed** | Unchanged at the reviewed revision; the second-pass closure stands. |

Judgements [AGENT 2026-10-18]. Reviewed the four cerberus charters at
`3bc11b2e30f3a91ef1ebfda4d34dc1011b2d2bb1`; the Lem charter remains at
`d6a8f0c7fcf7c42d3fcbd497069a9c246c4c6188`. The report before this append
is `cd994f608d84296641e02bf1105ed8ad8997688b`. Source mainline remains
`32ab44e4a76dc68d11baffc77f7aca95b4e71efc`, with functional Lem pin
`2d3a492758cb23dc4e417f2961983d25b36ce130`.

Read the binding project instructions, revised charters, previous findings
and relevant source. The inspection included the pinned map library,
construction/linking/conversion paths, existing stack records, consumer
W5 record and the local Lean 4.32.2 source for floating-point equality.
No builds, lanes, Lean executions, driver runs, consumer proof replays or
new runtime measurements were performed. Generated-source citations refer
to the existing primary generated tree, with the same freshness limitation
as the earlier passes. The sole mutations are this requested append and
its local commit; both earlier sections remain unchanged.

### Disposition of S1–S7 and originals 3, 5, 13

T, Q, S and O below denote the translation-fuel, core-quote, stack-ceiling
and outcome-protocol-s1-s2 charters, respectively, under
`lean_frontend/docs/2026-10-18_codex-charter-*.md`. All line numbers in
this section refer to rev 3 unless a different source is named.

| Finding | Disposition | Evidence and remaining action |
|---|---|---|
| S1 / original 3 | **still open** | Q:23–41,93–97,109–113 now fixes tree shape/heights, fully instantiated comparator terms, provenance paths and refusal on unknown provenance. R1, R2 and R4 identify remaining gaps; R3 addresses the stronger representation claim's leaf comparison. |
| S2 / original 5 | **closed** | S:19–20,31–36,49–50 now distinguishes completed 100000-element controls at the same explicit budget from million-element default-budget resource witnesses. It no longer demands completion of the overflowing programs at a larger fuel. |
| S3 / original 13 | **partly closed; still open at S1's boundary** | T:113–118, Q:118–120, S:112–115 and O:80–82 require Tier A per commit and full Tier B at close-out, independently rerun before landing. Those repairs are real. O:60 still closes the named S1 slice on Tier A alone (R6). Replay status is a proposed operator decision, discussed below, not an approved downgrade. |
| S4 | **still open in part** | S:23–30 identifies W5 and preserves all its emitted leaves; missing consumer identities are now an explicit dispatch dependency with honest narrowing of the claim. S:47–54 requires the full per-mode table and rejects signals/panic-only classifications. The 60-second selection/stop predicates still name only diverging witnesses (R5). |
| S5 | **closed** | S:111–115 and O:78–82 retain hand-written-copy synchronization and, for the outcome seam, manifest registration. Only `.lem` regeneration, oracle rebuilding and translation-specific manifest work are exempted. |
| S6 | **closed as reported** | T:33–34,44–47 makes the final form conditional on whether the joint obligation closes. The record and pins must match. R7 is a separate interaction with the still-unconditional runtime plant. |
| S7 | **closed** | Q:84 correctly identifies `coreFile` as linked and places quotation after conversion. |

The positive-control repair is adequate when read with its stated goal:
the 100000-element programs must complete with their oracle observations
at the same explicit budget before and after. Two matching exhaustion
results would not satisfy S:19 or the completing-control class at
S:31–32. Record those completed observations and the actual budget; no
new requirement for the million-element runs to complete is needed.

The corrected comparator account is supported by the inspected sources.
`generated/Symbol.lean:290–343,383–385` supplies the active description-
insensitive instances, distinct from the derived instances at `:237–250`.
Pinned `lean-lib/LemLib/Map.lean:49–63,101–105` threads the `MapKeyType`
instance through `fromList`. The Nat-keyed maps are populated with
`defaultCompare` in `generated/Cabs_to_ail_effect.lean:2136–2137` and
`generated/Translation_effect.lean:301–303`. The libc paths at
`Main.lean:246,993,1025` are correctly named. The union account needs the
empty-left exception in R1.

Preserving the original tree and cached heights is a justified choice
for later map operations: pinned `LemLib.lean:1114–1135` branches on
subtree heights, and `:1137–1145` documents traversal-dependent selection
of the stored key on a comparator-equal collision. This is stronger than
checking immediate lookups alone. These source observations support the
correction's rationale; this review did not independently replay the
consumer's claimed kernel probes.

A worker can establish provenance for these restricted pipeline outputs
by inspecting the construction paths and fixing their elaborated
comparator terms. It need not discover the name of an arbitrary runtime
closure or prove function equality by testing. Q:111–112 now provides the
right stop if that construction argument cannot be made. The lookup sweep
is supplementary evidence, not a replacement for provenance.

### Replay policy: legitimate proposal, existing rule still binding

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:115–118`,
inherited by the other cerberus charters' common rules.

It is legitimate to raise a standing-rule change to the operator, and
rev 3 no longer silently declares replay nonblocking. Requiring the
checker to run and its output to be recorded is also an improvement.
However, the supplied standing instructions already make kernel replay
a trust gate. A pending proposal does not suspend that rule, and this
audit request does not approve the proposed change.

At dispatch, the orchestrator must record an actual operator ruling if
the rule is to change; otherwise replay remains a gate. A failed replay
cannot be accepted merely because its output was quoted. I recommend
stating that default explicitly beside T:117–118 and naming the modules
and checker exit status in the eventual validation record. This is the
appropriate treatment of a pending proposal, not a demand that the worker
settle the policy. It does not by itself reopen the repaired per-commit
or final Tier B requirements. The remaining validation defect is R6.

### R1. [P1, S1/original 3 still open] Quoting every map as `Fmap.mk` loses a real constructor and changes union provenance

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:23–25,34–41,55–56,86`.

The required representation is not the representation of every `Fmap`.
At the pin, `LemLib.lean:1192–1194` has two constructors: `.empty`, which
has no comparator, and `.mk cmp tree`. In particular, `.empty` and
`.mk cmp .Empty` are different states. `Fmap.rep` at `:1200–1202` erases
that distinction, so a check limited to `Pmap` trees misses it; the
lookup sweep is empty in both cases.

This is an ordinary required input, not just a malformed-map plant:
`Main.lean:1021,1028–1029` initializes three fields of the libc file with
`fmapEmpty`, and `convert_file` preserves those fields
(`generated/Core_run_aux.lean:944,951–952`). The charter's universal
`.mk` instruction either changes those values or forces refusal of a
required library round trip.

The distinction also matters to the consumer's later-union concern.
`fmapUnionBy` at pinned `LemLib.lean:1271–1274` uses the left comparator
only when the left operand is `.mk`. With `.empty` on the left it takes
the right operand's captured comparator. Changing `.empty` to `.mk c
.Empty` fixes the result to `c` instead. Two empty binding spines and
identical underlying empty trees therefore do not justify this change.
The same distinction controls the comparator captured by insertion
(`:1211–1213`). Q:34–35's unconditional left-comparator statement is false.

**Suggested fix:** quote and compare the outer `Fmap` constructor as
well as its tree. Emit `.empty` exactly when the original is `.empty`,
and require no comparator term in that case. Preserve `.mk cmp .Empty`
as such when it actually occurs. Document both union branches, using
`.empty` rather than an empty binding list as the discriminator. Add an
empty-versus-captured-empty negative control and correct the Fmap
constructor citation to `LemLib.lean:1192–1194` (`:937–940` is `Pmap`).

### R2. [P1, S1/original 3 still open] The replacement check no longer requires comparison of the complete Core file

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:37–41,57–65,107–110`.

All three enumerated comparisons are map-specific. They do not compare
the non-map fields of `generic_file`, notably `main`,
`calling_convention0` and `globs` (`generated/Core.lean:2491–2501`). A
literal with unchanged maps but a dropped global initializer or changed
entry symbol passes those three checks. Requiring one altered scalar
negative control does not close this: that scalar can be inside a map
value that the existing check does compare.

The same completeness requirement applies recursively to structures
inside values. For example `core_run_annotation` contains `Pset` fields
(`generated/Core_run_aux.lean:53–57`), and the pinned Pset `BEq` compares
only element spines (`LemLib.lean:928–929`). The permission to quote sets
while preserving their representation needs a corresponding comparison;
generic leaf `BEq` is not that check for a represented container.

**Suggested fix:** make the first stage a comparison of the entire
`file core_run_annotation`, covering every constructor and field. Its
map/set cases must compare their representations recursively, including
R1's outer map tag and all cached heights. Retaining whole-file generated
`BEq` as an additional check is fine, but it cannot substitute for those
container checks. Place the scalar negative control outside all maps
(for example, change `main`) and add a changed global initializer control.
Derive the field inventory from the already-required D0 type inventory.

### R3. [P2, new] Generated value `BEq` can accept a changed floating-point representation

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:17–25,37–40,67–69`.

Even after the container checks are repaired, the stated key/value
comparison is not generally representation equality. `CerbMem.lean:75`
defines `FloatingValue` as `Float`; `generated/Core.lean:486–489` compares
`OVfloating` leaves with Float `BEq`. The shipped Lean 4.32.2 source
`Init/Data/Float.lean:133–144` specifies IEEE equality: positive and
negative zero compare equal, while operations can distinguish them.

Thus changing a supported floating leaf from positive to negative zero
inside a map value can preserve the tree, comparator term and every
BEq-based lookup-result comparison. The change is observable here:
`CerbFloat.lean:325–330,382–388` reads the sign bit when printing zero,
and the project has separate signed-zero examples at
`test/Unit/PPTest.lean:106–107`. Floating values can enter translated Core
through `generated/Translation.lean:236–238`.

**Suggested fix:** specify representation-sensitive leaf comparison for
supported floating values, with signed-zero controls, or explicitly
refuse that leaf constructor within the charter's existing refusal
policy when the required corpus permits it. Audit the admitted leaf
types instead of assuming every generated `BEq` is faithful. If NaNs
are supported, define their handling separately: this project's
`CerbFloat.lean:348–354` records that this toolchain's `toBits`
canonicalizes NaNs, so a blanket raw-bit-preservation claim would be
unjustified. No new opaque/native seam is authorized by this suggestion.

### R4. [P2, S1 still open] The comparator negative control asks the binding-key sweep to see a query it never makes

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:39–41,63–65`.

The specified sweep queries only keys stored in each map. That does not
distinguish structural symbol comparison from the active comparison on
the proposed description-only alias pair. For a singleton storing symbol
`s`, both comparators find `s`. They differ when queried with `s'`, which
has the same digest and number but another description. `s'` is absent
from the stored keys: under the active comparator it is equal to `s`,
so inserting it replaces the binding rather than creating a second key
(`LemLib.lean:985–991`). The term check can reject the changed comparator,
but the mandated sweep does not witness the claimed behaviour difference.

Also, `defaultCompare` and the active `ordCompare` are different head
names. Using those two naked constants does not exercise the same-head,
different-instance defect the control is meant to catch.

**Suggested fix:** use two fully instantiated applications of the same
head (for example `mapKeyCompare` with two explicit instance values),
and add the absent alias `s'` to the control's query list. Require the
term comparison to reject the instance substitution and the behavioural
control to expose its lookup difference. Keep stored-key sweeps as useful
positive checks without claiming they identify a captured comparator.

### R5. [P2, S4 still open] The numerical deadline still governs only the diverging subset

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-stack-ceiling.md:43–54,87–89,104–105`.

The new table covers every named input and mode, which fixes the missing
observations. The candidate-selection predicate at lines 44–45 and the
no-feasible-default stop at lines 53–54 still quantify the 60-second
bound only over diverging witnesses. The million-element finite programs
must produce FUEL, but are not explicitly required to do so within that
bound. A default yielding a normal fuel record at 80 seconds for one of
those programs satisfies those local predicates if its harness timeout
is longer. Recording that time does not satisfy the consumer's limit.

The identity handling is otherwise a useful repair: obtain the remaining
consumer inputs at dispatch or state the narrower claim, and preserve
W5's mode-appropriate emitted leaves. The historical mixed-leaf result
must not be converted into an expectation of three leaves in `--first`:
`CerbND.lean:222–236` follows one branch in that mode.

**Suggested fix:** use one explicit acceptance set for fuel selection,
the per-mode table and the stop rule: all named default-budget resource
witnesses, including the overflowing finite programs, must produce an
admitted record within 60 seconds. Treat the smaller finite programs'
same-explicit-budget completion checks separately. Freeze the exact
input set before dispatch, deduplicate overlapping consumer/probe cases,
and replace D0 and the file fence's stale references to four programs
with that inventory. No fresh timing claim follows from this review.

### R6. [P2, S3/original 13 still open] Full close-out checks do not cover the earlier named S1 slice exit

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-outcome-protocol-s1-s2.md:60–62,80–81`;
the other charters' common boundary wording has the same limitation if
used for an intermediate certified checkpoint.

The broad earlier defect is mostly fixed: commits now require Tier A,
final close-out names the full release runner, and the orchestrator has
an independent Tier B obligation before landing. However, this charter
explicitly contains S1 and S2 as slices and ends S1 at D3 with Tier A
and its record. Tier B is assigned only to the later S2 close-out.

`scripts/LADDER.md:66–70` requires Tier B at slice boundaries as well
as close-out/pre-merge; container `CLAUDE.md:151–158` requires the full
battery before checkpoint/audit claims and independent boundary checks.
An S1 slice-exit claim after D3's stated checks therefore still exceeds
the validation performed. This is separate from the pending replay
policy; approving a replay-policy change would not waive the ladder.

**Suggested fix:** assign full Tier B to the S1 slice exit and the
corresponding independent boundary verification, and state that any
earlier certified checkpoint/audit follows the standing full-battery
rule. If a reduced S1 exit is intended, obtain a specific waiver rather
than implying one through the final close-out wording. Routine work
between those claim points need not acquire additional checks.

### R7. [P2, new] The measured translation option still has an ambient-exhaustion acceptance test

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-translation-fuel.md:33–38,44–50,85–87`.

The final-form table now correctly admits a measured pair, closing S6.
But success item 3 and D2 still unconditionally require a low-fuel
driver run to exhaust one of those workers in dead code, fail at the
translation boundary, and cease failing when the recorded error is
removed. A measured wrapper supplies its data-derived measure instead
of the CLI fuel; lowering `--fuel` does not force its own exhaustion
arm (`CerbND.lean:386–394` explains precisely this distinction).

If the joint measure makes those arms unreachable on the admitted
production inputs, a successful implementation cannot supply that
end-to-end plant. Exhausting some other ambient frontend function would
not test the repaired recorded-error path. It would allow the wrong
witness to stand in for the promised one.

**Suggested fix:** branch the test obligation on the final form. For
ambient workers, keep the actual low-fuel dead-code driver witness. For
measured workers, require the measure/sufficiency obligations and an
ordinary production control, and test recorded-error propagation with
a deliberately under-fuelled raw-worker call through
`runStateM_errors` in a clearly identified unit probe. Where unreachability
is claimed, prove or state its precise established conditions. Do not
require the normal measured wrapper to exhaust or substitute an unrelated
driver panic. The native failure boundary remains distinct from a typed
error theorem, as in the prior passes.

## Fourth pass — 2026-10-18, Core quotation rev 4

### Verdict and scope

**Core quotation: still open, with narrow edits.** The substantial
representation repairs are present. R2 and R4 are closed; R1's operative
contract is repaired but its fact table retains the old error (F3).
R3's signed-zero comparison defect is repaired. Two new interactions in
the permitted floating-point choices need resolution (F1–F2). This is
not a request to replace the chosen instrument with a correctness proof.

Judgement [AGENT 2026-10-18]. Reviewed
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md` at
`e44c5a74fb3b04851cc249a7d017a72bfd08eba4`. Below, **Q** denotes that
file and its rev 4 line numbers. The report before this append is
`d59f58337fc70e8d6554713bb272b29ef2ba9bc7`; source mainline remains
`32ab44e4a76dc68d11baffc77f7aca95b4e71efc` and the functional Lem pin
remains `2d3a492758cb23dc4e417f2961983d25b36ce130`.

Read the binding instructions, rev 4, the prior findings and the relevant
construction, conversion, comparison and library-loading sources. The
other charters were not re-reviewed; translation §4 was read only because
Q inherits its rules. No disposition of R5–R7 follows from this pass.
Kernel replay's policy question is **closed**: container
`CLAUDE.md:206–211` now names it a trust gate, consistent with the inherited
rule. No rule change is proposed here.

Static inspection only: no builds, lanes, Lean executions or runtime
probes. I also read the installed 4.32.2 Float declarations and disassembled
the shipped `lean_float_to_bits` routine, without executing it. Generated
citations refer to the existing primary generated tree, without a fresh
regeneration claim. The only mutations are this requested report append
and its local commit; the three earlier sections are preserved.

### Disposition of R1–R4

| Finding | Disposition | Evidence / action |
|---|---|---|
| R1: outer map constructor and union provenance | **Operative repair closed; text still open** | Q:23–29,38–41,47–49,76–77 preserve and compare `.empty` versus `.mk`, including `.mk cmp .Empty`, and require the bidirectional constructor control. The stale summary/citation in Q:102 and the ambiguous abbreviation in Q:40 still need F3's edit. |
| R2: entire file and recursive containers | **Closed** | Q:44–54 requires every constructor and field recursively, expressly includes `Pset`, and rejects spine equality as the check. Q:74–75 puts controls in `main` and a global initializer. |
| R3: Float equality loses representation | **Signed-zero defect closed; new findings F1–F2** | Q:50–54 requires representation-sensitive leaves and distinguishes NaNs; Q:77 adds the sign-flip control. The floating refusal option and NaN branch need the qualifications below. |
| R4: comparator-instance control needs an absent alias query | **Closed** | Q:78–80 uses the same head with different explicit instances and queries an alias absent from the stored keys. Q:55 explicitly limits stored-key sweeps to supplementary evidence. |

The whole-file requirement is sufficiently specific. A worker using the
generated `BEq` with a few special cases would violate Q:44–50, even if
the listed negative controls happened to pass. The D0 inventory must be
followed through the recursive types; in particular a `ctype` is not an
atomic structural leaf whose existing `BEq` can be trusted:
`CerbCtypeInstances.lean:18–20,29–35` deliberately ignores annotations.
The new wording already requires inspecting those fields. I do not ask
for another exhaustive table or another gate to enforce that instruction.

### F1. [P2, new] The blanket floating-leaf refusal option cannot satisfy the mandatory libc round trip

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:57–59,68–85,123–124`.

The flex section lets the worker choose to refuse floating leaves using
a corpus count. But the separately required libc file already contains
them, regardless of whether the small program fixtures do. For example,
`tests/libc/libc.core:53379` contains a floating zero and `:53897` an
infinity. The existing register `scripts/libc_float_literals.txt:6–29`
lists 24 numeric float occurrences, in addition to the four infinity
sites documented in `CoreParser.lean:1506–1525`.

These become `OVfloating` values in the Lean input, not runtime-only
results: `CoreParser.lean:1058,1524,1573` constructs them; renaming
preserves them at `:2816`; `Core_run_aux.lean:749` preserves a `PEval`
during conversion. `Main.lean:997–1025` carries the parsed library bodies
into the required file. Refusing the float constructor therefore cannot
be a successful completion of this charter. Counting only
`tests/fixtures` and `lean_frontend/corpus` would give the worker a false
choice. My earlier conditional suggestion to refuse floats applied only
if the entire required input set permitted it; it does not here.

The unconditional signed-zero negative control also needs an accepted
floating domain. A refusal of both the original and mutated values is
not evidence that the representation comparison detected the changed
sign.

**Suggested fix:** require representation-preserving quotation of the
non-NaN floating leaves needed by the full acceptance set, explicitly
including libc, and remove the blanket float-refusal option from this
dispatch. Include signed zeros in the supported domain: unchanged +0
and -0 examples must pass, and a sign-flipped, elaborating literal must
fail the representation comparison. Keep refusal for unsupported
cases, with counts over all required inputs, and resolve
NaNs as in F2. This does not require changing any fixture or baseline.

### F2. [P2, new] The optional NaN branch is incompatible with an unconditional generated-BEq acceptance check

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:50–54,70–74,123–124`.

Q:52 permits NaNs to be handled separately, but Q:54 also adds generated
whole-file `BEq` to the mandatory round-trip check. That test is not a
weaker equality on NaN-bearing values: an unchanged NaN fails it.
`generated/Core.lean:489` compares floating leaves with Float `BEq`;
the pinned toolchain's `Init/Data/Float.lean:133–144` specifies its
non-reflexivity on NaN, and `include/lean/lean.h:3085` implements it as
C floating equality. Thus an otherwise exact NaN round trip would be
rejected by this additional condition.

Nor does treating any pair of NaNs as equal preserve the chosen
representation contract. `CerbFloat.lean:348–354`'s warning is accurate
for the shipped binary. Read-only disassembly of `lean_float_to_bits`
shows the unordered comparison selecting `0x7ff8000000000000`, losing
both sign and payload. The installed declaration's general bit-conversion
description is not sufficient evidence to override this implementation.
No new native seam is licensed by the charter's inherited rules.

**Suggested fix:** make named NaN refusal the specified behaviour for
this dispatch, subject to checking that no required input needs one.
Keep the generated-BEq positive check restricted to that supported
domain, and test NaN refusal separately. If NaN support is retained as
an option, first specify a feasible representation-preserving method
and an explicit conditional treatment of the auxiliary `BEq` result;
do not silently canonicalize NaNs, equate all NaNs, or claim that a
false auxiliary result is a passed check. The non-NaN bits clause,
including signed zero and infinity, is consistent with the inspected
toolchain and needs no replacement.

To reproduce the static binary inspection with the pinned toolchain
selected, without running Lean:

```sh
objdump -d --disassemble=lean_float_to_bits \
  "$(dirname "$(dirname "$(elan which lean)")")/lib/lean/libleanshared.so"
```

### F3. [P3, R1 cleanup still open] Old summaries contradict the repaired map contract and control list

**Location:**
`lean_frontend/docs/2026-10-18_codex-charter-core-quote.md:40,68–69,102,115,117`.

The detailed rule at Q:38–39 correctly branches on the outer
constructor, but Q:40 abbreviates this to non-empty left inputs.
That is not the discriminator: `.mk cmp .Empty` is empty under
`fmapIsEmpty` (`LemLib.lean:1204–1208`) and still contributes the left
comparator at `:1273`. Q:102 repeats the unconditional left-comparator
claim and still cites `:937–940` for `Fmap.mk`; those are the `Pmap`
constructor lines, whereas `Fmap` is at `:1192–1194`.

Q:68–69 and D1 also compress every map to a tree with a comparator,
omitting the `.empty` alternative that the new leading rule requires.
D3 still names four negative controls, although success item 2 now
lists seven families, including both directions of the outer-tag swap.
The detailed criteria prevent treating these abbreviations as permission
to omit work, but a dispatch document should not send the worker back
to the superseded requirements.

**Suggested fix:** use `.mk` versus `.empty` consistently, include the
both-empty union result, correct Q:102's constructor citation and union
summary, and have the shortened deliverables refer to the full
outer-constructor rule and all of success item 2's controls. Remove the
stale numeric control count.

### Provenance and control checks that passed this review

The provenance task is derivable from the named paths. It does not
require recovering a name from an arbitrary runtime closure. The
worker's table still has to record each elaborated monomorphic term,
its fixed instance arguments, and `.empty` as having no comparator.
The following inspected paths support that task:

| Value/path | Evidence and implication |
|---|---|
| Program `tagDefs`, `enumDefs`, `funs`, `funinfo` | `generated/Translation.lean:5643–5650,5663–5666,5828–5841,6178–6191` identifies the `fromList`, insertion and field-assembly paths. Resolve `fromList` through pinned `LemLib/Map.lean:61–63,101–105`, not the derived structural symbol instance. |
| Core standard-library map and `impl0` | `Main.lean:45–72,1081–1108`: `std.core` declarations go through `fromList`; the implementation map captures `implementation_constant_compare`. These fields also enter the assembled libc file. |
| Libc-specific maps | `Main.lean:246–257,993,1013–1029`: the three rebuilt symbol maps use the `libcSymMapCmp` alias of `symbol_compare`; `extern` is taken from the metadata file; three fields are `.empty`. The separate `stdlib` field comes from `std.core`, not the libc rebuild. |
| External-name map | `generated/Translation.lean:6143–6154` maps the desugared external identifier map; `generated/Cabs_to_ail_effect.lean:3679–3709` constructs it; `generated/Core_linking.lean:33–77,457` identifies its subsequent linking and name-based comparator path. |
| Nat-keyed maps | `generated/Cabs_to_ail_effect.lean:2136–2137` and `generated/Translation_effect.lean:301–303` supply `defaultCompare`, as the charter now says. |
| Linking and conversion | `generated/Core_linking.lean:465–496` gives field-specific retention/union and the fold direction. `generated/Core_run_aux.lean:931–952` preserves fields or maps values; pinned `LemLib.lean:1232–1237` preserves the outer constructor and captured comparator during those maps. |
| Derived `labeled` maps | `generated/Core_aux.lean:2577–2587,2637–2672,2824–2837` starts from `.empty`, inserts with the active symbol `ordCompare`, and traces both union branches. `generated/Driver.lean:2413,2422` installs the result at run initialization. These are provenance background for the consumer's derivation, not additional quoted fields under Q:58–59. |

The libc round trip must use `convert_file libcFile` for the Lean value
returned by `loadLibc`, alongside the actual post-link `runFile`.
`Main.lean:83–109,1135–1139` explains the text-plus-metadata input path.
It is not a quotation of the OCaml Marshal object itself. In particular,
preserving this value does not repair the pre-existing libc float
rounding deviation N3 (`VALIDATION.md:310`); changing that literal to
the oracle's original value would violate this quotation contract.

The non-float controls are constructible without changing generated
types: `main`, global initializers and bindings are ordinary data;
`Pmap.Node` permits a height mutation with the same spine; both empty
map constructors are available. For the comparator control, two
explicit `MapKeyType sym` dictionaries can project through the same
`mapKeyCompare` head, one using the active symbol comparison and one
the derived structural comparison. On a singleton storing `s`, an
unstored description-only alias `s'` is found only by the former
(`Symbol.lean:237–250,277–286,330–343`). Its term mismatch and lookup
difference are separate observable failures. No execution of these
controls is claimed here. Each mutated literal should elaborate, with
an accepted unchanged control, so a syntax error or blanket refusal
cannot stand in for the intended comparison failure.

The boundary statement remains appropriately limited: this is a tested
representation link for the admitted pipeline outputs with comparator
provenance supplied by source inspection, not a kernel proof of printer
correctness or a universal lookup theorem. The consumer retains the
per-field lemma and option B remains the named boundary mover.

No operator quotation was found in the revised charter. Static reading
did encounter one in the historical pinned `LemLib.lean:835–837`; current
Lem mainline already paraphrases that comment. This report does not copy
the wording or propose rewriting pinned history.
