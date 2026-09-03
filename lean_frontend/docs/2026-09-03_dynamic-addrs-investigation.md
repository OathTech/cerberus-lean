# dynamic-addrs investigation — the consumer's `free`-after-zero-size-`malloc` claim (2026-09-03)

Branch `probe/dynamic-addrs` off mainline `72164481a` (worktree
`worktrees/cerberus-lean-probe/dynamic-addrs`). INVESTIGATION ONLY: no
product code, gate, or baseline modified; this branch adds a probe
directory (`tests/noodle-probes/dynamic-addrs/`), an upstream tray
draft (`docs/upstream-tray/19-dynamic-addrs-never-cleaned.md` + INDEX
entry) and this record. Binaries: rebuilt in the worktree from
`72164481a` (`make lean-prelude-src`; `build_cerberus` under
`DUNE_CACHE=disabled`; `build_lean`; both under `scripts/capped`,
`CERB_MEM_MAX=16G`). Third engine: the un-forked upstream oracle
`deps/cerberus-upstream` @ `b9aeedcb4` (`--version` verbatim
`git-cn-pin-18-gb9aeedcb4`). Native referee: gcc 13.3.0 `-std=c11 -O0 -w`.
Quoted engine lines are verbatim from
`tests/noodle-probes/dynamic-addrs/results.log`; judgments are [AGENT];
the operator's rules cited are [USER 2026-09-03] as relayed in the brief.

## 0. Verdict in three lines

1. The claim (`refined-cerberus/docs/2026-09-03_upstream-note-dynamic-addrs.md`)
   is **CONFIRMED at the Core level** on both OCaml oracles and on the
   Lean port, and **NOT REPRODUCIBLE from C** through the library
   allocation functions on any engine (the note's C-flavoured
   consequence "`malloc(0)` then `free(p)`" is blocked by argument
   temporaries; §2).
2. The Lean port is a **faithful mirror** — zero Lean-vs-oracle
   discrepancy on the claim's programs; under the project rule (mirror
   oracle bugs, file them) this is NOT a cerberus-lean bug. Disposition:
   MIRROR + TRAY (draft 19); ISO-fix register candidate **R4 written,
   not decided** (§5).
3. **Side finding, Lean-side DISCREPANCY**: `CoreParser.lean:1281-1282`
   hardcodes the Core constant `IvMaxAlignment` to 16; the oracle
   evaluates it to 8. Every `malloc` in the Lean pipeline is 16-aligned
   where the oracle's is 8-aligned (`da_offset.c`: 8 vs 16). Product fix
   is one line (read `CerberusImpl.max_alignment`), NOT applied here (§6).

## 1. Reproduction table

Fork oracle = `_build/default/backend/driver/main.exe` from `72164481a`;
upstream = `deps/cerberus-upstream` @ `b9aeedcb4`; both
`--nolibc --exec --batch --mode=exhaustive`. Lean = `cerberus-lean --batch`
via cabs-json; `--first` agreed with `--batch` on every row. Full lines in
`results.log`; the UB rows below abbreviate `Undefined {ub: "X", ...}` to
`X` and `Defined {value: "V", ...}` to `V`.

| # | Probe | fork oracle | upstream oracle | Lean | gcc |
|---|---|---|---|---|---|
| a | `da_bug.c` — C shape: `void *q; _Alignas(16) int x=1; q=malloc(0); free(&x);` | `UB179a_non_matching_allocation_free` `<12:3--12:11>` | same | `UB179a_non_matching_allocation_free` `unknown location` | exit 139 (SIGSEGV) |
| b | `da_control.c` — `free(&x)` alone | `UB179a_non_matching_allocation_free` `<6:3--6:11>` | same | `UB179a_non_matching_allocation_free` | exit 134, `munmap_chunk(): invalid pointer` |
| c | `da_offset.c` — `(uintptr_t)&x - (uintptr_t)malloc(0)` | `Specified(8)` | `Specified(8)` | **`Specified(16)`** | native distance (192/208 across runs; ASLR) |
| c' | `da_align16.c` — `malloc(0)%16==0` + 2·`&x%16==0` | `Specified(2)` | `Specified(2)` | **`Specified(3)`** | 3 |
| d | `da_malloc0_nonnull.c` — `malloc(0) != NULL` | `Specified(1)` | `Specified(1)` | `Specified(1)` | 1 |
| e | `core_bug.core` — `create(16,int); alloc(8,0); free(x)` | **`Specified(0)`** | **`Specified(0)`** | n/a (no `.core` runner) | n/a |
| f | `core_control.core` — `create; free(x)` | `UB179a_non_matching_allocation_free` `<5:3--5:14>` | same | n/a | n/a |
| g | `core_ptreq.core` — `PtrEq(x, q)` | two executions: `Specified(0)`, `Specified(1)` | same | n/a | n/a |
| h | `core_dup.core` — two `alloc(8,0)`, free both, `free(x)` | **`Specified(0)`** | **`Specified(0)`** | n/a | n/a |
| i | `core_dup_dead.core` — free one zero-size region twice | `UB179b_dead_allocation_free` | same | n/a | n/a |
| j | `core_use_after_free.core` — load x after (e) | `UB010_pointer_to_dead_object` | same | n/a | n/a |
| k | `core_bug_then_kill.core` — (e) then `kill(int, x)` | uncaught `Failure("Concrete: FREE was called on a dead allocation")`, exit 125 | same | n/a | n/a |
| l | `core_maxalign.core` — `IvMaxAlignment` | `Specified(8)` | `Specified(8)` | n/a | n/a |
| m | `inj_bug_bexit.c` + `inject_rand_control.core` (Lean libc injection; `rand` body = no alloc) | — | — | `UB179a_non_matching_allocation_free` | — |
| n | `inj_bug_bexit.c` + `inject_rand.core` (`rand` body = `alloc(8,0)`; `free(&x)`; `__builtin_exit(0)`) | — | — | **`Specified(0)`** | — |
| n' | `inj_bug.c` + `inject_rand.core` (same, but main returns normally) | — | — | `UB179b_dead_allocation_free` at the free's loc (the scope-exit kill of the already-freed `x`) | — |
| o | `inj_bug_bexit.c` + `inject_rand_dup.core` | — | — | **`Specified(0)`** | — |
| p | `inj_maxalign.c` + `inject_maxalign.core` (`rand` body = `pure(Specified(IvMaxAlignment))`) | — | — | **`Specified(16)`** | — |

Reading. (e)/(f) is the claim: with the zero-size region the automatic
object's `free` is accepted; without it, `UB179a`. (n)/(m) is the same
pair on the Lean side. (g) is the base-coincidence witness: `eq_ptrval`
(impl_mem.ml:1851-1858) compares allocation IDS for two `Prov_some`
pointers and the exhaustive driver explores both outcomes only when the
addresses coincide (a different address gives a single `Specified(1)`);
`IntFromPtr` yields `Unspecified` for both pointers under PNVI exposure,
so the arithmetic form was not usable at Core level. (a) is the "not
reproducible from C" row; (c) explains it (§2) and exposes the side
finding (§6). Timeouts: 60 s per run, none hit; every run under
`scripts/capped` at 16G.

### Instruments

- `.core` probes run on the two OCaml oracles (`main.ml:31` accepts
  `.core` inputs). The Lean driver has no `.core` runner (`Main.lean`
  `--parse-core` parses only), so the Lean side uses libc-body
  injection: `cerberus-lean --batch --libc inject_X.core --libc-tu <12
  metadata jsons>` replaces the pinned libc dump with a file whose only
  proc is `rand` (no parameters ⇒ no argument temporaries); the C
  program calls `rand()` and then `free(&x)`. The oracles cannot link a
  `.c` with a `.core` (both: verbatim `unknown location  error:
  undefined startup function`), so the two sides use different vehicles
  for the same Core-level shape; the controls (f)/(m) anchor each.
- `__builtin_exit(0)` (std.core `exit_proxy`) in `inj_bug_bexit.c` ends
  the run before `x`'s scope-exit kill; without it (n') the Lean run
  proceeds to that kill and reports `UB179b` (§3, secondary divergence).

## 2. Why the C shape does not reproduce (and the note's error)

The note's consequence section writes `p = create(int); q = alloc(align,
0); free(p)` and says the C route is "a two-line exercise". At the Core
level that is exactly (e). From C it is not reachable through
`malloc`/`aligned_alloc`/`realloc`: the Ail→Core translation creates a
temporary object per argument of a call to an `[ailname]` proxy
(`frontend/model/translation.lem:4435`, `Caux.pcreate loc ... ty_pe
(Symbol.PrefFunArg ...)` for each parameter, then `pstore`), so the
allocator cursor at the moment of `malloc_proxy`'s `alloc(IvMaxAlignment,
size)` (std.core:354) is the base of the fresh `size_t` temporary — an
8-aligned object of size 8 — never the base of a user object. `malloc(0)`
therefore always coincides with its own temporary, which is killed
(statically) on return; the allocator is monotone (`allocator`,
impl_mem.ml:1247-1265, only ever lowers `last_address`), so no later live
object can acquire that base. Measured: (c) `&x - q = 8` on both oracles
(one temporary), and (a) `UB179a` on all three engines.

[AGENT] Consequently the note's "C-observable" framing is wrong and its
"reasoned, not executed" caveat was load-bearing; the semantic
imprecision it identifies is real (Core level, all engines). Paths not
assessed: the fork-only `cerb::with_address` attribute
(`allocator_with_address`, :1267 — places an object at a chosen address
and could collide by construction; out of scope for an upstream report
about the standard path) and hand-written Core.

## 3. Localisation and the mirror verdict

OCaml (`memory/concrete/impl_mem.ml`, byte-identical to upstream master
@ `b9aeedcb4` through :2998; the fork's only delta is :2999-3003, a
census helper):

- `dynamic_addrs: address list` :497, initial `[]` :517.
- `is_dynamic addr = List.mem addr st.dynamic_addrs` :661-663.
- `allocate_region` :1420-1435: `allocator size_n align_n` (:1421),
  record `{prefix= PrefMalloc; base= addr; size= size_n; ty= None; ...}`
  (:1429, no `size_n > 0` check), `dynamic_addrs= addr :: st.dynamic_addrs`
  (:1433) — the list's only writer.
- `kill loc is_dyn` :1464-1550. `Prov_symbolic` arm :1479-1513 and
  `Prov_some` arm :1515-1550: if `is_dyn`, `is_dynamic addr` first
  (:1518-1525 → `Free_non_matching` = UB179a), then `is_dead` (:1527-1532:
  dynamic → `Free_dead_allocation` = UB179b; static → `failwith
  "Concrete: FREE was called on a dead allocation"` :1532, the (k)
  crash), then `addr = alloc.base` (:1534-1549; mismatch →
  `Free_out_of_bound`, which mem_common.lem:283-284 maps to no UB —
  "internal error"). Both arms update only `dead_allocations`,
  `last_used`, `allocations` (:1505-1509, :1540-1542): `dynamic_addrs`
  is never written.
- `realloc` :2671-2690 reuses `is_dynamic addr` (:2675) with the same
  shape.

Lean (`lean_frontend/CerbMem.lean` at `72164481a`; the note's
`:1538-1548`/`:1573-1578` were at pin `ddcfc9199` — re-located):

- `dynamicAddrs : List Address := []` :135.
- `allocateRegion` :1873-1891: `size := sizeN.toNat` (:1878, no lower
  bound), `alignedAddr := alignDown (lastAddress - size) align` (:1879-
  1880 — the same cursor arithmetic as `allocator`), `dynamicAddrs :=
  alignedAddr :: st.dynamicAddrs` (:1888) — the only writer.
- `killM` :1895-1920: dead check :1906-1907 (`Free_dead_allocation` for
  static AND dynamic kills), base check :1911-1912
  (`Free_out_of_bound`), dynamic check :1913-1914 (`isDynamic &&
  !st.dynamicAddrs.contains alloc.base` → `Free_non_matching`); the
  success path :1916-1919 writes `deadAllocations` and `allocations`
  only. `realloc` :2383-2412 reads `dynamicAddrs.contains addr` (:2388).

Mirror verdict [AGENT]: on the claim's programs the Lean port agrees
with both oracles wherever both can run the shape — (a)(b)(d) AGREE
three-way; the Core-level pair (e)/(f) on the oracles is matched by
(n)/(m) on Lean, and the duplicate-address case (h) by (o). The
address-keyed list, the zero-size admission and the write-free kill are
mirrored line for line. Under the project rule (zero execution
discrepancies; oracle bugs are mirrored and filed) **this is not a
cerberus-lean bug**.

Two Lean-vs-OCaml differences in the same code, for the record, neither
of which touches the claim:

1. Check ORDER in `kill`: OCaml dynamic → dead → base; Lean dead → base
   → dynamic. Observable only when two conditions hold at once — the
   noodle slice's seam D6/D7 rows (`noodle/semantics`
   `tests/noodle-probes/seam/README.md`: free of an interior pointer,
   oracle `UB179a` vs Lean `Free_out_of_bound` Error) are this. Not
   re-examined here.
2. Static kill of a DEAD allocation: OCaml `failwith` (uncaught
   exception, exit 125 — row k) vs Lean `UB179b` (row n'). Reachable only
   after an accepted wrong `free` — i.e. only through this bug (or
   `with_address`). ORACLE_CRASH-vs-Lean-UB class; Lean's is the
   fail-closed-with-verdict behaviour. Reporting-only.

Duplicate-address case (asked in the brief): two zero-size regions at
`B` get distinct allocation ids; `free` of each kills its own id (the
address stays in the list twice, unused); a second `free` of the SAME
region is `UB179b` (i). After both are freed, `free(x)` is still accepted
(h)/(o). No engine mis-attributes one region's kill to the other — the
duplicate list entries are inert; the defect is the address keying, not
the duplication.

## 4. Disposition (i): MIRROR + TRAY

Draft: `docs/upstream-tray/19-dynamic-addrs-never-cleaned.md` (TRUE BUG,
memory-model soundness gap, low C exposure); INDEX.md updated (entry 19,
filing order after 16). Remedy recommendation [AGENT], with the
assessment of the note's two fixes:

- Note's fix 1 (erase the address in `kill`'s dynamic arm): NOT
  behaviour-preserving. `kill` checks `is_dynamic` before `is_dead`
  (:1518 vs :1527), so a double `free` would flip from `UB179b` to
  `UB179a`; `realloc` of a freed pointer (:2675 vs :2679) from `UB179d`
  to `UB179c`. Those codes are pinned by our lanes (`tests/immaculate/
  baseline.txt` `g3-realloc-dead MATCH | L=UB:UB179d_dead_allocation_
  realloc`) and presumably by upstream's suites. Erasing also cannot
  handle two live zero-size regions at one address without counting.
- Note's fix 2 (per-allocation flag): right idea, wrong carrier — `kill`
  removes the record (:1542), so the dead-arm verdicts lose the flag.
- Recommended: track dynamic allocations by ID (`dynamic_ids:
  storage_instance_id list`, pushed in `allocate_region`, never
  reused, never needs cleaning); `is_dynamic alloc_id`; the
  `Prov_symbolic` arm resolves the iota first. Identical verdicts on
  every existing program except the collision (fixed) and one doubly-UB
  corner (interior pointer into a freed dynamic block: `UB179a` →
  `UB179b`). Detail in the draft. The Lean mirror of that fix is the
  same three-line change in `CerbMem.lean` — to be made only when
  upstream accepts (mirror doctrine), or under a register ruling (§5).

## 5. Disposition (ii): ISO-fix register candidate R4 — NOT decided

Operator's class (d) [USER 2026-09-03, per brief]: a short, per-entry
[USER]-ruled list of deliberate Lean deviations toward ISO; bar:
unambiguous ISO clause; a second independent oracle agrees with the
Lean-side behaviour; filed upstream; pinned in the immaculate lane as a
Lean-right/oracle-wrong pair. (R1-R3 are taken here to be the existing
Lean-right/oracle-wrong pins — `g5-decode-question` `'\?'`=63 and
`g5-escape-roundtrip` 127 in `tests/immaculate/baseline.txt` — plus
whatever the operator has slotted; the numbering is the brief's.)

**R4 (candidate) — `free` of a non-dynamic allocation must be UB179a
even when a zero-size dynamic region shares its base.** Lean-side
deviation: `killM`'s dynamic check keyed on allocation identity
(dynamic ids) instead of `dynamicAddrs.contains base`. Evidence: §1
rows (e)(f)(h)(k) on both oracles, (m)(n)(o) on Lean; tray 19.

Criteria, one by one [AGENT]:

| Criterion | Status |
|---|---|
| Unambiguous ISO clause | MET. C11 §7.22.3.3p2 is explicit; Cerberus's own UB179a names exactly this case. |
| Second independent oracle agrees with the Lean-side (deviated) behaviour | PARTLY. glibc rejects `free(&x)` (abort/SIGSEGV, rows a/b) — but on the C shape, which Cerberus already rejects; no native oracle can run the Core shape. Agreement is in kind (reject), not on the defect's own input. |
| Filed upstream | NOT YET — draft 19 written; filing is the operator's networked step. |
| Pinned in the immaculate lane as a Lean-right/oracle-wrong pair | NOT POSSIBLE with today's lanes: no single input reproduces the defect on both engines (Core-only; C is blocked by temporaries on both). A pin needs either a Core-level differential lane (Lean `.core` runner — new driver surface) or an injection-capable pair (Lean `--libc` injection vs oracle `.core`, two vehicles). |

For admission (the soundness side): this is the class a verifier
consumer cares about most — the semantics ACCEPTS a UB program, so an
"execution completed" verdict from the engine is not evidence of
§7.22.3.3 compliance; the fix is small, identity-based, and provably
verdict-preserving on non-colliding programs; refined-cerberus's K1
coupling currently carries `dynamic = true → base ∈ dynamicAddrs` only,
and an exact engine check would let the converse be stated. The
consumer verifies programs at the Core level, where the shape IS
reachable.

Against admission (the discipline side): (1) the deviation would be
invisible to every differential lane — the gates cannot pin it, so the
"Lean-right/oracle-wrong pair" criterion is not merely unmet but
currently unmeetable; an unpinned deviation is exactly the trust gap the
register's bar exists to exclude. (2) From C the engine already gives
UB179a on all three engines; the missed UB is not reachable by any C
program through the standard library, so the soundness exposure for
C-level consumers is nil today. (3) refined-cerberus states its logic is
sound regardless — its `free` precondition (the metadata cell's
`dynamic` flag) IMPLIES the engine's check, and the colliding program is
simply outside the logic (deliberately incomplete on a UB program) — so
no consumer is blocked. (4) Mirror doctrine: a Lean-only fix creates a
permanent oracle divergence on Core-level inputs that the upstream fix
would later make redundant; the cheap path is upstream-first. (5) The
fix touches `killM`'s check structure, next to the D6/D7 order
differences the noodle slice has already recorded — better done as one
seam-alignment change with those, after upstream's position is known.

[AGENT] recommendation offered for the ruling, not a decision: **defer
R4** — file tray 19, keep Lean mirroring, and revisit if (a) upstream
declines or stalls AND (b) a Core-level pinned lane exists (the pin
criterion becomes meetable). If the operator wants R4 admitted now, the
honest form of the register entry says "pinned by `tests/noodle-probes/
dynamic-addrs/` (oracle `.core` rows vs Lean injection rows), not by
the immaculate lane".

## 6. Side finding — Lean `IvMaxAlignment` = 16, oracle 8 (DISCREPANCY, Lean-wrong)

`parsers/core/core_parser.mly:1536-1537`: `IVMAX_ALIGNMENT → integer_ival
(Ocaml_implementation.(get ()).max_alignment)`; `DefaultImpl.max_alignment
= 8` (`ocaml_frontend/ocaml_implementation.ml:151-152`; `MorelloImpl`'s 16
at :310-311 is selected only under CHERI, `backend/driver/main.ml:131`).
Both oracles: row (l) `Specified(8)`. `lean_frontend/CoreParser.lean:
1281-1282`: `| some "IvMaxAlignment" => ... CerbMem.integerIval 16` — a
literal, while `lean_frontend/CerberusImpl.lean:20` declares
`max_alignment : Nat := 8` "Corresponds to: DefaultImpl.max_alignment".
Lean: row (p) `Specified(16)`. Every `malloc`/`realloc` (std.core:354,
:365 `memop(Realloc, IvMaxAlignment, ...)`) is therefore 16-aligned in the Lean
pipeline and 8-aligned in the oracle: rows (c) 8 vs 16 and (c') 2 vs 3
are the C-observable consequence (UB-free programs: implementation-
defined pointer→integer conversion, §6.3.2.3p6). Undetected so far
because no corpus program observes heap addresses modulo 16, and the
2026-08-30 gcc-oracle design table (:160) compared OCaml 8 vs gcc 16, not
Lean. [AGENT] classification: Mirror-OCaml-doctrine defect, Lean-wrong;
NOT an ISO-fix candidate (ISO says nothing about the model's allocation
alignment). Fix: `CerbMem.integerIval CerberusImpl.max_alignment` at
`CoreParser.lean:1282` — NOT applied on this branch (investigation
only). Integration: `da_offset.c` and `da_align16.c` as
`tests/immaculate/nolibc/` DIFF rows pinned at the Lean values; they
flip to MATCH with the fix. Also a candidate row for the gcc lane's
existing `max_alignment` triage (gcc's `max_align_t` is 16, so gcc
agrees with the WRONG side here — a reminder that the gcc lane referees
ISO-determined values, not layout).

## 7. Probe integration (task 4)

`tests/noodle-probes/dynamic-addrs/` — README (ISO cite, per-probe
table, INTEGRATION table), `results.log` (verbatim four-engine pin),
`run_dynaddr.sh` (fork + upstream + Lean `--batch`/`--first` + gcc;
`--inject` mode; fail-closed on missing binaries/jsons; 60 s timeouts;
`scripts/capped`). The directory sits under `tests/noodle-probes/`
because that is where the 2026-09-03 probe corpora live (`noodle/
semantics`, unmerged); the top-level `tests/noodle-probes/README.md` is
that branch's and is NOT duplicated here. Recommendation: the C rows
(a)(b)(d) → exec corpus MATCH rows; (c)(c') → immaculate DIFF pins (§6);
the `.core` and `inj_*` rows → reporting-only pins cross-referenced from
tray 19 (no lane runs `.core` on both sides — the R4 pin gap of §5).

## 8. What was NOT done

- No product change (CoreParser constant, killM), no gate or baseline
  edit, no merge, no push.
- `cerb::with_address` collision path not probed.
- The `Prov_symbolic` (PNVI-ae-udi) arm not exercised (the concrete
  pipeline mints `Prov_some`).
- Libc-mode (`libc.co`-linked) runs of the C probes not repeated — the
  `--nolibc` runs already resolve `malloc`/`free` to the same std.core
  proxies (translation.lem ailname redirect), and the finding is
  temporary-driven, not libc-driven.

## 9. Provenance

[USER 2026-09-03] the brief: reproduce on three engines, localise,
disposition per the MIRROR+TRAY default and the ISO-fix register bar,
probes suite-ready, no product changes. [AGENT] everything else:
probe design, the argument-temporary explanation (§2), the mirror
verdict (§3), the remedy assessment (§4), the R4 text and the deferral
recommendation (§5), the IvMaxAlignment finding (§6). Every quoted
engine line is verbatim from `results.log` or the named scratch run;
line numbers are from the tree at `72164481a` and were re-read on
2026-09-03. Nothing pushed.
