"""Auditor's arithmetic reconstruction, not a run of the old C engine.

Positive alignments: Python divmod agrees with Zarith ediv_rem.
Schedules are derived from the five corpus programs and their allocation comments.
"""
from pathlib import Path
import subprocess
root = Path.cwd()
old = subprocess.check_output(['git', 'show', 'b9aeedcb4:memory/concrete/impl_mem.ml'], text=True)
start = old.index('  let allocator (sz: Z.t)')
print('Pristine source excerpt:\n' + old[start:old.index('  let allocator_with_address', start)])

def step(last, size, align, fixed):
    z = last - size
    if fixed and z < 0: return None
    q, m = divmod(z, align)
    address = z - (m if fixed or q >= 0 else -m)
    return address if address > 0 else None

def run(top, reqs, fixed):
    trace = []
    for size, align in reqs:
        address = step(top,size,align,fixed)
        trace.append((top,size,align,address))
        if address is None: break
        top=address
    return trace

schedules = {
    'array-40': [(4,4),(40,1)],
    'malloc-one': [(4,4),(8,8),(8,8),(8,8)],
    'nested-scopes': [(4,4)]*4,
    'three-ints-then-array': [(4,4)]*4+[(16,1)],
    'two-ints': [(4,4)]*3,
}
for name, reqs in schedules.items():
    for top in [64,32,8]:
        pre,post=run(top,reqs,False),run(top,reqs,True)
        assert pre==post
        print(f'{name}@{top}: old=fixed; (cursor,size,align,result): {post}')
print('P1: three-ints-then-array@32 has z=16-16=0, align=1, old zprime=0: KILL, never Specified(6).')
print('Discriminating replacement malloc(9)@32:', 'old', run(32,[(4,4),(8,8),(8,8),(9,8)],False), 'fixed', run(32,[(4,4),(8,8),(8,8),(9,8)],True))
