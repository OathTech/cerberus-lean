# cmm/pKVM scoping spike — what memory-model fragment does pKVM actually need?

STATUS: read-only scoping report (spike ratified [USER 2026-08-26];
no code, no builds). Instrument for (a) honest cmm-arc pricing and
(b) target-slate ordering (pKVM buddy vs WireGuard). Evidence:
empirical survey of deps/linux/arch/arm64/kvm/hyp/nvhe/ (the pristine
pKVM EL2 source), deps/CN-pKVM-buddy-allocator-case-study/, the
vendored litreview + iris-lean state, our cmm design seeds. All
tallies below are DERIVED (grep counts over the surveyed tree,
commands reproducible; spot-verified by reading the cited files).

## Headline

pKVM's hyp code is, at the C level, a LOCK-DISCIPLINED SEQUENTIAL
program to within a handful of sites. The ordering-bearing code is
the ticket spinlock itself — ~40 lines of inline asm in a header,
BELOW the C abstraction (Cerberus cannot parse it; it is necessarily
an interface primitive with a contract, under any memory model
whatsoever). The prior art on our exact target (the CN buddy-allocator
case study) verified it as a purely sequential program with an
ownership resource standing in for "lock held" — they COMMENTED OUT
every lock call and the lock field itself. The expensive fragment
(weak memory / LKMM) is needed only to verify the two lock
implementations, not the code between the locks.

## 1. Fragment classification (evidence-counted)

Survey scope: nvhe/*.c (~7.5k LOC; page_alloc, mem_protect, mm, pkvm,
hyp-main, ffa, psci-relay, switch, tlb, trace, setup, etc.).

**(i) Sequential-under-lock — the overwhelming bulk.**
- `hyp_spin_lock/unlock` call sites: 74 across 6 files (derived:
  page_alloc 7, ffa 14, mm 12, pkvm 23, mem_protect 8, trace 10),
  plus pervasive `hyp_assert_lock_held` in mem_protect.c (e.g.
  :503, :527, :816, :895 — the lock-discipline is *asserted* in-code).
- The buddy allocator: every entry point (`hyp_alloc_pages`,
  `hyp_get_page`, `hyp_put_page`) is lock-wrapped
  (page_alloc.c:179-181, 188-190, 212-227); the page refcount is a
  PLAIN non-atomic u16 with an explicit "hyp_pool::lock must be held"
  comment (include/nvhe/memory.h:127); the critical-section
  discipline is stated in-code (page_alloc.c:168-174: transient
  states "can't be observed by well-behaved readers").
- Guest/host page-table logic: `host_mmu.lock` + per-vm `vm->lock`
  (mem_protect.c:47-66 lock_component pattern).

**(ii) Release/acquire — 2 constructs, both ARE locks.**
- The ticket spinlock: include/nvhe/spinlock.h — inline asm,
  `ldaxr`(acquire)/`stlrh`(release), LL/SC + LSE variants. The whole
  inter-CPU ordering story of pKVM concentrates here.
- psci-relay.c:95-106: `atomic_cmpxchg_acquire`/`atomic_set_release`
  on CPU boot args — a hand-rolled trylock.
- Other bare atomics in all of nvhe: ONE further site
  (events.c:21 `atomic_set` on an event-enable flag). `cmpxchg/xchg`
  elsewhere: zero.

**(iii) Genuinely weak (Aarch64/LKMM) — nothing found at C level.**
- `smp_mb/smp_wmb/smp_rmb` in nvhe/*.c: ZERO. No lock-free data
  structures. No seqlocks, no RCU in the EL2 code itself. Nothing in
  the surveyed C exploits ordering weaker than lock
  acquire/release.
- `READ_ONCE/WRITE_ONCE` (~15 sites) classify as: (a) single racy
  reads of HOST-owned (adversarial) memory — pkvm.c:342, 435,
  462-464, 525-529, 822, 828; hyp-main.c:146 — the "input from an
  untrusted racing environment" idiom, no ordering exploited (an
  ND-value volatile-read primitive models it; fits our choice-stream
  machinery naturally); (b) page-table writes vs the HARDWARE walker
  — mm.c:239, 261 with `dsb(ishst)` (class iv); (c) trace ring
  status spin, trace.c:288 (debug infra, out of verification scope).

**(iv) Outside any C memory model — substantial, but orthogonal.**
- TLB/cache maintenance (tlb.c — dsb ish/nsh reasoning in comments
  :35-51), sysreg context switching (switch.c, sysreg-sr.c,
  debug-sr.c — isb/dsb density), EL2 entry/exit (.S files: host.S,
  hyp-init.S, cache.S), page-table-vs-MMU coherence (mm.c:240, 272).
  This is a HARDWARE-INTERFACE BOUNDARY story (axiomatized
  primitives with contracts) required under ANY memory-model choice
  — it, not the C memory model, is the bigger TCB question for
  full pKVM, and it is severable (the buddy allocator touches none
  of it except `memset`).

## 2. The buddy allocator specifically

Class (i) pure: all shared state (`pool->free_area`, `pool->lock`,
vmemmap refcounts/orders) is pool-lock-protected; internals
(`__hyp_attach_page`, `__hyp_extract_page`, `__find_buddy_*`) are
plain sequential C. `hyp_split_page` (no lock, page_alloc.c:193) runs
under the caller's ownership of a private page.

The CN case study (Pulte/Sewell/Makwana) confirms the shape: locks
commented out (their page_alloc.c:587-671, gfp.h:22 — lock field
removed), verification is sequential with `Owned(pool)` +
`hyp_pool_wf` as the resource/invariant; ownership transfer happens
where the lock calls were. One `trusted` memset primitive. Their
proof = exactly our segment-layer shape (per-function pre/post +
loop invariants + Coq lemmas for the tree arithmetic).

**Consequence: the pKVM buddy target needs NO cmm arc.** It needs
the segment layer + FnSpec + one lock-contract idiom (lock() yields
the pool footprint + invariant; unlock() returns it) with the
spinlock as a trusted primitive. The concurrency-soundness
metatheorem (lock discipline justifies sequential reasoning — CSL)
can layer over the SAME per-function proofs later without changing
them; that is the entire point of that lineage.

## 3. Honest cmm-arc prices

| Layer | Lineage (canon-first) | Buys | Price |
|---|---|---|---|
| Lock-invariant layer: lock/unlock as ownership transfer of an invariant-carrying footprint; spinlock + psci trylock as axiomatized primitives with acquire/release contracts (2 asm blobs, temporal boundary entries) | O'Hearn CSL resource invariants; seL4's sequential-under-lock; Perennial's SC discipline; the CN case study itself | pKVM buddy + mem_protect-shaped code, i.e. class (i) = the bulk | **M** on top of the segment layer (it is FnSpec-shaped: a lock contract is a function contract) |
| Schedule-interleaved executable face: choice streams = schedules at lock/primitive granularity; differential vs oracle stays sequential per-thread | Our standing cmm sketch; CompCert-style per-run determinization | Executable/differential legs for concurrent harnesses; plant tests for the lock discipline | M (independent) |
| C11 axiomatic model in Lean: Cerberus's `cmm_csem.lem` EXISTS upstream — lem-lean can GENERATE the Lean model (generation ≠ proofs); end-of-run candidate filtering per our ND design seed | Batty et al C11; Cerberus's own cmm | The model-level ND+filter formulation; concurrency statements | M-L generation+integration; proofs separate |
| Release/acquire program logic (verify the lock impls themselves) | GPS/iGPS, Cosmo, iRC11 — ALL Rocq; in Lean: nothing exists | Discharges the 2 trusted lock contracts + 3 atomic sites | **XL** (porting a research-grade logic to iris-lean) — terrible value/cost now |
| Aarch64/LKMM axiomatic | Alglave et al herd/cat; LKMM | Nothing the surveyed C demands | XXL; not justified by evidence |

Honesty notes: (a) the Lean-ecosystem gap is the binding constraint
on rows 4-5 — every mechanized weak-memory logic lives in Rocq;
(b) Cerberus's cmm is C11, NOT LKMM — for lock-discipline-only this
does not bite (the contracts are model-agnostic), but any future
claim about the lock *implementations* must say which model it is
under; (c) row 1's trusted-primitive count is 2 and stays 2 — the
kernel's own reviewers carry those 40 asm lines today.

## 4. Target-slate implication: pKVM buddy stays FIRST — and moves EARLIER

- pKVM buddy is class (i) + two trusted primitives: reachable with
  the machinery the segment ladder is building NOW (segment layer,
  FnSpec, invariants) + the M-priced lock-contract idiom. No cmm
  arc on its critical path.
- WireGuard's data path is WORSE, not better: its crypto kernels are
  cleanly sequential (good early rungs), but the device layer uses
  RCU (allowedips), per-peer locks + napi queueing — RCU is
  class-(iii)-adjacent and strictly harder than anything in
  nvhe. WireGuard-first would meet weak memory SOONER.
- Recommendation: keep the slate order (buddy first); pull the
  lock-contract idiom INTO the breadth campaign's edge tier as a
  worked example (a two-function program with a lock-shaped
  ownership transfer) so the buddy rung inherits a tested idiom.

## 5. Risks / follow-up design evaluation

1. **Init phase**: `__pkvm_init` runs lock-free by "other CPUs not
   up yet" (spinlock.h hyp_assert_lock_held comment + static key) —
   needs a pre-SMP ghost-token story; small, but must be designed,
   not assumed.
2. **Adversarial host memory**: the READ_ONCE-of-host-state idiom
   needs a modeling decision (ND-value volatile read — fits choice
   streams; recommend this as the cmm arc's warm-up client
   alongside freshness).
3. **Hardware-interface boundary** (class iv): the honest big-TCB
   item for full pKVM; severable from the allocator; needs its own
   scoping when the slate reaches mem_protect/mm.
4. **Alloc-subtleties gate** (standing, [USER]): lock-mediated
   `Owned` transfer interacts with provenance/address-observability
   exactly where the gate already demands evaluation vs Caesium —
   the lock-invariant layer design must pass that gate; nothing
   here pre-empts it.
5. CN case study is GPL — statement shapes/ideas reference only,
   fixtures live in the separate example repo per the standing
   split ruling.

## 6. Operator questions

1. Accept the ticket spinlock + psci boot trylock as AXIOMATIZED
   TRUSTED PRIMITIVES with acquire/release contracts (temporal
   boundary entries; expected mover = a Lean rel/acq logic, honestly
   far)? This is the load-bearing trust decision of the whole plan.
2. Rescope the queued cmm arc as: lock-invariant layer (M, CSL
   lineage) + schedule-streams executable face (M) + C11-model
   generation via lem (M-L), with weak-memory program logic
   explicitly DEFERRED — replacing the undifferentiated "cmm arc"?
3. Add the lock-contract worked example to the breadth edge tier
   (cheap, keeps the buddy rung honest)?
