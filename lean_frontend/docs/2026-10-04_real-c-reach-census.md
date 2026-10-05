# Real-C reach census (next-phase plan P1f-2): record

Branch `census/real-c-20261004`, written over mainline `ae48126e5` and rebased onto `7fc9b7bec` on 2026-10-05
(the only mainline change in between is to the failure-reach checker). Worker [AGENT]. Decisions are [AGENT]
unless marked [USER]. The pre-merge audit of 2026-10-05 and its dispositions are in §9; the passages it corrected
say so where they stand.

- Authorization: [USER 2026-10-04] "Approved (this box runs unnetworked, do you need me to download things?)", on the
  P1f-2 scope relayed by the orchestrator. The census is **report-only**: nothing in the semantics, the model, the
  harnesses or the gated lanes was changed, and no finding was fixed or pinned. Standing rule [USER 2026-10-03]: "we
  don't innovate wrt Cerberus-upstream ... fall back to loudly rejecting".
- Plan entry: `docs/2026-09-25_next-phase-plan.md` (branch `docs/next-phase-plan-20260925`) §11 table, row "1f
  direction", P1f-2. Phase 4's P4-5 coverage work is to be ordered by this record.

## 0. Summary

70 programs: the pKVM buddy allocator with four driver mains (plus one libc-mode variant), ten Linux `lib/` files
each with a driver main, and all 55 libxml2 top-level TUs (as far as elaboration). Counts below are derived from
`results.tsv` of the recorded run (§2).

- **No disagreements and no Lean-only gap.** Where the Lean pipeline received input (pKVM, libxml2), every stage
  agreed with the oracle, either both answering alike or both failing alike. No refusal was triggered in a census
  row. Every stop is on the oracle side or in the program.
- **Linux: 0/10 files get past the oracle's C parser.** The first blocker is GNU C syntax every time: `__attribute__`
  (7 files), `__signed__` (2) and `__builtin_va_list` (1). A diagnostic peel (§4.2) found more unsupported syntax
  behind it: `__extension__`, the `__typeof__` and `__alignof__` spellings, file-scope `asm`, one inline-asm site the
  parser rejects, `u128` and a file-scope empty declaration. So fixing the first blocker does not reach Lean.
  (Corrected by the pre-merge audit, M1: this bullet used to list inline asm, `typeof` and statement expressions as
  blockers. `typeof` and statement expressions are supported, and inline asm does not stop the front end; see the
  next bullet.)
- **Inline asm is a silent no-op on both engines** (pre-merge audit M1; §4.5). The C parser accepts `asm(...)`
  statements, including the extended form, and the desugarer erases them to a skip (`cabs_to_ail.lem:4112-4114`). Lean
  is generated from the same `.lem`, so the two engines agree, and both drop the asm silently. CONTRACT, SUPPORTED and
  VALIDATION do not register it. Operator ruling, [USER 2026-10-05]: "Re inline asm, this should be a loud refusal".
  The refusal is a separate queued slice and is not done here.
- **pKVM: the allocator reaches a run on both engines, which agree. In the declared configuration that run is UB.**
  The default (PVI) concrete model's `copy_alloc_id` does not copy the allocation ID. Every store through a computed
  page pointer is therefore `UB_CERB002b_out_of_bound_store`. Under `--switches=PNVI_ae_udi` the oracle runs all
  three drivers to the values native gcc gives. Lean refuses `--switches` by contract.
- **libxml2: 52/55 TUs pass the front end, the bridge and Lean elaboration on both engines. The other 3 fail alike on
  both** (an upstream front-end crash and two gaps in the oracle's libc headers). 20 of the 52 contain no main-file
  declaration under the pinned all-modules-off configuration, so their agreement is close to vacuous.
- **Instrument by-products (upstream, report-only):** the oracle's `-E` mode is broken at the pin and upstream.
  Two upstream front-end crashes were reduced to 4-line reproducers (§5).

## 1. Method

### 1.1 Engines and pins

Fresh worktree (`scripts/new-worktree.sh cerberus-lean census/real-c-20261004 mdd/cerberus-lean`). Both engines
were built there by the documented recipe (`lean_frontend/CLAUDE.md` Build):

- the OCaml side: `make prelude-src lean-prelude-src`, then `dune build backend/driver/main.exe cerberus-lib.install`,
  then `dune install --prefix _build/local-install cerberus-lib`, then `dune build cerberus.install`;
- the Lean side: `CERB_MEM_MAX=32G scripts/capped make lean-native-obj`, then `lake build CerberusLean cerberus-lean`
  under `capped` (`Build completed successfully (395 jobs).`).

Freshness stamps were recorded with `tools/check_driver_fresh.sh`, and every census run re-verified them (oracle bin
`f0cc245a…`, lean bin `11f91d7d…`). After the 2026-10-05 rebase the same builds still verify (oracle src `79f523b1…`,
lean src `378c786d…`), because the rebase changed no engine source; the post-audit run (§2) used them. Other pins:

- Lem: `Lem lean-backend-v0.1.0-alpha.1-63-g4e70bb5`, the switch's own; untouched.
- Lean: `v4.32.2`.
- cpp: `cc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`.
- `deps/linux`: `bd5f485f3f02` (7.2.0).
- `deps/libxml2`: `c63248941` (`scripts/libxml2_prep.sh --check`: OK).
- pKVM case study: `460fb6b6e`.
- Pristine upstream (§5): the worktree's independent oracle, cerberus `b9aeedcb4`.

### 1.2 The instrument: `tests/census/run_census.sh`

A *unit* is one program: an ordered TU list (the link order on both engines), a flag set, a libc mode and a stage
range (`tests/census/units.txt`). Each unit goes through the stages in order. Each stage runs on both engines where
both have one:

| # | Stage | Oracle | Lean |
|---|---|---|---|
| 1 | front end | per TU: the oracle's own cpp command, then the bare front end `cerberus --nolibc --pp core FLAGS tu.c` (parse, desugar, Ail typing, elaboration; `main.ml` "Link and execute" arm with exec=false) | — |
| 2 | bridge | per TU `cerberus --cabs-json FLAGS tu.c` (no `--nolibc`, as every lane) | — |
| 3 | elaboration | (stage 1) | per TU `cerberus-lean --pp-core tu.json` |
| 4 | link | bare front end over all TUs (+ libc unless `--nolibc`) | `cerberus-lean --pp-core [--libc …] *.json` (`Core_linking.link`; stops before execution) |
| 5 | run | `--exec --batch` (default `--mode=random`: one trace), then `--mode=exhaustive` | `--batch --first`, then `--batch` (exhaustive) |

Each stage's outcome is decided as follows:

- **Comparison.** Runs are compared with the lanes' codec (`scripts/observations.py compare`, `full` projection).
  Stages 1–4 compare success against failure. The failure text is recorded verbatim but not required to match, since
  a text difference is class (a) in the contract.
- **Signature sub-signal.** Stage 3 also carries `scripts/test_elab.sh`'s signature-level instrument
  (`extract_core_sig.py` and `canonicalize_ids.py`), made asymmetric because the OCaml pretty-printer drops
  header-declared items. The sub-signal is "every oracle signature line is present on the Lean side". It is
  reporting-only, and bodies are not compared.
- **Stages after a front-end failure.** Stages 1–3 still run after an oracle front-end failure. That separates "both
  fail alike" from "Lean accepts what the oracle rejects".
- **Resource limits.** Every invocation runs under the per-test cap (`CAPPED_TEST`, 4G), `timeout 300` (the libxml2
  lane's value) and a GNU `time` record. TIMEOUT, HANG and KILL use `common.sh`'s classifiers. Lean runs with
  `LEAN_ABORT_ON_PANIC=1`. `SKIP_BUILD=1` is forced, so `common.sh` checks the freshness stamps instead of
  rebuilding.
- **stdin.** Every engine invocation gets `</dev/null`, and `units.txt` is read on fd 3, so no engine can consume the
  unit list (audit L5).
- **The cpp mirror matches stage 1.** Stage 1 always runs `--nolibc`, and `create_cpp_cmd` adds `-DCERB_WITH_LIB`
  only without `--nolibc` (`main.ml:41`). So the mirror never adds it, whatever the unit's libc mode (audit L5; it
  used to add it in libc mode).
- **Instrument errors.** `observation_capture` returns 125 when the capture itself fails, and the oracle's internal
  error is also 125 (e.g. libxml2 `encoding.c`). The instrument therefore checks for the capture's `.capture-error`
  marker. A unit with such a capture gets an `INSTRUMENT-ERROR` row, and the run exits 1 (audit L2). Plant
  [AGENT]: a copy of the script that pre-created one capture's `.stdout` (a reused prefix) gave, verbatim,
  `[pkvm-alloc] link | INSTRUMENT-ERROR(capture failed: link.lean) | oracle [OK]  | lean [INSTRUMENT-ERROR]  (0s)`
  and `census: ERROR: 1 row(s) are INSTRUMENT-ERROR — the run is NOT a census result`, rc 1.
- **Refusals.** A row is a refusal only if the Lean capture has one of the engine's attributed refusal forms (audit
  L3; it used to be a bare `grep refused` over all captures). Either it exits 2 with a stderr line starting
  `cerberus-lean: refused — ` (`Main.lean` `refuseFlag`, `refuseRuntime`; the form `scripts/check_cli_refusals.sh`
  pins), or it exits 134 with a `PANIC at ` line that carries `: refused — ` or `CerbFS refusal (fail-closed
  fs-model boundary): ` (an in-model refusal through `failwithI`). Plant [AGENT]: the real `--switches=PNVI_ae_udi`
  capture and a synthetic CerbFS panic matched; exit 1 with the word "refused", exit 2 with an unattributed line,
  and a non-refusal panic did not.
- **Front end fails on one TU, Lean on another.** One engine then accepted a TU the other rejected, whichever TU comes
  first, so the row is a `DISAGREEMENT` (audit L1; it used to be filed as an oracle front-end failure).
- **Tally.** The script ends with a `census: tally:` line, by outcome class, derived from `results.tsv`.

**Why not `cerberus -E`.** The oracle's `-E` is broken at the pin, and identically upstream. `main.ml:248-253` hands
the preprocessed TEXT to `print_file`, and `print_file` (`main.ml:79-84`) `open_in`s it as a file name:

```
cerberus: internal error, uncaught exception:
          Sys_error("# 0 \"/home/dev/…/tests/census/pkvm/pkvm_init.c\"\n# 0 \"<built-in>\"…: File name too long")
```

(`deps/cerberus-upstream/backend/driver/main.ml:79/238` is the same code; the message is abridged by `…`.) The
instrument therefore runs the cpp command that `create_cpp_cmd` (`main.ml:38-52`) builds, rebuilt from the same flags.
It is used only to say whether a front-end stop happened in cpp.

### 1.3 Configurations and drivers (all committed under `tests/census/`)

**pKVM** (`units.txt` `pkvm-*`). Flags `--nostdinc -I <case study> -I tests/census/pkvm`, mode `--nolibc`.

- **Why `--nostdinc`** [AGENT]: the case study is freestanding and ships its own `stddef.h` and `limits.h`. With the
  oracle's libc include dirs first, a driver TU picked up libc `<limits.h>`, and `memory.h`'s `USHRT_MAX`
  redefinition failed cpp `-Werror`. That was the first shakedown failure.
- **`pkvm_driver.h`.** It supplies only what `page_alloc.c` leaves to its environment:
  - the header chain in `page_alloc.c`'s order;
  - a definition of `hyp_physvirt_offset`, which `memory.h` declares `extern` and nothing defines;
  - four pages of "physical memory" with `phys(census_mem) = 0`, and a vmemmap indexed by pfn.
- **`census_pool_init`, derived at run time.** The case study gives `get_order` an empty body (a CN-frontend
  workaround, `page_alloc.c:677-683`), and `hyp_pool_init` uses its value. So `pkvm_init.c` calls `hyp_pool_init`
  itself to record that. The other drivers call `census_pool_init` [AGENT]. Since the pre-merge audit (M2) this
  repository carries no text of it, because `page_alloc.c` is `SPDX-License-Identifier: GPL-2.0-only`.
  `tests/census/pkvm/derive_pool_init.py` derives it from the case study's own file on every run:
  - it extracts `hyp_pool_init` (`page_alloc.c:685-791`), from its two signature lines to the first line that is
    exactly `}`;
  - it fails loudly unless the signature occurs exactly once, the extracted text has the pinned sha256 (`98665f6a…`,
    case study `460fb6b6e`), and `get_order((nr_pages + 1) << PAGE_SHIFT)` occurs exactly once in it;
  - it makes the one documented substitution, that call → a new last parameter `max_order`, and renames the
    function `census_pool_init`;
  - it writes `<out>/.pkvm-derived/page_alloc_census.c`: `#include` of the case study's `page_alloc.c`, then the
    derived function. It has to share `page_alloc.c`'s TU because it calls the static `__hyp_put_page`. The file
    carries GPL text, lives only under the census output directory and is never committed (`units.txt` token
    `@G@`). The drivers call `census_pool_init(&pool, 0, CENSUS_NPAGES, 0, 3)`.

  Before the audit, `pkvm_driver.h` held a hand copy of the body. It freed pages through `hyp_put_page` on virtual
  addresses, where the derived function calls `__hyp_put_page` on `&p[i]` as the original does. Every pKVM row's
  outcome, and the PNVI and native values below, are unchanged.
- **The case study's `memset` is an empty-bodied stub** (`page_alloc.c:30-40`, `/*@ trusted @*/`, a CN-frontend
  workaround like `get_order`). `__hyp_attach_page` relies on it to zero a freed page (`page_alloc.c:398`). On every
  engine and in the native check, freed pages are therefore not zeroed. No driver observes page contents, so no
  census value depends on it.
- **Drivers:**
  - `pkvm_init.c`: init as shipped.
  - `pkvm_alloc.c`: allocate to exhaustion.
  - `pkvm_free.c`: allocate all pages, free all, and expect one order-2 block back.
  - `pkvm_split_merge.c`: free-list states across a split, `hyp_get_page`/`hyp_put_page` refcounts, and a merge.
  - `pkvm-alloc-libc`: `pkvm_alloc.c` in libc mode, recording how the freestanding `memset` meets the loaded libc.
- **Sanity check.** Native gcc (`-include assert.h`, `__cerbvar_copy_alloc_id` stubbed to a cast) built and ran all
  three non-init drivers: exit bytes `0x20`, `0x00`, `0x9c`. Re-run on 2026-10-05 against the derived TU: the same
  bytes.
- **Licence check of the committed census files** [AGENT] (audit M2). Nothing committed under `tests/census/` now
  carries case-study or kernel code:
  - `pkvm_driver.h` holds `#include` lines in the case study's order, three one-token `#define`s, and code written
    for the census;
  - the Linux drivers restate only interface facts: function prototypes (`drv_string.c` and others), the two-pointer
    `struct list_head` (`drv_list_sort.c`) and the ctype bit values `_U`…`_SP` (`drv_ctype.c`);
  - `linux/config-src/autoconf.h` holds nine `CONFIG_` settings, each with its reason, and the other config stubs
    are empty;
  - `prep.sh` runs the kernel's own recipes at run time into the output directory.

  Judgement [AGENT]: prototypes, a struct layout and flag constants are the interface a caller must restate to link
  against the code, not copied implementation, so they are fine in a BSD repository. This is an engineering
  judgement, not legal advice; the operator may rule otherwise.

**Linux** (`units.txt` `linux-*`). x86_64 (LP64, the contract's one ABI). Flags `--nostdinc` plus
`tests/census/linux/flags.txt` (kernel `-I` order, `--include` of `kconfig.h` and `compiler_types.h`, `-D__KERNEL__`).
The Kbuild-generated headers are derived by `tests/census/linux/prep.sh` from the tree; no kernel build:

- `autoconf.h`: hand-written, 9 options, each with its reason.
- `asm-generic` wrappers: from the arch and generic Kbuild `generic-y`/`mandatory-y` lists.
- `timeconst.h`: the Kbuild `bc` recipe with `CONFIG_HZ=250`.
- `cpufeaturemasks.h`: the `arch/x86/Makefile:265` awk recipe.
- `asm-offsets.h`, `rq-offsets.h`, `bounds.h`: empty stubs, since Kbuild makes them by compiling C.

The `-D` list in `flags.txt` restores macros gcc 13 predefines for x86_64 that the oracle's cpp drops with `-undef`
(`__GNUC__` and friends; `compiler_types.h` `#error`s "Unknown compiler" without it). The config grew one cpp error
at a time [AGENT]:

1. `__GNUC__` (Unknown compiler);
2. `asm/rwonce.h` (generic wrappers);
3. `generated/asm-offsets.h` (stub);
4. `P4D_SHIFT` redefined (`CONFIG_PGTABLE_LEVELS 5`);
5. `cache_line_size` redefined (`CONFIG_ARCH_HAS_CACHE_LINE_SIZE`);
6. `asm/cpufeaturemasks.h` (awk recipe);
7. `generated/rq-offsets.h` (stub);
8. "Unknown RCU implementation" (`CONFIG_TINY_RCU`);
9. `generated/timeconst.h` (bc recipe);
10. "Unknown SRCU implementation" (`CONFIG_TINY_SRCU`);
11. `generated/bounds.h` (stub).

**All ten requested files then preprocess with the oracle's cpp**, so no substitution was needed. `gcd`, `lcm` and
`int_sqrt` live in `lib/math/`. `lcm` links with `gcd.c` (3 TUs). The drivers (`tests/census/linux/drivers/`) restate
prototypes in plain C, return 0 or the number of the first failed check, and avoid null-pointer `container_of`. They
`#include` no kernel header themselves. Like every TU of a Linux unit, though, they are preprocessed with
`flags.txt`, so `kconfig.h` and `compiler_types.h` come in through its `--include`s (audit L5 wording fix). They are
syntax-checked by gcc, but no engine ever executed one (§7).

**libxml2** (`units.txt` `libxml2-*`, stages 1–3). Flags are `scripts/libxml2_prep.sh`'s per-TU arguments (pinned
`tests/libxml2/config`, `-D__inline=inline`), mode `--nolibc`, as the chvalid lane uses.

## 2. Per-file results

Recorded run: the post-audit re-run of 2026-10-05, `tests/census/run_census.sh .tmp/census/final` (exit 0, 70 rows),
on the rebased branch with every audit fix in place. Its last line, verbatim:

```
census: tally: 70 programs; agreement 56; both-fail-alike 14; DISAGREEMENT 0; refusal 0; resource-limit 0; INSTRUMENT-ERROR 0; other 0
```

That is the same tally as the original run of 2026-10-04 (56 agreement, 14 both-fail-alike, nothing else). Every
row's outcome class and cause is the same too, except where §2 notes otherwise. Raw captures were kept under the
ephemeral `.tmp/` for the slice and deleted at its end. Columns:

- **Cause** is the instrument's key line, verbatim, with absolute paths shortened to `linux/`, `pkvm/` and `libxml2/`.
- For libxml2 agreement rows, Cause is the signature sub-signal instead:
  - "sig OK": every oracle line is present on the Lean side;
  - "only ordinal artifacts": see §4.4;
  - "no main-file decls": the oracle signature is empty.
- **Time** is the sum of the recorded stage walls in seconds (cpp stage excluded), derived.

| File / unit | First stopping stage | Outcome class | Cause (verbatim key message) | Time (s) |
|---|---|---|---|---|
| pkvm-init | none (completed run) | agreement (`--first` and exhaustive; `--first` is time-seeded, see below) | Undefined {ub: "UB088_reached_end_of_function", stderr: "", loc: "<715:2--715:6>"} | 1.39 |
| pkvm-alloc | none (completed run) | agreement (`--first` and exhaustive) | Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | 0.85 |
| pkvm-free | none (completed run) | agreement (`--first` and exhaustive) | Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | 0.86 |
| pkvm-split-merge | none (completed run) | agreement (`--first` and exhaustive) | Undefined {ub: "UB_CERB002b_out_of_bound_store", stderr: "", loc: "<27:2--27:21>"} | 0.88 |
| pkvm-alloc-libc | link | both fail alike | oracle: pkvm/page_alloc.c:35:6: error: duplicate external symbol: memset · lean: Error {msg: "linking failed: duplicate external name: memset at pkvm/page_alloc.c:35:6-12"} | 1.65 |
| linux lib/math/gcd.c | oracle front end (parse) | both fail alike (shared parser; Lean not reached) | linux/include/linux/stdarg.h:5:9: error: unexpected token after '__builtin_va_list' and before '__builtin_va_list' | 0.14 |
| linux lib/math/lcm.c (+gcd.c) | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.14 |
| linux lib/math/int_sqrt.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.14 |
| linux lib/bsearch.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.42 |
| linux lib/ctype.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.12 |
| linux lib/sort.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/uapi/asm-generic/int-ll64.h:20:9: error: unexpected token after '__signed__' and before '__signed__' | 0.17 |
| linux lib/list_sort.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.15 |
| linux lib/kstrtox.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.34 |
| linux lib/hexdump.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/uapi/asm-generic/int-ll64.h:20:9: error: unexpected token after '__signed__' and before '__signed__' | 0.14 |
| linux lib/string.c | oracle front end (parse) | both fail alike (shared parser) | linux/include/linux/compiler.h:258:15: error: unexpected token after '__attribute__' and before '__attribute__' | 0.15 |
| libxml2 encoding.c | oracle front end (desugar) | both fail alike (both crash) | oracle rc 125: internal error: TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> NULL · lean rc 134: PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> <ail_expression> | 1.87 |
| libxml2 xmlIO.c | oracle front end (desugar) | both fail alike | oracle: libxml2/xmlIO.c:1238:12: error: use of undeclared identifier 'dup' · lean: Error {msg: "desugaring failed at libxml2/xmlIO.c:1238:12:"} | 0.85 |
| libxml2 xmllint.c | oracle front end (typing) | both fail alike | oracle: libxml2/xmllint.c:602:20: error: undefined behaviour: identifier with no linkage and incomplete type · lean: Undefined {ub: "UB059_incomplete_no_linkage_identifier", stderr: "", loc: "<602:20--602:22>"} | 0.83 |
| libxml2 chvalid, dict, globals, lintmain, list, runxmlconf, testModule, testapi, testcatalog, testdso, threads, xmlstring (12) | none (stages 1–3) | agreement | sig OK | 0.10–0.87 each |
| libxml2 SAX2, buf, entities, error, hash, parser, parserInternals, runsuite, runtest, shell, testchar, testdict, testlimits, testparser, testrecurse, tree, uri, valid, xmlcatalog, xmlmemory (20) | none (stages 1–3) | agreement | sig: only ordinal artifacts (§4.4) | 0.58–3.47 each (parser.c 3.47, tree.c 2.39) |
| libxml2 HTMLparser, HTMLtree, c14n, catalog, debugXML, nanohttp, pattern, relaxng, schematron, xinclude, xlink, xmlmodule, xmlreader, xmlregexp, xmlsave, xmlschemas, xmlschemastypes, xmlwriter, xpath, xpointer (20) | none (stages 1–3) | agreement, close to vacuous | no main-file decls: whole-file module guard off in the pinned config (e.g. `#ifdef LIBXML_HTML_ENABLED`; `tests/libxml2/config/libxml/xmlversion.h` has it under `#if 0`) | 0.09–0.64 each |

Tallies: the tally line above (56 agreement and 14 both-fail-alike; 0 refusals, resource limits, disagreements and
instrument errors). The recorded run took 69 s of wall time (sum of unit walls, derived; 61 s in the original run). The
original census pass, including both builds, took under 1 h, and the audit fixes and re-run took well under that (no
budget pressure).

**pkvm-init's two exhaustive executions** (corrected by the pre-merge audit, L4). The oracle's random mode is
time-seeded, so the row's `--first` comparison changes from run to run. The traces differed in the original recorded
run and in the first post-audit run, and agreed in a shakedown run and in this recorded run. Either way the row is
agreement, because exhaustive mode agrees. Exhaustive mode has two executions, identical on both engines, which differ
only in the UB's reported location: `<715:2--715:17>` (`pool->max_order`) or `<715:2--715:6>` (`pool`). The earlier
text attributed them to "the two orders in which the `min` macro calls `get_order` twice". That was wrong: `min` is a
`?:` (`minmax.h:5,10`), which is sequenced. The source [AGENT, by probe] is the assignment on `page_alloc.c:715`:
its two operands are unsequenced, so the load of `pool` in the left operand comes either before or after the right
operand's `get_order` call. Oracle `--mode=exhaustive` probes (scratch, deleted), each with an empty-bodied `int
g(unsigned long x) {}`:
- `p->m = (11 < g(4) ? 11 : g(4));` gives 2 executions (`<3:48--3:52>`, `<3:48--3:49>`);
- `v.m = (…);`, with no load on the left, gives 1;
- `int t = (…); p->m = t;` gives 1.

The contract conclusion is unchanged: exhaustive mode agrees, and `--first` is outside the contract.

## 3. Causes ranked by files blocked

The rank key is the number of census files whose FIRST stop the cause is (derived). Tags are from §6.

| Rank | Cause | Files | Where | Tag |
|---|---|---|---|---|
| 1 | Cerberus C parser lacks GNU C syntax (first hit: `__attribute__` 7, `__signed__` 2, `__builtin_va_list` 1; behind them `__extension__`, the `__typeof__`/`__alignof__` spellings, file-scope `asm`, one inline-asm site, file-scope empty declarations and `u128`, §4.2) | 10 (all Linux) | oracle front end (parse; `parsers/c/c_lexer.mll` has no `__attribute__` token) | (b) |
| 2 | Pinned libxml2 config turns every optional module off, so the TU is (nearly) empty | 20 (libxml2; not a stop, but their agreement measures little) | config | (d) |
| 3 | Default (PVI) concrete model: `copy_alloc_id` discards its pointer argument, so computed page pointers have no provenance and stores are `UB_CERB002b` | 3 (pkvm-alloc, -free, -split-merge) | run, both engines | (b); serving it needs PNVI, which Lean refuses: (c) |
| 4 | Oracle libc headers incomplete: `dup` commented out (`runtime/libc/include/posix/unistd.h:13`); `struct timeval` used by `posix/sys/time.h` but never defined | 2 (xmlIO.c, xmllint.c) | oracle front end | (b) |
| 5 | Upstream front-end crash: `(char *) NULL` in a static initializer reaches `is_integer_constant_expression`'s wildcard TODO arm (`frontend/model/cabs_to_ail.lem:757-760`) | 1 (encoding.c) | oracle front end, Lean mirrors the crash | (b) |
| 6 | The program itself: `get_order`'s empty body makes `hyp_pool_init` UB088 | 1 (pkvm-init) | run, both engines | (c), working as designed (correct verdict) |
| 7 | libc mode plus a freestanding definition of a libc name (`memset`) gives a duplicate external at link | 1 (pkvm-alloc-libc) | link, both engines | (c), working as designed (`--nolibc` is the freestanding mode) |

## 4. Supporting measurements

### 4.1 pKVM under PNVI (oracle only; Lean refuses the switch)

Root cause of rank 3, verified by probe (`.tmp/` probes, deleted): `copy_alloc_id(mem+4096 as integer, cn_virt_base)`
returns a pointer with the right address that compares unequal to `census_mem + 4096`. `impl_mem.ml:2810-2814` calls
`intfromptr` on `ptrval`, discards the result, and then calls `ptrfromint ival`. Outside PNVI, `ptrfromint`
(`impl_mem.ml:2206-2215`) keeps only the integer's own provenance, which page arithmetic never carries.

The same drivers on the oracle with `--switches=PNVI_ae_udi`, verbatim:

```
pkvm_alloc        Defined {value: "Specified(61728)", stdout: "", stderr: "", blocked: "false"}
pkvm_free         Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
pkvm_split_merge  Defined {value: "Specified(4508)", stdout: "", stderr: "", blocked: "false"}
```

These agree with native gcc (low bytes `0x20`, `0x00`, `0x9c`). They were re-run on 2026-10-05 with the
run-time-derived `census_pool_init` (§1.3; oracle random mode under the 4G cap), and all three lines were
identical. `61728` = `0xF120` decodes as allocations at pages
0, 2 and 1, then NULL. With `--mode=exhaustive` under PNVI_ae_udi, the oracle breached the 4G cap
(`capped: OOM-KILLED (exit 137 — cgroup memory cap CERB_MEM_MAX=4G breached; memory.events oom_kill=1; NOT a pass)`,
`wall=139.79 maxrss=4203580kB`). Lean's answer to the switch:

```
cerberus-lean: refused — --switches=PNVI_ae_udi: semantics switches (PVI/PNVI/strict_pointer_arith/CHERI/…) are not supported by this port — matched (default-switch) mode is the harness contract and CerbGlobal's switch set is permanently empty; the oracle's `--switches=…` changes the answer (e.g. PNVI turns an integer→pointer UB043 into a value) (see VALIDATION.md, zero-discrepancy Z-24)
```

### 4.2 Linux: what stands behind the first blocker

Static inventory of each TU's oracle-cpp output, comments and line markers stripped (derived counts). The columns
are `__attribute__`, asm, `typeof` (all spellings), statement expressions `({`, `__builtin_*` uses, and `_Generic`.
They count exposure, not blockers (corrected by the pre-merge audit, M1). Plain `typeof` is supported (lexer
`c_lexer.mll:91`, parser `c_parser.mly:956-958`); only the `__typeof__` spelling stopped the peel below. Statement
expressions are supported (parser `c_parser.mly:509-513`, desugar `cabs_to_ail.lem:2507`). Asm statements parse
and are erased (§4.5).

| TU | lines | attr | asm | typeof | `({` | builtins | _Generic |
|---|---|---|---|---|---|---|---|
| ctype | 1490 | 105 | 2 | 2 | 0 | 10 | 1 |
| list_sort | 3525 | 449 | 7 | 30 | 8 | 14 | 7 |
| int_sqrt | 4375 | 876 | 40 | 57 | 12 | 106 | 3 |
| hexdump | 5283 | 1185 | 45 | 91 | 38 | 152 | 29 |
| lcm | 8817 | 2701 | 83 | 39 | 43 | 14 | 7 |
| gcd | 10804 | 3360 | 114 | 94 | 49 | 123 | 9 |
| string | 11830 | 3544 | 147 | 138 | 72 | 157 | 32 |
| sort | 24249 | 6425 | 266 | 603 | 157 | 303 | 22 |
| kstrtox | 37447 | 11526 | 399 | 1129 | 646 | 714 | 77 |
| bsearch | 61336 | 17313 | 542 | 1681 | 889 | 876 | 144 |

A DIAGNOSTIC peel was run on the oracle front end only. It is not a census row and changes the program, so it is
never evidence of agreement. Each round neutralized the blocker classes found so far by extra `-D`:

- **Round 1** (`__attribute__(x)=`, `__signed__=signed`): the next blocker was `__extension__` (5 files) or
  `__builtin_va_list` (gcd).
- **Round 2** (adding `__extension__=` and `__builtin_va_list=__cerbty_va_list`): blockers were file-scope `asm` from
  `EXPORT_SYMBOL` (ctype, list_sort), an inline-asm site the parser rejects in `asm/bitops.h:136` (the
  `GEN_BINARY_RMWcc` expansion; gcd, int_sqrt, hexdump; the parser accepts the extended form in general, at
  `c_parser.mly:1538`, and the exact construct it rejects here was not determined), `u128`
  (string, lcm; `__int128` is not configured or supported), the `__typeof__` spelling in `asm/percpu.h:596` (sort, bsearch) and
  `__alignof__` in `linux/kstrtox.h:37` (kstrtox).
- **Round 3** (also `__typeof__=typeof`, `__alignof__=_Alignof`, `asm(...)=`): a file-scope empty declaration `;`
  (ctype, list_sort), and the inline-asm site again (gcd, int_sqrt).

The peel stopped there. (Corrected by the pre-merge audit, M1: this paragraph used to say that inline asm has no
Cerberus semantics, so raw kernel TUs stop in the front end however far the syntax work goes. That is wrong. The asm
stops above are particular syntax forms: file-scope `asm` and the `bitops.h` site. Asm statements that parse are
silently erased on both engines (§4.5). Until the queued refusal lands, a kernel TU that got past the syntax would run
with its asm dropped; after it lands, every such TU refuses.)

### 4.3 The two upstream front-end crashes (reduced)

```c
/* e1.c */
#include <stddef.h>
struct s { char *n; };
static const struct s t[1] = { { (char *) NULL } };
int main(void) { return t[0].n == NULL; }
```
```c
/* e2.c */
#include <stddef.h>
typedef int (*f)(int);
union u { f a; void *b; };
struct s { union u in; };
static const struct s t[1] = { { { NULL } } };
int main(void) { return t[0].in.a == NULL; }
```

Fork oracle (`--nolibc --exec --batch`), rc 125:

- e1: `internal error: TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> NULL`
- e2: `internal error: Translation called on Ail program with an invalid node`

Pristine upstream `b9aeedcb4`: the same lines, rc 125.

Lean (`--batch`), rc 134:

- e1: `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: TODO: Cabs_to_ail.is_integer_constant_expression, wildcard ==> <ail_expression>`
- e2: `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Translation called on Ail program with an invalid node`

Both engines crash, which is the contract's fail-stop mirror. The difference in failure text is class (a). e1 is the
`encoding.c` stop (`MAKE_HANDLER(NULL, …)`'s `(char *) name`, `encoding.c:310-320`). e2 was found while reducing it,
and no census file hits it first.

### 4.4 The signature sub-signal

52 libxml2 TUs and the elaborated driver TUs carry it. Results: 29 TUs OK, 20 libxml2 TUs with an empty oracle
signature, and 23 TUs (20 libxml2, 3 Linux drivers) where some oracle lines were MISSING verbatim on the Lean side.
Every MISSING line is a `glob a_<n>` (string literal) or `tagdef struct __cerbty_unnamed_tag_<n>` line. Normalizing the
ordinal away, with multiplicity, leaves 0 of 1006 oracle line kinds unexplained in those files (derived). This is
`test_elab.sh`'s documented first-occurrence-ordinal limitation, with Lean's extra header declarations shifting the
ordinals. Bodies are not compared anywhere.

### 4.5 Inline asm: a silent no-op on both engines (pre-merge audit M1)

The front end accepts and erases `asm`:
- the C parser accepts `asm(...)` statements, both the plain form and the extended form via `asm_with_output`
  (`parsers/c/c_parser.mly:1527-1548`, `asm_with_output` at `:1496`);
- the desugarer erases them, `frontend/model/cabs_to_ail.lem:4112-4114`:
  `(* TODO: erasing inline assembly for now *) E.return AilSskip`;
- Lean is generated from the same `.lem`, so both engines drop the asm, silently and identically.

Probe [AGENT] (scratch, deleted): `int main(void) { int x = 1; __asm__ volatile ("movl $5, %0" : "=r"(x));
asm("nop"); return x; }`. Native gcc would return 5. Verbatim:

```
oracle (--nolibc --exec --batch):  Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
lean (--batch, via --cabs-json):   Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

Because the engines agree, this is not a census disagreement. It is a contract defect: a silent absorption that
neither CONTRACT.md, SUPPORTED.md nor VALIDATION.md registers. No census row reached it. The pKVM case study has no
asm, and the Linux TUs stop in the parser first.

Operator ruling, [USER 2026-10-05]: "Re inline asm, this should be a loud refusal". The refusal is a **separate
queued slice**, not done here, because this census is report-only and changes no engine. It is listed in §6, item 4.

## 5. Disagreements

**None.** No census row produced a different answer, a silent absorption, or a Lean success where the oracle fails.
The silent asm erasure (§4.5) is shared by both engines and hit by no row, so it is a contract defect, not a
disagreement.
The one run-stage mismatch (pkvm-init `--first`) is resolved by exhaustive agreement (§2). It sits outside the
contract's §1 promise ("Exhaustive mode is the promise; `--first` is outside it").

## 6. Proposed coverage work, in priority order

Tags:

- (a) Lean-side gap;
- (b) oracle/upstream limitation;
- (c) contract refusal working as designed;
- (d) environment or configuration.

1. **(d) A second, modules-on libxml2 configuration.** Cheap. 20 of 55 TUs are measured empty today. A pinned
   config enabling the modules that need no threads, zlib, iconv or network (e.g. HTML, XPath, XPointer, reader,
   writer, save, regexp, pattern, c14n, schemas) would turn the near-vacuous rows into real elaboration evidence. It
   is the only item that adds reach without touching either engine. It is not a gated-lane change: it would be a
   census or lane decision for the operator.
2. **(b) → (c) decision: provenance switches for pKVM-shaped code.** The north-star target class (hypervisor and
   kernel allocators) computes pointers arithmetically and relies on `copy_alloc_id`. The oracle serves it only under
   PNVI_ae_udi, where its exhaustive mode does not fit in 4G (§4.1). Lean refuses every switch (Z-24). Options:
   - keep the refusal (status quo, correct);
   - a design pass on supporting PNVI_ae_udi in Lean. This is a (a)-class addition needing an operator ruling under
     "don't innovate wrt upstream": it mirrors an existing oracle mode rather than inventing one.
3. **(b) Upstream tray, front end.** e1 and e2 (§4.3, 4-line reproducers, upstream-confirmed) and the broken `-E`
   (§1.2). The oracle's libc header gaps (`dup`; `struct timeval` never defined) block xmlIO.c and xmllint.c.
4. **(b) GNU C in the Cerberus parser: the gate for every Linux TU, and the inline-asm refusal.** The syntax work is
   large and upstream-owned. Behind the first blockers the peel found more unsupported syntax (§4.2). Inline asm does
   not stop the front end: statements that parse are erased on both engines today (§4.5), so a kernel TU that got
   past the syntax would run with its asm silently dropped. Per [USER 2026-10-05] "Re inline asm, this should be a
   loud refusal", asm must refuse loudly. That refusal is a **separate queued slice**, not done here. Once it lands,
   every asm-bearing kernel TU refuses, and every preprocessed Linux TU in this census has asm (§4.2). Recommendation
   [AGENT]: do not pursue raw kernel TUs. The realistic route to kernel code is the pKVM shape: a curated, CN-style C
   subset with the environment made explicit. That puts item 2 ahead of this item.
5. **(c) No action, recorded for consumers.** Freestanding code that defines libc names (`memset`) must run with
   `--nolibc`, since libc mode refuses the duplicate external identically on both engines. pkvm-init's UB088 is a
   correct verdict about the case study's `get_order` stub.
6. **(a) No Lean-only gap found.** (The asm erasure, §4.5, is shared by both engines; its refusal is item 4's queued
   slice.) The only Lean-side follow-up the census suggests is the standing one: stage-3 evidence is
   success parity plus signature level, and a body-level elaborated-Core comparison remains a next-arc item
   (`test_elab.sh` header).

## 7. What could not be done

- **No Linux driver main ran.** Every Linux unit stops in the oracle parser before linking. The drivers are committed
  (gcc-syntax-checked) for the day the front end gets further.
- **No kernel build** (by scope). `asm-offsets.h`, `rq-offsets.h` and `bounds.h` are empty stubs, and their effect on
  later stages is unknown, because nothing got past parsing.
- **pKVM under PNVI could not be compared**: Lean refuses the switch, and exhaustive oracle under PNVI breaches the
  4G cap.
- **Elaboration bodies are not compared**: §4.4 is signature-level only.
- **libxml2 running beyond the chvalid/URI lanes was not attempted** (out of scope).
- **No upstream filing.** The box is offline and the census is report-only. The §4.3 reproducers and the `-E` finding
  are offered to the upstream tray, for the operator.
- The validation gate battery was not run: this is a census, not a checkpoint or merge claim. The engines used are
  stamp-verified builds of `ae48126e5`; the rebase onto `7fc9b7bec` changed no engine source (§1.1).
- **The asm refusal was not implemented** (report-only; it is the queued slice in §6, item 4).

## 8. Reproduce

From the worktree root, after the §1.1 builds:

```bash
/home/dev/projects/cerberus-lean-proj/scripts/ce opam exec --switch=. -- tests/census/run_census.sh .tmp/census/final
```

An optional second argument is a unit-name regex. `deps/linux`, `deps/libxml2` and the case study are found by
walking up from the worktree (`LINUX_DIR` overrides the Linux path). The script refuses to run on stale engines, on
drifted libxml2 or libc pins, or on a drifted case study (the `census_pool_init` derivation's exact-match checks). It
ends with the `census: tally:` line and exits 1 if any row is INSTRUMENT-ERROR.

## 9. Pre-merge audit 2026-10-05

A fresh pre-merge audit; the orchestrator verified M1 and M2. Fixes by the fix worker [AGENT], after rebasing onto
`7fc9b7bec` (clean). The whole census was then re-run once, and its tally is unchanged (§2, verbatim line).

| Finding | Disposition |
|---|---|
| **M1** The record said inline asm has no Cerberus semantics and stops raw kernel TUs in the front end; it also listed `typeof` and statement expressions as blockers | FIXED (record). Corrected in §0, §3 rank 1, §4.2 and §6 item 4. New finding §4.5: inline asm is a silent no-op on both engines (parser `c_parser.mly:1527-1548`, erasure `cabs_to_ail.lem:4112-4114`, probe) and unregistered in CONTRACT, SUPPORTED and VALIDATION. Ruling recorded verbatim, [USER 2026-10-05] "Re inline asm, this should be a loud refusal"; the refusal is a separate queued slice, not done here. `typeof` and statement expressions removed from the blockers (`c_lexer.mll:91`, `c_parser.mly:509-513`, `cabs_to_ail.lem:2507`); the peel-round evidence stands |
| **M2** `pkvm_driver.h`'s `census_pool_init` was `hyp_pool_init`'s body copied from GPL-2.0-only `page_alloc.c` | FIXED. The body is removed from the repository; `pkvm_driver.h` keeps a prototype. `tests/census/pkvm/derive_pool_init.py` derives the function at run time (exact-match and sha256 checks, the one `get_order` → `max_order` substitution) into the census output directory only (§1.3). The rest of `tests/census/` was checked: the Linux drivers restate only prototypes, `struct list_head` and the ctype bit values, which the worker judges [AGENT] to be interface facts that are fine to keep (§1.3) |
| **L1** "Oracle front end fails, Lean fails on a different TU" was filed as an oracle front-end failure | FIXED. It is now a `DISAGREEMENT(…)` row (`run_census.sh`). No census row is in this class |
| **L2** `observation_capture`'s infrastructure rc 125 collides with the oracle's internal-error rc 125 | FIXED. The `.capture-error` marker is detected, the row is `INSTRUMENT-ERROR` and the run exits 1. Plant-tested (§1.2) |
| **L3** A refusal was a bare `grep refused` over all captures | FIXED. `lean_refusal` matches only the engine's attributed forms with their exit codes (§1.2). Plant-tested |
| **L4** "The two orders in which `min` calls `get_order`" is wrong, because `?:` is sequenced | FIXED (record). By probe, the source is the unsequenced operands of the assignment on `page_alloc.c:715` (§2). The contract conclusion stands |
| **L5** Driver `--include` wording; `-DCERB_WITH_LIB` in the cpp mirror against stage 1's `--nolibc`; engines inheriting stdin | FIXED. Wording fixed (§1.3). The mirror never adds `-DCERB_WITH_LIB`, matching stage 1. Every engine gets `</dev/null`, and units are read on fd 3 |
| Info: the case study's `memset` is an empty-bodied stub that `page_alloc.c:398` relies on | NOTED (§1.3) |
| Info: empty leftover `.tmp/scripts/observations/` | DELETED. (`common.sh`'s evidence path re-creates it during runs; it is deleted again at slice end) |
