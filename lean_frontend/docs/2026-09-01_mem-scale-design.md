# MEMORY-SCALE arc — draft charter v0-R1 (design only; no code in this slice)

Date: 2026-09-01; R1 2026-09-02. Branch `arc/mem-scale` @ mainline
`bbdbacaff`. Author: P0 worker. Status: **DRAFT v0-R1 for operator
ruling** — nothing here is dispatched. R1 absorbs the fresh review of
`9502522e8` (RATIFY-WITH-AMENDMENTS, F1–F9): every reviewer claim was
re-verified against the tree before absorption; deltas from the
reviewer's statements are marked `[AGENT R1]`. Grounding: the measurement record
`2026-09-01_mem-scale-profile.md` (same slice); read it first — every
ranking below cites a table there.

## 0. Rulings this charter is bound by

[USER 2026-09-01] — arc shape, as transmitted in the P0 brief
(paraphrase of the ratified shape; the orchestrator holds the
verbatim): (1) PROFILE first; (2) if the ceiling is an algorithmic
defect (super-linear path), fix it IN PLACE in the same
representation with an ordinary functional-equality proof; (3) ONLY
if a representation change is proven necessary, introduce DATA
REFINEMENT: the simple per-byte model stays THE semantics (untouched
— it is what refined-cerberus reasons about and what the differential
battery validates); a second implementation of the same
memory-operation interface with the efficient representation; an
abstraction function α : MemFast → MemSimple; per-operation theorems
α (fastOp s) = simpleOp (α s); one bind-composition lemma through the
ND monad; both instances run the full differential battery.

[USER 2026-09-01] — ranking rule, verbatim as relayed by the
orchestrator: "Generally we should order these by (performance) *
(trust impact) i.e high performance, low impact on trust would be
best. We should work very hard to keep our trust surface stable i.e
'obviously right' wrt upstream Cerberus."

Consequences adopted here (orchestrator's reading, adopted as the
charter's structure): every candidate is scored on two axes —
measured/estimated performance gain, and TRUST IMPACT as distance
from the "obviously right" mirror of upstream Cerberus's memory
model: **(0)** same representation, same function (equality-proved),
observable model untouched; a SHAPE divergence from the OCaml text is
permitted only as an in-code documented divergence with the OCaml
cite — the mirror doctrine's existing clause (`CLAUDE.md` "Mirror-
OCaml doctrine": "mirror the OCaml with file:line cites, or document
the divergence in-code as deliberate") [R1/F3]; **(1)** representation change hidden
behind the interface with kernel-checked refinement to the untouched
simple model (the simple model remains the mirror; the fast instance
is a proven-equal implementation detail); **(2)** anything that
changes what the reference model IS or how it is compared against
the oracle — out of scope without a separate ruling. Rank by
gain × (1 / trust impact). Sequencing follows the ranking;
refinement-class items only if the class-(0) items leave the measured
ceiling unmet against a stated target.

Standing doctrine applied: profile-before-optimize; no grind;
canon-first (Hoare 1972 data-representation correctness; CompCert's
memory model — abstract interface with a proven implementation;
Cerberus's own `Memory` signature behind which upstream swaps
concrete/symbolic/VIP); kernel-checked only (no `native_decide`,
`bv_decide`, `ofReduce*`); mirror-OCaml doctrine for hand-written
seams; classic terminology, no house jargon.

## 1. Hard invariant of the arc: the trust surface does not move

Stated as an invariant, not a preference [USER 2026-09-01 via the
ranking ruling]:

- `CerbMem.MemState`, `AbsByte`, `PointerValue`, `MemValue`, the
  `memM` operations (`allocateObject`, `allocateRegion`, `killM`,
  `loadM`, `storeM`, `memcpyM`, `memcmpM`, `reallocM`, pointer ops,
  varargs), their definitions' line-by-line correspondence to
  `memory/concrete/impl_mem.ml`, and the differential-validation
  story (`VALIDATION.md`, `scripts/LADDER.md`) are the reference
  model and are **not changed for performance reasons**.
- refined-cerberus consumes exactly this surface today
  (`cerberus-heaplang/CerberusHeapLang/Lang.lean:221` puts
  `CerbMem.AbsByte` inside its heap resource; `Exhibit.lean:39-44`
  seeds states with `CerbMem.allocateObject` over `MemState`;
  `Heap.lean:155-307` states `applyMemM (CerbMem.storeM …) σ = …`
  by `rfl`). Its theorems must continue to be stated over the simple
  instance with the SAME definitions — so every class-(0) change is a
  proved-equal replacement (`rfl`-compatible where the consumer
  unfolds by `rfl`, or accompanied by the equality theorem), and every
  class-(1) change leaves the simple instance textually intact.
- Carve-out [R1/F5], so that S1 does not violate the invariant as
  literally stated: a DOCUMENTED ALGORITHMIC DIVERGENCE — a
  definition replaced by a functionally equal one, with the equality
  theorem kernel-checked and the in-code divergence note carrying the
  OCaml cite — does not move the trust surface. C1 and C3 are of this
  kind. C1 in fact REDUCES divergence: today's Lean already diverges
  from `abst` in shape (`CerbMem.lean:678` INVARIANT note: "differs
  from OCaml's consume-and-return-rest shape … recursive calls
  re-slice"); C1 adopts consume-and-return-rest, minus upstream's
  per-call `List.length` guard.
- Any candidate that requires the reference model to change is
  listed (§3, marked class 2) and is out of scope without a ruling.

## 2. What the measurements say (summary; tables in the profile record)

- The detective hypothesis (Lean OOMs from the per-byte boxed
  representation, OCaml paying "a far smaller constant") is
  **REFUTED** as stated: both detective inputs run under a 32 G RSS
  cap; Lean's peak RSS is within 2–3 % of the oracle's on both; the
  recorded OOMs were `ulimit -v` (virtual address space) artefacts
  (profile §2).
- Per-byte resident cost is shared with upstream by construction and
  linear (ΔRSS exponent 1.0 on every allocation class, both engines):
  uninitialised object ≈ 215–225 B/byte Lean vs 230–240 oracle;
  zero-initialised static ≈ 700 Lean vs 920–1000 oracle (profile §3).
  Isolated (profile §4): one `TreeMap` node = 48 B/byte; the 48-bit
  address keys add ≈ 62 B/byte as heap big-integers (110 B/byte
  total for the bare map at the real address range).
- Aggregate loads are QUADRATIC in the element count on BOTH engines
  (wall exponent ≈ 2.0 on `c_struct_*` 16 K → 256 K, both engines;
  single-trace Lean 1.4–1.5× the oracle's wall at equal RSS): Lean's
  mechanism is `drop`-based re-slicing in `reconstructValue`
  (profile §5.4); upstream's is the per-call `List.length` guard in
  `abst` (impl_mem.ml:929).
- Lean-only constants: big-integer keys (above); the interpreter's
  1.4–1.5× single-trace factor; the exhaustive runner's ~5× on
  4,620-execution fan-outs (profile §3b).
- The Lean driver's ACTUAL ceilings, in onset order, are not memory:
  (i) `lemDefaultFuel = 10^6` (100 K loop iterations, 100 KB
  `memset`, 10^6-element initialisers — registered in TODO.md);
  (ii) a deterministic HANG (all threads futex-blocked, no output,
  no exit) on a 10 M-byte zero-initialised global, onset between 7 M
  and 10 M bytes, while the oracle completes it in 246 s / 7.7 GB
  (profile §6.2–6.3). Both are outside the memory representation.

## 3. Candidates, scored and ranked

Gain is stated against the measured probe classes (profile §3/§4);
"est." marks extrapolation. Trust impact per §0. Ranking = gain ×
(1/impact); class-0 items with real measured gain first; class-1
items only if §4's target is unmet after class 0.

| # | Candidate | Mechanism (classic name) | Gain (measured / est.) | Trust impact | Proof obligation | Rank |
|---|-----------|--------------------------|------------------------|--------------|------------------|------|
| C1 | `reconstructValue` array arm: single linear chunking pass (consume-and-return-rest, OCaml `abst`'s shape minus its per-call `List.length` guard) instead of per-element `drop (i·e) |>.take e` | replace Θ(n²·e) re-slicing with one Θ(n·e) pass | measured: wall exponent ≈ 2.0 on aggregate loads at 16K→256K bytes (profile §3 fits; Lean `--first` 5.85 s → 114 s for 64 KB → 256 KB struct-by-value); in isolation (profile §4) `reconstruct_chararray` 16 K → 64 K → 256 K → 512 K = 0.11 → 1.80 → 28.4 → 113.5 s, exponents 2.02/1.99/2.00, so a 1 MB `char` aggregate load is ~450 s today and ~0.1 s linear. NOTE the oracle is Θ(n²) here too by its own mechanism (impl_mem.ml:929 `List.length bs` per recursive call) — so this fix takes Lean BELOW the oracle's complexity class on aggregate loads; the upstream counterpart is a tray item | **0** — same representation, same observable result; REDUCES divergence (see §1 carve-out); the in-code note must record that the OCaml's `List.length` guard is deliberately not mirrored (documented divergence). Consumer safety [AGENT R1, corrects the reviewer's "nothing unfolds reconstructValue"]: refined-cerberus unfolds `CerbMem.reconstructValue_lemFuel` at `cerberus-heaplang/CerberusHeapLang/TreeRotExhibit.lean:148` and `ListRevExhibit.lean:260` (struct/pointer-typed nodes, then `rfl`-from-`lemDefaultFuel`); those two proofs must be re-checked after C1 (the array arm changes; the struct/pointer arms do not) | `theorem reconstructValue_lemFuel_chunk_eq : reconstructValue'_lemFuel … = reconstructValue_lemFuel …` by induction on the element count from the list lemma `(l.drop (i*e)).take e = (chunks e l)[i]` | 1 |
| C2 | Harness memory limit: `ulimit -v` (virtual address space) is in SEVEN harnesses — `scripts/test_ci_sweep.sh:222,252,258`, `scripts/test_libc_exec.sh:82,90,97`, `tests/parity-probes/run_probe.sh:43,51,56`, `scripts/test_gcc_oracle.sh:361,368`, `scripts/test_libxml2.sh:141,159,191,201`, `scripts/test_libxml2_uri.sh:104,174`, `scripts/test_immaculate.sh:116,123,131` — and `scripts/LADDER.md:73` makes it NORMATIVE ("`ulimit -v 4000000` + timeout (operator directive, arc 5)") [R1/F2, all lines re-verified] | replace by per-test `scripts/capped` with `CERB_MEM_MAX=4G` (RSS via cgroup) — keeps the intended 4 GB blast radius per test, removes the virtual-vs-resident bias (Lean's virtual footprint is ~2–3.6× its RSS: a 4 GB `-v` kills Lean at ~1.7 GB RSS while the oracle runs to 3.1 GB) | removes the detective's two false OOM rows; the libxml2 lanes — exactly the kernel-shaped target of §4 — are biased against Lean today | **0** — harness only, no model text; BUT it supersedes an operator directive, so it REQUIRES a [USER] ruling (Q2) and, per LADDER's own rule ("Baseline updates are instrument changes: never silent, always a dedicated commit with justification"), a dedicated baseline-instrument commit with the before/after rows | none (harness); re-run the class-(b) rows and the libxml2 lanes | 1 (cheap; gated on Q2) |
| C3 | `memValueToBytes` struct arm: reversed-chunk accumulation + one `flatten` instead of `acc ++ pad ++ bs` in the left fold | remove `List.append` in a left fold (quadratic in members × bytes) | est. only — probes here are single-member; matters for kernel structs (tens–hundreds of members) | **0** (note: this is a shared upstream shape, `impl_mem.ml:1207-1212` has the same `acc @ …`; the in-code divergence note is mandatory per mirror doctrine) | `foldl_append_eq_flatten_reverse` — a standard list lemma; result list equal | 3 |
| C4 | Sparse bytemap instance: do not materialise unspecified bytes at allocation (both engines' `fetch_bytes`/`readBytesFrom` already default absent keys to unspecified) | sparse map with implicit default (a classic data refinement) | uninitialised allocation → O(1) instead of ~220 B and ~1.9 µs per byte (profile §3 class a; 10 M bytes: Lean 18.8 s / 2.19 GB → ~0); but zero-initialised statics (the kernel's `.bss`/`.data`, heap `calloc`) still pay ~700 B/byte unless runs are compressed too (profile §3 class a'); NOTE the oracle pays the same or more on both classes, so this widens the Lean–oracle gap in Lean's favour and does not change the differential corpus's economics, which the oracle bounds | **1** — MemState changes (`bytemap` sparser), so it must be a SECOND instance behind an interface; the simple model stays THE semantics; the OCaml mirror of the fast instance is deliberately absent (documented divergence) | α : fill every allocated, absent address with the unspecified byte; per-op `α (fastOp s) = simpleOp (α s)` for the 20-odd `memM` ops; one `nd_bind` composition lemma | 4 (only if §4 target unmet) |
| C5 | Chunked-bytes instance: per-allocation `ByteArray` of values + a shadow map for provenance/`copyOffset` (only pointer-bearing bytes carry metadata) | CompCert-style split of contents vs. metadata; run-length/implicit default for unspecified and zero regions | est. resident ≤ 2–10 B/byte for both uninitialised AND zero-initialised objects; removes the big-integer key per byte (keys become allocation id + `Nat` offset) | **1** — same interface/refinement discipline as C4, larger α and larger proof surface | α : Πalloc, byte i ↦ ⟨prov(meta i), copyOffset(meta i), some (arr[i])⟩ / default; all per-op theorems; the `nd_bind` lemma | 5 (after C4 evidence) |
| C6 | Address keys as `Nat` (scalar up to 2^63) instead of `Int` | avoid heap big-integers per key/step | measured in isolation: 48 → 110 B/byte for the bare bytemap at the real address range (profile §4 `alloc lo` vs `alloc hi`), plus one heap allocation per address arithmetic step | **2 if done in the reference model** (`Address := Int` is the mirrored signature, `impl_mem.ml` uses `Z`); **1 if done inside a C4/C5 instance** (keys are the instance's business) | folds into C4/C5's α | listed; NOT standalone |
| C7 | Interpreter per-step retention (~2.5 KB and ~90 µs per Core step on Lean; the ORACLE retains ~2.5 KB/step too, at ~180–200 µs) and the exhaustive runner's ~5× constant | driver/ND runner (trace/history retention), not the memory model; upstream-shaped | large on long-running programs — but bounded by the oracle's identical retention in any differential lane | 0 (interpreter) — a DIFFERENT arc | its own profile first | out of this arc; flagged |
| C9 | The >7 M-ELEMENT aggregate HANG — RE-SCOPED [R1/F1]: it is in the FRONT END, not `CerbMem`. `--pp-core` alone (no execution) hangs on `char g[8000000]` (re-verified: 30 s wall / 3.6 s CPU, exit 124); the uninitialised 10 M array completes under a 1 MB stack (9.3 s). Mechanism, first-hand (`strace -f`, profile §6.3): the working thread takes `SIGSEGV {si_code=SEGV_ACCERR}` and its very next syscall is `futex(…, FUTEX_WAIT_PRIVATE, 2, NULL)` that never returns — Lean's stack-overflow handler blocks on a contended lock inside the signal handler (signal-handler deadlock) instead of printing "Stack overflow detected. Aborting." Prime candidate recursion: `frontend/model/cabs_to_ail_aux.lem:124` `List.replicate n (mk_zeroInit_aux …)` builds an N-element `ConstantArray`; `frontend/model/ail/genTyping.lem:484` `E.mapM (typecheck_constant loc) csts` → `frontend/model/ail/errorMonad.lem:86-92` `ailErr_mapM` (non-tail: `f x >>= fun z -> ailErr_mapM f xs >>= fun zs -> return (z::zs)`), generated as `partial def` (`generated/ErrorMonad.lean:121`); same shape at `frontend/model/state_exception.lem:79` `foldrM` and `generated/Undefined.lean:1390` `sequence0` (`List.foldr`). Contrast datum (re-verified): the ORACLE under `OCAMLRUNPARAM=l=200000` fails LOUDLY in 0.03 s (`Called from Lem_list.replicate in file "lem_list.ml", line 341`, exit 125) — the same ceiling class, opposite loudness | non-tail monadic `mapM`/`foldrM` over the element list, depth ∝ elements, overflowing the runtime thread's 1 GiB stack (`mmap(NULL, 1073745920, PROT_NONE, … MAP_STACK)` + `mprotect(…, 1073741824, PROT_READ|PROT_WRITE)` in the trace), the overflow unreported | unblocks ≥ 8 M-element static aggregates (the oracle completes them); more importantly turns a silent hang into a loud failure | **0** (front end, no model text) — but the FIX IS A TWO-REPO SHAPE: either a `.lem` change (accumulate-and-reverse `ailErr_mapM`/`foldrM` — upstream-facing → upstream-tray item) or a lem-backend change (tail-recursive rendering), so it follows the two-repo pin dance, not a cerberus-only slice. The `theorem f = fTR` obligation promised in v0 is WITHDRAWN: the generated function is a `partial def` (kernel-opaque), so no equality theorem is available; validation = the differential battery + a COMPLETION gate (the 8 M/10 M probes must complete on both engines). INTERIM = LOUDNESS ONLY, never a stack-size knob (a bumped budget is the registered defect shape): the HANG classification (exit 124 with CPU/wall < 0.1) now in `tests/mem-scale-probes/measure.sh` (verified on the 8 M input: `HANG(cpu 3.17s of 60.09s wall)`), to be added to `scripts/test_exec.sh` and `scripts/test_ci_sweep.sh` in S0 with their baselines. Also: a Lean upstream bug report (signal-handler deadlock after the guard-page `SIGSEGV`) with the strace excerpt | none available (partial def); completion gate + differential | 2 (defect with a located cause class and a two-repo fix path; own slice) |
| C8 | `lemDefaultFuel` ceiling | fuel-totalisation budget (lem-side) | unblocks ≥ 1.7e4-iteration loops / 100 KB memset | 0 (lem arc; already registered in TODO.md with a design doc) | none here | out of this arc; the binding ceiling |

[AGENT] Reading of the table: after C1–C3 the Lean memory model has
NO super-linear path that OCaml lacks, and the per-byte constant is
upstream's. Whether C4/C5 are *necessary* is then a question of the
target (§4), not of parity with the oracle: the oracle itself spends
3.1 GB on a 13 MB object, so "Linux-scale objects are ordinary"
(detective RC-3) is a statement about BOTH engines' representation
inheritance from upstream, and any fix for it is a refinement by
definition — the reference model cannot become sparse without ceasing
to mirror `impl_mem.ml`.

**Recommended route [AGENT]: in-place fixes first; refinement
conditional.** C2 (harness), C1 (+ its equality theorem), C3, and the
C9 tail-recursive rewrite are class-0, measured or located, and
together remove every Lean-specific super-linear path and the silent
hang without touching the reference model. A representation change
(C4/C5) is NOT shown necessary by these measurements: the per-byte
constant is upstream's, and the oracle bounds every differential
lane at the same or higher memory. The refinement track opens only
if the §4 target is measured unmet after S1 — and if the operator
wants Lean to outrun the oracle at Linux scale, which is a
north-star question, not a parity one.

## 4. Target — a PARITY target, already met on every both-complete row [R1/F4]

Proposed target (for operator confirmation, Q1): the kernel-shaped
differential corpus — `deps/CN-pKVM-buddy-allocator-case-study` and
the libxml2 lanes (`scripts/test_libxml2*.sh`) — plus a synthetic
"large static object" lane (`a_zero_global_{1M,10M}`,
`a_uninit_local_10M`) runs on the Lean driver under
`CERB_MEM_MAX=32G` with wall ≤ 3× the oracle's and RSS ≤ 1.5× the
oracle's, in `--first` mode (oracle `--mode=random`).

**Status: MET on every row where both engines complete** (profile §3,
§3b): the recorded single-trace wall ratio is ≤ 1.53× (the reviewer's
re-run of the same rows observed 1.08×; absolute wall figures are
environment-dependent, ratios and exponents are robust — profile
§3.0), and Lean's peak RSS is ≤ the oracle's on every both-complete
row. So this is a PARITY target and S2 is a CONFIRMATION run on the
kernel-shaped lanes, not a search for a gap.

Rule for non-completing rows (fail-closed, never undefined): the
target is evaluated on both-complete rows ONLY. A row that completes
on neither engine is out of the target's domain and reported as such;
a row that completes on the oracle and dies on Lean of fuel (C8) or
the hang (C9) is reported as a **BLOCKER attributed to C8/C9**, not as
a target miss and not silently dropped. The memory model is not
charged for either.

Scale BEYOND the oracle's reach (the oracle bounds every differential
lane at ~3 GB per 13 MB object and ~4.5 KB/byte on `= {0}` locals) is
a values call, Q3 — not a parity measurement.

## 5. If refinement is opened: the design (per the ratified shape)

### 5.1 The parametric interface (mirrors Cerberus's own `Memory` signature)

Upstream selects an implementation of one module signature
(`memory/concrete`, `memory/symbolic`, `memory/vip`, …) behind
`Impl_mem`; the Lean port follows the original system: a structure
(or typeclass) `MemoryModel` collecting exactly the `memM` operations
the driver and libc seam call (the list in §1), parameterised by the
state type, with the ND monad fixed (`ndM a String mem_error
(mem_constraint IntegerValue) σ`). The simple instance is the
EXISTING `CerbMem` definitions bundled unchanged (no re-typing of the
reference model — the bundle is a record of the current names). The
driver (`Main.lean`, `RelSemCore`) becomes parametric in the instance
with the simple instance as default; a flag selects the fast one for
the differential lanes.

### 5.2 The fast representation (C4 first; C5 only with C4 evidence)

C4 (sparse, implicit default): `MemFast.bytemap` holds only written
bytes; allocation records the range; `readBytesFrom` defaults to
unspecified exactly as today. This is the smallest refinement:
α is `fun s => { s with bytemap := fill s.allocations s.bytemap }`
where `fill` inserts the unspecified byte at every allocated-and-
absent address, and the per-op theorems are mostly `simp` over
`TreeMap` lemmas plus the fact that the simple model's `readBytesFrom`
already reads the default.

C5 (chunked + shadow metadata): contents as `ByteArray` per
allocation (values), a `TreeMap` keyed by `Nat` offset for the
pointer-bearing bytes' provenance/`copyOffset`, and an unspecified-
region set; α reconstructs `AbsByte`s pointwise. Bigger proof
surface; only if C4 leaves the target unmet.

### 5.3 The theorems (all kernel-checked; no `native_decide` etc.)

- Per operation `op ∈ §1 list`: `α_op : ∀ s args, (fastOp args).run s
  = let (r, s') := (simpleOp args).run (α s); (r, α⁻¹-free form)` —
  stated as: the ND action results agree and the states agree under
  α (Hoare 1972's commuting-square form, one square per operation).
- One bind-composition lemma: refinement of `nd_bind` from
  refinement of its components (the ND structure is shared, so this
  is a single lemma over `nd_action`'s constructors, by structural
  induction on the fuel-indexed `nd_bind_lemFuel`).
- Consequence: any driver run's observable results are equal under
  the two instances; stated once for `runND`/`runND1`.

### 5.4 Gates (trust stability must be verifiable, not asserted)

- Both instances run the FULL battery (`scripts/LADDER.md` tiers;
  `VALIDATION.md` gates): the differential baselines must be
  bit-identical across instances.
- Refinement theorems kernel-checked, axiom-audited
  (`scripts/check_theorem_axioms.sh`), on the declared-boundary
  list only if unavoidable (none expected).
- **Plant** [USER 2026-09-01 via orchestrator, item 4]: a deliberate
  fast-instance divergence (e.g. `readBytesFrom` returning a zero
  byte instead of the unspecified default for one absent key) MUST
  be caught twice — the refinement theorem for `loadM` fails to
  typecheck, AND the both-instances differential run reports a
  verdict mismatch on a committed probe (`tests/mem-scale-probes/`
  gains an uninitialised-read UB probe for this). The plant is run
  and its two loud failures are quoted verbatim in the slice record
  before the instance is accepted.
- Change manifest for refined-cerberus [R1/F5, sites re-verified]:
  the consumer today `unfold`s `CerbMem.readBytesFrom`
  (`cerberus-heaplang/CerberusHeapLang/Exhibit.lean:121`,
  `ProdExhibit.lean:86`, `ProdEntry.lean:168`,
  `ProdLoopExhibit.lean:428`, `Heap.lean:377`), `CerbMem.storeM`
  (`Heap.lean:324`) and `CerbMem.reconstructValue_lemFuel`
  (`TreeRotExhibit.lean:148`, `ListRevExhibit.lean:260`); it uses
  `CerbMem.memValueToBytes` (`ProdExhibit.lean:103,153`, `Heap.lean:
  122-134`, …) and `CerbMem.allocateObject` (`Exhibit.lean:40,43`,
  `ProdEntry.lean:142,155`, `ProdExhibit.lean:47-64`,
  `ProdLoopExhibit.lean:370-387`) by name. Consequences: C1 touches
  only the array arm of `reconstructValue_lemFuel` — safe for every
  site except the two `unfold`s, which are re-checked; C3 touches only
  the struct arm of `memValueToBytes` — the consumer's uses are
  scalar (`sevenMval`, `longMval`) and go through `.2`/`.length`
  lemmas; any class-1 work must leave all of the above textually
  intact. The manifest is delivered before the merge ask.

## 6. Slice plan (sequenced by the ranking)

- S1 (class 0, this arc's first code slice): C2 (after the Q2 ruling;
  dedicated baseline-instrument commit) + C1 + C3, each of C1/C3 with
  its equality theorem; re-run the detective's
  class-(b) rows and the `c_struct_*`/`reconstruct_*` probes; record
  before/after tables. Expected: quadratic → linear on aggregate
  loads; the harness's two false OOM rows gone. Gate: full battery
  green, theorems kernel-checked, `rfl`-compatibility with
  refined-cerberus's `Heap.lean` uses re-checked (or the equality
  theorem supplied to them).
- S2 (measurement): the §4 target lane, both engines, under the cap.
  Decision point: refinement track opens ONLY on a measured "unmet".
- S3 (class 1, conditional): the interface + simple-instance bundle
  (no behaviour change; battery must be byte-identical); then C4 with
  α, per-op theorems, the bind lemma, the plant, both-instance
  battery.
- S4 (conditional on S3 evidence): C5.
- S0 (before S1, small, cerberus-only): LOUDNESS — add the HANG
  classification (exit 124 ∧ CPU/wall < 0.1, from `/usr/bin/time -v`
  User+System) to `scripts/test_exec.sh` and `scripts/test_ci_sweep.sh`
  (today: `test_exec` treats exit 124 as TIMEOUT, fatal except for
  `*.unsupported.c`; `test_ci_sweep` pins `overall_rc=0` at :169 and
  never fails; the gcc lane ledgers `SKIP_LEAN_TIMEOUT` at :405 — 11
  csmith rows, none C9-shaped; no lane has a CPU-time column) with
  their baseline commits; file the Lean upstream report (handler
  deadlock after the guard-page `SIGSEGV`, strace excerpt in the
  profile). C9's FIX is a separate two-repo slice (lem/.lem shape,
  §3 C9): confirm the recursion by `--pp-core` under a small
  `LEAN_STACK_SIZE_KB` stage-by-stage, then accumulate-and-reverse
  `ailErr_mapM`/`foldrM` in `.lem` (tray) or a tail-recursive backend
  rendering; gate = completion of the 8 M/10 M probes on both engines
  + the full battery. No equality theorem is available (`partial def`).
- Not in this arc: C7, C8 (separate arcs; C8 is lem-side).

## 7. Risks

- Proving `rfl`-compatibility for refined-cerberus's `by rfl` uses
  after C1: a definitional change to `reconstructValue` may break
  `rfl` proofs that unfold it; mitigation — keep the old definition
  as the reference and add the new one with the equality theorem, OR
  confirm no consumer unfolds the array arm (the `Heap.lean` uses go
  through `storeM` on scalars).
- Refinement proof volume (C4: ~20 ops × one square) is real but
  routine; the risk is the ND `nd_bind` fuel indexing — the lemma must
  be by induction on fuel, not by unfolding at the default budget
  (grind-ban companion smell: any `maxRecDepth` bump is a defect).
- The oracle's own 3.1 GB on a 13 MB object means "Linux-scale"
  needs upstream-side work too, or an accepted asymmetry where Lean's
  fast instance outruns the oracle (then the oracle, not Lean, limits
  the differential corpus — a validation-story question for the
  operator).
- Big-integer keys (C6) cannot be fixed in the reference model
  without leaving `Z`'s shape; accepted as inherited unless folded
  into an instance.

## 8. Open questions for the operator (with the reviewer's recommendations, for confirmation)

1. Q1 — target: confirm the §4 PARITY target (kernel-shaped corpus +
   large-static lane; wall ≤ 3×, RSS ≤ 1.5× oracle; `--first` vs
   `--mode=random`; both-complete rows only; C8/C9 rows reported as
   blockers). Recommendation: confirm as stated; it is already met on
   every both-complete row, S2 is confirmation.
2. Q2 — C2 supersedes `scripts/LADDER.md:73` ("operator directive,
   arc 5"): a [USER] ruling is required. Recommended form: per-test
   `scripts/capped` with `CERB_MEM_MAX=4G` (one cgroup per test,
   keeping the intended 4 GB blast radius), NOT one cap per sweep; a
   dedicated baseline-instrument commit per LADDER's own rule; the
   libxml2 lanes re-run first (they are the kernel-shaped target and
   are biased against Lean today).
3. Q3 — values call: if C1–C3 meet the target, PARK the refinement
   track with this charter as its record. Recommendation: PARK — the
   oracle bounds the differential corpus (~3 GB per 13 MB object), so
   a sparse/chunked Lean instance cannot be differentially validated
   beyond the oracle's reach, and C8 (fuel) binds first on
   kernel-shaped programs. Reopen only with a north-star ruling that
   Lean should outrun the oracle.
4. Q4 — `Address := Nat` inside a fast instance: yes in principle
   (class 1, the instance's business); moot unless Q3 opens.
5. Q5 — C9: fix in `.lem` (accumulate-and-reverse, tray) or the lem
   backend (tail-recursive rendering) via the two-repo pin dance;
   interim = LOUDNESS (HANG classification in the lanes), NO stack-
   size knob. Recommendation: exactly that; the knob is the
   registered-defect shape and only moves the silent ceiling.
6. Q6 — `--mode=random` vs `--first` for large-aggregate programs: a
   REPORTING lane only, never a gate; any mismatch is re-run
   exhaustively on both engines before it is counted.
