from pathlib import Path
import json, os, subprocess

root=Path.cwd(); out=root/'.tmp/enum-premerge/sign-normalisation'
base=root.parent/'enum-base-20260920'
env={**os.environ, 'CERB_MEM_MAX':'8G','LEAN_ABORT_ON_PANIC':'1'}
results=[]
for label, tree in [('base',base),('head',root)]:
    args=['ocamlfind','ocamlc','-package','lem,pprint,unix,str','-linkpkg',
          '-I',str(tree/'_build/default/ocaml_frontend/.cerb_frontend.objs/byte'),
          '-I',str(tree/'_build/default/util/.cerb_util.objs/byte'),
          str(tree/'_build/default/util/cerb_util.cma'),
          str(tree/'_build/default/sibylfs/sibylfs.cma'),
          str(tree/'_build/default/memory/concrete/mem_concrete.cma'),
          str(out/'sign.ml'),'-o',str(out/(label+'-sign.exe'))]
    p=subprocess.run(args,capture_output=True,text=True,env=env,timeout=30)
    results.append({'side':label,'engine':'ocaml-compile','args':args,'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
    if p.returncode==0:
        args=['ocamlrun',str(out/(label+'-sign.exe'))]
        p=subprocess.run(args,capture_output=True,text=True,env=env,timeout=30)
        results.append({'side':label,'engine':'ocaml','args':args,'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
        print(label,'ocaml',p.returncode,p.stdout,p.stderr,flush=True)
    for case in ['signed32','signed128','unsigned128']:
        args=['timeout','30s',str(tree/'scripts/lean_probe.sh'),'.tmp/EnumSignAudit-'+case+'.lean']
        p=subprocess.run(args,cwd=tree/'lean_frontend',capture_output=True,text=True,env=env)
        row={'side':label,'engine':'lean','case':case,'args':args,'cwd':str(tree/'lean_frontend'),'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
        results.append(row)
        (out/(label+'-lean-'+case+'.stdout')).write_text(p.stdout)
        (out/(label+'-lean-'+case+'.stderr')).write_text(p.stderr)
        print(label,'lean',case,p.returncode,p.stdout,p.stderr[:300],flush=True)
(out/'results.json').write_text(json.dumps(results,indent=2)+'\n')
