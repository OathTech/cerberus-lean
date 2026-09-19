from pathlib import Path
import sys,subprocess,json,os,re,time
root=Path.cwd(); out=root/'.tmp/concurrency-design-audit'; inputs=out/'probes'
sys.path.insert(0,'/home/dev/projects/cerberus-lean-proj/cerberus-lean/scripts')
from observations import parse
side=sys.argv[1]
fork=root/'_build/default/backend/driver/main.exe'; lean=root/'lean_frontend/.lake/build/bin/cerberus-lean'
runtime='--runtime='+str(root/'_build/install/default')
os.environ.update(NO_COLOR='1',TERM='dumb',LEAN_ABORT_ON_PANIC='1')
results=[]
for source in sorted(inputs.glob('*.c')):
    if source.stem.startswith('atomic-unseq-'): continue  # two later exploratory inputs, recorded separately
    for model in ('sequential','sc'):
        dest=out/'captures'/source.stem/model;dest.mkdir(parents=True,exist_ok=True)
        flags=[] if model=='sequential' else ['--concurrency=sc']
        if side=='fork':
            args=[str(fork),runtime,'--nolibc','--exec','--batch','--mode=exhaustive',*flags,str(source)]
        else:
            ast=dest/'source.json'
            p=subprocess.run([str(fork),runtime,'--cabs-json',str(source)],capture_output=True)
            ast.write_bytes(p.stdout);(dest/'frontend.stderr').write_bytes(p.stderr)
            if p.returncode: print(source.stem,'frontend failure',p.returncode,flush=True);continue
            args=['/home/dev/projects/cerberus-lean-proj/cerberus-lean/scripts/capped',str(lean),'--batch',*flags,str(ast)]
        args=['timeout','30s',*args]
        start=time.monotonic();p=subprocess.run(args,capture_output=True,env={**os.environ,'CERB_MEM_MAX':'8G'})
        (dest/(side+'.stdout')).write_bytes(p.stdout);(dest/(side+'.stderr')).write_bytes(p.stderr);(dest/(side+'.status')).write_text(str(p.returncode)+'\n')
        row={'case':source.stem,'model':model,'side':side,'args':args,'status':p.returncode,'seconds':round(time.monotonic()-start,3)}
        try:
            obs=parse(p.stdout,p.stderr,p.returncode,'batch');row['tokens']=sorted(set(obs.tokens('full')));row['count']=len(obs.tokens('full'))
        except Exception as e:
            row['protocol_error']=str(e);row['diagnostics']=p.stderr.decode(errors='replace')[-2000:];row['stdout_tail']=p.stdout.decode(errors='replace')[-2000:]
        results.append(row)
        print(source.stem,model,side,p.returncode,row.get('tokens',row.get('protocol_error')),flush=True)
(out/(side+'-probes.json')).write_text(json.dumps(results,indent=2)+'\n')
