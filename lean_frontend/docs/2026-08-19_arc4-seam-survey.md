# Arc 4: Lean-vs-OCaml seam survey (read-only, Opus worker)

Side-by-side comparison of every hand-written Lean seam against its OCaml
reference. Generated code is lem-shared by construction; ALL divergence
lives here. 30 ranked live-bug suspects + latent list + coverage
statement. Orchestrator cross-references: findings 1-3 ↔ S3a's
ACTION_ILLTYPED class; finding 5 ↔ 066-cast-float; findings 1/4 ↔
052-sizeof-expr; finding 22 ↔ multi-execution ordering.

## Top-tier findings (full report in orchestrator transcript; this file
## records the actionable extract — 30 live-bug suspects, tier-3 latents,
## coverage statement)

### Tier 1 (structs/unions/floats — blocks the current FAIL class)
1. CerbMem sizeofCtype/alignofCtype return 0/1 for struct/union (impl_mem.ml:161-273 not mirrored); poisons sizeof, allocation (1 byte per struct!), strides, memberShift. [S3b]
2. reconstructValue has NO Struct/Union arms → every aggregate load is MVunspecified; lastUsedUnionMembers stored but never read (impl_mem.ml:1055-1093). [S3b]
3. memValueToBytes: no inter-member/trailing padding; union writes only active member (impl_mem.ml:1199-1220). [S3b]
4. sizeof_fty/alignof_fty 4/8/16 vs DefaultImpl 8/8/8; CerbMem.basicTypeSize duplicates the wrong constants (ocaml_implementation.ml:206-253). [S3b]
5. CerbFloat.of_string parses via toNat? → any real literal becomes 0.0 (= the 066 mismatch; impl_mem.ml:2523). [S3c]
6. ivfromfloat via Float.toUInt64 → negatives/NaN → 0 (impl_mem.ml:2553-2554). [S3c]

### Tier 2 (arithmetic/pointer semantics; selected)
7. Int / and % are ediv/emod; OCaml truncates (Z.div, two distinct rem functions). -7/2: OCaml -3, Lean -4. [S3c]
8-10. eqPtrval missing provenance-fork msum; lt/le return false where OCaml fails UB; diffPtrval missing same-alloc/bounds checks + array-level strip. [S3c/backlog]
11. Initialized allocations left writable (OCaml: read-only prefixes → MerrWriteOnReadOnly). [backlog]
12. NoProvPtr emitted where OCaml has three distinct outcomes (DeadPtr/OutsideLifetime/OutOfBoundPtr) — OCaml never emits this constructor. [S3c]
13-16. store check order; memcpy without checks; varargs stubs; eff arrayShift panics on null instead of MerrArrayShift UB (= 098 neighborhood). [S3c/backlog]
17. CerbMem.isSignedIty duplicates and DISAGREES with CerberusImpl (Wchar_t, Enum0). [S3b]
18. maxIval Bool0=1 vs OCaml 255; enum range via stubbed typeof_enum. [S3c]
19-21. byte-provenance policy; function-pointer reconstruction missing; struct BEq tag-only. [backlog]
22. CerbND NDnd/NDstep accumulation REVERSED vs smt2.ml foldlM (permutes multi-execution first-verdict). [S3b step 0 — protects baseline]
23. Guards/branches never pruned; concrete cs_module DOES evaluate constraints (header comment wrong). [backlog unless 098/printf demands]
24-30. kill-order/realloc-error-constructor/decode-wrapI/encode %256 vs land 0xff/format_string_of_float stub/UTF-8 JSON crash. [S3c: 26,28; backlog: rest]

### Tier 3: latents + coverage statement — see orchestrator transcript;
### headline gaps NOT compared at all: CerbFS (largest untouched seam),
### CoreParser (no OCaml counterpart), CerbConcurrency, instance files.

### Addendum 2026-08-22 (cn-coverage audit)
31. DELIBERATE DIVERGENCE, documented in-code: CoreParser.lexDoubleAngle
    stops at the first '>' while OCaml's ub_name lexeme
    (core_lexer.mll:250-251) admits '<'/'>' inside DUMMY(...) payloads.
    Fail-closed (loud Lean parse error, never silent divergence);
    empirically unreachable — no in-tree DUMMY payload contains '>'
    (tree-wide sweep at the cn-coverage audit). Becomes live only if a
    future std.core stub names a payload with '>'; the fix then is to
    mirror the ub_name regex in lexDoubleAngle. [audit A-1, resolved by
    in-code comment at CoreParser.lean undef arm]
