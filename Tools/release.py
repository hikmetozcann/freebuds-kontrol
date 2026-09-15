#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Publish only checksummed CI artifacts built for the checked-out main commit."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
os.chdir(ROOT)

def command(*args):
    return subprocess.check_output(args, text=True).strip()

def main():
    version = (ROOT / 'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise SystemExit('Invalid VERSION')
    head = command('git', 'rev-parse', 'HEAD')
    repo = os.environ.get('GH_REPO') or command('gh', 'repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner')
    if command('gh', 'api', f'repos/{repo}/commits/main', '--jq', '.sha') != head:
        raise SystemExit('Release must use the current main commit')
    refs = json.loads(command('gh', 'api', f'repos/{repo}/git/matching-refs/tags/v{version}'))
    if any(ref['ref'] == f'refs/tags/v{version}' for ref in refs):
        raise SystemExit('This version tag already exists. Choose a new VERSION; published tags are not reused.')
    notes = ROOT / 'docs' / 'releases' / f'v{version}.md'
    if not notes.is_file():
        raise SystemExit('Release notes are missing')
    runs = json.loads(command('gh', 'api', f'repos/{repo}/actions/workflows/ci.yml/runs?head_sha={head}&event=push&status=success&per_page=20'))
    candidates = [r for r in runs['workflow_runs'] if r['head_sha'] == head and r['head_branch'] == 'main' and r['conclusion'] == 'success']
    if not candidates:
        raise SystemExit('No successful main-branch CI build exists for this exact commit. Wait for CI, then retry.')
    run = str(candidates[0]['id'])
    jobs = json.loads(command('gh', 'api', f'repos/{repo}/actions/runs/{run}/jobs?per_page=100'))['jobs']
    expected_jobs = {'Build and check (arm64)', 'Build and check (x86_64)'}
    if not expected_jobs.issubset({j['name'] for j in jobs if j['conclusion'] == 'success'}):
        raise SystemExit('Both architecture checks must succeed')
    with tempfile.TemporaryDirectory(prefix='freebuds-release-') as directory:
        target = Path(directory)
        subprocess.run(['gh', 'run', 'download', run, '--repo', repo, '--pattern', 'release-*', '--dir', directory], check=True)
        archives = []
        sums = []
        for arch in ('arm64', 'x86_64'):
            folder = target / f'release-{arch}'
            name = f'FreeBuds-Kontrol-{version}-{arch}.zip'
            archive = folder / name
            expected = (folder / f'SHA256SUMS-{arch}.txt').read_text().strip()
            actual = hashlib.sha256(archive.read_bytes()).hexdigest()
            if expected.split() != [actual, name]:
                raise SystemExit(f'Checksum or filename mismatch: {arch}')
            sums.append(f'{actual}  {name}\n')
            archives.append(str(archive))
        checksum = target / 'SHA256SUMS.txt'
        checksum.write_text(''.join(sums))
        # gh refuses to create a release when one already exists; no overwrite.
        subprocess.run(['gh', 'release', 'create', f'v{version}', *archives, str(checksum), '--repo', repo,
                        '--target', head, '--title', f'FreeBuds Kontrol {version}', '--notes-file', str(notes)], check=True)

if __name__ == '__main__':
    main()
