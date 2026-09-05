# ZERO-DISCREPANCY — slice Z3 pre-merge audit (2026-09-05)

Range audited: `eb27fa70f..a8a4fe8f6` (branch `arc/z3-libc-order`, 4 commits:
`f38adabf4` pins RED, `2ddc1300c` the mirror, `22dcb6284` pins re-recorded,
`a8a4fe8f6` record + charter). Auditor: [AGENT], a fresh reader; the arc
worktree `worktrees/cerberus-lean-arc/z3-libc-order` (binaries stamped
oracle `bin 5bf3b347…/src 15a3689e…`, lean `bin 17a894c3…/src 0611a6a6…`)
was read and probed, never edited; this record is written on
`audit/z3-premerge` (worktree `worktrees/cerberus-lean-audit/z3-premerge`).
Findings are CLAIMS; every quoted engine/lane line is verbatim from this
box; tallies are labelled derived. No push, no merge.

Grades: MAJOR = a `.lem` change / an oracle-semantics OCaml change / a JSON
consumer left broken / a symbol-identity change that alters any verdict
outside the nine flips / an unpinned fork-drift surface / a gate weakened.
MINOR = a record, cite or discipline gap with no verdict consequence.
NOTE = observation.

## 0. Verdict

**MERGEABLE — no MAJOR finding.** One MINOR (a record/manifest omission,
docs-only remedy), the rest NOTEs. The slice does what it claims: no `.lem`
change; the only OCaml change is a one-field addition inside the fork's
`--cabs-json` exporter arm (a manifested hand file, off every oracle
execution path); the Lean glue mirrors `merge_globs`' `(digest, number)`
keys with cites that all check out; the digest refusal is fail-closed and
attributed; every committed JSON consumer is regenerated and carries the
digest; the renaming preserves bindings (plants: function pointers to libc,
callbacks from libc, struct returns, `FILE*` internals — AGREE after,
STDOUT-DIFF before with exactly the address-order signature); the battery
(26 lanes, orchestrator log) and my four lanes are all rc=0 at the
recorded baselines, with the five immaculate pins and `012` MATCH.

Findings (one line each):
* **F1 MINOR** — The record and `scripts/fork_drift_manifest.txt` are
  silent on the fork-drift status of the `main.ml` change; the gate passes
  BY DESIGN (layer-1 hand file, no generated `.ml` moved — §2.2, §7) but
  the manifest's own practice is a header NOTE per `main.ml` delta and the
  record was asked to say so. Remedy: a header NOTE / one record sentence
  (docs-only; can ride the merge or Z4).
* **F2 NOTE** — `renameFile` leaves struct/union tags inside
  `core_base_type` (`OTy_struct`/`OTy_union` in patterns, decl btys,
  `Vlist`, `Cnil`, `Esave`) name-interned; no exec-cone/linker `.lem`
  reads them (grep-empty; Main runs AIL typing only) and the `div` plant
  agrees, so it is inert — but the record's/`CoreParser.lean`'s "total
  traversal of every symbol position" overstates; document the exclusion or
  add the three arms (§2.5).
* **F3 NOTE** — Cite drift: `main.ml`'s new comment cites `symbol.lem:238`
  for `Symbol (digest ()) …` (the minting sites are `:284`/`:287`); the
  record §6.3 cites `main.ml:438-441` for the `--mode` default, which the
  fix's own 15-line comment moved to `:453-456` (§5).
* **F4 NOTE** — The ten regenerated goldens also moved every `"file"`
  location from the original author's absolute `/Users/miked/…` paths to
  box-relative `./_build/install/…` / `tests/fixtures/<n>//source.c`; the
  record says so and `test_golden.sh` reads return values only (§3, §4.3).
* **F5 NOTE** — The re-verification log's oracle stamp (`bin 5bf3b347…`)
  differs from the record §5.4's (`bin 48312b25…`) at identical `src
  15a3689e…`: the orchestrator rebuilt; OCaml binaries are not
  bit-reproducible here. Not a slice finding (§6).
* **F6 NOTE** — `batchEscape` renders the em-dash of the refusal message as
  `\12` in the `Error {msg: …}` line (§4.1) — cosmetic, pre-existing.

## 1. The diagnosis, re-derived (scope item 1)

* `frontend/model/core_linking.lem:252` `let merge_globs gs1 gs2 def_tents`
  builds `dep_map` (a global → the set of tentative-definition symbols free
  in its initialiser, `free` :230-233), seeds `init_set = empty_dep dep_map`
  (:235-238) and calls `topo_order [] init_set dep_map` (:242-250) whose
  next element is `Set_extra.choose s` (:245). In lem's OCaml library
  `Pset.choose = min_elt` (`deps/lem-pinned/ocaml-lib/pset.ml:297`) and
  LemLib's target is `setChoose … = Pset.choose` (`lem-lean/lean-lib/
  LemLib.lean:780`). The set's comparator is the `Ord sym` instance
  (`symbol.lem:169-174`) = `symbol_compare` (`symbol.lem:157-159`):
  `if d1 = d2 then compare n1 n2 else compare d1 d2` — digest first, then
  number. `Driver.driver_globals` (`driver.lem:1564`) reads `core_file.globs`
  (:1577-1579), filters to `GlobalDef` (:1580-1584) and evaluates them in
  list order (`ND.mapM_`, :1585-). Confirmed: the tie-break is
  `(digest, number)` lexicographic and the list order is the allocation
  order.
* The digest key is `Digest.file` of the SOURCE: `backend/common/pipeline.ml:181`
  `Cerb_fresh.set_digest filename` at the top of `c_frontend`;
  `util/cerb_fresh.ml:88-94` `set_digest filename = digest := Digest.file
  filename`; symbols are minted `Symbol (digest ()) (fresh_int ()) sd`
  (`symbol.lem:284/287`). libc.co is built by `runtime/libc/dune:145-146`
  from exactly the twelve `src/{ctype,stdio,stdlib,string,time,utime,unistd,
  stat,uio,internal,vfscanf,signal}.c`.
* Digest spot-check (all twelve, not two — `md5sum runtime/libc/src/*.c` on
  the audit worktree, verbatim prefixes): time `1903e802…`, stdio
  `2bfa5eea…`, uio `410c38dd…`, stat `60cc8cb4…`, ctype `6ab7d824…`, string
  `861cf530…`, signal `91349331…`, internal `a37bf0e1…`, unistd `a6301165…`,
  stdlib `cba3016f…`, utime `d006482b…`, vfscanf `fb6fa1d8…` — every one
  equals the record §2's twelve. (`locale.c`/`math.c` also exist under
  `src/` but are not in the dune rule — consistent with the record.)
* Hex-vs-raw ordering: the oracle compares raw 16-byte digests, Lean the
  32-char lowercase hex; hex is a byte-monotone encoding under ASCII order
  (`0`-`9` < `a`-`f`), so every `symbol_compare` outcome agrees. The empty
  digest `""` of std.core symbols sorts first on both sides (pre-existing).

## 2. The mirror (scope item 2)

### 2.1 The exporter — minimal, outside the oracle's semantics
`git diff eb27fa70f..a8a4fe8f6 -- backend/driver/main.ml`: one hunk at
:267, inside the self-contained `else if cabs_json then` arm (:264-290),
which parses and serialises and `return success` — it never reaches the
frontend/exec path. The change: `kvs @ [("digest", `String (Digest.to_hex
(Cerb_fresh.digest ())))]` appended to the `TUnit` object; `failwith` on a
non-object. `Cerb_fresh.digest ()` is a read of the ref cell set two lines
above (`Cerb_fresh.set_digest filename`, :265, pre-existing). Only the JSON
gains a field; no oracle output path other than `--cabs-json` is touched.
`git diff --stat eb27fa70f..a8a4fe8f6 -- frontend/model` is EMPTY and no
`.lem` appears in `git diff --name-only`: no `.lem` change (ruling held).

### 2.2 The fork-drift manifest — MINOR (record omission), gate not weakened
`scripts/fork_drift_manifest.txt` and `scripts/check_fork_drift.sh` are
UNCHANGED in the range. `backend/driver/main.ml` is already a layer-1
`[files]` entry; layer 2 hashes only the fork-vs-upstream deltas of
GENERATED `.ml` under `ocaml_frontend/generated`, and `main.ml` is a hand
file — the manifest's own doctrine (arc-13 A-F1 note: "a hand file:
name-manifested here (layer 1), content defended by review, not by a hash
pin"). So the gate passing WITHOUT a manifest change is BY DESIGN for this
surface, not a gate weakness: the exporter is inside the manifested surface
and the manifest did not need re-pinning. HOWEVER the manifest header's
standing practice (NOTE "S-basket item 8": "backend/driver/main.ml (already
manifested) grew the flag + the census printing"; NOTE "CN-0 … main.ml …
stay [files] entries … with their deltas shrunk back") is a header NOTE per
`main.ml` delta change, and the Z3 record has ZERO occurrences of
"manifest"/"fork_drift" (`grep -c` = 0) — the record does not say whether
the exporter change is inside the manifested surface. Remedy: one header
NOTE in the manifest (or one sentence in the record §3.1) stating that the
`--cabs-json` `digest` field is a hand-file delta on the already-manifested
`main.ml`, layer-2-invisible by design. Grade MINOR.

### 2.3 `CabsImport.parseJson` refusal
`lean_frontend/CabsImport.lean:782-792`: returns `(digest, tunit)`; refuses
a missing field (message names the Z3 bridge and the regenerate recipe), a
non-string, and a string that is not exactly 32 lowercase-hex characters.
Plants: §4.1.

### 2.4 `Main.lean` — digest install and the reversed stitch, read against the OCaml
* Per-TU digest: `runPipeline` (`Main.lean:951-966`) calls
  `CerberusFresh.setDigestIO digest` before `frontendTU`, where the OCaml
  sets it before its C parse (`pipeline.ml:181`); Cabs carries no `sym`, so
  the placement difference is inert (the pre-existing in-code note). Same
  in `loadLibc` for each of the 12 metadata TUs (`:640-649`).
* The stitch (`loadLibc` step 3, `:656-823`): (a) tags joined by name with
  a structural-equality refusal; (a') one representative tag symbol per
  name on BOTH halves — justified in-code by `AilTypesAux.are_compatible`
  (`ailTypesAux.lem:830-837`, verified: `Struct tag1, Struct tag2 -> tag1 =
  tag2`) reached through `PEare_compatible` from the `cfunction` funinfo
  lookup (`core_eval.lem:906`, verified); (b) functions by name, the
  definition's symbol wins over declarations; (c) globals by POSITION over
  the `GlobalDef` subsequence — count, kind, ail-ctype (tags by name) and
  name checked per entry, refusing on any disagreement (`pp_globs` skips
  `GlobalDecl`, `pp_core.ml:840-841`, verified); (d) every `LK_normal`/
  `LK_tentative` target of `metaFile.extern` must equal the joined symbol;
  (e) `renameFile`; (f) the dump's surviving tagDefs must agree; (g) the
  libc `globs` list is the METADATA's (decls included, as libc.co) with the
  renamed dump bodies. `extern`, `funinfo`, `tagDefs` are the metadata's.
* Against the link: the FINAL link (libc file + program) re-runs
  `merge_globs` over the libc globs (now the oracle's own bodies, renamed)
  ++ the program's, so the dependency edges are the oracle's and the keys
  are (real digests, elaboration-order-isomorphic numbers) — the order is
  determined by exactly the oracle's data. The run-time extern remap
  (`core_eval.lem:571-574`, `driver.lem:63 core_extern: declarations ->
  definitions`) resolves a program-side declaration symbol to the
  definition symbol the stitched `funs` are keyed by, which (d) checks.

### 2.5 `CoreParser.renameFile` — coverage vs the Core AST
Every sym-carrying constructor of the generated AST (`lean_frontend/
generated/Core.lean`, `Ctype.lean`, `Annot.lean`, `Symbol.lean`,
`Mem_common.lean`, `CerbMem.lean`) was listed and matched against the
renamer's arms:
* pexpr: `PEsym`, `PEmember_shift`, `PEstruct`, `PEunion`, `PEmemberof`,
  `PEcall (Sym ·)`, patterns in `PEcase`/`PElet`, `PEval` values,
  `PEarray_shift` ctype — all renamed; `PEmemop` takes `pure_memop`
  (`Mem_common.lean:634-`), which carries no `sym` — correctly untouched.
* expr: `Ememop (PtrMemberShift s id)`, `Eproc (Sym ·)`, `Esave` label +
  params (+ their `Option (ctype × …)`), `Erun`, patterns, `Eaction`/
  `Eexcluded` actions (incl. `SeqRMW`'s sym, `Create*`/`Alloc0` prefixes
  `PrefSource loc syms`, `Kill (Static0 ty)`) — all renamed; `Eannot`'s
  `dyn_annotation` (`DA_neg/DA_pos`, Nat/Footprint) has no sym.
* values: `OVstruct`/`OVunion` tags, `OVpointer (PV _ (PVfunction s))`,
  `PVnull ty`, `MVstruct`/`MVunion`/`MVpointer`/`MVunspecified`,
  `LVunspecified ty`, `Vctype`, nested lists/tuples — all renamed.
* ctype: `Struct`/`Union0` incl. nested `Array0`/`Pointer`/`Atomic`/
  `Function`/`FunctionNoParams`; `tag_definition` members, `AlignType`
  alignments, `FlexibleArrayMember` — all renamed.
* annots: `Atypedef sym`, `Ainlined_label (loc, sym, la)` renamed; the
  other 12 `annot` constructors carry no sym (`Annot.lean:270-297`).
* declaration keys: `funs`/`procs`/`builtins`/`globs` keys via `onSym`,
  `tagDefs` keys via `onTag`, `ailnames` values, `impls` bodies.
* UNHANDLED (one class): struct/union tags inside `core_base_type` —
  `OTy_struct sym`/`OTy_union sym` (`Core.lean:64-66`) reachable from
  `CaseBase (_, bty)`, `Fun`/`Proc`/`ProcDecl`/`BuiltinDecl` btys and
  parameter btys, `GlobalDef (bty, _)`/`GlobalDecl`, `Vlist bty`, `Cnil bty`,
  `Esave (s, bty)`, `Def`/`IFun`. These stay name-interned
  (`CoreParser.resolveOTyTag`, Z2-CP-13) while the same tag in ctype
  position becomes the metadata symbol. Observability: `grep -n
  'BTy_object\|BTy_loaded\|OTy_\|core_object_type'` over the exec-cone and
  linker `.lem` (`core_run`, `core_eval`, `core_reduction`, `driver`,
  `core_run_aux`, `core_linking`) returns NOTHING; `core_aux.lem:58-60/
  98-146` only DERIVE `OTy_*` from ctypes/values (Core typing consumes them,
  which `Main.lean` does not run — its "typecheck" is the AIL typing,
  `Main.lean:540-561`). So the class is not read at run or link time and
  cannot move a verdict; the plant of §4.2 (`div` returning a struct
  through a libc `Proc` whose return bty is `OTy_struct`) is the empirical
  witness. Grade NOTE: the record §3.2 / `CoreParser.lean:2747-2748` say
  "a total traversal of every symbol position" — overstated; either rename
  base-type tags too (three more arms: `core_object_type`, `core_base_type`,
  `ctor.Cnil`) or state the exclusion and why it is inert.
* Conflation hazards are the PRE-EXISTING ones of name-interning (a local
  binder sharing a libc global's/function's name is renamed uniformly at
  binder and use, so binding is preserved; `to_string_pretty` prints plain
  names at debug level ≤ 4, `pp_symbol.ml:12-24`). No new conflation is
  introduced: `onSym` is the identity on names outside `globMap ∪ funMap`.

## 3. Consumers of the cabs JSON (scope item 3)

Census (`git ls-files | grep '\.json$'` + `git grep -l '"tag": *"TUnit"'`):
the ONLY committed cabs artefacts are the ten `tests/fixtures/*/cabs.json`
goldens — all ten regenerated in `2ddc1300c`, each carrying `"digest"`, and
each digest equals `md5sum` of the fixture's `source.c` (10/10 checked). The
other committed `.json` files (`lake-manifest.json` ×3, `public/dist/*`,
`tests/bytes/{elab,exec}.json` = harness configs, `tools/*.json`) are not
cabs documents. Every producer (`grep -rl -e '--cabs-json' scripts tests
tools lean_frontend`: the 20+ `test_*.sh`, `libc_prep.sh --jsons`,
`gen_goldens.sh`, `tests/parity-probes/run_probe.sh`, `tests/noodle-probes`,
`tests/z2-probes`, `tests/mem-scale-probes/measure.sh`) generates JSON on
the fly from the freshly built oracle (`common.sh` `CERBERUS_BIN`), so the
digest is always present; `libc_prep.sh --jsons` output is uncommitted and
regenerated per lane ("not committed", its header). `parseJson`'s only
callers are `Main.lean:643` and `:1381` — no unit test feeds it an inline
document. refined-cerberus (`refined-cerberus/`, read-only): no
`cabs`/`parseJson`/`CabsImport`/`loadLibc` reference outside dated docs;
its `.cerberus-ws` is a Lake path dependency on the semantics library
pinned at `f95ef8d9c` (pre-Z3) — nothing to adapt. `test_golden.sh` (not
in the ladder) consumes the goldens; single-fixture probe §4.3. Backward
note (NOTE): a pre-Z3 Lean binary handed a post-Z3 JSON ignores the extra
key (`getField` looks keys up by name; the `TUnit` arm reads `decls` only),
so mixed-version pairings fail only in the safe direction (new Lean, old
JSON → loud refusal).

## 4. Plants

All plant inputs live in the ephemeral container scratch
`.tmp/z3-audit/` (deleted at slice end; the two C sources are reproduced
below in full so the plants are re-runnable). Every invocation through
`scripts/ce`, `CERB_MEM_MAX=16G`, `ulimit -c 0`; "after" = the arc worktree's
stamped binaries (`a8a4fe8f6`), "before" = the primary checkout's stamped
binaries at mainline `eb27fa70f` (`check_driver_fresh --check`: oracle `bin
54877507…/src 7f1a0c0a…`, lean `bin 00edd6fd…/src e9f05dfb…`, both OK).

### 4.1 The digest refusal (fail-closed) — PASS
The committed golden `tests/fixtures/001-return-literal/cabs.json` was
rewritten four ways (python: key deleted; digest truncated to 31 chars;
digest upper-cased; digest replaced by the integer 42) and handed to the
arc `cerberus-lean --batch`. Verbatim first two lines and rc, each:
```
##### nodigest
cerberus-lean: parse error: parseJson: missing 'digest' field — this cabs-json predates the zero-discrepancy Z3 bridge (regenerate it with the current oracle's --cabs-json; the Lean driver installs the source digest it carries as the TU digest, Cerb_fresh.set_digest mirror)
Error {msg: "cabs-json parse error: parseJson: missing 'digest' field \12 this cabs-json predates the zero-discrepancy Z3 bridge (regenerate it with the current oracle's --cabs-json; the Lean driver installs the source digest it carries as the TU digest, Cerb_fresh.set_digest mirror)"}
nodigest rc=1
##### shortdigest
cerberus-lean: parse error: parseJson: 'digest' is not a 32-character lowercase-hex MD5: 81c0f476cb2abad15583f4fcde44a0e
##### upperdigest
cerberus-lean: parse error: parseJson: 'digest' is not a 32-character lowercase-hex MD5: 81C0F476CB2ABAD15583F4FCDE44A0ED
upperdigest rc=1
##### intdigest
cerberus-lean: parse error: parseJson: 'digest' is not a string: 42
```
No verdict is printed on any of the four; the `Error {msg: …}` line is the
bridge class, not a Lean verdict (Z-70 holds). NOTE: the batch-escaped
`Error` line renders the em-dash as `\12` (`batchEscape` of a non-ASCII
byte) — cosmetic, pre-existing escaping behaviour, mentioned only because
the `\12` is not the character's code point.

### 4.2 The metadata JSONs and the "before" oracle
`scripts/libc_prep.sh --jsons` on the arc worktree: 12 files, every
`"digest"` equal to `md5sum runtime/libc/src/<tu>.c` (`EQ` ×12, derived).
The same script on the primary checkout (mainline oracle): 12 files, ZERO
carry a `digest` field — so a mainline-built libc JSON set handed to the
Z3 Lean binary would be refused loudly by §4.1's path (the safe direction).

### 4.3 Goldens
Arc `cerberus-lean` on the committed `cabs.json` of `001-return-literal`
and `025-struct-basic`: `return value: 42` / `return value: 30` =
`expected.txt` (42 / 30). (`test_golden.sh` itself was not run — not in
the ladder; this is the same read for two fixtures.)

### 4.4 Symbol-identity plants — function pointers, callbacks, struct returns, FILE* (the risky part)
`tests/parity-probes/run_probe.sh` (oracle `--exec --batch
--mode=exhaustive` vs Lean `--batch --libc … --libc-tu ×12`), libc mode,
60 s bound, `PD_LIBCJSON` pointing at each engine's own metadata JSONs.

`funptr_libc.c`:
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int cmp(const void *a, const void *b) { return *(const int*)a - *(const int*)b; }
static void bye(void) { puts("bye"); }
int g1 = 7;
int main(void) {
  int (*f)(const char *) = puts;
  int (*g)(const char *) = &puts;
  f("via-ptr");
  printf("f==g:%d f==puts:%d\n", f == g, f == puts);
  int a[5] = {5, 3, 9, 1, 4};
  qsort(a, 5, sizeof a[0], cmp);
  printf("%d %d %d %d %d\n", a[0], a[1], a[2], a[3], a[4]);
  div_t d = div(17, 5);
  printf("div %d %d\n", d.quot, d.rem);
  size_t (*sl)(const char *) = strlen;
  printf("len %d\n", (int)sl("hello"));
  printf("g1=%ld\n", (long)&g1);
  atexit(bye);
  return d.quot + d.rem;
}
```
AFTER (arc), verbatim:
```
=== ORACLE (exit 0) ===
Defined {value: "Specified(5)", stdout: "via-ptr\nf==g:1 f==puts:1\n1 3 4 5 9\ndiv 3 2\nlen 5\ng1=281474976710648\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(5)", stdout: "via-ptr\nf==g:1 f==puts:1\n1 3 4 5 9\ndiv 3 2\nlen 5\ng1=281474976710648\n", stderr: "", blocked: "false"}
=== VERDICT ===
AGREE VAL:Specified(5)
```
BEFORE (mainline), verbatim:
```
=== ORACLE (exit 0) ===
Defined {value: "Specified(5)", stdout: "via-ptr\nf==g:1 f==puts:1\n1 3 4 5 9\ndiv 3 2\nlen 5\ng1=281474976710648\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(5)", stdout: "via-ptr\nf==g:1 f==puts:1\n1 3 4 5 9\ndiv 3 2\nlen 5\ng1=281474976706016\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
```
Read: a libc function reached through a pointer (`PVfunction` of a renamed
symbol, both `puts` and `&puts`), pointer equality against the function
designator, a program callback invoked from inside libc (`qsort`→`cmp`),
`atexit`'s handler (`bye` runs after `main`: not visible in stdout because
the oracle's batch driver reports `main`'s stdout — identical on both
sides), a libc `Proc` whose return base type is `OTy_struct` (`div`, the
§2.5 witness) and a program global's address ALL agree after; before, the
one movement is the address (`…706016` → `…710648`), the Z-28 class.

`struct_libc.c`:
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
struct P { int x; long y; } pa = {1, 2}, pb;
int main(void) {
  fputs("fputs\n", stdout);
  fputc('c', stdout); fputc('\n', stdout);
  fprintf(stdout, "%s %d\n", "fprintf", 42);
  double v = strtod("2.5e1", NULL);
  printf("strtod %d\n", (int)v);
  char buf[32];
  int n = snprintf(buf, sizeof buf, "%d-%d", 3, 4);
  printf("%s %d\n", buf, n);
  memcpy(&pb, &pa, sizeof pa);
  printf("pb %d %ld pa=%ld pb=%ld\n", pb.x, pb.y, (long)&pa, (long)&pb);
  return pb.x + (int)pb.y;
}
```
AFTER (arc): 64 executions per side (the `fputc` pair's unsequenced
interleavings), every one byte-identical; verdict line verbatim (trimmed to
its head — 64 identical `VAL:Specified(3)` entries):
```
Defined {value: "Specified(3)", stdout: "fputs\nfprintf 42\nstrtod 25\n3-4 3\npb 1 2 pa=281474976706032 pb=281474976706016\n", stderr: "", blocked: "false"}   [oracle, EXECUTION 0..63]
Defined {value: "Specified(3)", stdout: "fputs\nfprintf 42\nstrtod 25\n3-4 3\npb 1 2 pa=281474976706032 pb=281474976706016\n", stderr: "", blocked: "false"}   [Lean, EXECUTION 0..63]
=== VERDICT ===
AGREE VAL:Specified(3)|VAL:Specified(3)|…
```
BEFORE (mainline): oracle lines identical to the above; Lean `pa=281474976706000
pb=281474976705984` on all 64 → `STDOUT-DIFF (values equal, Defined lines
differ)`. (The `fputc('c')` output is absent from BOTH engines' stdout on
both trees — the oracle's own libc behaviour, agreed on all four runs; not
a Z3 matter.) Read: libc-INTERNAL cross-TU struct-pointer calls (`fputs`/
`fprintf`/`printf` → the stdio `FILE*` family; `strtod` → `__strtoxd`),
`snprintf`, and a libc call over a program struct agree after; before, only
the addresses differ, by the same 32-byte libc-order shift.

Plants NOT run (named): a libc-internal cross-TU call passing a struct BY
VALUE (none exists in the shipped libc sources' internal call graph as far
as the record states; the one-tag-per-name frame is exercised only through
pointers here); `--nolibc` regressions (Tier A rows 2–4c cover them, 0
movement); a program declaring a libc function with a DIFFERENT prototype
(UB041 path) — the `002-puts`/`strtod-inf` regression the record §6.5
describes is covered by lane 5 / immaculate.

## 5. Pins and baselines (scope item 4)

* `tests/libc_exec/012-global-alloc-order.c` — `baseline.txt` gains
  `012-global-alloc-order MATCH`; the arc battery's lane 5 line (verbatim,
  from `.tmp/z3-reverify.log`): `  MATCH 012-global-alloc-order: Defined
  {value: "Specified(0)", stdout: "s1=281474976707472 c1=281474976707471 i`
  … `SUMMARY: match=12 diff=0`.
* Five `tests/immaculate/libc/zd-z28-*` rows added MATCH to
  `tests/immaculate/baseline.txt` (diff read; header paragraph added to
  `test_immaculate.sh`'s `--record-baseline` text and the baseline). The
  three copied pins and both headers are BYTE-IDENTICAL to their
  `tests/pnvi_testsuite/` originals (`cmp`, 5/5), so their oracle digests —
  hence interleavings — equal the sweep rows'. `zd-z28-addr-layout-{a,b}.c`
  differ in exactly one comment line (`diff`: line 6 `This is file A.` /
  `This is file B.`) and pin DIFFERENT addresses (`s1=281474976706032` vs
  `s1=281474976707776`) — a genuine digest-sensitivity witness.
* The ND `_yx` rows: `backend/driver/main.ml` `exec_mode` defaults to
  `Random` (`:453-456` on the rebased tree; the record's `:438-441` is the
  pre-fix numbering — NOTE) and `driver_ocaml.ml:153/:194` `Random.self_init
  ()` — a two-execution program prints one line per run, so the single-trace
  immaculate lane cannot pin it; the argument holds. The exhaustive spot
  sweep carries them (record §5.3/§5.4, `stdout_diff=0`).
* The pnvi sweep before/after diff (record §5.3): exactly the nine
  `STDOUT_DIFF → MATCH` flips; the "three extra rows"
  (`pointer_from_integer_1ig/1pg`, `provenance_equality_uintptr_t_auto_yx`)
  are locals-only programs whose `&j` padding depends on the libc globals
  allocated before them — the same libc-order root cause; their Lean lines
  before differ from the oracle's only in the address hex, and after are
  byte-identical. Read as the same root cause: yes.

## 6. Battery log (scope item 5)

`.tmp/z3-reverify.log` (the orchestrator's re-verification on the arc
worktree's rebased head, 10:41–11:32 UTC, read after `=== DONE`). Stamps:
`check_driver_fresh: oracle OK (bin 5bf3b347637624aab9347062864e90406d1080f2969e52c92c54e9845105742f, src 15a3689ea020340129625c8999b49f8738313099d4530b073ba1806cd55ec6c4)`,
`check_driver_fresh: lean OK (bin 17a894c3f22e9340505b983ea02ccff6df6b42e54734b56e0df8076ec157429c, src 0611a6a63b48517c130eaf9914cb071acde493f616d9b45cb2fe50c2d788a8e3)`
— the lean stamp equals the record §5.4's; the oracle BIN differs from the
record's `48312b25…` (same src `15a3689e…`): the orchestrator rebuilt the
oracle (`=== rebuild` at the log head), a non-reproducible-binary
difference with identical sources — NOTE, expected.

Lanes and their `--- rc=` lines (derived: 26 lane invocations, 26 × rc=0):
`test_unit.sh` (tail `test_renumber_plants: OK (12 plants …)`), `test_exec.sh
--check-baseline` (`Baseline check: 0 regression(s), 0 improvement(s)`),
`… tests/coverage` (0/0), `… tests/debug` (0/0), `… tests/float` (0/0),
`test_bytes.sh` (`SUMMARY: exec_match=9 neg_pinned=5 fail=0`),
`test_libc_exec.sh` (`SUMMARY: match=12 diff=0` / `ALL MATCH RECORDED
BASELINE`), `test_multi_tu.sh` (`total=2 match=2 fail=0`), `test_parse.sh`
(`Lean parse: 106 ok, 0 failed`), `test_core.sh` (`106 ok, 0 failed`),
`test_elab.sh` (`total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0`),
`test_libxml2_uri.sh` (`[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI
corpus)` / `GATE PASS`), `test_cn_coverage.sh --check-baseline` (`total=213
match=207 ub_match=6 … mismatch=0` / `BASELINE OK (213 entries, exact
match)`), `test_parse.sh tests/ci` (`ALL PASSED`), `test_core.sh tests/ci`
(`Lean parse: 128 ok, 0 failed`), `test_verify.sh` (`test_verify: 127 passed,
0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus
points)`), `test_immaculate.sh` (`OK: lane matches the committed baseline
(MATCH except the ISO-fix register pins R1 …, R2 …, R3 … and the in-Lean
probes g6 TRIPWIRE / illtyped-store KILL)`), `test_speclab.sh --selftest`
/ `--plant` (PASS / PASS), `test_hang_plant.sh`, `test_kill_plant.sh`,
`test_fuel_plant.sh` (all plants OK), `test_libxml2.sh` (`SUMMARY: total=4
match=4 fail=0 (points: 1354, 22 observations each)`), and the gcc lane,
verbatim tail:
```
=== ./scripts/test_gcc_oracle.sh --check-baseline
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/gcc_oracle_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
--- rc=0
=== DONE
```
The load-caveat gcc row: the record §5.2 reports `sa_csmith_231.c`
`AGREE → SKIP_LEAN_TIMEOUT` under load ~30 (two foreign gcc lanes), and
§5.4 its quiet re-run at baseline; this log is a THIRD read at baseline
(`0 regression(s)`, `skip_lean_timeout=11` = the record's quiet count; the
box load at the lane's start was 4.9/16.0/12.7 by `uptime` in the log, and
0.73 at `=== DONE`). The LADDER row-7 caveat was applied correctly and the
row is not red.

## 7. Lanes re-run by the auditor (scope item 6)

Run by the auditor on the arc worktree AFTER the battery's `=== DONE`
(11:32:47), serially, `scripts/ce`, `CERB_MEM_MAX=16G`, `ulimit -c 0`; full
logs were in `.tmp/z3-audit/lane-*.log` (ephemeral; the verdict lines below
are verbatim from them).

`./scripts/test_unit.sh` — 11:34:15 → 11:37:27, rc=0. Gate lines:
```
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_fork_drift: OK — layer 1: 71 oracle-surface files = manifest; layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```
(`check_fork_drift.sh` also run directly: the same `OK` line, rc=0. Read
with §2.2: `main.ml` is one of the 71 layer-1 files; the 22 layer-2 hashes
are unmoved because no generated `.ml` changed.)

`./scripts/test_verify.sh` — 11:37:45 → 11:38:27, rc=0:
```
Build completed successfully (271 jobs).
check_driver_fresh: recorded lean stamp (bin 17a894c3f22e9340505b983ea02ccff6df6b42e54734b56e0df8076ec157429c, src 0611a6a63b48517c130eaf9914cb071acde493f616d9b45cb2fe50c2d788a8e3)

test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```

`./scripts/test_immaculate.sh` — 11:38:37 → 11:39:37, rc=0; the five Z3 rows
(oracle half of each line, verbatim; the Lean halves are equal — MATCH):
```
  MATCH          zd-z28-addr-layout-a  O[VAL:{value: "Specified(0)", stdout: "s1=281474976706032 c1=281474976706031 i1=281474976706024 p1=281474976706016\n", stderr: "", blocked: "false"}] L[…]
  MATCH          zd-z28-addr-layout-b  O[VAL:{value: "Specified(0)", stdout: "s1=281474976707776 c1=281474976707775 i1=281474976707768 p1=281474976707760\n", stderr: "", blocked: "false"}] L[…]
  MATCH          zd-z28-pointer_from_integer_2g  O[VAL:{value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffede8)\n", stderr: "", blocked: "false"}] L[…]
  MATCH          zd-z28-provenance_equality_uintptr_t_global_yx  O[VAL:{value: "Specified(0)", stdout: "Addresses: p=fffffffff3a0 q=fffffffff3a0\n(p==q) = true\n", stderr: "", blocked: "false"}] L[…]
  MATCH          zd-z28-provenance_lost_escape_1  O[VAL:{value: "Specified(0)", stdout: "Addresses: p=(@17, 0xfffffffff4cc)\n", stderr: "", blocked: "false"}] L[…]
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```
The three copied rows print exactly the committed 2026-08-22 `pnvi.tsv`
oracle lines quoted in the record §1.1 (`(@70, 0xffffffffede8)`,
`fffffffff3a0`, `(@17, 0xfffffffff4cc)`).

`./scripts/test_libc_exec.sh` — 11:39:49 → 11:40:12, rc=0:
```
  MATCH 012-global-alloc-order: Defined {value: "Specified(0)", stdout: "s1=281474976707472 c1=281474976707471 i

SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
```
Derived: 4/4 lanes rc=0, every Z3 pin MATCH, every gate line OK.

## 8. Not checked

* `test_golden.sh` as a lane (not in the ladder; one fixture probed, §4.3).
* A libc-INTERNAL cross-TU struct-typed call other than the `FILE*` family
  exercised by the puts/fputs/fprintf/strtod paths (record §6.6 names this
  as a Z4 probe suggestion; §4.2 adds `div`/`strtod`/`snprintf` witnesses).
* `--pp core` of the stitched libc file vs `libc.co`'s dump (a
  symbol-by-symbol textual comparison of the renamed file) — not attempted.
* Lanes other than the four named ones; the orchestrator's battery (§6) is
  the record for those.
* `Main.lean:625` `setDigestIO (md5Hex dumpContent)` before the dump parse
  (pre-existing, not touched by Z3; the dump's symbols are name-interned
  with digest "" regardless) — its purpose was not re-derived.
* The upstream-tray / concurrency worktrees: read-only, untouched.
