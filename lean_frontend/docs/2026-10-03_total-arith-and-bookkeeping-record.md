# Total arithmetic and register bookkeeping — record, 2026-10-03

Branch `fix/total-arith-and-bookkeeping`, cut from mainline
`mdd/cerberus-lean` at `621caf996`. Worker: [AGENT] Claude, at operator
direction (the orchestrator's brief). One commit per task; each section
below names what changed, the witnesses, and the verbatim gate lines of
that step.

The standing rules that drive this record (verbatim, as briefed):

- [USER 2026-10-03] "Generally, our rule is that we don't innovate wrt
  Cerberus-upstream, unless something is very very very obviously a bug.
  We're poorly placed to resolve semantic discrepancies, so we don't. ...
  we should fall back to loudly rejecting (either as unsupported, or
  matching upstream)."
- [USER 2026-10-03] "We do not resolve Cerberus TODO cases unless the
  answer is extremely obvious or if there's a similarly obvious bug, or for
  some reason we or some downstream customer need it with absolute
  priority".
- [USER 2026-10-03] "we specifically want to lift the address-space-top
  restriction for the sake of treating cerberus as a proof artifact. Agree
  on your recommendations with that framing (we shouldn't revert work that
  allows the iris reasoning to work properly)".
- [USER 2026-09-30] "we should not fix deviations with special 'magic
  mode' paths that work exclusively in one situation".

Upstream line numbers cite the un-forked tree
`deps/cerberus-upstream/memory/concrete/impl_mem.ml` (merge-base
`b9aeedcb4`) unless marked "fork".

## 1. Z2-M-01 — remainder by zero (task 1)

**Before.** `CerbMem.integerRem_t`/`integerRem_f` were Lean's total
`Int.tmod`/`Int.emod` (x mod 0 = x) and `integerDiv_t` the total
`Int.tdiv`. Upstream `op_ival` (`impl_mem.ml:2481-2484`) calls
`Z.integerRem_t = (mod)` = `Z.rem` and `Z.integerRem_f =
Big_int_Z.mod_big_int` (`:11-12`) with NO zero guard (unlike `IntDiv`,
`:2479-2480`); both raise `Division_by_zero`. Reached from C by
`runtime/libcore/std.core:385` (`aligned_alloc_proxy`: `if size rem_t
align = 0`). `aligned_alloc(0, 8)`: oracle `cerberus: internal error,
uncaught exception: Division_by_zero` (rc 125); Lean `Undefined {ub:
"DUMMY(align_alloc)", …}` — a value upstream never chooses.

**Change.** The three helpers fail-stop on a zero divisor with
`failwithI` — the mechanism `opIval`'s `IntExp` arm uses for a negative
exponent — citing the zarith raise and the OCaml lines (`:2481-2482`,
`:2483-2484`, and `:1967` for `diff_ptrval`'s `Z.div`, which divides by
`sizeof` and raises on 0 the same way). The guard lives in the helpers,
i.e. in the mirror of zarith's own behaviour, so every caller inherits it
(no per-caller special path). `opIval IntDiv` keeps upstream's explicit
`n2 = 0 → 0` guard in front of the helper. The `CerbMem.allocator`
alignment-0 kill (`impl_mem.ml:1252`/fork `:1258` `quomod` raises) was
already a fail-stop; its comment and message text drop the "operator
decision pending" wording (the unit pin in `test/Unit/MonadicFailstop.lean`
follows the message), and the comment records that its one former C route,
`aligned_alloc(0, 0)`, now stops earlier at `std.core:385`, as on the
oracle.

**Witnesses (both engines, probe = oracle `--exec --batch [--nolibc]` vs
Lean `--batch --first` on the oracle's `--cabs-json`).**

```
zd-z2m01-aligned-alloc-zero-nolibc:
ORACLE rc=125:  | cerberus: internal error, uncaught exception:
          Division_by_zero
LEAN   rc=134:  | PANIC at _private.LemLib.0.failwithIImpl LemLib:239:2: CerbMem.integerRem_t: Division_by_zero (zarith Z.rem raises; mirrors the oracle's uncaught exception, impl_mem.ml:2481-2482 op_ival IntRem_t)
zd-z2m01-aligned-alloc-zero (libc): identical two lines
```

Controls (the C `%`/`/` operators are guarded by the elaborator's UB045
before `rem_t`/`div`, so they never reach the helpers; both engines agree):

```
int x=5; return x % 0;     ORACLE/LEAN rc=1: Undefined {ub: "UB045b_modulo_by_zero", stderr: "", loc: "<1:32--1:37>"}
return 5 % 0;              ORACLE/LEAN rc=1: Undefined {ub: "UB045b_modulo_by_zero", stderr: "", loc: "<1:23--1:28>"}
unsigned x=5; x / 0u;      ORACLE/LEAN rc=1: Undefined {ub: "UB045a_division_by_zero", stderr: "", loc: "<1:37--1:43>"}
int y = 0; return 7 % y;   ORACLE/LEAN rc=1: Undefined {ub: "UB045b_modulo_by_zero", stderr: "", loc: "<1:34--1:39>"}
```

`diff_ptrval` with a zero-size element (the `integerDiv_t` route): not
constructible — `int (*)[2][0]` is refused by the shared front end on both
engines (oracle `error: constraint violation: array declared with a
negative or zero size`; Lean `Error {msg: "desugaring failed at
za.c:1:32-42"}`, a front-end rejection), and a member-less struct is
`UB061_no_named_members` on both.

**Pins (hand-edited, never `--record`).** `tests/immaculate/baseline.txt`:
`zd-z2m01-aligned-alloc-zero-nolibc` and `zd-z2m01-aligned-alloc-zero`
`ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", …}` → `MATCH | L=CRASH`;
`-zero-zero` stays `MATCH | L=CRASH`, now for the same cause on both
engines. The baseline's header note and the `--record` header template in
`scripts/test_immaculate.sh` were changed together (dated note citing the
rule). The three fixtures' header comments were rewritten in place with the
SAME line count (the program lines, hence any locations, do not move).

**Docs.** Z2 record: an addendum (`2026-09-04_zero-discrepancy-Z2-record.md`,
end) withdraws the §10.1 [AGENT] recommendation (Core-level UB045 /
`std.core:385` guard) as invention under the rule; nothing above it was
rewritten. VALIDATION §3: the "still open" `aligned_alloc(0, n)` bullet is
replaced by a "mirrored" paragraph. Tray draft 34 (still a Draft, never
sent) and its INDEX entry: the sentence about our port holding a
divergence open now says the port mirrors the crash; the remedy proposed
to upstream is unchanged (proposing to upstream is not innovating here).

**Failure-reach register.** `check_failure_reach.sh --emit` (first banner
line stripped) gave exactly three new UNREVIEWED rows; reviewed by reading
and resealed with `check_failure_reach.py --reseal`:

| site | position_reviewed | reach | reason |
|---|---|---|---|
| `CerbMem.integerDiv_t` | TAIL | UNREACHABLE-BY-INVARIANT | callers: `opIval IntDiv` (guarded first, `:2479-2480`) and `diffPtrval` (divisor `sizeof(elem) ≥ 1`; zero-size types refused by the front end / UB061) |
| `CerbMem.integerRem_t` | TAIL | REACHABLE | witness `zd-z2m01-*` (both crash) |
| `CerbMem.integerRem_f` | TAIL | UNREACHABLE-BY-INVARIANT | the elaborator never emits `rem_f`; `std.core:59`/`:238` and `core_eval.lem:34` divide by `Ivmax − Ivmin + 1 ≥ 1`, `std.core:164` by the literal 2 |

Tally line moved `sites=230 … UNREACHABLE-BY-INVARIANT=170 REACHABLE=39`
→ `sites=233 … UNREACHABLE-BY-INVARIANT=172 REACHABLE=40`.

**Gates (this step; build = `make lean-prelude-src` + capped `lake build
CerberusLean cerberus-lean`, `Build completed successfully (395 jobs).`).**

```
./scripts/test_unit.sh rc=0
Done: 292 passed, 0 failed
Total: 16 passed, 0 failed
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
./scripts/test_immaculate.sh rc=0
  MATCH          zd-z2m01-aligned-alloc-zero-nolibc  O[CRASH] L[CRASH]
  MATCH          zd-z2m01-aligned-alloc-zero  O[CRASH] L[CRASH]
  MATCH          zd-z2m01-aligned-alloc-zero-zero  O[CRASH] L[CRASH]
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

(A first immaculate run failed rc 2 with a bash syntax error at
`scripts/test_immaculate.sh:321`: the new header-template lines carried
unescaped `"` from the quoted ruling. Escaped; re-run above.)

**gcc second-oracle ledger (Tier B row 7, not re-run in full here).** A
partial run `SKIP_BUILD=1 ./scripts/test_gcc_oracle.sh
--write-baseline=<scratch> tests/immaculate/nolibc` (rc 0, `gcc second-oracle
lane OK`, 61 rows) differs from the committed ledger in exactly:

```
< tests/immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc.c SKIP_UB -
> tests/immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc.c SKIP_LEAN_CRASH -
> tests/immaculate/nolibc/zd-invalid-format-utf8-payload.c SKIP_UB -
```

The first is this step's movement and is hand-edited into
`scripts/gcc_oracle_baseline.txt` with a dated header note. The second is a
PRE-EXISTING ledger gap (the fixture landed in `eccc83b58`, bug hunt BUG-4,
with no ledger row; the lane reports such files as "new file (not in
baseline, not fatal)"). Not this slice's movement; left for the operator
(a finding, not re-pinned).

## 2. The sweep — total arithmetic and defaults in the hand-written seams (task 2)

**Method.** Two directions. (a) Every exception source in the OCaml the
seams mirror — `memory/concrete/impl_mem.ml` (`Z.to_int`, `Z.div`/`rem`/
`modulus`/`quomod`, `Z.pow`, `List.nth`/`hd`, `Pmap.find`/`IntMap.find`),
`ocaml_frontend/ocaml_implementation.ml`, `decode.ml`,
`ocaml_gcc_builtins.ml` — was listed and its Lean counterpart read. (b)
Every executable hand-written seam (`lean_frontend/*.lean` minus the proof/
measure modules) was grepped, comment-stripped, for `/`, `%`, `<<<`/`>>>`,
`.toNat`/`toUInt*`/`natAbs`, `getD`/`headD`/`get!`/`[i]!`/`[i]?`, and
`| none =>`/`| _ =>` value defaults; each hit was read. Probes are single
programs on both engines (oracle `--exec --batch [--nolibc]`, Lean
`--batch --first` on the oracle's `--cabs-json`, libc mode where noted).

### 2.1 Fixed (reachable; plain mirror, loud fail-stop)

`CerberusImpl.zToInt site n` is new: zarith's `Z.to_int` raises
`Z.Overflow` outside OCaml's native int range, `[min_int, max_int] =
[-2^62, 2^62-1]` on the 64-bit hosts upstream builds for; `zToInt` returns
`n` inside the range and `failwithI`s outside it, naming the site. The
bounds are `ocamlMinInt`/`ocamlMaxInt`, documented as forced by OCaml.

| # | OCaml | Lean before | Fix | Witness (both engines) |
|---|---|---|---|---|
| S-1 | `impl_mem.ml:248` / `:267`: `Concrete.alignof`'s struct/union member folds read `AlignInteger al_n` through `Z.to_int al_n` (offsetsof `:115-122` and union sizeof `:179-186` keep the `Z`) | `al_n.toNat`, no failure | `CerbMem.alignofMemberRead` wraps the member alignment in alignof's two folds only (`zToInt`); `memberAlign` is unchanged for offsetsof/sizeof | `zd-ta-alignas-huge-sizeof` (`sizeof` of a struct with an `_Alignas(0x4000000000000000)` member): oracle `Z.Overflow` rc 125, Lean before `Specified(0)`; `zd-ta-alignas-huge-union-alignof` (`_Alignof` of such a union): oracle `Z.Overflow` rc 125, Lean before `Specified(0)` |
| S-2 | `ocaml_implementation.ml:483` / `:501` (fork `:496`/`:514`): `Ocaml_implementation.alignof` (the desugarer's `alignof_ty`) reads `Some (Z.to_int al_n)` | `some n.toNat` | `CerberusImpl.alignof_ty`'s `AlignInteger` arm goes through `zToInt` | `zd-ta-alignas-huge-desugar` (`_Alignas(8) struct s g;` with a 2^62-aligned member): oracle `Z.Overflow` rc 125 raised from `Cabs_to_ail.desugar_alignment_specifiers`, Lean before `Error {msg: "desugaring failed at altyd2.c:2:22-23"}` |

The front end ACCEPTS `_Alignas(2^62)` (a power of two; `cabs_to_ail.lem`
`desugar_alignment_specifier` refuses only 0 → dropped, negatives and
non-powers of two). Control `zd-ta-alignas-2p61-control` (`2^61`, inside
the range): `Specified(4)` on both engines before and after. Post-fix, all
three witnesses give on Lean (rc 134):

```
PANIC at _private.LemLib.0.failwithIImpl LemLib:239:2: Z.to_int: Z.Overflow (outside OCaml's native int range [-2^62, 2^62-1]; mirrors the oracle's uncaught exception) at Concrete alignof (impl_mem.ml:248/:267)
PANIC at _private.LemLib.0.failwithIImpl LemLib:239:2: Z.to_int: Z.Overflow (outside OCaml's native int range [-2^62, 2^62-1]; mirrors the oracle's uncaught exception) at Ocaml_implementation.alignof (ocaml_implementation.ml:483/:501)
```

(the first for sizeof/union-alignof, the second for the desugar witness).
Other controls, both engines equal before and after: `_Alignas(0)` member
(dropped by §6.7.5#6) `Specified(11)`; `offsetof` past a 2^62-aligned
member `Specified(0)` (offsetsof keeps the `Z`, no raise upstream either);
`_Alignas(8) struct s *p` `Specified(0)`; `_Alignas(-8)` refused by the
front end on both.

The measure proof `CerbMem_lemMeasureProofs.lean` (fuel congruence of
`alignofCtype_lemFuel`'s struct fold) restates its `hcong` with the
wrapper; no other proof moved.

### 2.2 Unreachable (with the reason)

| # | Site (OCaml → Lean) | Why it cannot be reached |
|---|---|---|
| U-1 | layout `Z.modulus … align` (`impl_mem.ml:123`, `:169-171`, `:189-191`) raises on 0 → Lean `% 0` = identity | an alignment of 0 needs `_Alignas(0)` (dropped by the desugarer, probe: both `Specified(11)`), a member-less struct (UB061 on all engines, `tests/z2-probes/mem/empty_struct.c`) or a zero-length array (constraint violation on both); already declared Z2-M-11 |
| U-2 | `Array (_, Some n)` `Z.mul n` with negative `n` (`:150-151`) → Lean `n.toNat * …` | array sizes are front-end non-negative (Z2-M-11) |
| U-3 | `Concrete.allocator` `quomod … 0` (`:1252`) | already a fail-stop; its only C route (`aligned_alloc(0, 0)`) now stops earlier at `std.core:385`, as on the oracle (§1) |
| U-4 | `Z.to_int` on object SIZES: abst `:950/:975/:996/:1064/:1074`, repr `:1144/:1149/:1155/:1217`, alloc `:1225/:1311/:1442/:1450`, load `:1559` | needs an object or an access of ≥ 2^62 bytes. At the default address-space top every such allocation is out of memory first (`struct big` local of 2^62 bytes: both `MerrOther "Concrete.allocator: failed (out of memory)"`) and every such access is out-of-bound first (`*p = *q` on a 2^62-byte struct type over an `int`: both `UB_CERB002a_out_of_bound_load`; `memcpy(a, b, 2^62)` in libc mode: both `UB_CERB002a_out_of_bound_load`). Non-default tops: §3 / operator list O-1 |
| U-5 | `memcmp` `Z.to_int size_n` (`:2660-2661`) | REACHABLE but registered: ISO-fix register R3 (`s4b-memcmp-hugesize`); not changed (the owed code marker is task 4) |
| U-6 | `IntExp` `Z.pow n1 (Z.to_int n2)` (`:2490`) | the shift elaboration's UB checks dominate: `1 << -1` both `UB051a_negative_shift`; `1ULL << 2^62` and `8ULL >> 64` both `UB51b_shift_too_large`; the negative-exponent arm is already a fail-stop |
| U-7 | `Z.to_int` of a function-pointer address (`:1012`, `:1823`) | taken only after a successful `funptrmap` lookup: registered addresses are small |
| U-8 | `Decode.encode_character_constant` `Z.to_int n` (`decode.ml:225`) | callers: `printf` `%c` (argument type-checked — a `unsigned long long` argument is `UB153b_illtyped_argument_for_format` on both), the char-array loader (char-range bytes), `step_fs_proc` (CerbFS refuses every operation) |
| U-9 | `Ocaml_gcc_builtins.ctz` `Z.to_int64` (`:4`) | only `__builtin_ctz` (unsigned int argument) is wired; `__builtin_ctzl`/`ctzll` are unknown procedures on both engines (probe). bswap16/32/64 were already mirrored (g4 pins) |
| U-10 | `diff_ptrval` `Z.div … (sizeof elem)` (`:1967`) | now mirrored anyway by `integerDiv_t` (§1); zero-size element types do not exist past the front end |
| U-11 | `va_arg` `List.nth_opt` (`:2729`) | an option: already the mirrored kill |
| U-12 | `Pmap.find` → `Not_found` (`:100`, `:173`, `:229`, `:255`, `:1078`); `IntMap.find iota` (`:879`) | every Lean tag-lookup arm already fail-stops (`CerbMem` offsetsof/sizeof/alignof/reconstruct); the iota map is PNVI-ae-udi only and `--switches` is refused |
| U-13 | `Option.get` in `normalise_integerType_` (`ocaml_implementation.ml:40-44`) | already a fail-stop (Z2-I-03) |
| U-14 | `Ocaml_implementation.alignof` `assert false`/`Not_found` for void, function and unknown tags → Lean `none` | declared Z2-I-04 (Ail typing rejects those first); the incomplete-type `_Alignas` case is upstream-tray 47, owned by the separate `fix/alignas-p2d3` work — not touched here |
| U-15 | `decode.ml:16` `int_of_char n - int_of_char '0'` (no raise; garbage for a non-digit) → Lean `readDigit` default 0 | not an exception site; reachable only through `[[cerb::with_address("…")]]`, whose allocation Lean refuses ("TODO: cerb::with_address() is yet implemented") |
| U-16 | Lean-only defaults with NO OCaml counterpart: `Main.lean` libc loader `(tagMap[n]?).getD s` (`:863`, `:970`), `restArgs.getD` (CLI name), the UTF-8 validator's `b[i]!` (bounds-checked), `CoreParser` line table `tbl[…]!` | port-side vehicles, nothing to mirror |

### 2.3 For the operator (NOT changed)

- **O-1** — with a NON-DEFAULT `--address-space-top` ≥ 2^62 an object of
  ≥ 2^62 bytes can be allocated, and the fork oracle's `Z.to_int` on sizes
  (U-4) would raise where Lean computes. §3 states that non-default values
  are outside the mirroring promise; listed so the gap is visible, not
  closed.
- **O-2** — the pre-existing gcc-ledger gap of §1 (no row for
  `zd-invalid-format-utf8-payload.c`).
- **O-3** (added in step 4) — a RULE TENSION, raised rather than resolved.
  VALIDATION §0's [USER 2026-09-03] referent ruling classes `Z.Overflow`
  from a host-int conversion and `Division_by_zero` from a missing guard as
  KIND-2 OCaml-execution artifacts that are NOT mirrored (Lean implements
  the logical meaning), and R3 (memcmp's `Z.to_int size_n`) is admitted BY
  CLASS on exactly that basis. This branch, as briefed under [USER
  2026-10-03] ("... fall back to loudly rejecting (either as unsupported, or
  matching upstream)"), mirrors the same two exception kinds as loud
  fail-stops (§1, §2.1). Under the 2026-09-03 reading, Lean's former
  `Specified(0)` for `sizeof` of a 2^62-aligned struct was arguably the
  logical (unbounded-`Z`) answer. [AGENT] default taken: the fail-stop
  (fail-closed, the brief's explicit instruction). Operator questions: does
  the 2026-10-03 rule supersede the kind-2 paragraph; should R3 likewise
  become a fail-stop; should §0 be re-worded. A pointer note was added under
  VALIDATION §0; the ruling text itself is untouched.
  **RESOLVED 2026-10-03** by the synthesis [USER 2026-10-03] "(1) agree with
  this" and the F1 ruling — see §7 (alignment reads: computed, R7;
  division/remainder by zero: stops stay). VALIDATION §0 now carries the
  2026-10-03 rule and the synthesis next to the referent ruling.

### 2.4 Pins and register

- `tests/immaculate/baseline.txt`: four rows hand-inserted
  (`zd-ta-alignas-huge-{desugar,sizeof,union-alignof}` `MATCH | L=CRASH`,
  `zd-ta-alignas-2p61-control` `MATCH | L=VAL:{value: "Specified(4)", …}`),
  header note + `--record` template together.
- `scripts/gcc_oracle_baseline.txt`: four rows hand-inserted at the
  statuses a partial `--write-baseline` over `tests/immaculate/nolibc`
  observed (three `SKIP_LEAN_CRASH`, the control `SKIP_GCC_COMPILE`).
- Failure-reach register: one new site, `CerberusImpl.zToInt` — position
  TAIL, reach REACHABLE (witnesses above); resealed. Tally `sites=234 …
  REACHABLE=41`.

### 2.5 Gates (this step)

```
build: Build completed successfully (395 jobs).
./scripts/test_unit.sh rc=0
Done: 292 passed, 0 failed
Total: 16 passed, 0 failed
check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=41 UNKNOWN=21; every row sealed; tally line consistent)
./scripts/test_immaculate.sh rc=0
  MATCH          zd-ta-alignas-2p61-control  O[VAL:{value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}] L[VAL:{value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}]
  MATCH          zd-ta-alignas-huge-desugar  O[CRASH] L[CRASH]
  MATCH          zd-ta-alignas-huge-sizeof  O[CRASH] L[CRASH]
  MATCH          zd-ta-alignas-huge-union-alignof  O[CRASH] L[CRASH]
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
./scripts/test_exec.sh --check-baseline rc=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage rc=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
partial ./scripts/test_gcc_oracle.sh --write-baseline=<scratch> tests/immaculate/nolibc rc=0: gcc second-oracle lane OK (65 rows)
```

## 3. `--address-space-top` documentation (task 3)

Docs only. `CONTRACT.md` §2 gains a paragraph and `VALIDATION.md` §7 (the
"address-space top is a parameter too" block) a matching passage:

- the parameter is a DELIBERATE lift of upstream's constant for proof use,
  citing [USER 2026-10-03] verbatim ("we specifically want to lift the
  address-space-top restriction for the sake of treating cerberus as a
  proof artifact. ...");
- its default mirrors upstream exactly (`impl_mem.ml` `last_address=
  Z.of_int 0xFFFFFFFFFFFF; (* TODO: this is a random impl-def choice *)`,
  verified in `deps/cerberus-upstream/memory/concrete/impl_mem.ml:508`), and
  the §1 promise holds at that default only; non-default values are outside
  the mirroring promise — pristine upstream has no such parameter, the fork's
  flag is an instrument (LADDER A12), and tops ≥ 2^62 open the `Z.to_int`
  gap of §2.3 O-1;
- the fork's symbolic and CHERI models accept the value and ignore it
  (`memory/symbolic/impl_mem.ml:571`, `memory/cheri-coq/impl_mem.ml:273`:
  `initial_mem_state (_address_space_top: Z.t)`, verified by reading); they
  are fork-oracle-only executables (`cerberus-cheri`; the symbolic driver is
  commented out of `backend/driver/dune`), while cerberus-lean has the
  concrete model alone and refuses any model-selecting flag as an unknown
  flag (Z-24).

Gate (docs-only step): `./scripts/test_unit.sh` rc=0 —
`Done: 292 passed, 0 failed`, `Total: 16 passed, 0 failed`.

## 4. Register bookkeeping (task 4)

- **`CerbFloat.floatMul` (upstream `Cerb_floating.mul = (+.)`, #1009).**
  Reachability MEASURED, not just grepped: the failure-reach instrument
  (`tests/failure-probes/FailureReach.lean`, built as a scratch package over
  this tree) prints, for every constant, membership of the exec and the
  front-end kernel dependency closures:

  ```
  FAILURE_REACH	CerbFloat.floatMul	false	false
  FAILURE_REACH	CerbFloat.floatDiv	false	false
  FAILURE_REACH	CerbFloat.floatAdd	false	false
  FAILURE_REACH	CerbMem.opFval	true	false
  FAILURE_REACH	instNumMultFloat_float	false	false
  ```

  Added to VALIDATION §2 as **R6 — PROPOSED [AGENT], NOT ADMITTED**, with
  that reachability argument standing in for the (iv) pin a reachable entry
  would carry (none can exist); code marker `-- ISO-fix register R6` at
  `CerbFloat.floatMul`, whose docstring no longer uses the retired
  "documented-deliberate divergence" label. [AGENT] reasoning: under [USER
  2026-10-03] a fix is allowed when "something is very very very obviously a
  bug" — `mul = (+.)` beside a correct `add`/`sub`/`div` is that — but every
  register entry is individually [USER]-ruled, so the row waits for the
  operator. The alternative is to mirror `(+.)` (no observable effect today
  either way). Report item.
- **R3 marker.** `-- ISO-fix register R3` now sits at `CerbMem.memcmpM`'s
  size use (`getBytes … size_n.toNat`), with the upstream cite
  (`impl_mem.ml:2660-2661` `Z.to_int size_n`) and the pin; VALIDATION's R3
  row and the marker paragraph no longer say "owed".
- **§3 summary line** "(d) — the register, §2 (R1, R2, R3)" → "(R1, R2, R3,
  R5; R6 proposed, not admitted)".
- **VALIDATION §0** gains a dated [AGENT] pointer note to operator item O-3
  (§2.3); the ruling text is untouched.

Gates (comment/doc-only code change; rebuilt from `make lean-prelude-src`):

```
build: Build completed successfully (395 jobs).
./scripts/test_unit.sh rc=0
Done: 292 passed, 0 failed
Total: 16 passed, 0 failed
check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=41 UNKNOWN=21; every row sealed; tally line consistent)
```

## 5. Final battery — Tier A in full + immaculate + the upstream-oracle gate

Run serially on head `19e706bd3` (the task-4 commit; this section is the
only change after it), `CERB_MEM_MAX=32G`, every command from the repo root
through `scripts/ce`; 2026-10-03T06:35:54Z → 06:53:47Z. Per-command status
lines (verbatim from the runner's summary):

```
### ./scripts/test_unit.sh rc=0 (289s)
### ./scripts/test_exec.sh --check-baseline rc=0 (37s)
### ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage rc=0 (81s)
### ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug rc=0 (30s)
### ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float rc=0 (33s)
### ./scripts/test_bytes.sh rc=0 (3s)
### ./scripts/test_libc_exec.sh rc=0 (127s)
### ./scripts/test_multi_tu.sh rc=0 (5s)
### ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray rc=0 (4s)
### ./scripts/test_parse.sh rc=0 (12s)
### ./scripts/test_core.sh rc=0 (11s)
### ./scripts/test_elab.sh rc=0 (22s)
### ./scripts/test_libxml2_uri.sh rc=0 (25s)
### ./scripts/test_cn_coverage.sh --check-baseline rc=0 (65s)
### ./scripts/test_address_space.sh --selftest rc=0 (6s)
### ./scripts/test_address_space.sh rc=0 (6s)
### python3 scripts/test_memory_access.py rc=0 (3s)
### ./scripts/test_immaculate.sh rc=0 (134s)
### python3 scripts/test_upstream_oracle.py rc=0 (177s)
### python3 scripts/test_upstream_oracle.py --plant rc=0 (3s)
```

Verdict lines (verbatim, from each log):

```
Done: 292 passed, 0 failed
Total: 16 passed, 0 failed
check_failure_reach: OK (234 pure failure sites = the 234 register rows exactly (232 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=41 UNKNOWN=21; every row sealed; tally line consistent)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 matches lem -v lean-backend-v0.1.0-alpha.1-20-g77ad4fa (hex prefix))
check_pin_sites: OK — lem-pin 77ad4facfc60814a4a3f5d09dc88168ca208b285 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=276 match=224 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
SUMMARY: match=43 diff=0
ALL MATCH RECORDED BASELINE
SUMMARY: total=8 match=8 fail=0
ALL PASSED
SUMMARY: total=7 match=7 fail=0
ALL PASSED
Lean parse:     113 ok, 0 failed, 0 timeout (>60s; fatal), 0 lean failure(s) (crash / nonzero exit without a printed verdict; fatal)
ALL PASSED
Total:          113
ALL PASSED
SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0
[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
Agreement tally: 213/213 compared (213 run, 0 oracle-side unobservable)
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
BASELINE OK (213 entries, exact match)
test_address_space: SELFTEST OK (14 plants — P1 the discriminator's derived pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
PASS memory access: 3 runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
Independent oracle: passed; {'semantic_agreement': 950, 'matching_failure': 37, 'reviewed_difference': 7, 'interface_agreement': 2}; .tmp/upstream-oracle-vb3ong5z/report.json
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; .tmp/upstream-oracle-nxhrt_hb/report.json
```

(The address-space SELFTEST line is cut at 200 characters here; the rest
of it lists plants P12–P14.) The pristine-oracle gate classifies this
branch's new and moved fixtures (verbatim):

```
920/996 semantic_agreement: immaculate/nolibc/zd-ta-alignas-2p61-control (pristine 0.0s, fork 0.0s)
921/996 matching_failure: immaculate/nolibc/zd-ta-alignas-huge-desugar (pristine 0.0s, fork 0.0s)
922/996 matching_failure: immaculate/nolibc/zd-ta-alignas-huge-sizeof (pristine 0.0s, fork 0.0s)
923/996 matching_failure: immaculate/nolibc/zd-ta-alignas-huge-union-alignof (pristine 0.0s, fork 0.0s)
926/996 matching_failure: immaculate/nolibc/zd-z2m01-aligned-alloc-zero-nolibc (pristine 0.0s, fork 0.0s)
959/996 matching_failure: immaculate/libc/zd-z2m01-aligned-alloc-zero-zero (pristine 0.3s, fork 0.2s)
960/996 matching_failure: immaculate/libc/zd-z2m01-aligned-alloc-zero (pristine 0.3s, fork 0.2s)
```

i.e. PRISTINE upstream fails on them exactly as the fork does — the crash
being mirrored is upstream's own, not a fork artifact.

No lane row moved beyond the witnesses named in §1/§2 (the immaculate and
gcc-ledger movements are exactly the hand-edits recorded there).

Not run here: the rest of Tier B (libxml2 chvalid, parse/core over
`tests/ci`, verify, speclab, the full gcc lane, the plant batteries,
`test_observation_lanes.py`, the chvalid pristine row). The full gcc lane is
the one Tier B lane whose ledger this branch edits; its edits were checked
by the partial runs of §1 and §2 only.

## 6. Provenance

All decisions in this record are [AGENT] (the worker on this branch) unless
quoted as [USER]. The direction to mirror Z2-M-01, run the sweep, document
`--address-space-top` and do the register bookkeeping came from the
orchestrator's brief, which quotes the [USER 2026-10-03] and [USER
2026-09-30] rules verbatim; the brief is not itself a [USER] ruling.
Scratch probes and gate logs lived in the worktree's `.tmp/` and were
deleted after this record was committed.

## 7. Rework after the pre-merge audit — the alignment sites become ISO-fix register R7

Audit: `docs/2026-10-03_total-arith-pre-merge-audit.md` (cherry-picked from
`audit/total-arith-20261003` 583d11b1e). Operator rulings, verbatim as
relayed by the orchestrator:

- O-3 synthesis, [USER 2026-10-03] "(1) agree with this", on: where
  upstream's OWN semantics defines the answer and only OCaml's machinery
  crashes on the way (a host artifact), Lean computes that answer (the R3
  treatment); where no answer is defined, or Lean's "answer" was garbage,
  Lean makes a loud stop mirroring the crash.
- R6, [USER 2026-10-03] "(2) yes this is the canonical 'obviously a mistake,
  no semantic ambiguity, just fix'": floatMul stays real multiplication, R6
  ADMITTED.
- F1, [USER 2026-10-03] "Yes, I agree with this analysis. Go ahead", on the
  orchestrator's recommendation: classify the alignment-overflow cases (S-1,
  S-2) as R3-style; Lean COMPUTES the unbounded answer and the oracle's crash
  is a registered host-artifact difference. The remainder/division-by-zero
  stops STAY (no answer is defined).

### 7.1 What changed

- §2.1's S-1/S-2 code is reverted: `CerbMem.alignofMemberRead`,
  `CerberusImpl.zToInt`, `ocamlMinInt`/`ocamlMaxInt` are deleted (`zToInt`
  had no other caller, so audit F2's docstring finding is moot); the
  alignof folds and `CerberusImpl.alignof_ty` read the unbounded `Nat`
  again, now carrying `-- ISO-fix register R7` markers with the cites; the
  measure proof's `hcong` is back to its original statement; the Z2-M-11
  note records the reachable huge-`_Alignas` case as R7.
- VALIDATION §2 gains **R7** (ADMITTED, rulings cited). Why a NEW row rather
  than an extension of R3 [AGENT]: R3 is one site (memcmp) with its own tray
  (13) and pin and retires when upstream fixes that site; the alignment
  sites are three other lines in two files with their own pins and their own
  ruling (F1). Only the class is shared, and the row says so.
- Failure-reach register: the `CerberusImpl.zToInt` row is gone (stale
  site); `--emit` showed only that removal; resealed (`sites=233 …
  REACHABLE=40`).

### 7.2 Value verification — each former Lean value is upstream's unbounded answer

Probes, both engines, nolibc (`--exec --batch --nolibc` vs Lean `--batch
--first`), on the restored build:

```
v1   struct s { char c; _Alignas(2^62) char x; };  return sizeof(struct s) == 0x8000000000000000UL;
     ORACLE rc=125 Z.Overflow | LEAN rc=0 Specified(1)
v1b  … return offsetof(struct s, x) == 0x4000000000000000UL;
     ORACLE rc=0 Specified(1) | LEAN rc=0 Specified(1)
v1c  unsigned long z = 0x8000000000000000UL; return (int)z;
     ORACLE rc=0 Specified(0) | LEAN rc=0 Specified(0)
v2   union u { char c; _Alignas(2^62) char x; };   return _Alignof(union u) == 0x4000000000000000UL;
     ORACLE rc=125 Z.Overflow | LEAN rc=0 Specified(1)
v2b  … return sizeof(union u) == 0x4000000000000000UL;
     ORACLE rc=0 Specified(1) | LEAN rc=0 Specified(1)
v2c  unsigned long z = 0x4000000000000000UL; return (int)z;
     ORACLE rc=0 Specified(0) | LEAN rc=0 Specified(0)
v3c  struct s { _Alignas(16) char x; }; _Alignas(8) struct s g;
     ORACLE rc=1 v3c.c:2:22: error: constraint violation: alignment specifier less strict than the declaration type 'struct s'
     LEAN   rc=1 Error {msg: "desugaring failed at v3c.c:2:22-23"}
v3   struct s { _Alignas(2^62) char x; }; _Alignas(2^62) struct s g;
     ORACLE rc=125 Z.Overflow (raised in Ocaml_implementation.alignof, ocaml_implementation.ml:496 fork = :483 upstream, via Cabs_to_ail.desugar_alignment_specifiers)
     LEAN   rc=1 Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
v3b  as v3 with 0x1000:  return (int)(((unsigned long)&g) % 0x1000);
     ORACLE rc=0 Specified(0) | LEAN rc=0 Specified(0)
```

Arithmetic (upstream's own layout rules, `impl_mem.ml:108-127` offsetsof,
`:162-171` struct sizeof, `:228-271` alignof, all in unbounded `Z`):

- **`zd-ta-alignas-huge-sizeof` → `Specified(0)`.** `c` at offset 0, size 1.
  `x`: align 2^62, `1 mod 2^62 = 1`, pad `2^62 − 1`, offset 2^62 (v1b — the
  oracle itself computes this, offsetsof keeps the `Z`); `maxoffset = 2^62 +
  1`. Struct alignment = max(1, 2^62) = 2^62. `(2^62 + 1) mod 2^62 = 1`, so
  sizeof = `2^62 + 1 + (2^62 − 1) = 2^63` (v1, Lean 1). `(int)` of a
  `size_t` 2^63: the conversion wraps modulo 2^32 on both engines (v1c:
  oracle and Lean 0 for the same value without any alignment): `2^63 mod
  2^32 = 0`. So `Specified(0)` is the unbounded answer — not a garbage
  wrap of a Lean-only value.
- **`zd-ta-alignas-huge-union-alignof` → `Specified(0)`.** alignof(union) =
  max(alignof char = 1, 2^62) = 2^62 (v2, Lean 1; v2b: the oracle's own
  union sizeof, which keeps the `Z`, rounds the size 1 up to that same
  2^62). `(int)` 2^62 = `2^62 mod 2^32` = 0 (v2c, both engines).
- **`zd-ta-alignas-huge-desugar`.** The program CHANGED. The old program
  (`_Alignas(8) struct s g;`) gave Lean `Error {msg: "desugaring failed at
  <path>:8:22-23"}`; that IS the unbounded answer — declared alignment 2^62
  > 8 is the §6.7.5 less-strict-alignment constraint violation, the oracle's
  own class and location for the in-range analogue (v3c: oracle "constraint
  violation: alignment specifier less strict…" at 2:22, Lean the desugaring
  failure at 2:22-23) — but its token embeds the absolute path of the input
  the lane passes, so it cannot be pinned portably in a lane run from any
  worktree. The new program (`_Alignas(2^62) struct s g;`) reaches the same
  overflowing read on the oracle (v3, same desugarer frame) and has a
  path-free unbounded answer: alignment 2^62 is not less strict than 2^62 →
  accepted; `g` has sizeof 2^62 (one byte rounded up to its alignment) and
  alignment 2^62; the allocator's cursor starts at the default top `2^48 − 1`
  < 2^62, so `z = top − 2^62 < 0` → the out-of-memory kill
  (`impl_mem.ml:1252-1256`). The in-range analogue v3b agrees on both
  engines.
- Control `zd-ta-alignas-2p61-control` (2^61): MATCH `Specified(4)` on both
  (sizeof = 2^62, `>> 60` = 4), before and after.

No site kept a stop: every former Lean value is the unbounded answer.

### 7.3 Pins (hand-edited)

- `tests/immaculate/baseline.txt`: `zd-ta-alignas-huge-sizeof` and
  `-union-alignof` `MATCH | L=CRASH` → `ORACLE_CRASH | L=VAL:{value:
  "Specified(0)", stdout: "", stderr: "", blocked: "false"}`;
  `-desugar` → `ORACLE_CRASH | L=ERR:{msg: "MerrOther "Concrete.allocator:
  failed (out of memory)""}`. Header note and `--record` template replaced
  together (dated, rulings cited); the lane's OK line now names R7.
- Fixture header comments rewritten; the desugar fixture's program changed
  as above.
- `scripts/gcc_oracle_baseline.txt` (partial `--write-baseline` over
  `tests/immaculate/nolibc`, rc 0, `gcc second-oracle lane OK`, 65 rows):
  `-sizeof`/`-union-alignof` `SKIP_LEAN_CRASH` → `SKIP_GCC_COMPILE`;
  `-desugar` → `SKIP_LEAN_FAIL`; dated header note.

### 7.4 Gates (this step)

```
build: Build completed successfully (395 jobs).
./scripts/test_unit.sh rc=0
Done: 292 passed, 0 failed
Total: 16 passed, 0 failed
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=172 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
./scripts/test_immaculate.sh rc=0
  ORACLE_CRASH   zd-ta-alignas-huge-desugar  O[CRASH] L[ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}]
  ORACLE_CRASH   zd-ta-alignas-huge-sizeof  O[CRASH] L[VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
  ORACLE_CRASH   zd-ta-alignas-huge-union-alignof  O[CRASH] L[VAL:{value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}]
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash-digit9 ORACLE_CRASH, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF, R7 zd-ta-alignas-huge-{sizeof,union-alignof,desugar} ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

## 8. Addendum 2026-10-03 — R6 admitted; audit F2–F6 (supersedes §4's "PROPOSED" wording; §4 is left as history)

- **R6 ADMITTED**: [USER 2026-10-03] "(2) yes this is the canonical
  'obviously a mistake, no semantic ambiguity, just fix'". `CerbFloat.floatMul`
  stays real multiplication; its docstring and marker, the VALIDATION §2 row
  (label and status), the marker paragraph and the §3 "(d)" line (now
  "(R1, R2, R3, R5, R6, R7)") say ADMITTED.
- **F2** (`zToInt` docstring): moot — `zToInt` was deleted in §7 (no caller
  left).
- **F4**: the `IntExp` negative-exponent comment and message tail no longer
  speak of a "KIND-2 … NOT mirrored … not the referent" artifact; they cite
  the synthesis (no answer defined → stop). The message's first 60
  characters (the failure-reach register key) are unchanged; the register
  gate stays OK without a reseal. `tests/z2-probes/README.md` gains a
  SUPERSEDED pointer at the stale "stay ORACLE_CRASH as PENDING rows"
  sentence; tray draft 34's provenance paragraph says the port now mirrors
  the crash.
- **O-3**: marked RESOLVED in §2.3; VALIDATION §0's [AGENT] pointer note is
  replaced by the 2026-10-03 rule (verbatim) and the synthesis (verbatim),
  next to the 2026-09-03 referent ruling.
- **F6**: the gcc ledger row `tests/immaculate/nolibc/zd-invalid-format-utf8-payload.c
  SKIP_UB -` added at the measured status (partial run of §7.3:
  `[56/65] SKIP_UB  tests/immaculate/nolibc/zd-invalid-format-utf8-payload.c:
  (UB:{ub: "Invalid_format[caf\195\169 %y]", stderr: "", loc: "<6:18--6:45>"})`).
- **F5** (the uneven guarding of unreachable sites: `integerDiv_t` has the
  zero guard, the layout family's `% 0` does not): left as is, as directed;
  both are unreachable (U-1, U-10).
