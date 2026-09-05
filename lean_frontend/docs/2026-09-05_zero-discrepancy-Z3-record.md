# ZERO-DISCREPANCY — slice Z3 record: the libc-mode allocation-address order (2026-09-05)

Branch `arc/z3-libc-order` (worktree `worktrees/cerberus-lean-arc/z3-libc-order`),
base `928aa1e76` = mainline `mdd/cerberus-lean` (fuel-parameter C3 boundary
review) for every measurement and battery of §1–§5.2; REBASED at the end of
the slice onto `eb27fa70f` (the cerbglobal-defs merge, coordinator notice —
its delta: `CerbGlobal.lean`, `test/Unit/FuelExemplar.lean`,
`check_exec_purity.sh`/`check_theorem_axioms.sh`/`unsafebaseio_allowlist.txt`,
docs; no Z3 file), regenerated, rebuilt, re-stamped, and re-gated per §5.4;
lem pin `d4ba548` unchanged. Work order: charter
`docs/2026-09-03_zero-discrepancy-design.md` §1 (the rule), §2.3 row Z-28,
§2.7 Z-69, §6 Z3; detective report `docs/2026-08-30_parity-detective-report.md`
RC-2. Author: the Z3 worker [AGENT]; the rule applied is [USER 2026-09-03]
(charter §1.1: Lean ≠ oracle on a program both run in matched mode is a bug;
addresses are values under PVI, so allocation order is behaviour); every
measurement, classification and design choice below is [AGENT]. Quoted engine
lines are verbatim from this worktree's runs; tallies are labelled derived.

Binaries. Start of slice (every "before" line below): `check_driver_fresh:
recorded oracle stamp (bin 496eb5683a8a63ef1c2f465d5d6f601bb152464a539f39a8355ba7fb263cfc80, src 7f1a0c0afb84d4a2bac8e240197ae9d72d194985237aeb35ae16afa5cce912bf)`,
`recorded lean stamp (bin fbd8e397944f350b4024507ea888735db18dd7ab3daeec86e554d47ec89d557c, src caa6f8b8d0bd9839d68682acd6b28b9963a85919dc2ecc2b5fb25d7e060c6bc4)`
at `928aa1e76`. After the fix (every "after" line): oracle `bin ee94b1fcebc87d0926599931310784d41b5182b78a1b3a58baa8612ab2048fac, src 15a3689ea020340129625c8999b49f8738313099d4530b073ba1806cd55ec6c4`,
lean `bin 928c1995a956e8b80d44daa078f4a971a09ebd271af344821da4645c20dc287d, src b0ec32500df413772fe1e644c9c8f67a3a96b7cf14f248ee084d90dd626d77b5`.
Every lake/lean/Lean-binary invocation through `scripts/capped`,
`CERB_MEM_MAX=32G`; lanes serial; `ulimit -c 0`.

## 0. Headline (derived)

* Z-28 is FIXED: the nine `tests/pnvi_testsuite` rows that printed addresses
  (the charter's six + three that had moved into STDOUT_DIFF since the
  committed 2026-08-22 sweep) AGREE byte-for-byte in exhaustive mode (§1.3);
  `tests/libc_exec/012-global-alloc-order` and the five immaculate `zd-z28-*`
  pins flipped DIFF → MATCH (§4).
* Root cause (§2): the order of the linked globals is `Core_linking.merge_globs`'
  topological sort with ties broken by the smallest `(digest, number)` symbol,
  and the Lean libc file's symbols were name-interned (digest "", number =
  hash) — so every libc global sorted first, in hash order — while the Lean
  program TU's digest was the MD5 of the cabs-json text, not of the C source
  the oracle digests.
* Mirror (§3): the cabs-json bridge now carries the oracle's `Digest.file`
  digest and Lean installs it per TU; the libc loader's stitch is reversed —
  the dump's bodies are renamed onto the metadata's symbols (which carry the
  oracle's digests and order-isomorphic numbers), globals joined by POSITION
  under fail-closed order/kind/ctype/name checks. No `.lem` body changed.
* Battery: Tier A + Tier B on the fresh stamped binaries — §5 (verbatim, rc
  per lane). Other movement: none beyond the pins and the sweep rows, except
  the two findings in §6 (a pnvi `LEAN_TIMEOUT` and a worktree build-state
  gap in the axiom gate), both understood.

## 1. Measurements — findings are claims

### 1.1 The six charter rows, re-measured BEFORE (matched libc mode; oracle `--exec --batch --mode=exhaustive`, Lean `--batch --libc …`; `tests/parity-probes/run_probe.sh`)

```
##### pointer_from_integer_2g
=== ORACLE (exit 0) ===
Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffede8)\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffedd0)\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
##### provenance_equality_auto_yx
=== ORACLE (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedc8) q=(@73, 0xffffffffedc8)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedc8) q=(@73, 0xffffffffedc8)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedb0) q=(@73, 0xffffffffedb0)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedb0) q=(@73, 0xffffffffedb0)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
##### provenance_equality_global_fn_yx
=== ORACLE (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@1, 0xfffffffffff8) q=(@0, 0xfffffffffff8)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@1, 0xfffffffffff8) q=(@0, 0xfffffffffff8)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
##### provenance_equality_global_yx
=== ORACLE (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
EXECUTION 0:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = true\n", stderr: "", blocked: "false"}
EXECUTION 1:
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = false\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
##### provenance_equality_uintptr_t_global_yx
=== ORACLE (exit 0) ===
Defined {value: "Specified(0)", stdout: "Addresses: p=fffffffff3a0 q=fffffffff3a0\n(p==q) = true\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(0)", stdout: "Addresses: p=ffffffffede0 q=ffffffffede0\n(p==q) = true\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
##### provenance_lost_escape_1
=== ORACLE (exit 0) ===
Defined {value: "Specified(0)", stdout: "Addresses: p=(@17, 0xfffffffff4cc)\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(0)", stdout: "Addresses: p=(@68, 0xffffffffede0)\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
```

The oracle lines equal the committed `tests/ci_sweep/results/pnvi.tsv` rows
(2026-08-22 snapshot) exactly; the Lean lines differ from the snapshot's by a
few bytes of padding (`edd0` vs `edec`, `edb0` vs `edcc`, …) — the Z1
`IvMaxAlignment` mirror (Z-76) moved the Lean layout after the snapshot; the
class did not. Note the two `_yx` rows with two executions: the oracle's
default `--mode=random` (`Random.self_init`, backend/common/driver_ocaml.ml:153)
picks ONE of them per run (measured: three single-trace runs of
`provenance_equality_global_fn_yx` printed `false`/`true`/`true`), which is
why those rows are pinned only through the exhaustive spot sweep (§4).

### 1.2 The minimal probe (three engines)

`.tmp/z3/probes/addr_layout.c` (committed as
`tests/libc_exec/012-global-alloc-order.c` with a header comment — a
different digest, hence different addresses there, §4): five program
globals of mixed alignment (`struct S {char; double} s1; char c1; int i1;
int *p1 = &i1; long l1;`), the libc global `optind` via `<unistd.h>`, a
local; each printed as `(long)&g`.

```
=== ORACLE (exit 0) ===
Defined {value: "Specified(0)", stdout: "s1=281474976706032 c1=281474976706031 i1=281474976706024 p1=281474976706016 l1=281474976706008 optind=281474976707156\nloc=281474976705944\n", stderr: "", blocked: "false"}
=== LEAN (exit 0) ===
Defined {value: "Specified(0)", stdout: "s1=281474976706000 c1=281474976705999 i1=281474976705992 p1=281474976705984 l1=281474976705976 optind=281474976708324\nloc=281474976705912\n", stderr: "", blocked: "false"}
=== VERDICT ===
STDOUT-DIFF (values equal, Defined lines differ)
--- gcc
s1=98424845926464 c1=98424845926416 i1=98424845926420 p1=98424845926432 l1=98424845926424 optind=98424845926448
loc=140722644760756
gcc rc=0
```

gcc is not meaningful for the absolute addresses (the gcc lane's class for
such programs is `TRIAGED_ADDR`); it agrees on the value-level content (exit
0 = both alignments hold and `*p1 == 1`). Under `--nolibc` the same probe
shape agreed already (detective RC-2): the divergence is the libc link only.

### 1.3 AFTER — the same nine rows and the probe (oracle unchanged, Lean now identical)

```
##### pointer_from_integer_2g
Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffede8)\n", stderr: "", blocked: "false"}   [oracle]
Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffede8)\n", stderr: "", blocked: "false"}   [Lean]
AGREE VAL:Specified(0)
##### provenance_equality_auto_yx        (2 executions each side, byte-identical)
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedc8) q=(@73, 0xffffffffedc8)\n(p==q) = true\n", stderr: "", blocked: "false"}
Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedc8) q=(@73, 0xffffffffedc8)\n(p==q) = false\n", stderr: "", blocked: "false"}
AGREE VAL:Specified(0)|VAL:Specified(0)
##### provenance_equality_global_fn_yx   (2 executions each side, byte-identical)
Defined {value: "Specified(0)", stdout: "Addresses: p=(@1, 0xfffffffffff8) q=(@0, 0xfffffffffff8)\n(p==q) = true\n", stderr: "", blocked: "false"}
Defined {value: "Specified(0)", stdout: "Addresses: p=(@1, 0xfffffffffff8) q=(@0, 0xfffffffffff8)\n(p==q) = false\n", stderr: "", blocked: "false"}
AGREE VAL:Specified(0)|VAL:Specified(0)
##### provenance_equality_global_yx      (2 executions each side, byte-identical)
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = true\n", stderr: "", blocked: "false"}
Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = false\n", stderr: "", blocked: "false"}
AGREE VAL:Specified(0)|VAL:Specified(0)
##### provenance_equality_uintptr_t_global_yx
Defined {value: "Specified(0)", stdout: "Addresses: p=fffffffff3a0 q=fffffffff3a0\n(p==q) = true\n", stderr: "", blocked: "false"}   [both]
AGREE VAL:Specified(0)
##### provenance_lost_escape_1
Defined {value: "Specified(0)", stdout: "Addresses: p=(@17, 0xfffffffff4cc)\n", stderr: "", blocked: "false"}   [both]
AGREE VAL:Specified(0)
##### pointer_from_integer_1ig           (2 executions each side, byte-identical)
Defined {value: "Specified(0)", stdout: "j=5 &j=(@72, 0xffffffffeddc)\n", stderr: "", blocked: "false"}
AGREE VAL:Specified(0)|VAL:Specified(0)
##### pointer_from_integer_1pg           (2 executions each side, byte-identical)
Defined {value: "Specified(0)", stdout: "j=5 &j=(@73, 0xffffffffedd4)\n", stderr: "", blocked: "false"}
AGREE VAL:Specified(0)|VAL:Specified(0)
##### provenance_equality_uintptr_t_auto_yx
Defined {value: "Specified(0)", stdout: "Addresses: p=ffffffffedc8 q=ffffffffedc8\n(p==q) = true\n", stderr: "", blocked: "false"}   [both]
AGREE VAL:Specified(0)
##### addr_layout
Defined {value: "Specified(0)", stdout: "s1=281474976706032 c1=281474976706031 i1=281474976706024 p1=281474976706016 l1=281474976706008 optind=281474976707156\nloc=281474976705944\n", stderr: "", blocked: "false"}   [both]
AGREE VAL:Specified(0)
```

(The full two-sided transcripts are in the lane logs quoted in §5; the
compressed form above drops the repeated `=== ORACLE/LEAN ===` headers and
duplicated lines only.)

## 2. Diagnosis — the order and its keys

**What orders the globals.** After `Core_linking.link` the file's `globs`
list is produced by `merge_globs` (frontend/model/core_linking.lem:252-273):
a topological sort over the union of both files' globals (a global depends
on the symbols free in its initialiser, `free`, :230-233; the ready set is
`empty_dep`, :235-238), whose ready set is a `set sym` and whose next
element is `Set_extra.choose` (`topo_order`, :240-250, the choice at :245)
= `Pset.choose` = `min_elt` (lem ocaml-lib pset.ml:297) under the set's comparator `symbol_compare` — digest first,
then number (frontend/model/symbol.lem:157-160; digests compare as raw MD5
bytes, `Digest.compare`). `Driver.driver_globals` (frontend/model/driver.lem:
1564-1640; the list is read at :1578, allocation loop :1585-1639) then evaluates — i.e. `create`s — the definitions in exactly that
list order, so each global's address is fixed by the `(digest, number)` of
every global sorted before it. The LemLib target of `Set_extra.choose` is the
same `min_elt` (`setChoose … = Pset.choose`, lean-lib/LemLib.lean:780), so
the generated Lean computes the same order from the same keys — the keys
were the divergence.

**The oracle's keys.** libc.co's symbols carry the digest of their libc
SOURCE file — `Cerb_fresh.set_digest filename` is `Digest.file`
(util/cerb_fresh.ml:88-94) at the top of `c_frontend`
(backend/common/pipeline.ml:181) when `runtime/libc/dune:145-146` builds
libc.co from `src/ctype.c … src/signal.c` — and the build's single-supply
numbers. The program's symbols carry `Digest.file` of the program's `.c`.
Evidence, derived: the twelve source digests (`md5sum runtime/libc/src/*.c`,
identical to the `_build` copies) are
`1903…` time, `2bfa…` stdio, `410c…` uio, `60cc…` stat, `6ab7…` ctype,
`861c…` string, `9134…` signal, `a37b…` internal, `a630…` unistd, `cba3…`
stdlib, `d006…` utime, `fb6f…` vfscanf; the libc.co dump at debug level 5
(`--pp=core -d5`, symbol numbers shown) lists the 68 definitions in the order
stdio (1714–2073, `a_6371`, `a_9549`, `a_10546`) · stat (`a_22432`,
"/proc/self/fd/") · string (`a_18504`) · signal (37445–37814) · internal
(23580–32697) · unistd (21357–22149) · stdlib (11122–13660) — i.e. ascending
source digest, ascending number within a TU except where a dependency holds
a global back (`__stdout` (1714) waits for `__stdout_FILE` (1892), then is
the minimum). The program's position among them is its own digest's:
`provenance_equality_global_fn_yx.c` (`04cf…`, below every libc digest)
gets `@0`/`@1`; `provenance_lost_escape_1.c` (`5170…`, between uio and stat)
gets `@17`; `provenance_equality_global_yx.c` (`ce6b…`, between stdlib and
utime) gets `@68`/`@69`; the probe (`d45e…`) is allocated after stdlib's
globals in the oracle's `-d6` trace (`Starting the evaluation of global …`,
75 lines, the reverse of the allocation sequence because `ND.mapM_` prints at
construction time). Every observed position matches the digest order.

**Lean's keys before Z3.** (i) The libc file's symbols were CoreParser's
`mkSym name = Symbol "" name.hash (SD_Id name)` (CoreParser.lean:242): digest
"" sorts below every real digest, so all 68 libc globals were allocated
first, in name-HASH order among themselves (hence the different padding even
for programs with no globals of their own, e.g. `pointer_from_integer_2g`);
(ii) the program TU's digest was `md5Hex` of the cabs-json TEXT (Main.lean's
per-TU loop, "divergence recorded in CerberusFresh.lean") — a value unrelated
to the oracle's, so even with faithful libc keys the program would have
landed in the wrong slot.

In three sentences: the linked globals are allocated in `merge_globs`'
topological order with ties broken by the smallest `(digest, number)` symbol
(core_linking.lem:252-273 + driver.lem:1564-1640); the oracle's keys are the
`Digest.file` digests of the libc sources and of the program (pipeline.ml:181)
with single-supply numbers; the Lean libc file's name-interned symbols
(digest "", hash numbers) and the Lean program digest (of the JSON text) put
every libc global first, in hash order, and the program's globals last.

## 3. The mirror

No `.lem` body changed; the seams are hand-written glue, mirrored with cites.

1. **The bridge carries the oracle's digest.** `backend/driver/main.ml`
   `--cabs-json` path appends `"digest": Digest.to_hex (Cerb_fresh.digest ())`
   to the `TUnit` object — the value `set_digest filename` (= `Digest.file`,
   mirrored from pipeline.ml:181) just installed; a non-object serialisation
   `failwith`s. `CabsImport.parseJson` now returns `(digest, tunit)` and
   REFUSES a document without a 32-hex-digit `digest` (a stale bridge
   artifact). `Main.runPipeline` installs that digest per TU
   (`CerberusFresh.setDigestIO digest`) where it used to hash the JSON text;
   `CerberusFresh.lean`'s header records that what is digested is now the same
   on both sides. The ten `tests/fixtures/*/cabs.json` goldens were
   regenerated with the new oracle (they carry the field; their locations are
   this box's runtime-relative paths instead of the original author's absolute
   ones — `test_golden.sh` reads return values only).
2. **The libc stitch is reversed** (`Main.loadLibc`; module note "C-libc
   loading" rewritten). The 12 metadata TUs are frontended under the digests
   their cabs-jsons carry — `Digest.file` of `runtime/libc/src/<tu>.c`, the
   very digest libc.co's symbols carry — so their symbols order like the
   oracle's (numbers are the Lean supply's, order-isomorphic within a TU:
   the same lem elaboration draws them). The DUMP is then renamed onto the
   metadata's symbols by `CoreParser.renameFile` (new, CoreParser.lean:
   section "Symbol renaming": a total traversal of every symbol position in
   patterns, pexprs, actions, exprs, values incl. `PVnull`/`PVfunction`
   pointer values and ctype tags, fun/glob/tag declaration keys; two
   namespaces, ordinary identifiers vs struct/union tags, because `struct
   stat` and the function `stat` coexist):
   * tags by name — same-name definitions across TUs must agree
     structurally (fail-closed); ONE representative symbol per tag name, on
     both halves (the metadata's funinfo ctypes, tagDefs keys/members and
     decl-globs ctypes are moved onto it too), because the run-time
     compatibility check requires tag-symbol EQUALITY
     (`AilTypesAux.are_compatible`, ailTypesAux.lem:830-837, reached from
     every elaborated call via `PEare_compatible`, core_eval.lem:1090-1099)
     and the oracle satisfies it by checking a call site against the CALLER
     TU's own declaration entry (`cfunction` reads funinfo on the pointer's
     symbol before the extern remap, core_eval.lem:906) — a body from the
     dump cannot say which TU it came from, so the one-tag-per-name frame of
     the pre-Z3 loader is kept, now under a real `(digest, number)` symbol.
     (Measured while developing: with per-TU tags left in funinfo, every
     libc-internal call passing a `FILE*` — `puts`→`fputs`, `strtod`→
     `__strtoxd` — reported `UB041_function_not_compatible`; §6.)
   * functions by name — the DEFINITION's symbol where a name is declared
     in one TU and defined in another (`__strtox`/`__strtoxd`), checked
     against `metaFile.extern`'s `LK_normal`/`LK_tentative` targets
     (fail-closed);
   * globals by POSITION over the definitions — the metadata's linked
     `globs` is the same `merge_globs` over the same keys and edges as
     libc.co's link, so its `GlobalDef` subsequence must equal the dump's
     list (the dump prints only definitions, pp_core.ml:840-841; libc.co and
     the metadata also carry the declaration-only entries, kept as in
     libc.co). Checked entry by entry — count, kind, ail ctype (tags by
     name), name (named globals by name; the unnamed `a_<n>` string-literal
     globals have no name to join on, so position is their ONLY join and the
     whole-list agreement is load-bearing) — any disagreement refuses the
     load with a message naming the position. Both checks fired during
     development (68 definitions vs 91 entries before the definition filter;
     `__stdout` "twice" before definitions were allowed to shadow the
     header's per-TU `extern FILE *const __stdout;` declarations) — the
     refusals are loud and attributed, as the rule wants.
   The assembled libc file: `globs` = the metadata's list with each
   definition's body from the renamed dump; `funs` from the renamed dump
   (Proc over ProcDecl as before); `tagDefs`/`funinfo` = the metadata's,
   in the one-tag frame; `extern` = the metadata's. funinfo parameter-name
   symbols are now KEPT (they were dropped before).

Documented residual divergences (in the module note): symbol NUMBERS are
the Lean supply's (equal to libc.co's up to a per-TU offset — every
`symbol_compare` outcome agrees; the absolute number shows only in `a_<n>`
names inside Illformed_program payloads, Z-04/EXC(a)); the one-tag-per-name
frame (structurally-equal definitions, checked); same-named static functions
conflate to one body (pre-existing).

Consumer note: `CabsImport.parseJson`'s type changed (`Except String
translation_unit` → `Except String (String × translation_unit)`) and
`CoreParser.RenameCtx`/`renameFile`/`renameCtype`/`renameTagDef` are new
public entries; `Main.loadLibc`'s signature is unchanged. refined-cerberus
does not use the libc link or `parseJson` (it consumes the Core semantics,
not the driver's bridge) — nothing to adapt there.

## 4. Pins

* `tests/libc_exec/012-global-alloc-order.c` — pinned DIFF at `f38adabf4`
  (`O: … s1=281474976707472 …`, `L: … s1=281474976706000 …`; the header
  comment gives it digest `a1c3…`, so its oracle addresses differ from the
  probe's), re-recorded MATCH by the fix commit: `SUMMARY: match=12 diff=0`.
* `tests/immaculate/libc/zd-z28-{pointer_from_integer_2g,provenance_equality_uintptr_t_global_yx,provenance_lost_escape_1}.c`
  — BYTE-IDENTICAL copies of the deterministic three of the six charter
  rows (+ the two local headers they include, `charon_address_guesses.h`,
  `refinedc.h`); `zd-z28-addr-layout-{a,b}.c` — one program under two
  digests (comment-only difference): pinned DIFF, re-recorded MATCH at
  DIFFERENT addresses (`a: s1=281474976706032 …`, `b: s1=281474976707776 …`,
  both sides). The three `_yx` rows with two executions are NOT immaculate
  pins (the oracle's single-trace default is `Random.self_init`-random,
  §1.1); the exhaustive spot sweep below carries them.
* `tests/pnvi_testsuite` spot sweep (`test_ci_sweep.sh --suite pnvi --out
  <scratch>`, exhaustive both sides; the committed TSV is Z4's re-record and
  is NOT touched): §5.3, before/after.

## 5. Gates and battery (verbatim tails, rc per lane)

### 5.1 Tier A after the fix (`.tmp/z3/tierA.sh`: serial, `scripts/ce`, `CERB_MEM_MAX=32G`; log verbatim, per lane `=== label :: command`, `--- rc=N`, last 4 lines)

```
=== 01-unit :: ./scripts/test_unit.sh
--- rc=0
  OK (admitted as declared): layout_rewrap [RENUMBER-ONLY ADMIT plant/layout_rewrap class=LAYOUT ids=2 moved=2 canon=9b2ed22f1988]
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
=== 02-exec-min :: ./scripts/test_exec.sh --check-baseline
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 03-exec-cov :: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_coverage_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04-exec-debug :: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_debug_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04b-exec-float :: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_float_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04c-bytes :: ./scripts/test_bytes.sh
--- rc=0
[NEG_OK] only_unsigned_char.c: Lean-side desugar/typing rejection at the committed diagnostic line 1 (rc 1)

SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
=== 05-libc-exec :: ./scripts/test_libc_exec.sh
--- rc=0
  MATCH 012-global-alloc-order: Defined {value: "Specified(0)", stdout: "s1=281474976707472 c1=281474976707471 i

SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
=== 06-multi-tu :: ./scripts/test_multi_tu.sh
--- rc=0

==================================================
SUMMARY: total=2 match=2 fail=0
ALL PASSED
=== 07-parse :: ./scripts/test_parse.sh
--- rc=0
Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)
Success rate:   100% (of cerberus successes)

ALL PASSED
=== 08-core :: ./scripts/test_core.sh
--- rc=0
Lean parse:     106 ok, 0 failed
Success rate:   100% (of cerberus successes)

ALL PASSED
=== 09-elab :: ./scripts/test_elab.sh
--- rc=0
  OCAML_FAIL: 0
  LEAN_FAIL:  0

SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
=== 10-uri :: ./scripts/test_libxml2_uri.sh
--- rc=0
[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)

==================================================
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
=== 11-cn :: ./scripts/test_cn_coverage.sh --check-baseline
--- rc=0
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0

Checking against baseline (exact match, fail-closed both directions): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/tests/cn_coverage/baseline.txt
BASELINE OK (213 entries, exact match)
=== TIER A DONE
```

Derived: 13 lane invocations (rows 1, 2, 3, 4, 4b, 4c, 5, 6, 7, 8, 9, 10, 11), every rc 0. Rows 5 and 11
(libc_exec, cn_coverage) and 10 (uri, 16/16 lean+libc == oracle) exercise the reversed
stitch on every program they run; row 5 is at the re-recorded baseline (`22dcb6284`). The
row-1 gate `check_theorem_axioms` FAILED on its first run in this worktree (§6.4) and
passed once the default Lake targets were built; the log above is the passing run.

### 5.2 Tier B (`.tmp/z3/tierB.sh`: serial after a clear `pgrep` box-rule check at 08:10 — `box clear (load average: 29.42, 32.73, 30.51)`, the load being other agents' work; log verbatim as in §5.1)

```
=== B1-libxml2 :: ./scripts/test_libxml2.sh
--- rc=0

==================================================
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
ALL PASSED
=== B2-parse-ci :: ./scripts/test_parse.sh tests/ci
--- rc=0
        1 REJECTED (exit 1): Undefined {ub: "UB060_block_scope_function_with_storage_class", stderr: "", loc: "<3:15--3:24>"}
        1 REJECTED (exit 1): Undefined {ub: "UB060_block_scope_function_with_storage_class", stderr: "", loc: "<2:15--2:24>"}

ALL PASSED
=== B3-core-ci :: ./scripts/test_core.sh tests/ci
--- rc=0
Lean parse:     128 ok, 0 failed
Success rate:   100% (of cerberus successes)

ALL PASSED
=== B4-verify :: ./scripts/test_verify.sh
--- rc=0
Build completed successfully (271 jobs).
check_driver_fresh: recorded lean stamp (bin 928c1995a956e8b80d44daa078f4a971a09ebd271af344821da4645c20dc287d, src b0ec32500df413772fe1e644c9c8f67a3a96b7cf14f248ee084d90dd626d77b5)

test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
=== B5-immaculate :: ./scripts/test_immaculate.sh
--- rc=0
  TRIPWIRE       g6-hash-collision   
  KILL           illtyped-store      

OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
=== B6a-speclab-selftest :: ./scripts/test_speclab.sh --selftest
--- rc=0
  oracle: exit=0 verdict=Specified(0)
  lean:   exit=0 verdict=Specified(0)
  expect: Specified(0)
test_speclab: PASS (both pipelines agree on Specified(0))
=== B6b-speclab-plant :: ./scripts/test_speclab.sh --plant
--- rc=0
  oracle: exit=0 verdict=Specified(2)
  lean:   exit=0 verdict=Specified(2)
  expect: Specified(2)
test_speclab: PASS (both pipelines agree on Specified(2))
=== B6c-divmod :: ./scripts/test_speclab_divmod.sh --gate
--- rc=0
  PASS  exec [c] (-128,-1): Specified(0)
  PASS  exec [plant]: Specified(1) — the wrong-operator plant is RED in-logic
CoreGateTest: ALL PASSED
test_speclab_divmod: PASS (--gate)
=== B6d-bytearr :: ./scripts/test_speclab_bytearr.sh --gate
--- rc=0
  PASS  exec [getarr B]: Specified(0)
  PASS  exec [getarr plant]: Specified(1) — the wrong-index plant is RED in-logic
ByteArrGateTest: ALL PASSED
test_speclab_bytearr: PASS (--gate)
=== B6e-list :: ./scripts/test_speclab_list.sh --gate
--- rc=0
  PASS  exec [build-only]: Specified(0) — builder-walker round trip through the heap
  PASS  leak [build-only]: final allocations = 1
ListGateTest: ALL PASSED
test_speclab_list: PASS (--gate)
=== B6f-tree :: ./scripts/test_speclab_tree.sh --gate
--- rc=0
  PASS  exec [build-only]: Specified(0) — builder-walker round trip through the heap
  PASS  leak [build-only]: final allocations = 1
TreeGateTest: ALL PASSED
test_speclab_tree: PASS (--gate)
=== B6g-seed :: ./scripts/test_speclab_seed.sh --gate
--- rc=0
  PASS  exec [swap c]: Specified(0)
  PASS  exec [swap plant]: Specified(9) — the lost-update plant is RED in-logic at post-state cell 1, byte 0
SeedGateTest: ALL PASSED
test_speclab_seed: PASS (--gate)
=== B7-gcc :: ./scripts/test_gcc_oracle.sh --check-baseline
--- rc=1
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/gcc_oracle_baseline.txt
REGRESSION: csmith/sa_csmith_231.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-

Baseline check: 1 regression(s), 0 improvement(s)
=== B8a-hang :: ./scripts/test_hang_plant.sh
--- rc=0
PLANT OK   [sweep/sleep → LEAN_HANG]: ci	tests/ci/0001-emptymain.c	LEAN_HANG	HANG(cpu 0.00s of 3.00s wall; timeout 3s)
PLANT OK   [sweep/busy → LEAN_TIMEOUT]: ci	tests/ci/0001-emptymain.c	LEAN_TIMEOUT	TIMEOUT(cpu 2.99s of 3.00s wall; timeout 3s)
PLANT OK   [classifier fail-closed]: HARNESS ERROR: time record /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/.tmp/scripts/hang-plant.EodeEOZJSJ/does-not-exist.time missing
test_hang_plant: all plants read as expected (sleep→HANG, busy→TIMEOUT, both lanes; missing record→harness error)
=== B8b-kill :: ./scripts/test_kill_plant.sh
--- rc=0
PLANT OK   [libxml2_uri -> killed label]: FAIL: LEAN_NOLIBC killed by SIGKILL (exit 137 — the per-test cgroup memory cap CERB_TEST_MEM_MAX=4G if the lane's stderr carries capped's OOM-KILLED witness banner, otherwise an external SIGKILL): c
PLANT OK   [libxml2 -> Lean OOM-KILLED]: [chvalid_battery_00] FAIL: Lean OOM-KILLED (exit 137; cgroup memory cap CERB_TEST_MEM_MAX=4G breached — memory.events oom_kill=1)
PLANT OK   [gcc_oracle exit(137) native -> compared (AGREE gcc=137 lean={137}), not SKIP_GCC_KILL]: [1/1] AGREE  .tmp/scripts/kill-plant.v75GuRgNzS/gcc137/exit137.c: gcc=137 lean={137}
test_kill_plant: all plants read as expected (cap breach -> OOM-KILLED witness; ci_sweep LEAN_KILL, libc_exec KILL, immaculate KILL, uri/libxml2 FAIL-killed; SIGKILL stub NOT the cap class; native exit(137) still compared; no MATCH anywhere)
=== B8c-fuel :: ./scripts/test_fuel_plant.sh
--- rc=0
PLANT OK   [--fuel before the mode flag refused (positional contract)]
PLANT OK   [--fuel without an argument refused]

test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
=== TIER B DONE
```

Derived: 16 lane invocations, 15 rc 0, 1 rc 1 — B7 (`test_gcc_oracle.sh
--check-baseline`). B7's own tail, verbatim:

```
    SKIP_LEAN_CRASH: 9
    SKIP_LEAN_FAIL: 9
    SKIP_LEAN_TIMEOUT: 12
    SKIP_UB: 47
    TRIAGED_ADDR: 11
    TRIAGED_UB: 1

SUMMARY: total=1963 compared=1884 agree=1872 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=12 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/gcc_oracle_baseline.txt
REGRESSION: csmith/sa_csmith_231.c baseline=AGREE/- current=SKIP_LEAN_TIMEOUT/-

Baseline check: 1 regression(s), 0 improvement(s)
```

`disagree=0`; the single REGRESSION is a movement INTO `SKIP_LEAN_TIMEOUT`
of a nolibc csmith-tier row (`sa_csmith_231.c`) whose semantics this slice
cannot touch (the nolibc path changed only in the VALUE of the program TU's
digest, which orders nothing across the program's own symbols; Tier A rows
2–4c are at their baselines). Cause: two FOREIGN gcc lanes overlapped B7 — the concurrency agent's
(`worktrees/cerberus-lean-feature/concurrency/.tmp/chain10.sh`, started
08:10:20, the same minute as my Tier B, its `test_gcc_oracle.sh` from
08:41:59, PID 1130593, still running at 09:00 with load 55) and the other
cerberus worker's (`worktrees/cerberus-lean-arc/zero-discrepancy`,
`test_gcc_oracle.sh` from 08:52:28, PID 1347218) — and the load sat at ~30 (measured `load average: 12.33, 31.73, 30.30` at 08:40, `29.42, …`
at 08:10) — the LADDER row-7 load caveat verbatim: "a REGRESSION whose only
movement is into SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is
read as red; no code change". The re-run (box rule: 5-minute `pgrep` polls
until no battery lane runs) is §5.2b.

### 5.2b B7 re-run on a quiet box
Superseded: the quiet-box poller for a pre-rebase re-run was waiting on the
concurrency agent's back-to-back gcc lanes (08:41, 09:10, 09:40 starts) when
the coordinator's rebase notice arrived; the re-run was therefore done ONCE,
on the REBASED head, as the last lane of §5.4 (box clear, load 1.22 at its
start).


### 5.4 The rebased-head battery (`eb27fa70f` + the three Z3 commits; binaries: oracle `bin 48312b2511e79beb3a943a96a059dcd3e7a0345bd14d057f38e62735163302c7, src 15a3689e…`, lean `bin 17a894c3f22e9340505b983ea02ccff6df6b42e54734b56e0df8076ec157429c, src 0611a6a6…`, after `make lean-prelude-src` + `build_cerberus` + `build_lean` + the default Lake targets, `check_driver_fresh --check` both OK)

Per the coordinator's rule (the mainline delta touched no Z3 product file and
the full pre-rebase battery is §5.1/§5.2): Tier A + verify + immaculate +
libc_exec, plus the pnvi spot sweep and the gcc lane (the one lane that had
not read green pre-rebase), serial, after a box-rule wait (`.tmp/z3/rebased.sh`;
the first launch of this runner self-matched its own launching shell's argv
and waited on a clear box from 10:01 to 10:08 — restarted with an anchored
`^/bin/bash .*scripts/test_…\.sh` check). Log verbatim (rows 1–11, B4, B5,
the sweep):

```
start 10:08:20 load=0.67
10:08:20 box clear load=0.67
=== 01-unit :: ./scripts/test_unit.sh
--- rc=0
  OK (admitted as declared): layout_rewrap [RENUMBER-ONLY ADMIT plant/layout_rewrap class=LAYOUT ids=2 moved=2 canon=9b2ed22f1988]
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
=== 02-exec-min :: ./scripts/test_exec.sh --check-baseline
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 03-exec-cov :: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_coverage_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04-exec-debug :: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_debug_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04b-exec-float :: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/exec_float_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== 04c-bytes :: ./scripts/test_bytes.sh
--- rc=0
[NEG_OK] only_unsigned_char.c: Lean-side desugar/typing rejection at the committed diagnostic line 1 (rc 1)

SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
=== 05-libc-exec :: ./scripts/test_libc_exec.sh
--- rc=0
  MATCH 012-global-alloc-order: Defined {value: "Specified(0)", stdout: "s1=281474976707472 c1=281474976707471 i

SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
=== 06-multi-tu :: ./scripts/test_multi_tu.sh
--- rc=0

==================================================
SUMMARY: total=2 match=2 fail=0
ALL PASSED
=== 07-parse :: ./scripts/test_parse.sh
--- rc=0
Lean front end: 0 rejected (exit 1 + a printed Error/Undefined verdict; not a parse failure), 0 internal-error-expected (failwithI panic on an *.error.c input, oracle-mirrored)
Success rate:   100% (of cerberus successes)

ALL PASSED
=== 08-core :: ./scripts/test_core.sh
--- rc=0
Lean parse:     106 ok, 0 failed
Success rate:   100% (of cerberus successes)

ALL PASSED
=== 09-elab :: ./scripts/test_elab.sh
--- rc=0
  OCAML_FAIL: 0
  LEAN_FAIL:  0

SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
=== 10-uri :: ./scripts/test_libxml2_uri.sh
--- rc=0
[lean+libc] EXACT MATCH with ORACLE_LIBC (16/16 URI corpus)

==================================================
GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
=== 11-cn :: ./scripts/test_cn_coverage.sh --check-baseline
--- rc=0
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0

Checking against baseline (exact match, fail-closed both directions): /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/tests/cn_coverage/baseline.txt
BASELINE OK (213 entries, exact match)
=== B4-verify :: ./scripts/test_verify.sh
--- rc=0
Build completed successfully (271 jobs).
check_driver_fresh: recorded lean stamp (bin 17a894c3f22e9340505b983ea02ccff6df6b42e54734b56e0df8076ec157429c, src 0611a6a63b48517c130eaf9914cb071acde493f616d9b45cb2fe50c2d788a8e3)

test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
=== B5-immaculate :: ./scripts/test_immaculate.sh
--- rc=0
  TRIPWIRE       g6-hash-collision   
  KILL           illtyped-store      

OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
=== S-pnvi-sweep :: ./scripts/test_ci_sweep.sh --suite pnvi --out .tmp/z3/sweep-rebased
--- rc=0
[43/44] UB_MATCH provenance_union_punning_2_global_yx.c: UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<16:5--16:7>"}
[44/44] MATCH provenance_union_punning_3_global.c: VAL:Specified(0)

SWEEP SUMMARY suite=pnvi mode=libc total=44 match=18 ub_match=26 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_kill=0 lean_error=0 lean_timeout=0 lean_hang=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_hang=0 cerb_crash=0 cerb_kill=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
10:16:05 box clear load=1.22
```

Derived: 16 lanes rc 0; `test_verify: 127 passed, 0 failed`; immaculate at
the committed baseline (the five `zd-z28-*` rows MATCH); the sweep `total=44
match=18 ub_match=26 … stdout_diff=0 … lean_timeout=0` — identical to the
pre-rebase AFTER sweep except `pointer_copy_user_ctrlflow_bytewise.c`, which
reads `UB_MATCH` inside the 15 s bound on the quiet box (the committed TSV's
class; §6.2 confirmed). B7 (gcc), the last lane of the runner:

```
=== B7-gcc :: ./scripts/test_gcc_oracle.sh --check-baseline
--- rc=0
Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/gcc_oracle_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
=== REBASED BATTERY DONE 10:36:46
```

B7's own tail, verbatim:

```
    SKIP_LEAN_CRASH: 9
    SKIP_LEAN_FAIL: 9
    SKIP_LEAN_TIMEOUT: 11
    SKIP_UB: 47
    TRIAGED_ADDR: 11
    TRIAGED_UB: 1

SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/z3-libc-order/scripts/gcc_oracle_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
gcc second-oracle lane OK
```

Derived: on the quiet box (`box clear load=1.22` before the lane; no other
battery process for its whole run, 10:16:05 → 10:36:46) the gcc lane is at
its baseline — `0 regression(s), 0 improvement(s)`; the pre-rebase
`sa_csmith_231.c` movement into `SKIP_LEAN_TIMEOUT` (§5.2) was the load, as
the LADDER row-7 caveat says. Final state: 17/17 lanes rc 0 on the rebased
head; with §5.1/§5.2 (13 + 16 lanes pre-rebase, the single non-zero being
the B7 load read) the slice's claims stand on the full Tier A + Tier B.

### 5.3 The pnvi spot sweep, before / after (`test_ci_sweep.sh --suite pnvi --out <scratch>`, `SKIP_BUILD=1` on the stamped binaries; the committed `tests/ci_sweep/results/pnvi.tsv` is Z4's re-record and is NOT touched)

BEFORE (binaries of §0 "start of slice"), summary line verbatim:

```
SWEEP SUMMARY suite=pnvi mode=libc total=44 match=9 ub_match=25 ub_diff=0 stdout_diff=9 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_kill=0 lean_error=0 lean_timeout=1 lean_hang=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_hang=0 cerb_crash=0 cerb_kill=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

The nine STDOUT_DIFF rows before (detail column truncated at 600 chars):

```
pnvi	tests/pnvi_testsuite/pointer_from_integer_1ig.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "j=5 &j=(@72, 0xffffffffedbc)\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "j=5 &j=(@72, 0xffffffffeddc)\n", stderr: "", blocked: "false"}
pnvi	tests/pnvi_testsuite/pointer_from_integer_1pg.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "j=5 &j=(@73, 0xffffffffedb4)\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "j=5 &j=(@73, 0xffffffffedd4)\n", stderr: "", blocked: "false"}
pnvi	tests/pnvi_testsuite/pointer_from_integer_2g.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffedd0)\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "j=5 &j=(@70, 0xffffffffede8)\n", stderr: "", blocked: "false"}
pnvi	tests/pnvi_testsuite/provenance_equality_auto_yx.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedb0) q=(@73, 0xffffffffedb0)\n(p==q) = true\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=(@74, 0xffffffffedc8) q=(@73, 0xffffffffedc8)\n(p==q) = true\n", stde
pnvi	tests/pnvi_testsuite/provenance_equality_global_fn_yx.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = true\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=(@1, 0xfffffffffff8) q=(@0, 0xfffffffffff8)\n(p==q) = true\n", stderr
pnvi	tests/pnvi_testsuite/provenance_equality_global_yx.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffede0) q=(@68, 0xffffffffede0)\n(p==q) = true\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=(@69, 0xffffffffedfc) q=(@68, 0xffffffffedfc)\n(p==q) = true\n", stde
pnvi	tests/pnvi_testsuite/provenance_equality_uintptr_t_auto_yx.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=ffffffffedac q=ffffffffedac\n(p==q) = true\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=ffffffffedc8 q=ffffffffedc8\n(p==q) = true\n", stderr: "", blocked: "false"}
pnvi	tests/pnvi_testsuite/provenance_equality_uintptr_t_global_yx.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=ffffffffede0 q=ffffffffede0\n(p==q) = true\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=fffffffff3a0 q=fffffffff3a0\n(p==q) = true\n", stderr: "", blocked: "false"}
pnvi	tests/pnvi_testsuite/provenance_lost_escape_1.c	STDOUT_DIFF	values equal; Lean=Defined {value: "Specified(0)", stdout: "Addresses: p=(@68, 0xffffffffede0)\n", stderr: "", blocked: "false"} Cerberus=Defined {value: "Specified(0)", stdout: "Addresses: p=(@17, 0xfffffffff4cc)\n", stderr: "", blocked: "false"}
```

AFTER (binaries of §0 "after the fix"), summary line verbatim:

```
SWEEP SUMMARY suite=pnvi mode=libc total=44 match=18 ub_match=25 ub_diff=0 stdout_diff=0 diff=0 mismatch=0 lean_fail=0 lean_crash=0 lean_kill=0 lean_error=0 lean_timeout=1 lean_hang=0 cerb_reject=0 cerb_error=0 cerb_timeout=0 cerb_hang=0 cerb_crash=0 cerb_kill=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

The same nine rows after:

```
pnvi	tests/pnvi_testsuite/pointer_from_integer_1ig.c	MATCH	VAL:Specified(0)|VAL:Specified(0)
pnvi	tests/pnvi_testsuite/pointer_from_integer_1pg.c	MATCH	VAL:Specified(0)|VAL:Specified(0)
pnvi	tests/pnvi_testsuite/pointer_from_integer_2g.c	MATCH	VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_equality_auto_yx.c	MATCH	VAL:Specified(0)|VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_equality_global_fn_yx.c	MATCH	VAL:Specified(0)|VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_equality_global_yx.c	MATCH	VAL:Specified(0)|VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_equality_uintptr_t_auto_yx.c	MATCH	VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_equality_uintptr_t_global_yx.c	MATCH	VAL:Specified(0)
pnvi	tests/pnvi_testsuite/provenance_lost_escape_1.c	MATCH	VAL:Specified(0)
```

`diff` of the (file, class) columns, before → after — the ONLY movements are
the nine STDOUT_DIFF → MATCH flips:

```
13c13
< tests/pnvi_testsuite/pointer_from_integer_1ig.c	STDOUT_DIFF
---
> tests/pnvi_testsuite/pointer_from_integer_1ig.c	MATCH
15c15
< tests/pnvi_testsuite/pointer_from_integer_1pg.c	STDOUT_DIFF
---
> tests/pnvi_testsuite/pointer_from_integer_1pg.c	MATCH
17c17
< tests/pnvi_testsuite/pointer_from_integer_2g.c	STDOUT_DIFF
---
> tests/pnvi_testsuite/pointer_from_integer_2g.c	MATCH
32,37c32,37
< tests/pnvi_testsuite/provenance_equality_auto_yx.c	STDOUT_DIFF
< tests/pnvi_testsuite/provenance_equality_global_fn_yx.c	STDOUT_DIFF
< tests/pnvi_testsuite/provenance_equality_global_yx.c	STDOUT_DIFF
< tests/pnvi_testsuite/provenance_equality_uintptr_t_auto_yx.c	STDOUT_DIFF
< tests/pnvi_testsuite/provenance_equality_uintptr_t_global_yx.c	STDOUT_DIFF
< tests/pnvi_testsuite/provenance_lost_escape_1.c	STDOUT_DIFF
---
> tests/pnvi_testsuite/provenance_equality_auto_yx.c	MATCH
> tests/pnvi_testsuite/provenance_equality_global_fn_yx.c	MATCH
> tests/pnvi_testsuite/provenance_equality_global_yx.c	MATCH
> tests/pnvi_testsuite/provenance_equality_uintptr_t_auto_yx.c	MATCH
> tests/pnvi_testsuite/provenance_equality_uintptr_t_global_yx.c	MATCH
> tests/pnvi_testsuite/provenance_lost_escape_1.c	MATCH
```

Against the committed 2026-08-22 TSV (derived): that snapshot had 6 STDOUT_DIFF
+ 12 MATCH + 26 UB_MATCH; this tree BEFORE the fix had 9 + 9 + 25 + 1
LEAN_TIMEOUT — `pointer_from_integer_1ig.c`, `pointer_from_integer_1pg.c`,
`provenance_equality_uintptr_t_auto_yx.c` had joined the address class
(their Lean padding moved with Z1's Z-76 alignment mirror; same root cause,
fixed by the same commit), and `pointer_copy_user_ctrlflow_bytewise.c`
(UB_MATCH in the snapshot) reads LEAN_TIMEOUT at the lane's 15 s bound on this
loaded box — §6.2. AFTER: 0 STDOUT_DIFF, 18 MATCH, 25 UB_MATCH, 1 LEAN_TIMEOUT.

## 6. Findings, errata candidates, what is left out

### 6.1 Three more rows in the address class (not a finding against the fix)
`pointer_from_integer_1ig.c`, `pointer_from_integer_1pg.c`,
`provenance_equality_uintptr_t_auto_yx.c` were MATCH in the committed
2026-08-22 TSV and STDOUT_DIFF on this tree BEFORE the fix (locals-only
programs printing `&j`; their padding moved when Z1's Z-76 `IvMaxAlignment`
mirror changed the Lean layout, because the libc globals were still in hash
order). Same root cause; all three MATCH after (§5.3). Errata candidate for
the charter's Z-28 row wording ("6 rows"): the class is "every libc-mode
program that prints or compares an address", not a fixed row set — the row
text now says so.

### 6.2 `pointer_copy_user_ctrlflow_bytewise.c` — LEAN_TIMEOUT at the 15 s lane bound (Z-31 class, measured completion)
Before AND after the fix the sweep classifies it `TIMEOUT(cpu 14.98s of
15.00s wall; timeout 15s)` (CPU-bound, not a hang). Standalone on this box
(load average 16–32, other agents) at a 300 s bound:
```
AGREE UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"}|UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"}|UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"}|UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"}|UB:{ub: "UB043_indirection_invalid_value", stderr: "", loc: "<282:3--282:5>"}|UB:{… (6561 executions per side, 13122 verdict lines in total; every one `UB043_indirection_invalid_value` at `<282:3--282:5>`)
real	0m22.115s   (oracle + Lean together, `time` over run_probe.sh)
```
Both engines complete and agree on the whole exhaustive set; the Lean side
alone is ~15–20 s here. On the QUIET box (load 0.7–1.2, §5.4) the sweep
itself reads the row `UB_MATCH` inside the 15 s bound — the committed TSV's
class — so the LEAN_TIMEOUT was the load, as classified. This is the charter's Z-31 shape — "tolerated ONLY
PER ROW with measured completion at a larger bound" — and this is that
measurement; it is for Z4's re-record (the committed TSV has the row
UB_MATCH from a faster binary/box). No code change.

### 6.3 The oracle's default single-trace mode is randomised
`--exec --batch` without `--mode` is `Random` (backend/driver/main.ml:438-441)
with `Random.self_init ()` (backend/common/driver_ocaml.ml:153, :194): a
program with an ND choice (the `_yx` pointer comparisons: `(p==q)` on a
one-past pointer) prints a DIFFERENT single line run to run (measured,
§1.1). Consequence for pinning: the immaculate lane (single trace both
sides) cannot pin such programs — three of the six charter rows were pinned
there RED at `f38adabf4`, found non-deterministic, and REMOVED from the
corpus in that same commit (amended before the fix); the exhaustive spot
sweep is their evidence. Errata candidate for VALIDATION.md's description
of the immaculate lane (a one-line caveat: only ND-free programs are
pinnable there) — left for Z4's VALIDATION rewrite.

### 6.4 Worktree build-state gap in the axiom gate (not a code finding)
`test_unit.sh`'s `check_theorem_axioms` FUEL leg failed on its first run in
this worktree (`Unknown constant Ctype_lemMeasureProofs.ctypeEqual_measure_sufficient`
…, 6 constants): the primed `.lake` held 198 oleans; the `*_lemMeasureProofs`
modules are Lake roots of the `CerberusLean` lib outside the exe's import
closure, and `build_lean` builds only the `cerberus-lean` exe target, so the
gate's `lake env lean` probe could not import them. `scripts/capped lake
build` (default targets; 374 jobs, 210 oleans) closed it; the passing run is
§5.1. Operational note for `scripts/new-worktree.sh`/LADDER: a primed
worktree must have the DEFAULT targets built before Tier A row 1 is trusted.

### 6.5 The two stitch refusals seen while developing (evidence the checks are load-bearing)
1. `libc stitch: the dump has 68 globals but the linked metadata has 91 —
   the two link orders cannot be joined` — the dump prints only definitions
   (pp_core.ml:840-841); libc.co and the metadata carry 23 declaration-only
   entries too. Resolved by joining over the GlobalDef subsequence and
   keeping the declarations in the libc file, as libc.co does.
2. `libc stitch: global name '__stdout' occurs twice` — `extern FILE *const
   __stdout;` in stdio.h yields one GlobalDecl per including TU beside the
   one definition. Resolved: a definition wins over its declarations; two
   DEFINITIONS of one name still refuse.
3. With per-TU tag symbols left in the metadata's funinfo, `002-puts` and
   `zd-z2cp01-strtod-inf` reported `UB041_function_not_compatible` (libc-
   internal calls passing a `FILE*`): the run-time compatibility check
   requires tag-symbol equality (§3). Resolved by the one-tag-per-name frame
   on both halves; both rows MATCH again (Tier A row 5, Tier B row 5).

### 6.6 Left out / not done here
* The committed `tests/ci_sweep/results/*.tsv` are not re-recorded (Z4).
* Z-31 evidence for the other undemonstrated timeout rows (csmith/gcc): not
  this slice.
* A `tests/libc_exec` or immaculate pin that exercises a libc-INTERNAL
  cross-TU struct-typed call (the one place the one-tag frame could in
  principle differ from the oracle's per-TU tags: the oracle would compare
  the caller TU's declaration entry — same-TU tags — so no divergence is
  expected; the uri gate's 16/16 and the libc-mode Tier B rows are the
  empirical coverage). Left as a Z4 probe suggestion.
* `test_golden.sh` (not in the ladder) was not run; its goldens were
  regenerated because they must carry the digest field.

## 7. Commits (branch `arc/z3-libc-order`, rebased above `eb27fa70f`; the pre-rebase hashes `aa5f87f35`/`3d47dd418`/`94aa712d2` are the ones the §5.1–5.3 logs were produced on)

1. `f38adabf4` — Z3 (1/n): Z-28 pins RED — `tests/libc_exec/012-global-alloc-order.c`
   (DIFF), five `tests/immaculate/libc/zd-z28-*.c` (DIFF; the three ND `_yx`
   rows were pinned, found `Random.self_init`-flaky on the oracle side, and
   removed before this commit was finalised — §6.3), the two local headers,
   both baselines re-recorded, the immaculate header paragraph.
2. `2ddc1300c` — Z3 (2/n): the mirror — `backend/driver/main.ml` (the JSON
   `digest`), `lean_frontend/CabsImport.lean` (`parseJson` returns the digest,
   fail-closed), `lean_frontend/CerberusFresh.lean` (header),
   `lean_frontend/CoreParser.lean` (`RenameCtx`/`renameFile`/`renameCtype`/
   `renameTagDef`), `lean_frontend/Main.lean` (per-TU digest; `loadLibc`
   stitch reversed; module note rewritten), the ten `tests/fixtures/*/cabs.json`
   goldens regenerated. Tier A 13/13 rc 0 on it (§5.1).
3. `22dcb6284` — Z3 (3/n): pins re-recorded MATCH (012; five zd-z28-*).
4. this commit — Z3 (4/n): this record; charter rows Z-28 (BUG-FIX → FIXED
   `2ddc1300c`), Z-69, §6 Z3 (DONE).

No push; no merge; the mainline is untouched; lem pins unmoved (`d4ba548`).
