"""Ensure incomplete and overbroad answers fail against the live API."""
from pathlib import Path
import subprocess
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'validation'))
from probes import allowed, get, require

LAB = Path(__file__).resolve().parents[1]
NAMESPACES = ('navigation', 'telemetry', 'research')


def reject(grader):
    result = subprocess.run(['bash', str(LAB / 'validation' / ('validate-' + grader + '.sh'))],
                            capture_output=True, text=True, timeout=120)
    require(result.returncode == 1 and 'FAIL:' in result.stdout and 'ERROR:' not in result.stdout,
            'expected a grading failure: ' + result.stdout + result.stderr)


flagged = [name for name in NAMESPACES if get('namespace', name)['metadata']['labels'].get('security-review') == 'required']
require(len(flagged) == 1, 'run failure cases after the reference solution')
offender = flagged[0]
control = next(name for name in NAMESPACES if name != offender)
try:
    allowed('label', 'namespace', offender, 'security-review-')
    allowed('label', 'namespace', control, 'security-review=required')
    reject('finding')
    allowed('label', 'namespace', *NAMESPACES, 'security-review=required', '--overwrite')
    reject('finding')
    allowed('label', 'namespace', control, 'pod-security.kubernetes.io/warn-')
    reject('warnings')
    allowed('label', 'namespace', control, 'pod-security.kubernetes.io/warn=baseline')
    allowed('label', 'namespace', control, 'pod-security.kubernetes.io/enforce=baseline')
    reject('warnings')
finally:
    allowed('label', 'namespace', *NAMESPACES, 'security-review-', '--overwrite')
    allowed('label', 'namespace', offender, 'security-review=required')
    allowed('label', 'namespace', *NAMESPACES, 'pod-security.kubernetes.io/warn=baseline', '--overwrite')
    allowed('label', 'namespace', control, 'pod-security.kubernetes.io/enforce-', '--overwrite')
print('PASS: wrong namespace, blanket findings, missing warnings and persisted enforcement are rejected')
