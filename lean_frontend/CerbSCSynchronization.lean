import Sc_synchronization
import CerbSCAtomicSources

set_option autoImplicit true
namespace CerbSCSynchronization

theorem inputs_retained graph aliases inputs receipts :
    (sc_replay_synchronization graph aliases inputs receipts).sc_sync_original = inputs := rfl

theorem receipts_retained graph aliases inputs receipts :
    (sc_replay_synchronization graph aliases inputs receipts).sc_sync_atomic_receipts = receipts := rfl

theorem source_graph_retained graph aliases inputs receipts :
    (sc_replay_synchronization graph aliases inputs receipts).sc_sync_hb.sc_hb_source = graph := rfl

theorem aliases_retained graph aliases inputs receipts :
    (sc_replay_synchronization graph aliases inputs receipts).sc_sync_hb.sc_hb_aliases = aliases := rfl

/-- Both pinned sequence predicates ignore the location-kind parameter. -/
theorem release_sequence_kind_independent (actions : Pset sc_ref_action) mo
    (left right : sc_ref_location → sc_ref_location_kind) :
    sc_ref_release_sequence_set actions left mo = sc_ref_release_sequence_set actions right mo := rfl

theorem hypothetical_sequence_kind_independent (actions : Pset sc_ref_action) mo
    (left right : sc_ref_location → sc_ref_location_kind) :
    sc_ref_hypothetical_release_sequence_set actions left mo =
      sc_ref_hypothetical_release_sequence_set actions right mo := rfl

/-- Query SW always feeds the one existing all-vertex HB construction. -/
theorem shared_hb_connection graph aliases inputs receipts :
    (sc_replay_synchronization graph aliases inputs receipts).sc_sync_hb =
      sc_build_happens_before graph aliases
        ((setToList (sc_replay_synchronization graph aliases inputs receipts).sc_sync_sw).map
          (fun (a,b) => (sc_ref_aid_of a, sc_ref_aid_of b))) := rfl

/-- Source diagnostics cannot be silently resolved into an RF edge. -/
theorem unresolved_source actions receipt
    (unresolved : receipt.sc_atomic_source_issues.isEmpty = false) :
    (sc_sync_resolve actions receipt).sc_sync_resolved_edge = none ∧
    (sc_sync_resolve actions receipt).sc_sync_edge_issues = [SC_sync_unresolved_atomic_source receipt] := by
  simp [sc_sync_resolve, unresolved]

end CerbSCSynchronization
