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
