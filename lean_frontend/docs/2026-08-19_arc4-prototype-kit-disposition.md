# Arc 4 / S2 — prototype differential-kit disposition survey

Date: 2026-08-19. Slice S2 of the exec-pipeline arc (charter:
`2026-08-19_arc4-exec-pipeline-charter.md`, S2 survey list; success
condition 5). Source tree surveyed READ-ONLY:
`cerberus-lean-prototype/` (scripts/ + tests/). Decisions are
per-item port / skip / defer with a one-line rationale; "port" work
itself belongs to S4b (after the minimal bar), not this slice.

Context: `test_interp.sh` (+ its `common.sh` helpers) is already ported
in this slice as `scripts/test_exec.sh` (comparison semantics preserved;
adaptations documented in that script's header).

| Item | Disposition | Rationale |
|---|---|---|
| `test_interp.sh` | **PORTED (S2, this slice)** | → `scripts/test_exec.sh`, retargeted at the generated pipeline binary (`cerberus-lean --batch`); baseline-tracked (`scripts/exec_baseline.txt`, `--check-baseline`). |
| `tests/coverage` corpus (199 .c files / 21 category dirs) | **PORT (S4b)** | Plain .c corpus, zero porting cost beyond copying; charter S4b already commits it as the reporting-mode per-category parity scoreboard for obj 2. |
| `test_coverage.sh` | **SKIP** | It is an OCaml bisect_ppx line-coverage reporter for the prototype's cerberus fork (dedicated instrumented opam switch, HTML reports) — measures OCaml code coverage, not differential correctness; orthogonal to this arc and needs switch-level setup we deliberately don't do. |
| `tests/float` corpus (69 .c files) | **DEFER (S4b, "if they run")** | Float support is a known weak spot (078-float-special is the standing test_core red; floats on the exec path largely unprobed); sweep in reporting mode after the minimal bar, numbers recorded, not gated. |
| `tests/debug` corpus (90 .c files) | **PORT (S4b)** | Minimal reproducers distilled from real prototype/Cerberus divergences (conv-, ptr-, unseq- categories); cheap to run through test_exec.sh in reporting mode and each hit is pre-minimized S3 material. |
| `test_pp.sh` / `test_pp_category.sh` / `find_pp_mismatches.sh` | **SKIP** | They diff the prototype's hand-written Core pretty-printer against OCaml `--pp core`; our pipeline has no real Core PP surface (CerbPP is placeholders), and their role — stage-level Core comparison — is subsumed by the charter's S4 `test_elab.sh` (elaborated Core vs `--pp core` via `canonicalize_ids.py`). |
| `fuzz_csmith.sh` / `gen_csmith.sh` | **PORT (S4b smoke run, small N)** | csmith 2.3.0 IS installed in this sandbox (`/usr/bin/csmith`, verified fresh 2026-08-19 after operator install); port = retarget the driver loop at test_exec.sh and carry over the prototype's `csmith_cerberus.h` shim; scale fuzzing stays NEXT-arc per charter. |
| `creduce_interestingness.sh` | **DEFER (networked-window item)** | `creduce` binary is NOT in the sandbox (`command -v creduce` empty, 2026-08-19); the script itself is a ~20-line interestingness predicate, trivially re-created against test_exec.sh once creduce is installable — nothing worth porting until then. |
| `strip_core_json.py` | **SKIP** | Operates on the prototype's Core-JSON export to shrink inputs for its GenProof proof-skeleton flow; cerberus-lean's interchange format is Cabs JSON (no Core-JSON export exists here) and the GenProof flow is out of arc scope — revisit only if a Core-level proof-generation pipeline lands. |

Notes:

- csmith availability changed mid-slice: the S2 brief's expectation was
  "probably absent → networked-window item"; the operator installed it
  during the slice, so the fuzz kit moved to "port, smoke run in S4b".
  No fuzzing was run in this slice (explicitly out of scope).
- The `tests/csmith/` infrastructure directory in the prototype
  (`csmith_cerberus.h`, seed corpus) travels with the fuzz-kit port.
- The prototype's `test_parser.sh`, `test_cn.sh`, `test_genproof.sh`,
  `docker_entrypoint.sh` are outside the charter's S2 survey list
  (parser testing is covered by our `test_parse.sh`/`test_core.sh`; CN
  and GenProof are out of project scope here) — noted for completeness,
  no disposition owed.
