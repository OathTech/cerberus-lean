# FUEL arc — design note: a kernel-transparent, distinguished fuel-exhaustion outcome

Date: 2026-09-02. Branch `arc/fuel` off mainline `2c7c9347b`. Docs-only
slice (this note); the implementation slice is §6. Revisions: **R1**
absorbed the fresh review of `dd61ab87a` (F1-F8, Q1-Q6); **R2** absorbs
the operator's DESIGN CHANGE to Option C (below), which retires the
reserved-literal apparatus R1 had built. §8 lists both deltas; every
cite was re-verified against the tree at absorption.

Request (verbatim source, read first):
`refined-cerberus/worktrees/audit-response-3/docs/2026-09-02_request-cerberus-lean-fuel-exhaustion-outcome.md`
— the consumer (refined-cerberus / cerberus-heaplang) needs, in the ND
monad, a fuel-exhaustion outcome the kernel can recognise, so that
∀-fuel partial-correctness theorems can be stated over the SHIPPED
driver and the consumer's own `driveU` loop can be deleted (their
operator ruled it out as a root of trust: DECISIONS.md:626, "the actual,
genuine, legitimate, original Cerberus one").

Rulings logged in this note:

- [USER 2026-09-02] Option A (superseded in mechanism by C, same
  constructor discipline): "Very good, A sounds reasonable, go ahead" —
  the existing `kill_reason` constructor `Error of Loc.t * string`,
  unwrapped; Option B (a new `kill_reason` constructor) REJECTED: it
  changes the shared `.lem` type and therefore the generated-OCaml text
  / fork-drift surface, for a constructor the oracle never uses.
- [USER 2026-09-02] **OPTION C** (R2): "Yes, this seems reasonable. But
  we'll want to do a 2nd design review before merge to make sure we
  actually achieved this cleaner picture and it serves the
  refined-cerberus project needs." C = the sentinel's distinguishing
  atom is a kernel-checked OPAQUE constant (a pure `opaque … := v`, no
  `unsafe`/`implemented_by`/`extern`), not a reserved string. The second
  design review is a §6 deliverable.
- [USER 2026-09-01] standing ordering rule: "order these by
  (performance) * (trust impact) … keep our trust surface stable i.e
  'obviously right' wrt upstream Cerberus".
- [AGENT 2026-09-02, orchestrator; operator-overridable — FLAGGED]: the
  per-declaration fuel BUDGET application (C1 manifest §8's deferred
  item) is BUNDLED into this arc (§4), as the SECOND of two commits
  (§6).
- [AGENT 2026-09-02, orchestrator, R1 Q-rulings; operator-overridable]:
  Q1 keep `CerbFuel` + `CerbND`, re-export in `CerbND`; Q2 no change;
  Q3 YES — the runner leaf becomes the same kill (after `prune/relsem`
  lands, subject to consumer ack); Q4 family = the six; Q5 erratum
  CONFIRMED; Q6 no `DecidableEq` promised (restated for C in §7).

Facts below were re-verified in the worktree at `2c7c9347b`; every
cite is file:line in that tree unless stated.

## 0. Brief-vs-tree corrections (headline)

1. **Nine ND-typed sentinels, not six.** The brief's six
   (nondeterminism.lem:555 `nd_bind`, :557 `liftND`, :558 `liftAction`;
   driver.lem:1902 `print_eval_conv_aux`, :1903
   `drive_nonmemory_steps_aux2`, :1904 `driver2`) are joined by three in
   the memory model with the identical ND-killed witness:
   defacto_memory.lem:2674 `find_array_index`, :2675
   `easy_update_mem_value_aux`, :2676 `memcmp_load_aux` (generated
   Defacto_memory.lean:806, :821, :900). They are `impl_memM`-typed
   (defacto_memory.lem:84-85), lifted into the driver by `liftND`, and
   their exhaustion is a driver outcome exactly as `nd_bind`'s is. All
   nine are in scope (§1.2).
2. **The driver's `'err` is `driver_error`, not `mem_error`.**
   driver.lem:116: `type driverM 'a = ND.ndM 'a step_kind driver_error
   Mem.mem_iv_constraint driver_state`; `mem_error` appears only wrapped
   (`DErr_memory`, driver.lem:57). The export is `'err`-POLYMORPHIC.
3. **A string literal cannot be written in the `declare`.** The lem
   backtick lexer excludes `"` (lem-lean `src/lexer.mll:172`, :246;
   LemLib.lean:189-190 records the same constraint). The arm references
   NAMED constants (§1.2).
4. **The gcc ledger's fuel rows are `SKIP_LEAN_CRASH`, not
   `SKIP_LEAN_FAIL`**: `scripts/gcc_oracle_baseline.txt:1145`
   (`csmith/sia_csmith_477.c`), :1437 (`sia_csmith_769.c`); 9
   SKIP_LEAN_CRASH rows today; the lane record names the two as fuel
   deaths (docs/2026-08-30_gcc-oracle-lane-record.md:71). The same two
   are `LEAN_CRASH` in `scripts/exec_csmith_corpus_baseline.txt:1177,1469`.
5. **Erratum, CONFIRMED (two independent verifications).** The C1
   manifest's apply-condition statement
   (docs/2026-08-31_C1-change-manifest.md:171-176, "zero current lane
   baselines contain a fuel-exhaustion row") and the adoption record's
   (d) (docs/2026-09-01_C1-adoption-record.md:183-191) are contradicted
   by the committed rows. Verification 1 (this note's author): §0.4 at
   `2c7c9347b`. Verification 2 (the R1 reviewer, re-run here): at the
   C1 commit `c7cb5380d` both baselines ALREADY carried the rows
   (`git show c7cb5380d:scripts/gcc_oracle_baseline.txt` :1145/:1437;
   `…exec_csmith_corpus_baseline.txt` :1177/:1469), and the fuel
   attribution predates C1 (docs/2026-08-21_arc10-results.md:365,
   docs/2026-08-20_arc10-s4-csmith-campaign.md:434, the gcc record :71).
   The C1 measurement was VACUOUS (no fuel class existed to grep for;
   the glob excluded `gcc_oracle_baseline.txt`). Disposition: labeled
   errata to BOTH records in commit 1 (§6).
6. LemLib cites: `fuelExhaustedWith` at `lean-lib/LemLib.lean:184-187`,
   `fuelExhausted` at :192-193, `lemDefaultFuel := 1000000` at :56.
7. Main.lean has TWO kill-printing paths: batch (`Error {msg: "…"}`,
   Main.lean:918-919 — what every harness parses) and non-batch
   (`result: Killed (error: {msg})`, :947-949). Batch exit code for a
   single Killed execution is 1 (:925-928, mirroring OCaml main.ml runM).
8. The lem backend still has a `sorry` target_rep special case
   (lem-lean `src/lean_backend.ml:4044-4050`) while its header claims
   "sorry-emission paths are gone" (:84). §5 rider.
9. A stub rep for the `sorry` already exists (`CerbPP.lean:228`,
   `"<mem_value>"`, `[PRETTY]`); §5 chooses the real printer.
10. The L1 budget form takes an INTEGER LITERAL only (lem-lean
    `src/ast.ml:516`); the wrapper is emitted with the numeral. §4.3.
11. `prune/relsem` exists as a worktree at `2c7c9347b` with NO commits
    yet; the §6 dependency is on work not yet landed.
12. (R1, retained as fact) `Loc.unknown` is NOT a discriminator for
    kills: `current_loc` is initialised `Loc.unknown` (driver.lem:502,
    :1572) and a library-Core `error(…)` before the first located
    expression kills there. Under C this fact no longer bears on
    soundness (§2), but it is why the R0 argument was wrong.
13. (R1) 10^8 fuel is UNREACHABLE inside every gate lane's timeout —
    §3.3 / §4.5.

## 1. CUSTOMER CONTRACT (standalone for refined-cerberus)

This section is self-contained: a consumer can read it without the
rest of the note. Names are final unless §7 changes them; the consumer
is invited to object before the implementation slice.

### 1.1 The export

```lean
-- lean_frontend/CerbFuel.lean  (hand-written seam, imported by the
-- generated Nondeterminism.lean via `declare {lean} extra_import`)
namespace CerbFuel
/-- The distinguishing atom of the fuel-exhaustion kill. A pure, kernel-
    checked `opaque` WITH a value: it inhabits `Loc`, it compiles to
    `Loc.other "lem: fuel exhausted"` at runtime, and NO proof can unfold
    it. It is not in the model's vocabulary: no `.lem` term, no Core text,
    no JSON input can mention it. Registered on the boundary-opaque census
    (check_theorem_axioms.sh; VALIDATION.md). -/
opaque fuelExhaustedLoc : CerbLocation.Loc := CerbLocation.Loc.other "lem: fuel exhausted"
/-- The kill's message. A plain `def` — REPORTING-ONLY (it is what Main
    prints and what the harnesses classify on); it carries no soundness.
    It exists as a named constant only because a lem `declare` cannot
    carry a string literal. -/
def fuelExhaustedMsg : String := "lem: fuel exhausted"
def driverFuel : Nat := 100000000        -- §4; = 10^8
end CerbFuel

-- lean_frontend/CerbND.lean  (hand-written seam; already home of runND)
namespace CerbND
export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg driverFuel)   -- one namespace for the consumer

/-- The distinguished fuel-exhaustion kill. `'err`-polymorphic: it never
    mentions the error type, so it is the same value in `driverM`
    (`kill_reason driver_error`) and `impl_memM` (`kill_reason mem_error`). -/
def fuelExhaustedKill {err : Type} : kill_reason err :=
  Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg
end CerbND
```

`kill_reason` is the generated type (Nondeterminism.lean:54-62;
constructors `Undef0 | Error0 | Other`, the lem-mangled names of
nondeterminism.lem:19-22 `Undef | Error | Other`; the OCaml side carries
the same mangled names, backend/common/driver_ocaml.ml:173-179).
`CerbLocation.Loc` is the hand-written location type (CerbLocation.lean:
29-35: `unknown | other : String → Loc | point | region | regions`). The
`'err` instantiation the consumer's driver theorems need is
`driver_error` (driver.lem:116); nothing in the contract depends on it.

### 1.2 The guarantee (the fuel-zero arms)

For each of the NINE ND-typed fueled workers, the generated fuel-zero
arm is, with NO opaque wrapper around the monadic value,

```lean
| 0 => ND (fun st => (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), st))
```

(`liftAction` returns `nd_action`, not `ndM`, and is curried on its
scrutinee, so its arm is `fun _ => NDkilled (Error0 CerbFuel.fuelExhaustedLoc
CerbFuel.fuelExhaustedMsg)`; `drive_nonmemory_steps_aux2` has a trailing
curried list argument, so its arm is `fun _ => ND (fun st => …)`. These
are the SAME shapes the arms have today, minus `fuelExhausted (…)`.)
The arm spells the two constants rather than `fuelExhaustedKill` because
`kill_reason` is DEFINED in the generated Nondeterminism.lean, which no
seam it imports can mention; the `_zero` lemmas close that gap by `rfl`
(one delta step on a plain `def`) — the kernel sees the same term.

Shipped, kernel-checked (`rfl`), one per worker, FULLY APPLIED against
the generated signatures (Driver.lean:231, :346, :380;
Nondeterminism.lean:188, :306, :309; Defacto_memory.lean:805, :820,
:899 — the generated workers take the reader argument
`_lemReader_tagDefs`, here `tds`, where their lem definition reads
`tagDefs`). The consumer should cite these rather than the generated
text:

```lean
namespace CerbND
theorem print_eval_conv_aux_lemFuel_zero (tds) (dr_st) (th_st) (pe) :
    print_eval_conv_aux_lemFuel 0 tds dr_st th_st pe
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem drive_nonmemory_steps_aux2_lemFuel_zero (tds) (acc) (xs) :
    drive_nonmemory_steps_aux2_lemFuel 0 tds acc xs
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem driver2_lemFuel_zero (tds) (with_concurrency) :
    driver2_lemFuel 0 tds with_concurrency
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem nd_bind_lemFuel_zero (m) (f) :
    nd_bind_lemFuel 0 m f = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem liftND_lemFuel_zero (get) (put) (liftInfo) (liftErr) (m) :
    liftND_lemFuel 0 get put liftInfo liftErr m
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem liftAction_lemFuel_zero (get) (put) (liftInfo) (liftErr) (act) :
    liftAction_lemFuel 0 get put liftInfo liftErr act = NDkilled fuelExhaustedKill := rfl
theorem find_array_index_lemFuel_zero (size) (i) (ival) :
    find_array_index_lemFuel 0 size i ival
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem easy_update_mem_value_aux_lemFuel_zero (tds) (loc) (is_strong) (write_ty) (sh) (write_mval) (current_mval) :
    easy_update_mem_value_aux_lemFuel 0 tds loc is_strong write_ty sh write_mval current_mval
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl
theorem memcmp_load_aux_lemFuel_zero (tds) (ptrval) (offset) (max_offset) (acc) :
    memcmp_load_aux_lemFuel 0 tds ptrval offset max_offset acc
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

-- the runner leaves (Q3; lands after prune/relsem, subject to consumer ack)
theorem runNDFuel_zero (m) (st0) :
    runNDFuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)] := rfl
theorem runND1Fuel_zero (m) (st0) :
    runND1Fuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)] := rfl
theorem runND1TraceFuel_zero (showInfo) (m) (st0) :
    runND1TraceFuel showInfo 0 m st0 = ([], [(Killed st0 fuelExhaustedKill, [], st0)]) := rfl

-- the wrappers (§4; budget = CerbFuel.driverFuel for the drive family)
theorem driver2_wrapper_defeq : driver2 = driver2_lemFuel CerbFuel.driverFuel := rfl
theorem nd_bind_wrapper_defeq : @nd_bind = @nd_bind_lemFuel CerbFuel.driverFuel := rfl
theorem runND_eq (m) (st0) : runND m st0 = runNDFuel CerbFuel.driverFuel m st0 := rfl
theorem driverFuel_eq : CerbFuel.driverFuel = 100000000 := rfl
end CerbND
```

(Implicit type arguments are elaborated; exact binder names follow the
generated signatures at implementation and are recorded in the change
manifest.) Note for `liftAction_lemFuel_zero`: the fuel-0 arm DISCARDS
the incoming action — including a genuine kill it was lifting — and
reports exhaustion; that is the correct reading (the lift did not
complete) and the shape the type forces (Q2).

Propagation: `nd_bind`'s `NDkilled` arm re-emits the kill unchanged
(nondeterminism.lem:57-, generated :190); `liftAction`'s `Error` arm
is the identity (`Error loc str -> Error loc str`, nondeterminism.lem:
249-257). So the kill is stable under bind and under lifting from
`impl_memM` into `driverM`: an exhausted memory worker surfaces as the
driver's `fuelExhaustedKill`, not as a rewritten value. And since every
fueled worker — at the consumer's quantified fuel or at the fixed
budget of the workers beneath it — produces the SAME value, one kill
covers all fuels in a run.

### 1.3 What distinguishes the kill — soundness by construction

**Unforgeable by construction.** `fuelExhaustedLoc` is a Lean constant
in the hand-written `CerbFuel` seam. The semantics' only `Error` kill
site is core_eval.lem:605-606 (`PEerror str _ -> Undefined.error loc
str`), lifted by the four `ND.kill (ND.Error loc str)` at driver.lem:182,
:411, :432, :443; its `loc` is `th_st.current_loc` (core_run.lem:165,
:171), which takes values from the model's own `Loc` literals
(driver.lem:502, :1572, :1600, :1876, :141, :1448) and from `Aloc`
annotations (core_run.lem:776-784) that originate in C source positions
(cabs JSON, CabsImport.lean:125: `Loc_unknown | Loc_other s | Loc_point
| …`) or in Core text (CoreParser.lean:201-204: always `loc0 =
CerbLocation.unknown`). None of these can denote `fuelExhaustedLoc`: it
is not in the model's vocabulary — no `.lem` term, no Core text, no
JSON string names a Lean constant. A forged `error("lem: fuel
exhausted", pe)` in a Core file yields `Error0 CerbLocation.unknown
"lem: fuel exhausted"` (or `Error0 (Loc.other s) …` with `s` from a
JSON `Loc_other`), a SYNTACTICALLY DIFFERENT term from `Error0
fuelExhaustedLoc "…"`: the kernel does not identify an opaque constant
with any constructor application. So the only way a run's status can be
`Killed st fuelExhaustedKill` is through a fuel-zero arm (or, after Q3,
a runner leaf).

**How the consumer's proof uses it.** In the ∀-fuel induction, the
fuel-zero arm closes the LEFT disjunct by `rfl` (via the `_zero`
lemmas); every other arm is closed by the postcondition (or, when a
worker beneath the quantified one exhausts at its fixed budget, again
by the left disjunct — same value). No distinctness fact is consumed.

**Caveats, stated honestly (what C does NOT give):**
- The kernel cannot prove the sentinel UNEQUAL to a genuine `Error0`
  kill: `fuelExhaustedLoc` is opaque, so `fuelExhaustedKill ≠ Error0 loc
  msg` is not provable for any `loc`. No such distinctness lemma ships.
  The acceptance shape does not need one: for a program that can
  genuinely `Error`-kill, neither disjunct holds on that outcome and
  the theorem is unprovable — which is the correct meaning of a partial-
  correctness statement (the program is not correct). What DOES ship
  for free, by constructor disjointness, is `fuelExhaustedKill ≠ Undef0
  loc ubs` and `fuelExhaustedKill ≠ Other e`; these are not distinctness
  from a genuine `Error` kill and are documented as such.
- `isFuelExhaustedKill` is NOT decidable by comparing locations
  (`fuelExhaustedLoc` has no equations). Consumers state the STRUCTURAL
  equation `o.1 = Killed st fuelExhaustedKill` and discharge it with the
  `_zero` lemmas (Q6 restated for C: no decidable predicate and no
  `DecidableEq` is promised or needed).
- Runtime classification (§3) is by the printed message; the harness's
  copy of the string is reporting-only and never enters a proof.

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
  ∀ o ∈ CerbND.runND (driver2_lemFuel fuel fmapEmpty false) dst₀,
    (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)
```

with `dst₀ := (initial_driver_state sup file fs).1` (the consumer's own
production entry, ProdEntry.lean:8-9), and `driveU` deleted from every
export. The `∀ fuel` induction is the consumer's (request item 4).
After Q3 lands, runner exhaustion ALSO appears as a `Killed _
fuelExhaustedKill` element, so the left disjunct covers both fuels.
An in-repo exemplar in exactly this shape is a slice deliverable (§6).

### 1.5 Not provided

- **Fuel monotonicity** for the driver workers (request item 4:
  "welcome but not required"). The runner has `runNDFuel_mono` for ITS
  fuel (CerbND.lean header).
- **A distinguished runtime EXIT CODE**: the kill exits 1 like every
  `Error` kill, mirroring OCaml (Main.lean:925-928).
- **Distinctness from a genuine `Error0` kill; `DecidableEq`; a
  decidable `isFuelExhaustedKill`** (§1.3 caveats).
- **The pure-return workers** (`hack`, driver.lem:1905 `fuelExhausted
  Vunit`; the ~58 others across frontend/model, e.g. Defacto_memory.lean:
  285, :735) keep the opaque `fuelExhausted` sentinel and its panic
  (request item 3). Their exhaustion is a `PANIC` (exit 134, message on
  stderr), never a kill.

## 2. TRUST-STORY ANALYSIS

The operator's question: does this move the trust surface relative to
upstream Cerberus? Answer by parts.

**Fuel is a port-side artifact with no upstream counterpart.** The lem
model's recursion (`let rec driver2`, driver.lem:1369; `let rec
nd_bind`, nondeterminism.lem:57) is unbounded; OCaml runs it as is. The
Lean target makes it total by fuel (arc-3), via `declare {lean} fuel
val f = \`<lean expr>\`` — 67 such declares in `frontend/`, all
`{lean}`-scoped, rendered ONLY in the Lean emission; the sentinel text
is written verbatim in the declare, not synthesized by the backend.

**No shared-type change; the OCaml text is untouched — by construction,
and gate-verified.** Every edit is in a `{lean}` declare (nine sentinel
bodies, one `declare {lean} extra_import \`CerbFuel\`` in
nondeterminism.lem — the mechanism debug.lem:4 already uses) or in
hand-written Lean (`CerbFuel.lean`, `CerbND.lean`). The OCaml emission
does not read them. Verification: the standing fork-drift gate
(`scripts/check_fork_drift.sh`, Layer 2) diffs `ocaml_frontend/generated`
against the upstream-pristine tree and requires the differing set to
equal the manifest's hash-pinned entries; this arc adds ZERO entries to
`scripts/fork_drift_manifest.txt`, and the gate staying green at the
implementation head is the byte-identity proof.

**No new impure seam.** `opaque fuelExhaustedLoc : Loc := Loc.other "…"`
is a bare opaque WITH a kernel-checked value: pure, axiom-free, no
`unsafe`, no `@[implemented_by]`, no `@[extern]` — so it is NOT a member
of the `implemented_by`/`unsafe`/`unsafeBaseIO` seam population pinned
by `scripts/unsafebaseio_allowlist.txt` (VALIDATION.md:139), and it
introduces no runtime behaviour the kernel does not see (the compiler
uses the given value). What it IS: an abstraction barrier — a constant
with no equations — and the tree already keeps a census of those. The
boundary-opaque census (check_theorem_axioms.sh:180-191: each listed
opaque "must be present exactly once in its build copy", scanner regex
at :151, list `CerberusFresh\.lean:[0-9]+:forceIO` at :185; VALIDATION.md:
195-199 the digest boundary) REGISTERS `CerbFuel.lean:…:fuelExhaustedLoc`
with rationale "fuel-exhaustion atom: pure opaque, value-carrying, no
native binding; exists to be unforgeable, not to hide an effect". Its
cone contributes no axiom (the exec-entry set stays at the exact
allowlist `[propext, Classical.choice, Quot.sound]`, VALIDATION.md:139).

**Sufficient-fuel behaviour is unchanged.** The `Nat.succ` arms are
untouched; every run that completes today completes with the same
verdict. The differential battery (§6) is the check, byte-at-baseline
except the enumerated FUEL rows (§3.3).

**Exhaustion behaviour changes, from a crash to a typed kill.** Today: a
driver fuel death panics via `fuelExhaustedWithImpl` (LemLib.lean:184-
187) → exit 134, `lem: fuel exhausted` on stderr, classified LEAN_CRASH.
After: the driver returns `Killed st fuelExhaustedKill`, Main prints
`Error {msg: "lem: fuel exhausted"}` (batch) and exits 1. Loudness is
preserved at the HARNESS level (request item 2): the classifying lanes
assign FUEL, fail-noisy, never agreement; the byte-compare lanes report
DIFF/FAIL (§3). Nothing becomes quieter.

**Why C, against B and A' (the ordering rule: (performance) × (trust
impact)).** B = a new `kill_reason` constructor. A' = R1's design: the
existing constructor + a reserved string + a `Loc.other` tag + a
source-scan gate over `.lem`/Core text + a per-file structural lemma
for the consumer.

| | B (constructor) | A' (reserved literal + tag + gate + lemma) | C (opaque atom) |
|---|---|---|---|
| mechanism count | 1 type change + OCaml match fixes | 1 def + 1 tag + 1 gate + 1 enumeration + 1 consumer lemma + 1 harness drift leg | 1 opaque + 1 census row |
| forgeability from inputs (Core text / JSON) | impossible (no syntax) | possible for arbitrary Core text; closed by convention (gate) + tag + side condition | impossible: not in the model's vocabulary |
| shared `.lem` type change | YES — generated OCaml text moves, fork-drift manifest entry, `driver_ocaml.ml:173-182` exhaustiveness | no | no |
| trust class | oracle-surface movement | convention-based; correctness of an enumeration | kernel-checked pure opaque; existing census |
| consumer statement shape | `Killed st FuelExhausted` | `Killed st fuelExhaustedKill` + `noReservedPEerror file` side condition | `Killed st fuelExhaustedKill`, no side condition |
| kernel-provable distinctness from a genuine `Error` kill | yes | yes (`Error0 (.other msg) msg` vs enumerated literals) | NO (opaque) — and the acceptance shape does not use it |
| runtime / consumer cost | none | none | none |

C wins every column except the last, which nobody needs (§1.3
caveats). Under the ordering rule it is the smallest trust-surface
movement with the same performance.

**The residual risk, named.** C's soundness rests on ONE Lean fact —
`fuelExhaustedLoc` is opaque — pinned by the census (a definitional
unfolding would break the argument silently to the kernel; the census
makes its presence-as-opaque a gate). Runtime classification rests on
the printed message, which is reporting-only: a drift between
`CerbFuel.fuelExhaustedMsg` and the harness's copy degrades the FUEL
class to FAIL-class rows — loud, never a soundness matter.

**VALIDATION.md — the paragraph that replaces today's fuel text**
(VALIDATION.md:218-221):

> - **Fuel exhaustion is a typed, distinguished outcome** for the ND
>   monad's fueled workers (the driver loop family, the memory-model ND
>   workers, and the `CerbND` runners): the fuel-zero arm is `NDkilled
>   CerbND.fuelExhaustedKill` = `Error0 CerbFuel.fuelExhaustedLoc "lem:
>   fuel exhausted"`, where `fuelExhaustedLoc` is a pure, kernel-checked
>   `opaque` constant on the boundary-opaque census (present exactly
>   once; no native binding). Unforgeable by construction: no `.lem`
>   term, Core text, or JSON input can denote it, so a run's status is
>   `Killed _ fuelExhaustedKill` only through a fuel-zero arm; the kernel
>   cannot (and need not) prove it unequal to a genuine `Error` kill.
>   `_zero` lemmas hold by `rfl`. Budgets: the coupled driver family
>   (`driver2`, `drive_nonmemory_steps_aux2`, `print_eval_conv_aux`,
>   `hack`, `nd_bind`, `CerbND.ndDefaultFuel`) runs at
>   `CerbFuel.driverFuel` = 10^8; every other fueled declaration keeps
>   `lemDefaultFuel` = 10^6 (the L1 opt-in guarantee). Pure-return
>   workers keep the opaque panicking sentinel (exit 134, `lem: fuel
>   exhausted` on stderr). The classifying lanes (`test_exec.sh` and its
>   csmith wrapper, `test_gcc_oracle.sh`, `test_ci_sweep.sh`,
>   `test_cn_coverage.sh`, `tests/mem-scale-probes/measure.sh`) assign
>   the FUEL class to both forms by the printed message (fail-noisy,
>   never agreement; reporting-only, no soundness rests on it); the
>   byte-compare lanes (`test_libc_exec.sh`, `test_multi_tu.sh`,
>   `test_verify.sh`, `test_immaculate.sh`, `test_libxml2_uri.sh`,
>   `test_bytes.sh`) report DIFF/FAIL. A 10^8 budget is unreachable
>   inside any gate lane's timeout (15-30 s ⇒ ≤ 7×10^6 fuel per
>   invocation); it is exercised only by `measure.sh` (600 s) and
>   unbounded single probes. Record: `docs/2026-09-02_fuel-arc-design.md`.

## 3. HARNESS CLASSIFICATION

### 3.1 What a fuel death looks like, after

| source | stdout (batch) | stderr | exit |
|---|---|---|---|
| ND worker (nine) | `Error {msg: "lem: fuel exhausted"}` (Main.lean:918-919; non-batch: `result: Killed (error: lem: fuel exhausted)`, :947-949) | — | 1 |
| pure worker (`hack` + ~58) | none | `PANIC … lem: fuel exhausted` (LemLib.lean:184-187) | 134 |
| runner (`runNDFuel`), today | `Error {msg: "cerberus-lean: runND returned no executions"}` when the whole run exhausts (Main.lean:900-902) | `PANIC at CerbND.runNDFuel …` | 1 |
| runner, after Q3 | as the ND-worker row | — | 1 |

### 3.2 Where today's classifiers would put it, and the fix

Which scripts classify at all: of the ~20 scripts that invoke the
binary, FIVE classify outcomes — `scripts/test_exec.sh` (and
`test_csmith_corpus.sh`, which `exec`s it, :130), `test_gcc_oracle.sh`,
`test_ci_sweep.sh`, `test_cn_coverage.sh`, and
`tests/mem-scale-probes/measure.sh`. The byte-compare lanes
(`test_libc_exec.sh:120-129`, `test_multi_tu.sh:120`,
`test_verify.sh:71-72`, `test_immaculate.sh:96-97`,
`test_libxml2_uri.sh`, `test_bytes.sh:89-91`) compare verdict text and
turn any fuel kill into DIFF/FAIL — fail-noisy, never MATCH; acceptable,
and left as is.

Today's classifying lanes only look for `fuel exhausted` inside the
exit ≥ 128 branch: test_exec.sh:534-548, test_gcc_oracle.sh:416-420,
test_ci_sweep.sh:296-299, test_cn_coverage.sh:389-394 — all `grep -m1 -E
'PANIC|fuel exhausted'` on the crash path. An exit-1 `Error {msg: "lem:
fuel exhausted"}` never reaches them; it falls through to:

- test_exec.sh:560-570 `*'Error {'*` → **FAIL** (`LEAN_FAIL`, "Lean
  pipeline error(s)", fatal, :839-841);
- test_gcc_oracle.sh:421-424 → **SKIP_LEAN_FAIL** with the msg;
- test_ci_sweep.sh, test_cn_coverage.sh → their `Error {` / unexpected-
  output rows (FAIL-class);
- measure.sh:80-86 `verdict_of` maps `Error {msg: …}` to `ERR:<msg>`,
  so the row would read `ERR:lem: fuel exhausted` as its verdict and
  carry no FUEL note (:106-112 tag only `capped: (OOM-)?KILLED`,
  `INTERNAL PANIC`, HANG).

So the class is inserted, in every classifying lane, keyed on the
EXACT message (never the loose `fuel exhausted` regex on stdout), at two
points: (a) in the exit ≥ 128 branch, when the capture carries the
panic marker → `FUEL` (sub-kind `panic`); (b) BEFORE the `Error {` /
`SKIP_LEAN_FAIL` fall-through, when the capture carries `Error {msg:
"lem: fuel exhausted"}` → `FUEL` (sub-kind `kill`). Row names per lane:
`FUEL` (test_exec/csmith, test_ci_sweep, test_cn_coverage; measure.sh
note `FUEL(kill|panic);`), `SKIP_LEAN_FUEL` (gcc ledger taxonomy,
`scripts/gcc_oracle_baseline.txt` header +
docs/2026-08-30_gcc-second-oracle-design.md's class table). Semantics,
uniform: fail-noisy (fatal in default mode exactly as LEAN_CRASH is:
test_exec.sh:814 status list gains `FUEL`); baselined rows are honoured
only by the `--check-baseline` machinery; NEVER counted as MATCH/AGREE,
never as "completed" in measure.sh's parity tallies.

The classifier is factored once into `scripts/common.sh`:
`classify_fuel_outcome <exit> <capture>` over a SINGLE text argument —
the four lane scripts capture `2>&1` merged (test_exec.sh:329-330,
test_gcc_oracle.sh:413-414, test_ci_sweep.sh:287-288,
test_cn_coverage.sh:226/:234) and pass the merged capture; measure.sh
and test_libc_exec.sh split streams (measure.sh:135-136; test_libc_exec.
sh:104) and pass the concatenation of their files. Output: `FUEL:kill`,
`FUEL:panic`, or empty. **The string in `common.sh` is REPORTING-ONLY**:
it is a copy of what Main prints, it never enters a proof, and a drift
between it and `CerbFuel.fuelExhaustedMsg` degrades classification
loudly (fuel kills fall back to FAIL-class rows) — never soundness. No
drift gate is built for it (R2 deleted R1's); the classifier selftest
(§3.4) is the discipline.

Main.lean is NOT changed by the mechanism: the existing `Error0` arms
print the message.

### 3.3 Baseline movement expected (enumerated)

The arithmetic that governs it: gate lanes run `TIMEOUT_SECS` 30
(test_exec.sh:154, test_gcc_oracle.sh:116, test_cn_coverage.sh:81) or
15 (test_ci_sweep.sh:83, test_csmith_corpus.sh:51); at the measured
~2.3×10^5 fuel/s loop-shape rate (docs/2026-08-31_stack-ceiling-design.md:
194) that is 3.5-7×10^6 fuel per invocation. So **10^8 is UNREACHABLE
inside every gate lane**; only `measure.sh` (600 s, :46 ⇒ ~1.4×10^8 at
loop rate) and unbounded single probes can reach it. Hence two columns,
one per commit (§6):

| lane / record | row | today | after commit 1 (mechanism) | after commit 2 (budget) |
|---|---|---|---|---|
| `scripts/gcc_oracle_baseline.txt:1145` | `csmith/sia_csmith_477.c` | SKIP_LEAN_CRASH | SKIP_LEAN_FUEL (the recorded witness) | SKIP_LEAN_TIMEOUT, or AGREE if it completes within 30 s — NOT FUEL |
| `scripts/gcc_oracle_baseline.txt:1437` | `csmith/sia_csmith_769.c` | SKIP_LEAN_CRASH | SKIP_LEAN_FUEL | likewise |
| `scripts/exec_csmith_corpus_baseline.txt:1177` | `sia_csmith_477.c` | LEAN_CRASH | FUEL | TIMEOUT, or MATCH — NOT FUEL |
| `scripts/exec_csmith_corpus_baseline.txt:1469` | `sia_csmith_769.c` | LEAN_CRASH | FUEL | likewise |
| mem-scale record (docs/2026-09-02_mem-scale-record.md:685,699,700,703,704; not a gate baseline) | `b_zero_local_1000000`, `d_loop_100000`, `d_loop_1000000`, `e_memcpy_100000`, `e_memcpy_1000000` | BLOCKER: C8 (fuel), exit 134 | `ERR:lem: fuel exhausted` + `FUEL(kill)` note | expected to complete (§4.4); else TIMEOUT(600 s) or FUEL — measured |
| mem-scale record :686 | `b_zero_local_10000000` | out of domain (oracle TIMEOUT 600 s; Lean fuel) | FUEL(kill) | still out of domain (oracle) |

Every other committed baseline has zero fuel rows (`LEAN_CRASH` counts:
exec_baseline 0, exec_ci 0, exec_coverage 0, exec_debug 0, cn_coverage
0, immaculate 0). Any row moving that is not in this table is a
FINDING, not a re-baseline.

Consequence, stated plainly: **after commit 2 no standing baseline row
exercises `FUEL(kill)`** — the class is kept honest only by the
classifier selftest and the commit-1 witness rows recorded in the slice
record. That is why the slice is two commits: commit 1's lane runs are
the only time the FUEL rows appear in real lanes at a committed head.

Whether the two csmith rows were driver-fuel deaths (→ kill) or
pure-worker deaths (→ still a panic, now classed FUEL(panic)) is
determined at commit 1; either way they leave LEAN_CRASH.

### 3.4 Plants (vacuity must be loud)

- Classifier selftest (`scripts/test_unit.sh` leg): fixture captures →
  expected class, including the three negatives (a non-reserved `Error
  {msg: …}` → not fuel, a PANIC without the marker → not fuel, a stdout
  line containing the words "fuel exhausted" in a program's own output →
  not fuel).
- Commit-1 witness: the gcc lane and the csmith corpus lane run at the
  commit-1 head; the four FUEL rows are recorded VERBATIM in the slice
  record as the class's real-lane witness (§3.3).
- One end-to-end witness for the kill sub-kind at the budget head, if
  the csmith rows turn out to be panics: a scratch build with a tiny
  local budget (`declare {lean} fuel val driver2 = 1000` in a throwaway
  worktree) through each lane, recorded verbatim. A witness, not a
  standing gate.

## 4. BUDGET APPLICATION (bundled; [AGENT] assumption, operator-overridable)

### 4.1 The decision being applied

Record-and-defer, C1 manifest §8 (docs/2026-08-31_C1-change-manifest.md:
158-188) and the adoption record (docs/2026-09-01_C1-adoption-record.md:
183-191): **10^8 on the whole coupled family** — driver.lem quartet
`print_eval_conv_aux`, `drive_nonmemory_steps_aux2`, `driver2`, `hack`;
substrate `nd_bind`; hand-written `CerbND.ndDefaultFuel`. Coupling
analysis: docs/2026-08-31_stack-ceiling-design.md:139-146 — the trees
the runner walks are built by `nd_bind`'s own fuel, so "raising any ONE
member is vacuous". Sizing: stack-ceiling §6b (:194) / C1 §8 — at
measured fuel rates a 10^8 budget puts the loud edge at ~7 min
(loop-shape, 2.3×10^5 fuel/s) to ~55 min (rec-shape, 3×10^4 fuel/s) of
single-invocation stepping; 10^9+ would be past the grind horizon.

Why bundle ([AGENT], the orchestrator's assumption): the mechanism
already re-states the consumer's fuel-zero shape; landing the budget
separately would re-open the consumer's side conditions a second time
(the exact churn C1 §8 deferred to avoid). The operator may unbundle;
§1-§3 stand alone if so. (The C1 apply-condition itself was vacuous,
§0.5 — the "no improving row" premise for deferral never held.)

### 4.2 Mechanism

The L1 opt-in form, per member: `declare {lean} fuel val driver2 =
100000000` beside the existing sentinel declare (the backend REQUIRES
the sentinel on the same val, lean_backend.ml:556-575, and refuses a
non-positive literal and a target_rep'd or spec-only val: :576-599 —
all fail-closed at generation). Unannotated declarations keep
`lemDefaultFuel` byte-for-byte (the L1 record, "opt-in constraint held
structurally"). `CerbND.ndDefaultFuel` is hand-written (CerbND.lean:71)
and moves in the same commit (`:= CerbFuel.driverFuel`).

Family membership = the recorded six (Q4 ruling): `liftND`/`liftAction`
and the three defacto workers keep `lemDefaultFuel`. Reason: their fuel
counts the depth of a single lifted memory action's tree (`liftND`) or
a per-operation recursion bounded by the operand (`find_array_index` by
the array size, `memcmp_load_aux` by the byte count) — a different
measure from the driver's step count, and no recorded fuel death names
them. The FUEL class makes any such death visible; membership is
revisited on evidence.

### 4.3 The consumer side-condition statement

The budget form emits the NUMERAL into the wrapper (`def driver2 … :=
driver2_lemFuel 100000000`), not a name (§0.10). To give the consumer a
citable constant, `CerbFuel.driverFuel : Nat := 100000000` (§1.1) and
the wrapper `rfl`s of §1.2 (`driver2_wrapper_defeq`, siblings for the
quartet + `nd_bind`, `runND_eq`, `driverFuel_eq`). Statement for the
consumer's manifest: **every exported statement over the drive cone
(`drive`, `driver2`, `nd_bind`, `runND`) has fuel side condition
`CerbFuel.driverFuel` (= 10^8); every other declaration's side
condition remains `lemDefaultFuel` (= 10^6) verbatim.** Their `driver2 =
driver2_lemFuel lemDefaultFuel` `rfl`s (the shape of relsemcore/RelSem/
Cerberus.lean:183-184, which the prune retires) stop being `rfl` and are
re-stated against `driverFuel`.

### 4.4 Expected differential effect

Improvements, enumerated at commit 2 by MEASUREMENT (the record is the
evidence, not this prediction): the five mem-scale C8 rows (§3.3) — at
~55-61 fuel per plain loop iteration, `d_loop_1000000` needs ~6×10^7
fuel, inside 10^8 and (at loop rate) inside measure.sh's 600 s; the
memcpy and zero-local rows are the same order. The two csmith rows
cannot reach 10^8 inside 15-30 s: they become TIMEOUT rows unless they
complete (§3.3). No sufficient-fuel verdict changes (§2).

### 4.5 The grind tripwire

A 10^8 exhaustion costs ~7 min at the loop-shape rate and ~55 min at
the rec-shape rate — the latter AT the ~1 h tripwire. Where it can
happen: ONLY in `measure.sh` (600 s cap — so only loop-shape programs
can exhaust there; rec-shape programs TIMEOUT first) and in unbounded
single-invocation probes, which are exactly the runs the tripwire
governs (stop-and-report at ~1 h; written justification in advance for
longer). NEVER in a gate lane: every gate lane's `TIMEOUT_SECS` (15-30
s) fires at ≤ 7×10^6 fuel. No heartbeat/maxRecDepth/budget bump is ever
a fix (registered defect shape). Nothing here changes loudness: a fuel
death is a typed kill or a panic, never a silent verdict.

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

## 6. SLICES, GATES, AND THE SECOND DESIGN REVIEW

**One implementation slice, TWO commits**, dispatched AFTER
`prune/relsem` merges:

- **Commit 1 — mechanism**: §1 (`CerbFuel.lean` with the opaque atom,
  the message and budget constants; nine sentinels; `CerbND` exports,
  `fuelExhaustedKill`, the `_zero` lemmas, the two constructor-
  disjointness lemmas; the Q3 runner leaves), §2 (census registration
  of `fuelExhaustedLoc`), §3 (FUEL class in the five classifying lanes,
  `common.sh` classifier + selftest), the `sorry` closure + token leg
  (§5), the exemplar (below), VALIDATION/LADDER/TODO text, and the C1
  errata (§0.5). Gate run at this head INCLUDES the gcc lane and the
  csmith corpus lane so the FUEL rows appear in real lanes and are
  RECORDED verbatim (the witness); the four baseline rows move to their
  commit-1 column (§3.3).
- **Commit 2 — budget**: the six L1 declares + `ndDefaultFuel`, the
  `driverFuel` wrapper `rfl`s, the mem-scale re-measurement; the four
  rows move again to their commit-2 column, enumerated; the consumer
  side-condition statement (§4.3) is final at this head.

**Exemplar deliverable (commit 1):** `lean_frontend/test/Unit/
FuelExemplar.lean` — a minimal Core program (a `main` returning a
constant, parsed from an in-repo fixture via `CoreParser.parseFile`) and
the theorem in EXACTLY the consumer's shape (§1.4), kernel-checked:
`∀ fuel, ∀ o ∈ CerbND.runND (driver2_lemFuel fuel fmapEmpty false) dst₀,
(∃ st, o.1 = Killed st fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r
o.2.2)` with `post` the returned value. Proof by cases on `fuel`: the
zero case by `driver2_lemFuel_zero`/`runNDFuel_zero`; the successor case
by evaluation of the single step. It must be `sorryAx`-free and inside
the axiom allowlist (probed by the cone leg); if it does not close
within the tripwire on the minimal program, that is a STOP-AND-REPORT
finding for the second review (it would mean the shape is not
provable in practice with the shipped lemmas), never a grind.

**Second design review (operator-ruled, before merge).** A FRESH
reviewer (not the R1 reviewer, not the author) checks at the commit-2
head:
(a) the implementation achieved the cleaner picture — no reserved-
literal residue (no `check_fuel_literal.sh`, no `noReservedPEerror`, no
`Loc.other` tag, no harness drift leg; the string constant is
reporting-only and documented as such), no gate machinery beyond the
census row, `fuelExhaustedLoc` pinned exactly-once on the census, the
nine arms + three runner leaves identical in shape and unwrapped;
(b) it serves refined-cerberus's needs — the acceptance theorem is
provable in shape, exhibited by the exemplar, stated exactly in their
form, kernel-checked; the consumer's own review of §1 (Q3 ack, §7) is
on record.
The review's ASK precedes the merge audit ask (both unconditional).

Dependency, precisely: `prune/relsem` (worktree present at `2c7c9347b`,
no commits yet) will touch the RelSem-referencing set — Main.lean
(`RelSem.Cerb.callND`, :880-884), scripts/check_theorem_axioms.sh and
check_exec_totality.sh (cone/census entries), scripts/test_verify.sh,
test_immaculate.sh, lean_probe.sh, lean_frontend/lakefile.toml — and
retires `runND_sound`, which is why Q3 waits for it. This arc touches:
frontend/model/{nondeterminism,driver,defacto_memory}.lem (declares
only), frontend/concurrency/cmm_op.lem:17, NEW lean_frontend/
CerbFuel.lean + handwritten_copy.manifest, lean_frontend/CerbND.lean,
scripts/check_theorem_axioms.sh (the census row — the ONE shared file
with the prune; a one-line addition to the `want` list, rebased after
the prune), scripts/common.sh + the four lane scripts + tests/mem-scale-
probes/measure.sh, NEW scripts/check_sorry_token.sh, NEW test/Unit/
FuelExemplar.lean + fixture, the two csmith baselines + the gcc ledger
taxonomy, VALIDATION.md, LADDER.md, TODO.md (the ceiling entry :21-30
re-stated), the two C1 records (labeled errata).

Gates (full battery per scripts/LADDER.md Tier A+B, plus the gcc lane
and the csmith corpus lane), and the plants:

| gate | red-plant |
|---|---|
| boundary-opaque census (check_theorem_axioms.sh:180-191, scanner :151 extended to `fuelExhaustedLoc`): `CerbFuel\.lean:[0-9]+:fuelExhaustedLoc` present exactly once in the build copy | change `opaque` to `def` in a scratch copy → count 0 → red; duplicate the line → count 2 → red |
| the nine `_zero` lemmas, three runner-leaf lemmas, two disjointness lemmas, the exemplar theorem — in the cone probe (no `sorryAx`, no `ofReduce*`, exact axiom allowlist) | replace a `rfl` with `sorry` in a scratch → red |
| `check_fork_drift.sh` Layer 2 byte-green with ZERO manifest change | (the OCaml-neutrality proof; already plant-tested) |
| `check_handwritten_sync.sh` — `CerbFuel.lean` in the manifest and byte-pinned | unlisted file → red (existing behaviour) |
| `unsafebaseio_allowlist.txt` pin unchanged (the opaque is NOT a seam) | (existing gate; a new `implemented_by` would fail naming itself) |
| FUEL classifier selftest (§3.4) | fixture negatives |
| `sorry`-token leg | planted token → red; empty set → red |
| Differential: Tier A+B byte-at-baseline; gcc lane + csmith corpus lane at baseline with exactly the §3.3 movement for the respective commit | any other row moving is a finding |

Consumer change manifest (what the re-export carries):
- names: `CerbFuel.fuelExhaustedLoc` (opaque), `CerbFuel.fuelExhaustedMsg`,
  `CerbFuel.driverFuel`, `CerbND.fuelExhaustedKill`,
  `CerbND.fuelExhaustedKill_ne_Undef0`, `CerbND.fuelExhaustedKill_ne_Other`
  (constructor disjointness only), the nine `CerbND.<worker>_lemFuel_zero`
  (§1.2, fully applied), `CerbND.runNDFuel_zero`/`runND1Fuel_zero`/
  `runND1TraceFuel_zero`, the wrapper `rfl`s against `driverFuel`, the
  exemplar `FuelExemplar.<program>_certified_shipped`;
- the fuel side-condition statement of §4.3;
- the deleted-`driveU` expectation: the consumer's partial-correctness
  exports (API.lean:77-78, TotalAdequacy.lean:36-39, PROVISIONAL over
  `driveU`; 149 `driveU` references across 10 files at the audit-
  response-3 head) are re-stated over `driver2_lemFuel` per §1.4 and
  the PROVISIONAL label is removed by the consumer.

## 7. QUESTIONS — rulings [AGENT, orchestrator, operator-overridable] and what stays open

- **Q1 — two namespaces.** RULED: keep `CerbFuel` (pre-Nondeterminism:
  the opaque atom, message, budget) and `CerbND` (post: the kill,
  lemmas, runners); `CerbND` carries `export CerbFuel (fuelExhaustedLoc
  fuelExhaustedMsg driverFuel)` so the consumer imports ONE namespace.
- **Q2 — `liftAction`'s arm shape.** RULED: no change (forced by type).
  Documented in §1.2: the fuel-0 arm discards the incoming action,
  including a genuine kill it was lifting, and reports exhaustion.
- **Q3 — the runner's own fuel.** RULED YES: the three runner leaves
  become the same kill (§1.2 lemmas), AFTER `prune/relsem` lands (it
  retires `runND_sound`, stated against the `[]` leaf) and SUBJECT TO
  the consumer's ack. Reason: the `[]` leaf makes ∀-fuel theorems
  vacuous beyond `ndDefaultFuel` depth.
- **Q4 — budget family membership.** RULED: the six; the defacto trio
  and `liftND`/`liftAction` stay at 10^6 (operand-bounded measures; the
  FUEL class will surface any death; revisit on evidence).
- **Q5 — erratum to C1 §8.** CONFIRMED by second verification (§0.5);
  both records get a labeled erratum in commit 1.
- **Q6 — decidability.** RULED (restated for C): no `DecidableEq
  (kill_reason driver_error)` and — under C — no decidable
  `isFuelExhaustedKill` either (an opaque location has no decision
  procedure); the consumer uses the structural equation and the `_zero`
  lemmas, which is all the acceptance shape needs.

Still open for the CONSUMER's review of this note: (i) ack Q3's runner
leaf; (ii) ack the opaque-atom design — in particular that NO
distinctness-from-genuine-`Error` lemma ships (§1.3) and that their
induction never needs one; (iii) the exemplar's `post` shape (§6) —
does `∃ r, o.1 = Active r ∧ post r o.2.2` match how their exports
project the final state, or do they want the state component named
differently.

## 8. Revision deltas

**R2 (Option C, [USER 2026-09-02]):** the reserved-literal apparatus of
R1 is DELETED — `check_fuel_literal.sh` and its `.lem`/Core-text scan,
the `PEerror`-literal enumeration as a soundness argument, the
`Loc.other fuelExhaustedMsg` tag, `CerbFuel.noReservedPEerror(_iff)`,
the "exactly one place" invariant and the harness drift leg. Replaced
by: `opaque fuelExhaustedLoc` (pure, value-carrying, census-pinned),
`fuelExhaustedKill := Error0 fuelExhaustedLoc fuelExhaustedMsg`, the
unforgeability argument and its caveats (§1.3), the B/A'/C table (§2),
the census registration (§2, §6), the second design review + exemplar
deliverable (§6), Q6 restated. Kept from R1: the fully-applied `_zero`
lemmas (F3), Q1's namespace decision, the FUEL class with F4/F5 wording
(the harness string now explicitly reporting-only), the mechanism-then-
budget split (F2), the erratum (F7), Q2/Q4 rulings, §0 facts (the
`Loc.unknown` fact retained as history, no longer load-bearing).

**R1 (review of `dd61ab87a`):** F1 `Loc.unknown` mitigation deleted and
the invariant re-scoped (now superseded by C); F2 10^8 unreachable in
gate lanes, per-commit movement columns, two-commit split, §4.5
reworded; F3 lemmas fully applied; F4 `ERR:` verdict + merged-capture
classifier; F5 five classifying vs six byte-compare lanes; F6 harness
copy acknowledged; F7 erratum confirmed with two verifications; F8
cites (:686, :947-949, 9 SKIP_LEAN_CRASH); Q1-Q6 rulings logged.
