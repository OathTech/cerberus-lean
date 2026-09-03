# Draft — Lean 4 runtime: the stack-overflow `SIGSEGV` handler calls `pthread_getattr_np`, which mallocs; an overflow inside glibc `malloc` therefore deadlocks silently instead of aborting

Target: `leanprover/lean4` (runtime, `src/runtime/stack_overflow.cpp`).
Drafted 2026-09-02, rewritten 2026-09-03 with a standalone reproducer;
NOT filed — filing is the operator's call (network + GitHub).
Classification [AGENT 2026-09-03]: **TRUE BUG (runtime; silent hang in
place of the designed abort), NOT FIXED** — reproduced on v4.28.0,
v4.32.2, v4.33.0 and nightly-2026-08-02 (4.34.0-nightly); the offending
call is present in every toolchain inspected back to v4.13.0.
Reproducer + verbatim outputs: `lean4/repro/` (this directory); full
experiment log: `lean_frontend/docs/2026-09-03_lean4-runtime-repro-record.md`.

## Summary

The runtime installs `segv_handler` (on an alternate signal stack) to
turn a guard-page fault into `Stack overflow detected. Aborting.` +
`abort()`. To decide whether the fault address is in the guard page the
handler calls `pthread_attr_init` / `pthread_self` /
`pthread_getattr_np` / `pthread_attr_getstack` / `sysconf` FROM INSIDE
THE SIGNAL HANDLER, and only then `write(2, msg)` and `abort()` (call
sequence read off `libleanrt.a`'s `stack_overflow.cpp.o`, identical in
every toolchain checked). `pthread_getattr_np` is not async-signal-safe:
on glibc 2.39 it takes the thread descriptor's low-level lock and calls
`realloc`/`free` for the affinity cpuset, and for the initial thread it
additionally `fopen`s `/proc/self/maps` (`getline`, `sscanf`, `fclose`).
If the overflowing frame was inside glibc `malloc`/`realloc`/`free` — the
arena mutex held — the handler's own allocation waits on that mutex
forever. Nothing is printed (the `write` comes after), nothing exits.

Any program whose deepest recursion frame allocates through glibc
`malloc` hits this deterministically; in Lean that is every bignum
(`Nat`/`Int` beyond 63 bits: GMP uses `__gmp_default_reallocate` →
`realloc`) operation, since the glibc frames are then the deepest point
of every recursion level.

## Standalone reproducer (primary evidence)

`lean4/repro/OverflowInMalloc.lean` — 30 lines, no dependencies, built
with `lean -c` + `leanc -O3` (`repro/build.sh`):

```lean
def big : Nat := 2 ^ 10000   -- 157 limbs = 1256 bytes of limb storage

@[export repro_deep] partial def deep (n : Nat) (x : Nat) : Nat :=
  if n == 0 then x
  else deep (n - 1) (x + 1) + 1

def main (args : List String) : IO Unit := do
  let n := (args.head? >>= String.toNat?).getD 1000000000
  IO.println s!"depth {n}"
  (← IO.getStdout).flush
  IO.println s!"result {deep n big}"
```

(`@[export]` makes the parameters owned so each frame frees its bignum
before recursing — memory stays constant; the bignum is wider than
glibc's tcache limit so every `realloc`/`free` takes the arena lock.)
`repro/PlainRecursion.lean` is the same recursion with `deep n 0` — no
allocation per frame — and is the control.

Lean 4.32.2, default settings (1 GiB stack for the thread running
`main`), `repro/run.sh 60 ./<binary>`, verbatim:

```
$ ./PlainRecursion
depth 1000000000

Stack overflow detected. Aborting.
.../run.sh: line 15: 1812202 Aborted                 (core dumped) "$@"
exit=134

$ ./OverflowInMalloc
depth 1000000000
TIMEOUT after 60s; threads of pid 1812250:
  tid=1812250 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
  tid=1812252 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
  tid=1812253 state=S utime_ticks=590 stime_ticks=34 wchan=futex_do_wait
  VmRSS:	 1057264 kB
  Threads:	3
exit=124
```

The thread running `main` burns 5.9 s of CPU (derived: 590 ticks at
CLK_TCK 100) recursing, then parks in `futex` with the process alive and
silent.

### Mechanism, first-hand (`strace -f -k`)

`LEAN_STACK_SIZE_KB=65536 strace -f -k -e trace=futex,rt_sigaction,mprotect ./OverflowInMalloc`,
excerpt verbatim (tid 1800904 runs `main`; the first stack is the
faulting context, the second the handler's):

```
1800904 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_ACCERR, si_addr=0x73a14bfdfff8} ---
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0xd5f) [0xab84f]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x2635) [0xad125]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
 > .../OverflowInMalloc(__gmp_default_reallocate+0x14) [0x193864]
1800904 futex(0x73a144000030, FUTEX_WAIT_PRIVATE, 2, NULL <unfinished ...>
1800902 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__nptl_death_event+0x181) [0x98e51]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_join+0x173) [0x9e883]
 > .../OverflowInMalloc(lean_run_main+0x107) [0x186427]
1800904 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x2d0) [0xada20]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x12a) [0x9e05a]
 > .../OverflowInMalloc(segv_handler+0x35) [0x201ca5]
```

- Faulting frame: glibc `realloc` → `_int_realloc`/`_int_malloc` (the
  `__default_morecore+…` names are strace's nearest-exported-symbol
  labels for glibc's unexported malloc internals), called from GMP's
  `__gmp_default_reallocate` for the bignum add. `si_addr` is 8 bytes
  inside the guard page of the 64 MiB thread stack
  (`mprotect(0x73a14bfe0000, 67239936, PROT_READ|PROT_WRITE)` earlier in
  the same trace).
- Lock: the mutex of the thread's glibc malloc arena. The arena's heap
  is at `0x73a144000000` (created by the thread's first `malloc`, visible
  in the trace as `mprotect(0x73a144000000, 135168, …)` from
  `stack_guard::stack_guard()`); `struct malloc_state` follows the
  0x30-byte `heap_info`, so `arena->mutex` is at `+0x30` =
  `0x73a144000030`, and `2` is glibc's "locked with waiters".
- Handler frame: `segv_handler+0x35` → `pthread_getattr_np+0x12a` →
  `malloc` (the `realloc(NULL, 32)` for the cpuset) →
  `__lll_lock_wait_private`.

Initial-thread variant (`LEAN_MAIN_USE_THREAD=0`, or Lean ≤ 4.28 where
`main` still runs on the initial thread): the fault is `SEGV_MAPERR`
below the 8 MiB main stack and the handler blocks via
`pthread_getattr_np+0x266` → `fopen64` → `malloc` →
`__lll_lock_wait_private` on `main_arena.mutex`
(`futex(0x79f2ef603ac0, FUTEX_WAIT_PRIVATE, 2, NULL)`; full excerpt in
`repro/README.md`).

### Toolchain matrix (same source, same recipe, default settings, one run each)

| Toolchain | `PlainRecursion` | `OverflowInMalloc` |
|-----------|------------------|--------------------|
| v4.28.0 (`main` on the initial thread, 8 MiB) | abort, exit 134 | HANG: exit 124, utime_ticks=5, 2 threads, VmRSS 15240 kB |
| v4.32.2 | abort, exit 134 | HANG: exit 124, utime_ticks=590, VmRSS 1057264 kB |
| v4.33.0 | abort, exit 134 | HANG: exit 124, utime_ticks=599, VmRSS 1057348 kB |
| nightly-2026-08-02 (4.34.0-nightly) | abort, exit 134 | HANG: exit 124, utime_ticks=580, VmRSS 1057260 kB |

Not a regression range: the defect is present in the oldest and the
newest toolchain we can run. The `segv_handler` → `pthread_getattr_np`
call sequence is identical in the `stack_overflow.cpp.o` of every
toolchain from v4.13.0 to the nightly (by `objdump -r`).

### What decides hang vs. abort (variants, Lean 4.32.2, `repro/Variants.lean`)

| Per-frame work | Outcome |
|----------------|---------|
| none (`plain`) | abort, exit 134 |
| bignum add (`bignum`) | HANG |
| bignum add on a `Task.spawn` worker thread (`task`) | HANG |
| bignum add through a function-typed monad, one closure application per bind (`cps`, 64 MiB stack) | HANG |
| fresh 2 KB `ByteArray` per frame — Lean's own allocator, mimalloc (`bytes`) | abort, exit 134 |
| `IO.Ref.modify` per frame (`ref`) | abort, exit 134 |
| `OverflowInMalloc` with `LEAN_STACK_SIZE_KB=8192`, or built `-O0` | HANG |
| `lean --run OverflowInMalloc.lean` (interpreter) | `deep recursion was detected at 'interpreter'`, exit 1 — the interpreter's own depth check fires first |

So neither the recursion shape, the thread, the stack size nor the
optimisation level matters; only whether the frame that touches the guard
page holds glibc's arena lock. (Which frame that is depends on the
per-level stack layout — which is why, in our own program, a rebuild
that changed frame sizes moved the SAME overflow from a clean abort to a
hang: see the secondary evidence.)

## Secondary evidence: the program in which it was found

This project's Lean-compiled C front end, on a translation unit
declaring `char g[10000000];`, recurses once per array element. Run
under `strace -f -k -e trace=futex,rt_sigaction` (2026-09-03, Lean
4.32.2, 300 s timeout, no output, exit 124), excerpt verbatim (tid
1811517 runs `main`):

```
1811517 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_ACCERR, si_addr=0x7f355bfffff8} ---
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x262c) [0xad11c]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
 > .../cerberus-lean(__gmp_default_reallocate+0x14) [0x4d03994]
1811517 futex(0x7f3554000030, FUTEX_WAIT_PRIVATE, 2, NULL <unfinished ...>
1811515 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__nptl_death_event+0x181) [0x98e51]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_join+0x173) [0x9e883]
 > .../cerberus-lean(lean_run_main+0x107) [0x4d01e37]
1811517 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__libc_calloc+0x3b0) [0xaec50]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_attr_destroy+0x6b) [0x99f5b]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_attr_setaffinity_np+0x60) [0x9a2a0]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x1b8) [0x9e0e8]
 > .../cerberus-lean(segv_handler+0x35) [0x4d7fda5]
```

Same fault site (`realloc` from `__gmp_default_reallocate`, guard page
of the 1 GiB stack), same lock (`+0x30` of a fresh arena heap), same
handler path — here blocking one call later, in
`pthread_attr_setaffinity_np`'s `calloc`. This is the run recorded
earlier by `/proc` and a futex-only strace (all threads parked, ~3 s of
CPU, RSS plateau 2.7 GB, 8/8 reproductions across two sessions;
`lean_frontend/docs/2026-09-01_mem-scale-profile.md` §6.3). The earlier
observation that the onset moved with `LEAN_STACK_SIZE_KB` in both
directions (rows in that record) is consistent: the depth is the
program's, the silence is the handler's.

## Proposed remedy

1. Do not call `pthread_getattr_np` (or any allocating/locking function)
   in `segv_handler`. Compute the thread's stack bounds once, where the
   runtime already has a per-thread hook outside signal context — the
   `stack_guard` constructor that installs the alternate stack for each
   `lthread` (and `initialize_stack_overflow` for the initial thread) —
   and keep them in a thread-local; the handler then compares
   `info->si_addr` against the stored guard range using only plain
   loads.
2. Keep the report path to `write(2, static_msg, len)` + `abort()`
   (already the case once the check passes).
3. Defence in depth: if the handler cannot decide (no recorded bounds
   for this thread), still `write` a fixed message and `abort()` rather
   than restore `SIG_DFL` and return silently; and/or arm `alarm()` on
   entry so a second-order block inside the handler terminates the
   process.

## Provenance

Found and analysed by an AI agent (Claude) working on this project's
differential-validation harness; the reproducer, matrix and every quoted
trace are verbatim from runs on 2026-09-03 (Ubuntu glibc 2.39, kernel
7.0.0-30-generic, x86_64; toolchains from `~/.elan/toolchains`). Per this
tray's labeling policy, the filed issue body must carry an explicit
AI-provenance note.
