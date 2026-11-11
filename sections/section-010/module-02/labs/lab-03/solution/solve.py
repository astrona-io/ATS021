import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'validation'))
from probes import *

namespaces = ('navigation', 'telemetry', 'research')
allowed('label', '--overwrite', 'namespace', *namespaces, 'pod-security.kubernetes.io/warn=baseline')
findings = []
for namespace in namespaces:
    result = allowed('label', '--dry-run=server', '--overwrite', 'namespace', namespace,
                     'pod-security.kubernetes.io/enforce=baseline',
                     'pod-security.kubernetes.io/enforce-version=v1.35')
    print(namespace + ': ' + result.stderr.strip())
    if 'violate the new PodSecurity enforce level' in result.stderr:
        findings.append(namespace)
require(len(findings) == 1, 'expected exactly one namespace with a baseline violation')
allowed('label', '--overwrite', 'namespace', findings[0], 'security-review=required')
