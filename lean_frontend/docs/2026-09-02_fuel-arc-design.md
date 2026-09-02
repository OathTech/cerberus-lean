# FUEL arc — design note: a kernel-transparent, distinguished fuel-exhaustion outcome

Date: 2026-09-02. Branch `arc/fuel` off mainline `2c7c9347b`. Docs-only
slice (this note); the implementation slice is §6.

Request (verbatim source, read first):
`refined-cerberus/worktrees/audit-response-3/docs/2026-09-02_request-cerberus-lean-fuel-exhaustion-outcome.md`
— the consumer (refined-cerberus / cerberus-heaplang) needs, in the ND
monad, a fuel-exhaustion outcome the kernel can recognise, so that
∀-fuel partial-correctness theorems can be stated over the SHIPPED
driver and the consumer's own `driveU` loop can be deleted (their
operator ruled it out as a root of trust: DECISIONS.md:626, "the actual,
genuine, legitimate, original Cerberus one").

Rulings logged in this note:

- [USER 2026-09-02] mechanism = OPTION A: "Very good, A sounds
  reasonable, go ahead". A = the existing `kill_reason` constructor
  `Error of Loc.t * string` with a RESERVED message, unwrapped (no
  opaque sentinel). Option B (a new `kill_reason` constructor) REJECTED:
  it changes the shared `.lem` type and therefore the generated-OCaml
  text / fork-drift surface, for a constructor the oracle never uses.
- [USER 2026-09-01] standing ordering rule: "order these by
  (performance) * (trust impact) … keep our trust surface stable i.e
  'obviously right' wrt upstream Cerberus".
- [AGENT 2026-09-02, orchestrator; operator-overridable — FLAGGED]: the
  per-declaration fuel BUDGET application (C1 manifest §8's deferred
  item) is BUNDLED into this arc, so the consumer receives one change
  manifest and one re-export. §4.

Facts below were re-verified in the worktree at `2c7c9347b`; every
cite is file:line in that tree unless stated. §0 lists where the
verified tree contradicts the brief this note was written from.

## 0. Brief-vs-tree corrections (headline)

1. **Nine ND-typed sentinels, not six.** The brief's six
   (nondeterminism.lem:555 `nd_bind`, :557 `liftND`, :558 `liftAction`;
   driver.lem:1902 `print_eval_conv_aux`, :1903
   `drive_nonmemory_steps_aux2`, :1904 `driver2`) are joined by three in
   the memory model with the identical ND-killed witness:
   defacto_memory.lem:2674 `find_array_index`, :2675
   `easy_update_mem_value_aux`, :2676 `memcmp_load_aux` (generated
   Defacto_memory.lean:806, :821, :900). They are `impl_memM`-typed
   (defacto_memory.lem:84-85: `ndM 'a string mem_error (mem_constraint
   impl_integer_value) impl_mem_state`), lifted into the driver by
   `liftND`, and their exhaustion is a driver outcome exactly as
   `nd_bind`'s is. All nine are in scope (§1.2).
2. **The driver's `'err` is `driver_error`, not `mem_error`.**
   driver.lem:116: `type driverM 'a = ND.ndM 'a step_kind driver_error
   Mem.mem_iv_constraint driver_state`; `mem_error` appears only wrapped
   (`DErr_memory of Mem_common.mem_error`, driver.lem:57). The export is
   therefore `'err`-POLYMORPHIC (§1.1) — it never mentions `'err`.
3. **The reserved literal cannot be written in the `declare`.** The lem
   backtick lexer excludes `"` (lem-lean `src/lexer.mll:172` `let quote
   = [^'\t''\n''`''"']`, :246 the `BacktickString` rule; LemLib.lean:189-190
   records the same constraint). The sentinel must reference a NAMED
   constant (§1.3 mechanism).
4. **The gcc ledger's fuel rows are `SKIP_LEAN_CRASH`, not
   `SKIP_LEAN_FAIL`**: `scripts/gcc_oracle_baseline.txt:1145`
   `csmith/sia_csmith_477.c SKIP_LEAN_CRASH -`, :1437
   `csmith/sia_csmith_769.c SKIP_LEAN_CRASH -`; the lane record names
   them as the fuel deaths (docs/2026-08-30_gcc-oracle-lane-record.md:71:
   "csmith sia_477/769 (`lem: fuel exhausted` = the committed LEAN_CRASH
   rows)"). The same two files are `LEAN_CRASH` in
   `scripts/exec_csmith_corpus_baseline.txt:1177,1469`.
5. Consequently the C1 manifest's apply-condition measurement
   (docs/2026-08-31_C1-change-manifest.md:171-176, "zero current lane
   baselines contain a fuel-exhaustion row (measured: grep …)") was a
   measurement of the literal TEXT in baseline files (true: no baseline
   file contains "fuel" as a row token) but four committed baseline
   rows ARE fuel deaths by the lane record's own attribution. This is a
   candidate erratum to a committed record; per house rule it needs a
   second independent verification before the record is amended — it
   is FLAGGED here, not fixed (§7 Q5).
6. LemLib cites: `fuelExhaustedWith` is at `lean-lib/LemLib.lean:184-187`,
   `fuelExhausted` at :192-193, `lemDefaultFuel := 1000000` at :56
   (brief said ~170-186).
7. Main.lean has TWO kill-printing paths: batch (`Error {msg: "…"}`,
   Main.lean:918-919 — what every harness parses) and non-batch
   (`result: Killed (error: {msg})`, :948-950). The brief cited only the
   latter. Batch exit code for a single Killed execution is 1
   (Main.lean:925-928, mirroring OCaml main.ml runM).
8. The lem backend still has a `sorry` target_rep special case
   (lem-lean `src/lean_backend.ml:4044-4050`: "sorry is a term, not a
   function — drop applied arguments … `(sorry : T)`"), while the same
   file's header claims "sorry-emission paths are gone (fail-closed,
   arc-8 S2)" (:84). §5 rider.
9. A second candidate rep for the `sorry` already exists:
   `CerbPP.lean:228` `def pretty_stringFromMem_mem_value {α : Type}
   (_ : α) : String := "<mem_value>"  -- [PRETTY]`, the rep pp.lem:104
   uses. It is a stub; §5 chooses the real printer.
10. The L1 budget form takes an INTEGER LITERAL only (lem-lean
    `src/ast.ml:516` `Decl_fuel_budget_decl … (Z.t * string)`); the
    wrapper is emitted with the numeral, not a named constant. §4.3.
11. `prune/relsem` exists as a worktree
    (`worktrees/cerberus-lean-prune/relsem`) at `2c7c9347b` with NO
    commits yet; the §6 dependency is on work not yet landed.

## 1. CUSTOMER CONTRACT (standalone for refined-cerberus)

This section is self-contained: a consumer can read it without the
rest of the note. Names are final unless §7 changes them; the consumer
is invited to object before the implementation slice.

### 1.1 The export

```lean
-- lean_frontend/CerbFuel.lean  (hand-written seam, imported by the
-- generated Nondeterminism.lean; THE single occurrence of the literal)
namespace CerbFuel
def fuelExhaustedMsg : String := "lem: fuel exhausted"
end CerbFuel

-- lean_frontend/CerbND.lean  (hand-written seam; already home of runND)
namespace CerbND
/-- The distinguished fuel-exhaustion kill. `'err`-polymorphic: it never
    mentions the error type, so it is the same value in `driverM`
    (`kill_reason driver_error`) and `impl_memM` (`kill_reason mem_error`). -/
def fuelExhaustedKill {err : Type} : kill_reason err :=
  Error0 CerbLocation.Loc.unknown CerbFuel.fuelExhaustedMsg
end CerbND
```

`kill_reason` is the generated type (Nondeterminism.lean:54-62;
constructors `Undef0 | Error0 | Other`, the lem-mangled names of
nondeterminism.lem:19-22 `Undef | Error | Other`; the OCaml side carries
the same mangled names, backend/common/driver_ocaml.ml:173-179).
The `'err` instantiation the consumer's driver theorems need is
`driver_error` (driver.lem:116); nothing in the contract depends on it.

### 1.2 The guarantee (the fuel-zero arms)

For each of the NINE ND-typed fueled workers, the generated fuel-zero
arm is, with NO opaque wrapper,

```lean
| 0 => ND (fun st => (NDkilled (Error0 CerbLocation.Loc.unknown CerbFuel.fuelExhaustedMsg), st))
```

(`liftAction` returns `nd_action`, not `ndM`, and is curried on its
scrutinee, so its arm is `fun _ => NDkilled (Error0 … fuelExhaustedMsg)`;
`drive_nonmemory_steps_aux2` has a trailing curried list argument, so
its arm is `fun _ => ND (fun st => …)`. These are the SAME shapes the
arms have today, minus `fuelExhausted (…)`.)

Shipped, kernel-checked (`rfl`), one per worker — the form the consumer
should cite rather than the generated text:

| lemma (namespace `CerbND`) | statement |
|---|---|
| `driver2_lemFuel_zero` | `driver2_lemFuel 0 c = ND (fun st => (NDkilled fuelExhaustedKill, st))` |
| `print_eval_conv_aux_lemFuel_zero` | likewise, over its arguments |
| `drive_nonmemory_steps_aux2_lemFuel_zero` | `drive_nonmemory_steps_aux2_lemFuel 0 acc xs = ND (fun st => (NDkilled fuelExhaustedKill, st))` |
| `nd_bind_lemFuel_zero` | `nd_bind_lemFuel 0 m f = ND (fun st => (NDkilled fuelExhaustedKill, st))` |
| `liftND_lemFuel_zero` | likewise |
| `liftAction_lemFuel_zero` | `liftAction_lemFuel 0 get put li le act = NDkilled fuelExhaustedKill` |
| `find_array_index_lemFuel_zero`, `easy_update_mem_value_aux_lemFuel_zero`, `memcmp_load_aux_lemFuel_zero` | likewise (`impl_memM`) |

Why the arm names the message constant and not `fuelExhaustedKill`
itself: `kill_reason` is DEFINED in the generated Nondeterminism.lean,
so no hand-written seam imported by that file can mention it; and the
literal cannot appear in a `declare` (§0.3). The `_zero` lemmas close
the gap by `rfl` (one delta step on a plain `def`); the kernel sees the
same term either way.

The wrappers are unchanged in kind: `driver2 = driver2_lemFuel <budget>`
(Driver.lean:386 today: `driver2_lemFuel lemDefaultFuel`; after §4 the
family's budget is `CerbFuel.driverFuel`), so a statement over the
shipped `driver2` is a statement over `driver2_lemFuel` at a known
fuel, and a `∀ fuel` statement over `driver2_lemFuel` specialises to it.

### 1.3 Distinctness — the lemmas and the invariant

```lean
theorem fuelExhaustedKill_ne_Undef0 : fuelExhaustedKill (err := err) ≠ Undef0 loc ubs
theorem fuelExhaustedKill_ne_Other  : fuelExhaustedKill (err := err) ≠ Other e
def  isFuelExhaustedKill : kill_reason err → Bool
theorem isFuelExhaustedKill_iff : isFuelExhaustedKill r = true ↔ r = fuelExhaustedKill
instance : DecidablePred (fun r : kill_reason err => r = fuelExhaustedKill)
```

The first two are by constructor disjointness. `isFuelExhaustedKill`
matches `Error0 CerbLocation.Loc.unknown s` and decides `s =
CerbFuel.fuelExhaustedMsg` (String has decidable equality); the `iff`
is by cases. This is the "decidable equality on status" the request
asks for, delivered as the decidable predicate actually needed —
`kill_reason` derives only `BEq, Ord` (Nondeterminism.lean:62) and a
full `DecidableEq (kill_reason err)` would need `DecidableEq` on `Loc`
and `undefined_behaviour`; it is added if it falls out cheaply, not
promised.

**The distinctness INVARIANT (gate-enforced, §6):** the reserved
literal `lem: fuel exhausted` appears, as a token in comment-stripped
source, in exactly ONE place in the cerberus-lean tree — the
`CerbFuel.fuelExhaustedMsg` definition (and its byte-identical copy in
`generated/`, which the hand-written-sync gate already pins). It
appears in no `.lem` model source, no other hand-written seam, no
generated module. Every kill the SEMANTICS produces (`kill (Error loc
msg)` sites in the model) carries a message that is a different
literal or a literal-prefixed string; the implementation slice
ENUMERATES every `Error`-kill site in `frontend/` and records that none
can evaluate to the reserved message (a message built from program
text — identifiers, string literals — always carries a model-side
prefix). Meaning: **no C program's semantics can produce
`fuelExhaustedKill`**; a run whose status is `Killed _ fuelExhaustedKill`
ran out of fuel, and nothing else. The LemLib panic message of the
pure-worker sentinel (`fuelExhausted`, LemLib.lean:192-193) is the same
string, but it is a runtime STDERR text of an opaque constant, never a
`kill_reason` value; it is outside the invariant's scope and stays.

Propagation: `nd_bind`'s `NDkilled` arm re-emits the kill unchanged
(nondeterminism.lem:57-, generated :190); `liftAction`'s `Error` arm
is the identity (`Error loc str -> Error loc str`, nondeterminism.lem:
249-257). So the kill is stable under bind and under lifting from
`impl_memM` into `driverM`: an exhausted memory worker surfaces as the
driver's `fuelExhaustedKill`, not as a rewritten message.

### 1.4 The acceptance criterion, restated against these names

`CerbND.runND` returns `List (nd_status a err st × List String × st)`
with `nd_status = Active a | Killed st (kill_reason err)`
(Nondeterminism.lean:584-590; CerbND.lean:136-138). The request's

    theorem <program>_certified_shipped (fuel : Nat) … :
      ∀ o ∈ runND (driver2_lemFuel fuel fmapEmpty false) dst₀,
        o.status = NDkilled FuelExhausted ∨ (o is Active-done ∧ post o.state)

becomes, over the shipped names,

```lean
theorem <program>_certified_shipped (fuel : Nat) … :
  ∀ o ∈ CerbND.runND (driver2_lemFuel fuel tds false) dst₀,
    (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)
```

with `dst₀ := (initial_driver_state sup file fs).1` (the consumer's own
production entry, ProdEntry.lean:8-9), and `driveU` deleted from every
export. The `∀ fuel` induction is the consumer's (request item 4).

### 1.5 Not provided

- **Fuel monotonicity** for the driver workers: not provided (request
  item 4: "welcome but not required"). Note the runner already has
  `runNDFuel_mono` for ITS fuel (CerbND.lean header) — a different fuel,
  see §7 Q3.
- **A distinguished runtime EXIT CODE** for fuel exhaustion: not
  provided; the kill exits 1 like every `Error` kill, mirroring OCaml
  (Main.lean:925-928). Classification is by the message (§3).
- **The pure-return workers** (`hack`, driver.lem:1905 `fuelExhausted
  Vunit`; the ~58 others across frontend/model, e.g. the
  `Core_reduction`/`Defacto_memory` pure arms at Defacto_memory.lean:285,
  :735) keep the opaque `fuelExhausted` sentinel and its panic (request
  item 3). Their exhaustion is a `PANIC` (exit 134, message on stderr),
  never a kill.

## 2. TRUST-STORY ANALYSIS

The operator's question: does this move the trust surface relative to
upstream Cerberus? Answer by parts.

**Fuel is a port-side artifact with no upstream counterpart.** The lem
model's recursion (`let rec driver2`, driver.lem:1369; `let rec
nd_bind`, nondeterminism.lem:57) is unbounded; OCaml runs it as is. The
Lean target makes it total by fuel (arc-3), via `declare {lean} fuel
val f = \`<lean expr>\`` — 67 such declares in `frontend/` (grep
`declare {lean} fuel val`), all `{lean}`-scoped, all rendered ONLY in
the Lean emission. The sentinel text is written verbatim in the
declare; the lem backend does not synthesize it (lean_backend.ml
`fuel_sentinel` map; the L1 record §Feature 3).

**The mirrored semantics and the OCaml text are unchanged — by
construction, and gate-verified.** Every edit in §1 is in a `{lean}`
declare (nine sentinel bodies, one `declare {lean} extra_import
\`CerbFuel\`` in nondeterminism.lem — the mechanism debug.lem:4 already
uses) or in hand-written Lean. The OCaml emission does not read them.
Verification is not "we believe so": the standing fork-drift gate
(`scripts/check_fork_drift.sh`, Layer 2) diffs this repo's
`ocaml_frontend/generated` against the upstream-pristine tree and
requires the differing set to equal the manifest's hash-pinned entries.
This arc adds ZERO entries to `scripts/fork_drift_manifest.txt`; the
gate staying green at the implementation head is the byte-identity
proof. (Contrast B: a new `kill_reason` constructor lands in
nondeterminism.ml, breaks exhaustiveness at driver_ocaml.ml:173-182,
and requires a manifest entry — oracle-surface movement for a value the
oracle never constructs. Under (performance)×(trust impact) A and B
have the same kernel transparency and the same runtime cost; B's trust
impact is strictly larger. Rejected.)

**Sufficient-fuel behaviour is unchanged.** The `Nat.succ` arms are
untouched; every run that completes today completes with the same
verdict. The differential battery (§6) is the check, at its committed
baselines, byte-at-baseline except the enumerated FUEL rows (§3.3).

**Exhaustion behaviour changes, from a crash to a typed kill.** Today: a
driver fuel death is `fuelExhausted (ND …)` → `fuelExhaustedWithImpl`
panics (LemLib.lean:184-187) → exit 134 under `LEAN_ABORT_ON_PANIC=1`,
`lem: fuel exhausted` on stderr, classified LEAN_CRASH. After: the
driver returns `Killed st fuelExhaustedKill`, Main prints `Error {msg:
"lem: fuel exhausted"}` (batch) and exits 1. Loudness is preserved at
the HARNESS level (request item 2): every lane classifies the exact
message as FUEL, fail-noisy, never agreement (§3). Nothing becomes
quieter; what was a crash is now a reported, typed outcome that the
harness can also count.

**The new risk, named: distinctness is by CONVENTION** (a reserved
string on a general-purpose constructor), where B would have made it
STRUCTURAL. Mitigations, each independently checkable:
1. the reserved-literal gate (§1.3 invariant; §6 plants) — the literal
   occurs once, by construction of the scan;
2. the `Error`-kill-site enumeration (implementation slice, recorded);
3. the named export + `_zero` lemmas — consumers never spell the
   string; a change to it is a change to one definition and its gate;
4. the `Loc.unknown` component — model `Error` kills carry a location;
5. the FUEL harness class is never counted as agreement, so a
   mis-classified fuel death cannot pass a lane silently.
Residual: a future model edit that kills with a computed message equal
to the literal would be caught only by (2) at review time, not by the
token gate. Accepted, recorded.

**A second fuel exists and is outside this contract.** `CerbND.runND`
is itself fuel-totalized (`runNDFuel`, budget `ndDefaultFuel :=
lemDefaultFuel`, CerbND.lean:71, :89-134); its fuel-zero leaf is
`panic!` returning `[]` — proof-transparent, "an exhausted leaf CLAIMS
no behaviors" (CerbND header). Under the consumer's `∀ o ∈ runND …`
shape, runner exhaustion drops executions rather than producing a
classifiable `o`; that is a completeness loss the CerbND header already
records, not a soundness loss, and it is unchanged here. Whether the
runner leaf should ALSO become `[(Killed st fuelExhaustedKill, [], st)]`
is a genuine question for the consumer (§7 Q3), not a decision of this
note.

**VALIDATION.md — the paragraph that replaces today's fuel text**
(VALIDATION.md:218-221, "`lemDefaultFuel` = 10^6 … exhaustion aborts
with `lem: fuel exhausted` (LEAN_CRASH class). Raise is lem-side"):

> - **Fuel exhaustion is a typed, distinguished outcome** for the ND
>   monad's fueled workers (the driver loop family and the memory-model
>   ND workers): the fuel-zero arm is `NDkilled CerbND.fuelExhaustedKill`
>   (= `Error0 Loc.unknown "lem: fuel exhausted"`, transparent to the
>   kernel; `_zero` lemmas by `rfl`; distinctness lemmas + the
>   reserved-literal gate `check_fuel_literal.sh` make it a kill no
>   program semantics can produce). Budgets: the coupled driver family
>   (`driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`,
>   `hack`, `nd_bind`, `CerbND.ndDefaultFuel`) runs at
>   `CerbFuel.driverFuel` = 10^8; every other fueled declaration keeps
>   `lemDefaultFuel` = 10^6 (the L1 opt-in guarantee). Pure-return
>   workers keep the opaque panicking sentinel (exit 134, `lem: fuel
>   exhausted` on stderr). Every lane classifies BOTH as the FUEL class
>   (fail-noisy, never agreement): the typed kill by its exact message
>   in `Error {msg: …}`, the panic by its stderr marker. Record:
>   `docs/2026-09-02_fuel-arc-design.md`.

## 3. HARNESS CLASSIFICATION

### 3.1 What a fuel death looks like, after

| source | stdout (batch) | stderr | exit |
|---|---|---|---|
| ND worker (nine) | `Error {msg: "lem: fuel exhausted"}` (Main.lean:918-919; non-batch: `result: Killed (error: lem: fuel exhausted)`, :948-950) | — | 1 |
| pure worker (`hack` + ~58) | none | `PANIC … lem: fuel exhausted` (LemLib.lean:184-187) | 134 |
| runner (`runNDFuel`) | `Error {msg: "cerberus-lean: runND returned no executions"}` when the whole run exhausts (Main.lean:900-902) | `PANIC at CerbND.runNDFuel …` | 1 |

### 3.2 Where today's classifiers would put it, and the fix

Today's lanes only look for `fuel exhausted` inside the exit ≥ 128
branch: test_exec.sh:534-548, test_gcc_oracle.sh:416-420,
test_ci_sweep.sh:296-299, test_cn_coverage.sh:389-394 — all `grep -m1 -E
'PANIC|fuel exhausted'` on the crash path. An exit-1 `Error {msg: "lem:
fuel exhausted"}` never reaches them; it falls through to:

- test_exec.sh:560-570 `*'Error {'*` → **FAIL** (`LEAN_FAIL`, "Lean
  pipeline error(s)", fatal, :839-841);
- test_gcc_oracle.sh:421-424 → **SKIP_LEAN_FAIL** with the msg;
- test_ci_sweep.sh, test_cn_coverage.sh → their `Error {` / unexpected-
  output rows (FAIL-class);
- tests/mem-scale-probes/measure.sh:106-112 → no marker at all (it
  tags only `capped: (OOM-)?KILLED`, `INTERNAL PANIC`, HANG) — the row
  would read as a completed run with a NONE verdict.

So the class is inserted, in every lane, keyed on the EXACT reserved
message (never the loose `fuel exhausted` regex on stdout), at two
points: (a) in the exit ≥ 128 branch, when stderr carries the marker →
`FUEL` (sub-kind `panic`); (b) BEFORE the `Error {` / `SKIP_LEAN_FAIL`
fall-through, when stdout carries `Error {msg: "lem: fuel exhausted"}` →
`FUEL` (sub-kind `kill`). Row names per lane: `FUEL` (test_exec,
test_ci_sweep, test_cn_coverage, measure.sh note `FUEL(kill|panic);`),
`SKIP_LEAN_FUEL` (gcc ledger taxonomy, `scripts/gcc_oracle_baseline.txt`
header + docs/2026-08-30_gcc-second-oracle-design.md's class table).
Semantics, uniform: fail-noisy (fatal in default mode exactly as
LEAN_CRASH is: test_exec.sh:814 status list gains `FUEL`); baselined
rows are honoured only by the `--check-baseline` machinery; NEVER
counted as MATCH/AGREE, never as "completed" in measure.sh's parity
tallies. The classifier is factored once into `scripts/common.sh`
(`classify_fuel_outcome <exit> <stdout> <stderr>`) so the five lanes
cannot drift from each other.

Main.lean is NOT changed by the mechanism: the existing `Error0` arms
print the message. (A driver-side "FUEL" banner would be a second
convention to keep in sync; declined.)

### 3.3 Baseline movement expected (enumerated from the records)

| lane / record | row | today | after the mechanism alone | after the §4 budget |
|---|---|---|---|---|
| `scripts/gcc_oracle_baseline.txt:1145` | `csmith/sia_csmith_477.c` | SKIP_LEAN_CRASH | SKIP_LEAN_FUEL | measured at implementation (may AGREE) |
| `scripts/gcc_oracle_baseline.txt:1437` | `csmith/sia_csmith_769.c` | SKIP_LEAN_CRASH | SKIP_LEAN_FUEL | likewise |
| `scripts/exec_csmith_corpus_baseline.txt:1177` | `sia_csmith_477.c` | LEAN_CRASH | FUEL | likewise |
| `scripts/exec_csmith_corpus_baseline.txt:1469` | `sia_csmith_769.c` | LEAN_CRASH | FUEL | likewise |
| mem-scale record (docs/2026-09-02_mem-scale-record.md:685,699,700,703,704; not a gate baseline) | `b_zero_local_1000000`, `d_loop_100000`, `d_loop_1000000`, `e_memcpy_100000`, `e_memcpy_1000000` | BLOCKER: C8 (fuel), exit 134 | FUEL(kill) rows | expected to complete (§4.4) |
| mem-scale record :731 | `b_zero_local_10000000` | out of domain (oracle TIMEOUT; Lean fuel) | FUEL(kill) | still out of domain (oracle) |

Every other committed baseline has zero fuel rows (`LEAN_CRASH` counts:
exec_baseline 0, exec_ci 0, exec_coverage 0, exec_debug 0, cn_coverage
0, immaculate 0; exec_debug_baseline.txt:11 mentions "fuel" only in a
header comment). Any row moving that is not in this table is a
FINDING, not a re-baseline.

Whether the two csmith rows were driver-fuel deaths (→ kill) or
pure-worker deaths (→ still a panic, now classed FUEL(panic)) is
determined at implementation; either way they leave LEAN_CRASH.

### 3.4 Plants (vacuity must be loud)

- Classifier selftest (`scripts/test_unit.sh` leg): fixture triples →
  expected class, including the three negatives (a non-reserved `Error
  {msg: …}` → FAIL-class, a PANIC without the marker → LEAN_CRASH, a
  stdout line containing the words "fuel exhausted" in a program's own
  output → NOT FUEL).
- One end-to-end witness at implementation time, recorded verbatim in
  the slice record: a scratch build with a tiny local budget
  (`declare {lean} fuel val driver2 = 1000` in a throwaway worktree)
  run through each lane, showing the FUEL row appear and the lane go
  red. This is a witness, not a standing gate (a standing gate would
  need a second binary).

## 4. BUDGET APPLICATION (bundled; [AGENT] assumption, operator-overridable)

### 4.1 The decision being applied

Record-and-defer, C1 manifest §8 (docs/2026-08-31_C1-change-manifest.md:
158-188) and the adoption record (docs/2026-09-01_C1-adoption-record.md:
183-191): **10^8 on the whole coupled family** — driver.lem quartet
`print_eval_conv_aux`, `drive_nonmemory_steps_aux2`, `driver2`, `hack`;
substrate `nd_bind`; hand-written `CerbND.ndDefaultFuel`. Coupling
analysis: docs/2026-08-31_stack-ceiling-design.md:139-146 — the trees
the runner walks are built by `nd_bind`'s own fuel, so "raising any ONE
member is vacuous". Sizing: stack-ceiling §6b / C1 §8 — at measured
fuel rates a 10^8 budget puts the loud edge at ~7-50 min of
single-invocation stepping, below the grind horizon; 10^9+ would not
be.

Why bundle ([AGENT], the orchestrator's assumption): the mechanism
already re-states the consumer's fuel-zero shape; landing the budget
separately would re-open the consumer's side conditions a second time
(the exact churn C1 §8 deferred to avoid). The operator may unbundle;
§1-§3 stand alone if so.

### 4.2 Mechanism

The L1 opt-in form, per member: `declare {lean} fuel val driver2 =
100000000` beside the existing sentinel declare (the backend REQUIRES
the sentinel on the same val, lean_backend.ml:556-575, and refuses a
non-positive literal and a target_rep'd or spec-only val: :576-599 —
all fail-closed at generation). Unannotated declarations keep
`lemDefaultFuel` byte-for-byte (the L1 record, "opt-in constraint held
structurally"). `CerbND.ndDefaultFuel` is hand-written (CerbND.lean:71)
and moves in the same commit.

Family membership beyond the recorded six is NOT extended here: `liftND`
/`liftAction` and the three defacto workers keep `lemDefaultFuel`.
Reason: their fuel counts the depth of a single lifted memory action's
tree (`liftND`) or a per-operation recursion bounded by the operand
(`find_array_index` by the array size, `memcmp_load_aux` by the byte
count) — a different measure from the driver's step count, and no
recorded fuel death names them. The FUEL class makes any such death
visible; membership is revisited on evidence (§7 Q4).

### 4.3 The consumer side-condition statement

The budget form emits the NUMERAL into the wrapper (`def driver2 … :=
driver2_lemFuel 100000000`), not a name (§0.10). To give the consumer a
citable constant, `CerbFuel.lean` also defines `def driverFuel : Nat :=
100000000` and `CerbND` ships `driver2_wrapper_defeq : driver2 =
driver2_lemFuel CerbFuel.driverFuel := rfl` (and siblings for the
quartet + `nd_bind`), with `driverFuel_eq : CerbFuel.driverFuel =
100000000 := rfl`. Statement for the consumer's manifest: **every
exported statement over the drive cone (`drive`, `driver2`, `nd_bind`,
`runND`) has fuel side condition `CerbFuel.driverFuel` (= 10^8); every
other declaration's side condition remains `lemDefaultFuel` (= 10^6)
verbatim.** Their `driver2 = driver2_lemFuel lemDefaultFuel` `rfl`s
(the shape of relsemcore/RelSem/Cerberus.lean:183-184, which the prune
retires) stop being `rfl` and are re-stated against `driverFuel`.

### 4.4 Expected differential effect

Improvements, enumerated at implementation by MEASUREMENT (the record
is the evidence, not this prediction): the five mem-scale C8 rows
(§3.3) — at the stack-ceiling note's measured ~55-61 fuel per plain
loop iteration, `d_loop_1000000` needs ~6×10^7 fuel, inside 10^8; the
memcpy and zero-local rows are the same order. The two csmith rows may
or may not fit. No sufficient-fuel verdict changes (§2).

### 4.5 The grind tripwire

A 10^8-fuel exhaustion is 7-50 minutes of stepping — approaching the
~1 h tripwire — and a program that exhausts 10^8 can now run that long
before its FUEL row. Discipline is unchanged and is what bounds it: every
lane runs under `capped` with a `TIMEOUT_SECS` far below that edge (a
TIMEOUT row fires first on every gate lane; only the mem-scale
instrument, at 600 s, and deliberate single-invocation probes can reach
the fuel edge); no heartbeat/maxRecDepth/budget bump is ever a fix
(registered defect shape). Nothing here changes loudness: a fuel death
is a typed kill or a panic, never a silent verdict.

## 5. THE `sorry` CLOSURE (rider)

Fact: the tree has exactly one real `sorry` — frontend/concurrency/
cmm_op.lem:17 `declare lean target_rep function
pretty_stringFromMem_mem_value = \`sorry\`` → generated Cmm_op.lean:292
`(sorry : String)` twice in the `"CONCUR CHOSE ==> "` debug-log string
(the request's "Also observed"). The val is POLYMORPHIC: cmm_op.lem:14
`val pretty_stringFromMem_mem_value: forall 'a. 'a -> string` (the
comment above it: "It was not type checking with Mem.mem_value"); its
OCaml rep is `String_mem.string_pretty_of_mem_value_decimal` (:15).
The backend renders `sorry` specially — drops the applied argument and
emits `(sorry : <type>)` (lean_backend.ml:4044-4050) — which is why the
argument `y`/`z` vanished from the generated text.

Do the types line up with the real printer? At the only use site
(cmm_op.lem:380 `pretty_stringFromMem_mem_value y ^ " --- " ^ … z`) the
generated pair is typed `CerbMem.MemValue × CerbMem.MemValue`
(Cmm_op.lean:283-292), so a MONOMORPHIC Lean rep `CerbMem.MemValue →
String` typechecks at both applications (lem does not type a
target_rep; Lean does, at the sites). Two candidates:

- `CerbMem.stringFromMemValue : MemValue → String` (CerbMem.lean:1731) —
  needs NO import change (Cmm_op.lean already imports Mem, which imports
  CerbMem: Mem.lean:5). `CerbPP.stringFromMem_mem_value`
  (CerbPP.lean:173-174) is literally this function wrapped, and using it
  would need `extra_import \`CerbPP\`` pulling `Core` into Cmm_op's
  import closure (cycle-free — Core.lean imports Cmm_csem, not Cmm_op —
  but heavier for nothing). **Chosen: the CerbMem rep.**
- `CerbPP.pretty_stringFromMem_mem_value {α} (_ : α) : String :=
  "<mem_value>"` (CerbPP.lean:228, the `[PRETTY]` stub pp.lem:104 uses)
  — types line up exactly but prints a placeholder. Declined: closing a
  `sorry` with a stub is the wrong kind of closure.

Mirror-OCaml note to put in-code at the declare: the OCaml rep is the
PRETTY decimal printer; `CerbMem.stringFromMemValue` mirrors
`String_mem.string_of_mem_value` — a deliberate divergence in a
debug-log string of the concurrency model (never oracle-compared),
recorded, not accidental.

Riders bundled with the slice:
- **The `sorry`-token source leg** in the ratchet: a comment-stripped
  scan for the token `sorry` over `lean_frontend/generated/*.lean`,
  `lean_frontend/*.lean`, and the LemLib copy
  (`lean_frontend/.lake/packages/LemLib/`), expected count 0 — today the
  axiom gates check `sorryAx` only in probed cones
  (scripts/check_theorem_axioms.sh:31, :506, :579) and no source scan
  exists. Vacuity plant: an empty scan set is FAIL; a planted `sorry`
  token in a temp copy of a generated file is red; the token inside a
  comment or string is NOT counted (the strip is the point).
- **Backend rider (next lem arc, class 0 — Lean emission only):**
  delete the `sorry` special case at lean_backend.ml:4044-4050 and fail
  closed ("Lean backend: target_rep `sorry` refused") — making the
  header's :84 claim true. Registered here; not in this arc (two-repo
  pin dance).

## 6. SLICES + GATES

**One implementation slice**, dispatched AFTER `prune/relsem` merges.
Dependency, precisely: `prune/relsem` (worktree present at `2c7c9347b`,
no commits yet) will touch the RelSem-referencing set — Main.lean
(`RelSem.Cerb.callND`, :880-884), scripts/check_theorem_axioms.sh and
check_exec_totality.sh (cone/census entries), scripts/test_verify.sh,
test_immaculate.sh, lean_probe.sh, lean_frontend/lakefile.toml. This
arc touches: frontend/model/{nondeterminism,driver,defacto_memory}.lem
(declares only), frontend/concurrency/cmm_op.lem:17, NEW
lean_frontend/CerbFuel.lean + handwritten_copy.manifest,
lean_frontend/CerbND.lean, scripts/common.sh + the four lane scripts +
tests/mem-scale-probes/measure.sh, NEW scripts/check_fuel_literal.sh
(+ the sorry leg, kept in its own script to stay out of
check_theorem_axioms.sh), the two csmith baselines, VALIDATION.md,
LADDER.md (Tier A row for the new gate), TODO.md (the ceiling entry
:21-30 re-stated). Overlap is avoided by design (Main.lean untouched;
census script untouched); the ordering is still required because the
full battery must be run at a head that contains both.

Gates (full battery per scripts/LADDER.md Tier A+B, plus the gcc lane
and csmith), and the plants:

| gate | red-plant |
|---|---|
| `check_fuel_literal.sh` — reserved-literal token count == 1, at `CerbFuel.lean` (+ its `generated/` copy) | (a) plant the literal in a model `.lem` comment-stripped body → red; (b) delete the `CerbFuel` def → count 0 → red (vacuity) |
| the nine `_zero` lemmas + distinctness lemmas, in a `check_theorem_axioms.sh` cone probe (no `sorryAx`, no `ofReduce*`) | replace a `rfl` with `sorry` in a scratch → red |
| `check_fork_drift.sh` Layer 2 byte-green with ZERO manifest change | (the OCaml-neutrality proof; a planted `.lem` body edit → red, already plant-tested) |
| `check_handwritten_sync.sh` — `CerbFuel.lean` in the manifest and byte-pinned | unlisted file → red (existing behaviour) |
| FUEL class: classifier selftest + the recorded end-to-end witness (§3.4) | fixture negatives; the tiny-budget witness |
| `sorry`-token leg | planted token → red; empty set → red |
| Differential: Tier A+B byte-at-baseline; gcc lane + csmith at baseline with exactly the §3.3 movement | any other row moving is a finding |

Consumer change manifest (what the re-export carries):
- names: `CerbFuel.fuelExhaustedMsg`, `CerbFuel.driverFuel`,
  `CerbND.fuelExhaustedKill`, `CerbND.fuelExhaustedKill_ne_Undef0`,
  `CerbND.fuelExhaustedKill_ne_Other`, `CerbND.isFuelExhaustedKill`,
  `CerbND.isFuelExhaustedKill_iff`, the nine `CerbND.<worker>_lemFuel_zero`,
  the wrapper `rfl`s `CerbND.<member>_wrapper_defeq` against `driverFuel`;
- the fuel side-condition statement of §4.3;
- the deleted-`driveU` expectation: the consumer's partial-correctness
  exports (API.lean:77-78, TotalAdequacy.lean:36-39, PROVISIONAL over
  `driveU`; 149 `driveU` references across 10 files at the audit-
  response-3 head) are re-stated over `driver2_lemFuel` per §1.4 and
  the PROVISIONAL label is removed by the consumer.

## 7. OPEN QUESTIONS (genuine)

- **Q1 (consumer) — two namespaces.** `fuelExhaustedMsg`/`driverFuel`
  live in `CerbFuel` (must precede the generated Nondeterminism.lean);
  `fuelExhaustedKill` and the lemmas live in `CerbND` (must follow it,
  and is already the consumer's import for `runND`). Acceptable, or is a
  post-Nondeterminism `CerbFuel` (with the message constant moved into
  `CerbLocation.lean`, next to `Loc.unknown`) preferred?
- **Q2 (operator) — `liftAction`'s arm shape.** It is `fun _ => NDkilled
  fuelExhaustedKill` (returns `nd_action`, curried scrutinee) — the same
  value, different shape from the eight `ND (fun st => …)` arms. The
  `_zero` lemma states it as such. Any reason to want the generated
  arm to match the ND shape (it cannot, by type)?
- **Q3 (consumer) — the runner's own fuel.** `runNDFuel 0 = []`
  (panic marker) drops executions; under `∀ o ∈ runND …` that is
  vacuous, not classified. Should the runner leaf become `[(Killed st
  fuelExhaustedKill, [], st)]`? It is a one-line CerbND change but it
  alters the runner's soundness story (`runND_sound`, in the RelSem
  layer being pruned) and the "runND returned no executions" batch
  error path (Main.lean:900-902). Not decided here.
- **Q4 (operator) — budget family membership.** `liftND`/`liftAction`
  and the three defacto ND workers keep 10^6 (§4.2 reasoning). Confirm,
  or extend the family to all nine on the principle "one measure, one
  budget" (cost: none at runtime; benefit: fewer distinct side
  conditions)?
- **Q5 (operator) — erratum to C1 §8.** §0.4-5: the "zero fuel rows"
  apply-condition statement is contradicted by the gcc lane record's
  attribution of sia_477/769. Second independent verification wanted
  before the C1 manifest is amended (house rule on errata).
- **Q6 (consumer) — `DecidableEq`.** Is the decidable predicate `r =
  fuelExhaustedKill` (§1.3) sufficient, or is a full `DecidableEq
  (kill_reason driver_error)` required by some proof shape? The latter
  needs `DecidableEq` on `Loc` and `undefined_behaviour` (derivable but
  not free).
