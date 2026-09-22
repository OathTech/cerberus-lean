from pathlib import Path
import subprocess,sys,json,time,os
root=Path.cwd();out=root/'.tmp/two-range-audit';sys.path.insert(0,str(root/'scripts'))
from observations import parse
base=Path('/home/dev/projects/cerberus-lean-proj/cerberus-lean')
records=[]
env={**os.environ,'NO_COLOR':'1','TERM':'dumb','LEAN_ABORT_ON_PANIC':'1','CERB_MEM_MAX':'8G'}
for source in sorted((out/'probes').glob('*.c')):
 dest=out/'captures'/source.stem;dest.mkdir(parents=True,exist_ok=True)
 ast=dest/'source.json'
 frontend=[str(root/'_build/default/backend/driver/main.exe'),'--runtime='+str(root/'_build/install/default'),'--cabs-json',str(source)]
 p=subprocess.run(frontend,capture_output=True,env=env,timeout=30)
 ast.write_bytes(p.stdout);(dest/'frontend.stderr').write_bytes(p.stderr)

 if p.returncode:
  records.append({'case':source.stem,'engine':'frontend','status':p.returncode,'stderr':p.stderr.decode(errors='replace')});print(source.stem,'FRONTEND FAILURE',p.returncode,flush=True);continue
 for name,engine in [('fork',root),('lean',root)]:
  if name.startswith('base-') and not (source.stem.startswith('stmt-') or source.stem=='sizeof-enum-control'): continue
  if name.endswith('lean'):
   args=[str(root/'scripts/capped'),str(engine/'lean_frontend/.lake/build/bin/cerberus-lean'),'--batch',str(ast)]
  else: args=[str(engine/'_build/default/backend/driver/main.exe'),'--runtime='+str(engine/'_build/install/default'),'--nolibc','--exec','--batch','--mode=exhaustive',str(source)]
  start=time.monotonic();p=subprocess.run(['timeout','30s',*args],capture_output=True,env=env)
  for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',str(p.returncode).encode())]:(dest/(name+'.'+suffix)).write_bytes(data)
  row={'case':source.stem,'engine':name,'args':args,'status':p.returncode,'seconds':round(time.monotonic()-start,3)}
  try:row['tokens']=sorted(set(parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full')))
  except Exception as e:row['protocol_error']=str(e);row['stderr_tail']=p.stderr.decode(errors='replace')[-1000:]
  records.append(row);print(source.stem,name,p.returncode,row.get('tokens',row.get('protocol_error')),flush=True)
(out/'probes-results.json').write_text(json.dumps(records,indent=2)+'\n')
