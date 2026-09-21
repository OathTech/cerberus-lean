from pathlib import Path
import subprocess,sys,json,os,time
root=Path.cwd();out=root/'.tmp/enum-premerge';sys.path.insert(0,str(root/'scripts'))
from observations import parse
base=Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/enum-base-20260920')
pristine=root/'.validation-foundations/independent-oracle-v2/cerberus'
records=[];env={**os.environ,'NO_COLOR':'1','TERM':'dumb','LEAN_ABORT_ON_PANIC':'1','CERB_MEM_MAX':'8G'}
for source in sorted((out/'probes').glob('*.c')):
 if not (source.stem.startswith('callback-') or source.stem in ['stmt-typeof-enum','stmt-typeof-int-control','stmt-sizeof-enum','stmt-sizeof-int-control','sizeof-enum-control']):continue
 dest=out/'captures'/source.stem;ast=dest/'source.json'
 for name,engine in [('base-fork',base),('base-lean',base),('pristine',pristine)]:
  if name.endswith('lean'):args=[str(root/'scripts/capped'),str(engine/'lean_frontend/.lake/build/bin/cerberus-lean'),'--batch',str(ast)]
  else:args=[str(engine/'_build/default/backend/driver/main.exe'),'--runtime='+str(engine/'_build/install/default'),'--nolibc','--exec','--batch','--mode=exhaustive',str(source)]
  t=time.monotonic();p=subprocess.run(['timeout','30s',*args],capture_output=True,env=env)
  for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',str(p.returncode).encode())]:(dest/(name+'.'+suffix)).write_bytes(data)
  row={'case':source.stem,'engine':name,'args':args,'status':p.returncode,'seconds':round(time.monotonic()-t,3)}
  try:row['tokens']=sorted(set(parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full')))
  except Exception as e:row['protocol_error']=str(e);row['stderr_head']=p.stderr.decode(errors='replace')[:1000]
  records.append(row);print(source.stem,name,p.returncode,row.get('tokens',row.get('protocol_error')),flush=True)
(out/'controls-results.json').write_text(json.dumps(records,indent=2)+'\n')
