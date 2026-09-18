from pathlib import Path
import subprocess,os,sys,json
root=Path.cwd(); out=root/'.tmp/audit-address-space-part-two-rereview/cli'; out.mkdir(exist_ok=True)
sys.path.insert(0,str(root/'scripts'))
from observations import parse
fork=root/'_build/default/backend/driver/main.exe'; lean=root/'lean_frontend/.lake/build/bin/cerberus-lean'; runtime=root/'_build/install/default'
source=root/'tests/address_space/window-char-int7.c'; ast=out/'window.json'
os.environ.update(NO_COLOR='1',TERM='dumb',LEAN_ABORT_ON_PANIC='1')
p=subprocess.run([str(fork),'--runtime='+str(runtime),'--cabs-json',str(source)],capture_output=True,timeout=15);assert p.returncode==0,p.stderr;ast.write_bytes(p.stdout)
values=[None,'1','7','8','31','32','33','64','00064',str(2**63),str(2**64-1),'0',str(2**64),str(2**64+1),str(2**80),'-1','+64','0x40','0o100','0b1000000','6_4','6__4','64_','_64','_','0_0','00_64','1_8446744073709551615','1_8446744073709551616','64 ',' 64','abc','']
results=[]
for i,value in enumerate(values):
    valid=value is None or value.isascii() and value.isdigit() and 0<int(value)<2**64
    tokens=[];row={'input':value,'in_domain':valid}
    for side,base,arg in [('fork',[str(fork),'--runtime='+str(runtime),'--nolibc','--exec','--batch','--mode=exhaustive'],source),('lean',[str(lean),'--batch'],ast)]:
        args=base+([] if value is None else ['--address-space-top',value])+[str(arg)]
        p=subprocess.run(args,capture_output=True,timeout=15)
        (out/f'{i}.{side}.stdout').write_bytes(p.stdout);(out/f'{i}.{side}.stderr').write_bytes(p.stderr)
        (out/f'{i}.{side}.status').write_text(str(p.returncode)+'\n')
        row[side]={'status':p.returncode,'stderr':p.stderr.decode(errors='replace')}
        if valid:
            token=parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full');tokens.append(token);row[side]['tokens']=token
        else:
            row[side]['refused_as_expected'] = p.returncode==(124 if side=='fork' else 2) and not p.stdout
            if not row[side]['refused_as_expected']:
                row[side]['unexpected_stdout']=p.stdout.decode(errors='replace')
    if valid: assert tokens[0]==tokens[1],row
    results.append(row)
    print(f'{value!r}: in_domain={valid}; fork={row["fork"]["status"]}, lean={row["lean"]["status"]}'+(f'; tokens={tokens[0]}' if valid else f'; refused_as_expected fork={row["fork"]["refused_as_expected"]}, lean={row["lean"]["refused_as_expected"]}'))
(out/'results.json').write_text(json.dumps(results,indent=2)+'\n')
bad=[r['input'] for r in results if not r['in_domain'] and not all(r[s]['refused_as_expected'] for s in ['fork','lean'])]
print(f'CLI matrix: {len(values)} inputs; unexpected acceptance for {bad}')
