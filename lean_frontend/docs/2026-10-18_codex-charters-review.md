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
