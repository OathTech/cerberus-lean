# Reasoning-artifact audit — where the semantics was shaped as an executable, and what it costs a consumer that reasons (2026-09-03)

Branch `audit/reasoning-artifact` off mainline `de2fbf1bd` (worktree
`worktrees/cerberus-lean-audit/reasoning-artifact`). READ-ONLY design
audit: this document only; no product code, gate, baseline or build was
touched; nothing merged or pushed.

Question [USER 2026-09-03], verbatim: "Can you send a worker to go look
for similar instances of 'execution focus' - I think this basically is a
result of thinking of the semantics as an execution artifact, not a
reasoning artifact. Where else might we have baked this in?"

Every grading below is [AGENT] (this auditor). Quoted code and consumer
text are verbatim; tallies marked DERIVED are grep-derived. Trees read:
cerberus-lean mainline `de2fbf1bd` (hand-written seams in this worktree;
`generated/` read from the primary checkout, same commit); LemLib at the
Lake pin `3c88f0d` (`lean_frontend/.lake/packages/LemLib/lean-lib/
LemLib.lean`, byte-identical to lem-lean `mdd/lean-backend` `0890229`'s
copy — verified by `diff`); refined-cerberus (the consumer) at
`5d08237` (2026-09-03 23:57), whose `.cerberus-ws` pins cerberus-lean
`f95ef8d9c` (verified: `git -C refined-cerberus/.cerberus-ws rev-parse
HEAD`). The three instances already ruled on 2026-09-03 — (1) fixed fuel
budgets, (2) `panic!`/`failwithI` denoting the `Inhabited` default in-
process, (3) the "no magic values" principle — are NOT restated here
except as cross-references (§3, §4); their records are lem-lean
`doc/lean-backend/2026-09-03_fuel-parameter-design.md`,
`docs/2026-09-03_typed-failure-outcomes-ruling.md` (branch
`arc/zero-discrepancy-z2`) and `DESIGN.md` §4 + `docs/2026-09-03_logical-
semantics-referent-ruling.md` (branch `docs/no-magic-values`).

## 0. Headline

Nine further instances, one of them serious enough that the consumer's
next re-pin will hit it; three of them are FREE (the mechanism that hides
them from the kernel hides a constant), so the remedy is a deletion.

| # | Instance | Where | Fails | Who pays (consumer evidence) | Remedy | Price | Grade |
|---|---|---|---|---|---|---|---|
| A | The switch/config surface (`has_switch`, `current_execution_mode`, `is_PNVI`, `using_concurrency`, …) is 11 kernel-OPAQUE constants reading process refs that NOTHING ever writes — on the exec cone: `core_thread_step2`, `perform_action_request2`, `process_core_step2`, and since Z1 `killM` and `ptrfromint` | `CerbGlobal.lean:62-144`; generated `Core_run.lean:424`, `Driver.lean:315,421`; `CerbMem.lean:1922,1966,2357` | Q1 Q2 Q3 | refined-cerberus `README.md:585-600` argues switch-independence from "the Lean `CerbMem` references no `CerbGlobal` constant" — TRUE at their pin `f95ef8d9c`, FALSE at mainline (`0cdb1dfb8`, Z1, added three reads incl. `killM`, their `free` rule's referent); they `cases` on the opaque `current_execution_mode` (`DriverCollapse.lean:64, 671-709`); our own exemplar does the same (`test/Unit/FuelExemplar.lean:22-23,180-183,350-352`); third-party audit: "It also explains why full refusal classification is not currently available" (`2026-09-02_cerberus-heaplang-detailed-audit.md:481-484`) | Step 1 (S, deletion): the refs are never written, so replace every opaque by the plain `def` of the default configuration — kernel-transparent, zero behaviour change. Step 2 (M): make configuration a reader-lifted parameter like `tagDefs` (`drive conf switches fuel …`) so a theorem quantifies over switch settings | S then M | **MAJOR** |
| B | Core-text symbol identity is `String.hash` — an `@[extern] opaque` of the Lean prelude — with digest `""`; the OCaml parser mints via the fresh supply. Every std.core / libc.core symbol therefore has a kernel-opaque id, and the hash-collision tripwire (G6) lives inside the parser | `CoreParser.lean:188-198, 2051-2156`; `Prelude.lean:4653-4654`; `parsers/core/core_parser.mly:184,220` | Q2 Q7 Q8 | Consumer authors Core by hand and never parses: "Synthetic Core entry: authored Core wrapped by `prodFile`, not C through the frontend" (`README.md:614`); our exemplar likewise avoids the parser ("kernel evaluation of the Parsec text parser would be an uninformative cost", `FuelExemplar.lean:7-12`). No consumer theorem mentions a stdlib symbol — because none can compute with one | Mint symbols from the threaded supply (the mechanism exists since C1; mirrors `core_parser.mly`), digest as a parameter; DELETE the G6 tripwire (the collision class vanishes) | S-M | **MAJOR** |
| C | The enum registry: `typeof_enum`/`register_enum` are opaques over a process-global `IO.Ref` written during desugar; `sizeof_ity`/`is_signed_ity` route enum types through it — on the exec cone via `CerbMem.sizeofCtype` and integer conversions. An in-process consumer that never ran desugar (authored/parsed Core) hits the "unregistered" arm: panic → `Inhabited` default | `CerberusImpl.lean:48-68, 77-92, 123-137, 220-238`; DERIVED reach: `CerbMem.lean` 9 `sizeof_ity` + 9 `is_signed_ity` + 2 `typeof_enum`, `Defacto_memory.lean` 2 | Q2 Q3 | Listed by the consumer among the opaques reached by their export cones: "`CerberusImpl.typeof_enum` (via `sizeofCtype`'s enum arm)" (`README.md:557-570`) | The registry is a VALUE: desugar returns it (it already threads a supply); the Core `file` (or the tagDefs reader) carries the enum table; `typeof_enum tbl sym` | M | **MAJOR** |
| D | The front end is `partial`: `desugar`/typing/`translate`/`link`/CoreParser/CabsImport carry ~290 `partial def`s (DERIVED, line count); the totality gate is scoped to the exec cone, so VALIDATION's "total artifact … consumers can reason about" holds for `drive`, not for the C→Core pipeline the north star needs | `scripts/check_exec_totality.sh:56-62` (EXEC_MODULES); DERIVED census: `Cabs_to_ail` 50, `CoreParser` 100, `CabsImport` 37, `GenTyping` 14, `Core_rewrite` 13, `Core_typing` 9, `Translation` 6, `Core_linking` 4, `Implementation` 1 (`normalise_ctype`, :642) | Q2 | Consumer lists "a C-frontend entry" as the mover of their synthetic-Core limitation (`README.md:614`) and `normalise_ctype` among reached opaques (`README.md:568`) | Extend the lem totalization declares (fuel now, ∀-fuel after the fuel-parameter arc) over the front-end modules; extend the totality gate's module list | L | MINOR (latent: no consumer reasons about C yet; it is the wall the north star walks into) |
| E | The per-TU digest is a kernel-opaque read of a native mutable global set by `Main` (`setDigestIO`) — the value of `desugar`/`translate` depends on process state, not arguments (front end only; the exec cone uses the pure `digest_compare`) | `CerberusFresh.lean:56-70, 108-120, 152-166`; generated `Cabs_to_ail_effect.lean:762-782`; `Main.lean:853` | Q3 | "`CerberusFresh.digest`" is on the consumer's reached-opaque list (`README.md:568`); `digest_compare` NOT being opaque is recorded as a win they depended on (`EnvLaws.lean:207-210`) | Digest becomes a parameter of `frontendTU` (reader-lifted like `tagDefs`, or a field of the supply record); delete the native global, `forceIO` barrier and 6 of the 26 opaque-census rows (`md5Hex` stays) | S-M | MINOR |
| F | Invented choices over nondeterminism: `runND1` (`--first`) always takes branch 0 where the oracle draws randomly; `bounded_integer` returns `lo` (opaque, `implemented_by`) where the oracle draws `Random.int64 [lo,hi]` | `CerbND.lean:165-182, 190-227`; `CerbUtils.lean:56-76`; generated `Core_run.lean` (one `bounded_integer` site) | Q2 Q4 | None yet (consumer uses `runND`, not `runND1`; `bounded` is unexercised) — the harness pays: the divergence note admits the single-trace differential is "sound only for programs whose observable verdict is trace-independent" (`CerbND.lean:165-177`) | `bounded_integer` becomes an ND fork over `[lo,hi]` (or a parameter); `runND1` takes the branch selector as an argument (`runND1With (pick : List _ → Option _)`), the CLI default = index 0 | S | MINOR |
| G | `BEq MemValue` is an `unsafe` + `opaque`/`implemented_by` sandwich "for the nested recursion" — a definition the kernel cannot unfold, where a structural mutual definition exists (`CerbStepInstances.lean:98-140` already does exactly that shape without `unsafe`); plus degenerate `Ord PointerValue/MemValue := .eq`, `BEq Allocation/MemState := false` | `CerbMem.lean:191-222` | Q2 Q5 | "`CerbMem`'s private `beqMemValueSafe`" on the consumer's reached-opaque list (`README.md:568`) | Replace by a structural (nested-inductive) `BEq`; delete the `implemented_by` row; give the degenerate instances real comparators or delete them | S | MINOR |
| H | The reasoning API is not shipped: the symbolic round library that makes ∀-fuel proofs feasible (`Round`, `runOne`, `driver2_done`, `budget_succ`) is test-local by declaration; the brute route (unfold, `cases` the opaque, `rfl`) times out at the DEFAULT heartbeat budget even at literal fuel 1 | `test/Unit/FuelExemplar.lean:17-49` | Q5 | Consumer rebuilt the same library (`DriverCollapse.lean`, `Round.lean`); ~35 hand re-normalisations `show lemDefaultFuel = 999999 + 1 from rfl` (DERIVED); "10^8 vs 10^6 hits the recursion-depth limit — the 2026-09-03 re-pin's error class" (`DriverCollapse.lean:92-95`); fuel monotonicity requested (`2026-09-03_request-lem-lean-pmap-laws-and-fuel-scheme.md:79-99`) | Ship the round equations and `_succ` lemmas in `CerbND` as contract (with the fuel-parameter arc, restated over the parameter); fuel monotonicity as a generated theorem (lem-side) | M | MINOR |
| I | No-op shims made OPAQUE for "OCaml module-shape parity": `STD_ s x` (26 desugar sites) is an opaque that returns `x` after writing a log nobody reads; `begin_timing`/`end_timing` are opaque no-ops with zero generated callers; `statically_satisfied := true` is a silent stub with zero callers | `CerbUtils.lean:18-47`; `CerbConcurrency.lean:20`; DERIVED: `Cabs_to_ail(_effect).lean` 26 `STD_` sites, 0 timing callers, 0 `statically_satisfied` callers | Q2 Q7 | None measured (front end); the allowlist classes them "permanent-declared" (`scripts/unsafebaseio_allowlist.txt` rows 1-3) — this audit disagrees: nothing about a write-only log is load-bearing | `def STD_ (_ : String) (x : α) : α := x`; delete the timing refs and the dead stub (or make the stub a loud refusal, class (c)); 3 opaque-census rows and 11 PIN rows disappear | S | MINOR |
| J | `isLibraryLocation` (behaviour-bearing: UB-location substitution) tests a path SUFFIX because the runtime root is not plumbed — meaning depends on the file-system layout convention | `CerbLocation.lean:177-210` | Q3 | None measured; own residual note: "the residual is a USER file under a directory literally named `runtime/libcore`" (`:197-200`) | Runtime root as a parameter (the same plumbing slice as A) | S | NOTE |
| K | The consumer-facing trust story classifies seams by EFFECT (`unsafeBaseIO`/`implemented_by` census), not by REASONING COST: there is no list of "what a theorem about `drive` cannot unfold". The consumer had to measure it (`qa2-notes`) and a third auditor had to correct their reading | `VALIDATION.md:234-260`, `DESIGN.md` §4 ("a total Lean artifact … future consumers can reason about") | — | `README.md:557-570` (their measured list); `detailed-audit:485-489`: "The correct conclusion is not 'opaques are harmless,' but 'the exported theorems are kernel-valid for every interpretation of the opaques'" | A "Reasoning surface" section in VALIDATION.md: every opaque/`partial`/process-state read reachable from each exec entry, with mover; gate = the existing census, partitioned by reach | S | NOTE |

Three things this audit found that are NOT ours to fix but the consumer
is paying for, recorded in §5: LemLib's `partial` leaves and the WF-
recursive `Pmap.join` that does not compute (consumer request §2 of
their 2026-09-03 note); lem `string` as Lean `String` (F2, lem-lean
design note, scheduled); Lean `Float` being kernel-opaque by the
standard library.

## 1. Method and the lens

The product is a semantics consumers REASON against (refined-cerberus
states theorems over `CerbND.runND (drive …)` and the `CerbMem` model
in-process); it was built and validated as an EXECUTABLE (a binary under
`scripts/*.sh`, compared with the OCaml oracle). The three 2026-09-03
rulings each name a place where a choice that is invisible to the binary
(a fixed budget; a panic that the harness turns into an abort; a
hardcoded value) is a defect for the definitions. This audit asks the
same question of every other hand-written seam, the lem backend's emitted
shapes, the trust documents and the unit gates.

Each candidate was tested against Q1–Q9 of the brief: can a theorem
quantify over it (Q1); unfold it (Q2); does its meaning depend on the
process rather than the arguments (Q3); is a choice over nondeterminism
fixed inside the semantics, and is that forced by the OCaml (Q4); is the
interface execution-shaped where a reasoning shape exists (Q5); is a
totality device a fuel where a measure would do (Q6); does an instrument
live inside the semantics (Q7); does a constant mirror the OCaml runtime
rather than the model (Q8); what did the consumer actually work around
(Q9). Reach was MEASURED, not assumed: every "on the exec cone" claim
below names the generated definition that contains the read
(`awk`-located enclosing `def`), and the exec cone is the gate's own
module list (`scripts/check_exec_totality.sh:56-62`).

What counts as an instance: a design choice that serves the binary or the
harness and costs the reasoning consumer — a theorem cannot quantify over,
unfold, state or trust something because the definition was shaped for
execution. What does not: a shape forced by the lem model, the OCaml
mirror or ISO (§3), even if it is inconvenient to reason about.

Consumer evidence was gathered by a full read of refined-cerberus's
`docs/DECISIONS.md`, `cerberus-heaplang/{README,ARCHITECTURE}.md`, the
request/review/scout notes, and a grep of their Lean sources for every
cerberus-lean name; every quote used below was re-read by this auditor
at `5d08237` (the sweep ran at `e34b30b`; two consumer commits landed
during the audit — one deleted their `driveU` workaround and every
`PROVISIONAL` label, one filed a new upstream request).

## 2. The instances

### 2.A The configuration surface is opaque process state — and it is never written

`CerbGlobal.lean` defines the whole switch/config surface as eleven
`opaque` constants bound by `@[implemented_by]` to `unsafe` readers of
two `IO.Ref`s:

```lean
@[never_extract, noinline]
private unsafe def confRef : IO.Ref CerbConf :=
  unsafeBaseIO (IO.mkRef default)                          -- CerbGlobal.lean:62-64
…
@[implemented_by has_switch_impl]
opaque has_switch : CerbSwitch → Bool                     -- :134-135
@[implemented_by is_PNVI_impl]
opaque is_PNVI : Unit → Bool                              -- :140-141
```

with `is_PNVI_impl (_ : Unit) : Bool := false` and
`has_strict_pointer_arith_impl … := false` (:107-109) — literal `false`
hidden behind an opaque. The file's own comment states the load-bearing
fact (:53-56): "The hazard is latent today only because nothing ever
WRITES these refs (no setter is exposed — `current_execution_mode` is
permanently `none`), so all reads return `default` regardless". `Main`
refuses `--switches` outright (`Main.lean:1041`; `VALIDATION.md:265-276`,
Z-24). So the opaque machinery hides a CONSTANT: at runtime every read
is `default`, and the kernel is told nothing.

Reach (measured on the generated tree at `de2fbf1bd`):

- `Core_run.lean:424`, inside `core_thread_step2` — the step function —
  `if CerbGlobal.has_switch CerbGlobal.CerbSwitch.inner_arg_temps && …`
  (model source `core_run.lem:954,964`);
- `Driver.lean:315` (`perform_action_request2`) and `:421`
  (`process_core_step2`) — `maybeEqualBy (fun x y => x == y)
  (CerbGlobal.current_execution_mode ()) (some
  CerbGlobal.ExecutionMode.random)` (model source `driver.lem:748,
  1380`);
- since Z1 (`0cdb1dfb8`, 2026-09-03, "CerbMem kill arms and check order
  … mirror impl_mem.ml line for line"): `CerbMem.lean:1922` and `:1966`
  inside `killM` (`if CerbGlobal.has_switch .forbid_nullptr_free then
  fail_ MerrFreeNullPtr`; `if CerbGlobal.has_switch .zap_dead_pointers
  then (NDkilled …)`) and `:2357` inside `ptrfromint` (`if
  CerbGlobal.is_PNVI () then kill …`).

Q1: a theorem cannot range over switch settings — there is no parameter.
Q2: it cannot unfold the read either — every proof that passes a switch
test must `cases` on an opaque `Bool` and prove both arms, including the
arm the binary can never take. Q3: the definition's meaning is "whatever
the process ref holds", which the kernel does not know is `default`.

Consumer cost, three independent pieces:

1. Their configuration argument (`cerberus-heaplang/README.md:585-600`,
   verbatim): "the Lean `CerbMem` references no `CerbGlobal` constant,
   so `loadM`/`storeM`/`allocateObject`/`eqPtrval` are switch-independent
   by construction; the one configuration read on a proved path, the
   driver's `current_execution_mode`, is discharged for both values by
   `cases` on the opaque test (`driver2_done`, DriverCollapse.lean)". At
   their pin `f95ef8d9c` the premise is true (`grep -c CerbGlobal
   .cerberus-ws/lean_frontend/CerbMem.lean` = 0). At mainline it is
   false: `killM` — the referent of their `free` rule (`Heap.lean:826-834`
   cites "`killM`'s dynamic check (CerbMem.lean:1573)") — now reads two
   opaque switches. Their next re-pin inherits a `cases` on each, or a
   premise they cannot state.
2. `DriverCollapse.lean:64` (`driver2_done`, proof at :671-709, `cases
   hmode` :709) / `README.md:594-596`: the `cases` on the
   opaque scheduler-mode read is already paid on every production
   statement. Our own `FuelExemplar.lean` pays it too (:22-23 "CASES on
   the opaque scheduler-mode read `CerbGlobal.current_execution_mode ()`";
   :180-183 `generalize hm : CerbGlobal.current_execution_mode () = m;
   cases m with … | some md => cases md <;> decide +kernel`).
3. The third-party audit of the consumer
   (`2026-09-02_cerberus-heaplang-detailed-audit.md:481-484`): "proofs
   cannot unfold them, so a theorem involving them must be parametric in
   their value or avoid the relevant branch. This is generally handled
   conservatively. It also explains why full refusal classification is
   not currently available."

Remedy, in two steps that are separately valuable:

- Step 1 (S, a deletion, zero behaviour change): replace the eleven
  opaques by plain `def`s of the default configuration
  (`def has_switch (_ : CerbSwitch) : Bool := false`, `def
  current_execution_mode (_ : Unit) : Option ExecutionMode := none`, …).
  The binary computes exactly what it computes today (the refs are never
  written); the kernel now sees the constant, every `cases` above becomes
  `rfl`, and 11 opaque-census rows + 29 PIN rows leave
  `scripts/unsafebaseio_allowlist.txt`. This is the honest statement of
  what the port IS today ("matched default-switch mode is the harness
  contract", `Main.lean:1041`).
- Step 2 (M, the named mover — allowlist class
  `temporal(post-arc-parameter-plumbing-slice)`): make the configuration
  a reader-lifted parameter exactly as `tagDefs` is (`declare {lean}
  reader val` on `Global.current_execution_mode`, `Switches.has_switch`
  … in `global.lem`; the lem-side machinery is the effect-retirement
  arc's, lem-lean `lean_backend.ml:3538-3544`). Then `drive conf sws fuel
  …` and a consumer's theorem quantifies over the switch set — which is
  what "every export holds under every switch setting" (their
  `README.md:598-599`) ought to mean.

Grade: MAJOR — on the exec cone, already paid by the consumer, and about
to be paid again at re-pin; Step 1 costs an afternoon.

### 2.B Core-text symbols are identified by `String.hash`

```lean
/-- Construct a symbol from a parsed identifier string.
    Uses the string's hash as the number so distinct names get distinct
    IDs (symbol equality ignores the description — see symbolEqual in
    symbol.lem).  This sidesteps Lean's CSE of pure `Unit → Nat` calls. -/
private def mkSym (name : String) : sym :=
  Symbol "" name.hash.toNat (SD_Id name)                  -- CoreParser.lean:187-192
```

`String.hash` is `@[extern "lean_string_hash"] protected opaque
String.hash (s : @& String) : UInt64` (Lean 4.32.2 `Init/Prelude.lean:
4653-4654`): the kernel has no equations for it. Every symbol of
`std.core`, of `libc.core`, and every symbol `Main.loadLibc` rekeys onto
them (`Main.lean:103-110` "THE STITCH", `CoreParser.internSym` :198) therefore
has an id no proof can compute, and digest `""`. `symbolEquality`
(digest + id, `Core_run.lean:424` etc.) on any such pair is stuck; a
theorem about any program that calls a libc or std.core function —
i.e. any C program with a `printf` — cannot decide which procedure is
called. The OCaml parser mints these symbols from the fresh supply
(`parsers/core/core_parser.mly:184,220`: `Symbol.Symbol
(Cerb_fresh.digest(), Cerb_fresh.int(), SD_Id (fst _sym))`), so the hash
is a Lean-side invention — and its stated reason ("sidesteps Lean's CSE
of pure `Unit → Nat` calls") is an artefact of the effect-erasure era
that the effect-retirement arc ended: the supply now exists and is
threaded through `Main` (`Main.lean:831-856`).

The instrument inside the semantics (Q7) follows from the choice: because
"distinct names get distinct numbers" is a probabilistic margin, the
parser scans every identifier and FAIL-STOPS on a collision
(`CoreParser.lean:2051-2080`, the G6 tripwire; the refusal at :2156).
`Main.lean:1172-1176` explains why supply collisions are impossible "by
construction" for the fresh stream — the hash stream is outside that
argument (hash values are `Nat`s that could in principle coincide with
supply-drawn ids; the margin is 2^64).

Consumer cost: indirect but total — nobody reasons about a parsed Core
file. The consumer authors Core as Lean terms (`README.md:614`
"Synthetic Core entry: authored Core wrapped by `prodFile`, not C
through the frontend") and our own exemplar declines to parse
(`FuelExemplar.lean:7-12`). Q2 fails for every stdlib symbol; Q8: the id
is a runtime hash of the host's string representation, mirroring
nothing in the model.

Remedy: `CoreParser` takes the supply (its parse state already threads a
`Sigma String.Pos`; the supply is one more `Nat`) and mints
`Symbol digest n (SD_Id name)` with a per-file interning table (by-name
interning within a file is the OCaml behaviour: `core_parser.mly`'s
`symbolify_state` (:74-80) resolves declared names to their minted symbol). The digest
becomes a parameter (2.E). The G6 tripwire, its probe and its immaculate
pin are DELETED — the collision class no longer exists. Price S-M
(CoreParser's `mkSym` sites + `Main.loadLibc`'s rekeying + the libc lane
baselines, which embed no symbol numbers by the renumbering ruling
`VALIDATION.md:92-114`).

Grade: MAJOR.

### 2.C The enum registry is process state inside `sizeof`

```lean
initialize enumRegistryRef : IO.Ref (List (sym × integerType)) ← IO.mkRef []
…
@[implemented_by typeof_enum_impl]
opaque typeof_enum : sym → integerType                    -- CerberusImpl.lean:48, 66-67
```

with the unregistered arm `pure (panic! "Ocaml_implementation.typeof_enum:
tag was not registered …")` (:60-62). `is_signed_ity` (:77-91),
`sizeof_ity` (:123-137), `precision_ity`, `normalise_integerType` (:245)
all route `.Enum0` through it, and `CerbMem.lean` calls `sizeof_ity` 9
times, `is_signed_ity` 9 times and `typeof_enum` twice (DERIVED) — the
memory model's layout of an enum-typed object is "whatever the process
registry says". Registration happens during desugar
(`cabs_to_ail_effect.lem:1759`), i.e. in a phase an in-process consumer
who authors or parses Core never runs; for them every enum-typed access
reaches the panic arm and, in-process, the `Inhabited` default (the
typed-failure ruling's shape, but here the CAUSE is the process-state
read, not the failure rendering).

Consumer cost: `README.md:566` lists "`CerberusImpl.typeof_enum` (via
`sizeofCtype`'s enum arm)" among the opaques their export cones reach.
The allowlist names the mover ("reader/supply-machinery-follow-up-slice,
explicitly NOT in-arc").

Remedy (M): the registry is a value the desugarer PRODUCES (it already
returns a supply; the enum table is one more component) and the memory
model CONSUMES (`typeof_enum tbl sym`, threaded like `tagDefs` — indeed
the natural home is the tag-definition environment the model already
passes by value: an enum's compatible type is part of the program's type
environment, exactly as a struct's layout is). 2 opaque-census rows and 6
PIN rows leave the allowlist.

Grade: MAJOR — exec cone, consumer-reached, and it disagrees with the
oracle exactly for the in-process consumer (who has no desugar run to
populate the registry).

### 2.D The front end is `partial`

`check_exec_totality.sh:56-62` scopes the totality gate to the exec cone
(`Core_run Core_reduction Core_eval Driver … Formatted Monadic_parsing`),
and `VALIDATION.md:190-192` claims "The execution path is total,
effect-honest, and axiom-clean". True — and the pipeline in front of it
is not: DERIVED `partial def` census of the generated tree at
`de2fbf1bd`: `CoreParser` 100, `Cabs_to_ail` 50, `CabsImport` 37,
`GenTyping` 14, `Core_rewrite` 13, `Core_typing` 9, `Desugaring_init`
9, `Translation` 6, `Core_typing_aux` 6, `AilTypesAux` 6, `Core_linking`
4, `Cabs_to_ail_effect` 4, `Cabs_to_ail_aux` 4 (and 18 more modules with
1-3; ~290 lines in all, `Main.lean`'s 2 excluded as harness). `desugar`, `translate`, `link`, `convert_file` are on the exec-
entry axiom list (`VALIDATION.md:148`), but that list's own caveat
applies: "the `#print axioms` probes … underreport across `partial def`
boundaries" — so the axiom-cleanliness of the front-end entries is
weaker evidence than the exec cone's.

Q2: a consumer who wants to state anything about a C program (not a Core
program) — the north star — cannot unfold `translate`. The consumer's
limitation table names the mover: "a C-frontend entry" (`README.md:614`);
`normalise_ctype` (`Implementation.lean:642`, `partial`) is on their
reached-opaque list (`README.md:568`).

Remedy (L): the same lem declares that totalized the exec cone
(`declare {lean} fuel val` / `termination_argument`), applied module by
module to the front end, and the gate's module list extended as each
module closes — after the fuel-parameter arc, so the fuel is the
quantified one. Grade MINOR today (no consumer reasons about C yet),
with the note that it becomes MAJOR the day one does.

### 2.E The per-TU digest is native mutable state

`CerberusFresh.lean:56-70` declares `md5Hex`, `digestIO`, `setDigestIO`
as externs over `native/md5.c`'s global; `:108-120` the kernel-checked
opaque chain `digestPure → digest_impl → opaque digest : Unit → String :=
fun _ => ""`; `:152-166` the `forceIO` evaluation barrier "Needed
wherever a PURE computation reads mutable native state … and is written
between two writes of that state". `Main.lean:853` sets it per TU;
`Symbol.fresh*` read it (`Cabs_to_ail_effect.lean:762-782`,
`Symbol.lean`). The exec cone is CLEAN: every `CerberusFresh.digest`
occurrence in `Core_run`/`Core_aux`/`Defacto_memory` is the pure
`digest_compare` (measured; the `digest ()` calls are all in the front
end).

Q3: `desugar`'s result depends on which TU the process last stamped.
Consumer cost: `README.md:568` lists `CerberusFresh.digest` among reached
opaques; `EnvLaws.lean:207-210` records, as a fact they relied on, that
`digest_compare` is "NOT extern-opaque" — the line between the two is
exactly the reasoning surface.

Remedy (S-M): the digest is a per-TU VALUE `Main` already holds
(`CerberusFresh.md5Hex content`); pass it into `frontendTU` and reader-
lift `Cerb_fresh.digest` like `tagDefs` (or make it a field of the
supply state — it is per-TU constant, so reader is the right shape).
Then delete the native global, `digestIO`/`setDigestIO`/`digestPure`/
`digest_impl`/`forceThunkIO`/`forceIO_impl`/`forceIO` and the `let-
sinking` hazard they exist to armour against (`:121-135`): 6 of the 26
opaque-census rows and 10 PIN rows. `md5Hex` stays (a pure extern; a
Lean MD5 would remove even that, S). Grade MINOR (front end only) —
but the cheapest large deletion in this list.

### 2.F Invented choices over nondeterminism

Two, both documented, both harness-motivated:

- `CerbND.runND1Fuel` (`CerbND.lean:190-227`; `--first`) takes
  `(_, branch) :: _ => runND1Fuel fuel branch st'` — branch index 0 and
  the left side of `NDbranch` — where the oracle's `Smt2.runND Random`
  draws from a time-seeded PRNG (`:156-163`). The file calls it a
  "DELIBERATE DIVERGENCE (trace selection only)" and states the
  harness's soundness condition honestly (:165-177): "sound only for
  programs whose observable verdict is trace-independent".
- `CerbUtils.bounded_integer` (`CerbUtils.lean:71-76`): `opaque`,
  `implemented_by boundedIntegerImpl … pure lo`, where the oracle draws
  `Random.int64` in `[lo, hi]` (`:56-69`); one generated call site
  (`Core_run.lean`, the Core `bounded` primitive).

Q4: both fix a choice the model leaves open, and neither mirrors the
OCaml (which is random). Q2 for the second: it is also opaque, so a
theorem cannot even see that it returns `lo`. Consumer cost: none today
(they state theorems over the exhaustive `runND`; `bounded` is
unexercised) — the cost is the harness's own `--first` lanes
(`test_libxml2.sh`), sound only by the purity argument above.

Remedy (S): `bounded_integer` becomes what the model says it is — a
nondeterministic choice — an `NDnd` fork over `[lo, hi]` in the memory/
driver monad (the oracle's random draw is then one member of the set the
exhaustive runner enumerates, and Lean's exhaustive verdict set becomes
the oracle-in-all-seeds set), or at minimum a plain `def … := lo` with
the divergence stated; `runND1Fuel` takes its branch selector as an
argument (`pick : List (info × ndM …) → Option (ndM …)`), the CLI
supplying index 0. Grade MINOR.

### 2.G `BEq MemValue` is an `unsafe`/`opaque` sandwich

```lean
private unsafe def beqMemValueImpl : MemValue → MemValue → Bool
  …
  | .MVarray e1, .MVarray e2 =>
    e1.length == e2.length && (e1.zip e2).all (fun (a, b) => beqMemValueImpl a b)
  …
@[implemented_by beqMemValueImpl]
private opaque beqMemValueSafe : MemValue → MemValue → Bool
instance : BEq MemValue where beq := beqMemValueSafe        -- CerbMem.lean:195-213
```

The stated reason is "the MVarray/MVstruct nested recursion" (:194). But
`CerbStepInstances.lean:98-140` writes exactly that shape — mutual
structural recursion through `List` for `object_value`/`loaded_value`/
`value` — as plain `def`s. Q2 fails for no reason the kernel imposes.
Consumer cost: `README.md:568` lists "`CerbMem`'s private
`beqMemValueSafe`" among reached opaques. The degenerate instances next
to it (:218-222: `Ord PointerValue … := .eq`, `Ord MemValue … := .eq`,
`BEq Allocation … := false`, `BEq MemState … := false`, with the
reachability note :164-176) are traps for a consumer: `a == b = false`
is PROVABLE for equal allocations. The comparator-vs-equality coherence
gap on `ctype` (`CerbCtypeInstances.lean:17-24`: `BEq` annotation-
insensitive, `Ord` annotation-sensitive, "no consumer relies on
BEq/Ord coherence") is the same genus, stated.

Remedy (S): structural `BEq` (mutual with `List`), delete the
`implemented_by` row (1 opaque row, 2 PIN rows); give the degenerate
instances real comparators or remove them and let the missing instance
fail at compile time if a use ever appears. Grade MINOR.

### 2.H The reasoning API is test-local

`test/Unit/FuelExemplar.lean:17-32` describes what a ∀-fuel proof over
the shipped pipeline needs: "a test-local round library (`Round`:
`runOne` and its bind/get/update/read/liftMem/runND equations,
`prepare_exit_single`, `loop_step_done`, `process_done`, `driver2_done`
… `finalize_done`, `budget_succ : CerbFuel.driverFuel = Nat.succ 99999999
:= rfl`)" and then (:30-32): "The library is a proof device of this test
file; it is NOT part of the `CerbND` contract (it stays test-local unless
the consumer asks for it)". The diagnosis (:43-49) is the Q5 fact: "the
brute route — unfold the run, expose the opaque read, `cases`, then …
`rfl` — times out at the default 200000 heartbeats EVEN AT THE LITERAL
FUEL 1 … The consumer's symbolic method is the only viable shape".

The consumer built the same thing independently (`DriverCollapse.lean`,
`Round.lean`) and pays the numeral tax on every statement: ~35 `show
lemDefaultFuel = 999999 + 1 from rfl` (DERIVED count over
`cerberus-heaplang/CerberusHeapLang/`), `DriverCollapse.lean:92-95`:
"Budget numerals are unfolded ONLY through the `_succ` lemmas below
(never a `show`-forced numeral defeq: 10^8 vs 10^6 hits the recursion-
depth limit — the 2026-09-03 re-pin's error class)"; and their request
(`2026-09-03_request-lem-lean-pmap-laws-and-fuel-scheme.md:79-99`) asks
for "Fuel monotonicity as a generated or generic theorem".

Remedy (M, WITH the fuel-parameter arc so it is stated once over the
parameter): ship the engine-round equations and the `_zero`/`_succ`
lemmas in `CerbND` (or a `CerbND.Contract` module) as the citable
contract, exactly as the `_lemFuel_zero` lemmas are today; fuel
monotonicity lem-side. Grade MINOR — the consumer has it; the next
consumer will not.

### 2.I No-op shims made opaque for "module-shape parity"

`CerbUtils.lean:37-47`: `STD_` is `opaque`, `implemented_by` an
`unsafeBaseIO` that pushes `s` onto `logRef` and returns `x`; the file
says (:33-35) "nothing READS the log — the store exists for parity of
shape only". It has 26 generated call sites in the desugarer
(`Cabs_to_ail_effect.lean:1177-1188` `CerbUtils.STD_ "§6.2.2#3" (…)`):
every theorem through linkage determination meets an opaque that is
provably nothing but the identity — and cannot be proved to be.
`begin_timing`/`end_timing` (:18-29) are opaque no-ops with ZERO
generated callers (measured). `CerbConcurrency.statically_satisfied … :=
true` (:20) is a silent stub with ZERO callers (measured) — where the
zero-discrepancy rule's class (c) demands a loud refusal, not `true`.

The allowlist classes the first two "permanent-declared" ("no-op timing
ref, intentionally unread; OCaml module-shape parity";
`scripts/unsafebaseio_allowlist.txt` rows 1-3). This audit disagrees:
"shape parity" is a property of the hand-written Lean file's LAYOUT, not
of any behaviour; the mirror doctrine wants the same COMPUTATION, and the
same computation here is `x`. Remedy (S): `def STD_ (_ : String) (x : α)
: α := x`; delete `logRef`, `timingStackRef`, both timing opaques and
the dead stub (or make the stub a class-(c) refusal if the concurrency
arc wants a placeholder). 3 opaque rows and 11 PIN rows leave the
allowlist. Grade MINOR.

### 2.J `isLibraryLocation` depends on the path convention

`CerbLocation.lean:184-210`: behaviour-bearing (it decides UB-location
substitution, `core_eval.lem:602`, `core_run.lem:476,781`), it tests
`dir == d || dir.endsWith ("/" ++ d)` because "the Lean process has no
`Cerb_runtime` — the runtime ROOT is not plumbed" (:191-194), with the
residual stated (:197-200). Q3: the meaning depends on where the files
live. The mover is the same parameter-plumbing slice as 2.A ("plumb the
runtime root from Main", :199-200). Grade NOTE — recorded so the
plumbing slice's scope is complete.

### 2.K The trust story is written for the binary

`VALIDATION.md:234-260` enumerates "What remains on the trust boundary"
by MECHANISM (`unsafeBaseIO`/`implemented_by`/`extern` census rows) and
`DESIGN.md` §4 promises "a total Lean artifact the kernel can evaluate
and future consumers can reason about". Neither document tells a
consumer what a theorem about `drive` cannot unfold. The consumer had to
measure it (`README.md:557-570`, citing their `qa2-notes`), listing
eleven constants — of which four (`CerbGlobal.*`), one
(`CerberusImpl.typeof_enum`), one (`CerberusFresh.digest`) and one
(`beqMemValueSafe`) are 2.A/2.C/2.E/2.G above, two are the ruled
instances (`failwithI`, `fuelExhaustedWith`), and two are `partial`
(`normalise_ctype`) or derivation shapes (`Core.instBEqCore_base_type.beq`,
a `termination_by structural` derived function that does not `dsimp`).
Their auditor had to correct the reading of what those mean
(`detailed-audit:485-489`).

Remedy (S): a "Reasoning surface" section in `VALIDATION.md` — for each
exec entry, the opaques / `partial`s / process-state reads in its cone,
each with class and mover — produced from the census that already exists
(`check_theorem_axioms.sh` OPAQUE_WANT, :206-228) partitioned by
reachability. As 2.A/2.C/2.E/2.G/2.I land, the section shrinks to
`fuelExhaustedLoc` and the typed-failure atom. Grade NOTE.

## 3. What is NOT an instance

Things that look execution-shaped but are forced by the lem model, the
OCaml mirror or ISO — so that nobody "fixes" them — and cross-references
to the three ruled instances.

- **The allocator's addresses.** `MemState.lastAddress := 0xFFFFFFFFFFFF`
  (`CerbMem.lean:128`), the descending-cursor `allocateObject`/
  `allocateRegion` (:1859-1905), `deviceRanges = [(0x40000000, 0x40000004),
  (0xABC, 0xAC0)]` (:2004): all mirror `impl_mem.ml:508` (`last_address=
  Z.of_int 0xFFFFFFFFFFFF; (* TODO: this is a random impl-def choice *)`),
  `:1252-1263` and `:620-624`. Cerberus FIXES these; the consumer bakes
  the resulting literal into its demo (`ProdEntry.lean:145-153`,
  `errnoAddr : Int := 281474976710648`) and felt the shift when
  `max_alignment` went 16 → 8 (their `DECISIONS.md:1648`) — but the
  shift was a MIRROR FIX (Z-76), and the number is the model's. Not an
  instance; a tray question at most.
- **LP64 and the implementation record.** `CerberusImpl.max_alignment :=
  8`, `sizeof_integerBaseType`, `sizeof_fty := 8` for `float` ("we mirror
  the BEHAVIOR, hack included", `CerberusImpl.lean:146-157`): ISO
  implementation-defined choices Cerberus's `DefaultImpl` fixes. Not
  instances.
- **Harness-looking fields of the driver state.** `trace`,
  `dr_step_counter`, `blocked`, `symbolic_assoc` (`driver.lem:61-76`),
  `dres_stdout : string` (`:1462-1468`), the `args : List String` of
  `drive`: all model text, identical on the OCaml side. The consumer
  pins them (`ProdEntry.lean:412` `([] : List String)`; `Round.lean:5-19`
  "the trace extended, the step counter moved") — the cost is real but
  the shape is the model's.
- **`Loc` arguments on memory operations.** `storeM (Loc.other "errno
  init") …`, `current_loc := Loc.other "Driver.drive"` — `mem.lem`'s
  interface and `driver.lem:1876-1877` literals. The consumer proved
  location-irrelevance to drop 46 premises (their `DECISIONS.md:618`)
  — a lemma cerberus-lean could ship (a 2.H item), not a shape to change.
- **`setToList` ascending, `choose` = minimum, union representative by
  height.** `LemLib.lean:618-629, 699, 720, 467-486` mirror `pset.ml`
  (`elements`, `choose = min_elt`, the `h1 = 1`/`h2 = 1` short-cuts). lem
  says the order is unspecified (`library/set_extra.lem:86`, `:21`); the
  OCaml fixes it; Lean mirrors the OCaml. Deterministic — and for a
  reasoning consumer, strictly more convenient. Not an instance (it would
  be one if the port had picked a DIFFERENT fixed order than the OCaml).
- **`BEq core_step2`'s `failwithI` arms and the residual comparison
  instances** (`CerbStepInstances.lean:148-165`; lem-lean
  `lean_backend.ml:5831-5845`): they mirror OCaml's polymorphic compare
  RAISING on closures. Same failure class as the ruled instance (2); the
  typed-failure pass owns them.
- **`Ord Loc` is structural, not OCaml's `compare`**
  (`CerbLocation.lean:37-47`, "a deliberate proof-friendliness
  divergence"). The OPPOSITE of the lens — a reasoning-shaped choice —
  and since 2026-09-03 every legacy divergence permission is revoked
  (`VALIDATION.md:228-232`), so it is a zero-discrepancy census row, not
  this audit's. Flagged in §5.
- **`LEAN_ABORT_ON_PANIC` required** (`Main.lean:1063-1067`): the
  binary's meaning depends on an environment variable — Q3 to the letter
  — but it is the harness-side GUARD for ruled instance (2); the typed-
  failure pass removes the need for it. Cross-reference only.
- **`CerbFS`'s 39 `panic!` refusals** (`CerbFS.lean:227-503`): class (c)
  loud refusals in the binary; in-process they denote `default` — ruled
  instance (2)'s shape exactly; the typed-outcome pass owns them.
- **`driveCall` at the fixed `driver2`** (`CerbCall.lean:203`), the
  `driver_globals` phase at fixed `driverFuel` (`CerbND.lean:422-423`),
  the `hack`/`finalize` pure-return sentinel (consumer review §5, TODO
  "The `finalize`/`hack` leaf"), the LemLib computed budgets
  (`LemLib.lean:488-489, 503-504, 518-519, 574-575, 551-552, 669-670,
  975-976, 1014-1015, 1033-1034`) and `lemLeastFixedPoint`'s SILENT
  budget arm (`:729-736`, `| 0 => x` — no sentinel): all ruled instance
  (1); the fuel-parameter design covers them (§2 there names the
  LemLib bounds explicitly). One remark for that arc: `lemLeastFixedPoint
  … | 0 => x` returns a value indistinguishable from convergence — worse
  than the opaque sentinel, and not in the design note's list.
- **The unit gates' `rfl`-at-the-budget shape** (`TotalityProofTest.lean`
  Part 1, `VALIDATION.md:136-138`): execution-shaped by construction
  ("wrapper is defeq to the worker at `lemDefaultFuel`"); the fuel-
  parameter design already restates them as "every fuel'd entry is
  fuel-parametric" (§3 there). Cross-reference only.
- **The 63-bit `lemIntFromInteger`/`lemNatFromNatural` checks**
  (`LemLib.lean:1498-1509`): the referent ruling classifies them kind 2
  and removes them in the fuel-parameter arc. Cross-reference only.
- **`CerbDebug.get_level (_) := 0`** (`CerbDebug.lean:28`): a plain `def`
  of a constant — transparent to the kernel; the OCaml batch driver's
  level is 0 too. Not an instance (and the model of what 2.A Step 1
  should look like).
- **The process-stack ceiling** (`VALIDATION.md:338-354`, `TODO.md:39-66`,
  the mem-scale S1' revert [USER 2026-09-02] "poor roi for a change to
  the trust surface"): a property of the compiled binary's runtime, not
  of the definitions; the kernel and an in-process consumer's `whnf` do
  not share it. The revert kept the model shape — correct under this
  lens.

## 4. Recommended ordering

By consumer cost × trust stability (the standing rule: the reference
model stays the obviously-right mirror; changes to what the model IS
need a ruling; deletions that leave behaviour byte-identical first).

1. **2.A Step 1** — replace the eleven `CerbGlobal` opaques by `def`s of
   the default configuration. S; zero behaviour change (the refs are
   never written — differential battery must show zero movement, and
   would); removes the `cases` from our exemplar and the consumer's
   `driver2_done`; averts the re-pin hit on `killM`. No ruling needed:
   it states what the port already is (matched default-switch mode is
   the harness contract, Z-24). Do it before the consumer re-pins onto
   Z1.
2. **2.I + 2.G** — the deletions: `STD_` as the identity, timing refs
   and the dead stub gone; structural `BEq MemValue`. S; zero behaviour
   change; 4 opaque rows + 13 PIN rows leave the allowlist. Bundle with
   1 as one "opaque-census shrink" slice; plant-test the census gate both
   directions.
3. **2.B** — supply-minted Core symbols, G6 deleted. S-M. This is a
   mirror FIX (OCaml mints from the supply), so it also belongs to the
   zero-discrepancy census; the `--pp-core`/`test_core.sh` lanes compare
   Core text up to renaming (the renumbering ruling), so expected
   movement is zero at the verdict level. Needs the digest parameter
   (2.E) or an explicit `""` at first — do 2.E with it.
4. **2.E** — digest as a parameter; native global, barrier and 7 opaque
   rows deleted. S-M. Same slice as 3.
5. **2.C** — the enum registry as a value. M. Touches the desugarer's
   result type (`.lem` change → OCaml text → fork-drift review) or the
   tagDefs environment; needs a short design note and the consumer's
   read (it changes the `TagDefs` type they thread 223 times, or adds a
   parameter to `drive`). Schedule with the typed-failure pass, which
   otherwise has to invent an outcome for the unregistered arm that this
   change makes unreachable.
6. **2.A Step 2** — configuration as a reader-lifted parameter. M; the
   named mover; after the fuel-parameter arc (same reader machinery,
   same `drive` signature change — one consumer re-pin, not two). Needs
   a ruling on WHICH switches are parameters (the seven in `CerbSwitch`)
   versus fixed by the port (CHERI, PNVI: refused features, class (c)).
7. **2.H** — ship the round library + `_succ` lemmas with the fuel-
   parameter arc's restated contract; fuel monotonicity lem-side. M.
8. **2.K** — the "Reasoning surface" section, written once 1-4 have
   shrunk it. S. (Z4's VALIDATION rewrite is the natural home.)
9. **2.F** — `bounded_integer` as an ND fork; `runND1` with a selector.
   S; changes the exhaustive verdict SET for programs using `bounded`
   (none in any corpus) — a ruling item because it changes what the
   model enumerates.
10. **2.D** — front-end totalization. L; after the fuel-parameter arc;
    when a consumer needs the C entry.
11. **2.J** — runtime root as a parameter; rides 6.

## 5. What I could not settle

- **LemLib's remaining `partial`s and the non-computing `Pmap.join`.**
  `LemLib.lean:1238` (`natSqrtAux`), `:1643-1647` (`lemListUnfoldr`),
  `LemLib/Set_extra.lean:60` (`leastFixedPointUnbounded`) are `partial`
  in the runtime library the whole semantics imports; `Pmap.join` is
  WF-recursive and "every generated function that reaches `join` …
  stops computing on closed terms. Measured consequence on our side at
  `de2fbf1bd`: 17 declarations in 7 files … fail with `Type mismatch
  rfl`" (consumer request `2026-09-03_request-lem-lean-pmap-laws-and-
  fuel-scheme.md:48-56`). The `partial`s are execution-focus in the
  lens's sense (total-by-fuel or by measure is available for all three);
  the WF `join` is the opposite — a kernel-honest totality proof that
  happens not to reduce — and the remedy (structural recursion on the
  stored height) is the consumer's request §2. Both are lem-lean's; the
  request is filed; not graded here.
- **lem `string` as Lean `String`** (lem-lean `2026-09-03_string-
  representation-design.md` §1: `len e-acute: 2` on OCaml vs `1` on
  Lean; §3 "no re-mapping of the operations on Lean's `String` can be
  faithful"): a representation chosen for the host runtime that makes
  theorems over lem strings false of the referent for non-ASCII input —
  Q8 exactly — but it is a zero-discrepancy BUG already scheduled as the
  parity arc's last slice, so it is not re-graded here.
- **Lean `Float` is kernel-opaque** (`Init/Data/Float.lean:22 opaque
  floatSpec`, `:58 @[extern "lean_float_add"] opaque Float.add`).
  `CerbMem.FloatingValue := Float` (`CerbMem.lean:66`) means no theorem
  can compute `(int)1.5`. This is Lean's standard library, not this
  port's choice — but under the referent ruling the question "is the
  referent IEEE 754 or OCaml's `float`?" has an answer (IEEE, which
  OCaml implements), and a bit-level IEEE model would make the semantics
  of floating C reasonable-about. Price L; a design question, not a
  finding.
- **`runND`'s missing constraint pruning** (`CerbND.lean:5-14, 127-136`:
  "NDguard always continues and NDbranch explores both sides … pruning
  is simply not implemented here yet (recorded divergence — survey
  finding 23)"). In the concrete model the oracle evaluates
  `MC_eq/MC_le/…` and prunes UNSAT branches (`impl_mem.ml:321-361`); Lean
  enumerates them. For a consumer the exhaustive verdict SET is an
  over-approximation — a "∀ outcomes" theorem is stronger than the
  oracle's, an "∃ outcome" theorem may cite an infeasible branch. This is
  a semantics divergence (zero-discrepancy census), not an execution-
  focus instance; flagged because every consumer statement is over that
  set.
- **`Ord Loc`** (§3): reasoning-friendly, non-mirror, permission revoked
  2026-09-03; whether the OCaml `compare` on `Cerb_location.t` is even
  observable (no differential output enumerates a `Loc`-keyed set —
  `CerbLocation.lean:44-46`) decides whether it is a bug or a note. Not
  this audit's call.
- **Whether 2.A Step 2 should parameterise ALL switches or only the
  seven in `CerbSwitch`.** `is_PNVI`/`has_strict_pointer_arith` are
  `false` by port scope (PNVI and CHERI are refused features); making
  them parameters would let a theorem quantify over a configuration the
  port does not implement. Ruling item for the plumbing slice.

## Provenance

[USER 2026-09-03]: the question (verbatim, top). [AGENT] (this auditor):
every measurement, grading, remedy and price in §0–§5; the two evidence
sweeps (consumer side; lem-backend emission shapes) were run by
delegated read-only searches and every quote used here was re-read by
this auditor against the named trees. Consumer text is quoted from
refined-cerberus at `5d08237`; cerberus-lean code at `de2fbf1bd`; LemLib
at `3c88f0d`. Docs-only; nothing merged or pushed.
