# Draft — Lean 4 runtime: stack overflow on the `lean_run_main` thread can deadlock inside the SIGSEGV handler instead of aborting

Target: `leanprover/lean4` (runtime). Drafted 2026-09-02 (arc/mem-scale
S0); NOT filed — filing is the operator's call (network + GitHub).
Classification: **TRUE BUG (runtime; fail-open by silence)** — a stack
overflow that should end the process with "Stack overflow detected.
Aborting." instead leaves it blocked forever on a futex with no output
and no exit. Evidence: `lean_frontend/docs/2026-09-01_mem-scale-profile.md`
§6.2–6.3 (first-hand strace, size bisection, stack-size experiment).

## Environment

- Lean `leanprover/lean4:v4.32.2` (release toolchain, x86_64 Linux,
  glibc; kernel 7.0.0), executable built by `lake build` from a
  compiled-to-C Lean program (this project's `cerberus-lean` driver).
- Deterministic: 8/8 reproductions across two sessions (5 standalone
  runs + 3 sweep runs), independent of `LEAN_ABORT_ON_PANIC`.

## What happens

A deeply non-tail-recursive computation (one closure-application frame
per list element, ~8 × 10^6 elements) overflows the 1 GiB stack of the
thread that `lean_run_main` spawns to run `main`. The runtime's
guard-page `SIGSEGV` fires as designed — and then the handler blocks on
a contended lock and never returns. Both threads sit in `futex` until
killed. `strace -f -e trace=futex,rt_sigaction,mmap,mprotect`, excerpt
verbatim (tid 2456378 = process main thread, 2456380 = the runtime
thread running `main`):

```
2456378 mmap(NULL, 1073745920, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x7f316bfff000
2456378 mprotect(0x7f316c000000, 1073741824, PROT_READ|PROT_WRITE) = 0
2456378 futex(0x7f31abfff990, FUTEX_WAIT_BITSET|FUTEX_CLOCK_REALTIME, 2456380, NULL, FUTEX_BITSET_MATCH_ANY <unfinished ...>
2456380 mmap(0x415e8000000, 1073741824, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_NORESERVE, -1, 0) = 0x415e8000000
2456380 --- SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_ACCERR, si_addr=0x7f316bfffff8} ---
2456380 futex(0x7f3164000030, FUTEX_WAIT_PRIVATE, 2, NULL <unfinished ...>
2456378 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
2456380 <... futex resumed>)            = ? ERESTARTSYS (To be restarted if SA_RESTART is set)
```

Reading: the 1 GiB `MAP_STACK` region has its guard page at
`0x7f316bfff000–0x7f316c000000`; the fault address `0x7f316bfffff8` is
8 bytes inside that page — a genuine stack overflow. The faulting
thread's very next syscall, from inside the signal handler, is a
`FUTEX_WAIT_PRIVATE` on a lock word in state 2 (glibc lowlevellock
"locked with waiters") that is never released. The string "Stack
overflow detected. Aborting." IS present in `libleanshared.so` and is
printed on the ordinary overflow path (see "What works" below), so the
handler is being entered but blocks before/while printing.

Working hypothesis (not confirmed — we could not attach a debugger in
this sandbox): the fault landed while the thread held a non-reentrant
lock (the glibc malloc arena lock or a stdio `FILE` lock are the usual
suspects; `lean_alloc_object` for objects above the small-object limit
goes through `malloc`), and the handler's report path re-acquires the
same lock — a classic async-signal-safety violation in a SIGSEGV
handler. The handler should use only async-signal-safe calls
(`write(2)` to a pre-formatted buffer, then `_exit`/`abort`), never
`std::cerr`/`fprintf`/anything that may allocate or lock.

## Onset moves with the stack size (so it is the overflow path, not a resource limit)

Size bisection on the same program shape (`char g[N]` static
zero-initialised array; our front end maps over its N elements with a
non-tail monadic `mapM`), Lean `--first`, rows verbatim from
`tests/mem-scale-probes/results/2026-09-01_hang-bisect.tsv` and
`…/2026-09-02_hang-stackexp.txt`:

```
a_zero_global_7000000	nolibc	lean-first	0	20.86	4951452	VAL:Specified(7)	-
a_zero_global_8000000	nolibc	lean-first	124	90.20	2658428	NONE	TIMEOUT(90s);
stackexp	8M	LEAN_STACK_SIZE_KB=1048576	Command exited with non-zero status 124 wall=90.09 maxrss=2658956 exit=124
stackexp	8M	LEAN_STACK_SIZE_KB=4194304	Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"} wall=22.50 maxrss=5967020 exit=0
stackexp	5M	LEAN_STACK_SIZE_KB=2048	Command exited with non-zero status 124 wall=90.00 maxrss=235232 exit=124
stackexp	5M	LEAN_STACK_SIZE_KB=512	Command exited with non-zero status 124 wall=90.00 maxrss=231716 exit=124
```

At the default 1 GiB stack 7 M elements complete and 8 M hang; at 4 GiB
(`LEAN_STACK_SIZE_KB=4194304`) 8 M completes; at 2 MB / 0.5 MB the 5 M
case (which completes at the default) hangs instead — parking after
~0.2 GB RSS, i.e. very early. The hung processes burn ~3–4 s of CPU
and then zero (`HANG(cpu 3.29s of 400.12s wall)` under our harness's
classifier); RSS plateaus at a size-independent ~2.7 GB.

## What works (the loud path) — standalone attempt, negative result

A minimal standalone program with the same recursion shape overflows
and aborts LOUDLY as designed, so the deadlock is NOT the plain
overflow path; it needs the fault to land while a lock is held. Kept
here because it is the shape the report is about and because the
negative result narrows the search:

```lean
-- Repro.lean — lakefile: [[lean_exe]] name = "repro", root = "Repro"
structure M (α : Type) where
  run : Nat → Except String (α × Nat)
instance : Inhabited (M α) := ⟨⟨fun _ => .error "uninhabited"⟩⟩

@[inline] def M.pure (a : α) : M α := ⟨fun s => .ok (a, s)⟩
def M.bind (m : M α) (f : α → M β) : M β :=
  ⟨fun s => match m.run s with
    | .error e => .error e
    | .ok (a, s') => (f a).run s'⟩

partial def mapM (f : α → M β) : List α → M (List β)
  | [] => M.pure []
  | x :: xs => M.bind (f x) fun z => M.bind (mapM f xs) fun zs => M.pure (z :: zs)

def main (args : List String) : IO Unit := do
  let n := args.head!.toNat!
  match (mapM (fun (i : Nat) => M.pure (i + 1)) (List.replicate n 0)).run 0 with
  | .ok (l, _) => IO.println s!"ok {l.length}"
  | .error e => IO.println s!"error {e}"
```

```
$ .lake/build/bin/repro 1000000
ok 1000000
$ .lake/build/bin/repro 10000000

Stack overflow detected. Aborting.
Command terminated by signal 6
```

A variant allocating a large `ByteArray` (8 KB–70 KB, malloc path) per
element also did not deadlock in 3 trials each (it ran out the 60 s
timeout page-faulting at 35–94 GB RSS, cpu/wall 0.4–0.9 — slow, not
hung). So the deadlock needs a specific interleaving that our driver
hits deterministically and this toy does not.

## Reproducer (in-project, deterministic)

Until a standalone trigger is isolated, the reproducer is this
project's driver at the commit named in the arc record
(`lean_frontend/docs/2026-09-02_mem-scale-record.md`, "pre-fix
binary"), which the same record shows COMPLETING after the recursion
is made tail-position (the arc's S1' fix) — i.e. the recursion is ours
to fix, the silent handler is the runtime's:

```
$ cat tests/mem-scale-probes/probes/a_zero_global_10000000.c
char g[10000000];
int main(void) {
  g[10000000 - 1] = 7;
  return g[10000000 - 1] + g[0];
}
$ _build/default/backend/driver/main.exe --runtime=_build/install/default --cabs-json a_zero_global_10000000.c > g.json
$ timeout 400s lean_frontend/.lake/build/bin/cerberus-lean --batch --first g.json
(no output; exit 124 after 400 s; ~3.3 s of CPU consumed in total)
```

For contrast, OCaml on the equivalent recursion with a limited stack
(`OCAMLRUNPARAM=l=200000`) fails in 0.03 s with a backtrace (exit 125):
same ceiling class, opposite loudness.

## Proposed remedy

1. Make the stack-overflow `SIGSEGV` handler async-signal-safe: report
   via `write(2)` of a static message and terminate with `_exit`/
   `abort()`; do not allocate, do not take stdio or allocator locks. If
   the handler currently formats through `std::cerr` (or any locked
   stream), that is the likely culprit.
2. Optionally, as defence in depth: a watchdog that converts "handler
   did not terminate the process within N ms" into `abort()`, so a
   second-order failure inside the handler can never be silent.

## Provenance

Found and analysed by an AI agent (Claude) working on this project's
differential-validation harness; the strace excerpt and all measured
rows are verbatim from recorded runs (files cited above). Per this
tray's labeling policy, the filed issue body must carry an explicit
AI-provenance note.
