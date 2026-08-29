# Fork-drift review: every fork-side change vs upstream cerberus that could affect the oracle

Date: 2026-08-21. Reviewer: read-only audit worker (arc-10 follow-up).
Baseline: `upstream/master` @ `b9aeedcb4` = merge-base of `mdd/cerberus-lean`
(verified: `git merge-base upstream/master mdd/cerberus-lean` =
`b9aeedcb4dd438763b0eef7f95ac19e93875d7de`; fork = upstream + our commits, no
divergence below). Pristine upstream checkout: `deps/cerberus-upstream` @ the
same commit. All classifications below are against the CUMULATIVE diff
`upstream/master..mdd/cerberus-lean` (the drift ground truth), with introducing
commits identified per hunk family.

Method note: in addition to reading every hunk of the shared-model and
oracle-only surfaces, this review used a **whole-tree generated-OCaml
comparison**: `deps/cerberus-upstream/ocaml_frontend/generated/` (regenerated
2026-08-21 11:52 from upstream .lem) vs
`cerberus-lean/ocaml_frontend/generated/` (from fork .lem). 67 of 86 generated
.ml files are BYTE-IDENTICAL — which also confirms both trees were produced by
output-identical lem binaries — so every token-neutrality claim below is
generation-verified, not just reasoned. (Counts here and throughout are derived
tallies unless quoted.)

## 1. Partition of the diff (747 files, derived from `--stat`/`--name-only`)

| Partition | Files | Content |
|---|---|---|
| (a) `lean_frontend/**` — our Lean artifact | 110 | out of scope for oracle semantics (count only) |
| (b) `frontend/model/**` + `frontend/concurrency/**` — THE SHARED MODEL | 45 | 43 model .lem + 2 concurrency .lem; every hunk reviewed, table in §2 |
| (c) oracle-only OCaml surface | 7 | `backend/driver/{main.ml,dune}`, `backend/lean_export/{cabs_json.ml,dune}` (new), `runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl`, `cerberus.opam`, `cerberus-lib.opam` |
| (d) tooling | 585 | `tests/**` 552 (all additive corpora/baselines), `scripts/**` 30, `Makefile`, `.gitignore`, `CLAUDE.md` |

Untouched oracle surfaces (important negatives): `ocaml_frontend/**` (0 files —
`generated/` is gitignored build output), `backend/common/**` (0),
`parsers/**` (0), `memory/**` (0), `util/**` (0 — in particular
`util/cerb_fresh.ml` is UNCHANGED; this matters in §4), `sibylfs/**` (0).

Addendum — open arc branches (diffstat-only per scope):
`git diff mdd/cerberus-lean..arc/wp-tactics` and `..arc/robustness` over
`frontend backend/driver backend/common ocaml_frontend memory util parsers
runtime` are both EMPTY. Neither open branch adds oracle-surface drift beyond
mainline; their content is covered by their own arc audits.

## 2. Per-file classification, partition (b) — the shared model

Legend: **DECL** = DECLARES-ONLY (lean-target declares / target-set additions /
whitespace; OCaml artifact token-neutral, generation-verified §3);
**DELIB** = SEMANTIC-DELIBERATE (changes oracle code on purpose, rationale
confirmed); **SUSPECT** = SEMANTIC-SUSPECT (F-D class, §4).

| File | Class | Introducing commit / evidence |
|---|---|---|
| concurrency/cmm_csem.lem | DECL | `{ocaml}`→`{ocaml; lean}`, `~{ocaml}`→`~{ocaml;lean}`, lean target_reps; generated `cmm_csem.ml` byte-identical |
| concurrency/cmm_op.lem | DECL | same; `cmm_op.ml` byte-identical |
| ail/ailSyntax.lem, ail/ailTypesAux.lem, ail/ailWf.lem, ail/genTyping.lem | DECL | declares + whitespace; generated diffs comment/blank-only or byte-identical |
| annot.lem, any.lem, boot.lem, builtins.lem, cn.lem, core.lem, core_aux.lem, core_eval.lem, core_linking.lem, core_rewrite.lem, ctype.lem, ctype_aux.lem, debug.lem, decode.lem, defacto_memory.lem, defacto_memory_aux.lem, defacto_memory_types.lem, driver.lem, float.lem, formatted.lem, fs.lem, global.lem, implementation.lem, loc.lem, mem.lem, nondeterminism.lem, pp.lem, state_exception_undefined.lem, std.lem, translation.lem, utils.lem | DECL | arcs 1/3/7 totality & target_rep declares only; generated .ml byte-identical (fs, mem, lem_global, lem_loc, lem_decode, driver, float, implementation, defacto_memory, ctype_aux, core_eval, annot, …) or comment/whitespace-only (core, core_aux, ctype, cn, nondeterminism, pp, std, utils, lem_debug, defacto_memory_types, ailSyntax) |
| symbol.lem | SUSPECT (enabling) + DECL | `80b0f6d20` adds `fresh_given_int` (pure sym from supplied id — live via core_run); rest is lean declares |
| cabs_to_ail_effect.lem | **SUSPECT** | `8923d6436` — desugM `fresh_sym_supply` threaded, seeded **0**; `fresh_sym{,_int,_pretty,_cn,_object_address,_description}` helpers; migrated `record_marker`, `internal_register_identifier`, `register_cn_ident`, `register_tag` |
| cabs_to_ail.lem | **SUSPECT** | `8923d6436` — 4 loop-id sites `Symbol.fresh_int ()` → `E.fresh_sym_int ()` |
| core_run_aux.lem | **SUSPECT** | `80b0f6d20` — `sym_supply` added to `core_run_state`, seeded from ONE ambient `Symbol.fresh_int ()` at init (the anchor; its own comment concedes the non-escape obligation) |
| core_run.lem | **SUSPECT** | `80b0f6d20` — `fresh_symbol'` / `E.fresh_symbol`; LoadRequest `val_sym` now threaded instead of ambient `Symbol.fresh ()` |
| core_reduction.lem | **SUSPECT** (2 sites) + DECL | `80b0f6d20` — SeqRMW site: draw HOISTED out of the pure result-callback into the monad (`rmw_sym`) AND moved to the threaded supply; second (excluded/wseq) site: ambient → `E.fresh_symbol` |
| translation_effect.lem | DELIB (additive-dead) | new `push_block_objects`/`pop_block_objects` — compiled into the oracle but **no callers anywhere** (grep over frontend/backend/ocaml_frontend); zero behavior change until someone calls them |
| mini_pipeline.lem | DELIB (verified) | arc-2 S6 — `run_const_expr_driver` extraction. In-code claim "On OCaml this is semantically identical to the previous inline code" **verified** against generated `mini_pipeline.ml`: identical code modulo the extraction; only residual delta is evaluation order of two pure computations (`translate_tag_definitions` vs ND-closure construction), neither effectful at that point |

## 3. Token-neutrality spot-checks (mission asked for ≥3; done tree-wide)

Same-lem generation over upstream .lem vs fork .lem: **19 of 86 generated .ml
files differ**. All 19 examined:

- 11 differ ONLY in comments/blank lines/trailing whitespace (ailSyntax, cn,
  core, core_aux, ctype, defacto_memory_types, lem_debug, nondeterminism, pp,
  std, utils). Example (verbatim diff excerpt, pp.ml — the added line sits
  inside an OCaml comment block):

  ```
  52a53
  > declare lean target_rep function stringFromSequenceGraph = `CerbPP.stringFromSequenceGraph`
  ```

- 8 differ semantically and are EXACTLY the §2 SUSPECT/DELIB set
  (cabs_to_ail, cabs_to_ail_effect, core_reduction, core_run, core_run_aux,
  mini_pipeline, symbol, translation_effect). No unexplained hunk anywhere.

Named spot-checks (subsumed by the above, called out per mission):
1. **fs.lem / mem.lem** (43/43 and 92/92 added lines are declares): generated
   `fs.ml`, `mem.ml` **byte-identical**. Claim held.
2. **cmm_csem.lem target-set edits** (`{ocaml}`→`{ocaml; lean}` on
   `action_equality`, `downclosed`, etc. — the riskiest declare shape, since it
   edits the very annotation that selects the OCaml definition): generated
   `cmm_csem.ml` **byte-identical**. Claim held.
3. **mini_pipeline.lem** (the one hunk carrying an explicit "OCaml
   semantically identical" claim): generated diff shows a pure function
   extraction; the OCaml token stream of the computation is preserved
   (`Tags.with_tagDefs tds (fun () -> Smt2.runND Exhaustive
   Impl_mem.cs_module driver_action dr_st)` — same call, same construction).
   Claim held (with the benign pure-eval-order note above).

Caveat: this comparison holds the lem binary fixed (the pinned fork lem). It
cannot see drift of the lem FORK's OCaml backend vs upstream lem. Signals that
this lane is quiet: lem-lean's `src/backend.ml` diff vs its merge-base
`3802cb04` has no removed lines that don't mention "lean" (85 changed lines,
all lean-dispatch additions), and 67/86 byte-identical generated files show no
formatting drift. Not proof. One-off probe priced in §6.

## 4. THE SUSPECT LIST — the F-D family has three members, and they compose

Background invariant (upstream): symbol identity is `(digest, num)` —
`symbolEqual`/`symbol_compare` (symbol.lem:132-160) IGNORE the description.
`digest` is per-TU (`Cerb_fresh.set_digest`, backend/common/pipeline.ml:181).
Uniqueness of `num` within a TU therefore carries ALL of symbol identity, and
upstream guarantees it by routing EVERY minting site through the single
process-global `Cerb_fresh.int` counter (util/cerb_fresh.ml). This is exactly
the implicit invariant our own upstream-findings note
(`notes/upstream/07-symbol-identity-fragility.md`) reconstructs.

The fork BROKE that single-counter architecture twice, creating three id
streams per TU where upstream has one:

### S1 (primary suspect): desugar supply threaded, 0-based — commit `8923d6436`
"State-thread fresh symbol generation through desugM" (2026-04-20).
Desugar-minted symbols (every registered C identifier, tags, CN idents, loop
ids, markers) now take ids `[0, N)` from `fresh_sym_supply= 0` and NO LONGER
advance the ambient counter — **on the OCaml oracle too** (generated
`cabs_to_ail_effect.ml`: `fresh_sym_supply= 0`, `let n = st.fresh_sym_supply`).
The commit message claims:

> The OCaml target_rep of Symbol.fresh_int still maps to the mutable
> Cerb_fresh.int — OCaml path unchanged.

This is **false as stated**: the migrated call sites bypass `Cerb_fresh.int`
on both targets. What actually keeps the oracle working is a MARGIN, not the
old invariant — documented by ourselves in
`lean_frontend/native/fresh_int.c` (verbatim):

> the OCaml Core parser draws Cerb_fresh.int() once per registered symbol
> (parsers/core/core_parser.mly:184 register_sym, :220 register_label), so
> translation-time ambient ids (Symbol.fresh, frontend/model/symbol.lem)
> start ABOVE the 0-based ids the desugar stage threads through desugM
> (cabs_to_ail_effect.lem fresh_sym_supply, commit 8923d6436) — the two id
> streams are disjoint per translation unit.

and, same file:

> Starting the counter at 2^20 reproduces the OCaml invariant (ambient ids
> strictly above the per-unit desugar range) with a larger margin than
> OCaml's (~488 for the current std.core).

So: the LEAN side got a 2^20 base + a fail-stop floor assertion for its
ambient stream after this exact collision class produced `ACTION_ILLTYPED`
env-clobbering on 15 of tests/minimal (arc-4 S3a; also the case study in
notes/upstream/07 — "silent corruption surfacing far from the cause"). The
OCAML ORACLE got NOTHING: `util/cerb_fresh.ml` is unchanged (counter starts at
0), there is no floor, no assertion, no margin beyond the ~488 std.core draws.

**Risk analysis.** Ambient ids for a TU's translation temporaries start at
K = (std.core-parse draws ≈ 488) + (draws by earlier TUs / earlier pipeline
stages). Desugar ids are `[0, N)` with the SAME digest. Collision condition:
**N > K** — i.e. any TU whose desugar mints more fresh symbols than the
ambient counter's current value. For the first TU of a process that is
N ≳ 490: a file with ~500 declared identifiers (easily reached with real
headers, generated code, or the ci corpus's larger files). On collision, a
translation temporary is THE SAME MAP KEY as a desugared program symbol:
last-write-wins in sym-keyed environments → internal errors
(`ACTION_ILLTYPED`), spurious UB, or silent value corruption, with the
failure point determined by declaration layout — **this is the F-D signature,
and the margin arithmetic makes it declaration-COUNT-sensitive, which
subsumes layout-sensitivity**.

**Probes.** (i) Deterministic, no execution: emit `--pp core` (or walk the
symbol table) for a TU with >600 file-scope declarations and scan for
duplicate `(digest, num)` pairs with distinct descriptions — a pure
oracle-side self-check; the level-5 debug hook in `symbolEqual`
(symbol.lem:137-141, "suspicious equality") can be turned into the detector
by running with `-d 5`. (ii) Differential: same file, fork oracle vs
`deps/cerberus-upstream` oracle, self-checking main over globals declared
late in the file. (iii) Counter instrumentation: print `Cerb_fresh.int()`
once at translation start and compare against the TU's desugar draw count.

### S2 (the anchored suspect): run supply seeded-from-ambient — commit `80b0f6d20`
"Arc 2 S1+S2: fresh threaded through core_run_state" (2026-08-18).
`core_run_state.sym_supply` is seeded by ONE ambient read at init; run-minted
Load `val_sym`s / SeqRMW syms then count up WITHOUT advancing the ambient
counter. The in-code comment (core_run_aux.lem:233-244) already concedes the
hole (verbatim):

> PRECISE invariant (audit-corrected): ids are unique WITHIN a driver
> run, and distinct from all ambient ids drawn BEFORE that run's
> init. A run's threaded range can overlap ambient ids drawn AFTER
> init (e.g. desugaring resuming past a mid-desugar const-expr run) —
> latent-safe because run-created symbols do not escape their run
> (they appear only as arena binders and Load value names); a
> Phase-2 differential obligation asserts non-escape.

**Composition with S1 (new observation of this review):** the comment's
invariant only speaks about AMBIENT ids. Since S1, desugar ids are NOT
ambient draws, so they are not covered by it at all. A const-expr driver run
launched mid-desugar (mini_pipeline) seeds at K ≈ 488+ε while desugar is
still minting toward N; for N > K the run's Load-value ids overlap
already-minted desugar ids of the same digest — a collision S2's stated
invariant does not even claim to exclude. Whether it is observable depends
entirely on the conceded, undischarged non-escape obligation. Also note:
successive const-expr runs advance the ambient counter by only ONE draw each,
so consecutive runs' threaded ranges overlap each other too (harmless iff
non-escape holds).

**Risk/probe.** Const-expr-heavy TUs (large enum initializers, sizeof
arithmetic in array bounds, static initializers forcing the mini-pipeline
driver) with several hundred preceding declarations; shuffle declaration
order; differential vs upstream oracle. Any observable difference falsifies
non-escape.

### S3 (same commit): SeqRMW draw-time hoist — core_reduction.lem
Upstream draws the RMW symbol lazily inside the result callback; the fork
draws eagerly at request-construction (`rmw_sym`). The commit message absorbs
the numbering shift into "the id-insensitive differential ruling" — a ruling,
not a discharge; id-insensitivity is precisely what fails when streams
collide. Standalone risk is low (atomics path, id-order only); it inherits
whatever disjointness S1/S2 leave standing. Probe: atomic-RMW tests under the
S1 probe's high-declaration-count preamble.

### Expected mover (register-grade recommendation, not executed here)
Mirror the Lean fix into the oracle: base `util/cerb_fresh.ml`'s counter at
`1 << 20` (or seed it there via an init call) plus the same fail-stop floor —
recreating upstream's disjointness with an explicit margin, symmetrically to
`native/fresh_int.c`. That is an oracle change and needs its own differential
run + upstream-vs-fork re-baseline; alternatively (cleaner, bigger) revert S1
on the OCaml target by giving the desugar helpers an
`declare ocaml target_rep` back onto `Cerb_fresh.int`. Either way, the fix
lives OUTSIDE this review's write scope.

## 5. Oracle-only surface (c) + obligation sweep

Partition (c) classifications:

| Change | Class | Note |
|---|---|---|
| `backend/driver/main.ml` — `--cabs-json` flag + branch | DELIB | additive; default path only threads one extra cmdliner term |
| `backend/driver/dune` — link `lean_export` into cerberus/vip/cheri exes | DELIB | link-time only |
| `backend/lean_export/cabs_json.ml` + `dune` (new, 639 lines) | DELIB | new serializer library; reachable only behind `--cabs-json` |
| `runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl` | DELIB (fix) | comment syntax `(* *)`→`{- -}`; content otherwise unchanged. The OCaml core lexer (parsers/core/core_lexer.mll:278, unchanged from upstream) only accepts `{-` comments, so upstream's file was unparseable by the oracle's own impl loader; the fork made it loadable. Non-default impl (default `gcc_4.9.0_x86_64-apple-darwin10.8.0`) |
| `cerberus{,-lib}.opam` — yojson `>= 2.0.0` → `>= 3.0.0` | DELIB | build-constraint for cabs_json; no model impact |
| `Makefile`, `.gitignore` | tooling | lean targets, distclean-lean, ignores |

Obligation sweep over the (b)+(c) diff (comments conceding unproven
assumptions), each a register-grade item:

- **O1** core_run_aux.lem:233-244 — the conceded non-escape obligation
  (quoted in §4/S2). Status: undischarged; enforced only as a "Phase-2
  differential obligation" (differential ≠ proof, and the differential corpus
  is exactly the layout-insensitive one that misses F-D).
- **O2** cabs_to_ail_effect.lem:613-617 — "Callers that currently use
  Symbol.fresh/fresh_pretty/etc. directly should migrate to these —
  otherwise…": concedes a standing mixed-supply footgun. The ~15 remaining
  ambient sites in translation.lem/translation_effect.lem/core_unstruct.lem
  are ambient BY DESIGN, so the safety story is the §4 margin, nowhere
  stated on the OCaml side.
- **O3** lean_frontend/native/fresh_int.c — quantifies the OCaml margin
  (~488) and states the invariant, but the floor ASSERTION exists only in the
  Lean native counter; no OCaml counterpart in util/cerb_fresh.ml.
- **O4** core_reduction SeqRMW hoist — "numbering order shifts, absorbed by
  the id-insensitive differential ruling" (commit 80b0f6d20): ruling, not
  discharge.
- **O5** mini_pipeline "On OCaml this is semantically identical" —
  DISCHARGED by this review (generated-OCaml diff, §3.3).
- **O6** commit `8923d6436` message: "OCaml path unchanged" — FALSE (§4/S1).
  Record-integrity-adjacent finding: an incorrect neutrality claim in a
  commit message is exactly what a drift gate must not trust.

Also swept, not oracle-relevant: the arc-3/7 totality-declare comment blocks
("fuelExhausted panics at runtime, typing only") are Lean-target-only and
carry their own arc records.

## 6. The standing drift gate — design + draft

Recommendation: **layered (iii), with layer 2 nearly free because both
generated trees already exist on disk.**

**Layer 1 — manifest gate (name-level, <1 s, Tier A / every test_unit run).**
`git -C cerberus-lean diff upstream/master --name-only -- frontend
backend/common backend/driver backend/lean_export ocaml_frontend memory util
parsers sibylfs runtime` must equal the committed manifest below, byte for
byte (sorted). Any new file on the oracle surface = loud failure + forced
manifest update with in-file justification. Catches: new drift by filename.
Cost: one git invocation. (Note `upstream/master` is a local-only ref:
fetch-only remote, works offline; the gate should fail loud if the ref or the
merge-base ever moves from `b9aeedcb4`.)

**Layer 2 — token-neutrality gate (content-level, <1 s steady-state, Tier A;
regeneration only on pin moves, ~1 min, Tier B).**
Precondition (already true today): `deps/cerberus-upstream` checked out at the
merge-base with `ocaml_frontend/generated/` built by the SAME pinned lem as
the fork's tree. Gate logic sketch (drafted; DO NOT create — placement is the
orchestrator's call, arc-10 owns scripts/):

```
# fork_drift_gate.sh (sketch)
# A. name-level: git diff upstream/master --name-only -- <surfaces> | sort
#    must equal manifest section [files] (else FAIL, print delta).
# B. content-level: diff -rq of the two generated/ trees.
#    - files in manifest section [expected-semantic] may differ, but their
#      diff must hash (sha256 of "diff -u" output) to the pinned value in the
#      manifest — semantic drift INSIDE an already-excused file is loud too;
#    - files in [expected-cosmetic] must diff to empty after stripping
#      OCaml comments+blank lines (a 10-line awk/ocaml-lex-free filter is
#      acceptable here since we pin the full-diff hash as well);
#    - any OTHER differing file = FAIL.
# C. refresh mode (pin move / lem bump / deliberate model change, Tier B):
#    regenerate BOTH trees with the pinned lem (same invocation as
#    make prelude-src, -outdir into a temp dir for upstream), recompute
#    hashes, force a manifest commit whose message states the justification.
```

Pricing: regeneration = one `lem` run over LEM_SRC per tree (the upstream tree
was rebuilt today in well under 2 min; steady-state runs skip it), diff -rq
over 86 files ≈ milliseconds. The hash-pinning is what upgrades (i) to catch
what filenames can't: any new hunk in an already-touched .lem that changes
OCaml tokens flips the diff hash.

**Residual lane (explicitly not covered, one-off probe suggested):** fork-lem
vs upstream-lem OCaml-backend divergence (both trees use the pinned fork lem).
One-off probe: build upstream lem @ merge-base `3802cb04` (source available
via deps/mirrors), regenerate upstream .lem with it, diff against the
fork-lem-generated upstream tree. ~10 min once; if byte-identical, the lane is
closed until the lem pin moves (then repeat). Not worth a standing gate.

### Draft manifest (from this review; the committed file = these three sections)

```
[meta] merge-base=b9aeedcb4dd438763b0eef7f95ac19e93875d7de lem-pin=237867b
[files]  # oracle-surface files that may differ from upstream (45 + 7)
# frontend/concurrency (2): cmm_csem.lem cmm_op.lem                 DECL
# frontend/model/ail (4): ailSyntax ailTypesAux ailWf genTyping     DECL
# frontend/model (31 DECL): annot any boot builtins cn core core_aux
#   core_eval core_linking core_rewrite ctype ctype_aux debug decode
#   defacto_memory defacto_memory_aux defacto_memory_types driver float
#   formatted fs global implementation loc mem nondeterminism pp
#   state_exception_undefined std translation utils
# frontend/model (8 SEMANTIC): symbol cabs_to_ail cabs_to_ail_effect
#   core_run core_run_aux core_reduction translation_effect mini_pipeline
# oracle-only (7): backend/driver/main.ml backend/driver/dune
#   backend/lean_export/cabs_json.ml backend/lean_export/dune
#   runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl
#   cerberus.opam cerberus-lib.opam
[expected-semantic]   # generated .ml allowed to differ, WITH pinned diff hash
cabs_to_ail.ml cabs_to_ail_effect.ml core_reduction.ml core_run.ml
core_run_aux.ml mini_pipeline.ml symbol.ml translation_effect.ml
[expected-cosmetic]   # comment/whitespace-only generated diffs (11)
ailSyntax.ml cn.ml core.ml core_aux.ml ctype.ml defacto_memory_types.ml
lem_debug.ml nondeterminism.ml pp.ml std.ml utils.ml
```

(Concrete hashes are refresh-mode output, not hand-computed here.)

## 7. Bottom line

**F-D is the only suspect FAMILY — but it has three members, not one, and the
family is bigger and older than the arc-10 S4 attribution.** The arc-2 S1
threaded `sym_supply` (core_run_aux, commit `80b0f6d20`) is real and carries
its conceded non-escape obligation, but the earlier and larger member is the
April desugar threading (commit `8923d6436`, `fresh_sym_supply= 0` in
cabs_to_ail_effect.lem): it removed the desugar stage from the single global
counter ON THE ORACLE TOO, under a commit message that wrongly claims the
OCaml path is unchanged. Our own artifacts (native/fresh_int.c,
notes/upstream/07) document the resulting collision mechanism, quantify the
oracle's residual safety margin (~488 ambient draws from the std.core parse),
and show that the Lean side was given a 2^20 base + fail-stop floor while the
oracle received no equivalent protection. Everything else on the shared-model
surface is generation-verified token-neutral (67/86 generated files
byte-identical, 11 comment-only), the oracle-only surface is additive or a
comment-syntax fix, `util/ ocaml_frontend/ parsers/ memory/ backend/common`
are untouched, and the two open arc branches add zero oracle-surface drift.
The proposed two-layer gate (manifest + hash-pinned generated-tree diff)
makes any future member of this class loud for under a second per run.
