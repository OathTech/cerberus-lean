# `atexit` handlers do not run when `main` returns (they do run on `exit()`)

**Merged 2026-11-06 into [24-stdio-buffer-not-flushed-at-exit.md](24-stdio-buffer-not-flushed-at-exit.md)** — one
mechanism (the driver's `Step_done2` arm ends the program without entering the library's `exit`), one patch, one
filing; fixed in the fork on 2026-11-06 (contract D15; record `lean_frontend/docs/2026-11-05_stdio-exit-flush-record.md`;
witness `scripts/check_stdio_exit.sh`, `atexit_on_return` is this report's reproducer: gcc's `m21`, status 4, on both
engines). The original draft's text (reproducer `tests/noodle-probes/lib/lib_atexit_order.c`, C11 5.1.2.2.3 and
7.22.4.4#3, the verbatim pre-fix lines) is in the merged report's Description and Reproducers.
