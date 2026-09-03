# 2026-09-03 — Lean 4 runtime stack-overflow hang: standalone reproducer, mechanism, toolchain matrix (probe/lean4-runtime-repro)

Branch `probe/lean4-runtime-repro` off mainline `046e5cdd4`. Purpose: turn
tray draft `lean_frontend/docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`
(the in-project-only hang) into a standalone, fileable report. Outcome:
**standalone reproducer found on the first hypothesis (H1), deterministic
(18/18 hang runs of the malloc-per-frame program across four toolchains, threads, stack sizes and optimisation levels; 11/11 controls abort loudly), mechanism identified
to the frame and the lock.** Deliverables: `upstream-tray/lean4/repro/`
(sources, `build.sh`, `run.sh`, `README.md`), the rewritten tray draft,
this record. Every quoted output below is verbatim from this session;
counts and seconds marked "derived" are computed from quoted values.

Environment: Ubuntu glibc 2.39 (`ldd --version`: `ldd (Ubuntu GLIBC
2.39-0ubuntu8.8) 2.39`), kernel `7.0.0-30-generic`, x86_64, `CLK_TCK` 100,
strace 6.8 (`-k` works in the sandbox; `gdb` is not installed). All runs
under `cerberus-lean/scripts/capped` with `CERB_MEM_MAX=8G` (driver run:
16G), `ulimit -c 0`, and a 60 s timeout unless stated. Toolchains invoked
by path from `~/.elan/toolchains/` (no `elan` installs).

## 0. Static analysis first: what the handler does (all toolchains)

`libleanrt.a` ships `stack_overflow.cpp.o` with symbols. `objdump -d -r`
of the 4.32.2 object, `segv_handler` call sequence in order (relocations,
verbatim): `pthread_attr_init`, `pthread_self`, `pthread_getattr_np`,
`pthread_attr_getstack`, `pthread_attr_destroy`, `sysconf`, then EITHER
`sigaction` (not our guard page: reset to `SIG_DFL` and return) OR
`write` + `abort` (guard page). The `write` of "Stack overflow detected.
Aborting." (0x24 bytes) is reachable only after `pthread_getattr_np`
returns. The same relocation sequence is in v4.28.0, v4.33.0 and
nightly-2026-08-02 (checked); the same import list
(`pthread_getattr_np` …) is in every toolchain on the box:

```
== v4.13.0: abort free __gxx_personality_v0 malloc pthread_attr_destroy pthread_attr_getstack pthread_attr_init pthread_getattr_np pthread_self sigaction sigaltstack sysconf write operator operator
== v4.25.0-rc1 … v4.33.0, nightly-2026-08-02: abort free malloc pthread_attr_destroy pthread_attr_getstack pthread_attr_init pthread_getattr_np pthread_self sigaction sigaltstack sysconf write operator operator
```

glibc 2.39 `pthread_getattr_np` (objdump of `/lib/x86_64-linux-gnu/libc.so.6`,
calls in order, verbatim grep): `pthread_attr_init`, `lock cmpxchg`
(thread descriptor lll lock), `realloc@plt`, `pthread_getaffinity_np`,
`free@plt`, `pthread_attr_destroy`, `pthread_attr_setaffinity_np`,
`free@plt`, `__lll_lock_wake_private`, `__lll_lock_wait_private`,
`_IO_fopen`, `__getrlimit`, `_IO_fclose`, `__isoc23_sscanf`, `getline`.
I.e. it allocates on every path and does stdio on the initial-thread path.

Other runtime facts read off the objects: `lean::lthread::m_thread_stack_size`
initial value `0x40000000` (1 GiB); `lean_run_main` reads
`LEAN_STACK_SIZE_KB` (value << 10, page-aligned, + 0x20000) and
`LEAN_MAIN_USE_THREAD` (`"0"` → run `main` on the initial thread);
Lean objects go through mimalloc (`lean.h`: `LEAN_MIMALLOC` →
`mi_malloc_small`), but `libleanshared.so` imports glibc
`malloc/free/realloc/calloc`, links GMP statically with the default
allocator (`__gmp_default_allocate`/`__gmp_default_reallocate` → glibc),
and does not call `mp_set_memory_functions`.

Prediction [AGENT] before any run: the hang needs the guard page to be
touched while glibc's arena mutex is held, i.e. inside glibc
`malloc`/`realloc`/`free`; in Lean the cheapest deterministic way to
put glibc frames at the deepest point of every recursion level is a
bignum operation per frame (GMP → `realloc`), with the bignum wider than
glibc's tcache limit (1032 B) so the lock-free tcache fast path is
bypassed.

## 1. Hypotheses and verdicts

| H | Statement | Verdict [AGENT] |
|---|-----------|-----------------|
| H1 | overflow while a runtime lock is held → handler re-enters it | **CONFIRMED, lock = glibc malloc arena mutex** (`arena->mutex`, heap+0x30 for non-main arenas; `main_arena.mutex` in libc data for the initial thread). Not the Lean allocator (mimalloc: `bytes` variant aborts loudly), not stdio output, not `IO.Ref`. |
| H2 | closure-application depth (`lean_apply_*` chains / CPS) is the discriminator | **REJECTED as a cause**: `cps` mode with bignum hangs, `plain` with the same shape aborts; the tray's earlier closure-heavy toy without bignum aborted. Shape only moves WHICH frame is deepest. |
| H3 | thread identity / stack size | **REJECTED as a discriminator**: hangs on the `lean_run_main` thread (1 GiB), on a `Task.spawn` worker, on the initial thread (`LEAN_MAIN_USE_THREAD=0`, and natively on v4.28.0), and at `LEAN_STACK_SIZE_KB=8192`; the initial-thread path blocks in `fopen("/proc/self/maps")` → `malloc` instead of the cpuset `realloc`. |
| H4 | overflow inside `panic!`/`IO.Ref`/`initialize` | `IO.Ref` per frame: aborts loudly (no glibc lock). `panic!`/`initialize` not run — subsumed: only glibc-malloc-holding frames matter; not needed for the report. |
| H5 | `-O3` vs `-O0`; interpreter vs compiled | **REJECTED as a discriminator**: `-O0` hangs too. The interpreter (`lean --run`) never reaches the guard page — its own `deep recursion was detected at 'interpreter'` check fires (exit 1) for both programs. |

## 2. Experiments, in order (verbatim)

### 2.1 Build recipe

`repro/build.sh <toolchain> <outdir>`: `lean -c F.c F.lean && leanc -O3 -o F F.c`
(static link against the toolchain's `libInit`/`libleanrt`; `-lleanshared`
also works but then needs `LD_LIBRARY_PATH=$TC/lib/lean`). Built on
v4.28.0, v4.32.2, v4.33.0, nightly-2026-08-02 (`Lean (version
4.34.0-nightly-2026-08-02, … commit 23d17351ab63…)`).

### 2.2 Negative results on the way (kept: they are experiment defects, not evidence)

1. First `OverflowInMalloc` draft (`if n == 0 then x % 1000`): `x`
   inferred BORROWED → each frame's `lean_dec(x)` emitted AFTER the
   recursive call → every level's 1.3 KB bignum retained → OOM-KILLED at
   the 8G cap after 11.8 s (`capped: OOM-KILLED (exit 137 — cgroup memory
   cap CERB_MEM_MAX=8G breached; memory.events oom_kill=1; NOT a pass)`,
   `wall=11.80 user=3.47 sys=7.32 maxrss=8382340kB exit=137`). Returning
   `x` in the base case did not change the inference (`lean_inc(v_x_6_);
   return v_x_6_;`). Fix: `@[export repro_deep]` (exported functions
   have owned parameters); the generated C then reads
   `lean_dec(v_x_6_); v___x_12_ = repro_deep(v___x_10_, v___x_11_);`.
2. `Variants task` first draft used `IO.asTask (pure (deep n big % 1000))`
   — strict argument evaluation ran `deep` on the main thread (3 threads,
   hang on the `lean_run_main` thread). Rewritten as `Task.spawn fun _ =>
   deep n big % 1000` (4 threads, hang on the worker). Both runs hung; only
   the second is evidence for the task-thread claim.
3. `Variants cps` at the default 1 GiB stack: OOM-KILLED at 8G (the
   closure chain retains every level's bignum) — not evidence either
   way; re-run at `LEAN_STACK_SIZE_KB=65536` (hang, below).
4. `/usr/bin/time` under `timeout` loses the child's rusage when the
   process group is killed (`user=0.00` on a run that had burned 6 s) —
   hence `run.sh`, which reads per-thread `utime` from `/proc` before
   killing.

### 2.3 Toolchain matrix (`.tmp/matrix.out`, verbatim, one run each; default settings)

    ===== v4.28.0 / PlainRecursion (default settings) =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1802452 Aborted                 (core dumped) "$@"
    exit=134
    ===== v4.28.0 / OverflowInMalloc (default settings) =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1802526:
      tid=1802526 state=S utime_ticks=5 stime_ticks=0 wchan=futex_do_wait
      tid=1802528 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      VmRSS:	   15240 kB
      Threads:	2
    exit=124
    ===== v4.32.2 / PlainRecursion (default settings) =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1812202 Aborted                 (core dumped) "$@"
    exit=134
    ===== v4.32.2 / OverflowInMalloc (default settings) =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1812250:
      tid=1812250 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1812252 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1812253 state=S utime_ticks=590 stime_ticks=34 wchan=futex_do_wait
      VmRSS:	 1057264 kB
      Threads:	3
    exit=124
    ===== v4.33.0 / PlainRecursion (default settings) =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1820024 Aborted                 (core dumped) "$@"
    exit=134
    ===== v4.33.0 / OverflowInMalloc (default settings) =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1820612:
      tid=1820612 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1820614 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1820615 state=S utime_ticks=599 stime_ticks=37 wchan=futex_do_wait
      VmRSS:	 1057348 kB
      Threads:	3
    exit=124
    ===== nightly-2026-08-02 / PlainRecursion (default settings) =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1822336 Aborted                 (core dumped) "$@"
    exit=134
    ===== nightly-2026-08-02 / OverflowInMalloc (default settings) =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1822384:
      tid=1822384 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1822386 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1822387 state=S utime_ticks=580 stime_ticks=31 wchan=futex_do_wait
      VmRSS:	 1057260 kB
      Threads:	3
    exit=124

Derived: the `main` thread's CPU before parking — 4.32.2 5.90 s, 4.33.0
5.99 s, nightly 5.80 s; 4.28.0 0.05 s (initial thread, 8 MiB stack, only
2 threads: `main` not yet run on a dedicated thread in that version).
`PlainRecursion` aborts in ~2 s on every toolchain.

### 2.4 The mechanism (`strace -f -k`)

(a) 4.32.2, `LEAN_STACK_SIZE_KB=65536`, `strace -f -k -e trace=futex,rt_sigaction,mprotect -o trace_k.txt ./OverflowInMalloc`, 20 s timeout, stdout `depth 1000000000`; `trace_k.txt` lines 89–112 verbatim:

    1800902 futex(0x73a14ffff990, FUTEX_WAIT_BITSET|FUTEX_CLOCK_REALTIME, 1800904, NULL, FUTEX_BITSET_MATCH_ANY <unfinished ...>
    1800904 mprotect(0x73a144000000, 135168, PROT_READ|PROT_WRITE) = 0
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__mprotect+0xb) [0x125d4b]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(timer_settime+0x1336) [0xaa146]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(timer_settime+0x1869) [0xaa679]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x24a9) [0xacf99]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x126) [0xad876]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(lean::stack_guard::stack_guard()+0xe) [0x201d5e]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__clone+0x24c) [0x129d6c]
    1800904 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_ACCERR, si_addr=0x73a14bfdfff8} ---
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0xd5f) [0xab84f]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x2635) [0xad125]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(__gmp_default_reallocate+0x14) [0x193864]
    1800904 futex(0x73a144000030, FUTEX_WAIT_PRIVATE, 2, NULL <unfinished ...>
    1800902 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__nptl_death_event+0x181) [0x98e51]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_join+0x173) [0x9e883]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(lean_run_main+0x107) [0x186427]
    1800904 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x2d0) [0xada20]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x12a) [0x9e05a]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(segv_handler+0x35) [0x201ca5]

(Lines 90–97 above also show the arena at `0x73a144000000` being created by the new thread's FIRST `malloc`, inside `lean::stack_guard::stack_guard()+0xe` — the alt-stack `malloc(0x2000)`.)

Reading [AGENT]: fault in glibc `realloc` internals (labels
`__default_morecore+…` are nearest-exported-symbol names) called from
`__gmp_default_reallocate`; the futex word `0x73a144000030` = heap base +
0x30 = `((mstate)(heap_info + 1))->mutex` (glibc 2.35+ `heap_info` is 5 ×
8 B + 8 B pad = 0x30); value 2 = locked-with-waiters; the waiter is the
handler: `segv_handler+0x35` → `pthread_getattr_np+0x12a` → `malloc` →
`__lll_lock_wait_private`.

(b) v4.28.0 default (initial thread), `strace -f -k -e trace=futex`, 15 s timeout, verbatim:

    1847436 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_MAPERR, si_addr=0x7ffc9e1efff8} ---
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x10a) [0xaabfa]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x26c8) [0xad1b8]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.28.0/OverflowInMalloc(__gmp_default_reallocate+0x14) [0x1ebb94]
    1847436 futex(0x777b6c403ac0, FUTEX_WAIT_PRIVATE, 2, NULL) = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x2d0) [0xada20]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(fopen64+0x1f) [0x85f5f]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x266) [0x9e196]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.28.0/OverflowInMalloc(segv_handler+0x35) [0x25d245]

(c) 4.32.2 with `LEAN_MAIN_USE_THREAD=0`, same strace, verbatim:

    1849323 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_MAPERR, si_addr=0x7fff847bbff8} ---
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x590) [0xab080]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x26c8) [0xad1b8]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(__gmp_default_reallocate+0x14) [0x193864]
    1849323 futex(0x79f2ef603ac0, FUTEX_WAIT_PRIVATE, 2, NULL) = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(malloc+0x2d0) [0xada20]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(fopen64+0x1f) [0x85f5f]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x266) [0x9e196]
     > /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/.tmp/rb/v4.32.2/OverflowInMalloc(segv_handler+0x35) [0x201ca5]

`0x777b6c403ac0` / `0x79f2ef603ac0` lie in libc's writable data
(`main_arena.mutex`); the initial-thread branch of `pthread_getattr_np`
opens `/proc/self/maps` (`fopen64` → `malloc`).

### 2.5 Variants (4.32.2; `.tmp/variants.out` and the v2 run, verbatim; H1/H2/H3/H4)

    ===== Variants plain (v4.32.2, default settings) =====
    mode plain depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1834842 Aborted                 (core dumped) "$@"
    exit=134
    ===== Variants bignum (v4.32.2, default settings) =====
    mode bignum depth 1000000000
    TIMEOUT after 60s; threads of pid 1835516:
      tid=1835516 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1835518 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1835519 state=S utime_ticks=593 stime_ticks=35 wchan=futex_do_wait
      VmRSS:	 1057336 kB
      Threads:	3
    exit=124
    ===== Variants bytes (v4.32.2, default settings) =====
    mode bytes depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1867455 Aborted                 (core dumped) "$@"
    exit=134
    ===== Variants ref (v4.32.2, default settings) =====
    mode ref depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1867516 Aborted                 (core dumped) "$@"
    exit=134
    ===== Variants task (Task.spawn; v4.32.2, default settings) =====
    mode task depth 1000000000
    TIMEOUT after 60s; threads of pid 1868594:
      tid=1868594 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1868596 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1868597 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1868598 state=S utime_ticks=589 stime_ticks=32 wchan=futex_do_wait
      VmRSS:	 1059540 kB
      Threads:	4
    exit=124
    ===== Variants cps (v4.32.2, LEAN_STACK_SIZE_KB=65536) =====
    mode cps depth 1000000000
    TIMEOUT after 60s; threads of pid 1870582:
      tid=1870582 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1870584 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1870585 state=S utime_ticks=19 stime_ticks=33 wchan=futex_do_wait
      VmRSS:	  763764 kB
      Threads:	3
    exit=124
    ===== Variants plain (v4.32.2, LEAN_STACK_SIZE_KB=65536) — control for cps =====
    mode plain depth 1000000000

    Stack overflow detected. Aborting.
    .../run.sh: line 15: 1871807 Aborted                 (core dumped) "$@"
    exit=134

### 2.6 H3 knobs and H5 (`.tmp/variants.out`, verbatim; interpreter stack dumps of 10 321 frames elided to their first and last lines)

    ===== H3 main thread: LEAN_MAIN_USE_THREAD=0 PlainRecursion =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1867572 Aborted                 (core dumped) "$@"
    exit=134
    ===== H3 small stack: LEAN_STACK_SIZE_KB=8192 PlainRecursion =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1867614 Aborted                 (core dumped) "$@"
    exit=134
    ===== H3 main thread: LEAN_MAIN_USE_THREAD=0 OverflowInMalloc =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1867656:
      tid=1867656 state=S utime_ticks=5 stime_ticks=0 wchan=futex_do_wait
      tid=1867658 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      VmRSS:	   14840 kB
      Threads:	2
    exit=124
    ===== H3 small stack: LEAN_STACK_SIZE_KB=8192 OverflowInMalloc =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1868421:
      tid=1868421 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1868423 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1868424 state=S utime_ticks=5 stime_ticks=0 wchan=futex_do_wait
      VmRSS:	   17136 kB
      Threads:	3
    exit=124
    ===== H5 interpreter: lean --run OverflowInMalloc.lean =====
    depth 1000000000
    deep recursion was detected at 'interpreter' (potential solution: increase elaboration stack size using the `lean --tstack` flag). This flag can be set in the `
    interpreter stacktrace:
    #1 deep
    …
    #10320 main
    #10321 main._boxed
    
    exit=1
    ===== H5 interpreter: lean --run PlainRecursion.lean =====
    depth 1000000000
    deep recursion was detected at 'interpreter' (potential solution: increase elaboration stack size using the `lean --tstack` flag). This flag can be set in the `
    interpreter stacktrace:
    #1 deep
    …
    #10320 main
    #10321 main._boxed
    
    exit=1
    ===== H5 -O0 build =====
    3
    ===== H5 -O0 PlainRecursion =====
    depth 1000000000
    
    Stack overflow detected. Aborting.
    /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-probe/lean4-runtime-repro/lean_frontend/docs/upstream-tray/lean4/repro/run.sh: line 15: 1870245 Aborted                 (core dumped) "$@"
    exit=134
    ===== H5 -O0 OverflowInMalloc =====
    depth 1000000000
    TIMEOUT after 60s; threads of pid 1870313:
      tid=1870313 state=S utime_ticks=0 stime_ticks=0 wchan=futex_do_wait
      tid=1870315 state=S utime_ticks=0 stime_ticks=0 wchan=ep_poll
      tid=1870316 state=S utime_ticks=232 stime_ticks=34 wchan=futex_do_wait
      VmRSS:	 1057408 kB
      Threads:	3
    exit=124
    ===== variants done =====

### 2.7 The in-project trigger under `strace -k` (secondary evidence; read-only use of the primary checkout's binaries)

`tests/mem-scale-probes/probes/a_zero_global_10000000.c` →
`main.exe --runtime=_build/install/default --cabs-json` (rc 0, 114332 B
JSON) → `timeout 300 capped strace -f -k -e trace=futex,rt_sigaction -o drv_trace.txt env LEAN_ABORT_ON_PANIC=1 cerberus-lean --batch --first g.json`
with `CERB_MEM_MAX=16G`. Result: `Command exited with non-zero status 124`,
stdout empty, stderr only the env banner; `drv_trace.txt` (50 lines) from
the join onwards, verbatim:

    1811515 futex(0x7f359bfff990, FUTEX_WAIT_BITSET|FUTEX_CLOCK_REALTIME, 1811517, NULL, FUTEX_BITSET_MATCH_ANY <unfinished ...>
    1811517 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_ACCERR, si_addr=0x7f355bfffff8} ---
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__default_morecore+0x262c) [0xad11c]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(realloc+0x146) [0xae2e6]
     > /home/dev/projects/cerberus-lean-proj/cerberus-lean/lean_frontend/.lake/build/bin/cerberus-lean(__gmp_default_reallocate+0x14) [0x4d03994]
    1811517 futex(0x7f3554000030, FUTEX_WAIT_PRIVATE, 2, NULL <unfinished ...>
    1811515 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__nptl_death_event+0x181) [0x98e51]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_join+0x173) [0x9e883]
     > /home/dev/projects/cerberus-lean-proj/cerberus-lean/lean_frontend/.lake/build/bin/cerberus-lean(lean_run_main+0x107) [0x4d01e37]
    1811517 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__lll_lock_wait_private+0x2b) [0x98feb]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__libc_calloc+0x3b0) [0xaec50]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_attr_destroy+0x6b) [0x99f5b]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_attr_setaffinity_np+0x60) [0x9a2a0]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_getattr_np+0x1b8) [0x9e0e8]
     > /home/dev/projects/cerberus-lean-proj/cerberus-lean/lean_frontend/.lake/build/bin/cerberus-lean(segv_handler+0x35) [0x4d7fda5]
    1811515 --- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=1811492, si_uid=1000} ---
     > /usr/lib/x86_64-linux-gnu/libc.so.6(__nptl_death_event+0x181) [0x98e51]
     > /usr/lib/x86_64-linux-gnu/libc.so.6(pthread_join+0x173) [0x9e883]
     > /home/dev/projects/cerberus-lean-proj/cerberus-lean/lean_frontend/.lake/build/bin/cerberus-lean(lean_run_main+0x107) [0x4d01e37]

Reading [AGENT]: identical mechanism. Fault inside glibc `realloc` called
from `__gmp_default_reallocate` — a bignum reallocation in the Lean
`Nat`/`Int` runtime on the front end's per-element recursion (strace's
unwinder stops at the GMP frame, so the Lean frame above it is not
named; it does not need to be for the upstream report). Guard page of the
1 GiB `lean_run_main` stack (`si_addr=0x7f355bfffff8`). Lock word
`0x7f3554000030` = a fresh arena heap + 0x30. Handler blocks one call
later than the toy: `pthread_getattr_np+0x1b8` →
`pthread_attr_setaffinity_np+0x60` → `__libc_calloc+0x3b0` →
`__lll_lock_wait_private`. This also explains the pin-bump record's
`d_loop_1000000` movement (abort → hang after a rebuild): a changed
per-level frame layout moves the guard-page touch into or out of a
glibc-malloc frame.

## 3. Verdict and classification [AGENT]

- Standalone reproducer: YES — `repro/OverflowInMalloc.lean` (30 lines,
  no dependencies; `PlainRecursion.lean` control, `Variants.lean`
  brackets). Hang 18/18 (derived count of every run of the
  malloc-per-frame program that reached the guard page: matrix 4,
  `bignum` 1, `task` v1+v2 2, `cps`@64 MiB 1, `LEAN_MAIN_USE_THREAD=0` 1,
  `LEAN_STACK_SIZE_KB=8192` 1, `-O0` 1, four strace'd runs, the first
  60 s timeout run and the `/proc` inspection run 2); controls abort
  loudly 11/11 (matrix 4, `plain` 2, `bytes` 1, `ref` 1,
  `PlainRecursion` under the two H3 knobs 2, `-O0` 1). The three
  OOM-killed drafts (§2.2) are excluded as experiment defects.
- Classification: TRUE BUG, NOT FIXED as of nightly-2026-08-02
  (4.34.0-nightly); no regression range — present in every toolchain
  inspected (v4.13.0 … nightly) by the handler's call sequence, and by
  run on v4.28.0/v4.32.2/v4.33.0/nightly.
- Mechanism in three sentences: `segv_handler` calls `pthread_getattr_np`
  to locate the thread's guard page before it writes anything;
  `pthread_getattr_np` takes the thread descriptor lock and calls
  `realloc`/`free` (cpuset) — or `fopen("/proc/self/maps")` on the
  initial thread — inside the SIGSEGV handler. When the overflowing frame
  is glibc `malloc`/`realloc`/`free` (arena mutex held), the handler's
  allocation waits on the same mutex forever (`futex(arena+0x30,
  FUTEX_WAIT_PRIVATE, 2)`); the "Stack overflow detected" `write` is
  never reached. In Lean any bignum operation puts glibc frames at the
  deepest point of a recursion level, so bignum-per-frame recursions hang
  deterministically and allocation-free (or mimalloc-only) recursions
  abort as designed.
- Remaining unknowns: (i) the exact Lean frame in our driver that
  performs the bignum reallocation (strace's unwinder stops at
  `__gmp_default_reallocate`; a `perf`/`gdb` pass or a `LEAN_STACK_SIZE_KB`
  stage-by-stage probe would name it — it is our recursion, separately
  registered as the process-stack ceiling, not part of the upstream
  report); (ii) whether Lean's handler on non-glibc platforms (macOS,
  musl) has the same exposure — `pthread_getattr_np` is glibc-specific,
  so the macOS path is different code and untested here; (iii) whether
  upstream has since touched `stack_overflow.cpp` after 2026-08-02
  (offline: cannot check).

## 4. Hygiene

- No edits outside `lean_frontend/docs/upstream-tray/lean4/` and this
  record; `INDEX.md` untouched (another worker owns it). The primary
  checkout was used read-only (its built `main.exe` and `cerberus-lean`).
- All runs capped (`CERB_MEM_MAX=8G`, driver `16G`), `ulimit -c 0`
  (the shell's `(core dumped)` annotation is the wait-status flag; no
  core files were written — checked), every run under a timeout; the
  longest single run was the 300 s driver run. Wall-clock for the whole
  slice ≈ 1 h 20 min.
- Scratch (`.tmp/rb/`, `.tmp/driver/`, `.tmp/lrt-*`) is ephemeral and
  gitignored; everything load-bearing is quoted here or in `repro/README.md`.
