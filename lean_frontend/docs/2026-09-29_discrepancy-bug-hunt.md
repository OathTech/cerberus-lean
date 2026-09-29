# Discrepancy bug hunt, 2026-09-29: consolidated record

Branch `audit/bug-hunt-20260929`, base `f6fc60d4b` (mainline `mdd/cerberus-lean`). Seven hunters ran in parallel: six had
a set brief (area in §6), plus one free "noodler" with no brief, added at the operator's request ([USER 2026-09-29]
"we might want an extra 'noodler' with no spicific brief, just go wherever seems interesting"). One consolidator
[AGENT] deduplicated the findings, re-ran every one itself, and classified them against `CONTRACT.md` §1 and
`VALIDATION.md` §1–§3. Nothing was built and no other tracked file was edited. **Choosing fixes is left to the
operator.** This record lists options only.

Class vocabulary (from the consolidation brief):
- **BUG**: a served difference, i.e. the contract's "fifth outcome". Also used for a Lean failure where the oracle
  answers without a feature-naming refusal.
- **CLASS_A**: both engines fail and only the message text differs (VALIDATION §1(a)).
- **CLASS_B**: the oracle does not finish and Lean fails.
- **KNOWN**: an already named deviation (N1/N2), an ISO-fix register row (R1–R3), a documented refusal, or a listed
  open item in VALIDATION §2b/§3.
- **ORACLE_ISO**: both engines agree, and ISO C disagrees with both.

Every classification is an [AGENT] judgement by the consolidator unless it is marked otherwise.

## 1. Summary

Counts (derived tallies, after deduplication; one row per mechanism):

| Class | Count | Notes |
|---|---|---|
| BUG | 6 | all reproduced by the consolidator; ranked in §2 |
| KNOWN | 5 | all reproduced; two of them carry scope or record findings (R2 crash form; the CONTRACT/VALIDATION disagreement on Z1-A1) |
| CLASS_A | 5 | all reproduced |
| CLASS_B | 1 | NOT RE-RUN (see §4.3) |
| ORACLE_ISO | 21 | 2 spot-checked, both confirmed; the rest are hunter-reported |
| NOT REPRODUCED | 0 | |

Raw hunter findings before deduplication: 30 finding objects (derived count). Three hunters independently found the
Invalid_format byte finding, two the library-location finding, two the libc-dump float finding, two the non-UTF-8
file-name finding, four the R2 widening, and three Z1-A1.

Core semantics (generated from Lem) plus CerbMem held on every ordinary probe. Nondeterminism multiplicities, addresses,
layout, UB kinds and linking all matched. All six BUGs sit at **seams where Lean re-interprets data**: oracle-produced
text (the libc Core dump), paths (runtime lookup, library-location test), the batch printer, or the Cabs JSON bridge.
The one exception is the funptrmap finding, where the ORACLE is the side that errs. This is the same seam profile as
the pathleak bug.

## 2. Ranked BUG list

The ranking is by (likelihood that a real program or deployment hits it) × (how silently wrong the answer is)
[AGENT].

### BUG-1: libc-mode function-pointer identity: the oracle's number-keyed funptrmap conflates a user function with a libc static that has the same symbol number; Lean does not

- Source: the cerbmem hunter.
- Likelihood: low to moderate. It needs a libc-mode program large enough that a user function's symbol number lands
  on one of the few libc statics whose pointers sit in memory (stdio `close`/`seek`/`read`/`write` = 1852..1868). The
  function must also be stored as a pointer. Programs the size of the libxml2 lane are in range.
- Silence: high. The verdict itself differs. In the witness the ORACLE reports a spurious UB041 and Lean serves the
  ISO-correct answer. If the signatures were compatible, the oracle would silently call the wrong function (not
  located; see §6 cerbmem not-covered).

Witness (`b5_fp_conflate.c`):
```c
#include <stdio.h>
/* 1212 dummy globals: in the oracle's libc mode each consumes one symbol id, which moves g's
   id onto the id that the precompiled libc gives the static __stdout_write (1868). */
#define A(x) int x##0, x##1, x##2, x##3, x##4, x##5, x##6, x##7, x##8, x##9;
#define B(x) A(x##0) A(x##1) A(x##2) A(x##3) A(x##4) A(x##5) A(x##6) A(x##7) A(x##8) A(x##9)
#define C(x) B(x##0) B(x##1) B(x##2) B(x##3) B(x##4) B(x##5) B(x##6) B(x##7) B(x##8) B(x##9)
C(d) B(e) B(f) A(h) int k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
int calls;
size_t g(FILE *f, const unsigned char *s, size_t l) { calls++; return l; }
int main(void) {
  size_t (*fp)(FILE *, const unsigned char *, size_t) = g;  /* storing fp registers g's id in the funptrmap */
  fputs("via fputs\n", stdout);   /* libc loads stdout->write from memory and calls it */
  fflush(stdout);
  return calls + (fp == g);
}
```
Consolidator re-run, `run_both.sh b5_fp_conflate.c --libc --first --timeout 300`:
```
== ORACLE rc=1
      1 Undefined {ub: "UB041_function_not_compatible", stderr: "", loc: "<295:18--295:35>"}
== LEAN rc=0
      1 Defined {value: "Specified(1)", stdout: "via fputs\n", stderr: "", blocked: "false"}
```
Control: the same program without the `C(d) B(e) B(f) A(h) int k0…` line (`b5_ctl.c`, same flags):
```
== ORACLE rc=0
      1 Defined {value: "Specified(1)", stdout: "via fputs\n", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(1)", stdout: "via fputs\n", stderr: "", blocked: "false"}
```
Numbering calibration: the hunter's `fpd_0.c` prints `stdout->write`'s stored number and `g`'s number, same flags. The
printed numbers are themselves N1 territory.
```
== ORACLE rc=0
      1 Defined {value: "Specified(0)", stdout: "write=1868 g=656\nvia fputs\n", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(0)", stdout: "write=12778 g=37635\nvia fputs\n", stderr: "", blocked: "false"}
```

Mechanism:
- The funptrmap is keyed by the symbol NUMBER alone: `memory/concrete/impl_mem.ml:1206` `IntMap.add (Z.of_int n)
  (file_dig, name) funptrmap`. `abst` rebuilds the symbol from that one entry, under upstream's own FIXME at `:1044`: "A
  function pointer with the same id in different files might exist".
- `CerbMem.memValueToBytes`/`reconstructValue` mirror this (`CerbMem.lean:733-742`, `funptrmap` field `:167`).
- The engines number symbols differently. The oracle's libc ids were drawn when `libc.co` was compiled, in another
  process, and the program's ids come from a fresh counter that starts low, so the two ranges overlap. Lean draws both
  from one supply, so its ranges never meet.
- Sequence in the oracle: `__stdout_FILE`'s initialiser registers 1868 as `__stdout_write`. Storing `fp = g` (id 1868)
  overwrites that entry. `fputs` loads `f->write` (`stdio.c:295`) and gets `g`, and calling it is UB041.
- N1 covers only an OBSERVED function number. Here no number is observed, but function IDENTITY changes, so N1 as
  written does not cover this. The root cause is the same (the fresh-supply artefact), combined with the number-only
  key.

Fix options (operator decision):
- (a) Named deviation next to N1 (Lean ISO-right, oracle artefact), plus an upstream-tray entry for the FIXME.
- (b) Mirror: reproduce the oracle's libc/program numbering overlap. This is a numbering dependency that the §5
  renumbering principle calls a defect, and it would make Lean wrong.
- (c) Refuse loudly: detect a funptrmap key collision in Lean. Lean's numbers never collide, so Lean cannot see the
  oracle's collision. No precise refusal is known.

### BUG-2: Lean reads `std.core` and the `.impl` file from the current directory, unpinned; a different std.core there is used silently

- Source: the noodler.
- Likelihood: low for the lanes (`run_both`/lanes fix the cwd). It is real for consumers and for this box, where many
  worktrees exist. Running a binary from inside another checkout, or a branch that edits `std.core` (e.g. an SC branch),
  silently gives that tree's semantics.
- Silence: total. Nothing is printed.

Witness (`b6_ub2.c`):
```c
int main(void) {
  double d = 1e30;
  int x = (int)d;
  return x;
}
```
Consolidator re-run.
- `run_both.sh b6_ub2.c` (unmodified runtime):
```
== ORACLE rc=1
      1 Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}
== LEAN rc=1
      1 Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}
```
- Planted cwd: `runtime/libcore/impls` copied, and `std.core` copied with one line changed. `diff runtime/libcore/std.core
  planted`:
```
90c90
<           undef(<<UB017_out_of_range_floating_integer_conversion>>)
---
>           Specified(7)
```
- The same JSON through the same binary, first from the planted cwd and then from the worktree root:
```
##### Lean from cwd=consolidate/cwd (planted std.core)
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
##### Lean from cwd=worktree root (same json)
Undefined {ub: "UB017_out_of_range_floating_integer_conversion", stderr: "", loc: "<3:11--3:17>"}
rc=1
```
The planted tree was deleted after the probe.

Mechanism:
- `lean_frontend/Main.lean:476-486` `findRuntimeDir` probes `runtime/libcore`, `../runtime/libcore` and
  `../../runtime/libcore` relative to the cwd, and the first one found wins.
- `runPipeline` reads `<dir>/std.core` (`:912`) and `<dir>/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl` (`:927`).
  There is no hash, no pin, and no anchoring to the binary.
- The oracle uses its installed runtime (`--runtime`, `Cerb_runtime`).
- By contrast, `libc.core` is drift-checked by sha256 in `scripts/libc_prep.sh`.
- The same fail-open lookup also feeds BUG-3: the library-location test cannot know the real runtime root because none
  is plumbed.

Classification [AGENT]: configuration-level BUG, a fail-open lookup. No single C program shows it under the fixed
harness.

Fix options:
- (a) Anchor the lookup to the binary's location or a build-time constant, and refuse loudly if absent.
- (b) Require an explicit `--runtime` (mirroring the oracle's flag).
- (c) Hash-pin `std.core` and the `.impl` the way `libc.core` is pinned, and refuse on mismatch.

### BUG-3: `isLibraryLocation` matches a directory SUFFIX; a user file or header under any `…/runtime/libcore`, `…/runtime/libcore/impls` or `…/runtime/libc/include` directory is treated as library code, and the UB location differs

- Sources: the frontend hunter and the noodler.
- Likelihood: low. It needs a `#line` naming such a path, or a user tree containing such a directory. One `#line` is
  enough.
- Silence: medium. The UB kind agrees, but the location is wrong, and VALIDATION counts the UB location as behaviour.

Witnesses:
```c
/* b3_ln03.c */
#line 1 "lib/runtime/libcore/gen.c"
int main(void) {
  int x = 2147483647;
  return x + 1;
}
/* b3_f06_hdr.c, with runtime/libc/include/myhelp.h = "static int add1(int x) { return x + 1; }" */
#include "runtime/libc/include/myhelp.h"
int main(void) {
  return add1(2147483647);
}
/* runtime/libcore/liblocub.c (the file itself lives in such a directory) */
int f(int x) {
  return x + 1;
}
int main(void) {
  int y = 0;
  y = 3;
  return f(2147483647);
}
/* runtime/libcore/liblocmem.c: int *p = 0; int a = 1; a = a + 1; return *p; (from the noodler's scratch, 5 lines) */
```
Consolidator re-runs, `run_both.sh FILE.c` (default: nolibc, exhaustive):
```
##### b3_ln03.c (default)
== ORACLE rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<3:10--3:15>"}
== LEAN rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<other location: Driver.drive>"}
##### b3_f06_hdr.c (default)
== ORACLE rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:33--1:38>"}
== LEAN rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<3:10--3:26>"}
##### runtime/libcore/liblocub.c (default)
== ORACLE rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:10--2:15>"}
== LEAN rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<other location: Driver.drive>"}
##### runtime/libcore/liblocmem.c (default)
== ORACLE rc=1
      1 Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<5:10--5:12>"}
== LEAN rc=1
      1 Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<other location: Driver.drive>"}
```

Mechanism:
- Lean: `lean_frontend/CerbLocation.lean:217-222` tests `dir == d || dir.endsWith ("/" ++ d)`.
- Oracle: `util/cerb_location.ml:512-523` tests exact membership of `Filename.dirname path` in the three
  `Cerb_runtime.in_runtime` directories.
- A library location is skipped when `current_loc` is updated and is swapped out in UB reports (`core_eval.lem:602`,
  `core_run.lem:477/782`). A user file so classified therefore never sets a C location.
- The residual is documented only in code, as "Z-67" (`CerbLocation.lean:203-212`). It is not in CONTRACT, VALIDATION
  §2b/§3 or any lane.

Fix options:
- (a) Mirror: plumb the runtime root (the mover named in code; shares its root cause with BUG-2) and test exact
  equality.
- (b) Refuse loudly when a user-TU location is suffix-classified library.
- (c) Named deviation in §2b.

### BUG-4: the Invalid_format UB payload: format bytes >= 0x80 are printed raw by the oracle and UTF-8-encoded by Lean

- Sources: the numbers, strings and adversarial hunters.
- Likelihood: moderate. `%e`/`%g`/`%a` are Invalid_format in both engines (thin-surface O5), and a format string with
  non-ASCII text (`"température %e"`) triggers it.
- Silence: low. The UB kind and location agree, and only the payload bytes inside the `ub:` field differ. A
  byte-comparing lane records a DIFF. By the VALIDATION §1(a) test this is not class (a), because both sides serve an
  Undefined verdict and neither fails.

Witnesses:
```c
/* b1_if1.c */  #include <stdio.h>
int main(void) { return printf("\xe9\"\\\t%e", 1.0); }
/* b1_ib03.c */ int main(void){ printf("\xff%y", 1); return 0; }            (with #include <stdio.h>)
/* b1_ib04.c */ int main(void){ printf("caf\xc3\xa9 %y", 1); return 0; }    (with #include <stdio.h>)
/* b1_s02.c */  int main(void) { char f[] = {'%', 'd', (char)0xe9, '%', (char)0x80, 0}; return printf(f, 5, 6); }  (with #include <stdio.h>)
```
Consolidator re-run with `run_both.sh` (default flags). Shown through `cat -v`. For three of the four, run_both's grep
printed no oracle line because the line is not valid UTF-8.
```
##### b1_if1.c (default)
== ORACLE rc=1
grep: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/run.u19Nla/o.out: binary file matches
== LEAN rc=1
      1 Undefined {ub: "Invalid_format[M-CM-)"\	%e]", stderr: "", loc: "<2:25--2:52>"}
##### b1_ib04.c (default)
== ORACLE rc=1
      1 Undefined {ub: "Invalid_format[cafM-CM-) %y]", stderr: "", loc: "<2:17--2:44>"}
== LEAN rc=1
      1 Undefined {ub: "Invalid_format[cafM-CM-^CM-BM-) %y]", stderr: "", loc: "<2:17--2:44>"}
```
The bytes were checked by hand with the consolidator's `raw.sh` (nolibc, exhaustive, `od -c` of each engine's stdout).
The first two lines of each dump:
```
##### raw b1_if1.c
-- oracle stdout (od -c, Time line dropped):
0000000   U   n   d   e   f   i   n   e   d       {   u   b   :       "
0000020   I   n   v   a   l   i   d   _   f   o   r   m   a   t   [ 351
-- lean stdout (od -c):
0000000   U   n   d   e   f   i   n   e   d       {   u   b   :       "
0000020   I   n   v   a   l   i   d   _   f   o   r   m   a   t   [ 303
0000040 251   "   \  \t   %   e   ]   "   ,       s   t   d   e   r   r
##### raw b1_ib03.c
-- oracle stdout: 0000020   I   n   v   a   l   i   d   _   f   o   r   m   a   t   [ 377
-- lean stdout:   0000020   I   n   v   a   l   i   d   _   f   o   r   m   a   t   [ 303
                  0000040 277   %   y   ]   "   ,  ...
##### raw b1_ib04.c
-- oracle stdout: 0000040   a   f 303 251       %   y   ]   "   ,       s   t   d   e   r
-- lean stdout:   0000040   a   f 303 203 302 251       %   y   ]   "   ,       s   t   d
##### raw b1_s02.c
-- oracle stdout: 0000040   d 351   % 200   ]   "   ,       s   t   d   e   r   r   :
-- lean stdout:   0000040   d 303 251   % 302 200   ]   "   ,       s   t   d   e   r   r
```
(For b1_ib03/ib04/s02, only the differing od rows are shown. The rows are verbatim; the "-- oracle stdout:" prefixes
are condensed. All four runs had rc=1 on both engines.)

Mechanism:
- `formatted.lem:845/859/874` builds `U.Invalid_format (String.toString frmt)` from the format chars in memory. In Lean
  these are byte-carrier Chars, one per C byte (CabsImport `getByteStr`).
- `undefined.lem:1103` renders it as `"Invalid_format[" ^ str ^ "]"`.
- Lean prints the `ub:` field unescaped (`Main.lean:557/589/1101`, `IO.println s!"Undefined \{ub: …"`), so each
  carrier Char >= 0x80 becomes two UTF-8 bytes. OCaml writes the byte itself.
- The stdout/stderr fields go through `CerbEscape.byteChars` and agree for every byte 1..255 (measured by the numbers
  hunter).
- Invalid_format is the only UB constructor that carries program data (`undefined.lem:530`; `DUMMY` is always a
  literal).
- Related to thin-surface O5 (the payload is unescaped, so a newline breaks the record), but O5 does not name the
  encoding difference.

Fix options:
- (a) Mirror: print the `ub:` payload as bytes (the carrier-Char to byte encoding already used for stdout/stderr).
- (b) Named deviation, as a printer or instrument artefact.
- (c) Refuse: serve a refusal when an Invalid_format payload holds a char >= 0x80.

### BUG-5: the libc Core text dump rounds floats to 12 significant digits; decfloat's `0x1p64` becomes `1.84467440737e+19`, so Lean's strtod sets `errno = ERANGE` where the oracle does not

- Sources: the frontend hunter and the noodler.
- Likelihood: very low today. The pinned libc has no `math.c`, so the program must define `fabs`, `scalbn`,
  `scalbnl`, `copysignl` and `fmodl` itself, and the input must fall in a ~2^23-wide window near `DBL_MAX`. It becomes
  reachable by ordinary programs as soon as libm is linked into libc mode.
- Silence: high. The errno differs silently.

Witnesses: `b2_lb09.c` is the frontend hunter's witness, reproduced verbatim:
```c
#include <stdlib.h>
#include <errno.h>
double fabs(double x) { return x < 0 ? -x : x; }
double scalbn(double x, int n) {
  while (n > 0) { x *= 2.0; n--; }
  while (n < 0) { x *= 0.5; n++; }
  return x;
}
long double scalbnl(long double x, int n) { return scalbn(x, n); }
long double copysignl(long double x, long double y) { return y < 0 ? -fabs(x) : fabs(x); }
long double fmodl(long double x, long double y) {
  long double q = x / y;
  long long t = (long long)q;
  return x - (long double)t * y;
}
int main(void) {
  errno = 0;
  double d = strtod("1.7976931348619072e+308", 0);
  return (errno == ERANGE) * 10 + (d == 0x1.ffffffffff8p+1023) + 100 * (d > 1.7e308);
}
```
`b2_lb10.c` is the same program with `"1.5e+308"` as the control. `b2_sd5.c` is the noodler's instrumented version:
`fabs` and `scalbnl` print their argument's bits, and the input is `"1.7976931348619e308"`.

Consolidator re-runs, `run_both.sh FILE.c --libc --first --timeout 300`. The exhaustive mode times out on both engines
(hunter-measured at 280 s). The program has one deterministic result, so `--first` is argued sound for it but was not
measured.
```
##### b2_lb09.c --libc --first --timeout 300
== ORACLE rc=0
      1 Defined {value: "Specified(101)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(111)", stdout: "", stderr: "", blocked: "false"}
##### b2_lb10.c --libc --first --timeout 300
== ORACLE rc=0
      1 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
##### b2_sd5.c --libc --first --timeout 300
== ORACLE rc=0
      1 Defined {value: "Specified(0)", stdout: "fabs 43effffffffff800 0\nscalbnl 43effffffffff800 960\nerrno=0 big=1\n", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(0)", stdout: "fabs 43effffffffff800 0\nscalbnl 43dffffffffff800 961\nerrno=3 big=1\n", stderr: "", blocked: "false"}
```

Mechanism:
- Lean's `--libc` bodies come from `tests/libc/libc.core`, the oracle's pretty-print of `libc.co`. It prints floats
  with `string_of_float` (= `%.12g`, `ocaml_frontend/pprinters/pp_core.ml:282-284`).
- `runtime/libc/src/internal.c:303` is `if (fabs(y) >= CONCAT(0x1p, LDBL_MANT_DIG))`, i.e. 2^64. The dump prints it as
  `pure(Specified(1.84467440737e+19)) in` (libc.core:60849). The value parsed back is below 2^64.
- For y = 2^64 − 2^22, only Lean takes the branch (`y *= 0.5; e2++`), and the ERANGE check at `:309` fires. The returned
  value is the same.
- Prior record: `CoreParser.lean:95-103`, Z2-CP-02 ("DECLARED INSTRUMENT boundary … Not settled by probe"). That note
  names FLT_MAX at `libc.core:41698` as the lossy constant. FLT_MAX is not lossy: `3.40282347e+38` is its source
  spelling and round-trips.
- Both hunters' grep census of every float literal in the dump finds `0x1p64` to be the ONLY lossy one. This is the
  first measured served difference from that boundary, and the boundary is not in VALIDATION §2b/§3 or CONTRACT.

Fix options:
- (a) Mirror: regenerate the pin with an exact float printer (`%.17g`/`%h`) in `scripts/libc_prep.sh` (the mover named
  in code). This changes how the pin artefact is produced, not the semantics.
- (b) A gate that every float literal in `libc.core` round-trips (plant-tested), plus a named deviation until then.
- (c) Also correct the Z2-CP-02 in-code note (wrong constant).

### BUG-6: a non-UTF-8 byte in a file name (a real path, `#line` or an `#include` name) makes the Cabs JSON invalid UTF-8; Lean dies with an uncaught exception where the oracle answers

- Sources: the frontend and strings hunters.
- Likelihood: low. It needs Latin-1 file names or `#line` text.
- Silence: none. The failure is loud. It is ranked last because it is fail-noisy, but it is not a feature-naming
  refusal (CONTRACT §1(2)), and the file-name member is not in the §3(b) row, which lists only EDecl_magic text and
  attribute strings.

Witnesses:
- `b4_ln01.c`: `#line 1 "caf<0xE9>.c"` (raw byte) followed by `int main(void) { return 3; }`.
- `b4_s15.c`: `#line 1 "caf\351.c"`, which is ASCII in the source; cpp decodes the escape to a raw byte. It is followed
  by `int x = 2147483647; return x + 1;`.
- `b4_caf<0xE9>.c`: a file whose own name holds the raw byte, containing `int main(void) { return 4; }`.

Consolidator re-runs (`run_both.sh`, default flags):
```
##### b4_ln01.c (default)
== ORACLE rc=0
      1 Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=1
##### b4_s15.c (default)
== ORACLE rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:30--2:35>"}
== LEAN rc=1
##### b4_cafM-i.c (default)
== ORACLE rc=0
      1 Defined {value: "Specified(4)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=1
```
Lean stderr from `raw.sh` (the run directory is shown as RUNDIR), for b4_ln01 and b4_s15:
```
uncaught exception: Tried to read file 'RUNDIR/p.json' containing non UTF-8 data.
```

Mechanism: `backend/lean_export/cabs_json.ml:30` writes `Cerb_position.file` as `` `String ``, and `:44` writes
`Loc_other` the same way. Yojson copies bytes >= 0x80 raw, and `IO.FS.readFile` in Main throws. This is the same class
as the documented §3(b) row "Non-UTF-8 bytes in a TEXT field of the Cabs JSON", minus its listing.

Fix options:
- (a) Byte-carrier encoding for the file-name and `Loc_other` fields (`json_of_bytes` plus CabsImport `getByteStr`),
  as for literals since 2026-09-11.
- (b) Catch the read failure and refuse with a feature-naming message.
- (c) Extend the §3(b) row to list file names (documentation only; the row itself is class (b)).

## 3. KNOWN findings (all reproduced)

### K-1: ISO-fix register R2 is wider than its written scope: high bytes and a crash form

- Sources: the numbers, libc, strings and adversarial hunters.
- R2 (VALIDATION §2) is ADMITTED [USER 2026-09-03], and Lean is right. Its text and its single witness
  (`g5-escape-roundtrip`) cover only `%c` of 127 → 87.
- The same mechanism, `formatted.lem:794-805` `store_chars_in_array` using decimal `Char.escaped` read back as octal by
  `decode.ml:184-197`, also does two more things:
  - (a) It silently corrupts every stored byte >= 128 and every control byte (200 → 128, 255 → 173, 128 → 88, 25 → 21).
  - (b) It CRASHES the oracle (rc 125) on any byte whose decimal escape contains a 9: 19, 29, 139, 149, …, 190–199, and
    0xC3 = 195, the usual UTF-8 lead byte, so any Latin-1 text through `sprintf("%s")` crashes it. Lean serves a value
    in these cases.
- Classification [AGENT]: KNOWN (R2). Record finding: the register text and witness list do not mention the crash form
  or the high-byte form. Options: widen R2's stated scope and add a crash-form witness row.

Consolidator re-runs (`--libc --first --timeout 300`). The oracle's "uncaught exception" line is quoted with its ANSI
colour escapes removed; everything else is verbatim.
```
##### r2a.c    [char src[2] = { (char)200, 0 }; snprintf(buf, 8, "%s", src); return buf[0];]
== ORACLE rc=0
      1 Defined {value: "Specified(-128)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(-56)", stdout: "", stderr: "", blocked: "false"}
##### r2b.c    [snprintf(buf, 8, "%c", 19); return buf[0];]
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: 019")
== LEAN rc=0
      1 Defined {value: "Specified(19)", stdout: "", stderr: "", blocked: "false"}
##### sp1_3.c  [sprintf(b, "%s", {0xC3,0xA9,0}); return n*1000 + hash]
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: 195")
== LEAN rc=0
      1 Defined {value: "Specified(2534)", stdout: "", stderr: "", blocked: "false"}
##### sp2.c    [sprintf "%c" of 200, -1, 128, 0x141, printing the stored bytes]
== ORACLE rc=0
      1 Defined {value: "Specified(0)", stdout: "n=1 128 0 1 1\nn=1 173 0 1 1\nn=1 88 0 1 1\nn=1 65 0 1 1\n", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(0)", stdout: "n=1 200 0 1 1\nn=1 255 0 1 1\nn=1 128 0 1 1\nn=1 65 0 1 1\n", stderr: "", blocked: "false"}
##### p08.c    [snprintf(b, 8, "%c%c", 0x13, 0x19); return n*1000 + b[0]*10 + b[1];]
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: 019")
== LEAN rc=0
      1 Defined {value: "Specified(2215)", stdout: "", stderr: "", blocked: "false"}
##### p09.c    [sprintf "%c" of 25]
== ORACLE rc=0
      1 Defined {value: "Specified(1021)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(1025)", stdout: "", stderr: "", blocked: "false"}
##### r2_s18.c [snprintf(b, 8, "%s", "\xc8"); return (unsigned char)b[0];]
== ORACLE rc=0
      1 Defined {value: "Specified(128)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=0
      1 Defined {value: "Specified(200)", stdout: "", stderr: "", blocked: "false"}
##### r2_s19.c [the same with "\xc7"]
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, started like an octal constant, but failed: 199")
== LEAN rc=0
      1 Defined {value: "Specified(199)", stdout: "", stderr: "", blocked: "false"}
```
(The bracketed program summaries were added by the consolidator. The sources are in the hunters' reports, `numbers/`,
`libc/`, `strings/s18-19`, `adversarial/p08-09`.)

### K-2: UB inside a libc C body: the oracle reports the libc location, Lean reports `<unknown location>` (Z1-A1)

- Sources: the frontend, libc and noodler hunters.
- Recorded as "Still open" in VALIDATION §3 (Z1-A1, with a named mover).
- Record finding [AGENT]: CONTRACT.md §3's libc row says "Open questions: none" while VALIDATION lists this served
  difference as open. The two documents disagree.

Consolidator re-runs, `--libc --timeout 300` (exhaustive):
```
##### lb01.c --libc --timeout 300     [char a[2] = {'a','b'}; return (int)strlen(a);]
== ORACLE rc=1
      1 Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<357:9--357:11>"}
== LEAN rc=1
      1 Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<unknown location>"}
##### abs.c --libc --timeout 300      [return abs(INT_MIN) & 1;]
== ORACLE rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<521:20--521:22>"}
== LEAN rc=1
      1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<unknown location>"}
##### lu1.c --libc --timeout 300      [char *p = 0; return (int)strlen(p);]
== ORACLE rc=1
      1 Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<357:9--357:11>"}
== LEAN rc=1
      1 Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<unknown location>"}
```
Additional fact from the libc hunter, not re-run: every `sscanf`/`vsscanf` call is UB048 in BOTH engines (`__shlim`,
`stdio.c:116`). This is a shared libc defect.

### K-3: `ftell`/`fseek` on stdout: the oracle answers 0, Lean refuses at the CerbFS boundary (D2)

The refusal is documented (CONTRACT D2 refuses the filesystem in full). The existing witness
`zd-z2f01-lseek-whence` covers the mechanism but not the stdout form, where no file is involved. `io2.c`, `--libc
--first --timeout 300`:
```
== ORACLE rc=0
      1 Defined {value: "Specified(0)", stdout: "hi\n0 0 0 0\n", stderr: "", blocked: "false"}
== LEAN rc=134
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/run.THGMr3/l.err:PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: CerbFS refusal (fail-closed fs-model boundary): lseek fd 1 offset 0 whence 1 — the filesystem is not modelled by this port ([USER 2026-09-28] contract D2: refused in full); answering would differ from, or merely guess at, the orac
```
(run_both cuts the line at 400 columns.)

### K-4: `aligned_alloc(0, n)`: the oracle crashes with Division_by_zero, Lean serves `DUMMY(align_alloc)` (Z2-M-01)

This is still open in VALIDATION §3, and its operator decision is pending. CONTRACT does not list it. `aa1.c` (`char
*p = aligned_alloc(0, 16); return p == 0 ? 3 : 4;`), default flags (the `--libc` run printed the identical lines):
```
== ORACLE rc=125
cerberus: internal error, uncaught exception:
== LEAN rc=1
      1 Undefined {ub: "DUMMY(align_alloc)", stderr: "", loc: "<3:13--3:33>"}
```
Oracle run by hand (first lines of the combined output, colour escapes removed):
```
cerberus: internal error, uncaught exception:
          Division_by_zero
          Raised at Z.rem in file "z.ml", line 96, characters 13-50
```

### K-5: a raw non-UTF-8 byte in an attribute-argument string: the oracle answers, Lean dies reading the JSON

This is listed in VALIDATION §3(b), `cabs_json.ml:600/602`. Its file-name sibling is BUG-6. Re-run with
`run_both.sh` default flags:
```
##### b4_at01.c (default)      [[[gnu::deprecated("caf<0xE9>")]] int f(void) { return 1; }  int main(void) { return 5; }]
== ORACLE rc=0
      1 Defined {value: "Specified(5)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=1
##### b4_s11.c (default)       [block-scope [[deprecated("caf<0xE9>")]] attribute; return 42]
== ORACLE rc=0
      1 Defined {value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
== LEAN rc=1
```
Lean stderr (b4_at01, from raw.sh): `uncaught exception: Tried to read file 'RUNDIR/p.json' containing non UTF-8 data.`

## 4. Other classes

### 4.1 CLASS_A (both fail, message text only; all reproduced)

A-1. A backslash in `--args` (`k_a01.c --args 'x\y'`). Lean's message also cites the wrong OCaml arm
(decode.ml:199-200; the arm that fires is :165-167, per the frontend hunter).
```
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant, invalid constant: '\\'")
== LEAN rc=134
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/run.gcL8NF/l.err:PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: decode_character_constant: invalid char constant ==> \ (decode.ml:199-200)
```
A-2. A UTF-8 byte in a decoded string literal (`k_s03.c`, `char s[] = "héllo";`). The oracle names a byte; Lean names
a carrier Char, which prints as UTF-8 of U+00C3.
```
== ORACLE rc=125
cerberus: internal error, uncaught exception:
          Failure("decode_character_constant: invalid char constant ==> \195")
          Called from Cerb_frontend__Translation_effect.runStateM_errors in file "ocaml_frontend/generated/translation_effect.ml", line 265, characters 19-35
== LEAN rc=134
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/run.ewLxv0/l.err:PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: decode_character_constant: invalid char constant ==> M-CM-^C (decode.ml:199-200)
```
(Shown through `cat -v`.)

A-3. Duplicate external definitions across TUs (`m8/a.c`: `int f(void) { return 1; }`, `m8/b.c`: `int f(void) {
return 2; } int main(void){return f();}`, the hunter's `rbm.sh` multi-TU runner). The oracle reports on stderr and Lean
reports an `Error` line; this is a §1(a) standing member (front-end rejections).
```
== ORACLE rc=1
    ^ 
Time spent: 0.046765 seconds
== LEAN rc=1
      1 Error {msg: "linking failed: duplicate external name: f at /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/consolidate/m8/b.c:1:5-6"}
** FULL-OUTPUT DIFFERS
```
Oracle run by hand: `.tmp/hunt/consolidate/m8/b.c:1:5: error: duplicate external symbol: f`.

A-4. The symbol number embedded in an unknown-procedure error (`loc.c`, `setlocale`; also `fabs`/`scalbn` in
math-using programs). This is the Illformed_program text member of §1(a), "modulo the embedded symbol id". `--libc
--first --timeout 300`:
```
== ORACLE rc=1
      1 Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(505, SD_Id("setlocale"))'"}
== LEAN rc=1
      1 Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(37484, SD_Id("setlocale"))'"}
```
A-5. A call to a function declared without a prototype and not defined in the TU (`kr2.c`: `int abs(); int main(void) {
return abs(-5); }`, `--libc`). Both reject it, so it is also ORACLE_ISO-19.
```
== ORACLE rc=1
/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/consolidate/kr2.c:2:25: error: constraint violation: too many arguments to function call, expected 0, have 1
== LEAN rc=1
      1 Error {msg: "typechecking failed at /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/bug-hunt-20260929/.tmp/hunt/consolidate/kr2.c:2:25-28"}
```

### 4.2 Record observations (not discrepancies)

- **Frontend refusal text** (adversarial hunter): for front-end rejections Lean names only the location ("desugaring
  failed at …", "typechecking failed at …"), while the oracle names the reason ("feature not yet supported: variable
  length array", "bit-fields"). This is class (a) by §1(a), but it falls short of CONTRACT §1(2)'s "names the
  unsupported feature" for the cases where Lean itself is the refusing side. [AGENT] note for the operator.
- **Cite drift in CerbMem** (cerbmem hunter): the `impl_mem.ml:NNNN` cites in `CerbMem.lean` are stale, by +6 to +44
  lines through the file (after `3cb7f7587`, which added receipts), including cites marked "at THIS tree's lines". The
  hunter's full sample is in its report; not re-measured by the consolidator.
- **Z2-CP-02 note names the wrong constant** (BUG-5): `CoreParser.lean:95-103` blames FLT_MAX, and the lossy constant is
  0x1p64.
- **Lean binary rebuilt mid-hunt** (numbers hunter): the binary's mtime changed to 22:13 during the session.
  Unexplained; another agent's build is likely. The consolidator's runs all used the binary as it stood at consolidation
  time.

### 4.3 CLASS_B

- B-1 (adversarial hunter, `k02`): a 2^40-element global `char` array. The oracle stack-overflows in
  `Lem_list.replicate`, and Lean is OOM-killed under `capped` (loud). **NOT RE-RUN** [AGENT]. It is an OOM probe on a
  shared box (box discipline), and it falls under the documented §3(b) byte-list representation violation.
- The hunters also noted, and the consolidator did not re-run, the documented resource items: `for(;;);` aborting with
  "Stack overflow detected" before default fuel (TODO.md "Stack overflow vs fuel (C4 F-A7)"), and 1e6-iteration loops
  timing out on Lean (step-runner ceiling).

## 5. ORACLE_ISO list (both engines agree, ISO disagrees)

Two were spot-checked by the consolidator (verbatim below). The rest are hunter-reported and not re-run.

1. A whole-struct copy loses the active member of a union nested at a nonzero offset. `abst`'s Struct arm looks the
   union up at `base+pad`, not `base+offset`. **Spot-checked**, `iso_u4.c` (`struct S { long pad; union U { int i;
   double d; } u; }`, `s.u.d = 1.5; t = s; return (int)(t.u.d*2);`), default flags:
   ```
   == ORACLE rc=1
         1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<8:15--8:26>"}
   == LEAN rc=1
         1 Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<8:15--8:26>"}
   ```
2. A designated initialiser of a non-first union member initialises the first member (`desugaring_init.lem:583-599`,
   self-flagged at `:592`). This is a served wrong value, and it is a tray candidate (not in the tray INDEX per the
   adversarial hunter). **Spot-checked**, `iso_y13.c` (`union U { char c; int i; }; union U u = { .i = 0x01020304 };
   return u.i == 0x01020304;`), default flags:
   ```
   == ORACLE rc=0
         1 Defined {value: "Unspecified('signed int')", stdout: "", stderr: "", blocked: "false"}
   == LEAN rc=0
         1 Defined {value: "Unspecified('signed int')", stdout: "", stderr: "", blocked: "false"}
   ```
3. `union U w = t.u;` is rejected; 6.7.9#13 allows it.
4. A file-scope compound literal used as an address constant is rejected.
5. Returning from `main` does not run `atexit` handlers, while `exit(0)` does (5.1.2.2.3).
6. `float` is 8 bytes and is not rounded to single precision (`(float)16777217 == 16777217.0`; `(float)ULONG_MAX ==
   2^64`; union punning of `1.0f`).
7. `math.h`: `NAN` is the integer `0x7fc00000`, and `INFINITY` = `HUGE_VALF` = FLT_MAX, which is finite. So
   `strtod("nan")` is not a NaN.
8. Buffered stdout (putchar/fputs/fwrite) is not flushed at exit or at return from main, and printf bypasses the FILE
   buffer, so output can be reordered or lost (7.21.3#5).
9. With user-supplied math functions, `strtod("1.7976931348623157e308")` (DBL_MAX) sets ERANGE. This is musl decfloat
   with a 53-bit `long double`.
10. `L'\xFF'`/`u'\xff'` evaluate to −1: every prefixed constant is wrapped to plain char. `L'\xFF'`/`U'\377'`/`L"\xff"`
    crash both engines in `bytes_of_int`.
11. Wide/UTF-16/32 string literals get one element per UTF-8 source byte (`sizeof(U"é") = 12`, `sizeof(L"é") = 12`,
    `sizeof(u"é") = 6`).
12. `'\400'`/`'\777'` are accepted and wrapped, where ISO makes them a constraint violation.
13. `sizeof(int[1L<<62])` wraps to 0 instead of being a constraint violation.
14. Enum overflow (`A = INT_MAX, B`) is accepted silently.
15. The designated-initialiser override (`.b[1] = 3` then `.b = { [2] = 9 }`) keeps `b[1] = 3`. ISO is ambiguous here
    (DR 413), so this is a note only.
16. `write(-1, …)`/`write(-2, …)` go to stdout/stderr (`natFromInteger` is `abs`).
17. `time(&t)` returns 0 and does not store to `*t`.
18. `signal(99, h) == SIG_ERR` is 0. This is cross-TU function identity (thin-surface O10).
19. A call to a no-prototype function that is declared but not defined is rejected with "too many arguments" (A-5).
20. `%p` ignores the field width.
21. `sscanf`/`vsscanf` are always UB048 (`__shlim`, `stdio.c:116`).

Already in the tray and not re-reported: `_Bool b = 0.5` (tray 15), unary minus of 0.0 (tray 42), the snprintf
truncation return (tray 16).

## 6. Hunter coverage and not-covered notes

The summaries below are condensed from each hunter's report; the full reports were JSON returned to the orchestrator.

- **Concrete memory model (cerbmem), 47 probes.**
  - Covered: CerbMem vs `impl_mem.ml` code-read arm for arm (repr/abst, funptrmap, provenance, load/store/kill, pointer
    eq/rel/diff, int↔ptr, realloc/memcpy/memcmp, va_*, layout, allocator, unspecified values). Probed: u64→double
    rounding, union punning/copies, mixed-provenance pointer bytes, one-past equality, atomic member access, the `_Bool`
    trap, padding, realloc shapes, varargs (trace counts identical), address layout in both modes, and an atexit `call`
    conflation scan (no hit).
  - Not covered: memmove/memset (libc C), PNVI/switch arms (refused), WP0 receipts (off by default), SC, multi-TU
    funptrmap keying, the `call`-id atexit variant (same signature, so a silent wrong call; not located), CerbFloat.
- **Numbers and their text, 78 probes.**
  - Covered: float↔int conversions and bounds, int→float rounding ties, NaN/inf/−0.0, float bytes, integer constant
    typing, char/string escapes, hex float literals, decimal exponent overflow, printf `%f` widths/precision, `%p`, the
    Invalid_format payload, stdout/stderr escaping of all bytes, gcc builtins, strtol family, integer strtod, argv
    splitting, va_arg of doubles, cerb::with_address.
  - Not covered: finite strtod (unknown `scalbn`/`fabs` in both, D4), `%e/%g/%a` (Invalid_format in both),
    `%lc/%ls/%n`, `__int128`, long double beyond 8 bytes, concurrency/CHERI. Also a latent note: libc.core:60849 (this
    became BUG-5 via the frontend hunter and the noodler).
- **Input and driver (frontend), 62 probes.**
  - Covered: CabsImport decoders and bridge encoders, CerbDecode vs decode.ml, literal forms, GNU extensions,
    designators, enums, integer-constant types, `_Alignas`, magic comments, `#line`, isLibraryLocation (three routes),
    main signatures, exit codes, `--args`, multi-TU linking shapes (13 groups), libc name collisions, the libc-dump float
    census, address layout.
  - Not covered: exhaustive confirmation of BUG-5, the denormal route through the same branch, CoreParser on non-runtime
    files, `--call`/`--stdin`, multi-TU libc mode, 20000-term expressions (both time out), UCN escapes in literals.
- **libc breadth, 58 probes.**
  - Covered: stdlib (strto* edges, lldiv, qsort, quick_exit, abort, rand, mblen), signal.h, string.h
    (strcoll/strxfrm/strchrnul/memchr/memmove), stdio (setvbuf, fputs, fwrite, sprintf flags, `%p`, va_copy+vsnprintf,
    unspecified values), write/writev, getopt, time.h, limits/float.h, libc-global addresses, linking collisions, argv,
    and a code-read of the `loadLibc` stitch.
  - Not covered: stdin/filesystem (refused, D2), atexit beyond lanes 040/041, perror/strerror (shared assert), strtok
    (unknown), wide chars, and exhaustive printf-heavy programs (the oracle ran past 10 min). So libc-mode
    trace-dependent differences behind `--first` are unexamined.
- **Strings and characters, 42 probes.**
  - Covered: byte-carrier import vs text fields, CerbDecode tables and escaped_char, encode_character_constant, printf
    paths on high bytes, store_chars_in_array, batch escaping in both modes, literal escapes, raw UTF-8/control bytes,
    prefixed literals, char signedness, UTF-8 identifiers (UCN'd by cpp), UTF-8 paths and columns, `--args`,
    string-literal identity.
  - Not covered: CoreParser string escapes (error text only), `%ls/%lc`, exhaustive literal identity (times out on
    both), CerbFS, non-ASCII `--args` (D6), EDecl_magic non-UTF-8 (did not reach the JSON).
- **Adversarial shapes from the contract, 245 probes.**
  - Covered: boundary arithmetic, allocation edges, VLAs (refused), deep nesting (2000 parens, 3000-term sums, 1000-case
    switch, 600-member struct), odd control flow, exhaustive unsequenced effects (multiplicities matched, including 4960×3
    and 14880 traces), identifier/declaration clashes, provenance shapes, char/string constants, printf flags, snprintf,
    several libc calls, UB locations under macros/`#line`/CRLF, argv shapes, fuel and stack ceiling.
  - Not covered: `--first` (outside the promise), multi-TU, concurrency, bit-fields/VLAs beyond refusal, loops over
    ~1e5 iterations (Lean ceiling), any other unescaped printed field carrying byte-carrier strings (not searched).
- **Noodler (free, no brief), 52 probes.**
  - Where it went: the trust boundaries around the engine, meaning where Lean takes oracle-produced or environment data
    and re-interprets it. That covers runtime-file resolution (BUG-2), the library-location test (BUG-3) and the libc
    text dump (BUG-5, plus a census of every float literal).
  - Also probed: UB locations, main shapes, unspecified values, exhaustive counts, alignment, address layout, libc-static
    name collisions, libc through function pointers, K&R, and the dump's duplicate/shadowed names (safe).
  - Not covered: multi-TU (Lean's libc symbols are keyed by name), `--call`/`--pp-core`, exhaustive confirmation of
    BUG-5, other float-sensitive libc paths after a re-pin, and stdout of executions ending in UB (the batch Undefined
    line prints no stdout, so neither lanes nor probes compare it).

## 7. Method

1. Seven hunters ran in parallel, each in its own scratch directory under `.tmp/hunt/` of this worktree. Every probe
   went through the shared `.tmp/hunt/run_both.sh`: oracle `main.exe --exec --batch [--nolibc] [--mode=exhaustive]`
   versus `cerberus-lean --batch [--first] [--libc tests/libc/libc.core --libc-tu …]` on the oracle's `--cabs-json`
   export, both under `scripts/capped` with `CERB_MEM_MAX=16G` and `timeout`. It prints sorted, distinct verdict lines
   with counts and exit codes.
2. The consolidator [AGENT] deduplicated by mechanism: 30 raw findings became 17 non-ORACLE_ISO rows (derived). It
   copied every witness program into `.tmp/hunt/consolidate/` and re-ran every non-ORACLE_ISO finding itself with the
   hunter's flags, via `scripts/ce .tmp/hunt/run_both.sh FILE.c [flags]` from the worktree root. The exceptions are
   BUG-2 (a planted-cwd probe; no C program shows it under run_both) and CLASS_B B-1 (not re-run). Byte-level findings
   were re-checked with `raw.sh`, a copy of the same invocation that keeps the raw stdout (`od -c`) and Lean's stderr.
   The multi-TU case used the frontend hunter's `rbm.sh` (it mirrors `scripts/test_multi_tu.sh`). All outputs above are
   the consolidator's own, quoted verbatim except for the stated edits (ANSI colour codes removed, `cat -v` rendering,
   condensed od rows, bracketed program summaries).
3. The classification checked `CONTRACT.md` §1/§3/§5 and `VALIDATION.md` §1(a), §2 (R1–R3), §2b (N1, N2) and §3
   (including "Still open") before any finding was called KNOWN.
4. Harness gotchas that all hunters reported:
   - `run_both.sh` must run with cwd = the worktree root. Otherwise Lean exits 1 with "cannot find
     runtime/libcore/std.core", and run_both's stderr filter hides the message, so the run looks like a mass
     discrepancy. This lookup is itself BUG-2.
   - `--args "STR"` with STR starting with `-` is parsed by the oracle's cmdliner as its own option (rc 124). Use
     `--args=STR`.
   - When the oracle front end fails, run_both hands Lean empty JSON ("cabs-json parse error: offset 0"), which is a
     harness artefact.
5. Box discipline: one heavy run at a time; the exhaustive libc runs were capped at 300 s. No build, no push, and no
   other tracked file was edited. The consolidator's scratch directory was deleted after this commit. The hunters'
   directories are left for the orchestrator.
