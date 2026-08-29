# The alloc-ND design evaluation (the August gate, executed)

STATUS: DESIGN-EVALUATION DOCUMENT for the operator conversation —
NOT a decision. Commissioned [USER 2026-08-29]: "figuring this out
requires research now. Notably, this problem has been richly explored
in separation logic / iris, so we should draw on that." Discharges
the standing gate [USER 2026-08-24]: "memory allocation is a subtle
matter for separation logic due to the global effects it hides. This
is *one* way to deal with this, and we should evaluate before
executing." Gates: the V5 heap summit's design, P13's failure clause
+ statement registration (roadmap Q5). All primary sources read
in-tree; file:line cited.

## 0. The measured ground truth (our model; oracle-faithful, unmodifiable)

CerbMem.lean, mirrored per-line from upstream impl_mem.ml:

- **Allocation ids are a monotone counter**: `nextAllocId : … := 0`
  (CerbMem.lean:120), incremented per allocation (:1487, :1511).
  Ids live in their own namespace (`Prov_some allocId` on pointer
  values, :1496) — there is NO static population sharing the number
  line. This is the CompCert `nextblock` situation exactly.
- **Addresses are deterministic**: bump-down from `lastAddress`,
  `alignDown` to the requested alignment (:1476-1478). No ND
  anywhere in allocation.
- **Failure is deterministic exhaustion, not ND null**: `if
  alignedAddr == 0 then NDkilled (MerrOther "out of memory")`
  (:1478, :1507). malloc (via `allocateRegion`, the `dynamicAddrs`
  path) NEVER returns null in this model — the machine dies with an
  error outcome at literal address-space exhaustion, which for
  corpus-scale programs is unreachable by astronomical margin.
- **Free is tombstoned; ids are never reused**: kill/free pushes the
  id onto `deadAllocations` permanently and erases the live entry
  (:1541-1543); double free / non-matching free / out-of-bound free
  are UB179-class failures (:1531-1539).
- **What we already built and proved on top** (V1/V3a): the
  `allocIs` ghost_map (aid ↦ allocation, CerbStateRA.lean:398), THE
  BUMP POINTER AS A GHOST RESOURCE (`allocIs σ.…nextAllocId (.own 1)`
  inside the interpretation, :1015 — the mono-counter/freshness
  token shape), `mrKill` retirement (:1084-1113), and T3's proved
  create/store/kill round-trip at stack discipline — the alloc rules
  fire, mint footprints, and retire them, kernel-checked.

## 1. The reference point: what Caesium actually does (and dodges)

theories/caesium, read at source:

- **Freshness from the semantics**: allocation picks the location
  NONDETERMINISTICALLY under freshness constraints — `aid ∉ dom
  hs_allocs`, `heap_range_free` (heap.v:498-507, AllocNewBlock).
  The gen_heap alloc lemma then hands the logic fresh points-to for
  free. This is the co-designed move our deterministic, oracle-pinned
  allocator does not give us — and, per §2, does not need to.
- **Failure by fiat, everywhere**: `AllocFailS` — EVERY allocation
  may nondeterministically step to the distinguished non-stuck
  outcome `AllocFailed` (lang.v:490-494), and so may every function
  call (stack frames; `CallFailS`, lang.v:471-476). This is their
  finite-memory dodge: exhaustion is never modeled; instead no spec
  ever promises allocation succeeds, and adequacy tolerates
  `AllocFailed` as a legal result. Elegant, and unavailable to us:
  our model has no such transition, and inventing one would break
  oracle fidelity.
- **The ghost design** (ghost_state.v:17-48, 56-95): heap cells carry
  their alloc_id in an agree RA; `alloc_meta id al` = PERSISTENT
  metadata (base/len/kind, `↪□`); `alloc_alive id dq b` = a dfrac
  token for liveness; free flips alive to false, the id stays in the
  map — their id-reuse prevention, functionally our tombstone list.
- **Honest scoring**: genuinely solved by them and inherited by us —
  the aid-keyed ghost structure (we mirrored it at V1, cited
  in-file), the persistent-meta/liveness-token split, dead-id
  permanence. Dodged by co-design — deterministic-allocator
  freshness (they never face it), exhaustion (AllocFailed by fiat),
  and address arithmetic subtleties their `allocation_in_range` is
  cleaner about than real PNVI.

## 2. The freshness triangle: allocation is the EASY corner

The route-A analysis (symbols) established the pattern: fiat
freshness in the logic, paid for at the model. For ALLOCATION IDS
the bill is strictly smaller than for symbols, because the hazard
that forced the consistency bridge does not exist:

| | symbols | allocation ids |
|---|---|---|
| draw mechanism | counter from quantified seed | counter from 0, monotone |
| colliding static population | YES — hash-derived ids (~1e17) | NONE — own namespace |
| freshness | conditional (ConsistentRun) | UNCONDITIONAL THEOREM |
| bridge needed | route A (window apartness) | none — monotonicity suffices |

`aid = nextAllocId > every id in allocations ∪ deadAllocations` is a
plain invariant of the model (monotone counter + tombstones), the
same shape as the V0 anti-vacuity metatheorem and CompCert's
nextblock lemmas. **V5 does NOT need a second consistency bridge.**
The nextAllocId ghost resource already in the interpretation is the
freshness token; the alloc rule's frame-preserving update is the
per-step certificate ("the environment establishes it" — the August
ruling's own phrasing, here with an unconditional theorem behind it).

## 3. The design space

### Candidate A — deterministic-fresh ghost heap (INCUMBENT, completed)
**Classical name**: authoritative ghost heap with allocator-counter
token — gen_heap/Caesium structure over a CompCert-nextblock
allocator. **What it is**: finish what V1/V3a built: malloc mints
`allocIs aid (.own 1) al ∗ pointsToBytes …` by frame-preserving
update at the alloc round (freshness discharged by the monotonicity
theorem — no side conditions reach the user); free consumes both and
retires into the tombstone (the `mrKill` pattern, extended from kill
to the dynamic-free path: one extra premise, the `dynamicAddrs`
membership that free checks at :1538); the LEAK CONJUNCT reads back
as "the authoritative allocation map is empty at exit" ⟺ every
minted `allocIs` was retired — an ordinary readout law.
**The five subtleties**: (1) address observability — compatible by
construction: points-to carries concrete addresses (the gen_heap
discipline we already follow); no address-abstraction/renaming
argument is used anywhere, so the measured falseness of address
equivariance (PNVI casts; the pnvi sweep's stdout diffs) forecloses
nothing A does. (2) provenance in the RA — the RA is KEYED on aid;
pointer values carry `Prov_some aid`; ghost and physical provenance
agree by the coherence invariant, Caesium's agree-RA move mirrored.
(3) failure ND — none exists in the model; the deterministic OOM
kill is excluded by a per-program arithmetic side condition
(allocation footprint ≪ address space — same discipline as overflow
side conditions, minted once; at corpus scale the margin is ~2^60).
(4) finite space/alignment — real and inherited: addresses are the
model's actual aligned bump values; finiteness surfaces ONLY in the
OOM side condition, alignment in the address arithmetic the mem-op
rules already handle. (5) id reuse — never happens (tombstones);
`allocIs` for a dead id is unconstructible after retirement, which
is `∗`'s exclusivity doing its job.
**Cost over existing machinery**: S–M. The T3 legs are the template;
new: the dynamic-free mint class (S), the leak-readout law (S), the
OOM-unreachability side-condition minter (S). **P13 under A**:
outcomes = {Specified (v+1)} — equality, not ⊆; the null branch is
STATICALLY DEAD; family cell F1 withdrawn per the fixture's own
pre-authorized fork (header: "if infallible … F1 cell withdrawn").

### Candidate B — Caesium-style failure-robust specs over our model
**Classical name**: partial-correctness disjunction specs ("malloc
may fail" discipline, VST/Caesium style). Specs say `null ∨ (alloc
∗ points-to)`; P13's F1 stays live; outcomes = {v+1, SENTINEL}.
**Why it fails here**: the SEMANTICS has no failure branch — the
model's malloc never returns null, so `SENTINEL ∈ outcomes` is
FALSE and only ⊆-shaped statements survive; the null arm of every
proof is vacuous — unexercisable code proved "handled", which is
the catechism's vacuity smell wearing a robustness costume. At most
a DOCUMENTATION-level FnSpec shape (the C-source null-check pattern
honored in the contract text), consciously labeled vacuous-at-this-
model. Not recommended even for that without operator appetite.

### Candidate C — model-level failure ND (the filter-family extension)
**Classical name**: assume-not-assert over an ND failure oracle —
the ConsistentRun pattern applied to allocation success. Statements
would quantify over runs where allocation succeeded, keeping F1
semantically live. **Why not now**: it manufactures nondeterminism
the oracle does not exhibit — the model-as-run NEVER fails at corpus
scale, so the quantified "failing runs" would be pure fiction with
no executable member (the exact inverse of the anti-vacuity
discipline; the symbol story's bad runs at least EXIST as model
points). Becomes legitimate only if a real failure source enters
the model (an upstream Cerberus switch, or the cmm-era ND
switchboard). PARK with that trigger; ask upstream at the next
network window if the operator wants the option.

### Candidate D — dealloc-token/fractional refinement (RustBelt flavor)
**Classical name**: cancellable invariants / separate freeable
token. Splits "may access" from "may free". Needed exactly when
SHARING enters (fractional points-to, borrows) — no corpus row has
it (P07/P08/P13 are unique-ownership). Defer to the first sharing
customer; A's exclusive tokens upgrade to this compatibly (the
dfrac slot already exists in `allocIs`'s signature).

## 4. Recommendation (for the conversation, not a decision)

**Candidate A**, priced S–M, with:
- C parked-with-trigger (real failure source), and the upstream
  switch question queued for a network window;
- B's contract-level shape skipped unless the operator wants the
  null-check documentation form despite its vacuity at this model;
- D deferred to the first sharing customer, upgrade-compatible.

Trade-offs stated plainly: A buys the corpus and uri.c-class code
with machinery that is 2/3 already built and proved, at the price of
(i) F1's withdrawal (the corpus loses its live null-branch exercise
— pre-authorized by the frozen fixture's own header, but it is a
family-cell change and the freeze doctrine says operator sign-off);
(ii) theorems that say nothing about allocation failure (true of the
model; a fidelity FEATURE, but worth saying out loud: RefinedC's
specs are failure-robust and ours will not be until C's trigger
fires); (iii) the OOM side condition as a standing per-program
obligation (minted, cheap, but present).

## 5. What V5 inherits (pricing the summit under A)

- malloc/free mint classes on the T3 template + dynamicAddrs premise: S
- leak-readout law (auth-map-empty ⟺ all retired): S
- OOM side-condition minter: S
- P13 statement registered at V5-open (Q5) in the = shape, F1
  withdrawn, core clause unchanged (ownership birth/death + leak +
  v+1) — the statement text change is the pre-authorized fork of the
  frozen header, needing only the operator's confirming word.
- The REAL V5 weight is untouched by this decision: rep predicates
  over π-skeletons, lseg-class machinery for P07/P08 — orthogonal to
  the alloc story, which is exactly what one wants from the
  evaluation: the gate opens without enlarging the summit.

## 6. Open questions for the conversation

1. Confirm the infallible-malloc reading and F1's withdrawal (the
   frozen fixture pre-authorizes the fork; the freeze doctrine still
   wants the explicit word).
2. Any appetite for the upstream failure-switch route (unparks C
   someday; network-window item)?
3. B's documentation-level null-robust FnSpec: wanted, or skipped as
   vacuous (recommendation: skip)?
4. The OOM side condition: statement-level precondition vs
   proof-layer minted obligation (recommendation: proof-layer,
   like overflow side conditions — statements stay boring)?
5. D's token split: agreed deferred until sharing?

## 7. Catechism §VI self-check (on the candidates)

A serves the ∀-input theorems of P13/P07/P08 (§1); amortizes (mint
classes are per-construct, not per-program; §2); lineage named
throughout (gen_heap, Caesium agree/meta/alive, CompCert nextblock,
mono-counter token; §3); the professor reads "malloc gives you the
cell and the right to free it; free consumes both; leaks are the
unreturned tokens" — the textbook story (§4); no enumeration, no
costume — the one vacuity hazard (B's null arm) is named and
rejected rather than dressed up (§5); failure modes are loud (OOM
side condition fails visibly if a program actually approaches
exhaustion; §6); trust surface unchanged — no new axioms, the model
untouched (§7).
