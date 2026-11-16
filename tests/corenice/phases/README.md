# Normalized-AIL phase witnesses

Run `python3 scripts/corenice-phase-tests.py --root /path/to/provisioned/checkout`.
The script uses that checkout's comparator and binaries while retaining these
fixtures as its inputs. `--case NAME` selects a focused case. The comparator
bounds each process and deletes its scratch Cabs files and tapes.

`T`, `B` and `I` identify guard, body and for-increment effects. Numbered markers
print the counter value after its update. The harness checks each phase's exact
stdout prefix, final counters/output, and both directions of record/replay:

* While restart follows the completed body or continue path; its next guard is
  still pending. For loops reach this same normalized-while phase after increment.
* Do condition pending follows the completed body or continue path; that
  iteration's condition has not executed.
  A continue nested inside a switch reaches this phase, while a later outer
  loop break bypasses it; the switch's own break retains its distinct target.
* Condition ready follows successful if/while boolean preparation. Guard UB
  after an output marker does not create this phase.
* Break and return bypass the loop tail; a false while guard never enters it.
  UB in a for increment prevents restart, even after the increment's marker.
* A goto directly into a loop suffix can reach restart without having entered
  through its guard or executed the beginning of its body.

Every generated pause must carry the v2 normalized-AIL occurrence/slot origin;
static origins and roles remain consistent across visits. These checks use the
actual ordered stdout channel at a pause, not reconstructed cross-channel
ordering. They are bounded operational witnesses, not C-source provenance,
complete midpoint-state relations or a simulation theorem.
