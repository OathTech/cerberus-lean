# WireGuard as a verification target — scoping survey (2026-08-20)

Mission: scope `deps/linux/drivers/net/wireguard/` (~5,160 lines .c, 15 TUs +
selftest/) as a candidate target for the Cerberus→Lean pipeline. Read-only
survey + cheap ORACLE probes (OCaml cerberus only, capped: `ulimit -v 4000000`,
`timeout 120–300`); no kernel builds, no Lean-side runs. Extraction model and
prior art: the CN pKVM buddy-allocator case study
(`deps/CN-pKVM-buddy-allocator-case-study` — trimmed kernel headers with
original-location comments, minor recorded edits, no kernel build system) and
the libxml2 probe (`notes/2026-08-19_libxml2-probe.md`). Probe scratch:
`.tmp/wg-probe/` (recipe recorded below; scratch is disposable).

**Headline:** WireGuard clears the first bar far better than its reputation
suggests. There is **no inline asm anywhere in the module**, zero
typeof/statement-exprs/bitfields **in the .c bodies** (all GNU-C load lives in
the kernel headers, which the buddy-style extraction replaces), and the
flagship data structure (allowedips.c, the routing trie) **fully elaborates
through the oracle in 0.12 s** behind a ~200-line shim header with two
recorded one-line edits. A hand-extracted lookup slice **executes correctly**
in the oracle interpreter (5/5 selftest-derived vectors, matches native cc).
Exec of the *full* pristine TU is blocked by one newly-found **oracle
exec-driver defect**: elaboration of the failing program is clean, but the
Core evaluator dies during static-initialization/evaluation in a way that is
*deterministic yet declaration-layout-sensitive* (full characterization +
297-line repro recipe in the §2a addendum). The module ships its own deterministic selftest batteries
(allowedips: 34+ static vectors plus a built-in reference-implementation
differential mode; replay counter: ~120 vectors) that map directly onto our
chvalid-style differential-gate pattern. The honest ceiling is concurrency:
WireGuard is an RCU/LKMM showcase, and anything beyond single-threaded
algorithmic cores waits for the concurrency arc (see §4, incl. the operator's
LKMM direction).

---

## 1. Per-TU characterization

Kernel-API / extension / concurrency markers are grep-derived counts (labeled
derived, not verbatim): conc = spin/mutex/rcu/atomic/READ_ONCE sites;
skb = sk_buff surface; wq/timer/percpu/nl = workqueue/timer/per-cpu/netlink.

| TU | lines | role | kernel-API surface | GNU/ext load in body | concurrency entanglement | verdict |
|---|---|---|---|---|---|---|
| allowedips.c | 424 | IP→peer routing trie (the classic target) | slab cache, RCU, mutex-witness args, list.h, skb only in 2 wrapper fns | none (attrs only); 1 offsetof-array-designator, 1 void* arith | RCU woven through but **mechanically erasable**: readers lockless, writers hold external mutex; single-threaded semantics = plain pointers | **TRACTABLE-NOW** (probed, §2a) |
| selftest/allowedips.c | 727 | static vector battery + randomized differential vs naive "horrible" reference impl | kzalloc/kref/get_random/printk/hsiphash/hlist | macros only | none (runs under one mutex) | TRACTABLE-WITH-EXTRACTION — the differential battery (§2a) |
| receive.c | 586 | RX path: decap, decrypt queueing, napi | skb heavy (31 sites), napi, per-peer queues | none | deep, EXCEPT `counter_validate` (l.295–331): pure replay-window bit algebra under one spinlock | BLOCKED as a TU; **`counter_validate` slice TRACTABLE-NOW** |
| selftest/counter.c | 111 | ~120 deterministic vectors for `counter_validate` | kmalloc, pr_err only | none | none | TRACTABLE-NOW (trivial shim) |
| peerlookup.c | 226 | pubkey→peer + index→handshake hashtables | siphash, hlist-RCU, spin/mutex, get_random_u32 | none | RCU hlist iteration erasable; `wg_index_hashtable_insert`'s unlocked-guess/lock-recheck dance is concurrency theater when single-threaded | TRACTABLE-WITH-EXTRACTION (needs siphash + deterministic-RNG stub) |
| cookie.c | 236 | mac1/mac2 cookie protocol | blake2s, xchacha20poly1305, rwsem, skb reads, ratelimiter call | none | rwsems erasable; logic is sequential | TRACTABLE-WITH-EXTRACTION (crypto as opaque/spec'd primitives, §3) |
| ratelimiter.c | 223 | token-bucket ratelimiter + GC | hsiphash, hlist-RCU, kmem_cache, ktime, deferrable workqueue, totalram_pages | none | token math per-entry under spinlock (fine); GC via workqueue + ktime (cut at the seam: pass `now` as arg) | TRACTABLE-WITH-EXTRACTION (its selftest is timing-based — weak battery) |
| noise.c | 861 | Noise_IKpsk2 handshake state machine + keypair lifecycle | curve25519/blake2s/chacha20poly1305 (lib/crypto), RCU keypair ptrs, kref, rwsem, tai64n | none | two tiers: `hmac`/`kdf`/`mix_*`/`handshake_*` core = pure byte-array math (**pure slice TRACTABLE-NOW**); keypair rotation = RCU/kref lifecycle | TRACTABLE-WITH-EXTRACTION (state machine), pure-crypto-plumbing slice NOW |
| timers.c | 246 | 5 per-peer protocol timers | timer_list API throughout (50 sites) | none | all logic IS timer plumbing | BLOCKED as code (the timer *protocol* is a spec-layer object, not extractable code) |
| queueing.c/.h | 109+204 | MPSC skb ring + prev_queue | skb, per-cpu round-robin, `smp_load_acquire`(3 sites)/`xchg`/atomics | none | the POINT is lock-free MPSC — meaningless single-threaded | BLOCKED (pre-concurrency-arc by nature) |
| peer.c | 239 | peer lifecycle create/kref/teardown | kref, RCU, workqueue flush ordering, napi, dst_cache | none | teardown ordering is a concurrency object | BLOCKED |
| send.c | 414 | TX path: handshake msgs, encrypt, padding | skb heavy, workqueues | none | deep (padding calc `calculate_skb_padding` is a trivial extractable pure fn) | BLOCKED |
| socket.c | 436 | UDP tunnel send/recv, endpoint cache | full net stack (udp_tunnel, dst, flowi) | none | deep | BLOCKED |
| device.c | 475 | netdev ops, open/stop/xmit glue | netdev, rtnl, per-cpu, pm notifier | none | deep | BLOCKED |
| netlink.c | 607 | genetlink uapi (config get/set) | genl/nla (85 sites), dump cursors | none | mostly lock plumbing around device state | BLOCKED (config plumbing; nothing algorithmic) |
| main.c | 78 | module init/exit | module_init, genl register | none | — | BLOCKED (nothing to verify) |

Verdict counts (15 TUs + 3 selftest files): **TRACTABLE-NOW: 1 TU
(allowedips.c) + 2 slices (counter_validate incl. its selftest; noise pure
kdf/hmac core). TRACTABLE-WITH-EXTRACTION: 4 (peerlookup, cookie,
ratelimiter, noise state machine) + selftest/allowedips. BLOCKED: 9
(receive-as-a-TU/send/socket/device/netlink/timers/queueing/peer/main — all
for kernel-I/O or intrinsic-concurrency reasons, none for C-language
reasons).**

The striking census fact, mirroring libxml2: **the module's .c files are
plain C11**. grep census over all 17 .c files: inline asm 0, typeof 0,
statement-exprs 0, bitfields 0; attributes only via macros (`__rcu`,
`__aligned`, `__init`, `__force`, `__nonstring`) which the shim erases. The
GNU-C monster is the *kernel header graph*, which the buddy recipe exists to
amputate.

## 2. Deep probes

### 2a. allowedips.c — the first candidate, probed against the oracle

Extraction recipe (buddy-style, reproduced in `.tmp/wg-probe/`, deleted after
this note; ~1 hour to rebuild from this record):

- `inc/wg_shim.h` (~200 lines): kernel types (u8..u64, __be32), attribute
  erasers, RCU→plain-pointer macros (`rcu_dereference_*(p)→(p)`,
  `call_rcu(h,fn)→fn(h)`, `kfree_rcu→free` — single-threaded semantics),
  mutex as empty struct, slab→malloc/calloc, list.h doubly-linked subset
  (kernel-style `typeof` iterator macros — **the oracle accepts `typeof`**),
  fls/fls64 as loops, byte-order helpers, minimal `sk_buff`/`iphdr` with
  `ip_hdr()` accessors.
- `inc/linux/{mutex,ip,ipv6}.h` → one-line redirects to the shim.
- shim `peer.h`: `struct wg_peer { struct list_head allowedips_list; int
  refcount; }` + identity `wg_peer_get_maybe_zero`.
- pristine `allowedips.c` + `allowedips.h` + `selftest/allowedips.c` copied
  unmodified, then **two recorded edits** (below).

Oracle run 1 — parse gap (verbatim):

```
/home/dev/projects/cerberus-lean-proj/.tmp/wg-probe/allowedips.c:263:40: error: unexpected token after 'bit' and before '['
parsing "postfix_expression": seen "OFFSETOF LPAREN type_name COMMA general_identifier", expecting "RPAREN"
			offsetof(struct allowedips_node, bit[node->parent_bit_packed & 1]);
			                                    ^ 
```

Cerberus's parser rejects `offsetof(type, member[index])` — the array-element
member-designator form is ISO C11-legal (7.19p3). Same line also does GNU
`void*` arithmetic. Recorded edit 1: equivalent
`(char*)p - (offsetof(...,bit) + sizeof(ptr)*(idx))` form.

Oracle run 2 — desugar gap (verbatim):

```
/home/dev/projects/cerberus-lean-proj/.tmp/wg-probe/allowedips.c:54:31: error: feature not yet supported: cast operator in `integer constant expressions'
		container_of(rcu, struct allowedips_node, rcu) };
		                            ^~~~~~~~~~~~~ 
```

A `container_of` (cast expression) inside a **local array brace-initializer**
trips the integer-constant-expression checker — same defect family as libxml2
probe defect #1 (NULL-in-union static init). Recorded edit 2: hoist the first
element assignment out of the initializer (`stack[0] = container_of(...)`).

Oracle run 3 — **full elaboration, first try after the two edits**:

```
Command exited with non-zero status 3
wall=0.12s maxRSS=75136kB
```

(exit 3 = ELABORATED under `--progress`; Core output 13,310 lines.)

**Execution:** the full pristine TU does NOT yet execute — it hits an oracle
defect cluster (below). But a hand-extracted **lookup slice** (swap_endian /
choose / common_bits / prefix_matches / find_node, statically-built 3-node
trie, 5 selftest-derived query vectors incl. longest-prefix fallthrough and
negative case) **executes correctly** (verbatim):

```
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
Time spent: 0.270354 seconds
```

(return value = fail count = 0; native `cc -O1` binary agrees, exit 0.)

**Oracle exec defect cluster (new findings, full-TU exec).** Running the
elaborated full TU + harness under `--exec` produced, across small harness
perturbations, four distinct Core-level manifestations of what looks like one
underlying exec-driver bug (each verbatim, first lines):

1. `internal error: can_advance: Step_error2 ==> ...harness.c:33:24-26the value of a store(struct wg_peer) didn't match the lvalue type: NULL(void)`
2. `OTHER ERROR: ill-formed program: `PEctor: one of the operands was ill-typed ==> Specified(a_635) <====> [Specified(0)]'`
3. `OTHER ERROR: ill-formed program: `PEmember_shift'`
4. `internal error: can_advance: Step_error2 ==> Load`
5. (multi-TU variant with shim `static inline` fns) `internal error: Core_eval.step_eval_pexpr, PEcfunction expects a pointer`
6. (one variant) `error: undefined behaviour: out of bounds pointer at memory store` at `table->root4 = table->root6 = NULL;`

Micro-repros of every suspected feature **pass in isolation**: u8[]/u32
type-punning, anonymous unions, static struct zero-init, forward-declared
static pointers, chained NULL assignment into a global struct, the
kernel-style `typeof`+`offsetof` list-iterator macro, the `goto retry`
pattern. The failure point moves as *unrelated* code is added or removed.
System creduce is broken (missing helper passes: `prereqs not found for pass
pass_indent`; no clang_delta/topformflat on the box — worth an operator fix),
so custom ddmin loops (with a gcc `-S -O1 -Werror=return-type` validity
guard, after a first reduction went degenerate — see addendum) plus
stub-and-unstub localization were used instead. **Outcome (§2a addendum):
the defect is in the ORACLE'S EXEC DRIVER, not elaboration** — the failing
program elaborates cleanly (`--progress` exit 3) and the identical Core then
dies in `Core_eval`/driver during the static-initialization/first-store
phase, deterministically (stable across runs AND in `--mode=exhaustive`),
with a failure signature that is a pure function of *declaration layout*:
removing any one of ~70 unused libc-prelude declarations makes it pass,
reordering two declarations keeps `Step_error2 ==> Store`, adding one dummy
declaration morphs it to `Step_error2 ==> Kill`. This is the concrete oracle
work item this probe surfaces; it gates full-TU differential exec, NOT
elaboration and NOT the Lean lane's next steps.

**The selftest as differential battery (chvalid-style): yes, and better.**
`selftest/allowedips.c` has three tiers: (i) ~90 deterministic checks
(34 lookup vectors + removal/exact-match/EINVAL semantics + a list-walk
read-back block + a 129-deep worst-case insertion stress); (ii)
`DEBUG_RANDOM_TRIE`: randomized differential against `horrible_allowedips` —
a naive ordered-mask-list reference implementation **shipped in-tree** (i.e.
upstream already built our differential oracle for us); (iii) graphviz dump
(ignore). Tier (i) needs a modest shim extension over §2a's (kref_init,
kzalloc_obj, pr_err→printf, DEFINE_MUTEX, get_random stubs) — S/M. Tier (ii)
additionally needs a deterministic RNG stub (seeded LCG behind
`get_random_bytes`/`get_random_u32_*`) and scaled-down NUM_* constants — M,
and it converts into exactly the chvalid pattern: same vectors through
oracle-exec / Lean interpreter / native cc, three-way compare.

### 2b. cookie.c / ratelimiter.c

cookie.c is 100% sequential logic: two blake2s MAC computations over message
prefixes, an xchacha20poly1305-sealed cookie, birthdate checks. Every
interesting property (mac1 computed over `len - sizeof(macs) +
offsetof(mac1)` bytes; mac2 keyed by unexpired cookie; state transitions of
`latest_cookie`) sits above crypto primitives — with blake2s/xchacha as
opaque byte-functions (§3) the TU extracts cleanly (rwsem→no-op, skb→shim,
ktime→parameter). No selftest; differential battery would be hand-built or
driven from captured handshake traffic. TRACTABLE-WITH-EXTRACTION, M.

ratelimiter.c: the core (`wg_ratelimiter_allow` bucket update: `tokens =
min(TOKEN_MAX, tokens + now - last)`, pay `PACKET_COST` or refuse) is a
20-line pure kernel of real protocol importance (cookie-forcing DoS
resistance). Entanglement: `ktime_get_coarse_boottime_ns` (make `now` a
parameter — one recorded edit), hsiphash bucket choice (shim), table sizing
from `totalram_pages` (fix constants), GC workqueue (drop; GC correctness is
a concurrency-arc item). Its selftest is timing/jiffies-based — NOT a good
differential battery. TRACTABLE-WITH-EXTRACTION, M; theorem-attractive
(token-bucket invariant: over any window, allowed ≤ burst + rate·time —
small-int arithmetic, squarely in the T1–T4 envelope).

### 2c. peerlookup.c

Both hashtables are thin: siphash → bucket mask → hlist walk → memcmp/index
compare. Single-threaded verdict: extract with an hlist shim + siphash
(siphash itself: `include/linux/siphash.h` + `lib/siphash.c`, plain C, would
elaborate trivially and is itself a nice mini differential target with known
test vectors). The famous part — `wg_index_hashtable_insert`'s
random-probe/double-check loop — degenerates single-threaded to "draw
indices until unused", whose termination is probabilistic: fuel-style
statements only ("if it returns, the index is fresh and mapped"), which our
fuel opsem is already shaped for. TRACTABLE-WITH-EXTRACTION, S/M.

## 3. Crypto dependencies

noise.c/cookie.c pull, via `<crypto/...>` headers: curve25519, blake2s,
chacha20poly1305 (+xchacha), hchacha, poly1305, siphash (peerlookup),
hsiphash (ratelimiter). All present in our checkout at
`deps/linux/lib/crypto/` with **portable C generic implementations** and the
asm-optimized versions safely segregated in per-arch subdirs (`x86/`, `arm/`,
…) behind `CONFIG_..._ARCH` — the C paths are what an extraction takes:
chacha20poly1305.c 361 + chacha.c 70 + chacha-block-generic.c 118 +
poly1305.c 100 + poly1305-donna64.c 185 + blake2s.c 159 + curve25519.c 78
(dispatcher) + **curve25519-hacl64.c 786 / curve25519-fiat32.c 864** ≈ 2.9k
lines of dependency-light C11.

The HACL* connection is literal and double-ended: the kernel's 64-bit
curve25519 **is HACL\*-derived code** (curve25519-hacl64.c; the 32-bit one is
fiat-crypto-derived), and our repo already runs Cerberus over HACL*-style
generated code (`cerberus-lean/tests/hacl-star/compact`: Hacl_Curve25519.c,
Hacl_Chacha20Poly1305.c, …). So the natural spec-layer story writes itself,
in three escalating postures: (P1) **trusted primitives** — axiomatize
blake2s/chacha/curve25519 as opaque byte-functions in the harness (theorems
about WireGuard logic *modulo* crypto — the right first posture; mirrors how
CN treated lemmas as trusted); (P2) **differentially-validated primitives** —
run the actual lib/crypto C through the pipeline against the in-tree KUnit
vector files (`lib/crypto/tests/blake2s-testvecs.h`,
`chacha20poly1305_kunit.c`, `curve25519_kunit.c` — ready-made batteries);
(P3) **spec'd primitives** — state the primitives' functional specs in Lean
(or import HACL*'s) and connect. P1 suffices for every rung in §5; P2 is
cheap insurance; P3 is its own program and NOT on this target's critical
path. Note tests/hacl-star has known upstream float/`__int128`-adjacent
history — curve25519-hacl64.c uses u64×u64→u128 arithmetic (`(u128)a*b`):
**`unsigned __int128` support needs an explicit oracle check** before P2 on
curve25519; blake2s/chacha/poly1305-donna32 are 32/64-bit only and safe.

## 4. Concurrency honesty

WireGuard is not "a concurrent program" so much as a federation of
concurrency idioms: RCU-published trie + hashtables, kref lifecycles, an
MPSC lock-free ring (queueing.h, the module's only explicit
acquire/release code), per-peer spinlocks, rwsems, deferrable-work GC, timer
protocol. What we may honestly claim pre-concurrency-arc:

**Meaningful WITHOUT the concurrency arc** (single-threaded semantics, RCU
erased, external locks assumed held — all theorems explicitly labeled
"sequential semantics"):
- allowedips: functional correctness of insert/remove/lookup as a
  longest-prefix-match map (the selftest algebra); memory-safety of the trie
  walk; the MAX_ALLOWEDIPS_DEPTH=129 bound (a lovely finite-structure
  invariant: depth ≤ bits+1).
- counter_validate: the replay-window algebra (accept iff nonce unseen and
  within window; REJECT_AFTER_MESSAGES ceiling) — the selftest's 120 vectors
  are its spec sketch.
- ratelimiter token-bucket arithmetic; cookie MAC construction; noise
  kdf/hmac chain (pure); peerlookup set-semantics.

**Dishonest to claim before cmm/LKMM lands** (would assert order the
sequential model can't see):
- Any statement about *concurrent* lookup-during-mutation of the trie — the
  actual design theorem of allowedips (RCU readers never see a torn trie;
  `wg_peer_get_maybe_zero`'s retry loop, which is dead code single-threaded).
- queueing.h MPSC ring correctness (its content IS the memory ordering).
- kref/RCU teardown ordering (peer.c), index-hashtable steal-recheck,
  keypair rotation lifecycles, GC-vs-allow races, timer/handshake races.

Forward-design constraint (standing doctrine): the sequential theorems must
be phrased so the concurrency arc *refines* rather than unwinds them — state
them over the trie/counter ADTs and per-location step relations, never
baking "the whole heap is quiescent" into statement shapes that a
weak-memory instantiation would have to retract.

### [USER] The LKMM wrinkle (operator input, 2026-08-20)

> "one wrinkle with wireguard is that Linux ships its own memory model
> (famously, there's a txt file). So it isn't totally clear how to handle
> this with Cerberus (an interesting result would be proving wireguard at
> all plausible models above some very weak one, or something similar)."

**(a) The model mismatch.** Confirmed in-tree: `deps/linux/tools/memory-model/`
is present (linux-kernel.{bell,cat,cfg,def}, lock.cat, litmus-tests/,
Documentation/) plus the famous `Documentation/memory-barriers.txt`. Kernel
code does not speak C11 atomics: it speaks READ_ONCE/WRITE_ONCE,
smp_load_acquire/smp_store_release, smp_mb/rmb/wmb, RCU, and LKMM-semantics
atomics — and LKMM differs from the C11 model Cerberus ships (cmm_csem) in
load-bearing ways: LKMM preserves address/data/control dependencies as
ordering (C11 consume is dead; C11 relaxed does not order dependencies),
LKMM tolerates marked-access races where C11 declares data-race UB, and RCU
grace-period ordering has no C11 primitive at all. The concrete mapping
surface for this module (grep-derived counts, per candidate TU):

| TU | READ_ONCE | WRITE_ONCE | smp_acquire/release/mb | rcu_* | atomic_* | kref_* | lock ops |
|---|---|---|---|---|---|---|---|
| allowedips.c | 0 | 0 | 0 | 28 | 0 | 0 | 0 |
| peerlookup.c | 0 | 0 | 0 | 10 | 0 | 0 | 14 |
| cookie.c | 0 | 0 | 0 | 0 | 0 | 0 | 13 |
| ratelimiter.c | 0 | 0 | 0 | 6 | 4 | 0 | 12 |
| noise.c | 1 | 0 | 0 | 22 | 2 | 3 | 37 |
| receive.c | 5 | 2 | 0 | 6 | 5 | 0 | 3 |
| send.c | 4 | 1 | 0 | 10 | 9 | 0 | 6 |
| queueing.c | 1 | 2 | 3 | 0 | 4 | 0 | 0 |
| timers.c | 2 | 0 | 0 | 4 | 0 | 0 | 0 |
| device.c/socket.c/netlink.c/peer.c | 1/0/0/0 | 0/0/0/1 | 0 | 7/13/3/3 | 1/0/0/2 | 0/0/0/4 | 14/2/18/1 |

Read: the tractable tier (allowedips, peerlookup, cookie, ratelimiter) uses
NO raw barriers and almost no marked plain accesses — its concurrency is
entirely RCU + locks, i.e. the *structured* fragment of LKMM. Raw
acquire/release lives in exactly one place (queueing.c's MPSC ring). This is
the best possible shape for us: the primitives to model are few, idiomatic,
and mostly higher-level than fences.

**(b) Handling options.** (1) *Compile-to-C11*: macro-map READ_ONCE→relaxed
(volatile-ish), smp_load_acquire→acquire, rcu_dereference→consume-degraded-
to-acquire, rcu grace periods→a lock abstraction — standard but contested
(known to be neither sound nor complete vs LKMM in the corners: dependency
ordering, Alpha history, smp_mb vs seq_cst fences), and it silently
strengthens RCU readers. Fine for *differential testing*; shaky as a theorem
base. (2) *Axiomatize the primitives*: treat READ_ONCE/rcu_*/smp_* as opaque
effectful primitives of the model-parametric layer with LKMM-derived axioms
(from the .cat file) — honest, more work, and the .cat file is executable
spec we could translate against litmus-tests/ as a validation corpus. (3)
*The operator's proposed result shape — model-quantified theorems*: prove
properties ∀ memory model M in a family bounded below by a weak floor
("WireGuard's trie lookup is correct under EVERY plausible model ≥ floor",
rather than "under LKMM-as-we-formalized-it"). This turns the mismatch from
a liability into the headline: we never have to defend "our LKMM
formalization is THE LKMM", only that LKMM (and C11, and SC) lie in the
quantified family.

**(c) Why our substrate is unusually ready for (3).** This is not
retrofitting: cmm_csem's `behaviour` already takes the memory model as a
first-class parameter (the .lem model-family plumbing), and the standing
parametricity principle (ExecModel deliberately model-parametric; operator
doctrine 2026-08-19, banked in the concurrency spike notes) means the
Layer-2/3 shapes were designed NOT to bake in SC or single-thread
assumptions. A sketch (design belongs to the concurrency arc, NOT this note)
of the "plausible floor" hypothesis set: per-location coherence (SC per
location); preserved address/data dependencies (no out-of-thin-air, no
value-prediction on dependent loads — the Alpha caveat is carried by
rcu_dereference's own barrier, so the floor can be stated pre-Alpha-quirk);
lock/unlock and rcu_read_lock/synchronize_rcu induce the usual
happens-before/grace-period edges; RMWs atomic. Everything WireGuard's
structured fragment relies on is plausibly derivable from that floor; the
queueing.c ring is the one component that needs acquire/release edges
specifically, which is why it stays BLOCKED longest. **This
(model-quantified WireGuard trie/RCU-reader theorems) is the top rung of the
§5 ladder and a candidate headline result for the concurrency arc.**

## 5. Verdict

### Target ladder (ranked, priced)

| Rung | Object | Price | Gaps to close (Cerberus/pipeline) |
|---|---|---|---|
| 0. First probe | allowedips.c elaboration behind buddy-style shim | **S — DONE (this note)** | two recorded edits (offsetof-designator parse gap; cast-in-initializer ICE gap) |
| 1. First exec | full allowedips TU + harness under oracle `--exec` | S/M | fix the §2a exec-driver defect (characterized repro in addendum); side item: `remove` name-clash with oracle libc stdio.h in single-TU concats |
| 2. First differential battery | `counter_validate` + selftest/counter.c (~120 vectors), three-way (oracle / Lean interpreter / native) | **S — recommended first Lean-side move** | trivial shim (spinlock/kmalloc/pr_err); no RNG; no known blockers — the slice is plain C |
| 3. Second differential battery | allowedips static selftest tier, then randomized tier vs in-tree `horrible_allowedips` reference (chvalid-pattern `test_wireguard.sh`) | M | rung-1 defect; deterministic-RNG shim; scaled NUM_* constants; Lean-side multi-TU or single-TU concat stopgap |
| 4. First theorem | replay-window correctness of `counter_validate` (T1–T4 envelope: bounded loops, u64 array, early exit; ~40 lines) | M | globals machinery (in flight, arc-9); nothing else new |
| 5. Second theorem | allowedips `find_node`/insert functional correctness + depth-bound invariant (sequential semantics, labeled) | L | heap/inductive-structure reasoning in the WP layer (trie ≠ flat arrays — new proof machinery); statement-TCB additions for the shim |
| 6. Crypto lane (parallel) | lib/crypto blake2s/chacha20poly1305 through pipeline vs KUnit testvecs; primitives-as-axioms posture for cookie.c/noise-core | M | `unsigned __int128` oracle check for curve25519-hacl64; otherwise plain C |
| 7. Headline (concurrency arc) | **model-quantified theorems** (§4c): trie RCU-reader correctness ∀ models ≥ weak floor | XL | the concurrency arc itself: LKMM primitive axiomatization vs .cat, litmus validation, model-parametric Layer-2/3 instantiation |

### Gap list (consolidated, what Cerberus/our pipeline lacks)

Oracle (upstream-fixable, all recorded verbatim above): (1)
`offsetof(T, member[i])` parse gap (ISO-legal construct); (2) cast-expression
in local aggregate initializer → "not yet supported: cast operator in
integer constant expressions" (libxml2-defect-#1 family); (3) the full-TU
exec-driver declaration-layout-sensitive failure cluster (§2a addendum —
the one real blocker on this target; elaboration is clean, so the Lean
frontend consuming elaborated output is NOT gated by it) + the latent
missing-return→ill-formed-Core behavior found during reduction; (4) broken
creduce
install on this box (missing clang_delta/passes) — hampers exactly this kind
of work, operator-level fix. Pipeline-side (already-known gaps, priorities
confirmed by this survey): Lean multi-TU story for shim+pristine-TU pairs
(or cpp-concat stopgap, which hits the `remove`-vs-stdio clash → keep shim
stdio-free); deterministic-RNG + kernel-stub shim library as a reusable
artifact (this probe's wg_shim.h is its seed, worth promoting out of
scratch); heap-structure proof machinery for rung 5; LKMM lane for rung 7.
Nothing in the module needs varargs, setjmp, VLAs, computed goto, or (outside
lib/crypto's u128) exotic integer types.

### WireGuard vs pKVM buddy allocator as the next target

Not actually rivals — they answer different questions:

- **Buddy allocator** (page_alloc.c, 938 lines incl. CN annotations): comes
  with a complete pre-existing formal spec (CN predicates + Coq lemma
  library) = statement-design derisked; trimmed headers already made;
  single-threaded by design (hypervisor pool under host lock) so NO
  concurrency asterisk on its theorems; but its proof burden is invariant-
  heavy (vmemmap well-formedness, nonlinear `page_size_of_order` arithmetic
  needing a lemma layer), it has NO in-tree test battery (no differential
  rung — for us it is theorem-or-nothing), and it proves little new about
  our *extraction* capability (its extraction is already done).
- **WireGuard**: no pre-existing spec, and honest theorems above the
  algorithmic tier wait on the concurrency arc — but it offers a graded
  ladder ending in a genuinely novel headline (rung 7), in-tree differential
  batteries with a shipped reference implementation (perfect fit for our
  actual current strength — the differential harness), a live crypto/HACL*
  story, and real-world-relevance optics an allocator can't match.

**Recommendation:** buddy is the better *first-theorem* second target — take
it when the goal is exercising the T-slate/WP machinery on externally-spec'd
kernel code with zero concurrency caveats (its CN/Coq spec doubles as a
correctness oracle for our statements). WireGuard is the better *arc-scale*
target and should start now anyway at rungs 1–3, because its near rungs are
cheap (rung 2 is S-priced and needs nothing new), they extend the
differential surface where our pipeline is currently strongest, and they
bank the extraction recipe + LKMM groundwork the eventual headline needs.
Concretely: open the WireGuard differential lane (rungs 1–3) as a Tier-B
gate now; schedule buddy as the theorem lane's next big statement after the
arc-9 globals slate; let rung 7 anchor the concurrency arc's charter.

---

## §2a addendum — the oracle exec-driver defect, characterized

**Statement.** There exists a ~300-line plain-C11 TU (no type-punning
executed, one *unused* anonymous-union struct, near-empty `main` — two local
declarations only) that (a) elaborates cleanly — verbatim:
`--progress` exit `3`, `--pp core` emits 1753 lines of Core without
complaint — and (b) under `--exec --batch` fails, deterministically and
also under `--mode=exhaustive`, with (verbatim):

```
internal error: can_advance: Step_error2 ==> Store
```

**Sensitivity fingerprint** (each a single-run verbatim first line):

- remove ANY ONE of the ~70 (entirely unused) libc-prelude declarations →
  `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`
  (greedy loop confirmed: no single prelude line can be removed keeping the
  failure — i.e. every removal FIXES it);
- swap the order of two adjacent prelude declarations (memcpy/memmove) →
  still `internal error: can_advance: Step_error2 ==> Store`;
- add one dummy declaration (`int __extra_decl(int);`) →
  `internal error: can_advance: Step_error2 ==> Kill`;
- substitute `typedef __cerbty_size_t size_t;` → `typedef unsigned long
  size_t;` → still fails (the magic builtin typedefs are NOT the trigger);
- replace the whole 73-line prelude by 7 equivalent plain declarations →
  passes (also exhaustive-mode passes).

In the un-reduced original, the same underlying defect surfaced as (all
verbatim, §2a): `PEctor: one of the operands was ill-typed ==>
Specified(a_N) <====> [Specified(0)]` (with `a_N` varying as unrelated code
changed), `PEmember_shift`, `Step_error2 ==> Load`, `store(struct wg_peer)
didn't match the lvalue type: NULL(void)`, `PEcfunction expects a pointer`
(multi-TU variant), and one spurious
`undefined behaviour: out of bounds pointer at memory store` on
`table->root4 = table->root6 = NULL;`. Interpretation (derived, not
verbatim): something in the exec driver's concrete-memory/static-allocation
bookkeeping (allocation ids or address layout as a function of the number
and order of top-level declarations — note function declarations get
footprints too) goes inconsistent past a certain declaration count, and
whichever access first touches the corrupted object determines the visible
error. Elaboration being clean and exhaustive-mode failing rules out both
the elaborator and trace-nondeterminism as causes. Plausibly related to
libxml2 probe defect #3 only distantly; this one is driver-side.

**Repro recipe** (scratch `.tmp/wg-probe/` is disposable; everything needed
to regenerate): (1) build the §2a shim + pristine allowedips.c with the two
recorded edits; (2) `cc -std=c11 -E -P -CC -nostdinc -undef -D__cerb__
-I <cerberus runtime libc include> -I inc -I . combined2.c > pre.c` where
combined2.c = `#include "allowedips.c"` + the stdio-free harness (exit code
= fail count; note: a *stdio-using* single-TU merge instead collides with
the oracle libc's `int remove(const char*)` — allowedips.c has
`static int remove(...)` — verbatim: `error: constraint violation: multiple
declarations in the same scope with incompatible types`); (3) stub all 27
allowedips function bodies with trivial well-formed bodies (the stub set is
mechanical: `return 0;` / `(void)args;` / for `wg_allowedips_init` the real
3-store body); the resulting ~300-line file is the failing artifact. During
reduction two ADDITIONAL latent oracle behaviors were caught: (i) ddmin
without a compiler validity-guard converges to degenerate "repros" whose
ill-typed-Core errors come from calling non-void functions that fall off
the end — i.e. the oracle ALSO produces ill-formed Core (rather than a
clean UB verdict) for missing-return fall-through when the value is used;
(ii) gcc's `-fsyntax-only` does not run the fall-off analysis, so honest
reduction guards need `-S -O1 -Werror=return-type`. Both worth knowing for
future creduce-style oracle bug hunts.

## Probe inventory (what was actually run)

All oracle invocations: `cerberus-lean/scripts/cerberus` (OCaml oracle @
current build), capped `ulimit -v 4000000` + `timeout 120–300`; wall/RSS
worst case across all runs: 0.35 s / 124 MB — nowhere near caps. Runs:
allowedips.c `--progress --pp core` ×3 (2 fails verbatim above, then exit 3);
`--exec` harness variants ×8 (defect cluster, all first-lines recorded);
micro-repros ×~12 (punning ×2, anon-union, static-zero-init, fwd-static-ptr,
chained-NULL, NULL-compare, typeof-iterator, goto-retry,
`int main(){return 7;}` exit-code check — all pass);
lookup_slice.c `--exec --batch` (pass, verbatim above) + native cc
cross-check (pass); stub/unstub localization sweep (×29);
`--mode=exhaustive` ×4 (fail confirmed on the repro, pass on the 3
near-variants); sensitivity probes ×3; ddmin (~2–3k capped oracle
invocations, 25 s timeout each). NOT probed: any
other TU against the oracle (cookie/ratelimiter/peerlookup verdicts are
static analysis); the selftest battery itself (shim extension not built);
lib/crypto TUs; anything Lean-side (per instructions).

---

## ADDENDUM (2026-08-21, arc-10 S4 csmith campaign — ATTRIBUTION CORRECTION)

The §2a-addendum exec-driver defect (`can_advance: Step_error2` cluster,
declaration-layout-sensitive) was reproduced at scale by the arc-10 S4
csmith campaign (same fingerprint: one added unused declaration morphs
the failure class) — and REATTRIBUTED: it is a **cerberus-lean FORK
regression, NOT an upstream defect**. The un-forked upstream cerberus
(cerberus-lean-prototype/cerberus @ 866be5254) returns correct
gcc/Lean-agreeing results on every tested witness, including a
silent-value-corruption case (fork oracle: 187, and 138 with one added
declaration; upstream/gcc/Lean: 117). Prime suspect: the arc-2 S1
threaded symbol supply (core_run_aux.lem:233-247,287 — the in-code
invariant comment concedes an undischarged non-escape obligation).
Full evidence + root-cause analysis: cerberus-lean
`lean_frontend/docs/2026-08-20_arc10-s4-csmith-campaign.md`
(§root-cause) and reduced reproducers in `tests/csmith_findings/`.
This item therefore moves OFF the upstream tray onto the cerberus-lean
register. (The §2a parse/desugar gaps — offsetof-designator,
cast-in-initializer — remain genuinely upstream; the arc-10 campaign
separately confirmed the initializer-desugar family upstream verbatim.)
