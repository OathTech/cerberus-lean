> RESTORED 2026-09-02 [AGENT; ruling USER 2026-09-02, release-hygiene item 1]: VERBATIM from tag `park/reasoning-era-20260831` (`lean_frontend/docs/reasoning-era/2026-08-21_grumpy-audit-cerberus-semantics.md`), because live gates cite it — `scripts/test_immaculate.sh` / `tests/immaculate/baseline.txt` cite its G1–G6 register as the finding→row map.
> Historical record of the reasoning era (a container-side note at the time; first committed at the park). Wording, cites and line numbers are as written then; the body below is unchanged.
> Record: `lean_frontend/docs/2026-09-02_release-hygiene-record.md` §G2.

# Grumpy-professor audit: the cerberus-lean SEMANTICS artifact

Date: 2026-08-21. Auditor: read-only code-quality worker (grumpy-PL-professor
persona), scope per mission: hand-written seams in
`cerberus-lean/lean_frontend/`, generated-code conventions (backend OUTPUT
only), the fork's `frontend/model/*.lem` deltas, and `native/` shims.
Out of scope: `relsem/` (sibling audit), the lem backend's internals.
Comparison baselines: `deps/cerberus-upstream` @ merge-base `b9aeedcb4`
(impl_mem.ml, decode.ml, ocaml_gcc_builtins.ml, driver, pp_*), the .lem model's
own house style, and Std/mathlib-adjacent Lean idiom.

Operator clarification (mid-audit, [USER]): weight SEMANTIC fragility —
constructions whose correctness rests on accidents rather than stated
invariants — above style. Severities below follow that rule: a semantically
fragile construction that currently works is SERIOUS; a silent wrong value or
a fail-path-turned-value-path on reachable input is GRAVE; style-only items
are NITs. Everything here is recommendation only; zero fixes were applied.

Method: full reads of all 21 hand-written seam files + Main + native/*.c;
line-by-line comparison of ~10 seam function families against their cited
OCaml; samples of `generated/` (Symbol, Ctype, Core_run_aux, Formatted,
Mem_common); the cumulative `upstream/master..mdd/cerberus-lean` model diff
(leaning on notes/2026-08-21_fork-drift-review.md for the drift ground truth);
greps for partial/panic/instance censuses. No builds were run.

---

## 1. Findings register

Format: id | severity | category | location | finding | remedy price
(S = hours, M = days, L = a slice/arc).

### GRAVE — silent value where the oracle fails, or wrong value on reachable input

- **G1 | GRAVE | MIRROR | CerbMem.lean:1697-1708** — `ltPtrval`/`gtPtrval`/
  `lePtrval`/`gePtrval` silently return `false` for null/function/mixed
  pointer operands where upstream `lt_ptrval` et al. FAIL with
  `MerrWIP "lt_ptrval ==> one null pointer"` (impl_mem.ml:1886-1955): a
  kill-path became a value-path, so a C program comparing `p < NULL`
  continues executing down a branch the oracle never reaches — and these
  four functions carry NO impl_mem citation and no divergence note, in a
  file where every neighbour has both. Remedy: mirror the fail arms +
  add a differential test; **S**.
- **G2 | GRAVE | MIRROR | CerbMem.lean:1846-1870** — `memcpyM`/`memcmpM`
  copy/read raw bytemap bytes, bypassing the load/store machinery that
  upstream memcpy/memcmp deliberately route through (impl_mem.ml:2635-2665
  implements them as per-byte checked `load`/`store`): OOB memcpy, memcpy
  INTO a read-only or dead allocation, and memcmp of unspecified bytes all
  silently succeed here while the oracle kills (or, for memcmp on an
  unspecified byte, hard-crashes on its own `assert false`). Uncited,
  undocumented. Remedy: reimplement as checked per-byte load/store like the
  oracle (this also fixes realloc's copy path for free); **M**.
- **G3 | GRAVE | MIRROR | CerbMem.lean:1888-1891** — `reallocM` kills with
  `MerrUndefinedFree` where upstream uses `MerrUndefinedRealloc`
  (impl_mem.ml:2677-2681); the fail mapping sends these to DIFFERENT UB
  codes (UB179a/b vs UB179c/d, Mem_common `undefinedFromMem_error`), so any
  realloc-misuse test prints a differentially WRONG `Undefined {ub: ...}`
  line — and the in-code comment even asserts "these surface as UB179a/b",
  a miscitation directly under an impl_mem.ml:2668-2696 cite. The corpus
  evidently has no realloc-UB test; that is the only reason this is green.
  Remedy: one-constructor fix + a differential test; **S**.
- **G4 | GRAVE | MIRROR | CerbUtils.lean:97-144** — the GCC builtins do not
  mirror `ocaml_gcc_builtins.ml`: `gcc_builtin_generic_ffs` clamps negatives
  via `Int.toNat` so `ffs(-1) = 0` where the oracle's
  `Z.trailing_zeros` two's-complement semantics gives 1 (`__builtin_ffs`
  takes a signed int — a negative argument is well-defined C); `ctz 0`
  returns 64 where the oracle `assert`-crashes; the bswaps silently
  mask/wrap where the oracle asserts range. Silent wrong values on reachable
  inputs, with vague "Corresponds to" comments and zero line citations.
  Remedy: re-mirror on Z semantics, document the assert arms; **S**.
- **G5 | GRAVE | MIRROR | CerbDecode.lean:46-76** — `decode_character_constant_aux`
  is fail-OPEN where upstream decode.ml:41-200 is an exhaustive,
  fail-CLOSED, §5.2.1/§5.2.2/§6.4.4.4-cited table: `'\?'` (legal C) decodes
  here to 0 via `readDigit`'s silent-0 default (oracle: `failwith`);
  multi-char constants return the first char's code (oracle: `failwith`);
  empty input returns 0 (oracle: `failwith`); invalid hex/octal digits fold
  in as 0 instead of being validated. The C-standard citations upstream
  carries were dropped wholesale. Remedy: port the table + validation
  faithfully, restore the STD cites; **M**.
- **G6 | GRAVE | THEORY | CoreParser.lean:190-191 (+ native/fresh_int.c:26-28)** —
  `mkSym name := Symbol "" name.hash.toNat (SD_Id name)`: Core-text symbol
  IDENTITY is a 64-bit string hash, i.e. probabilistic injectivity with no
  collision tripwire — the comment above it even claims "distinct names get
  distinct numbers", which is not a theorem, and fresh_int.c openly prices
  the residual risk as "(im)probable". After the F-D family (three members,
  drift review §4) this is the fourth construction in the symbol-identity
  lane whose soundness is a margin, not an invariant. The fix is cheap: an
  intern-time duplicate-(digest,num)-with-distinct-name detector that
  fail-stops, exactly like the CERB_FRESH_BASE floor probe. Remedy: **S**.

### SERIOUS — semantic fragility, accident-scoped correctness, load-bearing divergence argued weakly or not at all

- **S1 | SERIOUS | THEORY | CerbMem.lean:142-179** — the equality/order
  instances on the memory model's core types are degenerate or coarse with
  NO in-file documentation: `BEq PointerValueBase` calls any two `PVnull`
  equal (OCaml `(=)` compares the ctype); `beqMemValueSafe` compares
  `MVstruct` by tag ONLY (members ignored; ity/fty/ctype payloads ignored
  elsewhere) behind an `unsafe`+`implemented_by`+`opaque` sandwich the
  kernel cannot see; `BEq Allocation`/`BEq MemState` are constant `false`;
  `Ord PointerValue`/`Ord MemValue`/`Ord MemState` are constant `.eq`. Any
  generated set/map/dedup over these types silently diverges from OCaml
  polymorphic compare. The ONLY statement of this caveat lives in a
  DIFFERENT file (CerbStepInstances.lean:84-94, "stated not fixed"), scoped
  to one call site, enforced by a comment asking future readers to
  "re-audit". Mirror doctrine: undocumented divergence = defect, and this
  is eight of them in the model's most central types. Remedy: OCaml-parity
  structural instances or loud `failwithI` arms, each with a reachability
  note, caveat moved into CerbMem; **M**.
- **S2 | SERIOUS | GENSTYLE | generated/Symbol.lean:52-77 (pattern
  tree-wide)** — the backend emits, in the same module, an automatic
  `Eq0/SetType identifier` derived from `deriving BEq, Ord` (which compares
  the LOCATION field) and, later, the model's own `Eq0/SetType identifier`
  instances (name-only, per symbol.lem) — two semantically DIVERGENT
  instances for one type/class, disambiguated solely by Lean's
  "most-recently-declared wins" rule, with no `(priority := low)` on the
  automatic one (the backend demonstrably knows the mechanism — it uses it
  for Inhabited, e.g. AilSyntax.lean:731). Location-sensitive identifier
  comparison is precisely the historical bug class (cf. the offsetof_ival
  fix note, CerbMem.lean:944-949). Correct today by emission ORDER; a
  semantic accident by construction. Remedy: emit auto instances at low
  priority (backend change — hand to the sibling audit) ; **S**(spec)/**M**(impl).
- **S3 | SERIOUS | PRACTICE | CerbLocation.lean:38-39** — `Ord Loc` compares
  `(repr a).pretty` STRINGS ("needed by generated code (e.g. Undefined.lean
  uses Loc in sets)"): set/map iteration order over locations is the
  lexicographic order of pretty-printed Repr text (line 10 sorts before
  line 9), which matches no OCaml comparator and is O(n·|repr|) per
  comparison. Any output that enumerates a Loc-keyed set can order
  differently from the oracle. Uncited, unargued. Remedy: structural
  comparator mirroring Cerb_location's; **S**.
- **S4 | SERIOUS | PRACTICE | CerbCtypeInstances.lean:22-26** — `Ord ctype`
  is `if ctypeEqual a b then .eq else .lt`: not antisymmetric, not
  transitive — an unlawful order ("not a true ordering, but sufficient to
  prevent sorry panics", says the comment, in 2026, in a repo whose arc-10
  standard is OCaml-poly-compare-parity-or-loud-failwithI). Any
  ctype-keyed ordered structure built through it is insertion-order
  dependent. Remedy: real structural compare or failwithI honesty, matching
  the CerbFunMapInstances register; **S**.
- **S5 | SERIOUS | MIRROR | CerbMem.lean:1921-1922** — `updatePrefix` is a
  silent no-op where upstream (impl_mem.ml:1349-1362) really updates the
  allocation's prefix and warns on bad arguments; the prefix is
  semantically LIVE downstream — `storeM`'s is_locking arm selects the
  readonly KIND from `alloc.prefix_` (CerbMem.lean:1573-1577), so a
  prefix-then-lock sequence can emit a different UB class than the oracle
  (UB033 vs UB064 vs temporary-lifetime). Undocumented. Remedy: implement
  or document unreachability with evidence; **S**.
- **S6 | SERIOUS | MIRROR | CerbMem.lean:1119-1121** — `bytefromint` wraps
  (`n % 256`, euclidean) where upstream ASSERTS `0 ≤ n ≤ 255` and returns
  the value unchanged (impl_mem.ml:2775-2781); `intfrombyte` drops the
  assert entirely. Crash-path→value-path, uncited, in a file that
  elsewhere cites every arm. Remedy: mirror + cite; **S**.
- **S7 | SERIOUS | MIRROR | CerbMem.lean:313-315, 361-362** — `sizeofCtype`
  returns 0 for Void/incomplete-Array/Function and `alignofCtype` returns 1
  where OCaml `assert false` (impl_mem.ml:133-135): documented, but the
  entire argument is "Divergence kept from the pre-existing code" — that is
  provenance, not a rationale. A 0-sized/1-aligned value flowing onward is
  the quintessential panic-optimized-into-value hazard (0-sized
  allocations, degenerate layout arithmetic) on inputs where the oracle
  stops the world. Remedy: panic like the neighbours, or write the actual
  unreachability argument; **S**.
- **S8 | SERIOUS | MIRROR | CerbMem.lean:1115** — `memberShiftPtrval` on a
  function pointer returns the pointer UNCHANGED with the comment
  "undefined per OCaml, but return unchanged": a self-confessed
  fail→value divergence with no analysis of reachability. Remedy: panic or
  argue; **S**.
- **S9 | SERIOUS | THEORY | CerberusImpl.lean:24-32, 86** — `typeof_enum`
  is a stub returning `Signed Int_` for EVERY enum (documented, survey
  finding 18b) — but the safety envelope is "nothing in tests/minimal
  declares such an enum", i.e. corpus accident: upstream registers
  `Unsigned Int_` for all-nonnegative enumerators
  (ocaml_implementation.ml:144-150), so signedness/max/min of such enums
  are wrong here today. Compounding the shape problem, `sizeof_ity` at :86
  answers `Enum0 _ => some 4` directly instead of routing through
  `typeof_enum` as upstream does — currently coincidentally equal, will
  silently NOT track the registry when the registry lands. Remedy: port the
  registry (a native/ ref-cell like tags.c, already the house pattern);
  **M**.
- **S10 | SERIOUS | THEORY | CerbGlobal.lean:49-53** — the mutable config
  is `private unsafe def confRef : IO.Ref ... := unsafeBaseIO (IO.mkRef _)`
  — a top-level pure `def` allocating a ref, without Lean's `initialize`
  idiom and WITHOUT the `@[never_extract, noinline]` armour that CerbTags/
  CerberusFresh lovingly justify for exactly this hazard class: if the
  compiler ever inlines the closed body, every read gets a FRESH ref. It
  works today because nothing ever writes these refs (no setter exists in
  the repo — which itself deserves a comment: `current_execution_mode` is
  permanently `none`). Two armouring disciplines for one hazard class is a
  semantic accident waiting for a compiler upgrade. Remedy: converge on the
  native-C-global pattern or `initialize`; **S**.
- **S11 | SERIOUS | PRACTICE | CerbDebug.lean:27-31 + Main.lean:1032** —
  `get_level`/`set_level` lack the `never_extract` armour (contrast
  CerbTags.lean:42-61's explicit hazard note for the same shape), and
  Main.lean:1032 sets the level via `let _ := CerbDebug.set_level (...)` —
  the EXACT discarded-pure-result pattern the codebase's own arc-4 S3b
  record documents as dead-code-eliminated (see the in-file warnings at
  Main.lean:545-549 and 789-791 telling people to use the BaseIO variant
  for this very reason). The human-mode debug level is thus plausibly never
  set at all. One rule, three enforcement levels, in one repo. Remedy:
  BaseIO call + armour; **S**.
- **S12 | SERIOUS | MIRROR | CerbDecode.lean:86-96 (+ generated/Formatted.lean
  store_chars_in_array)** — `escaped_char` emits `\xNN` HEX escapes while
  claiming "(= Char.escaped in OCaml)", which emits `\ddd` DECIMAL — and
  this divergence is LOAD-BEARING: formatted.lem's `store_chars_in_array`
  round-trips every printf-stored char through
  `decode_character_constant (escaped_char c)`, where upstream's decimal
  `\ddd` is then read back by decode's OCTAL path (decode.ml's octal
  validator even accepts '8'), i.e. the oracle plausibly CORRUPTS
  non-printable chars on this path while the Lean hex round-trip is exact.
  Nobody has analyzed this pair; the comment actively miscites. Whether
  Lean-right/oracle-wrong (a floatMul-class upstream bug to record) or
  unreachable, the mirror doctrine demands the analysis in writing.
  Remedy: analyze + document (+ likely a lembugs/notes/upstream entry);
  **S**.
- **S13 | SERIOUS | PRACTICE | CerbFS.lean:108-138, 183-202** — the fs model
  is internally incoherent: `fs_lseek` faithfully maintains per-fd offsets
  that `fs_read`/`fs_write` then IGNORE (read always from byte 0, write
  always appends; `fs_pread`/`fs_pwrite` "Simplified: ignore offset");
  `fs_open` ignores flags (no O_TRUNC), so reopen-and-write appends.
  A seek-then-read program gets silently wrong DATA. The header's
  "sufficient to run C programs with basic file I/O" oversells; per-function
  divergence notes are absent (contrast the enumerated-residual discipline
  of CerbPP). Remedy: implement offsets or make seek-dependent ops fail
  `enosys` loudly, and write the divergence table; **M**.
- **S14 | SERIOUS | MIRROR | CerbUtils.lean:57-67** — `bounded_integer`
  (lem's `Cerb_any.bounded_integer`, linked into core_run) deterministically
  returns `lo` where the oracle draws `Random.int64` in [lo,hi]; the only
  documentation is "can be replaced with real RNG". No statement of which
  call sites exist, why the divergence is unobservable in exhaustive mode,
  or what the single-trace differential story is. Remedy: document the
  envelope (or thread it through the ND fork like eqPtrval's msum); **S**.
- **S15 | SERIOUS | THEORY | CerbND.lean:6-14, 115-124** — no constraint
  evaluation: NDguard always continues and NDbranch explores both sides,
  where the CONCRETE oracle's cs_module really does eval_cs/check_sat and
  PRUNES (impl_mem.ml:321-361). Recorded (survey finding 23) and honestly
  framed — but it is a standing semantic gap in the ND runner, not a
  stylistic one: enumerated behaviors can strictly exceed the oracle's on
  any program whose guards are falsifiable, and "the corpus hasn't hit it"
  is the only fence. The recording keeps it out of GRAVE; its age argues
  for scheduling. Remedy: port eval_cs over mem_constraint (pure,
  self-contained); **M**.
- **S16 | SERIOUS | PRACTICE | CerbStepInstances.lean:66-73,
  CerbFunMapInstances.lean:44-49** — the instance-override mechanism is
  import-scoped: "any NEW use site in another generated module must also
  extra_import this file, or it will silently get the sorry fallback".
  Equality SEMANTICS of core_step2 depend on an import list maintained by
  hand; the tripwires (axiom gates) catch the sorry variant but nothing
  catches a future real-but-divergent generated instance winning by
  resolution order (cf. S2). Also: both files' framing ("sorry instances
  remain at priority low") predates arc-10's derived-comparison rework —
  the mechanism notes need a post-arc-10 accuracy pass. Remedy: re-verify +
  re-document; consider backend-level instance suppression per demand
  site; **S**.
- **S17 | SERIOUS | THEORY | CerbTags.lean:38-71, CerberusFresh.lean:71-113,
  generated/Symbol.lean:299-307** — the effect-erasure seams give
  PURE-typed signatures to reads of mutable native state (`tagDefs ()`,
  `digest ()`, and via `runEffectful` the fresh counter): in the logic,
  `tagDefs () = tagDefs ()` and two syntactically identical fresh draws are
  provably equal, while the runtime disagrees across set/reset boundaries —
  the classic unsafePerformIO referential-transparency breach. The
  per-site armour and its rationale are excellent (best-documented corner
  of the artifact), and the axiom census pins with_tagDefs/forceIO — but
  the SOUNDNESS INVARIANT ("no proof may relate values of these
  applications across different ambient states; theorem statements must not
  mention them"; how the statement-TCB gate enforces it) is nowhere stated
  as a single normative rule — it is distributed across four file comments
  and an arc doc. For a POPL-grade artifact this deserves one page, stated
  once, cross-referenced everywhere. Remedy: write the invariant section
  (docs/), point every seam comment at it; **S**.
- **S18 | SERIOUS | LEM | frontend/model/cabs_to_ail_effect.lem:228-232** —
  the `fresh_sym_supply` field comment still frames the threading as
  Lean-only ("OCaml-side target_reps can still use Cerb_fresh.int via the
  old API") — the same false-neutrality framing as commit `8923d6436`'s
  message, which the drift review (§4/S1, O6) has already shown to be wrong:
  the migrated sites bypass Cerb_fresh.int on BOTH targets. The .lem
  comment should state the truth the drift review established, and
  cross-reference the margin analysis (native/fresh_int.c) + the registered
  oracle-side mover. The stylistic siblings the mission asked about exist:
  core_run_aux.lem:233-244's conceded non-escape obligation (O1, still
  undischarged) and the SeqRMW "absorbed by the id-insensitive ruling"
  framing (O4) — all three concede obligations in prose that no gate
  discharges. Remedy: comment corrections + keep the drift-gate manifest
  authoritative; **S**.

### NIT — style, hygiene, small honesty debts

- **N1 | NIT | GENSTYLE | generated/*.lean** — the emitted Lean is
  transliterated OCaml with no line-breaking: single 2,000+-character
  `def`s (Core_run_aux.lean:415), `String.append` chains instead of `++`,
  erratic double-spacing, nested `match` where a two-pattern match would
  do. Lem's OCaml output is no beauty either (parity argument accepted),
  but a Lean reviewer asked to certify `generated/` as legible output would
  wince; diffs and error messages suffer. Remedy: an emitter
  pretty-printing pass (sibling audit's lane); **M**.
- **N2 | NIT | GENSTYLE | generated/Symbol.lean:98-121** — the lem `digest`
  abbreviation lands instances on ALL of `String` (`Eq0 String`,
  `Ord0 String`, `Show String := string_of_digest`): globally polluting a
  stock type with digest semantics. Benign while digest = identity-hex;
  fragile if the rep ever changes. Remedy: newtype the digest on the Lean
  side; **M**.
- **N3 | NIT | GENSTYLE | generated/*.lean:1** — generated headers say only
  "Generated by Lem from X.lem" — no DO-NOT-EDIT warning, no lem
  version/commit. Given the hand-written→generated cp workflow (files with
  the SAME names exist in both places), a DO-NOT-EDIT-HERE marker on the
  copied hand-written files' generated twins is cheap insurance. **S**.
- **N4 | NIT | PRACTICE | lean_frontend/CLAUDE.md ("must be copied")** —
  the hand-written↔generated mechanism is `cp` + a sync gate in
  test_unit.sh. The gate makes it sound; the mechanism still leaves a
  silent-stale window inside any dev loop that doesn't run the gate, and
  `srcDir = "generated"` plus same-named files is a foot-seeking mechanism
  design. Not embarrassing — gated — but a lakefile-level solution (extra
  source dir) would delete the failure mode. **M**.
- **N5 | NIT | PRACTICE | CerbConcurrency.lean:22-29** — comment rot: "The
  actual ndM monad wiring will use sorry"/"all behaviour functions are
  sorry" in a file containing one function and in a repo where sorry is
  banned and DAEMON was ceremonially executed. The declared TEMPORAL
  boundary deserves an accurate comment. **S**.
- **N6 | NIT | PRACTICE | CerbUtils.lean:9-41** — `begin_timing`/`end_timing`
  are no-ops beneath a comment claiming "We use Lean's IO for the same
  purpose"; `timingStackRef` is dead; `STD_` logs into a ref nothing reads.
  Comments describing code that does not exist are record-integrity debt.
  **S**.
- **N7 | NIT | PRACTICE | Main.lean:956-1000** — hand-rolled, order-sensitive
  CLI: `--batch` must be argv[0], `--first` must follow it, `--parse-core`
  is tested against raw `args`; a misordered flag silently becomes a
  filename. The oracle uses cmdliner. Fine for a harness binary; document
  the order contract at least. Also the `--stdin` read loop is duplicated
  (:290-297 vs :1054-1061). **S**.
- **N8 | NIT | PRACTICE | CerbFloat.lean:10-11** — `Ord Float` yields `.gt`
  for ALL NaN comparisons including `compare nan nan` (irreflexive!),
  diverging from OCaml's total `compare` (nan = nan → 0). Harmless until a
  float keys a set. **S**.
- **N9 | NIT | MIRROR | CerbLocation.lean:137-142** — `isLibraryLocation`
  matches any path SEGMENT named `include`/`libcore`/`impls`
  (`/home/include/foo.c` is "library"); the approximation is documented but
  the false-positive envelope is not. **S**.
- **N10 | NIT | PRACTICE | native/tags.c:57-72** — `cerb_tags_with` restores
  the saved map only after `lean_apply_1` returns; a panicking `f` (Lean
  panics return `default`, they don't unwind, so this is fine today) is the
  only reason the non-exception-safety is moot — worth one comment line.
  Similarly debug.c's `lean_unbox(n)` silently garbles a boxed big Nat
  level (unreachable; say so). **S**.
- **N11 | NIT | MIRROR | CerbDecode.lean:12-17** — `readDigit` returns 0 for
  invalid digit chars; upstream's `read_digit` computes garbage
  (`int_of_char n - 48`) instead. Garbage-for-garbage on lexer-guaranteed
  input — acceptable, but the Lean side should say why it may be laxer
  where G5's table is fixed. **S**.
- **N12 | NIT | PRACTICE | 316 `partial def`s in generated/ + 135 in
  CoreParser/CabsImport** — the partial residue outside the totalized slice
  is fenced by a module-allowlist gate, not per-def justification. As a
  boundary it is principled (parsers and dead defacto code); as
  documentation it is thin — a one-paragraph "why the residue is safe"
  note in the results docs would close it. **S**.
- **N13 | NIT | GENSTYLE | generated/Ctype.lean** — keyword collision
  handled by a single `«def»` guillemet; fine, but the backend should
  prefer renaming in a proof-facing artifact (guillemets poison every
  downstream mention). **S**.
- **N14 | NIT | PRACTICE | CerbPP.lean:26** — `ppAny := "<...>"` is a
  residual generic escape hatch alongside the enumerated placeholder
  register; every use should be one of the enumerated, reasoned entries.
  **S**.

---

## 2. Mirror-fidelity sampling (dimension 2 verdict)

Sampled against cited OCaml, side-by-side:

| Function family | Isomorphism grade |
|---|---|
| offsetsof/sizeof/alignof (impl_mem.ml:98-273) | **A−** — same fold shapes, same case order, per-arm line cites; the one refactor (memberAlign, repeated inline 3× upstream) is documented |
| eqPtrval (impl_mem.ml:1830-1881) | **A** — arm-for-arm incl. the msum ND fork, with the not-ported switch branches fenced and argued |
| loadM/storeM (impl_mem.ml:1552-1789) | **A−** — dispatch order preserved; do_load/do_store as inner lambdas mirror OCaml's; the upstream LoadAccess copy-paste quirk at :1772 mirrored AND flagged |
| memValueToBytes / repr (impl_mem.ml:1139-1220) | **A** — funptrmap threading preserved |
| reconstructValue / abst (impl_mem.ml:916-1095) | **B** — deliberately reshaped (slice-based vs consume-rest), documented as an INVARIANT note; a reviewer can no longer diff side-by-side, the acknowledged maintenance cost |
| relational ptr ops, memcpy/memcmp, realloc, bytefromint, update_prefix | **F** — see G1-G3, S5, S6: not isomorphic, divergent, largely uncited |
| Main driver vs driver_ocaml.ml/main.ml | **A−** — fold order, link order, batch format, exit codes all cited; deviations enumerated |
| CoreParser vs core_parser.mly | **C+** — different technology (Parsec), inherently non-isomorphic (acceptable); error positions weaker than menhir's, symbol identity by hash (G6) |

The register is bimodal: where a function was worked in arcs 4-10 the mirror
craft is genuinely excellent; the pre-arc residue (the F row) is
indistinguishable from prototype code and carries none of the doctrine.

## 3. Synthesis — top-10 remediations for an "immaculate semantics" arc

1. **Close the impl_mem F-row** (G1+G2+G3+S6+S8+S5): re-mirror relational
   ptr ops, memcpy/memcmp (as checked per-byte load/store), realloc's error
   constructors, bytefromint, update_prefix — each with citations and new
   differential tests (realloc-UB, null-relational, memcmp-uninit,
   locked-store-after-update_prefix). One slice, highest yield.
2. **Symbol-identity tripwires** (G6 + drift-review mover): intern-time
   duplicate-(digest,num) fail-stop in CoreParser + the registered oracle-side
   `cerb_fresh` floor; retire the last margin-based identity argument.
3. **decode/builtins re-mirror** (G5+G4+S12): port decode.ml's cited
   fail-closed table, fix the builtins on Z semantics, and write the
   escaped_char/octal-round-trip analysis (likely an upstream bug report).
4. **Instance-hygiene sweep** (S1+S4+S3+N8): every hand instance on model
   types is either OCaml-poly-compare-parity or loud failwithI, documented
   in-file, with the CerbStepInstances caveat relocated to CerbMem; kill the
   repr-string Ord Loc and the unlawful Ord ctype.
5. **Backend: no duplicate divergent instances** (S2, hand to sibling):
   automatic Eq0/SetType at `(priority := low)` or suppressed when the model
   declares its own.
6. **The effect-erasure page** (S17): one normative statement of the
   pure-signature/mutable-state soundness invariant, cross-referenced from
   CerbTags/CerberusFresh/CerbDebug/CerbGlobal; converge CerbGlobal and
   CerbDebug onto the armoured pattern (S10+S11), fix Main:1032's discarded
   set_level.
7. **Enum registry** (S9): the native ref-cell port of registered_enums;
   route sizeof_ity's Enum arm through typeof_enum.
8. **Constraint pruning** (S15): mirror the concrete cs_module's
   eval_cs/check_sat in CerbND; retire survey finding 23.
9. **CerbFS honesty** (S13): offsets or loud enosys; divergence table in the
   header, per the CerbPP enumerated-residual pattern.
10. **Comment-truth pass** (S18+N5+N6): correct the fresh_sym_supply .lem
    framing per the drift review, delete the sorry-era and no-op-claiming
    comments, post-arc-10 accuracy pass on the instance-mechanism notes.

## 4. Grade

**B− overall, with an A-grade core and an F-grade tail.**

Where the arcs have touched — CerbMem's layout/serialization/load/store,
CerbND, CerbFloat, Main, CerbPP, the .lem declares, the native shims — this
artifact is not merely publication-grade, it is BETTER-documented than the
upstream it mirrors: upstream impl_mem.ml does not cite its own line numbers,
does not enumerate its divergences, and does not gate its own drift. The
citation discipline (file:line on nearly every arm), the
documented-deliberate-divergence register, the enumerated pp-placeholder
residual, the fail-stop conventions (fresh-floor probe, fail-closed libc
name-join, drift manifest gate, loud fuel exhaustion), the DAEMON execution,
and the honest divergence prose in CerbND are, credit where due, exemplary —
several of these practices deserve to flow UPSTREAM.

But the operator asked for "no semantic ugliness," and the tail is ugly in
exactly the way that matters: six GRAVE findings where the artifact silently
returns values on inputs where the oracle stops (or returns the WRONG value —
ffs(-1), '\?', realloc's UB code), all in seams that predate the mirror
doctrine and carry no citations — plus a family of degenerate instances and
armouring inconsistencies whose correctness is corpus-accident, the very
F-D-shape the fork has already been burned by once. None of this is
load-bearing for the current green gates; all of it is reachable C.

Distance to "immaculate": one focused arc (the top-10 above; items 1-4 are
the bulk). The upstream-proposability question (dimension 6): the .lem
declare deltas and the drift-gate would likely be ACCEPTED by the Cerberus
maintainers as-is (they are invisible and generation-verified); what they
would reject on sight is the F-D desugar threading's oracle-side effect
(drift review §4 — already register-tracked with a mover) and any hand seam
in the F-row above being described as "matching the OCaml concrete model's
semantics exactly" (CerbMem.lean:5) while memcpy bypasses the checker. Fix
the tail and that sentence becomes true.

---
*Register totals: 6 GRAVE, 18 SERIOUS, 14 NIT. No fixes applied; write scope
was this file only.*
