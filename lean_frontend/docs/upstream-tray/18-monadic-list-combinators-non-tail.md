# Draft 18 — Non-tail monadic list combinators in the front-end monads make the stack depth proportional to aggregate size (8 M-element static initialiser overflows)

Target: `rems-project/cerberus` (`frontend/model/ail/errorMonad.lem`,
`frontend/model/state_exception.lem`, `frontend/model/undefined.lem`;
same shape in the sibling monad modules — see "Scope"). Drafted
2026-09-02 (arc/mem-scale S1'); NOT filed. Classification: **TRUE BUG
(robustness; loud-failure class on the OCaml target, silent-hang class
on our Lean target)** with a semantics-preserving remedy that is
ordinary library hygiene (accumulate-and-reverse). Cited lines verified
against upstream `master` @ `b9aeedcb4` (the merge base of our tree):
`errorMonad.lem` and `undefined.lem` are byte-identical to it;
`state_exception.lem` differs only by 7 appended Lean-target-only
`declare {lean} termination_argument` lines (fork, 2026-08-29) — the
cited definitions are identical.

## The shape

```
(* frontend/model/ail/errorMonad.lem:86-92 *)
let rec ailErr_mapM f ys =
  match ys with
  | []      -> return []
  | (x::xs) -> f x       >>= fun z  ->
               ailErr_mapM f xs >>= fun zs ->
               return (z::zs)
end
```

The error monad is function-typed (`errorMonad.lem:41`: `let bind
(ErrorM m) f = ErrorM (fun ts -> match m ts with … | Right (a, ts') ->
run (f a) ts')`), so running `ailErr_mapM f (x::xs)` runs the recursive
call INSIDE the frame that must afterwards cons `z` onto its result:
one stack frame per list element. `state_exception.lem:50-57`
(`sequence`, hence `stExpect_mapM`/`mapiM`) and `:79-82` (`foldrM`) have
the same shape in the state-exception monad; `undefined.lem:1442-1445`
(`sequence`, hence `mapM`) builds the same nesting through `List.foldr`
(`List.fold_right` on the OCaml target — itself non-tail).

## Where it bites

A zero-initialised static aggregate is desugared to an N-element
`ConstantArray` (`cabs_to_ail_aux.lem:123-124`, `List.replicate
(natFromInteger n) (mk_zeroInit_aux tagDefs elem_ty)`) and then type-checked with `E.mapM
(typecheck_constant loc) csts` (`ail/genTyping.lem:484`) — recursion
depth N. Reproducer:

```c
char g[8000000];
int main(void) { g[8000000 - 1] = 7; return g[8000000 - 1] + g[0]; }
```

- OCaml target, default 8 MB system stack: completes (OCaml 5's
  effect-based stack grows on the heap), 10 M elements in ~246 s /
  7.7 GB RSS on our box — so upstream users see cost, not failure.
  With a bounded stack the failure is LOUD and correctly attributed
  (verbatim, `OCAMLRUNPARAM=l=200000`, exit 125 in 0.03 s):
  `Called from Lem_list.replicate in file "lem_list.ml", line 341,
  characters 46-61` (the `replicate` frame; `lem_list.ml`'s
  `replicate` is itself non-tail — a separate note for lem).
- Our Lean target (compiled to C, 1 GiB runtime-thread stack): the
  recursion overflows at ~7–8 × 10^6 ELEMENTS (element-count driven:
  `int g[2500000]` completes, `char g[8000000]` does not) and — a Lean
  runtime defect, reported separately — the overflow handler deadlocks,
  so the tool hangs silently. Record: cerberus-lean
  `lean_frontend/docs/2026-09-01_mem-scale-profile.md` §6.2–6.3.

## Remedy (semantics-preserving; the change our fork carries)

Accumulate-and-reverse: run each element's action, cons the result onto
an accumulator, recurse in tail position of the continuation, reverse
once at the end. Effect ORDER is unchanged (element i's action still
runs after element i−1's succeeded and before element i+1's; the annots
state threads left to right exactly as before); the first failing
element still short-circuits with its error (`bind` returns `Left`
without invoking the continuation); the result list is the same list.

```
let rec ailErr_mapM_aux f acc ys =
  match ys with
  | []      -> return (List.reverse acc)
  | (x::xs) -> f x >>= fun z -> ailErr_mapM_aux f (z::acc) xs
end
let ailErr_mapM f ys = ailErr_mapM_aux f [] ys
```

For `foldrM` (a RIGHT fold: the last element's action runs first) the
equivalent is `foldrM f a l = foldlM (fun acc x -> f x acc) a (List.reverse l)`
— same action order (last element first), same short-circuit, same
result — using the already tail-position `stExcept_foldlM`. For the
`sequence`s the same accumulate-and-reverse form replaces the `foldr`.

Our fork's validation of the rewrite: the full differential battery
(both targets re-derived from the changed `.lem`) byte-identical to its
baselines, plus a completion gate on the 8 M / 10 M inputs; see the
arc record `lean_frontend/docs/2026-09-02_mem-scale-record.md` §S1'.

## Scope

The same shape exists in `exception.lem:54-61` (`except_sequence`),
`exception_undefined.lem:45-50` (`exception_undef_sequence`), `:66-70`
(`exception_undef_foldrM`), `state.lem:48-54` (`sequence`), `:82-87`
(`foldrM`), `state_exception_undefined.lem:96-103` (`sequence`), and
`nondeterminism.lem:147-153` (`sequence`). Upstream may prefer to fix
the family in one pass; our fork's S1' rewrites the three front-end
modules on the located path (`errorMonad`, `state_exception`,
`undefined`) and lists the rest here.

## Provenance

Found and analysed by an AI agent (Claude) during this project's
memory-scale profiling; all quoted outputs are verbatim from recorded
runs. Per this tray's labeling policy, the filed issue/PR must carry an
explicit AI-provenance note; commits carry the Co-Authored-By trailer.
