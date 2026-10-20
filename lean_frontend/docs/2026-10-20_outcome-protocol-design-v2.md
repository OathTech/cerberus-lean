# Outcome protocol v2 — operational reporting

**Status: proposed replacement design, awaiting independent review and the remaining
dispatch rulings. No implementation is included.** Author: [AGENT 2026-10-20].
Source/probe base: `e7e9bb427a514b6053865c303c4af512907da75b`, with only the
design/review/plan documentation added, at branch head `aeac9e722` before this note.

[USER 2026-10-20] The accepted review supersedes v1 as an assessment of the design.
The next delivery is operational reporting with the existing sentinel and pure
abort limitations disclosed; the structural-outcome work remains their mover.
V1 is retained as history, not as the specification for dispatch.

All proposed interface and policy choices below are **[AGENT 2026-10-20]**.
They instantiate §§1–4 of the
[revised mission plan](2026-10-19_outcome-protocol-revised-mission-plan.md).
This document defines the proposed contract without requiring v1 or its errata.
The [independent review](2026-10-19_outcome-protocol-design-review.md) remains the
record of the twelve findings; §7 disposes of each. The
[old S1–S2 charter](2026-10-18_codex-charter-outcome-protocol-s1-s2.md) must be
replaced before implementation dispatch: its file fence, partial delivery,
unchanged-baseline promise and shared-crash fallback do not describe v2.

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
| `RESOURCE` | Fuel, a witnessed cgroup OOM kill, a witnessed deadline, or the admitted runtime stack failure. Incomplete, never a C behaviour or agreement. |
| Legacy panic, origin unattributed | A validated LemLib panic without an outcome envelope. Neither an upstream attribution nor a diagnosis of a semantics defect. |
| Protocol/supervision problem | Classification cannot establish the required observation. RED; not a permitted semantic outcome. |

Only the three uppercase stop constructors in §2 can be emitted by the new Lean
builder. RESOURCE is derived from the specified evidence, never from a claimed
class inside a message. There is no `SHARED_CRASH` fallback. In particular, the
128 generated register rows remain unmigrated; an envelope-less panic does not
identify which of them, or which external caller of LemLib, produced it.

One process can report several executions and several causes. The report is a
collection, not a choice of a winning class. A valid verdict followed by a stop
does not establish a completed verdict set. An invariant is not hidden by fuel,
OOM, another stop, or malformed later output.

### 1.2 The operational claim

The new stop encoding separates fields and escapes input-derived text on every
stop channel. Host evidence is captured outside engine text. Classification
checks the entire capture and does not inspect escaped program stdout/stderr or
ordinary Error payloads for stop markers. These are operational properties of
the producer, capture interface and decoder, to be tested on the candidate.

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

The named mover is the
[structural-outcome arc](2026-09-16_lean-only-outcomes-implementation-plan.md):
WP1 replaces sentinel/text recognition with structural outcomes; WP2 covers
refusals and its low-level unsupported-feature mapping. Pure-return functions
also require the queued Lem failure-monad/effect work, not merely WP2's adapter
change. That dependency remains explicit within the structural work.

### 1.3 Fixed scope constraints

[USER 2026-10-20, task constraints] This delivery must preserve the Lem sources
and pinned dependency and must not introduce another opaque sentinel.
No new failure leaf is proposed. Existing kill types and pure/monadic mechanisms stay. Allocator
OOM remains the ordinary semantic kill named by `Interface.oomOutcome`; it is
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

These rules apply to the stop, host metadata and machine-report schemas below:

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
`B64` is canonical padded RFC 4648 base64 using the standard alphabet, with no
whitespace, for arbitrary bytes. Empty bytes encode as the empty string. Decode
and re-encode to check canonical spelling. No replacement decoding of legacy
bytes. All dynamically supplied fields go through the JSON serializer, never
string interpolation into JSON syntax.

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

## 3. Capture ownership and host evidence

### 3.1 Proposed `scripts/capped` interface

The new interface, **not present in this tree yet**, is:

```text
CERB_MEM_MAX=<bound> scripts/capped --capture-prefix <prefix> --timeout-seconds <N|none> -- <command> <args...>
```

`prefix` is resolved to an absolute path by the wrapper at invocation. The caller
allocates it inside its existing unique observation run directory. In this mode,
the bound must be explicitly set to a finite positive size (normalized to bytes)
or the explicitly declared `none`; `max`/`infinity` and an absent setting are
configuration errors. This does not authorize an uncapped run contrary to a
lane's or operator's declared bound. N is positive integer seconds. The ordinary
`scripts/capped <command>...` interface remains compatible for builds.

The wrapper owns these files for one invocation:

| File | Contents / owner |
|---|---|
| `<prefix>.stdout`, `.stderr` | Engine stdout and engine stderr only, byte-for-byte. |
| `<prefix>.host.stderr` | Wrapper, shell signal and deadline-supervisor diagnostics; engine stderr is redirected separately before execution. |
| `<prefix>.status` | Runner's original shell status, decimal plus LF, including 128+signal convention; never rewritten into a protocol success code. |
| `<prefix>.host.json` | Final Host tuple below, written to a temporary file and renamed after finalization. |
| `<prefix>.command` | The exact argv in the existing shell-escaped diagnostic format; never evaluated to rerun a command. |
| `<prefix>.capture-error` | In-progress/failure marker, removed only after the capture files and final metadata are complete. |

Reservation is exclusive; any pre-existing member (including temporary metadata)
is a reused-prefix failure preserving the old capture. A mkdir lock/reservation
inside the fresh run directory suffices; no persistent registry or cryptographic
token service is required. The classifier checks the absolute prefix in Host
against its requested capture and checks `.status` against Host. Missing,
truncated, stale or contradictory required files are capture problems. An OOM
that kills the wrapper may prevent final metadata: that is **unexplained or
incomplete supervision**, never an invented cap witness.

`scripts/observations.sh` gains the explicit adapter
`observation_capture_protocol <prefix> <N|none> <command> [args...]`, invoking
the above mode. Callers stop surrounding it with another `capped`/`timeout` or
merging wrapper stderr into engine stderr. The existing `observation_capture`
remains for dedicated non-batch/bridge decoders until their call sites are
explicitly migrated; argv inspection must not guess which wrapper was used.
Bridge captures need the same host evidence but keep their JSON-transport decoder.

### 3.2 Frozen Host tuple and finalization

```text
Host = ["cerberus-capture","1",prefix,status,cap,deadline,timing,issues]
Cap = [backend,requested_bytes,configured_bytes,oom_kills,populated,cleanup]
Deadline = [seconds,expired,kill_after_seconds]
Timing = null | [cpu_ns,wall_ns]
```

Prefix is Nonempty; status is NatText in 0–255. Backend is `cgroup-direct`,
`systemd-scope`, `uncapped` or `not-started`. Requested bytes is PosText or null
(explicit no-cap request); configured bytes is PosText or null (not read).
This is the group's `memory.max`, not a claim to have measured every ancestor's
effective limit. `oom_kills` is NatText or null (unavailable); populated is `"0"`,
`"1"` or null, from `cgroup.events`. Cleanup is `removed`, `busy`, `failed` or
`not-applicable`. Direct captures require the actual limit to equal the requested
limit. A finite request fulfilled by `uncapped` is a supervision problem.

Deadline seconds is PosText or null. Expired is `"yes"`, `"no"` or `"unknown"`.
No deadline is `[null,"no",null]`. The bounded profile uses kill-after `"5"`;
an actual deadline therefore records `[N,expired,"5"]`. Timing is optional,
trusted nonnegative integer CPU/wall nanoseconds, never sampled from engine text.
Both timing elements use NatText; zero wall time leaves the subtype unspecified.
Issues is an ordered list of Nonempty wrapper diagnostics; every entry becomes
a supervision problem, not an ignorable warning. Null means unknown/not
applicable as specified, never a measured zero.

For a clean direct capture, requested/configured bytes are equal and nonnull,
oom_kills is nonnull, populated is `"0"`, cleanup is `removed`, and issues is
empty. An uncapped capture has all four Cap measurements null and cleanup
`not-applicable`; it can be valid only when no cap was requested and the caller's
profile permits that. Systemd captures have a finite request, unavailable
measurements and a witness-unavailable issue under the current backend.
`not-started` has unavailable measurements, cleanup `not-applicable` and a
setup issue. Other inconsistent combinations are schema/supervision problems.

In direct mode, the wrapper must:

1. Establish its owned group, verify the requested memory limit and zero swap,
   and run the command with engine and supervisor streams separated.
2. Wait for the immediate command, preserve its status, move the wrapper back
   to its original group, then read `cgroup.events` before removal.
3. If populated is zero, read `memory.max`, `memory.swap.max` and
   `memory.events`' **hierarchical `oom_kill`** counter, then remove the group.
   This avoids declaring a final zero while descendants can still run. If busy,
   retain any positive evidence but record `busy` and a supervision problem;
   do not kill unrelated processes or claim completion. Removal/read failure is
   also loud. The wrapper must not report `removed` when removal failed.
4. Write the final metadata and status. Return the command's status; metadata
   write/finalization failure returns 125 with the capture-error marker retained.
   The raw command status, if observed, remains in `.status` and Host.

The probes (§8.2) establish that these files are readable on the current direct
backend both before and after wrapper migration, before removal. The current
wrapper already reads `oom_kill`, but publishes it only in human banners. It
does **not** implement this sidecar or finalization protocol today.

A positive counter in an owned, configured direct group is the operational
RESOURCE/cap witness, even when the parent exits 0 or 1. It reports an OOM kill
in that group; it is not a proof about which limit in the host hierarchy caused
the kernel decision. A checked zero means no recorded OOM kill. Neither a bare
137 nor banner-shaped bytes supply that witness. A positive count survives a
later cleanup problem, but the latter still prevents accepting the capture.

The current systemd fallback does not expose a readable counter to this wrapper;
record null and a supervision issue, not zero. A missing cap backend in protocol
mode fails before launching the engine. Ordinary wrapper mode retains its
documented loud fallback. Public hosts can run the supported interface or an
explicitly permitted uncapped profile; no machine-specific paths or privileges
are added. This is capture ownership against program-data confusion, not
protection against another host process with the same privileges.

### 3.3 Deadlines and resource engine frames

Use GNU timeout's existing supervision with a wrapper-owned diagnostic stream:
`LC_ALL=C timeout --verbose --signal=TERM --kill-after=5s Ns ...`. The executed
child redirects its own stderr to `.stderr`; timeout's stderr goes to
`.host.stderr`. The finalizer admits its exact TERM/KILL deadline notification
for this invocation to set expired=yes. It does not set expired from the
command's status. Unexpected supervisor output or inability to determine expiry
sets unknown and an issue. A native exit 124 with no expiry is unexplained
termination. A timeout implementation lacking the required convention is a
setup error, not a silent change of evidence. The implementation must probe this
separation with native-exit-124 and sleeping-child controls before adoption.
The local convention probe (§8.2) used the fixed child entry `bash` and admitted
exactly `timeout: sending signal TERM to command 'bash'` (or KILL), plus LF.
The capture implementation fixes that entry name and admits no engine-supplied
command label as a second notification. It may preserve the separately recognized
`timeout: the monitored command dumped core` notice without treating it as expiry.

Timeout/hang subdivision is diagnostic only: when trusted timing exists, CPU/wall
< 0.1 means hang, otherwise timeout; without timing retain timeout and no subtype.
Neither label permits comparison. A confirmed OOM and confirmed deadline can
both be retained. Engine fuel/stack are decoded separately, by whole frames:

| Form | Required engine evidence and status absent a witnessed interruption |
|---|---|
| Fuel kill | A complete batch `Error {msg: "lem: fuel exhausted"}` record; normal single/multiple execution framing and status 1/0. |
| Bare fuel panic | First engine stderr line exactly `lem: fuel exhausted`, then the admitted optional backtrace (§4.1), with no other payload; empty stdout; status 134. |
| Translation fuel panic | Exact LemLib origin below, payload exactly `lem: fuel exhausted`, admitted trace; empty stdout; status 134. |
| Stack | Entire engine stderr `\nStack overflow detected. Aborting.\n`; empty stdout; status 134. |

The timeout core-dump notice and shell `Aborted` line seen in current captures
belong to `.host.stderr` in the new capture mode. They do not become part of a
program diagnostic, and neither is by itself resource evidence. Existing
merged legacy captures cannot acquire new trusted host evidence by stripping
banner-like lines out of their stderr.

The exact fuel Error is a reserved legacy value until WP1, with the same
sentinel/text limitations as §1.2. Other Error messages containing envelopes or
fuel words remain verdict data. Human-mode fuel lines are decoded only by their
explicit legacy interface, not admitted as batch output. Stack classification
ships here; repairing stack consumption remains the stack-ceiling mission.

## 4. Whole-run classification and consumer API

### 4.1 Channel admission

Set `NO_COLOR=1`, `TERM=dumb` for engine invocations. Raw ANSI escape or NUL in
protocol framing is an encoding problem, not normalized away. Encoded control
bytes in data fields remain data. Positive host evidence is collected independently
of engine parsing; it does not bypass that parsing.

| Channel | Engine stdout / engine stderr | Status and allowed stop classes |
|---|---|---|
| CLI | Empty / a nonempty list of envelope lines, each validated | 2; all REFUSAL, or exactly one INVARIANT. |
| Panic | Empty / one exact LemLib panic frame and its trace | 134; REFUSAL, UPSTREAM_CRASH or INVARIANT. An absent envelope gives legacy/unattributed, not SHARED_CRASH. |
| ModelFailure | Batch records / ordinary diagnostic text subject to the exclusions below | 1 for a single ModelFailure, 0 for framed multiple executions; only UPSTREAM_CRASH or INVARIANT in each ModelFailure. |
| Verdict/fuel kill | Batch records / ordinary diagnostic text subject to the exclusions below | Existing single Defined=0, single other=1, multiple=0 convention. Exact fuel is a resource cause; ordinary records are data. |
| Bare fuel/stack | The exact whole engine frame in §3.3 | 134; RESOURCE only. |
| Host interruption | May leave a partial engine stream | Positive cap/deadline metadata; status alone never supplies the cause. |

Panic header is exactly `PANIC at _private.LemLib.0.failwithIImpl
LemLib:<line>:<column>: <payload>` on **one line**, with positive decimal source
coordinates. The mangled origin is pinned to the current LemLib; another origin
is RED until reviewed. A new encoded payload is exactly one physical line.
Its suffix is either empty (header-only fixture) or `backtrace:` followed by one
or more frames matching the existing full-line expression
`[^\r\n]+\([^()\r\n]*\) \[0x[0-9a-fA-F]+\]`, each LF-terminated.
There are no arbitrary continuation lines or wrapper lines in a v2 encoded
panic. For a legacy panic, the payload starts on the header line and may continue
up to a line exactly `backtrace:`. If that delimiter occurs, all following lines
must be one or more complete frames of the expression above; a second delimiter
or trailing material is invalid. If it does not occur, all continuation lines
are payload. Remove only the printer's final LF, not payload blank lines.
Continuation lines starting with `PANIC at `, `cerberus-lean stop`, `capped:`,
`internal error: ` or `Fatal error: exception `, or equal to a bare fuel/stack
marker, make that legacy capture ambiguous and invalid. They cannot be harvested
as additional trusted causes. The raw legacy payload is retained as bytes.

Batch framing retains the present grammar: one unheaded record, or contiguous
`EXECUTION 0:`, `EXECUTION 1:`, … with one record per header and at least two
executions; the existing optional header exit annotation remains permitted.
No missing, duplicate or skipped header, missing record or extra record is ignored.
ModelFailure outer escapes are validated before decoding. Ordinary Error and
program-data fields are not scanned after decoding for envelope prefixes.
The existing ordinary batch grammar remains its admission boundary; arbitrary
legacy unescaped diagnostic bytes do not gain a new authenticity guarantee.

Nonempty ordinary stderr is preserved, but a raw reserved stop line, fatal
frame, bare resource marker, ANSI framing or malformed stop beside a verdict is
RED. A raw cap banner on engine stderr is never a cap witness; it is unexpected
wrapper-shaped diagnostic material. The complete stdout/stderr pair is checked
before completed-observation comparison. Calling today's `parse` or
`failure_message` and returning early is insufficient.

### 4.2 Algorithm, partial observations and report schema

1. Validate capture ownership, files and Host; retain any independently obtained
   positive resource evidence and all problems. Never infer a missing counter.
2. Parse every complete engine record and diagnostic frame. In stop positions,
   distinguish absent envelope from malformed reserved prefix. Decode all
   constructors, fields, classes and channels; collect every cause, with its
   execution index when present. An ordinary Error payload is never a stop position.
3. Check the whole capture's framing, status and channel compatibility. A
   confirmed host interruption may override the normal final status and leave
   a terminal partial record; retain that prefix as raw evidence, mark incomplete,
   and never synthesize its missing fields. Only an EOF truncation consistent
   with that interruption is excused. A complete malformed record, wrong channel
   or invalid escape preceding EOF is still a problem. A normal exit with a
   truncated record is invalid. No resource removes a prior invariant/problem.
4. Complete means: valid capture, ordinary completed batch only, no causes or
   problems, and matching status. Any problem makes the report invalid; otherwise
   any stop/resource/legacy panic makes it incomplete. Only complete can produce
   the existing comparable `Observation`. No projection can bypass this check.

Python `classify_capture(prefix) -> RunReport` returns all evidence. Classification
is separate from lane disposition. Lean `CerbStop.parse` only decodes a stop
payload; it does not classify a process or prove producer identity.

The machine CLI is `python3 scripts/observations.py classify --capture <prefix>`.
It prints one JSON report line, carrying the same information as RunReport:

```text
Report = ["cerberus-outcome","1",completion,status,records,causes,problems,raw]
Record = [index,kind,fields]
Cause = [kind,channel,index,payload]
Problem = [code,channel,index,detail]
Raw = [stdout_b64,stderr_b64,host_stderr_b64,host_json_b64]
```

Completion is `complete`, `incomplete` or `invalid`; status is NatText 0–255 or
null if unobserved. Record index is NatText (unheaded singleton is `"0"`). Kind
and fields are exactly: Defined → `[value_b64,stdout_b64,stderr_b64,blocked]`,
Undefined → `[ub_b64,stderr_b64,loc_b64]`, Error → `[msg_b64]`, ModelFailure →
`[msg_b64]`. Blocked is `"true"` or `"false"`. These are the codec's existing
field bytes, not newly normalized semantic values. The exact fuel Error remains
in records and also produces a cause. A decoded ModelFailure likewise remains
in records; its Stop is in causes. CLI/panic stops have no batch Record.

Cause kind is `stop`, `legacy-panic`, or `resource`. Channel is `cli`, `panic`,
`model-failure`, `fuel-kill`, `fuel-panic`, `stack`, or `host`; index is NatText
for a batch record and otherwise null. Payload is respectively Stop, B64 legacy
message, or one of `["fuel","kill"]`, `["fuel","bare-panic"]`,
`["fuel","translation-panic"]`, `["stack"]`, `["cap",Cap]`,
`["timeout",Deadline,Timing,subtype]`. Subtype is `hang`, `timeout` or null.
These kind/channel combinations must match §4.1; RESOURCE/SHARED_CRASH written
inside a Stop tuple is a schema error, not a fallback.

Problem code is `capture`, `encoding`, `schema`, `channel`, `framing`, `status`,
`origin`, `supervision` or `unexplained-termination`. Channel is any Cause channel
or `stdout`, `stderr`, `capture`; index is NatText or null; detail is Nonempty.
Raw fields are B64 or null if the corresponding file is missing. Complete
reports require all four. Nonconforming metadata is preserved raw rather than
replaced with invented parsed values. Causes are decoded evidence, not permission
to ignore accompanying problems. Record order is execution order; causes are
ordered batch-index first, then stderr order, then cap and deadline; duplicates
remain. Problems are ordered by the validation phases above and source order.
No total temporal order between independent stdout/stderr/host events is claimed.

CLI exit 0 means a valid complete/incomplete report was emitted, **not agreement**;
exit 2 means invalid report, capture/usage/I/O error. Emit the invalid report when
a capture can be described; human error explanations go to stderr. An INVARIANT
can occur in an otherwise valid incomplete report: lanes must inspect its causes.
They must never use classifier exit 0 as the test verdict. Human summaries are
separate renderings; they do not replace the lossless API.

### 4.3 Lane policy

| Report content | Required disposition |
|---|---|
| Complete ordinary verdicts | Existing byte/UB/allowed projection comparison, unchanged. Ordinary Error/Error BOTH_FAIL rules stay specific to ordinary errors. |
| Any INVARIANT, or any protocol/supervision problem | RED. No expected-crash pin or oracle crash absorbs it. |
| REFUSAL only | Incomplete. A named registered refusal policy may accept the expected boundary/item; `.unsupported.c` alone cannot. |
| UPSTREAM_CRASH only | Incomplete. A reviewed crash policy may account for the cited mirrored failure; it never counts as semantic agreement. |
| Legacy panic only | Incomplete, origin unattributed. Existing reviewed coarse negative-test crash pins may remain with that explicit limitation; no automatic shared-model attribution or new expected crash. |
| RESOURCE | Incomplete. Apply only the lane's explicit resource direction rule; never project it to an ordinary crash or verdict. Lean resource against a completing oracle is RED where that is the existing rule. |
| Mixed non-defect causes | All remain visible; default RED unless the lane explicitly registers that entire allowed combination. A single accepted member does not admit the collection. |

PNVI must not map INVARIANT to CRASH/BOTH_FAIL. Immaculate must not accept every
STOP against an oracle CRASH: resource is not a matching crash. Existing pins
and hashes move only deliberately, with row-level explanations; zero label/status
movement is not promised. Unexpected semantic verdict movement stops the slice
for investigation. Oracle decoding retains its separate OCaml grammar; a Lean
envelope is not a new syntax for the oracle to emit.

Acceptance applies to the entire cause collection, including multiple members
of the same class. Matching one expected refusal or one upstream citation never
licenses additional unchecked items. Preserve order and multiplicity in the
report even where a documented lane policy compares a set of expected items.

## 5. Delivery, consumers and required checks

One implementation branch, coherent internal commits, one complete first
consumer-facing landing. A–E are work checkpoints, not new trust gates:

| Checkpoint | Deliverable |
|---|---|
| A | Review v2, settle §6, reconcile the charter/file fence and inventory dispositions. Probe the new capture separation and timeout convention before relying on them. |
| B | Structured builder/codec, full RunReport classifier and capture metadata; positive and negative plants. No production lane claims based on partial adoption. |
| C | Nine typed kills; existing pure/monadic refusals and driver admissions; the remaining hand-written pure mirrors/guards and twelve config-dead switch kills. Update their immediate tests/wrappers in the same commits. |
| D | All declared lane callers use the common classification entry and §4.3 policy. Reseal register keys, deliberately update affected baselines and complete the standing ladder obligations. |
| E | Consumer-shaped demonstrations, honest limits table, independent review, and a tested candidate for the operator's landing decision. |

The file fence must include CerbStop and tests, Lake roots/executable registration,
`handwritten_copy.manifest`, affected seams and Main, `MonadicFailstop.lean`'s
seven old message pins, `PnviArmsTest.lean`, the three CLI witness scripts and
stubs, `capped`, `observations.py`/`.sh`, `common.sh`, fuel/cap/hang/failstop plants,
`test_observation_lanes.py`, `pnvi_lane.py`, exec/immaculate and the other actual
direct classification callers. Existing shell fuel/cap interfaces become
adapters to the common report; merged-text helpers remain only explicitly named
legacy/test interfaces, not competing production acceptance rules.

Do not assume the old five-site usage census is complete. At this source base,
Main has seven explicit exit-1 admission branches: missing parse-core switch
argument (1496), missing option argument (1613), call-args without call (1678),
bad call integer (1690), libc without a metadata TU (1696), libc-TU without libc
(1701), and batch/pp-core without input (1759). The empty-input exception in
`readInputs` (335) must reach the same attributed usage handling, not remain an
uncaught exception. Repeated-option exit-2 paths also need envelopes. Parser
failures and actual semantic Error exits are not usage branches. Migrating these
usage branches to exit 2 is an explicit behavior change. Switch refusals retain
one envelope per rejected element, including empty/duplicate elements, then one
exit; test both `--switches=x` and `--switches x`.

The live register has 239 rows: 111 hand-written and 128 generated. Migrate/reseal
the 35 existing-refusal keys and remaining 76 hand-written keys with old-to-new
mappings; a site count is not a key count. Recompute position/reach evidence if
the rewrite changes it; no automatic preservation promise. Keep the optional
message-convention report a cheap speedbump. Generated copies are synchronized
by the normal build procedure, not edited manually. A `common.sh` edit requires
the documented reviewed source-content row update in `fork_drift_manifest.txt`,
not a blanket refresh or an oracle semantic change.

Tests must include JSON/control/Unicode round trips and the nested escaping;
object/duplicate/unknown-version/arity rejection; diagnostic marker injection;
every class/channel mismatch; multiple ModelFailures and CLI refusals; a good
record followed by malformed output; terminal truncation under a real resource
interruption; INVARIANT plus resource; native 137/SIGKILL without OOM; descendant
OOM at parent 0/1; forged engine banners; missing/stale metadata; native 124 vs
actual timeout; all fuel forms and measured stack framing. Update the actual
positive ModelFailure observation-lane plant to a valid envelope and keep the
old envelope-less one as a separate negative. Use these test families, not an
exhaustive string × channel × status matrix or a new certification runner.

The existing Tier A/B schedule in `scripts/LADDER.md` remains the validation
schedule for implementation. Changed proof declarations require the standing
axiom and kernel-replay checks. All Lake/Lean work uses `scripts/capped`; this
design's Lean probes used `CERB_MEM_MAX=32G`. No build or release certification
was run for this document. Scratch belongs under `.tmp/`; commit conclusions
and reproduction commands, not raw dumps.

At the first complete delivery, consumer-visible families are:

| Family | First complete delivery |
|---|---|
| CerbFS/PNVI/formatFixed and driver refusals | REFUSAL with boundary/item/mover. |
| Hand-written pure upstream mirrors and mirrored typed kills | UPSTREAM_CRASH with source/tray metadata. |
| Annotated port guards | INVARIANT; always a defect. |
| Generated/shared-model panics | Validated legacy panic, origin unattributed; audited examples may be described separately, not inferred from absence. |
| Fuel, stack, owned host interruption | RESOURCE from §3 evidence. |

Consumer source facts below are pinned to the accepted review's checks:
cerberus-caesium `32d88b8b3fd30aba8cd5b26bc009b3a0e5115f45` and cerberus-sl
`68832d914227a29c37df381d3e83ad274147e24c`. Recheck their actual heads and caller
inventory when demonstrating the implementation candidate.
Cerberus-caesium's binary-driver consumer there is `scripts/differential.py`;
`check-caesium-exec.sh` is a stepper harness and does not prove that decoder's
adoption. Demonstrate the report on each family plus mixed causes and supply the
consumer patch recipe. External consumer changes require their own authorized
task; do not claim adoption from the existence of a provider function.
Cerberus-sl must see diagnostic parsing separately from semantic interpretation;
recheck its fuel/OOM aliases and three-arm kill lift without claiming a sentinel
disjointness theorem. Intermediate B/C commits are incomplete foundations, not
an accurate replacement mapping for all the consumer's families.

## 6. Questions for dispatch, with recommendations

The operational-versus-structural ordering is already settled in the ruling at
the start of this note. The table restates every original §6 question in the
revised context; recommendations are not additional operator rulings.

| ID / question | Recommendation |
|---|---|
| Q1 — Names and attribution | **[AGENT]** Keep REFUSAL, UPSTREAM_CRASH and INVARIANT as emitted stop tags; RESOURCE is evidence-derived. Report envelope-less panic as legacy/unattributed. Do not equate it with a diagnosed semantics failure or SHARED_CRASH. A future attributed shared producer needs an explicit schema revision. |
| Q2 — Allocator OOM | **[AGENT]** Preserve the semantic Error/Other kill and consumer alias. Keep it distinct from cgroup OOM evidence. |
| Q3 — Usage errors | **[AGENT]** Migrate all enumerated admission paths, including the additional live paths in §5, to attributed exit-2 refusals. Disclose the exit change; keep parser/semantic errors separate. |
| Q4 — Config-dead switch kills | **[AGENT]** Use the existing memM panic mechanism with a structured switches refusal. State the abort-setting requirement for library callers; Main's deadness argument does not cover arbitrary Switches instances. |
| Q5 — Thirteen boundaries | **[AGENT]** Adopt §2's wire enumeration; do not silently enlarge the queued semantic Unsupported enumeration. Charter its mapping at WP2. |
| Q6 — Q-A sweep and disputed arms | **[AGENT]** Annotate all hand-written mirror/guard sites before first complete delivery, including unreachable ones. Retain the print-then-kill and defined arms under the mirror policy unless separately ruled; settle their inventory dispositions before C. |
| Q7 — Unsupported fixtures | **[AGENT]** Require an actual admitted REFUSAL and the expected boundary/item. A suffix cannot excuse a mirror, invariant or resource failure. |
| Q8 — Register convention check | **[AGENT]** Add a small nonblocking lexical report on the registered hand-written population, with one negative control. It is not producer authentication or a census of all host/driver failures. |
| Q9 — Stack | **[AGENT]** Ship the measured stack classifier in this mission; leave recursion repair to the stack-ceiling work. A bare 134 or stack-shaped substring is insufficient. |
| Q10 — Trays | **[AGENT]** Cite existing reports, update existing drafts such as bswap64's draft 12 as needed, and draft missing offsetof-union-member/funptr_reload reports. Use explicit none/pending/draft/filed state. Filing is separately authorized. |
| Q11 — CLI invariant exit | **[AGENT]** Retain exit 2. The constructor and whole capture distinguish the class; another status would not authenticate it. |
| Q12 — Run aggregation and lane dispositions | **[AGENT]** Adopt §§4.2–4.3. Preserve every cause, make invariants/problems RED, and require explicit policy for mixtures. Never use first match or a coarse CRASH projection as the stop decision. |
| Q13 — Capture scope and portability | **[AGENT]** Include §3's sidecar and stream-separation changes in the charter, with explicit unavailable-evidence behavior. The old text banner cannot be the machine witness. Preserve the ordinary build-wrapper interface. |
| Q14 — Delivery boundary | **[AGENT]** Deliver B–D together to consumers, with all hand-written migrations, explicit legacy limits and the real integration target. Replace the S1–S2-only charter before dispatch. |

The frozen schema is the proposed answer for this review; implementers must not
choose object/array shape, optional fields or unknown-version policy afresh.
Any change after review is a design amendment with updated fixtures. No standing
working-practice rule is amended by this document.

## 7. Resolution of the twelve review findings

| Finding | Where v2 settles it |
|---|---|
| 1 — Ambiguous fields and injected resource markers | §§2.1–2.2 freeze an injective positional schema and escaping; §3 separates host evidence; §§4.1–4.2 forbid searches inside payloads and validate all channels. §5 requires diagnostic-interpolation controls. |
| 2 — Forgeable ModelFailure attribution | §1.2 states the concrete sentinel collision and restricts the claim under the adopted operational ruling. Structural outcomes remain the named mover; no new opaque atom or authenticity claim is introduced. |
| 3 — Exit 137 is not OOM | §§3.1–3.2 require an owned positive counter, including descendant OOM at parent success; zero/unavailable are distinct. Native 137 is tested in §8.2. |
| 4 — First-match rules bypass malformed/channel checks | §§4.1–4.2 require complete capture admission, distinguish malformed from absent, reject forbidden constructors/boundaries and retain Error payloads as data. No early successful verdict return. |
| 5 — More than one ModelFailure/cause | §4.2 defines indexed record/cause collections and complete/incomplete/invalid; §4.3 defines mixtures. No scalar Stop wins. |
| 6 — Coarse lane projections conceal invariant/resource | §4.3 explicitly forbids those PNVI/immaculate projections and requires reviewed row movement. |
| 7 — Missing migration work | §5 budgets the seven MonadicFailstop pins, PNVI/CLI witnesses and both positive/new-envelope and negative/old-envelope observation plants, alongside capture/caller changes. |
| 8 — Multi-line CLI and usage exit contradiction | §§2.3/4.1 specify nonempty collections and one terminating exit; §5 lists the live usage paths and the deliberate 1→2 change. |
| 9 — Stale fuel/stack forms and competing delivery | §3.3 specifies translation panic, leading stack LF and separate wrapper diagnostics; §5/Q9 place stack classification here. §8.3 remeasures both. |
| 10 — Premature or false consumer attribution | §§1.1/5 remove the shared fallback, name the real Caesium decoder and require a complete first delivery. The family table includes refusals and generated legacy panics accurately. |
| 11 — Lossy classifier CLI | §4.2 freezes a lossless machine report with full Stop metadata, raw bytes, all causes/problems and explicit CLI status semantics. |
| 12 — String-only adapters cannot support WP2 | §2.3 carries structured Boundary/origin metadata to adapters and names the later Lem mapping/type work, without claiming a body-only signature-preserving conversion. |

V1 §8's three corrections are subsumed respectively by findings 3, 4 and 10.
That confirms their substance without treating the errata as the new specification.

## 8. Measurements and reproducible probes

These probes used the existing build; no production source was modified. Raw
captures and scratch sources were removed after this record was written. They
do not certify the proposed codec or sidecar, which are not implemented.

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
