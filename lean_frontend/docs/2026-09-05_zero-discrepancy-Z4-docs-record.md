# Zero-discrepancy Z4 — the DOCUMENTATION half: tray drafts 20–35, the VALIDATION.md trust-story rewrite (2026-09-05)

Branch `docs/z4-tray-validation`, written @ base mainline `mdd/cerberus-lean`
`928aa1e76` and REBASED 2026-09-05 onto `eb27fa70f` (the CerbGlobal-defs
step-1 slice; see §7) — plain worktree, no build. Author: the Z4 docs worker
[AGENT]; every ruling quoted is [USER 2026-09-03] as recorded in the
charter `docs/2026-09-03_zero-discrepancy-design.md` and the two rulings
`docs/2026-09-03_logical-semantics-referent-ruling.md`,
`docs/2026-09-03_typed-failure-outcomes-ruling.md`; every classification
here is [AGENT] and open to operator override. Scope (the brief): the
tray drafts of charter §5 (20–33) + 34 (aligned_alloc) + 35 (the four
pp↔grammar mismatches) + the tray-10 addendum + `lean4/02`; the
VALIDATION.md rewrite of charter §4.3 (+ `scripts/LADDER.md:69`); this
record. NOT in scope (the CODE half of Z4): probe integration into lanes,
the sweep re-record, instrument changes — §5 lists what it still owes.

Docs only. No product code, gate, baseline, lane or script other than
`scripts/LADDER.md`'s text was modified; nothing merged or pushed.

## 1. Method

- Inputs read in full: the charter (§1 rule + exceptions, §2.5 the
  oracle-suspect rows, §4.3, §5, §7), the Z1 record (§5 register, §7
  findings for Z4), the Z2 record (§2.1, §8, §10), the Z2 audit §2.14,
  the C1 record §4.3, the C2/C3 records' (A)/(B)/(C) table and
  `scripts/fuel_forms_pending.txt` (15 rows), the noodle record and the
  probe corpus READMEs, INDEX.md + README.md + drafts 10/15/19 as format
  templates, VALIDATION.md, DESIGN.md §4, the two rulings, LADDER.md.
- Reproducers re-run 2026-09-05, serially, under `scripts/capped`
  `CERB_MEM_MAX=8G`, timeout 30 s (120 s for `mem_calloc_overflow.c`),
  through an ephemeral three-engine runner modelled on
  `tests/z2-probes/run_z2.sh`: fork oracle = the PRIMARY checkout's
  `_build/default/backend/driver/main.exe` + `_build/install/default`
  (built from `928aa1e76`; read-only), upstream = `deps/cerberus-upstream`
  `main.exe` + its install runtime @ `b9aeedcb4`, Lean = the primary's
  `lean_frontend/.lake/build/bin/cerberus-lean` (`LEAN_ABORT_ON_PANIC=1
  --batch --fuel 100000000`, cabs-json from the fork binary; libc mode:
  `--libc tests/libc/libc.core` + the 12 libc metadata jsons generated
  into this worktree's `.tmp/z4/libcjson` by the same 12 `--cabs-json`
  invocations `scripts/libc_prep.sh --jsons` performs), gcc 13.3.0
  (`-std=c11 -O0 -w`). The `.core` witnesses for draft 35 and the
  `--pp=core` shapes quoted in drafts 20/21/33 were produced on the
  upstream binary. `.tmp/z4/` is EPHEMERAL (deleted at slice end); every
  line this record or a draft relies on is quoted verbatim in it.
- Every `file:line` cite was re-read in this tree AND in
  `deps/cerberus-upstream`; where the fork's `.lem` numbering has drifted
  (Lean-target `declare` lines: `ailTypesAux.lem`, `translation.lem`,
  `core_eval.lem`, `formatted.lem`, `driver.lem`, `cabs_to_ail.lem`,
  `genTyping.lem`, `core_aux.lem`) the drafts cite MASTER's numbers and
  state that the cited region is identical (region diff empty).
  Byte-identical files: `impl_mem.ml` (through :2998), `std.core`,
  `string.c`, `stdlib.c`, `stdio.c`, `float.h`, `ocaml_implementation.ml`,
  `pp_core.ml`, `pp_mem.ml`, `core_parser.mly`, `core_lexer.mll`,
  `desugaring_init.lem`, `constraint.lem`, `cabs_to_ail_aux.lem`.
- The `results.log` files the noodle READMEs reference are NOT in the
  tree for `int/ptr/elab/lib/mem/misc/float` (only
  `dynamic-addrs/results.log` is committed); the comparison baseline for
  "did a line move" is therefore the noodle record's quoted lines and the
  Z2 record §2.1 lines.

## 2. The draft table

| # | draft | class [AGENT] | reproducer | re-run 2026-09-05 (fork / upstream / Lean / gcc) | vs the recorded lines |
|---|---|---|---|---|---|
| 20 | `20-size-t-integer-rank-uac.md` (U1) | TRUE BUG | `tests/noodle-probes/int/int_size_t_uac_rank.c` (nolibc) | `Defined … stdout: "705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705\n"` ×3 / gcc `5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001` | unchanged |
| 21 | `21-provenance-lost-through-arithmetic-pvi.md` (P2) | TRUE BUG vs intent / UNCLEAR (question) | `ptr/ptr_intptr_arith_roundtrip.c` (nolibc) | `Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<10:10--10:12>"}` ×3 / gcc 20 | unchanged (record quoted no loc) |
| 22 | `22-ptrdiff-strips-array-layer.md` (P1) | TRUE BUG | `ptr/ptr_array_ptrdiff_scaling.c` (nolibc) | `… stdout: "8 3 2 2 4 8\n"` ×3 / gcc `2 1 2 2 1 8` | unchanged |
| 23 | `23-string-literal-init-of-char-array-members.md` (E4) | TRUE BUG | `elab/elab_string_member_init.c`, `elab_string_struct_member_init.c` (nolibc) | oracles: `constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'` exit 1; Lean `Error {msg: "typechecking failed at …:5:17-21"}` / `…:4:31-35`; gcc 99 / 98 | unchanged |
| 24 | `24-stdio-buffer-not-flushed-at-exit.md` (L3) | TRUE BUG | `lib/lib_stdio_unflushed_lost.c`, `lib_stdio_exit_unflushed_lost.c`, `lib_stdio_puts_after_putchar.c` (libc) | `stdout: ""` / `" 5\n"` / `"\n"` ×3 engines each; gcc `out` / `out 5\n` / `\nxy\n` | unchanged |
| 25 | `25-atexit-not-run-on-main-return.md` (L4) | TRUE BUG | `lib/lib_atexit_order.c` (libc) | `Defined {value: "Specified(4)", stdout: "m", …}` ×3 / gcc `m21` exit 4 | unchanged |
| 26 | `26-printf-star-width-crash.md` (L5) | TRUE BUG (crash on legal input) | `lib/lib_printf_star_width.c` (libc) | oracles exit 125 `Failure("internal error: TODO: formatted.lem 6")`; Lean exit 134 `PANIC at _private.LemLib.0.failwithIImpl LemLib:168:2: TODO: formatted.lem 6`; gcc `[   9]` | unchanged; the PANIC line number moved `LemLib:171:2` → `:168:2` (build-relative, Z1 record §7 item 9 — not a stop) |
| 27 | `27-printf-hex-int-argument-ub153b.md` (L6) | TRUE BUG (over-strict; caveat stated) | `lib/lib_printf_hex_int_arg.c` (libc) | `Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<7:18--7:55>"}` ×3 / gcc `[ff][FF][10]` | unchanged |
| 28 | `28-conditional-in-static-initializer.md` (E3) | TRUE BUG | `elab/elab_const_expr_ternary_init.c` (nolibc) | oracles `constraint violation: initializer element is not a compile-time constant` exit 1; Lean `Error {msg: "desugaring failed at …:5:16-33 (cursor: 5:24)"}`; gcc 10 | unchanged |
| 29 | `29-string-literal-address-constant.md` (E5) | TRUE BUG (tray-09-adjacent) | `elab/elab_addr_const_string_plus.c` (nolibc) | same diagnostic, exit 1; Lean `desugaring failed at …:6:24-35 (cursor: 6:32)`; gcc 101 | unchanged |
| 30 | `30-strncmp-zero-length.md` (L1) | TRUE BUG (libc) | `mem/mem_strncmp_zero.c` (libc) | `Defined {value: "Specified(2)", …}` ×3 / gcc 1 | unchanged |
| 31 | `31-calloc-overflow-check.md` (L2) | TRUE BUG (libc, minor) — **ON HOLD** | `mem/mem_calloc_overflow.c` (libc) | fork/upstream `Defined {value: "Specified(2)", …}`; **Lean `Defined {value: "Specified(2)", …}`**; gcc 1 | **STOP ROW — the Lean column moved**: the noodle record has Lean OOM-KILLED at 6G (RC-3); today Lean agrees with the oracle (Z2-M-04 made `allocateRegion` lazy for untouched regions — immaculate header, `zd-z2m03-malloc-oom-msg`). The upstream evidence is unchanged; per the brief's rule the draft is written but marked ON HOLD in its header, INDEX and README, for the operator's second look before filing |
| 32 | `32-float-evaluated-as-double.md` (F1) | INTENDED GAP + TRUE BUG on the `float.h` consistency (Q6 framing) | `float/float_single_precision.c` (nolibc) | `… stdout: "0 100000000 1 16777217 1 0 1 0\n"` ×3 / gcc `1 100000001 0 16777216 0 0 1 1` | unchanged |
| 33 | `33-unspecified-operand-exceptional-condition-question.md` (O6) | UNCLEAR (question) | `misc/misc_unspec_absorbed.c` (nolibc) | `Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<4:32--4:43>"}` ×3 / gcc 3 | unchanged |
| 34 | `34-aligned-alloc-zero-alignment-division-by-zero.md` (Z2-M-01) | TRUE BUG (tool crash; kind 2) | `tests/z2-probes/mem/aligned_alloc_zero.c`, `_nolibc.c`, `_zero_zero.c` | oracles exit 125 `Division_by_zero` `Raised at Z.rem … Called from Cerb_frontend__Impl_mem.Concrete.op_ival in file "memory/concrete/impl_mem.ml", line 2482` (all three); Lean `Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<8:28--8:47>"}` / `<4:28--4:47>` / `PANIC at CerbMem.allocator CerbMem:2075:6: … alignment 0 has no meaning in the model …` exit 134; gcc exit 0 (NULL) | unchanged (= the immaculate `zd-z2m01-*` pins); the PANIC line number moved `CerbMem:2035:6` → `:2075:6` (build-relative — not a stop) |
| 35 | `35-pp-core-grammar-mismatches.md` (CP-15/CP-21/CP-09/CP-10) | item 1 TRUE BUG (parser); 2–4 TRUE BUG conditional on round-trip intent | hand-written `.core` witnesses + a C-derived `x++` dump, upstream binary | CP-15: `seq_rmw('signed int', Specified(7), x => Specified(7))` re-printed; C: `--exec` of the re-read `x++` dump → `Error {msg: "unresolved symbol: a_509 at …:7:7-15:11"}` vs `Specified(2)` from the C; CP-21 `unresolved symbol 'Civfromfloat'` (29 in `tests/libc/libc.core`); CP-09 `unresolved symbol 'wrapI_div'`; CP-10 `pcall(f, )` → `unexpected token ')'`, `builtin g (integer)` → next-token parse error, and the grammar form trips `core_parser.mly:961` `Assertion failed` (new observation) | new evidence (the audit had code-read only); also observed: float literal `Specified(2.5)` and `'void (*) (void)'` unparseable (02/03 class) |
| 10 (addendum) | `10-decode-rejects-question-escape.md` (E2) | — (register R1's string-literal form) | `ptr/ptr_string_literals.c` (nolibc) | oracles exit 125 `Failure("decode_character_constant, started like an octal constant, but failed: ?")` from `translation.ml:3029` (upstream) / `:3032` (fork); Lean + gcc `98 65 66 4 83 52 3 10 9 92 34 39 63 0 4` | unchanged (= the immaculate `zd-e2-ptr-string-literals` pin) |
| lean4/02 | `lean4/02-nat-div-mod-literal-folding.md` | UNCLEAR (question, reproducer) | `docs/upstream-tray/lean4/repro/DivModLiteralFold.lean` (standalone) | 4.28.0 / 4.32.2 / 4.33.0 / nightly-2026-08-02: identical four `Type mismatch` errors at lines 17, 18, 19, 24; `lean` exit 1 | matches the C1 record §4.3 line-by-line outcomes (OK/FAIL pattern identical) |

Derived: 16 numbered drafts + 1 addendum + 1 lean4 draft; 1 stop row
(31, held); 2 build-relative PANIC line drifts (not stops); 0 rows where
an oracle or gcc line differed from the recorded one.

Cite verifications worth recording (all in-tree, re-read this slice):
`ailTypesAux.lem` catch-all is master :527-529 (fork :529-531);
`translation.lem` UAC last-resort master :1457-1477; `core_eval.lem`
:29-46/:61-80 identical numbering; `impl_mem.ml` :11, :627, :1961-1967,
:2479-2484, :1247-1265 as cited; `formatted.lem` master :253, :423-424,
:515-538, :563-572, :584-585, :741-742; `desugaring_init.lem:461-462`
(`if false (* … string literal *) then internal_error "TODO: explode the
elements"`) is E4's mechanism — more precise than the noodle's
"initializer typing"; `cabs_to_ail.lem:794-843` has no `AilEcond` arm
(E3) while `:727-740` does; `:894-925` has no `AilEstr` arm (E5);
`driver.lem` master :1303-1311/:1328-1333 and `stdlib.c:223-227`
(L3/L4: neither termination path flushes); the O6 arm is master
`translation.lem:2165-2171` via `core_aux.lem:476-478`; the Lean
`CerbMem.lean` strip comment moved to :2521 (was :2184-2187 in the
noodle record). Also: `x++` DOES elaborate to `seq_rmw` (C-reachable
CP-15), while `x += 6` and unsigned `/` do not print `seq_rmw` /
`wrapI_div` — the drafts say exactly what was and was not observed.

## 3. VALIDATION.md — before / after

Before (at `928aa1e76`): §1 what is compared, §2 lanes, §3 gates, §4 how
often, §5 "what this does and does not establish" carrying the ISO-fix
register (Z1), the runtime-seam list "with its ruled classification
[USER 2026-08-31]", a paragraph "The remaining declared MODEL boundary:
… CerbFS … CerbDebug … concurrency stubs (temporal, the cmm
instantiation is the mover)", and the "Known, LOUD limits" bullets
(refused flags, `LEAN_ABORT_ON_PANIC`, `runND`, the fuel paragraph with
the (A)/(B)/(C) table, the 8 M hang). `CerbGlobal` was "temporal; mover:
a post-arc parameter-plumbing slice". R3 was "ADMITTED CONDITIONAL on
Z4's (ii′)(3)". `test_verify` said 117 checks; `test_ci_sweep` said
"zero mismatches among 1,316 comparable files".

After (this slice):

- **§0 The aims and the rule** — the four aims verbatim; the rule §1.1
  verbatim; the referent ruling verbatim with the kind-1/kind-2
  distinction; "UB location is behaviour"; the terminology block
  (oracle/upstream/execution discrepancy/mirror).
- **§1 The exception classes and their operational tests** — (a), (b)
  [+ (b)/fuel], (c), (d) each with the quoted ruling, the TEST a lane or
  reader applies, and the standing members; plus the two non-exception
  dispositions (kind-1 fail-stops → the scheduled typed-failure pass;
  instrument artefacts).
- **§2 The ISO-fix register** — the Z1 table kept; **R3 rewritten:
  ADMITTED BY CLASS (kind 2)** with the referent-ruling cite and the
  honest provenance (the ruling is [USER]; the class admission is the
  orchestrator's [AGENT] reading recorded in the ruling doc's
  consequences list and relayed as this slice's instruction); tray 13's
  scratch-oracle check stays as the filing-time check, not a condition;
  the R3 (vii) marker and the register↔marker bijection gate are named
  as owed. R4 DEFERRED kept.
- **§3 Every known Lean-vs-oracle difference, by class** — the census
  pointer as THE enumeration; then the standing summary: (a) members;
  (b)-VIOLATIONS with named movers (8 M hang → lem run-loop rendering +
  lean4/01 + tray 18; byte-list → representation change; wall-clock →
  per-row evidence, 9 csmith + 11 gcc rows pending); (b)/fuel; (c)
  refusals (switches — Q7; concurrency — "not supported; the oracle's
  mode is non-functional at b9aeedcb4", the `feature/concurrency` branch
  noted; CerbFS = served-as-SibylFS or refused-loud, 25 ops, op table
  pointer; `LEAN_ABORT_ON_PANIC`; `runND` Q8 = A; the accepted CLI incl.
  `--fuel`); (d) pointer; **Still open** (Z-28 → Z3 not landed; Z1-A1
  libc-body loc mover; Z2-M-01 aligned_alloc pending + tray 34; the
  typed-failure pass scheduled + the in-process consumer note; Z-40,
  Z-42/Z-75 instruments → code half of Z4); oracle-suspect rows are
  correct under the rule, `PINNED_TRAY_<n>` owed.
- **§4–§6** = the former §1–§3 (what is compared; lanes; gates), text
  kept; lane table refreshed where verified this slice: `test_verify`
  127 checks (Z2 record §14), `test_ci_sweep` row now says the TSVs
  predate Z1/Z2 and the re-record is owed, `test_csmith_corpus` row
  carries the derived 1161/499/9 tallies; internal §-references updated.
  The gate table already listed `check_fuel_forms`,
  `check_no_fuel_numerals`, `check_lakefile_roots`,
  `gen_fuel_parametricity --check` (C1–C3) — unchanged.
- **§7 Fuel** — the former §5 fuel bullet promoted to a section, text
  kept (the (A)/(B)/(C) table at 47/13/15/6 = `fuel_forms_pending.txt`'s
  15 rows), its "ruling's frame" sentence now points at §0/§1 instead of
  restating two classes.
- **§8 How often** = the former §4.
- **§9 What this does and does not establish** — claim 1 rewritten so
  every recorded difference is one of: register pin / class-(a) pair /
  class-(b)/(c) row / open bug with owner ("There is no other kind of
  recorded difference"); claim 5 (fuel) added; the runtime-seam list kept
  with `CerbGlobal` re-classified (c); the "declared MODEL boundary"
  paragraph DELETED and replaced by "There is no other declared
  boundary" + pointers.
- Deleted phrasings: "declared MODEL boundary", "temporal, the cmm
  instantiation is the mover", "never fix-to-match" (already gone since
  Z1), "DELIBERATE divergence" (none remained). `grep -n "declared
  boundary\|never fix-to-match\|DELIBERATE" VALIDATION.md` → only the §0
  sentence that says those words are history.

`scripts/LADDER.md:69` (Tier C, `test_csmith_corpus.sh`): "15 DIFF are the
F-D fork-oracle class" → rewritten from the baseline file at
`928aa1e76`: no MISMATCH/DIFF/UB_DIFF row; 1161 MATCH / 499 `CERB_SKIP` /
9 `TIMEOUT` (derived; the file's own 2026-08-22 header narrates the
arc-13 numbers 1160/8/2 and a later 2 TIMEOUT → MATCH movement — the
header is history, the rows are the state), with the class-(b) note.

## 4. Provenance and integrity notes

- Verbatim: every engine line in the drafts and in §2 is pasted from the
  2026-09-05 runs (`.tmp/z4/results-nolibc.log`, `results-libc.log`,
  `lean4-02.log`, the `up.sh` outputs — ephemeral); tallies are labelled
  derived. Where a draft quotes a `--pp=core` fragment it says which
  binary printed it.
- Provenance: the rulings are [USER 2026-09-03] as recorded in the cited
  docs; the R3 class admission is the orchestrator's [AGENT] reading of
  the referent ruling (ruling doc "Consequences [AGENT] put to the
  operator") relayed as this slice's brief — VALIDATION.md §2 says so
  rather than presenting it as a [USER] ruling. All draft classifications
  and the INDEX ranking slots are [AGENT].
- The tray drafts avoid this project's internal vocabulary (no census
  ids, no class letters, no slice names in the bodies); provenance
  sections point at record files by path.
- Nothing in the primary checkout, `deps/`, or any other worktree was
  modified: the primary's binaries and `deps/cerberus-upstream`'s were
  executed read-only; the libc jsons were written under this worktree's
  ignored `.tmp/`.

## 5. What the CODE half of Z4 still owes (unchanged by this slice; pointers)

1. **Probe integration into the lanes** (charter §4.2): the ~78 3-way
   AGREE probes into the exec/libc_exec corpora, the 12 agreed-UB probes
   as UB_MATCH, the 13 oracle-suspect reproducers as MATCH pins with the
   tray cross-reference in the probe header, the both-crash pairs
   (`float_nan_to_int_ub.c`, `lib_printf_star_width.c`) as immaculate
   `MATCH | L=CRASH`, and the gcc lane's NEW class **`PINNED_TRAY_<n>`**
   (confirmed shared-source oracle bug with a draft; flips to AGREE on
   the upstream fix, any other movement is a regression) — amend
   `docs/2026-08-30_gcc-second-oracle-design.md` §4 and the acceptance
   lists `scripts/test_gcc_oracle.sh:229` and `:592`
   (`TRIAGED_ADDR|TRIAGED_FLOAT|TRIAGED_UB|TRIAGED_ORDER`); the F1
   witnesses stay `TRIAGED_FLOAT` (Q6). The `zd-d5` `TRIAGED_UB` row's
   provisional status (Z1 record §7 item 10): decide `TRIAGED_UB` vs
   `PINNED_TRAY` once a device-ranges draft exists (none drafted here —
   not in the brief's list; charter Z-06 calls it a tray QUESTION).
2. **`test_ci_sweep.sh` re-record** (Z-42/Z-75; TODO.md "Tier-C ci-sweep
   re-record"): a dedicated instrument commit on fresh stamped binaries;
   tripwire justification written in advance (hours of wall). Rule: a row
   surviving as `CERB_INCONSISTENT` is a bridge-attribution question.
   Expect `UB_DIFF` rows from Z1-A1 (libc-body locations) and movement on
   `stat.c`/`cat.c` (CerbFS refusals), the 6 pnvi rows (until Z3), the
   Z-30 rows.
3. **Defined-line stdout widening in `test_exec.sh`** (Z1 record §7 item
   5): `VAL:` keeps only the Defined VALUE today; widen to the whole
   Defined line so a stdout difference is a `MISMATCH`.
4. **`cerb_skip` ceiling** (Z1 record §7 items 2 and 6): default mode does
   not fail on `UB_DIFF` (only `--check-baseline` does — every gate row
   uses it, so no gate is fail-open), and a half-skipped run under
   contention reads green because `CERB_SKIP` is non-fatal; add a ceiling
   (fail if `cerb_skip` exceeds the baseline's count).
5. **The libc-body UB-location mover** (Z1-A1): a libc pin vehicle that
   carries locations (a `--pp=core` variant emitting locations, or a Lean
   reader of the marshalled `.co`); S–M.
6. **The two stale `lembugs` cites in gated files**:
   `scripts/exec_float_baseline.txt:8,14` and `lean_frontend/CerbFloat.lean:41`
   still cite `lembugs/2026-08-19_upstream-float-mul.md` (a path that no
   longer exists; the finding is tray draft 01 / issue #1009) and
   `CerbFloat.lean:40` still carries the "DOCUMENTED-DELIBERATE DIVERGENCE"
   wording that the rule revoked — re-cite to tray 01 and reword as a
   mirror of the referent (`Cerb_floating.mul` is a kind-2-adjacent
   upstream defect in the OCaml runtime library; Lean multiplies).
   `exec_float_baseline.txt` is a Tier A gated file: dedicated instrument
   commit with header justification.
7. **Z2-J-01 / Z2-J-02 bridge fixes** (Z2 record §10 item 2): the
   fail-closed remedies in `backend/lean_export/cabs_json.ml` (a
   fork-drift-manifest surface) — with the manifest re-pin.
8. Also owed and pointed at from VALIDATION.md §2/§3: the R3 `-- ISO-fix
   register R3` marker in `CerbMem.lean` and the register↔marker
   bijection gate (charter (vii)); Z-40 (`ppCoreSignature` main-file
   filter); the Z-31 per-row completion measurements (9 csmith TIMEOUT +
   11 gcc SKIP_LEAN_TIMEOUT); the Core-level differential lane TODO entry
   (charter §4.2 last row); `tests/immaculate` header wording is already
   register-citing (Z1) — no change needed.
9. Operator decisions this slice surfaces (no action taken): draft 31's
   hold (lift or keep); the aligned_alloc logical meaning (Z2 record
   §10.1 — the tray draft states both C11 and C17 readings); whether
   draft 35's fifth observation (float literals unparseable) merits its
   own draft or rides the pp-roundtrip branch.

## 6. Commits on `docs/z4-tray-validation` above `928aa1e76`

1. `zero-discrepancy Z4 (docs, 1/2): upstream tray drafts 20-35 + tray-10
   addendum + lean4/02; INDEX/README` — 16 new drafts, the addendum, the
   lean4 draft + `lean4/repro/DivModLiteralFold.lean`, INDEX.md, README.md.
2. `zero-discrepancy Z4 (docs, 2/2): VALIDATION.md trust-story rewrite
   (four aims, the rule, exception classes + tests, register R3 by class,
   census summary, fuel §7), LADDER.md:69, this record`.

## 7. Rebase onto `eb27fa70f` (2026-09-05, coordinator request)

Mainline moved `928aa1e76` → `eb27fa70f` (`CerbGlobal` step 1: the
config/switch surface becomes plain `def`s of the default configuration;
opaque-boundary census rows 26 → 15, `unsafebaseio_allowlist.txt` PIN
rows 66 → 37; `docs/2026-09-05_cerbglobal-defs-record.md`). `git rebase
mdd/cerberus-lean`: commit 1/2 applied cleanly (mainline touched no tray
file); commit 2/2 conflicted in ONE hunk of `lean_frontend/VALIDATION.md`
only (this slice never edited `TODO.md`/`CLAUDE.md`, so mainline's edits
there came through untouched):

- the runtime-seam bullet for `CerbGlobal` (§9): mainline's "LEFT the
  boundary 2026-09-05 … eleven reads are now plain `def`s … step 2 a
  separate slice" vs this slice's "class (c): flags refused, plumbing
  not wanted". RESOLVED keep-both: mainline's facts in this slice's
  framing (the surface left the boundary; the switch FEATURE stays class
  (c) under Q7; `using_concurrency`'s step 2 belongs to the concurrency
  feature branch).
- the gate-table row for `check_theorem_axioms.sh` merged automatically
  with mainline's text: "15 registered rows since 2026-09-05 — … the 11
  `CerbGlobal` config/switch opaques left the census when they became
  plain `def`s".
- consequential edit (no conflict): §3 (c) *Semantics switches* no
  longer says "`CerbGlobal`'s switch set is permanently empty"; it now
  says the surface is eleven plain `def`s of the DEFAULT configuration
  (kernel-transparent, `rfl` lemmas), every `Switches.has_switch` read
  evaluates as the oracle's default by definition, and `using_concurrency`
  is `def … := false` with `using_concurrency_eq … := rfl`, its
  parameterisation owned by the concurrency feature branch; the §9 lead
  sentence says `CerbGlobal` "left the list 2026-09-05".

Numbers that changed in VALIDATION.md through the rebase: the opaque
census 26 → 15 (gate row, from mainline). Nothing else in this document
carried the old 26 or the PIN count 66. The reproducer runs of §1–§2 were
made on binaries built from `928aa1e76`; the CerbGlobal slice's battery
recorded 0 movement (`eb27fa70f`), and none of the probes here touches a
switch, so the quoted lines stand. Post-rebase re-read of VALIDATION.md
end to end: §-references (§0–§9) consistent, R1–R3 rows intact, fuel
table 47/13/15/6 intact, no conflict marker, no stale phrasing.
