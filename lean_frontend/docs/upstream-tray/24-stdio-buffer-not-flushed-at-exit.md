# Program termination with the C library linked: `FILE` buffers are never flushed, `atexit` handlers do not run on return from `main`, `printf` bypasses the stream's buffer, and `vprintf` is undefined

**Status (cerberus-lean fork):** fixed in the fork on 2026-11-06 as a fork-ahead delta (the driver by generation on
both engines, the shipped library, the proxy rule mirrored in both drivers; record
`lean_frontend/docs/2026-11-05_stdio-exit-flush-record.md`; witness `scripts/check_stdio_exit.sh`); Draft for
upstream, to be filed. This report merges the fork's earlier drafts 24 (the flush) and 25 (the handlers) — one
mechanism, one patch. The patch below is against `rems-project/cerberus` at `c3ff8c53f` (the four files' hunks replayed
onto the pristine checkout's text, the fork-only comment hunks dropped; `git apply --check -p1` in the pristine checkout:
OK, 2026-11-06); upstream's tip carries the same text in every cited region.

**Affected:** `frontend/model/driver.lem` at `c3ff8c53f` — `process_core_step2`'s `Step_done2 cval` arm (`:1326-1333`;
`prepare_exit` `:1304-1312`): the startup function's return ends the program directly, the
C library's `exit` is never entered; `runtime/libc/src/stdlib.c:223-227` `exit`: `__funcs_on_exit(); _Exit(code);` — no
stream flush (musl calls `__stdio_exit()` between them; this copy does not); `runtime/libc/src/stdio.c:238-243`
`__stdout_write` turns stdout fully buffered after its first write (musl's `lbf = -1` without the `isatty`/ioctl test,
which the model has no device for), so after the first newline-terminated write nothing reaches the output until an
explicit `fflush`; `frontend/model/translation.lem` `translate_function_designator` (:242-251) substitutes the
std.core proxy (`runtime/libcore/std.core:295` `[ailname = "printf"] printf_proxy` → `<builtin_printf>`, which writes
straight into the driver's stdout record) for EVERY call of the identifier `printf`, in libc mode too, so the library's
own `printf`/`vfprintf` (`stdio.c:658`, `:708`) are dead code and a `printf` after an `fputs` prints before it;
`runtime/libc/src/stdio.c` declares `vprintf` (`include/stdio.h:84`) but defines it nowhere (a call is
`ill-formed program: calling an unknown procedure`).

## Description

C17 5.1.2.2.3: a return from the initial call to `main` is equivalent to calling `exit` with the returned value;
7.22.4.4#2-#4: `exit` calls the `atexit` handlers in reverse order of registration, then flushes every open stream
with unwritten buffered data and closes them; 7.21.3#5: streams are flushed at normal program termination; 7.21.3:
a stream's writes are ordered; 7.21.6.10: `vprintf`. With the library linked none of this held:

1. **Return from `main`.** The driver's `Step_done2` arm calls `prepare_exit` (the thread's stack emptied, the value
   placed as the result) without entering the library's `exit`: no handler runs, nothing is flushed.
2. **`exit()`.** The library's `exit` runs the handlers and calls `_Exit` → `__builtin_exit` → the Core builtin; no
   flush. Everything in a `FILE` buffer at termination is lost — and since stdout is fully buffered after its first
   write, that is everything after the first newline-terminated write: `puts("a"); puts("b");` prints only `a`.
3. **`printf` ordering.** The proxy writes past the `FILE` buffer: `fputs("b", stdout); printf("c\n");` prints `c\n`
   (and after the flush fix alone, `c\nb`).
4. **`vprintf`** is declared and undefined.

## Reproducers (verbatim, 2026-11-06, pristine `c3ff8c53f`; the fork's two engines printed the same before the fix)

```c
/* tests/noodle-probes/lib/lib_stdio_unflushed_lost.c */
#include <stdio.h>
int main(void) { fputs("out", stdout); return 0; }
/* tests/noodle-probes/lib/lib_atexit_order.c */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
int main(void) { atexit(h1); atexit(h2); printf("m"); return 4; }
/* the audit's k2_puts3.c */
#include <stdio.h>
int main(void) { puts("a"); puts("b"); puts("c"); return 0; }
/* tests/stdio_exit/order_fputs_then_printf.c */
#include <stdio.h>
int main(void) { fputs("b", stdout); printf("c\n"); return 0; }
```

```
$ cerberus --exec --batch lib_stdio_unflushed_lost.c
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
$ cerberus --exec --batch lib_atexit_order.c
Defined {value: "Specified(4)", stdout: "m", stderr: "", blocked: "false"}
$ cerberus --exec --batch k2_puts3.c
Defined {value: "Specified(0)", stdout: "a\n", stderr: "", blocked: "false"}
$ cerberus --exec --batch order_fputs_then_printf.c
Defined {value: "Specified(0)", stdout: "c\n", stderr: "", blocked: "false"}
```

gcc 13.3.0 (`-std=c11 -w -O0`): `out`; `m21` with `$?` 4; `a\nb\nc\n`; `bc\n`. After the patch both fork engines print
gcc's lines (`scripts/check_stdio_exit.sh`: 46 programs, 34 pinned to gcc's line byte for byte).

## Observed vs expected

Observed: buffered stdout lost at `return` and at `exit()`; handlers skipped on `return`; `printf` reordered before
earlier buffered writes; `vprintf` unknown. Expected (5.1.2.2.3, 7.22.4.4#2-#4, 7.21.3, 7.21.6.10): the lines above.

## Impact

Every libc-mode program with more than one stdout write, or whose last write is not newline-terminated, or that mixes
`printf` with `puts`/`fputs`/`fwrite`/`putchar`, or that registers an `atexit` handler and returns from `main`, prints
a different `stdout:` field from every hosted implementation — silently (the value is right, the output is missing),
and invisibly to a Cerberus-vs-Cerberus differential (both engines agree). The fork's libc-mode corpora: 17 of 447
programs moved (two by output, the rest by the library's global layout, below).

## Proposed remedy (the fork's fix, a patch against `c3ff8c53f`)

- `driver.lem`: when the linked Core file defines `exit` (the extern map's `LK_normal` target for the identifier —
  libc mode; a `--nolibc` run only declares it), a `Step_done2` that comes from the startup function's return (the
  initial thread with an empty stack and a current procedure — the globals phase has none, and the Core builtin `exit`
  reached from `_Exit` fires inside its frame) is turned into a call of the library's `exit` with the returned value,
  the status object allocated and stored under the file's calling convention; `driver2` continues and the call ends
  in the builtin as today. Only a target of the library's funinfo shape `void (signed int)` is routed, once per run;
  a routed `exit` that returns (a program-defined one, UB 7.1.3) is a loud kill. A `--nolibc` run only declares
  `exit`, so nothing is routed there unless the program defines it itself.
- `stdlib.c` `exit`: `__funcs_on_exit(); fflush(NULL); _Exit(code);` (`fflush(NULL)` is the shipped loop over stdout,
  stderr and the open-file list). `_Exit`, `quick_exit`, `abort` unchanged (implementation-defined).
- `stdio.c` `vfprintf`: flush the stream's pending buffer before the builtin writes through the descriptor;
  `vprintf`: `return vfprintf(stdout, fmt, ap);`.
- `main.ml`: with the library linked, withhold std.core's `printf` ailname from the program's elaboration
  (`Pmap.remove "printf"`), so `printf` resolves by linking to the library's own and is ordered with the buffer. (A
  header macro `#define printf(...) fprintf(stdout, __VA_ARGS__)` under a libc-mode define was tried first and
  withdrawn: a preprocessor define whose source of truth is the cpp invocation cannot be kept consistent across
  tools that preprocess separately.) Consequence to note: a printf-format UB is then raised inside the library's
  `vfprintf` rather than at the program's call — as `fprintf`'s always was.

```diff
--- a/frontend/model/driver.lem	2026-11-06 04:53:25.718966078 +0000
+++ b/frontend/model/driver.lem	2026-11-06 04:53:25.765865927 +0000
@@ -65,6 +65,12 @@
   symbolic_assoc: map Symbol.sym Core.object_value;
   
   blocked: bool; (* concurrency model ended by blocking *)
+  (* fork-ahead delta (fix/stdio-exit-flush, 2026-11-06): set when the startup function's
+     return has been routed through the C library's `exit' (process_core_step2's Step_done2
+     arm); a second Step_done2 of the startup thread with an empty stack after that is the
+     routed `exit' RETURNING (a program-defined `exit' with external linkage, UB 7.1.3), a
+     loud kill, never a second routing *)
+  exit_routed: bool;
   (* DEBUG *)
   (*trace: list string;*)
   dr_step_counter: nat;
@@ -1311,6 +1317,83 @@
         <| core_st with Core_run.thread_states= [(tid0, (Nothing, th_st'))] |>
   end
 
+(* FORK-AHEAD DELTA (fix/stdio-exit-flush, 2026-11-06; upstream-tray reports 24 and 25;
+   record lean_frontend/docs/2026-11-05_stdio-exit-flush-record.md): a return from the
+   startup function is equivalent to calling `exit` with the returned value
+   (C17 5.1.2.2.3), which runs the `atexit` handlers and flushes the open streams
+   (7.22.4.4#2-#4, 7.21.3#5). Upstream's Step_done2 arm terminates directly, so with
+   the C library linked the handlers never ran and every FILE buffer was lost.
+
+   `startup_exit_call_opt dr_st cval` is `Just (exit_sym, tid0, th_st, status)` exactly
+   when the return must be routed through the library's `exit`:
+   - no routing has happened yet in this run (`exit_routed`): the routed call's own
+     Step_done2 is its termination, never a second routing;
+   - the linked Core file DEFINES `exit` (the extern map's `LK_normal` target for the
+     identifier "exit") AND its funinfo type is the library's shape, `void (signed int)`,
+     not variadic. With the library linked that is the library's `exit`. Without it
+     (`--nolibc`) the headers only declare `exit` (`LK_none`), so nothing is routed —
+     unless the program itself defines `exit` with external linkage (UB 7.1.3): a
+     definition of the library's shape is routed like the library's and, should it return,
+     is refused by the loud kill in the arm below; a definition of another shape (another
+     return type, another arity, variadic) is not routed and keeps upstream's direct
+     termination. Every other `--nolibc` program is unchanged (the 787-program sweep);
+   - the Step_done2 came from the STARTUP FUNCTION's return: the initial thread
+     (parent Nothing) has an empty stack and a current procedure. The two other
+     producers of Step_done2 are excluded by that shape: the globals phase
+     (driver_globals installs the thread with current_proc_opt = Nothing) and the Core
+     builtin `exit` reached from the library's `_Exit` (core_reduction.lem,
+     process_impl_proc's "exit" arm: the thread is inside the `_Exit` frame, stack
+     non-empty) -- that one is the termination of the routed call;
+   - the returned value is a loaded integer (`memValueFromValue signed_int`): the
+     startup function of a C program is `int main` (UB004a rejects the others at
+     desugar); a `--call` of a non-int function keeps the direct termination.
+   Anything else is Nothing: upstream's path, unchanged. *)
+val startup_exit_call_opt: driver_state -> Core.value -> maybe (Symbol.sym * Mem.thread_id * Core_run.thread_state * Mem.mem_value)
+let startup_exit_call_opt dr_st cval =
+  if dr_st.exit_routed then Nothing else
+  match Map.lookup (Symbol.Identifier Loc.unknown "exit") dr_st.core_file.Core.extern with
+    | Just (_, Core.LK_normal exit_sym) ->
+        (* the library's shape: `void exit(int)` -- one `signed int' parameter, not variadic *)
+        let is_exit_shape =
+          match Map.lookup exit_sym dr_st.core_file.Core.funinfo with
+            | Just (_, _, Ctype.Ctype _ Ctype.Void, [(_, Ctype.Ctype _ (Ctype.Basic (Ctype.Integer (Ctype.Signed Ctype.Int_))))], false, _) -> true
+            | _ -> false
+          end in
+        if not is_exit_shape then Nothing else
+        match List.find (function (_, (Nothing, _)) -> true | _ -> false end) dr_st.core_state.Core_run.thread_states with
+          | Just (tid0, (_, th_st)) ->
+              match (th_st.Core_run.stack, th_st.Core_run.current_proc_opt) with
+                | (Core_run.Stack_empty, Just _) ->
+                    match Caux.memValueFromValue Ctype.signed_int cval with
+                      | Just status_mval ->
+                          Just (exit_sym, tid0, th_st, status_mval)
+                      | Nothing ->
+                          Nothing
+                    end
+                | _ ->
+                    Nothing
+              end
+          | Nothing ->
+              Nothing
+        end
+    | _ ->
+        Nothing
+  end
+
+(* the initial thread has an empty stack: a Step_done2 in that state after a routing is the
+   routed `exit' RETURNING to the startup thread (the library's `exit' never returns; a
+   program-defined one may) *)
+val startup_thread_stack_empty: driver_state -> bool
+let startup_thread_stack_empty dr_st =
+  match List.find (function (_, (Nothing, _)) -> true | _ -> false end) dr_st.core_state.Core_run.thread_states with
+    | Just (_, (_, th_st)) ->
+        match th_st.Core_run.stack with
+          | Core_run.Stack_empty -> true
+          | _ -> false
+        end
+    | Nothing -> false
+  end
+
 (* performing all action and memop requests until there are no more *)
 val process_core_step2: bool -> (bool -> driverM unit) -> Core_reduction.core_step2 -> driverM unit
 let process_core_step2 with_concurrency driver2 = function
@@ -1328,10 +1411,52 @@
       "driver.process_core_step ==> Step_done2 with value: " ^ Pp.stringFromCore_value cval
     ) >> (* DEBUG *)
     (* ND.return () *)
-    ND.update (fun dr_st ->
-      (* killing all threads and aborting the main thread and placing [cval] as its result *)
-      <| dr_st with core_state= prepare_exit dr_st.core_state cval |>
-    )
+    ND.get >>= fun dr_st ->
+    match startup_exit_call_opt dr_st cval with
+      | Nothing ->
+          if dr_st.exit_routed && startup_thread_stack_empty dr_st then
+            (* the routed `exit' returned (only a program-defined `exit' with external
+               linkage can, UB 7.1.3; the library's ends in the Core builtin, whose
+               Step_done2 fires inside the `_Exit' frame): refused, never re-routed and never
+               a verdict *)
+            ND.kill (ND.Other (DErr_other "Driver: the C library's `exit' returned to the startup thread (a program-defined `exit' with external linkage, UB C17 7.1.3; `exit' does not return, 7.22.4.4): refused"))
+          else
+          ND.update (fun dr_st ->
+            (* killing all threads and aborting the main thread and placing [cval] as its result *)
+            <| dr_st with core_state= prepare_exit dr_st.core_state cval |>
+          )
+      | Just (exit_sym, tid0, th_st, status_mval) ->
+          (* FORK-AHEAD DELTA (fix/stdio-exit-flush, 2026-11-06; upstream-tray 24/25): the
+             startup function returned in libc mode, so the return is `exit(cval)`
+             (C17 5.1.2.2.3). The status object is allocated and initialised under the
+             file's calling convention, as the elaborated caller side of a C call is
+             (Normal: a pointer to a caller-side `signed int` object; inner_arg_temps: the
+             loaded value), and the library's `exit` is installed as the thread's arena;
+             driver2 continues. The object is never killed: `exit` does not return
+             (its `_Exit` reaches the Core builtin, whose Step_done2 takes the arm above
+             with a non-empty stack). *)
+          (match dr_st.core_file.Core.calling_convention with
+            | Core.Normal_callconv ->
+                let align_ival = Mem.integer_ival (Implementation.alignof_ty dr_st.core_file.Core.tagDefs Ctype.signed_int) in
+                liftMem (
+                  Mem.bind (Mem.allocate_object tid0 (Symbol.PrefOther "exit status") align_ival Ctype.signed_int Nothing Nothing) (fun ptr_val ->
+                    Mem.bind (Mem.store (Loc.other "exit status init") Ctype.signed_int false ptr_val status_mval) (fun _ ->
+                      Mem.return (Caux.mk_value_pe (Core.Vobject (Core.OVpointer ptr_val)))
+                    )
+                  )
+                )
+            | Core.Inner_arg_callconv ->
+                ND.return (Caux.mk_value_pe cval)
+          end) >>= fun arg_pe ->
+          ND.update (fun dr_st -> <| dr_st with
+            core_state= Core_run.update_thread_state tid0
+              <| th_st with Core_run.arena= Core.Expr [] (Core.Eproc Core_run.empty_annotation (Core.Sym exit_sym) [arg_pe]) |>
+              dr_st.core_state;
+            exit_routed= true;
+            dr_step_counter= dr_st.dr_step_counter + 1
+          |>) >>= fun () ->
+          driver2 with_concurrency
+    end
   
 
   | Core_reduction.Step_ccall2 tid step_m ->
@@ -1513,6 +1638,7 @@
     trace=             [];
     symbolic_assoc=    Map.empty;
     blocked=           false;
+    exit_routed=       false;
     dr_step_counter=   0;
   |>
 
--- a/runtime/libc/src/stdlib.c	2026-11-06 04:53:25.723129085 +0000
+++ b/runtime/libc/src/stdlib.c	2026-11-06 04:53:25.772985976 +0000
@@ -220,9 +220,17 @@
 }
 
 
+/* Cerberus fork (fix/stdio-exit-flush, 2026-11-06; upstream-tray report 24): C17 7.22.4.4#2-#4
+   -- the atexit handlers first (they may write), then every open stream with unwritten
+   buffered data is flushed (fflush(NULL) walks stdout, stderr and the open-file list,
+   stdio.c), then control returns to the host through _Exit. musl calls __stdio_exit here;
+   this copy had no flush, so everything still in a FILE buffer at exit was lost. _Exit,
+   quick_exit and abort flush nothing (7.22.4.5#2, 7.22.4.7#3, 7.22.4.1#2: implementation-
+   defined; unchanged). */
 _Noreturn void exit(int code)
 {
   __funcs_on_exit();
+  fflush(NULL);
   _Exit(code);
 }
 
--- a/runtime/libc/src/stdio.c	2026-11-06 04:53:25.727572792 +0000
+++ b/runtime/libc/src/stdio.c	2026-11-06 04:53:25.782290043 +0000
@@ -709,9 +709,21 @@
 {
   int __builtin_vprintf(int, const char* restrict, va_list);
   int fd = fileno(f);
+  /* Cerberus fork (fix/stdio-exit-flush, 2026-11-06; upstream-tray report 24): the
+     builtin writes through the descriptor, past this FILE's buffer; a stream's writes
+     are ordered (C17 7.21.3), so whatever earlier fputs/fwrite/putc left in the buffer
+     goes out first. */
+  if (f->wpos != f->wbase) fflush(f);
   return __builtin_vprintf(fd, fmt, ap);
 }
 
+/* Cerberus fork (fix/stdio-exit-flush, 2026-11-06; upstream-tray report 24): declared by <stdio.h>
+   but defined nowhere in the shipped library (a call was an unknown procedure); C17 7.21.6.10. */
+int vprintf(const char *restrict fmt, va_list ap)
+{
+  return vfprintf(stdout, fmt, ap);
+}
+
 int vsnprintf(char *restrict s, size_t n, const char *restrict fmt, va_list ap)
 {
   int __builtin_vsnprintf(char *, size_t, const char* restrict, va_list);
--- a/backend/driver/main.ml	2026-11-06 04:53:25.734311449 +0000
+++ b/backend/driver/main.ml	2026-11-06 04:53:25.786506739 +0000
@@ -149,6 +149,22 @@
     (* Looking for and parsing the implementation file *)
     load_core_impl core_stdlib impl_name >>= fun core_impl ->
     io.pass_message "Implementation file loaded." >>
+    (* Cerberus fork (fix/stdio-exit-flush M1c, 2026-11-06; upstream-tray report 24): with the
+       C library linked, std.core's proxy for the identifier `printf` is withheld from the
+       elaboration of the program's translation units (translation.lem
+       translate_function_designator substitutes every `[ailname = ...]` identifier), so a
+       call of `printf` resolves by linking to the library's own `printf` (stdio.c), whose
+       output is sequenced with the FILE buffer (C17 7.21.3) where the proxy wrote past it
+       into the driver's record. --nolibc runs and the library's own build (--nolibc) keep
+       the proxy; the Cabs JSON is unchanged either way, so the Lean driver, which decides
+       by its own --libc, consumes the same translation unit (lean_frontend/Main.lean
+       mirrors this at its stdlib load). *)
+    let core_stdlib =
+      if nolibc then core_stdlib
+      else begin
+        let (ailnames, std_funs) = core_stdlib in
+        (Pmap.remove "printf" ailnames, std_funs)
+      end in
     return ((core_stdlib, core_impl), elab_conf)
   in
   let main elab_conf core_std =
```

## Related findings (not this mechanism)

- Editing the library's translation units changes their source digests, which order the linked globals
  (`core_linking.lem` `merge_globs`: min (digest, number)); every libc-mode address a program prints then moves. Not a
  bug, but worth knowing when pinning libc-mode outputs: the layout is a function of the library sources' digests.
- `perror`/`strerror` fail an `assert()` in the shipped library (the fork's audit, K2 rows); `fopen` is refused by the
  fork's Lean engine (its filesystem contract).
- `_Exit`/`quick_exit`/`abort` after buffered output print the lines the library wrote through before turning fully
  buffered; glibc with a pipe prints nothing — both implementation-defined (7.22.4.5#2).

## Classification

**TRUE BUG.** Standard-mandated behaviour missing on both termination paths and on the proxy's ordering; the affected
code is the shipped library's own and the driver's, not a documented gap.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over the fork's Lean port (findings L3, L4), re-verified
2026-09-05 and 2026-11-04 (the fork's true-bug audit, which upgraded the impact: every write after the first newline
lost), fixed in the fork 2026-11-06 ([USER 2026-11-04] agreed the fix pass; the design and the two measurement findings
on the way are in the record). Localisation, the fix and this draft by Claude (Fable 5.1) under operator direction;
the filed issue carries an AI-provenance note per the tray's policy.
