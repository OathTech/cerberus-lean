import sys, csv
from pathlib import Path
from collections import Counter
sys.path.insert(0, 'scripts')
import failure_census as fc, check_failure_reach as cfr
ROOT = Path('.').resolve(); OLD = ROOT/'.tmp/seam-hygiene/oldtree'
FILES = ['CerbMem','CerbFS','CerbDecode','CerbUtils','CerberusImpl','CerbLocation','CerbFloat','CoreParser','Main']
old_sites = {}; new_sites = {}
for f in FILES:
    for r in fc.census(OLD/f'lean_frontend/{f}.lean', OLD):
        old_sites[(r['file'], r['line'])] = (r['token'], cfr.msg_key(r['following_source']))
    for r in fc.census(ROOT/f'lean_frontend/{f}.lean', ROOT):
        new_sites[(r['file'], r['line'])] = (r['token'], cfr.msg_key(r['following_source']))
assert old_sites.keys() == new_sites.keys(), 'site set moved'
# old (file, token, msg) multiset -> list of (file,line)
by_key = {}
for k, (tok, msg) in old_sites.items(): by_key.setdefault((k[0], tok, msg), []).append(k)
rows, tally = cfr.read_register('scripts/failure_reach_register.txt')
changed = 0; prefixed = 0; unmatched = []
for r in rows:
    if r['token'] != 'panic!' or not r['file'].startswith('lean_frontend/'): continue
    cands = by_key.get((r['file'], 'panic!', r['msg']))
    if not cands: unmatched.append((r['file'], r['definition'], r['msg'])); continue
    k = cands.pop(0)
    ntok, nmsg = new_sites[k]
    assert ntok == 'failwithI', (k, ntok)
    r['token'] = ntok
    if nmsg != r['msg']: prefixed += 1
    r['msg'] = nmsg; changed += 1
if unmatched:
    print('UNMATCHED rows:', *unmatched, sep='\n  '); sys.exit(1)
out = cfr.HEADER + '# tally: ' + cfr.tally_line(rows) + '\n' + '\t'.join(cfr.COLS) + '\n' + ''.join('\t'.join(r[c] for c in cfr.COLS) + '\n' for r in rows)
Path('scripts/failure_reach_register.txt').write_text(out)
print(f'register: {changed} rows token panic!->failwithI ({prefixed} with a changed msg key); seals NOT yet recomputed')
