#!/usr/bin/env python3
"""Q3 assignment for the 231 pure exec-closure failure sites (2026-09-07 census).

Input : sites231.tsv (file, line, kernel owner, token, Q1 position, message head,
        closure(drive), closure(consumer fine), closure(consumer step), note)
Output: sites231_classified.tsv with Q3 class + invariant/witness + cite.
Rules are keyed on (module basename, owner suffix, message substring) and are
applied in order; the script FAILS if any site is left unassigned (fail-closed).
Class vocabulary (the record's Q3): UNREACHABLE-BY-INVARIANT | REACHABLE | UNKNOWN.
'kind' names the invariant class: structural (kernel-provable from the Lean
definitions), typing (Ail/Core typing rules), config (the default-configuration
defs of CerbGlobal), model-shape (a driver/memory invariant with no theorem),
dominance (an earlier evaluation of the same scrutinee/guard fires first),
pin (the libc/std.core pins), promotion (C default argument promotion).
"""
import csv, sys
inp, out = sys.argv[1], sys.argv[2]
rows = [l.rstrip('\n').split('\t') for l in open(inp)]
hdr, rows = rows[0], rows[1:]
assert len(rows) == 231, len(rows)

U, R, K = 'UNREACHABLE-BY-INVARIANT', 'REACHABLE', 'UNKNOWN'
def rule(mod=None, owner=None, msg=None, line=None):
    def pred(r):
        f, ln, own, m = r[0].split('/')[-1], int(r[1]), r[2], r[5]
        return (mod is None or f == mod) and (owner is None or own.endswith(owner)) \
            and (msg is None or msg in m) and (line is None or ln == line)
    return pred

RULES = [
 # ---------------- hand-written seams ----------------
 (rule('CerbDecode.lean', line=121), R, 'witness tests/failure-probes/reach/args_backslash.c (--args "a\\b"): both crash; input class HARNESS BOUNDARY (argv byte "\\"); C program well-typed', 'driver.lem prepare_main_args: Decode.decode_character_constant (String.toString [c]); Driver.lean:575'),
 (rule('CerbDecode.lean', line=151), R, 'same route as :121 (the two "invalid char constant" arms share the single-byte input); :121 witnessed', 'CerbDecode.lean:121-151'),
 (rule('CerbDecode.lean', owner='decode_character_constant_aux'), U, 'structural: the only exec-path caller passes a ONE-character string (String.ofList [c]); the \\x / octal / empty arms need ≥2 characters', 'Driver.lean:575 (generated prepare_main_args), CerbDecode.lean:127-146'),
 (rule('CerbDecode.lean', line=41), U, 'no exec-path caller: decode_integer_constant is called only by the desugarer (Cabs_to_ail); it is in the kernel closure through module constants only', 'grep: Driver.lean references CerbDecode.decode_character_constant only'),
 (rule('CerbFS.lean', line=338), R, 'witness tests/tcc/40_stdio.c (CI-sweep LEAN_CRASH row; q2 file): Lean exit 134 PANIC at CerbFS.fs_read CerbFS:338:8, ORACLE SUCCEEDS (exit 0) — class (c) filesystem refusal, declared boundary; input class filesystem boundary', 'q2_recorded_crash_rows.txt tcc-40_stdio'),
 (rule('CerbFS.lean', line=260), R, 'witness tests/freebsd/cat.c: Lean PANIC at CerbFS.fs_close CerbFS:260:4, oracle exit 0 — class (c) refusal (close of fd 1)', 'q2_recorded_crash_rows.txt freebsd-cat'),
 (rule('CerbFS.lean', line=504), R, 'witness tests/suite/fs/stat.c: Lean PANIC at CerbFS.fs_stat CerbFS:504:2, oracle exit 0 — class (c) refusal', 'q2_recorded_crash_rows.txt suite-fs-stat'),
 (rule('CerbFS.lean', line=510), R, 'witness tests/immaculate/libc/zd-z2f04-closedir.c: Lean PANIC at CerbFS.fs_opendir CerbFS:510:2; oracle crashes elsewhere (can_advance) — pinned MATCH | L=CRASH', 'q2_recorded_crash_rows.txt zd-z2f04-closedir'),
 (rule('CerbFS.lean'), R, 'family: class (c) filesystem refusals — each is the unconditional body of its fs_* entry point or a guard on the syscall arguments; reachable by any libc-mode program issuing that syscall shape (4 rows witnessed, this one by construction, unwitnessed); the ORACLE (SibylFS) typically succeeds: a one-sided declared boundary, not a both-crash', 'CerbFS.lean:23-90 header table; VALIDATION.md declared boundary'),
 (rule('CerbFloat.lean', line=307), R, 'witness tests/immaculate/nolibc/zd-z2fl03-nan-to-int.c: both crash (oracle Z.Overflow, Lean PANIC CerbFloat:307); input class UB ((int)NaN, ISO 6.3.1.4p1)', 'q2 file; IMMACULATE_PANICS'),
 (rule('CerbFunMapInstances.lean'), U, 'structural/phantom: the instance is required by initial_driver_state\'s generic fun-map set type; no set operation compares two same-constructor generic_fun_map_decl values; NOT in closure(drive) (FAILURE_CONS column)', 'CerbFunMapInstances.lean header; sites231.tsv closure(drive)=N'),
 (rule('CerbLocation.lean', line=133), U, 'constructor discipline (not a theorem): Loc.regions [] is refused at construction by CabsImport.jsonToLoc (Z2-L-02); outerBbox is called on non-empty region lists', 'typed-failure design §1.1 P-loc; CerbLocation.lean:151,:263 callers'),
 (rule('CerbMem.lean', owner='combineProv'), U, 'config: Prov_symbolic arises only in the symbolic execution mode; the default mode is `none` and is a plain def since 2026-09-05', 'CerbGlobal.lean (current_execution_mode default); docs/2026-09-05_cerbglobal-defs-record.md'),
 (rule('CerbMem.lean', line=330), U, 'structural: LP64 implementation is complete (sizeof_pointer is `some 8`); the `none` arm is dead', 'CerberusImpl.lean sizeof_pointer'),
 (rule('CerbMem.lean', line=415), U, 'typing: offsetof/sizeof require a complete struct type (constraint violation otherwise), and every complete tag is in tagDefs; historical LEAN_CRASH row pr44468.c is MATCH today', 'ail/genTyping.lem:1512-1516; final-reporting-summary.json movement pr44468.c'),
 (rule('CerbMem.lean', owner='sizeofCtype_lemFuel', msg='Void'), U, 'typing: sizeof of an incomplete/function type is a constraint violation (§6.5.3.4#1) rejected by GenTyping', 'ail/genTyping.lem:1512-1516'),
 (rule('CerbMem.lean', owner='sizeofCtype_lemFuel', msg='incomplete array'), U, 'typing: as Void (§6.5.3.4#1)', 'ail/genTyping.lem:1512-1516'),
 (rule('CerbMem.lean', owner='sizeofCtype_lemFuel', msg='function type'), U, 'typing: as Void (§6.5.3.4#1)', 'ail/genTyping.lem:1512-1516'),
 (rule('CerbMem.lean', owner='alignofCtype_lemFuel', msg='Void'), U, 'typing: _Alignof of an incomplete/function type is a constraint violation (§6.5.3.4#1)', 'ail/genTyping.lem:1512-1516 (same rule family)'),
 (rule('CerbMem.lean', owner='alignofCtype_lemFuel', msg='function type'), U, 'typing: as Void', 'ail/genTyping.lem:1512-1516'),
 (rule('CerbMem.lean', line=478), R, 'witness tests/immaculate/nolibc/offsetof-union-member.c: both crash (oracle Failure("Tags definitions must be set…"), Lean PANIC CerbMem:478); input class WELL-TYPED UB-FREE C — a model bug (upstream asymmetry, tray candidate)', 'q2 file; baseline.txt offsetof-union-member MATCH | L=CRASH'),
 (rule('CerbMem.lean', line=531), U, 'model-shape (not a theorem): alignofCtype reads the ambient tagDefs for unions; witness alignof_union_member.c (_Alignof(struct R) with a union member) returned Specified(4) on both engines, so the offsetof asymmetry of :478 does not recur here; a Union0 tag resolving to a StructDef needs tag-kind inconsistency in tagDefs', 'q3_witness_outputs.txt alignof_union_member; CerbMem.lean:526-531'),
 (rule('CerbMem.lean', line=521), U, 'typing/tag-kind consistency (not kernel-checked): a Struct tag in a ctype resolves to a StructDef in tagDefs (desugarer invariant)', 'CerbMem.lean:509-521; typed-failure design §1.1 P-layout'),
 (rule('CerbMem.lean', msg='complete implementation'), U, 'structural (kernel-provable): CerberusImpl.sizeof_ity/sizeof_fty have no `none`-returning arm after normalise_integerType (every arm is `some _` or a panic), so the `none` arms downstream are dead', 'CerberusImpl.lean:170-183'),
 (rule('CerbMem.lean', line=598), K, 'needs a value-representability invariant (stored integer values lie in their type\'s range: Core conv_int/wrapI precede stores) — model-shape, no theorem', 'CerbMem.lean:596-598; core_eval.lem mk_conv_int'),
 (rule('CerbMem.lean', owner='bytesToInt'), U, 'structural: integer sizes on LP64 are 1,2,4,8 (CerberusImpl.sizeof_ity), so byte lists handed to int_of_bytes are non-empty and ≤ 16', 'CerberusImpl.lean:170-183; CerbMem.lean:613-614'),
 (rule('CerbMem.lean', line=654), U, 'structural: as bytesToInt (sizeof ≥ 1)', 'CerberusImpl.lean:170-183'),
 (rule('CerbMem.lean', line=1045), R, 'witness tests/failure-probes/reach/funptr_reload.c: both crash (oracle Failure("unknown function pointer: 2748"), Lean PANIC CerbMem:1045:18); input class IMPLEMENTATION-DEFINED (int→function-pointer conversion, §6.3.2.3p5; no call, no UB)', 'reach/README.md funptr_reload'),
 (rule('CerbMem.lean', line=1114), U, 'typing: C forbids empty unions (§6.7.2.1#8 constraint) — the parser/desugarer rejects', 'ISO C11 6.7.2.1p8'),
 (rule('CerbMem.lean', line=1124), K, 'needs a memory well-formedness invariant (unionmap records only members of that union) — model-shape, no theorem', 'CerbMem.lean:1116-1124'),
 (rule('CerbMem.lean', line=1128), U, 'typing/tag-kind consistency (not kernel-checked): a Union0 tag resolves to a UnionDef', 'CerbMem.lean:1128'),
 (rule('CerbMem.lean', line=1299), U, 'typing: zero-length arrays are a constraint violation (§6.7.6.2#1); MVarray [] is never built', 'ISO C11 6.7.6.2p1; CerbMem.lean:1299'),
 (rule('CerbMem.lean', line=1379), R, 'witness tests/immaculate/nolibc/zd-z2m02-device-funptr-call.c: both crash (oracle Failure("case_ptrval"), Lean PANIC CerbMem:1379:4); input class UB (call through a forged function pointer)', 'q2 file; IMMACULATE_PANICS'),
 (rule('CerbMem.lean', msg='Enum after typeof_enum'), U, 'structural: CerberusImpl.typeof_enum never returns an Enum0 (its codomain is the registered underlying type)', 'CerberusImpl.lean:55-74 typeof_enum'),
 (rule('CerbMem.lean', line=1535), U, 'dominance: Core `shl`/`shr` reach IntExp only after the shift-count UB checks (UB136/137) — the exponent is non-negative; registered Z2 §2.10', 'docs/2026-09-04_zero-discrepancy-Z2-record.md §2.10; CerbMem.lean:1535'),
 (rule('CerbMem.lean', line=1551), U, 'typing: member access/offsetof names an existing member (Ail typing)', 'ail/genTyping.lem member rules; CerbMem.lean:1551'),
 (rule('CerbMem.lean', line=1724), U, 'config: Prov_symbolic only in symbolic mode', 'CerbGlobal.lean current_execution_mode'),
 (rule('CerbMem.lean', line=1726), R, 'witness tests/minimal/097-null-ptr-arith.undef.c: both crash (oracle Failure("TODO(pure shift a null pointer…"), Lean PANIC CerbMem:1726:6); input class UB (arithmetic on a null pointer)', 'q2 file; gcc_oracle_baseline SKIP_LEAN_CRASH row'),
 (rule('CerbMem.lean', line=1727), K, 'the tested route ((char*)main + 1, witness funptr_arith.c) is dominated by the typed `Error MerrOther "called isWellAligned_ptrval on function pointer"` on both engines; another route to array_shift on a PVfunction is not excluded', 'q3_witness_outputs.txt funptr_arith'),
 (rule('CerbMem.lean', line=1750), K, 'untested route (((struct S*)main)->x) — same family as :1727; bounded effort', 'CerbMem.lean:1750'),
 (rule('CerbMem.lean', owner='bytefromint'), U, 'structural (byte range): AbsByte values are produced by intToBytes in 0..255', 'CerbMem.lean:1762; intToBytes'),
 (rule('CerbMem.lean', owner='intfrombyte'), U, 'structural (byte range): as bytefromint', 'CerbMem.lean:1770'),
 (rule('CerbMem.lean', msg='CHERI only'), U, 'config: CerbGlobal.is_CHERI is the plain def `false` since 2026-09-05 (kernel-dead by simp)', 'CerbGlobal.lean is_CHERI; docs/2026-09-05_cerbglobal-defs-record.md'),
 (rule('CerbStepInstances.lean'), U, 'structural (call-site shape): the only `==` uses on core_step2 compare against the nullary Step_blocked2 (`step1 != Step_blocked2`, `maybeEqualBy … (some Step_blocked2)`); same-constructor closure arms never execute', 'Driver.lean:425 (generated driver2); CerbStepInstances.lean:60-63 header'),
 (rule('CerbUtils.lean', line=136), U, 'dominance: `__builtin_ctz(0)` yields `Undefined {ub: "DUMMY(__builtin_ctz)"}` on both engines before the model ctz runs (witness ctz0.c)', 'q3_witness_outputs.txt ctz0'),
 (rule('CerbUtils.lean', line=146), U, 'typing/promotion: the uint16_t parameter converts the argument into range (witness bswap16_range.c: Specified(35) both engines)', 'q3_witness_outputs.txt bswap16_range'),
 (rule('CerbUtils.lean', line=155), U, 'typing/promotion: as bswap16 (uint32_t parameter)', 'CerbUtils.lean:155'),
 (rule('CerbUtils.lean', line=172), R, 'witness tests/immaculate/nolibc/g4-bswap64-overflow.c: both crash (oracle Z.Overflow, Lean PANIC CerbUtils:172:4); input class LEGAL C (uint64_t ≥ 2^63) — ORACLE-WRONG (tray 12), mirrored', 'q2 file; baseline.txt g4-bswap64-overflow'),
 (rule('CerberusImpl.lean', line=142), U, 'structural/pin: the N-family alias table covers the four stdint widths; `__int128` is rejected by the parser (witness int128.c: cabs-json error)', 'CerberusImpl.lean:130-142; q3_witness_outputs.txt int128'),
 (rule('CerberusImpl.lean', owner='sizeof_ity'), U, 'structural (kernel-provable): the match is on normalise_integerType\'s result, whose codomain excludes the N-families/Intmax_t/Intptr_t/Enum/Wchar_t/Wint_t/Size_t/Ptrdiff_t', 'CerberusImpl.lean:170-183, normalise_integerType'),
 # ---------------- generated ----------------
 (rule('Builtins.lean', line=46), U, 'pin/structural: the only errno strings the fs model emits are "EINVAL" (5 sites in CerbFS.lean) and "__cerbvar_EINVAL" is in the table', 'driver.lem:213; builtins.lem:118; grep CerbFS.lean `.other "EINVAL"` ×5'),
 (rule('Core_aux.lean', line=75), U, 'typing: memory values carry complete object types (no incomplete arrays, no function types) — §6.2.5#1; the arms are the non-object cases', 'core_aux.lem core_object_type_of_ctype; translation.lem:690 force_core_object_type_of_ctype on object types'),
 (rule('Core_aux.lean', msg='concurrency read'), U, 'structural: the concrete memory model never constructs MVconcurRead (0 constructions in CerbMem.lean); the callback exists for the interface', 'grep MVconcurRead CerbMem.lean = 0'),
 (rule('Core_aux.lean', msg='empty array'), U, 'typing: zero-length arrays rejected (§6.7.6.2#1); array mem-values are non-empty', 'ISO C11 6.7.6.2p1'),
 (rule('Core_aux.lean', msg='heterogenous array'), U, 'model-shape (not a theorem): reconstructValue builds every array value from ONE element type', 'CerbMem.lean reconstructValue array arm'),
 (rule('Core_aux.lean', line=125), U, 'model-shape: exec-path callers (Core_reduction) build tuple patterns from non-empty unseq lists; an empty Eunseq is itself an error arm', 'core_reduction.lem; Core_run.lean:424 "BOOM Core_run, Eunseq, empty list"'),
 (rule('Core_aux.lean', owner='subst_pattern_val_lemFuel'), U, 'typing: the catch-all arm is a pattern/value shape mismatch on an irrefutable (let/wseq/sseq) pattern; Core typing makes pattern and value types agree', 'core_aux.lem subst_pattern_val (CaseCtor ctor pats, _) arm; core_typing.lem:30-75 infer_pattern/typecheck_pattern'),
 (rule('Core_aux.lean', owner='update_env_aux_lemFuel'), U, 'typing: as subst_pattern_val', 'core_aux.lem update_env_aux; core_typing.lem:30-75'),
 (rule('Core_aux.lean', owner='to_pure_lemFuel'), U, 'model-shape: to_pure is called (finalize, driver_globals) only when the arena is `Epure` of a value — Step_done requires it (core_run.lem:1557-1589) — and returns without descending', 'core_run.lem:1557-1589; driver.lem:1477,:1614'),
 (rule('Core_aux.lean', line=908), U, 'model-shape (not a theorem): the thread env is initialised `[Map.empty]` and pushed/popped in pairs', 'driver.lem:1571'),
 (rule('Core_eval.lean', owner='mk_wrapI'), U, 'structural (kernel-provable): eval_integer_value is total — IntegerValue has the single constructor IV and caseIntegerValue never invokes the `Nothing` callback', 'CerbMem.lean:68-70, :1620-1622; Mem.lean:214'),
 (rule('Core_eval.lean', owner='mk_conv_int'), U, 'structural: as mk_wrapI', 'CerbMem.lean:1620-1622'),
 (rule('Core_eval.lean', owner='mk_call_catch_exceptional_condition'), U, 'structural: as mk_wrapI', 'CerbMem.lean:1620-1622'),
 (rule('Core_eval.lean', line=128), U, 'structural: wrap_list is applied to 3-element lists only; PEconstrained is never introduced in the concrete model (pull_constrained only propagates existing ones)', 'core_eval.lem:180-220'),
 (rule('Core_eval.lean', owner='step_eval_peop'), U, 'typing (Core): OpAnd/OpOr are boolean-only and OpRem_t/OpRem_f/OpExp integer-only, so the integer/float catch-alls are dead for well-typed Core', 'core_typing.lem:626-659'),
 (rule('Core_eval.lean', line=147), U, 'typing/tag-kind consistency: a PEstruct tag resolves to a StructDef', 'core_typing.lem PEstruct rule; core_eval.lem:874'),
 (rule('Core_reduction.lean', line=349), K, 'needs a Core progress argument for Eunseq elements (which shapes survive evaluation) — bounded effort', 'core_reduction.lem one_step_unseq_aux'),
 (rule('Core_reduction.lean', msg='PEconstrained'), U, 'structural: PEconstrained is never introduced in the concrete model (only propagated: core_eval.lem:191-219); IntegerValue is single-constructor', 'core_eval.lem:191-219; CerbMem.lean:68-70'),
 (rule('Core_reduction.lean', msg='saw a non-evaluated e1'), U, 'model-shape (dispatch order): step_ctx fully evaluates `Epure` sub-expressions (full_eval_pexpr, core_reduction.lem:1100) before one_step is applied to the Ewseq/Esseq', 'core_reduction.lem:1100; :391-413'),
 (rule('Core_reduction.lean', msg='step_action ==> SeqRMW'), U, 'dispatch: step_ctx handles `Eaction (SeqRMW …)` itself (core_reduction.lem:1228) and never passes it to step_action ("this should not be possible")', 'core_reduction.lem:759-760, :1228'),
 (rule('Core_reduction.lean', msg='TODO[Core_reduction]: Fence'), R, 'witness tests/failure-probes/reach/atomic_fence.c (libc mode): both crash (oracle "internal error: TODO[Core_reduction]: Fence", Lean PANIC); input class WELL-TYPED UB-FREE C11 (atomic_thread_fence) — class (c) concurrency-feature refusal', 'reach/README.md atomic_fence'),
 (rule('Core_reduction.lean', msg='TODO[Core_reduction]: RMW'), K, 'same family as Fence (C11 atomics); atomic_fetch_add is rejected by the desugarer (witness atomic_fetch_add.c: "desugaring failed" both engines), other RMW-producing forms untested', 'q3_witness_outputs.txt atomic_fetch_add'),
 (rule('Core_reduction.lean', msg='CompareExchange'), K, 'C11 atomics family (atomic_compare_exchange_*); untested route through the libc pin — bounded effort', 'core_reduction.lem step_action'),
 (rule('Core_reduction.lean', msg='TODO[Core_reduction]: Linux'), U, 'config/pin: Linux memory-model actions are emitted only for the `__cerbvar_linux_*` builtins, which no standard header declares', 'core_run/core_reduction Linux* arms; typed-failure design §1.3 group C'),
 (rule('Core_reduction.lean', line=438), K, 'needs the bound-context (Cbound) shape invariant — bounded effort', 'core_reduction.lem break_at_sseq'),
 (rule('Core_reduction.lean', line=489), U, 'typing (Core builtin signatures): impl-proc integer arguments are OVinteger', 'core_reduction.lem process_impl_proc; core_typing builtin signatures'),
 (rule('Core_reduction.lean', msg='any_bounded_int'), U, 'pin: `__cerbvar_any_bounded_int` is a fork/CN builtin no standard header declares', 'core_reduction.lem process_impl_proc'),
 (rule('Core_reduction.lean', msg='__builtin_errno'), U, 'typing (Core builtin signatures): errno takes no arguments', 'core_reduction.lem process_impl_proc'),
 (rule('Core_reduction.lean', msg='exit given more'), U, 'typing/pin: the libc `exit` wrapper passes one argument (witness exit3.c in libc mode: Specified(3) on both engines)', 'q3_witness_outputs.txt exit3libc'),
 (rule('Core_reduction.lean', msg='process_impl_proc ==> TODO'), U, 'pin: unknown impl-procedure name — the libc/std.core pins declare only the handled builtins', 'tests/libc/libc.core pin; scripts/libc_prep.sh'),
 (rule('Core_reduction.lean', msg='empty Core_run env'), U, 'model-shape (not a theorem): env non-empty (initialised [Map.empty], driver.lem:1571)', 'driver.lem:1571'),
 (rule('Core_reduction.lean', msg='Core_reduction ==> Stack_cons'), U, 'config: Stack_cons2 frames exist only under concurrency (spawn); with_concurrency is false by default and Driver refuses concurrency', 'Driver.lean:320; CerbGlobal.lean'),
 (rule('Core_reduction.lean', msg='returned SeqRMWRequest2'), U, 'dispatch: step_action never returns SeqRMWRequest2 — the SeqRMW request is built directly by step_ctx (core_reduction.lem:1232)', 'core_reduction.lem:1196-1198, :1232'),
 (rule('Core_reduction.lean', msg='found a value with ctx <> CTX'), K, 'needs the context-decomposition invariant (get_ctx returns CTX for values) — bounded effort', 'core_reduction.lem step_ctx'),
 (rule('Core_reduction.lean', msg='negative SeqRMW'), U, 'structural: the elaborator emits SeqRMW with polarity Pos (core_aux.lem:564 `Paction Pos`)', 'core_aux.lem:551-564; translation.lem:700'),
 (rule('Core_reduction.lean', msg='SeqRMW ==> env is empty'), U, 'model-shape: env non-empty (driver.lem:1571)', 'driver.lem:1571'),
 (rule('Core_reduction.lean', msg='NO_BOUND'), K, 'needs the bound-context invariant for SeqRMW/negative actions — bounded effort (a plain `_Atomic int x; x += 1;` passes: witness atomic_rmw.c Specified(1) both engines)', 'q3_witness_outputs.txt atomic_rmw; core_reduction.lem:864-884'),
 (rule('Core_reduction.lean', msg='Erun outside of a proc'), U, 'typing (Core): Erun refers to a label of the enclosing procedure; Core typing checks labels within procs', 'core_typing.lem Erun/Esave rules; core_reduction.lem:1415'),
 (rule('Core_reduction.lean', msg='STUCK'), K, 'needs a Core progress theorem for the sequential fragment — bounded effort', 'core_reduction.lem step_ctx STUCK arm'),
 (rule('Core_reduction_aux.lean', msg='NOT an FS function'), U, 'dispatch: step_fs_proc is called only for the FS builtin names', 'core_reduction_aux.lem step_fs_proc caller guard'),
 (rule('Core_reduction_aux.lean', msg='BuiltinFunction: '), U, 'pin: unknown FS builtin name — the libc pin declares only the handled ones', 'tests/libc/libc.core pin'),
 (rule('Core_reduction_aux.lean'), U, 'typing/pin: argument-shape arms for the fs/printf builtins — the libc wrappers (pinned libc.core) pass the typed shapes; Core typing of builtin arguments', 'core_reduction_aux.lem step_fs_proc; tests/libc/libc.core'),
 (rule('Core_run_aux.lean'), U, 'config: Stack_cons2 / additional-synchronizes-with bookkeeping exist only for spawned threads; concurrency is refused by default', 'Driver.lean:320; CerbGlobal.lean with_concurrency'),
 (rule('Ctype_aux.lean'), K, 'cross-TU only (same-TU tags take the `tag1 = tag2` fast path, ctype_aux.lem:115-116); needs a 2-TU witness (an incomplete struct in one TU, a struct value stored across TUs) through scripts/test_multi_tu.sh — bounded effort', 'ctype_aux.lem:115-130; scripts/fuel_forms_pending.txt deep-ref note'),
 (rule('Driver.lean', line=301), U, 'dominance/typing: the `struct stat` lookup runs on FS_STAT results; in Lean the CerbFS.fs_stat refusal (:504) fires first (witness suite/fs/stat.c), and a libc program calling stat() has `struct stat` in tagDefs by typing', 'q2 file suite-fs-stat; Driver.lean:301'),
 (rule('Driver.lean', line=328), U, 'typing/pin: va_start\'s argument shape is fixed by the libc wrapper', 'driver.lem perform_memop_request2 Va_start'),
 (rule('Driver.lean', line=349), R, 'ORACLE-witnessed: tests/immaculate/libc/zd-z2f04-closedir.c makes the oracle die with exactly `internal error: can_advance: Step_error2 ==> …the value of a store(signed int*) didn\'t match the lvalue type: Specified(1)`; in Lean the CerbFS.fs_opendir refusal (:510) fires first (different site, same class — pinned MATCH | L=CRASH); input class filesystem boundary (legal opendir/closedir)', 'q2 file zd-z2f04-closedir'),
 (rule('Driver.lean', line=387), U, 'config: sequential execution has exactly the initial thread tid0', 'driver.lem drive_nonmemory_steps_aux2; Driver.lean:320 concurrency refusal'),
 (rule('Driver.lean', line=414), U, 'config: as :387 (initial thread always present)', 'driver.lem prepare_exit'),
 (rule('Driver.lean', line=436), U, 'model-shape: at finalize the arena is `Epure` of a value (Step_done shape, core_run.lem:1557-1589), so one step_eval_pexpr returns Defined — hack needs exactly one iteration and never sees UNDEF/ERROR', 'core_run.lem:1557-1589; driver.lem:1446-1457'),
 (rule('Driver.lean', line=469, msg='wasn\'t pure'), U, 'model-shape: as hack (arena is Epure at finalize; libc exit() also ends with a pure arena — witness exit3libc: Specified(3) both engines)', 'core_run.lem:1557-1589; q3_witness_outputs.txt exit3libc'),
 (rule('Driver.lean', line=469, msg='BOOM finalize'), U, 'config: thread_states is a singleton in the sequential driver (concurrency refused)', 'Driver.lean:320; driver.lem:1473-1498'),
 (rule('Formatted.lean', line=428), U, 'structural: digits handed to charFromDigit come from showNonNegativeWithBasis with basis 8/10/16', 'formatted.lem:300-345'),
 (rule('Formatted.lean', line=444), U, 'structural: callers pass `abs n` / unsigned conversions (formatted.lem:573 `naturalFromInteger $ abs n`); %o/%u/%x with a negative int is UB153b before conversion (witness printf_x_neg.c)', 'formatted.lem:573; q3_witness_outputs.txt printf_x_neg'),
 (rule('Formatted.lean', line=490), R, 'witness tests/failure-probes/reach/printf_star_prec.c (`%.*d`): both crash; input class WELL-TYPED UB-FREE C — class (c) feature refusal; LET-BOUND (F1 shape) yet USED at runtime', 'reach/README.md printf_star_prec'),
 (rule('Formatted.lean', line=494, msg='TODO(2)'), U, 'dominance: the top-level `let prec` (:490, formatted.lem:447-455) evaluates the same prec_opt first — witness printf_star_prec_s.c (`%.*s`) reports the :490 message', 'reach/README.md printf_star_prec_s; formatted.lem:447-455 vs :673'),
 (rule('Formatted.lean', line=494, msg='* prec'), U, 'dominance: as TODO(2) — witness printf_star_prec_f.c (`%.*f`) reports the :490 message', 'reach/README.md printf_star_prec_f; formatted.lem:447-455 vs :614'),
 (rule('Formatted.lean', line=499), R, 'witness tests/failure-probes/reach/printf_star_width.c (`%*d`): both crash ("TODO: formatted.lem 6"); WELL-TYPED UB-FREE C — class (c)', 'reach/README.md printf_star_width'),
 (rule('Formatted.lean', line=508), U, 'structural: the `Nothing` callback of caseIntegerValue is never invoked (CerbMem.lean:1620-1622)', 'CerbMem.lean:1620-1622'),
 (rule('Implementation.lean', owner='is_compatible_with_size_t'), U, 'structural: sizeof_ity never returns `none` (CerberusImpl.lean:170-183); witness printf_zu.c/printf_zd.c pass', 'implementation.lem:695-702; q3_witness_outputs.txt printf_zu'),
 (rule('Implementation.lean', owner='is_compatible_with_ptrdiff_t'), U, 'structural: as size_t; witness printf_td.c passes', 'implementation.lem:704-711; q3_witness_outputs.txt printf_td'),
 (rule('Implementation.lean', owner='is_signed_or_unsigned_aux'), U, 'promotion/normalisation (not kernel-checked): the predicate is applied to `normalise_ctype arg_ty` (formatted.lem:471) after C default argument promotion, so Char/Bool/Wchar_t/Wint_t/Enum never reach it (witness printf_ld_wchar.c → UB153b, not this arm)', 'formatted.lem:471; q3_witness_outputs.txt printf_ld_wchar'),
 (rule('Translation_aux.lean', line=75), U, 'pin: the pinned std.core defines conv_loaded_int (the only exec-path mk_stdcall)', 'driver.lem:166; runtime/libcore/std.core (grep conv_loaded_int = 1)'),
 (rule('Utils.lean'), U, 'structural: the exec-path caller (call_function) checks |params| = |args| before foldl2 (core_eval.lem:150-157); map2_ has no exec-path caller', 'core_eval.lem:150-157'),
]

out_rows = []
from collections import Counter
tally = Counter(); kinds = Counter()
for r in rows:
    for pred, cls, why, cite in RULES:
        if pred(r):
            out_rows.append(r[:9] + [cls, why, cite, r[9]])
            tally[cls] += 1
            break
    else:
        sys.exit(f'UNASSIGNED: {r[:3]} {r[5][:60]}')
with open(out, 'w') as f:
    f.write('\t'.join(hdr[:9] + ['Q3 class', 'Q3 invariant / witness / need', 'cite', 'Q1 note']) + '\n')
    for r in out_rows: f.write('\t'.join(r) + '\n')
print('Q3 tally:', dict(tally))
print('Q3 by Q1:', Counter((r[4].split('/')[0], r[9]) for r in out_rows))
print('REACHABLE sites:'); [print('  ', r[0].split('/')[-1]+':'+r[1], r[2], '|', r[4], '|', r[10][:110]) for r in out_rows if r[9]==R]
print('UNKNOWN sites:'); [print('  ', r[0].split('/')[-1]+':'+r[1], r[2], '|', r[5][:50]) for r in out_rows if r[9]==K]
