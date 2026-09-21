from pathlib import Path
import subprocess,json,os
root=Path.cwd();out=root/'.tmp/enum-premerge/constructors';out.mkdir(exist_ok=True)
base=Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/enum-base-20260920')
# Retain the actual record expressions, supplying identity stand-ins only for their unchanged transforms.
s=(root/'backend/web/instance.ml').read_text();start=s.index('  { main=    file.main;');end=s.index('\n  }',start)+4
web='open Cerb_frontend\nopen Core\nlet set_globs x = x\nlet set_fun _ x = x\nlet audit (file : unit Core.file) =\n'+s[start:end]+'\n'
s=(root/'backend/bmc/bmc_utils.ml').read_text();start=s.index('let set_uid file1 =');end=s.index('\nlet get_uid_or_fail',start)
bmc='open Cerb_frontend\nopen Core\nlet set_uid_globs x = x\nlet set_uid_fun _ x = x\n'+s[start:end]+'\n'
records=[]
for label,code in [('web_record',web),('bmc_record',bmc)]:
 source=out/(label+'.ml');source.write_text(code)
 for side,engine in [('base',base),('head',root)]:
  includes=[engine/'_build/default/ocaml_frontend/.cerb_frontend.objs/byte',engine/'_build/default/util/.cerb_util.objs/byte']
  args=['ocamlc','-c',*[v for p in includes for v in ['-I',str(p)]],'-I',str(root/'_opam/lib/lem_zarith'),'-o',str(out/(label+'_'+side+'.cmo')),str(source)]
  p=subprocess.run(args,capture_output=True,text=True)
  r={'case':label,'side':side,'args':args,'status':p.returncode,'stdout':p.stdout,'stderr':p.stderr};records.append(r);print(label,side,p.returncode,p.stderr,flush=True)
(out/'results.json').write_text(json.dumps(records,indent=2)+'\n')
