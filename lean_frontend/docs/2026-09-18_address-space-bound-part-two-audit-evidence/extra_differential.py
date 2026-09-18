"""Independent small-bound sweep and command-line refusal checks, audit only."""
from pathlib import Path
import subprocess, sys, os
root=Path.cwd(); out=root/'.tmp/audit-address-space-part-two/extra'; out.mkdir(exist_ok=True)
sys.path.insert(0,str(root/'scripts'))
from observations import parse
fork=root/'_build/default/backend/driver/main.exe'; lean=root/'lean_frontend/.lake/build/bin/cerberus-lean'; rt=root/'_build/install/default'
os.environ['NO_COLOR']='1'; os.environ['TERM']='dumb'; os.environ['LEAN_ABORT_ON_PANIC']='1'
programs=[root/'tests/address_space/two-ints.c',out/'malloc-nine.c']
programs[1].write_text('#include <stdlib.h>\nint main(void) { char *p = malloc(9); if (!p) return 3; p[0] = 2; return p[0]; }\n')
rows=[]
for c in programs:
    j=out/(c.stem+'.json')
    p=subprocess.run([str(fork),'--runtime='+str(rt),'--cabs-json',str(c)],capture_output=True,timeout=10)
    assert p.returncode==0,p.stderr
    j.write_bytes(p.stdout)
    basef=[str(fork),'--runtime='+str(rt),'--nolibc','--exec','--batch','--mode=exhaustive']
    basel=[str(lean),'--batch']
    for top in [1,3,4,7,8,9,12,13,16,17,24,25,31,32,33,40,41,64,65,2**64+9]:
        obs=[]
        for side,base,arg in [('fork',basef,c),('lean',basel,j)]:
            p=subprocess.run(base+['--address-space-top',str(top),str(arg)],capture_output=True,timeout=10)
            for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',str(p.returncode).encode())]:
                (out/f'{c.stem}.{top}.{side}.{suffix}').write_bytes(data)
            obs.append(parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full'))
        assert obs[0]==obs[1],(c.name,top,obs)
        print(f'{c.stem}@{top}: AGREE {obs[0]}')
    if c.stem=='two-ints':
        for value in ['0','abc','-1','0x40','64']:
            for side,base,arg in [('fork',basef,c),('lean',basel,j)]:
                p=subprocess.run(base+['--address-space-top',value,str(arg)],capture_output=True,timeout=10)
                print(f'CLI {side} {value}: rc={p.returncode}; {(p.stdout+p.stderr).decode(errors="replace").splitlines()[0]}')
print('Extra differential: 40/40 equal full observations (20 bounds, 2 programs); CLI matrix printed above.')
