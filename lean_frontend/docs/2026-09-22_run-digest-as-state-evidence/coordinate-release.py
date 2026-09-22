"""Local scheduling wrapper: run the unchanged release runner with lane polling.

No command, selection, timeout, status, or source-identity logic is replaced.
The only hook waits before execute_lane. The outer watchdog excludes these
explicitly recorded waits from its 100-minute active-time budget.
"""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time

script = Path(sys.argv.pop(1)).resolve()
sys.argv[0] = str(script)
sys.path.insert(0, str(script.parent))
spec = importlib.util.spec_from_file_location('run_digest_release', script)
release = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = release
spec.loader.exec_module(release)
execute = release.execute_lane
root = Path('.tmp/run-digest')
state_file = root / 'coordination-state.json'
log_file = root / 'lane-polls.jsonl'
state = {'wait_seconds': 0.0, 'wait_started': None}

def save_state():
    tmp = state_file.with_suffix('.tmp')
    tmp.write_text(json.dumps(state) + '\n')
    tmp.replace(state_file)

save_state()

def coordinated(lane, *args, **kwargs):
    started = time.monotonic()
    state['wait_started'] = started
    save_state()
    while True:
        procs = {}
        for line in subprocess.check_output(['ps', '-eo', 'pid=,ppid=,stat=,comm=,args='], text=True).splitlines():
            parts = line.split(None, 4)
            if len(parts) == 5:
                pid, parent, status, comm, command = parts
                procs[int(pid)] = (int(parent), status, comm, command)
        ancestors = set()
        pid = os.getpid()
        while pid and pid not in ancestors:
            ancestors.add(pid)
            pid = procs.get(pid, (0,))[0]
        jobs = []
        for pid, (_, status, comm, command) in procs.items():
            if pid in ancestors or status.startswith('Z'):
                continue
            heavy = (comm in ('lean', 'lem') or
                     (comm in ('lake', 'dune') and ' build' in command) or
                     (comm.startswith('python') and 'scripts/release.py' in command))
            if heavy:
                jobs.append({'pid': pid, 'comm': comm, 'command': command})
        row = {'lane': lane.id, 'external_heavy': jobs, 'load': os.getloadavg(),
               'wait_s': round(time.monotonic() - started, 3)}
        with log_file.open('a') as stream:
            stream.write(json.dumps(row) + '\n')
        print('COORDINATION ' + json.dumps(row), flush=True)
        if not jobs:
            break
        time.sleep(20)
    state['wait_seconds'] += time.monotonic() - started
    state['wait_started'] = None
    save_state()
    return execute(lane, *args, **kwargs)

release.execute_lane = coordinated
sys.exit(release.main())
