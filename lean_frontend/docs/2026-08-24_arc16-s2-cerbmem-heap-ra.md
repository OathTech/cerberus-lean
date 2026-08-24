# Arc 16 S2 — the CerbMem heap RA (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc16-iris-refounding-charter.md`, slice S2 (THE RISK
ITEM, exit ramp attached). Branch `iris-refounding` (off `47da89ffc`,
the S1 close). Companion context: the S0 record (perf cliffs consumed
throughout), the S1 record (the per-step language this state
interpretation couples to). [AGENT] decisions are marked; per the
brief, §1 (the Caesium study) was written BEFORE any design, and §2
(design) before the build.

## 1. The Caesium study (mandated first move)

Read: `deps/refinedc/theories/caesium/{heap.v,loc.v,ghost_state.v}`
in full, `lang.v`/`lifting.v` for how `state_ctx` reaches the WP, and
`lithium/{definitions.v,interpreter.v,proof_state.v}` for the
context-size discipline. Line references below are to those files.

### 1.1 What Caesium's heap RA is

**Physical state** (`heap.v`): `heap_state = { hs_heap : gmap addr
heap_cell; hs_allocs : gmap alloc_id allocation }`. A `heap_cell`
carries `(hc_alloc_id, hc_lock_state, hc_value : mbyte)` — the
authoritative map is at BYTE granularity, and each byte knows its
owning allocation. An `allocation` is `(al_start, al_len, al_alive :
bool, al_kind)`; freeing flips `al_alive` to false and DELETES the
byte range from the heap (`heap_free`), but the allocation record
itself stays (as a tombstone with `al_alive := false`).

**Ghost state** (`ghost_state.v`): FOUR components, one `heapG` class:

1. `heap_ctx h = own γ (● to_heapUR h)` — auth over
   `gmapUR addr (frac × lock_state × agree (alloc_id × mbyte))`:
   per-byte FRACTIONAL points-to with agreement on (allocation id,
   byte value). The fragment is `heap_mapsto_mbyte l q b = ∃ id,
   ⌜l.1 = ProvAlloc (Some id)⌝ ∗ own γ (◯ {[l.2 := (q, RSt 0,
   to_agree (id, b))]})`.
2. `alloc_meta_ctx` — a ghost map `alloc_id ↦ (start, len, kind)`
   whose fragments are PERSISTENT (`↪□`): an allocation's range/kind
   never changes, so range facts (`alloc_meta`, and the derived
   persistent `loc_in_bounds l n`) are shareable knowledge, free to
   duplicate into every pointer-arithmetic side condition.
3. `alloc_alive_ctx` — a ghost map `alloc_id ↦ bool` with FRACTIONAL
   fragments (`alloc_alive id dq a`): liveness is a revocable token;
   full ownership (`DfracOwn 1`) is what `freeable` carries and what
   the free rule consumes; `DfracDiscarded true` gives the persistent
   `alloc_global` for objects alive forever.
4. `fntbl_ctx` — persistent function table (code is not on the heap).

**The value-level points-to is DERIVED, not primitive**
(`ghost_state.v:147-149`): `l ↦{q} v := loc_in_bounds l (length v) ∗
[∗ list] i ↦ b ∈ v, heap_mapsto_mbyte (l +ₗ i) q b` — a big-op over
per-byte fragments plus one persistent bounds fact. All the value
lemmas (`heap_mapsto_app/cons/agree`, fractional splitting) are
proved over that big-op. This is the two-faces rule already embodied:
ONE authoritative map in `heap_ctx`; proof-level assertions are
footprint big-ops.

**The state interpretation** (`state_ctx`, `ghost_state.v:189-197`):
`⌜heap_state_invariant st⌝ ∗ heap_ctx ∗ alloc_meta_ctx ∗
alloc_alive_ctx ∗ fntbl_ctx`. Two structural lessons:

- The PURE well-formedness invariant of the physical state
  (`heap_state_invariant`: cells belong to live allocations,
  allocations in range and pairwise disjoint, live allocations fully
  mapped — 5 conjuncts, `heap.v:594-600`) travels INSIDE the
  interpretation as a `⌜⌝` conjunct, re-established by per-operation
  preservation lemmas (`alloc_new_block_invariant`,
  `free_block_invariant`). Rules get to ASSUME it and must RESTORE it.
- The physical memory operations are RELATIONS in the language
  (`alloc_new_block`, `free_block`), and the ghost laws are stated
  against them: `heap_alloc_new_block_upd : alloc_new_block σ1 kind l
  v σ2 → heap_state_ctx σ1 ==∗ heap_state_ctx σ2 ∗ l ↦ v ∗ freeable
  …` — auth-update lemmas per operation, consumed by the lifting
  proofs of the WP rules.

**Provenance handling**: a location is `loc = prov × addr`
(`loc.v:49`) with `prov = ProvNull | ProvAlloc (option alloc_id) |
ProvFnPtr`. Provenance lives in the POINTER, and the points-to ties
it to the allocation id by a pure conjunct (`⌜l.1 = ProvAlloc (Some
id)⌝`) plus the `agree` component of every byte fragment. Bytes
themselves are `mbyte` (byte | pointer fragment | poison), so byte
ranges can carry pointer provenance through memory — the VIP
`mem_cast` machinery reads it back. Typed/layout views
(`heap_mapsto_layout`, `struct.v`) sit ABOVE the byte points-to as
derived predicates; nothing in the RA is typed.

### 1.2 How Lithium keeps contexts footprint-sized

Lithium goals are one-continuation shaped (`P ∗ T` — every rule's
conclusion threads the remaining obligation `T`), and ownership is
never spilled into a flat context to be re-matched later: when a rule
needs a resource it runs `find_in_context` (`definitions.v:158-172`),
a typeclass/tactic-guided search that selects THE hypothesis matching
a pattern (e.g. "the points-to for location l") and hands exactly it
to the continuation. Together with persistent side-condition facts
(`loc_in_bounds` etc.) living in the intuitionistic context, the
spatial context at any moment is the footprint of the remaining
program — precisely the discipline S0's measurements force on us
(iframe ~quadratic in context width; cliffs at ~150-200).

### 1.3 Inherit / deviate ledger (reuse discipline, point 3)

INHERITED (Caesium's debugged decisions we adopt):

- I1. Byte-granularity authoritative map; value/range points-to as a
  DERIVED big-op over per-byte fragments (+ their app/cons/agree
  algebra). [ghost_state.v:147, heap_mapsto_* lemmas]
- I2. A separate allocation-table ghost map keyed by allocation id,
  distinct from the byte map. [alloc_meta/alloc_alive]
- I3. The pure physical-state well-formedness invariant carried
  inside the state interpretation, with per-operation preservation
  lemmas. [state_ctx / *_invariant]
- I4. Ghost laws stated per physical memory operation
  (auth-update lemmas alloc/free/read/write), consumed by lifting.
  [heap_alloc_new_block_upd etc.]
- I5. Provenance checked as a PURE side condition tying the
  pointer's provenance to the allocation id owned in the ghost
  layer; bytes carry provenance as data. [heap_mapsto_mbyte_def]
- I6. Typed views layered above raw bytes, never in the RA. (S2
  ships byte level; typed views trail to part 2 per charter.)

DEVIATIONS (each with the reason — our model, not preference):

- D1. **One allocation map, full-fraction fragment consumed on kill**
  instead of Caesium's persistent-meta + fractional-alive split.
  Reason: CerbMem's `killM` ERASES the allocation from
  `allocations` and records the id in `deadAllocations`
  (CerbMem.lean:1541-1543) — allocation records are not immutable
  tombstones here, so the persistent-meta half has no physical
  carrier that survives kill. The alive-token role is played by the
  fragment itself (`allocIs aid (own 1) alloc` is exactly Caesium's
  `freeable`). Cost of the deviation: no persistent
  `loc_in_bounds`-style facts for dead-pointer arithmetic; none of
  the four S2 ops needs them. If part 2's pointer-comparison rules
  want them, a persistent meta map can be ADDED without disturbing
  this layer (registered as the known extension point).
- D2. **Kill does not delete the byte range from the heap** (Caesium
  `heap_free` deletes). Reason: physical `killM` leaves `bytemap`
  untouched — mirror-OCaml (impl_mem.ml kill does not clear bytes).
  Consequence: byte points-to SURVIVES kill as stale-byte ownership;
  ACCESS safety comes entirely from the allocation fragment (load
  and store rules demand `allocIs`, mirroring Caesium's demand for
  `alloc_alive`), so use-after-free is unprovable exactly as there.
- D3. **No lock_state / data-race component** in the byte cell.
  Reason: single-threaded per-step instance (S1); the concurrency
  slot is the cmm arc's (forward-design: adding a lock-state
  component to the cell RA is the gen_heap→Caesium delta, known
  shape, not blocked by anything built here).
- D4. **Deterministic allocator addresses** (CerbMem allocates by
  bumping `lastAddress` down; Caesium's `alloc_new_block`
  nondeterministically picks a fresh block). Reason: mirror-OCaml
  byte-fidelity with the oracle — the physical model IS
  deterministic. Consequence: the alloc rule exposes the concrete
  address as a function of the rest-state; address-abstraction is
  spec-layer business, not RA business.
- D5. **The heap sits INSIDE a larger machine state** (driver_state:
  11 fields, of which `layout_state : CerbMem.MemState` with 14
  fields, of which 2 are the heap proper). Caesium's state is almost
  exactly its heap (+fntbl). Ours therefore adds a third resource —
  an exclusive ghost cell for the NON-heap remainder — so that
  memory rules can pin the non-heap state components they read
  (funptrmap, lastUsedUnionMembers, lastAddress, deadAllocations)
  without owning the physical σ wholesale. Lineage: `ghost_var`
  (the standard Iris library, present in the pinned iris-lean) at
  the remainder projection; this is the auth/frag "state lens"
  pattern, not an invention.
- D6. **`funptrmap`/`lastUsedUnionMembers` reads enter as pure
  hypotheses** on the rules (from the rest cell), not as a fourth
  ghost table (Caesium's `fntbl_ctx` analog). Reason: S2's four ops
  only READ them on the scalar paths (function-pointer bytes and
  union readback are the consumers); a dedicated persistent table is
  warranted only when function pointers through memory become a
  target (registered; the rest cell already carries the data).

## 2. The design ([AGENT]; recorded before the build)

### 2.1 The resource

File `relsem/RelSem/CerbHeapRA.lean`. Three ghost components in one
class (Caesium's `heapG` shape, iris-lean vocabulary):

    class CerbHeapGS (GF) where
      [invGS : InvGS_gen .hasLC GF]
      heap  : genHeapGS Address AbsByte GF BytesF   -- BytesF = ExtTreeMap Int · compare
      alloc : GhostMapG GF AllocId Allocation AllocsF
      allocName : GName
      rest  : GhostVarG GF driver_state
      restName : GName

- The BYTE map: iris-lean `GenHeap` AS-IS (reuse discipline point 1)
  at `L = Address (Int)`, `V = CerbMem.AbsByte` — `a ↦{dq} b` is the
  library's `pointsTo`, with `pointsTo_agree/combine/persist`,
  `Fractional`, `Timeless`, `genHeap_alloc/valid/update` all
  inherited. Range points-to is the Caesium-shaped derived big-op:
  `pointsToBytes a dq bs := [∗ list] i ↦ b ∈ bs, (a + i) ↦{dq} b`.
- The ALLOC map: iris-lean `ghost_map` at `AllocId (Int) ↦
  CerbMem.Allocation`; fragment `allocIs aid dq al := allocName
  ↪◯MAP[aid]{dq} al` (D1).
- The REST cell: `ghost_var` at the remainder projection
  `restOf σ := { σ with layout_state := memRest σ.layout_state }`,
  `memRest ms := { ms with bytemap := ∅, allocations := ∅ }`;
  fragment `restIs dq r := restName ↪VAR{dq} r` (D5).

### 2.2 The state interpretation (the ONE authoritative face)

    CerbMemInterp (σ : driver_state) : IProp GF :=
      genHeapInterp (bytesOf σ.layout_state)
      ∗ allocName ↪●MAP (allocsOf σ.layout_state)
      ∗ restName ↪VAR{half} restOf σ
      ∗ ⌜MemInv σ.layout_state⌝

with `bytesOf`/`allocsOf` the `TreeMap → ExtTreeMap` reflections of
the two physical maps (get?-preserving), wired into the per-step
language via a `StateInterp driver_state Empty GF` + `IrisGS_gen`
instance for `KDriveExpr` (the HeapLang `PrimitiveLaws.lean` template
line for line; ns/obs/nt ignored exactly as there). The rest cell is
held in HALVES (ghost_var's standard idiom): the interpretation keeps
one half, the prover holds the other — agreement pins `restOf σ`,
and updates need both halves, which is exactly the update rule shape.
It appears ONLY here and in the adequacy/lifting plumbing (§2.4);
proof-level assertions are `a ↦{dq} b` / `pointsToBytes` / `allocIs`
/ `restIs` — footprints (two-faces rule; S0 flag §5 honored: no
statement or rule carries a flat ∗-chain; ranges are big-ops).

`MemInv` (I3; the subset our four rules consume, each conjunct with
its consumer):

1. `∀ aid ∈ allocations, aid < nextAllocId` — ghost-insert freshness
   at alloc.
2. `∀ aid ∈ deadAllocations, allocations.get? aid = none` — allocIs
   fragment ⇒ the id is live ⇒ the dead-check branch of load/kill is
   not taken.
3. `∀ aid ∈ deadAllocations, aid < nextAllocId` — preservation of
   (2) across alloc.
4. `∀ a ∈ bytemap, lastAddress ≤ a` — the freshly allocated range
   `[alignedAddr, alignedAddr+size)` sits strictly below every
   existing key ⇒ ghost byte-alloc freshness at alloc.

Four preservation lemmas (one per op) re-establish it (I3's shape).

### 2.3 The laws — two layers

**Layer 1 (pure, no Iris)** — `relsem/RelSem/MemLocal.lean`:
locality/characterization lemmas for the four physical operations as
they appear in the exec path (always through the generated lens
`liftMem = liftND (·.layout_state) …`, Driver.lean:218, which by
construction touches ONLY `layout_state`; connected by the committed
`app_liftND_active/killed`). Each lemma computes
`app (op …) st = (NDactive v, st')` from POINTWISE facts about `st`
(bytemap lookups on the footprint, one allocation lookup, dead-list
non-membership, the rest components) — never from a closed `st`.
This is where bind-collapse meets the footprint: one `app` unfolding
evaluates the whole memM operation, and the lemma factors that
evaluation through exactly the facts the ghost layer can supply.

**Layer 2 (Iris)** — `relsem/RelSem/CerbHeapWP.lean`: one skeleton +
four rules.

- Skeleton `wpk_seq_resource_det` (proved once from the generic
  `wp_lift_step`): for an atom `m`, resources `R`, pure footprint
  predicate `Pre : driver_state → Prop`, fixed result `v`, and state
  transformer `upd`, if (a) interp ∗ R ⊢ ⌜Pre σ⌝, (b) ∀ σ, Pre σ →
  app m σ = (NDactive v, upd σ), (c) interp σ ∗ R ==∗ interp (upd σ)
  ∗ R', then `R ∗ (R' -∗ WP (k v)) ⊢ WP (seq m k)`. Lineage: this is
  `wp_lift_atomic_step` specialized to our det-per-resolved-choice
  step relation — the HeapLang primitive-law factoring, not new
  machinery. (A killed-head twin `wpk_seq_resource_killed` covers
  the UB arms if a negative rule is wanted; S2 ships the four
  positive rules.)
- `wpk_load` — consumes `restIs ∗ allocIs aid dq al ∗ pointsToBytes
  addr dq' bs` (fractions suffice: load is read-only), returns them
  unchanged, continuation at `(FP .R addr size, mv)` where `mv =
  reconstructValue r.…unionmap r.…funptrmap addr ty bs` enters as a
  PURE hypothesis (kernel-computable per instance; the value decode
  is a pure function ABOVE the RA, exactly Caesium's abst/mem_cast
  layering).
- `wpk_store` — consumes `restIs ∗ allocIs ∗ pointsToBytes addr
  (own 1) old`, produces `pointsToBytes addr (own 1) new`; scalar
  path (unionMem = none, isLocking = false, `memValueToBytes`
  leaving funptrmap unchanged as a pure hypothesis — D6), so the
  rest cell and alloc table pass through untouched.
- `wpk_alloc` (allocateObject, uninitialized path) — consumes
  `restIs (own 1) r`, produces `restIs (own 1) r' ∗ allocIs id
  (own 1) al ∗ pointsToBytes base (own 1) (replicate size ⟨none⟩)`
  at the model's deterministic address (D4).
- `wpk_kill` (isDynamic = false path) — consumes `restIs (own 1) r ∗
  allocIs aid (own 1) al` (full fraction = Caesium's freeable),
  produces `restIs (own 1) r'`; byte points-to is NOT consumed (D2)
  but is dead capital: no rule accepts it without a live `allocIs`.

### 2.4 Adequacy

`kAdequateHeap_of_wp` re-derives the S1 statement-facing bridge under
the new interpretation: `wp_adequacy_gen` (generic, REUSED) +
ghost initialization from the initial physical state (`genHeap_init`
+ `ghost_map_alloc` + `ghost_var_alloc`, the `heap_adequacy` template)
+ S1's `ksteps_erased`/`ksteps_of_runND` (REUSED). The client's WP
hypothesis receives the initial footprint: big-ops over `bytesOf σ₀`
and `allocsOf σ₀` plus `restIs (restOf σ₀)`, under a `MemInv
σ₀.layout_state` side condition. The authoritative maps appear only
here and in §2.2 — nowhere in client-facing rules.

### 2.5 Instance coexistence with S1 (recorded hazard)

The OwnP interpretation (S1) and this one are BOTH `IrisGS_gen`
routes for `KDriveExpr`; a theorem context selects by which class it
binds (`[CerbGS …]` vs `[CerbHeapGS …]`). WP under one interpretation
is a different assertion than under the other — no file may bind
both classes in one WP statement (nothing does; noted for S3's
tactic authors). The S1 OwnP route and its smoke stay untouched.

### 2.6 Effect-threading forward-design check

The rest cell quantifies over the FULL remainder of `driver_state` —
a seed-parametric state (effect-spike: seed enters through
`initial_core_run_state`'s supply inside `core_run_state0`, a rest
component) is just another value of `r`; nothing here inspects or
fixes the supply. The interpretation is supply-passable by
construction; the open-state rfl hazard (spike record) is dodged
because rules never `rfl` through a closed σ — they route through the
pointwise `MemLocal` lemmas.

## 3. The midpoint checkpoint (charter exit ramp)

RECORDED AT THE MIDPOINT (after the study + the resource definition
compiling green — `RelSem/MemLocal.lean` + `RelSem/CerbHeapRA.lean`
with class/interpretation/IrisGS instance/points-to/extraction laws —
and before the update-law + WP set). VERDICT: **PROCEED** — the RA is
NOT fighting CerbMem's structure.

- The Caesium mapping held with zero structural surprises: GenHeap
  at `Int ↦ AbsByte` (provenance rides IN the byte, exactly mbyte),
  ghost_map for allocations, ghost_var for the remainder. All three
  iris-lean libraries were consumed AS-IS; nothing needed patching.
- The real obstacles hit were ENVIRONMENTAL, not structural, and are
  now one-time-paid:
  1. **The Lem instance jungle** (measured, this is the S2 record's
     headline operational finding): inside the generated import
     closure the ambient `BEq Int` is
     `Lem_Basic_classes.instBEqOfEq0` bottoming out in the
     SetType/Ord comparator — compare-based, NOT defeq-bridgeable to
     the core instance at elaboration transparency — and the
     `Address`/`StorageInstanceId` abbrevs win binop-type inference,
     which makes `omega`/`simp`/TC treat those hypotheses as foreign
     atoms in the package build environment (the LSP env behaves
     differently — S1's probe warning extended: only `lake build` is
     the oracle). Fix: `Int`-pinned binders/ascriptions in every
     arithmetic statement + a once-proved lawfulness bridge
     (`lem_int_beq_unfold`/`lem_int_beq_eq_true_iff`/
     `lem_int_beq_eq_false_iff`/`lem_int_contains_eq_false_of_not_mem`
     in MemLocal). Priced: ~half a session-day of bisection, then
     amortized — every later `==`-side condition routes through it.
  2. **TreeMap→ExtTreeMap reflection**: `toExt` is the quotient
     injection (`ExtDTreeMap.mk`); getElem? commutes by `rfl`,
     insert/erase by one `ext_getElem?` each. Cheap.
- Provenance/byte-granularity interaction (the exit ramp's named
  risk): provenance checks enter the rules as PURE side conditions on
  pointer values, and bytes carry provenance as data — the Caesium
  layering (study I5) transfers unchanged. No wall.

## 4. Reuse-vs-built ledger

| Piece | Status |
|---|---|
| `genHeapGS`/`genHeapInterp`/`pointsTo` + agree/combine/valid/update/alloc/init, Fractional/Timeless instances | REUSED (iris-lean GenHeap, pinned 34390a013398) |
| `ghost_map` auth/frag + lookup/insert/delete/update/alloc | REUSED (iris-lean GhostMap) |
| `ghost_var` + agree/update/halves idiom | REUSED (iris-lean GhostVar) |
| `wp_lift_step` (generic), `wp_adequacy_gen`, `IrisGS_gen`/`StateInterp` shape, HeapLang instantiation template | REUSED (iris-lean) |
| `liftMem` lens equations `app_liftND_active/killed`, `KExpr`/`KStep` + inversions, `ksteps_erased`/`ksteps_of_runND` | REUSED (ours, S1/arc-11) |
| **The four physical op characterizations** — `Kit.mem_load_block`/`mem_store_block`/`mem_alloc_block`/`mem_kill_block` (the arc-9 `@[app_eq]` law table, named-hypothesis form): they ARE the layer-1 locality lemmas, hypothesis for hypothesis | REUSED (ours, arc-9 — the law table surviving the purge earns its keep here) |
| `bytesOf`/`allocsOf`/`restOf` reflections + `toExt` bridge; `writeList` pointwise algebra + `readBytesFrom_of_pointwise`; `MemInv` + 3 preservation lemmas; the ambient-`==` bridge; `CerbHeapGS`/`CerbMemInterp` + StateInterp/IrisGS instances; `pointsToBytes` big-op algebra; extraction + update law set; skeleton + 4 wpk rules; heap adequacy; framing demo | BUILT (this slice, Iris-compatible) |

## 5. Outcomes — the law inventory

Four new modules, all registered (lakefile roots, `RelSemAll`, Audit
import closure + curated pins; sweep re-baselined 3517 → 3692, all
175 new declarations trio-clean):

- `relsem/RelSem/MemLocal.lean` — physical layer: `writeBytesTo_eq`
  + `writeList_get?_notin`/`writeList_get?_in` (the byte-write
  pointwise algebra), `readBytesFrom_of_pointwise`, `alloc_range_le`,
  the ambient-`==` bridge (`lem_int_beq_unfold`,
  `lem_int_beq_eq_true_iff`, `lem_int_beq_eq_false_iff`,
  `lem_int_contains_eq_false_of_not_mem`), `MemInv` + consumers
  (`next_fresh`, `contains_dead_false`, `bytemap_below_none`) +
  preservation (`MemInv.store`/`MemInv.alloc`/`MemInv.kill`).
- `relsem/RelSem/CerbHeapRA.lean` — the resource: `toExt` reflection
  (+`toExt_insert`/`toExt_erase`/`toExt_writeList` ext-commutations),
  the projections, `CerbHeapGpreS`/`CerbHeapGS`, `allocIs`/`restIs`/
  `pointsToBytes` (+nil/cons algebra), `CerbMemInterp` + the
  `StateInterp`/`IrisGS_gen` instances, the KEEP-FORM extraction laws
  (`interp_meminv`/`interp_rest_agree`/`interp_alloc_lookup`/
  `interp_byte_lookup`/`interp_bytes_lookup`), the ghost transports
  (`extWriteList`, `bytesOf_writeBytesTo`, …), the byte-layer ghost
  updates (`bytes_update_ghost`/`bytes_alloc_ghost`), and the
  op-level interpretation updates (`interp_store_update`/
  `interp_alloc_update`/`interp_kill_update`).
- `relsem/RelSem/CerbHeapWP.lean` — the WP layer: the ONE lifting
  skeleton `wpk_seq_res_det` (proved from the generic
  `wp_lift_step`), the FOUR op rules `wpk_load`/`wpk_store`/
  `wpk_alloc`/`wpk_kill` (each = skeleton + Kit block + lens equation
  + interp update; value-level side conditions pure), and adequacy:
  `cerbHeap_adequacy` (the `heap_adequacy` template — ghost
  allocation from the initial physical state, client receives the
  initial footprint as big-ops + the rest half) +
  `kAdequateHeap_of_wp` (the statement-facing runner bridge, S1's
  `kAdequate_of_wp` mirrored onto the heap route).
- `relsem/RelSem/CerbHeapDemo.lean` — `two_alloc_frame` (§7).

Charter task-2's bar — "at least the four core memory operations get
resource-level rules" — is met: load consumes fractional footprint
and returns it; store overwrites at full fraction; alloc mints the
fragment + fresh-range points-to (and moves the rest half); kill
consumes the full fragment (Caesium's freeable) and records death.
Typed views above raw bytes TRAIL to part 2 (charter-sanctioned).

## 6. Axiom cones (VERBATIM, from `#print axioms` in-build; the
    Audit pins enforce the marked subset build-fatally)

```
'RelSem.Cerb.writeBytesTo_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.writeList_get?_notin' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.writeList_get?_in' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.readBytesFrom_of_pointwise' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.alloc_range_le' depends on axioms: [propext, Quot.sound]
'RelSem.Cerb.lem_int_beq_unfold' depends on axioms: [propext]
'RelSem.Cerb.lem_int_beq_eq_true_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.lem_int_beq_eq_false_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.lem_int_contains_eq_false_of_not_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.next_fresh' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.contains_dead_false' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.bytemap_below_none' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.store' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.alloc' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.MemInv.kill' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.toExt_insert' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.toExt_erase' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.bytesOf_writeBytesTo' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.pointsToBytes_cons' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_meminv' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_rest_agree' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_alloc_lookup' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_byte_lookup' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_bytes_lookup' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.bytes_update_ghost' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.bytes_alloc_ghost' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_store_update' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_alloc_update' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.interp_kill_update' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_res_det' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_load' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_store' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_alloc' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_kill' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.cerbHeap_adequacy' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.kAdequateHeap_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.two_alloc_frame' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Every cone is within the classical trio — NO effect-boundary axiom
enters (the rules and adequacy quantify over programs; no harness
substrate is quoted anywhere in this slice). Forward-design: nothing
here can make the runEffectful elimination harder — the layer never
touches the supply.

## 7. The framing demonstration (charter success criterion 2)

`RelSem.Cerb.two_alloc_frame` (CerbHeapDemo.lean): a program that
STORES into allocation A and then LOADS from allocation B, proved
against footprint resources for both. The demonstration is in the
shape, twice over:

- STATEMENT: the load's result `mvB` is determined by hypotheses
  mentioning ONLY B's bytes and the rest state (`hreconB` over `bsB`
  and `r`) — the store to A cannot influence it, by framing, not by
  any computation over a heap.
- PROOF (8 IPM lines): the store step consumes exactly
  {restIs, allocIs A, pointsToBytes A} with B's resources riding the
  frame; the load step consumes exactly {restIs, allocIs B,
  pointsToBytes B} with A's UPDATED resources riding the frame. No
  step's reasoning mentions the other allocation's footprint; no
  concrete heap or driver state appears anywhere.

Non-vacuity: `cerbHeap_adequacy` discharges WPs of exactly this form
against any physical initial state satisfying `MemInv` whose maps
supply the footprint (the big-op handover), and the S1 language the
WP runs over is the production fuel opsem's step relation.

## 8. Perf (vs the S0 guidance)

Fresh clean-elaboration times (forced rebuild, `lake build` lines
verbatim):

```
⚠ [369/375] Built RelSem.MemLocal (865ms)
✔ [370/375] Built RelSem.CerbHeapRA (1.1s)
✔ [371/375] Built RelSem.CerbHeapWP (1.0s)
✔ [372/375] Built RelSem.CerbHeapDemo (831ms)
```

(the MemLocal ⚠ in that pass was the since-pruned unused-simp-arg
warnings; final build is warning-free on the new modules). All far
below any S0 cliff: goals in the rules carry 2–5 spatial hypotheses;
ranges are big-ops materialized per-byte only inside the two
once-proved inductions (`bytes_update_ghost`/`bytes_alloc_ghost`);
no statement anywhere carries a flat ∗-chain. Default budgets
throughout; zero heartbeat/maxRecDepth changes. One deliberate
reducibility decision, recorded: `CerbMemInterp`,
`instCerbHeapStateInterp` and `instIrisGSCerbHeap` are `@[reducible]`
— required so the adequacy handoff (client WP at the CerbHeapGS
instance vs `wp_adequacy`'s `.mk`-of-stateI instance) unifies at
reducible transparency; these are plumbing-face defs the two-faces
rule already keeps out of proof-level goals, and no elaboration-time
movement was observed after the change (CerbHeapRA/WP timings above
are with it).

## 9. Validation

- relsem `lake build` (capped): green, in-build gates pass —
  `RelSem audit sweep: 3692 declarations … all within the declared
  axiom boundary (0 recorded sorryAx exceptions)` (re-baselined
  3517 → 3692 this slice, provenance comment at the pin; an interim
  3697 existed for one local iteration before the simp-arg prune
  removed 5 instance-equation auxiliaries — never committed),
  `RelSem DAEMON absence gate` OK, `RelSem statement gate: 16 slate
  statements fuel-opsem-clean` (statements untouched).
- `./scripts/test_unit.sh`: `Total: 7 passed, 0 failed`; freeze gate
  line verbatim: `check_chase_freeze: OK — no chase-surface
  imports/uses outside the legacy allowlist (8/8 allowlisted files
  present)`.
- `./scripts/test_verify.sh`: `test_verify: 29 passed, 0 failed
  (5 fixtures, 18 harness points)`.
- Cones §6, pins in `RelSem/Audit.lean` (`#guard_msgs`-enforced).
- No sorries; no new axioms; no edits to any statement, committed
  theorem, or existing proof file — pre-existing files touched only
  by additive registration (lakefile roots, RelSemAll imports, Audit
  imports + pins + re-baseline).

## 10. Walls, parks, and what S3 needs

- PARKED (charter-sanctioned): typed views above the byte layer
  (MemValue-level points-to) trail to part 2; the store rule is the
  scalar path (union member / isLocking / funptrmap-growing stores
  need their own rules when a target requires them); kill is the
  `isDynamic = false` path; killed-head (UB) resource rules
  (`wpk_seq_res_killed` twin) not yet needed by any consumer.
- The Lem-jungle finding (§3) is S2's standing operational hazard
  note for S3's tactic authors: pin arithmetic to `Int` explicitly,
  route `==`/`contains` side conditions through the MemLocal bridge,
  and treat `lake build` as the only oracle (LSP env diverges).
- WHAT S3 GETS FROM S2: per-op WP rules whose side conditions are
  kernel-computable pure facts — exactly the shape wp-tactic
  automation discharges (`decide`/`rfl` per instance); the skeleton
  `wpk_seq_res_det` for any further deterministic atom; the
  extraction/update law pattern for new resources. S3's dnms/driver2
  loop peels (S1 record §5) are unchanged in price; when they land,
  the four rules here attach at per-Core-step granularity without
  modification (they are stated at the `liftMem` atom, which is how
  the exec path emits memory ops).
