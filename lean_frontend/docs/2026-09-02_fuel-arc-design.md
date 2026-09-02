# FUEL arc — design note: a kernel-transparent, distinguished fuel-exhaustion outcome

Date: 2026-09-02. Branch `arc/fuel` off mainline `2c7c9347b`. Docs-only
slice (this note); the implementation slice is §6. **Revision R1**
(same day): the fresh review of `dd61ab87a` returned
RATIFY-WITH-AMENDMENTS (F1-F8 + Q-rulings); every amendment was
re-verified against the tree before absorption; the R1 delta is listed
in §8.

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
  item) is BUNDLED into this arc (§4), as the SECOND of two commits
  (§6, F2).
- [AGENT 2026-09-02, orchestrator, R1 F1(d); within the operator's
  Option A — still the existing `Error` constructor, unwrapped;
  operator-overridable]: the sentinel's LOCATION is `Loc.other
  fuelExhaustedMsg`, not `Loc.unknown` — the structural closure of the
  distinctness argument (§1.3, §2).
- [AGENT 2026-09-02, orchestrator, R1 Q-rulings; operator-overridable]:
  Q1 keep `CerbFuel` + `CerbND`, re-export in `CerbND`; Q2 no change;
  Q3 YES — the runner leaf becomes the same kill (after `prune/relsem`
  lands, subject to consumer ack); Q4 family = the six; Q5 erratum
  CONFIRMED; Q6 decidable predicate suffices. Details §7.

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
   constant (§1.1 mechanism).
4. **The gcc ledger's fuel rows are `SKIP_LEAN_CRASH`, not
   `SKIP_LEAN_FAIL`**: `scripts/gcc_oracle_baseline.txt:1145`
   `csmith/sia_csmith_477.c SKIP_LEAN_CRASH -`, :1437
   `csmith/sia_csmith_769.c SKIP_LEAN_CRASH -` (the ledger carries 9
   SKIP_LEAN_CRASH rows today; the lane record's "10" at
   docs/2026-08-30_gcc-oracle-lane-record.md:71 is that record's date);
   :71 names them as the fuel deaths ("csmith sia_477/769 (`lem: fuel
   exhausted` = the committed LEAN_CRASH rows)"). The same two files are
   `LEAN_CRASH` in `scripts/exec_csmith_corpus_baseline.txt:1177,1469`.
5. **Erratum, CONFIRMED (two independent verifications, R1 F7).** The
   C1 manifest's apply-condition statement
   (docs/2026-08-31_C1-change-manifest.md:171-176, "zero current lane
   baselines contain a fuel-exhaustion row (measured: grep …)") and the
   adoption record's (d) (docs/2026-09-01_C1-adoption-record.md:183-191)
   are contradicted by the committed rows. Verification 1 (this note's
   author): the four rows in §0.4 at `2c7c9347b`. Verification 2 (the
   R1 reviewer): at the C1 manifest commit `c7cb5380d` both baselines
   ALREADY carried the rows (`git show c7cb5380d:scripts/
   gcc_oracle_baseline.txt` :1145/:1437 SKIP_LEAN_CRASH; `…exec_csmith_
   corpus_baseline.txt` :1177/:1469 LEAN_CRASH — re-run and confirmed
   here), and the fuel attribution predates C1 in three records
   (docs/2026-08-21_arc10-results.md:365 "CEILING_FUEL … sia_csmith_477/
   769", docs/2026-08-20_arc10-s4-csmith-campaign.md:434 "2 LEAN_CRASH —
   CEILING_FUEL: sia_csmith_477/769", the gcc lane record :71). The C1
   measurement was VACUOUS: no fuel class existed to grep for, and the
   glob did not include `gcc_oracle_baseline.txt`. Disposition: the
   implementation slice adds a labeled erratum to BOTH records (§6).
6. LemLib cites: `fuelExhaustedWith` is at `lean-lib/LemLib.lean:184-187`,
   `fuelExhausted` at :192-193, `lemDefaultFuel := 1000000` at :56
   (brief said ~170-186).
7. Main.lean has TWO kill-printing paths: batch (`Error {msg: "…"}`,
   Main.lean:918-919 — what every harness parses) and non-batch
   (`result: Killed (error: {msg})`, :947-949). The brief cited only the
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
12. (R1) `Loc.unknown` is NOT a discriminator for kills — §1.3 / §2
    below; the R0 mitigation that relied on it is deleted.
13. (R1) 10^8 fuel is UNREACHABLE inside every gate lane's timeout —
    §3.3 / §4.5 below; R0's expected-movement table was wrong for the
    post-budget column.

## 1. CUSTOMER CONTRACT (standalone for refined-cerberus)

This section is self-contained: a consumer can read it without the
rest of the note. Names are final unless §7 changes them; the consumer
is invited to object before the implementation slice.

### 1.1 The export

```lean
-- lean_frontend/CerbFuel.lean  (hand-written seam, imported by the
-- generated Nondeterminism.lean via `declare {lean} extra_import`;
-- THE occurrence of the literal in Lean/lem/Core-text sources)
namespace CerbFuel
def fuelExhaustedMsg : String := "lem: fuel exhausted"
def driverFuel : Nat := 100000000        -- §4; = 10^8
end CerbFuel

-- lean_frontend/CerbND.lean  (hand-written seam; already home of runND)
namespace CerbND
export CerbFuel (fuelExhaustedMsg driverFuel)   -- one namespace for the consumer

/-- The distinguished fuel-exhaustion kill. `'err`-polymorphic: it never
    mentions the error type, so it is the same value in `driverM`
    (`kill_reason driver_error`) and `impl_memM` (`kill_reason mem_error`).
    BOTH components carry the reserved message: the location is
    `Loc.other fuelExhaustedMsg`, never `Loc.unknown` (§1.3). -/
def fuelExhaustedKill {err : Type} : kill_reason err :=
  Error0 (CerbLocation.Loc.other CerbFuel.fuelExhaustedMsg) CerbFuel.fuelExhaustedMsg
end CerbND
```

`kill_reason` is the generated type (Nondeterminism.lean:54-62;
constructors `Undef0 | Error0 | Other`, the lem-mangled names of
nondeterminism.lem:19-22 `Undef | Error | Other`; the OCaml side carries
the same mangled names, backend/common/driver_ocaml.ml:173-179).
`CerbLocation.Loc` is the hand-written location type (CerbLocation.lean:
29-35: `unknown | other : String → Loc | point | region | regions`;
`CerbLocation.unknown` at :78 is a `def` alias of the constructor). The
`'err` instantiation the consumer's driver theorems need is
`driver_error` (driver.lem:116); nothing in the contract depends on it.

### 1.2 The guarantee (the fuel-zero arms)

For each of the NINE ND-typed fueled workers, the generated fuel-zero
arm is, with NO opaque wrapper,

```lean
| 0 => ND (fun st => (NDkilled (Error0 (CerbLocation.Loc.other CerbFuel.fuelExhaustedMsg) CerbFuel.fuelExhaustedMsg), st))
```

(`liftAction` returns `nd_action`, not `ndM`, and is curried on its
scrutinee, so its arm is `fun _ => NDkilled (Error0 (…) …)`;
`drive_nonmemory_steps_aux2` has a trailing curried list argument, so
its arm is `fun _ => ND (fun st => …)`. These are the SAME shapes the
arms have today, minus `fuelExhausted (…)`.)

Shipped, kernel-checked (`rfl`), one per worker, FULLY APPLIED (the
generated workers take the reader argument `_lemReader_tagDefs` where
their lem definition reads `tagDefs`; signatures at Driver.lean:231,
:346, :380, Nondeterminism.lean:188, :306, :309, Defacto_memory.lean:805,
:820, :899). The consumer should cite these rather than the generated
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
end CerbND
```

(Implicit type arguments are elaborated; the exact binder names follow
the generated signatures at implementation and are recorded in the
change manifest.) Note for `liftAction_lemFuel_zero`: the fuel-0 arm
DISCARDS the incoming action — including a genuine kill it was lifting
— and reports exhaustion; that is the correct reading (the lift did not
complete), and it is the shape the type forces (Q2).

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
namespace CerbND
theorem fuelExhaustedKill_ne_Undef0 : fuelExhaustedKill (err := err) ≠ Undef0 loc ubs
theorem fuelExhaustedKill_ne_Other  : fuelExhaustedKill (err := err) ≠ Other e
/-- Matches `Error0 (.other s₁) s₂` and decides `s₁ = fuelExhaustedMsg ∧ s₂ = fuelExhaustedMsg`
    (constructor match on `Loc.other`; String has decidable equality). -/
def  isFuelExhaustedKill : kill_reason err → Bool
theorem isFuelExhaustedKill_iff : isFuelExhaustedKill r = true ↔ r = fuelExhaustedKill
instance : DecidablePred (fun r : kill_reason err => r = fuelExhaustedKill)
end CerbND
```

The first two are by constructor disjointness; the `iff` is by cases.
This is the "decidable equality on status" the request asks for,
delivered as the decidable predicate actually needed. A full
`DecidableEq (kill_reason driver_error)` is NOT promised (Q6): the type
derives only `BEq, Ord` (Nondeterminism.lean:62) and a full instance
would need `DecidableEq` on `Loc` and `undefined_behaviour`.

**How an `Error` kill arises in the semantics (verified, R1 F1).** Every
`Error0` kill originates at ONE site: core_eval.lem:605-606, `PEerror
str debug_pe -> Exception.return (Undefined.error loc str)`
(`Undefined.error loc str = Error loc str`, undefined.lem:1453-1454),
lifted into the ND monad by the four `ND.kill (ND.Error loc str)` at
driver.lem:182, :411, :432, :443. Its two components:

- `str` is the string of a `PEerror` Core expression. Those come from
  exactly two producers: (i) the shipped C→Core translation —
  `Caux.mk_error_pe` (core_aux.lem:382) at translation.lem:2699, :2702,
  :2712, :2717, :3129, :3142, three distinct literals (`"assert()
  failure"`, `"assert() unspecified"`, `"__bmc_assume() unspecified"`);
  (ii) Core TEXT parsed at runtime — `runtime/libcore/std.core` (9
  `error(<<<…>>>)` occurrences), `std_inner_arg_temps.core` (9),
  `impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl` (2; the i686 impl
  has 0), `tests/libc/libc.core` (12 quoted `error("…")` occurrences) —
  ELEVEN distinct literals in total across (i)+(ii) (`align_alloc_proxy`,
  `decodeTwos`, `encodeTwos`, `integerDecode`, `integerEncode`,
  `is_representable_floating`, `malloc_proxy`, `params_nth`, `wrapI`,
  and the two `assert()` strings shared with (i)); all fixed text.
  Substitution and rewriting preserve the string (core_aux.lem:954,
  :1226; core_rewrite2.lem:439, :566).
- `loc` is `th_st.current_loc` (core_run.lem:165, :171), initialised
  `Loc.unknown` (driver.lem:502, :1572) or `Loc.other "global(…)"` /
  `Loc.other "Driver.drive"` (:1600, :1876), updated ONLY by
  non-library `Aloc` annotations (core_run.lem:776-784); two further
  evaluator entries pass a fixed `Loc.other` (`"Driver.print_eval_conv_
  aux"` driver.lem:141, `"Driver.hack"` :1448). So **`Loc.unknown` is
  NOT a discriminator**: a library-Core `error(…)` evaluated before the
  first located expression kills at `Loc.unknown`. (R0's "mitigation 4"
  relied on it and is deleted.) The model's many other `Loc.other`
  strings (`"update errno"`, `"argv init"`, `"printf()"`, … —
  driver.lem, formatted.lem, defacto_memory.lem) are MEMORY-OP
  locations and never enter a `kill_reason`.

**The distinctness INVARIANT, scoped exactly:** for Core produced by
the shipped C→Core translation together with the pinned runtime Core
libraries (std.core, std_inner_arg_temps.core, the impls, libc.core),
**no execution produces `fuelExhaustedKill` other than by fuel
exhaustion** — by FINITE ENUMERATION of the eleven `PEerror` literals
above, none of which is `lem: fuel exhausted`, gate-enforced
(`check_fuel_literal.sh`, §6: a comment-stripped token scan of the
reserved literal over `frontend/**/*.lem`, `runtime/libcore/**`,
`tests/libc/libc.core`, `lean_frontend/*.lean`, `lean_frontend/
generated/*.lean` — expected hits: `CerbFuel.lean` and its `generated/`
copy only). The LemLib panic message of the pure-worker sentinel
(`fuelExhausted`, LemLib.lean:192-193) is the same string but is a
runtime STDERR text of an opaque constant, never a `kill_reason` value;
it is outside the invariant's scope and stays. The harness's own copy of
the literal (`scripts/common.sh`, §3) is outside the Lean/lem/Core-text
scope and is pinned to `CerbFuel.lean` by a selftest (§3.4, F6).

**Against ARBITRARY Core text the string invariant is FALSE, stated
honestly (R1 F1c):** `CoreParser.lean:1103-1114` accepts any
`error("…", pe)` — it is how libc.core's `error("assert() failure", …)`
is read — at `loc0 = CerbLocation.unknown` (:201-204), and Main parses
Core files from disk (`--libc`, Main.lean:611-613). A hand-written Core
file may therefore contain `error("lem: fuel exhausted", …)`. Two
closures are shipped, structural and independent:

1. **The location component (adopted, [AGENT] R1 F1d).** The kill's
   location is `Loc.other fuelExhaustedMsg`. `CoreParser` emits only
   `loc0` (verified: no other `Loc` construction in CoreParser.lean);
   the model's `.other` strings that can reach a kill are the four
   literals above; `CabsImport.lean:125` can carry a JSON `Loc_other`
   string into an Ail location (and thence, via `Aloc`, into
   `current_loc`) but never into a `PEerror` string. Forging the full
   `fuelExhaustedKill` therefore needs an adversarial cabs-JSON AND an
   adversarial Core file at once. Zero runtime or consumer cost; the
   `_zero` lemmas and `isFuelExhaustedKill` are unchanged in shape.
2. **A per-file structural side condition** for consumers who run Core
   text from disk:
   ```lean
   namespace CerbFuel
   /-- Decidable over syntax: every `PEerror s _` in the file has `s ≠ fuelExhaustedMsg`. -/
   def noReservedPEerror (f : file α) : Bool
   theorem noReservedPEerror_iff :
       noReservedPEerror f = true ↔ ∀ s pe, PEerror s pe ∈ₚ f → s ≠ fuelExhaustedMsg
   end CerbFuel
   ```
   (`∈ₚ` = the pexpr-occurrence relation the implementation defines
   over the Core AST.) NOT provided: the semantic bridge "the file's
   run produces an `Error0`-kill with message `m` only if some
   `PEerror m _` occurs in the file or the pinned libraries" — it is a
   preservation theorem over the whole evaluator; the consumer does not
   need it once closure 1 holds, and it is not promised.

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
  ∀ o ∈ CerbND.runND (driver2_lemFuel fuel fmapEmpty false) dst₀,
    (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)
```

with `dst₀ := (initial_driver_state sup file fs).1` (the consumer's own
production entry, ProdEntry.lean:8-9), and `driveU` deleted from every
export. The `∀ fuel` induction is the consumer's (request item 4).
After Q3 lands (§7), runner exhaustion ALSO appears as a `Killed _
fuelExhaustedKill` element, so the left disjunct covers both fuels.

### 1.5 Not provided

- **Fuel monotonicity** for the driver workers: not provided (request
  item 4: "welcome but not required"). The runner has `runNDFuel_mono`
  for ITS fuel (CerbND.lean header).
- **A distinguished runtime EXIT CODE** for fuel exhaustion: not
  provided; the kill exits 1 like every `Error` kill, mirroring OCaml
  (Main.lean:925-928). Classification is by the message (§3).
- **`DecidableEq (kill_reason driver_error)`**: not provided (Q6).
- **The semantic bridge lemma** for arbitrary Core text (§1.3 item 2).
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
the HARNESS level (request item 2): the classifying lanes assign FUEL,
fail-noisy, never agreement; the byte-compare lanes report DIFF/FAIL
(§3). Nothing becomes quieter; what was a crash is now a reported,
typed outcome that the harness can also count.

**The new risk, named: distinctness is by CONVENTION** (a reserved
string on a general-purpose constructor), where B would have made it
STRUCTURAL. Mitigations, each independently checkable (R1: mitigation 4
of R0 — `Loc.unknown` as discriminator — DELETED as false, §1.3):
1. the reserved-literal gate over the `PEerror`-literal sources
   (§1.3 invariant; §6 plants) — the literal occurs once, by
   construction of the scan, and the eleven model/runtime `PEerror`
   literals are enumerated in the gate's own output;
2. the LOCATION component `Loc.other fuelExhaustedMsg` — structural:
   the Core parser cannot produce it, the translation cannot produce it,
   forging needs two adversarial inputs at once;
3. the named export + `_zero` lemmas — consumers never spell the
   string; a change to it is a change to one definition and its gate;
4. the FUEL harness class is never counted as agreement, so a
   mis-classified fuel death cannot pass a lane silently;
5. for Core text from disk, `noReservedPEerror` (decidable) as a
   consumer side condition.
Residual: a future model edit that constructs a `PEerror` whose string
is COMPUTED (today all are literals) would be caught only at review
time, not by the token gate; and the semantic bridge for arbitrary Core
text is unproved. Accepted, recorded.

**A second fuel exists; Q3 brings it under the same contract.**
`CerbND.runND` is itself fuel-totalized (`runNDFuel`, budget
`ndDefaultFuel := lemDefaultFuel`, CerbND.lean:71, :89-134); its
fuel-zero leaf is today `panic!` returning `[]` (:93; likewise
`runND1Fuel` :182, `runND1TraceFuel` :232) — proof-transparent, "an
exhausted leaf CLAIMS no behaviors" (CerbND header). Under the
consumer's `∀ o ∈ runND …` shape that makes ∀-fuel theorems VACUOUS
beyond `ndDefaultFuel` depth. Ruling [AGENT, orchestrator, Q3]: the
leaves become `[(Killed st0 fuelExhaustedKill, [], st0)]` (`runND1Trace`:
`([], [(Killed …)])`), after `prune/relsem` lands (the RelSem layer
states `runND_sound` against the `[]` leaf) and subject to the
consumer's ack in their review of this note. Main's "runND returned no
executions" guard (Main.lean:900-902) then becomes unreachable for fuel
and stays as a fail-closed guard.

**VALIDATION.md — the paragraph that replaces today's fuel text**
(VALIDATION.md:218-221, "`lemDefaultFuel` = 10^6 … exhaustion aborts
with `lem: fuel exhausted` (LEAN_CRASH class). Raise is lem-side"):

> - **Fuel exhaustion is a typed, distinguished outcome** for the ND
>   monad's fueled workers (the driver loop family, the memory-model ND
>   workers, and the `CerbND` runners): the fuel-zero arm is `NDkilled
>   CerbND.fuelExhaustedKill` (= `Error0 (Loc.other "lem: fuel
>   exhausted") "lem: fuel exhausted"`, transparent to the kernel;
>   `_zero` lemmas by `rfl`; distinctness lemmas + the reserved-literal
>   gate `check_fuel_literal.sh` over the `PEerror`-literal sources make
>   it a kill that Core produced by the shipped translation with the
>   pinned runtime libraries cannot produce; for Core text from disk the
>   decidable side condition `CerbFuel.noReservedPEerror` and the
>   `Loc.other` component are the closure). Budgets: the coupled driver
>   family (`driver2`, `drive_nonmemory_steps_aux2`,
>   `print_eval_conv_aux`, `hack`, `nd_bind`, `CerbND.ndDefaultFuel`)
>   runs at `CerbFuel.driverFuel` = 10^8; every other fueled declaration
>   keeps `lemDefaultFuel` = 10^6 (the L1 opt-in guarantee). Pure-return
>   workers keep the opaque panicking sentinel (exit 134, `lem: fuel
>   exhausted` on stderr). The classifying lanes (`test_exec.sh` and its
>   csmith wrapper, `test_gcc_oracle.sh`, `test_ci_sweep.sh`,
>   `test_cn_coverage.sh`, `tests/mem-scale-probes/measure.sh`) assign
>   the FUEL class to both forms (fail-noisy, never agreement); the
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

Which scripts classify at all (R1 F5): of the ~20 scripts that invoke
the binary, FIVE classify outcomes — `scripts/test_exec.sh` (and
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
  `INTERNAL PANIC`, HANG) — a completed-looking row with an ERR verdict.

So the class is inserted, in every classifying lane, keyed on the
EXACT reserved message (never the loose `fuel exhausted` regex on
stdout), at two points: (a) in the exit ≥ 128 branch, when the capture
carries the panic marker → `FUEL` (sub-kind `panic`); (b) BEFORE the
`Error {` / `SKIP_LEAN_FAIL` fall-through, when the capture carries
`Error {msg: "lem: fuel exhausted"}` → `FUEL` (sub-kind `kill`). Row
names per lane: `FUEL` (test_exec/csmith, test_ci_sweep,
test_cn_coverage; measure.sh note `FUEL(kill|panic);`),
`SKIP_LEAN_FUEL` (gcc ledger taxonomy, `scripts/gcc_oracle_baseline.txt`
header + docs/2026-08-30_gcc-second-oracle-design.md's class table).
Semantics, uniform: fail-noisy (fatal in default mode exactly as
LEAN_CRASH is: test_exec.sh:814 status list gains `FUEL`); baselined
rows are honoured only by the `--check-baseline` machinery; NEVER
counted as MATCH/AGREE, never as "completed" in measure.sh's parity
tallies.

The classifier is factored once into `scripts/common.sh`:
`classify_fuel_outcome <exit> <capture>` over a SINGLE text argument —
the four lane scripts capture `2>&1` merged (test_exec.sh:329-330,
test_gcc_oracle.sh:413-414, test_ci_sweep.sh:287-288,
test_cn_coverage.sh:226/:234) and pass the merged capture; measure.sh
and test_libc_exec.sh split streams (measure.sh:135-136 `time -v -o`
+ `2>&1` into the .err file; test_libc_exec.sh:104 `2> …lean.err`) and
pass the concatenation of their files. Output: `FUEL:kill`,
`FUEL:panic`, or empty (not fuel). `common.sh` therefore carries the
SECOND copy of the literal (R1 F6) — see §3.4 for the drift leg.

Main.lean is NOT changed by the mechanism: the existing `Error0` arms
print the message. (A driver-side "FUEL" banner would be a second
convention to keep in sync; declined.)

### 3.3 Baseline movement expected (enumerated; R1 F2 corrected)

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
0, immaculate 0; exec_debug_baseline.txt:11 mentions "fuel" only in a
header comment). Any row moving that is not in this table is a
FINDING, not a re-baseline.

Consequence, stated plainly (F2 ii): **after commit 2 no standing
baseline row exercises `FUEL(kill)`** — the class is kept honest only by
the classifier selftest, the pinned-literal drift leg (§3.4), and the
commit-1 witness rows recorded in the slice record. That is why the
slice is two commits: commit 1's lane runs are the only time the FUEL
rows appear in real lanes at a committed head.

Whether the two csmith rows were driver-fuel deaths (→ kill) or
pure-worker deaths (→ still a panic, now classed FUEL(panic)) is
determined at commit 1; either way they leave LEAN_CRASH.

### 3.4 Plants (vacuity must be loud)

- Classifier selftest (`scripts/test_unit.sh` leg): fixture captures →
  expected class, including the three negatives (a non-reserved `Error
  {msg: …}` → not fuel, a PANIC without the marker → not fuel, a stdout
  line containing the words "fuel exhausted" in a program's own output →
  not fuel).
- **Literal-drift leg (R1 F6):** the selftest EXTRACTS the literal from
  `lean_frontend/CerbFuel.lean` (`def fuelExhaustedMsg : String :=
  "…"`) and compares it byte-for-byte to `common.sh`'s constant and to
  every fixture; a mismatch is FAIL. Without it, drift would not break
  any lane — a fuel kill would silently fall back to FAIL-class (noisy)
  while the FUEL class died unnoticed.
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
`CerbND` ships `driver2_wrapper_defeq : driver2 = driver2_lemFuel
CerbFuel.driverFuel := rfl` (and siblings for the quartet + `nd_bind`,
and `runND_eq : runND m st = runNDFuel CerbFuel.driverFuel m st := rfl`),
with `driverFuel_eq : CerbFuel.driverFuel = 100000000 := rfl`. Statement
for the consumer's manifest: **every exported statement over the drive
cone (`drive`, `driver2`, `nd_bind`, `runND`) has fuel side condition
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

### 4.5 The grind tripwire (R1 F2 iv)

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

## 6. SLICES + GATES

**One implementation slice, TWO commits** (R1 F2 iii), dispatched AFTER
`prune/relsem` merges:

- **Commit 1 — mechanism**: §1 (nine sentinels, `CerbFuel.lean`,
  `CerbND` exports/lemmas, `noReservedPEerror`), §3 (FUEL class in the
  five classifying lanes, `common.sh` classifier + selftest + drift
  leg), the reserved-literal gate, the `sorry` closure + token leg (§5),
  VALIDATION/LADDER/TODO text, the C1 errata (§0.5), and the Q3 runner
  leaves. Gate run at this head INCLUDES the gcc lane and the csmith
  corpus lane so the FUEL rows appear in real lanes and are RECORDED
  verbatim (the witness); the four baseline rows move to their
  commit-1 column (§3.3).
- **Commit 2 — budget**: the six L1 declares + `ndDefaultFuel`, the
  `driverFuel` wrapper `rfl`s, the mem-scale re-measurement; the four
  rows move again to their commit-2 column, enumerated; the consumer
  side-condition statement (§4.3) is final at this head.

Dependency, precisely: `prune/relsem` (worktree present at `2c7c9347b`,
no commits yet) will touch the RelSem-referencing set — Main.lean
(`RelSem.Cerb.callND`, :880-884), scripts/check_theorem_axioms.sh and
check_exec_totality.sh (cone/census entries), scripts/test_verify.sh,
test_immaculate.sh, lean_probe.sh, lean_frontend/lakefile.toml — and
retires `runND_sound`, which is why Q3 waits for it. This arc touches:
frontend/model/{nondeterminism,driver,defacto_memory}.lem (declares
only), frontend/concurrency/cmm_op.lem:17, NEW lean_frontend/
CerbFuel.lean + handwritten_copy.manifest, lean_frontend/CerbND.lean,
scripts/common.sh + the four lane scripts + tests/mem-scale-probes/
measure.sh, NEW scripts/check_fuel_literal.sh (+ the sorry leg, kept in
its own script to stay out of check_theorem_axioms.sh), the two csmith
baselines + the gcc ledger taxonomy, VALIDATION.md, LADDER.md (Tier A
row for the new gate), TODO.md (the ceiling entry :21-30 re-stated),
docs/2026-08-31_C1-change-manifest.md + docs/2026-09-01_C1-adoption-
record.md (labeled errata, §0.5). Overlap is avoided by design
(Main.lean untouched; census script untouched); the ordering is still
required because the full battery must be run at a head that contains
both, and Q3 edits the file `runND_sound` is stated against.

Gates (full battery per scripts/LADDER.md Tier A+B, plus the gcc lane
and the csmith corpus lane), and the plants:

| gate | red-plant |
|---|---|
| `check_fuel_literal.sh` — reserved-literal token count over `frontend/**/*.lem`, `runtime/libcore/**`, `tests/libc/libc.core`, `lean_frontend/*.lean`, `lean_frontend/generated/*.lean` == the `CerbFuel.lean` def + its `generated/` copy; ALSO prints the enumerated `PEerror`/`error(` literal set (§1.3) so the enumeration is a gate output, not prose | (a) plant `error("lem: fuel exhausted", …)` in a scratch copy of std.core → red; (b) plant the literal in a model `.lem` body → red; (c) delete the `CerbFuel` def → count 0 → red (vacuity) |
| the nine `_zero` lemmas + distinctness lemmas + `noReservedPEerror_iff`, in a `check_theorem_axioms.sh`-style cone probe kept in the new script (no `sorryAx`, no `ofReduce*`) | replace a `rfl` with `sorry` in a scratch → red |
| `check_fork_drift.sh` Layer 2 byte-green with ZERO manifest change | (the OCaml-neutrality proof; a planted `.lem` body edit → red, already plant-tested) |
| `check_handwritten_sync.sh` — `CerbFuel.lean` in the manifest and byte-pinned | unlisted file → red (existing behaviour) |
| FUEL classifier selftest + literal-drift leg (§3.4) | fixture negatives; a one-byte change to `common.sh`'s constant → red |
| `sorry`-token leg | planted token → red; empty set → red |
| Differential: Tier A+B byte-at-baseline; gcc lane + csmith corpus lane at baseline with exactly the §3.3 movement for the respective commit | any other row moving is a finding |

Consumer change manifest (what the re-export carries):
- names: `CerbFuel.fuelExhaustedMsg`, `CerbFuel.driverFuel`,
  `CerbFuel.noReservedPEerror(_iff)`, `CerbND.fuelExhaustedKill`,
  `CerbND.fuelExhaustedKill_ne_Undef0`, `CerbND.fuelExhaustedKill_ne_Other`,
  `CerbND.isFuelExhaustedKill(_iff)`, the decidable-predicate instance,
  the nine `CerbND.<worker>_lemFuel_zero` (§1.2, fully applied), the
  wrapper `rfl`s `CerbND.<member>_wrapper_defeq` + `runND_eq` against
  `driverFuel`, the Q3 runner-leaf lemmas `runNDFuel_zero`,
  `runND1Fuel_zero`, `runND1TraceFuel_zero`;
- the fuel side-condition statement of §4.3;
- the deleted-`driveU` expectation: the consumer's partial-correctness
  exports (API.lean:77-78, TotalAdequacy.lean:36-39, PROVISIONAL over
  `driveU`; 149 `driveU` references across 10 files at the audit-
  response-3 head) are re-stated over `driver2_lemFuel` per §1.4 and
  the PROVISIONAL label is removed by the consumer.

## 7. QUESTIONS — R1 rulings [AGENT, orchestrator, operator-overridable]

- **Q1 — two namespaces.** RULED: keep `CerbFuel` (pre-Nondeterminism:
  message + budget constants + `noReservedPEerror`) and `CerbND`
  (post: the kill, lemmas, runners); `CerbND` carries `export CerbFuel
  (fuelExhaustedMsg driverFuel)` so the consumer imports ONE namespace.
- **Q2 — `liftAction`'s arm shape.** RULED: no change (forced by type:
  it returns `nd_action`, curried on its scrutinee). Documented in
  §1.2: the fuel-0 arm discards the incoming action, including a
  genuine kill it was lifting, and reports exhaustion.
- **Q3 — the runner's own fuel.** RULED YES: `runNDFuel 0 m st0 =
  [(Killed st0 fuelExhaustedKill, [], st0)]`, likewise `runND1Fuel`
  (CerbND.lean:182) and `runND1TraceFuel` (:232, `([], [(Killed …)])`),
  AFTER `prune/relsem` lands (it retires `runND_sound`, stated against
  the `[]` leaf) and SUBJECT TO the consumer's ack in their review of
  this note. Reason: the `[]` leaf makes ∀-fuel theorems vacuous beyond
  `ndDefaultFuel` depth.
- **Q4 — budget family membership.** RULED: the six; the defacto trio
  and `liftND`/`liftAction` stay at 10^6 (operand-bounded measures; the
  FUEL class will surface any death; revisit on evidence).
- **Q5 — erratum to C1 §8.** CONFIRMED by second verification (§0.5);
  both records get a labeled erratum in commit 1.
- **Q6 — `DecidableEq`.** RULED: the decidable predicate `r =
  fuelExhaustedKill` suffices; `DecidableEq (kill_reason driver_error)`
  is NOT promised.

Still open for the CONSUMER's review of this note: (i) ack Q3's runner
leaf; (ii) ack the `Loc.other fuelExhaustedMsg` location (it changes
nothing in the lemma shapes but is visible in the value); (iii) whether
`noReservedPEerror` is wanted at all for their exhibits (they run Core
produced by the shipped translation + pinned libraries, for which the
finite enumeration already closes the invariant).

## 8. R1 delta (review of `dd61ab87a`, absorbed; each cite re-verified)

- F1 (HIGH): `Loc.unknown` mitigation deleted; invariant re-scoped to
  the `PEerror`-literal enumeration (translation + pinned Core text;
  eleven literals, counts per file in §1.3); gate scan moved onto those
  sources; "kill-site enumeration" dropped (it would pass vacuously —
  there is one site); arbitrary-Core falsity stated with
  `noReservedPEerror` as the structural side condition; F1(d)
  `Loc.other fuelExhaustedMsg` adopted — definition, lemmas,
  `isFuelExhaustedKill`, gate, §1 text updated. Reviewer's "impls (2)"
  refined: `gcc_4.9.0…impl` 2, `i686…impl` 0; libc.core carries 12
  quoted `error("…")` occurrences (two literals) among 16 `error(`
  tokens.
- F2 (HIGH): 10^8 unreachable in gate lanes (15-30 s ⇒ ≤ 7×10^6 fuel);
  §3.3 now has per-commit columns with TIMEOUT/AGREE as the post-budget
  destinations; the "no standing FUEL(kill) row" consequence is stated;
  the slice is two commits; §4.5 reworded (55 min rec-shape edge = at
  the tripwire; reachable only in measure.sh / unbounded probes).
- F3: all nine `_zero` lemmas stated fully applied against the
  generated signatures (reader `tagDefs` argument included).
- F4: measure.sh verdict is `ERR:lem: fuel exhausted` (not "NONE");
  classifier is over a single merged capture; split-stream callers pass
  a concatenation.
- F5: "every lane" → the five classifying lanes assign FUEL; the six
  byte-compare lanes report DIFF/FAIL; VALIDATION paragraph updated.
- F6: literal's second copy in `common.sh` acknowledged; "exactly one
  place" scoped to Lean/lem/Core-text sources; drift leg added.
- F7: Q5 erratum confirmed with two independent verifications; both C1
  records get labeled errata in commit 1.
- F8: cites fixed — mem-scale `b_zero_local_10000000` row :686; Main
  non-batch `Error0` print :947-949; gcc ledger has 9 SKIP_LEAN_CRASH
  today.
- Q1-Q6 rulings logged (§7) with [AGENT, orchestrator] provenance.
