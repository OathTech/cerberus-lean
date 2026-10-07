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

  THE SWITCH SET IS A PARAMETER (PNVI arc S1, 2026-10-05; record
  docs/2026-10-05_pnvi-s1-switch-parameter-record.md; design
  docs/2026-10-04_pnvi-ae-udi-design.md §B.3, option 3, accepted
  [USER 2026-10-05]): the switch set is the instance-implicit class
  `Switches` below — the `[LemFuel]` shape. `has_switch`, `is_PNVI` and
  `has_strict_pointer_arith` read `Switches.switches`; every definition
  that (transitively) reads them binds `[CerbGlobal.Switches]` (lem's
  instance reader, `frontend/model/lean_switches.lem`). NO instance of the
  class exists in this repository's library, seams, generated tree, tests
  or speclab (speedbump: `scripts/check_no_fuel_numerals.sh` rule W1); `Main.lean`
  supplies the one run instance, `⟨defaultSwitches⟩`, beside its
  `LemFuel` instance. A theorem quantifies by binding `[Switches]`, or
  states the default by `@f ⟨defaultSwitches⟩` / `@f ⟨[]⟩`, where every
  test reduces by `rfl`. DELIBERATE DIVERGENCE OF MECHANISM: OCaml reads
  the global `Switches.internal_ref`; this port reads the parameter — the
  `tagDefs`/`enum_definitions` precedent
  (docs/2026-09-18_program-data-parameters-design-note.md §1); the values
  are the same list. `is_CHERI` stays a BUILD constant (design §B.4.1).
  The rest of the configuration (`conf`) is still the plain default; its
  step 2 is not this slice's (`using_concurrency`'s belongs to the
  concurrency work, docs/2026-09-04_concurrency-scoping.md §4). The
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
    The lem file only exposes a subset of the full OCaml switch type; the
    constructors below are the lem subset PLUS (seam-hygiene H2, 2026-09-19,
    docs/2026-09-18_seam-hygiene-record.md §4 — fence extension granted
    2026-09-19) the four switches impl_mem.ml tests in its switch-conditioned
    arms, so those arms can be written in the explicit
    `if has_switch … then <loud kill> else <default>` shape and a consumer can
    state `has_switch … = false` by `rfl`. Naming mirrors switches.ml with the
    `SW_` prefix dropped, as for the existing constructors. No generated module
    matches on this type (Global.lean:61 only abbreviates it). -/

/-- The payload of `SW_pointer_arith of [ `PERMISSIVE | `STRICT ]`
    (switches.ml:5; `--switches=strict_pointer_arith` /
    `permissive_pointer_arith` read it at :65-67). -/
inductive PointerArithMode where
  | PERMISSIVE
  | STRICT
  deriving BEq, Inhabited, Repr

/-- The payload of `SW_PNVI of [ `PLAIN | `AE | `AE_UDI ]` (switches.ml:20;
    `--switches=PNVI` / `PNVI_ae` / `PNVI_ae_udi` read it at switches.ml:78-83). -/
inductive PNVIVariant where
  | PLAIN
  | AE
  | AE_UDI
  deriving BEq, Inhabited, Repr

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
  -- The four switches impl_mem.ml's switch-conditioned arms test (seam-hygiene
  -- H2), APPENDED after the lem subset so the derived `Inhabited` default stays
  -- `.strict_reads` (pre-merge audit M4: a first-placed constructor had moved it
  -- to `.pointer_arith .PERMISSIVE` — kernel-visible; pinned by `default_eq` below).
  -- switches.ml:5 `SW_pointer_arith of [ `PERMISSIVE | `STRICT ]`
  | pointer_arith (mode : PointerArithMode)
  -- switches.ml:15 `SW_strict_pointer_equality`
  | strict_pointer_equality
  -- switches.ml:18 `SW_strict_pointer_relationals`
  | strict_pointer_relationals
  -- switches.ml:32 `SW_zero_initialised`
  | zero_initialised
  -- switches.ml:20 `SW_PNVI of [ `PLAIN | `AE | `AE_UDI ]` (PNVI arc S1, 2026-10-05;
  -- appended so the derived `Inhabited` default stays `.strict_reads`). Lean-only:
  -- the lem subset (global.lem `cerb_switch`) does not gain it, because a new lem
  -- constructor changes the generated OCaml `Lem_global.cerb_switch` declaration
  -- (record §3, deviation D2); no lem code names it — `is_PNVI` is the only reader.
  | PNVI (v : PNVIVariant)
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

/-- THE SWITCH SET, as an instance-implicit parameter (PNVI arc S1; design §B.3).
    OCaml: the global `Switches.internal_ref` (switches.ml:47-48), read by
    `get_switches` (:51-52). One field; lem's instance reader
    `declare {lean} reader val switches = instance `CerbGlobal.Switches.switches``
    (frontend/model/lean_switches.lem) emits this projection, and every lifted
    definition binds `[CerbGlobal.Switches]`.

    Never declare an instance of this class in this repository; the entry point
    (`Main`) supplies it with `letI`; consumers declare their own. (Speedbump:
    `scripts/check_no_fuel_numerals.sh` rule W1 — not adversarially robust; the
    backstop is that Main's local instance wins for every lane, plus review.) -/
class Switches where
  switches : List CerbSwitch

/-- The default switch set: `Switches.internal_ref = ref []` (switches.ml:47-48) —
    the value the oracle holds when no `--switches`/`--iso` is passed. FORCED by
    OCaml, not a magic value. `Main.lean` runs every program at
    `⟨defaultSwitches⟩` (it refuses every `--switches` value, Z-24). Renamed from
    `CerbGlobal.switches` in PNVI arc S1. -/
def defaultSwitches : List CerbSwitch := []

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

/-! ## Switch accessors (mirror switches.ml:54-55, 153-160) — read the parameter -/

/-- `has_switch sw = List.mem sw !internal_ref` (switches.ml:54-55), over the
    parameter. -/
def has_switch [Switches] (sw : CerbSwitch) : Bool :=
  Switches.switches.any (· == sw)

/-- `List.exists (function SW_CHERI -> true | _ -> false) !internal_ref`
    (switches.ml:153-154). A BUILD CONSTANT here, not a read of the parameter
    (design §B.4.1, accepted [USER 2026-10-05] §F.9): CHERI is a memory-MODEL
    selection upstream (the separate `cerberus-cheri` executable injects "CHERI",
    main.ml:130-136); this port has the concrete model alone, and `--switches=CHERI`
    is refused at the CLI. Lifting it would put the binder on `sizeofCtype` and
    every layout function for a value that is always `false` in this executable.
    Deliberate divergence of mechanism, documented. -/
def is_CHERI (_ : Unit) : Bool := false

/-- `List.exists (function SW_PNVI _ -> true | _ -> false) !internal_ref`
    (switches.ml:156-157), over the parameter. -/
def is_PNVI [Switches] (_ : Unit) : Bool :=
  Switches.switches.any (fun | .PNVI _ => true | _ => false)

/-- `has_switch (SW_pointer_arith `STRICT)` (switches.ml:159-160). -/
def has_strict_pointer_arith [Switches] (_ : Unit) : Bool :=
  has_switch (.pointer_arith .STRICT)

/-! ## The contract: what the kernel sees
    Each configuration read is its default by `rfl`. The switch reads are
    stated AT THE DEFAULT INSTANCE `⟨defaultSwitches⟩` (= `⟨[]⟩`), where each
    is `false` by `rfl` (`List.any [] p = false` is definitional); a consumer
    declares its own local instance at `defaultSwitches` (or binds `[Switches]`
    to quantify), and its proofs through a switch test rewrite with these. The
    eight `has_switch_*_eq` lemmas of seam-hygiene H2 are replaced by these
    instance-explicit forms (PNVI arc S1). -/

theorem backend_name_eq : backend_name () = "Driver" := rfl
theorem current_execution_mode_eq : current_execution_mode () = none := rfl
theorem using_concurrency_eq : using_concurrency () = false := rfl
theorem isDefacto_eq : isDefacto () = false := rfl
theorem isPermissive_eq : isPermissive () = false := rfl
theorem isAgnostic_eq : isAgnostic () = false := rfl
theorem isIgnoreBitfields_eq : isIgnoreBitfields () = false := rfl
theorem defaultSwitches_eq : defaultSwitches = [] := rfl
theorem has_switch_default (sw : CerbSwitch) : @has_switch ⟨defaultSwitches⟩ sw = false := rfl
theorem has_switch_nil (sw : CerbSwitch) : @has_switch ⟨[]⟩ sw = false := rfl
-- per switch, at the default (the arms of impl_mem.ml CerbMem tests, seam-hygiene H2,
-- the two lem-model switches, and the PNVI family):
theorem has_switch_strict_reads_default : @has_switch ⟨[]⟩ .strict_reads = false := rfl
theorem has_switch_forbid_nullptr_free_default : @has_switch ⟨[]⟩ .forbid_nullptr_free = false := rfl
theorem has_switch_zap_dead_pointers_default : @has_switch ⟨[]⟩ .zap_dead_pointers = false := rfl
theorem has_switch_inner_arg_temps_default : @has_switch ⟨[]⟩ .inner_arg_temps = false := rfl
theorem has_switch_permissive_printf_default : @has_switch ⟨[]⟩ .permissive_printf = false := rfl
theorem has_switch_no_integer_provenance_default : @has_switch ⟨[]⟩ .no_integer_provenance = false := rfl
theorem has_switch_cheri_default : @has_switch ⟨[]⟩ .cheri = false := rfl
theorem has_switch_strict_pointer_equality_default : @has_switch ⟨[]⟩ .strict_pointer_equality = false := rfl
theorem has_switch_strict_pointer_relationals_default : @has_switch ⟨[]⟩ .strict_pointer_relationals = false := rfl
theorem has_switch_pointer_arith_permissive_default : @has_switch ⟨[]⟩ (.pointer_arith .PERMISSIVE) = false := rfl
theorem has_switch_pointer_arith_strict_default : @has_switch ⟨[]⟩ (.pointer_arith .STRICT) = false := rfl
theorem has_switch_zero_initialised_default : @has_switch ⟨[]⟩ .zero_initialised = false := rfl
theorem has_switch_PNVI_default (v : PNVIVariant) : @has_switch ⟨[]⟩ (.PNVI v) = false := rfl
-- the derived `Inhabited` default is the first constructor, `.strict_reads` — pinned so a
-- constructor reorder cannot move it silently again (pre-merge audit M4)
example : (default : CerbSwitch) = .strict_reads := rfl
theorem is_CHERI_eq : is_CHERI () = false := rfl
theorem is_PNVI_default : @is_PNVI ⟨[]⟩ () = false := rfl
theorem has_strict_pointer_arith_default : @has_strict_pointer_arith ⟨[]⟩ () = false := rfl

end CerbGlobal
