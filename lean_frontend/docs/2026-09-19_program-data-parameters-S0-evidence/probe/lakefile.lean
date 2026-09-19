import Lake
open Lake DSL

package Probe where
  version := v!"0.1.0"
  moreLeanArgs := #["-DautoImplicit=false"]

require LemLib from "../lean-lib"

@[default_target]
lean_lib Probe where
  srcDir := "."
  roots := #[`ProbeImpl,
             `Probe_readers, `Probe_readers_auxiliary, `ProbeCheck,
             `Probe_seed1, `Probe_seed1_auxiliary,
             `Pm_readers, `Pm_readers_auxiliary, `Pm_use, `Pm_use_auxiliary, `PmCheck, `Seed1Check]

/-- NEGATIVE control (not a default target): the assert-rooted reader read;
    its generated auxiliary references the unbound `_lemReader_*` names. -/
lean_lib NegAssert where
  srcDir := "."
  roots := #[`Neg_nonlifted_assert, `Neg_nonlifted_assert_auxiliary]
