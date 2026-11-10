# The cerberus-lean contract

Status: **adopted 2026-09-29**; the operator decisions are in §5. Author: the orchestrator [AGENT], on the
[USER 2026-09-28] direction that the correct fix is to define much more explicitly the contract cerberus-lean is
trying to establish, then make sure the well-built features are supported and the poorly-built ones are
appropriately rejected. Occasion: the CerbFS path defect
(`docs/2026-09-28_cerbfs-path-hotfix-record.md`), a SERVED wrong answer in a surface the project never tried to
clone, with no discrepancy found in the core semantics.

## 1. What cerberus-lean promises

cerberus-lean is a Lean 4 artifact that is meant to mean **what the Cerberus OCaml implementation means**, for a
declared set of C programs and a declared configuration. Concretely, for every input, an execution ends in exactly one of:

1. **The same observable verdict as the oracle** — value, stdout, stderr, the UB it reports — under the documented
   observation comparison (VALIDATION §4); or
2. **A loud refusal** — a nonzero exit and a message that names the unsupported feature and the boundary it belongs to;
   or
3. **A resource outcome** — fuel exhaustion or a declared resource limit, never counted as agreement (class (b)); or
4. **A registered deviation** — one of the few [USER]-ruled ISO fixes (class (d)), a [USER]-ruled named deviation where
   the mismatch cannot easily be resolved (class (e), VALIDATION §2b), or a failure whose message text alone differs
   (class (a)).

There is no fifth outcome. **A different answer, or a silent absorption (a default, an errno, a zero, a success no-op),
where the oracle answers, is a defect by definition** — wherever in the tree it occurs, supported area or not. The
pathleak bug was a fifth outcome.

The outcome protocol reports stop metadata within these four outcomes; it does
not add another permitted result. Migrated refusals expose `REFUSAL`, migrated
hand-written mirrors expose `UPSTREAM_CRASH` with pinned upstream attribution,
and port guards expose `INVARIANT` (a defect, even when the oracle crashes).
Generated envelope-less panics and the unmigrated D11/D12/D13/D16 refusal sites (the
shared desugarer's union-initializer and anonymous-member `error`s, the shared
elaborator's compound-assignment `error` and the shared formatter's five `error` classes
of D16) remain
legacy, origin unattributed: their refusal semantics are unchanged, but the
generic decoder cannot attribute them as REFUSAL; the
[migration map](docs/2026-10-20_outcome-protocol-register-migration.tsv) names
the shared-desugarer mapping mover. The two D10 memory-model refusals expose
REFUSAL with boundary `memory` since 2026-10-26 (quotation hygiene Q3, the
design-v2 §10 amendment), and the libc transport refusals boundary `libc`. Exit codes
alone do not establish these classes or prove shared origin. The first-delivery
[family table and consumer API](docs/2026-10-20_consumer-note-cerberus-caesium-outcome-protocol.md)
state the precise scope.

Collection completeness covers complete **emitted** records only. A pure abort
can discard earlier typed stops during exhaustive exploration before printing;
the constant-expression mini-run can also replace typed metadata with a legacy
panic. ModelFailure's location sentinel is not an authenticated origin tag.
These stated limits remain with the named
[structural-outcome arc](docs/2026-09-16_lean-only-outcomes-implementation-plan.md),
including the queued pure-failure work; this diagnostic protocol does not repair
them or prove correspondence.

What the contract does NOT promise: ISO C conformance beyond the oracle's; agreement outside the declared configuration;
correctness of the oracle itself (the upstream tray records where we believe it is wrong); a proof of correspondence.
The evidence is differential testing on documented corpora plus kernel-checked local properties of the Lean artifact
(totality, axiom cone, fuel contracts); **testing samples behaviour and does not prove equivalence** (VALIDATION §9) —
which is exactly why every unmodelled surface must refuse rather than guess.

## 2. The declared configuration

Matched (default-switch) mode of the oracle at the fork merge-base `c3ff8c53f` (stage 1 of the merge-base bump, 2026-10-30; `b9aeedcb4` before); sequential execution; the concrete
memory model; LP64; `--nolibc` and libc modes as exercised by the lanes; explicit `--fuel` and address-space parameters.
**Semantics switches: PNVI_ae_udi supported, matched against the oracle under the same switch; every other switch
refused.** The switch set is a parameter of the semantics (`[CerbGlobal.Switches]`, PNVI arc S1, 2026-10-05). The binary
supplies the default `[]` unless `--switches=PNVI_ae_udi` is given (PNVI arc S4, 2026-10-07): then `[PNVI_ae_udi]`, and §1
applies with the oracle run under the SAME switch (`scripts/test_pnvi.sh`, LADDER Tier A row 14). Every other
`--switches` value — another switch name, plain `PNVI`/`PNVI_ae`, a mixed list, an override (R-PNVI-11), an unknown name
(R-PNVI-12) — and `--iso` is refused at the CLI (`Main.lean` `judgeSwitches`/`refuseSwitches`, per element; `refuseFlag`),
including where the oracle silently ignores the name. Inside the PNVI-ae-udi semantics, the upstream arms that crash,
print debug output or call themselves wrong are refused (§3, the R-PNVI rows); the default set is unchanged by all of
this.

**The address-space top: the default is the promise; other values are a proof-use parameter.** `--address-space-top N`
is a DELIBERATE lift of upstream's constant for proof use — [USER 2026-10-03] ruled that the address-space-top
restriction is lifted specifically so that Cerberus can be treated as a proof artifact, accepted the recommendations
under that framing, and ruled that work enabling the Iris reasoning is not reverted. Its default mirrors upstream
exactly (`memory/concrete/impl_mem.ml` `last_address= Z.of_int 0xFFFFFFFFFFFF; (* TODO: this is a random impl-def
choice *)`, `Main.lean` `defaultAddressSpaceTop`), and §1 is promised at that default only. A NON-DEFAULT value is
outside the mirroring promise: pristine upstream has no such parameter, so there is nothing to mirror; the fork oracle's
own fork-only flag is an instrument (the tiny-top lane, LADDER A12), not the referent; and at very large tops (≥ 2^62)
objects become allocatable whose sizes OCaml's `Z.to_int` cannot represent, where the fork oracle would raise and Lean
computes (`docs/2026-10-03_total-arith-and-bookkeeping-record.md` §2.3 O-1). The fork's other memory models accept the
fork-only flag and IGNORE it (`memory/symbolic/impl_mem.ml` `initial_mem_state (_address_space_top: Z.t)`,
`memory/cheri-coq/impl_mem.ml` likewise) — those models exist on the fork oracle only (separate executables:
`cerberus-cheri`; the symbolic driver is commented out of `backend/driver/dune`); cerberus-lean has the concrete model
alone, and any model-selecting flag is an unknown flag, refused (exit 2, zero-discrepancy Z-24).

**Exhaustive mode is the promise; `--first` is outside it.** In the default (exhaustive) mode Lean explores every
nondeterministic branch, as the oracle's `--mode=exhaustive` does, and §1 applies to the whole verdict set. `--first`
follows only the first branch (`CerbND.runND1Fuel`), where the oracle's `--mode=random` draws branches from a
time-seeded generator: the two can serve different members of the same exhaustive set on a program whose result
depends on evaluation order. `--first` is a harness convenience (the libc_exec and libxml2 lanes use it, and are sound
only for programs whose result does not depend on the trace), not part of the §1 promise.

## 3. Feature areas and their states

Three states only: **SUPPORTED** (differentially validated; any disagreement is a bug), **REFUSED** (loud,
feature-attributed; each refusal has a witness), **OUT OF SCOPE** (not an input the artifact accepts at all).

| Area | State | Evidence / refusal witness | Open questions |
|---|---|---|---|
| C frontend (parse → Cabs → Ail → Core) | SUPPORTED | shared OCaml parser; Lean desugar/typing/elaboration differentially tested (row 1 parser tests, all Tier A/B lanes) | frontend is `partial` (not kernel-evaluable) — a stated limit, not a discrepancy |
| Inline assembly (GNU `asm`/`__asm__`: basic, extended, `asm goto`, asm labels on declarators) | **REFUSED** (D9) in both engines, where upstream silently erases it: an asm statement fails desugaring in the shared `.lem` (`feature not yet supported: inline assembly (asm statement) is unsupported`; Lean `--batch` reports `desugaring failed at` the asm location), an asm label on a declarator fails in the shared parser (`unimplemented keyword 'asm (inline assembly label on a declarator is unsupported)'`), so no Cabs reaches the Lean engine | `scripts/check_asm_refusal.sh` (row 1): 4 statement + 3 label witnesses, 2 controls, 3 plants | file-scope `asm(...)` is not in the grammar: a syntax error (loud, not attributed); `__asm` (no trailing underscores) is an ordinary identifier |
| Two upstream TODOs of the concrete memory model, item G (cerberus-caesium's note 2): `memcpy` on overlapping objects (C17 7.24.2.1#2 undefined; upstream's `impl_mem.ml` `memcpy` carries `(* TODO: if ptrval1 and ptrval2 overlap ==> UB *)` and copies byte-wise, tray 56) and an allocation with an invalid alignment (not a positive power of two; C17 7.22.3.1#2-3; upstream's `std.core:385` `aligned_alloc_proxy` checks only `size rem_t align = 0` and the allocator rounds to any alignment, tray 57) | **REFUSED** (D10) in both engines, where upstream answers a defined value: the memory model's `memcpy` (oracle `failwith`, Lean `CerbMem.memcpyM` `failwithI`) and its `allocator` (oracle `failwith`, Lean `CerbMem.allocator`) die with ONE text. The copy is refused when both pointers are concrete in the same allocation (`Prov_some`), or both are device-memory pointers (`Prov_device`, the fixed `device_ranges` an integer cast reaches — the pre-merge audit's P2-1), and the byte ranges intersect; the remaining pointer shapes cannot complete a copy (`Prov_none` fails at the first byte, `Prov_symbolic` dies in the pure `array_shift_ptrval`, `PVnull`/`PVfunction` fail in `load`; the audit's probes), except one named residual: an allocation/device pair, reachable only when an allocation lies inside a device range, i.e. under the fork-only `--address-space-top` (outside §2's promise), which both engines still serve (record §2: without the allocation's bounds, which `memcpy` does not consult, it cannot be told from an out-of-bounds run into device memory). The refusal fires before any access check, so an overlapping copy of a dead or out-of-bounds object is refused, not reported as that UB — `Concrete.memcpy: refused - memcpy on overlapping objects (…)` / `Concrete.allocator: refused - allocation with an invalid alignment N (…)`, each naming the clause, upstream's TODO/line and that the fork refuses rather than decides; oracle uncaught `Failure`, exit 125; Lean abort under `LEAN_ABORT_ON_PANIC=1`, exit 134 | `scripts/check_item_g_refusals.sh` (row 1): 6 overlapping-memcpy + 3 invalid-alignment witnesses with the two engines' texts compared byte for byte (the Lean text decoded from its REFUSAL envelope), 9 controls (incl. one allocation at each alignment the lanes use) + the unchanged zero-alignment crash, 5 plants | alignment zero stays the pre-existing `Division_by_zero` crash (tray 34, out of scope); since 2026-10-26 (quotation hygiene Q3, design-v2 §10 amendment) the Lean texts travel as REFUSAL envelopes — boundary `memory`, item `Concrete.memcpy` / `Concrete.allocator`, detail `Refused: ` + the oracle's text, `upstream` citing the TODO — on the panic channel; the oracle's `Failure` text is unchanged |
| Union initializers whose member designator names a member other than the first, item U (tray 59 (a)): upstream's live initializer desugarer `desugaring_init.lem` `constructValue_aux` builds EVERY braced union initializer as the FIRST member whatever the designators say (its own `TODO: this is only correct if the first member was the one initialised` and level-0 print `constructValue_aux: is WRONG for union ==> always assigning the first member`; the init-map key `Elem_union` carries no member identity), so `union U { int i; unsigned char c[4]; } u = { .c = {1,2,3,4} }` answered 0 on both engines where gcc gives 104 | **REFUSED** (D11) in both engines, in the SHARED desugarer's `moveTo_aux` Union arm — the one place the designated member is decidable — when a member designator on a union names a non-first member: at any depth, any storage class, arrays of unions, nested unions, compound literals, a union inside a struct; the text names the union, the designator and the first member, C17 6.7.9#17-19, upstream's TODO and print, and that the fork refuses rather than decides — `Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first (union U: designator .c, first member i); …`; oracle `Cerb_debug.error` (`internal error: <text>` + uncaught `Failure`, exit 125); Lean `failwithI` (abort under `LEAN_ABORT_ON_PANIC=1`, exit 134), the texts byte-identical. Positional and first-member-designated initializers (incl. mixing with the first member only, `{ 9, .a = 2 }` → 2), `{ 0 }` on a smaller first member (read back as Unspecified, both engines) and a union inside a struct initialised positionally or at its first member are UNCHANGED and agree with the oracle; the anonymous-union-in-struct path, which this refusal never reached (upstream splices the anonymous union's members into the enclosing struct), is REFUSED since 2026-10-26 by D12 at the member's declaration | `scripts/check_union_init_refusals.sh` (row 1): 14 witnesses with the two engines' texts compared byte for byte, 11 controls (the anonymous-union control retired 2026-10-26, its shape a D12 witness), 1 gap control (the struct-from-struct-variable rejection unchanged on both), 5 plants | tray 59 (b) stays as upstream has it: a struct/union VALUE as a member initializer and a designated union compound literal in the initializer position are constraint violations on both engines (gcc accepts); tray 59 (c), the flattened anonymous union, is D12's class |
| Anonymous struct/union members, the upstream-uncertainty survey's cluster A (tray 60): a struct-declaration with no declarator whose type specifier is a tagless struct/union (C17 6.7.2.1#13) — upstream's `desugar_struct_declaration` (cabs_to_ail.lem; pristine b9aeedcb4 :2697) splices the anonymous member's members flat into the containing aggregate's member list, under its own `this may be WRONG ==> anonymous Struct/Union` prints, so the member loses its own storage: wrong `sizeof`/offsets (`struct S { union { int b; char c; }; }` is 8, gcc 4), no aliasing between an anonymous union's members, brace-elided initializers one slot late (`{1, 2, 3}` over `int a; union { int b; char c; }; int d;` gives a=1, c=2... d=0), false UB081/UB036/pointer-equality verdicts — 25 silent-wrong probes, both engines and pristine agreeing; designated initializers naming the members were the one shape that answered right, by name lookup alone | **REFUSED** (D12) in both engines, in the SHARED desugarer's `desugar_struct_declaration` at the member's DECLARATION (whether or not the type is ever used; nested members refuse at the innermost; a typedef'd tagless specifier used bare, block scope, compound literals, `_Alignas` all refuse): a Lem `error` with one text naming the member's kind, C17 6.7.2.1#13, upstream's splice site and doubt, and that the fork refuses rather than decides — `Cabs_to_ail.desugar_struct_declaration: refused - anonymous union member (a struct-declaration with no declarator whose type specifier is a tagless union; C17 6.7.2.1#13); upstream splices its members into the containing aggregate's member list (…) - the fork refuses rather than decides (survey cluster A, tray 60, 2026-10-26)`; oracle `Cerb_debug.error` (`internal error: <text>` + uncaught `Failure`, exit 125); Lean `failwithI` (abort under `LEAN_ABORT_ON_PANIC=1`, exit 134), the texts byte-identical. The same shapes with NAMED members (`union { … } u;`, a named struct inside a struct, a tagless type WITH a declarator, a tagless file-scope object) are UNCHANGED and agree with the oracle; a TAGGED struct without a declarator, a typedef'd tagged specifier and `int;` stay the pre-existing 6.7.2.1#2 constraint violation | `scripts/check_anonymous_members_refusal.sh` (row 1): 29 witnesses, each pinning its WHOLE text (kind word included) on both engines and comparing them byte for byte, 10 named-member controls, 3 gap controls, 5 plants | a refusal, not an implementation: an anonymous member with its own storage and member-path lookup through it is upstream's feature to build (tray 60 asks for it); every `union { … };` inside a struct — kernel-style C — now refuses, which is the point; both texts remain envelope-less at this delivery (legacy stop under the outcome protocol, as D10/D11) |
| Compound assignment whose LEFT operand contains a side effect, the upstream-uncertainty survey's cluster B (tray 61): upstream's `AilEcompoundAssign` arm (translation.lem; pristine b9aeedcb4 :2505-2531, under its own `TODO: this elaboration is wrong because it duplicates any side-effect in E1` :2506) rewrites `E1 op= E2` to `E1 = E1 op E2` and elaborates `E1` twice, so an increment, a call or a comma inside the lvalue runs twice: `a[g()] += 4` calls `g` twice (24, gcc 14), `*g() += 3` likewise, and `a[i++] += 5`, `*p++ += 7`, `a[--i] += 6`, `(p++)->v += 5`, `a[(n++, 0)] += 3` are reported as `UB035_unsequenced_race` (false: C17 6.5.16#3 sequences the update after both value computations, 6.5.16.2#3 evaluates the lvalue once) — 9 silent-wrong probes, both engines and pristine agreeing; a side effect in the RIGHT operand is evaluated once, plain `=` is unaffected | **REFUSED** (D13) in both engines, in the SHARED elaborator's arm, when the syntactic walker `compound_assign_lhs_has_side_effect` finds anywhere inside `e1` a postfix `++`/`--`, an assignment, a compound assignment (the desugarer's form of a prefix `++`/`--`), a comma, a call (pure or not — the second copy calls it again), an assert, a `va_*` builtin, a GNU statement expression or a compound literal (a `_Generic`'s controlling expression and every association, selected or not, are walked though C evaluates only the selected association; a `sizeof` operand does not survive typing): a Lem `error` with one text carrying the location prefix of the translation layer's `record_error_at` rendering (`<file>:<line>:<col>:: `, the cursor on the operator) — `Translation.translate_expression: refused - compound assignment whose left operand contains a side effect (an increment or decrement, an assignment, a function call, a comma, a va_arg, a statement expression or a compound literal anywhere inside the lvalue; C17 6.5.16#3 sequences the update after both value computations and 6.5.16.2#3 evaluates the lvalue E1 only once); upstream elaborates E1 op= E2 as E1 = E1 op E2 with E1 elaborated twice, under its own 'TODO: this elaboration is wrong because it duplicates any side-effect in E1' (translation.lem b9aeedcb4 :2506), so the lvalue's side effect runs twice (a call in the lvalue is called twice, a wrong value) or a false UB035_unsequenced_race is reported (the ++/--/comma forms) - the fork refuses rather than decides (survey cluster B, tray 61, 2026-10-29)`; oracle `Cerb_debug.error` (`internal error: <text>` + uncaught `Failure`, exit 125); Lean `failwithI` (abort under `LEAN_ABORT_ON_PANIC=1`, exit 134), the texts byte-identical. NOT counted, a declared under-approximation against C17 5.1.2.3#2: a read of a VOLATILE object inside the lvalue's address computation (`volatile int i; a[i] += 2` loads `i` twice; Cerberus gives `volatile` no semantics beyond the qualifier, the second read is value-identical and verdict-neutral; the volatile object itself, `v += 2`, is loaded once by the rvalue copy and stored once). A side effect in the right operand only, plain `=` and `++` on a post-incremented subscript, `*p += 1`, `s.v |= 4`, `a[f] <<= 2`, a volatile object or subscript, a `sizeof` operand are UNCHANGED and agree with the oracle; the bit-field case stays the pre-existing `feature not yet supported: bit-fields` rejection | `scripts/check_compound_assignment_refusal.sh` (row 1): 18 witnesses, each pinning its WHOLE text (location included) on both engines and comparing them byte for byte, 11 controls, 1 gap control, 5 plants | a refusal, not an implementation: the one-binding elaboration (`let p = &E1 in *p = *p op E2`) is upstream's to adopt (tray 61 proposes it); every `*p++ |= x`, `buf[len++] += v`, `tbl[hash(k)] += 1` now refuses, which is the point; the stop is a pure `error`, not the neighbouring `?:` arm's `E.record_error_at`, because the constant-expression mini-run discards a recorded error (D13); the text remains envelope-less at this delivery (legacy stop under the outcome protocol, as D11/D12) |
| Formatted output — the `printf` family's conversion model (`frontend/model/formatted.lem`, the Core builtins `printf`/`vprintf`/`vsnprintf` run; the true-bug audit of 2026-11-04 rows 16, 26, 27 and §4 items 1, 3, 10): upstream's parser accepted only `%f` of the floating conversions and no `L` modifier, so a conforming `printf("%e", 3.5)` was reported as `Invalid_format` UB (a silently wrong verdict; tray 68); a `*` field width or precision, `%n`, `%ls` and `%lc` died with uncaught internal errors on conforming calls (tray 26); `%jd` of an `intmax_t` and `%zd`/`%tu` of the types 7.21.6.1#7 names were a false UB153b (the argument's type normalised through the alias table, the expected side not; tray 69); `snprintf` returned the truncated length, 0 without formatting at `n = 0`, and crashed on a format whose conversion reports UB (tray 16); the `0` flag padded in front of the sign and the `0x` base and over an infinity, `#` dropped `%f`'s decimal point (tray 70); a length modifier other than `l` with `%s` crashed | **REFUSED** (D16) in both engines by generation, one attributed text per class, the D11/D12/D13 form (a pure Lem `error`: oracle `internal error: <text>` + uncaught `Failure`, exit 125; Lean `failwithI`, abort 134; the texts byte-identical): every floating conversion other than `%f`/`%lf` and the `L` modifier (`Formatted.convert: refused - the %e conversion is not implemented (C17 7.21.6.1#8: …) … (upstream-tray report 68, 2026-11-07)`, the conversion named with its modifier), `%n`, `%ls` and `%lc` (`… refused - the %n conversion …` / `… the %ls conversion …` / `… the %lc conversion …`, tray 26), a `*` argument that is an unspecified value (`Formatted.printf_aux: refused - a * field width or precision whose int argument is an unspecified value …`), and a `%%` specification carrying a `*` width or precision (`%*%`: `Formatted.printf_aux: refused - a %% conversion specification carrying a * field width or precision (C17 7.21.6.1#8: 'The complete conversion specification shall be %%', so the form is undefined behaviour, 4#2); …` — 7.21.6.1#8 makes the form UB, upstream crashed on it, and the first version of this slice consumed the argument and padded, an invented value the pre-merge review's P2-1 struck); the parser accepts the full 7.21.6.1#7-#8 syntax, and a format that does not parse stays `Invalid_format` (7.21.6.1#9). **FIXED** (D16, fork-ahead deltas of the first kind) where the standard is explicit: a `*` width/precision is read from an `int` argument before the converted one (7.21.6.1#5: a negative width is the `-` flag and its magnitude, a negative precision is omitted; `UB153a` without an argument, `UB153b` when it is not an `int`); the `j`/`z`/`t` tests normalise the expected side through the alias table too, uniformly, in either signedness (upstream's `l`/`ll` laxity kept); `snprintf` returns the would-be length, formats at `n = 0` and passes a format's UB verdict through (7.21.6.5#2-#3); the `0` flag pads after the sign / base and spaces an infinity, `#` keeps `%f`'s point (7.21.6.1#6); a non-`l` modifier with `%s` is `UB158` (7.21.6.1#7). UNCHANGED, upstream's judgement: the strict 7.21.6.1#9 reading of `%x`/`%u`/`%d` with a wrong-signedness `int` argument and of a `long` for `%d` (tray 27), the `DUMMY` verdicts for `+` on an unsigned conversion and a modifier other than `l` on `%c`, the padded `%5%` (a literal width on `%%`, upstream's arm under its own TODO), the space flag applied to an unsigned conversion, the `%s`-of-a-non-pointer crash (UB input); `%f` of a NaN stays the Lean refusal; every other integer, character, string and `%f` conversion with its flags, widths, precisions and modifiers answers as before (= gcc) | `scripts/check_printf_refusals.sh`: row 1 runs its 32-program CORE (every refusal and fixed class once, the plants), Tier B row 15 (`--full`) the whole matrix — 161 programs in libc mode (4 nolibc controls) — 18 refusals pinned whole on both engines, 101 rows pinned to gcc 13's line on both engines, 3 to the fork's declared lines with gcc's beside, 38 UB rows with the verdict pinned and the location projected (N4), the NaN gap control; pristine `c3ff8c53f`'s lines the negative control (75 moved); 6 plants | a refusal, not an implementation, for the seven floating conversions, `L`, `%n` and the wide conversions (queued in TODO with a size); the refusal sites are envelope-less at this delivery (legacy stops under the outcome protocol, as D11/D12/D13); in libc mode a format UB is located inside the library's `vfprintf` on the oracle and at `<unknown location>` on Lean (N4, as D15); `%f` of `-0.0` prints `0.000000` on both engines — the sign is lost by the negation before the formatter (an arithmetic question, filed as a related finding of tray 70, not changed) |
| Core dynamics (driver, reduction, pure eval) | SUPPORTED | Tier A/B lanes, pristine 835/28/7/2, gcc oracle, csmith corpus | none known; this is where the report found nothing |
| Concrete memory model | SUPPORTED | CerbMem mirror with cites; immaculate lane; allocator soundness theorem | the SC receipt buffer is disabled by default (WP0) |
| Function pointers | SUPPORTED, including round trips through integers and `void*` (libc's `atexit` uses one); their numeric value — through an integer conversion, their bytes or `%p` — is named deviation N1 | `zd-funptr-*` rows, libc_exec `040`/`041` | none |
| Integer/float/layout implementation choices | SUPPORTED (LP64); printing a NaN with `%f` REFUSED (its text depends on the NaN's sign bit, which Lean cannot read); a NaN's sign and payload bits in memory are named deviation N2; float constants in the libc Lean loads are rounded to 12 digits in one place (named deviation N3) | CerberusImpl, CerbFloat, float/bytes lanes | other ABIs OUT OF SCOPE (D6) |
| libc (the oracle's libc.co, loaded) | functions written in C (`runtime/libc/src/*.c`): SUPPORTED — they run through the same Core semantics as user code — but thinly tested (§3.2); the 36 **builtins** of `runtime/libcore/std.core` (hand-implemented in each engine): one state each, §3.1 (D4) | libc_exec lane, libxml2 lanes | a UB raised inside a libc C body is reported at `<unknown location>` by Lean and at the libc source location by the oracle (VALIDATION §3, Z1-A1: an open bug with a named mover) |
| Filesystem (CerbFS) | **REFUSED** (D2) — every filesystem operation, including `read` on any fd; `write`/`vprintf` on fds 1/2 are served (the driver routes them to the stdout/stderr records, never reaching CerbFS) | `zd-fs-*`, `zd-f1-truncate-negative-length`, `zd-z2f01-lseek-whence` pinned refusals | none |
| Standard input / environment / argv | stdin REFUSED (every read reaches CerbFS, D2; the oracle models an empty stdin); `getenv` served by libc C code; argv SUPPORTED | `zd-fs-stdin-read` pinned refusal; argv lane (5 programs) | UTF-8 `--args` unmeasured |
| Concurrency (threads, atomics, Epar, C11 model) | REFUSED at the CLI flag; default-mode atomics and `{-{ ||| }-}` SUPPORTED as the oracle's sequential reading | `refuseFlag`; served-surface audit: 15 default-mode probes agree, `statically_satisfied` has no generated caller | none |
| Semantics switch `PNVI_ae_udi` (`--switches=PNVI_ae_udi`) | SUPPORTED (2026-10-07), matched against the oracle under the same switch | `scripts/test_pnvi.sh` (Tier A row 14): upstream's 44 PNVI litmus files exhaustive, `tests/minimal` under the switch, the pKVM census drivers; `check_cli_refusals.sh` (acceptance + one agreement witness) | the pKVM allocator drivers are compared in `--first` only (their exhaustive sets exceed the 4G cap on the oracle: outside §1, §2); the refused arms below |
| PNVI-ae-udi arms upstream itself leaves as crashes, debug prints or self-declared wrong code | **REFUSED** (class (c), [USER 2026-10-05]): `PNVI_ae_udi refusal (unsupported upstream arm): R-PNVI-nn: …`, exit 134. R-PNVI-01 `combine_prov` on a symbolic byte (impl_mem.ml:390-394; -01b `provs_of_bytes`, shadowed), -02 `find_overlaping`'s `assert false`, -03 its dropped third candidate, -04 `lookup_iota`'s `Not_found`, -05 `abst`'s "This is wrong" arm, -06 pure `array_shift_ptrval` on a symbolic pointer, -07 `case_ptrval` on a symbolic pointer, -08 `diff_ptrval`'s invariant failure, -10 the stdout-printing arm of `eff_array_shift_ptrval` | lane witnesses (`test_pnvi.sh`, each a registered `REFUSAL` row, never agreement): -01 by 4 upstream litmus files where the oracle crashes; -05 (`tests/pnvi_refusals/r05-…`, the oracle answers through the flagged arm), -06 (`r06-memcpy-symbolic-source.c`), -07 (`r07-call-through-symbolic-pointer.c`) where the oracle crashes; -01b, -02, -03, -04, -08, -10 by compile-time pins (`test/Unit/PnviArmsTest.lean`) — no C witness found. Reach: -01b, -02, -04 unreachable by invariant and -03 UNKNOWN (reviewed rows of `scripts/failure_reach_register.txt`); -08 and -10 are MONADIC sites (`pnviRefuseM` inside an `ND` body) outside that pure-site census, so their reach is UNREVIEWED (no register row; -10's arm is never taken on any litmus or pKVM trace, MEASURED, design §G R16 — a measurement, not a reach argument) | R-PNVI-09 (`eff_array_shift_ptrval`'s `PVfunction` arm) is a DEFAULT-path site and stays a mirrored fail-stop with the other default-path look-alikes (design §H.1), pending the queued default-path consistency review |
| Non-default memory models (symbolic, VIP, CHERI), every other switch (plain PNVI, PNVI_ae, strict reads, strict pointer arithmetic, …) and `--iso` | REFUSED at the CLI | `judgeSwitches` / `refuseSwitches` / `refuseFlag` (`check_cli_refusals.sh`), incl. R-PNVI-11 (an override in one list) and R-PNVI-12 (an unknown name), where the oracle ignores the name and runs on | none |
| Debug/pretty-print seams (CerbDebug, CerbPP) | OUT OF SCOPE for verdicts | no-op stubs; served-surface audit: no verdict path reads them | none |
| Core text (CoreParser) | SUPPORTED for the runtime's own Core files (`std.core`, the implementation file, the libc dump), which every run parses; no mode executes user-written Core text (`--parse-core` and `--pp-core` are diagnostics) | core-parser tests (292 checks); verify lane | none |

### 3.1 The builtin boundary (D4)

`runtime/libcore/std.core` declares 36 `builtin` procedures. Unlike libc's C functions, each is implemented by hand in
both engines, so each has its own state. The live stepper's fallback arm fails any builtin not handled here, in both
engines, so a builtin added upstream fails closed until it is reviewed and listed.

| Builtin(s) | State | Where / evidence |
|---|---|---|
| `printf`, `vprintf`, `vsnprintf` | SUPPORTED (`vprintf` to fds 1/2; other fds reach CerbFS and refuse) | generated `Formatted`; immaculate programs that print (measured: 11 files call printf), libc_exec, libxml2 |
| `exit` | SUPPORTED | generated `Core_reduction`; every lane's exit path |
| `errno` | SUPPORTED | generated `Core_reduction`; libc_exec |
| `generic_ffs`, `ctz`, `bswap16`, `bswap32`, `bswap64` | SUPPORTED | `CerbUtils` line mirrors of `ocaml_gcc_builtins.ml`; immaculate `g4-*` rows |
| `write` | SUPPORTED on fds 1/2; fd 0 fails in both engines; other fds REFUSED (CerbFS) | `driver.lem` routing |
| `read` | REFUSED (CerbFS, every fd) | D2 |
| `any_bounded_int` | NOT SERVED by either engine: both fail it (`core_reduction.lem:1012-1013`) | `zd-any-bounded-int-crash` pinned MATCH / both crash |
| `open`, `close`, `pread`, `pwrite`, `lseek`, `truncate`, `link`, `readlink`, `symlink`, `unlink`, `rename`, `rmdir`, `mkdir`, `stat`, `lstat`, `umask`, `chmod`, `chdir`, `chown`, `opendir`, `readdir`, `rewinddir`, `closedir` | REFUSED (D2) | `CerbFS` refusals; `zd-fs-*` rows |

### 3.2 How deeply each part is tested

SUPPORTED means "differentially tested, and any disagreement is a bug". It does not mean every part is tested equally.
The measurement behind this section is `docs/2026-09-28_test-depth-map.md` (static counts of the gated lane programs
that exercise each part; there is no coverage instrumentation, so the counts are proxies), re-counted after the
edge-case tests of `docs/2026-09-28_thin-surface-tests-record.md` and the four rows added with the fixes that followed
them. The gating lanes hold 972 programs that agree with the oracle (measured by the map's census script on the
range head; the two `%f`-of-a-NaN rows are refusal pins, not agreement).

**Deeply tested:** the C frontend and Core dynamics (generated from the same Lem source as the oracle), load/store and
allocation, integer and floating-point arithmetic (also checked against gcc as a second oracle), the exhaustive runner
and the batch output format. Every program exercises these.

**Less deeply tested — treat results here with more suspicion.** These are served, and a disagreement is still a bug,
but fewer gated programs exercise them, and most are hand-written Lean rather than shared generated code. Counts are
gated agreement programs, before → after the 2026-09-28 edge-case tests:

| Part | Programs | Depth now | Why it matters |
|---|---|---|---|
| libc breadth | 11 → 62 of the 188 libc functions called directly; libc mode 32 single-trace → 61 single-trace + 2 exhaustive | THIN | most libc functions are still called by no test, and libc mode is mostly compared single-trace |
| `printf("%f")` | 0 → 13 | MODERATE | `CerbFloat.formatFixed` is an independent reimplementation of glibc's `%f` |
| printf width, precision, flags; `%c`/`%x`/`%X`/`%o` | 0 → 22; 0/1/0/0 → 6/8/2/3 | MODERATE | formatting is shared code, `%c` goes through hand-written escaping |
| `realloc`, `memcpy`, `memcmp`, `memset` | 4/5/2/1 → 16/15/7/5 | MODERATE (`memcmp`, `memset` thin) | hand-written `CerbMem` routines |
| `snprintf`/`vsnprintf`, `errno`, `exit`, `atexit` | 2/1/1/0 → 6/5/4/2 | THIN | return values and status codes |
| argv | 5 | THIN | non-ASCII arguments fail in both engines (with different messages) |
| programs of several translation units | 8 → 14 | MODERATE | linking and cross-TU identity |
| default-mode atomics and `{-{ ||| }-}` | 1 | THIN | shared code, lower risk |
| `--first` mode | not checked to be one of the exhaustive results | outside §1 | outside the §1 promise (§2) |
| non-batch CLI output | never compared (only `--batch` output is the compared interface) | outside §1 | human-readable format, exits 0 for every outcome, as the oracle's does |

The **refused** parts (filesystem, stdin, concurrency and switch flags, the PNVI-ae-udi refusals, `%f` of a NaN, inline assembly, the item-G memory-model TODOs, union initializers designating a non-first member, anonymous struct/union members) are pinned by
witnesses and are not "thinly tested": they do not answer.

## 4. How the contract is enforced

1. **Every REFUSED area has at least one witness in a lane that pins the refusal**, so a return to a silent answer turns
   a gate red: the filesystem and stdin (`zd-fs-*`, `zd-f1-*`, `zd-z2f01-*` immaculate rows), `any_bounded_int` (`zd-any-bounded-int-crash`), `%f` of a NaN (`fmt-007*.unsupported.c`), the CLI flags (`scripts/check_cli_refusals.sh`,
   row 1), the PNVI-ae-udi refusals reachable from C (`scripts/test_pnvi.sh`'s `REFUSAL` rows, Tier A row 14, which
   assert the refusal id and the oracle side), inline assembly (`scripts/check_asm_refusal.sh`, row 1, which asserts the message too) and the
   item-G memory-model refusals (`scripts/check_item_g_refusals.sh`, row 1, which asserts the message on both engines and their equality) and the
   union-initializer refusal (`scripts/check_union_init_refusals.sh`, row 1, likewise) and the anonymous-member refusal
   (`scripts/check_anonymous_members_refusal.sh`, row 1, likewise — every witness pins its whole text on both engines) and the
   compound-assignment refusal (`scripts/check_compound_assignment_refusal.sh`, row 1, likewise, the location included).
   The one fork-ahead FIX (D14, not a refusal) has its own witness: `scripts/check_macro_type_ranks.sh` (row 1) pins gcc
   13's line on BOTH engines for 103 of 106 programs over the macro integer types' arithmetic (macro-versus-macro
   pairs included; 2 programs pin the fork's declared residuals, 1 the tray-62 crash), with pristine's pre-fix lines as
   the negative control, so a return to the narrowing turns the gate red.
   The second fork-ahead FIX (D15) has its own witness: `scripts/check_stdio_exit.sh` (row 1) pins ONE line on BOTH
   engines for 46 libc-mode programs over termination — 34 gcc 13's line, 6 the fork's declared line with gcc's beside
   it, a D2 gap control and five nolibc controls — with pristine's lines as the negative control (33 moved), so a return
   to the lost buffer, the skipped handlers or the proxy's ordering turns the gate red.
   The third fork-ahead FIX (D18, oracle-side only) has its own witness: `scripts/check_half_mirrors.sh` (row 1) pins
   ONE line on BOTH engines for 41 programs — 27 gcc 13's line (every byte 0..255 through the `snprintf` store, the
   `\?` escape in every literal form), 9 the fork's declared line with gcc's beside it (the `memcmp` neighbourhood's
   UB programs, one multi-character constant), 5 gap controls that still crash both engines — with pristine's lines
   as the negative control (18 moved), so a return to the oracle's `\?` crash, the decimal escape or the `Z.to_int`
   overflow turns the gate red.
   The fourth fork-ahead FIX (D17) has its own witness: `scripts/check_address_constants.sh` (row 1) pins gcc 13's line
   on BOTH engines for 183 of 244 nolibc programs over the §6.6 forms, 39 rejections as both engines' constraint
   diagnostics where gcc rejects too, 21 declared rows with gcc's line beside (the forms kept at upstream's answer), 1
   gap control, with pristine's lines as the negative control (113 moved), so a return to the missing arms, to the
   comma's acceptance, to `&local`, or to accepting a 6.6#10 form upstream does not accept turns the gate red.
   The formatter's refusals and fixes (D16) have one witness: `scripts/check_printf_refusals.sh` — row 1 runs its 32-program
   core (every refusal and fixed class once), Tier B row 15 (`--full`) the whole matrix — which pins, for 161
   libc-mode programs (4 nolibc controls), the 18 refusal texts WHOLE on both engines, 101 gcc 13 lines on both engines,
   3 declared fork lines, 38 UB verdicts (location projected) and the NaN gap control, with pristine's lines as the
   negative control (75 moved), so a return to the false `Invalid_format`, a crash, the truncated length or the
   misplaced zeros turns the gate red.
   Limit: the immaculate and coverage witnesses pin the crash CLASS (`L=CRASH`, `UNSUPPORTED`), not the refusal
   message, under those lanes' coarse crash policy (VALIDATION §1(a)); the message is fixed in the refusing code, and
   `check_cli_refusals.sh` asserts it for the CLI flags.
2. **A served-surface audit (the lesson of pathleak).** Every hand-written seam that can answer where it has no model —
   default arms, stub bodies, `Inhabited` defaults, lookups keyed on unnormalised data — is enumerated and classified:
   mirrors the oracle (with a cite), refuses (with a witness), or is unreachable (with the reason). The failure-reach
   register already does this for FAILURE sites; the audit extends the question to SUCCESS paths that answer without a
   model. Proposed as a fresh-reviewer pass with a finding ledger, before the contract is adopted.
3. **Adversarial inputs per area**, written from the contract rather than from the corpora: path spellings, fd reuse,
   environment and argv shapes, concurrency constructs in default mode. The corpora are upstream's tests and never
   exercised these.
4. `CONTRACT.md` becomes the front-page statement; `SUPPORTED.md` becomes its dated evidence table; VALIDATION keeps the
   mechanics. The announcement text points at `CONTRACT.md`.

## 5. Decisions

- **D1 — adopted** ([USER 2026-09-28] agreed): the outcome promise in §1 is the normative statement.
- **D2 — refuse the filesystem for now** ([USER 2026-09-28] chose refusal as the safer option). Implemented:
  every CerbFS operation refuses with a feature-attributed message; `write` to fds 1/2 stays served (driver-routed,
  never CerbFS). Three immaculate rows moved from MATCH to pinned refusals; the full ladder passed
  (`docs/2026-09-28_cerbfs-refuse-all-record.md`).
- **D3 — adopted** ([USER 2026-09-28] agreed): the served-surface audit (§4.2) ran
  (`docs/2026-09-28_served-surface-audit.md`). Its P1 finding (function-pointer numbers) is named deviation N1 ([USER 2026-09-28] agreed with option (1)),
  covering the integer conversion too after refusing it broke `atexit` ([USER 2026-09-28] agreed to the proposed
  `atexit` handling).
- **D4 — adopted, option 1** ([USER 2026-09-28] accepted option (1)): libc is supported by mechanism. Functions written
  in C inherit the core semantics' state; the 36 builtins are a named list with one state each (§3.1). `any_bounded_int`
  is listed as not served by either engine (the audit found it fails in both); its dead Lean seam, which returned `lo`,
  now fails loudly (`docs/2026-09-28_contract-enforcement-builtins-record.md`).
- **D5 — adopted, amended** ([USER 2026-09-28] agreed, amended to link it from the top-level README.md): this document is the
  public statement, linked from the top-level README.
- **D6 — LP64 only** ([USER 2026-09-28] agreed on the ABI): LP64 (the x86-64 Linux data model) is the one supported
  ABI, the only one the lanes test; every other ABI is out of scope. Its floating profile, stated 2026-10-29 (survey
  §2.4, tray 32; measured on both engines, identical): ONE representation, IEEE binary64 — `sizeof(float) ==
  sizeof(double) == sizeof(long double) == 8`, `_Alignof(float) == _Alignof(double) == _Alignof(long double) == 8`,
  every floating computation in binary64 (`(int)(float)16777217 == 16777217`; `1.0L + 1e-17L == 1.0L`, no 64-bit
  significand) — while the shipped `runtime/libc/include/float.h` still describes other types (`FLT_MANT_DIG 24`,
  `LDBL_MANT_DIG 64` against 53-bit values; no `FLT_EPSILON`): an intended gap reported in tray 32, the header not
  edited; a program that reasons about its own floats through `<float.h>` is told the wrong facts.
- **D7 — a NaN's bits are named deviation N2** ([USER 2026-09-29] agreed on all three points, on the recommendation to register
  the pre-merge audit's F2 rather than refuse storing NaNs): Lean's float store canonicalizes NaNs, so their bytes
  differ from the oracle's (VALIDATION §2b).
- **D8 — the libc dump's float rounding is named deviation N3** ([USER 2026-09-30] chose option (3) for now, leaving
  (1) or (2) as possible later work), with a float-literal inventory check. Standing rule [USER 2026-09-30]:
  deviations are not fixed with special-case paths that work only in one situation.
- **D9 — inline assembly is refused** ([USER 2026-10-05] ruled that inline asm is a loud refusal). Upstream erases
  it (an asm statement desugars to a skip; an asm label is dropped by the parser), so a program whose meaning lives in its
  asm ran as if the asm were absent (real-C census §4.5: both engines `Specified(1)` where gcc gives 5). The refusal is on
  the general path of the shared model and parser, so the oracle and Lean refuse identically and no asm semantics is
  invented; a deliberate fork-vs-pristine difference, manifested in the fork-drift gate. No gated lane row moved
  (`docs/2026-10-05_asm-refusal-record.md`).
- **D10 — the item-G memory-model TODOs are refused** ([USER 2026-10-20] ruled that where upstream Cerberus left a case
  deliberately to a TODO, the fork either leaves it as-is or REFUSES LOUDLY — the run dies with a declared unsupported
  outcome — and never invents a verdict (no UB verdict, no error verdict) in its place, nor answers silently wrong). Two
  cases from cerberus-caesium's note 2 (upstream-tray drafts 56/57): an overlapping `memcpy` (both engines answered
  `Specified(7)` on the draft's witness) and an allocation with an invalid alignment (`aligned_alloc(3, 9)` allocated at
  "alignment 3"). Both refusals sit in the concrete memory model of BOTH engines — `memcpy` and the `allocator`, not the
  shared `std.core` (Core text expresses only verdicts) — with byte-identical texts; alignment zero (tray 34's
  pre-existing crash) is unchanged. Two gated lane rows were literally these cases
  (`tests/coverage/mem4/mem4-020-memcpy-overlap.c`, `tests/libc_exec/009-aligned-alloc-3.c`), each a deliberate control
  of the superseded stance; [USER 2026-10-20] ruled them retired from the lanes with their baseline rows, the witness
  script carrying their purpose (`docs/2026-10-20_item-g-refusals-record.md`). Since 2026-10-26 the Lean
  engine's two refusals are outcome-protocol REFUSAL envelopes of boundary `memory` (quotation hygiene Q3,
  `docs/2026-10-26_quotation-hygiene-record.md`; the design-v2 §10 amendment, proposed by the worker and
  ratified at landing); the oracle's texts and the node shapes are unchanged.
- **D11 — union initializers designating a non-first member are refused** ([USER 2026-10-20] ruled, under the same
  rule as D10, that for union initializers the fork refuses rather than fixes — "refuse until it hurts" — that no C
  initialization semantics is to be claimed obvious, and that the parts upstream does not know about go to the upstream
  tray). Upstream's live initializer desugarer (`frontend/model/desugaring_init.lem` `constructValue_aux`) builds every
  braced union initializer as the FIRST member whatever the designators say, under its own TODO and a level-0 "is WRONG
  for union" print, so twelve well-formed programs answered silently wrong on both engines (tray 59 (a)). The refusal sits
  in the SHARED desugarer's `moveTo_aux` Union arm — the one place the designated member is decidable (the init-map key
  `Elem_union` carries no member identity) — as a Lem `error`, so the oracle (`Cerb_debug.error`) and Lean (`failwithI`)
  refuse with one text by generation; a deliberate fork-vs-pristine difference manifested in the fork-drift gate (the
  file was byte-identical to upstream before: new `desugaring_init.lem` / `desugaring_init.ml` rows). Measured over every
  corpus the lanes walk: exactly one gated program is a refused case — `tests/coverage/union3/union3-003-union-init.c`
  (`{ .c = 'A' }`, `c` the second member; Tier A row 3) — reported under the slice's STOP rule and RETIRED with its
  baseline row ([USER 2026-10-20], the item-G precedent: the project tolerates no silently wrong answer, and a MATCH on a
  wrong answer is not evidence; the witness script carries its shape) (`docs/2026-10-20_union-init-refusal-record.md`). Not refused, reported in tray 59 (b): the
  struct/union-value and designated-compound-literal initializer rejections; the anonymous-union layout (59 (c)) became D12.
- **D12 — anonymous struct/union members are refused** ([USER 2026-10-20] ruled, in the upstream-uncertainty survey
  (`docs/2026-10-20_upstream-uncertainty-survey-record.md` §0 ruling 2, §2.1 cluster A), that anonymous members are refused
  in the shared Lem and the upstream report filed (tray 60); [USER 2026-10-26] dispatched the slice). Upstream's
  `desugar_struct_declaration` (`frontend/model/cabs_to_ail.lem`; pristine b9aeedcb4 :2697) splices an anonymous member's
  members flat into the containing aggregate's member list — a struct-declaration with no declarator whose type specifier
  is a tagless struct/union, C17 6.7.2.1#13 — so the member loses its own storage: wrong `sizeof`/offsets, no aliasing
  between an anonymous union's members, brace-elided initializers one slot late, false UB verdicts (25 silent-wrong
  probes on both engines and pristine; the initializer layer carries upstream's own `this may be WRONG ==> anonymous`
  prints). The refusal sits at that arm as a Lem `error`, so the oracle (`Cerb_debug.error`) and Lean (`failwithI`)
  refuse with one text by generation (the D11 shape; [AGENT 2026-10-26] chose it over `E.fail loc
  (Desugar_NotYetSupported …)` because the latter is not rendered identically in batch — the port's record is only
  `desugaring failed at <loc>` — and the lanes class it `CERB_SKIP`, not a matched refusal); a deliberate fork-vs-pristine
  difference manifested in the fork-drift gate (the `cabs_to_ail.lem`/`cabs_to_ail.ml` rows). Measured over every corpus
  the lanes walk (5567 non-csmith files + 1669 csmith, the libc, CN and pKVM sources): exactly one gated program is a
  refused case — `tests/coverage/struct/struct-008-anon-struct.c` (Tier A row 3, MATCH 12: an anonymous struct accessed
  by name, the shape that happened to work) — RETIRED with its baseline row per the charter under the item-G/union3-003
  precedent (a MATCH on a case the fork now refuses is not evidence; the witness script carries its shape); the
  union-initializer script's anonymous-union control (D11's named carve-out) likewise retired, its shape a D12 witness;
  the ci-sweep scoreboard rows `gcc-torture/breakdown/success/anon-1.c` and
  `suite/desugaring/13-non_anonymous_empty_sdecltors.error.c` (no baseline) change class at their next deliberate
  re-record (`docs/2026-10-26_anonymous-members-refusal-record.md`). Not an override: the feature (an unnamed member with
  its own storage and member-path lookup through it) is upstream's to build; the refusal reaches every `union { … };`
  inside a struct, as intended.
- **D13 — compound assignments whose left operand contains a side effect are refused** ([USER 2026-10-20] ruled, in the
  upstream-uncertainty survey (`docs/2026-10-20_upstream-uncertainty-survey-record.md` §2.2 cluster B, §3 slice 2), that
  such a compound assignment is refused in the shared Lem and the one-binding elaboration filed upstream (tray 61);
  [USER 2026-10-29] dispatched the slice). Upstream's `AilEcompoundAssign` arm (`frontend/model/translation.lem`; pristine
  b9aeedcb4 :2505-2531) rewrites `E1 op= E2` to `E1 = E1 op E2` under its own `TODO: this elaboration is wrong because it
  duplicates any side-effect in E1` (:2506), so the lvalue's address computation runs twice: a call in it is called twice
  (a wrong value) and the `++`/`--`/comma forms get a false `UB035_unsequenced_race` (C17 6.5.16#3, 6.5.16.2#3; 9
  silent-wrong probes on both engines and pristine). The refusal is a syntactic walk over `e1` in the SHARED elaborator
  (`compound_assign_lhs_has_side_effect`, exhaustive over the Ail constructors: a postfix increment/decrement, an
  assignment, a compound assignment — the desugarer's form of the prefix `++`/`--` —, a comma, every call, an assert, the
  `va_*` builtins, a statement expression, a compound literal, anywhere inside the lvalue) and a Lem `error` whose text
  carries the location prefix (`<file>:<line>:<col>:: `, as the GNU `?:` arm's `record_error_at` renders it) so the
  oracle (`Cerb_debug.error`) and Lean (`failwithI`) refuse with one text by generation (the D11/D12 shape).
  [AGENT 2026-10-29, orchestrator ruling] `error` rather than the arm's neighbour `E.record_error_at` (the charter's
  first choice): measured, the constant-expression mini-run (`mini_pipeline.lem:157`, plain `runStateM`) DISCARDS a
  recorded error and executes the placeholder — the GNU `?:` arm in an enum, a `case` label, a `_Static_assert` or an
  array size dies with an unrelated text on both engines, and a `case (a[i++] += 1):` label reaches that run point —
  while `error` stops on every path with the attributed text (the 2026-10-18 fuel declares in the same file chose
  likewise); the walker takes its caller's declared fuel form (`failwithI CerbFuel.fuelExhaustedMsg` at zero; filed by
  the fuel-forms gate as ambient-unreachable, like `translate_expression`), no measure proof, no replay. Declared
  approximations: every call counts (`*g() += 3` refuses though `g` may be pure) and a `_Generic`'s controlling expression and every association, selected or not, are walked (over: `a[_Generic(0, long: i++, default: 1)] += 3` refuses though `i++` is never evaluated — pre-merge review P3-1); a VOLATILE read inside the lvalue's address computation is NOT counted (under, against
  C17 5.1.2.3#2: measured on the Core, the volatile object itself is loaded once by the rvalue copy and stored once,
  only a volatile subscript is loaded twice; Cerberus gives `volatile` no semantics beyond the qualifier, so the second
  read is value-identical and verdict-neutral; the strict reading would have refused every csmith program, the
  operator's standing reason not to refuse where a refusal kills a lot of code — [USER 2026-10-20], paraphrased). A
  deliberate fork-vs-pristine difference manifested in the fork-drift gate (the `translation.lem`/`translation.ml`
  rows). Measured over every corpus the lanes walk (5591 files under `tests/`, `lean_frontend/corpus` and the CN corpus
  through elaboration, 1669 csmith through the lane's materialization, the libxml2 and pKVM TUs with their lanes'
  arguments, the libc restaged): NO baselined row moves; exactly one scoreboard row does —
  `tests/gcc-torture/breakdown/success/990222-1.c` (`(*--ptr += 1)`; `torture_success.tsv:509` `UB_MATCH
  UB:UB035_unsequenced_race`, a false UB both engines agreed on) changes class at its next deliberate re-record
  (`docs/2026-10-29_compound-assignment-refusal-record.md`). Not an override: the one-binding elaboration is upstream's to adopt; the
  refusal reaches `*p++ |= x` and `buf[len++] += v`, as intended.
- **D14 — the macro integer types have the conversion rank of the type the implementation aliases them to** ([USER
  2026-11-04] approved the fork fix of an upstream mistake as proposed, a fork-ahead delta of the first kind: the fork's
  own fix, mirrored on both engines by generation, filed upstream as tray 20; the bar being a very clear standard and a
  blocked consumer, both met — C17 6.3.1.1#1, 7.19#2; cerberus-caesium's filing 05). Upstream's `lt_integer_rank`/
  `eq_integer_rank` (`ailTypesAux.lem`, pristine c3ff8c53f :455-541) compare the bare `Size_t`/`Ptrdiff_t`/`Wchar_t`/
  `Intptr_t`-family/`Enum` constructors and their ISO table's catch-all answers `false` under its own TODO, so the Core
  translation's usual arithmetic conversions fell to their last resort and computed `size_t` (and the other macro
  types') arithmetic and comparisons against the `int` family at 32 bits (`(size_t)1 << 32 == 0` was 1; `SIZE_MAX + 1`
  was 2^32; `!((size_t)1 << 57)` was 1), inside user code and inside the shipped C library (`strcspn` — and `strpbrk`,
  which calls it — kept only the first character of its set; two-way `strstr` read past the needle; `strspn`'s
  `&&` form was never affected: pristine's `strspn` is `9 9 5` = gcc on the reviewer's probe). The rule: outside CHERI
  both rank operands are normalised through `Implementation.normalise_integerType` before the comparison (the alias
  table the layout and range functions already used; an enum to its compatible type), the table carries the two
  `long long` rows (the standard's top rank; they answer what the catch-all answered for those pairs, which reach it
  from `usual_arithmetic_integer`'s bullets on equal promoted types), and the catch-all is a loud `error`; under CHERI
  upstream's reading is kept verbatim (`intptr_t` is a capability type there; its rank rule is upstream's; CHERI is
  unexercised here) [AGENT 2026-11-04, orchestrator rulings on the worker's report]. Consequences by construction:
  `wchar_t` and enums promote to `int` / their compatible type (6.3.1.1#2), and the Ail TYPE of every binary
  expression with a `ptrdiff_t`/`wchar_t`/`intmax_t`/`uintmax_t`/`intN_t`-family/enum operand against a standard type
  is the standard's (the type checker's `usual_arithmetic_integer` uses the same rank functions after its NON-STD
  arms; measured with `_Generic`, pristine → fork: `int + ptrdiff_t` 7 → 9, `enum + unsigned long` 8 → 10, `wchar_t +
  long` 7 → 9) while a `size_t` pair keeps its old Ail type through the NON-STD arm — so a consumer comparing its
  clone against RefinedC's frontend, which types those pairs the old way, may see that comparison move while the
  fork now matches the standard (the cerberus-caesium note says so). Deliberately unchanged, as upstream's
  judgement and the consumer's RefinedC parity: the type checker's NON-STD `Size_t`/`Intptr_t` arms, so `size_t op
  long long` is still TYPED `size_t` (gcc: `unsigned long long`; values equal) and `intptr_t` against an unsigned
  64-bit partner is a false UB036 — both filed in tray 20's related findings and pinned as declared residuals; a
  negative value stored into a `wchar_t` object still crashes both engines (report 62, the queued refusal). Measured
  (`docs/2026-11-04_macro-type-ranks-record.md`): a 483-program matrix over gcc 13.3.0, pristine and both engines —
  196 wrong before, 0 after on every program both sides complete, Lean = oracle throughout; the libc Core lost its 247
  `all_values_representable_in` conditionals (dumps and quotation pins re-derived); two `tests/libc_exec` rows moved
  to gcc's values (015 `strpbrk`, 016 two-way `strstr`), nothing else in any gated corpus; two `shared-model-fix`
  rows in the pristine register; the N4 witness moved from 016 to `042-strlen-unterminated-loc.c`. Witness:
  `scripts/check_macro_type_ranks.sh` (row 1). Not an override of a judgement: the code's own comment called the
  catch-all wrong, and the delta leaves when upstream absorbs the fix (the fork-drift manifest's `ailTypesAux` rows).
  **Known defect of D14 ([AGENT 2026-11-10]):** `WCHAR_MAX > 0` (`<stdint.h>`) answers 0 on both engines where pristine
  upstream and gcc answer 1 — `wchar_t` now promotes to `int` while its maximum is still the unsigned one; a silent wrong
  answer, fix slice queued (`TODO.md`, the entry at the top; tray 62 and the warning in tray 20).
- **D15 — program termination runs the `atexit` handlers and flushes the open streams; a libc-mode `printf` is the
  library's own** ([USER 2026-11-04] agreed the fix pass in the audited order under the standing bar — a very clear
  standard, no invented semantics; rulings [AGENT 2026-11-06, orchestrator] on the worker's design and on the two
  Tier A findings; upstream-tray report 24 (merged with 25) is the filing; record
  `docs/2026-11-05_stdio-exit-flush-record.md`). Upstream's driver ended the program at the startup function's return
  (`driver.lem` `process_core_step2`, `Step_done2` → `prepare_exit`) without entering the C library's `exit`, and the
  shipped library's `exit` ran the `atexit` handlers but flushed no stream, so with the library linked every `FILE`
  buffer still holding data at termination was lost (`fputs("out", stdout); return 0;` printed nothing; `puts("a");
  puts("b");` printed only `a`, stdout turning fully buffered after its first write) and the handlers a program
  registers never ran on `return` (tray 25). The rule: (1) with the library linked (the linked Core file DEFINES `exit`:
  the extern map's `LK_normal` target), the startup function's return is the library's `exit(status)` (C17 5.1.2.2.3;
  the SHARED driver installs the call on the initial thread — empty stack, a current procedure — under the file's
  calling convention; the globals phase and the Core builtin `exit` reached from `_Exit` keep upstream's direct
  termination, and the target must have the library's funinfo shape `void (signed int)`; `--nolibc` is unchanged for every program that does not itself define `exit` with external linkage (UB C17 7.1.3): the 787-program nolibc sweep moved nothing; a program-defined `exit` of the library's shape `void (signed int)` is routed like the library's and, should it return, is refused by a loud kill (never a second routing, never a verdict); a definition of another shape is not routed); (2) the library's
  `exit` flushes every open stream after the handlers (7.22.4.4#2-#4; `_Exit`, `quick_exit`, `abort` flush nothing:
  7.22.4.5#2, 7.22.4.7#3, 7.22.4.1#2, implementation-defined, upstream's library kept); (3) each engine withholds
  std.core's `printf` proxy from a libc-mode program at its stdlib load (the oracle's `prelude` under `not nolibc`,
  `Main.lean` under `--libc`, the Cabs JSON carrying no trace of the mode), so `printf` resolves by linking to the
  library's `printf` → `vfprintf`, which flushes the stream's pending buffer before the builtin writes through the
  descriptor (7.21.3: a stream's writes are ordered; the proxy wrote past the buffer); `vprintf`, declared by
  `<stdio.h>` and defined nowhere before, is `vfprintf(stdout, fmt, ap)` (7.21.6.10). Both engines: the driver by
  generation, the library through the pinned Core dumps, the proxy rule mirrored with the cite. Consequences a
  consumer sees: every libc-mode program whose output was not newline-terminated, or had more than one `FILE` write,
  prints more (`tests/libc_exec/034`, `041` moved to gcc's lines); a printf-format UB (`UB153b`, `Invalid_format`, …) is
  now raised inside the library's `vfprintf` (`stdio.c:717`), as `fprintf`'s always was, where the proxy raised it at
  the program's call — on the Lean engine that location is `<unknown location>` (N4), a `LOC_ONLY` pair for such
  programs; a printf call costs the library's varargs path (010-int32-printf 1249 → 1509 driver steps, 011-decimal-sweep
  31540 → 83540, a measurement); and the libc-mode global LAYOUT moved with the edited library TUs' source digests
  (every printed address shifted, allocation ids with them, values identical — the `address-layout` register class).
  Declared, pinned to the fork's own line in the witness: the exit status beyond 0..255 is the C int (`Specified(300)`;
  the host's `$?` is n mod 256); `_Exit`/`quick_exit`/`abort` after buffered output print the lines the shipped library
  wrote through before turning fully buffered (gcc with a pipe prints nothing); a handler that calls `exit` (UB
  7.22.4.4#3) follows the shipped library's (musl's) text — the remaining handlers, then `_Exit` — which gcc/glibc also
  follow; `fopen` is the D2 refusal. Witness: `scripts/check_stdio_exit.sh` (row 1), 46 programs (the total and the class
  counts pinned), pristine's lines the negative control (33 moved). Not an override of a judgement: the standard's clauses are explicit and the library's
  own `exit` (musl's `__stdio_exit`) and the TODO-free proxy shortcut were omissions; the delta leaves when upstream
  absorbs the fix (the manifest's `driver.lem`, `stdlib.c`, `stdio.c`, `main.ml` rows).
- **D16 — the formatter refuses the conversions it does not implement and reads a `*` width/precision, the `j`/`z`/`t`
  types, `snprintf`'s length and the `0`/`#` flags as the standard says** ([USER 2026-11-04] agreed the fix pass in the
  audited order under the standing bar — a fork fix only where the standard is very clear or a consumer is blocked, no
  invented semantics, otherwise a declared refusal and a filing; [USER 2026-11-07] dispatched the slice (charter
  `docs/2026-11-07_worker-charter-printf-refusals.md`); the dispositions below are [AGENT 2026-11-07, worker] within
  that bar; record `docs/2026-11-07_printf-refusals-record.md`; upstream-tray reports 26, 16, 68, 69, 70 are the
  filings, 27 stays as filed). Upstream's `formatted.lem` (pristine `c3ff8c53f`) parsed only `%f` of the floating
  conversions and no `L` (`:32`, `:40`, `:133`, `:143`), so a conforming `printf("%e", 3.5)` was `Invalid_format` UB;
  `%*d` and `%.*d` died with `TODO: formatted.lem 6` / `TODO: Formatted.convert, * prec` (`:742`, `:424`), `%n` with
  `WIP: Formatted.convert, CS_n` (`:697`), `%ls` and `%lc` with `WIP: … CS_s with length modifier` / `NOT YET SUPPORTED:
  %lc` (`:624`, `:612`); the `LM_j` arm tested the bare `Intmax_t` constructor against the alias-normalised argument
  (`:530-531`) and the `LM_z`/`LM_t` arms one signedness (`:532-535`); `vsnprintf` returned `List.length cs'` of the
  truncated list, 0 without formatting at `n = 0`, and `error "TODO: snprintf()"` on a UB result (`:794`, `:803`,
  `:805`); `justify` put the `0` flag's zeros in front of the sign/base (`:223-236`) and `expand` left `%#f` without its
  point (`:201-205`). The rule, in the shared Lem (both engines by generation; the libc C text untouched: the formatter
  is the Core builtin's model): (1) REFUSALS, the D11/D12/D13 form (a pure `error` in monadic position, one attributed
  text per class, fired when the conversion is reached) for the e/E/g/G/a/A/F conversions and the `L` modifier (a
  refusal rather than the false UB; the implementation is a later slice, queued with a size), for `%n`, `%ls`, `%lc`
  (a crash becomes a refusal: always a valid refinement), for a `*` argument whose value is unspecified or
  non-constant (the formatter does not guess a width), and for a `%%` specification carrying a `*` width or precision
  (`%*%`: UB by 7.21.6.1#8, a crash upstream; neither a value nor a UB verdict is upstream's — the pre-merge review's
  P2-1 struck the first version's consumed-and-padded value); the parser accepts the full 7.21.6.1#7-#8 syntax and a format
  it cannot parse stays `Invalid_format` (7.21.6.1#9, the standard's rule for a malformed specification). (2) FIXES
  where the clause is explicit and the implementation small: the `*` width/precision from an `int` argument
  (7.21.6.1#5; chosen over a refusal, the charter's option, because the obvious loads suffice); the `j`/`z`/`t`
  expected types normalised through the implementation's alias table, uniformly and in either signedness
  (7.21.6.1#7; the sibling `%zd`-of-a-`long` found by the vicinity probe); `snprintf`'s would-be length, formatting at
  `n = 0`, the UB verdict passed through (7.21.6.5#2-#3); the `0` flag's zeros after the sign and the `0x`/`0X` base,
  spaces for an infinity or NaN, `#`'s decimal point on `%f` (7.21.6.1#6; the vicinity probe's siblings `%05d` of -5 =
  `000-5`, `%#05x` = `00xff`, `%010f` of inf = `0000000inf`, `%#.0f` = `3`); a non-`l` modifier on `%s` is `UB158`
  (7.21.6.1#7, the rule upstream's `%f` arm applies; a crash before). (3) KEPT as upstream's judgement, pinned to the
  fork's own lines and filed: the strict exact-type reading for a wrong-signedness `int` argument (tray 27, the
  REFUSE-AND-FILE of the audit), the `DUMMY` verdicts (`+` on an unsigned conversion, a modifier on `%c`), the padded
  `%5%` (a literal width on `%%`: upstream's arm under its own TODO), the space flag on an unsigned conversion, the
  `%s`-of-a-non-pointer crash (UB input, a crash is tolerated); `%f` of `-0.0` printing `0.000000` is the negation's, not the formatter's (tray 70's related finding).
  Consequences a consumer sees: every program whose format reaches `%e`/`%E`/`%g`/`%G`/`%a`/`%A`/`%F`, `%Lf`, `%n`,
  `%ls`, `%lc` or `%*%` now REFUSES (oracle exit 125, Lean abort 134) where it was reported as UB or crashed — never a wrong
  answer; `%*d`/`%.*s`/`%*.*f` forms print; `%jd`/`%ju`/`%zd`/`%zu`/`%td`/`%tu` print for the standard's types;
  `snprintf`'s return is the would-be length (`tests/libc_exec` 026, 027, 028 moved to gcc's values; pristine-lane
  `shared-model-fix` rows); `%05d`/`%#08x`/`%010.3f` of a negative or prefixed value and `%#.0f` print gcc's text; a
  `snprintf` format's UB is a verdict. Measured (`docs/2026-11-07_printf-refusals-record.md`): a 162-program matrix
  over gcc 13.3.0, pristine and both engines — before, 36 crashes, 13 false `Invalid_format`, 8 false `UB153b` and 21
  values differing from gcc; after, 17 refusals, 99 values = gcc, 38 UB verdicts, 7 values differing from gcc (the
  known non-formatter / implementation-defined / judgement rows), 1 crash on UB input, Lean = oracle on 161 of 162 (the
  NaN refusal) — the after-counts restated for P2-1 (`%*%` moved from a value to a refusal; derived from the final
  matrix and the witness run). Witness: `scripts/check_printf_refusals.sh` (row 1). Not an override of a judgement: every fix is the
  clause's text (upstream's own TODOs and the commented-out constructors mark the omissions), and the deltas leave
  when upstream absorbs them (the fork-drift manifest's `formatted` rows); the refusals stay until the conversions are
  implemented.
- **D17 — the desugarer's constant-expression predicates accept every form C17 6.6#3-#9 lists and reject the
  operators 6.6#3 forbids** ([USER 2026-11-04] agreed the fix pass in the audited order under the standing bar — a very
  clear standard, no invented semantics, the vicinity rule; [USER 2026-11-07] dispatched the slice; upstream-tray
  report 09, with 28 and 29 merged into it, is the filing; record `docs/2026-11-07_address-constants-record.md`).
  Upstream's `is_lvalue_to_static_object`, `is_address_constant` and `is_arithmetic_constant_expression`
  (`cabs_to_ail.lem`, pristine c3ff8c53f :821-957), which decide 6.7.9#4 for every static or thread storage-duration
  initializer, lacked the indirection arm (`a[i]` is `*(a + i)`: `&g_arr[1].b` rejected), the conditional operator and
  the generic selection, the string-literal address constant (`"hello" + 1`), `address constant ± integer constant
  expression` below the top level (`(char *)&g + 4` a UB055 verdict) and the decay of a member array or matrix row,
  while accepting ANY identifier under unary `&` (`&local` in a block-scope static passed the constraint), the comma
  (`static int a = (1, 2);` ran), a value read through `*` and `->` through a pointer variable; `is_integer_constant_
  expression`'s wildcard arm crashed on a `_Generic` or a compound literal in an enumerator, case label, array bound
  or `_Static_assert`. The rule, arm by arm with its clause: `*p` and `p[i]` over an address constant (6.6#9), `->`
  over an address constant (6.5.2.3#4), a string literal (6.4.5#6, 6.3.2.1#3), `&` of a static lvalue or a function
  designator, a pointer cast of an address constant or an integer constant cast to pointer type, `±` an integer
  constant expression with the pointer operand found first (6.6#7, 6.5.6), `?:` and `_Generic` whose branches and
  associations are all constant (6.6#3, 6.5.1.1#3; the association is selected during the Ail typing, so an
  unselected non-constant one is rejected — too strict, never fail-open, upstream's own TODO on its `?:` arms), the
  decay of an lvalue of array or function type built from a static object (6.3.2.1#3-#4; its type taken from the
  desugar-time typing in the sizeof context, where neither the lvalue conversion nor the decay is performed, the
  mechanism the `sizeof` desugaring uses), the comma, the increment and the indirection operators rejected (6.6#3,
  6.6#9), `&` of a non-static object rejected (6.6#9), the caller testing 6.6#7's bullets in order [AGENT 2026-11-07,
  the worker's design under the charter's M1 text]. The accepted set is exactly upstream's accepted set plus those
  forms and nothing else ([AGENT 2026-11-07, orchestrator] on the pre-merge review's P1-1, option (ii): the first build
  had accepted four 6.6#10 forms upstream did not; the `?:`/`_Generic` operands are tested in 6.6#8's own terms, a
  cast to a non-pointer type keeps upstream's arm with its operand required to be a static ARRAY lvalue, and the base
  of `*`/`->` must designate an object). In the fork's own voice, the 6.6#10 forms and upstream's answers, both
  directions: accepted as upstream accepts them — `(long)&g`, `(long)ga`, `&g == &g`, pointer differences, `(int *)16`;
  `(int)&g` passes the constraint and is UB024 at execution (gcc rejects it) —; not accepted as upstream does not —
  `(int *)(long)&g` and the `offsetof` idiom through an integer cast (UB055), `&g ? 3 : 4` and `_Generic` over `(long)&g`
  (rejected), `&(int){3}` (a compound literal's static storage, 6.5.2.5#5: the charter's judgement area), `"hello"[1]`
  and a `const` object's value (rejected; gcc folds them). Declared over-strictness kept from upstream: an unevaluated
  `?:` branch or an unselected `_Generic` association that is not itself a constant expression is rejected, the comma
  there included (6.6#3's own exception not taken). Residuals of upstream's, not fixed: `(long)&g - (long)&ga[0]` runs
  and `&g + (int)&g` is UB024 where gcc rejects (the arithmetic predicate's retained `&` arm); a non-arithmetic cast
  operand is UB055 where gcc gives a constraint (`(int *)(double)3`); the GNU `?:` keeps its rejection in an
  initializer and its pre-existing crash in the integer-constant contexts (TODO); the `_Generic` arm in an integer
  constant expression is the fork's reading of 6.5.1.1#3 (6.6#6 does not name generic selections; upstream's TODO crash
  is what it replaced). Measured (the record §3-§4): a 472-program §6.6 table over gcc 13.3.0 `-std=c11
  -pedantic-errors`, pristine and both engines — before 77 over-strict rejections, 3 fail-open acceptances and 84
  crashes; after 94 rows the fork accepts and pristine does not, every one gcc-accepted and a listed form, 12 rows
  pristine accepts and the fork does not, every one gcc-rejected, 0 engine disagreements, 26 declared rows, 1 residual
  fail-open, the 4 GNU-`?:` crashes —; a 7413-file sweep of every corpus the lanes walk: 11 rows moved, none from
  accepted to rejected (8 rejections now run at gcc's values; `ci/0268 int x = &1;` reports the desugarer's
  constraint before the typing's, a `diagnostic-text` register row; `csmith_findings/oracle/init_addr_const.c` reaches
  draft 08's invalid-node crash one stop earlier). Witness: `scripts/check_address_constants.sh` (row 1), 244 programs
  (the total and the class counts pinned), pristine's lines the negative control (113 moved). Not an override of a
  judgement: the arms are the standard's list, upstream's own comments call the predicates partial, and the delta
  leaves when upstream absorbs the fix (the manifest's `cabs_to_ail` rows).
- **Agent-called dispositions under these rulings** [AGENT 2026-09-28]: `%f` of a NaN is refused rather than
  registered (it can be refused cheaply and precisely; Lean cannot read a NaN's sign), and the other disagreements that
  record found (its D3–D6, a separate numbering from this section's) are dispositioned in `docs/2026-09-28_thin-surface-tests-record.md` (addendum).
- **D18 — the three oracle half-mirrors are closed on the OCaml side: `\?` decodes, the formatted store round-trips
  every byte, `memcmp` with a huge size reports the out-of-bound load** ([USER 2026-11-04] agreed the fix pass in the
  audited order under the standing bar — a fork fix only where the standard is very clear or a consumer is blocked, no
  invented semantics; dispatched in parallel [USER 2026-11-07]; upstream-tray reports 10, 11 and 13 are the filings,
  Sent 2026-09-26 and now "fixed in the fork"; record `docs/2026-11-07_half-mirrors-oracle-record.md`; numbered after
  the two parallel slices' D16/D17). The true-bug audit of 2026-11-04 found these three HALF-MIRRORED: the Lean engine
  answered right under the ISO-fix register rows R1/R2/R3 (VALIDATION §2) while the fork's own OCaml oracle still
  crashed or corrupted, so the standing rule of zero Lean-versus-OCaml behavioural discrepancies was unmet on them. The
  oracle moves to the Lean engine's behaviour, hand-written OCaml only (no Lem change, no generated delta, no proof
  change; the Lean edits are comments): (1) `ocaml_frontend/decode.ml` `decode_character_constant_aux` carries the
  `\?` arm (C17 6.4.4.4#1 lists `\?` among the simple-escape-sequences, #4 gives it the value of `?` = 63; both the
  character-constant and the string-literal entry points share the decoder, so `'\?'`, `"\?"`, `L'\?'`, `u8"\?"`
  all decode) where upstream dies on an uncaught Failure on strictly conforming C; (2) `decode.ml` `escaped_char`
  mirrors `CerbDecode.escaped_char` arm for arm (the simple escapes the decoder names, hexadecimal `\xNN` for every
  other byte outside 32..126, the byte itself otherwise), so `formatted.lem`'s `store_chars_in_array` round trip
  `decode_character_constant (escaped_char c)` — the `vsnprintf` builtin's store behind `snprintf`/`sprintf`/
  `vsprintf`/`vsnprintf` — is the identity on all 256 bytes (C17 7.21.6.1#8: `%c` writes the argument converted to
  `unsigned char`, unchanged) where upstream's `Char.escaped` emitted OCaml's DECIMAL `\ddd`, read back as OCTAL (127
  stored as 87, 200 as 128) or refused (19, 199: an uncaught Failure); (3) `memory/concrete/impl_mem.ml` `memcmp`
  counts on `Z` (a count ≤ 0 is the empty comparison, `memcpy`'s shape in the same file; a negative count is
  unreachable from C) where upstream converted the C-controlled size with `Z.to_int` before reading a byte, an uncaught
  `Z.Overflow` on `memcmp(a, b, (size_t)-1)`, so the checked per-byte load's own `UB_CERB002a_out_of_bound_load` is
  reached, at the memop's location, on both engines. Not an override of a judgement: each is a demonstrable mistake
  against explicit standard text (the escape grammar, `%c`'s conversion) or a host-integer exception in place of the
  model's own verdict; each leaves when upstream absorbs it (the manifest's `decode.ml` and `impl_mem.ml` rows,
  fork-ahead deltas of the first kind). Consequences a consumer sees: a libc-mode program that stores a byte outside
  32..126 through the `snprintf` family now reads it back unchanged (it read 87/128/… or crashed); a program with `\?`
  in a constant or string literal now runs on the oracle (it crashed); `memcmp` with a size beyond OCaml's `int`
  reports the UB (it crashed); the immaculate pins `g5-decode-question`, `zd-e2-ptr-string-literals`,
  `g5-escape-roundtrip`, `zd-r2-highbyte`, `zd-r2-crash-digit9`, `s4b-memcmp-hugesize` are `MATCH` rows; R1/R2/R3
  are RETIRED (their `-- ISO-fix register Rn` markers kept as historical notes). Declared, pinned in the witness:
  universal character names (`\u00e9`, `\U0001F600`, in constants and string literals), multi-character and raw
  non-ASCII constants still CRASH both engines identically in the decoder's catch-all (tray 63's crash-to-refusal
  item owns that site: one refusal arm will cover all three shapes — UCNs need the execution character set, so a
  refusal, not an implementation, is the answer; [AGENT 2026-11-07] left to that slice rather than adding a Lean stop
  site here); `'\0123'` is read as ONE four-digit octal escape (83) where the grammar stops at three digits and gcc
  sees a multi-character constant (51, implementation-defined 6.4.4.4#10; tray 63's class); the out-of-range escapes
  `'\400'`/`'\x100'` (a constraint violation, 6.4.4.4#9) are accepted by both engines as the wrapped value gcc `-w`
  gives (gcc `-pedantic-errors` rejects them). Witness: `scripts/check_half_mirrors.sh` (row 1), 41 programs (27
  gcc-pinned, 9 fork-pinned, 5 gap controls; the totals and the moved count pinned), pristine's lines the negative
  control (18 moved).
