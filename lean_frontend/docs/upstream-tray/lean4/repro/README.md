# Lean 4 runtime: stack overflow inside glibc `malloc` deadlocks the SIGSEGV handler

Standalone reproducer for a Lean 4 runtime defect: when a thread overflows
its stack while glibc `malloc` holds its arena lock, the runtime's stack
overflow handler (`segv_handler` in `src/runtime/stack_overflow.cpp`) blocks
forever instead of printing `Stack overflow detected. Aborting.` and
aborting. The process produces no output and never exits.

Cause (from the stack traces below): `segv_handler` calls
`pthread_getattr_np` to find the current thread's stack bounds.
`pthread_getattr_np` is not async-signal-safe: on glibc it takes the
thread descriptor lock and calls `realloc`/`free` (for the cpuset), and for
the initial thread it additionally `fopen`s `/proc/self/maps`. When the
fault interrupted a `malloc`/`realloc`/`free` on the same arena, the
handler's own `malloc` waits on the arena mutex that the interrupted frame
holds. Nothing ever releases it.

## Files

| File | Purpose | Outcome |
|------|---------|---------|
| `OverflowInMalloc.lean` | non-tail recursion; each frame does one bignum add (GMP -> glibc `realloc`/`free`, chunk > tcache limit) | **hangs** (no output, no exit) |
| `PlainRecursion.lean` | same recursion, no allocation per frame | aborts loudly, as designed |
| `Variants.lean` | the same on a `Task` thread, through a closure-chain monad, with `ByteArray`/`IO.Ref` per frame instead of bignums | see the table below |
| `build.sh` | `lean -c` + `leanc -O3` for every `.lean` here (no lake, no deps) | |
| `run.sh` | runs a command with a timeout; on timeout dumps per-thread CPU time and wait channel from `/proc` | |

## Build and run

```
$ TC=~/.elan/toolchains/leanprover--lean4---v4.32.2
$ ./build.sh $TC /tmp/repro-build
$ cd /tmp/repro-build
$ ./PlainRecursion          # control: aborts with the message, exit 134
$ ./OverflowInMalloc        # hangs after ~6 s of CPU (1 GiB main-thread stack)
```

Both programs recurse until the stack of the thread running `main` (1 GiB
by default, see `LEAN_STACK_SIZE_KB`) is exhausted. `PlainRecursion` is
the control. Nothing else is needed: no lake project, no dependencies. To
make the hang appear faster use a smaller stack, e.g.
`LEAN_STACK_SIZE_KB=65536 ./OverflowInMalloc` (about 0.4 s).

## Observed (Lean 4.32.2, x86_64 Linux, glibc 2.39, kernel 7.0.0)

Control, verbatim (`run.sh 60 ./PlainRecursion`):

```
depth 1000000000

Stack overflow detected. Aborting.
.../run.sh: line 15: 1812202 Aborted                 (core dumped) "$@"
exit=134
```

Reproducer, verbatim (`run.sh 60 ./OverflowInMalloc`; the third thread is
the one running `main`, it burned 5.9 s of CPU and then parked in `futex`;
the process is still there at 60 s with no further output):

```
depth 1000000000
TIMEOUT after 60s; threads of pid 1812250:
  tid=1812250 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
  tid=1812252 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
  tid=1812253 state=S utime_ticks=590 stime_ticks=34 wchan=futex_do_wait
  VmRSS:	 1057264 kB
  Threads:	3
exit=124
```

### Where it blocks: `strace -k`

`LEAN_STACK_SIZE_KB=65536 strace -f -k -e trace=futex,rt_sigaction,mprotect ./OverflowInMalloc`,
excerpt verbatim (tid 1800904 runs `main`; 1800902 is the process's initial
thread, waiting in `pthread_join`). The first stack is the faulting
context, the second is the handler's:

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

Reading: the guard page of the 64 MiB thread stack (`mprotect(0x73a14bfe0000,
67239936, ...)` earlier in the trace) is hit 8 bytes in, from inside glibc
`realloc` (the `__default_morecore+...` frames are glibc's unexported
`_int_realloc`/`_int_malloc`, named after the nearest exported symbol)
called by GMP's `__gmp_default_reallocate` for the bignum add. The arena
mutex of the thread's malloc arena (heap at `0x73a144000000`, created by the
thread's first `malloc`; `struct malloc_state` follows the 0x30-byte
`heap_info`, so `arena->mutex` is at `+0x30`) is held. The handler then calls
`pthread_getattr_np`, which calls `realloc` (cpuset buffer) -> `malloc`,
which waits on the same mutex: `futex(0x73a144000030, FUTEX_WAIT_PRIVATE, 2)`
(state 2 = locked with waiters). The `write(2, "Stack overflow detected...")`
comes AFTER `pthread_getattr_np` in `segv_handler`, so no message appears.

### Same defect on the initial thread

With `LEAN_MAIN_USE_THREAD=0` (main runs on the process's initial thread,
8 MiB stack) the fault is `SEGV_MAPERR` below the main stack and the
handler blocks via the initial-thread branch of `pthread_getattr_np`,
which opens `/proc/self/maps` (verbatim, Lean 4.32.2):

```
1849323 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_MAPERR, si_addr=0x7fff847bbff8} ---
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x590) [0xab080]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x26c8) [0xad1b8]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
 > .../OverflowInMalloc(__gmp_default_reallocate+0x14) [0x193864]
1849323 futex(0x79f2ef603ac0, FUTEX_WAIT_PRIVATE, 2, NULL) = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
 > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x2d0) [0xada20]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(fopen64+0x1f) [0x85f5f]
 > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x266) [0x9e196]
 > .../OverflowInMalloc(segv_handler+0x35) [0x201ca5]
```

Here the lock is `main_arena.mutex` inside libc's data segment. Lean 4.28.0
(which still runs `main` on the initial thread) shows exactly this trace at
its default settings.

## Toolchain matrix

Same source, same recipe, default settings (`run.sh 60 ./<binary>`), one
run each; `utime_ticks` is the CPU consumed by the thread running `main`
before it parked (CLK_TCK = 100). The handler code (`segv_handler` ->
`pthread_getattr_np`) is byte-for-byte the same call sequence in every
toolchain's `libleanrt.a`.

| Toolchain | `PlainRecursion` | `OverflowInMalloc` |
|-----------|------------------|--------------------|
| v4.28.0 (main on the initial thread) | `Stack overflow detected. Aborting.` exit 134 | HANG: exit 124, utime_ticks=5, 2 threads, VmRSS 15240 kB |
| v4.32.2 | `Stack overflow detected. Aborting.` exit 134 | HANG: exit 124, utime_ticks=590, VmRSS 1057264 kB |
| v4.33.0 | `Stack overflow detected. Aborting.` exit 134 | HANG: exit 124, utime_ticks=599, VmRSS 1057348 kB |
| nightly-2026-08-02 (4.34.0-nightly) | `Stack overflow detected. Aborting.` exit 134 | HANG: exit 124, utime_ticks=580, VmRSS 1057260 kB |

Not fixed as of nightly-2026-08-02; present at least since v4.28.0 (the
`pthread_getattr_np` call in the handler is present in every toolchain we
have back to v4.13.0, by inspection of `libleanrt.a`).

## Variants (Lean 4.32.2)

`./Variants <mode>` (see the file header for the modes), `run.sh 60`, one
run each. Whether the process hangs or aborts depends only on whether the
frame that touches the guard page is inside glibc malloc, not on how the
recursion is written or which thread runs it:

| Mode | Per-frame work | Outcome |
|------|----------------|---------|
| `plain` | none | `Stack overflow detected. Aborting.` exit 134 |
| `bignum` | bignum add (GMP -> glibc `realloc`/`free`) | HANG (exit 124, utime_ticks=593) |
| `task` | `bignum`, but inside `Task.spawn` (worker thread; 4 threads in the process) | HANG (exit 124, utime_ticks=589 on the worker) |
| `cps` | `bignum` through a function-typed state monad (one closure application per bind); run with `LEAN_STACK_SIZE_KB=65536` because the closure chain retains every level's bignum | HANG (exit 124, utime_ticks=19, VmRSS 763764 kB) |
| `bytes` | a fresh 2 KB `ByteArray` per frame (Lean's own allocator, mimalloc) | `Stack overflow detected. Aborting.` exit 134 |
| `ref` | `IO.Ref.modify` per frame, no bignum | `Stack overflow detected. Aborting.` exit 134 |

Other knobs, `OverflowInMalloc` vs `PlainRecursion` (Lean 4.32.2):

| Setting | `PlainRecursion` | `OverflowInMalloc` |
|---------|------------------|--------------------|
| `LEAN_MAIN_USE_THREAD=0` (initial thread, 8 MiB) | abort, exit 134 | HANG (exit 124, utime_ticks=5, 2 threads) |
| `LEAN_STACK_SIZE_KB=8192` | abort, exit 134 | HANG (exit 124, utime_ticks=5) |
| built with `leanc -O0` instead of `-O3` | abort, exit 134 | HANG (exit 124, utime_ticks=232) |
| `lean --run File.lean` (interpreter) | `deep recursion was detected at 'interpreter'`, exit 1 | `deep recursion was detected at 'interpreter'`, exit 1 (the interpreter's own depth check fires first; the guard page is never reached) |

## Suggested fix

`segv_handler` must not call `pthread_getattr_np` (or anything that may
allocate or lock). Record the thread's stack bounds once, when the
`stack_guard` for the thread is constructed (that constructor already runs
on the thread, outside any signal context), in a thread-local; in the
handler compare `si_addr` against the recorded guard range and then
`write(2, ...)` + `abort()`. For the initial thread compute the bounds at
`initialize_stack_overflow` time. As defence in depth the handler could
`alarm()`/`_exit` if it has not terminated the process within a bound, so a
second-order failure inside the handler can never be silent.
