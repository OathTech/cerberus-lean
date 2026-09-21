from pathlib import Path
import subprocess,sys,json,os,time
root=Path.cwd();out=root/'.tmp/enum-premerge/integration';out.mkdir(exist_ok=True);sys.path.insert(0,str(root/'scripts'))
from observations import parse
cases={
 'multi-enums': ['enum E {A=-1,B}; enum E global_a=A; int f(void){return global_a<0;}','enum E {A,B}; enum E global_b=(enum E)-1; int f(void); int main(void){return f()+2*(global_b>0);}'],
 'cross-struct': ['enum E {A=-1,B}; struct S {enum E x;}; struct S s={A}; int f(void){return s.x;}','enum E {A=-1,B}; struct S {enum E x;}; extern struct S s; int f(void); int main(void){return (s.x==f())+2*(s.x<0);}'],
 'typeof-arithmetic': ['enum E {A,B};int main(void){enum E e=B;typeof(e+1)y=3;return y;}'],
 'call-enum': ['enum E {A=-1,B}; enum E g=A; int f(enum E x){return (g<0)+2*(x<0);} int main(void){return f(A);}'],
}
env={**os.environ,'NO_COLOR':'1','TERM':'dumb','LEAN_ABORT_ON_PANIC':'1','CERB_MEM_MAX':'8G'};results=[]
for name,sources in cases.items():
 d=out/name;d.mkdir(exist_ok=True);cs=[];asts=[]
 for i,source in enumerate(sources):
  c=d/(str(i)+'.c');c.write_text(source+'\n');ast=d/(str(i)+'.json');cs.append(str(c));asts.append(str(ast))
  args=[str(root/'_build/default/backend/driver/main.exe'),'--runtime='+str(root/'_build/install/default'),'--cabs-json',str(c)]
  p=subprocess.run(args,capture_output=True,env=env,timeout=30);ast.write_bytes(p.stdout);assert p.returncode==0,p.stderr
 for order in ([list(range(len(cs))),list(reversed(range(len(cs))))] if len(cs)>1 else [[0]]):
  for side in ['fork','lean']:
   args=([str(root/'_build/default/backend/driver/main.exe'),'--runtime='+str(root/'_build/install/default'),'--nolibc','--exec','--batch','--mode=exhaustive',*[cs[i] for i in order]] if side=='fork' else [str(root/'scripts/capped'),str(root/'lean_frontend/.lake/build/bin/cerberus-lean'),'--batch',*[asts[i] for i in order]])
   p=subprocess.run(['timeout','30s',*args],capture_output=True,env=env)
   stem=side+'-'+''.join(map(str,order))
   for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',str(p.returncode).encode())]:(d/(stem+'.'+suffix)).write_bytes(data)
   r={'case':name,'order':order,'side':side,'args':args,'status':p.returncode}
   try:r['tokens']=sorted(set(parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full')))
   except Exception as e:r['protocol_error']=str(e);r['stderr_head']=p.stderr.decode(errors='replace')[:1500]
   results.append(r);print(name,order,side,p.returncode,r.get('tokens',r.get('protocol_error')),flush=True)
 # --call companion: same f(-1) as the main wrapper; Lean-only CLI compared with both main runs
 if name=='call-enum':
  args=[str(root/'scripts/capped'),str(root/'lean_frontend/.lake/build/bin/cerberus-lean'),'--batch','--call','f','--call-args','-1',*asts]
  p=subprocess.run(['timeout','30s',*args],capture_output=True,env=env)
  for suffix,data in [('stdout',p.stdout),('stderr',p.stderr),('status',str(p.returncode).encode())]:(d/('lean-call.'+suffix)).write_bytes(data)
  r={'case':name,'side':'lean-call','args':args,'status':p.returncode}
  try:r['tokens']=sorted(set(parse(p.stdout,p.stderr,p.returncode,'batch').tokens('full')))
  except Exception as e:r['protocol_error']=str(e);r['stderr_head']=p.stderr.decode(errors='replace')[:1500]
  results.append(r);print(name,'lean-call',p.returncode,r.get('tokens',r.get('protocol_error')),flush=True)
(out/'results.json').write_text(json.dumps(results,indent=2)+'\n')
