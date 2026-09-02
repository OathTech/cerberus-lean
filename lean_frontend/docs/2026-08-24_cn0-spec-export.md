# CN-0 — the CN spec-AST exporter (`--cn-spec-json`)

> PARKED 2026-09-02 [USER 2026-09-02, release-hygiene item 2]: the exporter (`backend/lean_export/cn_spec_json.ml`, the `--cn-spec-json` flag, `scripts/test_cn_spec_export.sh`, `tests/cn_spec_export/`) was removed from mainline; last commit carrying it: `90e341db2`. This record is kept as the dated design record; nothing below is live.

Date: 2026-08-24. Provenance: [AGENT:cn0-spec-export] throughout;
design written BEFORE code per the charter discipline. Parent design:
`notes/2026-08-24_cn-on-iris-investigation.md` (container repo) — this
is stage CN-0 of the CN-on-Iris ladder. Doctrine: ELABORATE-DON'T-CHECK
— this stage only EXPORTS what was written; no checking, no elaboration
semantics, no Lean consumer. Branch `cn-spec-export`, off mainline
`5014fc4ae`, write surface: OCaml oracle side + tests + docs only
(disjoint from arc-16).

## 1. Survey — what the fork's parser actually has (the gap map)

Verified by inspection of the worktree at `5014fc4ae`:

* **The full CN surface grammar is IN THE FORK**, embedded in
  `parsers/c/c_parser.mly` (upstream cerberus layout — CN's grammar
  never left cerberus; deps/cn consumes it as a library). Start
  symbols (c_parser.mly:324-329): `translation_unit`, `fundef_spec`,
  `loop_spec`, `cn_statements`, `cn_ghost_args`, `cn_toplevel`.
* **The CN syntax AST is IN THE FORK and is LEM-GENERATED**:
  `frontend/model/cn.lem` → `ocaml_frontend/generated/cn.ml`
  (`cn_expr`, `cn_resource`, `cn_condition`, `cn_func_spec`,
  `cn_loop_spec`, `cn_statement`, `cn_function`, `cn_predicate`,
  `cn_datatype`, `cn_lemma`, `cn_type_synonym`, `cn_decl_spec`).
  Consequence for CN-2: `make lean-prelude-src` can generate the Lean
  twin of this exact AST from the same .lem — the Lean importer's
  target type comes for free, same-source, no hand mirror.
* **The lexer keyword table is MODERN** (c_lexer.mll): `RW`/`W`
  production keywords with `Owned`/`Block` as deprecated aliases,
  `focus` production with `extract` deprecated, `i32`/`u64`-style
  bits types, `match`, `datatype`, `type_synonym`, experimental
  `cn_function`/`to_bytes`/`from_bytes`/`cn_ghost`. Same surface
  vintage as deps/cn's `tests/cn` corpus.
* **Magic-comment plumbing** (verified in the arc-15 S0 probe +
  re-inspected): `/*@ ... @*/` lexes as `CERB_MAGIC` only under
  `SW_at_magic_comments` (OFF by default — zero behavior change for
  every existing lane). Attachment points in the grammar:
  - toplevel comment → `EDecl_magic (loc, str)`, which
    `C_parser_driver.parse` ALWAYS re-parses via the `cn_toplevel`
    start symbol into `EDecl_funcCN | EDecl_lemmaCN | EDecl_predCN |
    EDecl_datatypeCN | EDecl_type_synCN | EDecl_fun_specCN`
    (c_parser_driver.ml:118-141) — i.e. toplevel CN definitions
    arrive in Cabs ALREADY PARSED;
  - function definition → `cerb::magic` attribute on the `FunDef`
    attrs (c_parser.mly:1581-1588), raw string, NOT yet CN-parsed;
  - while/do/for → `cerb::magic` attribute on the loop
    `CabsStatement` (c_parser.mly:1417-1441), raw string;
  - block-item statement comment → `CabsSmarker (CabsSnull)` with a
    `cerb::magic` attribute (c_parser.mly:1365-1374), raw string;
  - call-site ghost args → `CabsEcall (_, _, Some attrs)`
    (c_parser.mly:544), raw string.
* **What the fork does NOT have / what lives in deps/cn** (BSD-2):
  the ~150-line driver walk `deps/cn/lib/parse.ml` that finds the
  raw-string attribute sites and feeds them to the fork's own start
  symbols (`function_spec`/`loop_spec`/`cn_statements` there), plus
  everything downstream (desugar-to-mucore spec injection,
  elaboration, typechecking — all out of CN-0 scope by design).
  ALSO not taken: `fiddle_at_hack` (legacy `@start` support,
  parse.ml:45) and `allow_split_magic_comments` (parse.ml:5, default
  false — we hard-adopt the default as a fail-closed error).

**Gap-map verdict: the fork needs NOTHING vendored from deps/cn for
CN-0.** The only missing piece was the walk, re-implemented here
(~100 lines, `backend/lean_export/cn_spec_json.ml`) against the
fork's own parser entry points, with the deps/cn walk as behavioral
reference (cited per site, mirror-OCaml style). For CN-2 the real
shape is: consume THIS export + the lem-generated Lean `Cn` AST;
deps/cn remains reference-only (spec-language semantics), no code
dependency.

Also verified (relevant to later stages, not used here): the fork's
lem-generated desugarer `cabs_to_ail.ml` retains the full CN toplevel
registration/desugar path (`desugar_and_register_cn_predicate` etc.)
— CN-2 has an Ail-level option too if it ever wants it.

### 1a. CN's own spec export (`deps/cn/lib/testGeneration/specExport.ml`)
— surveyed before freezing the schema (orchestrator mid-flight input)

CN already ships spec-export machinery, read in full. It is NOT the
layer CN-0 wants, for reasons worth recording precisely:

* **Wrong pipeline position**: it dumps CN's POST-ELABORATION internal
  IR — `ArgumentTypes`/`LogicalArgumentTypes` binder chains,
  `Request`, `Terms.Normal` index terms, `BaseTypes`, `Sctypes`,
  `Definition.Predicate/Function`, mucore struct layouts and globals.
  Producing that requires CN's full desugar + core-to-mucore +
  spec-elaboration + typechecker stack (`compile.ml` et al.) — the
  very surface the prototype died re-porting, and the thing the
  elaborate-don't-check inversion makes OUR job (CN-2's elaboration
  into Iris is normative for us; adopting CN's elaborated IR as the
  interchange would smuggle CN's checker semantics back in as a
  dependency).
* **Consumer-specific ABI**: the shape is the serde encoding of
  AustenTest (CN's Rust test-generation engine): num-bigint limb
  arrays, `const_` field spellings, a one-byte function-selector
  ordering contract, `next_sym` counters. Not a general interchange.
* **Deliberately lossy, by its own header**: ALL source locations
  dropped ("AustenTest carries no source spans" — CN-0's location
  requirement is load-bearing for us); loop invariants and
  `cn_statement`s dropped (the `fn_body` half of the AT terminal —
  precisely things we must export); operator normalization
  documented as "a lowering, not a round trip".
* **Fail-open**: unrepresentable functions are SKIPPED with a warning
  (`save`, specExport.ml:943-958) — the opposite of our fail-closed
  doctrine; not adoptable even as a pattern.

**What it IS for us**: (a) confirmation that syntax-level export has
no precedent inside CN to reuse — CN-0's layer is genuinely ours to
define; (b) a CHECKLIST FOR CN-2 of what CN itself considers the
elaborated spec surface (AT/LAT chains with define/resource/
constraint binders, Owned-with-init vs named requests, predicate
clause guards + packing chains, struct layouts, globals with linkage
classes) — when CN-2 designs the elaborated interface over Iris,
specExport.ml is the reference enumeration of what must exist;
(c) shared engineering judgments that independently validate ours:
hand-spelled encodings over derived ones with the convention
documented at the definition site, and exhaustive matches so an
upstream constructor addition is a compile error, not a silent
mistranslation.

## 2. Design — the exporter

**Mode**: `cerberus --cn-spec-json file.c` (flag name per charter).
Mirrors the `--cabs-json` precedent exactly: OCaml parses, prints one
JSON document to stdout, exits nonzero on any failure. The mode
IMPLIES `at_magic_comments` (set internally iff not already set); no
other switch or lane is touched — the flag default stays OFF
everywhere else.

**Pipeline**: cpp → `C_parser_driver.parse_from_string` (toplevel CN
already parsed by the driver, per §1) → `Cn_spec_json.export` walks
Cabs, CN-parses the four raw-string attachment sites via
`C_parser_driver.parse_loc_string` with the fork's own start symbols,
and serializes. STOPS AT PARSE — no desugar, no Ail, no core_std
prelude needed (faster than `--cabs-json`, and immune to any CN
desugar semantics).

**Fail-closed rules** (each an `Errors.UNSUPPORTED` or the parser's
own `Errors.CPARSER`, both fatal through the driver's standard error
path):
1. a CN annotation that fails to parse is a LOUD error with location
   (never omitted from output silently);
2. ≥2 magic comments on one function/loop ("split specs") are
   rejected, mirroring deps/cn's `allow_split_magic_comments = false`
   default (parse.ml:122-125) — we do not adopt the snippet-joining
   escape hatch;
3. a surviving `EDecl_magic` (impossible per the driver contract,
   c_parser_driver.ml:118-141) is an internal-invariant error;
4. Cabs constructor matches in the walker are EXHAUSTIVE with no
   wildcard on `cabs_statement_`/`cabs_expression_` — an upstream
   grammar addition becomes a compile error here, not a silent
   omission;
5. magic payloads found OUTSIDE any function body (e.g. inside a
   toplevel initializer via a GNU statement-expression) land in a
   `stray` array in the envelope, never dropped.

**Coverage** (all six toplevel CN decl forms + all four in-function
sites): function specs (requires/ensures/trusted/accesses — via
`fundef_spec`), loop invariants (`loop_spec`), CN proof-guidance
statements incl. ghost blocks (`cn_statements`), call-site ghost
arguments (`cn_ghost_args`), CN functions, predicates, datatypes,
lemmas, type synonyms, prototype specs (`spec f(...)`).

## 3. The JSON schema (v1)

Versioned envelope; syntax-faithful (serializes the fork's `Cn.*`
syntax AST verbatim — what was WRITTEN, not an interpretation);
constructor convention identical to cabs-json (`{"tag": Name, ...}`,
nullary constructors as bare strings, options as null-or-value,
locations in cabs-json's lossless format). `'ty` positions
(sizeof/cast/Owned⟨τ⟩ arguments) are Cabs `type_name` values,
serialized with the SAME `Cabs_json` serializers the Lean importer
already speaks.

```json
{ "cn_spec_json_version": 1,
  "file": "division.c",
  "toplevel": [ { "tag": "CN_function", "name": {...}, "args": [...],
                  "return_bty": "CN_integer", "body": {...}, ... } ],
  "functions": [
    { "name": "division",
      "name_loc": { "tag": "Loc_point", ... },
      "def_loc":  { "tag": "Loc_region", ... },
      "spec": { "tag": "CN_func_spec",
        "trusted": null,
        "acc_func": null,
        "requires": { "loc": ..., "vars": [],
          "conditions": [ { "tag": "CN_cconstr", "loc": ...,
            "assertion": { "tag": "CN_assert_exp", "expr":
              { "tag": "CNExpr_binop", "op": "CN_inequal",
                "e1": {"tag": "CNExpr_var", "ident": {...="y"}},
                "e2": {"tag": "CNExpr_const", "const":
                  {"tag": "CNConst_bits", "sign": "CN_signed",
                   "width": 32, "value": "0"}}, ... } } } ] },
        "ensures": { ...same shape... } },
      "loops":      [ { "loc": ..., "kind": "for",
                        "inv_loc": ..., "invariants": [ ...cn_condition... ] } ],
      "statements": [ { "loc": ..., "stmts": [ ...cn_statement... ] } ],
      "ghost_calls":[ { "loc": ..., "exprs": [...], "idents": [...] } ] } ],
  "stray": [] }
```

Envelope keys are STABLE under version 1; consumers must reject an
unknown `cn_spec_json_version` (recorded here as the compatibility
contract). Every spec ties to its C function by `name` + `name_loc`
(the declarator identifier's own location — the same identity the
Cabs JSON carries), loops/statements by their statement locations.
Forward-compatibility with CN-2's elaborator: the payload is the
lem-typed `Cn` AST itself, so the Lean-side decode target is the
lem-generated twin of the SAME type — schema evolution rides the
.lem file, which the fork-drift gate already pins.

## 4. Validation plan

* New lane `scripts/test_cn_spec_export.sh` (Tier C reporting, NOT
  wired into test_unit): golden JSON diffs over a representative
  deps/cn/tests/cn slice (division.c, mod.c, memcpy.c, swap_pair.c,
  append.c + datatype/predicate-rich picks), a JSON-well-formedness +
  envelope check per golden, and the MALFORMED case: a local file with
  a syntactically broken annotation must exit nonzero with a parse
  error naming a location (fail-closed plant, run every lane pass).
* Zero-movement proofs after the build: `./scripts/test_exec.sh`
  (106 baseline, no movement) and
  `bash scripts/test_cn_coverage.sh --check-baseline` (BASELINE OK
  213) — the switch stays off everywhere but inside the new mode.
* `./scripts/test_unit.sh` 7/7 incl. the fork-drift gate:
  `backend/lean_export/cn_spec_json.ml` is a NEW manifest [files]
  entry (additive; reason in the manifest header note);
  `backend/driver/main.ml` is already manifested (layer 1 is
  name-level for hand files — no hash pin exists to move);
  `backend/lean_export/dune` needs no edit (no `modules` stanza —
  new module auto-included).

## 5. Results (post-validation)

**Built**: `backend/lean_export/cn_spec_json.ml` (new; serializers for
the whole fork `Cn` AST + the exhaustive Cabs walk), `--cn-spec-json`
flag in `backend/driver/main.ml`, `cerberus-lib.c_parser` dependency
in `backend/lean_export/dune`, the lane
`scripts/test_cn_spec_export.sh`, fixtures + goldens under
`tests/cn_spec_export/`.

**Coverage**: all six toplevel CN declaration forms and all four
in-function sites export (verified live in the goldens: fundef specs
incl. trusted/accesses, loop invariants, statement ghosts incl.
focus/instantiate/unfold/apply, call-site ghost args, datatypes,
[rec] functions, [rec] predicates, lemmas, prototype `spec`
declarations). Deliberate non-adoptions, each documented in the module
header: split magic comments rejected (CN's own default), legacy
`@start` fiddle_at_hack not supported, hand-written
`[[cerb::magic(...)]]` attributes in unexpected positions rejected.

**Golden lane** (10 goldens + schema + 2 plants): PASS, both plants
loud with empty stdout. Full-corpus reporting sweep (derived tally):
194/203 top-level `deps/cn/tests/cn/*.c` export cleanly; the 9
failures are all `*.error.c` fixtures with deliberately broken CN
syntax (assert_on_toplevel, bad_col, bad_ordering,
ghost_arg_exec_switch_default_fail, ghost_bad_ordering,
lexer_hack_parse, list_literal_type, spec_after_curly_brace,
spec_grammar) — loud parse errors, which is the contract.

**Zero-movement proofs** (switch off by default): test_exec
`SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0
crash=0 lean_error=0 timeout=0 cerb_skip=3 cerb_floor=0
cerb_inconsistent=0`; cn_coverage `BASELINE OK (213 entries, exact
match)`. Fork-drift gate: `check_fork_drift: OK — layer 1: 59
oracle-surface files = manifest; layer 2: 20 differing generated
files, all hash-pinned` (one new [files] entry, reason note in the
manifest header).

**For CN-2** (the consumers' contract): decode target = the
lem-generated Lean twin of `frontend/model/cn.lem`; the envelope is
versioned and consumers must reject unknown versions; specExport.ml
(§1a) is the reference enumeration for the ELABORATED layer's
eventual interface.
