#!/usr/bin/env python3
"""Verify live candidate references without treating registry errors as unsigned."""
import json
import subprocess
import sys

key, signed, unsigned = sys.argv[1:]

def verify(image):
    return subprocess.run(['cosign', 'verify', '--key', key,
                           '--insecure-ignore-tlog', image],
                          capture_output=True, text=True, timeout=90)

trusted = verify(signed)
assert trusted.returncode == 0, trusted.stderr
payloads = json.loads(trusted.stdout)
assert any(payload['critical']['image']['docker-manifest-digest'] == signed.split('@')[1]
           for payload in payloads), 'Signed payload digest differs'
untrusted = verify(unsigned)
assert untrusted.returncode != 0, 'Unsigned candidate now verifies'
assert 'no matching signatures' in untrusted.stderr.lower(), untrusted.stderr
assert 'invalid signature' in untrusted.stderr.lower(), 'Registry failure is not unsigned evidence'
