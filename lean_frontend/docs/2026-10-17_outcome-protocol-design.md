# Outcome protocol — design note (2026-10-17)

**Status: DESIGN NOTE for the operator. It decides nothing and implements nothing.** Branch
`design/outcome-protocol-20261017` over mainline `f5303eda5`. Author: the design worker [AGENT]. No build, lane, lake,
dune or driver run was made; every count is DERIVED from the committed inventory unless marked MEASURED (a read-only
`grep` at `f5303eda5`, listed in §7). The question is Q-B of the stop-paths inventory
(`docs/2026-10-08_stop-paths-inventory.md`, hereafter INV), scoped by the operator to the inventory's option 3 ([USER
2026-10-17]: a protocol, not a mechanism). Prior art is taken as decided, not re-derived: the 2026-09-16 scoping note R1
(`Stopped of interp_stop`, hereafter R1) and its implementation plan (WP-O → WP0 → S1-pre → WP1 → WP2), the C-TF1
record, the PNVI design §G/§H, the CerbFS records and CONTRACT §1.

## 0. Summary

- Today's 16 outcome kinds on four wire shapes (INV §4) conflate two different things: the **channel** a stop leaves
  by (a pure `failwithI` panic, a monadic typed kill, the driver's exit 2, a verdict-shaped kill) and the **class** of
  what stopped (a refusal, a mirrored upstream crash, a port invariant, a resource limit). Channels are fixed by the
  mechanism and by what consumers name; classes are what a consumer needs and what nothing names today.
- The protocol therefore puts the CLASS into the message as a fixed **envelope**, carried unchanged on every channel,
  built by ONE seam (`CerbStop.lean`, §2) and read by ONE classifier (`observations.classify`, §3). Exit codes and
  record shapes do not change (§1.2); the class set is five stop classes + VERDICT (§1.1); the envelope grammar is §1.3.
- The 128 generated-tree `failwith` rows (shared `.lem`, both engines) stay as they are and classify as the one
  envelope-less class, `SHARED_CRASH` (§1.1); pure sites keep `failwithI` as their leaf (the census recognises only that
  head — `scripts/failure_census.py:84`), so the helper is a message builder, not a new leaf (§2).
- Migration is four slices (§4): the seam + classifier + the 9 typed-kill sites; the 37 existing refusals + the CLI;
  the Q-A sweep (76 pure rows + the 12 config-dead switch kills); the lane label split and one immaculate re-record.
  Two register re-seals, zero class movement anywhere, zero change to the five consumer-relied items.
- R1's `Stopped of interp_stop` later replaces the CHANNEL for monadic sites without touching the class set: RESOURCE/
  fuel ↔ `Exhausted`, REFUSAL ↔ `Unsupported`, UPSTREAM_CRASH and INVARIANT ↔ `FailStop` (§5; one recommendation for WP2).
- Open questions: 11 (§6), each with a recommendation.

## 1. The protocol

### 1.1 Classes

A run ends in a VERDICT or in exactly one STOP class. Class names are the literal strings the envelope and the
classifier use.

| Class | Definition | INV §4 kinds that map here | CONTRACT §1 |
|---|---|---|---|
| `VERDICT` | A `Defined`/`Undefined`/`Error` record the oracle also produces on this input class, including the semantics' own failures: front-end rejection and the inherited asm refusal (kind 3), the mirrored driver kills (16), the allocator's out-of-memory kill (10 — upstream's own `fail (MerrOther …)`, `impl_mem.ml:1291`/`:1296`, consumer-named `Interface.oomOutcome`). Not a stop; nothing changes. | 3, 10, 16 | (1) (or (4) where registered) |
| `REFUSAL` | A declared unsupported feature: the port stops BEFORE answering, naming the boundary (an enumeration, §2.1), the item inside it, and the mover. Never used for an upstream bug (that is `UPSTREAM_CRASH` with a tray cite). | 1, 2, 4, 5, 6, 11, 14 | (2) |
| `UPSTREAM_CRASH` | A hand-written mirror of an upstream `failwith` / `assert` / uncaught exception: both engines die on the input; the envelope cites the upstream site and quotes its text; a `tray` field marks the ones the fork believes wrong. | 7 (the 72 hand-written pure rows), 8 (the 7 typed kills that are mirrors) | (4)(a) |
| `SHARED_CRASH` | A `failwithI` of the SHARED lem model (the 128 generated rows): mirrored by construction (the fork-drift gate pins the generated OCaml), attributed by no envelope — the message is lem's own text. The brief's "semantics failure". Out of scope to migrate (the lem failure-monad arc, lem-lean TODO 24). | 7 (the generated rows) | (4)(a) |
| `INVARIANT` | A Lean-only guard fired: an invariant the port relies on and has not proved broke at run time. Never expected on any input; every occurrence is a finding (a port defect or an unproved invariant). The brief's "model failure". | 8 (`CerbMem.lean:2998`, `:3551`), 15, the 3 pure Lean-only guards of INV §3.3 | none — a defect by definition |
| `RESOURCE` | A limit of the executable, never a C behaviour and never agreement: fuel (kill or panic), the cgroup cap kill, timeout/hang, and the runtime's stack overflow (the consumer's item B, not in INV). Kinds: `fuel`, `cap`, `timeout`, `hang`, `stack`. | 9, 12, 13 (+ stack) | (3) / (b) |

Mapping to the brief's five names [AGENT]: mirrored upstream crash = `UPSTREAM_CRASH`; declared refusal = `REFUSAL`;
resource outcome = `RESOURCE`; model failure = `INVARIANT`; semantics failure = `SHARED_CRASH`. The allocator OOM is
NOT a resource stop: it is a verdict both engines give and the consumer names (§6 Q2).

### 1.2 Channels and the exit-code table

The channel is decided by the site's type (pure / monadic / `IO`) and by what consumers name; it is not a design
choice of this note. Every code below is the code of today (INV §4); the protocol changes none of them.

| Channel | Exit | Stream and shape | Classes admitted | Why this code |
|---|---|---|---|---|
| `cli` (driver admission, and the driver's own internal errors) | **2** | stderr: ONE envelope line; stdout empty | `REFUSAL`, `INVARIANT` | the port's admission convention since Z-24, pinned by three row-1 scripts and the PNVI lane's classifier; the driver chooses it |
| `panic` (a pure `failwithI`) | **134** | stderr: `PANIC at _private.LemLib.0.failwithIImpl <loc>: <envelope>` + the runtime's backtrace; stdout empty | `REFUSAL`, `UPSTREAM_CRASH`, `INVARIANT`; **no envelope = `SHARED_CRASH`** | SIGABRT under `LEAN_ABORT_ON_PANIC=1`: not chosen, not interceptable by `Main` (INV §5.3) |
| `model-failure` (a monadic typed kill) | **1** (single execution), **0** (multi) | stdout: `ModelFailure {msg: "<envelope, String.escaped>"}` | `UPSTREAM_CRASH`, `INVARIANT` (a `REFUSAL` here is RED until R1's `Unsupported` exists — INV §7 Q7) | the oracle's `runM` kill convention; the record is C-TF1's |
| `fuel-kill` / `fuel-panic` | **1**/**0** / **134** | stdout `Error {msg: "lem: fuel exhausted"}` / stderr bare `lem: fuel exhausted` | `RESOURCE/fuel` only | UNCHANGED: the text is the value of the consumer-named `CerbND.fuelExhaustedKill` (`CerbFuel.fuelExhaustedMsg`), and R1 plan R6 forbids a legacy decoder when WP1 replaces it |
| `host` | **137** / **124** | stderr capped banner (`scripts/cap_oom.regex`) / none | `RESOURCE/cap`, `/timeout`, `/hang` | the harness's, as today (`common.sh` `is_cap_kill`, `classify_exit124`) |
| `stack` | **134** | stderr: the Lean runtime's stack-overflow text, no `PANIC` line | `RESOURCE/stack` | the runtime's; the exact text is pinned from a measured run in S1 (§4.1) — this note has not run it |
| `verdict` | **0**/**1**/**0** | stdout records | `VERDICT` | the oracle's `runM` |

Two consequences the table fixes: a class may appear on several channels (a `REFUSAL` on `panic` from CerbFS, on
`cli` from `--concurrency`); a channel may carry several classes. The classifier reads the class from the envelope
head and the channel from (exit, stream); a class on a channel that does not admit it is RED (§3.5).

### 1.3 The envelope grammar

One line; the message string of whichever channel carries it. ASCII head, free-form tail.

```
envelope ::= "cerberus-lean stop " CLASS " " id ": " detail { " -- " field }
CLASS    ::= "REFUSAL" | "UPSTREAM_CRASH" | "INVARIANT"          -- the only spellable classes
id       ::= boundary [ "/" item ]                               -- REFUSAL: boundary ∈ the enumeration (§2.1)
           | site                                                -- UPSTREAM_CRASH, INVARIANT: the Lean definition
field    ::= "upstream: " file ":" lines                         -- UPSTREAM_CRASH: REQUIRED; REFUSAL of an upstream arm: present
           | "mover: " phrase                                    -- REFUSAL: REQUIRED (VALIDATION §1(c): the boundary and its mover)
           | "tray: " ( number | "none" | "pending" )            -- UPSTREAM_CRASH only: the fork believes upstream wrong
           | "see: " ref                                         -- a CONTRACT/VALIDATION/design citation
           | "text: " any-to-end-of-line                         -- the upstream text VERBATIM; always LAST
```

`SHARED_CRASH` and `RESOURCE` are never spelled in an envelope: the first is the ABSENCE of one on the panic channel,
the second is recognised by its fixed forms (§1.2). The separator ` -- ` occurs in none of the current message lines and nowhere in `impl_mem.ml` (MEASURED, §7:
zero hits in the register's rows, in `impl_mem.ml` and in `Main`'s refusal lines; the six in-code hits are trailing Lean
comments outside the strings); `text:` is last and greedy so
upstream text containing ` -- ` or `|` cannot break a field. The class and id are decided by the head alone; fields are
advisory to the classifier (a malformed field never changes the class).

Examples, one per class and channel:

```
cerberus-lean stop REFUSAL fs/open: open './secret.txt' oflag 0 mode none -- mover: a SibylFS-faithful filesystem model -- see: CONTRACT.md §3 (D2)
cerberus-lean stop REFUSAL pnvi/R-PNVI-07: case_ptrval on a Prov_symbolic concrete pointer -- upstream: impl_mem.ml:1858 -- mover: a PNVI-ae-udi model of calls through symbolic pointers -- see: docs/2026-10-04_pnvi-ae-udi-design.md §G.1 R11 -- text: | _ -> failwith "case_ptrval"
cerberus-lean stop REFUSAL cli/--concurrency: concurrency is not supported by this port (the oracle's own --concurrency is non-functional at b9aeedcb4) -- mover: the SC concurrency plan (SC-CONCURRENCY.md) -- see: VALIDATION.md Z-24
cerberus-lean stop REFUSAL switches/SW_strict_reads: strict reads reached CerbMem's load arm -- mover: the rm_unspecs Core pass and the switch's impl_mem.ml arms -- see: CONTRACT.md §2
cerberus-lean stop REFUSAL float-format/nan-fixed: printing a NaN with %f -- mover: a bit-level float representation (TODO.md, N2) -- see: CONTRACT.md §3
cerberus-lean stop UPSTREAM_CRASH CerbMem.arrayShiftPtrval: pure array_shift of a null pointer, offset 4 -- upstream: impl_mem.ml:2259-2261 -- tray: none -- text: failwith ("TODO(pure shift a null pointer should be undefined behaviour), offset:" ^ Nat_big_num.to_string n)
cerberus-lean stop UPSTREAM_CRASH CerbUtils.bswap64: argument >= 2^63 -- upstream: ocaml_gcc_builtins.ml:30 -- tray: 12 -- text: Z.to_int64 raises Z.Overflow
cerberus-lean stop UPSTREAM_CRASH CerbMem.memcmp: non-integer byte -- upstream: impl_mem.ml:2658-2659 -- tray: none -- text: assert false
cerberus-lean stop INVARIANT CerbMem.storeM: the allocation resolved for a Prov_symbolic store is absent -- see: CerbMemDefaultFacts.resolveIota_ok_of_shape (resolveIota's precondition found it)
cerberus-lean stop INVARIANT Main.judgeSwitches: refuseSwitches returned -- see: Main.lean judgeSwitches
```

The first and the sixth are the PANIC channel (`PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: cerberus-lean
stop REFUSAL fs/open: …`); the third and the last are `cli` (exit 2); the eighth is `ModelFailure {msg: "cerberus-lean
stop UPSTREAM_CRASH CerbMem.memcmp: …"}`. How the mover and boundary appear: `id` names the boundary (CONTRACT §3's
feature area) and the item; `mover:` names what would lift it, as every refusal already does in prose
(`CerbFS.lean:107`). How a mirrored site is cited: `upstream:` is `file:line(s)` of the fork oracle's source at the
merge-base, `text:` the OCaml verbatim — the mirror-OCaml doctrine kept in the message, not only in a comment.

### 1.4 What stays as it is

Every verdict line and its exit; the `ModelFailure` record name and exit; the fuel kill's and fuel panic's text (the
consumer-named value); `Interface.oomOutcome`'s text; the asm refusal's inherited verdict shape (INV §7 Q11: leave it;
`check_asm_refusal.sh` attests it); the oracle's shapes (the protocol is cerberus-lean's; the codec already decodes
upstream's `internal error` and uncaught-exception envelopes); `LEAN_ABORT_ON_PANIC` as the guard; the five
consumer-relied items of VALIDATION §3b (MEASURED in INV §5.4 and re-checked §7: cerberus-sl names no refusal text,
`failwithI`, `modelFailStopLoc` or `ModelFailure` in a theorem).

## 2. The helper — `CerbStop.lean`

A new leaf seam (imports `LemLib` only; a Lake root; a `handwritten_copy.manifest` entry; no `opaque`, no
`implemented_by`, no `IO.Ref`), imported by every seam that stops and by `Main`. The register census recognises exactly
the heads `failwithI`, `panic!`, `panic`, `panicCore` (`scripts/failure_census.py:84`), so the pure-site leaf STAYS
`failwithI` and the helper is the envelope BUILDER — the `fsRefusal`/`pnviRefusal` pattern made global — plus one
adapter per channel. "One helper every stop path goes through" = one builder; the channel adapters are thin.

### 2.1 Signatures

```lean
namespace CerbStop
/-- The REFUSAL boundaries. CLOSED: a new constructor is an operator ruling and a CONTRACT §3 row (§6 Q5).
    Becomes R1's `unsupported_feature` enumeration at WP2 (§5). -/
inductive Boundary
  | fs | pnvi | switches | concurrency | floatFormat          -- semantics boundaries
  | cli | runtime | libraryLocation | cabsJsonUtf8 | batchUbPayload | abortFlag | fuelArg | addressSpaceArg  -- admission
def Boundary.id : Boundary → String        -- "fs", "pnvi", "switches", "concurrency", "float-format", "cli", "runtime", …

structure Cite where                        -- the advisory fields, rendered in the fixed order of §1.3
  see  : Option String := none
  text : Option String := none

/-- The three spellable classes. Each builder is TOTAL and returns the envelope STRING; none can produce a value. -/
def refusal (b : Boundary) (item : Option String) (detail : String) (mover : String)
    (upstream : Option String := none) (c : Cite := {}) : String
def upstreamCrash (site : String) (detail : String) (upstream : String)    -- the cite is POSITIONAL: no mirror without it
    (tray : Tray := .unfiled) (c : Cite := {}) : String
def invariant (site : String) (detail : String) (see : String) : String

inductive Tray | unfiled | pending | n (k : Nat)      -- rendered `none` / `pending` / the number

/-- The channel adapters. -/
-- pure:    failwithI (CerbStop.refusal …)        -- at the site, verbatim: the census head stays `failwithI`
-- monadic: CerbMem.failStopMem (CerbStop.upstreamCrash …)   -- C-TF1's kill, unchanged
--          CerbMem.pnviRefuseM → CerbMem.refuseM (CerbStop.refusal …)   -- `failwithI` at `memM`, unchanged mechanism
def refuseIO {α} (b : Boundary) (item : Option String) (detail : String) (mover : String)
    (c : Cite := {}) : IO α          -- prints the envelope to stderr, `IO.Process.exit 2`
def invariantIO {α} (site : String) (detail : String) (see : String) : IO α   -- same, exit 2

/-- The in-process contract: the same grammar, parsed. Round-trip pinned by a unit exe (`render ∘ parse? = id`). -/
structure Stop where cls : String; id : String; detail : String; fields : List (String × String)
def parse? : String → Option Stop
end CerbStop
```

### 2.2 Routing

- **Pure sites** (the 111 hand-written register rows): `failwithI (CerbStop.<builder> …)` — the register key (file /
  owner / `failwithI` / first 60 chars of the message) moves once per site (a re-seal, classes unchanged — INV §7 Q10;
  shared keys lengthen automatically, `docs/2026-10-04_failure-reach-key-groups-record.md`). `fsRefusal` and
  `pnviRefusal` are deleted; the compile-time pins of `pnvi-arms-test` restate against `CerbStop.refusal .pnvi (some
  "R-PNVI-nn") …` (a plain `def`: the string still reduces).
- **Monadic sites** (9): the 7 mirrors become `failStopMem (CerbStop.upstreamCrash …)`; `CerbMem.lean:2998`/`:3551`
  become `failStopMem (CerbStop.invariant …)`; `pnviRefuseM` keeps its mechanism under the name `refuseM`. The 12
  config-dead switch kills (`kill (Other (MerrOther "… Z-24"))`, verdict-shaped if ever reached) become `refuseM
  (CerbStop.refusal .switches (some "SW_…") …)` — a `REFUSAL` on the panic channel, like R-PNVI-08/-10; config-dead, so
  zero observable movement (§6 Q4).
- **CLI and runtime refusals** (`Main.lean`: the 12 `refused —` sites, the `LEAN_ABORT_ON_PANIC` guard among them;
  2 `cannot be repeated` exit-2 sites; 5 usage errors at exit 1): all through `refuseIO` with the boundary (`cli`, `switches`,
  `runtime`, `libraryLocation`, `cabsJsonUtf8`, `batchUbPayload`, `abortFlag`, `fuelArg`, `addressSpaceArg`) and the
  flag or value as the item. The usage errors move from exit 1 to exit 2 (§6 Q3; nothing pins them — INV §4 kind 2).
  `refuseSwitches`' per-element loop prints one envelope per element, as now. The two internal errors
  (`Main.lean:1253`, `:1481`) become `invariantIO`.
- **Fuel, OOM, host**: untouched (§1.4).

### 2.3 What the helper must never do

- No default and no absorption: every builder returns a `String` only; the adapters are `failwithI`, a kill, or
  `exit 2`. There is no `String → α` in the seam. A site that wants a value does not go through it.
- No free class: the class is the builder's name; no builder takes a class string. `SHARED_CRASH` and `RESOURCE`
  have no builder (they are not spellable, §1.3), so no hand-written site can claim to be the shared model or a limit.
- No refusal without a mover, no mirror without an upstream cite (both positional); no `tray` on a refusal (the
  parameter does not exist there) — an upstream bug cannot be labelled "unsupported" (INV §3.10, the no-innovation rule
  [USER 2026-10-03] as recorded in the PNVI design §1.1).
- Mirror-OCaml doctrine kept: `upstream:`/`text:` carry the cite and the verbatim OCaml; a Lean paraphrase goes in
  `detail`, never in `text`.
- No fail-open at the boundary enumeration: `Boundary` is closed; `Boundary.id` is total by `match` with no wildcard.
- Nothing kernel-facing changes: `failwithI` stays opaque; the seven C-TF1 propagation theorems are uniform in the
  message; the boundary-opaque census (9 rows) is untouched; LemLib is not changed (the brief's rule).

## 3. The classifier — `scripts/observations.py`

### 3.1 Placement and output

One function beside `parse`, policy-free, plus one CLI action:

```python
@dataclass(frozen=True)
class Stop:
    cls: str        # REFUSAL | UPSTREAM_CRASH | SHARED_CRASH | INVARIANT | RESOURCE
    channel: str    # cli | panic | model-failure | fuel-kill | fuel-panic | cap | timeout | hang | stack
    id: str         # REFUSAL: boundary[/item]; *_CRASH, INVARIANT: site; RESOURCE: the kind; SHARED_CRASH: ''
    detail: bytes   # SHARED_CRASH: the whole lem message
    fields: dict[str, bytes]

def classify(stdout: bytes, stderr: bytes, status: int,
             cpu_wall: tuple[float, float] | None = None) -> Observation | Stop
# CLI: `observations.py classify --capture <prefix>` prints ONE line:
#   STOP <cls> <channel> <id>: <detail>      or      VERDICT <n> <tokens…>     (exit 0)
#   OBSERVATION ERROR: unclassifiable stop (…)                                  (exit 2, RED)
```

An `Observation` whose verdict list contains a `ModelFailure` is returned as the `Stop` of that record (a mixed batch is
INCOMPLETE regardless of exit status — the S0 protocol addendum's rule, adopted by R1.4); the lanes already refuse it as
agreement. `Stop` is never an `Observation`: no projection, no tokens, no comparison.

### 3.2 Decision procedure (ordered; the first rule that fires decides; none firing is RED)

1. `CAP_OOM` matches stderr, or status 137 → `RESOURCE/cap`.  (as `parse` today)
2. status 124 → `RESOURCE/timeout`; `/hang` iff `cpu_wall` is given and cpu/wall < 0.1 (`common.sh classify_exit124`'s rule; without the record the classifier says `timeout` and the shell keeps its own HANG split).
3. `FUEL_RECORD` matches stdout+stderr (the existing exact forms) → `RESOURCE/fuel`, channel `fuel-kill` (status 1/0, stdout) or `fuel-panic` (status 134, stderr). Precedence over every envelope, as today.
4. status 2: stdout must be empty and stderr's FIRST line an envelope with CLASS ∈ {REFUSAL, INVARIANT} → that class, channel `cli`. Any other status-2 capture → RED.
5. status 134: stdout must be empty. stderr's first line is `LEAN_PANIC` with the LemLib origin (`LEMLIB_FAILWITHI_ORIGIN`; any other origin → RED, as today): the message parses as an envelope with CLASS ∈ {REFUSAL, UPSTREAM_CRASH, INVARIANT} → that class; no envelope → `SHARED_CRASH` with the message. The backtrace envelope is validated exactly as `failure_message` does now. stderr's first line is the pinned stack-overflow text → `RESOURCE/stack`. Anything else at 134 → RED.
6. status 0/1: `parse(stdout, stderr, status, 'model-failure')` succeeds. If a `ModelFailure` record is present: its unescaped `msg` must be an envelope with CLASS ∈ {UPSTREAM_CRASH, INVARIANT} → that class, channel `model-failure`; no envelope or another class → RED. Otherwise → the `Observation` (`VERDICT`).
7. Everything else (a `PANIC` beside verdicts, styled stderr, status 139, an envelope inside an `Error {msg}` line — never read as a stop, see §3.5) → RED (`ProtocolError`).

The envelope parser: `^cerberus-lean stop (REFUSAL|UPSTREAM_CRASH|INVARIANT) (\S+): (.*)$` on the head; the tail is
split on ` -- ` left to right into `key: value` pairs, `text` taking the rest of the line; an unknown key or a required
field missing (`mover` on REFUSAL, `upstream` on UPSTREAM_CRASH) is reported in `fields['_malformed']` and does NOT
change the class (the head decides); the lanes may make it RED (the immaculate lane should: §3.3).

### 3.3 Lane adoption

| Lane / script | Today | Under the protocol | Rows that move |
|---|---|---|---|
| `scripts/pnvi_lane.py` `classify_side` (Lean side) | `REFUSAL_PREFIX` + `REFUSAL_ID` text rules; `CRASH <msg>` otherwise | a wrapper over `classify`: `REFUSAL` with boundary `pnvi` → `('REFUSAL', item)`; `REFUSAL` with another boundary → `('REFUSAL_OTHER', id)` (DIFF — no row has one, MEASURED); `UPSTREAM_CRASH`/`SHARED_CRASH`/`INVARIANT` → `('CRASH', msg)` as now; `RESOURCE` → as now; the oracle side unchanged | none: `REFUSAL` rows do not pin the Lean side; the 2 `BOTH_FAIL` rows are Error/Error (MEASURED); `097-null-ptr-arith` is `AGREE` under the switch (MEASURED), contrary to INV §3.10's guess |
| `scripts/test_immaculate.sh` `verdict()`/`classify()` | codec `--policy immaculate`; `INTERNAL_ERROR`/`MODEL_FAILURE` → token `CRASH`; status `MATCH` iff tokens equal | the Lean token becomes `STOP:<cls>[:<id>]` (`STOP:REFUSAL:fs/open`, `STOP:UPSTREAM_CRASH:CerbMem.memcmp`, `STOP:SHARED_CRASH`, `STOP:INVARIANT:…`); the STATUS rule treats every `STOP:*` as the coarse crash class against the oracle's `CRASH` (MATCH stays MATCH, DIFF stays DIFF — INV §7 Q12, label-only); a malformed envelope is `INVALID` | the 24 `L=CRASH` rows (18 MATCH + 6 DIFF, MEASURED) change LABEL in one re-record; the 7 `ORACLE_CRASH` rows carry Lean verdicts and do not move; status column unchanged everywhere |
| `scripts/test_exec.sh` (+ the lanes that inherit it: csmith, ci sweep, cn, gcc) | `LEAN_CRASH`/`UNSUPPORTED`/`FAIL`/`LEAN_ERROR`/`FUEL` by exit + first `PANIC` line | statuses unchanged; the log line names the class; `UNSUPPORTED` on a `.unsupported.c` file requires class `REFUSAL` (a mirrored crash on such a file is `LEAN_CRASH`) — §6 Q7 | none: the 2 coverage `UNSUPPORTED` rows are `formatFixed` refusals (MEASURED); the 21 gcc `SKIP_LEAN_CRASH` rows are status tokens |
| `check_cli_refusals.sh`, `check_runtime_resolution.sh`, `check_cabs_json_utf8.sh` (+ their `--selftest` stubs) | pin `cerberus-lean: refused — <flag>:` (24 / 9 / 3 pins by the scripts' own tallies, derived; 12 producer sites in `Main`, MEASURED) | pin `cerberus-lean stop REFUSAL cli/<flag>:` (`runtime/`, `library-location/`, `cabs-json-utf8/`); the `cannot be repeated` and the `--fuel`/`--address-space-top` refusals likewise | text pins only; no baseline |
| `check_asm_refusal.sh`, the fuel/kill/hang/failstop plants, `test_observation_lanes.py` | — | unchanged (verdict shape, RESOURCE forms, `ModelFailure` acceptance are all untouched); the failstop plant's stub message gains an envelope only when `test_exec.sh` adopts `classify` (S4) | none |
| `scripts/check_failure_reach.py` | the register gate | at S3's end, one speedbump rule: every `lean_frontend/*.lean` row's message begins with `(CerbStop.` — one regex over rows it already parses, one plant; a bare string at a hand-written site would otherwise be read as `SHARED_CRASH` by every consumer (§6 Q8) | two re-seals (S2, S3), classes unchanged |
| `observations.py` `refusal(prefix)` / `--refusal-prefix 'model refused: '` | the concurrency prototype's vestige; consumers: its own 3 unit tests only (MEASURED: the CN lane's "refusal" is its REJECT class, not this action) | DELETED in S1; D2 R0 §1 named it the thing to replace | none |

### 3.4 How a consumer uses it

- **A harness that runs the binary** (cerberus-caesium's W3 shape): `python3 scripts/observations.py classify --capture
  <prefix>` (or `import observations; observations.classify(out, err, rc)`) on every run; the one-line answer sorts the
  consumer's items as follows (their note §A–§D): A1, A2, A6, A7 → `UPSTREAM_CRASH` with the `impl_mem.ml`/`decode.ml`
  cite in the line (A1's ask to report UB instead is a semantics change the no-innovation rule excludes; the class says
  whose crash it is); A3, A4, C → `SHARED_CRASH` (the shared model's own `failwith`: lem text, both engines, no cite until
  the failure-monad arc); A5 → `SHARED_CRASH` (`Formatted`), `UPSTREAM_CRASH` (`truncToInt`), `REFUSAL float-format`
  (`formatFixed`); B → `RESOURCE/stack` once the text is pinned (until then RED, which is the honest state); D →
  `UPSTREAM_CRASH CerbMem.memcmp` on the `model-failure` channel.
- **A consumer that runs the semantics in-process** (cerberus-caesium's harness exe, cerberus-sl): a kill `Error0
  CerbFail.modelFailStopLoc msg` is read with `CerbStop.parse? msg` (the same grammar, §2.1); a pure stop is still the
  process abort (INV §5.3's honest caveat: nothing in-process sees a pure `failwithI` until the lem failure-monad arc).
- Neither needs the message prefixes of today: `CerbFS refusal (…)`, `PNVI_ae_udi refusal (…)`, `…: refused — `,
  `cerberus-lean: refused — ` all disappear.

### 3.5 Plants (hermetic, `scripts/test_observations.py`, Tier A row 1 via `test_unit.sh`)

Each forged in every other shape; the matrix is the acceptance list of S1.

- Positive, one per (class, channel) cell of §1.2: `REFUSAL`/`cli`, `INVARIANT`/`cli`, `REFUSAL`/`panic`,
  `UPSTREAM_CRASH`/`panic`, `INVARIANT`/`panic`, envelope-less/`panic` → `SHARED_CRASH`, `UPSTREAM_CRASH`/`model-failure`,
  `INVARIANT`/`model-failure`, `RESOURCE` × {fuel-kill, fuel-panic, cap, timeout, hang (cpu/wall 0.01), stack}, `VERDICT`
  (single and multi-execution).
- Class on a channel that does not admit it → RED: `UPSTREAM_CRASH` on `cli`; `REFUSAL` inside `ModelFailure`;
  envelope-less `ModelFailure`; an envelope whose CLASS is `RESOURCE` or `SHARED_CRASH` (unspellable) on any channel.
- Forgeries from program data → `VERDICT`, never a stop: the envelope inside `Defined {… stderr: "…"}`; the envelope as
  an `Error {msg: "cerberus-lean stop REFUSAL …"}` line (an ordinary kill stays ordinary — the Error channel never
  carries stops; the fuel precedent, R1 plan R6); the fuel line inside a `Defined` stdout field.
- Channel forgeries → RED: a `PANIC` with a non-LemLib origin carrying a perfect envelope; a `PANIC` beside a verdict;
  an envelope on stderr at exit 1; a `PANIC` line at exit 2; `ModelFailure` at exit 0 in a single execution; stdout
  beside a 134; styled (ANSI) stderr; status 139; a bare 134 with neither `PANIC`, fuel nor the stack text.
- Precedence: fuel beats an envelope on the same capture; cap beats everything.
- Grammar: a malformed field keeps the class (head decides) and sets `_malformed`; `text:` containing ` -- ` and `|`
  round-trips; `tray: 12`, `tray: none`, `tray: pending`; the ` -- ` separator inside `detail` (authored text) does not
  move the class; `CerbStop.parse? (render x) = some x` for every builder (the Lean unit exe).
- Lane-level: the existing `test_failstop_plant.sh`/`test_fuel_plant.sh` stay; `test_immaculate.sh` gets one plant: a
  hand-written-looking bare-string panic must read `STOP:SHARED_CRASH` (so the transitional misattribution of §4.1 is
  visible, not hidden).

## 4. Migration

### 4.1 Slices, in order, with prices (estimates [AGENT]; no build was run)

| Slice | Content | Price | Gate at exit |
|---|---|---|---|
| **S1 — the protocol core** | `CerbStop.lean` (+ manifest, Lake root, unit exe `stop-envelope-test` for the round trip); `observations.classify` + CLI action + the §3.5 plants; delete the `refusal` action; the 9 `model-failure` producers (7 → `upstreamCrash`, 2 → `invariant`); the stack-overflow text measured on the consumer's `while(1){}` witness and pinned; CONTRACT §1 gains one sentence (the classes), VALIDATION §1(a)/(c) one line each | ~120 lines Lean, ~150 lines Python, ~40 plants, 9 site edits, 1 measured run | Tier A; `test_observations.py` 25 + ~40; zero baseline movement (immaculate's two `ModelFailure` rows are coarse `L=CRASH` until S4) |
| **S2 — the existing refusals and the CLI** | CerbFS 25, PNVI 9 pure + 2 `refuseM`, `formatFixed` → `refusal`; `Main`'s 12 + 2 + 5 sites → `refuseIO` (usage errors to exit 2), its 2 internal errors → `invariantIO`; `pnvi_lane.py` wrapper; the three CLI witness scripts and their stubs; `pnvi-arms-test` pins; register re-seal #1 (35 pure rows) | ~50 site edits, 4 scripts, 1 unit test, 1 re-seal commit | Tier A (row 1 incl. the register gate, row 14); Tier B row 5 unchanged in status, labels still `L=CRASH` |
| **S3 — the Q-A sweep** | the 73 default-path pure rows (72 (A) + `intToBytes` (B)-as-(A)) → `upstreamCrash` with cites (`tray: 12` on `bswap64`; `pending` on `offsetof-union-member` and `funptr_reload` until their tray drafts exist); the 3 pure Lean-only guards → `invariant`; the 12 switch kills → `refuseM`; register re-seal #2 (76 rows); the `check_failure_reach` speedbump rule; three tray drafts in the filing tray | ~90 site edits, 1 re-seal, 1 gate rule + plant, 3 drafts | Tier A + Tier B rows 5, 11; the inventory's Q-A rulings (INV §7 Q2, Q4, Q5) are PRECONDITIONS of this slice |
| **S4 — the lanes** | `test_immaculate.sh` token split + one re-record (24 rows, label-only, statuses pinned unchanged); `test_exec.sh` class in the log line + the `UNSUPPORTED`-requires-`REFUSAL` rule (+ its plant in `test_failstop_plant.sh`'s family); the failstop plant stub gains an envelope | 2 scripts, 1 re-record commit, 1 plant | Tier A rows 2–5, Tier B rows 5, 8, 9 |

Ordering rationale: S1 before anything (the classifier makes every later slice observable); S2 before S3 so the
refusal shape is settled before the sweep touches 90 sites; S4 last so there is ONE immaculate re-record. Each slice
is green on its own because an envelope-less hand-written panic reads `SHARED_CRASH` (not RED) until S3 — a documented
TRANSITIONAL misattribution (hand-written ≠ shared) that S3's speedbump closes; it is visible, never silent (the
immaculate plant of §3.5). Consumer note at each landing (the cerberus-sl practice); cerberus-caesium's note 2 gets
its answer at S1.

### 4.2 What moves, and what does not

- Moves: the failure-reach register's `msg` keys and seals (S2: 35 rows; S3: 76 rows) — classes, positions and the
  `need/invariant/witness` column unchanged; the immaculate `L=` labels of 24 rows (S4); the text pins of three row-1
  scripts and `pnvi_lane.py`'s refusal rule (S2); `handwritten_copy.manifest` and `lakefile.toml` (S1); the exit code of
  5 unpinned usage errors (S2).
- Does not move: every baseline status; `tests/pnvi_lane/baseline.txt` (no row pins a Lean crash message); the gcc,
  coverage, minimal, debug, float, libc, multi-TU, CN, verify baselines; the fork-drift manifest (no `common.sh` edit);
  the boundary-opaque census; the fuel census; any `.lem`; any generated file; LemLib.

### 4.3 Deliberately not migrated (out of scope, with the reason)

- The 128 generated `failwith` rows (`SHARED_CRASH`): lem's text, both engines; attribution is the lem failure-monad
  arc's (lem-lean TODO 24; the 2026-09-16 plan's WP2 for monadic ones). A Lean-side text edit cannot reach them.
- Typed outcomes at pure sites: the same arc (INV §5.0 — a pure site has no channel but `failwithI`).
- The fuel text and record: the consumer-named value; replaced structurally by WP1 (`Exhausted {}`), no legacy decoder.
- The allocator OOM, the asm refusal, every `Error` verdict: verdicts (§1.4).
- The (B) `:1716` print-then-kill and the (C)/(D) defined arms: INV §7 Q4/Q5 — rulings, not this note's.
- Any new opaque atom (INV option 2a): rejected by the adopted doctrine (D2 R0 §1 item 3; the scoping note §3).
- `LemLib.lemRequireAbortOnPanic`'s own refusal line: lem-lean's; unreachable here (`Main` guards first).

## 5. Interaction with the queued typed-outcome work (R1)

The class set is designed to survive the channel change WP1/WP2 make, so the sites are touched ONCE:

| Protocol class | R1 `interp_stop` | At WP1/WP2 |
|---|---|---|
| `RESOURCE/fuel` | `Exhausted` | the `fuel-kill` channel becomes the `Exhausted {}` record; the classifier's rule 3 reads it; `fuel-panic` stays until the pure arc |
| `REFUSAL` | `Unsupported of unsupported_feature * string` | `Boundary` IS the enumeration (R1 closed it at {filesystem, concurrency, switches}; the protocol's 13 are the ruling §6 Q5 asks for); the `string` is the envelope's `detail` + fields; `refuseM`'s body becomes `kill (Stopped (Unsupported b s))`, its signature unchanged; pure refusals stay on `panic` |
| `UPSTREAM_CRASH`, `INVARIANT` | `FailStop of string` | `failStopMem`'s body becomes `kill (Stopped (FailStop s))`; the class would then live only in the string — recommendation for WP2 [AGENT]: `FailStop of stop_origin * string` with `stop_origin = Upstream of string (* the cite *) \| Invariant`, so the distinction is structural (the envelope stays the rendering) |
| `SHARED_CRASH` | — (the pure axis, "not claimed" by R1 §2) | unchanged until the lem failure-monad arc gives generated sites a channel; then `FailStop (Upstream <lem cite>)` |
| host `RESOURCE` kinds | — (R1.2: host failures stay harness failures) | never constructors |

What changes at WP2: the channel table (§1.2) gains `Stopped {kind, …}` records, the classifier's rules 4–6 read
them, the `model-failure` channel retires; what does not change: the class set, the envelope grammar (the record's
string field), every site's spelling, the lanes' labels, the consumer's reading. The helper's builders keep their
signatures; only the adapters' bodies change. This is INV §5.5's point (iv), made concrete.

## 6. Open questions for the operator — each with a recommendation [AGENT]

1. **Class names.** `REFUSAL` / `UPSTREAM_CRASH` / `SHARED_CRASH` / `INVARIANT` / `RESOURCE` + `VERDICT`, mapped to
   the brief's five names in §1.1. Recommend as written; the mapping of "model failure" → `INVARIANT` and "semantics
   failure" → `SHARED_CRASH` is this note's reading and should be confirmed.
2. **The allocator OOM** stays a verdict with no classifier tag (upstream's own `fail`, both engines, consumer-named).
   Recommend yes; a `resource:` tag would need the exact text the consumer already holds as a constant.
3. **CLI usage errors** (5 sites, exit 1, unattributed): fold into `REFUSAL cli/<flag>` at exit 2. Recommend yes
   (INV §7 Q8; nothing pins them).
4. **The 12 config-dead switch kills**: move to the panic channel via `refuseM` (`REFUSAL switches/SW_…`), or keep
   verdict-shaped with envelope text. Recommend the panic channel: it is the one channel on which a refusal is a stop
   today, the sites are `memM` (the `pnviRefuseM` mechanism applies unchanged), and reach is zero (the CLI refuses first).
5. **The `Boundary` enumeration** (13 ids, §2.1) — a ruling, since R0 decision 4 closed R1's set at three and WP2
   inherits this one. Recommend the 13; `concurrency` and `switches` are R1's, `fs` is R1's `filesystem`.
6. **Q-A dispositions before S3**: INV §7 Q2 (all 79 or the 20 with reach), Q4 (`:1716`), Q5 (`:1044`/`:1864`).
   Recommend INV's: all through the helper; keep the kill and the two defined arms; file the tray reports.
7. **`UNSUPPORTED` on a `.unsupported.c` file requires class `REFUSAL`** (test_exec.sh, S4). Recommend yes: cheap,
   closes a laundering shape (a mirrored crash accepted by file name); the two existing rows are refusals (MEASURED).
8. **The register speedbump** (every hand-written row's message is `(CerbStop.…`): add inside `check_failure_reach.py`
   at S3's end (one regex, one plant), or leave it to review. Recommend add — a bare-string hand-written site would be
   read as the shared model by every consumer, silently; the rule is a report on rows the gate already parses.
9. **`RESOURCE/stack`**: pin the runtime's stack-overflow text from a measured run (S1) and classify it, or leave bare
   134s RED. Recommend pin: it answers the consumer's item B honestly (a (b)-class limit, never agreement) while the
   driver's recursion is a separate item.
10. **Tray drafts** for the three mirrors the register calls oracle-wrong or legal-C (`bswap64` has tray 12;
    `offsetof-union-member`, `funptr_reload` have none): `tray: pending` until drafted in S3. Recommend drafting in S3
    (operator network window for filing, as always).
11. **The exit code of `INVARIANT` on the `cli` channel** (the two `Main` internal errors): 2, as proposed, or a
    distinct code. Recommend 2 — one driver channel, one code; the class is in the line.

Rulings this note relies on, cited (never quoted): CONTRACT §1 D1 ([USER 2026-09-28]); the PNVI §H ruling: a dedicated
controlled outcome, if built, must be a policy across every such stop rather than a PNVI-local device, may take a form
other than a refusal, and must never leave a crash uncontrolled, the CerbFS shape sufficing meanwhile ([USER 2026-10-05],
PNVI design §H); the no-innovation rule ([USER 2026-10-03], PNVI
design §1.1); the gates ruling ([USER 2026-10-07], S1 record §14) — no new gate here, one speedbump proposed; the scope
of this pass ([USER 2026-10-17], the brief). Every recommendation above is [AGENT].

## 7. Provenance — MEASURED commands (read-only, `f5303eda5`, this worktree; `/home/dev/projects/cerberus-sl` at `68832d91`)

- `grep -c -E '^[^#].* MATCH \| L=CRASH' tests/immaculate/baseline.txt` → 18; `DIFF \| L=CRASH` → 6; `ORACLE_CRASH ` → 7.
- `grep -c SKIP_LEAN_CRASH scripts/gcc_oracle_baseline.txt` → 21; `grep UNSUPPORTED scripts/exec_coverage_baseline.txt` → 2 rows (`fmt-007-f-nan-sign`, `fmt-007b-f-nan-negated`) + 1 header comment.
- `grep -E 'BOTH_FAIL|REFUSAL|097' tests/pnvi_lane/baseline.txt` → 7 `REFUSAL` rows, 2 `BOTH_FAIL` (`073-exit.libc`, `074-abort.libc`, Error/Error), `097-null-ptr-arith.undef AGREE`.
- `grep -c 'cerberus-lean: refused' lean_frontend/Main.lean` → 12; the register: 240 non-header lines, tally `sites=239 … REACHABLE=44 UNKNOWN=22`, 111 `lean_frontend/*.lean` rows, 128 `generated/` rows.
- `grep -n -E "'failwithI'" scripts/failure_census.py` → line 84: heads `failwithI`, `panic!`, `panic`, `panicCore`.
- `grep -n -B4 -A4 'out of memory' memory/concrete/impl_mem.ml` → `:1291`, `:1296` `fail (MerrOther "Concrete.allocator: failed (out of memory)")`.
- `grep -rn -F 'model refused' scripts tests` → `observations.py:376`, `test_observations.py:16,355-359`, `test_observation_lanes.py:68-70,122-123` (the CN lane's `refusal` words at `test_cn_coverage.sh:22,329,372,416,429,432` are its REJECT class).
- cerberus-sl: `fuelExhaustedKill` 301 mentions, `oomOutcome` 285, `Interface.lean:177-178` its definition; `modelFailStopLoc`/`failwithI`/`ModelFailure`/`refused`/`LEAN_ABORT_ON_PANIC` only in doc comments and one probe (`probes/2026-10-13_m2-0-observer.lean`); `liftKill` 3-arm match at `PrimOutcome.lean:355-358`.
- cerberus-caesium: `scripts/check-caesium-exec.sh:73` runs its own harness exe in-process under `LEAN_ABORT_ON_PANIC=1` and a cap; no driver `--batch` invocation (`grep` over `CaesiumHarness/`).
- The separator: `grep -v '^#' scripts/failure_reach_register.txt | grep -c -- ' -- '` → 0 (all 239 rows); `grep -c -- ' -- ' memory/concrete/impl_mem.ml` → 0;
  `grep 'cerberus-lean: refused' lean_frontend/Main.lean | grep -c -- ' -- '` → 0; the `failwithI`/`failStopMem`/`pnviRefuse`/`fsRefusal` lines of the eleven
  hand-written seams → 6 hits, all trailing `--` Lean comments outside the string (`CerbMem.lean:1414,2542,3247,3465,3495`, `Main.lean:1505`).

Not run: any build, lane, driver or oracle; the stack-overflow text is the consumer's quotation, not a measurement.
