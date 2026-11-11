"""Check warning mode and dry-run discovery against the teaching fixtures."""
import json
import subprocess


def kubectl(*args):
    return subprocess.run(['kubectl', '--request-timeout=15s', *args],
                          check=True, capture_output=True, text=True, timeout=30)


def namespace(name):
    return json.loads(kubectl('get', 'namespace', name, '-o', 'json').stdout)


original = {name:namespace(name)['metadata']['labels'] for name in ('starfleet','outpost')}
try:
    result = kubectl('label', 'namespace', 'starfleet', 'pod-security.kubernetes.io/warn=baseline')
    assert 'existing pods' not in result.stderr, 'warn label must not be mistaken for an inventory scan'
    for name in ('starfleet','outpost'):
        result = kubectl('label', '--dry-run=server', '--overwrite', 'namespace', name,
                         'pod-security.kubernetes.io/enforce=baseline',
                         'pod-security.kubernetes.io/enforce-version=v1.35')
        if name == 'starfleet':
            assert 'violate the new PodSecurity enforce level' in result.stderr
            assert 'privileged-debug' in result.stderr and 'privileged' in result.stderr
        else:
            assert 'violate the new PodSecurity enforce level' not in result.stderr
        labels = namespace(name)['metadata']['labels']
        for key in ('pod-security.kubernetes.io/enforce','pod-security.kubernetes.io/enforce-version'):
            assert labels.get(key) == original[name].get(key), 'dry run persisted enforcement'
    kubectl('label', 'namespace', 'starfleet', 'security-review=required', '--overwrite')
    assert namespace('starfleet')['metadata']['labels']['security-review'] == 'required'
    assert 'security-review' not in namespace('outpost')['metadata']['labels']
finally:
    kubectl('label', 'namespace', 'starfleet', 'security-review-', 'pod-security.kubernetes.io/warn-')
print('PASS: warning mode, baseline inventory and namespace finding procedure')
