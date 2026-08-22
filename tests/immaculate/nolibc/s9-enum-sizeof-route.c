// sem:S9 probe (second leg): sizeof over the enum's registered type.
// Also pins the routing hazard: the Lean sizeof_ity answers Enum0 with
// a literal 4 instead of routing through typeof_enum, so it will NOT
// track the registry when the registry lands (the register's compound
// finding). With LP64 both routes give 4 today; the differential
// observable stays the signedness leg above — this file pins that
// sizeof agrees regardless (a control).
enum big { X = 100, Y = 200 };
int main(void) { return (int)sizeof(enum big); }
