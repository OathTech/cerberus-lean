import json, os, subprocess, sys, time
from pathlib import Path
name, limit, *cmd = sys.argv[1:]
limit = int(limit)
root = Path('.tmp/run-digest')
started = time.monotonic()
# Poll actual workers, excluding shells whose command strings quote the poll.
while True:
    jobs = []
    for line in subprocess.check_output(['ps', '-eo', 'pid=,comm=,args='], text=True).splitlines():
        parts = line.split(None, 2)
        if len(parts) != 3: continue
        pid, comm, args = parts
        if int(pid) == os.getpid(): continue
        if comm in ('lean', 'lem') or (comm == 'lake' and ' build' in args) or (comm == 'dune' and ' build' in args) or (comm.startswith('python') and 'scripts/release.py' in args):
            jobs.append((pid, comm, args[:210]))
    print(json.dumps({'step':name,'external_heavy':jobs,'load':os.getloadavg(),'wait_s':round(time.monotonic()-started,1)}),flush=True)
    if not jobs: break
    time.sleep(20)
wait_s = time.monotonic()-started
print('START '+name,flush=True)
t0 = time.monotonic()
with (root/(name+'.log')).open('w') as log:
    proc = subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
    try:
        while True:
            credit = 0.0
            coordination = root/'coordination-state.json'
            if name == 'full' and coordination.exists():
                st = json.loads(coordination.read_text())
                credit = st['wait_seconds']
                if st['wait_started'] is not None:
                    credit += time.monotonic() - st['wait_started']
            remaining = limit - (time.monotonic() - t0 - credit)
            if remaining <= 0:
                raise subprocess.TimeoutExpired(cmd, limit)
            try:
                rc = proc.wait(timeout=min(20, remaining))
                break
            except subprocess.TimeoutExpired:
                continue
    except subprocess.TimeoutExpired:
        import signal
        os.killpg(proc.pid,signal.SIGTERM)
        rc=124
        proc.wait(timeout=30)
result={'step':name,'cmd':cmd,'rc':rc,'wait_s':round(wait_s,1),'wall_s':round(time.monotonic()-t0,1)}
with (root/'steps.jsonl').open('a') as f: f.write(json.dumps(result)+'\n')
print(json.dumps(result),flush=True)
print(subprocess.check_output(['tail','-12',str(root/(name+'.log'))],text=True),end='')
sys.exit(rc)
