#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Prevent local diagnostics and recognizable credentials from entering the tree."""
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parent.parent
files = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0')
patterns = [r'gh[pousr]_[A-Za-z0-9]{25,}', r'github_pat_[A-Za-z0-9_]{25,}',
            r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
            r'(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}', r'/' + r'Users/[^/\s]+/']
failures = []
for name in filter(None, files):
    path = root / name
    if name.endswith(('.png', '.icns')):
        continue
    if any(p in name.split('/') for p in ('build', 'dist', '.env')) or name.endswith(('.log', '.app')):
        failures.append(name)
    if path.is_file():
        data = path.read_text(errors='replace')
        if any(re.search(pattern, data) for pattern in patterns):
            failures.append(name)
if failures:
    raise SystemExit('Review potentially private content in: ' + ', '.join(sorted(set(failures))))
print(f'PASS: checked {len(list(filter(None, files)))} tracked paths; no recognized private diagnostics or credentials')
