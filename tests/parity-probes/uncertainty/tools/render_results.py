#!/usr/bin/env python3
"""render_results.py — render run_probes.sh result files as the record's markdown tables.

Each probe gets the survey's classification (the cls dictionary, dated 2026-10-20: CORRECT / SILENT WRONG /
NOISY WRONG / STRICT / LENIENT / UNSUPPORTED / IMPL-DEF DIVERGENCE / UNCLEAR, with a note); a probe not in the
dictionary is printed with an empty classification so that a new probe is visible, never silently graded.
usage: python3 -I tests/parity-probes/uncertainty/tools/render_results.py <results.txt>...  > tables.md
"""
import sys, collections
rows = {}
for f in sys.argv[1:]:
    for line in open(f, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        if " | " not in line: continue
        rows[line.split(" | ")[0].replace(".c", "")] = line
def table(prefixes, cls):
    """cls: dict probe-name -> (classification, note)"""
    out = ["| probe | gcc 13 (`-std=c11 -w`, exit code = return value mod 256) | harness line (verbatim, `scripts/test_exec.sh`, both engines) | classification | note |", "|---|---|---|---|---|"]
    for n in sorted(rows):
        if any(n.startswith(p) for p in prefixes):
            parts = rows[n].split(" | ")
            gcc = parts[1].replace("|", "\\|")
            h = " | ".join(parts[2:]).replace("|", "\\|")
            if len(h) > 230: h = h[:230] + "…"
            c, note = cls.get(n, ("", ""))
            out.append(f"| `{n}` | {gcc} | `{h}` | **{c}** | {note} |")
    return "\n".join(out)

C = "CORRECT"; SW = "SILENT WRONG"; NW = "NOISY WRONG"; ST = "STRICT (correct UB verdict)"; LEN = "LENIENT (UB not reported; deliberate upstream reading)"; U = "UNSUPPORTED (declared refusal)"; IMPL = "IMPL-DEF DIVERGENCE"; UNC = "UNCLEAR"

cls = {}
# anonymous members
for n in ["an-03-desig","an-04-anon-struct","an-05-anon-struct-zero","an-06-anon-struct-desig","an-07-anon-union-second","an-09-anon-static","un-01-named-elision","un-02-named-braced","un-04-anon-last","un-07-anon-single-member-union","un-08-named-single-member","un-10-anon-desig-after","au-05-named-ctl-sizeof","au-06-named-ctl-alias","au-07-anon-struct-sizeof"]:
    cls[n] = (C, "")
cls["an-01-ctl"] = (SW, "a=1,b=2,d=3 expected (321 = 65 mod 256); engines 21: `3` went into the union's second member `c`, `d` stayed 0")
cls["an-02-elision"] = (SW, "as an-01")
cls["an-08-anon-nested-braces"] = (SW, "false UB081: a braced initializer for an anonymous struct member is treated as a braced scalar")
cls["un-03-anon-where-did-3-go"] = (SW, "engines: s.c = 3, s.d = 0 (gcc: c = 2 (low byte of b), d = 3)")
cls["un-05-anon-two-after"] = (SW, "every member after the anonymous union is shifted by one slot (e = 0)")
cls["un-06-anon-first"] = (SW, "b=2, c=3, d=0 instead of b=2, d=3")
cls["un-09-anon-static"] = (SW, "static storage, same shift")
cls["un-11-anon-in-array"] = (SW, "array of such structs: d never initialised")
cls["un-12-anon-union-of-structs"] = (SW, "false UB081")
cls["au-01-sizeof"] = (SW, "sizeof(struct{union{int;char;};}) = 8 (gcc 4): the union's members get separate storage")
cls["au-02-alias"] = (SW, "`s.b = 0x01020304; return s.c` → Unspecified (gcc 4): the anonymous union's members do not alias")
cls["au-03-alias-write-c"] = (SW, "write through `c`, read `b`: 0 instead of 9")
cls["au-04-offsetof-d"] = (SW, "offset of the member after the union: 12 (gcc 8)")
cls["au-08-anon-union-in-union"] = (SW, "`union U { int x; struct { short lo, hi; }; }`: both `lo` and `hi` alias the low half (33 vs 53)")
cls["au-09-array-of-anon"] = (SW, "false UB036 (reading the separately-stored, never-written `c`)")
cls["au-10-assign-copy"] = (SW, "struct copy: `t.c` Unspecified (gcc 2)")
cls["ax-01-anon-struct-padding"] = (SW, "anonymous STRUCT: sizeof 8 (gcc 12) when the inner struct is more aligned than the member before it")
cls["ax-02-anon-struct-padding-offset"] = (SW, "offset of `c` 4 (gcc 8)")
cls["ax-03-parity-shape-layout"] = (SW, "the parity-probe shape, checked for LAYOUT: false UB036 (gcc 17 = sizeof 16 + 1)")
cls["ax-04-anon-union-named-struct-inside"] = (SW, "false UB036")
cls["ax-05-anon-union-ptr-member"] = (SW, "sizeof 16 (gcc 8)")
cls["ax-06-anon-union-ptr-alias"] = (SW, "false UB (unspecified pointer equality): `vp` does not alias `ip`")
cls["ax-07-anon-union-copy-via-ptr"] = (SW, "false UB: the kernel-style `p->vp = q; ... s.ip` round trip")
cls["ac-01-anon-union-desig-first-then-alias"] = (SW, "designated init of `.v` then read `bytes[0]`: 0 (gcc 4)")
cls["ac-02-anon-union-sizeof-array"] = (SW, "sizeof of an array of 3: 24 (gcc 12)")
# compound assignment
cls["ca-01-ctl"] = (C, ""); cls["cb-01-rhs-call-once"] = (C, "a side effect in the RIGHT operand is evaluated once"); cls["cb-06-plain-eq-postinc-ctl"] = (C, "plain `=` is fine"); cls["cb-07-postinc-on-lvalue-ctl"] = (C, "`++` on the same lvalue is fine")
cls["ca-02-idx-postinc"] = (SW, "false UB035: `a[i++] += 5` is defined (6.5.16#3: one modification of `i`); the elaboration evaluates `a[i++]` twice")
cls["ca-03-ptr-postinc"] = (SW, "false UB035 (`*p++ += 7`)")
cls["ca-04-call-lvalue"] = (SW, "WRONG VALUE: `*g() += 3` calls `g` twice (n = 2 → 23; gcc 13)")
cls["ca-05-shift-postinc"] = (SW, "false UB035 (`<<=`)")
cls["ca-06-member-postinc"] = (SW, "false UB035 (`s[i++].v |= 4`)")
cls["cb-02-lhs-call-index"] = (SW, "WRONG VALUE: `a[g()] += 4` calls `g` twice (24 vs 14)")
cls["cb-03-predec"] = (SW, "false UB035 (`a[--i] += 6`)")
cls["cb-04-ptr-deref-postinc-struct"] = (SW, "false UB035 (`(p++)->v += 5`)")
cls["cb-05-bitfield-postinc"] = (U, "`feature not yet supported: bit-fields` (both engines)")
cls["cb-08-comma-lhs"] = (SW, "false UB035 (comma in the subscript)")
# _Bool from floating
for n in ["bf-01-ctl-int","bf-06-two","bf-07-if","bf-08-not","bf-09-and","bf-10-cond","bf-13-huge-to-bool","bp-05-bool-from-float-var-cmp-ctl","bo-01-ctl","bo-03-300","bo-04-runtime","bo-05-ptr","bo-07-store-256"]:
    cls[n] = (C, "")
for n in ["bf-02-half","bf-03-half-f","bf-04-neg-half","bf-05-tiny","bf-11-cast","bf-12-bool-assign-later","bo-06-float","bp-01-bool-param","bp-02-bool-return","bp-03-bool-struct-init","bp-04-bool-compound"]:
    cls[n] = (SW, "C17 6.3.1.2#1: a value that compares unequal to 0 converts to 1; the engines truncate first (std.core:81-84; tray 15)")
cls["bf-14-huge-to-int-ub"] = (ST, "6.3.1.4#1"); cls["bf-15-neg-to-unsigned-ub"] = (ST, "6.3.1.4#1"); cls["bf-16-uchar-from-300"] = (ST, "6.3.1.4#1 (gcc 44 is the wrapped value)")
cls["bo-02-trap-rep"] = (ST, "6.2.6.1#5: `_Bool` with representation 2 is a trap representation (gcc reads 2)")
# floats
for n in ["fl-01-ctl","fl-04-mem-roundtrip","fl-08-sizeof-mixed-expr","fl-09-generic-mixed","fs-02-flt-mant-dig","fs-05-float-overflow","fs-08-dbl-mant-dig"]:
    cls[n] = (C, "")
cls["fl-02-float-to-double"] = (SW, "`0.1f` must round to binary32 (6.4.4.2#3), so `(double)f == 0.1` is false; engines keep 53 bits. `float.h` says FLT_MANT_DIG 24 (fs-02) — the implementation contradicts its own `<float.h>` (5.2.4.2.2)")
cls["fl-03-float-rounding"] = (SW, "16777217.0f is not representable in binary32")
cls["fl-05-third"] = (SW, "as fl-02")
cls["fl-10-store-via-char"] = (SW, "byte 3 of a `float` object: 0 (gcc 63): the object holds the low 4 bytes of a double pattern in an 8-byte object")
cls["fl-06-longdouble-eps"] = (IMPL, "long double precision is implementation-defined (5.2.4.2.2); x86-64 ABI has 64-bit significand, engines 53 (but `LDBL_MANT_DIG` = 64 in the shipped float.h, fs-08)")
cls["fl-07-sizeof"] = (IMPL, "sizeof(float) = 8, sizeof(long double) = 8 (ocaml_implementation.ml:208/212 `TODO:hack ==> 4` / `==> 16`; tray 32)")
cls["fs-01-sizeof-float"] = (IMPL, "as fl-07"); cls["fs-06-float-array-stride"] = (IMPL, "as fl-07"); cls["fs-07-ldbl-sizeof"] = (IMPL, "as fl-07"); cls["ag-02-alignof-ldbl"] = (IMPL, "_Alignof(long double) 8 (gcc 16)")
cls["fs-03-flt-epsilon"] = (NW, "`use of undeclared identifier 'FLT_EPSILON'`: the shipped float.h lacks it"); cls["fs-04-flt-epsilon-half"] = (NW, "as fs-03")
# wchar
cls["wt-01-ctl-pos"] = (C, ""); cls["wt-04-max"] = (C, ""); cls["wc-02-wchar-literal"] = (C, "")
cls["wt-02-neg-eq"] = (NW, "CRASH both engines: `wchar_t w = -1` is converted with an unsigned range (impl_mem.ml:2449 `max_ival Wchar_t = unsigned_max`) and then stored as signed (`is_signed_ity Wchar_t`, ocaml_implementation.ml:167 `wchar_t_alias = Signed Int_`): `bytes_of_int` assertion")
cls["wt-05-from-unsigned"] = (NW, "as wt-02"); cls["wc-01-wchar-signed"] = (NW, "as wt-02")
cls["wt-03-wide-string"] = (NW, "`wchar_t ws[] = L\"ab\"` rejected as a constraint violation (the string-literal-subobject path, tray 23 adjacent)")
cls["wt-06-sizeof-signedness"] = (IMPL, "`(wchar_t)-1 < 0` = 0 (gcc 1): signedness of wchar_t is implementation-defined (7.19#2), but this contradicts the implementation's own alias (signed int) — the crash above is the consequence")
cls["wt-07-char16"] = (U, "parser: `unexpected token after 'char16_t'` (uchar.h types not in the grammar)")
# string literal subobjects
cls["cs-01-ctl"] = (C, ""); cls["cs-02-no-room-for-nul"] = (C, "6.7.9#14"); cls["cs-03-concat"] = (C, ""); cls["cs-04-braced-string"] = (C, ""); cls["sl-10-ptr-member-ctl"] = (C, "pointer member: fine")
for n in ["cs-05-struct-member-string","sl-01-desig","sl-02-braced-member","sl-03-array-of-struct","sl-04-char-matrix","sl-05-char-matrix-braced","sl-06-nested-struct","sl-07-static","sl-08-exact-fit","sl-09-second-member","sl-11-compound-literal","ax-08-single-member-struct-string"]:
    cls[n] = (NW, "valid C (6.7.9#14 via #17-#20) rejected: `constraint violation: initializing 'char' with an expression with a non arithmetic type 'char*'` on both engines (desugaring_init.lem:461-462 stub; tray 23)")
# statement expressions
for n in ["se-01-basic","se-03-void","se-04-min-macro","sx-02-call-stmt","sx-03-decl-from-call","sx-08-in-loop"]:
    cls[n] = (C, "GNU extension served")
for n in ["se-02-side-effect","sx-01-assign-stmt","sx-04-if-inside","sx-05-postinc-stmt","sx-06-postinc-not-first","sx-07-stmt-expr-as-statement"]:
    cls[n] = (NW, "CRASH both engines `internal error: break_at_sseq, Cbound` (core_reduction.lem; failure register row 183) when the block contains an assignment, `++` or `if` statement")
# chars
cls["ch-02-char-377-sign"] = (C, ""); cls["ch-04-utf8-sizeof"] = (C, ""); cls["ch-05-escape-x-ff"] = (C, ""); cls["ch-06-plain-char-200"] = (C, ""); cls["ch-07-u8-literal"] = (C, "")
cls["ch-01-multichar"] = (NW, "CRASH both engines `decode_character_constant: invalid char constant ==> ab` (decode.ml:218; multi-character constants are implementation-defined, 6.4.4.4#10)")
cls["ch-03-utf8-byte"] = (NW, "CRASH both engines on a UTF-8 byte in a string literal (decode.ml:42/224 ASCII-only)")
# enums
for n in ["en-01-ctl","en-03-sizeof","en-04-negative","en-05-underlying-unsigned"]: cls[n] = (C, "")
cls["en-02-big-enumerator"] = (C, "rejected `constraint violation: integer constant not in the range of the representable values for its type` (6.7.2.2#2 / 6.6#4); gcc accepts as an extension")
cls["en-06-long-enumerator"] = (C, "as en-02")
# size_t etc
for n in [f"st-0{i}" for i in range(1,10)]:
    for k in rows:
        if k.startswith(n): cls[k] = (C, "")
# designators, tentative, goto, sizeof, shifts, static init, misc
for p in ["di-","td-","go-","sz-","tq-","at-","pr-01","ag-01","ag-03","ag-04","va-01","va-02","va-03","np-01","np-02","fp-01","fp-02","ra-01","ov-02","nl-01","sh-03","sh-04","si-02","si-04","si-05","si-06","si-07","zp-04","pf-01","pf-02","pf-03","pf-08"]:
    for k in rows:
        if k.startswith(p) and k not in cls: cls[k] = (C, "")
cls["td-09-array-never-completed"] = ("INVALID PROBE", "gcc rejects it too (sizeof of an incomplete array)")
cls["nl-01-offsetof-idiom"] = (LEN, "`&((struct S*)0)->b` served (impl_mem.ml:2293: 'gcc-torture assumes the following behaviour'); strictly 6.5.3.2/6.5.6 UB")
cls["nl-02-null-plus-zero"] = (NW, "CRASH both engines `TODO(pure shift a null pointer should be undefined behaviour), offset:0` (impl_mem.ml:2277; tray 04); 6.5.6#8 makes it UB, so a UB verdict would be the right loud outcome")
cls["nl-03-null-index"] = (NW, "as nl-02 (offset 4)")
cls["np-03-char-param-ub"] = (LEN, "gcc rejects (6.7.6.3#15: `int f()` then `int f(char)` incompatible); engines accept and answer 97")
cls["np-04-kr-def"] = (U, "`found K&R-style declaration (unsupported)`")
cls["va-04-wrong-type-ub"] = (ST, "7.16.1.1#2: va_arg with an incompatible type is UB (reported as out-of-bound load)")
for n in ["vl-01-ctl","vl-02-sizeof-vla","vl-03-sizeof-vla-side-effect","vl-04-sizeof-vla-type-side-effect"]:
    cls[n] = (U, "`feature not yet supported: variable length array type`")
for n in ["zp-01-scalar-ptr-dead","zp-02-struct-member-ptr-dead","zp-03-array-elem-ptr-dead"]:
    cls[n] = (LEN, "reading a pointer to a dead object (6.2.4#2 indeterminate) answers 0 as gcc does; pointer zapping is off in the default switch set (impl_mem.ml:1495-1515 only runs under its switch)")
cls["ov-01-inexact-overlap"] = (LEN, "6.5.16.1#3 inexact overlap is UB; both engines answer 43 like gcc (translation.lem:2408 Debug.warn)")
cls["ra-02-temp-ptr-after"] = (ST, "6.2.4#8: the temporary's lifetime ends at the full expression; gcc happens to print 3")
cls["fp-03-via-long"] = ("NAMED DEVIATION N1", "function-pointer numbers (CONTRACT)")
cls["pr-02-ushort-mul-overflow"] = (ST, "6.5#5 after promotion to int")
for n in ["sh-01-ub-amount","sh-02-neg-amount","sh-05-left-neg-ub","sh-06-left-overflow-ub","sh-07-ulong-64","sh-08-ushort-promote-ub"]:
    cls[n] = (ST, "6.5.7#3/#4")
cls["si-01-nonconst-cv"] = (C, "rejected as gcc does (6.7.9#4)"); cls["si-08-local-static-nonconst"] = (C, "rejected as gcc does")
cls["si-03-cast-addr"] = (C, "`(long)&x` accepted by both and by gcc (6.6#10 permits other forms)")
cls["si-09-string-ptr-arith"] = (NW, "`\"abc\" + 1` is an address constant (6.6#9); rejected `initializer element is not a compile-time constant` (tray 29)")
cls["si-10-cond-const"] = (UNC, "`1 ? 4 : (1/0)` rejected (tray 28; 6.6#3 lists the operators excused in unevaluated subexpressions, division by zero is not among them — gcc and clang accept)")
cls["pf-04-flags"] = (UNC, "UB153b for `%#x`/`%#o` with `int` arguments (tray 27); 7.21.6.1#9 vs the 7.16.1.1#2 signed/unsigned exception")
cls["pf-05-neg-precision"] = (NW, "CRASH both engines `TODO: Formatted.convert, * prec` (tray 26)")
cls["pf-06-u-with-negative"] = (ST, "7.21.6.1#9 / 7.16.1.1#2: -1 is not representable as unsigned"); cls["pf-07-lu-int-arg-ub"] = (ST, "7.21.6.1#9")
cls["pf-09-pct-n"] = (NW, "CRASH both engines `WIP: Formatted.convert, CS_n` (formatted.lem:726)")
cls["pf-10-zero-flag-string"] = (ST, "7.21.6.1#6: the 0 flag with `s` is UB")


GROUPS = [("A anonymous struct/union members", ["an-","un-","au-","ax-","ac-"]), ("B compound assignment", ["ca-","cb-"]),
  ("C _Bool from floating", ["bf-","bo-","bp-"]), ("D floating types", ["fl-","fs-"]), ("E wchar_t", ["wc-","wt-"]),
  ("F string-literal subobjects", ["cs-","sl-"]), ("G constant expressions", ["si-"]), ("H designators", ["di-"]),
  ("I tentative definitions", ["td-"]), ("J enumerators", ["en-"]), ("K size_t / ranks", ["st-"]),
  ("L variadics / prototypes / VLAs", ["va-","np-","vl-"]), ("M null-pointer shifts", ["nl-"]), ("N pointer zapping", ["zp-"]),
  ("O overlapping assignment / temporaries", ["ov-","ra-"]), ("P statement expressions", ["se-","sx-"]),
  ("Q character decoding", ["ch-"]), ("R printf", ["pf-"]), ("S shifts / promotions", ["sh-","pr-"]),
  ("T misc (function pointers, atomics, alignment, sizeof, qualifiers, labels)", ["fp-","at-","ag-","sz-","tq-","go-"])]
cnt = collections.Counter(cls[n][0] for n in rows if n in cls)
print("## Tally (derived)\n\n| classification | probes |\n|---|---|")
for k, v in sorted(cnt.items(), key=lambda kv: -kv[1]): print(f"| {k} | {v} |")
missing = [n for n in rows if n not in cls]
print(f"\n({len(rows)} probes; unclassified: {missing})\n")
for title, prefixes in GROUPS:
    if not any(n.startswith(p) for n in rows for p in prefixes): continue
    print(f"### {title}\n"); print(table(prefixes, cls)); print()
