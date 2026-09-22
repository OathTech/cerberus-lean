from pathlib import Path
import re, subprocess
out=Path('.tmp/run-digest/optional');out.mkdir(exist_ok=True)
opens='open Cerb_frontend\nopen Cerb_backend\nopen Cerb_util\n'
web=Path('backend/web/instance.ml').read_text()
m=re.search(r'let st0\s*=\s*(Driver.initial_driver_state[^\n]+?)\s*\(\* TODO \*\) in',web)
assert m
webprobe=opens+'type conf = { pipeline : Pipeline.configuration }\nlet check (conf : conf) (core\' : Core_run_aux.core_run_annotation Core.file) : Driver.driver_state =\n  '+m[1]+'\n'
rt=Path('backend/ocaml/runtime/rt_ocaml.ml').read_text()
m=re.search(r'let initial_state = (Driver.initial_driver_state[^\n]+\n\s*Sibylfs.fs_initial_state) in',rt)
assert m
rtprobe=opens+'let check (dummy_file : Core_run_aux.core_run_annotation Core.file) : Driver.driver_state =\n  '+m[1]+'\n'
incs=['_build/default/'+p for p in ['ocaml_frontend/.cerb_frontend.objs/byte', 'util/.cerb_util.objs/byte', 'backend/common/.cerb_backend.objs/byte', 'sibylfs/.sibylfs.objs/byte']]
for name,src in [('web_entry',webprobe),('runtime_entry',rtprobe)]:
 path=out/(name+'.ml');path.write_text(src)
 cmd=['ocamlfind','ocamlc','-package','lem,zarith']
 for inc in incs:cmd+=['-I',inc]
 cmd+=['-c',str(path),'-o',str(out/(name+'.cmo'))]
 result=subprocess.run(cmd,capture_output=True,text=True)
 print(name+' rc='+str(result.returncode))
 print(result.stdout+result.stderr,end='')
 if result.returncode:raise SystemExit(result.returncode)
 print(src,end='')

# The mirrored constructor must retain Digest.t, not an unconstrained ignored argument.
path=out/'wrong_digest.ml'
path.write_text(rtprobe.replace('(Cerb_fresh.digest ())', '0'))
cmd=['ocamlfind','ocamlc','-package','lem,zarith']
for inc in incs:cmd+=['-I',inc]
cmd+=['-c',str(path),'-o',str(out/'wrong_digest.cmo')]
result=subprocess.run(cmd,capture_output=True,text=True)
print('wrong_digest expected rejection rc='+str(result.returncode))
print(result.stdout+result.stderr,end='')
assert result.returncode != 0 and 'expected of type' in result.stderr
