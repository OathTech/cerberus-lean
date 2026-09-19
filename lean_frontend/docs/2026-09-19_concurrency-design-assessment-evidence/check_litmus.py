from pathlib import Path
import sys,subprocess,os,json,time
root=Path.cwd();out=root/'.tmp/concurrency-design-audit/litmus';out.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,'/home/dev/projects/cerberus-lean-proj/cerberus-lean/scripts')
from observations import parse
fork=root/'_build/default/backend/driver/main.exe';lean=root/'lean_frontend/.lake/build/bin/cerberus-lean';runtime='--runtime='+str(root/'_build/install/default')
rows={}
for line in (root/'tests/litmus/expectations.txt').read_text().splitlines():
 if line and not line.startswith('#'):
  name,cls,target=line.split();assert name not in rows;rows[name]=(cls,target)
assert set(rows)=={p.name for p in (root/'tests/litmus').glob('*.c')}
env={**os.environ,'NO_COLOR':'1','TERM':'dumb','LEAN_ABORT_ON_PANIC':'1','CERB_MEM_MAX':'8G'}
results=[]
for name,(cls,target) in sorted(rows.items()):
 source=root/'tests/litmus'/name;dest=out/name;dest.mkdir(exist_ok=True)
 p=subprocess.run([str(fork),runtime,'--cabs-json',str(source)],capture_output=True,env=env);assert p.returncode==0
 ast=dest/'source.json';ast.write_bytes(p.stdout)
 obs={};row={'name':name,'class':cls,'target':target}
 for side,args in [('fork',[str(fork),runtime,'--nolibc','--exec','--batch','--mode=exhaustive','--concurrency=sc',str(source)]),('lean',['/home/dev/projects/cerberus-lean-proj/cerberus-lean/scripts/capped',str(lean),'--batch','--concurrency=sc',str(ast)])]:
  args=['timeout','45s',*args];t=time.monotonic();p=subprocess.run(args,capture_output=True,env=env)
  for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',(str(p.returncode)+'\n').encode())]:(dest/(side+'.'+suffix)).write_bytes(data)
  row[side]={'args':args,'status':p.returncode,'seconds':round(time.monotonic()-t,3)}
  try:
   o=parse(p.stdout,p.stderr,p.returncode,'batch');obs[side]=o;row[side]['full_set']=sorted(set(o.tokens('full')));row[side]['count']=len(o.verdicts)
  except Exception as e:row[side]['error']=str(e)
 ok=len(obs)==2 and row['fork']['full_set']==row['lean']['full_set']
 if ok:
  o=obs['fork'];tokens=[]
  for v in o.verdicts:
   tokens.append(v.field('value').decode() if v.kind=='Defined' else v.field('ub').decode() if v.kind=='Undefined' else 'ERROR')
  rendered='{'+','.join(sorted(set(tokens)))+'}'
  if target=='REFUSE':ok=len(o.verdicts)==1 and o.verdicts[0].kind=='Error' and o.verdicts[0].field('msg').startswith(b'model refused: ')
  else:ok=rendered==target
  row['projection']=rendered
 row['passed']=ok;results.append(row);print(name,'PASS' if ok else 'FAIL',flush=True)
(out/'results.json').write_text(json.dumps(results,indent=2)+'\n');print('Independent checked litmus:',sum(r['passed'] for r in results),'/',len(results),flush=True)
sys.exit(0 if all(r['passed'] for r in results) else 1)
