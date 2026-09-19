from pathlib import Path
import subprocess,json
root=Path.cwd();out=root/'.tmp/concurrency-design-audit/instrument';out.mkdir(parents=True,exist_ok=True)
s=(root/'scripts/test_litmus.sh').read_text();helpers=s[s.index('tokens_of() {'):s.index('\necho ""\necho "litmus lane')]
(out/'helpers.sh').write_text(helpers)
corpus=out/'corpus';corpus.mkdir(exist_ok=True);(corpus/'probe.c').write_text('int main(void){return 7;}\n')
rows=out/'rows.txt';rows.write_text('probe.c SC {Specified(7)}\n')
common=(root/'scripts/common.sh').read_text();cap=common[common.index('is_cap_kill() {'):common.index('\nrequire_time_bin()')]
preamble='set -uo pipefail\n'+helpers+'\n'+cap+'''\nLITMUS_DIR="$1";OUTPUT_DIR="$2";MODEL_FLAG="";REFUSE_RE='^model refused: '
run_oracle() { printf '%s\\n' 'Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}' > "$2"; return "$ORC"; }
run_lean() { printf '%s\\n' 'Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}' > "$3"; return "$LRC"; }
run_all
compare_to "$3" reference
printf 'DIFF_FAIL=%s COMPARE_FAIL=%s\\n' "$DIFF_FAIL" "$COMPARE_FAIL"
'''
records=[]
for label,orc,lrc in [('control',0,0),('fork-kill',137,0),('lean-kill',0,137),('both-timeout',124,124)]:
 d=out/label;d.mkdir(exist_ok=True)
 q=subprocess.run(['bash','-c',f'ORC={orc}; LRC={lrc}\n'+preamble,'probe',str(corpus),str(d),str(rows)],capture_output=True,text=True)
 (d/'stdout').write_text(q.stdout);(d/'stderr').write_text(q.stderr)
 records.append({'case':label,'fork_status':orc,'lean_status':lrc,'helper_status':q.returncode,'stdout':q.stdout,'stderr':q.stderr})
 print(label,orc,lrc,repr(q.stdout),flush=True)
for label,data in [('reference-control',(root/'tests/litmus/expectations.txt').read_text()),('reference-duplicate','SB+sc_sc+sc_sc.c SC {Specified(99)}\n'+(root/'tests/litmus/expectations.txt').read_text())]:
 p=out/(label+'.txt');p.write_text(data)
 q=subprocess.run(['python3',str(root/'tests/litmus/sc_reference.py'),'--check',str(p)],capture_output=True,text=True)
 records.append({'case':label,'status':q.returncode,'stdout':q.stdout,'stderr':q.stderr});print(label,q.returncode,q.stdout.strip(),flush=True)
(out/'results.json').write_text(json.dumps(records,indent=2)+'\n')
