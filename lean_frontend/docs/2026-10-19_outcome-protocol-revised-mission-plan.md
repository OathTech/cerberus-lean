# Outcome protocol — revised mission plan

**Status: proposed, [AGENT 2026-10-19].** This is the reviewer's recommended
replacement structure for the mission, not an implementation authorization or
an amendment to standing project rules. It accompanies the
[independent review](2026-10-19_outcome-protocol-design-review.md), committed at
`6f35148acc22a2e00b4f593e919992977fc74ce1`, against code at `e7e9bb427`.
All design choices below are recommendations by the agent. No new operator
rulings are recorded here.

If accepted, reconcile the [design note](2026-10-17_outcome-protocol-design.md)
and replace the deliverables/file fence of the
[S1–S2 charter](2026-10-18_codex-charter-outcome-protocol-s1-s2.md) before dispatch.
Keep the review as the independent record of the original proposal.

**Recommended mission**

Deliver an operational outcome interface for the shipped driver: consumers can
separate completed verdicts, declared refusals, annotated upstream failures,
port invariant failures and resource interruptions, while retaining every cause
in an incomplete run. A malformed or unattributed failure remains visible. No
unknown failure is promoted to an attributed class to keep a lane green.

Use one implementation branch with small, coherent commits and **one first
consumer-facing landing**, after the hand-written producers and their consumers
are migrated. The original S1/S2/S3 order is useful internally, but publishing
S1 as the answer to the consumer's classification problem would be misleading.
The pure-mirror sweep belongs in the first complete delivery.

This mission changes reporting and classification, not C semantics or the
mechanism of pure failure. Allocator OOM, ordinary Error, inherited asm rejection,
the fuel value and the existing kill types retain their current meanings. The
structural-outcome and pure-failure arcs remain separate, with explicit residuals
below. CONTRACT §1's four outcomes remain the semantic contract; incomplete
diagnostics and protocol errors do not create another permitted C outcome.

**1. Set the claim boundary before implementation**

There are three different guarantees; the charter must not conflate them:

| Guarantee | Proposed scope |
|---|---|
| Framing and data isolation | Dynamic strings cannot create another record, field or host resource witness. The complete capture is checked. This is required now. |
| Operational attribution | The pinned, migrated driver emits a declared class and source citation under its documented input/configuration assumptions. This is useful evidence, not a correspondence theorem. |
| Structural distinction in Lean | Arbitrary Error0 values cannot impersonate a stop, and pure failures denote a distinguished outcome. The current location sentinel and panic leaf do not establish this; the queued structural work is required. |

Recommend proceeding with the operational mission now, explicitly retaining the
legacy ModelFailure limitation from review finding 2. Its parsed envelope is
diagnostic metadata, not proof that an Error0 was constructed by `failStopKill`.
State the driver input assumptions (the documented Cabs bridge/runtime recipe)
and the weaker guarantee for callers supplying arbitrary Core/Cabs/in-process
values. Do not add another opaque atom or a secret string as an attempted fix.
If the required deliverable includes unconditional structural authenticity,
the recommendation changes: execute the prerequisite structural-outcome work
first, under its own revised charter; a reporting-only mission cannot supply it.

Also withdraw the rule that an envelope-less LemLib panic means SHARED_CRASH.
Recommend retaining it as a **validated legacy panic with unattributed origin**
in the incomplete-run report. It is not a new semantic constructor or an
assertion that the failure is Lean-only. Existing shared-model examples can be
documented with their audited source origins, but absence of an envelope is not
general evidence of that origin. Explicit shared-source attribution can be added
when its producers carry it; it must not be inferred from arbitrary client code
that happens to call the same LemLib leaf.

**2. Separate the stop value, its rendering, and the run report**

Use a small structured Lean stop type, with separate constructors for refusal,
upstream crash and invariant failure. A refusal contains Boundary, optional item,
detail and mover; an upstream crash contains site, detail, upstream citation and
tray state; an invariant contains site, detail and its invariant citation.
Optional explanatory text stays data. Builders return this type, not a String
whose fields later adapters must rediscover.

Keep serialization at the boundary:

- Pure sites retain the census-visible `failwithI` head, applied to the rendered
  stop. No new polymorphic failure leaf is introduced.
- The memory adapter accepts a structured stop and renders it into today's
  `failStopMem`/ModelFailure channel. Its future structural implementation can
  inspect the constructor directly.
- The refusal adapter at memM retains today's abort mechanism. Its argument is
  a refusal value rather than an unparsed string.
- CLI handling builds all refused switch elements, prints one encoded stop per
  element, then exits once. A nonempty collection is required. Rendering a line
  and terminating the process are separate operations.

Recommend a reserved versioned prefix followed by **compact JSON**, using the
toolchain's existing JSON support rather than the free-form ` -- ` grammar.
Boundary and item are separate fields; spaces, slashes and colons in an item
have no syntactic authority. Example shape, to freeze at checkpoint A:

```text
cerberus-lean stop-v1 {"class":"REFUSAL","boundary":"fs","item":"open","detail":"...","mover":"..."}
```

Specify the schema completely at that checkpoint: exact fields/types for each
constructor, optional-field representation, unknown-version behavior and duplicate
field handling. Reject malformed, duplicate, unknown or missing required fields;
do not return a trusted class with a hidden `_malformed` flag. Verify the Lean
and Python parser behavior before choosing the final JSON object representation;
if a stock parser loses duplicate-field information, use an unambiguous fixed
array schema or an existing parser facility rather than building a general JSON
parser for this task.

JSON escaping must cover every input-derived string and every control byte
representable in those strings. Each encoded stop occupies one physical line.
The ModelFailure printer additionally applies its existing outer String.escaped
encoding; decoding reverses the outer encoding before parsing the stop. Preserve
UTF-8 text and arbitrary legacy diagnostic bytes without replacement decoding.
Give raw byte fields in the machine report an explicit lossless encoding, such
as base64; do not force undecodable captures into JSON text with replacement
characters.
Cross-language fixtures check value round trips, not incidental JSON whitespace.

Return a **run report containing collections**, not one selected Stop. It carries
completion, indexed execution results, all decoded stops, any validated legacy
panic, host resource evidence, and protocol problems. Partial verdicts remain
available for diagnosis but cannot use the completed-observation comparison API.
Two ModelFailures with different classes retain both; a fuel result or cap event
does not erase an already observed invariant or malformed record.

The classifier's machine CLI prints one JSON report containing the same
information as its Python API, including citations, movers, tray state and
diagnostics. Human summaries are a separate rendering. CLI success means that
classification succeeded; it never means that the program completed or matched
the oracle. Document that distinction beside the entry point.

**3. Move host evidence out of engine text**

The review's injected cap banner demonstrates that escaping new stop messages
alone is insufficient: legacy diagnostics and wrapper output still share stderr.
Recommend extending the project-local capture/cap interface so the supervising
wrapper records its resource evidence separately from the engine streams.

For each fresh capture, retain stdout, stderr and original status as today, plus
supervisor metadata distinguishing a positive OOM counter, a checked zero counter,
an unavailable counter, and no configured cap. Read the counter before removing
the owned cgroup. Publish metadata only for the invocation that produced that
capture; reused prefixes and missing/truncated required metadata fail loudly.
This is an extension of existing capture ownership, not a cryptographic record
system or protection against a malicious host process with the same privileges.

Only a positive supervisor witness yields RESOURCE/cap, including descendant OOM
when the immediate parent exits 0 or 1. A printed banner and a bare exit 137 do
not. Keep the banner for humans. On platforms where the wrapper cannot establish
or inspect a requested bound, report that limitation; do not invent zero OOMs or
silently grant a clean bounded-run claim. Preserve ordinary-machine portability
and use only capabilities the existing wrapper can obtain.

Timeout classification likewise belongs to the invocation's declared runner
convention/evidence, not a number interpreted without context. Keep the existing
CPU/wall hang subdivision as optional diagnostic information, with its measured
inputs retained. Do not grow an unrelated process supervisor in this mission.

Fuel and stack are engine-level failures. Decode their complete admitted forms:
the exact fuel Error record, bare fuel panic, translation failwithI fuel panic,
and the measured stack envelope including its leading newline and permitted
wrapper lines. Never search the combined streams for a matching line inside
another diagnostic's payload. Fuel embedded in an encoded detail is data.
An Error record with the currently reserved exact fuel message remains the
legacy special case until WP1 replaces it; ordinary Error messages containing
an envelope remain verdict data. After WP1, follow its no-legacy-decoder rule.

The measured stack capture supports classification work now. Preventing the
stack overflow remains the stack-ceiling mission. Resolve the two charters'
delivery overlap without making this reporting work wait for a recursion repair.

**4. Validate the whole run, then apply lane policy**

Implement the classifier as capture validation followed by cause collection.
Document a small channel table for allowed statuses, streams, record collections
and classes. Validate all CLI lines and every execution record, the panic origin
and complete allowed trace, encoding and forbidden raw stop records beside
verdicts. Distinguish a missing envelope from a malformed reserved-prefix envelope.
Never salvage the first good record while ignoring a later failure.

Real interruption can leave truncated output. Preserve the trusted resource
cause and mark the observation incomplete; retain the partial stream and any
independently established protocol problem. Define this case explicitly in the
classifier tests, so neither truncation nor a resource cause grants agreement or
conceals a fully decoded INVARIANT. A run with both invariant and resource causes
is still a port-defect finding.

| Collected result | Lane disposition |
|---|---|
| Completed verdicts, no stop/resource/protocol problem | Existing observation comparison, unchanged. |
| Declared REFUSAL | Incomplete; named refusal policies may accept a registered expected refusal. An `.unsupported.c` suffix alone is insufficient. |
| Annotated UPSTREAM_CRASH | Incomplete; an existing reviewed both-crash policy may account for it, never as semantic agreement. |
| Validated legacy panic | Incomplete with origin unattributed. Existing explicitly registered coarse crash cases may remain negative-test expectations; this does not certify SHARED_CRASH or permit arbitrary new failures. |
| INVARIANT anywhere | A defect, even if the oracle also crashes or the run later exhausts a resource. No expected-crash projection absorbs it. |
| RESOURCE | Incomplete, with the lane's existing direction rule where applicable. Never projected to a matching crash or a C result. |
| Malformed protocol or unexplained termination | RED with the original evidence and any other known causes retained. |

Retain legacy coarse crash pins only where they already describe reviewed negative
cases, and label their unattributed origin explicitly. Do not reclassify malformed
captures as legacy panics to satisfy a baseline. Any status change needed by the
corrected policy must be explained per row; the old blanket promise of zero
status movement is not an acceptance requirement. Semantic verdict changes remain
unexpected and require investigation before proceeding.

**5. Execution sequence and ownership**

One implementation owner should keep the producer/codec/lane changes coherent.
An independent reviewer examines the completed candidate and can challenge the
whole design; the implementation worker's conclusions are not a prescribed
review verdict. The following checkpoints organize work, not additional gates.
Existing ladder obligations still apply at commits and declared slice exits.

| Checkpoint | Work and concrete exit | Relative effort / main uncertainty |
|---|---|---|
| **A — settle the contract** | Incorporate the accepted choices into one authoritative design and charter. Freeze the structured stop/schema, report shape, trust limitation, channel table, lane policy and supervisor metadata. Use small framing/metadata probes to resolve implementation uncertainty. Reconcile every review finding and the original §6 questions. | Small design step; input-authenticity requirements could instead make the structural arc a prerequisite. |
| **B — implement the core** | Add the stop type, codec and machine report; add supervisor metadata and the classifier without switching production lanes yet. Test round trips, full-capture admission and collection. Keep existing comparison behavior available while adoption is incomplete. | Medium; capture portability and distinguishing wrapper text from engine payload are the principal risks. |
| **C — migrate producers and their immediate users** | Migrate nine typed kills, existing refusals/CLI, then the Q-A pure mirrors and switch kills. Update affected unit tests, PNVI wrapper and CLI witnesses in the same commits as their producers. Re-seal the 35 and 76 register populations separately, with old-to-new mappings. Finish all hand-written attribution before announcing the protocol as complete. | Largest, mechanical step; current site counts are a starting inventory, not a substitute for checking the candidate. |
| **D — adopt in the lanes** | Route the declared execution lanes through the common classification entry; apply the table above. Update failstop and observation-lane plants, including positive and negative ModelFailure controls. Make one deliberate immaculate re-record, with per-row explanation. Complete the existing required ladder checks. | Medium; several scripts classify directly rather than inheriting test_exec behavior. Inventory callers before claiming complete adoption. |
| **E — demonstrate and close** | Demonstrate the actual consumer-shaped binary and library uses against the candidate, publish the class/limitation table, and obtain independent review. Provide the commit, exact validation scope and remaining structural work for the operator's landing decision. | Small-to-medium; actual external consumer changes require their own authorized task. |

B–D may contain several commits. They are not independent product deliveries.
The Q-A rulings are prerequisites of C's sweep; if unavailable, deliver only a
clearly described partial foundation and do not claim the consumer mission is
finished. Do not widen semantic scope to obtain a convenient stop classification.

**6. Budget the actual files and moving checks**

The implementation charter should authorize these related surfaces together:

- Stop data/codec and their tests; `handwritten_copy.manifest`, Lake roots and
  executable registration. Generated copies must be synchronized by the normal
  build procedure; generated sources are not edited by hand.
- `CerbMem`, `CerbFS`, `CerbFloat`, `Main`, and the other inventory-listed seams;
  `test/Unit/MonadicFailstop.lean`, `PnviArmsTest.lean`, all three CLI witness
  scripts and their stubs. The seven old typed-kill message pins are real S1
  work, not an optional cleanup.
- `observations.py`, its shell interface and tests; the project `scripts/capped`
  interface; necessary capture wiring in `common.sh` and actual lane callers;
  fuel classification interfaces and the fuel/kill/hang/failstop/observation-lane
  plants. Wrappers may preserve their command interfaces, but should not retain
  separate competing rules for recognizing a stop.
- `pnvi_lane.py`, `test_exec.sh`, `test_immaculate.sh` and the direct consumers
  found during D's caller inventory. Include the positive envelope in
  `test_observation_lanes.py` and retain a distinct envelope-less negative case.
- Register keys/seals, the deliberate baseline changes, contract/validation
  wording, consumer notes and the final work record. Amend working-practice
  documents only with the required approval for any changed standing rule.

Unlike the original note, this plan expects the capture infrastructure to change.
If `common.sh` changes, its source-content row in `fork_drift_manifest.txt` must
move through the documented reviewed update. This is not an oracle semantic
change. Do not use a blanket manifest refresh. No Lem pin, `.lem` body, new opaque
atom or existing fuel/axiom census change is budgeted for the operational mission.
Any need for one is a scope finding, not an edit to conceal inside a re-seal.

The 35/76 split concerns message keys and seals, not permission to preserve a
position/reach classification that has actually changed. Recompute the live
position classes; explain any difference. Keep the proposed message-convention
check a cheap speedbump on the inventory it really covers, not an expanded gate
purporting to authenticate every panic or every consumer.

**7. Acceptance evidence**

Use the existing unit and lane plant suites. Add a compact set of tests that
catches the demonstrated classes of mistake, rather than an exhaustive Cartesian
product of all strings, statuses and channels:

| Test family | Necessary controls |
|---|---|
| Encoding | Filenames and argv with newline/CR/ESC, quotes, delimiter text, Unicode, spaces and injected fuel/cap/envelope text; Lean/Python round trips; outer ModelFailure escaping. |
| Admission | Valid class/channel cases; wrong origin/status/stream; malformed reserved prefix; unknown/duplicate/missing fields; valid verdict with a raw stop beside it; valid stop followed by bad data. |
| Collections | Two distinct stop classes; verdict plus stop; multiple switch refusals; later invariant; later malformed record; resource plus previously observed defect. |
| Host evidence | Native exit 137 and SIGKILL without OOM; positive descendant OOM at parent exit 0/1; forged banner with checked-zero metadata; unavailable/missing/stale metadata; declared timeout and CPU/wall subdivision. |
| Resources | Exact fuel kill, bare fuel panic, translation fuel panic, measured stack envelope and wrappers; identical markers inside payloads remain data. |
| Integration | All seven typed-kill unit pins, PNVI refusal witnesses, CLI witnesses, `.unsupported.c` with a genuine refusal and a mirrored crash, and the actual observation-lane positive/negative controls. |

Remeasure the register/baseline counts at the implementation base. The review's
239 rows, 35 refusal keys, 24 immaculate crash labels and two coverage refusals
are useful expectations, not immutable acceptance numbers.

Follow the existing Tier A/B schedule in `scripts/LADDER.md`; do not introduce
an additional certification runner or make every schema fixture a separate gate.
Use targeted tests while editing and the required ladder checks at claim points.
For changed proof declarations, run the project's axiom checks and capped
`lake env leanchecker` on the affected built modules as required by the standing
kernel-replay rule. Runtime probes do not substitute for those checks.

Implementation builds/probes use `scripts/capped` with `CERB_MEM_MAX=32G` in the
designated worktree; scratch and raw captures live under `.tmp/`. Keep commands
portable and record conclusions plus reproduction commands, not archived dumps.
This planning task itself runs no build or release certification.

**8. Consumer delivery and decisions needed**

For cerberus-caesium, demonstrate the interface used by `scripts/differential.py`,
not only the unrelated stepper harness: known upstream mirror, refusal, typed
kill, exact translation-fuel panic, stack failure and unattributed legacy panic.
Include a mixed-stop capture and show that all causes survive. Supply an explicit
consumer patch recipe or a patch prepared under a separate authorization; do not
claim the external consumer has adopted the API until that work is done.

For cerberus-sl, demonstrate decoding the diagnostic payload separately from its
semantic interpretation, and recheck the existing fuel/OOM aliases and kill-lift
shape. State plainly that `parse` returning a Stop is not a theorem distinguishing
the opaque sentinel from all ordinary locations. The current pure failure remains
a process abort under the required runtime setting.

All hand-written families become accurately annotated at the first complete
landing. Legacy generated panics retain an explicit unattributed status; they
never temporarily impersonate another source class. Later WP1/WP2 adapters can
consume the structured stop directly, with an explicit mapping to the low-level
Lem enumeration. Retire legacy sentinel/text recognition when that arc replaces
it, rather than promising unchanged string-only signatures indefinitely.

Before dispatch, the operator needs a concrete amended design answering:

1. Accept the operational scope and stated sentinel/pure-failure residuals now,
   or require structural outcomes first? Recommendation: operational delivery now,
   without structural-authenticity claims.
2. Accept unattributed legacy-panic reporting instead of automatic SHARED_CRASH,
   and the collection-based report? Recommendation: yes to both.
3. Authorize the capture/metadata surfaces and explicit lane policies above?
   Recommendation: yes; they address real attribution and completion defects.
4. Accept one complete first delivery including the Q-A sweep, and settle its
   outstanding inventory dispositions? Recommendation: yes; retain the existing
   semantics of the print-then-kill and defined arms unless separately ruled.
5. Resolve the original §6 choices in the revised context: attributed usage
   errors at exit 2, thirteen wire boundaries with a separate future semantic
   mapping, switch refusals using the existing mechanism, stack classification
   here, invariant exit 2, required refusal class for unsupported fixtures, and
   the modest register speedbump. Keep allocator OOM and tray-filing policy as
   assessed in the review. Recommendations remain those of that assessment,
   subject to the explicit changes in this plan.

These are proposed choices for the eventual dispatch decision, not a request to
approve an unfinished implementation. At close-out, present the tested candidate
and independent findings for the required merge decision. Push and off-machine
changes remain separately authorized actions. No such action is part of writing
this plan.
