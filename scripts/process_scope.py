#!/usr/bin/env python3
"""Owned cgroup-v2 command lifetimes, including nested process groups.

The supervisor stays outside its new scope. A pipe-watching guardian kills
the scope if the supervisor exits, including SIGKILL. Only this freshly
created cgroup subtree is ever signalled or removed. No shared controller,
system service, process table or global configuration is modified.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import uuid


class ContainmentError(RuntimeError):
    pass


def populated(scope):
    try:
        return dict(line.split() for line in (scope/'cgroup.events').read_text().splitlines())['populated'] != '0'
    except FileNotFoundError:
        return False


def wait_empty(scope, seconds):
    deadline = time.monotonic() + seconds
    while populated(scope):
        if time.monotonic() >= deadline:
            return False
        time.sleep(0.01)
    return True


def destroy(scope):
    if not scope.exists():
        return
    # cgroup.kill is atomic with respect to forks and includes child cgroups;
    # unlike PID enumeration it cannot signal an unrelated reused PID.
    (scope/'cgroup.kill').write_text('1')
    if not wait_empty(scope, 5):
        raise ContainmentError(f'owned command cgroup remains populated: {scope}')
    for child in sorted((p for p in scope.rglob('*') if p.is_dir()),
                        key=lambda p: len(p.parts), reverse=True):
        child.rmdir()
    scope.rmdir()


class ProcessScope:
    def __init__(self, directory: Path):
        self.directory = directory
        self.proc = None
        self.guardian = None
        self.write_fd = None
        self.closed = False
        current = next((line[3:] for line in Path('/proc/self/cgroup').read_text().splitlines()
                        if line.startswith('0::')), None)
        if not current or current == '/':
            raise ContainmentError('release commands require delegated cgroup v2')
        parent = (Path('/sys/fs/cgroup')/current.lstrip('/')).parent
        if 'memory' not in (parent/'cgroup.subtree_control').read_text().split():
            raise ContainmentError('delegated parent must already enable the memory controller')
        self.path = parent / ('cerb-command-' + uuid.uuid4().hex)
        self.leaf = self.path/'command'
        read_fd = None
        try:
            self.path.mkdir()
            if not (self.path/'cgroup.kill').exists():
                raise ContainmentError('cgroup.kill support is required for complete cleanup')
            (self.path/'cgroup.subtree_control').write_text('+memory')
            self.leaf.mkdir()
            self.directory.mkdir(parents=True, exist_ok=True)
            self.record = {'cgroup': str(self.path), 'status': 'prepared',
                           'policy': 'owned subtree; nested capped scopes stay inside; guardian on supervisor death'}
            self.save()
            read_fd, self.write_fd = os.pipe()
            with (directory/'scope-cleanup.log').open('wb') as log:
                self.guardian = subprocess.Popen(
                    [sys.executable, str(Path(__file__).resolve()), 'guard', str(self.path), str(read_fd)],
                    pass_fds=(read_fd,), start_new_session=True,
                    stdin=subprocess.DEVNULL, stdout=log, stderr=log)
            os.close(read_fd)
            read_fd = None
        except BaseException:
            if read_fd is not None:
                os.close(read_fd)
            if self.write_fd is not None:
                os.close(self.write_fd)
            if self.guardian is not None:
                self.guardian.wait(timeout=10)
            else:
                destroy(self.path)
            raise

    def save(self):
        temporary = self.directory/'scope.tmp'
        temporary.write_text(json.dumps(self.record, indent=2) + '\n')
        temporary.replace(self.directory/'scope.json')

    def start(self, command, *, cwd, env, stdout, stderr):
        if self.guardian.poll() is not None:
            raise ContainmentError('command guardian exited before launch')
        command = list(map(str, command))
        launch_error = self.directory/'scope-launch-error.json'
        self.proc = subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), 'exec', str(self.leaf),
             str(launch_error), *command], cwd=cwd,
            env=dict(env, CERB_JOB_CGROUP=str(self.path)), stdout=stdout,
            stderr=stderr, start_new_session=True)
        self.record.update(status='running', process_group=self.proc.pid, command=command,
                           guardian_pid=self.guardian.pid)
        self.save()
        return self.proc

    def wait(self, timeout):
        result = self.proc.wait(timeout=timeout)
        error = self.directory/'scope-launch-error.json'
        if error.exists():
            raise OSError(json.loads(error.read_text())['error'])
        return result

    def finish(self, *, cancel=False):
        if self.closed:
            return False
        # Defer cancellation until cleanup is complete; SIG_IGN would lose
        # a first cancellation arriving during otherwise normal cleanup.
        previous = signal.pthread_sigmask(signal.SIG_BLOCK, {signal.SIGINT, signal.SIGTERM})
        try:
            residual = not wait_empty(self.path, 0 if cancel else 0.25)
            destroy(self.path)
            if self.proc is not None:
                self.proc.wait(timeout=5)
            os.close(self.write_fd)
            self.write_fd = None
            self.guardian.wait(timeout=10)
            if self.guardian.returncode:
                raise ContainmentError('command guardian failed; see scope-cleanup.log')
            self.record.update(status='cleaned', cancelled=cancel,
                               residual_processes=residual, populated=False)
            self.save()
            self.closed = True
            return residual
        finally:
            # Even failed cleanup releases the guardian to retry; callers
            # must stop dispatch if finish raises, never certify or overlap.
            try:
                if self.write_fd is not None:
                    os.close(self.write_fd)
                    self.write_fd = None
                    self.guardian.wait(timeout=10)
            finally:
                signal.pthread_sigmask(signal.SIG_SETMASK, previous)


def main():
    action = sys.argv[1]
    scope = Path(sys.argv[2])
    if action == 'guard':
        fd = int(sys.argv[3])
        # Parent holds the sole writer. It is close-on-exec and not inherited
        # by any command, so parent death cannot leave this read blocked.
        while os.read(fd, 1):
            pass
        os.close(fd)
        destroy(scope)
        return 0
    if action == 'exec':
        error = Path(sys.argv[3])
        command = sys.argv[4:]
        try:
            (scope/'cgroup.procs').write_text(str(os.getpid()))
            os.execvpe(command[0], command, os.environ)
        except OSError as exc:
            error.write_text(json.dumps({'error': str(exc), 'command': command}) + '\n')
            print(f'command launch failed: {exc}', file=sys.stderr)
            return 126
    raise ValueError(f'unknown process_scope action: {action}')


if __name__ == '__main__':
    sys.exit(main())
