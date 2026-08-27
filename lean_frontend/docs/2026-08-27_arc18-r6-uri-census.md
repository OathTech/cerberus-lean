# Arc-18 R6 — THE URI.C IDIOM CENSUS ([F9] pre-registered artifact)

STATUS: committed BEFORE any corpus construction, per charter [F9]:
this is the pre-registered list against which R9's "trivial by
construction" claim is later checked — it is graded against THIS
text, never end-of-arc by the same hands that built the corpus.
Worker slice of the segment ladder (charter:
`docs/2026-08-26_arc18-segment-ladder-charter.md`, rung R6), branch
`arc/segment-ladder`. Provenance: [AGENT] empirical enumeration of
`deps/libxml2/uri.c` (2783 lines, the tree behind
`scripts/test_libxml2_uri.sh` / `scripts/libxml2_prep.sh`); all
counts are grep-derived over that file (commands preserved in the
worker transcript; tallies LABELED derived). Line numbers cite
`deps/libxml2/uri.c`.

## 0. Method + honesty note

The whole file was read; counts were then taken by grep so they are
reproducible. The census is organized by IDIOM FAMILY (the unit a
corpus program can rehearse), not by function. Families are listed
with their in-file frequency and 2–3 representative `file:line`
examples. Where a family is KNOWN to be beyond the current
substrate's demonstrated reach (e.g. `goto`-heavy multi-exit,
snprintf), it is listed anyway — the census is of uri.c, not of what
flatters the corpus. §9 lists what the census does NOT contain
(idioms uri.c happens not to use), so the corpus is not padded with
irrelevant material and R9's check has a closed universe.

Function inventory (derived): 33 function definitions; the RFC 3986
parser family (`xmlParse3986*`, 15 functions, lines 196–947), the
serializer family (`xmlSaveUri*`, 1074–1358), lifecycle
(`xmlCreateURI`/`xmlCleanURI`/`xmlFreeURI`, 1057–1425), path helpers
(`xmlNormalizePath`/`xmlIsPathSeparator`/`xmlIsAbsolutePath`,
1433–1557, 1836–1851), escape/unescape (1559–1828), resolution
(`xmlResolvePath`/`xmlBuildURISafe`/`xmlBuildRelativeURISafe`,
1862–2726).

## 1. Loop shapes (34 `while` + 3 `for` — derived counts)

The dominant control idiom. Sub-families:

- **L1 — guarded char-class scan** (advance while a predicate on
  `*cur` holds; the RFC-grammar workhorse): 8 sites.
  Examples: `while (ISA_ALPHA(cur) || ISA_DIGIT(cur) || …) cur++`
  (uri.c:240, scheme); `while ((ISA_PCHAR(uri, cur)) || (*cur == '/')
  …) NEXT(cur)` (uri.c:272, fragment; :305 query); `while
  (ISA_UNRESERVED(uri, cur) || …) NEXT(cur)` (uri.c:383 userinfo,
  :495 host); `while (ISA_PCHAR(uri, cur) && (*cur != forbid))`
  (uri.c:591 — scan guard with a RUNTIME-parameter character).
  Note the `NEXT` step is NON-UNIFORM: `(*p == '%')? p += 3 : p++`
  (uri.c:108) — a data-dependent stride inside the scan.
- **L2 — sentinel scan to NUL or stop-char**: 15+ sites.
  Examples: `while ((*cur != ']') && (*cur != 0)) cur++` (uri.c:462,
  IPv6 bracket scan); the 11 `while (*p != 0)` serializer copy loops
  (uri.c:1113, 1130, 1157, 1186, 1213, 1260, 1288, 1304, 1330);
  `while ((bptr[pos] == rptr[pos]) && (bptr[pos] != 0)) pos++`
  (uri.c:2584, common-prefix scan over TWO strings).
- **L3 — separator-driven iteration** (loop whose body calls a
  helper): 4 sites — `while (*cur == '/') { cur++; ret =
  xmlParse3986Segment(…); if (ret != 0) return(ret); }` (uri.c:615,
  660, 703, 745). HELPER-IN-LOOP with error propagation: the single
  most load-bearing composite idiom in the file.
- **L4 — counted/index loops**: `for (; ix > 0; ix--)` backward scan
  (uri.c:2599); `for (; bptr[ix] != 0; ix++)` slash count
  (uri.c:2608); `for (; nbslash>0; nbslash--)` emit `../` groups
  (uri.c:2654); `while ((i > 0) && !xmlIsPathSeparator(base[i-1],
  1)) i--` (uri.c:1912, backward trim); `while (out < cur)` indexed
  copy (uri.c:2270).
- **L5 — accumulate-with-guard loop**: the port parser
  (uri.c:347–358): `while (ISA_DIGIT(cur))` with `port = port*10 +
  digit` under TWO overflow guards (`port > INT_MAX / 10`,
  `port > INT_MAX - digit`) — arithmetic loop invariant + range
  reasoning in one loop.
- **L6 — nested loops**: xmlNormalizePath's outer `while (*cur !=
  0)` containing three inner scans (collapse separators uri.c:1479,
  do-while backward pop uri.c:1500–1503, copy segment uri.c:1524);
  the serializer's per-component `while` under per-char capacity
  `if` (uri.c:1113–1126); base-path copy `while` inside `while`
  (uri.c:2263–2274).
- **L7 — dual-pointer in/out copy loops** (in-place or
  target-buffer rewriting): xmlURIUnescapeString `while(len > 0)`
  consuming `in`, producing `out`, with a 3-byte %XX case vs 1-byte
  default (uri.c:1597–1622); xmlNormalizePath `cur`/`out` in-place
  compaction (uri.c:1463–1540); xmlURIEscapeStr `while(*in != 0)`
  1-in/3-out expansion (uri.c:1656–1695).

## 2. Char-class checks (the predicate vocabulary)

- 30 `#define`s total; the class macros: `IS_LOWALPHA`/`IS_UPALPHA`/
  `IS_DIGIT` (range pairs, uri.c:53/60/68), `IS_MARK`/`IS_RESERVED`/
  `ISA_SUB_DELIM`/`ISA_GEN_DELIM` (literal disjunction chains, 9–12
  arms, uri.c:79/95/138/147), composites `IS_ALPHANUM`/
  `IS_UNRESERVED`/`ISA_PCHAR`/`ISA_PCT_ENCODED` (uri.c:73/103/173/
  167 — the last with `p+1`/`p+2` LOOKAHEAD inside the predicate).
- 36 use sites of `IS_*`/`ISA_*` outside definitions/comments
  (derived).
- 140 `== '<char>'` literal comparisons; 29 `>= '0'|'a'|'A'` range
  checks (derived).
- Function-form predicates (the same shape as C functions, so they
  land as CALLS not macro-splices): `is_hex` (uri.c:1559–1565),
  `xmlIsUnreserved` (uri.c:196–212, flag-dependent), 
  `xmlIsPathSeparator` (uri.c:1434–1446).
- Bit-flag tests on a struct field: `uri->cleanup &
  XML_URI_NO_UNESCAPE` etc. — 10 test sites + 2 writes (uri.c:203,
  206, 278, 310, 389, 504, 623, 669, 711, 753; writes 1035, 1727).

## 3. Pointer arithmetic patterns

- **P1 — cursor advance**: ~60 `cur++`/`p++`/`in++`/`+=` advance
  sites (derived); non-unit strides `cur += 2/3`, `p += 3`
  (uri.c:423/425/428/431, 789, 837; NEXT macro uri.c:108).
- **P2 — lookahead without advance**: 19 sites of `cur[1]`,
  `cur + 1`, `cur + 2`, `p[1]`, `in[2]` (uri.c:420–431 dec-octet;
  :788 `(*cur == '/') && (*(cur + 1) == '/')`; :1489–1497 dot
  handling; :1598 `%XX` guard).
- **P3 — pointer difference as length**: 20 sites of
  `cur - *str` / `cur - host` / `fragment - escRef` / `end - server`
  feeding STRNDUP/unescape (uri.c:244, 279, 311, 322, 390, 505,
  1892, 2397).
- **P4 — by-reference cursor (`const char **str`)**: every
  `xmlParse3986*` helper reads `cur = *str` and commits `*str = cur`
  on success (uri.c:227/248, 343/361, …) — the parse-position
  OWNERSHIP-of-a-cursor protocol; 15 functions.
- **P5 — backward pointer motion**: `out--` pop-segment do-while
  (uri.c:1500–1503), `vptr[-1]` (uri.c:2664), `base[i-1]`
  (uri.c:1912).

## 4. Early returns / multi-exit (186 `return` sites — derived)

- **E1 — NULL-argument guards at entry**: `if (uri == NULL)
  return …` family — 121 `== NULL` tests total (derived); entry
  guards at uri.c:197, 927, 966–970, 1102, 1384, 1413, 1460, 1584,
  1642, 1719, 1871, 1979–1984, 2506–2510.
- **E2 — error-code ladder**: `ret = helper(…); if (ret != 0)
  return(ret);` — 24 sites (uri.c:539/545/549, 618, 663, 702–706,
  744–748, 791/798, 803/806, 839–847, 858–864, 889/895/899/903).
  Distinguished -1 (memory) vs 1 (syntax) vs 0 (ok): `if (ret < 0)
  return(ret)` (uri.c:538, 936, 2045, 2513).
- **E3 — goto-based exits**: 90 `goto` sites, 10 labels (derived):
  `mem_error` (xmlSaveUri, 21 sites), `done` (xmlBuildURISafe ~40
  sites; xmlParseUriOrPath; xmlBuildRelativeURISafe), `err_memory`
  (xmlResolvePath, 5), `step_7` (3, a FORWARD skip into the success
  path), `found`/`not_ipv4` (xmlParse3986Host, backtrack point),
  `escape` (uri.c:2559→2675). Cleanup-on-exit is concentrated at
  the labels (free temporaries, fall-through returns).
- **E4 — backtracking**: `not_ipv4: cur = *str;` (uri.c:489–490) —
  failed sub-parse RESETS the cursor and falls through to an
  alternative grammar production; also the try-absolute-then-
  relative structure of xmlParse3986URIReference (uri.c:935–945).

## 5. Helper-call patterns

- 32 call sites into the `xmlParse3986*` family (derived): argument
  is `&cur` (a LOCAL cursor) or the caller's own `str` pointer;
  results consumed via E2 ladders. Call depth in practice:
  URIReference → URI → HierPart → Authority → Userinfo/Host → 
  DecOctet — 6 levels of contract composition, each level a
  cursor-advancing partial parser with tri-state result.
- Helpers called under a loop: L3 above (Segment under the four
  path loops; DecOctet four times sequentially in Host with
  lookahead `.` checks between, uri.c:472–487).
- NULL-as-uri "dry-run" mode: every parser accepts `uri == NULL`
  and then only advances the cursor (validation without
  side-effects) — e.g. uri.c:242, 275, 307, 359.

## 6. Struct/field access patterns

- 342 accesses to `xmlURI` fields via `uri->`/`res->`/`ref->`/
  `bas->` (derived; field histogram: path 101, server 39, scheme
  31, user 27, query 26, authority 26, query_raw 25, fragment 25,
  port 21, cleanup 12, opaque 9).
- **S1 — free-then-assign ownership update**: `if (uri->x != NULL)
  xmlFree(uri->x); uri->x = STRNDUP/unescape(…); if (uri->x ==
  NULL) return(-1);` — 30 `xmlFree(uri->…)` sites (uri.c:243–246,
  276–283, 308–324, 388–394, 500–511, 621–631, …).
- **S2 — whole-struct reset**: xmlCleanURI nulls 9 owned pointers
  (uri.c:1383–1404); xmlFreeURI frees 9 + the struct (uri.c:
  1412–1425); create = malloc + memset + one field (uri.c:
  1058–1067).
- **S3 — field-to-field copy between structs**: xmlBuildURISafe's
  step algebra copies `bas->`/`ref->` fields into `res->` under
  presence tests, ~20 `xmlMemStrdup(…->…)` sites (uri.c:2090–2232).
- **S4 — scalar field with sentinel values**: `port` with
  `PORT_EMPTY 0` / `PORT_EMPTY_SERVER -1` (uri.c:36–37, 795–796,
  2088, 2109).

## 7. Allocation patterns

- **A1 — malloc + NULL check + early error**: 8 `xmlMalloc` sites
  (uri.c:1061, 1106, 1590, 1651, 1921, 2250, 2645).
- **A2 — computed allocation size**: `len + refLen + 1`
  (uri.c:1921), `len + 3 * nbslash` with an explicit `SIZE_MAX`
  overflow guard (uri.c:2641–2645), `len += 20` slack (uri.c:1650).
- **A3 — grow-on-demand realloc**: `xmlSaveUriRealloc` (growCapacity
  + realloc + swap, uri.c:1074–1086) invoked from 21 capacity-guard
  blocks of the shape `if (len + 3 >= max) { temp = realloc; if
  (temp == NULL) goto mem_error; ret = temp; }`; the same shape
  inline in xmlURIEscapeStr (uri.c:1657–1673).
- **A4 — strdup family**: 48 `xmlStrdup`/`xmlStrndup`/
  `xmlMemStrdup`/`STRNDUP` sites (derived).
- **A5 — byte-block ops**: 7 `memcpy`/`memset` sites (uri.c:1064,
  1925–1926, 2435–2437, 2665–2668).
- **A6 — alloc-or-target parameter**: xmlURIUnescapeString writes
  into caller's `target` if non-NULL else mallocs (uri.c:1589–1594).

## 8. Output-buffer append + encode/decode arithmetic

- **O1 — append with capacity guard**: 55 `ret[len++] = c` /
  `ret[out++]` / `*out++` / `*vptr++` append sites (derived),
  always under an A3 guard in the serializer (uri.c:1119, 1126,
  1153–1154, 1193, 1210–1211, …).
- **O2 — percent-encode arithmetic**: `hi = val / 0x10, lo = val %
  0x10; ret[len++] = hi + (hi > 9? 'A'-10 : '0')` — 8 sites
  (uri.c:1139–1143, 1170–1174, 1225–1229, 1272–1276, 1313–1317,
  1339–1343, 1680–1689).
- **O3 — hex-decode accumulation**: `c = c * 16 + (*in - 'a') + 10`
  three-way ladders (uri.c:1601–1613).
- **O4 — snprintf**: 2 sites, both `%d` of port (uri.c:1202, 1783)
  — libc-format dependency, census-listed though outside any
  near-term proof reach.

## 9. What uri.c does NOT contain (closed-universe note)

No arrays-of-structs; no function pointers; no switch statements; no
recursion (the parser family is mutually non-recursive — straight
call DAG); no unions; no bitfields; no variadic calls beyond
snprintf; no floating point; no dynamic data structures beyond flat
strings (no lists/trees); no concurrency. Corpus programs rehearsing
those idioms would NOT be justified by this census.

## 10. Ranked census summary (what a uri.c-shaped corpus must cover)

Derived ranking by frequency × structural load:

1. Sentinel/guarded char scans over byte buffers (L1/L2; the NEXT
   non-uniform stride).
2. Early-return NULL/error guards + the E2 error-code ladder.
3. Struct field ownership discipline (S1 free-then-assign; S3
   copy-under-presence-tests).
4. Helper composition with by-reference cursors (P4 + §5), incl.
   helper-in-loop (L3) and backtracking (E4).
5. Append-with-capacity-guard serialization (O1 + A3).
6. Pointer arithmetic: lookahead (P2), pointer-difference lengths
   (P3), dual-pointer copy (L7).
7. Arithmetic loops with overflow guards (L5) + encode/decode
   arithmetic (O2/O3).
8. Allocation with computed sizes + grow loops (A1–A3).
9. goto-based multi-exit cleanup (E3) — pervasive in the big
   resolution functions.
10. Counted/backward loops (L4/P5) and nested loops (L6).

---

# THE CORPUS PLAN (rung R6, Step 2 — maps tiers to the census)

Sources: all programs FRESH-WRITTEN minimal C by the worker except
where marked `[cn-shape]` = clean-room re-implementation of a SHAPE
observed in `deps/cn/tests/cn` (Yolo rule: shapes only, never text).
Every program gets: tests/verify fixture (.c + oracle-pinned .core +
expectation rows), threaded guarded-∀-seed statement (house shape,
statement-gate rows), proof via `verify_fn` + invariant(s) +
`seg_auto`, safety twin `_ubFree` (marginal cost recorded), trio
cone pins. Budget [F5]: spec + invariant declarations + ≤6 manual
steps; over-budget ⇒ PARK as design finding; two consecutive ⇒ HALT.

Constraint inherited from the substrate (recorded honestly, not
hidden): the current house harness (`callND`) takes INT-family
scalar arguments; string-buffer idioms are rehearsed over
caller-allocated int/char arrays written by the program itself, or
byte parameters, staying within the demonstrated harness forms
(T1–T7). Where a census idiom NEEDS a pointer-argument harness form
(e.g. scan over a caller buffer), building that harness form is
in-scope for the batch that first needs it, and its cost is recorded
as harness-form cost, not program cost.

## EASY tier (~5; the cost floor — target ~0 manual lines)

| id | program | census tie |
|----|---------|------------|
| e1 | `int clamp0(int x)` — single compare + select | E1-style guard shape, minimal branch |
| e2 | `int abs3(int x)` — if/else return | branch floor |
| e3 | `int scale(int x)` — straight-line arith 3 stmts | straight-line floor |
| e4 | `int is_digit(int c)` — range-pair predicate | §2 IS_DIGIT verbatim shape |
| e5 | `int is_mark(int c)` — 9-arm literal disjunction | §2 IS_MARK chain shape |

## CENSUS tier (~10–14; one idiom each, then combinations)

| id | program | census row |
|----|---------|-----------|
| c1 | `scan_digits`: count leading digits of a local byte array (guarded scan) | L1 |
| c2 | `scan_to_nul`: length of a NUL-terminated local array (sentinel scan) | L2 |
| c3 | `port_acc`: digit-accumulate with INT_MAX/10 + INT_MAX-digit guards | L5, §8 |
| c4 | `hex_val`: 3-way range ladder returning 0–15 / −1 | O3, §2 |
| c5 | `pct_encode1`: hi/lo nibble split + 'A'-10 arithmetic into locals | O2 |
| c6 | `skip_stride`: scan with data-dependent stride (%XX ⇒ +3 else +1) | L1+NEXT |
| c7 | `count_slashes`: counted forward loop over array with compare | L4 |
| c8 | `trim_back`: backward index loop (`while (i>0 && a[i-1]!=sep) i--`) | L4/P5 |
| c9 | `copy_compact`: dual-index in/out compaction (drop a char class) | L7 |
| c10 | `common_prefix`: two-array simultaneous scan to first difference | L2 (2584) |
| c11 | `lookahead2`: dec-octet-style classify by `a[i]`,`a[i+1]`,`a[i+2]` | P2 |
| c12 | `field_update`: struct with 2 fields, guarded overwrite + sentinel port | S1/S4 |
| c13 | `err_ladder`: helper returns 0/1/−1; caller ladder propagates | E2, §5 |
| c14 | `scan_then_len`: scan + pointer-difference length (index form) | P3 |

(Combinations grow past 20 total if coverage demands; c-programs
may merge when one fixture cleanly rehearses two rows — recorded in
the campaign table either way.)

## EDGE tier (~5–7; difficulty-biased — findings, not grinds)

| id | program | census/charter tie |
|----|---------|-----|
| x1 | `nested_scan`: outer segment loop, inner char scan (two loop labels, two invariants) | L6/L3 |
| x2 | `break_scan`: loop with early `break` + post-loop classify; and/or `continue` arm | E3-lite, T7 lineage |
| x3 | `helper_in_loop`: `while (a[i]=='/') { i++; r = seg(&i); if (r) return r; }` — TWO-function program, call rule via FnSpec/Summary.consume | L3 + charter call-rule item |
| x4 | `alias_frame`: two disjoint objects written interleaved; spec pins both (frame stress) | charter edge row |
| x5 | `lock_pair`: lock/unlock as C functions with FnSpec contracts transferring a shared cell's footprint + invariant (CSL lineage; the pKVM buddy rehearsal per notes/2026-08-26_cmm-pkvm-scoping-spike.md) | charter ratified edge example |
| x6 | `arith_inv`: loop with a nontrivial arithmetic invariant (running sum with algebraic close, T5-plus) | L5 |
| x7 | `early_in_loop`: return-from-inside-loop (multi-exit segment composition) | E2/E4 |

## SIZE LADDER (2–3; measure where the substrate bends — a found
cliff becomes a BETTER-ABSTRACTIONS work item, never pushed through)

| id | program | measures |
|----|---------|----------|
| z1 | `long_line`: ~60-statement straight-line function (locals reused) | rounds-per-mint, elaboration wall-clock vs statement count |
| z2 | `wide_ctx`: ~16 locals all live to the end | context width at the pack/frame |
| z3 | `long_loop`: trip count ~10⁴ at a concrete instance (symbolic-n statement if reachable) | invariant-rule scaling vs trip count |

## Family-∀ speclab targets (Step 4; non-blocking)

R1 divmod / R5 swap statements (landed honest-UNPROVED at C4):
attempted through the layer where it reaches; park-with-price
otherwise.

## Measurement protocol (feeds the campaign record)

Per program: manual proof lines (spec / invariant / manual steps,
against the [F5] budget), laws added (registry census delta —
the marginal-law rate per batch = the saturation curve), safety-twin
marginal cost (lines + wall-clock), wall-clock per program,
walls/parks with prices. Batches of ≤5, full Tier A green per batch,
one commit per batch, interim report to main at each batch boundary.
