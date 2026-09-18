"""Run the branch's exact check_expectations function against EOF mutations."""
from pathlib import Path
import subprocess
root=Path.cwd(); out=root/'.tmp/audit-address-space-part-two'
s=(root/'scripts/test_address_space.sh').read_text()
f=s[s.index('check_expectations() {'):s.index('\nif $RECORD;')]
ex=(root/'tests/address_space/expectations.txt').read_text()
(out/'observed.tsv').write_text(''.join(x+'\n' for x in ex.splitlines() if not x.startswith('#')))
cases={'control':ex,'phantom-newline':ex+'phantom\t64\tVAL:bogus\n','phantom-no-newline':ex+'phantom\t64\tVAL:bogus','duplicate-no-newline':ex+next(x for x in ex.splitlines() if not x.startswith('#')),'malformed-no-newline':ex+'broken-row','valid-last-row-no-newline':ex.rstrip('\n')}
for name,data in cases.items():
    p=out/(name+'.txt'); p.write_text(data)
    r=subprocess.run(['bash','-c','set -uo pipefail\n'+f+'\ncheck_expectations "$1" "$2"','audit',str(p),str(out/'observed.tsv')],capture_output=True,text=True)
    print(f'{name}: exit={r.returncode}\n{r.stdout}{r.stderr}',end='')
