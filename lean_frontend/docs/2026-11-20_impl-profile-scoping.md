# Implementation profiles and plain `char` signedness: scoping (2026-11-20)

Branch `design/impl-profile`, base mainline `dd0f52fe6`; upstream described at the merge-base `c3ff8c53f`
(`deps/cerberus-upstream`). Worker: Claude Fable 5.2 (agent). A scoping pass: no code, gate or baseline changed.
Quoted machine output is verbatim; counts marked "derived" are mine. Probe recipe: section 7.

The ask (consumer refinedc-lean, `docs/PUBLIC-ALPHA.md` "Plain char", `AilToCaesium/NORMALISATION.md`; this repo's
`TODO.md` "The implementation as a parameter"): select RefinedC's configuration, plain `char` unsigned, consistently,
constant evaluation included.

## 0. Findings in brief

1. Upstream has three profile records. `DefaultImpl` and `HafniumImpl` differ in **one** property, plain-`char`
   signedness (and their name strings). `MorelloImpl` is the CHERI profile.
2. No Cerberus driver flag selects `HafniumImpl`. `--impl` names the Core `.impl` file, which is independent of the
   profile record. RefinedC's own frontend selects it by a library call (`cerb_wrapper.ml:44`).
3. **Upstream's selection is not uniform.** One generated binding, `AilTypesAux.is_signed_ity`, reads the profile
   once at module initialisation, before any `set`; every other reader reads it at call time. Under `HafniumImpl` the
   constant evaluator, `CHAR_MIN`/`CHAR_MAX` and the integer ranges are unsigned, while the elaboration's signedness
   tests, Core's `is_signed`/`is_unsigned` and the memory model's store and load stay signed. Measured on pristine:
   storing 200 into a `char` crashes; loading byte 200 through a `char` lvalue yields a negative value while
   `CHAR_MIN == 0`. RefinedC never executes, so its use does not reach this.
4. The fork's oracle library already honours `set HafniumImpl.impl` (same results as pristine, same defect). The
   Lean side has one constant, `CerberusImpl.is_signed_ity` `.Char0 => true`; its hand-written readers already
   branch on that function, not on literals.
5. The consumer runs the Lean library in process for desugaring and typing, and the Lean driver for its execution
   differential. Normalising printed values on its side is unsound (section 4, option d).

## 1. Upstream's mechanism (c3ff8c53f; the fork's file differs only in the two hunks named in section 3)

Profile records, `ocaml_frontend/ocaml_implementation.ml`:

| Property | `DefaultImpl` :114-274 | `MorelloImpl` :300-353 | `HafniumImpl` :357-396 |
|---|---|---|---|
| `name` | `clang9_x86_64-apple-darwin16.7.0` | `clang11_aarch64-unknown-freebsd13` | `hafnium_aarch64-none-eabi` |
| plain `char` signed | `true` (:257) | `true` (:336) | **`false`** (:378) |
| `sizeof_pointer` / `alignof_pointer` | 8 / 8 | 16 / 16 | Default's |
| `max_alignment` | 8 | 16 | Default's |
| `intptr_t` alias | `Long` | `LongLong` | Default's |
| size, alignment of `(un)signed long long` | 8 | 16 | Default's |
| other integer sizes/alignments, `intN_t`, `intmax_t`, `wchar_t`/`wint_t` (`Signed Int_`), `size_t`, `ptrdiff_t` | table :154-245 | Default's | Default's |
| floating sizes/alignments (all 8) | :206-253 | Default's | Default's |
| enum registry and rule (`register_enum`, `typeof_enum`) | :125-150 | Default's (shared registry) | Default's (shared registry) |

A fourth module, `DefactoImpl` (:277-298), is commented out. Endianness is not a record field: the concrete memory
model's `bytes_of_int` is little-endian for every profile (`memory/concrete/impl_mem.ml:953-971`).
`hafniumIntImpl` (:399-409) packages Hafnium's signedness and precision as an `IntegerImpl.implementation`.

Selection and state. `set`/`get` (:426-438) close over one `ref (false, DefaultImpl.impl)`; `set` may be called once
(a second call is a `failwith`). Callers of `set` in the Cerberus tree, derived by grep over `*.ml`/`*.lem`: one,
`backend/driver/main.ml:131` (`:135` in the fork), `set MorelloImpl.impl` when the memory model is a CHERI one. No
flag, environment variable or Core file selects `HafniumImpl`.

The Core `.impl` files (`runtime/libcore/impls/`) are a separate axis: `--impl=NAME` (default
`gcc_4.9.0_x86_64-apple-darwin10.8.0`) loads `impls/NAME.impl` (`backend/common/pipeline.ml:46-47`). The default
file defines `<bits_in_byte>`, the signed-conversion wrap, `<SHR_signed_negative>` and `<Bitwise_complement>`; none
reads `char` signedness. The other file is not loadable on either tree:

```
$ main.exe --runtime=… --nolibc --exec --batch --impl=i686-apple-darwin10-gcc-4.2.1 arr.c     (fork and pristine)
ERROR: while parsing the Core impl, the parser didn't recognise it as an impl .
```

Which phase reads the profile (OCaml; "call time" sees a `set`, "init time" never does):

| Phase | Reader | When read |
|---|---|---|
| Preprocessor defines | none: `create_cpp_cmd` (`main.ml:38-52`) adds `__CHERI__` by memory model only; `limits.h` maps `CHAR_MIN` to `__cerbvar_CHAR_MIN` (`builtins.lem:338-341`), resolved later | not read |
| Desugarer, constant evaluation | `Decode.decode_character_constant` (`ocaml_frontend/decode.ml:210-219`), then the mini-pipeline's elaboration and Core run (rows below) | call time |
| Ail typing | `Implementation.is_signed_ity` applied (`genTyping.lem:30`, `ailTypesAux.lem:334-350`), `integerImpl ()` | call time |
| Ail typing, usual arithmetic conversions | `AilTypesAux.is_signed_ity` (`ailTypesAux.lem:728-796`, on promoted types) | **init time** |
| Core elaboration | `AilTypesAux.is_(un)signed_integer_type` (`translation.lem`, e.g. :319, :388, :2006, :4349); `ctype_aux.lem:271` | **init time** |
| Core runtime | `is_signed`/`is_unsigned` (`core_eval.lem:1075`, `:1085`; `std.core:48` reads `is_unsigned`) | **init time** |
| Memory model: ranges | `impl_mem.ml:2265`, `:2297` (fork line numbers) | call time |
| Memory model: store, load | `repr` `impl_mem.ml:1006` (store), `int_of_bytes` at `:815` (load), both `AilTypesAux.is_signed_ity` | **init time** |
| libc build | `runtime/libc/dune:149-157` runs the driver, so the default profile | default |

The init-time reader is one line of generated OCaml, identical in both trees (the only point-free top-level binding
of `Ocaml_implementation.get()` a one-line grep finds; derived):

```
ocaml_frontend/generated/ailTypesAux.ml:33:let is_signed_ity:integerType ->bool=  (Ocaml_implementation.get()).is_signed_ity
```

from `ailTypesAux.lem:28` `let is_signed_ity = Implementation.is_signed_ity`.

## 2. What RefinedC selects, what the consumer does, and the symptoms

RefinedC (`deps/refinedc` at `25f706d4`), `frontend/cerb_wrapper.ml`: `set_cerb_conf … ~exec:false` (:30-34),
`Ocaml_implementation.(set (HafniumImpl.impl))` (:44), the default `.impl` file unless `IMPL_NAME` is set (:26-28),
then `c_frontend` (:47): preprocess, parse, desugar, type. It never elaborates a whole program or executes. Its
translator reads `HafniumImpl.impl` and `hafniumIntImpl` directly (`ail_to_coq.ml:21`, `:29`, `:109`, `:118`). Its
cpp command passes `-undef` and no `char`-related define (:59-76). RefinedC's frontend is not built on this box.

refinedc-lean at its pin `03c8b4451` (an ancestor of this base): the OCaml producer only exports Cabs JSON
(`main.exe --cabs-json`); desugaring and typing run in process on the Lean library with the default fuel and switch
instances (`AilToCaesium/Pipeline.lean:151-172`); layouts come from its own `AilToCaesium/HafniumImpl.lean`
(`char` unsigned); its execution differential runs `cerberus-lean --batch` (`scripts/differential.py:751`).

Witnesses (mine, the consumer's `a12_char_case.c`/`a13_char_array.c` made executable, plus an enumerator):

```c
/* sw.c  */ int k(int c) { switch (c) { case '\377': return 1; case '\200': return 2; default: return 0; } }
            int main(void) { return k(255) * 10 + k(128); }
/* arr.c */ int main(void) { int a['\377' > 0 ? 2 : 1]; a[0] = 0; return (int)(sizeof a / sizeof a[0]); }
/* enu.c */ enum e { A = '\377' }; int main(void) { return A > 0 ? 2 : 1; }
/* r1.c  */ int main(void) { char c = (char)200; return c > 0; }
/* r4.c  */ #include <limits.h>
            int main(void) { unsigned char u = 200; char *p = (char*)&u; return (*p > 0 ? 1 : 0) + (CHAR_MIN == 0 ? 2 : 0); }
```

The fork's engines today (both symptoms reproduced; `--pp=ail` lines from the fork's `main.exe`):

```
sw.c:   6:    case -1:        8:    case -128:
arr.c:  4:  signed int a[1];
```

| Program | Fork oracle driver | Fork Lean driver (`--first`) | Pristine driver |
|---|---|---|---|
| `sw.c` | `Defined {value: "Specified(0)", …}` | `Defined {value: "Specified(0)", …}` | `Defined {value: "Specified(0)", …}` |
| `arr.c` | `Defined {value: "Specified(1)", …}` | `Defined {value: "Specified(1)", …}` | `Defined {value: "Specified(1)", …}` |
| `enu.c` | `Defined {value: "Specified(1)", …}` | `Defined {value: "Specified(1)", …}` | `Defined {value: "Specified(1)", …}` |

The Lean driver has no selector: `--impl hafnium` gives `cerberus-lean stop ["1","REFUSAL","cli","--impl",…unknown flag…`.

Under each profile, through the installed libraries (section 7). Frontend only, pristine, RefinedC's recipe:

```
== pristine cerberus-lib, default, sw.c       case -1:  …  case -128:
== pristine cerberus-lib, hafnium, sw.c       case 255:  …  case 128:
== pristine cerberus-lib, default, arr.c      signed int a[1];
== pristine cerberus-lib, hafnium, arr.c      signed int a[2];
== pristine cerberus-lib, default, enu.c      return -1 > 0 ? 2 : 1;
== pristine cerberus-lib, hafnium, enu.c      return 255 > 0 ? 2 : 1;
```

(each line is the differing line of the printed Ail; the first line of every run was `profile selected:
clang9_x86_64-apple-darwin16.7.0` or `hafnium_aarch64-none-eabi`.) These are the values the consumer records for
RefinedC (255, 128, two elements). With execution:

| Program | Pristine, default | Pristine, Hafnium | Fork library, default | Fork library, Hafnium |
|---|---|---|---|---|
| `sw.c` | not run | not run | `main returned: 0` | `main returned: 12` |
| `arr.c` | not run | not run | `main returned: 1` | `main returned: 2` |
| `enu.c` | not run | not run | `main returned: 1` | `main returned: 2` |
| `r1.c` | `main returned: 0` | crash (below) | not run | crash (below, line 967) |
| `r4.c` | `main returned: 0` | `main returned: 2` | `main returned: 0` | `main returned: 2` |

```
== pristine cerberus-lib, hafnium, r1.c
profile selected: hafnium_aarch64-none-eabi
Exception: Assert_failure ("memory/concrete/impl_mem.ml", 932, 6).
failed: bytes_of_int(signed), i= 200, nbits= 8, [-128 ... 127]
```

`r4.c` returning 2 under Hafnium means `CHAR_MIN == 0` holds and `*p > 0` is false for the byte 200: the mixed
configuration of finding 3, as a silent answer.

## 3. Where the fork bakes in the default profile

| Site | What |
|---|---|
| `lean_frontend/CerberusImpl.lean:112-123` | `is_signed_ity`, `.Char0 => true` (:114): the one signedness constant |
| `CerberusImpl.lean:24`, `:30-31`, `:149-185`, `:216-229`, `:247-266` | `max_alignment`, pointer size/alignment, the alias table, integer and floating sizes/alignments: constants shared by Default and Hafnium |
| `CerberusImpl.lean:233-237` | `precision_ity`, through `is_signed_ity` |
| `lean_frontend/CerbDecode.lean:71` | the character-constant wrap, already `if CerberusImpl.is_signed_ity .Char0` |
| `lean_frontend/CerbMem.lean:662`, `:790`, `:998`, `:1364`, `:1381` | store, load and the `char` range, all through `CerberusImpl.is_signed_ity` |
| `frontend/model/implementation.lem:86-93` | Lean target reps of the four `*_norm` vals: plain functions, no reader |
| `lean_frontend/generated/` | 8 files name `CerberusImpl.{is_signed_ity,precision_ity,sizeof_ity,…}` (derived); everything else reaches them through `Implementation`/`AilTypesAux` |
| `lean_frontend/Main.lean:1326` | the default `.impl` path as a literal; no `--impl`, no profile flag |
| `backend/driver/main.ml:135`, `:601-616` | the only `set` (Morello); the address-space-top bound reads `DefaultImpl.impl.sizeof_pointer` |
| `ocaml_frontend/ocaml_implementation.ml:412-423`, `:579` | the fork's two hunks: the enum registry read as a map (`DefaultImpl.registered_enums`), the union `alignof` line |
| `runtime/libc/dune:149-157`; ladder Tier B row 13 | `libc.co`, `libc_inner_arg_temps.co` built by the driver under the default; one dump and one SHA-256 pin per switch mode |
| Baselines | 19 baseline files (derived, `scripts/*baseline*`, `tests/*/…baseline*`), all recorded under the default |
| Docs | `CONTRACT.md:245` D6 (LP64 only; Hafnium is LP64), `SUPPORTED.md:27`, `:114`, `VALIDATION.md:2003-2007` |

Measured for the libc: the twelve sources of `libc.co`, elaborated by the fork's library under each profile
(driver cpp flags, no `--sequentialise`/`--rewrite`), print identical Core: 0 differing lines of 108161 (derived).
No libc source holds a character constant above `\177` (derived by grep).

No Lean theorem names signedness: outside `CerberusImpl`, `CerbDecode` and `CerbMem`, `is_signed_ity`/`precision_ity`
occur only in two unit tests (`test/Unit/ReconstructLegacyTest.lean`, `EnumDataTest.lean`);
`CerberusImpl_lemMeasureProofs.lean` has 0 occurrences (derived). Theorems stated over `loadM`/`storeM` and the
drive cone would gain a binder under (a) or (b), as they did for the switch set.

## 4. Options

Proxy for the size of a threaded parameter: the enum reader already reaches every caller of
`Implementation.is_signed_ity`; it is bound on 314 lines in 30 of the 229 generated files, and the switch class on
131 lines in 14 (derived). The lem mechanism exists at the current pin (`declare {lean} reader val … = instance`,
two instance readers on one definition are covered by lem-lean's record `2026-10-05_instance-reader-record.md`).

| | Option | Cost | Risk | Leaves inconsistent | Validation and pins |
|---|---|---|---|---|---|
| a | The whole profile record as a run-time parameter on both engines (sizes, alignments, aliases, pointer size, signedness) | 10-14 worker-days | Touches the layout block and its measure proofs, `CerbMem`'s pointer-size reads, the address-space bound; buys nothing today: Default and Hafnium differ in one field, Morello is outside the supported profile | Same as (b) | As (b), plus kernel replay over the layout proofs |
| b | Plain-`char` signedness alone as an instance-implicit class, threaded like the switch set; a fork flag on the oracle driver calling upstream's `set HafniumImpl.impl` | 6-9 worker-days | Binder churn across the desugar, typing, elaboration and execution cone; consumer proofs that unfold through it re-pin with a note (PNVI S1 precedent) | The oracle's init-time reader (finding 3) unless fixed; libc built under the default (prints identical, above) | A new witness lane, both engines under the second configuration; every existing baseline must be byte-unchanged under the default; totality proofs regenerate; kernel replay; no libc digest expected to fork; no quotation pin changes |
| c | A build-time constant on the Lean side (two builds of the root package); the oracle as in (b) | 3-5 worker-days, then a second full Lean build wherever the second configuration is gated | A configuration outside the types: theorems hold per build, artifacts double, a lakefile mechanism to select the constant does not exist yet | As (b) | The second build needs its own row-1 pass and lane; pins per build |
| d | Nothing here; the consumer normalises | 0 here | Unsound as a normalisation (below) | Everything | None |

On (d). The desugarer's results cannot be repaired after the fact: `int a['\377' > 0 ? 2 : 1]` has lost the
character constant by the time the consumer sees the size 1, and a label `-1` from `'\377'` is indistinguishable
from a written `case -1:`. The only sound form of (d) is a refusal on the consumer's side of every input whose
constant evaluation or typing can read plain-`char` signedness (character constants above `\177`, `CHAR_MIN`,
`CHAR_MAX`, conversions to `char` in constant expressions, and the typing sites of section 1). That is a release-domain
restriction for the consumer's owner, not a selection of RefinedC's configuration.

On every option that executes under the second configuration, the oracle's init-time reader has to be settled
first (question 2): with it, the oracle crashes or answers from a mixed configuration, and a uniformly unsigned Lean
engine would disagree with it on valid C.

## 5. Recommendation

[AGENT 2026-11-20] Option (b), and only once the operator confirms the consumer is blocked (the roadmap lists the
implementation switch under work not started unless a consumer needs it). Reasons:

- It is the whole difference between the two profiles the consumer cares about, so (a) adds cost and no coverage.
- It follows the two existing precedents for an OCaml global on the Lean side (the tag map, the switch set): one
  build, one set of theorems quantified over the parameter, the default supplied explicitly at the driver.
- The oracle needs no model change to select the profile: the fork's library already produces RefinedC's values
  under `set HafniumImpl.impl` (section 2).
- (c) is cheaper to write and dearer to keep; (d) is not sound.

[AGENT 2026-11-20] The class carries one field (the signedness) but is named for the implementation, so a later
field does not thread a second binder through the same cone.

[AGENT 2026-11-20] The init-time reader is treated as a demonstrable upstream mistake (a crash and a silently mixed
answer on valid C under upstream's own profile): fix it in the fork by making `ailTypesAux.lem:28` a function of its
argument, register the fork-ahead delta, and file the report in the upstream tray. This changes generated OCaml and
is the operator's call (question 2).

Shape, three slices: S1 threads the class with the default everywhere, zero behaviour change, generated OCaml
byte-identical, all lanes unchanged (3-4 days). S2 adds the two selectors, the oracle fix and a witness lane of a
few dozen programs covering case labels, array sizes, enumerators, `CHAR_MIN`/`CHAR_MAX`, conversions, store and
load, run on both engines under the second configuration (2-3 days). S3 is the pre-merge review round, the re-gate
and the consumer note (1-2 days). Total 6-9 worker-days (derived from the PNVI S1 record's scope, not measured).

## 6. Questions for the operator

1. Is refinedc-lean blocked on this in the roadmap's sense, so the slice starts now, or does it wait for the next
   functional re-pin as `TODO.md` records?
2. Execution under unsigned `char`: fix the oracle's init-time reader as a fork-ahead fix with a tray report
   (recommended); or refuse execution under the non-default configuration on both engines and validate the frontend
   only (serves the consumer's desugaring, not its execution differential); or mirror the mixed behaviour (not
   recommended: it mirrors a crash and a wrong answer).
3. The selector's surface: upstream's profile name (`hafnium_aarch64-none-eabi`) or a signedness flag; and the
   fork driver flag's name. The default stays `DefaultImpl` in every case.
4. How `SUPPORTED.md` and `CONTRACT.md` state the second configuration: supported, or consumer-configured and
   covered by the witness lane only. D6 (LP64 only) is unaffected.
5. Validation scale: the witness lane alone, as a gate or a speedbump; or also a second pass of the exec and libc
   rows under the second configuration (roughly doubles those rows' running cost, no baseline of its own).
6. The pristine-oracle gate cannot cover the second configuration (pristine's driver has no selector). Accept that,
   or extend the instrument with a linked probe? (Recommended: accept.)
7. Design-pass scope and reviewer, and the pre-merge audit scope, per the working practices.

## 7. Probe recipe and what was not established

Driver probes: `main.exe --runtime=<prefix> --nolibc --exec --batch f.c` (fork `_build/default/backend/driver`,
pristine `deps/cerberus-upstream/_build/…`); Lean: `main.exe … --cabs-json f.c > f.json`, then
`cerberus-lean --batch [--first] --runtime <prefix> f.json`. Library probes: an OCaml toplevel script, no build,
run as `OCAMLPATH=<prefix>/lib CAML_LD_LIBRARY_PATH=<prefix>/lib/stublibs scripts/ce ocaml probe.ml <profile> f.c`
with `#require "cerberus-lib.mem.concrete"` and `"cerberus-lib.backend_common"`; it mirrors `cerb_wrapper.ml`:
`Cerb_global.set_cerb_conf`, `Ocaml_implementation.(set (HafniumImpl.impl))` for `hafnium`, prints
`(Ocaml_implementation.get ()).name`, `load_core_stdlib`, `load_core_impl` (default file), then either `c_frontend`
with `pprints = [Ail]` under RefinedC's cpp command, or `c_frontend_and_elaboration`, `core_passes`,
`Core_linking.link`, `Tags.set_tagDefs`, `interp_backend ~batch:`NotBatch` (printing `main returned: N`), or, for
the libc comparison, elaboration with `pprints = [Core]` under the driver's default cpp command and a `diff`.
The scratch scripts were deleted with the worktree's `.tmp/`.

Not established:

- RefinedC's own frontend output (not built here); the Hafnium values are from pristine `c3ff8c53f`'s library and
  the consumer's record. RefinedC's README pins Cerberus `f11e6b33`; that commit was not examined.
- Anything about the Lean side under unsigned `char`: no build was allowed, so (b)'s binder count is the proxy above
  and its behaviour is unmeasured.
- Whether the init-time reader changes any frontend-only result (typing or the constant evaluator's elaboration)
  beyond the witnesses, which came out unsigned.
- Identity of the binary `libc.co` across profiles: only the printed Core of the twelve sources was compared.
- The full Lean build's running time, which prices (c); the effect of (b) on cerberus-sl's proofs.
- Multi-line top-level bindings of `Ocaml_implementation.get()` in generated OCaml: the search was per line.
