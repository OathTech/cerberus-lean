from pathlib import Path
import subprocess
root=Path.cwd(); out=root/'.tmp/audit-address-space-part-two-rereview';out.mkdir(exist_ok=True)
s=(root/'scripts/test_address_space.sh').read_text()
f=s[s.index('check_expectations() {'):s.index('\nif $RECORD;')]
ex=(root/'tests/address_space/expectations.txt').read_text()
ob=''.join(x+'\n' for x in ex.splitlines() if x and not x.startswith('#'))
first=next(x for x in ex.splitlines() if x and not x.startswith('#'))
cases={'control':ex,'phantom-newline':ex+'phantom\t64\tVAL:bogus\n','phantom-no-newline':ex+'phantom\t64\tVAL:bogus','duplicate-newline':ex+first+'\n','duplicate-no-newline':ex+first,'malformed-newline':ex+'broken-row\n','malformed-no-newline':ex+'broken-row','valid-no-final-newline':ex.rstrip('\n')}
(out/'observed.tsv').write_text(ob)
for name,data in cases.items():
    p=out/(name+'.txt');p.write_text(data)
    q=subprocess.run(['bash','-c','set -uo pipefail\n'+f+'\ncheck_expectations "$1" "$2"','audit',str(p),str(out/'observed.tsv')],capture_output=True,text=True)
    expected=0 if name in ('control','valid-no-final-newline') else 1
    assert q.returncode==expected,(name,q.stdout,q.stderr)
    print(f'{name}: exit={q.returncode}\n{q.stdout}{q.stderr}',end='')
