import Driver
import Cabs_to_ail_effect
import Unit.FuelExemplar
open Lem_Map

-- These are universal projection equalities for the actual generated entries.
-- They do not substitute for the requested universal execution theorem.
theorem audit_initial_cursor (sup : Nat) (top : Int)
    (f : file core_run_annotation) (fs : CerbFS.FsState) :
    ((initial_driver_state sup top f fs).1).layout_state.lastAddress = top := rfl

theorem audit_given_cursor (sup : Nat) (top : Int)
    (f : file core_run_annotation) (fs : CerbFS.FsState) :
    ((initial_driver_state_given sup top f fs).1).layout_state.lastAddress = top := rfl

theorem audit_desugar_cursor (sup : Nat) (top : Int)
    (coreStuff : Fmap String sym × fun_map Unit × impl) (cn : init_scope) :
    (initial_state sup top coreStuff cn).inner.address_space_top = top := rfl

#print axioms audit_initial_cursor
#print axioms audit_given_cursor
#print axioms audit_desugar_cursor
#check initial_state
#check get_address_space_top
#print FuelExemplar.run
#check FuelExemplar.exemplar_certified_shipped_forall
