# Outcome protocol v2 — operational reporting

**Revision 3 — independent-review amendments, 2026-10-20.**
Dated delivery amendment, 2026-10-20: §4.1 also admits the source-checked installed
cap wrapper suffix, as ruled and measured in checkpoint record E.1.
Implementation clarifications, 2026-10-20: the mini-run loss below is also within
the emitted-record limitation (checkpoint record A.6); §4.1 admits the observed
Bash padding before the optional core-dump marker (checkpoint record B); §5
records CerbTags' execution-register scope disposition (checkpoint record C.1).
**Status: operative design for charter checkpoints A–E.** Implementation status
is tracked in [the checkpoint record](2026-10-20_outcome-protocol-record.md).
Author: [AGENT 2026-10-20].
Initial source/probe base: `e7e9bb427a514b6053865c303c4af512907da75b`, with only the
design/review/plan documentation added, at branch head `aeac9e722` before this note.

[USER 2026-10-20] The accepted review supersedes v1 as an assessment of the design.
The next delivery is operational reporting with the existing sentinel and pure
abort limitations disclosed; the structural-outcome work remains their mover.
V1 is retained as history, not as the specification for dispatch.

[USER 2026-10-20, scope] Delivery is limited to preserving the upstream
correctness claim and supplying cerberus-caesium with every attributed stop in
a batch. Broader changes to the validation infrastructure are outside this
mission. The in-process/sentinel limits and structural mover above still apply.

All proposed interface and policy choices below are **[AGENT 2026-10-20]**.
The [mission plan](2026-10-19_outcome-protocol-revised-mission-plan.md) is an input;
this revision narrows its delivery scope. Earlier v2 text is retained in git,
not as an alternative specification in this file.
This document defines the proposed contract without requiring v1 or its errata.
The [independent review](2026-10-19_outcome-protocol-design-review.md) remains the
record of the twelve findings; §7 disposes of each. The
[current charter](2026-10-18_codex-charter-outcome-protocol-s1-s2.md) replaces
the earlier S1–S2 dispatch with checkpoints A–E and records the operative
rulings. Its historical file name does not select the withdrawn v1 scope.

## 1. Scope, guarantees and limits

### 1.1 The semantic contract stays separate from the report

CONTRACT §1 continues to permit only the oracle's observable verdict, a loud
refusal, a resource outcome, or a registered deviation. The protocol reports
what happened; it does not register deviations, establish correspondence, or
make a defect into an allowed fifth outcome.

| Reported evidence | Meaning and contract treatment |
|---|---|
| Completed verdicts | Defined/Undefined/ordinary Error observations eligible for the existing comparison; completion alone is not agreement. |
| `REFUSAL` | An attributed unsupported boundary and its mover. A refused run is incomplete and never semantic agreement. |
| `UPSTREAM_CRASH` | A hand-written producer declares a mirrored upstream failure and supplies its source citation. Eligibility for a registered failure comparison still requires the lane's reviewed policy and oracle evidence. |
| `INVARIANT` | A port invariant failed. This is a defect requiring investigation, including when the oracle also crashes. |
| `RESOURCE` | Existing fuel/declared-limit outcomes remain incomplete, never a C behaviour or agreement. This mission decodes the fuel forms; new host and stack classification is deferred (§9). |
| Legacy panic, origin unattributed | A validated LemLib panic without an outcome envelope. Neither an upstream attribution nor a diagnosis of a semantics defect. |
| Protocol/supervision problem | Classification cannot establish the required observation. RED; not a permitted semantic outcome. |

Only the three uppercase stop constructors in §2 can be emitted by the new Lean
builder. RESOURCE is derived from the existing resource evidence, never from a claimed
class inside a message. There is no `SHARED_CRASH` fallback. In particular, the
128 generated register rows remain unmigrated; an envelope-less panic does not
identify which of them, or which external caller of LemLib, produced it.

One process can report several executions and several causes. The report is a
collection of complete emitted records, not a choice of a winning class or a
record of every evaluated branch. A valid verdict followed by a stop does not
establish a completed verdict set. An emitted invariant is not hidden by fuel,
OOM, another stop, or malformed later output.

### 1.2 The operational claim

The new stop encoding separates fields and escapes input-derived text on every
stop channel. The Python decoder checks the supplied capture for every stop
and exact fuel frame, without inspecting escaped program stdout/stderr or
ordinary Error payloads for stop markers. It uses the existing stdout/stderr/
status inputs and makes no new claim to authenticate host diagnostics. These
are properties of the producer and decoder, to be tested on the candidate.

Attribution assumes the pinned driver and dependencies, the declared switches
and runtime, and the documented OCaml Cabs bridge. It is not a theorem about
arbitrary Core/Cabs values or arbitrary Lean callers. Existing legacy record
printers and panic text are not authenticated transports. Recognition of their
syntax alone does not prove their semantic origin.

The ModelFailure limitation is concrete: `modelFailStopLoc` has runtime value
`Loc.other "model fail-stop"`; an ordinary Error0 with that location compares
equal in Main's printer. Cabs admits arbitrary `Loc_other` strings. A parsed
ModelFailure envelope is therefore diagnostic metadata, not proof that the kill
was constructed by `failStopKill`. The interface must not advertise such a proof.

Pure sites retain `failwithI`, whose runtime implementation uses the existing
unsafe/`implemented_by` boundary. Every driver/library execution used for this
operational interface requires `LEAN_ABORT_ON_PANIC=1`. The driver checks it;
in-process callers must arrange it. A runtime abort is not a kernel-visible
distinguished outcome. No axiom/kernel acceptance claim follows from these probes.

Collection completeness covers **complete EMITTED records in the supplied
capture only**. Main obtains the exhaustive result list before printing batch
records (`Main.lean:1239–1258`); `CerbND.runNDFuel:134–139` accumulates branch
results first. A pure abort during exhaustive exploration discards already
evaluated typed stops before they reach that printer. The capture can therefore
contain only the later pure panic, with no ModelFailure for an earlier typed
stop. The decoder cannot recover those un-emitted causes. Reporting every cause
encountered during evaluation requires execution/producer changes in the named
structural-outcome arc, not a stronger decoder claim or an added streaming runner
in this mission. Checkpoint E includes a concrete mixed pure/typed witness.

There is also a consumer before the final batch printer: constant-expression
evaluation runs `Mini_pipeline.run_const_expr_driver`, then
`evalConstantExpressionAux` consumes its results. Its catch-all replaces a typed
Error0 (except its special range-error case) with a generated legacy failure
(`frontend/model/mini_pipeline.lem:199–218`, checked at checkpoint A's base).
That loses attributed metadata before emission; no decoder can reconstruct it.
The resulting envelope-less panic remains legacy/origin-unattributed. Repairing
that `.lem` path is outside this mission and belongs with the structural mover.

The named mover is the
[structural-outcome arc](2026-09-16_lean-only-outcomes-implementation-plan.md):
WP1 replaces sentinel/text recognition with structural outcomes; WP2 covers
refusals and its low-level unsupported-feature mapping. Pure-return functions
also require the queued Lem failure-monad/effect work, not merely WP2's adapter
change. That dependency remains explicit within the structural work.

### 1.3 Fixed scope constraints

[AGENT 2026-10-19, orchestrator constraints relayed by the operator]
This delivery must preserve the `.lem` sources and Lem pin and must not
introduce a new opaque atom. No new failure leaf is proposed. Existing kill
types and pure/monadic mechanisms stay. Allocator OOM remains the ordinary
semantic kill named by `Interface.oomOutcome`; it is
not host RESOURCE. Ordinary Error, the inherited asm rejection, the fuel value,
address-space parameter, run digest, enum reader and arity-matcher contracts are
not redefined. Different ordinary verdicts remain differential findings.

The admitted machine interface is batch execution plus attributed driver
admission failures. Human execution summaries, `--pp-core`, `--parse-core`
success output and `--trace-nodes` instruments are not batch observations.
Their existing dedicated decoders remain explicit; they may use the stop decoder
for failures but cannot obtain semantic agreement by falling through it.

## 2. Structured stops and the frozen wire schema

### 2.1 Representation decision and common JSON rules

**Use fixed-length JSON arrays, not JSON objects.** On Lean 4.32.2 and Python
3.12.3, the default object parsers both retain the last duplicate key; an escaped
spelling of the same key also collapses. Python can expose pairs, Lean's parsed
object already lost them (§8.1). Rejecting duplicates after Lean object parsing
would be an unenforceable promise. Arrays avoid that problem without a new JSON
object parser.

These rules freeze the stop envelope schema. The Python result is an object
API, not another wire protocol:

- Only arrays, strings and `null` occur. Objects, JSON numbers and booleans are
  rejected at every depth. Every tuple has exactly the stated length. Extra or
  missing elements are errors; optional values occupy their slot as `null`.
- Versions and natural numbers are strings. `NatText` is `0` or a nonzero ASCII
  digit followed by ASCII digits; `PosText` excludes `0`. No sign, leading zero,
  exponent or decimal point. Validate ranges where specified. This avoids
  cross-parser numeric coercion, including Python's bool/int relation.
- Input is strict UTF-8. Strings contain Unicode scalar values. Producers emit
  compact JSON, one physical line, with a final LF on stream/file records. The
  embedded envelope String has no terminal LF. Decoders allow spaces/tabs between
  tokens, not raw CR/LF within the JSON text, and require exactly one value.
- String escapes allowed on the wire are `\"`, `\\`, `\/`, `\b`, `\f`, `\n`,
  `\r`, `\t`, and `\u00HH` for U+0000–U+001F only. Other Unicode is literal
  UTF-8. A small escape-token validation pass precedes the stock parser; it must
  distinguish an escaped backslash from a Unicode escape. In particular, lone
  surrogate escapes are rejected before Lean can replace them (§8.1). This is
  a restricted wire spelling, not a claim that other JSON spellings are invalid JSON.
- Objects with duplicate keys are rejected because **all objects are forbidden**,
  even if the stock parser has discarded duplicates. Repeated strings in arrays
  are ordinary values, not duplicate fields. Exact tuple lengths prevent a second
  positional field being appended. Repeated stop records are retained (§4).
- Unknown version, tag, constructor, enumeration member or tuple shape is a
  protocol/schema error. No best-effort parsing, unknown-field ignoring, legacy
  envelope fallback, or trusted class carrying `_malformed` is permitted.

`Text` below is a Unicode string, possibly empty; `Nonempty` excludes empty.
Legacy diagnostics remain Python bytes; they need no new serialization here.
Do not replacement-decode them before classification. All dynamically supplied
stop fields go through the JSON serializer, never interpolation into JSON syntax.

### 2.2 Constructor fields

The exact envelope prefix is the ASCII bytes `cerberus-lean stop `, followed by
one `Stop` tuple. The first element is the wire version string `"1"`; this is
the first version of the implemented protocol, despite this document being v2.
The reserved prefix family is `cerberus-lean stop`: an invalid suffix or the old
unversioned grammar in a stop position is malformed, not an absent envelope.

| Constructor | Exact tuple, in field order |
|---|---|
| Refusal, length 8 | `["1","REFUSAL",boundary,item,detail,mover,upstream,see]` |
| Upstream crash, length 7 | `["1","UPSTREAM_CRASH",site,detail,upstream,tray,see]` |
| Invariant, length 5 | `["1","INVARIANT",site,detail,see]` |

`boundary` is one of the thirteen literal strings below. `item` is `Text | null`:
an empty argv/switch element is representable and different from no item.
`detail`, `mover` and `site` are Nonempty. `see` is `Nonempty | null` for refusal
and upstream crash, and required Nonempty for invariant; it names the relevant
contract, invariant or project record.

```text
fs pnvi switches concurrency float-format cli runtime library-location
cabs-json-utf8 batch-ub-payload abort-flag fuel-arg address-space-arg
```

`upstream` is required for UPSTREAM_CRASH and nullable for REFUSAL. Its exact
shape is `[repository,revision,path,first,last,text]`: repository is `"cerberus"`
or `"lem"`; revision is a full 40-character lowercase hexadecimal commit;
path is a nonempty repository-relative path with no empty, `.` or `..` components;
first/last are PosText with first ≤ last; text is Text containing the cited source
text. The source at that revision, not a moving line number alone, is the reference.
Schema validity does not establish that the citation or mirroring claim is true;
source review and the lane evidence do that. An absent refusal citation is null,
not an empty fabricated upstream reference.

`tray` is exactly one of `["none"]`, `["pending"]`, `["draft",number]`, or
`["filed",url]`. Number is PosText; url is a nonempty absolute HTTPS URL to the
filed issue. `none` means no report is identified, not that the upstream behaviour
is correct. Draft and filed status are distinguished; drafting never implies
network filing. There are no optional trailing fields on any tuple.

Examples of complete embedded envelope strings:

```text
cerberus-lean stop ["1","REFUSAL","fs","open","cannot open a\nb","a filesystem model",null,"CONTRACT.md §3"]
cerberus-lean stop ["1","UPSTREAM_CRASH","CerbMem.memcmp","non-integer byte",["cerberus","b9aeedcb4dd438763b0eef7f95ac19e93875d7de","memory/concrete/impl_mem.ml","2658","2659","assert false"],["none"],null]
cerberus-lean stop ["1","INVARIANT","Main.judgeSwitches","refusal returned","Main.refuseSwitches must terminate"]
```

An injected newline, cap banner, fuel marker or another envelope inside detail
is JSON string data. Slashes, spaces and colons in item have no field authority.
The optional upstream source text can contain every delimiter used by v1.

### 2.3 Lean values and channel adapters

`CerbStop.Stop` is an inductive type with the three constructors and structured
Boundary, Upstream and Tray values above. Builders return that type. Required
nonempty/range constraints are validated when constructing metadata; a bad
static producer is a test/build defect, not a fallback class. `render : Stop →
String` and `parse : String → Except DecodeError Stop` implement §2. The essential
round-trip is `parse (render s) = .ok s` for well-formed stop values. No claim
that re-rendering arbitrary accepted JSON preserves its whitespace is needed.

- Pure producers spell `failwithI (CerbStop.render stop)` at the site. The census
  head stays visible; no wrapper conceals a new polymorphic failure leaf.
- The typed-kill adapter accepts a structured upstream/invariant value, renders
  it, then calls today's `failStopMem`. It cannot accept a refusal by accident.
- `refuseM` accepts a structured refusal and uses the existing memM panic
  mechanism. It does not put a refusal string inside an ordinary Error kill.
  **Amendment, 2026-10-20 (checkpoint record C.5):** its implementation is
  `ND fun s => (NDkilled (failwithI (CerbStop.render (.refusal r))), s)`.
  The fixed killed node retains the input state; the opaque reason aborts at
  node construction. This preserves the public all-switch load-erasure theorem
  without assuming an erasure equation for an opaque whole-monad value.
- CLI rendering and exit are separate: build a **nonempty list** of refusals,
  print every envelope, then exit once with 2. Invariant CLI output is one
  invariant envelope, also exit 2. No fall-through default value is introduced.
  Batch printer admission checks, notably the UB byte-domain check, run over
  the pending results before any stdout record/header is emitted; a later
  unprintable result must not violate the CLI channel's empty-stdout rule.
- Main's ModelFailure printer retains its outer byte/String escaping. Decode
  that layer first, then parse exactly the resulting envelope. The inner JSON
  escaping is distinct; the existing outer decimal byte escapes are not JSON.

WP1/WP2 can inspect these constructors rather than parse strings. The future
mapping is fuel → Exhausted, semantic refusal → Unsupported, and upstream or
invariant → FailStop with its diagnostic metadata retained. Admission boundaries
are not automatically members of the future low-level semantic enumeration.
If that arc needs structured origin in its Lem type it must charter that type
change; v2 does not invent it or promise unchanged String-only signatures. The
legacy fuel/sentinel decoders retire when WP1 replaces them, per that arc's rule.

## 3. Existing capture and resource boundary

Use the current capture shapes: separate stdout/stderr bytes and the original
process status, either in memory or in the existing `.stdout`, `.stderr`,
`.status` files. Do not add capture files, a Host tuple, a new capped mode or a
new timeout convention. `scripts/capped`, `common.sh` and the capture runner are
outside the implementation file fence.

Restate the existing LADDER/observation-codec rule: **bare exit 137 is RED;
a positive owned-cgroup `memory.events` `oom_kill` counter is the OOM witness**.
The counter is read before the group is removed. A positive counter can accompany
parent exit 0 or 1; zero is not a breach and unavailable is not zero. These are
existing distinctions, not a new interface. §8.2 records the actual wrapper
probes. A banner-shaped string supplied by a program is not a kernel counter.

`decode_stop` does not infer a host resource cause from 137, 124 or a cap banner.
The caller retains its existing resource handling and original capture. A host
failure cannot make an admitted INVARIANT disappear. This does not certify every
existing caller's resource classifier: §8.4 records a pre-existing PNVI divergence
from the bare-137 rule. New resource-policy work is not smuggled into this mission.
Unknown termination stays a failure, not an attributed stop or agreement.

The exact fuel value remains reserved until WP1. Decode it only at these frame
positions, after identifying the record/frame that owns the bytes:

| Fuel form | Position and normal status |
|---|---|
| Kill | The entire batch Error message is `lem: fuel exhausted`; preserve its execution index. Existing single/multiple framing gives status 1/0. |
| Bare panic | First stderr line exactly `lem: fuel exhausted`, followed only by the admitted optional trace and wrapper suffix (§4.1); empty stdout; status 134. |
| Translation panic | Exact LemLib panic origin/header of §4.1, payload exactly `lem: fuel exhausted`, then the admitted trace/suffix; empty stdout; status 134. |

Do not use `FUEL_RECORD.search(stdout + stderr)` to implement this decoder.
Fuel-looking lines inside a refusal detail, a legacy panic's continuation or an
ordinary non-fuel Error are data or malformed framing, not an independent fuel
cause. Decode the outer record before considering its payload. An exact fuel
Error and a ModelFailure in the same batch retain both causes. Human-mode fuel
summaries are not admitted as batch records. The measurements in §8.3 include
both panic forms and the stack form; stack classification itself is deferred.

## 4. Python stop decoder over the existing channels

### 4.1 Admission and framing

The decoder belongs in `scripts/observations.py`, using existing record/escape
helpers where they apply. It is an additive API for stop metadata, not a
replacement for observation comparison or a new validation runner. Preserve the
usual `NO_COLOR=1`, `TERM=dumb` invocation settings. Raw ANSI/NUL in framing is
an error, never silently normalized; encoded bytes in data remain data.

| Channel | Existing capture shape | Stops admitted |
|---|---|---|
| CLI | Empty stdout; one or more envelope lines on stderr; exit 2 | A nonempty list of REFUSALs, or one INVARIANT. |
| Panic | Empty stdout; exact LemLib panic frame on stderr; exit 134 | REFUSAL, UPSTREAM_CRASH or INVARIANT. A validated frame without an envelope is legacy/unattributed. |
| ModelFailure | `ModelFailure {msg: "<outer-escaped envelope>"}` in stdout; single exit 1 or framed multiple executions exit 0 | UPSTREAM_CRASH or INVARIANT, one decoded occurrence for every such execution. |
| Ordinary batch record | Existing Defined/Undefined/Error shape and exit convention | No stop recognition inside program-data fields or ordinary Error messages. Exact fuel is handled as in §3. |

The exact panic header is `PANIC at _private.LemLib.0.failwithIImpl
LemLib:<line>:<column>: <payload>` on **one line**, with positive decimal
coordinates. Another origin is an error until reviewed. New encoded payloads
occupy one physical line. A trace, when present, is `backtrace:` followed by one
or more complete frames matching
`[^\r\n]+\([^()\r\n]*\) \[0x[0-9a-fA-F]+\]`.

Current captures may append `timeout: the monitored command dumped core` and
the shell's capped `Aborted` diagnostic. Admit these only as a terminal wrapper
suffix after an otherwise complete frame: at most one timeout core-dump line,
then at most one line matching this pattern (full-line match):

```text
(?:[^\r\n]*/)?scripts/capped: line [0-9]+: +[0-9]+ Aborted(?: +\(core dumped\))? +"\$@"
```

This extends today's `ABORT_WRAPPER` with the exact root-relative
`scripts/capped` spelling emitted by §8.3's recipe. Absolute/prefixed paths
retain the existing alternative. The suffix remains terminal, in the stated
order and cardinality; the extra spelling does not admit arbitrary diagnostics.
The optional core-dump marker also permits Bash's space padding after `Aborted`,
as measured by B's native adapter probes. No tabs, arbitrary tail, new wrapper
path, or extra suffix occurrence is admitted by that spacing amendment.

**Delivery amendment, 2026-10-20 (checkpoint record E.1).** The terminal
wrapper position also admits the installed `capped` form used by Caesium.
Its prefix is `(?:[^\r\n]*/)?capped: line [0-9]+: +[0-9]+ `, followed by
`Aborted(?: +\(core dumped\))? +`, then this **literal** command text:

```text
( { echo "$BASHPID" > "$cg/cgroup.procs"; } 2> /dev/null || { echo "$prog: could not move into $cg: refusing to run uncapped" 1>&2; exit 4; }; exec env CAPPED_STATE=1 CAPPED_MEM_MAX="$MEM" "$0" "$@" )
```

The path prefix may vary with installation; no machine path is hard-coded.
The two wrapper spellings are alternatives for the same single terminal slot,
not two successive suffixes. Timeout-line ordering and cardinality are unchanged.
Changed commands, tabs in the padding, extra suffixes and trailing material are
errors. This is diagnostic framing, not authentication or OOM evidence.

Never strip arbitrary matching lines from payloads or treat a suffix as OOM or
timeout evidence. Direct driver captures without wrapper suffixes are also
admitted. The Caesium demonstration must include its actual `cap timeout` suffix
shapes; any necessary additional suffix fixture is narrow and source-checked,
not a permissive diagnostic-tail regex. Unsupported trailing material is an
error while previously decoded metadata remains available.

For a legacy panic, payload may continue up to a line exactly `backtrace:`.
After that delimiter only the complete trace and admitted suffix may occur;
without it the continuations are payload. Remove only the printer's final LF.
An additional fatal/stop/fuel frame inside those continuations makes the capture
ambiguous: report the problem, do not reclassify that payload as a resource or
another trusted stop. A reserved `cerberus-lean stop` prefix with an invalid
version, constructor or field is malformed, not a legacy panic.

Batch framing remains one unheaded record, or contiguous `EXECUTION 0:`,
`EXECUTION 1:`, … with one record per header and at least two executions. Keep
the existing optional header exit annotation. Decode every ModelFailure's outer
escape layer before parsing its envelope. Missing/duplicate headers, extra
records, bad escapes and malformed trailing data are errors. Preserve complete
stop occurrences even when a later record is malformed or truncated; never
claim completion from that prefix. A stop-looking ordinary Error remains data.

Check stderr as well as stdout before declaring the stop decode clean. A raw
stop beside an otherwise valid verdict is a channel error, not an ignored line.
Do not delegate to today's `parse`/`failure_message` and return early before
checking the rest. This requirement is local to the new API; it does not charter
a rewrite of all existing classifiers or a new global completion protocol.

### 4.2 Object API and absent versus malformed

The proposed public Python entry point is:

```python
decode_stop(stdout: bytes, stderr: bytes, status: int) -> StopDecode
```

`StopDecode` carries ordinary Python objects with these required contents:

- `stops`: every decoded occurrence from complete emitted stop records in order,
  with its channel, execution index (None for CLI/panic), source position and the
  complete structured Stop.
  The Stop exposes all §2 metadata, including upstream source text, mover, tray
  and see. There is no summary class selected from the collection.
- `legacy_panics`: validated envelope-less panic payloads as bytes, explicitly
  origin-unattributed. They are neither SHARED_CRASH nor an ordinary Error.
- `fuel`: every exact fuel occurrence with its form and execution index where
  applicable. No occurrence is inferred from a substring or from host status.
- `problems`: every admission/schema/framing problem with its channel/position
  and explanation. Retain successfully decoded occurrences alongside problems;
  do not raise away the whole result on the first bad record.

These are API requirements, not a second JSON schema. Dataclass/type layout can
follow the existing Python module's conventions. Keep original capture bytes
with the caller; no replacement decoding or truncation before this call. No new
machine CLI or capture format is required.

Envelope recognition has three distinct results at each eligible position:
**absent**, **present and valid**, and **malformed reserved envelope**. An ordinary
verdict with no eligible envelope is a clean absence, not a stop. An absent
payload envelope on an otherwise valid panic produces legacy/unattributed;
an absent envelope on ModelFailure is a missing-envelope problem. A malformed
reserved prefix always produces a problem and must not take the absent branch.
The Lean `DecodeError` likewise distinguishes absent from malformed input.
A capture with no admitted ordinary record or failure frame produces an
unrecognized/truncated-capture problem, not clean absence. A status inconsistent
with the decoded channel is a separate problem; it does not erase decoded stops.

An occurrence decoded before a whole-capture problem is retained as diagnostic
metadata; its presence does not validate the capture. A caller must inspect
problems and all cause collections. It must not use `stops == []` as a completion
predicate: legacy panic, fuel, malformed output and unknown termination are
also incomplete/failing cases. Only when the new decoder has no causes/problems
may the caller continue to its existing ordinary verdict and status checks.
Those checks still establish completion and comparison, not `decode_stop` alone.

Inspect all complete records before applying resource/status early returns.
Thus a fully decoded INVARIANT remains a defect even if the process later dies
or a resource is also observed. A partial trailing record is an explicit problem,
not a fabricated stop; host-cause attribution remains the caller's existing
responsibility. No policy for accepting new mixed resource/crash baselines is
introduced here.

### 4.3 Exactly the retained lane corrections

Only `scripts/pnvi_lane.py` and the classifier in
`scripts/test_immaculate.sh` receive stop-policy changes:

1. Inspect the decoded stop collection before oracle matching and resource/crash
   early returns. Any INVARIANT is RED, even against an oracle crash/resource,
   another stop, or malformed later output. Never project it to CRASH/BOTH_FAIL
   or accept it through a baseline pin; INVARIANT must fail the lane.
2. Envelope-less validated panic is legacy/unattributed, never SHARED_CRASH.
   Existing coarse negative-test crash pins may keep their historical spelling;
   that spelling makes no producer-origin or semantic-agreement claim.

The hooks needed for these two corrections read the new structured payloads;
within PNVI, retaining its existing refusal witnesses means reading the same
R-PNVI item from the new refusal field instead of the old textual prefix. This
is producer-format compatibility, not a new lane policy or a common-entry
migration. Preserve existing oracle-side patterns and registered refusal rules.
No other lane is rerouted, no resource direction rule is redesigned, and no
new `.unsupported.c` policy or general mixed-cause baseline system is added.
Test pins and witnesses broken by the producer changes are updated in C.

## 5. Delivery, consumers and required checks

One branch, coherent internal commits, one complete first consumer delivery.
A–E are work checkpoints, not additional trust gates. Do not advertise an accurate hand-written-mirror mapping before C finishes.
The estimates below are **[AGENT]** planning ranges in focused engineering days
for one worker with the prepared build. They exclude review queueing and elapsed
standing ladder runs; they are not deadlines or a reduction of required checks.

| Checkpoint | Deliverable | Effort estimate |
|---|---|---|
| A | Review this scope, settle remaining §6 choices, amend the charter/file fence and confirm Q-A dispositions. Inventory `test/Unit/ReconstructLegacyTest.lean` and its dependent theorems; obtain the pending reference-contract ruling below before C changes those claims. No capture-infrastructure design step. | 0.5 day |
| B | Structured Lean stop/codec/adapters and Python `decode_stop`; focused shape, escaping, absent/malformed and collection tests. | 1–2 days |
| C | **Full producer migration:** nine typed kills; existing pure/monadic and driver refusals; remaining hand-written pure mirrors/guards; twelve config-dead switch refusals. One envelope per switch element, then one exit. Update immediate tests/pins and PNVI/CLI witnesses, including the three fuel CLI assertions; migrate `test/Unit/ReconstructLegacyTest.lean` and its dependent theorems under A's ruled reference contract; reseal the affected hand-written register keys. | 2–4 days; source citations and existing pins dominate |
| D | The two PNVI/immaculate corrections of §4.3, their focused plants, and only the baseline/diagnostic adjustments those changes actually require. No all-lane adoption. | 0.5–1 day |
| E | Demonstrate the actual `differential.py` capture shapes and the mixed pure/typed program below against the candidate and supply the patch recipe; complete standing checks and present the candidate for fresh review. | 1 day, plus independent review |

Checkpoint A measured **122 pure root-seam leaves**, including eleven outside
the existing execution register. All join C's inventory; the checkpoint record
A.4/A.6 supplies the reviewed per-site dispositions. C also converts CerbTags'
transparent `panic!` to the existing `failwithI` seam. Its target-coverage
declaration remains referenced, but reader lifting leaves the definition outside
both execution and frontend dependency closures. It receives no register row or
preamble entry; the scope ruling and reference check are recorded in the
checkpoint record C.1. This does not add an opaque atom or change any failure
trigger.

The implementation fence covers CerbStop and its tests, Lake roots/executable
registration, `handwritten_copy.manifest`, affected hand-written seams and Main;
`observations.py` and its tests; the two classifier hooks above and their tests;
producer-dependent test pins and reconstruction-reference proofs, their existing
axiom-census entries, PNVI/CLI witness scripts/stubs, register keys/seals and the
necessary documentation. It does not include changes to `capped`,
`common.sh`, `observations.sh` capture plumbing or wholesale lane call sites.
A small internal parsing helper may be shared to implement `decode_stop`; that
is not permission to refactor existing comparison or resource policy.

C includes all seven exact message pins in `test/Unit/MonadicFailstop.lean`,
`test/Unit/PnviArmsTest.lean` (both under `lean_frontend/`), and the three CLI
witness scripts and their stubs: `scripts/check_cli_refusals.sh`,
`scripts/check_runtime_resolution.sh`, and `scripts/check_cabs_json_utf8.sh`.
Update the
actual positive ModelFailure observation-lane plant to a valid new envelope,
and keep the envelope-less case as a distinct decoder negative. Other existing
producer-dependent expectations must be audited and updated, not left failing
because they were omitted from a file list. No lane acceptance rule is relaxed
for a new producer message. Keep a missed compatibility dependency visible as
a scope finding rather than silently widening the apparatus work.

C also includes `scripts/test_fuel_plant.sh:220–227`: the `--fuel 0`,
`--fuel abc` and `--fuel 5 --batch …` CLI assertions. Capture stdout/stderr
separately and pass them with the original status to `decode_stop`; replace the
old prefix greps with checks for no decode problems, exit 2, and one CLI
REFUSAL. Check boundary `fuel-arg` with item `0` or `abc` for the first two;
check boundary `cli`, item `--batch` and the retained canonical-position
explanation for the third. These remain refusal/status witnesses, not tests
that accept any decoded stop. The adjacent missing-argument exit-1 check stays
unchanged. `scripts/test_address_space.sh:258–263` checks detail substrings;
those checks survive if the domain and decimal-numeral explanations stay in the
rendered detail. This is producer-message compatibility, not a lane-policy change.

### Reconstruction reference contract for A and C

**[AGENT 2026-10-20, recommendation pending operator ruling]** Parameterise both
reference algorithms in `lean_frontend/test/Unit/ReconstructLegacyTest.lean`
over the six diagnostic messages (including a function of the pointer address
for the unknown-function-pointer message). Keep their reconstruction control
flow, fuel handling and ordinary values unchanged. A message record is a local
reference parameter, not another opaque failure atom. Each reference still uses
`failwithI` at its existing failure sites.

Use a historical message instance that reproduces the old strings and a
production instance that obtains each site's message from `CerbStop.render` on
its structured metadata. Prove the historical instance recovers the previously
frozen references; retain the C1 equivalence between the two reference
algorithms for the same arbitrary message instance. Restate the production
compatibility theorem at the **production renderer**, schematically:

```text
(reconstructValueAbst_lemFuel defaultSwitches fuel enumDefs ambient fo
    unionmap funptrmap addr ty bytes).2
  = reference productionMessages fuel enumDefs ambient unionmap funptrmap addr ty bytes
```

The theorem retains all current quantifiers, including every overlap closure,
fuel, type, byte list and map; no reachability premise excludes failure arms.
Its consequence for the wrappers and `loadM` uses that same production instance.
It is not literal equality to the old frozen messages, nor an equality between
opaque `failwithI` applications with different String arguments. The reference
headers, theorem descriptions and runtime success text must name the changed
claim rather than continue describing a verbatim pre-S2 production equality.

A inventories, and C restates/checks, these dependent theorem families in that
module (names below are the current names, not a requirement to hide the new
reference instance behind an old name):

- `reconstructValueLegacy_lemFuel_eq_indexed` and `reconstructValueLegacy_eq_indexed`;
- `reconstructValueAbst_default_snd_eq_legacy`, `reconstructValue_lemFuel_eq_legacy`
  and `reconstructValue_eq_legacy`;
- `loadM_reconstruct_default`, `reconstructValue_lemFuel_eq_indexed` and
  `reconstructValue_eq_indexed`.

Keep the production functions' names/types and default-mode closure-independence
claim. Explicitly document the changed diagnostic/reference contract for the
cerberus-sl compatibility claim; no consumer-facing guarantee may be weakened
silently. If that consumer still requires equality to the old failure strings,
raise that incompatibility before implementation. The operator has not yet
chosen this replacement contract; A records the ruling and confirms C's proof
work/estimate before dispatching it. Run the existing axiom census, including
`#print axioms` on the resulting headline theorems and the affected
`scripts/check_theorem_axioms.sh:811–817` entries, and kernel replay on the
resulting compiled modules. Updating statements/names must not drop a checked
cone, relax the allowed axioms or substitute runtime abort tests for proofs.
No extra gate is proposed and no replacement theorem is claimed proved here.

### Remaining producer checks

Switch tests cover empty/duplicate elements and both `--switches=x` and
`--switches x`, checking every emitted envelope. Existing declared exit-2
refusals are migrated; CLI INVARIANT remains exit 2. The separate exit-1 usage
paths keep their current behavior (§9), so they are not falsely described as
new attributed refusals. Parser errors and ordinary semantic Error stay separate.

The measured register has 239 rows: 111 hand-written and 128 generated.
Reseal the 35 existing-refusal keys and the remaining 76 hand-written keys with
old-to-new mappings; counts of keys and sites need not coincide. Recompute
position/reach evidence where a rewrite changes it. Synchronize generated copies
through the normal build procedure; do not edit them by hand. The existing
register checks remain. A new convention speedbump is deferred, and there is no
`common.sh` source-content manifest movement budgeted in this scope.

Focused tests cover the frozen JSON and outer escape layers; forbidden objects,
versions, fields and shapes; injected delimiters/control/fuel text; allowed and
wrong channels; multiple ModelFailures and switch refusals; good stops on both
sides of a malformed record, and truncated output; absent versus malformed; and
INVARIANT retained beside fuel or a later abnormal status. Exact fuel-frame tests include marker
text embedded in another diagnostic. The two lane plants must make INVARIANT
RED regardless of oracle output. No new host-sidecar, timing, supervisor or
exhaustive all-lane plant battery is required by this mission.

The existing Tier A/B schedule in `scripts/LADDER.md` remains the implementation
validation schedule. Changed proof declarations require the standing axiom and
kernel-replay checks. Every Lake/Lean invocation uses `scripts/capped`; the
recorded Lean probes used `CERB_MEM_MAX=32G`. This amendment is documentation
only: no build or release certification is claimed. Keep scratch under `.tmp/`
and commit conclusions/reproduction recipes rather than raw dumps.

### Consumer demonstration and patch recipe

The actual integration target is cerberus-caesium's `scripts/differential.py`,
not the stepper harness `check-caesium-exec.sh`. The read-only source check in
§8.4 locates `run`, `parse_driver`, `run_driver` and `driver_summary` at consumer
revision `75a6dd32e403df6597af7c0abb659c21d1214a89`. Its current runner returns
`(rc, out, err, secs)` from `cap timeout`, with stdout/stderr separate but already
text-decoded using replacement. Its batch invocation is `--batch`, optionally
`--first`, followed by runtime and Cabs arguments. There is no proposed sidecar
available to this consumer, and none is necessary for decoding the stop fields.

Prepare and demonstrate this patch recipe against that interface:

1. For the **driver call**, retain raw stdout/stderr bytes through decoding
   instead of `text=True, errors="replace"`. Keep the existing runner/cap/timeout
   arrangement and elapsed-seconds field. A driver-only raw-result option or a
   small driver capture adapter is sufficient; do not refactor unrelated phases.
2. Import `decode_stop` from the explicitly selected provider checkout/module
   that matches the candidate driver; do not find an arbitrary global module or
   implement another regex classifier. Call it on the complete capture before
   `head(err, 500)`, `bad[:5]`, or any resource/crash return.
3. Keep the returned stop occurrences with all metadata and indexes in the
   consumer's own result objects. Remove the conversion of ModelFailure into
   ordinary Error with a textual prefix. Preserve ordinary verdict records using
   the existing observation grammar. The consumer may serialize its own records;
   no new provider Report schema or CLI is needed.
4. Derive the consumer's fuel flag from exact decoded fuel occurrences, including
   translation panic; remove the merged-output line search for this driver path.
   Preserve legacy/unattributed and problems separately from the three stop tags.
5. Have `driver_summary` carry **every** decoded cause before handling rc 124/137,
   fuel or crash. A fully decoded INVARIANT marks a defect; a refusal/upstream
   stop makes the batch incomplete, never an ordinary C Error/verdict. Unknown
   137 remains unexplained, not asserted OOM. No early summary branch may drop
   later or mixed stop metadata. Keep stderr truncation as display only.

The demonstration consumes candidate-driver outputs through the consumer's
capture shape: one CLI refusal at exit 2; multiple rejected switch elements;
one panic refusal/upstream/invariant at 134; single ModelFailure at 1; framed
multiple ModelFailures at 0 with distinct classes; verdict plus stop; stop plus
exact fuel; malformed reserved envelope following a valid stop; and a validated
legacy panic with no envelope. Include the real wrapper suffixes, both fuel
panic forms and the already measured diagnostic-injection cases. Fixture-built
mixed batches are identified as fixtures, not claimed C end-to-end executions.
Assert exact metadata and occurrence counts, not just a nonempty stop list.

Checkpoint E also runs the revision-2 review's mixed pure/typed program:

```c
int memcmp(const void *, const void *, unsigned long);
int open(const char *, int, ...);
int a;
int f(void) { a = 1; return 0; }
int g(void) {
  int x, y;
  if (a) return memcmp(&x, &y, sizeof x);
  return open("x", 0);
}
int main(void) { return g() + f(); }
```

Store it under `.tmp/`, obtain fresh Cabs using §8.3's bridge recipe, then run
through the same capped engine recipe with `--batch --first` and with `--batch`
(no `--fuel 128` override). The independent review at `19d8c9980` measured one
memcmp ModelFailure at exit 1 with empty stderr in the first-trace run, but
exit 134, empty stdout and an `open 'x'` refusal panic in exhaustive mode.
After migration E must verify one emitted UPSTREAM_CRASH in the first run and
one emitted REFUSAL panic, with **zero emitted ModelFailures**, in the second.
The missing typed stop is a producer/exploration limit, not successful recovery
by `decode_stop`. This is a real C witness, distinct from the mixed-batch fixtures.

Deliver the candidate results and patch recipe, with the remaining legacy and
sentinel limits. The consumer handoff must state that collection completeness
covers complete **emitted** records only: a pure abort during exhaustive
exploration discards already-evaluated typed stops before batch printing. The
consumer receives the emitted panic, not a list of those lost causes; absence
of their ModelFailures does not establish that they were never evaluated.
This design task does not change the external consumer, and provider delivery
must not claim external adoption until that separate work is
authorized and done. Cerberus-sl's existing fuel/OOM aliases and kill lift remain
compatibility constraints of §1; no additional consumer migration arc is added.

At the first complete delivery, existing declared refusals expose REFUSAL;
hand-written mirrors expose UPSTREAM_CRASH with source/tray metadata; annotated
guards expose INVARIANT; generated envelope-less panics remain legacy/unattributed.
The unmigrated usage errors, host supervision and stack reporting are expressly
outside that three-class promise, not temporarily relabeled as shared failures.

## 6. Questions for dispatch, with recommendations

The operational scope and its two goals are settled. These **[AGENT]**
recommendations restate the original questions without reopening deferred work
as an implementation prerequisite.

| ID / question | Recommendation |
|---|---|
| Q1 — Names and attribution | **[AGENT]** Keep the three emitted tags and legacy/unattributed for envelope-less panic. No SHARED_CRASH inference or semantics-origin proof. |
| Q2 — Allocator OOM | **[AGENT]** Keep the existing semantic kill/consumer alias, distinct from host OOM. |
| Q3 — Usage errors | **[AGENT]** Preserve current exit-1 behavior in this delivery; defer attributed 1→2 conversion and its additional admission paths (§9). |
| Q4 — Config-dead switch kills | **[AGENT]** Migrate all twelve through the existing memM panic mechanism with structured switches refusals. Keep the library abort-setting limit explicit. |
| Q5 — Thirteen boundaries | **[AGENT]** Keep §2's wire vocabulary; do not silently enlarge the future low-level Unsupported enumeration. WP2 owns that mapping. |
| Q6 — Q-A dispositions | **[AGENT]** Complete all hand-written mirror/guard annotation, including unreachable sites. Keep the print-then-kill and defined arms unless separately ruled; settle those inventory dispositions before C. |
| Q7 — Unsupported fixtures | **[AGENT]** A filename is not evidence of REFUSAL. Defer the proposed new exec-lane acceptance rule; do not claim it was installed by this mission. New consumer attribution comes from the decoded class. |
| Q8 — Register convention report | **[AGENT]** Keep the required reseals and existing register checks; defer adding a new lexical speedbump. |
| Q9 — Stack | **[AGENT]** Retain the measurement in §8; defer the new RESOURCE/stack classifier. No bare-134 or stack-substring shortcut enters `decode_stop`. |
| Q10 — Trays | **[AGENT]** Carry accurate existing none/pending/draft/filed metadata, including bswap64's draft 12. Preparing additional reports is separable from the two goals; no filing or broad tray campaign is required for delivery. |
| Q11 — CLI invariant exit | **[AGENT]** Keep exit 2, with the class in the validated envelope. |
| Q12 — Collections and lane behavior | **[AGENT]** Return all causes through §4.2's Python objects; apply only the two §4.3 lane corrections. No scalar-stop or first-match summary. |
| Q13 — Host/capture redesign | **[AGENT]** Defer it as ruled; restate today's positive-counter/bare-137 rule without claiming authenticated legacy stderr (§3/§9). |
| Q14 — Delivery boundary | **[AGENT]** Finish producer checkpoint C and demonstrate the consumer interface before claiming complete delivery. Replace the old S1–S2-only charter accordingly. |

The stop JSON schema stays frozen. The worker does not choose duplicate/optional/
unknown-version behavior again. No broader runner/schema decision is needed to
implement the Python object API. This document changes no standing practice.

## 7. Disposition of the twelve review findings

“Deferred” below is an acknowledged residual with a reason in §9, not a claim
that the corresponding apparatus was repaired.

| Finding | Resolution in this scope / explicit residual |
|---|---|
| 1 — Ambiguous fields and diagnostic marker injection | §§2.1–2.2 retain injective encoding and escaped dynamic fields; §§3–4 decode markers only in their owning frames. New producers cannot inject another envelope/fuel record through detail. General host-banner provenance is deferred (§9), not certified by the decoder. |
| 2 — Forgeable ModelFailure attribution | §1.2 retains the concrete sentinel limit under the operational ruling and names the structural mover. No new atom or authenticity theorem. |
| 3 — Exit 137 is not OOM | §3 restates today's rule: bare 137 RED, positive owned `oom_kill` counter the witness, including descendant OOM at parent success. §8.2 retains the probes; no sidecar is needed to state or obey that distinction. |
| 4 — First-match/channel bypass | §4 decodes all supplied stop positions, distinguishes absent/malformed, validates class/channel/fields, and preserves errors alongside earlier stops. Ordinary Error payloads remain data. This is a local decoder contract, not a wholesale classifier rewrite. |
| 5 — Multiple ModelFailures/causes | §4.2 returns every indexed occurrence in complete emitted records; §5 requires consumer summaries to retain that collection and demonstrate the pure-abort loss before emission (§1.2). No new Report wire schema is needed. |
| 6 — Invariant/resource hidden by coarse projections | §4.3 makes INVARIANT RED in PNVI and immaculate before any oracle/resource early return. No new generic STOP→CRASH projection is introduced. Wider resource/mixed-cause lane-policy redesign is deferred (§9). |
| 7 — Missing migration work | A/C include the pending reconstruction-reference contract and dependent proofs; C also includes all seven MonadicFailstop message pins, PNVI/CLI witnesses, the three fuel CLI assertions, observation-plant positive/negative cases and register reseals. Those remain required despite the smaller apparatus scope. |
| 8 — Multi-line CLI and usage exits | §§2.3/4.1 preserve one envelope per switch element and one exit after the collection. §5 retains current usage exits; the separate 1→2 change is deferred (§9), removing the contradictory unchanged-exit promise. |
| 9 — Fuel/stack facts and delivery overlap | §3 retains exact kill, bare-panic-with-trace and translation-panic forms; §8.3 retains measured stack framing. New stack classification is explicitly deferred, with no competing delivery promise (§9). |
| 10 — Premature or false consumer attribution | §5 keeps full producer C before complete delivery, gives the actual consumer patch recipe and lists remaining limits. Generated legacy panics are never automatically SHARED_CRASH. |
| 11 — Classifier CLI loses metadata | §4.2's Python objects retain all fields and occurrences; §5 uses that API before truncation. The consumer does not depend on the lossy proposed CLI. A new machine CLI is deferred (§9). |
| 12 — String-only adapters cannot support WP2 | §2.3 keeps structured Boundary/origin values through adapters and names future mapping/type work without claiming unchanged String-only signatures. |

V1's three errata remain reflected in findings 3, 4 and 10. Neither v1 nor an
older v2 revision is an alternative fact table for this mission.

The subsequent review, `2026-10-20_outcome-protocol-v2-review.md` at commit
`19d8c9980`, has these four dispositions in revision 3:

| Revision-2 finding | Revision-3 disposition |
|---|---|
| 1 / P1 — Frozen reconstruction-reference proofs | §5 A/C inventory both reference algorithms and all dependent theorem families; the parameterised-message contract is an **[AGENT] recommendation pending operator ruling**, with unchanged quantifiers, explicit consumer notice and existing axiom/kernel checks. No implementation or ruling is claimed. |
| 2 / P2 — Typed causes lost before pure abort | §§1.2/4.2 limit completeness to complete emitted records; §5 repeats the limit in the handoff and adds the review's mixed pure/typed program to E. |
| 3 / P2 — Root-relative capped suffix | §4.1 admits the exact `scripts/capped` alternative, preserving terminal position, ordering and cardinality; §8.3's root-relative recipe is supported. |
| 4 / P3 — Fuel CLI assertion inventory | §5 C names all three assertions, requires decoder-based class/boundary/item checks with exit 2 retained, and records why address-space detail checks can survive. |

## 8. Measurements and reproducible probes

These probes used the existing build; no production source was modified. Raw
captures and scratch sources were removed after this record was written. They
do not certify an implemented codec. Host/timeout probes below remain useful
measurements of existing mechanisms; their proposed interface work is deferred
in §9, not a prerequisite for this narrower delivery.

### 8.1 JSON duplicate keys and Unicode

Create `.tmp/outcome-v2/JsonProbe.lean` with the following body, then from
`lean_frontend` run
`CERB_MEM_MAX=32G ../scripts/capped lake env lean --run ../.tmp/outcome-v2/JsonProbe.lean`:

```lean
import Lean
def main : IO Unit := do
  for input in ["{\"class\":\"REFUSAL\",\"class\":\"INVARIANT\"}",
                "{\"class\":\"INVARIANT\",\"class\":\"REFUSAL\"}",
                "{\"cl\\u0061ss\":\"REFUSAL\",\"class\":\"INVARIANT\"}",
                "[1,\"REFUSAL\",\"fs\",null,\"a\\nb\\u001bc\",\"mover\",null,null]",
                "[1,\"INVARIANT\",\"x\",\"\\ud800\",\"cite\"]"] do
    match Lean.Json.parse input with
    | .ok value => IO.println s!"OK {value.compress}"
    | .error error => IO.println s!"ERROR {error}"
```

Exit 0, verbatim output (these are parser probes, not schema-valid v2 stops):

```text
OK {"class":"INVARIANT"}
OK {"class":"REFUSAL"}
OK {"class":"INVARIANT"}
OK [1,"REFUSAL","fs",null,"a\nb\u001bc","mover",null,null]
OK [1,"INVARIANT","x","�","cite"]
```

Python reproduction: for the same three object strings `s`, evaluate
`json.dumps(json.loads(s), separators=(',', ':'))`, then
`json.loads(s, object_pairs_hook=lambda pairs: pairs)`. Python 3.12.3 output:

```text
default {"class":"INVARIANT"}
pairs [('class', 'REFUSAL'), ('class', 'INVARIANT')]
default {"class":"REFUSAL"}
pairs [('class', 'INVARIANT'), ('class', 'REFUSAL')]
default {"class":"INVARIANT"}
pairs [('class', 'REFUSAL'), ('class', 'INVARIANT')]
```

Thus neither default object decoder can enforce duplicate rejection after
parsing. Lean's surrogate replacement also makes strict UTF-8 alone insufficient;
§2.1 excludes the lossy spelling before parsing. The implementation tests must
cover a literal escaped backslash followed by `ud800` as ordinary text, a real
replacement character as ordinary text, and rejected surrogate escapes.

### 8.2 What capped can read

Reproduction child, stored as `.tmp/outcome-v2/cgroup_child.py`:

```python
import pathlib, subprocess, sys
mode = sys.argv[1]
if mode == "oom":
    child = subprocess.run([sys.executable, "-c", "x = bytearray(256 * 1024 * 1024)"])
    print(f"child_returncode={child.returncode}", flush=True)
relative = pathlib.Path('/proc/self/cgroup').read_text().split('0::', 1)[1].strip()
group = pathlib.Path('/sys/fs/cgroup') / relative.lstrip('/')
pathlib.Path(sys.argv[2]).write_text(str(group))
for name in ('memory.max', 'memory.swap.max', 'memory.events', 'memory.events.local'):
    print(f"{name}=" + repr((group / name).read_text()), flush=True)
raise SystemExit(137 if mode == 'exit137' else 0)
```

From the repo root run `CERB_MEM_MAX=32G bash -x scripts/capped python3
.tmp/outcome-v2/cgroup_child.py zero .tmp/outcome-v2/zero.path`, then `exit137`
instead of zero. Run the OOM child with **128M**, not 32G, so its one 256 MiB
allocation tests the local cap without consuming machine-scale memory. Trace
stderr and save stdout under `.tmp/`. No process other than this probe's child
is targeted; no machine configuration is changed.

| Mode | Wrapper status | `memory.max` | `oom_kill` | Group exists after return |
|---|---|---|---|---|
| zero | 0 | 34359738368 | 0 | False |
| native exit137 | 137 | 34359738368 | 0 | False |
| oom, child return -9 | 0 | 134217728 | 1 | False |

The unmodified wrapper trace reads `sed -n 's/^oom_kill //p'
<owned-group>/memory.events`, assigns `CAPPED_OOM_KILLS=0` or `=1`, then removes
the group. Its positive-case banner was:

```text
capped: OOM-KILLED (memory.events oom_kill=1, cap CERB_MEM_MAX=128M; command exit 0 — a descendant was killed by the cap; NOT a clean pass)
```

For the post-migration check, copy the wrapper into `.tmp/outcome-v2/` and insert
only these diagnostic reads immediately before its `rmdir "$CAPPED_CG"` line,
after the existing write to `"$CAPPED_ORIG/cgroup.procs"`; rerun zero and oom:

```bash
echo 'PROBE: after wrapper migration, before removal' >&2
for field in memory.max memory.swap.max cgroup.events memory.events; do
  echo "PROBE: $field" >&2
  cat "$CAPPED_CG/$field" >&2
done
```

Both exited 0 and the group was subsequently absent. Verbatim positive-case
probe output before the unchanged banner:

```text
PROBE: after wrapper migration, before removal
PROBE: memory.max
134217728
PROBE: memory.swap.max
0
PROBE: cgroup.events
populated 0
frozen 0
PROBE: memory.events
low 0
high 0
max 36
oom 1
oom_kill 1
oom_group_kill 0
sock_throttled 0
```

The zero control showed the 32G limit, zero swap, populated 0 and all these event
counters zero. The `max` count is a measurement, not an acceptance constant.
This was instrumentation of a disposable copy, not an implementation of v2.
Systemd/unavailable modes were inspected in source, not exercised successfully
by these direct-backend probes.

The timeout convention was also probed with `LC_ALL=C timeout --verbose
--signal=TERM --kill-after=5s 1s bash -c
'exec "$@" >"$PROBE_STDOUT" 2>"$PROBE_STDERR"' probe python3 -c <code>`, where
the two PROBE paths name fresh files under `.tmp/outcome-v2/`. The codes were
`raise SystemExit(124)` and `import time; time.sleep(3)`. Verbatim summaries:

```text
exit124 status= 124 host_stderr= b'' engine_stderr= b''
sleep status= 124 host_stderr= b"timeout: sending signal TERM to command 'bash'\n" engine_stderr= b''
```

This establishes the local notification distinction, not a completed capture
implementation or a claim about every timeout implementation.

### 8.3 Current engine forms and inventory

Use `opam exec --switch=. -- _build/default/backend/driver/main.exe
--runtime="$PWD/_build/install/default" --cabs-json <scratch.c>` to obtain fresh
Cabs. Engine recipe from the repo root:
`CERB_MEM_MAX=32G LEAN_ABORT_ON_PANIC=1 scripts/capped timeout 45
lean_frontend/.lake/build/bin/cerberus-lean --batch [--first --fuel 128]
--runtime="$PWD/_build/install/default" <scratch.json>`.
The optional flags, when used, precede runtime: `--first` immediately follows
`--batch`. These settings are necessary; the initial bridge invocation without
opam/runtime failed, and an initial misordered `--first` was correctly refused.
Neither failed setup was counted as a resource witness.

- Stack source: `int main(void) { while (1) {} }`, exhaustive/default fuel.
  Exit 134, stdout empty. Verbatim stderr prefix as bytes:
  `b'\nStack overflow detected. Aborting.\ntimeout: the monitored command dumped core\n'`;
  followed by the shell's capped `Aborted` line.
- Translation source: an uncalled `int unused(void)` returning
  `'1 + (' * 192 + '0' + ')' * 192`, plus `int main(void) { return 0; }`;
  run with the optional flags. Exit 134, stdout empty; first stderr line:
  `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: lem: fuel exhausted`,
  followed by `backtrace:` and runtime frames.
- Bare fuel runtime probe: a scratch file importing `LemLib`, with
  `def main : IO Unit := IO.println (fuelExhaustedWith "lem: fuel exhausted" (0 : Nat))`.
  From `lean_frontend`, run it through `CERB_MEM_MAX=32G LEAN_ABORT_ON_PANIC=1
  ../scripts/capped lake env lean --run <scratch-file>`. Exit 134, stdout empty;
  stderr begins `lem: fuel exhausted\nbacktrace:\n`, followed by runtime frames.
  A single-marker-only specification would reject this real form. The first
  attempt used an incorrect qualified name and failed elaboration; only the
  unqualified, successful runtime probe supplies this evidence.

Register counts are read with `check_failure_reach.read_register`, distinguishing
`lean_frontend/generated/` from hand-written paths, and checking every
`row['seal'] == seal_of(row)`. Baseline counts use noncomment rows, not substring
counts including headers. Counts are starting facts, not immutable acceptance
targets; the candidate must be measured again. Verbatim live count summaries:

```text
register rows=239 handwritten=111 generated=128 refusal_keys=35 remaining_keys=76 seals_valid=True
tests/immaculate/baseline.txt [('MATCH | L=CRASH', 18), ('DIFF | L=CRASH', 6), ('ORACLE_CRASH', 7)]
scripts/gcc_oracle_baseline.txt [('SKIP_LEAN_CRASH', 18)]
scripts/exec_coverage_baseline.txt [('UNSUPPORTED', 2)]
tests/pnvi_lane/baseline.txt [('REFUSAL', 7), ('BOTH_FAIL', 2)]
gcc total occurrences 21
```

The 35 refusal keys are the fsRefusal/pnviRefusal keys plus formatFixed's key.
The gcc count distinguishes **18 actual rows** from 21 textual occurrences
including comments, correcting the older note's ambiguous count. These reads
do not rerun the differential lanes or the live dependency/position census.

A final stock-parser round-trip probe used the chosen string-version array
shape with control bytes, Unicode, spaces/slashes/colons and a literal backslash
before `ud800`. Lean `Json.parse`/`compress` under the same capped recipe and
Python `json.loads`/`json.dumps(..., ensure_ascii=False, separators=(',', ':'))`
both emitted these exact lines:

```text
["1","REFUSAL","fs","a / :","x\ny\u001b☃😀","mover",null,null]
["1","INVARIANT","x","\\ud800","cite"]
```

To reproduce, JSON-quote these input strings in the Lean loop of §8.1 and pass
them directly to Python's loads. This verifies the selected spelling through
the stock parsers; schema admission and the escape-token guard still require
their implementation tests. No implementation, ladder, merge or push is claimed.

### 8.4 Consumer and classifier source checks for revision 2

Read-only checks used cerberus-caesium HEAD
`75a6dd32e403df6597af7c0abb659c21d1214a89`; `scripts/differential.py` and
`scripts/env.sh` had no local modifications. No consumer files were changed.
Reproduce by reading these definitions at that commit:

- `run:148–159`: exported `cap` around `timeout`; separate captured stdout/stderr;
  `text=True, errors="replace"`; returns rc, output, diagnostics and seconds.
- `parse_driver:529–552`: iterates batch records but converts ModelFailure to
  Error plus a textual prefix. Execution headers are discarded there.
- `run_driver:555–561`: parses before returning only five bad lines and 500
  diagnostic characters; searches merged text for fuel and misses the translation
  PANIC payload form. These truncations must follow stop decoding, not precede it.
- `driver_summary:716–752`: returns early for 124, 137, fuel and other abnormal
  statuses. Stop collections must be attached before those branches.
- `scripts/env.sh:65`: cap invokes an available `capped` or the command directly;
  its implementation is not this provider's proposed sidecar interface.

At the provider base, `observations.parse` rejects bare 137 and LADDER specifies
positive OOM evidence. `pnvi_lane.classify_side`, however, currently has
`obs.CAP_OOM.search(stderr) or status == 137` in its KILL branch. That existing
resource-policy divergence is not evidence for a new 137→OOM rule. It remains
explicitly outside this amendment's two lane corrections; the decoder never
uses it as a witness. No claim that every legacy resource classifier already
obeys the normative rule is made.

## 9. Deferred (not needed by the two goals)

The scope ruling defers the following work. Deferral preserves the two-goal
claim because the consumer receives every complete emitted stop through the
existing channels, subject to §1.2's loss before emission and with no new
positive host-origin or completion claim. Unexplained or malformed observations
remain failures. Existing limitations are stated, not
renamed as successful classification.

| Deferred work | Finding(s) addressed | Why deferral is sound for this delivery |
|---|---|---|
| The capture sidecar and Host tuple; new capped capture mode, stream separation, finalization/ownership rules and portability policy | 1 (host-banner provenance), 3, 6 | Stop-class metadata is already carried by the existing producer channels. `decode_stop` does not derive host causes from diagnostic banners. Today's positive-counter/bare-137 rule remains; no new guarantee that legacy stderr authenticates a host event is offered. §8.2's probes remain facts, not an interface dependency. |
| A new timeout notification convention and timing/hang subtype | 3, 6, 9 | The three stop tags and their collections do not require new deadline evidence or timing. Existing resource handling stays outside the stop decoder; resource/status returns must preserve already decoded stops. No status alone is newly promoted to trusted resource evidence. |
| The Report JSON schema, lossless machine CLI and new completion/projection API | 4, 5, 11 | The in-process Python API preserves every stop and all metadata, alongside problems and raw captures held by the caller. Consumer code uses that API directly, then its existing ordinary-observation checks. There is no lossy provider CLI in the integration path. |
| Usage-error exit 1→2 and expansion into new attributed admission paths | 8 | Existing declared refusals migrate, and per-element switch envelopes fix the actual collection defect at the existing exit 2. Plain usage failures retain their behavior and are not promised a new REFUSAL tag. No semantic verdict is changed by postponing admission unification. |
| Rerouting every lane through one classifier; new resource-direction/mixed-cause policies, `.unsupported.c` policy and a global baseline re-record | 6, 7, 10 | C supplies metadata; only the two named lane corrections are needed here to prevent invariants being accepted as crashes and to avoid invented shared attribution. Consumer integration retains all causes independently. Existing failure policies are neither broadened nor certified by this deferral; the PNVI resource-rule divergence is recorded in §8.4. |
| New RESOURCE/stack classification | 9 | Stack is not one of the three emitted stop classes. Keeping an unclassified stack abort failing does not fabricate a verdict or an upstream attribution. The measured full frame remains in §8.3 for a later classifier task. |
| New message-convention speedbump and a general tray-drafting campaign | 7, 10, 12 (future maintenance) | Existing register gates, required reseals, producer tests and source review cover this migration. Existing attribution/tray metadata must be accurate, but neither an extra check nor preparing every future report is necessary to expose the metadata to the consumer. |

The usage scope deferred above includes Main's explicit exit-1 branches at
1496, 1613, 1678, 1690, 1696, 1701 and 1759, plus empty-input handling in
`readInputs:335`. These source locations were measured in the first v2 pass;
they are not a five-site budget. Keeping this inventory does not schedule the
conversion in checkpoint C.

The structural-outcome and pure-failure arcs remain the already named movers
for §1's accepted limits (finding 2 and the later part of finding 12). They are
not covert additions to this reporting mission. Any later deferred task gets
its own scope and review; it must not be folded into producer migration merely
because the earlier v2 draft described it.
