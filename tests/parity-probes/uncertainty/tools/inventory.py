#!/usr/bin/env python3
"""inventory.py — the uncertainty-marker inventory of the survey record
lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md.

Greps the shared Lem, the hand-written OCaml, std.core and the Lean seams for uncertainty markers, classifies
every hit (a) NOISY / (b) SILENT / (c) DEAD-or-out-of-scope by the rule stated in the record, applies the
survey's hand overrides (the OV dictionary, dated 2026-10-20; line numbers are those of mainline 3ac3ff336 and
will drift), and writes <out>/inventory.csv and <out>/appendix_b.md (the full class-(b) list).
usage: python3 -I tests/parity-probes/uncertainty/tools/inventory.py [--out DIR]   (from anywhere; DIR default .tmp/uncertainty-inventory)
"""
import re, sys, csv, os, glob, collections
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
OUT = os.path.join(ROOT, ".tmp", "uncertainty-inventory")
if len(sys.argv) >= 3 and sys.argv[1] == "--out": OUT = os.path.abspath(sys.argv[2])
os.makedirs(OUT, exist_ok=True)
PAT = re.compile(r"TODO|FIXME|XXX|HACK|\bWIP\b|WRONG|BROKEN|[Cc]heck that|KAYVAN|[Tt]his may be|[Nn]ot sure|hackish|[Uu]nsound|[Ss]hould be|[Ss]hould probably|[Ii]s this (right|correct|ok)|dubious|[Nn]ot correct|[Ii]ncorrect|HELP|[Cc]an this happen|[Ww]hat if|[Nn]ot right|[Qq]uestionable|[Pp]robably wrong")
FILES = (sorted(glob.glob("frontend/model/*.lem", root_dir=ROOT)) + sorted(glob.glob("frontend/model/ail/*.lem", root_dir=ROOT))
         + ["memory/concrete/impl_mem.ml"] + sorted(glob.glob("ocaml_frontend/*.ml", root_dir=ROOT))
         + sorted(glob.glob("ocaml_frontend/pprinters/*.ml", root_dir=ROOT)) + sorted(glob.glob("ocaml_frontend/rewriters/*.ml", root_dir=ROOT))
         + sorted(glob.glob("util/*.ml", root_dir=ROOT)) + sorted(glob.glob("util/*.c", root_dir=ROOT)) + ["backend/driver/main.ml"]
         + ["runtime/libcore/std.core"] + sorted(glob.glob("lean_frontend/*.lean", root_dir=ROOT)))
rows = []
for f in FILES:
    with open(os.path.join(ROOT, f), encoding="utf-8", errors="replace") as fh:
        for ln, line in enumerate(fh, 1):
            if PAT.search(line): rows.append((f, ln, line.rstrip("\n").strip()))
# ---- out-of-scope files (c): dead/unused modules, non-concrete models, pretty-printers, proofs, rewriters not in the compared pipeline
OOS_FILE=re.compile(r"(defacto_memory|/cn\.lem|cn_desugaring|core_indet|core_unstruct|core_rewrite|core_sequentialise|core_run_effect|core_linking|cmm_aux|memory_order|/std\.lem|errors\.lem|undefined\.lem|constraint\.lem|exception|state_exception|state\.lem|product\.lem|symbol\.lem|utils\.lem|debug\.lem|annot\.lem|boot\.lem|dlist|bimap|multiset|/pp\.lem|/any\.lem|builtins\.lem|cabs\.lem|core\.lem$|core_typing_aux|errorMonad|genTypes\.lem|genTypesAux|ailWf|ailSyntax\.lem|ailSyntaxAux|pprinters/|smt2\.ml|core_peval|core_rewriter|core_remove_unused|milicore|fork_renumber|memory_model\.ml|memory_utils|ail_analysis|cerb_colour|cerb_location|cerb_pp_prelude|cerb_runtime|cerb_util|cerb_fresh|cerb_debug|cerb_any|cerberus_cstubs|_lemMeasureProofs|CerbCoreMeasure|CerbMemAccessFacts|CerbMemAllocatorProofs|CerbMeasureLemmas|CerbCtypeMeasure|CerbCoreShape|CerbParserProgress|CerbFunMapInstances|CerbStepInstances|CerbTagsWf|CerbFuel|CerbND\.lean|CerbNDFuelProofs|CerbDebug|CerbPP|CerbLocation|CerberusFresh|CerbDecode|CerbFS|CerbGlobal|CerbCall|CerbUtils|CabsImport|CoreParser|Main\.lean|CerbFloat)")
# implementation.lem: all hits are enumerations of unmodelled impl-def items or 'don't care' notes (no executed arm) -> c
OOS_FILE2=re.compile(r"implementation\.lem")
NOISY=re.compile(r'\berror\s*[("]|\berror\s*\(|failwith|E\.fail\b|\bfail\s+(~?loc|\()|assert_false|assert false|assert \(|internal_error|DInit_internal_error|illTypedAil|CoreTyping_TODO|Desugar_TODO|Desugar_NotYetSupported|failwithI|failStop|constraint_violation|E\.undef\b|Boot\.assert_false|undef\(|record_error_at|Illformed_program|MerrWIP|MerrOther|refused|unsupported\)')
HOUSE=re.compile(r"efficien|factori|rename|documentation|\bmove\b|\bclean\b|\bdoc\b|get rid|yuck|ugly|tasteless|newLem|HOL hack|renaming|codegen|DEBUG|debug|print more|memoise|disgusting|russian doll|too slow|Lem is|Lem's|signatures|PRESENT BETTER|ARRRGG|don't care|will probably never|functors|bring back|out of date|misnamed|I don't like|idiotic|horrible\.\.\.|when-patterns|type-classes|too large|lack of sync|smaller type|uber|quick'n'dirty|readable|bad name|unknown quote|find quote|find the text|TODO\(msg\)|TODO msg|proper error message|error message|error msg|better implementation|stupid|silly|fishy|associative|unused|UNUSED|dead code|DEAD CODE|impossible|should be impossible|should not be possible|this is for the parsing|TODO:HACKHACK|add location|loc \*\)|preserve locations|change the sym|TODO \*\)$|TODO$|\(\* TODO \*\)|TODOS|TODO\(V\)|impossible to write|dependent types|nat \*\)")
CONC=re.compile(r"concurren|thread|sb_stack|negatives|\bRMW\b|SeqRMW|Fence|Linux|CHERI|PNVI|iota|Prov_symbolic|\bVIP\b|\bUI\b|Charon|BMC|smt|Step_fs|m_fs_step|fs_st|Epar|par\(\)|Ewait|Easeq|with_address|cerb::|interactive|Step_nd|Step_aseq|CONCURRENCY|concurRead|TSK_Misc|positive|asw|Cn\b|CN |memory_order|bitfield|bit-field|VLA|vla|wchar_t, char16_t|K&R|FW_asterisk|CS_n|Device|device")
out=[]
for f,ln,txt in rows:
    cls="b"; why=""
    if OOS_FILE.search(f): cls="c"; why="file out of the compared pipeline / no semantic content"
    elif OOS_FILE2.search(f): cls="c"; why="implementation.lem: catalogue of unmodelled impl-def items; no executed arm"
    elif NOISY.search(txt): cls="a"; why="fails/aborts at the site"
    elif CONC.search(txt): cls="c"; why="concurrency/CHERI/PNVI/fs/refused-feature path"
    elif HOUSE.search(txt): cls="c"; why="housekeeping remark, no semantic content"
    out.append([f,ln,cls,why,txt[:140]])
# manual overrides: sites examined by hand
OV={
 ("frontend/model/cabs_to_ail.lem",144):("b","anonymous struct/union member paths (print_debug level 2, proceeds) — PROBED: anonymous members are FLATTENED into the containing struct (:2714-2719): SILENT WRONG"),
 ("frontend/model/cabs_to_ail.lem",166):("b","as :144 (Union)"),("frontend/model/cabs_to_ail.lem",194):("b","as :144"),("frontend/model/cabs_to_ail.lem",207):("b","as :144 (Union)"),("frontend/model/cabs_to_ail.lem",336):("b","cardinalityOfCtype anonymous Struct — as :144"),
 ("frontend/model/cabs_to_ail.lem",509):("b","constructValue_aux anonymous Struct (legacy path; live copy desugaring_init.lem:572)"),("frontend/model/cabs_to_ail.lem",526):("b","constructValue_aux anonymous Union (legacy; live copy desugaring_init.lem:588)"),
 ("frontend/model/cabs_to_ail.lem",529):("b","union initializer built as first member (legacy copy; live desugaring_init.lem:576/592) — separate slice in progress"),
 ("frontend/model/cabs_to_ail.lem",671):("c","sizeof of a VLA expression — VLAs are refused up front (`feature not yet supported: variable length array type`, probe vl-01)"),
 ("frontend/model/cabs_to_ail.lem",730):("a","dead ?: branch must be constant: E.fail (NOISY WRONG per tray 28; probe si-10 rejected `1 ? 4 : (1/0)`)"),("frontend/model/cabs_to_ail.lem",740):("a","as :730"),
 ("frontend/model/cabs_to_ail.lem",791):("b","is_arithmetic_constant_expression 'super partial and hackish' — PROBED si-01..si-10: rejects valid `\"abc\"+1` (tray 29) and `?:` (tray 28); accepts `(long)&x` (6.6#10 permits)"),
 ("frontend/model/cabs_to_ail.lem",792):("b","as :791"),("frontend/model/cabs_to_ail.lem",815):("b","as :791 (enumerations accepted — correct, 6.6#6)"),("frontend/model/cabs_to_ail.lem",830):("b","as :791 (sizeof: constant unless VLA — VLAs refused)"),("frontend/model/cabs_to_ail.lem",840):("b","as :791"),("frontend/model/cabs_to_ail.lem",860):("b","as :791"),("frontend/model/cabs_to_ail.lem",862):("b","as :791"),("frontend/model/cabs_to_ail.lem",865):("b","as :791"),("frontend/model/cabs_to_ail.lem",868):("b","as :791"),("frontend/model/cabs_to_ail.lem",871):("b","as :791"),("frontend/model/cabs_to_ail.lem",895):("b","is_null_pointer_constant as address-constant predicate — PROBED si-02 ok"),("frontend/model/cabs_to_ail.lem",936):("b","as :791"),
 ("frontend/model/cabs_to_ail.lem",1446):("b","6.7.3#5 duplicate qualifier via typedef — PROBED tq-01/tq-02 CORRECT"),
 ("frontend/model/cabs_to_ail.lem",1765):("b","typeof: type fixed by evaluator integer implementation — not probed"),
 ("frontend/model/cabs_to_ail.lem",1798):("a","enumerator range vs signed int: the else-branch skips the check BUT 6.6#4 range check rejects (probe en-02/en-06: constraint violation) — NOISY, correct"),
 ("frontend/model/cabs_to_ail.lem",1862):("b","array parameter adjustment (inner arrays) — not probed"),
 ("frontend/model/cabs_to_ail.lem",2027):("b","function returning function/array not rejected here (Ail typing catches it) — benign"),("frontend/model/cabs_to_ail.lem",2087):("b","as :2027"),
 ("frontend/model/cabs_to_ail.lem",2165):("a","UB086 vs constraint for incomplete adjusted parameter — reports UB (loud)"),
 ("frontend/model/cabs_to_ail.lem",2770):("b","enumerator evaluated at type signed int (6.7.2.2#2 requires int-representable; out of range rejected en-02) — CORRECT"),("frontend/model/cabs_to_ail.lem",2808):("b","as :2770 (case labels)"),
 ("frontend/model/cabs_to_ail.lem",2945):("b","_Alignas in a type-name ignored — PROBED ag-04 `sizeof((_Alignas(16) int){1})` = 4 both (same as gcc)"),
 ("frontend/model/cabs_to_ail.lem",3129):("b","designator backward skip fills zero-init (hackish) — PROBED di-01..di-08 all CORRECT"),("frontend/model/cabs_to_ail.lem",3141):("b","as :3129"),
 ("frontend/model/cabs_to_ail.lem",3159):("b","null-pointer-constant detection without Ail typing — not probed"),
 ("frontend/model/cabs_to_ail.lem",3173):("a","string literal for non-char-array cursor → constraint violation: this is the tray-23 NOISY WRONG (probes cs-05, sl-01..09, sl-11, ax-08)"),
 ("frontend/model/cabs_to_ail.lem",3184):("b","string-literal pieces concatenated ignoring encoding prefixes — PROBED cs-03 CORRECT (no prefix); prefixed pieces error (:3193)"),
 ("frontend/model/cabs_to_ail.lem",3428):("b","integer initializer constant evaluation disabled — benign (expression kept)"),("frontend/model/cabs_to_ail.lem",3438):("b","as :3428"),
 ("frontend/model/cabs_to_ail.lem",3451):("a","KAYVAN CHECK dead-code arm: E.undef UB083 (loud if reached)"),
 ("frontend/model/cabs_to_ail.lem",3499):("b","char-array string init — PROBED cs-01..cs-04 CORRECT at top level"),
 ("frontend/model/cabs_to_ail.lem",3509):("b","print_debugM 2: aggregate initialised by a non-list initializer — PROBED (struct = expr) correct by 6.7.9#13"),("frontend/model/cabs_to_ail.lem",3513):("b","as :3509"),
 ("frontend/model/cabs_to_ail.lem",3636):("b","register_external_object_declaration flag false — not probed"),
 ("frontend/model/cabs_to_ail.lem",3650):("b","tentative definitions: type update — PROBED td-01..td-08 CORRECT"),("frontend/model/cabs_to_ail.lem",3937):("b","as :3650"),("frontend/model/cabs_to_ail.lem",4901):("b","as :3650"),
 ("frontend/model/cabs_to_ail.lem",4932):("a","tentative internal-linkage incomplete → UB089 (6.9.2#3 is a constraint; verdict class differs but loud)"),("frontend/model/cabs_to_ail.lem",4938):("c","thread storage duration (unsupported, errors at :3664)"),
 ("frontend/model/cabs_to_ail.lem",2714):("b","(no marker; root of the anonymous-member finding) members of an anonymous struct/union are spliced into the containing aggregate"),
 ("frontend/model/translation.lem",53):("b","floating_conversion_TODO: casts between floating types are NOPs — PROBED fl-02/03/05 SILENT WRONG vs float.h (tray 32)"),
 ("frontend/model/translation.lem",1423):("b","usual arithmetic conversions: all real floating types computed as OCaml double — as :53"),
 ("frontend/model/translation.lem",864):("b","has_proto ignored (6.5.2.2#6) — PROBED np-01/np-02 CORRECT; np-03 accepts a 6.7.6.3#15-incompatible redeclaration (lenient on ill-formed input)"),
 ("frontend/model/translation.lem",2325):("a","GNU ?: → record_error_at (loud)"),
 ("frontend/model/translation.lem",2408):("b","non-exact overlapping assignment UB (6.5.16.1#3) not modelled — PROBED ov-01: both engines answer 43 (lenient; upstream-declared)"),
 ("frontend/model/translation.lem",2511):("b","compound assignment elaborated with e1 duplicated — PROBED ca-02..06, cb-02..04, cb-08: SILENT WRONG (false UB035 or doubled side effect)"),("frontend/model/translation.lem",2512):("b","as :2511"),
 ("frontend/model/translation.lem",2949):("a","UB043 reused for member access through an invalid pointer (loud)"),
 ("frontend/model/translation.lem",3193):("b","rvalue array member temporary allocated for the full expression — PROBED ra-01 CORRECT, ra-02 UB043 (correct, 6.2.4#8)"),("frontend/model/translation.lem",3194):("b","as :3193"),
 ("frontend/model/translation.lem",4023):("b","switch: visible labels after case — PROBED go-01..go-03 CORRECT"),
 ("frontend/model/translation_aux.lem",58):("c","promote_value is dead (no callers)"),("frontend/model/translation_aux.lem",399):("b","floating→floating conversion is identity — as translation.lem:53"),("frontend/model/translation_aux.lem",433):("b","as :399"),
 ("frontend/model/translation_aux.lem",414):("b","Debug.warn: elaboration wrong for atomic types (sequential) — PROBED at-01/at-02 CORRECT"),
 ("frontend/model/ail/ailTypesAux.lem",456):("b","integer rank equality — PROBED st-09 `_Generic(1L+1LL)` CORRECT"),("frontend/model/ail/ailTypesAux.lem",529):("b","rank comparison for macro types — not probed"),
 ("frontend/model/ail/ailTypesAux.lem",596):("b","size_t not an alias of unsigned long (tray 20) — PROBED st-02..st-08 CORRECT (compatibility and _Generic agree with gcc)"),("frontend/model/ail/ailTypesAux.lem",599):("b","as :596"),("frontend/model/ail/ailTypesAux.lem",602):("b","as :596"),("frontend/model/ail/ailTypesAux.lem",676):("b","Debug.warn NON STD: size_t common type — as :596"),("frontend/model/ail/ailTypesAux.lem",727):("b","as :596"),
 ("frontend/model/ail/ailTypesAux.lem",734):("b","usual_arithmetic_floating returns ty1 — PROBED fl-08/fl-09 CORRECT (sizeof/_Generic of float+double is double)"),
 ("frontend/model/ail/ailTypesAux.lem",1193):("c","is_vla BOGUS (always false) — VLAs are refused before typing (vl-01..04)"),
 ("frontend/model/ail/genTyping.lem",234):("b","sub_qualifiers sees wrong qualifiers in assignment typing (print_debug 2) — not probed"),
 ("frontend/model/ail/genTyping.lem",467):("a","multi-character constants: decode crashes (ch-01 `'ab'`, ch-03 UTF-8) — NOISY"),
 ("frontend/model/ail/genTyping.lem",666):("c","& of a bit-field member — bit-fields are refused (cb-05)"),("frontend/model/ail/genTyping.lem",1523):("c","sizeof bit-field — refused"),
 ("frontend/model/ail/genTyping.lem",838):("b","INT32_MIN etc typed signed int — not probed"),("frontend/model/ail/genTyping.lem",846):("b","as :838"),("frontend/model/ail/genTyping.lem",854):("b","as :838"),
 ("frontend/model/ail/genTyping.lem",1095):("c","atomic_thread_fence typing (concurrency)"),("frontend/model/ail/genTyping.lem",1097):("c","as :1095"),
 ("frontend/model/ail/genTyping.lem",1426):("b","void-pointer arithmetic only in permissive mode — standard-correct rejection"),
 ("frontend/model/ail/genTyping.lem",1657):("b","va_start argument type unchecked — not probed"),("frontend/model/ail/genTyping.lem",1674):("b","va_arg argument type unchecked — not probed"),
 ("frontend/model/ail/genTyping.lem",1966):("b","variadic extra arguments: default argument promotion — PROBED va-02/va-03 CORRECT (promotion happens in the elaboration)"),
 ("frontend/model/ail/genTyping.lem",2111):("b","array definition size check n1 >= n2 — PROBED cs-02 `char s[3] = \"abc\"` CORRECT"),
 ("memory/concrete/impl_mem.ml",307):("b","floating_value = OCaml float for all three types — see translation.lem:53"),
 ("memory/concrete/impl_mem.ml",1032):("b","pointer repr assumed unsigned (print_debug 1) — x86-64 correct"),
 ("memory/concrete/impl_mem.ml",1044):("b","FIXME funptrmap keyed by number across files (tray 48 adjacent) — not probed (needs multi-TU)"),("memory/concrete/impl_mem.ml",1880):("b","as :1044"),
 ("memory/concrete/impl_mem.ml",1095):("b","atomic repr = non-atomic repr — x86-64 correct"),
 ("memory/concrete/impl_mem.ml",1111):("c","zap hack for unions — zapping is off in the default switch set (zp-01..03: no zap)"),("memory/concrete/impl_mem.ml",1501):("c","zap for dynamic allocations — as :1111"),("memory/concrete/impl_mem.ml",1513):("c","as :1111"),
 ("memory/concrete/impl_mem.ml",1189):("b","float repr signed flag — benign"),
 ("memory/concrete/impl_mem.ml",1531):("b","kill of a Prov_device pointer is a no-op — not probed (needs libc free)"),
 ("memory/concrete/impl_mem.ml",1954):("c","one-past case under SW_strict_pointer_relationals (switch refused)"),("memory/concrete/impl_mem.ml",1972):("c","as :1954"),("memory/concrete/impl_mem.ml",1988):("c","as :1954"),("memory/concrete/impl_mem.ml",2005):("c","as :1954"),
 ("memory/concrete/impl_mem.ml",2225):("b","integer→pointer in device_ranges yields a device pointer without provenance check — upstream Charon ranges; not probed"),
 ("memory/concrete/impl_mem.ml",2275):("a","pure shift of a null pointer: failwith (probes nl-02/nl-03 both engines die, same text; tray 04)"),("memory/concrete/impl_mem.ml",2277):("a","as :2275"),
 ("memory/concrete/impl_mem.ml",2293):("b","member shift on a null pointer served (offsetof idiom) — PROBED nl-01 CORRECT (gcc 4); strictly UB in ISO, deliberate upstream reading"),
 ("memory/concrete/impl_mem.ml",2309):("a","eff shift of a null pointer → MerrArrayShift (UB verdict, loud)"),("memory/concrete/impl_mem.ml",2311):("a","as :2309"),
 ("memory/concrete/impl_mem.ml",2324):("b","lvalue_ty for eff shift precondition (PNVI/strict only)"),("memory/concrete/impl_mem.ml",2395):("b","as :2324"),
 ("memory/concrete/impl_mem.ml",2446):("b","_Bool max 255 — unreachable for conversions (std.core conv_int special-cases _Bool; bo-01..07 CORRECT)"),
 ("memory/concrete/impl_mem.ml",2449):("b","wchar_t treated unsigned in max_ival while ocaml_implementation.ml:167 aliases it to signed int — PROBED wt-02/wt-05/wc-01: both engines CRASH (assert in bytes_of_int); wt-06 `(wchar_t)-1 < 0` = 0 vs gcc 1"),("memory/concrete/impl_mem.ml",2479):("b","as :2449"),
 ("memory/concrete/impl_mem.ml",2453):("b","wint_t signedness — not probed"),
 ("memory/concrete/impl_mem.ml",2549):("a","IntExp with a huge exponent: Z.to_int raises (loud); shift amounts are range-checked earlier (sh-01/sh-07 UB51b)"),
 ("memory/concrete/impl_mem.ml",2559):("b","bitwise complement provenance — benign"),
 ("memory/concrete/impl_mem.ml",2834):("b","va_arg type compatibility unchecked (tray 05) — PROBED va-04: out-of-bound load UB (loud) for a wider type"),
 ("memory/concrete/impl_mem.ml",2864):("a","assert (n = 0) (loud)"),
 ("memory/concrete/impl_mem.ml",151):("b","array size multiplication overflow — unreachable at sane sizes"),
 ("runtime/libcore/std.core",72):("b","fvfromint out-of-range UB not modelled (6.3.1.4#2) — not probed"),
 ("runtime/libcore/std.core",78):("b","ivfromfloat non-finite values — tray 15 notes a crash; not probed"),
 ("runtime/libcore/std.core",101):("b","pointer→_Bool of an unspecified pointer — benign"),
 ("runtime/libcore/std.core",137):("b","encodeTwos assumes no padding bits — LP64 correct"),("runtime/libcore/std.core",149):("b","as :137"),
 ("runtime/libcore/std.core",231):("c","commented-out hack"),
 ("runtime/libcore/std.core",602):("c","open(): filesystem refused (D2)"),("runtime/libcore/std.core",670):("c","lseek: refused (D2)"),("runtime/libcore/std.core",684):("c","refused (D2)"),("runtime/libcore/std.core",770):("c","refused (D2)"),
 ("runtime/libcore/std.core",83):("b","(no marker) _Bool from floating: §6.3.1.2#1 test applied to the truncated integer — PROBED bf-02..05/11/12 SILENT WRONG (tray 15)"),
 ("frontend/model/core_eval.lem",76):("b","signed conv_int of a non-representable value wraps (tray 36; 6.3.1.3#3 impl-def; matches gcc)"),
 ("frontend/model/core_eval.lem",289):("b","PEif wrapping — benign"),("frontend/model/core_eval.lem",867):("b","flexible array member in PEstruct — not probed"),("frontend/model/core_eval.lem",924):("b","function pointer cast via void* — PROBED fp-01 CORRECT"),
 ("frontend/model/core_run.lem",1014):("b","as core_eval.lem:924"),("frontend/model/core_reduction.lem",1412):("b","as core_eval.lem:924"),
 ("frontend/model/core_aux.lem",170):("b","unspecified value type check skipped — benign"),("frontend/model/core_aux.lem",183):("b","pointer object value — benign"),("frontend/model/core_aux.lem",188):("b","array value size check skipped — benign"),
 ("frontend/model/core_aux.lem",2017):("c","old collect_labeled_continuations is dead (driver uses _NEW)"),
 ("frontend/model/core_run.lem",1439):("c","Debug.warn on every Ewseq: negatives (concurrency)"),("frontend/model/core_run.lem",1487):("c","as :1439"),
 ("frontend/model/driver.lem",237):("c","read() buffer store — filesystem refused (D2)"),("frontend/model/driver.lem",1664):("b","ASCII impl choice for argv — benign"),("frontend/model/driver.lem",1777):("b","as :1664"),
 ("frontend/model/formatted.lem",204):("b","printf: 'not doing the right thing' — PROBED pf-01..pf-10: %hhd/%c/%s precision/%+d/%05d/%hd agree with gcc; %#x with int arg UB153b (tray 27); %.*d negative crash (tray 26); %n crash"),
 ("frontend/model/formatted.lem",580):("b","printf conversions of n as unsigned int — PROBED pf-01/pf-06 CORRECT"),("frontend/model/formatted.lem",588):("b","as :580"),("frontend/model/formatted.lem",596):("b","as :580"),("frontend/model/formatted.lem",604):("b","as :580"),
 ("frontend/model/formatted.lem",509):("b","printf wrong if not integer — not probed"),("frontend/model/formatted.lem",806):("b","%c maybe unsigned char — PROBED pf-02 CORRECT"),("frontend/model/formatted.lem",829):("b","snprintf overlap UB — not probed"),
 ("frontend/model/desugaring_init.lem",462):("a","string literal for an array ELEMENT/MEMBER stubbed: internal_error 'TODO: explode the elements' (tray 23; probes sl-*)"),
 ("frontend/model/desugaring_init.lem",572):("b","constructValue_aux anonymous Struct — flattened, see cabs_to_ail.lem:2714"),("frontend/model/desugaring_init.lem",576):("b","union: first member only (separate slice)"),("frontend/model/desugaring_init.lem",588):("b","anonymous Union — flattened"),("frontend/model/desugaring_init.lem",592):("b","print_debug 0 'is WRONG for union' (separate slice)"),
 ("frontend/model/desugaring_init.lem",162):("b","overflowing cursor — PROBED di-* CORRECT"),("frontend/model/desugaring_init.lem",333):("b","array designator larger than array: no warning — not probed"),("frontend/model/desugaring_init.lem",515):("b","overflowing on block entry — PROBED di-03/di-07 CORRECT"),("frontend/model/desugaring_init.lem",566):("b","AilEarray flag false — benign (string-literal flag)"),("frontend/model/desugaring_init.lem",602):("b","atomic member init — not probed"),
 ("ocaml_frontend/ocaml_implementation.ml",167):("b","wchar_t_alias = signed int (TODO: check) vs impl_mem.ml:2449 unsigned range — the crash's root"),
 ("ocaml_frontend/ocaml_implementation.ml",208):("b","sizeof(float) = 8 'hack ==> 4' — PROBED fs-01/fs-06/fl-10: 8 (gcc 4) (tray 32)"),("ocaml_frontend/ocaml_implementation.ml",212):("b","sizeof(long double) = 8 'hack ==> 16' — PROBED fs-07 (gcc 16)"),("ocaml_frontend/ocaml_implementation.ml",249):("b","alignof(float) = 8 — as :208"),("ocaml_frontend/ocaml_implementation.ml",253):("b","alignof(long double) = 8 — PROBED ag-02 (gcc 16)"),
 ("ocaml_frontend/decode.ml",42):("a","ASCII-only decoding: multi-char and non-ASCII character constants crash (ch-01, ch-03)"),("ocaml_frontend/decode.ml",224):("a","as :42"),("ocaml_frontend/decode.ml",115):("b","escape decoding — PROBED ch-05 CORRECT"),("ocaml_frontend/decode.ml",119):("b","as :115"),
 ("lean_frontend/CerberusImpl.lean",181):("b","Lean mirror of wchar_t alias (signed int)"),("lean_frontend/CerberusImpl.lean",246):("b","Lean mirror sizeof(float)=8"),("lean_frontend/CerberusImpl.lean",248):("b","Lean mirror sizeof(long double)=8"),("lean_frontend/CerberusImpl.lean",262):("b","mirror alignof"),("lean_frontend/CerberusImpl.lean",264):("b","mirror alignof"),
 ("lean_frontend/CerbMem.lean",1654):("b","Lean mirror of _Bool max 255"),("lean_frontend/CerbMem.lean",2658):("b","Lean mirror of kill Prov_device no-op"),
}

# apply overrides; add the unmarked root sites the survey examined
seen = set((r[0], r[1]) for r in out)
for (f, ln), (c, w) in OV.items():
    if (f, ln) in seen:
        for r in out:
            if r[0] == f and r[1] == ln: r[2] = c; r[3] = w
    else:
        out.append([f, ln, c, w, "(no marker text; added by the survey)"])
out.sort()
with open(os.path.join(OUT, "inventory.csv"), "w", newline="") as fh:
    w = csv.writer(fh); w.writerow(["file", "line", "class", "note", "text"]); w.writerows(out)
b = [r for r in out if r[2] == "b"]
with open(os.path.join(OUT, "appendix_b.md"), "w") as fh:
    fh.write(f"## The full class (b) list ({len(b)} sites; derived from inventory.csv)\n\n")
    cur = None
    for r in b:
        if r[0] != cur:
            cur = r[0]; fh.write(f"\n### {cur}\n\n| line | marker text | note |\n|---|---|---|\n")
        fh.write(f"| {r[1]} | `{r[4][:110].replace('|', chr(92)+'|')}` | {r[3].replace('|', chr(92)+'|')} |\n")
cnt = collections.Counter(r[2] for r in out)
print("TOTAL", len(out), dict(cnt))
byfile = collections.defaultdict(collections.Counter)
for r in out: byfile[r[0]][r[2]] += 1
for f in sorted(byfile, key=lambda k: -sum(byfile[k].values())):
    c = byfile[f]; print(f"{f}: a={c['a']} b={c['b']} c={c['c']}")
print("written:", os.path.join(OUT, "inventory.csv"), os.path.join(OUT, "appendix_b.md"))
