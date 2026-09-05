/-
  Cerberus configuration and switches — the DEFAULT configuration as
  plain definitions.
  Corresponds to: util/cerb_global.ml and ocaml_frontend/switches.ml

  This is a leaf module — no imports from generated code.

  WHAT THIS FILE IS (reasoning-artifact audit instance A, step 1 —
  docs/2026-09-03_reasoning-artifact-audit.md §2.A; the record is
  docs/2026-09-05_cerbglobal-defs-record.md): every configuration read
  the lem model makes through `Global.*` / `Switches.*` (global.lem) is a
  plain `def` of the value the OCaml driver holds in matched mode —
  kernel-transparent, `rfl`-unfoldable, no process state. Until
  2026-09-05 the same eleven names were `opaque … implemented_by`
  wrappers over two `IO.Ref`s that NOTHING ever wrote (no setter was
  exposed; `Main` refuses `--switches`/`--concurrency`/`--mode` outright,
  zero-discrepancy Z-24), so every read already returned these values at
  runtime — the kernel was just not told. Behaviour is identical by
  construction; the differential battery at zero movement is the proof
  (record §5).

  THE OCAML SIDE, line by line (the fork at this commit; the defaults are
  the driver's, `backend/driver/main.ml`):
  * `Cerb_global.set_cerb_conf ~backend_name:"Driver" ~exec exec_mode
    ~concurrency QuoteStd ~defacto ~permissive ~agnostic ~ignore_bitfields`
    (main.ml:124) is the ONE write of `cerb_conf` (cerb_global.ml:32-43);
    the readers `backend_name`/`concurrency_mode`/`isDefacto`/
    `isPermissive`/`isAgnostic`/`isIgnoreBitfields`/
    `current_execution_mode` are cerb_global.ml:45-64.
  * `--defacto`, `--permissive`, `--agnostic`, `--dignore-bitfields`,
    `--concurrency` are `Arg.flag`s (main.ml:515-517, 519-521, 421-424,
    426-432, 496-498): FALSE unless passed; this port refuses them (Z-24).
  * `exec_mode_opt = if exec then Some exec_mode else None`
    (cerb_global.ml:36) with `--mode` defaulting to `Random`
    (main.ml:438-441): `Some Exhaustive` under the exec lanes'
    `--mode=exhaustive`, `Some Random` under the bare default. See
    `execMode` below for why this port's value is `none`.
  * `Switches.internal_ref = ref []` (switches.ml:47-48), written only by
    `Switches.set` / `set_iso_switches` from `--switches`/`--iso`
    (main.ml:129-143; the CHERI build variant adds "CHERI" itself, :130-136
    — not this build). `has_switch sw = List.mem sw !internal_ref`
    (:54-55); `is_CHERI` (:153-154), `is_PNVI` (:156-157),
    `has_strict_pointer_arith` (:159-160) are `List.exists`/`has_switch`
    over the same list.

  STEP 2 (NOT this file's job; the named mover of the former allowlist
  rows, `temporal(post-arc-parameter-plumbing-slice)`): the configuration
  becomes a reader-lifted PARAMETER exactly as `tagDefs` is (`declare
  {lean} reader val` on the `Global.*` reads in global.lem), so a theorem
  quantifies over switch settings. `using_concurrency`'s step 2 belongs
  to `feature/concurrency` (docs/2026-09-04_concurrency-scoping.md §4: "the
  feature branch OWNS A-step-2 for `using_concurrency` only"). The
  `CerbConf` structure below is kept as the value type that parameter
  will have.
-/

namespace CerbGlobal

/-! ## Execution Mode
    Corresponds to: Cerb_global.execution_mode (cerb_global.ml:14-16) -/

inductive ExecutionMode where
  | exhaustive
  | random
  deriving BEq, Inhabited, Repr

/-! ## Switches
    Corresponds to: Switches.cerb_switch in switches.ml:1-44
    The lem file only exposes a subset of the full OCaml switch type. -/

inductive CerbSwitch where
  | strict_reads
  | forbid_nullptr_free
  | zap_dead_pointers
  | inner_arg_temps
  | permissive_printf
  -- DECLARED (zero-discrepancy Z2-G-02, INSTRUMENT): the lem model's
  -- `SW_no_integer_provenance` (global.lem:66) names `Switches.SW_no_integer_
  -- provenance` as its OCaml target_rep (global.lem:81) — a constructor
  -- ABSENT from switches.ml:1-44 (a lem-side inconsistency, tray candidate);
  -- this Lean constructor is its target_rep (global.lem:82). No generated
  -- module references it (grep), and the switch set is refused (Z-24) — a
  -- dead constructor kept so the lem declaration stays resolvable.
  | no_integer_provenance
  | cheri
  deriving BEq, Inhabited, Repr

/-! ## Configuration
    Corresponds to: Cerb_global.cerberus_conf (cerb_global.ml:18-28); the
    field defaults are the values `set_cerb_conf` receives from the driver
    with no flag passed (main.ml:124 + the flag defaults cited in the
    header). -/

structure CerbConf where
  -- main.ml:124 `~backend_name:"Driver"`. Every read in the model is a
  -- test against "Cn" or "Bmc" (cabs_to_ail_effect.lem:676,
  -- translation_effect.lem:231, translation.lem:409/1732/1741,
  -- core_aux.lem:552-553 — the complete set; derived grep census in the
  -- record §2), so "Driver" and any other non-Cn/non-Bmc name behave
  -- identically; the value is the oracle's.
  backendName : String := "Driver"
  -- DECLARED (zero-discrepancy Z2-G-01, INSTRUMENT): the oracle's
  -- `current_execution_mode` is `Some Exhaustive` under `--mode=exhaustive`
  -- and `Some Random` under the bare default (main.ml:438-441); its ONE live
  -- exec-cone read, driver.lem:1380, takes the same branch for `none` and
  -- `Some Exhaustive` (driver.lem:748's `_execution_mode_is_random` is an
  -- unused binding). Two lanes run the oracle without `--mode` (single-
  -- verdict programs: the unique step is picked either way). Mode flags are
  -- refused by this port (Z-24); this port's trace selection (`--first`) is
  -- the explicit `firstTrace` argument `Main` threads to the runner choice
  -- (`CerbND.runND1` vs `runND`, Main.lean:967) and never flows into this
  -- value — so it is NOT a CLI-chosen value here, and `none` is what the
  -- binary has always computed. Whether `--first` should set `Random` to
  -- mirror the oracle's `--mode=random` lanes is a step-2 question (the
  -- read becomes a parameter there), NOT decided by this step.
  execMode : Option ExecutionMode := none
  -- main.ml:496-498 `--concurrency` flag (refused here, Z-24; the oracle's
  -- own mode is non-functional at the fork base, "CONCURRENCY IS BROKEN").
  concurrency : Bool := false
  -- main.ml:515-517 `--defacto` flag.
  defacto : Bool := false
  -- main.ml:519-521 `--permissive` flag.
  permissive : Bool := false
  -- main.ml:421-424 `--agnostic` flag.
  agnostic : Bool := false
  -- main.ml:426-432 `--dignore-bitfields` flag.
  ignoreBitfields : Bool := false
  deriving Inhabited

/-- The configuration this port runs under: the driver's defaults
    (cerb_global.ml:35-43 with no flag passed). -/
def conf : CerbConf := {}

/-- The switch set: `Switches.internal_ref = ref []` (switches.ml:47-48),
    never written — `--switches`/`--iso` are refused (Z-24). -/
def switches : List CerbSwitch := []

/-! ## Config accessors (mirror cerb_global.ml:45-64) -/

def backend_name (_ : Unit) : String :=
  conf.backendName

def current_execution_mode (_ : Unit) : Option ExecutionMode :=
  conf.execMode

def using_concurrency (_ : Unit) : Bool :=
  conf.concurrency

def isDefacto (_ : Unit) : Bool :=
  conf.defacto

def isPermissive (_ : Unit) : Bool :=
  conf.permissive

def isAgnostic (_ : Unit) : Bool :=
  conf.agnostic

def isIgnoreBitfields (_ : Unit) : Bool :=
  conf.ignoreBitfields

/-! ## Switch accessors (mirror switches.ml:54-55, 153-160) -/

/-- `has_switch sw = List.mem sw !internal_ref` (switches.ml:54-55). -/
def has_switch (sw : CerbSwitch) : Bool :=
  switches.any (· == sw)

/-- `List.exists (function SW_CHERI -> true | _ -> false) !internal_ref`
    (switches.ml:153-154). -/
def is_CHERI (_ : Unit) : Bool :=
  has_switch .cheri

/-- `List.exists (function SW_PNVI _ -> true | _ -> false) !internal_ref`
    (switches.ml:156-157) over the empty list; `SW_PNVI` is not in the lem
    subset (`CerbSwitch`), so the test is written as its value. -/
def is_PNVI (_ : Unit) : Bool := false

/-- `has_switch (SW_pointer_arith `STRICT)` (switches.ml:159-160) over the
    empty list; `SW_pointer_arith` is not in the lem subset. -/
def has_strict_pointer_arith (_ : Unit) : Bool := false

/-! ## The contract: what the kernel sees
    Each read is its default by `rfl`; a consumer's proof through a switch
    test rewrites with these (or unfolds) instead of `cases` on an opaque
    `Bool` and proving the arm the binary can never take. -/

theorem backend_name_eq : backend_name () = "Driver" := rfl
theorem current_execution_mode_eq : current_execution_mode () = none := rfl
theorem using_concurrency_eq : using_concurrency () = false := rfl
theorem isDefacto_eq : isDefacto () = false := rfl
theorem isPermissive_eq : isPermissive () = false := rfl
theorem isAgnostic_eq : isAgnostic () = false := rfl
theorem isIgnoreBitfields_eq : isIgnoreBitfields () = false := rfl
theorem has_switch_eq (sw : CerbSwitch) : has_switch sw = false := rfl
theorem is_CHERI_eq : is_CHERI () = false := rfl
theorem is_PNVI_eq : is_PNVI () = false := rfl
theorem has_strict_pointer_arith_eq : has_strict_pointer_arith () = false := rfl

end CerbGlobal
